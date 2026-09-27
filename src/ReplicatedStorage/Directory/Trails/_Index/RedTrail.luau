-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24ccmJ4YXNzZXRpZDovLzEyNjM5ODIwODg4MjkxOQ9TcGVlZE11bHRpcGxpZXINRGlzcGxheUluU2hvcAtEaXNwbGF5TmFtZQlSZWQgVHJhaWwIUmFyaXRpZXMGTXl0aGljAAEFAAABAgAjowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB4QUAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIkBAAAAE0CAvIGAAAAnwECAlICAADiAxMATQQB6BQAAABNBASkFQAAADAEA/IGAAAAnwICAIICAAAWAwEEAAAAQAMCBAAAIEADAwMEAwUDBgIAAADAC1rGQQMHAgAAAN6X6OpBAwgDCQMKAgAAAAAAABBAAwsBAQMMAw0IBwcIAAAACQoAAAALDAAAAAb/////DQ4AAAAPEAAAABESAAAAAw4DDwABAAEYAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAIABAAAAAAA/AABAAAAAADkD/UB1ResPXiMBh9Enf6QlBfiddbLnwA=

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 3200000000.0, -- ECON 2026-09-24 (money /125): was 400000000000.0; BALANCE 2026-09-23 (owner approved): was 750000000.0
	ProductId = 3611606768.0,
	Icon = "rbxassetid://126398208882919",
	SpeedMultiplier = 1.65, -- BALANCE 2026-09-23 (owner approved): was 4.0
	DisplayInShop = true,
	DisplayName = "Red Trail",
	Effect = "Inferno Flame", -- TRAILS 2026-09-24 (visual only): themed FX Assets.TrailFx.RedTrail
	Rarity = Rarity.Rarities.Mythic
})

