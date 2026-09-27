-- StarterPlayer.StarterPlayerScripts.Game.AssetPreloader (LocalScript)
-- Owner 2026-09-23: "the first time you steal, the villain behaves dumb - maybe it needs a preloader". The first chase of
-- a session was the first time this client needed the villains' run / attack animations (only the idle had played so
-- far) and their meshes up close, so it downloaded them mid-chase: the villain slid in a frozen pose until the run
-- animation arrived and the first catch swing was missing. Later chases had them cached. This downloads them right after
-- join, in the background and in priority order:
--   1. the villain chase animations (mirror of GuardChaseService.ANIMATION_IDS: run, idle, attack),
--   2. the six stage villains (Workspace.__OBJECTS.Areas.GuardAreas.<Stage>.Guard: meshes, textures, clothing),
--   3. the hero models (ReplicatedStorage.AssetModels, ReplicatedStorage.Assets.Models.Heroes), a few at a time.
-- Nothing waits on it and failures are ignored (an asset then loads on first use, as before). No sounds.

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local VILLAIN_ANIMATION_IDS = {
	"rbxassetid://507767714", -- Run
	"rbxassetid://507766388", -- Idle
	"rbxassetid://522635514", -- Attack
}
local LOOKUP_TIMEOUT = 30
local HERO_BATCH_SIZE = 4
local HERO_BATCH_GAP = 0.25 -- seconds between hero batches, so the join is not one long download burst

local function preload(instances)
	if #instances == 0 then
		return
	end
	local ok, err = pcall(ContentProvider.PreloadAsync, ContentProvider, instances)
	if not ok then
		warn("[AssetPreloader] preload failed: " .. tostring(err))
	end
end

local function findPath(root, names)
	local node = root
	for _, name in ipairs(names) do
		node = node and node:FindFirstChild(name)
	end
	return node
end

task.spawn(function()
	-- 1. chase animations: Animation instances are what PreloadAsync fetches into the animation cache
	local animations = {}
	for index, animationId in ipairs(VILLAIN_ANIMATION_IDS) do
		local animation = Instance.new("Animation")
		animation.Name = "VillainChasePreload" .. index
		animation.AnimationId = animationId
		table.insert(animations, animation)
	end
	preload(animations)

	-- 2. the stage villains (each Guard model with all its descendants)
	local objects = Workspace:WaitForChild("__OBJECTS", LOOKUP_TIMEOUT)
	local areas = objects and objects:WaitForChild("Areas", LOOKUP_TIMEOUT)
	local guardAreas = areas and areas:WaitForChild("GuardAreas", LOOKUP_TIMEOUT)
	if guardAreas then
		local villains = {}
		for _, zone in ipairs(guardAreas:GetChildren()) do
			local guard = zone:FindFirstChild("Guard")
			if guard and guard:IsA("Model") then
				table.insert(villains, guard)
			end
		end
		preload(villains)
	end

	-- 3. hero models, a few per call
	for _, folder in ipairs({ ReplicatedStorage:FindFirstChild("AssetModels"), findPath(ReplicatedStorage, { "Assets", "Models", "Heroes" }) }) do
		if folder then
			local batch = {}
			for _, hero in ipairs(folder:GetChildren()) do
				table.insert(batch, hero)
				if #batch >= HERO_BATCH_SIZE then
					preload(batch)
					batch = {}
					task.wait(HERO_BATCH_GAP)
				end
			end
			preload(batch)
		end
	end
end)
