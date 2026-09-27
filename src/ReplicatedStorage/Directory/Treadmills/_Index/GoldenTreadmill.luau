-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24bcmJ4YXNzZXRpZDovLzg0MjU4NzcxODU4MTc0D1NwZWVkTXVsdGlwbGllcg1EaXNwbGF5SW5TaG9wC0Rpc3BsYXlOYW1lEEdvbGRlbiBUcmVhZG1pbGwIUmFyaXRpZXMJTGVnZW5kYXJ5AAEFAAABAgAjowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB4QUAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIkBAAAAE0CAvIGAAAAnwECAlICAADiAxMATQQB6BQAAABNBAS5FQAAADAEA/IGAAAAnwICAIICAAAWAwEEAAAAQAMCBAAAIEADAwMEAwUDBgIAAAAAOJycQQMHAgAAwNSX6OpBAwgDCQMKAgAAAAAAAFRAAwsBAQMMAw0IBwcIAAAACQoAAAALDAAAAAb/////DQ4AAAAPEAAAABESAAAAAw4DDwABAAEYAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAIABAAAAAAA/AABAAAAAACmLqIZGHRd+gLaGe8UjC3f1ja1bZTqyBg=

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 200000000.0, -- ECON 2026-09-24 (money /125): was 25000000000.0; BALANCE 2026-09-23 (owner approved): was 120000000.0
	ProductId = 3611606694.0,
	Icon = "rbxassetid://84258771858174",
	SpeedMultiplier = 80.0, -- BALANCE 2026-09-23 (owner approved): the MODDED x3 reverted (was 240.0)
	DisplayInShop = true,
	DisplayName = "Golden Treadmill",
	Rarity = Rarity.Rarities.Legendary
})

