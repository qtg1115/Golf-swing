local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.Progress)
local ScheduleService = require(script.Parent.ScheduleService)
local StoryService = require(script.Parent.StoryService)

local GameService = {}

local CHAT = {
	["Mr. Park"] = "Go to class when the bell rings. Levels make you braver.",
	["Mia"] = "Hide behind the lockers or the green bushes to avoid bullies.",
	["Sky"] = "Thanks for looking out for me.",
	["Shop Keeper"] = "The sneakers and the whistle are my best sellers.",
	["Principal"] = "A student who protects friends makes this school proud.",
}

function GameService.attendClass(player: Player, subject: string, room: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local period = ScheduleService.snapshot()
	if period.kind ~= "class" then
		Progress.notify(player, "There is no class right now. Check the timer at the top.", "warn")
		return
	end
	if period.subject ~= subject and period.room ~= room then
		Progress.notify(player, "Right now it is " .. period.name .. ". Go there instead.", "warn")
		return
	end
	if ScheduleService.didAttend(player.UserId) then
		Progress.notify(player, "You already joined this class.", "info")
		return
	end
	if profile.energy < Config.Class.energyCost then
		Progress.notify(player, "Too tired. Eat lunch or use a candy bar.", "warn")
		return
	end

	profile.energy -= Config.Class.energyCost
	profile.coins += Config.Class.coins
	profile.courage = Util.clamp(profile.courage + Config.Class.courage, 0, profile.maxCourage)
	if profile.grades[subject] then
		profile.grades[subject] = Util.clamp(profile.grades[subject] + Config.Class.gradeGain, 0, 100)
	end
	ScheduleService.markAttended(player.UserId)
	Progress.stat(profile, "classes")
	Progress.addXp(player, profile, Config.Class.xp)
	Progress.notify(player, (Config.SubjectNames[subject] or "Class") .. " done! You earned XP and coins.", "good")
	StoryService.onClass(player)
	Progress.push(player)
end

function GameService.lunch(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local period = ScheduleService.snapshot()
	if period.kind ~= "lunch" then
		Progress.notify(player, "The cafeteria serves food at lunch time.", "warn")
		return
	end
	local key = period.id .. tostring(period.day)
	if profile.lastLunch == key then
		Progress.notify(player, "You already ate lunch today.", "info")
		return
	end
	profile.lastLunch = key
	profile.energy = Util.clamp(profile.energy + Config.Lunch.energy, 0, profile.maxEnergy)
	profile.courage = Util.clamp(profile.courage + Config.Lunch.courage, 0, profile.maxCourage)
	Progress.stat(profile, "lunches")
	Progress.addXp(player, profile, Config.Lunch.xp)
	Progress.notify(player, "Lunch was good. Energy and courage restored.", "good")
	Progress.push(player)
end

function GameService.play(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local period = ScheduleService.snapshot()
	if period.kind == "class" and period.subject == "gym" then
		GameService.attendClass(player, "gym", "Playground")
		return
	end
	if profile.energy < Config.Playtime.energyCost then
		Progress.notify(player, "Too tired to play. Get some food first.", "warn")
		return
	end
	profile.energy -= Config.Playtime.energyCost
	profile.courage = Util.clamp(profile.courage + Config.Playtime.courage, 0, profile.maxCourage)
	Progress.addXp(player, profile, Config.Playtime.xp)
	Progress.notify(player, "You played outside and felt braver.", "good")
	Progress.push(player)
end

function GameService.talk(player: Player, npcName: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	if StoryService.onTalk(player, npcName) then
		return
	end
	Progress.notify(player, npcName .. ": " .. (CHAT[npcName] or "Have a good day!"), "info")
end

function GameService.study(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	if profile.energy < 10 then
		Progress.notify(player, "Too tired to study.", "warn")
		return
	end
	profile.energy -= 10
	for _, subject in Config.Subjects do
		profile.grades[subject] = Util.clamp(profile.grades[subject] + 0.6, 0, 100)
	end
	Progress.addXp(player, profile, 12)
	Progress.notify(player, "You studied in the library.", "good")
	Progress.push(player)
end

function GameService.rest(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	profile.energy = Util.clamp(profile.energy + 25, 0, profile.maxEnergy)
	profile.courage = Util.clamp(profile.courage + 25, 0, profile.maxCourage)
	Progress.notify(player, "You rested in the nurse office.", "good")
	Progress.push(player)
end

function GameService.locker(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	if os.clock() - (profile.lastLocker or 0) < 12 then
		Progress.notify(player, "Nothing else in the locker right now.", "info")
		return
	end
	profile.lastLocker = os.clock()
	profile.energy = Util.clamp(profile.energy + 8, 0, profile.maxEnergy)
	Progress.notify(player, "You grabbed your things. You can hide behind lockers too.", "good")
	Progress.push(player)
end

function GameService.pickup(player: Player, itemId: string)
	local profile = DataService.get(player)
	if not profile or not Config.Items[itemId] then
		return
	end
	Progress.give(player, profile, itemId)
	Progress.push(player)
end

function GameService.buy(player: Player, itemId: string)
	local profile = DataService.get(player)
	local item = Config.Items[itemId]
	if not profile or not item or item.price <= 0 then
		return
	end
	if item.kind == "gear" and profile.gear[itemId] then
		Progress.notify(player, "You already own that.", "info")
		return
	end
	if profile.coins < item.price then
		Progress.notify(player, "Not enough coins. Go to class to earn more.", "warn")
		return
	end
	profile.coins -= item.price
	Progress.give(player, profile, itemId)
	if item.kind == "gear" then
		Progress.applySpeed(player)
	end
	StoryService.onBuy(player, itemId)
	Progress.push(player)
end

function GameService.useItem(player: Player, itemId: string)
	local profile = DataService.get(player)
	local item = Config.Items[itemId]
	if not profile or not item then
		return
	end
	if item.kind == "gear" then
		Progress.notify(player, "Gear works automatically while you own it.", "info")
		return
	end
	if (profile.bag[itemId] or 0) < 1 then
		Progress.notify(player, "That item is not in your bag.", "warn")
		return
	end
	if item.kind == "encounter" then
		Progress.notify(player, "Save that for when a bully catches you.", "info")
		return
	end
	profile.bag[itemId] -= 1
	profile.energy = Util.clamp(profile.energy + (item.energy or 0), 0, profile.maxEnergy)
	profile.courage = Util.clamp(profile.courage + (item.courage or 0), 0, profile.maxCourage)
	if item.grades then
		for _, subject in Config.Subjects do
			profile.grades[subject] = Util.clamp(profile.grades[subject] + item.grades, 0, 100)
		end
	end
	if item.xp then
		Progress.addXp(player, profile, item.xp)
	end
	Progress.notify(player, "You used " .. item.name .. ".", "good")
	Progress.push(player)
end

function GameService.claimTask(player: Player, taskId: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local task
	for _, entry in Config.Tasks do
		if entry.id == taskId then
			task = entry
			break
		end
	end
	local state = profile.tasks[taskId]
	if not task or not state or state.claimed then
		return
	end
	if (state.progress or 0) < task.goal then
		Progress.notify(player, "That task is not finished yet.", "warn")
		return
	end
	state.claimed = true
	profile.coins += task.coins
	Progress.addXp(player, profile, task.xp)
	Progress.notify(player, "Task complete: " .. task.name, "good")
	Progress.push(player)
end

function GameService.missedClass(period, attendedMap)
	if period.kind ~= "class" then
		return
	end
	for _, player in Players:GetPlayers() do
		local profile = DataService.get(player)
		if profile and not attendedMap[player.UserId] then
			if period.subject and profile.grades[period.subject] then
				profile.grades[period.subject] =
					Util.clamp(profile.grades[period.subject] - Config.Class.missPenalty, 0, 100)
			end
			Progress.notify(player, "You missed " .. period.name .. ". Class is the easiest way to level up.", "warn")
			Progress.push(player)
		end
	end
end

local function handle(player: Player, source: Instance)
	local action = source:GetAttribute("Action")
	if action == "Class" then
		GameService.attendClass(player, source:GetAttribute("Subject"), source:GetAttribute("Room"))
	elseif action == "Lunch" then
		GameService.lunch(player)
	elseif action == "Play" then
		GameService.play(player)
	elseif action == "Talk" then
		GameService.talk(player, source:GetAttribute("Npc") or "Friend")
	elseif action == "Study" then
		GameService.study(player)
	elseif action == "Rest" then
		GameService.rest(player)
	elseif action == "Locker" then
		GameService.locker(player)
	elseif action == "Shop" then
		Remotes.get("OpenShop"):FireClient(player)
	elseif action == "Pickup" then
		local itemId = source:GetAttribute("Item")
		if typeof(itemId) == "string" then
			GameService.pickup(player, itemId)
			source:Destroy()
		end
	end
end

function GameService.bind()
	ScheduleService.onPeriodEnd(GameService.missedClass)

	local function connect(instance: Instance)
		local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
		if not prompt then
			return
		end
		prompt.Triggered:Connect(function(player)
			local ok, err = pcall(handle, player, instance)
			if not ok then
				warn("[BraveKid] interaction error:", err)
			end
		end)
	end

	for _, instance in CollectionService:GetTagged("Interact") do
		connect(instance)
	end
	CollectionService:GetInstanceAddedSignal("Interact"):Connect(connect)

	Remotes.get("GetProfile").OnServerEvent:Connect(function(player)
		if DataService.get(player) then
			Progress.push(player)
			Remotes.get("PeriodChanged"):FireClient(player, ScheduleService.snapshot())
		end
	end)
	Remotes.get("BuyItem").OnServerEvent:Connect(function(player, itemId)
		if typeof(itemId) == "string" then
			GameService.buy(player, itemId)
		end
	end)
	Remotes.get("UseItem").OnServerEvent:Connect(function(player, itemId)
		if typeof(itemId) == "string" then
			GameService.useItem(player, itemId)
		end
	end)
	Remotes.get("ClaimTask").OnServerEvent:Connect(function(player, taskId)
		if typeof(taskId) == "string" then
			GameService.claimTask(player, taskId)
		end
	end)
end

return GameService
