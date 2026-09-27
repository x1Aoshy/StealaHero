-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUBnR5cGVvZgV0YWJsZQdQZXREYXRhB1BldExpc3QHUGV0VHlwZQlTZWxsUHJpY2UFTGV2ZWwGbnVtYmVyA0FnZQZXZWlnaHQKQmFzZVdlaWdodARtYXRoA21heAVmbG9vcgRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQlEaXJlY3RvcnkLUGV0UmVnaXN0cnkAAg8BAQAAAGu7LAADUgIAAKQBAQAAAABAnwECAvABCQACAACATQIAmgMAAAC7LAICpAEBAAAAAECfAQIC8AEDAAIAAACMAQAAggECAPsCAABNAgK+BAAAAE0DABIFAAAAhwECAysBAgCMAgAAggICAE0DAYYHAAAAkAIDBk0DAJoDAAAATQYDbQgAAAC7LAYCpAUBAAAAAECfBQIC8AUEAAkAAIBNBANtCAAAACsEAQCMBAEATQcD9goAAAC7LAcCpAYBAAAAAECfBgIC8AYEAAkAAIBNBQP2CgAAACsFAQCMBQAATQgDqwsAAAC7LAgCpAcBAAAAAECfBwIC8AcEAAkAAIBNBgOrCwAAACsGBABNBgP+DAAAACsGAQCMBgEATQkD/gwAAAC7LAkCpAgBAAAAAECfCAIC8AgEAAkAAIBNBwP+DAAAACsHAQBSBwYAjAkBAHgLBA5bCgsNQwgJCowKAQBbCwUPQwkKC4wNAAAmDgYHnhINAw4AAACkDBIAAEQAgZ8MAwJbCwwPlQoLDgkNAggJDA0JCQsMCrsMCwNSDQsApAwUAABMAIGfDAICggwCABUDAQQAAABAAwIDAwMEAwUCAAAAAAAAAAADBgMHAwgDCQMKAwsCmpmZmZmZuT8CAAAAAAAA8D8CmpmZmZmZqT8DDAMNBABEAIEDDgQATACBAAoAARgAAAAAAAAAAAAAAAAAAAABAAMAAAAAAAEBAAMAAAEAAgAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAgAAAAEAAAEAAAAAAAAAAAIAAAEAAAAAAAsAAAAAAwAAAQIAEaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAJEGAAAATQICggcAAACfAQICwAIIABIAAQCCAgIACQMPBAAAAEADEAMRAxIEAABAQAMTAxQGAAEAAQABGAADAAAAAAADAAAAAAAAAwAAAQAAAAABrlaDO/RgM19CNTPITh4/WN5OlE+ckuk6

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetRegistry = require(ReplicatedStorage.Directory.PetRegistry)

return function(p1) -- line: 10
	-- upvalues: PetRegistry (copy)
	if typeof(p1) ~= "table" or typeof(p1.PetData) ~= "table" then
		return 0.0
	end

	local v4 = PetRegistry.PetList[p1.PetType]

	if not v4 then
		return 0.0
	end

	local v5 = v4.SellPrice or 0.0
	local PetData = p1.PetData
	local v7 = typeof(PetData.Level) == "number" and PetData.Level or 1.0
	local v8 = typeof(PetData.Age) == "number" and PetData.Age or 0.0
	local v9 = typeof(PetData.Weight) == "number" and PetData.Weight or (PetData.BaseWeight or 1.0)
	local v10 = typeof(PetData.BaseWeight) == "number" and PetData.BaseWeight or v9
	local v11 = 1.0 + (v7 - 1.0) * 0.1
	local v12 = 1.0 + v8 * 0.05
	local v13 = math.max(0.0, v9 - v10) * 0.05 + 1.0

	return (math.floor(v5 * v11 * v12 * v13))
end

