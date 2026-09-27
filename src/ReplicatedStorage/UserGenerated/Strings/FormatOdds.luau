-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBHR5cGUGbnVtYmVyBmFzc2VydAEwCEluZmluaXR5CS1JbmZpbml0eQNOYU4CMS8KRm9ybWF0T2RkcwRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQ1Vc2VyR2VuZXJhdGVkB1N0cmluZ3MRRm9ybWF0QWJicmV2aWF0ZWQAAgUBAQAABwMBAAUBAg8juygAA1IEAACkAwEAAAAAQJ8DAgLwAwIAAgAAAKkCAAGpAgEAuwECAqQBBAAAADBAnwECAQ0AAwAFAACAbwEGAIIBAgANAAMABwAAgG8BCACCAQIADQADAAkAAIBvAQoAggECAPEAAwAAAAAAbwELAIIBAgBvAgwA+wMAANgEDQCfAwICcwECA4IBAgAOAwEEAAAAQAMCAwMEAAAwQAIAAAAAAAAAAAMEAgAAAAAAAPB/AwUCAAAAAAAA8P8DBgMHAwgCAAAAAAAA8D8AGAkBGAAAAAAAAAAAAAAAAAABAAEAAgABAAIAAQACAAEAAgAAAAAAGQAAAAADAAABAw8AAAMPAAESDwEHDA8CEAMTowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIA4AYAAABNAgIfBwAAAE0CAi0IAAAAnwECAsACCQASAAEAggICAAoDCgQAAABAAwsDDAMNBAAAQEADDgMPAxAGAAEAAQABGAATAAAAAAACAAAAAAAAAAACABEBAAAAAAFIScIhxwk9/5d0IQFvNtOsOFHVVXqNqCA=

-- decompilation:
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FormatAbbreviated = require(ReplicatedStorage.UserGenerated.Strings.FormatAbbreviated)

local function FormatOdds(n1: number) -- line: 24
	-- upvalues: FormatAbbreviated (copy)
	assert(type(n1) == "number")

	if n1 == 0.0 then
		return "0"
	end

	if n1 == 1e999 then
		return "Infinity"
	end

	if n1 == -1e999 then
		return "-Infinity"
	end

	if n1 ~= n1 then
		return "NaN"
	end

	return "1/" .. FormatAbbreviated(1.0 / n1)
end

return FormatOdds

