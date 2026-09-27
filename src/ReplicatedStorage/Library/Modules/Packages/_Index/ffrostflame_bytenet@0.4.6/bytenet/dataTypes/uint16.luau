-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBmJ1ZmZlcgdyZWFkdTE2BHJlYWQHcmVxdWlyZQZzY3JpcHQGUGFyZW50B3Byb2Nlc3MMYnVmZmVyV3JpdGVyBXR5cGVzCHdyaXRldTE2BXdyaXRlAAMFAgAAAAcEAAAFAgkCCZ5FAAUBAAAAUgMAAFIEAQCkAgIAAAQAgJ8CAwKMAwIAggIDAAMDAQMCBAAEAIAACQMBGAAAAAAAAAAAAAoAAAAAAQABAAAAAvsAAACCAAIAAAAOAAEYAAAPAAAAAAUAAAECACSjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHrBQAAAE0BAd4GAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAiQEAAAATQICDwcAAACfAQICTQIAbwgAAADiAwsAMAID0gkAAADABAwAMAQDeQoAAADABA0AEgADAIIEAgAOAwQEAAAAQAMFBAAAIEADBgMHAwgDCQMKAwsDAwUCCQoGAAYBAgABAQABGAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAACAAIBAAIAAAUAAAEAAAAAAqOfoHL1TO8K0GpPtNk7tMvTh7cGkVvKcw==

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local t1 = {
	write = bufferWriter.writeu16,
	read = function(p1: buffer, n1: number) -- line: 9
		return buffer.readu16(p1, n1), 2.0
	end
}

return function() -- line: 14
	-- upvalues: t1 (copy)
	return t1
end

