-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMiBU1vZGVsCEJhc2VQYXJ0CEdldFBpdm90CEluc3RhbmNlA25ldwRQYXJ0HEFzc2V0SW50ZXJhY3Rpb25Qcm9tcHRBbmNob3IETmFtZQRTaXplDFRyYW5zcGFyZW5jeQpDYW5Db2xsaWRlCENhblF1ZXJ5CENhblRvdWNoCE1hc3NsZXNzAVkGQ0ZyYW1lCFBvc2l0aW9uAVgEbWF0aANtaW4BWgZQYXJlbnQOV2VsZENvbnN0cmFpbnQFUGFydDAFUGFydDEGQ3JlYXRlBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwlGdW5jdGlvbnMWQkJGcm9tTW9kZWxWaXNpYmxlT25seQACDgICAAAHBAAABQIHB1P7AgAATQICOwAAAABSAwAAnwICAfsCAABNAgJjAQAAAFIDAQCfAgIBvAIAUgIAAACfAgIC+wMBAFIEAACfAwIDpAUFAAAQMIBvBgYAnwUCAm8GBwAwBgW6CAAAAG8GCQAwBgUvCgAAAIwGAQAwBgXZCwAAAKkGAAAwBgXTDAAAAKkGAAAwBgViDQAAAKkGAAAwBgX2DgAAAKkGAQAwBgWlDwAAAE0HBHgRAAAAWwYHEKQHEwAAECCBTQgCOxQAAABNCAh5FQAAAE0LAzsUAAAATQsLeBEAAAAmCgsGjAwDAJ4TDAQGAAAAUg0GAKQLGAAAXGCBnwsDAkMJCgtNCgI7FAAAAE0KCnsZAAAAnwcEAjAHBYUSAAAAMAAFJBoAAACkBwUAABAwgG8IGwCfBwICMAEHPBwAAAAwBQexHQAAADAFByQaAAAAggUCAB4DAQMCAwMDBAMFBAAQMIADBgMHAwgHAACAPwAAgD8AAIA/AAAAAAMJAwoDCwMMAw0DDgIAAAAAAADgPwMPAxAEABAggQMRAxIDEwMUBABcYIEDFQMWAxcDGAMZABEaARgAAAAAAAEAAAAAAgAAAQAAAQAAAAEAAAEAAAEAAAEAAAEAAAEAAAEAAAEAAAEAAQAAAAEAAAAAAAAAAAAAAAABAAAA/QAABQACAAAAAQABAAEAARIAAAAABQAAAQIAH6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICpAIFAAAAQEBNAwBqBgAAAE0DA1MIAAAATQMDhQkAAACfAgIC/wMBAAAAAADABAoAEgABABIAAgAwBAOWCwAAAIIDAgAMAxsEAAAAQAMcAx0DHgQAAEBAAx8DIAMhAyIGAAMaAQABAAEYAAMAAAAAAAMAAAAAAAABAAAAAAAAAAADAAYAAAAAHQEAAAAAAcPmnaYQfXcbryl4aFfwa0Sz/orS8SL3pw==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local BBFromModelVisibleOnly = require(ReplicatedStorage.Library.Functions.BBFromModelVisibleOnly)

return {
	Create = function(p1, p2) -- line: 17
		-- upvalues: Asserts (copy), BBFromModelVisibleOnly (copy)
		Asserts.Model(p1)
		Asserts.BasePart(p2)

		local Pivot = p1:GetPivot()
		local v7, v8 = BBFromModelVisibleOnly(p1)
		local Part = Instance.new("Part")

		Part.Name = "AssetInteractionPromptAnchor"
		Part.Size = Vector3.new(1.0, 1.0, 1.0)
		Part.Transparency = 1.0
		Part.CanCollide = false
		Part.CanQuery = false
		Part.CanTouch = false
		Part.Massless = true

		local v10 = v8.Y * 0.5

		Part.CFrame = CFrame.new(Pivot.Position.X, v7.Position.Y - v10 + math.min(3.0, v10), Pivot.Position.Z)
		Part.Parent = p1

		local WeldConstraint = Instance.new("WeldConstraint")

		WeldConstraint.Part0 = p2
		WeldConstraint.Part1 = Part
		WeldConstraint.Parent = Part

		return Part
	end
}

