-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBmJ1ZmZlcgZyZWFkdTgEcmVhZAV3cml0ZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQHcHJvY2VzcwxidWZmZXJXcml0ZXIFdHlwZXMJd3JpdGVib29sAAQGAgEAAAcEAAAFAgkCE55CAAUBAAAAUgMAAFIEAQCkAgIAAAQAgJ8CAwINAgQAAwAAgMYCAACMAwEAggIDAPsCAABSAwAAlQQBBJ8CAwNSBAIAlQUDBIIEAwAFAwEDAgQABACAAgAAAAAAAAAAAgAAAAAAAPA/ABADARgAAAAAAAAAAAACAAADAAAAAQAAEQAAAAAEAQIAAAAMRwACAAAAAICpAQABqQEBAPsCAABSAwEAnwICAQ4BAwD7AgEAUgMAAJ8CAgGCAAEAAAAbBAEYAAAAAAIAAAIBAAACHAAAAAAFAQEAAAAPTQEAeQAAAABNAgDSAQAAAOIDAgDZBAAAEgABADAEA3kAAAAA2QQBABICAAASAAIAMAQD0gEAAACCAwIAAwMDAwQFAgABAgABBgABGAAAAQACBgAAAAsAAAAAAAcAAAAABAAAAQIAHqMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BAesFAAAATQEB3gYAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIPBwAAAJ8BAgJNAgDKCAAAAMADCQASAAIAggMCAAoDBQQAAABAAwYEAAAgQAMHAwgDCQMKAwsGAgECAQABGAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAACAAIAAAEAAAAAA9bNFekj3vuoM637/K8BC66m1QKd5Al/6A==

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local writebool = bufferWriter.writebool

return function(p1) -- line: 6
	-- upvalues: writebool (copy)
	local read = p1.read
	local write = p1.write

	return {
		read = function(p2: buffer, n1: number) -- line: 16
			-- upvalues: read (copy)
			if buffer.readu8(p2, n1) == 0.0 then
				return nil, 1.0
			end

			local v8, v9 = read(p2, n1 + 1.0)

			return v8, v9 + 1.0
		end,
		write = function(p3) -- line: 27
			-- upvalues: writebool (copy), write (copy)
			local v11 = p3 ~= nil

			writebool(v11)

			if v11 then
				write(p3)
			end
		end
	}
end

