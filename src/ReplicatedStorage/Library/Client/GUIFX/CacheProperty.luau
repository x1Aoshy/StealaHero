-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMAAAIFAgEAAAcEAAAFAocDGCsAAgDGAgAAggICAPsDAACHAgMARwIFAAAAAID7AgAA/wMAAAAAAABqAwIA+wQAAIcDBACHAgMBRwIFAAAAAID7AwAAhwIDAIcDAAFqAwIB+wQAAIcDBACHAgMBggICAAAACQABGAABAAMAAAABAAAAAwAAAAABAAAAAwAAAAoAAAAAAgAAAQIABqMAAAD/AAAAAAAAAMABAAASAAAAggECAAEGAAEAAQABGAAGAAIAAAEAAAAAAQ==

-- decompilation:
local t1 = {}

return function(p1, s1: string) -- line: 9
	-- upvalues: t1 (copy)
	if not p1 then
		return nil
	end

	if t1[p1] == nil then
		t1[p1] = {}
	end

	if t1[p1][s1] == nil then
		t1[p1][s1] = p1[s1]
	end

	return t1[p1][s1]
end

