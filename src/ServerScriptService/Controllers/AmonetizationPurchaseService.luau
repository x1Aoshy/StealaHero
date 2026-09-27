local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Database = require(game.ServerScriptService.Library.Database)
local EggItemUtil = require(ReplicatedStorage.Library.Util.EggItemUtil)
local Assets = require(ReplicatedStorage.Directory.Assets)
local LimitedEgg = require(ReplicatedStorage.Directory.LimitedEgg)
local LotteryCustom = require(ReplicatedStorage.Library.Functions.LotteryCustom)
local EggService = require(game.ServerScriptService.Controllers.EggService)
local SpeedService = require(game.ServerScriptService.Controllers.SpeedService)
local Treadmills = require(ReplicatedStorage.Directory.Treadmills)
local TreadmillUtil = require(ReplicatedStorage.Library.Util.TreadmillUtil)

local AmonetizationPurchaseService = {}

local PRODUCT_TO_CREATURE = {
	[3710872700] = "Ascended Vermilion Phoenix",
	[3710872653] = "Dragon",
	[3710655033] = "El Maja",
	[3710872409] = "Ice Dragon",
	[3710872622] = "Mosasaurus",
	[3710872586] = "Balrog",
	[3710872550] = "Eternal Lunar Dragon",
	[3710872502] = "Unicorn",
	[3710872463] = "Archdemon Dragon",
	[3710872360] = "Strawberry Elephant",
}

local RANDOM_BUTTON_PRODUCT_ID = 3709337621

local LIMITED_EGG_QUANTITIES = {
	[3710651062] = 1,
	[3710651062] = 3,
	[3710651062] = 10,
	[3710651062] = 50,
}

local TREADMILL_PRODUCT_LEVELS = {
	[3710651062] = 2, -- Sci-FiTreadmill
	[3710651062] = 3, -- FlameTreadmill
	[3710651062] = 4, -- CelebrityTreadmill
	[3710651062] = 5, -- GoldenTreadmill
	[3710651062] = 6, -- The FreezeTreadmill
	[3710651062] = 7, -- Lucky BlockTreadmill
	[3710651062] = 8, -- HackerTreadmill
	[3710651062] = 9, -- DemonicTreadmill
	[3710651062] = 10, -- AngelicTreadmill
}

local SPEED_BOOST_TIER_PRODUCTS = {
	[3710651062] = 1, -- x2
	[3710651062] = 2, -- x4
	[3710651062] = 3, -- x8
	[3710651062] = 4, -- x16
	[3710651062] = 5, -- x32
	[3710651062] = 6, -- x64
	[3710651062] = 7, -- x128
	[3710651062] = 8, -- x256
	[3710651062] = 9, -- x512
	[3710651062] = 10, -- x1024
	[3710651062] = 11, -- x2048
	[3710651062] = 12, -- x4096
}

local SPEED_HIT_OFFER_PRODUCT_ID = nil 
local SPEED_HIT_OFFER_AMOUNT = 500 

-- ECON 2026-09-24: amounts /125 with the whole money economy (was 200K / 24K / 4M / 800K / 8M), same values as the
-- live Game Pass packs in ConsumableGamepassService.
local MONEY_PACK_PRODUCTS = {
	[3710651062] = 1600,
	[3710651062] = 200,
	[3710651062] = 32000,
	[3710651062] = 6400,
	[3710651062] = 64000,
}
local SPEED_POWER_PACK_PRODUCTS = {
	[3710651062] = 50000000,
	[3710651062] = 1000000000,
	[3710651062] = 500000000,
	[3710651062] = 10000000,
	[3710651062] = 1000000,
	[3710651062] = 150000,
}
local TEMPORARY_SPEED_BOOST_PRODUCTS = {
	[3710651062] = 600, -- 10 minutes
	[3710651062] = 3600, -- 1 hour
	[3710651062] = 1800, -- 30 minutes
}
local SIZE_TIERS = {
	{ name = "Normal", weight = 85, multiplier = 1 },
	{ name = "Grande", weight = 12, multiplier = 4 },
	{ name = "Enorme", weight = 3, multiplier = 12 },
}

