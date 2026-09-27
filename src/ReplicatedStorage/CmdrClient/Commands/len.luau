-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPASwFc3BsaXQDUnVuBE5hbWUDbGVuB0FsaWFzZXMLRGVzY3JpcHRpb24sUmV0dXJucyB0aGUgbGVuZ3RoIG9mIGEgY29tbWEtc2VwYXJhdGVkIGxpc3QFR3JvdXALRGVmYXVsdFV0aWwEQXJncwRUeXBlBnN0cmluZwNDU1YYVGhlIGNvbW1hLXNlcGFyYXRlZCBsaXN0AAIGAgAAAAAGbwUAALwDAeMBAAAAnwMDAhwCAwCCAgIAAgMBAwIADgMBGAAAAAAAAA8AAAAAAwAAAQIAEaMAAADiAAkA/wEAAAAAAAAwAQAnAgAAAP8BAAABAAAA4gIOAMUBAgIBAAAAMAEA2wcAAADAAQ8AMAEAFggAAACCAAIAEAMEAwUDBgMHAwgDCQMKAwsDAwgGAAEAAAAC/////wMEAAAABQYAAAAH/////wj/////AwwDDQMOAw8IAwoLAAAAAAwAAAADDQAAAAYAAQABAAEYAAACAAAAAwABAAD/AAgAAAABAAAAAAHV/n0YPKaTVkXJ+I1i3GBGpeZqbOc6Fxk=

-- decompilation:
return {
	Name = "len",
	Description = "Returns the length of a comma-separated list",
	Group = "DefaultUtil",
	Aliases = {},
	Args = {{
		Type = "string",
		Name = "CSV",
		Description = "The comma-separated list"
	}},
	Run = function(_, p2) -- line: 14
		return #p2:split(",")
	end
}

