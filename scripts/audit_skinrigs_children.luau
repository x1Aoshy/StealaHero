local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local raw = fs.readFile("c:/Users/Aoshy´/Desktop/Update2/src/assets/SkinRigs.rbxm")
local root = roblox.deserializeModel(raw)
for _, folder in ipairs(root) do
    print("Folder: " .. folder.Name)
    for _, item in ipairs(folder:GetChildren()) do
        local hum = item:FindFirstChildOfClass("Humanoid")
        local rigType = hum and tostring(hum.RigType) or "NoHumanoid"
        print("  - " .. item.Name .. " (" .. item.ClassName .. ", Rig: " .. rigType .. ")")
    end
end
