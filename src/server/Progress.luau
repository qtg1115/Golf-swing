local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))
local DataService = require(script.Parent.DataService)

local Progress = {}

function Progress.notify(player: Player, text: string, tone: string?)
	Remotes.get("Notify"):FireClient(player, {
		text = text,
		tone = tone or "info",
	})
end

function Progress.push(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	DataService.createLeaderstats(player, profile)
	Remotes.get("ProfileUpdated"):FireClient(player, DataService.publicProfile(profile))
	local chapter = Config.Story[profile.storyStep + 1] or Config.Story[#Config.Story]
	if chapter then
		Remotes.get("StoryUpdated"):FireClient(player, {
			step = profile.storyStep,
			title = chapter.title,
			goal = chapter.goal,
			done = chapter.done == true,
		})
	end
end

function Progress.bump(profile, statName: string, amount: number?)
	local add = amount or 1
	profile.stats[statName] = (profile.stats[statName] or 0) + add
	for _, quest in Config.Quests do
		if quest.stat == statName then
			local state = profile.quests[quest.id]
			if state and not state.claimed then
				local value = profile.stats[statName]
				if quest.stat == "storyStep" then
					value = profile.storyStep
				end
				state.progress = math.min(quest.goal, value)
			end
		end
	end
end

function Progress.addXp(player: Player, profile, amount: number)
	profile.xp += amount
	local needed = Util.xpForLevel(profile.level)
	local leveled = false
	while profile.xp >= needed do
		profile.xp -= needed
		profile.level += 1
		profile.coins += 15 + profile.level * 2
		profile.maxEnergy += 5
		profile.maxCourage += 6
		profile.energy = profile.maxEnergy
		profile.courage = profile.maxCourage
		profile.title = Util.titleForLevel(profile.level, Config.LevelTitles)
		leveled = true
		needed = Util.xpForLevel(profile.level)
	end
	if leveled then
		Progress.notify(player, string.format("레벨 %d! 칭호: %s", profile.level, profile.title), "good")
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
		local bonus = if profile.owned.sneakers then Config.Items.sneakers.speed else 0
		humanoid.WalkSpeed = Config.WalkSpeed + bonus
	end
end

function Progress.giveItem(player: Player, profile, itemId: string, amount: number?)
	local item = Config.Items[itemId]
	if not item then
		return
	end
	local count = amount or 1
	if item.kind == "equip" then
		profile.owned[itemId] = true
	else
		profile.inventory[itemId] = (profile.inventory[itemId] or 0) + count
	end
	Progress.notify(player, string.format("%s 을(를) 얻었어요!", item.name), "good")
end

return Progress
