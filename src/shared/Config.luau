local Config = {}

Config.GameName = "우리학교 대모험"
Config.SchoolName = "우리학교"
Config.PeriodSeconds = 50
Config.WalkSpeed = 16

Config.Starting = {
	coins = 40,
	energy = 100,
	maxEnergy = 100,
	courage = 80,
	maxCourage = 80,
	popularity = 8,
	xp = 0,
	level = 1,
	title = "신입생",
	storyStep = 0,
	classesThisStory = 0,
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
	korean = 55,
	math = 52,
	english = 54,
	science = 56,
	pe = 60,
	art = 58,
}

Config.LevelTitles = {
	{ min = 1, title = "신입생" },
	{ min = 3, title = "적응한 학생" },
	{ min = 5, title = "용기있는 친구" },
	{ min = 7, title = "반의 보호자" },
	{ min = 10, title = "학교 영웅" },
}

Config.Periods = {
	{ id = "homeroom", name = "조회", kind = "social", hint = "선생님이나 친구와 대화하세요" },
	{ id = "p1", name = "1교시 국어", kind = "class", subject = "korean", room = "Korean", hint = "국어 교실에서 수업을 들으면 레벨이 올라요" },
	{ id = "p2", name = "2교시 수학", kind = "class", subject = "math", room = "Math", hint = "수학 교실로 가세요" },
	{ id = "p3", name = "3교시 영어", kind = "class", subject = "english", room = "English", hint = "영어 교실에서 수업에 참여하세요" },
	{ id = "lunch", name = "점심시간", kind = "lunch", room = "Cafeteria", hint = "급식실에서 체력과 용기를 회복하세요" },
	{ id = "p4", name = "4교시 과학", kind = "class", subject = "science", room = "Science", hint = "과학실로 가세요" },
	{ id = "p5", name = "5교시 체육", kind = "class", subject = "pe", room = "Playground", hint = "운동장에서 몸을 단련하세요" },
	{ id = "p6", name = "6교시 미술", kind = "class", subject = "art", room = "Art", hint = "미술실에서 수업을 들으세요" },
	{ id = "after", name = "방과후", kind = "social", hint = "매점에서 아이템을 사거나 스토리를 진행하세요" },
}

Config.Class = {
	energyCost = 8,
	xpReward = 24,
	gradeGain = 2.2,
	coinReward = 8,
	courageGain = 4,
	skipGradePenalty = 1,
}

Config.Lunch = {
	energyRestore = 35,
	courageRestore = 20,
}

Config.Play = {
	energyCost = 6,
	xpReward = 10,
	courageGain = 3,
}

Config.Items = {
	chocolate = {
		id = "chocolate",
		name = "초콜릿",
		desc = "에너지를 25 회복합니다",
		kind = "consume",
		price = 10,
		energy = 25,
	},
	juice = {
		id = "juice",
		name = "용기 주스",
		desc = "용기를 30 회복합니다",
		kind = "consume",
		price = 14,
		courage = 30,
	},
	lunchbox = {
		id = "lunchbox",
		name = "도시락",
		desc = "에너지와 용기를 함께 채웁니다",
		kind = "consume",
		price = 22,
		energy = 40,
		courage = 15,
	},
	workbook = {
		id = "workbook",
		name = "참고서",
		desc = "성적과 경험치를 올립니다",
		kind = "consume",
		price = 28,
		allGrades = 2,
		xp = 18,
	},
	whistle = {
		id = "whistle",
		name = "호루라기",
		desc = "불리와 맞서기할 때 힘이 크게 올라갑니다",
		kind = "consume",
		price = 24,
		scare = true,
		powerBonus = 5,
	},
	friend_note = {
		id = "friend_note",
		name = "친구의 쪽지",
		desc = "불리에게 잡혔을 때 한 번 탈출할 수 있습니다",
		kind = "consume",
		price = 0,
		escape = true,
	},
	sneakers = {
		id = "sneakers",
		name = "운동화",
		desc = "더 빨리 달려 불리를 피할 수 있습니다",
		kind = "equip",
		price = 40,
		speed = 7,
	},
	courage_badge = {
		id = "courage_badge",
		name = "용기 배지",
		desc = "불리와 맞서기할 때 힘이 +3 됩니다",
		kind = "equip",
		price = 0,
		power = 3,
	},
}

Config.ShopOrder = { "chocolate", "juice", "lunchbox", "workbook", "whistle", "sneakers" }

