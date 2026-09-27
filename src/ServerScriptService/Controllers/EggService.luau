-- ServerScriptService.Controllers.EggService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Database = require(game.ServerScriptService.Library.Database)
local EggItemUtil = require(ReplicatedStorage.Library.Util.EggItemUtil)
local AreaEggResetTimeUtil = require(ReplicatedStorage.Library.Util.AreaEggResetTimeUtil)
local Assets = require(ReplicatedStorage.Directory.Assets)
local ItemDisplay = require(ReplicatedStorage.Library.Modules.ItemDisplay)
local AssetService = require(script.Parent.AssetService)

local Network = ReplicatedStorage:WaitForChild("Network")
local RequestRuntimeSnapshotRemote = Network:WaitForChild("Eggs: RequestRuntimeSnapshot")
local RequestEggRecordRemote = Network:WaitForChild("Eggs: RequestEggRecord")
local RequestEquipToolRemote = Network:WaitForChild("Eggs: RequestEquipTool")
local RequestUnequipToolRemote = Network:WaitForChild("Eggs: RequestUnequipTool")
local RequestPlaceEggRemote = Network:WaitForChild("Eggs: RequestPlaceEgg")
local RequestSkipGrowthRemote = Network:WaitForChild("Eggs: RequestSkipGrowth")
local RequestHatchEggRemote = Network:WaitForChild("Eggs: RequestHatchEgg")
local RequestCompleteHatchEggRemote = Network:WaitForChild("Eggs: RequestCompleteHatchEgg")
local RuntimeOwnerUpdatedRemote = Network:WaitForChild("Eggs: RuntimeOwnerUpdated")
local RuntimeOwnerClearedRemote = Network:WaitForChild("Eggs: RuntimeOwnerCleared")
local RequestAreaEggSnapshotRemote = Network:WaitForChild("Eggs: RequestAreaEggSnapshot")
local RequestAreaEggRareSpawnPresentationsRemote = Network:WaitForChild("Eggs: RequestAreaEggRareSpawnPresentations")

local EggService = {}
local uidCounter = 0
local function newUid(prefix)
	uidCounter += 1
	return string.format("%s_%d_%d", prefix, os.time(), uidCounter)
end
EggService.NewUid = newUid

function EggService.RollNewEgg(category)
	return EggItemUtil.BuildSavedEgg(category)
end

local function toRuntimeRecord(egg, growthSpeedMultiplier)
	local placement = nil
	if egg.Placement then
		placement = {
			LocalCFrame = CFrame.new(table.unpack(egg.Placement.LocalCFrame)),
			PlacedAt = egg.Placement.PlacedAt,
			GrowthDuration = egg.Placement.GrowthDuration,
			GrowthCreditSeconds = egg.Placement.GrowthCreditSeconds,
			NightGrowthPeriodIndex = egg.Placement.NightGrowthPeriodIndex,
			NightGrowthCreditSeconds = egg.Placement.NightGrowthCreditSeconds,
			ReadyAt = egg.Placement.ReadyAt,
		}
	end
	return {
		AssetCategory = egg.AssetCategory,
		AssetScale = egg.AssetScale,
		AssetEyeColor = egg.AssetEyeColor,
		AssetColorSeed = egg.AssetColorSeed,
		AssetColorIndex = egg.AssetColorIndex,
		Mutations = egg.Mutations,
		BaseMutation = egg.BaseMutation,
		AssetGender = egg.AssetGender,
		AssetPersonality = egg.AssetPersonality,
		IsStolenDNA = egg.IsStolenDNA,
		Placement = placement,
		GrowthSpeedMultiplier = growthSpeedMultiplier or 1,
	}
end

local function growthSpeedMultiplierFor(player)
	local ok, mult = pcall(EggItemUtil.GetGrowthSpeedMultiplier, player:GetAttribute("MonetizationX2GrowthGamepassOwned") == true)
	return ok and mult or 1
end

