-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBXRhYmxlBWNsb25lBmlwYWlycwRtYXRoA2FicwZjcmVhdGUAAhUCAAAAAHIcAgAApAMCAAAEAIBSBAAAnwMCAqQEBAAAADBAUgUDAJ8EAgRRBAUApAkCAAAEAIBSCggAnwkCAmoJAwduBPr/AgAAgKQEAgAABACAUgUBAJ8EAgKMBwEAeAUCBYwGAQCoBTsAUggHAJULBwVSCQIAjAoBAKgJEACHDgMLhw0OB7sCDQKkDAgAABxggJ8MAgKHDwMIhw4PB7sCDgKkDQgAABxggJ8NAgJgDQIADAAAAFIICwCLCfD/8QcJAAgAAACHCQMIhwoDB2oJAwdqCgMIhwkECIcKBAdqCQQHagoECJULBwVSCQIAjAoBAKgJFwCHDgMLhw0OB4cPAweHDg8H7AwNDocNBAuHDwQHCQ4MDyYNDQ5qDQQLUg8HAFINAgCMDgEAqA0IAIcQAwuHERAPhxQDB4cTFA8JEgwTJhEREmoREA+LDfj/iwnp/4sFxf+kBQoAACQAgFIGAgCMBwAAnwUDAlIIAgCMBgEAjAf//6gGFACHCQQIagkFCJULCAVSCQIAjAoBAKgJCACHDAUIhw8DCIcODwuHDwULCQ0ODyYMDA1qDAUIiwn4/4cJBQiHCwMIhwoLCOwJCQpqCQUIiwbs/4IFAgALAwEDAgQABACAAwMEAAAwQAIAAAAAAADwPwMEAwUEABxggAMGBAAkAIAAAQABGAABAAAAAQAAAAABAAAAAP8AAwAAAAEAAAABAQAAAAEAAAAAAAAAAAAAAAAAAf4FAAEAAAABAAAAAgAAAAEAAAAAAQAAAAABAAAAAQAAAAAAAP/99RMAAAAAAQAAAAEAAQAAAAEAAAAAAAD/AwAAAAD7BwIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAAEAAQABGAAAAAEAAAAAASSFsfv73S6nibhoWQsT4u1UnaaPFkHb+g==

-- decompilation:
return function(p1, p2) -- line: 1
	local v3 = #p1
	local v4 = table.clone(p1)

	for i, v in ipairs(v4) do
		v4[i] = table.clone(v)
	end

	local v7 = table.clone(p2)

	for i = 1.0, v3 - 1.0 do
		local v9 = i

		for j = i + 1.0, v3 do
			if math.abs(v4[j][i]) > math.abs(v4[v9][i]) then
				v9 = j
			end
		end

		if i ~= v9 then
			local v11 = v4[v9]
			local v12 = v4[i]

			v4[i] = v11
			v4[v9] = v12

			local v13 = v7[v9]
			local v14 = v7[i]

			v7[i] = v13
			v7[v9] = v14
		end

		for j = i + 1.0, v3 do
			local v16 = v4[j][i] / v4[i][i]

			v7[j] = v7[j] - v16 * v7[i]

			for k = i, v3 do
				local v18 = v4[j]

				v18[k] = v18[k] - v16 * v4[i][k]
			end
		end
	end

	local t1 = table.create(v3, 0.0)

	for i = v3, 1.0, -1.0 do
		t1[i] = v7[i]

		for j = i + 1.0, v3 do
			t1[i] = t1[i] - v4[i][j] * t1[j]
		end

		t1[i] = t1[i] / v4[i][i]
	end

	return t1
end

