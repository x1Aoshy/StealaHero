-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local t1 = {
	_TYPE = "module",
	_NAME = "digest.crc32",
	_VERSION = "0.3.20111128"
}

local function requireany(...) -- line: 128
	local t2 = {}

	for _, v in ipairs({ ... }) do
		if type(v) ~= "string" then
			return v, ""
		end

		local ok, result = pcall(require, v)

		if ok then
			return result, v
		end

		t2[#t2 + 1.0] = result
	end

	error(table.concat(t2, "\n"), 2.0)
end

local bxor = bit32.bxor
local bnot = bit32.bnot
local band = bit32.band
local rshift = bit32.rshift

local function memoize(p1) -- line: 152
	local t3 = {}
	local self = setmetatable({}, t3)

	function t3.__index(_, p3) -- line: 155
		-- upvalues: p1 (copy), self (copy)
		local v33 = p1(p3)

		self[p3] = v33

		return v33
	end

	return self
end

local v8 = memoize(function(p4) -- line: 164
	-- upvalues: band (copy), rshift (copy), bxor (copy)
	for _ = 1.0, 8.0 do
		local v21 = band(p4, 1.0)

		p4 = rshift(p4, 1.0)

		if v21 == 1.0 then
			p4 = bxor(p4, 3988292384.0)
		end
	end

	return p4
end)

function t1.crc32_byte(p5, p6) -- line: 176
	-- upvalues: bnot (copy), rshift (copy), v8 (copy), bxor (copy)
	local v24 = bnot(p6 or 0.0)

	return (bnot((bxor(rshift(v24, 8.0), v8[bxor(v24 % 256.0, p5)]))))
end

local crc32_byte = t1.crc32_byte

function t1.crc32_string(p7, p8) -- line: 184
	-- upvalues: crc32_byte (copy)
	local v27 = p8 or 0.0

	for i = 1.0, #p7 do
		v27 = crc32_byte(p7:byte(i), v27)
	end

	return v27
end

local crc32_string = t1.crc32_string

function t1.crc32(p9, p10) -- line: 193
	-- upvalues: crc32_string (copy), crc32_byte (copy)
	if type(p9) == "string" then
		return crc32_string(p9, p10)
	end

	return crc32_byte(p9, p10)
end

return t1

