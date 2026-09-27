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
-- No Sound, no Light, no mesh asset. Idempotent (a re-run rebuilds the same tools).

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")

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
		local count = Step.BuildWeapon(tool, byId[weaponId], data.Palettes, config)
		table.insert(built, string.format("%s -> %s (%d parts)", toolName, weaponId, count))
	end
	local clips = Step.PublishClips(place, config)
	print("[post_hero_weapons] " .. #built .. " hero weapon tools: " .. table.concat(built, ", "))
	print("[post_hero_weapons] " .. #clips .. " attack clips: " .. table.concat(clips, ", "))
end

return Step
