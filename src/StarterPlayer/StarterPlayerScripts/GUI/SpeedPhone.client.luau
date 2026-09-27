-- SpeedPhone (LocalScript, StarterPlayer.StarterPlayerScripts.GUI; injected by scripts/inject/phone.luau)
-- VISUAL_PASS_PLAN D4: the treadmill's TikTok-style video player is replaced by a stylised Speedsters smartphone with a
-- playable Flappy-Bird-style minigame, "Hero Flap". The phone (case, bezel, notch, status bar, game screens, pipes,
-- hero ball, minimise button and the small reopen button) is built by scripts/steps/ui_60_treadmill.luau as
-- StarterGui.SpeedPhone; this script drives it.
--
-- When it shows: as soon as the local player's treadmill session starts ("Treadmills: ActiveTreadmillChanged"(id), the
-- event TreadmillUI and the position lock use) and until it ends.
--
-- WHERE (owner 2026-09-23: "the phone must be ON the treadmill's screen"): every treadmill skin carries a PhoneScreen
-- part where the old video screen was (scripts/steps/treadmill.luau: same size / pose, Front face toward the runner,
-- with an idle "HERO FLAP" SurfaceGui from scripts/steps/ui_60_treadmill.luau). The Phone frame of the template is moved
-- into a SurfaceGui this script owns in PlayerGui (SpeedPhoneSurface, Adornee = the ACTIVE treadmill's PhoneScreen of
-- the local render, found through RuntimeInstanceRegistry "Treadmill"/id, fallback "TreadmillPlotRender"/my slot) and
-- that screen's idle SurfaceGui is disabled locally meanwhile. Other treadmills (and this one when not training) keep
-- their idle screen. A render replaced mid-session (upgrade) is followed within SESSION_TICK seconds. The runner stands
-- between the camera and the screen, so while a game runs on it the LOCAL character fades (LocalTransparencyModifier,
-- local only, restored after). 2D FALLBACK: when the active treadmill has no PhoneScreen (e.g. an unconverted skin),
-- the phone slides in on the right side of the screen as before; the gold button minimises it to a small phone button.
-- While a window (TabController tab) is open the phone steps aside (3D: back to the idle screen) and a running game
-- pauses. Players who turned Settings > "Disable Videos" on get it minimised (the reopen button) instead of auto-opened.
--
-- Controls (PC, mobile, console): tap / left click on the phone screen flaps; Space and gamepad ButtonA flap ONLY while
-- the game is focused. On the 3D screen a tap / click is hit-tested by a camera raycast onto the PhoneScreen part (the
-- SurfaceGui is not Active and the TapCatcher is hidden there), so a tap counts even where the runner covers the screen,
-- and never when a 2D button is under it. Focus starts with a click / tap on the phone (or gamepad ButtonY) and ends
-- when the phone is minimised or hidden, on a click outside the phone / screen, on gamepad ButtonB, or after
-- IDLE_UNFOCUS_SECONDS without input on a menu screen. While focused, Space / ButtonA are bound with
-- ContextActionService above the character controls and sunk, so they flap instead of jumping; unfocused, they are
-- released and Space jumps off the treadmill as before (TreadmillUI's JumpRequest -> Treadmills: RequestUnequip).
--
-- Game: gravity, flap impulse, scrolling pipe pairs with gaps (a pool of POOL_SIZE reused frames), collision with pipes
-- and ground, score, best score, start / game-over / pause screens, everything clipped to the phone screen. Physics
-- are in "screen heights" so every screen size plays the same; one RenderStepped connection, bound only while the
-- phone is open; no Instance is created per frame.
--
-- FULL SCREEN (FLAPPY 2026-09-23, owner: "Full Screen option to make it easier to play"): the FullscreenToggle in the
-- screen's top-right corner (every presentation), the big 2D FullscreenButton shown while the phone is on the 3D
-- screen, or gamepad ButtonX (while focused) moves the same Phone (same game state) into this ScreenGui, centred and
-- K.FULLSCREEN_HEIGHT of the screen tall, over FullscreenBackdrop: a tap / click ANYWHERE flaps, Space / ButtonA flap,
-- and FullscreenExit (top right), the Shrink toggle, ButtonB or ButtonX go back to the treadmill screen (or the 2D
-- dock). A run pauses on every toggle. The ScreenGui's DisplayOrder is raised meanwhile so the HUD cannot cover it.
--
-- LEADERBOARD (FLAPPY): the server (ServerScriptService.FlappyService) keeps each player's best (profile FlappyBest)
-- and the TOP 10 (OrderedDataStore FlappyBest_v1, this server only when offline). A run is announced with
-- "Flappy: RunStarted" and its score submitted once with "Flappy: SubmitScore" (the server rejects impossible
-- scores); the reply gives the best, NEW BEST and the rank shown on the game-over screen (GameOverScreen.Rank). The
-- TOP PLAYERS screen (TopButton on the start / game-over screens, gamepad ButtonY while focused) shows rank, name
-- and best from "Flappy: GetTop"; BACK / ButtonB / Space / ButtonA return. Without the server (remotes missing /
-- failing) the game still plays with a local best.
-- On-screen controls (FullscreenToggle, TopButton, BackButton) are hit-tested here, not GuiButtons: in 2D the
-- TapCatcher above the screen takes every tap (phoneControlAt with the tap's position), in 3D the camera ray's hit on
-- the PhoneScreen is mapped to the SurfaceGui canvas (surfacePointAt).

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LOG_PREFIX = "[SpeedPhone]"

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
if not PlayerGui then
	return
end

local gui = PlayerGui:WaitForChild("SpeedPhone", 60)
if not (gui and gui:IsA("ScreenGui")) then
	warn(LOG_PREFIX .. " StarterGui.SpeedPhone is missing: no phone minigame.")
	return
end

local function find(root: Instance?, path: string): any
	local node = root
	for _, segment in ipairs(string.split(path, "/")) do
		if node == nil then
			return nil
		end
		node = node:FindFirstChild(segment)
	end
	return node
end

local phone = find(gui, "Phone")
local openScale = find(phone, "OpenScale")
local screen = find(phone, "Bezel/Screen")
local gameFrame = find(screen, "Game")
local pipesFolder = find(gameFrame, "Pipes")
local pipeTemplate = find(pipesFolder, "PipeTemplate")
local groundStuds = find(gameFrame, "Ground/Studs")
local bird = find(gameFrame, "Bird")
local cape = find(bird, "Cape")
local cloudsFolder = find(gameFrame, "Clouds")
local scoreLabel = find(gameFrame, "Score")
local scorePop = find(scoreLabel, "PopScale")
local flash = find(gameFrame, "Flash")
local startScreen = find(gameFrame, "StartScreen")
local startBest = find(startScreen, "Best")
local startHint = find(startScreen, "Hint")
local playButton = find(startScreen, "PlayButton")
local overScreen = find(gameFrame, "GameOverScreen")
local overScore = find(overScreen, "Panel/ScoreValue")
local overBest = find(overScreen, "Panel/BestValue")
local newBestBadge = find(overScreen, "Panel/NewBest")
local overHint = find(overScreen, "Hint")
local pausedScreen = find(gameFrame, "PausedScreen")
local pausedHint = find(pausedScreen, "Hint")
local statusTime = find(screen, "StatusBar/Time")
local focusChip = find(screen, "StatusBar/Focus")
local focusChipLabel = find(focusChip, "Label")
local focusHint = find(screen, "FocusHint")
local focusHintLabel = find(focusHint, "Label")
local tapCatcher = find(screen, "TapCatcher")
local minimizeButton = find(phone, "MinimizeButton")
local minimizeScale = find(minimizeButton, "HoverScale")
local phoneButton = find(gui, "PhoneButton")
local phoneButtonPop = find(phoneButton, "PopScale")
-- FLAPPY: full screen + TOP PLAYERS nodes, in one table (the script is close to Luau's 200-locals limit). All
-- optional: a missing node only disables that feature.
local ui: { [string]: any } = {}
ui.toggle = find(screen, "FullscreenToggle")
ui.toggleExpand = find(ui.toggle, "Expand")
ui.toggleShrink = find(ui.toggle, "Shrink")
ui.backdrop = find(gui, "FullscreenBackdrop")
ui.backdropHint = find(ui.backdrop, "Hint")
ui.exit = find(gui, "FullscreenExit")
ui.exitScale = find(ui.exit, "HoverScale")
ui.shortcut = find(gui, "FullscreenButton")
ui.shortcutPop = find(ui.shortcut, "PopScale")
ui.startTop = find(startScreen, "TopButton")
ui.overTop = find(overScreen, "TopButton")
ui.overRank = find(overScreen, "Rank")
ui.board = find(gameFrame, "LeaderboardScreen")
ui.boardStatus = find(ui.board, "Status")
ui.boardList = find(ui.board, "List")
ui.boardEmpty = find(ui.boardList, "Empty")
ui.boardYou = find(ui.board, "You")
ui.boardBack = find(ui.board, "BackButton")
ui.youRank = find(ui.boardYou, "Rank")
ui.youScore = find(ui.boardYou, "Score")

for name, node in pairs({
	Phone = phone, Screen = screen, Game = gameFrame, Pipes = pipesFolder, PipeTemplate = pipeTemplate, Bird = bird,
	StartScreen = startScreen, GameOverScreen = overScreen, PausedScreen = pausedScreen, TapCatcher = tapCatcher,
	MinimizeButton = minimizeButton, PhoneButton = phoneButton, Score = scoreLabel,
}) do
	if node == nil then
		warn(LOG_PREFIX .. " the SpeedPhone template has no " .. name .. ": no phone minigame.")
		return
	end
end

local okLibs, libs = pcall(function()
	return {
		Constants = require(ReplicatedStorage.Library.Globals.Constants),
		Network = require(ReplicatedStorage.Library.Client.Network),
	}
end)
if not okLibs then
	warn(LOG_PREFIX .. " libraries unavailable, no phone minigame: " .. tostring(libs))
	return
end
local ACTIVE_TREADMILL_EVENT = libs.Constants.NETWORK_MAP.Treadmills.ACTIVE_TREADMILL_EVENT

-- Optional modules (the phone works without them).
local Audio, SettingsCmds, TabController = nil, nil, nil
task.spawn(function()
	local function optional(getter)
		local done, module = pcall(getter)
		return if done and type(module) == "table" then module else nil
	end
	Audio = optional(function()
		return require(ReplicatedStorage.Library.Audio)
	end)
	SettingsCmds = optional(function()
		return require(ReplicatedStorage.Library.Client.SettingsCmds)
	end)
	TabController = optional(function()
		return require(ReplicatedStorage.Library.Client.TabController)
	end)
end)
-- Where the active treadmill's render is (the 3D screen); without them the phone uses the 2D fallback.
local Registry, PlotCmds = nil, nil
task.spawn(function()
	local done, module = pcall(function()
		return require(ReplicatedStorage.Library.Modules.RuntimeInstanceRegistry)
	end)
	Registry = if done and type(module) == "table" then module else nil
	done, module = pcall(function()
		return require(ReplicatedStorage.Library.Client.PlotCmds)
	end)
	PlotCmds = if done and type(module) == "table" then module else nil
end)

---------------------------------------------------------------------------------------------------
-- Tuning (lengths in game-screen heights, times in seconds)
---------------------------------------------------------------------------------------------------

local GROUND_TOP = 0.88 -- Game.Ground top (template)
local BIRD_X = 0.3 -- fraction of the game width
local READY_Y = 0.42
local BIRD_RADIUS = 0.027 -- hitbox (the drawn ball is 0.072 across: a little forgiving)
local GRAVITY = 2.9
local FLAP_VELOCITY = -0.8
local MAX_FALL_SPEED = 1.35
local PIPE_WIDTH = 0.105
local CAP_OVERHANG = PIPE_WIDTH * 0.12 -- caps are 1.24 x the pipe width (template)
local CAP_HEIGHT = 0.05 -- template
local PIPE_SPACING = 0.42
local FIRST_PIPE_OFFSET = 0.3 -- beyond the right edge
local SPAWN_MARGIN = 0.1 -- a new pair appears this far beyond the right edge (more than the cap overhang)
local GAP_START = 0.29
local GAP_MIN = 0.215
local GAP_SHRINK_PER_POINT = 0.0035
local GAP_EDGE_MARGIN = 0.1
local MAX_GAP_SHIFT = 0.3
local SPEED_START = 0.33
local SPEED_MAX = 0.47
local SPEED_PER_POINT = 0.0045
local READY_SCROLL_SPEED = 0.2
local POOL_SIZE = 4
local MAX_STEP = 1 / 20 -- a hitch never tunnels the ball through a pipe
local DEATH_TO_GAME_OVER = 0.6
local RETRY_DELAY = 0.4
local IDLE_UNFOCUS_SECONDS = 6
local STUD_TILE_PX = 16 -- Ground.Studs TileSize (template)
local OUTSIDE_MARGIN_PX = 10

-- The phone on the treadmill's screen
local PHONE_SCREEN_NAME = "PhoneScreen" -- the skin's screen part (scripts/steps/treadmill.luau)
local IDLE_SCREEN_NAME = "IdleScreen" -- its attract SurfaceGui (scripts/steps/ui_60_treadmill.luau)
local SURFACE_GUI_NAME = "SpeedPhoneSurface"
local SURFACE_PIXELS_PER_STUD = 100 -- the 3.7 x 6.6 stud screen -> a ~369 x 656 px canvas (the 2D phone's size)
local SURFACE_MAX_DISTANCE = 150
local SURFACE_PHONE_SIZE = UDim2.fromScale(0.94, 0.965) -- inside the dark bezel part, then fitted to PHONE_ASPECT
local PHONE_ASPECT = 0.49 -- phone art width / height (template, layoutPhone)
local SCREEN_WAIT_SECONDS = 1.5 -- at a session start, wait this long for the render's PhoneScreen before the 2D fallback
local SESSION_TICK = 0.25
local RAY_LENGTH = 1000
local GHOST_TRANSPARENCY = 0.6 -- the local runner fades to this while a game runs on the 3D screen
local GHOST_FADE_SPEED = 4 -- per second
local GHOST_OVER_SECONDS = 3 -- stays faded this long on the game-over screen (the score panel)
local GHOST_REFRESH_SECONDS = 1 -- re-applied this often (new accessories, respawn)

local FLAP_ACTION = "SpeedPhoneFlap"
local FOCUS_ACTION = "SpeedPhoneFocus"
local FLAP_PRIORITY = Enum.ContextActionPriority.High.Value + 10 -- above the character controls and the treadmill lock

-- FLAPPY tuning, in one table (Luau's 200-locals limit)
local K = {
	-- Full screen
	FULLSCREEN_HEIGHT = 0.92, -- of the usable screen height (below the top bar)
	FULLSCREEN_MAX_WIDTH = 0.9, -- of the viewport width (tall / portrait screens)
	FULLSCREEN_DISPLAY_ORDER = 50, -- above the HUD (Money / Notifications 11, egg / pet lists 33-34), below Message (100)
	TAP_DEDUPE_SECONDS = 0.05, -- one InputObject reaching two handlers counts once
	CONTROL_SLACK_PX = 4,
	-- Leaderboard: remotes created by ServerScriptService.FlappyService in ReplicatedStorage.Network
	REMOTE_RUN_STARTED = "Flappy: RunStarted",
	REMOTE_SUBMIT = "Flappy: SubmitScore",
	REMOTE_GET_TOP = "Flappy: GetTop",
	REMOTE_WAIT_SECONDS = 60,
	BOARD_ROWS = 10, -- FlappyService TOP_COUNT
	BOARD_REFRESH_SECONDS = 10,
	RANK_COLORS = { Color3.fromRGB(255, 217, 0), Color3.fromRGB(217, 230, 255), Color3.fromRGB(255, 167, 90) },
	ROW_TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	MY_ROW_COLOR = Color3.fromRGB(0, 255, 247),
}

local SOUND_FLAP = 77120543307812 -- Speedsters ui-bubble-click (whitelisted in Library.Audio)
local SOUND_POINT = 72264591133889 -- Speedsters ui-pop
local SOUND_BEST = 136993031050456 -- Speedsters SuccessSfx

local OPEN_INFO = TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local POP_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FLASH_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HOVER_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local rng = Random.new()

---------------------------------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------------------------------

local sessionActive = false -- the local player is training
local minimised = false
local windowOpen = false -- a TabController window is open
local phoneShown = false
local focused = false

local state = "Ready" -- Ready | Playing | Dying | Over | Paused
local clock = 0
local aspect = 0.46 -- game width / game height, from AbsoluteSize
local gameHeightPx = 560
local birdY, birdVelocity = READY_Y, 0
local score, best = 0, 0
local deathAt, overAt = 0, 0
local lastInputAt = 0
local groundOffsetPx = 0
local shakeUntil = 0
local lastGapY: number? = nil

local renderConnection: RBXScriptConnection? = nil
local phoneTween: Tween? = nil

local activeTreadmillId: string? = nil
local sessionToken = 0
local surfaceGui: SurfaceGui? = nil
local surfacePart: BasePart? = nil -- the PhoneScreen the phone is on (nil: 2D fallback / full screen / hidden)
local phoneAspect: UIAspectRatioConstraint? = nil
local PHONE_2D_ANCHOR = phone.AnchorPoint
local BASE_DISPLAY_ORDER = gui.DisplayOrder

local fullscreen = false -- the player's choice for this training session (kept while a window steps the phone aside)
local boardOpen = false -- the TOP PLAYERS screen is shown
local runId, endedRunId = 0, 0 -- a run's game over (best, submission) is handled once
local lastRunWasBest = false
local board = {
	rank = nil :: number?, -- the local player's rank in the TOP 10 (FlappyService), else nil
	tenth = nil :: number?, -- the TOP 10's lowest best (nil while it has free rows)
	online = true, -- false: the board holds this server's players only
	data = nil :: { online: boolean, entries: { any } }?, -- the last GetTop reply (clean)
	fetchedAt = -math.huge,
	fetching = false,
}

local function playSound(id: number, volume: number, speed: number?)
	if Audio and type(Audio.Play) == "function" then
		pcall(Audio.Play, id, script, speed or 1, volume)
	end
end

-- A FlappyService remote in ReplicatedStorage.Network, or nil (never yields; see the wiring for the initial wait).
local remotes: { [string]: Instance } = {}
local function remote(name: string, className: string): any
	local cached = remotes[name]
	if cached ~= nil and cached.Parent ~= nil then
		return cached
	end
	local folder = ReplicatedStorage:FindFirstChild("Network")
	local found = if folder ~= nil then folder:FindFirstChild(name) else nil
	if found ~= nil and found:IsA(className) then
		remotes[name] = found
		return found
	end
	return nil
end

---------------------------------------------------------------------------------------------------
-- Pipes (pooled)
---------------------------------------------------------------------------------------------------

type Pipe = {
	frame: Frame,
	top: Frame?,
	bottom: Frame?,
	topCap: Frame?,
	bottomCap: Frame?,
	active: boolean,
	x: number,
	gapY: number,
	gapH: number,
	scored: boolean,
}

local pipes: { Pipe } = {}
pipeTemplate.Visible = false
for i = 1, POOL_SIZE do
	local clone = pipeTemplate:Clone()
	clone.Name = "Pipe" .. i
	clone.Visible = false
	clone.Parent = pipesFolder
	table.insert(pipes, {
		frame = clone,
		top = clone:FindFirstChild("Top"),
		bottom = clone:FindFirstChild("Bottom"),
		topCap = clone:FindFirstChild("TopCap"),
		bottomCap = clone:FindFirstChild("BottomCap"),
		active = false,
		x = 0,
		gapY = 0.44,
		gapH = GAP_START,
		scored = false,
	})
end

local function layoutPipeGap(pipe: Pipe)
	local gapTop = pipe.gapY - pipe.gapH / 2
	local gapBottom = pipe.gapY + pipe.gapH / 2
	if pipe.top then
		pipe.top.Position = UDim2.fromScale(0.5, 0)
		pipe.top.Size = UDim2.fromScale(1, gapTop)
	end
	if pipe.bottom then
		pipe.bottom.Position = UDim2.fromScale(0.5, GROUND_TOP)
		pipe.bottom.Size = UDim2.fromScale(1, GROUND_TOP - gapBottom)
	end
	if pipe.topCap then
		pipe.topCap.Position = UDim2.fromScale(0.5, gapTop)
	end
	if pipe.bottomCap then
		pipe.bottomCap.Position = UDim2.fromScale(0.5, gapBottom)
	end
end

local function clearPipes()
	for _, pipe in ipairs(pipes) do
		pipe.active = false
		pipe.frame.Visible = false
	end
	lastGapY = nil
end

local function spawnPipe(x: number)
	local pipe: Pipe? = nil
	for _, candidate in ipairs(pipes) do
		if not candidate.active then
			pipe = candidate
			break
		end
	end
	if pipe == nil then
		return
	end
	local gapH = math.max(GAP_MIN, GAP_START - score * GAP_SHRINK_PER_POINT)
	local minY = GAP_EDGE_MARGIN + gapH / 2
	local maxY = GROUND_TOP - GAP_EDGE_MARGIN - gapH / 2
	local gapY = rng:NextNumber(minY, maxY)
	if lastGapY ~= nil then
		gapY = math.clamp(gapY, lastGapY - MAX_GAP_SHIFT, lastGapY + MAX_GAP_SHIFT)
	end
	lastGapY = gapY
	pipe.active = true
	pipe.scored = false
	pipe.x = x
	pipe.gapY = gapY
	pipe.gapH = gapH
	layoutPipeGap(pipe)
	pipe.frame.Size = UDim2.fromScale(PIPE_WIDTH / aspect, 1)
	pipe.frame.Position = UDim2.fromScale(x / aspect, 0)
	pipe.frame.Visible = true
end

local function circleHitsRect(cx: number, cy: number, r: number, x0: number, y0: number, x1: number, y1: number): boolean
	local nx = math.clamp(cx, x0, x1)
	local ny = math.clamp(cy, y0, y1)
	local dx, dy = cx - nx, cy - ny
	return dx * dx + dy * dy < r * r
end

local function pipeHitsBird(pipe: Pipe, bx: number, by: number): boolean
	local x0, x1 = pipe.x, pipe.x + PIPE_WIDTH
	local gapTop = pipe.gapY - pipe.gapH / 2
	local gapBottom = pipe.gapY + pipe.gapH / 2
	return circleHitsRect(bx, by, BIRD_RADIUS, x0, -1, x1, gapTop)
		or circleHitsRect(bx, by, BIRD_RADIUS, x0 - CAP_OVERHANG, gapTop - CAP_HEIGHT, x1 + CAP_OVERHANG, gapTop)
		or circleHitsRect(bx, by, BIRD_RADIUS, x0, gapBottom, x1, 2)
		or circleHitsRect(bx, by, BIRD_RADIUS, x0 - CAP_OVERHANG, gapBottom, x1 + CAP_OVERHANG, gapBottom + CAP_HEIGHT)
end

---------------------------------------------------------------------------------------------------
-- Screens, hints, focus UI
---------------------------------------------------------------------------------------------------

local function lastInputKind(): string
	local inputType = UserInputService:GetLastInputType()
	if inputType == Enum.UserInputType.Touch then
		return "Touch"
	end
	local name = inputType.Name
	if string.sub(name, 1, 7) == "Gamepad" then
		return "Gamepad"
	end
	return "Keyboard"
end

local function refreshHints()
	local kind = lastInputKind()
	local startText, overText, pausedText, chipText
	if kind == "Touch" then
		startText = if fullscreen then "Tap anywhere to flap" else "Tap the screen to flap"
		overText, pausedText, chipText = "Tap to try again", "Tap to resume", "TAP = FLAP"
	elseif kind == "Gamepad" then
		if focused then
			local back = if fullscreen then "B exit" else "B back"
			startText = "A flap - Y top players - X " .. (if fullscreen then "exit full screen" else "full screen")
			overText, pausedText = "A retry - Y top players - " .. back, "A to resume"
		else
			startText, overText, pausedText = "Press Y to play", "Press Y to try again", "Press Y to resume"
		end
		chipText = "A = FLAP"
	else
		if focused or fullscreen then
			startText, overText, pausedText = "Space or click to flap", "Space or click to retry", "Space or click to resume"
		else
			startText, overText, pausedText = "Click the screen to play", "Click to try again", "Click to resume"
		end
		chipText = "SPACE = FLAP"
	end
	if ui.backdropHint then
		ui.backdropHint.Text = if kind == "Touch" then "Tap anywhere to flap"
			elseif kind == "Gamepad" then "A = flap\nB = exit full screen"
			else "Space or click anywhere to flap"
	end
	if startHint then
		startHint.Text = startText
	end
	if overHint then
		overHint.Text = overText
	end
	if pausedHint then
		pausedHint.Text = pausedText
	end
	if focusChipLabel then
		focusChipLabel.Text = chipText
	end
	if focusChip then
		focusChip.Visible = focused and kind ~= "Touch"
	end
	if focusHint then
		focusHint.Visible = focused and kind ~= "Touch" and state ~= "Playing"
		if focusHintLabel then
			focusHintLabel.Text = if fullscreen then (if kind == "Gamepad" then "B = exit full screen" else "Click EXIT (top right) to leave full screen")
				elseif kind == "Gamepad" then "B = back to running (A jumps again)"
				elseif surfacePart ~= nil then "Click off the screen to jump"
				else "Click outside the phone to jump"
		end
	end
end

-- name: "Start" | "Over" | "Paused" | "Board" (TOP PLAYERS) | nil (playing: only the score)
local function showScreen(name: string?)
	startScreen.Visible = name == "Start"
	overScreen.Visible = name == "Over"
	pausedScreen.Visible = name == "Paused"
	boardOpen = name == "Board" and ui.board ~= nil
	if ui.board then
		ui.board.Visible = boardOpen
	end
	scoreLabel.Visible = name == nil or name == "Paused"
	refreshHints()
end

---------------------------------------------------------------------------------------------------
-- TOP PLAYERS (FlappyService data; every server value is checked before use)
---------------------------------------------------------------------------------------------------

type BoardRow = { frame: GuiObject, rank: TextLabel?, name: TextLabel?, score: TextLabel? }
local boardRows: { [number]: BoardRow } = {}
if ui.boardList then
	for i = 1, K.BOARD_ROWS do
		local row = ui.boardList:FindFirstChild(string.format("Row%02d", i))
		if row ~= nil and row:IsA("GuiObject") then
			boardRows[i] = { frame = row, rank = find(row, "Rank"), name = find(row, "Name"), score = find(row, "Score") }
		end
	end
end

local function setText(label: TextLabel?, value: string)
	if label ~= nil and label.Text ~= value then
		label.Text = value
	end
end

local function wholeNumber(value: any): number?
	value = tonumber(value)
	if value == nil or value ~= value or value == math.huge or value == -math.huge then
		return nil
	end
	return math.max(0, math.floor(value))
end

local function renderBoard()
	if ui.board == nil then
		return
	end
	local data = board.data
	local entries = if data ~= nil then data.entries else {}
	for i, row in pairs(boardRows) do
		local entry = entries[i]
		if entry ~= nil then
			setText(row.rank, "#" .. i)
			if row.rank then
				row.rank.TextColor3 = K.RANK_COLORS[i] or K.ROW_TEXT_COLOR
			end
			setText(row.name, entry.name)
			if row.name then
				row.name.TextColor3 = if entry.userId == LocalPlayer.UserId then K.MY_ROW_COLOR else K.ROW_TEXT_COLOR
			end
			setText(row.score, tostring(entry.best))
			row.frame.Visible = true
		else
			row.frame.Visible = false
		end
	end
	if ui.boardEmpty then
		ui.boardEmpty.Visible = data ~= nil and #entries == 0
	end
	if ui.boardStatus then
		ui.boardStatus.Text = if data == nil then (if board.fetching then "Loading..." else "Leaderboard unavailable right now")
			elseif data.online then "WORLD TOP 10"
			else "THIS SERVER (world board offline)"
	end
	setText(ui.youRank, if board.rank then "#" .. board.rank else "-")
	setText(ui.youScore, tostring(best))
end

local function setBest()
	if startBest then
		startBest.Text = "BEST " .. tostring(best) .. (if board.rank then "  -  #" .. board.rank else "")
	end
	if boardOpen then
		renderBoard()
	end
end

-- GetTop reply -> board.data (at most K.BOARD_ROWS clean rows), the local best / rank.
local function applyTop(result: any)
	if type(result) ~= "table" then
		return
	end
	local entries = {}
	if type(result.entries) == "table" then
		for i = 1, K.BOARD_ROWS do
			local entry = result.entries[i]
			if type(entry) ~= "table" then
				break
			end
			local name = if type(entry.name) == "string" and entry.name ~= "" then string.sub(entry.name, 1, 32) else "..."
			table.insert(entries, { userId = wholeNumber(entry.userId) or 0, name = name, best = wholeNumber(entry.best) or 0 })
		end
	end
	board.online = result.online ~= false
	board.data = { online = board.online, entries = entries }
	if type(result.you) == "table" then
		local serverBest = wholeNumber(result.you.best)
		if serverBest ~= nil and serverBest > best then
			best = serverBest
		end
		board.rank = wholeNumber(result.you.rank)
	end
	board.tenth = wholeNumber(result.tenth)
	setBest()
	renderBoard()
end

-- Asks FlappyService for the TOP 10 (at most every K.BOARD_REFRESH_SECONDS unless forced); never yields.
local function fetchBoard(force: boolean)
	if board.fetching or (not force and os.clock() - board.fetchedAt < K.BOARD_REFRESH_SECONDS) then
		renderBoard()
		return
	end
	local getTop = remote(K.REMOTE_GET_TOP, "RemoteFunction")
	if getTop == nil then
		renderBoard()
		return
	end
	board.fetching = true
	renderBoard()
	task.spawn(function()
		local ok, result = pcall(function()
			return getTop:InvokeServer()
		end)
		board.fetching = false
		if ok and type(result) == "table" then
			board.fetchedAt = os.clock()
			applyTop(result)
		end
		renderBoard()
	end)
end

-- The game-over line: NEW BEST! / world (or server) rank / the score that enters the TOP 10.
local function rankText(newBest: boolean): string
	local prefix = if newBest then "NEW BEST!  " else ""
	if board.rank ~= nil then
		return prefix .. (if board.online then "WORLD RANK #" else "SERVER RANK #") .. board.rank
	elseif board.tenth ~= nil then
		return prefix .. "Score " .. (board.tenth + 1) .. " for the TOP 10"
	end
	return if newBest then "NEW BEST!" else ""
end

---------------------------------------------------------------------------------------------------
-- Focus (Space / ButtonA owned by the game only while focused)
---------------------------------------------------------------------------------------------------

local setFocused -- forward
local onFlapInput -- forward
local setFullscreen, openBoard, closeBoard, toggleBoard -- forward (FLAPPY)

-- While focused: Space / ButtonA flap, ButtonB goes back (TOP PLAYERS -> menu, full screen -> treadmill screen,
-- else releases the focus), ButtonX toggles full screen, ButtonY toggles TOP PLAYERS.
local function flapAction(_actionName: string, inputState: Enum.UserInputState, input: InputObject)
	if not (focused and phoneShown) then
		return Enum.ContextActionResult.Pass
	end
	if inputState == Enum.UserInputState.Begin then
		local key = input.KeyCode
		if key == Enum.KeyCode.ButtonB then
			if boardOpen then
				closeBoard()
			elseif fullscreen then
				setFullscreen(false)
			else
				setFocused(false)
			end
		elseif key == Enum.KeyCode.ButtonX then
			setFullscreen(not fullscreen)
		elseif key == Enum.KeyCode.ButtonY then
			toggleBoard()
		else
			onFlapInput()
		end
	end
	-- Begin, Change and End are all sunk, so the character controls never see half a jump.
	return Enum.ContextActionResult.Sink
end

local function focusAction(_actionName: string, inputState: Enum.UserInputState, _input: InputObject)
	if not phoneShown or focused then
		return Enum.ContextActionResult.Pass
	end
	if inputState == Enum.UserInputState.Begin then
		setFocused(true)
		onFlapInput()
	end
	return Enum.ContextActionResult.Sink
end

local focusBound = false
local function refreshGamepadFocusBinding()
	local wanted = phoneShown and not focused
	if wanted == focusBound then
		return
	end
	focusBound = wanted
	if wanted then
		ContextActionService:BindActionAtPriority(FOCUS_ACTION, focusAction, false, FLAP_PRIORITY, Enum.KeyCode.ButtonY)
	else
		ContextActionService:UnbindAction(FOCUS_ACTION)
	end
end

function setFocused(value: boolean)
	value = value and phoneShown
	if value == focused then
		refreshGamepadFocusBinding()
		return
	end
	focused = value
	if value then
		lastInputAt = clock
		ContextActionService:BindActionAtPriority(
			FLAP_ACTION,
			flapAction,
			false,
			FLAP_PRIORITY,
			Enum.KeyCode.Space,
			Enum.KeyCode.ButtonA,
			Enum.KeyCode.ButtonB,
			Enum.KeyCode.ButtonX,
			Enum.KeyCode.ButtonY
		)
	else
		ContextActionService:UnbindAction(FLAP_ACTION)
	end
	refreshGamepadFocusBinding()
	refreshHints()
end

local function isInsideObject(object: GuiObject, position: Vector3, margin: number): boolean
	local point = Vector2.new(position.X, position.Y)
	local topLeft = object.AbsolutePosition - Vector2.new(margin, margin)
	local bottomRight = object.AbsolutePosition + object.AbsoluteSize + Vector2.new(margin, margin)
	local inset = GuiService:GetGuiInset()
	for _, candidate in ipairs({ point, point - inset }) do
		if candidate.X >= topLeft.X and candidate.X <= bottomRight.X and candidate.Y >= topLeft.Y and candidate.Y <= bottomRight.Y then
			return true
		end
	end
	return false
end

local function isInsidePhone(position: Vector3): boolean
	return isInsideObject(phone, position, OUTSIDE_MARGIN_PX)
end

-- 3D: does a tap / click at this input position land on the treadmill's phone screen? A camera ray onto the
-- PhoneScreen part ONLY, so the runner standing in front of the screen never blocks a tap. Both conventions of the
-- position (below / including the top-bar inset) are tried, like isInsidePhone: a few pixels of margin.
local screenRayParams = RaycastParams.new()
screenRayParams.FilterType = Enum.RaycastFilterType.Include

local function hitsPhoneScreen(position: Vector3): boolean
	local part = surfacePart
	local camera = Workspace.CurrentCamera
	if part == nil or camera == nil or not part:IsDescendantOf(Workspace) then
		return false
	end
	screenRayParams.FilterDescendantsInstances = { part }
	for _, ray in ipairs({ camera:ScreenPointToRay(position.X, position.Y), camera:ViewportPointToRay(position.X, position.Y) }) do
		if Workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, screenRayParams) ~= nil then
			return true
		end
	end
	return false
end

-- 3D: where a tap / click lands on the phone's SurfaceGui canvas (the space its GuiObjects' AbsolutePosition is in),
-- or nil when it misses the PhoneScreen's front face. The SurfaceGui is on the Front face (-Z): seen from the front,
-- its X axis runs along the part's -X and its Y axis along -Y.
local function surfacePointAt(position: Vector3): Vector2?
	local part, surface = surfacePart, surfaceGui
	local camera = Workspace.CurrentCamera
	if part == nil or surface == nil or camera == nil or not part:IsDescendantOf(Workspace) then
		return nil
	end
	screenRayParams.FilterDescendantsInstances = { part }
	for _, ray in ipairs({ camera:ScreenPointToRay(position.X, position.Y), camera:ViewportPointToRay(position.X, position.Y) }) do
		local hit = Workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, screenRayParams)
		if hit ~= nil then
			local pose = part.CFrame
			if hit.Normal:Dot(pose.LookVector) < 0.5 then
				return nil -- the back or an edge of the screen part
			end
			local localPoint = pose:PointToObjectSpace(hit.Position)
			local u = 0.5 - localPoint.X / part.Size.X
			local v = 0.5 - localPoint.Y / part.Size.Y
			local canvas = surface.AbsoluteSize
			if canvas.X < 1 or canvas.Y < 1 then
				canvas = Vector2.new(part.Size.X, part.Size.Y) * SURFACE_PIXELS_PER_STUD
			end
			return Vector2.new(u * canvas.X, v * canvas.Y)
		end
	end
	return nil
end

-- 2D: a tap position in the phone ScreenGui's space. InputObject.Position and AbsolutePosition share the origin
-- (below the top-bar inset) for this IgnoreGuiInset = false ScreenGui; when the point falls outside the object that
-- received the input, the other convention is tried (like isInsidePhone).
local function guiPoint(position: Vector3, receiver: GuiObject): Vector2
	local point = Vector2.new(position.X, position.Y)
	local topLeft, size = receiver.AbsolutePosition, receiver.AbsoluteSize
	local function inside(candidate: Vector2): boolean
		return candidate.X >= topLeft.X and candidate.X <= topLeft.X + size.X and candidate.Y >= topLeft.Y and candidate.Y <= topLeft.Y + size.Y
	end
	if inside(point) then
		return point
	end
	local inset = GuiService:GetGuiInset()
	for _, candidate in ipairs({ point - inset, point + inset }) do
		if inside(candidate) then
			return candidate
		end
	end
	return point
end

-- Is this phone element (and every ancestor up to the phone) visible, and is `point` on it (a few px of slack)?
local function onControl(object: GuiObject?, point: Vector2): boolean
	if object == nil then
		return false
	end
	local node: Instance? = object
	while node ~= nil and node ~= phone.Parent do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		node = node.Parent
	end
	local topLeft, size = object.AbsolutePosition, object.AbsoluteSize
	return point.X >= topLeft.X - K.CONTROL_SLACK_PX and point.X <= topLeft.X + size.X + K.CONTROL_SLACK_PX
		and point.Y >= topLeft.Y - K.CONTROL_SLACK_PX and point.Y <= topLeft.Y + size.Y + K.CONTROL_SLACK_PX
end

-- The on-screen control a tap at `point` (phone container space) hits: "Fullscreen" | "Top" | "Back" | "Board"
-- (elsewhere on TOP PLAYERS) | nil (a plain flap).
local function phoneControlAt(point: Vector2?): string?
	if point == nil then
		return if boardOpen then "Board" else nil
	end
	if onControl(ui.toggle, point) then
		return "Fullscreen"
	end
	if boardOpen then
		return if onControl(ui.boardBack, point) then "Back" else "Board"
	end
	if onControl(ui.startTop, point) or onControl(ui.overTop, point) then
		return "Top"
	end
	return nil
end

-- True when a 2D button / active frame (HUD, a window, the touch jump button) is under the position: the tap is theirs.
local function screenButtonAt(position: Vector3): boolean
	local ok, objects = pcall(function()
		return PlayerGui:GetGuiObjectsAtPosition(position.X, position.Y)
	end)
	if not ok or type(objects) ~= "table" then
		return false
	end
	for _, object in ipairs(objects) do
		if object:IsA("GuiButton") or object.Active then
			local layer = object:FindFirstAncestorWhichIsA("LayerCollector")
			if layer ~= nil and layer:IsA("ScreenGui") then
				return true
			end
		end
	end
	return false
end

---------------------------------------------------------------------------------------------------
-- 3D: the local runner fades while a game runs on the screen in front of it (local only, restored after)
---------------------------------------------------------------------------------------------------

local ghostAlpha = 0
local ghostRefreshAt = 0
local ghostWritten = setmetatable({}, { __mode = "k" }) -- [BasePart | Decal] = the LocalTransparencyModifier written here

local function writeGhost(value: number)
	local character = LocalPlayer.Character
	if character ~= nil then
		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("BasePart") or d:IsA("Decal") then
				local current = d.LocalTransparencyModifier
				local written = ghostWritten[d]
				if written ~= nil and math.abs(current - written) > 1e-3 then
					ghostWritten[d] = nil -- someone else (the camera's first-person fade) owns it now: leave it
				elseif written ~= nil or current < value then
					d.LocalTransparencyModifier = value
					ghostWritten[d] = if value > 0 then value else nil
				end
			end
		end
	end
	if value <= 0 then
		table.clear(ghostWritten)
	end
end

local function updateGhost(dt: number)
	local wanted = surfacePart ~= nil and phoneShown and (focused or state == "Playing" or state == "Dying"
		or (state == "Over" and clock - overAt < GHOST_OVER_SECONDS))
	local target = if wanted then 1 else 0
	local before = ghostAlpha
	if ghostAlpha < target then
		ghostAlpha = math.min(target, ghostAlpha + dt * GHOST_FADE_SPEED)
	elseif ghostAlpha > target then
		ghostAlpha = math.max(target, ghostAlpha - dt * GHOST_FADE_SPEED)
	end
	if ghostAlpha ~= before or (ghostAlpha > 0 and clock >= ghostRefreshAt) then
		ghostRefreshAt = clock + GHOST_REFRESH_SECONDS
		writeGhost(ghostAlpha * GHOST_TRANSPARENCY)
	end
end

local function clearGhost()
	if ghostAlpha > 0 or next(ghostWritten) ~= nil then
		ghostAlpha = 0
		writeGhost(0)
	end
end

---------------------------------------------------------------------------------------------------
-- Game flow
---------------------------------------------------------------------------------------------------

local function popScore()
	if scorePop then
		scorePop.Scale = 1.35
		TweenService:Create(scorePop, POP_INFO, { Scale = 1 }):Play()
	end
end

local function flap()
	birdVelocity = FLAP_VELOCITY
	playSound(SOUND_FLAP, 0.35, rng:NextNumber(1.05, 1.2))
end

local function startRun()
	state = "Playing"
	score = 0
	runId += 1
	local runStarted = remote(K.REMOTE_RUN_STARTED, "RemoteEvent")
	if runStarted ~= nil then
		pcall(function()
			runStarted:FireServer() -- FlappyService times the run (its score ceiling)
		end)
	end
	scoreLabel.Text = "0"
	birdY = READY_Y
	birdVelocity = 0
	clearPipes()
	spawnPipe(aspect + FIRST_PIPE_OFFSET)
	if newBestBadge then
		newBestBadge.Visible = false
	end
	showScreen(nil)
	flap()
end

local function addPoint()
	score += 1
	scoreLabel.Text = tostring(score)
	popScore()
	playSound(SOUND_POINT, 0.45, 1 + math.min(score, 20) * 0.01)
end

local function die()
	state = "Dying"
	deathAt = clock
	shakeUntil = clock + 0.3
	birdVelocity = math.min(birdVelocity, -0.35)
	if flash then
		flash.BackgroundTransparency = 0.15
		TweenService:Create(flash, FLASH_INFO, { BackgroundTransparency = 1 }):Play()
	end
	refreshHints()
end

-- Sends the finished run's score to FlappyService (once per run); its reply refines the best and the rank line.
local function submitScore(forRun: number, finalScore: number)
	local submit = remote(K.REMOTE_SUBMIT, "RemoteFunction")
	if submit == nil or finalScore <= 0 then
		return
	end
	task.spawn(function()
		local ok, result = pcall(function()
			return submit:InvokeServer(finalScore)
		end)
		if not (ok and type(result) == "table") then
			return -- offline / failed: the local best and the line already shown stay
		end
		local serverBest = wholeNumber(result.best)
		if serverBest ~= nil and serverBest > best then
			best = serverBest
		end
		board.rank = wholeNumber(result.rank)
		board.tenth = wholeNumber(result.tenth)
		board.online = result.online ~= false
		board.fetchedAt = -math.huge -- the TOP 10 may have changed
		setBest()
		if forRun == runId and state == "Over" then
			if ui.overRank then
				-- a refused score (result.ok false: rate limit / no run / impossible) keeps the local NEW BEST! alone
				ui.overRank.Text = if result.ok == false and lastRunWasBest then "NEW BEST!"
					else rankText(lastRunWasBest or result.newBest == true)
			end
			if overBest then
				overBest.Text = tostring(best)
			end
		end
	end)
end

-- Once per run, when it ends: the local best, the NEW BEST sound and the submission.
local function endRun()
	if endedRunId == runId then
		return
	end
	endedRunId = runId
	lastRunWasBest = score > best and score > 0
	if lastRunWasBest then
		best = score
		setBest()
		playSound(SOUND_BEST, 0.6)
	end
	if ui.overRank then
		-- until the server answers: NEW BEST! alone (the old rank is stale), else the known rank
		ui.overRank.Text = if lastRunWasBest then "NEW BEST!" else rankText(false)
	end
	submitScore(runId, score)
end

local function showGameOver()
	state = "Over"
	overAt = clock
	endRun()
	if overScore then
		overScore.Text = tostring(score)
	end
	if overBest then
		overBest.Text = tostring(best)
	end
	if newBestBadge then
		newBestBadge.Visible = lastRunWasBest
	end
	showScreen("Over")
end

local function pause()
	if state == "Playing" then
		state = "Paused"
		showScreen("Paused")
	elseif state == "Dying" then
		showGameOver()
	end
end

-- TOP PLAYERS: from the start / game-over screens only (never over a run).
function openBoard()
	if ui.board == nil or boardOpen or (state ~= "Ready" and state ~= "Over") then
		return
	end
	showScreen("Board")
	playSound(SOUND_FLAP, 0.35, 1.25)
	fetchBoard(false)
end

function closeBoard()
	if not boardOpen then
		return
	end
	showScreen(if state == "Over" then "Over" else "Start")
	playSound(SOUND_FLAP, 0.35, 0.95)
end

function toggleBoard()
	if boardOpen then
		closeBoard()
	else
		openBoard()
	end
end

function onFlapInput()
	if not phoneShown then
		return
	end
	lastInputAt = clock
	if boardOpen then
		closeBoard() -- Space / ButtonA on TOP PLAYERS go back to the menu (never start a run from there)
		return
	end
	if state == "Ready" then
		startRun()
	elseif state == "Playing" then
		flap()
	elseif state == "Paused" then
		state = "Playing"
		showScreen(nil)
		flap()
	elseif state == "Over" then
		if clock - overAt >= RETRY_DELAY then
			startRun()
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Frame update
---------------------------------------------------------------------------------------------------

local clouds = {}
if cloudsFolder then
	for _, cloud in ipairs(cloudsFolder:GetChildren()) do
		if cloud:IsA("GuiObject") then
			table.insert(clouds, { frame = cloud, x = cloud.Position.X.Scale, y = cloud.Position.Y.Scale, speed = 0.02 + 0.01 * #clouds })
		end
	end
end
local playButtonSize = if playButton then playButton.Size else nil

local function measure()
	local size = gameFrame.AbsoluteSize
	if size.X > 1 and size.Y > 1 then
		aspect = size.X / size.Y
		gameHeightPx = size.Y
	end
	for _, pipe in ipairs(pipes) do
		pipe.frame.Size = UDim2.fromScale(PIPE_WIDTH / aspect, 1)
		if pipe.active then
			pipe.frame.Position = UDim2.fromScale(pipe.x / aspect, 0)
		end
	end
end
gameFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure)

local function step(dt: number)
	dt = math.min(dt, MAX_STEP)
	clock += dt

	local scroll = 0
	if state == "Playing" then
		local speed = math.min(SPEED_MAX, SPEED_START + score * SPEED_PER_POINT)
		scroll = speed
		birdVelocity = math.min(birdVelocity + GRAVITY * dt, MAX_FALL_SPEED)
		birdY += birdVelocity * dt
		if birdY - BIRD_RADIUS < 0 then
			birdY = BIRD_RADIUS
			birdVelocity = math.max(birdVelocity, 0)
		end

		local birdX = BIRD_X * aspect
		local rightmost = -math.huge
		local hit = false
		for _, pipe in ipairs(pipes) do
			if pipe.active then
				pipe.x -= speed * dt
				if pipe.x + PIPE_WIDTH + CAP_OVERHANG < -0.02 then
					pipe.active = false
					pipe.frame.Visible = false
				else
					pipe.frame.Position = UDim2.fromScale(pipe.x / aspect, 0)
					rightmost = math.max(rightmost, pipe.x)
					if not pipe.scored and pipe.x + PIPE_WIDTH / 2 < birdX then
						pipe.scored = true
						addPoint()
					end
					if not hit and pipeHitsBird(pipe, birdX, birdY) then
						hit = true
					end
				end
			end
		end
		-- The next pair enters just beyond the right edge, PIPE_SPACING behind the last one.
		if rightmost == -math.huge then
			spawnPipe(aspect + FIRST_PIPE_OFFSET)
		elseif rightmost + PIPE_SPACING <= aspect + SPAWN_MARGIN then
			spawnPipe(rightmost + PIPE_SPACING)
		end
		if birdY + BIRD_RADIUS >= GROUND_TOP then
			birdY = GROUND_TOP - BIRD_RADIUS
			hit = true
		end
		if hit then
			die()
		end
	elseif state == "Dying" then
		birdVelocity = math.min(birdVelocity + GRAVITY * 1.2 * dt, MAX_FALL_SPEED * 1.4)
		birdY = math.min(birdY + birdVelocity * dt, GROUND_TOP - BIRD_RADIUS)
		if clock - deathAt >= DEATH_TO_GAME_OVER and birdY >= GROUND_TOP - BIRD_RADIUS - 1e-3 then
			showGameOver()
		end
	elseif state == "Ready" then
		scroll = READY_SCROLL_SPEED
		birdY = READY_Y + math.sin(clock * 3.2) * 0.014
		birdVelocity = math.cos(clock * 3.2) * 0.1
		if playButton and playButtonSize then
			local s = 1 + math.sin(clock * 5) * 0.035
			playButton.Size = UDim2.new(playButtonSize.X.Scale * s, 0, playButtonSize.Y.Scale * s, 0)
		end
	end

	-- Draw: ball, cape flutter, ground scroll, clouds, shake.
	bird.Position = UDim2.fromScale(BIRD_X, birdY)
	if state == "Dying" or state == "Over" then
		bird.Rotation = math.min(bird.Rotation + 540 * dt, 90)
	else
		bird.Rotation = math.clamp(birdVelocity * 65, -25, 80)
	end
	if cape then
		cape.Rotation = -12 + math.sin(clock * (if state == "Playing" then 22 else 9)) * 10
	end
	if groundStuds and scroll > 0 then
		groundOffsetPx = (groundOffsetPx + scroll * dt * gameHeightPx) % STUD_TILE_PX
		groundStuds.Position = UDim2.fromOffset(-groundOffsetPx, 0)
	end
	local drift = if state == "Playing" then 1 else 0.4
	for _, cloud in ipairs(clouds) do
		cloud.x -= cloud.speed * drift * dt
		if cloud.x < -0.35 then
			cloud.x = 1.35
		end
		cloud.frame.Position = UDim2.fromScale(cloud.x, cloud.y)
	end
	if clock < shakeUntil then
		screen.Position = UDim2.new(0.5, math.sin(clock * 95) * 4, 0.5, math.cos(clock * 80) * 3)
	elseif screen.Position ~= UDim2.fromScale(0.5, 0.5) then
		screen.Position = UDim2.fromScale(0.5, 0.5)
	end

	-- Release Space after a while on a menu screen, so an idle phone never blocks the jump (full screen keeps it:
	-- the player leaves full screen explicitly).
	if focused and not fullscreen and state ~= "Playing" and state ~= "Dying" and clock - lastInputAt > IDLE_UNFOCUS_SECONDS then
		setFocused(false)
	end

	updateGhost(dt)
end

---------------------------------------------------------------------------------------------------
-- Phone open / minimise / hide
---------------------------------------------------------------------------------------------------

-- Full screen: the phone centred, K.FULLSCREEN_HEIGHT of the usable height (narrower on tall screens), the EXIT pill
-- and the backdrop hint (only where the phone leaves room on its left) sized from the viewport.
local function layoutFullscreen()
	local camera = Workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	local usable = math.max(200, viewport.Y - GuiService:GetGuiInset().Y)
	local height = math.floor(usable * K.FULLSCREEN_HEIGHT)
	local width = math.floor(height * PHONE_ASPECT)
	local maxWidth = math.floor(viewport.X * K.FULLSCREEN_MAX_WIDTH)
	if width > maxWidth then
		width = maxWidth
		height = math.floor(width / PHONE_ASPECT)
	end
	phone.AnchorPoint = Vector2.new(0.5, 0.5)
	phone.Position = UDim2.fromScale(0.5, 0.5)
	phone.Size = UDim2.fromOffset(width, height)
	if ui.exit then
		local exitHeight = math.clamp(math.floor(usable * 0.11), 44, 72)
		ui.exit.Size = UDim2.fromOffset(math.floor(exitHeight * 3.2), exitHeight)
	end
	if ui.backdropHint then
		local free = (viewport.X - width) / 2 - 40
		ui.backdropHint.Visible = free >= 140
		ui.backdropHint.Size = UDim2.fromOffset(math.max(0, math.floor(free)), math.clamp(math.floor(usable * 0.14), 40, 110))
	end
end

local function layoutPhone()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local usable = math.max(200, viewport.Y - GuiService:GetGuiInset().Y)
	local buttonSize = math.clamp(math.floor(usable * 0.12), 56, 88)
	phoneButton.Size = UDim2.fromOffset(buttonSize, buttonSize)
	if ui.shortcut then
		ui.shortcut.Size = UDim2.fromOffset(buttonSize, buttonSize)
	end
	if fullscreen and phoneShown then
		layoutFullscreen()
		return
	end
	if surfacePart ~= nil then
		return -- on the treadmill screen: sized by mount3D, not by the viewport
	end
	local height = math.clamp(math.floor(usable * 0.64), 230, 600)
	local width = math.floor(height * PHONE_ASPECT)
	local maxWidth = math.floor(viewport.X * 0.22) -- stays in the right fifth, clear of the runner
	if width > maxWidth and maxWidth >= 110 then
		width = maxWidth
		height = math.floor(width / PHONE_ASPECT)
	end
	phone.Size = UDim2.fromOffset(width, height)
end

local function shownPhonePosition(): UDim2
	return UDim2.fromScale(0.845, 0.53)
end

local function hiddenPhonePosition(): UDim2
	return UDim2.new(1, phone.AbsoluteSize.X + 40, 0.53, 0)
end

local cameraConnection: RBXScriptConnection? = nil
local function bindCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
	local camera = Workspace.CurrentCamera
	if camera then
		cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutPhone)
	end
	layoutPhone()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

local function updateClock()
	if statusTime then
		local now = os.date("*t")
		statusTime.Text = string.format("%d:%02d", now.hour, now.min)
	end
end

-- The active treadmill's PhoneScreen in the local render (TreadmillStaticController registers it), or nil.
local function resolvePhoneScreen(): BasePart?
	if activeTreadmillId == nil or Registry == nil then
		return nil
	end
	local model = nil
	local done, found = pcall(Registry.Get, "Treadmill", activeTreadmillId)
	if done then
		model = found
	end
	if model == nil and PlotCmds ~= nil then
		local okSlot, slot = pcall(PlotCmds.GetMySlot)
		if okSlot and slot ~= nil then
			local okRender, render = pcall(Registry.Get, "TreadmillPlotRender", tostring(slot))
			if okRender then
				model = render
			end
		end
	end
	if typeof(model) ~= "Instance" or not model:IsDescendantOf(Workspace) then
		return nil
	end
	local part = model:FindFirstChild(PHONE_SCREEN_NAME, true)
	return if part ~= nil and part:IsA("BasePart") then part else nil
end

-- The SurfaceGui the phone renders in on the treadmill screen. In PlayerGui (local only) with an Adornee; not Active:
-- taps are hit-tested by a raycast (hitsPhoneScreen), so nothing in it has to receive GUI input.
local function getSurfaceGui(): SurfaceGui
	if surfaceGui ~= nil and surfaceGui.Parent == PlayerGui then
		return surfaceGui
	end
	local existing = PlayerGui:FindFirstChild(SURFACE_GUI_NAME)
	local surface: SurfaceGui = if existing ~= nil and existing:IsA("SurfaceGui") then existing else Instance.new("SurfaceGui")
	surface.Name = SURFACE_GUI_NAME
	surface.ResetOnSpawn = false
	surface.Enabled = false
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = SURFACE_PIXELS_PER_STUD
	surface.LightInfluence = 0
	surface.Brightness = 1
	surface.MaxDistance = SURFACE_MAX_DISTANCE
	surface.AlwaysOnTop = false
	surface.ZOffset = 1
	surface.ClipsDescendants = true
	surface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function()
		surface.Active = false
	end)
	surface.Parent = PlayerGui
	surfaceGui = surface
	return surface
end

local function setIdleScreen(part: BasePart?, enabled: boolean)
	local idle = if part ~= nil then part:FindFirstChild(IDLE_SCREEN_NAME) else nil
	if idle ~= nil and idle:IsA("LayerCollector") then
		pcall(function()
			idle.Enabled = enabled
		end)
	end
end

-- Which chrome the current presentation shows: the minimise button (2D dock only), the TapCatcher (2D: dock and full
-- screen), the toggle's Expand / Shrink glyph, and the big 2D FULL SCREEN shortcut (phone on the 3D screen).
local shortcutShown = false
local function refreshChrome()
	local on3D = surfacePart ~= nil
	minimizeButton.Visible = not on3D and not fullscreen
	tapCatcher.Visible = not on3D
	if ui.toggleExpand then
		ui.toggleExpand.Visible = not fullscreen
	end
	if ui.toggleShrink then
		ui.toggleShrink.Visible = fullscreen
	end
	if ui.shortcut then
		local want = phoneShown and on3D and not fullscreen
		if want ~= shortcutShown then
			shortcutShown = want
			ui.shortcut.Visible = want
			if want and ui.shortcutPop then
				ui.shortcutPop.Scale = 0.6
				TweenService:Create(ui.shortcutPop, OPEN_INFO, { Scale = 1 }):Play()
			end
		end
	end
end

-- Puts the phone on a treadmill screen (from the 2D fallback, another screen, or hidden).
local function mount3D(part: BasePart)
	local surface = getSurfaceGui()
	local wasShown = surface.Enabled and phone.Parent == surface and phone.Visible
	if surfacePart ~= nil and surfacePart ~= part then
		setIdleScreen(surfacePart, true)
	end
	surfacePart = part
	setIdleScreen(part, false)
	if phoneTween then
		phoneTween:Cancel()
		phoneTween = nil
	end
	surface.Adornee = part
	phone.AnchorPoint = Vector2.new(0.5, 0.5)
	phone.Position = UDim2.fromScale(0.5, 0.5)
	phone.Size = SURFACE_PHONE_SIZE
	if phoneAspect == nil or phoneAspect.Parent ~= phone then
		local constraint = Instance.new("UIAspectRatioConstraint")
		constraint.Name = "SurfaceAspect"
		constraint.AspectRatio = PHONE_ASPECT
		constraint.AspectType = Enum.AspectType.FitWithinMaxSize
		constraint.Parent = phone
		phoneAspect = constraint
	end
	-- Nothing to minimise on the treadmill (it never covers the view); taps go through hitsPhoneScreen.
	minimizeButton.Visible = false
	tapCatcher.Visible = false
	if phone.Parent ~= surface then
		phone.Parent = surface
	end
	phone.Visible = true
	surface.Enabled = true
	if openScale and not wasShown then
		openScale.Scale = 0.85
		TweenService:Create(openScale, OPEN_INFO, { Scale = 1 }):Play()
	end
	refreshChrome()
	refreshHints()
end

-- Takes the phone off the treadmill screen (the screen shows its idle SurfaceGui again); the phone is left hidden
-- in the 2D ScreenGui, ready for either presentation.
local function unmount3D()
	if surfacePart ~= nil then
		setIdleScreen(surfacePart, true)
		surfacePart = nil
	end
	if surfaceGui ~= nil then
		surfaceGui.Enabled = false
		surfaceGui.Adornee = nil
	end
	phone.Visible = false
	phone.Parent = gui
	phone.AnchorPoint = PHONE_2D_ANCHOR
	if phoneAspect ~= nil then
		phoneAspect:Destroy()
		phoneAspect = nil
	end
	minimizeButton.Visible = true
	tapCatcher.Visible = true
	if openScale then
		openScale.Scale = 1
	end
	refreshChrome()
	layoutPhone()
end

-- 2D fallback: slides in on the right side of the screen.
local function slideIn2D()
	layoutPhone()
	if phoneTween then
		phoneTween:Cancel()
	end
	if not phone.Visible then
		phone.Position = hiddenPhonePosition()
	end
	phone.Visible = true
	if openScale then
		openScale.Scale = 1
	end
	phoneTween = TweenService:Create(phone, OPEN_INFO, { Position = shownPhonePosition() })
	phoneTween:Play()
end

-- Full screen on: the phone (already in this ScreenGui) centred over the backdrop, above the HUD.
local function presentFullscreen()
	if phoneTween then
		phoneTween:Cancel()
		phoneTween = nil
	end
	if phone.Parent ~= gui then
		phone.Parent = gui
	end
	layoutFullscreen()
	gui.DisplayOrder = K.FULLSCREEN_DISPLAY_ORDER
	if ui.backdrop then
		ui.backdrop.Visible = true
	end
	if ui.exit then
		ui.exit.Visible = true
	end
	phone.Visible = true
	if openScale then
		openScale.Scale = 0.9
		TweenService:Create(openScale, OPEN_INFO, { Scale = 1 }):Play()
	end
	refreshChrome()
end

-- Full screen chrome off (the phone itself is placed by the caller).
local function hideFullscreen()
	gui.DisplayOrder = BASE_DISPLAY_ORDER
	if ui.backdrop then
		ui.backdrop.Visible = false
	end
	if ui.exit then
		ui.exit.Visible = false
	end
	phone.AnchorPoint = PHONE_2D_ANCHOR
end

-- Toggles FULL SCREEN (same phone, same game state). A run pauses; the player taps to resume.
function setFullscreen(value: boolean)
	if value == fullscreen or (value and not phoneShown) then
		return
	end
	pause()
	fullscreen = value
	playSound(SOUND_FLAP, 0.4, if value then 1.2 else 0.9)
	if value then
		if surfacePart ~= nil then
			unmount3D()
		end
		clearGhost()
		presentFullscreen()
		setFocused(true)
	else
		hideFullscreen()
		phone.Visible = false
		local part = if phoneShown then resolvePhoneScreen() else nil
		if part ~= nil then
			mount3D(part)
		elseif phoneShown then
			slideIn2D()
		end
		lastInputAt = clock
	end
	measure()
	refreshChrome()
	refreshHints()
end

local function openPhone()
	phoneShown = true
	updateClock()
	if fullscreen then
		if surfacePart ~= nil then
			unmount3D()
		end
		presentFullscreen()
	else
		local part = resolvePhoneScreen()
		if part ~= nil then
			mount3D(part)
		else
			slideIn2D()
		end
	end
	measure()
	if state == "Over" or state == "Dying" then
		showGameOver()
	elseif state == "Ready" then
		showScreen("Start")
	end
	if renderConnection == nil then
		renderConnection = RunService.RenderStepped:Connect(step)
	end
	if fullscreen then
		setFocused(true)
	end
	refreshChrome()
	refreshGamepadFocusBinding()
	refreshHints()
end

local function closePhone()
	phoneShown = false
	pause()
	setFocused(false)
	refreshGamepadFocusBinding()
	clearGhost()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	if phoneTween then
		phoneTween:Cancel()
	end
	if fullscreen then
		-- the choice is kept: the phone comes back full screen when it reopens this session
		hideFullscreen()
		phone.Visible = false
		refreshChrome()
		return
	end
	if surfacePart ~= nil then
		unmount3D()
		return
	end
	if not phone.Visible then
		return
	end
	local tween = TweenService:Create(phone, CLOSE_INFO, { Position = hiddenPhonePosition() })
	phoneTween = tween
	tween.Completed:Once(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed and not phoneShown then
			phone.Visible = false
		end
	end)
	tween:Play()
end

-- While shown: follow the treadmill render (replaced on an upgrade, or registered after the session started).
local function refreshMount()
	if not phoneShown or fullscreen then
		return
	end
	if surfacePart ~= nil and surfacePart:IsDescendantOf(Workspace) then
		return
	end
	local part = resolvePhoneScreen()
	if part ~= nil then
		mount3D(part)
		measure()
	elseif surfacePart ~= nil then
		unmount3D()
		slideIn2D()
		measure()
		refreshHints()
	end
end

local buttonShown = false
local function setPhoneButton(visible: boolean)
	if visible == buttonShown then
		return
	end
	buttonShown = visible
	phoneButton.Visible = visible
	if visible and phoneButtonPop then
		phoneButtonPop.Scale = 0.6
		TweenService:Create(phoneButtonPop, OPEN_INFO, { Scale = 1 }):Play()
	end
end

local function refreshVisibility()
	local wantPhone = sessionActive and not minimised and not windowOpen
	if wantPhone ~= phoneShown then
		if wantPhone then
			openPhone()
		else
			closePhone()
		end
	end
	setPhoneButton(sessionActive and minimised and not windowOpen)
end

local function autoOpenDisabled(): boolean
	if SettingsCmds and type(SettingsCmds.IsEnabled) == "function" then
		local done, disabled = pcall(SettingsCmds.IsEnabled, "DisableVideos")
		return done and disabled == true
	end
	return false
end

local function startSession()
	if sessionActive then
		return
	end
	sessionActive = true
	sessionToken += 1
	local token = sessionToken
	minimised = autoOpenDisabled()
	task.spawn(function()
		-- The local render registers on the same event: give it a moment, so the phone opens on the treadmill
		-- screen instead of flashing the 2D fallback first.
		local waited = 0
		while sessionActive and token == sessionToken and waited < SCREEN_WAIT_SECONDS and resolvePhoneScreen() == nil do
			task.wait(0.1)
			waited += 0.1
		end
		if not (sessionActive and token == sessionToken) then
			return
		end
		refreshVisibility()
		-- While training: step aside when a window opens, follow the render, keep the clock and the button's nudge.
		local sinceClock, sinceNudge = 0, 0
		while sessionActive and token == sessionToken do
			task.wait(SESSION_TICK)
			if not (sessionActive and token == sessionToken) then
				break
			end
			local open = false
			if TabController and type(TabController.Get) == "function" then
				local done, current = pcall(TabController.Get)
				open = done and current ~= nil
			end
			if open ~= windowOpen then
				windowOpen = open
				refreshVisibility()
			end
			refreshMount()
			sinceClock += SESSION_TICK
			if sinceClock >= 10 then
				sinceClock = 0
				updateClock()
			end
			sinceNudge += SESSION_TICK
			if buttonShown and sinceNudge >= 5 and phoneButtonPop then
				sinceNudge = 0
				phoneButtonPop.Scale = 1.14
				TweenService:Create(phoneButtonPop, POP_INFO, { Scale = 1 }):Play()
			end
		end
	end)
end

local function endSession()
	if not sessionActive then
		return
	end
	sessionActive = false
	windowOpen = false
	refreshVisibility()
	-- full screen is chosen per training session (closePhone already hid its chrome)
	if fullscreen then
		fullscreen = false
		hideFullscreen()
		refreshChrome()
		refreshHints()
	end
end

---------------------------------------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------------------------------------

phone.Visible = false
phoneButton.Visible = false
tapCatcher.Selectable = false
if ui.backdrop then
	ui.backdrop.Visible = false
end
if ui.exit then
	ui.exit.Visible = false
end
if ui.shortcut then
	ui.shortcut.Visible = false
end
setBest()
showScreen("Start")
refreshChrome()
measure()

-- One InputObject reaching two handlers in the same moment (e.g. the backdrop and the TapCatcher) counts once.
local lastTapInput: InputObject? = nil
local lastTapAt = -math.huge
local function freshTap(input: InputObject): boolean
	local now = os.clock()
	if input == lastTapInput and now - lastTapAt < K.TAP_DEDUPE_SECONDS then
		return false
	end
	lastTapInput, lastTapAt = input, now
	return true
end

-- A tap / click on the phone (every presentation): an on-screen control (full screen toggle, TOP PLAYERS, BACK) when
-- `point` (phone container space) is on one, else a flap; takes Space / ButtonA while a keyboard / gamepad exists
-- (always in full screen).
local function tapPhone(inputType: Enum.UserInputType, point: Vector2?)
	if inputType == Enum.UserInputType.MouseButton1 or UserInputService.KeyboardEnabled or UserInputService.GamepadEnabled or fullscreen then
		setFocused(true)
	end
	local control = phoneControlAt(point)
	if control == "Fullscreen" then
		setFullscreen(not fullscreen)
	elseif control == "Top" then
		lastInputAt = clock
		openBoard()
	elseif control == "Back" then
		lastInputAt = clock
		closeBoard()
	elseif control == "Board" then
		lastInputAt = clock -- elsewhere on TOP PLAYERS: nothing (never starts a run by accident)
	else
		onFlapInput()
	end
end

-- 2D (dock and full screen): the TapCatcher over the phone screen catches taps / clicks (hidden on the treadmill).
tapCatcher.InputBegan:Connect(function(input: InputObject)
	if surfacePart ~= nil then
		return
	end
	local inputType = input.UserInputType
	if (inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch)
		and input.UserInputState == Enum.UserInputState.Begin and freshTap(input) then
		tapPhone(inputType, guiPoint(input.Position, tapCatcher))
	end
end)

-- Full screen: a tap / click anywhere around the phone screen flaps too (the screen's own taps are the TapCatcher's,
-- EXIT is a button of its own).
if ui.backdrop then
	ui.backdrop.InputBegan:Connect(function(input: InputObject)
		if not (fullscreen and phoneShown) then
			return
		end
		local inputType = input.UserInputType
		if not ((inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch)
			and input.UserInputState == Enum.UserInputState.Begin) then
			return
		end
		if isInsideObject(tapCatcher, input.Position, 0) or (ui.exit ~= nil and isInsideObject(ui.exit, input.Position, 6)) then
			return
		end
		if freshTap(input) then
			tapPhone(inputType, nil)
		end
	end)
end

-- 3D: a tap / click whose camera ray meets the treadmill's phone screen flaps (unless a 2D button is under it), or
-- presses the on-screen control under it. Both: a click / tap anywhere else gives Space back to the character (jump
-- off the treadmill). Full screen: the backdrop / TapCatcher / EXIT handle every tap.
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	local inputType = input.UserInputType
	if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
		return
	end
	if fullscreen then
		return
	end
	if surfacePart ~= nil and phoneShown then
		if hitsPhoneScreen(input.Position) and not (gameProcessed and screenButtonAt(input.Position)) then
			if freshTap(input) then
				tapPhone(inputType, surfacePointAt(input.Position))
			end
		elseif focused then
			setFocused(false)
		end
		return
	end
	if focused and not isInsidePhone(input.Position) then
		setFocused(false)
	end
end)
UserInputService.LastInputTypeChanged:Connect(refreshHints)

-- Full screen buttons (real GuiButtons in this ScreenGui)
if ui.shortcut then
	ui.shortcut.Activated:Connect(function()
		setFullscreen(true)
	end)
end
if ui.exit then
	ui.exit.Activated:Connect(function()
		setFullscreen(false)
	end)
	ui.exit.MouseEnter:Connect(function()
		if ui.exitScale then
			TweenService:Create(ui.exitScale, HOVER_INFO, { Scale = 1.08 }):Play()
		end
	end)
	ui.exit.MouseLeave:Connect(function()
		if ui.exitScale then
			TweenService:Create(ui.exitScale, HOVER_INFO, { Scale = 1 }):Play()
		end
	end)
end

-- Seed the all-time best and rank from FlappyService once its remotes exist (the start screen shows them).
task.spawn(function()
	local network = ReplicatedStorage:WaitForChild("Network", K.REMOTE_WAIT_SECONDS)
	local getTop = network and network:WaitForChild(K.REMOTE_GET_TOP, K.REMOTE_WAIT_SECONDS)
	if getTop == nil then
		warn(LOG_PREFIX .. " Network." .. K.REMOTE_GET_TOP .. " not found: Hero Flap keeps a local best (no leaderboard).")
		return
	end
	fetchBoard(true)
end)

minimizeButton.Activated:Connect(function()
	minimised = true
	playSound(SOUND_FLAP, 0.4, 0.9)
	refreshVisibility()
end)
minimizeButton.MouseEnter:Connect(function()
	if minimizeScale then
		TweenService:Create(minimizeScale, HOVER_INFO, { Scale = 1.12 }):Play()
	end
end)
minimizeButton.MouseLeave:Connect(function()
	if minimizeScale then
		TweenService:Create(minimizeScale, HOVER_INFO, { Scale = 1 }):Play()
	end
end)
phoneButton.Activated:Connect(function()
	minimised = false
	playSound(SOUND_FLAP, 0.4, 1.1)
	refreshVisibility()
end)

libs.Network.Fired(ACTIVE_TREADMILL_EVENT):Connect(function(treadmillId: string?)
	if treadmillId ~= nil then
		activeTreadmillId = treadmillId
		startSession()
	else
		endSession()
		activeTreadmillId = nil
	end
end)
