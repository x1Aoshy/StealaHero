-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMHBXN0YXJ0BXRhYmxlBmluc2VydANhZGQNY3VycmVudExlbmd0aAtjdXJyZW50TmFtZQVlbXB0eQAGAgECAAAGAwAABQEDBf8BAAAAAAAA3gEAAN4AAQCCAAEAAAAKAQEYAAAAAQELAAAAAAQBAQAAAAv7AQAAKwEBAIIAAQD7AgAAnjQCBAAAAABSAwAApAECAAAEAICfAQMBggABAAMDAgMDBAAEAIAADwQBGAAAAQMAAAAAAAABEAAAAAACAAEAAAAH+wEAAA4BAwD7AQAAHAABAIIAAgCMAAAAggACAAAAFwUBGAAAAAAAAAAYAAAAAAEAAQAAAAL7AAAAggACAAAAGwYBGAAAHAAAAAACAAEAAAAK+wAAAEcABAAAAACA/wAAAAAAAACCAAIA+wAAAMYBAADeAQAAggACAAAAHwcBGAAAAAEAAAMBAAIgAAAAAAQAAAECAByjAAAAxgAAAMYBAAD/AgQAAAAAANkDAAASAQD/EgEB/zADAvwAAAAA2QMBABIBAP8wAwK/AQAAANkDAgASAQD/MAMCXAIAAADZAwMAEgEB/zADAl4DAAAA2QMEABIBAP8wAwKtBAAAAMEAAACCAgIABQMBAwQDBQMGAwcFAAECAwQBAAEYAAQBAgACAAAAAAUAAAAIAAAABAAAAAQAAAALAAEAAAAABSk/CtybFqIbJ/2hEHUY7IlZJx2oG/tg3Q==

-- decompilation:
local t1 = nil
local u2 = nil

return {
	start = function(s1: string) -- line: 10
		-- upvalues: t1 (ref), u2 (ref)
		t1 = {}
		u2 = s1
	end,
	add = function(p1) -- line: 15
		-- upvalues: t1 (ref)
		if not t1 then
			return
		end

		table.insert(t1, p1)
	end,
	currentLength = function() -- line: 23
		-- upvalues: t1 (ref)
		if t1 then
			return #t1
		end

		return 0.0
	end,
	currentName = function() -- line: 27
		-- upvalues: u2 (ref)
		return u2
	end,
	empty = function() -- line: 31
		-- upvalues: t1 (ref)
		if t1 == nil then
			return {}
		end

		local v5 = t1

		t1 = nil

		return v5
	end
}

