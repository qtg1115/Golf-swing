local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local DataService = {}

local STORE_NAME = "BraveKid_v1"
local profiles: { [number]: any } = {}
local store

local function getStore()
	if store ~= nil then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	store = if ok then result else false
	return store
end

local function newProfile()
	return {
		coins = Config.Start.coins,
		energy = Config.Start.energy,
		maxEnergy = Config.Start.maxEnergy,
		courage = Config.Start.courage,
		maxCourage = Config.Start.maxCourage,
		xp = Config.Start.xp,
		level = Config.Start.level,
		title = Config.Start.title,
		story = 0,
		storyClasses = 0,
		bag = {},
		gear = {},
		grades = Util.copy(Config.StartGrades),
		stats = {
			classes = 0,
			lunches = 0,
			escapes = 0,
			standups = 0,
			friendsHelped = 0,
			story = 0,
		},
		tasks = {},
		lastLunch = "",
		lastLocker = 0,
	}
end

local function repair(profile)
	local blank = newProfile()
	for key, value in blank do
		if profile[key] == nil then
			profile[key] = Util.copy(value)
		end
	end
	for key, value in blank.stats do
		if profile.stats[key] == nil then
			profile.stats[key] = value
		end
	end
	for key, value in blank.grades do
		if typeof(profile.grades[key]) ~= "number" then
			profile.grades[key] = value
		end
	end
	for _, task in Config.Tasks do
		if profile.tasks[task.id] == nil then
			profile.tasks[task.id] = { progress = 0, claimed = false }
		end
	end
	profile.stats.story = profile.story
	profile.title = Util.titleForLevel(profile.level, Config.Titles)
end

function DataService.leaderstats(player: Player, profile)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player
	end

	local function set(name: string, value: number)
		local entry = folder:FindFirstChild(name)
		if not entry then
			entry = Instance.new("IntValue")
			entry.Name = name
			entry.Parent = folder
		end
		entry.Value = math.floor(value + 0.5)
	end

	set("Level", profile.level)
	set("Courage", profile.courage)
	set("Coins", profile.coins)
end

function DataService.toClient(profile)
	return {
		coins = profile.coins,
		energy = profile.energy,
		maxEnergy = profile.maxEnergy,
		courage = profile.courage,
		maxCourage = profile.maxCourage,
		xp = profile.xp,
		xpNeeded = Util.xpForLevel(profile.level),
		level = profile.level,
		title = profile.title,
		story = profile.story,
		bag = Util.copy(profile.bag),
		gear = Util.copy(profile.gear),
		grades = Util.copy(profile.grades),
		gpa = Util.round(Util.average(profile.grades), 0),
		stats = Util.copy(profile.stats),
		tasks = Util.copy(profile.tasks),
		power = Util.standUpPower(profile),
	}
end

function DataService.load(player: Player)
	local profile = newProfile()
	local dataStore = getStore()
	if dataStore then
		local ok, saved = pcall(function()
			return dataStore:GetAsync("p_" .. player.UserId)
		end)
		if ok and typeof(saved) == "table" then
			for key, value in saved do
				profile[key] = value
			end
		end
	end
	repair(profile)
	profiles[player.UserId] = profile
	DataService.leaderstats(player, profile)
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

function DataService.bind()
	Players.PlayerRemoving:Connect(function(player)
		DataService.save(player)
		profiles[player.UserId] = nil
	end)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			DataService.save(player)
		end
	end)
end

return DataService
