-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMEBHR5cGUFdGFibGUEbmV4dApkZWVwRXF1YWxzAAILAgEAAABEmgADAAEAAACpAgEAggICALsoAANSAwAApAIBAAAAAECfAgIC8AIIAAIAAIC7KAEDUgMBAKQCAQAAAABAnwICAvACCQACAAAA8QAFAAAAAADxAQMAAQAAAKkCAQCCAgIAqQIAAIICAgAcAgAAHAMBAPECAwADAAAAqQIAAIICAgCkAgQAAAAwQFIDAADGBAAAFwIKAIcHAQVHBwYAAAAAAPsIAABSCQYAUgoHAJ8IAwIrCAIAqQgAAIIIAgBuAvX/AgAAAKQCBAAAADBAUgMBAMYEAAAXAgoAhwcABUcHBgAAAAAA+wgAAFIJBgBSCgcAnwgDAisIAgCpCAAAgggCAG4C9f8CAAAAqQIBAIICAgAFAwEEAAAAQAMCAwMEAAAwQAABBAEYAAABAAIAAAAAAAAAAAAAAAAAAQAAAAEAAgACAAAAAQACAAAAAAEBAAAAAAAAAQD9AAYAAAAAAQEAAAAAAAABAP0ABgACAAAAAAEAAAECAASjAAAAwAAAABIAAACCAAIAAQYAAQABAAEYAAAAHAEAAAAAAUiHgXFPDfbMg+x0tNDr5bw4n5YFekPrcA==

-- decompilation:
local function deepEquals(p1, p2) -- line: 1
	-- upvalues: deepEquals (copy)
	if p1 == p2 then
		return true
	end

	if type(p1) ~= "table" or type(p2) ~= "table" then
		if p1 ~= p1 and p2 ~= p2 then
			return true
		end

		return false
	end

	if #p1 ~= #p2 then
		return false
	end

	for k, v in next, p1 do
		local v6 = p2[k]

		if v6 == nil or not deepEquals(v, v6) then
			return false
		end
	end

	for k, v in next, p2 do
		local v9 = p1[k]

		if v9 == nil or not deepEquals(v, v9) then
			return false
		end
	end

	return true
end

return deepEquals

