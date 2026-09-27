-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMCBHRhc2sFZGVsYXkABAEAAQAAAAOpAAAA3gAAAIIAAQAAAAgAARgAAAEJAAAAAAUCAQAABwQAAAUCAoUR+wIAAA4CAgCpAgAAggICAKkCAQDeAgAApAICAAAEAIBSAwAA2QQAABICAACfAgMBDgECAFICAQCfAgEBqQIBAIICAgADAwEDAgQABACAAQADAAEYAAABAAIAAQAAAAAAAwEAAgAEAAAAAAIAAAAAAAWpAAAA2QEAABIBAP/BAAAAggECAAABAQEAARgAAQAAAAIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAgECAQABGAAAAAEAAAAAAw==

-- decompilation:
return function() -- line: 1
	local u1 = false

	return function(n1: number, p1: ((...any) -> ...any)?) -- line: 3
		-- upvalues: u1 (ref)
		if u1 then
			return false
		end

		u1 = true
		task.delay(n1, function() -- line: 8
			-- upvalues: u1 (ref)
			u1 = false
		end)

		if p1 then
			p1()
		end

		return true
	end
end

