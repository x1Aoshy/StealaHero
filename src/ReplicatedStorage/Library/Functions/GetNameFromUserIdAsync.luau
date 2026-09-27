-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMREUdldFBsYXllckJ5VXNlcklkBE5hbWUWR2V0TmFtZUZyb21Vc2VySWRBc3luYwR0eXBlBnN0cmluZwZhc3NlcnQDZ2V0BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdQbGF5ZXJzB0xpYnJhcnkMV2FpdEZvckNoaWxkB01vZHVsZXMHcmVxdWlyZQpTbWFydENhY2hlA25ldwADBwEBAAAGAwAABQECLvsBAABSAwAAvAEBYQAAAACfAQMCDgEEAKkCAQBNAwG6AQAAAIICAwD7AgAAUgQAALwCAvQCAAAAnwIDArsoAgNSBgIApAUEAAAAMECfBQIC8AUCAAUAAACpBAABqQQBALsBBAKkAwcAAABgQJ8DAgGpBAAAHAUCAIwGAABgBgcABQAAABwFAgCMBhQA1AUCAAYAAACpBAABqQQBALsBBAKkAwcAAABgQJ8DAgGpAwEAUgQCAIIDAwAIAwEDAgMDAwQEAAAwQAMFAwYEAABgQAAGAAEYAAAAAAABAQAAAAMAAAAAAQAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAEAAAcAAAAABQEBAAAGAwAABQECDvsBAABNAQFfAAAAAFICAADGAwAAqQQBAJ8BBAIrAQUA+wEAAE0BAV8AAAAAUgIAAJ8BAgKCAQIAAQMHABIAARgAAAAAAAAAAAAAAAAAABMAAAAACAAAAQIAJaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwJvBAUAvAIA0wYAAACfAgMCbwQHALwCAtMGAAAAnwIDAqQDCQAAAIBATQQCOQoAAACfAwICTQMD7wsAAACMBA8AjAUQDowGPADABwwAEgABAJ8DBQLABA0AEgADAIIEAgAOAwgEAAAAQAMJAwoDCwMMAw0DDgMPBAAAgEADEAMRBgAGAQIAAQEAARgAAAAAAAAAAQAAAAAAAgAAAAAAAAACAAAAAAAAAAAAAAAADAAAAQAAAAACBVBn4jlvGgzFB/InfEpfZXVIcJY3lA3j

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = ReplicatedStorage:WaitForChild("Library"):WaitForChild("Modules")
local v4 = require(Modules.SmartCache).new(15.0, 3600.0, 60.0, function(n1: number) -- line: 6
	-- upvalues: Players (copy)
	local PlayerByUserId = Players:GetPlayerByUserId(n1)

	if PlayerByUserId then
		return true, PlayerByUserId.Name
	end

	local NameFromUserIdAsync = Players:GetNameFromUserIdAsync(n1)

	assert(type(NameFromUserIdAsync) == "string")
	assert(#NameFromUserIdAsync > 0.0 and #NameFromUserIdAsync <= 20.0)

	return true, NameFromUserIdAsync
end)

return function(n2: number) -- line: 18
	-- upvalues: v4 (copy)
	return v4.get(n2, nil, true) or v4.get(n2)
end

