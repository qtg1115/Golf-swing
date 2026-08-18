local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 맵이 생기기 전에 캐릭터가 보이드로 떨어지지 않게 합니다.
Players.CharacterAutoLoads = false

local function ensureSafeGround()
	if not workspace:FindFirstChild("SafeGround") then
		local ground = Instance.new("Part")
		ground.Name = "SafeGround"
		ground.Anchored = true
		ground.Size = Vector3.new(520, 4, 400)
		ground.CFrame = CFrame.new(0, 0, -10)
		ground.Color = Color3.fromRGB(92, 168, 96)
		ground.Material = Enum.Material.Grass
		ground.Parent = workspace
	end

	if not workspace:FindFirstChild("SafeSpawn") then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "SafeSpawn"
		spawn.Anchored = true
		spawn.Duration = 0
		spawn.Neutral = true
		spawn.Size = Vector3.new(16, 1, 16)
		spawn.CFrame = CFrame.new(0, 3.5, 58)
		spawn.Color = Color3.fromRGB(92, 168, 220)
		spawn.Material = Enum.Material.SmoothPlastic
		spawn.Parent = workspace
	end
end

local function spawnCFrame(): CFrame
	local school = workspace:FindFirstChild("SchoolCampus")
	local schoolSpawn = school and school:FindFirstChild("SchoolSpawn")
	if schoolSpawn and schoolSpawn:IsA("BasePart") then
		return schoolSpawn.CFrame + Vector3.new(0, 4, 0)
	end
	local safe = workspace:FindFirstChild("SafeSpawn")
	if safe and safe:IsA("BasePart") then
		return safe.CFrame + Vector3.new(0, 4, 0)
	end
	return CFrame.new(0, 8, 58)
end

local function putOnCampus(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = spawnCFrame()
	end
end

ensureSafeGround()

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local SchoolBuilder = require(script.Parent.SchoolBuilder)
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.Progress)
local ScheduleService = require(script.Parent.ScheduleService)
local GameService = require(script.Parent.GameService)
local NPCService = require(script.Parent.NPCService)
local BullyService = require(script.Parent.BullyService)
local StoryService = require(script.Parent.StoryService)

Remotes.ensure()

local built, buildError = pcall(function()
	SchoolBuilder.build()
end)
if not built then
	warn("[우리학교 대모험] 맵 생성 실패: ", buildError)
	ensureSafeGround()
end

DataService.bind()
GameService.bind()
ScheduleService.start()
NPCService.start()
BullyService.start()

local function setupPlayer(player: Player)
	DataService.load(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		putOnCampus(character)
		Progress.applySpeed(player)
	end)
	StoryService.intro(player)
	Remotes.get("PeriodChanged"):FireClient(player, ScheduleService.snapshot())
	player:LoadCharacter()
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

print("[우리학교 대모험] 서버가 시작되었습니다. 정문 스폰에서 시작하세요.")
