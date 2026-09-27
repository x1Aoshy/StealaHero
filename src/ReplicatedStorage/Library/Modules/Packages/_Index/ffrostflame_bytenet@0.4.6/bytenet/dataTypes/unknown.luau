-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOBXdyaXRlA2dldAZidWZmZXIGcmVhZHU4BHJlYWQHcmVxdWlyZQZzY3JpcHQGUGFyZW50B3Byb2Nlc3MMYnVmZmVyV3JpdGVyCHJlYWRSZWZzBXR5cGVzDndyaXRlUmVmZXJlbmNlBWFsbG9jAAQDAQIAAAAH+wEAAIwCAQCfAQIB+wEBAFICAACfAQIBggABAAAACgEBGAAAAAEAAAELAAAAAAcCAQAABwQAAAUCCQIS+wIAAE0CAl8AAAAAnwIBAisCAwDGAwAAjAQBAIIDAwCeQgAFAQAAAFIFAABSBgEApAQDAAAIEICfBAMChwMCBIwEAQCCAwMABAMCAwMDBAQACBCAAA8FARgAAAAAAgEAAAMAAAAAAAAAAAAQAAAAAAIAAwAAAAviAAIAwAEDABICAAASAgEAMAEA0gAAAADAAQQAEgICADABAHkBAAAAggACAAUDAQMFBQIAAQYABgECAAEIAAEYAAEAAAAABQAAAAAJAAAAAAYAAAECAC+jAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHrBQAAAE0BAd4GAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAiQEAAAATQIC6wUAAABNAgJrBwAAAJ8BAgKkAgEAAAAAQKQDAwAAACBATQMDJAQAAABNAwMkBAAAAE0DAw8IAAAAnwICAk0DAHoJAAAATQQAvAoAAADABQsAEgAEABIAAwASAAEAggUCAAwDBgQAAABAAwcEAAAgQAMIAwkDCgMLAwwDDQMOBgIBAgEAARgAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAIAAQACAAAAAAEAAAAAAyTRkYNCkH+6GQOkIavP36NUyYb3FhX7gg==

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

			return v8[buffer.readu8(p2, n1)], 1.0
		end
	}
end

