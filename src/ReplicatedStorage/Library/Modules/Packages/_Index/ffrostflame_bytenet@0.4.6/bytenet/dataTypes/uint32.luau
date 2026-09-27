-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBmJ1ZmZlcgdyZWFkdTMyBHJlYWQHcmVxdWlyZQZzY3JpcHQGUGFyZW50B3Byb2Nlc3MMYnVmZmVyV3JpdGVyBXR5cGVzCHdyaXRldTMyBXdyaXRlAAMFAgAAAAcEAAAFAgkCCZ5IAAUBAAAAUgMAAFIEAQCkAgIAAAQAgJ8CAwKMAwQAggIDAAMDAQMCBAAEAIAACQMBGAAAAAAAAAAAAAoAAAAAAQABAAAAAvsAAACCAAIAAAAOAAEYAAAPAAAAAAUAAAECACSjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHrBQAAAE0BAd4GAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAiQEAAAATQICDwcAAACfAQICTQIAZQgAAADiAwsAMAID0gkAAADABAwAMAQDeQoAAADABA0AEgADAIIEAgAOAwQEAAAAQAMFBAAAIEADBgMHAwgDCQMKAwsDAwUCCQoGAAYBAgABAQABGAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAACAAIBAAIAAAUAAAEAAAAAApRW5I1Z7zSRxdVPw8DzKxPkTvP5ppKOjA==

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local t1 = {
	write = bufferWriter.writeu32,
	read = function(p1: buffer, n1: number) -- line: 9
		return buffer.readu32(p1, n1), 4.0
	end
}

return function() -- line: 14
	-- upvalues: t1 (copy)
	return t1
end

