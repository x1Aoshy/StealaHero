-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24ccmJ4YXNzZXRpZDovLzEwNDExMzk1MjExMjAzMw9TcGVlZE11bHRpcGxpZXINRGlzcGxheUluU2hvcAtEaXNwbGF5TmFtZRNDZWxlYnJpdHkgVHJlYWRtaWxsCFJhcml0aWVzBEVwaWMAAQUAAAECACOjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHhBQAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAiQEAAAATQIC8gYAAACfAQICUgIAAOIDEwBNBAHoFAAAAE0EBLwVAAAAMAQD8gYAAACfAgIAggIAABYDAQQAAABAAwIEAAAgQAMDAwQDBQMGAgAAAADQElNBAwcCAAAA1Jfo6kEDCAMJAwoCAAAAAAAAPkADCwEBAwwDDQgHBwgAAAAJCgAAAAsMAAAABv////8NDgAAAA8QAAAAERIAAAADDgMPAAEAARgAAwAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAgAEAAAAAAD8AAEAAAAAAIzb0n62SHucfHdSCk2aCer8w8UKvh+4fw==

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 60000000.0, -- ECON 2026-09-24 (money /125): was 7500000000.0; BALANCE 2026-09-23 (owner approved): was 5000000.0
	ProductId = 3611606688.0,
	Icon = "rbxassetid://104113952112033",
	SpeedMultiplier = 30.0, -- BALANCE 2026-09-23 (owner approved): the MODDED x3 reverted (was 90.0)
	DisplayInShop = true,
	DisplayName = "Celebrity Treadmill",
	Rarity = Rarity.Rarities.Epic
})

