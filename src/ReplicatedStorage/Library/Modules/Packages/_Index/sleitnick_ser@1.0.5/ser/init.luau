-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Option = require(script.Parent.Option)
local t1 = {
	Classes = {
		Option = {
			Serialize = function(p1) -- line: 73
				return p1:Serialize()
			end,
			Deserialize = Option.Deserialize
		}
	}
}

function t1.SerializeArgs(...) -- line: 85
	-- upvalues: t1 (copy)
	local v4 = table.pack(...)

	for i, v in ipairs(v4) do
		if type(v) == "table" then
			local v7 = t1.Classes[v.ClassName]

			if v7 then
				v4[i] = v7.Serialize(v)
			end
		end
	end

	return v4
end
function t1.SerializeArgsAndUnpack(...) -- line: 103
	-- upvalues: t1 (copy)
	local v8 = t1.SerializeArgs(...)

	return table.unpack(v8, 1.0, v8.n)
end
function t1.DeserializeArgs(...) -- line: 113
	-- upvalues: t1 (copy)
	local v9 = table.pack(...)

	for i, v in ipairs(v9) do
		if type(v) == "table" then
			local v12 = t1.Classes[v.ClassName]

			if v12 then
				v9[i] = v12.Deserialize(v)
			end
		end
	end

	return v9
end
function t1.DeserializeArgsAndUnpack(...) -- line: 131
	-- upvalues: t1 (copy)
	local v13 = t1.DeserializeArgs(...)

	return table.unpack(v13, 1.0, v13.n)
end
function t1.Serialize(p2) -- line: 141
	-- upvalues: t1 (copy)
	if type(p2) == "table" then
		local v15 = t1.Classes[p2.ClassName]

		if v15 then
			p2 = v15.Serialize(p2)
		end
	end

	return p2
end
function t1.Deserialize(p3) -- line: 156
	-- upvalues: t1 (copy)
	if type(p3) == "table" then
		local v17 = t1.Classes[p3.ClassName]

		if v17 then
			p3 = v17.Deserialize(p3)
		end
	end

	return p3
end
function t1.UnpackArgs(t2: {[any]: any}) -- line: 171
	return table.unpack(t2, 1.0, t2.n)
end

return t1

