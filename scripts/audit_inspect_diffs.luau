local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local vipRaw = fs.readFile("Steal An Egg Fully Scripted VIP.rbxl")
local vip = roblox.deserializePlace(vipRaw)
local v2Raw = fs.readFile("Steal An Egg with treadmill V2.rbxl")
local v2 = roblox.deserializePlace(v2Raw)

local function inspectScript(name, inst1, inst2)
    print("========================================")
    print("DIFF: " .. name)
    print("========================================")
    local s1 = inst1 and inst1.Source or "<nil>"
    local s2 = inst2 and inst2.Source or "<nil>"
    print("Len 1:", #s1, "Len 2:", #s2)
    -- print first 200 chars or find differences
    local lines1 = string.split(s1, "\n")
    local lines2 = string.split(s2, "\n")
    print("Lines 1:", #lines1, "Lines 2:", #lines2)
    local diffCount = 0
    for i = 1, math.max(#lines1, #lines2) do
        local l1 = lines1[i]
        local l2 = lines2[i]
        if l1 ~= l2 then
            diffCount += 1
            if diffCount <= 10 then
                print(string.format("Line %d:\n  VIP: %s\n  V2:  %s", i, tostring(l1), tostring(l2)))
            end
        end
    end
    print("Total diff lines:", diffCount)
end

local vipSSS = vip:GetService("ServerScriptService")
local v2SSS = v2:GetService("ServerScriptService")

inspectScript("TreadmillGrindService", 
    vipSSS.Controllers:FindFirstChild("TreadmillGrindService"),
    v2SSS.Controllers:FindFirstChild("TreadmillGrindService")
)

inspectScript("AssetService", 
    vipSSS.Controllers:FindFirstChild("AssetService"),
    v2SSS.Controllers:FindFirstChild("AssetService")
)

local vipSPS = vip:GetService("StarterPlayer").StarterPlayerScripts
local v2SPS = v2:GetService("StarterPlayer").StarterPlayerScripts

inspectScript("AreaEggs",
    vipSPS.Game:FindFirstChild("AreaEggs"),
    v2SPS.Game:FindFirstChild("AreaEggs")
)
