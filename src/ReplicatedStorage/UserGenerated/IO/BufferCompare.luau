-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBmJ1ZmZlcgNsZW4EbWF0aANtaW4GcmVhZHU4DUNvbXBhcmVCdWZmZXIAAgwCAAAAHwQABgUCCQkCCBMSAgkaCwIHDxYPAgAoDwMEJAIECCAopAICAAAEAIBSAwAAnwICAqQDAgAABACAUgQBAJ8DAgKeEwIFAwAAAFIFAgBSBgMApAQFAAAQMICfBAMCjAcAAHgFBAaMBgEAqAUTAJ5CAAUHAAAAUgkAAFIKBwCkCAgAABwAgJ8IAwKeQgEFBwAAAFIKAQBSCwcApAkIAAAcAICfCQMC8QgDAAkAAAAmCggJggoCAIsF7f8mBQIDggUCAAkDAQMCBAAEAIADAwMEBAAQMIACAAAAAAAA8D8DBQQAHACAABQGARgAAAAAAQAAAAEAAAAAAAACAAAAAQAAAAAAAAEAAAAAAAABAAIA+wkAFQAAAAABAAABAwcAAAEPAAECA6MAAADAAAAAggACAAEGAAEAAQABGAATEQEAAAAAAceQemC2j89m+eD0f4HOMby3iG0U9VQQYQ==

-- decompilation:
--!native
local function CompareBuffer(p1: buffer, p2: buffer) -- line: 20
	local v4 = buffer.len(p1)
	local v5 = buffer.len(p2)

	for i = 0.0, math.min(v4, v5) - 1.0 do
		local v7 = buffer.readu8(p1, i)
		local v8 = buffer.readu8(p2, i)

		if v7 ~= v8 then
			return v7 - v8
		end
	end

	return v4 - v5
end

return CompareBuffer

