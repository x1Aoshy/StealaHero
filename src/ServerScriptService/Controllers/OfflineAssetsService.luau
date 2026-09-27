-- ServerScriptService.Controllers.OfflineAssetsService
-- Handles "OfflineAssets: GetSummary"/"OfflineAssets: Redeem" (RemoteFunctions). Contract
-- confirmed by reading StarterPlayer...Game.Plots.OfflineMoney.OfflineMoneyBucketPiles (the
-- client bucket-pile claim visual, fully built) in full: GetSummary returns an
-- OfflineClaimSummary ({ClaimableAmount, ReservedAmount, TotalAmount,
-- IsMultiplierPurchasePending}, see Library.Types.OfflineAssets), Redeem takes
-- {Kind = "Claim"} and returns (ok: boolean, _, OfflineRedeemResult?) where
-- OfflineRedeemResult is {BaseAmount, AwardedAmount, ClaimedByUid}.
--
-- Design (no real formula exists anywhere in the rip for this -- same situation as
-- FuseMachine): while a player is away, their currently-equipped pets earn money at their
-- normal $/sec rate (AssetService.EarningRateFor, the same per-pet formula the live pen tick
-- and OfflineMoneyInPlotUI's own preview both already use), scaled by
-- Constants.OFFLINE_ASSETS.MONEY_RATE_MULTIPLIER (0.1 = 10% of the online rate) and capped per
-- absence at MAX_DURATION_SECONDS (10h, the real game's own constant, unchanged). Uses CURRENT
-- equipped pets to value the absence, not a frozen snapshot -- matches OfflineMoneyInPlotUI's
-- live preview, which does the exact same thing. Unclaimed amounts accumulate across multiple
-- absences until redeemed.
--
-- NOT built (needs a product decision from the user, not guessed -- same pattern as the DNA
-- steal Robux system left pending): ReservedAmount/IsMultiplierPurchasePending exist in the
-- real schema for a Robux offer that doubles your offline earnings -- always 0/false here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local AssetService = require(script.Parent.AssetService)
local OFFLINE_ASSETS = require(ReplicatedStorage.Library.Globals.Constants._Index.OFFLINE_ASSETS)

local Network = ReplicatedStorage:WaitForChild("Network")
local GetSummaryRemote = Network:WaitForChild("OfflineAssets: GetSummary")
local RequestRedeemRemote = Network:WaitForChild("OfflineAssets: Redeem")
local SummaryUpdatedRemote = Network:WaitForChild("OfflineAssets: SummaryUpdated")
local ClaimedRemote = Network:WaitForChild("OfflineAssets: Claimed")

local OfflineAssetsService = {}

local function computeTotalRate(profile)
	local totalRate = 0
	for _, uid in ipairs(profile.EquippedAssets or {}) do
		local itemData = profile.Inventory and profile.Inventory[uid]
		if itemData then
			totalRate += AssetService.EarningRateFor(profile, itemData)
		end
	end
	return totalRate
end

-- The whole dollars a claim pays right now (REVIEW_ECON 2026-09-24): the accrual stays fractional, Redeem credits
-- this floor and keeps the cents for the next absence, and the summary shows the same floor, so the bucket's
-- "precision-integer" label (ClaimVisual) always equals what the claim credits and no cent is ever dropped.
local function claimableWholeDollars(profile)
	local claimable = tonumber(profile.OfflineClaimableAmount) or 0
	if claimable ~= claimable or claimable == math.huge or claimable <= 0 then
		return 0
	end
	return math.floor(claimable)
end

local function buildSummary(profile)
	local claimable = claimableWholeDollars(profile)
	return {
		ClaimableAmount = claimable,
		ReservedAmount = 0,
		TotalAmount = claimable,
		IsMultiplierPurchasePending = false,
	}
end

-- ECON 2026-09-24: the whole money economy was divided by 125 (ReplicatedStorage.Library.Util.AssetGenerationUtil
-- MONEY_SCALE: income, prices, bounties, packs). A profile saved before that still holds old-scale Money and
-- OfflineClaimableAmount, which would buy the new, 125x cheaper ladders outright: bring it to the new scale once.
-- MoneyScaleVersion (saved with the profile) marks a converted profile; a profile that was never saved (LastSeenAt 0,
-- stamped by every Database save) already starts at the new scale and is only stamped.
local MONEY_SCALE_VERSION = 1
local MONEY_SCALE = 1 / 125

local function migrateMoneyScale(player, profile)
	if (tonumber(profile.MoneyScaleVersion) or 0) >= MONEY_SCALE_VERSION then
		return
	end
	local changes = { MoneyScaleVersion = MONEY_SCALE_VERSION }
	if (tonumber(profile.LastSeenAt) or 0) > 0 then
		local money = tonumber(profile.Money) or 0
		if money == money and money > 0 and money ~= math.huge then
			changes.Money = math.floor(money * MONEY_SCALE)
		end
		local claimable = tonumber(profile.OfflineClaimableAmount) or 0
		if claimable == claimable and claimable > 0 and claimable ~= math.huge then
			changes.OfflineClaimableAmount = math.floor(claimable * MONEY_SCALE)
		end
	end
	for key, value in pairs(changes) do
		profile[key] = value
	end
	local ok, err = pcall(Database.Set, player, changes)
	if not ok then
		warn("[OfflineAssetsService] Money scale migration broadcast failed for " .. player.Name .. ": " .. tostring(err))
	end
end

-- Grant accrued offline earnings the moment a profile loads (covers both a normal PlayerAdded
-- and a Controller requiring late -- see Database.OnLoaded's own doc comment).
Database.OnLoaded(function(player, profile)
	if not profile then
		return
	end

	-- before the offline accrual below, which already uses the new-scale income (a fallback since INTEGRATE3 2026-09-25:
	-- Database converts and stamps the profile before firing OnLoaded, so this returns at once)
	local okMigrate, migrateErr = pcall(migrateMoneyScale, player, profile)
	if not okMigrate then
		warn("[OfflineAssetsService] Money scale migration failed for " .. player.Name .. ": " .. tostring(migrateErr))
	end

	local lastSeenAt = profile.LastSeenAt or 0
	if lastSeenAt > 0 then
		local elapsed = math.clamp(os.time() - lastSeenAt, 0, OFFLINE_ASSETS.MAX_DURATION_SECONDS)
		if elapsed > 0 then
			local ok, rate = pcall(computeTotalRate, profile)
			rate = (ok and type(rate) == "number") and rate or 0
			local awarded = elapsed * rate * OFFLINE_ASSETS.MONEY_RATE_MULTIPLIER
			if awarded > 0 then
				profile.OfflineClaimableAmount = (profile.OfflineClaimableAmount or 0) + awarded
				Database.Set(player, { OfflineClaimableAmount = profile.OfflineClaimableAmount })
			end
		end
	end

	local ok2, err2 = pcall(function()
		SummaryUpdatedRemote:FireClient(player, buildSummary(profile))
	end)
	if not ok2 then
		warn("[OfflineAssetsService] Failed firing SummaryUpdated for " .. player.Name .. ": " .. tostring(err2))
	end
end)

-- Stamps the moment the player actually went offline, so the NEXT login's elapsed-time math is
-- accurate (deliberately not touched at login -- see the OnLoaded handler above, which reads
-- this value before anything here could overwrite it).
Players.PlayerRemoving:Connect(function(player)
	if not Database.Get(player) then
		return
	end
	Database.Set(player, { LastSeenAt = os.time() })
end)

GetSummaryRemote.OnServerInvoke = function(player)
	local profile = Database.Get(player)
	if not profile then
		return nil
	end
	return buildSummary(profile)
end

RequestRedeemRemote.OnServerInvoke = function(player, payload)
	if typeof(payload) ~= "table" or payload.Kind ~= "Claim" then
		return false, "Invalid request"
	end

	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end

	-- ECON 2026-09-24: whole dollars (the accrual is fractional; with the /125 economy a fraction shows in the HUD).
	-- REVIEW_ECON: the cents stay claimable (they used to be zeroed, and the bucket label rounded them up).
	local amount = claimableWholeDollars(profile)
	if amount < OFFLINE_ASSETS.MIN_CLAIM_MONEY then
		return false, "Nothing to claim"
	end

	local remainder = math.max((tonumber(profile.OfflineClaimableAmount) or 0) - amount, 0)
	profile.OfflineClaimableAmount = remainder
	Database.SetAndBroadcast(player, {
		OfflineClaimableAmount = remainder,
		Money = (profile.Money or 0) + amount,
	})

	local result = {
		BaseAmount = amount,
		AwardedAmount = amount,
		ClaimedByUid = {},
	}

	local ok, err = pcall(function()
		ClaimedRemote:FireClient(player, result)
	end)
	if not ok then
		warn("[OfflineAssetsService] Failed firing Claimed for " .. player.Name .. ": " .. tostring(err))
	end

	return true, nil, result
end

return OfflineAssetsService