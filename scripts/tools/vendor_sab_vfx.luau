--!nocheck
-- scripts/tools/vendor_sab_vfx.luau
-- Builds vendor/sab_vfx.rbxl: a minimal place holding ONLY the effect subtrees scripts/steps/vfx.luau ports (Step.EFFECTS,
-- same ReplicatedStorage paths), so the build can run without the full third-party reference place (cloud sessions).
--   lune run scripts/tools/vendor_sab_vfx.luau "<path to V40 SAB by FaypleStudios.rbxl>"
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local Step = require("../steps/vfx")

local src = roblox.deserializePlace(fs.readFile(process.args[1] or Step.SAB_PLACE_PATH))
local srcRs = src:GetService("ReplicatedStorage")
local out = roblox.Instance.new("DataModel")
local outRs = out:GetService("ReplicatedStorage")
local copied = 0
for _, effect in ipairs(Step.EFFECTS) do
	local node = srcRs
	for _, seg in ipairs(string.split(effect.source, "/")) do
		node = node and node:FindFirstChild(seg)
	end
	if node then
		local segs = string.split(effect.source, "/")
		local parent = outRs
		for i = 1, #segs - 1 do
			local child = parent:FindFirstChild(segs[i])
			if not child then
				child = roblox.Instance.new("Folder")
				child.Name = segs[i]
				child.Parent = parent
			end
			parent = child
		end
		node:Clone().Parent = parent
		copied += 1
	else
		print("missing in the reference place: " .. effect.source)
	end
end
fs.writeFile("vendor/sab_vfx.rbxl", roblox.serializePlace(out))
print(string.format("vendor/sab_vfx.rbxl: %d/%d effect subtrees", copied, #Step.EFFECTS))
