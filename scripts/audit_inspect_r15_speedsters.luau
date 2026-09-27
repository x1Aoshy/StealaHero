local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local raw = fs.readFile("c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl")
local spPlace = roblox.deserializePlace(raw)

local ws = spPlace.Workspace
local folder = ws:FindFirstChild("Folder")
if folder then
    local zoom = folder:FindFirstChild("Zoom")
    if zoom then
        print("=== ZOOM in Speedsters Workspace.Folder ===")
        print("Class:", zoom.ClassName)
        local hum = zoom:FindFirstChildOfClass("Humanoid")
        print("Humanoid RigType:", hum and tostring(hum.RigType))
        for _, c in ipairs(zoom:GetChildren()) do
            print("  -", c.Name, "(" .. c.ClassName .. ")")
        end
    end
    local rf = folder:FindFirstChild("ReverseFlashBoss")
    if rf then
        print("=== ReverseFlashBoss in Speedsters Workspace.Folder ===")
        print("Class:", rf.ClassName)
        local hum = rf:FindFirstChildOfClass("Humanoid")
        print("Humanoid RigType:", hum and tostring(hum.RigType))
        for _, c in ipairs(rf:GetChildren()) do
            print("  -", c.Name, "(" .. c.ClassName .. ")")
        end
    end
end
