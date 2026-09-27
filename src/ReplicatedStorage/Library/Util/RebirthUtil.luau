-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSBm51bWJlcg1HZXRNYXhSZWJpcnRoIUV4cGVjdGVkIHJlYmlydGggbXVsdGlwbGllciBlbnRyeQZhc3NlcnQKTXVsdGlwbGllchNSZWJpcnRoVG9NdWx0aXBsaWVyDFJlcXVpcmVtZW50cxJSZXF1aXJlZFNwZWVkUG93ZXIGdHlwZW9mG1JlYmlydGhUb1JlcXVpcmVkU3BlZWRQb3dlcgRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMJRGlyZWN0b3J5CFJlYmlydGhzAAQFAQMAAAYDAAAFAQIg+wEAAE0BAWAAAAAAUgIAAJ8BAgGMAQAAfQADAAEAAACMAQEAggECAPsCAQCHAQIAKwEGAPsCAQD7AwIATQMDogEAAACfAwEChwECA0cBAgAAAACAqQMAAakDAQCBAQMEAgAAAG8EAgCkAgQAAAAwQJ8CAwFNAgEGBQAAAIICAgAGAwEDAgMDAwQEAAAwQAMFAA4GARgAAAAAAAEAAAEAAwABAQAAAAAAAwAAAAAAAAAAAAEAAA8AAAAAAgABAAAAA/sBAAAcAAEAggACAAAAHQIBGAAAAB4AAAAABQECAAAGAwAABQECGPsBAABNAQFgAAAAAFICAACfAQIB+wIBAIcBAgArAQIAbwIBAIICAgBNAgFkAgAAAE0CAhkDAAAAuywCA1IEAgCkAwUAAABAQJ8DAgLwAwMAAAAAAG8DAQCCAwIAggICAAYDAQIAAAAAAADwfwMHAwgDCQQAAEBAACEKARgAAAAAAAEAAQEAAwAAAAEAAAAAAAABAAMiAAAAAAUAAAECACejAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAokHAAAAnwECAqQCBQAAAEBATQMAkQgAAABNAwN2CQAAAJ8CAgL/AwMAAAAAAMAECgASAAEAEgACABIAAwAwBAP4CwAAAMAEDAASAAIAMAQDog0AAADABA4AEgABABIAAgAwBANSDwAAAIIDAgAQAwsEAAAAQAMMAw0DDgQAAEBAAw8DEAMRAxIGAAMGBgEDAgYCAwoDAAECAQABGAADAAAAAAADAAAAAAAAAQAAAAAAAAMAAwAAAAAADwAAAAQAAAAADwEAAAAAA/FX5ZeN2zEhOaQeutXTDo2BT/Ljw5OPlg==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Rebirths = require(ReplicatedStorage.Directory.Rebirths)
local t1 = {}

function t1.RebirthToMultiplier(n1: number) -- line: 14
	-- upvalues: Asserts (copy), Rebirths (copy), t1 (copy)
	Asserts.number(n1)

	if n1 <= 0.0 then
		return 1.0
	end

	local v6 = Rebirths[n1] or Rebirths[t1.GetMaxRebirth()]

	assert(v6 ~= nil, "Expected rebirth multiplier entry")

	return v6.Multiplier
end
function t1.GetMaxRebirth() -- line: 29
	-- upvalues: Rebirths (copy)
	return #Rebirths
end
function t1.RebirthToRequiredSpeedPower(n2: number) -- line: 33
	-- upvalues: Asserts (copy), Rebirths (copy)
	Asserts.number(n2)

	local v8 = Rebirths[n2]

	if not v8 then
		return 1e999
	end

	local RequiredSpeedPower = v8.Requirements.RequiredSpeedPower

	if typeof(RequiredSpeedPower) ~= "number" then
		return 1e999
	end

	return RequiredSpeedPower
end

return t1

