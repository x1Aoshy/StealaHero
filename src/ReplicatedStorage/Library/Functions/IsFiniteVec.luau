-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMHAVgBWQFaB3JlcXVpcmUGc2NyaXB0BlBhcmVudAhJc0Zpbml0ZQACBAEBAAAAEfsBAABNAgB5AAAAAJ8BAgIOAQQA+wEAAE0CAHgBAAAAnwECAg4BBQD7AgAATQMAewIAAACfAgIAggIAAKkCAACCAgIAAwMBAwIDAwADAAEYAAAAAAAAAAAAAQEAAAAAAgAEAAAAAAIAAAECAA2jAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBbgUAAACfAAICwAEGABIAAACCAQIABwMEBAAAAEADBQQAACBAAwYDBwYAAQABAAEYAAAAAAAAAAAAAAIAAAEAAAAAAVrG8JAishFuk47o1uR0tY4q3ufkaAKakQ==

-- decompilation:
local IsFinite = require(script.Parent.IsFinite)

return function(p1) -- line: 3
	-- upvalues: IsFinite (copy)
	if IsFinite(p1.X) and IsFinite(p1.Y) then
		return IsFinite(p1.Z)
	end

	return false
end

