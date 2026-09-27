-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWBFR5cGUETmFtZQZGb3JtYXQLRGVzY3JpcHRpb25EV2hhdCBkYXRhIHRvIHJldHVybi4gUGxhY2VJZEpvYklkIHJldHVybnMgYm90aCBzZXBhcmF0ZWQgYnkgYSBzcGFjZS4HRGVmYXVsdAxQbGFjZUlkSm9iSWQEQ21kcgRVdGlsDE1ha2VFbnVtVHlwZRRQbGFjZUluc3RhbmNlIEZvcm1hdAdQbGFjZUlkBUpvYklkGWdldC1wbGF5ZXItcGxhY2UtaW5zdGFuY2UHQWxpYXNlc4kBUmV0dXJucyB0aGUgdGFyZ2V0IHBsYXllcidzIFBsYWNlIElEIGFuZCB0aGUgSm9iSWQgc2VwYXJhdGVkIGJ5IGEgc3BhY2UuIFJldHVybnMgMCBpZiB0aGUgcGxheWVyIGlzIG9mZmxpbmUgb3Igc29tZXRoaW5nIGVsc2UgZ29lcyB3cm9uZy4FR3JvdXAMRGVmYXVsdERlYnVnBEFyZ3MIcGxheWVySWQGUGxheWVyJUdldCB0aGUgcGxhY2UgaW5zdGFuY2Ugb2YgdGhpcyBwbGF5ZXIAAggBAAAAABPiAQcATQIAnggAAABNAgKeCQAAAE0CArIKAAAAbwMLAP8EAAADAAAAbwUGAG8GDABvBw0AxQQFBAEAAACfAgMCMAIBEQAAAACCAQIADgMBAwIDAwMEAwUDBgMHCAQA/////wECAAAAAwQAAAAFBgAAAAMIAwkDCgMLAwwDDQAMAAEYAAEAAAAAAAAAAAAAAAAAAAAAAA0AAAAABAAAAQIAD6MAAADiAAgA/wEAAAAAAAAwAQAnAgAAAP8BAAACAAAA4gINAMADDgDFAQIDAQAAADABANsHAAAAggACAA8DAgMOAw8DBAMQAxEDEgMTCAUAAQAAAAL/////AwQAAAAFBgAAAAf/////AwEDFAMVAxYIAwkKAAAAAAsAAAADDAAAAAYAAQABAAEYAAACAAAAAwABBQAA+gAAAQAAAAABV59dkheAWes1BUHxasVRsieHSuZlWzeT

-- decompilation:
return {
	Name = "get-player-place-instance",
	Description = "Returns the target player's Place ID and the JobId separated by a space. Returns 0 if the player is offline or something else goes wrong.",
	Group = "DefaultDebug",
	Aliases = {},
	Args = {
		{
			Type = "playerId",
			Name = "Player",
			Description = "Get the place instance of this player"
		},
		function(p1) -- line: 12
			return {
				Name = "Format",
				Description = "What data to return. PlaceIdJobId returns both separated by a space.",
				Default = "PlaceIdJobId",
				Type = p1.Cmdr.Util.MakeEnumType("PlaceInstance Format", {
					"PlaceIdJobId",
					"PlaceId",
					"JobId"
				})
			}
		end
	}
}

