-- scripts/steps/post_scratch_layout.luau
-- Owner SCRATCH (docs/VISUAL_PASS_PLAN.md D8 + D9). Two jobs live here so the scratch-layout rules have one home:
--
--   D9  Egg ring around the villain (library, called by scripts/steps/env_a.luau and env_b.luau while they build):
--       Layout.BuildRing(model, opts)    places <Key>.VillainPost in the middle of the stage X range at |Z| = 40
--                                        (stage 1, 3, 5 on +Z; 2, 4, 6 on -Z), facing -X (the hub), the EggSpot
--                                        markers as a horseshoe on the floor around it (12-28 studs out, opening
--                                        toward the main street) and one low Slate cover rock per hidden spot,
--                                        between the egg and the villain, under <Key>.EggCover.
--       Layout.ValidateRing(model, opts) reads the instances back and errors on any D9 violation.
--       scripts/steps/stages.luau then builds the nests on the markers and moves the Guard onto the post, unchanged.
--
--   D8  Scratch layout (this post step, runs after the hero builder via the post_*.luau hook):
--       Layout.Apply(place, spPlace, ctx) moves every procedural building / prop group of
--       Workspace.StageEnvironments.<Key> into ReplicatedStorage.Archived_ProceduralEnvironments.<Key> (kept as a
--       backup for the owner's builder, never deleted; world CFrames unchanged, so dragging a group back into the
--       stage model restores it). What stays in Workspace.StageEnvironments.<Key>: EggSpots, VillainPost, EggCover,
--       Boundary (invisible side walls) and Rain (stage 2's RainVolume region marker for StageWeather, invisible and non-collidable);
--       the whole EndWall model stays (Red Line end wall + invisible side walls of stages 4-6). Everything outside
--       StageEnvironments (Workspace.Ground zone floors, Workspace.Hub gates and board, zone Bounds, lighting /
--       StageAmbience) is not touched.
--       Slow hazards (StageHazard parts) are archived with the groups that hold them: they were placed around the
--       procedural buildings (sea shallows, puddles, quicksand) and would be invisible slow zones on an empty floor.
--       StageHazardService stays installed and simply finds no hazard until the builder tags new ones under
--       Workspace.StageEnvironments.
--       After the move it checks its own result (errors) and the rest of the world (warnings): nothing collidable
--       left in the main street |Z| <= 15 or on a villain pad, no hazard left, the nests of stages.luau sit on the
--       ring markers.
--
-- Lune notes: explicit CFrames only (CFrame.Angles; never CFrame.lookAt, mirrored in Lune 0.10.5); Instance.new
-- ignores its parent argument; Model.WorldPivotData is written, not WorldPivot.

local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local Layout = {}

-- D8
Layout.ENV_FOLDER = "StageEnvironments"
Layout.ARCHIVE_NAME = "Archived_ProceduralEnvironments"
Layout.KEEP_CHILDREN = { EggSpots = true, VillainPost = true, EggCover = true, Boundary = true, Rain = true }
Layout.KEEP_MODELS = { EndWall = true }
Layout.STREET_HALF_WIDTH = 15 -- main street |Z| <= 15 stays clear of collidables up to STREET_CLEAR_HEIGHT
Layout.STREET_CLEAR_HEIGHT = 12
Layout.STREET_X0, Layout.STREET_X1 = 76, 1471.5 -- stage 1 start (past the safe zone X <= 75) .. end of stage 6

-- D9
Layout.POST_ABS_Z = 40
Layout.POST_Z_TOLERANCE = 4 -- "|Z| ~ 40": the validator accepts 36..44
Layout.RING_ARC_DEG = 270 -- the horseshoe spans 270 degrees; the 90-degree gap faces the main street
Layout.RING_MIN, Layout.RING_MAX = 12, 28
Layout.SPOT_MIN_ABS_Z, Layout.SPOT_MAX_ABS_Z = 16, 72
Layout.SPOT_MIN_GAP = 3
Layout.OPENING_MIN_DEG = 40 -- no spot within this angle of the post -> street direction
Layout.POST_PAD = 20
Layout.POST_CLEAR_HEIGHT = 14
Layout.ROCK_MAX_HEIGHT = 3.5 -- over the floor
Layout.ROCK_SETBACK = 3.6 -- rock centre this far inside its hidden egg, toward the villain
Layout.ROCK_ROUTE_WIDTH = 8 -- A6: >= 8-stud walkways between cover rocks (Kaido)
Layout.ROCK_EGG_CLEARANCE = 0.3 -- own egg: the rock never touches the nest
Layout.ROCK_OTHER_EGG_CLEARANCE = 1.0 -- other eggs: room to walk up to them
-- Nest radii the checks assume: stages.luau clones nest templates of at most 2.8 studs (hidden) / 5 studs (open)
-- footprint onto the markers (its NEST_MAX_FOOTPRINT); AreaEggService rescales them to their egg at runtime.
Layout.HIDDEN_NEST_RADIUS = 1.4
Layout.OPEN_NEST_RADIUS = 2.5
Layout.ROCK_COLOR = Color3.fromRGB(122, 116, 108)
Layout.ROCK_CAP_COLOR = Color3.fromRGB(148, 142, 132)
Layout.DEFAULT_FLOOR_LIFT = 0.026 -- zone floor top over the baseplate top (ground step)

local LOG_PREFIX = "[StealaHero Build][post_scratch_layout]"

-- Ring radii by spot count: 12 spots at 18 (open) / 24 (hidden), 14 spots a little wider so the cover rocks keep
-- their 8-stud walkways.
function Layout.RingRadii(count)
	if count <= 12 then
		return 18, 24
	end
	return 19, 26
end

-- Zone floor top (Workspace.Ground attribute written by the ground step), else baseplate top + DEFAULT_FLOOR_LIFT.
function Layout.FloorTopY(ws, groundY)
	local ground = ws and ws:FindFirstChild("Ground")
	local top = ground and ground:GetAttribute("ZoneFloorTopY")
	if type(top) ~= "number" or top < groundY or top > groundY + 0.2 then
		top = groundY + Layout.DEFAULT_FLOOR_LIFT
	end
	return top
end

-- Middle of the stage X range, |Z| = POST_ABS_Z: odd stages on +Z, even stages on -Z.
function Layout.PostPosition(number, x0, x1)
	local side = (number % 2 == 1) and 1 or -1
	return (x0 + x1) / 2, side * Layout.POST_ABS_Z, side
end

---------------------------------------------------------------------------------------------------
-- 2D footprint helpers (upright parts only: the ring markers and rocks are never tilted)
---------------------------------------------------------------------------------------------------

local function footprint(part)
	local cf = part.CFrame
	local r, l = cf.RightVector, cf.LookVector
	local p = cf.Position
	return {
		c = { p.X, p.Z },
		axes = { { r.X, r.Z }, { -l.X, -l.Z } },
		half = { part.Size.X / 2, part.Size.Z / 2 },
	}
end

local function squareFootprint(x, z, hx, hz)
	return { c = { x, z }, axes = { { 1, 0 }, { 0, 1 } }, half = { hx, hz } }
end

local function project(f, ax)
	local centre = f.c[1] * ax[1] + f.c[2] * ax[2]
	local extent = 0
	for i = 1, 2 do
		extent += f.half[i] * math.abs(f.axes[i][1] * ax[1] + f.axes[i][2] * ax[2])
	end
	return centre - extent, centre + extent
end

-- Largest separating gap over the four SAT axes: > 0 means apart (and the true distance is at least this), <= 0
-- means the footprints overlap.
local function footprintGap(a, b)
	local best = -math.huge
	for _, f in ipairs({ a, b }) do
		for i = 1, 2 do
			local ax = f.axes[i]
			local a0, a1 = project(a, ax)
			local b0, b1 = project(b, ax)
			best = math.max(best, b0 - a1, a0 - b1)
		end
	end
	return best
end

-- Distance from an XZ point to a footprint (0 inside it).
local function pointFootprintDistance(f, x, z)
	local dx, dz = x - f.c[1], z - f.c[2]
	local sum = 0
	for i = 1, 2 do
		local d = math.abs(dx * f.axes[i][1] + dz * f.axes[i][2]) - f.half[i]
		if d > 0 then
			sum += d * d
		end
	end
	return math.sqrt(sum)
end

local function pointInFootprint(f, x, z, pad)
	local dx, dz = x - f.c[1], z - f.c[2]
	for i = 1, 2 do
		if math.abs(dx * f.axes[i][1] + dz * f.axes[i][2]) > f.half[i] + (pad or 0) then
			return false
		end
	end
	return true
end

local function worldAABB(part)
	local cf, half = part.CFrame, part.Size * 0.5
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local ext = Vector3.new(
		math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
		math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
		math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z
	)
	local p = cf.Position
	return p - ext, p + ext
end

local function yawTowards(dx, dz)
	-- CFrame.Angles(0, yaw, 0) has LookVector (-sin yaw, 0, -cos yaw): pick yaw so it points along (dx, dz)
	return math.atan2(-dx, -dz)
end

---------------------------------------------------------------------------------------------------
-- D9 ring layout
---------------------------------------------------------------------------------------------------

local function sideName(phiDeg)
	if phiDeg < -67.5 then
		return "hub side, near the street"
	elseif phiDeg < -22.5 then
		return "hub side"
	elseif phiDeg <= 22.5 then
		return "back of the ring"
	elseif phiDeg <= 67.5 then
		return "far side"
	end
	return "far side, near the street"
end

-- Spot list for a post: angles phi from -ARC/2 to +ARC/2 (phi = 0 points away from the street, negative phi toward
-- the hub), odd indices hidden on the outer radius, even indices open on the inner radius.
function Layout.RingSpots(postX, postZ, side, count)
	local rOpen, rHidden = Layout.RingRadii(count)
	local spots = {}
	local half = Layout.RING_ARC_DEG / 2
	for i = 1, count do
		local phiDeg = -half + Layout.RING_ARC_DEG * (i - 1) / (count - 1)
		local phi = math.rad(phiDeg)
		local hidden = i % 2 == 1
		local r = hidden and rHidden or rOpen
		local ux, uz = math.sin(phi), side * math.cos(phi) -- unit vector post -> spot
		table.insert(spots, {
			n = i,
			x = postX + ux * r,
			z = postZ + uz * r,
			r = r,
			phiDeg = phiDeg,
			ux = ux,
			uz = uz,
			hidden = hidden,
			label = string.format("Egg ring, %s%s", sideName(phiDeg), hidden and ", behind a cover rock" or ""),
		})
	end
	return spots
end

local function newMarker(name, cf)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Locked = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function newRockPart(parent, name, size, cf, color, spotName)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Slate
	p.Anchored = true
	p.Locked = true
	p.CanCollide = true
	p.CanQuery = true
	p.CanTouch = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p:SetAttribute("EggSpot", spotName)
	p.Parent = parent
	return p
end

-- Low two-block rock between the hidden egg and the villain, long side across the line of sight. Sizes and yaw jitter
-- vary by index so the ring does not look stamped. Top <= groundY + 3.35 (<= 3.5 over the floor).
local function buildCoverRock(folder, spot, k, postX, postZ, groundY)
	local mainW = 4.8 + (k % 3) * 0.3
	local mainD = 2.4 + (k % 2) * 0.3
	local mainTop = 2.3 + ((k + 1) % 3) * 0.2
	local jitter = math.rad(((k % 5) - 2) * 3)
	local d = spot.r - Layout.ROCK_SETBACK
	local cx, cz = postX + spot.ux * d, postZ + spot.uz * d
	-- local Z along the radial direction, local X across it (tangent)
	local yaw = math.atan2(spot.ux, spot.uz) + jitter
	local bottom = -0.3 -- sunk a little into the floor so it never looks like it floats
	local mainName = "CoverRock_" .. spot.n
	local spotName = "EggSpot_" .. spot.n
	newRockPart(folder, mainName, Vector3.new(mainW, mainTop - bottom, mainD),
		CFrame.new(cx, groundY + (bottom + mainTop) / 2, cz) * CFrame.Angles(0, yaw, 0), Layout.ROCK_COLOR, spotName)
	-- cap block: narrower, shifted along the tangent, a little more yaw
	local tx, tz = math.cos(yaw), -math.sin(yaw) -- the main block's local X in world space
	local shift = (k % 2 == 0) and 0.5 or -0.5
	local capBottom, capTop = mainTop - 0.35, mainTop + 0.65
	newRockPart(folder, mainName .. "Cap", Vector3.new(mainW * 0.62, capTop - capBottom, mainD * 0.75),
		CFrame.new(cx + tx * shift, groundY + (capBottom + capTop) / 2, cz + tz * shift) * CFrame.Angles(0, yaw + (shift > 0 and 0.17 or -0.17), 0),
		Layout.ROCK_CAP_COLOR, spotName)
	return mainName
end

-- opts = { key, number, x0, x1, groundY, floorTopY, count }. Replaces the model's VillainPost / EggSpots / EggCover.
-- Returns { post = { x, z, side }, spots = { ... }, rocks = <cover rock count>, parts = <parts created> }.
function Layout.BuildRing(model, opts)
	assert(opts.count and opts.count >= 4, "BuildRing: count")
	for _, name in ipairs({ "VillainPost", "EggSpots", "EggCover" }) do
		local old = model:FindFirstChild(name)
		while old do
			old:Destroy()
			old = model:FindFirstChild(name)
		end
	end
	local G, floorTop = opts.groundY, opts.floorTopY
	local postX, postZ, side = Layout.PostPosition(opts.number, opts.x0, opts.x1)
	local parts = 0

	local post = newMarker("VillainPost", CFrame.new(postX, floorTop, postZ) * CFrame.Angles(0, math.pi / 2, 0)) -- LookVector -X
	post:SetAttribute("PadSize", Layout.POST_PAD)
	post:SetAttribute("ClearHeight", Layout.POST_CLEAR_HEIGHT)
	post:SetAttribute("RingInner", Layout.RING_MIN)
	post:SetAttribute("RingOuter", Layout.RING_MAX)
	post:SetAttribute("RingSide", side > 0 and "+Z" or "-Z")
	post.Parent = model
	parts += 1

	local spotFolder = Instance.new("Folder")
	spotFolder.Name = "EggSpots"
	spotFolder.Parent = model
	local coverFolder = Instance.new("Folder")
	coverFolder.Name = "EggCover"
	coverFolder.Parent = model

	local spots = Layout.RingSpots(postX, postZ, side, opts.count)
	local rocks, k = 0, 0
	for _, s in ipairs(spots) do
		-- nest faces the villain
		local marker = newMarker("EggSpot_" .. s.n, CFrame.new(s.x, floorTop, s.z) * CFrame.Angles(0, yawTowards(postX - s.x, postZ - s.z), 0))
		marker:SetAttribute("Hidden", s.hidden)
		marker:SetAttribute("Elevation", 0)
		marker:SetAttribute("Label", s.label)
		marker:SetAttribute("RingRadius", s.r)
		marker:SetAttribute("RingAngle", s.phiDeg)
		if s.hidden then
			k += 1
			marker:SetAttribute("CoverRock", buildCoverRock(coverFolder, s, k, postX, postZ, G))
			rocks += 1
			parts += 2
		end
		marker.Parent = spotFolder
		parts += 1
	end
	return { post = { x = postX, z = postZ, side = side }, spots = spots, rocks = rocks, parts = parts }
end

-- Reads the model back and errors on any D9 rule. opts = { key, number, x0, x1, groundY, floorTopY, count,
-- minSpotX?, bounds? (zone Bounds part) }. Only kept content (Layout.KEEP_CHILDREN) is checked against the pad: the
-- procedural buildings still in the model at this point are archived by Layout.Apply.
function Layout.ValidateRing(model, opts)
	local key = opts.key
	local G, floorTop = opts.groundY, opts.floorTopY
	local function fail(fmt, ...)
		error(string.format("%s: " .. fmt, key, ...), 2)
	end

	-- VillainPost
	local post = model:FindFirstChild("VillainPost")
	if not (post and post:IsA("BasePart")) then
		fail("no VillainPost")
	end
	local pp = post.CFrame.Position
	if not (post.Size == Vector3.new(1, 1, 1) and post.Transparency >= 1 and post.Anchored and not post.CanCollide and not post.CanQuery and not post.CanTouch) then
		fail("VillainPost must be an invisible anchored non-collidable 1x1x1 Part")
	end
	if math.abs(pp.Y - floorTop) > 0.1 then
		fail("VillainPost Y %.3f is not on the floor (%.3f)", pp.Y, floorTop)
	end
	local mid = (opts.x0 + opts.x1) / 2
	if math.abs(pp.X - mid) > 1 then
		fail("VillainPost X %.1f is not the middle of the stage (%.1f)", pp.X, mid)
	end
	if math.abs(math.abs(pp.Z) - Layout.POST_ABS_Z) > Layout.POST_Z_TOLERANCE then
		fail("VillainPost |Z| %.1f is not ~%d", math.abs(pp.Z), Layout.POST_ABS_Z)
	end
	local expectSide = (opts.number % 2 == 1) and 1 or -1
	if (pp.Z > 0 and 1 or -1) ~= expectSide then
		fail("VillainPost is on the wrong side (stage %d alternates to %s)", opts.number, expectSide > 0 and "+Z" or "-Z")
	end
	if post.CFrame.LookVector.X > -0.99 then
		fail("VillainPost must face -X (LookVector %s)", tostring(post.CFrame.LookVector))
	end
	local side = expectSide
	local pad = squareFootprint(pp.X, pp.Z, Layout.POST_PAD / 2, Layout.POST_PAD / 2)

	-- EggSpots
	local folder = model:FindFirstChild("EggSpots")
	if not folder then
		fail("no EggSpots folder")
	end
	local spots = {}
	for _, c in ipairs(folder:GetChildren()) do
		local n = tonumber(string.match(c.Name, "^EggSpot_(%d+)$"))
		if not (n and c:IsA("BasePart")) then
			fail("unexpected %s in EggSpots", c.Name)
		end
		spots[n] = c
	end
	if #spots ~= opts.count then
		fail("%d EggSpots (need %d, numbered 1..%d)", #spots, opts.count, opts.count)
	end
	local hidden, minDist, maxDist, minGap = 0, math.huge, 0, math.huge
	local angles = {}
	for n, s in ipairs(spots) do
		local p = s.CFrame.Position
		if not (s.Size == Vector3.new(1, 1, 1) and s.Transparency >= 1 and s.Anchored and not s.CanCollide and not s.CanQuery and not s.CanTouch) then
			fail("EggSpot_%d must be an invisible anchored non-collidable 1x1x1 Part", n)
		end
		if s.CFrame.UpVector.Y < 0.999 then
			fail("EggSpot_%d is not upright", n)
		end
		if math.abs(p.Y - floorTop) > 0.05 or p.Y < G - 0.01 then
			fail("EggSpot_%d Y %.3f does not rest on the floor (%.3f)", n, p.Y, floorTop)
		end
		local dist = math.sqrt((p.X - pp.X) ^ 2 + (p.Z - pp.Z) ^ 2)
		if dist < Layout.RING_MIN or dist > Layout.RING_MAX then
			fail("EggSpot_%d is %.1f studs from the VillainPost (%d-%d)", n, dist, Layout.RING_MIN, Layout.RING_MAX)
		end
		minDist, maxDist = math.min(minDist, dist), math.max(maxDist, dist)
		if math.abs(p.Z) < Layout.SPOT_MIN_ABS_Z or math.abs(p.Z) > Layout.SPOT_MAX_ABS_Z then
			fail("EggSpot_%d |Z| %.1f is outside %d..%d", n, math.abs(p.Z), Layout.SPOT_MIN_ABS_Z, Layout.SPOT_MAX_ABS_Z)
		end
		if p.X < opts.x0 + 2 or p.X > opts.x1 - 2 or (opts.minSpotX and p.X < opts.minSpotX) then
			fail("EggSpot_%d X %.1f is outside the stage X range", n, p.X)
		end
		if opts.bounds then
			local b = opts.bounds
			local rel = b.CFrame:PointToObjectSpace(Vector3.new(p.X, b.CFrame.Position.Y, p.Z))
			if math.abs(rel.X) > b.Size.X / 2 - 1 or math.abs(rel.Z) > b.Size.Z / 2 - 1 then
				fail("EggSpot_%d is outside the zone Bounds", n)
			end
		end
		for m = n + 1, #spots do
			local q = spots[m].CFrame.Position
			local gap = (p - q).Magnitude
			minGap = math.min(minGap, gap)
			if gap < Layout.SPOT_MIN_GAP then
				fail("EggSpot_%d and EggSpot_%d are %.1f apart", n, m, gap)
			end
		end
		-- horseshoe opening: angle between (post -> spot) and (post -> street)
		local dx, dz = (p.X - pp.X) / dist, (p.Z - pp.Z) / dist
		local toStreet = math.deg(math.acos(math.clamp(dx * 0 + dz * -side, -1, 1)))
		if toStreet < Layout.OPENING_MIN_DEG then
			fail("EggSpot_%d closes the horseshoe (only %.0f deg from the street direction)", n, toStreet)
		end
		table.insert(angles, math.deg(math.atan2(dx, dz * side))) -- 0 = away from the street, +-180 = street
		if s:GetAttribute("Hidden") == true then
			hidden += 1
		end
	end
	if hidden * 2 < #spots then
		fail("only %d of %d EggSpots are hidden (>= 50%% required)", hidden, #spots)
	end
	table.sort(angles)
	local widest, widestMid = 360 - (angles[#angles] - angles[1]), 180 -- the wrap-around gap straddles +-180 (street)
	for i = 2, #angles do
		local gap = angles[i] - angles[i - 1]
		if gap > widest then
			widest, widestMid = gap, (angles[i] + angles[i - 1]) / 2
		end
	end
	if widestMid ~= 180 then
		fail("the horseshoe's opening (widest gap %.0f deg) does not face the street", widest)
	end

	-- EggCover rocks
	local cover = model:FindFirstChild("EggCover")
	if not cover then
		fail("no EggCover folder")
	end
	local clusters = {} -- spot name -> { footprints }
	local rockCount = 0
	for _, d in ipairs(cover:GetDescendants()) do
		if d:IsA("BasePart") then
			rockCount += 1
			local name = d:GetFullName()
			if d.Material ~= Enum.Material.Slate then
				fail("%s must be Slate", name)
			end
			if not (d.Anchored and d.CanCollide) then
				fail("%s must be anchored and collidable", name)
			end
			if d.CFrame.UpVector.Y < 0.999 then
				fail("%s must be upright", name)
			end
			local top = d.CFrame.Position.Y + d.Size.Y / 2
			if top - floorTop > Layout.ROCK_MAX_HEIGHT then
				fail("%s is %.2f studs tall over the floor (max %.1f)", name, top - floorTop, Layout.ROCK_MAX_HEIGHT)
			end
			local f = footprint(d)
			if footprintGap(f, pad) <= 0 then
				fail("%s is on the villain's 20x20 pad", name)
			end
			local z0, z1 = project(f, { 0, 1 })
			local x0, x1 = project(f, { 1, 0 })
			if not (z0 > Layout.STREET_HALF_WIDTH or z1 < -Layout.STREET_HALF_WIDTH) then
				fail("%s reaches into the main street (Z %.1f..%.1f)", name, z0, z1)
			end
			if x0 < opts.x0 + 1 or x1 > opts.x1 - 1 then
				fail("%s leaves the stage X range", name)
			end
			local owner = d:GetAttribute("EggSpot")
			local list = clusters[owner]
			if not list then
				list = { bottom = math.huge }
				clusters[owner] = list
			end
			table.insert(list, f)
			list.bottom = math.min(list.bottom, d.CFrame.Position.Y - d.Size.Y / 2)
		elseif not d:IsA("Folder") and not d:IsA("Model") then
			fail("unexpected %s in EggCover", d:GetFullName())
		end
	end
	for owner, list in pairs(clusters) do
		local n = tonumber(string.match(tostring(owner), "^EggSpot_(%d+)$"))
		if not (n and spots[n] and spots[n]:GetAttribute("Hidden") == true) then
			fail("cover rock assigned to %s, which is not a hidden EggSpot", tostring(owner))
		end
		if list.bottom > G + 0.05 then
			fail("cover rock of %s floats (bottom %.2f)", owner, list.bottom)
		end
	end
	for n, s in ipairs(spots) do
		local p = s.CFrame.Position
		local isHidden = s:GetAttribute("Hidden") == true
		local eggRadius = isHidden and Layout.HIDDEN_NEST_RADIUS or Layout.OPEN_NEST_RADIUS
		local own = clusters[s.Name]
		if isHidden then
			if not own then
				fail("hidden EggSpot_%d has no cover rock", n)
			end
			-- the rock hides the egg from the villain: sight lines from the post to the egg's centre and both edges cross it
			local dist = math.sqrt((p.X - pp.X) ^ 2 + (p.Z - pp.Z) ^ 2)
			local ux, uz = (p.X - pp.X) / dist, (p.Z - pp.Z) / dist
			for _, off in ipairs({ -eggRadius, 0, eggRadius }) do
				local ex, ez = p.X - uz * off, p.Z + ux * off
				local blocked = false
				for step = 0, 100 do
					local t = step / 100
					local x, z = pp.X + (ex - pp.X) * t, pp.Z + (ez - pp.Z) * t
					for _, f in ipairs(own) do
						if pointInFootprint(f, x, z, 0) then
							blocked = true
							break
						end
					end
					if blocked then
						break
					end
				end
				if not blocked then
					fail("the cover rock of EggSpot_%d does not hide it from the villain", n)
				end
			end
			-- walkable access: the outer side and both tangential sides of the egg stay free
			for _, dir in ipairs({ { ux, uz }, { -uz, ux }, { uz, -ux } }) do
				local ax, az = p.X + dir[1] * (eggRadius + 1), p.Z + dir[2] * (eggRadius + 1)
				for _, list in pairs(clusters) do
					for _, f in ipairs(list) do
						if pointInFootprint(f, ax, az, 0.3) then
							fail("a cover rock blocks the approach to EggSpot_%d", n)
						end
					end
				end
			end
		elseif own then
			fail("open EggSpot_%d has a cover rock", n)
		end
		for owner, list in pairs(clusters) do
			local need = eggRadius + (owner == s.Name and Layout.ROCK_EGG_CLEARANCE or Layout.ROCK_OTHER_EGG_CLEARANCE)
			for _, f in ipairs(list) do
				local dist = pointFootprintDistance(f, p.X, p.Z)
				if dist < need then
					fail("cover rock of %s is %.2f studs from the centre of EggSpot_%d (needs %.1f)", owner, dist, n, need)
				end
			end
		end
	end
	local owners = {}
	for owner in pairs(clusters) do
		table.insert(owners, owner)
	end
	local minRoute = math.huge
	for i = 1, #owners do
		for j = i + 1, #owners do
			for _, a in ipairs(clusters[owners[i]]) do
				for _, b in ipairs(clusters[owners[j]]) do
					minRoute = math.min(minRoute, footprintGap(a, b))
				end
			end
		end
	end
	if #owners > 1 and minRoute < Layout.ROCK_ROUTE_WIDTH then
		fail("cover rocks leave only a %.1f-stud walkway (>= %d)", minRoute, Layout.ROCK_ROUTE_WIDTH)
	end

	-- the villain pad: nothing collidable of the kept content up to POST_CLEAR_HEIGHT
	for name in pairs(Layout.KEEP_CHILDREN) do
		local child = model:FindFirstChild(name)
		local list = child and (child:IsA("BasePart") and { child } or child:GetDescendants()) or {}
		for _, d in ipairs(list) do
			if d:IsA("BasePart") and d.CanCollide then
				local half = Layout.POST_PAD / 2
				local mn, mx = worldAABB(d)
				if mn.X < pp.X + half and mx.X > pp.X - half and mn.Z < pp.Z + half and mx.Z > pp.Z - half
					and mn.Y < floorTop + Layout.POST_CLEAR_HEIGHT and mx.Y > floorTop + 0.05 then
					fail("%s is on the villain pad", d:GetFullName())
				end
			end
		end
	end

	return {
		hidden = hidden,
		rocks = rockCount,
		minDist = minDist,
		maxDist = maxDist,
		minGap = minGap,
		minRoute = minRoute,
		opening = widest,
		post = { x = pp.X, z = pp.Z },
	}
end

---------------------------------------------------------------------------------------------------
-- D8 archive (post step)
---------------------------------------------------------------------------------------------------

local function countParts(inst)
	local n = inst:IsA("BasePart") and 1 or 0
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

local STAGE_ORDER = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }

function Layout.Apply(place, spPlace, ctx)
	ctx = ctx or {}
	local ws = place.Workspace
	local rs = place:GetService("ReplicatedStorage")
	local baseplate = ctx.baseplate or ws:FindFirstChild("Baseplate")
	local groundY = ctx.groundY or (baseplate and baseplate.CFrame.Position.Y + baseplate.Size.Y / 2)
	assert(type(groundY) == "number", "post_scratch_layout: groundY unavailable")
	local floorTop = Layout.FloorTopY(ws, groundY)

	local envRoot = ws:FindFirstChild(Layout.ENV_FOLDER)
	assert(envRoot, "post_scratch_layout: Workspace." .. Layout.ENV_FOLDER .. " missing (env steps not run?)")

	local archive = rs:FindFirstChild(Layout.ARCHIVE_NAME)
	if not archive then
		archive = Instance.new("Folder")
		archive.Name = Layout.ARCHIVE_NAME
		archive.Parent = rs
	end
	archive:SetAttribute("Note", "Procedural stage buildings/props archived by the scratch layout (D8). Drag a group back into Workspace.StageEnvironments.<Key> to restore it; CFrames are world positions.")
	archive:SetAttribute("ArchivedBy", "scripts/steps/post_scratch_layout.luau")

	local summary = {}
	local warnings = 0
	local function warnf(fmt, ...)
		warnings += 1
		print(string.format("%s WARNING: " .. fmt, LOG_PREFIX, ...))
	end

	for _, stageModel in ipairs(envRoot:GetChildren()) do
		if Layout.KEEP_MODELS[stageModel.Name] then
			continue
		end
		if not stageModel:IsA("Model") then
			warnf("Workspace.%s.%s is not a stage model; left in place", Layout.ENV_FOLDER, stageModel.Name)
			continue
		end
		local toMove = {}
		for _, child in ipairs(stageModel:GetChildren()) do
			if not Layout.KEEP_CHILDREN[child.Name] then
				table.insert(toMove, child)
			end
		end
		if #toMove == 0 then
			table.insert(summary, string.format("%s nothing to archive", stageModel.Name))
			continue
		end
		local old = archive:FindFirstChild(stageModel.Name)
		while old do
			old:Destroy()
			old = archive:FindFirstChild(stageModel.Name)
		end
		local dest = Instance.new("Model")
		dest.Name = stageModel.Name
		for attr, value in pairs(stageModel:GetAttributes()) do
			dest:SetAttribute(attr, value)
		end
		dest:SetAttribute("ArchivedFrom", string.format("Workspace.%s.%s", Layout.ENV_FOLDER, stageModel.Name))
		pcall(function()
			(dest :: any).WorldPivotData = (stageModel :: any).WorldPivotData
		end)
		local moved, hazards = 0, 0
		for _, child in ipairs(toMove) do
			moved += countParts(child)
			for _, d in ipairs(child:IsA("BasePart") and { child } or child:GetDescendants()) do
				if d:IsA("BasePart") and d:GetAttribute("StageHazard") ~= nil then
					hazards += 1
				end
			end
			child.Parent = dest
		end
		dest:SetAttribute("PartCount", moved)
		dest.Parent = archive
		stageModel:SetAttribute("ScratchLayout", true)
		stageModel:SetAttribute("ArchivedTo", string.format("ReplicatedStorage.%s.%s", Layout.ARCHIVE_NAME, stageModel.Name))
		if stageModel:GetAttribute("PartCount") ~= nil then
			stageModel:SetAttribute("PartCount", countParts(stageModel))
		end
		table.insert(summary, string.format("%s %d groups (%d parts, %d hazards) archived, kept %d parts", stageModel.Name, #toMove, moved, hazards, countParts(stageModel)))
	end

	-- Own result (errors): only the kept children remain, the ring content is intact, no hazard is left.
	for _, key in ipairs(STAGE_ORDER) do
		local m = envRoot:FindFirstChild(key)
		assert(m, string.format("post_scratch_layout: Workspace.%s.%s missing", Layout.ENV_FOLDER, key))
		for _, child in ipairs(m:GetChildren()) do
			assert(Layout.KEEP_CHILDREN[child.Name], string.format("post_scratch_layout: %s still holds %s", key, child.Name))
		end
		assert(m:FindFirstChild("VillainPost") and m:FindFirstChild("EggSpots") and m:FindFirstChild("EggCover"),
			string.format("post_scratch_layout: %s lost its VillainPost / EggSpots / EggCover", key))
		assert(archive:FindFirstChild(key), string.format("post_scratch_layout: archive of %s missing", key))
	end
	for _, d in ipairs(envRoot:GetDescendants()) do
		assert(not (d:IsA("BasePart") and d:GetAttribute("StageHazard") ~= nil), "post_scratch_layout: hazard left in the Workspace: " .. d:GetFullName())
	end

	-- World checks. Street: nothing collidable in |Z| <= 15 below STREET_CLEAR_HEIGHT over the stages. Pads: nothing
	-- collidable but the villain itself on its 20x20 pad up to POST_CLEAR_HEIGHT. Own parts -> error, others -> warning.
	local guardAreas = ws:FindFirstChild("__OBJECTS") and ws.__OBJECTS:FindFirstChild("Areas") and ws.__OBJECTS.Areas:FindFirstChild("GuardAreas")
	local pads = {}
	for _, key in ipairs(STAGE_ORDER) do
		local post = envRoot[key]:FindFirstChild("VillainPost")
		local zone = guardAreas and guardAreas:FindFirstChild(key)
		table.insert(pads, { key = key, p = post.CFrame.Position, guard = zone and zone:FindFirstChild("Guard") })
	end
	local streetHits, padHits = {}, {}
	for _, d in ipairs(ws:GetDescendants()) do
		if d:IsA("BasePart") and d.CanCollide and d ~= baseplate and d.Name ~= "Terrain" then
			local mn, mx = worldAABB(d)
			local own = d:IsDescendantOf(envRoot)
			if mx.X > Layout.STREET_X0 and mn.X < Layout.STREET_X1 and mn.Z < Layout.STREET_HALF_WIDTH and mx.Z > -Layout.STREET_HALF_WIDTH
				and mn.Y < floorTop + Layout.STREET_CLEAR_HEIGHT and mx.Y > floorTop + 0.05 then
				assert(not own, "post_scratch_layout: collidable " .. d:GetFullName() .. " is in the main street")
				table.insert(streetHits, d:GetFullName())
			end
			for _, pad in ipairs(pads) do
				local half = Layout.POST_PAD / 2
				if not (pad.guard and d:IsDescendantOf(pad.guard))
					and mn.X < pad.p.X + half and mx.X > pad.p.X - half and mn.Z < pad.p.Z + half and mx.Z > pad.p.Z - half
					and mn.Y < floorTop + Layout.POST_CLEAR_HEIGHT and mx.Y > floorTop + 0.05 then
					assert(not own, "post_scratch_layout: collidable " .. d:GetFullName() .. " is on the " .. pad.key .. " villain pad")
					table.insert(padHits, pad.key .. ": " .. d:GetFullName())
				end
			end
		end
	end
	if #streetHits > 0 then
		warnf("%d collidable part(s) in the main street: %s", #streetHits, table.concat(streetHits, ", ", 1, math.min(#streetHits, 6)))
	end
	if #padHits > 0 then
		warnf("%d collidable part(s) on villain pads: %s", #padHits, table.concat(padHits, ", ", 1, math.min(#padHits, 6)))
	end

	-- The nests of stages.luau sit on the ring markers (warning only: stages.luau is a separate step).
	for _, key in ipairs(STAGE_ORDER) do
		local markers = envRoot[key].EggSpots:GetChildren()
		local zone = guardAreas and guardAreas:FindFirstChild(key)
		local nests = zone and zone:FindFirstChild("Nests")
		local matched, total = 0, 0
		for _, nest in ipairs(nests and nests:GetChildren() or {}) do
			local root = nest:IsA("Model") and (nest.PrimaryPart or nest:FindFirstChild("Root"))
			if root and root:IsA("BasePart") then
				total += 1
				local rp = root.CFrame.Position
				for _, marker in ipairs(markers) do
					local mp = marker.CFrame.Position
					if math.abs(mp.X - rp.X) < 0.05 and math.abs(mp.Z - rp.Z) < 0.05 and math.abs(mp.Y - rp.Y) < 0.05 then
						matched += 1
						break
					end
				end
			end
		end
		if matched ~= #markers or total ~= #markers then
			warnf("%s: %d of %d nests sit on the %d ring markers", key, matched, total, #markers)
		end
	end

	print(string.format("%s Scratch layout: %s. Kept per stage: EggSpots, VillainPost, EggCover, Boundary%s; EndWall kept whole. %d warning(s).",
		LOG_PREFIX, table.concat(summary, "; "), envRoot:FindFirstChild("Lake") and envRoot.Lake:FindFirstChild("Rain") and ", Rain (stage 2)" or "", warnings))
end

return Layout
