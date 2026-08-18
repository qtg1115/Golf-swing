local CollectionService = game:GetService("CollectionService")

local SchoolBuilder = {}

local FLOOR_Y = 2
local WALL_H = 15
local WALL_T = 1.2
local DOOR_W = 10
local DOOR_H = 11

local C = {
	grass = Color3.fromRGB(96, 168, 96),
	path = Color3.fromRGB(214, 196, 158),
	brick = Color3.fromRGB(188, 92, 82),
	floor = Color3.fromRGB(218, 200, 170),
	hall = Color3.fromRGB(232, 220, 198),
	roof = Color3.fromRGB(72, 84, 102),
	wood = Color3.fromRGB(150, 104, 66),
	board = Color3.fromRGB(46, 78, 58),
	sign = Color3.fromRGB(48, 72, 128),
	seat = Color3.fromRGB(92, 122, 168),
	field = Color3.fromRGB(74, 150, 82),
	white = Color3.fromRGB(244, 244, 244),
	bush = Color3.fromRGB(48, 122, 62),
	shop = Color3.fromRGB(214, 92, 98),
	food = Color3.fromRGB(240, 196, 92),
	metal = Color3.fromRGB(96, 132, 178),
}

local function part(props): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Name = props.name or "Part"
	p.Size = props.size
	p.CFrame = props.cframe
	p.Color = props.color or C.white
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Transparency = props.transparency or 0
	p.CanCollide = if props.collide == nil then true else props.collide
	p.Parent = props.parent
	return p
end

local function faceText(target: BasePart, text: string, face: Enum.NormalId, size: number)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 18
	gui.LightInfluence = 0.2
	gui.Parent = target

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextSize = size
	label.TextColor3 = C.white
	label.TextWrapped = true
	label.Parent = gui
end

local function tag(target: BasePart, text: string, color: Color3?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Size = UDim2.fromOffset(210, 40)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 220
	gui.Parent = target

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(26, 34, 50)
	label.BackgroundTransparency = 0.2
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 236, 180)
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

local function interact(target: BasePart, action: string, data, prompt: string)
	CollectionService:AddTag(target, "Interact")
	target:SetAttribute("Action", action)
	for key, value in data or {} do
		target:SetAttribute(key, value)
	end

	local p = Instance.new("ProximityPrompt")
	p.ActionText = prompt
	p.ObjectText = "School"
	p.HoldDuration = 0.15
	p.MaxActivationDistance = 11
	p.RequiresLineOfSight = false
	p.Parent = target
end

local function wall(parent: Instance, size: Vector3, pos: Vector3, name: string)
	part({
		name = name,
		parent = parent,
		size = size,
		cframe = CFrame.new(pos + Vector3.new(0, WALL_H / 2 + 0.5, 0)),
		color = C.brick,
		material = Enum.Material.Brick,
	})
end

local function doorWall(parent: Instance, center: Vector3, size: Vector3, axis: string, sign: number)
	local span = if axis == "z" then size.X else size.Z
	local side = (span - DOOR_W) / 2
	local offset = side / 2 + DOOR_W / 2

	if axis == "z" then
		local z = center.Z + sign * size.Z / 2
		wall(parent, Vector3.new(side, WALL_H, WALL_T), Vector3.new(center.X - offset, 0, z), "Wall")
		wall(parent, Vector3.new(side, WALL_H, WALL_T), Vector3.new(center.X + offset, 0, z), "Wall")
		part({
			name = "DoorTop",
			parent = parent,
			size = Vector3.new(DOOR_W, WALL_H - DOOR_H, WALL_T),
			cframe = CFrame.new(center.X, FLOOR_Y + DOOR_H + (WALL_H - DOOR_H) / 2 + 0.5, z),
			color = C.brick,
			material = Enum.Material.Brick,
		})
	else
		local x = center.X + sign * size.X / 2
		wall(parent, Vector3.new(WALL_T, WALL_H, side), Vector3.new(x, 0, center.Z - offset), "Wall")
		wall(parent, Vector3.new(WALL_T, WALL_H, side), Vector3.new(x, 0, center.Z + offset), "Wall")
		part({
			name = "DoorTop",
			parent = parent,
			size = Vector3.new(WALL_T, WALL_H - DOOR_H, DOOR_W),
			cframe = CFrame.new(x, FLOOR_Y + DOOR_H + (WALL_H - DOOR_H) / 2 + 0.5, center.Z),
			color = C.brick,
			material = Enum.Material.Brick,
		})
	end
