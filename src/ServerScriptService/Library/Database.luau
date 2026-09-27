local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Network = ReplicatedStorage:WaitForChild("Network")
local statsRemote = Network:FindFirstChild("New Stats")
local profileStore = nil
local memoryMockStore = {}
local usingMockStore = false

-- In-memory stand-in for a DataStore (offline / Studio without API access). Nothing written
-- here ever reaches the real store.
local function createMockStore()
	return {
		GetAsync = function(self, key)
			return memoryMockStore[key]
		end,
		SetAsync = function(self, key, value)
			memoryMockStore[key] = value
		end,
		UpdateAsync = function(self, key, transform)
			local current = memoryMockStore[key]
			local new = transform(current)
			memoryMockStore[key] = new
			return new
		end,
	}
end

local function switchToMockStore(reason)
	if usingMockStore then
		return
	end
	usingMockStore = true
	profileStore = createMockStore()
	warn("[Database] " .. reason .. " Using in-memory mock store (profiles are NOT saved to the real DataStore).")
end

local ok, ds = pcall(function()
	return DataStoreService:GetDataStore("PlayerProfiles_v3")
end)

if ok and ds then
	profileStore = ds
else
	switchToMockStore("DataStore unavailable (local Studio/offline).")
end

local Database = {}
local profiles = {}
local loadedProfiles = {}
local loadingProfiles = {}
local savingProfiles = {}
local loadedCallbacks = {}
local fieldCallbacks = {}

local defaults = {
	Money = 2, -- ECON 2026-09-24: starting cash /125 with the whole money economy (was 250)
	Rebirth = 0,
	SpeedPower = 10,
	EggInventory = {},
	Inventory = {},
	EquippedAssets = {},
	FusionSlots = {},
	AutoSellRarities = {},
	BaseUpgradeLevel = 0,
	TreadmillUpgradeLevel = 1,
	Gamepasses = {},
	Products = {},
	Settings = {},
	Index = {},
	FavoriteAssets = {},
	PlacedAssets = {},
	GearInventory = {},
	VisitedGears = {},
	TrailInventory = {},
	EquippedTrail = "GreyTrail",
	-- Treadmill / speed-boost stats read by TreadmillUtil and the treadmill UI (mirrors
	-- ReplicatedStorage.Library.Modules.DefaultStats).
	SpeedBoostTierIndex = 0,
	TemporarySpeedBoostRemainingSeconds = 0,
	TemporarySpeedBoostActiveStartedAt = 0,
	LatestTreadmillMediaIndex = 0,
	TreadmillMediaFeedState = {
		Seed = 0,
		CurrentIndex = 0,
		AlgorithmVersion = 3,
		ReleaseTrackingInitialized = false,
		FullFeedReleaseVersion = 0,
		CompletedReleaseVersion = 0,
		PendingReleaseVersion = 0,
		SeenPendingMediaKeys = {},
	},
	OfflineClaimableAmount = 0,
	LastSeenAt = 0,
	FlappyBest = 0, -- Hero Flap best score (FlappyService)
	-- Hub leaderboards (LeaderboardService, scripts/steps/post_leaderboards.luau), both server-authoritative:
	TimePlayed = 0, -- seconds spent in-game, accumulated by LeaderboardService while the profile is loaded
	EggsHatched = 0, -- hatches completed (EggService RequestCompleteHatchEgg)
	-- Index completion rewards (IndexService / PlotService, Directory.BaseThemes): stage key -> true once that stage's
	-- Hero Index is complete, and the stage key of the base theme shown on the owner's plot ("" = the plain base).
	UnlockedBaseThemes = {},
	EquippedBaseTheme = "",
}

-- Numeric stats that must always be finite numbers (value = fallback when missing/invalid).
local NUMERIC_DEFAULTS = {
	Money = 0,
	Rebirth = 0,
	SpeedPower = 10,
	BaseUpgradeLevel = 0,
	TreadmillUpgradeLevel = 1,
	SpeedBoostTierIndex = 0,
	TemporarySpeedBoostRemainingSeconds = 0,
	TemporarySpeedBoostActiveStartedAt = 0,
	LatestTreadmillMediaIndex = 0,
	OfflineClaimableAmount = 0,
	LastSeenAt = 0,
	FlappyBest = 0, -- Hero Flap best score (FlappyService)
	TimePlayed = 0, -- hub leaderboard "IN-GAME TIME" (seconds, LeaderboardService)
	EggsHatched = 0, -- hub leaderboard "EGGS HATCHED" (EggService)
}

