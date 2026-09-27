-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbBWVycm9yDXVuaW1wbGVtZW50ZWQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdNb2R1bGVzCFBhY2thZ2VzAXQJRGlyZWN0b3J5BlJhcml0eRNUcmVhZG1pbGxOYW1lRXhpc3RzCWludGVyZmFjZQNfaWQFUHJpY2UJUHJvZHVjdElkBEljb24PU3BlZWRNdWx0aXBsaWVyDURpc3BsYXlJblNob3ALRGlzcGxheU5hbWUGc3RyaW5nBm51bWJlcghvcHRpb25hbAVUeXBlcw1EZWZhdWx0Q29uZmlnB2Jvb2xlYW4AAgMBAAAABgMAAAUBAwWkAQEAAAAAQG8CAgCfAQIBggABAAMDAQQAAABAAwIADQABGAAAAAABDgAAAAAIAAABAgBNowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLoBwAAAE0CAuYIAAAATQIClQkAAACfAQICpAIFAAAAQEBNAwCRCgAAAE0DA/ILAAAAnwICAv8DAgAAAAAAwAQMADAEAzwNAAAATQQBLw4AAADiBRYATQYBQRcAAAAwBgXTDwAAAE0GAWAYAAAAMAYFJBAAAABNBgERGQAAAE0HAWAYAAAAnwYCAjAGBQsRAAAATQYBQRcAAAAwBgWuEgAAAE0GAu8aAAAATQYGDBsAAAAwBgXyCwAAAE0GAWAYAAAAMAYFoBMAAABNBgERGQAAAE0HAT4cAAAAnwYCAjAGBWYUAAAATQYBQRcAAAAwBgVXFQAAAJ8EAgIwBAMMGwAAAIIDAgAdAwMEAAAAQAMEAwUDBgQAAEBAAwcDCAMJAwoDCwMMBgADDQMOAw8DEAMRAxIDEwMUAxUFCA8QERILExQVAxYDFwMYAxkDGgMbAQABAAEYAAMAAAAAAAMAAAAAAAAAAAAAAQAAAAAAAAMAAgAABAAAAQAAAAEAAAABAAAAAAAAAQAAAAEAAAAAAAEAAAABAAAAAAAAAQAAAPgAAAsBAAAAAAHKcrCg5isBQdkua3JsipTiumqn1Pi22qE=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local Rarity = require(ReplicatedStorage.Directory.Rarity)

return {
	TreadmillNameExists = function(_: string) -- line: 13
		error("unimplemented")
	end,
	DefaultConfig = t.interface({
		_id = t.string,
		Price = t.number,
		ProductId = t.optional(t.number),
		Icon = t.string,
		Rarity = Rarity.Types.DefaultConfig,
		SpeedMultiplier = t.number,
		DisplayInShop = t.optional(t.boolean),
		DisplayName = t.string
	})
}

