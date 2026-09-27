-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24ccmJ4YXNzZXRpZDovLzEwNjExMjQ3NzEyMjg2Mw9TcGVlZE11bHRpcGxpZXINRGlzcGxheUluU2hvcAtEaXNwbGF5TmFtZQxHb2xkZW4gVHJhaWwIUmFyaXRpZXMJTGVnZW5kYXJ5AAEFAAABAgAjowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB4QUAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIkBAAAAE0CAvIGAAAAnwECAlICAADiAxMATQQB6BQAAABNBAS5FQAAADAEA/IGAAAAnwICAIICAAAWAwEEAAAAQAMCBAAAIEADAwMEAwUDBgIAAAAAOJx8QQMHAgAAgN2X6OpBAwgDCQMKAgAAAAAAAAxAAwsBAQMMAw0IBwcIAAAACQoAAAALDAAAAAb/////DQ4AAAAPEAAAABESAAAAAw4DDwABAAEYAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAIABAAAAAAA/AABAAAAAADr3iR+b6ipnOuI3Uvla5Atm8YzCtkaTn8=

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 600000000.0, -- ECON 2026-09-24 (money /125): was 75000000000.0; BALANCE 2026-09-23 (owner approved): was 30000000.0
	ProductId = 3611606764.0,
	Icon = "rbxassetid://106112477122863",
	SpeedMultiplier = 1.5, -- BALANCE 2026-09-23 (owner approved): was 3.5
	DisplayInShop = true,
	DisplayName = "Golden Trail",
	Effect = "Golden Energy", -- TRAILS 2026-09-24 (visual only): themed FX Assets.TrailFx.GoldenTrail
	Rarity = Rarity.Rarities.Legendary
})