local function placedRecordsFor(profile, growthSpeedMultiplier)
	local records = {}
	local any = false
	for uid, egg in pairs(profile.EggInventory) do
		if egg.Placement then
			records[uid] = toRuntimeRecord(egg, growthSpeedMultiplier)
			any = true
		end
	end
	return records, any
end

local function broadcastOwnerRecords(player)
	local profile = Database.Get(player)
	if not profile then return end
	local records, any = placedRecordsFor(profile, growthSpeedMultiplierFor(player))
	if any then
		RuntimeOwnerUpdatedRemote:FireAllClients({ OwnerUserId = player.UserId, Records = records })
	else
		RuntimeOwnerClearedRemote:FireAllClients({ OwnerUserId = player.UserId })
	end
end
EggService.BroadcastOwnerRecords = broadcastOwnerRecords

local function destroyExistingEggTool(player)
	for _, container in ipairs({ player:FindFirstChild("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute("ItemType") == "AssetEgg" then
					child:Destroy()
				end
			end
		end
	end
end

local function grantEggTool(player, uid, egg)
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then return false end
	destroyExistingEggTool(player)
	local tool = Instance.new("Tool")
	tool.Name = (egg.AssetCategory or "Egg") .. " Egg"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 1)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	tool:SetAttribute("ItemType", "AssetEgg")
	tool:SetAttribute("UID", uid)
	tool:SetAttribute("Category", egg.AssetCategory)
	tool.Parent = backpack
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:EquipTool(tool) end
	return true
end
EggService.GrantEggTool = grantEggTool

local function withPlacementForMath(egg)
	local clone = table.clone(egg)
	clone.Placement = table.clone(egg.Placement)
	clone.Placement.LocalCFrame = CFrame.new(table.unpack(egg.Placement.LocalCFrame))
	return clone
end

-- The clock growth is judged on: the same one the clients use (Workspace:GetServerTimeNow), so a timer that reads
-- 0 on screen is ready on the server too (os.time() lagged up to a second behind).
local function serverNow()
	return Workspace:GetServerTimeNow()
end

local function isReady(egg, now, growthSpeedMultiplier)
	if not egg.Placement then return false end
	if egg.Placement.ReadyAt ~= nil then return true end
	local ok, ready = pcall(function()
		local record = withPlacementForMath(egg)
		local nightCredit = EggItemUtil.GetCurrentNightGrowthCreditSeconds(record, now, growthSpeedMultiplier or 1)
		return EggItemUtil.IsGrowthReady(record, now, growthSpeedMultiplier or 1, nightCredit)
	end)
	return ok and ready or false
end

function EggService.GrantEgg(player, category)
	local profile = Database.Get(player)
	if not profile then return nil end
	local ok, egg = pcall(EggItemUtil.BuildSavedEgg, category)
	if not ok then return nil end
	local uid = newUid("Egg")
	profile.EggInventory[uid] = egg
	Database.Set(player, { EggInventory = profile.EggInventory })
	return uid
end

Players.PlayerRemoving:Connect(function(player)
	RuntimeOwnerClearedRemote:FireAllClients({ OwnerUserId = player.UserId })
end)

RequestRuntimeSnapshotRemote.OnServerInvoke = function()
	local snapshot = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = Database.Get(player)
		if profile then
			local records, any = placedRecordsFor(profile, growthSpeedMultiplierFor(player))
			if any then table.insert(snapshot, { OwnerUserId = player.UserId, Records = records }) end
		end
	end
	return snapshot
end

RequestEggRecordRemote.OnServerInvoke = function(player, uid)
	local profile = Database.Get(player)
	local egg = profile and type(uid) == "string" and profile.EggInventory[uid]
	return egg and toRuntimeRecord(egg, growthSpeedMultiplierFor(player)) or nil
end

RequestEquipToolRemote.OnServerInvoke = function(player, uid)
	local profile = Database.Get(player)
	if not profile then return false, "Profile not loaded" end
	if type(uid) ~= "string" then return false, "Invalid egg" end
	local egg = profile.EggInventory[uid]
	if not egg then return false, "Egg not found" end
	if egg.Placement then return false, "Egg is already placed" end
	-- Carrier rules (AreaEggService sets CarryingEgg): no tools while carrying a stolen egg.
	if player:GetAttribute("CarryingEgg") == true then return false, "Drop the egg to use items!" end
	if not grantEggTool(player, uid, egg) then return false, "No backpack" end
	return true
end

RequestUnequipToolRemote.OnServerInvoke = function(player)
	destroyExistingEggTool(player)
	return true
end

RequestPlaceEggRemote.OnServerInvoke = function(player, args)
	local profile = Database.Get(player)
	if not profile then return false, "Profile not loaded" end
	if type(args) ~= "table" or type(args.Uid) ~= "string" or typeof(args.LocalCFrame) ~= "CFrame" then return false, "Invalid request" end
	local egg = profile.EggInventory[args.Uid]
	if not egg then return false, "Egg not found" end
	if egg.Placement then return false, "Already placed" end
	-- GrowthDuration stays nil: EggItemUtil.GetGrowthDuration then derives the incubation time
	-- from the hero config (Assets.Directory[category].Egg.GrowthTime x the egg's scale curve),
	-- on the server and on every client alike.
	egg.Placement = { LocalCFrame = { args.LocalCFrame:GetComponents() }, PlacedAt = os.time(), GrowthDuration = nil, ReadyAt = nil }
	destroyExistingEggTool(player)
	Database.Set(player, { EggInventory = profile.EggInventory })
	broadcastOwnerRecords(player)
	return true
end

-- The client calls this whenever a player interacts with a still-growing egg, expecting
-- (ok, err, productId) so it can open a Robux purchase prompt; the skip itself belongs in the
-- purchase receipt. The ripped product ids belong to another universe, so there is no working
-- paid path: refuse instead of readying the egg for free, which let every egg hatch instantly
-- and skipped incubation entirely.
RequestSkipGrowthRemote.OnServerInvoke = function(player, uid)
	local profile = Database.Get(player)
	local egg = profile and type(uid) == "string" and profile.EggInventory[uid]
	if not egg or not egg.Placement then return false, "Egg not placed" end
	return false, "Skip growth is not available"
end

RequestHatchEggRemote.OnServerInvoke = function(player, uid)
	local profile = Database.Get(player)
	local egg = profile and type(uid) == "string" and profile.EggInventory[uid]
	if not egg or not egg.Placement then return false, "Egg not placed" end
	if not isReady(egg, serverNow(), growthSpeedMultiplierFor(player)) then
		return false, "Egg is not ready yet"
	end
	-- Lock it ready (owner 2026-09-27: "the egg showed hatched but did not hatch and got smaller"): the hatch
	-- animation runs ~6.6 s before RequestCompleteHatchEgg, and an egg that was ready only thanks to the night bonus
	-- used to fail that second check once day came. Placement.ReadyAt makes it ready for good (GetGrowthAlpha = 1).
	if egg.Placement.ReadyAt == nil then
		egg.Placement.ReadyAt = os.time()
	end
	return true
end

local function findExistingAssetTool(player, uid)
	-- Both containers checked explicitly: ipairs({ nil, backpack }) would stop at a nil
	-- Character (mid-respawn) and miss the Backpack, creating a duplicate Tool.
	local containers = {}
	if player.Character then table.insert(containers, player.Character) end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then table.insert(containers, backpack) end
	for _, container in ipairs(containers) do
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and child:GetAttribute("UID") == uid then return child end
		end
	end
	return nil
end

local function grantAssetTool(player, uid, itemData)
	local existing = findExistingAssetTool(player, uid)
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then
		warn("[EggService] Backpack unavailable while returning pet " .. tostring(uid))
		return false
	end
	if existing then
		if existing.Parent == player.Character then
			existing.Parent = backpack
		end
		return true
	end
	local ok, err = pcall(ItemDisplay.CreateTool, itemData, uid, player)
	if not ok then
		warn("[EggService] ItemDisplay.CreateTool failed for " .. tostring(uid) .. ": " .. tostring(err))
		return false
	end
	return findExistingAssetTool(player, uid) ~= nil
end
EggService.GrantAssetTool = grantAssetTool

local function grantAssetToolWithRetry(player, uid, itemData)
	for attempt = 1, 3 do
		if grantAssetTool(player, uid, itemData) then
			return true
		end
		if attempt < 3 then
			task.wait(0.15)
		end
	end
	warn("[EggService] Could not return pet to Backpack after retries: " .. tostring(uid))
	return false
end
EggService.GrantAssetToolWithRetry = grantAssetToolWithRetry
EggService.GrantAssetTool = grantAssetTool

local function isEquipped(profile, uid)
	return type(profile.EquippedAssets) == "table" and table.find(profile.EquippedAssets, uid) ~= nil
end

local function populateAssetBackpack(player)
	local profile = Database.Get(player)
	if not profile or not profile.Inventory then return end
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then return end
	local uids = {}
	for uid in pairs(profile.Inventory) do table.insert(uids, uid) end
	for _, uid in ipairs(uids) do
		-- Heroes placed on the plot (EquippedAssets) live in the pen, not in the Backpack.
		-- Re-checked per item because CreateTool can yield while the pen changes.
		local itemData = profile.Inventory[uid]
		if itemData and not isEquipped(profile, uid) then grantAssetTool(player, uid, itemData) end
	end
end

Database.OnLoaded(function(player)
	task.defer(populateAssetBackpack, player)
end)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.defer(populateAssetBackpack, player)
	end)
end)
for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function() task.defer(populateAssetBackpack, player) end)
	if player.Character then task.defer(populateAssetBackpack, player) end
