-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCdWlsZENvbmZpZwZSYXJpdHkFUHJpY2UJUHJvZHVjdElkBEljb24ccmJ4YXNzZXRpZDovLzEyNDk2MzE1MTQ5NTcyMQ9TcGVlZE11bHRpcGxpZXINRGlzcGxheUluU2hvcAtEaXNwbGF5TmFtZRBTY2ktRmkgVHJlYWRtaWxsCFJhcml0aWVzCFVuY29tbW9uAAEFAAABAgAjowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB4QUAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIkBAAAAE0CAvIGAAAAnwECAlICAADiAxMATQQB6BQAAABNBASWFQAAADAEA/IGAAAAnwICAIICAAAWAwEEAAAAQAMCBAAAIEADAwMEAwUDBgIAAAAAAEzNQAMHAgAAYNGX6OpBAwgDCQMKAgAAAAAAABRAAwsBAQMMAw0IBwcIAAAACQoAAAALDAAAAAb/////DQ4AAAAPEAAAABESAAAAAw4DDwABAAEYAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAIABAAAAAAA/AABAAAAAACCIHwrgM9jX1GHY2PhtAOI8jhrX7DkFio=

-- decompilation:
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarity = require(script.Parent.Parent.Parent.Rarity)

return BuildConfig({
	Price = 1600000.0, -- ECON 2026-09-24 (money /125): was 200000000.0; BALANCE 2026-09-23 (owner approved): was 15000.0
	ProductId = 3611606667.0,
	Icon = "rbxassetid://124963151495721",
	SpeedMultiplier = 5.0, -- BALANCE 2026-09-23 (owner approved): the MODDED x3 reverted (was 15.0)
	DisplayInShop = true,
	DisplayName = "Sci-Fi Treadmill",
	Rarity = Rarity.Rarities.Uncommon
})

