-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMBAV8AAwQBAQEAAA2jAQAA+wIAAIcBAgArAQMA+wIAAE0BAn4AAAAAKwEBAIIAAQBSAgEA3QMAAJ8CAACCAgAAAQMBAAIAARgAAQAAAAAAAQEDAAAAAgAAAAACAQAAAAYDAAAFAQQD2QEAABIAAACCAQIAAAEAAQABGAAAAAIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAQEBAQABGAAAAAEAAAAAAg==

-- decompilation:
return function(t1: {[any]: any}) -- line: 1
	return function(p1, ...) -- line: 2
		-- upvalues: t1 (copy)
		local v3 = t1[p1] or t1._

		if not v3 then
			return
		end

		return v3(...)
	end
end

