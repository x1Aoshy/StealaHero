-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBXdyaXRlA2dldAZidWZmZXIGcmVhZHU4BnR5cGVvZghJbnN0YW5jZQRyZWFkB3JlcXVpcmUGc2NyaXB0BlBhcmVudAdwcm9jZXNzDGJ1ZmZlcldyaXRlcghyZWFkUmVmcwV0eXBlcw53cml0ZVJlZmVyZW5jZQVhbGxvYwAEAwECAAAAB/sBAACMAgEAnwECAfsBAQBSAgAAnwECAYIAAQAAAAoBARgAAAABAAABCwAAAAAHAgEAAAcEAAAFAgkCHfsCAABNAgJfAAAAAJ8CAQIrAgMAxgMAAIwEAQCCAwMAnkIABQEAAABSBQAAUgYBAKQEAwAACBCAnwQDAocDAgS7LAMDUgUDAKQEBQAAAEBAnwQCAvAEBAAGAACAUgQDAIwFAQCCBAMAxgQAAIwFAQCCBAMABwMCAwMDBAQACBCAAwUEAABAQAMGAA8HARgAAAAAAgEAAAMAAAAAAAAAAgAAAAAAAAEAAAIAABAAAAAAAgADAAAAC+IAAgDAAQMAEgIAABICAQAwAQDSAAAAAMABBAASAgIAMAEAeQEAAACCAAIABQMBAwcFAgABBgAGAQIAAQgAARgAAQAAAAAFAAAAAAkAAAAABgAAAQIAL6MAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BAesFAAAATQEB3gYAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgLrBQAAAE0CAmsHAAAAnwECAqQCAQAAAABApAMDAAAAIEBNAwMkBAAAAE0DAyQEAAAATQMDDwgAAACfAgICTQMAegkAAABNBAC8CgAAAMAFCwASAAQAEgADABIAAQCCBQIADAMIBAAAAEADCQQAACBAAwoDCwMMAw0DDgMPAxAGAgECAQABGAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAgABAAIAAAAAAQAAAAADoK3dN+LRjESWpNknZDahodC1ykOSabc2

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)
local readRefs = require(script.Parent.Parent.process.readRefs)

require(script.Parent.Parent.types)

local writeReference = bufferWriter.writeReference
local alloc = bufferWriter.alloc

return function() -- line: 8
	-- upvalues: alloc (copy), writeReference (copy), readRefs (copy)
	return {
		write = function(p1) -- line: 10
			-- upvalues: alloc (copy), writeReference (copy)
			alloc(1.0)
			writeReference(p1)
		end,
		read = function(p2: buffer, n1: number) -- line: 15
			-- upvalues: readRefs (copy)
			local v8 = readRefs.get()

			if not v8 then
				return nil, 1.0
			end

			local v9 = v8[buffer.readu8(p2, n1)]

			if typeof(v9) == "Instance" then
				return v9, 1.0
			end

			return nil, 1.0
		end
	}
end

