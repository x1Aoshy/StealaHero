-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBnR5cGVvZgV0YWJsZQVwYWlycwhkZWVwQ29weQpkZWVwRXF1YWxzE2dldERpY3Rpb25hcnlMZW5ndGgABAkBAQAAABi7LAADUgIAAKQBAQAAAABAnwECAvABEQACAACA/wEAAAAAAACkAgQAAAAwQFIDAACfAgIEFwIGAPsHAABNBwflBQAAAFIIBgCfBwICagcBBW4C+f8CAAAAggECAIIAAgAGAwEEAAAAQAMCAwMEAAAwQAMEAAMEARgAAAAAAAAAAQABAAAAAAEAAAAAAP8AAwIEAAAAAAoCAQAAADW7LAADUgMAAKQCAQAAAABAnwICAvACKgACAACAuywBA1IDAQCkAgEAAAAAQJ8CAgLwAiMAAgAAgKQCBAAAADBAUgMAAJ8CAgQXAgkA+wcAAE0HB5MFAAAAUggGAIcJAQWfBwMCKwcCAKkHAACCBwIAbgL2/wIAAACkAgQAAAAwQFIDAQCfAgIEFwIJAPsHAABNBweTBQAAAFIIBgCHCQAFnwcDAisHAgCpBwAAggcCAG4C9v8CAAAAqQIBAIICAgDxAAIAAQAAAKkCAAGpAgEAggICAAYDAQQAAABAAwIDAwQAADBAAwUADwUBGAAAAAAAAAAAAAAAAAAAAQAAAAABAAAAAAAAAQD+AAUAAAAAAQAAAAAAAAEA/gAFAAIAAAAAEAAAAAAHAQAAAAAKjAEAAKQCAQAAAABAUgMAAJ8CAgQXAgEAlQEBAm4C/v8BAAAAggECAAMDAwQAAABAAgAAAAAAAPA/ACEGARgAAQAAAAAB/wADIgAAAAACAAABAgAPowAAAP8AAwAAAAAAwAEAABIAAAAwAQDlAQAAAMABAgASAAAAMAEAkwMAAADAAQQAMAEA9gUAAACCAAIABgYAAwQGAQMFBgIDBgMAAQIBAAEYAAAAAgAAAAwAAAASAAAIAQAAAAAD52j1LoQIoNauylDo6SvKm5dw4lrVrJ8v

-- decompilation:
local t1 = {}

function t1.deepCopy(p1) -- line: 3
	-- upvalues: t1 (copy)
	if typeof(p1) == "table" then
		local t2 = {}

		for k, v in pairs(p1) do
			t2[k] = t1.deepCopy(v)
		end

		return t2
	end

	return p1
end
function t1.deepEquals(p2, p3) -- line: 15
	-- upvalues: t1 (copy)
	if typeof(p2) == "table" and typeof(p3) == "table" then
		for k, v in pairs(p2) do
			if not t1.deepEquals(v, p3[k]) then
				return false
			end
		end

		for k, v in pairs(p3) do
			if not t1.deepEquals(v, p2[k]) then
				return false
			end
		end

		return true
	end

	return p2 == p3
end
function t1.getDictionaryLength(p4) -- line: 33
	local n1 = 0.0

	for _ in pairs(p4) do
		n1 += 1.0
	end

	return n1
end

return t1

