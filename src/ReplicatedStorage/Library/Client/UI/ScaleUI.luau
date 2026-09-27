-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUDFZpZXdwb3J0U2l6ZQFYAVkEbWF0aANtaW4FY2xhbXAFU2NhbGULdXBkYXRlU2NhbGUKRGlzY29ubmVjdAdVSVNjYWxlGEdldFByb3BlcnR5Q2hhbmdlZFNpZ25hbAdDb25uZWN0BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwl3b3Jrc3BhY2UNQ3VycmVudENhbWVyYQAECgACAAAAH/sAAABNAACwAAAAAE0BAHkBAAAATQIAeAIAAACeEwEFAgAAAFIIAQBSCQIApAcJAAAgcICfBwMCeAYHBj4FBgVbBAUElQMEA/sEAQBvCAMAjAkBADQuAwQICQAAUgcDAKQGDAAALHCAnwYEAlsFBgowBQSEDQAAAIIAAQAOAwEDAgMDApqZmZmZmdk/AjMzMzMzM+M/AgAAAAAAAI5AAgAAAAAAAHRAAwQDBQQAIHCAAgAAAAAAAPA/AwYEACxwgAMHAA0IARgAAAABAAEAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAABDgAAAAACAAEAAAAK+wAAACsAAQCCAAEA+wAAALwAABoAAAAAnwACAcYAAADeAAAAggABAAEDCQAZAAEYAAABAgAAAAEAARoAAAAADAECAAAGAwAABQEHMvsBAABNAQErAAAAAFICAACfAQIB2QEAABICAQASAAAA+wIBAE0CArABAAAATQMCeQIAAABNBAJ4AwAAAJ4TAwUEAAAAUgoDAFILBACkCQoAACSAgJ8JAwJ4CAkHPgcIBlsGBwWVBQYEbwkEAIwKAQA0LgUECQoAAFIIBQCkBw0AADCAgJ8HBAJbBgcLMAYAhA4AAAD7AgEAbwQBALwCApQPAAAAnwIDAlIEAQC8AgLHEAAAAJ8CAwLZAwEAEgEC/8ECAACCAwIAEQMKAwEDAgMDApqZmZmZmdk/AjMzMzMzM+M/AgAAAAAAAI5AAgAAAAAAAHRAAwQDBQQAJICAAgAAAAAAAPA/AwYEADCAgAMHAwsDDAIAAQoAARgAAAAAAAIAAAEAAAEAAQABAAAAAAAAAAAAAAEAAAAAAAAAAAAABQAAAAAAAAAAAgAAAAsAAAAABAAAAQIAFqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICpAIJAAAAgEBNAgJICgAAAMADCwASAAEAEgACAIIDAgAMAw0EAAAAQAMOAw8DEAQAAEBAAxEDEgMTBAAAgEADFAYCAQIBAAEYAAEAAAAAAAMAAAAAAAADAAAAAgAAAAEAAAAAAwW9gFrMij4bsD0K/pn5eMB1pZcuN3nqWw==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local CurrentCamera = workspace.CurrentCamera

return function(p1) -- line: 10
	-- upvalues: Asserts (copy), CurrentCamera (copy)
	Asserts.UIScale(p1)

	local function updateScale() -- line: 13
		-- upvalues: CurrentCamera (copy), p1 (copy)
		local ViewportSize = CurrentCamera.ViewportSize

		p1.Scale = math.clamp((math.min(ViewportSize.X, ViewportSize.Y) - 320.0) / 960.0 * 0.6 + 0.4, 0.4, 1.0) * 1.0
	end

	local ViewportSize = CurrentCamera.ViewportSize

	p1.Scale = math.clamp((math.min(ViewportSize.X, ViewportSize.Y) - 320.0) / 960.0 * 0.6 + 0.4, 0.4, 1.0) * 1.0

	local connection = CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

	return function() -- line: 25
		-- upvalues: connection (ref)
		if not connection then
			return
		end

		connection:Disconnect()
		connection = nil
	end
end

