--!nocheck
-- scripts/tools/build_vfx_library.luau
-- Builds a standalone "VFX Library" place: every model / part / effect set that carries visual effects
-- (ParticleEmitter, Beam, Trail, Fire, Smoke, Sparkles) found in
--   * V40 SAB (the full reference place, reference/V40 SAB by FaypleStudios.rbxl; else vendor/sab_vfx.rbxl),
--   * Steal a Hero (StealaHero.rbxl, the hero models, the treadmill skins) and its Steal an Egg base place,
--   * Speedsters (the three worlds, AURAS/, src/assets, src/ui, design/ kits and the loose kits at its root),
-- de-duplicated (byte-identical subtrees are kept once) and laid out on labelled pedestals, one hall per origin,
-- so the owner can open it in Studio and save any of them (right-click > Save to File / Save to Roblox).
--
--   lune run scripts/tools/build_vfx_library.luau [--v40=<V40 place>] [--speedsters=<dir>] [--out=<rbxl>]
--   env: SAB_V40_PLACE, SPEEDSTERS_DIR, VFX_LIBRARY_OUT
--
-- The place:
--   Workspace.VfxLibrary.<Hall>.<Category>.<Item>   the assets, moved onto their pedestals. Nothing else is changed,
--                                                   except that server Scripts inside are Disabled (ScriptsDisabled)
--                                                   and area volumes are scaled previews (ScaledPreview, RealSize).
--   Workspace.VfxLibraryDisplay                     pedestals, labels and hall signs (not part of any asset)
--   ServerStorage.VfxLibraryOriginals.<Hall>...     untouched copies of the items the showcase changes: those that
--                                                   carry server Scripts, and area volumes (weather / map effects up
--                                                   to 2000 studs) shown as a preview scaled to PREVIEW_SIZE
--   ServerScriptService.VfxLibraryPreviewer         Play-mode only: anchors the showcase, silences it and replays the
--                                                   burst emitters (Enabled = false, fired by code in their games)
-- Loose effects (a lone Attachment / emitter / Beam / Trail, or a Folder of them) cannot render on their own: the item
-- is then a Model holding the untouched effect plus a "_Preview" host part with a copy that renders.

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local serde = require("@lune/serde")

local Instance, Vector3, CFrame, Color3, UDim2 = roblox.Instance, roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.UDim2
local Enum = roblox.Enum

local args = {}
for _, a in process.args do
	local k, v = string.match(a, "^%-%-([%w_]+)=(.*)$")
	if k then
		args[k] = v
	end
end

local OWNER_UPDATE2 = "c:/Users/Aoshy´/Desktop/Update2"
local V40_NAME = "Outdated/V40 SAB by FaypleStudios.rbxl"

local function firstDir(list)
	for _, p in list do
		if p and p ~= "" and fs.isDir(p) then
			return p
		end
	end
	return nil
end
local function firstFile(list)
	for _, p in list do
		if p and p ~= "" and fs.isFile(p) then
			return p
		end
	end
	return nil
end

local SPEEDSTERS = firstDir({ args.speedsters, process.env.SPEEDSTERS_DIR, "../Speedsters", OWNER_UPDATE2 })
local V40_FULL = firstFile({
	args.v40,
	process.env.SAB_V40_PLACE,
	"reference/V40 SAB by FaypleStudios.rbxl",
	SPEEDSTERS and (SPEEDSTERS .. "/" .. V40_NAME),
	OWNER_UPDATE2 .. "/" .. V40_NAME,
})
local OUT = args.out or process.env.VFX_LIBRARY_OUT or "assets/vfx_library/VfxLibrary.rbxl"
local MANIFEST = string.gsub(OUT, "%.rbxl$", "") .. "_manifest.json"

----------------------------------------------------------------------
-- Rules
----------------------------------------------------------------------
local FX = { ParticleEmitter = true, Beam = true, Trail = true, Fire = true, Smoke = true, Sparkles = true }
-- Parents that only file assets; the asset is the first node below them that is not one of these.
local CONTAINER = {
	Folder = true,
	Configuration = true,
	ModuleScript = true,
	Script = true,
	LocalScript = true,
	Terrain = true,
	Camera = true,
}
local SKIP_SERVICES = { StarterGui = true, CoreGui = true, Players = true }
-- A unit bigger than this (a whole map, a building) is not "a model with VFX": descend to the effect's own model.
local MAX_UNIT_PARTS = 150
local MAX_UNIT_EXTENT = 200 -- studs, for Models
-- Assets wider than this (weather / sky / map volumes, up to 2000 studs) are shown as a preview scaled down to
-- PREVIEW_SIZE; the untouched full-size copy is in ServerStorage.VfxLibraryOriginals.
local AREA_EFFECT_SIZE = 120
local PREVIEW_SIZE = 40
-- Names that say nothing on their own: the item is shown as "<Parent> <Name>".
local GENERIC = {
	[""] = true,
	Part = true,
	Model = true,
	MeshPart = true,
	Main = true,
	fx = true,
	Rig = true,
	Template = true,
	Default = true,
	VfxInstance = true,
	Attachment = true,
	ParticleEmitter = true,
	Handle = true,
	Effect = true,
	Effects = true,
	VFX = true,
}
-- Scripts that fetch or run remote code (free-model backdoors): stripped everywhere and reported.
local SUSPICIOUS = { "require%s*%(%s*%d%d%d%d", "loadstring", "getfenv", "setfenv" }

