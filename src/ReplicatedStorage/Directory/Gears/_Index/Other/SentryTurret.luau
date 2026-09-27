-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMZB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2ULQmFzZUNvbmZpZ3MHRGVmYXVsdARJY29uG3JieGFzc2V0aWQ6Ly84NDg4OTU5NjE1MDU4OQtEaXNwbGF5TmFtZQlNb25leUNvc3QOU2hvcERyb3BXZWlnaHQUTWluU2hvcFN0b2NrUXVhbnRpdHkUTWF4U2hvcFN0b2NrUXVhbnRpdHkOVG9vbENvbnRyb2xsZXIETm9uZQtEZXNjcmlwdGlvbk9Vc2UgdGhpcyBzZW50cnkgdHVycmV0IGFzIG1lYW5zIG9mIGF1dG9tYXRlZCBwcm90ZWN0aW9uIGZvciB5b3UgYW5kIHlvdXIgaXRlbXMuBlJhcml0eQlQcmlzbWF0aWMKUGVyc2lzdGVudA5TaW5nbGVQdXJjaGFzZQROYW1lB19faW5kZXgMc2V0bWV0YXRhYmxlAAEFAAABAgAvowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEBJAQAAABNAQHvBQAAAE0BAQ8GAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAiQEAAAATQICJAQAAABNAgI6BwAAAE0CAjoIAAAAnwECAuIDHQCkBAMAAAAgQE0EBLoeAAAAMAQDVwsAAADiBCAAMAEEbh8AAACePQMDBAAAAKQCIgAAABBCnwIDAoICAgAjAwEEAAAAQAMCBAAAIEADAwMEAwUDBgMHAwgDCQMKAwsCAAAAANASU0EDDAIAAAAAAAAYQAMNAgAAAAAAAPA/Aw4DDwMQAxEDEgMTAxQDFQEAAxYBAQgLCQoAAAAL/////wwNAAAADg8AAAAQEQAAABIRAAAAExQAAAAVFgAAABcYAAAAGRoAAAAbHAAAAAMXAxgFAR8DGQQAABBCAAEAARgAAwAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAwIAAAAAAAsAAAAA8gAAAAEAAAAAABQQfOviK7PKZx7WGw/0fgxkCGufJtQW6g==

-- decompilation:
require(script.Parent.Parent.Parent.Types.Interface)

local Default = require(script.Parent.Parent.Parent.BaseConfigs.Default)

return (setmetatable({
	Icon = "rbxassetid://84889596150589",
	MoneyCost = 5000000.0,
	ShopDropWeight = 6.0,
	MinShopStockQuantity = 1.0,
	MaxShopStockQuantity = 1.0,
	ToolController = "None",
	Description = "Use this sentry turret as means of automated protection for you and your items.",
	Rarity = "Prismatic",
	Persistent = false,
	SinglePurchase = true,
	DisplayName = script.Name
}, {
	__index = Default
}))

