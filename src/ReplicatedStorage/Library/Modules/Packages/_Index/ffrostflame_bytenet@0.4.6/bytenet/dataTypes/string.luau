-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBmJ1ZmZlcgdyZWFkdTE2CnJlYWRzdHJpbmcEcmVhZAZzdHJpbmcDbGVuBXdyaXRlB3JlcXVpcmUGc2NyaXB0BlBhcmVudAdwcm9jZXNzDGJ1ZmZlcldyaXRlcgV0eXBlcwh3cml0ZXUxNgt3cml0ZXN0cmluZwlkeW5fYWxsb2MABAcCAAAABwQAAAUCCQIPnkUABQEAAABSAwAAUgQBAKQCAgAABACAnwIDAqQDBAAADACAUgQAAJUFAQVSBgIAnwMEApUEAgWCAwMABgMBAwIEAAQAgAMDBAAMAIACAAAAAAAAAEAADAQBGAAAAAAAAAACAAAAAAAAAA0AAAAABAEDAAAGAwAABQEDD7srAANSAgAApAECAAAEAICfAQIC+wIAAFIDAQCfAgIB+wIBAFIDAQCfAgIB+wICAFIDAACfAgIBggABAAMDBQMGBAAEAIAAEQcBGAAAAAAAAQAAAgAAAQAAARIAAAAAAQABAAAAAvsAAACCAAIAAAAaAAEYAAAbAAAAAAcAAAECACyjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHrBQAAAE0BAd4GAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAiQEAAAATQICDwcAAACfAQICTQIAbwgAAABNAwCQCQAAAE0EALoKAAAA4gUNAMAGDgAwBgV5CwAAAMAGDwASAAIAEgAEABIAAwAwBgXSDAAAAMAGEAASAAUAggYCABEDCAQAAABAAwkEAAAgQAMKAwsDDAMNAw4DDwMQAwQDBwUCCwwGAAYBBgIDAAECAQABGAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAACAAEAAgACAwAABQAAAAAACQAAAQAAAAAD6u9N0Vgkk4nPUKEOnRd6jZr3WqXYKyfQ

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local writeu16 = bufferWriter.writeu16
local writestring = bufferWriter.writestring
local dyn_alloc = bufferWriter.dyn_alloc
local t1 = {
	read = function(p1: buffer, n1: number) -- line: 12
		local v8 = buffer.readu16(p1, n1)

		return buffer.readstring(p1, n1 + 2.0, v8), v8 + 2.0
	end,
	write = function(s1: string) -- line: 17
		-- upvalues: writeu16 (copy), dyn_alloc (copy), writestring (copy)
		local v10 = string.len(s1)

		writeu16(v10)
		dyn_alloc(v10)
		writestring(s1)
	end
}

return function() -- line: 26
	-- upvalues: t1 (copy)
	return t1
end

