-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBnN0cmluZwZmb3JtYXQdQ2Fubm90IHJlYXNzaWduICVzIGluIGNvbnRleHQIdG9zdHJpbmcGYXNzZXJ0Cl9fbmV3aW5kZXgHX19pbmRleAVwYWlycwxnZXRtZXRhdGFibGUMc2V0bWV0YXRhYmxlA25ldwADCQMBAAAAFvsGAACHBQYBRwUCAAAAAACpBAABqQQBAKQFAgAABACAbwYDALs/AQNSCAEApAcFAAAAQECfBwICnwUDAEwBAAKkAwcAAABgQJ8DAAH7AwAAagIDAYIAAQAIAwEDAgQABACAAwMDBAQAAEBAAwUEAABgQAASBgEYAAAAAAAAAAAAAAAAAAAAAAAAAAEAARMAAAAACAEAAAAAI/8BAgAAAAAA/wIAAAAAAAAwAgFuAAAAAA4ADwCkAwIAAAAQQLs8AANSBwAApAYEAAAAMECfBgICUgQGAE0EBG4AAAAAnwMCBBcDAQBqBwIGbgP+/wIAAADZAwAAEgACADADAc4FAAAA/wQAAAAAAACePQQEAQAAAFIFAQCkAwcAAABgQJ8DAwKCAwIACAMHAwgEAAAQQAMJBAAAMEADBgMKBAAAYEABAAcLARgAAAEAAQACAQAAAAAAAAAAAAAAAf8ABQAAAAUAAAAAAAAAAAgAAAAAAgAAAQIAB6MAAAD/AAEAAAAAAMABAAAwAQDvAQAAAIIAAgACBgEDCwEBAQABGAAEAAIAABMBAAAAAAJBDtE4Eqga4u1LN2T02maZMRbGTHPKuzk=

-- decompilation:
return {
	new = function(p1) -- line: 7
		local t1 = {}
		local t2 = {}

		t1.__index = t2

		if p1 then
			for k, v in pairs(getmetatable(p1).__index) do
				t2[k] = v
			end
		end

		function t1.__newindex(_, p3, p4) -- line: 18
			-- upvalues: t2 (copy)
			assert(t2[p3] == nil, string.format("Cannot reassign %s in context", (tostring(p3))))
			t2[p3] = p4
		end

		return (setmetatable({}, t1))
	end
}

