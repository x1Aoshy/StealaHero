-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKCHRlc3QgZm9vA2ZvbwxfcHJpdmF0ZVRlc3QMcHJpdmF0ZSB0ZXN0B19faW5kZXgMc2V0bWV0YXRhYmxlA25ldwAIZWF0Um9ja3MDZGllAAUBAAAAAAACbwAAAIIAAgABAwEADwIBGAAAEAAAAAAEAAEAAAAL4gECAOICBAD7AwAAMAMCbgMAAACePQEDAgAAAKQABgAAAFBAnwADAoIAAgAHAwMDBAgBAAEAAAADBQUBAwMGBAAAUEAAEwcBGAACAAAAAAD+AAAAFAAAAAACAQAAAAACbwEAAIIBAgABAwgAKQkBGAAAKgAAAAACAQAAAAACqQEBAIIBAgAAAC0KARgAAC4AAAAAAwAAAQIAFKMAAAD/AAAAAAAAAMABAAAwAQAPAQAAAMABAgASAAAAMAEA7wMAAABNAQDvAwAAAJ8BAQLAAgQAMAIBvwUAAADAAgYAMAIB1wcAAACCAQIACAYAAwIGAQMHBgIDCQYDAwoEAAECAwEAARgADAACAAAEAAAAFAAAAgAABAAABAEAAAAABKegmYpFD+WMLObBW3VxRlrXuI7+lWTziw==

-- decompilation:
local t1 = {
	foo = function() -- line: 15
		return "test foo"
	end
}

function t1.new() -- line: 19
	-- upvalues: t1 (copy)
	return (setmetatable({
		_privateTest = "private test"
	}, {
		__index = t1
	}))
end

local v2 = t1.new()

function v2.eatRocks(_) -- line: 41
	return ""
end
function v2.die(_) -- line: 45
	return true
end

return v2

