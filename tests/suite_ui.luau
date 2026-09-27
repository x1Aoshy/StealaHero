--!nocheck
-- UI: HUD layout (left-edge tool pills centred vertically, right-edge icon tabs, bottom-left currency ribbons),
-- Speedsters window material, and the script
-- contracts the re-skin must never break (Close buttons, ConsoleButtons, no extra UIScales on buttons). Visual pass
-- (docs/VISUAL_PASS_PLAN.md): D4 treadmill video player removed + training HUD + SpeedPhone (Hero Flap), D5 StageArt
-- and the Index stage cards, D6 Free Gift opener script, D7 HUD pills / sidebar buttons / night timer, Sell Heroes and
-- Free Gift windows, no group-join prompt, "Heroes" in every user-facing text.

local place = H.place()
local sg = place:GetService("StarterGui")
local Enum = H.roblox.Enum
local PLAN = H.PLAN

local SPEEDSTERS_WINDOW_ART = { [106477372921851] = true, [91870898439604] = true }
local EGG_ICON, INDEX_ICON, CLOSE_ART = 96783034607256, 140189242202677, 110882579806743

-- HUD tabs: icon-first, egg + index icons visible, captions kept
local tabs = H.path(sg, "Elements/Tabs")
local function visibleIcon(button, wanted)
	for _, d in ipairs(button:GetDescendants()) do
		if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and H.imageId(d) == wanted and d.Visible and d.ImageTransparency < 0.5 then
			return d
		end
	end
	return nil
end
-- owner 2026-09-23: EGGS shows the minimalist Steal an Egg egg; HERO INDEX shows no icon until the owner's own icon
-- (ui_30_hud HERO_TAB_ICON) is uploaded
for _, spec in ipairs({ { "GrowingEggs", EGG_ICON, "EGGS" }, { "Pets", nil, "HERO INDEX" } }) do
	local tab = tabs and tabs:FindFirstChild(spec[1])
	if T.check(tab ~= nil, "Elements.Tabs.%s missing", spec[1]) then
		if spec[2] then
			T.check(visibleIcon(tab, spec[2]) ~= nil, "tab %s must show its icon %d", spec[1], spec[2])
		end
		local plate = tab:FindFirstChild("SpIconPlate")
		T.check(plate == nil or not plate.Visible, "tab %s must not show the sticker plate (minimalist icon)", spec[1])
		local label = tab:FindFirstChild("Label")
		T.check(label ~= nil and label.Text == spec[3], "tab %s caption must read %q", spec[1], spec[3])
	end
end

if tabs then
	T.check(tabs.Position.X.Scale > 0.8 and tabs.AnchorPoint.X > 0.5, "Elements.Tabs must hang on the right edge (X scale %.2f)", tabs.Position.X.Scale)
end

-- HUD tools: stacked vertically on the left edge, vertically centred (clear of the Roblox topbar), icon + label
local left = H.path(sg, "Elements/Left")
local tools = left and left:FindFirstChild("Tools")
if T.check(tools ~= nil, "Elements.Left.Tools missing") then
	local layout = tools:FindFirstChildOfClass("UIListLayout")
	T.check(layout ~= nil and layout.FillDirection == Enum.FillDirection.Vertical, "Left.Tools must stack vertically")
	T.check(layout ~= nil and layout.VerticalAlignment == Enum.VerticalAlignment.Center,
		"Left.Tools must centre its visible pills vertically (UIListLayout.VerticalAlignment Center)")
	T.check(left.Position.X.Scale < 0.1 and math.abs(left.Position.Y.Scale - 0.5) < 1e-3 and math.abs(left.AnchorPoint.Y - 0.5) < 1e-3,
		"Elements.Left must sit on the left edge, vertically centred (AnchorPoint Y 0.5 at Y scale 0.5)")
	for _, name in ipairs({ "Shop", "Index" }) do
		local tool = tools:FindFirstChild(name)
		if T.check(tool ~= nil, "Left.Tools.%s missing", name) then
			local hasIcon = false
			for _, d in ipairs(tool:GetDescendants()) do
				if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Visible and H.imageId(d) and string.find(d.Name, "Icon") then
					hasIcon = true
				end
			end
			T.check(hasIcon, "tool %s must show an icon", name)
		end
	end
end

-- Speedsters window material on the tab windows
for _, name in ipairs({ "Shop", "Index", "Settings", "GroupReward", "AutoSell", "TrailShop", "TreadmillSpeedShop", "Message", "StealDnaMessage", "PetList", "Rebirth" }) do
	local gui = sg:FindFirstChild(name)
	if T.check(gui ~= nil, "StarterGui.%s missing", name) then
		local art = false
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("ImageLabel") and SPEEDSTERS_WINDOW_ART[H.imageId(d) or 0] then
				art = true
				break
			end
		end
		T.check(art, "window %s must use the Speedsters window art", name)
	end
end

-- Script contracts (ConsoleCmds asserts these at runtime; a violation breaks tab opening). Only regressions
-- count: Close buttons that already lacked the child in the base place are pre-existing and left alone.
local legacyClose = {}
local basePlace = H.basePlace()
for _, d in ipairs(basePlace and basePlace:GetService("StarterGui"):GetDescendants() or {}) do
	if d:IsA("GuiButton") and d.Name == "Close" then
		local child = d:FindFirstChild("TextButton")
		if not ((child and child:IsA("ImageLabel")) or (d:FindFirstChild("TextLabel") and d.TextLabel:IsA("TextLabel"))) then
			legacyClose[d:GetFullName()] = true
		end
	end
end
local closeArt = 0
for _, d in ipairs(sg:GetDescendants()) do
	if d:IsA("GuiButton") and d.Name == "Close" then
		local child = d:FindFirstChild("TextButton")
		local ok = (child and child:IsA("ImageLabel")) or (d:FindFirstChild("TextLabel") and d.TextLabel:IsA("TextLabel"))
		T.check(ok or legacyClose[d:GetFullName()], "%s: Close button needs its TextButton ImageLabel (or TextLabel) child", d:GetFullName())
		if child and child:IsA("ImageLabel") and H.imageId(child) == CLOSE_ART then
			closeArt += 1
		end
	elseif d:IsA("GuiObject") and d.Name == "ConsoleButton" then
		T.check(type(d:GetAttribute("ConsoleButton")) == "string", "%s: ConsoleButton needs its string attribute", d:GetFullName())
		T.check(d:FindFirstAncestorWhichIsA("GuiButton") ~= nil, "%s: ConsoleButton needs a GuiButton ancestor", d:GetFullName())
	end
end
T.check(closeArt >= 5, "expected the Speedsters close art on >= 5 Close buttons, found %d", closeArt)

-- No UIScale added directly under buttons (ButtonFX owns button scale)
-- (SpeedPhone, PHONE 2026-09-23, never goes through ButtonFX: its client tweens its own HoverScale / PopScale)
local function buttonScales(root)
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("UIScale") and d.Parent and d.Parent:IsA("GuiButton")
			and not ((d.Name == "HoverScale" or d.Name == "PopScale") and string.find(d:GetFullName(), "SpeedPhone.", 1, true)) then
			n += 1
		end
	end
	return n
end
local base = H.basePlace()
if base then
	local before, after = buttonScales(base:GetService("StarterGui")), buttonScales(sg)
	T.check(after <= before, "UIScales under buttons grew from %d to %d (ButtonFX owns button scale)", before, after)
end

-- Juice / window animation scripts are injected
local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
T.check(sps and sps:FindFirstChild("SpeedstersJuice", true) ~= nil, "SpeedstersJuice LocalScript missing")
T.check(H.path(place.ReplicatedStorage, "Library/Client/TabController") ~= nil, "TabController missing")

---------------------------------------------------------------------------------------------------
-- Visual pass (docs/VISUAL_PASS_PLAN.md D4, D5, D6, D7): shared helpers
---------------------------------------------------------------------------------------------------
local rs = place.ReplicatedStorage
local UDim = H.roblox.UDim
local function hex(c)
	return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
-- Source without `--` comments (line comments and --[[ ]] blocks): what actually runs.
local function codeOnly(source)
	local s = H.normalize(source)
	s = string.gsub(s, "%-%-%[(=*)%[.-%]%1%]", "")
	s = string.gsub(s, "%-%-[^\n]*", "")
	return s
end
local function isClass(inst, className)
	return inst ~= nil and inst:IsA(className)
end
local function allCorners(corner, udim)
	return corner ~= nil and corner.TopLeftRadius == udim and corner.TopRightRadius == udim and corner.BottomLeftRadius == udim and corner.BottomRightRadius == udim
