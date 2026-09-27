-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0CWludGVyZmFjZQlQcm9kdWN0SWQLRGlzcGxheU5hbWUKQ2xpZW50VGVzdARJY29uBERlc2MGbnVtYmVyCG9wdGlvbmFsBnN0cmluZwhjYWxsYmFjaw1EZWZhdWx0Q29uZmlnAAEHAAABAgA7owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLoBwAAAE0CAuYIAAAATQIClQkAAACfAQIC/wIBAAAAAABNAwEvCgAAAOIEEABNBQFgEQAAADAFBAsLAAAATQUBERIAAABNBgFBEwAAAJ8FAgIwBQRXDAAAAE0FARESAAAATQYBphQAAACfBQICMAUEpQ0AAABNBQEREgAAAE0GAUETAAAAnwUCAjAFBK4OAAAATQUBERIAAABNBgFBEwAAAJ8FAgIwBQR3DwAAAJ8DAgIwAwIMFQAAAIICAgAWAwEEAAAAQAMCAwMDBAQAAEBAAwUDBgMHAwgDCQMKAwsDDAMNAw4FBQsMDQ4PAw8DEAMRAxIDEwABAAEYAAMAAAAAAAMAAAAAAAAAAAAAAwACAAABAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAPsAAAgBAAAAAACi8+196CTbWwQF3ECr8n2X0uv6CZA3h3w=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)

return {
	DefaultConfig = t.interface({
		ProductId = t.number,
		DisplayName = t.optional(t.string),
		ClientTest = t.optional(t.callback),
		Icon = t.optional(t.string),
		Desc = t.optional(t.string)
	})
}

