-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBHR5cGUGbnVtYmVyBmFzc2VydAhJbmZpbml0eQNOYU4EbWF0aANtYXgEY2VpbAZpcGFpcnMIdG9zdHJpbmcBcwEwAToFdGFibGUGaW5zZXJ0BmNvbmNhdA5Gb3JtYXREdXJhdGlvbgACEgEBAAA3AwEMBQECDw8KNwYPCzcGAwtYFw8MXRICClQbAgEjUgICJVACAydOAgQpTA8FKksCBjJDDwdLKnW7KAADUgQAAKQDAQAAAABAnwMCAvADAgACAAAAqQIAAakCAQC7AQICpAEEAAAAMECfAQIBDQADAAUAAIBvAQYAggECAPEAAwAAAAAAbwEHAIIBAgCMAgAAnhICBAAAAABSAwAApAEKAAAkgICfAQMCUgABALsHAANSAgAApAEMAAAsgICfAQICUgABACEBAA22AAANIQIADbYAAA0hAwAOtgAADlIEAAD/BQAABAAAAFIGBABSBwMAUggCAFIJAQDFBQYFAQAAABwGBQCkBxAAAADwQFIIBQCfBwIEUQcFAIwMAABgDAMACwAAAFIGCgBlAAIAbgf6/wIAAIAcBwUAmgYKAAcAAAC7PwEDUgsBAKQKEgAAABBBnwoCAlIICgBvCRMAcwcICYIHAgD/BwAAAQAAAIcJBQa7PwkCpAgSAAAAEEGfCAICxQcIAgEAAACVCgYUHAgFAIwJAQCoCBgAhwwFCrs/DAKkCxIAAAAQQZ8LAgL7DQAAhwwNChwNCwBgDQUADAAAAG8NFQBSDgsAcwsNDkgA+f9vEBYAUhELAHMPEBGeNAcEDwAAAFIOBwCkDRkAAGBwgZ8NAwGLCOj/pAgbAABocIFSCQcAnwgCAIIIAAAcAwEEAAAAQAMCAwMEAAAwQAIAAAAAAADwfwMEAwUDBgMHBAAkgIADCAQALICAAgAAAAAAAE5AAgAAAAAAADhAAwkEAADwQAMKBAAAEEEDCwIAAAAAAADwPwMMAw0DDgMPBABgcIEDEAQAaHCBABYRARgAAAAAAAAAAAAAAAAAAgABAAIAAQADAAAAAAAAAAEAAAAAAAIBAQEBAQECAAAAAAAAAAEBAAAAAAEAAAEB/QAHAAABAAAAAAAAAAADAAEAAAAAAAACAAAAAQAAAAABAAEAAAEAAP8DAAAAAAAAAAD6CAAAAAAXAAAAAAUAAAEDCwAAAg8AAQsPAQkDDKMAAAD/AAAABAAAAIwBAACMAgIAjAMCAIwEAgDFAAEFAQAAAMABAAASAAAAggECAAEGAAEAAQABGAATAAAAAAAAAAIAMAEAAAAAAdnHpg1voZTx85BE9J7mBFmp37F56wPMDA==

-- decompilation:
--!native
local t1 = {
	0.0,
	2.0,
	2.0,
	2.0
}

local function FormatDuration(n1: number) -- line: 22
	-- upvalues: t1 (copy)
	assert(type(n1) == "number")

	if n1 == 1e999 then
		return "Infinity"
	end

	if n1 ~= n1 then
		return "NaN"
	end

	local v4 = math.ceil((math.max(0.0, n1)))
	local v5 = v4 % 60.0
	local v6 = v4 // 60.0
	local v7 = v6 % 60.0
	local v8 = v6 // 60.0
	local v9 = v8 % 24.0
	local t2 = {
		v8 // 24.0,
		v9,
		v7,
		v5
	}
	local v11 = #t2

	for i, v in ipairs(t2) do
		if v > 0.0 then
			v11 = i

			break
		end
	end

	if v11 == #t2 then
		return tostring(v5) .. "s"
	end

	local t3 = { (tostring(t2[v11])) }

	for i = v11 + 1.0, #t2 do
		local str = tostring(t2[i])
		local v17 = t1[i]

		while v17 > #str do
			str = "0" .. str
		end

		table.insert(t3, ":" .. str)
	end

	return table.concat(t3)
end

return FormatDuration