end

-- True when the player currently owns a plot (PlotService loads before EggService in
-- Bootstrap; required lazily so a PlotService failure never takes egg handling down with it).
local function ownsPlot(player)
	local okRequire, PlotService = pcall(require, script.Parent:FindFirstChild("PlotService"))
	if not okRequire or type(PlotService) ~= "table" or type(PlotService.GetPlotId) ~= "function" then
		return false
	end
	return PlotService.GetPlotId(player) ~= nil
end

RequestCompleteHatchEggRemote.OnServerInvoke = function(player, uid)
	local profile = Database.Get(player)
	local egg = profile and type(uid) == "string" and profile.EggInventory[uid]
	if not egg or not egg.Placement then return false, "Egg not placed" end
	if not isReady(egg, serverNow(), growthSpeedMultiplierFor(player)) then return false, "Egg is not ready yet" end
	local ok, itemData = pcall(EggItemUtil.BuildAssetItemData, withPlacementForMath(egg))
	if not ok then warn("[EggService] BuildAssetItemData failed: " .. tostring(itemData)); return false, "Failed to hatch" end
	local petUid = newUid("Pet")
	profile.Inventory[petUid] = itemData
	profile.EggInventory[uid] = nil
	local autoSold, autoSellPrice = AssetService.MaybeAutoSell(player, profile, petUid)
	if autoSold then profile.Money = (profile.Money or 0) + autoSellPrice end
	profile.HasPlacedFirstEgg = true
	profile.Index[egg.AssetCategory] = true
	-- hub leaderboard "EGGS HATCHED" (LeaderboardService): one per completed hatch, counted here on the server only
	local hatched = tonumber(profile.EggsHatched)
	if hatched == nil or hatched ~= hatched or hatched == math.huge or hatched < 0 then
		hatched = 0
	end
	profile.EggsHatched = math.floor(hatched) + 1
	Database.SetAndBroadcast(player, { EggInventory = profile.EggInventory, Inventory = profile.Inventory, Money = profile.Money, HasPlacedFirstEgg = true, Index = profile.Index, EggsHatched = profile.EggsHatched })
	broadcastOwnerRecords(player)
	if not autoSold then
		-- The hatched hero goes straight onto the owner's plot PetArea through AssetService's
		-- equip path (pen capacity, EquippedAssets, runtime broadcast, ghost-tool cleanup). Only
		-- when the pen is full (or the owner has no plot) does it stay a Backpack Tool.
		local placed = ownsPlot(player) and AssetService.EquipFromInventory ~= nil
			and AssetService.EquipFromInventory(player, petUid)
		if not placed then
			task.spawn(grantAssetTool, player, petUid, itemData)
		end
	end
	return true, nil, petUid
