-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMCElBoeXNpY2FsUHJvcGVydGllcwNuZXcAAgQBAQAAAAv7AgAAhwECACsBBwCkAgIAAAQAgFIDAACfAgICUgECAPsCAABqAQIAggECAAMDAQMCBAAEAIAAAwABGAAAAQEAAAAAAQACBAAAAAACAAABAgAGowAAAP8AAAAAAAAAwAEAABIAAACCAQIAAQYAAQABAAEYAAAAAgAAAQAAAAAB

-- decompilation:
local t1 = {}

return function(p1) -- line: 3
	-- upvalues: t1 (copy)
	local v3 = t1[p1]

	if not v3 then
		v3 = PhysicalProperties.new(p1)
		t1[p1] = v3
	end

	return v3
end

