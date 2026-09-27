-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMFB3JlcXVpcmUGc2NyaXB0BlBhcmVudAV0eXBlcwZwYWNrZXQAAwQBAgAACAMCAAUBAg8PBfsBAAD7AgEAUgMAAJ8BAwCCAQAAAAANAAEYAAAAAAAOAAAAAAIBAQAABAABAA8E2QEAABICAAASAAAAggECAAABAAwAARgAAAAADQAAAAADAAABAwsAAAIPAAEXDwEMDBijAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQEPBQAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgJ0BgAAAJ8BAgLAAgcAEgABAIICAgAIAwEEAAAAQAMCBAAAIEADAwMEAwUGAQEBAQABGAAIAAAAAAAAAAAAAAEAAAAAAAAAAAIAAAEAAAAAAk9AuoQ2N0Fj00wEQNSbFvU/WK3wfYTQhQ==

-- decompilation:
--!native
require(script.Parent.Parent.types)

local packet = require(script.Parent.packet)

return function(p1) -- line: 12
	-- upvalues: packet (copy)
	return function(n1: number) -- line: 13
		-- upvalues: packet (copy), p1 (copy)
		return packet(p1, n1)
	end
end

