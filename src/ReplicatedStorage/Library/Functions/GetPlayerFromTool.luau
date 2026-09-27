-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMNBFRvb2wGUGFyZW50BlBsYXllcgNJc0EFTW9kZWwWR2V0UGxheWVyRnJvbUNoYXJhY3RlcgRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHUGxheWVycwdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwACBQECAAAGAwAABQEHHfsBAABNAQFOAAAAAFICAACfAQIBTQEAJAEAAAArAQIAxgIAAIICAgBvBAIAvAIB/gMAAACfAgMCDgIBAIIBAgBvBAQAvAIB/gMAAACfAgMCDgIGAPsCAQBSBAEAvAICiQUAAACfAgMAggIAAMYCAACCAgIABgMBAwIDAwMEAwUDBgALAAEYAAAAAAACAAEBAAIAAAAAAQIAAAAAAQAAAAAAAgAMAAAAAAQAAAECABijAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIGAAAAUEBNAwBqBwAAAE0DA4kIAAAAnwICAsADCQASAAIAEgABAIIDAgAKAwcEAAAAQAMIAwkDCgMLBAAAUEADDAMNBgABAAEAARgAAwAAAAAAAQAAAAAAAwAAAAAAAAMAAAABAAAAAAET1Z38AZAGJlnqY9TIvXGIY82KiCER9/0=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(p1) -- line: 11
	-- upvalues: Asserts (copy), Players (copy)
	Asserts.Tool(p1)

	local p1Parent = p1.Parent

	if not p1Parent then
		return nil
	end

	if p1Parent:IsA("Player") then
		return p1Parent
	end

	if p1Parent:IsA("Model") then
		return Players:GetPlayerFromCharacter(p1Parent)
	end

	return nil
end

