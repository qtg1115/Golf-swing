local CharacterFactory = require(script.Parent.CharacterFactory)

local NPCService = {}

local NPCS = {
	{
		name = "김선생님",
		title = "담임선생님",
		color = Color3.fromRGB(72, 96, 168),
		start = Vector3.new(-6, 4, 50),
		interact = "Talk",
		actionText = "선생님과 대화",
		wander = false,
	},
	{
		name = "민지",
		title = "같은 반 친구",
		color = Color3.fromRGB(232, 132, 168),
		start = Vector3.new(-12, 4, 2),
		interact = "Talk",
		actionText = "민지와 대화",
		wander = false,
	},
	{
		name = "하늘",
		title = "운동장 친구",
		color = Color3.fromRGB(88, 176, 214),
		start = Vector3.new(-16, 4, -86),
		interact = "Talk",
		actionText = "하늘 도와주기",
		wander = false,
	},
	{
		name = "교장선생님",
		title = "교장",
		color = Color3.fromRGB(96, 84, 72),
		start = Vector3.new(108, 4, -28),
		interact = "Talk",
		actionText = "대화하기",
		wander = false,
	},
	{
		name = "매점아저씨",
		title = "매점",
		color = Color3.fromRGB(210, 140, 72),
		start = Vector3.new(22, 4, 52),
		interact = "Talk",
		actionText = "대화하기",
		wander = false,
	},
}

function NPCService.start()
	for _, info in NPCS do
		CharacterFactory.create(info)
	end
end

return NPCService
