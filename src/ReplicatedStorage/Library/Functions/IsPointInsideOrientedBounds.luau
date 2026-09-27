-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOBkNGcmFtZQdWZWN0b3IzElBvaW50VG9PYmplY3RTcGFjZQFYBG1hdGgDYWJzAVkBWgRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMBAQACCAMBAAAIBQAABQNACAg3+wMAAE0DA4UAAAAAUgQAAJ8DAgH7AwAATQMDTwEAAABSBAEAnwMCAfsDAABNAwNPAQAAAFIEAgCfAwIBUgUCALwDAMYCAAAAnwMDAlsEAQOpBQAATQcDeQQAAAC7AgcCpAYHAAAYUICfBgICTQcEeQQAAAB9BhgABwAAAKkFAABNBwN4CAAAALsCBwKkBgcAABhQgJ8GAgJNBwR4CAAAAH0GDQAHAAAATQcDewkAAAC7AgcCpAYHAAAYUICfBgICTQcEewkAAADUBgIABwAAAKkFAAGpBQEAggUCAAoDAQMCAwMCAAAAAAAA4D8DBAMFAwYEABhQgAMHAwgACQABGAAAAAAAAQAAAAABAAAAAAEAAAABAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAEAAAAAAAAAAAAAAAAKAAAAAAMAAAECABGjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAokHAAAAnwECAsACCAASAAEAggICAAkDCQQAAABAAwoDCwMMBAAAQEADDQMOBgABAAEAARgAAwAAAAAAAwAAAAAAAAIAAAEAAAAAASgbMsIdCsvRzJo+LPine29YAyW2Gt9Yww==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(cFrame: CFrame, vector3: Vector3, vector3_2: Vector3) -- line: 9
	-- upvalues: Asserts (copy)
	Asserts.CFrame(cFrame)
	Asserts.Vector3(vector3)
	Asserts.Vector3(vector3_2)

	local v6 = cFrame:PointToObjectSpace(vector3_2)
	local v7 = vector3 * 0.5

	return math.abs(v6.X) <= v7.X and (math.abs(v6.Y) <= v7.Y and math.abs(v6.Z) <= v7.Z)
end

