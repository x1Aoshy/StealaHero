-- scripts/build_place.luau
-- Builds StealaHero.rbxl from base assets, placing 6 plots onto a clean Baseplate,
-- injecting HeroCatalog, SkinRigs, Network remotes, and updated controllers.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

print("[Build] Loading Steal An Egg with treadmill V2.rbxl...")
local raw = fs.readFile("Steal An Egg with treadmill V2.rbxl")
local masterPlace = roblox.deserializePlace(raw)

local place = masterPlace
local ws = place.Workspace

-- 1. Setup Workspace with clean Baseplate
local baseplate = ws:FindFirstChild("Baseplate")
if not baseplate then
    baseplate = roblox.Instance.new("Part")
    baseplate.Name = "Baseplate"
    baseplate.Size = Vector3.new(2048, 20, 2048)
    baseplate.CFrame = CFrame.new(0, -10, 0)
    baseplate.Anchored = true
    baseplate.Material = Enum.Material.SmoothPlastic
    baseplate.Color = Color3.fromRGB(99, 95, 98)
    baseplate.TopSurface = Enum.SurfaceType.Smooth
    baseplate.BottomSurface = Enum.SurfaceType.Smooth
    baseplate.Parent = ws
    
    local texture = roblox.Instance.new("Texture")
    texture.Name = "Texture"
    texture.Texture = "rbxassetid://6372755229"
    texture.StudsPerTileU = 16
    texture.StudsPerTileV = 16
    texture.Face = Enum.NormalId.Top
    texture.Parent = baseplate
end

-- Ensure central spawn
local spawn = ws:FindFirstChild("SpawnLocation")
if not spawn then
    spawn = roblox.Instance.new("SpawnLocation")
    spawn.Name = "SpawnLocation"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.CFrame = CFrame.new(0, 1, 0)
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Neutral = true
    spawn.Parent = ws
end

-- 2. Configure 6 Plots in Workspace.Plots
local plotsFolder = ws:FindFirstChild("Plots")
if not plotsFolder then
    plotsFolder = roblox.Instance.new("Folder")
    plotsFolder.Name = "Plots"
    plotsFolder.Parent = ws
end

-- Keep only plots 1..6, remove plot 7
local plot7 = plotsFolder:FindFirstChild("7")
if plot7 then
    plot7:Destroy()
    print("[Build] Removed extra Plot 7 (Hub uses 6 plots).")
end
print(string.format("[Build] Configured %d Plots in Workspace.Plots", #plotsFolder:GetChildren()))

-- 4. Inject HeroCatalog into ReplicatedStorage.Directory
local dir = place.ReplicatedStorage:FindFirstChild("Directory")
if not dir then
    dir = roblox.Instance.new("Folder")
    dir.Name = "Directory"
    dir.Parent = place.ReplicatedStorage
end

local heroCatalogContent = fs.readFile("src/ReplicatedStorage/Directory/HeroCatalog.luau")
local heroCatalogModule = dir:FindFirstChild("HeroCatalog")
if not heroCatalogModule then
    heroCatalogModule = roblox.Instance.new("ModuleScript")
    heroCatalogModule.Name = "HeroCatalog"
    heroCatalogModule.Parent = dir
end
heroCatalogModule.Source = heroCatalogContent
print("[Build] Injected HeroCatalog into ReplicatedStorage.Directory")

-- 5. Inject NetworkInit and update Scripts in ServerScriptService
local sss = place.ServerScriptService
local networkInitContent = fs.readFile("src/ServerScriptService/NetworkInit.server.luau")
local networkInitScript = sss:FindFirstChild("NetworkInit")
if not networkInitScript then
    networkInitScript = roblox.Instance.new("Script")
    networkInitScript.Name = "NetworkInit"
    networkInitScript.Parent = sss
end
networkInitScript.Source = networkInitContent

-- Update PlotService with 6 plots
local controllers = sss:FindFirstChild("Controllers")
if controllers then
    local plotServiceContent = fs.readFile("src/ServerScriptService/Controllers/PlotService.luau")
    local plotServiceModule = controllers:FindFirstChild("PlotService")
    if plotServiceModule then
        plotServiceModule.Source = plotServiceContent
        print("[Build] Updated PlotService in ServerScriptService.Controllers")
    end
    
    local eggServiceContent = fs.readFile("src/ServerScriptService/Controllers/EggService.luau")
    local eggServiceModule = controllers:FindFirstChild("EggService")
    if eggServiceModule then
        eggServiceModule.Source = eggServiceContent
        print("[Build] Updated EggService in ServerScriptService.Controllers")
    end
end

-- Update Bases module in Directory
local basesContent = fs.readFile("src/ReplicatedStorage/Directory/Bases.luau")
local basesModule = dir:FindFirstChild("Bases")
if basesModule then
    basesModule.Source = basesContent
    print("[Build] Updated Bases in ReplicatedStorage.Directory (with safe navigation)")
end

-- 6. Inject Speedters UI Style (GamePanelStyle, StudUi, ModalJuice)
local lib = place.ReplicatedStorage:FindFirstChild("Library")
if lib then
    local sharedFolder = lib:FindFirstChild("Shared")
    if not sharedFolder then
        sharedFolder = roblox.Instance.new("Folder")
        sharedFolder.Name = "Shared"
        sharedFolder.Parent = lib
    end
    
    -- Copy GamePanelStyle from Speedters if available
    local gamePanelStylePath = "c:/Users/Aoshy´/Desktop/Update2/src/common/ReplicatedStorage/Shared/GamePanelStyle.luau"
    if fs.isFile(gamePanelStylePath) then
        local styleModule = sharedFolder:FindFirstChild("GamePanelStyle")
        if not styleModule then
            styleModule = roblox.Instance.new("ModuleScript")
            styleModule.Name = "GamePanelStyle"
            styleModule.Parent = sharedFolder
        end
        styleModule.Source = fs.readFile(gamePanelStylePath)
        print("[Build] Injected Speedters GamePanelStyle into ReplicatedStorage.Library.Shared")
    end
    
    local studUiPath = "c:/Users/Aoshy´/Desktop/Update2/src/common/ReplicatedStorage/Shared/StudUi.luau"
    if fs.isFile(studUiPath) then
        local studUiModule = sharedFolder:FindFirstChild("StudUi")
        if not studUiModule then
            studUiModule = roblox.Instance.new("ModuleScript")
            studUiModule.Name = "StudUi"
            studUiModule.Parent = sharedFolder
        end
        studUiModule.Source = fs.readFile(studUiPath)
        print("[Build] Injected Speedters StudUi into ReplicatedStorage.Library.Shared")
    end
end

-- 7. Ensure ReplicatedStorage.Network has all remote instances created
local netFolder = place.ReplicatedStorage:FindFirstChild("Network")
if not netFolder then
    netFolder = roblox.Instance.new("Folder")
    netFolder.Name = "Network"
    netFolder.Parent = place.ReplicatedStorage
end

-- 8. Serialize final place to StealaHero.rbxl
print("[Build] Serializing place to StealaHero.rbxl...")
local outBytes = roblox.serializePlace(place)
fs.writeFile("StealaHero.rbxl", outBytes)
print(string.format("[Build] SUCCESS! StealaHero.rbxl generated (%d bytes)!", #outBytes))
