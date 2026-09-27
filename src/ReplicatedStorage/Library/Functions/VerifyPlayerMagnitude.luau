-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMECUNoYXJhY3RlcgtQcmltYXJ5UGFydAhQb3NpdGlvbglNYWduaXR1ZGUAAgkDAAAACAUAAAUDB4iCFZADAgAOAREATQQAaQEAAABSBQQADgUCAE0FBJsCAAAADgUKAE0IBTsDAAAAJgcIAU0HB6oEAAAAtwcCAAMAAACpBgABqQYBAIIGAgCpBAAAggQCAAUCAAAAAAAAJEADAQMCAwMDBAABAAEYAAEBAAEAAAABAQAAAAAAAAAAAAMAAgAAAAABAAABAgADowAAAMAAAACCAAIAAQYAAQABAAEYAAAAAQAAAAAB

-- decompilation:
return function(p1, vector3: Vector3?, n1: number?) -- line: 1
	local v4 = n1 or 10.0

	if vector3 then
		local Character = p1.Character
		local v6 = Character and Character.PrimaryPart

		if v6 then
			return v4 > (v6.Position - vector3).Magnitude
		end
	end

	return false
end

