-- StarterPlayer.StarterPlayerScripts.BranchControllers.MenuMotionController (Branch controller; injected by
-- scripts/inject/branch.luau, started by StarterPlayerScripts.BranchClient)
-- Owner 2026-09-27:
--   * "there is no animation to open the egg menu or the Hero menu": the egg list (GrowingEggList) and the hero list
--     (PetList) only flip their ScreenGui's Enabled. When one opens, its panel now slides in from the right edge (where
--     the Egg / H tabs are) and pops from 0.9 to full size.
--   * "when a menu opens, Elements should slide down so it is not showing behind it; when the menu closes everything
--     comes back: elements, money and speed, the egg and hero buttons, shift lock, the night timer, the money counter".
--     While any menu is open (a TabController window: Shop, Index, Settings, Rebirth...; or the egg / hero list) the HUD
--     groups in HUD_GROUPS slide off their nearest screen edge, and they slide back when the last menu closes.
-- Only Position (and the panels' own "SpOpenScale" UIScale) is animated, with engine tweens. Other scripts keep
-- toggling Visible / Enabled on these GUIs as before (HideImportantUI while carrying an egg, the treadmill UI), and
-- UiScaleController keeps owning their UIScale. Each group's resting Position is remembered while it is away.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MenuMotionController = {}

-- { ScreenGui, child } slid away while a menu is open (the direction comes from where the group sits on screen)
MenuMotionController.HUD_GROUPS = {
	{ "Elements", "Left" }, -- Shop / Index column
	{ "Elements", "Tabs" }, -- Egg / H tabs
	{ "Elements", "Right" },
	{ "Elements", "RightFrame" }, -- x2 speed pill
	{ "Money", "Bottom" }, -- money counter + speed ribbons (and the cash shoe)
	{ "GameResetTimer", "TimeLeft" }, -- night / day timer
	{ "GameResetTimer", "EndingSoon" },
	{ "Hud", "LeftHUD" },
	{ "Hud", "RightHUD" },
	{ "Hud", "MoneyFrame" },
	{ "ShiftLockButton", "ImageButton" },
}
-- side panels without a TabController window: ScreenGui -> panel frame
MenuMotionController.POP_PANELS = { GrowingEggList = "Frame", PetList = "Frame" }
MenuMotionController.HIDE_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In)
MenuMotionController.SHOW_INFO = TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
MenuMotionController.POP_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
MenuMotionController.POP_SLIDE = 70 -- px the panel travels in from the right
MenuMotionController.POP_SCALE = 0.9
MenuMotionController.AWAY_SCALE = 1.25 -- screens a hidden group travels past its edge

local BASE_ATTRIBUTE = "SpHudRestPosition"

local playerGui = nil
local TabController = nil
local hudHidden = false
local groupTweens = setmetatable({}, { __mode = "k" }) -- [GuiObject] = Tween

-- Which screen edge a group leaves by: the nearest one, preferring bottom / top for groups that hug them.
local function edgeOf(object)
	local position, anchor = object.Position, object.AnchorPoint
	local y = position.Y.Scale + (0.5 - anchor.Y) * object.Size.Y.Scale
	local x = position.X.Scale + (0.5 - anchor.X) * object.Size.X.Scale
	if y >= 0.8 then
		return "bottom"
	elseif y <= 0.2 then
		return "top"
	elseif x <= 0.5 then
		return "left"
	end
	return "right"
end
MenuMotionController._edgeOf = edgeOf

-- A whole screen past the edge (the groups are children of their ScreenGui, so a Position scale of 1 is one screen):
-- their content spills far outside their own boxes (the money rows and the "+$" column sit above Money.Bottom, the
-- night warning's text runs past EndingSoon), so moving them by their box size left them half on screen (owner
-- 2026-09-27: "it does not hide properly when you open another menu").
local function awayOffset(_object, edge)
	local away = MenuMotionController.AWAY_SCALE
	if edge == "bottom" then
		return UDim2.fromScale(0, away)
	elseif edge == "top" then
		return UDim2.fromScale(0, -away)
	elseif edge == "left" then
		return UDim2.fromScale(-away, 0)
	end
	return UDim2.fromScale(away, 0)
end

