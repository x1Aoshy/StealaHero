--!nocheck
-- scripts/steps/post_hero_weapons.luau (owner 2026-09-27, "MISSION: replace the bat system with Hero Gadgets")
-- Turns the classic bats into the owner's hero weapons, keeping every Tool name ("Bat", "Forest Bat"...: the kit, the
-- Index equip, the hotbar slot lock and the saves key off them):
--   1. For each tool in HeroWeapons.BY_TOOL (src/ReplicatedStorage/Library/Modules/HeroWeapons.luau), the bat template
--      in ReplicatedStorage.GearTools.ShopItems loses its bat (the MeshPart Handle and its particles), its HitAnim /
--      IdleAnim (another creator's animations, they never loaded) and the legacy BatController scripts (target
--      highlight + a dead "Bat:Activate" request; BranchControllers.HeroWeaponController replaces both), and gets the
--      weapon's part model from assets/hero_weapons/weapon_models.json (authored by
--      scripts/tools/hero_weapons/weapon_models.py). The result is what HeroWeaponTools.Prepare makes of an import:
--      attributes HeroWeaponId / GripFromHand, per part HeroSection (+ HeroPalette, StretchLength), the palette's
--      material, CanCollide / CanTouch / CanQuery off, Massless, unanchored, one "HeroWeaponWeld" per part with
--      C0 = Handle.CFrame:ToObjectSpace(part.CFrame). The models are authored in RightGripAttachment space, so
--      Tool.Grip = (Handle in grip space):Inverse() holds them right in the engine's own RightGrip (also stored as
--      the HeroGrip attribute for HeroWeaponTools.Attach).
--   2. Publishes src/ReplicatedStorage/Directory/WeaponAnimations/<WeaponId>.luau (the owner's attack clips, generated
--      by scripts/tools/hero_weapons/gen_weapon_clips.py) as ReplicatedStorage.Directory.WeaponAnimations after
--      validating each with the game's own HeroClipMath.PrepareClip (Impact inside the clip, the right arm animated).
--   3. The owner's own models: a weapon imported in Studio and prepared with their HeroWeaponTools.Prepare
--      (assets/hero_weapons/HeroWeaponsImport.lua -> ServerStorage.HeroWeaponImports, extracted by the build to
--      assets/hero_weapons/imports/weapons/<WeaponId>.rbxm) REPLACES the part model of that weapon: its MeshParts (with
--      their textures) are flattened into the Tool, re-welded to the Handle, and Tool.Grip holds the Handle where the
--      kit's GripFromHand puts it (Handle = RightHand * GripFromHand). The effect models
--      (imports/vfx/<Name>.rbxm: Web_Blob, Web_Net, Web_Cocoon, Mjolnir_Lightning, Dazed_Stars, Comic_Explosion,
--      Bat_Smoke_Cloud) go to ReplicatedStorage.HeroWeaponVfx for BranchControllers.HeroWeaponController. A weapon's
--      "VFX" section (the Power Pole's energy arc) is left out: owner 2026-09-27, "remove every mesh VFX that is not a
--      particle emitter". assets/hero_weapons/grip_adjust.json moves / turns a model in the hand (Mjolnir is held by
--      the wrap above the pommel, its head's striking axis along the forearm), every MeshPart is DoubleSided (the
--      shield's discs are single-sided faces: from behind, the wielder's view, only the rim showed), and the Tool
--      carries HeroModelRadius (the model's own radius: the thrown weapons' hitbox).
--   4. vendor/weapon_vfx.rbxm (scripts/tools/vendor_weapon_vfx.luau: Speedsters' Eggman missile blast, Steal a
--      Brainrot's Ban Hammer lightning strike and electric impact - particle emitters only) is published as
--      ReplicatedStorage.Assets.VFX.HeroWeapons.<Name> for the controller.
--      STEALAHERO_WEAPON_IMPORTS=synthetic fabricates those imports from assets/hero_weapons/fbx_manifest.json (block
--      parts at each FBX mesh's bounds, laid out exactly like Prepare's output) to test the path without Studio.
-- No Sound, no Light, no mesh upload (an import's meshes are the owner's Studio uploads). Idempotent.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local process = require("@lune/process")

local Instance = roblox.Instance
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Vector3 = roblox.Vector3
local Enum = roblox.Enum

local Step = {}

Step.MODELS = "assets/hero_weapons/weapon_models.json"
Step.CONFIG = "src/ReplicatedStorage/Library/Modules/HeroWeapons.luau"
Step.CLIP_MATH = "src/ReplicatedStorage/Library/Modules/HeroClipMath.luau"
Step.CLIP_DIR = "src/ReplicatedStorage/Directory/WeaponAnimations"
Step.WELD_NAME = "HeroWeaponWeld"
Step.IMPORT_DIR = "assets/hero_weapons/imports"
Step.FBX_MANIFEST = "assets/hero_weapons/fbx_manifest.json"
Step.VFX_FOLDER = "HeroWeaponVfx"
Step.GRIP_ADJUST = "assets/hero_weapons/grip_adjust.json"
Step.PARTICLES = "vendor/weapon_vfx.rbxm"
-- HeroWeaponTools.gripRotations (the owner's kit + the two weapons it did not list), for the synthetic imports
Step.GRIP_ROTATIONS = {
	Mjolnir = CFrame.Angles(math.rad(-90), 0, 0),
	PowerPole = CFrame.Angles(math.rad(-90), 0, 0),
	PowerPole_GoldToy = CFrame.Angles(math.rad(-90), 0, 0),
	CapShield = CFrame.Angles(math.rad(-90), 0, 0),
	Batarang = CFrame.Angles(math.rad(-90), 0, 0),
	WebShooter = CFrame.new(),
	BakugoGauntlet = CFrame.new(),
	GomuFist = CFrame.Angles(math.pi, 0, 0),
}
Step.METAL_PALETTES = { mjolnir_metal = true, steel_dark = true, silver = true, gold = true, cartridge_brass = true,
	hammer_forged = true, hammer_edge = true, hammer_inlay = true }
Step.NEON_PALETTES = { lightning = true, web_neon = true, gold_energy = true }
-- a Neon part glows its Color (not its texture): the energy palettes get their colour
Step.NEON_COLORS = { lightning = { 150, 220, 255 }, web_neon = { 236, 248, 255 }, gold_energy = { 255, 170, 60 } }
-- R15 RightGripAttachment (RightHand space): GripFromHand = this * (Handle in grip space), like Kit.Prepare's value.
Step.GRIP_ATTACHMENT = CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(-90), 0, 0)
-- the legacy bat pieces a hero weapon drops
Step.DROP_CLASSES = { "BasePart", "Animation", "LuaSourceContainer", "ParticleEmitter", "Attachment", "Sound", "Light",
	"Trail", "Beam", "SpecialMesh", "SurfaceAppearance", "Decal", "Texture", "Weld", "WeldConstraint", "Motor6D" }

-- The grip adjustment of a model in the hand: CFrame.Angles(0, Twist, 0) * CFrame.new(Shift) (FBX origin space).
local gripAdjustCache = nil
-- Palettes of a model's single-sided flat meshes that get a backward-facing copy (grip_adjust.json BackfaceCopies).
function Step.BackfacePalettes(weaponId)
	Step.GripAdjust(weaponId) -- loads the file
	local entry = gripAdjustCache[weaponId]
	local set = {}
	for _, palette in ipairs(type(entry) == "table" and entry.BackfaceCopies or {}) do
		set[palette] = true
	end
	return set
end

function Step.GripAdjust(weaponId)
	if gripAdjustCache == nil then
		gripAdjustCache = if fs.isFile(Step.GRIP_ADJUST) then serde.decode("json", fs.readFile(Step.GRIP_ADJUST)) else {}
	end
	local entry = gripAdjustCache[weaponId]
	if type(entry) ~= "table" then
		return CFrame.new()
	end
	local shift = entry.Shift or { 0, 0, 0 }
	return CFrame.Angles(0, math.rad(entry.Twist or 0), 0) * CFrame.new(shift[1], shift[2], shift[3])
end

local function loadModule(path, env)
	return luau.load(fs.readFile(path), { debugName = path, environment = env, injectGlobals = false })()
end

function Step.LoadConfig()
	return loadModule(Step.CONFIG, {
		Color3 = Color3, math = math, pairs = pairs, ipairs = ipairs, type = type, typeof = typeof, pcall = pcall,
		table = table, string = string, tostring = tostring,
	})
end

local function frameOf(c)
	return CFrame.new(c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12])
