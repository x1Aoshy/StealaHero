--!nocheck
-- Hero eggs painted with each hero's colours (docs/HERO_MODELS_PLAN.md H4; owner EGGS).
-- Contract: scripts/data/hero_palettes.luau gives every roster hero (H.PLAN.HEROES) a Base / Accent / Detail palette;
-- scripts/steps/post_egg_colors.luau paints ReplicatedStorage.Assets.Models.Eggs.<id> with it: the shell (dominant
-- colour) = Base, a band + spots in Accent / Detail. The egg's names, PrimaryPart, pivot, size and bounding box stay
-- those of the generic egg the hero builder clones (the base place's Eggs.Chicken), and nothing collidable is added.

local roblox = H.roblox
local PLAN = H.PLAN
local place = H.place()
local rs = place:GetService("ReplicatedStorage")
local eggs = H.path(rs, "Assets/Models/Eggs")
T.check(eggs ~= nil, "ReplicatedStorage.Assets.Models.Eggs missing")

local PALETTE_PATH = "scripts/data/hero_palettes.luau"
local STEP_PATH = "scripts/steps/post_egg_colors.luau"
local COLOR_TOL = 2 -- 0-255 units per channel
local GEOM_TOL = 1e-3

---------------------------------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------------------------------
local function to255(c)
	return math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255)
end
local function sameColor(c, rgb)
	local r, g, b = to255(c)
	return math.abs(r - rgb[1]) <= COLOR_TOL and math.abs(g - rgb[2]) <= COLOR_TOL and math.abs(b - rgb[3]) <= COLOR_TOL
end
local function rgbDistance(x, y)
	return math.sqrt((x[1] - y[1]) ^ 2 + (x[2] - y[2]) ^ 2 + (x[3] - y[3]) ^ 2)
end
local function isDeco(d)
	return d:GetAttribute("EggDeco") ~= nil
end
local function isVisible(d)
	return d:IsA("BasePart") and d.Transparency < 1
end
local function isGlow(d)
	return d.Material == roblox.Enum.Material.Neon or d.Material == roblox.Enum.Material.ForceField
end
local function near(a, b, tol)
	return math.abs(a - b) <= (tol or GEOM_TOL)
end
local function nearV(a, b, tol)
	return near(a.X, b.X, tol) and near(a.Y, b.Y, tol) and near(a.Z, b.Z, tol)
end
local function nearCF(a, b, tol)
	return nearV(a.Position, b.Position, tol) and nearV(a.RightVector, b.RightVector, tol)
		and nearV(a.UpVector, b.UpVector, tol) and nearV(a.LookVector, b.LookVector, tol)
end
-- world AABB of the BaseParts of `root` accepted by `filter`
local function boundsOf(root, filter)
	local mn, mx
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") and filter(d) then
			local a, b = H.aabb(d)
			if not mn then
				mn, mx = a, b
			else
				mn = roblox.Vector3.new(math.min(mn.X, a.X), math.min(mn.Y, a.Y), math.min(mn.Z, a.Z))
				mx = roblox.Vector3.new(math.max(mx.X, b.X), math.max(mx.Y, b.Y), math.max(mx.Z, b.Z))
			end
		end
	end
	return mn, mx
end
-- non-decoration parts keyed by name|class (the geometry the step must not touch)
local function coreParts(egg)
	local out, n = {}, 0
	local primary = egg.PrimaryPart
	for _, d in ipairs(egg:GetDescendants()) do
		if d:IsA("BasePart") and not isDeco(d) then
			local key = d.Name .. "|" .. d.ClassName
			out[key] = { size = d.Size, rel = primary and primary.CFrame:ToObjectSpace(d.CFrame) or d.CFrame, cc = d.CanCollide }
			n += 1
		end
	end
	return out, n
end

---------------------------------------------------------------------------------------------------
-- 1. the palette data: every roster hero, three distinct colours, no duplicated egg
---------------------------------------------------------------------------------------------------
local okPal, palettes = pcall(function()
	return H.luau.load(H.fs.readFile(PALETTE_PATH), { debugName = PALETTE_PATH })()
end)
if not T.check(okPal and type(palettes) == "table", "%s must load and return a table (%s)", PALETTE_PATH, tostring(palettes)) then
	palettes = {}
end
local function validRgb(t)
	if type(t) ~= "table" or #t ~= 3 then
		return false
	end
	for _, v in ipairs(t) do
		if type(v) ~= "number" or v < 0 or v > 255 or v ~= math.floor(v) then
			return false
		end
	end
	return true
