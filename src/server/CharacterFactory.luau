local CollectionService = game:GetService("CollectionService")

local CharacterFactory = {}

local function limb(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, collide: boolean)
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = color
	piece.Material = Enum.Material.SmoothPlastic
	piece.Anchored = false
	piece.CanCollide = collide
	piece.Parent = parent
	return piece
end

local function weld(root: BasePart, other: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = other
	w.Parent = root
end

function CharacterFactory.create(info): Model
	local model = Instance.new("Model")
	model.Name = info.name

	local start = info.start
	local color = info.color
	local root = limb(model, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(start), color, true)
	root.Transparency = 1
	local torso = limb(model, "Torso", Vector3.new(2, 2, 1), CFrame.new(start), color, true)
	local head = limb(model, "Head", Vector3.new(1.5, 1.5, 1.5), CFrame.new(start + Vector3.new(0, 1.8, 0)), Color3.fromRGB(232, 198, 164), false)
	local leftArm = limb(model, "Left Arm", Vector3.new(1, 2, 1), CFrame.new(start + Vector3.new(-1.5, 0, 0)), color, false)
	local rightArm = limb(model, "Right Arm", Vector3.new(1, 2, 1), CFrame.new(start + Vector3.new(1.5, 0, 0)), color, false)
	local pants = Color3.fromRGB(48, 52, 72)
	local leftLeg = limb(model, "Left Leg", Vector3.new(1, 2, 1), CFrame.new(start + Vector3.new(-0.5, -2, 0)), pants, false)
	local rightLeg = limb(model, "Right Leg", Vector3.new(1, 2, 1), CFrame.new(start + Vector3.new(0.5, -2, 0)), pants, false)

	weld(root, torso)
	weld(root, head)
	weld(root, leftArm)
	weld(root, rightArm)
	weld(root, leftLeg)
	weld(root, rightLeg)

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = info.name
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = info.walkSpeed or 11
	humanoid.Parent = model
	model.PrimaryPart = root

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, 44)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = info.name .. "\n" .. (info.title or "")
	label.TextColor3 = info.labelColor or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.25
	label.TextScaled = true
	label.Parent = gui

	if info.interact then
		CollectionService:AddTag(root, "SchoolInteract")
		root:SetAttribute("Interact", info.interact)
		root:SetAttribute("NpcName", info.name)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = info.actionText or "대화하기"
		prompt.ObjectText = info.name
		prompt.HoldDuration = 0.15
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
	end

	for key, value in info.attributes or {} do
		root:SetAttribute(key, value)
		model:SetAttribute(key, value)
	end

	model.Parent = workspace:FindFirstChild("SchoolCampus") or workspace
	return model
end

return CharacterFactory
