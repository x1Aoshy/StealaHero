--!nocheck
-- scripts/lib/hero_egg_models.luau
-- Builds the 44 voxel Hero Egg models (38 heroes + 6 bosses, ids = HeroCatalog ids) as plain Roblox Parts from
-- assets/eggs/egg_parts.json, which scripts/tools/blender/hero_eggs/export_parts.py derives from the Hero Eggs kit
-- generator (audit/generate_voxel_eggs_bpy.py, the same geometry as assets/eggs/fbx/<HeroId>_Egg.fbx). Parts need no
-- Studio import or asset upload, so every build has them.
--
-- Model contract (see scripts/steps/post_hero_eggs.luau for where they go):
--   Model "<HeroId>"  PrimaryPart = opts.rootName ("Hitbox" by default, the name the game's egg renderer expects);
--                     attributes HeroId, Stage, Rarity, BossScale, EggHeight, HeroEgg = true, PartCount
--     Hitbox  invisible Part at the egg's centre (bounding box of every part), sized to that box, the weld hub
--     V###    the voxel parts: SmoothPlastic + MaterialVariant EGG_VARIANT (the kit's square stud finish) or Neon for
--             the kit's glow / gem colours; every part welded to the hub (WeldConstraint with CFrame0 written) and
--             flagged DontModify (the runtime's AssetColorUtil must not recolour them)
--   Origin = ground centre (the model's pivot), front = -Z (the pivot's LookVector), 3.2 * BossScale * opts.scale
--   studs tall (the kit's size at scale 1).
-- Every part is Anchored, CanCollide/CanTouch/CanQuery false and Massless: the runtime owns anchoring and hit boxes.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Eggs = {}

Eggs.DATA_PATH = "assets/eggs/egg_parts.json"
Eggs.EGG_VARIANT = "HeroEggStud" -- MaterialService variant made by Eggs.EnsureMaterialVariant
Eggs.VARIANT_SOURCE = "Custom Stud" -- SmoothPlastic stud variant of the base place (StudsPerTile 0.498)
Eggs.STUDS_PER_TILE = 0.3 -- the kit's stud pitch (0.30 stud)

local cached = nil

function Eggs.Load()
	if cached then
		return cached
	end
	assert(fs.isFile(Eggs.DATA_PATH), Eggs.DATA_PATH .. " missing: run scripts/tools/blender/hero_eggs/export_parts.py")
	cached = serde.decode("json", fs.readFile(Eggs.DATA_PATH))
	return cached
end

function Eggs.Ids()
	local ids = {}
	for id in pairs(Eggs.Load().eggs) do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

-- A SmoothPlastic MaterialVariant with the kit's stud pitch, cloned from the base place's stud variant (same texture
-- maps, only StudsPerTile differs). Returns the variant name to use ("" when no source variant exists).
function Eggs.EnsureMaterialVariant(place, roblox)
	local Enum = roblox.Enum
	local ms = place:GetService("MaterialService")
	for _, d in ipairs(ms:GetChildren()) do
		if d:IsA("MaterialVariant") and d.Name == Eggs.EGG_VARIANT then
			return Eggs.EGG_VARIANT
		end
	end
	local source = nil
	for _, d in ipairs(ms:GetDescendants()) do
		if d:IsA("MaterialVariant") and d.Name == Eggs.VARIANT_SOURCE and d.BaseMaterial == Enum.Material.SmoothPlastic then
			source = d
			break
		end
	end
	if not source then
		print("[hero_egg_models] WARNING: MaterialVariant '" .. Eggs.VARIANT_SOURCE .. "' not found; eggs use plain SmoothPlastic")
		return ""
	end
	local variant = source:Clone()
	variant.Name = Eggs.EGG_VARIANT
	variant.StudsPerTile = Eggs.STUDS_PER_TILE
	variant.Parent = ms
	return Eggs.EGG_VARIANT
end

local function color3(roblox, hex)
	return roblox.Color3.fromRGB(tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16),
		tonumber(string.sub(hex, 5, 6), 16))
end

-- Builds Model "<heroId>" with its pivot at `pivot` (default the origin). variantName from EnsureMaterialVariant.
-- opts.scale (default 1) scales every part and offset; opts.rootName (default "Hitbox") names the PrimaryPart.
function Eggs.Build(roblox, heroId, variantName, pivot, opts)
	local Instance, Vector3, CFrame, Enum = roblox.Instance, roblox.Vector3, roblox.CFrame, roblox.Enum
	local data = Eggs.Load()
	local egg = data.eggs[heroId]
	assert(egg, "no voxel egg for hero " .. tostring(heroId))
	pivot = pivot or CFrame.new()
	opts = opts or {}
	local k = opts.scale or 1
	local neon = {}
	for _, key in ipairs(data.neon) do
		neon[key] = true
	end

	local model = Instance.new("Model")
	model.Name = heroId

	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = Vector3.new(-math.huge, -math.huge, -math.huge)
	local parts = {}
	for index, p in ipairs(egg.parts) do
		local key = p[1]
		local local_ = CFrame.new(p[2] * k, p[3] * k, p[4] * k, p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16])
		local size = Vector3.new(p[5] * k, p[6] * k, p[7] * k)
		local part = Instance.new("Part")
		part.Name = string.format("V%03d", index)
		part.Size = size
		part.CFrame = pivot * local_
		part.Color = color3(roblox, data.colors[key])
		if neon[key] then
			part.Material = Enum.Material.Neon
		else
			part.Material = Enum.Material.SmoothPlastic
			if variantName and variantName ~= "" then
				part.MaterialVariant = variantName
			end
		end
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.CastShadow = size.X * size.Y * size.Z > 0.02 * k * k * k
		part:SetAttribute("EggColor", key)
		part:SetAttribute("DontModify", true)
		part.Parent = model
		table.insert(parts, part)
		-- bounding box in the egg's own space
		local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					local c = (local_ * CFrame.new(sx * hx, sy * hy, sz * hz)).Position
					lo = Vector3.new(math.min(lo.X, c.X), math.min(lo.Y, c.Y), math.min(lo.Z, c.Z))
					hi = Vector3.new(math.max(hi.X, c.X), math.max(hi.Y, c.Y), math.max(hi.Z, c.Z))
				end
			end
		end
	end

	local root = Instance.new("Part")
	root.Name = opts.rootName or "Hitbox"
	root.Size = hi - lo
	root.CFrame = pivot * CFrame.new((lo + hi) / 2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Massless = true
	root.CastShadow = false
	root.Parent = model
	model.PrimaryPart = root

	for _, part in ipairs(parts) do
		local weld = Instance.new("WeldConstraint")
		weld.Name = "EggWeld"
		weld.Part0 = root
		weld.Part1 = part
		weld.CFrame0 = root.CFrame:ToObjectSpace(part.CFrame)
		weld.Parent = part
	end

	model.WorldPivotData = pivot
	model:SetAttribute("HeroEgg", true)
	model:SetAttribute("HeroId", heroId)
	model:SetAttribute("Stage", egg.stage)
	model:SetAttribute("Rarity", egg.rarity)
	model:SetAttribute("BossScale", egg.bossScale)
	model:SetAttribute("EggHeight", egg.height * k)
	model:SetAttribute("PartCount", #parts)
	return model
end

return Eggs
