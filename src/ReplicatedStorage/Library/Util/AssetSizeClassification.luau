-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMiBm51bWJlcgZpcGFpcnMMTWluaW11bVNjYWxlB1Jlc29sdmUHQXRUcmFjZStSZWFkIHNoYXJlZCBhc3NldCBzaXplIGNsYXNzaWZpY2F0aW9uIHRpZXJzA0xvZwhHZXRUaWVycwRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMFVHlwZXMXQXNzZXRTaXplQ2xhc3NpZmljYXRpb24HTW9kdWxlcwhQYWNrYWdlcwV0YWJsZQZmcmVlemUGUHJlZml4CkdBUkdBTlRVQU4FQ29sb3IIUmljaFRleHQnPGZvbnQgY29sb3I9IiNGRkQ3MDAiPkdBUkdBTlRVQU48L2ZvbnQ+BkNvbG9yMwdmcm9tUkdCB1RJVEFOSUMkPGZvbnQgY29sb3I9IiM5QjUxRTAiPlRJVEFOSUM8L2ZvbnQ+BEhVR0UhPGZvbnQgY29sb3I9IiMyRjgwRUQiPkhVR0U8L2ZvbnQ+A0JJRyA8Zm9udCBjb2xvcj0iIzM0Qzc1OSI+QklHPC9mb250PgNuZXcAAwcBAgAABgMAAAUBAhP7AQAATQEBYAAAAABSAgAAnwECAaQBAgAAABBA+wIBAJ8BAgRRAQUATQYFKQMAAAB9BgIAAAAAAIIFAgBuAfr/AgAAgMYBAACCAQIABAMBAwIEAAAQQAMDADQEARgAAAAAAAEAAAAAAQAAAAH+AAYANQAAAAADAAIAAAAK+wAAALwAAKoAAAAAnwACAm8CAQC8AAChAgAAAJ8AAwH7AAEAggACAAMDBQMGAwcAPwgBGAAAAAAAAAAAAQBAAAAAAA4AAAECAF2jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAokHAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwPvCAAAAE0DA50JAAAAnwICAqQDBQAAAEBATQQAagYAAABNBAToCgAAAE0EBOYLAAAATQQEoQwAAACfAwICpAQPAAA40ID/BQAABAAAAOIGFwCkBxoAAGSAgYwI/wCMCdcAjAoAAJ8HBAIwBwakFAAAAOIHHgCkCBoAAGSAgYwJmwCMClEAjAvgAJ8IBAIwCAekFAAAAOIIIgCkCRoAAGSAgYwKLwCMC4AAjAztAJ8JBAIwCQikFAAAAOIJJgCkChoAAGSAgYwLNACMDMcAjA1ZAJ8KBAIwCgmkFAAAAMUFBgUBAAAAnwQCAk0FA+8nAAAAnwUBAv8GAgAAAAAAwAcoABIAAQASAAQAMAcG/SkAAADAByoAEgAFABIABAAwBwb1KwAAAIIGAgAsAwkEAAAAQAMKAwsDDAQAAEBAAw0DDgMPAxADEQMSAwcDEwMUBAA40IADAwIAAAAAAIBGQAMVAxYDFwMYAxkIBBARAAAAEhMAAAAU/////xUWAAAAAxoDGwQAZICBAgAAAAAAADlAAxwDHQgEEBsAAAASHAAAABT/////FR0AAAACAAAAAAAAJEADHgMfCAQQHwAAABIgAAAAFP////8VIQAAAAIAAAAAAAAUQAMgAyEIBBAjAAAAEiQAAAAU/////xUlAAAAAyIGAAMEBgEDCAIAAQEAARgAAwAAAAAAAwAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAAABgAAAAEDAAAAAAAAAAMDAAAAAAAAAAMDAAAAAAAAAAMDAAAAAAAAAAAA6hwAAAMABgAAAAALAAAAAAUBAAAAAAJXSauLI3+PTGsAgQVMv21/J1G8/2WNwYo=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

require(ReplicatedStorage.Library.Types.AssetSizeClassification)

local Log = require(ReplicatedStorage.Library.Modules.Packages.Log)
local v4 = table.freeze({
	{
		MinimumScale = 45.0,
		Prefix = "GARGANTUAN",
		RichText = "<font color=\"#FFD700\">GARGANTUAN</font>",
		Color = Color3.fromRGB(255.0, 215.0, 0.0)
	},
	{
		MinimumScale = 25.0,
		Prefix = "TITANIC",
		RichText = "<font color=\"#9B51E0\">TITANIC</font>",
		Color = Color3.fromRGB(155.0, 81.0, 224.0)
	},
	{
		MinimumScale = 10.0,
		Prefix = "HUGE",
		RichText = "<font color=\"#2F80ED\">HUGE</font>",
		Color = Color3.fromRGB(47.0, 128.0, 237.0)
	},
	{
		MinimumScale = 5.0,
		Prefix = "BIG",
		RichText = "<font color=\"#34C759\">BIG</font>",
		Color = Color3.fromRGB(52.0, 199.0, 89.0)
	}
})
local v5 = Log.new()

return {
	Resolve = function(n1: number) -- line: 52
		-- upvalues: Asserts (copy), v4 (copy)
		Asserts.number(n1)

		for _, v in ipairs(v4) do
			if n1 >= v.MinimumScale then
				return v
			end
		end

		return nil
	end,
	GetTiers = function() -- line: 63
		-- upvalues: v5 (copy), v4 (copy)
		v5:AtTrace():Log("Read shared asset size classification tiers")

		return v4
	end
}