end

local function shouldDrop(instance)
	for _, className in ipairs(Step.DROP_CLASSES) do
		if instance:IsA(className) then
			return true
		end
	end
	return false
end

-- Builds one part of a weapon (grip-space frame `frame`) into `tool`.
local function buildPart(tool, spec, palettes)
	local part
	if spec.shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		part = Instance.new("Part")
		if spec.shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		elseif spec.shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		else
			part.Shape = Enum.PartType.Block
		end
	end
	local palette = palettes[spec.palette]
	assert(palette ~= nil, "unknown palette " .. tostring(spec.palette))
	part.Name = if spec.handle then "Handle" else spec.name
	part.Size = Vector3.new(spec.size[1], spec.size[2], spec.size[3])
	part.CFrame = frameOf(spec.cframe)
	part.Color = Color3.fromRGB(palette.Color[1], palette.Color[2], palette.Color[3])
	part.Material = Enum.Material[palette.Material]
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = spec.shape ~= "Wedge" or spec.size[1] > 0.12 -- the thin wedges (stars, batarang) cast no shadow
	part:SetAttribute("HeroSection", spec.section or "Handle")
	part:SetAttribute("HeroPalette", spec.palette)
	if type(spec.StretchLength) == "number" then
		part:SetAttribute("StretchLength", spec.StretchLength)
	end
	part.Parent = tool
	return part
