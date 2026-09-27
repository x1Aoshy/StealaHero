--!nocheck
-- World (docs/STAGES_PLAN.md §1, §3, §4, A1, A5, A6, A10 + docs/VISUAL_PASS_PLAN.md D3, D6, D8, D9): baseplate + 6
-- themed stage floors, the 6 kept zones (retired zones 7-9 gone), the D8 scratch layout (procedural buildings archived
-- to ReplicatedStorage, floors/walls/gates kept), the D9 egg ring (villain posts off the street, EggSpots in a
-- horseshoe around them, cover rocks, nests on the markers), the 6 stage villains, side/end walls, a clear main
-- street, the hub (gates, progression board, D6 remodel: plot fences, upgrade signs, leaderboard, Free Gift corner,
-- shops), plots with the locked treadmill display and no gear lying on the lobby floor (D3).

local place = H.place()
local ws = place.Workspace
local PLAN = H.PLAN
local Vector3 = H.roblox.Vector3
local Enum = H.roblox.Enum

local function fmtV(v)
	return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
end

---------------------------------------------------------------------------------------------------
-- 1. Baseplate + stage floors
---------------------------------------------------------------------------------------------------
local baseplate = ws:FindFirstChild("Baseplate")
local groundY = 2.05
if T.check(baseplate ~= nil and baseplate:IsA("BasePart"), "expected Workspace.Baseplate") then
	local s = baseplate.Size
	T.check(math.abs(s.X - 10000) < 1 and math.abs(s.Y - 20) < 1 and math.abs(s.Z - 3000) < 1, "baseplate size expected 10000x20x3000, found %s", tostring(s))
	T.check(baseplate.Anchored and baseplate.CanCollide, "baseplate must be anchored and collidable")
	local c = baseplate.Color
	T.check(c.G > c.R and c.G > c.B, "baseplate should be the green grass floor, found rgb(%d,%d,%d)", c.R * 255, c.G * 255, c.B * 255)
	groundY = baseplate.CFrame.Position.Y + s.Y / 2
end

-- The base game's floor colours before the restructure (§3: each stage floor is recoloured to its theme).
local ORIGINAL_FLOOR_RGB = {
	Forest = { 63, 165, 0 }, Lake = { 87, 162, 16 }, Desert = { 212, 168, 85 },
	Jungle = { 36, 126, 16 }, Snow = { 202, 203, 209 }, Volcano = { 49, 43, 39 },
}
local ground = ws:FindFirstChild("Ground")
local floors = {}
for _, d in ipairs(ground and ground:GetChildren() or {}) do
	local key = string.match(d.Name, "^ZoneFloor_(.+)$")
	if key then
		floors[key] = d
		T.check(PLAN.STAGE_BY_KEY[key] ~= nil, "Workspace.Ground.%s: only the 6 stage floors may remain (retired zone floor?)", d.Name)
	end
	local divider = tonumber(string.match(d.Name, "^ZoneDivider_(%d+)$"))
	if divider then
		T.check(divider <= 6, "Workspace.Ground.%s must be removed (A1: dividers past stage 6 are retired)", d.Name)
	end
end
for _, stage in ipairs(PLAN.STAGES) do
	local floor = floors[stage.key]
	if T.check(floor ~= nil and floor:IsA("BasePart"), "Workspace.Ground.ZoneFloor_%s missing", stage.key) then
		local mn, mx = H.aabb(floor)
		T.check(math.abs(mn.X - stage.xMin) <= 2 and math.abs(mx.X - stage.xMax) <= 2,
			"ZoneFloor_%s spans X %.1f..%.1f, stage %d is X %d..%d", stage.key, mn.X, mx.X, stage.number, stage.xMin, stage.xMax)
		T.check(mx.Y >= 2.04 and mx.Y <= 2.1, "ZoneFloor_%s top %.3f must sit at 2.05-2.08 (nests/eggs are seated on it)", stage.key, mx.Y)
		T.check(not floor.CanCollide and not floor.CanQuery and not floor.CanTouch, "ZoneFloor_%s must be visual only", stage.key)
		local c, o = floor.Color, ORIGINAL_FLOOR_RGB[stage.key]
		local delta = math.abs(c.R * 255 - o[1]) + math.abs(c.G * 255 - o[2]) + math.abs(c.B * 255 - o[3])
		T.check(delta > 30, "ZoneFloor_%s still has the legacy colour rgb(%d,%d,%d) (§3: recolour to the stage theme)", stage.key, o[1], o[2], o[3])
	end
end
for _, key in ipairs(PLAN.RETIRED) do
	T.check(ground == nil or ground:FindFirstChild("ZoneFloor_" .. key) == nil, "Workspace.Ground.ZoneFloor_%s must be removed (A1)", key)
end

