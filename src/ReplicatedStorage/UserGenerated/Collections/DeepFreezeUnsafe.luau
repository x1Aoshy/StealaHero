-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBHR5cGUFdGFibGUIaXNmcm96ZW4GZnJlZXplBG5leHQQRGVlcEZyZWV6ZVVuc2FmZQACCAEAAAALAAACDwQVCQ8FFQkhuygAA1ICAACkAQEAAAAAQJ8BAgLwAQIAAgAAAIIAAgCkAQQAAAwggFICAACfAQICKwEEAKQBBgAAFCCAUgIAAJ8BAgGkAQgAAABwQFICAADGAwAAFwEIADUGADAJAAAAUgcEAJ8GAgE1BgAwCQAAAFIHBQCfBgIBbgH3/wIAAACCAAIACgMBBAAAAEADAgMDBAAMIIADBAQAFCCAAwUEAABwQAMGAB8GARgAAAAAAAAAAQQAAAAAAQAAAAQAAAAAAQAAAAEAAAD+AAQgAAAAAAEAAAEDAAejAAAAwAAAABgAADABAAAANQAAMAEAAACCAAIAAgYAAwYBAAEAARgAHgAAEgAAAQAAAAABa1vX6EAz6HkoTVo7MlWPkBtDwJxZn73p

-- decompilation:
--!native
function DeepFreezeUnsafe(p1) -- line: 31
	if type(p1) ~= "table" then
		return p1
	end

	if not table.isfrozen(p1) then
		table.freeze(p1)
	end

	for k, v in next, p1 do
		DeepFreezeUnsafe(k)
		DeepFreezeUnsafe(v)
	end

	return p1
end

return DeepFreezeUnsafe

