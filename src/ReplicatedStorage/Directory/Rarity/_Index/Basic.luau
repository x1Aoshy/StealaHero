-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQHUHJpdmF0ZQtCYXNlQ29uZmlncwdTeXN0ZW1zDEZvcm1hdFJhcml0eQdEZWZhdWx0BE5hbWUGQXNzZXRzAlVJBlJhcml0eQtEaXNwbGF5TmFtZQZDb21tb24MUmFyaXR5TnVtYmVyEkRlZmF1bHRSYXJpdHlWYWx1ZQYxIGluIDIISXRlbVNsb3QIR3JhZGllbnQFQ29sb3IHTWVzc2FnZQhBbm5vdW5jZQZDb2xvcjMHZnJvbVJHQgABCQAAAQIAPKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQKQCBwAAAGBATQICJAgAAABNAgIkCAAAAE0CAgwJAAAATQICOgoAAABNAgImCwAAAE0CAjgMAAAATQICOg0AAACfAQICpAIHAAAAYEBNAgK6DgAAAE0EAIEPAAAATQQEXBAAAABNBATyEQAAAIcDBALiBB4ATQUDiRgAAAAwBQSJGAAAAE0FAz0ZAAAAMAUEPRkAAACkBSEAAIDwgYwGlwCMB5cAjAiXAJ8FBAIwBQSkGgAAAFIFAQBvBhcAnwUCAjAFBPgbAAAAggQCACIDAQQAAABAAwIDAwMEBAAAQEADBQQAAGBAAwYDBwMIAwkDCgMLAwwDDQMOAw8DEAMRAxICAAAAAAAA8D8DEwMUAxUDFgMXAxgDGQEACAgSEwAAABQVAAAAFhcAAAAY/////xn/////Gv////8b/////xwdAAAAAxoDGwQAgPCBAAEAARgAAQAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAMAAAACAAAAAAAAAwUAAAABAAAAAQAAAAAAAAACAAAAAAABAAAAAACgXt3lOA/hO5XczrYEU1ii0EbKkZKat+Q=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Default = require(script.Parent.Parent.Private.BaseConfigs.Systems.FormatRarity.Default)
local scriptName = script.Name
local v4 = ReplicatedStorage.Assets.UI.Rarity[scriptName]

return {
	DisplayName = "Common",
	RarityNumber = 1.0,
	DefaultRarityValue = "1 in 2",
	Announce = false,
	ItemSlot = v4.ItemSlot,
	Gradient = v4.Gradient,
	Color = Color3.fromRGB(151.0, 151.0, 151.0),
	Message = Default("1 in 2")
}

