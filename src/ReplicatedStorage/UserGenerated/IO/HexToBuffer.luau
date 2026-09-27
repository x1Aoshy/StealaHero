-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLF2hleCBsZW5ndGggbXVzdCBiZSBldmVuBmFzc2VydAZidWZmZXIGY3JlYXRlBnN0cmluZwRieXRlBWVycm9yEWludmFsaWQgaGV4IGF0ICUqBmZvcm1hdAd3cml0ZXU4C0hleFRvQnVmZmVyAAIQAQEAACcDAQgFAQMPAgcVKA8IFSgPCR0gDwooFQIGESwCAQA/DwIMMwIDEC8/HAEAACEEAQANBAIAAQAAAKkDAAGpAwEAgQEDBAIAAABvBAIApAIEAAAAMECfAgMBpAIHAAAYUIC2AwEAnwICAowDAACMBgEAUgQBAIwFAgCoBCkAlQoGCDQpAAUGCgAAUggAAFIJBgCkBwsAACiQgJ8HBAP7CgAAhwkKBysJCACkCg0AAADAQG8LDgBSDQYAvAsLjQ8AAACfCwMCnwoCAfsLAACHCgsIKwoIAKQLDQAAAMBAbwwOAJUOBgi8DAyNDwAAAJ8MAwKfCwIBWw8JEEMODwo0QwIFAw4AAFIMAgBSDQMApAsSAABEUICfCwQBlQMDCIsE1/+CAgIAEwIAAAAAAAAAQAIAAAAAAAAAAAMBAwIEAAAwQAMDAwQEABhQgAIAAAAAAADwPwMFAwYEACiQgAMHBAAAwEADCAMJAgAAAAAAADBAAwoEAERQgAAtCwEYAAEAAAAAAAAAAAAAAQAAAAEBAAAAAQAAAAAAAAABAAEBAAAAAAAAAAIAAQEAAAAAAAAAAgAAAAAAAAAAAfUNLgAAAAACAAABAwsAAAIPAAExDwEvAzKjAAAA/wAGAAAAAACMAQAA9gEAL4wBAQD2AQAwjAECAPYBADGMAQMA9gEAMowBBAD2AQAzjAEFAPYBADSMAQYA9gEANYwBBwD2AQA2jAEIAPYBADeMAQkA9gEAOIwBCgD2AQBAjAELAPYBAEGMAQwA9gEAQowBDQD2AQBDjAEOAPYBAESMAQ8A9gEARYwBCgD2AQBgjAELAPYBAGGMAQwA9gEAYowBDQD2AQBjjAEOAPYBAGSMAQ8A9gEAZcABAAASAAAAggECAAEGAAEAAQABGAATAAEAAQABAAEAAQABAAEAAQABAAEAAQABAAEAAQABAAEAAQABAAEAAQABAAEAAwAVAQAAAAAB9HJnlXzTaDYfBf1ImpBAIIRqcOHGtg2U

-- decompilation:
--!native
local t1 = {
	[48.0] = 0.0,
	[49.0] = 1.0,
	[50.0] = 2.0,
	[51.0] = 3.0,
	[52.0] = 4.0,
	[53.0] = 5.0,
	[54.0] = 6.0,
	[55.0] = 7.0,
	[56.0] = 8.0,
	[57.0] = 9.0,
	[65.0] = 10.0,
	[66.0] = 11.0,
	[67.0] = 12.0,
	[68.0] = 13.0,
	[69.0] = 14.0,
	[70.0] = 15.0,
	[97.0] = 10.0,
	[98.0] = 11.0,
	[99.0] = 12.0,
	[100.0] = 13.0,
	[101.0] = 14.0,
	[102.0] = 15.0
}

local function HexToBuffer(s1: string) -- line: 45
	-- upvalues: t1 (copy)
	local v4 = #s1

	assert(v4 % 2.0 == 0.0, "hex length must be even")

	local buf = buffer.create(v4 // 2.0)
	local n1 = 0.0

	for i = 1.0, v4, 2.0 do
		local v8, v9 = string.byte(s1, i, i + 1.0)
		local v10 = t1[v8]

		if not v10 then
			error(`invalid hex at { i }`)
		end

		local v11 = t1[v9]

		if not v11 then
			error(`invalid hex at { i + 1.0 }`)
		end

		buffer.writeu8(buf, n1, v10 * 16.0 + v11)
		n1 += 1.0
	end

	return buf
end

return HexToBuffer

