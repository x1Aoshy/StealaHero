-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetItem = require(ReplicatedStorage.Library.Types.AssetItem)
local Personalities = require(ReplicatedStorage.Directory.Assets.Personalities)
local Assets = require(ReplicatedStorage.Directory.Assets)
local AssetGenerationUtil = require(ReplicatedStorage.Library.Util.AssetGenerationUtil)
local Commas = require(ReplicatedStorage.Library.Functions.Commas)
local t1 = {}

local function createItemData(s1: string) -- line: 23
	-- upvalues: Personalities (copy)
	return {
		Scale = 1.0,
		HasBeenFirstPlaced = true,
		Category = s1,
		Mutations = {},
		Personality = Personalities.Personalities.Normal
	}
end

function t1.GetIndexMoneyRewardAmount(s2: string) -- line: 37
	-- upvalues: Personalities (copy), AssetGenerationUtil (copy)
	local t2 = {
		Scale = 1.0,
		HasBeenFirstPlaced = true,
		Category = s2,
		Mutations = {},
		Personality = Personalities.Personalities.Normal
	}

	return (math.round(AssetGenerationUtil.GetBaseRateMutationOnly(t2) * 100.0))
end
function t1.GetIndexSpeedRewardAmount(s3: string) -- line: 44
	-- upvalues: Assets (copy)
	return Assets.Directory[s3].IndexSpeedReward
end
function t1.GetVisualWeightKg(p1) -- line: 49
	-- upvalues: AssetItem (copy), Assets (copy)
	assert(AssetItem.AssetItemData(p1))

	return Assets.Directory[p1.Category].ModelWeight * math.max(p1.Scale, 0.0) ^ 3.0
end
function t1.GetVisualWeightKgDisplay(p2) -- line: 59
	-- upvalues: Commas (copy), t1 (copy)
	return `{ Commas((math.max(math.round(t1.GetVisualWeightKg(p2) * 100.0) / 100.0, 0.0))) }Kg`
end

return t1

