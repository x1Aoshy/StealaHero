-- TreadmillTrainingHud (LocalScript, StarterPlayer.StarterPlayerScripts.GUI; injected by scripts/inject/treadmill.luau)
-- Training HUD while the local player runs on their treadmill (VISUAL_PASS_PLAN D4). The card itself
-- (StarterGui.TreadmillTrainingHud.Card: stud frame, gradient "+SPEED" counter, multiplier chip, milestone bar) is built
-- by scripts/steps/ui_60_treadmill.luau; this script only drives it.
--
-- Session signal: the game's own "Treadmills: ActiveTreadmillChanged" (TreadmillGrindService fires
-- (treadmillId, speedMultiplier, nextAwardAt, mediaFeedState) on entry and (nil) on exit; TreadmillUI and the
-- position lock listen to the same event). Gains: Library.Client.SpeedPowerProjection.Changed, the value TreadmillUI
-- reveals step by step during the session (and reconciles with the saved SpeedPower), so the counter moves exactly
-- with the speed counter of the HUD.
--   * top-centre card, 8 px under the top bar: the runner stands in the middle of the screen, so it never covers them;
--     sized from the viewport height (72-124 px tall);
--   * "+N SPEED" = SpeedPower gained this session, vibrant text gradient, pops on each gain (throttled) with a small
--     rising "+n" float every 0.35 s;
--   * multiplier chip = the Speed gained per step (treadmill multiplier x boosts, TreadmillUtil.ResolveSpeedPowerPerStep);
--   * bar = progress toward the next Speed milestone on the 1 / 2.5 / 5 x 10^k ladder (10, 25, 50, 100, 250 ...);
--     crossing one flashes the card title ("MILESTONE 1K!").
-- On exit the card shows the session total for a moment, then slides away.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LOG_PREFIX = "[TreadmillTrainingHud]"

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
if not PlayerGui then
	return
end

local gui = PlayerGui:WaitForChild("TreadmillTrainingHud", 60)
if not (gui and gui:IsA("ScreenGui")) then
	warn(LOG_PREFIX .. " StarterGui.TreadmillTrainingHud is missing: no training HUD.")
	return
end

local function find(root: Instance?, path: string): Instance?
	local node = root
	for _, segment in ipairs(string.split(path, "/")) do
		if node == nil then
			return nil
		end
		node = node:FindFirstChild(segment)
	end
	return node
end

local card = find(gui, "Card") :: Frame?
local titleLabel = find(card, "Inner/Title") :: TextLabel?
local gainLabel = find(card, "Inner/Gain") :: TextLabel?
local gainPop = find(gainLabel, "PopScale") :: UIScale?
local multiplierLabel = find(card, "Inner/Multiplier/Value") :: TextLabel?
local barFill = find(card, "Inner/Bar/Fill") :: Frame?
local barLabel = find(card, "Inner/Bar/Label") :: TextLabel?
local floatsFolder = find(card, "Inner/Floats")
local floatTemplate = find(floatsFolder, "FloatTemplate") :: TextLabel?
if not (card and titleLabel and gainLabel and multiplierLabel and barFill and barLabel) then
	warn(LOG_PREFIX .. " the TreadmillTrainingHud template is incomplete: no training HUD.")
	return
end

local ok, libs = pcall(function()
	return {
		Constants = require(ReplicatedStorage.Library.Globals.Constants),
		Network = require(ReplicatedStorage.Library.Client.Network),
		Save = require(ReplicatedStorage.Library.Client.Save),
		SpeedPowerProjection = require(ReplicatedStorage.Library.Client.SpeedPowerProjection),
		TreadmillUtil = require(ReplicatedStorage.Library.Util.TreadmillUtil),
	}
end)
if not ok then
	warn(LOG_PREFIX .. " libraries unavailable, no training HUD: " .. tostring(libs))
	return
end
local Network = libs.Network
local Save = libs.Save
local SpeedPowerProjection = libs.SpeedPowerProjection
local TreadmillUtil = libs.TreadmillUtil
local ACTIVE_TREADMILL_EVENT = libs.Constants.NETWORK_MAP.Treadmills.ACTIVE_TREADMILL_EVENT

local Audio = nil
task.spawn(function()
	local loaded, module = pcall(function()
		return require(ReplicatedStorage.Library.Audio)
	end)
	Audio = if loaded and type(module) == "table" then module else nil
end)
local MILESTONE_SOUND = 136993031050456 -- Speedsters SuccessSfx (whitelisted in Library.Audio)

