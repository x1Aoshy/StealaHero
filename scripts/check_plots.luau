local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local function inspectPlots(path)
    local raw = fs.readFile(path)
    local place = roblox.deserializePlace(raw)
    local ws = place.Workspace
    local plots = ws:FindFirstChild("Plots")
    print("-----------------------------------------")
    print(path)
    if plots then
        local names = {}
        for _, c in ipairs(plots:GetChildren()) do
            table.insert(names, c.Name)
        end
        print("Plots count: " .. #names .. " -> " .. table.concat(names, ", "))
    else
        print("No Plots folder!")
    end
end

inspectPlots("Steal An Egg Fully Scripted VIP.rbxl")
inspectPlots("Steal An Egg with treadmill V2.rbxl")
inspectPlots("StealaHero.rbxl")
