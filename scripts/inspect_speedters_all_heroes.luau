local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local spPlacePath = "c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl"
local p = roblox.deserializePlace(fs.readFile(spPlacePath))

print("=== Searching for Hero Models in Speedters ===")

-- Check ReplicatedStorage for character/hero models
local rs = p:GetService("ReplicatedStorage")
print("RS Children:")
for _, c in ipairs(rs:GetChildren()) do
    if c.Name:lower():find("hero") or c.Name:lower():find("skin") or c.Name:lower():find("character") or c.Name:lower():find("morph") or c.Name:lower():find("asset") or c.Name:lower():find("model") then
        print("  RS:", c.Name, c.ClassName)
        for _, sub in ipairs(c:GetChildren()) do
            print("    Sub:", sub.Name, sub.ClassName)
            if #sub:GetChildren() > 0 and #sub:GetChildren() < 10 then
                for _, s2 in ipairs(sub:GetChildren()) do
                    print("      s2:", s2.Name, s2.ClassName)
                end
            end
        end
    end
end

-- Check ServerStorage
local ss = p:GetService("ServerStorage")
print("\nSS Children:")
for _, c in ipairs(ss:GetChildren()) do
    if c.Name:lower():find("hero") or c.Name:lower():find("skin") or c.Name:lower():find("character") or c.Name:lower():find("morph") or c.Name:lower():find("asset") or c.Name:lower():find("model") then
        print("  SS:", c.Name, c.ClassName)
        for _, sub in ipairs(c:GetChildren()) do
            print("    Sub:", sub.Name, sub.ClassName)
        end
    end
end

-- Check Workspace
print("\nWorkspace Children:")
for _, c in ipairs(p.Workspace:GetChildren()) do
    if c.Name:lower():find("hero") or c.Name:lower():find("npc") or c.Name:lower():find("boss") then
        print("  WS:", c.Name, c.ClassName)
    end
end