-- Halls, in the order they are laid out (sources keep their own priority order for de-duplication: an asset
-- V40 and a game share byte for byte is shown once, in the V40 hall, and the game is listed in AlsoIn).
local HALLS = {
	{ key = "SAH", name = "Steal a Hero", color = Color3.fromRGB(80, 170, 255) },
	{ key = "SAE", name = "Steal an Egg (base)", color = Color3.fromRGB(120, 220, 120) },
	{ key = "SP", name = "Speedsters", color = Color3.fromRGB(255, 90, 90) },
	{ key = "V40", name = "V40 (Steal a Brainrot)", color = Color3.fromRGB(255, 196, 64) },
}
local HALL_BY_KEY = {}
for i, h in HALLS do
	h.index = i
	HALL_BY_KEY[h.key] = h
end

-- Material that came from the V40 SAB place, wherever it was found (ports and captures): shown in the V40 hall.
local V40_PATHS = {
	"^ReplicatedStorage/Assets/VFX/SAB/",
	"^ReplicatedStorage/Shared/TacoEventAssets/",
	"^ReplicatedStorage/Shared/TacoMeteorAssets/",
	"^ReplicatedStorage/VfxTemplates/",
	"^TacoEventAssets%.rbxm:",
	"^TacoMeteorAssets%.rbxm:",
	"^VfxTemplates%.rbxm:",
}

----------------------------------------------------------------------
-- Sources (priority order: the first copy of an asset wins, later copies are listed as "also in")
----------------------------------------------------------------------
local function walk(dir, pattern, out)
	if not fs.isDir(dir) then
		return out
	end
	local names = fs.readDir(dir)
	table.sort(names)
	for _, name in names do
		local p = dir .. "/" .. name
		if fs.isDir(p) then
			walk(p, pattern, out)
		elseif string.match(string.lower(name), pattern) then
			table.insert(out, p)
		end
	end
	return out
end

local sources = {}
local function add(path, hall, family, label)
	if fs.isFile(path) then
		table.insert(sources, { path = path, hall = hall, family = family, label = label })
	end
end

if V40_FULL then
	add(V40_FULL, "V40", "v40", "V40 SAB by FaypleStudios.rbxl")
else
	add("vendor/sab_vfx.rbxl", "V40", "v40", "vendor/sab_vfx.rbxl (V40 subset)")
end
add("StealaHero.rbxl", "SAH", "sah", "StealaHero.rbxl")
for _, p in walk("assets/hero_models", "%.rbxm$", {}) do
	add(p, "SAH", "sah-" .. p, string.gsub(p, "^assets/", ""))
end
add("Treadmills.rbxl", "SAH", "sah-treadmills", "Treadmills.rbxl")
for _, p in walk("assets/models/bases", "%.rbxm$", {}) do
	add(p, "SAH", "sah-" .. p, string.gsub(p, "^assets/models/", ""))
