-- StarterPlayerScripts.Game.Plots.BaseWindowLights (LocalScript, injected by scripts/inject/gekko_windows.luau)
-- Base window lights (owner 2026-09-25, Spider-Verse base: "make the windows have those lights; in Roblox Studio we will
-- put that effect where one turns off, one turns on"). The build (scripts/steps/post_zz_base_themes.luau section 8)
-- gives a modelled base's buildings one flat pane Part per window ("ThemeWindowPane", SmoothPlastic, never Neon, no
-- lights) in the Model "ThemeWindows", tagged "BaseWindowLights" with its style as attributes (WindowLitColor,
-- WindowOffColor, WindowLitFraction, WindowMinGap, WindowMaxGap, WindowTween, WindowRange; an accent pane carries its
-- own LitColor). PlotService clones it into the plot's ThemeProps when the owner equips the theme.
-- Here, on each client, a city at night: every 2..12 s (per building group, random) one to three changes happen - a
-- lit window goes dark while a dark one lights up, or a single one switches to keep ~WindowLitFraction of them lit -
-- each a gentle 0.25 s colour tween. Only groups within WindowRange (~250) studs of the camera and only while the game
-- window has focus; ONE scheduler thread that sleeps until the next due change (at most IDLE_WAKE s to re-check a
-- paused group), parked while no group exists: no per-frame work, nothing for idle windows. A group is forgotten (its
-- tweens cancelled, its connections dropped) as soon as it leaves the Workspace (theme unequipped / plot freed).
-- Client-only colours: nothing is sent to the server.

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local TAG = "BaseWindowLights"
local PANE_NAME = "ThemeWindowPane"
local DEFAULTS = {
	lit = Color3.fromRGB(255, 204, 64),
	off = Color3.fromRGB(46, 56, 80),
	litFraction = 0.8,
	minGap = 2,
	maxGap = 12,
	tween = 0.25,
	range = 250,
}
local IDLE_WAKE = 1.5 -- seconds between two checks of a paused (far / unfocused) group
local MAX_CHANGES = 3 -- changes per event ("a few at a time")
local BAND = 0.08 -- lit fraction tolerance before a change only goes one way

local rng = Random.new()
local groups = {} -- [Model] = group
local focused = true
local parked = nil -- the scheduler thread while no group exists

local function number(model, name, default, lo, hi)
	local value = model:GetAttribute(name)
	if type(value) ~= "number" or value ~= value then
		return default
	end
	return math.clamp(value, lo, hi)
end

local function colour(instance, name, default)
	local value = instance:GetAttribute(name)
	return if typeof(value) == "Color3" then value else default
end

local function isPane(instance)
	return instance:IsA("BasePart") and instance.Name == PANE_NAME
end

local function litColourOf(group, part)
	return colour(part, "LitColor", group.litColour)
end

-- Switches one pane (tweened unless instant). Keeps the lit count.
local function setPane(group, part, on, instant)
	if part == nil or group.lit[part] == nil or group.lit[part] == on then
		return
	end
	group.lit[part] = on
	group.litCount += if on then 1 else -1
	local target = if on then litColourOf(group, part) else group.offColour
	local running = group.tweens[part]
	if running then
		running:Cancel()
		group.tweens[part] = nil
	end
	if instant then
		part.Color = target
		return
	end
	local tween = TweenService:Create(part, group.tweenInfo, { Color = target })
	group.tweens[part] = tween
	tween.Completed:Once(function()
		if group.tweens[part] == tween then
			group.tweens[part] = nil
		end
	end)
	tween:Play()
	group.changes += 1
end

-- A random pane that is lit (wantLit) or dark; nil when there is none.
local function pick(group, wantLit)
	local panes = group.panes
	local n = #panes
	if n == 0 or (wantLit and group.litCount == 0) or (not wantLit and group.litCount == n) then
		return nil
	end
	for _ = 1, 8 do
		local part = panes[rng:NextInteger(1, n)]
		if group.lit[part] == wantLit then
			return part
		end
	end
	local start = rng:NextInteger(1, n)
	for k = 0, n - 1 do
		local part = panes[(start + k - 1) % n + 1]
		if group.lit[part] == wantLit then
			return part
		end
	end
	return nil
end

-- One event: one to three changes, mostly "one goes dark, another lights up", sometimes a single one (the lit share
-- drifts inside WindowLitFraction +- BAND).
local function flicker(group)
	local n = #group.panes
	if n == 0 then
		return
	end
	for _ = 1, rng:NextInteger(1, math.min(MAX_CHANGES, n)) do
		local fraction = group.litCount / n
		local roll = rng:NextNumber()
		if group.litCount == n or fraction > group.fraction + BAND or (roll < 0.2 and fraction - 1 / n >= group.fraction - BAND) then
			setPane(group, pick(group, true), false)
		elseif fraction < group.fraction - BAND or (roll < 0.4 and fraction + 1 / n <= group.fraction + BAND) then
			setPane(group, pick(group, false), true)
		else
			local dark, light = pick(group, true), pick(group, false)
			setPane(group, dark, false)
			setPane(group, light, true)
		end
	end
	group.events += 1
