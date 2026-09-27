local ServerScriptService = game:GetService("ServerScriptService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

-- Collision groups (NPC pass 2026-09-26, owner: players must never physically collide with NPCs). Registered here,
-- first thing on the server (groups replicate to every client); every registration is guarded because other scripts
-- register the same names defensively (GuardChaseService, the hub podium) and RegisterCollisionGroup errors on a
-- name that exists.
--   Players     every player character part - assigned below for every character, unconditionally
--               (GuardChaseService assigns the same group when the chase runs; both are idempotent)
--   NPCs        pen heroes (ItemDisplay.CreateWanderingAssetModel, client side) and the hub podium avatars
--   Guards      stage villains (GuardChaseService; its path / line-of-sight probes raycast as "Guards")
--   HoverProbe  holds no parts: the pen hero hover raycast (ModelMouseHover) - it used to raycast as "Players", which
--               no longer sees NPCs
-- Pass-through pairs: Players-NPCs, Players-Guards, Guards-Guards, Guards-NPCs, NPCs-NPCs, HoverProbe-Guards.
-- Colliding pairs: Players-Players (as in the base game), everything with Default, HoverProbe-Players/NPCs.
-- Other names found on parts of the base place (GuardsNoCollide, MobOnlyNoCollisions, LuckyBlocks, TreadmillModel,
-- Player, Orbs, NoCollide, Custom, no_collisions, d, Objects) are deliberately NOT registered: unregistered names act
-- as Default, which is what those parts need (they are CanCollide = false or visible props), and registering them
-- would only add groups with default (all-colliding) rules.
local COLLISION_GROUPS = { "Players", "NPCs", "Guards", "HoverProbe" }
local COLLISION_RULES = {
	{ "Players", "NPCs", false },
	{ "Players", "Guards", false },
	{ "Guards", "Guards", false },
	{ "Guards", "NPCs", false },
	{ "NPCs", "NPCs", false },
	{ "HoverProbe", "Guards", false },
	{ "Players", "Players", true },
	{ "Guards", "Default", true },
	{ "NPCs", "Default", true },
	{ "HoverProbe", "Default", true },
	{ "HoverProbe", "Players", true },
	{ "HoverProbe", "NPCs", true },
}
for _, g in ipairs(COLLISION_GROUPS) do
	pcall(function()
		if not PhysicsService:IsCollisionGroupRegistered(g) then
			PhysicsService:RegisterCollisionGroup(g)
		end
	end)
end
for _, rule in ipairs(COLLISION_RULES) do
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(rule[1], rule[2], rule[3])
	end)
end

-- Every part of every player character goes in "Players" (also parts added later: tools, held heroes, accessories).
local PLAYER_COLLISION_GROUP = "Players"
local function assignPlayerGroup(descendant)
	if descendant:IsA("BasePart") and descendant.CollisionGroup ~= PLAYER_COLLISION_GROUP then
		pcall(function()
			descendant.CollisionGroup = PLAYER_COLLISION_GROUP
		end)
	end
end
local function onCharacterAdded(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		assignPlayerGroup(descendant)
	end
	character.DescendantAdded:Connect(assignPlayerGroup)
end
local function hookPlayer(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end
Players.PlayerAdded:Connect(hookPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	hookPlayer(player)
end

local function safeRequire(moduleScript)
	local ok, err = pcall(require, moduleScript)
	if not ok then warn("[Bootstrap] Failed to require " .. moduleScript:GetFullName() .. ": " .. tostring(err)) end
	return ok
end
warn("[Bootstrap] Starting server initialization...")
local library = ServerScriptService:WaitForChild("Library")
safeRequire(library:WaitForChild("Database"))
local controllers = ServerScriptService:WaitForChild("Controllers")
local order = {"PlotService", "SpeedService", "LeaderstatsService", "GamepassService", "TreadmillService", "TreadmillGamepassService", "SpeedBoostGamepassService", "ConsumableGamepassService", "GroupRewardService", "TreadmillGrindService", "TreadmillSpawnService", "EggService", "AreaEggService", "AssetService", "OfflineAssetsService", "IndexService", "FuseMachineService", "AmonetizationPurchaseService", "GuardTutorialService", "SettingsService", "StubService"}
for _, name in ipairs(order) do
	local module = controllers:FindFirstChild(name)
	if module then safeRequire(module) else warn("[Bootstrap] Missing controller: " .. name) end
end
warn("[Bootstrap] Server initialization complete.")
