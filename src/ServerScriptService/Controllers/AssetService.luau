-- ServerScriptService.Controllers.AssetService
-- Owns profile.Inventory (hatched pets, AssetItemData shape from EggItemUtil.BuildAssetItemData)
-- and profile.EquippedAssets (uids currently "out" following the player). Contract confirmed
-- by reading ReplicatedStorage.Library.Client.AssetCmds in full:
--   ActiveAssets: RequestEquip(uid) -> (ok, extra?, err?)
--   ActiveAssets: RequestUnequip(uid) -> (ok, err?)
--   ActiveAssets: RequestEquipLimit() -> number
--   ActiveAssets: RequestRuntimeSnapshot() -> array<{OwnerUserId, Records}>
-- and ReplicatedStorage.Library.Types.AssetRuntime (STRICT schema -- no extra fields allowed):
--   RuntimeAssetRecord = {OwnerUserId, UID, ItemData, MoneyPerSecond, Seed, IsFirstPlacement?}
-- The client already renders/animates equipped pets purely from this broadcast data (confirmed
-- in AssetCmds -- it just materializes records into a snapshot signal, no server-side pet AI
-- needed). MoneyPerSecond per pet comes from ReplicatedStorage.Directory.Assets[Category].EarningRate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local Assets = require(ReplicatedStorage.Directory.Assets)
local GetPriceValueForItem = require(ReplicatedStorage.Library.Util.GetPriceValueForItem)
local PlayerMoneyPerSecondUtil = require(ReplicatedStorage.Library.Util.PlayerMoneyPerSecondUtil)
local AssetGenerationUtil = require(ReplicatedStorage.Library.Util.AssetGenerationUtil)
local AssetItemSerialization = require(ReplicatedStorage.Library.Util.AssetItemSerialization)
local EggItemUtil = require(ReplicatedStorage.Library.Util.EggItemUtil) -- egg sale prices (sell path)

local Network = ReplicatedStorage:WaitForChild("Network")
local RequestEquipRemote = Network:WaitForChild("ActiveAssets: RequestEquip")
local RequestUnequipRemote = Network:WaitForChild("ActiveAssets: RequestUnequip")
local RequestEquipLimitRemote = Network:WaitForChild("ActiveAssets: RequestEquipLimit")
local RequestSellRemote = Network:WaitForChild("ActiveAssets: RequestSell")
local RequestRuntimeSnapshotRemote = Network:WaitForChild("ActiveAssets: RequestRuntimeSnapshot")
local RuntimeOwnerUpdatedRemote = Network:WaitForChild("ActiveAssets: RuntimeOwnerUpdated")
local RuntimeOwnerClearedRemote = Network:WaitForChild("ActiveAssets: RuntimeOwnerCleared")
local MoneyCollectedRemote = Network:WaitForChild("ActiveAssets: MoneyCollected")

local SellAssetRemote = Network:WaitForChild("AssetInventory: SellAsset")
local SellAllAssetsRemote = Network:WaitForChild("AssetInventory: SellAllAssets")
local SetFavoriteRemote = Network:WaitForChild("AssetInventory: SetFavorite")

