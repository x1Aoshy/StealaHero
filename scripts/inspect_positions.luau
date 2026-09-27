local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame

local p = roblox.deserializePlace(fs.readFile("StealaHero.rbxl"))
local ws = p.Workspace

print("=== Baseplate ===")
local bp = ws:FindFirstChild("Baseplate")
if bp then
    print(string.format("Baseplate: Pos=(%.1f, %.1f, %.1f) Size=(%.1f, %.1f, %.1f)",
        bp.CFrame.Position.X, bp.CFrame.Position.Y, bp.CFrame.Position.Z,
        bp.Size.X, bp.Size.Y, bp.Size.Z))
    local topY = bp.CFrame.Position.Y + (bp.Size.Y / 2)
    local minX = bp.CFrame.Position.X - (bp.Size.X / 2)
    local maxX = bp.CFrame.Position.X + (bp.Size.X / 2)
    local minZ = bp.CFrame.Position.Z - (bp.Size.Z / 2)
    local maxZ = bp.CFrame.Position.Z + (bp.Size.Z / 2)
    print(string.format("  Baseplate Top Y = %.1f | X Range: [%.1f, %.1f] | Z Range: [%.1f, %.1f]",
        topY, minX, maxX, minZ, maxZ))
end

print("\n=== Plots Bounds ===")
local plots = ws:FindFirstChild("Plots")
if plots then
    for _, plot in ipairs(plots:GetChildren()) do
        local minP = Vector3.new(1e9, 1e9, 1e9)
        local maxP = Vector3.new(-1e9, -1e9, -1e9)
        for _, part in ipairs(plot:GetDescendants()) do
            if part:IsA("BasePart") then
                local pos = part.CFrame.Position
                local s = part.Size / 2
                minP = Vector3.new(math.min(minP.X, pos.X - s.X), math.min(minP.Y, pos.Y - s.Y), math.min(minP.Z, pos.Z - s.Z))
                maxP = Vector3.new(math.max(maxP.X, pos.X + s.X), math.max(maxP.Y, pos.Y + s.Y), math.max(maxP.Z, pos.Z + s.Z))
            end
        end
        print(string.format("Plot %-3s | Min=(%.1f, %.1f, %.1f) | Max=(%.1f, %.1f, %.1f) | Center=(%.1f, %.1f, %.1f)",
            plot.Name, minP.X, minP.Y, minP.Z, maxP.X, maxP.Y, maxP.Z,
            (minP.X + maxP.X)/2, (minP.Y + maxP.Y)/2, (minP.Z + maxP.Z)/2))
    end
end

print("\n=== Stands Bounds ===")
local stands = ws:FindFirstChild("Stands")
if stands then
    local minP = Vector3.new(1e9, 1e9, 1e9)
    local maxP = Vector3.new(-1e9, -1e9, -1e9)
    for _, part in ipairs(stands:GetDescendants()) do
        if part:IsA("BasePart") then
            local pos = part.CFrame.Position
            local s = part.Size / 2
            minP = Vector3.new(math.min(minP.X, pos.X - s.X), math.min(minP.Y, pos.Y - s.Y), math.min(minP.Z, pos.Z - s.Z))
            maxP = Vector3.new(math.max(maxP.X, pos.X + s.X), math.max(maxP.Y, pos.Y + s.Y), math.max(maxP.Z, pos.Z + s.Z))
        end
    end
    print(string.format("Stands | Min=(%.1f, %.1f, %.1f) | Max=(%.1f, %.1f, %.1f)",
        minP.X, minP.Y, minP.Z, maxP.X, maxP.Y, maxP.Z))
end

print("\n=== GuardAreas Bounds ===")
local ga = ws:FindFirstChild("__OBJECTS") and ws.__OBJECTS:FindFirstChild("Areas") and ws.__OBJECTS.Areas:FindFirstChild("GuardAreas")
if ga then
    for _, z in ipairs(ga:GetChildren()) do
        local bounds = z:FindFirstChild("Bounds")
        local guard = z:FindFirstChild("Guard")
        local hrp = guard and guard:FindFirstChild("HumanoidRootPart")
        print(string.format("Zone %-12s | Bounds Pos=(%.1f, %.1f, %.1f) Size=(%.1f, %.1f, %.1f) | Guard HRP=(%.1f, %.1f, %.1f)",
            z.Name,
            bounds.CFrame.Position.X, bounds.CFrame.Position.Y, bounds.CFrame.Position.Z,
            bounds.Size.X, bounds.Size.Y, bounds.Size.Z,
            hrp and hrp.CFrame.Position.X or 0, hrp and hrp.CFrame.Position.Y or 0, hrp and hrp.CFrame.Position.Z or 0))
    end
end
