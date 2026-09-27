local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local EggService = require(game.ServerScriptService.Controllers.EggService)
local EggItemUtil = require(ReplicatedStorage.Library.Util.EggItemUtil)
local EggScaleUtil = require(ReplicatedStorage.Library.Util.EggScaleUtil)
local Assets = require(ReplicatedStorage.Directory.Assets)
local Areas = require(ReplicatedStorage.Directory.Areas)
local AreaEggSlotIdentity = require(ReplicatedStorage.Library.Util.AreaEggSlotIdentity)
local AreaEggResetTimeUtil = require(ReplicatedStorage.Library.Util.AreaEggResetTimeUtil)

local Network = ReplicatedStorage:WaitForChild("Network")
local RequestAreaEggSnapshotRemote = Network:WaitForChild("Eggs: RequestAreaEggSnapshot")
local RequestAreaEggCarryRemote = Network:WaitForChild("Eggs: RequestAreaEggCarry")
local RequestAreaEggDropRemote = Network:WaitForChild("Eggs: RequestAreaEggDrop")
local AreaEggUpdatedRemote = Network:WaitForChild("Eggs: AreaEggUpdated")
local AreaEggRemovedRemote = Network:WaitForChild("Eggs: AreaEggRemoved")
local AreaEggCarryStateRemote = Network:WaitForChild("Eggs: AreaEggCarryState")
local AreaEggClaimFeedbackRemote = Network:WaitForChild("Eggs: AreaEggClaimFeedback")
local AreaEggResetStartCountdownRemote = Network:WaitForChild("Eggs: AreaEggResetStartCountdown")
local RequestAreaEggRareSpawnPresentationsRemote = Network:WaitForChild("Eggs: RequestAreaEggRareSpawnPresentations")
local ForestHitRemote = Network:WaitForChild("Guards: ForestHit")
local ForestDepositRemote = Network:WaitForChild("Guards: ForestDeposit")

local SpeedHitWarningRemote = Network:WaitForChild("Guards: SpeedHitWarning")
local SpeedHitOfferRemote = Network:WaitForChild("Guards: SpeedHitOffer")

-- Night teleport cue (owner 2026-09-23: "Make Night tp you back to spawn"), server -> client only. The client half
-- is StarterPlayerScripts.GUI.NightTeleportCue (scripts/inject/night.luau): fade, toast, wall collision hand-off.
local NightTeleportRemote = Network:FindFirstChild("Eggs: NightTeleport")
if NightTeleportRemote == nil then
	NightTeleportRemote = Instance.new("RemoteEvent")
	NightTeleportRemote.Name = "Eggs: NightTeleport"
	NightTeleportRemote.Parent = Network
elseif not NightTeleportRemote:IsA("RemoteEvent") then
	warn("[AreaEggService] Network['Eggs: NightTeleport'] is a " .. NightTeleportRemote.ClassName .. ", night teleport cue disabled.")
	NightTeleportRemote = nil
end
if NightTeleportRemote then
	-- Nothing is expected from clients; drain whatever one sends instead of letting it queue.
	NightTeleportRemote.OnServerEvent:Connect(function() end)
end

-- Secret hero spawn broadcast (owner 2026-09-26: "when the current secret and more secrets to come [spawn] the global
-- messages says [Server] A SECRET HERO, JOYBOY HAS SPAWNED IN ONE PIECE! in chat and on your screen"), server -> every
-- client. The client half is StarterPlayerScripts.GUI.SecretHeroAnnouncer (scripts/inject/secretannounce.luau): a
-- system chat line + a 6 s gold/cyan top banner with a fanfare.
local SecretHeroSpawnedRemote = Network:FindFirstChild("Eggs: SecretHeroSpawned")
if SecretHeroSpawnedRemote == nil then
	SecretHeroSpawnedRemote = Instance.new("RemoteEvent")
	SecretHeroSpawnedRemote.Name = "Eggs: SecretHeroSpawned"
	SecretHeroSpawnedRemote.Parent = Network
elseif not SecretHeroSpawnedRemote:IsA("RemoteEvent") then
	warn("[AreaEggService] Network['Eggs: SecretHeroSpawned'] is a " .. SecretHeroSpawnedRemote.ClassName .. ", secret spawn broadcast disabled.")
	SecretHeroSpawnedRemote = nil
end
if SecretHeroSpawnedRemote then
	SecretHeroSpawnedRemote.OnServerEvent:Connect(function() end)
end

local SPEED_HIT_OFFER_PRODUCT_ID = nil
local SPEED_HIT_OFFER_AMOUNT = 500

-- Server-side villain chase (refactor contract C3). Optional: if the module is missing or fails to
-- load, eggs keep working and zones without ServerChase keep their client guard runtime.
local GuardChaseService = nil
do
	local controllersFolder = game:GetService("ServerScriptService"):FindFirstChild("Controllers")
	local chaseModule = controllersFolder and controllersFolder:FindFirstChild("GuardChaseService")
	if chaseModule then
		local ok, result = pcall(require, chaseModule)
		if ok and type(result) == "table" then
			GuardChaseService = result
		else
			warn("[AreaEggService] GuardChaseService failed to load, server guards disabled: " .. tostring(result))
		end
	else
		warn("[AreaEggService] GuardChaseService not found, server guards disabled.")
	end
end

-- Anti-exploit: a carry must start next to the egg (the Steal prompt is 8 studs) and outside the safe zone.
local CARRY_MAX_DISTANCE = 20
-- A guard normally walks a dropped egg home within seconds; this is the backstop for eggs nobody retrieves.
local DROPPED_EGG_RETURN_SECONDS = 30

local GuardAreasFolder = Workspace:WaitForChild("__OBJECTS"):WaitForChild("Areas"):WaitForChild("GuardAreas")

for _, area in ipairs(GuardAreasFolder:GetChildren()) do
	local nests = area:FindFirstChild("Nests")
	if nests then
		for _, nest in ipairs(nests:GetChildren()) do
			if nest:IsA("Model") and not nest:FindFirstChild("EggSpotBottom", true) then
				local spot = Instance.new("Part")
				spot.Name = "EggSpotBottom"
				spot.Size = Vector3.new(0.2, 0.2, 0.2)
				spot.Transparency = 1
				spot.CanCollide = false
				spot.CanTouch = false
				spot.CanQuery = false
				spot.Anchored = true
				spot.CFrame = nest:GetPivot() * CFrame.new(0, 1, 0)
				spot.Parent = nest
			end
		end
	end
end

-- Game-plan stages 1-6 (docs/STAGES_PLAN.md §1), in stage order. The legacy zones 7-9 are retired by the
-- build (scripts/steps/stages.luau) and never get eggs.
local ZONE_NAMES = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }
local RESPAWN_DELAY_SECONDS = 20

