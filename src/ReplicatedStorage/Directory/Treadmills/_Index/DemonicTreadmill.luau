-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24ccmJ4YXNzZXRpZDovLzExOTI2MjMwMjQ2MzAyMg9TcGVlZE11bHRpcGxpZXINRGlzcGxheUluU2hvcAtEaXNwbGF5TmFtZRFEZW1vbmljIFRyZWFkbWlsbAhSYXJpdGllcwdFdGVybmFsAAEFAAABAgAjowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB4QUAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIkBAAAAE0CAvIGAAAAnwECAlICAADiAxMATQQB6BQAAABNBAQmFQAAADAEA/IGAAAAnwICAIICAAAWAwEEAAAAQAMCBAAAIEADAwMEAwUDBgIAAJAexLzGQgMHAgAAANmX6OpBAwgDCQMKAgAAAAAAQI9AAwsBAQMMAw0IBwcIAAAACQoAAAALDAAAAAb/////DQ4AAAAPEAAAABESAAAAAw4DDwABAAEYAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAIABAAAAAAA/AABAAAAAADIfxjBRBQRa0laRDHpzDABuGcPtfq7csA=

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 800000000000.0, -- ECON 2026-09-24 (money /125): was 100000000000000.0; BALANCE 2026-09-23 (owner approved): was 50000000000000.0
	ProductId = 3611606728.0,
	Icon = "rbxassetid://119262302463022",
	SpeedMultiplier = 1280.0, -- BALANCE 2026-09-23 (owner approved): the MODDED x3 reverted (was 3000.0)
	DisplayInShop = true,
	DisplayName = "Demonic Treadmill",
	Rarity = Rarity.Rarities.Eternal
})