Config.Story = {
	{
		id = 0,
		title = "첫 등교",
		goal = "정문 앞 김선생님과 대화하세요",
		npc = "김선생님",
		lines = {
			"새 전학생인가? 나는 담임 김선생님이야.",
			"이 학교엔 심술궂은 아이들이 있어. 피하거나, 준비가 되면 맞서렴.",
			"우선 사물함 쪽에 있는 민지를 만나보렴.",
		},
	},
	{
		id = 1,
		title = "친구의 경고",
		goal = "사물함 앞에서 민지를 만나세요",
		npc = "민지",
		give = "friend_note",
		lines = {
			"안녕! 너도 전학생이구나. 나는 민지야.",
			"복도에 왕딱이 있어. 보면 도망치거나 사물함 뒤에 숨어.",
			"이 쪽지를 줄게. 진짜 위험하면 써서 빠져나가.",
		},
	},
	{
		id = 2,
		title = "첫 불리",
		goal = "복도의 왕딱을 피하거나 물리치세요",
		bully = "wangtak",
		lines = {
			"잘했어! 불리를 피하는 것도, 맞서는 것도 용기야.",
			"수업 들으면 레벨이 올라. 두 번만 수업을 들어보자.",
		},
	},
	{
		id = 3,
		title = "수업으로 강해지기",
		goal = "수업을 2번 들으세요",
		needClasses = 2,
		lines = {
			"몸이 좀 든든해진 것 같지?",
			"매점에서 운동화를 사면 더 빨리 도망칠 수 있어.",
		},
	},
	{
		id = 4,
		title = "도망칠 준비",
		goal = "매점에서 운동화를 사세요",
		needItem = "sneakers",
		lines = {
			"이제 발이 가볍네!",
			"운동장에서 하늘이가 불리에게 괴롭힘당하고 있어. 가서 도와줘.",
		},
	},
	{
		id = 5,
		title = "친구를 구해라",
		goal = "운동장에서 하늘을 도와주세요",
		npc = "하늘",
		lines = {
			"고마워... 막내가 계속 공을 뺏어갔어.",
			"네가 와서 다행이야. 선생님께 보고하면 용기 배지를 주실 거야.",
		},
	},
	{
		id = 6,
		title = "용기 배지",
		goal = "교무실 근처 김선생님께 보고하세요",
		npc = "김선생님",
		give = "courage_badge",
		lines = {
			"친구를 도왔구나. 그게 진짜 센 거야.",
			"이 용기 배지를 받아. 이제 3학년 형에게 맞설 수 있을 거야.",
			"운동장 끝에서 기다리고 있다. 준비가 되면 가렴.",
		},
	},
	{
		id = 7,
		title = "마지막 대결",
		goal = "운동장에서 3학년 형을 물리치세요",
		bully = "hyung",
		lines = {
			"형도... 그냥 혼자여서 센 척한 거였어.",
			"네가 이겼어. 이제 이 학교는 조금 더 안전해질 거야.",
		},
	},
	{
		id = 8,
		title = "학교 영웅",
		goal = "이야기를 모두 끝냈어요!",
		done = true,
		lines = {
			"전학생이 학교 영웅이 됐어. 수업도 듣고, 친구도 지키고, 불리도 이겨 냈구나.",
			"원하면 계속 학교를 탐험해도 좋아!",
		},
	},
}

Config.Bullies = {
	{
		id = "wangtak",
		name = "왕딱",
		title = "복도 불리",
		power = 3,
		detect = 30,
		catch = 7,
		color = Color3.fromRGB(196, 64, 64),
		start = Vector3.new(-8, 4, -8),
		storyMin = 2,
		xp = 30,
		coins = 12,
	},
	{
		id = "chul",
		name = "철이",
		title = "급식실 불리",
		power = 5,
		detect = 28,
		catch = 7,
		color = Color3.fromRGB(168, 72, 40),
		start = Vector3.new(-90, 4, -8),
		storyMin = 3,
		xp = 40,
		coins = 16,
	},
	{
		id = "maknae",
		name = "막내",
		title = "운동장 불리",
		power = 6,
		detect = 32,
		catch = 8,
		color = Color3.fromRGB(120, 48, 80),
		start = Vector3.new(18, 4, -80),
		storyMin = 5,
		xp = 50,
		coins = 20,
	},
	{
		id = "hyung",
		name = "3학년 형",
		title = "제일 센 불리",
		power = 9,
		detect = 26,
		catch = 8,
		color = Color3.fromRGB(64, 36, 48),
		start = Vector3.new(0, 4, -110),
		storyMin = 7,
		boss = true,
		xp = 90,
		coins = 40,
	},
}

Config.Quests = {
	{
		id = "story",
		name = "메인 스토리",
		desc = "학교 이야기를 끝까지 진행하세요",
		goal = 8,
		stat = "storyStep",
		rewardCoins = 80,
		rewardXp = 80,
	},
	{
		id = "dodge2",
		name = "날쌘 전학생",
		desc = "불리를 2번 피하세요",
		goal = 2,
		stat = "bulliesDodged",
		rewardCoins = 20,
		rewardXp = 25,
	},
	{
		id = "fight1",
		name = "맞서는 용기",
		desc = "불리와 맞서 1번 이기세요",
		goal = 1,
		stat = "bulliesDefeated",
		rewardCoins = 25,
		rewardXp = 30,
	},
	{
		id = "attend2",
		name = "수업은 힘",
		desc = "수업을 2번 들으세요",
		goal = 2,
		stat = "classesAttended",
		rewardCoins = 15,
		rewardXp = 20,
	},
}

return Config
