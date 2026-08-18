local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local SchoolBuilder = require(script.Parent.SchoolBuilder)
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.Progress)
local ScheduleService = require(script.Parent.ScheduleService)
local GameService = require(script.Parent.GameService)
local NPCService = require(script.Parent.NPCService)
local BullyService = require(script.Parent.BullyService)
local StoryService = require(script.Parent.StoryService)

local START_POSITION = Vector3.new(0, 8, 60)

Remotes.ensure()

local built = false
do
	local ok, err = pcall(SchoolBuilder.build)
	built = ok
	if not ok then
		warn("[BraveKid] Map build failed, using the backup ground:", err)
	end
end

-- The place file ships with a plain ground and spawn so nobody ever falls into
-- the void while the campus is still being created. Once the campus exists the
-- placeholders are no longer needed.
if built then
	for _, name in { "SafeGround", "SafeSpawn" } do
		local placeholder = workspace:FindFirstChild(name)
		if placeholder then
			placeholder:Destroy()
		end
	end
end

local function startSpot(): CFrame
	local campus = workspace:FindFirstChild("SchoolCampus")
	local pad = campus and campus:FindFirstChild("SchoolSpawn")
	if pad and pad:IsA("BasePart") then
		return pad.CFrame + Vector3.new(0, 5, 0)
	end
	return CFrame.new(START_POSITION)
end

local function startSystem(name: string, callback)
	local ok, err = pcall(callback)
	if not ok then
		warn("[BraveKid] " .. name .. " failed to start:", err)
	end
end

startSystem("DataService", DataService.bind)
startSystem("GameService", GameService.bind)
startSystem("ScheduleService", ScheduleService.start)
startSystem("NPCService", NPCService.start)
startSystem("BullyService", BullyService.start)

local function onCharacter(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root and root:IsA("BasePart") then
		root.CFrame = startSpot()
	end
	Progress.applySpeed(player)
end

local function setupPlayer(player: Player)
	local ok, err = pcall(function()
		DataService.load(player)
	end)
	if not ok then
		warn("[BraveKid] Could not load profile:", err)
		return
	end

	player.CharacterAdded:Connect(function(character)
		task.spawn(onCharacter, player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end

	task.spawn(function()
		StoryService.intro(player)
		Remotes.get("PeriodChanged"):FireClient(player, ScheduleService.snapshot())
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

-- Safety net: anyone who ends up under the map is put back at the gate.
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") and root.Position.Y < -30 then
				root.AssemblyLinearVelocity = Vector3.zero
				root.CFrame = startSpot()
			end
		end
	end
end)

print("[BraveKid] School is ready. Walk to Mr. Park at the front gate.")
