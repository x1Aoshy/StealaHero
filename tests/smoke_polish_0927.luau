--!nocheck
-- tests/smoke_polish_0927.luau (owner pass 2026-09-27, second round). Joins the "smoke" filter. Checks, against the
-- built place:
--   1. villains: one clip module per boss (Idle / Wake / Move / Walk / Attack) in ReplicatedStorage.Directory
--      .VillainAnimations, the client player injected, the server loads no track for them, the C0 punch gives way;
--   2. the grab animation squats forward (Waist leans forward, knees bend) and the villain carry frees the arms;
--   3. the night wall spans the whole lane opening between the hub's east walls;
--   4. hero slots in the inventory mount the hero's headshot; the topbar keeps its round corners;
--   5. the Hero Index claimed state is a muted green; the hotbar slots are charcoal; the pixel night icon script is in.

local place = H.place()
local rs = place:GetService("ReplicatedStorage")
local sps = place:GetService("StarterPlayer").StarterPlayerScripts
local sss = place:GetService("ServerScriptService")
local ws = place:GetService("Workspace")

local function src(inst)
	return inst and H.normalize(inst.Source) or ""
end

-- 1. villain clips
local folder = H.path(rs, "Directory/VillainAnimations")
for _, villain in ipairs({ "Thanos", "Darkseid", "Carnage", "Shigaraki", "Frieza", "Kaido" }) do
	local module = folder and folder:FindFirstChild(villain)
	local text = src(module)
	local ok = module ~= nil and module:IsA("ModuleScript") and pcall(H.luau.compile, text)
	for _, clip in ipairs({ "Idle", "Wake", "Move", "Walk", "Attack" }) do
		ok = ok and H.has(text, "\t\t" .. clip .. " = {")
	end
	T.check(ok, "VillainAnimations.%s must hold Idle / Wake / Move / Walk / Attack clips", villain)
end
local player = H.path(sps, "Game/VillainClipPlayer")
T.check(player ~= nil and player:IsA("LocalScript") and pcall(H.luau.compile, src(player)) and H.has(src(player), "motor.Transform =")
	and H.has(src(player), "PreRender"), "Game.VillainClipPlayer must be injected and write the villains' Motor6D.Transform")
local chase = H.path(sss, "Controllers/GuardChaseService")
T.check(H.has(src(chase), "local function hasClientClips(") and H.has(src(chase), "if hasClientClips(guardModel) then {} else loadTracks("),
	"GuardChaseService must load no Animator track for villains with clips")
local chaseFx = H.path(sps, "Game/VillainChaseFx")
T.check(H.has(src(chaseFx), "GetAttribute(\"ClientClips\") ~= true"), "VillainChaseFx must leave the catch hit to the villain's Attack clip")

-- 2. grab / carry
local areaEggs = H.path(sps, "Game/AreaEggs")
local eggsSrc = src(areaEggs)
T.check(H.has(eggsSrc, "Waist = { -38, 0, 0 }") and H.has(eggsSrc, "RightKnee = { -82, 0, 0 }") and H.has(eggsSrc, "local GRAB_TIME = 0.85"),
	"the grab must squat forward (Waist -38, knees -82) over 0.85 s")
T.check(H.has(eggsSrc, "guard:SetAttribute(\"ClipArmsHeld\", true)"), "the villain carry must free the clip's arms (ClipArmsHeld)")

-- 3. night wall
local wall = H.path(ws, "__OBJECTS/Areas/WallStartVisual")
local south = H.path(ws, "WorldWalls/Hub/HubWall_EastSouth")
local north = H.path(ws, "WorldWalls/Hub/HubWall_EastNorth")
if T.check(wall ~= nil and south ~= nil and north ~= nil, "night wall / hub east walls missing") then
	local wmn, wmx = H.aabb(wall)
	local _, smx = H.aabb(south)
	local nmn = H.aabb(north)
	T.check(wmn.Z <= smx.Z + 0.01 and wmx.Z >= nmn.Z - 0.01, "the night wall (Z %.1f..%.1f) must close the lane opening (Z %.1f..%.1f)", wmn.Z, wmx.Z,
		smx.Z, nmn.Z)
end

-- 4. inventory portraits / round topbar
local backpack = H.path(sps, "GUI/BackpackController/Main")
T.check(H.has(src(backpack), "function mountHeroPortrait(") and H.has(src(backpack), "if not mountHeroPortrait(Icon, v1084) then"),
	"hero slots must mount the hero's headshot (HeroPortrait)")
local squareUi = H.path(sps, "GUI/SquareUi")
T.check(H.has(src(squareUi), "local function isTopbar(") and H.has(src(squareUi), "not isTopbar(corner)"), "SquareUi must leave the topbar round")

-- 5. claimed muted green / charcoal hotbar / pixel night icon
local claim = nil
for _, d in ipairs(place:GetService("StarterGui"):GetDescendants()) do
	if d.Name == "GreyGradient" and d.Parent and d.Parent.Name == "TextButton" and d.Parent.Parent and d.Parent.Parent.Name == "ClaimButton" then
		claim = d
	end
end
if T.check(claim ~= nil, "Index ClaimButton.TextButton.GreyGradient missing") then
	local c = claim.Color.Keypoints[1].Value
	T.check(c.G > c.R and c.G > c.B and c.G < 0.8, "the claimed Index button must be a muted green (first key %s)", tostring(c))
end
local main = H.path(sps, "GUI/BackpackController/Main")
local bg = main and main:GetAttribute("BackgroundColor")
T.check(typeof(bg) == "Color3" and math.max(bg.R, bg.G, bg.B) < 0.25 and math.abs(bg.R - bg.B) < 0.08, "hotbar slots must be charcoal (BackgroundColor %s)",
	tostring(bg))
local pixel = H.path(sps, "GUI/PixelNightIcon")
T.check(pixel ~= nil and pcall(H.luau.compile, src(pixel)), "GUI.PixelNightIcon must be injected and compile")
