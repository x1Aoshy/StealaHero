-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWBE5hbWUKZ290by1wbGFjZQdBbGlhc2VzC0Rlc2NyaXB0aW9uGlRlbGVwb3J0IHRvIGEgUm9ibG94IHBsYWNlBUdyb3VwDERlZmF1bHRBZG1pbghBdXRvRXhlYwRBcmdzhwFhbGlhcyAiZm9sbG93LXBsYXllcnxKb2luIGEgcGxheWVyIGluIGFub3RoZXIgc2VydmVyIiBnb3RvLXBsYWNlICQxe3BsYXllcnN8UGxheWVyc30gJHt7Z2V0LXBsYXllci1wbGFjZS1pbnN0YW5jZSAkMntwbGF5ZXJJZHxUYXJnZXR9fX2TAWFsaWFzICJyZWpvaW58UmVqb2luIHRoaXMgcGxhY2UuIFlvdSBtaWdodCBlbmQgdXAgaW4gYSBkaWZmZXJlbnQgc2VydmVyLiIgZ290by1wbGFjZSAkMXtwbGF5ZXJzfFBsYXllcnN9ICR7Z2V0LXBsYXllci1wbGFjZS1pbnN0YW5jZSAke21lfSBQbGFjZUlkfQRUeXBlB3BsYXllcnMHUGxheWVycyBUaGUgcGxheWVycyB5b3Ugd2FudCB0byB0ZWxlcG9ydAdpbnRlZ2VyCFBsYWNlIElEJFRoZSBQbGFjZSBJRCB5b3Ugd2FudCB0byB0ZWxlcG9ydCB0bwZzdHJpbmcFSm9iSWQqVGhlIHNwZWNpZmljIEpvYklkIHlvdSB3YW50IHRvIHRlbGVwb3J0IHRvCE9wdGlvbmFsAAEFAAABAgAYowAAAOIACQD/AQAAAAAAADABACcCAAAA/wEAAAIAAABvAgoAbwMLAMUBAgMBAAAAMAEAfQcAAAD/AQAAAwAAAOICEADiAxQA4gQaAMUBAgQBAAAAMAEA2wgAAACCAAIAGwMBAwIDAwMEAwUDBgMHAwgDCQgGAAEAAAAC/////wMEAAAABQYAAAAH/////wj/////AwoDCwMMAw0DDgMPCAMMDQAAAAAOAAAAAw8AAAADEAMRAxIIAwwRAAAAABIAAAADEwAAAAMTAxQDFQMWAQEIBAwVAAAAABYAAAADFwAAABgZAAAAAAEAARgAAAIAAAADAAEBAAD+AAQAAQUFAAD1AAABAAAAAADUhrvhPxN8NnLh8nS4IOH8pJ6sleZC0eA=

-- decompilation:
return {
	Name = "goto-place",
	Description = "Teleport to a Roblox place",
	Group = "DefaultAdmin",
	Aliases = {},
	AutoExec = {
		"alias \"follow-player|Join a player in another server\" goto-place $1{players|Players} ${{get-player-place-instance $2{playerId|Target}}}",
		"alias \"rejoin|Rejoin this place. You might end up in a different server.\" goto-place $1{players|Players} ${get-player-place-instance ${me} PlaceId}"
	},
	Args = {
		{
			Type = "players",
			Name = "Players",
			Description = "The players you want to teleport"
		},
		{
			Type = "integer",
			Name = "Place ID",
			Description = "The Place ID you want to teleport to"
		},
		{
			Type = "string",
			Name = "JobId",
			Description = "The specific JobId you want to teleport to",
			Optional = true
		}
	}
}

