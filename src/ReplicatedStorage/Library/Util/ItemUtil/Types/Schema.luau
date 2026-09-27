-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0BVR5cGVzCEN1cnJlbmN5EFNjaGVtYVZhbGlkYXRpb24QQWxsQ3VycmVuY3lUeXBlcxNBdmFpbGFibGVDdXJyZW5jaWVzCWludGVyZmFjZQZBbW91bnQIb3B0aW9uYWwGbnVtYmVyBEl0ZW0IRnVsbEl0ZW0AAQgAAAECAEejAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAugHAAAATQIC5ggAAABNAgKVCQAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMD7woAAABNAwMJCwAAAJ8CAgL/AwMAAAAAAE0EAt8MAAAATQQEhg0AAAAwBAOIDgAAAE0EAS8PAAAA4gURAE0GAt8MAAAATQYGhg0AAAAwBgUJCwAAAE0GARESAAAATQcBYBMAAACfBgICMAYFKxAAAACfBAICMAQDyhQAAABNBAEvDwAAAOIFEQBNBgLfDAAAAE0GBoYNAAAAMAYFCQsAAABNBgFgEwAAADAGBSsQAAAAnwQCAjAEAxAVAAAAggMCABYDAQQAAABAAwIDAwMEBAAAQEADBQMGAwcDCAMJAwoDCwMMAw0DDgMPBQILEAMQAxEDEgMTAAEAARgAAwAAAAAAAwAAAAAAAAAAAAABAAAAAAAAAAADAAIAAAAAAAIAAAEAAAAAAAEAAAAAAAD+AAAFAAABAAAAAAABAAAA/gAABQEAAAAAAExnoLZVvXeIWc1cXUzOxbk8f7fCfqPKtw==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local Currency = require(ReplicatedStorage.Library.Types.Currency)

return {
	AvailableCurrencies = Currency.SchemaValidation.AllCurrencyTypes,
	Item = t.interface({
		Currency = Currency.SchemaValidation.AllCurrencyTypes,
		Amount = t.optional(t.number)
	}),
	FullItem = t.interface({
		Currency = Currency.SchemaValidation.AllCurrencyTypes,
		Amount = t.number
	})
}

