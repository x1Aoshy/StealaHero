-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMFBHR5cGUFdGFibGUGaW5zZXJ0BG5leHQIZGVlcENvcHkAAgsBAQAAACu7KAADUgIAAKQBAQAAAABAnwECAvABJAACAACA/wEAAAAAAAAcAgAAjAMAAGADDwACAAAAjAUBAFIDAgCMBAEAqAMJAFIHAQD7CAAAhwkABZ8IAgBMNAACpAYEAAAMIICfBgABiwP3/4IBAgCkAwYAAABQQFIEAADGBQAAFwMHAPsIAABSCQYAnwgCAvsJAABSCgcAnwkCAmoJAQhuA/j/AgAAAIIBAgCCAAIABwMBBAAAAEADAgMDBAAMIIADBAQAAFBAAAEFARgAAAAAAAAAAQABAQAAAQAAAAEAAAAAAAAA/wMCAAAAAAEAAAAAAAD/AAMDAgAAAAABAAABAgAEowAAAMAAAAASAAAAggACAAEGAAEAAQABGAAAABQBAAAAAAEffCjPrxtfO+xO5pkKFNVjb2Q/uy24Qs4=

-- decompilation:
local function deepCopy(p1) -- line: 1
	-- upvalues: deepCopy (copy)
	if type(p1) == "table" then
		local t1 = {}
		local v4 = #p1

		if v4 > 0.0 then
			for i = 1.0, v4 do
				table.insert(t1, deepCopy(p1[i]))
			end

			return t1
		end

		for k, v in next, p1 do
			t1[deepCopy(k)] = deepCopy(v)
		end

		return t1
	end

	return p1
end

return deepCopy

