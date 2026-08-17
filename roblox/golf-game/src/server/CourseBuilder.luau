--!strict
-- 코스를 코드로 생성하는 모듈입니다.
-- (모델 파일 대신 스크립트로 월드를 만들기 때문에 Rojo 코드 동기화만으로 완성됩니다.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.GolfShared.Config)

local CourseBuilder = {}

-- 앵커된 파트를 간단히 만들어 주는 헬퍼.
local function makePart(
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

function CourseBuilder.build(parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = "GolfCourse"

	local course = Config.Course
	local groundTopY = 0 -- 지면 윗면의 Y좌표를 0으로 맞춥니다.

	-- 페어웨이(잔디 바닥)
	local ground = makePart(
		"Fairway",
		Vector3.new(course.Width, course.GroundThickness, course.Length),
		Vector3.new(0, groundTopY - course.GroundThickness / 2, 0),
		Color3.fromRGB(88, 158, 76),
		Enum.Material.Grass
	)
	ground.Parent = folder

	-- 코스 밖으로 공이 나가지 않도록 양옆에 낮은 벽을 세웁니다.
	local wallHeight = 6
	for _, side in { -1, 1 } do
		local wall = makePart(
			"Wall",
			Vector3.new(1, wallHeight, course.Length),
			Vector3.new(side * course.Width / 2, groundTopY + wallHeight / 2, 0),
			Color3.fromRGB(120, 110, 95),
			Enum.Material.WoodPlanks
		)
		wall.Parent = folder
	end

	-- 티 박스(출발 발판)
	local tee = makePart(
		"TeeBox",
		Vector3.new(10, 1, 10),
		Vector3.new(Config.TeeGround.X, groundTopY + 0.5, Config.TeeGround.Z),
		Color3.fromRGB(60, 120, 200),
		Enum.Material.SmoothPlastic
	)
	tee.Parent = folder

	-- 홀(구멍) - 어두운 원기둥으로 표현
	local hole = Instance.new("Part")
	hole.Name = "Hole"
	hole.Shape = Enum.PartType.Cylinder
	hole.Size = Vector3.new(1, Config.Hole.Radius * 2, Config.Hole.Radius * 2)
	-- Cylinder는 X축이 높이 방향이라 눕혀서 세웁니다.
	hole.CFrame = CFrame.new(Config.Hole.Position.X, groundTopY + 0.05, Config.Hole.Position.Z)
		* CFrame.Angles(0, 0, math.rad(90))
	hole.Color = Color3.fromRGB(20, 20, 20)
	hole.Material = Enum.Material.SmoothPlastic
	hole.Anchored = true
	hole.CanCollide = false
	hole.Parent = folder

	-- 깃대
	local pole = makePart(
		"FlagPole",
		Vector3.new(0.3, 14, 0.3),
		Vector3.new(Config.Hole.Position.X, groundTopY + 7, Config.Hole.Position.Z),
		Color3.fromRGB(240, 240, 240),
		Enum.Material.Metal
	)
	pole.Parent = folder

	-- 깃발
	local flag = makePart(
		"Flag",
		Vector3.new(0.2, 3, 5),
		Vector3.new(Config.Hole.Position.X, groundTopY + 12, Config.Hole.Position.Z + 2.5),
		Color3.fromRGB(220, 50, 50),
		Enum.Material.Fabric
	)
	flag.Parent = folder

	folder.Parent = parent
	return folder
end

return CourseBuilder
