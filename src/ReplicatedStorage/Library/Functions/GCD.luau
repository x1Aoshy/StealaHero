-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMAAAIDAgAAAAAHDQEFAAAAAADPAgABUgABAFIBAgBIAPr/ggACAAECAAAAAAAAAAAAAQABGAAAAQEB/QUCAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgABAAEAARgAAAABAAAAAAE=

-- decompilation:
return function(p1, p2) -- line: 1
	while p2 ~= 0.0 do
		local v3 = p2

		p2 = p1 % p2
		p1 = v3
	end

	return p1
end

