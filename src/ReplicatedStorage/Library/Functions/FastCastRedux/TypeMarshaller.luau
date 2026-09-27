-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMEBXRhYmxlDGdldG1ldGF0YWJsZQZfX3R5cGUGdHlwZW9mAAIFAQEAAAAZuywAAlICAAD7AQAAnwECAvABAgAAAAAAggECALs8AANSAwAApAICAAAAEECfAgICuywCAlIEAgD7AwAAnwMCAvADAgAAAAAAggECAE0DApkDAAAARwMCAAAAAICCAQIAggMCAAQDAQMCBAAAEEADAwAFBAEYAAAAAAEAAQQAAAAAAQAAAAAAAQQAAQABBAYAAAAAAgAAAQIABqMAAACkAAEAAAAAQMABAgASAAAAggECAAMDBAQAAABABgABAAEAARgAAwABABYBAAAAAAE=

-- decompilation:
local _typeof = typeof

local function typeof2(p1) -- line: 5
	-- upvalues: _typeof (copy)
	local v4 = _typeof(p1)

	if v4 ~= "table" then
		return v4
	end

	local mt = getmetatable(p1)

	if _typeof(mt) ~= "table" then
		return v4
	end

	local __type = mt.__type

	if __type == nil then
		return v4
	end

	return __type
end

return typeof2

