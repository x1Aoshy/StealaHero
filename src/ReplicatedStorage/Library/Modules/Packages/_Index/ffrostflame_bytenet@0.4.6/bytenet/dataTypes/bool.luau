-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMBmJ1ZmZlcgZyZWFkdTgEcmVhZAdyZXF1aXJlBnNjcmlwdAZQYXJlbnQHcHJvY2VzcwxidWZmZXJXcml0ZXIFdHlwZXMGbGVuZ3RoBXdyaXRlCXdyaXRlYm9vbAADBgIAAAAHBAAABQIJAg2eQgAFAQAAAFIEAABSBQEApAMCAAAEAICfAwMCDQMCAAMAAACpAgABqQIBAIwDAQCCAgMABAMBAwIEAAQAgAIAAAAAAADwPwALAwEYAAAAAAAAAAAAAAAAAAwAAAAAAQABAAAAAvsAAACCAAIAAAAUAAEYAAAVAAAAAAQAAAECACSjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQHrBQAAAE0BAd4GAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAiQEAAAATQICDwcAAACfAQIC4gIMAMADDQAwAwJ5CAAAAE0DAMoOAAAAMAMC0gsAAADAAw8AEgACAIIDAgAQAwQEAAAAQAMFBAAAIEADBgMHAwgDCQMDAwoCAAAAAAAA8D8DCwgDCP////8JCgAAAAv/////BgADDAYBAgABAQABGAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAACBwAABgAAAAMAAAEAAAAAAhtiI82d06+MTVvoP6IkkN1rejS5KaZJzA==

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local t1 = {
	length = 1.0,
	read = function(p1: buffer, n1: number) -- line: 11
		return buffer.readu8(p1, n1) == 1.0, 1.0
	end,
	write = bufferWriter.writebool
}

return function() -- line: 20
	-- upvalues: t1 (copy)
	return t1
end

