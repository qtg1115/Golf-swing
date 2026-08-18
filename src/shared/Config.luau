local Config = {}

Config.GameName = "Brave Kid: School Story"
Config.PeriodSeconds = 55
Config.WalkSpeed = 16

Config.Start = {
	coins = 40,
	energy = 100,
	maxEnergy = 100,
	courage = 80,
	maxCourage = 80,
	xp = 0,
	level = 1,
	title = "New Kid",
}

Config.Subjects = { "reading", "math", "science", "art", "gym" }

Config.SubjectNames = {
	reading = "Reading",
	math = "Math",
	science = "Science",
	art = "Art",
	gym = "Gym",
}

Config.StartGrades = {
	reading = 55,
	math = 52,
	science = 56,
	art = 58,
	gym = 60,
}

Config.Titles = {
	{ min = 1, title = "New Kid" },
	{ min = 3, title = "Brave Student" },
	{ min = 5, title = "Hall Defender" },
	{ min = 7, title = "Class Hero" },
	{ min = 10, title = "School Legend" },
}

Config.Periods = {
	{ id = "morning", name = "Morning Meeting", kind = "free", hint = "Talk to people and follow your story goal" },
	{ id = "p1", name = "Period 1: Reading", kind = "class", subject = "reading", room = "Reading", hint = "Go to the Reading room and sit down" },
	{ id = "p2", name = "Period 2: Math", kind = "class", subject = "math", room = "Math", hint = "Go to the Math room" },
	{ id = "lunch", name = "Lunch", kind = "lunch", room = "Cafeteria", hint = "Eat in the cafeteria to refill energy and courage" },
	{ id = "p3", name = "Period 3: Science", kind = "class", subject = "science", room = "Science", hint = "Go to the Science room" },
	{ id = "p4", name = "Period 4: Gym", kind = "class", subject = "gym", room = "Playground", hint = "Go outside to the playground" },
	{ id = "p5", name = "Period 5: Art", kind = "class", subject = "art", room = "Art", hint = "Go to the Art room" },
	{ id = "after", name = "After School", kind = "free", hint = "Shop, explore, or finish your story goal" },
}

Config.Class = {
	energyCost = 8,
	xp = 26,
	gradeGain = 2.5,
	coins = 10,
	courage = 5,
	missPenalty = 1,
}

Config.Lunch = {
	energy = 40,
	courage = 20,
	xp = 10,
}

Config.Playtime = {
	energyCost = 6,
	xp = 10,
	courage = 4,
}

Config.Items = {
	candy = {
		id = "candy",
		name = "Candy Bar",
		info = "Restores 25 energy",
		kind = "use",
		price = 10,
		energy = 25,
	},
	juice = {
		id = "juice",
		name = "Brave Juice",
		info = "Restores 30 courage",
		kind = "use",
		price = 14,
		courage = 30,
	},
	lunchbox = {
		id = "lunchbox",
		name = "Lunch Box",
		info = "Restores energy and courage",
		kind = "use",
		price = 22,
		energy = 40,
		courage = 15,
	},
	book = {
		id = "book",
		name = "Study Book",
		info = "Raises grades and gives XP",
		kind = "use",
		price = 28,
		grades = 2,
		xp = 20,
	},
	whistle = {
		id = "whistle",
		name = "Whistle",
		info = "Use in an encounter: +5 stand-up power",
		kind = "encounter",
		price = 24,
		power = 5,
	},
	note = {
		id = "note",
		name = "Friend's Note",
		info = "Use in an encounter to escape safely",
		kind = "encounter",
		price = 0,
		escape = true,
	},
	sneakers = {
		id = "sneakers",
		name = "Fast Sneakers",
		info = "You run faster and escape more easily",
		kind = "gear",
		price = 40,
		speed = 8,
	},
	badge = {
		id = "badge",
		name = "Courage Badge",
		info = "+3 stand-up power, always on",
		kind = "gear",
		price = 0,
		power = 3,
	},
}

Config.ShopItems = { "candy", "juice", "lunchbox", "book", "whistle", "sneakers" }

