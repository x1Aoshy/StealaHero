-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = require(ReplicatedStorage.Directory.Assets)
local t1 = {}

local function parseMutations(p1) -- line: 25
	if typeof(p1) ~= "string" or p1 == "" then
		return {}
	end

	local t2 = {}

	for match in string.gmatch(p1, "[^,%s]+") do
		if match ~= "" and match ~= "Alpha" then
			table.insert(t2, match)
		end
	end

	return t2
end
local function cloneDropTable(t3: {[any]: any}?) -- line: 40
	if not t3 then
		return nil
	end

	local t4 = {}

	for i, v in ipairs(t3) do
		t4[i] = {
			v[1.0],
			v[2.0]
		}
	end

	return t4
end

function t1.GetTimerConfig(p2) -- line: 54
	-- upvalues: Assets (copy), parseMutations (copy), cloneDropTable (copy)
	if not p2:IsA("BasePart") then
		return nil
	end

	local AssetId = p2:GetAttribute("AssetId")
	local Time = p2:GetAttribute("Time")

	if typeof(AssetId) ~= "string" or typeof(Time) ~= "number" then
		return nil
	end

	local v16 = Assets.Directory[AssetId]

	if not v16 then
		return nil
	end

	local BaseMutation = p2:GetAttribute("BaseMutation")
	local v18 = if typeof(BaseMutation) ~= "string" or BaseMutation == "Alpha" then nil else BaseMutation
	local v19 = parseMutations(p2:GetAttribute("Mutations"))
	local v20 = math.max(Time, 0.0)
	local BaseScale = p2:GetAttribute("BaseScale")
	local v22 = if typeof(BaseScale) ~= "number" then math.max(v16.BaseModelScale or 1.0, 0.0) else math.max(BaseScale, 0.0)
	local v23 = cloneDropTable(v16.LuckyBlockDropTable) or {}

	return {
		assetId = AssetId,
		duration = v20,
		mutations = v19,
		baseMutation = v18,
		baseScale = v22,
		scale = v22,
		dropTable = v23
	}
end
function t1.CloneDropTable(t5: {[any]: any}?) -- line: 95
	-- upvalues: cloneDropTable (copy)
	return (cloneDropTable(t5))
end

return t1

