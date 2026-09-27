-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOBHR5cGUGbnVtYmVyBmFzc2VydARtYXRoA21heARjZWlsA2luZgNuYW4GaXBhaXJzCHRvc3RyaW5nAXMBMAE6DkZvcm1hdER1cmF0aW9uAAIOAQEAAAYDAAAFAQJjuygAA1IEAACkAwEAAAAAQJ8DAgLwAwIAAgAAAKkCAAGpAgEAuwECAqQBBAAAADBAnwECAYwDAACeEgMEAAAAAFIEAACkAgcAABhQgJ8CAwK7BwICpAEJAAAgUICfAQICUgABAA0AAwAKAACAbwELAIIBAgDxAAMAAAAAAG8BDACCAQIAIQEADbYAAA0hAgANtgAADf8DAAAEAAAAtgQADiEFAA5SBgIAUgcBAMUDBAUBAAAAHAQDAKQFEAAAAPBAUgYDAJ8FAgRRBQUAjAoAAGAKAwAJAAAAUgQIAGUAAgBuBfr/AgAAgBwFAwCaBAoABQAAALs/AQNSCQEApAgSAAAAEEGfCAICUgYIAG8HEwBzBQYHggUCAIcGAwS7PwYCpAUSAAAAEEGfBQIClQgEFBwGAwCMBwEAqAYTAIcKAwi7PwoCpAkSAAAAEEGfCQIC+wsAAIcKCwgcCwkAYAsFAAoAAABvCxUAUgwJAHMJCwxIAPn/UgsFAG8MFgBSDQkAcwULDYsG7f+CBQIAFwMBBAAAAEADAgMDBAAAMEADBAMFBAAYUIADBgQAIFCAAgAAAAAAAPB/AwcDCAIAAAAAAABOQAIAAAAAAAA4QAMJBAAA8EADCgQAABBBAwsCAAAAAAAA8D8DDAMNAAMOARgAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQABAAEAAQADAQEBAgABAQEBAAADAQAAAAABAAABAf0ABwAAAQAAAAAAAAAAAwAAAAABAAAAAQAAAAABAAEAAAEAAP8DAAAA+ggEAAAAAAUAAAECABCjAAAA/wAAAAQAAACMAQAAjAICAIwDAgCMBAIAxQABBQEAAADAAQAAEgAAABgBAFwBAAAANQEAXAEAAACCAQIAAgYAAw4BAAEAARgAAAAAAAAAAAACAAAALQAAAQAAAAABo/4pNfD1xASNSqjxVg8RgdPmPkGROkM0

-- decompilation:
local t1 = {
	0.0,
	2.0,
	2.0,
	2.0
}

function FormatDuration(n1: number) -- line: 3
	-- upvalues: t1 (copy)
	assert(type(n1) == "number")

	local v3 = math.ceil((math.max(0.0, n1)))

	if v3 == 1e999 then
		return "inf"
	end

	if v3 ~= v3 then
		return "nan"
	end

	local v4 = v3 % 60.0
	local v5 = v3 // 60.0
	local v6 = v5 % 60.0
	local v7 = v5 // 60.0
	local t2 = {
		v7 // 24.0,
		v7 % 24.0,
		v6,
		v4
	}
	local v9 = #t2

	for i, v in ipairs(t2) do
		if v > 0.0 then
			v9 = i

			break
		end
	end

	if v9 == #t2 then
		return tostring(v4) .. "s"
	end

	local str = tostring(t2[v9])

	for i = v9 + 1.0, #t2 do
		local str2 = tostring(t2[i])
		local v15 = t1[i]

		while v15 > #str2 do
			str2 = "0" .. str2
		end

		str ..= ":" .. str2
	end

	return str
end

return FormatDuration

