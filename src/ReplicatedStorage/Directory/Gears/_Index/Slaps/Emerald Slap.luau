-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2ULQmFzZUNvbmZpZ3MHRGVmYXVsdARJY29uHHJieGFzc2V0aWQ6Ly8xMjU0ODYwNzIxNzUwNzcLRGlzcGxheU5hbWUJTW9uZXlDb3N0DlNob3BEcm9wV2VpZ2h0FE1pblNob3BTdG9ja1F1YW50aXR5FE1heFNob3BTdG9ja1F1YW50aXR5DlRvb2xDb250cm9sbGVyBFNsYXAOQ29udHJvbGxlckRhdGEJU2xhcFBvd2VyC0Rlc2NyaXB0aW9uS1JhZGlhdGUgcG93ZXIgd2l0aCBhIHZpdmlkIHNsYXAgdGhhdCByYWdkb2xscyBlbmVtaWVzIGZvciBhbiBleHRlbmRlZCB0aW1lLgZSYXJpdHkEUmFyZQpQZXJzaXN0ZW50DlNpbmdsZVB1cmNoYXNlBE5hbWUGUGxheWVyCEJyYWlucm90CER1cmF0aW9uBUZvcmNlDkJyYWlucm90RGFtYWdlEk1heEJyYWlucm90VGFyZ2V0cwdfX2luZGV4DHNldG1ldGF0YWJsZQABBgAAAQIAOKMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BASQEAAAATQEB7wUAAABNAQEPBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAiQEAAAATQICOgcAAABNAgI6CAAAAJ8BAgLiAyAApAQDAAAAIEBNBAS6IQAAADAEA1cLAAAA4gQkAOIFLAAwBQT5IgAAAOIFLwAwBQRdIwAAADAEAzcVAAAA4gQxADABBG4wAAAAnj0DAwQAAACkAjMAAAAgQ58CAwKCAgIANAMBBAAAAEADAgQAACBAAwMDBAMFAwYDBwMIAwkDCgMLAgAAAAAAaghBAwwCAAAAAAAAPkADDQIAAAAAAADwPwMOAw8DEAMRAxICAAAAAAAAREADEwMUAxUDFgMXAQADGAEBCA0JCgAAAAv/////DA0AAAAODwAAABARAAAAEhEAAAATFAAAABX/////FhcAAAAYGQAAABobAAAAHB0AAAAeHwAAAAMZAxoDGwUCIiMDHAKPwvUoXI/qPwMdAgAAAAAAAEBAAx4CAAAAAAAAMUADHwgEJSYAAAAnKAAAACkqAAAAKxEAAAACH4XrUbge1T8CAAAAAAAAJkAIBCUtAAAAJy4AAAApKgAAACsRAAAAAyAFATADIQQAACBDAAEAARgAAwAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAABAIAAAAAAAYBAAAGAAD5ABQAAAAA4wAAAAEAAAAAADarQVg9VsG9qvAQUfwo75xGs1YsBG8rWQ==

-- decompilation:
require(script.Parent.Parent.Parent.Types.Interface)

local Default = require(script.Parent.Parent.Parent.BaseConfigs.Default)

return (setmetatable({
	Icon = "rbxassetid://125486072175077",
	MoneyCost = 200000.0,
	ShopDropWeight = 30.0,
	MinShopStockQuantity = 1.0,
	MaxShopStockQuantity = 1.0,
	ToolController = "Slap",
	SlapPower = 40.0,
	Description = "Radiate power with a vivid slap that ragdolls enemies for an extended time.",
	Rarity = "Rare",
	Persistent = false,
	SinglePurchase = true,
	DisplayName = script.Name,
	ControllerData = {
		Player = {
			Duration = 0.83,
			Force = 32.0,
			BrainrotDamage = 17.0,
			MaxBrainrotTargets = 1.0
		},
		Brainrot = {
			Duration = 0.33,
			Force = 11.0,
			BrainrotDamage = 17.0,
			MaxBrainrotTargets = 1.0
		}
	}
}, {
	__index = Default
}))

