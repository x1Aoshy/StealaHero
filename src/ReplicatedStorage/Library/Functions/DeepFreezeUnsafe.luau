-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMFBHR5cGUFdGFibGUIaXNmcm96ZW4GZnJlZXplBXBhaXJzAAMIAQEAAAAeuygAA1ICAACkAQEAAAAAQJ8BAgLwARcAAgAAgKQBBAAADCCAUgIAAJ8BAgIrAQQApAEGAAAUIIBSAgAAnwECAaQBCAAAAHBAUgIAAJ8BAgQXAQYA+wYAAFIHBACfBgIB+wYAAFIHBQCfBgIBbgH5/wIAAACCAAEACQMBBAAAAEADAgMDBAAMIIADBAQAFCCAAwUEAABwQAABBAEYAAAAAAAAAAEAAAAAAQAAAAIAAAAAAQAAAQAA/gAFAgAAAAADAQEAAAAE+wEAAFICAACfAQIBggACAAAADQABGAAAAAEOAAAAAAIAAAECAAajAAAAwAAAABIAAADAAQEAEgAAAIIBAgACBgAGAQIAAQEAARgAAAAMAAABAAAAAALn2JDM8Pk0yvlkEfwMCcFcl8CHuNUc+s0=

-- decompilation:
local function freeze(p1) -- line: 1
	-- upvalues: freeze (copy)
	if type(p1) == "table" then
		if not table.isfrozen(p1) then
			table.freeze(p1)
		end

		for k, v in pairs(p1) do
			freeze(k)
			freeze(v)
		end
	end
end

return function(p2) -- line: 13
	-- upvalues: freeze (copy)
	freeze(p2)

	return p2
end