end
local seenScheme = {}
for _, hero in ipairs(PLAN.HEROES) do
	local id = hero[1]
	local p = palettes[id]
	if T.check(type(p) == "table", "hero_palettes: no palette for roster hero %s", id) then
		local ok = T.check(validRgb(p.Base) and validRgb(p.Accent) and validRgb(p.Detail),
			"hero_palettes.%s: Base / Accent / Detail must be {R, G, B} integers 0-255", id)
		if ok then
			T.check(rgbDistance(p.Base, p.Accent) >= 60 and rgbDistance(p.Base, p.Detail) >= 60,
				"hero_palettes.%s: Accent and Detail must stand out from Base (RGB distance >= 60)", id)
			local key = table.concat(p.Base, ",") .. "/" .. table.concat(p.Accent, ",") .. "/" .. table.concat(p.Detail, ",")
			T.check(seenScheme[key] == nil, "hero_palettes: %s and %s have the same egg colours", id, tostring(seenScheme[key]))
			seenScheme[key] = id
		end
	end
end
for id in pairs(palettes) do
	T.check(PLAN.HERO_BY_ID[id] ~= nil, "hero_palettes.%s is not a roster hero", id)
end

---------------------------------------------------------------------------------------------------
-- 2. the renderer contract the paint relies on: every egg visual clones Assets.Models.Eggs.<id>, and the runtime
--    colour-variant pass (AssetColorUtil.Apply) skips DontModify parts
---------------------------------------------------------------------------------------------------
local sources = H.allSources()
local renderer = sources["ReplicatedStorage.Library.Client.Eggs.EggRenderer"]
local colorUtil = sources["ReplicatedStorage.Library.Util.AssetColorUtil"]
if T.check(renderer ~= nil, "Library.Client.Eggs.EggRenderer missing") then
	T.check(H.has(renderer, "ReplicatedStorage.Assets.Models.Eggs") and H.has(renderer, ":Clone()"),
		"EggRenderer must render clones of ReplicatedStorage.Assets.Models.Eggs.<id> (the painted templates)")
end
if T.check(colorUtil ~= nil, "Library.Util.AssetColorUtil missing") then
	T.check(H.has(colorUtil, "GetAttribute(\"DontModify\")"),
		"AssetColorUtil.Apply must skip DontModify parts (the egg palettes rely on it)")
end

---------------------------------------------------------------------------------------------------
-- 3. every roster egg: dominant colour = palette Base, Accent + Detail present, protected from runtime recolour
---------------------------------------------------------------------------------------------------
local base = H.basePlace()
local template = base and H.path(base:GetService("ReplicatedStorage"), "Assets/Models/Eggs/Chicken")
local templateCore, templateCount = nil, 0
if template then
	templateCore, templateCount = coreParts(template)
end

-- 3a. a Hero Eggs kit costume egg (scripts/steps/post_hero_eggs.luau, attribute VoxelEgg): its own colours replace
--     the palette paint. Contract: PrimaryPart "Hitbox" = the invisible weld hub sized to the egg's box; every visible
--     part DontModify, inert, massless and welded to the Hitbox with CFrame0 written; the stud finish variant; the
--     configured height with the bottom on the pivot; model scale 1; no "eye" in part names.
local EGG_HEIGHT = 1.0 -- post_hero_eggs Step.HERO_EGG_HEIGHT
local EGG_VARIANT = "HeroEggStud"
local variantOk = false
for _, d in ipairs(place:GetService("MaterialService"):GetDescendants()) do
	if d:IsA("MaterialVariant") and d.Name == EGG_VARIANT and d.BaseMaterial == roblox.Enum.Material.SmoothPlastic then
		variantOk = true
	end
