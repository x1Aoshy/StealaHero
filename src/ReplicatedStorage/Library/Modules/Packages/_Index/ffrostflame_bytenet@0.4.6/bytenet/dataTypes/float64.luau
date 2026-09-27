-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBmJ1ZmZlcgdyZWFkZjY0BHJlYWQHcmVxdWlyZQZzY3JpcHQGUGFyZW50B3Byb2Nlc3MMYnVmZmVyV3JpdGVyBXR5cGVzCHdyaXRlZjY0BXdyaXRlAAMFAgAAAAcEAAAFAgkCCZ5MAAUBAAAAUgMAAFIEAQCkAgIAAAQAgJ8CAwKMAwgAggIDAAMDAQMCBAAEAIAACQMBGAAAAAAAAAAAAAoAAAAAAQABAAAAAvsAAACCAAIAAAAOAAEYAAAPAAAAAAUAAAECACSjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHrBQAAAE0BAd4GAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAiQEAAAATQICDwcAAACfAQICTQIAuwgAAADiAwsAMAID0gkAAADABAwAMAQDeQoAAADABA0AEgADAIIEAgAOAwQEAAAAQAMFBAAAIEADBgMHAwgDCQMKAwsDAwUCCQoGAAYBAgABAQABGAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAACAAIBAAIAAAUAAAEAAAAAAn1aU7HgMuoFotyJz8DTgisNQkTFT545sA==

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local t1 = {
	write = bufferWriter.writef64,
	read = function(p1: buffer, n1: number) -- line: 9
		return buffer.readf64(p1, n1), 8.0
	end
}

return function() -- line: 14
	-- upvalues: t1 (copy)
	return t1
end