end
local function hasStop(gradient, color, interiorOnly)
	if not (gradient and gradient:IsA("UIGradient")) then
		return false
	end
	local kp = gradient.Color.Keypoints
	for i, k in ipairs(kp) do
		if (not interiorOnly or (i > 1 and i < #kp)) and hex(k.Value) == color then
			return true
		end
	end
	return false
end
local function checkLocalScript(path, srcPath)
	local node = sps and H.path(sps, path)
	if T.check(node ~= nil and node.ClassName == "LocalScript", "StarterPlayerScripts.%s (LocalScript) missing", path) then
		T.check(pcall(H.luau.compile, node.Source), "StarterPlayerScripts.%s does not compile", path)
		if srcPath then
			T.check(H.fs.isFile(srcPath) and H.normalize(node.Source) == H.normalize(H.fs.readFile(srcPath)), "StarterPlayerScripts.%s Source differs from %s (rebuild)", path, srcPath)
		end
	end
	return node
end

---------------------------------------------------------------------------------------------------
-- D4 treadmill: the TikTok-style video player is gone without waits/errors; training HUD + SpeedPhone replace it
---------------------------------------------------------------------------------------------------
for _, name in ipairs({ "TreadmillVideoSurfaceGui", "StaticTreadmillImageSurfaceGui", "TreadmillScreenButtonShare", "TreadmillScreenButtonSwapLeft",
	"TreadmillScreenButtonSwapRight", "TreadmillScreenComments", "TreadmillScreenFriendLikes", "TreadmillScreenSideButtons" }) do
	T.check(sg:FindFirstChild(name) == nil, "StarterGui.%s must be removed (D4: no video player)", name)
end
local videoController = H.path(rs, "Library/Client/TreadmillVideoController")
if T.check(videoController ~= nil and videoController:IsA("ModuleScript"), "Library.Client.TreadmillVideoController (ModuleScript stub) missing") then
	local children = {}
	for _, c in ipairs(videoController:GetChildren()) do
		table.insert(children, c.Name)
	end
	T.check(#children == 1 and children[1] == "Types" and H.path(videoController, "Types/Interface") ~= nil and H.path(videoController, "Types/Schema") ~= nil,
		"TreadmillVideoController must keep only Types (Interface, Schema), found {%s}", table.concat(children, ", "))
	local code = codeOnly(videoController.Source)
	local requires = {}
	for target in string.gmatch(code, "require%(%s*script%.([%w_]+)") do
		if target ~= "Types" then
			table.insert(requires, target)
		end
	end
	T.check(#requires == 0, "TreadmillVideoController still requires removed children: %s", table.concat(requires, ", "))
	T.check(not string.find(code, "GUI%.Treadmill%w*%(") and not string.find(code, "GUI%.StaticTreadmill%w*%("), "TreadmillVideoController must not open the treadmill SurfaceGuis")
end
T.check(H.path(rs, "Library/Client/UI/TreadmillStaticCover") == nil and H.path(rs, "Library/Client/VideoCommentsCmds") == nil,
	"Library.Client.UI.TreadmillStaticCover and Library.Client.VideoCommentsCmds must be removed (D4)")
do
	local REMOVED = { "CommentsController", "FeedSequencer", "FriendLikesController", "VideoFramePool", "TreadmillStaticCover", "VideoCommentsCmds",
		"TreadmillVideoController.LikeController", "TreadmillVideoController.Media", "TreadmillVideoController:WaitForChild(\"Media\")" }
	local offenders = {}
	for fullName, source in pairs(H.allSources()) do
		if fullName ~= "ReplicatedStorage.Library.Client.GUI" then
			local code = codeOnly(source)
			if string.find(code, "GUI%.TreadmillVideoSurfaceGui%(") or string.find(code, "GUI%.StaticTreadmillImageSurfaceGui%(") or string.find(code, "GUI%.TreadmillScreen%w*%(") then
				table.insert(offenders, fullName .. " (treadmill SurfaceGui call)")
			end
			for line in string.gmatch(code .. "\n", "([^\n]*)\n") do
				if H.has(line, "require") then
					for _, name in ipairs(REMOVED) do
						if H.has(line, name) then
							table.insert(offenders, fullName .. " (requires " .. name .. ")")
						end
					end
				end
			end
		end
	end
	T.check(#offenders == 0, "D4: scripts still use the removed video player: %s", table.concat(offenders, ", ", 1, math.min(#offenders, 5)))
end

local function screenGui(name)
	local gui = sg:FindFirstChild(name)
	if T.check(gui ~= nil and gui:IsA("ScreenGui"), "StarterGui.%s (ScreenGui) missing (D4)", name) then
		T.check(gui.ResetOnSpawn == false, "StarterGui.%s must keep ResetOnSpawn = false", name)
		T.check(H.countClass(gui, "LuaSourceContainer") == 0, "StarterGui.%s is a template: no scripts inside", name)
		return gui
	end
	return nil
end
local hud = screenGui("TreadmillTrainingHud")
if hud then
	for _, p in ipairs({ "Card/Inner/Gain/PopScale", "Card/Inner/Multiplier/Value", "Card/Inner/Bar/Fill", "Card/Inner/Bar/Label", "Card/Inner/Floats/FloatTemplate" }) do
		T.check(H.path(hud, p) ~= nil, "TreadmillTrainingHud.%s missing (the HUD script reads it)", p)
	end
end
local phoneGui = screenGui("SpeedPhone")
if phoneGui then
	for _, p in ipairs({ "Phone/Bezel/Screen/Game/Pipes/PipeTemplate/Top", "Phone/Bezel/Screen/Game/Pipes/PipeTemplate/Bottom",
		"Phone/Bezel/Screen/Game/Pipes/PipeTemplate/TopCap", "Phone/Bezel/Screen/Game/Pipes/PipeTemplate/BottomCap", "Phone/Bezel/Screen/Game/Bird",
		"Phone/Bezel/Screen/Game/StartScreen", "Phone/Bezel/Screen/Game/GameOverScreen", "Phone/Bezel/Screen/Game/PausedScreen", "Phone/Bezel/Screen/TapCatcher",
		"Phone/MinimizeButton", "PhoneButton" }) do
		T.check(H.path(phoneGui, p) ~= nil, "SpeedPhone.%s missing (the phone script reads it)", p)
	end
	local game = H.path(phoneGui, "Phone/Bezel/Screen/Game")
	T.check(game ~= nil and game.ClipsDescendants == true, "SpeedPhone game screen must clip its pipes (ClipsDescendants)")
end
checkLocalScript("GUI/TreadmillTrainingHud", "src/StarterPlayer/StarterPlayerScripts/GUI/TreadmillTrainingHud.client.luau")
local phoneScript = checkLocalScript("GUI/SpeedPhone", "src/StarterPlayer/StarterPlayerScripts/GUI/SpeedPhone.client.luau")
if phoneScript then
	local psrc = phoneScript.Source
	for _, token in ipairs({ "ACTIVE_TREADMILL_EVENT", "BindActionAtPriority", "Enum.KeyCode.Space", "Enum.KeyCode.ButtonA", "UnbindAction", "RenderStepped" }) do
		T.check(H.has(psrc, token), "SpeedPhone must contain %s (shown while training, Space/ButtonA flap, per-frame game loop)", token)
	end
	-- behaviour (sandboxed): Lune's luau.load copies the environment table, so the script's upvalues are rebuilt as
	-- locals of a factory and every case gets a fresh closure over the state it needs.
	local function factory(label, prelude, body, returns)
		local chunk, err = H.sandbox("return function(S)\n" .. prelude .. "\n" .. body .. "\nreturn " .. returns .. "\nend", { Enum = Enum }, label)
		local ok, make = false, err
		if chunk then
			ok, make = pcall(chunk)
		end
		if T.check(ok and type(make) == "function", "%s does not load: %s", label, tostring(make)) then
			return make
		end
		return nil
	end
	-- the flap action flaps only while the phone is shown and focused, and sinks the key (Begin and End) then
	local body = H.extractFunction(psrc, "flapAction")
	local makeFlapAction = T.check(body ~= nil, "SpeedPhone: local function flapAction missing")
		and factory("SpeedPhone.flapAction", "local focused, phoneShown, onFlapInput, setFocused = S.focused, S.phoneShown, S.onFlapInput, S.setFocused", body, "flapAction")
	if makeFlapAction then
		local function press(focused, shown, keyCode, inputState)
			local S = { focused = focused, phoneShown = shown, flaps = 0, unfocused = 0 }
			S.onFlapInput = function()
				S.flaps += 1
			end
			S.setFocused = function(value)
				if value == false then
					S.unfocused += 1
				end
			end
			local okCall, result = pcall(makeFlapAction(S), "SpeedPhoneFlap", inputState or Enum.UserInputState.Begin, { KeyCode = keyCode })
			return if okCall then result else nil, S
		end
		local r, S = press(false, false, Enum.KeyCode.Space)
		T.check(r == Enum.ContextActionResult.Pass and S.flaps == 0, "SpeedPhone: Space must pass through (jump) while the phone is hidden")
		r, S = press(false, true, Enum.KeyCode.Space)
		T.check(r == Enum.ContextActionResult.Pass and S.flaps == 0, "SpeedPhone: Space must pass through while the game is not focused")
		r, S = press(true, true, Enum.KeyCode.Space)
		T.check(r == Enum.ContextActionResult.Sink and S.flaps == 1, "SpeedPhone: Space must flap and be sunk while focused")
		r, S = press(true, true, Enum.KeyCode.ButtonA)
		T.check(r == Enum.ContextActionResult.Sink and S.flaps == 1, "SpeedPhone: ButtonA must flap and be sunk while focused")
		r, S = press(true, true, Enum.KeyCode.Space, Enum.UserInputState.End)
		T.check(r == Enum.ContextActionResult.Sink and S.flaps == 0, "SpeedPhone: releasing Space must be sunk (no half jump) without flapping again")
		r, S = press(true, true, Enum.KeyCode.ButtonB)
		T.check(r == Enum.ContextActionResult.Sink and S.unfocused == 1 and S.flaps == 0, "SpeedPhone: ButtonB must leave the game focus")
	end
	-- the flap input drives the Ready -> Playing -> Paused / Over state machine
	local normalized = H.normalize(psrc)
	local start = string.find(normalized, "\nfunction onFlapInput%(%)")
	local finish = start and string.find(normalized, "\nend\n", start + 1, true)
	local makeOnFlap = T.check(start ~= nil and finish ~= nil, "SpeedPhone: function onFlapInput missing")
		and factory("SpeedPhone.onFlapInput", table.concat({
			"local phoneShown, state, clock, overAt, lastInputAt = S.phoneShown, S.state, S.clock, S.overAt, 0",
			"local RETRY_DELAY = S.RETRY_DELAY",
			"local function startRun() table.insert(S.log, \"start\"); state = \"Playing\" end",
			"local function flap() table.insert(S.log, \"flap\") end",
			"local function showScreen(name) table.insert(S.log, \"screen:\" .. tostring(name)) end",
			"local onFlapInput",
		}, "\n"), string.sub(normalized, start + 1, finish + 4), "onFlapInput, function() return state end")
	if makeOnFlap then
		local retry = H.constant(psrc, "RETRY_DELAY") or 0.4
		local function tap(shown, state, clock, overAt)
			local S = { phoneShown = shown, state = state, clock = clock or 10, overAt = overAt or 0, RETRY_DELAY = retry, log = {} }
			local onFlapInput, stateOf = makeOnFlap(S)
			local okTap, err = pcall(onFlapInput)
			T.check(okTap, "SpeedPhone onFlapInput failed: %s", tostring(err))
			return table.concat(S.log, ","), stateOf()
		end
		local log, state = tap(true, "Ready")
		T.check(log == "start" and state == "Playing", "SpeedPhone: a tap on the ready screen starts a run (got %s -> %s)", log, tostring(state))
		log, state = tap(true, "Playing")
		T.check(log == "flap" and state == "Playing", "SpeedPhone: a tap while playing flaps (got %s)", log)
		log, state = tap(true, "Paused")
		T.check(log == "screen:nil,flap" and state == "Playing", "SpeedPhone: a tap on the pause screen resumes and flaps (got %s -> %s)", log, tostring(state))
		log, state = tap(true, "Over", 10 + retry / 2, 10)
		T.check(log == "" and state == "Over", "SpeedPhone: a tap right after game over is ignored (retry delay), got %s", log)
		log, state = tap(true, "Over", 10 + retry + 0.01, 10)
		T.check(log == "start", "SpeedPhone: a tap after the retry delay starts a new run (got %s)", log)
		log, state = tap(false, "Playing")
		T.check(log == "" and state == "Playing", "SpeedPhone: taps do nothing while the phone is hidden (got %s)", log)
	end
end

---------------------------------------------------------------------------------------------------
-- D5 stage art + Hero Index stage cards
---------------------------------------------------------------------------------------------------
local stageArtModule = H.path(rs, "Directory/StageArt")
if T.check(stageArtModule ~= nil and stageArtModule:IsA("ModuleScript"), "ReplicatedStorage.Directory.StageArt (ModuleScript) missing (D5)") then
	local srcPath = "src/ReplicatedStorage/Directory/StageArt.luau"
	T.check(H.fs.isFile(srcPath) and H.normalize(stageArtModule.Source) == H.normalize(H.fs.readFile(srcPath)), "Directory.StageArt Source differs from %s", srcPath)
	local chunk, err = H.sandbox(stageArtModule.Source, { Color3 = H.roblox.Color3, ColorSequence = H.roblox.ColorSequence,
		ColorSequenceKeypoint = H.roblox.ColorSequenceKeypoint }, "StageArt")
	local ok, art = false, err
	if chunk then
		ok, art = pcall(chunk)
	end
	if T.check(ok and type(art) == "table", "Directory.StageArt does not load: %s", tostring(art)) then
		local keys = {}
		for key in pairs(art) do
			table.insert(keys, key)
		end
		table.sort(keys)
		local want = {}
		for _, stage in ipairs(PLAN.STAGES) do
			table.insert(want, stage.key)
		end
		table.sort(want)
		T.check(table.concat(keys, ",") == table.concat(want, ","), "pairs(StageArt) must yield exactly the 6 stage keys, found {%s}", table.concat(keys, ","))
		for _, stage in ipairs(PLAN.STAGES) do
			local entry = rawget(art, stage.key)
			if T.check(type(entry) == "table", "StageArt.%s missing", stage.key) then
				T.check(entry.Number == stage.number and entry.Name == stage.name, "StageArt.%s must be stage %d %q, found %s %s", stage.key, stage.number, stage.name,
					tostring(entry.Number), tostring(entry.Name))
				local file = "assets/Stages/Stage" .. stage.number .. "_" .. string.gsub(stage.name, "[^%w]", "") .. ".png"
				T.check(entry.File == file and H.fs.isFile(file), "StageArt.%s.File must be %s (an existing file), found %s", stage.key, file, tostring(entry.File))
				T.check(type(entry.ImageId) == "number" and entry.ImageId >= 0, "StageArt.%s.ImageId must be a number (0 = not uploaded)", stage.key)
				local colors = type(entry.Colors) == "table" and entry.Colors or {}
				local okColors = #colors >= 2 and #colors <= 3
				for _, c in ipairs(colors) do
					okColors = okColors and typeof(c) == "Color3"
				end
				T.check(okColors, "StageArt.%s.Colors must be 2-3 Color3 stops", stage.key)
				if type(art.GetImage) == "function" then
					local image = art.GetImage(stage.key)
					T.check(if entry.ImageId == 0 then image == "" else image == "rbxassetid://" .. entry.ImageId,
						"StageArt.GetImage(%s) must be \"\" while ImageId is 0, else rbxassetid://<id>; got %q", stage.key, tostring(image))
				end
				if type(art.GetColorSequence) == "function" then
					local okSeq, seq = pcall(art.GetColorSequence, stage.key)
					T.check(okSeq and typeof(seq) == "ColorSequence", "StageArt.GetColorSequence(%s) must return a ColorSequence", stage.key)
				end
				if type(art.Get) == "function" then
					T.check(art.Get(stage.key) == entry, "StageArt.Get(%s) must return its entry", stage.key)
				end
				T.check(type(art.Order) == "table" and art.Order[stage.number] == stage.key, "StageArt.Order[%d] must be %s", stage.number, stage.key)
			end
		end
		T.check(type(art.Get) == "function" and type(art.GetImage) == "function" and type(art.GetColorSequence) == "function",
			"StageArt helpers Get / GetImage / GetColorSequence (on the metatable) missing")
		for _, key in ipairs(PLAN.RETIRED) do
			T.check(type(art.Get) ~= "function" or art.Get(key) == nil, "StageArt.Get(%q) must be nil (retired zone)", key)
		end
	end
end

local cardFrame = H.path(sg, "Index/Index/Content/IndexPage/IndexListFrame/IndexEntries/Template/Frame")
if T.check(cardFrame ~= nil, "Index stage card template (IndexEntries.Template.Frame) missing") then
	local aspect = cardFrame:FindFirstChild("SpStageAspect")
	T.check(isClass(aspect, "UIAspectRatioConstraint") and math.abs(aspect.AspectRatio - 0.5625) < 1e-3 and aspect.DominantAxis == Enum.DominantAxis.Width,
		"stage card SpStageAspect must be a 9:16 UIAspectRatioConstraint (0.5625, DominantAxis Width)")
	local image = cardFrame:FindFirstChild("Image")
	local fallback = cardFrame:FindFirstChild("SpStageFallback")
	T.check(isClass(image, "ImageLabel") and image.ScaleType == Enum.ScaleType.Crop, "stage card Frame.Image must be an ImageLabel with ScaleType Crop")
	for _, node in ipairs({ cardFrame, image, fallback }) do
		if node then
			-- owner 2026-09-27: square UI (was 10 px)
			T.check(allCorners(node:FindFirstChildOfClass("UICorner"), UDim.new(0, 0)), "%s: UICorner radii must be square (0)", node:GetFullName())
		end
	end
	if T.check(isClass(fallback, "Frame"), "stage card SpStageFallback (Frame) missing") then
		local gradient = fallback:FindFirstChild("SpStageGradient")
		T.check(isClass(gradient, "UIGradient") and math.abs(gradient.Rotation - 90) < 1e-3, "SpStageFallback.SpStageGradient must be a vertical UIGradient (Rotation 90)")
		T.check(fallback:FindFirstChild("SpGloss") ~= nil and fallback:FindFirstChild("SpStageCaption") ~= nil, "SpStageFallback needs SpGloss and SpStageCaption")
		local studs = fallback:FindFirstChild("SpStuds")
		T.check(isClass(studs, "ImageLabel") and H.uri(studs, "ImageContent") == "rbxassetid://6927295847" and studs.ScaleType == Enum.ScaleType.Tile,
			"SpStageFallback.SpStuds must tile the Speedsters stud texture")
		local number = fallback:FindFirstChild("SpStageNumber")
		T.check(isClass(number, "TextLabel") and number.TextScaled, "SpStageFallback.SpStageNumber must be a TextScaled TextLabel")
	end
	local title = cardFrame:FindFirstChild("TextLabel")
	if T.check(isClass(title, "TextLabel"), "stage card title TextLabel missing") then
		T.check(H.has(title.FontFace.Family, "FredokaOne"), "stage card title must use FredokaOne")
		local stroke = title:FindFirstChildOfClass("UIStroke")
		T.check(stroke ~= nil and stroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual and hex(stroke.Color) == "#0b1b3d", "stage card title needs a Contextual #0b1b3d UIStroke")
		T.check(fallback == nil or title.ZIndex > fallback.ZIndex, "stage card title must float above the fallback art")
	end
	T.check(cardFrame:FindFirstChild("ProgressBar") ~= nil and cardFrame:FindFirstChild("EquipBat") ~= nil, "stage card must keep ProgressBar and EquipBat")
end
local indexScript = checkLocalScript("GUI/Index", "src/StarterPlayer/StarterPlayerScripts/GUI/Index/init.client.luau")
if indexScript then
	local code = codeOnly(indexScript.Source)
	T.check(H.has(code, "_renderStageCard") and H.has(code, "requireOptional(\"StageArt\""), "Index must render stage cards from Directory.StageArt (_renderStageCard, requireOptional)")
	T.check(not string.find(code, "require%(%s*ReplicatedStorage%.Directory%.LimitedEgg%s*%)"), "Index must not hard-require Directory.LimitedEgg (empty since D1)")
end

---------------------------------------------------------------------------------------------------
-- D7 HUD: sidebar Shop / Index buttons, currency pills, night timer
---------------------------------------------------------------------------------------------------
local SIDEBAR_WRAPPER_SIZE = { 1, 0.22 } -- Elements.Left.Tools.Shop/Index: a square tile of the left column (owner 2026-09-27)
local sideButtons = { { "Shop", "#4ed61b", "ShopIcon", 96787567013749 }, { "Index", "#14c4f4", "HeroIcon", 140189242202677 } }
for _, spec in ipairs(sideButtons) do
	local wrapper = H.path(sg, "Elements/Left/Tools/" .. spec[1])
	local button = wrapper and wrapper:FindFirstChild("Button")
	local label = "Elements.Left.Tools." .. spec[1] .. ".Button"
	if T.check(button ~= nil and button:IsA("GuiObject"), "%s missing", label) then
		T.check(button.ImageTransparency == 1 and hex(button.BackgroundColor3) == "#ffffff" and button.BackgroundTransparency == 0,
			"%s: white face under the gradient (ImageTransparency 1, BackgroundTransparency 0)", label)
		local fill = button:FindFirstChild("SpFill")
		T.check(isClass(fill, "UIGradient") and fill.Enabled and hasStop(fill, spec[2], true), "%s: SpFill gradient must run through %s", label, spec[2])
		local studs = button:FindFirstChild("SpStuds")
		T.check(isClass(studs, "ImageLabel") and H.uri(studs, "ImageContent") == "rbxassetid://6927295847" and studs.ScaleType == Enum.ScaleType.Tile, "%s: SpStuds tile missing", label)
		T.check(isClass(button:FindFirstChild("SpGloss"), "Frame"), "%s: SpGloss missing", label)
		local plate = button:FindFirstChild("SpIconPlate")
		local rim = plate and plate:FindFirstChild("SpStrokeRim")
		T.check(isClass(plate, "Frame") and plate.SizeConstraint == Enum.SizeConstraint.RelativeYY and isClass(rim, "UIStroke") and hex(rim.Color) == "#ffffff",
			"%s: SpIconPlate sticker with a white SpStrokeRim missing", label)
		local icon = button:FindFirstChild(spec[3])
		T.check(icon ~= nil and icon.Visible and H.imageId(icon) == spec[4] and (plate == nil or icon.ZIndex > plate.ZIndex),
			"%s: visible %s (%d) above the sticker plate missing", label, spec[3], spec[4])
		-- owner 2026-09-27: square minimalist stud tiles (were 190x70 pills with a 0.3 corner), square corners
		local size = wrapper.Size
		T.check(math.abs(size.X.Scale - SIDEBAR_WRAPPER_SIZE[1]) < 1e-3 and size.X.Offset == 0 and math.abs(size.Y.Scale - SIDEBAR_WRAPPER_SIZE[2]) < 1e-3
			and size.Y.Offset == 0, "%s: wrapper Size must be {%g,0,%g,0} (square tile), found %s", spec[1], SIDEBAR_WRAPPER_SIZE[1], SIDEBAR_WRAPPER_SIZE[2],
			tostring(size))
		T.check(allCorners(button:FindFirstChildOfClass("UICorner"), UDim.new(0, 0)), "%s: button corners must be square", label)
		local ratio = wrapper:FindFirstChildOfClass("UIAspectRatioConstraint")
		T.check(ratio ~= nil and math.abs(ratio.AspectRatio - 1) < 1e-3, "%s: the sidebar tile must be square (aspect 1)", label)
	end
end
if left then
	-- 3rd pass: the column moved from the top-left corner (44 px, under the Roblox topbar buttons) to the vertical
	-- centre of the left edge; no pixel offsets, so it clears the topbar on every device
	local pos, anchor = left.Position, left.AnchorPoint
	T.check(math.abs(pos.X.Scale - 0.012) < 1e-4 and pos.X.Offset == 0 and math.abs(pos.Y.Scale - 0.5) < 1e-4 and pos.Y.Offset == 0
		and anchor.X == 0 and math.abs(anchor.Y - 0.5) < 1e-4,
		"Elements.Left must be at {0.012,0,0.5,0} with AnchorPoint (0,0.5), found %s / %s", tostring(pos), tostring(anchor))
	for _, name in ipairs({ "Shop", "Index", "TreadmillSpeedShop", "Rebirth" }) do
		local label = H.path(sg, "Elements/Left/Tools/" .. name .. "/Button/Label")
		T.check(label ~= nil and label.TextScaled and label.TextWrapped,
			"Elements.Left.Tools.%s.Button.Label must be TextScaled + TextWrapped (TextWrapped = false renders it tiny)", name)
	end
end
local badge = H.path(sg, "Elements/Left/Tools/Index/Button/NotificationBadge")
if T.check(badge ~= nil, "Index.Button.NotificationBadge missing") then
	T.check(badge.Visible == false and badge:GetAttribute("SpShake") ~= nil, "NotificationBadge stays hidden at rest and keeps its SpShake attribute")
	local circle = H.path(badge, "Frame/BadgeFrame/Frame")
	T.check(circle ~= nil and hasStop(circle:FindFirstChildOfClass("UIGradient"), "#f3212c", false) and isClass(circle:FindFirstChildOfClass("UIStroke"), "UIStroke")
		and hex(circle:FindFirstChildOfClass("UIStroke").Color) == "#0b1b3d", "NotificationBadge circle must be red (#f3212c) with an ink outline")
	local number = H.path(badge, "Frame/BadgeFrame/TextLabelFrame/TextLabel")
	T.check(number ~= nil and hex(number.TextColor3) == "#ffffff" and H.has(number.FontFace.Family, "GothamSSm") and number.FontFace.Weight == Enum.FontWeight.Heavy
		and number:FindFirstChildOfClass("UIStroke") ~= nil and hex(number:FindFirstChildOfClass("UIStroke").Color) == "#0b1b3d",
		"NotificationBadge number must be white GothamSSm Heavy with an ink stroke")
end
-- Currency rows (owner brief, 3rd pass): minimalist SQUARED translucent ribbons (flat ink band, small corner, no
-- gradient / outline), the Shop / Index label type on the values, the Shop's banknotes icon on Money, the Speed "+"
-- at the right end of its ribbon, and a real gap between the rows.
local rows = H.path(sg, "Money/Bottom/Frame")
if T.check(rows ~= nil, "StarterGui.Money.Bottom.Frame missing") then
	local column = rows:FindFirstChildOfClass("UIListLayout")
	T.check(column ~= nil and column.Padding.Scale >= 0.3,
		"Money.Bottom.Frame needs a gap between the rows (UIListLayout Padding >= 0.3 of the Frame height, ~9 px at 720p)")
	for _, name in ipairs({ "SpeedValue", "Money", "FriendBoost", "TemporarySpeedBoost" }) do
		local row = rows:FindFirstChild(name)
		if T.check(row ~= nil, "Money row %s missing", name) then
			local corner = row:FindFirstChildOfClass("UICorner")
			local gradientOn = false
			for _, c in ipairs(row:GetChildren()) do
				if c:IsA("UIGradient") and c.Enabled then
					gradientOn = true
				end
			end
			local outline = row:FindFirstChild("SpStrokeDark")
			local edge = row:FindFirstChild("SpStrokeLight")
			T.check(hex(row.BackgroundColor3) == "#0b1b3d" and row.BackgroundTransparency >= 0.35 and row.BackgroundTransparency <= 0.6
				and corner ~= nil and allCorners(corner, corner.TopLeftRadius) and corner.TopLeftRadius.Scale <= 0.2 and corner.TopLeftRadius.Offset == 0
				and not gradientOn and (outline == nil or not outline.Enabled or outline.Transparency >= 1)
				and isClass(edge, "UIStroke") and edge.Transparency >= 0.7,
				"Money row %s must be a flat squared translucent ink ribbon (#0b1b3d @0.35-0.6, corner <= 0.2, no gradient / outline, faint SpStrokeLight)", name)
			T.check(row:FindFirstChildOfClass("UIAspectRatioConstraint") ~= nil, "Money row %s needs an aspect constraint (its layout is in ribbon-height units)", name)
			for _, d in ipairs(row:GetDescendants()) do
				if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.TextScaled and not d.TextWrapped then
					T.check(false, "%s is TextScaled without TextWrapped (renders at the tiny fixed TextSize)", d:GetFullName())
				end
			end
		end
	end
	for _, spec in ipairs({ { "FriendBoost", 139671463277267 }, { "TemporarySpeedBoost", 123961542220277 } }) do
		T.check(H.imageId(H.path(rows, spec[1] .. "/SpIcon")) == spec[2], "Money row %s needs its SpIcon %d", spec[1], spec[2])
	end
	-- Money icon: the banknotes art of the Shop's cash packs, not the old trophy
	local cashSource = H.path(sg, "Shop/Frame/Main/ScrollingFrame/MoneyTop/1/Icon")
	local moneyIcon = H.path(rows, "Money/CurrencyIcon")
	T.check(moneyIcon ~= nil and cashSource ~= nil and H.imageId(moneyIcon) ~= nil and H.imageId(moneyIcon) == H.imageId(cashSource)
		and H.imageId(moneyIcon) ~= 107664846509614 and moneyIcon.ImageTransparency == 0,
		"Money.CurrencyIcon must show the Shop's banknotes art (StarterGui.Shop...MoneyTop.1.Icon), not the trophy")
	-- values: the Shop / Index button label type (same font face, TextScaled + TextWrapped, thick ink outline)
	local shopLabel = H.path(sg, "Elements/Left/Tools/Shop/Button/Label")
	local function shopType(face)
		if face == nil or shopLabel == nil or face.FontFace.Family ~= shopLabel.FontFace.Family or not (face.TextScaled and face.TextWrapped) then
			return false
		end
		for _, c in ipairs(face:GetChildren()) do
			if c:IsA("UIStroke") and c.Enabled and c.Transparency < 1 and c.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual
				and hex(c.Color) == "#0b1b3d" and c.Thickness >= 0.1 then
				return true
			end
		end
		return false
	end
	local moneyFace = H.path(rows, "Money/Money/Shadow")
	T.check(moneyFace ~= nil and hex(moneyFace.TextColor3) == "#52ff2e" and shopType(moneyFace),
		"Money value face must be green #52ff2e in the Shop / Index label type (FredokaOne, ink outline, TextScaled + TextWrapped)")
	local friendFace = H.path(rows, "FriendBoost/CurrentBoost/Shadow")
	T.check(friendFace ~= nil and hex(friendFace.TextColor3) == "#ffffff" and shopType(friendFace), "Friend Boost value must be white, in the Shop / Index label type")
	local speedFace = H.path(rows, "SpeedValue/CurrentBoost/Shadow")
	T.check(speedFace ~= nil and hex(speedFace.TextColor3) == "#00ddff", "SpeedValue.CurrentBoost.Shadow keeps its script-owned cyan #00ddff")
	T.check(shopType(speedFace), "SpeedValue value must use the Shop / Index label type")
	-- the "+" shortcut (ButtonFX-bound by SpeedShopShortcut) sits at the RIGHT end of the speed ribbon
	local speed = rows:FindFirstChild("SpeedValue")
	local holder = speed and speed:FindFirstChild("ImageLabel")
	local plus = holder and holder:FindFirstChild("ImageButton")
	local glyph = plus and plus:FindFirstChild("SpPlus")
	T.check(isClass(plus, "ImageButton") and plus.ImageTransparency == 1 and glyph ~= nil and glyph.Text == "+" and glyph.TextScaled and glyph.TextWrapped,
		"Speed row needs its \"+\" button (SpPlus, TextScaled + TextWrapped)")
	local ratio = speed and speed:FindFirstChildOfClass("UIAspectRatioConstraint")
	if plus and holder and ratio then
		-- ribbon-height units: the holder is a RelativeYY square list item that starts after the row's left padding
		local pad = speed:FindFirstChildOfClass("UIPadding")
		local width = ratio.AspectRatio
		local start = pad and pad.PaddingLeft.Scale * width or 0
		local contentH = pad and (1 - pad.PaddingTop.Scale - pad.PaddingBottom.Scale) or 1
		local side = holder.Size.Y.Scale * contentH
		local left = start + (plus.Position.X.Scale - plus.AnchorPoint.X * plus.Size.X.Scale) * side
		local right = left + plus.Size.X.Scale * side
		T.check(holder.SizeConstraint == Enum.SizeConstraint.RelativeYY and left > start + side and right <= width and right >= width * 0.95,
			"Speed \"+\" must sit at the right end of the speed ribbon, clear of the shoe icon (spans %.2f-%.2f of %.2f ribbon heights)", left, right, width)
	end
end
local timer = sg:FindFirstChild("GameResetTimer")
if T.check(timer ~= nil, "StarterGui.GameResetTimer missing") then
	for _, spec in ipairs({ { "TimeLeft", 131317614803230 }, { "EndingSoon", 86038047961937 } }) do
		local root = timer:FindFirstChild(spec[1])
		if T.check(root ~= nil, "GameResetTimer.%s missing", spec[1]) then
			local pill = root:FindFirstChild("Background")
			local g = pill and pill:FindFirstChildOfClass("UIGradient")
			T.check(pill ~= nil and math.abs(pill.BackgroundTransparency - 0.22) < 0.01 and g ~= nil and hex(g.Color.Keypoints[1].Value) == "#2c4a9c"
				and allCorners(pill:FindFirstChildOfClass("UICorner"), UDim.new(0, 0)) and isClass(pill:FindFirstChild("SpStroke"), "UIStroke"),
				"GameResetTimer.%s must be a translucent night-blue band (#2c4a9c, 0.22, square, SpStroke rim)", spec[1])
			local shadow = root:FindFirstChild("SpShadow")
			T.check(pill ~= nil and shadow ~= nil and shadow.ZIndex == pill.ZIndex - 1, "GameResetTimer.%s.SpShadow must sit one ZIndex below the pill", spec[1])
			local iconFrame = H.path(root, "Main/Frame")
			local icon = iconFrame and iconFrame:FindFirstChild("ImageLabel")
			T.check(icon ~= nil and H.imageId(icon) == spec[2], "GameResetTimer.%s timer icon must stay %d", spec[1], spec[2])
			for n = 1, 4 do
				local glow = iconFrame and iconFrame:FindFirstChild("SpGlow" .. n)
				T.check(glow ~= nil and icon ~= nil and glow.ZIndex < icon.ZIndex, "GameResetTimer.%s.Main.Frame.SpGlow%d must glow behind the moon", spec[1], n)
			end
			local text = H.path(root, "Main/TextLabel")
			T.check(text ~= nil and text.AutomaticSize == Enum.AutomaticSize.None and text.FontFace.Weight == Enum.FontWeight.Heavy
				and text.FontFace.Style == Enum.FontStyle.Italic and hex(text.TextColor3) == "#ffffff",
				"GameResetTimer.%s.Main.TextLabel: white GothamSSm Heavy Italic, AutomaticSize None", spec[1])
		end
	end
	local timeLeft = timer:FindFirstChild("TimeLeft")
	if timeLeft then
		local pos, anchor = timeLeft.Position, timeLeft.AnchorPoint
		T.check(math.abs(pos.X.Scale - 0.99) < 1e-4 and pos.X.Offset == 0 and math.abs(pos.Y.Scale - 0.98) < 1e-4 and pos.Y.Offset == 0
			and math.abs(anchor.X - 1) < 1e-4 and math.abs(anchor.Y - 1) < 1e-4,
			"GameResetTimer.TimeLeft keeps Position {0.99,0,0.98,0} and AnchorPoint (1,1)")
		local ratio = timeLeft:FindFirstChildOfClass("UIAspectRatioConstraint")
		T.check(math.abs(timeLeft.Size.X.Scale - 0.165) < 1e-3 and math.abs(timeLeft.Size.Y.Scale - 0.078) < 1e-3 and ratio ~= nil and math.abs(ratio.AspectRatio - 4.3) < 0.01,
			"GameResetTimer.TimeLeft must be {0.165,0,0.078,0} with aspect 4.3")
	end
end

---------------------------------------------------------------------------------------------------
-- D7 windows: Sell Heroes and Free Gift
---------------------------------------------------------------------------------------------------
local sell = H.path(sg, "AutoSell/Frame")
if T.check(sell ~= nil, "StarterGui.AutoSell.Frame missing") then
	T.check(sell:GetAttribute("SellHeroesWindow") == true, "AutoSell.Frame must carry SellHeroesWindow = true")
	T.check(sell:FindFirstChild("TextLabel") ~= nil and sell.TextLabel.Text == "Sell Heroes", "AutoSell window title must read \"Sell Heroes\"")
	for _, p in ipairs({ "SpTabs/HeroesTab/Label", "SpTabs/EggsTab/Label", "SpSortPanel/SortSize/Label", "SpSortPanel/SortValue/Label", "SpSortPanel/SelectAll/Label",
		"SpEmpty", "SpFooter/TotalValue", "SpFooter/CashIcon", "SpCardTemplate/Icon", "SpCardTemplate/HeroName", "SpCardTemplate/SizeTag", "SpCardTemplate/Value",
		"SpCardTemplate/Check", "SpHeaderBand" }) do
		T.check(H.path(sell, p) ~= nil, "AutoSell.Frame.%s missing (SellHeroes reads it)", p)
	end
	T.check(H.imageId(H.path(sell, "SpTabs/HeroesTab/Icon")) == 140189242202677 and H.imageId(H.path(sell, "SpTabs/EggsTab/Icon")) == 96783034607256,
		"Sell Heroes tabs need their hero / egg icons")
	local list = sell:FindFirstChild("SpList")
	T.check(isClass(list, "ScrollingFrame") and list:FindFirstChildOfClass("UIGridLayout") ~= nil, "AutoSell.Frame.SpList must be a ScrollingFrame with a UIGridLayout")
	local sellLabel = H.path(sell, "SpFooter/SellButton/Label")
	T.check(sellLabel ~= nil and sellLabel.Text == "Sell", "AutoSell SellButton label must read \"Sell\"")
	local card = sell:FindFirstChild("SpCardTemplate")
	T.check(card ~= nil and card.Visible == false and isClass(card:FindFirstChild("Rarity"), "UIStroke"), "SpCardTemplate must be hidden with a UIStroke named Rarity")
	T.check(isClass(sell:FindFirstChild("Frame"), "ScrollingFrame"), "AutoSell.Frame.Frame must stay a ScrollingFrame (BackpackController waits for it)")
	local close = H.path(sell, "Close/TextButton")
	T.check(close ~= nil and H.imageId(close) == CLOSE_ART, "Sell Heroes window keeps the Speedsters close art")
end
checkLocalScript("GUI/SellHeroes", "src/StarterPlayer/StarterPlayerScripts/GUI/SellHeroes.client.luau")
local seller = sps and H.path(sps, "Game/Npcs/AssetSellerNpc")
-- (SELL 2026-09-23: the held hero / egg goes through the validated ActiveAssets: RequestSell, not the legacy SELL_ASSET Fire)
T.check(seller ~= nil and H.has(seller.Source, "openSellHeroesWindow") and H.has(seller.Source, "{ Heroes = { t1.uid } }")
	and not H.has(seller.Source, "Network.Fire(AssetInventory.SELL_ASSET"),
	"AssetSellerNpc must open the Sell Heroes window and sell the held hero by uid (RequestSell)")
local sellPrompt = H.path(place.Workspace, "Stands/Prompts/SellAll")
sellPrompt = sellPrompt and sellPrompt:FindFirstChildWhichIsA("ProximityPrompt", true)
T.check(sellPrompt ~= nil and sellPrompt.ActionText == "Sell Heroes", "Stands.Prompts.SellAll prompt must read \"Sell Heroes\"")

local gift = H.path(sg, "GroupReward/FrameReward")
if T.check(gift ~= nil, "StarterGui.GroupReward.FrameReward missing") then
	local title = H.path(gift, "Header/Txts/Title")
	T.check(title ~= nil and title.Text == "Free Gift!" and title:FindFirstChild("Shadow") ~= nil and title.Shadow.Text == "Free Gift!", "Free Gift window title (and Shadow) must read \"Free Gift!\"")
	local main = gift:FindFirstChild("Main")
	if T.check(main ~= nil and main:IsA("Frame"), "FrameReward.Main must resolve to the content Frame (GroupRewards indexes it)") then
		T.check(main:FindFirstChild("Info") ~= nil and main.Info.Text == "~ LIMITED TIME! ~", "Free Gift Info must read \"~ LIMITED TIME! ~\"")
		local reward = H.path(main, "ImageLabel/NameLabel")
		T.check(reward ~= nil and reward.Text == "1,000 SPEED!", "Free Gift reward must read \"1,000 SPEED!\" (balance 2026-09-23)")
		local steps = {}
		for _, c in ipairs(H.path(main, "Requirements") and main.Requirements:GetChildren() or {}) do
			if c.Name == "Template" and c:IsA("GuiObject") then
				local caption = c:FindFirstChild("Name")
				steps[c.LayoutOrder] = caption and caption.Text
			end
		end
		for i, text in ipairs({ "1. Like the game!", "2. Favorite the game!", "3. Join the community!" }) do
			T.check(steps[i] == text, "Free Gift step %d must read %q, found %s", i, text, tostring(steps[i]))
		end
		local claim = H.path(main, "ClaimReward/Title")
		T.check(claim ~= nil and claim.Text == "Claim!", "Free Gift claim button must read \"Claim!\"")
	end
	T.check(gift:FindFirstChild("SpHeaderBand") ~= nil, "Free Gift window keeps its SpHeaderBand")
	local close = H.path(gift, "Close/TextButton")
	T.check(close ~= nil and H.imageId(close) == CLOSE_ART, "Free Gift window keeps the Speedsters close art")
end
local groupRewards = sps and H.path(sps, "GUI/GroupRewards")
if T.check(groupRewards ~= nil, "StarterPlayerScripts.GUI.GroupRewards missing") then
	local code = codeOnly(groupRewards.Source)
	T.check(not H.has(code, "IsInGroupAsync") and not H.has(code, "PromptJoinAsync"), "GroupRewards must not check or prompt group membership")
	T.check(H.has(code, "\"Claimed!\""), "GroupRewards must show \"Claimed!\" once claimed")
end
local rewardService = H.path(place:GetService("ServerScriptService"), "Controllers/GroupRewardService")
T.check(rewardService ~= nil and not H.has(codeOnly(rewardService.Source), "IsInGroup"), "GroupRewardService must grant the gift without a group check")
do
	local live = {}
	for fullName, source in pairs(H.allSources()) do
		if H.has(source, "PromptJoin") and H.has(codeOnly(source), "PromptJoin") then
			table.insert(live, fullName)
		end
	end
	T.check(#live == 0, "no script may prompt a group join (live PromptJoin/PromptJoinAsync in %s)", table.concat(live, ", "))
end
checkLocalScript("Game/HubFreeGift", "src/StarterPlayer/StarterPlayerScripts/Game/HubFreeGift.client.luau")

-- D7 terms: no user-facing text calls the heroes "pets" or "brainrots"
do
	local offenders = {}
	local function scan(inst, text)
		if type(text) == "string" and text ~= "" then
			local lower = string.lower(text)
			if string.find(lower, "%f[%a]pets?%f[%A]") or string.find(lower, "%f[%a]brainrots?%f[%A]") then
				table.insert(offenders, inst:GetFullName() .. " = " .. string.sub(text, 1, 50))
			end
		end
	end
	local uiAssets = H.path(rs, "Assets/UI")
	for _, d in ipairs(place:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			if d:IsDescendantOf(sg) or (uiAssets and d:IsDescendantOf(uiAssets)) or d:FindFirstAncestorWhichIsA("BillboardGui") or d:FindFirstAncestorWhichIsA("SurfaceGui") then
				scan(d, d.Text)
				if d:IsA("TextBox") then
					scan(d, d.PlaceholderText)
				end
			end
		elseif d:IsA("ProximityPrompt") then
			scan(d, d.ActionText)
			scan(d, d.ObjectText)
		end
	end
	T.check(#offenders == 0, "%d user-facing text(s) still say pets/brainrots (D7: \"Heroes\"): %s", #offenders, table.concat(offenders, " | ", 1, math.min(#offenders, 5)))
end

---------------------------------------------------------------------------------------------------
-- H3 hero portraits (docs/HERO_MODELS_PLAN.md): live ViewportFrame headshots of the hero models replace the old
-- hero icons in the Hero Index (entry cards + info panel) and on the Sell Heroes cards
---------------------------------------------------------------------------------------------------
do
	local R = H.roblox
	local PORTRAIT_PATH = "src/ReplicatedStorage/Library/Client/HeroPortrait.luau"
	local portraitModule = H.path(rs, "Library/Client/HeroPortrait")
	local portraitSource = nil
	if T.check(portraitModule ~= nil and portraitModule:IsA("ModuleScript"), "ReplicatedStorage.Library.Client.HeroPortrait (ModuleScript) missing (H3)") then
		T.check(H.fs.isFile(PORTRAIT_PATH) and H.normalize(portraitModule.Source) == H.normalize(H.fs.readFile(PORTRAIT_PATH)),
			"Library.Client.HeroPortrait Source differs from %s (rebuild)", PORTRAIT_PATH)
		if T.check(pcall(H.luau.compile, portraitModule.Source), "Library.Client.HeroPortrait does not compile") then
			portraitSource = portraitModule.Source
		end
		local code = codeOnly(portraitModule.Source)
		T.check(not H.has(code, "WorldModel") and not H.has(code, "RenderStepped") and not H.has(code, "Heartbeat") and not H.has(code, "BindToRenderStep")
			and not H.has(code, ":LoadAnimation("), "HeroPortrait must stay static: no WorldModel, animation or per-frame work")
		T.check(not H.has(code, ":WaitForChild("), "HeroPortrait must never yield on WaitForChild")
	end
	do
		local ok, entries = pcall(function()
			return H.luau.load(H.fs.readFile("scripts/inject/portraits.luau"), { debugName = "portraits manifest" })()
		end)
		local found = false
		for _, entry in ipairs(ok and type(entries) == "table" and entries or {}) do
			if entry.target == "ReplicatedStorage/Library/Client/HeroPortrait" then
				found = entry.class == "ModuleScript" and entry.source == PORTRAIT_PATH and entry.create == true
			end
		end
		T.check(found, "scripts/inject/portraits.luau must inject %s as ReplicatedStorage/Library/Client/HeroPortrait (ModuleScript, create = true)", PORTRAIT_PATH)
	end

	-- sandboxed module: `game` resolves ReplicatedStorage to the given folder; task.defer / delay are queued and run by flush()
	local function loadPortraits(replicatedStorage, label)
		if portraitSource == nil then
			return nil
		end
		local queue, warnings = {}, {}
		local fakeGame = {}
		function fakeGame:GetService(name)
			assert(name == "ReplicatedStorage", "HeroPortrait asked for service " .. tostring(name))
			return replicatedStorage
		end
		local fakeTask = {
			defer = function(fn)
				table.insert(queue, fn)
			end,
			delay = function(_, fn)
				table.insert(queue, fn)
			end,
			spawn = function(fn, ...)
				fn(...)
			end,
		}
		local chunk, err = H.sandbox(portraitSource, {
			game = fakeGame,
			Instance = R.Instance,
			Vector3 = R.Vector3,
			Vector2 = R.Vector2,
			CFrame = R.CFrame,
			Color3 = R.Color3,
			UDim2 = R.UDim2,
			Enum = Enum,
			task = fakeTask,
			warn = function(...)
				table.insert(warnings, table.concat({ ... }, " "))
			end,
		}, label)
		local ok, module = false, err
		if chunk then
			ok, module = pcall(chunk)
		end
		if not T.check(ok and type(module) == "table", "%s does not load: %s", label, tostring(module)) then
			return nil
		end
		local function flush()
			for _ = 1, 50 do
				if #queue == 0 then
					return
				end
				local batch = queue
				queue = {}
				for _, fn in ipairs(batch) do
					fn()
				end
			end
		end
		return module, flush, warnings
	end

	local function portraitsIn(holder)
		local list = {}
		for _, c in ipairs(holder:GetChildren()) do
			if c:IsA("ViewportFrame") and c:GetAttribute("HeroPortrait") == true then
				table.insert(list, c)
			end
		end
		return list
	end
	local function flat(v)
		local f = R.Vector3.new(v.X, 0, v.Z)
		return if f.Magnitude > 1e-3 then f.Unit else nil
	end
	local function headOf(model)
		for _, d in ipairs(model:GetDescendants()) do
			if d.Name == "Head" and d:IsA("BasePart") and d:FindFirstAncestorWhichIsA("Accoutrement") == nil then
				return d
			end
		end
		return nil
	end
	local function headHeight(head)
		local mesh = head:FindFirstChildOfClass("SpecialMesh")
		if mesh and mesh.MeshType == Enum.MeshType.Head then
			return math.min(head.Size.X, head.Size.Y, head.Size.Z) * mesh.Scale.Y
		end
		return head.Size.Y
	end
	-- a point in normalised frame coordinates (-1..1, y up) and `size` as a fraction of the frame height
	local function project(camera, point, size)
		local cf = camera.CFrame
		local rel = point - cf.Position
		local depth = rel:Dot(cf.LookVector)
		if depth <= 0 then
			return nil
		end
		local tanHalf = math.tan(math.rad(camera.FieldOfView) / 2)
		return rel:Dot(cf.RightVector) / depth / tanHalf, rel:Dot(cf.UpVector) / depth / tanHalf, size / (2 * depth * tanHalf)
	end
	local FORBIDDEN = { "LuaSourceContainer", "Sound", "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles", "Light", "BillboardGui", "WorldModel",
		"ProximityPrompt", "ClickDetector" }

	-- every roster hero of the build gets a framed headshot
	local HeroPortrait = loadPortraits(rs, "HeroPortrait (build)")
	if HeroPortrait then
		local am = rs:FindFirstChild("AssetModels")
		local templateCounts = {}
		for _, hero in ipairs(PLAN.HEROES) do
			local template = am and am:FindFirstChild(hero[1])
			templateCounts[hero[1]] = template and #template:GetDescendants() or -1
		end
		local framed, problems = 0, {}
		local function problem(id, fmt, ...)
			if #problems < 12 then
				table.insert(problems, id .. ": " .. string.format(fmt, ...))
			end
		end
		for _, hero in ipairs(PLAN.HEROES) do
			local id = hero[1]
			local holder = R.Instance.new("ImageLabel")
			holder.ZIndex = 3
			local okMount, vp = pcall(HeroPortrait.Mount, holder, id)
			if not HeroPortrait.HasModel(id) then
				problem(id, "no model (AssetModels / Assets.Models.Heroes)")
			elseif not okMount or vp == nil or not vp:IsA("ViewportFrame") then
				problem(id, "Mount failed (%s)", tostring(vp))
			else
				local camera = vp:FindFirstChildOfClass("Camera")
				local model = vp:FindFirstChildOfClass("Model")
				local aspect = vp:FindFirstChildOfClass("UIAspectRatioConstraint")
				local ok = true
				local function need(cond, fmt, ...)
					if not cond then
						ok = false
						problem(id, fmt, ...)
					end
				end
				need(vp.Parent == holder and vp.Name == "HeroPortrait" and vp:GetAttribute("HeroId") == id and #portraitsIn(holder) == 1,
					"portrait must be the holder's only HeroPortrait with HeroId")
				need(vp.BackgroundTransparency == 1 and vp.ZIndex == 4 and aspect ~= nil and aspect.AspectRatio == 1, "transparent square frame above its holder")
				need(camera ~= nil and model ~= nil, "needs its Camera and the model clone")
				need(model == nil or model ~= (am and am:FindFirstChild(id)), "must show a clone, never the template")
				if camera and model then
					need(camera.FieldOfView >= 10 and camera.FieldOfView <= 35, "small field of view (%.0f)", camera.FieldOfView)
					for _, d in ipairs(model:GetDescendants()) do
						for _, className in ipairs(FORBIDDEN) do
							if d:IsA(className) then
								need(false, "clone keeps a %s (%s)", className, d.Name)
							end
						end
						if d:IsA("BasePart") and not d.Anchored then
							need(false, "part %s not anchored", d.Name)
						end
					end
					local head = headOf(model)
					if head then
						local toCamera = flat(camera.CFrame.Position - head.CFrame.Position)
						local root = model:FindFirstChild("HumanoidRootPart", true)
						local fronts = { flat(head.CFrame.LookVector), root and flat(root.CFrame.LookVector) or false }
						local facing = false
						for _, front in ipairs(fronts) do
							if toCamera and front and toCamera:Dot(front) >= math.cos(math.rad(40)) then
								facing = true
							end
						end
						need(facing, "camera must be on the face side (within 40 degrees of the face)")
						local x, y, fill = project(camera, head.CFrame.Position, headHeight(head))
						need(x ~= nil and math.abs(x) <= 0.25 and math.abs(y) <= 0.5, "head must be centred (x %.2f, y %.2f)", x or 0, y or 0)
						need(fill ~= nil and fill >= 0.25 and fill <= 0.85, "head must fill 25-85%% of the frame height (%.2f)", fill or 0)
					else
						need(false, "clone has no Head part")
					end
				end
				-- same hero again: no new clone, only the silhouette changes
				local again = HeroPortrait.Mount(holder, id, { Silhouette = true })
				need(again == vp and vp.ImageColor3 == R.Color3.new(0, 0, 0) and math.abs(vp.ImageTransparency - 0.35) < 1e-3 and vp:GetAttribute("Silhouette") == true,
					"re-mounting with Silhouette must reuse the portrait and tint it black at 0.35")
				HeroPortrait.Mount(holder, id)
				need(vp.ImageColor3 == R.Color3.new(1, 1, 1) and vp.ImageTransparency == 0, "a discovered hero shows in full colour")
				if ok then
					framed += 1
				end
				HeroPortrait.Clear(holder)
				need(#portraitsIn(holder) == 0, "Clear must remove the portrait")
			end
		end
		T.check(framed == #PLAN.HEROES, "H3: %d/%d roster heroes get a framed headshot: %s", framed, #PLAN.HEROES, table.concat(problems, " | "))
		local touched = {}
		for _, hero in ipairs(PLAN.HEROES) do
			local template = am and am:FindFirstChild(hero[1])
			if (template and #template:GetDescendants() or -1) ~= templateCounts[hero[1]] then
				table.insert(touched, hero[1])
			end
		end
		T.check(#touched == 0, "HeroPortrait must never modify the hero templates (changed: %s)", table.concat(touched, ", "))
		-- another hero replaces the portrait; an unknown hero mounts nothing
		local holder = R.Instance.new("Frame")
		local first = HeroPortrait.Mount(holder, PLAN.HEROES[1][1])
		local second = HeroPortrait.Mount(holder, PLAN.HEROES[2][1])
		T.check(first ~= nil and second ~= nil and first ~= second and first.Parent == nil and #portraitsIn(holder) == 1
			and second:GetAttribute("HeroId") == PLAN.HEROES[2][1], "mounting another hero must replace (destroy) the previous portrait")
		T.check(HeroPortrait.Mount(holder, "NoSuchHero") == nil and #portraitsIn(holder) == 0 and not HeroPortrait.HasModel("NoSuchHero"),
			"an unknown hero mounts nothing (and clears the holder)")
	end

	-- robustness: any rig (R6 Part head with the classic head mesh, turned sideways; no Head; nothing visible), the
	-- Assets.Models.Heroes fallback, non-archivable templates
	do
		local function folder(name, parent)
			local f = R.Instance.new("Folder")
			f.Name = name
			f.Parent = parent
			return f
		end
		local fakeRS = folder("ReplicatedStorage", nil)
		local assetModels = folder("AssetModels", fakeRS)
		local heroesFolder = folder("Heroes", folder("Models", folder("Assets", fakeRS)))

		-- an R6 rig standing at (50, 0, 20) that faces +X (rotation: local -Z -> world +X)
		local facing = R.Vector3.new(1, 0, 0)
		local rigFrame = R.CFrame.fromMatrix(R.Vector3.new(50, 0, 20), R.Vector3.new(0, 0, 1), R.Vector3.new(0, 1, 0), R.Vector3.new(-1, 0, 0))
		local function part(parent, name, size, offset)
			local p = R.Instance.new("Part")
			p.Name = name
			p.Size = size
			p.CFrame = rigFrame * R.CFrame.new(offset)
			p.Parent = parent
			return p
		end
		local r6 = R.Instance.new("Model")
		r6.Name = "RigR6"
		local root = part(r6, "HumanoidRootPart", R.Vector3.new(2, 2, 1), R.Vector3.new(0, 3, 0))
		root.Transparency = 1
		r6.PrimaryPart = root
		local torso = part(r6, "Torso", R.Vector3.new(2, 2, 1), R.Vector3.new(0, 3, 0))
		part(r6, "Left Arm", R.Vector3.new(1, 2, 1), R.Vector3.new(-1.5, 3, 0))
		part(r6, "Right Arm", R.Vector3.new(1, 2, 1), R.Vector3.new(1.5, 3, 0))
		part(r6, "Left Leg", R.Vector3.new(1, 2, 1), R.Vector3.new(-0.5, 1, 0))
		part(r6, "Right Leg", R.Vector3.new(1, 2, 1), R.Vector3.new(0.5, 1, 0))
		local head = part(r6, "Head", R.Vector3.new(2, 1, 1), R.Vector3.new(0, 4.5, 0))
		local mesh = R.Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Head
		mesh.Scale = R.Vector3.new(1.25, 1.25, 1.25)
		mesh.Parent = head
		local face = R.Instance.new("Decal")
		face.Name = "face"
		face.Face = Enum.NormalId.Front
		face.Parent = head
		R.Instance.new("Humanoid").Parent = r6
		local hat = R.Instance.new("Accessory")
		hat.Name = "TallHat"
		hat.Parent = r6
		local handle = part(hat, "Handle", R.Vector3.new(1.2, 1.2, 1.2), R.Vector3.new(0, 5.6, 0))
		local hatAttachment = R.Instance.new("Attachment")
		hatAttachment.Name = "HatAttachment"
		hatAttachment.Parent = handle
		local cape = part(r6, "Cape", R.Vector3.new(3, 4, 0.2), R.Vector3.new(0, 2.5, 0.8))
		local capeWeld = R.Instance.new("WeldConstraint")
		capeWeld.Part0 = cape
		capeWeld.Part1 = torso
		capeWeld.Parent = cape
		for _, className in ipairs({ "Script", "LocalScript", "Sound", "ParticleEmitter", "PointLight", "BillboardGui", "Fire" }) do
			R.Instance.new(className).Parent = if className == "Script" or className == "LocalScript" then r6 else head
		end
		r6.Archivable = false
		r6.Parent = heroesFolder -- only in the Assets.Models.Heroes fallback

		local noHead = R.Instance.new("Model")
		noHead.Name = "NoHead"
		local body = R.Instance.new("Part")
		body.Name = "Body"
		body.Size = R.Vector3.new(2, 5, 1)
		body.CFrame = R.CFrame.new(0, 2.5, 0)
		body.Parent = noHead
		noHead.PrimaryPart = body
		noHead.Parent = assetModels

		local ghost = R.Instance.new("Model")
		ghost.Name = "Ghost"
		local invisible = R.Instance.new("Part")
		invisible.Transparency = 1
		invisible.Parent = ghost
		ghost.Parent = assetModels

		local Portraits = loadPortraits(fakeRS, "HeroPortrait (synthetic rigs)")
		if Portraits then
			local holder = R.Instance.new("ImageLabel")
			T.check(Portraits.HasModel("RigR6"), "HeroPortrait.HasModel must fall back to ReplicatedStorage.Assets.Models.Heroes")
			local okMount, vp = pcall(Portraits.Mount, holder, "RigR6")
			if T.check(okMount and vp ~= nil, "R6 rig (Assets.Models.Heroes, Archivable = false) must mount: %s", tostring(vp)) then
				T.check(r6.Archivable == false, "the template's Archivable flag must be restored")
				local camera = vp:FindFirstChildOfClass("Camera")
				local clone = vp:FindFirstChildOfClass("Model")
				local cloneHead = clone and headOf(clone)
				local junkLeft = {}
				for _, d in ipairs(clone and clone:GetDescendants() or {}) do
					for _, className in ipairs(FORBIDDEN) do
						if d:IsA(className) then
							table.insert(junkLeft, d.ClassName)
						end
					end
				end
				T.check(#junkLeft == 0, "R6 rig: scripts / sounds / particles / lights / billboards must be stripped (left: %s)", table.concat(junkLeft, ", "))
				if T.check(camera ~= nil and cloneHead ~= nil, "R6 rig portrait needs its camera and head") then
					local toCamera = flat(camera.CFrame.Position - cloneHead.CFrame.Position)
					T.check(toCamera ~= nil and toCamera:Dot(facing) >= math.cos(math.rad(35)),
						"R6 rig turned to +X: the camera must be on its face side (face decal direction)")
					local x, y, fill = project(camera, cloneHead.CFrame.Position, 1.25)
					T.check(x ~= nil and math.abs(x) <= 0.25 and math.abs(y) <= 0.5 and fill >= 0.25 and fill <= 0.85,
						"R6 rig: the classic head must be centred and fill 25-85%% of the frame (x %.2f y %.2f fill %.2f)", x or 0, y or 0, fill or 0)
					local hatHandle = clone:FindFirstChild("TallHat") and clone.TallHat:FindFirstChild("Handle")
					local _, hatY = project(camera, hatHandle.CFrame.Position + R.Vector3.new(0, 0.6, 0), 0)
					T.check(hatY ~= nil and hatY <= 1.0, "R6 rig: a hat on the head must stay inside the frame (top at %.2f)", hatY or 99)
				end
			end
			local okNoHead, headless = pcall(Portraits.Mount, R.Instance.new("Frame"), "NoHead")
			T.check(okNoHead and headless ~= nil and headless:FindFirstChildOfClass("Camera") ~= nil, "a model without a Head must still get a portrait (top of the model)")
			local ghostHolder = R.Instance.new("Frame")
			local okGhost, ghostVp = pcall(Portraits.Mount, ghostHolder, "Ghost")
			T.check(okGhost and ghostVp == nil and #ghostHolder:GetChildren() == 0, "a model with nothing visible mounts nothing and leaves no partial frame")
		end
	end

	-- lazy loader: mounts only laid-out, shown holders inside the scroller's view, PerStep per frame, event driven, and
	-- nothing after Destroy
	do
		local Portraits, flush = loadPortraits(rs, "HeroPortrait (lazy)")
		if Portraits then
			local mounted = {}
			Portraits.Mount = function(parent, heroId)
				if heroId == "Broken" then
					return nil
				end
				table.insert(mounted, parent.Name .. ":" .. heroId)
				return {}
			end
			local disconnected = 0
			local function signal()
				local s = { handlers = {} }
				function s:Connect(fn)
					table.insert(self.handlers, fn)
					return {
						Disconnect = function()
							disconnected += 1
						end,
					}
				end
				function s:Fire()
					for _, fn in ipairs(self.handlers) do
						fn()
					end
				end
				return s
			end
			local screen = { Enabled = true }
			function screen:IsA(className)
				return className == "LayerCollector"
			end
			local function gui(name, position, size)
				local g = { Name = name, Visible = true, Parent = screen, AbsolutePosition = position, AbsoluteSize = size, signals = {}, Destroying = signal() }
				function g:IsA(className)
					return className == "GuiObject"
				end
				function g:GetChildren()
					return {}
				end
				function g:GetPropertyChangedSignal(property)
					self.signals[property] = self.signals[property] or signal()
					return self.signals[property]
				end
				return g
			end
			local V2 = R.Vector2.new
			local scroller = gui("List", V2(0, 0), V2(400, 300))
			local loader = Portraits.Lazy(scroller, { PerStep = 2, Margin = 0.5 })
			local far = gui("Far", V2(10, 2000), V2(80, 80))
			local unlaid = gui("Unlaid", V2(0, 0), V2(0, 0))
			for _, g in ipairs({ gui("A", V2(10, 10), V2(80, 80)), gui("B", V2(100, 10), V2(80, 80)), gui("C", V2(10, 200), V2(80, 80)), far, unlaid }) do
				loader:Request(g, "Hero")
			end
			T.check(#mounted == 0, "Lazy:Request must not mount synchronously")
			flush()
			local sorted = table.clone(mounted)
			table.sort(sorted)
			T.check(table.concat(sorted, ",") == "A:Hero,B:Hero,C:Hero", "Lazy must mount the 3 holders in view (2 per step) and skip the far / unlaid ones, got {%s}",
				table.concat(sorted, ","))
			unlaid.AbsolutePosition, unlaid.AbsoluteSize = V2(200, 100), V2(80, 80)
			unlaid.signals.AbsoluteSize:Fire()
			flush()
			T.check(table.find(mounted, "Unlaid:Hero") ~= nil, "Lazy must mount a holder once it is laid out (AbsoluteSize change)")
			far.AbsolutePosition = V2(10, 250)
			far.signals.AbsolutePosition:Fire()
			flush()
			T.check(table.find(mounted, "Far:Hero") ~= nil and #mounted == 5, "Lazy must mount a holder scrolled into view (AbsolutePosition change)")
			local failed = false
			loader:Request(gui("Bad", V2(0, 0), V2(50, 50)), "Broken", {
				OnFailed = function()
					failed = true
				end,
			})
			flush()
			T.check(failed, "Lazy must call opts.OnFailed when the portrait cannot be mounted")
			local hidden = gui("Hidden", V2(0, 0), V2(50, 50))
			hidden.Visible = false
			loader:Request(hidden, "Hero")
			flush()
			T.check(table.find(mounted, "Hidden:Hero") == nil, "Lazy must not mount into a hidden holder")
			local before = disconnected
			loader:Destroy()
			T.check(disconnected > before, "Lazy:Destroy must disconnect its signals")
			hidden.Visible = true
			hidden.signals.AbsolutePosition:Fire()
			loader:Request(gui("Late", V2(0, 0), V2(50, 50)), "Hero")
			flush()
			T.check(table.find(mounted, "Hidden:Hero") == nil and table.find(mounted, "Late:Hero") == nil, "a destroyed loader must mount nothing")
		end
	end

	-- the Hero Index: entry cards (lazy, in the list's view) + info panel, silhouettes for undiscovered heroes
	local index = indexScript and H.normalize(indexScript.Source)
	if index then
		local code = codeOnly(index)
		T.check(H.has(code, "clientFolder:FindFirstChild(\"HeroPortrait\")") and H.has(code, "HeroPortrait.Lazy(IndexEntries"),
			"Index must load Library.Client.HeroPortrait and lazily mount the entry-card portraits in IndexEntries")
		T.check(H.has(code, "p38:_renderEntryIcon(Frame.Button.Icon.ImageLabel, p40, v142, p38._portraitLoader)") and H.has(code, "p45:_renderEntryIcon(ImageLabel, v173, v174)"),
			"Index must render portraits on the entry cards (with the loader) and in the info panel")
		T.check(H.has(code, "loader:Destroy()") and H.has(code, "HeroPortrait.Clear(ImageLabel)"), "Index must free the portraits when it closes")
		local start = string.find(index, "\nfunction t1._renderEntryPortrait(", 1, true)
		local finish = start and string.find(index, "\nfunction t1._renderIconImage(", start + 1, true)
		if T.check(start ~= nil and finish ~= nil, "Index: t1._renderEntryPortrait missing") then
			local chunk, err = H.sandbox("return function(S)\nlocal t1 = {}\nlocal HeroPortrait, HIDDEN_ICON_TRANSPARENCY = S.HeroPortrait, 0.35\n"
				.. string.sub(index, start + 1, finish) .. "\nreturn t1\nend", {}, "Index._renderEntryPortrait")
			local ok, make = false, err
			if chunk then
				ok, make = pcall(chunk)
			end
			if T.check(ok and type(make) == "function", "Index._renderEntryPortrait does not load: %s", tostring(make)) then
				local function run(hasModel, discovered, withLoader, noModule)
					local log = { requests = {}, mounts = 0, clears = 0, cancels = 0 }
					local S = {}
					if not noModule then
						S.HeroPortrait = {
							HasModel = function()
								return hasModel
							end,
							Mount = function(_, _, opts)
								log.mounts += 1
								log.opts = opts
								return {}
							end,
							Clear = function()
								log.clears += 1
							end,
						}
					end
					local loader = if withLoader
						then {
							Request = function(_, _, heroId, opts)
								table.insert(log.requests, heroId)
								log.opts = opts
							end,
							Cancel = function()
								log.cancels += 1
							end,
						}
						else nil
					local label = { Image = "rbxassetid://1", ImageTransparency = 0, Parent = {} }
					local t1 = make(S)
					local okRun, result = pcall(t1._renderEntryPortrait, t1, label, { Category = "Batman" }, discovered, loader)
					T.check(okRun, "Index._renderEntryPortrait failed: %s", tostring(result))
					return okRun and result, log, label
				end
				local shown, log, label = run(true, false, true)
				T.check(shown == true and #log.requests == 1 and log.requests[1] == "Batman" and log.opts.Silhouette == true
					and log.opts.SilhouetteTransparency == 0.35 and label.ImageTransparency == 1 and label.Image == "",
					"Index: an undiscovered entry card requests a 0.35 black silhouette portrait and hides the old icon")
				shown, log = run(true, true, false)
				T.check(shown == true and log.mounts == 1 and log.opts.Silhouette == false, "Index: the info panel mounts the discovered hero's portrait at once, in colour")
				shown, log, label = run(false, true, true)
				T.check(shown == false and log.clears == 1 and log.cancels == 1 and label.Image == "rbxassetid://1",
					"Index: an entry without a model clears its portrait and keeps the old icon")
				shown = run(true, true, true, true)
				T.check(shown == false, "Index: without HeroPortrait the old icons are used")
			end
		end
	end

	-- Sell Heroes: hero cards show the portrait (lazy, in the list's view); egg cards keep the egg icon
	local sellScript = sps and H.path(sps, "GUI/SellHeroes")
	if sellScript then
		local src = H.normalize(sellScript.Source)
		local code = codeOnly(src)
		T.check(H.has(code, "Library.Client:FindFirstChild(\"HeroPortrait\")") and H.has(code, "HeroPortrait.Lazy(ui.list")
			and H.has(code, "category = item.Category"), "SellHeroes must load HeroPortrait and lazily mount hero portraits in SpList")
		T.check(H.has(code, "state.cardsTab ~= state.tab") and H.has(code, "fillCard(card, entry, i)"),
			"SellHeroes must keep cards (and their portraits) per uid between rebuilds")
		local body = H.extractFunction(src, "showIcon")
		if T.check(body ~= nil, "SellHeroes: local function showIcon missing") then
			local chunk, err = H.sandbox("return function(S)\nlocal portraits, HeroPortrait = S.portraits, S.HeroPortrait\n" .. body .. "\nreturn showIcon\nend", {},
				"SellHeroes.showIcon")
			local ok, make = false, err
			if chunk then
				ok, make = pcall(chunk)
			end
			if T.check(ok and type(make) == "function", "SellHeroes.showIcon does not load: %s", tostring(make)) then
				local function show(entry)
					local log = { requests = {}, cancels = 0, clears = 0 }
					local S = {
						HeroPortrait = {
							HasModel = function(id)
								return id == "Batman"
							end,
							Clear = function()
								log.clears += 1
							end,
						},
						portraits = {
							Request = function(_, _, heroId)
								table.insert(log.requests, heroId)
							end,
							Cancel = function()
								log.cancels += 1
							end,
						},
					}
					local icon = { Image = "old", ImageTransparency = 0.5, Parent = {} }
					local okShow, e = pcall(make(S), icon, entry)
					T.check(okShow, "SellHeroes.showIcon failed: %s", tostring(e))
					return icon, log
				end
				local icon, log = show({ uid = "1", name = "Batman", category = "Batman", icon = "rbxassetid://5" })
				T.check(#log.requests == 1 and log.requests[1] == "Batman" and icon.ImageTransparency == 1 and icon.Image == "",
					"SellHeroes: a hero card requests its portrait and hides the icon image")
				icon, log = show({ uid = "2", name = "Egg", icon = "rbxassetid://96783034607256" })
				T.check(#log.requests == 0 and log.cancels == 1 and log.clears == 1 and icon.Image == "rbxassetid://96783034607256" and icon.ImageTransparency == 0,
					"SellHeroes: an egg card keeps the egg icon (no portrait)")
			end
		end
	end
end
