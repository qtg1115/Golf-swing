local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local FOLDER_NAME = "SchoolRemotes"
local NAMES = {
	"GetProfile",
	"ProfileUpdated",
	"PeriodChanged",
	"StoryUpdated",
	"Dialogue",
	"Notify",
	"OpenShop",
	"BuyItem",
	"UseItem",
	"ClaimTask",
	"EncounterStart",
	"EncounterEnd",
	"EncounterAction",
	"BullyWarning",
}

local function folder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = ReplicatedStorage
	return created
end

function Remotes.ensure(): Folder
	local parent = folder()
	for _, name in NAMES do
		if not parent:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = parent
		end
	end
	return parent
end

function Remotes.get(name: string): RemoteEvent
	local parent = ReplicatedStorage:WaitForChild(FOLDER_NAME, 20)
	assert(parent, "Remote folder missing")
	local remote = parent:WaitForChild(name, 20)
	assert(remote and remote:IsA("RemoteEvent"), "Missing remote: " .. name)
	return remote
end

return Remotes
