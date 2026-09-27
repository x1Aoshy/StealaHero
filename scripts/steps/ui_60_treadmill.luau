-- scripts/steps/ui_60_treadmill.luau
-- Build step (TREADMILL owner, VISUAL_PASS_PLAN D4). Runs in the ui_*.luau pass (scripts/build_stealahero.luau
-- step 14b, name order: after ui_40_world, before ui_90_terms), Apply(place, spPlace, ctx).
--
-- 1. REMOVES the TikTok-style treadmill video player, completely:
--      StarterGui  TreadmillVideoSurfaceGui, StaticTreadmillImageSurfaceGui, TreadmillScreenButtonShare,
--                  TreadmillScreenButtonSwapLeft, TreadmillScreenButtonSwapRight, TreadmillScreenComments,
--                  TreadmillScreenFriendLikes, TreadmillScreenSideButtons (the video / cover / comments / likes /
--                  share / swap SurfaceGuis; none holds a script).
--      ReplicatedStorage.Library.Client.TreadmillVideoController's runtime children (FeedSequencer, Media,
--                  VideoFramePool, LikeController, FriendLikesController, CommentsController); the module itself
--                  is an API-compatible no-op (src/.../TreadmillVideoController/init.luau) and keeps Types.
--      ReplicatedStorage.Library.Client.UI.TreadmillStaticCover (the static video cover) and
--                  ReplicatedStorage.Library.Client.VideoCommentsCmds (comments client): nothing requires them any
--                  more, and TreadmillStaticCover would wait forever for StaticTreadmillImageSurfaceGui.
--    The skins' VideoFeedScreen / VideoDecorationPart / SwapLeft / SwapRight parts are removed by
--    scripts/steps/treadmill.luau; this step re-checks every skin. The step errors if any script left in the place
--    still waits for / requires one of the removed names (every Source is scanned), so a hang can never ship.
--    Kept on purpose: TreadmillClickX2, SpeedGainAnimation, RunCharge (not video UI; SpeedGainAnimation is still
--    driven by TreadmillUI), the server's TreadmillMediaFeedState, GUI.luau's lazy accessors (never called now).
--
-- 2. BUILDS the two new treadmill ScreenGuis (Speedsters look: scripts/lib/speedsters_ui_kit.luau materials, ink
--    #0b1b3d strokes, stud texture, glossy vertical gradients, FredokaOne / GothamSSm). Runtime lives in
--    StarterPlayerScripts.GUI.TreadmillTrainingHud and StarterPlayerScripts.GUI.SpeedPhone; the names below are
--    their contract (they look every node up by name and degrade gracefully when one is missing).
--      TreadmillTrainingHud  Card{SpStuds, Inner{Icon, Title, Gain{PopScale}, Multiplier{Value}, Bar{Fill{Shine}, Label},
--                            Floats{FloatTemplate}}}  -- top-centre training card, hidden until a session starts
--      SpeedPhone            Phone{Shadow, Case{CaseStuds, CaseShine, PowerKey, VolumeUp, VolumeDown},
--                                  Bezel{Screen{Game{Clouds, Hills, Pipes{PipeTemplate{Top, Bottom, TopCap, BottomCap}},
--                                  Ground{Studs, Grass}, Bird{Cape, Body, Mask}, Score, Flash, StartScreen{.., TopButton},
--                                  GameOverScreen{.., Rank, TopButton}, PausedScreen, LeaderboardScreen{Title, Status,
--                                  List{Row01..Row10{Rank, Name, Score}, Empty}, You{Rank, Name, Score}, BackButton}},
--                                  StatusBar{Time, Focus, Signal, Battery}, Notch, FocusHint, HomeBar, FullscreenToggle{
--                                  Expand, Shrink}, TapCatcher}}, MinimizeButton{Glyph}}, PhoneButton{Glyph, Label},
--                            FullscreenBackdrop{Hint}, FullscreenButton{Glyph, Label, PopScale}, FullscreenExit{Glyph,
--                            Label, HoverScale}
--    FLAPPY (2026-09-23): FULL SCREEN moves the same Phone into this ScreenGui, centred and ~92% of the screen height,
--    over FullscreenBackdrop (tap anywhere = flap) with FullscreenExit in the top-right corner; FullscreenButton is the
--    big 2D shortcut shown while the phone is on the treadmill's 3D screen. TopButton / BackButton / FullscreenToggle
--    are decorations SpeedPhone hit-tests (like PlayButton), because TapCatcher / the 3D raycast take every tap.
--    Both ScreenGuis: ResetOnSpawn = false (the scripts keep their references across respawns), DisplayOrder 3 (below
--    every window, so an opened window covers them), ZIndexBehavior Sibling.
--    The SpeedPhone's Phone frame is a template for BOTH presentations: at runtime SpeedPhone moves it into a
--    PlayerGui SurfaceGui adorned to the active treadmill's PhoneScreen part (the phone ON the treadmill screen, the
--    normal case), or keeps it in this ScreenGui as the 2D fallback when the treadmill has no PhoneScreen.
--
-- 3. IDLE SCREENS: every skin's PhoneScreen part (added by scripts/steps/treadmill.luau where the video screen was)
--    gets a cheap "HERO FLAP" attract SurfaceGui, IdleScreen (Front face, PixelsPerStud, LightInfluence 0): what
--    every treadmill shows when nobody is playing on it. SpeedPhone disables it locally while its phone is on that
--    screen.

local roblox = require("@lune/roblox")
local Kit = require("../lib/speedsters_ui_kit")

local Instance = roblox.Instance
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2
local Enum = roblox.Enum

local hex = Kit.hex
local C = Kit.Colors

local Step = {}

local LOG_PREFIX = "[StealaHero Build][ui_60_treadmill]"

Step.REMOVED_GUIS = {
	"TreadmillVideoSurfaceGui",
	"StaticTreadmillImageSurfaceGui",
	"TreadmillScreenButtonShare",
	"TreadmillScreenButtonSwapLeft",
	"TreadmillScreenButtonSwapRight",
	"TreadmillScreenComments",
	"TreadmillScreenFriendLikes",
	"TreadmillScreenSideButtons",
}
Step.VIDEO_CONTROLLER_PATH = { "Library", "Client", "TreadmillVideoController" } -- under ReplicatedStorage
Step.VIDEO_CONTROLLER_KEEP = { Types = true }
Step.REMOVED_MODULES = {
	{ "Library", "Client", "UI", "TreadmillStaticCover" },
	{ "Library", "Client", "VideoCommentsCmds" },
}
Step.SKINS_PATH = { "Assets", "Models", "Treadmills" }
Step.VIDEO_PART_NAMES = { "VideoFeedScreen", "VideoDecorationPart", "SwapLeft", "SwapRight" }
-- Code forms (a GUI accessor call, a require path, a quoted name for WaitForChild/FindFirstChild) that would wait
-- forever or error once the instances are gone: any script still containing one fails the step instead.
Step.FORBIDDEN_REFERENCES = {
	"GUI.TreadmillVideoSurfaceGui()", "GUI.StaticTreadmillImageSurfaceGui()", "GUI.TreadmillScreenButtonShare()",
	"GUI.TreadmillScreenButtonSwapLeft()", "GUI.TreadmillScreenButtonSwapRight()", "GUI.TreadmillScreenComments()",
	"GUI.TreadmillScreenFriendLikes()", "GUI.TreadmillScreenSideButtons()",
	"Client.UI.TreadmillStaticCover)", "Client.VideoCommentsCmds)", "Client.VideoCommentsCmds.",
	"TreadmillVideoController.FeedSequencer)", "TreadmillVideoController.Media)", "TreadmillVideoController.VideoFramePool)",
	"TreadmillVideoController.LikeController)", "TreadmillVideoController.FriendLikesController)",
	"TreadmillVideoController.CommentsController)", "TreadmillVideoController.CommentsController.",
	"\"TreadmillVideoSurfaceGui\"", "\"StaticTreadmillImageSurfaceGui\"", "\"TreadmillScreenSideButtons\"",
	"\"TreadmillScreenComments\"", "\"TreadmillScreenFriendLikes\"", "\"TreadmillScreenButtonShare\"",
	"\"TreadmillScreenButtonSwapLeft\"", "\"TreadmillScreenButtonSwapRight\"", "\"VideoFeedScreen\"",
	"\"VideoDecorationPart\"",
}
-- Sources allowed to keep a match (lazy accessors / name sets that never run for a removed GUI).
Step.REFERENCE_WHITELIST = {
	["ReplicatedStorage.Library.Client.GUI"] = true, -- accessor table: functions, called by nobody now
	["ReplicatedStorage.Library.Client.TreadmillVideoController"] = true, -- the no-op module documents what it replaced
	["ReplicatedStorage.Library.Util.TreadmillUtil"] = true, -- FindFirstChild("VideoFeedScreen", true): nil-safe lookups
}

