-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTBmJ1ZmZlcgdyZWFkZjMyBkNGcmFtZQNuZXcGQW5nbGVzBHJlYWQBWAFZAVoQVG9FdWxlckFuZ2xlc1hZWgV3cml0ZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQHcHJvY2VzcwxidWZmZXJXcml0ZXIFdHlwZXMPd3JpdGVmMzJOb0FsbG9jBWFsbG9jAQMABA4CAAAABwQAAAUCCQI5nkoABQEAAABSAwAAUgQBAKQCAgAABACAnwIDApUFAQOeSgAEBQAAAFIEAACkAwIAAAQAgJ8DAwKVBgEEnkoABAYAAABSBQAApAQCAAAEAICfBAMClQcBBZ5KAAQHAAAAUgYAAKQFAgAABACAnwUDApUIAQaeSgAECAAAAFIHAACkBgIAAAQAgJ8GAwKVCQEHnkoABAkAAABSCAAApAcCAAAEAICfBwMCpAkKAAAkgIBSCgIAUgsDAFIMBACfCQQCpAoMAAAsgIBSCwUAUgwGAFINBwCfCgQCCQgJCowJGACCCAMADQMBAwIEAAQAgAIAAAAAAAAQQAIAAAAAAAAgQAIAAAAAAAAoQAIAAAAAAAAwQAIAAAAAAAA0QAMDAwQEACSAgAMFBAAsgIAACAYBGAAAAAAAAAABAAAAAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAAIAAAAAAAAAAAAAAAAAAAkAAAAACQECAAAGAwAABQFAH00BAHkAAAAATQIAeAEAAABNAwB7AgAAALwEAIcDAAAAnwQCBPsHAACMCBgAnwcCAfsHAQBSCAEAnwcCAfsHAQBSCAIAnwcCAfsHAQBSCAMAnwcCAfsHAQBSCAQAnwcCAfsHAQBSCAUAnwcCAfsHAQBSCAYAnwcCAYIAAQAEAwcDCAMJAwoAEgsBGAAAAAAAAAEAAAMAAAEAAAEAAAEAAAEAAAEAAAEAAAETAAAAAAEAAQAAAAL7AAAAggACAAAAIQABGAAAIgAAAAAGAAABAgApowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB6wUAAABNAQHeBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAg8HAAAAnwECAk0CACYIAAAATQMAvAkAAADiBAwAwAUNADAFBHkKAAAAwAUOABIAAwASAAIAMAUE0gsAAADABQ8AEgAEAIIFAgAQAwwEAAAAQAMNBAAAIEADDgMPAxADEQMSAxMDBgMLBQIKCwYABgEGAgMAAQIBAAEYAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAIAAQACAQAACgAAAAAPAAABAAAAAAMymM6VRfh6Nl+nSq0skbMBQoDZ4QBcpJQ=

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local writef32NoAlloc = bufferWriter.writef32NoAlloc
local alloc = bufferWriter.alloc
local t1 = {
	read = function(p1: buffer, n1: number) -- line: 8
		local v7 = buffer.readf32(p1, n1)
		local v8 = buffer.readf32(p1, n1 + 4.0)
		local v9 = buffer.readf32(p1, n1 + 8.0)
		local v10 = buffer.readf32(p1, n1 + 12.0)
		local v11 = buffer.readf32(p1, n1 + 16.0)
		local v12 = buffer.readf32(p1, n1 + 20.0)

		return CFrame.new(v7, v8, v9) * CFrame.Angles(v10, v11, v12), 24.0
	end,
	write = function(cFrame: CFrame) -- line: 18
		-- upvalues: alloc (copy), writef32NoAlloc (copy)
		local cFrameX = cFrame.X
		local cFrameY = cFrame.Y
		local cFrameZ = cFrame.Z
		local v17, v18, v19 = cFrame:ToEulerAnglesXYZ()

		alloc(24.0)
		writef32NoAlloc(cFrameX)
		writef32NoAlloc(cFrameY)
		writef32NoAlloc(cFrameZ)
		writef32NoAlloc(v17)
		writef32NoAlloc(v18)
		writef32NoAlloc(v19)
	end
}

return function() -- line: 33
	-- upvalues: t1 (copy)
	return t1
end

