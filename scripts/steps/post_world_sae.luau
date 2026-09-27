-- scripts/steps/post_world_sae.luau
-- Build step (WORLD, owner "Gekko TO DO": "tambien mete los muros y el piso del steal an egg original pero basados en
-- nuestros stages tmb"): the Steal an Egg (SAE) boundary walls and grid floor, adapted to the 6 stages.
--
-- Reference: the owner pasted the original SAE pieces into assets/user_models/StealaHero_studio_save_20260923_2237.rbxl
-- (Workspace children "Part" x7 and "Baseplate" x2). Their look, read with Lune:
--   * walls: SmoothPlastic + MaterialVariant "2022 Stud", rgb(226,145,74), 8.56 thick, 36.935 tall with the bottom 0.7
--     under the floor, one Texture "Top" (rbxassetid://6905003203, white, 0.9 transparent, 8x8 studs) on a long face.
--     They enclose the lobby (inner faces X -100.6 / ~71.2, Z -212.03 / 216.97) and run along both sides of the lane,
--     open where the lobby meets the lane;
--   * floor: Plastic + MaterialVariant "Studs", rgb(105,208,20), GridTexture (rbxassetid://6372755229, black, 0.8, 8x8
--     studs) on top. The ground step (scripts/steps/ground.luau) already gives Workspace.Baseplate exactly this look, so
--     the hub and the plots keep it.
--
-- This step runs in the post_* pass (after env_a / env_b tinted the zone floors and after every other layout step):
--   1. Zone floors in the SAE look, tinted per stage: each Workspace.Ground.ZoneFloor_<Key> becomes Plastic + "Studs"
--      with one GridTexture on top. The colour stays the stage palette colour env_a / env_b gave it; on dark floors
--      (the city stages 1-3) the grid lines are white so they still read. The floors and the ZoneDivider strips are
--      stretched in Z to run under the side walls (no baseplate strip between floor and wall). Heights and the
--      visual-only flags do not change: the nests sit on the floor top and nothing new is coplanar with it.
--   2. Workspace.WorldWalls, SAE walls with the reference profile and texture (on both long faces):
--        Hub     West, North, South and the two East walls beside the lane mouth, in the SAE orange;
--        <Key>   North and South wall over the stage's X range, in a colour from the stage palette. Their inner faces
--                are flush with the invisible side walls (StageEnvironments.<Key>.Boundary / EndWall.SideWalls), so the
--                walkable lane and the villains' chase / return routes are exactly what they were.
--      The lane mouth (Z between the side walls: the street, the stage-1 gate, the safe-zone line) stays open, the stage
--      gates and the street run along the lane, never through a wall, and the lane walls end inside the Red Line wall.
--   3. Geometry check (errors on any violation): no wall box grown by CLEARANCE touches the main street corridor, the
--      lane corridor, the plots (pens, treadmills, spawn points, upgrade signs), the SpawnLocation, the Sell / Trails
--      stalls and pads, the leaderboards, the Free Gift corner, the stage gate areas, any GuardAreas zone content
--      (Bounds, nests, villains), the EggSpots, EggCover rocks and VillainPost pads; every hub object stands inside the
--      hub walls; nothing visible is coplanar with the stretched floor strips.
--
-- Lune notes: explicit axis-aligned CFrames only; Texture art through TextureContent (Content.fromUri); Instance.new
-- ignores its parent argument.
--
-- Idempotent: Workspace.WorldWalls is rebuilt from scratch and the floor restyle is absolute.

local roblox = require("@lune/roblox")
local Ground = require("./ground")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local rgb = Color3.fromRGB

local Step = {}

Step.FOLDER_NAME = "WorldWalls"
Step.REFERENCE = "assets/user_models/StealaHero_studio_save_20260923_2237.rbxl (Workspace Part x7 + Baseplate x2)"

-- SAE wall profile (reference walls)
Step.WALL_THICKNESS = 8.56
Step.WALL_HEIGHT = 36.935
Step.WALL_SINK = 0.7 -- the wall bottom sits this far under the floor (reference: 1.35 on a 2.05 floor)
Step.WALL_MATERIAL = Enum.Material.SmoothPlastic
Step.WALL_VARIANT = "2022 Stud"
Step.WALL_TEXTURE = {
	Name = "Top",
	Uri = "rbxassetid://6905003203",
	Color3 = rgb(255, 255, 255),
	Transparency = 0.9,
	StudsPerTile = 8,
}
Step.HUB_WALL_COLOR = rgb(226, 145, 74) -- the SAE orange

-- One signature colour per stage, taken from the stage palettes of env_a / env_b.
Step.STAGE_WALL_COLORS = {
	Forest = rgb(28, 58, 150), -- The Avengers: Captain America blue (env_a AV.capBlue)
	Lake = rgb(76, 72, 86), -- Justice League: Gotham stone (env_a JL.stoneMid)
	Desert = rgb(184, 64, 52), -- Spider-Verse: Queens brick (env_a SV.brickRed)
	Jungle = rgb(62, 140, 72), -- My Hero Academia: U.A. hedges (env_b C4.hedge)
	Snow = rgb(236, 128, 40), -- Dragon Ball: Capsule / Dragon Ball orange (env_b C5.roof)
	Volcano = rgb(160, 112, 68), -- One Piece: ship planks (env_b C6.plank)
}
Step.STAGE_ORDER = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }
-- Stage X ranges when neither the zone floor nor the stage model gives one (docs/STAGES_PLAN.md §1).
Step.FALLBACK_STAGE_X = {
	Forest = { 72, 170 }, Lake = { 170, 316 }, Desert = { 316, 526 },
	Jungle = { 526, 762 }, Snow = { 762, 1086 }, Volcano = { 1086, 1471 },
}

-- Hub enclosure: inner faces of the SAE lobby walls. They only ever move outward (to keep hub content inside).
Step.HUB_INNER = { West = -100.6, East = 71.2, North = 216.97, South = -212.03 }
-- Lane side walls: inner faces when no invisible side wall is found (env_a Step.WALL_NORTH_Z / WALL_SOUTH_Z - 1 / + 1).
Step.LANE_NORTH_Z = 85
Step.LANE_SOUTH_Z = -87
Step.LANE_END_PAST_FLOOR = 2 -- without a Red Line wall, the lane walls stop this far past the last zone floor

-- Floors: the SAE floor look (see Ground.GRID for the grid art and the light-floor grid)
Step.FLOOR_MATERIAL = Enum.Material.Plastic
Step.FLOOR_VARIANT = "Studs"
Step.GRID_NAME = "GridTexture"
Step.DARK_FLOOR_LUMINANCE = 0.35 -- below this the grid is drawn light
Step.DARK_GRID = { Color3 = rgb(255, 255, 255), Transparency = 0.85 }
Step.BAND_MATCH_TOLERANCE = 0.6 -- a Ground part spanning the zone floor Z band (within this) is stretched with it
Step.COPLANAR_TOLERANCE = 0.03

-- Geometry check
Step.CLEARANCE = 1 -- studs between a wall and anything it must not block
Step.STREET_HALF_WIDTH = 15 -- main street |Z| <= 15 (env_a / post_scratch_layout)
Step.STREET_CLEAR_HEIGHT = 12
Step.GATE_AREA_DEPTH = 14 -- env_b: X [gate, gate + 14] and |Z| <= 32 stay free for the stage gates
Step.GATE_AREA_HALF_WIDTH = 32
Step.UNDERGROUND_MARGIN = 1 -- parts whose top is this far under the floor are legacy junk, not blocked by a wall
Step.MAX_WALLS = 24

local LOG_PREFIX = "[StealaHero Build][post_world_sae]"

local function findPath(root, path)
	local current = root
	for _, segment in ipairs(path) do
		current = current and current:FindFirstChild(segment)
	end
	return current
end

local function worldAABB(part)
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

-- Boxes overlap when they share volume after growing box A by `pad` on every side (pad < 0 shrinks it).
local function overlaps(amn, amx, bmn, bmx, pad)
	return amn.X - pad < bmx.X and amx.X + pad > bmn.X
		and amn.Y - pad < bmx.Y and amx.Y + pad > bmn.Y
		and amn.Z - pad < bmx.Z and amx.Z + pad > bmn.Z
end

local function setProp(inst, name, value)
	return (pcall(function()
		(inst :: any)[name] = value
	end))
end

local function rgbText(c)
	return string.format("rgb(%d,%d,%d)", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function baseParts(root)
	local out = {}
	if root == nil then
		return out
	end
	if root:IsA("BasePart") then
		table.insert(out, root)
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(out, d)
		end
	end
	return out
end

local function hasMaterialVariant(place, name, baseMaterial)
	local ms = place:FindFirstChildOfClass("MaterialService")
	for _, d in ipairs(ms and ms:GetDescendants() or {}) do
		if d:IsA("MaterialVariant") and d.Name == name and d.BaseMaterial == baseMaterial then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------------------------------
-- Layout: stage X ranges, lane side walls, lane end, hub walls
---------------------------------------------------------------------------------------------------

-- Stage key -> { x0, x1 }: the zone floor (the seams the floor colour changes at), else the stage model attributes.
local function stageRanges(ws)
	local ground = ws:FindFirstChild("Ground")
	local envs = ws:FindFirstChild("StageEnvironments")
	local out = {}
	for _, key in ipairs(Step.STAGE_ORDER) do
		local floor = ground and ground:FindFirstChild("ZoneFloor_" .. key)
		local model = envs and envs:FindFirstChild(key)
		if floor and floor:IsA("BasePart") then
			local mn, mx = worldAABB(floor)
			out[key] = { mn.X, mx.X }
		elseif model and type(model:GetAttribute("XMin")) == "number" and type(model:GetAttribute("XMax")) == "number" then
			out[key] = { model:GetAttribute("XMin"), model:GetAttribute("XMax") }
		else
			out[key] = Step.FALLBACK_STAGE_X[key]
			print(string.format("%s WARNING: no zone floor or stage model for %s; using X %d..%d.", LOG_PREFIX, key, out[key][1], out[key][2]))
		end
	end
	return out
end

-- Inner faces of the lane's invisible side walls (Boundary of stages 1-3, EndWall.SideWalls of stages 4-6).
local function laneSides(ws)
	local envs = ws:FindFirstChild("StageEnvironments")
	local north, south = nil, nil
	local northMin, southMax = math.huge, -math.huge
	for _, d in ipairs(envs and envs:GetDescendants() or {}) do
		if d:IsA("BasePart") and d.CanCollide then
			local mn, mx = worldAABB(d)
			if d.Name == "BoundaryWallNorth" or d.Name == "SideWallNorth" then
				north = math.max(north or -math.huge, mn.Z)
				northMin = math.min(northMin, mn.Z)
			elseif d.Name == "BoundaryWallSouth" or d.Name == "SideWallSouth" then
				south = math.min(south or math.huge, mx.Z)
				southMax = math.max(southMax, mx.Z)
			end
		end
	end
	if north == nil or south == nil then
		print(string.format("%s WARNING: invisible side walls not found; lane walls at Z %.2f / %.2f.", LOG_PREFIX, Step.LANE_NORTH_Z, Step.LANE_SOUTH_Z))
		return Step.LANE_NORTH_Z, Step.LANE_SOUTH_Z
	end
	if north - northMin > 0.1 or southMax - south > 0.1 then
		print(string.format("%s WARNING: the invisible side walls are not flush (north %.2f..%.2f, south %.2f..%.2f); the visible walls take the outer line.",
			LOG_PREFIX, northMin, north, south, southMax))
	end
	return north, south
end

-- X where the lane walls stop: inside the Red Line wall after stage 6 (its middle), else just past the last floor.
local function laneEndX(ws, ranges)
	local wall = findPath(ws, { "StageEnvironments", "EndWall", "RedLine", "RedLineWall" })
	if wall and wall:IsA("BasePart") then
		return wall.CFrame.Position.X
	end
	local last = ranges[Step.STAGE_ORDER[#Step.STAGE_ORDER]]
	print(LOG_PREFIX .. " WARNING: EndWall.RedLine.RedLineWall not found; lane walls stop past the last zone floor.")
	return last[2] + Step.LANE_END_PAST_FLOOR
end

-- Everything that belongs to the hub (must stand inside the hub walls, never touch one). Above-ground parts only.
local function hubContent(ws, groundY)
	local roots = {
		{ "plots", ws:FindFirstChild("Plots") },
		{ "stalls", ws:FindFirstChild("Stands") },
		{ "leaderboards", findPath(ws, { "__OBJECTS", "Leaderboards" }) },
		{ "free gift", findPath(ws, { "Hub", "FreeGift" }) },
		{ "group reward", findPath(ws, { "__OBJECTS", "GroupReward" }) },
		{ "spawn", ws:FindFirstChild("SpawnLocation") },
	}
	local out = {}
	for _, entry in ipairs(roots) do
		for _, part in ipairs(baseParts(entry[2])) do
			local mn, mx = worldAABB(part)
			if mx.Y > groundY - Step.UNDERGROUND_MARGIN then
				table.insert(out, { label = entry[1], part = part, mn = mn, mx = mx })
			end
		end
	end
	return out
end

-- The SAE lobby walls, pushed outward only where hub content would otherwise touch them.
local function hubInner(content, laneNorth, laneSouth)
	local inner = table.clone(Step.HUB_INNER)
	local c = Step.CLEARANCE
	for _, item in ipairs(content) do
		inner.West = math.min(inner.West, item.mn.X - c)
		inner.North = math.max(inner.North, item.mx.Z + c)
		inner.South = math.min(inner.South, item.mn.Z - c)
		-- the East walls stand only beside the lane mouth: content inside the mouth's Z band may reach past them
		if item.mx.Z > laneNorth - c or item.mn.Z < laneSouth + c then
			inner.East = math.max(inner.East, item.mx.X + c)
		end
	end
	for side, value in pairs(inner) do
		if value ~= Step.HUB_INNER[side] then
			print(string.format("%s hub %s wall moved out to %.2f (was %.2f) to keep the hub content inside.", LOG_PREFIX, side, value, Step.HUB_INNER[side]))
		end
	end
	return inner
end

---------------------------------------------------------------------------------------------------
-- 1. Zone floors in the SAE look
---------------------------------------------------------------------------------------------------

local function luminance(c)
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

local function restyleFloors(place, ws)
	local ground = ws:FindFirstChild("Ground")
	if not ground then
		print(LOG_PREFIX .. " WARNING: Workspace.Ground not found; zone floors keep their look.")
		return 0
	end
	local variantOk = hasMaterialVariant(place, Step.FLOOR_VARIANT, Step.FLOOR_MATERIAL)
	if not variantOk then
		print(string.format("%s WARNING: MaterialVariant '%s' (%s) missing; zone floors render as plain %s.", LOG_PREFIX, Step.FLOOR_VARIANT,
			tostring(Step.FLOOR_MATERIAL), tostring(Step.FLOOR_MATERIAL)))
	end
	local done = 0
	for _, key in ipairs(Step.STAGE_ORDER) do
		local floor = ground:FindFirstChild("ZoneFloor_" .. key)
		if floor and floor:IsA("BasePart") then
			floor.Material = Step.FLOOR_MATERIAL
			setProp(floor, "MaterialVariant", variantOk and Step.FLOOR_VARIANT or "")
			floor.CanCollide = false
			floor.CanQuery = false
			floor.CanTouch = false
			-- one top grid overlay, named like the SAE one
			local grid = nil
			for _, child in ipairs(floor:GetChildren()) do
				if grid == nil and child:IsA("Texture") and child.Face == Enum.NormalId.Top then
					grid = child
				elseif child:IsA("Texture") or child:IsA("Decal") then
					child:Destroy()
				end
			end
			if not grid then
				grid = Instance.new("Texture")
				grid.Parent = floor
			end
			local dark = luminance(floor.Color) < Step.DARK_FLOOR_LUMINANCE
			grid.Name = Step.GRID_NAME
			setProp(grid, "TextureContent", roblox.Content.fromUri(Ground.GRID.Uri))
			grid.Face = Enum.NormalId.Top
			grid.Color3 = dark and Step.DARK_GRID.Color3 or Ground.GRID.Color3
			grid.Transparency = dark and Step.DARK_GRID.Transparency or Ground.GRID.Transparency
			grid.StudsPerTileU = Ground.GRID.StudsPerTile
			grid.StudsPerTileV = Ground.GRID.StudsPerTile
			grid.OffsetStudsU = 0
			grid.OffsetStudsV = 0
			done += 1
			print(string.format("%s   ZoneFloor_%-8s %s Plastic + '%s', %s grid", LOG_PREFIX, key, rgbText(floor.Color), variantOk and Step.FLOOR_VARIANT or "",
				dark and "light" or "dark"))
		else
			print(string.format("%s WARNING: Workspace.Ground.ZoneFloor_%s not found; not restyled.", LOG_PREFIX, key))
		end
	end
	return done
end

-- The Z band all zone floors share (ground step), or nil.
local function floorBand(ws)
	local ground = ws:FindFirstChild("Ground")
	local zMin, zMax = nil, nil
	for _, key in ipairs(Step.STAGE_ORDER) do
		local floor = ground and ground:FindFirstChild("ZoneFloor_" .. key)
		if floor and floor:IsA("BasePart") then
			local mn, mx = worldAABB(floor)
			zMin = math.min(zMin or math.huge, mn.Z)
			zMax = math.max(zMax or -math.huge, mx.Z)
		end
	end
	return zMin, zMax
end

-- Stretches every Workspace.Ground part spanning the band [bandMin, bandMax] to [zMin, zMax] (visual only).
local function stretchGround(ws, bandMin, bandMax, zMin, zMax)
	local ground = ws:FindFirstChild("Ground")
	local count = 0
	for _, part in ipairs(ground and ground:GetChildren() or {}) do
		if part:IsA("BasePart") then
			local mn, mx = worldAABB(part)
			if math.abs(mn.Z - bandMin) <= Step.BAND_MATCH_TOLERANCE and math.abs(mx.Z - bandMax) <= Step.BAND_MATCH_TOLERANCE then
				local cf = part.CFrame
				local s = part.Size
				local len = zMax - zMin
				local size = nil
				if math.abs(cf.RightVector.Z) > 0.999 then
					size = Vector3.new(len, s.Y, s.Z)
				elseif math.abs(cf.UpVector.Z) > 0.999 then
					size = Vector3.new(s.X, len, s.Z)
				elseif math.abs(cf.LookVector.Z) > 0.999 then
					size = Vector3.new(s.X, s.Y, len)
				end
				if size then
					local p = cf.Position
					part.Size = size
					part.CFrame = CFrame.new(p.X, p.Y, (zMin + zMax) / 2) * cf.Rotation
					count += 1
				else
					print(string.format("%s WARNING: %s is not axis-aligned; not stretched.", LOG_PREFIX, part:GetFullName()))
				end
			end
		end
	end
	return count
end

---------------------------------------------------------------------------------------------------
-- 2. Walls
---------------------------------------------------------------------------------------------------

local OPPOSITE_FACE = { Front = "Back", Back = "Front", Left = "Right", Right = "Left" }

-- face: a NormalId name ("Front" = -Z, "Back" = +Z, "Left" = -X, "Right" = +X on an unrotated part)
local function addTexture(part, name, face)
	local t = Step.WALL_TEXTURE
	local tex = Instance.new("Texture")
	tex.Name = name
	setProp(tex, "TextureContent", roblox.Content.fromUri(t.Uri))
	tex.Face = (Enum.NormalId :: any)[face]
	tex.Color3 = t.Color3
	tex.Transparency = t.Transparency
	tex.StudsPerTileU = t.StudsPerTile
	tex.StudsPerTileV = t.StudsPerTile
	tex.OffsetStudsU = 0
	tex.OffsetStudsV = 0
	tex.Parent = part
	return tex
end

-- Axis-aligned SAE wall over X [x0, x1] x Z [z0, z1]. innerFace: NormalId name of the face toward the playable side (Front = -Z,
-- Back = +Z, Left = -X, Right = +X on an unrotated part); the SAE texture goes on it and on the opposite face.
local function makeWall(folder, name, x0, x1, z0, z1, bottomY, color, innerFace, variantOk, zoneName, side)
	assert(x1 - x0 > 0.5 and z1 - z0 > 0.5, string.format("%s: degenerate wall %s (X %.2f..%.2f, Z %.2f..%.2f)", LOG_PREFIX, name, x0, x1, z0, z1))
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(x1 - x0, Step.WALL_HEIGHT, z1 - z0)
	p.CFrame = CFrame.new((x0 + x1) / 2, bottomY + Step.WALL_HEIGHT / 2, (z0 + z1) / 2)
	p.Color = color
	p.Material = Step.WALL_MATERIAL
	setProp(p, "MaterialVariant", variantOk and Step.WALL_VARIANT or "")
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Transparency = 0
	p.Reflectance = 0
	p.Anchored = true
	p.CanCollide = true
	p.CanQuery = true
	p.CanTouch = false
	p.CastShadow = true
	p.Locked = true
	addTexture(p, Step.WALL_TEXTURE.Name, innerFace)
	addTexture(p, Step.WALL_TEXTURE.Name .. "Outer", OPPOSITE_FACE[innerFace])
	p:SetAttribute("Zone", zoneName)
	p:SetAttribute("Side", side)
	p.Parent = folder
	return p
end

local function subFolder(root, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = root
	return f
end

---------------------------------------------------------------------------------------------------
-- 3. Geometry check
---------------------------------------------------------------------------------------------------

local function validate(ws, walls, layout, groundY)
	local problems = {}
	local wallBoxes = {}
	for _, w in ipairs(walls) do
		local mn, mx = worldAABB(w)
		table.insert(wallBoxes, { part = w, mn = mn, mx = mx })
	end
	local checked = 0
	local function checkBox(label, mn, mx, pad)
		checked += 1
		for _, w in ipairs(wallBoxes) do
			if overlaps(w.mn, w.mx, mn, mx, pad) then
				table.insert(problems, string.format("%s touches %s", label, w.part.Name))
			end
		end
	end
	local function checkParts(label, root)
		for _, part in ipairs(baseParts(root)) do
			local mn, mx = worldAABB(part)
			if mx.Y > groundY - Step.UNDERGROUND_MARGIN then
				checkBox(label .. " " .. part:GetFullName(), mn, mx, Step.CLEARANCE)
			end
		end
	end
	local c = Step.CLEARANCE
	local top = groundY + Step.WALL_HEIGHT

	-- corridors: the main street (from the hub spawn, through the lane mouth, to the end of the lane), the walkable lane
	-- between the side walls (chase and return routes, the night teleport runs from there) and the hub floor
	local spawn = ws:FindFirstChild("SpawnLocation")
	local streetX0 = layout.hub.East - 10
	if spawn and spawn:IsA("BasePart") then
		streetX0 = math.min(streetX0, (worldAABB(spawn)).X)
	end
	checkBox("main street", Vector3.new(streetX0, groundY, -Step.STREET_HALF_WIDTH), Vector3.new(layout.laneEnd, groundY + Step.STREET_CLEAR_HEIGHT, Step.STREET_HALF_WIDTH), c)
	checkBox("lane corridor", Vector3.new(layout.hub.East, groundY, layout.laneSouth), Vector3.new(layout.laneEnd, top, layout.laneNorth), -0.01)
	checkBox("hub interior", Vector3.new(layout.hub.West, groundY, layout.hub.South), Vector3.new(layout.hub.East, top, layout.hub.North), -0.01)

	-- hub objects: never touch a wall, always inside the hub (or in the lane mouth)
	for _, item in ipairs(layout.hubContent) do
		checkBox(item.label .. " " .. item.part:GetFullName(), item.mn, item.mx, c)
		local inHub = item.mn.X >= layout.hub.West and item.mn.Z >= layout.hub.South and item.mx.Z <= layout.hub.North
		local eastOk = item.mx.X <= layout.hub.East or (item.mn.Z >= layout.laneSouth and item.mx.Z <= layout.laneNorth)
		if not (inHub and eastOk) then
			table.insert(problems, string.format("%s %s is outside the hub walls", item.label, item.part:GetFullName()))
		end
	end

	-- stage gates (empty markers: their entrance areas) and every stage's gameplay content
	for _, gate in ipairs(findPath(ws, { "Hub", "StageGates" }) and findPath(ws, { "Hub", "StageGates" }):GetChildren() or {}) do
		local ok, pivot = pcall(function()
			return (gate :: any).WorldPivotData
		end)
		if ok and typeof(pivot) == "CFrame" then
			local x = pivot.Position.X
			checkBox("gate area " .. gate.Name, Vector3.new(x - 2, groundY, -Step.GATE_AREA_HALF_WIDTH), Vector3.new(x + Step.GATE_AREA_DEPTH, groundY + Step.STREET_CLEAR_HEIGHT, Step.GATE_AREA_HALF_WIDTH), c)
		end
		checkParts("gate", gate)
	end
	checkParts("zone", findPath(ws, { "__OBJECTS", "Areas", "GuardAreas" }))
	local envs = ws:FindFirstChild("StageEnvironments")
	for _, key in ipairs(Step.STAGE_ORDER) do
		local model = envs and envs:FindFirstChild(key)
		if model then
			checkParts("egg spot", model:FindFirstChild("EggSpots"))
			checkParts("egg cover", model:FindFirstChild("EggCover"))
			checkParts("rain volume", model:FindFirstChild("Rain"))
			local post = model:FindFirstChild("VillainPost")
			if post and post:IsA("BasePart") then
				local pad = post:GetAttribute("PadSize")
				local r = (type(pad) == "number" and pad or 20) / 2
				local p = post.CFrame.Position
				checkBox("villain pad " .. key, Vector3.new(p.X - r, groundY, p.Z - r), Vector3.new(p.X + r, groundY + 14, p.Z + r), c)
			end
		end
	end
	return problems, checked
end

-- A part renders something when it is not fully transparent or when it carries face art (a Decal / Texture /
-- SurfaceGui draws on its faces even at Transparency 1, e.g. an invisible road or sidewalk carrier).
local function rendersSomething(part)
	if part.Transparency < 1 then
		return true
	end
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("Decal") or child:IsA("SurfaceGui") then -- Texture is a Decal subclass
			return true
		end
	end
	return false
end

-- Nothing visible may lie flat on the floor top inside the strips the floors were stretched into (z-fighting).
local function coplanarOnStrips(ws, strips, floorTopY)
	local hits = {}
	local ground = ws:FindFirstChild("Ground")
	local walls = ws:FindFirstChild(Step.FOLDER_NAME)
	for _, d in ipairs(ws:GetDescendants()) do
		if d:IsA("BasePart") and rendersSomething(d) and d.Name ~= "Baseplate" and d.Name ~= "Terrain"
			and not (ground and d:IsDescendantOf(ground)) and not (walls and d:IsDescendantOf(walls)) then
			local mn, mx = worldAABB(d)
			if math.abs(mx.Y - floorTopY) <= Step.COPLANAR_TOLERANCE or math.abs(mn.Y - floorTopY) <= Step.COPLANAR_TOLERANCE then
				for _, s in ipairs(strips) do
					if mn.X < s.x1 and mx.X > s.x0 and mn.Z < s.z1 and mx.Z > s.z0 then
						table.insert(hits, d:GetFullName())
						break
					end
				end
			end
		end
	end
	return hits
end

---------------------------------------------------------------------------------------------------

function Step.Apply(place, spPlace, ctx)
	ctx = ctx or {}
	local ws = place.Workspace
	local baseplate = ctx.baseplate or ws:FindFirstChild("Baseplate")
	local groundY = ctx.groundY or (baseplate and baseplate:IsA("BasePart") and baseplate.CFrame.Position.Y + baseplate.Size.Y / 2)
	assert(type(groundY) == "number", LOG_PREFIX .. " groundY unavailable (no ctx.groundY and no Workspace.Baseplate)")
	local T = Step.WALL_THICKNESS

	-- 1. floors
	local restyled = restyleFloors(place, ws)

	-- layout
	local ranges = stageRanges(ws)
	local laneNorth, laneSouth = laneSides(ws)
	local laneEnd = laneEndX(ws, ranges)
	local content = hubContent(ws, groundY)
	local hub = hubInner(content, laneNorth, laneSouth)
	local laneStart = hub.East + T -- the lane walls start at the outer face of the hub's East walls
	assert(laneNorth > Step.STREET_HALF_WIDTH and laneSouth < -Step.STREET_HALF_WIDTH, LOG_PREFIX .. " lane side walls inside the main street")
	assert(laneEnd > laneStart + 50, string.format("%s lane end X %.2f is not past the lane start X %.2f", LOG_PREFIX, laneEnd, laneStart))

	-- 2. walls
	local old = ws:FindFirstChild(Step.FOLDER_NAME)
	while old do
		old:Destroy()
		old = ws:FindFirstChild(Step.FOLDER_NAME)
	end
	local root = Instance.new("Folder")
	root.Name = Step.FOLDER_NAME
	root:SetAttribute("Source", Step.REFERENCE)
	root:SetAttribute("BuiltBy", "scripts/steps/post_world_sae.luau")
	root:SetAttribute("WallHeight", Step.WALL_HEIGHT)
	root:SetAttribute("WallThickness", T)
	root:SetAttribute("LaneNorthZ", laneNorth)
	root:SetAttribute("LaneSouthZ", laneSouth)
	root:SetAttribute("HubEastX", hub.East)
	root.Parent = ws

	local variantOk = hasMaterialVariant(place, Step.WALL_VARIANT, Step.WALL_MATERIAL)
	if not variantOk then
		print(string.format("%s WARNING: MaterialVariant '%s' (%s) missing; the walls render as plain %s.", LOG_PREFIX, Step.WALL_VARIANT,
			tostring(Step.WALL_MATERIAL), tostring(Step.WALL_MATERIAL)))
	end
	local bottomY = groundY - Step.WALL_SINK
	local walls = {}
	local function add(part)
		table.insert(walls, part)
	end

	-- hub: West and the East pair span between North and South; North / South run from West to the East outer face
	local hubFolder = subFolder(root, "Hub")
	local HC = Step.HUB_WALL_COLOR
	add(makeWall(hubFolder, "HubWall_West", hub.West - T, hub.West, hub.South - T, hub.North + T, bottomY, HC, "Right", variantOk, "Hub", "West"))
	add(makeWall(hubFolder, "HubWall_North", hub.West, hub.East + T, hub.North, hub.North + T, bottomY, HC, "Front", variantOk, "Hub", "North"))
	add(makeWall(hubFolder, "HubWall_South", hub.West, hub.East + T, hub.South - T, hub.South, bottomY, HC, "Back", variantOk, "Hub", "South"))
	add(makeWall(hubFolder, "HubWall_EastNorth", hub.East, hub.East + T, laneNorth, hub.North, bottomY, HC, "Left", variantOk, "Hub", "East"))
	add(makeWall(hubFolder, "HubWall_EastSouth", hub.East, hub.East + T, hub.South, laneSouth, bottomY, HC, "Left", variantOk, "Hub", "East"))

	-- stages: one North and one South wall per stage X range, seams where the zone floor colour changes
	for i, key in ipairs(Step.STAGE_ORDER) do
		local x0 = i == 1 and laneStart or math.max(ranges[key][1], laneStart)
		local x1 = i == #Step.STAGE_ORDER and laneEnd or ranges[Step.STAGE_ORDER[i + 1]][1]
		if x1 - x0 > 0.5 then
			local color = Step.STAGE_WALL_COLORS[key] or HC
			local folder = subFolder(root, key)
			folder:SetAttribute("XMin", x0)
			folder:SetAttribute("XMax", x1)
			add(makeWall(folder, "StageWall_" .. key .. "_North", x0, x1, laneNorth, laneNorth + T, bottomY, color, "Front", variantOk, key, "North"))
			add(makeWall(folder, "StageWall_" .. key .. "_South", x0, x1, laneSouth - T, laneSouth, bottomY, color, "Back", variantOk, key, "South"))
		else
			print(string.format("%s WARNING: stage %s has no lane length past X %.2f; no walls.", LOG_PREFIX, key, laneStart))
		end
	end
	assert(#walls <= Step.MAX_WALLS, string.format("%s produced %d walls (limit %d)", LOG_PREFIX, #walls, Step.MAX_WALLS))

	-- 1b. floors and dividers run on under the side walls (to the wall centre lines)
	local bandMin, bandMax = floorBand(ws)
	local stretched, stripHits = 0, {}
	if bandMin and bandMax then
		local zMin = math.min(bandMin, laneSouth - T / 2)
		local zMax = math.max(bandMax, laneNorth + T / 2)
		stretched = stretchGround(ws, bandMin, bandMax, zMin, zMax)
		local ground = ws:FindFirstChild("Ground")
		local floorTop = ground and ground:GetAttribute("ZoneFloorTopY")
		if type(floorTop) ~= "number" then
			floorTop = groundY + Ground.ZONE_FLOOR_LIFT
		end
		local x0, x1 = ranges[Step.STAGE_ORDER[1]][1], ranges[Step.STAGE_ORDER[#Step.STAGE_ORDER]][2]
		stripHits = coplanarOnStrips(ws, {
			{ x0 = x0, x1 = x1, z0 = bandMax, z1 = zMax },
			{ x0 = x0, x1 = x1, z0 = zMin, z1 = bandMin },
		}, floorTop)
	end

	-- 3. geometry check
	local problems, checked = validate(ws, walls, {
		hub = hub,
		hubContent = content,
		laneNorth = laneNorth,
		laneSouth = laneSouth,
		laneEnd = laneEnd,
	}, groundY)
	for _, name in ipairs(stripHits) do
		table.insert(problems, string.format("%s lies on the floor top in a stretched floor strip (z-fighting)", name))
	end
	if #problems > 0 then
		error(string.format("%s %d geometry problem(s): %s", LOG_PREFIX, #problems, table.concat(problems, " | ", 1, math.min(#problems, 8))))
	end

	print(string.format("%s hub walls: X %.2f..%.2f, Z %.2f..%.2f (inner faces), lane mouth Z %.2f..%.2f open; lane walls X %.2f..%.2f.",
		LOG_PREFIX, hub.West, hub.East, hub.South, hub.North, laneSouth, laneNorth, laneStart, laneEnd))
	print(string.format("[StealaHero Build] SAE world: Workspace.%s holds %d walls (%.2f thick, %.3f tall, '%s' + Texture %s; hub SAE orange, 6 stage colours); %d zone floors in the SAE grid look, %d ground parts stretched under the walls; geometry check passed (%d boxes, 0 problems).",
		Step.FOLDER_NAME, #walls, T, Step.WALL_HEIGHT, variantOk and Step.WALL_VARIANT or "SmoothPlastic", Step.WALL_TEXTURE.Uri, restyled, stretched, checked))
end

return Step
