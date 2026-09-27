-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMDBHR5cGUFdGFibGUEbmV4dAACAwAAAQAAI6MAAADdAAIAKwADAP8BAAAAAAAAggECALsoAANSAgAApAEBAAAAAECfAQIC8AEHAAIAAAD/AQAAAAAAAN0CAADFAQIAAQAAAIIBAgAcAQAAjAIAAH0BDAACAAAApAEEAAAAMEBSAgAAnwECAg4BBgD/AQAAAAAAAN0CAADFAQIAAQAAAIIBAgCCAAIABQMBBAAAAEADAgMDBAAAMEAAAQABGAABAQEAAAIAAAAAAAABAAAAAAACAAAAAAAAAAABAAAAAAACAQAAAAABAAABAgADowAAAMAAAACCAAIAAQYAAQABAAEYAAAAAQAAAAAB0ziXr01/ReFvh4KcFYCDX6MggNvh/P2u

-- decompilation:
return function(...) -- line: 1
	local v1 = ...

	if not v1 then
		return {}
	end

	if type(v1) ~= "table" then
		return { ... }
	end

	if #v1 <= 0.0 and next(v1) then
		return { ... }
	end

	return v1
end

