-- ReplicatedStorage.Library.Client.SpeedstersWindowJuice
-- Speedsters Escape "ModalJuice" feel for Steal a Hero windows (UI port phase 3, owner UI-WINDOWS; CONTRACTS_PHASE3 D4).
-- Required by Library.Client.TabController (optional: the controller works without it).
--   * AttachClose(button): close-button hover/press juice, ModalJuice values (hover -8 deg in 0.18 Back Out, leave
--     0 deg in 0.15 Quad Out, press -4 deg in 0.08 Quad Out). Only Rotation is animated: the button's scale belongs to
--     ButtonFX (its ButtonUIScale), and no UIScale is ever added to a button (D2).
--   * OnOpen(screenGui, root) / OnClose(screenGui): the header icon (the descendant of the window root carrying the
--     attribute SpHeaderIcon = true, placed by the build step ui_20_windows) bounces every 4.5-7.0 s while the window
--     is open: 1.22 / +6 deg (0.14 Back Out) -> 1.16 / -6 deg (0.10 Back Out) -> 1 / 0 deg (0.22 Quad Out). The icon
--     is an ImageLabel; the bounce scales its Size around its AnchorPoint instead of adding a UIScale.
--   * WatchDrawers(): the right-docked drawers PetList and GrowingEggList are toggled by their own controllers
--     (ScreenGui.Enabled); they get the same close juice and header bounce.
-- No per-frame work: every animation is a TweenService tween started by an input event or by the bounce timer.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Juice = {}

local CLOSE_HOVER_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_LEAVE_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_PRESS_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_HOVER_ROTATION = -8
local CLOSE_PRESS_ROTATION = -4

local HEADER_ATTRIBUTE = "SpHeaderIcon"
local BOUNCE_EVERY_MIN = 4.5
local BOUNCE_EVERY_MAX = 7.0
local BOUNCE_STEPS = {
	{ info = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), scale = 1.22, rotation = 6 },
	{ info = TweenInfo.new(0.10, Enum.EasingStyle.Back, Enum.EasingDirection.Out), scale = 1.16, rotation = -6 },
	{ info = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), scale = 1, rotation = 0 },
}

local DRAWER_NAMES = { "PetList", "GrowingEggList" }

local PRESS_INPUTS = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
}

local random = Random.new()
local activeBounces: { [Instance]: { icon: GuiObject } } = {}
local iconBase: { [Instance]: { size: UDim2, rotation: number } } = setmetatable({}, { __mode = "k" }) :: any
local headerIconCache: { [Instance]: GuiObject | false } = setmetatable({}, { __mode = "k" }) :: any

local function isPress(input: InputObject): boolean
	return PRESS_INPUTS[input.UserInputType] == true or input.KeyCode == Enum.KeyCode.ButtonA
end

function Juice.AttachClose(button: Instance)
	if typeof(button) ~= "Instance" or not button:IsA("GuiButton") then
		return
	end
	if button:GetAttribute("SpCloseJuice") == true then
		return
	end
	button:SetAttribute("SpCloseJuice", true)

	local baseRotation = button.Rotation
	local hovered = false
	local pressed = false

	local function refresh()
		local info, rotation
		if pressed then
			info, rotation = CLOSE_PRESS_INFO, CLOSE_PRESS_ROTATION
		elseif hovered then
			info, rotation = CLOSE_HOVER_INFO, CLOSE_HOVER_ROTATION
		else
			info, rotation = CLOSE_LEAVE_INFO, 0
		end
		TweenService:Create(button, info, { Rotation = baseRotation + rotation }):Play()
	end

	button.MouseEnter:Connect(function()
		hovered = true
		refresh()
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		pressed = false
		refresh()
	end)
	button.SelectionGained:Connect(function()
		hovered = true
		refresh()
	end)
	button.SelectionLost:Connect(function()
		hovered = false
		pressed = false
		refresh()
	end)
	button.InputBegan:Connect(function(input)
		if isPress(input) then
			pressed = true
			refresh()
		end
	end)
	button.InputEnded:Connect(function(input)
		if isPress(input) then
			pressed = false
			-- touch has no hover: settle back to rest
			if input.UserInputType == Enum.UserInputType.Touch then
				hovered = false
			end
			refresh()
		end
	end)
