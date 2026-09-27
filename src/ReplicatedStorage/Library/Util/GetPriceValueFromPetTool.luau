-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMZBFRvb2wHUGV0VHlwZQxHZXRBdHRyaWJ1dGUKQmFzZVdlaWdodAVTY2FsZQNBZ2UFTGV2ZWwIUEVUX1VVSUQEVVVJRAdQZXREYXRhAAROYW1lBldlaWdodA1MZXZlbFByb2dyZXNzBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQTR2V0UHJpY2VWYWx1ZUZvclBldAdMaWJyYXJ5B0Fzc2VydHMJRGlyZWN0b3J5C1BldFJlZ2lzdHJ5AAIKAQIAAAYDAAAFAQc9+wEAAE0BAU4AAAAAUgIAAJ8BAgFvAwEAvAEAEgIAAACfAQMCbwQDALwCABICAAAAnwIDAm8FBAC8AwASAgAAAJ8DAwJvBgUAvAQAEgIAAACfBAMCbwcGALwFABICAAAAnwUDAm8IBwC8BgASAgAAAJ8GAwIOAQIADgIBACsDAgCMBwAAggcCAOIHCgCQCAYLMAgHMggAAAAwAQcSAQAAAOIIEACQCQQPMAkI9gUAAACQCQURMAkIbQYAAABNCQC6DAAAADAJCLoMAAAAMAII/gMAAAAwAwirDQAAADAIB5oJAAAA+wgBAFIJBwCfCAIAgggAABIDAQMCAwMDBAMFAwYDBwMIAwkDCgUDCAEJAwsDDAMNAw4CAAAAAAAAAAAIBgX/////Bv////8M/////wP/////Df////8ODwAAAAIAAAAAAADwPwAMAAEYAAAAAAACAAAAAQAAAAEAAAABAAAAAQAAAAEAAAACAAABAAMBAAABAAEBAAABAAABAAAAAQABAPsACgAAAA0AAAAABQAAAQIAIqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQKQCBwAAAGBATQICJAgAAABNAgJYCQAAAJ8BAgKkAgUAAABAQE0DAGoKAAAATQMDiQsAAACfAgICpAMFAAAAQEBNBACRDAAAAE0EBIINAAAAnwMCAsAEDgASAAIAEgABAIIEAgAPAw8EAAAAQAMQAxEDEgQAAEBAAxMEAABgQAMUAxUDFgMXAxgDGQYAAQABAAEYAAMAAAAAAAMAAAAAAAAAAAEAAAAAAAABAAAAAAAAAwAAAAEAAAAAAX+s3jxgjaDQewSTj81d9sEPtMlITWi0PQ==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPriceValueForPet = require(script.Parent.GetPriceValueForPet)
local Asserts = require(ReplicatedStorage.Library.Asserts)

require(ReplicatedStorage.Directory.PetRegistry)

return function(p1) -- line: 12
	-- upvalues: Asserts (copy), GetPriceValueForPet (copy)
	Asserts.Tool(p1)

	local PetType = p1:GetAttribute("PetType")
	local BaseWeight = p1:GetAttribute("BaseWeight")
	local Scale = p1:GetAttribute("Scale")
	local Age = p1:GetAttribute("Age")
	local Level = p1:GetAttribute("Level")
	local PET_UUID = p1:GetAttribute("PET_UUID")

	if not PetType or (not BaseWeight or not Scale) then
		return 0.0
	end

	local t1 = {
		UUID = PET_UUID or "",
		PetType = PetType,
		PetData = {
			LevelProgress = 0.0,
			Age = Age or 0.0,
			Level = Level or 1.0,
			Name = p1.Name,
			BaseWeight = BaseWeight,
			Weight = Scale
		}
	}

	return GetPriceValueForPet(t1)
end

