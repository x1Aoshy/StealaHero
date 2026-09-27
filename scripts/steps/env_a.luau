-- scripts/steps/env_a.luau
-- Build step (ENV-A; owner SCRATCH in the visual pass): themed environments for game-plan stages 1-3 plus each stage's
-- villain post and egg ring (docs/VISUAL_PASS_PLAN.md D9).
--
--   Stage 1  The Avengers    (zone key Forest, X  72 - 170)  sleek sci-fi city: Avengers Tower with a walkable lobby,
--                                                            glass towers, holo gates, Quinjet hangar roof + landing deck
--   Stage 2  Justice League  (zone key Lake,   X 170 - 316)  dark rainy Gotham street: gothic tower + skybridge, neon,
--                                                            Bat-signal, fire stairs, cathedral square, Hall of Justice
--   Stage 3  Spider-Verse    (zone key Desert, X 316 - 526)  Queens rooftops: fire escapes, web-bridge rooftop routes
--                                                            (6 -> 10 -> 14 studs), water towers, crane, construction site
--
-- Contract (docs/STAGES_PLAN.md sections 3 and 4b, docs/VISUAL_PASS_PLAN.md D8 and D9):
--   * Workspace.StageEnvironments (Folder, shared with ENV-B) . <Key> (Model); this step only replaces its own three
--     children and recolours only its own Workspace.Ground.ZoneFloor_<Key> (kept visual-only at its height).
--   * D9 egg ring, placed and checked by scripts/steps/post_scratch_layout.luau (BuildRing / ValidateRing):
--     <Key>.VillainPost (invisible anchored non-collidable 1x1x1 Part on the floor) in the middle of the stage X range
--     at |Z| = 40 (stages 1 and 3 on +Z, stage 2 on -Z), facing -X toward the hub; <Key>.EggSpots.EggSpot_1..12 on
--     the floor in a horseshoe 12-28 studs around it that opens toward the main street (|Z| 16..72, inside the
--     stage and its zone Bounds, stage 1 X >= 95, >= 3 studs apart), attribute Hidden on half of them, each hidden
--     spot tucked behind a low Slate rock (<= 3.5 studs, anchored, collidable) in <Key>.EggCover. The villain's
--     20x20 pad and 8-stud walkways between the rocks stay clear. STAGES builds the nests on the markers and moves
--     the villain onto the post.
--   * D8 scratch layout: the themed buildings and props below are still built (and checked) here, but the
--     post_scratch_layout post step archives them to ReplicatedStorage.Archived_ProceduralEnvironments.<Key>; only
--     EggSpots, VillainPost, EggCover, Boundary and Rain stay in the Workspace. The ring may overlap archived buildings.
--   * Main street: over |Z| <= 15 no collidable part reaches below 12 studs above the floor. Rooftops connect
--     through no-jump ramps (tilted slabs <= RAMP_LIMIT_DEG, 9 wide with rails = 8.2 clear). Decorative parts are
--     CanCollide/CanQuery/CanTouch=false.
--   * Invisible collidable side walls at Z ~ +86 / -88, 40 studs tall, over X 76 - 526 (ENV-B continues them).
--   * Slowing hazards: parts with StageHazard = "Slow" + Factor (0.4-0.8), CanCollide=false, CanTouch=true,
--     CanQuery=false, at |Z| > 15; more of them each stage (STAGES runs them).
--   * <= 450 parts per stage, all anchored; Plastic/SmoothPlastic/Neon/Glass/Wood/Metal/Slate only; no scripts, sounds,
--     meshes, decals or textures (the Lake Rain.RainVolume is only a region marker; StageWeather rains on the client). No part is named like a
--     character limb and nothing contains "cloud_" (the build deletes those).
--
-- Lune notes: explicit CFrames only (CFrame.Angles / fromMatrix; never CFrame.lookAt, mirrored in Lune 0.10.5);
-- Model.WorldPivotData is written; Instance.new ignores its parent argument; ParticleEmitter texture via TextureContent.
--
-- Idempotent: the three stage models are rebuilt from scratch on every run. The step validates itself (budget, X range,
-- street clearance, walls, ramp angles, hazards, and every D9 ring rule) and errors on any violation, so a bad
-- coordinate never ships silently.

local roblox = require("@lune/roblox")
local ScratchLayout = require("./post_scratch_layout")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local Step = {}

Step.FOLDER_NAME = "StageEnvironments"
Step.MAX_PARTS = 450
Step.SPOTS_PER_STAGE = 12
Step.RAMP_LIMIT_DEG = 32 -- contract allows 35; keep a margin
Step.STREET_HALF_WIDTH = 15 -- A6: no collidable part below STREET_MIN_UNDERSIDE over |Z| <= 15
Step.STREET_MIN_UNDERSIDE = 12
Step.WALL_X0 = 76
Step.WALL_NORTH_Z = 86
Step.WALL_SOUTH_Z = -88
Step.WALL_HEIGHT = 40
Step.WALL_THICKNESS = 2
Step.Z_MIN, Step.Z_MAX = -85.5, 81.5 -- zone floor band (everything but the side walls stays inside it)
Step.DEFAULT_FLOOR_LIFT = 0.026 -- zone floor top over groundY (ground step), when Workspace.Ground has no attribute
-- the olive ZoneDivider strips of the ground step sit at the stage seams (X ~ 169.6 / 315.6 / 526.6, 6 wide, top
-- ~ groundY + 0.17); street decals stop short of them so no two coplanar tops can z-fight
Step.DIVIDER_HALF_WIDTH = 3.1

Step.STAGES = {
	{ key = "Forest", number = 1, name = "The Avengers", theme = "Sleek sci-fi city: Avengers Tower, glass towers, holo displays",
		x0 = 72, x1 = 170, spotMinX = 95 },
	{ key = "Lake", number = 2, name = "Justice League", theme = "Dark rainy Gotham street with neon, Hall of Justice at the far end",
		x0 = 170, x1 = 316 },
	{ key = "Desert", number = 3, name = "Spider-Verse", theme = "Queens rooftops: fire escapes, water towers, cranes, web-line bridges",
		x0 = 316, x1 = 526 },
}

local LOG_PREFIX = "[StealaHero Build][env_a]"

local SMOOTH = Enum.Material.SmoothPlastic
local PLASTIC = Enum.Material.Plastic
local NEON = Enum.Material.Neon
local GLASS = Enum.Material.Glass
local METAL = Enum.Material.Metal
local WOOD = Enum.Material.Wood
local SLATE = Enum.Material.Slate

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local DECO = { deco = true }

local function merged(base, extra)
	local o = {}
	for k, v in pairs(base) do
		o[k] = v
	end
	if extra then
		for k, v in pairs(extra) do
			o[k] = v
		end
	end
	return o
end

-- ---------------------------------------------------------------------------------------------------------------
-- Builder: every coordinate is absolute world X/Z; heights (h) are studs above the ground (ctx.groundY).
-- ---------------------------------------------------------------------------------------------------------------

local Builder = {}
Builder.__index = Builder

local function newBuilder(model, stage, groundY)
	local self = setmetatable({}, Builder)
	self.model = model
	self.stage = stage
	self.G = groundY
	self.groups = {}
	self.ramps = {}
	self.hazards = {}
	-- street decals stop short of the ground step's divider strips at the stage seams
	self.decalX0 = stage.x0 + (stage.x0 > 72 and Step.DIVIDER_HALF_WIDTH or 0)
	self.decalX1 = stage.x1 - Step.DIVIDER_HALF_WIDTH
	return self
end

function Builder:group(name)
	local folder = self.groups[name]
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = self.model
		self.groups[name] = folder
	end
	return folder
end

-- Raw part. opts: deco (non-collidable/non-queryable/non-touchable), transparency, reflectance, shape, shadow
function Builder:part(group, name, size, cf, color, material, opts)
	opts = opts or {}
	local p = Instance.new("Part")
	p.Name = name
	if opts.shape then
		p.Shape = opts.shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or SMOOTH
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.Locked = true
	local solid = not opts.deco
	p.CanCollide = solid
	p.CanQuery = solid
	p.CanTouch = solid
	local shadow = opts.shadow
	if shadow == nil then
		local matName = material and material.Name or "SmoothPlastic"
		shadow = solid or (matName ~= "Neon" and matName ~= "Glass" and (opts.transparency or 0) < 0.3)
	end
	p.CastShadow = shadow
	if opts.transparency then
		p.Transparency = opts.transparency
	end
	if opts.reflectance then
		p.Reflectance = opts.reflectance
	end
	p.Parent = self:group(group)
	return p
end

-- Axis-aligned box from (x0, h0, z0) to (x1, h1, z1). Collidable unless opts.deco.
function Builder:box(group, name, x0, x1, h0, h1, z0, z1, color, material, opts)
	assert(x1 > x0 and h1 > h0 and z1 > z0, string.format("%s: degenerate box %s", self.stage.key, name))
	local size = Vector3.new(x1 - x0, h1 - h0, z1 - z0)
	local cf = CFrame.new((x0 + x1) / 2, self.G + (h0 + h1) / 2, (z0 + z1) / 2)
	local p = self:part(group, name, size, cf, color, material, opts)
	return p
end

function Builder:deco(group, name, x0, x1, h0, h1, z0, z1, color, material, opts)
	return self:box(group, name, x0, x1, h0, h1, z0, z1, color, material, merged(DECO, opts))
end

-- Window/trim bands wrapped around a building core (one part per band covers all four facades).
function Builder:bands(group, x0, x1, z0, z1, list, color, material, transparency)
	for i, band in ipairs(list) do
		self:deco(group, "Windows" .. i, x0 - 0.15, x1 + 0.15, band[1], band[2], z0 - 0.15, z1 + 0.15, color, material, { transparency = transparency })
	end
end

-- Cylinder along a world axis ("X", "Y" or "Z"), centred at (cx, h, cz), `len` long, diameter d.
function Builder:cyl(group, name, cx, h, cz, len, d, axis, color, material, opts)
	local rot
	if axis == "Y" then
		rot = CFrame.Angles(0, 0, math.pi / 2)
	elseif axis == "Z" then
		rot = CFrame.Angles(0, math.pi / 2, 0)
	else
		rot = CFrame.new()
	end
	return self:part(group, name, Vector3.new(len, d, d), CFrame.new(cx, self.G + h, cz) * rot, color, material,
		merged({ shape = Enum.PartType.Cylinder }, opts))
end

function Builder:ball(group, name, cx, h, cz, d, color, material, opts)
	return self:part(group, name, Vector3.new(d, d, d), CFrame.new(cx, self.G + h, cz), color, material, merged({ shape = Enum.PartType.Ball }, opts))
end

-- Thin decorative beam between two points (x, h, z) -> (x, h, z), e.g. web lines and cables. Oriented with an explicit
-- orthonormal basis (CFrame.fromMatrix): local Z runs from p1 to p2.
function Builder:strand(group, name, x1, h1, z1, x2, h2, z2, thick, color, material, opts)
	local p1 = Vector3.new(x1, self.G + h1, z1)
	local p2 = Vector3.new(x2, self.G + h2, z2)
	local delta = p2 - p1
	local len = delta.Magnitude
	local vz = delta.Unit
	local up = Vector3.new(0, 1, 0)
	if math.abs(vz.Y) > 0.95 then
		up = Vector3.new(1, 0, 0)
	end
	local vx = up:Cross(vz).Unit
	local vy = vz:Cross(vx).Unit
	local cf = CFrame.fromMatrix((p1 + p2) / 2, vx, vy, vz)
	local tip = cf * Vector3.new(0, 0, len / 2)
	assert((tip - p2).Magnitude < 0.01, string.format("%s: strand %s orientation mismatch", self.stage.key, name))
	return self:part(group, name, Vector3.new(thick, thick, len), cf, color, material or NEON, merged(DECO, opts))
end

local RAMP_THICKNESS = 1
local RAIL_HEIGHT = 2.4
local RAIL_THICKNESS = 0.4

