-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTDUFzc2V0SXRlbURhdGEGYXNzZXJ0CURpcmVjdG9yeQhDYXRlZ29yeQZSYXJpdHkDX2lkBXBhaXJzC1N0ZWFsUmFyaXR5CVByb2R1Y3RJZAxHZXRQcm9kdWN0SWQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUGQXNzZXRzB0xpYnJhcnkFVHlwZXMJQXNzZXRJdGVtCFByb2R1Y3RzAAIIAQMAAAAl+wIAAE0CArwAAAAAUgMAAJ8CAgBMAQACpAECAAAAEECfAQAB+wIBAE0CApEDAAAATQMACwQAAACHAQIDTQEB8gUAAABNAQHTBgAAAKQCCAAAAHBA+wMCAE0DA5EDAAAAnwICBBcCBwBNBwZ5CQAAAJoHBAABAAAATQcGCwoAAACCBwIAbgL4/wIAAADGAgAAggICAAsDAQMCBAAAEEADAwMEAwUDBgMHBAAAcEADCAMJABIKARgAAAAAAAAAAAACAAAAAAAAAAAAAQAAAAAAAAEAAAABAAD+AAUAEwAAAAAGAAABAgAnowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAkQYAAABNAgKBBwAAAJ8BAgKkAgUAAABAQE0DAGoIAAAATQMD7wkAAABNAwPmCgAAAJ8CAgKkAwUAAABAQE0EAJEGAAAATQQEQQsAAACfAwIC/wQBAAAAAADABQwAEgACABIAAQASAAMAMAUE3w0AAACCBAIADgMLBAAAAEADDAMNAw4EAABAQAMDAw8DEAMRAxIDEwYAAwoBAAEAARgAAwAAAAAAAwAAAAAAAAEAAAAAAAAAAAEAAAAAAAADAAYAAAAAAAwBAAAAAAECO1AK607ejXD9m09Igxk8ciNHfjD/Ogs=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = require(ReplicatedStorage.Directory.Assets)
local AssetItem = require(ReplicatedStorage.Library.Types.AssetItem)
local Products = require(ReplicatedStorage.Directory.Products)

return {
	GetProductId = function(p1) -- line: 18
		-- upvalues: AssetItem (copy), Assets (copy), Products (copy)
		assert(AssetItem.AssetItemData(p1))

		local _id = Assets.Directory[p1.Category].Rarity._id

		for _, v in pairs(Products.Directory) do
			if _id == v.StealRarity then
				return v.ProductId
			end
		end

		return nil
	end
}

