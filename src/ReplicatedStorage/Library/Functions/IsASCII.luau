-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMEBHR5cGUGc3RyaW5nBmFzc2VydARieXRlAAIIAQAAAAAhuygAA1IDAACkAgEAAAAAQJ8CAgLwAgIAAgAAAKkBAAGpAQEAuwEBA1IDAQCkAgQAAAAwQJ8CAgGMBAEAHAIAAIwDAQCoAg0AUgcEALwFANwFAAAAnwUDAowGIAC3BQQABgAAAIwGfgBgBgMABQAAAKkGAACCBgIAiwLz/6kCAQCCAgIABgMBBAAAAEADAgMDBAAAMEADBAABAAEYAAAAAAAAAAAAAQAAAAADAAAAAQAAAAEAAAAAAAEA/QcAAwAAAAABAAABAgADowAAAMAAAACCAAIAAQYAAQABAAEYAAAAAQAAAAABrqFIeLrydXekgJ0W6gFXvN65XwycZSJ5

-- decompilation:
return function(p1) -- line: 1
	assert(type(p1) == "string")

	for i = 1.0, #p1 do
		local v3 = p1:byte(i)

		if v3 < 32.0 or v3 > 126.0 then
			return false
		end
	end

	return true
end

