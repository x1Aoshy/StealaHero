-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local t1 = {
	Compare = function(p1, p2) -- line: 3
		if p1 < p2 then
			return -1.0
		end

		if p2 < p1 then
			return 1.0
		end

		return 0.0
	end,
	Any = function(p3, p4, ...) -- line: 7
		local v6 = #p3
		local n1 = 1.0

		while n1 <= v6 do
			local v8 = n1 + (v6 - n1) // 2.0
			local v9 = p4(p3[v8], ...)

			if not (v9 > 0.0) then
				if v9 == 0.0 then
					return v8
				end

				n1 = v8 + 1.0

				continue
			end

			v6 = v8 - 1.0
		end

		return -n1
	end,
	Left = function(p5, p6, ...) -- line: 24
		local v12 = #p5
		local n2 = 1.0
		local v14 = false

		while n2 <= v12 do
			local v15 = n2 + (v12 - n2) // 2.0
			local v16 = p6(p5[v15], ...)

			if v16 > 0.0 then
				v12 = v15 - 1.0
			elseif v16 < 0.0 then
				n2 = v15 + 1.0
			else
				v12 = v15 - 1.0
				v14 = true
			end
		end

		return v14 and n2 or -n2
	end,
	Right = function(p7, p8, ...) -- line: 43
		local v19 = #p7
		local n3 = 1.0
		local v21 = false

		while n3 <= v19 do
			local v22 = n3 + (v19 - n3) // 2.0
			local v23 = p8(p7[v22], ...)

			if v23 > 0.0 then
				v19 = v22 - 1.0
			elseif v23 < 0.0 then
				n3 = v22 + 1.0
			else
				n3 = v22 + 1.0
				v21 = true
			end
		end

		return v21 and n3 or -n3
	end
}

function t1.InsertAny(p9, p10, p11) -- line: 62
	-- upvalues: t1 (copy)
	local v27 = math.abs((t1.Any(p9, p10, p11)))

	table.insert(p9, v27, p11)

	return v27
end
function t1.InsertLeft(p12, p13, p14) -- line: 69
	-- upvalues: t1 (copy)
	local v31 = math.abs((t1.Left(p12, p13, p14)))

	table.insert(p12, v31, p14)

	return v31
end
function t1.InsertRight(p15, p16, p17) -- line: 76
	-- upvalues: t1 (copy)
	local v35 = math.abs((t1.Right(p15, p16, p17)))

	table.insert(p15, v35, p17)

	return v35
end
function t1.Remove(p18, p19, p20) -- line: 83
	-- upvalues: t1 (copy)
	local v39 = t1.Left(p18, p19, p20)

	if v39 > 0.0 then
		for i = v39, #p18 do
			if p20 == p18[i] then
				table.remove(p18, i)

				return true
			end
		end
	end

	return false
end
function t1.NumberSearch(p21, p22) -- line: 96
	local v43 = #p21
	local n4 = 1.0

	while n4 <= v43 do
		local v45 = n4 + (v43 - n4) // 2.0
		local v46 = p21[v45]

		if not (p22 < v46) then
			if v46 == p22 then
				return v45
			end

			n4 = v45 + 1.0

			continue
		end

		v43 = v45 - 1.0
	end

	return n4 - 1.0
end
function t1.NumberAny(p23, p24) -- line: 113
	local v49 = #p23
	local n5 = 1.0

	while n5 <= v49 do
		local v51 = n5 + (v49 - n5) // 2.0
		local v52 = p23[v51]

		if not (p24 < v52) then
			if v52 == p24 then
				return v51
			end

			n5 = v51 + 1.0

			continue
		end

		v49 = v51 - 1.0
	end

	return -n5
end

return t1

