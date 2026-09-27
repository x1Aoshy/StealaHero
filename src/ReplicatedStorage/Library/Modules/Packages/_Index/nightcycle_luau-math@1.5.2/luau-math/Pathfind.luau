-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
({}).__index = {}

return function(t1: {[any]: any}, p1: ((...any) -> ...any)) -- line: 9
	local t2 = {}

	for k, v in pairs(t1) do
		for _, v2 in ipairs(v) do
			t2[v2] = t2[v2] or {}
			t2[v2][k] = p1(k, v2)
		end
	end

	local function getScoredDistances(p2) -- line: 19
		-- upvalues: t2 (copy)
		local t3 = {
			[p2] = 0.0
		}

		for k, _ in pairs(t2) do
			if k ~= p2 then
				t3[k] = 1e999
				table.insert({}, k)
			end
		end

		local function scoreStep(p3, n1: number) -- line: 31
			-- upvalues: p2 (copy), t3 (copy), t2 (copy), scoreStep (copy)
			if p3 == p2 then
				return
			end

			if t3[p3] and n1 < t3[p3] then
				t3[p3] = n1

				for k, v in pairs(t2[p3]) do
					scoreStep(k, n1 + v)
				end
			end
		end

		for k, v in pairs(t2[p2]) do
			scoreStep(k, v)
		end

		return t3
	end

	local t4 = {}
	local t5 = {}

	return function(p4, p5) -- line: 51
		-- upvalues: t4 (copy), t5 (copy), getScoredDistances (copy), t1 (copy)
		local t6 = {}

		t4[p4] = t4[p4] or {}

		if t4[p4][p5] ~= nil then
			for _, v in ipairs(t4[p4][p5]) do
				table.insert(t6, v)
			end

			return t6
		end

		if t5[p5] == nil then
			t5[p5] = getScoredDistances(p5)
		end

		local v23 = t5[p5]

		local function assemblePath(p6) -- line: 68
			-- upvalues: t6 (copy), t4 (copy), p4 (copy), p5 (copy), t1 (copy), v23 (copy), assemblePath (copy)
			table.insert(t6, p6)
			table.insert(t4[p4][p5], p6)

			if p6 == p5 then
				return
			end

			local v33 = nil

			for _, v in ipairs(t1[p6] or {}) do
				if v23[v] < 1e999 then
					v33 = v
				end
			end

			if v33 then
				assemblePath(v33)
			end
		end

		t4[p4][p5] = {}
		assemblePath(p4)

		local t7 = {}

		for i, v in ipairs(t6) do
			t7[#t6 - i + 1.0] = v
		end

		t4[p5] = t4[p5] or {}
		t4[p5][p4] = t7

		return t6
	end
end

