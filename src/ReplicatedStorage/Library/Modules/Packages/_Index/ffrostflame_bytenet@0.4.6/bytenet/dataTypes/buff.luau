-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBmJ1ZmZlcgdyZWFkdTE2BmNyZWF0ZQRjb3B5BHJlYWQDbGVuBXdyaXRlB3JlcXVpcmUGc2NyaXB0BlBhcmVudAdwcm9jZXNzDGJ1ZmZlcldyaXRlcgV0eXBlcwh3cml0ZXUxNgl3cml0ZWNvcHkJZHluX2FsbG9jAAQKAgAAAAcEAAAFAgkCFp5FAAUBAAAAUgMAAFIEAQCkAgIAAAQAgJ8CAwKkAwQAAAwAgFIEAgCfAwICpAQGAAAUAIBSBQMAjAYAAFIHAACVCAEHUgkCAJ8EBgFSBAMAlQUCB4IEAwAIAwEDAgQABACAAwMEAAwAgAMEBAAUAIACAAAAAAAAAEAACQUBGAAAAAAAAAABAAAAAwAAAAAAAAACAAAKAAAAAAQBAwAABgMAAAUBCQ6kAQIAAAQAgFICAACfAQIC+wIAAFIDAQCfAgIB+wIBAFIDAQCfAgIB+wICAFIDAACfAgIBggABAAMDAQMGBAAEAIAAEgcBGAAAAAABAAACAAADAAABEwAAAAABAAEAAAAC+wAAAIIAAgAAAB0AARgAAB4AAAAABwAAAQIALKMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BAesFAAAATQEB3gYAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIPBwAAAJ8BAgJNAgBvCAAAAE0DAJYJAAAATQQAugoAAADiBQ0AwAYOADAGBXkLAAAAwAYPABIAAgASAAQAEgADADAGBdIMAAAAwAYQABIABQCCBgIAEQMIBAAAAEADCQQAACBAAwoDCwMMAw0DDgMPAxADBQMHBQILDAYABgEGAgMAAQIBAAEYAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAIAAQABAAIBAAAJAAAAAAALAAABAAAAAAOAH2c5eHLIHFwzff6wPBbs8AdwTbLbDTg=

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local writeu16 = bufferWriter.writeu16
local writecopy = bufferWriter.writecopy
local dyn_alloc = bufferWriter.dyn_alloc
local t1 = {
	read = function(p1: buffer, n1: number) -- line: 9
		local v8 = buffer.readu16(p1, n1)
		local buf = buffer.create(v8)

		buffer.copy(buf, 0.0, p1, n1 + 2.0, v8)

		return buf, v8 + 2.0
	end,
	write = function(p2: buffer) -- line: 18
		-- upvalues: writeu16 (copy), dyn_alloc (copy), writecopy (copy)
		local v11 = buffer.len(p2)

		writeu16(v11)
		dyn_alloc(v11)
		writecopy(p2)
	end
}

return function() -- line: 29
	-- upvalues: t1 (copy)
	return t1
end

