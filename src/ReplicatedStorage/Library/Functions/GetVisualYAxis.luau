-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMHC1JpZ2h0VmVjdG9yAVkEbWF0aANhYnMIVXBWZWN0b3IKTG9va1ZlY3RvcgZDRnJhbWUBBwACBQEAAAAGAwAABQFAJE0CAE0AAAAATQICeAEAAAC7AgICpAEEAAAMIICfAQICTQMAEQUAAABNAwN4AQAAALsCAwKkAgQAAAwggJ8CAgJNBABoBgAAAE0EBHgBAAAAuwIEAqQDBAAADCCAnwMCAn0BBQACAAAAfQMDAAIAAABvBAcAggQCAH0DAwABAAAAbwQIAIIEAgBvBAkAggQCAAoDAQMCAwMDBAQADCCAAwUDBgcAAAAAAACAPwAAAAAAAAAABwAAgD8AAAAAAAAAAAAAAAAHAAAAAAAAAAAAAIA/AAAAAAAFAAEYAAAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAgAAAAEAAQABAAIABgAAAAABAAABAgADowAAAMAAAACCAAIAAQYAAQABAAEYAAQAAQAAAAABq7Q49mCz6vnIKEAIOk6/V9usL4KZcFL3

-- decompilation:
return function(cFrame: CFrame) -- line: 5
	local v2 = math.abs(cFrame.RightVector.Y)
	local v3 = math.abs(cFrame.UpVector.Y)
	local v4 = math.abs(cFrame.LookVector.Y)

	if v2 <= v3 and v4 <= v3 then
		return (Vector3.new(0.0, 1.0, 0.0))
	end

	if v4 <= v2 then
		return (Vector3.new(1.0, 0.0, 0.0))
	end

	return (Vector3.new(0.0, 0.0, 1.0))
end

