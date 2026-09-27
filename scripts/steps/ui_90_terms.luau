--!nocheck
-- scripts/steps/ui_90_terms.luau (owner WINDOWS; VISUAL_PASS_PLAN D7: "Pets" -> "Heroes" in every user-facing text)
-- Runs last among the ui_* steps (name order), after every window / HUD / world GUI step, so it also sees the text
-- those steps wrote. Rewrites the legacy creature words of Steal an Egg in user-facing text only:
--   pet(s) -> hero(es) and brainrot(s) -> hero(es), whole words, case kept (Pets -> Heroes, PETS -> HEROES,
--   pet -> hero), rich-text tags untouched;
--   in TextLabel / TextButton / TextBox .Text and TextBox .PlaceholderText under StarterGui, StarterPlayer (GUI
--   templates kept by client scripts), ReplicatedStorage.Assets.UI, every BillboardGui / SurfaceGui template in
--   ReplicatedStorage and every BillboardGui / SurfaceGui in Workspace; ProximityPrompt ActionText / ObjectText in
--   Workspace and ReplicatedStorage.
-- Never touched: instance Names, attributes, script Sources (strings that scripts write at runtime are patched in
-- their src files, injected by scripts/inject/windows.luau per CONTRACTS rule 4), identifiers such as PetList,
-- PetArea or PET_UUID (a word must stand alone: letters, digits and "_" around it block the match).
-- Idempotent (the replacement words never match again). Apply(place, spPlace, ctx) prints one summary line.

local Step = {}

-- whole-word replacements, most specific first
local RULES = {
	{ "PETS", "HEROES" }, { "Pets", "Heroes" }, { "pets", "heroes" },
	{ "PET", "HERO" }, { "Pet", "Hero" }, { "pet", "hero" },
	{ "BRAINROTS", "HEROES" }, { "Brainrots", "Heroes" }, { "brainrots", "heroes" },
	{ "BRAINROT", "HERO" }, { "Brainrot", "Hero" }, { "brainrot", "hero" },
}

-- Returns the rewritten text and the number of words replaced.
function Step.rewrite(text)
	if type(text) ~= "string" or text == "" then
		return text, 0
	end
	local out, total = text, 0
	for _, rule in ipairs(RULES) do
		local count
		out, count = string.gsub(out, "%f[%w_]" .. rule[1] .. "%f[^%w_]", rule[2])
		total += count
	end
	return out, total
end

local TEXT_CLASSES = { TextLabel = true, TextButton = true, TextBox = true }

local function rewriteProperty(inst, property, stats)
	local ok, value = pcall(function()
		return inst[property]
	end)
	if not ok or type(value) ~= "string" then
		return
	end
	local new, count = Step.rewrite(value)
	if count > 0 then
		inst[property] = new
		stats.words += count
		stats.objects += 1
		if #stats.samples < 12 then
			table.insert(stats.samples, string.format("%s.%s %q -> %q", inst:GetFullName(), property, value, new))
		end
	end
end

local function visitText(inst, stats)
	if TEXT_CLASSES[inst.ClassName] then
		rewriteProperty(inst, "Text", stats)
		if inst.ClassName == "TextBox" then
			rewriteProperty(inst, "PlaceholderText", stats)
		end
	end
end

local function visitPrompt(inst, stats)
	if inst.ClassName == "ProximityPrompt" then
		rewriteProperty(inst, "ActionText", stats)
		rewriteProperty(inst, "ObjectText", stats)
	end
end

-- every text object under `root` (root included)
local function textPass(root, stats)
	if root == nil then
		return
	end
	visitText(root, stats)
	for _, d in ipairs(root:GetDescendants()) do
		visitText(d, stats)
	end
end

-- the text of every BillboardGui / SurfaceGui under `root`, and its ProximityPrompts
local function worldPass(root, stats)
	if root == nil then
		return
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			textPass(d, stats)
		else
			visitPrompt(d, stats)
		end
	end
end

function Step.Apply(place, _spPlace, _ctx)
	local rs = place:GetService("ReplicatedStorage")
	local stats = { words = 0, objects = 0, samples = {} }

	textPass(place:GetService("StarterGui"), stats)
	textPass(place:GetService("StarterPlayer"), stats)
	local assets = rs:FindFirstChild("Assets")
	local assetsUI = assets and assets:FindFirstChild("UI")
	textPass(assetsUI, stats)
	-- ReplicatedStorage GUI templates outside Assets.UI (a BillboardGui already visited in Assets.UI is harmless:
	-- the pass is idempotent)
	worldPass(rs, stats)
	worldPass(place:GetService("Workspace"), stats)

	for _, sample in ipairs(stats.samples) do
		print("[ui_90_terms]   " .. sample)
	end
	print(string.format("[ui_90_terms] Pets/Brainrot -> Heroes: %d words in %d user-facing texts rewritten", stats.words, stats.objects))
end

return Step
