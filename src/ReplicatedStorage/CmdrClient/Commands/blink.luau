-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSCEV4ZWN1dG9yCEdldE1vdXNlCUNoYXJhY3RlchtZb3UgZG9uJ3QgaGF2ZSBhIGNoYXJhY3Rlci4DSGl0AXAGTW92ZVRvCEJsaW5rZWQhCUNsaWVudFJ1bgROYW1lBWJsaW5rB0FsaWFzZXMLRGVzY3JpcHRpb24uVGVsZXBvcnRzIHlvdSB0byB3aGVyZSB5b3VyIG1vdXNlIGlzIGhvdmVyaW5nLgVHcm91cAxEZWZhdWx0RGVidWcEQXJncwFiAAIGAQAAAAAVTQEA/wAAAAC8AQEjAQAAAJ8BAgJNAgD/AAAAAE0CAmkCAAAAKwICAG8DAwCCAwIATQUB+wQAAABNBQWRBQAAALwDAncGAAAAnwMDAW8DBwCCAwIACAMBAwIDAwMEAwUDBgMHAwgACAkBGAAAAAAAAQAAAAIBAAMAAAAAAAACAAwAAAAAAwAAAQIAEaMAAADiAAkA/wEAAAEAAABvAgoAxQECAgEAAAAwAQAnAgAAAP8BAAAAAAAAMAEA2wcAAADAAQsAMAEAMwgAAACCAAIADAMKAwsDDAMNAw4DDwMQAxEDCQgGAAEAAAAC/////wMEAAAABQYAAAAH/////wj/////AxIGAAEAAQABGAAAAgAAAAAAAAMAAAACAAAAAQAAAAABiU083odHkaMfQIq0yimusvlVK6q7iVbf

-- decompilation:
return {
	Name = "blink",
	Description = "Teleports you to where your mouse is hovering.",
	Group = "DefaultDebug",
	Aliases = { "b" },
	Args = {},
	ClientRun = function(p1) -- line: 8
		local Mouse = p1.Executor:GetMouse()
		local Character = p1.Executor.Character

		if not Character then
			return "You don't have a character."
		end

		Character:MoveTo(Mouse.Hit.p)

		return "Blinked!"
	end
}

