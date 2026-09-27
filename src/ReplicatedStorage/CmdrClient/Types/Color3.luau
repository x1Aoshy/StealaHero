-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Util = require(script.Parent.Parent.Shared.Util)
local v2 = Util.MakeSequenceType({
	Prefixes = "# hexColor3 ! brickColor3",
	Length = 3.0,
	ValidateEach = function(p1, p2) -- line: 5
		if p1 == nil then
			return false, ("Invalid or missing number at position %d in Color3 type."):format(p2)
		end

		if p1 < 0.0 or p1 > 255.0 then
			return false, ("Number out of acceptable range 0-255 at position %d in Color3 type."):format(p2)
		end

		if p1 % 1.0 ~= 0.0 then
			return false, ("Number is not an integer at position %d in Color3 type."):format(p2)
		end

		return true
	end,
	TransformEach = tonumber,
	Constructor = Color3.fromRGB
})

local function parseHexDigit(p3) -- line: 21
	if #p3 == 1.0 then
		p3 ..= p3
	end

	return (tonumber(p3, 16.0))
end

local t1 = {
	Transform = function(p4) -- line: 30
		-- upvalues: Util (copy), parseHexDigit (copy)
		local v9, v10, v11 = p4:match("^#?(%x%x?)(%x%x?)(%x%x?)$")

		return Util.Each(parseHexDigit, v9, v10, v11)
	end,
	Validate = function(p5, p6, p7) -- line: 35
		return p5 ~= nil and (p6 ~= nil and p7 ~= nil), "Invalid hex color"
	end,
	Parse = function(...) -- line: 39
		return Color3.fromRGB(...)
	end
}

return function(p8) -- line: 44
	-- upvalues: v2 (copy), Util (copy), t1 (copy)
	p8:RegisterType("color3", v2)
	p8:RegisterType("color3s", Util.MakeListableType(v2, {
		Prefixes = "# hexColor3s ! brickColor3s"
	}))
	p8:RegisterType("hexColor3", t1)
	p8:RegisterType("hexColor3s", Util.MakeListableType(t1))
end

