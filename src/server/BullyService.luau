local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))
local CharacterFactory = require(script.Parent.CharacterFactory)
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.Progress)
local StoryService = require(script.Parent.StoryService)

local BullyService = {}

local models: { [string]: Model } = {}
local stunnedUntil: { [string]: number } = {}
local encounters: { [number]: any } = {}
local runningAway: { [number]: boolean } = {}

local NURSE_CF = CFrame.new(-42, 6, 62)

local function rootPart(model: Model): BasePart?
	return model.PrimaryPart
end

local function playerRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function nearHide(player: Player): boolean
	local root = playerRoot(player)
	if not root then
		return false
	end
	for _, spot in CollectionService:GetTagged("HideSpot") do
		if spot:IsA("BasePart") and (spot.Position - root.Position).Magnitude <= 10 then
			return true
		end
	end
	return false
end

local function sendToNurse(player: Player)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = NURSE_CF
	end
	Progress.notify(player, "보건실로 이동했어요. 잠시 쉬며 용기를 회복합니다.", "warn")
end

local function endEncounter(player: Player)
	encounters[player.UserId] = nil
	runningAway[player.UserId] = nil
	Remotes.get("EncounterEnd"):FireClient(player)
end

function BullyService.resolve(player: Player, action: string, itemId: string?)
	local encounter = encounters[player.UserId]
	if not encounter then
		return
	end
	local profile = DataService.get(player)
	local bully = encounter.info
	if not profile then
		return
	end

	local model = models[bully.id]
	local bullyRoot = model and rootPart(model)

	if action == "item" then
		local item = itemId and Config.Items[itemId]
		local count = itemId and (profile.inventory[itemId] or 0) or 0
		if not item or count < 1 then
			Progress.notify(player, "쓸 수 있는 아이템이 없어요.", "warn")
			return
		end
		profile.inventory[itemId] -= 1
		if item.escape then
			Progress.bump(profile, "bulliesDodged")
			Progress.addXp(player, profile, 18)
			Progress.notify(player, "친구의 쪽지로 빠져나왔어요!", "good")
			StoryService.onBullyResolved(player, bully.id)
			endEncounter(player)
			Progress.push(player)
			return
		end
		if item.scare then
			action = "fight"
			encounter.bonus = item.powerBonus or 5
			Progress.notify(player, "호루라기를 불었어요! 맞서기 힘이 올라갑니다.", "info")
		elseif item.courage or item.energy then
			profile.courage = Util.clamp(profile.courage + (item.courage or 0), 0, profile.maxCourage)
			profile.energy = Util.clamp(profile.energy + (item.energy or 0), 0, profile.maxEnergy)
			Progress.notify(player, item.name .. " 을(를) 썼어요. 다시 선택하세요!", "info")
			Progress.push(player)
			return
		end
	end

	if action == "hide" then
		if nearHide(player) then
			Progress.bump(profile, "bulliesDodged")
			Progress.addXp(player, profile, 22)
			Progress.notify(player, "숨어서 왕딱... 아니, 불리를 피했어요!", "good")
			StoryService.onBullyResolved(player, bully.id)
			endEncounter(player)
			Progress.push(player)
			return
		end
		Progress.notify(player, "근처에 숨을 곳이 없어요. 사물함이나 덤불 뒤로 가세요!", "warn")
		return
	end

	if action == "run" then
		if runningAway[player.UserId] then
			return
		end
		runningAway[player.UserId] = true
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 28
		end
		Progress.notify(player, "도망치세요! 멀리 떨어지면 성공입니다.", "info")
		task.delay(6.5, function()
			if not encounters[player.UserId] then
				Progress.applySpeed(player)
				return
			end
			local still = playerRoot(player)
			local other = bullyRoot
			local far = still and other and (still.Position - other.Position).Magnitude or 0
			Progress.applySpeed(player)
			if far >= 28 then
				Progress.bump(profile, "bulliesDodged")
				Progress.addXp(player, profile, 26)
				Progress.notify(player, "멀리 도망쳐서 피했어요!", "good")
				StoryService.onBullyResolved(player, bully.id)
			else
				profile.courage = Util.clamp(profile.courage - 18, 0, profile.maxCourage)
				Progress.notify(player, "따라잡혀서 용기가 떨어졌어요. 보건실로 가요.", "warn")
				sendToNurse(player)
				profile.courage = Util.clamp(profile.courage + 25, 0, profile.maxCourage)
			end
			endEncounter(player)
			Progress.push(player)
		end)
		return
	end

	if action == "fight" then
		local power = Util.confrontPower(profile, Config) + (encounter.bonus or 0)
		if power >= bully.power then
			stunnedUntil[bully.id] = os.clock() + 22
			Progress.bump(profile, "bulliesDefeated")
			Progress.addXp(player, profile, bully.xp)
			profile.coins += bully.coins
			profile.courage = Util.clamp(profile.courage + 8, 0, profile.maxCourage)
			Progress.notify(player, string.format("%s 에게 맞서서 이겼어요! (힘 %d vs %d)", bully.name, power, bully.power), "good")
			StoryService.onBullyResolved(player, bully.id)
		else
			profile.courage = Util.clamp(profile.courage - 22, 0, profile.maxCourage)
			Progress.notify(
				player,
				string.format("아직 힘이 부족해요. (내 힘 %d / 상대 %d) 수업과 아이템으로 더 강해지세요.", power, bully.power),
				"warn"
			)
			sendToNurse(player)
			profile.courage = Util.clamp(profile.courage + 20, 0, profile.maxCourage)
		end
		endEncounter(player)
		Progress.push(player)
	end
