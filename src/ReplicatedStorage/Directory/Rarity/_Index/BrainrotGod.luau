-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQHUHJpdmF0ZQtCYXNlQ29uZmlncwdTeXN0ZW1zDEZvcm1hdFJhcml0eQdEZWZhdWx0BE5hbWUGQXNzZXRzAlVJBlJhcml0eQtEaXNwbGF5TmFtZQtTcXVpc2h5IEdvZAxSYXJpdHlOdW1iZXISRGVmYXVsdFJhcml0eVZhbHVlEDEgaW4gMTAwLDAwMCwwMDAISXRlbVNsb3QIR3JhZGllbnQFQ29sb3IHTWVzc2FnZQhBbm5vdW5jZQZDb2xvcjMHZnJvbVJHQgABCQAAAQIAPKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQKQCBwAAAGBATQICJAgAAABNAgIkCAAAAE0CAgwJAAAATQICOgoAAABNAgImCwAAAE0CAjgMAAAATQICOg0AAACfAQICpAIHAAAAYEBNAgK6DgAAAE0EAIEPAAAATQQEXBAAAABNBATyEQAAAIcDBALiBB4ATQUDiRgAAAAwBQSJGAAAAE0FAz0ZAAAAMAUEPRkAAACkBSEAAIDwgYwGrACMBwAAjAjGAJ8FBAIwBQSkGgAAAFIFAQBvBhcAnwUCAjAFBPgbAAAAggQCACIDAQQAAABAAwIDAwMEBAAAQEADBQQAAGBAAwYDBwMIAwkDCgMLAwwDDQMOAw8DEAMRAxICAAAAAAAAGEADEwMUAxUDFgMXAxgDGQEACAgSEwAAABQVAAAAFhcAAAAY/////xn/////Gv////8b/////xwdAAAAAxoDGwQAgPCBAAEAARgAAQAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAMAAAACAAAAAAAAAwUAAAABAAAAAQAAAAAAAAACAAAAAAABAAAAAABLwgG6hSgEqz3jAlauCVPqO9oWznkGa7s=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Default = require(script.Parent.Parent.Private.BaseConfigs.Systems.FormatRarity.Default)
local scriptName = script.Name
local v4 = ReplicatedStorage.Assets.UI.Rarity[scriptName]

return {
	DisplayName = "Squishy God",
	RarityNumber = 6.0,
	DefaultRarityValue = "1 in 100,000,000",
	Announce = false,
	ItemSlot = v4.ItemSlot,
	Gradient = v4.Gradient,
	Color = Color3.fromRGB(172.0, 0.0, 198.0),
	Message = Default("1 in 100,000,000")
}

