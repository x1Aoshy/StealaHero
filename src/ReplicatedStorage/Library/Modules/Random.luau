-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local t1 = {}

function t1.new(p1) -- line: 5
	-- upvalues: t1 (copy)
	local random = nil

	if p1 == nil then
		random = Random.new()
	elseif type(p1) == "number" then
		random = Random.new(p1)
	elseif typeof(p1) == "Random" then
		random = p1
	else
		error("Unknown alternative seed type: " .. typeof(p1))
	end

	return {
		new = t1.new,
		handle = function() -- line: 18
			-- upvalues: random (ref)
			return random
		end,
		clone = function() -- line: 21
			-- upvalues: t1 (copy), random (ref)
			return t1.new(random:Clone())
		end,
		seed = function(p2) -- line: 24
			-- upvalues: random (ref)
			random = Random.new(p2)
		end,
		number = function(p3, p4) -- line: 27
			-- upvalues: random (ref)
			return p3 and random:NextNumber(p3, p4) or random:NextNumber()
		end,
		boolean = function(p5) -- line: 30
			-- upvalues: random (ref)
			return random:NextNumber() < (p5 or 0.5)
		end,
		integer = function(p6, p7) -- line: 33
			-- upvalues: random (ref)
			return random:NextInteger(p6, p7)
		end,
		normal = function(p8, p9) -- line: 36
			-- upvalues: random (ref)
			local v12 = math.sqrt(math.log((math.max(2.2250738585072014E-308, random:NextNumber()))) * -2.0) * (p9 or 1.0)
			local v13 = random:NextNumber() * 6.283185307179586
			local v14 = p8 or 0.0

			return v12 * math.cos(v13) + v14, v12 * math.sin(v13) + v14
		end,
		Vector3 = function(p10) -- line: 45
			-- upvalues: random (ref)
			return random:NextUnitVector() * (p10 or 1.0)
		end,
		Vector2 = function(p11) -- line: 48
			-- upvalues: random (ref)
			local v17 = 6.283185307179586 * random:NextNumber()

			return Vector2.new(math.cos(v17), (math.sin(v17))) * (p11 or 1.0)
		end,
		flatVector3 = function(p12) -- line: 52
			-- upvalues: random (ref)
			local v19 = 6.283185307179586 * random:NextNumber()
			local v20 = p12 or 1.0

			return (Vector3.new(math.cos(v19) * v20, 0.0, math.sin(v19) * v20))
		end
	}
end

t1.R = t1.new()

return t1

