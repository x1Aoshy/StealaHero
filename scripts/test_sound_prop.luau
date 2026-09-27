local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local raw = fs.readFile("c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl")
local spPlace = roblox.deserializePlace(raw)

for _, inst in ipairs(spPlace:GetDescendants()) do
    if inst:IsA("Sound") then
        local ok, err = pcall(function()
            print(inst.Name, "SoundId:", inst.SoundId)
        end)
        if not ok then
            print(inst.Name, "Error:", err)
        end
        break
    end
end
