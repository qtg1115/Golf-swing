local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local Hud = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local profile
local period
local story
local shopOpen = false
local bagOpen = false

local function corner(parent: Instance, radius: number)
	local ui = Instance.new("UICorner")
	ui.CornerRadius = UDim.new(0, radius)
	ui.Parent = parent
end

local function pad(parent: Instance, pixels: number)
	local ui = Instance.new("UIPadding")
	ui.PaddingTop = UDim.new(0, pixels)
	ui.PaddingBottom = UDim.new(0, pixels)
	ui.PaddingLeft = UDim.new(0, pixels)
	ui.PaddingRight = UDim.new(0, pixels)
	ui.Parent = parent
end

local function textButton(parent: Instance, caption: string, color: Color3, size: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.BackgroundColor3 = color
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = caption
	button.AutoButtonColor = true
	button.Parent = parent
	corner(button, 10)
	return button
end

function Hud.mount()
	local gui = Instance.new("ScreenGui")
	gui.Name = "SchoolHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local top = Instance.new("Frame")
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 14)
	top.Size = UDim2.fromOffset(460, 78)
	top.BackgroundColor3 = Color3.fromRGB(24, 36, 58)
	top.Parent = gui
	corner(top, 16)

	local periodTitle = Instance.new("TextLabel")
	periodTitle.BackgroundTransparency = 1
	periodTitle.Position = UDim2.fromOffset(16, 8)
	periodTitle.Size = UDim2.new(1, -32, 0, 28)
	periodTitle.Font = Enum.Font.GothamBold
	periodTitle.TextSize = 20
	periodTitle.TextColor3 = Color3.fromRGB(255, 224, 140)
	periodTitle.TextXAlignment = Enum.TextXAlignment.Left
	periodTitle.Text = "우리학교 대모험"
	periodTitle.Parent = top

	local periodHint = Instance.new("TextLabel")
	periodHint.BackgroundTransparency = 1
	periodHint.Position = UDim2.fromOffset(16, 38)
	periodHint.Size = UDim2.new(1, -32, 0, 28)
	periodHint.Font = Enum.Font.Gotham
	periodHint.TextSize = 14
	periodHint.TextColor3 = Color3.fromRGB(220, 228, 240)
	periodHint.TextXAlignment = Enum.TextXAlignment.Left
	periodHint.TextWrapped = true
	periodHint.Text = "정문에서 김선생님을 만나세요"
	periodHint.Parent = top

	local left = Instance.new("Frame")
	left.Position = UDim2.fromOffset(16, 104)
	left.Size = UDim2.fromOffset(250, 210)
	left.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
	left.BackgroundTransparency = 0.08
	left.Parent = gui
	corner(left, 14)
	pad(left, 12)

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.Padding = UDim.new(0, 5)
	leftLayout.Parent = left

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = "1레벨 신입생"
	nameLabel.Parent = left

	local xpBack = Instance.new("Frame")
	xpBack.Size = UDim2.new(1, 0, 0, 12)
	xpBack.BackgroundColor3 = Color3.fromRGB(40, 52, 72)
	xpBack.Parent = left
	corner(xpBack, 6)
	local xpFill = Instance.new("Frame")
	xpFill.Size = UDim2.fromScale(0, 1)
	xpFill.BackgroundColor3 = Color3.fromRGB(255, 196, 72)
	xpFill.Parent = xpBack
	corner(xpFill, 6)

	local statEnergy = Instance.new("TextLabel")
	statEnergy.BackgroundTransparency = 1
	statEnergy.Size = UDim2.new(1, 0, 0, 18)
	statEnergy.Font = Enum.Font.Gotham
	statEnergy.TextSize = 14
	statEnergy.TextColor3 = Color3.fromRGB(140, 220, 170)
	statEnergy.TextXAlignment = Enum.TextXAlignment.Left
	statEnergy.Parent = left

	local statCourage = Instance.new("TextLabel")
	statCourage.BackgroundTransparency = 1
	statCourage.Size = UDim2.new(1, 0, 0, 18)
	statCourage.Font = Enum.Font.Gotham
	statCourage.TextSize = 14
	statCourage.TextColor3 = Color3.fromRGB(255, 150, 150)
	statCourage.TextXAlignment = Enum.TextXAlignment.Left
	statCourage.Parent = left

	local statCoin = Instance.new("TextLabel")
	statCoin.BackgroundTransparency = 1
	statCoin.Size = UDim2.new(1, 0, 0, 18)
	statCoin.Font = Enum.Font.Gotham
	statCoin.TextSize = 14
	statCoin.TextColor3 = Color3.fromRGB(255, 214, 120)
	statCoin.TextXAlignment = Enum.TextXAlignment.Left
	statCoin.Parent = left

	local statPower = Instance.new("TextLabel")
	statPower.BackgroundTransparency = 1
	statPower.Size = UDim2.new(1, 0, 0, 18)
	statPower.Font = Enum.Font.Gotham
	statPower.TextSize = 14
	statPower.TextColor3 = Color3.fromRGB(180, 200, 255)
	statPower.TextXAlignment = Enum.TextXAlignment.Left
	statPower.Parent = left

	local bagBtn = textButton(left, "가방 열기", Color3.fromRGB(64, 96, 150), UDim2.new(1, 0, 0, 32))

	local storyBox = Instance.new("Frame")
	storyBox.Position = UDim2.fromOffset(16, 326)
	storyBox.Size = UDim2.fromOffset(250, 120)
	storyBox.BackgroundColor3 = Color3.fromRGB(48, 32, 28)
	storyBox.Parent = gui
	corner(storyBox, 14)
	pad(storyBox, 12)

	local storyTitle = Instance.new("TextLabel")
	storyTitle.BackgroundTransparency = 1
	storyTitle.Size = UDim2.new(1, 0, 0, 22)
	storyTitle.Font = Enum.Font.GothamBold
	storyTitle.TextSize = 16
	storyTitle.TextColor3 = Color3.fromRGB(255, 200, 140)
	storyTitle.TextXAlignment = Enum.TextXAlignment.Left
	storyTitle.Text = "첫 등교"
	storyTitle.Parent = storyBox

	local storyGoal = Instance.new("TextLabel")
	storyGoal.BackgroundTransparency = 1
	storyGoal.Position = UDim2.fromOffset(0, 28)
	storyGoal.Size = UDim2.new(1, 0, 1, -28)
	storyGoal.Font = Enum.Font.Gotham
	storyGoal.TextSize = 14
	storyGoal.TextColor3 = Color3.new(1, 1, 1)
	storyGoal.TextXAlignment = Enum.TextXAlignment.Left
	storyGoal.TextYAlignment = Enum.TextYAlignment.Top
	storyGoal.TextWrapped = true
	storyGoal.Text = "정문 앞 김선생님과 대화하세요"
	storyGoal.Parent = storyBox

	local warning = Instance.new("TextLabel")
	warning.AnchorPoint = Vector2.new(0.5, 0)
	warning.Position = UDim2.new(0.5, 0, 0, 100)
	warning.Size = UDim2.fromOffset(380, 36)
	warning.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
	warning.Font = Enum.Font.GothamBold
	warning.TextSize = 16
	warning.TextColor3 = Color3.new(1, 1, 1)
	warning.Visible = false
	warning.Parent = gui
	corner(warning, 10)

	local toast = Instance.new("TextLabel")
	toast.AnchorPoint = Vector2.new(0.5, 1)
	toast.Position = UDim2.new(0.5, 0, 1, -24)
	toast.Size = UDim2.fromOffset(540, 46)
	toast.BackgroundColor3 = Color3.fromRGB(28, 40, 62)
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 16
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.Visible = false
	toast.Parent = gui
	corner(toast, 12)

	local dialogue = Instance.new("Frame")
	dialogue.AnchorPoint = Vector2.new(0.5, 1)
	dialogue.Position = UDim2.new(0.5, 0, 1, -80)
	dialogue.Size = UDim2.fromOffset(620, 150)
	dialogue.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
	dialogue.Visible = false
	dialogue.Parent = gui
	corner(dialogue, 16)
	pad(dialogue, 16)

	local speaker = Instance.new("TextLabel")
	speaker.BackgroundTransparency = 1
	speaker.Size = UDim2.new(1, 0, 0, 24)
	speaker.Font = Enum.Font.GothamBold
	speaker.TextSize = 18
	speaker.TextColor3 = Color3.fromRGB(255, 220, 140)
	speaker.TextXAlignment = Enum.TextXAlignment.Left
	speaker.Parent = dialogue

	local lineLabel = Instance.new("TextLabel")
	lineLabel.BackgroundTransparency = 1
	lineLabel.Position = UDim2.fromOffset(0, 28)
	lineLabel.Size = UDim2.new(1, 0, 1, -70)
	lineLabel.Font = Enum.Font.Gotham
	lineLabel.TextSize = 18
	lineLabel.TextColor3 = Color3.new(1, 1, 1)
	lineLabel.TextXAlignment = Enum.TextXAlignment.Left
	lineLabel.TextYAlignment = Enum.TextYAlignment.Top
	lineLabel.TextWrapped = true
	lineLabel.Parent = dialogue

	local nextLine = textButton(dialogue, "다음", Color3.fromRGB(70, 110, 180), UDim2.new(0, 120, 0, 36))
	nextLine.Position = UDim2.new(1, -120, 1, -36)

	local encounter = Instance.new("Frame")
	encounter.AnchorPoint = Vector2.new(0.5, 0.5)
	encounter.Position = UDim2.fromScale(0.5, 0.5)
	encounter.Size = UDim2.fromOffset(420, 340)
	encounter.BackgroundColor3 = Color3.fromRGB(48, 24, 28)
	encounter.Visible = false
	encounter.Parent = gui
	corner(encounter, 18)
	pad(encounter, 16)

	local encTitle = Instance.new("TextLabel")
	encTitle.BackgroundTransparency = 1
	encTitle.Size = UDim2.new(1, 0, 0, 50)
	encTitle.Font = Enum.Font.GothamBold
	encTitle.TextSize = 20
	encTitle.TextColor3 = Color3.fromRGB(255, 200, 200)
	encTitle.TextWrapped = true
	encTitle.Parent = encounter

	local encLayout = Instance.new("UIListLayout")
	encLayout.Padding = UDim.new(0, 8)
	encLayout.SortOrder = Enum.SortOrder.LayoutOrder
	encLayout.Parent = encounter
	encTitle.LayoutOrder = 0

	local runBtn = textButton(encounter, "도망가기", Color3.fromRGB(70, 120, 80), UDim2.new(1, 0, 0, 42))
	local hideBtn = textButton(encounter, "숨기", Color3.fromRGB(70, 90, 130), UDim2.new(1, 0, 0, 42))
	local fightBtn = textButton(encounter, "맞서기", Color3.fromRGB(160, 70, 70), UDim2.new(1, 0, 0, 42))
	local noteBtn = textButton(encounter, "친구의 쪽지 쓰기", Color3.fromRGB(120, 90, 160), UDim2.new(1, 0, 0, 42))
	local whistleBtn = textButton(encounter, "호루라기 불기", Color3.fromRGB(160, 110, 50), UDim2.new(1, 0, 0, 42))
	runBtn.LayoutOrder = 1
	hideBtn.LayoutOrder = 2
	fightBtn.LayoutOrder = 3
	noteBtn.LayoutOrder = 4
	whistleBtn.LayoutOrder = 5

	local shop = Instance.new("Frame")
	shop.AnchorPoint = Vector2.new(0.5, 0.5)
	shop.Position = UDim2.fromScale(0.5, 0.5)
	shop.Size = UDim2.fromOffset(430, 460)
	shop.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
	shop.Visible = false
	shop.Parent = gui
	corner(shop, 18)
	pad(shop, 16)
	local shopLayout = Instance.new("UIListLayout")
	shopLayout.Padding = UDim.new(0, 7)
	shopLayout.Parent = shop
	local shopHead = Instance.new("TextLabel")
	shopHead.BackgroundTransparency = 1
	shopHead.Size = UDim2.new(1, 0, 0, 28)
	shopHead.Font = Enum.Font.GothamBold
	shopHead.TextSize = 22
	shopHead.TextColor3 = Color3.fromRGB(255, 224, 140)
	shopHead.TextXAlignment = Enum.TextXAlignment.Left
	shopHead.Text = "매점"
	shopHead.Parent = shop

	for _, itemId in Config.ShopOrder do
		local item = Config.Items[itemId]
		local button = textButton(shop, string.format("%s  ·  %d코인\n%s", item.name, item.price, item.desc), Color3.fromRGB(48, 64, 96), UDim2.new(1, 0, 0, 52))
		button.TextSize = 14
		button.MouseButton1Click:Connect(function()
			Remotes.get("BuyItem"):FireServer(itemId)
		end)
	end
	local closeShop = textButton(shop, "닫기", Color3.fromRGB(160, 70, 70), UDim2.new(1, 0, 0, 38))
	closeShop.MouseButton1Click:Connect(function()
		shop.Visible = false
		shopOpen = false
	end)

	local bag = Instance.new("Frame")
	bag.AnchorPoint = Vector2.new(0, 0)
	bag.Position = UDim2.fromOffset(276, 104)
	bag.Size = UDim2.fromOffset(260, 280)
	bag.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
	bag.Visible = false
	bag.Parent = gui
	corner(bag, 14)
	pad(bag, 12)
	local bagLayout = Instance.new("UIListLayout")
	bagLayout.Padding = UDim.new(0, 6)
	bagLayout.Parent = bag
	local bagHead = Instance.new("TextLabel")
	bagHead.BackgroundTransparency = 1
	bagHead.Size = UDim2.new(1, 0, 0, 24)
	bagHead.Font = Enum.Font.GothamBold
	bagHead.TextSize = 18
	bagHead.TextColor3 = Color3.fromRGB(255, 224, 140)
	bagHead.TextXAlignment = Enum.TextXAlignment.Left
	bagHead.Text = "가방"
	bagHead.Parent = bag
	local bagRows: { [string]: TextButton } = {}

	local function refreshBag()
		for _, child in bag:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		bagRows = {}
		if not profile then
			return
		end
		for itemId, count in profile.inventory do
			if count > 0 and Config.Items[itemId] then
				local item = Config.Items[itemId]
				local row = textButton(bag, string.format("%s x%d  (클릭해서 사용)", item.name, count), Color3.fromRGB(50, 70, 100), UDim2.new(1, 0, 0, 36))
				row.TextSize = 13
				row.MouseButton1Click:Connect(function()
					Remotes.get("UseItem"):FireServer(itemId)
				end)
				bagRows[itemId] = row
			end
		end
		if profile.owned.sneakers then
			textButton(bag, "운동화 착용 중", Color3.fromRGB(50, 90, 70), UDim2.new(1, 0, 0, 32)).Active = false
		end
		if profile.owned.courage_badge then
			textButton(bag, "용기 배지 착용 중", Color3.fromRGB(90, 70, 50), UDim2.new(1, 0, 0, 32)).Active = false
		end
	end

	bagBtn.MouseButton1Click:Connect(function()
		bagOpen = not bagOpen
		bag.Visible = bagOpen
		bagBtn.Text = if bagOpen then "가방 닫기" else "가방 열기"
		refreshBag()
	end)

	local help = Instance.new("TextLabel")
	help.AnchorPoint = Vector2.new(1, 1)
	help.Position = UDim2.new(1, -16, 1, -16)
	help.Size = UDim2.fromOffset(300, 96)
	help.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
	help.Font = Enum.Font.Gotham
	help.TextSize = 13
	help.TextColor3 = Color3.fromRGB(230, 234, 244)
	help.TextXAlignment = Enum.TextXAlignment.Left
	help.TextYAlignment = Enum.TextYAlignment.Top
	help.TextWrapped = true
	help.Text = "스토리를 따라 이동하세요\n불리에게 잡히면 도망/숨기/맞서기\n수업 = 레벨, 매점 = 아이템"
	help.Parent = gui
	corner(help, 12)
	pad(help, 10)

	local dialogueLines = {}
	local dialogueIndex = 1

	local function showDialogue(speakerName: string, lines)
		dialogueLines = lines
		dialogueIndex = 1
		speaker.Text = speakerName
		lineLabel.Text = lines[1] or ""
		dialogue.Visible = true
	end

	nextLine.MouseButton1Click:Connect(function()
		dialogueIndex += 1
		if dialogueIndex > #dialogueLines then
			dialogue.Visible = false
		else
			lineLabel.Text = dialogueLines[dialogueIndex]
		end
	end)

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
		task.delay(3, function()
			if toast.Text == text then
				toast.Visible = false
			end
		end)
	end

	local function refreshProfile()
		if not profile then
			return
		end
		nameLabel.Text = string.format("%d레벨 %s", profile.level, profile.title)
		statEnergy.Text = string.format("에너지 %d / %d", profile.energy, profile.maxEnergy)
		statCourage.Text = string.format("용기 %d / %d", profile.courage, profile.maxCourage)
		statCoin.Text = string.format("코인 %d", profile.coins)
		statPower.Text = string.format("맞서기 힘 %d   평균성적 %.0f", profile.power, profile.gpa)
		local needed = profile.xpNeeded or 100
		xpFill.Size = UDim2.fromScale(Util.clamp(profile.xp / needed, 0, 1), 1)
		refreshBag()
	end

	runBtn.MouseButton1Click:Connect(function()
		Remotes.get("EncounterAction"):FireServer("run")
	end)
	hideBtn.MouseButton1Click:Connect(function()
		Remotes.get("EncounterAction"):FireServer("hide")
	end)
	fightBtn.MouseButton1Click:Connect(function()
		Remotes.get("EncounterAction"):FireServer("fight")
	end)
	noteBtn.MouseButton1Click:Connect(function()
		Remotes.get("EncounterAction"):FireServer("item", "friend_note")
	end)
	whistleBtn.MouseButton1Click:Connect(function()
		Remotes.get("EncounterAction"):FireServer("item", "whistle")
	end)

	Remotes.get("ProfileUpdated").OnClientEvent:Connect(function(data)
		profile = data
		refreshProfile()
	end)
	Remotes.get("PeriodChanged").OnClientEvent:Connect(function(data)
		period = data
		periodTitle.Text = string.format("%s  ·  %s", data.name, Util.formatTime(data.remaining or 0))
		periodHint.Text = data.hint or ""
		showToast(data.name .. " 시작!", "info")
	end)
	Remotes.get("StoryUpdated").OnClientEvent:Connect(function(data)
		story = data
		storyTitle.Text = data.title
		storyGoal.Text = data.goal
	end)
	Remotes.get("Dialogue").OnClientEvent:Connect(function(data)
		if typeof(data) == "table" and data.lines then
			showDialogue(data.speaker or "이야기", data.lines)
		end
	end)
	Remotes.get("Notify").OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" then
			showToast(payload.text, payload.tone)
		end
	end)
	Remotes.get("EncounterStart").OnClientEvent:Connect(function(data)
		encTitle.Text = string.format("%s (%s)\n상대 힘 %d  /  내 힘 %d", data.name, data.title, data.power, data.playerPower)
		encounter.Visible = true
	end)
	Remotes.get("EncounterEnd").OnClientEvent:Connect(function()
		encounter.Visible = false
	end)
	Remotes.get("BullyWarning").OnClientEvent:Connect(function(data)
		warning.Text = string.format("%s 가 가까이 온다! (거리 %d)", data.name, math.floor(data.distance or 0))
		warning.Visible = true
		task.delay(1.2, function()
			warning.Visible = false
		end)
	end)

	task.spawn(function()
		while gui.Parent do
			if period then
				period.remaining = math.max(0, (period.endsAt or 0) - workspace:GetServerTimeNow())
				periodTitle.Text = string.format("%s  ·  %s", period.name, Util.formatTime(period.remaining))
			end
			task.wait(0.25)
		end
	end)

	Remotes.get("GetProfile"):FireServer()
end

return Hud
