-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQHUHJpdmF0ZQtCYXNlQ29uZmlncwdTeXN0ZW1zDEZvcm1hdFJhcml0eQdEZWZhdWx0BE5hbWUGQXNzZXRzAlVJBlJhcml0eQtEaXNwbGF5TmFtZQxSYXJpdHlOdW1iZXISRGVmYXVsdFJhcml0eVZhbHVlCDEgaW4gMjAwCEl0ZW1TbG90CEdyYWRpZW50BUNvbG9yB01lc3NhZ2UIQW5ub3VuY2UGQ29sb3IzB2Zyb21SR0IAAQkAAAECAD6jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQECkAgcAAABgQE0CAiQIAAAATQICJAgAAABNAgIMCQAAAE0CAjoKAAAATQICJgsAAABNAgI4DAAAAE0CAjoNAAAAnwECAqQCBwAAAGBATQICug4AAABNBACBDwAAAE0EBFwQAAAATQQE8hEAAACHAwQC4gQdADACBFcSAAAATQUDiRcAAAAwBQSJFwAAAE0FAz0YAAAAMAUEPRgAAACkBSAAAHzggYwGAACMB90AjAhCAJ8FBAIwBQSkGQAAAFIFAQBvBhYAnwUCAjAFBPgaAAAAggQCACEDAQQAAABAAwIDAwMEBAAAQEADBQQAAGBAAwYDBwMIAwkDCgMLAwwDDQMOAw8DEAMRAgAAAAAAAABAAxIDEwMUAxUDFgMXAxgBAAgIEv////8TFAAAABUWAAAAF/////8Y/////xn/////Gv////8bHAAAAAMZAxoEAHzggQABAAEYAAEAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAADAAAAAgAAAAAAAAMBAAQAAAABAAAAAQAAAAAAAAACAAAAAAABAAAAAACr+e7MWyVTfOb+PeLsresd2+H5uJk9hM0=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Default = require(script.Parent.Parent.Private.BaseConfigs.Systems.FormatRarity.Default)
local scriptName = script.Name
local v4 = ReplicatedStorage.Assets.UI.Rarity[scriptName]

return {
	RarityNumber = 2.0,
	DefaultRarityValue = "1 in 200",
	Announce = false,
	DisplayName = scriptName,
	ItemSlot = v4.ItemSlot,
	Gradient = v4.Gradient,
	Color = Color3.fromRGB(0.0, 221.0, 66.0),
	Message = Default("1 in 200")
}

