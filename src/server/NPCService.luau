local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

local NPCService = {}

local NPCS = {
	{ name = "김선생", title = "담임선생님", color = Color3.fromRGB(72, 96, 168), start = Vector3.new(0, 4, -8) },
	{ name = "이수진", title = "학생회장", color = Color3.fromRGB(220, 118, 148), start = Vector3.new(-20, 4, 50) },
	{ name = "박도윤", title = "2학년", color = Color3.fromRGB(88, 168, 214), start = Vector3.new(24, 4, 48) },
	{ name = "최하늘", title = "축구부", color = Color3.fromRGB(92, 176, 110), start = Vector3.new(0, 4, -70) },
	{ name = "교장선생님", title = "교장", color = Color3.fromRGB(96, 84, 72), start = Vector3.new(100, 4, -28) },
}

local function limb(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3)
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = color
	piece.Material = Enum.Material.SmoothPlastic
	piece.Anchored = false
	piece.CanCollide = name == "HumanoidRootPart" or name == "Torso"
	piece.Parent = parent
	return piece
end

local function weld(root: BasePart, other: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = other
	w.Parent = root
end

local function createNpc(info): Model
	local model = Instance.new("Model")
	model.Name = info.name

	local root = limb(model, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(info.start), info.color)
	root.Transparency = 1

	local torso = limb(model, "Torso", Vector3.new(2, 2, 1), CFrame.new(info.start), info.color)
	local head = limb(model, "Head", Vector3.new(1.4, 1.4, 1.4), CFrame.new(info.start + Vector3.new(0, 1.7, 0)), Color3.fromRGB(232, 198, 164))
	local leftArm = limb(model, "Left Arm", Vector3.new(1, 2, 1), CFrame.new(info.start + Vector3.new(-1.5, 0, 0)), info.color)
	local rightArm = limb(model, "Right Arm", Vector3.new(1, 2, 1), CFrame.new(info.start + Vector3.new(1.5, 0, 0)), info.color)
	local leftLeg = limb(model, "Left Leg", Vector3.new(1, 2, 1), CFrame.new(info.start + Vector3.new(-0.5, -2, 0)), Color3.fromRGB(52, 64, 92))
	local rightLeg = limb(model, "Right Leg", Vector3.new(1, 2, 1), CFrame.new(info.start + Vector3.new(0.5, -2, 0)), Color3.fromRGB(52, 64, 92))

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
	humanoid.WalkSpeed = 10
	humanoid.Parent = model
	model.PrimaryPart = root

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 40)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = info.name .. "\n" .. info.title
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Parent = gui

	CollectionService:AddTag(root, "SchoolInteract")
	root:SetAttribute("Interact", "Talk")
	root:SetAttribute("NpcName", info.name)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "인사하기"
	prompt.ObjectText = info.name
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	model.Parent = workspace:FindFirstChild("SchoolCampus") or workspace
	return model
end

local function waypoints(): { Vector3 }
	local folder = workspace:FindFirstChild("SchoolCampus") and workspace.SchoolCampus:FindFirstChild("NpcWaypoints")
	local points = {}
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(points, child.Position)
			end
		end
	end
	if #points == 0 then
		points = {
			Vector3.new(0, 4, 20),
			Vector3.new(-40, 4, -8),
			Vector3.new(40, 4, -8),
			Vector3.new(0, 4, -70),
		}
	end
	return points
end

local function walkLoop(model: Model, points: { Vector3 })
	task.spawn(function()
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model.PrimaryPart
		if not humanoid or not root then
			return
		end

		while model.Parent and humanoid.Health > 0 do
			local target = points[math.random(1, #points)]
			local path = PathfindingService:CreatePath({
				AgentRadius = 2,
				AgentHeight = 5,
				AgentCanJump = true,
			})
			local ok = pcall(function()
				path:ComputeAsync(root.Position, target)
			end)
			if ok and path.Status == Enum.PathStatus.Success then
				for _, waypoint in path:GetWaypoints() do
					if not model.Parent then
						return
					end
					humanoid:MoveTo(waypoint.Position)
					humanoid.MoveToFinished:Wait()
				end
			else
				humanoid:MoveTo(target)
				humanoid.MoveToFinished:Wait()
			end
			task.wait(math.random(2, 5))
		end
	end)
end

function NPCService.start()
	local points = waypoints()
	for _, info in NPCS do
		local npc = createNpc(info)
		walkLoop(npc, points)
	end
end

return NPCService
