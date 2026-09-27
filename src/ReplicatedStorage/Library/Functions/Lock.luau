-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMFB2FjcXVpcmUHcmVxdWlyZQZzY3JpcHQGUGFyZW50B2ZpbmFsbHkABAEAAQAAAAOpAAAA3gAAAIIAAQAAAAwAARgAAAENAAAAAAYBAgEAAA+jAQAA+wEAAA4BAgCpAQAAggECAKkBAQDeAQAAqQEBAPsCAQBSAwAA2QQAABICAADdBQAAnwIAAIIBAAAAAQAHAQEYAAEAAQACAAEAAAAAAv4ABwAAAAACAAEAAAAGqQAAANkBAAASAQD/EgIAAMEAAACCAQIAAAEBBQABGAABAAALAAYAAAAAAgAAAQIADaMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQFCBQAAAJ8AAgLAAQYAEgAAAIIBAgAHAwIEAAAAQAMDBAAAIEADBAMFBgIBAgEAARgAAAAAAAAAAAAABAAAAQAAAAADxjzJidjgqB2wiZxoQya1wLYk3v30+KOI

-- decompilation:
local finally = require(script.Parent.finally)

return function() -- line: 5
	-- upvalues: finally (copy)
	local u2 = false

	local function acquire(p1, ...) -- line: 7
		-- upvalues: u2 (ref), finally (copy)
		if u2 then
			return false
		end

		u2 = true

		return true, finally(p1, function() -- line: 12
			-- upvalues: u2 (ref)
			u2 = false
		end, ...)
	end

	return acquire
end