-- Story chapters. The player always sees the goal of the current chapter.
Config.Story = {
	{
		title = "First Day",
		goal = "Talk to Mr. Park at the front gate",
		npc = "Mr. Park",
		speaker = "Mr. Park",
		lines = {
			"You must be the new student. I am Mr. Park.",
			"Some kids here push others around. You can run, hide, or stand up to them.",
			"Go find Mia by the lockers. She will help you.",
		},
	},
	{
		title = "A Friend's Warning",
		goal = "Find Mia near the lockers",
		npc = "Mia",
		speaker = "Mia",
		grant = "note",
		lines = {
			"Hi! You are new here. I am Mia.",
			"Watch out for Rex in the hallway. Run away or hide behind the green bushes.",
			"Take my note. If you are in trouble, use it to get away.",
		},
	},
	{
		title = "Meeting Rex",
		goal = "Escape from Rex or stand up to him",
		bully = "rex",
		speaker = "Mia",
		lines = {
			"You did it! Running and hiding are brave too.",
			"Go to class to get stronger. Two classes should do it.",
		},
	},
	{
		title = "Get Stronger",
		goal = "Attend 2 classes to level up",
		classes = 2,
		speaker = "Mr. Park",
		lines = {
			"You look stronger already.",
			"Buy the fast sneakers at the school shop so you can get away quickly.",
		},
	},
	{
		title = "Fast Feet",
		goal = "Buy the Fast Sneakers at the shop",
		item = "sneakers",
		speaker = "Shop Keeper",
		lines = {
			"Those sneakers are quick!",
			"Sky is being bullied at the playground. Please go help.",
		},
	},
	{
		title = "Help a Friend",
		goal = "Go to the playground and help Sky",
		npc = "Sky",
		speaker = "Sky",
		lines = {
			"Thank you. Bruno kept taking my ball.",
			"Tell Mr. Park what happened. He has something for you.",
		},
	},
	{
		title = "The Courage Badge",
		goal = "Report back to Mr. Park",
		npc = "Mr. Park",
		speaker = "Mr. Park",
		grant = "badge",
		lines = {
			"You helped a friend. That is real strength.",
			"Take this Courage Badge. Now you are ready for Max.",
			"He waits at the far end of the playground.",
		},
	},
	{
		title = "The Big One",
		goal = "Face Max at the far playground",
		bully = "max",
		speaker = "Max",
		lines = {
			"Okay, okay. I only acted tough because I was alone.",
			"You win. This school is safer now.",
		},
	},
	{
		title = "School Hero",
		goal = "You finished the story! Keep exploring.",
		final = true,
		speaker = "Mr. Park",
		lines = {
			"The new kid became the school hero.",
			"Keep going to class and helping friends!",
		},
	},
}

Config.Bullies = {
	{
		id = "rex",
		name = "Rex",
		role = "Hallway Bully",
		power = 3,
		sight = 34,
		catch = 8,
		speed = 11,
		color = Color3.fromRGB(196, 64, 64),
		home = Vector3.new(-10, 5, -6),
		range = 34,
		unlock = 2,
		xp = 30,
		coins = 12,
	},
	{
		id = "vic",
		name = "Vic",
		role = "Cafeteria Bully",
		power = 5,
		sight = 32,
		catch = 8,
		speed = 11,
		color = Color3.fromRGB(168, 72, 40),
		home = Vector3.new(-92, 5, -6),
		range = 26,
		unlock = 3,
		xp = 40,
		coins = 16,
	},
	{
		id = "bruno",
		name = "Bruno",
		role = "Playground Bully",
		power = 6,
		sight = 34,
		catch = 8,
		speed = 12,
		color = Color3.fromRGB(120, 48, 80),
		home = Vector3.new(24, 5, -78),
		range = 30,
		unlock = 5,
		xp = 50,
		coins = 20,
	},
	{
		id = "max",
		name = "Max",
		role = "Toughest Bully",
		power = 9,
		sight = 30,
		catch = 8,
		speed = 12,
		color = Color3.fromRGB(72, 40, 52),
		home = Vector3.new(0, 5, -112),
		range = 24,
		unlock = 7,
		boss = true,
		xp = 90,
		coins = 40,
	},
}

Config.Tasks = {
	{
		id = "story",
		name = "Main Story",
		info = "Finish the school story",
		goal = 8,
		stat = "story",
		coins = 80,
		xp = 90,
	},
	{
		id = "escapes",
		name = "Quick Feet",
		info = "Escape bullies 2 times",
		goal = 2,
		stat = "escapes",
		coins = 20,
		xp = 25,
	},
	{
		id = "standups",
		name = "Stand Tall",
		info = "Stand up to a bully once",
		goal = 1,
		stat = "standups",
		coins = 25,
		xp = 30,
	},
	{
		id = "classes",
		name = "Good Student",
		info = "Attend 2 classes",
		goal = 2,
		stat = "classes",
		coins = 15,
		xp = 20,
	},
}

return Config
