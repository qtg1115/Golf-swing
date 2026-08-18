local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))
local ActorFactory = require(script.Parent.ActorFactory)
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.Progress)
local StoryService = require(script.Parent.StoryService)

local BullyService = {}

local NURSE = CFrame.new(-50, 7, 60)
local CHASE_TIME = 8

local models: { [string]: Model } = {}
local calmUntil: { [string]: number } = {}
local wanderTarget: { [string]: Vector3 } = {}
local encounters: { [number]: any } = {}

local function playerRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function nearHideSpot(player: Player): boolean
	local root = playerRoot(player)
	if not root then
		return false
	end
	for _, spot in CollectionService:GetTagged("HideSpot") do
		if spot:IsA("BasePart") and (spot.Position - root.Position).Magnitude <= 12 then
			return true
		end
	end
	return false
end

local function sendToNurse(player: Player)
	local root = playerRoot(player)
	if root then
		root.CFrame = NURSE
	end
end

local function closeEncounter(player: Player)
	encounters[player.UserId] = nil
	Remotes.get("EncounterEnd"):FireClient(player)
end

local function win(player: Player, profile, bully, message: string, statName: string, xp: number)
	Progress.stat(profile, statName)
	Progress.addXp(player, profile, xp)
	Progress.notify(player, message, "good")
	StoryService.onBully(player, bully.id)
	calmUntil[bully.id] = os.clock() + 20
	closeEncounter(player)
	Progress.push(player)
end

local function lose(player: Player, profile, message: string)
	profile.courage = Util.clamp(profile.courage - 20, 0, profile.maxCourage)
	Progress.notify(player, message, "warn")
	sendToNurse(player)
	profile.courage = Util.clamp(profile.courage + 25, 0, profile.maxCourage)
	closeEncounter(player)
	Progress.push(player)
end

function BullyService.act(player: Player, action: string, itemId: string?)
	local encounter = encounters[player.UserId]
	local profile = DataService.get(player)
	if not encounter or not profile then
		return
	end
	local bully = encounter.bully

	if action == "item" and itemId then
		local item = Config.Items[itemId]
		local count = profile.bag[itemId] or 0
		if not item or count < 1 then
			Progress.notify(player, "You do not have that item.", "warn")
			return
		end
		profile.bag[itemId] = count - 1
		if item.escape then
			win(player, profile, bully, "You used the note and slipped away safely!", "escapes", 20)
			return
		end
		if item.power then
			encounter.bonus = (encounter.bonus or 0) + item.power
			Progress.notify(player, "You blew the whistle! Stand-up power went up.", "info")
			Remotes.get("EncounterStart"):FireClient(player, {
				name = bully.name,
				role = bully.role,
				power = bully.power,
				myPower = Util.standUpPower(profile) + encounter.bonus,
			})
			Progress.push(player)
			return
		end
		profile.energy = Util.clamp(profile.energy + (item.energy or 0), 0, profile.maxEnergy)
		profile.courage = Util.clamp(profile.courage + (item.courage or 0), 0, profile.maxCourage)
		Progress.notify(player, "You used " .. item.name .. ".", "info")
		Progress.push(player)
		return
	end

	if action == "hide" then
		if nearHideSpot(player) then
			win(player, profile, bully, "You hid and the bully walked right past you!", "escapes", 22)
		else
			Progress.notify(player, "No hiding spot nearby. Look for green bushes or lockers.", "warn")
		end
		return
	end

	if action == "run" then
		if encounter.running then
			return
		end
		encounter.running = true
		encounter.runUntil = os.clock() + CHASE_TIME
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.WalkSpeed + 14
		end
		Progress.notify(player, "Run! Get far away before the bully catches up.", "info")
		return
	end

	if action == "stand" then
		local myPower = Util.standUpPower(profile) + (encounter.bonus or 0)
		if myPower >= bully.power then
			profile.coins += bully.coins
			profile.courage = Util.clamp(profile.courage + 10, 0, profile.maxCourage)
			win(
				player,
				profile,
				bully,
				string.format("You stood up to %s and won! (%d vs %d)", bully.name, myPower, bully.power),
				"standups",
				bully.xp
			)
		else
			lose(
				player,
				profile,
				string.format("Not strong enough yet (%d vs %d). Go to class and get gear.", myPower, bully.power)
			)
		end
	end
