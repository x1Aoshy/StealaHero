-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBFRvb2wIQ2F0ZWdvcnkMR2V0QXR0cmlidXRlCU11dGF0aW9ucwVTY2FsZQpJc0Zhdm9yaXRlBnN0cmluZwZnbWF0Y2gFW14sXSsEZ3N1YgxeJXMqKC4tKSVzKiQCJTEFdGFibGUGaW5zZXJ0BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQUR2V0UHJpY2VWYWx1ZUZvckl0ZW0HTGlicmFyeQdBc3NlcnRzAAIPAQIAAAYDAAAFAQdE+wEAAE0BAU4AAAAAUgIAAJ8BAgFvAwEAvAEAEgIAAACfAQMCbwQDALwCABICAAAAnwIDAm8FBAC8AwASAgAAAJ8DAwJvBgUAvAQAEgIAAACfBAMCRwEFAAAAAABHAgMAAAAAAEcDAwAAAACAjAUAAIIFAgD/BQAAAAAAAKQGCAAAHGCAUgcCAG8ICQCfBgMEZAYNAKQLCwAAKGCAUgwJAG8NDABvDg0AnwsEAp40BQULAAAAUg0FAFIOCwCkDBAAADzggJ8MAwFuBvL/AQAAAPsGAQDiBxEAMAEHCwEAAAAwBQcNAwAAADADB4QEAAAAKgQCAAEAAACpCAABqQgBADAIB9IFAAAAnwYCAIIGAAASAwEDAgMDAwQDBQMGAwcDCAQAHGCAAwkDCgQAKGCAAwsDDAMNAw4EADzggAUEAQMEBQALAAEYAAAAAAACAAAAAQAAAAEAAAABAAAAAgAAAAAAAQADAAEAAAAAAAEAAAAAAAEAAAAAAAD+AAUAAQABAAEAAQAAAAAA/AAMAAAAAAQAAAECABujAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQECkAgcAAABgQE0CAiQIAAAATQIC9wkAAACfAQICpAIFAAAAQEBNAwBqCgAAAE0DA4kLAAAAnwICAsADDAASAAIAEgABAIIDAgANAw8EAAAAQAMQAxEDEgQAAEBAAxMEAABgQAMUAxUDFgMXBgABAAEAARgAAwAAAAAAAwAAAAAAAAAAAQAAAAAAAAMAAAABAAAAAAH3oHRiZhcPt8tvB51nbGQUh7hjFsVkHmM=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPriceValueForItem = require(script.Parent.GetPriceValueForItem)
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(p1) -- line: 11
	-- upvalues: Asserts (copy), GetPriceValueForItem (copy)
	Asserts.Tool(p1)

	local Category = p1:GetAttribute("Category")
	local Mutations = p1:GetAttribute("Mutations")
	local Scale = p1:GetAttribute("Scale")
	local IsFavorite = p1:GetAttribute("IsFavorite")

	if Category == nil or (Mutations == nil or Scale == nil) then
		return 0.0
	end

	local t1 = {}

	for match in string.gmatch(Mutations, "[^,]+") do
		table.insert(t1, (string.gsub(match, "^%s*(.-)%s*$", "%1")))
	end

	return GetPriceValueForItem({
		Category = Category,
		Mutations = t1,
		Scale = Scale,
		IsFavorite = IsFavorite == true
	})
end

