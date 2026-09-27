-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWB0VnZ05hbWUJTXV0YXRpb25zCklzRmF2b3JpdGUGQ0ZyYW1lCElzQWN0aXZlBVNjYWxlDENyZWF0aW9uVGltZQ1OZXN0U2xvdEluZGV4D0dyb3d0aFN0YXJ0ZWRBdA5Hcm93dGhEdXJhdGlvbglTZXJpYWxpemULRGVzZXJpYWxpemUEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQVUeXBlcwxBc3NldEVnZ0l0ZW0JRnVuY3Rpb25zDFVucGFja0NGcmFtZQpQYWNrQ0ZyYW1lAAMEAQEAAAAx4gEKAE0CAAwAAAAAMAIBDAAAAABNAgANAQAAADACAQ0BAAAATQIA0gIAAAAwAgHSAgAAAE0DAIUDAAAADgMFAPsCAABNAwCFAwAAAJ8CAgIrAgEAxgIAADACAYUDAAAATQIAdgQAAAAwAgF2BAAAAE0CAIQFAAAAMAIBhAUAAABNAgANBgAAADACAQ0GAAAATQIAJwcAAAAwAgEnBwAAAE0CAKsIAAAAMAIBqwgAAABNAgBWCQAAADACAVYJAAAAggECAAsDAQMCAwMDBAMFAwYDBwMIAwkDCgUKAAECAwQFBgcICQAOCwEYAAEAAAABAAAAAQAAAAEAAAAAAAAAAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAABEAAAAABAEBAAAAMeIBCgBNAgAMAAAAADACAQwAAAAATQIADQEAAAAwAgENAQAAAE0CANICAAAAMAIB0gIAAABNAwCFAwAAAA4DBQD7AgAATQMAhQMAAACfAgICKwIBAMYCAAAwAgGFAwAAAE0CAHYEAAAAMAIBdgQAAABNAgCEBQAAADACAYQFAAAATQIADQYAAAAwAgENBgAAAE0CACcHAAAAMAIBJwcAAABNAgCrCAAAADACAasIAAAATQIAVgkAAAAwAgFWCQAAAIIBAgALAwEDAgMDAwQDBQMGAwcDCAMJAwoFCgABAgMEBQYHCAkAHwwBGAABAAAAAQAAAAEAAAABAAAAAAAAAAAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAAiAAAAAAYAAAECAC2jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAu8HAAAATQICWggAAACfAQICpAIFAAAAQEBNAwBqBgAAAE0DA1MJAAAATQMDewoAAACfAgICpAMFAAAAQEBNBABqBgAAAE0EBFMJAAAATQQEtwsAAACfAwIC/wQCAAAAAADABQwAEgACADAFBHENAAAAwAUOABIAAwAwBQRPDwAAAIIEAgAQAw0EAAAAQAMOAw8DEAQAAEBAAxEDEgMTAxQDFQMWBgADCwYBAwwCAAEBAAEYAAMAAAAAAAMAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAMAAgAAABEAAAARAQAAAAACf9mZq/OnAR911nyw4Vat4Q/Bjt9NHfOq

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Library.Types.AssetEggItem)

local UnpackCFrame = require(ReplicatedStorage.Library.Functions.UnpackCFrame)
local PackCFrame = require(ReplicatedStorage.Library.Functions.PackCFrame)

return {
	Serialize = function(p1) -- line: 14
		-- upvalues: UnpackCFrame (copy)
		return {
			EggName = p1.EggName,
			Mutations = p1.Mutations,
			IsFavorite = p1.IsFavorite,
			CFrame = p1.CFrame and UnpackCFrame(p1.CFrame) or nil,
			IsActive = p1.IsActive,
			Scale = p1.Scale,
			CreationTime = p1.CreationTime,
			NestSlotIndex = p1.NestSlotIndex,
			GrowthStartedAt = p1.GrowthStartedAt,
			GrowthDuration = p1.GrowthDuration
		}
	end,
	Deserialize = function(p2) -- line: 31
		-- upvalues: PackCFrame (copy)
		return {
			EggName = p2.EggName,
			Mutations = p2.Mutations,
			IsFavorite = p2.IsFavorite,
			CFrame = p2.CFrame and PackCFrame(p2.CFrame) or nil,
			IsActive = p2.IsActive,
			Scale = p2.Scale,
			CreationTime = p2.CreationTime,
			NestSlotIndex = p2.NestSlotIndex,
			GrowthStartedAt = p2.GrowthStartedAt,
			GrowthDuration = p2.GrowthDuration
		}
	end
}

