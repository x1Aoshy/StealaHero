-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOA1J1bgROYW1lBGVjaG8HQWxpYXNlcwtEZXNjcmlwdGlvbh1FY2hvZXMgeW91ciB0ZXh0IGJhY2sgdG8geW91LgVHcm91cAtEZWZhdWx0VXRpbARBcmdzAT0EVHlwZQZzdHJpbmcEVGV4dAlUaGUgdGV4dC4AAgICAAAAAAGCAQIAAAAOAQEYAA8AAAAAAwAAAQIAFKMAAADiAAkA/wEAAAEAAABvAgoAxQECAgEAAAAwAQAnAgAAAP8BAAABAAAA4gIPAMUBAgIBAAAAMAEA2wcAAADAARAAMAEAFggAAACCAAIAEQMCAwMDBAMFAwYDBwMIAwkDAQgGAAEAAAAC/////wMEAAAABQYAAAAH/////wj/////AwoDCwMMAw0DDggDCwwAAAAADQAAAAMOAAAABgABAAEAARgAAAIAAAAAAAADAAEAAP8ACAAAAAEAAAAAAdGmX3vYO/cEDicrT6oQohKhvkgP42I1eg==

-- decompilation:
return {
	Name = "echo",
	Description = "Echoes your text back to you.",
	Group = "DefaultUtil",
	Aliases = { "=" },
	Args = {{
		Type = "string",
		Name = "Text",
		Description = "The text."
	}},
	Run = function(_, p2) -- line: 14
		return p2
	end
}

