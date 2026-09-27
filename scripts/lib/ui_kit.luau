--!nocheck
-- scripts/lib/ui_kit.luau
-- Steal a Hero window style kit (owner UI, Gekko TO DO "UI Revamp"). The build-time recipes of the two windows the
-- owner picked as the quality reference, the "Free Gift!" window (StarterGui.GroupReward) and the "Sell Heroes"
-- window (StarterGui.AutoSell), extracted so every other window shares the same look with its own colour theme,
-- icon and background pattern.
--
-- REQUIRE (Lune resolves require paths relative to the requiring file):
--   from scripts/steps/*.luau:  local UiKit = require("../lib/ui_kit")
--   from scripts/lib/*.luau:    local UiKit = require("./ui_kit")
-- Built on scripts/lib/speedsters_ui_kit.luau (UiKit.Kit): its Lune-safe writers are used for every property that
-- Lune 0.10.5 would otherwise lose (ImageContent, FontFace, the four UICorner radii, UIStroke sizing).
--
-- THE LOOK ("studded glossy"):
--   * body        dark rounded window (theme.body) + a faint theme background pattern + the stud texture at ~15 % +
--                 a thick ink rim (#0b1b3d) and a light inner rim;
--   * header band glossy left -> right gradient (theme.band) with two diagonal light streaks, studs, a top gloss, a
--                 darker lower half and an ink line under it; top corners rounded;
--   * title       white GothamSSm Bold with a thick ink outline, LEFT aligned in the band after the header icon;
--   * icon        the theme icon (an image id already in the place, or a big glossy letter) at the band's left end;
--   * close       the round red X (Speedsters art on Close.TextButton, ConsoleCmds contract) with an ink rim and an
--                 embossed dark disc, at the band's right end;
--   * buttons     chunky glossy buttons: the colour is BackgroundColor3 (scripts may recolour it), a multiplied
--                 light-to-dark gradient with a relief lip, a top gloss, an ink rim;
--   * panels      dark rounded panels (theme.panel) with an ink rim (Sell Heroes' Sort By / Total Value);
--   * cards       dark rounded cards (theme.card) with a soft rim (Free Gift's step cards);
--   * tabs        glossy square side tabs with a caption and an icon (Sell Heroes' HEROES / EGGS).
--
-- IDEMPOTENT: every layer has an `Sp` + Capital name (SpHeaderBand, SpStuds, SpGloss, SpPattern, SpRim...) and a
-- second run reconfigures it instead of adding a new one. Legacy decoration is hidden by transparency; nothing that
-- scripts look up is renamed, re-parented or destroyed by the kit.
--
-- API (every function returns the node it styled / created; opts are optional unless noted):
--   Constants  UiKit.Kit (speedsters_ui_kit), UiKit.INK / WHITE / BLACK, UiKit.STUD_TILE, UiKit.STUD_TRANSPARENCY,
--              UiKit.GLOSS_FILL, UiKit.CARD_FILL, UiKit.CHECK_GLYPH, UiKit.DECOR, UiKit.Icons, UiKit.Patterns,
--              UiKit.Themes[name] = { band = stops, body = Color3, panel, card, cardStroke, list, accent, on, off,
--                                     icon = image id | nil, letter = "H" | nil, pattern = image id | nil,
--                                     patternTile = UDim2, patternTransparency, patternColor = Color3 }
--              (themes: gift, sell, index, heroes, eggs, shop, speed, trail, treadmill, gear, settings, codes, odds,
--               fuse, trade, offline, starter, rebirth, message, danger, freegifts)
--   Geometry   UiKit.layer(parent, className, name, zIndex)  -- ensureChild + BorderSizePixel 0 + Active false
--              UiKit.setBox(node, anchor, position, size)      UiKit.aspect(node, ratio)
--              UiKit.cornerFor(rootCorner, heightFraction)     UiKit.topCorner(node, radius)
--              UiKit.bottomCorner(node, radius)                UiKit.boxOf(node, root) -> x, y, w, h (root scale)
--              UiKit.rootPixels(root) -> w, h     -- rendered size of a scale-sized frame on a 1280x720 screen
--              UiKit.bandHeightFor(root, px)  -- band height as a fraction of the root for ~px pixels at 1280x720
--              UiKit.isGlobal(node)            UiKit.minContentZ(root, excludeNames)   -- Global ZIndexBehavior helpers
--   Layers     UiKit.studs(parent, zIndex, { name, tile, color, transparency, corner })
--              UiKit.gloss(parent, zIndex, { name, top, width, height, strength, corner })
--              UiKit.streaks(parent, zIndex, layerAspect)
--              UiKit.pattern(parent, zIndex, theme | { pattern, patternTile, patternStretch, patternTransparency,
--                                                      patternColor, corner })
--   Window     UiKit.body(root, painter, { color (required), corner (required), art, artTint, transparency, hide, theme,
--                                          noStuds, globalExclude })
--              UiKit.headerBand(root, { colors, height, zIndex, rootCorner, rootAspect, box = {x, y, w, h},
--                                       placement = "inside" | "above", name })
--              UiKit.title(label, { strokeThickness, text, keepColor, keepGradient, alignX, kind })  -- band title face
--              UiKit.placeTitle(node, band, { left, width, height, zIndex })   -- places a title node on the band
--              UiKit.headerIcon(root, iconIdOrLetter, { position, size, zIndex, existing, parent, strokeColor })
--              UiKit.closeButton(close, position, size, zIndex)
--              UiKit.chrome(root, painter, theme, spec) -- body + band + title + icon + close in one call (see there)
--   Content    UiKit.glossButton(button, { color, owned, corner, stroke, strokeColor, glossStrength, glossZ })
--              UiKit.text(parent, name, text, kind, { anchor, position, size, zIndex, color, stroke, strokeColor,
--                                                    gradient, gradientRotation, alignX, rich })
--              UiKit.labelButton(parent, name, caption, { color, anchor, position, size, corner, stroke, kind,
--                                                        labelPosition, labelSize, labelStroke, alignX, zIndex })
--              UiKit.panel(frame, { color, transparency, corner, stroke, owned })
--              UiKit.card(frame, { color, transparency, corner, strokeColor, stroke, owned })
--              UiKit.tab(parent, name, caption, iconId, { color, size, corner, stroke, layoutOrder })
--              UiKit.input(holder, box, theme)                              -- dark text input
--              UiKit.letterIcon(parent, letter, { name, strokeColor, zIndex })
--
-- The Index window structure produced by scripts/steps/ui_50_revamp.luau is documented there (BASES adds its reward
-- panel inside it with UiKit.panel / UiKit.card / UiKit.glossButton / UiKit.text).

local roblox = require("@lune/roblox")
local Kit = require("./speedsters_ui_kit")

local Color3 = roblox.Color3
local UDim = roblox.UDim
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2
local Enum = roblox.Enum

local UiKit = {}
UiKit.Kit = Kit

local hex = Kit.hex
local INK = Kit.Colors.ink
local WHITE = Kit.Colors.white
local BLACK = Kit.Colors.black
UiKit.INK, UiKit.WHITE, UiKit.BLACK = INK, WHITE, BLACK

UiKit.STUD_TILE = UDim2.fromOffset(18, 18)
UiKit.STUD_TRANSPARENCY = 0.6 -- the studs show at ~40 % (owner 2026-09-27: "stud texture on every UI, and visible")
-- Multiplied into a button's BackgroundColor3: light top, a darker lip along the bottom edge (the relief). Because it
-- multiplies, a script that recolours the button (claim state, selection) keeps the glossy look.
UiKit.GLOSS_FILL = { { 0, "#ffffff" }, { 0.46, "#f2f2f2" }, { 0.79, "#c8c8c8" }, { 0.83, "#8c8c8c" }, { 1, "#747474" } }
UiKit.CARD_FILL = { { 0, "#ffffff" }, { 1, "#a3a9c8" } }
UiKit.CHECK_GLYPH = "\u{2714}" -- the base game's own tick (GroupReward Requirements Reached)
-- Legacy SAH decoration (hidden by transparency on the buttons the kit restyles).
UiKit.DECOR = {
	BevelEffect = true, InletTexture = true, DropShadow = true, Glow = true, Pattern = true, shadow = true,
	Shadow = true, ContainerShadow = true, SearchShadow = true, ["shadow-toolbar"] = true, Closure = true,
}

-- Header icons by meaning. Every id is an image already in the place (StarterGui / ReplicatedStorage.Assets.UI).
UiKit.Icons = {
	index = 140189242202677, -- blue book (the HUD Index button)
	egg = 96783034607256, -- the Steal an Egg egg sticker (HUD EGGS tab)
	shop = 78361985857528, -- green shopping cart
	basket = 96787567013749, -- red shop basket (the old Shop icon)
	speed = 123961542220277, -- lightning bolt (Speed Shop)
	trail = 78795694520145, -- comet trail
	treadmill = 140429435591753, -- treadmill
	bat = 131099804712161, -- baseball bat (gear)
	settings = 77188882273275, -- cog
	codes = 102193985057745, -- scroll
	dice = 91172938049818, -- odds
	evolve = 116946301675584, -- green up arrow (fuse / upgrade)
	trade = 80807460450475, -- swap arrows (HUD Trading button)
	moneyBag = 139742352093157, -- offline cash
	cash = 107418433037502, -- banknotes
	crown = 113221127098716, -- starter pack
	rebirth = 129578402198506, -- rebirth arrows
	alert = 95109671231611, -- red "!"
	dna = 107358579463229, -- steal DNA
	gift = 127191998618608, -- gift box
	giftRed = 139767177148368,
	star = 94279344773398, -- gold star
	clock = 71850546752124,
	check = 134146067473598,
}

-- Tiled background patterns (images already in the place), drawn faintly over the body under the studs.
UiKit.Patterns = {
	stars = 116054484875156, -- white star outlines
	flames = 86655919544454, -- little flames
	sparkles = 130029461460330, -- blue sparkles
	blocks = 118133511364596, -- cubes + critters doodles
	money = 123051839615959, -- green sparkle field (stretched, not tiled)
	bigStuds = 117164658961906, -- large studs
}

local function stops(...)
	return { ... }
end

-- Theme = band gradient (left -> right) + body / panel / card colours + icon + background pattern.
UiKit.Themes = {
	-- the two reference windows (their exact values)
	gift = {
		band = stops({ 0, "#45efff" }, { 0.5, "#00d0ff" }, { 1, "#0a9ef2" }),
		body = hex("#252a50"), card = hex("#0e1124"), cardStroke = hex("#3c4270"), panel = hex("#131726"), list = hex("#0f1220"),
		accent = hex("#36e21c"), icon = 127191998618608,
	},
	sell = {
		band = stops({ 0, "#00e676" }, { 1, "#00b0ff" }),
		body = hex("#23283f"), panel = hex("#131726"), list = hex("#0f1220"), card = hex("#2c3252"), cardStroke = hex("#3c4270"),
		accent = hex("#2bd63c"), on = hex("#2bd63c"), off = hex("#4f5674"), tabOff = hex("#1d5a2b"), icon = 140189242202677,
	},
	-- one variant per window family
	index = {
		band = stops({ 0, "#8ff6ff" }, { 0.45, "#22c7ff" }, { 1, "#1b6dff" }),
		body = hex("#1c2555"), panel = hex("#111836"), list = hex("#0d1330"), card = hex("#26306a"), cardStroke = hex("#3d4a92"),
		accent = hex("#2bd63c"), on = hex("#22c7ff"), off = hex("#3a4478"), icon = 140189242202677,
		pattern = UiKit.Patterns.sparkles, patternTile = UDim2.fromOffset(96, 96), patternTransparency = 0.93,
	},
	heroes = {
		band = stops({ 0, "#e0c8ff" }, { 0.45, "#a46bff" }, { 1, "#5a24d6" }),
		body = hex("#221a48"), panel = hex("#150f33"), list = hex("#120c2c"), card = hex("#2f2563"), cardStroke = hex("#4a3a94"),
		accent = hex("#2bd63c"), letter = "H", letterStroke = hex("#1f0a4d"),
		pattern = UiKit.Patterns.stars, patternTile = UDim2.fromOffset(110, 110), patternTransparency = 0.94,
	},
	eggs = {
		band = stops({ 0, "#ffc2ee" }, { 0.45, "#ff5fcf" }, { 1, "#b3127a" }),
		body = hex("#2c1a44"), panel = hex("#1b1030"), list = hex("#160c28"), card = hex("#3a2458"), cardStroke = hex("#5a3a86"),
		accent = hex("#2bd63c"), icon = 96783034607256,
		pattern = UiKit.Patterns.stars, patternTile = UDim2.fromOffset(110, 110), patternTransparency = 0.94,
	},
	shop = {
		band = stops({ 0, "#d2ff72" }, { 0.45, "#5ee02a" }, { 1, "#16a53a" }),
		body = hex("#1d2d3a"), panel = hex("#111c26"), list = hex("#0d1720"), card = hex("#263e4c"), cardStroke = hex("#3d6070"),
		accent = hex("#36e21c"), icon = 78361985857528,
		pattern = UiKit.Patterns.stars, patternTile = UDim2.fromOffset(110, 110), patternTransparency = 0.93,
	},
	speed = {
		band = stops({ 0, "#fff27a" }, { 0.45, "#ffbf1f" }, { 1, "#ff7a00" }),
		body = hex("#2d2240"), panel = hex("#1b1428"), list = hex("#161022"), card = hex("#3b2d52"), cardStroke = hex("#5e4a80"),
		accent = hex("#36e21c"), icon = 123961542220277,
		pattern = UiKit.Patterns.flames, patternTile = UDim2.fromOffset(90, 90), patternTransparency = 0.93,
	},
	trail = {
		band = stops({ 0, "#ff9ef0" }, { 0.45, "#d24bff" }, { 1, "#6d3cff" }),
		body = hex("#261c4a"), panel = hex("#17112e"), list = hex("#130e28"), card = hex("#33276a"), cardStroke = hex("#51409c"),
		accent = hex("#36e21c"), icon = 78795694520145,
		pattern = UiKit.Patterns.sparkles, patternTile = UDim2.fromOffset(96, 96), patternTransparency = 0.92,
	},
	treadmill = {
		band = stops({ 0, "#ffc56b" }, { 0.45, "#ff7a1a" }, { 1, "#e8363d" }),
		body = hex("#2e1e3a"), panel = hex("#1c1224"), list = hex("#170e1e"), card = hex("#3e2a4e"), cardStroke = hex("#644476"),
		accent = hex("#36e21c"), icon = 140429435591753,
		pattern = UiKit.Patterns.bigStuds, patternTile = UDim2.fromOffset(64, 64), patternTransparency = 0.9,
	},
	gear = {
		band = stops({ 0, "#ff9a8a" }, { 0.45, "#f0444f" }, { 1, "#a81645" }),
		body = hex("#2c1d34"), panel = hex("#1b1121"), list = hex("#160d1b"), card = hex("#3c2846"), cardStroke = hex("#63426f"),
		accent = hex("#36e21c"), icon = 131099804712161,
		pattern = UiKit.Patterns.bigStuds, patternTile = UDim2.fromOffset(64, 64), patternTransparency = 0.9,
	},
	settings = {
		band = stops({ 0, "#d9e3ff" }, { 0.45, "#8e9fe0" }, { 1, "#5363b4" }),
		body = hex("#20263e"), panel = hex("#141828"), list = hex("#10131f"), card = hex("#2b3350"), cardStroke = hex("#465078"),
		accent = hex("#36e21c"), icon = 77188882273275,
	},
	codes = {
		band = stops({ 0, "#7dffe0" }, { 0.45, "#1ed6c0" }, { 1, "#0a8fc4" }),
		body = hex("#18303e"), panel = hex("#0e1d26"), list = hex("#0b171f"), card = hex("#21404f"), cardStroke = hex("#386476"),
		accent = hex("#36e21c"), icon = 102193985057745,
		pattern = UiKit.Patterns.sparkles, patternTile = UDim2.fromOffset(96, 96), patternTransparency = 0.93,
	},
	odds = {
		band = stops({ 0, "#fff08a" }, { 0.45, "#ffc21f" }, { 1, "#ff8c00" }),
		body = hex("#2a2442"), panel = hex("#19152a"), list = hex("#141123"), card = hex("#383058"), cardStroke = hex("#5a4f86"),
		accent = hex("#36e21c"), icon = 91172938049818,
		pattern = UiKit.Patterns.stars, patternTile = UDim2.fromOffset(110, 110), patternTransparency = 0.93,
	},
	fuse = {
		band = stops({ 0, "#d9a8ff" }, { 0.45, "#9b4dff" }, { 1, "#e0339e" }),
		body = hex("#251b48"), panel = hex("#16102e"), list = hex("#120d27"), card = hex("#322566"), cardStroke = hex("#503f96"),
		accent = hex("#36e21c"), icon = 116946301675584,
		pattern = UiKit.Patterns.sparkles, patternTile = UDim2.fromOffset(96, 96), patternTransparency = 0.92,
	},
	trade = {
		band = stops({ 0, "#9ec5ff" }, { 0.45, "#4d86ff" }, { 1, "#3b3fd9" }),
		body = hex("#1e2450"), panel = hex("#121633"), list = hex("#0e122b"), card = hex("#29316a"), cardStroke = hex("#434e98"),
		accent = hex("#36e21c"), icon = 80807460450475,
		pattern = UiKit.Patterns.sparkles, patternTile = UDim2.fromOffset(96, 96), patternTransparency = 0.93,
	},
	offline = {
		band = stops({ 0, "#b6ff7a" }, { 0.45, "#3ddc4f" }, { 1, "#0f9f6e" }),
		body = hex("#1b3036"), panel = hex("#101d21"), list = hex("#0c171a"), card = hex("#244048"), cardStroke = hex("#3a626c"),
		accent = hex("#36e21c"), icon = 139742352093157,
		pattern = UiKit.Patterns.money, patternStretch = true, patternTransparency = 0.8,
	},
	starter = {
		band = stops({ 0, "#ffe57a" }, { 0.45, "#ffa31a" }, { 1, "#ff4d6d" }),
		body = hex("#33223f"), panel = hex("#1f1427"), list = hex("#191021"), card = hex("#442e54"), cardStroke = hex("#6a4a80"),
		accent = hex("#36e21c"), icon = 113221127098716,
		pattern = UiKit.Patterns.stars, patternTile = UDim2.fromOffset(110, 110), patternTransparency = 0.92,
	},
	rebirth = {
		band = stops({ 0, "#ffa3e2" }, { 0.45, "#ff3fb4" }, { 1, "#a31bff" }),
		body = hex("#2c1a44"), panel = hex("#1b1030"), list = hex("#160c28"), card = hex("#3a2458"), cardStroke = hex("#5a3a86"),
		accent = hex("#e405f8"), icon = 129578402198506,
		pattern = UiKit.Patterns.sparkles, patternTile = UDim2.fromOffset(96, 96), patternTransparency = 0.92,
	},
	message = {
		band = stops({ 0, "#8fe3ff" }, { 0.45, "#3fa9ff" }, { 1, "#2d62ff" }),
		body = hex("#212a52"), panel = hex("#141a36"), list = hex("#10152d"), card = hex("#2c376c"), cardStroke = hex("#465399"),
		accent = hex("#36e21c"), icon = 95109671231611,
	},
	danger = {
		band = stops({ 0, "#ff9a86" }, { 0.45, "#ff4b4b" }, { 1, "#c8143c" }),
		body = hex("#2e1d3a"), panel = hex("#1c1124"), list = hex("#170d1e"), card = hex("#3e284e"), cardStroke = hex("#644276"),
		accent = hex("#36e21c"), icon = 107358579463229,
	},
	freegifts = {
		band = stops({ 0, "#45efff" }, { 0.5, "#00d0ff" }, { 1, "#0a9ef2" }),
		body = hex("#252a50"), card = hex("#0e1124"), cardStroke = hex("#3c4270"), panel = hex("#131726"), list = hex("#0f1220"),
		accent = hex("#36e21c"), icon = 139767177148368,
		pattern = UiKit.Patterns.stars, patternTile = UDim2.fromOffset(110, 110), patternTransparency = 0.93,
	},
}

---------------------------------------------------------------------------------------------------
-- geometry
---------------------------------------------------------------------------------------------------

-- The child `name` of exact class `className` (created when missing), with BorderSizePixel 0 and (not scrolling)
-- Active false so a decoration layer never eats clicks.
function UiKit.layer(parent, className, name, zIndex)
	local node = Kit.ensureChild(parent, className, name)
	node.BorderSizePixel = 0
	if not node:IsA("ScrollingFrame") then
		node.Active = false
	end
	if zIndex then
		node.ZIndex = zIndex
	end
	return node
end

function UiKit.setBox(node, anchor, position, size)
	node.AnchorPoint = anchor or Vector2.new(0.5, 0.5)
	node.Position = position or UDim2.fromScale(0.5, 0.5)
	node.Size = size or UDim2.fromScale(1, 1)
	return node
end

function UiKit.aspect(node, ratio)
	local constraint = node:FindFirstChildOfClass("UIAspectRatioConstraint") or Kit.ensureChild(node, "UIAspectRatioConstraint", Kit.Names.aspect)
	constraint.AspectRatio = ratio
	return constraint
end

-- UICorner radius (scale of the node's short side) that matches a radius of `rootCorner` x the root's height on a
-- node `heightFraction` of the root tall (the windows here are landscape: their short side is the height).
function UiKit.cornerFor(rootCorner, heightFraction)
	return math.min(0.5, rootCorner / math.max(heightFraction, 0.01))
end

-- Top corners rounded, bottom corners square.
function UiKit.topCorner(node, radius)
	local corner = Kit.setCorner(node, radius)
	corner.BottomLeftRadius = UDim.new(0, 0)
	corner.BottomRightRadius = UDim.new(0, 0)
	return corner
end

-- Bottom corners rounded, top corners square (a body under an "above" band).
function UiKit.bottomCorner(node, radius)
	local corner = Kit.setCorner(node, radius)
	corner.TopLeftRadius = UDim.new(0, 0)
	corner.TopRightRadius = UDim.new(0, 0)
	return corner
end

-- The box of `node` in `root` scale units (x, y = top-left; w, h), following a scale-only parent chain. Offsets and
-- aspect constraints below the root are ignored (the windows are laid out in scale).
function UiKit.boxOf(node, root)
	if node == root then
		return 0, 0, 1, 1
	end
	local px, py, pw, ph = UiKit.boxOf(node.Parent, root)
	local w, h = node.Size.X.Scale * pw, node.Size.Y.Scale * ph
	local x = px + node.Position.X.Scale * pw - node.AnchorPoint.X * w
	local y = py + node.Position.Y.Scale * ph - node.AnchorPoint.Y * h
	return x, y, w, h
end

-- Rendered height (px) of a ScreenGui root frame on a 1280x720 screen (topbar inset 58 unless IgnoreGuiInset),
-- from its scale Size and its UIAspectRatioConstraint (FitWithinMaxSize).
function UiKit.rootPixels(root)
	local parent = root.Parent
	local parentW, parentH
	if parent and parent:IsA("GuiObject") then
		parentW, parentH = UiKit.rootPixels(parent)
	else
		local inset = (parent and Kit.prop(parent, "IgnoreGuiInset")) and 0 or 58
		parentW, parentH = 1280, 720 - inset
	end
	local w = root.Size.X.Scale * parentW + root.Size.X.Offset
	local h = root.Size.Y.Scale * parentH + root.Size.Y.Offset
	local ratio = root:FindFirstChildOfClass("UIAspectRatioConstraint")
	if ratio and ratio.AspectRatio > 0 then
		if w / h > ratio.AspectRatio then
			w = h * ratio.AspectRatio
		else
			h = w / ratio.AspectRatio
		end
	end
	return w, h
end

-- Band height as a fraction of the root's height that renders ~`px` pixels tall at 1280x720 (the reference bands are
-- ~65 px there), clamped to [0.07, 0.22].
function UiKit.bandHeightFor(root, px)
	local _, h = UiKit.rootPixels(root)
	return math.clamp((px or 64) / math.max(h, 1), 0.07, 0.22)
end

-- True when `node` renders in a ScreenGui with Global ZIndexBehavior (a child's ZIndex is then global, not relative
-- to its parent: every layer the kit adds must be ordered with explicit, absolute ZIndex values).
function UiKit.isGlobal(node)
	local gui = node and node:FindFirstAncestorWhichIsA("LayerCollector")
	return gui ~= nil and Kit.prop(gui, "ZIndexBehavior") == Enum.ZIndexBehavior.Global
end

-- Lowest ZIndex of the real content under `root` (kit layers, legacy decoration and opts.exclude names excluded).
function UiKit.minContentZ(root, exclude)
	local minZ = root.ZIndex
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiObject") and not Kit.isKitName(d.Name) and not UiKit.DECOR[d.Name] and not (exclude and exclude[d.Name]) then
			minZ = math.min(minZ, d.ZIndex)
		end
	end
	return minZ
end

---------------------------------------------------------------------------------------------------
-- layers
---------------------------------------------------------------------------------------------------

-- Tiled stud texture (Kit.Images.stud) over the whole node.
function UiKit.studs(parent, zIndex, opts)
	opts = opts or {}
	local studs = UiKit.layer(parent, "ImageLabel", opts.name or "SpStuds", zIndex)
	Kit.setImage(studs, Kit.Images.stud)
	studs.BackgroundTransparency = 1
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = opts.tile or UiKit.STUD_TILE
	studs.ImageColor3 = opts.color or WHITE
	studs.ImageTransparency = opts.transparency or UiKit.STUD_TRANSPARENCY
	UiKit.setBox(studs)
	if opts.corner then
		Kit.setCorner(studs, opts.corner)
	end
	return studs
end

-- White highlight on the upper part of a node, fading out downwards.
function UiKit.gloss(parent, zIndex, opts)
	opts = opts or {}
	local gloss = UiKit.layer(parent, "Frame", opts.name or "SpGloss", zIndex)
	gloss.BackgroundColor3 = WHITE
	gloss.BackgroundTransparency = 0
	UiKit.setBox(gloss, Vector2.new(0.5, 0), UDim2.fromScale(0.5, opts.top or 0.07), UDim2.fromScale(opts.width or 0.9, opts.height or 0.42))
	Kit.addGradient(gloss, WHITE, 90, "SpGlossGradient", { transparency = { { 0, opts.strength or 0.5 }, { 1, 1 } } })
	Kit.setCorner(gloss, opts.corner or 0.5)
	return gloss
end

-- Two diagonal "/" light streaks (refs 06/07): one white layer, the bands are drawn by its gradient transparency.
-- UIGradient rotates in the layer's normalised space, so the angle is corrected by the layer's aspect (w / h) to
-- give 60 degree streaks on screen.
function UiKit.streaks(parent, zIndex, layerAspect)
	local streaks = UiKit.layer(parent, "Frame", "SpStreaks", zIndex)
	streaks.BackgroundColor3 = WHITE
	streaks.BackgroundTransparency = 0
	UiKit.setBox(streaks)
	local rotation = math.deg(math.atan(0.5774 / math.max(layerAspect, 0.1)))
	Kit.addGradient(streaks, WHITE, rotation, "SpStreakGradient", { transparency = {
		{ 0, 1 }, { 0.5, 1 }, { 0.505, 0.8 }, { 0.565, 0.8 }, { 0.57, 1 }, { 0.61, 1 }, { 0.615, 0.87 }, { 0.64, 0.87 },
		{ 0.645, 1 }, { 1, 1 },
	} })
	return streaks
end

-- The theme's faint background pattern (SpPattern): tiled (theme.patternTile) or stretched (theme.patternStretch).
-- Owner 2026-09-27: the Roblox stud texture is the only UI texture (the studs layer UiKit.body draws); no theme pattern
-- (stars, flames, sparkles, blocks, money, big studs) is drawn any more, an old one is hidden.
UiKit.THEME_PATTERNS = false
function UiKit.pattern(parent, zIndex, theme)
	if theme == nil or theme.pattern == nil or not UiKit.THEME_PATTERNS then
		local old = parent:FindFirstChild("SpPattern")
		if old and old:IsA("ImageLabel") and old.Name == "SpPattern" and old:GetAttribute("SpThemePattern") then
			old.ImageTransparency = 1
		end
		return nil
	end
	local art = UiKit.layer(parent, "ImageLabel", "SpPattern", zIndex)
	Kit.setImage(art, theme.pattern)
	art.BackgroundTransparency = 1
	art.ImageColor3 = theme.patternColor or WHITE
	art.ImageTransparency = theme.patternTransparency or 0.92
	if theme.patternStretch then
		art.ScaleType = Enum.ScaleType.Crop
	else
		art.ScaleType = Enum.ScaleType.Tile
		art.TileSize = theme.patternTile or UDim2.fromOffset(96, 96)
	end
	UiKit.setBox(art)
	if theme.corner then
		Kit.setCorner(art, theme.corner)
	end
	art:SetAttribute("SpThemePattern", true)
	return art
end

---------------------------------------------------------------------------------------------------
-- window
---------------------------------------------------------------------------------------------------

local function disablePainterGradients(inst)
	for _, c in ipairs(inst:GetChildren()) do
		if c:IsA("UIGradient") and not Kit.isKitName(c.Name) and Kit.prop(c, "Enabled") ~= false then
			c.Enabled = false
		end
	end
end

-- Dark studded body on the window painter: the Speedsters window material (Kit.skinWindow: its art layer is kept
-- faint), then a dark fill, the stud texture at ~15 %, a thick ink rim and a light inner rim. opts: color (required),
-- corner (required), art, artTint, transparency, hide, theme (adds its SpPattern), noStuds. Returns the
-- Kit.skinWindow result ({ background, stroke, ... }).
function UiKit.body(root, painter, opts)
	if root == nil or painter == nil then
		return nil
	end
	local res = Kit.skinWindow(root, painter, { art = opts.art, hide = opts.hide })
	disablePainterGradients(painter)
	if painter ~= root then
		root.BackgroundTransparency = 1
		if root:IsA("ImageLabel") or root:IsA("ImageButton") then
			root.ImageTransparency = 1
		end
	end
	painter.BackgroundColor3 = opts.color
	painter.BackgroundTransparency = opts.transparency or 0.03
	Kit.setCorner(painter, opts.corner)
	local bg = res and res.background
	if bg then
		bg.ImageColor3 = opts.artTint or hex("#7d88c2")
		bg.ImageTransparency = 0.9
		Kit.setCorner(bg, opts.corner)
	end
	local z = (bg and bg.ZIndex or 0) + 1
	if bg and UiKit.isGlobal(painter) then
		-- Global ZIndexBehavior: the painter's own fill would be drawn above every layer with a lower ZIndex, so the
		-- fill moves onto SpBackground under the content and the pattern / studs share its ZIndex (tree order)
		bg.ZIndex = math.min(bg.ZIndex, UiKit.minContentZ(root, opts.globalExclude) - 1)
		bg.BackgroundColor3 = opts.color
		bg.BackgroundTransparency = opts.transparency or 0.03
		painter.BackgroundTransparency = 1
		z = bg.ZIndex
	end
	if opts.theme and opts.theme.pattern and not Kit.hasLayout(painter) then
		local art = UiKit.pattern(painter, z, opts.theme) -- nil while UiKit.THEME_PATTERNS is off (stud texture only)
		if art then
			Kit.setCorner(art, opts.corner)
		end
	end
	if not opts.noStuds and not Kit.hasLayout(painter) then
		UiKit.studs(painter, z, { corner = opts.corner })
	end
	Kit.addStroke(painter, { name = Kit.Names.stroke, color = INK, thickness = 0.011, mode = "Border" })
	Kit.addStroke(painter, { name = "SpRimLight", color = hex("#7780b3"), transparency = 0.45, thickness = 0.004,
		borderOffset = -0.005, zIndex = 2, mode = "Border" })
	return res
end

-- Glossy header band: left -> right colour gradient, streaks, studs, a top gloss, a darker bottom and an ink line
-- under it. opts: colors (stops), height (fraction of the root), rootCorner, rootAspect, zIndex, name ("SpHeaderBand"),
-- box = { x, y, w, h } (root scale: the body's left edge, top edge, width and height; default 0, 0, 1, 1),
-- placement "inside" (default: the band covers the top of the box) or "above" (the band sits on top of the box).
function UiKit.headerBand(root, opts)
	local height = opts.height
	local box = opts.box or { 0, 0, 1, 1 }
	local band = UiKit.layer(root, "Frame", opts.name or "SpHeaderBand", opts.zIndex)
	band.BackgroundColor3 = WHITE
	band.BackgroundTransparency = 0
	local anchorY = if opts.placement == "above" then 1 else 0
	UiKit.setBox(band, Vector2.new(0.5, anchorY), UDim2.fromScale(box[1] + box[3] / 2, box[2]), UDim2.fromScale(box[3], height))
	Kit.addGradient(band, opts.colors, 0, "SpBandGradient")
	local bandAspect = opts.rootAspect * box[3] / height
	local radius = UiKit.cornerFor(opts.rootCorner, height)
	UiKit.topCorner(band, radius)
	-- Global ZIndexBehavior: the band's layers are ordered above the band itself
	local z0 = if UiKit.isGlobal(root) then band.ZIndex else 0
	-- full-size layers get the band's rounded top (UICorner does not clip children)
	UiKit.topCorner(UiKit.streaks(band, z0 + 1, bandAspect), radius)
	UiKit.topCorner(UiKit.studs(band, z0 + 2, { transparency = 0.8 }), radius)
	local gloss = UiKit.gloss(band, z0 + 3, { top = 0, width = 1, height = 0.55, strength = 0.55 })
	UiKit.topCorner(gloss, UiKit.cornerFor(opts.rootCorner, height * 0.55))
	local shade = UiKit.layer(band, "Frame", "SpShade", z0 + 3)
	shade.BackgroundColor3 = BLACK
	shade.BackgroundTransparency = 0
	UiKit.setBox(shade, Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.fromScale(1, 0.5))
	Kit.addGradient(shade, BLACK, 90, "SpShadeGradient", { transparency = { { 0, 1 }, { 1, 0.74 } } })
	local line = UiKit.layer(band, "Frame", "SpBandLine", z0 + 4)
	line.BackgroundColor3 = INK
	line.BackgroundTransparency = 0
	UiKit.setBox(line, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 1), UDim2.fromScale(1, 0.05))
	if opts.placement == "above" then
		-- the band's ink rim (the body's rim covers the other three sides)
		-- (ScaledSize strokes scale with the node's short side: the band's height vs the body's)
		Kit.addStroke(band, { name = "SpRim", color = INK, thickness = 0.011 * (box[4] or 1) / height, mode = "Border" })
	end
	return band
end

-- Band title face: white GothamSSm Bold, thick ink outline, left aligned, scaled. SAH stacked copies (a dark copy with
-- a white face child, or DropShadow copies) are the caller's business (see scripts/steps/ui_20_windows styleTitle).
function UiKit.title(label, opts)
	opts = opts or {}
	if label == nil or not Kit.isText(label) then
		return nil
	end
	if opts.text then
		label.Text = opts.text
	end
	Kit.styleText(label, opts.kind or "title", {
		color = (not opts.keepColor) and WHITE or nil, keepColor = opts.keepColor, scaled = true,
		strokeThickness = opts.strokeThickness or 0.08, disableGradients = not opts.keepGradient,
	})
	label.TextXAlignment = opts.alignX or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Rotation = 0
	return label
end

-- Places a title node (a TextLabel or a Frame holding the title faces) on the band of `root`: left edge after the
-- icon (opts.left, root scale), vertically centred on the band, opts.height x the band height tall.
-- band = { top, height, x, w } in root scale (see UiKit.chrome).
function UiKit.placeTitle(node, band, opts)
	opts = opts or {}
	if node == nil or not node:IsA("GuiObject") then
		return nil
	end
	local left = opts.left or (band.x + 0.1 * band.w)
	local width = opts.width or (band.x + band.w - left - 0.12 * band.w)
	UiKit.setBox(node, Vector2.new(0, 0.5), UDim2.fromScale(left, band.top + band.height / 2),
		UDim2.fromScale(width, band.height * (opts.height or 0.64)))
	node.Rotation = 0
	if opts.zIndex then
		node.ZIndex = opts.zIndex
	end
	return node
end

-- A big glossy letter in place of an icon (the HUD's "H" hero tab recipe).
function UiKit.letterIcon(parent, letter, opts)
	opts = opts or {}
	local face = UiKit.layer(parent, "TextLabel", opts.name or "SpLetter", opts.zIndex)
	face.Text = letter
	face.FontFace = roblox.Font.fromEnum(Enum.Font.FredokaOne)
	face.TextColor3 = WHITE
	face.TextScaled = true
	face.TextWrapped = true
	face.TextXAlignment = Enum.TextXAlignment.Center
	face.TextYAlignment = Enum.TextYAlignment.Center
	face.TextStrokeTransparency = 1
	face.BackgroundTransparency = 1
	face.Rotation = 0
	face.Visible = true
	Kit.addGradient(face, { { 0, "#ffffff" }, { 0.55, "#ffffff" }, { 1, "#e2d2ff" } }, 90, Kit.Names.textGradient)
	Kit.addStroke(face, { name = "SpTextStroke", color = opts.strokeColor or INK, thickness = 0.12, mode = "Contextual", zIndex = 1 })
	return face
end

-- Header icon on the band: an existing SAH icon ImageLabel re-arted (opts.existing), else an SpHeaderIcon layer (or,
-- for a string, an SpLetter glossy letter). Tagged SpHeaderIcon = true for the runtime bounce
-- (Library.Client.SpeedstersWindowJuice). opts: position, size (square via aspect 1), zIndex, parent, strokeColor.
function UiKit.headerIcon(root, icon, opts)
	opts = opts or {}
	local parent = opts.parent or root
	local node
	if type(icon) == "string" then
		node = UiKit.letterIcon(parent, icon, { name = "SpHeaderLetter", strokeColor = opts.strokeColor, zIndex = opts.zIndex })
		local image = parent:FindFirstChild(Kit.Names.headerIcon)
		if image and image:IsA("ImageLabel") then
			image.ImageTransparency = 1
			image:SetAttribute("SpHeaderIcon", nil) -- the runtime bounce takes the first tagged node: the letter only
		end
	elseif opts.existing and (opts.existing:IsA("ImageLabel") or opts.existing:IsA("ImageButton")) then
		node = opts.existing
		if icon then
			Kit.setImage(node, icon)
		end
		node.ImageTransparency = 0
		node.ImageColor3 = WHITE
		node.BackgroundTransparency = 1
		node.ScaleType = Enum.ScaleType.Fit
		Kit.hideLegacyStrokes(node)
		for _, c in ipairs(node:GetChildren()) do
			if c:IsA("ImageLabel") and Kit.DECOR_NAMES[c.Name] or (c:IsA("ImageLabel") and c.Name == "Closure") then
				Kit.hideDecoration(c)
			end
		end
	else
		node = UiKit.layer(parent, "ImageLabel", Kit.Names.headerIcon, opts.zIndex)
		Kit.setImage(node, icon)
		node.BackgroundTransparency = 1
		node.ImageTransparency = 0
		node.ImageColor3 = WHITE
		node.ScaleType = Enum.ScaleType.Fit
	end
	UiKit.setBox(node, Vector2.new(0.5, 0.5), opts.position, opts.size)
	UiKit.aspect(node, 1)
	if opts.zIndex then
		node.ZIndex = opts.zIndex
	end
	node:SetAttribute("SpHeaderIcon", true)
	return node
end

-- Round embossed close (ref 06/07 X): the Speedsters round X art stays on Close.TextButton (ConsoleCmds contract),
-- with an ink rim and a dark disc offset under the glyph. Every text child is set to FredokaOne (the hidden 'X').
function UiKit.closeButton(close, position, size, zIndex)
	if close == nil or not close:IsA("GuiButton") then
		return nil
	end
	Kit.skinCloseButton(close, { place = false })
	for _, d in ipairs(close:GetDescendants()) do
		if Kit.isText(d) then
			Kit.setFont(d, "body")
		end
	end
	if zIndex then
		close.ZIndex = zIndex
	end
	UiKit.setBox(close, Vector2.new(0.5, 0.5), position, size)
	UiKit.aspect(close, 1)
	Kit.setCorner(close, 0.5)
	Kit.addStroke(close, { name = "SpRim", color = INK, thickness = 0.07, mode = "Border" })
	local glyph = close:FindFirstChild("TextButton")
	if glyph and glyph:IsA("GuiObject") and UiKit.isGlobal(close) and glyph.ZIndex <= close.ZIndex then
		glyph.ZIndex = close.ZIndex + 2 -- Global: the X must stay above the band it sits on
	end
	local glyphZ = if glyph and glyph:IsA("GuiObject") then glyph.ZIndex else close.ZIndex + 2
	local emboss = UiKit.layer(close, "Frame", "SpEmboss", glyphZ - 1)
	emboss.BackgroundColor3 = BLACK
	emboss.BackgroundTransparency = 0.4
	UiKit.setBox(emboss, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.58), UDim2.fromScale(0.98, 0.98))
	Kit.setCorner(emboss, 0.5)
	return close
end

---------------------------------------------------------------------------------------------------
-- content
---------------------------------------------------------------------------------------------------

-- Chunky glossy button: its colour is BackgroundColor3 (opts.owned.BackgroundColor3 leaves a scripted colour alone),
-- GLOSS_FILL multiplies it into a vertical gloss with a relief lip, a top highlight, an ink rim. The label must be a
-- child TextLabel (a gradient would tint the button's own text).
function UiKit.glossButton(button, opts)
	opts = opts or {}
	if button == nil or not button:IsA("GuiObject") then
		return nil
	end
	local owned = opts.owned or {}
	if opts.color and not owned.BackgroundColor3 then
		button.BackgroundColor3 = opts.color
	end
	button.BackgroundTransparency = 0
	if button:IsA("ImageLabel") or button:IsA("ImageButton") then
		button.ImageTransparency = 1
	end
	if button:IsA("GuiButton") then
		button.AutoButtonColor = false
	end
	for _, c in ipairs(button:GetChildren()) do
		if c:IsA("UIGradient") and c.Name ~= Kit.Names.fill then
			c.Enabled = false
		elseif c:IsA("GuiObject") and (UiKit.DECOR[c.Name] or c.Name == Kit.Names.skin) then
			Kit.hideDecoration(c, { recursive = true })
		end
	end
	Kit.hideLegacyStrokes(button, { borderOnly = Kit.isText(button) })
	local light = button:FindFirstChild(Kit.Names.strokeLight)
	if light and light:IsA("UIStroke") then
		light.Transparency = 1 -- a Speedsters pill's light rim (the glossy button has one ink rim)
	end
	Kit.setCorner(button, opts.corner or 0.28)
	Kit.addGradient(button, UiKit.GLOSS_FILL, 90, Kit.Names.fill)
	UiKit.gloss(button, opts.glossZ or 1, { top = 0.08, width = 0.9, height = 0.38, strength = opts.glossStrength or 0.45 })
	Kit.addStroke(button, { name = Kit.Names.strokeDark, color = opts.strokeColor or INK, thickness = opts.stroke or 0.05, mode = "Border" })
	return button
end

-- A TextLabel the step owns (created or reused), styled.
function UiKit.text(parent, name, text, kind, opts)
	opts = opts or {}
	local label = UiKit.layer(parent, "TextLabel", name, opts.zIndex or 4)
	label.Text = text
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextWrapped = true
	label.RichText = opts.rich == true
	label.TextXAlignment = opts.alignX or Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	UiKit.setBox(label, opts.anchor, opts.position, opts.size)
	Kit.styleText(label, kind or "body", {
		color = opts.color or WHITE, strokeThickness = opts.stroke, strokeColor = opts.strokeColor,
		gradient = opts.gradient, gradientRotation = opts.gradientRotation,
	})
	return label
end

-- A text-less TextButton + child Label, glossy.
function UiKit.labelButton(parent, name, caption, opts)
	local button = UiKit.layer(parent, "TextButton", name, opts.zIndex or 3)
	button.Active = true
	button.Text = ""
	button.Selectable = true
	UiKit.setBox(button, opts.anchor, opts.position, opts.size)
	UiKit.glossButton(button, { color = opts.color, corner = opts.corner, stroke = opts.stroke })
	local label = UiKit.text(button, "Label", caption, opts.kind or "button", {
		position = opts.labelPosition or UDim2.fromScale(0.5, 0.47), size = opts.labelSize or UDim2.fromScale(0.86, 0.62),
		zIndex = 3, stroke = opts.labelStroke, alignX = opts.alignX,
	})
	return button, label
end

-- Dark rounded panel with an ink rim (Sell Heroes' Sort By / Total Value). opts.owned.BackgroundColor3 /
-- BackgroundTransparency keep a scripted colour; legacy strokes (except those a script sizes) are hidden.
function UiKit.panel(frame, opts)
	opts = opts or {}
	if frame == nil or not frame:IsA("GuiObject") then
		return nil
	end
	local owned = opts.owned or {}
	if not owned.BackgroundColor3 then
		frame.BackgroundColor3 = opts.color or UiKit.Themes.sell.panel
	end
	if not owned.BackgroundTransparency then
		frame.BackgroundTransparency = opts.transparency or 0.15
	end
	if frame:IsA("ImageLabel") or frame:IsA("ImageButton") then
		if not owned.Image then
			frame.ImageTransparency = 1
		end
	end
	Kit.setCorner(frame, opts.corner or 0.1)
	if not opts.keepStrokes then
		for _, c in ipairs(frame:GetChildren()) do
			if c:IsA("UIStroke") and not Kit.isKitName(c.Name) and c:GetAttribute("OriginalThickness") == nil then
				c.Transparency = 1
			end
		end
	end
	if not owned.UIGradient then
		disablePainterGradients(frame)
	end
	if opts.stroke ~= false then
		Kit.addStroke(frame, { name = Kit.Names.stroke, color = opts.strokeColor or INK, thickness = opts.stroke or 0.02, mode = "Border" })
	end
	return frame
end

-- Dark rounded card with a soft rim (Free Gift's step cards).
function UiKit.card(frame, opts)
	opts = opts or {}
	if frame == nil or not frame:IsA("GuiObject") then
		return nil
	end
	local owned = opts.owned or {}
	if (frame:IsA("ImageLabel") or frame:IsA("ImageButton")) and not owned.Image then
		frame.ImageTransparency = 1
	end
	if not owned.BackgroundColor3 then
		frame.BackgroundColor3 = opts.color or UiKit.Themes.gift.card
	end
	if not owned.BackgroundTransparency then
		frame.BackgroundTransparency = opts.transparency or 0.05
	end
	Kit.setCorner(frame, opts.corner or 0.09)
	Kit.hideLegacyStrokes(frame)
	Kit.addStroke(frame, { name = Kit.Names.stroke, color = opts.strokeColor or UiKit.Themes.gift.cardStroke, thickness = opts.stroke or 0.014, mode = "Border" })
	return frame
end

-- Dark text input (holder panel + FredokaOne text).
function UiKit.input(holder, box, theme)
	if box and Kit.isText(box) then
		Kit.setFont(box, "body")
	end
	if holder and holder:IsA("GuiObject") and not holder:IsA("ScrollingFrame") then
		holder.BackgroundColor3 = (theme and theme.list) or UiKit.Themes.sell.list
		holder.BackgroundTransparency = 0.05
		Kit.setCorner(holder, 0.25)
		Kit.hideLegacyStrokes(holder)
		Kit.addStroke(holder, { name = Kit.Names.stroke, color = INK, thickness = 0.05, mode = "Border" })
		Kit.addStroke(holder, { name = "SpRimLight", color = (theme and theme.cardStroke) or UiKit.Themes.gift.cardStroke,
			thickness = 0.03, borderOffset = -0.04, zIndex = 2, mode = "Border" })
	end
	return holder
end

-- Glossy square side tab with a caption on top and an icon under it (Sell Heroes' HEROES / EGGS).
function UiKit.tab(parent, name, caption, iconId, opts)
	opts = opts or {}
	local tab = UiKit.labelButton(parent, name, caption, {
		color = opts.color, corner = opts.corner or 0.16, stroke = opts.stroke or 0.045, kind = "tab",
		labelPosition = UDim2.fromScale(0.5, 0.2), labelSize = UDim2.fromScale(0.9, 0.27),
	})
	if opts.layoutOrder then
		tab.LayoutOrder = opts.layoutOrder
	end
	tab.Size = opts.size or UDim2.fromScale(1, 0.48)
	local icon = UiKit.layer(tab, "ImageLabel", "Icon", 3)
	Kit.setImage(icon, iconId)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	UiKit.setBox(icon, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.63), UDim2.fromScale(0.62, 0.62))
	UiKit.aspect(icon, 1)
	return tab
end

---------------------------------------------------------------------------------------------------
-- one-call window chrome
---------------------------------------------------------------------------------------------------

-- Full window chrome on an existing window: body + band + icon + title + close.
--   root     the window root (TabController's frame: Close stays its direct child);
--   painter  the node that draws the window box (root itself, or e.g. Background);
--   theme    a UiKit.Themes entry (band, body, icon | letter, pattern);
--   spec     { corner = 0.035, bandPx = 64 | bandHeight = fraction, placement = "above" | "inside",
--              title = node (TextLabel or a Frame of faces) | nil, titleFaces = { labels } | nil, text = string | nil
--              (text without a title node creates a static SpTitle TextLabel), keepTitleColor, showTitle,
--              icon = { existing = node } | nil, noIcon = true, close = node | nil, zBand = int,
--              zTop = int (title; icon = zTop + 1, close = zTop + 2), globalExclude = { [name] = true },
--              recenter = true (an "above" band shifts the root AnchorPoint so the whole window stays centred),
--              hide = { instances }, art = image id }
-- Returns { band = frame, box = { top, height, x, w }, icon, title, close, rootAspect }.
function UiKit.chrome(root, painter, theme, spec)
	spec = spec or {}
	painter = painter or root
	local corner = spec.corner or 0.035
	local x, y, w, h = UiKit.boxOf(painter, root)
	local bandH = spec.bandHeight or UiKit.bandHeightFor(root, spec.bandPx or 64)
	local placement = spec.placement or "above"
	local pxW, pxH = UiKit.rootPixels(root)
	local rootAspect = pxW / math.max(pxH, 1)
	-- body corners: scale of the painter's short side matching `corner` x the root's height
	local bodyCorner = UiKit.cornerFor(corner, h)
	UiKit.body(root, painter, {
		color = theme.body, corner = bodyCorner, theme = theme, hide = spec.hide, art = spec.art, globalExclude = spec.globalExclude,
	})
	local bandTop = if placement == "above" then y - bandH else y
	if placement == "above" then
		-- the band caps the body: the body's top corners go square
		local c = painter:FindFirstChildOfClass("UICorner")
		if c then
			c.TopLeftRadius = UDim.new(0, 0)
			c.TopRightRadius = UDim.new(0, 0)
		end
		for _, name in ipairs({ Kit.Names.background, "SpStuds", "SpPattern" }) do
			local l = painter:FindFirstChild(name)
			local lc = l and l:FindFirstChildOfClass("UICorner")
			if lc then
				lc.TopLeftRadius = UDim.new(0, 0)
				lc.TopRightRadius = UDim.new(0, 0)
			end
		end
	end
	local band = UiKit.headerBand(root, {
		colors = theme.band, height = bandH, zIndex = spec.zBand, rootCorner = corner, rootAspect = rootAspect,
		box = { x, y, w, h }, placement = placement,
	})
	local bandBox = { top = bandTop, height = bandH, x = x, w = w }
	local zTop = spec.zTop or 12
	-- icon at the band's left end (a square as tall as ~1.25 x the band, popping a little out of it)
	local iconSize = bandH * 1.25
	local iconX = x + (iconSize * 0.62) / rootAspect -- root width units: the icon is square in pixels
	local iconNode = nil
	local left = x + 0.04 * w
	if not spec.noIcon then
		iconNode = UiKit.headerIcon(root, theme.letter or theme.icon, {
			existing = spec.icon and spec.icon.existing, position = UDim2.fromScale(iconX, bandTop + bandH * 0.47),
			size = UDim2.fromScale(iconSize / rootAspect, iconSize), zIndex = zTop + 1, strokeColor = theme.letterStroke,
		})
		-- the title starts after the icon
		left = iconX + (iconSize * 0.62) / rootAspect
	end
	local closeSize = bandH * 0.78
	local closeX = x + w - (closeSize * 0.75) / rootAspect
	local titleNode = spec.title
	if titleNode == nil and spec.text then
		-- a static title the kit owns (the window's own title is laid out by a UIListLayout, or it has none)
		titleNode = UiKit.layer(root, "TextLabel", "SpTitle", zTop)
		titleNode.BackgroundTransparency = 1
		titleNode.Text = spec.text
	end
	if titleNode then
		UiKit.placeTitle(titleNode, bandBox, { left = left, width = closeX - left - (closeSize * 0.8) / rootAspect, zIndex = zTop })
		if titleNode:IsA("GuiObject") and not titleNode.Visible and spec.showTitle then
			titleNode.Visible = true
		end
		local faces = spec.titleFaces or { titleNode }
		for _, face in ipairs(faces) do
			if Kit.isText(face) then
				UiKit.title(face, { text = spec.text, keepColor = spec.keepTitleColor })
				if face ~= titleNode then
					UiKit.setBox(face, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1))
				end
			end
		end
	end
	local closeNode = spec.close
	if closeNode then
		UiKit.closeButton(closeNode, UDim2.fromScale(closeX, bandTop + bandH / 2), UDim2.fromScale(closeSize / rootAspect, closeSize), zTop + 2)
	end
	-- keep the whole window (band + body) centred: a root opened at the screen centre (every TabController window)
	-- gets the visual box's centre as its AnchorPoint; any other root keeps its old visual centre. The first anchor is
	-- remembered (SpBaseAnchorY) so a second pass does not shift twice.
	if placement == "above" and spec.recenter ~= false then
		local base = root:GetAttribute("SpBaseAnchorY")
		if base == nil then
			base = root.AnchorPoint.Y
			root:SetAttribute("SpBaseAnchorY", base)
		end
		local visualCentre = (bandTop + y + h) / 2
		local centred = root.Position.Y.Scale == 0.5 and root.Position.Y.Offset == 0
		local anchorY = if centred then visualCentre else base + visualCentre - (y + h / 2)
		root.AnchorPoint = Vector2.new(root.AnchorPoint.X, anchorY)
	end
	return { band = band, box = bandBox, icon = iconNode, title = titleNode, close = closeNode, rootAspect = rootAspect }
end

return UiKit
