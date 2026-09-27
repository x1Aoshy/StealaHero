--!nocheck
-- scripts/steps/post_zzzzz_scenery.luau (owner 2026-09-27: "add trees after shrinking the map: fill awkward / empty
-- corners with trees, make the map feel cleaner and less empty; little rocks, whatever, outside the main map and inside
-- so it does not feel so empty")
-- Low-poly toy scenery in Workspace.Scenery, placed deterministically (seeded) where it cannot get in the way:
--   * OUTSIDE the walls (the green all around the hub and the stage lane): woods of three tree kinds (round, pine,
--     blocky) and rock clusters in a band up to OUTSIDE_BAND studs from the walls, denser near them so the skyline over
--     the walls reads as a forest;
--   * INSIDE the hub: smaller trees, bushes and pebbles in the empty corners and along the walls;
--   * INSIDE the stages: pebble clusters tinted to each stage's floor, hugging the side walls.
-- Every spot is checked against the built world (the occupancy of every part above floor level, plus a clearance) and
-- kept off the main street, the spawn and the lane mouths. Trunks inside the hub collide (the canopies do not); every
-- other scenery part is non-colliding, and no scenery part takes touch / query, so nothing blocks a path or a raycast.
-- Pebbles and rocks cast no shadow. Runs after the owner layout and the NPC collider pass. Idempotent (Scenery is
-- rebuilt).

local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local Step = {}

Step.SEED = 20260927
Step.GROUND_Y = 2.05
Step.OUTSIDE_BAND = 240
Step.CELL = 8

-- world footprint (hub + stage lane), from the world walls (outer faces)
Step.HUB = { x0 = -109, x1 = 80, z0 = -221, z1 = 226 }
Step.LANE = { x0 = 80, x1 = 1480, z0 = -96, z1 = 94 }

local GREENS = {
	Color3.fromRGB(76, 168, 52), Color3.fromRGB(98, 190, 62), Color3.fromRGB(58, 142, 44), Color3.fromRGB(122, 200, 70),
}
local PINE_GREENS = { Color3.fromRGB(38, 110, 60), Color3.fromRGB(46, 128, 68), Color3.fromRGB(30, 96, 54) }
local TRUNK = Color3.fromRGB(112, 74, 42)
local ROCK_GREYS = { Color3.fromRGB(140, 140, 146), Color3.fromRGB(116, 118, 126), Color3.fromRGB(160, 158, 150) }
-- stage floor tints for the pebbles (by GuardAreas / stage key)
local STAGE_PEBBLES = {
	Forest = { Color3.fromRGB(96, 104, 120), Color3.fromRGB(70, 78, 94) },
	Lake = { Color3.fromRGB(90, 96, 110), Color3.fromRGB(60, 64, 78) },
	Desert = { Color3.fromRGB(120, 92, 118), Color3.fromRGB(88, 70, 96) },
	Jungle = { Color3.fromRGB(96, 132, 84), Color3.fromRGB(70, 104, 64) },
	Snow = { Color3.fromRGB(226, 236, 246), Color3.fromRGB(190, 206, 222) },
	Volcano = { Color3.fromRGB(70, 60, 58), Color3.fromRGB(150, 70, 40) },
}

-- deterministic RNG (LCG)
local state = Step.SEED
local function rand()
	state = (state * 1103515245 + 12345) % 2147483648
	return state / 2147483648
end
local function range(a, b)
	return a + (b - a) * rand()
end
local function pick(list)
	return list[math.floor(rand() * #list) + 1]
end

---------------------------------------------------------------------------------------------------
-- occupancy: every part above floor level, hashed into CELL-stud cells (AABB + clearance)
---------------------------------------------------------------------------------------------------
local function aabb(p)
	local cf, s = p.CFrame, p.Size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local ex = math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z
	local ey = math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z
	local ez = math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
	local c = cf.Position
	return c.X - ex, c.Y - ey, c.Z - ez, c.X + ex, c.Y + ey, c.Z + ez
end

local function buildOccupancy(ws)
	local cells = {}
	local function mark(x0, z0, x1, z1)
		for cx = math.floor(x0 / Step.CELL), math.floor(x1 / Step.CELL) do
			for cz = math.floor(z0 / Step.CELL), math.floor(z1 / Step.CELL) do
				cells[cx * 100000 + cz] = true
			end
		end
	end
	for _, d in ipairs(ws:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Baseplate" and not d:IsA("Terrain") then
			local x0, _, z0, x1, y1, z1 = aabb(d)
			-- floors / flat ground tiles (top within half a stud of the ground) do not block; huge volumes (the invisible
			-- night-wall collision, zone volumes) are not scenery obstacles either
			if y1 > Step.GROUND_Y + 0.5 and (x1 - x0) < 600 and (z1 - z0) < 900 then
				mark(x0, z0, x1, z1)
			end
		end
	end
	return cells
end

local function free(cells, x, z, radius)
	for cx = math.floor((x - radius) / Step.CELL), math.floor((x + radius) / Step.CELL) do
		for cz = math.floor((z - radius) / Step.CELL), math.floor((z + radius) / Step.CELL) do
			if cells[cx * 100000 + cz] then
				return false
			end
		end
	end
	return true
end

local function claim(cells, x, z, radius)
	for cx = math.floor((x - radius) / Step.CELL), math.floor((x + radius) / Step.CELL) do
		for cz = math.floor((z - radius) / Step.CELL), math.floor((z + radius) / Step.CELL) do
			cells[cx * 100000 + cz] = true
		end
	end
end

local function inside(rect, x, z, pad)
	return x > rect.x0 - pad and x < rect.x1 + pad and z > rect.z0 - pad and z < rect.z1 + pad
end

-- distance from (x, z) to the world footprint (0 inside)
local function distanceToWorld(x, z)
	local function rectDist(r)
		local dx = math.max(r.x0 - x, 0, x - r.x1)
		local dz = math.max(r.z0 - z, 0, z - r.z1)
		return math.sqrt(dx * dx + dz * dz)
	end
	return math.min(rectDist(Step.HUB), rectDist(Step.LANE))
end

---------------------------------------------------------------------------------------------------
-- builders
---------------------------------------------------------------------------------------------------
local function part(parent, name, shape, size, cframe, color, material, opts)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = opts and opts.collide or false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = not (opts and opts.noShadow)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function model(parent, name, x, z)
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Scenery", true)
	m.WorldPivotData = CFrame.new(x, Step.GROUND_Y, z)
	m.Parent = parent
	return m
end

local UP = CFrame.Angles(0, 0, math.pi / 2) -- a Cylinder's axis is X: stand it up

local function trunk(m, x, z, height, width, collide)
	part(m, "Trunk", Enum.PartType.Cylinder, Vector3.new(height, width, width),
		CFrame.new(x, Step.GROUND_Y + height / 2, z) * UP, TRUNK, Enum.Material.Wood, { collide = collide })
end

local function roundTree(parent, x, z, s, collide)
	local m = model(parent, "RoundTree", x, z)
	local h = 7 * s
	trunk(m, x, z, h + 2 * s, 1.5 * s, collide)
	local g = pick(GREENS)
	part(m, "Canopy", Enum.PartType.Ball, Vector3.one * 9 * s, CFrame.new(x, Step.GROUND_Y + h + 3 * s, z), g, Enum.Material.SmoothPlastic)
	part(m, "Canopy", Enum.PartType.Ball, Vector3.one * 6.5 * s, CFrame.new(x + 3.2 * s, Step.GROUND_Y + h + 1.5 * s, z - 1.5 * s),
		g:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.SmoothPlastic)
	part(m, "Canopy", Enum.PartType.Ball, Vector3.one * 5.5 * s, CFrame.new(x - 2.8 * s, Step.GROUND_Y + h + 5.5 * s, z + 1.8 * s),
		g:Lerp(Color3.new(0, 0, 0), 0.08), Enum.Material.SmoothPlastic)
	return m
end

local function pineTree(parent, x, z, s, collide)
	local m = model(parent, "PineTree", x, z)
	local h = 4 * s
	trunk(m, x, z, h + 1, 1.3 * s, collide)
	local g = pick(PINE_GREENS)
	local yaw = range(0, math.pi / 2)
	local y = Step.GROUND_Y + h
	for i, w in ipairs({ 9, 7, 5, 3 }) do
		local tier = 3.2 * s
		part(m, "Tier" .. i, Enum.PartType.Block, Vector3.new(w * s, tier, w * s),
			CFrame.new(x, y + tier / 2, z) * CFrame.Angles(0, yaw + i * math.rad(22), 0), g:Lerp(Color3.new(1, 1, 1), i * 0.04),
			Enum.Material.SmoothPlastic)
		y += tier * 0.82
	end
	return m
end

local function blockyTree(parent, x, z, s, collide)
	local m = model(parent, "BlockyTree", x, z)
	local h = 6 * s
	part(m, "Trunk", Enum.PartType.Block, Vector3.new(1.6 * s, h + 2 * s, 1.6 * s), CFrame.new(x, Step.GROUND_Y + (h + 2 * s) / 2, z), TRUNK,
		Enum.Material.Wood, { collide = collide })
	local g = pick(GREENS)
	local yaw = range(0, math.pi / 2)
	part(m, "Canopy", Enum.PartType.Block, Vector3.new(8 * s, 6 * s, 8 * s), CFrame.new(x, Step.GROUND_Y + h + 3 * s, z) * CFrame.Angles(0, yaw, 0),
		g, Enum.Material.SmoothPlastic)
	part(m, "Canopy", Enum.PartType.Block, Vector3.new(5.5 * s, 4 * s, 5.5 * s),
		CFrame.new(x + 1 * s, Step.GROUND_Y + h + 7 * s, z - 0.8 * s) * CFrame.Angles(0, yaw + math.rad(35), 0), g:Lerp(Color3.new(1, 1, 1), 0.1),
		Enum.Material.SmoothPlastic)
	return m
end

local function rock(parent, x, z, s, colors)
	local m = model(parent, "Rock", x, z)
	local n = if s > 1.5 then 3 else 2
	for i = 1, n do
		local size = Vector3.new(range(1.4, 2.4) * s, range(0.9, 1.6) * s, range(1.2, 2.2) * s)
		local ox, oz = range(-0.7, 0.7) * s, range(-0.7, 0.7) * s
		part(m, "Stone" .. i, Enum.PartType.Block, size,
			CFrame.new(x + ox, Step.GROUND_Y + size.Y * 0.3, z + oz) * CFrame.Angles(range(-0.25, 0.25), range(0, math.pi), range(-0.25, 0.25)),
			pick(colors or ROCK_GREYS), Enum.Material.Slate, { noShadow = s < 1.2 })
	end
	return m
end

local function bush(parent, x, z, s)
	local m = model(parent, "Bush", x, z)
	local g = pick(GREENS)
	part(m, "Leaves", Enum.PartType.Ball, Vector3.one * 3 * s, CFrame.new(x, Step.GROUND_Y + 1.1 * s, z), g, Enum.Material.SmoothPlastic)
	part(m, "Leaves", Enum.PartType.Ball, Vector3.one * 2.3 * s, CFrame.new(x + 1.4 * s, Step.GROUND_Y + 0.9 * s, z + 0.6 * s),
		g:Lerp(Color3.new(1, 1, 1), 0.1), Enum.Material.SmoothPlastic)
	return m
end

local TREES = { roundTree, pineTree, blockyTree }

---------------------------------------------------------------------------------------------------
-- placement
---------------------------------------------------------------------------------------------------
local function scatter(cells, count, tries, sampler, radius, place)
	local placed = 0
	for _ = 1, tries do
		if placed >= count then
			break
		end
		local x, z = sampler()
		if x and free(cells, x, z, radius) then
			claim(cells, x, z, radius)
			place(x, z)
			placed += 1
		end
	end
	return placed
end

function Step.Apply(place, _spPlace, _ctx)
	state = Step.SEED
	local ws = place:GetService("Workspace")
	local old = ws:FindFirstChild("Scenery")
	if old then
		old:Destroy()
	end
	local cells = buildOccupancy(ws)
	local root = Instance.new("Folder")
	root.Name = "Scenery"
	root.Parent = ws
	local outside = Instance.new("Folder")
	outside.Name = "Outside"
	outside.Parent = root
	local hub = Instance.new("Folder")
	hub.Name = "Hub"
	hub.Parent = root
	local stages = Instance.new("Folder")
	stages.Name = "Stages"
	stages.Parent = root

	local spawn = ws:FindFirstChild("SpawnLocation")
	local spawnPos = spawn and spawn.CFrame.Position or Vector3.new(37, 2, 0)

	-- OUTSIDE: a band around the footprint, denser near the walls
	local function outsideSample()
		local x = range(Step.HUB.x0 - Step.OUTSIDE_BAND, Step.LANE.x1 + Step.OUTSIDE_BAND)
		local z = range(Step.HUB.z0 - Step.OUTSIDE_BAND, Step.HUB.z1 + Step.OUTSIDE_BAND)
		local d = distanceToWorld(x, z)
		if d < 14 or d > Step.OUTSIDE_BAND then
			return nil
		end
		-- keep a thinning with distance (more trees hugging the walls)
		if rand() > 1.15 - d / Step.OUTSIDE_BAND then
			return nil
		end
		return x, z
	end
	-- a dense border first (16-55 studs off the walls: the treeline seen over the walls from inside), then sparser woods
	-- further out, which cast no shadow (the shadow map stays small)
	local function ringSample()
		local x = range(Step.HUB.x0 - 60, Step.LANE.x1 + 60)
		local z = range(Step.HUB.z0 - 60, Step.HUB.z1 + 60)
		local d = distanceToWorld(x, z)
		if d < 16 or d > 55 then
			return nil
		end
		return x, z
	end
	local trees = scatter(cells, 230, 12000, ringSample, 7, function(x, z)
		pick(TREES)(outside, x, z, range(1, 1.6), false)
	end)
	trees += scatter(cells, 140, 9000, outsideSample, 9, function(x, z)
		local tree = pick(TREES)(outside, x, z, range(0.9, 1.7), false)
		if distanceToWorld(x, z) > 60 then
			for _, d in ipairs(tree:GetDescendants()) do
				if d:IsA("BasePart") then
					d.CastShadow = false
				end
			end
		end
	end)
	local rocks = scatter(cells, 110, 6000, outsideSample, 5, function(x, z)
		rock(outside, x, z, range(1.2, 3.2))
	end)

	-- INSIDE THE HUB: corners and edges, never on the street / spawn / mouths
	local function hubSample(maxWall)
		return function()
			local x = range(Step.HUB.x0 + 12, Step.HUB.x1 - 14)
			local z = range(Step.HUB.z0 + 12, Step.HUB.z1 - 12)
			local wallDist = math.min(x - Step.HUB.x0, Step.HUB.x1 - x, z - Step.HUB.z0, Step.HUB.z1 - z)
			if wallDist > maxWall then
				return nil
			end
			if math.abs(z) < 24 and x > -60 then
				return nil -- the main street from the spawn to the lane
			end
			local dx, dz = x - spawnPos.X, z - spawnPos.Z
			if dx * dx + dz * dz < 35 * 35 then
				return nil
			end
			if x > Step.HUB.x1 - 30 and z > -100 and z < 100 then
				return nil -- the lane mouth
			end
			return x, z
		end
	end
	local hubTrees = scatter(cells, 18, 4000, hubSample(26), 8, function(x, z)
		local kind = pick({ roundTree, blockyTree, pineTree })
		kind(hub, x, z, range(0.6, 0.85), true)
	end)
	local hubBushes = scatter(cells, 26, 4000, hubSample(34), 3.5, function(x, z)
		bush(hub, x, z, range(0.8, 1.2))
	end)
	local hubPebbles = scatter(cells, 40, 5000, hubSample(40), 2, function(x, z)
		rock(hub, x, z, range(0.5, 0.9))
	end)

	-- INSIDE THE STAGES: pebbles along the side walls, tinted to each stage
	local stageCount = 0
	local walls = ws:FindFirstChild("WorldWalls")
	for key, colors in pairs(STAGE_PEBBLES) do
		local south = walls and walls:FindFirstChild(key) and walls[key]:FindFirstChild("StageWall_" .. key .. "_South")
		if south and south:IsA("BasePart") then
			local x0, _, _, x1 = aabb(south)
			local folder = Instance.new("Folder")
			folder.Name = key
			folder.Parent = stages
			local n = scatter(cells, math.floor((x1 - x0) / 9), 2000, function()
				local x = range(x0 + 6, x1 - 6)
				local side = if rand() < 0.5 then -1 else 1
				local z = if side < 0 then range(-85, -79) else range(77, 83)
				return x, z
			end, 1.5, function(x, z)
				rock(folder, x, z, range(0.5, 1.1), colors)
			end)
			stageCount += n
		end
	end

	local parts = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	print(string.format(
		"[post_zzzzz_scenery] outside: %d trees, %d rocks; hub: %d trees, %d bushes, %d pebbles; stages: %d pebbles (%d parts)",
		trees, rocks, hubTrees, hubBushes, hubPebbles, stageCount, parts))
end

return Step