Step.HUD_NAME = "TreadmillTrainingHud"
Step.PHONE_NAME = "SpeedPhone"
Step.DISPLAY_ORDER = 3
Step.PHONE_SCREEN_NAME = "PhoneScreen" -- skin part (scripts/steps/treadmill.luau); SpeedPhone adorns it at runtime
Step.IDLE_SCREEN_NAME = "IdleScreen"
Step.IDLE_PIXELS_PER_STUD = 50
Step.IDLE_MAX_DISTANCE = 90

-- Palette (Speedsters): electric cyan / blue case, green pipes, gold multiplier, ink outlines.
local P = {
	ink = C.ink,
	navy = hex("#13244a"),
	navyDeep = hex("#07132b"),
	cyan = hex("#00fff7"),
	caseTop = hex("#48ecff"),
	caseMid = hex("#0a9dff"),
	caseBottom = hex("#0650cf"),
	bezel = hex("#05070f"),
	skyTop = hex("#3fc8ff"),
	skyBottom = hex("#c9f6ff"),
	ground = hex("#3dbb1b"),
	groundDark = hex("#23800f"),
	grass = hex("#8dff3a"),
	pipeLight = hex("#b6ff5a"),
	pipeMid = hex("#36f800"),
	pipeDark = hex("#0e8a25"),
	gold = hex("#ffd900"),
	orange = hex("#ffa006"),
	red = hex("#ff2d55"),
	white = C.white,
}

---------------------------------------------------------------------------------------------------
-- Small builders (every property written here persists in Lune 0.10.5: FontFace, ImageContent, per-corner radii,
-- ScaledSize strokes via the kit)
---------------------------------------------------------------------------------------------------

local function new(className, name, parent, props)
	local inst = Instance.new(className)
	inst.Name = name
	if props then
		for key, value in pairs(props) do
			(inst :: any)[key] = value
		end
	end
	if inst:IsA("GuiObject") and not (props and props.BorderSizePixel ~= nil) then
		inst.BorderSizePixel = 0
	end
	inst.Parent = parent
	return inst
end

local function frame(name, parent, props)
	local f = new("Frame", name, parent, props)
	if props == nil or props.BackgroundTransparency == nil then
		f.BackgroundTransparency = 1
	end
	return f
end

local function corner(inst, radius)
	return Kit.setCorner(inst, radius)
end

local function aspect(inst, ratio, dominant)
	local a = new("UIAspectRatioConstraint", "SpAspect", inst)
	a.AspectRatio = ratio
	a.AspectType = Enum.AspectType.FitWithinMaxSize
	a.DominantAxis = dominant or Enum.DominantAxis.Width
	return a
end

-- Speedsters text: FontFace per role + Contextual ScaledSize ink outline, TextScaled with a max size.
local function text(name, parent, value, kind, props, opts)
	local label = new("TextLabel", name, parent, props)
	label.BackgroundTransparency = 1
	label.Text = value
	label.TextScaled = true
	label.TextWrapped = true
	opts = opts or {}
	opts.scaled = true
	Kit.styleText(label, kind, opts)
	if opts.maxTextSize then
		new("UITextSizeConstraint", "SpTextSize", label, { MaxTextSize = opts.maxTextSize, MinTextSize = opts.minTextSize or 1 })
	end
	return label
end

local function studs(name, parent, tile, transparency, color, zIndex)
	local img = new("ImageLabel", name, parent, {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(tile, tile),
		ImageTransparency = transparency,
		ImageColor3 = color or P.white,
		ZIndex = zIndex or 1,
	})
	Kit.setImage(img, Kit.Images.stud)
	return img
end

-- Glossy vertical gradient fill on a white Frame (Speedsters buttons/panels: light top -> saturated -> dark bottom).
local function glossy(inst, stops, rotation)
	inst.BackgroundColor3 = P.white
	inst.BackgroundTransparency = 0
	Kit.addGradient(inst, stops, rotation or 90, Kit.Names.fill)
end

local function inkStroke(inst, thickness, opts)
	opts = opts or {}
	opts.thickness = thickness
	opts.color = opts.color or P.ink
	return Kit.addStroke(inst, opts)
end

-- A glossy pill "button" face (Frame + centred label); the phone's taps are caught by TapCatcher, so these are
-- decoration, not GuiButtons.
local function pill(name, parent, label, stops, props, darkStroke)
	local f = frame(name, parent, props)
	glossy(f, stops, 90)
	corner(f, 0.5)
	inkStroke(f, 0.07, { name = Kit.Names.strokeDark, color = darkStroke or P.ink })
	Kit.addStroke(f, {
		name = Kit.Names.strokeLight, thickness = 0.05, color = P.white, borderOffset = -0.12, zIndex = 2, transparency = 0.35,
	})
	text("Label", f, label, "button", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.7), ZIndex = 3,
	}, { strokeThickness = 0.1 })
	return f
end

---------------------------------------------------------------------------------------------------
-- 1. Removal
---------------------------------------------------------------------------------------------------

local function findPath(root, path)
	local node = root
	for _, segment in ipairs(path) do
		node = node and node:FindFirstChild(segment)
	end
	return node
end

