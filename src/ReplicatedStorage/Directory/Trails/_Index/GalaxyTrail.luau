-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24ccmJ4YXNzZXRpZDovLzEwMjg5NjY2NDQ1MzE4OQ9TcGVlZE11bHRpcGxpZXINRGlzcGxheUluU2hvcAtEaXNwbGF5TmFtZQxHYWxheHkgVHJhaWwIUmFyaXRpZXMGQ29zbWljAAEFAAABAgAjowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB4QUAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIkBAAAAE0CAvIGAAAAnwECAlICAADiAxMATQQB6BQAAABNBAQFFQAAADAEA/IGAAAAnwICAIICAAAWAwEEAAAAQAMCBAAAIEADAwMEAwUDBgIAAAAgX6ASQgMHAgAAoN6X6OpBAwgDCQMKAgAAAAAAABRAAwsBAQMMAw0IBwcIAAAACQoAAAALDAAAAAb/////DQ4AAAAPEAAAABESAAAAAw4DDwABAAEYAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAIABAAAAAAA/AABAAAAAABa+JBXKBjByelq/q/KEk8CKuCHI2g8+lY=

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 16000000000.0, -- ECON 2026-09-24 (money /125): was 2000000000000.0; BALANCE 2026-09-23 (owner approved): was 20000000000.0
	ProductId = 3611606773.0,
	Icon = "rbxassetid://102896664453189",
	SpeedMultiplier = 1.8, -- BALANCE 2026-09-23 (owner approved): was 5.0
	DisplayInShop = true,
	DisplayName = "Galaxy Trail",
	Effect = "Cosmic Galaxy", -- TRAILS 2026-09-24 (visual only): themed FX Assets.TrailFx.GalaxyTrail
	Rarity = Rarity.Rarities.Cosmic
})

