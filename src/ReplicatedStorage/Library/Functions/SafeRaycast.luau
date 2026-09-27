-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMNBGx1YXUGYXNzZXJ0CU1hZ25pdHVkZQdSYXljYXN0CERpc3RhbmNlBG1hdGgDbWF4CEluc3RhbmNlCE1hdGVyaWFsCFBvc2l0aW9uBk5vcm1hbAtTYWZlUmF5Y2FzdAl3b3Jrc3BhY2UAAgwEAQAAEQYAAgUECAiHgggLLQEICi4BQZAEAwCMBwAA1AcCAAQAAACpBgABqQYBAIEBBgQBAAAAbwcBAKQFAwAAACBAnwUDAU0FAaoEAAAAtwQCAAUAAACpBwABqQcBAIEBBwQBAAAAbwgBAKQGAwAAACBAnwYDAfsGAABSCAAAUgkBAFIKAgC8BgbCBQAAAJ8GBQIrBgIAxgcAAIIHAgBNCAZVBgAAACYHCASMCQAAnhIJBAcAAABSCgcApAgJAAAgcICfCAMCCQsIAewKCwVDCQAK4goOADAIClUGAAAATQsG9AoAAAAwCwr0CgAAAE0LBi0LAAAAMAsKLQsAAAAwCQo7DAAAAE0LBhANAAAAMAsKEA0AAACCCgIADwL8qfHSTWJQPwMBAwIEAAAgQAMDAwQDBQMGAwcEACBwgAMIAwkDCgMLBQUGCgsMDQALDAEYAAEAAAAAAAAAAAAAAgABAAAAAAAAAAAAAgAAAAAAAAEBAAMAAAEAAAAAAAABAAACAQABAAAAAQAAAAEAAQAAAAARAAAAAAIAAAECAAajAAAApAABAAAAAEDAAQIAEgAAAIIBAgADAw0EAAAAQAYAAQABAAEYAAgAAgAeAQAAAAABttws4Ve2cmSctnNF4xOa9sbEO5WEGEbg

-- decompilation:
local _workspace = workspace

local function SafeRaycast(vector3: Vector3, vector3_2: Vector3, p1, n1: number?) -- line: 11
	-- upvalues: _workspace (copy)
	local v7 = n1 or 0.001

	assert(v7 >= 0.0, "luau")

	local Magnitude = vector3_2.Magnitude

	assert(v7 < Magnitude, "luau")

	local raycastResult = _workspace:Raycast(vector3, vector3_2, p1)

	if not raycastResult then
		return nil
	end

	local v10 = math.max(0.0, raycastResult.Distance - v7)
	local v11 = vector3 + v10 * vector3_2 / Magnitude

	return {
		Distance = v10,
		Instance = raycastResult.Instance,
		Material = raycastResult.Material,
		Position = v11,
		Normal = raycastResult.Normal
	}
end

return SafeRaycast

