-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQB0NoYW5nZXMETm9uZQNUYmwHX19pbmRleApfX25ld2luZGV4BG5leHQGRXh0ZW5kBl9fY2FsbAxzZXRtZXRhdGFibGUMVGFibGVXYXRjaGVyB3JlcXVpcmUGc2NyaXB0BlBhcmVudARVdGlsBl9fbW9kZQFrAAUGAgIAAAAT+wMAAIcCAwBNBAJWAAAAAIcDBAFHAwkAAAAAAPsEAQBNBAQ/AQAAAJoDAwAEAAAAxgQAAIIEAgCCAwIATQUC+AIAAACHBAUBggQCAAMDAQMCAwMAFQQBGAAAAQAAAQABAAAAAAEAAgMAAAAWAAAAAAYDAgAAABX7BAAAhwMEAE0FA/gAAAAAhwQFAZoEAgACAAAAggABAEcCCAAAAACATQQDVgEAAAD7BQEATQUFPwIAAABqBQQBggABAE0EA1YBAAAAagIEAYIAAQADAwMDAQMCACIFARgAAAEAAAAAAQIAAQAAAAAAAAIAAAIjAAAAAAUBAgAAABX7AgAAhwECAKQCAQAAAABATQMBVgIAAACfAgICRwIEAAAAAIBNAgH4AwAAAIICAgD7AgEATQICvAQAAABNAwH4AwAAAE0EAVYCAAAAnwIDAIICAAAFAwYEAAAAQAMBAwMDBwAuCAEYAAABAAAAAAAAAQAAAgAAAAAAAAAALwAAAAAFAQIAAAYDAAAFAQQS/wIAAAAAAAD7AwAAnj0CAwMAAACkAQEAAAAAQJ8BAwL7AgEA4gMEAP8EAAAAAAAAMAQDVgIAAAAwAAP4AwAAAGoDAgGCAQIABQMJBAAAAEADAQMDBQICAwA2CgEYAAAAAAAAAAABAAEAAAABAP4ENwAAAAAFAAABAgAoowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BAZ4FAAAAnwACAv8BAAAAAAAA4gQIAJ49AQQEAAAAUgMBAKQCCgAAAJBAnwIDAf8CAwAAAAAAwAMLABIAAQASAAAAMAMCbgwAAADAAw0AEgABABIAAAAwAwLODgAAAMADDwASAAEAEgAAADADAu8QAAAAwAMRABIAAgASAAEAggMCABIDCwQAAABAAwwEAAAgQAMNAw4DDwMQCAEGBwAAAAMJBAAAkEAGAAMEBgEDBQYCAwgGAwQAAQIDAQABGAANAAAAAAAAAAACAAEAAAAAAAACAAIAAAAADQAAAAAMAAAAAAgAAAsBAAAAAAR6kF879gsKNxitVZFL3xdgCohIT0hUNTo=

-- decompilation:
local Util = require(script.Parent.Util)
local t1 = {}

setmetatable(t1, {
	__mode = "k"
})

local t2 = {
	__index = function(p1, p2) -- line: 21
		-- upvalues: t1 (copy), Util (copy)
		local v7 = t1[p1]
		local v8 = v7.Changes[p2]

		if v8 ~= nil then
			if v8 == Util.None then
				return nil
			end

			return v8
		end

		return v7.Tbl[p2]
	end,
	__newindex = function(p3, p4, p5) -- line: 34
		-- upvalues: t1 (copy), Util (copy)
		local v12 = t1[p3]

		if p5 == v12.Tbl[p4] then
			return
		end

		if p5 == nil then
			v12.Changes[p4] = Util.None

			return
		end

		v12.Changes[p4] = p5
	end,
	__call = function(p6) -- line: 46
		-- upvalues: t1 (copy), Util (copy)
		local v14 = t1[p6]

		if next(v14.Changes) == nil then
			return v14.Tbl
		end

		return Util.Extend(v14.Tbl, v14.Changes)
	end
}

local function TableWatcher(t3: {[any]: any}) -- line: 54
	-- upvalues: t2 (copy), t1 (copy)
	local self = setmetatable({}, t2)

	t1[self] = {
		Changes = {},
		Tbl = t3
	}

	return self
end

return TableWatcher

