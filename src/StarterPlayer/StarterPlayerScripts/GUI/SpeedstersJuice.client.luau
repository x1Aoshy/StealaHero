-- SpeedstersJuice (LocalScript, StarterPlayer.StarterPlayerScripts.GUI; injected by scripts/inject/ui_hud.luau)
-- Speedsters Escape HUD animation layer for the Steal a Hero HUD (CONTRACTS_PHASE3 D4). The tween numbers are
-- Speedsters' own (Update2 MainHUDController.client.luau: icon hover :447-505, attention bounce :990-1028 and
-- :1406-1435, badge shake :1031-1060, Shine rotation :1393-1403, value pulse :245-271; TopbarIconsController).
--
-- Targets are marked at build time by scripts/steps/ui_30_hud.luau:
--   GuiButton  SpHover (tilt degrees) + SpHoverTarget (child name: the icon, or the label when there is no icon)
--   GuiButton  SpBounce (seconds between attention bounces) + SpBounceOffset (seconds before the first)
--   GuiObject  SpShake = true  (a "!" badge: shakes +5 px while it is Visible)
--   TextLabel  SpPulse = true  (pulses when its Text changes: the money counter)
--   ImageLabel named SpShine    (premium rays: 45 deg/s while shown)
-- Coexistence rules: ButtonFX owns every button's UIScale and HideImportantUI owns Enabled/Visible, so this script
-- never writes a button's UIScale, Enabled or Visible. It only tweens Rotation of icons/labels, a UIScale it creates
-- on non-button icons/labels (SpBounceScale, SpPulseScale), badge Position and SpShine Rotation.
-- Cost: one Heartbeat (SpShine only), tweens created once per target and replayed, no per-frame allocations.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
if not PlayerGui then
	return
end