end
local voxelCount = 0
local function voxelEggChecks(id, egg)
	voxelCount += 1
	local primary = egg.PrimaryPart
	if not T.check(primary ~= nil and primary.Name == "Hitbox" and primary.Transparency >= 1 and not primary.CanCollide,
		"Eggs.%s: voxel egg PrimaryPart must be the invisible, non-colliding Hitbox", id) then
		return
	end
	local welded, visible, colors, nonNeon = {}, 0, {}, 0
	for _, w in ipairs(egg:GetDescendants()) do
		if w:IsA("WeldConstraint") and w.Part1 then
			welded[w.Part1] = (welded[w.Part1] or 0) + 1
			T.check(w.Part0 == primary and nearCF(w.CFrame0, primary.CFrame:ToObjectSpace(w.Part1.CFrame)),
				"Eggs.%s.%s: weld must hold it to the Hitbox with its offset written in CFrame0", id, w.Part1.Name)
		end
	end
	for _, d in ipairs(egg:GetDescendants()) do
		if d:IsA("BasePart") and d ~= primary then
			visible += 1
			local r, g, b = to255(d.Color)
			colors[r .. "," .. g .. "," .. b] = true
			T.check(d:GetAttribute("DontModify") == true, "Eggs.%s.%s: voxel part must carry DontModify", id, d.Name)
			T.check(not d.CanCollide and not d.CanTouch and not d.CanQuery and d.Massless,
				"Eggs.%s.%s: voxel part must be CanCollide/CanTouch/CanQuery false and Massless", id, d.Name)
			T.check(welded[d] == 1, "Eggs.%s.%s: exactly one WeldConstraint must hold the part (%d)", id, d.Name, welded[d] or 0)
			T.check(not string.find(string.lower(d.Name), "eye", 1, true), "Eggs.%s.%s: part names must not contain 'eye'", id, d.Name)
			if d.Material ~= roblox.Enum.Material.Neon then
				nonNeon += 1
				T.check(d.MaterialVariant == EGG_VARIANT, "Eggs.%s.%s: stud finish variant %s missing", id, d.Name, EGG_VARIANT)
			end
		end
	end
	local nColors = 0
	for _ in pairs(colors) do
		nColors += 1
	end
	T.check(visible >= 30 and visible <= 260, "Eggs.%s: %d voxel parts (expected 30..260)", id, visible)
	T.check(nColors >= 2 and nonNeon > 0, "Eggs.%s: a costume egg shows at least 2 colours (%d)", id, nColors)
	local mn, mx = boundsOf(egg, function(d)
		return d ~= primary
	end)
	if T.check(mn ~= nil, "Eggs.%s: no visible part", id) then
		T.check(near(mx.Y - mn.Y, EGG_HEIGHT, 0.02), "Eggs.%s: height %.3f, expected %.2f", id, mx.Y - mn.Y, EGG_HEIGHT)
		local hbMin, hbMax = H.aabb(primary)
		T.check(nearV(hbMin, mn, 0.01) and nearV(hbMax, mx, 0.01), "Eggs.%s: the Hitbox must be the egg's bounding box", id)
		local okPivot, pivot = pcall(function()
			return egg.WorldPivotData
		end)
		T.check(okPivot and near(pivot.Position.Y, mn.Y, 0.02), "Eggs.%s: the model pivot must sit at the egg's bottom", id)
	end
	local okScale, scale = pcall(function()
		return egg.Scale
	end)
	T.check(not okScale or near(scale, 1), "Eggs.%s: model scale must stay 1 (Directory.Assets asserts it)", id)
end