local function removeVideoPlayer(place)
	local report = { guis = {}, modules = {}, parts = 0 }
	local starterGui = place:GetService("StarterGui")
	for _, name in ipairs(Step.REMOVED_GUIS) do
		for _, child in ipairs(starterGui:GetChildren()) do
			if child.Name == name then
				for _, d in ipairs(child:GetDescendants()) do
					assert(not d:IsA("LuaSourceContainer"), string.format("%s holds script %s: review before removing", name, d:GetFullName()))
				end
				child:Destroy()
				table.insert(report.guis, name)
			end
		end
	end

	local rs = place:GetService("ReplicatedStorage")
	local controller = findPath(rs, Step.VIDEO_CONTROLLER_PATH)
	if controller then
		for _, child in ipairs(controller:GetChildren()) do
			if not Step.VIDEO_CONTROLLER_KEEP[child.Name] then
				table.insert(report.modules, "TreadmillVideoController." .. child.Name)
				child:Destroy()
			end
		end
		assert(controller:IsA("ModuleScript"), "TreadmillVideoController must stay a ModuleScript")
		local source = controller.Source
		assert(not string.find(source, "require(script.", 1, true) or string.find(source, "require(script.Types", 1, true),
			"TreadmillVideoController still requires a removed child module: the no-op src module was not injected")
		for _, name in ipairs(Step.REMOVED_GUIS) do
			assert(not string.find(source, "GUI." .. name .. "(", 1, true), "TreadmillVideoController still reads " .. name)
		end
	else
		print(LOG_PREFIX .. " WARNING: ReplicatedStorage.Library.Client.TreadmillVideoController not found.")
	end
	for _, path in ipairs(Step.REMOVED_MODULES) do
		local module = findPath(rs, path)
		if module then
			module:Destroy()
			table.insert(report.modules, table.concat(path, "."))
		end
	end

	local skins = findPath(rs, Step.SKINS_PATH)
	local names = {}
	for _, name in ipairs(Step.VIDEO_PART_NAMES) do
		names[name] = true
	end
	for _, tool in ipairs(skins and skins:GetChildren() or {}) do
		for _, d in ipairs(tool:GetDescendants()) do
			if d.Parent ~= nil and names[d.Name] then
				d:Destroy()
				report.parts += 1
			end
		end
	end

	-- No script may still wait for / require a removed instance (GUI.luau accessors are lazy and never called).
	local offenders = {}
	for _, d in ipairs(place:GetDescendants()) do
		if d:IsA("LuaSourceContainer") and not Step.REFERENCE_WHITELIST[d:GetFullName()] then
			local source = d.Source
			for _, needle in ipairs(Step.FORBIDDEN_REFERENCES) do
				if string.find(source, needle, 1, true) then
					table.insert(offenders, d:GetFullName() .. " -> " .. needle)
				end
			end
		end
	end
	assert(#offenders == 0, "scripts still reference the removed video player: " .. table.concat(offenders, "; "))
	return report
end

---------------------------------------------------------------------------------------------------
-- 2a. Training HUD (top-centre card: never over the runner, who stands in the middle of the screen)
---------------------------------------------------------------------------------------------------

local function buildTrainingHud(starterGui)
	local old = starterGui:FindFirstChild(Step.HUD_NAME)
	if old then
		old:Destroy()
	end
	local gui = new("ScreenGui", Step.HUD_NAME, starterGui, {
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = Step.DISPLAY_ORDER,
		Enabled = true,
	})

	-- Card: runtime sizes it in pixels from the viewport height (72-124 px tall, 3.4 : 1).
	local card = frame("Card", gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(354, 104),
		Visible = false,
	})
	-- The stud frame: a glossy electric-blue band with the Speedsters stud texture, the content on a dark glass panel.
	glossy(card, { { 0, "#48ecff" }, { 0.5, "#0a9dff" }, { 1, "#0650cf" } }, 90)
	corner(card, 0.26)
	inkStroke(card, 0.035, { name = Kit.Names.stroke })
	local band = studs("SpStuds", card, 18, 0.72, P.white, 1)
	corner(band, 0.26)

	local inner = frame("Inner", card, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -12, 1, -12),
		BackgroundColor3 = P.navyDeep,
		BackgroundTransparency = 0.12,
		ZIndex = 2,
	})
	corner(inner, 0.24)
	Kit.addGradient(inner, { { 0, "#1b3366" }, { 1, "#07132b" } }, 90, Kit.Names.fill)
	inkStroke(inner, 0.025, { name = Kit.Names.strokeLight, color = P.cyan, transparency = 0.45, position = "Inner" })

	local icon = new("ImageLabel", "Icon", inner, {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.02, 0.44),
		Size = UDim2.fromScale(0.2, 0.74),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 3,
	})
	Kit.setImage(icon, Kit.Icons.speed)
	aspect(icon, 1)

	text("Title", inner, "TRAINING", "body", {
		Position = UDim2.fromScale(0.22, 0.06), Size = UDim2.fromScale(0.44, 0.24), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
	}, { color = P.cyan, strokeThickness = 0.12, maxTextSize = 30 })

	local gain = text("Gain", inner, "+0 SPEED", "heavy", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.22, 0.46),
		Size = UDim2.fromScale(0.54, 0.36),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = P.white,
		ZIndex = 4,
	}, { color = P.white, strokeThickness = 0.09, maxTextSize = 60, gradient = { { 0, "#00fff7" }, { 0.45, "#88ff00" }, { 1, "#ffe30e" } }, gradientRotation = 0 })
	new("UIScale", "PopScale", gain, { Scale = 1 })

	local multi = frame("Multiplier", inner, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.975, 0.1),
		Size = UDim2.fromScale(0.2, 0.46),
		ZIndex = 3,
	})
	glossy(multi, Kit.Gradients.multiplier, 90)
	corner(multi, 0.45)
	inkStroke(multi, 0.07, { name = Kit.Names.strokeDark })
	text("Value", multi, "x1", "title", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.84, 0.8), ZIndex = 4,
	}, { color = P.white, strokeThickness = 0.12, maxTextSize = 40 })

	local bar = frame("Bar", inner, {
		Position = UDim2.fromScale(0.22, 0.7),
		Size = UDim2.fromScale(0.755, 0.2),
		BackgroundColor3 = hex("#030a1a"),
		BackgroundTransparency = 0.1,
		ClipsDescendants = false,
		ZIndex = 3,
	})
	corner(bar, 0.5)
	inkStroke(bar, 0.12, { name = Kit.Names.stroke })
	local fill = frame("Fill", bar, {
		Size = UDim2.fromScale(0, 1),
		ZIndex = 4,
	})
	glossy(fill, { { 0, "#afff03" }, { 0.55, "#4aff1a" }, { 1, "#01c42b" } }, 90)
	corner(fill, 0.5)
	local shine = frame("Shine", fill, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.12),
		Size = UDim2.new(1, -6, 0.32, 0),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 0.55,
		ZIndex = 5,
	})
	corner(shine, 0.5)
	text("Label", bar, "10 / 25", "body", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.96, 1.25), ZIndex = 6,
	}, { color = P.white, strokeThickness = 0.14, maxTextSize = 26 })

	local floats = frame("Floats", inner, { Size = UDim2.fromScale(1, 1), ZIndex = 7 })
	text("FloatTemplate", floats, "+1", "heavy", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromScale(0.3, 0.3),
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = false,
		ZIndex = 8,
	}, { color = hex("#88ff00"), strokeThickness = 0.1, maxTextSize = 34 })

	return gui
end

---------------------------------------------------------------------------------------------------
-- 2b. SpeedPhone (right side, never over the runner; a small phone button when minimised)
---------------------------------------------------------------------------------------------------

local function buildBird(game)
	-- The "hero ball": yellow glossy body, red cape, navy eye mask. Square (aspect 1, sized by the game's height).
	local bird = frame("Bird", game, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.3, 0.42),
		Size = UDim2.fromScale(1, 0.072),
		ZIndex = 20,
	})
	aspect(bird, 1, Enum.DominantAxis.Height)
	local cape = frame("Cape", bird, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.42, 0.56),
		Size = UDim2.fromScale(0.78, 0.62),
		Rotation = -12,
		ZIndex = 20,
	})
	glossy(cape, { { 0, "#ff5a7a" }, { 1, "#c4002d" } }, 90)
	corner(cape, 0.35)
	inkStroke(cape, 0.09, { name = Kit.Names.stroke })
	local body = frame("Body", bird, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 21,
	})
	glossy(body, { { 0, "#fff27a" }, { 0.5, "#ffd900" }, { 1, "#ff9d00" } }, 90)
	corner(body, 0.5)
	inkStroke(body, 0.09, { name = Kit.Names.stroke })
	local bodyShine = frame("Shine", body, {
		Position = UDim2.fromScale(0.2, 0.1),
		Size = UDim2.fromScale(0.32, 0.22),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 0.35,
		ZIndex = 22,
	})
	corner(bodyShine, 0.5)
	local mask = frame("Mask", bird, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.62, 0.42),
		Size = UDim2.fromScale(0.74, 0.26),
		BackgroundColor3 = P.navy,
		BackgroundTransparency = 0,
		ZIndex = 23,
	})
	corner(mask, 0.5)
	for i, x in ipairs({ 0.34, 0.74 }) do
		local eye = frame(i == 1 and "EyeL" or "EyeR", mask, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, 0.5),
			Size = UDim2.fromScale(0.26, 0.72),
			BackgroundColor3 = P.white,
			BackgroundTransparency = 0,
			ZIndex = 24,
		})
		corner(eye, 0.5)
	end
	local emblem = frame("Emblem", bird, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.52, 0.76),
		Size = UDim2.fromScale(0.24, 0.16),
		BackgroundColor3 = P.red,
		BackgroundTransparency = 0,
		Rotation = 8,
		ZIndex = 23,
	})
	corner(emblem, 0.3)
	return bird
end

local function buildPipeTemplate(pipes)
	local pair = frame("PipeTemplate", pipes, {
		Position = UDim2.fromScale(1.2, 0),
		Size = UDim2.fromScale(0.22, 1),
		Visible = false,
		ZIndex = 10,
	})
	local stops = { { 0, "#b6ff5a" }, { 0.35, "#36f800" }, { 1, "#0e8a25" } }
	local function body(name, anchorY, posY, sizeY)
		local b = frame(name, pair, {
			AnchorPoint = Vector2.new(0.5, anchorY),
			Position = UDim2.fromScale(0.5, posY),
			Size = UDim2.fromScale(1, sizeY),
			ZIndex = 10,
		})
		glossy(b, stops, 0) -- horizontal: lit left edge, dark right edge
		inkStroke(b, 0.07, { name = Kit.Names.stroke })
		studs("Studs", b, 14, 0.78, P.white, 11)
		return b
	end
	body("Top", 0, 0, 0.3)
	body("Bottom", 1, 0.88, 0.3)
	local function cap(name, anchorY, posY)
		local c = frame(name, pair, {
			AnchorPoint = Vector2.new(0.5, anchorY),
			Position = UDim2.fromScale(0.5, posY),
			Size = UDim2.fromScale(1.24, 0.05),
			ZIndex = 12,
		})
		glossy(c, stops, 0)
		corner(c, 0.18)
		inkStroke(c, 0.1, { name = Kit.Names.stroke })
		local lip = frame("Lip", c, {
			Position = UDim2.fromScale(0.08, 0.16),
			Size = UDim2.fromScale(0.84, 0.22),
			BackgroundColor3 = P.white,
			BackgroundTransparency = 0.55,
			ZIndex = 13,
		})
		corner(lip, 0.5)
		return c
	end
	cap("TopCap", 1, 0.3)
	cap("BottomCap", 0, 0.58)
	return pair
