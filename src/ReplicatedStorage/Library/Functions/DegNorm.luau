-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMCBG1hdGgEY2VpbAACBQEAAAAADowBAABgAAoAAQAAADkCAAA+AQIAuwcBA1IEAQCkAwMAAAgQgJ8DAgJbAgMAQwAAAiEBAACCAQIABAIAAAAAAIB2QAMBAwIEAAgQgAABAAEYAAAAAQABAAAAAAAAAgACAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgABAAEAARgAAAABAAAAAAE=

-- decompilation:
return function(p1) -- line: 1
	if p1 < 0.0 then
		p1 += math.ceil(-p1 / 360.0) * 360.0
	end

	return p1 % 360.0
end

