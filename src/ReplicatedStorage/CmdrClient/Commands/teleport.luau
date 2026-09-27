-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTBE5hbWUIdGVsZXBvcnQHQWxpYXNlcwtEZXNjcmlwdGlvbjNUZWxlcG9ydHMgYSBwbGF5ZXIgb3Igc2V0IG9mIHBsYXllcnMgdG8gb25lIHRhcmdldC4FR3JvdXAMRGVmYXVsdEFkbWluCEF1dG9FeGVjBEFyZ3MCdHBvYWxpYXMgImJyaW5nfEJyaW5ncyBhIHBsYXllciBvciBzZXQgb2YgcGxheWVycyB0byB5b3UuIiB0ZWxlcG9ydCAkMXtwbGF5ZXJzfHBsYXllcnN8VGhlIHBsYXllcnMgdG8gYnJpbmd9ICR7bWV9jQFhbGlhcyAidG98VGVsZXBvcnRzIHlvdSB0byBhbm90aGVyIHBsYXllciBvciBsb2NhdGlvbi4iIHRlbGVwb3J0ICR7bWV9ICQxe3BsYXllciBAIHZlY3RvcjN8RGVzdGluYXRpb258VGhlIHBsYXllciBvciBsb2NhdGlvbiB0byB0ZWxlcG9ydCB0b30EVHlwZQdwbGF5ZXJzBEZyb20XVGhlIHBsYXllcnMgdG8gdGVsZXBvcnQQcGxheWVyIEAgdmVjdG9yMwtEZXN0aW5hdGlvbhlUaGUgcGxheWVyIHRvIHRlbGVwb3J0IHRvAAEEAAABAgAaowAAAOIACQD/AQAAAQAAAG8CCgDFAQICAQAAADABACcCAAAA/wEAAAIAAABvAgsAbwMMAMUBAgMBAAAAMAEAfQcAAAD/AQAAAgAAAOICEQDiAxUAxQECAwEAAAAwAQDbCAAAAIIAAgAWAwEDAgMDAwQDBQMGAwcDCAMJCAYAAQAAAAL/////AwQAAAAFBgAAAAf/////CP////8DCgMLAwwDDQMOAw8DEAgDDQ4AAAAADwAAAAMQAAAAAxEDEgMTCAMNEgAAAAATAAAAAxQAAAAAAQABGAAAAgAAAAAAAAMAAQEAAP4ABAABBQAA+gAAAQAAAAAATMKDrcbEiTTQ/eQKOG4D5DzalNl+Bums

-- decompilation:
return {
	Name = "teleport",
	Description = "Teleports a player or set of players to one target.",
	Group = "DefaultAdmin",
	Aliases = { "tp" },
	AutoExec = {
		"alias \"bring|Brings a player or set of players to you.\" teleport $1{players|players|The players to bring} ${me}",
		"alias \"to|Teleports you to another player or location.\" teleport ${me} $1{player @ vector3|Destination|The player or location to teleport to}"
	},
	Args = {
		{
			Type = "players",
			Name = "From",
			Description = "The players to teleport"
		},
		{
			Type = "player @ vector3",
			Name = "Destination",
			Description = "The player to teleport to"
		}
	}
}

