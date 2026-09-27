-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBmlwYWlycwZzdHJpbmcFc3BsaXQBLgR0eXBlBXRhYmxlC1F1ZXJ5T2JqZWN0BG1hdGgDbWluFkhhc0hpZXJhcmNoaWNhbE92ZXJsYXAGZnJlZXplAAMKAwAAABAFAAIFAw8DDw8GCBMPBwgTKKQDAQAAAABApAQEAAAMIIBSBQEAbwYFAJ8EAwCfAwAEUQMSAEcAAwAAAACAqQgAAIIIAgCaAAMAAgAAAKkIAQCCCAIAuygAA1IJAACkCAcAAABgQJ8IAgLwCAMACAAAAKkIAACCCAIAhwAAB24D7f8CAACARwADAAAAAICpAwAAggMCAJoAAwACAAAAqQMBAIIDAgCpAwEAUgQAAIIDAwAJAwEEAAAAQAMCAwMEAAwggAMEAwUEAABgQAMGAB0HARgAAAAAAAAAAAABAAEAAgABAAIAAAAAAAABAAL2AAwAAQACAAEAAgAAHgAAAAAKAgAAABcEAAQFAgMDAgcVCg8CBB4PAwkZAgQOFCKaAAMAAQAAAKkCAQCCAgIApAICAAAEAIBSAwAAbwQDAJ8CAwKkAwIAAAQAgFIEAQBvBQMAnwMDAhwFAgAcBgMAnhMFAwYAAACkBAYAABRAgJ8EAwKMBwEAUgUEAIwGAQCoBQcAhwgCB4cJAwfxCAMACQAAAKkIAACCCAIAiwX5/6kFAQCCBQIABwMCAwMEAAQAgAMEAwgDCQQAFECAADkKARgAAAEAAgAAAAABAAAAAAEAAAAAAAABAAAAAQAAAAEA/gUAOgAAAAADAAABAwcAAAEPAAENDqMAAAD/AAIAAAAAAMABAAAwAQDcAQAAAMABAgAwAQCXAwAAAKQBBgAAFECAUgIAAJ8BAgCCAQAABwYAAwcGAQMKAwYDCwQAFECAAgABAQABGAATAAkAABwAAA8AAAAAAQAAAAACA23wCwAMpTM7KqROWKJoSnN1538xqZoK

-- decompilation:
--!native
local t1 = {
	QueryObject = function(p1, s1: string, p2) -- line: 29
		for _, v in ipairs(string.split(s1, ".")) do
			if p1 == nil then
				return false
			end

			if p1 == p2 then
				return true
			end

			if type(p1) ~= "table" then
				return false
			end

			p1 = p1[v]
		end

		if p1 == nil then
			return false
		end

		if p1 == p2 then
			return true
		end

		return true, p1
	end,
	HasHierarchicalOverlap = function(s2: string, s3: string) -- line: 57
		if s2 == s3 then
			return true
		end

		local parts = string.split(s2, ".")
		local parts2 = string.split(s3, ".")

		for i = 1.0, math.min(#parts, #parts2) do
			if parts[i] ~= parts2[i] then
				return false
			end
		end

		return true
	end
}

return table.freeze(t1)

