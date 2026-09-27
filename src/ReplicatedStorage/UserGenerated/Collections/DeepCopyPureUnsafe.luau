-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMEBHR5cGUFdGFibGUEbmV4dBJEZWVwQ29weVB1cmVVbnNhZmUAAgoBAAAAFwAABQ8HDwkPCBMFDwUOCg8GDgoPAQgTG7soAANSAgAApAEBAAAAAECfAQIC8AECAAIAAACCAAIA/wEAAAAAAACkAgQAAAAwQFIDAADGBAAAFwIJADUHAAQFAAAAUggFAJ8HAgI1CAAEBQAAAFIJBgCfCAICaggBB24C9v8CAAAAggECAAYDAQQAAABAAwIDAwQAADBAAwQAHwQBGAAAAAAAAAABBAABAAAAAAEAAAABAAAAAf0ABSAAAAAAAQAAAQMAB6MAAADAAAAAGAAABAEAAAA1AAAEAQAAAIIAAgACBgADBAEAAQABGAAeAAAPAAABAAAAAAGLtkXfqtoodZ8RrmiFUH2V+65Sq7lyL94=

-- decompilation:
--!native
function DeepCopyPureUnsafe(p1) -- line: 31
	if type(p1) ~= "table" then
		return p1
	end

	local t1 = {}

	for k, v in next, p1 do
		t1[DeepCopyPureUnsafe(k)] = DeepCopyPureUnsafe(v)
	end

	return t1
end

return DeepCopyPureUnsafe

