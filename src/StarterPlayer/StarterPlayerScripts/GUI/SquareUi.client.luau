-- StarterPlayerScripts.GUI.SquareUi (injected by scripts/inject/ui_square.luau)
-- Owner 2026-09-27: "no more rounded UI, leave them square". The build squares every UICorner it leaves in the place
-- (scripts/steps/ui_98_square_studs.luau); this squares the ones scripts create at runtime (tooltips, backpack slots,
-- doors, panels) in this player's PlayerGui and in the world's SurfaceGuis / BillboardGuis.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ZERO = UDim.new(0, 0)

-- Owner 2026-09-27: "the topbar UI is not square, leave it round" and "the prompt to grab the eggs must be round like
-- before, not square": TopbarPlus's icons (PlayerGui.TopbarStandard / TopbarCentered, and any clone it makes) and the
-- proximity prompts (Game.ProximityPromptScript clones its templates into PlayerGui.ProximityPrompts) keep their round
-- corners.
local ROUND_GUIS = { ProximityPrompts = true }
local function isTopbar(inst)
	local node = inst
	while node ~= nil do
		if node:IsA("ScreenGui") then
			return string.sub(node.Name, 1, 6) == "Topbar" or ROUND_GUIS[node.Name] == true
		end
		node = node.Parent
	end
	return false
end

local function square(corner)
	if corner.CornerRadius ~= ZERO and not isTopbar(corner) then
		corner.CornerRadius = ZERO
	end
end

local function watch(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("UICorner") then
			square(d)
		end
	end
	root.DescendantAdded:Connect(function(d)
		if d.ClassName == "UICorner" then
			square(d)
			-- a script that sets the radius right after creating the corner
			d:GetPropertyChangedSignal("CornerRadius"):Connect(function()
				square(d)
			end)
		end
	end)
end

watch(Players.LocalPlayer:WaitForChild("PlayerGui"))
watch(Workspace)
