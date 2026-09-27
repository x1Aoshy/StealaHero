-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBWVycm9yI0F0dGVtcHQgdG8gbW9kaWZ5IHJlYWQtb25seSB0YWJsZTogBiwga2V5PQgsIHZhbHVlPQpfX25ld2luZGV4B19faW5kZXgLX19tZXRhdGFibGUMc2V0bWV0YXRhYmxlDXJlYWRvbmx5dGFibGUGU291cmNlBFNpbmsAAwsDAAAAAAukAwEAAAAAQG8FAgBSBgAAbwcDAFIIAQBvCQQAUgoCAHMEBQqfAwIBggABAAUDAQQAAABAAwIDAwMEAAUFARgAAAAAAAAAAAAAAQYAAAAABQEAAAAADv8CAAAAAAAA4gMEADAAA24AAAAAwAQFADAEA84DAAAAnj0CAwMAAACkAQcAAABgQJ8BAwKCAQIACAMGAwcBAAMFCAMA/////wECAAAAA/////8GAAMIBAAAYEABAAEJARgAAAABAAIAAAAA/QAAAAIAAAAAAwAAAQIABqMAAADAAAAAUgEAAOICAwCfAQICggECAAQGAQMKAwsIAgEBAAAAAgIAAAABAQEAARgAAAoAAAABAAAAAAL+maZeeKteEqrQ1/qy1GwUjoGxKsxdzF8=

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
	Source = "Source",
	Sink = "Sink"
}))

