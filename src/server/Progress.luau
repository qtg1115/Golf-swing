local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))
local DataService = require(script.Parent.DataService)

local Progress = {}

function Progress.notify(player: Player, text: string, tone: string?)
	Remotes.get("Notify"):FireClient(player, { text = text, tone = tone or "info" })
end

function Progress.push(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	DataService.leaderstats(player, profile)
	Remotes.get("ProfileUpdated"):FireClient(player, DataService.toClient(profile))

	local chapter = Config.Story[profile.story + 1] or Config.Story[#Config.Story]
	Remotes.get("StoryUpdated"):FireClient(player, {
		step = profile.story,
		total = #Config.Story - 1,
		title = chapter.title,
		goal = chapter.goal,
	})
end

function Progress.stat(profile, name: string, amount: number?)
	profile.stats[name] = (profile.stats[name] or 0) + (amount or 1)
	Progress.syncTasks(profile)
end

function Progress.syncTasks(profile)
	for _, task in Config.Tasks do
		local state = profile.tasks[task.id]
		if state and not state.claimed then
			local value = if task.stat == "story" then profile.story else (profile.stats[task.stat] or 0)
			state.progress = math.min(task.goal, value)
		end
	end
end

function Progress.addXp(player: Player, profile, amount: number)
	profile.xp += amount
	local needed = Util.xpForLevel(profile.level)
	local gained = false
	while profile.xp >= needed do
		profile.xp -= needed
		profile.level += 1
		profile.coins += 15 + profile.level * 2
		profile.maxEnergy += 5
		profile.maxCourage += 6
		profile.energy = profile.maxEnergy
		profile.courage = profile.maxCourage
		profile.title = Util.titleForLevel(profile.level, Config.Titles)
		gained = true
		needed = Util.xpForLevel(profile.level)
	end
	if gained then
		Progress.notify(player, string.format("Level %d! You are now a %s", profile.level, profile.title), "good")
		Progress.applySpeed(player)
	end
end

function Progress.applySpeed(player: Player)
	local profile = DataService.get(player)
	local character = player.Character
	if not profile or not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local bonus = if profile.gear.sneakers then Config.Items.sneakers.speed else 0
		humanoid.WalkSpeed = Config.WalkSpeed + bonus
	end
end

function Progress.give(player: Player, profile, itemId: string, quiet: boolean?)
	local item = Config.Items[itemId]
	if not item then
		return
	end
	if item.kind == "gear" then
		profile.gear[itemId] = true
	else
		profile.bag[itemId] = (profile.bag[itemId] or 0) + 1
	end
	if not quiet then
		Progress.notify(player, "You got: " .. item.name, "good")
	end
end

return Progress
