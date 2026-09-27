-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMAAAIEAgAAAAAMJgIAAYwDtABgAwMAAgAAAHgDAgCCAwIAjANM/2ACAwADAAAAlQMCAIIDAgCCAgIAAQIAAAAAAIB2QAABAAEYAAEAAAEAAQAAAQACAgAAAAABAAABAgADowAAAMAAAACCAAIAAQYAAQABAAEYAAAAAQAAAAAB

-- decompilation:
return function(p1, p2) -- line: 1
	local v3 = p1 - p2

	if v3 > 180.0 then
		return v3 - 360.0
	end

	if v3 < -180.0 then
		return v3 + 360.0
	end

	return v3
end

