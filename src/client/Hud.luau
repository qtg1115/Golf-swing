local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local Hud = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local profile
local period
local shopOpen = false

local function corner(parent: Instance, radius: number)
	local ui = Instance.new("UICorner")
	ui.CornerRadius = UDim.new(0, radius)
	ui.Parent = parent
	return ui
end

local function pad(parent: Instance, pixels: number)
	local ui = Instance.new("UIPadding")
	ui.PaddingTop = UDim.new(0, pixels)
	ui.PaddingBottom = UDim.new(0, pixels)
	ui.PaddingLeft = UDim.new(0, pixels)
	ui.PaddingRight = UDim.new(0, pixels)
	ui.Parent = parent
end

local function label(parent: Instance, text: string, size: number, color: Color3, bold: boolean?): TextLabel
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.Size = UDim2.fromScale(1, 0)
	item.AutomaticSize = Enum.AutomaticSize.Y
	item.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	item.TextSize = size
	item.TextColor3 = color
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextWrapped = true
	item.Text = text
	item.Parent = parent
	return item
end

function Hud.mount()
	local gui = Instance.new("ScreenGui")
	gui.Name = "SchoolHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local top = Instance.new("Frame")
	top.Name = "PeriodBar"
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 18)
	top.Size = UDim2.fromOffset(420, 72)
	top.BackgroundColor3 = Color3.fromRGB(28, 40, 62)
	top.BackgroundTransparency = 0.08
	top.Parent = gui
	corner(top, 16)

	local periodTitle = label(top, "조회", 22, Color3.fromRGB(255, 224, 140), true)
	periodTitle.Position = UDim2.fromOffset(18, 10)
	periodTitle.Size = UDim2.new(1, -36, 0, 28)

	local periodHint = label(top, "학교에 오신 것을 환영합니다", 14, Color3.fromRGB(220, 228, 240))
	periodHint.Position = UDim2.fromOffset(18, 40)
	periodHint.Size = UDim2.new(1, -36, 0, 22)

	local stats = Instance.new("Frame")
	stats.Name = "Stats"
	stats.Position = UDim2.fromOffset(18, 18)
	stats.Size = UDim2.fromOffset(230, 168)
	stats.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
	stats.BackgroundTransparency = 0.12
	stats.Parent = gui
	corner(stats, 14)
	pad(stats, 14)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 6)
	layout.Parent = stats

	local statsTitle = label(stats, "학생증", 18, Color3.fromRGB(255, 224, 140), true)
	local levelLabel = label(stats, "1레벨 신입생", 15, Color3.new(1, 1, 1), true)
	local coinLabel = label(stats, "코인 80", 14, Color3.fromRGB(255, 214, 120))
	local energyLabel = label(stats, "에너지 100/100", 14, Color3.fromRGB(140, 220, 170))
	local popLabel = label(stats, "인기 15", 14, Color3.fromRGB(255, 170, 190))
	local gpaLabel = label(stats, "평균 성적 62", 14, Color3.fromRGB(170, 200, 255))

	local quest = Instance.new("Frame")
	quest.Name = "Quests"
	quest.Position = UDim2.fromOffset(18, 198)
	quest.Size = UDim2.fromOffset(230, 220)
	quest.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
	quest.BackgroundTransparency = 0.12
	quest.Parent = gui
	corner(quest, 14)
	pad(quest, 14)

	local questLayout = Instance.new("UIListLayout")
	questLayout.Padding = UDim.new(0, 6)
	questLayout.Parent = quest
	label(quest, "오늘 할 일", 18, Color3.fromRGB(255, 224, 140), true)

	local questLabels = {}
	for _, info in Config.Quests do
		local row = Instance.new("TextButton")
		row.Name = info.id
		row.BackgroundColor3 = Color3.fromRGB(42, 58, 86)
		row.AutoButtonColor = true
		row.Size = UDim2.new(1, 0, 0, 36)
		row.Font = Enum.Font.Gotham
		row.TextSize = 13
		row.TextColor3 = Color3.new(1, 1, 1)
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = info.name
		row.Parent = quest
		corner(row, 8)
		pad(row, 8)
		questLabels[info.id] = row
		row.MouseButton1Click:Connect(function()
			Remotes.get("ClaimQuest"):FireServer(info.id)
		end)
	end

	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.AnchorPoint = Vector2.new(0.5, 1)
	toast.Position = UDim2.new(0.5, 0, 1, -28)
	toast.Size = UDim2.fromOffset(520, 48)
	toast.BackgroundColor3 = Color3.fromRGB(28, 40, 62)
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 16
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.TextWrapped = true
	toast.Visible = false
	toast.Parent = gui
	corner(toast, 12)

	local shop = Instance.new("Frame")
	shop.Name = "Shop"
	shop.AnchorPoint = Vector2.new(0.5, 0.5)
	shop.Position = UDim2.fromScale(0.5, 0.5)
	shop.Size = UDim2.fromOffset(420, 430)
	shop.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
	shop.Visible = false
	shop.Parent = gui
	corner(shop, 18)
	pad(shop, 18)

	local shopLayout = Instance.new("UIListLayout")
	shopLayout.Padding = UDim.new(0, 8)
	shopLayout.Parent = shop

	label(shop, "매점", 24, Color3.fromRGB(255, 224, 140), true)
	label(shop, "코인으로 간식과 아이템을 사세요", 14, Color3.fromRGB(210, 218, 230))

	for _, item in Config.ShopItems do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 58)
		button.BackgroundColor3 = Color3.fromRGB(48, 64, 96)
		button.Font = Enum.Font.Gotham
		button.TextSize = 15
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Text = string.format("%s  ·  %d코인\n%s", item.name, item.price, item.desc)
		button.Parent = shop
		corner(button, 10)
		button.MouseButton1Click:Connect(function()
			Remotes.get("BuyItem"):FireServer(item.id)
		end)
	end

	local closeShop = Instance.new("TextButton")
	closeShop.Size = UDim2.new(1, 0, 0, 40)
	closeShop.BackgroundColor3 = Color3.fromRGB(180, 72, 80)
	closeShop.Font = Enum.Font.GothamBold
	closeShop.TextSize = 16
	closeShop.TextColor3 = Color3.new(1, 1, 1)
	closeShop.Text = "닫기"
	closeShop.Parent = shop
	corner(closeShop, 10)
	closeShop.MouseButton1Click:Connect(function()
		shop.Visible = false
		shopOpen = false
	end)

	local help = Instance.new("TextLabel")
	help.AnchorPoint = Vector2.new(1, 1)
	help.Position = UDim2.new(1, -18, 1, -18)
	help.Size = UDim2.fromOffset(280, 88)
	help.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
	help.BackgroundTransparency = 0.12
	help.Font = Enum.Font.Gotham
	help.TextSize = 13
	help.TextColor3 = Color3.fromRGB(230, 234, 244)
	help.TextXAlignment = Enum.TextXAlignment.Left
	help.TextYAlignment = Enum.TextYAlignment.Top
	help.TextWrapped = true
	help.Text = "E 키 또는 근접 버튼으로 상호작용\n수업 시간엔 해당 교실로\n점심엔 급식실, 체육은 운동장"
	help.Parent = gui
	corner(help, 12)
	pad(help, 12)

	local function showToast(text: string, tone: string)
		if tone == "shop" then
			shopOpen = not shopOpen
			shop.Visible = shopOpen
			return
		end
		toast.Text = text
		toast.BackgroundColor3 = if tone == "good"
			then Color3.fromRGB(36, 110, 78)
			elseif tone == "warn" then Color3.fromRGB(150, 78, 48)
			else Color3.fromRGB(28, 40, 62)
		toast.Visible = true
		toast.BackgroundTransparency = 0.05
		task.delay(3.2, function()
			if toast.Text == text then
				TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
				task.wait(0.25)
				if toast.Text == text then
					toast.Visible = false
					toast.BackgroundTransparency = 0.05
				end
			end
		end)
	end

	local function refreshProfile()
		if not profile then
			return
		end
		levelLabel.Text = string.format("%d레벨 %s", profile.level, profile.title)
		coinLabel.Text = string.format("코인 %d", profile.coins)
		energyLabel.Text = string.format("에너지 %d/%d", profile.energy, profile.maxEnergy)
		popLabel.Text = string.format("인기 %d", profile.popularity)
		gpaLabel.Text = string.format("평균 성적 %.1f", profile.gpa)
		for _, info in Config.Quests do
			local state = profile.quests[info.id]
			local row = questLabels[info.id]
			if state and row then
				if state.claimed then
					row.Text = string.format("%s  완료", info.name)
					row.BackgroundColor3 = Color3.fromRGB(46, 96, 70)
				else
					row.Text = string.format("%s  %d/%d  (클릭 보상)", info.name, state.progress or 0, info.goal)
				end
			end
		end
	end

	local function refreshPeriod()
		if not period then
			return
		end
		periodTitle.Text = string.format("%s  ·  %s", period.name, Util.formatTime(period.remaining or 0))
		periodHint.Text = period.hint or ""
	end

	Remotes.get("ProfileUpdated").OnClientEvent:Connect(function(data)
		profile = data
		refreshProfile()
	end)

	Remotes.get("PeriodChanged").OnClientEvent:Connect(function(data)
		period = data
		refreshPeriod()
		showToast(string.format("%s 시작! %s", data.name, data.hint or ""), "info")
	end)

	Remotes.get("Notify").OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" then
			showToast(payload.text, payload.tone)
		end
	end)

	task.spawn(function()
		while gui.Parent do
			if period then
				period.remaining = math.max(0, (period.endsAt or 0) - workspace:GetServerTimeNow())
				refreshPeriod()
			end
			task.wait(0.25)
		end
	end)

	Remotes.get("GetProfile"):FireServer()
end

return Hud
