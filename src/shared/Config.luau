local Config = {}

Config.GameName = "스쿨 시뮬레이터"
Config.SchoolName = "우리학교"

Config.PeriodSeconds = 45

Config.Starting = {
	coins = 80,
	energy = 100,
	maxEnergy = 100,
	popularity = 15,
	xp = 0,
	level = 1,
}

Config.GradeKeys = { "korean", "math", "english", "science", "pe", "art" }

Config.SubjectNames = {
	korean = "국어",
	math = "수학",
	english = "영어",
	science = "과학",
	pe = "체육",
	art = "미술",
}

Config.StartingGrades = {
	korean = 62,
	math = 58,
	english = 60,
	science = 61,
	pe = 70,
	art = 64,
}

Config.Periods = {
	{ id = "homeroom", name = "조회", kind = "social", hint = "친구들과 인사하고 하루를 시작하세요" },
	{ id = "p1", name = "1교시 국어", kind = "class", subject = "korean", room = "Korean", hint = "국어 교실에 앉아 수업을 들으세요" },
	{ id = "p2", name = "2교시 수학", kind = "class", subject = "math", room = "Math", hint = "수학 교실로 이동하세요" },
	{ id = "p3", name = "3교시 영어", kind = "class", subject = "english", room = "English", hint = "영어 교실에서 수업에 참여하세요" },
	{ id = "lunch", name = "점심시간", kind = "lunch", room = "Cafeteria", hint = "급식실에서 밥을 먹고 에너지를 회복하세요" },
	{ id = "p4", name = "4교시 과학", kind = "class", subject = "science", room = "Science", hint = "과학실로 가세요" },
	{ id = "p5", name = "5교시 체육", kind = "class", subject = "pe", room = "Playground", hint = "운동장에서 체육 활동에 참여하세요" },
	{ id = "p6", name = "6교시 미술", kind = "class", subject = "art", room = "Art", hint = "미술실에서 창작 활동을 하세요" },
	{ id = "after", name = "방과후", kind = "social", hint = "상점을 이용하거나 퀘스트를 완료하세요" },
}

Config.Class = {
	energyCost = 8,
	xpReward = 18,
	gradeGain = 2.4,
	coinReward = 6,
	popularityGain = 1,
	skipGradePenalty = 1.2,
	skipPopularityPenalty = 1,
}

Config.Lunch = {
	energyRestore = 40,
	coinCost = 0,
	popularityGain = 2,
	oncePerPeriod = true,
}

Config.Play = {
	energyCost = 6,
	popularityGain = 4,
	xpReward = 8,
}

Config.Talk = {
	popularityGain = 3,
	xpReward = 5,
	cooldown = 20,
}

Config.LevelXp = 100

Config.ShopItems = {
	{
		id = "snack",
		name = "초콜릿",
		desc = "에너지를 바로 채워 줍니다",
		price = 12,
		energy = 22,
	},
	{
		id = "drink",
		name = "인기 음료",
		desc = "마시는 순간 인기가 조금 오릅니다",
		price = 18,
		energy = 10,
		popularity = 6,
	},
	{
		id = "workbook",
		name = "참고서",
		desc = "모든 과목 성적이 조금 오릅니다",
		price = 35,
		allGrades = 2,
	},
	{
		id = "uniform",
		name = "새 교복",
		desc = "깔끔한 교복으로 인기가 크게 오릅니다",
		price = 70,
		popularity = 14,
		title = "모범생",
	},
}

Config.Quests = {
	{
		id = "attend3",
		name = "성실한 학생",
		desc = "오늘 수업을 3번 들으세요",
		goal = 3,
		stat = "classesAttended",
		rewardCoins = 25,
		rewardXp = 30,
	},
	{
		id = "lunch1",
		name = "급식 타임",
		desc = "급식실에서 한 끼를 드세요",
		goal = 1,
		stat = "lunchesEaten",
		rewardCoins = 10,
		rewardXp = 12,
	},
	{
		id = "talk2",
		name = "인사하기",
		desc = "NPC와 2번 대화하세요",
		goal = 2,
		stat = "talks",
		rewardCoins = 12,
		rewardXp = 15,
		rewardPopularity = 4,
	},
	{
		id = "play1",
		name = "운동장 한 바퀴",
		desc = "운동장에서 한 번 놀아 보세요",
		goal = 1,
		stat = "plays",
		rewardCoins = 10,
		rewardXp = 12,
	},
}

return Config
