-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBHR5cGUFdGFibGUGbnVtYmVyBmlwYWlycxdXZWlnaHQgbXVzdCBiZSBhIG51bWJlcgZhc3NlcnQKTmV4dE51bWJlcgVlcnJvcjNMb3R0ZXJ5IHNlbGVjdGlvbiBmYWlsZWQgLSBpbXBvc3NpYmxlIHN0YXRlIHJlYWNoZWQGUmFuZG9tA25ldwACEwEBAQAGAwAABQGHb6MBAABSAQAAKwEBAPsBAAD/AgAAAAAAAN0DAADFAgMAAQAAABwDAgANAxIAAAAAgBMDAgC7KAMDUgUDAKQEAgAAABBAnwQCAvAECgADAACAEwQDAbsoBANSBgQApAUCAAAAEECfBQIC8AUCAAQAAABSAgMAjAMAAIwEAACMBQAApAYGAAAAUEBSBwIAnwYCBFEGGgATCwoBuygLA1IPCwCkDgIAAAAQQJ8OAgLwDgIABAAAAKkNAAGpDQEAgQENBAcAAABvDgcApAwJAAAAgECfDAMBjAwAAGAMCAALAAAAmgsGAAsAAAANCwQACgAAAJUDAwBDBAQLUgUJAG4G5f8CAACADQMHAAsAAIDGBgAAjAcAAIwIAACMCQAAjAoAAIIGBgCMCAAAUgkEALwGAYUMAAAAnwYEAlIHBgCkCAYAAABQQFIJAgCfCAIEUQgUABMNDAGMDgAAYA4RAA0AAACaDQ8ADQAAAA0NDQAKAAAAJgcHDYwOAADUBwMADgAAAJoLBwAFAAAAEw4MAOwPBgTsEA0EUhELAFISDQCCDgYAbgjr/wIAAICkCA4AAADQQG8JDwCfCAIBggABABACAAAAAAAA8D8DAQQAABBAAwIDAwMEBAAAUEADBQMGBAAAgEACAAAAAAAA8H8CAAAAAAAAAAADBwMIBAAA0EADCQAQAAEYAAEAAAEAAAAAAwAAAQEAAAAAAAABAQAAAAAAAAEGAQECAAAAAAEBAAAAAAAAAAAAAAAAAAACAAAAAAAAAQEB+QAMAAEAAAAAAAQAAAAAAQIAAAAAAQIAAAAAAAABAQAAAAABAAAAAAD6AAsAAAABEAAAAAACAAABAgAHowAAAKQAAgAABACAnwABAsABAwASAAAAggECAAQDCgMLBAAEAIAGAAEAAQABGAADAAAMAAABAAAAAAG7lkCXStS6GJc43TGjvgLDy45X44lSKpY=

-- decompilation:
local random = Random.new()

return function(p1, ...) -- line: 16
	-- upvalues: random (copy)
	local v3 = p1 or random
	local t1 = { ... }

	if #t1 == 1.0 then
		local v5 = t1[1.0]

		if type(v5) == "table" and type(v5[2.0]) ~= "number" then
			t1 = v5
		end
	end

	local n1 = 0.0
	local n2 = 0.0
	local n3 = 0.0

	for i, v in ipairs(t1) do
		local v11 = v[2.0]

		assert(type(v11) == "number", "Weight must be a number")

		if v11 > 0.0 and v11 == v11 and v11 ~= 1e999 then
			n1 += 1.0
			n2 += v11
			n3 = i
		end
	end

	if n1 == 0.0 then
		return nil, 0.0, 0.0, 0.0, 0.0
	end

	local v12 = v3:NextNumber(0.0, n2)
	local v13 = v12

	for i, v in ipairs(t1) do
		local v16 = v[2.0]

		if not (v16 > 0.0) or v16 ~= v16 or v16 == 1e999 then
			continue
		end

		v13 -= v16

		if v13 <= 0.0 or i == n3 then
			return v[1.0], v12 / n2, v16 / n2, i, v16
		end
	end

	error("Lottery selection failed - impossible state reached")
end

