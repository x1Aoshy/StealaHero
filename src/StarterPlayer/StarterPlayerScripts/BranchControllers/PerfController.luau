-- StarterPlayer.StarterPlayerScripts.BranchControllers.PerfController (Branch controller; injected by
-- scripts/inject/branch.luau, started by StarterPlayerScripts.BranchClient)
-- Owner 2026-09-27: "hyper optimised: client FPS, memory use". Client-side budget for what the build cannot know ahead:
--   * world billboards on the plots (hero name / income tags over every pen hero of every player, pen displays) stop
--     rendering beyond BILLBOARD_RANGE studs (they had no MaxDistance: dozens of GUIs were laid out and drawn every frame
--     across the whole map). Only a billboard with no distance limit of its own is capped; one a script already limits is
--     left alone.
-- Event driven (DescendantAdded), no per-frame work.

local Workspace = game:GetService("Workspace")

local PerfController = {}

PerfController.BILLBOARD_RANGE = 120
local ROOTS = { "ClientRenderedAssets", "Plots" }

local function capBillboard(gui)
	if gui:IsA("BillboardGui") and (gui.MaxDistance == math.huge or gui.MaxDistance <= 0 or gui.MaxDistance > 10000) then
		gui.MaxDistance = PerfController.BILLBOARD_RANGE
	end
end

local function watch(root)
	for _, d in ipairs(root:GetDescendants()) do
		capBillboard(d)
	end
	root.DescendantAdded:Connect(function(d)
		if d:IsA("BillboardGui") then
			task.defer(capBillboard, d)
		end
	end)
end

function PerfController:Start()
	for _, name in ipairs(ROOTS) do
		local root = Workspace:FindFirstChild(name)
		if root then
			watch(root)
		end
	end
	Workspace.ChildAdded:Connect(function(child)
		if table.find(ROOTS, child.Name) then
			watch(child)
		end
	end)
end

return PerfController