-- Nothing visible or collidable past the closing wall after stage 6 (A1: the world ends in a closed wall).
local lastX = PLAN.STAGES[#PLAN.STAGES].xMax
local beyond = {}
for _, top in ipairs(ws:GetChildren()) do
	if top ~= baseplate and top.Name ~= "Terrain" and top.Name ~= "Camera" then
		for _, p in ipairs(top:IsA("BasePart") and { top } or top:GetDescendants()) do
			if p:IsA("BasePart") and (p.CanCollide or p.Transparency < 1) then
				local mn = H.aabb(p)
				if mn.X > lastX + 6 and p.CFrame.Position.Y > groundY - 30 then
					table.insert(beyond, p:GetFullName())
				end
			end
		end
	end
end
T.check(#beyond == 0, "%d part(s) left past stage 6 (X > %d): %s", #beyond, lastX + 6, table.concat(beyond, ", ", 1, math.min(#beyond, 5)))

---------------------------------------------------------------------------------------------------
-- 2. Zones: exactly the 6 kept keys, their attributes and villains (A1, A2, A11, §1)
---------------------------------------------------------------------------------------------------
local guardAreas = H.path(ws, "__OBJECTS/Areas/GuardAreas")
local environments = ws:FindFirstChild("StageEnvironments")
T.check(guardAreas ~= nil, "Workspace.__OBJECTS.Areas.GuardAreas missing")
T.check(environments ~= nil, "Workspace.StageEnvironments missing")
if guardAreas then
	T.check(#guardAreas:GetChildren() == #PLAN.STAGES, "expected exactly %d GuardAreas zones, found %d", #PLAN.STAGES, #guardAreas:GetChildren())
	for _, zone in ipairs(guardAreas:GetChildren()) do
		T.check(PLAN.STAGE_BY_KEY[zone.Name] ~= nil, "GuardAreas.%s is not one of the 6 stage zones (retired zones are destroyed, A1)", zone.Name)
	end
	for _, key in ipairs(PLAN.RETIRED) do
		T.check(guardAreas:FindFirstChild(key) == nil, "retired zone GuardAreas.%s must be destroyed (A1)", key)
	end
	-- A10: gates, board and markers never live under GuardAreas
	for _, d in ipairs(guardAreas:GetDescendants()) do
		if string.match(d.Name, "^StageGate_") or d.Name == "ProgressionBoard" or d.Name == "VillainPost" or string.match(d.Name, "^EggSpot_%d+$") then
			T.check(false, "%s must not live under GuardAreas (A10)", d:GetFullName())
		end
	end
end

local function zoneBoundsContain(zone, pos)
	local bounds = zone and zone:FindFirstChild("Bounds")
	if not bounds or not bounds:IsA("BasePart") then
		return false
	end
	local rel = bounds.CFrame:PointToObjectSpace(pos)
	return math.abs(rel.X) <= bounds.Size.X / 2 and math.abs(rel.Z) <= bounds.Size.Z / 2
end

local R15_BODY = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm",
	"RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }

for _, stage in ipairs(PLAN.STAGES) do
	local zone = guardAreas and guardAreas:FindFirstChild(stage.key)
	if T.check(zone ~= nil, "GuardAreas.%s (stage %d %s) missing", stage.key, stage.number, stage.name) then
		T.check(zone:GetAttribute("ServerChase") == true, "zone %s: ServerChase must be true", stage.key)
		T.check(zone:GetAttribute("StageNumber") == stage.number, "zone %s: StageNumber attribute must be %d", stage.key, stage.number)
		T.check(zone:GetAttribute("ActiveEggCount") == stage.eggs, "zone %s: ActiveEggCount must be %d (§1), found %s", stage.key, stage.eggs, tostring(zone:GetAttribute("ActiveEggCount")))
		for _, name in ipairs({ "Bounds", "ClosestExitPoint", "RequiredSpeedSign", "Nests", "Guard" }) do
			T.check(zone:FindFirstChild(name) ~= nil, "zone %s: %s missing (A10 keeps it)", stage.key, name)
		end

		-- the stage villain (§1, A11, contract C2)
		local guard = zone:FindFirstChild("Guard")
		if guard then
			T.check(guard:GetAttribute("HeroId") == stage.villain, "zone %s: guard HeroId must be %s, found %s", stage.key, stage.villain, tostring(guard:GetAttribute("HeroId")))
			T.check(guard:GetAttribute("VillainName") == stage.villainName, "zone %s: guard VillainName must be %q, found %s", stage.key, stage.villainName, tostring(guard:GetAttribute("VillainName")))
			local rigScale = guard:GetAttribute("RigScale")
			T.check(type(rigScale) == "number" and math.abs(rigScale - stage.scale) < 1e-3, "zone %s: guard RigScale must be %.1f, found %s", stage.key, stage.scale, tostring(rigScale))
			T.check(guard:GetAttribute("GuardState") == "Sleeping", "zone %s: guard must start Sleeping", stage.key)
			local hum = guard:FindFirstChildOfClass("Humanoid")
			if T.check(hum ~= nil and hum.RigType == Enum.HumanoidRigType.R15, "zone %s: guard needs an R15 Humanoid", stage.key) then
				T.check(math.abs(hum.HipHeight - 2 * stage.scale) < 1e-3, "zone %s: HipHeight %.2f must scale with the villain (2 x %.1f)", stage.key, hum.HipHeight, stage.scale)
			end
			local hrp = guard:FindFirstChild("HumanoidRootPart")
			if T.check(hrp ~= nil and hrp:IsA("BasePart"), "zone %s: guard HumanoidRootPart missing", stage.key) then
				T.check(guard.PrimaryPart == hrp, "zone %s: guard PrimaryPart must be its HumanoidRootPart", stage.key)
				T.check(math.abs(hrp.Size.Y - 2 * stage.scale) < 0.01, "zone %s: HumanoidRootPart height %.2f must be 2 x RigScale", stage.key, hrp.Size.Y)
				local look = hrp.CFrame.LookVector
				T.check(look.X < -0.99, "zone %s: villain must face -X toward the hub at its post (look %s)", stage.key, fmtV(look))
				if hum then
					local expectedY = groundY + hum.HipHeight + hrp.Size.Y / 2
					T.check(math.abs(hrp.CFrame.Position.Y - expectedY) < 0.3, "zone %s: villain root Y %.2f, standing on the floor needs %.2f", stage.key, hrp.CFrame.Position.Y, expectedY)
				end
			end
			local loose, solid = {}, {}
			for _, d in ipairs(guard:GetDescendants()) do
				if d:IsA("BasePart") then
					if not d.Anchored then
						table.insert(loose, d.Name)
					end
					if d.CanCollide and d.Name ~= "Collider" then
						table.insert(solid, d.Name)
					end
				end
			end
			T.check(#loose == 0, "zone %s: every guard part must be anchored in the file (%s)", stage.key, table.concat(loose, ", ", 1, math.min(#loose, 4)))
			T.check(#solid == 0, "zone %s: only the Collider may collide (%s)", stage.key, table.concat(solid, ", ", 1, math.min(#solid, 4)))
			local collider = guard:FindFirstChild("Collider")
			T.check(collider ~= nil and collider:IsA("BasePart") and collider.CanCollide, "zone %s: guard Collider (CanCollide=true) missing", stage.key)
			local body = guard:FindFirstChild("Model") or guard -- flattened villain body (owner 2026-09-23)
			if T.check(body ~= nil, "zone %s: guard body missing", stage.key) then
				local missing = {}
				for _, part in ipairs(R15_BODY) do
					if not body:FindFirstChild(part) then
						table.insert(missing, part)
					end
				end
				T.check(#missing == 0, "zone %s: villain body misses R15 parts %s", stage.key, table.concat(missing, ", "))
			end
			local bad = H.badJoints(guard)
			T.check(#bad == 0, "zone %s: %d broken guard joints (%s)", stage.key, #bad, bad[1] or "")
		end
	end
end

-- A11 / §4b: no hero limbs left anywhere in Workspace outside the guards; A10: no decor named like a limb or "cloud_"
local LIMB_NAMES = { Torso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
	LeftArm = true, RightArm = true, LeftLeg = true, RightLeg = true }
for _, n in ipairs(R15_BODY) do
	LIMB_NAMES[n] = true
end
local stray = {}
-- (HUB LAYOUT 2026-09-26: the Hero Park statues are whole hero rigs on purpose, Workspace.Hub.HeroPark.Statues.*.Hero
-- tagged HeroParkStatue; their R15 limb names stay so the Humanoid still dresses them)
local statueRoot = H.path(ws, "Hub/HeroPark/Statues")
local function isParkStatue(d)
	if statueRoot == nil or not d:IsDescendantOf(statueRoot) then
		return false
	end
	local rig = d:FindFirstAncestor("Hero")
	return rig ~= nil and type(rig:GetAttribute("HeroParkStatue")) == "string"
end
for _, d in ipairs(ws:GetDescendants()) do
	if d:IsA("BasePart") and LIMB_NAMES[d.Name] and not isParkStatue(d) then
		local guard = d:FindFirstAncestor("Guard")
		if not (guard and guardAreas and guard:IsDescendantOf(guardAreas)) then
			table.insert(stray, d:GetFullName())
		end
	end
end
T.check(#stray == 0, "%d limb-named part(s) outside the villains (A10/A11): %s", #stray, table.concat(stray, ", ", 1, math.min(#stray, 5)))
for _, root in ipairs({ environments, ws:FindFirstChild("Hub") }) do
	for _, d in ipairs(root and root:GetDescendants() or {}) do
		if string.find(string.lower(d.Name), "cloud_", 1, true) then
			T.check(false, "%s: names must never contain \"cloud_\" (the build deletes them, A10)", d:GetFullName())
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 3. Collidable geometry index (street, villain pads, walkable access to the eggs)
---------------------------------------------------------------------------------------------------
local collidables = {}
for _, d in ipairs(ws:GetDescendants()) do
	if d:IsA("BasePart") and not d:IsA("Terrain") and d.CanCollide and d ~= baseplate and not (guardAreas and d:IsDescendantOf(guardAreas)) then
		local mn, mx = H.aabb(d)
		table.insert(collidables, { part = d, min = mn, max = mx })
	end
end
local function collidablesIn(mn, mx)
	local hits = {}
	for _, c in ipairs(collidables) do
		if c.min.X < mx.X and c.max.X > mn.X and c.min.Y < mx.Y and c.max.Y > mn.Y and c.min.Z < mx.Z and c.max.Z > mn.Z then
			table.insert(hits, c.part)
		end
	end
	return hits
end

-- Is the XZ point inside `part`'s footprint grown by `r`? (exact for upright parts, the world AABB otherwise)
local function inFootprint(part, mn, mx, x, z, r)
	if x < mn.X - r or x > mx.X + r or z < mn.Z - r or z > mx.Z + r then
		return false
	end
	if part.CFrame.UpVector.Y < 0.999 then
		return true
	end
	local rel = part.CFrame:PointToObjectSpace(Vector3.new(x, part.CFrame.Position.Y, z))
	return math.abs(rel.X) <= part.Size.X / 2 + r and math.abs(rel.Z) <= part.Size.Z / 2 + r
end

-- Does the 2D segment (x0,z0)-(x1,z1) cross the footprint of an upright part? (slab test in the part's frame)
local function segmentCrossesFootprint(part, x0, z0, x1, z1)
	local cf = part.CFrame
	local a = cf:PointToObjectSpace(Vector3.new(x0, cf.Position.Y, z0))
	local b = cf:PointToObjectSpace(Vector3.new(x1, cf.Position.Y, z1))
	local t0, t1 = 0, 1
	for _, axis in ipairs({ { a.X, b.X, part.Size.X / 2 }, { a.Z, b.Z, part.Size.Z / 2 } }) do
		local s, d, h = axis[1], axis[2] - axis[1], axis[3]
		if math.abs(d) < 1e-9 then
			if math.abs(s) > h then
				return false
			end
		else
			local ta, tb = (-h - s) / d, (h - s) / d
			if ta > tb then
				ta, tb = tb, ta
			end
			t0, t1 = math.max(t0, ta), math.min(t1, tb)
			if t0 > t1 then
				return false
			end
		end
	end
	return true
end

-- Smallest separating distance (SAT over both parts' horizontal axes) between two upright footprints: > 0 means
-- apart, and the true distance is at least this much.
local function footprintGap(p, q)
	local function frame(part)
		local cf = part.CFrame
		return {
			c = { cf.Position.X, cf.Position.Z },
			axes = { { cf.RightVector.X, cf.RightVector.Z }, { cf.LookVector.X, cf.LookVector.Z } },
			half = { part.Size.X / 2, part.Size.Z / 2 },
		}
	end
	local a, b = frame(p), frame(q)
	local function project(f, ax)
		local centre = f.c[1] * ax[1] + f.c[2] * ax[2]
		local extent = 0
		for i = 1, 2 do
			extent += f.half[i] * math.abs(f.axes[i][1] * ax[1] + f.axes[i][2] * ax[2])
		end
		return centre - extent, centre + extent
	end
	local best = -math.huge
	for _, f in ipairs({ a, b }) do
		for i = 1, 2 do
			local a0, a1 = project(a, f.axes[i])
			local b0, b1 = project(b, f.axes[i])
			best = math.max(best, b0 - a1, a0 - b1)
		end
	end
	return best
end

-- Walkable grid of one stage (1-stud cells, X over the stage, Z between the side walls): a cell is blocked when a
-- body of radius `radius` standing there would touch a collidable part between floor + 0.3 and floor + 5.
local function walkableFrom(stage, floorTop, radius, startX, startZ, ignore)
	local zMin, zMax = PLAN.WALL_SOUTH_Z, PLAN.WALL_NORTH_Z
	local nx, nz = math.floor(stage.xMax - stage.xMin), zMax - zMin
	local function idx(ix, iz)
		return iz * (nx + 1) + ix
	end
	local blocked = {}
	for _, c in ipairs(collidables) do
		if c.max.X > stage.xMin - radius and c.min.X < stage.xMax + radius and c.min.Y < floorTop + 5 and c.max.Y > floorTop + 0.3
			and not (ignore and c.part:IsDescendantOf(ignore)) then
			for ix = math.max(0, math.floor(c.min.X - radius - stage.xMin)), math.min(nx, math.ceil(c.max.X + radius - stage.xMin)) do
				for iz = math.max(0, math.floor(c.min.Z - radius - zMin)), math.min(nz, math.ceil(c.max.Z + radius - zMin)) do
					if inFootprint(c.part, c.min, c.max, stage.xMin + ix, zMin + iz, radius) then
						blocked[idx(ix, iz)] = true
					end
				end
			end
		end
	end
	local seen, queue, head = {}, {}, 1
	local sx, sz = math.floor(startX - stage.xMin + 0.5), math.floor(startZ - zMin + 0.5)
	if not blocked[idx(sx, sz)] then
		seen[idx(sx, sz)] = true
		table.insert(queue, { sx, sz })
	end
	while head <= #queue do
		local cell = queue[head]
		head += 1
		for _, step in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local ax, az = cell[1] + step[1], cell[2] + step[2]
			local k = idx(ax, az)
			if ax >= 0 and ax <= nx and az >= 0 and az <= nz and not seen[k] and not blocked[k] then
				seen[k] = true
				table.insert(queue, { ax, az })
			end
		end
	end
	-- reached(x, z, within): some reachable cell lies within `within` studs of (x, z)
	return function(x, z, within)
		for ix = math.floor(x - within - stage.xMin), math.ceil(x + within - stage.xMin) do
			for iz = math.floor(z - within - zMin), math.ceil(z + within - zMin) do
				local cx, cz = stage.xMin + ix, zMin + iz
				if (cx - x) ^ 2 + (cz - z) ^ 2 <= within * within + 1e-6 and seen[idx(ix, iz)] then
					return true
				end
			end
		end
		return false
	end
end

---------------------------------------------------------------------------------------------------
-- 4. Stage environments: D8 scratch layout (procedural buildings archived to ReplicatedStorage; the floors, walls,
--    gates and lighting stay) and the D9 egg ring (EggSpots in a horseshoe 12-28 studs around a villain post off the
--    street, >= 50% Hidden behind low cover rocks, nests on the markers)
---------------------------------------------------------------------------------------------------
local ALLOWED = {}
for _, m in ipairs(PLAN.ALLOWED_MATERIALS) do
	ALLOWED[m] = true
end
local floorTopY = ground and ground:GetAttribute("ZoneFloorTopY")
if not T.check(type(floorTopY) == "number" and floorTopY >= groundY and floorTopY <= groundY + 0.1,
	"Workspace.Ground.ZoneFloorTopY must give the zone floor top (baseplate top %.3f .. +0.1), found %s", groundY, tostring(floorTopY)) then
	floorTopY = groundY + 0.026
end
for key, floor in pairs(floors) do
	local _, mx = H.aabb(floor)
	T.check(math.abs(mx.Y - floorTopY) <= 0.01, "ZoneFloor_%s top %.3f disagrees with Ground.ZoneFloorTopY %.3f", key, mx.Y, floorTopY)
end

local function keptIn(name, number)
	local rule = PLAN.SCRATCH_KEEP[name]
	return rule == "all" or (type(rule) == "table" and table.find(rule, number) ~= nil)
end

-- §3 build rules, for what stays in the Workspace and for the archived backup alike. Returns the part count.
local function checkBuildRules(root, label)
	local parts, loose, badMat, forbidden, highlights = 0, 0, {}, {}, 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
			if not d.Anchored then
				loose += 1
			end
			local mat = string.match(tostring(d.Material), "([%w]+)$")
			if not ALLOWED[mat] then
				table.insert(badMat, d.Name .. "=" .. tostring(mat))
			end
			if d:IsA("MeshPart") or d:IsA("UnionOperation") then
				table.insert(forbidden, d:GetFullName())
			end
		elseif d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("Decal") or d:IsA("Texture") or d:IsA("SpecialMesh")
			or d:IsA("SurfaceAppearance") or d:IsA("FileMesh") then
			table.insert(forbidden, d:GetFullName())
		elseif d:IsA("Highlight") then
			highlights += 1
			T.check(d.DepthMode == Enum.HighlightDepthMode.Occluded, "%s: outline Highlight must use DepthMode Occluded (A9)", d:GetFullName())
		end
	end
	T.check(parts <= PLAN.MAX_PARTS_PER_STAGE, "%s: %d parts, budget is %d (§3)", label, parts, PLAN.MAX_PARTS_PER_STAGE)
	T.check(loose == 0, "%s: %d unanchored parts (§3: all Anchored)", label, loose)
	T.check(#badMat == 0, "%s: materials outside the allowed set: %s", label, table.concat(badMat, ", ", 1, math.min(#badMat, 5)))
	T.check(#forbidden == 0, "%s: scripts/sounds/meshes/textures are not allowed: %s", label, table.concat(forbidden, ", ", 1, math.min(#forbidden, 5)))
	T.check(highlights <= 1, "%s: at most one outline Highlight per stage model (A9), found %d", label, highlights)
	return parts
end

-- A8 rules of one slowing hazard (still enforced on the archived ones: dragging a group back restores them as they are)
local function checkHazard(d, stage)
	local label = d:GetFullName()
	if T.check(d:IsA("BasePart"), "%s: StageHazard on a non-part", label) then
		local factor = d:GetAttribute("Factor")
		T.check(d:GetAttribute("StageHazard") == "Slow", "%s: StageHazard must be \"Slow\"", label)
		T.check(type(factor) == "number" and factor >= 0.4 and factor <= 0.8, "%s: Factor must be a number in 0.4-0.8, found %s", label, tostring(factor))
		T.check(not d.CanCollide and d.CanTouch and not d.CanQuery, "%s: hazards are CanCollide=false, CanTouch=true, CanQuery=false", label)
		local mn, mx = H.aabb(d)
		T.check(mn.Z > PLAN.STREET_OVERHEAD_HALF_WIDTH or mx.Z < -PLAN.STREET_OVERHEAD_HALF_WIDTH, "%s: hazards stay at |Z| > 15 (off the main street)", label)
		T.check(mn.X > PLAN.HUB_MAX_X and mn.X >= stage.xMin - 1 and mx.X <= stage.xMax + 1, "%s: hazard must be inside stage %d, never in the hub", label, stage.number)
	end
end

-- D8: only the stage models + the EndWall stay under StageEnvironments; the perimeter walls are kept
if environments then
	for _, c in ipairs(environments:GetChildren()) do
		T.check(PLAN.STAGE_BY_KEY[c.Name] ~= nil or c.Name == "EndWall", "Workspace.StageEnvironments.%s is neither a stage model nor the EndWall (D8)", c.Name)
	end
	local endWall = environments:FindFirstChild("EndWall")
	T.check(endWall ~= nil and endWall:FindFirstChild("RedLine") ~= nil and endWall:FindFirstChild("SideWalls") ~= nil,
		"StageEnvironments.EndWall must keep RedLine and SideWalls (D8 keeps the perimeter walls)")
end
local wsHazards = {}
for _, d in ipairs(ws:GetDescendants()) do
	if d:GetAttribute("StageHazard") ~= nil then
		table.insert(wsHazards, d:GetFullName())
	end
end
T.check(#wsHazards == 0, "%d StageHazard part(s) left in the Workspace (D8 archives them with their buildings): %s", #wsHazards,
	table.concat(wsHazards, ", ", 1, math.min(#wsHazards, 4)))

local archive = place.ReplicatedStorage:FindFirstChild(PLAN.ARCHIVE_NAME)
T.check(archive ~= nil, "ReplicatedStorage.%s missing (D8 keeps the procedural buildings as a backup)", PLAN.ARCHIVE_NAME)
local archivedHazards = 0
for _, stage in ipairs(PLAN.STAGES) do
	-- D8 archive: the procedural buildings, kept (never deleted) with their original world CFrames
	local arch = archive and archive:FindFirstChild(stage.key)
	if T.check(arch ~= nil and arch:IsA("Model"), "ReplicatedStorage.%s.%s (Model) missing (D8)", PLAN.ARCHIVE_NAME, stage.key) then
		local from = arch:GetAttribute("ArchivedFrom")
		T.check(type(from) == "string" and H.has(from, "StageEnvironments") and H.has(from, stage.key),
			"archive %s: ArchivedFrom attribute must name Workspace.StageEnvironments.%s, found %s", stage.key, stage.key, tostring(from))
		local parts = checkBuildRules(arch, "archived stage " .. stage.number .. " " .. stage.key)
		T.check(parts > 100, "archive %s holds only %d parts (the stage's procedural buildings must be kept, D8)", stage.key, parts)
		for _, d in ipairs(arch:GetDescendants()) do
			if d:GetAttribute("StageHazard") ~= nil then
				archivedHazards += 1
				checkHazard(d, stage)
			end
		end
	end

	local env = environments and environments:FindFirstChild(stage.key)
	local zone = guardAreas and guardAreas:FindFirstChild(stage.key)
	if T.check(env ~= nil and env:IsA("Model"), "Workspace.StageEnvironments.%s (Model) missing", stage.key) then
		-- D8: what stays in the Workspace
		for _, c in ipairs(env:GetChildren()) do
			T.check(keptIn(c.Name, stage.number), "StageEnvironments.%s.%s must be archived (D8 keeps only EggSpots, VillainPost, EggCover, Boundary (stages 1-3) and Rain (stage 2))",
				stage.key, c.Name)
		end
		for name in pairs(PLAN.SCRATCH_KEEP) do
			if keptIn(name, stage.number) then
				T.check(env:FindFirstChild(name) ~= nil, "StageEnvironments.%s.%s missing (D8 keeps it)", stage.key, name)
			end
		end
		local models = {}
		for _, d in ipairs(env:GetDescendants()) do
			if d:IsA("Model") then
				table.insert(models, d:GetFullName())
			end
		end
		T.check(#models == 0, "stage %d %s: building models left in the Workspace (D8): %s", stage.number, stage.key, table.concat(models, ", ", 1, math.min(#models, 4)))
		checkBuildRules(env, "stage " .. stage.number .. " " .. stage.key)

		-- D9 villain post: mid-stage at |Z| ~ 40 off the street (odd stages +Z, even -Z), facing -X
		local side = if stage.number % 2 == 1 then 1 else -1
		local post = env:FindFirstChild("VillainPost")
		local p = nil
		if T.check(post ~= nil and post:IsA("BasePart"), "StageEnvironments.%s.VillainPost missing (D9)", stage.key) then
			p = post.CFrame.Position
			T.check(post.Anchored and not post.CanCollide and post.Transparency >= 0.99 and (post.Size - Vector3.new(1, 1, 1)).Magnitude < 0.01,
				"%s VillainPost must be an invisible anchored non-collidable 1x1x1 Part", stage.key)
			T.check(math.abs(p.X - (stage.xMin + stage.xMax) / 2) <= PLAN.POST_X_TOLERANCE, "%s VillainPost X %.1f must be the middle of the stage (%.1f) (D9)",
				stage.key, p.X, (stage.xMin + stage.xMax) / 2)
			T.check(p.Z * side > 0 and math.abs(math.abs(p.Z) - PLAN.POST_ABS_Z) <= PLAN.POST_ABS_Z_TOLERANCE,
				"%s VillainPost Z %.1f must be %s%d (+-%d): posts alternate +Z / -Z off the main street (D9)", stage.key, p.Z, side > 0 and "+" or "-",
				PLAN.POST_ABS_Z, PLAN.POST_ABS_Z_TOLERANCE)
			T.check(post.CFrame.LookVector.X < -0.99, "%s VillainPost must face -X toward the hub (look %s)", stage.key, fmtV(post.CFrame.LookVector))
			T.check(p.Y >= groundY - 0.01 and p.Y <= floorTopY + 0.05, "%s VillainPost Y %.3f must be at the floor (%.3f)", stage.key, p.Y, floorTopY)
			T.check(post:GetAttribute("PadSize") == PLAN.POST_PAD and post:GetAttribute("ClearHeight") == PLAN.POST_CLEAR_HEIGHT
				and post:GetAttribute("RingInner") == PLAN.RING_MIN and post:GetAttribute("RingOuter") == PLAN.RING_MAX,
				"%s VillainPost attributes PadSize/ClearHeight/RingInner/RingOuter must be %d/%d/%d/%d", stage.key, PLAN.POST_PAD, PLAN.POST_CLEAR_HEIGHT,
				PLAN.RING_MIN, PLAN.RING_MAX)
			T.check(post:GetAttribute("RingSide") == (side > 0 and "+Z" or "-Z"), "%s VillainPost RingSide must be %q, found %s", stage.key,
				side > 0 and "+Z" or "-Z", tostring(post:GetAttribute("RingSide")))
			local half = PLAN.POST_PAD / 2
			local blocking = collidablesIn(Vector3.new(p.X - half, groundY + 0.2, p.Z - half), Vector3.new(p.X + half, groundY + PLAN.POST_CLEAR_HEIGHT, p.Z + half))
			T.check(#blocking == 0, "%s VillainPost: only the villain may stand on its %dx%d pad up to %d studs, blocked by %s", stage.key, PLAN.POST_PAD, PLAN.POST_PAD,
				PLAN.POST_CLEAR_HEIGHT, #blocking > 0 and blocking[1]:GetFullName() or "")
			local guard = zone and zone:FindFirstChild("Guard")
			local hrp = guard and guard:FindFirstChild("HumanoidRootPart")
			if hrp then
				local g = hrp.CFrame.Position
				T.check(math.abs(g.X - p.X) <= 0.5 and math.abs(g.Z - p.Z) <= 0.5, "%s villain stands at %s, its VillainPost is at %s (D9)", stage.key, fmtV(g), fmtV(p))
			end
		end

		-- D9 EggSpots: 12 (One Piece 14) on the floor, a horseshoe 12-28 studs around the post opening to the street
		local folder = env:FindFirstChild("EggSpots")
		local markers, byName = {}, {}
		for _, c in ipairs(folder and folder:GetChildren() or {}) do
			if string.match(c.Name, "^EggSpot_%d+$") and c:IsA("BasePart") then
				table.insert(markers, c)
				byName[c.Name] = c
			else
				T.check(false, "%s: unexpected child in EggSpots", c:GetFullName())
			end
		end
		T.check(#markers == stage.spots, "stage %d %s: expected %d EggSpots, found %d (§1)", stage.number, stage.key, stage.spots, #markers)
		for i = 1, stage.spots do
			T.check(byName["EggSpot_" .. i] ~= nil, "stage %d %s: EggSpot_%d missing (markers are numbered 1..%d)", stage.number, stage.key, i, stage.spots)
		end
		local hidden, angles = 0, {}
		local streetDir = Vector3.new(0, 0, p and -math.sign(p.Z) or -side)
		for i, m in ipairs(markers) do
			local pos = m.CFrame.Position
			local label = stage.key .. "." .. m.Name
			if m:GetAttribute("Hidden") == true then
				hidden += 1
			end
			T.check(type(m:GetAttribute("Hidden")) == "boolean", "%s: boolean Hidden attribute missing", label)
			T.check(m.Anchored and not m.CanCollide and m.Transparency >= 0.99, "%s: EggSpot must be an invisible anchored non-collidable Part", label)
			T.check((m.Size - Vector3.new(1, 1, 1)).Magnitude < 0.01, "%s: EggSpot must be 1x1x1", label)
			T.check(m.CFrame.UpVector.Y > 0.99, "%s: EggSpot must be upright", label)
			T.check(math.abs(pos.Y - floorTopY) <= 0.05, "%s at Y %.3f must rest on the floor (zone floor top %.3f, D9)", label, pos.Y, floorTopY)
			T.check(pos.X >= stage.xMin and pos.X <= stage.xMax and pos.X >= (stage.minSpotX or 0), "%s at X %.1f is outside stage %d (X %d..%d%s)",
				label, pos.X, stage.number, stage.minSpotX or stage.xMin, stage.xMax, stage.minSpotX and ", stage 1 spots X >= 95" or "")
			T.check(math.abs(pos.Z) >= PLAN.SPOT_MIN_ABS_Z and math.abs(pos.Z) <= PLAN.SPOT_MAX_ABS_Z, "%s at Z %.1f: EggSpots stay at |Z| %d-%d (D9)", label, pos.Z,
				PLAN.SPOT_MIN_ABS_Z, PLAN.SPOT_MAX_ABS_Z)
			T.check(zoneBoundsContain(zone, pos), "%s at %s is outside the zone Bounds", label, fmtV(pos))
			if p then
				local flat = Vector3.new(pos.X - p.X, 0, pos.Z - p.Z)
				local dist = flat.Magnitude
				T.check(dist >= PLAN.RING_MIN - 0.01 and dist <= PLAN.RING_MAX + 0.01, "%s is %.1f studs from the villain post; the ring is %d-%d studs (D9)", label, dist,
					PLAN.RING_MIN, PLAN.RING_MAX)
				if dist > 0 then
					local deg = math.deg(math.acos(math.clamp(flat.Unit:Dot(streetDir), -1, 1)))
					T.check(deg >= PLAN.OPENING_MIN_DEG - 0.01, "%s is only %.0f degrees off the post -> street direction: the horseshoe opens toward the street (>= %d, D9)",
						label, deg, PLAN.OPENING_MIN_DEG)
					table.insert(angles, math.atan2(flat.Z, flat.X))
				end
			end
			for j = i + 1, #markers do
				local d = (markers[j].CFrame.Position - pos).Magnitude
				T.check(d >= PLAN.SPOT_MIN_GAP, "%s and %s are only %.1f studs apart (D9: >= %d)", label, markers[j].Name, d, PLAN.SPOT_MIN_GAP)
			end
		end
		T.check(hidden * 2 >= #markers, "stage %d %s: only %d of %d EggSpots are Hidden (D9: >= 50%%)", stage.number, stage.key, hidden, #markers)
		if #angles >= 2 then
			table.sort(angles)
			local widest, from = -1, 0
			for i, a in ipairs(angles) do
				local nextA = if i < #angles then angles[i + 1] else angles[1] + 2 * math.pi
				if nextA - a > widest then
					widest, from = nextA - a, a
				end
			end
			local rel = (math.atan2(streetDir.Z, streetDir.X) - from) % (2 * math.pi)
			T.check(rel > 0 and rel < widest, "stage %d %s: the widest gap of the egg ring (%.0f degrees) must face the main street (D9 horseshoe)", stage.number,
				stage.key, math.deg(widest))
		end

		-- nests on the markers (stages.luau builds them; AreaEggService spawns into them)
		local nests = zone and zone:FindFirstChild("Nests")
		local nestBySpot = {}
		if T.check(nests ~= nil, "zone %s: Nests folder missing", stage.key) then
			local seen, count = {}, 0
			for _, nest in ipairs(nests:GetChildren()) do
				count += 1
				local spotName = nest:GetAttribute("EggSpot")
				local marker = byName[spotName or ""]
				local label = stage.key .. " nest " .. tostring(spotName)
				local root = nest:FindFirstChild("Root")
				T.check(nest:IsA("Model") and root ~= nil and root:IsA("BasePart") and nest.PrimaryPart == root and nest:FindFirstChild("EggSpotBottom") ~= nil
					and nest:FindFirstChild("EggFitBounds") ~= nil, "%s: nest needs Root (its PrimaryPart), EggSpotBottom and EggFitBounds", label)
				if T.check(marker ~= nil, "%s: nest EggSpot attribute must name one of the stage's EggSpot markers", label) then
					T.check(not seen[spotName], "%s: two nests on the same EggSpot", label)
					seen[spotName] = true
					nestBySpot[spotName] = nest
					T.check(nest:GetAttribute("Hidden") == (marker:GetAttribute("Hidden") == true), "%s: nest Hidden must copy the marker's", label)
					if root then
						local rp, q = root.CFrame.Position, marker.CFrame.Position
						T.check((rp - q).Magnitude <= 0.05, "%s: nest Root sits at %s, its EggSpot is at %s (D9: on the marker)", label, fmtV(rp), fmtV(q))
						T.check(rp.Y - groundY >= -0.001 and rp.Y - groundY <= 0.1, "%s: nest Root Y %.3f must sit 0-0.1 above the baseplate top %.3f", label, rp.Y, groundY)
					end
				end
				local vmn, vmx, onStreet = nil, nil, false
				for _, d in ipairs(nest:GetDescendants()) do
					if d:IsA("BasePart") then
						local a, b = H.aabb(d)
						if a.Z < PLAN.STREET_OVERHEAD_HALF_WIDTH and b.Z > -PLAN.STREET_OVERHEAD_HALF_WIDTH then
							onStreet = true
						end
						if d.Transparency < 1 then
							vmn = vmn and Vector3.new(math.min(vmn.X, a.X), math.min(vmn.Y, a.Y), math.min(vmn.Z, a.Z)) or a
							vmx = vmx and Vector3.new(math.max(vmx.X, b.X), math.max(vmx.Y, b.Y), math.max(vmx.Z, b.Z)) or b
						end
					end
				end
				T.check(not onStreet, "%s: nest parts reach the main street |Z| <= 15", label)
				if vmn then
					local foot = math.max(vmx.X - vmn.X, vmx.Z - vmn.Z)
					local isHidden = nest:GetAttribute("Hidden") == true
					local limit = if isHidden then PLAN.NEST_MAX_FOOTPRINT.hidden else PLAN.NEST_MAX_FOOTPRINT.open
					T.check(foot <= limit + 1e-3, "%s: visible nest footprint %.2f studs, %s nest stays <= %.1f (the cover rocks are sized for it)", label, foot,
						isHidden and "a hidden" or "an open", limit)
				end
			end
			T.check(count == #markers, "zone %s: %d nests for %d EggSpots (one nest per spot)", stage.key, count, #markers)
			T.check(zone:GetAttribute("EggSpotCount") == nil or zone:GetAttribute("EggSpotCount") == count, "zone %s: EggSpotCount attribute disagrees with its nests", stage.key)
			T.check(stage.eggs <= count, "zone %s: %d active eggs need at least as many nests (found %d)", stage.key, stage.eggs, count)
		end

		-- D9 cover rocks: one low Slate rock per hidden spot, between the egg and the villain, off the pad and the street
		local cover = env:FindFirstChild("EggCover")
		local rocks, rocksBySpot = {}, {}
		for _, d in ipairs(cover and cover:GetDescendants() or {}) do
			if d:IsA("BasePart") then
				local owner = d:GetAttribute("EggSpot")
				local marker = byName[owner or ""]
				local mn, mx = H.aabb(d)
				local label = d:GetFullName()
				T.check(marker ~= nil and marker:GetAttribute("Hidden") == true, "%s: a cover rock must name a Hidden EggSpot of its stage (EggSpot attribute %s)", label, tostring(owner))
				T.check(d.Material == Enum.Material.Slate and d.Anchored and d.CanCollide, "%s: cover rocks are Slate, anchored and collidable", label)
				T.check(mx.Y <= floorTopY + PLAN.ROCK_MAX_HEIGHT + 1e-3, "%s: top %.2f studs over the floor, cover rocks stay <= %.1f (D9)", label, mx.Y - floorTopY, PLAN.ROCK_MAX_HEIGHT)
				T.check(mn.Z > PLAN.STREET_OVERHEAD_HALF_WIDTH or mx.Z < -PLAN.STREET_OVERHEAD_HALF_WIDTH, "%s: cover rocks stay off the main street (|Z| > 15)", label)
				if p then
					local half = PLAN.POST_PAD / 2
					T.check(not (mn.X < p.X + half and mx.X > p.X - half and mn.Z < p.Z + half and mx.Z > p.Z - half), "%s stands on the villain's %dx%d pad", label,
						PLAN.POST_PAD, PLAN.POST_PAD)
				end
				local rock = { part = d, min = mn, max = mx, owner = owner }
				table.insert(rocks, rock)
				if owner then
					rocksBySpot[owner] = rocksBySpot[owner] or {}
					table.insert(rocksBySpot[owner], rock)
				end
			end
		end
		for _, m in ipairs(markers) do
			local list = rocksBySpot[m.Name]
			if m:GetAttribute("Hidden") == true then
				T.check(list ~= nil and #list > 0, "%s.%s: a hidden EggSpot needs its cover rock in EggCover (D9)", stage.key, m.Name)
			else
				T.check(list == nil, "%s.%s: an open EggSpot must have no cover rock", stage.key, m.Name)
			end
		end
		for owner, list in pairs(rocksBySpot) do
			-- the rock rests on the floor: its lowest part reaches the floor, every other part stands on it
			local lowest = math.huge
			for _, r in ipairs(list) do
				lowest = math.min(lowest, r.min.Y)
			end
			T.check(lowest <= floorTopY + 0.05 and lowest >= groundY - 1, "%s.%s cover rock bottom %.2f must rest on the floor (%.2f)", stage.key, owner, lowest, floorTopY)
			for _, r in ipairs(list) do
				local grounded = r.min.Y <= floorTopY + 0.05
				for _, o in ipairs(list) do
					if not grounded and o ~= r and r.min.Y >= o.min.Y - 0.01 and r.min.Y <= o.max.Y + 0.01
						and inFootprint(o.part, o.min, o.max, r.part.CFrame.Position.X, r.part.CFrame.Position.Z, 0) then
						grounded = true
					end
				end
				T.check(grounded, "%s floats: every cover part stands on the floor or on its own rock", r.part:GetFullName())
			end
		end
		local closest, pair = math.huge, ""
		for i = 1, #rocks do
			for j = i + 1, #rocks do
				if rocks[i].owner ~= rocks[j].owner then
					local gap = footprintGap(rocks[i].part, rocks[j].part)
					if gap < closest then
						closest, pair = gap, string.format("%s (%s) / %s (%s)", rocks[i].part.Name, tostring(rocks[i].owner), rocks[j].part.Name, tostring(rocks[j].owner))
					end
				end
			end
		end
		T.check(closest >= PLAN.ROCK_ROUTE_WIDTH - 0.01, "stage %d %s: cover rocks of different eggs only %.2f studs apart (%s); walkways stay >= %d studs (D9)",
			stage.number, stage.key, closest, pair, PLAN.ROCK_ROUTE_WIDTH)
		-- nests never clip into a rock, and every hidden egg is hidden from the villain's post
		for spotName, nest in pairs(nestBySpot) do
			local pts = {}
			for _, d in ipairs(nest:GetDescendants()) do
				if d:IsA("BasePart") and d.Transparency < 1 then
					local a, b = H.aabb(d)
					for _, c in ipairs({ { a.X, a.Z }, { a.X, b.Z }, { b.X, a.Z }, { b.X, b.Z }, { (a.X + b.X) / 2, (a.Z + b.Z) / 2 } }) do
						table.insert(pts, { x = c[1], z = c[2], y0 = a.Y, y1 = b.Y })
					end
				end
			end
			local clipped = nil
			for _, pt in ipairs(pts) do
				for _, r in ipairs(rocks) do
					if pt.y0 < r.max.Y and pt.y1 > r.min.Y and inFootprint(r.part, r.min, r.max, pt.x, pt.z, 0) then
						clipped = r.part.Name
					end
				end
			end
			T.check(clipped == nil, "%s nest %s clips into cover rock %s", stage.key, spotName, tostring(clipped))
			local own = rocksBySpot[spotName]
			if p and nest:GetAttribute("Hidden") == true and own then
				local q = byName[spotName].CFrame.Position
				local flat = Vector3.new(q.X - p.X, 0, q.Z - p.Z)
				local tangent = Vector3.new(-flat.Z, 0, flat.X).Unit
				local lo, hi = nil, nil
				for _, pt in ipairs(pts) do
					local t = (pt.x - q.X) * tangent.X + (pt.z - q.Z) * tangent.Z
					if lo == nil or t < lo.t then
						lo = { x = pt.x, z = pt.z, t = t }
					end
					if hi == nil or t > hi.t then
						hi = { x = pt.x, z = pt.z, t = t }
					end
				end
				local targets = { { x = q.X, z = q.Z, what = "centre" } }
				if lo then
					table.insert(targets, { x = lo.x, z = lo.z, what = "left edge" })
					table.insert(targets, { x = hi.x, z = hi.z, what = "right edge" })
				end
				for _, target in ipairs(targets) do
					local crossed = false
					for _, r in ipairs(own) do
						if segmentCrossesFootprint(r.part, p.X, p.Z, target.x, target.z) then
							crossed = true
						end
					end
					T.check(crossed, "%s hidden egg %s: the sight line from the villain post to its %s must cross its cover rock (D9)", stage.key, spotName, target.what)
				end
			end
		end

		-- walkable access: a player on the street reaches every egg; the villain walks from its post to the street
		local reachPlayer = walkableFrom(stage, floorTopY, PLAN.PLAYER_RADIUS, (stage.xMin + stage.xMax) / 2, 0)
		for _, m in ipairs(markers) do
			local q = m.CFrame.Position
			T.check(reachPlayer(q.X, q.Z, 2), "%s.%s: a player walking from the street cannot reach the egg (cover rocks / walls block it, D9)", stage.key, m.Name)
		end
		if p then
			local villainRadius = math.max(2, 1.6 * stage.scale)
			local guard = zone and zone:FindFirstChild("Guard")
			local reachVillain = walkableFrom(stage, floorTopY, villainRadius, p.X, p.Z, guard)
			T.check(reachVillain((stage.xMin + stage.xMax) / 2, 0, 1), "%s: the villain (path radius %.1f) cannot walk from its post to the main street", stage.key, villainRadius)
		end
	end
end
T.check(archivedHazards == PLAN.ARCHIVED_HAZARDS, "ReplicatedStorage.%s holds %d StageHazard parts, D8 archives all %d of the procedural stages", PLAN.ARCHIVE_NAME,
	archivedHazards, PLAN.ARCHIVED_HAZARDS)

-- A6 / D8: the main street stays clear. Over |Z| < 15 from X 76 to the end of stage 6 (1471.5), anything collidable
-- is >= 12 studs up.
local streetBlocks = {}
for _, c in ipairs(collidables) do
	if c.max.X > PLAN.STAGES[1].xMin + 4 and c.min.X < lastX + 0.5
		and c.min.Z < PLAN.STREET_OVERHEAD_HALF_WIDTH - 0.05 and c.max.Z > -PLAN.STREET_OVERHEAD_HALF_WIDTH + 0.05
		and c.min.Y < groundY + PLAN.STREET_HEADROOM - 0.05 then
		table.insert(streetBlocks, string.format("%s %s..%s", c.part:GetFullName(), fmtV(c.min), fmtV(c.max)))
	end
end
T.check(#streetBlocks == 0, "%d collidable part(s) block the main street (|Z| < 15 below 12 studs, §3/A6): %s", #streetBlocks,
	table.concat(streetBlocks, " | ", 1, math.min(#streetBlocks, 4)))

-- A5: invisible side walls at Z ~ +86 / -88 (40 tall) from X 76 to the end wall after stage 6. D8 keeps them: the
-- Boundary walls of stages 1-3 and the EndWall's SideWalls of stages 4-6, 8 in all.
do
	local north, south, endWalls, named = {}, {}, {}, 0
	for _, d in ipairs(environments and environments:GetDescendants() or {}) do
		if d:IsA("BasePart") and (d.Name == "BoundaryWallNorth" or d.Name == "BoundaryWallSouth" or d.Name == "SideWallNorth" or d.Name == "SideWallSouth")
			and d.Transparency >= 0.95 and d.CanCollide and d.Anchored then
			named += 1
		end
		if d:IsA("BasePart") and d.CanCollide and d.Anchored then
			local mn, mx = H.aabb(d)
			local tall = mn.Y <= groundY + 0.5 and mx.Y >= groundY + PLAN.WALL_HEIGHT - 0.5
			if tall and d.Transparency >= 0.95 and mx.X - mn.X > 20 then
				if mn.Z >= PLAN.WALL_NORTH_Z - 3 and mn.Z <= PLAN.WALL_NORTH_Z + 3 then
					table.insert(north, { mn.X, mx.X })
				elseif mx.Z <= PLAN.WALL_SOUTH_Z + 3 and mx.Z >= PLAN.WALL_SOUTH_Z - 3 then
					table.insert(south, { mn.X, mx.X })
				end
			end
			if mn.X >= lastX - 6 and mn.X <= lastX + 10 and mn.Z <= PLAN.WALL_SOUTH_Z and mx.Z >= PLAN.WALL_NORTH_Z and mx.Y >= groundY + 20 then
				table.insert(endWalls, { mn.X, mx.X })
			end
		end
	end
	local function covered(list, from, to)
		table.sort(list, function(a, b)
			return a[1] < b[1]
		end)
		local reach = from
		for _, seg in ipairs(list) do
			if seg[1] > reach + 0.5 then
				return false, reach
			end
			reach = math.max(reach, seg[2])
		end
		return reach >= to - 0.5, reach
	end
	T.check(named == PLAN.SIDE_WALL_COUNT, "expected %d invisible collidable side walls (Boundary + EndWall.SideWalls, D8), found %d", PLAN.SIDE_WALL_COUNT, named)
	T.check(#endWalls > 0, "no closing wall after stage 6 (collidable, spanning Z %d..%d, at X ~%d)", PLAN.WALL_SOUTH_Z, PLAN.WALL_NORTH_Z, lastX)
	local wallX = #endWalls > 0 and endWalls[1][1] or lastX
	for _, side in ipairs({ { "north", north }, { "south", south } }) do
		local ok, reach = covered(side[2], 76, wallX)
		T.check(ok, "the %s side wall (invisible, collidable, 40 tall) must run from X 76 to the end wall at X %.1f; covered up to X %.1f (A5)", side[1], wallX, reach)
	end
end

---------------------------------------------------------------------------------------------------
-- 5. Hub: stage gates, progression board, shops, zone signs (§4, A6, A10)
---------------------------------------------------------------------------------------------------
local hub = ws:FindFirstChild("Hub")
local gates = {}
if T.check(hub ~= nil, "Workspace.Hub missing (§4)") then
	for _, d in ipairs(hub:GetDescendants()) do
		local n = tonumber(string.match(d.Name, "^StageGate_(%d+)$"))
		if n then
			T.check(gates[n] == nil, "two StageGate_%d under Workspace.Hub", n)
			gates[n] = d
		end
	end
end
local function labelsOf(root)
	local list = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") then
			table.insert(list, string.upper(d.Text))
		end
	end
	return table.concat(list, "\n")
end
for _, stage in ipairs(PLAN.STAGES) do
	local gate = gates[stage.number]
	if T.check(gate ~= nil, "Workspace.Hub: StageGate_%d (%s) missing (§4)", stage.number, stage.name) then
		T.check(gate.Parent ~= nil and gate.Parent.Name == "StageGates" and gate.Parent.Parent == hub, "StageGate_%d must live in Workspace.Hub.StageGates (D8 keeps it there)",
			stage.number)
		T.check(gate:GetAttribute("StageNumber") == stage.number and gate:GetAttribute("StageKey") == stage.key
			and gate:GetAttribute("StageName") == stage.name and gate:GetAttribute("VillainName") == stage.villainName
			and gate:GetAttribute("ActiveEggs") == stage.eggs,
			"StageGate_%d attributes must describe stage %d %s / %s / %d eggs", stage.number, stage.number, stage.name, stage.villainName, stage.eggs)
		-- owner 2026-09-23: no arch - the gate is an invisible marker Model (no parts) placed by its pivot
		T.check(H.countClass(gate, "BasePart") == 0, "StageGate_%d must have no arch parts any more (owner removed them)", stage.number)
		local pivot = gate.WorldPivotData
		if pivot then
			local gateX = pivot.Position.X
			if stage.number == 1 then
				T.check(gateX >= 55 and gateX <= PLAN.HUB_MAX_X, "StageGate_1 at X %.1f must stand at the hub edge (X <= 75) facing the hub", gateX)
			else
				T.check(math.abs(gateX - stage.xMin) <= 3, "StageGate_%d at X %.1f must stand at the stage start (X ~%d)", stage.number, gateX, stage.xMin)
			end
			-- the gate's zone signs (A10)
			local zone = guardAreas and guardAreas:FindFirstChild(stage.key)
			local rss = zone and zone:FindFirstChild("RequiredSpeedSign")
			if rss then
				local smn, smx = H.groupAabb(rss)
				if smn then
					T.check(math.abs((smn.X + smx.X) / 2 - gateX) <= 6, "%s RequiredSpeedSign at X %.1f must stand next to its gate (X %.1f)", stage.key, (smn.X + smx.X) / 2, gateX)
					T.check(smn.Z >= PLAN.STREET_OVERHEAD_HALF_WIDTH or smx.Z <= -PLAN.STREET_OVERHEAD_HALF_WIDTH, "%s RequiredSpeedSign must stay off the main street", stage.key)
				end
			end
			local exit = zone and zone:FindFirstChild("ClosestExitPoint")
			if exit and exit:IsA("BasePart") then
				local e = exit.CFrame.Position
				T.check(math.abs(e.X - gateX) <= 6 and math.abs(e.Z) <= 1, "%s ClosestExitPoint %s must sit at its gate's hub-side edge (gate X %.1f)", stage.key, fmtV(e), gateX)
				T.check(zoneBoundsContain(zone, e), "%s ClosestExitPoint must lie inside the zone Bounds (GuardEscapePrediction asserts it)", stage.key)
			end
		end
		for _, part in ipairs(gate:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				local pmn, pmx = H.aabb(part)
				T.check(pmn.Z >= PLAN.STREET_OVERHEAD_HALF_WIDTH - 0.05 or pmx.Z <= -PLAN.STREET_OVERHEAD_HALF_WIDTH + 0.05 or pmn.Y >= groundY + PLAN.STREET_HEADROOM,
					"%s: collidable gate parts stay at |Z| >= 15 or >= 12 studs up (A6)", part:GetFullName())
			end
		end
		-- owner 2026-09-23: the "STAGE n" / "LEAVING STAGE n" sign panels are gone (the gate keeps its attributes)
		T.check(gate:FindFirstChild("SignPanel") == nil and gate:FindFirstChildWhichIsA("SurfaceGui", true) == nil,
			"StageGate_%d must not carry a stage sign any more (owner removed them)", stage.number)
	end
end
for n in pairs(gates) do
	T.check(PLAN.STAGE_BY_NUMBER[n] ~= nil, "StageGate_%d is not one of the 6 stages", n)
end

-- owner 2026-09-23: no hub "STAGES" progression board ("is not really needed")
T.check(hub == nil or hub:FindFirstChild("ProgressionBoard", true) == nil, "Workspace.Hub.ProgressionBoard must be gone (owner removed it)")

-- shops around the stage-1 entrance, hub side (§4, A5/A6)
local stands = ws:FindFirstChild("Stands")
local SHOPS = {
	{ "Sell Heroes", { "Models/Sell Stands", "Prompts/SellAll", "Prompts/SellHeldAsset" } },
	{ "Trails", { "Models/GearShopStand", "Pads/TrailShop" } },
}
for _, shop in ipairs(SHOPS) do
	local mn, mx
	for _, p in ipairs(shop[2]) do
		local inst = stands and H.path(stands, p)
		if T.check(inst ~= nil, "Workspace.Stands.%s missing (%s shop)", p, shop[1]) then
			local a, b = H.groupAabb(inst)
			if a then
				mn = mn and Vector3.new(math.min(mn.X, a.X), math.min(mn.Y, a.Y), math.min(mn.Z, a.Z)) or a
				mx = mx and Vector3.new(math.max(mx.X, b.X), math.max(mx.Y, b.Y), math.max(mx.Z, b.Z)) or b
			end
		end
	end
	if mn then
		T.check(mx.X <= PLAN.SHOP_MAX_X + 0.05, "%s shop reaches X %.1f (hub side of the stage-1 entrance: X <= %d)", shop[1], mx.X, PLAN.SHOP_MAX_X)
		T.check(mx.X >= PLAN.SHOP_MAX_X - 20, "%s shop (max X %.1f) must stand around the stage-1 entrance", shop[1], mx.X)
		T.check(mn.Z >= PLAN.STREET_OVERHEAD_HALF_WIDTH or mx.Z <= -PLAN.STREET_OVERHEAD_HALF_WIDTH, "%s shop must leave the street to stage 1 open (|Z| <= 15)", shop[1])
	end
end

-- A1: AdminAbuseEggSpawn moved onto stage 1's street
local adminSpawn = H.path(ws, "__OBJECTS/Areas/AdminAbuseEggSpawn")
if T.check(adminSpawn ~= nil and adminSpawn:IsA("BasePart"), "__OBJECTS.Areas.AdminAbuseEggSpawn missing") then
	local p = adminSpawn.CFrame.Position
	T.check(math.abs(p.X - PLAN.ADMIN_EGG_SPAWN.x) <= 1 and math.abs(p.Z - PLAN.ADMIN_EGG_SPAWN.z) <= 1,
		"AdminAbuseEggSpawn at %s must be at stage 1's street (%d, %d) (A1)", fmtV(p), PLAN.ADMIN_EGG_SPAWN.x, PLAN.ADMIN_EGG_SPAWN.z)
end

---------------------------------------------------------------------------------------------------
-- 6. Plots + locked treadmill display (unchanged hub contract)
---------------------------------------------------------------------------------------------------
local plots = ws:FindFirstChild("Plots")
T.check(plots ~= nil and #plots:GetChildren() == 6, "expected exactly 6 plots, found %d", plots and #plots:GetChildren() or 0)
for i = 1, 6 do
	local plot = plots and plots:FindFirstChild(tostring(i))
	if T.check(plot ~= nil, "plot %d missing", i) then
		local center = plot:FindFirstChild("CenterPoint")
		T.check(center ~= nil and math.abs(center.CFrame.Position.Y - groundY) < 6, "plot %d: CenterPoint must sit at ground level", i)
		T.check(center ~= nil and center.CFrame.Position.X <= PLAN.HUB_MAX_X, "plot %d must be in the hub (X <= 75)", i)
		T.check(plot:FindFirstChild("TreadmillBottom") ~= nil, "plot %d: TreadmillBottom missing (treadmill detection)", i)
		local display = plot:FindFirstChild("SpeedsterTreadmillDisplay")
		if T.check(display ~= nil, "plot %d: SpeedsterTreadmillDisplay missing (the Speedsters treadmill must be visible in the .rbxl)", i) then
			-- Gekko 2026-09-24: the display is the tier-1 BasicTreadmill model from Treadmills.rbxl (TreadmillModel attribute)
			local model = nil
			for _, d in ipairs(display:GetDescendants()) do
				if d:GetAttribute("TreadmillModel") ~= nil then
					model = d
					break
				end
			end
			T.check(model ~= nil or display:GetAttribute("TreadmillModel") ~= nil, "plot %d: display lacks the tier-1 treadmill model", i)
			T.check(H.path(display, "LockAnchor/LockBillboard") ~= nil, "plot %d: display lacks the LOCKED billboard", i)
			local parts, solid = 0, {}
			for _, d in ipairs(display:GetDescendants()) do
				if d:IsA("BasePart") then
					parts += 1
					if d.CanCollide or d.CanQuery or d.CanTouch then
						table.insert(solid, d.Name)
					end
				end
			end
			T.check(parts >= 3, "plot %d: display has only %d parts", i, parts)
			T.check(#solid == 0, "plot %d: display parts must be visual-only (no collide/query/touch): %s", i, table.concat(solid, ", "))
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 7. Gear (D3): no gear givers and no tool lying on the lobby floor; the starter kit comes from GearTools.ShopItems
---------------------------------------------------------------------------------------------------
T.check(ws:FindFirstChild("GearGivers") == nil, "Workspace.GearGivers must be removed (D3: no gear lying on the lobby floor)")
do
	local givers, tools = {}, {}
	for _, d in ipairs(ws:GetDescendants()) do
		if string.find(d.Name, "GearGiver", 1, true) then
			table.insert(givers, d:GetFullName())
		end
		if d:IsA("Tool") then
			table.insert(tools, d:GetFullName())
		end
	end
	T.check(#givers == 0, "%d GearGiver instance(s) left in the Workspace (D3): %s", #givers, table.concat(givers, ", ", 1, math.min(#givers, 4)))
	T.check(#tools == 0, "%d Tool(s) lying in the Workspace (D3: gear is only in Backpacks): %s", #tools, table.concat(tools, ", ", 1, math.min(#tools, 4)))
	local okPack, starterPack = pcall(function()
		return place:GetService("StarterPack")
	end)
	T.check(okPack and starterPack ~= nil and #starterPack:GetChildren() == 0, "StarterPack must stay empty (D3: the kit is granted per player through Backpack + StarterGear)")
	local shopItems = H.path(place.ReplicatedStorage, "GearTools/ShopItems")
	for _, name in ipairs(PLAN.STARTER_GEAR) do
		local tool = shopItems and shopItems:FindFirstChild(name)
		if T.check(tool ~= nil and tool:IsA("Tool"), "GearTools.ShopItems.%s (starter gear Tool) missing (D3)", name) then
			T.check(tool:GetAttribute("GearName") == name and tool:GetAttribute("ItemType") == "Gear" and tool.CanBeDropped == false,
				"GearTools.ShopItems.%s must carry GearName=%q, ItemType=\"Gear\" and CanBeDropped=false (D3)", name, name)
		end
	end
	for _, name in ipairs(PLAN.NOT_STARTER_GEAR) do
		T.check(shopItems ~= nil and shopItems:FindFirstChild(name) ~= nil, "GearTools.ShopItems.%s must still exist (advanced gear, only not granted at start)", name)
	end
end

---------------------------------------------------------------------------------------------------
-- 8. Hub remodel (D6): the scripted contracts of the remodelled hub objects stay intact
---------------------------------------------------------------------------------------------------
local function colorIs(c, r, g, b, tolerance)
	return math.abs(c.R * 255 - r) <= tolerance and math.abs(c.G * 255 - g) <= tolerance and math.abs(c.B * 255 - b) <= tolerance
end

-- plot upgrade signs: every name PlotUpgradeController / TreadmillUpgrade read, and the gold-to-red price button
local caps, braces, gems = 0, 0, 0
for i = 1, 6 do
	local plot = plots and plots:FindFirstChild(tostring(i))
	for _, spec in ipairs({ { "PlotUpgrade", "Upgrade Pen" }, { "TreadmillUpgrade", "Upgrade Treadmill" } }) do
		local model = plot and plot:FindFirstChild(spec[1])
		local label = "plot " .. i .. " " .. spec[1]
		if T.check(model ~= nil, "%s missing", label) then
			local signs = 0
			for _, c in ipairs(model:GetChildren()) do
				if c.Name == "Sign" then
					signs += 1
				end
			end
			T.check(signs == 1, "%s: exactly one child named Sign (the controllers index it), found %d", label, signs)
			local sign = model:FindFirstChild("Sign")
			if T.check(sign ~= nil and sign:IsA("BasePart"), "%s: Sign (BasePart) missing", label) then
				local canUpgrade = sign:FindFirstChild("CanUpgrade")
				T.check(canUpgrade ~= nil and canUpgrade:IsA("BillboardGui"), "%s: Sign.CanUpgrade (BillboardGui) missing", label)
				local surface = sign:FindFirstChild("SurfaceGui")
				if T.check(surface ~= nil and surface:IsA("SurfaceGui"), "%s: Sign.SurfaceGui missing", label) then
					local info, level = surface:FindFirstChild("Info"), surface:FindFirstChild("Level")
					local frame = surface:FindFirstChild("Frame")
					local upgrade = frame and frame:FindFirstChild("Upgrade")
					local robux = frame and frame:FindFirstChild("RobuxUpgrade")
					local cost = upgrade and upgrade:FindFirstChild("Cost")
					T.check(info ~= nil and info:IsA("TextLabel") and level ~= nil and level:IsA("TextLabel"), "%s: SurfaceGui.Info / Level (TextLabel) missing", label)
					T.check(frame ~= nil and frame:IsA("GuiObject"), "%s: SurfaceGui.Frame missing", label)
					T.check(upgrade ~= nil and upgrade:IsA("GuiButton") and robux ~= nil and robux:IsA("GuiButton"), "%s: Frame.Upgrade / Frame.RobuxUpgrade (GuiButton) missing", label)
					T.check(cost ~= nil and cost:IsA("TextLabel"), "%s: Upgrade.Cost (TextLabel) missing", label)
					if info and info:IsA("TextLabel") then
						T.check(info.Text == spec[2], "%s: Info must read %q, found %q", label, spec[2], info.Text)
						local face = surface:FindFirstChild("HubFace")
						T.check(face ~= nil and face:IsA("GuiObject") and face.ZIndex < info.ZIndex, "%s: SurfaceGui.HubFace must be drawn below Info (D6)", label)
					end
					if upgrade and upgrade:IsA("GuiButton") then
						T.check(colorIs(upgrade.BackgroundColor3, 255, 255, 255, 1), "%s: Upgrade.BackgroundColor3 must be white (the gradient carries the colour)", label)
						local gradient = upgrade:FindFirstChildOfClass("UIGradient")
						if T.check(gradient ~= nil and gradient.Enabled, "%s: Upgrade's first UIGradient must be enabled (affordability channel)", label) then
							local kp = gradient.Color.Keypoints
							local top, bottom = kp[1].Value, kp[#kp].Value
							if math.abs(gradient.Rotation - 270) < 1 or math.abs(gradient.Rotation + 90) < 1 then
								top, bottom = bottom, top
							end
							local vertical = math.abs(math.abs(gradient.Rotation) - 90) < 1 or math.abs(gradient.Rotation - 270) < 1
							T.check(vertical and top.R > 0.8 and top.G > 0.5 and top.B < 0.45 and bottom.R > 0.35 and bottom.G < 0.3 and bottom.B < 0.3,
								"%s: the price button gradient must run gold (top) to deep red (bottom) (D6)", label)
						end
					end
				end
			end
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") and string.match(d.Name, "^HubSign") then
					T.check(d.Anchored and not d.CanCollide, "%s: remodel part %s must be anchored and non-collidable", label, d.Name)
				end
			end
		end
	end
	-- plot fences: still walk-through, prompts kept, remodel parts present
	local pen = plot and H.path(plot, "ToUpdate/StarterPen")
	if T.check(pen ~= nil, "plot %d: ToUpdate.StarterPen missing", i) then
		local solid = {}
		for _, d in ipairs(pen:GetDescendants()) do
			if d:IsA("BasePart") then
				if d.CanCollide then
					table.insert(solid, d.Name)
				end
				if d.Name == "HubFenceCap" then
					caps += 1
				elseif d.Name == "HubFenceBrace" then
					braces += 1
				elseif d.Name == "HubFenceGem" then
					gems += 1
				end
			end
		end
		T.check(#solid == 0, "plot %d: StarterPen parts must stay non-collidable (D6): %s", i, table.concat(solid, ", ", 1, math.min(#solid, 4)))
		for _, name in ipairs({ "Prompt1", "Prompt2", "Prompt3", "GridCenter" }) do
			T.check(pen:FindFirstChild(name, true) ~= nil, "plot %d: StarterPen.%s must be kept", i, name)
		end
	end
end
T.check(caps == 126 and braces == 120 and gems > 0, "D6 plot fences: expected 126 HubFenceCap, 120 HubFenceBrace and some HubFenceGem parts, found %d / %d / %d",
	caps, braces, gems)

-- leaderboards (HEROBOARD 2026-09-26): the four free-standing boards are retired (scripts/steps/post_leaderboards.luau)
-- and ONE HERO BOARD hangs on HubWall_EastSouth (scripts/steps/post_x_hero_board.luau): a page per stat in one SurfaceGui,
-- a tab + click part per page, a top-3 podium; filled at runtime by LeaderboardService (tests/smoke_heroboard.luau
-- checks the wall / tab / podium geometry)
T.check(H.path(ws, "__OBJECTS/Leaderboards") == nil, "__OBJECTS.Leaderboards (the old four boards) must stay retired")
local heroBoard = hub and hub:FindFirstChild("HeroBoard")
if T.check(heroBoard ~= nil and heroBoard:IsA("Model"), "Workspace.Hub.HeroBoard (Model) missing") then
	local gui = H.path(heroBoard, "Screen/BoardGui")
	T.check(gui ~= nil and gui:IsA("SurfaceGui") and gui.Enabled and gui.Face == Enum.NormalId.Front and gui.LightInfluence == 0 and gui.MaxDistance >= 200,
		"HeroBoard.Screen.BoardGui must be an enabled front SurfaceGui (LightInfluence 0, MaxDistance >= 200)")
	local pages = gui and H.path(gui, "Board/List/Pages")
	for _, spec in ipairs({ { "Networth", "TOTAL NETWORTH" }, { "SpeedPower", "TOTAL SPEED" }, { "TimePlayed", "IN-GAME TIME" }, { "EggsHatched", "EGGS HATCHED" } }) do
		local page = pages and pages:FindFirstChild("Page_" .. spec[1])
		if T.check(page ~= nil and page:GetAttribute("LeaderboardStat") == spec[1], "HeroBoard page Page_%s (LeaderboardStat %q) missing", spec[1], spec[1]) then
			local header = H.path(page, "Header/Title")
			T.check(header ~= nil and header.Text == spec[2], "Page_%s header must read %q", spec[1], spec[2])
			for i = 1, 10 do
				local row = page:FindFirstChild(string.format("Row%02d", i))
				T.check(row ~= nil and row.Visible == false and H.path(row, "Rank/Label") ~= nil and row:FindFirstChild("Avatar") ~= nil
					and row:FindFirstChild("PlayerName") ~= nil and row:FindFirstChild("Value") ~= nil,
					"Page_%s Row%02d must exist hidden with Rank.Label, Avatar, PlayerName and Value", spec[1], i)
			end
			local tab = H.path(gui, "Board/Tabs/Tab_" .. spec[1])
			local hit = H.path(heroBoard, "TabButtons/TabHit_" .. spec[1])
			T.check(tab ~= nil and tab:GetAttribute("LeaderboardStat") == spec[1] and hit ~= nil and hit:FindFirstChildOfClass("ClickDetector") ~= nil
				and hit:GetAttribute("LeaderboardStat") == spec[1], "Page_%s needs its tab and its TabHit part with a ClickDetector", spec[1])
		end
	end
	local baked = 0
	for _, d in ipairs(heroBoard:GetDescendants()) do
		if string.sub(d.Name, 1, 7) == "Player_" or d:IsA("Humanoid") then
			baked += 1
		end
	end
	T.check(baked == 0, "HeroBoard ships %d baked player rows / avatars (they are runtime only)", baked)
	local _, mx = H.groupAabb(heroBoard)
	T.check(mx ~= nil and mx.X <= 71.25, "HeroBoard reaches X %.2f, past HubWall_EastSouth's face (71.2)", mx and mx.X or 0)
	for rank = 1, 3 do
		T.check(H.path(heroBoard, "Podium/Spot" .. rank .. "/Stand") ~= nil and H.path(heroBoard, "Podium/Spot" .. rank .. "/FrontFace/NamePlate") ~= nil,
			"HeroBoard podium Spot%d (Stand + FrontFace.NamePlate) missing", rank)
	end
end
T.check(place:GetService("ServerScriptService"):FindFirstChild("LeaderboardService") ~= nil, "ServerScriptService.LeaderboardService missing")

T.check(stands ~= nil and H.path(stands, "Models/GearShopStand/StandBounds") ~= nil, "Stands.Models.GearShopStand.StandBounds must be kept")

-- Free Gift corner: the CLICK TO CLAIM board and the gift chest open the Free Gift window
local freeGift = hub and hub:FindFirstChild("FreeGift")
local chest = nil
if T.check(freeGift ~= nil, "Workspace.Hub.FreeGift missing (D6)") then
	for _, name in ipairs({ "ClaimSign", "GiftChest" }) do
		local model = freeGift:FindFirstChild(name)
		if T.check(model ~= nil and model:IsA("Model"), "Hub.FreeGift.%s (Model) missing", name) then
			T.check(model:FindFirstChildWhichIsA("ClickDetector", true) ~= nil, "Hub.FreeGift.%s needs a ClickDetector (HubFreeGift opens the window)", name)
		end
	end
	chest = freeGift:FindFirstChild("GiftChest")
	local loose = {}
	for _, d in ipairs(freeGift:GetDescendants()) do
		if d:IsA("BasePart") and not d.Anchored then
			table.insert(loose, d:GetFullName())
		elseif d:IsA("ParticleEmitter") then
			local uri = H.uri(d, "TextureContent")
			T.check(uri ~= nil and string.sub(uri, 1, 11) == "rbxasset://", "%s: hub particles use a built-in rbxasset texture", d:GetFullName())
		end
	end
	T.check(#loose == 0, "Hub.FreeGift: every part anchored (%s)", table.concat(loose, ", ", 1, math.min(#loose, 3)))
	T.check(H.countClass(freeGift, "Sound") == 0, "Hub.FreeGift must be silent")
	local claimSign = freeGift:FindFirstChild("ClaimSign")
	T.check(claimSign ~= nil and H.has(labelsOf(claimSign), "CLICK TO CLAIM"), "Hub.FreeGift.ClaimSign must read \"CLICK TO CLAIM\" (D6)")
end
for _, spec in ipairs({ { "Sell Stands", "SELL" }, { "GearShopStand", "TRAILS SHOP" } }) do
	local stall = stands and H.path(stands, "Models/" .. spec[1])
	T.check(stall ~= nil and H.has(labelsOf(stall), spec[2]), "Stands.Models.%s must carry its %q sign (D6)", spec[1], spec[2])
end
local giftPart = H.path(ws, "__OBJECTS/GroupReward")
local giftPrompt = giftPart and giftPart:FindFirstChildOfClass("ProximityPrompt")
if T.check(giftPrompt ~= nil, "__OBJECTS.GroupReward.ProximityPrompt missing (the chest's opener)") then
	T.check(giftPrompt.Enabled == true and giftPrompt.MaxActivationDistance >= 8,
		"__OBJECTS.GroupReward.ProximityPrompt must be enabled with MaxActivationDistance >= 8 (D6 re-enables it)")
	if chest and giftPart:IsA("BasePart") then
		local mn, mx = H.groupAabb(chest)
		local g = giftPart.CFrame.Position
		T.check(mn ~= nil and g.X >= mn.X - 0.5 and g.X <= mx.X + 0.5 and g.Z >= mn.Z - 0.5 and g.Z <= mx.Z + 0.5 and g.Y >= mn.Y - 0.5 and g.Y <= mx.Y + 0.5,
			"__OBJECTS.GroupReward at %s must sit inside the gift chest", fmtV(g))
	end
end
