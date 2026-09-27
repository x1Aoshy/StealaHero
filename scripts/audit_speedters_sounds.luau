local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local raw = fs.readFile("c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl")
local spPlace = roblox.deserializePlace(raw)

local sounds = {}
for _, inst in ipairs(spPlace:GetDescendants()) do
    if inst:IsA("Sound") then
        local sid = "unknown"
        pcall(function()
            sid = tostring(inst.SoundId)
        end)
        table.insert(sounds, {
            name = inst.Name,
            path = inst:GetFullName(),
            id = sid,
            vol = pcall(function() return inst.Volume end) or 0.5,
        })
    end
end

print("Total Sounds found in Speedsters:", #sounds)
for i = 1, math.min(30, #sounds) do
    local s = sounds[i]
    print(string.format("  [%d] %s: %s (Path: %s)", i, s.name, tostring(s.id), s.path))
end
