-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

require(ReplicatedStorage.Library.Types.Eggs)

return {
	RollScale = function(t1: {[any]: any}, p1, n1: number?, n2: number?, p2) -- line: 24
		-- upvalues: Asserts (copy)
		Asserts.table(t1)
		Asserts.optional.number(n1)
		Asserts.optional.number(n2)
		Asserts.optional.func(p2)

		local v8 = p1 or Random.new()
		local n3 = 0.0

		for _, v in ipairs(t1) do
			Asserts.number(v.min)
			Asserts.number(v.max)
			Asserts.number(v.weight)
			assert(v.max >= v.min, "Scale tier max must be greater than or equal to min")
			assert(v.weight > 0.0, "Scale tier weight must be positive")

			local v12 = not p2 and 1.0 or p2(v.min, v.max)

			Asserts.finite(v12)
			assert(v12 > 0.0, "Scale tier weight multiplier must be positive")
			n3 += v.weight * v12
		end

		assert(n3 > 0.0, "Scale tier table must include positive weight")

		local v13 = t1[1.0]
		local v14 = v8:NextNumber() * n3
		local n4 = 0.0

		for _, v in ipairs(t1) do
			local v18 = not p2 and 1.0 or p2(v.min, v.max)

			n4 += v.weight * v18

			if v14 <= n4 then
				v13 = v

				break
			end
		end

		local v19 = v13.min + v8:NextNumber() * (v13.max - v13.min)
		local v20 = n2 or 0.0

		if n1 and v20 > 0.0 then
			while n1 >= v19 * 2.0 and v20 >= v8:NextNumber() do
				v19 *= 2.0
			end
		end

		return v19
	end
}

