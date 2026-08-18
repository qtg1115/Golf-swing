local ActorFactory = require(script.Parent.ActorFactory)

local NPCService = {}

local NPCS = {
	{
		name = "Mr. Park",
		role = "Teacher",
		color = Color3.fromRGB(72, 96, 168),
		position = Vector3.new(-10, 6, 62),
	},
	{
		name = "Mia",
		role = "Classmate",
		color = Color3.fromRGB(232, 132, 168),
		position = Vector3.new(-18, 6, 6),
	},
	{
		name = "Sky",
		role = "Playground Friend",
		color = Color3.fromRGB(88, 176, 214),
		position = Vector3.new(-20, 6, -84),
	},
	{
		name = "Shop Keeper",
		role = "School Shop",
		color = Color3.fromRGB(214, 148, 76),
		position = Vector3.new(20, 6, 52),
	},
	{
		name = "Principal",
		role = "Principal",
		color = Color3.fromRGB(104, 88, 76),
		position = Vector3.new(96, 6, 26),
	},
}

function NPCService.start()
	local campus = workspace:FindFirstChild("SchoolCampus") or workspace
	for _, info in NPCS do
		ActorFactory.create({
			name = info.name,
			role = info.role,
			color = info.color,
			position = info.position,
			action = "Talk",
			prompt = "Talk to " .. info.name,
			labelColor = Color3.fromRGB(190, 235, 255),
			parent = campus,
		})
	end
end

return NPCService
