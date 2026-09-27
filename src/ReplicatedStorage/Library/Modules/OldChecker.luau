-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local t1 = {
	"__index",
	"__newindex"
}
local t2 = {
	__proxy = {
		new = function(p1) -- line: 7
			-- upvalues: t1 (copy)
			if typeof(p1) ~= "table" then
				return
			end

			local v5 = newproxy(true)

			for _, v7 in t1 do
				getmetatable(v5)[v7] = p1
			end

			return v5
		end
	}
}

t2.__index = t2

local function Is_Structure_Valid(p2, p3) -- line: 24
	-- upvalues: Is_Structure_Valid (copy)
	if typeof(p2) ~= "table" or typeof(p3) ~= "table" then
		return warn("Invalid STRF structure params. Structure must be a table, got:", p2, ", object must be a table got:", p3)
	end

	local v10 = table.find({
		"string",
		"table"
	}, (typeof(p2.__generic))) and p2.__generic

	for v11, v12 in v10 and p3 or p2 do
		local v13 = v10 or v12
		local v14 = v10 and v12 or p3[v11]
		local v15 = typeof(v13) == "string" and { v13:gsub(";", "") }
		local v16 = v15 and v13:split(";")[1.0]:split("|")
		local v17 = v15 and (v15[2.0] > 0.0 and (#v13:split(";")[2.0] > 0.0 and v13:split(";")[2.0]:split("|")))

		if typeof(not v10 and v12 or (typeof(v10) == "table" and v10 or p2[v11])) ~= "table" then
			if not table.find(v16, (typeof(v14))) then
				return
			end

			if not (#v16 >= 2.0) or not (v15[2.0] > 0.0) or v14:IsA(v16[2.0]) and (not v17 or table.find(v17, v14.ClassName)) then
				continue
			end

			return
		end

		local v18 = v10 and {
			typeof(v10) == "table" and v10 or p2[v11],
			v12
		} or {
			v12,
			p3[v11]
		}

		if not Is_Structure_Valid(unpack(v18)) then
			return
		end
	end

	return p3
end

function t2.new(p4) -- line: 63
	-- upvalues: t2 (copy)
	return (setmetatable(p4, t2))
end
function t2.Request_Proxy(p5, p6, ...) -- line: 67
	-- upvalues: Is_Structure_Valid (copy)
	local v22 = Is_Structure_Valid(p5["Strct_" .. p6], { ... })

	return typeof(v22) == "table" and v22
end

return t2