end

local function overlayScreen(name, parent, dim)
	local screen = frame(name, parent, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = P.navyDeep,
		BackgroundTransparency = dim or 1,
		Visible = false,
		ZIndex = 40,
	})
	return screen
end

-- Speedsters cyan (the sidebar / reopen button family): the TOP PLAYERS pills.
local TOP_BUTTON_STOPS = { { 0, "#00fbff" }, { 0.45, "#0ad2ff" }, { 1, "#0a7cff" } }

-- Full-screen glyph: four white corner brackets, pointing out (Expand: "go full screen") or in (Shrink: "leave full
-- screen"). Square (aspect 1) inside `props`' box.
local function bracketGlyph(name, parent, inward, props, zIndex)
	local glyph = frame(name, parent, props)
	aspect(glyph, 1)
	local length, thickness = 0.4, 0.15
	for _, quadrant in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
		local sx, sy = quadrant[1], quadrant[2]
		local anchor, position
		if inward then
			anchor = Vector2.new(1 - sx, 1 - sy)
			position = UDim2.fromScale(if sx == 0 then 0.42 else 0.58, if sy == 0 then 0.42 else 0.58)
		else
			anchor = Vector2.new(sx, sy)
			position = UDim2.fromScale(sx, sy)
		end
		for _, bar in ipairs({ { "H", UDim2.fromScale(length, thickness) }, { "V", UDim2.fromScale(thickness, length) } }) do
			local b = new("Frame", string.format("Bar%d%d%s", sx, sy, bar[1]), glyph, {
				AnchorPoint = anchor,
				Position = position,
				Size = bar[2],
				BackgroundColor3 = P.white,
				BackgroundTransparency = 0,
				ZIndex = zIndex,
			})
			inkStroke(b, 0.3, { name = Kit.Names.stroke })
		end
	end
	return glyph
end

Step.BOARD_ROWS = 10 -- FlappyService.TOP_COUNT

-- One leaderboard line: Rank | Name | Score (TextScaled + wrapped + FontFace through text()).
local function boardRow(name, parent, props, zIndex, maxText)
	local row = frame(name, parent, props)
	text("Rank", row, "#1", "title", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.02, 0.5), Size = UDim2.fromScale(0.15, 0.78), ZIndex = zIndex,
	}, { color = P.gold, strokeThickness = 0.12, maxTextSize = maxText })
	text("Name", row, "...", "body", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.18, 0.5), Size = UDim2.fromScale(0.54, 0.7),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = zIndex,
	}, { color = P.white, strokeThickness = 0.12, maxTextSize = maxText })
	text("Score", row, "0", "heavy", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.97, 0.5), Size = UDim2.fromScale(0.24, 0.78),
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = zIndex,
	}, { color = hex("#b6ff5a"), strokeThickness = 0.1, maxTextSize = maxText })
	return row
end

-- TOP PLAYERS (Hero Flap leaderboard): reached from the start / game-over screens' TopButton; SpeedPhone fills the
-- rows from FlappyService ("Flappy: GetTop") and hides the unused ones.
local function buildLeaderboardScreen(game)
	local board = overlayScreen("LeaderboardScreen", game, 0.2)
	text("Title", board, "TOP PLAYERS", "heavy", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.155), Size = UDim2.fromScale(0.66, 0.07), ZIndex = 41,
	}, { color = P.white, strokeThickness = 0.08, maxTextSize = 64, gradient = { { 0, "#fff27a" }, { 0.5, "#ffd900" }, { 1, "#ff8a00" } } })
	text("Status", board, "Loading...", "body", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.208), Size = UDim2.fromScale(0.86, 0.034), ZIndex = 41,
	}, { color = P.cyan, strokeThickness = 0.14, maxTextSize = 22 })

	local list = frame("List", board, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.232),
		Size = UDim2.fromScale(0.92, 0.48),
		BackgroundColor3 = P.navyDeep,
		BackgroundTransparency = 0.2,
		ClipsDescendants = true,
		ZIndex = 41,
	})
	corner(list, 0.06)
	inkStroke(list, 0.012, { name = Kit.Names.stroke })
	for i = 1, Step.BOARD_ROWS do
		local row = boardRow(string.format("Row%02d", i), list, {
			Position = UDim2.fromScale(0, (i - 1) / Step.BOARD_ROWS),
			Size = UDim2.fromScale(1, 1 / Step.BOARD_ROWS),
			BackgroundColor3 = P.white,
			BackgroundTransparency = if i % 2 == 1 then 0.9 else 1,
			Visible = false,
			ZIndex = 42,
		}, 43, 26)
		assert(row.Parent == list, "board row not parented")
	end
	text("Empty", list, "No scores yet - be the first!", "body", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.1), Visible = false, ZIndex = 43,
	}, { color = P.white, strokeThickness = 0.14, maxTextSize = 26 })

	-- The local player's own line (always shown: rank in the TOP 10 or "-", and the all-time best)
	local you = boardRow("You", board, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.727),
		Size = UDim2.fromScale(0.92, 0.058),
		ZIndex = 41,
	}, 42, 28)
	glossy(you, TOP_BUTTON_STOPS, 90)
	corner(you, 0.3)
	inkStroke(you, 0.06, { name = Kit.Names.stroke, color = hex("#073d39") })
	you:FindFirstChild("Rank").Text = "-"
	you:FindFirstChild("Name").Text = "YOU"
	you:FindFirstChild("Score").TextColor3 = P.white

	pill("BackButton", board, "BACK", { { 0, "#fff27a" }, { 0.5, "#ffd900" }, { 1, "#ff8a00" } }, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.835), Size = UDim2.fromScale(0.5, 0.068), ZIndex = 41,
	}, hex("#5a3200"))
	return board
end

