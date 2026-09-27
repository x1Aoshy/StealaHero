-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2ULQmFzZUNvbmZpZ3MHRGVmYXVsdARJY29uHHJieGFzc2V0aWQ6Ly8xMDM0MDA0MTQwMTQ5MDULRGlzcGxheU5hbWUJTW9uZXlDb3N0DlNob3BEcm9wV2VpZ2h0FE1pblNob3BTdG9ja1F1YW50aXR5FE1heFNob3BTdG9ja1F1YW50aXR5DlRvb2xDb250cm9sbGVyBFNsYXAOQ29udHJvbGxlckRhdGEJU2xhcFBvd2VyC0Rlc2NyaXB0aW9uJEEgZnVsbHkgZGlhbW9uZCBwb3dlcmVkIHN0cm9uZyBzbGFwLgZSYXJpdHkEUmFyZQpQZXJzaXN0ZW50DlNpbmdsZVB1cmNoYXNlBE5hbWUGUGxheWVyCEJyYWlucm90CER1cmF0aW9uBUZvcmNlDkJyYWlucm90RGFtYWdlEk1heEJyYWlucm90VGFyZ2V0cwdfX2luZGV4DHNldG1ldGF0YWJsZQABBgAAAQIAOKMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BASQEAAAATQEB7wUAAABNAQEPBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAiQEAAAATQICOgcAAABNAgI6CAAAAJ8BAgLiAyAApAQDAAAAIEBNBAS6IQAAADAEA1cLAAAA4gQkAOIFLAAwBQT5IgAAAOIFLwAwBQRdIwAAADAEAzcVAAAA4gQxADABBG4wAAAAnj0DAwQAAACkAjMAAAAgQ58CAwKCAgIANAMBBAAAAEADAgQAACBAAwMDBAMFAwYDBwMIAwkDCgMLAgAAAAAAauhAAwwCAAAAAAAAPkADDQIAAAAAAADwPwMOAw8DEAMRAxICAAAAAABAUEADEwMUAxUDFgMXAQADGAEBCA0JCgAAAAv/////DA0AAAAODwAAABARAAAAEhEAAAATFAAAABX/////FhcAAAAYGQAAABobAAAAHB0AAAAeHwAAAAMZAxoDGwUCIiMDHAKamZmZmZnpPwMdAgAAAAAAAD1AAx4CAAAAAAAANEADHwgEJSYAAAAnKAAAACkqAAAAKxEAAAACmpmZmZmZyT8CAAAAAAAAJEAIBCUtAAAAJy4AAAApKgAAACsRAAAAAyAFATADIQQAACBDAAEAARgAAwAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAABAIAAAAAAAYBAAAGAAD5ABQAAAAA4wAAAAEAAAAAAMjMWUPnZ3yTrigEgOP3CuG41E43+ggzQg==

-- decompilation:
require(script.Parent.Parent.Parent.Types.Interface)

local Default = require(script.Parent.Parent.Parent.BaseConfigs.Default)

return (setmetatable({
	Icon = "rbxassetid://103400414014905",
	MoneyCost = 50000.0,
	ShopDropWeight = 30.0,
	MinShopStockQuantity = 1.0,
	MaxShopStockQuantity = 1.0,
	ToolController = "Slap",
	SlapPower = 65.0,
	Description = "A fully diamond powered strong slap.",
	Rarity = "Rare",
	Persistent = false,
	SinglePurchase = true,
	DisplayName = script.Name,
	ControllerData = {
		Player = {
			Duration = 0.8,
			Force = 29.0,
			BrainrotDamage = 20.0,
			MaxBrainrotTargets = 1.0
		},
		Brainrot = {
			Duration = 0.2,
			Force = 10.0,
			BrainrotDamage = 20.0,
			MaxBrainrotTargets = 1.0
		}
	}
}, {
	__index = Default
}))

