-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOB19faW5kZXgMc2V0bWV0YXRhYmxlBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlCURpcmVjdG9yeQZSYXJpdHkGc2NyaXB0BlBhcmVudAtCYXNlQ29uZmlncwdEZWZhdWx0BVR5cGVzCUludGVyZmFjZQACBQEBAAAGAwAABQEEC+IDAQD7BAAAMAQDbgAAAACePQAEAwAAAFICAACkAQMAAAAgQJ8BAwKCAQIABAMBBQEAAwIEAAAgQAAWAAEYAAEAAAAAAP8AAAAXAAAAAAUAAAECACejAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgCRBgAAAE0CAvIHAAAAnwECAqQCBQAAAEBApAMJAAAAgEBNAwMkCgAAAE0DAzoLAAAATQMDOgwAAACfAgICpAMFAAAAQECkBAkAAACAQE0EBCQKAAAATQQE7w0AAABNBAQPDgAAAJ8DAgLABA8AEgACAIIEAgAQAwMEAAAAQAMEAwUDBgQAAEBAAwcDCAMJBAAAgEADCgMLAwwDDQMOBgABAAEAARgAAwAAAAAAAwAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAANAAABAAAAAAGaXnMRqDWOgXcYmY1yMmHx6kZkZaiaGRA=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Directory.Rarity)

local Default = require(script.Parent.BaseConfigs.Default)

require(script.Parent.Types.Interface)

return function(t1: {[any]: any}) -- line: 22
	-- upvalues: Default (copy)
	return (setmetatable(t1, {
		__index = Default
	}))
end

