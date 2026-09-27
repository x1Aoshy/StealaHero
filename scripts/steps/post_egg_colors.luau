-- scripts/steps/post_egg_colors.luau
-- H4 (docs/HERO_MODELS_PLAN.md, owner EGGS): every hero's egg is painted with that hero's colours ("los huevos los
-- pintas con los colores de ellos"). Palette per hero: scripts/data/hero_palettes.luau (Base / Accent / Detail).
-- Build hook: scripts/build_stealahero.luau step 12b runs every scripts/steps/post_*.luau in name order after the hero
-- builder (which clones one generic egg per hero into ReplicatedStorage.Assets.Models.Eggs.<id>, all in one flat
-- colour) and before post_purge (which deletes the legacy animal eggs): Apply(place, spPlace, ctx).
--
-- The per-hero egg models the game renders are exactly Assets.Models.Eggs.<id>: every egg visual (area nests, carried
-- eggs, placed / growing eggs, the egg tool, the hatch) goes through Library.Client.Eggs.EggRenderer.RenderVisual,
-- which clones that template (ToolTemplates.EggTemplate / AssetEggTemplate are invisible wrappers without a visual).
--
-- Per egg:
--   * the shell (largest visible part) takes the palette Base colour;
--   * an egg that already has detail parts (bands / spots) gets them painted Accent / Detail (largest first);
--   * a single-mesh egg (today's Chicken union) gets decorations: an Accent band around the upper egg (a squashed
--     clone of the shell itself, so it follows the egg's own curvature) and Detail / Accent spots (Ball parts sunk
--     into the shell so only a dome shows). Every decoration stays inside the shell's bounding box, so the egg's size,
--     bounding box (AreaEggService sizes the nest from it, EggRenderer finds the egg's bottom from it), pivot,
--     PrimaryPart / Hitbox and the names scripts use are unchanged. Decorations are non-colliding, non-touching,
--     non-query, massless and welded (WeldConstraint with CFrame0 written) to the egg's PrimaryPart.
--   * painted and added parts carry DontModify = true: Library.Util.AssetColorUtil.Apply (run by RenderVisual on
--     every egg render) would otherwise shift any part whose hue matches the hero's BaseModelColor. Mutation cues
--     (MutationsDontModify) and rarity cues (Neon glow parts, ParticleEmitters, lights) are left untouched.
-- Idempotent: parts tagged EggDeco are removed and rebuilt, colours are absolute.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local Step = {}

local PALETTE_PATH = "scripts/data/hero_palettes.luau"
local DECO_ATTR = "EggDeco" -- role of an added decoration: "Band" | "Spot"

-- Decoration layout, in units of the shell: t = height / half-height (-1 bottom .. 1 top), radii / depths as a
-- fraction of the shell's half width. The shell profile is not readable offline (a union's geometry lives in its
-- asset), so the surface is estimated between an ellipsoid and a classic egg (round bottom half-sphere + longer top
-- half-ellipsoid) inscribed in the shell's box, and every part is placed against the OUTER estimate so it can never
-- end up hidden inside the shell.
Step.BAND = { t = 0.45, halfHeight = 0.25, widthScale = 0.96 } -- visible stripe ~10% of the egg height, lip ~9% of its radius
Step.SPOTS = {
	-- waist ring: 4 larger Detail spots on the diagonals (the box corners leave room for the dome)
	{ t = -0.12, azimuths = { 45, 135, 225, 315 }, radius = 0.22, protrude = 0.075, role = "Detail" },
	-- lower ring: 4 small Accent dots on the axes, where the egg is already narrower
	{ t = -0.62, azimuths = { 0, 90, 180, 270 }, radius = 0.15, protrude = 0.07, role = "Accent" },
}

local function log(fmt, ...)
	print(string.format("[post_egg_colors] " .. fmt, ...))
end

local function loadPalettes()
	local ok, palettes = pcall(function()
		return luau.load(fs.readFile(PALETTE_PATH), { debugName = PALETTE_PATH })()
	end)
	assert(ok and type(palettes) == "table", "[post_egg_colors] cannot load " .. PALETTE_PATH .. ": " .. tostring(palettes))
	return palettes
end

local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function isVisiblePart(d)
	return d:IsA("BasePart") and d.Transparency < 1
end

local function isGlowCue(d)
	return d.Material == Enum.Material.Neon or d.Material == Enum.Material.ForceField
end

local function volume(d)
	return d.Size.X * d.Size.Y * d.Size.Z
end

-- Local AABB (centre, half extents) of `part` in frame `frame`.
local function localBox(frame, part)
	local rel = frame:ToObjectSpace(part.CFrame)
	local half = part.Size * 0.5
	local r, u, l = rel.RightVector, rel.UpVector, rel.LookVector
	local ext = Vector3.new(
		math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
		math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
		math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z
	)
	return rel.Position, ext
end

-- Outer estimate of the shell radius (absolute studs) at height y (relative to the shell centre); a = half height,
-- b = half width. max(ellipsoid, egg with a round bottom of radius b and a stretched top).
local function outerRadius(y, a, b)
	local tt = math.clamp(y / a, -1, 1)
	local ell = b * math.sqrt(math.max(0, 1 - tt * tt))
	local egg = ell
	if a > b then
		local y0 = -a + b
		local c = 2 * a - b
		if y <= y0 then
			egg = math.sqrt(math.max(0, b * b - (y - y0) ^ 2))
		else
			local k = (y - y0) / c
			egg = b * math.sqrt(math.max(0, 1 - k * k))
		end
	end
	return math.max(ell, egg)
end

local function newWeld(primary, part)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "EggDecoWeld"
	weld.Part0 = primary
	weld.Part1 = part
	-- Lune gotcha: a WeldConstraint made offline keeps CFrame0 = identity unless written, and the engine would then
	-- snap Part1 onto Part0 on load. CFrame0 = Part0.CFrame:ToObjectSpace(Part1.CFrame) (verified on the base place).
	weld.CFrame0 = primary.CFrame:ToObjectSpace(part.CFrame)
	weld.Parent = part
	return weld
end

local function styleDeco(part, shell, color, role)
	part.Color = color
	part.Material = shell.Material
	part.Transparency = 0
	part.Reflectance = shell.Reflectance
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false
	part:SetAttribute(DECO_ATTR, role)
	part:SetAttribute("DontModify", true)
end

-- Keeps a decoration's local AABB inside the shell's local box (moves it inward if a rounding pushed it out).
local function clampInside(frame, part, centre, half)
	local c, e = localBox(frame, part)
	local dx, dy, dz = 0, 0, 0
	local function fix(cv, ev, sc, sh)
		local lo, hi = cv - ev, cv + ev
		if hi > sc + sh then
			return (sc + sh) - hi
		elseif lo < sc - sh then
			return (sc - sh) - lo
		end
		return 0
	end
	dx = fix(c.X, e.X, centre.X, half.X)
	dy = fix(c.Y, e.Y, centre.Y, half.Y)
	dz = fix(c.Z, e.Z, centre.Z, half.Z)
	if dx ~= 0 or dy ~= 0 or dz ~= 0 then
		part.CFrame = frame * CFrame.new(c.X + dx, c.Y + dy, c.Z + dz) * (frame:ToObjectSpace(part.CFrame) - frame:ToObjectSpace(part.CFrame).Position)
		return true
	end
	return false
end

-- Adds the band + spots to a single-mesh egg. Returns the number of parts added.
local function decorate(egg, primary, shell, palette)
	local frame = primary.CFrame - primary.CFrame.Position -- rotation of the egg (PrimaryPart axes, up = UpVector)
	local sc, sh = localBox(frame, shell) -- shell box centre / half extents in that frame
	frame = frame + frame:VectorToWorldSpace(sc) -- origin at the shell centre
	local centre = Vector3.new(0, 0, 0)
	local a = sh.Y
	local b = math.min(sh.X, sh.Z)
	local sxN, szN = sh.X / b, sh.Z / b -- elliptic cross-section factors (1 for a round egg)
	local added = 0
	local accent, detail = rgb(palette.Accent), rgb(palette.Detail)

	-- Band: a squashed clone of the shell (same mesh, so the rim follows the egg's own curvature).
	local band = shell:Clone()
	for _, c in ipairs(band:GetChildren()) do
		c:Destroy()
	end
	for name in pairs(band:GetAttributes()) do
		band:SetAttribute(name, nil)
	end
	band.Name = "EggBand"
	local rel = frame:ToObjectSpace(shell.CFrame)
	local rot = rel - rel.Position
	-- which of the shell's own axes points up in the egg frame
	local axes = { rot.RightVector, rot.UpVector, rot.LookVector }
	local upAxis, best = 1, -1
	for i, v in ipairs(axes) do
		if math.abs(v.Y) > best then
			upAxis, best = i, math.abs(v.Y)
		end
	end
	local size = { shell.Size.X, shell.Size.Y, shell.Size.Z }
	for i = 1, 3 do
		size[i] = if i == upAxis then 2 * Step.BAND.halfHeight * a else size[i] * Step.BAND.widthScale
	end
	band.Size = Vector3.new(size[1], size[2], size[3])
	band.CFrame = frame * CFrame.new(0, Step.BAND.t * a, 0) * rot
	pcall(function()
		(band :: any).UsePartColor = true
	end)
	styleDeco(band, shell, accent, "Band")
	band.Parent = egg
	clampInside(frame, band, centre, sh)
	newWeld(primary, band)
	added += 1

	-- Spots: balls sunk into the shell so only a dome of `protrude` shows over the outer surface estimate.
	local n = 0
	for _, ring in ipairs(Step.SPOTS) do
		local y = ring.t * a
		local rs = ring.radius * b
		local dist = outerRadius(y, a, b) + ring.protrude * b - rs
		for _, deg in ipairs(ring.azimuths) do
			n += 1
			local phi = math.rad(deg)
			local spot = Instance.new("Part")
			spot.Name = "EggSpot" .. n
			spot.Shape = Enum.PartType.Ball
			spot.Size = Vector3.new(2 * rs, 2 * rs, 2 * rs)
			spot.TopSurface = Enum.SurfaceType.Smooth
			spot.BottomSurface = Enum.SurfaceType.Smooth
			spot.CFrame = frame * CFrame.new(dist * math.cos(phi) * sxN, y, dist * math.sin(phi) * szN)
			styleDeco(spot, shell, if ring.role == "Accent" then accent else detail, "Spot")
			spot.Parent = egg
			clampInside(frame, spot, centre, sh)
			newWeld(primary, spot)
			added += 1
		end
	end
	return added
end

-- Paints one egg model. Returns "decorated" | "detailed" | nil (nothing visible to paint), count.
function Step.PaintEgg(egg, palette)
	-- idempotent: drop what an earlier run added (collected first: Lune errors on a destroyed instance's children)
	local stale = {}
	for _, d in ipairs(egg:GetDescendants()) do
		if d:GetAttribute(DECO_ATTR) ~= nil then
			table.insert(stale, d)
		end
	end
	for _, d in ipairs(stale) do
		local nested = false
		for _, other in ipairs(stale) do
			if other ~= d and d:IsDescendantOf(other) then
				nested = true
			end
		end
		if not nested then
			d:Destroy()
		end
	end
	local primary = egg.PrimaryPart or egg:FindFirstChild("Hitbox") or egg:FindFirstChildWhichIsA("BasePart", true)
	if primary == nil then
		return nil, 0
	end
	local visible = {}
	for _, d in ipairs(egg:GetDescendants()) do
		if isVisiblePart(d) and not isGlowCue(d) then
			table.insert(visible, d)
		end
	end
	if #visible == 0 then
		return nil, 0
	end
	table.sort(visible, function(x, y)
		local vx, vy = volume(x), volume(y)
		if vx ~= vy then
			return vx > vy
		end
		return x:GetFullName() < y:GetFullName()
	end)
	local base, accent, detail = rgb(palette.Base), rgb(palette.Accent), rgb(palette.Detail)
	local shell = visible[1]
	for i, part in ipairs(visible) do
		part.Color = if i == 1 then base elseif i == 2 then accent else (if i % 2 == 1 then detail else accent)
		if part:IsA("UnionOperation") then
			pcall(function()
				(part :: any).UsePartColor = true -- a union shows its baked colours otherwise
			end)
		end
		part:SetAttribute("DontModify", true)
	end
	if #visible > 1 then
		return "detailed", #visible - 1
	end
	return "decorated", decorate(egg, primary, shell, palette)
end

function Step.Apply(place, _spPlace, _ctx)
	local palettes = loadPalettes()
	local rs = place:GetService("ReplicatedStorage")
	local assets = rs:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	local eggs = models and models:FindFirstChild("Eggs")
	assert(eggs, "[post_egg_colors] ReplicatedStorage.Assets.Models.Eggs missing")

	local ids = {}
	for id in pairs(palettes) do
		table.insert(ids, id)
	end
	table.sort(ids)
	local decorated, detailed, parts, missing, empty, voxel = 0, 0, 0, {}, {}, 0
	for _, id in ipairs(ids) do
		local egg = eggs:FindFirstChild(id)
		if egg == nil or not egg:IsA("Model") then
			table.insert(missing, id)
		elseif egg:GetAttribute("VoxelEgg") == true then
			-- a Hero Eggs kit costume egg (post_hero_eggs) carries its own colours: never repaint it
			voxel += 1
		else
			local mode, count = Step.PaintEgg(egg, palettes[id])
			if mode == "decorated" then
				decorated += 1
				parts += count
			elseif mode == "detailed" then
				detailed += 1
			else
				table.insert(empty, id)
			end
		end
	end
	local unpainted = {}
	for _, egg in ipairs(eggs:GetChildren()) do
		if palettes[egg.Name] == nil and egg:GetAttribute("HeroId") ~= nil and egg:GetAttribute("VoxelEgg") ~= true then
			table.insert(unpainted, egg.Name)
		end
	end
	log("Painted %d hero eggs with their palettes (%s): %d single-mesh eggs got a band + spots (%d welded, non-colliding parts), %d eggs had their own detail parts repainted.",
		decorated + detailed, PALETTE_PATH, decorated, parts, detailed)
	if voxel > 0 then
		log("%d voxel costume eggs (post_hero_eggs) kept their own colours.", voxel)
	end
	if #missing > 0 then
		log("!! no egg model for: %s", table.concat(missing, ", "))
	end
	if #empty > 0 then
		log("!! egg without a visible part (left as is): %s", table.concat(empty, ", "))
	end
	if #unpainted > 0 then
		table.sort(unpainted)
		log("!! hero eggs without a palette (left as built): %s", table.concat(unpainted, ", "))
	end
end

return Step
