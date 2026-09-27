-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUBXBhaXJzDURpc3BsYXlJblNob3ANRXZlbnRTaG9wVHlwZQV0YWJsZQZmcmVlemUMYnVpbGRDYXRhbG9nBENvc3QETmFtZQZDb25maWcJTW9uZXlDb3N0BHNvcnQTYnVpbGRDYXRhbG9nRW50cmllcwRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQlEaXJlY3RvcnkFR2VhcnMHQ2F0YWxvZw5DYXRhbG9nRW50cmllcwAECAEAAAAAGP8BAAAAAAAApAIBAAAAAEBSAwAAnwICBBcCCgBNBwZmAgAAACoHBwAAAAAATQcG2QMAAABHBwMAAAAAgKkHAQBqBwEFbgL1/wIAAACkAgYAABRAgFIDAQCfAgIAggIAAAcDAQQAAABAAwIDAwMEAwUEABRAgAAZBgEYAAABAAAAAAEAAAAAAAAAAQD+AAYAAAAAGgAAAAAFAgAAAAcEAAAFAgQEGE0CACMAAAAATQMBIwAAAACaAgoAAwAAAE0DALoBAAAATQQBugEAAAC3AwIABAAAAKkCAAGpAgEAggICAE0DACMAAAAATQQBIwAAAAC3AwIABAAAAKkCAAGpAgEAggICAAIDBwMIADEAARgAAAAAAAABAAAAAAAAAAADAAAAAAAAAAAyAAAAAAwBAAAAACv/AQAAAAAAAKQCAQAAAABAUgMAAJ8CAgQXAhgATQcGZgIAAAAqBxUAAAAAAE0HBtkDAAAARwcRAAAAAIAcCAEAlQcIBKQIBwAAGFCA4gkLADAFCboIAAAATQsG4Q0AAACQCgsMMAoJIwkAAAAwBgnZCgAAAJ8IAgJqCAEHbgLn/wIAAACkAg8AADhQgFIDAQDABBAAnwIDAaQCBwAAGFCAUgMBAJ8CAgCCAgAAEQMBBAAAAEADAgMDAgAAAAAAAPA/AwQDBQQAGFCAAwgDBwMJBQMICQoCAAAAAAAAAAADCgMLBAA4UIAGAQEBJAwBGAAAAgAAAAABAAAAAAAAAAEAAAAAAQABAAAAAAEA/QD+AAoAAAAACAAAAAAlAAAAAAcAAAECAB6jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgCRBgAAAE0CArMHAAAAnwECAsACCADAAwkA4gQMAFIFAgBNBgGRBgAAAJ8FAgIwBQRiCgAAAFIFAwBNBgGRBgAAAJ8FAgIwBQSpCwAAAIIEAgANAw0EAAAAQAMOAw8DEAQAAEBAAxEDEgYABgIDEwMUBQIKCwIAAgEAARgAAwAAAAAAAwAAAAAAABILGAEAAAAAAAEAAAAAAAABAAAAAANU8tmbQpBqV2Ka0RXHA/EPJOrO72Y2s5o=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Gears = require(ReplicatedStorage.Directory.Gears)

local function buildCatalog(p1) -- line: 25
	local t1 = {}

	for k, v in pairs(p1) do
		if v.DisplayInShop ~= false and v.EventShopType == nil then
			t1[k] = true
		end
	end

	return table.freeze(t1)
end
local function buildCatalogEntries(p2) -- line: 36
	local t2 = {}

	for k, v in pairs(p2) do
		if v.DisplayInShop ~= false and v.EventShopType == nil then
			t2[#t2 + 1.0] = table.freeze({
				Name = k,
				Cost = v.MoneyCost or 0.0,
				Config = v
			})
		end
	end

	table.sort(t2, function(t3: {[any]: any}, t4: {[any]: any}) -- line: 49
		if t3.Cost == t4.Cost then
			return t3.Name < t4.Name
		end

		return t3.Cost < t4.Cost
	end)

	return table.freeze(t2)
end

return {
	Catalog = buildCatalog(Gears.Directory),
	CatalogEntries = buildCatalogEntries(Gears.Directory)
}

