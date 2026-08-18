local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local FOLDER_NAME = "SchoolRemotes"
local REMOTE_NAMES = {
	"GetProfile",
	"ProfileUpdated",
	"PeriodChanged",
	"Notify",
	"StoryUpdated",
	"Dialogue",
	"BuyItem",
	"UseItem",
	"ClaimQuest",
	"EncounterStart",
	"EncounterEnd",
	"EncounterAction",
	"BullyWarning",
}

local function getFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if folder and folder:IsA("Folder") then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

function Remotes.ensure(): Folder
	local folder = getFolder()
	for _, name in REMOTE_NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	return folder
end

function Remotes.get(name: string): RemoteEvent
	local folder = Remotes.ensure()
	local remote = folder:WaitForChild(name, 10)
	assert(remote and remote:IsA("RemoteEvent"), "Missing remote: " .. name)
	return remote
end

return Remotes
