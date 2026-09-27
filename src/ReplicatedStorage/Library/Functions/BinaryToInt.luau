-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMFBWJpdDMyBmxzaGlmdAZzdHJpbmcEYnl0ZQNib3IAAgoBAAAAABqMAQAAjAQBABwCAACMAwEAqAIUAIEkAQUAAAAAUgcBAG8IAACkBgMAAAgQgJ8GAwKeKQAFBAAAAFIIAABSCQQApAcGAAAUQICfBwMATB8AAqQFCAAAHBCAnwUAAlIBBQCLAuz/ggECAAkCAAAAAAAAIEADAQMCBAAIEIADAwMEBAAUQIADBQQAHBCAAAEAARgAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAD/AwIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAAEAAQABGAAAAAEAAAAAAQ==

-- decompilation:
return function(p1) -- line: 1
	local n1 = 0.0

	for i = 1.0, #p1 do
		n1 = bit32.bor(bit32.lshift(n1, 8.0), string.byte(p1, i))
	end

	return n1
end