end

local function room(parent: Instance, name: string, center: Vector3, size: Vector3, floorColor: Color3, door: string)
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

	local sides = {
		posZ = { "z", 1, Vector3.new(size.X, WALL_H, WALL_T), Vector3.new(0, 0, size.Z / 2) },
		negZ = { "z", -1, Vector3.new(size.X, WALL_H, WALL_T), Vector3.new(0, 0, -size.Z / 2) },
		posX = { "x", 1, Vector3.new(WALL_T, WALL_H, size.Z), Vector3.new(size.X / 2, 0, 0) },
		negX = { "x", -1, Vector3.new(WALL_T, WALL_H, size.Z), Vector3.new(-size.X / 2, 0, 0) },
	}

	for key, info in sides do
		if key == door then
			doorWall(folder, center, size, info[1], info[2])
		else
			wall(folder, info[3], center + info[4], "Wall")
		end
	end

	part({
		name = "Roof",
		parent = folder,
		size = Vector3.new(size.X + 3, 1.5, size.Z + 3),
		cframe = CFrame.new(center.X, FLOOR_Y + WALL_H + 1.5, center.Z),
		color = C.roof,
		material = Enum.Material.Slate,
	})

	return folder
end

local function classroom(parent: Instance, id: string, subject: string, title: string, center: Vector3, door: string)
	local folder = room(parent, id, center, Vector3.new(40, WALL_H, 30), C.floor, door)

	local board = part({
		name = "Board",
		parent = folder,
		size = Vector3.new(16, 6, 0.4),
		cframe = CFrame.new(center + Vector3.new(0, 8, -14.2)),
		color = C.board,
	})
	faceText(board, title, Enum.NormalId.Back, 40)

	local teacher = part({
		name = "TeacherDesk",
		parent = folder,
		size = Vector3.new(8, 2, 3),
		cframe = CFrame.new(center + Vector3.new(0, 3, -9)),
		color = C.wood,
		material = Enum.Material.Wood,
	})
	interact(teacher, "Class", { Subject = subject, Room = id }, "Join class")
	tag(teacher, title)

	for row = 0, 2 do
		for col = 0, 3 do
			local pos = center + Vector3.new(-12 + col * 8, 1.4, -2 + row * 6)
			part({
				name = "Desk",
				parent = folder,
				size = Vector3.new(4, 1.4, 2.4),
				cframe = CFrame.new(pos + Vector3.new(0, 1.6, 0)),
				color = C.wood,
				material = Enum.Material.Wood,
			})
			local seat = part({
				name = "Seat",
				parent = folder,
				size = Vector3.new(2, 1, 2),
				cframe = CFrame.new(pos + Vector3.new(0, 1.4, 2.6)),
				color = C.seat,
			})
			interact(seat, "Class", { Subject = subject, Room = id }, "Join class")
		end
	end

	local signZ = if door == "negZ" then -15.6 else 15.6
	local signFace = if door == "negZ" then Enum.NormalId.Back else Enum.NormalId.Front
	local doorSign = part({
		name = "Sign",
		parent = folder,
		size = Vector3.new(12, 3, 0.4),
		cframe = CFrame.new(center + Vector3.new(0, 12, signZ)),
		color = C.sign,
	})
	faceText(doorSign, title, signFace, 26)

	return folder
end

