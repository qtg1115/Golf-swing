local CollectionService = game:GetService("CollectionService")

local ActorFactory = {}

-- Actors are anchored block characters moved with PivotTo.
-- No Humanoid is used, so they never ragdoll, fall, or need pathfinding.
local function block(parent: Instance, name: string, size: Vector3, offset: Vector3, color: Color3): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.CFrame = CFrame.new(offset)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function ActorFactory.create(info): Model
	local model = Instance.new("Model")
	model.Name = info.name

	local skin = Color3.fromRGB(236, 202, 168)
	local pants = Color3.fromRGB(48, 54, 76)

	local root = block(model, "Root", Vector3.new(2, 5, 1), Vector3.new(0, 0, 0), info.color)
	root.Transparency = 1
	model.PrimaryPart = root

	block(model, "Torso", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0), info.color)
	local head = block(model, "Head", Vector3.new(1.5, 1.5, 1.5), Vector3.new(0, 1.8, 0), skin)
	block(model, "ArmLeft", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0), info.color)
	block(model, "ArmRight", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0), info.color)
	block(model, "LegLeft", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0), pants)
	block(model, "LegRight", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0), pants)

	local eyeL = block(model, "EyeL", Vector3.new(0.25, 0.25, 0.1), Vector3.new(-0.35, 2, -0.75), Color3.fromRGB(30, 30, 40))
	local eyeR = block(model, "EyeR", Vector3.new(0.25, 0.25, 0.1), Vector3.new(0.35, 2, -0.75), Color3.fromRGB(30, 30, 40))
	eyeL.Material = Enum.Material.SmoothPlastic
	eyeR.Material = Enum.Material.SmoothPlastic

	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(190, 46)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 250
	gui.Parent = head

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = info.name .. "\n" .. (info.role or "")
	label.TextColor3 = info.labelColor or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui

	model:PivotTo(CFrame.new(info.position))

	if info.action then
		CollectionService:AddTag(root, "Interact")
		root:SetAttribute("Action", info.action)
		root:SetAttribute("Npc", info.name)

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = info.prompt or "Talk"
		prompt.ObjectText = info.name
		prompt.HoldDuration = 0.1
		prompt.MaxActivationDistance = 13
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
	end

	model.Parent = info.parent or workspace
	return model
end

function ActorFactory.moveTowards(model: Model, target: Vector3, speed: number, dt: number)
	local pivot = model:GetPivot()
	local from = pivot.Position
	local flatTarget = Vector3.new(target.X, from.Y, target.Z)
	local delta = flatTarget - from
	local distance = delta.Magnitude
	if distance < 0.5 then
		return
	end
	local direction = delta.Unit
	local step = math.min(speed * dt, distance - 0.25)
	if step <= 0 then
		return
	end
	local nextPos = from + direction * step
	model:PivotTo(CFrame.lookAt(nextPos, nextPos + direction))
end

return ActorFactory
