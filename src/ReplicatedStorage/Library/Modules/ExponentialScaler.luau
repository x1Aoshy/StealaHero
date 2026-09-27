-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMIDHNldG1ldGF0YWJsZQhCYXNlQ29zdA1TY2FsaW5nRmFjdG9yA25ldwRtYXRoA3BvdwdHZXRDb3N0B19faW5kZXgAAwQBAQAAABP/AgIAAAAAAPsDAACePQIDAwAAAKQBAQAAAABAnwEDAk0DAFUDAAAAkAIDAjACAVUDAAAATQMAhQUAAACQAgMEMAIBhQUAAACCAQIABgMBBAAAAEACAAAAAAAAWUADAgIzMzMzMzPzPwMDAAQEARgAAAAAAAAAAAEAAAAAAQAAAAABBQAAAAAHAgAAAAAMTQMAVQAAAABNBgCFAQAAAJ4VAQQGAAAAUgUBAKQEBAAADCCAnwQDAgkCAwSCAgIABQMCAwMDBQMGBAAMIIAACwcBGAAAAAAAAAAAAAAAAAwAAAAAAgAAAQIADaMAAAD/AAMAAAAAADAAAG4AAAAAwAEBABIAAAAwAQDvAgAAAMABAwAwAQD/BAAAAIIAAgAFAwgGAAMEBgEDBwIAAQEAARgAAAABAAIAAAAHAAAEAQAAAAACnCSqc7rSqZwnwWB+R/imzuw8vQeu4MBy

-- decompilation:
local t1 = {}

t1.__index = t1

function t1.new(p1) -- line: 4
	-- upvalues: t1 (copy)
	local self = setmetatable({}, t1)

	self.BaseCost = p1.BaseCost or 100.0
	self.ScalingFactor = p1.ScalingFactor or 1.2

	return self
end
function t1.GetCost(p2, p3) -- line: 11
	return p2.BaseCost * math.pow(p3, p2.ScalingFactor)
end

return t1