-- Walkable ramp along X: a tilted slab whose top surface runs from (xa, ha) to (xb, hb) between z0..z1.
-- The top edges land exactly on the surfaces at both ends (flush), the slab body hangs below them.
-- opts.rails = "both" | "z0" | "z1" | nil adds collidable side rails on top of the slab edges.
function Builder:rampX(group, name, xa, ha, xb, hb, z0, z1, color, material, opts)
	opts = opts or {}
	local xl, hl, xr, hr = xa, ha, xb, hb
	if xa > xb then
		xl, hl, xr, hr = xb, hb, xa, ha
	end
	local run = xr - xl
	local theta = math.atan((hr - hl) / run)
	assert(math.deg(math.abs(theta)) <= Step.RAMP_LIMIT_DEG, string.format("%s: ramp %s is %.1f deg", self.stage.key, name, math.deg(math.abs(theta))))
	local len = run / math.cos(theta)
	local nx, ny = -math.sin(theta), math.cos(theta) -- top-face normal in the X/Y plane
	local mx, my = (xl + xr) / 2, self.G + (hl + hr) / 2
	local zc = (z0 + z1) / 2
	local rot = CFrame.Angles(0, 0, theta)
	local t = RAMP_THICKNESS
	local slab = self:part(group, name, Vector3.new(len, t, z1 - z0), CFrame.new(mx - nx * t / 2, my - ny * t / 2, zc) * rot, color, material)
	local rails = opts.rails
	local railColor = opts.railColor or color
	local railMat = opts.railMaterial or material
	local function rail(zr)
		self:part(group, name .. "Rail", Vector3.new(len, RAIL_HEIGHT, RAIL_THICKNESS),
			CFrame.new(mx + nx * RAIL_HEIGHT / 2, my + ny * RAIL_HEIGHT / 2, zr) * rot, railColor, railMat)
	end
	if rails == "both" or rails == "z0" then
		rail(z0 + RAIL_THICKNESS / 2)
	end
	if rails == "both" or rails == "z1" then
		rail(z1 - RAIL_THICKNESS / 2)
	end
	table.insert(self.ramps, { name = name, axis = "X", a0 = xl, a1 = xr, h0 = hl, h1 = hr, b0 = z0, b1 = z1, deg = math.deg(math.abs(theta)) })
	return slab
end

-- Walkable ramp along Z: top surface from (za, ha) to (zb, hb) between x0..x1 (see rampX).
function Builder:rampZ(group, name, za, ha, zb, hb, x0, x1, color, material, opts)
	opts = opts or {}
	local zl, hl, zr, hr = za, ha, zb, hb
	if za > zb then
		zl, hl, zr, hr = zb, hb, za, ha
	end
	local run = zr - zl
	local theta = math.atan((hr - hl) / run) -- rise toward +Z
	assert(math.deg(math.abs(theta)) <= Step.RAMP_LIMIT_DEG, string.format("%s: ramp %s is %.1f deg", self.stage.key, name, math.deg(math.abs(theta))))
	local len = run / math.cos(theta)
	-- CFrame.Angles(-theta, 0, 0) maps local +Z to (y = sin theta, z = cos theta) and local +Y to the top-face normal
	local ny, nz = math.cos(theta), -math.sin(theta)
	local mz, my = (zl + zr) / 2, self.G + (hl + hr) / 2
	local xc = (x0 + x1) / 2
	local rot = CFrame.Angles(-theta, 0, 0)
	local t = RAMP_THICKNESS
	local slab = self:part(group, name, Vector3.new(x1 - x0, t, len), CFrame.new(xc, my - ny * t / 2, mz - nz * t / 2) * rot, color, material)
	local rails = opts.rails
	local railColor = opts.railColor or color
	local railMat = opts.railMaterial or material
	local function rail(xr)
		self:part(group, name .. "Rail", Vector3.new(RAIL_THICKNESS, RAIL_HEIGHT, len),
			CFrame.new(xr, my + ny * RAIL_HEIGHT / 2, mz + nz * RAIL_HEIGHT / 2) * rot, railColor, railMat)
	end
	if rails == "both" or rails == "x0" then
		rail(x0 + RAIL_THICKNESS / 2)
	end
	if rails == "both" or rails == "x1" then
		rail(x1 - RAIL_THICKNESS / 2)
	end
	table.insert(self.ramps, { name = name, axis = "Z", a0 = zl, a1 = zr, h0 = hl, h1 = hr, b0 = x0, b1 = x1, deg = math.deg(math.abs(theta)) })
	return slab
end

local PARAPET_T = 0.6
local PARAPET_H = 1.1

-- Low collidable walls around a walkable roof x0..x1 / z0..z1 at height `top`, leaving the given gaps open.
-- gaps = { N = { {a, b}, ... }, S = ..., E = ..., W = ... }  (N/S intervals along X, E/W intervals along Z)
function Builder:parapets(group, x0, x1, z0, z1, top, color, gaps, material)
	gaps = gaps or {}
	local function segments(a0, a1, list)
		local out = { { a0, a1 } }
		for _, gap in ipairs(list or {}) do
			local nextOut = {}
			for _, seg in ipairs(out) do
				if gap[2] <= seg[1] or gap[1] >= seg[2] then
					table.insert(nextOut, seg)
				else
					if gap[1] > seg[1] then
						table.insert(nextOut, { seg[1], gap[1] })
					end
					if gap[2] < seg[2] then
						table.insert(nextOut, { gap[2], seg[2] })
					end
				end
			end
			out = nextOut
		end
		return out
	end
	local mat = material or METAL
	local ht = PARAPET_H
	for _, s in ipairs(segments(x0, x1, gaps.N)) do
		if s[2] - s[1] > 0.3 then
			self:box(group, "ParapetN", s[1], s[2], top, top + ht, z1 - PARAPET_T, z1, color, mat)
		end
	end
	for _, s in ipairs(segments(x0, x1, gaps.S)) do
		if s[2] - s[1] > 0.3 then
			self:box(group, "ParapetS", s[1], s[2], top, top + ht, z0, z0 + PARAPET_T, color, mat)
		end
	end
	for _, s in ipairs(segments(z0 + PARAPET_T, z1 - PARAPET_T, gaps.W)) do
		if s[2] - s[1] > 0.3 then
			self:box(group, "ParapetW", x0, x0 + PARAPET_T, top, top + ht, s[1], s[2], color, mat)
		end
	end
	for _, s in ipairs(segments(z0 + PARAPET_T, z1 - PARAPET_T, gaps.E)) do
		if s[2] - s[1] > 0.3 then
			self:box(group, "ParapetE", x1 - PARAPET_T, x1, top, top + ht, s[1], s[2], color, mat)
		end
	end
end

-- Slowing hazard (A8): a 1-stud-thick disc sunk into the surface with only `lift` showing above it; touchable,
-- non-collidable, non-queryable. STAGES' runtime slows players while they overlap it.
function Builder:hazard(group, name, cx, cz, surface, d, factor, color, material, transparency)
	assert(factor >= 0.4 and factor <= 0.8, "hazard factor out of range")
	local lift = 0.1
	local p = self:cyl(group, name, cx, surface + lift - 0.5, cz, 1, d, "Y", color, material, { deco = true, transparency = transparency })
	p.CanTouch = true
	p:SetAttribute("StageHazard", "Slow")
	p:SetAttribute("Factor", factor)
	table.insert(self.hazards, { x = cx, z = cz, r = d / 2, part = p })
	return p
end

-- A5: invisible collidable side walls over this stage's share of X 76-526.
function Builder:sideWalls()
	local x0 = math.max(Step.WALL_X0, self.stage.x0)
	local x1 = self.stage.x1
	local t = Step.WALL_THICKNESS / 2
	local invisible = { transparency = 1, shadow = false }
	local north = self:box("Boundary", "BoundaryWallNorth", x0, x1, 0, Step.WALL_HEIGHT, Step.WALL_NORTH_Z - t, Step.WALL_NORTH_Z + t, rgb(0, 0, 0), SMOOTH, invisible)
	local south = self:box("Boundary", "BoundaryWallSouth", x0, x1, 0, Step.WALL_HEIGHT, Step.WALL_SOUTH_Z - t, Step.WALL_SOUTH_Z + t, rgb(0, 0, 0), SMOOTH, invisible)
	north.CanTouch = false
	south.CanTouch = false
end

-- World AABB of a part (all 8 corners, so rotated parts are covered).
local function partAABB(part)
	local h = part.Size / 2
	local mn, mx
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local c = part.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
				mn = mn and mn:Min(c) or c
				mx = mx and mx:Max(c) or c
			end
		end
	end
	return mn, mx
end

-- keyed by name: Lune EnumItems are not stable table keys
local ALLOWED_MATERIALS = {
	Plastic = true,
	SmoothPlastic = true,
	Neon = true,
	Glass = true,
	Wood = true,
	Metal = true,
	Slate = true,
}

