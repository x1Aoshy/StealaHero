local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local function inspectGame(name, file)
    print("========================================")
    print("INSPECTING: " .. name .. " (" .. file .. ")")
    print("========================================")
    local raw = fs.readFile(file)
    local place = roblox.deserializePlace(raw)
    local ws = place.Workspace
    
    print("Workspace children:")
    for _, c in ipairs(ws:GetChildren()) do
        print("  - " .. c.Name .. " (" .. c.ClassName .. ")")
    end
    
    local plots = ws:FindFirstChild("Plots")
    if plots then
        local p1 = plots:FindFirstChild("1")
        if p1 then
            print("Plot 1 children:")
            for _, c in ipairs(p1:GetChildren()) do
                print("    * " .. c.Name .. " (" .. c.ClassName .. ")")
            end
        end
    end
    
    -- Check Treadmills
    local treadmills = {}
    for _, inst in ipairs(ws:GetDescendants()) do
        if string.find(string.lower(inst.Name), "treadmill") then
            table.insert(treadmills, inst:GetFullName())
        end
    end
    print("Treadmill references in Workspace:", #treadmills)
    for i = 1, math.min(5, #treadmills) do
        print("   " .. treadmills[i])
    end
end

inspectGame("VIP", "Steal An Egg Fully Scripted VIP.rbxl")
inspectGame("V2", "Steal An Egg with treadmill V2.rbxl")
