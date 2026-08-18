local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.Progress)

local StoryService = {}

function StoryService.current(profile)
	return Config.Story[profile.story + 1]
end

function StoryService.say(player: Player, speaker: string, lines)
	Remotes.get("Dialogue"):FireClient(player, { speaker = speaker, lines = lines })
end

function StoryService.advance(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local chapter = StoryService.current(profile)
	if not chapter or chapter.final then
		return
	end

	if chapter.grant then
		Progress.give(player, profile, chapter.grant)
	end

	profile.story += 1
	profile.stats.story = profile.story
	profile.storyClasses = 0
	Progress.syncTasks(profile)
	Progress.addXp(player, profile, 40)
	StoryService.say(player, chapter.speaker or "Story", chapter.lines or {})

	local nextChapter = StoryService.current(profile)
	if nextChapter then
		Progress.notify(player, "New goal: " .. nextChapter.goal, "good")
	end
	Progress.push(player)
	StoryService.checkPassive(player)
end

-- Handles chapters that are already satisfied (e.g. the player already owns the item).
function StoryService.checkPassive(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local chapter = StoryService.current(profile)
	if not chapter then
		return
	end
	if chapter.item and (profile.gear[chapter.item] or (profile.bag[chapter.item] or 0) > 0) then
		StoryService.advance(player)
	end
end

function StoryService.onTalk(player: Player, npcName: string): boolean
	local profile = DataService.get(player)
	if not profile then
		return false
	end
	local chapter = StoryService.current(profile)
	if chapter and chapter.npc == npcName then
		if npcName == "Sky" then
			Progress.stat(profile, "friendsHelped")
		end
		StoryService.advance(player)
		return true
	end
	return false
end

function StoryService.onBully(player: Player, bullyId: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local chapter = StoryService.current(profile)
	if chapter and chapter.bully == bullyId then
		StoryService.advance(player)
	end
end

function StoryService.onClass(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local chapter = StoryService.current(profile)
	if not chapter or not chapter.classes then
		return
	end
	profile.storyClasses += 1
	if profile.storyClasses >= chapter.classes then
		StoryService.advance(player)
	else
		Progress.notify(
			player,
			string.format("Class %d of %d done. One more to continue the story!", profile.storyClasses, chapter.classes),
			"info"
		)
	end
end

function StoryService.onBuy(player: Player, itemId: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local chapter = StoryService.current(profile)
	if chapter and chapter.item == itemId then
		StoryService.advance(player)
	end
end

function StoryService.intro(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	if profile.story == 0 then
		StoryService.say(player, "You", {
			"Today is my first day at this school.",
			"Go to class to level up, and watch out for the bullies.",
			"You can run away, hide, or stand up to them.",
			"Let's find Mr. Park at the front gate.",
		})
	end
	Progress.push(player)
	StoryService.checkPassive(player)
end

return StoryService
