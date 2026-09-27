-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local TestEnum = require(script.Parent.TestEnum)
local t1 = {
	[TestEnum.TestStatus.Success] = "+",
	[TestEnum.TestStatus.Failure] = "-",
	[TestEnum.TestStatus.Skipped] = "~"
}
local t2 = {}

t2.__index = t2

function t2.new(p1) -- line: 25
	-- upvalues: t2 (copy)
	local t3 = {
		successCount = 0.0,
		failureCount = 0.0,
		skippedCount = 0.0,
		planNode = p1,
		children = {},
		errors = {}
	}

	setmetatable(t3, t2)

	return t3
end
function t2.createNode(p2) -- line: 43
	return {
		status = nil,
		planNode = p2,
		children = {},
		errors = {}
	}
end
function t2.visitAllNodes(p3, p4, p5) -- line: 57
	local v10 = p5 or p3

	for _, v in ipairs(v10.children) do
		p4(v)
		p3:visitAllNodes(p4, v)
	end
end
function t2.visualize(p6, p7, p8) -- line: 70
	-- upvalues: TestEnum (copy), t1 (copy)
	local v16 = p7 or p6
	local v17 = p8 or 0.0
	local t4 = {}

	for _, v in ipairs(v16.children) do
		if v.planNode.type == TestEnum.NodeType.It then
			local v21 = t1[v.status] or "?"
			local v22 = ("%s[%s] %s"):format((" "):rep(3.0 * v17), v21, v.planNode.phrase)

			if v.messages and #v.messages > 0.0 then
				v22 ..= "\n " .. (" "):rep(3.0 * v17) .. table.concat(v.messages, "\n " .. (" "):rep(3.0 * v17))
			end

			table.insert(t4, v22)
		else
			local v23 = ("%s%s"):format((" "):rep(3.0 * v17), v.planNode.phrase or "")

			if v.status then
				v23 ..= (" (%s)"):format(v.status)
			end

			table.insert(t4, v23)

			if #v.children > 0.0 then
				table.insert(t4, (p6:visualize(v, v17 + 1.0)))
			end
		end
	end

	return table.concat(t4, "\n")
end

return t2