local function buildGame(screen)
	local game = frame("Game", screen, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		ZIndex = 1,
	})
	Kit.addGradient(game, { { 0, "#3fc8ff" }, { 0.62, "#8fe6ff" }, { 1, "#d8fbff" } }, 90, "Sky")

	local sun = frame("Sun", game, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.8, 0.2),
		Size = UDim2.fromScale(1, 0.1),
		BackgroundColor3 = hex("#fff6b0"),
		BackgroundTransparency = 0.05,
		ZIndex = 2,
	})
	aspect(sun, 1, Enum.DominantAxis.Height)
	corner(sun, 0.5)
	Kit.addStroke(sun, { name = Kit.Names.stroke, thickness = 0.18, color = hex("#fff6b0"), transparency = 0.6 })

	local clouds = frame("Clouds", game, { Size = UDim2.fromScale(1, 1), ZIndex = 3 })
	for i, spec in ipairs({ { 0.15, 0.24, 0.34 }, { 0.62, 0.36, 0.26 }, { 1.05, 0.16, 0.3 } }) do
		local cloud = frame("Cloud" .. i, clouds, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(spec[1], spec[2]),
			Size = UDim2.fromScale(spec[3], spec[3] * 0.24),
			BackgroundColor3 = P.white,
			BackgroundTransparency = 0.1,
			ZIndex = 3,
		})
		corner(cloud, 0.5)
		local puff = frame("Puff", cloud, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.42, 0.5),
			Size = UDim2.fromScale(0.5, 1.2),
			BackgroundColor3 = P.white,
			BackgroundTransparency = 0.1,
			ZIndex = 3,
		})
		corner(puff, 0.5)
	end

	local hills = frame("Hills", game, { Size = UDim2.fromScale(1, 1), ZIndex = 4 })
	for i, spec in ipairs({ { 0.2, 1.1, "#5fd23a" }, { 0.85, 0.9, "#4cc22c" } }) do
		local hill = frame(i == 1 and "HillA" or "HillB", hills, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(spec[1], 0.9),
			Size = UDim2.fromScale(spec[2], 0.3),
			BackgroundColor3 = hex(spec[3]),
			BackgroundTransparency = 0,
			ZIndex = 4,
		})
		corner(hill, 0.5)
		inkStroke(hill, 0.02, { name = Kit.Names.stroke, transparency = 0.5 })
	end

	local pipes = frame("Pipes", game, { Size = UDim2.fromScale(1, 1), ZIndex = 10 })
	buildPipeTemplate(pipes)

	local ground = frame("Ground", game, {
		Position = UDim2.fromScale(0, 0.88),
		Size = UDim2.fromScale(1, 0.12),
		BackgroundColor3 = P.ground,
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		ZIndex = 30,
	})
	Kit.addGradient(ground, { { 0, "#4fd126" }, { 1, "#23800f" } }, 90, Kit.Names.fill)
	local groundStuds = studs("Studs", ground, 16, 0.62, P.white, 31)
	groundStuds.Size = UDim2.new(1, 32, 1, 0) -- two tiles wider: the runtime scrolls it by one tile, seamlessly
	local grass = frame("Grass", ground, {
		Size = UDim2.new(1, 0, 0.16, 0),
		BackgroundColor3 = P.grass,
		BackgroundTransparency = 0,
		ZIndex = 32,
	})
	inkStroke(grass, 0.25, { name = Kit.Names.stroke })

	buildBird(game)

	local score = text("Score", game, "0", "heavy", { -- below the status bar and its focus chip
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.118),
		Size = UDim2.fromScale(0.7, 0.1),
		Visible = false,
		ZIndex = 35,
	}, { color = P.white, strokeThickness = 0.09, maxTextSize = 72 })
	new("UIScale", "PopScale", score, { Scale = 1 })

	frame("Flash", game, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 1,
		ZIndex = 38,
	})

	-- Start screen
	local start = overlayScreen("StartScreen", game, 1)
	start.Visible = true
	text("Title", start, "HERO FLAP", "heavy", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.2), Size = UDim2.fromScale(0.92, 0.12), ZIndex = 41,
	}, { color = P.white, strokeThickness = 0.08, maxTextSize = 80, gradient = { { 0, "#fff27a" }, { 0.5, "#ffd900" }, { 1, "#ff8a00" } } })
	text("Subtitle", start, "Train your thumbs too!", "body", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(0.86, 0.05), ZIndex = 41,
	}, { color = P.white, strokeThickness = 0.14, maxTextSize = 30 })
	pill("PlayButton", start, "TAP TO PLAY", { { 0, "#f2ff00" }, { 0.4877, "#36f800" }, { 1, "#0ea52c" } }, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromScale(0.74, 0.085), ZIndex = 41,
	}, hex("#104300"))
	text("Best", start, "BEST 0", "title", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.685), Size = UDim2.fromScale(0.8, 0.05), ZIndex = 41,
	}, { color = P.gold, strokeThickness = 0.12, maxTextSize = 34 })
	-- Opens the TOP PLAYERS screen (a decoration hit-tested by SpeedPhone, like PlayButton: taps land on TapCatcher)
	pill("TopButton", start, "TOP PLAYERS", TOP_BUTTON_STOPS, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.765), Size = UDim2.fromScale(0.62, 0.068), ZIndex = 41,
	}, hex("#073d39"))
	text("Hint", start, "Tap / Click / Space to flap", "body", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.838), Size = UDim2.fromScale(0.9, 0.04), ZIndex = 41,
	}, { color = P.white, strokeThickness = 0.14, maxTextSize = 24 })

	-- Game over screen
	local over = overlayScreen("GameOverScreen", game, 0.45)
	text("Title", over, "GAME OVER", "heavy", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.2), Size = UDim2.fromScale(0.92, 0.11), ZIndex = 41,
	}, { color = P.white, strokeThickness = 0.08, maxTextSize = 80, gradient = { { 0, "#ff9d9d" }, { 0.5, "#ff2d55" }, { 1, "#c4002d" } } })
	local panel = frame("Panel", over, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.43),
		Size = UDim2.fromScale(0.8, 0.25),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 0.08,
		ZIndex = 41,
	})
	corner(panel, 0.12)
	inkStroke(panel, 0.03, { name = Kit.Names.stroke })
	local panelStuds = studs("Studs", panel, 16, 0.9, P.navy, 41)
	corner(panelStuds, 0.12)
	text("ScoreLabel", panel, "SCORE", "body", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.28, 0.1), Size = UDim2.fromScale(0.44, 0.2), ZIndex = 42,
	}, { color = P.cyan, strokeThickness = 0.14, maxTextSize = 28 })
	text("ScoreValue", panel, "0", "heavy", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.28, 0.34), Size = UDim2.fromScale(0.44, 0.42), ZIndex = 42,
	}, { color = P.white, strokeThickness = 0.09, maxTextSize = 64 })
	text("BestLabel", panel, "BEST", "body", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.72, 0.1), Size = UDim2.fromScale(0.44, 0.2), ZIndex = 42,
	}, { color = P.gold, strokeThickness = 0.14, maxTextSize = 28 })
	text("BestValue", panel, "0", "heavy", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.72, 0.34), Size = UDim2.fromScale(0.44, 0.42), ZIndex = 42,
	}, { color = P.white, strokeThickness = 0.09, maxTextSize = 64 })
	local newBest = frame("NewBest", panel, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.9, 0.02),
		Size = UDim2.fromScale(0.36, 0.26),
		Rotation = 10,
		Visible = false,
		ZIndex = 44,
	})
	glossy(newBest, Kit.Gradients.badge, 90)
	corner(newBest, 0.5)
	inkStroke(newBest, 0.08, { name = Kit.Names.stroke, color = C.badgeStroke })
	text("Label", newBest, "NEW!", "badge", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.78), ZIndex = 45,
	}, { maxTextSize = 30 })
	-- "NEW BEST!" / world rank / score to beat for the TOP 10 (SpeedPhone fills it from FlappyService's reply)
	text("Rank", over, "", "title", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.597), Size = UDim2.fromScale(0.92, 0.05), ZIndex = 41,
	}, { color = P.gold, strokeThickness = 0.12, maxTextSize = 32 })
	pill("RetryButton", over, "RETRY", { { 0, "#f2ff00" }, { 0.4877, "#36f800" }, { 1, "#0ea52c" } }, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.677), Size = UDim2.fromScale(0.6, 0.08), ZIndex = 41,
	}, hex("#104300"))
	pill("TopButton", over, "TOP PLAYERS", TOP_BUTTON_STOPS, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.768), Size = UDim2.fromScale(0.62, 0.068), ZIndex = 41,
	}, hex("#073d39"))
	text("Hint", over, "Tap to try again", "body", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.843), Size = UDim2.fromScale(0.9, 0.04), ZIndex = 41,
	}, { color = P.white, strokeThickness = 0.14, maxTextSize = 24 })

	-- Paused screen (the session ended or a window opened mid-run)
	local paused = overlayScreen("PausedScreen", game, 0.4)
	text("Title", paused, "PAUSED", "heavy", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.8, 0.1), ZIndex = 41,
	}, { color = P.white, strokeThickness = 0.08, maxTextSize = 70, gradient = { { 0, "#48ecff" }, { 1, "#0a9dff" } } })
	text("Hint", paused, "Tap to resume", "body", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.86, 0.05), ZIndex = 41,
	}, { color = P.white, strokeThickness = 0.14, maxTextSize = 28 })

	buildLeaderboardScreen(game)
	return game
end

