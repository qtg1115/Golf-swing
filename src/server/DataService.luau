local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local DataService = {}

local STORE_NAME = "SchoolSim_v1"
local profiles: { [number]: any } = {}
local store

local function getStore()
	if store then
		return store
	end

	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	end
	return store
end

local function blankProfile()
	return {
		coins = Config.Starting.coins,
		energy = Config.Starting.energy,
		maxEnergy = Config.Starting.maxEnergy,
		popularity = Config.Starting.popularity,
		xp = Config.Starting.xp,
		level = Config.Starting.level,
		title = "신입생",
		grades = Util.deepCopy(Config.StartingGrades),
		stats = {
			classesAttended = 0,
			lunchesEaten = 0,
			talks = 0,
			plays = 0,
			skipped = 0,
		},
		quests = {},
		owned = {},
		lastLunchPeriod = "",
		lastTalkAt = 0,
	}
end

local function ensureQuestState(profile)
	for _, quest in Config.Quests do
		if not profile.quests[quest.id] then
			profile.quests[quest.id] = {
				progress = 0,
				claimed = false,
			}
		end
	end
end

function DataService.createLeaderstats(player: Player, profile)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player
	end

	local function stat(name: string, value: number)
		local int = folder:FindFirstChild(name)
		if not int then
			int = Instance.new("IntValue")
			int.Name = name
			int.Parent = folder
		end
		int.Value = math.floor(value + 0.5)
	end

	stat("성적", Util.average(profile.grades))
	stat("인기", profile.popularity)
	stat("코인", profile.coins)
end

function DataService.publicProfile(profile)
	return {
		coins = profile.coins,
		energy = profile.energy,
		maxEnergy = profile.maxEnergy,
		popularity = profile.popularity,
		xp = profile.xp,
		level = profile.level,
		title = profile.title,
		grades = Util.deepCopy(profile.grades),
		gpa = Util.round(Util.average(profile.grades), 1),
		stats = Util.deepCopy(profile.stats),
		quests = Util.deepCopy(profile.quests),
		owned = Util.deepCopy(profile.owned),
	}
end

function DataService.load(player: Player)
	local profile = blankProfile()
	local dataStore = getStore()
	if dataStore then
		local ok, saved = pcall(function()
			return dataStore:GetAsync("p_" .. player.UserId)
		end)
		if ok and typeof(saved) == "table" then
			for key, value in saved do
				profile[key] = value
			end
			if typeof(saved.grades) == "table" then
				for key, value in Config.StartingGrades do
					if typeof(saved.grades[key]) ~= "number" then
						profile.grades[key] = value
					end
				end
			end
		end
	end

	ensureQuestState(profile)
	profiles[player.UserId] = profile
	DataService.createLeaderstats(player, profile)
	return profile
end

function DataService.get(player: Player)
	return profiles[player.UserId]
end

function DataService.save(player: Player)
	local profile = profiles[player.UserId]
	local dataStore = getStore()
	if not profile or not dataStore then
		return
	end

	pcall(function()
		dataStore:SetAsync("p_" .. player.UserId, profile)
	end)
end

function DataService.release(player: Player)
	DataService.save(player)
	profiles[player.UserId] = nil
end

function DataService.bind()
	Players.PlayerRemoving:Connect(function(player)
		DataService.release(player)
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			DataService.save(player)
		end
	end)
end

return DataService