end

RequestAreaEggSnapshotRemote.OnServerInvoke = function() return { Records = {}, ServerTime = os.time() } end
RequestAreaEggRareSpawnPresentationsRemote.OnServerInvoke = function() return true, {} end

-- Night growth commit (owner 2026-09-27: "the egg shows ready but does not hatch and gets smaller: the timer must be
-- accurate"). During the night placed eggs grow AreaEggResetTimeUtil.GetNightGrowthBonusRate() times faster; the
-- server and the clients both add that live credit, but nothing ever saved it, so at day start the server's egg lost
-- it while the client's night animation (NightEggTimeSkipAnimation) waited forever for the commit and kept showing
-- the egg grown / "Ready!". At each day start every loaded player's placed eggs get the night they just lived:
-- GrowthCreditSeconds += credit, NightGrowthPeriodIndex = the new period, NightGrowthCreditSeconds = the night's
-- total -- exactly what the client's AcknowledgeRecord expects -- and the owner's records are broadcast.
local function commitNightGrowth(player, dayStartsAt)
	local profile = Database.Get(player)
	if not profile or type(profile.EggInventory) ~= "table" then
		return 0
	end
	local mult = growthSpeedMultiplierFor(player)
	local nightStartsAt = dayStartsAt - AreaEggResetTimeUtil.GetNightDurationSeconds()
	local periodIndex = AreaEggResetTimeUtil.GetPeriodIndex(dayStartsAt)
	local committedEggs = 0
	for _, egg in pairs(profile.EggInventory) do
		local placement = egg.Placement
		if placement and placement.ReadyAt == nil and type(placement.PlacedAt) == "number" and placement.PlacedAt <= nightStartsAt then
			local ok, credit = pcall(function()
				return EggItemUtil.GetNightGrowthCreditSecondsAt(withPlacementForMath(egg), dayStartsAt, mult, nightStartsAt, periodIndex)
			end)
			if ok and type(credit) == "number" and credit == credit and credit > 0 then
				local already = if placement.NightGrowthPeriodIndex == periodIndex then (placement.NightGrowthCreditSeconds or 0) else 0
				placement.GrowthCreditSeconds = (placement.GrowthCreditSeconds or 0) + credit
				placement.NightGrowthPeriodIndex = periodIndex
				placement.NightGrowthCreditSeconds = already + credit
				committedEggs += 1
			end
		end
	end
	if committedEggs > 0 then
		Database.Set(player, { EggInventory = profile.EggInventory })
		broadcastOwnerRecords(player)
	end
	return committedEggs
end
EggService.CommitNightGrowth = commitNightGrowth

task.spawn(function()
	local lastIndex = AreaEggResetTimeUtil.GetPeriodIndex(serverNow())
	while true do
		task.wait(0.25)
		local index = AreaEggResetTimeUtil.GetPeriodIndex(serverNow())
		if index > lastIndex then
			lastIndex = index
			local dayStartsAt = AreaEggResetTimeUtil.GetPeriodStartsAt(index)
			for _, player in ipairs(Players:GetPlayers()) do
				local ok, err = pcall(commitNightGrowth, player, dayStartsAt)
				if not ok then
					warn("[EggService] night growth commit failed for " .. player.Name .. ": " .. tostring(err))
				end
			end
		end
	end
end)

-- The x2 Growth pass changes the growth multiplier the clients time eggs with (GamepassService only sets the player
-- attribute): re-broadcast the owner's records so their timers follow at once.
local function watchGrowthPass(player)
	player:GetAttributeChangedSignal("MonetizationX2GrowthGamepassOwned"):Connect(function()
		pcall(broadcastOwnerRecords, player)
	end)
end
Players.PlayerAdded:Connect(watchGrowthPass)
for _, player in ipairs(Players:GetPlayers()) do
	watchGrowthPass(player)
end

return EggService