local function buildStatusBar(screen)
	local bar = frame("StatusBar", screen, {
		Size = UDim2.fromScale(1, 0.055),
		BackgroundColor3 = P.navyDeep,
		BackgroundTransparency = 0.75,
		ZIndex = 60,
	})
	text("Time", bar, "9:41", "title", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.07, 0.55), Size = UDim2.fromScale(0.24, 0.62),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61,
	}, { color = P.white, strokeThickness = 0.08, maxTextSize = 22 })
	-- Focus chip: shown while the game owns Space / ButtonA.
	local focus = frame("Focus", bar, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 1.55),
		Size = UDim2.fromScale(0.44, 0.8),
		Visible = false,
		ZIndex = 62,
	})
	glossy(focus, { { 0, "#f2ff00" }, { 0.4877, "#36f800" }, { 1, "#0ea52c" } }, 90)
	corner(focus, 0.5)
	inkStroke(focus, 0.08, { name = Kit.Names.stroke, color = hex("#104300") })
	text("Label", focus, "SPACE = FLAP", "button", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.72), ZIndex = 63,
	}, { strokeThickness = 0.12, maxTextSize = 18 })
	local signal = frame("Signal", bar, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.72, 0.55),
		Size = UDim2.fromScale(0.11, 0.5),
		ZIndex = 61,
	})
	for i = 1, 4 do
		local h = 0.25 + 0.25 * (i - 1)
		new("Frame", "Bar" .. i, signal, {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale((i - 1) * 0.26, 1),
			Size = UDim2.fromScale(0.18, h),
			BackgroundColor3 = P.white,
			BackgroundTransparency = 0,
			ZIndex = 61,
		})
	end
	local battery = frame("Battery", bar, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.9, 0.55),
		Size = UDim2.fromScale(0.13, 0.46),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 1,
		ZIndex = 61,
	})
	corner(battery, 0.3)
	Kit.addStroke(battery, { name = Kit.Names.stroke, thickness = 0.14, color = P.white })
	local batteryFill = frame("Fill", battery, {
		Position = UDim2.fromScale(0.1, 0.18),
		Size = UDim2.fromScale(0.72, 0.64),
		BackgroundColor3 = hex("#46ff3a"),
		BackgroundTransparency = 0,
		ZIndex = 62,
	})
	corner(batteryFill, 0.25)
	new("Frame", "Tip", battery, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 2, 0.5, 0),
		Size = UDim2.new(0, 2, 0.4, 0),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 0,
		ZIndex = 61,
	})
	return bar
end

local function buildPhone(starterGui)
	local old = starterGui:FindFirstChild(Step.PHONE_NAME)
	if old then
		old:Destroy()
	end
	local gui = new("ScreenGui", Step.PHONE_NAME, starterGui, {
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = Step.DISPLAY_ORDER,
		Enabled = true,
	})

	-- Full screen (FLAPPY): a dim tap-anywhere backdrop under the centred phone (tap / click on it flaps), shown only
	-- while the game is full screen; SpeedPhone raises this ScreenGui's DisplayOrder meanwhile.
	local backdrop = new("TextButton", "FullscreenBackdrop", gui, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = P.white, -- tinted by the navy gradient
		BackgroundTransparency = 0.25,
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		Visible = false,
		ZIndex = 1,
	})
	Kit.addGradient(backdrop, { { 0, "#13244a" }, { 1, "#030a1a" } }, 90, Kit.Names.fill)
	studs("SpStuds", backdrop, 26, 0.92, P.white, 1)
	text("Hint", backdrop, "Tap anywhere to flap", "body", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -20), Size = UDim2.new(0.25, 0, 0.12, 0),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
	}, { color = P.white, strokeThickness = 0.12, maxTextSize = 34 })

	-- Phone: runtime sizes it in pixels from the viewport height (0.49 : 1) and slides it in from the right.
	local phone = frame("Phone", gui, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.845, 0.53),
		Size = UDim2.fromOffset(300, 612),
		Visible = false,
		ZIndex = 2,
	})
	new("UIScale", "OpenScale", phone, { Scale = 1 })

	local shadow = frame("Shadow", phone, {
		Position = UDim2.fromScale(0.035, 0.018),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = hex("#000000"),
		BackgroundTransparency = 0.62,
		ZIndex = 1,
	})
	corner(shadow, 0.15)

	-- Side keys stick out of the case (drawn under it).
	local function key(name, x, y, h)
		local k = frame(name, phone, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(0.035, h),
			ZIndex = 2,
		})
		glossy(k, { { 0, "#0a9dff" }, { 1, "#0648b0" } }, 0)
		corner(k, 0.5)
		inkStroke(k, 0.25, { name = Kit.Names.stroke })
		return k
	end
	key("PowerKey", 1.0, 0.24, 0.1)
	key("VolumeUp", 0.0, 0.2, 0.07)
	key("VolumeDown", 0.0, 0.3, 0.07)

	local case = frame("Case", phone, { Size = UDim2.fromScale(1, 1), ZIndex = 3 })
	glossy(case, { { 0, "#48ecff" }, { 0.45, "#0a9dff" }, { 1, "#0650cf" } }, 90)
	corner(case, 0.15)
	inkStroke(case, 0.022, { name = Kit.Names.strokeDark })
	Kit.addStroke(case, {
		name = Kit.Names.strokeLight, thickness = 0.012, color = P.white, borderOffset = -0.012, zIndex = 2, transparency = 0.3,
		gradient = { { 0, "#ffffff" }, { 0.5, "#9ff6ff" }, { 1, "#2a7bff" } },
	})
	local caseStuds = studs("CaseStuds", case, 18, 0.8, P.white, 3)
	corner(caseStuds, 0.15)
	local caseShine = frame("CaseShine", case, {
		Position = UDim2.fromScale(0.035, 0.02),
		Size = UDim2.fromScale(0.08, 0.96),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 0.6,
		ZIndex = 4,
	})
	corner(caseShine, 0.5)

	local bezel = frame("Bezel", phone, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.95),
		BackgroundColor3 = P.bezel,
		BackgroundTransparency = 0,
		ZIndex = 5,
	})
	corner(bezel, 0.12)
	inkStroke(bezel, 0.012, { name = Kit.Names.stroke })

	local screen = frame("Screen", bezel, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.955, 0.978),
		BackgroundColor3 = P.skyTop,
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		ZIndex = 6,
	})
	corner(screen, 0.07)

	buildGame(screen)
	buildStatusBar(screen)

	-- Full-screen toggle (FLAPPY): a small dark-glass button in the screen's top-right corner, under the status bar.
	-- A decoration hit-tested by SpeedPhone in every presentation (TapCatcher above it in 2D, a raycast in 3D);
	-- Expand shows while docked, Shrink while full screen.
	local toggle = frame("FullscreenToggle", screen, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.965, 0.068),
		Size = UDim2.fromScale(0.14, 0.14),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		BackgroundColor3 = P.navyDeep,
		BackgroundTransparency = 0.3,
		ZIndex = 75,
	})
	corner(toggle, 0.3)
	Kit.addStroke(toggle, { name = Kit.Names.stroke, thickness = 0.06, color = P.white, transparency = 0.35 })
	bracketGlyph("Expand", toggle, false, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6), ZIndex = 76,
	}, 76)
	bracketGlyph("Shrink", toggle, true, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6), Visible = false, ZIndex = 76,
	}, 76)

	local notch = frame("Notch", screen, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.012),
		Size = UDim2.fromScale(0.3, 0.032),
		BackgroundColor3 = P.bezel,
		BackgroundTransparency = 0,
		ZIndex = 70,
	})
	corner(notch, 0.5)
	local lens = frame("Lens", notch, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.78, 0.5),
		Size = UDim2.fromScale(1, 0.46),
		BackgroundColor3 = hex("#1b2f5e"),
		BackgroundTransparency = 0,
		ZIndex = 71,
	})
	aspect(lens, 1, Enum.DominantAxis.Height)
	corner(lens, 0.5)

	local hint = frame("FocusHint", screen, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.965),
		Size = UDim2.fromScale(0.92, 0.042),
		BackgroundColor3 = P.navyDeep,
		BackgroundTransparency = 0.35,
		Visible = false,
		ZIndex = 70,
	})
	corner(hint, 0.5)
	text("Label", hint, "Click outside the phone to jump", "body", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.94, 0.78), ZIndex = 71,
	}, { color = P.white, strokeThickness = 0.12, maxTextSize = 18 })

	local home = frame("HomeBar", screen, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.992),
		Size = UDim2.fromScale(0.34, 0.008),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 0.25,
		ZIndex = 70,
	})
	corner(home, 0.5)

	-- Catches every tap / click on the screen (the minigame's flap). Not selectable: gamepads flap with ButtonA.
	new("TextButton", "TapCatcher", screen, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		ZIndex = 80,
	})

	-- Minimise: a round gold sticker button on the case's top-right corner.
	local minimize = new("TextButton", "MinimizeButton", phone, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.93, 0.03),
		Size = UDim2.fromScale(0.17, 0.17),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 90,
	})
	glossy(minimize, { { 0, "#fff27a" }, { 0.5, "#ffd900" }, { 1, "#ff8a00" } }, 90)
	corner(minimize, 0.5)
	inkStroke(minimize, 0.09, { name = Kit.Names.strokeDark })
	Kit.addStroke(minimize, {
		name = Kit.Names.strokeLight, thickness = 0.06, color = P.white, borderOffset = -0.12, zIndex = 2, transparency = 0.3,
	})
	local glyph = frame("Glyph", minimize, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.5, 0.14),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 0,
		ZIndex = 91,
	})
	corner(glyph, 0.5)
	inkStroke(glyph, 0.3, { name = Kit.Names.stroke })
	new("UIScale", "HoverScale", minimize, { Scale = 1 })

	-- Reopen button (visible while training with the phone minimised): Speedsters cyan sidebar-style square.
	local button = new("TextButton", "PhoneButton", gui, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.845, 0.6),
		Size = UDim2.fromOffset(78, 78),
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 2,
	})
	glossy(button, { { 0, "#00fbff" }, { 0.45, "#0ad2ff" }, { 1, "#0a7cff" } }, 90)
	corner(button, 0.24)
	inkStroke(button, 0.05, { name = Kit.Names.strokeDark, color = hex("#073d39") })
	Kit.addStroke(button, {
		name = Kit.Names.strokeLight, thickness = 0.04, color = P.white, borderOffset = -0.06, zIndex = 2, transparency = 0.2,
		gradient = { { 0, "#00fbff" }, { 0.1127, "#06ffff" }, { 1, "#58e9ff" } },
	})
	local buttonStuds = studs("SpStuds", button, 14, 0.78, P.white, 2)
	corner(buttonStuds, 0.24)
	local mini = frame("Glyph", button, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromScale(0.34, 0.56),
		BackgroundColor3 = P.navy,
		BackgroundTransparency = 0,
		Rotation = -8,
		ZIndex = 3,
	})
	corner(mini, 0.22)
	inkStroke(mini, 0.1, { name = Kit.Names.stroke })
	local miniScreen = frame("Screen", mini, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.76, 0.78),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 0,
		ZIndex = 4,
	})
	Kit.addGradient(miniScreen, { { 0, "#3fc8ff" }, { 1, "#d8fbff" } }, 90, "Sky")
	corner(miniScreen, 0.18)
	local miniBird = frame("Bird", miniScreen, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.42, 0.45),
		Size = UDim2.fromScale(0.5, 0.3),
		BackgroundColor3 = P.gold,
		BackgroundTransparency = 0,
		ZIndex = 5,
	})
	corner(miniBird, 0.5)
	local miniNotch = frame("Notch", mini, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.05),
		Size = UDim2.fromScale(0.34, 0.06),
		BackgroundColor3 = P.bezel,
		BackgroundTransparency = 0,
		ZIndex = 5,
	})
	corner(miniNotch, 0.5)
	text("Label", button, "PLAY", "sidebar", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.84), Size = UDim2.fromScale(0.86, 0.3), ZIndex = 4,
	}, { maxTextSize = 26 })
	new("UIScale", "PopScale", button, { Scale = 1 })

	-- Full-screen shortcut (FLAPPY): while the phone is on the treadmill's 3D screen (where its own toggle can be a
	-- small tap target on a phone), the same spot as PhoneButton offers a big FULL SCREEN button.
	local full = new("TextButton", "FullscreenButton", gui, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.845, 0.6),
		Size = UDim2.fromOffset(78, 78),
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 2,
	})
	glossy(full, TOP_BUTTON_STOPS, 90)
	corner(full, 0.24)
	inkStroke(full, 0.05, { name = Kit.Names.strokeDark, color = hex("#073d39") })
	Kit.addStroke(full, {
		name = Kit.Names.strokeLight, thickness = 0.04, color = P.white, borderOffset = -0.06, zIndex = 2, transparency = 0.2,
		gradient = { { 0, "#00fbff" }, { 0.1127, "#06ffff" }, { 1, "#58e9ff" } },
	})
	local fullStuds = studs("SpStuds", full, 14, 0.78, P.white, 2)
	corner(fullStuds, 0.24)
	bracketGlyph("Glyph", full, false, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.5, 0.5), ZIndex = 4,
	}, 4)
	text("Label", full, "FULL SCREEN", "sidebar", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.84), Size = UDim2.fromScale(0.92, 0.26), ZIndex = 4,
	}, { maxTextSize = 22 })
	new("UIScale", "PopScale", full, { Scale = 1 })

	-- Leaves full screen: a big red pill in the top-right corner, above the backdrop (visible only while full screen).
	local exit = new("TextButton", "FullscreenExit", gui, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 14),
		Size = UDim2.fromOffset(200, 60),
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 3,
	})
	glossy(exit, { { 0, "#ff9d9d" }, { 0.5, "#ff2d55" }, { 1, "#c4002d" } }, 90)
	corner(exit, 0.5)
	inkStroke(exit, 0.06, { name = Kit.Names.strokeDark, color = hex("#4a0010") })
	Kit.addStroke(exit, {
		name = Kit.Names.strokeLight, thickness = 0.04, color = P.white, borderOffset = -0.1, zIndex = 2, transparency = 0.35,
	})
	bracketGlyph("Glyph", exit, true, {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.08, 0.5), Size = UDim2.fromScale(0.26, 0.56), ZIndex = 4,
	}, 4)
	text("Label", exit, "EXIT", "button", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.36, 0.5), Size = UDim2.fromScale(0.56, 0.62),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
	}, { strokeThickness = 0.1, maxTextSize = 40 })
	new("UIScale", "HoverScale", exit, { Scale = 1 })

	return gui