end

local function tryEncounter(player: Player, info)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	if profile.storyStep < info.storyMin then
		return
	end
	if encounters[player.UserId] then
		return
	end
	if stunnedUntil[info.id] and os.clock() < stunnedUntil[info.id] then
		return
	end
	encounters[player.UserId] = { info = info }
	Remotes.get("EncounterStart"):FireClient(player, {
		id = info.id,
		name = info.name,
		title = info.title,
		power = info.power,
		playerPower = Util.confrontPower(profile, Config),
		boss = info.boss == true,
	})
	Progress.notify(player, string.format("%s 가 다가온다! 피하거나 맞서세요.", info.name), "warn")
end

local function tickBully(info, model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = rootPart(model)
	if not humanoid or not root then
		return
	end

	if stunnedUntil[info.id] and os.clock() < stunnedUntil[info.id] then
		return
	end

	local targetPlayer = nil
	local targetDist = math.huge
	for _, player in Players:GetPlayers() do
		local profile = DataService.get(player)
		local pr = playerRoot(player)
		if profile and pr and profile.storyStep >= info.storyMin and not encounters[player.UserId] then
			local dist = (pr.Position - root.Position).Magnitude
			if dist < info.detect and dist < targetDist then
				targetPlayer = player
				targetDist = dist
			end
		end
	end

	if targetPlayer then
		Remotes.get("BullyWarning"):FireClient(targetPlayer, { name = info.name, distance = targetDist })
		if targetDist <= info.catch then
			tryEncounter(targetPlayer, info)
		else
			humanoid:MoveTo(playerRoot(targetPlayer).Position)
		end
	else
		local wander = info.start + Vector3.new(math.random(-18, 18), 0, math.random(-18, 18))
		humanoid:MoveTo(wander)
	end
end

function BullyService.start()
	for _, info in Config.Bullies do
		local model = CharacterFactory.create({
			name = info.name,
			title = info.title,
			color = info.color,
			start = info.start,
			walkSpeed = 13,
			labelColor = Color3.fromRGB(255, 170, 170),
			attributes = { BullyId = info.id },
		})
		models[info.id] = model
	end

	Remotes.get("EncounterAction").OnServerEvent:Connect(function(player, action, itemId)
		if typeof(action) ~= "string" then
			return
		end
		if itemId ~= nil and typeof(itemId) ~= "string" then
			return
		end
		BullyService.resolve(player, action, itemId)
	end)

	task.spawn(function()
		while true do
			task.wait(0.35)
			for _, info in Config.Bullies do
				local model = models[info.id]
				if model and model.Parent then
					pcall(tickBully, info, model)
				end
			end
		end
	end)
end

return BullyService