local TITLE_TEXT = "TRAINING"
local TITLE_COLOR = titleLabel.TextColor3
local MILESTONE_COLOR = Color3.fromRGB(255, 217, 0)
local CARD_TOP = 8
local CARD_ASPECT = 3.4
local SHOW_INFO = TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HIDE_INFO = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local POP_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local BAR_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLOAT_INFO = TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_SCALE = 1.16
local POP_COOLDOWN = 0.12
local FLOAT_INTERVAL = 0.35
local SUMMARY_SECONDS = 1.6
local MULTIPLIER_REFRESH = 1

local active = false
local sessionToken = 0
local treadmillMultiplier = 1
local baseline = 0
local sessionGain = 0
local pendingFloat = 0
local lastPopAt = 0
local shownGain = -1
local milestoneNext = nil
local titleToken = 0
local cardHeight = 104

---------------------------------------------------------------------------------------------------
-- Formatting
---------------------------------------------------------------------------------------------------

local function formatSpeed(value: number): string
	local floored = math.max(0, math.floor(value))
	local done, text = pcall(TreadmillUtil.FormatSpeedPower, floored)
	if done and type(text) == "string" then
		return text
	end
	return tostring(floored)
end

-- Milestone ladder 1 / 2.5 / 5 x 10^k: the rung at or below `value` and the next one above it.
local function milestoneBounds(value: number): (number, number)
	local v = math.max(value, 1)
	local base = 10 ^ math.floor(math.log10(v) + 1e-9)
	local previous, nextRung = base, base * 10
	for _, factor in ipairs({ 2.5, 5, 10 }) do
		local rung = base * factor
		if rung > v then
			nextRung = rung
			break
		end
		previous = rung
	end
	if nextRung <= previous then
		nextRung = previous * 2.5
	end
	return previous, nextRung
end

---------------------------------------------------------------------------------------------------
-- Layout + show / hide
---------------------------------------------------------------------------------------------------

local function layout()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	cardHeight = math.clamp(math.floor(viewport.Y * 0.11 + 0.5), 72, 124)
	local width = math.min(math.floor(cardHeight * CARD_ASPECT + 0.5), math.max(200, viewport.X - 24))
	card.Size = UDim2.fromOffset(width, cardHeight)
end

local function shownPosition(): UDim2
	return UDim2.new(0.5, 0, 0, CARD_TOP)
end

local function hiddenPosition(): UDim2
	return UDim2.new(0.5, 0, 0, -cardHeight - 24)
end

local cameraConnection: RBXScriptConnection? = nil
local function bindCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
	local camera = Workspace.CurrentCamera
	if camera then
		cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
	end
	layout()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

local cardTween: Tween? = nil
local function tweenCard(info: TweenInfo, position: UDim2): Tween
	if cardTween then
		cardTween:Cancel()
	end
	local tween = TweenService:Create(card, info, { Position = position })
	cardTween = tween
	tween:Play()
	return tween
end

local function setTitle(text: string, color: Color3)
	titleLabel.Text = text
	titleLabel.TextColor3 = color
end

local function flashTitle(text: string, seconds: number)
	titleToken += 1
	local token = titleToken
	setTitle(text, MILESTONE_COLOR)
	task.delay(seconds, function()
		if token == titleToken and active then
			setTitle(TITLE_TEXT, TITLE_COLOR)
		end
	end)
end

---------------------------------------------------------------------------------------------------
-- Counter, floats, bar, multiplier
---------------------------------------------------------------------------------------------------

local function pop()
	if not gainPop then
		return
	end
	local now = os.clock()
	if now - lastPopAt < POP_COOLDOWN then
		return
	end
	lastPopAt = now
	gainPop.Scale = POP_SCALE
	TweenService:Create(gainPop, POP_INFO, { Scale = 1 }):Play()
end

local floatPool = {}
local function spawnFloat(amount: number)
	if not (floatTemplate and floatsFolder) then
		return
	end
	local label = table.remove(floatPool)
	if label == nil then
		label = floatTemplate:Clone()
		label.Name = "Float"
		label.Parent = floatsFolder
	end
	local stroke = label:FindFirstChildOfClass("UIStroke")
	local bounds = gainLabel.TextBounds.X
	local startX = 0.22 + math.clamp(bounds / math.max(1, floatsFolder.AbsoluteSize.X), 0.12, 0.5) + 0.02
	label.Text = "+" .. formatSpeed(amount)
	label.Position = UDim2.fromScale(startX, 0.42)
	label.TextTransparency = 0
	if stroke then
		stroke.Transparency = 0
	end
	label.Visible = true
	local goal = { Position = UDim2.fromScale(startX + 0.03, -0.05), TextTransparency = 1 }
	local tween = TweenService:Create(label, FLOAT_INFO, goal)
	if stroke then
		TweenService:Create(stroke, FLOAT_INFO, { Transparency = 1 }):Play()
	end
	tween.Completed:Once(function()
		label.Visible = false
		table.insert(floatPool, label)
	end)
	tween:Play()
