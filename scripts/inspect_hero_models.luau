local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local spPlacePath = "c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl"
local p = roblox.deserializePlace(fs.readFile(spPlacePath))

local heroes = {
    p.Workspace:FindFirstChild("Folder") and p.Workspace.Folder:FindFirstChild("Zoom"),
    p.Workspace:FindFirstChild("Folder") and p.Workspace.Folder:FindFirstChild("ReverseFlashBoss"),
    p.Workspace:FindFirstChild("ColdBloodedKiller"),
    p:GetService("ReplicatedStorage"):FindFirstChild("SkinRigs") and p.ReplicatedStorage.SkinRigs:FindFirstChild("ATrain"),
    p:GetService("ReplicatedStorage"):FindFirstChild("SkinRigs") and p.ReplicatedStorage.SkinRigs:FindFirstChild("Superman"),
}

for _, h in ipairs(heroes) do
    if h then
        local shirt = h:FindFirstChildOfClass("Shirt")
        local pants = h:FindFirstChildOfClass("Pants")
        local accs = {}
        for _, a in ipairs(h:GetChildren()) do
            if a:IsA("Accessory") then table.insert(accs, a.Name) end
        end
        print(string.format("Hero: %-20s | Shirt=%s | Pants=%s | Accs=%s",
            h.Name,
            shirt and shirt.ShirtTemplate or "NONE",
            pants and pants.PantsTemplate or "NONE",
            table.concat(accs, ", ")
        ))
    end
end
