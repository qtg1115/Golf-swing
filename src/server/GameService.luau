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

local FLAVOR = {
	김선생님 = "수업 종이 울리면 교실로 가렴. 레벨이 오르면 불리에게 맞설 수 있어.",
	민지 = "사물함 뒤에 숨으면 복도 불리를 피할 수 있어!",
	하늘 = "운동장 쪽이 아직 무서워. 네가 있어 줘서 고마워.",
	교장선생님 = "친구를 지키는 학생이 우리 학교의 자랑이지.",
	매점아저씨 = "운동화랑 호루라기가 잘 나가. 불리 대비에 좋지.",
}

function GameService.attendClass(player: Player, subject: string, roomId: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local period = ScheduleService.snapshot()
	if period.kind ~= "class" then
		Progress.notify(player, "지금은 수업 시간이 아니에요.", "warn")
		return
	end
	if period.room ~= roomId and period.subject ~= subject then
		Progress.notify(player, string.format("지금은 %s 이에요. 그곳으로 가세요.", period.name), "warn")
		return
	end
	if ScheduleService.didAttend(player.UserId) then
		Progress.notify(player, "이번 교시 수업은 이미 들었어요.", "info")
		return
	end
	if profile.energy < Config.Class.energyCost then
		Progress.notify(player, "에너지가 부족해요. 급식이나 초콜릿을 챙기세요.", "warn")
		return
	end

	profile.energy -= Config.Class.energyCost
	profile.coins += Config.Class.coinReward
	profile.courage = Util.clamp(profile.courage + Config.Class.courageGain, 0, profile.maxCourage)
	if profile.grades[subject] then
		profile.grades[subject] = Util.clamp(profile.grades[subject] + Config.Class.gradeGain, 0, 100)
	end
	Progress.addXp(player, profile, Config.Class.xpReward)
	ScheduleService.markAttended(player.UserId)
	Progress.bump(profile, "classesAttended")
	Progress.notify(player, string.format("%s 수업 완료! 경험치와 용기가 올랐어요.", Config.SubjectNames[subject] or subject), "good")
	StoryService.onClass(player)
	Progress.push(player)
end

function GameService.eatLunch(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local period = ScheduleService.snapshot()
	if period.kind ~= "lunch" then
		Progress.notify(player, "급식은 점심시간에만 먹을 수 있어요.", "warn")
		return
	end
	if profile.lastLunchPeriod == period.id .. period.day then
		Progress.notify(player, "이번 점심은 이미 먹었어요.", "info")
		return
	end
	profile.lastLunchPeriod = period.id .. period.day
	profile.energy = Util.clamp(profile.energy + Config.Lunch.energyRestore, 0, profile.maxEnergy)
	profile.courage = Util.clamp(profile.courage + Config.Lunch.courageRestore, 0, profile.maxCourage)
	Progress.addXp(player, profile, 10)
	Progress.bump(profile, "lunchesEaten")
	Progress.notify(player, "급식을 먹었어요. 에너지와 용기가 회복됐습니다.", "good")
	Progress.push(player)
end

function GameService.play(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local period = ScheduleService.snapshot()
	if period.kind == "class" and period.subject == "pe" then
		GameService.attendClass(player, "pe", "Playground")
		return
	end
	if profile.energy < Config.Play.energyCost then
		Progress.notify(player, "놀기엔 에너지가 부족해요.", "warn")
		return
	end
	profile.energy -= Config.Play.energyCost
	profile.courage = Util.clamp(profile.courage + Config.Play.courageGain, 0, profile.maxCourage)
	Progress.addXp(player, profile, Config.Play.xpReward)
	Progress.bump(profile, "plays")
	Progress.notify(player, "운동장에서 몸을 풀었어요.", "good")
	Progress.push(player)
end

function GameService.talk(player: Player, npcName: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local now = os.clock()
	if StoryService.onTalk(player, npcName) then
		Progress.bump(profile, "talks")
		return
	end
	if now - (profile.lastTalkAt or 0) < 8 then
		Progress.notify(player, "조금 뒤에 다시 이야기해 보세요.", "info")
		return
	end
	profile.lastTalkAt = now
	Progress.bump(profile, "talks")
	Progress.addXp(player, profile, 4)
	Progress.notify(player, string.format("%s: %s", npcName, FLAVOR[npcName] or "오늘도 힘내!"), "info")
	Progress.push(player)
end

function GameService.study(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	if profile.energy < 10 then
		Progress.notify(player, "자습하기엔 너무 피곤해요.", "warn")
		return
	end
	profile.energy -= 10
	for _, key in Config.GradeKeys do
		profile.grades[key] = Util.clamp(profile.grades[key] + 0.5, 0, 100)
	end
	Progress.addXp(player, profile, 12)
	Progress.notify(player, "도서관에서 자습했어요.", "good")
	Progress.push(player)
end

function GameService.locker(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	if os.clock() - (profile.lastLockerAt or 0) < 12 then
		Progress.notify(player, "사물함은 잠시 뒤에 다시 열 수 있어요.", "info")
		return
	end
	profile.lastLockerAt = os.clock()
	profile.energy = Util.clamp(profile.energy + 8, 0, profile.maxEnergy)
	Progress.notify(player, "사물함에서 준비물을 챙겼어요. 뒤에 숨으면 불리를 피할 수 있어요.", "good")
	Progress.push(player)
end

function GameService.pickup(player: Player, itemId: string)
	local profile = DataService.get(player)
	if not profile or not Config.Items[itemId] then
		return
	end
	Progress.giveItem(player, profile, itemId, 1)
	Progress.push(player)
end

function GameService.buy(player: Player, itemId: string)
	local profile = DataService.get(player)
	local item = Config.Items[itemId]
	if not profile or not item or item.price <= 0 then
		return
	end
	if item.kind == "equip" and profile.owned[itemId] then
		Progress.notify(player, "이미 가지고 있어요.", "info")
		return
	end
	if profile.coins < item.price then
		Progress.notify(player, "코인이 부족해요. 수업을 들으면 용돈을 받아요.", "warn")
		return
	end
	profile.coins -= item.price
	Progress.giveItem(player, profile, itemId, 1)
	if item.kind == "equip" then
		Progress.applySpeed(player)
	end
	StoryService.onBuy(player, itemId)
	StoryService.syncOwned(player)
	Progress.push(player)
end

function GameService.useItem(player: Player, itemId: string)
	local profile = DataService.get(player)
	local item = Config.Items[itemId]
	if not profile or not item then
		return
	end
	if item.kind == "equip" then
		Progress.notify(player, "장착 아이템은 가지고 있으면 자동으로 효과가 있어요.", "info")
		return
	end
	if (profile.inventory[itemId] or 0) < 1 then
		Progress.notify(player, "가방에 그 아이템이 없어요.", "warn")
		return
	end
	if item.escape or item.scare then
		Progress.notify(player, "이 아이템은 불리와 마주쳤을 때 쓰세요.", "info")
		return
	end
	profile.inventory[itemId] -= 1
	if item.energy then
		profile.energy = Util.clamp(profile.energy + item.energy, 0, profile.maxEnergy)
	end
	if item.courage then
		profile.courage = Util.clamp(profile.courage + item.courage, 0, profile.maxCourage)
	end
	if item.allGrades then
		for _, key in Config.GradeKeys do
			profile.grades[key] = Util.clamp(profile.grades[key] + item.allGrades, 0, 100)
		end
	end
	if item.xp then
		Progress.addXp(player, profile, item.xp)
	end
	Progress.notify(player, item.name .. " 을(를) 사용했어요.", "good")
	Progress.push(player)
end

function GameService.claimQuest(player: Player, questId: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local quest
	for _, entry in Config.Quests do
		if entry.id == questId then
			quest = entry
			break
		end
	end
	local state = profile.quests[questId]
	if not quest or not state or state.claimed then
		return
	end
	if (state.progress or 0) < quest.goal then
		Progress.notify(player, "아직 끝나지 않은 할 일이에요.", "warn")
		return
	end
	state.claimed = true
	profile.coins += quest.rewardCoins
	Progress.addXp(player, profile, quest.rewardXp)
	Progress.notify(player, "할 일 보상: " .. quest.name, "good")
	Progress.push(player)
end

function GameService.handleSkip(period, attendedMap)
	if period.kind ~= "class" then
		return
	end
	for _, player in Players:GetPlayers() do
		local profile = DataService.get(player)
		if profile and not attendedMap[player.UserId] then
			Progress.bump(profile, "skipped")
			if period.subject and profile.grades[period.subject] then
				profile.grades[period.subject] = Util.clamp(profile.grades[period.subject] - Config.Class.skipGradePenalty, 0, 100)
			end
			Progress.notify(player, period.name .. " 를 빠졌어요. 수업은 레벨 올리는 제일 쉬운 방법이에요.", "warn")
			Progress.push(player)
		end
	end
end

function GameService.bind()
	ScheduleService.onPeriodEnded(GameService.handleSkip)

	local function bindPrompt(instance: Instance)
		local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
		if not prompt then
			return
		end
		prompt.Triggered:Connect(function(player)
			local interact = instance:GetAttribute("Interact")
			if interact == "AttendClass" then
				GameService.attendClass(player, instance:GetAttribute("Subject"), instance:GetAttribute("RoomId"))
			elseif interact == "EatLunch" then
				GameService.eatLunch(player)
			elseif interact == "Play" then
				GameService.play(player)
			elseif interact == "Talk" then
				GameService.talk(player, instance:GetAttribute("NpcName") or "친구")
			elseif interact == "Study" then
				GameService.study(player)
			elseif interact == "Locker" then
				GameService.locker(player)
			elseif interact == "Pickup" then
				local itemId = instance:GetAttribute("ItemId")
				if typeof(itemId) == "string" then
					GameService.pickup(player, itemId)
					instance:Destroy()
				end
			elseif interact == "OpenShop" then
				Remotes.get("Notify"):FireClient(player, { text = "SHOP_OPEN", tone = "shop" })
			end
		end)
	end

	for _, instance in CollectionService:GetTagged("SchoolInteract") do
		bindPrompt(instance)
	end
	CollectionService:GetInstanceAddedSignal("SchoolInteract"):Connect(bindPrompt)

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
	Remotes.get("ClaimQuest").OnServerEvent:Connect(function(player, questId)
		if typeof(questId) == "string" then
			GameService.claimQuest(player, questId)
		end
	end)
end

return GameService
