-- StarterPlayer.StarterPlayerScripts.BranchControllers.UiScaleController (Branch controller; injected by
-- scripts/inject/branch.luau, started by StarterPlayerScripts.BranchClient)
-- Owner 2026-09-27: "the positions are fine; I mean the sizes, the buttons and the screen sizing: comfortable on phone,
-- playable on console". The HUD is laid out in scale for a desktop screen: on a phone the Shop / Index rectangles and the
-- tabs come out ~27 px tall (under a thumb's ~44 px) and on a TV across the room everything reads small. This picks a
-- device profile and scales the HUD groups by a factor per profile with each group's UIScale - a UIScale grows a
-- GuiObject around its AnchorPoint, so every group keeps its authored position (left column, right tabs, bottom-left
-- money, bottom-right timer) and only gets bigger.
--   phone    touch-first and the short side of the screen under PHONE_SHORT_SIDE px
--   tablet   touch-first, bigger screens
--   console  gamepad-first or a ten-foot interface (Xbox / PlayStation / TV)
--   desktop  unchanged
-- A group that already carries a UIScale keeps it (its authored scale is remembered in the SpBaseScale attribute and
-- multiplied), otherwise an "SpDeviceScale" UIScale is added. Re-applied when the input type or the screen changes and
-- when the HUD is recreated. Event driven, nothing per frame.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local UiScaleController = {}

UiScaleController.PHONE_SHORT_SIDE = 500
UiScaleController.TABLET_SHORT_SIDE = 900
-- { ScreenGui, child path, factors per profile }
UiScaleController.TARGETS = {
	{ "Elements", { "Left" }, { phone = 1.4, tablet = 1.15, console = 1.3 } }, -- Shop / Index
	{ "Elements", { "Tabs" }, { phone = 1.4, tablet = 1.15, console = 1.3 } }, -- Eggs / Hero Index tabs
	{ "Elements", { "RightFrame" }, { phone = 1.25, tablet = 1.1, console = 1.2 } }, -- x2 speed pill (treadmill)
	{ "Money", { "Bottom" }, { phone = 1.2, tablet = 1.1, console = 1.25 } }, -- money / speed ribbons
	{ "GameResetTimer", { "TimeLeft" }, { phone = 1.2, tablet = 1.1, console = 1.25 } },
	{ "GameResetTimer", { "EndingSoon" }, { phone = 1.15, tablet = 1.05, console = 1.2 } },
}

local profile = "desktop"

local function detect()
	local preferred = nil
	pcall(function()
		preferred = UserInputService.PreferredInput
	end)
	local tenFoot = false
	pcall(function()
		tenFoot = GuiService:IsTenFootInterface()
	end)
	local gamepad = tenFoot or (preferred ~= nil and preferred == Enum.PreferredInput.Gamepad)
	local touch = if preferred ~= nil then preferred == Enum.PreferredInput.Touch
		else UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if gamepad then
		return "console"
	elseif touch then
		local camera = Workspace.CurrentCamera
		local size = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local short = math.min(size.X, size.Y)
		if short < UiScaleController.PHONE_SHORT_SIDE then
			return "phone"
		elseif short < UiScaleController.TABLET_SHORT_SIDE then
			return "tablet"
		end
		return "desktop"
	end
	return "desktop"
end
UiScaleController._detect = detect

local function scaleOf(object)
	for _, c in ipairs(object:GetChildren()) do
		if c:IsA("UIScale") then
			return c
		end
	end
	local scale = Instance.new("UIScale")
	scale.Name = "SpDeviceScale"
	scale.Parent = object
	return scale
end

local function apply()
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end
	for _, target in ipairs(UiScaleController.TARGETS) do
		local node = playerGui:FindFirstChild(target[1])
		for _, name in ipairs(target[2]) do
			node = node and node:FindFirstChild(name)
		end
		if node and node:IsA("GuiObject") then
			local scale = scaleOf(node)
			local base = scale:GetAttribute("SpBaseScale")
			if type(base) ~= "number" then
				base = scale.Scale
				scale:SetAttribute("SpBaseScale", base)
			end
			local factor = target[3][profile] or 1
			local wanted = base * factor
			if math.abs(scale.Scale - wanted) > 1e-3 then
				scale.Scale = wanted
			end
		end
	end
	playerGui:SetAttribute("UiDeviceProfile", profile)
end

local function refresh()
	profile = detect()
	apply()
end

function UiScaleController:Start()
	refresh()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	playerGui.ChildAdded:Connect(function(child)
		for _, target in ipairs(UiScaleController.TARGETS) do
			if child.Name == target[1] then
				task.defer(apply)
				break
			end
		end
	end)
	pcall(function()
		UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
	end)
	UserInputService.LastInputTypeChanged:Connect(function()
		local wanted = detect()
		if wanted ~= profile then
			refresh()
		end
	end)
	local function watchCamera(camera)
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
		end
	end
	watchCamera(Workspace.CurrentCamera)
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		watchCamera(Workspace.CurrentCamera)
		refresh()
	end)
end

-- Test hook: the profile currently applied.
function UiScaleController.GetProfile()
	return profile
end

return UiScaleController
