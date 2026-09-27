-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKBXRhYmxlBmNyZWF0ZQRtYXRoBGNlaWwABnN0cmluZwZmb3JtYXQEJTAyeARieXRlBmNvbmNhdAACCwEAAAAAIBwBAACkAgIAAAQAgLsHAQNSBAEApAMFAAAQMICfAwICbwQGAJ8CAwKMBQEAUgMBAIwEAQCoAw0ApAYJAAAgcIBvBwoAnikABQUAAABSCQAAUgoFAKQIDAAALHCAnwgDAJ8GAAJqBgIFiwPz/6QDDgAANACAUgQCAJ8DAgCCAwAADwMBAwIEAAQAgAMDAwQEABAwgAMFAwYDBwQAIHCAAwgDCQQALHCAAwoEADQAgAABAAEYAAEAAAAAAAAAAAEAAAABAAAAAAAAAAAAAAD/AwAAAAACAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgABAAEAARgAAAABAAAAAAFKxSZnomeaoVNH32kEi1/KOt0xE3gBTGY=

-- decompilation:
return function(p1) -- line: 1
	local v2 = #p1
	local t1 = table.create(math.ceil(v2), "")

	for i = 1.0, v2 do
		t1[i] = string.format("%02x", string.byte(p1, i))
	end

	return table.concat(t1)
end

