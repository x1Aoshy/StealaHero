-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0D3N0cmljdEludGVyZmFjZQhQb3NpdGlvbglSZW1haW5pbmcIQ2F0ZWdvcnkHVmVjdG9yMwZudW1iZXIGc3RyaW5nEVNwcmlua2xlckl0ZW1EYXRhBWFycmF5G1NlcmlhbGl6ZWRTcHJpbmtsZXJJdGVtRGF0YQABBwAAAQIAPKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQIC6AcAAABNAgLmCAAAAE0CApUJAAAAnwECAv8CAgAAAAAATQMB8AoAAADiBA4ATQUBTw8AAAAwBQQ7CwAAAE0FAWAQAAAAMAUEaQwAAABNBQFBEQAAADAFBAsNAAAAnwMCAjADAjsSAAAATQMB8AoAAADiBA4ATQUBHRMAAABNBgFgEAAAAJ8FAgIwBQQ7CwAAAE0FAWAQAAAAMAUEaQwAAABNBQFBEQAAADAFBAsNAAAAnwMCAjADAsUUAAAAggICABUDAQQAAABAAwIDAwMEBAAAQEADBQMGAwcDCAMJAwoDCwMMBQMLDA0DDQMOAw8DEAMRAxIAAQABGAADAAAAAAADAAAAAAAAAAAAABAAAgAAAQAAAAEAAAABAAAA/QAABgAAAQAAAAAAAAEAAAABAAAA/QAABgEAAAAAAL9rL3akCsnxuW0N/FyoKBbPczgCja9Fdw==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)

return {
	SprinklerItemData = t.strictInterface({
		Position = t.Vector3,
		Remaining = t.number,
		Category = t.string
	}),
	SerializedSprinklerItemData = t.strictInterface({
		Position = t.array(t.number),
		Remaining = t.number,
		Category = t.string
	})
}

