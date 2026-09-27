-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMcBnN0cmluZwNzdWIBLQABLApjb21tYXNGdWxsBm51bWJlcghvcHRpb25hbAhJbmZpbml0eQktSW5maW5pdHkGZm9ybWF0AiVmDyhbXiUuXSopJS4/KC4qKQVtYXRjaAMwKyQEZ3N1YgUlcy4lcwNOYU4NZm9ybWF0RmlndXJlcwRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQZzY3JpcHQGUGFyZW50DFJvdW5kRmlndXJlcwdMaWJyYXJ5B0Fzc2VydHMAAwoBAQAABgMAAAUBAzf7AQAATQEBQQAAAABSAgAAnwECAcYBAACMBAEAjAUBALwCAPABAAAAnwIEAvACCAACAACAjAQCALwCAPABAAAAnwIDAlIAAgBvAQIAZQABAG8BAwCMAgEAHAQAACEDBASMBAAAYAQKAAMAAABSBAEAUgcCAEMJAgN4CAkFvAUA8AEAAACfBQQCcwEEBUMCAgMcBAAAfQIQAAQAAACMBAEAYAQEAAIAAABSBAEAbwUGAHMBBAVSBAEAUgcCAJUIAge8BQDwAQAAAJ8FBAJzAQQFlQICBEgA7v+CAQIACAMBAwIDAwMEAgAAAAAAAAhAAgAAAAAAAPA/AwUCAAAAAAAAAEAADQYBGAAAAAAAAgEAAAAAAAABAAAAAAEAAgMBAAIAAAEAAAAAAAAAAQMAAAEAAAEAAAIAAAAAAAAB+wgOAAAAAAwDAgAACAUAAAUDAoKCQ/sDAABNAwNgAAAAAFIEAACfAwIB+wMAAE0DAxEBAAAATQMDYAAAAABSBAEAnwMCAfsDAABNAwMRAQAAAE0DA2AAAAAAUgQCAJ8DAgGaAC0AAAAAAA0AAwACAACAbwMDAIIDAgANAAMABAAAgG8DBQCCAwIA+wMBAFIEAABSBQEAUgYCAJ8DBAKkBAgAABxggG8FCQBSBgMAnwQDAm8GCgC8BATnCwAAAJ8EAwM1BgDDDAAAAFIHBACfBgICDgUQAG8JDQBvCg4AvAcFzA8AAACfBwQCHAgHAA0IAgAQAACAggYCAKQICAAAHGCAbwkRAFIKBgBSCwcAnwgEAIIIAACCBgIAbwMSAIIDAgATAwcDCAIAAAAAAADwfwMJAgAAAAAAAPD/AwoDAQMLBAAcYIADDAMNAw4DBgMPAwQDEAIAAAAAAAAAAAMRAxIAMhMBGAAAAAAAAQAAAAAAAAEAAAAAAAACAAEAAQABAAEAAgAAAAABAAAAAAAAAAABAAAAAgEAAAAAAQAAAQIAAAAAAAADBAAzAAAAAAQAAAECACOjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQECkAgcAAABgQE0CAiQIAAAATQICvQkAAACfAQICpAIFAAAAQEBNAwBqCgAAAE0DA4kLAAAAnwICAsADDAASAAIAGAMAww0AAADAAw4AEgACABIAAQAYAwA2DwAAADUDADYPAAAAggMCABADFAQAAABAAxUDFgMXBAAAQEADGAQAAGBAAxkDGgMbAxwGAAMGBgEDEwIAAQEAARgAAQAAAAAAAwAAAAAAAAAAAQAAAAAAAAcAAAAlAAAAAB8AAAEAAAAAAkOCfkI19HnMH7dPpl4Bq1gzmmk2cUYUQw==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundFigures = require(script.Parent.RoundFigures)
local Asserts = require(ReplicatedStorage.Library.Asserts)

function commasFull(s1: string) -- line: 13
	-- upvalues: Asserts (copy)
	Asserts.string(s1)

	local s2

	if s1:sub(1.0, 1.0) == "-" then
		s1 = s1:sub(2.0)
		s2 = "-"
	else
		s2 = ""
	end

	local n1 = 1.0
	local v7 = #s1 % 3.0

	if v7 > 0.0 then
		s2 ..= s1:sub(n1, n1 + v7 - 1.0)
		n1 += v7
	end

	while n1 <= #s1 do
		if n1 > 1.0 then
			s2 ..= ","
		end

		s2 ..= s1:sub(n1, n1 + 2.0)
		n1 += 3.0
	end

	return s2
end
function formatFigures(n2: number, n3: number?, n4: number?) -- line: 50
	-- upvalues: Asserts (copy), RoundFigures (copy)
	Asserts.number(n2)
	Asserts.optional.number(n3)
	Asserts.optional.number(n4)

	if n2 == n2 then
		if n2 == 1e999 then
			return "Infinity"
		end

		if n2 == -1e999 then
			return "-Infinity"
		end

		local v11 = RoundFigures(n2, n3, n4)
		local v12, v13 = string.format("%f", v11):match("([^%.]*)%.?(.*)")
		local v14 = commasFull(v12)

		if v13 then
			local v15 = v13:gsub("0+$", "")

			if #v15 == 0.0 then
				return v14
			end

			return string.format("%s.%s", v14, v15)
		end

		return v14
	end

	return "NaN"
end

return formatFigures

