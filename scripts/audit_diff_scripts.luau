local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

print("=== COMPARING VIP vs V2 SCRIPTS ===")
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
                sourceHash = child.Source,
            }
        end
        local sub = getScripts(child, path)
        for k, v in pairs(sub) do
            list[k] = v
        end
    end
    return list
end

local vipSSS = vip:GetService("ServerScriptService")
local v2SSS = v2:GetService("ServerScriptService")

local vipScripts = getScripts(vipSSS, "SSS")
local v2Scripts = getScripts(v2SSS, "SSS")

print("Scripts in VIP SSS:", 0)
local vipCount = 0
for _ in pairs(vipScripts) do vipCount += 1 end
print("Total VIP SSS scripts:", vipCount)

local v2Count = 0
for _ in pairs(v2Scripts) do v2Count += 1 end
print("Total V2 SSS scripts:", v2Count)

print("\n--- Differences in ServerScriptService ---")
for path, data in pairs(vipScripts) do
    if not v2Scripts[path] then
        print("[VIP ONLY]", path, "(" .. data.className .. ", " .. data.sourceLen .. " bytes)")
    else
        if data.sourceLen ~= v2Scripts[path].sourceLen then
            print("[DIFF LEN]", path, "VIP:" .. data.sourceLen .. " vs V2:" .. v2Scripts[path].sourceLen)
        end
    end
end

for path, data in pairs(v2Scripts) do
    if not vipScripts[path] then
        print("[V2 ONLY]", path, "(" .. data.className .. ", " .. data.sourceLen .. " bytes)")
    end
end

-- Check StarterPlayerScripts
local vipSPS = vip:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local v2SPS = v2:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local vipCli = getScripts(vipSPS, "SPS")
local v2Cli = getScripts(v2SPS, "SPS")

print("\n--- Differences in StarterPlayerScripts ---")
for path, data in pairs(vipCli) do
    if not v2Cli[path] then
        print("[VIP ONLY]", path, "(" .. data.className .. ", " .. data.sourceLen .. " bytes)")
    else
        if data.sourceLen ~= v2Cli[path].sourceLen then
            print("[DIFF LEN]", path, "VIP:" .. data.sourceLen .. " vs V2:" .. v2Cli[path].sourceLen)
        end
    end
end
for path, data in pairs(v2Cli) do
    if not vipCli[path] then
        print("[V2 ONLY]", path, "(" .. data.className .. ", " .. data.sourceLen .. " bytes)")
    end
end
