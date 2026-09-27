-- ServerScriptService.Controllers.GuardChaseService
-- Server-authoritative zone villain chase (refactor contract C3).
--
-- Every GuardAreas zone flagged ServerChase=true is driven here instead of by the per-client
-- Forest/GenericGuardRuntime clones: the authored Workspace guard itself (an R15 villain with a
-- Humanoid, see contract C2) sleeps anchored at its post, wakes when an egg from its zone is
-- carried, chases the closest carrier with PathfindingService (straight MoveTo fallback), catches
-- on the server, and walks dropped eggs back to their nest.
--
-- State machine per guard (mirrored to the guard's GuardState attribute):
--   Sleeping --carry--> Waking (0.63 s) --> Chasing --catch/escape--> Retrieving --> Returning --> Sleeping
--   Returning/Retrieving go straight back to Chasing when a new carrier of this zone appears.
--
-- AreaEggService owns all egg state and hands this module its callbacks through Init() (no circular
-- require). This module never mutates egg records itself.
--
-- Villain chase signatures (docs/STAGES_PLAN.md §1), keyed by the guard's HeroId: the movement side
-- lives here (Darkseid slow-then-surge, Carnage leaps, Frieza hover, beam/roar timing); the looks live
-- in StarterPlayerScripts.Game.VillainChaseFx, driven by the guard attributes ChaseSignature,
-- Hovering and ChaseFx ("<Kind>;<seq>;<targetUserId>;<seconds>"). Unknown HeroIds chase plainly.
-- ChaseSpeedFactor (number) is the signature's steady-speed equivalent, derived here from SIGNATURES; the client's
-- GuardEscapeSignController multiplies the zone WalkSpeed by it for the stage's RequiredSpeedSign.
-- Only the 6 stage zones are driven; retired legacy zones (Abyss Ocean, Prehistoric, Cosmic) are skipped
-- if they are still in the place.
--
-- Spawn on pickup (STAGES_PLAN A2): the villain sleeps at its stage's VillainPost; when an egg is picked up
-- it appears (ChaseFx "Spawn") on the main street ~SPAWN_DISTANCE from the carrier, on the side away from
-- the hub, unless it is already that close on that far side, wakes there and chases. Afterwards it walks back to its post,
-- or vanishes and reappears there (ChaseFx "Vanish") when far away or stuck.
-- Catches are 3D (A3): flat reach hitDistance * (0.6 + 0.4 * scale), |dy| <= 2.5 * scale + 3, and a clear
-- line between villain and carrier.
--
-- Cold start (owner 2026-09-23: "the first time you steal, the villain behaves dumb"): the first chase of a server was
-- the first ComputeAsync in that stage, which has to build the stage's navmesh first (the villain held still while the
-- route computed, then walked back to where the route started), and the first time the run/attack tracks played. So
-- right after setup every stage is routed once with its villain's own agent (post, nests, street; warmUpPaths), the
-- tracks are awaited and their Priority/Looped re-applied once loaded (primeTracks), a route computed while the villain
-- kept moving resumes from where it is (resumeWaypointIndex), a villain waiting for its first route closes in along the
-- main street, and every release from anchored starts with no stale velocity, the server as network owner and a
-- standing Humanoid (releaseRoot). Clients preload the chase animations and villain meshes (Game.AssetPreloader).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local PathfindingService = game:GetService("PathfindingService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GuardChaseService = {}

local GUARD_COLLISION_GROUP = "Guards"
local PLAYER_COLLISION_GROUP = "Players"
local NPC_COLLISION_GROUP = "NPCs"

local STATE_SLEEPING = "Sleeping"
local STATE_WAKING = "Waking"
local STATE_CHASING = "Chasing"
local STATE_RETURNING = "Returning"
local STATE_RETRIEVING = "Retrieving"

local DEFAULT_WAKING_DURATION = 0.63
local ATTACK_COOLDOWN = 0.75
local SAFE_ZONE_MAX_X = 75 -- fallback when AreaEggService does not provide IsInSafeZone
local MIN_GUARD_X = 80 -- the guard never steps closer to the safe zone than this
local MOVE_UPDATE_INTERVAL = 0.1
local TARGET_SCAN_INTERVAL = 0.25
local SLEEP_SCAN_INTERVAL = 0.5
local PATH_RECOMPUTE_INTERVAL = 0.3
local PATH_GOAL_REUSE_DISTANCE = 12
local STRAIGHT_LINE_DISTANCE = 25
local LOOKAHEAD_SECONDS = 0.35
local HIT_BASE_PAD = 0.75
local HIT_LATENCY_SECONDS = 0.1 -- client-owned characters replicate ~ping late
local HIT_MAX_LATENCY_PAD = 6
local LEAD_MAX_SECONDS = 0.35
local DEFAULT_FLAT_RADIUS = 20
local MIN_WALK_SPEED = 8
local MAX_WALK_SPEED = 360
local MAX_SPEED_FACTOR = 3 -- far-away catch-up never exceeds 3x the zone speed
local RETURN_SPEED_MULTIPLIER = 1.5
local RECOVERY_SPEED_MULTIPLIER = 1.6 -- re-stealing a dropped egg makes the villain angrier for a while
local RECOVERY_DURATION = 8
local HOME_SNAP_DISTANCE = 4
local VOID_Y = -200
local PROGRESS_DISTANCE = 3
local NO_PROGRESS_SECONDS = 6
local RETURN_MIN_SECONDS = 6
local RETURN_MAX_SECONDS = 25
local CHASE_REPATH_STUCK_SECONDS = 3
local CHASE_GIVE_UP_STUCK_SECONDS = 9
local OUT_OF_REACH_GIVE_UP_SECONDS = 4 -- standing on its goal yet unable to touch the carrier this long: give up on them
local IGNORE_RELEASE_DISTANCE = 6 -- a carrier given up on is chased again once it moves this far back within reach
local RETRIEVE_REACH = 6
local RETRIEVE_TIMEOUT = 15
local ATTACK_PAUSE = 0.6
local RETRIEVE_PICKUP_PAUSE = 0.45 -- the villain stops this long to lift a dropped egg before carrying it home
local NETWORK_OWNER_REFRESH = 2
local SETUP_WAIT_SECONDS = 15
local RUN_ANIMATION_BASE_SPEED = 16

-- Pathing through stage environments (buildings/obstacles off a clear main street |Z| <= 12).
local STREET_HALF_WIDTH = 10 -- fallback route: the same X on the main street, kept 2 studs inside its edge
local PATH_FAIL_FALLBACK_SECONDS = 1.5 -- after a failed path to the target, route to the street point this long
local LOW_PROBE_HEIGHT = 1.6 -- straight-line probe just above step height (curbs below this are walkable)
local STRAIGHT_MAX_RISE = 6.5 -- a goal this far above the guard's floor sits on a ledge: only a path gets there
local GROUND_PROBE_DEPTH = 40
local LINE_TOLERANCE = 0.5 -- past X = MIN_GUARD_X - this, westward velocity is cancelled
local LINE_HARD_TOLERANCE = 2 -- past this, the guard is put back on the line
local WAYPOINT_REACH = 2.5 -- a waypoint this close (or within one update's travel) counts as reached
local MAX_LOOKAHEAD_WAYPOINTS = 2 -- aim at most this many waypoints further, and only along a clear line
local MIN_MOVE_UPDATE_INTERVAL = 1 / 30 -- fast villains re-steer more often so no update overshoots a waypoint
local MOVE_UPDATE_TRAVEL = 4 -- studs a villain may cover between two steering updates

-- Spawn on pickup (A2) and the trip back to the post.
local SPAWN_DISTANCE = 35 -- the villain appears this far from the carrier, on the side away from the hub
local SPAWN_MIN_DISTANCE = 18 -- a spot squeezed closer than this (stage end) is not used: it starts from where it is
local SPAWN_EDGE_MARGIN = 6 -- spawn spots stay this far inside the stage's X range
local SPAWN_FLOOR_PROBE_ABOVE = 8 -- floor probe starts this far above the post's floor (street overheads are >= 12 up)
local RETURN_TELEPORT_DISTANCE = 160 -- farther than this from its post after a chase: vanish and reappear there

-- ChaseSpeedFactor (see resolveChaseSpeedFactor): a replay of a straight run from the far end of the stage.
local SPEED_FACTOR_SIM_STEP = 1 / 60
local SPEED_FACTOR_MIN = 0.4 -- carrier speed search range, as multiples of the zone WalkSpeed
local SPEED_FACTOR_MAX = 4
local SPEED_FACTOR_COARSE_STEP = 0.05 -- scanned downwards from the top, then refined by bisection
local SPEED_FACTOR_REFINE_STEPS = 8
local SPEED_FACTOR_MIN_RUN = 40 -- studs from the far end of the stage to the safe zone
local SPEED_FACTOR_DEFAULT_RUN = 240 -- used when the stage has no Bounds part

-- Cold-start warm-up (see the header): one route per point a chase of the stage runs between, after every zone is set up.
local WARMUP_SETUP_TIMEOUT = 20 -- start the warm-up anyway if a zone's setup is still waiting on its model
local WARMUP_START_DELAY = 1
local WARMUP_STEP_WAIT = 0.05 -- between two warm-up routes, so the navmesh builds spread over several frames
local WARMUP_MAX_TARGETS = 20 -- per stage: post, stage ends on the street, X line, nests
local TRACK_LOAD_TIMEOUT = 15

-- 3D catch (A3): flat reach hitDistance * (REACH_FACTOR_BASE + REACH_FACTOR_PER_SCALE * scale), height difference
-- between the two roots at most VERTICAL_CATCH_BASE + VERTICAL_CATCH_PER_SCALE * scale.
local REACH_FACTOR_BASE = 0.6
local REACH_FACTOR_PER_SCALE = 0.4
local VERTICAL_CATCH_BASE = 3
local VERTICAL_CATCH_PER_SCALE = 2.5

-- Mirrored in StarterPlayerScripts.Game.AssetPreloader (clients download them at join, not mid-chase).
local ANIMATION_IDS = {
	Run = "rbxassetid://507767714",
	Idle = "rbxassetid://507766388",
	Attack = "rbxassetid://522635514",
}
local ANIMATION_PRIORITIES = {
	Run = Enum.AnimationPriority.Movement,
	Idle = Enum.AnimationPriority.Idle,
	Attack = Enum.AnimationPriority.Action,
}

-- Game plan: 6 stages keep the internal zone keys Forest..Volcano; these legacy zones are out of play.
local RETIRED_ZONES = {
	["Abyss Ocean"] = true,
	Prehistoric = true,
	Cosmic = true,
}

-- Same per-zone knockback the old client runtime used (GenericGuardRuntime KNOCKBACK_FORCE_BY_ZONE).
local KNOCKBACK_FORCE_BY_ZONE = {
	Forest = 55,
	Snow = 65,
	Jungle = 75,
	Desert = 85,
	Volcano = 95,
	Lake = 115,
}
local DEFAULT_KNOCKBACK_FORCE = 55

-- Used only when ReplicatedStorage.Directory.Guards cannot be required on the server.
local FALLBACK_CONFIG = {
	Forest = { WalkSpeed = 16, HitDistance = 2.5 },
	Lake = { WalkSpeed = 35, HitDistance = 3 },
	Desert = { WalkSpeed = 62, HitDistance = 4 },
	Jungle = { WalkSpeed = 88, HitDistance = 3 },
	Snow = { WalkSpeed = 102, HitDistance = 3 },
	Volcano = { WalkSpeed = 122, HitDistance = 5 },
}

-- Per-villain chase signatures. Distances in studs, times in seconds, factors multiply the chase speed.
-- Surge and Leap raise the steady speed a carrier needs, so they set the stage's real requirement: resolveChaseSpeedFactor
-- turns them into the guard's ChaseSpeedFactor for the RequiredSpeedSign. Keep the stage order when tuning them:
-- from the farthest EggSpots a steady carrier escapes Darkseid (Lake 35) at ~39.5 WalkSpeed, Carnage (Desert 62) at
-- ~69-71 and the plain Shigaraki (Jungle 88) at ~86, so each stage still needs more speed than the one before it.
local SIGNATURES = {
	Thanos = {}, -- heavy footsteps + proximity camera shake: client only
	Darkseid = { Surge = { SlowFactor = 0.8, SlowSeconds = 2.6, SurgeFactor = 1.75, SurgeSeconds = 1.1 } },
	Carnage = {
		-- Scripted lunge, never a Humanoid jump: a speed burst along the current path while HipHeight follows
		-- an arc (ArcHeight * RigScale at the apex), so the body visibly bounds forward.
		Leap = {
			MinDistance = 9,
			MaxDistance = 38,
			FirstDelay = 1.2,
			Cooldown = 3.6,
			Seconds = 0.6,
			SpeedFactor = 1.5, -- still a visible lunge (93 vs a ~71 carrier); 1.9 made stage 3 need ~86, above stage 4
			ArcHeight = 3.5,
			LineMargin = 4, -- no lunge at a carrier this close to the X line
		},
	},
	Shigaraki = {}, -- decay particle trail: client only
	Frieza = {
		Hover = { Height = 1.8, LeanDegrees = 14 },
		Beam = { MinDistance = 8, Range = 70, FirstDelay = 2, Cooldown = 5.5, Seconds = 0.6 },
	},
	Kaido = { Roar = { Range = 34, FirstDelay = 1.5, Cooldown = 7, Seconds = 1.2 } },
}

-- HeroId -> signature key (case/punctuation-insensitive; "Kaidou", "Tomura_Shigaraki" ... still match).
local SIGNATURE_ALIASES = {
	{ "thanos", "Thanos" },
	{ "darkseid", "Darkseid" },
	{ "carnage", "Carnage" },
	{ "shigaraki", "Shigaraki" },
	{ "frieza", "Frieza" },
	{ "freeza", "Frieza" },
	{ "kaido", "Kaido" },
}

local MOVING_STATES = {
	Chasing = true,
	Returning = true,
	Retrieving = true,
}

local callbacks = {}
local guards = {} -- zoneName -> guard state table
local initialized = false
local warned = {}
local guardsDirectory = nil -- nil = not loaded yet, false = unavailable
local wakeUpRemote = nil
local serverHitRemote = nil
local characterConnections = {} -- Player -> RBXScriptConnection

local GuardChasePolicy = nil -- RS GuardChasePolicy, loaded by the setup thread

local function warnOnce(key, message)
	if warned[key] then
		return
	end
	warned[key] = true
	warn("[GuardChaseService] " .. message)
end

-- Shared ReplicatedStorage modules are required from the setup thread with a deadline, so a module
-- that yields on the server can never stall AreaEggService (and with it the Bootstrap chain).
local function requireWithTimeout(getModule, timeout)
	local done, ok, result = false, false, nil
	task.spawn(function()
		ok, result = pcall(function()
			return require(getModule())
		end)
		done = true
	end)
	local deadline = os.clock() + timeout
	while not done and os.clock() < deadline do
		task.wait(0.1)
	end
	if not done then
		return false, "timed out"
	end
	return ok, result
end

local function flatDistance(a, b)
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

local function clampGoal(position)
	if position.X < MIN_GUARD_X then
		return Vector3.new(MIN_GUARD_X, position.Y, position.Z)
	end
	return position
end

-- Same X, on the stage's main street (kept clear of anything collidable by the environment builders).
local function streetPoint(position)
	return Vector3.new(position.X, position.Y, math.clamp(position.Z, -STREET_HALF_WIDTH, STREET_HALF_WIDTH))
end

local function resolveSignatureKey(heroId)
	if type(heroId) ~= "string" or heroId == "" then
		return nil
	end
	local normalized = string.lower((string.gsub(heroId, "[^%w]", "")))
	for _, alias in ipairs(SIGNATURE_ALIASES) do
		if normalized == alias[1] then
			return alias[2]
		end
	end
	for _, alias in ipairs(SIGNATURE_ALIASES) do
		if string.find(normalized, alias[1], 1, true) then
			return alias[2]
		end
	end
	return nil
end

local function trySet(instance, property, value)
	pcall(function()
		instance[property] = value
	end)
end

local function setAttr(g, name, value)
	if g.guard:GetAttribute(name) ~= value then
		g.guard:SetAttribute(name, value)
	end
end

local function isInSafeZone(position)
	local check = callbacks.IsInSafeZone
	if check then
		local ok, result = pcall(check, position)
		if ok then
			return result == true
		end
	end
	return position.X <= SAFE_ZONE_MAX_X
end

local function getRecord(uid)
	local get = callbacks.GetRecord
	if not get or type(uid) ~= "string" then
		return nil
	end
	local ok, record = pcall(get, uid)
	if ok and type(record) == "table" then
		return record
	end
	return nil
end

local function returnDroppedEgg(uid)
	local fn = callbacks.ReturnDroppedEggToNest
	if fn then
		local ok, err = pcall(fn, uid)
		if not ok then
			warnOnce("return-dropped", "ReturnDroppedEggToNest failed: " .. tostring(err))
		end
	end
end

-- Lifts a Dropped egg into the villain's arms (AreaEggService state GuardCarried). Returns the egg's nest position,
-- or nil when it could not be picked up (then the caller returns it to its nest the old way).
local function pickUpDroppedEgg(uid)
	local fn = callbacks.PickUpDroppedEgg
	if not fn then
		return nil
	end
	local ok, nest = pcall(fn, uid)
	if not ok then
		warnOnce("pickup-dropped", "PickUpDroppedEgg failed: " .. tostring(nest))
		return nil
	end
	return if typeof(nest) == "CFrame" then nest.Position else nil
end

-- Policy wrappers: reuse RS GuardChasePolicy when it loads, same maths inline otherwise.
local function resolveWakingDuration()
	if GuardChasePolicy and GuardChasePolicy.GetWakingDuration then
		local ok, value = pcall(GuardChasePolicy.GetWakingDuration)
		if ok and type(value) == "number" and value >= 0 and value < 5 then
			return value
		end
	end
	return DEFAULT_WAKING_DURATION
end

local function resolveHitDistance(value)
	if GuardChasePolicy and GuardChasePolicy.ResolveHitDistance then
		local ok, result = pcall(GuardChasePolicy.ResolveHitDistance, value)
		if ok and type(result) == "number" and result > 0 then
			return result
		end
	end
	return value or 3
end

local function resolveWalkSpeed(base, flatRadius, distance)
	distance = math.max(distance, 0)
	if GuardChasePolicy and GuardChasePolicy.ResolveWalkSpeed then
		local ok, speed = pcall(GuardChasePolicy.ResolveWalkSpeed, base, flatRadius, distance)
		if ok and type(speed) == "number" and speed == speed then
			return speed
		end
	end
	local radius = math.max(flatRadius, 0.001)
	if distance <= radius then
		return base
	end
	return math.min(base * ((distance / radius - 1) * 0.5 + 1), base * 4)
end

local function clampWalkSpeed(speed, base)
	local upper = math.max(MIN_WALK_SPEED, math.min(base * MAX_SPEED_FACTOR, MAX_WALK_SPEED))
	return math.clamp(speed, MIN_WALK_SPEED, upper)
end

local function loadZoneConfig(zoneName)
	local fallback = FALLBACK_CONFIG[zoneName] or { WalkSpeed = 18, HitDistance = 3 }
	local config = {
		WalkSpeed = fallback.WalkSpeed,
		HitDistance = fallback.HitDistance,
		FlatRadius = DEFAULT_FLAT_RADIUS,
	}

	if guardsDirectory then
		-- Directory.Guards is a strict table (indexing a missing zone errors), hence the pcalls.
		local ok, source = pcall(function()
			return guardsDirectory[zoneName]
		end)
		if ok and type(source) == "table" then
			for _, key in ipairs({ "WalkSpeed", "HitDistance", "FlatRadius" }) do
				local okValue, value = pcall(function()
					return source[key]
				end)
				if okValue and type(value) == "number" and value > 0 then
					config[key] = value
				end
			end
		end
	end

	return config
end

--------------------------------------------------------------------------------------------------
-- Collision groups
--------------------------------------------------------------------------------------------------

local function ensureCollisionGroups()
	-- Bootstrap registers these too (and assigns "Players" to every character); repeating it here keeps the service
	-- self-sufficient. NPC pass 2026-09-26: villains also pass through NPCs (pen heroes, podium avatars).
	pcall(function()
		for _, name in ipairs({ GUARD_COLLISION_GROUP, PLAYER_COLLISION_GROUP, NPC_COLLISION_GROUP }) do
			if not PhysicsService:IsCollisionGroupRegistered(name) then
				PhysicsService:RegisterCollisionGroup(name)
			end
		end
		PhysicsService:CollisionGroupSetCollidable(GUARD_COLLISION_GROUP, PLAYER_COLLISION_GROUP, false)
		PhysicsService:CollisionGroupSetCollidable(GUARD_COLLISION_GROUP, GUARD_COLLISION_GROUP, false)
		PhysicsService:CollisionGroupSetCollidable(GUARD_COLLISION_GROUP, NPC_COLLISION_GROUP, false)
		PhysicsService:CollisionGroupSetCollidable(PLAYER_COLLISION_GROUP, NPC_COLLISION_GROUP, false)
	end)
end

local function setCollisionGroup(part, group)
	pcall(function()
		part.CollisionGroup = group
	end)
end

local function onCharacterAdded(player, character)
	local previous = characterConnections[player]
	if previous then
		previous:Disconnect()
	end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			setCollisionGroup(descendant, PLAYER_COLLISION_GROUP)
		end
	end
	characterConnections[player] = character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			setCollisionGroup(descendant, PLAYER_COLLISION_GROUP)
		end
	end)
end

local function hookPlayer(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

--------------------------------------------------------------------------------------------------
-- Guard helpers
--------------------------------------------------------------------------------------------------

local function getLiveRoot(player)
	if not player or player.Parent ~= Players then
		return nil
	end
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function catchDistance(g, root)
	local velocity = root.AssemblyLinearVelocity
	local flatSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	return g.hitDistance + HIT_BASE_PAD + math.min(flatSpeed * HIT_LATENCY_SECONDS, HIT_MAX_LATENCY_PAD)
end

-- Root centre height above the floor the Humanoid stands on (includes Frieza's hover).
local function rootHeight(g)
	return g.humanoid.HipHeight + g.hrp.Size.Y * 0.5
end

local function castRay(g, origin, direction)
	local params = g.rayParams
	if not params then
		return nil
	end
	local ok, result = pcall(Workspace.Raycast, Workspace, origin, direction, params)
	if ok then
		return result
	end
	return nil
end

-- Where a carrier's root would be if they stood on the floor under them. A jumping carrier (FloorMaterial Air) is
-- read at that height, so a jump never lifts the chase goal off the floor (isLineClear refused every airborne goal:
-- the villain stopped, repathed and stuttered on each hop; owner 2026-09-27 "the pathfinder bugs while I jump")
-- nor makes the carrier uncatchable in mid-air. Grounded carriers (and a fall with no floor below) keep their
-- real position.
local function standingPosition(g, root)
	local position = root.Position
	local humanoid = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.FloorMaterial ~= Enum.Material.Air then
		return position
	end
	local hit = castRay(g, position, Vector3.new(0, -GROUND_PROBE_DEPTH, 0))
	if hit == nil then
		return position
	end
	local standing = hit.Position.Y + humanoid.HipHeight + root.Size.Y / 2
	return Vector3.new(position.X, math.min(position.Y, standing), position.Z)
end

-- 3D catch: within flat reach, roots at most 2.5*scale + 3 apart in height (a carrier on a roof or a
-- ledge above the villain is out of reach; a jumping one is judged where they will land), nothing solid in
-- between, never in the safe zone.
local function canCatch(g, root, distance)
	if distance > catchDistance(g, root) or isInSafeZone(root.Position) then
		return false
	end
	local origin = g.hrp.Position
	local target = root.Position
	if math.abs(standingPosition(g, root).Y - origin.Y) > VERTICAL_CATCH_BASE + VERTICAL_CATCH_PER_SCALE * g.scale then
		return false
	end
	return castRay(g, origin, target - origin) == nil
end

-- True when the guard can walk straight at `to`: nothing collidable at step height or at root height
-- along the flat line, and `to` is not up on a ledge. Stage environments put buildings, ramps and props
-- next to the main street; walking straight through them (the villain does not collide) looks broken.
local function isLineClear(g, from, to)
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if flat.Magnitude < 0.5 then
		return true
	end
	local floor = from.Y - rootHeight(g)
	if to.Y - floor > STRAIGHT_MAX_RISE then
		return false
	end
	for _, height in ipairs({ LOW_PROBE_HEIGHT, rootHeight(g) }) do
		if castRay(g, Vector3.new(from.X, floor + height, from.Z), flat) then
			return false
		end
	end
	return true
end

-- Line of sight from the villain's chest to a point (visual beams only fire when nothing blocks them).
local function hasLineOfSight(g, to)
	local origin = g.hrp.Position
	return castRay(g, origin, to - origin) == nil
end

-- Path goals are projected onto the floor under them, so a jumping carrier never asks for a mid-air goal.
local function groundPoint(g, position)
	local hit = castRay(g, position + Vector3.new(0, 2, 0), Vector3.new(0, -GROUND_PROBE_DEPTH, 0))
	if hit then
		return Vector3.new(position.X, hit.Position.Y + 1, position.Z)
	end
	return position
end

local function isGrounded(g)
	local ok, material = pcall(function()
		return g.humanoid.FloorMaterial
	end)
	return not ok or material ~= Enum.Material.Air
end

local function formatPosition(position)
	if typeof(position) ~= "Vector3" then
		return ""
	end
	return string.format("%.1f,%.1f,%.1f", position.X, position.Y, position.Z)
end

-- One-shot presentation event for the clients (VillainChaseFx). A single string attribute, so the fields
-- always arrive together: "<Kind>;<seq>;<targetUserId>;<seconds>[;<x,y,z>[;<x,y,z>]]" (seq makes repeats of
-- the same kind distinct; Spawn/Vanish carry the arrival and departure positions).
local function fireFx(g, kind, player, seconds, position, fromPosition)
	g.fxSeq += 1
	local userId = if player then player.UserId else 0
	local value = string.format("%s;%d;%d;%.2f", kind, g.fxSeq, userId, seconds or 0)
	if position then
		value ..= ";" .. formatPosition(position) .. ";" .. formatPosition(fromPosition)
	end
	g.guard:SetAttribute("ChaseFx", value)
end

-- How far a position lies past the guard's X line (0 anywhere the guard can walk up to).
local function lineGap(position)
	return math.max(MIN_GUARD_X - position.X, 0)
end

-- Living carrier of an egg from this guard's zone, outside the safe zone, to chase. Carriers the
-- X-clamped guard can touch always win over ones parked in the strip between the safe zone and its
-- line (X 75..80), so a parked carrier can never shield the others; then the closest wins. Carriers
-- this guard gave up on stay skipped until they walk back within its reach.
local function selectTarget(g)
	local getCarriers = callbacks.GetCarriersForArea
	if not getCarriers then
		return nil
	end
	local ok, carriers = pcall(getCarriers, g.zoneName)
	if not ok or type(carriers) ~= "table" then
		return nil
	end

	local origin = g.hrp.Position
	local standingReach = g.hitDistance + HIT_BASE_PAD
	local bestPlayer, bestUid, bestRoot, bestDistance, bestReachable = nil, nil, nil, math.huge, false
	for _, entry in ipairs(carriers) do
		local player = entry.Player
		local root = getLiveRoot(player)
		if root and not isInSafeZone(root.Position) then
			local position = root.Position
			local ignoredAt = g.ignored[player]
			if ignoredAt and lineGap(position) <= standingReach and flatDistance(position, ignoredAt) >= IGNORE_RELEASE_DISTANCE then
				g.ignored[player] = nil
				ignoredAt = nil
			end
			if not ignoredAt then
				local reachable = lineGap(position) <= catchDistance(g, root)
				local distance = flatDistance(origin, position)
				if (reachable and not bestReachable) or (reachable == bestReachable and distance < bestDistance) then
					bestPlayer, bestUid, bestRoot, bestDistance, bestReachable = player, entry.Uid, root, distance, reachable
				end
			end
		end
	end
	return bestPlayer, bestUid, bestRoot, bestDistance
end

local function playLoop(g, key)
	if g.currentLoop == key then
		return
	end
	local previous = g.currentLoop and g.tracks[g.currentLoop]
	if previous then
		pcall(previous.Stop, previous, 0.2)
	end
	g.currentLoop = key
	local track = g.tracks[key]
	if track then
		pcall(track.Play, track, 0.2)
	end
end

local function setWalkSpeed(g, speed)
	if math.abs(g.humanoid.WalkSpeed - speed) > 0.5 then
		g.humanoid.WalkSpeed = speed
	end
	if g.currentLoop == "Run" and g.tracks.Run then
		pcall(g.tracks.Run.AdjustSpeed, g.tracks.Run, math.clamp(speed / (RUN_ANIMATION_BASE_SPEED * g.scale), 0.8, 2.5))
	end
end

-- Frieza floats: a raised HipHeight lifts the whole body and a forward lean on the Root joint turns the
-- idle pose into a glide (no leg-run). Everyone else is untouched.
local function applyHipHeight(g, extra)
	local hover = if g.hovering then g.sig.Hover.Height else 0
	trySet(g.humanoid, "HipHeight", g.baseHipHeight + hover + (extra or 0))
end

local function setHover(g, enabled)
	local hover = g.sig and g.sig.Hover
	enabled = enabled and hover ~= nil
	if g.hovering == enabled then
		return
	end
	g.hovering = enabled
	applyHipHeight(g)
	if g.rootMotor and g.rootMotorC0 then
		local lean = if enabled then math.rad(hover.LeanDegrees or 0) else 0
		trySet(g.rootMotor, "C0", g.rootMotorC0 * CFrame.Angles(-lean, 0, 0))
	end
	setAttr(g, "Hovering", enabled)
end

local function movingLoop(g)
	return if g.hovering then "Idle" else "Run"
end

local function endLeap(g)
	if g.leapUntil ~= 0 then
		g.leapUntil = 0
		applyHipHeight(g)
	end
end

-- Carnage's lunge arc: HipHeight rises and falls over the leap (the Humanoid never jumps).
local function updateLeapArc(g, now)
	if g.leapUntil == 0 then
		return
	end
	local leap = g.sig and g.sig.Leap
	if not leap or now >= g.leapUntil then
		endLeap(g)
		return
	end
	local progress = math.clamp(1 - (g.leapUntil - now) / leap.Seconds, 0, 1)
	applyHipHeight(g, leap.ArcHeight * g.scale * math.sin(math.pi * progress))
end

local function moveInterval(speed)
	return math.clamp(MOVE_UPDATE_TRAVEL / math.max(speed, 1), MIN_MOVE_UPDATE_INTERVAL, MOVE_UPDATE_INTERVAL)
end

local function resetSignatureTimers(g, now)
	local sig = g.sig or {}
	g.surgeCycleStart = now
	g.surging = false
	endLeap(g)
	g.leapReadyAt = now + (if sig.Leap then sig.Leap.FirstDelay else 0)
	g.beamReadyAt = now + (if sig.Beam then sig.Beam.FirstDelay else 0)
	g.roarReadyAt = now + (if sig.Roar then sig.Roar.FirstDelay else 0)
end

local function claimNetworkOwnership(g, now)
	g.lastOwnerAt = now
	pcall(function()
		g.hrp:SetNetworkOwner(nil)
	end)
end

-- A villain released from anchored (post, spawn spot, wake beat) must start the leg standing: it was anchored since the
-- server loaded on its first chase, and a Humanoid never simulated (or left in Freefall/Physics by a knock) walks off
-- sluggishly or not at all. The floor under it is always there (authored post / floor-probed spawn), so Running is right;
-- if it really is in the air the Humanoid goes back to Freefall on its next step.
local function settleHumanoid(g)
	pcall(function()
		local state = g.humanoid:GetState()
		if state ~= Enum.HumanoidStateType.Running and state ~= Enum.HumanoidStateType.RunningNoPhysics then
			g.humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)
end

-- Unanchors the root (when anchored) and keeps the server as network owner. The claim runs in the same step as the
-- unanchor, before automatic ownership can hand the assembly to the thief standing next to it (SetNetworkOwner cannot
-- be called while the root is anchored), and no velocity from before the anchor carries over.
local function releaseRoot(g, now)
	local wasAnchored = g.hrp.Anchored
	if wasAnchored then
		g.hrp.Anchored = false
	end
	claimNetworkOwnership(g, now)
	if wasAnchored then
		pcall(function()
			g.hrp.AssemblyLinearVelocity = Vector3.zero
			g.hrp.AssemblyAngularVelocity = Vector3.zero
		end)
		settleHumanoid(g)
	end
end

local function invalidatePath(g)
	g.pathToken += 1
	g.waypoints = nil
	g.pathGoal = nil
	g.pathModeUntil = 0
end

local function resetProgress(g, now)
	g.progressPos = g.hrp.Position
	g.progressAt = now
end

-- Moves the whole guard so its root lands exactly on `target` (PivotTo by delta, so a
-- non-identity model pivot offset does not matter).
local function pivotRootTo(g, target)
	local delta = target * g.hrp.CFrame:Inverse()
	local ok = pcall(function()
		g.guard:PivotTo(delta * g.guard:GetPivot())
	end)
	if not ok then
		g.hrp.CFrame = target
	end
end

local function snapHome(g)
	pcall(function()
		g.humanoid:MoveTo(g.home.Position)
		g.hrp.AssemblyLinearVelocity = Vector3.zero
		g.hrp.AssemblyAngularVelocity = Vector3.zero
	end)
	g.hrp.Anchored = true
	pivotRootTo(g, g.home)
end

--------------------------------------------------------------------------------------------------
-- State transitions
--------------------------------------------------------------------------------------------------

local enterChasing, enterReturning, enterRetrieving, enterSleeping, finishChase, configureSignature

-- A villain pulled out of a retrieval while it holds an egg (sleep, return, teleport home) sets it back in its nest.
local function releaseCarriedEgg(g)
	if g.carryNest ~= nil and g.retrieveUid ~= nil then
		returnDroppedEgg(g.retrieveUid)
	end
	g.carryNest = nil
end

enterSleeping = function(g, now)
	releaseCarriedEgg(g)
	g.state = STATE_SLEEPING
	g.target = nil
	g.retrieveUid = nil
	table.clear(g.pendingDropped) -- AreaEggService's dropped-egg timer returns anything left behind
	endLeap(g)
	invalidatePath(g)
	setHover(g, false)
	snapHome(g)
	setWalkSpeed(g, g.config.WalkSpeed)
	setAttr(g, "GuardState", STATE_SLEEPING)
	setAttr(g, "Sleeping", true)
	setAttr(g, "TargetPlayer", "")
	setAttr(g, "WakeTargetPlayer", "")
	playLoop(g, "Idle")
	g.nextScanAt = now + SLEEP_SCAN_INTERVAL
end

local function enterWaking(g, now, player, root)
	releaseCarriedEgg(g)
	g.state = STATE_WAKING
	g.wakeEndsAt = now + g.wakingDuration
	g.target = nil
	endLeap(g)
	invalidatePath(g)
	setHover(g, false)
	if not g.hrp.Anchored then
		-- Woken again on the way back from a chase: stand still (anchored) for the wake beat.
		pcall(function()
			g.humanoid:MoveTo(g.hrp.Position)
			g.hrp.AssemblyLinearVelocity = Vector3.zero
			g.hrp.AssemblyAngularVelocity = Vector3.zero
		end)
		g.hrp.Anchored = true
	end
	local userId = tostring(player.UserId)
	setAttr(g, "GuardState", STATE_WAKING)
	setAttr(g, "Sleeping", false)
	setAttr(g, "WakeTargetPlayer", userId)
	setAttr(g, "TargetPlayer", userId)
	playLoop(g, "Idle")

	-- Turn towards the thief while anchored (at the post, or where it just appeared).
	if root then
		local position = g.hrp.Position
		local look = Vector3.new(root.Position.X - position.X, 0, root.Position.Z - position.Z)
		if look.Magnitude > 0.1 then
			pivotRootTo(g, CFrame.lookAt(position, position + look))
		end
	end

	if wakeUpRemote then
		pcall(wakeUpRemote.FireAllClients, wakeUpRemote, g.guard)
	end
end

enterChasing = function(g, now)
	releaseCarriedEgg(g)
	g.state = STATE_CHASING
	g.nextMoveAt = 0
	g.outOfReachSince = nil
	invalidatePath(g)
	releaseRoot(g, now)
	resetProgress(g, now)
	resetSignatureTimers(g, now)
	setHover(g, true)
	setAttr(g, "GuardState", STATE_CHASING)
	setAttr(g, "Sleeping", false)
	setAttr(g, "WakeTargetPlayer", "")
	playLoop(g, movingLoop(g))
end

enterReturning = function(g, now)
	releaseCarriedEgg(g)
	g.state = STATE_RETURNING
	g.target = nil
	g.retrieveUid = nil
	g.nextMoveAt = 0
	g.nextScanAt = now + TARGET_SCAN_INTERVAL
	invalidatePath(g)
	releaseRoot(g, now)
	resetProgress(g, now)

	local speed = clampWalkSpeed(g.config.WalkSpeed * RETURN_SPEED_MULTIPLIER, g.config.WalkSpeed)
	local distance = flatDistance(g.hrp.Position, g.home.Position)
	g.returnDeadline = now + math.clamp(distance / speed * 1.5 + 4, RETURN_MIN_SECONDS, RETURN_MAX_SECONDS)

	endLeap(g)
	setHover(g, true)
	setAttr(g, "GuardState", STATE_RETURNING)
	setAttr(g, "Sleeping", false)
	setAttr(g, "TargetPlayer", "")
	setAttr(g, "WakeTargetPlayer", "")
	playLoop(g, movingLoop(g))
end

enterRetrieving = function(g, now, uid)
	releaseCarriedEgg(g)
	g.state = STATE_RETRIEVING
	g.target = nil
	g.retrieveUid = uid
	g.retrieveStartedAt = now
	g.nextMoveAt = 0
	g.nextScanAt = now + TARGET_SCAN_INTERVAL
	invalidatePath(g)
	releaseRoot(g, now)
	resetProgress(g, now)
	endLeap(g)
	setHover(g, true)
	setAttr(g, "GuardState", STATE_RETRIEVING)
	setAttr(g, "Sleeping", false)
	setAttr(g, "TargetPlayer", "")
	setAttr(g, "WakeTargetPlayer", "")
	playLoop(g, movingLoop(g))
end

-- Nearest dropped egg of this zone that this guard knocked loose and that is still on the floor.
local function nextDroppedEgg(g)
	local bestUid, bestDistance = nil, math.huge
	local origin = g.hrp.Position
	for uid in pairs(g.pendingDropped) do
		local record = getRecord(uid)
		if not record or record.State ~= "Dropped" or typeof(record.BottomCFrame) ~= "CFrame" then
			g.pendingDropped[uid] = nil
		else
			local distance = flatDistance(origin, record.BottomCFrame.Position)
			if distance < bestDistance then
				bestUid, bestDistance = uid, distance
			end
		end
	end
	return bestUid
end

-- Vanish where it stands and reappear asleep at its post (clients play the Vanish effect at both ends).
local function vanishHome(g, now)
	local from = g.hrp.Position
	enterSleeping(g, now)
	if flatDistance(from, g.home.Position) > HOME_SNAP_DISTANCE then
		fireFx(g, "Vanish", nil, 0, g.home.Position, from)
	end
end

local function teleportHome(g, now, reason)
	warnOnce("teleport:" .. g.zoneName .. ":" .. reason, string.format("%s guard teleported home (%s)", g.zoneName, reason))
	vanishHome(g, now)
end

finishChase = function(g, now)
	g.target = nil
	local uid = nextDroppedEgg(g)
	if uid then
		enterRetrieving(g, now, uid)
	elseif flatDistance(g.hrp.Position, g.home.Position) > RETURN_TELEPORT_DISTANCE then
		vanishHome(g, now) -- chased far out of its stage: no long walk back
	else
		enterReturning(g, now)
	end
end

--------------------------------------------------------------------------------------------------
-- Movement
--------------------------------------------------------------------------------------------------

-- First waypoint to steer at when a route arrives. The villain may have moved while it computed (along the street, see
-- moveToward; a cold navmesh takes a while), so walk along the route from its start only while it keeps getting closer to
-- where the villain is now (never jumping to a later stretch that merely passes near it, e.g. behind a wall), and skip
-- the waypoint it is already past when the line to the next one is clear. A route that did not wait for anything
-- starts at 2 as before.
local function resumeWaypointIndex(g, waypoints)
	local position = g.hrp.Position
	local index = 2
	while index < #waypoints
		and flatDistance(position, waypoints[index + 1].Position) < flatDistance(position, waypoints[index].Position) do
		index += 1
	end
	if index < #waypoints then
		local a, b = waypoints[index].Position, waypoints[index + 1].Position
		local along = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local offset = Vector3.new(position.X - a.X, 0, position.Z - a.Z)
		if along.Magnitude > 0.01 and offset:Dot(along) > 0 and isLineClear(g, position, b) then
			index += 1
		end
	end
	return index
end

-- `isFallback`: the request is the street detour itself, so its failure does not re-arm the detour.
local function requestPath(g, goal, now, isFallback)
	if not g.path or g.computing or now - g.lastPathAt < PATH_RECOMPUTE_INTERVAL then
		return
	end
	g.computing = true
	g.lastPathAt = now
	g.pathToken += 1
	local token = g.pathToken
	local start = g.hrp.Position
	local target = groundPoint(g, goal)
	local path = g.path
	task.spawn(function()
		local ok = pcall(path.ComputeAsync, path, start, target)
		g.computing = false
		if g.disabled or g.pathToken ~= token then
			return
		end
		if ok and path.Status == Enum.PathStatus.Success then
			local okWaypoints, waypoints = pcall(path.GetWaypoints, path)
			if okWaypoints and type(waypoints) == "table" and #waypoints >= 2 then
				g.waypoints = waypoints
				g.waypointIndex = resumeWaypointIndex(g, waypoints)
				g.pathGoal = goal
				if not isFallback then
					g.pathFailedUntil = 0
				end
				return
			end
		end
		g.waypoints = nil
		g.pathGoal = nil
		if not isFallback then
			-- No route to the target itself (on an unreachable prop, or off the navmesh): head for the
			-- main street at the same X for a moment instead of walking into whatever is in between.
			g.pathFailedUntil = os.clock() + PATH_FAIL_FALLBACK_SECONDS
		end
	end)
end

-- Steers the Humanoid towards `goal` and returns the point it is actually heading for (the goal, or
-- the street detour), which the callers use for their progress / reach bookkeeping.
--   * close and nothing in between: straight MoveTo (smooth final approach);
--   * otherwise PathfindingService waypoints (recomputed at most every PATH_RECOMPUTE_INTERVAL, dropped
--     when the path reports Blocked);
--   * no route to the goal: straight if the line is clear, else a detour via the main street;
--   * while no route is usable yet: straight only when the line is clear, else the previous waypoints,
--     else along the main street (or hold) while the route computes; only when there is nothing else walk straight (the
--     villain does not collide, and the stall logic repaths or sends it home).
local function moveToward(g, goal, now, speed)
	local position = g.hrp.Position
	local humanoid = g.humanoid
	if not g.path then
		g.waypoints = nil
		humanoid:MoveTo(goal)
		return goal
	end

	local lineClear = nil
	local function straightIsClear()
		if lineClear == nil then
			lineClear = isLineClear(g, position, goal)
		end
		return lineClear
	end

	local isFallback = now < g.pathFailedUntil
	local closeRange = now >= g.pathModeUntil and flatDistance(position, goal) <= STRAIGHT_LINE_DISTANCE
	if (isFallback or closeRange) and straightIsClear() then
		g.waypoints = nil
		humanoid:MoveTo(goal)
		return goal
	end

	local navGoal = if isFallback then streetPoint(goal) else goal
	requestPath(g, navGoal, now, isFallback)

	local waypoints = g.waypoints
	if waypoints and g.pathGoal and flatDistance(g.pathGoal, navGoal) <= PATH_GOAL_REUSE_DISTANCE then
		-- Drop the waypoints already reached (or reached before the next steering update), then aim further
		-- ahead only while the straight line there is clear, so a fast villain never cuts a corner.
		local reach = math.max(WAYPOINT_REACH, speed * MIN_MOVE_UPDATE_INTERVAL)
		local index = g.waypointIndex
		while index < #waypoints and flatDistance(position, waypoints[index].Position) <= reach do
			index += 1
		end
		g.waypointIndex = index
		local lookahead = math.clamp(speed * LOOKAHEAD_SECONDS, 6, 40)
		local target = index
		for ahead = index + 1, math.min(#waypoints, index + MAX_LOOKAHEAD_WAYPOINTS) do
			local point = waypoints[ahead].Position
			if flatDistance(position, point) > lookahead or not isLineClear(g, position, point) then
				break
			end
			target = ahead
		end
		if target >= #waypoints then
			humanoid:MoveTo(navGoal)
		else
			humanoid:MoveTo(waypoints[target].Position)
		end
		return navGoal
	end

	if straightIsClear() then
		humanoid:MoveTo(goal)
		return goal
	end
	local staleWaypoint = waypoints and waypoints[g.waypointIndex]
	if staleWaypoint then
		-- Path to an earlier goal: still the right way round the obstacle while the new one computes.
		humanoid:MoveTo(staleWaypoint.Position)
	elseif g.computing then
		-- A route is on its way (a few frames once the stage's navmesh exists; longer on a cold one). Close in along the
		-- main street (kept clear by the environment builders) while that line is clear; never walk into the obstacle.
		local street = streetPoint(Vector3.new(goal.X, position.Y, goal.Z))
		if flatDistance(position, street) > WAYPOINT_REACH and isLineClear(g, position, street) then
			humanoid:MoveTo(street)
		else
			humanoid:MoveTo(position)
		end
	else
		humanoid:MoveTo(navGoal)
	end
	return navGoal
end

-- Returns seconds without PROGRESS_DISTANCE of movement (0 while progressing or already close).
local function stalledFor(g, now, goal, closeEnough)
	local position = g.hrp.Position
	if flatDistance(position, g.progressPos) >= PROGRESS_DISTANCE or flatDistance(position, goal) <= closeEnough then
		g.progressPos = position
		g.progressAt = now
		return 0
	end
	return now - g.progressAt
end

-- Stuck for CHASE_REPATH_STUCK_SECONDS: drop the waypoints, request a fresh path from here right away
-- and follow paths even at close range until the next check. This fires once per interval rather
-- than every tick, so the new path gets followed instead of being cancelled before it arrives.
local function repathIfStuck(g, now, stalled)
	if stalled < CHASE_REPATH_STUCK_SECONDS or now - g.lastStuckRepathAt < CHASE_REPATH_STUCK_SECONDS then
		return
	end
	g.lastStuckRepathAt = now
	g.waypoints = nil
	g.pathGoal = nil
	g.lastPathAt = -math.huge
	g.pathModeUntil = now + CHASE_REPATH_STUCK_SECONDS
end

local function isInsideZoneBounds(g, position)
	local bounds = g.bounds
	if not bounds or bounds.Parent == nil then
		return true -- no Bounds part: treat the whole map as this guard's turf
	end
	local relative = bounds.CFrame:PointToObjectSpace(position)
	local halfSize = bounds.Size * 0.5
	return math.abs(relative.X) <= halfSize.X and math.abs(relative.Z) <= halfSize.Z
end

-- Owner 2026-09-23: a villain's catch knocks the carrier into the same ragdoll as a bat hit (GearService's
-- ServerScriptService.GearRagdollRequest), flung away from the villain. Asynchronous: the chase never waits on it.
local function ragdollCaught(g, player)
	local request = ServerScriptService:FindFirstChild("GearRagdollRequest")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (request and request:IsA("BindableFunction") and root and root:IsA("BasePart")) then
		return
	end
	local away = root.Position - g.hrp.Position
	away = Vector3.new(away.X, 0, away.Z)
	local direction = if away.Magnitude > 0.05 then away.Unit else g.hrp.CFrame.LookVector
	task.spawn(function()
		pcall(request.Invoke, request, player, direction)
	end)
end

local function catchPlayer(g, player, uid, now)
	g.lastAttackAt = now
	-- the swing: a procedural punch every client plays on the villain's joints (VillainChaseFx "Punch"; owner
	-- 2026-09-27), instead of the stock tool-slash track
	fireFx(g, "Punch", player, ATTACK_PAUSE)

	if serverHitRemote then
		pcall(serverHitRemote.FireClient, serverHitRemote, player, {
			AreaId = g.zoneName,
			GuardPosition = g.hrp.Position,
			Force = g.knockbackForce,
		})
	end

	local onCaught = callbacks.OnGuardCaughtPlayer
	if onCaught then
		local ok, dropped = pcall(onCaught, player, uid, g.hrp.CFrame)
		if not ok then
			warnOnce("caught:" .. g.zoneName, "OnGuardCaughtPlayer failed for " .. g.zoneName .. ": " .. tostring(dropped))
		elseif type(dropped) == "table" and dropped.Uid and typeof(dropped.BottomCFrame) == "CFrame" then
			-- Product rule: an egg that falls inside the guard's own zone is carried back to its nest;
			-- one that falls outside stays up for grabs (AreaEggService's dropped-egg timer returns it
			-- if nobody takes it).
			if isInsideZoneBounds(g, dropped.BottomCFrame.Position) then
				g.pendingDropped[dropped.Uid] = true
			end
		end
	end

	ragdollCaught(g, player)

	-- Stand still for the swing; the dropped egg is visible for a moment before any retrieval.
	g.pauseUntil = now + ATTACK_PAUSE
	g.nextMoveAt = 0
	g.progressPos = g.hrp.Position
	g.progressAt = g.pauseUntil
	pcall(function()
		g.humanoid:MoveTo(g.hrp.Position)
	end)
end

-- Per-villain chase behaviour on top of the zone speed (see SIGNATURES). Returns the walk speed to use.
local function applySignature(g, now, player, root, distance, speed)
	local sig = g.sig
	if not sig then
		return speed
	end

	local surge = sig.Surge
	if surge then
		local phase = (now - g.surgeCycleStart) % (surge.SlowSeconds + surge.SurgeSeconds)
		local surging = phase >= surge.SlowSeconds
		if surging and not g.surging then
			fireFx(g, "Surge", player, surge.SurgeSeconds)
		end
		g.surging = surging
		speed *= if surging then surge.SurgeFactor else surge.SlowFactor
	end

	local leap = sig.Leap
	local leaping = g.leapUntil ~= 0 and now < g.leapUntil
	if leap and not leaping and now >= g.leapReadyAt and distance >= leap.MinDistance and distance <= leap.MaxDistance
		and root.Position.X >= MIN_GUARD_X + leap.LineMargin and isGrounded(g) then
		leaping = true
		g.leapUntil = now + leap.Seconds -- updateLeapArc drives the bound, the burst follows the path
		g.leapReadyAt = now + leap.Cooldown
		fireFx(g, "Leap", player, leap.Seconds)
	end
	if leaping then
		speed *= leap.SpeedFactor
	end

	local beam = sig.Beam
	if beam and now >= g.beamReadyAt and distance >= beam.MinDistance and distance <= beam.Range and hasLineOfSight(g, root.Position) then
		g.beamReadyAt = now + beam.Cooldown * (0.85 + math.random() * 0.3)
		fireFx(g, "Beam", player, beam.Seconds)
	end

	local roar = sig.Roar
	if roar and now >= g.roarReadyAt and distance <= roar.Range then
		g.roarReadyAt = now + roar.Cooldown
		fireFx(g, "Roar", player, roar.Seconds)
	end

	return math.clamp(speed, MIN_WALK_SPEED, MAX_WALK_SPEED)
end

local function stepChasing(g, now)
	local player, uid, root, distance = selectTarget(g)
	if not player then
		finishChase(g, now)
		return
	end

	if g.target ~= player then
		g.target = player
		g.outOfReachSince = nil
		setAttr(g, "TargetPlayer", tostring(player.UserId))
	end

	local reachable = canCatch(g, root, distance)
	if reachable and now - g.lastAttackAt >= ATTACK_COOLDOWN then
		catchPlayer(g, player, uid, now)
		return
	end

	if now < g.nextMoveAt then
		return
	end

	local base = g.config.WalkSpeed
	local boostUntil = g.recoveryUntil[player]
	if boostUntil then
		if now < boostUntil then
			base *= RECOVERY_SPEED_MULTIPLIER
		else
			g.recoveryUntil[player] = nil
		end
	end
	local speed = clampWalkSpeed(resolveWalkSpeed(base, g.config.FlatRadius, distance), base)
	speed = applySignature(g, now, player, root, distance, speed)
	setWalkSpeed(g, speed)
	g.nextMoveAt = now + moveInterval(speed)

	local velocity = root.AssemblyLinearVelocity
	local lead = math.min(distance / math.max(speed, 1), LEAD_MAX_SECONDS)
	-- the floor-level position of a jumping carrier (standingPosition): the goal stays walkable during a hop
	local goal = clampGoal(standingPosition(g, root) + Vector3.new(velocity.X, 0, velocity.Z) * lead)
	local heading = moveToward(g, goal, now, speed)

	local closeEnough = g.hitDistance + 4
	-- On its goal (typically the X line in front of a carrier parked at X 75..80, or under a carrier up on a
	-- prop it has no route to) but still unable to touch the carrier: give up on them after a while instead
	-- of holding the spot forever. They stay ignored until they come back within reach; the next tick picks
	-- another carrier or ends the chase.
	if flatDistance(g.hrp.Position, heading) <= closeEnough and not reachable then
		g.outOfReachSince = g.outOfReachSince or now
		if now - g.outOfReachSince >= OUT_OF_REACH_GIVE_UP_SECONDS then
			g.ignored[player] = root.Position
			g.outOfReachSince = nil
			g.target = nil
			return
		end
	else
		g.outOfReachSince = nil
	end

	local stalled = stalledFor(g, now, heading, closeEnough)
	if stalled >= CHASE_GIVE_UP_STUCK_SECONDS then
		teleportHome(g, now, "stuck while chasing")
	else
		repathIfStuck(g, now, stalled)
	end
end

-- Retrieval (owner 2026-09-27): walk to the dropped egg, lift it (GuardCarried: every client shows it in the
-- villain's arms), carry it to its nest and set it down there. A new carrier to chase, a timeout or a stall sends
-- the egg straight home (returnDroppedEgg) as before.
local function stepRetrieving(g, now)
	local uid = g.retrieveUid
	local record = getRecord(uid)
	local carrying = record ~= nil and record.State == "GuardCarried" and g.carryNest ~= nil

	if now >= g.nextScanAt then
		g.nextScanAt = now + TARGET_SCAN_INTERVAL
		if selectTarget(g) then
			if carrying then
				returnDroppedEgg(uid) -- put it home before chasing again: never chase with an egg in the arms
			end
			g.carryNest = nil
			enterChasing(g, now)
			return
		end
	end

	if not record or (record.State ~= "Dropped" and not carrying) or typeof(record.BottomCFrame) ~= "CFrame" then
		-- Re-stolen, claimed or already returned by someone else.
		if uid then
			g.pendingDropped[uid] = nil
		end
		g.carryNest = nil
		finishChase(g, now)
		return
	end

	if now - g.retrieveStartedAt > RETRIEVE_TIMEOUT then
		g.pendingDropped[uid] = nil
		returnDroppedEgg(uid)
		g.carryNest = nil
		finishChase(g, now)
		return
	end

	local eggPosition = if carrying then g.carryNest else record.BottomCFrame.Position
	local goal = clampGoal(eggPosition)
	local distance = flatDistance(g.hrp.Position, eggPosition)
	if distance <= RETRIEVE_REACH + (goal.X - eggPosition.X) then
		g.pendingDropped[uid] = nil
		if carrying then
			-- at the nest: set the egg down
			returnDroppedEgg(uid)
			g.carryNest = nil
			finishChase(g, now)
			return
		end
		local nest = pickUpDroppedEgg(uid)
		if nest == nil then
			returnDroppedEgg(uid)
			finishChase(g, now)
			return
		end
		-- lifted: now carry it to the nest (a fresh timeout for the walk; a short stop to pick it up)
		g.carryNest = nest
		g.retrieveStartedAt = now
		g.pauseUntil = now + RETRIEVE_PICKUP_PAUSE
		g.nextMoveAt = 0
		g.progressPos = g.hrp.Position
		g.progressAt = g.pauseUntil
		pcall(function()
			g.humanoid:MoveTo(g.hrp.Position)
		end)
		return
	end

	if now < g.nextMoveAt then
		return
	end

	local base = g.config.WalkSpeed
	local speed = clampWalkSpeed(resolveWalkSpeed(base, g.config.FlatRadius, distance), base)
	setWalkSpeed(g, speed)
	g.nextMoveAt = now + moveInterval(speed)
	local heading = moveToward(g, goal, now, speed)

	local stalled = stalledFor(g, now, heading, 2)
	if stalled >= NO_PROGRESS_SECONDS then
		g.pendingDropped[uid] = nil
		returnDroppedEgg(uid)
		g.carryNest = nil
		teleportHome(g, now, "stuck while retrieving an egg")
	else
		repathIfStuck(g, now, stalled)
	end
end

local function stepReturning(g, now)
	if now >= g.nextScanAt then
		g.nextScanAt = now + TARGET_SCAN_INTERVAL
		if selectTarget(g) then
			enterChasing(g, now)
			return
		end
	end

	local homePosition = g.home.Position
	if flatDistance(g.hrp.Position, homePosition) <= HOME_SNAP_DISTANCE then
		enterSleeping(g, now)
		return
	end

	if now > g.returnDeadline then
		teleportHome(g, now, "return timeout")
		return
	end

	if now < g.nextMoveAt then
		return
	end

	local speed = clampWalkSpeed(g.config.WalkSpeed * RETURN_SPEED_MULTIPLIER, g.config.WalkSpeed)
	setWalkSpeed(g, speed)
	g.nextMoveAt = now + moveInterval(speed)
	local heading = moveToward(g, homePosition, now, speed)

	if stalledFor(g, now, heading, HOME_SNAP_DISTANCE) >= NO_PROGRESS_SECONDS then
		teleportHome(g, now, "no progress while returning")
	end
end

-- Where the villain appears for a new carrier (A2): on the main street, SPAWN_DISTANCE from the carrier on
-- the side away from the hub, inside its stage, on a floor with room for its body. nil = stay where it is
-- (already that close on the far side of the carrier, the spot would be squeezed against the stage end, or nothing
-- suitable). A villain standing between the carrier and the hub (X below the carrier's) always moves behind it.
local function resolveSpawnCFrame(g, root)
	local carrier = root.Position
	local current = g.hrp.Position
	-- Balance #7 (owner 2026-09-23): each VillainPost sits inside its EggSpot cluster, so for an egg on the far side
	-- of the post (carrier X > post X) the villain would start between the carrier and the hub. It only stays put
	-- when it is already that close on the far side; otherwise it spawns behind the carrier like for far eggs.
	local hubSide = current.X < carrier.X
	if flatDistance(current, carrier) <= SPAWN_DISTANCE + HOME_SNAP_DISTANCE and current.X >= carrier.X then
		return nil
	end
	local height = g.baseHipHeight + g.hrp.Size.Y * 0.5 -- it wakes standing (no hover, no lunge)
	for _, streetZ in ipairs({ math.clamp(carrier.Z, -STREET_HALF_WIDTH, STREET_HALF_WIDTH), 0 }) do
		local dz = math.abs(carrier.Z - streetZ)
		local x = carrier.X + math.sqrt(math.max(SPAWN_DISTANCE * SPAWN_DISTANCE - dz * dz, 0))
		if g.stageMaxX and carrier.X >= g.stageMinX and carrier.X <= g.stageMaxX then
			x = math.min(x, g.stageMaxX - SPAWN_EDGE_MARGIN)
		end
		x = math.max(x, MIN_GUARD_X + SPAWN_EDGE_MARGIN)
		local spot = Vector3.new(x, carrier.Y, streetZ)
		local spotDistance = flatDistance(spot, carrier)
		if spotDistance >= SPAWN_MIN_DISTANCE and (hubSide or spotDistance < flatDistance(current, carrier)) then
			local hit = castRay(g, Vector3.new(x, g.homeFloorY + SPAWN_FLOOR_PROBE_ABOVE, streetZ), Vector3.new(0, -3 * SPAWN_FLOOR_PROBE_ABOVE, 0))
			if hit then
				local floor = hit.Position.Y
				local blocked = false
				if g.overlapParams then
					local size = Vector3.new(2 * math.max(2, 1.6 * g.scale), math.max(g.bodyHeight - 0.5, 1), 2 * math.max(2, 1.6 * g.scale))
					local okOverlap, parts = pcall(Workspace.GetPartBoundsInBox, Workspace, CFrame.new(x, floor + 0.5 + size.Y * 0.5, streetZ), size, g.overlapParams)
					blocked = okOverlap and type(parts) == "table" and #parts > 0
				end
				if not blocked then
					local position = Vector3.new(x, floor + height, streetZ)
					local look = Vector3.new(carrier.X - x, 0, carrier.Z - streetZ)
					if look.Magnitude > 0.1 then
						return CFrame.lookAt(position, position + look)
					end
					return CFrame.new(position)
				end
			end
		end
	end
	return nil
end

-- Appears near the carrier (see resolveSpawnCFrame), then wakes there. Returns true when it moved.
local function spawnForCarrier(g, player, root)
	local spawnCFrame = root and resolveSpawnCFrame(g, root)
	if not spawnCFrame then
		return false
	end
	local from = g.hrp.Position
	endLeap(g)
	setHover(g, false)
	invalidatePath(g)
	pcall(function()
		g.humanoid:MoveTo(spawnCFrame.Position)
		g.hrp.AssemblyLinearVelocity = Vector3.zero
		g.hrp.AssemblyAngularVelocity = Vector3.zero
	end)
	g.hrp.Anchored = true
	pivotRootTo(g, spawnCFrame)
	fireFx(g, "Spawn", player, g.wakingDuration, spawnCFrame.Position, from)
	return true
end

local function stepSleeping(g, now)
	if now < g.nextScanAt then
		return
	end
	g.nextScanAt = now + SLEEP_SCAN_INTERVAL
	-- Backstop for carries that started before this guard was set up (or after a teleport home).
	local player, _, root = selectTarget(g)
	if player then
		spawnForCarrier(g, player, root)
		enterWaking(g, now, player, root)
	end
end

-- Goals are clamped to X >= MIN_GUARD_X; this also catches momentum (a Carnage leap, a knock) that
-- would carry the villain over the line towards the safe zone.
local function enforceLine(g)
	local position = g.hrp.Position
	if position.X >= MIN_GUARD_X - LINE_TOLERANCE then
		return
	end
	local velocity = g.hrp.AssemblyLinearVelocity
	if velocity.X < 0 then
		g.hrp.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, velocity.Z)
	end
	if position.X < MIN_GUARD_X - LINE_HARD_TOLERANCE then
		pivotRootTo(g, g.hrp.CFrame + Vector3.new(MIN_GUARD_X - position.X, 0, 0))
	end
end

local function disableGuard(g, reason)
	g.disabled = true
	g.pathToken += 1
	guards[g.zoneName] = nil
	warnOnce("disabled:" .. g.zoneName, string.format("%s guard disabled: %s", g.zoneName, reason))
end

local function stepGuard(g, now)
	if g.guard.Parent == nil or not g.hrp:IsDescendantOf(Workspace) or g.humanoid.Parent == nil then
		disableGuard(g, "guard model, root or humanoid was removed")
		return
	end

	local state = g.state
	if state == STATE_SLEEPING then
		stepSleeping(g, now)
		return
	end

	if state == STATE_WAKING then
		if now >= g.wakeEndsAt then
			if selectTarget(g) then
				enterChasing(g, now)
			else
				vanishHome(g, now)
			end
		end
		return
	end

	if g.hrp.Position.Y < VOID_Y then
		teleportHome(g, now, "fell below the world")
		return
	end

	enforceLine(g)
	updateLeapArc(g, now)

	if now - g.lastOwnerAt >= NETWORK_OWNER_REFRESH then
		claimNetworkOwnership(g, now)
	end

	if now < g.pauseUntil then
		return
	end

	if state == STATE_CHASING then
		stepChasing(g, now)
	elseif state == STATE_RETRIEVING then
		stepRetrieving(g, now)
	elseif state == STATE_RETURNING then
		stepReturning(g, now)
	end
end

--------------------------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------------------------

-- Parts reachable from `root` through joints/weld constraints inside the guard.
local function collectJointedParts(model, root)
	local adjacency = {}
	local function link(a, b)
		if a and b then
			adjacency[a] = adjacency[a] or {}
			adjacency[b] = adjacency[b] or {}
			table.insert(adjacency[a], b)
			table.insert(adjacency[b], a)
		end
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("JointInstance") or descendant:IsA("WeldConstraint") then
			link(descendant.Part0, descendant.Part1)
		end
	end

	local reached = { [root] = true }
	local queue = { root }
	local head = 1
	while head <= #queue do
		local part = queue[head]
		head += 1
		for _, other in ipairs(adjacency[part] or {}) do
			if not reached[other] then
				reached[other] = true
				table.insert(queue, other)
			end
		end
	end
	return reached
end

-- Villains with authored clips (ReplicatedStorage.Directory.VillainAnimations.<HeroId>, owner 2026-09-27: "each boss its
-- own attack, run and a distracted / asleep idle; Frieza's float") are animated on every client by
-- StarterPlayerScripts.Game.VillainClipPlayer: the server loads no Animator track for them (nothing to replicate, no
-- track fighting the clips) and marks the rig ClientClips.
local function hasClientClips(guardModel)
	local heroId = guardModel:GetAttribute("HeroId")
	local directory = ReplicatedStorage:FindFirstChild("Directory")
	local folder = directory and directory:FindFirstChild("VillainAnimations")
	return type(heroId) == "string" and folder ~= nil and folder:FindFirstChild(heroId) ~= nil
end

local function loadTracks(humanoid, zoneName)
	local tracks = {}
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	for key, animationId in pairs(ANIMATION_IDS) do
		local animation = Instance.new("Animation")
		animation.Name = "GuardChase" .. key
		animation.AnimationId = animationId
		local ok, track = pcall(animator.LoadAnimation, animator, animation)
		if ok and track then
			trySet(track, "Priority", ANIMATION_PRIORITIES[key])
			trySet(track, "Looped", key ~= "Attack")
			tracks[key] = track
		else
			warnOnce("anim:" .. zoneName .. ":" .. key, string.format("%s guard could not load %s animation: %s", zoneName, key, tostring(track)))
		end
	end
	return tracks
end

-- Waits (warm-up thread) until the tracks' animations have loaded, then re-applies Priority and Looped: a track's
-- asset replaces both when it finishes loading, so the values set right after LoadAnimation do not survive the first
-- load (the Attack swing would blend at the asset's Core priority under the run). Returns the number of loaded tracks.
local function primeTracks(g)
	local deadline = os.clock() + TRACK_LOAD_TIMEOUT
	local pending = {}
	for key, track in pairs(g.tracks) do
		pending[key] = track
	end
	local loaded = 0
	while next(pending) ~= nil and os.clock() < deadline and not g.disabled do
		for key, track in pairs(pending) do
			local ok, length = pcall(function()
				return track.Length
			end)
			if ok and type(length) == "number" and length > 0 then
				trySet(track, "Priority", ANIMATION_PRIORITIES[key])
				trySet(track, "Looped", key ~= "Attack")
				pending[key] = nil
				loaded += 1
			end
		end
		if next(pending) ~= nil then
			task.wait(0.2)
		end
	end
	for key in pairs(pending) do
		warnOnce("animload:" .. g.zoneName .. ":" .. key,
			string.format("%s guard: %s animation still not loaded after %d s (the villain slides without it)", g.zoneName, key, TRACK_LOAD_TIMEOUT))
	end
	return loaded
end

-- Visible body height above the floor, read from the rig (at least the R15 block height at `scale`).
local function measureBodyHeight(guardModel, hrp, humanoid, scale)
	local floor = hrp.Position.Y - hrp.Size.Y * 0.5 - humanoid.HipHeight
	local top = hrp.Position.Y + hrp.Size.Y * 0.5
	-- the villain body is flattened into the guard (a legacy nested Guard.Model is still read)
	local body = guardModel:FindFirstChild("Model") or guardModel
	if body then
		for _, part in ipairs(body:GetDescendants()) do
			if part:IsA("BasePart") and part.Transparency < 1 and part ~= hrp then
				top = math.max(top, part.Position.Y + part.Size.Y * 0.5)
			end
		end
	end
	return math.max(top - floor, 4 * scale)
end

-- The stage's X range from its Bounds part (spawn spots stay inside it).
local function boundsXRange(bounds)
	if not bounds then
		return nil, nil
	end
	local half = bounds.Size * 0.5
	local minX, maxX = math.huge, -math.huge
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local corner = bounds.CFrame:PointToWorldSpace(Vector3.new(half.X * sx, 0, half.Z * sz))
			minX = math.min(minX, corner.X)
			maxX = math.max(maxX, corner.X)
		end
	end
	return minX, maxX
end

-- 1D replay of stepChasing + applySignature along the exit axis (positions = studs in front of the safe-zone line):
-- a carrier runs steadily at carrierSpeed from `run` studs out, the villain appears SPAWN_DISTANCE behind it, stands
-- still for the wake beat, then chases at the rubber-band speed times the signature (surge cycle from the start of
-- the chase, lunges after FirstDelay) and catches within the same reach as canCatch. True when the carrier gets home.
local function survivesSteadyRun(g, sig, carrierSpeed, run)
	local base = g.config.WalkSpeed
	local flatRadius = g.config.FlatRadius
	local reach = g.hitDistance + HIT_BASE_PAD + math.min(carrierSpeed * HIT_LATENCY_SECONDS, HIT_MAX_LATENCY_PAD)
	local line = MIN_GUARD_X - SAFE_ZONE_MAX_X
	local surge, leap = sig.Surge, sig.Leap
	local carrier = run - carrierSpeed * g.wakingDuration
	local villain = run + SPAWN_DISTANCE
	local elapsed, leapUntil = 0, 0
	local leapReadyAt = if leap then leap.FirstDelay else 0
	while carrier > 0 do
		local gap = villain - carrier
		if gap <= reach then
			return false
		end
		local speed = clampWalkSpeed(resolveWalkSpeed(base, flatRadius, gap), base)
		if surge then
			local phase = elapsed % (surge.SlowSeconds + surge.SurgeSeconds)
			speed *= if phase >= surge.SlowSeconds then surge.SurgeFactor else surge.SlowFactor
		end
		if leap then
			local leaping = elapsed < leapUntil
			if not leaping and elapsed >= leapReadyAt and gap >= leap.MinDistance and gap <= leap.MaxDistance
				and carrier >= line + leap.LineMargin then
				leaping = true
				leapUntil = elapsed + leap.Seconds
				leapReadyAt = elapsed + leap.Cooldown
			end
			if leaping then
				speed *= leap.SpeedFactor
			end
		end
		speed = math.clamp(speed, MIN_WALK_SPEED, MAX_WALK_SPEED)
		villain = math.max(villain - speed * SPEED_FACTOR_SIM_STEP, line)
		carrier -= carrierSpeed * SPEED_FACTOR_SIM_STEP
		elapsed += SPEED_FACTOR_SIM_STEP
	end
	return true
end

-- Slowest steady carrier speed, as a multiple of the zone WalkSpeed, that gets home such that every faster speed
-- does too (a lunge window could spare one speed and catch a faster one): coarse scan down from the top, then
-- bisection inside the last coarse step.
local function slowestEscapeFactor(g, sig, run)
	local base = g.config.WalkSpeed
	local high = SPEED_FACTOR_MAX
	if not survivesSteadyRun(g, sig, high * base, run) then
		return high
	end
	local low = nil
	while not low do
		local candidate = high - SPEED_FACTOR_COARSE_STEP
		if candidate < SPEED_FACTOR_MIN then
			return high
		end
		if survivesSteadyRun(g, sig, candidate * base, run) then
			high = candidate
		else
			low = candidate
		end
	end
	for _ = 1, SPEED_FACTOR_REFINE_STEPS do
		local mid = (low + high) * 0.5
		if survivesSteadyRun(g, sig, mid * base, run) then
			high = mid
		else
			low = mid
		end
	end
	return high
end

-- Steady-speed equivalent of a burst signature (Darkseid's surge, Carnage's lunge): how much faster a carrier running
-- straight home from the far end of the stage must be than against the same villain without its signature. Published
-- as the guard's ChaseSpeedFactor; GuardEscapeSignController solves its plain rubber-band model at WalkSpeed * factor,
-- so the RequiredSpeedSign covers the bursts and not only their time average (a carrier faster than the average is
-- still caught by a surge or a lunge). Derived from SIGNATURES, so retuning a signature retunes the sign. 1 when the
-- signature does not change the chase speed.
local function resolveChaseSpeedFactor(g, sig)
	if type(sig) ~= "table" or not (sig.Surge or sig.Leap) then
		return 1
	end
	local base = g.config.WalkSpeed
	if type(base) ~= "number" or base <= 0 then
		return 1
	end
	local run = if g.stageMaxX then g.stageMaxX - SAFE_ZONE_MAX_X else SPEED_FACTOR_DEFAULT_RUN
	run = math.max(run, SPEED_FACTOR_MIN_RUN)
	local ratio = slowestEscapeFactor(g, sig, run) / slowestEscapeFactor(g, {}, run)
	return math.clamp(math.ceil(ratio * 100) / 100, SPEED_FACTOR_MIN, SPEED_FACTOR_MAX)
end

-- (Re)reads the guard's HeroId: signature table and the ChaseSignature attribute the clients key their
-- effects on. Safe to call at any time (HEROES may swap the villain at runtime).
configureSignature = function(g)
	local key = resolveSignatureKey(g.guard:GetAttribute("HeroId"))
	if key == g.sigKey and g.sig ~= nil then
		return
	end
	local wasHovering = g.hovering
	setHover(g, false)
	g.sigKey = key
	endLeap(g)
	g.sig = key and SIGNATURES[key] or nil
	setAttr(g, "ChaseSignature", key or "")
	local okFactor, factor = pcall(resolveChaseSpeedFactor, g, g.sig)
	if okFactor and type(factor) == "number" and factor == factor then
		setAttr(g, "ChaseSpeedFactor", factor)
	else
		-- No attribute: the sign falls back to its own table.
		warnOnce("speedfactor:" .. g.zoneName, g.zoneName .. ": ChaseSpeedFactor not resolved: " .. tostring(factor))
		setAttr(g, "ChaseSpeedFactor", nil)
	end
	if wasHovering or MOVING_STATES[g.state] then
		setHover(g, MOVING_STATES[g.state] == true)
		if MOVING_STATES[g.state] then
			playLoop(g, movingLoop(g))
		end
	end
end

local function setupZone(zone)
	local zoneName = zone.Name
	local guardModel = zone:FindFirstChild("Guard") or zone:WaitForChild("Guard", SETUP_WAIT_SECONDS)
	if not guardModel or not guardModel:IsA("Model") then
		warnOnce("missing:" .. zoneName, zoneName .. " has no Guard model; zone skipped")
		return nil
	end
	local hrp = guardModel:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		warnOnce("missing:" .. zoneName, zoneName .. " guard has no HumanoidRootPart; zone skipped")
		return nil
	end
	local humanoid = guardModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warnOnce("missing:" .. zoneName, zoneName .. " guard has no Humanoid; zone skipped")
		return nil
	end

	local scale = tonumber(guardModel:GetAttribute("RigScale")) or (hrp.Size.Y / 2)
	scale = math.clamp(scale, 0.5, 4)

	-- Home = authored root pose, kept upright (yaw only).
	local authored = hrp.CFrame
	local flatLook = Vector3.new(authored.LookVector.X, 0, authored.LookVector.Z)
	local home = if flatLook.Magnitude > 0.01
		then CFrame.lookAt(authored.Position, authored.Position + flatLook)
		else CFrame.new(authored.Position)

	-- Everything is anchored in the file. Re-capture weld-constraint offsets from that authored pose
	-- (offline-built constraints may carry identity offsets), then free every non-root part; the root
	-- stays anchored while sleeping. Parts with no joint path to the root get welded where they are,
	-- so nothing falls out of the villain once the root is released.
	hrp.Anchored = true
	for _, descendant in ipairs(guardModel:GetDescendants()) do
		if descendant:IsA("WeldConstraint") and descendant.Enabled and descendant.Part0 and descendant.Part1 then
			pcall(function()
				descendant.Enabled = false
				descendant.Enabled = true
			end)
		end
	end
	local jointed = collectJointedParts(guardModel, hrp)
	local rewelded = 0
	for _, descendant in ipairs(guardModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			setCollisionGroup(descendant, GUARD_COLLISION_GROUP)
			if descendant ~= hrp then
				if not jointed[descendant] then
					local weld = Instance.new("WeldConstraint")
					weld.Name = "GuardChaseRootWeld"
					weld.Part0 = hrp
					weld.Part1 = descendant
					weld.Parent = descendant
					rewelded += 1
				end
				descendant.Anchored = false
			end
		end
	end
	if rewelded > 0 then
		warnOnce("rewelded:" .. zoneName, string.format("%s guard: welded %d unjointed part(s) to the root", zoneName, rewelded))
	end

	-- Every guard part may be authored Massless; keep the root as the mass-carrying assembly root so
	-- the Humanoid always drives a predictable assembly.
	trySet(hrp, "Massless", false)
	trySet(hrp, "RootPriority", 127)

	-- The collider is authored CanCollide=true (kept in the file for tests/tools); at runtime the
	-- Humanoid hovers at HipHeight and a colliding box would only snag on the floor or props.
	local collider = guardModel:FindFirstChild("Collider")
	if collider and not collider:IsA("BasePart") then
		collider = nil
	end
	if collider then
		collider.CanCollide = false
	end

	for _, stateType in ipairs({ Enum.HumanoidStateType.Dead, Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll }) do
		pcall(humanoid.SetStateEnabled, humanoid, stateType, false)
	end
	trySet(humanoid, "BreakJointsOnDeath", false)
	trySet(humanoid, "RequiresNeck", false)
	trySet(humanoid, "AutoRotate", true)
	trySet(humanoid, "PlatformStand", false)
	trySet(humanoid, "Sit", false)
	trySet(humanoid, "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None)

	-- Agent size from the actual rig (villains range from 1.0x Frieza to 1.9x Kaido): radius max(2, 1.6*scale),
	-- height = the collider's (the body's measured height when there is no collider).
	local agentHeight = if collider then collider.Size.Y else measureBodyHeight(guardModel, hrp, humanoid, scale)

	local agentParams = {
		AgentRadius = math.max(2, 1.6 * scale),
		AgentHeight = math.clamp(agentHeight, 4, 20),
		AgentCanJump = false,
		AgentCanClimb = false,
		WaypointSpacing = 8,
	}
	local path = nil
	local okPath, result = pcall(function()
		return PathfindingService:CreatePath(agentParams)
	end)
	if okPath then
		path = result
	else
		warnOnce("path:" .. zoneName, zoneName .. " guard: CreatePath failed, using straight-line movement: " .. tostring(result))
	end

	local config = loadZoneConfig(zoneName)

	-- Straight-line / ground / catch probes see what the villain would walk into: everything that collides
	-- with the Guards group (player characters and guards do not), minus GuardAreas (guards, nests, bounds).
	local rayParams = nil
	pcall(function()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { zone.Parent or guardModel }
		params.RespectCanCollide = true
		params.CollisionGroup = GUARD_COLLISION_GROUP
		rayParams = params
	end)
	local overlapParams = nil
	pcall(function()
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		-- Spawn-spot clearance only cares about parts (Terrain is never a street prop).
		params.FilterDescendantsInstances = { zone.Parent or guardModel, Workspace:FindFirstChildOfClass("Terrain") }
		params.RespectCanCollide = true
		params.CollisionGroup = GUARD_COLLISION_GROUP
		overlapParams = params
	end)
	local bounds = zone:FindFirstChild("Bounds")
	if bounds and not bounds:IsA("BasePart") then
		bounds = nil
	end
	local stageMinX, stageMaxX = boundsXRange(bounds)

	local lowerTorso = guardModel:FindFirstChild("LowerTorso", true)
	local rootMotor = lowerTorso and lowerTorso:FindFirstChild("Root")
	if rootMotor and (not rootMotor:IsA("Motor6D") or rootMotor.Part0 ~= hrp) then
		rootMotor = nil
	end

	local g = {
		zoneName = zoneName,
		zone = zone,
		bounds = bounds,
		stageMinX = stageMinX,
		stageMaxX = stageMaxX,
		homeFloorY = home.Position.Y - hrp.Size.Y * 0.5 - humanoid.HipHeight,
		bodyHeight = agentHeight,
		overlapParams = overlapParams,
		guard = guardModel,
		hrp = hrp,
		humanoid = humanoid,
		home = home,
		scale = scale,
		config = config,
		hitDistance = resolveHitDistance(config.HitDistance) * (REACH_FACTOR_BASE + REACH_FACTOR_PER_SCALE * scale),
		baseHipHeight = humanoid.HipHeight,
		rootMotor = rootMotor,
		rootMotorC0 = rootMotor and rootMotor.C0,
		rayParams = rayParams,
		sigKey = nil,
		sig = nil,
		hovering = false,
		fxSeq = 0,
		surgeCycleStart = 0,
		surging = false,
		leapUntil = 0,
		leapReadyAt = 0,
		beamReadyAt = 0,
		roarReadyAt = 0,
		pathFailedUntil = 0,
		wakingDuration = resolveWakingDuration(),
		knockbackForce = KNOCKBACK_FORCE_BY_ZONE[zoneName] or DEFAULT_KNOCKBACK_FORCE,
		tracks = if hasClientClips(guardModel) then {} else loadTracks(humanoid, zoneName),
		currentLoop = nil,
		path = path,
		agentParams = agentParams,
		pathToken = 0,
		computing = false,
		lastPathAt = -math.huge,
		waypoints = nil,
		waypointIndex = 2,
		pathGoal = nil,
		pathModeUntil = 0,
		lastStuckRepathAt = -math.huge,
		state = STATE_SLEEPING,
		target = nil,
		outOfReachSince = nil,
		ignored = {}, -- Player -> Vector3 where this guard gave up on them (see selectTarget)
		recoveryUntil = {},
		pendingDropped = {},
		retrieveUid = nil,
		retrieveStartedAt = 0,
		wakeEndsAt = 0,
		returnDeadline = 0,
		lastAttackAt = -math.huge,
		pauseUntil = 0,
		lastOwnerAt = -math.huge,
		nextMoveAt = 0,
		nextScanAt = 0,
		progressPos = hrp.Position,
		progressAt = 0,
		errorCount = 0,
		disabled = false,
	}

	if path then
		-- A prop moved into the current route: drop the waypoints and ask for a new path right away.
		pcall(function()
			path.Blocked:Connect(function(blockedIndex)
				if g.waypoints and (type(blockedIndex) ~= "number" or blockedIndex >= g.waypointIndex - 1) then
					g.waypoints = nil
					g.pathGoal = nil
					g.lastPathAt = -math.huge
				end
			end)
		end)
	end

	guardModel:SetAttribute("ClientClips", hasClientClips(guardModel))
	guardModel:SetAttribute("AreaId", zoneName)
	guardModel:SetAttribute("HomeCFrame", home)
	guardModel:SetAttribute("HeadLookAtDisabled", true)
	configureSignature(g)
	pcall(function()
		guardModel:GetAttributeChangedSignal("HeroId"):Connect(function()
			configureSignature(g)
		end)
	end)
	enterSleeping(g, os.clock())
	return g
end

local function onHeartbeat()
	local now = os.clock()
	for _, g in pairs(guards) do
		local ok, err = pcall(stepGuard, g, now)
		if not ok then
			g.errorCount += 1
			if g.errorCount == 1 or g.errorCount % 100 == 0 then
				warn(string.format("[GuardChaseService] %s guard step failed (%s, %d total): %s", g.zoneName, tostring(g.state), g.errorCount, tostring(err)))
			end
			-- Put the guard back on its post; the sleep scan re-wakes it if a carrier is still out.
			if not g.disabled then
				pcall(enterSleeping, g, now)
			end
		end
	end
end

local function resolveRemotes()
	local network = ReplicatedStorage:FindFirstChild("Network") or ReplicatedStorage:WaitForChild("Network", SETUP_WAIT_SECONDS)
	if not network then
		warnOnce("network", "ReplicatedStorage.Network missing; wake flash and knockback disabled")
		return
	end
	local wake = network:FindFirstChild("Guards: WakeUp")
	if wake and wake:IsA("RemoteEvent") then
		wakeUpRemote = wake
	end
	local hit = network:FindFirstChild("Guards: ServerHit") or network:WaitForChild("Guards: ServerHit", SETUP_WAIT_SECONDS)
	if not hit then
		-- NetworkInit normally creates it; create it here so the carrier's client can still find it.
		hit = Instance.new("RemoteEvent")
		hit.Name = "Guards: ServerHit"
		hit.Parent = network
		warnOnce("serverhit", "created missing RemoteEvent Guards: ServerHit")
	end
	if hit:IsA("RemoteEvent") then
		serverHitRemote = hit
	end
end

local function loadSharedModules()
	local okPolicy, policy = requireWithTimeout(function()
		return ReplicatedStorage.Library.Modules.GuardAreas.GuardChasePolicy
	end, 5)
	if okPolicy and type(policy) == "table" then
		GuardChasePolicy = policy
	else
		warnOnce("policy", "GuardChasePolicy unavailable, using built-in chase maths: " .. tostring(policy))
	end

	local okGuards, guardsModule = requireWithTimeout(function()
		return ReplicatedStorage.Directory.Guards
	end, 5)
	if okGuards and type(guardsModule) == "table" and type(guardsModule.Directory) == "table" then
		guardsDirectory = guardsModule.Directory
	else
		guardsDirectory = false
		warnOnce("directory", "Directory.Guards unavailable on the server, using built-in guard speeds: " .. tostring(guardsModule))
	end
end

local function isRetiredZone(zone)
	return RETIRED_ZONES[zone.Name] == true or zone:GetAttribute("Retired") == true
end

-- Floor points a chase of this stage routes to: the post, both stage ends on the main street and every nest (where the
-- carriers start). Rays skip GuardAreas, so a nest's point lands on the floor under it.
local function warmupTargets(g)
	local targets = {}
	local floorY = g.homeFloorY + 1
	local function add(x, z)
		if #targets < WARMUP_MAX_TARGETS then
			table.insert(targets, groundPoint(g, Vector3.new(x, floorY, z)))
		end
	end
	add(g.home.Position.X, g.home.Position.Z)
	if g.stageMinX and g.stageMaxX then
		add(g.stageMaxX - SPAWN_EDGE_MARGIN, 0)
		add(math.max(g.stageMinX + SPAWN_EDGE_MARGIN, MIN_GUARD_X), 0)
	end
	local nests = g.zone:FindFirstChild("Nests")
	for _, nest in ipairs(nests and nests:GetChildren() or {}) do
		local spot = nest:FindFirstChild("EggSpotBottom", true)
		local position = nil
		if spot and spot:IsA("BasePart") then
			position = spot.Position
		elseif nest:IsA("BasePart") then
			position = nest.Position
		elseif nest:IsA("Model") then
			local ok, pivot = pcall(nest.GetPivot, nest)
			position = ok and pivot.Position or nil
		end
		if position then
			add(position.X, position.Z)
		end
	end
	return targets
end

-- Routes the stage once with the villain's own agent (a separate Path object: the chase's own one is never touched), so
-- the navmesh tiles a chase needs already exist when the first carrier runs. Failed routes (a point on a prop) still
-- build the tiles they searched. Returns routed, total.
local function warmUpZone(g)
	if not g.agentParams then
		return 0, 0
	end
	local okPath, path = pcall(function()
		return PathfindingService:CreatePath(g.agentParams)
	end)
	if not okPath or not path then
		return 0, 0
	end
	local targets = warmupTargets(g)
	local start = groundPoint(g, streetPoint(Vector3.new(g.home.Position.X, g.homeFloorY + 1, g.home.Position.Z)))
	local routed = 0
	for _, target in ipairs(targets) do
		if g.disabled then
			break
		end
		local ok = pcall(path.ComputeAsync, path, start, target)
		if ok and path.Status == Enum.PathStatus.Success then
			routed += 1
		end
		task.wait(WARMUP_STEP_WAIT)
	end
	pcall(path.Destroy, path)
	return routed, #targets
end

-- Runs once, after every zone's setup (or WARMUP_SETUP_TIMEOUT), stage by stage from the hub outwards. The summary line
-- lands in the output (FLog::CreatorOutput in Studio logs) as evidence the warm-up ran.
local function warmUpPaths(isSetupDone)
	local deadline = os.clock() + WARMUP_SETUP_TIMEOUT
	while not isSetupDone() and os.clock() < deadline do
		task.wait(0.25)
	end
	task.wait(WARMUP_START_DELAY)
	local ordered = {}
	for _, g in pairs(guards) do
		table.insert(ordered, g)
	end
	table.sort(ordered, function(a, b)
		return a.home.Position.X < b.home.Position.X
	end)
	local startedAt = os.clock()
	local report = {}
	for _, g in ipairs(ordered) do
		if not g.disabled then
			local ok, routed, total = pcall(warmUpZone, g)
			if ok then
				table.insert(report, string.format("%s %d/%d", g.zoneName, routed, total))
			else
				table.insert(report, g.zoneName .. " failed (" .. tostring(routed) .. ")")
			end
		end
	end
	local animations = {}
	for _, g in ipairs(ordered) do
		table.insert(animations, string.format("%s %s", g.zoneName, if g.tracksLoaded then tostring(g.tracksLoaded) else "?"))
	end
	print(string.format("[GuardChaseService] chase warm-up in %.1f s: routes %s; animations loaded %s", os.clock() - startedAt,
		table.concat(report, ", "), table.concat(animations, ", ")))
end

local function setupAllZones()
	resolveRemotes()
	loadSharedModules()

	local objects = Workspace:FindFirstChild("__OBJECTS") or Workspace:WaitForChild("__OBJECTS", SETUP_WAIT_SECONDS)
	local areas = objects and (objects:FindFirstChild("Areas") or objects:WaitForChild("Areas", SETUP_WAIT_SECONDS))
	local guardAreas = areas and (areas:FindFirstChild("GuardAreas") or areas:WaitForChild("GuardAreas", SETUP_WAIT_SECONDS))
	if not guardAreas then
		warnOnce("guardareas", "Workspace.__OBJECTS.Areas.GuardAreas not found; no server-side guards")
		return
	end

	local skipped = {}
	local pendingSetups = 0
	for _, zone in ipairs(guardAreas:GetChildren()) do
		if zone:IsA("Model") and not isRetiredZone(zone) then
			if zone:GetAttribute("ServerChase") == true then
				pendingSetups += 1
				task.spawn(function()
					local ok, result = pcall(setupZone, zone)
					if not ok then
						warnOnce("setup:" .. zone.Name, zone.Name .. " guard setup failed: " .. tostring(result))
					elseif result then
						guards[zone.Name] = result
						task.spawn(function()
							local okPrime, loaded = pcall(primeTracks, result)
							result.tracksLoaded = if okPrime then loaded else 0
						end)
					end
					pendingSetups -= 1
				end)
			else
				table.insert(skipped, zone.Name)
			end
		end
	end
	if #skipped > 0 then
		table.sort(skipped)
		warnOnce("skipped", "zones without ServerChase=true stay on the client guard runtime: " .. table.concat(skipped, ", "))
	end
	task.spawn(warmUpPaths, function()
		return pendingSetups <= 0
	end)
end

--------------------------------------------------------------------------------------------------
-- Public API (called by AreaEggService)
--------------------------------------------------------------------------------------------------

-- callbacks: {
--   IsInSafeZone(position) -> boolean,
--   GetCarriersForArea(areaId) -> { { Player = Player, Uid = string } },
--   GetRecord(uid) -> AreaEggRecord?,
--   OnGuardCaughtPlayer(player, uid, guardCFrame) -> droppedRecord?,
--   ReturnDroppedEggToNest(uid) -> boolean,
-- }
function GuardChaseService.Init(options)
	if type(options) == "table" then
		callbacks = options
	end
	if initialized then
		return
	end
	initialized = true

	ensureCollisionGroups()
	Players.PlayerAdded:Connect(hookPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		hookPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local connection = characterConnections[player]
		if connection then
			connection:Disconnect()
			characterConnections[player] = nil
		end
		for _, g in pairs(guards) do
			g.recoveryUntil[player] = nil
			g.ignored[player] = nil
			if g.target == player then
				g.target = nil
			end
		end
	end)

	RunService.Heartbeat:Connect(onHeartbeat)
	task.spawn(setupAllZones)
end

-- A carry of an egg from `record.AreaId` just started. Never yields.
function GuardChaseService.StartChase(player, record, wasDropped)
	if type(record) ~= "table" then
		return false
	end
	local g = guards[record.AreaId]
	if not g or g.disabled then
		return false
	end
	local now = os.clock()
	g.ignored[player] = nil -- a fresh carry starts at a nest, well within reach
	if wasDropped then
		g.recoveryUntil[player] = now + RECOVERY_DURATION
	end
	if g.state == STATE_SLEEPING then
		local root = getLiveRoot(player)
		spawnForCarrier(g, player, root)
		enterWaking(g, now, player, root)
	elseif g.state == STATE_RETURNING or g.state == STATE_RETRIEVING then
		-- On its way back: appear near the new carrier if it is far off (with the wake beat), else just turn round.
		-- An egg it is carrying home goes back to its nest first (it must not teleport in the villain's arms).
		releaseCarriedEgg(g)
		local root = getLiveRoot(player)
		if spawnForCarrier(g, player, root) then
			enterWaking(g, now, player, root)
		else
			enterChasing(g, now)
		end
	end
	return true
end

-- A carry of this zone ended (claim, voluntary drop, death, leave). With `force`, the guard
-- abandons whatever it is doing and walks back to its post; otherwise it only stops chasing when
-- no valid carrier is left.
function GuardChaseService.ReturnToPost(areaId, force)
	local g = guards[areaId]
	if not g or g.disabled then
		return false
	end
	local now = os.clock()
	if force then
		if g.state == STATE_WAKING or flatDistance(g.hrp.Position, g.home.Position) > RETURN_TELEPORT_DISTANCE then
			vanishHome(g, now)
		elseif g.state ~= STATE_SLEEPING then
			enterReturning(g, now)
		end
	elseif (g.state == STATE_CHASING or g.state == STATE_WAKING) and not selectTarget(g) then
		if g.state == STATE_WAKING then
			vanishHome(g, now) -- it may have just appeared next to the carrier
		else
			finishChase(g, now)
		end
	end
	return true
end

-- True when this service is actively driving the zone's guard.
function GuardChaseService.IsActive(areaId)
	local g = guards[areaId]
	return g ~= nil and not g.disabled
end

function GuardChaseService.GetState(areaId)
	local g = guards[areaId]
	return g and g.state or nil
end

return GuardChaseService
