-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKB1ZlY3RvcjMBWAFZAVoEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzAAIFAQEAAAYDAAAFAQgQ+wEAAE0BAU8AAAAAUgIAAJ8BAgH/AQAAAwAAAE0CAHkBAAAATQMAeAIAAABNBAB7AwAAAMUBAgQBAAAAggECAAQDAQMCAwMDBAAKAAEYAAAAAAABAAAAAAAAAAAAAAsAAAAAAwAAAQIAEaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICwAIIABIAAQCCAgIACQMFBAAAAEADBgMHAwgEAABAQAMJAwoGAAEAAQABGAADAAAAAAADAAAAAAAAAwAAAQAAAAABikRRw164m5lS0LOwXrkQt/pcRre4gDvC

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(vector3: Vector3) -- line: 10
	-- upvalues: Asserts (copy)
	Asserts.Vector3(vector3)

	return {
		vector3.X,
		vector3.Y,
		vector3.Z
	}
end

