local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

print("=== CHECKING REPLICATED STORAGE SCRIPTS ===")
local vipRaw = fs.readFile("Steal An Egg Fully Scripted VIP.rbxl")
local vip = roblox.deserializePlace(vipRaw)
local v2Raw = fs.readFile("Steal An Egg with treadmill V2.rbxl")
local v2 = roblox.deserializePlace(v2Raw)

local function getScripts(root, prefix)
    local list = {}
    prefix = prefix or ""
    for _, child in ipairs(root:GetChildren()) do
        local path = prefix .. "/" .. child.Name
        if child:IsA("LuaSourceContainer") then
            list[path] = {
                className = child.ClassName,
                sourceLen = #child.Source,
            }
        end
        local sub = getScripts(child, path)
        for k, v in pairs(sub) do
            list[k] = v
        end
    end
    return list
end

local vipRS = vip:GetService("ReplicatedStorage")
local v2RS = v2:GetService("ReplicatedStorage")
local vipList = getScripts(vipRS, "RS")
local v2List = getScripts(v2RS, "RS")

print("Total VIP RS scripts:", 0)
local countVip = 0
for _ in pairs(vipList) do countVip += 1 end
local countV2 = 0
for _ in pairs(v2List) do countV2 += 1 end
print("VIP RS scripts:", countVip, "V2 RS scripts:", countV2)

for path, data in pairs(vipList) do
    if not v2List[path] then
        print("[VIP ONLY]", path, "(" .. data.className .. ", " .. data.sourceLen .. " bytes)")
    else
        if data.sourceLen ~= v2List[path].sourceLen then
            print("[DIFF LEN]", path, "VIP:" .. data.sourceLen .. " vs V2:" .. v2List[path].sourceLen)
        end
    end
end
for path, data in pairs(v2List) do
    if not vipList[path] then
        print("[V2 ONLY]", path, "(" .. data.className .. ", " .. data.sourceLen .. " bytes)")
    end
end
