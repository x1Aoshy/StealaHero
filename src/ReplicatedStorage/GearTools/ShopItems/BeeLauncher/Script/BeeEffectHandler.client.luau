-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local function createScreenEffect() -- line: 8
	local Lighting = game:GetService("Lighting")
	local ColorCorrectionEffect = Instance.new("ColorCorrectionEffect")

	ColorCorrectionEffect.Name = "BeeEffect"
	ColorCorrectionEffect.TintColor = Color3.fromRGB(255.0, 255.0, 0.0)
	ColorCorrectionEffect.Saturation = 0.5
	ColorCorrectionEffect.Parent = Lighting
	game:GetService("Debris"):AddItem(ColorCorrectionEffect, 5.0)
end
local function createVFX() -- line: 20
	-- upvalues: ReplicatedStorage (copy), LocalPlayer (copy)
	local clone = ReplicatedStorage.Assets.ToolEffects.BeeToolEffect:Clone()
	local Character = LocalPlayer.Character
	local v14 = Character and Character:FindFirstChild("Head")

	if not v14 then
		return
	end

	clone.CFrame = v14.CFrame

	local WeldConstraint = Instance.new("WeldConstraint")

	WeldConstraint.Parent = clone
	WeldConstraint.Part0 = v14
	WeldConstraint.Part1 = clone
	clone.Parent = v14
	game:GetService("Debris"):AddItem(clone, 5.0)
end
local function invertMovement() -- line: 39
	-- upvalues: LocalPlayer (copy)
	local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local Controls = require(PlayerScripts:WaitForChild("PlayerModule")):GetControls()
	local moveFunction = Controls.moveFunction

	function Controls.moveFunction(p1, p2, p3) -- line: 47
		-- upvalues: moveFunction (copy)
		return moveFunction(p1, -p2, p3)
	end

	spawn(function() -- line: 51
		-- upvalues: Controls (copy), moveFunction (copy)
		wait(5.0)
		Controls.moveFunction = moveFunction
	end)
end
local function zoomCameraCloser() -- line: 57
	local CurrentCamera = workspace.CurrentCamera

	if not CurrentCamera then
		return
	end

	local FieldOfView = CurrentCamera.FieldOfView

	CurrentCamera.FieldOfView = FieldOfView / 2.4
	spawn(function() -- line: 67
		-- upvalues: CurrentCamera (copy), FieldOfView (copy)
		wait(5.0)

		if CurrentCamera then
			CurrentCamera.FieldOfView = FieldOfView
		end
	end)
end

createScreenEffect()
createVFX()
invertMovement()

local CurrentCamera = workspace.CurrentCamera

if not CurrentCamera then
	return
end

local FieldOfView = CurrentCamera.FieldOfView

CurrentCamera.FieldOfView = FieldOfView / 2.4
spawn(function() -- line: 67
	-- upvalues: CurrentCamera (copy), FieldOfView (copy)
	wait(5.0)

	if CurrentCamera then
		CurrentCamera.FieldOfView = FieldOfView
	end
end)

