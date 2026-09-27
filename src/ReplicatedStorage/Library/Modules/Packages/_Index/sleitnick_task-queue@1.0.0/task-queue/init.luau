-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQDHNldG1ldGF0YWJsZQZfcXVldWUJX2ZsdXNoaW5nCl9zY2hlZHVsZWQIX29uRmx1c2gDbmV3BXRhYmxlBWNsZWFyBmluc2VydAR0YXNrBWRlZmVyA0FkZAZjYW5jZWwFQ2xlYXIHRGVzdHJveQdfX2luZGV4AAYEAQEAAAYDAAAFAQUV/wIDAAAAAAD7AwAAnj0CAwMAAACkAQEAAAAAQJ8BAwL/AgAAAAAAADACAQwCAAAAqQIAADACAY0DAAAAxgIAADACAf0EAAAAMAABSwUAAACCAQIABgMBBAAAAEADAgMDAwQDBQAlBgEYAAAAAAAAAAACAAAAAQAAAQAAAQACJgAAAAACAAEAAAAa+wAAAKkBAQAwAQCNAAAAAPsAAABNAABLAQAAAPsBAABNAQEMAgAAAJ8AAgGkAAUAABAwgPsBAABNAQEMAgAAAJ8AAgH7AAAAqQEAADABAI0AAAAA+wAAAMYBAAAwAQD9BgAAAIIAAQAHAwMDBQMCAwcDCAQAEDCAAwQAOAABGAAAAAABAAAAAAAAAQAAAAAAAQAAAAEAAAABOQAAAAAFAgAAAAAUTQMADAAAAACeNAMEAQAAAFIEAQCkAgMAAAgQgJ8CAwFNAgD9BAAAAEcCCAAAAACApAIHAAAYUIDZAwAAEgAAAJ8CAgIwAgD9BAAAAIIAAQAIAwIDBwMJBAAIEIADBAMKAwsEABhQgAEBNAwBGAAAAAAAAAAAAgAAAAEAAAAAAAAINQAAAAADAQAAAAAWTQEAjQAAAAAOAQEAggABAE0BAP0BAAAARwEJAAAAAACkAQQAAAwggE0CAP0BAAAAnwECAcYBAAAwAQD9AQAAAKQBBwAAGFCATQIADAgAAACfAQIBggABAAkDAwMEAwoDDQQADCCAAwcDCAQAGFCAAwIATQ4BGAAAAAEDAAAAAQAAAAABAAADAAAAAAFOAAAAAAMBAAAAAAS8AQCQAAAAAJ8BAgGCAAEAAQMOAF0PARgAAAABXgAAAAACAAABAgATowAAAP8ABAAAAAAAMAAAbgAAAADAAQEAEgAAADABAO8CAAAAwAEDADABAF8EAAAAwAEFADABAJAGAAAAwAEHADABAFAIAAAAggACAAkDEAYAAwYGAgMMBgMDDgYEAw8EAAIDBAEAARgAHAABAAcAAAAPAAAZAAAQAAAEAQAAAAAF/7p5mQ8YcWeNgZ593CHn1o+ibu3NfhOY

-- decompilation:
local t1 = {}

t1.__index = t1

function t1.new(p1: ((...any) -> ...any)) -- line: 37
	-- upvalues: t1 (copy)
	local self = setmetatable({}, t1)

	self._queue = {}
	self._flushing = false
	self._scheduled = nil
	self._onFlush = p1

	return self
end
function t1.Add(p2, p3) -- line: 52
	table.insert(p2._queue, p3)

	if p2._scheduled == nil then
		p2._scheduled = task.defer(function() -- line: 56
			-- upvalues: p2 (copy)
			p2._flushing = true
			p2._onFlush(p2._queue)
			table.clear(p2._queue)
			p2._flushing = false
			p2._scheduled = nil
		end)
	end
end
function t1.Clear(p4) -- line: 77
	if p4._flushing then
		return
	end

	if p4._scheduled ~= nil then
		task.cancel(p4._scheduled)
		p4._scheduled = nil
	end

	table.clear(p4._queue)
end
function t1.Destroy(p5) -- line: 93
	p5:Clear()
end

return t1

