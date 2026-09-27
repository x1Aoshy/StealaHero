local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

print("Loading World1Update3New.rbxl...")
local raw = fs.readFile("c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl")
local spPlace = roblox.deserializePlace(raw)

print("--- Inspecting Treadmills in Speedsters ---")
local tmList = {}
for _, inst in ipairs(spPlace:GetDescendants()) do
    if string.find(string.lower(inst.Name), "treadmill") then
        table.insert(tmList, inst:GetFullName() .. " (" .. inst.ClassName .. ")")
    end
end
print("Total treadmill occurrences:", #tmList)
for i = 1, math.min(25, #tmList) do
    print("  " .. tmList[i])
end

print("\n--- Inspecting Characters / Heroes in Speedsters ---")
local heroesList = {}
for _, inst in ipairs(spPlace:GetDescendants()) do
    if inst:IsA("Model") and inst:FindFirstChildOfClass("Humanoid") then
        local hum = inst:FindFirstChildOfClass("Humanoid")
        table.insert(heroesList, inst:GetFullName() .. " (RigType: " .. tostring(hum.RigType) .. ")")
    end
end
print("Total Models with Humanoid:", #heroesList)
for i = 1, math.min(30, #heroesList) do
    print("  " .. heroesList[i])
end

print("\n--- Inspecting StarterGui in Speedsters ---")
local sg = spPlace:GetService("StarterGui")
for _, c in ipairs(sg:GetChildren()) do
    print("  " .. c.Name .. " (" .. c.ClassName .. ")")
end

print("\n--- Inspecting Sounds in Speedsters ---")
local sounds = {}
for _, inst in ipairs(spPlace:GetDescendants()) do
    if inst:IsA("Sound") then
        table.insert(sounds, inst.Name .. " -> " .. tostring(inst.SoundId))
    end
end
print("Total Sounds in Speedsters:", #sounds)
for i = 1, math.min(20, #sounds) do
    print("  " .. sounds[i])
end
