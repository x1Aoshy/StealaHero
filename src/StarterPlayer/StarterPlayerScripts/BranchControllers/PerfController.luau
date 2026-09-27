-- StarterPlayer.StarterPlayerScripts.BranchControllers.PerfController (Branch controller; injected by
-- scripts/inject/branch.luau, started by StarterPlayerScripts.BranchClient)
-- Owner 2026-09-27: "hyper optimised: client FPS, memory use". Client-side budget for what the build cannot know ahead:
--   * world billboards on the plots (hero name / income tags over every pen hero of every player, pen displays) stop
--     rendering beyond BILLBOARD_RANGE studs (they had no MaxDistance: dozens of GUIs were laid out and drawn every frame
--     across the whole map). Only a billboard with no distance limit of its own is capped; one a script already limits is
--     left alone.
--   * on touch devices (owner 2026-09-27: "prioritise phone players: no lag"): billboards stop at MOBILE_BILLBOARD_RANGE,
--     the far woods outside the walls (Workspace.Scenery models marked SceneryFar; the treeline hugging the walls stays)
--     are removed from this client only, and the hero eggs' VFX emitters (attribute EggVfx) emit at MOBILE_EGG_VFX_RATE
--     of their rate.
-- Event driven (DescendantAdded), no per-frame work.

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local PerfController = {}

PerfController.BILLBOARD_RANGE = 120
PerfController.MOBILE_BILLBOARD_RANGE = 80
PerfController.MOBILE_EGG_VFX_RATE = 0.5
local ROOTS = { "ClientRenderedAssets", "Plots" }

local function isTouchFirst()
	local preferred = nil
	pcall(function()
		preferred = UserInputService.PreferredInput
	end)
	if preferred ~= nil then
		return preferred == Enum.PreferredInput.Touch
	end
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end
local mobile = false

local function capBillboard(gui)
	if gui:IsA("BillboardGui") and (gui.MaxDistance == math.huge or gui.MaxDistance <= 0 or gui.MaxDistance > 10000) then
		gui.MaxDistance = if mobile then PerfController.MOBILE_BILLBOARD_RANGE else PerfController.BILLBOARD_RANGE
	end
end

local function thinEggVfx(emitter)
	if emitter:IsA("ParticleEmitter") and emitter:GetAttribute("EggVfx") == true and emitter:GetAttribute("EggVfxThinned") ~= true then
		emitter:SetAttribute("EggVfxThinned", true)
		emitter.Rate *= PerfController.MOBILE_EGG_VFX_RATE
	end
end

local function mobileBudget()
	local scenery = Workspace:FindFirstChild("Scenery")
	if scenery then
		for _, m in ipairs(scenery:GetDescendants()) do
			if m:IsA("Model") and m:GetAttribute("SceneryFar") == true and m.Parent then
				m:Destroy() -- local copy only: nothing replicates back
			end
		end
	end
	for _, d in ipairs(Workspace:GetDescendants()) do
		thinEggVfx(d)
	end
	Workspace.DescendantAdded:Connect(function(d)
		if d:IsA("ParticleEmitter") then
			task.defer(thinEggVfx, d)
		end
	end)
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
	mobile = isTouchFirst()
	if mobile then
		pcall(mobileBudget)
	end
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