local HOVER_IN = TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HOVER_OUT = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local BOUNCE_IN = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local BOUNCE_MID = TweenInfo.new(0.10, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local BOUNCE_OUT = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BOUNCE_SCALE = 1.22
local BOUNCE_ROTATION = 5

local SHAKE_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
local SHAKE_OFFSET = UDim2.fromOffset(5, 0)

local SHINE_DEGREES_PER_SECOND = 45

local PULSE_UP = TweenInfo.new(0.07, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local PULSE_DOWN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PULSE_SCALE = 1.18
local PULSE_COOLDOWN = 0.25 -- MoneyUpdate counts the label up frame by frame: one pulse per burst, not per frame

-- Speedsters topbar art (TopbarIconsController.client.luau:11-24): TopbarPlus v3 icons already created by SAH
-- (Settings LocalScript, BackpackController.Main) get the Speedsters images and image scale.
local TOPBAR_SETTINGS_OLD = "rbxassetid://101403250204482"
local TOPBAR_SETTINGS = "rbxassetid://77188882273275"
local TOPBAR_BACKPACK = "rbxassetid://139874655682754"
local TOPBAR_BACKPACK_NAME = "InventoryIcon"
local TOPBAR_IMAGE_SCALE = 0.85
local TOPBAR_DISPLAY_ORDER = 10 -- TopbarPlus's own Icon.baseDisplayOrder default
local TOPBAR_AUDIT_DELAYS = { 15, 60 } -- seconds after join

local HUD_GUIS = { "Elements", "Money", "Hud" }

local bound = setmetatable({}, { __mode = "k" })
local targetState = setmetatable({}, { __mode = "k" })
local shines = {}

-- True when `inst` and every GuiObject ancestor are Visible and its LayerCollector is Enabled.
local function isShown(inst: Instance): boolean
	local node: Instance? = inst
	while node do
		if node:IsA("GuiObject") then
			if not node.Visible then
				return false
			end
		elseif node:IsA("LayerCollector") then
			return node.Enabled
		else
			return false
		end
		node = node.Parent
	end
	return false
end

local function stateOf(target: Instance)
	local state = targetState[target]
	if not state then
		state = { hovered = false }
		targetState[target] = state
	end
	return state
end

local function hoverTarget(button: Instance): GuiObject?
	local name = button:GetAttribute("SpHoverTarget")
	if type(name) ~= "string" then
		return nil
	end
	local target = button:FindFirstChild(name) or button:FindFirstChild(name, true)
	if target and target:IsA("GuiObject") then
		return target
	end
	return nil
end

-- Icon tilt on hover / touch / gamepad selection (ButtonFX keeps scaling the button itself).
local function bindHover(button: GuiButton)
	local degrees = button:GetAttribute("SpHover")
	local target = hoverTarget(button)
	if type(degrees) ~= "number" or not target then
		return
	end
	local state = stateOf(target)
	local tweenIn = TweenService:Create(target, HOVER_IN, { Rotation = degrees })
	local tweenOut = TweenService:Create(target, HOVER_OUT, { Rotation = 0 })
	local function setHovered(on: boolean)
		if state.hovered == on then
			return
		end
		state.hovered = on
		if on then
			tweenIn:Play()
		else
			tweenOut:Play()
		end
	end
	button.MouseEnter:Connect(function()
		setHovered(true)
	end)
	button.MouseLeave:Connect(function()
		setHovered(false)
	end)
	button.SelectionGained:Connect(function()
		setHovered(true)
	end)
	button.SelectionLost:Connect(function()
		setHovered(false)
	end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			setHovered(true)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			setHovered(false)
		end
	end)
	-- a button hidden while hovered (its own Visible, or HideImportantUI disabling the ScreenGui) never gets
	-- MouseLeave: settle it
	button:GetPropertyChangedSignal("Visible"):Connect(function()
		setHovered(false)
	end)
	local gui = button:FindFirstAncestorWhichIsA("LayerCollector")
	if gui then
		gui:GetPropertyChangedSignal("Enabled"):Connect(function()
			setHovered(false)
		end)
	end
end

-- Attention bounce (Shop every 6 s, premium every 7 s): scale via a UIScale on the icon (never on the button) plus
-- the same icon Rotation the hover uses; skipped while hovered or hidden, cut short when a hover starts.
local function bindBounce(button: GuiButton)
	local interval = button:GetAttribute("SpBounce")
	local offset = button:GetAttribute("SpBounceOffset")
	local target = hoverTarget(button)
	if type(interval) ~= "number" or interval <= 0 or not target then
		return
	end
	local state = stateOf(target)
	local scale = target:FindFirstChild("SpBounceScale")
	if not (scale and scale:IsA("UIScale")) then
		scale = Instance.new("UIScale")
		scale.Name = "SpBounceScale"
		scale.Parent = target
	end
	local steps = {
		{ TweenService:Create(scale, BOUNCE_IN, { Scale = BOUNCE_SCALE }), TweenService:Create(target, BOUNCE_IN, { Rotation = BOUNCE_ROTATION }) },
		{ TweenService:Create(scale, BOUNCE_MID, { Scale = BOUNCE_SCALE * 0.97 }), TweenService:Create(target, BOUNCE_MID, { Rotation = -BOUNCE_ROTATION }) },
		{ TweenService:Create(scale, BOUNCE_OUT, { Scale = 1 }), TweenService:Create(target, BOUNCE_OUT, { Rotation = 0 }) },
	}
	local settle = TweenService:Create(scale, HOVER_OUT, { Scale = 1 })
	task.spawn(function()
		task.wait(if type(offset) == "number" then offset else 0)
		while target.Parent and button.Parent do
			task.wait(interval)
			if not state.hovered and isShown(button) then
				for _, step in ipairs(steps) do
					if state.hovered then
						break
					end
					step[1]:Play()
					step[2]:Play()
					step[1].Completed:Wait()
				end
				if state.hovered then
					settle:Play()
				end
			end
		end
	end)
end

-- "!" badge shake: base -> base + 5 px, 0.12 s Linear, reversing, while the badge is Visible (scripts own Visible).
local function bindShake(badge: GuiObject)
	local base = badge.Position
	local tween = TweenService:Create(badge, SHAKE_INFO, { Position = base + SHAKE_OFFSET })
	local function sync()
		if badge.Visible then
			tween:Play()
		else
			tween:Cancel()
			badge.Position = base
		end
	end
	badge:GetPropertyChangedSignal("Visible"):Connect(sync)
	sync()
end

-- Value pulse on Text change: UIScale 1 -> 1.18 (0.07 Back Out) -> 1 (0.12 Quad Out).
local function bindPulse(label: GuiObject)
	local scale = label:FindFirstChild("SpPulseScale")
	if not (scale and scale:IsA("UIScale")) then
		scale = Instance.new("UIScale")
		scale.Name = "SpPulseScale"
		scale.Parent = label
	end
	local up = TweenService:Create(scale, PULSE_UP, { Scale = PULSE_SCALE })
	local down = TweenService:Create(scale, PULSE_DOWN, { Scale = 1 })
	local busy = false
	local readyAt = 0
	up.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed then
			down:Play()
		else
			busy = false
		end
	end)
	down.Completed:Connect(function()
		busy = false
		readyAt = os.clock() + PULSE_COOLDOWN
	end)
	label:GetPropertyChangedSignal("Text"):Connect(function()
		if busy or os.clock() < readyAt then
			return
		end
		busy = true
		up:Play()
	end)
end

local function bindInstance(d: Instance)
	if bound[d] then
		return
	end
	if d:IsA("GuiButton") and d:GetAttribute("SpHover") ~= nil then
		bound[d] = true
		bindHover(d)
		if d:GetAttribute("SpBounce") ~= nil then
			bindBounce(d)
		end
	elseif d:IsA("GuiObject") and d:GetAttribute("SpShake") == true then
		bound[d] = true
		bindShake(d)
	elseif d:IsA("GuiObject") and d:GetAttribute("SpPulse") == true then
		bound[d] = true
		bindPulse(d)
	elseif d:IsA("ImageLabel") and d.Name == "SpShine" then
		bound[d] = true
		table.insert(shines, d)
	end
end

local function scanGui(gui: Instance)
	for _, d in ipairs(gui:GetDescendants()) do
		local ok, err = pcall(bindInstance, d)
		if not ok then
			warn("[SpeedstersJuice] " .. d:GetFullName() .. ": " .. tostring(err))
		end
	end
end

RunService.Heartbeat:Connect(function(dt)
	local count = #shines
	if count == 0 then
		return
	end
	local delta = dt * SHINE_DEGREES_PER_SECOND
	for i = 1, count do
		local shine = shines[i]
		if shine.Parent ~= nil and isShown(shine) then
			shine.Rotation = (shine.Rotation + delta) % 360
		end
	end
end)

for _, name in ipairs(HUD_GUIS) do
	task.spawn(function()
		local gui = PlayerGui:WaitForChild(name, 30)
		if gui then
			scanGui(gui)
		end
	end)
end

-- TopbarPlus v3 (SAH ships 3.2.5; Speedsters' v2 is not ported): swap the icon art of the icons SAH creates.
task.spawn(function()
	local library = ReplicatedStorage:WaitForChild("Library", 30)
	local modules = library and library:WaitForChild("Modules", 30)
	local packages = modules and modules:WaitForChild("Packages", 30)
	local module = packages and packages:WaitForChild("TopBarPlus", 30)
	if not (module and module:IsA("ModuleScript")) then
		return
	end
	local ok, Icon = pcall(require, module)
	if not ok or type(Icon) ~= "table" or type(Icon.getIcons) ~= "function" then
		return
	end

	-- TOPBAR (owner report 2026-09-23, backpack + gear icons gone): TopbarPlus 3.2.5 only copies
	-- Icon.baseDisplayOrder (10) onto its container ScreenGuis when setDisplayOrder fires, and nothing in SAH calls it,
	-- so TopbarStandard (both icons' container) sat at DisplayOrder 0, level with or under every HUD ScreenGui. Apply
	-- the library's own default so no HUD layer can paint over the icons (windows, DisplayOrder 11+, still cover them).
	pcall(function()
		if type(Icon.setDisplayOrder) == "function" then
			Icon.setDisplayOrder(if type(Icon.baseDisplayOrder) == "number" then Icon.baseDisplayOrder else TOPBAR_DISPLAY_ORDER)
		end
	end)

	local function currentImage(icon): string?
		local found, image = pcall(function()
			return icon:getInstance("IconImage")
		end)
		if found and typeof(image) == "Instance" and image:IsA("ImageLabel") then
			return image.Image
		end
		return nil
	end

	local function restyle(icon)
		if type(icon) ~= "table" then
			return
		end
		local image = currentImage(icon)
		local wanted = nil
		if icon.name == TOPBAR_BACKPACK_NAME then
			wanted = TOPBAR_BACKPACK
		elseif image == TOPBAR_SETTINGS_OLD then
			wanted = TOPBAR_SETTINGS
		end
		if wanted == nil or image == wanted then
			return
		end
		pcall(function()
			icon:setImage(wanted)
			icon:setImageScale(TOPBAR_IMAGE_SCALE)
			icon:setImageRatio(1)
		end)
	end

	local function restyleAll()
		local okIcons, icons = pcall(Icon.getIcons)
		if okIcons and type(icons) == "table" then
			for _, icon in pairs(icons) do
				restyle(icon)
			end
		end
	end

	if Icon.iconAdded and type(Icon.iconAdded.Connect) == "function" then
		pcall(function()
			Icon.iconAdded:Connect(function(icon)
				task.delay(1, restyle, icon)
			end)
		end)
	end
	-- the SAH scripts set their images asynchronously (TopbarPlus themes apply in a spawned task)
	for _, delaySeconds in ipairs({ 1, 3, 6, 12, 25 }) do
		task.delay(delaySeconds, restyleAll)
	end

	-- Topbar audit: one warn per distinct problem, so the next playtest log says exactly why an icon is not on screen
	-- (missing = its script never created it; enabled=false = its own rule hid it: the gear while HideUI is locked, i.e.
	-- carrying a stolen egg, the backpack while trapped / fuse-selecting; TopbarStandard off = the whole container).
	local hideUILock = nil
	pcall(function()
		hideUILock = require(ReplicatedStorage.Library.Variables).Locks.HideUI
	end)
	local lastReport = nil

	local function describe(icon): string
		if type(icon) ~= "table" then
			return "missing"
		end
		local widget = icon.widget
		local holder = typeof(widget) == "Instance" and widget.Parent
		return string.format("enabled=%s holder=%s image=%s", tostring(icon.isEnabled), holder and holder.Name or "nil", tostring(currentImage(icon)))
	end

	local function audit()
		local okIcons, icons = pcall(Icon.getIcons)
		if not okIcons or type(icons) ~= "table" then
			return
		end
		local inventory, gear, count = nil, nil, 0
		for _, icon in pairs(icons) do
			count += 1
			if type(icon) == "table" then
				if icon.name == TOPBAR_BACKPACK_NAME then
					inventory = icon
				elseif gear == nil and icon.name ~= "HeroAdminIcon" and icon.name ~= "Cmdr" then
					-- SAH creates two TopbarPlus icons: the InventoryIcon and the unnamed settings gear (the admin
					-- panel's HeroAdminIcon and the Cmdr icon only exist for admins)
					gear = icon
				end
			end
		end
		local container = PlayerGui:FindFirstChild("TopbarStandard")
		local containerShown = container ~= nil and container:IsA("LayerCollector") and container.Enabled
		if inventory and inventory.isEnabled and gear and gear.isEnabled and containerShown then
			lastReport = nil
			return
		end
		local report = string.format(
			"[SpeedstersJuice] topbar icons not all shown (%d icons): InventoryIcon %s | settings gear %s | TopbarStandard %s | HideUI locks %s",
			count,
			describe(inventory),
			describe(gear),
			if container and container:IsA("LayerCollector")
				then string.format("Enabled=%s DisplayOrder=%d", tostring(container.Enabled), container.DisplayOrder)
				else "missing",
			tostring(hideUILock and hideUILock._obtainedCount)
		)
		if report ~= lastReport then
			lastReport = report
			warn(report)
		end
	end

	for _, delaySeconds in ipairs(TOPBAR_AUDIT_DELAYS) do
		task.delay(delaySeconds, function()
			local okAudit, err = pcall(audit)
			if not okAudit then
				warn("[SpeedstersJuice] topbar audit failed: " .. tostring(err))
			end
		end)
	end
end)
