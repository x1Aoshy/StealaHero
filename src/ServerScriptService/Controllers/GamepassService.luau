-- ServerScriptService.Controllers.GamepassService
-- Syncs real gamepass ownership (MarketplaceService:UserOwnsGamePassAsync) into the Player
-- Attributes/profile fields the rest of the game already reads:
--   * X2Money: reuses the REAL ReplicatedStorage.Library.Util.MonetizationGamepassUtil
--     (SyncPlayerAttributes sets Player Attribute "MonetizationX2MoneyGamepassOwned"), and also
--     mirrors it into profile.Gamepasses[X2Money._id] because AssetService.earningRateFor
--     already calls AssetGenerationUtil.GetRate(item, profile.Gamepasses, profile.Products) --
--     that's the real game's own x2-money-on-rebirth-bonus formula, it just needed real
--     ownership data flowing into it.
--   * X2Growth ("Eggs grow x2 faster"): MonetizationGamepassUtil has OwnsX2Growth(table) but
--     NO player-attribute getter/setter counterpart at all (dead/unfinished in this rip) -- so
--     this uses its own Player Attribute "MonetizationX2GrowthGamepassOwned", read directly by
--     EggService wherever it calls EggItemUtil.GetGrowthSpeedMultiplier.
--
-- Re-synced on join and whenever PromptGamePassPurchaseFinished reports a successful purchase
-- of either pass (matches the established pattern from Amonetization's Fly/Lap/BanHammer
-- gamepass-touch scripts and TreadmillUpgradeButton).

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local Gamepasses = require(ReplicatedStorage.Directory.Gamepasses)
local MonetizationGamepassUtil = require(ReplicatedStorage.Library.Util.MonetizationGamepassUtil)

local X2Money = Gamepasses.Directory.X2Money
local X2Growth = Gamepasses.Directory.X2Growth
local Lucky = Gamepasses.Directory.Lucky

local GamepassService = {}

local function ownsGamepass(userId, productId)
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, productId)
	end)
	if not ok then
		warn("[GamepassService] UserOwnsGamePassAsync failed for user " .. tostring(userId) .. ", pass " .. tostring(productId) .. " (treating as not owned): " .. tostring(owns))
		return false
	end
	return owns == true
end

local function syncPlayer(player)
	local ownsMoney = ownsGamepass(player.UserId, X2Money.ProductId)
	local ownsGrowth = ownsGamepass(player.UserId, X2Growth.ProductId)
	-- BUG FIX (audit: "haz una auditoria... clientes que no tienen servidor"). Lucky
	-- (1854056525, confirmed real via ReplicatedStorage.Directory.Gamepasses._Index.Lucky) was
	-- a real, purchasable gamepass with ZERO ownership tracking -- SyncPlayerAttributes was
	-- always called with a nil/false Lucky entry, confirmed by reading its own body: it checks
	-- the SAME map passed as the 2nd argument for BOTH X2Money._id and Lucky._id, so this only
	-- ever needed the map to also include Lucky's id, not a separate parameter.
	local ownsLucky = ownsGamepass(player.UserId, Lucky.ProductId)

	local ownedMap = {}
	if ownsMoney then
		ownedMap[X2Money._id] = true
	end
	if ownsLucky then
		ownedMap[Lucky._id] = true
	end

	local ok, syncErr = pcall(
		MonetizationGamepassUtil.SyncPlayerAttributes,
		player,
		next(ownedMap) and ownedMap or nil,
		nil,
		nil
	)
	if not ok then
		warn("[GamepassService] MonetizationGamepassUtil.SyncPlayerAttributes failed for " .. player.Name .. " (falling back to manual attributes): " .. tostring(syncErr))
		player:SetAttribute("MonetizationX2MoneyGamepassOwned", ownsMoney)
		player:SetAttribute("MonetizationLuckyGamepassOwned", ownsLucky)
	end

	-- No real accessor exists for X2Growth in this rip -- own attribute, same naming convention.
	player:SetAttribute("MonetizationX2GrowthGamepassOwned", ownsGrowth)

	local profile = Database.WaitForProfile(player, 30)
	if profile then
		profile.Gamepasses = profile.Gamepasses or {}
		profile.Gamepasses[X2Money._id] = ownsMoney or nil
		profile.Gamepasses[Lucky._id] = ownsLucky or nil
		Database.Set(player, { Gamepasses = profile.Gamepasses })
	end
end

GamepassService.Sync = syncPlayer

Players.PlayerAdded:Connect(function(player)
	task.spawn(syncPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(syncPlayer, player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if wasPurchased and (gamepassId == X2Money.ProductId or gamepassId == X2Growth.ProductId or gamepassId == Lucky.ProductId) then
		task.spawn(syncPlayer, player)
	end
end)

return GamepassService
