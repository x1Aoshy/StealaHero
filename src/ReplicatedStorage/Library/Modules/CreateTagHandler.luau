-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKA1RhZw9Pbkluc3RhbmNlQWRkZWQRT25JbnN0YW5jZVJlbW92ZWQJR2V0VGFnZ2VkFkdldEluc3RhbmNlQWRkZWRTaWduYWwHQ29ubmVjdBhHZXRJbnN0YW5jZVJlbW92ZWRTaWduYWwEZ2FtZRFDb2xsZWN0aW9uU2VydmljZQpHZXRTZXJ2aWNlAAQBAQAAAAABggABAAAABQABGAAFAAAAAAEBAAAAAAGCAAEAAAAGAAEYAAYAAAAACwEBAAAAKE0BAF8AAAAATQIASQEAAAArAgEAwAICAE0DAHoDAAAAKwMBAMADBAD7BAAAUgYBALwEBAUFAAAAnwQDBGQEAwBSCQIAUgoIAJ8JAgFuBPz/AgAAAPsEAABSBgEAvAQEXgYAAACfBAMCUgYCALwEBMcHAAAAnwQDAfsEAABSBgEAvAQE3AgAAACfBAMCUgYDALwEBMcHAAAAnwQDAYIAAQAJAwEDAgYAAwMGAQMEAwUDBgMHAgABAwABGAAAAQAAAAEAAAACAAAAAAABAAD/AAQAAAAAAAAAAAEAAAAAAAAAAAEEAAAAAAMAAAECAAqjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCwAEEABIAAACCAQIABQMIBAAAAEADCQMKBgIBAgEAARgAAAAAAAAAAgAAAQAAAAADi2wCgIAUR1VBXO20juPczvt0FfS5qGiB

-- decompilation:
local CollectionService = game:GetService("CollectionService")

return function(p1) -- line: 3
	-- upvalues: CollectionService (copy)
	local Tag = p1.Tag
	local v4 = p1.OnInstanceAdded or function(_) -- line: 5
	end
	local v5 = p1.OnInstanceRemoved or function(_) -- line: 6
	end

	for _, v7 in CollectionService:GetTagged(Tag) do
		v4(v7)
	end

	CollectionService:GetInstanceAddedSignal(Tag):Connect(v4)
	CollectionService:GetInstanceRemovedSignal(Tag):Connect(v5)
end

