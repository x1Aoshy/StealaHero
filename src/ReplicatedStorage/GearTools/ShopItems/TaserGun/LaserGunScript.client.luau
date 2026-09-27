-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMeC1ByaW1hcnlQYXJ0EEh1bWFub2lkUm9vdFBhcnQORmluZEZpcnN0Q2hpbGQIQmFzZVBhcnQDSXNBC2dldFJvb3RQYXJ0EENhbkFjdGl2YXRlTG9jYWwJQ2hhcmFjdGVyA0hpdAhQb3NpdGlvbglNYWduaXR1ZGUJZGlyZWN0aW9uBFVuaXQKRmlyZVNlcnZlcgtvbkFjdGl2YXRlZARnYW1lB1BsYXllcnMKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZQdyZXF1aXJlB0xpYnJhcnkGQ2xpZW50EVRvb2xHYW1lcGxheUd1YXJkC0xvY2FsUGxheWVyBnNjcmlwdAZQYXJlbnQOTGFzZXJHdW5SZW1vdGUIR2V0TW91c2UJQWN0aXZhdGVkB0Nvbm5lY3QAAwYBAAAABgMAAAUBBxFNAQCbAAAAAA4BAQCCAQIAbwQBALwCAAMCAAAAnwIDAg4CBgBvBQMAvAMC/gQAAACfAwMCDgMBAIICAgDGAwAAggMCAAUDAQMCAwMDBAMFABQGARgAAAEBAwAAAAEAAAAAAAEDABUAAAAACQAFAAAAOfsAAABNAAA8AAAAAPsBAQCfAAICKwABAIIAAQD7AAIATQAAaQEAAAArAAEAggABAE0CAJsCAAAADgICAFIBAgBlAA0AbwUDALwDAAMEAAAAnwMDAg4DBwBvBgUAvAQD/gYAAACfBAMCDgQCAFIBAwBlAAEAxgEAACsBAQCCAAEA+wIDAE0CAvsHAAAATQICOwgAAABNBAE7CAAAACYDAgRNBAOqCQAAAA0EAwAKAAAA8QQCAAQAAACCAAEA+wUEAOIHDABNCAMHDQAAADAIB0ELAAAAvAUFaw4AAACfBQMBggABAA8DBwMIAwEDAgMDAwQDBQMJAwoDCwIAAAAAAAAAAAMMBQELAw0DDgAiDwEYDgAAAAAAAQMAAAEB7AABAQADAAAAAQAAAAAAAQADDgEDAAAAAAEAAAEAAQAAAAEDAAEAAAD/AAADFQAAAAAMAAABAgAvowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqQCBgAAAFBATQMBagcAAABNAwNNCAAAAE0DA4IJAAAAnwICAk0DADEKAAAApAQMAAAAsEBNBAQkDQAAAE0FBJEOAAAAvAYDIw8AAACfBgICwAcQAMAIEQASAAIAEgAEABIAAwASAAYAEgAFAE0JBB4SAAAAUgsIALwJCccTAAAAnwkDAYIAAQAUAxAEAAAAQAMRAxIDEwMUBAAAUEADFQMWAxcDGAMZBAAAsEADGgMbAxwGAAYBAx0DHgIAAQEAARgAAgAAAAAAAQAAAAAAAQAAAAAAAAAACQABAAAAAQABAAADDgAAAAAAHAAAAAAAAQEAAAAAAs0l86ulehv6nmFnTzDbJcy9PeTf/+GZqg==

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolGameplayGuard = require(ReplicatedStorage.Library.Client.ToolGameplayGuard)
local LocalPlayer = Players.LocalPlayer
local scriptParent = script.Parent
local LaserGunRemote = scriptParent.LaserGunRemote
local Mouse = LocalPlayer:GetMouse()

local function getRootPart(p1) -- line: 20
	local PrimaryPart = p1.PrimaryPart

	if PrimaryPart then
		return PrimaryPart
	end

	local HumanoidRootPart = p1:FindFirstChild("HumanoidRootPart")

	if HumanoidRootPart and HumanoidRootPart:IsA("BasePart") then
		return HumanoidRootPart
	end

	return nil
end
local function onActivated() -- line: 34
	-- upvalues: ToolGameplayGuard (copy), scriptParent (copy), LocalPlayer (copy), Mouse (copy), LaserGunRemote (copy)
	if not ToolGameplayGuard.CanActivateLocal(scriptParent) then
		return
	end

	local Character = LocalPlayer.Character

	if not Character then
		return
	end

	local PrimaryPart = Character.PrimaryPart

	if PrimaryPart then
	else
		local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

		PrimaryPart = if not HumanoidRootPart or not HumanoidRootPart:IsA("BasePart") then nil else HumanoidRootPart
	end

	if not PrimaryPart then
		return
	end

	local v16 = Mouse.Hit.Position - PrimaryPart.Position
	local Magnitude = v16.Magnitude

	if Magnitude == 0.0 or Magnitude ~= Magnitude then
		return
	end

	LaserGunRemote:FireServer({
		direction = v16.Unit
	})
end

scriptParent.Activated:Connect(onActivated)

