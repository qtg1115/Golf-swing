local CollectionService = game:GetService("CollectionService")

local SchoolBuilder = {}

local WALL_HEIGHT = 16
local WALL_THICKNESS = 1.2
local FLOOR_Y = 2

local COLORS = {
	grass = Color3.fromRGB(92, 168, 96),
	path = Color3.fromRGB(214, 196, 158),
	dirt = Color3.fromRGB(145, 118, 82),
	brick = Color3.fromRGB(188, 86, 78),
	trim = Color3.fromRGB(236, 228, 210),
	floor = Color3.fromRGB(214, 196, 168),
	hallway = Color3.fromRGB(232, 220, 198),
	roof = Color3.fromRGB(72, 84, 102),
	desk = Color3.fromRGB(158, 108, 68),
	chair = Color3.fromRGB(92, 122, 168),
	board = Color3.fromRGB(46, 78, 58),
	glass = Color3.fromRGB(164, 206, 230),
	locker = Color3.fromRGB(72, 118, 168),
	field = Color3.fromRGB(70, 148, 78),
	line = Color3.fromRGB(245, 245, 245),
	sign = Color3.fromRGB(48, 72, 128),
	wood = Color3.fromRGB(140, 96, 62),
	food = Color3.fromRGB(240, 196, 92),
	shop = Color3.fromRGB(214, 92, 98),
}

local function part(props): BasePart
	local instance = Instance.new("Part")
	instance.Anchored = true
	instance.CastShadow = true
	instance.TopSurface = Enum.SurfaceType.Smooth
	instance.BottomSurface = Enum.SurfaceType.Smooth
	instance.Material = props.material or Enum.Material.SmoothPlastic
	instance.Color = props.color or Color3.new(1, 1, 1)
	instance.Size = props.size
	instance.CFrame = props.cframe
	instance.Name = props.name or "Part"
	instance.CanCollide = if props.canCollide == nil then true else props.canCollide
	instance.Transparency = props.transparency or 0
	if props.parent then
		instance.Parent = props.parent
	end
	return instance
end

