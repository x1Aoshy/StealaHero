-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRAVIBRwFCBXdyaXRlBkNvbG9yMwdmcm9tUkdCBmJ1ZmZlcgZyZWFkdTgEcmVhZAdyZXF1aXJlBnNjcmlwdAZQYXJlbnQHcHJvY2VzcwxidWZmZXJXcml0ZXIFdHlwZXMOd3JpdGV1OE5vQWxsb2MFYWxsb2MBBQAEBAECAAAGAwAABQFAE/sBAACMAgMAnwECAfsBAQBNAwBzAQAAAFsCAwCfAQIB+wEBAE0DAGYCAAAAWwIDAJ8BAgH7AQEATQMAYwMAAABbAgMAnwECAYIAAQAEAgAAAAAA4G9AAwEDAgMDAAgEARgAAAABAAAAAAEAAAAAAQAAAAABCQAAAAAIAgAAAAcEAAAFAgkCGqQCAgAABACAnkIABQEAAABSBAAAUgUBAKQDBQAAEDCAnwMDApUGAQaeQgAEBgAAAFIFAACkBAUAABAwgJ8EAwKVBwEHnkIABAcAAABSBgAApAUFAAAQMICfBQMCnwIEAowDAwCCAgMACAMFAwYEAAQAgAMHAwgEABAwgAIAAAAAAADwPwIAAAAAAAAAQAAOCQEYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPAAAAAAEAAQAAAAL7AAAAggACAAAAEwABGAAAFAAAAAAGAAABAgApowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB6wUAAABNAQHeBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAg8HAAAAnwECAk0CAI0IAAAATQMAvAkAAADiBAwAwAUNABIAAwASAAIAMAUE0goAAADABQ4AMAUEeQsAAADABQ8AEgAEAIIFAgAQAwoEAAAAQAMLBAAAIEADDAMNAw4DDwMQAxEDBAMJBQIKCwYABgEGAgMAAQIBAAEYAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAIAAQACAQAAAAAGAAAFAAABAAAAAAODJRKp6cYIJtnvjIc3gBfM8z0F3bHheKg=

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local writeu8NoAlloc = bufferWriter.writeu8NoAlloc
local alloc = bufferWriter.alloc
local t1 = {
	write = function(color3: Color3) -- line: 8
		-- upvalues: alloc (copy), writeu8NoAlloc (copy)
		alloc(3.0)
		writeu8NoAlloc(color3.R * 255.0)
		writeu8NoAlloc(color3.G * 255.0)
		writeu8NoAlloc(color3.B * 255.0)
	end,
	read = function(p1: buffer, n1: number) -- line: 14
		return Color3.fromRGB(buffer.readu8(p1, n1), buffer.readu8(p1, n1 + 1.0), (buffer.readu8(p1, n1 + 2.0))), 3.0
	end
}

return function() -- line: 19
	-- upvalues: t1 (copy)
	return t1
end

