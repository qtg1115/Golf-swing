--!strict
-- 서버 메인 스크립트: 코스 생성, 플레이어별 공 관리, 스윙 처리, 홀인 판정.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.GolfShared.Config)
local CourseBuilder = require(script.Parent:WaitForChild("CourseBuilder"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local hitBallRemote = remotes:WaitForChild("HitBall") :: RemoteEvent
local notifyRemote = remotes:WaitForChild("Notify") :: RemoteEvent

CourseBuilder.build(workspace)

type PlayerState = {
	ball: Part,
	holes: IntValue,
	strokes: IntValue,
	scored: boolean,
}

local states: { [Player]: PlayerState } = {}

local function ballStartPosition(): Vector3
	return Config.TeeGround + Vector3.new(0, Config.Ball.StartHeight, 0)
end

local function spawnBall(player: Player): Part
	local ball = Instance.new("Part")
	ball.Name = "GolfBall_" .. player.UserId
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(Config.Ball.Radius * 2, Config.Ball.Radius * 2, Config.Ball.Radius * 2)
	ball.Position = ballStartPosition()
	ball.Color = Color3.fromRGB(245, 245, 245)
	ball.Material = Enum.Material.SmoothPlastic
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.35, 0.55)
	ball.Parent = workspace
	return ball
end

local function resetBall(state: PlayerState)
	local ball = state.ball
	if not ball.Parent then
		return
	end
	ball.AssemblyLinearVelocity = Vector3.zero
	ball.AssemblyAngularVelocity = Vector3.zero
	ball.CFrame = CFrame.new(ballStartPosition())
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local holes = Instance.new("IntValue")
	holes.Name = "Holes"
	holes.Parent = leaderstats

	local strokes = Instance.new("IntValue")
	strokes.Name = "Strokes"
	strokes.Parent = leaderstats

	leaderstats.Parent = player

	states[player] = {
		ball = spawnBall(player),
		holes = holes,
		strokes = strokes,
		scored = false,
	}
end)

Players.PlayerRemoving:Connect(function(player)
	local state = states[player]
	if state then
		state.ball:Destroy()
		states[player] = nil
	end
end)

hitBallRemote.OnServerEvent:Connect(function(player, direction, power)
	local state = states[player]
	if not state then
		return
	end
	-- 클라이언트가 보낸 값 검증(악용 방지).
	if typeof(direction) ~= "Vector3" or typeof(power) ~= "number" then
		return
	end
	if direction.Magnitude < 0.001 or power ~= power then
		return
	end
	-- 공이 거의 멈춰 있을 때만 칠 수 있습니다.
	if state.ball.AssemblyLinearVelocity.Magnitude > Config.Ball.StopSpeed then
		return
	end

	local clamped = math.clamp(power, Config.Swing.MinPower, Config.Swing.MaxPower)
	state.ball.AssemblyLinearVelocity = direction.Unit * clamped
	state.strokes.Value += 1
end)

-- 매 프레임 홀인/낙하 판정.
RunService.Heartbeat:Connect(function()
	local holePos = Config.Hole.Position
	for player, state in pairs(states) do
		local ball = state.ball
		if not ball.Parent then
			continue
		end

		-- 코스 밖으로 떨어졌으면 티로 복귀.
		if ball.Position.Y < Config.Ball.ResetY then
			resetBall(state)
			continue
		end

		if state.scored then
			continue
		end

		-- 수평 거리(XZ)로 홀 근처인지 판정.
		local dx = ball.Position.X - holePos.X
		local dz = ball.Position.Z - holePos.Z
		local flatDistance = math.sqrt(dx * dx + dz * dz)
		local speed = ball.AssemblyLinearVelocity.Magnitude

		if
			flatDistance < Config.Hole.Radius
			and speed < Config.Hole.CaptureSpeed
			and ball.Position.Y < 6
		then
			state.scored = true
			state.holes.Value += 1
			local strokeCount = state.strokes.Value
			state.strokes.Value = 0
			notifyRemote:FireClient(player, string.format("⛳ 홀인! (%d타)", strokeCount))

			task.delay(0.8, function()
				if states[player] == state then
					resetBall(state)
					state.scored = false
				end
			end)
		end
	end
end)
