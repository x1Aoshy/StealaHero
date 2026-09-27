local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local file = roblox.deserializePlace(fs.readFile("c:/Users/Aoshy´/Desktop/Update2/World1Update3New.rbxl"))

local function findCandidates(inst)
    local n = inst.Name:lower()
    if inst:IsA("Model") and (n:find("treadmill") or n == "basic" or n == "diamond" or n == "needoh" or n == "hacker" or n == "admin" or n == "valentine") then
        print("Candidate Model:", inst.Name, "at", inst:GetFullName())
        for _, c in ipairs(inst:GetChildren()) do
            print("   ->", c.Name, "(" .. c.ClassName .. ")")
        end
    end
    for _, c in ipairs(inst:GetChildren()) do
        findCandidates(c)
    end
end

findCandidates(file.Workspace)
