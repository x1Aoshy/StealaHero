local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local p = roblox.deserializePlace(fs.readFile("StealaHero.rbxl"))
local plot1 = p.Workspace.Plots:FindFirstChild("1")

print("=== BaseParts in Plot 1 ===")
for _, c in ipairs(plot1:GetChildren()) do
    if c:IsA("BasePart") then
        print(string.format("  Part: %-20s Pos=(%.2f, %.2f, %.2f) Size=(%.2f, %.2f, %.2f)",
            c.Name, c.CFrame.Position.X, c.CFrame.Position.Y, c.CFrame.Position.Z,
            c.Size.X, c.Size.Y, c.Size.Z))
    elseif c:IsA("Model") or c:IsA("Folder") then
        print(string.format("  Folder/Model: %-20s (#children=%d)", c.Name, #c:GetChildren()))
        for _, sub in ipairs(c:GetChildren()) do
            if sub:IsA("BasePart") and (sub.Size.X > 5 or sub.Size.Z > 5) then
                print(string.format("    SubPart: %-18s Pos=(%.2f, %.2f, %.2f) Size=(%.2f, %.2f, %.2f)",
                    sub.Name, sub.CFrame.Position.X, sub.CFrame.Position.Y, sub.CFrame.Position.Z,
                    sub.Size.X, sub.Size.Y, sub.Size.Z))
            end
        end
    end
end
