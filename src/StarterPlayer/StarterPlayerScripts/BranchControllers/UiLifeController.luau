-- StarterPlayer.StarterPlayerScripts.BranchControllers.UiLifeController (Branch controller; injected by
-- scripts/inject/branch.luau, started by StarterPlayerScripts.BranchClient)
-- Owner 2026-09-27: "make most of the UI alive, animations, something that pulses or moves so it feels animated like the
-- Speedsters ones". Idle life for the HUD and the windows, driven by attributes the build sets (scripts/steps/ui_30_hud
-- .luau) plus a few elements recognised by name:
--   SpBreathe = period (s)   a slow scale pulse (UIScale "SpLifeScale" 1 <-> 1 + SpBreatheAmp, default 0.05)
--   SpBob = pixels            a slow float up and down (SpBobPeriod s, default 2.4)
--   SpSweep = period (s)      a light band sweeping across the button every period (SpSweepDelay s offsets the first)
--   SpTwinkle = true          a frame that twinkles (BackgroundTransparency flicker at a random rate)
--   by name: ClaimButton / ClaimAllButton / Claim / ClaimAll / Buy / Purchase buttons sweep every 4 s; count badges
--            (NotificationBadge / ReadyNotification / Notification / Badge) breathe quickly while shown.
-- Cost rules: breathe / bob / twinkle are looping engine tweens (no Lua per frame); sweeps share one 0.2 s scheduler and
-- only run for visible elements; TopbarPlus GUIs are never touched; an element owning another UIScale is not breathed
-- (ButtonFX and SpeedstersJuice own theirs).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UiLifeController = {}

local DEFAULT_BREATHE_AMP = 0.05
local DEFAULT_BOB_PERIOD = 2.4
local SWEEP_TIME = 0.75
local SWEEP_SCHEDULER = 0.2
local BADGE_NAMES = { NotificationBadge = true, ReadyNotification = true, Notification = true, Badge = true }
local SWEEP_NAMES = { ClaimButton = 4, ClaimAllButton = 4, Claim = 4, ClaimAll = 4, Buy = 5, Purchase = 5 }

local bound = setmetatable({}, { __mode = "k" }) -- [GuiObject] = true
local sweeps = {} -- { { gui, period, nextAt, gradient } }

local function isTopbar(inst)
	local node = inst
	while node ~= nil do
		if node:IsA("ScreenGui") then
			return string.sub(node.Name, 1, 6) == "Topbar"
		end
		node = node.Parent
	end
	return false
end

local function shown(gui)
	local node = gui
	while node ~= nil do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		elseif node:IsA("LayerCollector") then
			return node.Enabled
		end
		node = node.Parent
	end
	return false
end

local function loop(instance, info, goal)
	local tween = TweenService:Create(instance, info, goal)
	tween:Play()
	return tween
end

local function breathe(gui, period, amp)
	for _, c in ipairs(gui:GetChildren()) do
		if c:IsA("UIScale") and c.Name ~= "SpLifeScale" then
			return -- someone else scales it (ButtonFX / SpeedstersJuice)
		end
	end
	local scale = gui:FindFirstChild("SpLifeScale") or Instance.new("UIScale")
	scale.Name = "SpLifeScale"
	scale.Scale = 1
	scale.Parent = gui
	loop(scale, TweenInfo.new(period / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, math.random() * period / 2),
		{ Scale = 1 + amp })
end

local function bob(gui, pixels, period)
	local base = gui.Position
	loop(gui, TweenInfo.new(period / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, math.random() * period / 2),
		{ Position = base - UDim2.fromOffset(0, pixels) })
end

local function twinkle(gui)
	local base = gui.BackgroundTransparency
	loop(gui, TweenInfo.new(0.5 + math.random() * 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, math.random() * 1.2),
		{ BackgroundTransparency = math.min(1, base + 0.75) })
end

local function addSweep(gui, period, delay)
	if gui:FindFirstChild("SpSweepShine") then
		return
	end
	local shine = Instance.new("Frame")
	shine.Name = "SpSweepShine"
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0
	shine.BorderSizePixel = 0
	shine.Size = UDim2.fromScale(1, 1)
	shine.Position = UDim2.fromScale(0, 0)
	shine.Active = false
	shine.Selectable = false
	shine.ZIndex = gui.ZIndex + 6
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 20
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Offset = Vector2.new(-1, 0)
	gradient.Parent = shine
	shine.Parent = gui
	table.insert(sweeps, { gui = gui, period = period, nextAt = os.clock() + (delay or math.random() * period), gradient = gradient })
end

local function bind(gui)
	if bound[gui] or not gui:IsA("GuiObject") or isTopbar(gui) then
		return
	end
	local breathePeriod = gui:GetAttribute("SpBreathe")
	local bobPixels = gui:GetAttribute("SpBob")
	local sweepPeriod = gui:GetAttribute("SpSweep")
	local twinkles = gui:GetAttribute("SpTwinkle") == true
	if sweepPeriod == nil and gui:IsA("GuiButton") and SWEEP_NAMES[gui.Name] then
		sweepPeriod = SWEEP_NAMES[gui.Name]
	end
	if breathePeriod == nil and BADGE_NAMES[gui.Name] and (gui:IsA("Frame") or gui:IsA("ImageLabel")) then
		breathePeriod = 0.9
		gui:SetAttribute("SpBreatheAmp", gui:GetAttribute("SpBreatheAmp") or 0.12)
	end
	if not (breathePeriod or bobPixels or sweepPeriod or twinkles) then
		return
	end
	bound[gui] = true
	if type(breathePeriod) == "number" and breathePeriod > 0 then
		breathe(gui, breathePeriod, tonumber(gui:GetAttribute("SpBreatheAmp")) or DEFAULT_BREATHE_AMP)
	end
	if type(bobPixels) == "number" and bobPixels ~= 0 then
		bob(gui, bobPixels, tonumber(gui:GetAttribute("SpBobPeriod")) or DEFAULT_BOB_PERIOD)
	end
	if type(sweepPeriod) == "number" and sweepPeriod > 0 then
		addSweep(gui, sweepPeriod, tonumber(gui:GetAttribute("SpSweepDelay")))
	end
	if twinkles and gui:IsA("Frame") then
		twinkle(gui)
	end
end

local function watch(root)
	for _, d in ipairs(root:GetDescendants()) do
		bind(d)
	end
	root.DescendantAdded:Connect(function(d)
		task.defer(bind, d)
	end)
end

function UiLifeController:Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	watch(playerGui)
	task.spawn(function()
		while true do
			task.wait(SWEEP_SCHEDULER)
			local now = os.clock()
			for i = #sweeps, 1, -1 do
				local sweep = sweeps[i]
				if sweep.gui.Parent == nil then
					table.remove(sweeps, i)
				elseif now >= sweep.nextAt then
					sweep.nextAt = now + sweep.period
					if shown(sweep.gui) then
						sweep.gradient.Offset = Vector2.new(-1, 0)
						TweenService:Create(sweep.gradient, TweenInfo.new(SWEEP_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
							{ Offset = Vector2.new(1, 0) }):Play()
					end
				end
			end
		end
	end)
end

return UiLifeController
