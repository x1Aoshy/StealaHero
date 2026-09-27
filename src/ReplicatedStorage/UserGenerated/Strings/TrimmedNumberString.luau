-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBHR5cGUGbnVtYmVyBmFzc2VydANOYU4ISW5maW5pdHkJLUluZmluaXR5BnN0cmluZwZmb3JtYXQCJWYFbWF0Y2gRXihbXiUuXSopJS4/KC4qKSQEZ3N1YgMwKyQABSUqLiUqE1RyaW1tZWROdW1iZXJTdHJpbmcAAggBAAAAEgMAAwUBAg8BGSMPAh4eDwMeHjy7KAADUgQAAKQDAQAAAABAnwMCAvADAgACAAAAqQIAAakCAQC7AQICpAEEAAAAMECfAQIB8QADAAAAAABvAQUAggECAA0AAwAGAACAbwEHAIIBAgANAAMACAAAgG8BCQCCAQIApAEMAAAsoIBvAg0AUgMAAJ8BAwKkAg8AADiggFIDAQBvBBAAnwIDA7sBAgNSBQIApAQEAAAAMECfBAIBKwMBAIICAgCkBBIAAESggFIFAwBvBhMAbwcUAJ8EBAJSAwQAHAQDAA0EAgAVAACAggICAG8EFgBSBgIAUgcDALwEBI0LAAAAnwQEAoIEAgAXAwEEAAAAQAMCAwMEAAAwQAMEAgAAAAAAAPB/AwUCAAAAAAAA8P8DBgMHAwgEACyggAMJAwoEADiggAMLAwwEAESggAMNAw4CAAAAAAAAAAADDwAUEAEYAAAAAAAAAAAAAAAAAAEAAQACAAEAAgABAAIAAAAAAQAAAAABAAAAAAEBAgAAAAAAAAEAAAECAAAAAAAAFQAAAAABAAABAwcAAAEPAAECA6MAAADAAAAAggACAAEGAAEAAQABGAATGAEAAAAAAW6Hh3vZ+AaX0e3XQxfPO/oen5APXEPteg==

-- decompilation:
--!native
local function TrimmedNumberString(n1: number) -- line: 20
	assert(type(n1) == "number")

	if n1 ~= n1 then
		return "NaN"
	end

	if n1 == 1e999 then
		return "Infinity"
	end

	if n1 == -1e999 then
		return "-Infinity"
	end

	local v3 = string.format("%f", n1)
	local v4, v5 = string.match(v3, "^([^%.]*)%.?(.*)$")

	assert(v4)

	if not v5 then
		return v4
	end

	local v6 = string.gsub(v5, "0+$", "")

	if #v6 == 0.0 then
		return v4
	end

	return `{ v4 }.{ v6 }`
end

return TrimmedNumberString

