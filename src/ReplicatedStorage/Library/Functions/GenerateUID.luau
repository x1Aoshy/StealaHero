-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMIDEdlbmVyYXRlR1VJRAEtAARnc3ViBWxvd2VyBGdhbWULSHR0cFNlcnZpY2UKR2V0U2VydmljZQACBAABAAAADvsAAACpAgAAvAAApAAAAACfAAMCbwIBAG8DAgC8AADMAwAAAJ8ABAK8AADvBAAAAJ8AAgCCAAAABQMBAwIDAwMEAwUAAwABGAAAAAAAAAAAAAAAAAAABAAAAAADAAABAgAKowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAsABBAASAAAAggECAAUDBgQAAABAAwcDCAYAAQABAAEYAAAAAAAAAAIAAAEAAAAAAQ==

-- decompilation:
local HttpService = game:GetService("HttpService")

return function() -- line: 3
	-- upvalues: HttpService (copy)
	return HttpService:GenerateGUID(false):gsub("-", ""):lower()
end