end

---------------------------------------------------------------------------------------------------
-- 3. Idle "HERO FLAP" attract screen on every skin's PhoneScreen (about 30 instances per skin)
---------------------------------------------------------------------------------------------------

local function buildIdleScreen(part)
	for _, child in ipairs(part:GetChildren()) do
		if child.Name == Step.IDLE_SCREEN_NAME then
			child:Destroy()
		end
	end
	local gui = new("SurfaceGui", Step.IDLE_SCREEN_NAME, part, {
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = Step.IDLE_PIXELS_PER_STUD,
		LightInfluence = 0,
		Brightness = 1,
		MaxDistance = Step.IDLE_MAX_DISTANCE,
		AlwaysOnTop = false,
		ClipsDescendants = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Active = false,
		Enabled = true,
	})

	-- A dimmed phone display inside the dark bezel (the part itself).
	local display = frame("Display", gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.86, 0.95),
		BackgroundColor3 = P.white,
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		ZIndex = 1,
	})
	Kit.addGradient(display, { { 0, "#1f7fe0" }, { 0.65, "#0f4aa8" }, { 1, "#082a66" } }, 90, "Sky")
	corner(display, 0.08)
	inkStroke(display, 0.012, { name = Kit.Names.stroke, color = P.cyan, transparency = 0.4 })

	text("Logo", display, "HERO FLAP", "heavy", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.19), Size = UDim2.fromScale(0.9, 0.22), ZIndex = 5,
	}, { color = P.white, strokeThickness = 0.08, gradient = { { 0, "#fff27a" }, { 0.5, "#ffd900" }, { 1, "#ff8a00" } } })

	local ground = frame("Ground", display, {
		Position = UDim2.fromScale(0, 0.84),
		Size = UDim2.fromScale(1, 0.16),
		BackgroundColor3 = P.ground,
		BackgroundTransparency = 0,
		ZIndex = 2,
	})
	Kit.addGradient(ground, { { 0, "#4fd126" }, { 1, "#23800f" } }, 90, Kit.Names.fill)
	frame("Grass", ground, { Size = UDim2.new(1, 0, 0.14, 0), BackgroundColor3 = P.grass, BackgroundTransparency = 0, ZIndex = 3 })

	local pipe = frame("Pipe", display, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.76, 0.84),
		Size = UDim2.fromScale(0.2, 0.26),
		ZIndex = 2,
	})
	glossy(pipe, { { 0, "#b6ff5a" }, { 0.35, "#36f800" }, { 1, "#0e8a25" } }, 0)
	inkStroke(pipe, 0.05, { name = Kit.Names.stroke })
	local cap = frame("Cap", pipe, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(1.24, 0.18),
		ZIndex = 3,
	})
	glossy(cap, { { 0, "#b6ff5a" }, { 0.35, "#36f800" }, { 1, "#0e8a25" } }, 0)
	corner(cap, 0.18)
	inkStroke(cap, 0.08, { name = Kit.Names.stroke })

	-- The hero ball (the game's Bird look, simplified).
	local bird = frame("Bird", display, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.36, 0.5),
		Size = UDim2.fromScale(1, 0.13),
		ZIndex = 4,
	})
	aspect(bird, 1, Enum.DominantAxis.Height)
	local cape = frame("Cape", bird, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.42, 0.56),
		Size = UDim2.fromScale(0.78, 0.62),
		Rotation = -12,
		ZIndex = 4,
	})
	glossy(cape, { { 0, "#ff5a7a" }, { 1, "#c4002d" } }, 90)
	corner(cape, 0.35)
	local body = frame("Body", bird, { Size = UDim2.fromScale(1, 1), ZIndex = 5 })
	glossy(body, { { 0, "#fff27a" }, { 0.5, "#ffd900" }, { 1, "#ff9d00" } }, 90)
	corner(body, 0.5)
	inkStroke(body, 0.08, { name = Kit.Names.stroke })
	local mask = frame("Mask", bird, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.62, 0.42),
		Size = UDim2.fromScale(0.74, 0.26),
		BackgroundColor3 = P.navy,
		BackgroundTransparency = 0,
		ZIndex = 6,
	})
	corner(mask, 0.5)

	text("Hint", display, "RUN HERE TO PLAY!", "body", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.925), Size = UDim2.fromScale(0.9, 0.08), ZIndex = 5,
	}, { color = P.white, strokeThickness = 0.14 })
	return gui
