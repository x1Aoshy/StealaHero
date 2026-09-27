-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJBXRhYmxlBG1hdGgGcmFuZG9tBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwACBAEBAAAGAwAABQEEC/sBAABNAQFLAAAAAFICAACfAQIBpAIDAAAIEIAcAwAAnwICAocBAAKCAQIABAMBAwIDAwQACBCAAAwAARgAAAAAAAIAAAAAAA0AAAAAAwAAAQIAEaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICwAIIABIAAQCCAgIACQMEBAAAAEADBQMGAwcEAABAQAMIAwkGAAEAAQABGAABAAAAAAADAAAAAAAABwAAAQAAAAAB8oeQ11b3Q10HANeWD6vkqIKfh6PAQ/rW

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(t1: {[any]: any}) -- line: 12
	-- upvalues: Asserts (copy)
	Asserts.table(t1)

	return t1[math.random(#t1)]
end

