-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0CWludGVyZmFjZQZFZ2dVaWQHTWVzc2FnZQhSYXJpdHlJZAdTb3VuZElkBnN0cmluZwhvcHRpb25hbAZudW1iZXIFYXJyYXkQU2NoZW1hVmFsaWRhdGlvbhVSYXJlU3Bhd25QcmVzZW50YXRpb24WUmFyZVNwYXduUHJlc2VudGF0aW9ucw9TZXF1ZW5jZVBheWxvYWQLRGF5U3RhcnRzQXQKUmFyZVNwYXducwABCQAAAQIAQqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQIC6AcAAABNAgLmCAAAAE0CApUJAAAAnwECAk0CAS8KAAAA4gMPAE0EAUEQAAAAMAQDVQsAAABNBAFBEAAAADAEA/gMAAAATQQBQRAAAAAwBAPzDQAAAE0EARERAAAATQUBYBIAAACfBAICMAQDfA4AAACfAgICTQMBHRMAAABSBAIAnwMCAuIEFQDiBRkAMAIFzRYAAAAwAwUCFwAAAE0GAS8KAAAA4gccAE0IAWASAAAAMAgHcRoAAAAwAwd2GwAAAJ8GAgIwBgUyGAAAADAFBN8UAAAAggQCAB0DAQQAAABAAwIDAwMEBAAAQEADBQMGAwcDCAMJAwoDCwMMAw0FBAsMDQ4DDgMPAxADEQMSBQEUAxMDFAMVBQMWFxgDFgMXBQIaGwABAAEYAAMAAAAAAAMAAAAAAAAAAAAAEgAAAQAAAAEAAAABAAAAAQAAAAAAAPwGAAAAAgEBAAEAAQAAAQAAAAEA/gAA/QAKAQAAAAAA5i2rZefS/7L6n/8ssL0BSpY1vBHU6cFk

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local v3 = t.interface({
	EggUid = t.string,
	Message = t.string,
	RarityId = t.string,
	SoundId = t.optional(t.number)
})
local v4 = t.array(v3)

return {
	SchemaValidation = {
		RareSpawnPresentation = v3,
		RareSpawnPresentations = v4,
		SequencePayload = t.interface({
			DayStartsAt = t.number,
			RareSpawns = v4
		})
	}
}

