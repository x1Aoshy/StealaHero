--!nocheck
-- Gameplay (docs/STAGES_PLAN.md A2-A5, A7-A9, A12 + docs/VISUAL_PASS_PLAN.md D2, D3, D5, D8 + the earlier refactor
-- contracts): steal -> villain chase -> escape bounty -> hatch -> plot -> treadmill, gear (bat ragdoll, starter kit,
-- server-side safe zone), the 6-stage rules (one chase per stage, 3D catches, spawn on pickup, per-villain signatures,
-- hub-only safe zone), the stage hazard runtime, stage ambience and retired-zone removal.
-- Where a rule lives in a small pure function, the function is extracted from the injected source and run in a
-- sandbox (Roblox semantics mocked), so these checks exercise behaviour, not just the presence of tokens.

local place = H.place()
local ws = place.Workspace
local rs = place.ReplicatedStorage
local sss = place:GetService("ServerScriptService")
local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local PLAN = H.PLAN
local roblox = H.roblox
local Vector3 = roblox.Vector3

local function src(path)
	local node = H.path(sss, path)
	return node and node.Source or ""
end
local function clientSrc(path)
	local node = sps and H.path(sps, path)
	return node and node.Source or ""
end
local baseplate = ws:FindFirstChild("Baseplate")
local groundY = baseplate and (baseplate.CFrame.Position.Y + baseplate.Size.Y / 2) or 2.05

-- Loads extracted function sources (plus optional prelude) in a sandbox and returns what the chunk returns.
local function loadPieces(label, prelude, names, source, globals, returnExpr)
	local pieces = { prelude or "" }
	for _, name in ipairs(names) do
		local body = H.extractFunction(source, name)
		if not T.check(body ~= nil, "%s: local function %s not found", label, name) then
			return nil
		end
		table.insert(pieces, body)
	end
	table.insert(pieces, "return " .. returnExpr)
	local chunk, err = H.sandbox(table.concat(pieces, "\n"), globals, label)
	if not T.check(chunk ~= nil, "%s: extracted code does not load: %s", label, tostring(err)) then
		return nil
	end
	local ok, result = pcall(chunk)
	if not T.check(ok, "%s: extracted code failed: %s", label, tostring(result)) then
		return nil
	end
	return result
end

-- task.* stand-in: spawned threads run until their first wait; tick() resumes every waiting thread once.
local function newScheduler()
	local s = { threads = {}, errors = {} }
	s.task = {}
	function s.task.spawn(fn, ...)
		local co = if type(fn) == "thread" then fn else coroutine.create(fn)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			table.insert(s.errors, tostring(err))
		elseif coroutine.status(co) ~= "dead" then
			table.insert(s.threads, co)
		end
		return co
	end
	s.task.defer = s.task.spawn
	function s.task.delay(_, fn, ...)
		return s.task.spawn(fn, ...)
	end
	function s.task.wait(seconds)
		return coroutine.yield(seconds)
	end
	function s.tick()
		local live = {}
		for _, co in ipairs(s.threads) do
			local ok, err = coroutine.resume(co)
			if not ok then
				table.insert(s.errors, tostring(err))
			elseif coroutine.status(co) ~= "dead" then
				table.insert(live, co)
			end
		end
		s.threads = live
	end
	return s
end

---------------------------------------------------------------------------------------------------
-- 1. Earlier contracts: plots / data / steal + chase + bounty / eggs / treadmill / gear
---------------------------------------------------------------------------------------------------
T.check(H.has(src("Controllers/PlotService"), "AvatarHeadShot"), "PlotService must show the owner's headshot on the sign")
T.check(H.has(src("Library/Database"), "EnsureStatDefaults"), "Database must self-heal profiles (EnsureStatDefaults)")

local areaEgg = src("Controllers/AreaEggService")
for _, token in ipairs({ "attemptCarry", "claimAreaEgg", "startVillainChase", "onGuardCaughtPlayer", "returnGuardToPost", "isInSafeZone",
	"BOUNTY_BY_RARITY", "SpawnIntoNest", "returnToNest", "ForestDeposit" }) do
	T.check(H.has(areaEgg, token), "AreaEggService must contain %s", token)
end
for _, tier in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Eternal", "Divine" }) do
	T.check(string.find(areaEgg, tier .. "%s*=%s*%d") ~= nil, "BOUNTY_BY_RARITY must define %s", tier)
end
local chase = src("Controllers/GuardChaseService")
for _, token in ipairs({ "PathfindingService", "CreatePath", "ComputeAsync", "GetWaypoints", "SetNetworkOwner" }) do
	T.check(H.has(chase, token), "GuardChaseService must use %s", token)
end

local eggService = src("Controllers/EggService")
local skip = string.match(eggService, "RequestSkipGrowthRemote%.OnServerInvoke%s*=%s*function(.-)\nend")
T.check(skip ~= nil and not string.find(skip, "ReadyAt"), "RequestSkipGrowth must not ready eggs for free")

local grind = src("Controllers/TreadmillGrindService")
T.check(H.has(grind, "BaseUpgradeLevel"), "TreadmillGrindService must gate training on the purchase (BaseUpgradeLevel)")
T.check(H.has(grind, "TREADMILL_COINS_PER_SECOND"), "TreadmillGrindService must award coins")
local lock = sps and sps:FindFirstChild("TreadmillPositionLockController", true)
if T.check(lock ~= nil, "TreadmillPositionLockController missing") then
	T.check(H.has(lock.Source, "913376220"), "treadmill must play Roblox's default R15 run (913376220)")
	T.check(H.has(lock.Source, "AutoRotate"), "treadmill lock must hold facing (AutoRotate)")
	T.check(H.has(lock.Source, "AnimationPriority.Action"), "treadmill run must play at Action priority")
end

local shopItems = H.path(rs, "GearTools/ShopItems")
T.check(shopItems ~= nil and shopItems:FindFirstChild("Bat", true) ~= nil, "Bat tool missing from GearTools")

-- AreaEggService waits (no timeout) on its remotes: every one must exist or be created by NetworkInit.
local networkInit = src("NetworkInit")
local networkFolder = rs:FindFirstChild("Network")
for name in string.gmatch(areaEgg, "Network:WaitForChild%(\"([^\"]+)\"%)") do
	local created = H.has(networkInit, "\"" .. name .. "\"") or (networkFolder and networkFolder:FindFirstChild(name) ~= nil)
	T.check(created, "AreaEggService waits forever on Network[%q]: neither in the place nor created by NetworkInit", name)
end

