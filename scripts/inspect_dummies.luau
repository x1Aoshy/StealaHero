local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local spPlacePath = "c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl"
local p = roblox.deserializePlace(fs.readFile(spPlacePath))
local cp = p:GetService("ServerStorage"):FindFirstChild("RawCosmeticPack")

if cp then
    local count = 0
    for _, c in ipairs(cp:GetChildren()) do
        if c.Name == "R6 Dummy" then
            count = count + 1
            local shirt = c:FindFirstChildOfClass("Shirt")
            local pants = c:FindFirstChildOfClass("Pants")
            local accs = {}
            for _, a in ipairs(c:GetChildren()) do
                if a:IsA("Accessory") then table.insert(accs, a.Name) end
            end
            print(string.format("Dummy #%d | Shirt=%s | Pants=%s | Accs=%s",
                count,
                shirt and shirt.ShirtTemplate or "NONE",
                pants and pants.PantsTemplate or "NONE",
                table.concat(accs, ", ")
            ))
        end
    end
end
