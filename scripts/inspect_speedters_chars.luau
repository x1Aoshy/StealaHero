local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local spPlacePath = "c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl"
local p = roblox.deserializePlace(fs.readFile(spPlacePath))

local folder = p.Workspace:FindFirstChild("Folder")
if folder then
    print("Workspace.Folder children:")
    for _, c in ipairs(folder:GetChildren()) do
        print("  Child:", c.Name, c.ClassName)
    end
end

local cbk = p.Workspace:FindFirstChild("ColdBloodedKiller")
if cbk then
    print("ColdBloodedKiller Class:", cbk.ClassName)
end

-- Check ServerStorage.RawCosmeticPack
local cp = p:GetService("ServerStorage"):FindFirstChild("RawCosmeticPack")
if cp then
    print("RawCosmeticPack children:")
    for _, c in ipairs(cp:GetChildren()) do
        print("  Cosmetic:", c.Name, c.ClassName)
        for _, sub in ipairs(c:GetChildren()) do
            if sub:IsA("Shirt") or sub:IsA("Pants") or sub:IsA("Accessory") or sub:IsA("CharacterMesh") then
                print("    Asset:", sub.Name, sub.ClassName)
            end
        end
    end
end
