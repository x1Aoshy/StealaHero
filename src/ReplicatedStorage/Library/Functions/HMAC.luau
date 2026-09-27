-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBnN0cmluZwNyZXABAAFcATYABGJ5dGUFYml0MzIEYnhvcgRjaGFyBEhNQUMAAhQEAAAACQYAAAUEBQIDA1kcBAIAYAEFAAQAAABSBAAAUgUCAJ8EAgJSAgQAUgUCAKQGAgAABACAbwcDABwJAgAmCAEJnwYDAnMEBQakBQIAAAQAgG8GBABSBwEAnwUDAqQGAgAABACAbwcFAFIIAQCfBgMCbwcGAG8IBgCMCwEAUgkBAIwKAQCoCTAAnikFBQsAAABSDQUAUg4LAKQMCAAAHACAnwwDAp4pBAULAAAAUg4EAFIPCwCkDQgAABwAgJ8NAwJSDgcAniAMBQ0AAABSEQwAUhINAKQQCwAAKJCAnxADArsqEAKkDw0AADAAgJ8PAgJzBw4PnikGBQsAAABSDwYAUhALAKQOCAAAHACAnw4DAlIPCACeIA4FDQAAAFISDgBSEw0ApBELAAAokICfEQMCuyoRAqQQDQAAMACAnxACAnMIDxCLCdD/UgkAAFILBwBSDAAAUg4IAFIPAwBzDQ4PnwwCAnMKCwyfCQIAggkAAA4DAQMCBAAEAIADAwMEAwUDBgMHBAAcAIADCAMJBAAokIADCgQAMACAAAELARgAAAABAAAAAwAAAAAAAAABAAAAAAEAAAAAAQECAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAAAAAAAAAgAAAAAAAAEAAAAAAAAAAAAAAAD6CQAAAAAAAAAAAAIAAAAAAQAAAQIAB6MAAADAAAAAGAAAegEAAAA1AAB6AQAAAIIAAgACBgADCwEAAQABGAAAAAAXAAABAAAAAAGsq8zamKg6yeghB4BLHGI13LPbrp5vpts=

-- decompilation:
function HMAC(p1: ((...any) -> ...any), n1: number, s1: string, s2: string) -- line: 1
	if n1 < #s1 then
		s1 = p1(s1)
	end

	local v5 = s1 .. string.rep("\000", n1 - #s1)
	local v6 = string.rep("\\", n1)
	local v7 = string.rep("6", n1)
	local s3 = ""
	local s4 = ""

	for i = 1.0, n1 do
		local byte = string.byte(v6, i)
		local byte2 = string.byte(v5, i)

		s3 ..= string.char((bit32.bxor(byte, byte2)))
		s4 ..= string.char((bit32.bxor(string.byte(v7, i), byte2)))
	end

	return p1(s3 .. p1(s4 .. s2))
end

return HMAC

