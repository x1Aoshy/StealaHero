-- scripts/steps/ground.luau
-- Build step: gives the world back the ground of the original map.
--
-- The build deletes the decorative map (`Workspace.__OBJECTS.Build`; `Workspace.Map` is already empty in the
-- base place) and lays one solid 10000x20x3000 Baseplate under everything. Out of the box that Baseplate is
-- grey Plastic with a grey grid, so the hub, the plots and all 9 zones read as a grey grid. The original map
-- floor was:
--   * hub / plots: `Build.MainMap.Bases.Part`, Plastic + MaterialVariant "Studs", rgb(105,208,20) green, with a
--     black 80%-transparent 8-stud grid Texture (6372755229) on top;
--   * zones: `Build.1.BOTTOMS`, one Plastic "Studs" floor per zone in the zone's colour (Forest green, Desert
--     sand, Snow white, Volcano ash, Abyss navy, Prehistoric brown, Cosmic black...), same grid overlay;
--   * `Build.3`: 7 olive divider strips across the lane at the zone boundaries.
--
-- This step reproduces exactly that, read from the base place (ctx.basePlacePath), not guessed:
--   1. the Baseplate itself takes the hub floor look (material, variant, colour, grid overlay). It stays the one
--      solid, collidable floor at ctx.groundY, so nothing under the plots, treadmills, spawn or stands changes;
--   2. Workspace.Ground (Folder) gets the 9 zone floors + 7 dividers (16 parts, no decorations, scripts, sounds,
--      meshes or lights), shifted by ctx.shiftOffset like the rest of __OBJECTS. They are VISUAL ONLY
--      (CanCollide/CanQuery/CanTouch/CastShadow = false): the Baseplate remains the walkable, raycast and
--      pathfinding surface, so guard chase lanes, egg drops and every ground raycast behave exactly as before.
--      Zone floor tops sit at their ORIGINAL height (67.576 + shiftOffset.Y = groundY + 0.026): the nests were
--      authored on that surface (several are only a few hundredths of a stud tall above it), so any higher floor
--      would bury them and any lower one would z-fight the Baseplate top face. Seams
--      between neighbouring zones are cut at the midpoint of the original overlaps and all floors share one
--      Z band (the original corridor walls, not restored, used to hide their uneven edges).
-- The corridor walls, invisible collision shells, props and meshes of Build are NOT restored (they block walking
-- and are what the build strips as bloat).
-- Later passes: env_a / env_b tint each zone floor with its stage palette, then scripts/steps/post_world_sae.luau gives
-- the zone floors the SAE grid look (Plastic + "Studs" + GridTexture, reusing Step.GRID below), stretches the floors and
-- dividers in Z under the side walls and builds the SAE walls (Workspace.WorldWalls) around the hub and the stages.
--
-- Idempotent: Workspace.Ground is rebuilt from scratch and the Baseplate restyle is absolute.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local Step = {}

Step.FOLDER_NAME = "Ground"
-- Zone floor top = the original floor top shifted (groundY + 0.026 today). If that ever lands outside
-- groundY + [MIN_LIFT, MAX_LIFT] (base place or shift changed), fall back to groundY + ZONE_FLOOR_LIFT.
Step.ZONE_FLOOR_LIFT = 0.026
Step.MIN_LIFT = 0.015 -- keeps the zone floor off the Baseplate top face (no coplanar z-fighting)
Step.MAX_LIFT = 0.1
Step.SLAB_THICKNESS = 1
Step.MAX_PARTS = 40

-- Sources in the base place (Workspace-relative)
Step.HUB_FLOOR_PATH = { "__OBJECTS", "Build", "MainMap", "Bases" } -- largest visible part = hub floor
Step.ZONE_FLOORS_PATH = { "__OBJECTS", "Build", "1", "BOTTOMS" }
Step.DIVIDERS_PATH = { "__OBJECTS", "Build", "3" }

-- Hub floor look as found in the base place (used only when the base place cannot be read).
Step.FALLBACK_HUB = {
	Material = Enum.Material.Plastic,
	MaterialVariant = "Studs",
	Color = Color3.fromRGB(105, 208, 20),
}
Step.GRID = {
	Name = "GridTexture",
	Uri = "rbxassetid://6372755229",
	Color3 = Color3.new(0, 0, 0),
	Transparency = 0.8,
	StudsPerTile = 8,
}

local LOG_PREFIX = "[StealaHero Build][ground]"

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