local function surfaceText(parent: BasePart, text: string, face: Enum.NormalId, textSize: number, color: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 18
	gui.LightInfluence = 0.15
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextScaled = false
	label.TextSize = textSize
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextWrapped = true
	label.Parent = gui
end

local function billboard(parent: BasePart, text: string, color: Color3?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(220, 42)
	gui.StudsOffset = Vector3.new(0, 4.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(28, 36, 52)
	label.BackgroundTransparency = 0.15
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 236, 180)
	label.TextScaled = true
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

local function tagInteract(instance: Instance, data: { [string]: any })
	CollectionService:AddTag(instance, "SchoolInteract")
	for key, value in data do
		instance:SetAttribute(key, value)
	end
end

local function addPrompt(parent: Instance, text: string, hold: number?)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = text
	prompt.ObjectText = "우리학교"
	prompt.HoldDuration = hold or 0.35
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

local DOOR_WIDTH = 9
local DOOR_HEIGHT = 11

local function addSolidWall(folder: Instance, size: Vector3, worldPos: Vector3, color: Color3, name: string)
	part({
		name = name,
		parent = folder,
		size = size,
		cframe = CFrame.new(worldPos + Vector3.new(0, WALL_HEIGHT / 2 + 0.5, 0)),
		color = color,
		material = Enum.Material.Brick,
	})
end

local function addDoorWall(folder: Instance, center: Vector3, size: Vector3, color: Color3, axis: string, sign: number)
	local half = if axis == "z" then size.X / 2 else size.Z / 2
	local side = (half * 2 - DOOR_WIDTH) / 2
	local offset = (side / 2) + (DOOR_WIDTH / 2)

	if axis == "z" then
		local z = center.Z + sign * (size.Z / 2)
		addSolidWall(folder, Vector3.new(side, WALL_HEIGHT, WALL_THICKNESS), Vector3.new(center.X - offset, 0, z), color, "DoorWallL")
		addSolidWall(folder, Vector3.new(side, WALL_HEIGHT, WALL_THICKNESS), Vector3.new(center.X + offset, 0, z), color, "DoorWallR")
		part({
			name = "DoorLintel",
			parent = folder,
			size = Vector3.new(DOOR_WIDTH, WALL_HEIGHT - DOOR_HEIGHT, WALL_THICKNESS),
			cframe = CFrame.new(center.X, FLOOR_Y + DOOR_HEIGHT + (WALL_HEIGHT - DOOR_HEIGHT) / 2 + 0.5, z),
			color = color,
			material = Enum.Material.Brick,
		})
	else
		local x = center.X + sign * (size.X / 2)
		addSolidWall(folder, Vector3.new(WALL_THICKNESS, WALL_HEIGHT, side), Vector3.new(x, 0, center.Z - offset), color, "DoorWallL")
		addSolidWall(folder, Vector3.new(WALL_THICKNESS, WALL_HEIGHT, side), Vector3.new(x, 0, center.Z + offset), color, "DoorWallR")
		part({
			name = "DoorLintel",
			parent = folder,
			size = Vector3.new(WALL_THICKNESS, WALL_HEIGHT - DOOR_HEIGHT, DOOR_WIDTH),
			cframe = CFrame.new(x, FLOOR_Y + DOOR_HEIGHT + (WALL_HEIGHT - DOOR_HEIGHT) / 2 + 0.5, center.Z),
			color = color,
			material = Enum.Material.Brick,
		})
	end
end

local function roomBox(parent: Instance, center: Vector3, size: Vector3, wallColor: Color3, floorColor: Color3, name: string, doorSide: string)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent

	part({
		name = "Floor",
		parent = folder,
		size = Vector3.new(size.X, 1, size.Z),
		cframe = CFrame.new(center.X, FLOOR_Y + 0.5, center.Z),
		color = floorColor,
		material = Enum.Material.WoodPlanks,
	})

	local faces = {
		posZ = { "z", 1, Vector3.new(size.X, WALL_HEIGHT, WALL_THICKNESS), Vector3.new(0, 0, size.Z / 2) },
		negZ = { "z", -1, Vector3.new(size.X, WALL_HEIGHT, WALL_THICKNESS), Vector3.new(0, 0, -size.Z / 2) },
		posX = { "x", 1, Vector3.new(WALL_THICKNESS, WALL_HEIGHT, size.Z), Vector3.new(size.X / 2, 0, 0) },
		negX = { "x", -1, Vector3.new(WALL_THICKNESS, WALL_HEIGHT, size.Z), Vector3.new(-size.X / 2, 0, 0) },
	}

	for side, info in faces do
		if side == doorSide then
			addDoorWall(folder, center, size, wallColor, info[1], info[2])
		else
			addSolidWall(folder, info[3], center + info[4], wallColor, "Wall_" .. side)
		end
	end

	part({
		name = "Roof",
		parent = folder,
		size = Vector3.new(size.X + 4, 2, size.Z + 4),
		cframe = CFrame.new(center.X, FLOOR_Y + WALL_HEIGHT + 2, center.Z),
		color = COLORS.roof,
		material = Enum.Material.Slate,
	})

	return folder
end

local function makeDesk(parent: Instance, position: Vector3, subject: string, roomId: string)
	local desk = part({
		name = "Desk",
		parent = parent,
		size = Vector3.new(4.2, 1.4, 2.4),
		cframe = CFrame.new(position),
		color = COLORS.desk,
		material = Enum.Material.Wood,
	})

	local seat = Instance.new("Seat")
	seat.Name = "ClassSeat"
	seat.Anchored = true
	seat.Size = Vector3.new(2, 0.5, 2)
	seat.Color = COLORS.chair
	seat.Material = Enum.Material.SmoothPlastic
	seat.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 2.1))
	seat.Parent = parent
	tagInteract(seat, {
		Interact = "AttendClass",
		Subject = subject,
		RoomId = roomId,
	})
	addPrompt(seat, "수업 듣기")
	return desk
end

