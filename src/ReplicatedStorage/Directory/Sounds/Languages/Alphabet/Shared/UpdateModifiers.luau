-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTD1VwZGF0ZU1vZGlmaWVycwZhc3NlcnQGdHlwZW9mBnN0cmluZwV0YWJsZTRMZXR0ZXIgIiUqIiBkb2VzIG5vdCBleGlzdCBpbiB0aGUgYWxwaGFiZXQgY29udGFpbmVyBmZvcm1hdAlNb2RpZmllcnMGUGFyZW50BVNvdW5kBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwZzY3JpcHQFVHlwZXMJSW50ZXJmYWNlAAIPAgMAAAcEAAAFAg8EQPsDAABNAwOEAAAAAFIEAABSBQEAnwMDAEwBAAKkAgIAAAAQQJ8CAAG7LAADUgQAAKQDBAAAADBAnwMCAvADBAAFAACA+wMBAIcCAwBlAAEAUgIAAPsDAgBNAwNLBgAAAFIEAgCfAwIBUgMBAMYEAADGBQAAZAMfAIcJAgZvCgcAUgwGALwKCo0IAAAAnwoDAp4BCQMKAAAApAgCAAAAEECfCAMCTQkIFgkAAADGCgAAxgsAAGQJAwDGDgAAMA4NJAoAAABuCfz/AgAAAFIJBwDGCgAAxgsAAGQJBABNDghuCwAAADAODSQKAAAAbgn7/wIAAABuA+D/AgAAAIICAgAMAwEDAgQAABBAAwMEAAAwQAMEAwUDBgMHAwgDCQMKAAoAARgAAAAAAAAAAAAAAgAAAAAAAAAAAAABAAAAAAIAAAACAAAAAAAAAAAAAAIAAAAAAQAA/wAEAAAAAQAAAP8A+AANCwAAAAAFAAABAgApowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgKkAgUAAABAQKQDCQAAAIBATQMDJAoAAABNAwMkCgAAAE0DA+8LAAAATQMDDwwAAACfAgICpAMFAAAAQECkBAkAAACAQE0EBCQKAAAATQQEJAoAAACfAwICwAQNABIAAgASAAMAEgABAIIEAgAOAwsEAAAAQAMMAw0DDgQAAEBAAw8DEAMRBAAAgEADCQMSAxMGAAEAAQABGAABAAAAAAADAAAAAAAAAQAAAAAAAAAAAAAAAAEAAAAAAAAAAAMAAAAAAQAAAAABPzpw9Blt2hocNl50jLHSX08iZ4AN/hr1

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Interface = require(script.Parent.Parent.Types.Interface)
local Parent = require(script.Parent.Parent)

return function(p1, t1: {[any]: any}) -- line: 10
	-- upvalues: Interface (copy), Parent (copy), Asserts (copy)
	assert(Interface.UpdateModifiers(p1, t1))

	local v7 = if typeof(p1) ~= "string" then p1 else Parent[p1]

	Asserts.table(v7)

	for v8, v9 in t1 do
		local v10 = assert(v7[v8], `Letter "{ v8 }" does not exist in the alphabet container`)

		for _, v12 in v10.Modifiers do
			v12.Parent = nil
		end

		for _, v14 in v9 do
			v14.Parent = v10.Sound
		end
	end

	return v7
end

