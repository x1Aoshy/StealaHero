-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMICHJhd2VxdWFsBHR5cGUFdGFibGUGcmF3bGVuDGdldG1ldGF0YWJsZQRuZXh0BnJhd2dldBREZWVwRXF1YWxzUHVyZVVuc2FmZQACCwIAAAAbAAAGDwdBEQ8FQBIPBkASDwdZCw8FWAwPBlgMaJ4zAAUBAAAAUgMAAFIEAQCkAgEAAAAAQJ8CAwIOAgIAqQIBAIICAgC7KAADUgMAAKQCAwAAACBAnwICAvACCAAEAACAuygBA1IDAQCkAgMAAAAgQJ8CAgLwAgkABAAAAPEABQAAAAAA8QEDAAEAAACpAgEAggICAKkCAACCAgIAuzoAA1IDAACkAgYAAABQQJ8CAgK7OgEDUgQBAKQDBgAAAFBAnwMCAvECAwADAAAAqQIAAIICAgC7PAADUgMAAKQCCAAAAHBAnwICArs8AQNSBAEApAMIAAAAcECfAwIC8QIDAAMAAACpAgAAggICAKQCCgAAAJBAUgMAAMYEAAAXAhEAnjIBBQUAAABSCAEAUgkFAKQHDAAAALBAnwcDAkcHBwAAAAAANQgAnA0AAABSCQYAUgoHAJ8IAwIrCAIAqQgAAIIIAgBuAu7/AgAAAKQCCgAAAJBAUgMBAMYEAAAXAgsAnjIABQUAAABSCAAAUgkFAKQHDAAAALBAnwcDAkcHAwAAAACAqQgAAIIIAgBuAvT/AgAAAKkCAQCCAgIADgMBBAAAAEADAgQAACBAAwMDBAQAAFBAAwUEAABwQAMGBAAAkEADBwQAALBAAwgAIQgBGAAAAAAAAAAAAQAEAAAAAAAAAAAAAAAAAAIAAAABAAIABAAAAAAAAAAAAAAAAQAEAAAAAAAAAAAAAAABAAQAAAAAAQAAAAAAAAEAAAAAAAAAAQD9AAgAAAAAAQAAAAAAAAEAAQD9AAcAIwAAAAABAAABAwAHowAAAMAAAAAYAACcAQAAADUAAJwBAAAAggACAAIGAAMIAQABAAEYACAAACwAAAEAAAAAAbAJfvO/OfBHuP2NVmgZ0ozAEWmHgs0U8g==

-- decompilation:
--!native
function DeepEqualsPureUnsafe(p1, p2) -- line: 33
	if rawequal(p1, p2) then
		return true
	end

	if type(p1) ~= "table" or type(p2) ~= "table" then
		if p1 ~= p1 and p2 ~= p2 then
			return true
		end

		return false
	end

	if rawlen(p1) ~= rawlen(p2) then
		return false
	end

	if getmetatable(p1) ~= getmetatable(p2) then
		return false
	end

	for k, v in next, p1 do
		local v5 = rawget(p2, k)

		if v5 == nil or not DeepEqualsPureUnsafe(v, v5) then
			return false
		end
	end

	for k, _ in next, p2 do
		if rawget(p1, k) == nil then
			return false
		end
	end

	return true
end

return DeepEqualsPureUnsafe