end

-- Rebuilds `tool` (a bat template) as `weapon`. Returns the part count.
function Step.BuildWeapon(tool, weapon, palettes, config)
	for _, child in ipairs(tool:GetChildren()) do
		if shouldDrop(child) then
			child:Destroy()
		end
	end
	local parts, handle, handleSpec = {}, nil, nil
	for _, spec in ipairs(weapon.Parts) do
		if spec.section == "VFX" then
			continue -- no mesh VFX on a weapon: particles only
		end
		local part = buildPart(tool, spec, palettes)
		table.insert(parts, part)
		if spec.handle then
			assert(handle == nil, weapon.WeaponId .. ": two handles")
			handle, handleSpec = part, spec
		end
	end
	assert(handle ~= nil, weapon.WeaponId .. ": no handle")
	for _, part in ipairs(parts) do
		if part ~= handle then
			local weld = Instance.new("Weld")
			weld.Name = Step.WELD_NAME
			weld.Part0 = handle
			weld.Part1 = part
			weld.C0 = handle.CFrame:ToObjectSpace(part.CFrame)
			weld.C1 = CFrame.new()
			weld.Parent = part
		end
	end
	local handleInGrip = frameOf(handleSpec.cframe)
	local grip = handleInGrip:Inverse()
	tool.Grip = grip
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ManualActivationOnly = false
	tool.ToolTip = weapon.DisplayName
	tool:SetAttribute("HeroWeaponId", weapon.WeaponId)
	tool:SetAttribute("HeroGrip", grip)
	tool:SetAttribute("GripFromHand", Step.GRIP_ATTACHMENT * handleInGrip)
	tool:SetAttribute("HeroWeaponName", weapon.DisplayName)
	tool:SetAttribute("ItemType", "Gear")
	if type(tool:GetAttribute("GearName")) ~= "string" then
		tool:SetAttribute("GearName", tool.Name)
	end
	local spec = config.WEAPONS[weapon.WeaponId]
	assert(spec ~= nil, weapon.WeaponId .. " missing from HeroWeapons.WEAPONS")
	tool:SetAttribute("HeroEffect", spec.Effect)
	return #parts
