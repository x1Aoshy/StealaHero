-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBmJ1ZmZlcgdyZWFkdTE2BHJlYWQFd3JpdGUHcmVxdWlyZQZzY3JpcHQGUGFyZW50B3Byb2Nlc3MMYnVmZmVyV3JpdGVyBXR5cGVzCHdyaXRldTE2AAQNAgIAAAcEAAAFAgkCIv8CAAAAAAAAUgMBAJ5FAAUDAAAAUgUAAFIGAwCkBAIAAAQAgJ8EAwKVAwMDjAcBAFIFBACMBgEAqAUQAPsIAABNCAh5BAAAAFIJAABSCgMAnwgDA0MDAwn7CgEATQoKeQQAAABSCwAAUgwDAJ8KAwNDAwMLagoCCIsF8P9SBQIAJgYDAYIFAwAFAwEDAgQABACAAgAAAAAAAABAAwMAEAMBGAAAAQMAAAAAAAABAgAAAAIAAAAAAAECAAAAAAABAvgMAAARAAAAAAkBAwAAABiMAQAAUgIAAMYDAADGBAAAZAIBAJUBAQBuAv7/AQAAAPsCAABSAwEAnwICAVICAADGAwAAxgQAAGQCBgD7BwEAUggFAJ8HAgH7BwIAUggGAJ8HAgFuAvn/AgAAAIIAAQABAgAAAAAAAPA/ACYEARgAAQAAAAH/AAUAAAIAAAACAAABAAD9AAUnAAAAAAYCAQAAABFNAgDSAAAAAE0DAdIAAAAA4gQCANkFAAASAAAAEgABADAFBHkBAAAA2QUBABICAAASAAIAEgADADAFBNIAAAAAggQCAAMDBAMDBQIBAAIAAQcAARgAAAEAAgEAAAAAFgAAAAAAAAwAAAAABAAAAQIAHqMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BAesFAAAATQEB3gYAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIPBwAAAJ8BAgJNAgBvCAAAAMADCQASAAIAggMCAAoDBQQAAABAAwYEAAAgQAMHAwgDCQMKAwsGAgECAQABGAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAACAAMAAAEAAAAAA3glGfTunZuZAPwrfW9yvfkIPQ6ASuFz9Q==

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local writeu16 = bufferWriter.writeu16

return function(p1, p2) -- line: 7
	-- upvalues: writeu16 (copy)
	local write = p1.write
	local write2 = p2.write

	return {
		read = function(p3: buffer, n1: number) -- line: 16
			-- upvalues: p1 (copy), p2 (copy)
			local t1 = {}
			local v10 = buffer.readu16(p3, n1)
			local v11 = n1 + 2.0

			for _ = 1.0, v10 do
				local v13, v14 = p1.read(p3, v11)
				local v15 = v11 + v14
				local v16, v17 = p2.read(p3, v15)

				v11 = v15 + v17
				t1[v13] = v16
			end

			return t1, v11 - n1
		end,
		write = function(p4) -- line: 38
			-- upvalues: writeu16 (copy), write (copy), write2 (copy)
			local n2 = 0.0

			for _ in p4 do
				n2 += 1.0
			end

			writeu16(n2)

			for v21, v22 in p4 do
				write(v21)
				write2(v22)
			end
		end
	}
end