local RANDOM_BUTTON_SIZE_TIERS = {
	{ name = "Normal", weight = 70, multiplier = 1 },
	{ name = "Grande", weight = 20, multiplier = 5 },
	{ name = "Enorme", weight = 8, multiplier = 15 },
	{ name = "Gigante", weight = 2, multiplier = 25 },
}

local function rollSizeMultiplier(tiers)
	local total = 0
	for _, tier in ipairs(tiers) do
		total += tier.weight
	end
	local roll = math.random() * total
	local acc = 0
	for _, tier in ipairs(tiers) do
		acc += tier.weight
		if roll <= acc then
			return tier.multiplier, tier.name
		end
	end
	return 1, "Normal"
end

local uidCounter = 0
local function newUid()
	uidCounter += 1
	return "AdBuy_" .. os.time() .. "_" .. uidCounter
end

local function grantCreature(player, category, tiers)
	local profile = Database.Get(player)
	if not profile then
		return false
	end

	local ok, egg = pcall(EggItemUtil.BuildSavedEgg, category)
	if not ok then
		warn("[AmonetizationPurchaseService] BuildSavedEgg failed for " .. category .. ": " .. tostring(egg))
		return false
	end

	local multiplier, tierName = rollSizeMultiplier(tiers)
	egg.AssetScale = (egg.AssetScale or 1) * multiplier

	local ok2, itemData = pcall(EggItemUtil.BuildAssetItemData, egg)
	if not ok2 then
		warn("[AmonetizationPurchaseService] BuildAssetItemData failed for " .. category .. ": " .. tostring(itemData))
		return false
	end

	local uid = newUid()

	profile.Inventory[uid] = itemData
	Database.SetAndBroadcast(player, { Inventory = profile.Inventory })
	task.spawn(EggService.GrantAssetTool, player, uid, itemData)

	print(string.format("[AmonetizationPurchaseService] Granted %s (%s, x%d scale) to %s", category, tierName, multiplier, player.Name))
	return true
end