end

-- FBX material name per mesh: { [FBX model name or WeaponId] = { [mesh name] = material } } (fbx_manifest.json)
local materialCache = nil
function Step.FbxMaterials()
	if materialCache == nil then
		materialCache = {}
		if fs.isFile(Step.FBX_MANIFEST) then
			local manifest = serde.decode("json", fs.readFile(Step.FBX_MANIFEST))
			for _, kind in ipairs({ "Weapons", "Vfx" }) do
				for name, entry in pairs(manifest[kind]) do
					local byMesh = {}
					for _, mesh in ipairs(entry.Meshes) do
						byMesh[mesh.name] = mesh.material
					end
					materialCache[name] = byMesh
					if entry.WeaponId then
						materialCache[entry.WeaponId] = byMesh
					end
				end
			end
		end
	end
	return materialCache
end

-- The owner's kit's material rule (HeroWeaponTools.materialByPalette): metals Metal, energy Neon (+ its colour: a Neon
-- part glows its Color, not its texture), the rest SmoothPlastic.
function Step.ApplyPalette(part, palette)
	palette = palette or ""
	if Step.NEON_PALETTES[palette] then
		part.Material = Enum.Material.Neon
		local c = Step.NEON_COLORS[palette]
		part.Color = Color3.fromRGB(c[1], c[2], c[3])
	elseif Step.METAL_PALETTES[palette] then
		part.Material = Enum.Material.Metal
	else
		part.Material = Enum.Material.SmoothPlastic
	end
end

local function flattenedParts(root)
	local parts = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	return parts
end

