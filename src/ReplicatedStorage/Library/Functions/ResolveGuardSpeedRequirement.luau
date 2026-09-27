-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBXRhYmxlIVJlc29sdmVQbGF5ZXJXYWxrU3BlZWRSZXF1aXJlbWVudBVXYWxrU3BlZWRUb1NwZWVkUG93ZXIaUm91bmRTcGVlZFBvd2VyUmVxdWlyZW1lbnQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzB01vZHVsZXMKR3VhcmRBcmVhcxVHdWFyZEVzY2FwZVByZWRpY3Rpb24FVHlwZXMJSW50ZXJmYWNlBFV0aWwNVHJlYWRtaWxsVXRpbAACBQEDAAAAFvsBAABNAQFLAAAAAFICAACfAQIB+wEBAE0BAY0BAAAAUgIAAG8DAgCfAQMC+wICAE0CAjkDAAAAUgMBAJ8CAgL7AwIATQMDxAQAAABbBAIFnwMCAIIDAAAGAwEDAgLNzMzMzMzsPwMDAwQCzczMzMzM8D8AEAABGAAAAAAAAwAAAAAAAQAAAAABAAAAAAARAAAAAAYAAAECADSjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAokHAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwPoCAAAAE0DA4EJAAAATQMDTwoAAACfAgICpAMFAAAAQEBNBABqBgAAAE0EBOgIAAAATQQEgQkAAABNBATvCwAAAE0EBA8MAAAAnwMCAqQEBQAAAEBATQUAagYAAABNBQWeDQAAAE0FBZ0OAAAAnwQCAsAFDwASAAEAEgACABIABACCBQIAEAMFBAAAAEADBgMHAwgEAABAQAMJAwoDCwMMAw0DDgMPAxADEQYAAQABAAEYAAMAAAAAAAMAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAABAAAAAAAAAAAGAAAAAAEAAAAAAcFJT5kWJKDB3my16NdJdKOxUVjt840lmA==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local GuardEscapePrediction = require(ReplicatedStorage.Library.Modules.GuardAreas.GuardEscapePrediction)

require(ReplicatedStorage.Library.Modules.GuardAreas.Types.Interface)

local TreadmillUtil = require(ReplicatedStorage.Library.Util.TreadmillUtil)

return function(p1) -- line: 16
	-- upvalues: Asserts (copy), GuardEscapePrediction (copy), TreadmillUtil (copy)
	Asserts.table(p1)

	local v6 = GuardEscapePrediction.ResolvePlayerWalkSpeedRequirement(p1, 0.9)
	local v7 = TreadmillUtil.WalkSpeedToSpeedPower(v6)

	return TreadmillUtil.RoundSpeedPowerRequirement(v7 * 1.05)
end

