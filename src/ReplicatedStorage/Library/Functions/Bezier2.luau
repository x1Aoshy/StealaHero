-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMB1ZlY3RvcjIDbmV3BG1hdGgDcG93BXRhYmxlBHBhY2sBbgZpbnNlcnQHcmVxdWlyZQZzY3JpcHQGUGFyZW50BENvbWIAAw0BAwAAACOkAQIAAAQAgJ8BAQKMBAAA+wIAAIwDAQCoAhsA+wYBAJUHBAOHBQYH9QYDAPsMAAAmCwwEnhUGBAsAAABSCgYApAkGAAAUQICfCQMCCQgFCZ4VAAUEAAAAUgoAAFILBACkCQYAABRAgJ8JAwIJBwgJ+woCAJULBAOHCQoLCQgJB0MBAQiLAuX/ggECAAcDAQMCBAAEAIACAAAAAAAA8D8DAwMEBAAUQIAADAABGAAAAAIAAAABAAABAQAAAAAAAAAAAAAAAAAAAAABAAAAAPwHDQAAAAALAAEBAAAdowAAAKQAAgAABACA3QEAAJ8AAAJNAgCPBAAAAHgBAgP/AgAAAAAAAIwFAABSAwEAjAQBAKgDCgBSBwIA+wgAAFIJAQBSCgUAnwgDAEw0AAKkBgYAABQAgJ8GAAGLA/b/2QMAABIAAQASAAIAEgAAAIIDAgAHAwUDBgQABACAAgAAAAAAAPA/AwcDCAQAFACAAQADAAEYAAEAAAABAAABAAIAAAABAAAAAAAAAAD/BAAAAAADAAAAAAIAAAECAA2jAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBIgUAAACfAAICwAEGABIAAACCAQIABwMJBAAAAEADCgQAACBAAwsDDAYBAQEBAAEYAAAAAAAAAAAAAAIAAAEAAAAAAtBrV48FNex9B8Nyvsms8JCgc0D74q89jg==

-- decompilation:
local Comb = require(script.Parent.Comb)

return function(...) -- line: 3
	-- upvalues: Comb (copy)
	local v2 = table.pack(...)
	local v3 = v2.n - 1.0
	local t1 = {}

	for i = 0.0, v3 do
		table.insert(t1, Comb(v3, i))
	end

	return function(p1) -- line: 12
		-- upvalues: v3 (copy), t1 (copy), v2 (copy)
		local vector2 = Vector2.new()

		for i = 0.0, v3 do
			local v9 = t1[i + 1.0] * math.pow(1.0 - p1, v3 - i) * math.pow(p1, i)

			vector2 += v2[i + 1.0] * v9
		end

		return vector2
	end
end