end
add("Steal An Egg with treadmill V2.rbxl", "SAE", "sah", "Steal An Egg with treadmill V2.rbxl")
if SPEEDSTERS then
	for _, w in { "World1Update3New.rbxl", "World2Update3new.rbxl", "World3Update3New.rbxl" } do
		add(SPEEDSTERS .. "/" .. w, "SP", "sp", w)
	end
	local kits = {}
	for _, dir in { "src/assets", "src/ui", "AURAS", "design", "assets/vfx_imported" } do
		walk(SPEEDSTERS .. "/" .. dir, "%.rbx[ml]$", kits)
	end
	local rootNames = fs.readDir(SPEEDSTERS)
	table.sort(rootNames)
	for _, name in rootNames do
		if string.match(string.lower(name), "%.rbxm$") then
			table.insert(kits, SPEEDSTERS .. "/" .. name)
		end
	end
	for _, p in kits do
		local rel = string.sub(p, #SPEEDSTERS + 2)
		add(p, "SP", "sp-" .. rel, rel)
	end
end

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function get(inst, prop)
	local ok, value = pcall(function()
		return inst[prop]
	end)
	return if ok then value else nil
end

local function chainOf(inst)
	local c = {}
	local n = inst
	while n and n.ClassName ~= "DataModel" do
		table.insert(c, 1, n)
		n = n.Parent
	end
	return c
end

local partCountCache = {}
local function partCount(inst)
	local c = partCountCache[inst]
	if c then
		return c
	end
	c = if inst:IsA("BasePart") then 1 else 0
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			c += 1
		end
	end
	partCountCache[inst] = c
	return c
end

local function bboxOf(inst)
	local minV, maxV
	local list = inst:GetDescendants()
	table.insert(list, 1, inst)
	for _, d in list do
		if d:IsA("BasePart") then
			local cf, size = d.CFrame, d.Size
			local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local p = cf * Vector3.new(sx * hx, sy * hy, sz * hz)
						if not minV then
							minV, maxV = p, p
						else
							minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
							maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
						end
					end
				end
			end
		end
	end
	return minV, maxV
end

-- Largest side of a non-part asset's bounds (a Model spread over a map is not one prop).
local extentCache = {}
local function extentOf(inst)
	local e = extentCache[inst]
	if e then
		return e
	end
	local minV, maxV = bboxOf(inst)
	e = if minV then math.max(maxV.X - minV.X, maxV.Y - minV.Y, maxV.Z - minV.Z) else 0
	extentCache[inst] = e
	return e
end

local function oversized(inst)
	return partCount(inst) > MAX_UNIT_PARTS or (not inst:IsA("BasePart") and extentOf(inst) > MAX_UNIT_EXTENT)
end

local function hasPhysical(inst)
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Model") then
			return true
		end
	end
	return false
end

local function isUiHosted(chain)
	for _, n in chain do
		if n:IsA("LayerCollector") or n:IsA("GuiObject") then
			return true
		end
	end
	return false
end

local function countFx(inst)
	local n = if FX[inst.ClassName] then 1 else 0
	for _, d in inst:GetDescendants() do
		if FX[d.ClassName] then
			n += 1
		end
	end
	return n
end

local function roundCFrame(cf)
	local c = { cf:GetComponents() }
	for i, v in c do
		c[i] = math.floor(v * 1000 + 0.5) / 1000
	end
	return CFrame.new(table.unpack(c))
end

-- Identity of an asset for de-duplication: its serialized bytes once moved to the origin (relative to its
-- PrimaryPart / first part), so the same prop placed 14 times along a map is kept once.
local function fingerprint(inst)
	local copy = inst:Clone()
	local ref = if copy:IsA("BasePart") then copy else (get(copy, "PrimaryPart") or copy:FindFirstChildWhichIsA("BasePart", true))
	if ref then
		local inv = ref.CFrame:Inverse()
		local list = copy:GetDescendants()
		table.insert(list, 1, copy)
		for _, d in list do
			if d:IsA("BasePart") then
				d.CFrame = roundCFrame(inv * d.CFrame)
			elseif d:IsA("Model") then
				local pivot = get(d, "WorldPivotData")
				if pivot then
					d.WorldPivotData = roundCFrame(inv * pivot)
				end
			end
		end
	end
	local ok, bytes = pcall(roblox.serializeModel, { copy })
	copy:Destroy()
	if not ok then
		return nil
	end
	return serde.hash("sha256", bytes)
end

-- Finds the asset that owns an effect: the first non-container node from the top of its chain; when that is a whole
-- map (more than MAX_UNIT_PARTS parts, or a Model wider than MAX_UNIT_EXTENT), the first smaller node on the way down to the effect. A lone attachment or
-- emitter filed in a Folder of effects only is promoted to that Folder (an effect set, e.g. Mutation_FX/Candy).
local function unitOf(effect, isPlace)
	local chain = chainOf(effect)
	if isPlace and (#chain < 2 or SKIP_SERVICES[chain[1].ClassName]) then
		return nil
	end
	if isUiHosted(chain) then
		return nil
	end
	local start = if isPlace then 2 else 1
	local idx
	for i = start, #chain do
		if not CONTAINER[chain[i].ClassName] then
			idx = i
			break
		end
	end
	if not idx then
		return nil
	end
	if oversized(chain[idx]) then
		local found
		for i = idx + 1, #chain do
			if not CONTAINER[chain[i].ClassName] and not oversized(chain[i]) then
				found = i
				break
			end
		end
		idx = found or #chain
	end
	local unit = chain[idx]
	if (unit:IsA("Attachment") or FX[unit.ClassName]) and unit.Parent and unit.Parent.ClassName == "Folder" then
		local folder = unit.Parent
		-- (a Folder at the root of a .rbxm counts; a service never does)
		if (folder.Parent == nil or folder.Parent.ClassName ~= "DataModel") and not hasPhysical(folder) then
			unit = folder
			idx -= 1
		end
	end
	return unit, chain, start, idx
end

local function joinNames(chain, i, j)
	local names = {}
	for k = i, j do
		table.insert(names, chain[k].Name)
	end
	return table.concat(names, "/")
end

local function hallFor(source, sourcePath)
	for _, pat in V40_PATHS do
		if string.match(sourcePath, pat) then
			return "V40"
		end
	end
	return source.hall
end

local SERVICE_NAMES = { ReplicatedStorage = true, ServerStorage = true, Workspace = true, ReplicatedFirst = true, Lighting = true }

local CATEGORY_ALIASES = { ["__AssetLibrary / m"] = "Brainrots (__AssetLibrary)" }

local function displayCategory(path, depth)
	local segs = string.split(path, "/")
	if #segs == 1 then
		return if SERVICE_NAMES[segs[1]] then (segs[1] .. " (misc)") else segs[1]
	end
	local keep = {}
	for i = math.max(1, #segs - depth + 1), #segs do
		if not (i == 1 and SERVICE_NAMES[segs[i]] and #segs > 1) then
			table.insert(keep, segs[i])
		end
	end
	-- "Workspace/Folder" reads better than "Folder"
	if #keep == 1 and (GENERIC[keep[1]] or keep[1] == "Folder") and #segs >= 2 then
		table.insert(keep, 1, segs[#segs - 1])
	end
	return table.concat(keep, " / ")
end

-- Categories with fewer than MIN_PER_CATEGORY items fold into their parent folder (deepest first), then take a
-- short display name (the last two folders; three when two collide).
local MIN_PER_CATEGORY = 3
local function assignCategories(list)
	for _, item in list do
		item.catPath = item.categoryPath
	end
	while true do
		local counts = {}
		for _, item in list do
			counts[item.catPath] = (counts[item.catPath] or 0) + 1
		end
		local deepest = 0
		for path, n in counts do
			local depth = #string.split(path, "/")
			if n < MIN_PER_CATEGORY and depth > 1 then
				deepest = math.max(deepest, depth)
			end
		end
		if deepest == 0 then
			break
		end
		for _, item in list do
			local depth = #string.split(item.catPath, "/")
			if depth == deepest and counts[item.catPath] < MIN_PER_CATEGORY then
				item.catPath = string.match(item.catPath, "^(.*)/[^/]+$")
			end
		end
	end
	local owner = {}
	for _, item in list do
		local name = displayCategory(item.catPath, 2)
		if owner[name] and owner[name] ~= item.catPath then
			name = displayCategory(item.catPath, 3)
		end
		name = CATEGORY_ALIASES[name] or name
		owner[name] = owner[name] or item.catPath
		item.category = name
	end
end

----------------------------------------------------------------------
-- 1. Collect
----------------------------------------------------------------------
local items = {} -- in discovery order
local byFingerprint = {}
local byFamilyPath = {}
local suspicious = {}
local skipped = { duplicate = 0, samePath = 0, unserializable = 0 }
local perSource = {}

for _, source in sources do
	local isPlace = string.match(string.lower(source.path), "%.rbxl$") ~= nil
	local ok, roots = pcall(function()
		if isPlace then
			return roblox.deserializePlace(fs.readFile(source.path)):GetChildren()
		end
		return roblox.deserializeModel(fs.readFile(source.path))
	end)
	if not ok then
		print(string.format("[vfx_library] cannot read %s: %s", source.path, tostring(roots)))
		continue
	end
	local fileTag = string.match(source.path, "([^/]+)$")
	local seenUnits = {}
	local added, dup = 0, 0
	for _, root in roots do
		local list = root:GetDescendants()
		table.insert(list, 1, root)
		for _, d in list do
			if not FX[d.ClassName] then
				continue
			end
			local unit, chain, start, idx = unitOf(d, isPlace)
			if not unit or seenUnits[unit] then
				continue
			end
			seenUnits[unit] = true
			local unitChain = chainOf(unit)
			local inner = joinNames(unitChain, 1, #unitChain)
			local sourcePath = if isPlace then inner else (fileTag .. ":" .. inner)
			local fp = fingerprint(unit)
			if not fp then
				skipped.unserializable += 1
				continue
			end
			local prior = byFingerprint[fp]
			if prior then
				table.insert(prior.alsoIn, source.label .. " :: " .. sourcePath)
				skipped.duplicate += 1
				dup += 1
				continue
			end
			local famKey = source.family .. "|" .. sourcePath
			local famPrior = byFamilyPath[famKey]
			if famPrior and famPrior.sourceFile ~= source.path then
				-- Same asset path in a sibling place (World2/3 vs World1, the Steal an Egg base vs Steal a Hero):
				-- the first (current) one stands.
				table.insert(famPrior.alsoIn, source.label .. " :: " .. sourcePath .. " (variant)")
				skipped.samePath += 1
				dup += 1
				continue
			end
			-- Category: the containers above the unit (and the oversized map it was cut from).
			local catEnd = idx - 1
			local categoryPath = if catEnd >= 1 then joinNames(chain, 1, catEnd) else ""
			if not isPlace then
				categoryPath = "Kit files/" .. (if categoryPath == "" then fileTag else (fileTag .. "/" .. categoryPath))
			end
			local item = {
				unit = unit,
				source = source,
				sourceFile = source.path,
				sourcePath = sourcePath,
				hall = hallFor(source, sourcePath),
				categoryPath = categoryPath,
				fx = countFx(unit),
				parts = partCount(unit),
				alsoIn = {},
				fingerprint = fp,
			}
			if item.hall ~= source.hall then
				item.foundIn = source.label
			end
			byFingerprint[fp] = item
			byFamilyPath[famKey] = item
			table.insert(items, item)
			added += 1
		end
	end
	perSource[source.label] = { added = added, duplicates = dup }
	print(string.format("[vfx_library] %-58s +%d items (%d duplicates)", source.label, added, dup))
end

----------------------------------------------------------------------
-- 2. Build the place
----------------------------------------------------------------------
local game = Instance.new("DataModel")
local workspace = game:GetService("Workspace")
local serverStorage = game:GetService("ServerStorage")
local sss = game:GetService("ServerScriptService")
local lighting = game:GetService("Lighting")

lighting.ClockTime = 20
lighting.Brightness = 1.5
lighting.Ambient = Color3.fromRGB(110, 110, 125)
lighting.OutdoorAmbient = Color3.fromRGB(125, 125, 140)
lighting.GlobalShadows = false

local FONT_BOLD = roblox.Font.fromEnum(Enum.Font.FredokaOne)
local FONT_BODY = roblox.Font.fromEnum(Enum.Font.GothamMedium)

local libraryRoot = Instance.new("Folder")
libraryRoot.Name = "VfxLibrary"
libraryRoot.Parent = workspace
local displayRoot = Instance.new("Folder")
displayRoot.Name = "VfxLibraryDisplay"
displayRoot.Parent = workspace
local originalsRoot = Instance.new("Folder")
originalsRoot.Name = "VfxLibraryOriginals"
originalsRoot.Parent = serverStorage

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		if k == "Position" then
			-- Lune: Position is not serialized, only CFrame places a part
			p.CFrame = CFrame.new(v)
		else
			p[k] = v
		end
	end
	return p
end

local function billboard(adornee, lines, sizeStuds, offsetY, maxDistance, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.new(sizeStuds.X, 0, sizeStuds.Y, 0)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	local n = #lines
	for i, line in lines do
		local t = Instance.new("TextLabel")
		t.Name = "Line" .. i
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, 0, if i == 1 then 0.6 else 0.4 / (n - 1), 0)
		t.Position = UDim2.new(0, 0, if i == 1 then 0 else 0.6 + (i - 2) * 0.4 / (n - 1), 0)
		t.Text = line
		t.TextScaled = true
		t.TextWrapped = true
		t.TextColor3 = if i == 1 then Color3.fromRGB(255, 255, 255) else (color or Color3.fromRGB(210, 210, 220))
		t.TextStrokeTransparency = 0.35
		t.FontFace = if i == 1 then FONT_BOLD else FONT_BODY
		t.Parent = gui
	end
	gui.Parent = adornee
	return gui
end

local function translate(inst, delta)
	local list = inst:GetDescendants()
	table.insert(list, 1, inst)
	for _, d in list do
		if d:IsA("BasePart") then
			d.CFrame = d.CFrame + delta
		elseif d:IsA("Model") then
			local pivot = get(d, "WorldPivotData")
			if pivot then
				d.WorldPivotData = pivot + delta
			end
		end
	end
end

local function rotationOf(cf)
	return cf - cf.Position
end

-- Scales an asset about `centre` (parts, meshes, attachments, joints, pivots); used only for area previews.
local function scaleAbout(inst, k, centre)
	local list = inst:GetDescendants()
	table.insert(list, 1, inst)
	for _, d in list do
		if d:IsA("BasePart") then
			local cf = d.CFrame
			local size = d.Size * k
			d.Size = Vector3.new(math.max(size.X, 0.001), math.max(size.Y, 0.001), math.max(size.Z, 0.001))
			d.CFrame = CFrame.new(centre + (cf.Position - centre) * k) * rotationOf(cf)
		elseif d:IsA("Attachment") then
			local cf = d.CFrame
			d.CFrame = CFrame.new(cf.Position * k) * rotationOf(cf)
		elseif d:IsA("JointInstance") then
			local c0, c1 = get(d, "C0"), get(d, "C1")
			if c0 then
				d.C0 = CFrame.new(c0.Position * k) * rotationOf(c0)
			end
			if c1 then
				d.C1 = CFrame.new(c1.Position * k) * rotationOf(c1)
			end
		elseif d:IsA("SpecialMesh") then
			if get(d, "MeshType") == Enum.MeshType.FileMesh then
				d.Scale = d.Scale * k
			end
			d.Offset = d.Offset * k
		elseif d:IsA("Model") then
			local pivot = get(d, "WorldPivotData")
			if pivot then
				d.WorldPivotData = CFrame.new(centre + (pivot.Position - centre) * k) * rotationOf(pivot)
			end
		end
	end
end

local function scriptsOf(inst)
	local out = {}
	for _, d in inst:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			table.insert(out, d)
		end
	end
	return out
end

-- Loose effects get a host part that renders a copy of them.
local function buildPreview(item, clone)
	local host = part({
		Name = "_Preview",
		Size = Vector3.new(2, 2, 2),
		Transparency = 1,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
	})
	local copy = clone:Clone()
	copy.Parent = host
	local moved = {}
	local candidates = copy:GetDescendants()
	table.insert(candidates, 1, copy)
	for _, d in candidates do
		local parentOk = d.Parent and (d.Parent:IsA("BasePart") or d.Parent:IsA("Attachment"))
		if d:IsA("Attachment") and not (d.Parent and d.Parent:IsA("BasePart")) then
			table.insert(moved, d)
		elseif FX[d.ClassName] and not parentOk then
			table.insert(moved, d)
		end
	end
	for _, d in moved do
		d.Parent = host
	end
	if copy.Parent == host and copy.ClassName == "Folder" then
		copy:Destroy()
	end
	-- Recentre the attachments on the host (a Terrain attachment carries world coordinates).
	local atts = {}
	for _, c in host:GetChildren() do
		if c:IsA("Attachment") then
			table.insert(atts, c)
		end
	end
	if #atts > 0 then
		local sum = Vector3.new(0, 0, 0)
		for _, a in atts do
			sum += a.CFrame.Position
		end
		local centre = sum / #atts
		for _, a in atts do
			a.CFrame = a.CFrame - centre
		end
	end
	-- A lone Beam needs two ends, a lone Trail needs to move (the previewer spins the host).
	local needsSpin = false
	for _, c in host:GetDescendants() do
		if c:IsA("Beam") and (get(c, "Attachment0") == nil or get(c, "Attachment1") == nil) then
			local a0 = Instance.new("Attachment")
			a0.Name = "_BeamStart"
			a0.CFrame = CFrame.new(0, 0, -3)
			a0.Parent = host
			local a1 = Instance.new("Attachment")
			a1.Name = "_BeamEnd"
			a1.CFrame = CFrame.new(0, 0, 3)
			a1.Parent = host
			c.Attachment0, c.Attachment1 = a0, a1
		elseif c:IsA("Trail") then
			needsSpin = true
			if get(c, "Attachment0") == nil or get(c, "Attachment1") == nil then
				local a0 = Instance.new("Attachment")
				a0.Name = "_TrailTop"
				a0.CFrame = CFrame.new(0, 0.6, 0)
				a0.Parent = host
				local a1 = Instance.new("Attachment")
				a1.Name = "_TrailBottom"
				a1.CFrame = CFrame.new(0, -0.6, 0)
				a1.Parent = host
				c.Attachment0, c.Attachment1 = a0, a1
			end
		end
	end
	if needsSpin then
		host:SetAttribute("PreviewSpin", true)
	end
	return host
end

-- Group items: hall -> category -> list, categories and items in name order.
local byHall = {}
for _, item in items do
	byHall[item.hall] = byHall[item.hall] or {}
	table.insert(byHall[item.hall], item)
end
for _, list in byHall do
	assignCategories(list)
end
table.sort(items, function(a, b)
	if a.hall ~= b.hall then
		return HALL_BY_KEY[a.hall].index < HALL_BY_KEY[b.hall].index
	end
	if a.category ~= b.category then
		return string.lower(a.category) < string.lower(b.category)
	end
	return string.lower(a.unit.Name) < string.lower(b.unit.Name)
end)
local grouped = {}
for _, item in items do
	grouped[item.hall] = grouped[item.hall] or { order = {}, cats = {} }
	local g = grouped[item.hall]
	if not g.cats[item.category] then
		g.cats[item.category] = {}
		table.insert(g.order, item.category)
	end
	table.insert(g.cats[item.category], item)
end

-- Each category is packed into a roughly square block; blocks flow across the hall, HALL_WIDTH studs wide.
local HALL_WIDTH = 900
local GAP = 5
local BLOCK_GAP = 14
local HEADER_DEPTH = 8
local HALL_GAP = 60
local manifestItems = {}
local zCursor = 0
local floorMinX, floorMaxX, floorMaxZ = -60, 0, 0
local strippedScripts = 0
local disabledScripts = 0
local scaledPreviews = 0

for _, hall in HALLS do
	local g = grouped[hall.key]
	if not g then
		continue
	end
	local hallFolder = Instance.new("Folder")
	hallFolder.Name = hall.name
	hallFolder.Parent = libraryRoot
	local hallDisplay = Instance.new("Folder")
	hallDisplay.Name = hall.name
	hallDisplay.Parent = displayRoot
	local hallOriginals

	local hallStartZ = zCursor
	-- Hall sign
	local sign = part({
		Name = "HallSign",
		Size = Vector3.new(4, 1, 4),
		Position = Vector3.new(-40, 0.5, zCursor + 10),
		Color = hall.color,
		Material = Enum.Material.Neon,
	})
	sign.Parent = hallDisplay
	local hallCount = 0
	for _, cat in g.order do
		hallCount += #g.cats[cat]
	end
	billboard(sign, { hall.name, string.format("%d models with VFX", hallCount) }, Vector3.new(40, 10, 0), 8, 1000, hall.color)
	zCursor += 24
	local hx, hallRowDepth = 0, 0

	local function placeItem(entry, cx, cz)
		local item, showcase, display = entry.item, entry.showcase, entry.display
		local w, dpt, height = entry.w, entry.dpt, entry.height
		local pw, pd = w + 2, dpt + 2
		local pedestal = part({
			Name = display,
			Size = Vector3.new(pw, 1, pd),
			Position = Vector3.new(cx, 0.5, cz),
			Color = Color3.fromRGB(38, 40, 48),
			CanCollide = true,
		})
		pedestal.Parent = entry.catDisplay
		local rim = part({
			Name = "Rim",
			Size = Vector3.new(pw + 0.4, 0.2, pd + 0.4),
			Position = Vector3.new(cx, 0.1, cz),
			Color = hall.color,
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		rim.Parent = pedestal

		if entry.renderable then
			-- Centred on its pedestal, bottom on the pedestal top.
			local minV, maxV = item._bboxMin, item._bboxMax
			local centre = (minV + maxV) / 2
			translate(showcase, Vector3.new(cx - centre.X, 1 - minV.Y, cz - centre.Z))
		else
			local host = buildPreview(item, entry.clone)
			host.CFrame = CFrame.new(cx, 4, cz)
			host.Parent = showcase
			height = 6
		end

		showcase.Name = display
		showcase:SetAttribute("SourceFile", item.source.label)
		showcase:SetAttribute("SourcePath", item.sourcePath)
		if item.foundIn then
			showcase:SetAttribute("FoundIn", item.foundIn)
		end
		if display ~= item.unit.Name then
			showcase:SetAttribute("OriginalName", item.unit.Name)
		end
		showcase:SetAttribute("EffectCount", item.fx)
		if #item.alsoIn > 0 then
			showcase:SetAttribute("AlsoIn", table.concat(item.alsoIn, "\n"))
		end
		showcase.Parent = entry.catFolder

		local lines = { display, string.format("%d FX · %s", item.fx, item.source.label) }
		if entry.realSize then
			table.insert(lines, "scaled preview of " .. entry.realSize .. " studs · real one in ServerStorage")
		end
		if entry.serverScripts > 0 then
			table.insert(lines, "scripts OFF here · clean copy in ServerStorage")
		end
		billboard(pedestal, lines, Vector3.new(math.clamp(w, 8, 16), 3.2, 0), math.min(height, 60) + 3, 90, hall.color)

		table.insert(manifestItems, {
			hall = hall.name,
			category = entry.cat,
			name = display,
			originalName = item.unit.Name,
			class = item.unit.ClassName,
			source = item.source.label,
			sourcePath = item.sourcePath,
			foundIn = item.foundIn,
			effects = item.fx,
			parts = item.parts,
			realSize = entry.realSize,
			scriptsDisabled = if entry.serverScripts > 0 then entry.serverScripts else nil,
			alsoIn = if #item.alsoIn > 0 then item.alsoIn else nil,
			position = { math.floor(cx + 0.5), math.floor(cz + 0.5) },
			size = { math.floor(w * 10 + 0.5) / 10, math.floor((height or 0) * 10 + 0.5) / 10, math.floor(dpt * 10 + 0.5) / 10 },
		})
	end
	for _, cat in g.order do
		local list = g.cats[cat]
		local catFolder = Instance.new("Folder")
		catFolder.Name = cat
		catFolder.Parent = hallFolder
		local catDisplay = Instance.new("Folder")
		catDisplay.Name = cat
		catDisplay.Parent = hallDisplay

		local names = {}
		local catEntries = {}
		for _, item in list do
			local unit = item.unit
			-- Display name
			local base = unit.Name
			if GENERIC[base] or names[base] then
				local parentName = if unit.Parent then unit.Parent.Name else ""
				base = if parentName ~= "" then (parentName .. " " .. (if unit.Name == "" then "" else unit.Name)) else base
				base = string.gsub(base, "%s+$", "")
			end
			local display = base
			local n = 2
			while names[display] do
				display = base .. " (" .. n .. ")"
				n += 1
			end
			names[display] = true

			local clone = unit:Clone()
			-- Strip remote-code scripts (free-model backdoors) and report them.
			for _, s in scriptsOf(clone) do
				local src = get(s, "Source") or ""
				for _, pat in SUSPICIOUS do
					if string.find(src, pat) then
						table.insert(suspicious, { item = item.sourcePath, script = s.Name, pattern = pat })
						s:Destroy()
						strippedScripts += 1
						break
					end
				end
			end

			local renderable = clone:IsA("BasePart") or ((clone:IsA("Model") or clone:IsA("Tool") or clone:IsA("Accessory")) and partCount(unit) > 0)
			local showcase
			local height, w, dpt
			if renderable then
				showcase = clone
				-- Bring it to the origin by its own first part before measuring: some assets are parked at
				-- y = 10,000,000, where float32 bounds would drift by a third of a stud (the offset is exact).
				local ref = if showcase:IsA("BasePart") then showcase else showcase:FindFirstChildWhichIsA("BasePart", true)
				translate(showcase, Vector3.zero - ref.CFrame.Position)
				local minV, maxV = bboxOf(showcase)
				local size = maxV - minV
				w, dpt, height = math.max(size.X, 4), math.max(size.Z, 4), size.Y
				item._bboxMin, item._bboxMax = minV, maxV
			else
				showcase = Instance.new("Model")
				clone.Parent = showcase
				w, dpt, height = 6, 6, 4
			end

			-- Untouched copy in ServerStorage for anything the showcase changes (scripts off, scaled preview).
			local originalKept = false
			local function keepOriginal()
				if originalKept then
					return
				end
				originalKept = true
				hallOriginals = hallOriginals
					or (function()
						local f = Instance.new("Folder")
						f.Name = hall.name
						f.Parent = originalsRoot
						return f
					end)()
				local catOriginals = hallOriginals:FindFirstChild(cat)
				if not catOriginals then
					catOriginals = Instance.new("Folder")
					catOriginals.Name = cat
					catOriginals.Parent = hallOriginals
				end
				local original = clone:Clone()
				original.Name = display
				original.Parent = catOriginals
			end

			-- Server Scripts off in the showcase.
			local serverScripts = 0
			for _, s in scriptsOf(showcase) do
				if s.ClassName == "Script" and not get(s, "Disabled") then
					serverScripts += 1
				end
			end
			if serverScripts > 0 then
				keepOriginal()
				for _, s in scriptsOf(showcase) do
					if s.ClassName == "Script" and not get(s, "Disabled") then
						s.Disabled = true
					end
				end
				disabledScripts += serverScripts
				showcase:SetAttribute("ScriptsDisabled", serverScripts)
			end

			-- Area volumes: a scaled preview here, the real size in ServerStorage.
			local realSize
			if renderable and math.max(w, dpt, height) > AREA_EFFECT_SIZE then
				keepOriginal()
				local k = PREVIEW_SIZE / math.max(w, dpt, height)
				realSize = string.format("%d x %d x %d", w, height, dpt)
				scaleAbout(showcase, k, (item._bboxMin + item._bboxMax) / 2)
				local minV, maxV = bboxOf(showcase)
				local size = maxV - minV
				w, dpt, height = math.max(size.X, 4), math.max(size.Z, 4), size.Y
				item._bboxMin, item._bboxMax = minV, maxV
				showcase:SetAttribute("ScaledPreview", math.floor(k * 10000 + 0.5) / 10000)
				showcase:SetAttribute("RealSize", realSize)
				scaledPreviews += 1
			end

			local entry = {
				item = item,
				showcase = showcase,
				clone = clone,
				renderable = renderable,
				display = display,
				w = w,
				dpt = dpt,
				height = height,
				serverScripts = serverScripts,
				cat = cat,
				catFolder = catFolder,
				catDisplay = catDisplay,
				realSize = realSize,
			}
			table.insert(catEntries, entry)
		end

		-- Pack the category into a block, rows up to a width that keeps it roughly square.
		local area, widest = 0, 0
		for _, e in catEntries do
			area += (e.w + 2 + GAP) * (e.dpt + 2 + GAP)
			widest = math.max(widest, e.w + 2)
		end
		local blockWidth = math.max(math.min(math.sqrt(area) * 1.3, HALL_WIDTH), widest)
		local bx, bz, rowDepth, bw = 0, 0, 0, 0
		for _, e in catEntries do
			if bx > 0 and bx + e.w + 2 > blockWidth then
				bz += rowDepth + GAP
				bx, rowDepth = 0, 0
			end
			e.lx, e.lz = bx + (e.w + 2) / 2, bz + (e.dpt + 2) / 2
			bx += e.w + 2 + GAP
			bw = math.max(bw, bx - GAP)
			rowDepth = math.max(rowDepth, e.dpt + 2)
		end
		local bd = bz + rowDepth + HEADER_DEPTH
		-- Flow the block across the hall.
		if hx > 0 and hx + bw > HALL_WIDTH then
			zCursor += hallRowDepth + BLOCK_GAP
			hx, hallRowDepth = 0, 0
		end
		local ox, oz = hx, zCursor + HEADER_DEPTH
		local plate = part({
			Name = "CategoryPlate",
			Size = Vector3.new(bw + 4, 0.04, bd + 2),
			Position = Vector3.new(ox + bw / 2, 0.16, zCursor + bd / 2),
			Color = hall.color:Lerp(Color3.fromRGB(20, 20, 26), 0.7),
			CanCollide = false,
		})
		plate.Parent = catDisplay
		local header = part({
			Name = "CategorySign",
			Size = Vector3.new(2, 0.6, 2),
			Position = Vector3.new(ox + 1, 0.3, zCursor + 2),
			Color = hall.color,
		})
		header.Parent = catDisplay
		billboard(header, { cat, string.format("%d item(s)", #list) }, Vector3.new(18, 4.5, 0), 4, 250, hall.color)
		for _, e in catEntries do
			placeItem(e, ox + e.lx, oz + e.lz)
		end
		hx += bw + BLOCK_GAP
		hallRowDepth = math.max(hallRowDepth, bd)
		floorMaxX = math.max(floorMaxX, hx)
	end
	zCursor += hallRowDepth + 10
	-- Hall floor strip
	local strip = part({
		Name = "HallFloor",
		Size = Vector3.new(floorMaxX - floorMinX + 20, 0.2, zCursor - hallStartZ + 10),
		Position = Vector3.new((floorMinX + floorMaxX) / 2, 0.05, (hallStartZ + zCursor) / 2),
		Color = hall.color:Lerp(Color3.fromRGB(20, 20, 26), 0.82),
		CanCollide = false,
	})
	strip.Parent = hallDisplay
	zCursor += HALL_GAP
	floorMaxZ = zCursor
end

local floor = part({
	Name = "LibraryFloor",
	Size = Vector3.new(floorMaxX - floorMinX + 200, 2, floorMaxZ + 200),
	Position = Vector3.new((floorMinX + floorMaxX) / 2, -1, floorMaxZ / 2 - 60),
	Color = Color3.fromRGB(24, 25, 30),
	Material = Enum.Material.Slate,
})
floor.Parent = displayRoot
local spawn = Instance.new("SpawnLocation")
spawn.Name = "SpawnLocation"
spawn.Anchored = true
spawn.Size = Vector3.new(8, 1, 8)
spawn.CFrame = CFrame.new(-40, 0.5, -20)
spawn.Transparency = 0.5
spawn.Parent = displayRoot

local previewer = Instance.new("Script")
previewer.Name = "VfxLibraryPreviewer"
previewer.Source = [[
-- VFX Library previewer (Play mode only; the assets themselves are untouched).
-- Anchors the showcase, keeps it silent, replays burst emitters (Enabled = false: their games fire them with
-- :Emit, usually with an EmitCount / EmitDelay attribute) and spins the hosts of lone Trails.
local RunService = game:GetService("RunService")
local root = workspace:WaitForChild("VfxLibrary")
local bursts, spinners = {}, {}
for _, d in root:GetDescendants() do
	if d:IsA("BasePart") then
		d.Anchored = true
		if d:GetAttribute("PreviewSpin") then
			table.insert(spinners, { part = d, origin = d.CFrame })
		end
	elseif d:IsA("Sound") then
		d.Playing = false
		d.Volume = 0
	elseif d:IsA("ParticleEmitter") and not d.Enabled then
		table.insert(bursts, d)
	end
end
local t = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	for _, s in spinners do
		s.part.CFrame = s.origin * CFrame.new(math.cos(t * 3) * 3, 0, math.sin(t * 3) * 3)
	end
end)
while true do
	for i, e in bursts do
		if e.Parent then
			local count = e:GetAttribute("EmitCount")
			count = if typeof(count) == "number" then math.clamp(count, 1, 80) else 12
			local delay = e:GetAttribute("EmitDelay")
			delay = if typeof(delay) == "number" then math.clamp(delay, 0, 2) else 0
			task.delay(delay, function()
				if e.Parent then
					e:Emit(count)
				end
			end)
		end
		if i % 200 == 0 then
			task.wait()
		end
	end
	task.wait(3)
end
]]
previewer.Parent = sss

local readme = Instance.new("StringValue")
readme.Name = "README"
readme.Value = table.concat({
	"VFX Library (built by StealaHero/scripts/tools/build_vfx_library.luau).",
	"Workspace.VfxLibrary.<Hall>.<Category>.<Item>: every model/part/effect set with VFX, one copy each.",
	"Save one: right-click it > Save to File... (.rbxm) or Save to Roblox.",
	"Attributes on each item: SourceFile, SourcePath (where it lives in its game), AlsoIn, FoundIn, OriginalName.",
	"Items with ScriptsDisabled (server Scripts off here) or ScaledPreview (weather / map volumes shrunk to fit a pedestal):",
	"their untouched copy, same name and folders, is in ServerStorage.VfxLibraryOriginals.",
	"Loose effects are a Model with the untouched effect + a _Preview host that renders a copy.",
	"Press Play to see burst effects (the previewer in ServerScriptService replays them every 3 s).",
}, "\n")
readme.Parent = workspace

----------------------------------------------------------------------
-- 3. Write
----------------------------------------------------------------------
local dir = string.match(OUT, "^(.*)/[^/]+$")
if dir and not fs.isDir(dir) then
	fs.writeDir(dir)
end
local bytes = roblox.serializePlace(game)
fs.writeFile(OUT, bytes)

local hallCounts = {}
for _, m in manifestItems do
	hallCounts[m.hall] = (hallCounts[m.hall] or 0) + 1
end
fs.writeFile(
	MANIFEST,
	serde.encode("json", {
		generator = "scripts/tools/build_vfx_library.luau",
		place = OUT,
		v40Source = V40_FULL or "vendor/sab_vfx.rbxl (subset: the full V40 place was not found)",
		speedstersDir = SPEEDSTERS,
		halls = hallCounts,
		items = manifestItems,
		skipped = skipped,
		perSource = perSource,
		strippedSuspiciousScripts = suspicious,
		disabledServerScripts = disabledScripts,
		scaledPreviews = scaledPreviews,
	}, true)
)

print(string.format("[vfx_library] V40 source: %s", V40_FULL or "vendor/sab_vfx.rbxl (subset)"))
for _, hall in HALLS do
	print(string.format("[vfx_library] %-24s %d items", hall.name, hallCounts[hall.name] or 0))
end
print(
	string.format(
		"[vfx_library] %d items, %d duplicates and %d same-path variants skipped, %d server scripts disabled, %d area volumes as scaled previews (untouched copies in ServerStorage), %d suspicious scripts stripped",
		#manifestItems,
		skipped.duplicate,
		skipped.samePath,
		disabledScripts,
		scaledPreviews,
		strippedScripts
	)
)
for _, s in suspicious do
	print(string.format("[vfx_library]   stripped %s in %s (%s)", s.script, s.item, s.pattern))
end
print(string.format("[vfx_library] wrote %s (%.1f MB) and %s", OUT, #bytes / 1048576, MANIFEST))
