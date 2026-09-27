-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVDEJhc2VNdXRhdGlvbgV0YWJsZQRmaW5kCU11dGF0aW9ucwtoYXNNdXRhdGlvbg1Bc3NldEl0ZW1EYXRhF0ludmFsaWQgYXNzZXQgaXRlbSBkYXRhBmFzc2VydAdSYWluYm93BkdvbGRlbgZTaWx2ZXINR2V0TXVsdGlwbGllcgRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5BVR5cGVzCUFzc2V0SXRlbQdNb2R1bGVzD0dldE11dGF0aW9uc01hcAADBgIAAAAHBAAABQIPAxCpAgEATQMAJAAAAADxAwsAAQAAAKQDAwAACBCATQQADQQAAABSBQEAnwMDAkcDAgAAAACAqQIAAakCAQCCAgIABQMBAwIDAwQACBCAAwQAFAUBGAAAAAAAAAAAAAAAAAAAAAAVAAAAAAYBAgAAAEz7AgAATQICvAAAAABSAwAAnwICAoEBAgQBAAAAbwMBAKQBAwAAACBAnwEDAfsCAQBNAgJ0BAAAAKkBAQBNAwAkBQAAAPEDCwACAAAApAMIAAAcYIBNBAANCQAAAFIFAgCfAwMCRwMCAAAAAICpAQABqQEBAA4BAgCMAQIAggECAPsCAQBNAgJ4CgAAAKkBAQBNAwAkBQAAAPEDCwACAAAApAMIAAAcYIBNBAANCQAAAFIFAgCfAwMCRwMCAAAAAICpAQABqQEBAA4BAgBvAQsAggECAPsCAQBNAgJCDAAAAKkBAQBNAwAkBQAAAPEDCwACAAAApAMIAAAcYIBNBAANCQAAAFIFAgCfAwMCRwMCAAAAAICpAQABqQEBAA4BAgBvAQ0AggECAIwBAQCCAQIADgMGAwcDCAQAACBAAwkDAQMCAwMEABxggAMEAwoCAAAAAAAA4D8DCwJmZmZmZmbmPwAcDAEYCAAAAAAAAAAAAAACAAD2AAAAAAAAAAAAAAAAAAAACwABAAD0AAAAAAAAAAAAAAAAAAAADQABAADyAAAAAAAAAAAAAAAAAAAADwADABUAAAAABwAAAQIAJaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQIC7wcAAABNAgLmCAAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMD6AkAAABNAwMNCgAAAJ8CAgJNAwIuCwAAAJ8DAQL/BAEAAAAAAMAFDADABg0AEgABABIAAwAwBgTwDgAAAIIEAgAPAw0EAAAAQAMOAw8DEAQAAEBAAxEDEgMTAxQDBAMVBgAGAQMMAgABAQABGAADAAAAAAADAAAAAAAAAAABAAAAAAAAAAADAAADAAYIAAAAAA4BAAAAAAJ/8PGQO0iGenrvkPDhtTN3D+jm5E00m5E=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetItem = require(ReplicatedStorage.Library.Types.AssetItem)
local v3 = require(ReplicatedStorage.Library.Modules.Mutations).GetMutationsMap()
local t1 = {}

local function hasMutation(p1, s1: string) -- line: 20
	return s1 == p1.BaseMutation or table.find(p1.Mutations, s1) ~= nil
end

function t1.GetMultiplier(p2) -- line: 28
	-- upvalues: AssetItem (copy), v3 (copy)
	assert(AssetItem.AssetItemData(p2), "Invalid asset item data")

	local Rainbow = v3.Rainbow

	if Rainbow == p2.BaseMutation or table.find(p2.Mutations, Rainbow) ~= nil then
		return 2.0
	end

	local Golden = v3.Golden

	if Golden == p2.BaseMutation or table.find(p2.Mutations, Golden) ~= nil then
		return 0.5
	end

	local Silver = v3.Silver

	if Silver == p2.BaseMutation or table.find(p2.Mutations, Silver) ~= nil then
		return 0.7
	end

	return 1.0
end

return t1

