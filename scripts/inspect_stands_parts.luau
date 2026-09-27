local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local p = roblox.deserializePlace(fs.readFile("StealaHero.rbxl"))
local stands = p.Workspace.Stands

print("=== Stands Children ===")
print("Stands ClassName:", stands.ClassName, "Children:", #stands:GetChildren())
for _, c in ipairs(stands:GetChildren()) do
    print(string.format("  Child: %-25s Class=%s (#children=%d)", c.Name, c.ClassName, #c:GetChildren()))
    for _, sub in ipairs(c:GetChildren()) do
        if sub:IsA("BasePart") then
            print(string.format("    Part: %-20s Pos=(%.2f, %.2f, %.2f) Size=(%.2f, %.2f, %.2f)",
                sub.Name, sub.CFrame.Position.X, sub.CFrame.Position.Y, sub.CFrame.Position.Z,
                sub.Size.X, sub.Size.Y, sub.Size.Z))
        end
    end
end
