-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBnN0cmluZwdSZXNvbHZlBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwtBYnlzcyBPY2VhbgZDb3NtaWMLUHJlaGlzdG9yaWMAAgQBAgAABgMAAAUBAwn7AQAATQEBQQAAAABSAgAAnwECAfsDAQCHAgMAkAECAYIBAgACAwECAAAAAAAACEAAGAIBGAAAAAAAAgAAABkAAAAABQAAAQIAIaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQIC/wIDAAAAAACMAw8AMAMCYAgAAACMAw8AMAMCBQkAAACMAw8AMAMC5woAAAD/AwEAAAAAAMAECwASAAEAEgACADAEA/0MAAAAggMCAA0DAwQAAABAAwQDBQMGBAAAQEADBwMIAwkDCgMLBgADAgEAAQABGAADAAAAAAADAAAAAAAABAABAAABAAABAAAEAAYAAAAABgEAAAAAAeKP97/w5NRrIpFYGAVF2wqSl+DL0Eudvg==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local t1 = {
	["Abyss Ocean"] = 15.0,
	Cosmic = 15.0,
	Prehistoric = 15.0
}

return {
	Resolve = function(s1: string) -- line: 24
		-- upvalues: Asserts (copy), t1 (copy)
		Asserts.string(s1)

		return t1[s1] or 3.0
	end
}

