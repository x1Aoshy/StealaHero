-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQFVHlwZXMJSW50ZXJmYWNlCURpcmVjdG9yeQZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24AD1NwZWVkTXVsdGlwbGllcg1EaXNwbGF5SW5TaG9wC0Rpc3BsYXlOYW1lCFJhcml0aWVzBkNvbW1vbgABBQAAAQIAI6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQKQCBwAAAGBATQICJAgAAABNAgIkCAAAAE0CAu8JAAAATQICDwoAAACfAQICpAIFAAAAQEBNAwCRCwAAAE0DA/IMAAAAnwICAuIDFwBNBALoGAAAAE0EBHMZAAAAMAQD8gwAAACCAwIAGgMBBAAAAEADAgMDAwQEAABAQAMFBAAAYEADBgMHAwgDCQMKAwsCAAAAAAAAAAADDAADDQMOAw8DEAEBAxEIBw0OAAAADxAAAAAREgAAAAz/////Ew4AAAAUFQAAABYSAAAAAxIDEwABAAEYAAMAAAAAAAMAAAAAAAAAAAAAAAABAAAAAAAAAgQAAAAAAAABAAAAAADNFHjUs4oURA7RYbSjhh1tvQxvoP/QEtU=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(script.Parent.Parent.Types.Interface)

local Rarity = require(ReplicatedStorage.Directory.Rarity)

return {
	Price = 0.0,
	ProductId = nil,
	Icon = "",
	SpeedMultiplier = 0.0,
	DisplayInShop = true,
	DisplayName = "",
	Rarity = Rarity.Rarities.Common
}

