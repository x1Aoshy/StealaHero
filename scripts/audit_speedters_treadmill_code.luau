local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local raw = fs.readFile("c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl")
local spPlace = roblox.deserializePlace(raw)

local sss = spPlace:GetService("ServerScriptService")
local tt = sss:FindFirstChild("Progression") and sss.Progression:FindFirstChild("TreadmillTraining")
if tt then
    print("--- TreadmillTraining source preview ---")
    local lines = string.split(tt.Source, "\n")
    for i = 1, math.min(50, #lines) do
        print(lines[i])
    end
end
