-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQB1ZlY3RvcjIDbmV3BmJ1ZmZlcgdyZWFkZjMyBHJlYWQBWAFZBXdyaXRlB3JlcXVpcmUGc2NyaXB0BlBhcmVudAdwcm9jZXNzDGJ1ZmZlcldyaXRlcgV0eXBlcw93cml0ZWYzMk5vQWxsb2MFYWxsb2MBAQAEBwIAAAAHBAAABQIJAhOkAgIAAAQAgJ5KAAUBAAAAUgQAAFIFAQCkAwUAABAwgJ8DAwKVBgEGnkoABAYAAABSBQAApAQFAAAQMICfBAMCnwIDAowDCACCAgMABwMBAwIEAAQAgAMDAwQEABAwgAIAAAAAAAAQQAAMBQEYAAAAAAAAAAAAAAAAAAAAAAAAAA0AAAAAAwECAAAGAwAABQFADPsBAACMAggAnwECAfsBAQBNAgB5AAAAAJ8BAgH7AQEATQIAeAEAAACfAQIBggABAAIDBgMHABAIARgAAAABAAAAAQAAAAERAAAAAAEAAQAAAAL7AAAAggACAAAAFwABGAAAGAAAAAAGAAABAgApowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB6wUAAABNAQHeBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAg8HAAAAnwECAk0CACYIAAAATQMAvAkAAADiBAwAwAUNADAFBHkKAAAAwAUOABIAAwASAAIAMAUE0gsAAADABQ8AEgAEAIIFAgAQAwkEAAAAQAMKBAAAIEADCwMMAw0DDgMPAxADBQMIBQIKCwYABgEGAgMAAQIBAAEYAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAIAAQACBQAABAAAAAAHAAABAAAAAAMruOexKopm4CkniffuszCEW6DwxRl8jbA=

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local writef32NoAlloc = bufferWriter.writef32NoAlloc
local alloc = bufferWriter.alloc
local t1 = {
	read = function(p1: buffer, n1: number) -- line: 12
		return Vector2.new(buffer.readf32(p1, n1), (buffer.readf32(p1, n1 + 4.0))), 8.0
	end,
	write = function(vector2: Vector2) -- line: 16
		-- upvalues: alloc (copy), writef32NoAlloc (copy)
		alloc(8.0)
		writef32NoAlloc(vector2.X)
		writef32NoAlloc(vector2.Y)
	end
}

return function() -- line: 23
	-- upvalues: t1 (copy)
	return t1
end

