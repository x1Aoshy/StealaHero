-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQHUHJpdmF0ZQtCYXNlQ29uZmlncwdTeXN0ZW1zDEZvcm1hdFJhcml0eQdEZWZhdWx0BE5hbWUGQXNzZXRzAlVJBlJhcml0eQtEaXNwbGF5TmFtZQxSYXJpdHlOdW1iZXISRGVmYXVsdFJhcml0eVZhbHVlBjEgaW4gMghJdGVtU2xvdAhHcmFkaWVudAVDb2xvcgdNZXNzYWdlCEFubm91bmNlBkNvbG9yMwdmcm9tUkdCAAEJAAABAgBCowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBApAIHAAAAYEBNAgIkCAAAAE0CAiQIAAAATQICDAkAAABNAgI6CgAAAE0CAiYLAAAATQICOAwAAABNAgI6DQAAAJ8BAgKkAgcAAABgQE0CAroOAAAATQQAgQ8AAABNBARcEAAAAE0EBPIRAAAAhwMEAuIEHQCkBQcAAABgQE0FBboOAAAAMAUEVxIAAABNBQOJFwAAADAFBIkXAAAATQUDPRgAAAAwBQQ9GAAAAKQFIAAAfOCBjAYAAIwH/wCMCAAAnwUEAjAFBKQZAAAAUgUBAG8GFgCfBQICMAUE+BoAAACCBAIAIQMBBAAAAEADAgMDAwQEAABAQAMFBAAAYEADBgMHAwgDCQMKAwsDDAMNAw4DDwMQAxECAAAAAAAAAEADEgMTAxQDFQMWAxcDGAEACAgS/////xMUAAAAFRYAAAAX/////xj/////Gf////8a/////xscAAAAAxkDGgQAfOCBAAEAARgAAQAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAMAAAACAAAAAAAAAwEAAAAAAAQAAAABAAAAAQAAAAAAAAACAAAAAAABAAAAAAAxG+2UzOUtjsvMGzh3vLXkQQP64APfh5U=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Default = require(script.Parent.Parent.Private.BaseConfigs.Systems.FormatRarity.Default)
local scriptName = script.Name
local v4 = ReplicatedStorage.Assets.UI.Rarity[scriptName]

return {
	RarityNumber = 2.0,
	DefaultRarityValue = "1 in 2",
	Announce = false,
	DisplayName = script.Name,
	ItemSlot = v4.ItemSlot,
	Gradient = v4.Gradient,
	Color = Color3.fromRGB(0.0, 255.0, 0.0),
	Message = Default("1 in 2")
}

