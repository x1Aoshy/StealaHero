-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQHUHJpdmF0ZQtCYXNlQ29uZmlncwdTeXN0ZW1zDEZvcm1hdFJhcml0eQdEZWZhdWx0BE5hbWUGQXNzZXRzAlVJBlJhcml0eQtEaXNwbGF5TmFtZQdFdGVybmFsDFJhcml0eU51bWJlchJEZWZhdWx0UmFyaXR5VmFsdWUQMSBpbiAxMDAsMDAwLDAwMAhJdGVtU2xvdAhHcmFkaWVudAVDb2xvcgdNZXNzYWdlCEFubm91bmNlBkNvbG9yMwdmcm9tUkdCAAEJAAABAgA8owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBApAIHAAAAYEBNAgIkCAAAAE0CAiQIAAAATQICDAkAAABNAgI6CgAAAE0CAiYLAAAATQICOAwAAABNAgI6DQAAAJ8BAgKkAgcAAABgQE0CAroOAAAATQQAgQ8AAABNBARcEAAAAE0EBPIRAAAAhwMEAuIEHgBNBQOJGAAAADAFBIkYAAAATQUDPRkAAAAwBQQ9GQAAAKQFIQAAgPCBjAb/AIwHHgCMCPAAnwUEAjAFBKQaAAAAUgUBAG8GFwCfBQICMAUE+BsAAACCBAIAIgMBBAAAAEADAgMDAwQEAABAQAMFBAAAYEADBgMHAwgDCQMKAwsDDAMNAw4DDwMQAxEDEgIAAAAAAAAiQAMTAxQDFQMWAxcDGAMZAQAICBITAAAAFBUAAAAWFwAAABj/////Gf////8a/////xv/////HB0AAAADGgMbBACA8IEAAQABGAABAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAAwAAAAIAAAAAAAADBQAAAAEAAAABAAAAAAAAAAIAAAAAAAEAAAAAALcP01PIKE4+M/WScp8WnabHF8Qnhcu5Ug==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Default = require(script.Parent.Parent.Private.BaseConfigs.Systems.FormatRarity.Default)
local scriptName = script.Name
local v4 = ReplicatedStorage.Assets.UI.Rarity[scriptName]

return {
	DisplayName = "Eternal",
	RarityNumber = 9.0,
	DefaultRarityValue = "1 in 100,000,000",
	Announce = false,
	ItemSlot = v4.ItemSlot,
	Gradient = v4.Gradient,
	Color = Color3.fromRGB(255.0, 30.0, 240.0),
	Message = Default("1 in 100,000,000")
}

