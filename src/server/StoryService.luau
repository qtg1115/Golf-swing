local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.Progress)

local StoryService = {}

function StoryService.chapter(step: number)
	return Config.Story[step + 1]
end

function StoryService.sendDialogue(player: Player, speaker: string, lines)
	Remotes.get("Dialogue"):FireClient(player, {
		speaker = speaker,
		lines = lines,
	})
end

function StoryService.advance(player: Player, reason: string?)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local current = StoryService.chapter(profile.storyStep)
	if not current or current.done then
		return
	end

	if current.give then
		Progress.giveItem(player, profile, current.give, 1)
	end

	profile.storyStep += 1
	profile.stats.storyStep = profile.storyStep
	profile.classesThisStory = 0
	Progress.bump(profile, "storyStep", 0)
	if profile.quests.story then
		profile.quests.story.progress = math.min(8, profile.storyStep)
	end
	Progress.addXp(player, profile, 35)
	Progress.notify(player, string.format("스토리 진행: %s", current.title), "good")

	local nextChapter = StoryService.chapter(profile.storyStep)
	if nextChapter and current.lines then
		StoryService.sendDialogue(player, reason or "이야기", current.lines)
	end
	Progress.push(player)
	StoryService.syncOwned(player)
end

function StoryService.onTalk(player: Player, npcName: string): boolean
	local profile = DataService.get(player)
	if not profile then
		return false
	end
	local chapter = StoryService.chapter(profile.storyStep)
	if chapter and chapter.npc == npcName then
		if npcName == "하늘" then
			Progress.bump(profile, "friendsHelped")
		end
		StoryService.advance(player, npcName)
		return true
	end
	return false
end

function StoryService.onBullyResolved(player: Player, bullyId: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local chapter = StoryService.chapter(profile.storyStep)
	if chapter and chapter.bully == bullyId then
		StoryService.advance(player, "이야기")
	end
end

function StoryService.onClass(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local chapter = StoryService.chapter(profile.storyStep)
	if chapter and chapter.needClasses then
		profile.classesThisStory += 1
		if profile.classesThisStory >= chapter.needClasses then
			StoryService.advance(player, "김선생님")
		else
			Progress.notify(
				player,
				string.format("수업 %d/%d 완료. 한 번 더 들으면 다음 이야기로!", profile.classesThisStory, chapter.needClasses),
				"info"
			)
		end
	end
end

function StoryService.onBuy(player: Player, itemId: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local chapter = StoryService.chapter(profile.storyStep)
	if chapter and chapter.needItem == itemId then
		StoryService.advance(player, "매점아저씨")
	end
end

function StoryService.syncOwned(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local chapter = StoryService.chapter(profile.storyStep)
	if chapter and chapter.needItem and (profile.owned[chapter.needItem] or (profile.inventory[chapter.needItem] or 0) > 0) then
		StoryService.advance(player, "매점아저씨")
	end
end

function StoryService.intro(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	if profile.storyStep == 0 then
		StoryService.sendDialogue(player, "나", {
			"오늘은 우리학교 첫날이야.",
			"수업을 들으면서 레벨을 올리고, 나쁜 아이들(불리)을 피하거나 이겨야 해.",
			"정문 쪽 김선생님께 가 보자.",
		})
	end
	Progress.push(player)
	StoryService.syncOwned(player)
end

return StoryService
