-- scripts/tools/sim_pen_wander.luau (ANIMPOLISH, pen hero movement check)
-- Runs the game's pen wander simulation (ActiveAssetsController.AssetWanderSimulator + AssetPenSpace + helpers, as built
-- into a place) offline with a crowd of heroes in one real PetArea, a fake terminal and two eggs, and measures what a
-- player would see (the movement batch's easing is emulated):
--   overlap   share of hero-time two heroes' footprints overlap by more than 20 %
--   fence     frames a footprint crossed the pen rectangle (the fence line)
--   obstacle  frames a hero stood inside the terminal / an egg
--   turn      the fastest rendered turn (deg/s) and the share of turning frames above 360 deg/s (snaps)
--   crab      share of walking time the hero moves more than 35 deg off where it faces (crab-walk / moonwalk)
--   skate     share of walking time the planted feet would visibly slide (> 0.8 studs/s): HeroClipPlayer's Move
--             rate band 0.35x..2.6x of the clip's ground speed, and its partial Move weight below the slowest rate
--   (turn / crab / skate skip hops: a spin jump spins on purpose)   SIM_PEN_DEBUG=1 prints them per phase
--   stuck     (NPC pass 2026-09-26) share of hero-time a hero that is NOT standing by choice (idle, greeting / affection
--             hold, following its owner and arrived) moved less than STUCK_STUDS in the last STUCK_WINDOW s (pushing
--             into an obstacle / another hero, frozen when the owner is away, jittering in a corner), the number of
--             heroes that ever got stuck and the longest stuck streak
--   retarget  destination jumps (> 1 stud) per hero-minute while walking to a destination (Curve wander, greeting
--             approaches and follow-owner track a moving point on purpose and are skipped): a hero re-picking its goal
--             every frame (the old retreat) shows here
--   cost      simulation microseconds per hero per frame (Lune, relative only)
--   lune run scripts/tools/sim_pen_wander.luau <place.rbxl> [heroes=30] [seconds=90]
--   (SIM_PEN_SRC=1 runs the ActiveAssetsController modules from their src mirrors instead of the place's Sources;
--    SIM_PEN_OWNER=0 keeps the owner away the whole run; SIM_PEN_OWNER=corner parks the owner next to a pen corner)
-- Exit code 1 when a check fails (overlap > 8 %, any fence crossing, obstacle > 0.2 %, snaps > 5 %, crab > 8 %, skate
-- > 9 %, stuck > 1 % or a streak > 6 s, retarget > 30 / hero-minute; the owner strolls through the pen for 60 % of the
-- run, so greetings crowd round them; legacy build: overlap
-- 28 %, fence 3047, obstacle 1601, crab 14 %, skate 32 %). A place built before ANIMPOLISH still runs (no footprint / profile / pen space): the
-- numbers then show the old behaviour.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3
local Instance = roblox.Instance

local placePath = process.args[1]
assert(placePath ~= nil and fs.isFile(placePath), "usage: lune run scripts/tools/sim_pen_wander.luau <place.rbxl> [heroes] [seconds]")
local HEROES = tonumber(process.args[2]) or 30
local SECONDS = tonumber(process.args[3]) or 90
local DT = 1 / 60

local place = roblox.deserializePlace(fs.readFile(placePath))
local rs = place:GetService("ReplicatedStorage")
local ws = place:GetService("Workspace")
local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local folder = sps:FindFirstChild("ActiveAssetsController", true)
assert(folder, "ActiveAssetsController missing")

-- Random (Roblox API subset)
local Random = {}
Random.__index = Random
function Random.new(seed)
	return setmetatable({ state = (math.floor(seed or 0) % 2147483646) + 1 }, Random)
end
function Random:_next()
	self.state = (self.state * 48271) % 2147483647
	return self.state / 2147483647
end
function Random:NextNumber(a, b)
	if a == nil then
		return self:_next()
	end
	return a + (b - a) * self:_next()
end
function Random:NextInteger(a, b)
	return math.floor(self:NextNumber(a, b + 1))
end

-- the pen: a real PetArea + a terminal inside it + two eggs
local area
for _, d in ipairs(ws:GetDescendants()) do
	if d.Name == "PetArea" and d:IsA("BasePart") then
		area = d
		break
	end
end
assert(area, "no PetArea in the place")
local areaPart = area
-- Lune cannot read a file part's derived Position: the simulation gets a stand-in with the fields it reads
area = { Name = "PetArea", CFrame = areaPart.CFrame, Size = areaPart.Size, Position = areaPart.CFrame.Position, Parent = areaPart.Parent }
local terminal = Instance.new("Part")
terminal.Name = "SimTerminal"
terminal.Size = Vector3.new(3, 5, 2)
terminal.CFrame = area.CFrame * CFrame.new(8, 2.5, -6)
terminal.Transparency = 0
terminal.Parent = area.Parent
local eggs = Instance.new("Folder")
eggs.Name = "PlacedEggRenders"
eggs.Parent = ws
local eggSpots = { Vector3.new(-12, 1.6, 8), Vector3.new(14, 1.6, 10) }
for i, spot in ipairs(eggSpots) do
	local egg = Instance.new("Part")
	egg.Name = "SimEgg" .. i
	egg.Size = Vector3.new(3, 3.2, 3)
	egg.CFrame = area.CFrame * CFrame.new(spot)
	egg.Parent = eggs
end

-- players: the owner stands in the pen, then walks around it
local ownerRoot = { Position = (area.CFrame * CFrame.new(-4, 3, 0)).Position }
local owner = { UserId = 1, Name = "Owner", Character = nil }
local Players = { LocalPlayer = owner }

local function callableStub()
	local stub
	stub = setmetatable({}, {
		__index = function()
			return stub
		end,
		__call = function()
			return true
		end,
	})
	return stub
end
local STUBS = {
	Log = { new = function()
		local logger = {}
		function logger.AtDebug()
			return { Log = function() end }
		end
		return logger
	end },
	Asserts = callableStub(),
	AssetItem = callableStub(),
	Personality = {},
	Mutations = { GetMutationsMap = function()
		return { Rainbow = "Rainbow", Golden = "Golden", Silver = "Silver" }
	end },
	Player = { Optional = { PrimaryPart = function(player)
		return if player == owner then ownerRoot else nil
	end } },
}

local services = { ReplicatedStorage = rs, Workspace = ws, Players = Players }
local game = {
	GetService = function(_, name)
		return assert(services[name], "sim: no service " .. tostring(name))
	end,
}
local loaded = {}
local env
local function simRequire(module)
	if type(module) == "table" then
		return module
	end
	local stub = STUBS[module.Name]
	if stub ~= nil then
		return stub
	end
	if module.Name == "AssetPenSpace" and process.env.SIM_PEN_SRC == "1" and folder:FindFirstChild("AssetPenSpace") == nil then
		module = Instance.new("ModuleScript")
		module.Name = "AssetPenSpace"
		module.Parent = folder
	end
	if loaded[module] == nil then
		local moduleEnv = table.clone(env)
		moduleEnv.script = module
		local source = module.Source
		-- SIM_PEN_SRC=1: the ActiveAssetsController modules come from their src mirrors (iterate without a build)
		local mirror = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/" .. module.Name .. ".luau"
		if process.env.SIM_PEN_SRC == "1" and module.Parent == folder and fs.isFile(mirror) then
			source = fs.readFile(mirror)
		end
		local chunk = luau.load(source, { debugName = module:GetFullName(), environment = moduleEnv })
		loaded[module] = chunk()
	end
	return loaded[module]
end
env = {
	game = game,
	workspace = ws,
	Random = Random,
	Instance = Instance,
	CFrame = CFrame,
	Vector3 = Vector3,
	Color3 = roblox.Color3,
	Enum = roblox.Enum,
	require = simRequire,
	warn = function(...)
		print("[sim_pen_wander] warn:", ...)
	end,
}

local Simulator = simRequire(folder:FindFirstChild("AssetWanderSimulator"))
local Personalities = simRequire(rs.Directory.Assets.Personalities)
local WanderArea = simRequire(folder:FindFirstChild("AssetWanderArea"))
local polished = Simulator.SetFootprint ~= nil

-- the crowd: personalities in their roll proportions, sizes from tiny to giant, a gait per hero like the real clips
local PERSONALITIES = { "Normal", "Normal", "Normal", "Normal", "Lazy", "Lazy", "Loyal", "Energetic", "Energetic", "Shy",
	"Scared", "ExtremelyEnergetic", "UltraLoyal", "JumpCrazy" }
local GAITS = { -- Move ground speed at scale 1, cadence band (HeroMotion styles)
	{ 4.7, 0.7, 1.9 }, { 3.6, 0.7, 1.9 }, { 4.4, 0.7, 1.9 }, { 2.6, 0.65, 1.5 }, { 16.6, 0.75, 2.2 }, { 10.2, 0.75, 2.2 },
	{ 19.5, 0.7, 2.0 }, { 3.4, 0.7, 1.9 },
}
local rng = Random.new(7)
local heroes = {}
for i = 1, HEROES do
	local personality = PERSONALITIES[(i - 1) % #PERSONALITIES + 1]
	if not Personalities.IsPersonality(personality) then
		personality = "Normal"
	end
	local scale = ({ 0.45, 0.7, 0.85, 1.0, 1.0, 1.15, 1.35, 1.6, 2.1 })[(i * 7) % 9 + 1]
	local gait = GAITS[(i * 3) % #GAITS + 1]
	local itemData = { Category = "Hero" .. i, Personality = personality, Mutations = {}, Scale = scale }
	local radius = 1.25 * scale
	local sim = Simulator.new(1000 + i * 17, owner, area, itemData, false, 2.5 + radius * 0.8, math.max(scale * 5 / 4.5, 1))
	if polished then
		sim:SetFootprint(radius)
		local sizeFactor = scale ^ 0.8
		local ground = gait[1] * scale
		local minSpeed = math.min(ground * gait[2], 14) -- AssetComponent._paceProfile (HeroMotion.Pace)
		sim:SetSpeedProfile({ Scale = 0.72 * sizeFactor, Min = minSpeed, Max = math.max(minSpeed, math.min(ground * gait[3], 40)), Tremble = 0.06 })
	end
	local half = area.Size * 0.5
	local start = (area.CFrame * CFrame.new(rng:NextNumber(-half.X + 3, half.X - 3), 0, rng:NextNumber(-half.Z + 3, half.Z - 3))).Position
	local cf = CFrame.new(start.X, area.Position.Y, start.Z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
	table.insert(heroes, { sim = sim, radius = radius, scale = scale, stride = gait[1] * scale, sim_cf = cf, cur = cf, lastYaw = nil })
end

local function yawOf(cf)
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

local stats = { frames = 0, heroFrames = 0, overlap = 0, fence = 0, obstacle = 0, walk = 0, crab = 0, skate = 0,
	turnFrames = 0, snaps = 0, maxTurn = 0, cost = 0, snapBy = {}, crabBy = {}, skateBy = {}, overlapBy = {}, overlapSim = 0, samples = 0,
	stuckSamples = 0, stuckTotal = 0, stuckHeroes = 0, stuckLongest = 0, stuckBy = {}, retargets = 0, retargetBy = {} }
local steps = math.floor(SECONDS / DT)
local settle = math.floor(5 / DT)
local halfX, halfZ = area.Size.X * 0.5, area.Size.Z * 0.5
local STUCK_WINDOW, STUCK_STUDS, STUCK_SAMPLE = 3.0, 0.5, 0.25
local stuckFrames = math.max(math.floor(STUCK_SAMPLE / DT + 0.5), 1)
local HOLD_PHASES = { ReturnGreetingHold = true, AffectionHold = true, GreetingFinish = true }
-- true while the hero stands still on purpose (its own idle, a greeting / affection hold, next to its owner)
local function standingByChoice(h, ownerPosition)
	local sim = h.sim
	if (sim._idleRemaining or 0) > 0 or HOLD_PHASES[sim._phase] then
		return true
	end
	local movement = sim._config and sim._config.Movement
	if sim._phase == "Normal" and movement and movement.FollowOwnerInPen and ownerPosition ~= nil and sim._loyalOwnerOffset ~= nil
		and WanderArea.IsPositionInside(area, ownerPosition) then
		local point = WanderArea.PointNearOwner(area, ownerPosition, sim._loyalOwnerOffset, sim._margin)
		local p = h.sim_cf.Position
		if Vector3.new(point.X - p.X, 0, point.Z - p.Z).Magnitude <= 3.5 then
			return true
		end
	end
	return false
end
local function following(h, ownerPosition)
	local movement = h.sim._config and h.sim._config.Movement
	return h.sim._phase == "Normal" and movement and movement.FollowOwnerInPen and ownerPosition ~= nil
		and WanderArea.IsPositionInside(area, ownerPosition)
end
local ownerMode = process.env.SIM_PEN_OWNER
for frame = 1, steps do
	local t = frame * DT
	-- the owner strolls through the pen for a while, then leaves (SIM_PEN_OWNER=corner: stands by a corner instead)
	if t < SECONDS * 0.6 and ownerMode ~= "0" then
		if ownerMode == "corner" then
			ownerRoot.Position = (area.CFrame * CFrame.new(halfX - 9, 3, halfZ - 9)).Position
		else
			ownerRoot.Position = (area.CFrame * CFrame.new(math.sin(t * 0.3) * 14, 3, math.cos(t * 0.21) * 10)).Position
		end
	else
		ownerRoot = nil
		STUBS.Player.Optional.PrimaryPart = function()
			return nil
		end
	end
	local t0 = os.clock()
	local ownerPosition = ownerRoot and ownerRoot.Position
	for _, h in ipairs(heroes) do
		local prevDest, prevPos = h.sim._destination, h.sim_cf.Position
		local prevWalking = h.sim._phase == "Normal" and h.sim._mode ~= "Curve" and (h.sim._idleRemaining or 0) <= 0
			and not following(h, ownerPosition)
		local target, moving, grounded = h.sim:Step(DT, h.sim_cf)
		local dest = h.sim._destination
		if frame > settle and prevWalking and h.sim._phase == "Normal" and prevDest ~= nil and dest ~= nil
			and Vector3.new(dest.X - prevDest.X, 0, dest.Z - prevDest.Z).Magnitude > 1
			and Vector3.new(prevDest.X - prevPos.X, 0, prevDest.Z - prevPos.Z).Magnitude > 1.5 then
			stats.retargets += 1
			local key = h.sim._config and h.sim._config._id or "?"
			stats.retargetBy[key] = (stats.retargetBy[key] or 0) + 1
		end
		h.moving = moving
		h.jumping = (h.sim._jumpRemaining or 0) > 0 or h.airTail ~= nil and h.airTail > 0
		h.airTail = if (h.sim._jumpRemaining or 0) > 0 then 0.3 else math.max((h.airTail or 0) - DT, 0) -- the render settles after a hop
		h.phase = tostring(h.sim._phase) .. (if (h.sim._idleRemaining or 0) > 0 then "/idle" else "")
		-- the movement batch: simulation grounded on the floor, the render eases toward it
		h.sim_cf = CFrame.new(target.Position.X, area.Position.Y, target.Position.Z) * target.Rotation
		local goal = if grounded then h.sim_cf else target
		local prev = h.cur
		h.cur = prev:Lerp(goal, math.clamp(DT * 8, 0, 1))
		h.prevCur = prev
	end
	stats.cost += os.clock() - t0
	-- stuck: a hero that wants to move (not idling / holding / standing by its owner) but covered < STUCK_STUDS in STUCK_WINDOW s
	if frame > settle and frame % stuckFrames == 0 then
		local keep = math.floor(STUCK_WINDOW / STUCK_SAMPLE + 0.5) + 1
		for _, h in ipairs(heroes) do
			h.ring = h.ring or {}
			table.insert(h.ring, { h.sim_cf.Position, standingByChoice(h, ownerPosition) })
			if #h.ring > keep then
				table.remove(h.ring, 1)
			end
			if #h.ring == keep then
				stats.stuckTotal += 1
				local first = h.ring[1][1]
				local stuck = true
				for _, s in ipairs(h.ring) do
					if s[2] or Vector3.new(s[1].X - first.X, 0, s[1].Z - first.Z).Magnitude >= STUCK_STUDS then
						stuck = false
						break
					end
				end
				if stuck then
					stats.stuckSamples += 1
					h.stuckStreak = (h.stuckStreak or 0) + STUCK_SAMPLE
					if not h.everStuck then
						h.everStuck = true
						stats.stuckHeroes += 1
					end
					stats.stuckLongest = math.max(stats.stuckLongest, h.stuckStreak + STUCK_WINDOW - STUCK_SAMPLE)
					local key = tostring(h.sim._config and h.sim._config._id or "?") .. "/" .. tostring(h.sim._phase)
						.. (if h.sim._retreatActive then "/retreat" else "") .. (if ownerPosition then "" else "/ownerAway")
					stats.stuckBy[key] = (stats.stuckBy[key] or 0) + 1
				else
					h.stuckStreak = 0
				end
			end
		end
	end
	if frame > settle then
		stats.frames += 1
		for i, h in ipairs(heroes) do
			stats.heroFrames += 1
			local p = h.cur.Position
			local l = area.CFrame:PointToObjectSpace(p)
			if math.abs(l.X) + h.radius > halfX + 0.05 or math.abs(l.Z) + h.radius > halfZ + 0.05 then
				stats.fence += 1
			end
			local tl = terminal.CFrame:PointToObjectSpace(p)
			if math.abs(tl.X) < terminal.Size.X * 0.5 + h.radius * 0.5 and math.abs(tl.Z) < terminal.Size.Z * 0.5 + h.radius * 0.5 then
				stats.obstacle += 1
			end
			for _, spot in ipairs(eggSpots) do
				local d = Vector3.new(l.X - spot.X, 0, l.Z - spot.Z).Magnitude
				if d < 1.5 + h.radius * 0.5 then
					stats.obstacle += 1
				end
			end
			for j = i + 1, #heroes do
				local o = heroes[j]
				local d = Vector3.new(p.X - o.cur.Position.X, 0, p.Z - o.cur.Position.Z).Magnitude
				local ds = Vector3.new(h.sim_cf.Position.X - o.sim_cf.Position.X, 0, h.sim_cf.Position.Z - o.sim_cf.Position.Z).Magnitude
				if ds < (h.radius + o.radius) * 0.8 then
					stats.overlapSim += 1
					if h.phase == "Normal" and o.phase == "Normal" and stats.samples < 6 and process.env.SIM_PEN_DEBUG == "1" then
						stats.samples += 1
						local hv = h.sim._space and Vector3.new(h.sim._space.VX, 0, h.sim._space.VZ) or Vector3.zero
						local ov = o.sim._space and Vector3.new(o.sim._space.VX, 0, o.sim._space.VZ) or Vector3.zero
						print(string.format("[sim_pen_wander] overlap t=%.1f d=%.2f r=%.2f+%.2f v=%.1f/%.1f dot=%.2f speeds %.1f %.1f", frame * DT, ds,
							h.radius, o.radius, hv.Magnitude, ov.Magnitude, if hv.Magnitude > 0.1 and ov.Magnitude > 0.1 then hv.Unit:Dot(ov.Unit) else 0,
							h.sim._walkSpeed, o.sim._walkSpeed))
					end
				end
				if d < (h.radius + o.radius) * 0.8 then
					stats.overlap += 1
					local key = h.phase .. "+" .. o.phase
					stats.overlapBy[key] = (stats.overlapBy[key] or 0) + 1
				end
			end
			-- rendered motion
			local delta = p - h.prevCur.Position
			local flat = Vector3.new(delta.X, 0, delta.Z)
			local speed = flat.Magnitude / DT
			local yaw = yawOf(h.cur)
			if h.lastYaw ~= nil and not h.jumping then
				local dy = math.abs(math.atan2(math.sin(yaw - h.lastYaw), math.cos(yaw - h.lastYaw))) / DT
				if dy > math.rad(20) then
					stats.turnFrames += 1
					if dy > math.rad(360) then
						stats.snaps += 1
						stats.snapBy[h.phase] = (stats.snapBy[h.phase] or 0) + 1
					end
				end
				stats.maxTurn = math.max(stats.maxTurn, math.deg(dy))
			end
			h.lastYaw = yaw
			if speed > 0.8 and not h.jumping then
				stats.walk += 1
				local facing = h.cur.LookVector
				local cos = (facing.X * flat.X + facing.Z * flat.Z) / (flat.Magnitude * math.max(math.sqrt(facing.X ^ 2 + facing.Z ^ 2), 1e-6))
				if cos < math.cos(math.rad(35)) then
					stats.crab += 1
					stats.crabBy[h.phase] = (stats.crabBy[h.phase] or 0) + 1
				end
				-- HeroClipPlayer: rate = clamp(v / stride, 0.35, 2.6); below the slowest rate Move only partly covers Idle
				local rate = math.clamp(speed / h.stride, if h.moving then 0.35 else 0, 2.6) -- stopping: the stride slows with the body
				local weight = math.clamp(speed / (0.35 * h.stride), 0.15, 1)
				local slide = weight * math.abs(speed - rate * h.stride)
				if slide > 0.8 then
					stats.skate += 1
					local key = h.phase .. (if speed < 0.35 * h.stride then " slow" else " fast") .. (if process.env.SIM_PEN_DEBUG == "2" then string.format(" stride%.0f", h.stride) else "")
					stats.skateBy[key] = (stats.skateBy[key] or 0) + 1
				end
			end
		end
	end
end

local pairsPerFrame = HEROES * (HEROES - 1) / 2
local overlapShare = stats.overlap / math.max(stats.frames * pairsPerFrame, 1) * HEROES -- ~ share of heroes overlapped
local crabShare = stats.crab / math.max(stats.walk, 1)
local skateShare = stats.skate / math.max(stats.walk, 1)
local snapShare = stats.snaps / math.max(stats.turnFrames, 1)
local costUs = stats.cost / steps / HEROES * 1e6
print(string.format("[sim_pen_wander] %s simulation, %d heroes, %d s in a %.0f x %.0f pen (terminal + 2 eggs)",
	if polished then "ANIMPOLISH" else "legacy", HEROES, SECONDS, area.Size.X, area.Size.Z))
print(string.format("[sim_pen_wander] overlap %.1f%% | fence %d | obstacle %d | max turn %.0f deg/s, snaps %.1f%% | crab %.1f%% | skate %.1f%% | %.1f us/hero/frame",
	overlapShare * 100, stats.fence, stats.obstacle, stats.maxTurn, snapShare * 100, crabShare * 100, skateShare * 100, costUs))
local stuckShare = stats.stuckSamples / math.max(stats.stuckTotal, 1)
local heroMinutes = math.max((steps - settle) * DT / 60 * HEROES, 1e-6)
local retargetRate = stats.retargets / heroMinutes
print(string.format("[sim_pen_wander] stuck %.2f%% of hero-time (%d/%d heroes, longest %.1f s) | retarget %.1f / hero-minute",
	stuckShare * 100, stats.stuckHeroes, HEROES, stats.stuckLongest, retargetRate))
-- (tests/smoke_npc.luau runs this tool in a sandbox with a stand-in `process` that carries a result sink)
local okSink, resultSink = pcall(rawget, process :: any, "simResultSink")
if okSink and type(resultSink) == "function" then
	resultSink({ polished = polished, overlap = overlapShare, fence = stats.fence, obstacle = stats.obstacle, heroFrames = stats.heroFrames,
		stuck = stuckShare, stuckHeroes = stats.stuckHeroes, stuckLongest = stats.stuckLongest, retarget = retargetRate, crab = crabShare,
		skate = skateShare, snaps = snapShare })
end
if process.env.SIM_PEN_DEBUG == "1" or process.env.SIM_PEN_DEBUG == "2" then
	print(string.format("[sim_pen_wander] overlap on simulation positions: %.1f%%", stats.overlapSim / math.max(stats.frames * pairsPerFrame, 1) * HEROES * 100))
	for _, key in ipairs({ "snapBy", "crabBy", "skateBy", "overlapBy", "stuckBy", "retargetBy" }) do
		local parts = {}
		for k, v in pairs(stats[key]) do
			table.insert(parts, k .. "=" .. v)
		end
		print("[sim_pen_wander] " .. key .. ": " .. table.concat(parts, " "))
	end
end
if polished then
	local failures = {}
	if overlapShare > 0.08 then
		table.insert(failures, "overlap")
	end
	if stats.fence > 0 then
		table.insert(failures, "fence")
	end
	if stats.obstacle > stats.heroFrames * 0.002 then
		table.insert(failures, "obstacle")
	end
	if snapShare > 0.05 then
		table.insert(failures, "snaps")
	end
	if crabShare > 0.08 then
		table.insert(failures, "crab")
	end
	if skateShare > 0.09 then
		table.insert(failures, "skate")
	end
	if stuckShare > 0.01 or stats.stuckLongest > 6.0 then
		table.insert(failures, "stuck")
	end
	if retargetRate > 30 then
		table.insert(failures, "retarget")
	end
	if #failures > 0 then
		print("[sim_pen_wander] FAIL: " .. table.concat(failures, ", "))
		process.exit(1)
	end
	print("[sim_pen_wander] OK")
end
