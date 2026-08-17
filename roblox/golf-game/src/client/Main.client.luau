--!strict
-- 클라이언트 메인 스크립트: 파워 게이지 UI, 조준(카메라 방향), 스윙 입력 처리.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.GolfShared.Config)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local hitBallRemote = remotes:WaitForChild("HitBall") :: RemoteEvent
local notifyRemote = remotes:WaitForChild("Notify") :: RemoteEvent

-- ---------------------------------------------------------------------------
-- UI 생성 (코드로 직접 생성)
-- ---------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "GolfHud"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function makeLabel(name: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	return label
end

-- 안내 문구
local hint = makeLabel("Hint")
hint.AnchorPoint = Vector2.new(0.5, 0)
hint.Position = UDim2.new(0.5, 0, 0, 16)
hint.Size = UDim2.fromOffset(560, 28)
hint.TextScaled = true
hint.Text =
	"마우스 왼쪽 버튼(모바일: 화면 터치)을 길게 눌러 파워를 모으고, 떼서 공을 치세요!"

-- 알림 문구(홀인 등)
local notice = makeLabel("Notice")
notice.AnchorPoint = Vector2.new(0.5, 0.5)
notice.Position = UDim2.fromScale(0.5, 0.32)
notice.Size = UDim2.fromOffset(420, 60)
notice.TextScaled = true
notice.TextColor3 = Color3.fromRGB(120, 255, 160)
notice.Text = ""

-- 파워 게이지(하단 중앙)
local meterBg = Instance.new("Frame")
meterBg.Name = "PowerMeter"
meterBg.AnchorPoint = Vector2.new(0.5, 1)
meterBg.Position = UDim2.new(0.5, 0, 1, -40)
meterBg.Size = UDim2.fromOffset(320, 26)
meterBg.BackgroundColor3 = Color3.fromRGB(15, 25, 18)
meterBg.BackgroundTransparency = 0.25
meterBg.BorderSizePixel = 0
meterBg.Parent = gui

local meterCorner = Instance.new("UICorner")
meterCorner.CornerRadius = UDim.new(0, 8)
meterCorner.Parent = meterBg

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.AnchorPoint = Vector2.new(0, 0.5)
fill.Position = UDim2.new(0, 3, 0.5, 0)
fill.Size = UDim2.new(0, 0, 1, -6)
fill.BackgroundColor3 = Color3.fromRGB(74, 222, 128)
fill.BorderSizePixel = 0
fill.Parent = meterBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 6)
fillCorner.Parent = fill

local powerText = makeLabel("PowerText")
powerText.AnchorPoint = Vector2.new(0.5, 1)
powerText.Position = UDim2.new(0.5, 0, 1, -70)
powerText.Size = UDim2.fromOffset(200, 24)
powerText.TextScaled = true
powerText.Text = "파워 0%"

-- ---------------------------------------------------------------------------
-- 스윙(차징) 로직
-- ---------------------------------------------------------------------------
local charging = false
local chargeStart = 0

local function currentCharge(): number
	if not charging then
		return 0
	end
	local elapsed = os.clock() - chargeStart
	return math.clamp(elapsed / Config.Swing.ChargeTime, 0, 1)
end

local function aimDirection(): Vector3
	local camera = workspace.CurrentCamera
	local look = camera and camera.CFrame.LookVector or Vector3.new(0, 0, 1)
	-- 수평 방향만 사용해 조준하고, 발사각만큼 위로 띄웁니다.
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.001 then
		flat = Vector3.new(0, 0, 1)
	end
	flat = flat.Unit
	local angle = math.rad(Config.Swing.LaunchAngle)
	return (flat * math.cos(angle) + Vector3.new(0, 1, 0) * math.sin(angle)).Unit
end

local function beginCharge()
	if charging then
		return
	end
	charging = true
	chargeStart = os.clock()
end

local function releaseCharge()
	if not charging then
		return
	end
	charging = false
	local charge = math.clamp((os.clock() - chargeStart) / Config.Swing.ChargeTime, 0, 1)
	local power = Config.Swing.MinPower + (Config.Swing.MaxPower - Config.Swing.MinPower) * charge
	hitBallRemote:FireServer(aimDirection(), power)

	fill.Size = UDim2.new(0, 0, 1, -6)
	powerText.Text = "파워 0%"
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		beginCharge()
	end
end)

UserInputService.InputEnded:Connect(function(input, _gameProcessed)
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		releaseCharge()
	end
end)

-- 매 프레임 게이지 갱신.
RunService.RenderStepped:Connect(function()
	local charge = currentCharge()
	local usableWidth = meterBg.AbsoluteSize.X - 6
	fill.Size = UDim2.new(0, usableWidth * charge, 1, -6)
	-- 파워가 높아질수록 초록 -> 노랑 -> 빨강.
	fill.BackgroundColor3 = Color3.fromRGB(74, 222, 128):Lerp(Color3.fromRGB(248, 113, 113), charge)
	if charging then
		powerText.Text = string.format("파워 %d%%", math.floor(charge * 100 + 0.5))
	end
end)

notifyRemote.OnClientEvent:Connect(function(message: string)
	notice.Text = message
	task.delay(2.5, function()
		if notice.Text == message then
			notice.Text = ""
		end
	end)
end)
