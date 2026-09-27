-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMHB1N5bWJvbCgBKQhuZXdwcm94eQAMZ2V0bWV0YXRhYmxlCl9fdG9zdHJpbmcGU3ltYm9sAAMEAAEAAAAFbwEAAPsCAABvAwEAcwABA4IAAgACAwEDAgAyAAEYAAAAAAAzAAAAAAQBAAAABgMAAAUBgxGkAQEAAAAAQKkCAQCfAQICKwABAG8AAgC7PAEDUgMBAKQCBAAAADBAnwICAtkDAAASAQD/MAMCBgUAAADBAAAAggECAAYDAwQAAABAAwQDBQQAADBAAwYBAC0HARgAAAAAAQECAAAAAAAAAAADAC4AAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAQEBAQABGAAsCwEAAAAAArJEqZ/8bHReVbvNbPB1QQ3CXL7rgIDDng==

-- decompilation:
local function Symbol(s1: string?) -- line: 45
	local v4 = newproxy(true)

	if not s1 then
		s1 = ""
	end

	getmetatable(v4).__tostring = function() -- line: 50
		-- upvalues: s1 (ref)
		return "Symbol(" .. s1 .. ")"
	end

	return v4
end

return Symbol

