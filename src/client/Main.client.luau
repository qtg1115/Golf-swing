local Players = game:GetService("Players")

local Hud = require(script.Parent.Hud)

local ok, err = pcall(Hud.mount)
if not ok then
	warn("[BraveKid] HUD failed to load:", err)
end

local player = Players.LocalPlayer

-- Client-side backup so a fall never ends the session.
local function watch(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or not root:IsA("BasePart") then
		return
	end
	while character.Parent do
		if root.Position.Y < -40 then
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = CFrame.new(0, 10, 60)
		end
		task.wait(0.5)
	end
end

player.CharacterAdded:Connect(function(character)
	task.spawn(watch, character)
end)
if player.Character then
	task.spawn(watch, player.Character)
end