-- FEATURE (user request: "arregla mas bugs" -- found via the same "client fully built, server
-- stubbed FAIL" pattern as everything else in this project). Contract confirmed by reading
-- StarterPlayer...GUI.PetList.requestEquipBest (Backpack.EQUIP_BEST -> (ok, err?), no args) and
-- BackpackController.Main.requestEquipBestStatusRefresh (Backpack.GET_EQUIP_BEST_STATUS ->
-- {wouldChange: boolean} -- only element [1] is ever read). Non-monetary, self-contained --
-- unlike ActiveAssets: RequestStealTarget (real money, needs a whole ServerScriptService.
-- Controllers.AssetDnaStealService + FFlags.Purchases gate, deliberately NOT attempted here)
-- and OfflineAssets (also real but bigger, has its own Robux multiplier upsell path) -- both
-- left stubbed, documented for the user instead of guessed at blind.
local EquipBestRemote = Network:WaitForChild("Backpack: EquipBest")
local GetEquipBestStatusRemote = Network:WaitForChild("Backpack: GetEquipBestStatus")

-- FEATURE 2 (same request: "arregla mas bugs seguros"). profile.AutoSellRarities ALREADY existed
-- in the schema (DefaultStats/Database/SchemaFields.lua: t.map(t.string, t.boolean)) and the
-- entire client tab was already built (BackpackController.Main: buildAutoSellSlots/
-- serializeAutoSellState/initializeAutoSellUI) -- only the server side was missing (StubService
-- FAIL_ONLY). Contract confirmed by reading Main directly: SetAutoSellState's payload is the
-- FULL desired {[rarityId]: true} map (not a delta), reply is {ok: boolean, mapOrErrorString};
-- GetAutoSellState reply is {map}. Rarity ids come from Assets.Directory[category].Rarity._id,
-- same field buildAutoSellSlots reads client-side to build the rarity toggle list.
local GetAutoSellStateRemote = Network:WaitForChild("Backpack: GetAutoSellState")
local SetAutoSellStateRemote = Network:WaitForChild("Backpack: SetAutoSellState")

-- Same tiers as PlotService.BASE_TIERS (copied literally from ReplicatedStorage.Directory.Bases,
-- which still can't be require()'d -- see PlotService for why).
local BASE_MAX_ASSETS = {
	[0] = 7, [1] = 7, [2] = 9, [3] = 10, [4] = 11, [5] = 12,
	[6] = 13, [7] = 14, [8] = 15, [9] = 16, [10] = 17, [11] = 18,
}

local AssetService = {}
local lastEquipBestAt = {}
local broadcastSpeedFactor = {} -- [player] = SpeedPower factor baked into the last runtime broadcast
local lastOwnerBroadcastAt = {} -- [player] = os.clock() of the last runtime broadcast
local incomeErrorWarned = {} -- [player] = true once an income-tick failure was logged

local function equipCapacity(profile)
	return BASE_MAX_ASSETS[profile.BaseUpgradeLevel or 0] or BASE_MAX_ASSETS[0]
end

-- Treadmill training pays off in hero income: 10 SpeedPower (the starting value) = x1,
-- 100 = x2, 1000 = x3 (log10 curve). Nil/NaN/inf-safe. The client-side mirror lives in
-- ReplicatedStorage.Library.Util.PlayerMoneyPerSecondUtil (keep both formulas identical).
local function speedPowerFactor(profile)
	local speedPower = tonumber(profile and profile.SpeedPower) or 10
	if speedPower ~= speedPower or speedPower == math.huge or speedPower == -math.huge then
		speedPower = 10
	end
	return 1 + math.log10(math.max(speedPower, 10) / 10)
end
AssetService.SpeedPowerFactor = speedPowerFactor

-- Per-pet $/sec, using the game's own rate formula (factors in scale, rebirth, gamepasses,
-- products -- confirmed by reading ReplicatedStorage.Library.Util.PlayerMoneyPerSecondUtil,
-- which calls this same AssetGenerationUtil.GetRate per equipped item), times the SpeedPower
-- factor above.
-- exactRateFor is the unrounded rate (ranking); earningRateFor the paid whole-dollar rate.
local function exactRateFor(profile, itemData)
	local ok, deserialized = pcall(AssetItemSerialization.Deserialize, itemData)
	if not ok then
		warn("[AssetService] AssetItemSerialization.Deserialize failed for " .. tostring(itemData and itemData.Category) .. " (rate=0): " .. tostring(deserialized))
		return 0
	end
	local ok2, rate = pcall(
		AssetGenerationUtil.GetRate,
		deserialized,
		profile.Rebirth or 0,
		profile.Gamepasses or {},
		profile.Products or {}
	)
	if not ok2 then
		warn("[AssetService] AssetGenerationUtil.GetRate failed for " .. tostring(itemData and itemData.Category) .. " (rate=0): " .. tostring(rate))
		return 0
	end
	if type(rate) ~= "number" or rate ~= rate then
		warn("[AssetService] AssetGenerationUtil.GetRate returned non-number for " .. tostring(itemData and itemData.Category) .. ": " .. tostring(rate))
		return 0
	end
	if rate <= 0 then
		return 0
	end
	return rate * speedPowerFactor(profile)
end

local function earningRateFor(profile, itemData)
	local exact = exactRateFor(profile, itemData)
	if exact <= 0 then
		return 0
	end
	-- GetRate keeps cents below $100 since the /125 rescale (ECON 2026-09-24); a hero pays whole dollars (>= 1) so
	-- Money stays integral after the SpeedPower factor.
	return math.max(math.round(exact), 1)
end

-- Exported for OfflineAssetsService, which needs this exact same per-pet formula (SpeedPower
-- factor included) to value how much a player's currently-equipped pets earned while away.
AssetService.EarningRateFor = earningRateFor

