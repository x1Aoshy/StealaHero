-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhA05hTghJbmZpbml0eQktSW5maW5pdHkAAS0EbWF0aAVmbG9vcgh0b3N0cmluZwVsb2cxMAVjbGFtcARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5CUZ1bmN0aW9ucxJGb3JtYXRGaWd1cmVzRmxvb3IGQ29tbWFzCU5pY2VFeHAxMAFrAW0BYgF0AXECUXQCU3gCU3ABbwFuAWQBdQJEdQJUcgACEAQEAAAAUfEAAwAAAAAAbwQAAIIEAgANAAMAAQAAgG8EAgCCBAIADQADAAMAAIBvBAQAggQCAEcDAwAAAACAqQQBAGUAAQBSBAMAkAUCBW8GBgCMBwAAYAADAAcAAAA5AAAAbwYHALsMAANSCAAApAcKAAAkgICfBwICYAcOAAUAAABSCQYADgQEAPsKAABSCwcAnwoCAisKBQC7PwcDUgsHAKQKDAAAALBAnwoCAnMICQqCCAIAuxAHA1IMBwCkCxAAADyAgJ8LAgI+CgsOuwwKAqQJCgAAJICAnwkCApUICQ2MCwEA+w0BABwMDQA0LggECwwAAFIKCACkCRIAAESAgJ8JBAL7CgIA+wsDAFIMBwB4DgkNWw0OE58LAwKMDAMAxg0AAFIOBACfCgUC+wwBAIcLDAlSDQYAUg4KAFIPCwBzDA0PggwCABQDAQIAAAAAAADwfwMCAgAAAAAAAPD/AwMCAAAAAABAj0ADBAMFAwYDBwQAJICAAwgEAACwQAIAAAAAAADwPwIAAAAAAAAIQAMJBAA8gIADCgQARICAAgAAAAAAAAjAABgAARgAAAEAAgABAAIAAQACAAAAAAEBAQAAAQECAAAAAAEAAQAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAAEAAQAAAAAZAAAAABQAAAECADujAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAlMHAAAATQICWwgAAACfAQICpAIFAAAAQEBNAwBqBgAAAE0DA1MHAAAATQMDzgkAAACfAgICpAMFAAAAQEBNBABqBgAAAE0EBFMHAAAATQQEnwoAAACfAwIC/wQAAA8AAABvBQsAbwYMAG8HDQBvCA4AbwkPAG8KEABvCxEAbwwSAG8NEwBvDhQAbw8VAG8QFgBvERcAbxIYAG8TGQDFBAUQAQAAAMAFGgASAAIAEgAEABIAAQASAAMAggUCABsDCwQAAABAAwwDDQMOBAAAQEADDwMQAxEDEgMTAwQDFAMVAxYDFwMYAxkDGgMbAxwDHQMeAx8DIAMhBgABAAEAARgAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAgABAQEBAQEBAQEBAQEBAQEAAAMAAAAAAAEAAAAAAWuql/z1nD5tYEe3M62kugQbsoCIWW79/Q==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FormatFiguresFloor = require(ReplicatedStorage.Library.Functions.FormatFiguresFloor)
local Commas = require(ReplicatedStorage.Library.Functions.Commas)
local NiceExp10 = require(ReplicatedStorage.Library.Functions.NiceExp10)
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

return function(p1, _, p3, p4) -- line: 24
	-- upvalues: Commas (copy), t1 (copy), FormatFiguresFloor (copy), NiceExp10 (copy)
	if p1 ~= p1 then
		return "NaN"
	end

	if p1 == 1e999 then
		return "Infinity"
	end

	if p1 == -1e999 then
		return "-Infinity"
	end

	local v10 = p4 == nil or p4
	local v11 = p3 or 1000.0
	local s1 = ""

	if p1 < 0.0 then
		p1 = -p1
		s1 = "-"
	end

	local v13 = math.floor(p1)

	if v13 < v11 then
		return s1 .. (v10 and Commas(v13) or tostring(v13))
	end

	local v14 = math.clamp(math.floor(math.log10(v13) / 3.0) + 1.0, 1.0, #t1)

	return s1 .. FormatFiguresFloor(NiceExp10(v13, (v14 - 1.0) * -3.0), 3.0, nil, v10) .. t1[v14]
end

