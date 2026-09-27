--!nocheck
-- scripts/steps/post_branch_framework.luau (owner 2026-09-27: "implement the Branch framework in the game")
-- Installs the vendored Branch 2.0.0 runtime (vendor/Branch, MIT) at ReplicatedStorage.Packages.Branch and creates the
-- two segment roots its loader starts:
--   ServerScriptService.BranchServices     *Service modules, started by ServerScriptService.BranchServer
--   StarterPlayerScripts.BranchControllers *Controller modules, started by StarterPlayerScripts.BranchClient
-- (the scripts and segments themselves are injected by scripts/inject/branch.luau). Branch.Data / Branch.Network are not
-- used: see vendor/Branch/README.md.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local Instance = roblox.Instance

local Step = {}

Step.RUNTIME = "vendor/Branch/Branch.rbxm"

local function folder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	elseif existing then
		existing:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function Step.Apply(place, _spPlace, _ctx)
	assert(fs.isFile(Step.RUNTIME), Step.RUNTIME .. " missing (vendored Branch runtime)")
	local packages = folder(place:GetService("ReplicatedStorage"), "Packages")
	local old = packages:FindFirstChild("Branch")
	if old then
		old:Destroy()
	end
	local roots = roblox.deserializeModel(fs.readFile(Step.RUNTIME))
	local branch = roots[1]
	assert(branch and branch:IsA("ModuleScript") and branch.Name == "Branch", "vendor Branch.rbxm must hold the Branch ModuleScript")
	branch:SetAttribute("SegmentRule", "Suffix")
	branch.Parent = packages -- the whole subtree in one move (its modules only reference each other by script paths)
	folder(place:GetService("ServerScriptService"), "BranchServices")
	folder(place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"), "BranchControllers")
	local count = #branch:GetDescendants()
	print(string.format("[post_branch_framework] Branch %s at ReplicatedStorage.Packages.Branch (%d modules); BranchServices / BranchControllers roots ready",
		"2.0.0", count))
end

return Step
