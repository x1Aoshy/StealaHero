--!nonstrict
-- StarterPlayer.StarterPlayerScripts.GUI.NightTeleportCue (LocalScript, injected by scripts/inject/night.luau)
--
-- Client half of the night teleport (owner 2026-09-23: "Make Night tp you back to spawn"). The server
-- (ServerScriptService.Controllers.AreaEggService) fires ReplicatedStorage.Network["Eggs: NightTeleport"]:
--   { Phase = "Warning", SecondsLeft = n }  a night started while this player is out in a stage: short toast.
--   { Phase = "Teleport", Target = Vector3 } the night ended while they are still out: fade to black, the server
--       moves the character home (~0.3 s later), fade back in, toast, and fire ClientCharacter's
--       OnClientTeleportCompleted signal so AreaEggResetWall turns its hub-side collision on (the wall stays up
--       for the 3-2-1 countdown after the reset, same as for the players who were already in the hub).
-- No sounds. Every require is optional: without NotificationCmds the toast uses this script's own label, and the
-- fade never stays black longer than ARRIVAL_TIMEOUT_SECONDS.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local REMOTE_NAME = "Eggs: NightTeleport"
local HUB_MAX_X = 75 -- AreaEggService.isInSafeZone: the hub (plots, lobby) is X <= 75
local ARRIVAL_DISTANCE = 12
local FADE_IN_SECONDS = 0.2
local FADE_OUT_SECONDS = 0.35
local ARRIVAL_TIMEOUT_SECONDS = 3
local TOAST_SECONDS = 4
local WARNING_TEXT = "Night is falling! Get back to your base within %ds or you'll be sent back."
local TELEPORT_TEXT = "The night is over! You were sent back to your base."
local WARNING_COLOR = Color3.fromRGB(150, 180, 255)
local TELEPORT_COLOR = Color3.fromRGB(255, 220, 120)

local function lazyModule(getter)
	local loaded, value = false, nil
	return function()
		if not loaded then
			loaded = true
			local ok, result = pcall(getter)
			value = if ok then result else nil
		end
		return value
	end
end

local getNotificationCmds = lazyModule(function()
	return require(ReplicatedStorage:WaitForChild("Library"):WaitForChild("Client"):WaitForChild("NotificationCmds"))
end)
local getSignal = lazyModule(function()
	return require(ReplicatedStorage:WaitForChild("Library"):WaitForChild("Signal"))
end)

-- Overlay: a full-screen black frame for the fade and a fallback toast label.
local screen = Instance.new("ScreenGui")
screen.Name = "NightTeleportCue"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 100
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local fade = Instance.new("Frame")
fade.Name = "Fade"
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BackgroundTransparency = 1
fade.BorderSizePixel = 0
fade.Visible = false
fade.Parent = screen

local toastLabel = Instance.new("TextLabel")
toastLabel.Name = "Toast"
toastLabel.AnchorPoint = Vector2.new(0.5, 1)
toastLabel.Position = UDim2.fromScale(0.5, 0.86)
toastLabel.Size = UDim2.fromScale(0.7, 0.07)
toastLabel.BackgroundTransparency = 1
toastLabel.Font = Enum.Font.FredokaOne
toastLabel.TextColor3 = TELEPORT_COLOR
toastLabel.TextStrokeTransparency = 0.2
toastLabel.TextScaled = true
toastLabel.TextWrapped = true
toastLabel.Text = ""
toastLabel.Visible = false
toastLabel.ZIndex = 2
toastLabel.Parent = screen

local toastSize = Instance.new("UITextSizeConstraint")
toastSize.MaxTextSize = 34
toastSize.MinTextSize = 12
toastSize.Parent = toastLabel

screen.Parent = LocalPlayer:WaitForChild("PlayerGui")

local toastSerial = 0
local function showToast(text, color)
	local cmds = getNotificationCmds()
	local message = type(cmds) == "table" and cmds.Message
	if type(message) == "table" and type(message.Bottom) == "function" then
		local ok = pcall(message.Bottom, { Message = text, Time = TOAST_SECONDS, Color = color })
		if ok then
			return
		end
	end
	toastSerial += 1
	local mine = toastSerial
	toastLabel.Text = text
	toastLabel.TextColor3 = color
	toastLabel.Visible = true
	task.delay(TOAST_SECONDS, function()
		if toastSerial == mine then
			toastLabel.Visible = false
		end
	end)
end

local fadeTween = nil
local function tweenFade(transparency, seconds)
	if fadeTween then
		fadeTween:Cancel()
	end
	fade.Visible = true
	fadeTween = TweenService:Create(fade, TweenInfo.new(seconds, Enum.EasingStyle.Quad), { BackgroundTransparency = transparency })
	fadeTween:Play()
	return fadeTween
end

local function hasArrived(target)
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	local position = root.Position
	if typeof(target) == "Vector3" and (position - target).Magnitude <= ARRIVAL_DISTANCE then
		return true
	end
	return position.X <= HUB_MAX_X
end

local function fireTeleportCompleted()
	local signal = getSignal()
	local map = type(signal) == "table" and signal.MAP
	local name = nil
	pcall(function()
		name = map.Client.ClientCharacter.ON_CLIENT_TELEPORT_COMPLETED
	end)
	if type(name) == "string" and type(signal.Fire) == "function" then
		local ok, err = pcall(signal.Fire, name)
		if not ok then
			warn("[NightTeleportCue] OnClientTeleportCompleted failed: " .. tostring(err))
		end
	end
end

local fadeSerial = 0
local function onTeleport(payload)
	fadeSerial += 1
	local mine = fadeSerial
	local started = os.clock()
	tweenFade(0, FADE_IN_SECONDS)
	task.wait(FADE_IN_SECONDS)
	while mine == fadeSerial and not hasArrived(payload.Target) and os.clock() - started < ARRIVAL_TIMEOUT_SECONDS do
		task.wait(0.05)
	end
	if mine ~= fadeSerial then
		return
	end
	local arrived = hasArrived(payload.Target)
	task.wait(0.15) -- the camera catches up behind the black
	if mine ~= fadeSerial then
		return
	end
	if arrived then
		fireTeleportCompleted()
	end
	local tween = tweenFade(1, FADE_OUT_SECONDS)
	tween.Completed:Connect(function(state)
		if mine == fadeSerial and state == Enum.PlaybackState.Completed then
			fade.Visible = false
		end
	end)
	if arrived then
		showToast(TELEPORT_TEXT, TELEPORT_COLOR)
	end
end

local network = ReplicatedStorage:WaitForChild("Network")
local remote = network:WaitForChild(REMOTE_NAME, 120)
if not remote or not remote:IsA("RemoteEvent") then
	warn("[NightTeleportCue] Network['" .. REMOTE_NAME .. "'] not found; night teleport cue disabled.")
	return
end

remote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.Phase == "Teleport" then
		task.spawn(onTeleport, payload)
	elseif payload.Phase == "Warning" then
		local seconds = math.clamp(math.floor(tonumber(payload.SecondsLeft) or 10), 1, 99)
		task.spawn(showToast, string.format(WARNING_TEXT, seconds), WARNING_COLOR)
	end
end)