-- Stats that must always be tables.
local TABLE_FIELDS = {
	"TrailInventory", "Gamepasses", "Products", "Settings", "Inventory", "EggInventory",
	"EquippedAssets", "GearInventory", "Index", "FusionSlots", "AutoSellRarities",
	"FavoriteAssets", "PlacedAssets", "VisitedGears", "UnlockedBaseThemes",
}

local MIN_SPEED_POWER = 10 -- TreadmillUtil.DEFAULT_BASE_SPEED_POWER
local MAX_TREADMILL_UPGRADE_LEVEL = 10 -- #Directory.Treadmills.GetOrdered()
local MAX_SPEED_BOOST_TIER_INDEX = 12 -- TreadmillUtil.MAX_SPEED_BOOST_TIER_INDEX

local function cloneValue(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, nested in pairs(value) do
		result[key] = cloneValue(nested)
	end
	return result
end

local function finiteNumber(value, fallback)
	value = tonumber(value)
	if value == nil or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return value
end

-- The game's own default profile (ReplicatedStorage.Library.Modules.DefaultStats) carries ~60
-- more fields than `defaults` above; client and base-place server code read many of them.
-- Optional: required once in its own thread (so a slow or failing require can never block a
-- profile load); until it resolves, or if it fails, the extra fields are simply skipped.
local gameDefaultStats = nil
task.spawn(function()
	local module = ReplicatedStorage:FindFirstChild("Library")
	module = module and module:FindFirstChild("Modules")
	module = module and module:FindFirstChild("DefaultStats")
	if not (module and module:IsA("ModuleScript")) then
		return
	end
	local okRequire, result = pcall(require, module)
	if okRequire and type(result) == "table" then
		gameDefaultStats = result
	else
		warn("[Database] DefaultStats unavailable, skipping extra default fields: " .. tostring(result))
	end
end)

-- D1 purge migration (docs/VISUAL_PASS_PLAN.md): the build deleted every legacy animal/brainrot asset and the
-- 10 pre-plan Speedsters heroes, so their ids no longer exist in Directory.Assets (a strict table - indexing a
-- removed id errors). Old saves drop every entry that names such an id: Inventory items, EggInventory eggs, and
-- everything that points at them (EquippedAssets, FavoriteAssets, fusion slots/rewards, Index flags). The game is
-- pre-launch, so nothing is refunded. Valid ids = the Directory.Assets._Index config names (read from the instances,
-- no require) plus the lucky-block model names an inventory item may carry. Runs once per profile table (weak memo),
-- so the per-tick EnsureStatDefaults callers pay nothing after the first call.
local purgedProfiles = setmetatable({}, { __mode = "k" })
local knownAssetIds = nil

local function getKnownAssetIds()
	if knownAssetIds then
		return knownAssetIds
	end
	local directory = ReplicatedStorage:FindFirstChild("Directory")
	local assetsDir = directory and directory:FindFirstChild("Assets")
	local index = assetsDir and assetsDir:FindFirstChild("_Index")
	if not index then
		return nil
	end
	local known, count = {}, 0
	for _, child in ipairs(index:GetChildren()) do
		if child:IsA("ModuleScript") then
			known[child.Name] = true
			count += 1
		end
	end
	if count == 0 then
		-- never wipe inventories against an empty/unloaded directory
		return nil
	end
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	local luckyBlocks = models and models:FindFirstChild("LuckyBlocks")
	if luckyBlocks then
		for _, child in ipairs(luckyBlocks:GetChildren()) do
			known[child.Name] = true
		end
	end
	knownAssetIds = known
	return known
end

-- The asset id a saved record names: Inventory items use Category, eggs AssetCategory, pending fusion eggs { Egg }.
local function assetIdOf(record)
	if type(record) == "string" then
		return record
	end
	if type(record) ~= "table" then
		return nil
	end
	if type(record.Egg) == "table" then
		record = record.Egg
	end
	local id = record.Category or record.AssetCategory
	return if type(id) == "string" then id else nil
end

local function purgeRetiredAssets(profile)
	if purgedProfiles[profile] then
		return
	end
	local known = getKnownAssetIds()
	if not known then
		return -- directory not readable yet: retried on the next call
	end
	purgedProfiles[profile] = true

	local dropped = 0
	for _, field in ipairs({ "Inventory", "EggInventory" }) do
		local map = profile[field]
		if type(map) == "table" then
			for uid, record in pairs(map) do
				local id = assetIdOf(record)
				if id ~= nil and not known[id] then
					map[uid] = nil
					dropped += 1
				end
			end
		end
	end

	local inventory = if type(profile.Inventory) == "table" then profile.Inventory else {}
	-- uid lists into Inventory (EquippedAssets is also re-checked by EnsureStatDefaults right after this)
	for _, field in ipairs({ "EquippedAssets", "FusionSlots", "VIPFusionSlots", "PrivateFusionSlots" }) do
		local list = profile[field]
		if type(list) == "table" then
			for index = #list, 1, -1 do
				if type(list[index]) == "string" and inventory[list[index]] == nil then
					table.remove(list, index)
				end
			end
		end
	end
	if type(profile.FavoriteAssets) == "table" then
		for uid in pairs(profile.FavoriteAssets) do
			if inventory[uid] == nil then
				profile.FavoriteAssets[uid] = nil
			end
		end
	end
	-- category-keyed sets (the Index GUI resolves every key through the strict Assets directory)
	for _, field in ipairs({ "Index", "IndexClaimedCategories" }) do
		local set = profile[field]
		if type(set) == "table" then
			for category in pairs(set) do
				if type(category) == "string" and not known[category] then
					set[category] = nil
					dropped += 1
				end
			end
		end
	end
	-- pending fusion results naming a removed asset
	for _, field in ipairs({ "FusionReward", "VIPFusionReward", "PrivateFusionReward" }) do
		local id = assetIdOf(profile[field])
		if id ~= nil and not known[id] then
			profile[field] = nil
			dropped += 1
		end
	end
	local pendingEgg = profile.FusionEggReward
	if type(pendingEgg) == "table" then
		local id = assetIdOf(pendingEgg)
		if id ~= nil and not known[id] then
			profile.FusionEggReward = false
			dropped += 1
		end
	end

	if dropped > 0 then
		warn(string.format("[Database] D1 purge: dropped %d save entr%s naming removed legacy assets.", dropped, dropped == 1 and "y" or "ies"))
	end
end

-- Heals a profile in place so every stat the game reads has a valid value. Idempotent and cheap
-- enough to call every tick (TreadmillGrindService does). Returns the same profile table.
function Database.EnsureStatDefaults(profile)
	if type(profile) ~= "table" then
		return profile
	end

	for key, fallback in pairs(NUMERIC_DEFAULTS) do
		profile[key] = finiteNumber(profile[key], fallback)
	end
	profile.SpeedPower = math.max(profile.SpeedPower, MIN_SPEED_POWER)
	profile.BaseUpgradeLevel = math.max(0, math.floor(profile.BaseUpgradeLevel))
	profile.TreadmillUpgradeLevel = math.clamp(math.floor(profile.TreadmillUpgradeLevel), 1, MAX_TREADMILL_UPGRADE_LEVEL)
	profile.SpeedBoostTierIndex = math.clamp(math.floor(profile.SpeedBoostTierIndex), 0, MAX_SPEED_BOOST_TIER_INDEX)
	profile.TemporarySpeedBoostRemainingSeconds = math.max(0, profile.TemporarySpeedBoostRemainingSeconds)
	profile.OfflineClaimableAmount = math.max(0, profile.OfflineClaimableAmount)

	for _, key in ipairs(TABLE_FIELDS) do
		if type(profile[key]) ~= "table" then
			profile[key] = {}
		end
	end

	if profile.EquippedTrail ~= nil and type(profile.EquippedTrail) ~= "string" then
		profile.EquippedTrail = nil
	end
	if type(profile.EquippedBaseTheme) ~= "string" then
		profile.EquippedBaseTheme = ""
	end

	purgeRetiredAssets(profile)

	-- EquippedAssets is an array of Inventory uids; drop stale/duplicate entries so they do not
	-- eat pen capacity (in place, only when something is wrong).
	local equipped = profile.EquippedAssets
	local seen = {}
	for index = #equipped, 1, -1 do
		local uid = equipped[index]
		if type(uid) ~= "string" or profile.Inventory[uid] == nil or seen[uid] then
			table.remove(equipped, index)
		else
			seen[uid] = true
		end
	end

	local feedState = profile.TreadmillMediaFeedState
	if type(feedState) ~= "table" then
		feedState = {}
		profile.TreadmillMediaFeedState = feedState
	end
	for key, value in pairs(defaults.TreadmillMediaFeedState) do
		if feedState[key] == nil then
			feedState[key] = cloneValue(value)
		end
	end
	if type(feedState.SeenPendingMediaKeys) ~= "table" then
		feedState.SeenPendingMediaKeys = {}
	end

	local extra = gameDefaultStats
	if extra then
		for key, value in pairs(extra) do
			if profile[key] == nil then
				profile[key] = cloneValue(value)
			end
		end
	end

	return profile
end

local function mergeDefaults(saved, template)
	local result = {}
	if type(saved) == "table" then
		for key, value in pairs(saved) do
			if type(value) == "table" then
				result[key] = cloneValue(value)
			elseif type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
				result[key] = value
			end
		end
	end
	for key, value in pairs(template) do
		if result[key] == nil then
			result[key] = cloneValue(value)
		end
	end
	result.BaseUpgradeLevel = math.max(0, math.floor(tonumber(result.BaseUpgradeLevel) or 0))
	result.TreadmillUpgradeLevel = math.max(1, math.floor(tonumber(result.TreadmillUpgradeLevel) or 1))
	return result
end

-- [INTEGRATE3 2026-09-25] The /125 money rescale (ECON 2026-09-24, AssetGenerationUtil.MONEY_SCALE) converts a profile
-- saved before it here, before fireLoaded, so neither the client's first "New Stats" nor any OnLoaded callback ever sees
-- old-scale Money, and the conversion no longer depends on OfflineAssetsService loading (its own migrateMoneyScale
-- stays as a fallback and returns at once for a stamped profile). A never-saved profile (LastSeenAt 0) already starts on
-- the new scale and is only stamped. MoneyScaleVersion is saved with the profile (it is NOT a default: mergeDefaults
-- would stamp old saves without converting them).
local MONEY_SCALE_VERSION = 1
local MONEY_SCALE = 1 / 125

local function migrateMoneyScale(profile)
	if type(profile) ~= "table" or (tonumber(profile.MoneyScaleVersion) or 0) >= MONEY_SCALE_VERSION then
		return
	end
	if (tonumber(profile.LastSeenAt) or 0) > 0 then
		local money = tonumber(profile.Money) or 0
		if money == money and money > 0 and money ~= math.huge then
			profile.Money = math.floor(money * MONEY_SCALE)
		end
		local claimable = tonumber(profile.OfflineClaimableAmount) or 0
		if claimable == claimable and claimable > 0 and claimable ~= math.huge then
			profile.OfflineClaimableAmount = math.floor(claimable * MONEY_SCALE)
		end
	end
	profile.MoneyScaleVersion = MONEY_SCALE_VERSION
end

local function fireLoaded(player, profile)
	if loadedProfiles[player] then
		return
	end
	loadedProfiles[player] = true
	if statsRemote then
		statsRemote:FireClient(player, profile)
	end
	for _, callback in ipairs(loadedCallbacks) do
		task.spawn(callback, player, profile)
	end
end

-- Studio without "Enable Studio Access to API Services" (or an unpublished place) fails every
-- request with one of these errors; retrying is pointless there.
local function isStudioAccessError(err)
	local message = string.lower(tostring(err))
	return string.find(message, "studioaccesstoapisnotallowed", 1, true) ~= nil
		or string.find(message, "studio access", 1, true) ~= nil
		or string.find(message, "publish", 1, true) ~= nil
end

local function loadProfile(player)
	if loadingProfiles[player] or loadedProfiles[player] or not player.Parent then
		return
	end
	loadingProfiles[player] = true
	local key = "Player_" .. tostring(player.UserId)
	local success, saved = false, nil
	for attempt = 1, 3 do
		success, saved = pcall(function()
			return profileStore:GetAsync(key)
		end)
		if success then
			break
		end
		warn("[Database] Load attempt " .. tostring(attempt) .. " failed for " .. player.Name .. ": " .. tostring(saved))
		if RunService:IsStudio() and isStudioAccessError(saved) then
			break
		end
		task.wait(attempt)
	end
	if not success and RunService:IsStudio() then
		-- Studio offline fallback: play with a fresh in-memory profile instead of a dead session.
		switchToMockStore("Studio could not reach the DataStore for " .. player.Name .. ".")
		success, saved = pcall(function()
			return profileStore:GetAsync(key)
		end)
	end
	loadingProfiles[player] = nil
	if not player.Parent then
		return
	end
	if not success then
		warn("[Database] Profile for " .. player.Name .. " was not loaded; refusing to create/save a default profile")
		return
	end
	profiles[player] = Database.EnsureStatDefaults(mergeDefaults(saved, defaults))
	local okMigrate, migrateErr = pcall(migrateMoneyScale, profiles[player])
	if not okMigrate then
		warn("[Database] Money scale migration failed for " .. player.Name .. ": " .. tostring(migrateErr))
	end
	fireLoaded(player, profiles[player])
	print("[Database] Loaded profile for " .. player.Name .. (usingMockStore and " (mock store)" or ""))
end

local function serializable(value)
	if type(value) ~= "table" then
		if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
			return value
		end
		return nil
	end
	local result = {}
	for key, nested in pairs(value) do
		local clean = serializable(nested)
		if clean ~= nil and (type(key) == "string" or type(key) == "number") then
			result[key] = clean
		end
	end
	return result
end

local function saveProfile(player, reason)
	local profile = profiles[player]
	if not profile or not loadedProfiles[player] then
		warn("[Database] Skipping unsafe save for " .. player.Name .. " (profile was not loaded)")
		return false
	end
	if savingProfiles[player] then
		if reason == "Autosave" then
			return true
		end
		-- A leave/shutdown save must not be dropped just because an autosave is in flight: that
		-- autosave serialized its payload before yielding, so progress made since would be lost.
		-- Wait for it, then write a fresh payload.
		local deadline = os.clock() + 30
		while savingProfiles[player] and os.clock() < deadline do
			task.wait()
		end
		profile = profiles[player]
		if not profile or not loadedProfiles[player] then
			return false
		end
	end
	savingProfiles[player] = true
	-- Stamped on every save (not only in a separate PlayerRemoving handler, which races this
	-- save) so OfflineAssetsService can value the absence on the next login.
	profile.LastSeenAt = os.time()
	local payload = serializable(cloneValue(profile))
	local key = "Player_" .. tostring(player.UserId)
	local success, err = false, nil
	for attempt = 1, 3 do
		success, err = pcall(function()
			profileStore:UpdateAsync(key, function()
				return payload
			end)
		end)
		if success then
			break
		end
		warn("[Database] Save attempt " .. tostring(attempt) .. " failed for " .. player.Name .. ": " .. tostring(err))
		task.wait(attempt)
	end
	savingProfiles[player] = nil
	if not success then
		warn("[Database] Failed to save " .. player.Name .. " (" .. tostring(reason) .. "): " .. tostring(err))
		return false
	end
	if reason ~= "Autosave" then
		print("[Database] Saved profile for " .. player.Name .. " (" .. tostring(reason) .. ")")
	end
	return true
end

function Database.Get(player)
	return profiles[player]
end

function Database.WaitForProfile(player, timeout)
	local deadline = os.clock() + (timeout or 30)
	while not loadedProfiles[player] and player.Parent and os.clock() < deadline do
		task.wait()
	end
	return profiles[player]
end

function Database.UnsafeGetProfileAwait(player)
	return profiles[player], loadedProfiles[player] == true
end

function Database.IsPlayerLoaded(player)
	return loadedProfiles[player] == true
end

function Database.IsUsingMockStore()
	return usingMockStore
end

function Database.OnLoaded(callback)
	table.insert(loadedCallbacks, callback)
	for player, profile in pairs(profiles) do
		if loadedProfiles[player] then
			task.spawn(callback, player, profile)
		end
	end
end

function Database.OnFieldChanged(field, callback)
	fieldCallbacks[field] = fieldCallbacks[field] or {}
	table.insert(fieldCallbacks[field], callback)
end

function Database.Set(player, changes)
	local profile = profiles[player]
	if not profile or not loadedProfiles[player] then
		return nil
	end
	for field, value in pairs(changes) do
		profile[field] = value
		for _, callback in ipairs(fieldCallbacks[field] or {}) do
			task.spawn(callback, player, value)
		end
	end
	if statsRemote then
		statsRemote:FireClient(player, changes)
	end
	return profile
end

function Database.SetAndBroadcast(player, changes)
	return Database.Set(player, changes)
end

function Database.UpdateProfileImmutable(player, updater)
	local profile = profiles[player]
	if not profile or not loadedProfiles[player] then
		return nil
	end
	local updated = updater(cloneValue(profile))
	if type(updated) == "table" then
		profiles[player] = updated
	end
	return profiles[player]
end

function Database.ResetProfile(player)
	profiles[player] = Database.EnsureStatDefaults(cloneValue(defaults))
	migrateMoneyScale(profiles[player]) -- a fresh profile: stamped only, so a later load never divides it again
	loadedProfiles[player] = true
	return profiles[player]
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadProfile, player)
end)

Players.PlayerRemoving:Connect(function(player)
	saveProfile(player, "PlayerRemoving")
	profiles[player] = nil
	loadedProfiles[player] = nil
	loadingProfiles[player] = nil
	savingProfiles[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			saveProfile(player, "Autosave")
		end
	end
end)

game:BindToClose(function()
	local remaining = 0
	for _, player in ipairs(Players:GetPlayers()) do
		remaining += 1
		task.spawn(function()
			saveProfile(player, "BindToClose")
			remaining -= 1
		end)
	end
	local deadline = os.clock() + 25
	while remaining > 0 and os.clock() < deadline do
		task.wait()
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadProfile, player)
end

return Database
