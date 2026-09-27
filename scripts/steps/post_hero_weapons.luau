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
--      Bat_Smoke_Cloud) go to ReplicatedStorage.HeroWeaponVfx for BranchControllers.HeroWeaponController. A "VFX"
--      section of a weapon (the Power Pole's energy arc) is hidden until the attack shows it.
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
-- R15 RightGripAttachment (RightHand space): GripFromHand = this * (Handle in grip space), like Kit.Prepare's value.
Step.GRIP_ATTACHMENT = CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(-90), 0, 0)
-- the legacy bat pieces a hero weapon drops
Step.DROP_CLASSES = { "BasePart", "Animation", "LuaSourceContainer", "ParticleEmitter", "Attachment", "Sound", "Light",
	"Trail", "Beam", "SpecialMesh", "SurfaceAppearance", "Decal", "Texture", "Weld", "WeldConstraint", "Motor6D" }

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
	assert(typeof(gripFromHand) == "CFrame", weaponId .. " import has no GripFromHand (run HeroWeaponsImport.lua in Studio)")
	local handle, parts = nil, {}
	for _, source in ipairs(flattenedParts(imported)) do
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
		if section == "VFX" then
			part.Transparency = 1 -- shown by HeroWeaponController while the attack plays
			part.CastShadow = false
		end
		part.Parent = tool
		table.insert(parts, part)
		if source.Name == "Handle" and handle == nil then
			handle = part
		end
	end
	assert(handle ~= nil, weaponId .. " import has no Handle")
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
	tool:SetAttribute("GripFromHand", Step.GRIP_ROTATIONS[entry.WeaponId] * handle.CFrame)
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
		local primary = nil
		for _, part in ipairs(flattenedParts(source)) do
			local copy = part:Clone()
			for _, child in ipairs(copy:GetChildren()) do
				if child:IsA("BasePart") or child:IsA("JointInstance") or child:IsA("WeldConstraint")
					or child:IsA("LuaSourceContainer") or child:IsA("Sound") or child:IsA("Light") then
					child:Destroy()
				end
			end
			copy.CFrame = part.CFrame
			copy.Anchored = true
			copy.CanCollide = false
			copy.CanTouch = false
			copy.CanQuery = false
			copy.CastShadow = false
			copy.Massless = true
			copy.Parent = model
			if part.Name == "Handle" then
				primary = copy
			end
		end
		if primary then
			model.PrimaryPart = primary
		end
		-- the pivot is the FBX file origin (the effect meshes are authored around it)
		model.WorldPivotData = CFrame.new()
		model.Parent = folder
		table.insert(published, name)
	end
	table.sort(published)
	return published
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
end

return Step
