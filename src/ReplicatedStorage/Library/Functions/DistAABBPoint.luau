-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMHAVgBWQFaBG1hdGgEc3FydAdWZWN0b3IzA25ldwACDAIAAAAHBAAABQIICHiMAgAATQMBeQAAAABNBAF4AQAAAE0FAXsCAAAAjAYAAE0HAXkAAAAATQkAeQAAAAA5CAkAYAcKAAgAAABNCAB5AAAAAEMHAwgJCAcHQwICCE0IAHkAAAAAOQMIAGUADwBNBwF5AAAAAE0IAHkAAAAAYAgJAAcAAABNCAB5AAAAACYHAwgJCAcHQwICCE0DAHkAAAAAZQABAJUGBgNNBwF4AQAAAE0JAHgBAAAAOQgJAGAHCgAIAAAATQgAeAEAAABDBwQICQgHB0MCAghNCAB4AQAAADkECABlAA8ATQcBeAEAAABNCAB4AQAAAGAICQAHAAAATQgAeAEAAAAmBwQICQgHB0MCAghNBAB4AQAAAGUAAQCVBgYDTQcBewIAAABNCQB7AgAAADkICQBgBwoACAAAAE0IAHsCAAAAQwcFCAkIBwdDAgIITQgAewIAAAA5BQgAZQAPAE0HAXsCAAAATQgAewIAAABgCAkABwAAAE0IAHsCAAAAJgcFCAkIBwdDAgIITQUAewIAAABlAAEAlQYGA7sZAgNSCAIApAcGAAAUQICfBwICNDYDBgQFAABSCQMAUgoEAFILBQCkCAkAACBwgJ8IBAKMCgMA1AoCAAYAAACpCQABqQkBAIIHBAAKAwEDAgMDAgAAAAAAAPA/AwQDBQQAFECAAwYDBwQAIHCAAAEAARgAAQABAAEAAQIAAAAAAAABAAABAAEAAAABAAAAAAABAAABAAEAAAIDAAAAAAAAAQAAAQABAAAAAQAAAAAAAQAAAQABAAACAwAAAAAAAAEAAAEAAQAAAAEAAAAAAAEAAAEAAQAAAgMAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgABAAEAARgAAAABAAAAAAG8c1So7ZDxl0nSmgrklzCozGtD3I63Pqk=

-- decompilation:
return function(vector3: Vector3, vector3_2: Vector3) -- line: 1
	local n1 = 0.0
	local vector3_2X = vector3_2.X
	local vector3_2Y = vector3_2.Y
	local vector3_2Z = vector3_2.Z
	local n2 = 0.0

	if vector3_2.X < -vector3.X then
		local v8 = vector3_2X + vector3.X

		n1 += v8 * v8
		vector3_2X = -vector3.X
	elseif vector3_2.X > vector3.X then
		local v9 = vector3_2X - vector3.X

		n1 += v9 * v9
		vector3_2X = vector3.X
	else
		n2 += 1.0
	end

	if vector3_2.Y < -vector3.Y then
		local v10 = vector3_2Y + vector3.Y

		n1 += v10 * v10
		vector3_2Y = -vector3.Y
	elseif vector3_2.Y > vector3.Y then
		local v11 = vector3_2Y - vector3.Y

		n1 += v11 * v11
		vector3_2Y = vector3.Y
	else
		n2 += 1.0
	end

	if vector3_2.Z < -vector3.Z then
		local v12 = vector3_2Z + vector3.Z

		n1 += v12 * v12
		vector3_2Z = -vector3.Z
	elseif vector3_2.Z > vector3.Z then
		local v13 = vector3_2Z - vector3.Z

		n1 += v13 * v13
		vector3_2Z = vector3.Z
	else
		n2 += 1.0
	end

	return math.sqrt(n1), Vector3.new(vector3_2X, vector3_2Y, vector3_2Z), n2 >= 3.0
end

