-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPCFBvc2l0aW9uCVJlbWFpbmluZwhDYXRlZ29yeQlTZXJpYWxpemULRGVzZXJpYWxpemUEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQVUeXBlcwpTcHJpbmtsZXJzCUZ1bmN0aW9ucwtQYWNrVmVjdG9yMw1VbnBhY2tWZWN0b3IzAAMEAQEAAAAQ4gEDAPsCAABNAwA7AAAAAJ8CAgIwAgE7AAAAAE0CAGkBAAAAMAIBaQEAAABNAgALAgAAADACAQsCAAAAggECAAQDAQMCAwMFAwABAgAOBAEYAAEAAAAAAAEAAAABAAAAABEAAAAABAEBAAAAEOIBAwD7AgAATQMAOwAAAACfAgICMAIBOwAAAABNAgBpAQAAADACAWkBAAAATQIACwIAAAAwAgELAgAAAIIBAgAEAwEDAgMDBQMAAQIAGAUBGAABAAAAAAABAAAAAQAAAAAbAAAAAAYAAAECAC2jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAu8HAAAATQICbggAAACfAQICpAIFAAAAQEBNAwBqBgAAAE0DA1MJAAAATQMDogoAAACfAgICpAMFAAAAQEBNBABqBgAAAE0EBFMJAAAATQQEXwsAAACfAwIC/wQCAAAAAADABQwAEgACADAFBHENAAAAwAUOABIAAwAwBQRPDwAAAIIEAgAQAwYEAAAAQAMHAwgDCQQAAEBAAwoDCwMMAw0DDgMPBgADBAYBAwUCAAEBAAEYAAMAAAAAAAMAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAMAAgAAAAoAAAAKAQAAAAACqzcO5OYHNX8jqX/+YmCnxNsvGZCZ82Tl

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Library.Types.Sprinklers)

local PackVector3 = require(ReplicatedStorage.Library.Functions.PackVector3)
local UnpackVector3 = require(ReplicatedStorage.Library.Functions.UnpackVector3)

return {
	Serialize = function(p1) -- line: 14
		-- upvalues: PackVector3 (copy)
		return {
			Position = PackVector3(p1.Position),
			Remaining = p1.Remaining,
			Category = p1.Category
		}
	end,
	Deserialize = function(p2) -- line: 24
		-- upvalues: UnpackVector3 (copy)
		return {
			Position = UnpackVector3(p2.Position),
			Remaining = p2.Remaining,
			Category = p2.Category
		}
	end
}