-- Hidden eggs: each stage has M EggSpot nests (placed by the build on the stage's EggSpot markers) and
-- keeps exactly N eggs alive among them (6, One Piece 8). Every spawn, respawn and night reset picks
-- random free spots, so the eggs move around and players have to explore. The build writes N to each
-- zone's ActiveEggCount attribute; this table is the fallback when the attribute is missing.
local ACTIVE_EGGS_BY_ZONE = { Volcano = 8 }
local DEFAULT_ACTIVE_EGGS = 6
-- Rotation rules (plan A7): at least this many active eggs sit on Hidden spots (EggSpot attribute copied onto
-- the nest by the build), and at least one active egg per stage is Epic or better, whenever possible.
local MIN_HIDDEN_ACTIVE_EGGS = 2
local EPIC_RARITY_NUMBER = 4
do
	local ok, number = pcall(function()
		return require(ReplicatedStorage.Directory.Rarity).Rarities.Epic.RarityNumber
	end)
	if ok and type(number) == "number" then
		EPIC_RARITY_NUMBER = number
	end
end
-- One chase per stage (plan A4). Villain names come from the Guard's VillainName/HeroId attributes; these are
-- the last-resort fallback (plan §1).
local VILLAIN_BY_ZONE = { Forest = "Thanos", Lake = "Darkseid", Desert = "Carnage", Jungle = "Shigaraki", Snow = "Frieza", Volcano = "Kaido" }

warn("[AreaEggService] MODULE LOADED -- if you see this, the server-side piece is running.")

local AreaEggService = {}

local records = {} -- uid -> AreaEggRecord
local nestOccupant = {} -- "AreaId:NestId" -> uid
local carryByPlayer = {} -- Player -> uid
local nightTeleportUntil = {} -- Player -> os.clock() deadline: being sent home by the night reset, no new steals
local version = 0

-- Carrier rules (owner 2026-09-24, Gekko TO DO 3): the carry is mirrored on the player as the attribute
-- CarryingEgg (true while carrying) so the systems that must refuse carriers read it without requiring this
-- module: GearService (no tools / bat swings while carrying), TreadmillGrindService (no training), EggService
-- (no egg tool) and the client backpack (no equip). Every write to carryByPlayer goes through setCarry.
local CARRY_ATTRIBUTE = "CarryingEgg"
local function setCarry(player, uid)
	carryByPlayer[player] = uid
	player:SetAttribute(CARRY_ATTRIBUTE, uid ~= nil)
end

-- Whoever loses an egg (bat hit, trap, villain catch or their own drop) cannot grab THAT egg again for
-- REPICK_LOCK_SECONDS; everyone else can pick it up at once. Per player + egg: another player's pickup and drop of
-- the same egg never lifts (or replaces) an earlier dropper's lock. Expired locks are pruned on every new lock.
local REPICK_LOCK_SECONDS = 3
local repickLock = {} -- egg uid -> { [UserId] = os.clock() deadline }
local function lockRepick(player, uid)
	if type(uid) ~= "string" then
		return
	end
	local now = os.clock()
	for lockedUid, locks in pairs(repickLock) do
		for userId, deadline in pairs(locks) do
			if deadline <= now then
				locks[userId] = nil
			end
		end
		if next(locks) == nil then
			repickLock[lockedUid] = nil
		end
	end
	local locks = repickLock[uid] or {}
	locks[player.UserId] = now + REPICK_LOCK_SECONDS
	repickLock[uid] = locks
end
local function isRepickLocked(player, uid)
	local locks = repickLock[uid]
	local deadline = locks and locks[player.UserId]
	return deadline ~= nil and os.clock() < deadline
end



local zoneModel = {} -- AreaId -> Model
local zoneNests = {} -- AreaId -> array<Model> (sorted, index+1 = Slot number)

for _, name in ipairs(ZONE_NAMES) do
	local model = GuardAreasFolder:FindFirstChild(name)
	if model then
		zoneModel[name] = model
		local ok, nests = pcall(AreaEggSlotIdentity.GetSortedNests, model)
		if ok then
			zoneNests[name] = nests
		else
			warn("[AreaEggService] Failed to read nests for " .. name .. ": " .. tostring(nests))
		end
	end
end

local zoneSlots = {} -- AreaId -> array<{ Nest: Model, NestId: string, Hidden: boolean }> (every EggSpot nest)
local zoneSlotById = {} -- AreaId -> NestId -> slot
for _, name in ipairs(ZONE_NAMES) do
	local model, nests = zoneModel[name], zoneNests[name]
	if model and nests then
		local slots, byId = {}, {}
		for _, nestModel in ipairs(nests) do
			local ok, nestId = pcall(AreaEggSlotIdentity.GetNestId, model, nestModel)
			if ok then
				local slot = { Nest = nestModel, NestId = nestId, Hidden = nestModel:GetAttribute("Hidden") == true }
				table.insert(slots, slot)
				byId[nestId] = slot
			else
				warn("[AreaEggService] GetNestId failed for " .. name .. ": " .. tostring(nestId))
			end
		end
		zoneSlots[name] = slots
		zoneSlotById[name] = byId
	end
end

local function nestKey(areaId, nestId)
	return areaId .. ":" .. nestId
end

-- How many eggs `areaId` keeps alive at once: its ActiveEggCount attribute (written by the build), else
-- the table above, never more than the stage has nests.
local function getActiveEggTarget(areaId)
	local slots = zoneSlots[areaId]
	if not slots or #slots == 0 then
		return 0
	end
	local zone = zoneModel[areaId]
	local configured = zone and zone:GetAttribute("ActiveEggCount")
	if type(configured) ~= "number" or configured < 1 then
		configured = ACTIVE_EGGS_BY_ZONE[areaId] or DEFAULT_ACTIVE_EGGS
	end
	return math.min(math.floor(configured), #slots)
end

-- The stage's name as players know it (area config DisplayName), for messages.
local function getStageDisplayName(areaId)
	local ok, area = pcall(function()
		return Areas.Directory[areaId]
	end)
	local displayName = ok and type(area) == "table" and area.DisplayName
	if type(displayName) == "string" and displayName ~= "" then
		return displayName
	end
	return areaId
end

local function weightedPick(dropTable)
	local total = 0
	for _, entry in ipairs(dropTable) do
		total += entry[2]
	end
	local roll = math.random() * total
	local acc = 0
	for _, entry in ipairs(dropTable) do
		acc += entry[2]
		if roll <= acc then
			return entry[1]
		end
	end
	return dropTable[#dropTable][1]
end

local function getRarityNumber(category)
	local ok, number = pcall(function()
		local config = Assets.Directory[category]
		return config and config.Rarity and config.Rarity.RarityNumber
	end)
	return if ok and type(number) == "number" then number else 0
end

-- NOTE: this used to also roll a separate invented "5% chance -> rare creature x3 scale"
-- on top of this. Removed: EggItemUtil.BuildSavedEgg (called below, same as every other egg
-- source in the game) ALREADY rolls AssetScale from a real weighted table
-- (WeightedScaleRollUtil + the 11-tier list in EggItemUtil) that goes from ~0.1x (diminuto) all
-- the way to ~35x (colosal, ~1 in 25 million), with ~80% landing near 1x -- the exact "a veces
-- pequeño, un poco mas grande, normal, un poquitin mas, uno gigante" gradient the user remembers
-- from the real game. The invented bolt-on was redundant with (and inconsistent alongside) a
-- system that was already real and already being called.
-- `minRarityNumber` (optional) restricts the roll to the stage's heroes of that rarity or better; when the
-- stage has none, the normal roll is used.
local function pickCategoryFor(areaId, minRarityNumber)
	local area = Areas.Directory[areaId]
	if area and area.DropTable and #area.DropTable > 0 then
		if minRarityNumber then
			local rare = {}
			for _, entry in ipairs(area.DropTable) do
				if entry[2] > 0 and getRarityNumber(entry[1]) >= minRarityNumber then
					table.insert(rare, entry)
				end
			end
			if #rare > 0 then
				return weightedPick(rare)
			end
		end
		return weightedPick(area.DropTable)
	end
	-- D1: no fallback creature exists any more (the legacy animals were purged); a stage without a drop table
	-- simply spawns no egg.
	return nil
end

-- BUG FIX (user report: "el nest donde tiene que estar el huevo es muchisimo mas enorme que el
-- huevo"): the NestScale formula below (session-10 fix, still correct as far as it goes) reuses
-- the EXACT SAME visual-scale multiplier the creature itself renders at
-- (EggScaleUtil.GetPreGrowthVisualScale(1, AssetScale, category)) and applies it to the Nest
-- prop. Verified live in Studio: every "NestModel" is ~5.6 studs wide at Scale=1 regardless of
-- area, while creature templates (ReplicatedStorage.Assets.Models.Eggs) range from well under 1
-- stud (Chicken: ~0.7) to several studs (Mammoth: ~5.2) at that SAME Scale=1 baseline. Reusing
-- one multiplier on two objects with wildly different base sizes doesn't make them match -- it
-- preserves whatever disproportion already existed at 1x (nest ~8x wider than a baseline
-- Chicken) and, for high-tier creatures pushing the multiplier toward its 8x cap, balloons that
-- into a ~45-stud slab. Confirmed with the real EggScaleUtil formula across AssetScale 1-35 for
-- Chicken/Mammoth/Cyclops Gorilla before writing this fix.
-- Fix: derive NestScale from the CREATURE's actual rendered footprint (same template + same
-- formula EggRenderer.RenderVisual uses client-side) divided by the Nest model's own true
-- unscaled footprint, so the nest is sized to actually frame whatever is currently sitting in
-- it instead of drifting independently. The nest's true unscaled size is recovered as
-- currentSize/currentScale rather than assumed -- ScaleTo is the only thing that ever touches
-- this shared, reused-in-place map instance's size, so that division is safe even across
-- however many previous eggs/sessions already scaled it.
local EggTemplatesFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("Eggs")
local NEST_TO_EGG_FOOTPRINT_RATIO = 1.2
local MIN_NEST_SCALE = 0.15
local MAX_NEST_SCALE = 3.0

local function resolveNestScale(nestModel, category, assetScale)
	local eggVisualScale = EggScaleUtil.GetPreGrowthVisualScale(1, assetScale or 1, category)

	local ok, result = pcall(function()
		local template = EggTemplatesFolder:FindFirstChild(category)
		if not template then
			return nil
		end

		local currentNestScale = nestModel:GetScale()
		local _, nestCurrentSize = nestModel:GetBoundingBox()
		local nestBaseSize = nestCurrentSize / currentNestScale
		local nestBaseFootprint = math.max(nestBaseSize.X, nestBaseSize.Z)

		if nestBaseFootprint <= 0 then
			return nil
		end

		local _, templateSize = template:GetBoundingBox()
		local eggFootprint = math.max(templateSize.X, templateSize.Z) * eggVisualScale

		return math.clamp((eggFootprint * NEST_TO_EGG_FOOTPRINT_RATIO) / nestBaseFootprint, MIN_NEST_SCALE, MAX_NEST_SCALE)
	end)

	if ok and result then
		return result
	end

	-- Fall back to the old (still not-wrong, just not-footprint-aware) behavior if anything
	-- above didn't resolve (missing template, zero-size nest, etc.) rather than erroring the
	-- whole spawn.
	return eggVisualScale
end

local attemptCarry -- forward-declared, assigned further down
local returnGuardToPost -- forward-declared, assigned with the villain chase hooks further down
-- Night teleport (owner 2026-09-23), assigned next to the carry helpers further down; the night watcher calls them.
local warnPlayersOutsideForNight
local prepareNightTeleports
local runNightTeleports

-- Every egg of Secret rarity or better (RarityNumber >= 8, e.g. JoyBoy in One Piece; future secrets included) is
-- announced to the whole server the moment it spawns: initial stock, respawns after a claim and the night reset.
local SECRET_ANNOUNCE_MIN_RARITY_NUMBER = 8

local function announceSecretSpawn(record)
	if SecretHeroSpawnedRemote == nil or getRarityNumber(record.AssetCategory) < SECRET_ANNOUNCE_MIN_RARITY_NUMBER then
		return
	end
	local config = Assets.Directory[record.AssetCategory]
	local rarity = config and config.Rarity
	local heroName = (config and type(config.DisplayName) == "string" and config.DisplayName ~= "" and config.DisplayName)
		or record.AssetCategory
	local stageName = getStageDisplayName(record.AreaId)
	local rarityName = (rarity and type(rarity.DisplayName) == "string" and rarity.DisplayName) or (rarity and rarity._id) or "Secret"
	local ok, err = pcall(function()
		SecretHeroSpawnedRemote:FireAllClients({
			EggUid = record.Uid,
			HeroId = record.AssetCategory,
			HeroName = heroName,
			StageName = stageName,
			AreaId = record.AreaId,
			RarityName = rarityName,
			Message = string.format("A %s HERO, %s HAS SPAWNED IN %s!", string.upper(rarityName), string.upper(heroName),
				string.upper(stageName)),
		})
	end)
	if not ok then
		warn("[AreaEggService] secret spawn broadcast failed: " .. tostring(err))
	end
end

-- `minRarityNumber` (optional): roll only the stage's heroes of that rarity or better (see topUpZone).
function AreaEggService.SpawnIntoNest(areaId, nestModel, nestId, minRarityNumber)
	-- Never two eggs in one nest.
	local occupant = nestOccupant[nestKey(areaId, nestId)]
	if occupant ~= nil and records[occupant] ~= nil then
		return nil
	end

	local category = pickCategoryFor(areaId, minRarityNumber)
	if category == nil then
		return
	end
	local ok, egg = pcall(EggItemUtil.BuildSavedEgg, category)
	if not ok then
		warn("[AreaEggService] BuildSavedEgg failed for " .. tostring(category) .. ": " .. tostring(egg))
		return
	end

	local zone = zoneModel[areaId]
	local bounds = zone and zone:FindFirstChild("Bounds")
	local eggSpotBottom = nestModel:FindFirstChild("EggSpotBottom", true)

	local nestBottomCFrame = (eggSpotBottom and eggSpotBottom.CFrame) or CFrame.new()
	local nestBoundsCFrame = (bounds and bounds.CFrame) or CFrame.new()

	version += 1
	local uid = EggService.NewUid("AreaEgg")
	local record = {
		Uid = uid,
		AreaId = areaId,
		NestId = nestId,
		AssetCategory = egg.AssetCategory,
		AssetScale = egg.AssetScale,
		AssetEyeColor = egg.AssetEyeColor,
		AssetColorSeed = egg.AssetColorSeed,
		AssetColorIndex = egg.AssetColorIndex,
		Mutations = egg.Mutations or {},
		BaseMutation = egg.BaseMutation,
		-- The nest tracks the egg's visual size -- see resolveNestScale() above for why this is
		-- no longer just the egg's raw visual-scale multiplier reused on the nest prop.
		NestScale = resolveNestScale(nestModel, egg.AssetCategory, egg.AssetScale),
		BottomCFrame = nestBottomCFrame,
		BoundsCFrame = nestBoundsCFrame,
		BoundsSize = (bounds and bounds.Size) or Vector3.new(0, 0, 0),
		-- Home pose: a drop moves BottomCFrame/BoundsCFrame to the drop spot, and returnToNest
		-- restores them from here (attemptCarry measures the steal distance from BottomCFrame).
		-- Extra fields are fine for clients: the AreaEggRecord schema is a non-strict t.interface.
		NestBottomCFrame = nestBottomCFrame,
		NestBoundsCFrame = nestBoundsCFrame,
		-- "Slot" (not "Dropped"!) is the state the client's AreaEggs.lua actually spawns a fresh
		-- visual for when no prior model exists (renderSlot -> renderClientEgg fallback).
		-- "Dropped" only re-binds a model that's ALREADY parented in Workspace (mid-carry drop);
		-- for a never-before-rendered nest egg it silently does nothing. This was the exact bug
		-- behind "no salen los huevos en los Nest".
		State = "Slot",
		CarrierUserId = nil,
		DroppedAt = os.time(),
		Version = version,
	}

	records[uid] = record
	nestOccupant[nestKey(areaId, nestId)] = uid
	AreaEggUpdatedRemote:FireAllClients(record)
	announceSecretSpawn(record)

	return record
end

-- Every live egg of a stage (in its nest, carried or lying dropped) counts toward the stage's active
-- eggs and keeps its home nest reserved, so a carried/dropped egg can still go back there (returnToNest).
-- Also returns how many of them sit on Hidden nests and how many are Epic or better (rotation rules).
local function getZoneEggState(areaId)
	local count, reserved, hidden, epic = 0, {}, 0, 0
	local slotsById = zoneSlotById[areaId] or {}
	for _, record in pairs(records) do
		if record.AreaId == areaId then
			count += 1
			reserved[record.NestId] = true
			local slot = slotsById[record.NestId]
			if slot and slot.Hidden then
				hidden += 1
			end
			if getRarityNumber(record.AssetCategory) >= EPIC_RARITY_NUMBER then
				epic += 1
			end
		end
	end
	return count, reserved, hidden, epic
end

-- A random free nest of the stage (only Hidden ones when `hiddenOnly`). Nests in `avoid` (a set of NestIds,
-- e.g. where the eggs sat last cycle) are only used when no other nest is free, so eggs move to new spots.
local function pickFreeSlot(areaId, reserved, avoid, hiddenOnly)
	local preferred, fallback = {}, {}
	for _, slot in ipairs(zoneSlots[areaId] or {}) do
		if not reserved[slot.NestId] and (not hiddenOnly or slot.Hidden) then
			if avoid and avoid[slot.NestId] then
				table.insert(fallback, slot)
			else
				table.insert(preferred, slot)
			end
		end
	end
	local pool = if #preferred > 0 then preferred else fallback
	if #pool == 0 then
		return nil
	end
	return pool[math.random(1, #pool)]
end

-- Spawns eggs into random free nests of `areaId` until the stage is back to its active egg count (or
-- `maxSpawns` eggs were added). Returns the new records. Keeps the plan's rotation rules when possible: at
-- least MIN_HIDDEN_ACTIVE_EGGS eggs on Hidden spots and one Epic-or-better egg in the stage.
local function topUpZone(areaId, avoid, maxSpawns)
	local spawned = {}
	local target = getActiveEggTarget(areaId)
	local count, reserved, hidden, epic = getZoneEggState(areaId)
	local hiddenSlots = 0
	for _, slot in ipairs(zoneSlots[areaId] or {}) do
		if slot.Hidden then
			hiddenSlots += 1
		end
	end
	local wantHidden = math.min(MIN_HIDDEN_ACTIVE_EGGS, hiddenSlots, target)
	local failures = 0
	while count < target and (maxSpawns == nil or #spawned < maxSpawns) and failures < 3 do
		local slot = (hidden < wantHidden and pickFreeSlot(areaId, reserved, avoid, true)) or pickFreeSlot(areaId, reserved, avoid)
		if not slot then
			break
		end
		reserved[slot.NestId] = true
		local minRarity = if epic == 0 then EPIC_RARITY_NUMBER else nil
		local ok, record = pcall(AreaEggService.SpawnIntoNest, areaId, slot.Nest, slot.NestId, minRarity)
		if ok and record then
			count += 1
			if slot.Hidden then
				hidden += 1
			end
			if getRarityNumber(record.AssetCategory) >= EPIC_RARITY_NUMBER then
				epic += 1
			end
			table.insert(spawned, record)
		else
			failures += 1
			if not ok then
				warn("[AreaEggService] Spawn failed for " .. areaId .. "/" .. tostring(slot.NestId) .. ": " .. tostring(record))
			end
		end
	end
	return spawned
end

-- A claimed (or retired) egg is replaced after RESPAWN_DELAY_SECONDS by one new egg on a random free
-- nest, preferably not the one it just left.
local function scheduleRespawn(areaId, vacatedNestId)
	task.delay(RESPAWN_DELAY_SECONDS, function()
		topUpZone(areaId, if vacatedNestId then { [vacatedNestId] = true } else nil, 1)
	end)
end

local function clearNestOccupant(uid)
	local record = records[uid]
	if not record then
		return
	end
	local key = nestKey(record.AreaId, record.NestId)
	if nestOccupant[key] == uid then
		nestOccupant[key] = nil
	end
end

-- A carried egg is successfully brought to safety: hand it to the player as a normal
-- (unplaced) personal egg -- from here on the existing EggService place/grow/hatch loop
-- takes over, exactly matching "si coges el huevo lo puedes poner en tu plot".
-- Only call through claimAreaEgg below, which keeps one claim per egg in flight.
local function grantAreaEggClaim(player, record)
	if not player or not record or not records[record.Uid] then
		return false
	end

	local profile = Database.Get(player) or Database.WaitForProfile(player, 5)
	if not profile then
		warn("[AreaEggService] Refused to consume stolen egg " .. tostring(record.Uid) .. " because profile is not loaded for " .. player.Name)
		return false
	end
	-- WaitForProfile can yield: the carry may have ended meanwhile (death/leave returned the egg
	-- to its nest, a drop, a guard catch). Granting it then would duplicate the egg.
	if records[record.Uid] ~= record or carryByPlayer[player] ~= record.Uid
		or record.State ~= "Carried" or record.CarrierUserId ~= player.UserId then
		return false
	end

	profile.EggInventory = profile.EggInventory or {}
	local egg = {
		AssetCategory = record.AssetCategory,
		AssetScale = record.AssetScale,
		AssetEyeColor = record.AssetEyeColor,
		AssetColorSeed = record.AssetColorSeed,
		AssetColorIndex = record.AssetColorIndex,
		Mutations = record.Mutations,
		BaseMutation = record.BaseMutation,
		IsStolenDNA = true,
	}
	local uid = EggService.NewUid("Egg")
	profile.EggInventory[uid] = egg

	local config = Assets.Directory[record.AssetCategory]
	local rarity = config and config.Rarity
	local rarityId = (rarity and rarity._id) or "Common"

	-- ECON 2026-09-24: the whole money economy /125 (AssetGenerationUtil.MONEY_SCALE), whole dollars
	-- (was 150 / 250 / 400 / 800 / 1800 / 3500 / 7500 / 12000 / 25000).
	local BOUNTY_BY_RARITY = {
		Common = 1,
		Uncommon = 2,
		Rare = 3,
		Epic = 6,
		Legendary = 14,
		Mythic = 28,
		Secret = 60,
		Eternal = 100,
		Divine = 200,
	}
	local cashBounty = BOUNTY_BY_RARITY[rarityId] or 1
	profile.Money = (profile.Money or 0) + cashBounty

	local okSet, setErr = pcall(Database.SetAndBroadcast, player, {
		EggInventory = profile.EggInventory,
		Money = profile.Money,
	})
	if not okSet then
		profile.EggInventory[uid] = nil
		profile.Money = profile.Money - cashBounty
		warn("[AreaEggService] Failed to add stolen egg/bounty to inventory for " .. player.Name .. ": " .. tostring(setErr))
		return false
	end

	-- End the carry and tell the client BEFORE granting the real egg Tool: the client destroys its
	-- client-only "CarriedEgg" hand Tool on these events. Granting first left two Tools equipped for a
	-- moment, and destroying CarriedEgg then cleared the player's equipped-tool slot, so the new egg
	-- could not be placed until it was re-selected (user report).
	setCarry(player, nil)
	records[record.Uid] = nil
	AreaEggRemovedRemote:FireAllClients(record.Uid)

	-- BUG FIX (user report: al llegar a la safe zone "me sigue saliendo el drop run y lo rojo
	-- de fondo" -- the tense run-back screen effects/music never turn off after a successful
	-- claim). Root cause: this function is the ONE place every successful claim funnels through
	-- (instant non-Forest pickup AND the new Forest safe-zone deposit), but it never told the
	-- client the carry ended -- only AreaEggRemovedRemote fired. AreaEggs.lua's own carried-egg
	-- hand visual already has a documented workaround listening to AreaEggRemoved for exactly
	-- this reason, but CarryRunBackEffects.lua (the red vignette/music) ONLY listens to
	-- AreaEggCarryStateChanged and has no such fallback -- it just never finds out. Every other
	-- carry-ending path (drop, guard catch) already fires this; claiming was the one gap.
	AreaEggCarryStateRemote:FireClient(player, {
		IsCarrying = false,
		SpeedMultiplier = 1
	})

	local okTool, EggServiceForTool = pcall(require, game.ServerScriptService.Controllers.EggService)
	if okTool and EggServiceForTool.GrantEggTool then
		local okGrant, granted = pcall(EggServiceForTool.GrantEggTool, player, uid, egg)
		if not okGrant or granted ~= true then
			warn("[AreaEggService] Failed to create stolen egg tool for " .. player.Name .. ": " .. tostring(granted))
		end
	end
	print("[AreaEggService] Claimed stolen egg " .. uid .. " for " .. player.Name)

	local config = Assets.Directory[record.AssetCategory]
	AreaEggClaimFeedbackRemote:FireClient(player, {
		AssetCategory = record.AssetCategory,
		DisplayName = (config and config.DisplayName) or record.AssetCategory,
		Rarity = (config and config.Rarity and config.Rarity._id) or "Common",
		Color = (config and config.Rarity and config.Rarity.Color) or Color3.new(1, 1, 1),
		Position = record.BottomCFrame.Position,
	})

	-- The stage stays at its active egg count: a new egg appears on another free spot.
	scheduleRespawn(record.AreaId, record.NestId)

	if returnGuardToPost then
		returnGuardToPost(record.AreaId, false)
	end
	return true
end

-- The claim poll and ForestDeposit can both claim the same carry, and grantAreaEggClaim can yield
-- (profile wait, inventory save): a second claim while the first is in flight would pay twice.
local claimInFlight = {} -- egg uid -> true
local function claimAreaEgg(player, record)
	if type(record) ~= "table" or record.Uid == nil or claimInFlight[record.Uid] then
		return false
	end
	local claimUid = record.Uid
	claimInFlight[claimUid] = true
	local ok, result = pcall(grantAreaEggClaim, player, record)
	claimInFlight[claimUid] = nil
	if not ok then
		warn("[AreaEggService] Claim of " .. tostring(claimUid) .. " failed: " .. tostring(result))
		return false
	end
	return result
end

local function returnToNest(record, reason)
	if records[record.Uid] ~= record then
		return false
	end
	-- The night reset refills empty nests, including the nest of an egg that was out being carried
	-- or lying Dropped. Never stack two eggs in one nest: retire the returning egg instead.
	local key = nestKey(record.AreaId, record.NestId)
	local occupant = nestOccupant[key]
	if occupant ~= nil and occupant ~= record.Uid and records[occupant] ~= nil then
		records[record.Uid] = nil
		AreaEggRemovedRemote:FireAllClients(record.Uid)
		scheduleRespawn(record.AreaId, record.NestId) -- keeps the stage at its active egg count
		return false
	end

	version += 1
	record.State = "Slot" -- back in its home nest slot, same as a fresh spawn (see SpawnIntoNest)
	-- Back to the nest pose: clients render Slot eggs at the nest, and attemptCarry's proximity
	-- check must measure from there, not from where the egg was last dropped.
	record.BottomCFrame = record.NestBottomCFrame or record.BottomCFrame
	record.BoundsCFrame = record.NestBoundsCFrame or record.BoundsCFrame
	record.CarrierUserId = nil
	record.DroppedAt = os.time()
	record.Version = version
	nestOccupant[key] = record.Uid
	AreaEggUpdatedRemote:FireAllClients(record)
	return true
end

-- Initial population: each stage gets its active eggs on random nests (small stagger so we're not
-- building every creature config in a single frame; 0.05s/egg, ~2s for all six stages) so
-- "no aparecen los huevos" reports aren't just someone checking before the stagger finishes.
do
	local delayIndex = 0
	local finished = 0
	local spawnedCount = 0
	local totalEggs = 0
	local totalNests = 0
	local totalZones = 0
	for _, areaId in ipairs(ZONE_NAMES) do
		local target = getActiveEggTarget(areaId)
		if target > 0 then
			totalEggs += target
			totalNests += #zoneSlots[areaId]
			totalZones += 1
		end
	end
	for _, areaId in ipairs(ZONE_NAMES) do
		for _ = 1, getActiveEggTarget(areaId) do
			delayIndex += 1
			task.delay(delayIndex * 0.05, function()
				spawnedCount += #topUpZone(areaId, nil, 1)
				finished += 1
				if finished == totalEggs then
					warn(string.format("[AreaEggService] Initial population done: %d/%d eggs on %d nests across %d stages.", spawnedCount, totalEggs, totalNests, totalZones))
				end
			end)
		end
	end
end

-- FEATURE (user report: "los huevos se suponen que se tienen que resetear" + the "Night"
-- countdown wall/UI only ever showing once per session at best): confirmed nothing server-side
-- ever fired "Eggs: AreaEggResetStartCountdown" -- the remote the client's ResetStartTimer.lua
-- (wall reveal, 3-2-1 countdown, "ALL EGG RESET!") is entirely built to react to. The client
-- only self-triggers it ONCE, at script load, IF the player happens to join mid-night
-- (AreaEggResetTimeUtil.IsNight is a pure/deterministic function of Workspace:GetServerTimeNow()
-- -- no server round-trip needed to know "is it night", confirmed reading it in full). But
-- nothing ever re-fires for a night that starts WHILE a player is already in the game, and
-- nothing ever actually resets the wild nest eggs either -- the whole night/day cycle was
-- visual-only for whoever happened to load in at the right second, with zero gameplay effect.
-- Fix: a lightweight poll loop that (a) broadcasts the same countdown payload the client
-- already knows how to render whenever a new night starts, so it repeats every cycle for
-- everyone, and (b) actually respawns the wild nests once each day begins, skipping any egg
-- currently Carried/Dropped so a night reset can never yank an egg out from mid-heist.

-- FEATURE (user request: "puede tocar secret egg un eternal lunar dragon egg... dime que
-- porcentaje hay de cada uno y cuando toca aparece el mensaje en gui justo cuando sale el 3 2 1,
-- por ejemplo 'Eternal Lunar Dragon egg spawned in volcano'"). This whole announcement pipeline
-- was ALREADY fully built client-side (ResetStartTimer.lua's requestJoinRareSpawnPresentations
-- polls Eggs: RequestAreaEggRareSpawnPresentations until ready, then announceRareSpawns shows a
-- top notification + chat message per entry, timed to when the countdown actually completes --
-- confirmed by reading it) but the server-side handler for that remote was FAIL/stub-answering
-- "ready, none pending" always (same EggService.lua fallback pattern as RequestAreaEggSnapshot),
-- so nothing was ever announced regardless of what spawned. The odds come from each stage's
-- Areas.Directory[stage].DropTable (the same weights pickCategoryFor rolls from below);
-- RARE_SPAWN_MIN_RARITY_NUMBER=8 (Secret and above) announces only the rare tail, e.g. One Piece's
-- Secret hero.
local RARE_SPAWN_MIN_RARITY_NUMBER = 8
local lastRareSpawnPresentations = {}

-- Day start: every resting (Slot) egg leaves and the stage is refilled on random nests, preferring the
-- ones that were empty, so the eggs move around. Carried/Dropped eggs are never yanked mid-heist: they
-- keep counting toward the stage's active eggs and keep their home nest.
local function resetAllNests()
	local rareSpawns = {}

	for _, areaId in ipairs(ZONE_NAMES) do
		if zoneSlots[areaId] then
			local previousNests = {}
			local resting = {}
			for uid, record in pairs(records) do
				if record.AreaId == areaId and record.State == "Slot" then
					table.insert(resting, uid)
				end
			end
			for _, uid in ipairs(resting) do
				local record = records[uid]
				local key = nestKey(record.AreaId, record.NestId)
				previousNests[record.NestId] = true
				records[uid] = nil
				if nestOccupant[key] == uid then
					nestOccupant[key] = nil
				end
				AreaEggRemovedRemote:FireAllClients(uid)
			end

			for _, newRecord in ipairs(topUpZone(areaId, previousNests)) do
				local config = Assets.Directory[newRecord.AssetCategory]
				local rarity = config and config.Rarity
				if rarity and type(rarity.RarityNumber) == "number" and rarity.RarityNumber >= RARE_SPAWN_MIN_RARITY_NUMBER then
					local displayName = (config.DisplayName and config.DisplayName ~= "" and config.DisplayName) or newRecord.AssetCategory
					table.insert(rareSpawns, {
						EggUid = newRecord.Uid,
						Message = displayName .. " egg spawned in " .. getStageDisplayName(areaId) .. "!",
						RarityId = rarity._id or "Secret",
					})
				end
			end
		end
	end

	-- The live SecretHeroSpawned broadcast (announceSecretSpawn, fired by SpawnIntoNest) now announces these the moment
	-- they spawn, so the post-countdown pull list stays empty (it would show the same spawns a second time).
	lastRareSpawnPresentations = {}
	warn("[AreaEggService] Night reset: eggs moved to new hiding spots. Rare spawns: " .. #rareSpawns)
end

RequestAreaEggRareSpawnPresentationsRemote.OnServerInvoke = function(_player)
	return true, lastRareSpawnPresentations
end

task.spawn(function()
	local lastAnnouncedDayStartsAt = nil
	local lastResetDayStartsAt = nil

	while true do
		local ok, err = pcall(function()
			local now = Workspace:GetServerTimeNow()

			if AreaEggResetTimeUtil.IsNight(now) then
				local dayStartsAt = AreaEggResetTimeUtil.GetNextResetAt(now)

				if lastAnnouncedDayStartsAt ~= dayStartsAt then
					lastAnnouncedDayStartsAt = dayStartsAt
					-- DIAGNOSTIC (user report: "lo de la night no va, no aparece el bloque" --
					-- could not root-cause statically this session, the wiring reads correct
					-- end to end: this broadcast, EggCmds.handleAreaEggResetStartCountdown,
					-- ResetStartTimer.startSequence/runCountdown, AreaEggResetWall.Reveal. Left
					-- unable to playtest live again (MCP plugin loses its target connection
					-- during Play). Prints so next time this is confirmed to fire at all, and
					-- with what dayStartsAt/player count, instead of guessing blind a 4th time.
					print(("[AreaEggService] Night started, broadcasting AreaEggResetStartCountdown to %d player(s), dayStartsAt=%.1f (in %.1fs)")
						:format(#Players:GetPlayers(), dayStartsAt, dayStartsAt - now))
					AreaEggResetStartCountdownRemote:FireAllClients({
						DayStartsAt = dayStartsAt,
						RareSpawns = {}
					})
					-- Players out in the stages get a heads-up: whoever is still out when the night ends is sent home.
					if warnPlayersOutsideForNight then
						local okWarn, warnErr = pcall(warnPlayersOutsideForNight, dayStartsAt - now)
						if not okWarn then
							warn("[AreaEggService] Night warning failed: " .. tostring(warnErr))
						end
					end
				end
			elseif lastAnnouncedDayStartsAt ~= nil and lastResetDayStartsAt ~= lastAnnouncedDayStartsAt and now >= lastAnnouncedDayStartsAt then
				lastResetDayStartsAt = lastAnnouncedDayStartsAt
				-- Night teleport (owner 2026-09-23: "Make Night tp you back to spawn"). The carries of the players still
				-- out in the stages end and loose eggs go home FIRST, so the reset below reshuffles them like every other
				-- resting egg (nothing lost, nothing granted twice); then the stages refill; then the players are moved.
				local homeBound = nil
				if prepareNightTeleports then
					local okPrep, prepared = pcall(prepareNightTeleports)
					if okPrep then
						homeBound = prepared
					else
						warn("[AreaEggService] Night teleport preparation failed: " .. tostring(prepared))
					end
				end
				local okReset, resetErr = pcall(resetAllNests)
				if not okReset then
					warn("[AreaEggService] Night reset failed: " .. tostring(resetErr))
				end
				if runNightTeleports and type(homeBound) == "table" then
					local okRun, runErr = pcall(runNightTeleports, homeBound)
					if not okRun then
						warn("[AreaEggService] Night teleport failed: " .. tostring(runErr))
					end
				end
			end
		end)

		if not ok then
			warn("[AreaEggService] Night cycle watcher error: " .. tostring(err))
		end

		task.wait(1)
	end
end)

RequestAreaEggSnapshotRemote.OnServerInvoke = function(_player)
	local list = {}
	for _, record in pairs(records) do
		table.insert(list, record)
	end
	return { Records = list, ServerTime = os.time() }
end

-- BUG FIX v2 (user report: first version claimed the egg the moment you left the SOURCE zone's
-- own bounds -- "cojo un huevo de la zona 2 y para tenerlo en mi inventario tengo que pasar por
-- la zona 1 y luego a la safe zone, ahi me lo da, pues esta mal, me lo da cuando llego a la
-- zona 1" -- since zones sit right next to each other, leaving zone 2 usually means walking
-- straight into zone 1's own bounds, which counted as "safe" even though zone 1 is still a wild
-- zone, not the actual safe hub). Fixed to require being outside ALL stage zones' Bounds at once,
-- not just the one the egg came from -- cached once at module load (every zone folder under
-- GuardAreasFolder has its own Bounds part, confirmed structurally identical to Forest's).
-- (Defined above attemptCarry, which validates the carry against isInSafeZone.)
local zoneBoundsParts = {}
for _, zoneName in ipairs(ZONE_NAMES) do
	local zoneModel = GuardAreasFolder:FindFirstChild(zoneName)
	local bounds = zoneModel and zoneModel:FindFirstChild("Bounds")
	if bounds then
		zoneBoundsParts[zoneName] = bounds
	end
end

local safeZonePart = Workspace:FindFirstChild("GameplayZ", true)
if safeZonePart and not safeZonePart:IsA("BasePart") then
	safeZonePart = nil
end

local function isInsideAnyZone(position)
	for _, bounds in pairs(zoneBoundsParts) do
		local relative = bounds.CFrame:PointToObjectSpace(position)
		local halfSize = bounds.Size * 0.5
		if math.abs(relative.X) <= halfSize.X and math.abs(relative.Z) <= halfSize.Z then
			return true
		end
	end
	return false
end

-- The hub (plots, shops, lobby) is the only safe zone (plan A5; the old DeliveryHitbox far outside the map no
-- longer counts).
local function isInSafeZone(position)
	-- Plots and lobby sit at X <= 75, outside all danger zones (Forest starts at X ~73.2)
	if position.X <= 75 then
		return true
	end
	if safeZonePart then
		local relative = safeZonePart.CFrame:PointToObjectSpace(position)
		local halfSize = safeZonePart.Size * 0.5
		if math.abs(relative.X) <= halfSize.X and math.abs(relative.Z) <= halfSize.Z then
			return true
		end
	end
	return false
end

local function getCharacterRoot(player)
	local character = player and player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return rootPart, character
	end
	return nil, character
end

local function isServerChaseZone(areaId)
	local zone = zoneModel[areaId]
	return zone ~= nil and zone:GetAttribute("ServerChase") == true
end

local function getVillainName(areaId)
	local zone = zoneModel[areaId]
	local guard = zone and zone:FindFirstChild("Guard")
	local name = guard and (guard:GetAttribute("VillainName") or guard:GetAttribute("HeroId"))
	if type(name) == "string" and name ~= "" then
		return name
	end
	return VILLAIN_BY_ZONE[areaId] or "The villain"
end

-- One chase per stage (plan A4): true only while the stage's villain is waking up for / chasing another
-- player who is still in the game. Another carrier alone does not lock the stage: once the villain gave up
-- on them (out of reach) and went back to its post, anyone may steal again (GuardChaseService.StartChase
-- sets Waking synchronously and its target selection arbitrates between several carriers).
local function isVillainHuntingOther(areaId, player)
	local zone = zoneModel[areaId]
	local guard = zone and zone:FindFirstChild("Guard")
	local state = guard and guard:GetAttribute("GuardState")
	if state == "Waking" or state == "Chasing" then
		local target = tonumber(guard:GetAttribute("TargetPlayer"))
		if target and target ~= 0 and target ~= player.UserId and Players:GetPlayerByUserId(target) ~= nil then
			return true
		end
	end
	return false
end

-- Bottom-of-screen message through the game's notification remote (NotificationCmds.Message), at most one
-- per second per player (the Steal prompt can be re-triggered quickly).
local lastNoticeAt = {} -- Player -> os.clock()
local function notifyPlayer(player, message)
	local now = os.clock()
	if lastNoticeAt[player] and now - lastNoticeAt[player] < 1 then
		return
	end
	lastNoticeAt[player] = now
	local remote = Network:FindFirstChild("Notifications_Show")
	if remote and remote:IsA("RemoteEvent") then
		pcall(function()
			remote:FireClient(player, "Message", "Bottom", {
				Time = 3,
				Message = message,
				Color = Color3.fromRGB(255, 96, 96),
			})
		end)
	end
end

-- Ends a carry bookkeeping-wise and tells the client (run-back FX, carried-egg hand visual).
local function clearCarry(player)
	setCarry(player, nil)
	if player.Parent ~= nil then
		pcall(function()
			AreaEggCarryStateRemote:FireClient(player, { IsCarrying = false, SpeedMultiplier = 1 })
		end)
	end
end

-- Where a dropped egg lands: on the floor under the carrier (R15 HRPs hover HipHeight above it).
local dropRaycastParams = RaycastParams.new()
dropRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
dropRaycastParams.RespectCanCollide = true

local function resolveDropCFrame(player, guardCFrame, record)
	local rootPart, character = getCharacterRoot(player)
	if rootPart then
		local _, yaw, _ = rootPart.CFrame:ToOrientation()
		local feet = rootPart.Position - Vector3.new(0, rootPart.Size.Y / 2, 0)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local legLength = if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then humanoid.HipHeight else 2
		dropRaycastParams.FilterDescendantsInstances = { character, GuardAreasFolder }
		local hit = Workspace:Raycast(rootPart.Position, Vector3.new(0, -(rootPart.Size.Y / 2 + legLength + 6), 0), dropRaycastParams)
		if hit then
			feet = Vector3.new(feet.X, hit.Position.Y, feet.Z)
		else
			feet -= Vector3.new(0, legLength, 0)
		end
		return CFrame.new(feet) * CFrame.Angles(0, yaw, 0)
	elseif typeof(guardCFrame) == "CFrame" then
		return guardCFrame
	end
	return record.BottomCFrame
end

-- The guard caught the carrying player. FEATURE (user request): previously this instantly
-- teleported the egg back to its nest ("returnToNest"), with no physical drop and no chance to
-- recover it. Now it DROPS at the player's position instead (State = "Dropped", matching the
-- schema's existing GuardHit DropReason and the client's already-working Dropped-state
-- rendering in AreaEggs.lua -- renderDropped just unwelds/repositions the model that's already
-- in the player's hand, confirmed by reading it). Anyone can pick a Dropped egg back up
-- (attemptCarry allows State == "Dropped"); the zone's server guard (GuardChaseService) walks
-- over and returns it to its nest, and the DROPPED_EGG_RETURN_SECONDS timer below is the backstop.
-- Shared by the server chase (onGuardCaughtPlayer) and the legacy client "Guards: ForestHit" path,
-- and by player gear (Bat / traps) through DropCarriedEggFrom below. `reason` is nil for guard
-- catches; gear drops pass their own reason so the guard-only speed-hit popups stay guard-only.
local function dropCarriedEgg(player, eggUid, guardCFrame, reason)
	if type(eggUid) ~= "string" or carryByPlayer[player] ~= eggUid then
		return nil
	end
	local record = records[eggUid]
	if not record then
		clearCarry(player)
		return nil
	end
	setCarry(player, nil)
	lockRepick(player, eggUid)

	local dropCFrame = resolveDropCFrame(player, guardCFrame, record)
	version += 1
	record.State = "Dropped"
	record.CarrierUserId = nil
	record.DroppedAt = os.time()
	record.BottomCFrame = dropCFrame
	record.BoundsCFrame = dropCFrame
	record.Version = version
	AreaEggUpdatedRemote:FireAllClients(record)
	AreaEggCarryStateRemote:FireClient(player, { IsCarrying = false, SpeedMultiplier = 1 })

	-- Guard caught you -- show the free warning always, and the paid speed-boost offer only if a
	-- real product exists to sell (see SPEED_HIT_OFFER_PRODUCT_ID above).
	if reason == nil or reason == "GuardHit" then
		local ok, err = pcall(function()
			SpeedHitWarningRemote:FireClient(player)
			if SPEED_HIT_OFFER_PRODUCT_ID then
				SpeedHitOfferRemote:FireClient(player, SPEED_HIT_OFFER_PRODUCT_ID, SPEED_HIT_OFFER_AMOUNT)
			end
		end)
		if not ok then
			warn("[AreaEggService] Failed firing SpeedHitWarning/SpeedHitOffer for " .. player.Name .. ": " .. tostring(err))
		end
	end

	local dropVersion = record.Version
	task.delay(DROPPED_EGG_RETURN_SECONDS, function()
		if records[record.Uid] == record and record.State == "Dropped" and record.Version == dropVersion then
			returnToNest(record, "DroppedTimeout")
		end
	end)

	return record
end

-- Guard retrieval finished (or timed out): put a still-Dropped egg back in its nest.
-- returnToNest retires the egg instead when its nest was refilled meanwhile.
local function returnDroppedEggToNest(uid)
	local record = type(uid) == "string" and records[uid]
	if not record or record.State ~= "Dropped" then
		return false
	end
	return returnToNest(record, "GuardRetrieved")
end

local function getCarriersForArea(areaId)
	local carriers = {}
	for player, uid in pairs(carryByPlayer) do
		local record = records[uid]
		if record and record.AreaId == areaId and record.State == "Carried" and record.CarrierUserId == player.UserId then
			table.insert(carriers, { Player = player, Uid = uid })
		end
	end
	return carriers
end

-- Villain chase hooks (contract C3); GuardChaseService does the movement, AreaEggService keeps the egg state.
local function startVillainChase(player, record, wasDropped)
	if not GuardChaseService or type(record) ~= "table" then
		return
	end
	local ok, err = pcall(GuardChaseService.StartChase, player, record, wasDropped == true)
	if not ok then
		warn("[AreaEggService] startVillainChase failed for " .. tostring(record.AreaId) .. ": " .. tostring(err))
	end
end

local function onGuardCaughtPlayer(player, eggUid, guardCFrame)
	return dropCarriedEgg(player, eggUid, guardCFrame)
end

returnGuardToPost = function(areaId, force)
	if not GuardChaseService or type(areaId) ~= "string" then
		return
	end
	local ok, err = pcall(GuardChaseService.ReturnToPost, areaId, force == true)
	if not ok then
		warn("[AreaEggService] returnGuardToPost failed for " .. areaId .. ": " .. tostring(err))
	end
end

-- Carrier died, respawned or left while carrying: the egg goes home (no "reset to bank").
local function endCarryAndReturn(player, reason)
	local uid = carryByPlayer[player]
	if not uid then
		return
	end
	local record = records[uid]
	clearCarry(player)
	if record and record.State == "Carried" and record.CarrierUserId == player.UserId then
		returnToNest(record, reason)
	end
	if record then
		returnGuardToPost(record.AreaId, false)
	end
end

-- Public: uid of the area egg `player` is actively carrying right now, or nil.
local function getCarriedEggUid(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return nil
	end
	local uid = carryByPlayer[player]
	if type(uid) ~= "string" then
		return nil
	end
	local record = records[uid]
	if not record or record.State ~= "Carried" or record.CarrierUserId ~= player.UserId then
		return nil
	end
	return uid
end

--------------------------------------------------------------------------------------------------
-- Night teleport (owner 2026-09-23: "Make Night tp you back to spawn")
--------------------------------------------------------------------------------------------------
-- When a night ends (the reset that moves the eggs), every living player still outside the hub safe zone
-- (isInSafeZone: X > 75, i.e. in a stage) is moved back to their plot's SpawnPoint (the same spot PlotService
-- spawns them on), or to the hub SpawnLocation when they have no plot. Their carry ends first through
-- endCarryAndReturn (egg back to its nest, run-back FX off), loose Dropped eggs go home, every villain is sent
-- back to its post, and they cannot start a new steal until they have been moved. The client
-- (StarterPlayerScripts.GUI.NightTeleportCue) fades to black while the character moves and shows a toast.
local NIGHT_TELEPORT_FADE_LEAD = 0.3 -- the client fades to black (0.2 s) before the character moves
local NIGHT_TELEPORT_PENDING_SECONDS = 8 -- steal lock backstop; cleared as soon as the player was moved
local NIGHT_RAGDOLL_WAIT_SECONDS = 3.2 -- GearService ragdolls last 1.75 s (3 s for a bat-hit carrier); GearReleaseRequest usually ends them at once
local NIGHT_RELEASE_WAIT_SECONDS = 0.5 -- max wait on the optional GearReleaseRequest bindable
local NIGHT_SPAWN_SCATTER = 4.5 -- studs of random offset, only on the shared hub SpawnLocation

local ServerScriptService = game:GetService("ServerScriptService")

local plotServiceModule = nil -- PlotService table, or false once it failed to load
local function getPlotSpawnPoint(player)
	if plotServiceModule == nil then
		plotServiceModule = false
		local controllers = ServerScriptService:FindFirstChild("Controllers")
		local module = controllers and controllers:FindFirstChild("PlotService")
		if module and module:IsA("ModuleScript") then
			local ok, result = pcall(require, module)
			if ok and type(result) == "table" then
				plotServiceModule = result
			else
				warn("[AreaEggService] PlotService unavailable for the night teleport: " .. tostring(result))
			end
		end
	end
	if not plotServiceModule or type(plotServiceModule.GetPlotId) ~= "function" then
		return nil
	end
	local ok, plotId = pcall(plotServiceModule.GetPlotId, player)
	if not ok or plotId == nil then
		return nil
	end
	local plots = Workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild(tostring(plotId))
	local spawnPoint = plot and plot:FindFirstChild("SpawnPoint")
	if spawnPoint and spawnPoint:IsA("BasePart") then
		return spawnPoint
	end
	return nil
end

local function getHubSpawnLocation()
	local spawn = Workspace:FindFirstChild("SpawnLocation")
	if spawn and spawn:IsA("SpawnLocation") then
		return spawn
	end
	return Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
end

local homeRaycastParams = RaycastParams.new()
homeRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
homeRaycastParams.RespectCanCollide = true

-- Root CFrame standing on the floor at the player's plot spawn (hub SpawnLocation + a small random offset when
-- they have no plot), facing the way the spawn point faces. Nil when the place has neither.
local function resolveNightHomeCFrame(player, rootPart, humanoid)
	local anchor, scatter = getPlotSpawnPoint(player), 0
	if anchor == nil then
		anchor = getHubSpawnLocation()
		if anchor then
			scatter = math.clamp(math.min(anchor.Size.X, anchor.Size.Z) / 2 - 1.5, 0, NIGHT_SPAWN_SCATTER)
		end
	end
	if anchor == nil then
		return nil
	end
	local _, yaw, _ = anchor.CFrame:ToOrientation()
	local angle, radius = math.random() * 2 * math.pi, math.sqrt(math.random()) * scatter
	local spot = anchor.Position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	local legs = if humanoid.RigType == Enum.HumanoidRigType.R15 then math.max(humanoid.HipHeight, 0.5) else 2
	local exclude = {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Character then
			table.insert(exclude, other.Character)
		end
	end
	homeRaycastParams.FilterDescendantsInstances = exclude
	local hit = Workspace:Raycast(spot + Vector3.new(0, 4, 0), Vector3.new(0, -24, 0), homeRaycastParams)
	-- No floor found: PlotService's own spawn rule (5 studs above the spawn point, the character drops onto it).
	local rootY = if hit then hit.Position.Y + legs + rootPart.Size.Y / 2 + 0.2 else anchor.Position.Y + 5
	return CFrame.new(spot.X, rootY, spot.Z) * CFrame.Angles(0, yaw, 0)
end

local function zeroCharacterVelocity(character)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function fireNightCue(player, payload)
	if NightTeleportRemote and player.Parent ~= nil then
		pcall(function()
			NightTeleportRemote:FireClient(player, payload)
		end)
	end
end

-- Trap freeze / bat ragdoll (GearService character attributes). GearService only exposes a ragdoll START
-- (GearRagdollRequest); when it also exposes ServerScriptService.GearReleaseRequest (BindableFunction,
-- player -> released) it is used to lift both. Otherwise a ragdoll is waited out (it ends by itself within 3 s)
-- and a trap freeze simply runs out at home (GearService restores the speed after its 7 s).
local function releaseGearHold(player, character)
	local trapped = character:GetAttribute("IsTrapped") == true
	local ragdolled = character:GetAttribute("Ragdolled") == true
	if not trapped and not ragdolled then
		return
	end
	local release = ServerScriptService:FindFirstChild("GearReleaseRequest")
	if release and release:IsA("BindableFunction") then
		-- Invoke yields until a handler exists: never let it hold the teleport.
		local done = false
		task.spawn(function()
			local ok, err = pcall(release.Invoke, release, player)
			if not ok then
				warn("[AreaEggService] GearReleaseRequest failed for " .. player.Name .. ": " .. tostring(err))
			end
			done = true
		end)
		local deadline = os.clock() + NIGHT_RELEASE_WAIT_SECONDS
		while not done and os.clock() < deadline do
			task.wait()
		end
	end
	local deadline = os.clock() + NIGHT_RAGDOLL_WAIT_SECONDS
	while character.Parent ~= nil and character:GetAttribute("Ragdolled") == true and os.clock() < deadline do
		task.wait(0.1)
	end
end

-- Night start: the players out in the stages learn that they are sent home when the night ends.
warnPlayersOutsideForNight = function(secondsLeft)
	for _, player in ipairs(Players:GetPlayers()) do
		local rootPart = getCharacterRoot(player)
		if rootPart and not isInSafeZone(rootPart.Position) then
			fireNightCue(player, {
				Phase = "Warning",
				SecondsLeft = math.max(1, math.floor((tonumber(secondsLeft) or 10) + 0.5)),
			})
		end
	end
end

-- Night reset, BEFORE the nests are reshuffled. Never yields. Returns the players to move.
prepareNightTeleports = function()
	local homeBound = {}
	local lockUntil = os.clock() + NIGHT_TELEPORT_PENDING_SECONDS
	for _, player in ipairs(Players:GetPlayers()) do
		local rootPart, character = getCharacterRoot(player)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if rootPart and humanoid and humanoid.Health > 0 and not isInSafeZone(rootPart.Position) then
			nightTeleportUntil[player] = lockUntil
			table.insert(homeBound, player)
			-- A claim already in flight (safe-zone arrival) finishes on its own; any other carry goes home.
			local uid = carryByPlayer[player]
			if uid ~= nil and not claimInFlight[uid] then
				endCarryAndReturn(player, "NightReset")
			end
		end
	end
	-- Loose eggs go home as well: nobody is left out there to pick them up, and the reset reshuffles them.
	local loose = {}
	for _, record in pairs(records) do
		if record.State == "Dropped" then
			table.insert(loose, record)
		end
	end
	for _, record in ipairs(loose) do
		returnToNest(record, "NightReset")
	end
	-- Every villain stops (chase, wake-up or retrieval) and goes back to its post for the new day.
	for _, areaId in ipairs(ZONE_NAMES) do
		returnGuardToPost(areaId, true)
	end
	return homeBound
end

local function sendPlayerHome(player)
	local _, character = getCharacterRoot(player)
	if not character then
		return
	end
	releaseGearHold(player, character)

	local rootPart, currentCharacter = getCharacterRoot(player)
	local humanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
	if player.Parent == nil or currentCharacter ~= character or not rootPart or not humanoid or humanoid.Health <= 0 then
		return -- left, died or respawned meanwhile (a respawn lands on the plot anyway)
	end
	if isInSafeZone(rootPart.Position) then
		return -- made it home on their own
	end
	local target = resolveNightHomeCFrame(player, rootPart, humanoid)
	if not target then
		warn("[AreaEggService] Night teleport: no plot SpawnPoint or SpawnLocation for " .. player.Name)
		return
	end

	fireNightCue(player, { Phase = "Teleport", Target = target.Position })
	task.wait(NIGHT_TELEPORT_FADE_LEAD)

	rootPart = getCharacterRoot(player)
	if player.Parent == nil or player.Character ~= character or not rootPart or humanoid.Health <= 0 then
		return
	end
	-- Belt and braces: a carry that slipped in since the reset goes home too, never to the plot.
	local uid = carryByPlayer[player]
	if uid ~= nil and not claimInFlight[uid] then
		endCarryAndReturn(player, "NightReset")
	end
	local seat = humanoid.SeatPart
	if seat then
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		humanoid.Sit = false
	end
	zeroCharacterVelocity(character)
	if character.PrimaryPart then
		character:PivotTo(target)
	else
		rootPart.CFrame = target
	end
	zeroCharacterVelocity(character)
end

-- Night reset, AFTER the nests were reshuffled: each player is moved on their own thread (a ragdoll wait
-- must not hold the others).
runNightTeleports = function(homeBound)
	local names = {}
	for _, player in ipairs(homeBound) do
		table.insert(names, player.Name)
		task.spawn(function()
			local ok, err = pcall(sendPlayerHome, player)
			nightTeleportUntil[player] = nil
			if not ok then
				warn("[AreaEggService] Night teleport failed for " .. player.Name .. ": " .. tostring(err))
			end
		end)
	end
	if #names > 0 then
		print(("[AreaEggService] Night reset: sending %d player(s) back to base (%s)."):format(#names, table.concat(names, ", ")))
	end
end

-- Public: another player's gear (Bat hit, Trap / SubspaceTrap) knocked the egg out of `player`'s
-- hands. Same drop path as a villain catch (dropCarriedEgg): the egg lands Dropped at their feet,
-- anyone can pick it up again, the DROPPED_EGG_RETURN_SECONDS timer sends it home. No-op (nil) for
-- non-carriers, dead or leaving players (the Died / PlayerRemoving hooks return their egg to the
-- nest) and carriers already in the safe zone (the claim loop banks it). Never yields; the carry is
-- cleared synchronously, so a second call for the same hit returns nil (no double drop).
local function dropCarriedEggFrom(player, sourceCFrame, reason)
	local uid = getCarriedEggUid(player)
	if not uid or player.Parent == nil then
		return nil
	end
	local rootPart, character = getCharacterRoot(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	if isInSafeZone(rootPart.Position) then
		return nil
	end
	local source = if typeof(sourceCFrame) == "CFrame" then sourceCFrame else nil
	local record = dropCarriedEgg(player, uid, source, if type(reason) == "string" then reason else "External")
	if record then
		returnGuardToPost(record.AreaId, false)
	end
	return record
end

attemptCarry = function(player, uid)
	if type(uid) ~= "string" then
		return false, "Invalid request"
	end
	if carryByPlayer[player] then
		return false, "Already carrying an egg"
	end
	-- Being sent home by the night reset: a fresh egg grabbed now would be carried home by the teleport.
	if (nightTeleportUntil[player] or 0) > os.clock() then
		return false, "Night reset"
	end
	local record = records[uid]
	-- "Dropped" (added alongside the guard-catch drop mechanic below) is an egg that fell
	-- outside the guard's zone when its previous carrier got caught -- per the user's spec
	-- ("si esta fuera de su zona lo puedes volver a coger"), anyone can pick it back up.
	if not record or (record.State ~= "Slot" and record.State ~= "Dropped") then
		return false, "Egg not available"
	end
	-- Carrier rules: the player who just lost this egg waits REPICK_LOCK_SECONDS; anyone else may take it.
	if isRepickLocked(player, uid) then
		notifyPlayer(player, "You just dropped this egg! Wait a moment.")
		return false, "Just dropped this egg"
	end

	-- The prompt only exists next to the egg; reject remote/safe-zone carries (instant-claim exploit).
	local rootPart, character = getCharacterRoot(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		return false, "No character"
	end
	-- GearService attributes: a trapped / bat-flung player just had their egg knocked loose and
	-- must not grab it straight back while frozen or mid-fling.
	if character:GetAttribute("IsTrapped") == true or character:GetAttribute("BatFlung") == true then
		return false, "Stunned"
	end
	if isInSafeZone(rootPart.Position) then
		return false, "Cannot steal from the safe zone"
	end
	local maxDistance = CARRY_MAX_DISTANCE * math.max(1, tonumber(record.NestScale) or 1)
	if (rootPart.Position - record.BottomCFrame.Position).Magnitude > maxDistance then
		return false, "Too far from the egg"
	end
	if isVillainHuntingOther(record.AreaId, player) then
		local message = getVillainName(record.AreaId) .. " is already hunting someone! Try again in a moment."
		notifyPlayer(player, message)
		return false, message
	end

	local wasDropped = record.State == "Dropped"
	version += 1
	record.State = "Carried"
	record.CarrierUserId = player.UserId
	record.Version = version
	clearNestOccupant(uid)
	setCarry(player, uid)

	AreaEggUpdatedRemote:FireAllClients(record)
	AreaEggCarryStateRemote:FireClient(player, {
		IsCarrying = true,
		Uid = record.Uid,
		AreaId = record.AreaId,
		AssetCategory = record.AssetCategory,
		RunBackWakeDelayRequired = false,
		SpeedMultiplier = 1,
	})

	startVillainChase(player, record, wasDropped)

	return true
end

RequestAreaEggCarryRemote.OnServerInvoke = function(player, args)
	if type(args) ~= "table" then
		return false, "Invalid request"
	end
	return attemptCarry(player, args.Uid)
end

-- Claims carried eggs when arriving at the safe zone / lobby / plots
task.spawn(function()
	while true do
		task.wait(0.5)
		-- Snapshot first: claimAreaEgg can yield (profile wait) while other threads start/end carries.
		local carries = {}
		for player, uid in pairs(carryByPlayer) do
			table.insert(carries, { player, uid })
		end
		for _, carry in ipairs(carries) do
			local player, uid = carry[1], carry[2]
			if carryByPlayer[player] == uid then
				local ok, err = pcall(function()
					local record = records[uid]
					if not record or record.State ~= "Carried" or record.CarrierUserId ~= player.UserId then
						-- Stale carry (record claimed/removed elsewhere): release it so the player can steal again.
						clearCarry(player)
					else
						local hrp = getCharacterRoot(player)
						if hrp and isInSafeZone(hrp.Position) then
							claimAreaEgg(player, record)
						end
					end
				end)
				if not ok then
					warn("[AreaEggService] Claim check failed for " .. player.Name .. ": " .. tostring(err))
				end
			end
		end
	end
end)

RequestAreaEggDropRemote.OnServerInvoke = function(player, _args)
	local uid = carryByPlayer[player]
	if not uid then
		return false, "Not carrying anything"
	end
	local record = records[uid]
	setCarry(player, nil)
	lockRepick(player, uid)
	if record then
		returnToNest(record, "PlayerRequest")
		returnGuardToPost(record.AreaId, false)
	end
	AreaEggCarryStateRemote:FireClient(player, { IsCarrying = false, SpeedMultiplier = 1 })
	return true
end

-- Legacy client-simulated catch (Forest/GenericGuardRuntime). Zones flagged ServerChase=true are
-- caught by GuardChaseService on the server, so client reports for them are ignored.
ForestHitRemote.OnServerEvent:Connect(function(player, args)
	if type(args) ~= "table" or type(args.EggUid) ~= "string" then
		return
	end
	local record = records[args.EggUid]
	if record and isServerChaseZone(record.AreaId) then
		return
	end
	dropCarriedEgg(player, args.EggUid, args.GuardCFrame)
end)

-- "Attached" = picked up in-hand client-side (informational, state already Carried).
-- "Deposited" has two distinct real senders sharing the same event/Kind (confirmed by reading
-- both): (1) the CARRYING player reaching the safe zone (ForestGuardRuntime's own safe-zone
-- watcher) -- claim it for them, but only when the server also sees them in the safe zone;
-- (2) the GUARD's client-simulated GuardEggRetrievalComponent finishing walking a DROPPED
-- (uncarried) egg back to its nest (_handleRetrievalEvent's "Deposited" branch) -- nobody is its
-- carrier at that point, so the claim branch below correctly no-ops for it; this returns it to
-- "Slot" server-side so it isn't stuck as "Dropped" forever. Server-chased zones retrieve dropped
-- eggs on the server (GuardChaseService), so that second branch is ignored for them.
ForestDepositRemote.OnServerEvent:Connect(function(player, args)
	if type(args) ~= "table" or type(args.EggUid) ~= "string" then
		return
	end
	if args.Kind == "Attached" then
		return
	end
	if carryByPlayer[player] == args.EggUid then
		local record = records[args.EggUid]
		if not record then
			clearCarry(player)
			return
		end
		local hrp = getCharacterRoot(player)
		if hrp and isInSafeZone(hrp.Position) then
			claimAreaEgg(player, record)
		end
		return
	end
	local record = records[args.EggUid]
	if record and record.State == "Dropped" and not isServerChaseZone(record.AreaId) then
		returnToNest(record)
	end
end)

local function hookCharacter(player, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Connect(function()
			if player.Character == character then
				endCarryAndReturn(player, "HumanoidDied")
			end
		end)
	end
end

local function hookPlayer(player)
	player.CharacterAdded:Connect(function(character)
		hookCharacter(player, character)
	end)
	player.CharacterRemoving:Connect(function()
		endCarryAndReturn(player, "CharacterRemoving")
	end)
	if player.Character then
		task.spawn(hookCharacter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(hookPlayer)
for _, existingPlayer in ipairs(Players:GetPlayers()) do
	hookPlayer(existingPlayer)
end

Players.PlayerRemoving:Connect(function(player)
	lastNoticeAt[player] = nil
	nightTeleportUntil[player] = nil
	local uid = carryByPlayer[player]
	setCarry(player, nil)
	if uid then
		local record = records[uid]
		if record then
			if record.State == "Carried" and record.CarrierUserId == player.UserId then
				returnToNest(record, "PlayerLeft")
			end
			returnGuardToPost(record.AreaId, false)
		end
	end
end)

if GuardChaseService then
	local ok, err = pcall(GuardChaseService.Init, {
		IsInSafeZone = isInSafeZone,
		GetCarriersForArea = getCarriersForArea,
		GetRecord = function(uid)
			return records[uid]
		end,
		OnGuardCaughtPlayer = onGuardCaughtPlayer,
		ReturnDroppedEggToNest = returnDroppedEggToNest,
	})
	if not ok then
		warn("[AreaEggService] GuardChaseService.Init failed: " .. tostring(err))
		GuardChaseService = nil
	end
end

-- Backstop for failed initial spawns: every stage is topped up to its active egg count.
task.delay(3, function()
	local repaired = 0
	local checked = 0
	for _, areaId in ipairs(ZONE_NAMES) do
		if zoneSlots[areaId] then
			checked += 1
			repaired += #topUpZone(areaId)
			local count = getZoneEggState(areaId)
			if count < getActiveEggTarget(areaId) then
				warn(string.format("[AreaEggService] %s has %d/%d active eggs after the spawn retry.", areaId, count, getActiveEggTarget(areaId)))
			end
		end
	end
	warn(string.format("[AreaEggService] Spawn verification: checked %d stages, spawned %d missing eggs.", checked, repaired))
end)


-- Contract C3 hooks, exposed for other server code and tooling.
AreaEggService.StartVillainChase = startVillainChase
AreaEggService.OnGuardCaughtPlayer = onGuardCaughtPlayer
AreaEggService.ReturnGuardToPost = returnGuardToPost
AreaEggService.DropCarriedEgg = dropCarriedEgg
AreaEggService.IsInSafeZone = isInSafeZone
-- Player-vs-player gear (GearService): Bat hits and traps make a carrier drop their egg.
AreaEggService.GetCarriedEggUid = getCarriedEggUid
AreaEggService.DropCarriedEggFrom = dropCarriedEggFrom

return AreaEggService
