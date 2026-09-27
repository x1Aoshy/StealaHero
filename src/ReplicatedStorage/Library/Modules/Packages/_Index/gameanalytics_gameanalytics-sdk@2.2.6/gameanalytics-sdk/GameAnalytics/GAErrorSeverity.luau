-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMNBWVycm9yI0F0dGVtcHQgdG8gbW9kaWZ5IHJlYWQtb25seSB0YWJsZTogBiwga2V5PQgsIHZhbHVlPQpfX25ld2luZGV4B19faW5kZXgLX19tZXRhdGFibGUMc2V0bWV0YXRhYmxlDXJlYWRvbmx5dGFibGUFZGVidWcEaW5mbwd3YXJuaW5nCGNyaXRpY2FsAAMLAwAAAAALpAMBAAAAAEBvBQIAUgYAAG8HAwBSCAEAbwkEAFIKAgBzBAUKnwMCAYIAAQAFAwEEAAAAQAMCAwMDBAAFBQEYAAAAAAAAAAAAAAEGAAAAAAUBAAAAAA7/AgAAAAAAAOIDBAAwAANuAAAAAMAEBQAwBAPOAwAAAJ49AgMDAAAApAEHAAAAYECfAQMCggECAAgDBgMHAQADBQgDAP////8BAgAAAAP/////BgADCAQAAGBAAQABCQEYAAAAAQACAAAAAP0AAAACAAAAAAMAAAECAAajAAAAwAAAAFIBAADiAgYAnwECAoIBAgAHBgEDCgMLAwwDAQMNCAUBAQAAAAICAAAAAwMAAAAEBAAAAAUFAAAAAQEBAAEYAAAKAAAAAQAAAAACRKGwQqLeOijE4ko2jS2d9TS5pzZ2ZdpD

-- decompilation:
local function readonlytable(p1) -- line: 1
	return (setmetatable({}, {
		__metatable = false,
		__index = p1,
		__newindex = function(p2, p3, p4) -- line: 5
			error("Attempt to modify read-only table: " .. p2 .. ", key=" .. p3 .. ", value=" .. p4)
		end
	}))
end

return (readonlytable({
	debug = "debug",
	info = "info",
	warning = "warning",
	error = "error",
	critical = "critical"
}))