function SchoolBuilder.build()
	local old = workspace:FindFirstChild("SchoolCampus")
	if old then
		old:Destroy()
	end

	local campus = Instance.new("Folder")
	campus.Name = "SchoolCampus"
	campus.Parent = workspace

	part({
		name = "Ground",
		parent = campus,
		size = Vector3.new(520, 4, 420),
		cframe = CFrame.new(0, 0, -20),
		color = C.grass,
		material = Enum.Material.Grass,
	})

	part({
		name = "Plaza",
		parent = campus,
		size = Vector3.new(90, 0.6, 46),
		cframe = CFrame.new(0, 2.2, 56),
		color = C.path,
		material = Enum.Material.Concrete,
	})

	part({
		name = "Walkway",
		parent = campus,
		size = Vector3.new(24, 0.6, 100),
		cframe = CFrame.new(0, 2.2, 16),
		color = C.path,
		material = Enum.Material.Concrete,
	})

	part({
		name = "Hallway",
		parent = campus,
		size = Vector3.new(160, 1, 20),
		cframe = CFrame.new(0, FLOOR_Y + 0.5, -6),
		color = C.hall,
		material = Enum.Material.Concrete,
	})

	local gate = part({
		name = "Gate",
		parent = campus,
		size = Vector3.new(30, 8, 1.4),
		cframe = CFrame.new(0, 8, 76),
		color = C.sign,
	})
	faceText(gate, "WELCOME TO SCHOOL", Enum.NormalId.Front, 34)
	faceText(gate, "WELCOME TO SCHOOL", Enum.NormalId.Back, 34)

	classroom(campus, "Reading", "reading", "Reading Room", Vector3.new(-56, 0, -34), "posZ")
	classroom(campus, "Math", "math", "Math Room", Vector3.new(0, 0, -34), "posZ")
	classroom(campus, "Science", "science", "Science Room", Vector3.new(56, 0, -34), "posZ")
	classroom(campus, "Art", "art", "Art Room", Vector3.new(56, 0, 22), "negZ")

	-- Cafeteria
	local cafe = room(campus, "Cafeteria", Vector3.new(-96, 0, -6), Vector3.new(44, WALL_H, 34), Color3.fromRGB(232, 214, 186), "posX")
	local counter = part({
		name = "Counter",
		parent = cafe,
		size = Vector3.new(20, 3, 4),
		cframe = CFrame.new(-96, 4, -18),
		color = C.food,
	})
	interact(counter, "Lunch", nil, "Eat lunch")
	tag(counter, "Cafeteria")
	for i = -1, 1 do
		local table1 = part({
			name = "Table",
			parent = cafe,
			size = Vector3.new(10, 1.4, 4),
			cframe = CFrame.new(-96 + i * 13, 3.4, 2),
			color = C.wood,
			material = Enum.Material.Wood,
		})
		interact(table1, "Lunch", nil, "Eat lunch")
	end

	-- Nurse office (safe room)
	local nurse = room(campus, "Nurse", Vector3.new(-48, 0, 60), Vector3.new(24, WALL_H, 20), Color3.fromRGB(238, 238, 244), "posX")
	local bed = part({
		name = "Bed",
		parent = nurse,
		size = Vector3.new(8, 1.6, 4),
		cframe = CFrame.new(-50, 3.4, 60),
		color = Color3.fromRGB(240, 240, 250),
	})
	interact(bed, "Rest", nil, "Rest here")
	tag(bed, "Nurse Office")

	-- Library
	local library = room(campus, "Library", Vector3.new(104, 0, 10), Vector3.new(30, WALL_H, 26), Color3.fromRGB(214, 190, 152), "negX")
	for i = -1, 1 do
		local shelf = part({
			name = "Shelf",
			parent = library,
			size = Vector3.new(7, 9, 2),
			cframe = CFrame.new(104 + i * 9, 7, 2),
			color = C.wood,
			material = Enum.Material.Wood,
		})
		interact(shelf, "Study", nil, "Study")
	end
	tag(library:FindFirstChild("Floor") :: BasePart, "Library")

	-- Shop
	local shop = part({
		name = "Shop",
		parent = campus,
		size = Vector3.new(16, 9, 10),
		cframe = CFrame.new(30, 7, 52),
		color = C.shop,
	})
	interact(shop, "Shop", nil, "Open shop")
	tag(shop, "School Shop")
	part({
		name = "ShopRoof",
		parent = campus,
		size = Vector3.new(20, 1.2, 14),
		cframe = CFrame.new(30, 12, 52),
		color = Color3.fromRGB(250, 214, 92),
	})

	-- Playground
	local field = part({
		name = "Playground",
		parent = campus,
		size = Vector3.new(100, 1, 64),
		cframe = CFrame.new(0, 2.6, -92),
		color = C.field,
		material = Enum.Material.Grass,
	})
	interact(field, "Play", { Subject = "gym", Room = "Playground" }, "Play / Gym class")
	tag(field, "Playground")
	part({
		name = "FieldLine",
		parent = campus,
		size = Vector3.new(1, 0.2, 64),
		cframe = CFrame.new(0, 3.2, -92),
		color = C.white,
		collide = false,
	})

	-- Lockers
	for i = 0, 7 do
		local locker = part({
			name = "Locker",
			parent = campus,
			size = Vector3.new(2.4, 8, 1.8),
			cframe = CFrame.new(-14 + i * 2.8, FLOOR_Y + 4.5, 1),
			color = if i % 2 == 0 then C.metal else Color3.fromRGB(206, 96, 96),
			material = Enum.Material.Metal,
		})
		interact(locker, "Locker", nil, "Open locker")
	end

	-- Hiding spots
	local hides = {
		{ Vector3.new(-20, 5, 4), "Behind Lockers" },
		{ Vector3.new(34, 5, -88), "Bushes" },
		{ Vector3.new(-34, 5, -88), "Bushes" },
		{ Vector3.new(20, 5, 68), "Bushes" },
		{ Vector3.new(-74, 5, 6), "Bushes" },
	}
	for index, spot in hides do
		local bush = part({
			name = "Hide" .. index,
			parent = campus,
			size = Vector3.new(8, 5, 5),
			cframe = CFrame.new(spot[1]),
			color = C.bush,
			material = Enum.Material.Grass,
		})
		CollectionService:AddTag(bush, "HideSpot")
		tag(bush, "Hide: " .. spot[2], Color3.fromRGB(190, 255, 200))
	end

	-- Free pickups
	local pickups = {
		{ "candy", Vector3.new(12, 4, 8), Color3.fromRGB(130, 78, 44), "Candy Bar" },
		{ "juice", Vector3.new(-70, 4, -6), Color3.fromRGB(255, 148, 88), "Brave Juice" },
	}
	for _, entry in pickups do
		local box = part({
			name = "Pickup",
			parent = campus,
			size = Vector3.new(2.6, 2.6, 2.6),
			cframe = CFrame.new(entry[2]),
			color = entry[3],
		})
		interact(box, "Pickup", { Item = entry[1] }, "Pick up")
		tag(box, entry[4])
	end

	local board = part({
		name = "StoryBoard",
		parent = campus,
		size = Vector3.new(18, 8, 0.6),
		cframe = CFrame.new(-28, 8, 56),
		color = C.sign,
	})
	faceText(board, "BRAVE KID\nRun, hide, or stand up", Enum.NormalId.Front, 26)

	local spawnPad = Instance.new("SpawnLocation")
	spawnPad.Name = "SchoolSpawn"
	spawnPad.Anchored = true
	spawnPad.Duration = 0
	spawnPad.Neutral = true
	spawnPad.Size = Vector3.new(16, 1, 16)
	spawnPad.CFrame = CFrame.new(0, 3.2, 60)
	spawnPad.Color = Color3.fromRGB(92, 168, 220)
	spawnPad.Material = Enum.Material.SmoothPlastic
	spawnPad.Parent = campus
	tag(spawnPad, "Start Here")

	for _, edge in {
		{ Vector3.new(520, 60, 4), Vector3.new(0, 30, 190) },
		{ Vector3.new(520, 60, 4), Vector3.new(0, 30, -230) },
		{ Vector3.new(4, 60, 420), Vector3.new(260, 30, -20) },
		{ Vector3.new(4, 60, 420), Vector3.new(-260, 30, -20) },
	} do
		part({
			name = "Edge",
			parent = campus,
			size = edge[1],
			cframe = CFrame.new(edge[2]),
			transparency = 1,
		})
	end

	return campus
end

return SchoolBuilder
