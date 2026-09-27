-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24bcmJ4YXNzZXRpZDovLzg3MzAwNDI0NDg5MzkzD1NwZWVkTXVsdGlwbGllcg1EaXNwbGF5SW5TaG9wC0Rpc3BsYXlOYW1lEEhhY2tlciBUcmVhZG1pbGwIUmFyaXRpZXMGU2VjcmV0AAEFAAABAgAjowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB4QUAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIkBAAAAE0CAvIGAAAAnwECAlICAADiAxMATQQB6BQAAABNBARnFQAAADAEA/IGAAAAnwICAIICAAAWAwEEAAAAQAMCBAAAIEADAwMEAwUDBgIAAACilBp9QgMHAgAAwNeX6OpBAwgDCQMKAgAAAAAAQH9AAwsBAQMMAw0IBwcIAAAACQoAAAALDAAAAAb/////DQ4AAAAPEAAAABESAAAAAw4DDwABAAEYAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAIABAAAAAAA/AABAAAAAACmpHT56Ggz0X2IkA1pv1T61rxjjZRgHvg=

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 80000000000.0, -- ECON 2026-09-24 (money /125): was 10000000000000.0; BALANCE 2026-09-23 (owner approved): was 2000000000000.0
	ProductId = 3611606718.0,
	Icon = "rbxassetid://87300424489393",
	SpeedMultiplier = 640.0, -- BALANCE 2026-09-23 (owner approved): the MODDED x3 reverted (was 1500.0)
	DisplayInShop = true,
	DisplayName = "Hacker Treadmill",
	Rarity = Rarity.Rarities.Secret
})

