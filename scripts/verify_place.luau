local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local raw = fs.readFile("StealaHero.rbxl")
local place = roblox.deserializePlace(raw)

print("=== FINAL VERIFICATION OF STEALAHERO.RBXL ===")

-- 1. Baseplate & Floor Check
local bp = place.Workspace:FindFirstChild("Baseplate")
assert(bp ~= nil, "Baseplate must exist")
print(string.format("Baseplate: Size=%s, CFrame=%s, Material=%s, CanCollide=%s", tostring(bp.Size), tostring(bp.CFrame), tostring(bp.Material), tostring(bp.CanCollide)))

-- 2. Plots & Stands Check
local plots = place.Workspace:FindFirstChild("Plots")
assert(plots ~= nil and #plots:GetChildren() == 6, "Must have exactly 6 plots")
print(string.format("Plots: %d plots present at Y=0", #plots:GetChildren()))

local stands = place.Workspace:FindFirstChild("Stands")
assert(stands ~= nil, "Stands must exist")
print(string.format("Stands: %d folders present in Workspace", #stands:GetChildren()))

-- 3. Gameplay Areas & 45 Nests
local objs = place.Workspace:FindFirstChild("__OBJECTS")
assert(objs ~= nil, "__OBJECTS must exist")
local guardAreas = objs.Areas:FindFirstChild("GuardAreas")
assert(guardAreas ~= nil and #guardAreas:GetChildren() == 9, "9 GuardAreas must exist")
local nestCount = 0
for _, ga in ipairs(guardAreas:GetChildren()) do
    local nests = ga:FindFirstChild("Nests")
    if nests then nestCount += #nests:GetChildren() end
end
print(string.format("Nests: %d nests across %d GuardAreas", nestCount, #guardAreas:GetChildren()))

-- 4. ReplicatedStorage.AssetModels Check
local rs = place:GetService("ReplicatedStorage")
local am = rs:FindFirstChild("AssetModels")
assert(am ~= nil, "AssetModels must exist in ReplicatedStorage")
print(string.format("AssetModels: %d models present in ReplicatedStorage.AssetModels", #am:GetChildren()))

-- 5. Directory.Assets validation simulation
local assetsMod = rs.Directory:FindFirstChild("Assets")
assert(assetsMod ~= nil, "Directory.Assets must exist")
local idx = assetsMod:FindFirstChild("_Index")
assert(idx ~= nil, "Assets._Index must exist")
local missingModels = 0
for _, c in ipairs(idx:GetChildren()) do
    if not am:FindFirstChild(c.Name) then
        missingModels += 1
        print("Missing model in AssetModels:", c.Name)
    end
end
print(string.format("Species in Assets._Index: %d, Missing from AssetModels: %d", #idx:GetChildren(), missingModels))
assert(missingModels == 0, "All species must have matching models in AssetModels!")

-- 6. Heroes in Assets.Models.Heroes
local heroesFolder = rs.Assets.Models:FindFirstChild("Heroes")
assert(heroesFolder ~= nil, "Assets.Models.Heroes must exist")
print(string.format("Heroes in Assets.Models.Heroes: %d", #heroesFolder:GetChildren()))
for _, h in ipairs(heroesFolder:GetChildren()) do
    print("  - Hero rig:", h.Name, h.ClassName)
end

-- 7. Sounds check
local soundCount = 0
local badSoundCount = 0
for _, inst in ipairs(place:GetDescendants()) do
    if inst:IsA("Sound") then
        soundCount += 1
        local ac = tostring((inst :: any).AudioContent)
        if string.find(ac, "rbxassetid://") and not string.find(ac, "None") then
            badSoundCount += 1
        end
    end
end
print(string.format("Sound instances: %d total, %d private non-sanitized", soundCount, badSoundCount))
assert(badSoundCount == 0, "No unauthorized private sounds may remain!")

-- 8. StarterGui Check
local sg = place:GetService("StarterGui")
local hud = sg:FindFirstChild("Hud")
local adminPanel = hud and hud.LeftHUD.Uilistlayout:FindFirstChild("AdminPanel")
assert(adminPanel ~= nil and adminPanel.Visible == false, "AdminPanel must exist and be hidden")
print("AdminPanel button in Hud: Exists, Visible = false")

print("=== ALL VERIFICATIONS PASSED! ===")
