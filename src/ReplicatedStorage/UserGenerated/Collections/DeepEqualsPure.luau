-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMIBHR5cGUFdGFibGUIcmF3ZXF1YWwGcmF3bGVuDGdldG1ldGF0YWJsZQRuZXh0BnJhd2dldA5EZWVwRXF1YWxzUHVyZQACDgMAAAAkBQAHBQMPD4QPCVkSDwdYEw8IWBMPCXILDwdxDA8IcQwPAyBlhQG7KAADUgQAAKQDAQAAAABAnwMCAvADCAACAACAuygBA1IEAQCkAwEAAAAAQJ8DAgLwAxMAAgAAAJ4zAAUBAAAAUgQAAFIFAQCkAwQAAAAwQJ8DAwIOAwIAqQMBAIIDAgDxAAUAAAAAAPEBAwABAAAAqQMBAIIDAgCpAwAAggMCAFIDAgArAwIA/wMAAAAAAACHBAMAKwQCAIcEAwEOBAIAqQQAAIIEAgCeMwAFAQAAAFIFAABSBgEApAQEAAAAMECfBAMCDgQCAKkEAQCCBAIAuzoAA1IFAACkBAYAAABQQJ8EAgK7OgEDUgYBAKQFBgAAAFBAnwUCAvEEAwAFAAAAqQQAAIIEAgC7PAADUgUAAKQECAAAAHBAnwQCArs8AQNSBgEApAUIAAAAcECfBQIC8QQDAAUAAACpBAAAggQCAKkEAQBqBAMAqQQBAGoEAwGkBAoAAACQQFIFAADGBgAAFwQSAJ4yAQUHAAAAUgoBAFILBwCkCQwAAACwQJ8JAwJHCQgAAAAAADUKAJkNAAAAUgsIAFIMCQBSDQMAnwoEAisKAgCpCgAAggoCAG4E7f8CAAAApAQKAAAAkEBSBQEAxgYAABcECwCeMgAFBwAAAFIKAABSCwcApAkMAAAAsECfCQMCRwkDAAAAAICpCgAAggoCAG4E9P8CAAAAxgQAAGoEAwDGBAAAagQDAakEAQCCBAIADgMBBAAAAEADAgMDBAAAMEADBAQAAFBAAwUEAABwQAMGBAAAkEADBwQAALBAAwgAIQgBGAAAAAAAAAAAAAAAAAAAAgAAAAAAAAABAAMAAAABAAIABAAAAAEAAAABAAQAAAAAAAAAAQAEAAAAAAAAAAAAAAABAAQAAAAAAAAAAAAAAAEABAABAAMAAAAAAQAAAAAAAAEAAAAAAAAAAAEA/QAIAAAAAAEAAAAAAAABAAEA/QAIAAEAAQAjAAAAAAEAAAEDAAejAAAAwAAAABgAAJkBAAAANQAAmQEAAACCAAIAAgYAAwgBAAEAARgAIAAAPQAAAQAAAAAB9EU6Y5iqRCcj4ZYbpwVnXYRdLRfGgVBi

-- decompilation:
--!native
function DeepEqualsPure(p1, p2, t1: {[any]: any}?) -- line: 33
	if type(p1) ~= "table" or type(p2) ~= "table" then
		if rawequal(p1, p2) then
			return true
		end

		if p1 ~= p1 and p2 ~= p2 then
			return true
		end

		return false
	end

	local v4 = t1 or {}

	if v4[p1] or v4[p2] then
		return false
	end

	if rawequal(p1, p2) then
		return true
	end

	if rawlen(p1) ~= rawlen(p2) then
		return false
	end

	if getmetatable(p1) ~= getmetatable(p2) then
		return false
	end

	v4[p1] = true
	v4[p2] = true

	for k, v in next, p1 do
		local v7 = rawget(p2, k)

		if v7 == nil or not DeepEqualsPure(v, v7, v4) then
			return false
		end
	end

	for k, _ in next, p2 do
		if rawget(p1, k) == nil then
			return false
		end
	end

	v4[p1] = nil
	v4[p2] = nil

	return true
end

return DeepEqualsPure

