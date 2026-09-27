-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMfBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0BVR5cGVzCUFzc2V0SXRlbQ9zdHJpY3RJbnRlcmZhY2ULT3duZXJVc2VySWQDVUlECEl0ZW1EYXRhDk1vbmV5UGVyU2Vjb25kBFNlZWQQSXNGaXJzdFBsYWNlbWVudAZudW1iZXIGc3RyaW5nDUFzc2V0SXRlbURhdGEIb3B0aW9uYWwHYm9vbGVhbgNtYXAHUmVjb3JkcxJSdW50aW1lQXNzZXRSZWNvcmQTUnVudGltZUFzc2V0UmVjb3JkcxdSdW50aW1lQXNzZXRPd25lclVwZGF0ZRZSdW50aW1lQXNzZXRPd25lckNsZWFyFFJ1bnRpbWVBc3NldFNuYXBzaG90BWFycmF5EFNjaGVtYVZhbGlkYXRpb24AAQsAAAECAGajAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAugHAAAATQIC5ggAAABNAgKVCQAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMD7woAAABNAwPmCwAAAJ8CAgL/AwEAAAAAAE0EAfAMAAAA4gUTAE0GAWAUAAAAMAYFEg0AAABNBgFBFQAAADAGBYcOAAAATQYCvBYAAAAwBgVTDwAAAE0GAWAUAAAAMAYFfBAAAABNBgFgFAAAADAGBVsRAAAATQYBERcAAABNBwE+GAAAAJ8GAgIwBgUuEgAAAJ8EAgJNBQGQGQAAAE0GAUEVAAAAUgcEAJ8FAwJNBgHwDAAAAOIHGwBNCAFgFAAAADAIBxINAAAAMAUHeBoAAACfBgIC4gchADAEB90cAAAAMAUH/x0AAAAwBgdRHgAAAE0IAfAMAAAA4gkiAE0KAWAUAAAAMAoJEg0AAACfCAICMAgHoh8AAABNCAEdIwAAAFIJBgCfCAICMAgHxyAAAAAwBwPfJAAAAIIDAgAlAwEEAAAAQAMCAwMDBAQAAEBAAwUDBgMHAwgDCQMKAwsDDAMNAw4DDwMQAxEFBg0ODxAREgMSAxMDFAMVAxYDFwMYBQINGgMZAxoDGwMcAx0FBRwdHh8gBQENAx4DHwABAAEYAAMAAAAAAAMAAAAAAAAAAAAAAQAAAAAAAAAAGAACAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAAAAAD6CQAAAAAAAQAAAQAAAAEA/gUBAAEAAQABAAAAAAAAAAAAAQAAAAAA+wAIAQAAAAAA/q4beTMRwfBIi36sfDJRoo62DA3ManF4

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local AssetItem = require(ReplicatedStorage.Library.Types.AssetItem)
local t1 = {}
local v5 = t.strictInterface({
	OwnerUserId = t.number,
	UID = t.string,
	ItemData = AssetItem.AssetItemData,
	MoneyPerSecond = t.number,
	Seed = t.number,
	IsFirstPlacement = t.optional(t.boolean)
})
local v6 = t.map(t.string, v5)
local v7 = t.strictInterface({
	OwnerUserId = t.number,
	Records = v6
})

t1.SchemaValidation = {
	RuntimeAssetRecord = v5,
	RuntimeAssetRecords = v6,
	RuntimeAssetOwnerUpdate = v7,
	RuntimeAssetOwnerClear = t.strictInterface({
		OwnerUserId = t.number
	}),
	RuntimeAssetSnapshot = t.array(v7)
}

return t1

