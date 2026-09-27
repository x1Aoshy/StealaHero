-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2ULQmFzZUNvbmZpZ3MHRGVmYXVsdARJY29uHHJieGFzc2V0aWQ6Ly8xMTE3NDQzMTQ4NjQxMjcLRGlzcGxheU5hbWUJTW9uZXlDb3N0DlNob3BEcm9wV2VpZ2h0FE1pblNob3BTdG9ja1F1YW50aXR5FE1heFNob3BTdG9ja1F1YW50aXR5DlRvb2xDb250cm9sbGVyBFNsYXAOQ29udHJvbGxlckRhdGEJU2xhcFBvd2VyC0Rlc2NyaXB0aW9uP0EgdHJ1c3R5IHNsYXAgdGhhdCByYWdkb2xscyBuZWFyYnkgcGxheWVycyB3aXRoIGEgc29saWQgbGF1bmNoLgZSYXJpdHkEUmFyZQpQZXJzaXN0ZW50DlNpbmdsZVB1cmNoYXNlBE5hbWUGUGxheWVyCEJyYWlucm90CER1cmF0aW9uBUZvcmNlDkJyYWlucm90RGFtYWdlEk1heEJyYWlucm90VGFyZ2V0cwdfX2luZGV4DHNldG1ldGF0YWJsZQABBgAAAQIAOKMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BASQEAAAATQEB7wUAAABNAQEPBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAiQEAAAATQICOgcAAABNAgI6CAAAAJ8BAgLiAyAApAQDAAAAIEBNBAS6IQAAADAEA1cLAAAA4gQkAOIFLAAwBQT5IgAAAOIFLwAwBQRdIwAAADAEAzcVAAAA4gQxADABBG4wAAAAnj0DAwQAAACkAjMAAAAgQ58CAwKCAgIANAMBBAAAAEADAgQAACBAAwMDBAMFAwYDBwMIAwkDCgMLAgAAAAAAQH9AAwwCAAAAAAAAPkADDQIAAAAAAADwPwMOAw8DEAMRAxICAAAAAAAALkADEwMUAxUDFgMXAQADGAEBCA0JCgAAAAv/////DA0AAAAODwAAABARAAAAEhEAAAATFAAAABX/////FhcAAAAYGQAAABobAAAAHB0AAAAeHwAAAAMZAxoDGwUCIiMDHAKamZmZmZnpPwMdAgAAAAAAADlAAx4CAAAAAAAAKEADHwgEJSYAAAAnKAAAACkqAAAAKxEAAAACAAAAAAAA0D8CAAAAAAAAHEAIBCUtAAAAJy4AAAApKgAAACsRAAAAAyAFATADIQQAACBDAAEAARgAAwAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAABAIAAAAAAAYBAAAGAAD5ABQAAAAA4wAAAAEAAAAAAOc1FyC2hQlN2sHu9mawTj2XLQBU1fF9IQ==

-- decompilation:
require(script.Parent.Parent.Parent.Types.Interface)

local Default = require(script.Parent.Parent.Parent.BaseConfigs.Default)

return (setmetatable({
	Icon = "rbxassetid://111744314864127",
	MoneyCost = 500.0,
	ShopDropWeight = 30.0,
	MinShopStockQuantity = 1.0,
	MaxShopStockQuantity = 1.0,
	ToolController = "Slap",
	SlapPower = 15.0,
	Description = "A trusty slap that ragdolls nearby players with a solid launch.",
	Rarity = "Rare",
	Persistent = false,
	SinglePurchase = true,
	DisplayName = script.Name,
	ControllerData = {
		Player = {
			Duration = 0.8,
			Force = 25.0,
			BrainrotDamage = 12.0,
			MaxBrainrotTargets = 1.0
		},
		Brainrot = {
			Duration = 0.25,
			Force = 7.0,
			BrainrotDamage = 12.0,
			MaxBrainrotTargets = 1.0
		}
	}
}, {
	__index = Default
}))

