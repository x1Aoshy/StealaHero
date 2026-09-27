local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local p = roblox.deserializePlace(fs.readFile("StealaHero.rbxl"))
local rs = p:GetService("ReplicatedStorage")
local am = rs:FindFirstChild("AssetModels")

print("=== AssetModels in ReplicatedStorage ===")
if am then
    print("AssetModels count:", #am:GetChildren())
    for i = 1, math.min(#am:GetChildren(), 20) do
        local child = am:GetChildren()[i]
        print(string.format("  #%d: %-20s (%s)", i, child.Name, child.ClassName))
    end
else
    print("NO AssetModels folder in ReplicatedStorage!")
end

local function inspectModel(name)
    local m = am and am:FindFirstChild(name)
    if not m then return end
    print(string.format("\n=== %s in AssetModels ===", name))
    print("PrimaryPart:", m.PrimaryPart and m.PrimaryPart.Name)
    print("CENTER:", m:FindFirstChild("CENTER") ~= nil)
    local subModel = m:FindFirstChild("Model")
    print("Child 'Model':", subModel ~= nil)
    if subModel then
        local animCtrl = subModel:FindFirstChildWhichIsA("AnimationController")
        print("  AnimationController:", animCtrl ~= nil)
    end
    for _, c in ipairs(m:GetChildren()) do
        if c:IsA("Humanoid") then
            print("  Has Humanoid:", c.Name)
        end
    end
end

inspectModel("Warden")
inspectModel("Spider")
inspectModel("Mire Fox")
inspectModel("Burrowing Owl")


