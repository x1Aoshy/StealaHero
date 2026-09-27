-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24ccmJ4YXNzZXRpZDovLzEzNjU4OTI5OTc3Mjk2NQ9TcGVlZE11bHRpcGxpZXINRGlzcGxheUluU2hvcAtEaXNwbGF5TmFtZRRUaGUgRnJlZXplIFRyZWFkbWlsbAhSYXJpdGllcwZNeXRoaWMAAQUAAAECACOjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHhBQAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAiQEAAAATQIC8gYAAACfAQICUgIAAOIDEwBNBAHoFAAAAE0EBKQVAAAAMAQD8gYAAACfAgIAggIAABYDAQQAAABAAwIEAAAgQAMDAwQDBQMGAgAAAMALWuZBAwcCAACg1Zfo6kEDCAMJAwoCAAAAAAAAWUADCwEBAwwDDQgHBwgAAAAJCgAAAAsMAAAABv////8NDgAAAA8QAAAAERIAAAADDgMPAAEAARgAAwAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAgAEAAAAAAD8AAEAAAAAAMcZ1LxE+cYmajddnOmRjKa3AcPI9d2+vQ==

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 1000000000.0, -- ECON 2026-09-24 (money /125): was 120000000000.0; BALANCE 2026-09-23 (owner approved): was 3000000000.0
	ProductId = 3611606701.0,
	Icon = "rbxassetid://136589299772965",
	SpeedMultiplier = 160.0, -- BALANCE 2026-09-23 (owner approved): the MODDED x3 reverted (was 300.0)
	DisplayInShop = true,
	DisplayName = "The Freeze Treadmill",
	Rarity = Rarity.Rarities.Mythic
})

