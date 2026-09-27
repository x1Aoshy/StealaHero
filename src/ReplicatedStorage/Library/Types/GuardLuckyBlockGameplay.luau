-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0CWludGVyZmFjZQlyZXF1ZXN0SWQHYmxvY2tJZA5yZXdhcmRDYXRlZ29yeQ9yZXdhcmRNdXRhdGlvbnMScmV3YXJkQmFzZU11dGF0aW9uC3Jld2FyZFNjYWxlEWhpZ2hlc3RSYXJpdHlOYW1lE2hpZ2hlc3RSYXJpdHlOdW1iZXIGc3RyaW5nBWFycmF5CG9wdGlvbmFsBm51bWJlchlDYXVnaHRSZXZlYWxSZXdhcmRQYXlsb2FkC2NoYXJnZVBvd2VyD0JlZ2luUnVuUGF5bG9hZAxtdXRhdGlvbk5hbWUbQWN0aXZlUnVuTXV0YXRpb25IaXRQYXlsb2FkAAEHAAABAgBVowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLoBwAAAE0CAuYIAAAATQIClQkAAACfAQIC/wIDAAAAAABNAwEvCgAAAOIEEwBNBQFBFAAAADAFBL8LAAAATQUBQRQAAAAwBQSzDAAAAE0FAUEUAAAAMAUEYw0AAABNBQEdFQAAAE0GAUEUAAAAnwUCAjAFBKkOAAAATQUBERYAAABNBgFBFAAAAJ8FAgIwBQQeDwAAAE0FAWAXAAAAMAUEVhAAAABNBQFBFAAAADAFBA4RAAAATQUBYBcAAAAwBQSNEgAAAJ8DAgIwAwLNGAAAAE0DAS8KAAAA4gQaAE0FAWAXAAAAMAUENRkAAACfAwICMAMCwxsAAABNAwEvCgAAAOIEHQBNBQFBFAAAADAFBPocAAAAnwMCAjADAoceAAAAggICAB8DAQQAAABAAwIDAwMEBAAAQEADBQMGAwcDCAMJAwoDCwMMAw0DDgMPAxADEQUICwwNDg8QERIDEgMTAxQDFQMWAxcFARkDGAMZBQEcAxoAAQABGAADAAAAAAADAAAAAAAAAAAAABoAAgAAAQAAAAEAAAABAAAAAQAAAAAAAAEAAAAAAAABAAAAAQAAAAEAAAD4AAAKAAABAAAA/wAAAwAAAQAAAP8AAAQBAAAAAADHkZrhKDoDPpO8Mh06LVAVt4mNlfVV8OA=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)

return {
	CaughtRevealRewardPayload = t.interface({
		requestId = t.string,
		blockId = t.string,
		rewardCategory = t.string,
		rewardMutations = t.array(t.string),
		rewardBaseMutation = t.optional(t.string),
		rewardScale = t.number,
		highestRarityName = t.string,
		highestRarityNumber = t.number
	}),
	BeginRunPayload = t.interface({
		chargePower = t.number
	}),
	ActiveRunMutationHitPayload = t.interface({
		mutationName = t.string
	})
}

