-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMHCU1hZ25pdHVkZQRVbml0CFNhZmVVbml0BUJvbmVzC1BhcmVudEluZGV4CkZyZWVMZW5ndGgIUG9zaXRpb24AAwIBAAAAAAlNAQCqAAAAAA0BAwABAACAbwECAIIBAgBNAQAHAwAAAIIBAgAEAwECAAAAAAAAAAAHAAAAAAAAAAAAAAAAAAAAAAMCAAEDARgAAAAAAQADAAACAAAAAAsDAAAAACFNBAJ4AAAAAE0FAM0BAAAAhwMEBQ4DGgBNBAB+AgAAAE0GAzsDAAAAJgUBBk0HBaoEAAAADQcDAAUAAIBvBgYAZQACAE0GBQcHAAAATQgFqgQAAABgCAQABAAAAE0HBaoEAAAAKwcBAFIHBABNCQM7AwAAAAkKBgdDCAkKgggCAIIAAQAIAwQDBQMGAwcDAQIAAAAAAAAAAAcAAAAAAAAAAAAAAAAAAAAAAwIACQABGAoAAAAAAgEAAQAA8gAAAAEAAwAMAAAAAAAAAAIAAAAEBQIAAAAAAgAAAQIABKMAAADAAAAAwAEBAIIBAgACBgAGAQIAAQEAARgAAAgAAQAAAAACGEYtswLUn+f/Tle3apAWiWheOscqgkey

-- decompilation:
local function SafeUnit(p1) -- line: 1
	if p1.Magnitude == 0.0 then
		return (Vector3.new(0.0, 0.0, 0.0))
	end

	return p1.Unit
end

return function(p2, p3, p4) -- line: 9
	local v6 = p4.Bones[p2.ParentIndex]

	if v6 then
		local FreeLength = p2.FreeLength
		local v8 = p3 - v6.Position
		local v9 = if v8.Magnitude ~= 0.0 then v8.Unit else Vector3.new(0.0, 0.0, 0.0)
		local v10 = FreeLength > v8.Magnitude and v8.Magnitude or FreeLength

		return v6.Position + v9 * v10
	end
end

