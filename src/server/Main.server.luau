local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local SchoolBuilder = require(script.Parent.SchoolBuilder)
local DataService = require(script.Parent.DataService)
local ScheduleService = require(script.Parent.ScheduleService)
local GameService = require(script.Parent.GameService)
local NPCService = require(script.Parent.NPCService)

Remotes.ensure()
SchoolBuilder.build()
DataService.bind()
GameService.bind()
ScheduleService.start()
NPCService.start()

local function setupPlayer(player: Player)
	DataService.load(player)
	Remotes.get("ProfileUpdated"):FireClient(player, DataService.publicProfile(DataService.get(player)))
	Remotes.get("PeriodChanged"):FireClient(player, ScheduleService.snapshot())
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

print("[스쿨 시뮬레이터] 서버가 시작되었습니다.")
