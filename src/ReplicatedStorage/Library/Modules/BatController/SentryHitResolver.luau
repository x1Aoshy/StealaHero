-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWB1ZlY3RvcjMGbnVtYmVyBmlwYWlycwtHZXRDaGlsZHJlbgVNb2RlbANJc0EIR2V0UGl2b3QIUG9zaXRpb24JTWFnbml0dWRlB0Rlc3Ryb3kEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlCVdvcmtzcGFjZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwlfX09CSkVDVFMIU2VudHJpZXMGRm9sZGVyLVdvcmtzcGFjZS5fX09CSkVDVFMuU2VudHJpZXMgbXVzdCBiZSBhIEZvbGRlcgZhc3NlcnQAAgoCAgAABwQAAAUCCAIn+wIAAE0CAk8AAAAAUgMAAJ8CAgH7AgAATQICYAEAAABSAwEAnwICAaQCAwAAACBA+wMBALwDA2gEAAAAnwMCAJ8CAARRAhIAbwkFALwHBv4GAAAAnwcDAg4HDQC8CAZSBwAAAJ8IAgJNCAg7CAAAACYHCABNBweqCQAAAH0HBAABAAAAvAcGUAoAAACfBwIBbgLt/wIAAICCAAEACwMBAwIDAwQAACBAAwQDBQMGAwcDCAMJAwoAFwABGAAAAAAAAQAAAAACAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAEAAP4ABRgAAAAACAAAAQIAJqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQE0DAGoHAAAATQMDiQgAAACfAgICTQMBwwkAAABNAwNMCgAAAG8HCwC8BQP+DAAAAJ8FAwKBAQUEDQAAAG8GDQCkBA8AAADgQJ8EAwHABBAAEgACABIAAwCCBAIAEQMLBAAAAEADDAMNAw4DDwQAAFBAAxADEQMSAxMDFAMGAxUDFgQAAOBABgABAAEAARgAAwAAAAAAAQAAAAAAAwAAAAAAAAsAAAABAAAAAAAAAAAAAwAAAAEAAAAAAVydI2HSnzOTFtK73Xm+1hwshTQVbllJYA==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Sentries = Workspace.__OBJECTS.Sentries

assert(Sentries:IsA("Folder"), "Workspace.__OBJECTS.Sentries must be a Folder")

return function(vector3: Vector3, n1: number) -- line: 23
	-- upvalues: Asserts (copy), Sentries (copy)
	Asserts.Vector3(vector3)
	Asserts.number(n1)

	for _, child in ipairs(Sentries:GetChildren()) do
		if child:IsA("Model") and n1 >= (child:GetPivot().Position - vector3).Magnitude then
			child:Destroy()
		end
	end
end

