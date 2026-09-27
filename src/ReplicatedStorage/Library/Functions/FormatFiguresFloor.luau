-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVAANzdWIBLQEsDGluc2VydENvbW1hcwNOYU4ISW5maW5pdHkJLUluZmluaXR5BnN0cmluZwZmb3JtYXQCJWYPKFteJS5dKiklLj8oLiopBW1hdGNoAzArJARnc3ViBSVzLiVzEkZvcm1hdEZpZ3VyZXNGbG9vcgdyZXF1aXJlBnNjcmlwdAZQYXJlbnQMRmxvb3JGaWd1cmVzAAMKAQAAAAYDAAAFAQMwbwEAAIwEAQCMBQEAvAIA8AEAAACfAgQC8AIHAAIAAICMBAIAvAIA8AEAAACfAgMCUgACAG8BAgCMAgEAHAQAACEDBAOMBAAAYAQKAAMAAABSBAEAUgcCAEMJAgN4CAkEvAUA8AEAAACfBQQCcwEEBUMCAgMcBAAAfQIQAAQAAACMBAEAYAQEAAIAAABSBAEAbwUFAHMBBAVSBAEAUgcCAJUIAga8BQDwAQAAAJ8FBAJzAQQFlQICA0gA7v+CAQIABwMBAwIDAwIAAAAAAAAIQAIAAAAAAADwPwMEAgAAAAAAAABAAAMFARgAAQAAAAAAAAEAAAAAAQMBAAEAAAEAAAAAAAAAAQMAAAEAAAEAAAIAAAAAAAAB+wgEAAAAAAwEAgAADQYAAQUEAoKCgQMILAIx8QADAAAAAABvBAAAggQCAA0AAwABAACAbwQCAIIEAgANAAMAAwAAgG8EBACCBAIA+wQAAFIFAABSBgEAUgcCAJ8EBAKkBQcAABhQgG8GCABSBwQAnwUDAm8HCQC8BQXnCgAAAJ8FAwMOAwQA+wcBAFIIBQCfBwICUgUHAA4GEABvCQsAbwoMALwHBswNAAAAnwcEAhwIBwANCAIADgAAgIIFAgBvCA8AUgoFAFILBwC8CAiNBgAAAJ8IBACCCAAAggUCABADBgIAAAAAAADwfwMHAgAAAAAAAPD/AwgDCQMKBAAYUIADCwMMAw0DDgMBAw8CAAAAAAAAAAADEAAcEQEYAAABAAIAAQABAAEAAwAAAAABAAAAAAAAAAABAQAAAAIBAAAAAAEAAAECAAAAAAAAAx0AAAAAAwAAAQIAE6MAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQGNBQAAAJ8AAgLAAQYAwAIHABIAAAASAAEAGAIAWwgAAAA1AgBbCAAAAIICAgAJAxIEAAAAQAMTBAAAIEADFAMVBgAGAQMRAgABAQABGAAAAAAAAAAAAAACGQAAAAAbAAABAAAAAAI4nn6QQsXs9IPGuItt8ZDqSIZp5ApaFJE=

-- decompilation:
local FloorFigures = require(script.Parent.FloorFigures)

local function insertCommas(s1: string) -- line: 3
	local s2 = ""

	if s1:sub(1.0, 1.0) == "-" then
		s1 = s1:sub(2.0)
		s2 = "-"
	end

	local n1 = 1.0
	local v6 = #s1 % 3.0

	if v6 > 0.0 then
		s2 ..= s1:sub(n1, n1 + v6 - 1.0)
		n1 += v6
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

function FormatFiguresFloor(n2: number, n3: number?, n4: number?, b1: boolean?) -- line: 28
	-- upvalues: FloorFigures (copy), insertCommas (copy)
	if n2 ~= n2 then
		return "NaN"
	end

	if n2 == 1e999 then
		return "Infinity"
	end

	if n2 == -1e999 then
		return "-Infinity"
	end

	local v11 = FloorFigures(n2, n3, n4)
	local v12, v13 = string.format("%f", v11):match("([^%.]*)%.?(.*)")

	if b1 then
		v12 = insertCommas(v12)
	end

	if v13 then
		local v14 = v13:gsub("0+$", "")

		if #v14 == 0.0 then
			return v12
		end

		return ("%s.%s"):format(v12, v14)
	end

	return v12
end

return FormatFiguresFloor

