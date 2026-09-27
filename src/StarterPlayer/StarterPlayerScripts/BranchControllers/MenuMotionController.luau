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
-- Owner 2026-09-27 ("on the treadmill the effect that hides the UI goes crazy, the logic fights"): the PlayerGui
-- ChildAdded handler used to send EVERY group away again whenever anything at all was added to PlayerGui while a menu
-- was open. On the treadmill SpeedGainAnimation.ShowPlusOne parents a "+N" BillboardGui to PlayerGui on every speed step
-- (every 0.1-0.25 s, TreadmillUtil.ResolveWalkSpeedPowerAwardInterval), so opening the speed shop (or any menu) there
-- restarted the 0.22 s Back-In hide tween several times a second: Back easing starts by moving backwards, so the groups
-- crept back onto the screen and jittered instead of leaving. Now only a recreated HUD ScreenGui (respawn) is looked at,
-- and only its fresh groups are sent away; a group already away or already on its way is never re-tweened (moveTo).

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
local groupTweens = setmetatable({}, { __mode = "k" }) -- [GuiObject] = { tween = Tween, goal = UDim2 }

-- Which screen edge a group leaves by: the nearest one, preferring bottom / top for groups that hug them. `position`
-- (default: the current one) is the resting Position, so a group caught mid-slide still picks its own edge.
local function edgeOf(object, position)
	position = position or object.Position
	local anchor = object.AnchorPoint
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

local function isPlaying(tween)
	local state = tween.PlaybackState
	return state == Enum.PlaybackState.Playing or state == Enum.PlaybackState.Begin or state == Enum.PlaybackState.Delayed
end

-- Tweens `object`'s Position to `goal`, the only writer of it while the HUD moves. Idempotent: an object already at
-- `goal`, or already tweening there, is left alone (restarting a Back tween makes it jump backwards first). `restart`
-- replays anyway (the pop-in places its own start). Returns the new tween, or nil when nothing had to move.
local function moveTo(object, info, goal, restart)
	local current = groupTweens[object]
	local running = current ~= nil and isPlaying(current.tween)
	if not restart then
		if running and current.goal == goal then
			return nil
		end
		if not running and object.Position == goal then
			return nil
		end
	end
	if current then
		current.tween:Cancel()
	end
	local tween = TweenService:Create(object, info, { Position = goal })
	groupTweens[object] = { tween = tween, goal = goal }
	tween:Play()
	return tween
end
MenuMotionController._moveTo = moveTo

local function hideGroup(object)
	local rest = object:GetAttribute(BASE_ATTRIBUTE)
	if typeof(rest) ~= "UDim2" then
		rest = object.Position
		object:SetAttribute(BASE_ATTRIBUTE, rest)
	end
	moveTo(object, MenuMotionController.HIDE_INFO, rest + awayOffset(object, edgeOf(object, rest)))
end

local function showGroup(object)
	local rest = object:GetAttribute(BASE_ATTRIBUTE)
	if typeof(rest) ~= "UDim2" then
		return
	end
	local tween = moveTo(object, MenuMotionController.SHOW_INFO, rest)
	if tween then
		tween.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed and not hudHidden then
				object:SetAttribute(BASE_ATTRIBUTE, nil)
			end
		end)
	elseif object.Position == rest then
		object:SetAttribute(BASE_ATTRIBUTE, nil)
	end
end

local function setHudHidden(hidden)
	if hidden == hudHidden then
		return
	end
	hudHidden = hidden
	for _, entry in ipairs(MenuMotionController.HUD_GROUPS) do
		local object = groupObject(entry)
		if object then
			if hidden then
				hideGroup(object)
			else
				showGroup(object)
			end
		end
	end
end

-- A HUD ScreenGui added to PlayerGui (a ResetOnSpawn copy recreated on respawn, e.g. ShiftLockButton) while the HUD is
-- away: its fresh groups start at their authored place, so they are sent away too. The groups already away are not
-- touched.
local function isHudGui(child)
	if not child:IsA("ScreenGui") then
		return false
	end
	for _, entry in ipairs(MenuMotionController.HUD_GROUPS) do
		if entry[1] == child.Name then
			return true
		end
	end
	return false
end
MenuMotionController._isHudGui = isHudGui

local function hideAddedGroups(gui)
	if not hudHidden or gui.Parent ~= playerGui then
		return
	end
	for _, entry in ipairs(MenuMotionController.HUD_GROUPS) do
		if entry[1] == gui.Name then
			local object = gui:FindFirstChild(entry[2])
			if object and object:IsA("GuiObject") then
				hideGroup(object)
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
	moveTo(panel, MenuMotionController.POP_INFO, rest, true)
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
	playerGui.ChildAdded:Connect(function(child)
		watchPanel(child)
		-- Only a recreated HUD ScreenGui matters (see hideAddedGroups). Everything else parented to PlayerGui - the
		-- treadmill's "+N" speed billboards every step, notifications, prompts, popups - leaves the HUD alone.
		if hudHidden and isHudGui(child) then
			task.defer(hideAddedGroups, child)
		end
	end)
	refresh()
end

-- Test hooks
function MenuMotionController.IsHudHidden()
	return hudHidden
end

return MenuMotionController
