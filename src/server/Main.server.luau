local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
SchoolBuilder.build()
DataService.bind()
GameService.bind()
ScheduleService.start()
NPCService.start()
BullyService.start()

local function setupPlayer(player: Player)
	DataService.load(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		Progress.applySpeed(player)
	end)
	if player.Character then
		Progress.applySpeed(player)
	end
	StoryService.intro(player)
	Remotes.get("PeriodChanged"):FireClient(player, ScheduleService.snapshot())
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

print("[우리학교 대모험] 서버가 시작되었습니다.")
