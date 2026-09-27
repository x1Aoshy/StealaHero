-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2ULQmFzZUNvbmZpZ3MHRGVmYXVsdARJY29uG3JieGFzc2V0aWQ6Ly83MzU4NzQ1OTY2ODg5NQtEaXNwbGF5TmFtZQlNb25leUNvc3QOU2hvcERyb3BXZWlnaHQUTWluU2hvcFN0b2NrUXVhbnRpdHkUTWF4U2hvcFN0b2NrUXVhbnRpdHkOVG9vbENvbnRyb2xsZXIEU2xhcA5Db250cm9sbGVyRGF0YQlTbGFwUG93ZXILRGVzY3JpcHRpb25HU3RyaWtlIHdpdGggZ2lsZGVkIHN0cmVuZ3RoIHRvIHNlbmQgb3Bwb25lbnRzIGZseWluZyBpbiBhIGxvbmcgcmFnZG9sbC4GUmFyaXR5CUxlZ2VuZGFyeQpQZXJzaXN0ZW50DlNpbmdsZVB1cmNoYXNlBE5hbWUGUGxheWVyCEJyYWlucm90CER1cmF0aW9uBUZvcmNlDkJyYWlucm90RGFtYWdlEk1heEJyYWlucm90VGFyZ2V0cwdfX2luZGV4DHNldG1ldGF0YWJsZQABBgAAAQIAOKMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BASQEAAAATQEB7wUAAABNAQEPBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAiQEAAAATQICOgcAAABNAgI6CAAAAJ8BAgLiAyAApAQDAAAAIEBNBAS6IQAAADAEA1cLAAAA4gQkAOIFLAAwBQT5IgAAAOIFLwAwBQRdIwAAADAEAzcVAAAA4gQxADABBG4wAAAAnj0DAwQAAACkAjMAAAAgQ58CAwKCAgIANAMBBAAAAEADAgQAACBAAwMDBAMFAwYDBwMIAwkDCgMLAgAAAAAATM1AAwwCAAAAAAAALkADDQIAAAAAAADwPwMOAw8DEAMRAxICAAAAAACAQUADEwMUAxUDFgMXAQADGAEBCA0JCgAAAAv/////DA0AAAAODwAAABARAAAAEhEAAAATFAAAABX/////FhcAAAAYGQAAABobAAAAHB0AAAAeHwAAAAMZAxoDGwUCIiMDHAIzMzMzMzPrPwMdAgAAAAAAADlAAx4CAAAAAAAALEADHwgEJSYAAAAnKAAAACkqAAAAKxEAAAACMzMzMzMz0z8CAAAAAAAAIkAIBCUtAAAAJy4AAAApKgAAACsRAAAAAyAFATADIQQAACBDAAEAARgAAwAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAABAIAAAAAAAYBAAAGAAD5ABQAAAAA4wAAAAEAAAAAANmQFpv5mQ9CNWhcziHVtfmpiAHv61R8mg==

-- decompilation:
require(script.Parent.Parent.Parent.Types.Interface)

local Default = require(script.Parent.Parent.Parent.BaseConfigs.Default)

return (setmetatable({
	Icon = "rbxassetid://73587459668895",
	MoneyCost = 15000.0,
	ShopDropWeight = 15.0,
	MinShopStockQuantity = 1.0,
	MaxShopStockQuantity = 1.0,
	ToolController = "Slap",
	SlapPower = 35.0,
	Description = "Strike with gilded strength to send opponents flying in a long ragdoll.",
	Rarity = "Legendary",
	Persistent = false,
	SinglePurchase = true,
	DisplayName = script.Name,
	ControllerData = {
		Player = {
			Duration = 0.85,
			Force = 25.0,
			BrainrotDamage = 14.0,
			MaxBrainrotTargets = 1.0
		},
		Brainrot = {
			Duration = 0.3,
			Force = 9.0,
			BrainrotDamage = 14.0,
			MaxBrainrotTargets = 1.0
		}
	}
}, {
	__index = Default
}))