local function rgbText(c)
	return string.format("rgb(%d,%d,%d)", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function getProp(inst, name)
	local ok, v = pcall(function()
		return (inst :: any)[name]
	end)
	if ok then
		return v
	end
	return nil
end

local function setProp(inst, name, value)
	return (pcall(function()
		(inst :: any)[name] = value
	end))
end

-- A restored slab keeps only its look: Texture/Decal children stay, anything else (welds, attachments,
-- plugin attributes, tags) goes. Every slab is purely visual.
local function makeVisualOnly(part)
	for _, child in ipairs(part:GetChildren()) do
		if not (child:IsA("Texture") or child:IsA("Decal")) then
			child:Destroy()
		else
			for name in pairs(child:GetAttributes()) do
				child:SetAttribute(name, nil)
			end
		end
	end
	for name in pairs(part:GetAttributes()) do
		part:SetAttribute(name, nil)
	end
	pcall(function()
		for _, tag in ipairs(part:GetTags()) do
			part:RemoveTag(tag)
		end
	end)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	setProp(part, "Massless", true)
	setProp(part, "Locked", true)
end

local function loadBasePlace(ctx)
	local path = ctx and ctx.basePlacePath
	if type(path) ~= "string" or not fs.isFile(path) then
		print(string.format("%s WARNING: base place '%s' not found; original ground look unavailable.", LOG_PREFIX, tostring(path)))
		return nil
	end
	local ok, placeOrErr = pcall(function()
		return roblox.deserializePlace(fs.readFile(path))
	end)
	if not ok then
		print(string.format("%s WARNING: could not read base place '%s': %s", LOG_PREFIX, path, tostring(placeOrErr)))
		return nil
	end
	return placeOrErr
end

-- The hub floor of the original map: the largest visible part of Build.MainMap.Bases (175 x 438 studs).
local function findHubFloor(basePlace)
	local bases = basePlace and findPath(basePlace.Workspace, Step.HUB_FLOOR_PATH)
	if not bases then
		return nil
	end
	local best, bestArea = nil, 0
	for _, d in ipairs(bases:GetChildren()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local mn, mx = worldAABB(d)
			local area = (mx.X - mn.X) * (mx.Z - mn.Z)
			if mx.Y - mn.Y <= 2 and area > bestArea then
				best, bestArea = d, area
			end
		end
	end
	return best
end

local function findGridTexture(part)
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("Texture") and child.Face == Enum.NormalId.Top then
			return child
		end
	end
	return nil
end

-- Makes sure the MaterialVariant the ground uses resolves in this place (copies it from the base place if not).
local function ensureMaterialVariant(place, basePlace, variantName, baseMaterial)
	if variantName == nil or variantName == "" then
		return true
	end
	local ms = place:GetService("MaterialService")
	for _, d in ipairs(ms:GetDescendants()) do
		if d:IsA("MaterialVariant") and d.Name == variantName and d.BaseMaterial == baseMaterial then
			return true
		end
	end
	local baseMs = basePlace and basePlace:FindFirstChildOfClass("MaterialService")
	if baseMs then
		for _, d in ipairs(baseMs:GetDescendants()) do
			if d:IsA("MaterialVariant") and d.Name == variantName and d.BaseMaterial == baseMaterial then
				local copy = d:Clone()
				copy.Parent = ms
				print(string.format("%s Copied MaterialVariant '%s' (%s) into MaterialService.", LOG_PREFIX, variantName, tostring(baseMaterial)))
				return true
			end
		end
	end
	print(string.format("%s WARNING: MaterialVariant '%s' (%s) not found; the floor renders as plain %s.", LOG_PREFIX, variantName, tostring(baseMaterial), tostring(baseMaterial)))
	return false
end

-- 1. The Baseplate takes the original hub floor look. Only look properties change: size, CFrame, Anchored and
-- CanCollide are the build's (the solid safety floor at groundY).
local function restyleBaseplate(place, basePlace, baseplate)
	local hub = findHubFloor(basePlace)
	local look = Step.FALLBACK_HUB
	local grid = Step.GRID
	local source = "fallback constants"
	if hub then
		look = { Material = hub.Material, MaterialVariant = getProp(hub, "MaterialVariant") or "", Color = hub.Color }
		source = hub:GetFullName()
		local tex = findGridTexture(hub)
		if tex then
			local content = getProp(tex, "TextureContent")
			grid = {
				Name = Step.GRID.Name,
				Uri = (typeof(content) == "Content" and content.Uri) or Step.GRID.Uri,
				Color3 = tex.Color3,
				Transparency = tex.Transparency,
				StudsPerTile = tex.StudsPerTileU,
			}
		end
	else
		print(LOG_PREFIX .. " WARNING: original hub floor (Build.MainMap.Bases) not found; using the recorded original look.")
	end

	baseplate.Material = look.Material
	if not setProp(baseplate, "MaterialVariant", look.MaterialVariant) then
		print(LOG_PREFIX .. " WARNING: could not set Baseplate.MaterialVariant.")
	end
	baseplate.Color = look.Color
	baseplate.TopSurface = Enum.SurfaceType.Smooth
	baseplate.BottomSurface = Enum.SurfaceType.Smooth
	ensureMaterialVariant(place, basePlace, look.MaterialVariant, look.Material)

	-- one top-face grid overlay, restyled from the build's grey grid to the original dark one
	local keep = baseplate:FindFirstChild(grid.Name)
	if keep and not keep:IsA("Texture") then
		keep = nil
	end
	for _, child in ipairs(baseplate:GetChildren()) do
		if (child:IsA("Texture") or child:IsA("Decal")) and child ~= keep then
			child:Destroy()
		end
	end
	if not keep then
		keep = Instance.new("Texture")
		keep.Name = grid.Name
		keep.Parent = baseplate
	end
	setProp(keep, "TextureContent", roblox.Content.fromUri(grid.Uri))
	keep.Face = Enum.NormalId.Top
	keep.Color3 = grid.Color3
	keep.Transparency = grid.Transparency
	keep.StudsPerTileU = grid.StudsPerTile
	keep.StudsPerTileV = grid.StudsPerTile
	keep.OffsetStudsU = 0
	keep.OffsetStudsV = 0

	print(string.format("%s Baseplate restyled as the original hub floor (%s): %s + MaterialVariant '%s', %s, grid %s %s at %.2f transparency.",
		LOG_PREFIX, source, tostring(look.Material), tostring(look.MaterialVariant), rgbText(look.Color), grid.Uri, rgbText(grid.Color3), grid.Transparency))
end

-- Zone name -> { xMin, xMax } of its Bounds (final, shifted world positions).
local function zoneRanges(ws)
	local ga = findPath(ws, { "__OBJECTS", "Areas", "GuardAreas" })
	local out = {}
	if not ga then
		return out
	end
	for _, zone in ipairs(ga:GetChildren()) do
		local bounds = zone:FindFirstChild("Bounds")
		if bounds and bounds:IsA("BasePart") then
			local mn, mx = worldAABB(bounds)
			table.insert(out, { name = zone.Name, xMin = mn.X, xMax = mx.X })
		end
	end
	return out
end

-- 2. Zone floors + dividers into Workspace.Ground.
local function buildZoneGround(place, basePlace, ctx, folder, groundY)
	local ws = place.Workspace
	local shift = ctx.shiftOffset or Vector3.new(0, 0, 0)
	local floorsSrc = basePlace and findPath(basePlace.Workspace, Step.ZONE_FLOORS_PATH)
	if not floorsSrc then
		print(LOG_PREFIX .. " WARNING: original zone floors (Build.1.BOTTOMS) not found; zones keep the plain Baseplate.")
		return 0, 0, nil
	end
	local zones = zoneRanges(ws)
	if #zones == 0 then
		print(LOG_PREFIX .. " WARNING: no GuardAreas zone Bounds found; zone floors skipped.")
		return 0, 0, nil
	end

	-- match every original floor to the zone whose Bounds contain its (shifted) centre
	local floors, used, origFloorTop = {}, {}, -math.huge
	for _, src in ipairs(floorsSrc:GetChildren()) do
		if src:IsA("BasePart") then
			local mn, mx = worldAABB(src)
			mn += shift
			mx += shift
			local cx = (mn.X + mx.X) / 2
			local match = nil
			for _, z in ipairs(zones) do
				if cx >= z.xMin and cx <= z.xMax then
					match = z
					break
				end
			end
			if match and not used[match.name] then
				used[match.name] = true
				origFloorTop = math.max(origFloorTop, mx.Y)
				table.insert(floors, { src = src, zone = match.name, xMin = mn.X, xMax = mx.X, zMin = mn.Z, zMax = mx.Z })
			else
				print(string.format("%s WARNING: original zone floor at X %.1f matches no free zone; skipped.", LOG_PREFIX, cx))
			end
		end
	end
	for _, z in ipairs(zones) do
		if not used[z.name] then
			print(string.format("%s WARNING: zone %s has no original floor; it keeps the plain Baseplate.", LOG_PREFIX, z.name))
		end
	end
	if #floors == 0 then
		return 0, 0, nil
	end
	table.sort(floors, function(a, b)
		return a.xMin < b.xMin
	end)

	-- one shared Z band; seams at the midpoint between neighbours (no overlap = no z-fighting, no gap)
	local zMin, zMax = math.huge, -math.huge
	for _, f in ipairs(floors) do
		zMin = math.min(zMin, f.zMin)
		zMax = math.max(zMax, f.zMax)
	end
	local seams = {}
	for i = 1, #floors - 1 do
		seams[i] = (floors[i].xMax + floors[i + 1].xMin) / 2
	end

	local T = Step.SLAB_THICKNESS
	local floorTop = origFloorTop
	local lift = origFloorTop - groundY
	if lift < Step.MIN_LIFT or lift > Step.MAX_LIFT then
		print(string.format("%s WARNING: original zone floor top %.3f is %.3f from groundY; using groundY + %.3f.", LOG_PREFIX, origFloorTop, lift, Step.ZONE_FLOOR_LIFT))
		floorTop = groundY + Step.ZONE_FLOOR_LIFT
	end
	for i, f in ipairs(floors) do
		local x0 = i == 1 and f.xMin or seams[i - 1]
		local x1 = i == #floors and f.xMax or seams[i]
		local part = f.src:Clone()
		makeVisualOnly(part)
		part.Name = "ZoneFloor_" .. f.zone
		part.Size = Vector3.new(x1 - x0, T, zMax - zMin)
		part.CFrame = CFrame.new((x0 + x1) / 2, floorTop - T / 2, (zMin + zMax) / 2)
		part:SetAttribute("Zone", f.zone)
		part.Parent = folder
		print(string.format("%s   %-12s floor %s %s X[%.2f..%.2f] top %.3f", LOG_PREFIX, f.zone, rgbText(part.Color), tostring(getProp(part, "MaterialVariant")), x0, x1, floorTop))
	end

	-- dividers: same height above the floor as in the original, trimmed to the shared Z band
	local dividers = 0
	local divSrc = findPath(basePlace.Workspace, Step.DIVIDERS_PATH)
	local laneX0, laneX1 = floors[1].xMin, floors[#floors].xMax
	if divSrc then
		local list = {}
		for _, src in ipairs(divSrc:GetChildren()) do
			if src:IsA("BasePart") then
				local mn, mx = worldAABB(src)
				mn += shift
				mx += shift
				local cx = (mn.X + mx.X) / 2
				local flat = math.abs(src.CFrame.UpVector.Y) > 0.999
				if flat and cx > laneX0 and cx < laneX1 then
					table.insert(list, { src = src, cx = cx, lift = mx.Y - origFloorTop })
				end
			end
		end
		table.sort(list, function(a, b)
			return a.cx < b.cx
		end)
		for i, d in ipairs(list) do
			local src = d.src
			local part = src:Clone()
			makeVisualOnly(part)
			local rot = src.CFrame.Rotation
			local size = src.Size
			if math.abs(src.CFrame.RightVector.Z) > 0.999 then
				size = Vector3.new(zMax - zMin, size.Y, size.Z)
			elseif math.abs(src.CFrame.LookVector.Z) > 0.999 then
				size = Vector3.new(size.X, size.Y, zMax - zMin)
			end
			local top = floorTop + math.max(d.lift, 0.02)
			part.Name = string.format("ZoneDivider_%d", i)
			part.Size = size
			part.CFrame = CFrame.new(d.cx, top - size.Y / 2, (zMin + zMax) / 2) * rot
			part.Parent = folder
			dividers += 1
		end
	else
		print(LOG_PREFIX .. " WARNING: original zone dividers (Build.3) not found; skipped.")
	end
	return #floors, dividers, floorTop
end

function Step.Apply(place, spPlace, ctx)
	ctx = ctx or {}
	local ws = place.Workspace
	local baseplate = ctx.baseplate or ws:FindFirstChild("Baseplate")
	if not (baseplate and baseplate:IsA("BasePart")) then
		print(LOG_PREFIX .. " WARNING: Workspace.Baseplate not found; ground step skipped.")
		return
	end
	local groundY = ctx.groundY or (baseplate.CFrame.Position.Y + baseplate.Size.Y / 2)
	local basePlace = loadBasePlace(ctx)

	restyleBaseplate(place, basePlace, baseplate)

	local old = ws:FindFirstChild(Step.FOLDER_NAME)
	while old do
		old:Destroy()
		old = ws:FindFirstChild(Step.FOLDER_NAME)
	end
	local folder = Instance.new("Folder")
	folder.Name = Step.FOLDER_NAME
	folder:SetAttribute("GroundY", groundY)
	folder:SetAttribute("Source", tostring(ctx.basePlacePath) .. " Workspace.__OBJECTS.Build (1.BOTTOMS, 3)")
	folder.Parent = ws

	local floors, dividers, floorTop = buildZoneGround(place, basePlace, ctx, folder, groundY)
	if floorTop then
		folder:SetAttribute("ZoneFloorTopY", floorTop)
	end
	local parts = 0
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	assert(parts <= Step.MAX_PARTS, string.format("ground step produced %d parts (limit %d)", parts, Step.MAX_PARTS))
	print(string.format("[StealaHero Build] World ground: Baseplate restyled as the original green hub floor; Workspace.%s holds %d original zone floors + %d dividers (visual only, top %s over groundY %.3f).",
		Step.FOLDER_NAME, floors, dividers, floorTop and string.format("%.3f", floorTop) or "-", groundY))
end

return Step
