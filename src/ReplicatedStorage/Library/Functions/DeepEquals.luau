-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBHR5cGUFdGFibGUMZ2V0bWV0YXRhYmxlBF9fZXEFcGFpcnMKRGVlcEVxdWFscwACDwMBAAAAe5oAAwABAAAAqQMBAIIDAgC7KAADUgQAAKQDAQAAAABAnwMCAvADCAACAACAuygBA1IEAQCkAwEAAAAAQJ8DAgLwAwMAAgAAAKkDAACCAwIAUgMCACsDAgD/AwAAAAAAAFICAwCHAwIAKwMCAP8DAAAAAAAAagMCAIcEAgCHAwQBDgMCAKkDAQCCAwIAhwMCASsDAgD/AwAAAAAAAGoDAgGHBAIBhwMEAA4DAgCpAwEAggMCAIcDAgCpBAEAagQDAYcDAgGpBAEAagQDALs8AANSBAAApAMEAAAAMECfAwICDgMIAE0EA+MFAAAADgQFAPEAAgABAAAAqQQAAakEAQCCBAIAuzwBA1IFAQCkBAQAAAAwQJ8EAgIOBAgATQUE4wUAAAAOBQUA8QACAAEAAACpBQABqQUBAIIFAgAcBQAAHAYBAPEFAwAGAAAAqQUAAIIFAgCkBQcAAABgQFIGAACfBQIEFwULAIcKAQhHCgcAAAAAAPsLAABSDAkAUg0KAFIOAgCfCwQCKwsCAKkLAACCCwIAbgX0/wIAAACkBQcAAABgQFIGAQCfBQIEFwULAIcKAAhHCgcAAAAAAPsLAABSDAkAUg0KAFIOAgCfCwQCKwsCAKkLAACCCwIAbgX0/wIAAACpBQEAggUCAAgDAQQAAABAAwIDAwQAADBAAwQDBQQAAGBAAAEGARgAAAEAAgAAAAAAAAAAAAAAAAABAAIAAAAAAQAAAAABAAABAAIAAAAAAQAAAQACAAABAAABAAAAAAEAAAABAAAAAAIAAAAAAQAAAAEAAAAAAgAAAAEAAgAAAAABAQAAAAAAAAABAP0ABgAAAAABAQAAAAAAAAABAP0ABgACAAAAAAEAAAECAASjAAAAwAAAABIAAACCAAIAAQYAAQABAAEYAAAALAEAAAAAASAfH7Ew32MCXazMR3z29xFQBwjFEtt1sA==

-- decompilation:
local function DeepEquals(p1, p2, p3) -- line: 1
	-- upvalues: DeepEquals (copy)
	if p1 == p2 then
		return true
	end

	if type(p1) ~= "table" or type(p2) ~= "table" then
		return false
	end

	local v5 = p3 or {}

	v5[p1] = v5[p1] or {}

	if v5[p1][p2] then
		return true
	end

	v5[p2] = v5[p2] or {}

	if v5[p2][p1] then
		return true
	end

	v5[p1][p2] = true
	v5[p2][p1] = true

	local mt = getmetatable(p1)

	if mt and mt.__eq then
		return p1 == p2
	end

	local mt2 = getmetatable(p2)

	if mt2 and mt2.__eq then
		return p1 == p2
	end

	if #p1 ~= #p2 then
		return false
	end

	for k, v in pairs(p1) do
		local v10 = p2[k]

		if v10 == nil or not DeepEquals(v, v10, v5) then
			return false
		end
	end

	for k, v in pairs(p2) do
		local v13 = p1[k]

		if v13 == nil or not DeepEquals(v, v13, v5) then
			return false
		end
	end

	return true
end

return DeepEquals

