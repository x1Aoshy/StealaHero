-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJBHR5cGUGbnVtYmVyBmFzc2VydAUlKmUlKgZzdHJpbmcGZm9ybWF0AiVmCHRvbnVtYmVyC1N0YWJsZUV4cDEwAAIIAgAAAAsEAAEFAgICAgIdFDG7KAADUgUAAKQEAQAAAABAnwQCAvAEAgACAAAAqQMAAakDAQC7AQMCpAIEAAAAMECfAgIBuygBA1IFAQCkBAEAAAAAQJ8EAgLwBAIAAgAAAKkDAAGpAwEAuwEDAqQCBAAAADBAnwICAQ0BAgAFAACAggACAG8DBgCkBQkAACBwgG8GCgBSBwAAnwUDAlIGAQC8AwONCAAAAJ8DBAK7PgMCpAIMAAAAsECfAgICKwIEAIwFCgCyBAUBCQMABIIDAgCCAgIADQMBBAAAAEADAgMDBAAAMEACAAAAAAAAAAADBAMFAwYEACBwgAMHAwgEAACwQAAZCQEYAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAABAAECAAAAAAAAAAAAAAAAAAEBAAAAAhoAAAAAAQAAAQMHAAABDwABAgOjAAAAwAAAAIIAAgABBgABAAEAARgAGA0BAAAAAAF/s9IlCb5PpCm9V5x0TUdTD6vFUU13uCQ=

-- decompilation:
--!native
local function StableExp10(n1: number, n2: number) -- line: 25
	assert(type(n1) == "number")
	assert(type(n2) == "number")

	if n2 == 0.0 then
		return n1
	end

	local num = tonumber(`{ string.format("%f", n1) }e{ n2 }`)

	if not num then
		return n1 * 10.0 ^ n2
	end

	return num
end

return StableExp10

