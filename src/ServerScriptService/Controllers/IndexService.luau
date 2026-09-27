-- ServerScriptService.Controllers.IndexService
-- The "Index" (pokedex-style discovery log): profile.Index[category]=true once you've hatched
-- one (set in EggService.RequestCompleteHatchEgg), profile.IndexClaimedCategories[category]=true
-- once you've claimed its one-time reward. Contract confirmed by reading
-- StarterPlayer...GUI.Index in full:
--   _isDiscovered = profile.Index[Category] == true
--   _isClaimed = profile.IndexClaimedCategories[Category] == true
--   _isClaimable = discovered and not claimed
--   Index: RequestClaim(category) -> (ok, err?, results?) where results is an array the client
--     folds into IndexClaimedCategories itself (Save.ProcessManualTableKeyChange) -- we still
--     broadcast the authoritative New Stats update ourselves.
--   Index: RequestClaimAll() -> (ok, err?, results?) same shape, one entry per category claimed.
-- Rewards per category, read from ReplicatedStorage.Library.Util.AssetItemUtil (both are real
-- per-creature values/formulas, not guesses):
--   GetIndexMoneyRewardAmount(category) -> one-time Money reward
--   GetIndexSpeedRewardAmount(category) -> Assets.Directory[category].IndexSpeedReward,
--     added permanently to profile.SpeedPower
--
-- NOT built here: RequestEquipAreaBat (the stage bat for a completed stage page; answered by
-- GearService.server since INDEXBATS 2026-09-24) and RequestClaimLimitedEggReward (seasonal/limited
-- offer, still answered safely by StubService).
--
-- Index completion rewards (Gekko TO DO #5, Directory.BaseThemes): once every hero of a stage is
-- discovered, profile.UnlockedBaseThemes[stageKey] = true (checked whenever profile.Index changes
-- and again on join, so profiles that completed a stage earlier get it too) with a notification; a
-- first unlock while no theme is equipped equips it right away. The owner picks the theme shown on
-- their plot with "BaseThemes: RequestEquip"(stageKey | "") -> (ok, err?, equippedKey?), which
-- only accepts unlocked themes; PlotService applies profile.EquippedBaseTheme to the plot.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local SpeedService = require(game.ServerScriptService.Controllers.SpeedService)
local AssetItemUtil = require(ReplicatedStorage.Library.Util.AssetItemUtil)

local Network = ReplicatedStorage:WaitForChild("Network")
local RequestClaimRemote = Network:WaitForChild("Index: RequestClaim")
local RequestClaimAllRemote = Network:WaitForChild("Index: RequestClaimAll")

-- Created at build time (scripts/steps/post_zz_base_themes.luau); created here if a place lacks it.
local EQUIP_BASE_THEME_REMOTE = "BaseThemes: RequestEquip"
local EquipBaseThemeRemote = Network:FindFirstChild(EQUIP_BASE_THEME_REMOTE)
if EquipBaseThemeRemote == nil or not EquipBaseThemeRemote:IsA("RemoteFunction") then
	EquipBaseThemeRemote = Instance.new("RemoteFunction")
	EquipBaseThemeRemote.Name = EQUIP_BASE_THEME_REMOTE
	EquipBaseThemeRemote.Parent = Network
end

-- Optional: without the theme directory the Index rewards above keep working and equips are refused.
local BaseThemes = nil
do
	local directory = ReplicatedStorage:FindFirstChild("Directory")
	local module = directory and directory:FindFirstChild("BaseThemes")
	if module and module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" then
			BaseThemes = result
		else
			warn("[IndexService] Directory.BaseThemes failed to load (base themes disabled): " .. tostring(result))
		end
	else
		warn("[IndexService] Directory.BaseThemes missing (base themes disabled)")
	end
end

local UNLOCK_NOTICE_COLOR = Color3.fromRGB(255, 214, 64)
local JOIN_NOTICE_DELAY = 6 -- s: lets the client's notification UI load before a join-time unlock is announced
local EQUIP_COOLDOWN = 0.4 -- s between two equip requests of one player

local IndexService = {}

local function isClaimable(profile, category)
	return profile.Index[category] == true and profile.IndexClaimedCategories[category] ~= true
end

local function rewardFor(category)
	local ok, money = pcall(AssetItemUtil.GetIndexMoneyRewardAmount, category)
	if not ok then
		warn("[IndexService] GetIndexMoneyRewardAmount failed for " .. tostring(category) .. " (reward=0): " .. tostring(money))
	end
	local ok2, speed = pcall(AssetItemUtil.GetIndexSpeedRewardAmount, category)
	if not ok2 then
		warn("[IndexService] GetIndexSpeedRewardAmount failed for " .. tostring(category) .. " (reward=0): " .. tostring(speed))
	end
	return (ok and money) or 0, (ok2 and speed) or 0
end

local function claimCategory(profile, category)
	profile.IndexClaimedCategories[category] = true
	local money, speed = rewardFor(category)
	profile.Money = (profile.Money or 0) + money
	profile.SpeedPower = (profile.SpeedPower or 10) + speed
	return { Category = category }
end

RequestClaimRemote.OnServerInvoke = function(player, category)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end
	if type(category) ~= "string" then
		return false, "Invalid category"
	end
	if not isClaimable(profile, category) then
		return false, "Not claimable"
	end

	local result = claimCategory(profile, category)

	Database.SetAndBroadcast(player, {
		Money = profile.Money,
		SpeedPower = profile.SpeedPower,
		IndexClaimedCategories = profile.IndexClaimedCategories,
	})
	SpeedService.Refresh(player)

	return true, nil, { result }
end

RequestClaimAllRemote.OnServerInvoke = function(player)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end

	local results = {}
	for category in pairs(profile.Index) do
		if isClaimable(profile, category) then
			table.insert(results, claimCategory(profile, category))
		end
	end

	if #results == 0 then
		return false, "Nothing to claim"
	end

	Database.SetAndBroadcast(player, {
		Money = profile.Money,
		SpeedPower = profile.SpeedPower,
		IndexClaimedCategories = profile.IndexClaimedCategories,
	})
	SpeedService.Refresh(player)

	return true, nil, results
end

---------------------------------------------------------------------------------------------------
-- Index completion rewards: stage base themes
---------------------------------------------------------------------------------------------------

local function notifyUnlock(player, key, equipped, delaySeconds)
	local theme = BaseThemes and BaseThemes.Get(key)
	local remote = Network:FindFirstChild("Notifications_Show")
	if theme == nil or remote == nil or not remote:IsA("RemoteEvent") then
		return
	end
	local message = string.format("%s Index complete! %s base unlocked%s", theme.Franchise, theme.Name,
		equipped and " and equipped!" or ": equip it in the Index.")
	task.delay(delaySeconds or 0, function()
		if player.Parent ~= Players then
			return
		end
		pcall(remote.FireClient, remote, player, "Message", "Top", {
			Time = 6,
			Message = message,
			Color = UNLOCK_NOTICE_COLOR,
		})
	end)
end

-- Unlocks every theme whose stage is complete and drops an equipped theme that is not unlocked (a
-- stale or edited save). A new unlock while nothing is equipped is equipped right away.
local function syncBaseThemes(player, profile, noticeDelay)
	if BaseThemes == nil or type(profile) ~= "table" then
		return
	end
	if type(profile.UnlockedBaseThemes) ~= "table" then
		profile.UnlockedBaseThemes = {}
	end
	local unlocked = profile.UnlockedBaseThemes
	local newlyUnlocked = {}
	for _, key in ipairs(BaseThemes.Order) do
		if unlocked[key] ~= true and BaseThemes.IsComplete(profile.Index, key) then
			unlocked[key] = true
			table.insert(newlyUnlocked, key)
		end
	end

	local changes = nil
	local equipped = profile.EquippedBaseTheme
	if type(equipped) ~= "string" or (equipped ~= "" and (unlocked[equipped] ~= true or not BaseThemes.IsValidKey(equipped))) then
		equipped = ""
		changes = { EquippedBaseTheme = "" }
	end
	local autoEquipped = nil
	if #newlyUnlocked > 0 then
		changes = changes or {}
		changes.UnlockedBaseThemes = unlocked
		if equipped == "" then
			autoEquipped = newlyUnlocked[#newlyUnlocked]
			changes.EquippedBaseTheme = autoEquipped
		end
	end
	if changes then
		Database.SetAndBroadcast(player, changes)
	end
	for _, key in ipairs(newlyUnlocked) do
		notifyUnlock(player, key, key == autoEquipped, noticeDelay)
	end
end

function IndexService.SyncBaseThemes(player)
	local profile = Database.Get(player)
	if profile then
		local ok, err = pcall(syncBaseThemes, player, profile, 0)
		if not ok then
			warn("[IndexService] Base theme sync failed for " .. player.Name .. ": " .. tostring(err))
		end
	end
end

-- Every discovery goes through Database.Set(..., { Index = ... }) (EggService hatch, admin / trade paths).
Database.OnFieldChanged("Index", function(player)
	IndexService.SyncBaseThemes(player)
end)

-- Profiles that completed a stage before the rewards existed, or while the directory was missing.
Database.OnLoaded(function(player, profile)
	local ok, err = pcall(syncBaseThemes, player, profile, JOIN_NOTICE_DELAY)
	if not ok then
		warn("[IndexService] Base theme join check failed for " .. player.Name .. ": " .. tostring(err))
	end
end)

local lastEquipAt = {} -- [player] = os.clock() of the last accepted request

EquipBaseThemeRemote.OnServerInvoke = function(player, key)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end
	if BaseThemes == nil then
		return false, "Base themes unavailable"
	end
	if key == nil then
		key = ""
	end
	if type(key) ~= "string" or #key > 32 then
		return false, "Invalid theme"
	end
	local now = os.clock()
	if lastEquipAt[player] and now - lastEquipAt[player] < EQUIP_COOLDOWN then
		return false, "Too fast"
	end
	lastEquipAt[player] = now

	if key == "" then
		if profile.EquippedBaseTheme ~= "" then
			Database.SetAndBroadcast(player, { EquippedBaseTheme = "" })
		end
		return true, nil, ""
	end
	if not BaseThemes.IsValidKey(key) then
		return false, "Invalid theme"
	end
	-- a completion that has not been processed yet (e.g. the directory loaded late) still counts
	local ok = pcall(syncBaseThemes, player, profile, 0)
	if not ok or type(profile.UnlockedBaseThemes) ~= "table" or profile.UnlockedBaseThemes[key] ~= true then
		return false, "Locked"
	end
	if profile.EquippedBaseTheme ~= key then
		Database.SetAndBroadcast(player, { EquippedBaseTheme = key })
	end
	return true, nil, key
end

-- Studio-only test hook (never in a live server): setting the Player attribute DevUnlockBaseThemes = true from
-- the server command bar unlocks every base theme, e.g.
--   for _, p in game.Players:GetPlayers() do p:SetAttribute("DevUnlockBaseThemes", true) end
local devConnections = {} -- [player] = RBXScriptConnection
if RunService:IsStudio() then
	local function watchDevUnlock(player)
		devConnections[player] = player:GetAttributeChangedSignal("DevUnlockBaseThemes"):Connect(function()
			local profile = Database.Get(player)
			if player:GetAttribute("DevUnlockBaseThemes") ~= true or not profile or BaseThemes == nil then
				return
			end
			local unlocked = if type(profile.UnlockedBaseThemes) == "table" then profile.UnlockedBaseThemes else {}
			for _, key in ipairs(BaseThemes.Order) do
				unlocked[key] = true
			end
			Database.SetAndBroadcast(player, { UnlockedBaseThemes = unlocked })
			warn("[IndexService] Studio: every base theme unlocked for " .. player.Name)
		end)
	end
	Players.PlayerAdded:Connect(watchDevUnlock)
	for _, player in ipairs(Players:GetPlayers()) do
		watchDevUnlock(player)
	end
end

Players.PlayerRemoving:Connect(function(player)
	lastEquipAt[player] = nil
	if devConnections[player] then
		devConnections[player]:Disconnect()
		devConnections[player] = nil
	end
end)

return IndexService
