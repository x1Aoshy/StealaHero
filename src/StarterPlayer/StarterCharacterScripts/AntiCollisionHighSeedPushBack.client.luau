-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbCEdldFN0YXRlBEVudW0RSHVtYW5vaWRTdGF0ZVR5cGUHUnVubmluZxBSdW5uaW5nTm9QaHlzaWNzCVdhbGtTcGVlZBZBc3NlbWJseUxpbmVhclZlbG9jaXR5CU1hZ25pdHVkZQdWZWN0b3IzA25ldxBvblBvc3RTaW11bGF0aW9uCkRpc2Nvbm5lY3QEZ2FtZQpSdW5TZXJ2aWNlCkdldFNlcnZpY2UGc2NyaXB0BlBhcmVudAhIdW1hbm9pZAxXYWl0Rm9yQ2hpbGQLRmFsbGluZ0Rvd24PU2V0U3RhdGVFbmFibGVkB1JhZ2RvbGwPQXV0b0p1bXBFbmFibGVkEEh1bWFub2lkUm9vdFBhcnQOUG9zdFNpbXVsYXRpb24HQ29ubmVjdAREaWVkAAMJAQIAAAcAAAEIBSYBKvsBAAC8AQF2AAAAAJ8BAgKkAgQAAwgQwPEBBQACAAAApAIGAAUIEMCaAR4AAgAAAPsCAABNAgKOBwAAAIwDMgB9AxgAAgAAAPsCAQBNAgIXCAAAAE0CAqoJAAAAjAMKAGADEAACAAAA+wIBAPsEAQBNBAQXCAAAAIwGAACMCM7/CQcIAIwIAABMNgACpAUMAAAsoICfBQQCQwMEBTADAhcIAAAAggABAA0DAQMCAwMDBAQDCBDAAwUEBQgQwAMGAwcDCAMJAwoEACyggAAPCwEYAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAACEAAAAAACAAEAAAAF+wAAALwAABoAAAAAnwACAYIAAQABAwwAGAABGAAAAAABGQAAAAAJAAABAgAzowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQEBJAYAAABvBAcAvAIB0wgAAACfAgMCpAUMAAsokMCpBgAAvAMC6A0AAACfAwQBpAUPAA4okMCpBgAAvAMC6A0AAACfAwQBqQMAADADAmMQAAAAbwURALwDAdMIAAAAnwMDAsAEEgASAAIAEgADAE0FALYTAAAAUgcEALwFBccUAAAAnwUDAk0GAscVAAAAwAgWABIABQC8BgbHFAAAAJ8GAwGCAAEAFwMNBAAAAEADDgMPAxAEAABAQAMRAxIDEwMCAwMDFAQLKJDAAxUDFgQOKJDAAxcDGAYAAxkDGgMbBgECAAEBAAEYAAMAAAAAAAMAAAABAAAAAgAAAAAAAQAAAAAAAQAAAgAAAAEAAAgAAAAAAAEAAAAAAAADAQAAAAACIDaXkDkA0HCCJS5BqEkckVAugOQS8v2R

-- decompilation:
local RunService = game:GetService("RunService")
local scriptParent = script.Parent
local Humanoid = scriptParent:WaitForChild("Humanoid")

Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
Humanoid.AutoJumpEnabled = false

local HumanoidRootPart = scriptParent:WaitForChild("HumanoidRootPart")

local function onPostSimulation(p1) -- line: 15
	-- upvalues: Humanoid (copy), HumanoidRootPart (copy)
	local State = Humanoid:GetState()

	if (State == Enum.HumanoidStateType.Running or State == Enum.HumanoidStateType.RunningNoPhysics) and (Humanoid.WalkSpeed >= 50.0 and HumanoidRootPart.AssemblyLinearVelocity.Magnitude > 10.0) then
		HumanoidRootPart.AssemblyLinearVelocity = HumanoidRootPart.AssemblyLinearVelocity + Vector3.new(0.0, -50.0 * p1, 0.0)
	end
end

local connection = RunService.PostSimulation:Connect(onPostSimulation)

Humanoid.Died:Connect(function() -- line: 24
	-- upvalues: connection (copy)
	connection:Disconnect()
end)