local decoTotal = 0
for _, hero in ipairs(PLAN.HEROES) do
	local id = hero[1]
	local p = palettes[id]
	local egg = eggs and eggs:FindFirstChild(id)
	if egg ~= nil and egg:IsA("Model") and egg:GetAttribute("VoxelEgg") == true then
		voxelEggChecks(id, egg)
	elseif T.check(egg ~= nil and egg:IsA("Model") and egg.PrimaryPart ~= nil, "Assets.Models.Eggs.%s missing (Model with PrimaryPart)", id)
		and p ~= nil and validRgb(p.Base) and validRgb(p.Accent) and validRgb(p.Detail) then
		local primary = egg.PrimaryPart
		-- dominant colour, by volume of the visible parts
		local volumeByColor, largest, largestVolume = {}, nil, -1
		local hasAccent, hasDetail, painted = false, false, 0
		for _, d in ipairs(egg:GetDescendants()) do
			if isVisible(d) then
				painted += if isGlow(d) then 0 else 1
				local v = d.Size.X * d.Size.Y * d.Size.Z
				local r, g, b = to255(d.Color)
				local key = r .. "," .. g .. "," .. b
				volumeByColor[key] = (volumeByColor[key] or 0) + v
				if v > largestVolume then
					largest, largestVolume = d, v
				end
				hasAccent = hasAccent or sameColor(d.Color, p.Accent)
				hasDetail = hasDetail or sameColor(d.Color, p.Detail)
				if not isGlow(d) then
					T.check(d:GetAttribute("DontModify") == true,
						"Eggs.%s.%s: painted part must carry DontModify (AssetColorUtil would shift its colour at runtime)", id, d.Name)
				end
			end
		end
		local domKey, domVolume, total = nil, -1, 0
		for key, v in pairs(volumeByColor) do
			total += v
			if v > domVolume then
				domKey, domVolume = key, v
			end
		end
		local dr, dg, db = string.match(domKey or "", "(%d+),(%d+),(%d+)")
		local dom = { tonumber(dr) or -1, tonumber(dg) or -1, tonumber(db) or -1 }
		T.check(rgbDistance(dom, p.Base) <= COLOR_TOL * 2 and domVolume >= 0.5 * total,
			"Eggs.%s: dominant colour %s (%.0f%% of the visible volume) must be the palette Base %s", id, tostring(domKey),
			total > 0 and domVolume / total * 100 or 0, table.concat(p.Base, ","))
		T.check(largest ~= nil and not isDeco(largest) and sameColor(largest.Color, p.Base),
			"Eggs.%s: the shell (largest visible part, %s) must be painted Base", id, largest and largest.Name or "none")
		-- (an egg with its own single detail part only has room for the Accent)
		T.check(hasAccent and (hasDetail or painted < 3), "Eggs.%s: the egg must show the palette Accent (%s) and Detail (%s) colours",
			id, table.concat(p.Accent, ","), table.concat(p.Detail, ","))

		-- decorations: non-colliding, welded to the PrimaryPart with the offset written, inside the shell's box
		for _, d in ipairs(egg:GetDescendants()) do
			if d:IsA("BasePart") and isDeco(d) then
				decoTotal += 1
				T.check(not d.CanCollide and not d.CanTouch and not d.CanQuery and d.Massless and not d.Anchored,
					"Eggs.%s.%s: decoration must be CanCollide/CanTouch/CanQuery false, Massless, unanchored", id, d.Name)
				local welds = 0
				for _, w in ipairs(egg:GetDescendants()) do
					if w:IsA("WeldConstraint") and w.Part1 == d then
						welds += 1
						T.check(w.Part0 == primary, "Eggs.%s.%s: weld must hold it to the PrimaryPart", id, d.Name)
						T.check(nearCF(w.CFrame0, primary.CFrame:ToObjectSpace(d.CFrame)),
							"Eggs.%s.%s: WeldConstraint.CFrame0 must be the part's offset (the engine snaps it onto the PrimaryPart otherwise)", id, d.Name)
					end
				end
				T.check(welds == 1, "Eggs.%s.%s: exactly one WeldConstraint must hold the decoration (%d)", id, d.Name, welds)
				T.check(not string.find(string.lower(d.Name), "eye", 1, true),
					"Eggs.%s.%s: decoration names must not contain 'eye' (AssetColorUtil treats those as eyes)", id, d.Name)
			end
		end
		for _, d in ipairs(egg:GetDescendants()) do
			if d:IsA("BasePart") and d.CanCollide then
				T.check(not isDeco(d), "Eggs.%s.%s: nothing collidable may be added to an egg", id, d.Name)
			end
		end
		local mnAll, mxAll = boundsOf(egg, function()
			return true
		end)
		local mnCore, mxCore = boundsOf(egg, function(d)
			return not isDeco(d)
		end)
		T.check(mnAll ~= nil and mnCore ~= nil and nearV(mnAll, mnCore) and nearV(mxAll, mxCore),
			"Eggs.%s: decorations must stay inside the egg's bounding box (nest sizing / egg bottom use it)", id)

		-- visible and attached: every spot pokes out of the ellipsoid inscribed in the shell's box and its centre is
		-- inside it; the band reaches past that ellipsoid at its height
		local shell = largest
		if shell and not isDeco(shell) then
			-- half extents of `part` along the axes of the rotation-only frame `frame`
			local function extents(frame, part)
				local rel = frame:ToObjectSpace(part.CFrame)
				local half = part.Size * 0.5
				local r, u, l = rel.RightVector, rel.UpVector, rel.LookVector
				return math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
					math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
					math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z,
					rel.Position
			end
			local frame = primary.CFrame - primary.CFrame.Position
			local hx, hy, hz, centre = extents(frame, shell)
			local origin = frame + frame:VectorToWorldSpace(centre)
			local function f(x, y, z)
				return (x / hx) ^ 2 + (y / hy) ^ 2 + (z / hz) ^ 2
			end
			for _, d in ipairs(egg:GetDescendants()) do
				if d:IsA("BasePart") and isDeco(d) then
					local c = origin:PointToObjectSpace(d.CFrame.Position)
					if d:GetAttribute("EggDeco") == "Band" then
						local bx, _, bz = extents(frame, d)
						T.check(f(bx, c.Y, 0) > 1 and f(0, c.Y, bz) > 1,
							"Eggs.%s.%s: the band must reach past the shell surface at its height", id, d.Name)
					else
						local radius = d.Size.X * 0.5
						local len = math.sqrt(c.X * c.X + c.Z * c.Z)
						local ox, oz = len > 0 and c.X / len * radius or 0, len > 0 and c.Z / len * radius or 0
						T.check(f(c.X + ox, c.Y, c.Z + oz) > 1 and f(c.X, c.Y, c.Z) < 1,
							"Eggs.%s.%s: the spot must be sunk into the shell with a dome showing", id, d.Name)
					end
				end
			end
		end

		-- names / pivot / size unchanged: while the builder still clones the generic egg (base place Eggs.Chicken), the
		-- non-decoration parts are exactly the generic egg's (section 5 checks the step itself on a pristine clone)
		local okScale, scale = pcall(function()
			return egg.Scale
		end)
		T.check(not okScale or near(scale, 1), "Eggs.%s: model scale must stay 1 (Directory.Assets asserts it)", id)
		local core, count = coreParts(egg)
		local sameParts = templateCore ~= nil and count == templateCount
		if sameParts then
			for key in pairs(templateCore) do
				sameParts = sameParts and core[key] ~= nil
			end
		end
		if sameParts then
			T.check(primary.Name == template.PrimaryPart.Name, "Eggs.%s: PrimaryPart %s, the generic egg's is %s", id, primary.Name,
				template.PrimaryPart.Name)
			T.check(nearCF(primary.PivotOffset, template.PrimaryPart.PivotOffset), "Eggs.%s: PrimaryPart.PivotOffset changed", id)
			for key, t in pairs(templateCore) do
				local c = core[key]
				T.check(nearV(c.size, t.size), "Eggs.%s: %s size changed", id, key)
				T.check(nearCF(c.rel, t.rel), "Eggs.%s: %s moved relative to the PrimaryPart", id, key)
				T.check(c.cc == t.cc, "Eggs.%s: %s CanCollide changed", id, key)
			end
		elseif templateCore then
			print(string.format("   (suite_eggs) Eggs.%s is no longer a clone of the generic egg: template comparison skipped", id))
		end
	end
