-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local scriptParent = script.Parent
local Network = require(ReplicatedStorage.Library.Client.Network)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local ToolGameplayGuard = require(ReplicatedStorage.Library.Client.ToolGameplayGuard)
local Traps = Constants.NETWORK_MAP.Traps
local n1 = 0.0

local function onActivated() -- line: 16
	-- upvalues: ToolGameplayGuard (copy), scriptParent (copy), n1 (ref), LocalPlayer (copy), Network (copy), Traps (copy)
	if not ToolGameplayGuard.CanActivateLocal(scriptParent) then
		return
	end

	local timestamp = tick()

	if timestamp - n1 < 1.0 then
		return
	end

	if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then
		return
	end

	n1 = timestamp

	local Character = LocalPlayer.Character
	local PrimaryPart = Character.PrimaryPart
	local LookVector = PrimaryPart.CFrame.LookVector
	local v15 = PrimaryPart.Position + LookVector * 4.0
	local raycastParams = RaycastParams.new()

	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { Character }

	if workspace:Raycast(PrimaryPart.Position, LookVector * 4.0, raycastParams) then
		return
	end

	local vector3 = Vector3.new(v15.X, v15.Y + 5.0, v15.Z)
	local raycastResult = workspace:Raycast(vector3, Vector3.new(0.0, -100.0, 0.0), raycastParams)
	local v19 = if not raycastResult then v15 else raycastResult.Position
	local GearName = scriptParent:GetAttribute("GearName")

	if typeof(GearName) ~= "string" then
		GearName = scriptParent.Name
	end

	Network.Fire(Traps.REQUEST_PLACE, GearName, v19)
end

scriptParent.Activated:Connect(onActivated)

