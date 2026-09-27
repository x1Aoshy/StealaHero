-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhCkxvb2tWZWN0b3IBWAFaB1ZlY3RvcjMDbmV3CU1hZ25pdHVkZUFBc3NldCBmcm9udCBwbGFjZW1lbnQgcmVxdWlyZXMgYSBob3Jpem9udGFsIHJvb3QgZmFjaW5nIGRpcmVjdGlvbgZhc3NlcnQEVW5pdARTaXplBG1hdGgDbWF4CFBvc2l0aW9uBkNGcmFtZRJQb2ludFRvT2JqZWN0U3BhY2UFY2xhbXAGbG9va0F0IGNmcmFtZUluRnJvbnRPZlJvb3RDbGFtcGVkVG9BcmVhBnN0cmluZwpSb290Q0ZyYW1lCUV4cGlyZXNBdAJvcwVjbG9jaxFTZXRGcm9udFBsYWNlbWVudAhCYXNlUGFydBVDb25zdW1lRnJvbnRQbGFjZW1lbnQTQ2xlYXJGcm9udFBsYWNlbWVudARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMBDgAFEQIAAAAHBAAABQJAB2BNAgBoAAAAAE0EAnkBAAAAjAUAAE0GAnsCAAAATDYAAqQDBQAAEDCAnwMEAk0GA6oGAAAAjAcAALcHAgAGAAAAqQUAAakFAQCBAQUEBwAAAG8GBwCkBAkAAACAQJ8EAwFNBAMHCgAAAE0FAS8LAAAATQkFeQEAAABbCAkNeAcIDIESBwQOAAAAbwgOAKQGEQAAQPCAnwYDAk0KBXsCAAAAWwkKDXgICQyBEggEDgAAAG8JDgCkBxEAAEDwgJ8HAwJNCQA7EgAAAFsKBBNDCAkKTQkBhRQAAABSCwgAvAkJxhUAAACfCQMCTQwJeQEAAAA5DQYANC4MBA0GAABSDgYApAsXAABY8ICfCwQCjAwAAE0OCXsCAAAAOQ8HADQuDgQPBwAAUhAHAKQNFwAAWPCAnw0EAkw2AAKkCgUAABAwgJ8KBAJNDAGFFAAAAKQNGAAAEECBUg4KAJ8NAgIJCwwNTQsLOxIAAACkDBoAAGRAgVINCwBDDgsEnwwDAIIMAAAbAwEDAgMDAwQDBQQAEDCAAwYDBwMIBAAAgEADCQMKAgAAAAAAAPw/AgAAAAAAAOA/AgAAAAAAAAAAAwsDDAQAQPCAAw0CAAAAAAAAGEADDgMPAxAEAFjwgAQAEECBAxEEAGRAgQAeEgEYAAABAAAAAAAAAAABAAAAAAAAAAAAAAAAAgABAAEAAAAAAAAAAAABAAAAAAAAAAAAAQAAAAEAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAgAAAAAAHwAAAAAGAgIAAAcEAAAFAgNAFvsCAABNAgJBAAAAAFIDAACfAgIB+wIAAE0CAoUBAAAAUgMBAJ8CAgH7AgEA4gMEADABAxgCAAAApAUIAAAcYICfBQEClQQFBTAEAy8DAAAAagMCAIIAAQAJAxMDDgMUAxUFAgIDAgAAAAAAACRAAxYDFwQAHGCAADQYARgAAAAAAAEAAAAAAgABAAEAAAAAAP4ENQAAAAAGAgMAAAcEAAAFAgMHIPsCAABNAgJBAAAAAFIDAACfAgIB+wIAAE0CAmMBAAAAUgMBAJ8CAgH7AwEAhwIDAPsDAQDGBAAAagQDAEcCCAAAAAAATQMCLwIAAACkBAUAABAwgJ8EAQJgAwMABAAAAMYDAACCAwIA+wMCAE0EAhgGAAAAUgUBAJ8DAwCCAwAABwMTAxkDFQMWAxcEABAwgAMUAD4aARgAAAAAAAEAAAAAAgABAAABAAAAAAAAAAABAAMAAAAAAD8AAAAAAwECAAAGAwAABQEDCfsBAABNAQFBAAAAAFICAACfAQIB+wEBAMYCAABqAgEAggABAAEDEwBLGwEYAAAAAAACAAABTAAAAAAGAAABAgAkowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgL/AgAAAAAAAP8DAwAAAAAAwAQIAMAFCQASAAEAEgACADAFA+QKAAAAwAULABIAAQASAAIAEgAEADAFAwEMAAAAwAUNABIAAQASAAIAMAUDfA4AAACCAwIADwMcBAAAAEADHQMeAx8EAABAQAMgAyEGAAYBAxgGAgMaBgMDGwQAAQIDAQABGAADAAAAAAADAAAAAAAADgADAAYWAAAAAAoAAAAAAA0AAAAABgEAAAAABMl8THohcDeargXUKSr7WEq5ZFsO+7gmew==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local t1 = {}
local t2 = {}

local function cframeInFrontOfRootClampedToArea(cFrame: CFrame, p1) -- line: 30
	local LookVector = cFrame.LookVector
	local vector3 = Vector3.new(LookVector.X, 0.0, LookVector.Z)

	assert(vector3.Magnitude > 0.0, "Asset front placement requires a horizontal root facing direction")

	local Unit = vector3.Unit
	local p1Size = p1.Size
	local v12 = math.max(p1Size.X * 0.5 - 1.75, 0.0)
	local v13 = math.max(p1Size.Z * 0.5 - 1.75, 0.0)
	local v14 = cFrame.Position + Unit * 6.0
	local v15 = p1.CFrame:PointToObjectSpace(v14)
	local vector3_2 = Vector3.new(math.clamp(v15.X, -v12, v12), 0.0, (math.clamp(v15.Z, -v13, v13)))
	local Position = (p1.CFrame * CFrame.new(vector3_2)).Position

	return CFrame.lookAt(Position, Position + Unit)
end

function t2.SetFrontPlacement(s1: string, cFrame: CFrame) -- line: 52
	-- upvalues: Asserts (copy), t1 (copy)
	Asserts.string(s1)
	Asserts.CFrame(cFrame)
	t1[s1] = {
		RootCFrame = cFrame,
		ExpiresAt = os.clock() + 10.0
	}
end
function t2.ConsumeFrontPlacement(s2: string, p2) -- line: 62
	-- upvalues: Asserts (copy), t1 (copy), cframeInFrontOfRootClampedToArea (copy)
	Asserts.string(s2)
	Asserts.BasePart(p2)

	local v22 = t1[s2]

	t1[s2] = nil

	if v22 == nil or v22.ExpiresAt < os.clock() then
		return nil
	end

	return cframeInFrontOfRootClampedToArea(v22.RootCFrame, p2)
end
function t2.ClearFrontPlacement(s3: string) -- line: 75
	-- upvalues: Asserts (copy), t1 (copy)
	Asserts.string(s3)
	t1[s3] = nil
end

return t2

