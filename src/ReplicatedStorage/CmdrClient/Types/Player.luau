-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhD01ha2VGdXp6eUZpbmRlcgpHZXRQbGF5ZXJzCVRyYW5zZm9ybShObyBwbGF5ZXIgd2l0aCB0aGF0IG5hbWUgY291bGQgYmUgZm91bmQuCFZhbGlkYXRlCEdldE5hbWVzDEF1dG9jb21wbGV0ZQVQYXJzZQROYW1lB0RlZmF1bHQGcGxheWVyDFJlZ2lzdGVyVHlwZQdwbGF5ZXJzEE1ha2VMaXN0YWJsZVR5cGUIUHJlZml4ZXMNJSB0ZWFtUGxheWVycwdyZXF1aXJlBnNjcmlwdAZQYXJlbnQGU2hhcmVkBFV0aWwEZ2FtZQdQbGF5ZXJzCkdldFNlcnZpY2UXQXJndW1lbnRPcGVyYXRvckFsaWFzZXMCbWUBLgNhbGwBKgZvdGhlcnMCKioGcmFuZG9tAT8ABwQBAgAAAAz7AQAATQEBPQAAAAD7AgEAvAICqwEAAACfAgIAnwEAAlICAQBSAwAAnwICAIICAAACAwEDAgAFAwEYAAAAAAAAAAACAAAABgAAAAAEAQAAAAAIHAIAAIwDAAC3AwIAAgAAAKkBAAGpAQEAbwIAAIIBAwABAwQACwUBGAAAAAAAAAAADAAAAAADAQEAAAAG+wEAAE0BAccAAAAAUgIAAJ8BAgCCAQAAAQMGAA8HARgAAAAAAAAQAAAAAAIBAAAAAAITAQAAggECAAAAEwgBGAAAFAAAAAACAQAAAAADTQEAugAAAACCAQIAAQMJABcKARgAAAAYAAAAAAcBAgAAABBvAwAA+wQAALwBAN0BAAAAnwEEAW8DAgD7BAEATQQEJAMAAAD7BQAA4gYGAJ8EAwC8AQDdAQAAAJ8BAAGCAAEABwMLAwwDDQMOAw8DEAgBBAUAAAAAIwABGAAAAAAAAQAAAAAAAAAAAAMkAAAAAAQAAAECAC6jAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQESBQAAAE0BAZ4GAAAAnwACAqQBCAAAAHBAbwMJALwBARYKAAAAnwEDAuICEQDAAxIAEgAAABIAAQAwAwIhCwAAAMADEwAwAwJ2DAAAAMADFAASAAAAMAMCqw0AAADAAxUAMAMCmw4AAADAAxYAMAMCOg8AAADiAx8AMAMCaRAAAADAAyAAEgACABIAAACCAwIAIQMRBAAAAEADEgQAACBAAxMDFAMVAxYEAABwQAMXAxgDAwMFAwcDCAMKAxkFBgsMDQ4PEAYABgEGAgYDBgQDGgMbAxwDHQMeAx8DIAMhCAQXGAAAABkaAAAAGxwAAAAdHgAAAAYFBgABAgMEBQEAARgAAAAAAAAAAAAAAAAAAAEAAAAAAAIBAAAAAAYAAAQAAAAEAAAEAAAEAAAIAAAAAQAAAAAGcTi96vLLRMej/bhM9m+kMQEgqp5D/Nfr

-- decompilation:
local Util = require(script.Parent.Parent.Shared.Util)
local Players = game:GetService("Players")
local t1 = {
	Transform = function(p1) -- line: 5
		-- upvalues: Util (copy), Players (copy)
		return Util.MakeFuzzyFinder(Players:GetPlayers())(p1)
	end,
	Validate = function(p2) -- line: 11
		return #p2 > 0.0, "No player with that name could be found."
	end,
	Autocomplete = function(p3) -- line: 15
		-- upvalues: Util (copy)
		return Util.GetNames(p3)
	end,
	Parse = function(p4) -- line: 19
		return p4[1.0]
	end,
	Default = function(p5) -- line: 23
		return p5.Name
	end,
	ArgumentOperatorAliases = {
		me = ".",
		all = "*",
		others = "**",
		random = "?"
	}
}

return function(p6) -- line: 35
	-- upvalues: t1 (copy), Util (copy)
	p6:RegisterType("player", t1)
	p6:RegisterType("players", Util.MakeListableType(t1, {
		Prefixes = "% teamPlayers"
	}))
end

