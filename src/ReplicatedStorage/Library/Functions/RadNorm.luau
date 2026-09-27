-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMCBG1hdGgEY2VpbAACBQEAAAAADowBAABgAAoAAQAAADkCAAA+AQIAuwcBA1IEAQCkAwMAAAgQgJ8DAgJbAgMAQwAAAiEBAACCAQIABAIYLURU+yEZQAMBAwIEAAgQgAADAAEYAAAAAQABAAAAAAAAAgAEAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgABAAEAARgAAgABAAAAAAE=

-- decompilation:
return function(p1) -- line: 3
	if p1 < 0.0 then
		p1 += math.ceil(-p1 / 6.283185307179586) * 6.283185307179586
	end

	return p1 % 6.283185307179586
end