local function makeClassroom(campus: Instance, roomId: string, subject: string, title: string, center: Vector3, doorSide: string)
	local folder = roomBox(campus, center, Vector3.new(42, WALL_HEIGHT, 32), COLORS.brick, COLORS.floor, roomId, doorSide)

	local board = part({
		name = "Blackboard",
		parent = folder,
		size = Vector3.new(18, 7, 0.4),
		cframe = CFrame.new(center + Vector3.new(0, 8, -15.2)),
		color = COLORS.board,
		material = Enum.Material.SmoothPlastic,
	})
	surfaceText(board, title, Enum.NormalId.Back, 42, Color3.fromRGB(240, 255, 230))

	local teacherDesk = part({
		name = "TeacherDesk",
		parent = folder,
		size = Vector3.new(8, 2, 3),
		cframe = CFrame.new(center + Vector3.new(0, 2, -10)),
		color = COLORS.wood,
		material = Enum.Material.Wood,
	})
	tagInteract(teacherDesk, {
		Interact = "AttendClass",
		Subject = subject,
		RoomId = roomId,
	})
	addPrompt(teacherDesk, "수업 듣기")

	local doorZ = if doorSide == "negZ" then -16.7 else 16.7
	local sign = part({
		name = "DoorSign",
		parent = folder,
		size = Vector3.new(10, 3, 0.4),
		cframe = CFrame.new(center + Vector3.new(0, 12, doorZ)),
		color = COLORS.sign,
	})
	surfaceText(sign, title, if doorSide == "negZ" then Enum.NormalId.Back else Enum.NormalId.Front, 28)

	local startX = center.X - 12
	local startZ = center.Z + 2
	for row = 0, 2 do
		for col = 0, 3 do
			makeDesk(
				folder,
				Vector3.new(startX + col * 8, FLOOR_Y + 1.4, startZ + row * 6),
				subject,
				roomId
			)
		end
	end

	billboard(folder:FindFirstChild("Floor") :: BasePart, title)
	return folder
end

local function makeCafeteria(campus: Instance, center: Vector3)
	local folder = roomBox(campus, center, Vector3.new(48, WALL_HEIGHT, 36), COLORS.brick, Color3.fromRGB(232, 214, 186), "Cafeteria", "posX")

	local counter = part({
		name = "LunchCounter",
		parent = folder,
		size = Vector3.new(22, 3, 4),
		cframe = CFrame.new(center + Vector3.new(0, 2.5, -12)),
		color = COLORS.food,
		material = Enum.Material.SmoothPlastic,
	})
	tagInteract(counter, { Interact = "EatLunch", RoomId = "Cafeteria" })
	addPrompt(counter, "급식 먹기")
	billboard(counter, "급식실")

	for i = -1, 1 do
		local tablePart = part({
			name = "Table",
			parent = folder,
			size = Vector3.new(10, 1.2, 4),
			cframe = CFrame.new(center + Vector3.new(i * 14, 1.8, 4)),
			color = COLORS.wood,
			material = Enum.Material.Wood,
		})
		tagInteract(tablePart, { Interact = "EatLunch", RoomId = "Cafeteria" })
		addPrompt(tablePart, "급식 먹기")
	end

	local sign = part({
		name = "Sign",
		parent = folder,
		size = Vector3.new(12, 3, 0.4),
		cframe = CFrame.new(center + Vector3.new(0, 12, 18.7)),
		color = COLORS.sign,
	})
	surfaceText(sign, "급식실", Enum.NormalId.Front, 30)
	return folder
end

local function makeOffice(campus: Instance, center: Vector3)
	local folder = roomBox(campus, center, Vector3.new(28, WALL_HEIGHT, 24), COLORS.brick, COLORS.hallway, "Office", "negX")

	local desk = part({
		name = "PrincipalDesk",
		parent = folder,
		size = Vector3.new(8, 2, 4),
		cframe = CFrame.new(center + Vector3.new(0, 2, -4)),
		color = COLORS.wood,
		material = Enum.Material.Wood,
	})
	tagInteract(desk, { Interact = "Talk", NpcName = "교장선생님", RoomId = "Office" })
	addPrompt(desk, "대화하기")
	billboard(desk, "교무실")
	return folder
end

