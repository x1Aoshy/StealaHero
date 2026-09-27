-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBl9maXJzdAVfbGFzdAZfcXVldWUMc2V0bWV0YXRhYmxlA25ldwdpc0VtcHR5B2VucXVldWUFZXJyb3IfQ2Fubm90IGRlcXVldWUgZnJvbSBlbXB0eSBxdWV1ZQdkZXF1ZXVlB19faW5kZXgABQMAAQAAAAziAQUA/wIAAAAAAAAwAgEMBAAAAPsCAACePQEDAgAAAKQABwAAAGBAnwADAoIAAgAIAwECAAAAAAAAAAADAgIAAAAAAADwvwMDCAMAAQAAAAIDAAAABP////8DBAQAAGBAAAQFARgAAwAAAAEAAPwAAAAFAAAAAAQBAAAAAAlNAgD1AAAAAE0DADUBAAAAtwMCAAIAAACpAQABqQEBAIIBAgACAwEDAgAMBgEYAAAAAAAAAAAADQAAAAAEAgAAAAAJTQMANQEAAACVAgMAMAIANQEAAABNAwAMAgAAAGoBAwKCAAEAAwIAAAAAAADwPwMCAwMAEAcBGAAAAAEAAQAAAREAAAAABQEAAAAAFbwBANUAAAAAnwECAg4BBACkAQIAAAAQQG8CAwCfAQIBTQEA9QQAAABNAwAMBQAAAIcCAwFNAwAMBQAAAMYEAABqBAMBlQMBBjADAPUEAAAAggICAAcDBgMIBAAAEEADCQMBAwMCAAAAAAAA8D8AFgoBGAAAAAABAAAAAgABAAABAAAAAQAAARcAAAAAAgAAAQIAE6MAAAD/AAQAAAAAADAAAG4AAAAAwAEBABIAAAAwAQDvAgAAAMABAwAwAQDVBAAAAMABBQAwAQDoBgAAAMABBwAwAQDECAAAAIIAAgAJAwsGAAMFBgEDBgYCAwcGAwMKBAABAgMBAAEYAAAAAQACAAAACAAABAAABgAACwEAAAAABFEQm7Dk6Fd9DUtcZxcmTGEhCIzEY9TxsQ==

-- decompilation:
local t1 = {}

t1.__index = t1

function t1.new() -- line: 4
	-- upvalues: t1 (copy)
	return (setmetatable({
		_first = 0.0,
		_last = -1.0,
		_queue = {}
	}, t1))
end
function t1.isEmpty(p1) -- line: 12
	return p1._first > p1._last
end
function t1.enqueue(p2, p3) -- line: 16
	local v5 = p2._last + 1.0

	p2._last = v5
	p2._queue[v5] = p3
end
function t1.dequeue(p4) -- line: 22
	if p4:isEmpty() then
		error("Cannot dequeue from empty queue")
	end

	local _first = p4._first
	local v8 = p4._queue[_first]

	p4._queue[_first] = nil
	p4._first = _first + 1.0

	return v8
end

return t1

