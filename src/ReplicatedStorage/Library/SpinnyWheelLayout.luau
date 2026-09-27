-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOBG1hdGgFY2xhbXAHcmVzZXJ2ZQV0YWJsZQZjcmVhdGUKYnVpbGRPcmRlcgVjbG9uZQZpcGFpcnMOQXJyYW5nZUVudHJpZXMUSW52YWxpZCByYXJpdHkgaW5kZXgGYXNzZXJ0H0ZhaWxlZCB0byBjb21wdXRlIGRpc3BsYXkgaW5kZXgPR2V0RGlzcGxheUluZGV4CEdldE9yZGVyAAYGAQIAAAYDAAAFAYIeDgAKAIwBAQB9AQgAAAAAAPsBAAB9AAUAAQAAAPsCAQCHAQIAKwEBAIIAAgCMAwEA+wEAAIwCAQCoAQUA+wUBAIcEBQMrBAEAggMCAIsB+/9SAgAAKwIBAPsCAACMAwEA+wQAAEwuAAKkAQIAAAQAgJ8BBAKCAQIAAwMBAwIEAAQAgAAUAwEYAAAAAAAAAAAAAAEDAAAAAQAAAf4GAAAAAAAAAAAAFQAAAAANAQEAAAYDAAAFAQI3jAEAAH0ABAABAAAA/wEAAAAAAACCAQIApAECAAAEAIBSAgAAnwECAqQCAgAABACAUgMAAJ8CAgLZAwAAEgAAABIAAgCMBgEAUgQAAIwFAQCoBCEA+wgAAIcHCAYOBwkAjAkBAH0JBwAHAAAAfQcFAAAAAACHCQIHKwkCAFIIBwBlABEAjAsBAFIJAACMCgEAqAkFAIcMAgsrDAIAUggLAGUACQCLCfv/ygkHAIwKAQA0LgkECgAAAFILAACkCAUAABAwgJ8IBAJqCAEGqQkBAGoJAgiLBN//ggECAAYDBAMFBAAEAIADAQMCBAAQMIABAAwGARgAAAABAAADAAAAAQAAAAIAAA4AAAABAPIAAAAAAAAAAQADAAAAAQABAP4GAAAAAAAAAAYBAPwHDQAAAAAKAQEAAAYDAAAFAQQaHAEAAIwCAQB9AQYAAgAAAKQCAgAABACAUgMAAJ8CAgCCAgAA+wIAAFIDAQCfAgICpAMEAAAMAIBSBAEAnwMCAqQEBgAAAFBAUgUAAJ8EAgRRBAIAhwkCB2oIAwluBP3/AgAAgIIDAgAHAwQDBwQABACAAwUEAAwAgAMIBAAAUEAALQkBGAABAAABAAAAAAMAAAEAAAACAAAAAAEA/wAELgAAAAAHAgEAAAcEAAAFAgICHakDAACMBAEAfQQFAAAAAADUAAIAAQAAAKkDAAGpAwEAgQEDBAAAAABvBAAApAICAAAAEECfAgMB+wIAAFIDAQCfAgIChwMCAEcDAgAAAACAqQUAAakFAQCBAQUEAwAAAG8GAwCkBAIAAAAQQJ8EAwGCAwIABAMKAwsEAAAQQAMMAD0NARgAAAAAAAAAAAAAAAAAAAIAAAECAAAAAAAAAAAAAj4AAAAAAwEBAAAGAwAABQECBPsBAABSAgAAnwECAoIBAgAAAEgOARgAAAAASQAAAAAHAAABAgAcowAAAP8AAAAGAAAAjAEBAIwCBACMAwMAjAQCAIwFBQCMBgYAxQABBwEAAAD/AQMAAAAAAMACAAASAAAAwAMBABIAAgAwAwFlAgAAAMADAwASAAIAMAMBwQQAAADAAwUAEgACADADAacGAAAAggECAAcGAQYCAwkGAwMNBgQDDgQBAgMEAQABGAADAAAAAAAAAAAABQADACEAAAAQAAAACwAAAAQBAAAAAAWfhCcDkn33BJLy8Jh7TB+k75wwd61ATQI=

-- decompilation:
local t1 = {
	1.0,
	4.0,
	3.0,
	2.0,
	5.0,
	6.0
}
local t2 = {}

local function buildOrder(n1: number) -- line: 12
	-- upvalues: t1 (copy)
	if n1 <= 0.0 then
		return {}
	end

	local t3 = table.create(n1)
	local t4 = table.create(n1)

	local function reserve(n2: number?) -- line: 20
		-- upvalues: n1 (copy), t4 (copy)
		if n2 and (n2 >= 1.0 and n2 <= n1 and not t4[n2]) then
			return n2
		end

		for i = 1.0, n1 do
			if not t4[i] then
				return i
			end
		end

		return (math.clamp(n2 or n1, 1.0, n1))
	end

	local g11 = nil

	for i = 1.0, n1 do
		local v9 = t1[i]

		if v9 and v9 >= 1.0 and v9 <= n1 and not t4[v9] then
		else
			for j = 1.0, n1 do
				if not t4[j] then
					v9 = j
					g11 = true
				end

				if g11 then
					break
				end
			end

			if not g11 then
				v9 = math.clamp(v9 or n1, 1.0, n1)
			end
		end

		g11 = false
		t3[i] = v9
		t4[v9] = true
	end

	return t3
end

function t2.ArrangeEntries(t5: {[any]: any}) -- line: 45
	-- upvalues: buildOrder (copy)
	local v13 = #t5

	if v13 <= 1.0 then
		return table.clone(t5)
	end

	local v14 = buildOrder(v13)
	local t6 = table.create(v13)

	for i, v in ipairs(t5) do
		t6[v14[i]] = v
	end

	return t6
end
function t2.GetDisplayIndex(n3: number, n4: number) -- line: 61
	-- upvalues: buildOrder (copy)
	assert(n3 >= 1.0 and n3 <= n4, "Invalid rarity index")

	local v20 = buildOrder(n4)[n3]

	assert(v20 ~= nil, "Failed to compute display index")

	return v20
end
function t2.GetOrder(n5: number) -- line: 72
	-- upvalues: buildOrder (copy)
	return (buildOrder(n5))
end

return t2

