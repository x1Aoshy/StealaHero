-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLCG9wdGlvbmFsBnN0cmluZwQlKjogBmZvcm1hdAAEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzAAMHAQIAAAYDAAAFAYMT+wEAAE0BAREAAAAATQEBQQEAAABSAgAAnwECAQ4ABwBvBAIAUgYAALwEBI0DAAAAnwQDAlICBAArAgEAbwIEAPsDAQBzAQIDggECAAUDAQMCAwMDBAMFAAsAARgAAAAAAAAAAQAAAAAAAAAAAAAADAAAAAADAQEAAAYDAAAFAQMJ+wEAAE0BAUEAAAAAUgIAAJ8BAgHZAQAAEgIAABIAAACCAQIAAQMCAQAIAAEYAAAAAAACAAAACQAAAAADAAABAgARowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgLAAggAEgABAIICAgAJAwYEAAAAQAMHAwgDCQQAAEBAAwoDCwYBAQEBAAEYAAEAAAAAAAMAAAAAAAADAAABAAAAAAJ1VvB1e+g/Sz79HCvOgEevBU7nAUeSmnQ=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(s1: string) -- line: 8
	-- upvalues: Asserts (copy)
	Asserts.string(s1)

	return function(s2: string?) -- line: 11
		-- upvalues: Asserts (copy), s1 (copy)
		Asserts.optional.string(s2)

		return (s2 and `{ s2 }: ` or "") .. s1
	end
end

