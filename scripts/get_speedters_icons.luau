local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local raw = fs.readFile("c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl")
local place = roblox.deserializePlace(raw)

local mainHud = place:GetService("StarterGui"):FindFirstChild("Mainhud")
local leftBar = mainHud and mainHud:FindFirstChild("LeftSideBar")

print("=== Speedters LeftSideBar Icons ===")
if leftBar then
    for _, btn in ipairs(leftBar:GetChildren()) do
        if btn:IsA("ImageButton") then
            local icon = btn:FindFirstChild("Icon") or btn:FindFirstChild("Rebirth")
            local img = icon and icon:IsA("ImageLabel") and icon.Image or "none"
            local nameLabel = btn:FindFirstChild("Name")
            local txt = nameLabel and nameLabel:IsA("TextLabel") and nameLabel.Text or "none"
            print(string.format("Button: %s | Text: '%s' | Icon Image: %s", btn.Name, txt, img))
        end
    end
end

local rebithBar = mainHud and mainHud:FindFirstChild("Rebith/trof")
if rebithBar then
    print("\n=== Speedters Currency / Trophy Icons ===")
    for _, ch in ipairs(rebithBar:GetChildren()) do
        if ch:IsA("ImageLabel") then
            print(string.format("ImageLabel: %s | Image: %s", ch.Name, ch.Image))
        end
    end
end
