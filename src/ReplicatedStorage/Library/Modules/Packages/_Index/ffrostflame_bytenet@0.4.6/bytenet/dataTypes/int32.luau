-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBmJ1ZmZlcgdyZWFkaTMyBHJlYWQHcmVxdWlyZQZzY3JpcHQGUGFyZW50B3Byb2Nlc3MMYnVmZmVyV3JpdGVyBXR5cGVzCHdyaXRlaTMyBXdyaXRlAAMFAgAAAAcEAAAFAgkCCZ5HAAUBAAAAUgMAAFIEAQCkAgIAAAQAgJ8CAwKMAwQAggIDAAMDAQMCBAAEAIAACQMBGAAAAAAAAAAAAAoAAAAAAQABAAAAAvsAAACCAAIAAAAOAAEYAAAPAAAAAAUAAAECACSjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHrBQAAAE0BAd4GAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAiQEAAAATQICDwcAAACfAQICTQIAcggAAADiAwsAMAID0gkAAADABAwAMAQDeQoAAADABA0AEgADAIIEAgAOAwQEAAAAQAMFBAAAIEADBgMHAwgDCQMKAwsDAwUCCQoGAAYBAgABAQABGAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAACAAIBAAIAAAUAAAEAAAAAAnIaBrfDsTmeNtLuXH4pskICAhHDQN5stg==

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local t1 = {
	write = bufferWriter.writei32,
	read = function(p1: buffer, n1: number) -- line: 9
		return buffer.readi32(p1, n1), 4.0
	end
}

return function() -- line: 14
	-- upvalues: t1 (copy)
	return t1
end