end
T.check(decoTotal > 0 or voxelCount > 0 or (eggs ~= nil and #eggs:GetChildren() == 0), "no egg decoration found (post_egg_colors did not run?)")
if voxelCount > 0 then
	T.check(variantOk, "MaterialService.%s (SmoothPlastic) missing: the voxel eggs' stud finish", EGG_VARIANT)
	T.check(voxelCount == #PLAN.HEROES, "only %d of %d roster eggs are voxel costume eggs", voxelCount, #PLAN.HEROES)
	local bossEggs = H.path(rs, "Assets/Models/BossEggs")
	if T.check(bossEggs ~= nil, "Assets.Models.BossEggs missing (the 6 boss costume eggs)") then
		for _, id in ipairs({ "Thanos", "Darkseid", "Carnage", "Shigaraki", "Frieza", "Kaido" }) do
			local egg = bossEggs:FindFirstChild(id)
			T.check(egg ~= nil and egg:IsA("Model") and egg.PrimaryPart ~= nil and egg:GetAttribute("VoxelEgg") == true,
				"BossEggs.%s missing (voxel Model with PrimaryPart)", id)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 4. the step is idempotent: running it again on the built place changes nothing
---------------------------------------------------------------------------------------------------
local mods = { ["@lune/fs"] = H.fs, ["@lune/luau"] = H.luau, ["@lune/roblox"] = H.roblox }
local chunk, err = H.sandbox(H.fs.readFile(STEP_PATH), {
	require = function(path)
		return assert(mods[path], "unexpected require " .. tostring(path))
	end,
}, STEP_PATH)
if T.check(chunk ~= nil, "%s must compile: %s", STEP_PATH, tostring(err)) then
	local okStep, Step = pcall(chunk)
	if T.check(okStep and type(Step) == "table" and type(Step.Apply) == "function", "%s must return a step with Apply", STEP_PATH) then
		local fresh = H.freshPlace()
		local freshEggs = H.path(fresh:GetService("ReplicatedStorage"), "Assets/Models/Eggs")
		local function snapshot(folder)
			local rows = {}
			for _, egg in ipairs(folder:GetChildren()) do
				local primary = egg.PrimaryPart
				for _, d in ipairs(egg:GetDescendants()) do
					if d:IsA("BasePart") then
						local rel = primary and primary.CFrame:ToObjectSpace(d.CFrame) or d.CFrame
						local r, g, b = to255(d.Color)
						table.insert(rows, string.format("%s/%s|%s|%d,%d,%d|%.3f,%.3f,%.3f|%.3f,%.3f,%.3f|%s", egg.Name, d.Name, d.ClassName,
							r, g, b, d.Size.X, d.Size.Y, d.Size.Z, rel.Position.X, rel.Position.Y, rel.Position.Z, tostring(d.CanCollide)))
					end
				end
			end
			table.sort(rows)
			return table.concat(rows, "\n"), #rows
		end
		if T.check(freshEggs ~= nil, "fresh place without Assets.Models.Eggs") then
			local before, n = snapshot(freshEggs)
			local okApply, applyErr = pcall(Step.Apply, fresh, nil, {})
			if T.check(okApply, "re-running %s failed: %s", STEP_PATH, tostring(applyErr)) then
				local after, m = snapshot(freshEggs)
				T.check(before == after, "%s is not idempotent: a second run changed the eggs (%d parts before, %d after)", STEP_PATH, n, m)
			end
		end

		-------------------------------------------------------------------------------------------------
		-- 5. the step on a pristine generic egg (base place Eggs.Chicken, what the builder clones): names, PrimaryPart,
		--    pivot, part sizes / offsets / collision and the bounding box are untouched; a band + spots are added
		-------------------------------------------------------------------------------------------------
		if template and type(Step.PaintEgg) == "function" and palettes.Hulk then
			local folder = roblox.Instance.new("Folder")
			local egg = template:Clone()
			egg.Parent = folder
			local coreBefore, countBefore = coreParts(egg)
			local mnBefore, mxBefore = boundsOf(egg, function()
				return true
			end)
			local pivotBefore = egg.PrimaryPart and egg.PrimaryPart.PivotOffset
			local okPaint, mode = pcall(Step.PaintEgg, egg, palettes.Hulk)
			if T.check(okPaint, "PaintEgg on the generic egg failed: %s", tostring(mode)) then
				local coreAfter, countAfter = coreParts(egg)
				T.check(countAfter == countBefore, "PaintEgg changed the generic egg's own parts (%d -> %d)", countBefore, countAfter)
				for key, t in pairs(coreBefore) do
					local c = coreAfter[key]
					if T.check(c ~= nil, "PaintEgg removed / renamed the generic egg's %s", key) then
						T.check(nearV(c.size, t.size) and nearCF(c.rel, t.rel) and c.cc == t.cc,
							"PaintEgg changed the size / offset / CanCollide of the generic egg's %s", key)
					end
				end
				T.check(egg.PrimaryPart ~= nil and egg.PrimaryPart.Name == template.PrimaryPart.Name
					and nearCF(egg.PrimaryPart.PivotOffset, pivotBefore), "PaintEgg changed the egg's PrimaryPart / pivot")
				local mnAfter, mxAfter = boundsOf(egg, function()
					return true
				end)
				T.check(nearV(mnAfter, mnBefore) and nearV(mxAfter, mxBefore), "PaintEgg grew the generic egg's bounding box")
				local deco, bands = 0, 0
				for _, d in ipairs(egg:GetDescendants()) do
					if d:IsA("BasePart") and isDeco(d) then
						deco += 1
						bands += if d:GetAttribute("EggDeco") == "Band" then 1 else 0
					end
				end
				T.check(mode == "decorated" and bands == 1 and deco >= 4,
					"a single-mesh egg must get a band and spots (%s: %d parts, %d band)", tostring(mode), deco, bands)
				local once = snapshot(folder)
				Step.PaintEgg(egg, palettes.Hulk)
				T.check(snapshot(folder) == once, "PaintEgg is not idempotent on the generic egg")
			end
			folder:Destroy()
		end
	end
end
