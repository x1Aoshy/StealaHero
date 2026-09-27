-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaD01ha2VGdXp6eUZpbmRlcghHZXRUZWFtcwlUcmFuc2Zvcm0mTm8gdGVhbSB3aXRoIHRoYXQgbmFtZSBjb3VsZCBiZSBmb3VuZC4IVmFsaWRhdGUIR2V0TmFtZXMMQXV0b2NvbXBsZXRlBVBhcnNlCkdldFBsYXllcnMJVGVhbUNvbG9yBHRlYW0MUmVnaXN0ZXJUeXBlBXRlYW1zEE1ha2VMaXN0YWJsZVR5cGULdGVhbVBsYXllcnMJdGVhbUNvbG9yCnRlYW1Db2xvcnMEZ2FtZQVUZWFtcwpHZXRTZXJ2aWNlB3JlcXVpcmUGc2NyaXB0BlBhcmVudAZTaGFyZWQEVXRpbAhMaXN0YWJsZQAIBAECAAAADPsBAABNAQE9AAAAAPsCAQC8AgIxAQAAAJ8CAgCfAQACUgIBAFIDAACfAgIAggIAAAIDAQMCAAUDARgAAAAAAAAAAAIAAAAGAAAAAAQBAAAAAAgcAgAAjAMAALcDAgACAAAAqQEAAakBAQBvAgAAggEDAAEDBAALBQEYAAAAAAAAAAAMAAAAAAMBAQAAAAb7AQAATQEBxwAAAABSAgAAnwECAIIBAAABAwYADwcBGAAAAAAAABAAAAAAAgEAAAAAAhMBAACCAQIAAAATCAEYAAAUAAAAAAMBAAAAAAUTAQAAvAEBqwAAAACfAQIAggEAAAEDCQAeCAEYAAAAAAAfAAAAAAIBAAAAAAQTAQAATQEB2wAAAACCAQIAAQMKACgIARgAAAAAKQAAAAAGAQQAAAAibwMAAPsEAAC8AQDdAQAAAJ8BBAFvAwIA+wQBAE0EBCQDAAAA+wUAAJ8EAgC8AQDdAQAAAJ8BAAFvAwQA+wQCALwBAN0BAAAAnwEEAW8DBQD7BAMAvAEA3QEAAACfAQQBbwMGAPsEAQBNBAQkAwAAAPsFAwCfBAIAvAEA3QEAAACfAQABggABAAcDCwMMAw0DDgMPAxADEQAtAAEYAAAAAAABAAAAAAAAAAACAAAAAAIAAAAAAQAAAAAAAAAAAS4AAAAABgAAAQIASqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQKQCBwAAAGBATQICJAgAAABNAgIkCAAAAE0CAhIJAAAATQICngoAAACfAQIC4gIPAMADEAASAAEAEgAAADADAiELAAAAwAMRADADAnYMAAAAwAMSABIAAQAwAwKrDQAAAMADEwAwAwKbDgAAAOIDFgBNBAIhCwAAADAEAyELAAAATQQCdgwAAAAwBAN2DAAAAE0EAqsNAAAAMAQDqw0AAADABBcAMAQDmw4AAADiBA8ATQUCIQsAAAAwBQQhCwAAAE0FAnYMAAAAMAUEdgwAAABNBQKrDQAAADAFBKsNAAAAwAUYADAFBJsOAAAAwAUZABIAAgASAAEAEgADABIABACCBQIAGgMSBAAAAEADEwMUAxUEAABAQAMWBAAAYEADFwMYAxkDAwMFAwcDCAUECwwNDgYABgEGAgYDAxoBAQgFFBUAAAAL/////wz/////Df////8O/////wYEBgUGBgcAAQIDBAUGAQABGAAAAAAAAAABAAAAAAAAAAAAAAAAAgEAAAAABgAABAAAAAQAAAUCAAAAAQAAAAEAAAACAAAFAQAAAAEAAAABAAAAAgAABQAAAAAAAQAAAAAHjaaWh1gKBPUhQ+l9ZVLlAf2+gfO/YvyG

-- decompilation:
local Teams = game:GetService("Teams")
local Util = require(script.Parent.Parent.Shared.Util)
local t1 = {
	Transform = function(p1) -- line: 5
		-- upvalues: Util (copy), Teams (copy)
		return Util.MakeFuzzyFinder(Teams:GetTeams())(p1)
	end,
	Validate = function(p2) -- line: 11
		return #p2 > 0.0, "No team with that name could be found."
	end,
	Autocomplete = function(p3) -- line: 15
		-- upvalues: Util (copy)
		return Util.GetNames(p3)
	end,
	Parse = function(p4) -- line: 19
		return p4[1.0]
	end
}
local t2 = {
	Listable = true,
	Transform = t1.Transform,
	Validate = t1.Validate,
	Autocomplete = t1.Autocomplete,
	Parse = function(p5) -- line: 30
		return p5[1.0]:GetPlayers()
	end
}
local t3 = {
	Transform = t1.Transform,
	Validate = t1.Validate,
	Autocomplete = t1.Autocomplete,
	Parse = function(p6) -- line: 40
		return p6[1.0].TeamColor
	end
}

return function(p7) -- line: 45
	-- upvalues: t1 (copy), Util (copy), t2 (copy), t3 (copy)
	p7:RegisterType("team", t1)
	p7:RegisterType("teams", Util.MakeListableType(t1))
	p7:RegisterType("teamPlayers", t2)
	p7:RegisterType("teamColor", t3)
	p7:RegisterType("teamColors", Util.MakeListableType(t3))
end