end

local function startEncounter(player: Player, bully)
	local profile = DataService.get(player)
	if not profile or encounters[player.UserId] then
		return
	end
	encounters[player.UserId] = { bully = bully, bonus = 0 }
	Remotes.get("EncounterStart"):FireClient(player, {
		name = bully.name,
		role = bully.role,
		power = bully.power,
		myPower = Util.standUpPower(profile),
		boss = bully.boss == true,
	})
	Progress.notify(player, bully.name .. " found you! Run, hide, or stand up.", "warn")
end

local function updateRunning(bully, model: Model)
	for userId, encounter in encounters do
		if encounter.bully.id == bully.id and encounter.running then
			local player = Players:GetPlayerByUserId(userId)
			local profile = player and DataService.get(player)
			if not player or not profile then
				encounters[userId] = nil
				continue
			end
			local root = playerRoot(player)
			local distance = if root then (root.Position - model:GetPivot().Position).Magnitude else 0
			if distance >= 45 then
				Progress.applySpeed(player)
				win(player, profile, bully, "You got away safely!", "escapes", 24)
			elseif os.clock() >= (encounter.runUntil or 0) then
				Progress.applySpeed(player)
				lose(player, profile, "The bully kept up with you. Try hiding or buy the sneakers.")
			end
		end
	end
end

local function step(bully, model: Model, dt: number)
	updateRunning(bully, model)

	local origin = model:GetPivot().Position
	if calmUntil[bully.id] and os.clock() < calmUntil[bully.id] then
		return
	end

	local target: Player? = nil
	local best = math.huge
	for _, player in Players:GetPlayers() do
		local profile = DataService.get(player)
		local root = playerRoot(player)
		if profile and root and profile.story >= bully.unlock then
			local encounter = encounters[player.UserId]
			if not encounter or (encounter.bully.id == bully.id and encounter.running) then
				local distance = (root.Position - origin).Magnitude
				if distance < bully.sight and distance < best then
					target = player
					best = distance
				end
			end
		end
	end

	if target then
		local root = playerRoot(target)
		if root then
			ActorFactory.moveTowards(model, root.Position, bully.speed, dt)
			if best <= bully.catch and not encounters[target.UserId] then
				startEncounter(target, bully)
			elseif best < bully.sight then
				Remotes.get("BullyWarning"):FireClient(target, { name = bully.name, distance = best })
			end
		end
		return
	end

	local spot = wanderTarget[bully.id]
	if not spot or (origin - spot).Magnitude < 3 then
		spot = bully.home + Vector3.new(math.random(-bully.range, bully.range), 0, math.random(-bully.range, bully.range))
		wanderTarget[bully.id] = spot
	end
	ActorFactory.moveTowards(model, spot, bully.speed * 0.55, dt)
end

function BullyService.start()
	local campus = workspace:FindFirstChild("SchoolCampus") or workspace

	for _, bully in Config.Bullies do
		models[bully.id] = ActorFactory.create({
			name = bully.name,
			role = bully.role,
			color = bully.color,
			position = bully.home,
			labelColor = Color3.fromRGB(255, 170, 170),
			parent = campus,
		})
	end

	Remotes.get("EncounterAction").OnServerEvent:Connect(function(player, action, itemId)
		if typeof(action) ~= "string" then
			return
		end
		if itemId ~= nil and typeof(itemId) ~= "string" then
			return
		end
		BullyService.act(player, action, itemId)
	end)

	Players.PlayerRemoving:Connect(function(player)
		encounters[player.UserId] = nil
	end)

	RunService.Heartbeat:Connect(function(dt)
		for _, bully in Config.Bullies do
			local model = models[bully.id]
			if model and model.Parent then
				local ok, err = pcall(step, bully, model, dt)
				if not ok then
					warn("[BraveKid] bully error:", err)
				end
			end
		end
	end)
end

return BullyService