local function makeLibrary(campus: Instance, center: Vector3)
	local folder = roomBox(campus, center, Vector3.new(32, WALL_HEIGHT, 28), COLORS.brick, Color3.fromRGB(210, 186, 150), "Library", "negX")

	for i = -1, 1 do
		local shelf = part({
			name = "Shelf",
			parent = folder,
			size = Vector3.new(8, 10, 2),
			cframe = CFrame.new(center + Vector3.new(i * 10, 6, -10)),
			color = COLORS.wood,
			material = Enum.Material.Wood,
		})
		tagInteract(shelf, { Interact = "Study", RoomId = "Library" })
		addPrompt(shelf, "자습하기")
	end

	billboard(folder:FindFirstChild("Floor") :: BasePart, "도서관")
	return folder
end

local function makeShop(campus: Instance, center: Vector3)
	local stall = part({
		name = "ShopStall",
		parent = campus,
		size = Vector3.new(14, 8, 8),
		cframe = CFrame.new(center + Vector3.new(0, 5, 0)),
		color = COLORS.shop,
		material = Enum.Material.SmoothPlastic,
	})
	tagInteract(stall, { Interact = "OpenShop", RoomId = "Shop" })
	addPrompt(stall, "상점 열기", 0.2)
	billboard(stall, "매점")

	part({
		name = "ShopRoof",
		parent = campus,
		size = Vector3.new(18, 1.2, 12),
		cframe = CFrame.new(center + Vector3.new(0, 9.6, 0)),
		color = Color3.fromRGB(250, 214, 92),
	})
	return stall
end

local function makePlayground(campus: Instance, center: Vector3)
	local field = part({
		name = "Playground",
		parent = campus,
		size = Vector3.new(90, 1, 56),
		cframe = CFrame.new(center + Vector3.new(0, 0.6, 0)),
		color = COLORS.field,
		material = Enum.Material.Grass,
	})
	tagInteract(field, { Interact = "Play", RoomId = "Playground", Subject = "pe" })
	addPrompt(field, "운동하기")
	billboard(field, "운동장")

	part({
		name = "CenterLine",
		parent = campus,
		size = Vector3.new(1, 0.2, 56),
		cframe = CFrame.new(center + Vector3.new(0, 1.15, 0)),
		color = COLORS.line,
		canCollide = false,
	})

	for _, side in { -44, 44 } do
		part({
			name = "Goal",
			parent = campus,
			size = Vector3.new(2, 8, 16),
			cframe = CFrame.new(center + Vector3.new(side, 5, 0)),
			color = COLORS.line,
			material = Enum.Material.Metal,
			canCollide = false,
			transparency = 0.15,
		})
	end

	local bench = part({
		name = "Bench",
		parent = campus,
		size = Vector3.new(10, 1.4, 2.4),
		cframe = CFrame.new(center + Vector3.new(0, 1.8, 26)),
		color = COLORS.wood,
		material = Enum.Material.Wood,
	})
	tagInteract(bench, { Interact = "Play", RoomId = "Playground", Subject = "pe" })
	addPrompt(bench, "운동하기")
	return field
end

local function makeLockers(campus: Instance, origin: Vector3)
	for i = 0, 7 do
		local locker = part({
			name = "Locker",
			parent = campus,
			size = Vector3.new(2.2, 8, 1.6),
			cframe = CFrame.new(origin + Vector3.new(i * 2.6, 5, 0)),
			color = if i % 2 == 0 then COLORS.locker else Color3.fromRGB(210, 92, 92),
			material = Enum.Material.Metal,
		})
		tagInteract(locker, { Interact = "Locker" })
		addPrompt(locker, "사물함 열기")
	end
end

local function makeNpcWaypoints(campus: Instance)
	local points = {
		Vector3.new(0, 4, 20),
		Vector3.new(-40, 4, -8),
		Vector3.new(40, 4, -8),
		Vector3.new(0, 4, -70),
		Vector3.new(90, 4, 10),
		Vector3.new(-90, 4, -20),
	}

	local folder = Instance.new("Folder")
	folder.Name = "NpcWaypoints"
	folder.Parent = campus

	for index, position in points do
		local marker = part({
			name = "Waypoint" .. index,
			parent = folder,
			size = Vector3.new(1, 1, 1),
			cframe = CFrame.new(position),
			transparency = 1,
			canCollide = false,
		})
		marker.CanQuery = false
	end
