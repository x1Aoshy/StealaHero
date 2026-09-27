-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local _select = select

local function v31(tbl, idx, ...)
	local va = { ... }

	for i = 1, _select("#", ...) do
		tbl[idx + i - 1] = va[i]
	end
end

local TestService = game:GetService("TestService")
local TestEnum = require(script.Parent.Parent.TestEnum)
local v3 = (" "):rep(3.0)
local t1 = {
	[TestEnum.TestStatus.Success] = "+",
	[TestEnum.TestStatus.Failure] = "-",
	[TestEnum.TestStatus.Skipped] = "~"
}
local t2 = {}

local function reportNode(p1, p2, p3) -- line: 22
	-- upvalues: TestEnum (copy), t1 (copy), v3 (copy), reportNode (copy)
	local v12 = p2 or {}
	local v13 = p3 or 0.0

	if p1.status == TestEnum.TestStatus.Skipped then
		return v12
	end

	local v14 = nil

	if p1.status ~= TestEnum.TestStatus.Success then
		local v15 = t1[p1.status] or "?"

		v14 = ("%s[%s] %s"):format(v3:rep(v13), v15, p1.planNode.phrase)
	end

	table.insert(v12, v14)

	for _, v in ipairs(p1.children) do
		reportNode(v, v12, v13 + 1.0)
	end

	return v12
end
local function reportRoot(p4) -- line: 47
	-- upvalues: reportNode (copy)
	local t3 = {}

	for _, v in ipairs(p4.children) do
		reportNode(v, t3, 0.0)
	end

	return t3
end
local function report(p5) -- line: 57
	-- upvalues: reportRoot (copy)
	local v23 = reportRoot(p5)

	return table.concat(v23, "\n")
end

function t2.report(p6) -- line: 63
	-- upvalues: reportRoot (copy), TestService (copy)
	local t4 = {}
	local s1 = "Test results:"
	local v27 = reportRoot(p6)
	local v28 = table.concat(v27, "\n")

	t4[1] = s1
	t4[2] = v28
	v31(t4, 3, ("%d passed, %d failed, %d skipped"):format(p6.successCount, p6.failureCount, p6.skippedCount))
	print(table.concat(t4, "\n"))

	if p6.failureCount > 0.0 then
		print(("%d test nodes reported failures."):format(p6.failureCount))
	end

	if #p6.errors > 0.0 then
		print("Errors reported by tests:")
		print("")

		for _, v in ipairs(p6.errors) do
			TestService:Error(v)
			print("")
		end
	end
end

return t2

