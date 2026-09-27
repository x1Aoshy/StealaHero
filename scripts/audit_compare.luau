local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local function inspect(path)
    print("==================================================")
    print("INSPECTING: " .. path)
    print("==================================================")
    local raw = fs.readFile(path)
    local place = roblox.deserializePlace(raw)
    local ws = place.Workspace
    local plots = ws:FindFirstChild("Plots")
    if plots then
        local names = {}
        for _, c in ipairs(plots:GetChildren()) do
            table.insert(names, c.Name)
        end
        print("Plots (" .. #names .. "): " .. table.concat(names, ", "))
    else
        print("No Plots folder in Workspace!")
    end

    local rs = place:GetService("ReplicatedStorage")
    print("ReplicatedStorage top-level items:")
    for _, c in ipairs(rs:GetChildren()) do
        print("  - " .. c.Name .. " (" .. c.ClassName .. ")")
    end

    local sss = place:GetService("ServerScriptService")
    print("ServerScriptService top-level items:")
    for _, c in ipairs(sss:GetChildren()) do
        print("  - " .. c.Name .. " (" .. c.ClassName .. ")")
        if c:IsA("Folder") then
            for _, sub in ipairs(c:GetChildren()) do
                print("      * " .. sub.Name .. " (" .. sub.ClassName .. ")")
            end
        end
    end

    local starterGui = place:GetService("StarterGui")
    print("StarterGui top-level items:")
    for _, c in ipairs(starterGui:GetChildren()) do
        print("  - " .. c.Name .. " (" .. c.ClassName .. ")")
    end

    local starterPlayer = place:GetService("StarterPlayer")
    local sps = starterPlayer:FindFirstChild("StarterPlayerScripts")
    if sps then
        print("StarterPlayerScripts top-level items:")
        for _, c in ipairs(sps:GetChildren()) do
            print("  - " .. c.Name .. " (" .. c.ClassName .. ")")
        end
    end
end

inspect("Steal An Egg Fully Scripted VIP.rbxl")
inspect("Steal An Egg with treadmill V2.rbxl")
inspect("StealaHero.rbxl")
