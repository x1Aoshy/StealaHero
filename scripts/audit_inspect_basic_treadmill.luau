local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local file = roblox.deserializePlace(fs.readFile("c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl"))
local basic = file.Workspace:FindFirstChild("neworld1") and file.Workspace.neworld1:FindFirstChild("Basic")
if basic then
    local tm = basic:FindFirstChild("Treadmil")
    print("Basic.Treadmil found!")
    for _, c in ipairs(tm:GetChildren()) do
        print("  -", c.Name, "(" .. c.ClassName .. ")")
    end
end