end

local function buildIdleScreens(place)
	local skins = findPath(place:GetService("ReplicatedStorage"), Step.SKINS_PATH)
	local built, missing = 0, {}
	for _, tool in ipairs(skins and skins:GetChildren() or {}) do
		local part = tool:FindFirstChild(Step.PHONE_SCREEN_NAME)
		if part and part:IsA("BasePart") then
			local gui = buildIdleScreen(part)
			for _, d in ipairs(gui:GetDescendants()) do
				if d:IsA("TextLabel") then
					assert(d.TextScaled and d.TextWrapped and d.FontFace ~= nil, d:GetFullName() .. ": idle text must be scaled + wrapped with a FontFace")
				end
			end
			built += 1
		else
			table.insert(missing, tool.Name)
		end
	end
	return built, missing
end

---------------------------------------------------------------------------------------------------
-- Verification (the runtime scripts rely on these paths)
---------------------------------------------------------------------------------------------------

local REQUIRED_PATHS = {
	[Step.HUD_NAME] = {
		"Card", "Card/SpStuds", "Card/Inner/Icon", "Card/Inner/Title", "Card/Inner/Gain", "Card/Inner/Gain/PopScale",
		"Card/Inner/Multiplier/Value", "Card/Inner/Bar/Fill", "Card/Inner/Bar/Label",
		"Card/Inner/Floats/FloatTemplate",
	},
	[Step.PHONE_NAME] = {
		"Phone", "Phone/OpenScale", "Phone/Case", "Phone/Bezel/Screen/Game", "Phone/Bezel/Screen/Game/Pipes/PipeTemplate/Top",
		"Phone/Bezel/Screen/Game/Pipes/PipeTemplate/Bottom", "Phone/Bezel/Screen/Game/Pipes/PipeTemplate/TopCap",
		"Phone/Bezel/Screen/Game/Pipes/PipeTemplate/BottomCap", "Phone/Bezel/Screen/Game/Ground/Studs",
		"Phone/Bezel/Screen/Game/Bird/Cape", "Phone/Bezel/Screen/Game/Bird/Body", "Phone/Bezel/Screen/Game/Clouds",
		"Phone/Bezel/Screen/Game/Score/PopScale", "Phone/Bezel/Screen/Game/Flash", "Phone/Bezel/Screen/Game/StartScreen/Best",
		"Phone/Bezel/Screen/Game/StartScreen/Hint", "Phone/Bezel/Screen/Game/StartScreen/PlayButton",
		"Phone/Bezel/Screen/Game/GameOverScreen/Panel/ScoreValue", "Phone/Bezel/Screen/Game/GameOverScreen/Panel/BestValue",
		"Phone/Bezel/Screen/Game/GameOverScreen/Panel/NewBest", "Phone/Bezel/Screen/Game/GameOverScreen/Hint",
		"Phone/Bezel/Screen/Game/PausedScreen", "Phone/Bezel/Screen/StatusBar/Time", "Phone/Bezel/Screen/StatusBar/Focus/Label",
		"Phone/Bezel/Screen/FocusHint/Label", "Phone/Bezel/Screen/TapCatcher", "Phone/MinimizeButton", "PhoneButton",
		"PhoneButton/PopScale",
		-- FLAPPY: full screen + TOP PLAYERS
		"Phone/Bezel/Screen/FullscreenToggle/Expand", "Phone/Bezel/Screen/FullscreenToggle/Shrink",
		"Phone/Bezel/Screen/Game/StartScreen/TopButton", "Phone/Bezel/Screen/Game/GameOverScreen/TopButton",
		"Phone/Bezel/Screen/Game/GameOverScreen/Rank", "Phone/Bezel/Screen/Game/LeaderboardScreen/Status",
		"Phone/Bezel/Screen/Game/LeaderboardScreen/List/Row01/Rank", "Phone/Bezel/Screen/Game/LeaderboardScreen/List/Row01/Name",
		"Phone/Bezel/Screen/Game/LeaderboardScreen/List/Row10/Score", "Phone/Bezel/Screen/Game/LeaderboardScreen/List/Empty",
		"Phone/Bezel/Screen/Game/LeaderboardScreen/You/Rank", "Phone/Bezel/Screen/Game/LeaderboardScreen/You/Score",
		"Phone/Bezel/Screen/Game/LeaderboardScreen/BackButton", "FullscreenBackdrop/Hint", "FullscreenExit/Label",
		"FullscreenButton/PopScale", "FullscreenButton/Label",
	},
}

local function verify(gui)
	for _, path in ipairs(REQUIRED_PATHS[gui.Name]) do
		local node = gui
		for _, segment in ipairs(string.split(path, "/")) do
			node = node and node:FindFirstChild(segment)
		end
		assert(node ~= nil, gui.Name .. ": missing " .. path)
	end
	local count, texts = 0, 0
	for _, d in ipairs(gui:GetDescendants()) do
		count += 1
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			texts += 1
			assert(d.FontFace ~= nil, d:GetFullName() .. ": no FontFace")
		end
		assert(not d:IsA("LuaSourceContainer"), d:GetFullName() .. ": templates hold no scripts")
	end
	return count, texts
end

function Step.Apply(place, _spPlace, _ctx)
	local report = removeVideoPlayer(place)
	print(string.format("%s D4 video player removed: %d SurfaceGuis (%s), %d modules (%s), %d leftover skin video parts; no script references it.",
		LOG_PREFIX, #report.guis, table.concat(report.guis, ", "), #report.modules, table.concat(report.modules, ", "), report.parts))

	local starterGui = place:GetService("StarterGui")
	local hud = buildTrainingHud(starterGui)
	local hudCount = verify(hud)
	local phone = buildPhone(starterGui)
	local phoneCount, phoneTexts = verify(phone)
	print(string.format("%s built StarterGui.%s (%d instances: top-centre training card) and StarterGui.%s (%d instances, %d texts: phone + Hero Flap minigame + reopen button).",
		LOG_PREFIX, Step.HUD_NAME, hudCount, Step.PHONE_NAME, phoneCount, phoneTexts))

	local idle, noScreen = buildIdleScreens(place)
	print(string.format("%s %d treadmill skins carry a %s with the idle HERO FLAP %s (the phone renders there while training).",
		LOG_PREFIX, idle, Step.PHONE_SCREEN_NAME, Step.IDLE_SCREEN_NAME))
	if #noScreen > 0 then
		print(string.format("%s WARNING: %d skin(s) without a %s use the 2D SpeedPhone fallback: %s",
			LOG_PREFIX, #noScreen, Step.PHONE_SCREEN_NAME, table.concat(noScreen, ", ")))
	end
	return report
end

return Step
