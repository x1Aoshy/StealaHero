-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGGHRvS2lsb2dyYW1zUGVyQ3ViaWNNZXRlchN0b0dyYW1QZXJNaWxsaWxpdGVyGHRvR3JhbVBlckN1YmljQ2VudGltZXRlchZHcmFtUGVyQ3ViaWNDZW50aW1ldGVyFktpbG9ncmFtc1BlckN1YmljTWV0ZXIRR3JhbVBlck1pbGxpbGl0ZXIABwIBAAAABgMAAAUBAgJbAQAAggECAAEC/Knx0k1iUD8AEwEBGAAAFgAAAAACAQAAAAYDAAAFAQICWwEAAIIBAgABAo3ttaD3xrA+ABgCARgAABkAAAAAAgEAAAAGAwAABQECAj4BAACCAQIAAQKN7bWg98awPgAdAwEYAAAeAAAAAAQBAgAABgMAAAUBAgr7AQAATQEB2QAAAAD7AgEATQICmAEAAABSAwAAnwICAJ8BAACCAQAAAgMBAwMAIAEBGAAAAAEAAAAA/wAjAAAAAAIBAAAABgMAAAUBAgI+AQAAggECAAEC/Knx0k1iUD8AKQMBGAAALAAAAAAEAQIAAAYDAAAFAQIK+wEAAE0BAdkAAAAA+wIBAE0CApgBAAAAUgMAAJ8CAgCfAQAAggEAAAIDAQMDAC4BARgAAAABAAAAAP8AMQAAAAAEAAABAgAlowAAAP8AAgAAAAAAwAEAADABANkBAAAAwAECADABAHYDAAAA/wECAAAAAADAAgQAMAIBmAUAAADAAgYAEgAAABIAAQAwAgHZAQAAAP8CAgAAAAAAwAMHADADApgFAAAAwAMIABIAAAASAAIAMAMC2QEAAADiAwwAMAADqwkAAAAwAgNgCgAAADABA9kLAAAAggMCAA0GAAMBBgEDAgYCAwMGAwYEBgUDBAMFAwYFAwkKCwYAAQIDBAUBAAEYABEAAQAABQAABAABAAADAAAAAAgAAQAABQAAAAAIAQABAAEAAAEAAAAABhsSscVwWWv18dm2tV0D1NVrCqaxKdbbxA==

-- decompilation:
local t1 = {
	toKilogramsPerCubicMeter = function(n1: number) -- line: 19
		return n1 * 0.001
	end,
	toGramPerMilliliter = function(n2: number) -- line: 24
		return n2 * 1E-06
	end
}
local t2 = {
	toGramPerCubicCentimeter = function(n3: number) -- line: 29
		return n3 / 1E-06
	end
}

function t2.toKilogramsPerCubicMeter(n4: number) -- line: 32
	-- upvalues: t1 (copy), t2 (copy)
	return t1.toKilogramsPerCubicMeter(t2.toGramPerCubicCentimeter(n4))
end

local t3 = {
	toGramPerCubicCentimeter = function(n5: number) -- line: 41
		return n5 / 0.001
	end
}

function t3.toKilogramsPerCubicMeter(n6: number) -- line: 46
	-- upvalues: t1 (copy), t3 (copy)
	return t1.toKilogramsPerCubicMeter(t3.toGramPerCubicCentimeter(n6))
end

return {
	GramPerCubicCentimeter = t1,
	KilogramsPerCubicMeter = t3,
	GramPerMilliliter = t2
}

