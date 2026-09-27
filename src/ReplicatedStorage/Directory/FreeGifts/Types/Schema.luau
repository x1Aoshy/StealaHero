-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0BVR5cGVzCUZyZWVHaWZ0cwlpbnRlcmZhY2UCSWQEVHlwZQhXYWl0VGltZQhUeXBlRGF0YQdSZXdhcmRzBm51bWJlchBTY2hlbWFWYWxpZGF0aW9uD0FsbERpZmZpY3VsdGllcwVhcnJheQxSZXdhcmRDb25maWcNRGVmYXVsdENvbmZpZwABCAAAAQIAQaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQIC6AcAAABNAgLmCAAAAE0CApUJAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwPvCgAAAE0DA7ELAAAAnwICAv8DAQAAAAAATQQBLwwAAADiBRIATQYBYBMAAAAwBgWUDQAAAE0GAt8UAAAATQYG0RUAAAAwBgURDgAAAE0GAWATAAAAMAYF3A8AAABNBgLfFAAAAE0GBl0QAAAAMAYFXRAAAABNBgEdFgAAAE0HAt8UAAAATQcH8RcAAACfBgICMAYFFREAAACfBAICMAQDDBgAAACCAwIAGQMBBAAAAEADAgMDAwQEAABAQAMFAwYDBwMIAwkDCgMLAwwDDQMOAw8DEAUFDQ4PEBEDEQMSAxMDFAMVAxYAAQABGAADAAAAAAADAAAAAAAAAAAAAAEAAAAAAAAAAAMAAgAAAQAAAAEAAAAAAAEAAAABAAAAAAABAAAAAAAAAAD7AAAIAQAAAAAAXTC9bGIMMHajBQmT66aaYC0oqhhv9Ndt

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local FreeGifts = require(ReplicatedStorage.Library.Types.FreeGifts)

return {
	DefaultConfig = t.interface({
		Id = t.number,
		Type = FreeGifts.SchemaValidation.AllDifficulties,
		WaitTime = t.number,
		TypeData = FreeGifts.SchemaValidation.TypeData,
		Rewards = t.array(FreeGifts.SchemaValidation.RewardConfig)
	})
}

