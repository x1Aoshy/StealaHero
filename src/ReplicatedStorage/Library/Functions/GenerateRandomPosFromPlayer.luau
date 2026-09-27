-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMZBlBsYXllcglDaGFyYWN0ZXIOQ2hhcmFjdGVyQWRkZWQEV2FpdBBIdW1hbm9pZFJvb3RQYXJ0DFdhaXRGb3JDaGlsZAlBdFdhcm5pbmc8RmFpbGVkIHRvIGdlbiBybmcgcG9zIGZyb20gcGxheWVyICIlKiIsIHByaW1hcnkgcGFydCB0aW1lb3V0BE5hbWUGZm9ybWF0A0xvZxBwb3NpdGl2ZVlWZWN0b3IzB1ZlY3RvcjMIUG9zaXRpb24GbnVtYmVyBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwNuZXcHQXNzZXJ0cwxCZXR0ZXJSYW5kb20AAgwCAwAABwQAAAUCB4E2+wIAAE0CAvkAAAAAUgMAAJ8CAgFNAgBpAQAAACsCBQBNAgCXAgAAALwCAvcDAAAAnwICAm8FBACMBjwAvAMC0wUAAACfAwQCKwMOAPsEAQC8BAQKBgAAAJ8EAgJvBgcATQgAuggAAAC8BgaNCQAAAJ8GAwK8BAShCgAAAJ8EAwCCBAAADgEFAPsEAgC8BATNCwAAAJ8EAgIrBAQA+wQCALwEBE8MAAAAnwQCAk0GAzsNAAAA+wgCAIwKFACMCzIAvAgIYA4AAACfCAQCCQcECEMFBgeCBQIADwMBAwIDAwMEAwUDBgMHAwgDCQMKAwsDDAMNAw4DDwALAAEYAAAAAAACAAAAAAAAAAEAAAAAAgEAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAIAAAAAAAAAAAAADAAAAAAGAAABAgAtowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLoBwAAAE0CAuYIAAAATQICoQkAAACfAQICTQIB7woAAACfAgECpAMFAAAAQEBNBABqBgAAAE0EBIkLAAAAnwMCAqQEBQAAAEBATQUAagYAAABNBQXoBwAAAE0FBWAMAAAAnwQCAk0EBO8KAAAAnwQBAsAFDQASAAMAEgACABIABACCBQIADgMQBAAAAEADEQMSAxMEAABAQAMUAxUDFgMLAxcDGAMZBgABAAEAARgAAQAAAAAAAwAAAAAAAAAAAAABAAABAAAAAAAAAQAAAAAAAAAAAAAAAwAAAAABAAAAAAE+o+NZGKqdpSNhJOSPS1plTrv0LQxniVg=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local v2 = require(ReplicatedStorage.Library.Modules.Packages.Log).new()
local Asserts = require(ReplicatedStorage.Library.Asserts)
local v4 = require(ReplicatedStorage.Library.Modules.BetterRandom).new()

return function(p1, b1: boolean?) -- line: 11
	-- upvalues: Asserts (copy), v2 (copy), v4 (copy)
	Asserts.Player(p1)

	local HumanoidRootPart = (p1.Character or p1.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart", 60.0)

	if not HumanoidRootPart then
		return v2:AtWarning():Log(`Failed to gen rng pos from player "{ p1.Name }", primary part timeout`)
	end

	local v8 = b1 and v4:positiveYVector3() or v4:Vector3()

	return HumanoidRootPart.Position + v8 * v4:number(20.0, 50.0)
end

