-- ServerScriptService.Controllers.FuseMachineService
--
-- IMPORTANT: unlike everything else built this session, there is NO authoritative fusion
-- ruleset anywhere in the rip to match -- no Directory.Fusion module, no slot-count/duration
-- constant found in either FuseMachine LocalScript (checked both StarterGui.FuseMachine and
-- Game.FuseMachine). The original rules lived entirely on the real private server and never
-- replicated. Remote contract (uid args/returns) IS confirmed by reading the client in full:
--   InsertMob(uid) -> (ok, err?)      RemoveMob(uid) -> (ok, err?)
--   StartFuse() -> (ok, err?)          AcknowledgeInfo() -> boolean
--   CompleteReveal() -> (ok, err?, category?)
--
-- Design below is MINE, not reverse-engineered -- documented so a future session can replace it
-- with something closer to the real game if better information turns up:
--   3 slots (FusionSlots), must all be the same AssetCategory from profile.Inventory.
--   StartFuse consumes the 3 pets, runs for 60s (FusionDuration), then CompleteReveal grants a
--   freshly-rolled egg (EggItemUtil.BuildSavedEgg) of that SAME category into EggInventory --
--   i.e. "trade 3 duplicates for one fresh roll" rather than a rarity-up mechanic (no tier
--   progression table exists to reverse-engineer, so committing to a rarity-up chain would be
--   pure invention layered on invention).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local EggService = require(game.ServerScriptService.Controllers.EggService)
local EggItemUtil = require(ReplicatedStorage.Library.Util.EggItemUtil)

local Network = ReplicatedStorage:WaitForChild("Network")
local InsertMobRemote = Network:WaitForChild("FuseMachine: InsertMob")
local RemoveMobRemote = Network:WaitForChild("FuseMachine: RemoveMob")
local StartFuseRemote = Network:WaitForChild("FuseMachine: StartFuse")
local CompleteRevealRemote = Network:WaitForChild("FuseMachine: CompleteReveal")
local AcknowledgeInfoRemote = Network:WaitForChild("FuseMachine: AcknowledgeInfo")

local SLOT_COUNT = 3
local FUSION_DURATION = 60

local FuseMachineService = {}

InsertMobRemote.OnServerInvoke = function(player, uid)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end
	if type(uid) ~= "string" then
		return false, "Invalid pet"
	end
	if profile.FusionLocked then
		return false, "Fusion in progress"
	end
	local itemData = profile.Inventory[uid]
	if not itemData then
		return false, "Pet not found"
	end
	if #profile.FusionSlots >= SLOT_COUNT then
		return false, "Slots full"
	end
	for _, existing in ipairs(profile.FusionSlots) do
		if existing == uid then
			return false, "Already inserted"
		end
		local existingItem = profile.Inventory[existing]
		if existingItem and existingItem.Category ~= itemData.Category then
			return false, "All slots must be the same pet"
		end
	end

	table.insert(profile.FusionSlots, uid)
	Database.Set(player, { FusionSlots = profile.FusionSlots })
	return true
end

RemoveMobRemote.OnServerInvoke = function(player, uid)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end
	if profile.FusionLocked then
		return false, "Fusion in progress"
	end
	for i, existing in ipairs(profile.FusionSlots) do
		if existing == uid then
			table.remove(profile.FusionSlots, i)
			Database.Set(player, { FusionSlots = profile.FusionSlots })
			return true
		end
	end
	return false, "Pet not in a slot"
end

StartFuseRemote.OnServerInvoke = function(player)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end
	if profile.FusionLocked then
		return false, "Fusion already running"
	end
	if #profile.FusionSlots < SLOT_COUNT then
		return false, "Need " .. SLOT_COUNT .. " pets to fuse"
	end
	if next(profile.EggInventory) ~= nil then
		local count = 0
		for _ in pairs(profile.EggInventory) do
			count += 1
		end
		if count >= 115 then
			return false, "Your egg inventory is full!"
		end
	end

	local category = nil
	for _, uid in ipairs(profile.FusionSlots) do
		local itemData = profile.Inventory[uid]
		if not itemData then
			return false, "A slotted pet is missing"
		end
		category = category or itemData.Category
	end

	for _, uid in ipairs(profile.FusionSlots) do
		profile.Inventory[uid] = nil
	end
	profile.FusionSlots = {}
	profile.FusionLocked = true
	profile.FusionEndsAt = os.time() + FUSION_DURATION
	profile.FusionDuration = FUSION_DURATION
	profile.FusionReward = category

	Database.SetAndBroadcast(player, {
		Inventory = profile.Inventory,
		FusionSlots = profile.FusionSlots,
		FusionLocked = profile.FusionLocked,
		FusionEndsAt = profile.FusionEndsAt,
		FusionDuration = profile.FusionDuration,
		FusionReward = profile.FusionReward,
	})

	return true
end

CompleteRevealRemote.OnServerInvoke = function(player)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end
	if not profile.FusionLocked or not profile.FusionReward then
		return false, "Nothing to reveal"
	end
	if os.time() < (profile.FusionEndsAt or 0) then
		return false, "Fusion is not ready yet"
	end

	local category = profile.FusionReward
	local ok, egg = pcall(EggItemUtil.BuildSavedEgg, category)
	if ok then
		local uid = EggService.NewUid("Egg")
		profile.EggInventory[uid] = egg
	else
		warn("[FuseMachineService] BuildSavedEgg failed for " .. tostring(category) .. " -- player " .. player.Name .. " loses their 3 fused pets with no reward: " .. tostring(egg))
	end

	profile.FusionLocked = false
	profile.FusionEndsAt = nil
	profile.FusionDuration = nil
	profile.FusionReward = nil

	Database.SetAndBroadcast(player, {
		EggInventory = profile.EggInventory,
		FusionLocked = false,
	}, { "FusionEndsAt", "FusionDuration", "FusionReward" })

	return true, nil, category
end

AcknowledgeInfoRemote.OnServerInvoke = function(player)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	profile.FusionInfoAcknowledged = true
	Database.Set(player, { FusionInfoAcknowledged = true })
	return true
end

return FuseMachineService