end

local function setGainText(value: number)
	local rounded = math.floor(value)
	if rounded == shownGain then
		return
	end
	shownGain = rounded
	gainLabel.Text = "+" .. formatSpeed(rounded) .. " SPEED"
end

local function updateBar(speed: number, animate: boolean)
	local previous, nextRung = milestoneBounds(speed)
	if active and milestoneNext ~= nil and nextRung > milestoneNext and speed >= milestoneNext then
		flashTitle("MILESTONE " .. formatSpeed(milestoneNext) .. "!", 1.6)
		if Audio then
			pcall(Audio.Play, MILESTONE_SOUND, script, 1, 0.6)
		end
	end
	milestoneNext = nextRung
	local progress = math.clamp((speed - previous) / math.max(nextRung - previous, 1e-6), 0, 1)
	local size = UDim2.fromScale(math.max(progress, 0.02), 1)
	if animate then
		TweenService:Create(barFill, BAR_INFO, { Size = size }):Play()
	else
		barFill.Size = size
	end
	barLabel.Text = formatSpeed(speed) .. " / " .. formatSpeed(nextRung)
end

local function refreshMultiplier()
	local perStep = treadmillMultiplier
	local save = Save.Get()
	if save ~= nil then
		local done, value = pcall(TreadmillUtil.ResolveSpeedPowerPerStep, save, treadmillMultiplier, Workspace:GetServerTimeNow())
		if done and type(value) == "number" and value == value and value > 0 then
			perStep = value
		end
	end
	local done, text = pcall(TreadmillUtil.FormatSpeedMultiplierValue, perStep)
	multiplierLabel.Text = if done and type(text) == "string" then text else ("x" .. tostring(perStep))
end

local function onSpeedChanged(value: number)
	if type(value) ~= "number" then
		return
	end
	if not active then
		return
	end
	local gained = math.max(0, value - baseline)
	local delta = gained - sessionGain
	if delta > 0 then
		sessionGain = gained
		pendingFloat += delta
		setGainText(gained)
		pop()
	end
	updateBar(value, true)
end

---------------------------------------------------------------------------------------------------
-- Session
---------------------------------------------------------------------------------------------------

local function startSession(multiplier: number?)
	sessionToken += 1
	local token = sessionToken
	active = true
	treadmillMultiplier = if type(multiplier) == "number" and multiplier > 0 then multiplier else 1
	baseline = SpeedPowerProjection.GetSpeedPower()
	sessionGain = 0
	pendingFloat = 0
	shownGain = -1
	milestoneNext = nil
	titleToken += 1
	setTitle(TITLE_TEXT, TITLE_COLOR)
	setGainText(0)
	updateBar(baseline, false)
	refreshMultiplier()

	layout()
	if not card.Visible then
		card.Position = hiddenPosition()
	end
	card.Visible = true
	tweenCard(SHOW_INFO, shownPosition())

	-- Floats + multiplier refresh while this session lasts.
	task.spawn(function()
		local sinceMultiplier = 0
		while active and token == sessionToken do
			task.wait(FLOAT_INTERVAL)
			if not (active and token == sessionToken) then
				break
			end
			if pendingFloat >= 1 then
				spawnFloat(pendingFloat)
				pendingFloat = 0
			end
			sinceMultiplier += FLOAT_INTERVAL
			if sinceMultiplier >= MULTIPLIER_REFRESH then
				sinceMultiplier = 0
				refreshMultiplier()
			end
		end
	end)
end

local function endSession()
	if not active then
		return
	end
	active = false
	sessionToken += 1
	local token = sessionToken
	titleToken += 1
	if sessionGain >= 1 then
		setTitle("GREAT RUN!", MILESTONE_COLOR)
		pop()
	end
	task.delay(if sessionGain >= 1 then SUMMARY_SECONDS else 0, function()
		if token ~= sessionToken or active then
			return
		end
		local tween = tweenCard(HIDE_INFO, hiddenPosition())
		tween.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed and token == sessionToken and not active then
				card.Visible = false
			end
		end)
	end)
end

card.Visible = false
SpeedPowerProjection.Changed:Connect(onSpeedChanged)
Network.Fired(ACTIVE_TREADMILL_EVENT):Connect(function(treadmillId: string?, multiplier: number?)
	if treadmillId ~= nil then
		startSession(multiplier)
	else
		endSession()
	end
end)
