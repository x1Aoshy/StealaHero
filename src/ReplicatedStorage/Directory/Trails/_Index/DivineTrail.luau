-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24bcmJ4YXNzZXRpZDovLzkwNTk5ODg3ODk1MzcyD1NwZWVkTXVsdGlwbGllcg1EaXNwbGF5SW5TaG9wC0Rpc3BsYXlOYW1lDERpdmluZSBUcmFpbAhSYXJpdGllcwZEaXZpbmUAAQUAAAECACOjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHhBQAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAiQEAAAATQIC8gYAAACfAQICUgIAAOIDEwBNBAHoFAAAAE0EBMcVAAAAMAQD8gYAAACfAgIAggIAABYDAQQAAABAAwIEAAAgQAMDAwQDBQMGAgAA7BaTDfFCAwcCAADg4Jfo6kEDCAMJAwoCAAAAAAAALEADCwEBAwwDDQgHBwgAAAAJCgAAAAsMAAAABv////8NDgAAAA8QAAAAERIAAAADDgMPAAEAARgAAwAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAgAEAAAAAAD8AAEAAAAAACezjPX3GjZkZJPSZ56odttXq5uBFXfm9A==

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 16000000000000.0, -- ECON 2026-09-24 (money /125): was 2000000000000000.0; BALANCE 2026-09-23 (owner approved): was 300000000000000.0
	ProductId = 3611606791.0,
	Icon = "rbxassetid://90599887895372",
	SpeedMultiplier = 2.5, -- BALANCE 2026-09-23 (owner approved): was 14.0
	DisplayInShop = true,
	DisplayName = "Divine Trail",
	Effect = "Holy Light", -- TRAILS 2026-09-24 (visual only): themed FX Assets.TrailFx.DivineTrail
	Rarity = Rarity.Rarities.Divine
})

