local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local file = roblox.deserializePlace(fs.readFile("Steal An Egg with treadmill V2.rbxl"))
local p1 = file.Workspace.Plots:FindFirstChild("1")
if p1 then
    local tu = p1:FindFirstChild("TreadmillUpgrade")
    print("TreadmillUpgrade children:")
    for _, c in ipairs(tu:GetChildren()) do
        print("  -", c.Name, "(" .. c.ClassName .. ")")
        for _, sub in ipairs(c:GetChildren()) do
            print("     *", sub.Name, "(" .. sub.ClassName .. ")")
        end
    end
    local tb = p1:FindFirstChild("TreadmillBottom")
    print("TreadmillBottom:", tb.ClassName, "Size:", tostring(tb.Size), "CFrame:", tostring(tb.CFrame))
end