end

local function findHeaderIcon(root: Instance): GuiObject?
	local cached = headerIconCache[root]
	if cached ~= nil then
		if cached and cached.Parent ~= nil then
			return cached
		end
		if cached == false then
			return nil
		end
	end
	local found: GuiObject? = nil
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("GuiObject") and descendant:GetAttribute(HEADER_ATTRIBUTE) == true then
			found = descendant
			break
		end
	end
	headerIconCache[root] = found or false
	return found
end

local function scaled(size: UDim2, factor: number): UDim2
	return UDim2.new(size.X.Scale * factor, size.X.Offset * factor, size.Y.Scale * factor, size.Y.Offset * factor)
end

local function bounce(icon: GuiObject)
	local base = iconBase[icon]
	if base == nil then
		base = { size = icon.Size, rotation = icon.Rotation }
		iconBase[icon] = base
	end
	for _, step in BOUNCE_STEPS do
		if icon.Parent == nil then
			return
		end
		local tween = TweenService:Create(icon, step.info, {
			Size = scaled(base.size, step.scale),
			Rotation = base.rotation + step.rotation,
		})
		tween:Play()
		tween.Completed:Wait()
	end
	if icon.Parent ~= nil then
		icon.Size = base.size
		icon.Rotation = base.rotation
	end
end

function Juice.OnOpen(screenGui: Instance, root: Instance)
	if typeof(screenGui) ~= "Instance" or typeof(root) ~= "Instance" then
		return
	end
	local icon = findHeaderIcon(root)
	if icon == nil then
		activeBounces[screenGui] = nil
		return
	end
	local state = { icon = icon }
	activeBounces[screenGui] = state
	task.spawn(function()
		while activeBounces[screenGui] == state do
			task.wait(BOUNCE_EVERY_MIN + random:NextNumber() * (BOUNCE_EVERY_MAX - BOUNCE_EVERY_MIN))
			if activeBounces[screenGui] ~= state or icon.Parent == nil then
				break
			end
			local enabled = true
			if screenGui:IsA("LayerCollector") then
				enabled = (screenGui :: LayerCollector).Enabled
			end
			if enabled and icon.Visible then
				bounce(icon)
			end
		end
	end)
end

function Juice.OnClose(screenGui: Instance)
	activeBounces[screenGui] = nil
end

local function watchDrawer(screenGui: ScreenGui)
	if screenGui:GetAttribute("SpDrawerJuice") == true then
		return
	end
	screenGui:SetAttribute("SpDrawerJuice", true)
	local root = screenGui:FindFirstChildOfClass("Frame")
	if root == nil then
		return
	end
	local close = root:FindFirstChild("Close")
	if close and close:IsA("GuiButton") then
		Juice.AttachClose(close)
	end
	local function sync()
		if screenGui.Enabled then
			if activeBounces[screenGui] == nil then
				Juice.OnOpen(screenGui, root)
			end
		else
			Juice.OnClose(screenGui)
		end
	end
	screenGui:GetPropertyChangedSignal("Enabled"):Connect(sync)
	screenGui.AncestryChanged:Connect(function()
		if screenGui.Parent == nil then
			Juice.OnClose(screenGui)
		end
	end)
	sync()
end

local drawersWatched = false
function Juice.WatchDrawers()
	if drawersWatched then
		return
	end
	drawersWatched = true
	task.spawn(function()
		local player = Players.LocalPlayer
		if player == nil then
			return
		end
		local playerGui = player:WaitForChild("PlayerGui", 30)
		if playerGui == nil then
			return
		end
		local wanted = {}
		for _, name in DRAWER_NAMES do
			wanted[name] = true
		end
		local function consider(child: Instance)
			if wanted[child.Name] and child:IsA("ScreenGui") then
				-- the drawer's children are cloned in with it; defer one step so its Frame exists
				task.defer(watchDrawer, child)
			end
		end
		playerGui.ChildAdded:Connect(consider)
		for _, child in playerGui:GetChildren() do
			consider(child)
		end
	end)
end

return Juice
