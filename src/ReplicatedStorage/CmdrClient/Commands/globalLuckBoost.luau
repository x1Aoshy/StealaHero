-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBE5hbWUPZ2xvYmFsTHVja0Jvb3N0C0Rlc2NyaXB0aW9uIkdpdmVzIGEgbHVjayBib29zdCB0byBhbGwgc2VydmVycy4HQWxpYXNlcwVHcm91cAVBZG1pbgRBcmdzAARUeXBlB2ludGVnZXIIRHVyYXRpb24YVGhlIGR1cmF0aW9uIGluIHNlY29uZHMuCk11bHRpcGxpZXIiVGhlIG11bHRpcGxpZXIgdG8gYXBwbHkgKHgyIC0geDMyKQhPcHRpb25hbAABBAAAAQIAEqMAAADiAAgA/wEAAAEAAABvAgkAxQECAgEAAAAwAQAnBAAAAP8BAAACAAAA4gIOAOIDEwDFAQIDAQAAADABANsHAAAAggACABQDAQMCAwMDBAMFAwYDBwMICAUAAQAAAAIDAAAABP////8FBgAAAAf/////AwkDCgMLAwwDDQgDCgsAAAAADAAAAAINAAAAAw4DDwMQAQEIBAoLAAAAAA8AAAACEAAAABESAAAAAAEAARgAAAMAAAAAAAACAAEFAAD6AAABAAAAAADsWgewZZ6/ZK9mCwndaUiinEIQxN6ebbE=

-- decompilation:
return {
	Name = "globalLuckBoost",
	Description = "Gives a luck boost to all servers.",
	Group = "Admin",
	Aliases = { "" },
	Args = {
		{
			Type = "integer",
			Name = "Duration",
			Description = "The duration in seconds."
		},
		{
			Type = "integer",
			Name = "Multiplier",
			Description = "The multiplier to apply (x2 - x32)",
			Optional = true
		}
	}
}

