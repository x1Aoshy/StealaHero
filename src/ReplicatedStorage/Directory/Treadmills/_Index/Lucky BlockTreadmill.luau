-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24ccmJ4YXNzZXRpZDovLzEzNDI1NTExNTQ3MTU4Mg9TcGVlZE11bHRpcGxpZXINRGlzcGxheUluU2hvcAtEaXNwbGF5TmFtZRVMdWNreSBCbG9jayBUcmVhZG1pbGwIUmFyaXRpZXMGQ29zbWljAAEFAAABAgAjowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB4QUAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIkBAAAAE0CAvIGAAAAnwECAlICAADiAxMATQQB6BQAAABNBAQFFQAAADAEA/IGAAAAnwICAIICAAAWAwEEAAAAQAMCBAAAIEADAwMEAwUDBgIAAAAuWXYxQgMHAgAAQNaX6OpBAwgDCQMKAgAAAAAAAGlAAwsBAQMMAw0IBwcIAAAACQoAAAALDAAAAAb/////DQ4AAAAPEAAAABESAAAAAw4DDwABAAEYAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAIABAAAAAAA/AABAAAAAAAFjjcSn4C0dKQ+eByWVB6VdZYgZjdKXRM=

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 8000000000.0, -- ECON 2026-09-24 (money /125): was 1000000000000.0; BALANCE 2026-09-23 (owner approved): was 75000000000.0
	ProductId = 3611606706.0,
	Icon = "rbxassetid://134255115471582",
	SpeedMultiplier = 320.0, -- BALANCE 2026-09-23 (owner approved): the MODDED x3 reverted (was 600.0)
	DisplayInShop = true,
	DisplayName = "Lucky Block Treadmill",
	Rarity = Rarity.Rarities.Cosmic
})