-- Rebuilds `tool` from an imported Tool made by HeroWeaponTools.Prepare in Studio. Returns the part count.
function Step.BuildWeaponFromImport(tool, imported, config, weaponId)
	for _, child in ipairs(tool:GetChildren()) do
		if shouldDrop(child) then
			child:Destroy()
		end
	end
	local gripFromHand = imported:GetAttribute("GripFromHand")
	local raw = typeof(gripFromHand) ~= "CFrame"
	if raw then
		-- a raw Import 3D model (saved straight to a .rbxm): HeroWeaponTools.Prepare's grip, offline. The model's pivot
		-- is the FBX origin (checked against fbx_manifest.json by the smoke test).
		local handleSource = imported:FindFirstChild("Handle", true)
		assert(handleSource ~= nil and handleSource:IsA("BasePart"), weaponId .. " import has no Handle part")
		local pivot = if imported:IsA("Model") and imported.WorldPivotData then imported.WorldPivotData else CFrame.new()
		assert(Step.GRIP_ROTATIONS[weaponId] ~= nil, "no grip rotation for " .. weaponId)
		gripFromHand = Step.GRIP_ROTATIONS[weaponId] * Step.GripAdjust(weaponId) * pivot:ToObjectSpace(handleSource.CFrame)
	elseif Step.GRIP_ROTATIONS[weaponId] then
		-- a Tool prepared by the kit in Studio (GripFromHand = rotation * origin->Handle): the same hand adjustment
		local rotation = Step.GRIP_ROTATIONS[weaponId]
		gripFromHand = rotation * Step.GripAdjust(weaponId) * rotation:Inverse() * gripFromHand
	end
	local handle, parts = nil, {}
	local radius = 0
	for _, source in ipairs(flattenedParts(imported)) do
		local sourceSection = source:GetAttribute("HeroSection")
		if type(sourceSection) ~= "string" then
			sourceSection = string.match(source.Name, "__([^_]+)__")
		end
		if sourceSection == "VFX" then
			continue -- no mesh VFX on a weapon (the Power Pole's energy arc): particles only
		end
		local part = source:Clone()
		for _, child in ipairs(part:GetChildren()) do
			if child:IsA("BasePart") or child:IsA("JointInstance") or child:IsA("WeldConstraint")
				or child:IsA("LuaSourceContainer") or child:IsA("Sound") or child:IsA("Light") then
				child:Destroy() -- nested parts come in on their own; joints are rebuilt below
			end
		end
		part.CFrame = source.CFrame
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		local section = part:GetAttribute("HeroSection")
		if type(section) ~= "string" then
			section = string.match(part.Name, "__([^_]+)__") or "Handle"
			part:SetAttribute("HeroSection", section)
		end
		local palette = string.match(part.Name, "__[^_]+__(.+)$")
		if palette then
			part:SetAttribute("HeroPalette", palette)
		end
		if raw then
			-- Prepare's material by palette (the Handle has no palette in its name: its FBX material stands in)
			local materials = Step.FbxMaterials()[weaponId] or {}
			Step.ApplyPalette(part, palette or materials[source.Name])
		end
		if part:IsA("MeshPart") then
			part.DoubleSided = true -- single-sided faces (the shield's discs) vanish when seen from behind
		end
		radius = math.max(radius, math.max(part.Size.X, part.Size.Y, part.Size.Z) / 2)
		part.Parent = tool
		table.insert(parts, part)
		if source.Name == "Handle" and handle == nil then
			handle = part
		end
	end
	assert(handle ~= nil, weaponId .. " import has no Handle")
	-- single-sided flat meshes (the shield's discs) get a copy turned about their own vertical axis, facing backward:
	-- DoubleSided alone did not show them from behind in Studio
	local backface = Step.BackfacePalettes(weaponId)
	for index = #parts, 1, -1 do
		local part = parts[index]
		if backface[part:GetAttribute("HeroPalette") or ""] then
			local copy = part:Clone()
			copy.Name = part.Name .. "__Back"
			copy.CFrame = part.CFrame * CFrame.Angles(0, math.pi, 0)
			copy:SetAttribute("HeroBackface", true)
			copy.Parent = tool
			table.insert(parts, copy)
		end
	end
	-- a stretching weapon (Luffy's rubber arm): its Fist rides the end of the Rubber section, so it moves by the
	-- rubber's far-end distance per unit of stretch (HeroWeaponTools.SetStretch's StretchLength)
	local rubber = nil
	for _, part in ipairs(parts) do
		if part:GetAttribute("HeroSection") == "Rubber" then
			rubber = part
			break
		end
	end
	if rubber then
		local offset = handle.CFrame:PointToObjectSpace(rubber.CFrame.Position)
		if offset.Magnitude > 1e-3 then
			local dir = offset.Unit
			local localDir = rubber.CFrame:VectorToObjectSpace(handle.CFrame:VectorToWorldSpace(dir))
			local half = (math.abs(localDir.X) * rubber.Size.X + math.abs(localDir.Y) * rubber.Size.Y
				+ math.abs(localDir.Z) * rubber.Size.Z) / 2
			local far = math.floor((offset:Dot(dir) + half) * 1000 + 0.5) / 1000
			for _, part in ipairs(parts) do
				if part:GetAttribute("HeroSection") == "Fist" then
					part:SetAttribute("StretchLength", far)
				end
			end
		end
	end
	for _, part in ipairs(parts) do
		if part ~= handle then
			local weld = Instance.new("Weld")
			weld.Name = Step.WELD_NAME
			weld.Part0 = handle
			weld.Part1 = part
			weld.C0 = handle.CFrame:ToObjectSpace(part.CFrame)
			weld.C1 = CFrame.new()
			weld.Parent = part
		end
	end
	-- Handle = RightHand * GripFromHand (the kit), and the engine's RightGrip does Handle = RightHand * attachment * Grip^-1
	local grip = gripFromHand:Inverse() * Step.GRIP_ATTACHMENT
	tool.Grip = grip
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ManualActivationOnly = false
	local spec = config.WEAPONS[weaponId]
	tool.ToolTip = spec.DisplayName
	tool:SetAttribute("HeroWeaponId", weaponId)
	tool:SetAttribute("HeroGrip", grip)
	tool:SetAttribute("GripFromHand", gripFromHand)
	tool:SetAttribute("HeroWeaponName", spec.DisplayName)
	tool:SetAttribute("HeroEffect", spec.Effect)
	tool:SetAttribute("HeroWeaponModel", "Import")
	tool:SetAttribute("HeroModelRadius", math.floor(radius * 100 + 0.5) / 100)
	tool:SetAttribute("ItemType", "Gear")
	if type(tool:GetAttribute("GearName")) ~= "string" then
		tool:SetAttribute("GearName", tool.Name)
	end
	return #parts
end

-- A stand-in for a Studio import made from the FBX manifest: block parts at each mesh's bounds, laid out and tagged
-- exactly like HeroWeaponTools.Prepare's output (origin = the file origin).
function Step.SyntheticWeapon(name, entry)
	local tool = Instance.new("Tool")
	tool.Name = entry.WeaponId
	local handle = nil
	local parts = {}
	for _, mesh in ipairs(entry.Meshes) do
		local part = Instance.new("Part")
		part.Name = mesh.name
		part.Size = Vector3.new(math.max(mesh.size[1], 0.05), math.max(mesh.size[2], 0.05), math.max(mesh.size[3], 0.05))
		part.CFrame = CFrame.new(mesh.centre[1], mesh.centre[2], mesh.centre[3])
		part:SetAttribute("HeroSection", mesh.section)
		part.Material = if Step.METAL_PALETTES[mesh.palette or ""] then Enum.Material.Metal
			elseif Step.NEON_PALETTES[mesh.palette or ""] then Enum.Material.Neon else Enum.Material.SmoothPlastic
		part.Parent = tool
		table.insert(parts, part)
		if mesh.name == "Handle" then
			handle = part
		end
	end
	tool:SetAttribute("HeroWeaponId", entry.WeaponId)
	tool:SetAttribute("HeroWeaponSource", name .. ".fbx (synthetic)")
	tool:SetAttribute("GripFromHand", Step.GRIP_ROTATIONS[entry.WeaponId] * Step.GripAdjust(entry.WeaponId) * handle.CFrame)
	return tool
end

function Step.SyntheticVfx(name, entry)
	local model = Instance.new("Model")
	model.Name = name
	for _, mesh in ipairs(entry.Meshes) do
		local part = Instance.new("Part")
		part.Name = mesh.name
		part.Size = Vector3.new(math.max(mesh.size[1], 0.05), math.max(mesh.size[2], 0.05), math.max(mesh.size[3], 0.05))
		part.CFrame = CFrame.new(mesh.centre[1], mesh.centre[2], mesh.centre[3])
		part.Parent = model
	end
	model:SetAttribute("HeroWeaponSource", name .. ".fbx (synthetic)")
	return model
end

-- { weapons = { [WeaponId] = Tool }, vfx = { [Name] = Model } } from assets/hero_weapons/imports (or synthetic).
function Step.LoadImports()
	local out = { weapons = {}, vfx = {} }
	if process.env.STEALAHERO_WEAPON_IMPORTS == "synthetic" then
		local manifest = serde.decode("json", fs.readFile(Step.FBX_MANIFEST))
		for name, entry in pairs(manifest.Weapons) do
			out.weapons[entry.WeaponId] = Step.SyntheticWeapon(name, entry)
		end
		for name, entry in pairs(manifest.Vfx) do
			out.vfx[name] = Step.SyntheticVfx(name, entry)
		end
		return out
	end
	for kind, bucket in pairs({ weapons = out.weapons, vfx = out.vfx }) do
		local dir = Step.IMPORT_DIR .. "/" .. kind
		if fs.isDir(dir) then
			for _, file in ipairs(fs.readDir(dir)) do
				local name = string.match(file, "^(.+)%.rbxm$")
				if name then
					local ok, roots = pcall(roblox.deserializeModel, fs.readFile(dir .. "/" .. file))
					if ok and roots[1] then
						bucket[name] = roots[1]
					else
						print("[post_hero_weapons] !! could not read " .. dir .. "/" .. file .. ": " .. tostring(roots))
					end
				end
			end
		end
	end
	return out
end

-- The effect models under ReplicatedStorage.HeroWeaponVfx (anchored, no collisions, no shadow).
function Step.PublishVfx(place, vfx)
	local rs = place:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild(Step.VFX_FOLDER)
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = Step.VFX_FOLDER
	folder.Parent = rs
	local published = {}
	for name, source in pairs(vfx) do
		local model = Instance.new("Model")
		model.Name = name
		-- normalised around the FBX origin (the import's pivot), so a clone's PivotTo places the effect exactly
		local pivot = if source:IsA("Model") and source.WorldPivotData then source.WorldPivotData else CFrame.new()
		local materials = Step.FbxMaterials()[name] or {}
		for _, part in ipairs(flattenedParts(source)) do
			local copy = part:Clone()
			for _, child in ipairs(copy:GetChildren()) do
				if child:IsA("BasePart") or child:IsA("JointInstance") or child:IsA("WeldConstraint")
					or child:IsA("LuaSourceContainer") or child:IsA("Sound") or child:IsA("Light") then
					child:Destroy()
				end
			end
			copy.CFrame = pivot:ToObjectSpace(part.CFrame)
			local palette = string.match(part.Name, "__[^_]+__(.+)$") or materials[part.Name]
			if palette and Step.NEON_PALETTES[palette] then
				Step.ApplyPalette(copy, palette) -- the bolts and the web glow
			end
			copy.Anchored = true
			copy.CanCollide = false
			copy.CanTouch = false
			copy.CanQuery = false
			copy.CastShadow = false
			copy.Massless = true
			copy.Parent = model
		end
		-- the pivot is the FBX file origin (the effect meshes are authored around it). No PrimaryPart on purpose: with one,
		-- Model:GetPivot / PivotTo would use the Handle instead of this WorldPivot.
		model.WorldPivotData = CFrame.new()
		model.Parent = folder
		table.insert(published, name)
	end
	table.sort(published)
	return published
end

-- vendor/weapon_vfx.rbxm -> ReplicatedStorage.Assets.VFX.HeroWeapons (one Attachment of emitters per effect).
function Step.PublishParticles(place)
	if not fs.isFile(Step.PARTICLES) then
		print("[post_hero_weapons] !! " .. Step.PARTICLES .. " missing (lune run scripts/tools/vendor_weapon_vfx.luau)")
		return {}
	end
	local rs = place:GetService("ReplicatedStorage")
	local assets = rs:FindFirstChild("Assets")
	assert(assets ~= nil, "ReplicatedStorage.Assets missing")
	local vfx = assets:FindFirstChild("VFX")
	if not vfx then
		vfx = Instance.new("Folder")
		vfx.Name = "VFX"
		vfx.Parent = assets
	end
	local old = vfx:FindFirstChild("HeroWeapons")
	if old then
		old:Destroy()
	end
	local source = roblox.deserializeModel(fs.readFile(Step.PARTICLES))[1]
	local folder = Instance.new("Folder")
	folder.Name = "HeroWeapons"
	local names = {}
	for _, effect in ipairs(source:GetChildren()) do
		for _, d in ipairs(effect:GetDescendants()) do
			assert(d:IsA("ParticleEmitter"), Step.PARTICLES .. ": " .. d:GetFullName() .. " is not a ParticleEmitter")
		end
		effect:Clone().Parent = folder
		table.insert(names, effect.Name)
	end
	folder.Parent = vfx
	table.sort(names)
	return names
end

function Step.PublishClips(place, config)
	local directory = place:GetService("ReplicatedStorage"):FindFirstChild("Directory")
	assert(directory ~= nil, "ReplicatedStorage.Directory missing")
	local clipMath = loadModule(Step.CLIP_MATH, { math = math, table = table, string = string, type = type, pairs = pairs,
		ipairs = ipairs, error = error, tostring = tostring, tonumber = tonumber, setmetatable = setmetatable, CFrame = CFrame })
	local folder = directory:FindFirstChild("WeaponAnimations")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "WeaponAnimations"
	folder.Parent = directory
	local published = {}
	for weaponId in pairs(config.WEAPONS) do
		local path = Step.CLIP_DIR .. "/" .. weaponId .. ".luau"
		assert(fs.isFile(path), "missing weapon clip " .. path .. " (run scripts/tools/hero_weapons/gen_weapon_clips.py)")
		local data = loadModule(path, {})
		assert(data.WeaponId == weaponId, path .. ": WeaponId mismatch")
		local clip = clipMath.PrepareClip(weaponId, data)
		assert(not clip.Loop, path .. ": an attack clip must not loop")
		assert(type(data.Impact) == "number" and data.Impact > 0 and data.Impact < data.Length, path .. ": Impact outside the clip")
		assert(data.Tracks.RightShoulder ~= nil and data.Tracks.RightElbow ~= nil, path .. ": the right arm is not animated")
		local module = Instance.new("ModuleScript")
		module.Name = weaponId
		module.Source = fs.readFile(path)
		module.Parent = folder
		table.insert(published, string.format("%s (%s, impact %.2fs / %.2fs)", weaponId, data.Clip, data.Impact, data.Length))
	end
	table.sort(published)
	return published
end

function Step.Apply(place, _spPlace, _ctx)
	local rs = place:GetService("ReplicatedStorage")
	local config = Step.LoadConfig()
	local data = serde.decode("json", fs.readFile(Step.MODELS))
	assert(data.Format == 1, Step.MODELS .. ": unknown format")
	local byId = {}
	for _, weapon in ipairs(data.Weapons) do
		byId[weapon.WeaponId] = weapon
	end
	for weaponId in pairs(config.WEAPONS) do
		assert(byId[weaponId] ~= nil, "weapon_models.json has no model for " .. weaponId)
	end

	local shopItems = rs:FindFirstChild("GearTools") and rs.GearTools:FindFirstChild("ShopItems")
	assert(shopItems ~= nil, "ReplicatedStorage.GearTools.ShopItems missing")
	local imports = Step.LoadImports()
	local built = {}
	local toolNames = {}
	for toolName in pairs(config.BY_TOOL) do
		table.insert(toolNames, toolName)
	end
	table.sort(toolNames)
	for _, toolName in ipairs(toolNames) do
		local weaponId = config.BY_TOOL[toolName]
		local tool = shopItems:FindFirstChild(toolName)
		assert(tool ~= nil and tool:IsA("Tool"), "GearTools.ShopItems." .. toolName .. " is not a Tool")
		local imported = imports.weapons[weaponId]
		if imported then
			local count = Step.BuildWeaponFromImport(tool, imported, config, weaponId)
			table.insert(built, string.format("%s -> %s (owner's model, %d meshes)", toolName, weaponId, count))
		else
			local count = Step.BuildWeapon(tool, byId[weaponId], data.Palettes, config)
			tool:SetAttribute("HeroWeaponModel", "Parts")
			table.insert(built, string.format("%s -> %s (part stand-in, %d parts)", toolName, weaponId, count))
		end
	end
	local clips = Step.PublishClips(place, config)
	local vfx = Step.PublishVfx(place, imports.vfx)
	local particles = Step.PublishParticles(place)
	local missing, total = {}, 0
	for weaponId in pairs(config.WEAPONS) do
		total += 1
		if not imports.weapons[weaponId] then
			table.insert(missing, weaponId)
		end
	end
	table.sort(missing)
	print(string.format("[post_hero_weapons] owner models: %d/%d weapon imports, %d effect imports (%s)%s", total - #missing,
		total, #vfx, if #vfx > 0 then table.concat(vfx, ", ") else "none",
		if #missing > 0 then "; part stand-ins for " .. table.concat(missing, ", ") .. " until they are imported" else ""))
	print("[post_hero_weapons] " .. #built .. " hero weapon tools: " .. table.concat(built, ", "))
	print("[post_hero_weapons] " .. #clips .. " attack clips: " .. table.concat(clips, ", "))
	print("[post_hero_weapons] particle sets: " .. table.concat(particles, ", "))
end

return Step
