-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBmJ1ZmZlcgdyZWFkaTE2BHJlYWQHcmVxdWlyZQZzY3JpcHQGUGFyZW50B3Byb2Nlc3MMYnVmZmVyV3JpdGVyBXR5cGVzCHdyaXRlaTE2BXdyaXRlAAMFAgAAAAcEAAAFAgkCCZ5EAAUBAAAAUgMAAFIEAQCkAgIAAAQAgJ8CAwKMAwIAggIDAAMDAQMCBAAEAIAACQMBGAAAAAAAAAAAAAoAAAAAAQABAAAAAvsAAACCAAIAAAAOAAEYAAAPAAAAAAUAAAECACSjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHrBQAAAE0BAd4GAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAiQEAAAATQICDwcAAACfAQICTQIAjggAAADiAwsAMAID0gkAAADABAwAMAQDeQoAAADABA0AEgADAIIEAgAOAwQEAAAAQAMFBAAAIEADBgMHAwgDCQMKAwsDAwUCCQoGAAYBAgABAQABGAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAACAAIBAAIAAAUAAAEAAAAAAhlpfbQ3v3WRGm9ByLoc5R1pcWrAK60XtQ==

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local t1 = {
	write = bufferWriter.writei16,
	read = function(p1: buffer, n1: number) -- line: 9
		return buffer.readi16(p1, n1), 2.0
	end
}

return function() -- line: 14
	-- upvalues: t1 (copy)
	return t1
end