end

local function addPane(group, part)
	if group.lit[part] ~= nil then
		return
	end
	table.insert(group.panes, part)
	group.lit[part] = true -- the build makes every pane lit
	group.litCount += 1
	-- a new pane starts dark with the group's odds (a lived-in block from the first frame)
	if rng:NextNumber() > group.fraction then
		setPane(group, part, false, true)
	end
end

local function removePane(group, part)
	if group.lit[part] == nil then
		return
	end
	local running = group.tweens[part]
	if running then
		running:Cancel()
	end
	group.tweens[part] = nil
	if group.lit[part] then
		group.litCount -= 1
	end
	group.lit[part] = nil
	local index = table.find(group.panes, part)
	if index then
		group.panes[index] = group.panes[#group.panes]
		group.panes[#group.panes] = nil
	end
end

local function centreOf(model, panes)
	local ok, pivot = pcall(function()
		return model:GetPivot()
	end)
	if ok and pivot then
		return pivot.Position
	end
	local sum = Vector3.new(0, 0, 0)
	for _, part in ipairs(panes) do
		sum += part.Position
	end
	return if #panes > 0 then sum / #panes else Vector3.new(0, 0, 0)
end

local untrack

local function track(model)
	if groups[model] or not model:IsA("Model") or not model:IsDescendantOf(Workspace) then
		return
	end
	local group = {
		model = model,
		panes = {},
		lit = {},
		litCount = 0,
		tweens = {},
		connections = {},
		litColour = colour(model, "WindowLitColor", DEFAULTS.lit),
		offColour = colour(model, "WindowOffColor", DEFAULTS.off),
		fraction = number(model, "WindowLitFraction", DEFAULTS.litFraction, 0, 1),
		minGap = number(model, "WindowMinGap", DEFAULTS.minGap, 0.5, 600),
		range = number(model, "WindowRange", DEFAULTS.range, 10, 5000),
		events = 0,
		changes = 0,
	}
	group.maxGap = math.max(group.minGap, number(model, "WindowMaxGap", DEFAULTS.maxGap, 0.5, 600))
	group.tweenInfo = TweenInfo.new(number(model, "WindowTween", DEFAULTS.tween, 0, 5), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	groups[model] = group
	for _, d in ipairs(model:GetDescendants()) do
		if isPane(d) then
			addPane(group, d)
		end
	end
	group.centre = centreOf(model, group.panes)
	group.nextAt = os.clock() + rng:NextNumber(group.minGap, group.maxGap)
	table.insert(group.connections, model.DescendantAdded:Connect(function(d)
		if isPane(d) then
			addPane(group, d)
		end
	end))
	table.insert(group.connections, model.DescendantRemoving:Connect(function(d)
		removePane(group, d)
	end))
	table.insert(group.connections, model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(Workspace) then
			untrack(model)
		end
	end))
	if parked then
		local thread = parked
		parked = nil
		task.spawn(thread)
	end
end

function untrack(model)
	local group = groups[model]
	if group == nil then
		return
	end
	groups[model] = nil
	for _, connection in ipairs(group.connections) do
		connection:Disconnect()
	end
	for _, tween in pairs(group.tweens) do
		tween:Cancel()
	end
	table.clear(group.tweens)
	table.clear(group.panes)
	table.clear(group.lit)
end

-- The scheduler: runs every due group that is near the camera and visible, then sleeps until the next due time.
local function run()
	while true do
		if next(groups) == nil then
			parked = coroutine.running()
			coroutine.yield()
		end
		local now = os.clock()
		local camera = Workspace.CurrentCamera
		local eye = camera and camera.CFrame.Position
		local sleep = IDLE_WAKE
		for model, group in pairs(groups) do
			if now + 0.02 >= group.nextAt then -- (a wake-up a hair early still counts)
				if model.Parent == nil or not model:IsDescendantOf(Workspace) then
					untrack(model)
					continue
				end
				if focused and eye and (group.centre - eye).Magnitude <= group.range then
					flicker(group)
					group.nextAt = now + rng:NextNumber(group.minGap, group.maxGap)
				else
					-- paused (far from the camera / the window hidden): re-check on the shared IDLE_WAKE tick, so any
					-- number of paused groups costs one wake-up per tick
					group.nextAt = (math.floor(now / IDLE_WAKE + 1e-3) + 1) * IDLE_WAKE
				end
			end
			sleep = math.min(sleep, math.max(0.05, group.nextAt - now))
		end
		task.wait(sleep)
	end
end

UserInputService.WindowFocusReleased:Connect(function()
	focused = false
end)
UserInputService.WindowFocused:Connect(function()
	focused = true
end)
CollectionService:GetInstanceAddedSignal(TAG):Connect(track)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(model)
	untrack(model)
end)
for _, model in ipairs(CollectionService:GetTagged(TAG)) do
	track(model)
end
task.spawn(run)
