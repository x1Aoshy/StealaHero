-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local t1 = {}

function t1.CopyTable(p1) -- line: 3
	-- upvalues: t1 (copy)
	local t2 = {}

	for k, v in pairs(p1) do
		t2[k] = typeof(v) == "table" and t1.CopyTable(v) or v
	end

	return t2
end
function t1.Reconcile(p2, p3, p4) -- line: 11
	-- upvalues: t1 (copy)
	local v9 = p4 and t1.CopyTable(p2) or p2

	for k, v in pairs(p3) do
		if v9[k] == nil then
			v9[k] = typeof(v) == "table" and t1.CopyTable(v) or v
		end
	end

	return v9
end
function t1.CacheDirectory(p5, p6) -- line: 21
	-- upvalues: t1 (copy)
	local t3 = {}

	for _, child in ipairs(p5:GetChildren()) do
		local v17 = nil

		if child:IsA("ModuleScript") then
			v17 = p6 and p6(child) or require(child)
		end

		if v17 then
			t3[child.Name] = v17
		elseif child:IsA("Folder") or child:IsA("Model") then
			t3[child.Name] = t1.CacheDirectory(child, p6)
		else
			t3[child.Name] = nil
		end
	end

	return t3
end
function t1.DeepCopy(p7) -- line: 39
	-- upvalues: t1 (copy)
	if type(p7) == "table" then
		local t4 = {}

		for k, v in pairs(p7) do
			t4[t1.DeepCopy(k)] = t1.DeepCopy(v)
		end

		setmetatable(t4, t1.DeepCopy((getmetatable(p7))))

		return t4
	end

	return p7
end
function t1.DeepCopyRecursive(p8, p9) -- line: 52
	-- upvalues: t1 (copy)
	local v24 = p9 or {}

	if type(p8) == "table" then
		if v24[p8] then
			return v24[p8]
		end

		local t5 = {}

		v24[p8] = t5

		for k, v in pairs(p8) do
			t5[t1.DeepCopyRecursive(k, v24)] = t1.DeepCopyRecursive(v, v24)
		end

		setmetatable(t5, t1.DeepCopyRecursive(getmetatable(p8), v24))

		return t5
	end

	return p8
end

return t1

