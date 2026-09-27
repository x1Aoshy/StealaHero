local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local raw = fs.readFile("c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl")
local spPlace = roblox.deserializePlace(raw)

local names = {
    "Treadmill1", "Treadmill2_fast", "Treadmill3_superfast", "Treadmill4_hyperspeed", "Treadmill5_insanespeed"
}

for _, n in ipairs(names) do
    local found = {}
    for _, inst in ipairs(spPlace:GetDescendants()) do
        if inst.Name == n or inst.Name:find(n) then
            table.insert(found, inst:GetFullName() .. " (" .. inst.ClassName .. ")")
        end
    end
    print("Search " .. n .. ":", #found)
    for _, item in ipairs(found) do
        print("   " .. item)
    end
end
