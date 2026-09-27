-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMdBnR5cGVvZgV0YWJsZQNBZGQIZnVuY3Rpb24FZXJyb3JpQmFkIHRyb3ZlIGNvbmZpZ3VyYXRpb24gaW5zaWRlIHJlbW92ZWQgb2JqZWN0LiBJZiBubyB0cm92ZSBpbnRlbmRlZCB0aGVuIG9wdCBmb3IgY3JlYXRpbmcgb25lIHZpYSBjb25maWcuC3ZlcmlmeVRyb3ZlDWluZGV4T3ZlcnJpZGUGcmVtb3ZlBGZpbmQGYXNzZXJ0Bm9iamVjdApyZW1vdmVGcm9tFmNyZWF0ZVRyb3ZlSWZOb3RFeGlzdHMDbmV3Bl90cm92ZRNvdmVycmlkZU9iamVjdFRyb3ZlBmluc2VydBlJbmplY3RBdXRvUmVtb3ZhbEJlaGF2aW9yBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwVUcm92ZQF0CWludGVyZmFjZQAFAwEAAAAAFLssAANSAgAApAEBAAAAAECfAQIC8AEJAAIAAIBNAgBfAwAAALssAgKkAQEAAAAAQJ8BAgLwAQUABAAAAKQBBgAAAFBAbwIHAJ8BAgGCAAIACAMBBAAAAEADAgMDAwQDBQQAAFBAAwYAJAcBGAAAAAAAAAAAAAAAAAAAAAEAAf8FJQAAAAADAAIAAAAH+wAAAPsBAQBNAQFiAAAAAMYCAABqAgABggABAAEDCAA+AAEYAAAAAAAAAT8AAAAABQACAAAACqQAAgAABACA+wEAAKQCBAAADACA+wMAAPsEAQCfAgMAnwAAAYIAAQAFAwIDCQQABACAAwoEAAwAgABDAAEYAAAAAAAAAAAAAUQAAAAABwECAAAASvsCAABSAwAAnwICAEwBAAKkAQEAAAAAQJ8BAAFNAQD6AgAAAE0CAJYDAAAATQMAGwQAAAAOAwgATQMA+gIAAAD7BAEATQQE7wUAAACfBAECMAQDxQYAAABNBADCBwAAACsEAgBNBAHFBgAAALssBANSBgQApAUJAAAAgECfBQIC8AUJAAoAAIBNBgRfCwAAALssBgKkBQkAAACAQJ8FAgLwBQUADAAAAKQFDgAAANBAbwYPAJ8FAgFSAwQATQQAYhAAAAAOBAoATQQAYhAAAABqAQIE2QYAABIAAgASAAAAvAQDXwsAAACfBAMBggECAJ40AgUBAAAAUgUCAFIGAQCkBBIAAESggJ8EAwHZBgEAEgACABIAAQC8BANfCwAAAJ8EAwGCAQIAEwMLBAAAAEADDAMNAw4DDwMQAxEDAQQAAIBAAwIDAwMEAwUEAADQQAMGAwgDEgQARKCAAgECLxMBGAsAAAAAAAACAAEAAgAAAQAAAAAAAAADAAAAAOwAAAAAAAAAAAAAAAAAAAEAAf8FEAAAAQAAAgAAAAAAAAQAAAAAAAABAAAAAAAFJQAAAAAGAAABAgAuowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLoBwAAAE0CAuYIAAAATQICmwkAAACfAQICpAIFAAAAQEBNAwBqBgAAAE0DA+gHAAAATQMD5ggAAABNAwOVCgAAAJ8CAgJNAwIvCwAAAOIEDgBNBQJLDwAAADAFBJYMAAAATQUCSw8AAAAwBQT6DQAAAJ8DAgLABBAAwAURABIAAwASAAEAggUCABIDFAQAAABAAxUDFgMXBAAAQEADGAMZAxoDGwMcAx0DDQMMBQIMDQMCBgAGAwIAAwEAARgAAQAAAAAAAwAAAAAAAAAAAAABAAAAAAAAAAAAABQAAAEAAAABAAAA/goLAAAcAQAAAAAE+gKa2/Nt/YPtFjOcFUIGpooaja/IxvDa

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Library.Modules.Packages.Trove)
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local v4 = t.interface({
	removeFrom = t.table,
	object = t.table
})

local function verifyTrove(p1) -- line: 36
	if typeof(p1) ~= "table" or typeof(p1.Add) ~= "function" then
		error("Bad trove configuration inside removed object. If no trove intended then opt for creating one via config.")
	end

	return p1
end
local function InjectAutoRemovalBehavior(p2) -- line: 47
	-- upvalues: v4 (copy), Trove (copy)
	assert(v4(p2))

	local object = p2.object
	local removeFrom = p2.removeFrom

	if p2.createTroveIfNotExists then
		p2.object._trove = Trove.new()
	end

	local v11 = p2.overrideObjectTrove or object._trove

	if typeof(v11) ~= "table" or typeof(v11.Add) ~= "function" then
		error("Bad trove configuration inside removed object. If no trove intended then opt for creating one via config.")
	end

	if p2.indexOverride then
		removeFrom[p2.indexOverride] = object
		v11:Add(function() -- line: 62
			-- upvalues: removeFrom (copy), p2 (copy)
			removeFrom[p2.indexOverride] = nil
		end)

		return object
	end

	table.insert(removeFrom, object)
	v11:Add(function() -- line: 67
		-- upvalues: removeFrom (copy), object (copy)
		table.remove(removeFrom, table.find(removeFrom, object))
	end)

	return object
end

return InjectAutoRemovalBehavior

