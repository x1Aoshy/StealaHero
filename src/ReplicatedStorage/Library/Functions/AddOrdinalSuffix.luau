-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJCHRvc3RyaW5nA3N1YgExAnN0ATICbmQBMwJyZAJ0aAACBwEAAAAAKrs/AANSAgAApAEBAAAAAECfAQICjAT//7wCAfACAAAAnwIDAowF/v+MBv7/vAMB8AIAAACfAwQC8AIHAAMAAIDwAwUAAwAAAFIFAQBvBgQAcwQFBoIEAgDwAgcABQAAgPADBQADAAAAUgUBAG8GBgBzBAUGggQCAPACBwAHAACA8AMFAAMAAABSBQEAbwYIAHMEBQaCBAIAUgUBAG8GCQBzBAUGggQCAAoDAQQAAABAAwIDAwMEAwUDBgMHAwgDCQABAAEYAAAAAAABAAAAAQAAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAACAAAAAgAAAAABAAABAgADowAAAMAAAACCAAIAAQYAAQABAAEYAAAAAQAAAAABfcxGC1Tmb/zY4IgUMLLZfw3UUX9PCCwK

-- decompilation:
return function(p1) -- line: 1
	local str = tostring(p1)
	local v3 = str:sub(-1.0)
	local v4 = str:sub(-2.0, -2.0)

	if v3 == "1" and v4 ~= "1" then
		return str .. "st"
	end

	if v3 == "2" and v4 ~= "1" then
		return str .. "nd"
	end

	if v3 == "3" and v4 ~= "1" then
		return str .. "rd"
	end

	return str .. "th"
end

