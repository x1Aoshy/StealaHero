-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMNBG1hdGgFcm91bmQEc2lnbgVsb2cxMAVmbG9vcgxSb3VuZEZpZ3VyZXMEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQlGdW5jdGlvbnMJTmljZUV4cDEwAAIPBAEAAAAskAEBAJACAgFSBAMAKwQCAKQEBAAADCCAUgMEALsvAANSBQAApAQGAAAUIICfBAICDQQDAAcAAICMBQAAggUCAAkFAAS7EAUDUgcFAKQGCQAAICCAnwYCArsMBgNSCgYApAkLAAAoIICfCQICJggJAZUHCAENAgIAAQAAAOwFBQL7CQAAUgsDAPsMAABSDQUAOQ4HAJ8MAwKfCwICCQoLAlILBwCfCQMCCQgJBIIIAgAMAgAAAAAAAAhAAgAAAAAAAPA/AwEDAgQADCCAAwMEABQggAIAAAAAAAAAAAMEBAAgIIADBQQAKCCAAAQGARgAAQEAAAAAAgAAAAABAAEAAwEAAAAAAQAAAAAAAAEAAQIAAAAAAAAAAAAAAAUAAAAAAwAAAQIAF6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICUwcAAABNAgKfCAAAAJ8BAgLAAgkAEgABABgCAL0KAAAANQIAvQoAAACCAgIACwMHBAAAAEADCAMJAwoEAABAQAMLAwwDDQYAAwYBAAEAARgAAAAAAAAAAQAAAAAAAAAAAgAAABMAAAEAAAAAAYb+mZpbBDULWQuNQbnBZG/25o7utDrzmw==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NiceExp10 = require(ReplicatedStorage.Library.Functions.NiceExp10)

function RoundFigures(p1, p2, p3, p4) -- line: 4
	-- upvalues: NiceExp10 (copy)
	local v7 = p2 or 3.0
	local v8 = p3 or 1.0
	local v9 = p4 or math.round
	local v10 = math.sign(p1)

	if v10 == 0.0 then
		return 0.0
	end

	local v11 = p1 * v10
	local v12 = math.floor((math.log10(v11))) - v7 + 1.0

	if v8 ~= 1.0 then
		v11 /= v8
	end

	return NiceExp10(v9((NiceExp10(v11, -v12))) * v8, v12) * v10
end

return RoundFigures

