-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVBE1hbGUGRmVtYWxlCElzR2VuZGVyBlJhbmRvbQNuZXcLTmV4dEludGVnZXIEUm9sbAlEaXJlY3RvcnkMR2VuZGVyTG9ja2VkElJlc29sdmVGb3JDYXRlZ29yeRtyYnhhc3NldGlkOi8vODg2Mjc4NzY5NjE5NzYbcmJ4YXNzZXRpZDovLzk4NzgyNDgwMjI1OTg4B0dldEljb24EZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUGQXNzZXRzB0xpYnJhcnkFVHlwZXMJQXNzZXRJdGVtAAUCAQAAAAAIqQEBAPAABQAAAAAA8AACAAEAAACpAQABqQEBAIIBAgACAwEDAgAYAwEYAAAAAAAAAAAZAAAAAAYBAAAABgMAAAUBhxBSAQAAKwEDAKQBAgAABACAnwEBAowEAQCMBQIAvAIBjAMAAACfAgQCDQIDAAQAAIBvAgUAggICAG8CBgCCAgIABwMEAwUEAAQAgAMGAgAAAAAAAPA/AwEDAgAcBwEYAAAAAAABAAAAAAAAAQADAB0AAAAABwMCAAAIBQAABQMDg4ca+wMAAE0DAyUAAAAAUgQBAJ8DAgIOAwEAggECAPsEAQBNBASRAQAAAIcDBABNBAMmAgAAAPsFAABNBQUlAAAAAFIGBACfBQICDgUBAIIEAgD7BQAATQUFqgMAAABSBgIAnwUCAIIFAAAEAwMDCAMJAwcAJQoBGAAAAAAAAAEDAAAAAQABAAAAAAABAwAAAAAAJgAAAAACAQAAAAAG8AADAAAAAIBvAQEAggECAG8BAgCCAQIAAwMBAwsDDAAzDQEYAAABAAMANAAAAAAFAAABAgAoowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAkQYAAABNAgKBBwAAAJ8BAgKkAgUAAABAQE0DAGoIAAAATQMD7wkAAABNAwPmCgAAAJ8CAgL/AwMAAAAAAMAECwAwBAMlDAAAAMAEDQAwBAOqDgAAAMAEDwASAAMAEgABADAEA9YQAAAAwAQRADAEA14SAAAAggMCABMDDgQAAABAAw8DEAMRBAAAQEADCAMSAxMDFAMVBgADAwYBAwcGAgMKBgMDDQQAAQIDAQABGAADAAAAAAADAAAAAAAAAQAAAAAAAAAACgAGAAAEAAAJAAAAAA4AAAgBAAAAAASKNqDS5KTtMSTJUdtA7vj6+i63prjyytM=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = require(ReplicatedStorage.Directory.Assets)

require(ReplicatedStorage.Library.Types.AssetItem)

local t1 = {
	IsGender = function(p1) -- line: 24
		return p1 == "Male" or p1 == "Female"
	end,
	Roll = function(p2) -- line: 28
		if (p2 or Random.new()):NextInteger(1.0, 2.0) == 1.0 then
			return "Male"
		end

		return "Female"
	end
}

function t1.ResolveForCategory(s1: string, s2: string?, p3) -- line: 37
	-- upvalues: t1 (copy), Assets (copy)
	if t1.IsGender(s2) then
		return s2
	end

	local GenderLocked = Assets.Directory[s1].GenderLocked

	if t1.IsGender(GenderLocked) then
		return GenderLocked
	end

	return t1.Roll(p3)
end
function t1.GetIcon(p4) -- line: 51
	if p4 == "Male" then
		return "rbxassetid://88627876961976"
	end

	return "rbxassetid://98782480225988"
end

return t1

