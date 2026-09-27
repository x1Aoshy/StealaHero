-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24ccmJ4YXNzZXRpZDovLzEzNDEyMzQxNzk4NDExMA9TcGVlZE11bHRpcGxpZXINRGlzcGxheUluU2hvcAtEaXNwbGF5TmFtZQ1FdGVybmFsIFRyYWlsCFJhcml0aWVzB0V0ZXJuYWwAAQUAAAECACOjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHhBQAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAiQEAAAATQIC8gYAAACfAQICUgIAAOIDEwBNBAHoFAAAAE0EBCYVAAAAMAQD8gYAAACfAgIAggIAABYDAQQAAABAAwIEAAAgQAMDAwQDBQMGAgAAkB7EvKZCAwcCAABg4Jfo6kEDCAMJAwoCAAAAAAAAJEADCwEBAwwDDQgHBwgAAAAJCgAAAAsMAAAABv////8NDgAAAA8QAAAAERIAAAADDgMPAAEAARgAAwAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAgAEAAAAAAD8AAEAAAAAANP1xzVADArsEsFwIXVWmvSj7dBB4TGtNA==

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 1600000000000.0, -- ECON 2026-09-24 (money /125): was 200000000000000.0; BALANCE 2026-09-23 (owner approved): was 12500000000000.0
	ProductId = 3611606787.0,
	Icon = "rbxassetid://134123417984110",
	SpeedMultiplier = 2.25, -- BALANCE 2026-09-23 (owner approved): was 10.0
	DisplayInShop = true,
	DisplayName = "Eternal Trail",
	Effect = "Void Shadow", -- TRAILS 2026-09-24 (visual only): themed FX Assets.TrailFx.EternalTrail
	Rarity = Rarity.Rarities.Eternal
})

