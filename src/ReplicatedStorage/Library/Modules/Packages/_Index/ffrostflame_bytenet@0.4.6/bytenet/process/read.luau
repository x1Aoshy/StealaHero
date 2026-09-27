-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWDmZ1bmN0aW9uUGFzc2VyCWNvcm91dGluZQV5aWVsZAd5aWVsZGVyBmNyZWF0ZQZyZXN1bWUEdGFzawVzcGF3bgtydW5MaXN0ZW5lcgZidWZmZXIDbGVuA3NldAZyZWFkdTgGcmVhZGVyDGdldExpc3RlbmVycwdyZXF1aXJlBnNjcmlwdAZQYXJlbnQKbmFtZXNwYWNlcwlwYWNrZXRJRHMIcmVhZFJlZnMDcmVmAAUEAQEBAAgAAQGGhgEBCAmjAQAA+wEAAMYCAADeAgAAUgIAAN0DAACfAgAB3gEAAIIAAQAAAAkBARgAAQEAAQAAAQEJAAAAAAIAAQAABAABAA8H+wAAAKQBAgAABACAnwEBAJ8AAAFIAPr/ggABAAMDAgMDBAAEAIAAEAQBGAEAAAAA/wMRAAAAAAUBAgEABQACAIYPFKMBAAD7AQAARwEKAAAAAICkAQIAAAQAgPsCAQCfAQIC3gEAAKQBBAAADACA+wIAAJ8BAgGkAQcAABhQgPsCAABSAwAA3QQAAJ8BAAGCAAEACAMCAwUEAAQAgAMGBAAMAIADBwMIBAAYUIAAFgkBGAABAAABAAAAAAEAAAADAAAAAAABFgAAAAARAwMAACcFAwcFAwmEhw8PDw8LHwYPDB8GDwUMGw8GFhEPBxYRDwMAKQIEBCUppAMCAAAEAIBSBAAAnwMCAowEAAD7BQAATQUFUwMAAABSBgEAnwUCAWAEHQADAAAA+wYBAJ5CAAUEAAAAUggAAFIJBACkBwUAABAAgJ8HAwKHBQYHlQQEBk0GBeAHAAAAUgcAAFIIBACfBgMDQwQEB00IBf4IAAAAnwgBBGQIBQD7DQIAUg4MAFIPBgBSEAIAnw0EAW4I+v8CAAAASADi/4IAAQAJAwoDCwQABACAAwwDDQQAEACAAgAAAAAAAPA/Aw4DDwAfAAEYAAAAAAECAAAAAAIAAQAAAAAAAAAAAQIAAAAAAgIAAAABAAAAAP8A+AwgAAAAAAgAAAEDHwAABw8AAScPAQ4aDwIXEYYDGg4PBBsNDwUdCw8GHwkoowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEBRAUAAABNAQEhBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgJrBwAAAJ8BAgJNAgC9CAAAAJ8CAQLGAwAA2QQAABIBA//ABQkAEgAEANkGAgASAQP/EgAFAMAHCgASAAEAEgACABIABgDBAwAAggcCAAsDEAQAAABAAxEEAAAgQAMSAxMDFAMVAxYGAQYDBAABAgMBAAEYAAIAAAAAAAAAAAAAAAABAAAAAAAAAAACAAABAgAHAAYAAAkAAAAAAAEAAAAABPX3lgaVAMig0v1D3k3xPqWF74FyxzP8Bw==

-- decompilation:
--!native
local packetIDs = require(script.Parent.Parent.namespaces.packetIDs)
local readRefs = require(script.Parent.readRefs)
local v3 = packetIDs.ref()
local u4 = nil

local function functionPasser(p1, ...) -- line: 9
	-- upvalues: u4 (ref)
	local v9 = u4

	u4 = nil
	p1(...)
	u4 = v9
end
local function yielder() -- line: 16
	-- upvalues: functionPasser (copy)
	while true do
		functionPasser(coroutine.yield())
	end
end
local function runListener(p2, ...) -- line: 22
	-- upvalues: u4 (ref), yielder (copy)
	if u4 == nil then
		u4 = coroutine.create(yielder)
		coroutine.resume(u4)
	end

	task.spawn(u4, p2, ...)
end

return function(p3: buffer, t1: {[any]: any}?, p4) -- line: 31
	-- upvalues: readRefs (copy), v3 (copy), runListener (copy)
	local v14 = buffer.len(p3)
	local n1 = 0.0

	readRefs.set(t1)

	while n1 < v14 do
		local v16 = v3[buffer.readu8(p3, n1)]
		local v17 = n1 + 1.0
		local v18, v19 = v16.reader(p3, v17)

		n1 = v17 + v19

		for _, v21 in v16.getListeners() do
			runListener(v21, v18, p4)
		end
	end
end

