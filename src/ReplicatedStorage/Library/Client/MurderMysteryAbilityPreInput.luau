-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOBXRhYmxlBnJlbW92ZQR0eXBlBnN0cmluZwAkYWJpbGl0eUlkIG11c3QgYmUgYSBub24tZW1wdHkgc3RyaW5nBmFzc2VydAhmdW5jdGlvbhpoYW5kbGVyIG11c3QgYmUgYSBmdW5jdGlvbgZpbnNlcnQIUmVnaXN0ZXIGaXBhaXJzA1J1bgZDRnJhbWUBDgAEBwAEAAAAIfsAAAAOAAEAggABAKkAAQDeAAAA+wEBAPsCAgCHAAECKwABAIIAAQAcAwAAjAEBAIwC//+oAQsAhwQAA/sFAwCaBAcABQAAAKQEAgAABACAUgUAAFIGAwCfBAMBZQABAIsB9f8cAQAADQEFAAMAAID7AQEA+wICAMYDAABqAwECggABAAQDAQMCBAAEAIACAAAAAAAAAAAAHQABGAAAAQIAAgAAAQEDAAAAAQAAAAEAAAAAAf0HAAABAAAAAh4AAAAABgIBAAAHBAAABQIDBTepAwAAuygAA1IFAACkBAEAAAAAQJ8EAgLwBAUAAgAAgPAAAgADAACAqQMAAakDAQCBAQMEBAAAAG8EBACkAgYAAABQQJ8CAwG7KAEDUgUBAKQEAQAAAABAnwQCAvAEAgAHAAAAqQMAAakDAQCBAQMECAAAAG8ECACkAgYAAABQQJ8CAwH7AwAAhwIDACsCBAD/AgAAAAAAAPsDAABqAgMAnjQCBQEAAABSBAIAUgUBAKQDCwAAKJCAnwMDAakDAADZBAAAEgED/xICAAASAAAAEgABAMEDAACCBAIADAMDBAAAAEADBAMFAwYDBwQAAFBAAwgDCQMBAwoEACiQgAEAEAsBGAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAIAAQEAAQADAAAAAAAAAgEAAAAAAAARAAAAAAwCAQAABwQAAAUCA4QsqQMAALsoAANSBQAApAQBAAAAAECfBAIC8AQFAAIAAIDwAAIAAwAAgKkDAAGpAwEAgQEDBAQAAABvBAQApAIGAAAAUECfAgMB+wMAAIcCAwAOAgMAHAMCAA0DAwAHAACAxgMAAIIDAgBSAwEAKwMCAP8DAAAAAAAAxgQAAKQFCQAAAIBAUgYCAJ8FAgRRBQUAUgoJAFILAwCfCgICDgoBAFIECgBuBfr/AgAAgIIEAgAKAwMEAAAAQAMEAwUDBgMHBAAAUEACAAAAAAAAAAADDAQAAIBAADUNARgAAAAAAAAAAAAAAAAAAAAAAAACAAEAAAABAAMAAAABAQAAAAABAAABAf0ABzYAAAAAAwAAAQIADqMAAAD/AAIAAAAAAP8BAAAAAAAAwAIAABIAAQAwAgCDAQAAAMACAgASAAEAMAIAFgMAAACCAAIABAYBAwsGAgMNAgECAQABGAAKAAIAAwAAACUAAAAUAQAAAAADMqSJenI60DjS4wJ64SKbKUK8ng4AYON7

-- decompilation:
local t1 = {}
local t2 = {}

function t1.Register(s1: string, p1: ((...any) -> ...any)) -- line: 16
	-- upvalues: t2 (copy)
	assert(type(s1) == "string" and s1 ~= "", "abilityId must be a non-empty string")
	assert(type(p1) == "function", "handler must be a function")

	local v5 = t2[s1]

	if not v5 then
		v5 = {}
		t2[s1] = v5
	end

	table.insert(v5, p1)

	local u6 = false

	return function() -- line: 29
		-- upvalues: u6 (ref), t2 (copy), s1 (copy), p1 (copy)
		if u6 then
			return
		end

		u6 = true

		local v15 = t2[s1]

		if not v15 then
			return
		end

		for i = #v15, 1.0, -1.0 do
			if v15[i] == p1 then
				table.remove(v15, i)

				break
			end
		end

		if #v15 == 0.0 then
			t2[s1] = nil
		end
	end
end
function t1.Run(s2: string, t3: {[any]: any}?) -- line: 53
	-- upvalues: t2 (copy)
	assert(type(s2) == "string" and s2 ~= "", "abilityId must be a non-empty string")

	local v9 = t2[s2]

	if not v9 or #v9 == 0.0 then
		return nil
	end

	local v10 = t3 or {}
	local v11 = nil

	for _, v in ipairs(v9) do
		local v14 = v(v10)

		if v14 then
			v11 = v14
		end
	end

	return v11
end

return t1

