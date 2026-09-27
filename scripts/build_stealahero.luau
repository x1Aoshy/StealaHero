-- scripts/build_stealahero.luau
-- Lune master build pipeline for Steal a Hero
-- Produces a clean, optimized StealaHero.rbxl with 6 plots on a solid Baseplate, Speedters Heroes, and Speedters UIs.
-- Strips all ripped bloat (unauthorized sounds, broken DataStore dependencies, brainrot models, exploit scripts).

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

-- Build options (env vars):
--   STEALAHERO_OUT=<path>   output place file (default StealaHero.rbxl) so parallel builds never clobber each other
--   STEALAHERO_LENIENT=1    a failing build step is logged and skipped instead of aborting the build
local OUT_PATH = process.env.STEALAHERO_OUT or "StealaHero.rbxl"
local LENIENT = process.env.STEALAHERO_LENIENT == "1"
local failedSteps = {}

-- Runs a named build step. Steps live in their own modules (scripts/steps/*.luau) so each
-- subsystem owner can change its step without touching this file.
local function runStep(name, fn)
    if not LENIENT then
        fn()
        return true
    end
    local ok, err = pcall(fn)
    if not ok then
        table.insert(failedSteps, name)
        print(string.format("[StealaHero Build] !! STEP '%s' FAILED (lenient mode, skipped): %s", name, tostring(err)))
    end
    return ok
end

print("[StealaHero Build] Starting clean master build pipeline...")

-- A Studio save of the output file may hold Blender base pens the owner imported (ServerStorage.BaseThemeImports):
-- keep them as assets/models/bases/<Key>/<Variant>.rbxm before this build overwrites the file (post_zz_base_themes).
do
    local ok, err = pcall(function()
        require("./lib/base_imports").fromPlaceFile(OUT_PATH)
    end)
    if not ok then
        print("[StealaHero Build] base imports check skipped: " .. tostring(err))
    end
end

-- The same for the owner's hero weapon models (ServerStorage.HeroWeaponImports, assets/hero_weapons/HeroWeaponsImport.lua):
-- keep them as assets/hero_weapons/imports/{weapons,vfx}/<Name>.rbxm (post_hero_weapons).
do
    local ok, err = pcall(function()
        require("./lib/hero_weapon_imports").fromPlaceFile(OUT_PATH)
    end)
    if not ok then
        print("[StealaHero Build] hero weapon imports check skipped: " .. tostring(err))
    end
end

local raw = fs.readFile("Steal An Egg with treadmill V2.rbxl")
local place = roblox.deserializePlace(raw)
local ws = place.Workspace
local rs = place:GetService("ReplicatedStorage")
local sss = place:GetService("ServerScriptService")
local starterGui = place:GetService("StarterGui")
local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local soundService = place:GetService("SoundService")

-- Pre-load Speedters place for hero rigs and UI assets
local spPlace = nil
-- External Speedsters sources: the repo carries a snapshot in vendor/Update2 (cloud sessions); the owner's local
-- Update2 folder is the fallback. STEALAHERO_UPDATE2 overrides the folder.
local UPDATE2_DIR = process.env.STEALAHERO_UPDATE2
    or (if fs.isDir("vendor/Update2") then "vendor/Update2" else "c:/Users/Aoshy´/Desktop/Update2")
local spPlacePath = UPDATE2_DIR .. "/World1Update3New.rbxl"
if fs.isFile(spPlacePath) then
    local spRaw = fs.readFile(spPlacePath)
    spPlace = roblox.deserializePlace(spRaw)
    print("[StealaHero Build] Loaded Speedters place (World1Update3New.rbxl) for assets.")
end

-- 1. Clean up legacy bloat from Workspace (KEEP Stands and essential gameplay structures)
print("[StealaHero Build] Cleaning up legacy bloat from Workspace...")
-- NOTE: the four GearGiver* podium models are NOT junk - they are the in-world stands that hand out
-- gear (Bat, traps...). scripts/steps/gear.luau re-lays them out next to the hub spawn and retargets
-- them, and src/ServerScriptService/GearService.server.luau drives them. Deleting them here is what
-- made the bat and the traps unobtainable.
local wsJunk = {
    "Amonetization", "Giftbox", "_MultiPhotoboothExports",
    "_Guards", "Dragons", "__DEBRIS", "ObjectCache", "__CarryTestFolder",
    "HumanoidRootPart", "Aclaude", "TestEggTool", "Catalog_Imports", "Idle",
    "HarmlessAssetManagerConnector", "PlacedEggRenders", "Map"
}
for _, name in ipairs(wsJunk) do
    local item = ws:FindFirstChild(name)
    while item do
        item:Destroy()
        item = ws:FindFirstChild(name)
    end
end

-- Clean up __OBJECTS: keep gameplay areas, 45 nests, delivery hitbox, but remove decorative map 'Build'
local objs = ws:FindFirstChild("__OBJECTS")
if objs then
    local build = objs:FindFirstChild("Build")
    if build then
        build:Destroy()
        print("[StealaHero Build] Removed decorative map 'Build' models from __OBJECTS.")
    end
    -- Purge private sounds in __OBJECTS (e.g. guard sounds that cause 403 authorization errors)
    local objsSoundCount = 0
    for _, inst in ipairs(objs:GetDescendants()) do
        if inst:IsA("Sound") then
            inst:Destroy()
            objsSoundCount += 1
        end
    end
    print(string.format("[StealaHero Build] Purged %d private sounds from __OBJECTS.", objsSoundCount))
end

-- 2. Sanitize all Sound instances across the place to prevent 403 authorization errors
local totalSanitizedSounds = 0
for _, inst in ipairs(place:GetDescendants()) do
    if inst:IsA("Sound") then
        pcall(function()
            (inst :: any).AudioContent = roblox.Content.none
            totalSanitizedSounds += 1
        end)
    end
end
print(string.format("[StealaHero Build] Sanitized %d Sound instances across place to Content.none (0 403 errors).", totalSanitizedSounds))

-- 3. Clean up ReplicatedStorage bloat (DO NOT DESTROY AssetModels - required by Assets.luau & EggService)
print("[StealaHero Build] Cleaning up ReplicatedStorage bloat...")
for _, name in ipairs({
    "BanMesh", "Slap", "Rainbow", "TornadoZone",
    "StrikeLightningHere", "LightningZone", "CustomSpeedEvent"
}) do
    local item = rs:FindFirstChild(name)
    if item then item:Destroy() end
end

local rsAssets = rs:FindFirstChild("Assets")
if rsAssets then
    for _, name in ipairs({"Sounds", "ToolSounds", "SFX"}) do
        local sf = rsAssets:FindFirstChild(name)
        if sf then sf:Destroy() end
    end
end

-- Purge broken SurfaceAppearances from AssetModels to prevent TexturePack download failures
local am = rs:FindFirstChild("AssetModels")
if am then
    local saCount = 0
    for _, inst in ipairs(am:GetDescendants()) do
        if inst:IsA("SurfaceAppearance") then
            inst:Destroy()
            saCount += 1
        end
    end
    print(string.format("[StealaHero Build] Purged %d broken SurfaceAppearance instances from AssetModels.", saCount))
end

-- Remove ripped sound test pipelines
local rsDir = rs:FindFirstChild("Directory")
if rsDir then
    local dirSounds = rsDir:FindFirstChild("Sounds")
    if dirSounds then dirSounds:Destroy() end
end

local rsLib = rs:FindFirstChild("Library")
if rsLib then
    -- Safe stub for PreloadAssets so it never logs failure retries
    local fnFolder = rsLib:FindFirstChild("Functions")
    if fnFolder then
        local pa = fnFolder:FindFirstChild("PreloadAssets")
        if pa then
            pa.Source = [[
return function(assets, onStatus)
    return true
end
]]
        end
    end

    -- Inject bulletproof safe Audio module
    local audioMod = rsLib:FindFirstChild("Audio")
    if audioMod and fs.isFile("src/ReplicatedStorage/Library/Audio/init.luau") then
        audioMod.Source = fs.readFile("src/ReplicatedStorage/Library/Audio/init.luau")
        print("[StealaHero Build] Injected safe bulletproof Audio module into ReplicatedStorage.Library.Audio.")
    end

    -- Inject non-blocking HideImportantUI
    local hideUI = rsLib:FindFirstChild("Client") and rsLib.Client:FindFirstChild("HideImportantUI")
    if hideUI and fs.isFile("src/ReplicatedStorage/Library/Client/HideImportantUI.luau") then
        hideUI.Source = fs.readFile("src/ReplicatedStorage/Library/Client/HideImportantUI.luau")
        print("[StealaHero Build] Injected non-blocking HideImportantUI into Library.Client.")
    end

    -- Inject patched NotificationCmds.Message (no 403 sound)
    local notifCmds = rsLib:FindFirstChild("Client") and rsLib.Client:FindFirstChild("NotificationCmds")
    local msgMod = notifCmds and notifCmds:FindFirstChild("Message")
    if msgMod and fs.isFile("src/ReplicatedStorage/Library/Client/NotificationCmds/Message/init.luau") then
        msgMod.Source = fs.readFile("src/ReplicatedStorage/Library/Client/NotificationCmds/Message/init.luau")
        print("[StealaHero Build] Injected patched NotificationCmds.Message into Library.Client.")
    end

    -- Inject patched BUTTON_FX (no 403 sound)
    local constFolder = rsLib:FindFirstChild("Globals") and rsLib.Globals:FindFirstChild("Constants")
    local constIdx = constFolder and constFolder:FindFirstChild("_Index")
    local bfx = constIdx and constIdx:FindFirstChild("BUTTON_FX")
    if bfx and fs.isFile("src/ReplicatedStorage/Library/Globals/Constants/_Index/BUTTON_FX.luau") then
        bfx.Source = fs.readFile("src/ReplicatedStorage/Library/Globals/Constants/_Index/BUTTON_FX.luau")
        print("[StealaHero Build] Injected patched BUTTON_FX into Constants._Index.")
    end

    -- Inject patched TutorialMessageAnimator (safe without Directory.Sounds)
    local clientFolder = rsLib:FindFirstChild("Client")
    local uiFolder = clientFolder and clientFolder:FindFirstChild("UI")
    local tma = uiFolder and uiFolder:FindFirstChild("TutorialMessageAnimator")
    if tma and fs.isFile("src/ReplicatedStorage/Library/Client/UI/TutorialMessageAnimator.luau") then
        tma.Source = fs.readFile("src/ReplicatedStorage/Library/Client/UI/TutorialMessageAnimator.luau")
        print("[StealaHero Build] Injected patched TutorialMessageAnimator into Library.Client.UI.")
    end

    -- Inject patched EggRenderer (fallback model if species egg model missing)
    local eggsFolder = clientFolder and clientFolder:FindFirstChild("Eggs")
    local er = eggsFolder and eggsFolder:FindFirstChild("EggRenderer")
    if er and fs.isFile("src/ReplicatedStorage/Library/Client/Eggs/EggRenderer.luau") then
        er.Source = fs.readFile("src/ReplicatedStorage/Library/Client/Eggs/EggRenderer.luau")
        print("[StealaHero Build] Injected patched EggRenderer into Library.Client.Eggs.")
    end
end

-- Clean up CmdrClient to prevent infinite yield on StarterGui:WaitForChild("Cmdr")
local cmdrClient = rs:FindFirstChild("CmdrClient")
if cmdrClient then
    cmdrClient:Destroy()
    print("[StealaHero Build] Removed CmdrClient from ReplicatedStorage.")
end

-- Clean up UserGenerated.Analytics telemetry senders to prevent discarded remote event warnings
local ug = rs:FindFirstChild("UserGenerated")
local analytics = ug and ug:FindFirstChild("Analytics")
if analytics then
    local cr = analytics:FindFirstChild("ClientRunner")
    if cr then cr:Destroy() end
    local ck = analytics:FindFirstChild("ClientKit")
    if ck then
        for _, sName in ipairs({"PingSender", "MenuStateSender", "FocusStateSender", "PerformanceSender"}) do
            local s = ck:FindFirstChild(sName)
            if s then s:Destroy() end
        end
    end
    print("[StealaHero Build] Cleaned up UserGenerated.Analytics telemetry senders.")
end

-- Remove private sounds from GearTools
local gearTools = rs:FindFirstChild("GearTools")
if gearTools then
    for _, inst in ipairs(gearTools:GetDescendants()) do
        if inst:IsA("Sound") then
            inst:Destroy()
        end
    end
end

-- 4. Clean up ServerScriptService junk/exploit scripts
print("[StealaHero Build] Cleaning up ServerScriptService junk...")
for _, name in ipairs({
    "__MCP_CommandListener", "TrollActionServer", "TrollFreeAdmin",
    "AnalyticsIngestService", "AdminStatusHandler", "CmdrAdminHandler",
    "CustomSpeedServer"
}) do
    local item = sss:FindFirstChild(name)
    while item do
        item:Destroy()
        item = sss:FindFirstChild(name)
    end
end

-- 5. Clean up StarterGui junk ScreenGuis and non-functional buttons
print("[StealaHero Build] Cleaning up StarterGui junk ScreenGuis and buttons...")
for _, name in ipairs({
    "Frames", "Troll", "LikeGameBanner", "CustomSpeedSystem", "AdminToast", "Cmdr"
}) do
    local item = starterGui:FindFirstChild(name)
    if item then item:Destroy() end
end

-- Hide AdminPanel button in Hud instead of destroying (prevents any infinite yield)
local hud = starterGui:FindFirstChild("Hud")
if hud then
    local trollBtn = hud:FindFirstChild("Troll")
    if trollBtn then trollBtn:Destroy() end
    local rightHud = hud:FindFirstChild("RightHUD")
    local brainrot = rightHud and rightHud:FindFirstChild("RandomBrainrot")
    if brainrot then
        brainrot:Destroy()
        print("[StealaHero Build] Removed legacy RandomBrainrot button from Hud.RightHUD.")
    end
    local leftHud = hud:FindFirstChild("LeftHUD")
    local uilist = leftHud and leftHud:FindFirstChild("Uilistlayout")
    local adminBtn = uilist and uilist:FindFirstChild("AdminPanel")
    if adminBtn then
        adminBtn.Visible = false
        if adminBtn:IsA("GuiObject") then
            adminBtn.Active = false
        end
        for _, ch in ipairs(adminBtn:GetDescendants()) do
            if ch:IsA("LocalScript") or ch:IsA("Script") then
                ch:Destroy()
            end
        end
        print("[StealaHero Build] Purged all script children inside AdminPanel button (no Frames wait yield).")
    end
end

-- Remove LimitedEgg frame from Shop to avoid nonexistent Marketplace product errors
local shopGui = starterGui:FindFirstChild("Shop")
if shopGui then
    local limEgg = shopGui:FindFirstChild("LimitedEgg", true)
    if limEgg then limEgg:Destroy() end
end

-- 6. Clean up problematic/anti-tamper scripts in StarterPlayerScripts
if sps then
    local amShowcase = sps:FindFirstChild("AmonetizationShowcase")
    if amShowcase then
        amShowcase:Destroy()
        print("[StealaHero Build] Removed AmonetizationShowcase from StarterPlayerScripts.")
    end

    local spGame = sps:FindFirstChild("Game")
    if spGame then
        local rp = spGame:FindFirstChild("RuntimePulse")
        if rp then
            rp:Destroy()
            print("[StealaHero Build] Removed anti-tamper RuntimePulse from StarterPlayerScripts.Game.")
        end
    end

    local guiFolder = sps:FindFirstChild("GUI")
    if guiFolder then
        local fr = guiFolder:FindFirstChild("FriendRequest")
        if fr then
            fr:Destroy()
            print("[StealaHero Build] Removed obsolete FriendRequest from StarterPlayerScripts.GUI.")
        end
        local adminCmdr = guiFolder:FindFirstChild("AdminCmdrClient")
        if adminCmdr then
            adminCmdr:Destroy()
            print("[StealaHero Build] Removed AdminCmdrClient from StarterPlayerScripts.GUI (no CmdrClient yield).")
        end
        local check = guiFolder:FindFirstChild("CheckResetOnSpawn")
        if check then check:Destroy() end
        local slow = guiFolder:FindFirstChild("SlowToggle")
        if slow then slow:Destroy() end
        local shop = guiFolder:FindFirstChild("Shop")
        if shop then
            local sl = shop:FindFirstChild("ServerLuck")
            if sl then sl:Destroy() end
            local le = shop:FindFirstChild("LimitedEgg")
            if le then le:Destroy() end
        end

        local shopsFolder = guiFolder:FindFirstChild("Shops")
        local trailShop = shopsFolder and shopsFolder:FindFirstChild("TrailShop")
        if trailShop and fs.isFile("src/StarterPlayer/StarterPlayerScripts/GUI/Shops/TrailShop.client.luau") then
            trailShop.Source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/GUI/Shops/TrailShop.client.luau")
            print("[StealaHero Build] Injected patched TrailShop (nil-safe TrailInventory).")
        end

        local tradingFolder = guiFolder:FindFirstChild("Trading")
        local tradingNotifs = tradingFolder and tradingFolder:FindFirstChild("Notifications")
        if tradingNotifs and fs.isFile("src/StarterPlayer/StarterPlayerScripts/GUI/Trading/Notifications.luau") then
            tradingNotifs.Source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/GUI/Trading/Notifications.luau")
            print("[StealaHero Build] Injected patched Trading.Notifications.")
        end

        local indexScript = guiFolder:FindFirstChild("Index")
        if indexScript and fs.isFile("src/StarterPlayer/StarterPlayerScripts/GUI/Index/init.client.luau") then
            indexScript.Source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/GUI/Index/init.client.luau")
            print("[StealaHero Build] Injected patched Index LocalScript (guarded GearInventory).")
        end
    end

    -- Inject patched Treadmill controllers (graceful render check & resilient camera presentation)
    local plotsClientFolder = sps:FindFirstChild("Game") and sps.Game:FindFirstChild("Plots")
    if plotsClientFolder then
        local tsc = plotsClientFolder:FindFirstChild("TreadmillStaticController")
        if tsc and fs.isFile("src/StarterPlayer/StarterPlayerScripts/Game/Plots/TreadmillStaticController/init.client.luau") then
            tsc.Source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Game/Plots/TreadmillStaticController/init.client.luau")
            print("[StealaHero Build] Injected patched TreadmillStaticController (graceful render check).")
        end
        local tcpc = plotsClientFolder:FindFirstChild("TreadmillCharacterPresentationController")
        if tcpc and fs.isFile("src/StarterPlayer/StarterPlayerScripts/Game/Plots/TreadmillCharacterPresentationController.luau") then
            tcpc.Source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Game/Plots/TreadmillCharacterPresentationController.luau")
            print("[StealaHero Build] Injected patched TreadmillCharacterPresentationController (resilient camera).")
        end
    end

    print("[StealaHero Build] Cleaned up anti-tamper and broken scripts in StarterPlayerScripts.")
end

-- Ensure Workspace.__DEBRIS exists for audio and projectile effects
if not ws:FindFirstChild("__DEBRIS") then
    local deb = Instance.new("Folder")
    deb.Name = "__DEBRIS"
    deb.Parent = ws
    print("[StealaHero Build] Created Workspace.__DEBRIS folder.")
end

-- 7. Create a massive, solid Baseplate covering all plots, lobby, and all 9 zones
print("[StealaHero Build] Creating solid Baseplate floor...")
local baseplate = ws:FindFirstChild("Baseplate")
if not baseplate then
    baseplate = Instance.new("Part")
    baseplate.Name = "Baseplate"
    baseplate.TopSurface = Enum.SurfaceType.Smooth
    baseplate.BottomSurface = Enum.SurfaceType.Smooth
    baseplate.Parent = ws
end
baseplate.Size = Vector3.new(10000, 20, 3000)
baseplate.CFrame = CFrame.new(3400, -7.95, 0)
baseplate.Anchored = true
baseplate.CanCollide = true
baseplate.Material = Enum.Material.Plastic
baseplate.Color = Color3.fromRGB(163, 162, 165)

local gridTexture = baseplate:FindFirstChild("GridTexture")
if not gridTexture then
    gridTexture = Instance.new("Texture")
    gridTexture.Name = "GridTexture"
    gridTexture.Texture = "rbxassetid://6372755229"
    gridTexture.StudsPerTileU = 16
    gridTexture.StudsPerTileV = 16
    gridTexture.Transparency = 0.6
    gridTexture.Face = Enum.NormalId.Top
    gridTexture.Parent = baseplate
end

-- Central Spawn
local spawn = ws:FindFirstChild("SpawnLocation")
if not spawn then
    spawn = Instance.new("SpawnLocation")
    spawn.Name = "SpawnLocation"
    spawn.Size = Vector3.new(12, 0.4, 12)
    spawn.CFrame = CFrame.new(0, 2.25, 0)
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Neutral = true
    spawn.Parent = ws
else
    spawn.Size = Vector3.new(12, 0.4, 12)
    spawn.CFrame = CFrame.new(0, 2.25, 0)
    spawn.Anchored = true
end


-- 8. Configure exactly 6 Plots and center them onto Baseplate at Y = 0
local plots = ws:FindFirstChild("Plots")
assert(plots, "Workspace.Plots not found in master place!")

-- Remove extra plot 7
local plot7 = plots:FindFirstChild("7")
if plot7 then
    plot7:Destroy()
    print("[StealaHero Build] Removed extra Plot 7 (Using 6 plots).")
end

-- Translate all plots, objects, and stands so floor sits at Y = 0 and center sits at (0, 0, 0)
local shiftOffset = Vector3.new(-480.0, -65.5, 363.3)
local function translatePart(inst)
    if inst:IsA("BasePart") then
        inst.CFrame = CFrame.new(shiftOffset) * inst.CFrame
    elseif inst:IsA("Model") then
        -- Shift the stored pivot too, otherwise Studio shows every shifted model's pivot ~600 studs away.
        -- (Lune serializes WorldPivotData; WorldPivot writes are not persisted.)
        local ok, wp = pcall(function()
            return (inst :: any).WorldPivotData
        end)
        if ok and typeof(wp) == "CFrame" then
            (inst :: any).WorldPivotData = CFrame.new(shiftOffset) * wp
        end
    end
    for _, ch in ipairs(inst:GetChildren()) do
        translatePart(ch)
    end
end
translatePart(plots)
print(string.format("[StealaHero Build] Shifted %d plots to center on Baseplate at Y=0.", #plots:GetChildren()))

if objs then
    translatePart(objs)
    print("[StealaHero Build] Shifted __OBJECTS (Areas, GuardAreas, DeliveryHitbox) to align with Plots on Baseplate.")

    -- Guard rigs, colliders and anchoring are owned by hero_system_builder.luau (section F), which
    -- rebuilds each zone guard as a jointed R15 villain. Only anchor here so nothing falls during load.
    local ga = objs:FindFirstChild("Areas") and objs.Areas:FindFirstChild("GuardAreas")
    if ga then
        for _, z in ipairs(ga:GetChildren()) do
            local g = z:FindFirstChild("Guard")
            if g then
                for _, part in ipairs(g:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Anchored = true
                    end
                end
            end
        end
        print("[StealaHero Build] Anchored all 9 guard models in place file.")
    end
end

local stands = ws:FindFirstChild("Stands")
if stands then
    translatePart(stands)
    print("[StealaHero Build] Shifted Stands (sell stands and upgrade pads) to align with Plots on Baseplate.")
end

-- 9. Plot polish: Speedsters PlayerPlotSign layout, hub spawn, plot attributes (scripts/steps/plots.luau),
-- then the Speedsters 3D treadmill on every plot (scripts/steps/treadmill.luau).
-- Both must run AFTER translatePart(plots) so they see final world positions.
local STEP_CTX = {
    roblox = roblox,
    fs = fs,
    baseplate = baseplate,
    groundY = baseplate.CFrame.Position.Y + baseplate.Size.Y / 2,
    shiftOffset = shiftOffset,
    -- the untouched base place, for steps that need content this build deleted (e.g. original map ground)
    basePlacePath = "Steal An Egg with treadmill V2.rbxl",
}

if fs.isFile("scripts/steps/plots.luau") then
    runStep("plots", function()
        require("./steps/plots").Apply(place, spPlace, STEP_CTX)
    end)
else
    local INK_COLOR = Color3.fromRGB(11, 27, 45)
    local PANEL_COLOR = Color3.fromRGB(24, 38, 68)
for _, plot in ipairs(plots:GetChildren()) do
    local sign = plot:FindFirstChild("PlotSign")
    local pps = sign and sign:FindFirstChild("PlayerPlotSign")
    if pps then
        pps.Size = roblox.UDim2.new(0, 160, 0, 50)
        local frame = pps:FindFirstChild("Frame")
        if frame then
            frame.BackgroundColor3 = PANEL_COLOR
            frame.BorderSizePixel = 0
            
            local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
            corner.CornerRadius = roblox.UDim.new(0, 10)
            corner.Parent = frame
            
            local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
            stroke.Color = INK_COLOR
            stroke.Thickness = 2.5
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Parent = frame
            
            local nameLabel = frame:FindFirstChild("PlayerName")
            if nameLabel and nameLabel:IsA("TextLabel") then
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextStrokeColor3 = INK_COLOR
                nameLabel.TextStrokeTransparency = 0.3
            end
        end
    end
end
print("[StealaHero Build] Enhanced PlayerPlotSigns with Speedters UI styling.")
end

if fs.isFile("scripts/steps/treadmill.luau") then
    runStep("treadmill", function()
        require("./steps/treadmill").Apply(place, spPlace, STEP_CTX)
    end)
end

-- 9b. World ground (scripts/steps/ground.luau): the grass look of the original maps over the solid baseplate.
if fs.isFile("scripts/steps/ground.luau") then
    runStep("ground", function()
        require("./steps/ground").Apply(place, spPlace, STEP_CTX)
    end)
end
if fs.isFile("scripts/steps/nogroup.luau") then runStep("nogroup", function() require("./steps/nogroup").Apply(place, spPlace, STEP_CTX) end) end

-- 9c. Brainrot VFX port (scripts/steps/vfx.luau): ReplicatedStorage.Assets.VFX.SAB, cloned from the
-- read-only "V40 SAB by FaypleStudios" reference place and driven by the SabVfxController client script.
if fs.isFile("scripts/steps/vfx.luau") then
    runStep("vfx", function()
        require("./steps/vfx").Apply(place, spPlace, STEP_CTX)
    end)
end

-- 9c. Gear givers (scripts/steps/gear.luau): the GearGiver podiums that hand out the Bat and the traps.
if fs.isFile("scripts/steps/gear.luau") then
    runStep("gear", function()
        require("./steps/gear").Apply(place, spPlace, STEP_CTX)
    end)
end

-- 9d. Game-plan stages (docs: Steal_A_Hero_Game_Plan.docx): themed stage environments first
-- (scripts/steps/env_*.luau, name order; each places the stage's hidden EggSpot markers), then
-- scripts/steps/stages.luau turns the 9 legacy zones into the plan's 6 stages (gates, nests on the
-- EggSpot markers, retired zones, hub layout).
if fs.isDir("scripts/steps") then
    local envSteps = {}
    for _, fileName in ipairs(fs.readDir("scripts/steps")) do
        if string.sub(fileName, 1, 4) == "env_" and string.sub(fileName, -5) == ".luau" then
            table.insert(envSteps, string.sub(fileName, 1, -6))
        end
    end
    table.sort(envSteps)
    for _, stepName in ipairs(envSteps) do
        runStep(stepName, function()
            require("./steps/" .. stepName).Apply(place, spPlace, STEP_CTX)
        end)
    end
end
if fs.isFile("scripts/steps/stages.luau") then
    runStep("stages", function()
        require("./steps/stages").Apply(place, spPlace, STEP_CTX)
    end)
end

-- 10. Inject HeroCatalog into ReplicatedStorage.Directory
local dir = rs:FindFirstChild("Directory")
if not dir then
    dir = Instance.new("Folder")
    dir.Name = "Directory"
    dir.Parent = rs
end

local heroCatalogContent = fs.readFile("src/ReplicatedStorage/Directory/HeroCatalog.luau")
local heroCatalogModule = dir:FindFirstChild("HeroCatalog")
if not heroCatalogModule then
    heroCatalogModule = Instance.new("ModuleScript")
    heroCatalogModule.Name = "HeroCatalog"
    heroCatalogModule.Parent = dir
end
heroCatalogModule.Source = heroCatalogContent
print("[StealaHero Build] Injected HeroCatalog into ReplicatedStorage.Directory.")

-- 11. Inject Speedters UI Style (GamePanelStyle, StudUi, ModalJuice)
local lib = rs:FindFirstChild("Library")
if lib then
    local shared = lib:FindFirstChild("Shared")
    if not shared then
        shared = Instance.new("Folder")
        shared.Name = "Shared"
        shared.Parent = lib
    end
    
    local gamePanelStylePath = UPDATE2_DIR .. "/src/common/ReplicatedStorage/Shared/GamePanelStyle.luau"
    if fs.isFile(gamePanelStylePath) then
        local m = shared:FindFirstChild("GamePanelStyle") or Instance.new("ModuleScript")
        m.Name = "GamePanelStyle"
        m.Source = fs.readFile(gamePanelStylePath)
        m.Parent = shared
    end
    
    local studUiPath = UPDATE2_DIR .. "/src/common/ReplicatedStorage/Shared/StudUi.luau"
    if fs.isFile(studUiPath) then
        local m = shared:FindFirstChild("StudUi") or Instance.new("ModuleScript")
        m.Name = "StudUi"
        m.Source = fs.readFile(studUiPath)
        m.Parent = shared
    end
    
    local modalJuicePath = UPDATE2_DIR .. "/src/common/ReplicatedStorage/Shared/ModalJuice.luau"
    if fs.isFile(modalJuicePath) then
        local m = shared:FindFirstChild("ModalJuice") or Instance.new("ModuleScript")
        m.Name = "ModalJuice"
        m.Source = fs.readFile(modalJuicePath)
        m.Parent = shared
    end
    print("[StealaHero Build] Injected Speedters GamePanelStyle, StudUi, and ModalJuice into ReplicatedStorage.Library.Shared.")
end

-- 12. Apply the Hero Ecosystem from the owner's models (assets/hero_models/*.rbxm): 38 hero AssetModels + template rigs, egg models, configs, DropTables and the 6 villain guards
runStep("heroes", function()
    local heroSystem = require("./hero_system_builder")
    heroSystem.Apply(place, spPlace)
    print("[StealaHero Build] Integrated the Hero System: 38 game-plan heroes (+ legacy DontRoll heroes), eggs, configs, 6 stage DropTables and the 6 stage villains.")
end)

-- 12b. Post-hero steps (scripts/steps/post_*.luau, name order): run after the hero builder and the
-- stages step, before controller/manifest injection (e.g. purging legacy animal content, hub remodel).
if fs.isDir("scripts/steps") then
    local postSteps = {}
    for _, fileName in ipairs(fs.readDir("scripts/steps")) do
        if string.sub(fileName, 1, 5) == "post_" and string.sub(fileName, -5) == ".luau" then
            table.insert(postSteps, string.sub(fileName, 1, -6))
        end
    end
    table.sort(postSteps)
    for _, stepName in ipairs(postSteps) do
        runStep(stepName, function()
            require("./steps/" .. stepName).Apply(place, spPlace, STEP_CTX)
        end)
    end
end


-- 13. Ensure ServerScriptService has NetworkInit and offline-safe Database and controllers
local netInit = sss:FindFirstChild("NetworkInit") or Instance.new("Script")
netInit.Name = "NetworkInit"
netInit.Source = fs.readFile("src/ServerScriptService/NetworkInit.server.luau")
netInit.Parent = sss

local sssLib = sss:FindFirstChild("Library")
if sssLib then
    local dbModule = sssLib:FindFirstChild("Database")
    if dbModule then
        dbModule.Source = fs.readFile("src/ServerScriptService/Library/Database.luau")
        print("[StealaHero Build] Injected Database.luau with offline in-memory mock store and starter cash.")
    end
end

local gsModule = sss:FindFirstChild("GlobalStatsService")
if gsModule then
    gsModule.Source = fs.readFile("src/ServerScriptService/GlobalStatsService.luau")
    print("[StealaHero Build] Injected GlobalStatsService.luau with offline mock store.")
end

local controllers = sss:FindFirstChild("Controllers")
if controllers then
    local ps = controllers:FindFirstChild("PlotService")
    if ps and fs.isFile("src/ServerScriptService/Controllers/PlotService.luau") then
        ps.Source = fs.readFile("src/ServerScriptService/Controllers/PlotService.luau")
    end
    local es = controllers:FindFirstChild("EggService")
    if es and fs.isFile("src/ServerScriptService/Controllers/EggService.luau") then
        es.Source = fs.readFile("src/ServerScriptService/Controllers/EggService.luau")
    end
    local aes = controllers:FindFirstChild("AreaEggService")
    if aes and fs.isFile("src/ServerScriptService/Controllers/AreaEggService.luau") then
        aes.Source = fs.readFile("src/ServerScriptService/Controllers/AreaEggService.luau")
    end
    local tgs = controllers:FindFirstChild("TreadmillGrindService")
    if tgs and fs.isFile("src/ServerScriptService/Controllers/TreadmillGrindService.luau") then
        tgs.Source = fs.readFile("src/ServerScriptService/Controllers/TreadmillGrindService.luau")
        print("[StealaHero Build] Injected patched TreadmillGrindService with coin awards.")
    end
    local aps = controllers:FindFirstChild("AmonetizationPurchaseService")
    if aps and fs.isFile("src/ServerScriptService/Controllers/AmonetizationPurchaseService.luau") then
        aps.Source = fs.readFile("src/ServerScriptService/Controllers/AmonetizationPurchaseService.luau")
        print("[StealaHero Build] Injected non-blocking AmonetizationPurchaseService.")
    end
    local assetsServ = controllers:FindFirstChild("AssetService")
    if assetsServ and fs.isFile("src/ServerScriptService/Controllers/AssetService.luau") then
        assetsServ.Source = fs.readFile("src/ServerScriptService/Controllers/AssetService.luau")
        print("[StealaHero Build] Injected AssetService.")
    end
    local offAssetsServ = controllers:FindFirstChild("OfflineAssetsService")
    if offAssetsServ and fs.isFile("src/ServerScriptService/Controllers/OfflineAssetsService.luau") then
        offAssetsServ.Source = fs.readFile("src/ServerScriptService/Controllers/OfflineAssetsService.luau")
        print("[StealaHero Build] Injected OfflineAssetsService.")
    end
    local bases = dir:FindFirstChild("Bases")
    if bases and fs.isFile("src/ReplicatedStorage/Directory/Bases.luau") then
        bases.Source = fs.readFile("src/ReplicatedStorage/Directory/Bases.luau")
    end
end

-- Inject Bootstrap with PhysicsService collision groups
local bootstrapScript = sss:FindFirstChild("Bootstrap")
if bootstrapScript and fs.isFile("src/ServerScriptService/Bootstrap.server.luau") then
    bootstrapScript.Source = fs.readFile("src/ServerScriptService/Bootstrap.server.luau")
    print("[StealaHero Build] Injected Bootstrap.server.luau with PhysicsService collision groups.")
end

-- Inject patched GuardMovementRecovery and GuardComponent in ReplicatedStorage
local rsLib = rs:FindFirstChild("Library")
local rsModules = rsLib and rsLib:FindFirstChild("Modules")
local rsGuardAreas = rsModules and rsModules:FindFirstChild("GuardAreas")
if rsGuardAreas then
    local gmr = rsGuardAreas:FindFirstChild("GuardMovementRecovery")
    if gmr and fs.isFile("src/ReplicatedStorage/Library/Modules/GuardAreas/GuardMovementRecovery.luau") then
        gmr.Source = fs.readFile("src/ReplicatedStorage/Library/Modules/GuardAreas/GuardMovementRecovery.luau")
        print("[StealaHero Build] Injected GuardMovementRecovery.luau (throttled & void-safe).")
    end
    local gc = rsGuardAreas:FindFirstChild("GuardComponent")
    if gc and fs.isFile("src/ReplicatedStorage/Library/Modules/GuardAreas/GuardComponent.luau") then
        gc.Source = fs.readFile("src/ReplicatedStorage/Library/Modules/GuardAreas/GuardComponent.luau")
        print("[StealaHero Build] Injected GuardComponent.luau (anchored during sleep).")
    end
end

-- Inject patched GenericGuardRuntime and ForestGuardRuntime in StarterPlayerScripts
local spGame = sps and sps:FindFirstChild("Game")
local spGuardAreas = spGame and spGame:FindFirstChild("GuardAreas")
if spGuardAreas then
    local ggr = spGuardAreas:FindFirstChild("GenericGuardRuntime")
    if ggr and fs.isFile("src/StarterPlayer/StarterPlayerScripts/Game/GuardAreas/GenericGuardRuntime.luau") then
        ggr.Source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Game/GuardAreas/GenericGuardRuntime.luau")
        print("[StealaHero Build] Injected GenericGuardRuntime.luau (zone Bounds as ground).")
    end
    local fgr = spGuardAreas:FindFirstChild("ForestGuardRuntime")
    if fgr and fs.isFile("src/StarterPlayer/StarterPlayerScripts/Game/GuardAreas/ForestGuardRuntime.luau") then
        fgr.Source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Game/GuardAreas/ForestGuardRuntime.luau")
        print("[StealaHero Build] Injected ForestGuardRuntime.luau (zone Bounds as ground).")
    end
end
print("[StealaHero Build] Updated ServerScriptService controllers, NetworkInit, Database, and Guard modules.")

-- 13b. Injection manifests: scripts/inject/*.luau each return a list of
--   { target = "ServerScriptService/Controllers/GuardChaseService", class = "ModuleScript",
--     source = "src/ServerScriptService/Controllers/GuardChaseService.luau", create = true }
-- target is a "/"-separated path whose first segment is a service name. With create = false the
-- instance must already exist in the base place (its Source is replaced); with create = true it is
-- created (parents must exist) when missing. One manifest file per subsystem owner.
local function resolveInjectionTarget(entry)
    local segments = string.split(entry.target, "/")
    local node = place:GetService(segments[1])
    for i = 2, #segments - 1 do
        node = node and node:FindFirstChild(segments[i])
    end
    if not node then
        return nil, "parent path missing"
    end
    local leafName = segments[#segments]
    local leaf = node:FindFirstChild(leafName)
    if leaf and entry.class and leaf.ClassName ~= entry.class then
        return nil, string.format("existing %s is a %s, expected %s", leafName, leaf.ClassName, entry.class)
    end
    if not leaf then
        if not entry.create then
            return nil, "target missing and create = false"
        end
        leaf = Instance.new(entry.class)
        leaf.Name = leafName
        leaf.Parent = node
    end
    return leaf
end

if fs.isDir("scripts/inject") then
    local manifestFiles = fs.readDir("scripts/inject")
    table.sort(manifestFiles)
    for _, fileName in ipairs(manifestFiles) do
        if string.sub(fileName, -5) == ".luau" then
            local manifestPath = "scripts/inject/" .. fileName
            runStep("inject:" .. fileName, function()
                local entries = luau.load(fs.readFile(manifestPath), { debugName = manifestPath })()
                for _, entry in ipairs(entries) do
                    assert(fs.isFile(entry.source), manifestPath .. ": source file not found: " .. tostring(entry.source))
                    local leaf, err = resolveInjectionTarget(entry)
                    assert(leaf, string.format("%s: cannot inject %s (%s)", manifestPath, entry.target, tostring(err)))
                    leaf.Source = fs.readFile(entry.source)
                    print(string.format("[StealaHero Build] Injected %s -> %s", entry.source, entry.target))
                end
            end)
        end
    end
end

-- 14. Apply complete Speedters UI polish to StarterGui
runStep("ui", function()
    local applySpeedtersUi = require("./apply_speedters_ui")
    applySpeedtersUi(place, spPlace)
    print("[StealaHero Build] Applied full Speedters UI style, icons, tabs & indicators to StarterGui.")
end)

-- 14b. Speedsters Escape UI port: every scripts/steps/ui_*.luau runs in name order after the base pass,
-- each Apply(place, spPlace, STEP_CTX) (one file per owner, e.g. shared materials, HUD, windows).
if fs.isDir("scripts/steps") then
    local uiSteps = {}
    for _, fileName in ipairs(fs.readDir("scripts/steps")) do
        if string.sub(fileName, 1, 3) == "ui_" and string.sub(fileName, -5) == ".luau" then
            table.insert(uiSteps, string.sub(fileName, 1, -6))
        end
    end
    table.sort(uiSteps)
    for _, stepName in ipairs(uiSteps) do
        runStep(stepName, function()
            local step = require("./steps/" .. stepName)
            if type(step) == "table" and type(step.Apply) == "function" then
                step.Apply(place, spPlace, STEP_CTX)
            end
        end)
    end
end

-- 15. Remove invalid service instances that are not top-level
local SERVICE_CLASSES = {
    Workspace = true, Lighting = true, ReplicatedStorage = true, ReplicatedFirst = true,
    ServerScriptService = true, ServerStorage = true, StarterGui = true, StarterPack = true,
    StarterPlayer = true, SoundService = true, Chat = true, TextChatService = true,
    Players = true, Debris = true, TweenService = true, HttpService = true,
    TeleportService = true, MarketplaceService = true, ContextActionService = true,
    UserInputService = true, RunService = true, PhysicsService = true,
    CollectionService = true, MaterialService = true, LocalizationService = true,
    TestService = true, VRService = true, VoiceChatService = true
}

local removedCount = 0
for _, inst in ipairs(place:GetDescendants()) do
    pcall(function()
        if not inst.Parent then return end
        if SERVICE_CLASSES[inst.ClassName] and inst.Parent ~= place then
            print(string.format("[Fix] Removing invalid service instance %s ('%s') inside %s", inst.ClassName, inst.Name, inst.Parent:GetFullName()))
            inst:Destroy()
            removedCount += 1
        elseif inst.Name:find("cloud_") or inst.Name:find("Zonito") then
            print(string.format("[Fix] Removing plugin artifact %s ('%s')", inst.ClassName, inst.Name))
            inst:Destroy()
            removedCount += 1
        end
    end)
end
print(string.format("[StealaHero Build] Sanitized place: removed %d invalid service instances/artifacts.", removedCount))

-- 16. Final Sound Sanitization pass across the entire place to ensure 0 403 errors
local finalSanitized = 0
for _, inst in ipairs(place:GetDescendants()) do
    pcall(function()
        if inst:IsA("Sound") then
            (inst :: any).AudioContent = roblox.Content.none
            finalSanitized += 1
        end
    end)
end
print(string.format("[StealaHero Build] Final sound sanitization: %d Sound instances verified with Content.none.", finalSanitized))

-- 16b. Speedsters audio mapping (scripts/steps/audio.luau). Runs AFTER the final sanitize pass so the
-- whitelisted Speedsters sounds it assigns are not wiped back to Content.none.
if fs.isFile("scripts/steps/audio.luau") then
    runStep("audio", function()
        require("./steps/audio").Apply(place, spPlace, STEP_CTX)
    end)
end

-- 17. Serialize final place
print(string.format("[StealaHero Build] Serializing place to %s...", OUT_PATH))
local outBytes = roblox.serializePlace(place)
fs.writeFile(OUT_PATH, outBytes)
if #failedSteps > 0 then
    print(string.format("[StealaHero Build] !! %d step(s) FAILED and were skipped: %s", #failedSteps, table.concat(failedSteps, ", ")))
end
print(string.format("[StealaHero Build] === COMPLETE! %s successfully generated (%d bytes) ===", OUT_PATH, #outBytes))