local function grantRandomCreature(player)
	local pool = {}
	for name in pairs(Assets.Directory) do
		table.insert(pool, name)
	end
	if #pool == 0 then
		return false
	end
	local category = pool[math.random(1, #pool)]
	return grantCreature(player, category, RANDOM_BUTTON_SIZE_TIERS)
end


local function grantLimitedEggBatch(player, quantity)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	local granted = 0
	for _ = 1, quantity do
		local ok, category = pcall(LotteryCustom, nil, LimitedEgg.DropTable)
		if ok and type(category) == "string" then
			local ok2, egg = pcall(EggItemUtil.BuildSavedEgg, category)
			if ok2 then
				profile.EggInventory[EggService.NewUid("Egg")] = egg
				granted += 1
			else
				warn("[AmonetizationPurchaseService] BuildSavedEgg failed for " .. tostring(category) .. ": " .. tostring(egg))
			end
		else
			warn("[AmonetizationPurchaseService] LimitedEgg lottery failed: " .. tostring(category))
		end
	end
	if granted == 0 then
		return false
	end
	Database.SetAndBroadcast(player, { EggInventory = profile.EggInventory })
	print(string.format("[AmonetizationPurchaseService] Granted %d/%d limited egg(s) to %s", granted, quantity, player.Name))
	return true
end

local function grantTreadmillLevelIfBetter(player, level)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	local current = profile.TreadmillUpgradeLevel or 1
	if level <= current then
		return true
	end
	local config = Treadmills.GetByUpgradeLevel(level)
	if not config then
		warn("[AmonetizationPurchaseService] No treadmill config for level " .. tostring(level))
		return false
	end
	Database.SetAndBroadcast(player, { TreadmillUpgradeLevel = level })
	SpeedService.Refresh(player)
	print(string.format("[AmonetizationPurchaseService] Granted %s (level %d) to %s via Robux skip", config._id, level, player.Name))
	return true
end

local function grantSpeedBoostTierIfBetter(player, tierIndex)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	local current = profile.SpeedBoostTierIndex or 0
	if tierIndex <= current then
		return true
	end
	Database.SetAndBroadcast(player, { SpeedBoostTierIndex = tierIndex })
	local multiplier = TreadmillUtil.GetSpeedBoostMultiplierForTierIndex(tierIndex)
	print(string.format("[AmonetizationPurchaseService] Granted SpeedBoostTier %d (x%d) to %s via Robux", tierIndex, multiplier, player.Name))
	return true
end

local function grantSpeedHitOfferBoost(player)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	Database.SetAndBroadcast(player, { SpeedPower = (profile.SpeedPower or 10) + SPEED_HIT_OFFER_AMOUNT })
	SpeedService.Refresh(player)
	print(string.format("[AmonetizationPurchaseService] Granted +%d SpeedPower (SpeedHitOffer) to %s", SPEED_HIT_OFFER_AMOUNT, player.Name))
	return true
end

local function grantMoneyPack(player, amount)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	Database.SetAndBroadcast(player, { Money = (profile.Money or 0) + amount })
	print(string.format("[AmonetizationPurchaseService] Granted +%d Money to %s", amount, player.Name))
	return true
end

local function grantSpeedPowerPack(player, amount)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	Database.SetAndBroadcast(player, { SpeedPower = (profile.SpeedPower or 10) + amount })
	SpeedService.Refresh(player)
	print(string.format("[AmonetizationPurchaseService] Granted +%d SpeedPower (pack) to %s", amount, player.Name))
	return true
end

local function grantTemporarySpeedBoost(player, durationSeconds)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	local now = Workspace:GetServerTimeNow()
	local currentRemaining = TreadmillUtil.ResolveTemporarySpeedBoostRemainingSeconds(profile, now)
	Database.SetAndBroadcast(player, {
		TemporarySpeedBoostRemainingSeconds = currentRemaining + durationSeconds,
		TemporarySpeedBoostActiveStartedAt = now,
	})
	print(string.format("[AmonetizationPurchaseService] Granted +%ds Temporary Speed Boost to %s (had %ds left)", durationSeconds, player.Name, currentRemaining))
	return true
end

local function grantEggGrowAll(player)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	local grownCount = 0
	for _, egg in pairs(profile.EggInventory) do
		if egg.Placement and egg.Placement.ReadyAt == nil then
			egg.Placement.ReadyAt = os.time()
			grownCount += 1
		end
	end
	Database.Set(player, { EggInventory = profile.EggInventory })
	print(string.format("[AmonetizationPurchaseService] Granted Grow All Eggs to %s (%d egg(s) finished)", player.Name, grownCount))
	return true
end

local processedReceipts = {}
local trollProducts = {
	[3710872795] = "Fling",
	[3710872835] = "Explode",
	[3710872862] = "Freeze",
	[3710872895] = "Trip",
	[3710872934] = "Kill",
	[3710872968] = "Kick",
	[3710872994] = "FlingAll",
	[3710873021] = "ExplodeAll",
	[3710873048] = "FreezeAll",
	[3710873079] = "KillAll",
	[3710873105] = "TripAll",
}
local runTrollAction = ServerStorage:FindFirstChild("RunTrollAction")

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local trollAction = trollProducts[receiptInfo.ProductId]
	if trollAction then
		local buyer = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not buyer or not (runTrollAction and runTrollAction:IsA("BindableEvent")) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if processedReceipts[receiptInfo.PurchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		runTrollAction:Fire(buyer, trollAction)
		processedReceipts[receiptInfo.PurchaseId] = true
		print(("[AmonetizationPurchaseService] Granted %s to %s"):format(trollAction, buyer.Name))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if processedReceipts[receiptInfo.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local category = PRODUCT_TO_CREATURE[receiptInfo.ProductId]
	local eggQuantity = LIMITED_EGG_QUANTITIES[receiptInfo.ProductId]
	local isRandomButton = receiptInfo.ProductId == RANDOM_BUTTON_PRODUCT_ID
	local treadmillLevel = TREADMILL_PRODUCT_LEVELS[receiptInfo.ProductId]
	local speedBoostTier = SPEED_BOOST_TIER_PRODUCTS[receiptInfo.ProductId]
	local isSpeedHitOffer = SPEED_HIT_OFFER_PRODUCT_ID ~= nil and receiptInfo.ProductId == SPEED_HIT_OFFER_PRODUCT_ID
	local moneyPackAmount = MONEY_PACK_PRODUCTS[receiptInfo.ProductId]
	local speedPowerPackAmount = SPEED_POWER_PACK_PRODUCTS[receiptInfo.ProductId]
	local tempSpeedBoostSeconds = TEMPORARY_SPEED_BOOST_PRODUCTS[receiptInfo.ProductId]
	local isEggGrowAll = receiptInfo.ProductId == EGG_GROW_ALL_PRODUCT_ID
	if not category and not eggQuantity and not isRandomButton and not treadmillLevel and not speedBoostTier and not isSpeedHitOffer and not moneyPackAmount and not speedPowerPackAmount and not tempSpeedBoostSeconds and not isEggGrowAll then
		-- Not one of ours; leave it for whatever else might handle Products in the future.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = Database.WaitForProfile(player, 30)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted
	if category then
		granted = grantCreature(player, category, SIZE_TIERS)
	elseif isRandomButton then
		granted = grantRandomCreature(player)
	elseif treadmillLevel then
		granted = grantTreadmillLevelIfBetter(player, treadmillLevel)
	elseif speedBoostTier then
		granted = grantSpeedBoostTierIfBetter(player, speedBoostTier)
	elseif isSpeedHitOffer then
		granted = grantSpeedHitOfferBoost(player)
	elseif moneyPackAmount then
		granted = grantMoneyPack(player, moneyPackAmount)
	elseif speedPowerPackAmount then
		granted = grantSpeedPowerPack(player, speedPowerPackAmount)
	elseif tempSpeedBoostSeconds then
		granted = grantTemporarySpeedBoost(player, tempSpeedBoostSeconds)
	elseif isEggGrowAll then
		granted = grantEggGrowAll(player)
	else
		granted = grantLimitedEggBatch(player, eggQuantity)
	end
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	processedReceipts[receiptInfo.PurchaseId] = true
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local PODIUM_NAMES = { "Elephant", "a", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", "b", "b2", "b3", "c1", "c2", "c3", "D1", "D2" }
local Amonetization = Workspace:FindFirstChild("Amonetization")
local promptCooldown = {}

if Amonetization then
	for _, name in ipairs(PODIUM_NAMES) do
		local podium = Amonetization:FindFirstChild(name)
		local hitboxes = podium and podium:FindFirstChild("Hitboxes")
		local hitbox = hitboxes and hitboxes:FindFirstChild("Hitbox")
		local configScript = podium and podium:FindFirstChild("Configuration")

		if hitbox and configScript then
			local ok, config = pcall(require, configScript)
			if ok and type(config) == "table" and config.ProductId then
				local productId = config.ProductId
				hitbox.Touched:Connect(function(otherPart)
					local character = otherPart.Parent
					local player = character and Players:GetPlayerFromCharacter(character)
					if not player then
						return
					end
					local now = os.clock()
					if promptCooldown[player] and now - promptCooldown[player] < 2 then
						return
					end
					promptCooldown[player] = now
					MarketplaceService:PromptProductPurchase(player, productId)
				end)
			else
				warn("[AmonetizationPurchaseService] Could not read Configuration for " .. name)
			end
		else
			warn("[AmonetizationPurchaseService] Missing Hitbox or Configuration for " .. name)
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	promptCooldown[player] = nil
end)

return AmonetizationPurchaseService
