-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBSUqZSUqBnN0cmluZwZmb3JtYXQCJWYIdG9udW1iZXIIdG9zdHJpbmcFZXJyb3ICeDoDIHk6CCBmbXQoeCk6CU5pY2VFeHAxMAACDwIAAAAHAAABAwIKAi0NAQIAAAAAgIIAAgBvAgEApAQEAAAMIIBvBQUAUgYAAJ8EAwJSBQEAvAICjQMAAACfAgQCuz4CA1IEAgCkAwcAAABgQJ8DAgIrAxkAuz8AA1IFAACkBAkAAACAQJ8EAgK7PwEDUgYBAKQFCQAAAIBAnwUCAqQGBAAADCCAbwcFAFIIAACfBgMCpAcLAAAAoEBvCQwAUgoEAG8LDQBSDAUAbw0OAFIOBgBzCAkOnwcCAYIDAgAPAgAAAAAAAAAAAwEDAgMDBAAMIIADBAMFBAAAYEADBgQAAIBAAwcEAACgQAMIAwkDCgABCwEYAAABAgAAAAAAAAAAAAEAAAAAAQEAAAAAAQAAAAABAAAAAAEAAAAAAAAAAAACAgAAAAABAAABAgAHowAAAMAAAAAYAACfAQAAADUAAJ8BAAAAggACAAIGAAMLAQABAAEYAAAAAA4AAAEAAAAAAdDZrq5a9yNTJUhlLF0S0regwbna4h3Erw==

-- decompilation:
function NiceExp10(p1, p2) -- line: 1
	if p2 == 0.0 then
		return p1
	end

	local num = tonumber(`{ string.format("%f", p1) }e{ p2 }`)

	if not num then
		local str = tostring(p1)
		local str2 = tostring(p2)
		local v6 = string.format("%f", p1)

		error("x:" .. str .. " y:" .. str2 .. " fmt(x):" .. v6)
	end

	return num
end

return NiceExp10

