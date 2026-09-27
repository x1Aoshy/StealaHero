-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPBnNjcmlwdAZTdHlsZXMMV2FpdEZvckNoaWxkHHJieGFzc2V0aWQ6Ly8xMTM4MzY1MzY3NDk5MzEccmJ4YXNzZXRpZDovLzEwNjAyNzc3MDUxNTU2OAdhdGxhc2VzC2luZm9ybWF0aW9uBnN0eWxlcwZmYW1pbHkITWFyaW8yNTYFc2l6ZXMIdXNlRW51bXMHUmVndWxhcgRmb250B3JlcXVpcmUAARQAAAEAAE+jAAAA/wACAAAAAACkAQEAAAAAQG8DAgC8AQHTAwAAAJ8BAwL/AgAAAgAAAG8DBAD2AwIAbwMFAPYDAgEwAgDWBgAAAOICCQDiAw8A/wQAAAEAAABvBRAAxQQFAgEAAAAwBAOBCAAAAP8EAAAPAAAAjAVgAIwGPACMBzAAjAgqAIwJJACMCiAAjAscAIwMGACMDRIAjA4OAIwPDACMEAsAjBEKAIwSCQCMEwgAxQQFEAEAAAAwBAPqDAAAADADAn4HAAAA/wMAAAAAAAAwAwKBCAAAADACABkRAAAATQIAGREAAABNAgJ+BwAAAE0CAoEIAAAAxgMAAMYEAABkAgwATQcAGREAAABNBweBCAAAAKQIEwAAACBBUgsGALwJAdMDAAAAnwkDAJ8IAAJqCAcGbgLz/wIAAACCAAIAFAMBBAAAAEADAgMDAwQDBQMGAwcDCAUCBwgDCQMKAwsDDAEBCAQKCwAAAAj/////DP////8NDgAAAAMNAw4DDwQAACBBAAEAARgABwABAAAAAAACAAEAAQD+AAUBAgAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAP0ABgAAAPkACgAAAAAAAAAAAQAAAAAAAAAAAAAA/wAEAQAAAAAAdE0M19RGKIbSVCvzTGlZlQRVG6NGiWbW

-- decompilation:
local t1 = {}
local Styles = script:WaitForChild("Styles")

t1.atlases = {
	[1.0] = "rbxassetid://113836536749931",
	[2.0] = "rbxassetid://106027770515568"
}
t1.font = {
	information = {
		family = "Mario256",
		useEnums = true,
		styles = { "Regular" },
		sizes = {
			96.0,
			60.0,
			48.0,
			42.0,
			36.0,
			32.0,
			28.0,
			24.0,
			18.0,
			14.0,
			12.0,
			11.0,
			10.0,
			9.0,
			8.0
		}
	},
	styles = {}
}

for _, v4 in t1.font.information.styles do
	t1.font.styles[v4] = require(Styles:WaitForChild(v4))
end

return t1

