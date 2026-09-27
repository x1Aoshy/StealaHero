-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0CXdvcmtzcGFjZQlfX09CSkVDVFMMV2FpdEZvckNoaWxkCkhpZ2hsaWdodHMFdGFibGUGZnJlZXplBVdoaXRlBUJsYWNrB1JhaW5ib3cHQnlDb2xvchBTY2hlbWFWYWxpZGF0aW9uBXVuaW9uB2xpdGVyYWwSQWxsSGlnaGxpZ2h0Q29sb3JzAAEKAAABAgBMowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLoBwAAAE0CAuYIAAAATQIClQkAAACfAQICpAILAAAAoEBvBAwAvAIC0w0AAACfAgMCbwQOALwCAtMNAAAAnwIDAv8DAgAAAAAApAQRAABA8IDiBRUAbwgSALwGAtMNAAAAnwYDAjAGBX8SAAAAbwgTALwGAtMNAAAAnwYDAjAGBboTAAAAbwgUALwGAtMNAAAAnwYDAjAGBXQUAAAAnwQCAjAEA0MWAAAA/wQBAAAAAAAwBAPfFwAAAE0FAZgYAAAATQYBcxkAAABvBxIAnwYCAk0HAXMZAAAAbwgTAJ8HAgJNCAFzGQAAAG8JFACfCAIAnwUAAjAFBKAaAAAAggMCABsDAQQAAABAAwIDAwMEBAAAQEADBQMGAwcDCAMJBAAAoEADCgMLAwwDDQMOBABA8IADDwMQAxEFAxITFAMSAxMDFAMVAxYAAQABGAADAAAAAAADAAAAAAAAAAAAAAMAAAAAAAAAAAADAAIAAAEAAAAAAAEAAAAAAAEAAAAAAP0AAAoAAQACAAAAAAAAAAAAAAAAAAAAAAIBAAAAAADTPftc5VbkcB6sFNrzdeeloyXsKOH5kV0=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local Highlights = workspace:WaitForChild("__OBJECTS"):WaitForChild("Highlights")
local t1 = {
	ByColor = table.freeze({
		White = Highlights:WaitForChild("White"),
		Black = Highlights:WaitForChild("Black"),
		Rainbow = Highlights:WaitForChild("Rainbow")
	})
}
local t2 = {}

t1.SchemaValidation = t2
t2.AllHighlightColors = t.union(t.literal("White"), t.literal("Black"), t.literal("Rainbow"))

return t1

