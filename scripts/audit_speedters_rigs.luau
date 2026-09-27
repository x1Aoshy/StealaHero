local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

print("=== INSPECTING SPEEDTERS RIGS AND MODELS ===")

local function inspectRigs(path)
    if not fs.isFile(path) then
        print("File not found:", path)
        return
    end
    print("Reading " .. path .. "...")
    local raw = fs.readFile(path)
    local root = roblox.deserializeModel(raw)
    for _, item in ipairs(root) do
        print("Item in model: " .. item.Name .. " (" .. item.ClassName .. ")")
        if item:IsA("Model") then
            local hum = item:FindFirstChildOfClass("Humanoid")
            if hum then
                print("  RigType: " .. tostring(hum.RigType))
            end
            local parts = {}
            for _, p in ipairs(item:GetChildren()) do
                if p:IsA("BasePart") then table.insert(parts, p.Name) end
            end
            print("  Parts (" .. #parts .. "): " .. table.concat(parts, ", "))
        end
    end
end

inspectRigs("c:/Users/Aoshy´/Desktop/Update2/src/assets/SkinRigs.rbxm")
