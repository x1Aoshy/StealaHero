-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24ccmJ4YXNzZXRpZDovLzEyOTg3NjgwOTM3MDIzNA9TcGVlZE11bHRpcGxpZXINRGlzcGxheUluU2hvcAtEaXNwbGF5TmFtZQxTZWNyZXQgVHJhaWwIUmFyaXRpZXMGU2VjcmV0AAEFAAABAgAjowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB4QUAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIkBAAAAE0CAvIGAAAAnwECAlICAADiAxMATQQB6BQAAABNBARnFQAAADAEA/IGAAAAnwICAIICAAAWAwEEAAAAQAMCBAAAIEADAwMEAwUDBgIAAACilBpdQgMHAgAAAOCX6OpBAwgDCQMKAgAAAAAAABxAAwsBAQMMAw0IBwcIAAAACQoAAAALDAAAAAb/////DQ4AAAAPEAAAABESAAAAAw4DDwABAAEYAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAIABAAAAAAA/AABAAAAAAAQSTLoWk4BDppvD5Tmbv5PYFElnCKNWOk=

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 160000000000.0, -- ECON 2026-09-24 (money /125): was 20000000000000.0; BALANCE 2026-09-23 (owner approved): was 500000000000.0
	ProductId = 3611606784.0,
	Icon = "rbxassetid://129876809370234",
	SpeedMultiplier = 2.0, -- BALANCE 2026-09-23 (owner approved): was 7.0
	DisplayInShop = true,
	DisplayName = "Secret Trail",
	Effect = "Storm Lightning", -- TRAILS 2026-09-24 (visual only): themed FX Assets.TrailFx.SecretTrail
	Rarity = Rarity.Rarities.Secret
})

