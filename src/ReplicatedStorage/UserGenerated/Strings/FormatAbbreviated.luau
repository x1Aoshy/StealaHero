-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMoBHR5cGUGbnVtYmVyBmFzc2VydANOYU4ISW5maW5pdHkJLUluZmluaXR5AS0FdGFibGUGaW5zZXJ0BG1hdGgFZmxvb3IFbG9nMTAFY2xhbXAGY29uY2F0EUZvcm1hdEFiYnJldmlhdGVkBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlDVVzZXJHZW5lcmF0ZWQETWF0aAxSb3VuZEZpZ3VyZXMLU3RhYmxlRXhwMTAHU3RyaW5ncxNUcmltbWVkTnVtYmVyU3RyaW5nAAFrAW0BYgF0AXECUXQCU3gCU3ABbwFuAWQBdQJEdQJUcgACCAEEAAASAwQCBQECDw8PDwICLzMPARlXcLsoAANSBAAApAMBAAAAAECfAwIC8AMCAAIAAACpAgABqQIBALsBAgKkAQQAAAAwQJ8BAgHxAAMAAAAAAG8BBQCCAQIADQADAAYAAIBvAQcAggECAA0AAwAIAACAbwEJAIIBAgD/AQAAAAAAAIwCAABgAAkAAgAAAIE0AQUKAAAAUgMBAG8ECgCkAg0AADCwgJ8CAwE5AAAAuwwAA1IDAACkAhAAADzggJ8CAgJSAAIAjALoA30CNQAAAAAAuxAAA1IGAACkBRQAAEzggJ8FAgI+BAUSuwwEAqQDEAAAPOCAnwMCApUCAxGMBQEA+wcAABwGBwA0LgIEBQYAAFIEAgCkAxYAAFTggJ8DBAJSAgMA+wMBAFIEAAB4BgIRWwUGF58DAwJSAAMA+wMCAFIEAACMBQMAxgYAAKQHEAAAPOCAnwMFAlIAAwBSBAEA+wUDAFIGAACfBQIATDQAAqQDDQAAMLCAnwMAAfsGAACHBQYCnjQBBAUAAABSBAEApAMNAAAwsICfAwMBZQAIAFIDAQD7BAMAUgUAAJ8EAgBMNAACpAINAAAwsICfAgABpAIZAABgsIBSAwEAnwICAIICAAAaAwEEAAAAQAMCAwMEAAAwQAMEAgAAAAAAAPB/AwUCAAAAAAAA8P8DBgMHAwgDCQQAMLCAAwoDCwQAPOCAAgAAAAAAAPA/AgAAAAAAAAhAAwwEAEzggAMNBABU4IACAAAAAAAACMADDgQAYLCAAEIPARgAAAAAAAAAAAAAAAAAAgABAAIAAQACAAEAAwABAAABAAAAAAAAAQMAAAAAAAEAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAEAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAACAAAAAAAAAAMAAAAAQwAAAAAUAAABAxsAAAYPAAE6DwEHNA8CECsPAxkiDwQiGQ8FNQY7owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIA4AYAAABNAgKMBwAAAE0CAr0IAAAAnwECAqQCBQAAAEBATQMA4AYAAABNAwOMBwAAAE0DA+MJAAAAnwICAqQDBQAAAEBATQQA4AYAAABNBAQfCgAAAE0EBJ0LAAAAnwMCAv8EAAAPAAAAbwUMAG8GDQBvBw4AbwgPAG8JEABvChEAbwsSAG8MEwBvDRQAbw4VAG8PFgBvEBcAbxEYAG8SGQBvExoAxQQFEAEAAADABRsAEgAEABIAAgASAAEAEgADAIIFAgAcAxAEAAAAQAMRAxIDEwQAAEBAAxQDFQMWAxcDGAMZAxoDGwMcAx0DHgMfAyADIQMiAyMDJAMlAyYDJwMoBgABAAEAARgAEwAAAAAAAgAAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAgABAQEBAQEBAQEBAQEBAQEAABkAAAAAIgEAAAAAAeHqP5XIOfnhO5dNrnnb546R8ijh0y5VlA==

-- decompilation:
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundFigures = require(ReplicatedStorage.UserGenerated.Math.RoundFigures)
local StableExp10 = require(ReplicatedStorage.UserGenerated.Math.StableExp10)
local TrimmedNumberString = require(ReplicatedStorage.UserGenerated.Strings.TrimmedNumberString)
local t1 = {
	"",
	"k",
	"m",
	"b",
	"t",
	"q",
	"Qt",
	"Sx",
	"Sp",
	"o",
	"n",
	"d",
	"u",
	"Du",
	"Tr"
}

local function FormatAbbreviated(n1: number) -- line: 66
	-- upvalues: t1 (copy), StableExp10 (copy), RoundFigures (copy), TrimmedNumberString (copy)
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

	local t2 = {}

	if n1 < 0.0 then
		table.insert(t2, "-")
		n1 = -n1
	end

	local v9 = math.floor(n1)

	if v9 >= 1000.0 then
		local v10 = math.clamp(math.floor(math.log10(v9) / 3.0) + 1.0, 1.0, #t1)
		local v11 = StableExp10(v9, (v10 - 1.0) * -3.0)
		local v12 = RoundFigures(v11, 3.0, nil, math.floor)

		table.insert(t2, TrimmedNumberString(v12))
		table.insert(t2, t1[v10])
	else
		table.insert(t2, TrimmedNumberString(v9))
	end

	return table.concat(t2)
end

return FormatAbbreviated

