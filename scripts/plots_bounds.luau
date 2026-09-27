local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local raw = fs.readFile("StealaHero.rbxl")
local place = roblox.deserializePlace(raw)

local plots = place.Workspace.Plots

local minX, maxX = math.huge, -math.huge
local minY, maxY = math.huge, -math.huge
local minZ, maxZ = math.huge, -math.huge

local function checkParts(inst)
    if inst:IsA("BasePart") then
        local pos = inst.CFrame.Position
        local sz = inst.Size
        minX = math.min(minX, pos.X - sz.X/2)
        maxX = math.max(maxX, pos.X + sz.X/2)
        minY = math.min(minY, pos.Y - sz.Y/2)
        maxY = math.max(maxY, pos.Y + sz.Y/2)
        minZ = math.min(minZ, pos.Z - sz.Z/2)
        maxZ = math.max(maxZ, pos.Z + sz.Z/2)
    end
    for _, ch in ipairs(inst:GetChildren()) do
        checkParts(ch)
    end
end

checkParts(plots)
print(string.format("Plots Bounding Box: X=[%.1f, %.1f], Y=[%.1f, %.1f], Z=[%.1f, %.1f]", minX, maxX, minY, maxY, minZ, maxZ))
local centerX = (minX + maxX) / 2
local centerY = minY -- floor level
local centerZ = (minZ + maxZ) / 2
print(string.format("Calculated Center: X=%.1f, FloorY=%.1f, Z=%.1f", centerX, centerY, centerZ))
