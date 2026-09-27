-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBmJ1ZmZlcgZyZWFkaTgEcmVhZAdyZXF1aXJlBnNjcmlwdAZQYXJlbnQHcHJvY2VzcwxidWZmZXJXcml0ZXIFdHlwZXMHd3JpdGVpOAV3cml0ZQADBQIAAAAHBAAABQIJAgmeQQAFAQAAAFIDAABSBAEApAICAAAEAICfAgMCjAMBAIICAwADAwEDAgQABACAAAkDARgAAAAAAAAAAAAKAAAAAAEAAQAAAAL7AAAAggACAAAADgABGAAADwAAAAAFAAABAgAkowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB6wUAAABNAQHeBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAg8HAAAAnwECAk0CAGIIAAAA4gMLADACA9IJAAAAwAQMADAEA3kKAAAAwAQNABIAAwCCBAIADgMEBAAAAEADBQQAACBAAwYDBwMIAwkDCgMLAwMFAgkKBgAGAQIAAQEAARgAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAgACAQACAAAFAAABAAAAAAIhflXzZ69JzpwxYceGp1bdUWZChxO6P/I=

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local t1 = {
	write = bufferWriter.writei8,
	read = function(p1: buffer, n1: number) -- line: 9
		return buffer.readi8(p1, n1), 1.0
	end
}

return function() -- line: 14
	-- upvalues: t1 (copy)
	return t1
end

