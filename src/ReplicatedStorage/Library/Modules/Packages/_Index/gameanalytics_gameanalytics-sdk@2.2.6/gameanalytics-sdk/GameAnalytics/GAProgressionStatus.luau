-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMBWVycm9yI0F0dGVtcHQgdG8gbW9kaWZ5IHJlYWQtb25seSB0YWJsZTogBiwga2V5PQgsIHZhbHVlPQpfX25ld2luZGV4B19faW5kZXgLX19tZXRhdGFibGUMc2V0bWV0YXRhYmxlDXJlYWRvbmx5dGFibGUFU3RhcnQIQ29tcGxldGUERmFpbAADCwMAAAAAC6QDAQAAAABAbwUCAFIGAABvBwMAUggBAG8JBABSCgIAcwQFCp8DAgGCAAEABQMBBAAAAEADAgMDAwQABQUBGAAAAAAAAAAAAAABBgAAAAAFAQAAAAAO/wIAAAAAAADiAwQAMAADbgAAAADABAUAMAQDzgMAAACePQIDAwAAAKQBBwAAAGBAnwEDAoIBAgAIAwYDBwEAAwUIAwD/////AQIAAAAD/////wYAAwgEAABgQAEAAQkBGAAAAAEAAgAAAAD9AAAAAgAAAAADAAABAgAGowAAAMAAAABSAQAA4gIEAJ8BAgKCAQIABQYBAwoDCwMMCAMBAQAAAAICAAAAAwMAAAABAQEAARgAAAoAAAABAAAAAAI9I4mCAU+LHn/F6kAeB8NrTTue9g/n44M=

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
	Start = "Start",
	Complete = "Complete",
	Fail = "Fail"
}))