local function groupObject(entry)
	local gui = playerGui and playerGui:FindFirstChild(entry[1])
	local object = gui and gui:FindFirstChild(entry[2])
	if object and object:IsA("GuiObject") then
		return object
	end
	return nil
end

local function play(object, info, goal)
	local previous = groupTweens[object]
	if previous then
		previous:Cancel()
	end
	local tween = TweenService:Create(object, info, goal)
	groupTweens[object] = tween
	tween:Play()
	return tween
end

local function setHudHidden(hidden)
	if hidden == hudHidden then
		return
	end
	hudHidden = hidden
	for _, entry in ipairs(MenuMotionController.HUD_GROUPS) do
		local object = groupObject(entry)
		if object then
			local rest = object:GetAttribute(BASE_ATTRIBUTE)
			if hidden then
				if typeof(rest) ~= "UDim2" then
					rest = object.Position
					object:SetAttribute(BASE_ATTRIBUTE, rest)
				end
				play(object, MenuMotionController.HIDE_INFO, { Position = rest + awayOffset(object, edgeOf(object)) })
			elseif typeof(rest) == "UDim2" then
				local tween = play(object, MenuMotionController.SHOW_INFO, { Position = rest })
				tween.Completed:Once(function(state)
					if state == Enum.PlaybackState.Completed and not hudHidden then
						object:SetAttribute(BASE_ATTRIBUTE, nil)
					end
				end)
			end
		end
	end
end

local function anyMenuOpen()
	if TabController then
		local ok, open = pcall(TabController.IsOpen)
		if ok and open then
			return true
		end
	end
	for name in pairs(MenuMotionController.POP_PANELS) do
		local gui = playerGui and playerGui:FindFirstChild(name)
		if gui and gui:IsA("ScreenGui") and gui.Enabled then
			return true
		end
	end
	return false
end

local refreshQueued = false
local function refresh()
	if refreshQueued then
		return
	end
	refreshQueued = true
	task.defer(function()
		refreshQueued = false
		setHudHidden(anyMenuOpen())
	end)
end
MenuMotionController._refresh = refresh

local function popIn(gui)
	local panel = gui:FindFirstChild(MenuMotionController.POP_PANELS[gui.Name])
	if not (panel and panel:IsA("GuiObject")) then
		return
	end
	local rest = panel:GetAttribute(BASE_ATTRIBUTE)
	if typeof(rest) ~= "UDim2" then
		rest = panel.Position
		panel:SetAttribute(BASE_ATTRIBUTE, rest)
	end
	local scale = panel:FindFirstChild("SpOpenScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "SpOpenScale"
		scale.Parent = panel
	end
	panel.Position = rest + UDim2.fromOffset(MenuMotionController.POP_SLIDE, 0)
	scale.Scale = MenuMotionController.POP_SCALE
	play(panel, MenuMotionController.POP_INFO, { Position = rest })
	TweenService:Create(scale, MenuMotionController.POP_INFO, { Scale = 1 }):Play()
end

local watchedPanels = setmetatable({}, { __mode = "k" })
local function watchPanel(gui)
	if watchedPanels[gui] or not gui:IsA("ScreenGui") or MenuMotionController.POP_PANELS[gui.Name] == nil then
		return
	end
	watchedPanels[gui] = true
	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if gui.Enabled then
			popIn(gui)
		end
		refresh()
	end)
end

function MenuMotionController:Start()
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local ok, controller = pcall(require, ReplicatedStorage.Library.Client.TabController)
	if ok and type(controller) == "table" then
		TabController = controller
		pcall(TabController.AddOpenListener, refresh)
		pcall(TabController.AddCloseListener, refresh)
	else
		warn("[MenuMotionController] TabController unavailable: " .. tostring(controller))
	end
	for _, gui in ipairs(playerGui:GetChildren()) do
		watchPanel(gui)
	end
	playerGui.ChildAdded:Connect(function(gui)
		watchPanel(gui)
		-- a group recreated on respawn (ShiftLockButton resets) comes back where it was authored
		if hudHidden then
			task.defer(function()
				hudHidden = false
				setHudHidden(anyMenuOpen())
			end)
		end
	end)
	refresh()
end

-- Test hooks
function MenuMotionController.IsHudHidden()
	return hudHidden
end

return MenuMotionController