end

function SchoolBuilder.build()
	local existing = workspace:FindFirstChild("SchoolCampus")
	if existing then
		existing:Destroy()
	end

	local campus = Instance.new("Folder")
	campus.Name = "SchoolCampus"
	campus.Parent = workspace

	part({
		name = "Grass",
		parent = campus,
		size = Vector3.new(420, 4, 360),
		cframe = CFrame.new(0, 0, -10),
		color = COLORS.grass,
		material = Enum.Material.Grass,
	})

	part({
		name = "Path",
		parent = campus,
		size = Vector3.new(28, 0.6, 90),
		cframe = CFrame.new(0, 2.2, 28),
		color = COLORS.path,
		material = Enum.Material.Concrete,
	})

	part({
		name = "Plaza",
		parent = campus,
		size = Vector3.new(70, 0.6, 40),
		cframe = CFrame.new(0, 2.2, 58),
		color = COLORS.path,
		material = Enum.Material.Concrete,
	})

	local schoolSign = part({
		name = "SchoolSign",
		parent = campus,
		size = Vector3.new(28, 8, 1.2),
		cframe = CFrame.new(0, 8, 72),
		color = COLORS.sign,
	})
	surfaceText(schoolSign, "우리학교", Enum.NormalId.Front, 48)
	surfaceText(schoolSign, "우리학교", Enum.NormalId.Back, 48)

	local flagPole = part({
		name = "FlagPole",
		parent = campus,
		size = Vector3.new(0.6, 24, 0.6),
		cframe = CFrame.new(18, 14, 68),
		color = Color3.fromRGB(200, 200, 210),
		material = Enum.Material.Metal,
	})
	part({
		name = "Flag",
		parent = campus,
		size = Vector3.new(8, 4, 0.3),
		cframe = CFrame.new(22.4, 23, 68),
		color = Color3.fromRGB(232, 72, 78),
	})

	-- Hallway connecting classrooms
	part({
		name = "HallwayFloor",
		parent = campus,
		size = Vector3.new(150, 1, 18),
		cframe = CFrame.new(0, FLOOR_Y + 0.5, -8),
		color = COLORS.hallway,
		material = Enum.Material.Concrete,
	})

	makeClassroom(campus, "Korean", "korean", "국어 교실", Vector3.new(-52, 0, -36), "posZ")
	makeClassroom(campus, "Math", "math", "수학 교실", Vector3.new(0, 0, -36), "posZ")
	makeClassroom(campus, "English", "english", "영어 교실", Vector3.new(52, 0, -36), "posZ")
	makeClassroom(campus, "Science", "science", "과학실", Vector3.new(-52, 0, 20), "negZ")
	makeClassroom(campus, "Art", "art", "미술실", Vector3.new(52, 0, 20), "negZ")

	makeCafeteria(campus, Vector3.new(-110, 0, -8))
	makeOffice(campus, Vector3.new(110, 0, -28))
	makeLibrary(campus, Vector3.new(110, 0, 12))
	makeShop(campus, Vector3.new(28, 0, 58))
	makePlayground(campus, Vector3.new(0, 0, -92))
	makeLockers(campus, Vector3.new(-10, 0, -1))
	makeNpcWaypoints(campus)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SchoolSpawn"
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 3, 58)
	spawn.Color = Color3.fromRGB(92, 168, 220)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Parent = campus
	billboard(spawn, "등교")

	-- Soft invisible walls so players stay on campus
	for _, wall in {
		{ Vector3.new(420, 40, 4), Vector3.new(0, 20, 168) },
		{ Vector3.new(420, 40, 4), Vector3.new(0, 20, -188) },
		{ Vector3.new(4, 40, 360), Vector3.new(210, 20, -10) },
		{ Vector3.new(4, 40, 360), Vector3.new(-210, 20, -10) },
	} do
		part({
			name = "Boundary",
			parent = campus,
			size = wall[1],
			cframe = CFrame.new(wall[2]),
			transparency = 1,
		})
	end

	return campus
end

return SchoolBuilder