-- gear (D2 ragdoll, D3 starter kit, server-side safe zone)
local gear = sss:FindFirstChild("GearService")
if T.check(gear ~= nil and gear.ClassName == "Script", "ServerScriptService.GearService (server Script) missing") then
	local gsrc = gear.Source
	T.check(H.has(gsrc, "Bat") and (H.has(gsrc, "Trap") or H.has(gsrc, "SubspaceMine")), "GearService must hand out the Bat and the traps")
	-- D3 starter kit through StarterGear; D2 bat ragdoll; the base game's safe zone enforced on the server
	T.check(H.has(gsrc, "StarterGear") and not H.has(gsrc, "GearGivers"), "D3: GearService grants the kit through StarterGear, never from Workspace.GearGivers")
	T.check(H.has(gsrc, "Gear: Ragdoll") and H.has(gsrc, "BallSocketConstraint"), "D2: GearService ragdolls the bat victim (BallSocketConstraint joints + Network[\"Gear: Ragdoll\"])")
	T.check(H.has(gsrc, "SeparationLine") and H.has(gsrc, "isOnGameplaySide"), "GearService must enforce the hub safe zone on the server (SeparationLine / isOnGameplaySide)")

	-- behaviour: ensureStarterGear gives exactly one Bat + Trap to the Backpack and StarterGear, never the Subspace Trap
	local starterBlock = string.match(gsrc, "local STARTER_GEAR%s*=%s*%b{}")
	local shopItems = H.path(rs, "GearTools/ShopItems")
	local hooked = {}
	local ensure = loadPieces("D3 starter gear", starterBlock, { "prepareGearTool", "gearToolsIn", "ensureStarterGear" }, gsrc, {
		shopItems = shopItems,
		hookTool = function(_, tool)
			table.insert(hooked, tool)
		end,
		log = function() end,
	}, "ensureStarterGear")
	if ensure and shopItems then
		local backpack = roblox.Instance.new("Folder") -- detached stand-ins: the shared place is never mutated
		local starterGear = roblox.Instance.new("Folder")
		local character = roblox.Instance.new("Folder")
		local player = {
			Name = "Tester",
			Parent = true,
			Character = character,
			FindFirstChildOfClass = function(_, className)
				return if className == "Backpack" then backpack elseif className == "StarterGear" then starterGear else nil
			end,
		}
		local function names(container)
			local list = {}
			for _, c in ipairs(container:GetChildren()) do
				table.insert(list, c.Name)
			end
			table.sort(list)
			return table.concat(list, ",")
		end
		local want = table.clone(PLAN.STARTER_GEAR)
		table.sort(want)
		local okRun, err = pcall(ensure, player)
		if T.check(okRun, "D3 ensureStarterGear failed: %s", tostring(err)) then
			T.check(names(backpack) == table.concat(want, ","), "D3: a new player's Backpack must hold exactly %s, found {%s}", table.concat(want, ", "), names(backpack))
			T.check(names(starterGear) == table.concat(want, ","), "D3: StarterGear must hold exactly %s (respawns keep them), found {%s}", table.concat(want, ", "), names(starterGear))
			for _, tool in ipairs(backpack:GetChildren()) do
				T.check(tool:GetAttribute("ItemType") == "Gear" and tool:GetAttribute("GearName") == tool.Name and tool.CanBeDropped == false,
					"D3: granted %s must be marked as gear (GearName, ItemType) and not droppable", tool.Name)
			end
			T.check(#hooked == #PLAN.STARTER_GEAR, "D3: every granted Backpack tool must be hooked (swing / place handlers), hooked %d", #hooked)
			for _, name in ipairs(PLAN.NOT_STARTER_GEAR) do
				T.check(backpack:FindFirstChild(name) == nil and starterGear:FindFirstChild(name) == nil, "D3: %s must not be granted at start", name)
			end
			-- idempotent: a second pass (respawn) and an equipped Bat never duplicate the kit
			local equipped = backpack:FindFirstChild(PLAN.STARTER_GEAR[1])
			if equipped then
				equipped.Parent = character
			end
			pcall(ensure, player)
			pcall(ensure, player)
			T.check(#backpack:GetChildren() + #character:GetChildren() == #PLAN.STARTER_GEAR and #starterGear:GetChildren() == #PLAN.STARTER_GEAR,
				"D3: re-running the grant (respawn / equipped tool) must not duplicate the kit: backpack {%s}, character {%s}, StarterGear {%s}", names(backpack),
				names(character), names(starterGear))
		end
	end

	-- behaviour: gear works only past the SeparationLine (the hub is the safe zone). Lune parts have no derived
	-- Position property, so the place's SeparationLine is handed over as a stand-in with the same CFrame.
	local line = H.path(ws, "__OBJECTS/Areas/SeparationLine")
	T.check(line ~= nil and line:IsA("BasePart"), "Workspace.__OBJECTS.Areas.SeparationLine missing (GearService's safe-zone edge)")
	local lineProxy = line and {
		CFrame = line.CFrame,
		Position = line.CFrame.Position,
		IsA = function(_, className)
			return line:IsA(className)
		end,
	}
	local function finder(children)
		return { FindFirstChild = function(_, name)
			return children[name]
		end }
	end
	local wsProxy = finder({ __OBJECTS = finder({ Areas = finder({ SeparationLine = lineProxy }) }) })
	local isOnGameplaySide = loadPieces("gear safe zone", "local SAFE_ZONE_FALLBACK_X = " .. tostring(H.constant(gsrc, "SAFE_ZONE_FALLBACK_X") or 75),
		{ "isOnGameplaySide" }, gsrc, { Workspace = wsProxy }, "isOnGameplaySide")
	if isOnGameplaySide then
		local points = { { Vector3.new(37, groundY + 3, 0), false, "hub spawn" }, { Vector3.new(60, groundY + 3, 25), false, "hub plots" } }
		for _, stage in ipairs(PLAN.STAGES) do
			table.insert(points, { Vector3.new((stage.xMin + stage.xMax) / 2, groundY + 3, 0), true, stage.name })
		end
		for _, pt in ipairs(points) do
			local ok, result = pcall(isOnGameplaySide, pt[1])
			T.check(ok and result == pt[2], "GearService isOnGameplaySide(%s) must be %s", pt[3], tostring(pt[2]))
		end
	end
end
local ragdollRemote = networkFolder and networkFolder:FindFirstChild("Gear: Ragdoll")
T.check(ragdollRemote ~= nil and ragdollRemote.ClassName == "RemoteEvent", "ReplicatedStorage.Network[\"Gear: Ragdoll\"] (RemoteEvent) missing (D2)")
local ragdollClient = sps and H.path(sps, "Game/Tools/GearRagdollController")
T.check(ragdollClient ~= nil and ragdollClient.ClassName == "LocalScript" and H.has(ragdollClient.Source, "Gear: Ragdoll"),
	"StarterPlayerScripts.Game.Tools.GearRagdollController (LocalScript on Network[\"Gear: Ragdoll\"]) missing (D2)")

---------------------------------------------------------------------------------------------------
-- 2. AreaEggService stage rules: 6 zones, N active of M spots, hidden/Epic rotation (§1, A1, A7)
---------------------------------------------------------------------------------------------------
do
	local block = string.match(areaEgg, "local ZONE_NAMES%s*=%s*(%b{})")
	local names = {}
	for name in string.gmatch(block or "", "\"([^\"]+)\"") do
		table.insert(names, name)
	end
	local want = {}
	for _, s in ipairs(PLAN.STAGES) do
		table.insert(want, s.key)
	end
	T.check(table.concat(names, ",") == table.concat(want, ","), "AreaEggService ZONE_NAMES must be exactly the 6 stage keys (A1), found {%s}", table.concat(names, ","))
	T.check(H.has(areaEgg, "GetAttribute(\"ActiveEggCount\")"), "AreaEggService must read the zone's ActiveEggCount (N active eggs of M spots)")
	local minHidden = H.constant(areaEgg, "MIN_HIDDEN_ACTIVE_EGGS")
	T.check(minHidden ~= nil and minHidden >= 2, "A7: the rotation keeps >= 2 Hidden spots among the active eggs (MIN_HIDDEN_ACTIVE_EGGS = %s)", tostring(minHidden))
	local topUp = H.extractFunction(areaEgg, "topUpZone") or ""
	T.check(H.has(topUp, "MIN_HIDDEN_ACTIVE_EGGS") and H.has(topUp, "Hidden"), "A7: topUpZone must prefer Hidden spots up to MIN_HIDDEN_ACTIVE_EGGS")
	T.check(H.has(areaEgg, "EPIC_RARITY_NUMBER") and H.has(H.extractFunction(areaEgg, "pickCategoryFor") or "", "minRarityNumber"),
		"A7: the rotation keeps one Epic-or-better egg per stage (pickCategoryFor minRarityNumber)")
	T.check(H.has(areaEgg, "GuardAreasFolder:FindFirstChild(name)"), "AreaEggService must look zones up with FindFirstChild (retired zones are gone)")
end

---------------------------------------------------------------------------------------------------
-- 3. A4 one chase per stage (behaviour of isVillainHuntingOther / getVillainName + attemptCarry wiring)
---------------------------------------------------------------------------------------------------
do
	local present = { [101] = true, [202] = true }
	local mockPlayers = {
		GetPlayerByUserId = function(_, id)
			return if present[id] then { UserId = id } else nil
		end,
	}
	local function guardWith(attrs)
		return {
			GetAttribute = function(_, k)
				return attrs[k]
			end,
		}
	end
	local zones = {}
	local function zoneWith(guard)
		return {
			FindFirstChild = function(_, name)
				return if name == "Guard" then guard else nil
			end,
		}
	end
	local villainTable = string.match(areaEgg, "local VILLAIN_BY_ZONE%s*=%s*%b{}") or "local VILLAIN_BY_ZONE = {}"
	local fns = loadPieces("A4", villainTable, { "getVillainName", "isVillainHuntingOther" }, areaEgg,
		{ zoneModel = zones, Players = mockPlayers }, "{ getVillainName = getVillainName, isVillainHuntingOther = isVillainHuntingOther }")
	if fns then
		local me, other, gone = { UserId = 101 }, { UserId = 202 }, { UserId = 303 }
		local cases = {
			{ "Chasing another present player", { GuardState = "Chasing", TargetPlayer = 202 }, me, true },
			{ "Waking for another present player", { GuardState = "Waking", TargetPlayer = "202" }, me, true },
			{ "Chasing the same player", { GuardState = "Chasing", TargetPlayer = 101 }, me, false },
			{ "Chasing a player who left", { GuardState = "Chasing", TargetPlayer = 303 }, me, false },
			{ "Returning to its post", { GuardState = "Returning", TargetPlayer = 202 }, me, false },
			{ "Retrieving a dropped egg", { GuardState = "Retrieving", TargetPlayer = 202 }, me, false },
			{ "Sleeping (another player merely carries an egg)", { GuardState = "Sleeping", TargetPlayer = 0 }, other, false },
			{ "Chasing with no target", { GuardState = "Chasing", TargetPlayer = 0 }, me, false },
		}
		for _, c in ipairs(cases) do
			zones.Lake = zoneWith(guardWith(c[2]))
			local ok, result = pcall(fns.isVillainHuntingOther, "Lake", c[3])
			T.check(ok and result == c[4], "A4 isVillainHuntingOther (%s) must be %s, got %s", c[1], tostring(c[4]), tostring(result))
		end
		zones.Lake = nil
		local ok, result = pcall(fns.isVillainHuntingOther, "Lake", me)
		T.check(ok and result == false, "A4 isVillainHuntingOther must tolerate a missing zone")
		for _, stage in ipairs(PLAN.STAGES) do
			zones[stage.key] = zoneWith(guardWith({ VillainName = stage.villainName, HeroId = "X" }))
			T.check(fns.getVillainName(stage.key) == stage.villainName, "A4 getVillainName(%s) must use the Guard's VillainName", stage.key)
			zones[stage.key] = zoneWith(guardWith({ HeroId = stage.villain }))
			T.check(fns.getVillainName(stage.key) == stage.villain, "A4 getVillainName(%s) must fall back to HeroId", stage.key)
			zones[stage.key] = nil
			T.check(fns.getVillainName(stage.key) == stage.villainName, "A4 getVillainName(%s) must fall back to the plan villain", stage.key)
		end
	end
	local carry = H.extractFunction(areaEgg, "attemptCarry") or ""
	local refuse = string.find(carry, "isVillainHuntingOther(record.AreaId, player)", 1, true)
	local claim = string.find(carry, "record.State = \"Carried\"", 1, true)
	T.check(refuse ~= nil and claim ~= nil and refuse < claim, "A4: attemptCarry must refuse before it marks the egg Carried")
	T.check(H.has(carry, "getVillainName(record.AreaId) .. \" is already hunting someone! Try again in a moment.\""),
		"A4: the refusal message must be \"<Villain> is already hunting someone! Try again in a moment.\"")
	local hunting = H.extractFunction(areaEgg, "isVillainHuntingOther") or ""
	T.check(not H.has(hunting, "carryByPlayer") and not H.has(hunting, "Carried"), "A4: another carrier alone must not lock the stage (only the Guard's state)")
end

---------------------------------------------------------------------------------------------------
-- 4. A5 the hub is the only safe zone (isInSafeZone behaviour with the place's own GameplayZ part)
---------------------------------------------------------------------------------------------------
do
	local gameplayZ = ws:FindFirstChild("GameplayZ", true)
	local isInSafeZone = loadPieces("A5", nil, { "isInSafeZone" }, areaEgg, { safeZonePart = gameplayZ }, "isInSafeZone")
	local body = H.extractFunction(areaEgg, "isInSafeZone") or ""
	T.check(not H.has(body, "DeliveryHitbox"), "A5: isInSafeZone must not count the DeliveryHitbox (the hub is the only safe zone)")
	if gameplayZ then
		local mn, mx = H.aabb(gameplayZ)
		T.check(mx.X <= PLAN.HUB_MAX_X, "A5: GameplayZ (a safe-zone volume) reaches X %.1f, beyond the hub", mx.X)
	end
	if isInSafeZone then
		local delivery = H.path(ws, "__OBJECTS/DeliveryHitbox")
		local points = {
			{ Vector3.new(37, groundY + 3, 0), true, "hub spawn" },
			{ Vector3.new(74.9, groundY + 3, 30), true, "hub edge" },
			{ Vector3.new(76, groundY + 3, 0), false, "stage 1 entrance" },
		}
		for _, stage in ipairs(PLAN.STAGES) do
			table.insert(points, { Vector3.new((stage.xMin + stage.xMax) / 2, groundY + 3, -40), false, stage.name })
		end
		if delivery then
			table.insert(points, { delivery.CFrame.Position, false, "the old DeliveryHitbox" })
		end
		for _, p in ipairs(points) do
			local ok, result = pcall(isInSafeZone, p[1])
			T.check(ok and result == p[2], "A5 isInSafeZone(%s) must be %s", p[3], tostring(p[2]))
		end
	end
	T.check(H.constant(chase, "MIN_GUARD_X") == PLAN.GUARD_MIN_X, "villains must stop at X = %d (MIN_GUARD_X)", PLAN.GUARD_MIN_X)
	T.check(H.constant(chase, "SAFE_ZONE_MAX_X") == PLAN.HUB_MAX_X, "GuardChaseService safe-zone fallback must be X <= %d", PLAN.HUB_MAX_X)
end

---------------------------------------------------------------------------------------------------
-- 5. A3 3D catches (canCatch behaviour per villain scale) + pathing agent + no Humanoid jumps
---------------------------------------------------------------------------------------------------
do
	local consts = {}
	for _, name in ipairs({ "HIT_BASE_PAD", "HIT_LATENCY_SECONDS", "HIT_MAX_LATENCY_PAD", "VERTICAL_CATCH_BASE", "VERTICAL_CATCH_PER_SCALE" }) do
		consts[name] = H.constant(chase, name)
		T.check(consts[name] ~= nil, "GuardChaseService constant %s missing", name)
	end
	T.check(consts.VERTICAL_CATCH_BASE == 3 and consts.VERTICAL_CATCH_PER_SCALE == 2.5, "A3: catch height limit must be 2.5 * scale + 3")
	local globals = {
		Vector3 = Vector3,
		Enum = H.roblox.Enum,
		GROUND_PROBE_DEPTH = H.constant(chase, "GROUND_PROBE_DEPTH") or 40,
		isInSafeZone = function(p)
			return p.X <= PLAN.HUB_MAX_X
		end,
		-- a downward probe (the jump check) finds the floor at g.floorY; any other ray hits only when g.blocked
		castRay = function(g, origin, direction)
			if direction.X == 0 and direction.Z == 0 and direction.Y < 0 and g.floorY then
				return { Position = Vector3.new(origin.X, g.floorY, origin.Z) }
			end
			return if g.blocked then {} else nil
		end,
	}
	for k, v in pairs(consts) do
		globals[k] = v
	end
	-- canCatch judges a jumping carrier where they will land (standingPosition; owner 2026-09-27 jump fix)
	local canCatch = loadPieces("A3", nil, { "catchDistance", "standingPosition", "canCatch" }, chase, globals, "canCatch")
	if canCatch then
		for _, stage in ipairs(PLAN.STAGES) do
			local s = stage.scale
			local villainY = groundY + 2 * s + s -- HipHeight 2*scale + half the 2*scale root
			local limit = 2.5 * s + 3
			local reach = 3 + (consts.HIT_BASE_PAD or 0)
			local function try(label, carrier, flatDistance, blocked)
				local g = { hitDistance = 3, scale = s, blocked = blocked, hrp = { Position = Vector3.new(200, villainY, 0) } }
				local root = { Position = carrier, AssemblyLinearVelocity = Vector3.new(0, 0, 0) }
				local ok, result = pcall(canCatch, g, root, flatDistance)
				return ok and result, label
			end
			local near = Vector3.new(201, groundY + 3, 0)
			T.check(try("same floor", near, 1) == true, "A3 %s: a carrier 1 stud away on the same floor must be caught", stage.villain)
			T.check(try("out of reach", near, reach + 1) == false, "A3 %s: a carrier beyond the flat reach must not be caught", stage.villain)
			T.check(try("ledge", Vector3.new(201, villainY + limit + 0.5, 0), 1) == false,
				"A3 %s: a carrier %.1f studs above the villain's root (limit %.2f) must not be caught", stage.villain, limit + 0.5, limit)
			T.check(try("step", Vector3.new(201, villainY + limit - 0.5, 0), 1) == true, "A3 %s: a carrier just inside the height limit must be caught", stage.villain)
			T.check(try("below", Vector3.new(201, villainY - limit - 0.5, 0), 1) == false, "A3 %s: a carrier far below must not be caught", stage.villain)
			T.check(try("wall", near, 1, true) == false, "A3 %s: nothing solid may stand between villain and carrier", stage.villain)
			-- mid-jump above the height limit, over the villain's own floor: judged at the floor, so caught
			local g = { hitDistance = 3, scale = s, floorY = groundY, hrp = { Position = Vector3.new(200, villainY, 0) } }
			local jumper = {
				Position = Vector3.new(201, villainY + limit + 2, 0),
				Size = Vector3.new(2, 2, 1),
				AssemblyLinearVelocity = Vector3.new(0, 0, 0),
				Parent = {
					FindFirstChildOfClass = function(_, className)
						return if className == "Humanoid" then { FloorMaterial = H.roblox.Enum.Material.Air, HipHeight = 2 } else nil
					end,
				},
			}
			local okJump, jumpCaught = pcall(canCatch, g, jumper, 1)
			T.check(okJump and jumpCaught == true, "A3 %s: a carrier mid-jump over the villain's floor must be catchable (%s)", stage.villain,
				tostring(jumpCaught))
		end
		local g = { hitDistance = 3, scale = 1, hrp = { Position = Vector3.new(76, groundY + 3, 0) } }
		local ok, result = pcall(canCatch, g, { Position = Vector3.new(74, groundY + 3, 0), AssemblyLinearVelocity = Vector3.new(0, 0, 0) }, 2)
		T.check(ok and result == false, "A3: a carrier in the safe zone is never caught")
	end
	T.check(H.has(chase, "AgentRadius = math.max(2, 1.6 * scale)"), "A3: AgentRadius must be max(2, 1.6 * scale)")
	T.check(H.has(chase, "AgentCanJump = false"), "A3: villains path with AgentCanJump = false")
	T.check(string.find(chase, "local agentHeight = if collider then collider.Size.Y", 1, true) ~= nil, "A3: AgentHeight must be the collider height")
	T.check(not string.find(chase, "%.Jump%s*=%s*true") and not H.has(chase, "HumanoidStateType.Jumping") and not string.find(chase, ":Jump%("),
		"A3: Carnage's leap must never be a Humanoid jump")
end

---------------------------------------------------------------------------------------------------
-- 6. A2 spawn on pickup + return to post; §1 signatures per HeroId; ChaseSpeedFactor for the speed sign
---------------------------------------------------------------------------------------------------
do
	local spawnDistance = H.constant(chase, "SPAWN_DISTANCE")
	T.check(spawnDistance ~= nil and spawnDistance >= 30 and spawnDistance <= 40, "A2: the villain spawns ~35 studs from the carrier (SPAWN_DISTANCE = %s)", tostring(spawnDistance))
	local spawnFn = H.extractFunction(chase, "resolveSpawnCFrame") or ""
	T.check(H.has(spawnFn, "carrier.X + math.sqrt"), "A2: the spawn point is on the side away from the hub (+X of the carrier)")
	T.check(H.has(spawnFn, "streetZ") and H.has(spawnFn, "castRay"), "A2: the spawn point is a floor point on the main street")
	T.check(H.has(H.extractFunction(chase, "spawnForCarrier") or "", "fireFx(g, \"Spawn\""), "A2: the spawn plays the arrival FX (ChaseFx Spawn)")
	T.check(H.has(chase, "function GuardChaseService.StartChase") and H.has(chase, "function GuardChaseService.ReturnToPost"),
		"GuardChaseService must export StartChase and ReturnToPost")
	T.check(H.has(chase, "\"Vanish\"") and H.constant(chase, "RETURN_TELEPORT_DISTANCE") ~= nil, "A2: far/stuck villains vanish and reappear at their post")

	-- signatures, keyed by the built guards' HeroId
	local sigBlock = string.match(chase, "local SIGNATURES%s*=%s*(%b{})")
	local sigChunk = sigBlock and H.sandbox("return " .. sigBlock, {}, "SIGNATURES")
	local okSig, signatures = false, nil
	if sigChunk then
		okSig, signatures = pcall(sigChunk)
	end
	if T.check(okSig and type(signatures) == "table", "GuardChaseService SIGNATURES table missing or not plain data") then
		T.check(signatures.Darkseid and signatures.Darkseid.Surge, "Darkseid signature: slow-then-surge (Surge) missing")
		T.check(signatures.Carnage and signatures.Carnage.Leap, "Carnage signature: leap/lunge (Leap) missing")
		T.check(signatures.Frieza and signatures.Frieza.Hover and signatures.Frieza.Beam, "Frieza signature: hover + energy beam missing")
		T.check(signatures.Kaido and signatures.Kaido.Roar, "Kaido signature: ground-shake roar missing")
	end
	local aliases = string.match(chase, "local SIGNATURE_ALIASES%s*=%s*%b{}")
	local resolve = aliases and loadPieces("signatures", aliases, { "resolveSignatureKey" }, chase, {}, "resolveSignatureKey")
	local guardAreas = H.path(ws, "__OBJECTS/Areas/GuardAreas")
	for _, stage in ipairs(PLAN.STAGES) do
		local guard = guardAreas and H.path(guardAreas, stage.key .. "/Guard")
		local heroId = guard and guard:GetAttribute("HeroId")
		if resolve then
			local key = resolve(heroId)
			T.check(key == stage.villain and signatures and signatures[key] ~= nil, "stage %d guard HeroId %s must resolve to the %s chase signature, got %s",
				stage.number, tostring(heroId), stage.villain, tostring(key))
		end
	end
	T.check(H.has(chase, "setAttr(g, \"ChaseSpeedFactor\""), "GuardChaseService must publish ChaseSpeedFactor for the RequiredSpeedSign")
	local sign = clientSrc("Game/GuardAreas/GuardEscapeSignController")
	T.check(H.has(sign, "GetAttribute(\"ChaseSpeedFactor\")"), "GuardEscapeSignController must use the guard's ChaseSpeedFactor")

	-- client presentation (A12)
	local fx = clientSrc("Game/VillainChaseFx")
	if T.check(fx ~= "", "StarterPlayerScripts.Game.VillainChaseFx missing") then
		-- owner 2026-09-23: no on-screen chase banner / safe-zone distance meter (the original game has none)
		T.check(not H.has(fx, "IS CHASING YOU") and not H.has(fx, "SafeZoneMeter") and not H.has(fx, "ScreenGui"),
			"VillainChaseFx must not build the chase banner / safe-zone meter UI (owner removed it)")
		for _, stage in ipairs(PLAN.STAGES) do
			T.check(string.find(fx, "\n%s*" .. stage.villain .. "%s*=%s*{") ~= nil, "VillainChaseFx has no signature entry for %s", stage.villain)
		end
		local maxShake = H.constant(fx, "MAX_SHAKE")
		T.check(maxShake ~= nil and maxShake <= 0.5, "A12: camera shake amplitude must be <= 0.5 (MAX_SHAKE = %s)", tostring(maxShake))
		for amp in string.gmatch(fx, "Amplitude%s*=%s*([%d%.]+)") do
			T.check(tonumber(amp) <= 0.5, "A12: shake Amplitude %s exceeds 0.5", amp)
		end
		T.check(H.has(fx, "ReducedMotion"), "A12: camera shake must respect Reduced Motion")
		T.check(not string.find(fx, "Instance%.new%(%s*\"Sound\""), "A12: chase effects are silent (no Sound)")
		T.check(H.has(fx, "__DEBRIS"), "A12: effects live in Workspace.__DEBRIS")
		T.check(not H.has(fx, "Aura_Villain"), "A12: no duplicate of the SabVfx villain aura")
		T.check(H.has(fx, "\"GuardState\"") and H.has(fx, "\"TargetPlayer\"") and H.has(fx, "\"ChaseFx\""), "A12: effects are driven by the replicated guard attributes")
	end
end

---------------------------------------------------------------------------------------------------
-- 7. A8 StageHazardService stays installed: D8 archived every hazard with its building, so it runs silently with none
--    in the Workspace; its runtime is still exercised on synthetic hazards (what the owner's builder will tag)
---------------------------------------------------------------------------------------------------
local hazardScript = sss:FindFirstChild("StageHazardService")
local environments = ws:FindFirstChild("StageEnvironments")
if T.check(hazardScript ~= nil and hazardScript.ClassName == "Script", "ServerScriptService.StageHazardService (server Script) missing (A8)") then
	local hsrc = hazardScript.Source
	T.check(not hazardScript.Disabled, "StageHazardService must be enabled")
	T.check(H.has(hsrc, "Players:GetPlayers()") and not H.has(hsrc, "GuardAreas"), "A8: hazards slow players only, never the villains")

	-- collidable flat surfaces, to stand the test player on whatever is under each hazard
	local surfaces = {}
	for _, d in ipairs(ws:GetDescendants()) do
		if d:IsA("BasePart") and not d:IsA("Terrain") and d.CanCollide and d ~= baseplate and d.CFrame.UpVector.Y > 0.99 then
			table.insert(surfaces, d)
		end
	end
	local function floorUnder(pos, maxTop)
		local best = groundY
		for _, p in ipairs(surfaces) do
			local rel = p.CFrame:PointToObjectSpace(pos)
			local top = p.CFrame.Position.Y + p.Size.Y / 2
			if math.abs(rel.X) <= p.Size.X / 2 and math.abs(rel.Z) <= p.Size.Z / 2 and top <= maxTop and top > best then
				best = top
			end
		end
		return best
	end

	local sched = newScheduler()
	local warnings = {}
	local added, removing = H.mockSignal(), H.mockSignal()
	local fakeParts = {}
	local envProxy = {
		GetDescendants = function()
			local list = environments and environments:GetDescendants() or {}
			for _, p in ipairs(fakeParts) do
				table.insert(list, p)
			end
			return list
		end,
		DescendantAdded = added,
		DescendantRemoving = removing,
	}
	local players = {}
	local services = {
		Players = { GetPlayers = function()
			return players
		end, PlayerRemoving = H.mockSignal() },
		ServerScriptService = { FindFirstChild = function()
			return nil
		end },
		Workspace = {
			FindFirstChild = function(_, name)
				return if name == "StageEnvironments" then envProxy else nil
			end,
			WaitForChild = function(_, name)
				return if name == "StageEnvironments" then envProxy else nil
			end,
		},
	}
	local chunk, err = H.sandbox(hsrc, {
		game = { GetService = function(_, name)
			return services[name]
		end },
		task = sched.task,
		Enum = roblox.Enum,
		warn = function(...)
			table.insert(warnings, table.concat({ ... }, " "))
		end,
	}, "StageHazardService")
	if T.check(chunk ~= nil, "StageHazardService does not load: %s", tostring(err)) then
		local ok, runErr = pcall(chunk)
		T.check(ok, "StageHazardService failed at start: %s", tostring(runErr))
		local attrs = {}
		local character = {}
		local humanoid = { WalkSpeed = 40, Health = 100, Parent = character }
		local root = { Position = Vector3.new(37, groundY + 3, 0) }
		function character:FindFirstChildOfClass(className)
			return if className == "Humanoid" then humanoid else nil
		end
		function character:FindFirstChild(name)
			return if name == "HumanoidRootPart" then root else nil
		end
		function character:GetAttribute(name)
			return attrs[name]
		end
		players[1] = { Name = "Tester", UserId = 1, Character = character }
		local function standAt(pos)
			root.Position = pos
			sched.tick()
			return humanoid.WalkSpeed
		end

		-- every hazard part of the build, stood on at its centre
		local hazards = {}
		for _, d in ipairs(environments and environments:GetDescendants() or {}) do
			if d:IsA("BasePart") and d:GetAttribute("StageHazard") == "Slow" then
				table.insert(hazards, d)
			end
		end
		T.check(#hazards == 0, "D8: no StageHazard may stay in Workspace.StageEnvironments (archived with the buildings), found %d", #hazards)
		local function standingPoint(part, localOffset)
			local world = part.CFrame:PointToWorldSpace(localOffset or Vector3.new(0, 0, 0))
			local _, mx = H.aabb(part)
			local floor = floorUnder(Vector3.new(world.X, mx.Y, world.Z), mx.Y + 0.1)
			return Vector3.new(world.X, floor + 3, world.Z) -- an R15 root stands ~3 studs over its floor
		end
		for _, part in ipairs(hazards) do
			local factor = part:GetAttribute("Factor")
			humanoid.WalkSpeed = 40
			standAt(Vector3.new(part.CFrame.Position.X, groundY + 3, 0)) -- main street: reset
			local speed = standAt(standingPoint(part))
			T.check(speed <= 40 * factor + 1e-6, "A8: standing in %s (Factor %.2f) leaves WalkSpeed %.2f, expected %.2f", part:GetFullName(), factor, speed, 40 * factor)
			local back = standAt(Vector3.new(part.CFrame.Position.X, groundY + 3, 0))
			T.check(math.abs(back - 40) < 1e-6, "A8: stepping out of %s onto the main street must restore WalkSpeed 40, got %.2f", part:GetFullName(), back)
			-- round spills/puddles (Cylinder discs on their side) slow inside their circle only
			if part:IsA("Part") and part.Shape == roblox.Enum.PartType.Cylinder and math.abs(part.CFrame.XVector.Y) > 0.99 then
				local r = math.min(part.Size.Y, part.Size.Z) / 2
				local inside = standAt(standingPoint(part, Vector3.new(0, 0.55 * r, 0.55 * r)))
				T.check(inside < 40, "A8: %s must slow inside its circle", part:GetFullName())
				standAt(Vector3.new(part.CFrame.Position.X, groundY + 3, 0))
				local cornerPoint = standingPoint(part, Vector3.new(0, 0.85 * r, 0.85 * r))
				local covered = false -- another hazard under the same corner would legitimately slow it
				for _, other in ipairs(hazards) do
					if other ~= part then
						local omn, omx = H.aabb(other)
						if cornerPoint.X >= omn.X and cornerPoint.X <= omx.X and cornerPoint.Z >= omn.Z and cornerPoint.Z <= omx.Z then
							covered = true
						end
					end
				end
				if not covered then
					local corner = standAt(cornerPoint)
					T.check(math.abs(corner - 40) < 1e-6, "A8: %s must not slow outside its circle (square corner), got %.2f", part:GetFullName(), corner)
				end
			end
		end

		-- dynamic hazards: tracked when added, forgotten when removed; strongest slow wins; never in the hub
		local holder = roblox.Instance.new("Folder") -- detached: the shared place is never mutated
		local function fakeHazard(pos, size, factor)
			local p = roblox.Instance.new("Part")
			p.Size = size
			p.CFrame = roblox.CFrame.new(pos)
			p:SetAttribute("StageHazard", "Slow")
			p:SetAttribute("Factor", factor)
			p.Parent = holder -- Parent ~= nil: the service drops parts whose Parent is nil
			table.insert(fakeParts, p)
			added:Fire(p)
			return p
		end
		humanoid.WalkSpeed = 40
		standAt(Vector3.new(37, groundY + 3, 0))
		local streetX = 150
		local weak = fakeHazard(Vector3.new(streetX, groundY + 0.2, 40), Vector3.new(10, 0.4, 10), 0.7)
		local strong = fakeHazard(Vector3.new(streetX, groundY + 0.2, 40), Vector3.new(6, 0.4, 6), 0.5)
		local both = standAt(Vector3.new(streetX, groundY + 3, 40))
		T.check(math.abs(both - 20) < 1e-6, "A8: overlapping hazards 0.7 and 0.5 must apply the strongest slow (20), got %.2f", both)
		humanoid.WalkSpeed = 60 -- a speed upgrade while slowed becomes the new base
		local upgraded = standAt(Vector3.new(streetX, groundY + 3, 40))
		T.check(math.abs(upgraded - 30) < 1e-6, "A8: a WalkSpeed change while slowed must become the new base (60 x 0.5 = 30), got %.2f", upgraded)
		local restored = standAt(Vector3.new(streetX, groundY + 3, 0))
		T.check(math.abs(restored - 60) < 1e-6, "A8: leaving the hazard must restore the new base 60, got %.2f", restored)
		strong.Parent = nil
		removing:Fire(strong)
		local weakOnly = standAt(Vector3.new(streetX, groundY + 3, 40))
		T.check(math.abs(weakOnly - 42) < 1e-6, "A8: a removed hazard must stop slowing (60 x 0.7 = 42), got %.2f", weakOnly)
		standAt(Vector3.new(streetX, groundY + 3, 0))
		attrs.IsTrapped = true
		local trapped = standAt(Vector3.new(streetX, groundY + 3, 40))
		T.check(math.abs(trapped - 60) < 1e-6, "A8: a trapped (GearService-frozen) player must be left alone, got %.2f", trapped)
		attrs.IsTrapped = nil
		standAt(Vector3.new(streetX, groundY + 3, 0))
		weak.Parent = nil
		local hubHazard = fakeHazard(Vector3.new(50, groundY + 0.2, 30), Vector3.new(10, 0.4, 10), 0.5)
		local hub = standAt(Vector3.new(50, groundY + 3, 30))
		T.check(math.abs(hub - 60) < 1e-6, "A8: nothing slows anyone in the hub (X <= 75), got %.2f", hub)
		hubHazard.Parent = nil
		T.check(#sched.errors == 0, "StageHazardService threads errored: %s", table.concat(sched.errors, " | "))
		T.check(#warnings == 0, "StageHazardService warned: %s", table.concat(warnings, " | "))
	end
end

---------------------------------------------------------------------------------------------------
-- 8. A9 StageAmbience: lighting preset by the local player's X (sandboxed run against LightingsController)
---------------------------------------------------------------------------------------------------
local ambience = sps and H.path(sps, "Game/StageAmbience")
if T.check(ambience ~= nil and ambience.ClassName == "LocalScript", "StarterPlayerScripts.Game.StageAmbience (LocalScript) missing (A9)") then
	local lcModule = H.path(rs, "Library/Client/LightingsController")
	local lcSrc = lcModule and lcModule.Source or ""
	T.check(string.find(lcSrc, "function t1.SetModifier%(p%d+, s%d+: string, p%d+: %(%(%.%.%.any%) %-> %.%.%.any%), n%d+: number%?, n%d+: number%?%)") ~= nil
		and H.has(lcSrc, "function t1.ClearModifier("), "A9: LightingsController must expose SetModifier(id, transform, priority?, seconds?) / ClearModifier(id, seconds?)")
	local resetCycle = H.path(rs, "Directory/AreaEggResetCycle")
	local nightPriority = resetCycle and tonumber(string.match(resetCycle.Source, "LightingModifierPriority%s*=%s*([%d%.]+)"))

	-- the transforms run on the serialized Lighting (LightingsCore.Serialize): build it from the place's Lighting
	local lighting = place:GetService("Lighting")
	local base = {}
	for _, key in ipairs({ "Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
		"OutdoorAmbient", "ShadowSoftness", "ClockTime", "GeographicLatitude", "ExposureCompensation", "FogColor", "FogEnd", "FogStart" }) do
		local ok, value = pcall(function()
			return lighting[key]
		end)
		if ok then
			base[key] = value
		end
	end
	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		base.Atmosphere = { Density = atmosphere.Density, Offset = atmosphere.Offset, Color = atmosphere.Color, Decay = atmosphere.Decay,
			Glare = atmosphere.Glare, Haze = atmosphere.Haze }
	end
	local cc = lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then
		base.ColorCorrection = { Brightness = cc.Brightness, Contrast = cc.Contrast, Enabled = cc.Enabled, Saturation = cc.Saturation, TintColor = cc.TintColor }
	end

	local sched = newScheduler()
	local lc = { calls = {}, active = nil }
	function lc:SetModifier(id, transform, priority, seconds)
		table.insert(self.calls, { "Set", id, transform, priority, seconds })
		self.active = transform
	end
	function lc:ClearModifier(id, seconds)
		table.insert(self.calls, { "Clear", id, seconds })
		self.active = nil
	end
	local LC_TOKEN = {}
	local function node(depth)
		return { WaitForChild = function(_, name)
			if name == "LightingsController" then
				return LC_TOKEN
			end
			return node(depth + 1)
		end }
	end
	local root = { Position = Vector3.new(37, groundY + 3, 0) }
	local character = { FindFirstChild = function(_, name)
		return if name == "HumanoidRootPart" then root else nil
	end }
	local warnings = {}
	local chunk, err = H.sandbox(ambience.Source, {
		game = { GetService = function(_, name)
			if name == "Players" then
				return { LocalPlayer = { Character = character } }
			elseif name == "ReplicatedStorage" then
				return node(0)
			end
			return nil
		end },
		require = function(module)
			if module == LC_TOKEN then
				return lc
			end
			error("StageAmbience required an unexpected module")
		end,
		task = sched.task,
		Color3 = roblox.Color3,
		warn = function(...)
			table.insert(warnings, table.concat({ ... }, " "))
		end,
	}, "StageAmbience")
	if T.check(chunk ~= nil, "StageAmbience does not load: %s", tostring(err)) then
		sched.task.spawn(chunk)
		T.check(#sched.threads == 1, "StageAmbience must keep polling (task.wait loop)")

		local function snapshot(t)
			local out = {}
			for k, v in pairs(t) do
				out[k] = if type(v) == "table" then snapshot(v) else v
			end
			return out
		end
		local function sameShape(a, b, path)
			for k, v in pairs(a) do
				local w = b[k]
				if typeof(w) ~= typeof(v) then
					return false, path .. k
				end
				if type(v) == "table" then
					local ok, where = sameShape(v, w, path .. k .. ".")
					if not ok then
						return false, where
					end
				end
			end
			return true
		end
		local function equalDeep(a, b)
			for k, v in pairs(a) do
				if type(v) == "table" then
					if type(b[k]) ~= "table" or not equalDeep(v, b[k]) then
						return false
					end
				elseif b[k] ~= v then
					return false
				end
			end
			return true
		end
		local expectations = {
			[2] = function(out)
				local tint = out.ColorCorrection and out.ColorCorrection.TintColor
				return (base.Brightness == nil or out.Brightness < base.Brightness) and tint ~= nil and tint.B > tint.R, "dark and rainy blue"
			end,
			[3] = function(out)
				return out.ColorCorrection ~= nil and out.ColorCorrection.Saturation > (base.ColorCorrection and base.ColorCorrection.Saturation or 0), "saturated"
			end,
			[5] = function(out)
				return out.ColorCorrection ~= nil and out.ColorCorrection.Saturation > (base.ColorCorrection and base.ColorCorrection.Saturation or 0), "saturated"
			end,
			[6] = function(out)
				local tint = out.ColorCorrection and out.ColorCorrection.TintColor
				return tint ~= nil and tint.R > tint.B and (base.OutdoorAmbient == nil or out.OutdoorAmbient.R > out.OutdoorAmbient.B), "warm"
			end,
		}
		local route = { { 37, 0 } }
		for _, stage in ipairs(PLAN.STAGES) do
			table.insert(route, { stage.xMin + 3, stage.number })
			table.insert(route, { (stage.xMin + stage.xMax) / 2, stage.number })
			table.insert(route, { stage.xMax - 3, stage.number })
		end
		table.insert(route, { 50, 0 })
		for _, step in ipairs(route) do
			root.Position = Vector3.new(step[1], groundY + 3, -30)
			sched.tick()
			local stageNumber = step[2]
			local expect = expectations[stageNumber]
			if expect then
				if T.check(lc.active ~= nil, "A9: at X %.0f (stage %d) the stage lighting preset must be active", step[1], stageNumber) then
					local before = snapshot(base)
					local ok, out = pcall(lc.active, base)
					if T.check(ok and type(out) == "table", "A9: stage %d lighting transform failed: %s", stageNumber, tostring(out)) then
						local good, what = expect(out)
						T.check(good, "A9: stage %d lighting must be %s", stageNumber, what)
						local shapeOk, where = sameShape(base, out, "")
						T.check(shapeOk, "A9: stage %d transform changed the type of %s (LightingsCore.Lerp needs every field)", stageNumber, tostring(where))
						local ccOut = out.ColorCorrection
						T.check(ccOut and ccOut.Brightness and ccOut.Contrast and ccOut.Enabled ~= nil and ccOut.Saturation and ccOut.TintColor,
							"A9: stage %d ColorCorrection must carry every field LightingsCore lerps", stageNumber)
						T.check(equalDeep(before, base), "A9: the stage %d transform must not mutate the lighting config it is given", stageNumber)
					end
				end
			else
				T.check(lc.active == nil, "A9: at X %.0f (%s) the default lighting must be used", step[1], stageNumber == 0 and "hub" or ("stage " .. stageNumber))
			end
		end
		local sets = 0
		for _, call in ipairs(lc.calls) do
			if call[1] == "Set" then
				sets += 1
				T.check(call[2] == "StageAmbience", "A9: modifier id must be StageAmbience")
				T.check(type(call[5]) == "number" and call[5] > 0, "A9: stage lighting must tween (transition seconds > 0)")
				T.check(type(call[4]) == "number" and nightPriority ~= nil and call[4] < nightPriority,
					"A9: stage ambience priority %s must stay below the night reset lighting (%s)", tostring(call[4]), tostring(nightPriority))
			end
		end
		T.check(sets == 4, "A9: walking the 6 stages must switch the preset 4 times (stages 2, 3, 5, 6), got %d", sets)
		T.check(#sched.errors == 0, "StageAmbience errored: %s", table.concat(sched.errors, " | "))
		T.check(#warnings == 0, "StageAmbience warned: %s", table.concat(warnings, " | "))
	end
end

---------------------------------------------------------------------------------------------------
-- 9. A1 retired-zone tolerance: nothing waits on or indexes a retired zone
---------------------------------------------------------------------------------------------------
do
	local offenders = {}
	for fullName, source in pairs(H.allSources()) do
		for _, key in ipairs(PLAN.RETIRED) do
			local k = string.gsub(key, " ", "%%s")
			local patterns = {
				"WaitForChild%(%s*[\"']" .. k .. "[\"']%s*%)", -- infinite yield on a destroyed zone
				"GuardAreas%s*%.%s*" .. k .. "[^%w]",
				"GuardAreas%s*%[%s*[\"']" .. k .. "[\"']%s*%]",
				"ZoneFloor_" .. k,
			}
			for _, pattern in ipairs(patterns) do
				if string.find(source, pattern) then
					table.insert(offenders, fullName .. " (" .. key .. ")")
				end
			end
		end
	end
	T.check(#offenders == 0, "A1: scripts still wait on / index retired zones: %s", table.concat(offenders, ", ", 1, math.min(#offenders, 5)))
	local retiredLists = {
		{ "GuardChaseService", chase },
		{ "GuardAreas client", clientSrc("Game/GuardAreas") },
		{ "VillainChaseFx", clientSrc("Game/VillainChaseFx") },
	}
	for _, entry in ipairs(retiredLists) do
		for _, key in ipairs(PLAN.RETIRED) do
			T.check(H.has(entry[2], "[\"" .. key .. "\"] = true") or H.has(entry[2], key .. " = true"), "A1: %s must skip the retired zone %s", entry[1], key)
		end
	end
	-- D5: the retired zones' area and guard configs are removed; nothing looks them up by name any more
	local guardsIndex = H.path(rs, "Directory/Guards/_Index")
	for _, key in ipairs(PLAN.RETIRED) do
		T.check(guardsIndex and guardsIndex:FindFirstChild(key) == nil, "D5: Directory.Guards._Index.%s must be removed with its retired area config", key)
	end
	for _, stage in ipairs(PLAN.STAGES) do
		T.check(guardsIndex and guardsIndex:FindFirstChild(stage.key) ~= nil, "Directory.Guards._Index.%s missing", stage.key)
	end
	T.check(guardsIndex and #guardsIndex:GetChildren() == #PLAN.STAGES, "Directory.Guards._Index must hold exactly the %d stage guards, found %d", #PLAN.STAGES,
		guardsIndex and #guardsIndex:GetChildren() or 0)
	local lookups = {}
	for fullName, source in pairs(H.allSources()) do
		local lineNo = 0
		for line in string.gmatch(source .. "\n", "([^\n]*)\n") do
			lineNo += 1
			local code = string.match(line, "^(.-)%-%-") or line -- (naive comment strip, as the build's own scan)
			if code ~= "" and not string.find(code, "Rarit", 1, true) then
				for _, key in ipairs(PLAN.RETIRED) do
					local k = string.gsub(key, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
					local q = "[\"']" .. k .. "[\"']"
					local hit = string.find(code, "Directory%s*%[%s*" .. q .. "%s*%]") or string.find(code, "WaitForChild%s*%(%s*" .. q)
						or (string.match(key, "^[%a_][%w_]*$") and string.find(code, "Directory%." .. k .. "%f[^%w_]"))
					if hit then
						table.insert(lookups, string.format("%s:%d (%s)", fullName, lineNo, key))
					end
				end
			end
		end
	end
	T.check(#lookups == 0, "D5: scripts still look up a removed retired-zone directory entry: %s", table.concat(lookups, ", ", 1, math.min(#lookups, 5)))
end

---------------------------------------------------------------------------------------------------
-- 10. Presentation contracts: escape burst only on a real claim, hero auras honour Hide Other Pets
---------------------------------------------------------------------------------------------------
do
	local grant = H.extractFunction(areaEgg, "grantAreaEggClaim") or ""
	local _, fires = string.gsub(areaEgg, "AreaEggClaimFeedbackRemote:FireClient", "")
	T.check(H.has(grant, "AreaEggClaimFeedbackRemote:FireClient") and fires == 1, "ClaimFeedback must be fired only by grantAreaEggClaim (a bounty-paying claim)")
	local claimCalls = 0
	for call in string.gmatch(areaEgg, "claimAreaEgg%(player, record%)") do
		claimCalls += 1
	end
	local withoutDefinition = string.gsub(areaEgg, "local function grantAreaEggClaim%(", "")
	T.check(claimCalls >= 1 and not string.find(withoutDefinition, "[^%w]grantAreaEggClaim%(player"),
		"claims go through claimAreaEgg (in-flight guard), never grantAreaEggClaim directly")

	local vfx = clientSrc("Game/SabVfxController")
	if T.check(vfx ~= "", "SabVfxController missing") then
		local claimHandler = string.match(vfx, "connectRemote%(\"Eggs: AreaEggClaimFeedback\"(.-)\nend%)")
		local carryHandler = string.match(vfx, "connectRemote%(\"Eggs: AreaEggCarryState\"(.-)\nend%)")
		T.check(claimHandler ~= nil and H.has(claimHandler, "Burst_Escape"), "Burst_Escape must play on Eggs: AreaEggClaimFeedback (a real escape)")
		T.check(carryHandler ~= nil and not H.has(carryHandler, "Burst_Escape"), "a carry that ends any other way (catch, knock, drop) must not play Burst_Escape")
		T.check(H.has(vfx, "\"HideOtherPets\"") and H.has(vfx, "GetAttribute(\"OwnerUserId\")"), "hero auras must honour Hide Other Pets (OwnerUserId)")
		T.check(H.has(networkInit, "\"Eggs: AreaEggClaimFeedback\""), "NetworkInit must create Eggs: AreaEggClaimFeedback")
	end
	local itemDisplay = H.path(rs, "Library/Modules/ItemDisplay")
	local wander = itemDisplay and string.match(itemDisplay.Source, "function t1%.CreateWanderingAssetModel(.-)\nend")
	local stamp = wander and string.find(wander, "SetAttribute(\"OwnerUserId\"", 1, true)
	local parent = wander and string.find(wander, "%.Parent%s*=")
	T.check(stamp ~= nil and parent ~= nil and stamp < parent, "ItemDisplay.CreateWanderingAssetModel must stamp OwnerUserId before parenting (SabVfxController relies on it)")
end
