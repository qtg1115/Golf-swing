local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local DataService = require(script.Parent.DataService)
local ScheduleService = require(script.Parent.ScheduleService)

local GameService = {}

local function notify(player: Player, text: string, tone: string?)
	Remotes.get("Notify"):FireClient(player, {
		text = text,
		tone = tone or "info",
	})
end

local function push(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	DataService.createLeaderstats(player, profile)
	Remotes.get("ProfileUpdated"):FireClient(player, DataService.publicProfile(profile))
end

local function addXp(player: Player, profile, amount: number)
	profile.xp += amount
	local needed = Util.xpForLevel(profile.level)
	while profile.xp >= needed do
		profile.xp -= needed
		profile.level += 1
		profile.coins += 20
		profile.maxEnergy += 4
		profile.energy = profile.maxEnergy
		notify(player, string.format("레벨 %d 달성! 용돈과 체력이 올랐어요", profile.level), "good")
		needed = Util.xpForLevel(profile.level)
	end
end

local function bumpQuest(profile, statName: string)
	profile.stats[statName] = (profile.stats[statName] or 0) + 1
	for _, quest in Config.Quests do
		if quest.stat == statName then
			local state = profile.quests[quest.id]
			if state and not state.claimed then
				state.progress = math.min(quest.goal, profile.stats[statName])
			end
		end
	end
end

local function changeGrade(profile, subject: string, delta: number)
	if not profile.grades[subject] then
		return
	end
	profile.grades[subject] = Util.clamp(profile.grades[subject] + delta, 0, 100)
end

function GameService.attendClass(player: Player, subject: string, roomId: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end

	local period = ScheduleService.snapshot()
	if period.kind ~= "class" then
		notify(player, "지금은 수업 시간이 아니에요. 시간표를 확인하세요!", "warn")
		return
	end
	if period.room ~= roomId and period.subject ~= subject then
		notify(player, string.format("지금은 %s 시간이에요. 해당 장소로 이동하세요.", period.name), "warn")
		return
	end
	if ScheduleService.didAttend(player.UserId) then
		notify(player, "이번 교시 수업은 이미 들었어요.", "info")
		return
	end
	if profile.energy < Config.Class.energyCost then
		notify(player, "에너지가 부족해요. 급식을 먹거나 매점에서 간식을 사세요.", "warn")
		return
	end

	profile.energy -= Config.Class.energyCost
	profile.coins += Config.Class.coinReward
	profile.popularity += Config.Class.popularityGain
	changeGrade(profile, subject, Config.Class.gradeGain)
	addXp(player, profile, Config.Class.xpReward)
	ScheduleService.markAttended(player.UserId)
	bumpQuest(profile, "classesAttended")
	notify(
		player,
		string.format("%s 수업을 들었어요! 성적 +%.1f", Config.SubjectNames[subject] or subject, Config.Class.gradeGain),
		"good"
	)
	push(player)
end

function GameService.eatLunch(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end

	local period = ScheduleService.snapshot()
	if period.kind ~= "lunch" then
		notify(player, "급식은 점심시간에만 먹을 수 있어요.", "warn")
		return
	end
	if profile.lastLunchPeriod == period.id .. period.day then
		notify(player, "이번 점심은 이미 먹었어요.", "info")
		return
	end

	profile.lastLunchPeriod = period.id .. period.day
	profile.energy = Util.clamp(profile.energy + Config.Lunch.energyRestore, 0, profile.maxEnergy)
	profile.popularity += Config.Lunch.popularityGain
	addXp(player, profile, 8)
	bumpQuest(profile, "lunchesEaten")
	notify(player, "맛있는 급식을 먹었어요! 에너지가 회복됐습니다.", "good")
	push(player)
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
		notify(player, "놀기엔 에너지가 부족해요.", "warn")
		return
	end

	profile.energy -= Config.Play.energyCost
	profile.popularity += Config.Play.popularityGain
	addXp(player, profile, Config.Play.xpReward)
	bumpQuest(profile, "plays")
	notify(player, "운동장에서 뛰어 놀았어요! 인기가 올랐습니다.", "good")
	push(player)
end

function GameService.talk(player: Player, npcName: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end

	local now = os.clock()
	if now - (profile.lastTalkAt or 0) < Config.Talk.cooldown then
		notify(player, "조금 뒤에 다시 인사해 보세요.", "info")
		return
	end

	profile.lastTalkAt = now
	profile.popularity += Config.Talk.popularityGain
	addXp(player, profile, Config.Talk.xpReward)
	bumpQuest(profile, "talks")

	local lines = {
		교장선생님 = "오늘도 성실하게 생활하렴. 성적과 인기 둘 다 중요하다.",
		김선생 = "수업 종이 울리면 제시간에 교실로 오너라.",
		이수진 = "점심에 급식실에서 같이 먹자!",
		박도윤 = "방과후에 매점에서 간식 먹을래?",
		최하늘 = "체육 시간엔 운동장으로 가야 해!",
	}
	notify(player, string.format("%s: %s", npcName, lines[npcName] or "안녕! 오늘 학교 생활 재밌다."), "info")
	push(player)
end

function GameService.study(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	if profile.energy < 10 then
		notify(player, "자습하기엔 너무 피곤해요.", "warn")
		return
	end

	profile.energy -= 10
	for _, key in Config.GradeKeys do
		changeGrade(profile, key, 0.6)
	end
	addXp(player, profile, 10)
	notify(player, "도서관에서 자습했어요. 전체 성적이 조금 올랐습니다.", "good")
	push(player)
end

function GameService.locker(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local now = os.clock()
	if now - (profile.lastLockerAt or 0) < 15 then
		notify(player, "사물함은 잠시 뒤에 다시 열 수 있어요.", "info")
		return
	end
	profile.lastLockerAt = now
	profile.energy = Util.clamp(profile.energy + 6, 0, profile.maxEnergy)
	notify(player, "사물함에서 물과 준비물을 챙겼어요. 에너지 +6", "good")
	push(player)
end

function GameService.buy(player: Player, itemId: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end

	local item
	for _, entry in Config.ShopItems do
		if entry.id == itemId then
			item = entry
			break
		end
	end
	if not item then
		notify(player, "없는 상품이에요.", "warn")
		return
	end
	if profile.owned[item.id] and item.id == "uniform" then
		notify(player, "이미 새 교복을 가지고 있어요.", "info")
		return
	end
	if profile.coins < item.price then
		notify(player, "코인이 부족해요.", "warn")
		return
	end

	profile.coins -= item.price
	if item.energy then
		profile.energy = Util.clamp(profile.energy + item.energy, 0, profile.maxEnergy)
	end
	if item.popularity then
		profile.popularity += item.popularity
	end
	if item.allGrades then
		for _, key in Config.GradeKeys do
			changeGrade(profile, key, item.allGrades)
		end
	end
	if item.title then
		profile.title = item.title
	end
	profile.owned[item.id] = true
	notify(player, string.format("%s을(를) 구매했어요!", item.name), "good")
	push(player)
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
	if not quest or not state then
		return
	end
	if state.claimed then
		notify(player, "이미 보상을 받았어요.", "info")
		return
	end
	if (state.progress or 0) < quest.goal then
		notify(player, "아직 퀘스트를 끝내지 못했어요.", "warn")
		return
	end

	state.claimed = true
	profile.coins += quest.rewardCoins
	addXp(player, profile, quest.rewardXp)
	if quest.rewardPopularity then
		profile.popularity += quest.rewardPopularity
	end
	notify(player, string.format("퀘스트 완료: %s", quest.name), "good")
	push(player)
end

function GameService.handleSkip(period, attendedMap)
	if period.kind ~= "class" then
		return
	end

	for _, player in Players:GetPlayers() do
		local profile = DataService.get(player)
		if profile and not attendedMap[player.UserId] then
			profile.stats.skipped += 1
			profile.popularity = math.max(0, profile.popularity - Config.Class.skipPopularityPenalty)
			if period.subject then
				changeGrade(profile, period.subject, -Config.Class.skipGradePenalty)
			end
			notify(player, string.format("%s를 빠졌어요. 성적과 인기가 조금 내려갔습니다.", period.name), "warn")
			push(player)
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
		local profile = DataService.get(player)
		if profile then
			Remotes.get("ProfileUpdated"):FireClient(player, DataService.publicProfile(profile))
			Remotes.get("PeriodChanged"):FireClient(player, ScheduleService.snapshot())
		end
	end)

	Remotes.get("BuyItem").OnServerEvent:Connect(function(player, itemId)
		if typeof(itemId) == "string" then
			GameService.buy(player, itemId)
		end
	end)

	Remotes.get("ClaimQuest").OnServerEvent:Connect(function(player, questId)
		if typeof(questId) == "string" then
			GameService.claimQuest(player, questId)
		end
	end)
end

return GameService
