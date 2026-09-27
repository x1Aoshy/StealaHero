--!nocheck
-- scripts/steps/post_hero_eggs.luau
-- The Hero Eggs kit (assets/eggs: 44 faceless voxel costume eggs, 38 heroes + 6 bosses; owner 2026-09-26: "make diff
-- designs for all the eggs ... iron man should be more iron man alike ... miles morales more alike to his ... more
-- texture on them") replaces the generic painted egg of every hero.
--
-- Every runtime egg visual (stage nests, the carried egg, the egg tool, placed / growing eggs, the hatch) clones
-- ReplicatedStorage.Assets.Models.Eggs[<HeroId>] through Library.Client.Eggs.EggRenderer.RenderVisual, so swapping
-- those 38 templates changes every egg in the game. Each egg is built from assets/eggs/egg_parts.json by
-- scripts/lib/hero_egg_models.luau (plain Parts: no Studio import, no asset upload):
--   * PrimaryPart "Hitbox" (invisible, the weld hub); every visible part welded to it, so EggActionMovement /
--     BulkMove (which only moves the PrimaryPart) and ScaleTo carry the whole egg;
--   * DontModify on every part (AssetColorUtil.Apply must not shift the costume colours);
--   * the kit's square-stud finish -> SmoothPlastic + MaterialVariant "HeroEggStud" (the base place's stud texture at
--     STUDS_PER_TILE), the kit's glow / gem colours -> Neon;
--   * sized to HERO_EGG_HEIGHT studs (the kit is 3.2 studs tall; the game scales egg templates itself: nests fit the
--     nest, placed eggs grow to 3x), front = -Z, Model scale 1, attribute HeroId.
-- The 6 boss eggs (Thanos, Darkseid, Carnage, Shigaraki, Frieza, Kaido: no hero config, not droppable) are stored in
-- ReplicatedStorage.Assets.Models.BossEggs at the same scale for later use (post_purge only prunes Models.Eggs).
-- Runs after post_egg_colors (which painted the old eggs) and before post_purge, in name order (build step 12b).
-- Regenerate the part lists: "blender -b --factory-startup --python scripts/tools/blender/hero_eggs/export_parts.py".

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local HeroEggs = require("../lib/hero_egg_models")

local Instance = roblox.Instance

local Step = {}

Step.HERO_EGG_HEIGHT = 1.0 -- studs, whole egg incl. hats / weapons (the old painted egg was 0.82)
Step.STUDS_PER_TILE = 0.25 -- stud pitch of the egg finish (in hand ~4 studs tall, placed eggs ~12)
Step.BOSS_FOLDER = "BossEggs"

local function log(fmt, ...)
	print(string.format("[post_hero_eggs] " .. fmt, ...))
end

local function rosterIds()
	local path = "src/ReplicatedStorage/Directory/HeroCatalog.luau"
	local ok, catalog = pcall(function()
		return luau.load(fs.readFile(path), { debugName = path })()
	end)
	if not ok or type(catalog) ~= "table" then
		return nil
	end
	local list = catalog.List or catalog.Heroes or catalog
	local ids = {}
	for key, entry in pairs(list) do
		local id = type(entry) == "table" and (entry.Id or entry.id) or (type(key) == "string" and key or nil)
		if type(id) == "string" then
			ids[id] = true
		end
	end
	return ids
end

function Step.Apply(place, _spPlace, _ctx)
	local rs = place:GetService("ReplicatedStorage")
	local assets = rs:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	local eggs = models and models:FindFirstChild("Eggs")
	assert(eggs, "[post_hero_eggs] ReplicatedStorage.Assets.Models.Eggs missing")

	HeroEggs.STUDS_PER_TILE = Step.STUDS_PER_TILE
	local variant = HeroEggs.EnsureMaterialVariant(place, roblox)
	local ms = place:GetService("MaterialService")
	local mv = ms:FindFirstChild(HeroEggs.EGG_VARIANT)
	if mv then
		mv.StudsPerTile = Step.STUDS_PER_TILE
	end

	local roster = rosterIds()
	local bossFolder = models:FindFirstChild(Step.BOSS_FOLDER)
	if not bossFolder then
		bossFolder = Instance.new("Folder")
		bossFolder.Name = Step.BOSS_FOLDER
		bossFolder.Parent = models
	end

	local replaced, bosses, parts, missing = 0, 0, 0, {}
	for _, id in ipairs(HeroEggs.Ids()) do
		local data = HeroEggs.Load().eggs[id]
		local scale = Step.HERO_EGG_HEIGHT / (data.height / data.bossScale)
		local old = eggs:FindFirstChild(id)
		local isHero = old ~= nil or (roster ~= nil and roster[id] == true)
		local parent = isHero and eggs or bossFolder
		-- keep the template where the old one sat (only its pivot matters; nothing reads the storage position)
		local pivot = roblox.CFrame.new()
		if old and old:IsA("Model") then
			local ok, wp = pcall(function()
				return old.WorldPivotData
			end)
			if ok and typeof(wp) == "CFrame" then
				pivot = roblox.CFrame.new(wp.Position)
			end
		end
		local egg = HeroEggs.Build(roblox, id, variant, pivot, { scale = scale, rootName = "Hitbox" })
		egg:SetAttribute("HeroId", id)
		egg:SetAttribute("VoxelEgg", true)
		if old then
			old:Destroy()
		end
		local stale = parent:FindFirstChild(id)
		while stale do
			stale:Destroy()
			stale = parent:FindFirstChild(id)
		end
		egg.Parent = parent
		parts += egg:GetAttribute("PartCount")
		if isHero then
			replaced += 1
		else
			bosses += 1
		end
	end
	for id in pairs(roster or {}) do
		local egg = eggs:FindFirstChild(id)
		if not egg or egg:GetAttribute("VoxelEgg") ~= true then
			table.insert(missing, id)
		end
	end
	table.sort(missing)
	log("Voxel hero eggs: %d hero eggs replaced in Assets.Models.Eggs, %d boss eggs in Assets.Models.%s (%d parts, %.2f studs tall, MaterialVariant %s @ %.2f).",
		replaced, bosses, Step.BOSS_FOLDER, parts, Step.HERO_EGG_HEIGHT, variant ~= "" and variant or "(none)", Step.STUDS_PER_TILE)
	if #missing > 0 then
		log("!! roster heroes without a voxel egg (kept their old egg): %s", table.concat(missing, ", "))
	end
end

return Step
