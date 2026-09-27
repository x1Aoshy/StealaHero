local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local raw = fs.readFile("c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl")
local spPlace = roblox.deserializePlace(raw)

local ws = spPlace.Workspace
local treadmillArea = ws:FindFirstChild("neworld1") and ws.neworld1:FindFirstChild("Treadmillarea")
if treadmillArea then
    print("Found Treadmillarea! Children:")
    for _, c in ipairs(treadmillArea:GetChildren()) do
        print("  - " .. c.Name .. " (" .. c.ClassName .. ")")
        if c:IsA("Model") then
            for _, sub in ipairs(c:GetChildren()) do
                print("      * " .. sub.Name .. " (" .. sub.ClassName .. ")")
            end
        end
    end
else
    print("Treadmillarea not found under ws.neworld1!")
end

print("\n--- Inspecting Workspace.Folder in Speedsters ---")
local folder = ws:FindFirstChild("Folder")
if folder then
    for _, c in ipairs(folder:GetChildren()) do
        print("  - " .. c.Name .. " (" .. c.ClassName .. ")")
    end
end
