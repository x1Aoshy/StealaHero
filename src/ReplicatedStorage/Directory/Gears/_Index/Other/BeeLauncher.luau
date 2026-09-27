-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2ULQmFzZUNvbmZpZ3MHRGVmYXVsdARJY29uG3JieGFzc2V0aWQ6Ly85NjIxMDExMDIyNzk0NQtEaXNwbGF5TmFtZQlNb25leUNvc3QOU2hvcERyb3BXZWlnaHQUTWluU2hvcFN0b2NrUXVhbnRpdHkUTWF4U2hvcFN0b2NrUXVhbnRpdHkOVG9vbENvbnRyb2xsZXIETm9uZQtEZXNjcmlwdGlvbj9SZWxlYXNlIGJlZXMgdG8gYXR0YWNrIHlvdXIgb3Bwb25lbnQgYW5kIGludmVydCB0aGVpciBjb250cm9scyEGUmFyaXR5CUxlZ2VuZGFyeQ1EaXNwbGF5SW5TaG9wClBlcnNpc3RlbnQOU2luZ2xlUHVyY2hhc2UETmFtZQdfX2luZGV4DHNldG1ldGF0YWJsZQABBQAAAQIAL6MAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BASQEAAAATQEB7wUAAABNAQEPBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAiQEAAAATQICOgcAAABNAgI6CAAAAJ8BAgLiAx4ApAQDAAAAIEBNBAS6HwAAADAEA1cLAAAA4gQhADABBG4gAAAAnj0DAwQAAACkAiMAAAAgQp8CAwKCAgIAJAMBBAAAAEADAgQAACBAAwMDBAMFAwYDBwMIAwkDCgMLAgAAAAAAiMNAAwwCAAAAAAAATkADDQIAAAAAAADwPwMOAw8DEAMRAxIDEwMUAxUBAAMWAQEDFwgMCQoAAAAL/////wwNAAAADg8AAAAQEQAAABIRAAAAExQAAAAVFgAAABcYAAAAGRoAAAAbHAAAAB0cAAAAAxgDGQUBIAMaBAAAIEIAAQABGAADAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAADAgAAAAAADAAAAADxAAAAAQAAAAAA4aM0FRF1v42vt1cg0wFVApG7I2HTZ14U

-- decompilation:
require(script.Parent.Parent.Parent.Types.Interface)

local Default = require(script.Parent.Parent.Parent.BaseConfigs.Default)

return (setmetatable({
	Icon = "rbxassetid://96210110227945",
	MoneyCost = 10000.0,
	ShopDropWeight = 60.0,
	MinShopStockQuantity = 1.0,
	MaxShopStockQuantity = 1.0,
	ToolController = "None",
	Description = "Release bees to attack your opponent and invert their controls!",
	Rarity = "Legendary",
	DisplayInShop = false,
	Persistent = true,
	SinglePurchase = true,
	DisplayName = script.Name
}, {
	__index = Default
}))

