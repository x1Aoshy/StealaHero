-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMECHRvc3RyaW5nBnR5cGVvZgZzdHJpbmcBIgACBgEAAAAAErs/AANSAgAApAEBAAAAAECfAQICuywAA1IDAACkAgMAAAAgQJ8CAgLwAgYABAAAgG8DBQBSBAEAbwUFAHMCAwWCAgIAggECAAYDAQQAAABAAwIEAAAgQAMDAwQAAQABGAAAAAAAAQAAAAAAAAEAAAAAAgIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAAEAAQABGAAAAAEAAAAAAQ==

-- decompilation:
return function(p1) -- line: 1
	local str = tostring(p1)

	if typeof(p1) == "string" then
		return "\"" .. str .. "\""
	end

	return str
end

