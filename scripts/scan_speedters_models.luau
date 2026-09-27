local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local spPlacePath = "c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl"
local p = roblox.deserializePlace(fs.readFile(spPlacePath))

print("=== Scanning all Models in Speedters ===")
local modelsWithHum = {}
local skinModels = {}

for _, d in ipairs(p:GetDescendants()) do
    if d:IsA("Model") then
        local hum = d:FindFirstChildOfClass("Humanoid")
        if hum then
            table.insert(modelsWithHum, d:GetFullName())
        end
        if d.Name:lower():find("skin") or d.Name:lower():find("rig") or d.Name:lower():find("hero") then
            table.insert(skinModels, d:GetFullName())
        end
    end
end

print("Models with Humanoid (" .. #modelsWithHum .. "):")
for i = 1, math.min(#modelsWithHum, 40) do
    print("  ", modelsWithHum[i])
end

print("\nModels with skin/rig/hero in name (" .. #skinModels .. "):")
for i = 1, math.min(#skinModels, 40) do
    print("  ", skinModels[i])
end
