-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPBnNjcmlwdAZTdHlsZXMMV2FpdEZvckNoaWxkHHJieGFzc2V0aWQ6Ly8xMzIzNzYwMDg5NTg1ODkbcmJ4YXNzZXRpZDovLzc1ODk4NTY3MDYyODA5B2F0bGFzZXMLaW5mb3JtYXRpb24Gc3R5bGVzBmZhbWlseQdNYXJpbzY0BXNpemVzCHVzZUVudW1zB1JlZ3VsYXIEZm9udAdyZXF1aXJlAAEUAAABAABPowAAAP8AAgAAAAAApAEBAAAAAEBvAwIAvAEB0wMAAACfAQMC/wIAAAIAAABvAwQA9gMCAG8DBQD2AwIBMAIA1gYAAADiAgkA4gMPAP8EAAABAAAAbwUQAMUEBQIBAAAAMAQDgQgAAAD/BAAADwAAAIwFYACMBjwAjAcwAIwIKgCMCSQAjAogAIwLHACMDBgAjA0SAIwODgCMDwwAjBALAIwRCgCMEgkAjBMIAMUEBRABAAAAMAQD6gwAAAAwAwJ+BwAAAP8DAAAAAAAAMAMCgQgAAAAwAgAZEQAAAE0CABkRAAAATQICfgcAAABNAgKBCAAAAMYDAADGBAAAZAIMAE0HABkRAAAATQcHgQgAAACkCBMAAAAgQVILBgC8CQHTAwAAAJ8JAwCfCAACaggHBm4C8/8CAAAAggACABQDAQQAAABAAwIDAwMEAwUDBgMHAwgFAgcIAwkDCgMLAwwBAQgECgsAAAAI/////wz/////DQ4AAAADDQMOAw8EAAAgQQABAAEYAAcAAQAAAAAAAgABAAEA/gAFAQIAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAD9AAYAAAD5AAoAAAAAAAAAAAEAAAAAAAAAAAAAAP8ABAEAAAAAAIha7r4otO+9OlLAZ4VKIXn4QvnKup6Evw==

-- decompilation:
local t1 = {}
local Styles = script:WaitForChild("Styles")

t1.atlases = {
	[1.0] = "rbxassetid://132376008958589",
	[2.0] = "rbxassetid://75898567062809"
}
t1.font = {
	information = {
		family = "Mario64",
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

