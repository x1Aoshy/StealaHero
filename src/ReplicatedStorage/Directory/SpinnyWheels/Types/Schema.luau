-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0CURyb3BUYWJsZQVJdGVtcwxDdXJyZW5jeUl0ZW0FdW5pb24HbGl0ZXJhbApCYXNpY1doZWVsDUFsbFdoZWVsTmFtZXMJaW50ZXJmYWNlC0Rpc3BsYXlOYW1lDFJlcXVpcmVkSXRlbQxJdGVtQ29vbGRvd24HV2VpZ2h0cwZzdHJpbmcNV3JhcEZvclRDaGVjawZudW1iZXIFYXJyYXkLSXNEcm9wVGFibGUNRGVmYXVsdENvbmZpZwABCQAAAQIAT6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQIC6AcAAABNAgLmCAAAAE0CApUJAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwN9CgAAAJ8CAgKkAwUAAABAQE0EAGoGAAAATQQEOAsAAABNBASRDAAAAJ8DAgL/BAIAAAAAAE0FAZgNAAAATQYBcw4AAABvBw8AnwYCAJ8FAAIwBQTCEAAAAE0FAS8RAAAA4gYWAE0HAUEXAAAAMAcGVxIAAAC8BwOIGAAAAJ8HAgIwBwYyEwAAAE0HAWAZAAAAMAcGhRQAAABNBwEdGgAAAE0IAWAZAAAAnwcCAjAHBlUVAAAATQcBHRoAAABNCAJAGwAAAJ8HAgIwBwZ9CgAAAJ8FAgIwBQQMHAAAAIIEAgAdAwEEAAAAQAMCAwMDBAQAAEBAAwUDBgMHAwgDCQMKAwsDDAMNAw4DDwMQAxEDEgMTAxQFBRITFBUKAxUDFgMXAxgDGQMaAAEAARgAAwAAAAAAAwAAAAAAAAAAAAABAAAAAAAAAQAAAAAAAAAAAwACAAAAAAAAAAACAAABAAAAAQAAAAABAAAAAQAAAAAAAAEAAAAAAAD7AAAIAQAAAAAAafXa/+akIVWRHs/9MfUbShntzYtbMbD+

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local DropTable = require(ReplicatedStorage.Library.DropTable)
local CurrencyItem = require(ReplicatedStorage.Library.Items.CurrencyItem)

return {
	AllWheelNames = t.union(t.literal("BasicWheel")),
	DefaultConfig = t.interface({
		DisplayName = t.string,
		RequiredItem = CurrencyItem:WrapForTCheck(),
		ItemCooldown = t.number,
		Weights = t.array(t.number),
		DropTable = t.array(DropTable.IsDropTable)
	})
}