local LIMB_NAMES = {
	Head = true, Torso = true, HumanoidRootPart = true, UpperTorso = true, LowerTorso = true,
	LeftArm = true, RightArm = true, LeftLeg = true, RightLeg = true,
	["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
}

-- Geometry self-check of a finished stage (see the contract summary at the top). The D9 ring (post, spots, cover rocks)
-- is checked separately by ScratchLayout.ValidateRing.
function Builder:validate(floorTopY)
	local stage = self.stage
	local parts, collidable = 0, 0
	for _, d in ipairs(self.model:GetDescendants()) do
		assert(not LIMB_NAMES[d.Name] and not string.find(d.Name, "cloud_", 1, true), stage.key .. ": forbidden name " .. d:GetFullName())
		if d:IsA("BasePart") then
			parts += 1
			assert(d.Anchored, stage.key .. ": unanchored part " .. d:GetFullName())
			assert(ALLOWED_MATERIALS[d.Material.Name], stage.key .. ": material not allowed on " .. d:GetFullName())
			local mn, mx = partAABB(d)
			assert(mn.X >= stage.x0 - 0.01 and mx.X <= stage.x1 + 0.01,
				string.format("%s: %s leaves the stage X range (%.2f..%.2f)", stage.key, d:GetFullName(), mn.X, mx.X))
			local isWall = d.Name == "BoundaryWallNorth" or d.Name == "BoundaryWallSouth"
			if not isWall then
				assert(mn.Z >= Step.Z_MIN and mx.Z <= Step.Z_MAX,
					string.format("%s: %s leaves the zone Z band (%.2f..%.2f)", stage.key, d:GetFullName(), mn.Z, mx.Z))
			end
			if d.CanCollide then
				collidable += 1
				local overStreet = mn.Z < Step.STREET_HALF_WIDTH and mx.Z > -Step.STREET_HALF_WIDTH
				assert(not (overStreet and mn.Y < floorTopY + Step.STREET_MIN_UNDERSIDE and mx.Y > floorTopY + 0.01),
					string.format("%s: collidable %s is in the main street (Z %.2f..%.2f, Y %.2f..%.2f)", stage.key, d:GetFullName(), mn.Z, mx.Z, mn.Y, mx.Y))
			end
			if d:GetAttribute("StageHazard") ~= nil then
				assert(d:GetAttribute("StageHazard") == "Slow" and not d.CanCollide and d.CanTouch and not d.CanQuery, stage.key .. ": bad hazard flags " .. d:GetFullName())
				assert(mn.Z > Step.STREET_HALF_WIDTH or mx.Z < -Step.STREET_HALF_WIDTH, stage.key .. ": hazard in the main street " .. d:GetFullName())
			end
		elseif d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("DataModelMesh") or d:IsA("Decal") then
			error(stage.key .. ": forbidden instance " .. d:GetFullName())
		end
	end
	assert(parts <= Step.MAX_PARTS, string.format("%s: %d parts (limit %d)", stage.key, parts, Step.MAX_PARTS))
	return parts, collidable
end

-- ---------------------------------------------------------------------------------------------------------------
-- Stage 1: The Avengers (Forest, X 72-170). Buildings archived by the D8 scratch layout; Thanos' egg ring is D9's.
-- ---------------------------------------------------------------------------------------------------------------

local AV = {
	floor = rgb(64, 72, 86),
	road = rgb(40, 45, 56),
	sidewalk = rgb(170, 178, 190),
	plaza = rgb(196, 204, 216),
	lobby = rgb(214, 222, 232),
	lane = rgb(225, 232, 240),
	holo = rgb(0, 200, 255),
	holoBlue = rgb(50, 130, 255),
	white = rgb(228, 232, 238),
	steel = rgb(110, 122, 138),
	steelDark = rgb(52, 58, 70),
	glass = rgb(120, 180, 235),
	glassDark = rgb(36, 66, 104),
	darkCore = rgb(44, 60, 86),
	shield = rgb(96, 108, 124),
	hangar = rgb(204, 210, 220),
	lab = rgb(186, 194, 206),
	jet = rgb(58, 64, 76),
	jetLight = rgb(92, 100, 114),
	red = rgb(255, 60, 60),
	ironRed = rgb(178, 34, 34),
	ironGold = rgb(224, 176, 64),
	capRed = rgb(196, 30, 42),
	capBlue = rgb(28, 58, 150),
	leaf = rgb(70, 160, 90),
	trunk = rgb(96, 72, 52),
	emblemDark = rgb(30, 44, 70),
	logo = rgb(170, 225, 255),
	deck = rgb(66, 74, 88),
	coolant = rgb(0, 230, 200),
}

local function buildAvengers(b)
	local C = AV
	local g
	local dx0, dx1 = b.decalX0, b.decalX1

	-- Main street: road + sidewalks + light lines (visual-only decals over the solid Baseplate)
	g = "Street"
	b:deco(g, "Road", dx0, dx1, -0.3, 0.08, -12, 12, C.road, SMOOTH, { reflectance = 0.05 })
	b:deco(g, "SidewalkNorth", dx0, dx1, -0.3, 0.16, 12, 17, C.sidewalk, SMOOTH)
	b:deco(g, "SidewalkSouth", dx0, dx1, -0.3, 0.16, -17, -12, C.sidewalk, SMOOTH)
	b:deco(g, "CurbLightNorth", dx0, dx1, -0.2, 0.12, 11.6, 12, C.holo, NEON)
	b:deco(g, "CurbLightSouth", dx0, dx1, -0.2, 0.12, -12, -11.6, C.holo, NEON)
	for i = 0, 6 do
		local x = 77 + i * 12
		b:deco(g, "LaneDash", x, x + 6, -0.2, 0.12, -0.25, 0.25, C.lane, SMOOTH)
	end
	-- holo gates over the street: pillars on the outer sidewalk edge (|Z| >= 15), everything overhead is visual
	g = "Holo Gates"
	for _, ax in ipairs({ 100, 146 }) do
		b:box(g, "GatePillarN", ax - 0.8, ax + 0.8, 0, 17, 15.2, 16.8, C.white, METAL)
		b:box(g, "GatePillarS", ax - 0.8, ax + 0.8, 0, 17, -16.8, -15.2, C.white, METAL)
		b:deco(g, "GateBeam", ax - 1, ax + 1, 17, 18.4, -17.2, 17.2, C.white, METAL)
		b:deco(g, "GateLight", ax - 0.6, ax + 0.6, 16.7, 17, -16.2, 16.2, C.holo, NEON)
		b:deco(g, "GateHoloBanner", ax - 0.1, ax + 0.1, 12.5, 16.2, -6, 6, C.holoBlue, NEON, { transparency = 0.45 })
	end
	g = "Street Lights"
	for _, lamp in ipairs({ { 88, 1 }, { 160, 1 }, { 88, -1 }, { 124, -1 }, { 160, -1 } }) do
		local x, s = lamp[1], lamp[2]
		local pz0, pz1, az0, az1, lz0, lz1 = 15.4, 16.1, 11, 16.1, 11.3, 14.6
		if s < 0 then
			pz0, pz1, az0, az1, lz0, lz1 = -16.1, -15.4, -16.1, -11, -14.6, -11.3
		end
		b:box(g, "LampPost", x - 0.35, x + 0.35, 0, 9, pz0, pz1, C.steel, METAL)
		b:deco(g, "LampArm", x - 0.4, x + 0.4, 9, 9.5, az0, az1, C.white, METAL)
		b:deco(g, "LampLight", x - 0.3, x + 0.3, 8.8, 9, lz0, lz1, C.holo, NEON)
	end
	for i = 0, 5 do
		local x = 84 + i * 16
		b:deco(g, "HoloBollard", x - 0.3, x + 0.3, 0, 1.4, 16.3, 16.9, C.holo, NEON, { transparency = 0.2 })
		b:deco(g, "HoloBollard", x - 0.3, x + 0.3, 0, 1.4, -16.9, -16.3, C.holo, NEON, { transparency = 0.2 })
	end

	-- North: Stark Expo glass block
	g = "Stark Expo"
	b:box(g, "Core", 78, 100, 0, 30, 22, 44, C.white, SMOOTH)
	b:bands(g, 78, 100, 22, 44, { { 3, 5.4 }, { 8, 10.4 }, { 13, 15.4 }, { 18, 20.4 }, { 23, 25.4 } }, C.glass, GLASS, 0.1)
	b:deco(g, "CrownLight", 77.7, 100.3, 28.9, 29.3, 21.7, 44.3, C.holo, NEON)
	b:deco(g, "RoofCap", 78.4, 99.6, 30, 30.6, 22.4, 43.6, C.steelDark, METAL)
	b:deco(g, "Antenna", 88.8, 89.2, 30.6, 40, 32.8, 33.2, C.steel, METAL)
	b:deco(g, "AntennaBeacon", 88.7, 89.3, 40, 40.6, 32.7, 33.3, C.red, NEON)
	b:deco(g, "BillboardFrame", 82, 96, 9.6, 17.4, 21.3, 21.7, C.steelDark, METAL)
	b:deco(g, "BillboardScreen", 82.6, 95.4, 10.2, 16.8, 21.15, 21.3, C.holoBlue, NEON, { transparency = 0.15 })

	-- North: tower plaza (the legacy villain pad in front), holo emblem, kiosks, planters
	g = "Tower Plaza"
	b:deco(g, "PlazaFloor", 100, 133, -0.3, 0.12, 17, 58, C.plaza, SMOOTH)
	b:cyl(g, "EmblemRing", 117, 0.15, 42, 0.06, 16, "Y", C.holo, NEON, DECO)
	b:cyl(g, "EmblemDisc", 117, 0.17, 42, 0.06, 14.6, "Y", C.emblemDark, SMOOTH, DECO)
	b:part(g, "EmblemA", Vector3.new(0.9, 0.04, 10.77), CFrame.new(115, b.G + 0.21, 42) * CFrame.Angles(0, math.atan2(4, 10), 0), C.holo, NEON, DECO)
	b:part(g, "EmblemA", Vector3.new(0.9, 0.04, 10.77), CFrame.new(119, b.G + 0.21, 42) * CFrame.Angles(0, math.atan2(-4, 10), 0), C.holo, NEON, DECO)
	b:deco(g, "EmblemA", 114.4, 119.6, 0.19, 0.23, 40.6, 41.4, C.holo, NEON)
	for _, kx in ipairs({ 103, 131 }) do
		b:box(g, "HoloKiosk", kx - 1, kx + 1, 0, 1.2, 23, 25, C.steelDark, METAL)
		b:deco(g, "HoloKioskScreen", kx - 1.5, kx + 1.5, 1.6, 4.2, 23.9, 24.1, C.holo, NEON, { transparency = 0.35 })
	end
	for _, px in ipairs({ 104, 130 }) do
		b:box(g, "Planter", px - 1.5, px + 1.5, 0, 1, 48.5, 51.5, C.white, SMOOTH)
		b:deco(g, "TreeTrunk", px - 0.3, px + 0.3, 1, 3.5, 49.7, 50.3, C.trunk, WOOD)
		b:ball(g, "TreeCrown", px, 4.6, 50, 3.6, C.leaf, SMOOTH, DECO)
	end

	-- North: Avengers Tower. The podium is a walkable lobby (10-wide door on the plaza, 14 studs of headroom, 9-wide
	-- west wing behind a holo archive wall) with holo displays and a hall of trophies; above it the glass shaft with
	-- white fins and the crown with the glowing A.
	g = "Avengers Tower"
	b:box(g, "LobbyFrontWall", 104, 115, 0, 14, 58, 59, C.white, SMOOTH)
	b:box(g, "LobbyFrontWall", 125, 130, 0, 14, 58, 59, C.white, SMOOTH)
	b:box(g, "LobbyLintel", 115, 125, 12.5, 14, 58, 59, C.white, SMOOTH)
	b:box(g, "LobbyBackWall", 104, 130, 0, 14, 79, 80, C.white, SMOOTH)
	b:box(g, "LobbySideWall", 104, 105, 0, 14, 59, 79, C.white, SMOOTH)
	b:box(g, "LobbySideWall", 129, 130, 0, 14, 59, 79, C.white, SMOOTH)
	b:box(g, "LobbyCeiling", 104, 130, 14, 15, 58, 80, C.white, SMOOTH)
	b:deco(g, "LobbyWindow", 104.5, 114.5, 1.5, 11, 57.8, 58, C.glass, GLASS, { transparency = 0.15 })
	b:deco(g, "LobbyWindow", 125.5, 129.5, 1.5, 11, 57.8, 58, C.glass, GLASS, { transparency = 0.15 })
	b:deco(g, "PodiumLight", 103.8, 130.2, 13.4, 13.8, 57.8, 80.2, C.holo, NEON)
	b:deco(g, "DoorFrame", 114.6, 115, 0, 12.5, 57.8, 58.2, C.holoBlue, NEON)
	b:deco(g, "DoorFrame", 125, 125.4, 0, 12.5, 57.8, 58.2, C.holoBlue, NEON)
	b:deco(g, "DoorFrame", 114.6, 125.4, 12.5, 12.9, 57.8, 58.2, C.holoBlue, NEON)
	b:deco(g, "LobbyFloor", 105, 129, -0.3, 0.12, 59, 79, C.lobby, SMOOTH)
	b:box(g, "ArchiveWall", 114, 115, 0, 8, 59, 67, C.steelDark, METAL)
	b:deco(g, "ArchiveGlow", 113.8, 115.2, 1, 7, 60, 66, C.holo, NEON, { transparency = 0.4 })
	b:box(g, "HoloTable", 122, 128, 0, 1.2, 73, 78, C.steelDark, METAL)
	b:ball(g, "HoloGlobe", 125, 3.4, 75.5, 3, C.holo, NEON, { deco = true, transparency = 0.35 })
	b:cyl(g, "HoloRing", 125, 3.4, 75.5, 0.1, 4.4, "Y", C.holoBlue, NEON, { deco = true, transparency = 0.2 })
	b:deco(g, "HoloScreen", 105, 105.2, 3, 8, 66, 76, C.holoBlue, NEON, { transparency = 0.25 })
	b:deco(g, "HoloScreen", 128.8, 129, 3, 8, 66, 70, C.holoBlue, NEON, { transparency = 0.25 })
	-- trophies: Captain America's shield on the back wall, Mjolnir on a pedestal
	b:cyl(g, "TrophyShieldRing", 110, 6, 78.8, 0.2, 4, "Z", C.capRed, METAL, DECO)
	b:cyl(g, "TrophyShieldBand", 110, 6, 78.65, 0.2, 3, "Z", C.white, METAL, DECO)
	b:cyl(g, "TrophyShieldCenter", 110, 6, 78.5, 0.2, 2, "Z", C.capBlue, METAL, DECO)
	b:deco(g, "TrophyShieldStar", 109.6, 110.4, 5.6, 6.4, 78.3, 78.4, C.white, NEON)
	b:box(g, "TrophyPedestal", 116, 118, 0, 1.5, 76.5, 78.5, C.steelDark, METAL)
	b:deco(g, "TrophyHammerHead", 116.3, 117.7, 1.5, 2.5, 77, 78, C.steel, METAL)
	b:deco(g, "TrophyHammerHandle", 116.8, 117.2, 2.5, 4.2, 77.3, 77.7, C.trunk, WOOD)
	-- tower above the lobby
	b:box(g, "Shaft", 108, 126, 15, 70, 61, 77, C.white, SMOOTH)
	b:deco(g, "ShaftGlass", 109, 125, 16, 68.5, 60.8, 77.2, C.glassDark, GLASS, { transparency = 0.05 })
	for _, y in ipairs({ 20, 28, 36, 44, 52, 60 }) do
		b:deco(g, "ShaftRib", 108.9, 125.1, y, y + 0.5, 60.7, 77.3, C.white, SMOOTH)
	end
	b:deco(g, "Crown", 110, 124, 70, 86, 63, 75, C.white, SMOOTH)
	b:deco(g, "CrownGlass", 110.6, 123.4, 71, 85, 62.8, 75.2, C.glass, GLASS, { transparency = 0.1 })
	b:deco(g, "Cap", 112, 122, 86, 92, 65, 73, C.white, SMOOTH)
	b:deco(g, "Mast", 116.6, 117.4, 92, 112, 68.6, 69.4, C.steel, METAL)
	b:deco(g, "MastBeacon", 116.5, 117.5, 112, 113, 68.5, 69.5, C.red, NEON)
	b:part(g, "LogoA", Vector3.new(1.2, 10.31, 0.4), CFrame.new(115, b.G + 79.25, 62.5) * CFrame.Angles(0, 0, -math.atan2(4, 9.5)), C.logo, NEON, DECO)
	b:part(g, "LogoA", Vector3.new(1.2, 10.31, 0.4), CFrame.new(119, b.G + 79.25, 62.5) * CFrame.Angles(0, 0, math.atan2(4, 9.5)), C.logo, NEON, DECO)
	b:deco(g, "LogoA", 114.6, 119.4, 77.8, 78.8, 62.3, 62.7, C.logo, NEON)
	b:deco(g, "Helipad", 110, 124, 55, 56, 50, 61, C.steelDark, METAL)
	b:deco(g, "HelipadLight", 110, 124, 56, 56.3, 50, 50.4, C.holo, NEON)
	b:deco(g, "FinWest", 106, 108, 15, 44, 66, 72, C.white, SMOOTH)
	b:deco(g, "FinEast", 126, 128, 15, 44, 66, 72, C.white, SMOOTH)

	-- North: Avengers hangar with a walkable roof (9-wide ramp + landing on its west side) and a parked Quinjet
	g = "Avengers Hangar"
	b:box(g, "Hangar", 142, 166, 0, 6, 24, 46, C.hangar, SMOOTH)
	b:deco(g, "HangarDoor", 146, 162, 0.3, 5, 23.75, 24, C.steelDark, METAL)
	b:deco(g, "HangarDoorLight", 146, 162, 5.2, 5.5, 23.7, 23.95, C.holo, NEON)
	b:rampZ(g, "HangarRamp", 24, 0, 36, 6, 133, 142, C.steel, METAL, { rails = "x0", railColor = C.steelDark })
	b:box(g, "HangarLanding", 133, 142, 0, 6, 36, 46, C.steel, METAL)
	b:box(g, "ParapetN", 133, 166, 6, 7.1, 45.4, 46, C.steelDark, METAL)
	b:box(g, "ParapetS", 142, 166, 6, 7.1, 24, 24.6, C.steelDark, METAL)
	b:box(g, "ParapetE", 165.4, 166, 6, 7.1, 24.6, 45.4, C.steelDark, METAL)
	b:box(g, "ParapetW", 142, 142.6, 6, 7.1, 24.6, 36, C.steelDark, METAL)
	b:box(g, "ParapetW", 133, 133.6, 6, 7.1, 36, 45.4, C.steelDark, METAL)
	b:box(g, "QuinjetBody", 147, 159, 6, 8.4, 28, 32, C.jet, METAL)
	b:deco(g, "QuinjetNose", 159, 161.5, 6.4, 8, 28.8, 31.2, C.glassDark, GLASS)
	b:deco(g, "QuinjetWings", 150, 156, 7, 7.4, 25, 35, C.jetLight, METAL)
	b:deco(g, "QuinjetTail", 147, 149, 8.4, 10.6, 27.4, 27.9, C.jetLight, METAL)
	b:deco(g, "QuinjetTail", 147, 149, 8.4, 10.6, 32.1, 32.6, C.jetLight, METAL)
	b:deco(g, "QuinjetEngines", 146.6, 147, 6.6, 8, 28.5, 31.5, C.holoBlue, NEON)
	b:box(g, "RoofUnit", 161.5, 164.5, 6, 7.6, 25.5, 28.5, C.steel, METAL)

	-- North back: tech lab and a courtyard generator behind the tower
	g = "Tech Lab"
	b:box(g, "Lab", 146, 168, 0, 18, 58, 80, C.lab, SMOOTH)
	b:bands(g, 146, 168, 58, 80, { { 3, 6 }, { 9, 12 }, { 14, 16 } }, C.glassDark, GLASS, 0.05)
	b:deco(g, "LabCrown", 145.7, 168.3, 17.2, 17.6, 57.7, 80.3, C.holo, NEON)
	b:box(g, "Generator", 136, 142, 0, 4, 72, 78, C.steel, METAL)
	b:deco(g, "GeneratorGlow", 136.5, 141.5, 4, 4.2, 72.5, 77.5, C.holo, NEON)

	-- South: dark glass skyscraper with a setback
	g = "Glass Skyscraper"
	b:box(g, "Tower", 78, 102, 0, 22, -46, -22, C.darkCore, SMOOTH)
	b:bands(g, 78, 102, -46, -22, { { 2, 4.4 }, { 6, 8.4 }, { 10, 12.4 }, { 14, 16.4 }, { 18, 20.4 } }, C.glass, GLASS, 0.1)
	b:deco(g, "SetbackLight", 77.7, 102.3, 21.1, 21.5, -46.3, -21.7, C.holo, NEON)
	b:box(g, "UpperTower", 82, 98, 22, 40, -42, -26, C.darkCore, SMOOTH)
	b:bands(g, 82, 98, -42, -26, { { 24, 26.4 }, { 28, 30.4 }, { 32, 34.4 }, { 36, 38.4 } }, C.glass, GLASS, 0.1)
	b:deco(g, "UpperLight", 81.7, 98.3, 39.4, 39.8, -42.3, -25.7, C.holo, NEON)

	g = "SHIELD Office"
	b:box(g, "Office", 112, 134, 0, 20, -40, -20, C.shield, SMOOTH)
	b:bands(g, 112, 134, -40, -20, { { 3, 5.5 }, { 8, 10.5 }, { 13, 15.5 } }, C.glassDark, GLASS, 0.05)
	b:deco(g, "OfficeCrown", 111.7, 134.3, 19.4, 20.4, -40.3, -19.7, C.steelDark, METAL)
	b:deco(g, "HoloAdFrame", 116, 130, 5.6, 12.4, -19.65, -19.4, C.steelDark, METAL)
	b:deco(g, "HoloAd", 116.6, 129.4, 6.2, 11.8, -19.4, -19.25, C.holoBlue, NEON, { transparency = 0.2 })

	g = "Stark Showroom"
	b:box(g, "Showroom", 144, 166, 0, 14, -42, -20, C.white, SMOOTH)
	b:deco(g, "ShowroomGlass", 146, 164, 0.4, 10, -19.9, -19.75, C.glass, GLASS, { transparency = 0.25 })
	b:deco(g, "StarkSign", 148, 162, 11, 12.8, -19.9, -19.7, C.lane, NEON)
	b:deco(g, "ShowroomCrown", 143.7, 166.3, 13.4, 14.3, -42.3, -19.7, C.steelDark, METAL)
	b:box(g, "DisplayPlinth", 153.5, 158.5, 0, 0.8, -19.6, -17.4, C.steelDark, METAL)
	b:deco(g, "ArmorLegs", 155.2, 156.8, 0.8, 3.6, -18.9, -18.1, C.ironRed, METAL)
	b:deco(g, "ArmorChest", 154.8, 157.2, 3.6, 6, -19, -18, C.ironRed, METAL)
	b:deco(g, "ArmorShoulders", 154.2, 157.8, 3.8, 5.8, -18.8, -18.2, C.ironGold, METAL)
	b:deco(g, "ArmorArcReactor", 155.7, 156.3, 4.9, 5.5, -18.05, -17.9, C.holo, NEON)
	b:deco(g, "ArmorHelmet", 155.35, 156.65, 6, 7.3, -19, -18, C.ironRed, METAL)
	b:deco(g, "ArmorFaceplate", 155.5, 156.5, 6.2, 7.1, -18.05, -17.95, C.ironGold, METAL)

	-- South back: research lab, Quinjet landing deck (ramp from the back street), arc reactor plant
	g = "Research Lab"
	b:box(g, "Lab", 78, 104, 0, 16, -82, -58, C.lab, SMOOTH)
	b:bands(g, 78, 104, -82, -58, { { 3, 5.5 }, { 9, 11.5 } }, C.glassDark, GLASS, 0.05)
	b:deco(g, "LabCrown", 77.7, 104.3, 15.3, 15.7, -82.3, -57.7, C.holo, NEON)

	g = "Quinjet Deck"
	b:box(g, "Deck", 110, 132, 7, 8, -82, -62, C.deck, METAL)
	for _, p in ipairs({ { 110.2, -81.8 }, { 130.4, -81.8 }, { 110.2, -63.4 }, { 130.4, -63.4 } }) do
		b:box(g, "DeckSupport", p[1], p[1] + 1.4, 0, 7, p[2], p[2] + 1.4, C.steel, METAL)
	end
	b:rampZ(g, "DeckRamp", -56, 0, -72, 8, 132, 141, C.steel, METAL, { rails = "x1", railColor = C.steelDark })
	b:box(g, "DeckLanding", 132, 141, 0, 8, -82, -72, C.steel, METAL)
	b:box(g, "ParapetN", 110, 132, 8, 9.1, -62.6, -62, C.steelDark, METAL)
	b:box(g, "ParapetW", 110, 110.6, 8, 9.1, -81.4, -62.6, C.steelDark, METAL)
	b:box(g, "ParapetS", 110, 141, 8, 9.1, -82, -81.4, C.steelDark, METAL)
	b:box(g, "ParapetE", 131.4, 132, 8, 9.1, -72, -62.6, C.steelDark, METAL)
	b:box(g, "ParapetE", 140.4, 141, 8, 9.1, -81.4, -72, C.steelDark, METAL)
	b:deco(g, "DeckLightN", 110, 132, 9.1, 9.25, -62.5, -62.1, C.holo, NEON)
	b:deco(g, "DeckLightS", 110, 141, 9.1, 9.25, -81.9, -81.5, C.holo, NEON)
	b:deco(g, "QuinjetBody", 116, 128, 8, 10.4, -71, -67, C.jet, METAL)
	b:deco(g, "QuinjetNose", 128, 130.5, 8.4, 10, -70.2, -67.8, C.glassDark, GLASS)
	b:deco(g, "QuinjetWings", 119, 125, 9, 9.4, -74, -64, C.jetLight, METAL)
	b:deco(g, "QuinjetTail", 116, 118, 10.4, 12.6, -71.4, -70.9, C.jetLight, METAL)
	b:deco(g, "QuinjetTail", 116, 118, 10.4, 12.6, -67.1, -66.6, C.jetLight, METAL)
	b:deco(g, "QuinjetEngines", 115.6, 116, 8.6, 10, -70.5, -67.5, C.holoBlue, NEON)

	g = "Arc Reactor Plant"
	b:box(g, "Plant", 144, 166, 0, 12, -82, -60, C.shield, METAL)
	b:bands(g, 144, 166, -82, -60, { { 8, 9.5 } }, C.glassDark, GLASS, 0.05)
	b:deco(g, "PlantCrown", 143.7, 166.3, 11.4, 11.8, -82.3, -59.7, C.holo, NEON)
	b:cyl(g, "ArcReactor", 155, 5.5, -59.75, 0.4, 7, "Z", C.holo, NEON, DECO)
	b:cyl(g, "ArcReactorCore", 155, 5.5, -59.6, 0.5, 3.6, "Z", C.lane, NEON, DECO)

	-- Hazards (A8, stage 1 = few): glowing coolant spills
	g = "Hazards"
	b:hazard(g, "CoolantSpill", 146, -51, 0, 5, 0.8, C.coolant, NEON, 0.35)
	b:hazard(g, "CoolantSpill", 138, 52, 0, 4, 0.8, C.coolant, NEON, 0.35)

	b:sideWalls()

end

-- ---------------------------------------------------------------------------------------------------------------
-- Stage 2: Justice League (Lake, X 170-316). Buildings archived by the D8 scratch layout (the rain stays).
-- ---------------------------------------------------------------------------------------------------------------

local JL = {
	floor = rgb(34, 35, 42),
	road = rgb(27, 28, 34),
	sidewalk = rgb(62, 60, 70),
	square = rgb(50, 48, 58),
	dash = rgb(222, 168, 52),
	stone = rgb(54, 52, 64),
	stoneMid = rgb(76, 72, 86),
	brick = rgb(84, 54, 48),
	brickRed = rgb(98, 42, 46),
	iron = rgb(30, 30, 36),
	warm = rgb(255, 192, 110),
	magenta = rgb(255, 40, 170),
	cyan = rgb(0, 230, 255),
	green = rgb(70, 255, 120),
	amber = rgb(255, 176, 50),
	red = rgb(255, 50, 60),
	purple = rgb(160, 90, 255),
	puddle = rgb(60, 80, 120),
	rain = rgb(170, 190, 220),
	hoj = rgb(222, 216, 200),
	hojTrim = rgb(210, 168, 72),
	hojGlass = rgb(96, 150, 215),
	dome = rgb(232, 236, 242),
	ice = rgb(180, 232, 255),
	tank = rgb(88, 100, 92),
	wood = rgb(132, 96, 60),
	signal = rgb(255, 232, 130),
	bat = rgb(10, 10, 12),
	lounge = rgb(44, 58, 78),
	warehouse = rgb(72, 76, 84),
	dock = rgb(92, 92, 98),
}

-- Rain over the Gotham street (A9, docs/HERO_MODELS_PLAN.md H5). The rain itself is drawn by each client
-- (StarterPlayerScripts.Game.StageWeather, modelled on the owner's ZeroDown weather: camera-following rain ceiling,
-- raycast-placed splashes, mist, lightning; StageAmbience darkens the lighting). The build only declares WHERE it rains:
-- Rain.RainVolume, an invisible, anchored, non-collidable / non-queryable / non-touchable box over the stage from the
-- floor up to `h` (its bottom is the street level the drops fall to). No ParticleEmitter lives in the Workspace (one
-- rain). The owner's builder can move / resize it in Studio and tune its attributes: Weather ("Rain"), Intensity
-- (0 = off .. 3), Lightning (flashes on/off), StreakTexture ("" = built-in streak; an approved image id otherwise).
local function addRain(b, x0, x1, z0, z1, h)
	local p = b:deco("Rain", "RainVolume", x0, x1, 0, h, z0, z1, JL.rain, SMOOTH, { transparency = 1, shadow = false })
	p:SetAttribute("Weather", "Rain")
	p:SetAttribute("Intensity", 1)
	p:SetAttribute("Lightning", true)
	p:SetAttribute("StreakTexture", "")
	return p
end

local function buildJusticeLeague(b)
	local C = JL
	local g
	local dx0, dx1 = b.decalX0, b.decalX1

	g = "Street"
	b:deco(g, "Road", dx0, dx1, -0.3, 0.08, -12, 12, C.road, SMOOTH, { reflectance = 0.25 })
	b:deco(g, "SidewalkNorth", dx0, dx1, -0.3, 0.16, 12, 17, C.sidewalk, SLATE)
	b:deco(g, "SidewalkSouth", dx0, dx1, -0.3, 0.16, -17, -12, C.sidewalk, SLATE)
	for i = 0, 10 do
		local x = 176 + i * 12
		b:deco(g, "LaneDash", x, x + 6, -0.2, 0.12, -0.25, 0.25, C.dash, SMOOTH)
	end
	for _, p in ipairs({ { 184, -6, 5 }, { 198, 8, 3.5 }, { 212, 5, 4 }, { 236, -3, 6 }, { 276, -8, 5 } }) do
		b:cyl(g, "WetPatch", p[1], 0.11, p[2], 0.04, p[3], "Y", C.puddle, GLASS, { deco = true, transparency = 0.2, reflectance = 0.6 })
	end
	g = "Street Lights"
	for _, lamp in ipairs({ { 190, 1 }, { 222, 1 }, { 190, -1 }, { 234, -1 }, { 261, -1 } }) do
		local x, s = lamp[1], lamp[2]
		local pz0, pz1, az0, az1, lz0, lz1 = 15.4, 16.1, 12.2, 15.8, 12.2, 13.2
		if s < 0 then
			pz0, pz1, az0, az1, lz0, lz1 = -16.1, -15.4, -15.8, -12.2, -13.2, -12.2
		end
		b:box(g, "LampPost", x - 0.35, x + 0.35, 0, 10, pz0, pz1, C.iron, METAL)
		b:deco(g, "LampArm", x - 0.25, x + 0.25, 10, 10.4, az0, az1, C.iron, METAL)
		b:deco(g, "Lantern", x - 0.5, x + 0.5, 9, 10, lz0, lz1, C.amber, NEON)
	end
	addRain(b, b.stage.x0, b.stage.x1, Step.Z_MIN, Step.Z_MAX, 60) -- the whole stage floor band (the client pads Z to the walls)

	-- North: gothic "Wayne" tower, joined to the GCPD across the street by a skybridge (visual, 22 studs up)
	g = "Gothic Tower"
	b:box(g, "Tower", 178, 202, 0, 34, 24, 52, C.stone, SLATE)
	b:bands(g, 178, 202, 24, 52, { { 4, 6 }, { 10, 12 }, { 16, 18 }, { 22, 24 }, { 28, 30 } }, C.warm, GLASS, 0.2)
	b:deco(g, "Buttress", 179.5, 181, 0, 36, 23.4, 24, C.stoneMid, SLATE)
	b:deco(g, "Buttress", 199, 200.5, 0, 36, 23.4, 24, C.stoneMid, SLATE)
	b:deco(g, "TowerCrown", 182, 198, 34, 44, 28, 48, C.stone, SLATE)
	b:deco(g, "CrownWindows", 181.85, 198.15, 38, 40, 27.85, 48.15, C.amber, NEON)
	b:deco(g, "Spire", 187, 193, 44, 56, 35, 41, C.stoneMid, SLATE)
	b:deco(g, "SpireTip", 189.3, 190.7, 56, 66, 37.3, 38.7, C.iron, METAL)
	b:deco(g, "SpireBeacon", 189.2, 190.8, 66, 66.8, 37.2, 38.8, C.red, NEON)
	b:deco(g, "Gargoyle", 181, 183, 34, 35.6, 26.5, 28.5, C.stoneMid, SLATE)
	b:deco(g, "Gargoyle", 197, 199, 34, 35.6, 26.5, 28.5, C.stoneMid, SLATE)
	b:deco(g, "Skybridge", 186, 194, 22, 26, -20, 24, C.stone, SLATE)
	b:deco(g, "SkybridgeWindows", 185.85, 194.15, 23.4, 24.6, -19, 23, C.amber, NEON)

	-- North: Gotham Gazette with a rooftop terrace reached by a 9-wide outdoor fire stair (ramp) on its east side
	g = "Gazette"
	b:box(g, "Front", 210, 234, 0, 20, 18, 32, C.brick, SLATE)
	b:bands(g, 210, 234, 18, 32, { { 4, 6.5 }, { 10, 12.5 } }, C.warm, GLASS, 0.2)
	b:deco(g, "SignFrame", 214, 230, 14, 17.4, 17.5, 17.8, C.magenta, NEON)
	b:deco(g, "SignPanel", 215, 229, 14.6, 16.8, 17.35, 17.5, C.bat, SMOOTH)
	b:deco(g, "Cornice", 209.6, 234.4, 19.6, 20.4, 17.6, 32.4, C.iron, METAL)
	b:box(g, "Annex", 210, 234, 0, 10, 32, 48, C.stoneMid, SLATE)
	b:bands(g, 210, 234, 32, 48, { { 4, 6.5 } }, C.warm, GLASS, 0.2)
	b:rampZ(g, "FireStair", 20, 0, 38, 10, 234, 243, C.iron, METAL, { rails = "x1" })
	b:box(g, "FireStairLanding", 234, 243, 0, 10, 38, 48, C.iron, METAL)
	b:box(g, "ParapetN", 210, 243, 10, 11.1, 47.4, 48, C.iron, METAL)
	b:box(g, "ParapetW", 210, 210.6, 10, 11.1, 32, 47.4, C.iron, METAL)
	b:box(g, "ParapetE", 242.4, 243, 10, 11.1, 38, 47.4, C.iron, METAL)
	b:box(g, "ParapetE", 233.4, 234, 10, 11.1, 32, 38, C.iron, METAL)
	b:box(g, "StairHouse", 211, 215, 10, 14, 33, 37, C.stone, SLATE)
	b:deco(g, "StairHouseDoor", 215, 215.15, 10, 13, 34, 36, C.iron, METAL)
	b:cyl(g, "WaterTank", 213, 12.5, 43, 5, 4, "Y", C.wood, WOOD)

	-- North: neon alley between the Gazette and the cathedral square
	g = "Neon Alley"
	b:deco(g, "NeonSign", 242.6, 242.9, 3, 7, 40, 44, C.green, NEON)
	b:deco(g, "NeonSign", 252.1, 252.4, 6, 14, 36, 39, C.magenta, NEON)
	b:deco(g, "NeonSign", 252.1, 252.4, 4, 9, 44, 47, C.cyan, NEON)

	-- North: cathedral square (the legacy villain pad) and the cathedral with twin bell towers and a rose window
	g = "Cathedral"
	b:deco(g, "SquarePaving", 243, 272, -0.3, 0.12, 17, 29, C.square, SLATE)
	b:box(g, "Nave", 254, 270, 0, 22, 31, 61, C.stoneMid, SLATE)
	b:deco(g, "Gable", 255.5, 268.5, 22, 26, 31.5, 60.5, C.stone, SLATE)
	b:deco(g, "Gable", 258, 266, 26, 30, 32, 60, C.stone, SLATE)
	b:deco(g, "Gable", 260.5, 263.5, 30, 34, 32.5, 59.5, C.stone, SLATE)
	b:box(g, "BellTower", 252, 256, 0, 30, 29, 35, C.stone, SLATE)
	b:box(g, "BellTower", 268, 272, 0, 30, 29, 35, C.stone, SLATE)
	b:deco(g, "TowerCap", 252.5, 255.5, 30, 34, 29.5, 34.5, C.stoneMid, SLATE)
	b:deco(g, "TowerCap", 268.5, 271.5, 30, 34, 29.5, 34.5, C.stoneMid, SLATE)
	b:deco(g, "TowerSpike", 253.4, 254.6, 34, 38, 31.4, 32.6, C.iron, METAL)
	b:deco(g, "TowerSpike", 269.4, 270.6, 34, 38, 31.4, 32.6, C.iron, METAL)
	b:cyl(g, "RoseWindow", 262, 15, 30.8, 0.3, 7, "Z", C.purple, NEON, DECO)
	b:deco(g, "Lancet", 257.5, 258.9, 3, 10, 30.8, 31, C.warm, GLASS)
	b:deco(g, "Lancet", 265.1, 266.5, 3, 10, 30.8, 31, C.warm, GLASS)
	b:deco(g, "CathedralDoor", 260.5, 263.5, 0, 6, 30.8, 31, C.wood, WOOD)

	-- Hall of Justice: two wings flanking the street, grand steps + colonnaded terraces, a portico, a bridge block
	-- over the street (18 studs of clearance) and the dome.
	g = "Hall of Justice"
	for _, s in ipairs({ 1, -1 }) do
		local function zr(a, bb)
			if s > 0 then
				return a, bb
			end
			return -bb, -a
		end
		local tz0, tz1 = zr(16, 56)
		b:box(g, "Terrace", 280, 290, 0, 4, tz0, tz1, C.hoj, SMOOTH)
		local rz0, rz1 = zr(18, s > 0 and 54 or 44)
		b:rampX(g, "GrandSteps", 272, 0, 280, 4, rz0, rz1, C.hoj, SMOOTH)
		for i = 1, 3 do
			-- step nosings painted on the grand steps (visual only)
			b:part(g, "StepLine", Vector3.new(0.35, 0.05, rz1 - rz0), CFrame.new(272 + i * 2, b.G + i + 0.02, (rz0 + rz1) / 2) * CFrame.Angles(0, 0, math.atan(0.5)), C.hojTrim, SMOOTH, DECO)
		end
		local wz0, wz1 = zr(16, 56)
		b:box(g, "Wing", 290, 312, 0, 18, wz0, wz1, C.hoj, SMOOTH)
		b:bands(g, 290, 312, wz0, wz1, { { 6, 12 } }, C.hojGlass, GLASS, 0.1)
		b:deco(g, "Cornice", 289.6, 312.4, 17, 18.6, wz0 - 0.4, wz1 + 0.4, C.hojTrim, METAL)
		for _, cz in ipairs({ 20, 27, 34, 41, 48 }) do
			local c0, c1 = zr(cz - 0.8, cz + 0.8)
			b:box(g, "Column", 288.2, 289.8, 4, 16, c0, c1, C.hoj, SMOOTH)
		end
		b:deco(g, "Entablature", 287.5, 290, 16, 18, tz0, tz1, C.hoj, SMOOTH)
		local pz0, pz1 = zr(15.2, 17.2)
		b:box(g, "PorticoColumn", 285, 287, 0, 24, pz0, pz1, C.hoj, SMOOTH)
	end
	b:deco(g, "PorticoBeam", 284, 289, 24, 27, -17.2, 17.2, C.hoj, SMOOTH)
	b:deco(g, "PorticoGold", 283.8, 284, 25, 26.2, -15, 15, C.hojTrim, NEON)
	b:deco(g, "Bridge", 290, 312, 18, 26, -16, 16, C.hoj, SMOOTH)
	b:deco(g, "BridgeGlass", 289.8, 290, 19, 23, -14, 14, C.hojGlass, GLASS, { transparency = 0.1 })
	b:cyl(g, "DomeDrum", 301, 28, 0, 4, 22, "Y", C.hoj, SMOOTH, DECO)
	b:ball(g, "Dome", 301, 30, 0, 20, C.dome, SMOOTH, DECO)
	b:cyl(g, "DomeLantern", 301, 41, 0, 2.4, 3, "Y", C.hojTrim, METAL, DECO)
	b:deco(g, "LanternSpike", 300.6, 301.4, 42, 46, -0.4, 0.4, C.hojTrim, METAL)

	-- South: GCPD with the Bat-signal shining onto the clouds
	g = "GCPD"
	b:box(g, "Precinct", 178, 202, 0, 30, -46, -20, C.brick, SLATE)
	b:bands(g, 178, 202, -46, -20, { { 4, 6.5 }, { 10, 12.5 }, { 16, 18.5 }, { 23, 25.5 } }, C.warm, GLASS, 0.2)
	b:deco(g, "Cornice", 177.6, 202.4, 29.6, 30.4, -46.4, -19.6, C.iron, METAL)
	b:deco(g, "PoliceSign", 184, 196, 7, 9, -20.35, -20.05, C.cyan, NEON)
	b:deco(g, "Searchlight", 188, 191, 30.4, 32.4, -36, -33, C.iron, METAL)
	b:deco(g, "SignalBeam", 188.3, 190.7, 32.4, 84, -35.7, -33.3, C.signal, NEON, { transparency = 0.8 })
	b:cyl(g, "SignalDisc", 189.5, 90, -34.5, 0.5, 22, "X", C.signal, NEON, { deco = true, transparency = 0.3 })
	b:deco(g, "BatBody", 188.6, 188.9, 87.6, 91.8, -35.6, -33.4, C.bat, SMOOTH)
	b:part(g, "BatWing", Vector3.new(0.3, 2.6, 8), CFrame.new(188.75, b.G + 90, -38) * CFrame.Angles(-0.35, 0, 0), C.bat, SMOOTH, DECO)
	b:part(g, "BatWing", Vector3.new(0.3, 2.6, 8), CFrame.new(188.75, b.G + 90, -31) * CFrame.Angles(0.35, 0, 0), C.bat, SMOOTH, DECO)
	b:deco(g, "BatEars", 188.6, 188.9, 91.8, 92.6, -35.2, -33.8, C.bat, SMOOTH)

	-- South: Iceberg Lounge with a walkable roof (9-wide fire stair in the alley on its west side)
	g = "Iceberg Lounge"
	b:box(g, "Lounge", 214, 238, 0, 10, -48, -18, C.lounge, SLATE)
	b:bands(g, 214, 238, -48, -18, { { 3, 6 } }, C.cyan, NEON, 0.35)
	b:deco(g, "Canopy", 222, 230, 6.4, 6.9, -18, -15.5, C.iron, METAL)
	b:rampZ(g, "FireStair", -20, 0, -38, 10, 205, 214, C.iron, METAL, { rails = "x0" })
	b:box(g, "FireStairLanding", 205, 214, 0, 10, -48, -38, C.iron, METAL)
	b:box(g, "ParapetS", 214, 238, 10, 11.1, -18.6, -18, C.iron, METAL)
	b:box(g, "ParapetE", 237.4, 238, 10, 11.1, -47.4, -18.6, C.iron, METAL)
	b:box(g, "ParapetN", 205, 238, 10, 11.1, -48, -47.4, C.iron, METAL)
	b:box(g, "ParapetW", 214, 214.6, 10, 11.1, -38, -18.6, C.iron, METAL)
	b:box(g, "ParapetW", 205, 205.6, 10, 11.1, -47.4, -38, C.iron, METAL)
	b:deco(g, "RoofSignFrame", 218, 234, 11.1, 16, -21, -20.6, C.iron, METAL)
	b:deco(g, "RoofSign", 218.5, 233.5, 11.5, 15.6, -21.1, -20.95, C.cyan, NEON)
	b:box(g, "IceSculpture", 226, 230, 10, 13, -30, -26, C.ice, GLASS, { transparency = 0.3 })
	b:part(g, "IceShard", Vector3.new(2, 3.4, 2), CFrame.new(228, b.G + 14.2, -28) * CFrame.Angles(0.4, 0.6, 0.3), C.ice, GLASS, { deco = true, transparency = 0.3 })

	g = "Theater"
	b:box(g, "Theater", 252, 272, 0, 16, -38, -18, C.brickRed, SLATE)
	b:bands(g, 252, 272, -38, -18, { { 10, 12 } }, C.warm, GLASS, 0.2)
	b:deco(g, "Marquee", 255, 269, 7.4, 9.5, -18, -15.5, C.iron, METAL)
	b:deco(g, "MarqueeLights", 255.2, 268.8, 7, 7.4, -17.8, -15.7, C.amber, NEON)
	b:deco(g, "BladeSign", 261.6, 262.4, 9.5, 15, -17.5, -15.5, C.red, NEON)
	b:deco(g, "Cornice", 251.6, 272, 15.6, 16.4, -38.4, -17.6, C.iron, METAL)

	-- South back: chemical tanks, warehouse with a loading dock (ramp from the lot behind the lounge)
	g = "Chemical Plant"
	b:cyl(g, "ChemTank", 256, 6, -79, 12, 7, "Y", C.tank, METAL)
	b:cyl(g, "ChemTank", 268, 6, -79, 12, 7, "Y", C.tank, METAL)
	b:deco(g, "ChemDrip", 255.7, 256.3, 2, 11, -75.6, -75.4, C.green, NEON)
	b:deco(g, "ChemDrip", 267.7, 268.3, 3, 10, -75.6, -75.4, C.green, NEON)

	g = "Warehouse"
	b:box(g, "Warehouse", 180, 206, 0, 12, -82, -56, C.warehouse, METAL)
	b:deco(g, "RoofTrim", 179.7, 206.3, 11.4, 12.3, -82.3, -55.7, C.iron, METAL)
	b:deco(g, "WarehouseDoor", 184, 200, 0.3, 8, -55.9, -55.7, C.stone, METAL)
	b:box(g, "LoadingDock", 206, 218, 0, 4, -82, -60, C.dock, SLATE)
	b:rampX(g, "DockRamp", 218, 4, 227, 0, -72, -63, C.dock, SLATE, { rails = "both", railColor = C.iron, railMaterial = METAL })
	b:box(g, "Crate", 207, 209.5, 4, 6.5, -81, -78.5, C.wood, WOOD)
	b:box(g, "Crate", 210, 212.5, 4, 6, -81, -79, C.wood, WOOD)
	b:box(g, "Crate", 207.3, 209.2, 6.5, 8.4, -80.7, -78.8, C.wood, WOOD)

	-- Hazards (A8, stage 2 = more): rain puddles off the main street
	g = "Hazards"
	b:hazard(g, "RainPuddle", 247.5, 58, 0, 6, 0.65, C.puddle, GLASS, 0.15)
	b:hazard(g, "RainPuddle", 232, -60, 0, 6, 0.65, C.puddle, GLASS, 0.15)
	b:hazard(g, "RainPuddle", 286, -66, 0, 6, 0.65, C.puddle, GLASS, 0.15)
	b:hazard(g, "RainPuddle", 202, 62, 0, 5, 0.65, C.puddle, GLASS, 0.15)

	b:sideWalls()

end

-- ---------------------------------------------------------------------------------------------------------------
-- Stage 3: Spider-Verse (Desert, X 316-526). Buildings archived by the D8 scratch layout.
-- Two rooftop routes: north A(6) -> B(10) -> C(14) -> D(10) -> E(6) over web bridges (both ends reach the street),
-- south Q(6) -> R(10) -> S(14), plus a construction site with scaffold decks (5 -> 10) and a tower crane.
-- ---------------------------------------------------------------------------------------------------------------

local SV = {
	floor = rgb(56, 54, 68),
	road = rgb(42, 42, 52),
	sidewalk = rgb(134, 130, 142),
	yellow = rgb(255, 212, 40),
	crossing = rgb(236, 236, 240),
	brickRed = rgb(184, 64, 52),
	brickOrange = rgb(208, 118, 66),
	teal = rgb(38, 156, 166),
	purple = rgb(114, 72, 170),
	ochre = rgb(232, 182, 58),
	blue = rgb(58, 110, 198),
	pink = rgb(214, 72, 148),
	navy = rgb(48, 60, 120),
	green = rgb(46, 150, 112),
	brown = rgb(150, 84, 56),
	outline = rgb(20, 20, 26),
	iron = rgb(34, 34, 40),
	window = rgb(150, 220, 255),
	web = rgb(245, 246, 255),
	goo = rgb(236, 238, 250),
	magenta = rgb(255, 50, 160),
	cyan = rgb(0, 220, 255),
	neonYellow = rgb(255, 228, 60),
	towerWood = rgb(152, 102, 62),
	crane = rgb(250, 190, 30),
	fence = rgb(150, 160, 170),
	hoarding = rgb(70, 96, 140),
	plank = rgb(172, 132, 84),
	beam = rgb(220, 100, 40),
	cement = rgb(150, 146, 140),
	lampGreen = rgb(34, 64, 50),
	lampLight = rgb(255, 214, 140),
	hydrant = rgb(210, 40, 40),
	concrete = rgb(120, 118, 124),
}

-- Rooftop building with window bands, black comic-outline parapets (with gaps for bridges/landings).
local function svRoofBuilding(b, g, x0, x1, z0, z1, top, color, gaps, bands)
	b:box(g, "Building", x0, x1, 0, top, z0, z1, color, PLASTIC)
	b:bands(g, x0, x1, z0, z1, bands, SV.window, GLASS, 0.1)
	b:parapets(g, x0, x1, z0, z1, top, SV.outline, gaps)
end

-- Web bridge between two roofs (9-wide tilted slab + white rails + web strands above it).
local function svWebBridge(b, g, xa, ha, xb, hb, z0, z1)
	b:rampX(g, "WebBridge", xa, ha, xb, hb, z0, z1, SV.web, SMOOTH, { rails = "both", railColor = SV.web, railMaterial = SMOOTH })
	b:strand(g, "WebLine", xa, ha + 3.2, z0 + 0.2, xb, hb + 3.2, z0 + 0.2, 0.18, SV.web)
	b:strand(g, "WebLine", xa, ha + 3.2, z1 - 0.2, xb, hb + 3.2, z1 - 0.2, 0.18, SV.web)
end

-- Water tower on a roof: wooden tank on thin legs (tank is solid, legs visual).
local function svWaterTower(b, g, cx, cz, roof)
	b:cyl(g, "WaterTank", cx, roof + 8.3, cz, 6, 6, "Y", SV.towerWood, WOOD)
	b:cyl(g, "WaterTankRoof", cx, roof + 11.6, cz, 0.6, 6.6, "Y", SV.outline, METAL, DECO)
	for _, o in ipairs({ { -2.2, -2.2 }, { 2.2, -2.2 }, { -2.2, 2.2 }, { 2.2, 2.2 } }) do
		b:deco(g, "WaterTowerLeg", cx + o[1] - 0.2, cx + o[1] + 0.2, roof, roof + 5.3, cz + o[2] - 0.2, cz + o[2] + 0.2, SV.iron, METAL)
	end
end

-- 9-wide fire escape (ramp along Z from the street side up to a slab landing that joins a roof edge).
local function svFireEscape(b, g, x0, x1, zFoot, zTop, top, zEnd, railSide)
	b:rampZ(g, "FireEscape", zFoot, 0, zTop, top, x0, x1, SV.iron, METAL, { rails = railSide })
	local l0, l1 = math.min(zTop, zEnd), math.max(zTop, zEnd)
	b:box(g, "FireEscapeLanding", x0, x1, top - 0.6, top, l0, l1, SV.iron, METAL)
	local outer = zEnd > zTop and l1 or l0
	local railX0, railX1 = x0, x0 + 0.6
	if railSide == "x1" then
		railX0, railX1 = x1 - 0.6, x1
	end
	b:box(g, "FireEscapeRail", railX0, railX1, top, top + 1.1, l0, l1, SV.iron, METAL)
	local ez0, ez1 = outer - 0.6, outer
	if outer == l0 then
		ez0, ez1 = l0, l0 + 0.6
	end
	b:box(g, "FireEscapeRail", x0, x1, top, top + 1.1, ez0, ez1, SV.iron, METAL)
	b:box(g, "FireEscapePost", railX0, railX1, 0, top - 0.6, ez0, ez1, SV.iron, METAL)
end

local function buildSpiderVerse(b)
	local C = SV
	local g
	local dx0, dx1 = b.decalX0, b.decalX1

	g = "Street"
	b:deco(g, "Road", dx0, dx1, -0.3, 0.08, -12, 12, C.road, SMOOTH)
	b:deco(g, "SidewalkNorth", dx0, dx1, -0.3, 0.16, 12, 17, C.sidewalk, SMOOTH)
	b:deco(g, "SidewalkSouth", dx0, dx1, -0.3, 0.16, -17, -12, C.sidewalk, SMOOTH)
	b:deco(g, "CenterLine", dx0 + 1, dx1 - 1, -0.2, 0.12, -0.6, -0.2, C.yellow, SMOOTH)
	b:deco(g, "CenterLine", dx0 + 1, dx1 - 1, -0.2, 0.12, 0.2, 0.6, C.yellow, SMOOTH)
	for i = 0, 8 do
		local z = -11 + i * 2.6
		b:deco(g, "Crosswalk", 424, 432, -0.2, 0.13, z, z + 1.3, C.crossing, SMOOTH)
	end
	g = "Street Lights"
	for _, x in ipairs({ 350, 395, 490 }) do
		for _, s in ipairs({ 1, -1 }) do
			local pz0, pz1, az0, az1, lz0, lz1 = 15.4, 16.1, 12, 15.8, 12, 13.1
			if s < 0 then
				pz0, pz1, az0, az1, lz0, lz1 = -16.1, -15.4, -15.8, -12, -13.1, -12
			end
			b:box(g, "LampPost", x - 0.35, x + 0.35, 0, 10, pz0, pz1, C.lampGreen, METAL)
			b:deco(g, "LampArm", x - 0.25, x + 0.25, 10, 10.4, az0, az1, C.lampGreen, METAL)
			b:deco(g, "LampLight", x - 0.45, x + 0.45, 9.4, 10, lz0, lz1, C.lampLight, NEON)
		end
	end
	for _, p in ipairs({ { 366, 16.4 }, { 446, -16.4 }, { 505, 16.4 } }) do
		b:cyl(g, "Hydrant", p[1], 0.7, p[2], 1.4, 0.8, "Y", C.hydrant, METAL, DECO)
	end
	-- web lines slung across the street between the rooftops
	g = "Web Lines"
	b:strand(g, "WebLine", 349, 17.6, -20.3, 358, 9.95, 20.3, 0.25, C.web)
	b:strand(g, "WebLine", 402, 13.95, 22.3, 421, 5.95, -18.3, 0.25, C.web)
	b:strand(g, "WebLine", 490, 27.5, 20.3, 506, 23.5, -18.3, 0.25, C.web)
	b:strand(g, "WebLine", 380, 30, 20.3, 398, 46, -20, 0.25, C.web)
	b:strand(g, "WebLine", 496, 13.95, -22.4, 505.2, 22, -30, 0.2, C.web)
	b:strand(g, "WebLine", 402, 13.95, 45.8, 408.2, 9.95, 52, 0.2, C.web)

	-- North rooftop chain (roof A has the west fire escape, roof E the east one)
	g = "Queens North"
	svRoofBuilding(b, g, 326, 348, 24, 48, 6, C.brickRed, { W = { { 36, 46 } }, E = { { 30, 39 } } }, { { 1.8, 4.2 } })
	svFireEscape(b, g, 317, 326, 24, 36, 6, 46, "x0")
	svWebBridge(b, g, 344, 6, 354, 10, 30, 39)
	svRoofBuilding(b, g, 354, 376, 20, 46, 10, C.brickOrange, { W = { { 30, 39 } }, E = { { 30, 39 } } }, { { 2, 4.4 }, { 6, 8.4 } })
	b:box(g, "RoofAC", 358, 362, 10, 11.6, 40, 44, C.concrete, METAL)
	svWebBridge(b, g, 374, 10, 382, 14, 30, 39)
	svRoofBuilding(b, g, 382, 402, 22, 46, 14, C.purple, { W = { { 30, 39 } }, E = { { 34, 43 } } }, { { 2, 4.4 }, { 6, 8.4 }, { 10, 12.4 } })
	svWaterTower(b, g, 386.5, 42.5, 14)
	svWebBridge(b, g, 402, 14, 410, 10, 34, 43)
	svRoofBuilding(b, g, 408, 430, 30, 54, 10, C.ochre, { W = { { 34, 43 } }, E = { { 33, 42 } } }, { { 2, 4.4 }, { 6, 8.4 } })
	b:box(g, "RoofAC", 412, 416, 10, 11.6, 48, 52, C.concrete, METAL)
	svWebBridge(b, g, 430, 10, 438, 6, 33, 42)
	svRoofBuilding(b, g, 436, 454, 22, 44, 6, C.blue, { W = { { 33, 42 } }, E = { { 34, 43 } } }, { { 1.8, 4.2 } })
	b:rampX(g, "FireEscape", 454, 6, 466, 0, 34, 43, C.iron, METAL, { rails = "both" })
	-- F: tall brick block with a comic billboard and a water tower (not walkable)
	g = "Comic Billboard Block"
	b:box(g, "Building", 488, 518, 0, 28, 20, 48, C.brickRed, PLASTIC)
	b:bands(g, 488, 518, 20, 48, { { 3, 5.4 }, { 8, 10.4 }, { 13, 15.4 }, { 18, 20.4 }, { 23, 25.4 } }, C.window, GLASS, 0.1)
	b:deco(g, "Cornice", 487.6, 518.4, 27.4, 28.6, 19.6, 48.4, C.outline, METAL)
	b:part(g, "BillboardBack", Vector3.new(22, 11, 0.3), CFrame.new(503, b.G + 16.5, 19.35) * CFrame.Angles(0, 0, -0.14), C.magenta, NEON, DECO)
	b:part(g, "Billboard", Vector3.new(19, 8.4, 0.3), CFrame.new(503, b.G + 16.5, 19.1) * CFrame.Angles(0, 0, 0.1), C.neonYellow, SMOOTH, DECO)
	b:deco(g, "BillboardSpider", 501.6, 504.4, 14.8, 18.6, 18.85, 18.95, C.outline, SMOOTH)
	b:cyl(g, "WaterTank", 510, 34.5, 40, 6, 6, "Y", C.towerWood, WOOD, DECO)
	b:deco(g, "WaterTowerBase", 507, 513, 28.6, 31.5, 37, 43, C.iron, METAL)

	-- North skyline behind the back alley (not walkable)
	g = "North Skyline"
	for _, blk in ipairs({ { 326, 376, 20, C.teal }, { 492, 520, 18, C.purple } }) do
		b:box(g, "Backdrop", blk[1], blk[2], 0, blk[3], 58, 78, blk[4], PLASTIC)
		b:bands(g, blk[1], blk[2], 58, 78, { { 4, 6.4 }, { 10, 12.4 } }, C.window, GLASS, 0.1)
		b:deco(g, "Cornice", blk[1] - 0.4, blk[2] + 0.4, blk[3] - 0.6, blk[3] + 0.4, 57.6, 78.4, C.outline, METAL)
	end

	-- South: brick walk-up with a decorative fire escape on its facade
	g = "Walk-up"
	b:box(g, "Building", 324, 350, 0, 18, -48, -20, C.brickOrange, PLASTIC)
	b:bands(g, 324, 350, -48, -20, { { 2.5, 4.5 }, { 7.5, 9.5 }, { 12.5, 14.5 } }, C.window, GLASS, 0.1)
	b:deco(g, "Cornice", 323.6, 350.4, 17.4, 18.6, -48.4, -19.6, C.outline, METAL)
	for _, h in ipairs({ 5, 10, 15 }) do
		b:deco(g, "FireEscapeDeck", 330, 344, h, h + 0.3, -19.85, -18, C.iron, METAL)
		b:deco(g, "FireEscapeRail", 330, 344, h + 0.3, h + 1.5, -18.1, -17.9, C.iron, METAL)
	end
	b:part(g, "FireEscapeStair", Vector3.new(7.1, 0.3, 1.6), CFrame.new(337, b.G + 7.65, -19) * CFrame.Angles(0, 0, math.atan(5 / 6)), C.iron, METAL, DECO)
	b:part(g, "FireEscapeStair", Vector3.new(7.1, 0.3, 1.6), CFrame.new(337, b.G + 12.65, -19) * CFrame.Angles(0, 0, -math.atan(5 / 6)), C.iron, METAL, DECO)
	b:deco(g, "Graffiti", 344.5, 349.5, 1, 3.8, -19.95, -19.8, C.magenta, NEON)
	b:deco(g, "Graffiti", 345.5, 348.5, 1.6, 3.2, -19.8, -19.7, C.cyan, NEON)

	-- South: construction site (fenced; 14-wide entrance from the street and a back gate to the south back alley),
	-- scaffold decks at 5 and 10 on 9-wide ramps, steel frame, tower crane with its jib swung over the street
	g = "Construction Site"
	-- plywood hoardings (street and west side, plastered with comic posters) hide the scaffold; chain-link elsewhere
	b:box(g, "Hoarding", 356, 378, 0, 9, -20, -19.6, C.hoarding, WOOD)
	b:box(g, "Hoarding", 392, 410, 0, 9, -20, -19.6, C.hoarding, WOOD)
	b:deco(g, "HazardStripe", 356, 378, 9, 9.5, -20.05, -19.55, C.crane, SMOOTH)
	b:deco(g, "HazardStripe", 392, 410, 9, 9.5, -20.05, -19.55, C.crane, SMOOTH)
	b:deco(g, "Poster", 359, 365, 2.5, 7.5, -19.75, -19.55, C.magenta, SMOOTH)
	b:deco(g, "Poster", 367, 372, 3, 7, -19.75, -19.55, C.neonYellow, SMOOTH)
	b:deco(g, "Poster", 396, 403, 2, 7.5, -19.75, -19.55, C.cyan, SMOOTH)
	b:deco(g, "PosterSpider", 398.5, 400.5, 3.5, 6, -19.55, -19.45, C.outline, SMOOTH)
	b:box(g, "Hoarding", 356, 356.4, 0, 9, -78, -20, C.hoarding, WOOD)
	b:box(g, "Fence", 356.4, 410, 0, 6, -78, -77.7, C.fence, METAL, { transparency = 0.45 })
	b:box(g, "Fence", 409.7, 410, 0, 6, -44, -20, C.fence, METAL, { transparency = 0.45 })
	b:box(g, "Fence", 409.7, 410, 0, 6, -77.7, -60, C.fence, METAL, { transparency = 0.45 })
	b:box(g, "ScaffoldDeck", 360, 376, 4.4, 5, -40, -26, C.plank, WOOD)
	b:box(g, "ScaffoldDeck", 360, 376, 9.4, 10, -64, -50, C.plank, WOOD)
	for _, p in ipairs({ { 360, -26.5 }, { 375.5, -26.5 }, { 360, -40 }, { 375.5, -40 } }) do
		b:box(g, "ScaffoldPost", p[1], p[1] + 0.5, 0, 4.4, p[2], p[2] + 0.5, C.fence, METAL)
	end
	for _, p in ipairs({ { 360, -50.5 }, { 375.5, -50.5 }, { 360, -64 }, { 375.5, -64 } }) do
		b:box(g, "ScaffoldPost", p[1], p[1] + 0.5, 0, 9.4, p[2], p[2] + 0.5, C.fence, METAL)
	end
	b:rampX(g, "ScaffoldRamp", 386, 0, 376, 5, -35, -26, C.plank, WOOD, { rails = "both", railColor = C.fence, railMaterial = METAL })
	b:rampZ(g, "ScaffoldRamp", -40, 5, -50, 10, 360, 369, C.plank, WOOD, { rails = "both", railColor = C.fence, railMaterial = METAL })
	b:box(g, "ScaffoldRail", 360, 376, 5, 6.1, -26.3, -26, C.fence, METAL)
	b:box(g, "ScaffoldRail", 360, 360.3, 5, 6.1, -40, -26.3, C.fence, METAL)
	b:box(g, "ScaffoldRail", 375.7, 376, 5, 6.1, -40, -35, C.fence, METAL)
	b:box(g, "ScaffoldRail", 369, 376, 5, 6.1, -40, -39.7, C.fence, METAL)
	b:box(g, "ScaffoldRail", 369, 376, 10, 11.1, -50.3, -50, C.fence, METAL)
	b:box(g, "ScaffoldRail", 360, 360.3, 10, 11.1, -64, -50.3, C.fence, METAL)
	b:box(g, "ScaffoldRail", 375.7, 376, 10, 11.1, -64, -50.3, C.fence, METAL)
	b:box(g, "ScaffoldRail", 360.3, 375.7, 10, 11.1, -64, -63.7, C.fence, METAL)
	b:box(g, "PlywoodStack", 369.5, 375.7, 10, 12.6, -52.6, -50.3, C.plank, WOOD)
	for _, p in ipairs({ { 385, -38 }, { 405, -38 }, { 385, -56 }, { 405, -56 } }) do
		b:box(g, "SteelColumn", p[1] - 0.5, p[1] + 0.5, 0, 16, p[2] - 0.5, p[2] + 0.5, C.beam, METAL)
	end
	b:deco(g, "SteelBeam", 384.5, 405.5, 15, 16, -38.5, -37.5, C.beam, METAL)
	b:deco(g, "SteelBeam", 384.5, 405.5, 15, 16, -56.5, -55.5, C.beam, METAL)
	b:deco(g, "SteelBeam", 384.5, 385.5, 15, 16, -55.5, -38.5, C.beam, METAL)
	b:deco(g, "SteelBeam", 404.5, 405.5, 15, 16, -55.5, -38.5, C.beam, METAL)
	b:box(g, "CraneMast", 396, 400, 0, 46, -70, -66, C.crane, METAL)
	b:deco(g, "CraneCab", 395, 401, 46, 50, -71, -65, C.crane, METAL)
	b:deco(g, "CraneJib", 397.2, 398.8, 50, 52, -68, 24, C.crane, METAL)
	b:deco(g, "CraneCounterJib", 397.2, 398.8, 50, 52, -84, -68, C.crane, METAL)
	b:deco(g, "CraneCounterweight", 395.5, 400.5, 47, 51, -83, -79, C.concrete, SLATE)
	b:deco(g, "CraneCable", 397.9, 398.1, 30, 50, 7.9, 8.1, C.outline, METAL)
	b:deco(g, "HangingGirder", 392, 404, 28, 30, 7, 9, C.beam, METAL)
	b:box(g, "BeamStack", 380, 390, 0, 2, -76, -72, C.beam, METAL)
	b:box(g, "BeamStack", 381, 389, 2, 3.2, -75.5, -72.5, C.beam, METAL)
	for _, p in ipairs({ { 380, -22 }, { 390, -22.5 }, { 391, -36 } }) do
		b:cyl(g, "Cone", p[1], 0.6, p[2], 1.2, 0.9, "Y", C.beam, SMOOTH, DECO)
	end

	-- South rooftop chain: Q (6) -> R (10) -> S (14)
	g = "Queens South"
	svRoofBuilding(b, g, 420, 442, -42, -18, 6, C.green, { W = { { -41.4, -32 } }, E = { { -33, -24 } } }, { { 1.8, 4.2 } })
	svFireEscape(b, g, 411, 420, -20, -32, 6, -42, "x0")
	svWebBridge(b, g, 438, 6, 448, 10, -33, -24)
	svRoofBuilding(b, g, 448, 470, -46, -20, 10, C.pink, { W = { { -33, -24 } }, E = { { -37, -28 } } }, { { 2, 4.4 }, { 6, 8.4 } })
	b:box(g, "RoofAC", 453, 459, 10, 11.6, -42, -36, C.concrete, METAL)
	svWebBridge(b, g, 468, 10, 476, 14, -37, -28)
	svRoofBuilding(b, g, 476, 496, -48, -22, 14, C.navy, { W = { { -37, -28 } } }, { { 2, 4.4 }, { 6, 8.4 }, { 10, 12.4 } })
	svWaterTower(b, g, 491, -26.5, 14)
	b:deco(g, "RoofSign", 478, 486, 15.1, 19, -22.5, -22.2, C.cyan, NEON)
	b:deco(g, "RoofSignFrame", 477.6, 486.4, 15.1, 19.4, -22.2, -21.9, C.outline, METAL)
	-- T: tall corner block (not walkable), 9-wide gap to S so the south back alley opens onto the street
	g = "Corner Block"
	b:box(g, "Building", 505, 520, 0, 24, -46, -18, C.brown, PLASTIC)
	b:bands(g, 505, 520, -46, -18, { { 3, 5.4 }, { 8, 10.4 }, { 13, 15.4 }, { 18, 20.4 } }, C.window, GLASS, 0.1)
	b:deco(g, "Cornice", 504.6, 520.4, 23.4, 24.6, -46.4, -17.6, C.outline, METAL)
	b:deco(g, "Graffiti", 507, 513, 1, 4, -17.95, -17.8, C.neonYellow, NEON)

	-- South skyline behind the back alley (not walkable)
	g = "South Skyline"
	for _, blk in ipairs({ { 420, 470, 18, C.purple }, { 476, 520, 22, C.teal } }) do
		b:box(g, "Backdrop", blk[1], blk[2], 0, blk[3], -82, -60, blk[4], PLASTIC)
		b:bands(g, blk[1], blk[2], -82, -60, { { 4, 6.4 }, { 10, 12.4 } }, C.window, GLASS, 0.1)
		b:deco(g, "Cornice", blk[1] - 0.4, blk[2] + 0.4, blk[3] - 0.6, blk[3] + 0.4, -82.4, -59.6, C.outline, METAL)
	end

	-- Hazards (A8, stage 3 = most): sticky web goo on the rooftop routes and alleys, wet cement in the site
	g = "Hazards"
	b:hazard(g, "WebGoo", 364, 25, 10, 5, 0.5, C.goo, SMOOTH, 0.1)
	b:hazard(g, "WebGoo", 420, 38, 10, 5, 0.5, C.goo, SMOOTH, 0.1)
	b:hazard(g, "WebGoo", 459, -27, 10, 5, 0.5, C.goo, SMOOTH, 0.1)
	b:hazard(g, "WebGoo", 400, 64, 0, 6, 0.5, C.goo, SMOOTH, 0.1)
	b:hazard(g, "WebGoo", 440, -54, 0, 6, 0.5, C.goo, SMOOTH, 0.1)
	b:hazard(g, "WetCement", 395, -47, 0, 6, 0.4, C.cement, SLATE, 0)

	b:sideWalls()


	-- comic-book outline over the city blocks (A9: one Highlight for this stage model)
	local comic = Instance.new("Model")
	comic.Name = "ComicOutline"
	comic.Parent = b.model
	for _, name in ipairs({ "Queens North", "Queens South", "Comic Billboard Block", "North Skyline", "South Skyline", "Walk-up", "Corner Block" }) do
		local folder = b.groups[name]
		if folder then
			folder.Parent = comic
		end
	end
	local outline = Instance.new("Highlight")
	outline.Name = "ComicInk"
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.FillTransparency = 1
	outline.OutlineColor = rgb(12, 12, 18)
	outline.OutlineTransparency = 0.15
	outline.Parent = comic
end

local BUILDERS = {
	Forest = { build = buildAvengers, floor = { color = AV.floor, material = SMOOTH } },
	Lake = { build = buildJusticeLeague, floor = { color = JL.floor, material = SLATE } },
	Desert = { build = buildSpiderVerse, floor = { color = SV.floor, material = SMOOTH } },
}

-- Themes the stage's visual-only zone floor (Workspace.Ground.ZoneFloor_<Key>, built by the ground step). Only colour,
-- material and the grid overlay's opacity change; its size, height and (non-)collision stay as the ground step made them.
local function recolourFloor(ws, key, look)
	local ground = ws:FindFirstChild("Ground")
	local floor = ground and ground:FindFirstChild("ZoneFloor_" .. key)
	if not (floor and floor:IsA("BasePart")) then
		print(string.format("%s WARNING: Workspace.Ground.ZoneFloor_%s not found; floor not recoloured.", LOG_PREFIX, key))
		return false
	end
	floor.Color = look.color
	floor.Material = look.material
	pcall(function()
		(floor :: any).MaterialVariant = ""
	end)
	floor.CanCollide = false
	floor.CanQuery = false
	floor.CanTouch = false
	for _, child in ipairs(floor:GetChildren()) do
		if child:IsA("Texture") then
			child.Transparency = 0.88
		end
	end
	return true
end

local function findBounds(ws, key)
	local objects = ws:FindFirstChild("__OBJECTS")
	local areas = objects and objects:FindFirstChild("Areas")
	local guardAreas = areas and areas:FindFirstChild("GuardAreas")
	local zone = guardAreas and guardAreas:FindFirstChild(key)
	local bounds = zone and zone:FindFirstChild("Bounds")
	if bounds and bounds:IsA("BasePart") then
		return bounds
	end
	return nil
end

function Step.Apply(place, spPlace, ctx)
	ctx = ctx or {}
	local ws = place.Workspace
	local groundY = ctx.groundY
	if not groundY then
		local baseplate = ws:FindFirstChild("Baseplate")
		assert(baseplate and baseplate:IsA("BasePart"), "env_a: no ctx.groundY and no Workspace.Baseplate")
		groundY = baseplate.CFrame.Position.Y + baseplate.Size.Y / 2
	end
	local groundFolder = ws:FindFirstChild("Ground")
	local floorTopY = groundFolder and groundFolder:GetAttribute("ZoneFloorTopY")
	if type(floorTopY) ~= "number" or floorTopY < groundY or floorTopY > groundY + 0.2 then
		floorTopY = groundY + Step.DEFAULT_FLOOR_LIFT
	end

	local root = ws:FindFirstChild(Step.FOLDER_NAME)
	if not root then
		root = Instance.new("Folder")
		root.Name = Step.FOLDER_NAME
		root.Parent = ws
	end

	for _, stage in ipairs(Step.STAGES) do
		for _, old in ipairs(root:GetChildren()) do
			if old.Name == stage.key then
				old:Destroy()
			end
		end
		local model = Instance.new("Model")
		model.Name = stage.key
		model:SetAttribute("StageNumber", stage.number)
		model:SetAttribute("StageName", stage.name)
		model:SetAttribute("Theme", stage.theme)
		model:SetAttribute("XMin", stage.x0)
		model:SetAttribute("XMax", stage.x1)
		model:SetAttribute("GroundY", groundY)
		model:SetAttribute("BuiltBy", "scripts/steps/env_a.luau")
		local b = newBuilder(model, stage, groundY)
		BUILDERS[stage.key].build(b)
		-- D9: villain post + egg ring + cover rocks (kept in the Workspace by the D8 scratch layout)
		local ringOpts = {
			key = stage.key,
			number = stage.number,
			x0 = stage.x0,
			x1 = stage.x1,
			groundY = groundY,
			floorTopY = floorTopY,
			count = Step.SPOTS_PER_STAGE,
			minSpotX = stage.spotMinX,
			bounds = findBounds(ws, stage.key),
		}
		ScratchLayout.BuildRing(model, ringOpts)
		local parts, collidable = b:validate(floorTopY)
		local ring = ScratchLayout.ValidateRing(model, ringOpts)
		model:SetAttribute("EggSpotCount", Step.SPOTS_PER_STAGE)
		model:SetAttribute("HiddenEggSpots", ring.hidden)
		;(model :: any).WorldPivotData = CFrame.new((stage.x0 + stage.x1) / 2, groundY, 0)
		model.Parent = root
		local recoloured = recolourFloor(ws, stage.key, BUILDERS[stage.key].floor)
		print(string.format("%s Stage %d %s (%s, X %d-%d): %d parts (%d collidable), %d ramps, %d hazards; egg ring: VillainPost (%.1f, %.0f), %d EggSpots %.1f-%.1f studs out (%d hidden, %d cover rock parts, spots >= %.1f apart, rock walkways >= %.1f, opening %.0f deg)%s.",
			LOG_PREFIX, stage.number, stage.name, stage.key, stage.x0, stage.x1, parts, collidable, #b.ramps, #b.hazards,
			ring.post.x, ring.post.z, Step.SPOTS_PER_STAGE, ring.minDist, ring.maxDist, ring.hidden, ring.rocks, ring.minGap, ring.minRoute, ring.opening,
			recoloured and ", floor recoloured" or ""))
	end
end

return Step
