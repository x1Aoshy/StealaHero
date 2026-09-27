-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMcFUluZGV4QmF0Q29uZmlnT3B0aW9ucwZhc3NlcnQESWNvbgtEaXNwbGF5TmFtZQlNb25leUNvc3QOU2hvcERyb3BXZWlnaHQUTWluU2hvcFN0b2NrUXVhbnRpdHkUTWF4U2hvcFN0b2NrUXVhbnRpdHkOVG9vbENvbnRyb2xsZXIETm9uZQlUb29sTW9kZWwLRGVzY3JpcHRpb24GUmFyaXR5ClBlcnNpc3RlbnQOU2luZ2xlUHVyY2hhc2UNRGlzcGxheUluU2hvcAxJbmRleEJhdFRpZXIRQmF0Q29udHJvbGxlckRhdGEtQ29tcGxldGUgdGhlICUqIGFyZWEgaW5kZXggdG8gZXF1aXAgdGhpcyBiYXQhBmZvcm1hdAhEdXJhdGlvbgVGb3JjZQpSYW5nZUJvbnVzB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2UAAggBAQAAADv7AQAATQEB6gAAAABSAgAAnwECA54BAQUCAAAAUgQBAFIFAgCkAwIAAAAQQJ8DAwHiAxcATQQArgMAAAAwBAOuAwAAAE0EAFcEAAAAMAQDVwQAAABNBABXBAAAADAEA4ENAAAAbwQYAE0GAFcEAAAAvAQEjRkAAACfBAMCMAQD4g4AAABNBADyDwAAADAEA/IPAAAATQQABxUAAAAwBAMHFQAAAOIEHQBNBQDlGgAAADAFBOUaAAAATQUALRsAAAAwBQQtGwAAAE0HAAcVAAAAeAYHCVsFBh4wBQTnHAAAADAEAxkWAAAAggMCAB8DAQMCBAAAEEADAwMEAwUCAAAAAAAAAAADBgMHAgAAAAAAAPA/AwgDCQMKAwsDDAMNAw4BAQMPAxABAAMRAxIIDwP/////BP////8FBgAAAAcGAAAACAkAAAAKCQAAAAsMAAAADf////8O/////w//////EBEAAAASEQAAABMUAAAAFf////8W/////wMTAxQDFQMWAxcFAxobHAIAAAAAAAD+PwALAAEYAAAAAAABAAAAAAAAAgEAAAABAAAABgAAAAEAAAAAAAAAAQAAAAQAAAABAQAAAAEAAAABAAAAAAD9AAYMAAAAAAIAAAECABGjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHvBQAAAE0BAQ8GAAAAnwACAsABBwASAAAAggECAAgDGAQAAABAAxkEAAAgQAMaAxsDHAYAAQABAAEYAAMAAAAAAAAAAAAAAAAHAAABAAAAAAF/iC2WPEdt8OSpWNhlLQBlD5A64k1MR5c=

-- decompilation:
local Interface = require(script.Parent.Parent.Types.Interface)

return function(p1) -- line: 11
	-- upvalues: Interface (copy)
	local v3, v4 = Interface.IndexBatConfigOptions(p1)

	assert(v3, v4)

	return {
		MoneyCost = 0.0,
		ShopDropWeight = 0.0,
		MinShopStockQuantity = 1.0,
		MaxShopStockQuantity = 1.0,
		ToolController = "None",
		Persistent = true,
		SinglePurchase = true,
		DisplayInShop = false,
		Icon = p1.Icon,
		DisplayName = p1.DisplayName,
		ToolModel = p1.DisplayName,
		Description = `Complete the { p1.DisplayName } area index to equip this bat!`,
		Rarity = p1.Rarity,
		IndexBatTier = p1.IndexBatTier,
		BatControllerData = {
			Duration = p1.Duration,
			Force = p1.Force,
			RangeBonus = (p1.IndexBatTier - 1.0) * 1.875
		}
	}
end

