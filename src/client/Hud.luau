local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local Hud = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DARK = Color3.fromRGB(24, 32, 48)
local GOLD = Color3.fromRGB(255, 214, 120)
local WHITE = Color3.new(1, 1, 1)

local function round(instance: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function padding(instance: Instance, amount: number)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, amount)
	pad.PaddingBottom = UDim.new(0, amount)
	pad.PaddingLeft = UDim.new(0, amount)
	pad.PaddingRight = UDim.new(0, amount)
	pad.Parent = instance
end

local function panel(parent: Instance, position: UDim2, size: UDim2, color: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.05
	frame.Parent = parent
	round(frame, 14)
	padding(frame, 12)
	return frame
end

local function text(parent: Instance, content: string, size: number, color: Color3, bold: boolean?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, size + 6)
	label.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	label.TextSize = size
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = content
	label.Parent = parent
	return label
end

local function button(parent: Instance, caption: string, color: Color3, height: number): TextButton
	local item = Instance.new("TextButton")
	item.Size = UDim2.new(1, 0, 0, height)
	item.BackgroundColor3 = color
	item.Font = Enum.Font.GothamBold
	item.TextSize = 15
	item.TextColor3 = WHITE
	item.Text = caption
	item.TextWrapped = true
	item.Parent = parent
	round(item, 10)
	return item
end

function Hud.mount()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BraveKidHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local profile
	local period

	-- Top bar: current period
	local top = Instance.new("Frame")
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 12)
	top.Size = UDim2.fromOffset(470, 72)
	top.BackgroundColor3 = Color3.fromRGB(22, 34, 56)
	top.Parent = gui
	round(top, 16)
	padding(top, 12)

	local periodName = text(top, "Brave Kid: School Story", 19, GOLD, true)
	local periodHint = text(top, "Find Mr. Park at the front gate", 14, Color3.fromRGB(214, 224, 238))
	periodHint.Position = UDim2.fromOffset(0, 28)
	periodHint.Size = UDim2.new(1, 0, 0, 34)
	periodHint.TextWrapped = true

	-- Left: player card
	local card = panel(gui, UDim2.fromOffset(14, 96), UDim2.fromOffset(248, 200), DARK)
	local cardList = Instance.new("UIListLayout")
	cardList.Padding = UDim.new(0, 5)
	cardList.Parent = card

	local nameLabel = text(card, "Level 1 New Kid", 16, WHITE, true)

	local xpTrack = Instance.new("Frame")
	xpTrack.Size = UDim2.new(1, 0, 0, 12)
	xpTrack.BackgroundColor3 = Color3.fromRGB(42, 54, 76)
	xpTrack.Parent = card
	round(xpTrack, 6)
	local xpFill = Instance.new("Frame")
	xpFill.Size = UDim2.fromScale(0, 1)
	xpFill.BackgroundColor3 = Color3.fromRGB(255, 196, 72)
	xpFill.BorderSizePixel = 0
	xpFill.Parent = xpTrack
	round(xpFill, 6)

	local energyLabel = text(card, "Energy 100 / 100", 14, Color3.fromRGB(140, 220, 170))
	local courageLabel = text(card, "Courage 80 / 80", 14, Color3.fromRGB(255, 150, 150))
	local coinLabel = text(card, "Coins 40", 14, GOLD)
	local powerLabel = text(card, "Stand-up power 1", 14, Color3.fromRGB(180, 200, 255))
	local bagButton = button(card, "Open Bag", Color3.fromRGB(64, 96, 150), 30)

	-- Left: story goal
	local storyPanel = panel(gui, UDim2.fromOffset(14, 306), UDim2.fromOffset(248, 116), Color3.fromRGB(52, 34, 30))
	local storyTitle = text(storyPanel, "First Day", 16, Color3.fromRGB(255, 200, 140), true)
	local storyGoal = text(storyPanel, "Talk to Mr. Park at the front gate", 14, WHITE)
	storyGoal.Position = UDim2.fromOffset(0, 26)
	storyGoal.Size = UDim2.new(1, 0, 0, 64)
	storyGoal.TextWrapped = true
	storyGoal.TextYAlignment = Enum.TextYAlignment.Top

	-- Left: tasks
	local taskPanel = panel(gui, UDim2.fromOffset(14, 432), UDim2.fromOffset(248, 190), DARK)
	local taskList = Instance.new("UIListLayout")
	taskList.Padding = UDim.new(0, 5)
	taskList.Parent = taskPanel
	text(taskPanel, "Tasks", 16, GOLD, true)

	local taskButtons = {}
	for _, task in Config.Tasks do
		local row = button(taskPanel, task.name, Color3.fromRGB(44, 58, 84), 32)
		row.TextSize = 13
		row.MouseButton1Click:Connect(function()
			Remotes.get("ClaimTask"):FireServer(task.id)
		end)
		taskButtons[task.id] = row
	end

	-- Bag
	local bag = panel(gui, UDim2.fromOffset(272, 96), UDim2.fromOffset(250, 300), Color3.fromRGB(28, 34, 52))
	bag.Visible = false
	local bagList = Instance.new("UIListLayout")
	bagList.Padding = UDim.new(0, 5)
	bagList.Parent = bag
	local bagTitle = text(bag, "Bag", 17, GOLD, true)

	local function refreshBag()
		for _, child in bag:GetChildren() do
			if child:IsA("TextButton") or (child:IsA("TextLabel") and child ~= bagTitle) then
				child:Destroy()
			end
		end
		if not profile then
			return
		end
		local empty = true
		for itemId, count in profile.bag do
			local item = Config.Items[itemId]
			if item and count > 0 then
				empty = false
				local row = button(bag, string.format("%s x%d - %s", item.name, count, item.info), Color3.fromRGB(50, 70, 100), 46)
				row.TextSize = 12
				row.MouseButton1Click:Connect(function()
					Remotes.get("UseItem"):FireServer(itemId)
				end)
			end
		end
		for itemId in profile.gear do
			local item = Config.Items[itemId]
			if item then
				empty = false
				local worn = text(bag, "Wearing: " .. item.name, 13, Color3.fromRGB(150, 230, 170))
				worn.LayoutOrder = 50
			end
		end
		if empty then
			text(bag, "Your bag is empty. Buy items at the school shop.", 13, Color3.fromRGB(200, 208, 220)).TextWrapped = true
		end
	end

	bagButton.MouseButton1Click:Connect(function()
		bag.Visible = not bag.Visible
		bagButton.Text = if bag.Visible then "Close Bag" else "Open Bag"
		refreshBag()
	end)

	-- Shop
	local shop = Instance.new("Frame")
	shop.AnchorPoint = Vector2.new(0.5, 0.5)
	shop.Position = UDim2.fromScale(0.5, 0.5)
	shop.Size = UDim2.fromOffset(430, 470)
	shop.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
	shop.Visible = false
	shop.Parent = gui
	round(shop, 18)
	padding(shop, 14)
	local shopList = Instance.new("UIListLayout")
	shopList.Padding = UDim.new(0, 6)
	shopList.Parent = shop
	text(shop, "School Shop", 20, GOLD, true)

	for _, itemId in Config.ShopItems do
		local item = Config.Items[itemId]
		local row = button(shop, string.format("%s - %d coins\n%s", item.name, item.price, item.info), Color3.fromRGB(48, 64, 96), 52)
		row.TextSize = 13
		row.MouseButton1Click:Connect(function()
			Remotes.get("BuyItem"):FireServer(itemId)
		end)
	end
	local shopClose = button(shop, "Close", Color3.fromRGB(160, 70, 70), 36)
	shopClose.MouseButton1Click:Connect(function()
		shop.Visible = false
	end)

	-- Encounter
	local encounter = Instance.new("Frame")
	encounter.AnchorPoint = Vector2.new(0.5, 0.5)
	encounter.Position = UDim2.fromScale(0.5, 0.5)
	encounter.Size = UDim2.fromOffset(400, 350)
	encounter.BackgroundColor3 = Color3.fromRGB(56, 26, 30)
	encounter.Visible = false
	encounter.Parent = gui
	round(encounter, 18)
	padding(encounter, 14)
	local encounterList = Instance.new("UIListLayout")
	encounterList.Padding = UDim.new(0, 8)
	encounterList.SortOrder = Enum.SortOrder.LayoutOrder
	encounterList.Parent = encounter

	local encounterTitle = Instance.new("TextLabel")
	encounterTitle.BackgroundTransparency = 1
	encounterTitle.Size = UDim2.new(1, 0, 0, 56)
	encounterTitle.Font = Enum.Font.GothamBold
	encounterTitle.TextSize = 18
	encounterTitle.TextColor3 = Color3.fromRGB(255, 200, 200)
	encounterTitle.TextWrapped = true
	encounterTitle.LayoutOrder = 0
	encounterTitle.Parent = encounter

	local runButton = button(encounter, "Run away", Color3.fromRGB(66, 122, 78), 44)
	local hideButton = button(encounter, "Hide", Color3.fromRGB(66, 92, 136), 44)
	local standButton = button(encounter, "Stand up", Color3.fromRGB(164, 70, 70), 44)
	local noteButton = button(encounter, "Use Friend's Note", Color3.fromRGB(120, 90, 160), 40)
	local whistleButton = button(encounter, "Use Whistle", Color3.fromRGB(160, 112, 52), 40)
	runButton.LayoutOrder = 1
	hideButton.LayoutOrder = 2
	standButton.LayoutOrder = 3
	noteButton.LayoutOrder = 4
	whistleButton.LayoutOrder = 5

	runButton.MouseButton1Click:Connect(function()
		Remotes.get("EncounterAction"):FireServer("run")
	end)
	hideButton.MouseButton1Click:Connect(function()
		Remotes.get("EncounterAction"):FireServer("hide")
	end)
	standButton.MouseButton1Click:Connect(function()
		Remotes.get("EncounterAction"):FireServer("stand")
	end)
	noteButton.MouseButton1Click:Connect(function()
		Remotes.get("EncounterAction"):FireServer("item", "note")
	end)
	whistleButton.MouseButton1Click:Connect(function()
		Remotes.get("EncounterAction"):FireServer("item", "whistle")
	end)

	-- Dialogue
	local dialogue = Instance.new("Frame")
	dialogue.AnchorPoint = Vector2.new(0.5, 1)
	dialogue.Position = UDim2.new(0.5, 0, 1, -70)
	dialogue.Size = UDim2.fromOffset(620, 150)
	dialogue.BackgroundColor3 = Color3.fromRGB(18, 24, 40)
	dialogue.Visible = false
	dialogue.Parent = gui
	round(dialogue, 16)
	padding(dialogue, 16)

	local speakerLabel = text(dialogue, "", 18, GOLD, true)
	local lineLabel = text(dialogue, "", 17, WHITE)
	lineLabel.Position = UDim2.fromOffset(0, 28)
	lineLabel.Size = UDim2.new(1, 0, 0, 70)
	lineLabel.TextWrapped = true
	lineLabel.TextYAlignment = Enum.TextYAlignment.Top

	local nextButton = button(dialogue, "Next", Color3.fromRGB(70, 110, 180), 34)
	nextButton.Size = UDim2.fromOffset(120, 34)
	nextButton.Position = UDim2.new(1, -120, 1, -34)

	local lines = {}
	local lineIndex = 1
	nextButton.MouseButton1Click:Connect(function()
		lineIndex += 1
		if lineIndex > #lines then
			dialogue.Visible = false
		else
			lineLabel.Text = lines[lineIndex]
		end
	end)

	-- Alerts
	local warningLabel = Instance.new("TextLabel")
	warningLabel.AnchorPoint = Vector2.new(0.5, 0)
	warningLabel.Position = UDim2.new(0.5, 0, 0, 92)
	warningLabel.Size = UDim2.fromOffset(380, 34)
	warningLabel.BackgroundColor3 = Color3.fromRGB(150, 46, 46)
	warningLabel.Font = Enum.Font.GothamBold
	warningLabel.TextSize = 15
	warningLabel.TextColor3 = WHITE
	warningLabel.Visible = false
	warningLabel.Parent = gui
	round(warningLabel, 10)

	local toast = Instance.new("TextLabel")
	toast.AnchorPoint = Vector2.new(0.5, 1)
	toast.Position = UDim2.new(0.5, 0, 1, -20)
	toast.Size = UDim2.fromOffset(560, 44)
	toast.BackgroundColor3 = Color3.fromRGB(28, 40, 62)
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 15
	toast.TextColor3 = WHITE
	toast.TextWrapped = true
	toast.Visible = false
	toast.Parent = gui
	round(toast, 12)

	local help = Instance.new("TextLabel")
	help.AnchorPoint = Vector2.new(1, 1)
	help.Position = UDim2.new(1, -14, 1, -14)
	help.Size = UDim2.fromOffset(290, 92)
	help.BackgroundColor3 = DARK
	help.BackgroundTransparency = 0.1
	help.Font = Enum.Font.Gotham
	help.TextSize = 13
	help.TextColor3 = Color3.fromRGB(228, 234, 244)
	help.TextXAlignment = Enum.TextXAlignment.Left
	help.TextYAlignment = Enum.TextYAlignment.Top
	help.TextWrapped = true
	help.Text = "Move: W A S D\nInteract: press E near a person or object\nClass = XP  Shop = items  Bushes = hiding"
	help.Parent = gui
	round(help, 12)
	padding(help, 10)

	local function showToast(message: string, tone: string?)
		toast.Text = message
		toast.BackgroundColor3 = if tone == "good"
			then Color3.fromRGB(38, 112, 80)
			elseif tone == "warn" then Color3.fromRGB(152, 80, 48)
			else Color3.fromRGB(28, 40, 62)
		toast.Visible = true
		task.delay(3.2, function()
			if toast.Text == message then
				toast.Visible = false
			end
		end)
	end

	local function refreshProfile()
		if not profile then
			return
		end
		nameLabel.Text = string.format("Level %d %s", profile.level, profile.title)
		energyLabel.Text = string.format("Energy %d / %d", profile.energy, profile.maxEnergy)
		courageLabel.Text = string.format("Courage %d / %d", profile.courage, profile.maxCourage)
		coinLabel.Text = string.format("Coins %d", profile.coins)
		powerLabel.Text = string.format("Stand-up power %d   Grades %d", profile.power, profile.gpa)
		xpFill.Size = UDim2.fromScale(Util.clamp(profile.xp / math.max(1, profile.xpNeeded), 0, 1), 1)

		for _, task in Config.Tasks do
			local state = profile.tasks[task.id]
			local row = taskButtons[task.id]
			if state and row then
				if state.claimed then
					row.Text = task.name .. " - done"
					row.BackgroundColor3 = Color3.fromRGB(46, 96, 70)
				elseif state.progress >= task.goal then
					row.Text = string.format("%s - CLAIM REWARD", task.name)
					row.BackgroundColor3 = Color3.fromRGB(120, 96, 40)
				else
					row.Text = string.format("%s  %d/%d", task.name, state.progress or 0, task.goal)
					row.BackgroundColor3 = Color3.fromRGB(44, 58, 84)
				end
			end
		end

		if bag.Visible then
			refreshBag()
		end
	end

	Remotes.get("ProfileUpdated").OnClientEvent:Connect(function(data)
		profile = data
		refreshProfile()
	end)

	Remotes.get("PeriodChanged").OnClientEvent:Connect(function(data)
		period = data
		periodHint.Text = data.hint or ""
		showToast(data.name .. " started!", "info")
	end)

	Remotes.get("StoryUpdated").OnClientEvent:Connect(function(data)
		storyTitle.Text = string.format("%s (%d/%d)", data.title, data.step, data.total)
		storyGoal.Text = data.goal
	end)

	Remotes.get("Dialogue").OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" or typeof(data.lines) ~= "table" or #data.lines == 0 then
			return
		end
		lines = data.lines
		lineIndex = 1
		speakerLabel.Text = data.speaker or "Story"
		lineLabel.Text = lines[1]
		dialogue.Visible = true
	end)

	Remotes.get("Notify").OnClientEvent:Connect(function(data)
		if typeof(data) == "table" and typeof(data.text) == "string" then
			showToast(data.text, data.tone)
		end
	end)

	Remotes.get("OpenShop").OnClientEvent:Connect(function()
		shop.Visible = not shop.Visible
	end)

	Remotes.get("EncounterStart").OnClientEvent:Connect(function(data)
		encounterTitle.Text = string.format(
			"%s (%s)\nTheir power: %d      Your power: %d",
			data.name,
			data.role or "Bully",
			data.power or 0,
			data.myPower or 0
		)
		encounter.Visible = true
	end)

	Remotes.get("EncounterEnd").OnClientEvent:Connect(function()
		encounter.Visible = false
	end)

	Remotes.get("BullyWarning").OnClientEvent:Connect(function(data)
		warningLabel.Text = string.format("%s is nearby! (%d studs)", data.name, math.floor(data.distance or 0))
		warningLabel.Visible = true
		task.delay(1.2, function()
			warningLabel.Visible = false
		end)
	end)

	task.spawn(function()
		while gui.Parent do
			if period then
				local left = math.max(0, (period.endsAt or 0) - workspace:GetServerTimeNow())
				periodName.Text = string.format("%s   %s", period.name, Util.formatTime(left))
			end
			task.wait(0.25)
		end
	end)

	Remotes.get("GetProfile"):FireServer()
end

return Hud
