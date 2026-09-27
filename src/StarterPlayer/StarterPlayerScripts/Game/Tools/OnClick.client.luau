-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Gears = require(ReplicatedStorage.Directory.Gears)
local Network = require(ReplicatedStorage.Library.Client.Network)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local ToolGameplayGuard = require(ReplicatedStorage.Library.Client.ToolGameplayGuard)
local ToolInput = Constants.NETWORK_MAP.ToolInput
local t1 = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true
}
local LocalPlayer = Players.LocalPlayer

local function isBatTool(p1) -- line: 29
	-- upvalues: Asserts (copy), Gears (copy)
	local GearName = p1:GetAttribute("GearName")

	Asserts.optional.string(GearName)

	if GearName == nil then
		return false
	end

	return Gears.Types.GearNameExists(GearName) and Gears.Directory[GearName].BatControllerData ~= nil
end
local function trySendActivation() -- line: 40
	-- upvalues: LocalPlayer (copy), ToolGameplayGuard (copy), Asserts (copy), Gears (copy), Network (copy), ToolInput (copy)
	local v16 = LocalPlayer

	if not v16 then
		return
	end

	local Character = v16.Character

	if not Character then
		return
	end

	local Tool = Character:FindFirstChildWhichIsA("Tool")

	if not Tool then
		return
	end

	if not ToolGameplayGuard.CanActivateLocal(Tool) then
		return
	end

	local GearName = Tool:GetAttribute("GearName")

	Asserts.optional.string(GearName)

	if GearName ~= nil and (Gears.Types.GearNameExists(GearName) and Gears.Directory[GearName].BatControllerData ~= nil) then
		return
	end

	Network.Fire(ToolInput.ACTIVATE, Tool)
end

UserInputService.InputBegan:Connect(function(input) -- line: 69
	-- upvalues: t1 (copy), trySendActivation (copy)
	if not t1[input.UserInputType] then
		return
	end

	trySendActivation()
end)

