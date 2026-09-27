-- scripts/steps/post_purge.luau
-- Post-hero build step (D1, docs/VISUAL_PASS_PLAN.md): only the 38 game-plan heroes (+ the 6 stage villains, which
-- are guard rigs and have no asset config) may exist. Runs after scripts/hero_system_builder.luau, which has already
-- built every roster hero's config, AssetModel, egg and R6 rig and generated ReplicatedStorage.Directory.HeroCatalog.
--
-- What it removes / neutralises (everything below was verified unreferenced by name, or is rewritten so no code path
-- indexes a removed id - Directory.Assets.Directory is a MakeTableStrict table, so indexing a removed id ERRORS):
--   1. Directory.Assets._Index, ReplicatedStorage.AssetModels, Assets.Models.Eggs, Assets.Models.Heroes: every entry
--      that is not a HeroCatalog.List id (the 84 base-place animals/brainrots, e.g. Chicken, Dog, Dragon, Tung Tung
--      Sahur). The hero builder used Eggs.Chicken as its egg TEMPLATE before this step; that clone is done by now.
--   2. Legacy pet/brainrot leftovers nobody references: Assets.Models.PetAssets (Pig, Cow, Cat, Dog...),
--      Assets.Animations.PetAnimations, Assets.Models.AssetEggModels(+WithBones) (empty), Assets.VFX.WildBrainrots,
--      the "Random Brainrot Block" lucky-block model, ReplicatedStorage.AssetMutationTargets/Replacements (empty
--      per-asset mutation folders; only Debug.Cmd tools name them, through a nil-safe lookup).
--   3. Directory.LimitedEgg (six brainrots) and Directory.AdminAbuseEgg (six demons): rewritten as empty, nil-safe
--      data modules with the same fields/functions (the Index iterates LimitedEgg.Entries through the strict Assets
--      table; Assets / EggScaleUtil call AdminAbuseEgg.IsEventCategory). The four Directory.Products._Index.LimitedEggs
--      product configs (another game's product ids, their callback rolls LimitedEgg.DropTable) are removed.
--   4. Leftover debug attributes naming the animals (Workspace.Claude*, ServerScriptService.AssetsTest/...).
--   5. User-facing template texts that name a removed asset or say "brainrot" (e.g. "+1 Tung Tung Sahur",
--      "Huge Flaming Bull Egg", "Brainrots") -> hero wording. Text only; instance names are never changed.
-- Guard: if the hero builder's output is incomplete (a lenient build skipped it), the step errors instead of
-- purging - deleting the animals without the heroes in place would leave the game with no assets at all.
-- Idempotent.

local luau = require("@lune/luau")

local Step = {}

local function childPath(root, path)
	local node = root
	for _, name in ipairs(string.split(path, ".")) do
		node = node and node:FindFirstChild(name)
	end
	return node
end

-- Destroys every child of `folder` whose name is not in `keep`; returns the sorted removed names.
local function purgeChildren(folder, keep)
	local removed = {}
	if not folder then
		return removed
	end
	for _, child in ipairs(folder:GetChildren()) do
		if not keep[child.Name] then
			table.insert(removed, child.Name)
			child:Destroy()
		end
	end
	table.sort(removed)
	return removed
end

local LIMITED_EGG_SOURCE = [[
-- ReplicatedStorage.Directory.LimitedEgg
-- NEUTRALISED by scripts/steps/post_purge.luau (D1, docs/VISUAL_PASS_PLAN.md). The base game's limited egg rolled
-- six legacy brainrots that no longer exist, and Steal a Hero has no limited egg: the drop list is empty, so every
-- consumer degrades to a no-op (the Index builds no limited-egg entries, AmonetizationPurchaseService's pcall'd
-- limited-egg grant rolls nothing, and the Products.LimitedEggs configs were removed with this step).
return table.freeze({
	DropTable = table.freeze({}),
	Entries = table.freeze({}),
	Offers = table.freeze({}),
})
]]

local ADMIN_ABUSE_EGG_SOURCE = [[
-- ReplicatedStorage.Directory.AdminAbuseEgg
-- NEUTRALISED by scripts/steps/post_purge.luau (D1, docs/VISUAL_PASS_PLAN.md). The base game's admin-abuse
-- "Demonic Egg" event rolled six legacy demons that no longer exist; the event's server half was never part of this
-- place. Same fields and functions as before, but no asset is an event category and nothing can be rolled.
local AdminAbuseEgg = {
	EggDisplayName = "Demonic Egg",
	DropTable = {},
}

function AdminAbuseEgg.IsEventCategory(_category: string?)
	return false
end

function AdminAbuseEgg.GetTotalWeight()
	return 0
end

function AdminAbuseEgg.Roll(_random)
	return nil
end

return AdminAbuseEgg
]]

-- Leftover debug attributes on services (written by earlier tooling into the base place).
local DEBUG_ATTRIBUTES = {
	ServerScriptService = { "AssetsTest", "TreadmillsTest", "BootTest" },
}

-- Template placeholders that are neither a removed asset id nor the word "brainrot" but are animal jokes.
local PLACEHOLDER_REWRITES = {
	{ "Dog Poop", "1.0 kg" }, -- the Weight label of the backpack / fuse item templates (runtime overwrites it)
	{ "Dragonfly", "Hero" }, -- the PetList notepad template name
}

-- "brainrot" wording -> hero wording (count-aware phrases first).
local BRAINROT_REWRITES = {
	{ "Brainrot Hatched", "Heroes Hatched" },
	{ "Brainrot Placed", "Heroes Placed" },
	{ "BRAINROTS", "HEROES" },
	{ "Brainrots", "Heroes" },
	{ "brainrots", "heroes" },
	{ "BRAINROT", "HERO" },
	{ "Brainrot", "Hero" },
	{ "brainrot", "hero" },
}

local function replacePlain(text, from, to)
	local out, start, changed = {}, 1, false
	while true do
		local i, j = string.find(text, from, start, true)
		if not i then
			break
		end
		table.insert(out, string.sub(text, start, i - 1))
		table.insert(out, to)
		start = j + 1
		changed = true
	end
	if not changed then
		return text
	end
	table.insert(out, string.sub(text, start))
	return table.concat(out)
end

-- Replaces whole-word occurrences of `word` (letters/digits around it block the match).
local function replaceWord(text, word, to)
	local escaped = string.gsub(word, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
	local result = string.gsub(text, "%f[%w]" .. escaped .. "%f[%W]", (string.gsub(to, "%%", "%%%%")))
	return result
end

function Step.Apply(place, _spPlace, ctx)
	local roblox = ctx.roblox
	local rs = place:GetService("ReplicatedStorage")
	local ws = place.Workspace

	-- 0. the roster = HeroCatalog.List, as generated by the hero builder
	local catalogModule = childPath(rs, "Directory.HeroCatalog")
	assert(catalogModule and catalogModule:IsA("ModuleScript"), "[post_purge] ReplicatedStorage.Directory.HeroCatalog missing")
	local catalog = luau.load(catalogModule.Source, {
		debugName = "HeroCatalog",
		environment = { Color3 = roblox.Color3 },
	})()
	assert(type(catalog) == "table" and type(catalog.List) == "table" and #catalog.List > 0, "[post_purge] HeroCatalog.List is empty")

	local assetsIndex = childPath(rs, "Directory.Assets._Index")
	local assetModels = rs:FindFirstChild("AssetModels")
	local eggs = childPath(rs, "Assets.Models.Eggs")
	local heroRigs = childPath(rs, "Assets.Models.Heroes")
	assert(assetsIndex and assetModels and eggs, "[post_purge] Directory.Assets._Index / AssetModels / Assets.Models.Eggs missing")

	local keep, keepList, missing = {}, {}, {}
	for _, hero in ipairs(catalog.List) do
		keep[hero.Id] = true
		table.insert(keepList, hero.Id)
		local model = assetModels:FindFirstChild(hero.Id)
		if not assetsIndex:FindFirstChild(hero.Id) then
			table.insert(missing, "Directory.Assets._Index." .. hero.Id)
		end
		if not (model and model:GetAttribute("HeroId") == hero.Id) then
			table.insert(missing, "AssetModels." .. hero.Id .. " (R15 hero model)")
		end
		if not eggs:FindFirstChild(hero.Id) then
			table.insert(missing, "Assets.Models.Eggs." .. hero.Id)
		end
	end
	if #missing > 0 then
		error(string.format(
			"[post_purge] refusing to purge: the hero builder output is incomplete (%d missing: %s). The legacy assets are the only ones left in this place.",
			#missing,
			table.concat(missing, ", ", 1, math.min(#missing, 8))
		))
	end

	-- 1. every non-roster asset, wherever the game looks assets up by id
	local purgedIds = {}
	local removedConfigs = purgeChildren(assetsIndex, keep)
	for _, id in ipairs(removedConfigs) do
		purgedIds[id] = true
	end
	local removedModels = purgeChildren(assetModels, keep)
	for _, id in ipairs(removedModels) do
		purgedIds[id] = true
	end
	local removedEggs = purgeChildren(eggs, keep)
	for _, id in ipairs(removedEggs) do
		purgedIds[id] = true
	end
	local removedRigs = purgeChildren(heroRigs, keep)
	print(string.format(
		"[post_purge] Kept the %d roster heroes. Removed %d asset configs, %d AssetModels, %d egg models, %d R6 rigs: %s",
		#keepList, #removedConfigs, #removedModels, #removedEggs, #removedRigs,
		table.concat(removedConfigs, ", ")
	))

	-- 2. unreferenced legacy pet/brainrot content
	local leftovers = {}
	for _, path in ipairs({
		"Assets.Models.PetAssets",
		"Assets.Animations.PetAnimations",
		"Assets.Models.AssetEggModels",
		"Assets.Models.AssetEggModelsWithBones",
		"Assets.VFX.WildBrainrots",
		"Assets.Models.LuckyBlocks.Random Brainrot Block",
		"AssetMutationTargets",
		"AssetMutationReplacements",
	}) do
		local inst = childPath(rs, path)
		if inst then
			inst:Destroy()
			table.insert(leftovers, "ReplicatedStorage." .. path)
		end
	end
	print(string.format("[post_purge] Removed %d legacy pet/brainrot leftovers: %s", #leftovers, table.concat(leftovers, ", ")))

	-- 3. reward / event / product data that named the animals
	local neutralised = {}
	for _, spec in ipairs({
		{ path = "Directory.LimitedEgg", source = LIMITED_EGG_SOURCE },
		{ path = "Directory.AdminAbuseEgg", source = ADMIN_ABUSE_EGG_SOURCE },
	}) do
		local module = childPath(rs, spec.path)
		if module and module:IsA("ModuleScript") then
			local ok, err = pcall(luau.compile, spec.source)
			assert(ok, "[post_purge] neutralised " .. spec.path .. " does not compile: " .. tostring(err))
			for _, child in ipairs(module:GetChildren()) do
				child:Destroy() -- LimitedEgg's Types.Interface only typed the removed drop entries
			end
			module.Source = spec.source
			table.insert(neutralised, "ReplicatedStorage." .. spec.path)
		end
	end
	local limitedProducts = childPath(rs, "Directory.Products._Index.LimitedEggs")
	if limitedProducts then
		limitedProducts:Destroy()
		table.insert(neutralised, "ReplicatedStorage.Directory.Products._Index.LimitedEggs (removed)")
	end
	print("[post_purge] Neutralised: " .. table.concat(neutralised, ", "))

	-- 4. debug attributes that listed the animals
	local clearedAttributes = {}
	for name in pairs(ws:GetAttributes()) do
		if string.sub(name, 1, 6) == "Claude" then
			ws:SetAttribute(name, nil)
			table.insert(clearedAttributes, "Workspace." .. name)
		end
	end
	for serviceName, names in pairs(DEBUG_ATTRIBUTES) do
		local service = place:GetService(serviceName)
		for _, name in ipairs(names) do
			if service:GetAttribute(name) ~= nil then
				service:SetAttribute(name, nil)
				table.insert(clearedAttributes, serviceName .. "." .. name)
			end
		end
	end
	table.sort(clearedAttributes)
	print(string.format("[post_purge] Cleared %d debug attributes: %s", #clearedAttributes, table.concat(clearedAttributes, ", ")))

	-- 5. template texts. A removed id is only rewritten when it is not part of a roster/stage/villain name
	-- ("Spider" is in Spider-Gwen and Spider-Verse, "Dragon" in Dragon Ball).
	local protectedNames = {}
	for _, hero in ipairs(catalog.List) do
		table.insert(protectedNames, hero.DisplayName or hero.Id)
		table.insert(protectedNames, hero.Id)
	end
	for _, stage in ipairs(catalog.Stages or {}) do
		table.insert(protectedNames, stage.Name or "")
	end
	for _, villain in pairs(catalog.Villains or {}) do
		table.insert(protectedNames, villain.DisplayName or "")
	end
	local textIds = {}
	for id in pairs(purgedIds) do
		local clash = #id < 3
		for _, name in ipairs(protectedNames) do
			if not clash and string.find(" " .. name .. " ", "%f[%w]" .. string.gsub(id, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "%f[%W]") then
				clash = true
			end
		end
		if not clash then
			table.insert(textIds, id)
		end
	end
	table.sort(textIds, function(a, b)
		return #a > #b -- longest first ("Polar Bear" before "Bear")
	end)

	local changedTexts = {}
	for _, root in ipairs({ place:GetService("StarterGui"), rs, place:GetService("StarterPlayer"), ws }) do
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
				local before = d.Text
				local text = before
				for _, pair in ipairs(PLACEHOLDER_REWRITES) do
					text = replacePlain(text, pair[1], pair[2])
				end
				for _, id in ipairs(textIds) do
					text = replaceWord(text, id, "Hero")
				end
				for _, pair in ipairs(BRAINROT_REWRITES) do
					text = replacePlain(text, pair[1], pair[2])
				end
				if text ~= before then
					d.Text = text
					table.insert(changedTexts, string.format("%s: %q -> %q", d:GetFullName(), string.sub(before, 1, 60), string.sub(text, 1, 60)))
				end
			end
		end
	end
	print(string.format("[post_purge] Rewrote %d template texts naming legacy assets / brainrots:", #changedTexts))
	for _, line in ipairs(changedTexts) do
		print("[post_purge]   " .. line)
	end

	-- 6. nothing in the place may still be NAMED after a removed asset (instances only; code is verified offline)
	local stray = {}
	for _, d in ipairs(place:GetDescendants()) do
		if purgedIds[d.Name] and (d:IsA("Model") or d:IsA("ModuleScript") or d:IsA("Folder")) then
			table.insert(stray, d:GetFullName())
		end
	end
	if #stray > 0 then
		print(string.format("[post_purge] NOTE: %d instance(s) still named after a removed asset (left, not asset content): %s",
			#stray, table.concat(stray, ", ", 1, math.min(#stray, 10))))
	end
end

return Step
