-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaBSgwMDopBmdtYXRjaAMwMDoKXigwMDopKC4qKQVtYXRjaAZhc3NlcnQABGdzdWIQZm9ybWF0RG91YmxlWmVybwRtYXRoBXJvdW5kAm9zBGRhdGUDISVYAToEZ2FtZQlXb3Jrc3BhY2UKR2V0U2VydmljZRBHZXRTZXJ2ZXJUaW1lTm93Aip0A2RheQMlQiACc3QCbmQCcmQCdGgAAwoBAAAABgMAAAUBAyWMAQAAbwQAALwCAIgBAAAAnwIDBGQCAQCVAQECbgL+/wEAAAANAQUAAwAAgG8DBABSBAAAcwIDBIICAgANAQIAAgAAgIIAAgBvBAUAvAIA5wYAAACfAgMDngECBQMAAABSBQIAUgYDAKQECAAAAHBAnwQDAVIFAgBvCAAAbwkJALwGA8wKAAAAnwYEAnMEBQaCBAIACwMBAwICAAAAAAAA8D8CAAAAAAAAAAADAwMEAwUDBgQAAHBAAwcDCAADCQEYAAEAAAAAAf8AAwABAAAAAQABAgAAAAEAAAAAAAABAAAAAAAAAAQAAAAADwIAAAAHBAAABQICgVDAAgAAPgYAAz4FBgM+BAUCeAMEAbswAwNSBQMApAQGAAAUQICfBAICpAUJAAAgcIBvBgoAUgcAAJ8FAwIOBAcAjAYAAGAGBQAEAAAAUgYEAG8HCwBSCAUAcwUGCG8GDAB9BjEAAAAAAKQGDgAAANBAbwgPALwGBhYQAAAAnwYDArwHBrcRAAAAnwcCAqQICQAAIHCAbwkSAEMKBwCfCAMCTQgIyhMAAACkCQkAACBwgG8KFABDCwcAnwkDAiELCBUNCwUAFgAAgA0IAwAXAAAAbwoYAGUADwAhCwgVDQsFABkAAIANCAMAGgAAAG8KGwBlAAgAIQsIFQ0LBQAcAACADQgDAB0AAABvCh4AZQABAG8KHwBSDAkAUg0IAFIOCgBzCwwOggsCAA4BBABSBgIAUgcFAJ8GAgKCBgIAggUCACAGAAIAAAAAAADgPwIAAAAAAAA4QAIAAAAAAABOQAMKAwsEABRAgAMMAw0EACBwgAMOAw8CAAAAAAAY9UADEAQAANBAAxEDEgMTAxQDFQMWAgAAAAAAACRAAgAAAAAAAPA/AgAAAAAAACZAAxcCAAAAAAAAAEACAAAAAAAAKEADGAIAAAAAAAAIQAIAAAAAAAAqQAMZAxoBAAEAARgAEQAAAAEAAAAAAQAAAAABAQAAAQAAAAQAAAEAAAAAAAEAAAEAAAAAAAABAAAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAAEBAAAAAAEBAAAAAgMAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAQEBAQABGAAAAAEAAAAAApzW51S9jx92rETovtmULI3szvAgrhKNVQ==

-- decompilation:
return function(n1: number, b1: boolean?) -- line: 1
	local function formatDoubleZero(s1: string) -- line: 3
		local n2 = 0.0

		for _ in s1:gmatch("(00:)") do
			n2 += 1.0
		end

		if n2 == 0.0 then
			return "00:" .. s1
		end

		if n2 == 1.0 then
			return s1
		end

		local v11, v12 = s1:match("^(00:)(.*)")

		assert(v11, v12)

		return v11 .. v12:gsub("(00:)", "")
	end

	local v4 = math.round(n1 / 60.0 / 60.0 / 24.0 - 0.5)
	local v5 = os.date("!%X", n1)

	if v4 and v4 > 0.0 then
		v5 = v4 .. ":" .. v5
	end

	if n1 >= 86400.0 then
		local ServerTimeNow = game:GetService("Workspace"):GetServerTimeNow()
		local day = os.date("*t", ServerTimeNow + n1).day

		return os.date("%B ", ServerTimeNow + n1) .. day .. if day % 10.0 ~= 1.0 or day == 11.0 then if day % 10.0 ~= 2.0 or day == 12.0 then (day % 10.0 ~= 3.0 or day == 13.0) and "th" or "rd" else "nd" else "st"
	end

	if b1 then
		return (formatDoubleZero(v5))
	end

	return v5
end

