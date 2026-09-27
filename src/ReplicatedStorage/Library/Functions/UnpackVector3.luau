-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKBWFycmF5BmZpbml0ZQdWZWN0b3IzA25ldwRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMAAgUBAQAABgMAAAUBBA/7AQAATQEBHQAAAABNAQEZAQAAAFICAACfAQIBEwIAABMDAAETBAACTDYAAqQBBAAADCCAnwEEAoIBAgAFAwEDAgMDAwQEAAwggAAKAAEYAAAAAAAAAAEAAAAAAAAACwAAAAADAAABAgARowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgLAAggAEgABAIICAgAJAwUEAAAAQAMGAwcDCAQAAEBAAwkDCgYAAQABAAEYAAMAAAAAAAMAAAAAAAADAAABAAAAAAF4SC49RY97PhQDvqG3xKcNCFA5SUqMRDw=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(t1: {[any]: any}) -- line: 10
	-- upvalues: Asserts (copy)
	Asserts.array.finite(t1)

	return (Vector3.new(t1[1.0], t1[2.0], t1[3.0]))
end