-- Ranks every owned pet by the game's own $/sec formula (same one the pen tick and the client
-- preview both already use) and picks the top `equipCapacity(profile)` of them by uid.
-- [INTEGRATE3 2026-09-25] Ranked by the UNROUNDED rate: after the /125 money rescale most early heroes are paid the
-- same whole $1, and a sort on the paid rate was unstable (the badge stayed lit and Equip Best swapped equal heroes).
-- Ties keep the heroes already in the pen, then the uid, so the result is deterministic.
local function computeBestSelection(profile)
	local placed = {}
	for _, uid in ipairs(profile.EquippedAssets or {}) do
		placed[uid] = true
	end
	local candidates = {}
	for uid, itemData in pairs(profile.Inventory) do
		table.insert(candidates, { uid = uid, rate = exactRateFor(profile, itemData), placed = placed[uid] == true })
	end
	table.sort(candidates, function(a, b)
		if a.rate ~= b.rate then
			return a.rate > b.rate
		end
		if a.placed ~= b.placed then
			return a.placed
		end
		return tostring(a.uid) < tostring(b.uid)
	end)
	local capacity = equipCapacity(profile)
	local selected = {}
	for i = 1, math.min(capacity, #candidates) do
		table.insert(selected, candidates[i].uid)
	end
	return selected
end

-- Set-equality (order doesn't matter) -- used to answer "would pressing Equip Best actually
-- change anything right now" for the status/badge check.
local function sameAssetSelection(a, b)
	if #a ~= #b then
		return false
	end
	local bSet = {}
	for _, uid in ipairs(b) do
		bSet[uid] = true
	end
	for _, uid in ipairs(a) do
		if not bSet[uid] then
			return false
		end
	end
	return true
end

local function buildRuntimeRecords(player, profile)
	local records = {}
	local any = false
	for _, uid in ipairs(profile.EquippedAssets) do
		local itemData = profile.Inventory[uid]
		if itemData then
			local clone = table.clone(itemData)
			clone.Mutations = itemData.Mutations and table.clone(itemData.Mutations) or {}
			records[uid] = {
				OwnerUserId = player.UserId,
				UID = uid,
				ItemData = clone,
				MoneyPerSecond = earningRateFor(profile, itemData),
				Seed = itemData.ColorSeed or 0,
				IsFirstPlacement = false,
			}
			any = true
		end
	end
	return records, any
end

local function broadcastOwner(player)
	-- A deferred call can land after PlayerRemoving already fired RuntimeOwnerCleared.
	if not player.Parent then
		return
	end
	local profile = Database.Get(player)
	if not profile then
		return
	end
	broadcastSpeedFactor[player] = speedPowerFactor(profile)
	lastOwnerBroadcastAt[player] = os.clock()
	local records, any = buildRuntimeRecords(player, profile)
	if any then
		RuntimeOwnerUpdatedRemote:FireAllClients({ OwnerUserId = player.UserId, Records = records })
	else
		RuntimeOwnerClearedRemote:FireAllClients({ OwnerUserId = player.UserId })
	end
end

local function removeFromEquipped(profile, uid)
	for i, existing in ipairs(profile.EquippedAssets) do
		if existing == uid then
			table.remove(profile.EquippedAssets, i)
			return true
		end
	end
	return false
end

-- Clients ask for RequestRuntimeSnapshot once, at startup, so a player who joins (or whose
-- profile loads after that request) must be announced to everyone, or their placed heroes stay
-- invisible to the others until they next equip/sell/hatch. Clients cache records until
-- PlotCmds reports the owner's plot, so ordering relative to PlotService does not matter.
Database.OnLoaded(function(player)
	task.defer(broadcastOwner, player)
end)

Players.PlayerRemoving:Connect(function(player)
	RuntimeOwnerClearedRemote:FireAllClients({ OwnerUserId = player.UserId })
	lastEquipBestAt[player] = nil
	broadcastSpeedFactor[player] = nil
	lastOwnerBroadcastAt[player] = nil
	incomeErrorWarned[player] = nil
end)

-- BUG FIX (user report 2026-09-03: "when placing down like a pet, it bugs and still has it
-- on ur hands, for other players"): AssetToolEquipController on the client destroys the Tool
-- locally after a successful equip, but that Destroy() only removes the Tool from the local
-- viewer -- if the Tool was created by any code path that puts it into the player's
-- Character/Backpack server-side (BackpackController's replicated slot builders,
-- server-side inventory sync, etc), the Tool stays parented server-side and every OTHER
-- client keeps seeing it welded to the character. This runs server-side inside the same
-- equip handler that added the pet to EquippedAssets, and destroys any Tool whose UID
-- attribute matches the just-equipped pet, wherever it currently lives (Character while
-- equipped, or Backpack if it was un-equipped between requests). Because the destroy
-- happens on the server, it replicates to every client.
local function destroyPetToolsWithUid(player, uid)
	if type(uid) ~= "string" then return end
	-- Explicit list: ipairs({ nil, character }) would stop at a missing Backpack.
	local containers = {}
	local backpack = player:FindFirstChild("Backpack")
	if backpack then table.insert(containers, backpack) end
	if player.Character then table.insert(containers, player.Character) end
	for _, container in ipairs(containers) do
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and child:GetAttribute("ItemType") == "Asset" and child:GetAttribute("UID") == uid then
				child:Destroy()
			end
		end
	end
end

-- Hands heroes that just left the pen back to the Backpack as Tools (placed heroes have none:
-- EggService.populateAssetBackpack skips EquippedAssets). GrantAssetTool reuses an existing
-- Tool with the same UID, so this never duplicates one. EggService is required lazily (not at
-- module top) because EggService requires AssetService itself -- a top-level require here
-- would be a circular require and error.
local function returnHeroTools(player, profile, uids)
	if #uids == 0 then
		return
	end
	local ok, EggService = pcall(require, game.ServerScriptService.Controllers.EggService)
	if not ok then
		warn("[AssetService] Failed to load EggService to return pets: " .. tostring(EggService))
		return
	end
	for _, uid in ipairs(uids) do
		local itemData = profile.Inventory[uid]
		if itemData then
			if EggService.GrantAssetToolWithRetry then
				task.spawn(EggService.GrantAssetToolWithRetry, player, uid, itemData)
			elseif EggService.GrantAssetTool then
				if not EggService.GrantAssetTool(player, uid, itemData) then
					warn("[AssetService] Failed to return pet to Backpack: " .. tostring(uid))
				end
			end
		end
	end
end

-- The one equip path (pen capacity, EquippedAssets, runtime broadcast, ghost-tool cleanup),
-- shared by the "ActiveAssets: RequestEquip" handler and EggService's hatch auto-placement.
local function equipFromInventory(player, uid)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end
	if type(uid) ~= "string" then
		return false, "Invalid pet"
	end
	local itemData = profile.Inventory[uid]
	if not itemData then
		return false, "Pet not found"
	end
	for _, existing in ipairs(profile.EquippedAssets) do
		if existing == uid then
			-- Already equipped -- still make sure no lingering Tool is hanging on the character.
			destroyPetToolsWithUid(player, uid)
			return true, nil
		end
	end
	if #profile.EquippedAssets >= equipCapacity(profile) then
		return false, "Pet pen is full"
	end
	table.insert(profile.EquippedAssets, uid)
	Database.Set(player, { EquippedAssets = profile.EquippedAssets })
	broadcastOwner(player)
	destroyPetToolsWithUid(player, uid)
	return true, nil
end

-- Places an owned (Inventory) hero onto the owner's plot PetArea if the pen has room.
-- Returns true when the hero is (now) equipped, false otherwise (caller keeps it as a Tool).
function AssetService.EquipFromInventory(player, uid)
	local ok, equipped = pcall(equipFromInventory, player, uid)
	if not ok then
		warn("[AssetService] EquipFromInventory failed for " .. tostring(uid) .. ": " .. tostring(equipped))
		return false
	end
	return equipped == true
end

-- Remaining free pen slots for the player's current base level (0 when not loaded).
function AssetService.GetFreeEquipSlots(player)
	local profile = Database.Get(player)
	if not profile then
		return 0
	end
	return math.max(equipCapacity(profile) - #profile.EquippedAssets, 0)
end

RequestEquipRemote.OnServerInvoke = function(player, uid)
	local ok, err = equipFromInventory(player, uid)
	if not ok then
		return false, nil, err
	end
	return true, nil, nil
end

RequestUnequipRemote.OnServerInvoke = function(player, uid)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end
	if type(uid) ~= "string" then
		return false, "Invalid pet"
	end
	if removeFromEquipped(profile, uid) then
		Database.Set(player, { EquippedAssets = profile.EquippedAssets })
		broadcastOwner(player)

		if profile.Inventory[uid] == nil then
			warn("[AssetService] Unequipped pet was missing from Inventory: " .. tostring(uid))
		end

		-- BUG FIX (user report: "el unequip al darle a una pet no te devuelve la pet, esta mal"):
		-- this only ever removed the pet from EquippedAssets (the pet correctly leaves the plot)
		-- but never gave the player back a physical Tool for it -- that only happens today via
		-- populateAssetBackpack, wired to CharacterAdded, so the pet just vanished until your
		-- next respawn. Same bug class already fixed once for AmonetizationPurchaseService's
		-- podium purchases (see EggService.GrantAssetTool's own comment) -- this call site was
		-- just missed.
		returnHeroTools(player, profile, { uid })
	end
	return true, nil
end

RequestEquipLimitRemote.OnServerInvoke = function(player)
	local profile = Database.Get(player)
	if not profile then
		return 0
	end
	return equipCapacity(profile)
end

EquipBestRemote.OnServerInvoke = function(player)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end
	local now = os.clock()
	if lastEquipBestAt[player] and now - lastEquipBestAt[player] < 5.0 then
		return false, "Please wait a bit before equipping bests again!"
	end
	lastEquipBestAt[player] = now
	local previous = profile.EquippedAssets
	local selection = computeBestSelection(profile)
	profile.EquippedAssets = selection
	Database.Set(player, { EquippedAssets = profile.EquippedAssets })
	broadcastOwner(player)

	-- Keep Tools in step with the pen: newly placed heroes lose their Tool (no ghost/duplicate
	-- in the hand), displaced ones get theirs back (otherwise they would be unusable until the
	-- next respawn).
	local wasPlaced, isPlaced = {}, {}
	for _, uid in ipairs(previous) do
		wasPlaced[uid] = true
	end
	local displaced = {}
	for _, uid in ipairs(selection) do
		isPlaced[uid] = true
		if not wasPlaced[uid] then
			destroyPetToolsWithUid(player, uid)
		end
	end
	for _, uid in ipairs(previous) do
		if not isPlaced[uid] then
			table.insert(displaced, uid)
		end
	end
	returnHeroTools(player, profile, displaced)
	return true
end

GetEquipBestStatusRemote.OnServerInvoke = function(player)
	local profile = Database.Get(player)
	if not profile then
		return { false }
	end
	local best = computeBestSelection(profile)
	if sameAssetSelection(best, profile.EquippedAssets) then
		return { false }
	end
	-- lit only when Equip Best would raise the paid $/s (not for a swap between heroes paid the same whole dollars)
	local function paidTotal(uids)
		local total = 0
		for _, uid in ipairs(uids) do
			local itemData = profile.Inventory[uid]
			if itemData then
				total += earningRateFor(profile, itemData)
			end
		end
		return total
	end
	return { paidTotal(best) > paidTotal(profile.EquippedAssets) }
end

RequestRuntimeSnapshotRemote.OnServerInvoke = function(_player)
	local snapshot = {}
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		local profile = Database.Get(otherPlayer)
		if profile then
			local records, any = buildRuntimeRecords(otherPlayer, profile)
			if any then
				table.insert(snapshot, { OwnerUserId = otherPlayer.UserId, Records = records })
			end
		end
	end
	return snapshot
end

-- ============================== SELLING (owner 2026-09-23: "Implement Selling") ==============================
-- One validated sell path behind every entry point:
--   "ActiveAssets: RequestSell" (RemoteFunction), used by GUI.SellHeroes and the sell stall (Game.Npcs.AssetSellerNpc):
--       RequestSell({ Heroes = { uid, ... } } | { Eggs = { uid, ... } }) -> (true, SellResult) | (false, message)
--       RequestSell(uid: string) -> (ok, message?)          legacy single-uid form (a hero or an egg uid)
--     SellResult = { Sold = { uid }, SoldHeroes, SoldEggs, Earned, Money (new balance), Skipped, Reasons = { [reason] =
--     count }, Note = player-facing text about the skipped ones or nil }
--   "AssetInventory: SellAsset" (RemoteEvent, uid)             legacy held-item sale, same rules
--   "AssetInventory: SellAllAssets" (RemoteEvent, { uid }?)    the given heroes, else every sellable hero
--   AssetService.MaybeAutoSell                                  hatch auto-sell by rarity (sellOne below)
-- Sellable hero: in Inventory, not placed in the pen (EquippedAssets), not favourited (FavoriteAssets[uid] or
-- ItemData.IsFavorite) and not in the fuse machine (FusionSlots / InFuse). Sellable egg: in EggInventory and not
-- placed (Placement == nil; growing eggs stay in the base).
-- Prices: hero = floor(GetPriceValueForItem(item) * HERO_SELL_MULTIPLIER); egg = floor(EggItemUtil.GetSellPrice(egg)
-- * EGG_SELL_MULTIPLIER), where GetSellPrice is the base game's egg price (80% of the hero's un-mutated value, about
-- 60% of what the hatched hero sells for). Both multipliers are published as attributes of the RequestSell remote, so
-- every client lists exactly what the server pays.
-- No dupes: each request is validated, priced and applied without yielding (atomic), uids are de-duplicated, a uid is
-- removed from the profile in the same step that pays for it (a repeated or retried uid finds nothing and pays nothing:
-- idempotent), and requests are rate-limited per player.
local HERO_SELL_MULTIPLIER = 1.33 -- 🟡 MODDED REBALANCE (user: "okey x1.33"; was 0.8x)
local EGG_SELL_MULTIPLIER = 1
local SELL_COOLDOWN = 0.35 -- seconds between two sell requests of one player
local MAX_SELL_BATCH = 300 -- uids per RequestSell call (GUI.SellHeroes sends bigger selections in chunks)
local MAX_UID_LENGTH = 100

local lastSellAt = {} -- [player] = os.clock() of the last accepted sell request

pcall(function()
	RequestSellRemote:SetAttribute("HeroSellMultiplier", HERO_SELL_MULTIPLIER)
	RequestSellRemote:SetAttribute("EggSellMultiplier", EGG_SELL_MULTIPLIER)
	RequestSellRemote:SetAttribute("MaxSellBatch", MAX_SELL_BATCH)
end)

Players.PlayerRemoving:Connect(function(player)
	lastSellAt[player] = nil
end)

local function finitePrice(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- What a hero pays when sold (0 when it cannot be priced).
local function heroSellPrice(itemData)
	local ok, price = pcall(GetPriceValueForItem, itemData)
	if not ok or not finitePrice(price) then
		warn("[AssetService] GetPriceValueForItem failed for " .. tostring(type(itemData) == "table" and itemData.Category) .. ": " .. tostring(price))
		return 0
	end
	return math.max(math.floor(price * HERO_SELL_MULTIPLIER), 0)
end
AssetService.HeroSellPrice = heroSellPrice

-- What an unhatched egg pays when sold (0 when it cannot be priced). DeserializeSavedEgg first, exactly like the
-- clients do with their Save copy, so both sides price the same record.
local function eggSellPrice(egg)
	if type(egg) ~= "table" then
		return 0
	end
	local ok, price = pcall(function()
		return EggItemUtil.GetSellPrice(EggItemUtil.DeserializeSavedEgg(egg))
	end)
	if not ok or not finitePrice(price) then
		warn("[AssetService] EggItemUtil.GetSellPrice failed for " .. tostring(egg.AssetCategory) .. ": " .. tostring(price))
		return 0
	end
	return math.max(math.floor(price * EGG_SELL_MULTIPLIER), 0)
end
AssetService.EggSellPrice = eggSellPrice

local function listHas(list, uid)
	return type(list) == "table" and table.find(list, uid) ~= nil
end

-- nil when the hero can be sold, else the reason it is kept.
local function heroSellBlock(profile, uid)
	local itemData = profile.Inventory[uid]
	if type(itemData) ~= "table" then
		return "gone"
	end
	if listHas(profile.EquippedAssets, uid) then
		return "placed"
	end
	if (type(profile.FavoriteAssets) == "table" and profile.FavoriteAssets[uid]) or itemData.IsFavorite == true then
		return "favorite"
	end
	if listHas(profile.FusionSlots, uid) or itemData.InFuse then
		return "fusing"
	end
	return nil
end

-- nil when the egg can be sold, else the reason it is kept.
local function eggSellBlock(profile, uid)
	local egg = type(profile.EggInventory) == "table" and profile.EggInventory[uid]
	if type(egg) ~= "table" then
		return "gone"
	end
	if egg.Placement ~= nil then
		return "growing"
	end
	return nil
end

local SKIP_NOTES = {
	placed = "Heroes in your base can't be sold - pick them up first.",
	favorite = "Favorited heroes can't be sold.",
	fusing = "Heroes in the Fuse Machine can't be sold.",
	growing = "Eggs growing in your base can't be sold.",
	unpriced = "Some items could not be priced.",
	gone = "Already sold.",
}
local SKIP_ORDER = { "placed", "favorite", "fusing", "growing", "unpriced", "gone" }

-- The sold egg's Tool (EggService.grantEggTool, ItemType "AssetEgg") must not stay in the hand / Backpack.
local function destroyEggToolsWithUid(player, uid)
	local containers = {}
	local backpack = player:FindFirstChild("Backpack")
	if backpack then table.insert(containers, backpack) end
	if player.Character then table.insert(containers, player.Character) end
	for _, container in ipairs(containers) do
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and child:GetAttribute("ItemType") == "AssetEgg" and child:GetAttribute("UID") == uid then
				child:Destroy()
			end
		end
	end
end

-- Keeps the string uids of a client list: de-duplicated (across heroes and eggs), at most `limit` of them.
local function collectUids(list, seen, out, limit)
	if type(list) ~= "table" then
		return true
	end
	for _, uid in ipairs(list) do
		if type(uid) == "string" and #uid > 0 and #uid <= MAX_UID_LENGTH and not seen[uid] then
			if #out >= limit then
				return false
			end
			seen[uid] = true
			table.insert(out, uid)
		end
	end
	return true
end

-- Validates, prices and applies one sale. Never yields between the checks and the Money commit.
local function applySale(player, profile, heroUids, eggUids)
	local result = { Sold = {}, SoldHeroes = 0, SoldEggs = 0, Earned = 0, Skipped = 0, Reasons = {}, Note = nil }
	local function skip(reason)
		result.Skipped += 1
		result.Reasons[reason] = (result.Reasons[reason] or 0) + 1
	end

	-- 1. validate + price everything first (no mutation yet)
	local heroes, eggs, total = {}, {}, 0
	for _, uid in ipairs(heroUids) do
		local reason = heroSellBlock(profile, uid)
		local price = if reason == nil then heroSellPrice(profile.Inventory[uid]) else 0
		if reason == nil and price <= 0 then
			reason = "unpriced"
		end
		if reason then
			skip(reason)
		else
			table.insert(heroes, uid)
			total += price
		end
	end
	for _, uid in ipairs(eggUids) do
		local reason = eggSellBlock(profile, uid)
		local price = if reason == nil then eggSellPrice(profile.EggInventory[uid]) else 0
		if reason == nil and price <= 0 then
			reason = "unpriced"
		end
		if reason then
			skip(reason)
		else
			table.insert(eggs, uid)
			total += price
		end
	end

	-- 2. apply: remove every sold item and pay in the same step
	for _, uid in ipairs(heroes) do
		profile.Inventory[uid] = nil
		table.insert(result.Sold, uid)
	end
	for _, uid in ipairs(eggs) do
		profile.EggInventory[uid] = nil
		table.insert(result.Sold, uid)
	end
	result.SoldHeroes, result.SoldEggs, result.Earned = #heroes, #eggs, total
	if #heroes + #eggs > 0 then
		profile.Money = (tonumber(profile.Money) or 0) + total
		local changes = { Money = profile.Money }
		if #heroes > 0 then
			changes.Inventory = profile.Inventory
		end
		if #eggs > 0 then
			changes.EggInventory = profile.EggInventory
		end
		Database.SetAndBroadcast(player, changes)
	end
	result.Money = profile.Money

	-- 3. after the commit: sold items leave no Tool behind (replicates to every client)
	for _, uid in ipairs(heroes) do
		pcall(destroyPetToolsWithUid, player, uid)
	end
	for _, uid in ipairs(eggs) do
		pcall(destroyEggToolsWithUid, player, uid)
	end

	for _, reason in ipairs(SKIP_ORDER) do
		if result.Reasons[reason] then
			result.Note = SKIP_NOTES[reason]
			break
		end
	end
	return result
end

-- Shared entry: profile + rate limit + input checks, then applySale. Returns (true, result) or (false, message).
local function sellItems(player, heroList, eggList, limit)
	local profile = Database.Get(player)
	if not profile or not Database.IsPlayerLoaded(player) then
		return false, "Your data is still loading - try again in a moment."
	end
	if type(profile.Inventory) ~= "table" or type(profile.EggInventory) ~= "table" then
		return false, "Your inventory is not ready yet."
	end
	local now = os.clock()
	if lastSellAt[player] and now - lastSellAt[player] < SELL_COOLDOWN then
		return false, "Slow down - try again in a moment."
	end
	local seen, heroes, eggs = {}, {}, {}
	limit = limit or MAX_SELL_BATCH
	if not collectUids(heroList, seen, heroes, limit) or not collectUids(eggList, seen, eggs, limit - #heroes) then
		return false, "Too many items at once."
	end
	if #heroes + #eggs == 0 then
		return false, "Nothing to sell."
	end
	lastSellAt[player] = now
	return true, applySale(player, profile, heroes, eggs)
end

-- Legacy single-uid sale (RequestSell(uid) / SellAsset(uid)): the uid may name a hero or an egg.
local function sellSingleUid(player, uid)
	local profile = Database.Get(player)
	if not profile or type(uid) ~= "string" then
		return false, "Invalid request"
	end
	local isEgg = type(profile.Inventory) == "table" and profile.Inventory[uid] == nil
		and type(profile.EggInventory) == "table" and profile.EggInventory[uid] ~= nil
	local ok, result = sellItems(player, if isEgg then {} else { uid }, if isEgg then { uid } else {})
	if not ok then
		return false, result
	end
	if result.SoldHeroes + result.SoldEggs == 0 then
		return false, result.Note or "This item can't be sold."
	end
	return true, nil
end

-- Hatch auto-sell (MaybeAutoSell): a freshly hatched hero, never placed / favourited / fused yet. Does NOT touch
-- profile.Money -- the caller adds the returned price.
local function sellOne(player, profile, uid)
	local itemData = profile.Inventory[uid]
	if not itemData then
		return 0
	end
	local sellPrice = heroSellPrice(itemData)
	profile.Inventory[uid] = nil
	removeFromEquipped(profile, uid)
	-- a sold hero must not leave its Tool behind in the Backpack / hand until respawn
	destroyPetToolsWithUid(player, uid)
	return sellPrice
end

local function rarityIdForItem(itemData)
	local config = itemData and Assets.Directory[itemData.Category]
	local rarity = config and config.Rarity
	return rarity and rarity._id
end

-- Called by EggService right after granting a hatched pet, so a rarity the player has toggled
-- on in the AutoSell tab gets sold the instant it's granted instead of sitting in Inventory.
-- Mirrors sellOne's contract -- does NOT touch profile.Money, the caller adds the returned price.
function AssetService.MaybeAutoSell(player, profile, uid)
	local itemData = profile.Inventory[uid]
	if not itemData then
		return false, 0
	end
	local rarities = profile.AutoSellRarities
	if type(rarities) ~= "table" then
		return false, 0
	end
	local rarityId = rarityIdForItem(itemData)
	if not rarityId or not rarities[rarityId] then
		return false, 0
	end
	local sellPrice = sellOne(player, profile, uid)
	return true, sellPrice
end

GetAutoSellStateRemote.OnServerInvoke = function(player)
	local profile = Database.Get(player)
	if not profile then
		return { {} }
	end
	return { profile.AutoSellRarities or {} }
end

SetAutoSellStateRemote.OnServerInvoke = function(player, desiredMap)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end
	if type(desiredMap) ~= "table" then
		return false, "Invalid request"
	end

	-- Validate against real rarity ids (same source of truth the client UI itself is built
	-- from) instead of trusting the client payload's keys blindly.
	local validRarities = {}
	for _, config in pairs(Assets.Directory) do
		local rarity = config.Rarity
		if rarity and type(rarity._id) == "string" then
			validRarities[rarity._id] = true
		end
	end

	local cleaned = {}
	for k, v in pairs(desiredMap) do
		if v == true and type(k) == "string" and validRarities[k] then
			cleaned[k] = true
		end
	end

	profile.AutoSellRarities = cleaned
	Database.Set(player, { AutoSellRarities = cleaned })
	return true, cleaned
end

RequestSellRemote.OnServerInvoke = function(player, request)
	local okCall, ok, result = pcall(function()
		if type(request) == "string" then
			return sellSingleUid(player, request)
		end
		if type(request) ~= "table" then
			return false, "Invalid request"
		end
		return sellItems(player, request.Heroes, request.Eggs)
	end)
	if not okCall then
		warn("[AssetService] RequestSell failed for " .. player.Name .. ": " .. tostring(ok))
		return false, "Selling failed - try again."
	end
	return ok, result
end

SellAssetRemote.OnServerEvent:Connect(function(player, uid)
	local okCall, err = pcall(sellSingleUid, player, uid)
	if not okCall then
		warn("[AssetService] SellAsset failed for " .. player.Name .. ": " .. tostring(err))
	end
end)

-- Sell All: the heroes the client listed (the stall's fallback confirm sends them), else every hero; applySale keeps
-- placed / favourited / fusing heroes either way.
SellAllAssetsRemote.OnServerEvent:Connect(function(player, uids)
	local okCall, err = pcall(function()
		local list = uids
		if type(list) ~= "table" then
			local profile = Database.Get(player)
			list = {}
			for uid in pairs(profile and type(profile.Inventory) == "table" and profile.Inventory or {}) do
				table.insert(list, uid)
			end
		end
		sellItems(player, list, nil, 2000)
	end)
	if not okCall then
		warn("[AssetService] SellAllAssets failed for " .. player.Name .. ": " .. tostring(err))
	end
end)

SetFavoriteRemote.OnServerEvent:Connect(function(player, uid, favorite)
	local profile = Database.Get(player)
	if not profile or type(uid) ~= "string" then
		return
	end
	profile.FavoriteAssets = profile.FavoriteAssets or {}
	profile.FavoriteAssets[uid] = favorite and true or nil
	Database.Set(player, { FavoriteAssets = profile.FavoriteAssets })
end)

-- Money-per-second income from equipped pets, using the game's own total formula.
-- BUG FIX (user report: constant spam every ~1s in the log -- "MoneyUpdate:346: invalid
-- argument #1 to 'ipairs' (table expected, got number)" AND the identical error in
-- ActiveAssetsController:307, both on the SAME remote "ActiveAssets: MoneyCollected"). Root
-- cause: this loop fired that remote with a raw number (`total`), but BOTH client listeners do
-- `for _, v in ipairs(payload) do local uid = v.uid ... end` -- they need an ARRAY of
-- {uid, amount} records (one per equipped pet that earned that tick), not a lump sum. Switched
-- to earningRateFor (already used by EquipBest/computeBestSelection above, itself confirmed to
-- match PlayerMoneyPerSecondUtil.GetTotalForProfile's own per-item formula) to build that array
-- and sum it for the same total instead.
local function payIncome(player)
	local profile = Database.Get(player)
	if profile and #profile.EquippedAssets > 0 then
		local records = {}
		local total = 0
		for _, uid in ipairs(profile.EquippedAssets) do
			local itemData = profile.Inventory[uid]
			if itemData then
				local rate = earningRateFor(profile, itemData)
				if rate > 0 then
					total += rate
					table.insert(records, { uid = uid, amount = rate })
				end
			end
		end
		if total > 0 then
			Database.Set(player, { Money = (profile.Money or 0) + total })
			MoneyCollectedRemote:FireClient(player, records)
		end
		-- Treadmill training changes SpeedPower continuously; refresh the per-hero
		-- MoneyPerSecond the clients display once the factor has moved by >= 1%
		-- (throttled to one broadcast per 5 s per owner).
		local factor = speedPowerFactor(profile)
		local lastFactor = broadcastSpeedFactor[player]
		if lastFactor == nil then
			-- Never broadcast for this owner yet (normally the OnLoaded broadcast covers it).
			broadcastOwner(player)
		elseif math.abs(factor - lastFactor) >= 0.01 and os.clock() - (lastOwnerBroadcastAt[player] or 0) >= 5 then
			broadcastOwner(player)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			-- One malformed profile/hero record must not end this loop (income for everyone).
			local ok, err = pcall(payIncome, player)
			if not ok and not incomeErrorWarned[player] then
				incomeErrorWarned[player] = true
				warn("[AssetService] Income tick failed for " .. player.Name .. ": " .. tostring(err))
			end
		end
	end
end)

return AssetService
