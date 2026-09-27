-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMZB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2ULQmFzZUNvbmZpZ3MHRGVmYXVsdARJY29uG3JieGFzc2V0aWQ6Ly83MzA0NjA5MDg1MzAyNQtEaXNwbGF5TmFtZQlNb25leUNvc3QOU2hvcERyb3BXZWlnaHQUTWluU2hvcFN0b2NrUXVhbnRpdHkUTWF4U2hvcFN0b2NrUXVhbnRpdHkOVG9vbENvbnRyb2xsZXIETm9uZQtEZXNjcmlwdGlvbjVQdXRzIG9uIGNhcGUuIFNob290cyBsYXNlciBmcm9tIGV5ZXMuIFRvdGFsbHkgbm9ybWFsLgZSYXJpdHkMVHJhbnNjZW5kZW50ClBlcnNpc3RlbnQOU2luZ2xlUHVyY2hhc2UETmFtZQdfX2luZGV4DHNldG1ldGF0YWJsZQABBQAAAQIAL6MAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BASQEAAAATQEB7wUAAABNAQEPBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAiQEAAAATQICOgcAAABNAgI6CAAAAJ8BAgLiAx0ApAQDAAAAIEBNBAS6HgAAADAEA1cLAAAA4gQgADABBG4fAAAAnj0DAwQAAACkAiIAAAAQQp8CAwKCAgIAIwMBBAAAAEADAgQAACBAAwMDBAMFAwYDBwMIAwkDCgMLAgAAAAAAavhAAwwCAAAAAAAAAEADDQIAAAAAAADwPwMOAw8DEAMRAxIDEwMUAxUBAAMWAQEICwkKAAAAC/////8MDQAAAA4PAAAAEBEAAAASEQAAABMUAAAAFRYAAAAXGAAAABkaAAAAGxwAAAADFwMYBQEfAxkEAAAQQgABAAEYAAMAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAMCAAAAAAALAAAAAPIAAAABAAAAAABCNjQa8q1PFMFi274A/EkyMi4jbnDyXhs=

-- decompilation:
require(script.Parent.Parent.Parent.Types.Interface)

local Default = require(script.Parent.Parent.Parent.BaseConfigs.Default)

return (setmetatable({
	Icon = "rbxassetid://73046090853025",
	MoneyCost = 100000.0,
	ShopDropWeight = 2.0,
	MinShopStockQuantity = 1.0,
	MaxShopStockQuantity = 1.0,
	ToolController = "None",
	Description = "Puts on cape. Shoots laser from eyes. Totally normal.",
	Rarity = "Transcendent",
	Persistent = false,
	SinglePurchase = true,
	DisplayName = script.Name
}, {
	__index = Default
}))

