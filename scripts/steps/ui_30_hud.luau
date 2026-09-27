-- scripts/steps/ui_30_hud.luau
-- Phase 3 (owner UI-HUD): re-skins the Steal a Hero HUD with the real Speedsters Escape materials (CONTRACTS_PHASE3
-- D1) while keeping the SAH HUD layout and UX (D2). Build hook: scripts/build_stealahero.luau step 14b runs every
-- scripts/steps/ui_*.luau in name order, Apply(place, spPlace, ctx).
--
-- What it touches (StarterGui unless noted):
--   Elements.Left.Tools     sidebar buttons: 77444378011596 over the per-button colour (Kit.Sidebar), white gradient +
--                           dark strokes, Speedsters icons, FredokaOne labels, Speedsters "!" badges. Layout (owner
--                           brief, 3rd pass): a column of compact rounded-rectangle pills, icon left + word right,
--                           the premium pill on its own row, VERTICALLY CENTRED on the left edge (the old top-left
--                           box sat under the Roblox topbar buttons) with the visible pills centred in it.
--                           Visual pass D7 (ref 10): Shop / Index become glossy stud pills (GREEN Shop, CYAN Index:
--                           vertical fill gradient + tiled stud texture 6927295847 + top gloss + ink outline), their
--                           official icons sit on a white-rimmed sticker plate, and the Index count badge is a red
--                           circle with a bold white number and an ink outline. Position and shape are unchanged.
--   Elements.Left.Tools.DoubleYourSpeed, Elements.RightFrame DoubleYourSpeed, Hud.RightHUD, Hud.MoneyFrame,
--   Hud.LeftHUD AdminPanel, Right.Tools.LimitedStarterPack
--                           premium materials: 116981003258590 pill (or the gold premium square), rotating SpShine
--                           72314714453458, green price gradient.
--   Elements.Tabs           icon-first right-edge tabs: GrowingEggs = the egg sticker + a small "EGGS" caption,
--                           Pets = the hero/index icon + "HERO INDEX"; identical rounded boxes, evenly spaced.
--   Elements.Right.Tools    GroupReward (Teleport yellow) / LimitedStarterPack (premium gold) squares, moved to the
--                           top-right corner so the promo column can never overlap the tabs.
--   Money.Bottom.Frame      currency rows (owner brief, 3rd pass): SpeedValue (+ its "+" buy button at the right end),
--                           Money (the Shop's banknotes icon instead of the trophy), FriendBoost and
--                           TemporarySpeedBoost each on a minimalist SQUARED semi-transparent navy ribbon (small
--                           corner, faint inner hairline, no gloss/outline), the icon at the left end, values in the
--                           Shop / Index label type (FredokaOne + thick ink outline), ~11 px between rows. Scripted
--                           children keep their names; the script-owned speed colour is never written.
--   Notifications, Friend_Notification, RS.Assets.UI.Notifications
--                           Speedsters toast/ticker material (FredokaOne, ink strokes, ticker card + stud texture).
--                           (RS.Assets.MoneyChange, the +$ popup, is styled by UI-WORLD's ui_40_world with the same
--                           number recipe.)
--   GameResetTimer          night / sleep timer (D7, ref 08): TimeLeft and EndingSoon become floating night-blue
--                           pills (subtle rim + drop shadow) with a glow behind the script-driven moon/sun icon and
--                           stylised heavy italic type. Position/Visible, the label's Text/TextColor3 and the icon's
--                           Image stay script-owned.
--   SpeedGainAnimation, TreadmillClickX2, ShiftLockButton, RunButton, Hud.JoinGroup.
--   StarterPlayerScripts.GUI.BackpackController.Main
--                           HotbarTemplate / InventoryTemplate edited in place + the module's styling attributes
--                           (Lune 0.10.5 round-trips Color3 / UDim / Font / number attributes: probe
--                           SP/impl3/UI-HUD/p2_attr_roundtrip.luau).
--
-- The runtime juice (hover tilt, attention bounce, badge shake, SpShine rotation, money pulse, TopbarPlus icons) lives
-- in src/StarterPlayer/StarterPlayerScripts/GUI/SpeedstersJuice.client.luau. This step marks its targets with
-- attributes: SpHover (tilt degrees) + SpHoverTarget (child name) on GuiButtons, SpBounce (seconds) + SpBounceOffset,
-- SpShake on badges, SpPulse on the money label; every SpShine ImageLabel is rotated.
--
-- D2 rules honoured here: no protected node is renamed, reclassed, destroyed or set Visible=false; no UIScale is added
-- anywhere; script-owned properties are left alone (listed per section); every new layer has an Sp* name; legacy
-- decoration is hidden by transparency. D3: the SPEEDSTER ESCAPE logo is never used (Kit.setImage refuses it).

local roblox = require("@lune/roblox")
local Kit = require("../lib/speedsters_ui_kit")

local UDim = roblox.UDim
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2
local Color3 = roblox.Color3
local Enum = roblox.Enum
local Content = roblox.Content
local Font = roblox.Font

local hex = Kit.hex
local C = Kit.Colors
local Sz = Kit.Sizes

local HUD = {}

---------------------------------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------------------------------

-- Speedsters premium-gold colours on the square sidebar base (Right.Tools.LimitedStarterPack, Hud.RightHUD): the
-- 2X Victory pill's gradients (materials hud.premium_button, Mainhud.Rightbuttons.2xVictory).
local PREMIUM_GOLD_SQUARE = {
	color = hex("#ffbe00"),
	fill = Kit.ButtonFamilies.premium_gold.fill,
	light = { thickness = 0.04, offset = -0.06, zIndex = 2, rotation = 270, gradient = Kit.ButtonFamilies.premium_gold.light.gradient },
	dark = { color = hex("#583312"), thickness = 0.04, offset = -0.02, zIndex = 3 },
	labelStroke = 0.11,
}

-- Speedsters ticker card, "Ice" theme (MessageHandler.client.luau:42-48): top -> bottom gradient + theme stroke.
local TICKER = {
	top = Color3.fromRGB(170, 235, 255),
	bottom = Color3.fromRGB(40, 140, 230),
	stroke = Color3.fromRGB(10, 50, 110),
	studsTransparency = 0.82,
	studsTile = UDim2.fromOffset(24, 24),
}

-- Speedsters "!" badge (materials hud.badge, Mainhud.LeftSideBar.Shop.!).
local BADGE = {
	size = UDim2.fromScale(0.4588, 0.4588),
	position = UDim2.fromScale(0.9747, 0.1397),
	anchor = Vector2.new(0.5, 0.5),
	corner = 0.9,
	red = { gradient = Kit.Gradients.badge, stroke = C.badgeStroke, labelStroke = C.badgeLabelStroke },
	green = {
		gradient = Kit.ButtonFamilies.claim_green.fill,
		stroke = Kit.ButtonFamilies.claim_green.dark.color,
		labelStroke = Kit.ButtonFamilies.claim_green.dark.color,
	},
}

local HOVER_TILT = 4 -- sidebar/tab icons (MainHUDController :447-505 uses 3-5 degrees)

---------------------------------------------------------------------------------------------------
-- Visual pass D7 (design/references 08-10)
---------------------------------------------------------------------------------------------------

-- Heavy italic GothamSSm: the stylised number type of ref 08 (night timer) inside the kit's GothamSSm family (Roblox
-- falls back to the nearest face if a weight/style is missing). Badge numbers use the upright heavy face. (The
-- currency rows switched to the Shop / Index label type in the 3rd pass: see RIBBON.)
local FONT_STYLISED = Font.new(Kit.FontFamilies.gotham, Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local FONT_BADGE = Font.new(Kit.FontFamilies.gotham, Enum.FontWeight.Heavy, Enum.FontStyle.Normal)

-- Shop / Index glossy stud pills (ref 10). Fill = light top -> saturated -> dark bottom (rot 90); ring = the inset
-- light stroke's gradient; outline = the thick outer stroke; plate = the icon sticker plate behind the icon.
local GLOSSY = {
	Shop = {
		fill = { { 0, "#c8ff6e" }, { 0.16, "#8ff53d" }, { 0.55, "#4ed61b" }, { 1, "#2a930c" } },
		ring = { { 0, "#f2ffd9" }, { 0.5, "#9cf55a" }, { 1, "#3aa815" } },
		outline = hex("#0f3a07"),
		plate = hex("#1d6e0b"),
	},
	Index = {
		fill = { { 0, "#aef9ff" }, { 0.16, "#64e9ff" }, { 0.55, "#14c4f4" }, { 1, "#0a7cc2" } },
		ring = { { 0, "#e8fdff" }, { 0.5, "#74ecff" }, { 1, "#168fd0" } },
		outline = C.ink,
		plate = hex("#0a5d94"),
	},
	-- treadmill-only buttons (owner 2026-09-23: "outdated", same new style as Shop): Speed Shop and x2 Speed
	TreadmillSpeedShop = {
		fill = { { 0, "#fff1a3" }, { 0.16, "#ffd43b" }, { 0.55, "#ffae00" }, { 1, "#d97700" } },
		ring = { { 0, "#fffbe0" }, { 0.5, "#ffd966" }, { 1, "#c47000" } },
		outline = hex("#5a2d00"),
		plate = hex("#b35f00"),
	},
	DoubleYourSpeed = {
		fill = { { 0, "#c4e9ff" }, { 0.16, "#7cc8ff" }, { 0.55, "#2f8cff" }, { 1, "#1553c7" } },
		ring = { { 0, "#eaf6ff" }, { 0.5, "#8fd0ff" }, { 1, "#1d5fc4" } },
		outline = C.ink,
		plate = hex("#1a4fa8"),
	},
	-- right-edge tabs (Elements.Tabs): the same material, their own colours
	Eggs = {
		fill = { { 0, "#ffb3e6" }, { 0.16, "#ff6fd0" }, { 0.55, "#f0199b" }, { 1, "#a3066a" } },
		ring = { { 0, "#ffe6f7" }, { 0.5, "#ff8fdc" }, { 1, "#c01485" } },
		outline = hex("#4a0231"),
		plate = hex("#8f0a5e"),
	},
	HeroTab = {
		fill = { { 0, "#e0c8ff" }, { 0.16, "#b98cff" }, { 0.55, "#8646f5" }, { 1, "#4f1bb0" } },
		ring = { { 0, "#f3eaff" }, { 0.5, "#c3a0ff" }, { 1, "#5f2ac4" } },
		outline = hex("#1f0a4d"),
		plate = hex("#4a1c9c"),
	},
}
local GLOSSY_GEOMETRY = {
	-- the pill keeps TOOL_PILL_ASPECT (2.714) through its wrapper's aspect constraint, so scale tiles stay square:
	-- 8 studs across, ~2.7 rows
	studColumns = 8,
	studTransparency = 0.72,
	glossTop = 0.07, glossWidth = 0.94, glossHeight = 0.42, glossCornerTop = 0.45, glossCornerBottom = 0.2,
	glossFrom = 0.45, glossTo = 0.95,
	outline = 0.055, ring = 0.035, ringOffset = -0.05,
	iconCenter = UDim2.fromScale(0.2, 0.5), iconSize = UDim2.fromScale(0.36, 0.86),
	plateSize = UDim2.fromScale(0.74, 0.74), plateTransparency = 0.2, plateRim = 0.075, plateInk = 0.13,
	labelPosition = UDim2.fromScale(0.37, 0.5), labelSize = UDim2.fromScale(0.59, 0.54), labelStroke = 0.13,
	badgeSize = UDim2.fromScale(0.5, 0.5), badgePosition = UDim2.fromScale(0.965, 0.1),
	z = { studs = 2, gloss = 2, plate = 3, icon = 4, label = 5, badge = 7 },
}

-- Round count badge (ref 10): red gradient circle, ink outline, bold white number with an ink stroke.
BADGE.round = {
	gradient = { { 0, "#ff6f60" }, { 0.45, "#f3212c" }, { 1, "#b1001a" } },
	stroke = C.ink, strokeThickness = 0.1,
	labelStroke = C.ink, labelStrokeThickness = 0.14, labelSize = UDim2.fromScale(0.78, 0.78), font = FONT_BADGE,
}

-- Bottom-left currency ribbons (owner brief, 3rd pass: "cinta semi transparente cuadrada, minimalista, con padding
-- entre ellos"). Every row is a flat translucent navy band with a small corner (a squared ribbon, not a capsule),
-- a faint inner light hairline and nothing else (no gradient, gloss or outline). Values use the Shop / Index label
-- type (FredokaOne + thick ink Contextual outline). The icon sits at the left end, a little taller than the band.
-- Row geometry is in units of the ribbon HEIGHT (H). Money.Bottom keeps its 6.46 aspect, so the Frame (the vertical
-- list container) is ~162 x 31 px at 1280x720 and ~107 x 20.5 px on an 844x390 phone; every row gets an aspect
-- constraint, so the H-unit maths below holds on every screen.
local RIBBON = {
	color = C.ink, -- #0b1b3d
	transparency = 0.45,
	corner = UDim.new(0.14, 0), -- ~5 px at 720p
	edge = { thickness = 0.03, transparency = 0.8 }, -- SpStrokeLight: ~1 px inner hairline
	-- SpeedValue / Money: {1.6, 1.25} of the Frame with SpAspect 6.6 -> height-limited: H = 1.25 x Frame height
	-- (~39 x 257 px at 720p, ~26 x 169 px on a phone)
	rowSize = UDim2.fromScale(1.6, 1.25), rowAspect = 6.6,
	-- FriendBoost / TemporarySpeedBoost: the same width, a slimmer band (~30 px at 720p)
	lineSize = UDim2.fromScale(1.6, 0.95), lineAspect = 6.6 * 1.25 / 0.95,
	-- between rows, of the Frame height: ~11 px at 720p, ~7 px on a phone (the icons overflow ~3.5 px each)
	listPadding = UDim.new(0.36, 0),
	-- the Frame's left edge lines up with Elements.Left's (both are width fractions: ~19.5 px at 720p, ~13 px on a
	-- phone); centred in Money.Bottom so the lowest row keeps ~15 px off the screen bottom
	framePosition = UDim2.fromScale(0.0325, 0.5), frameAnchor = Vector2.new(0, 0.5),
	padLeft = 0.08, -- H, before the icon
	gap = 0.14, -- H, icon -> value
	icon = 1.18, -- H, icon side
	textHeight = 0.82, -- H, value text box (FredokaOne digits ~0.6 H tall)
	textRight = 0.3, -- H, free space after the value (Money / buff rows)
	textMax = 48,
	textStroke = 0.13, -- GLOSSY_GEOMETRY.labelStroke: the Shop / Index label outline
	moneyColor = hex("#52ff2e"),
	-- the Speed "+" shortcut: a gold square at the RIGHT end of the speed ribbon, inset like a key cap
	plus = {
		size = 0.72, inset = 0.14, gap = 0.14, corner = 0.25, -- H
		fill = Kit.ButtonFamilies.premium_gold.fill, stroke = C.ink, strokeThickness = 0.08, glyphStroke = 0.16,
	},
	friendIcon = 139671463277267, -- Steal a Hero's own "Friends" art (TradePlayerList bottom bar)
	boostIcon = Kit.Icons.ability, -- Speedsters lightning bolt
	-- Money icon: the banknotes art of the Shop's cash packs (StarterGui.Shop ... MoneyTop.1.Icon, the "$24,000"
	-- pack), read from the place at build time; the id is the fallback when that path is missing.
	cashIconPath = "Shop.Frame.Main.ScrollingFrame.MoneyTop.1.Icon",
	cashIcon = 130591156585519,
}

-- Night / sleep timer pill (ref 08).
local NIGHT = {
	fill = { { 0, "#2c4a9c" }, { 0.55, "#172a66" }, { 1, "#0c1640" } },
	transparency = 0.22,
	corner = UDim.new(0.5, 0),
	rim = hex("#9fc6ff"), rimThickness = 0.045, rimTransparency = 0.5,
	shadowOffset = 0.1, shadowTransparency = 0.72,
	glowColor = hex("#cfe2ff"),
	-- { size x icon-holder height, transparency }: ~45% opaque at the centre, the outer halo spills a few px off the pill
	glow = { { 1.3, 0.88 }, { 1.08, 0.84 }, { 0.86, 0.8 }, { 0.64, 0.76 } },
	textGradient = { { 0, "#ffffff" }, { 1, "#d2e2ff" } },
	textStroke = 0.1,
	timeLeft = { size = UDim2.fromScale(0.165, 0.078), aspect = 4.3, main = UDim2.fromScale(0.92, 1),
		icon = UDim2.fromScale(0.3, 0.94), text = UDim2.fromScale(0.64, 0.6) },
	endingSoon = { pill = UDim2.fromScale(0.3, 1.08), main = UDim2.fromScale(0.28, 1),
		icon = UDim2.fromScale(0.26, 0.95), text = UDim2.fromScale(0.66, 0.66) },
	listPadding = UDim.new(0.035, 0),
}

---------------------------------------------------------------------------------------------------
-- HUD layout (owner brief, 2nd + 3rd pass): the tool buttons are compact rounded rectangles ("icon + word")
-- stacked in a column that is VERTICALLY CENTRED on the left edge (3rd pass: the top-left box sat under the Roblox
-- topbar buttons, whose height changes per device, so no fixed offset clears it everywhere), and two roughly square
-- ICON-FIRST tabs sit on the right edge, grouped near the middle. Everything below is expressed in scale +
-- AnchorPoint so it holds on any aspect ratio. No runtime script moves Elements.Left: InterfaceScaling
-- (UIOffsetScaler) only rescales FixedSize strokes / 9-slice / rich text, and TreadmillUI.Visibility, HideImportantUI
-- and ConsoleController only toggle Visible / Enabled.
--
-- Reference px at 1280x720 (Elements' content box is 1272 x 708 after its UIPadding):
--   Left box 190 x 317, left edge 19.5, centred at y 354 -> the visible pills are centred in it (Shop + Index:
--                                                           190x70 each, 10 px apart, y 279-429)
--   Tabs box  95 x 234, right edge 1261 -> GrowingEggs / Pets 95x110, 14 px apart, centred at 0.56 h
-- At 844x390 (phone landscape): Left box 125 x 209 centred at y 189 (Shop + Index y 140-239), clear of the
-- bottom-left currency rows (top >= y 287 with both buff rows shown) and of Hud.LeftHUD.AdminPanel (y 53-84).
---------------------------------------------------------------------------------------------------

-- Left tool "pill": wider than tall, icon left + label right (reference "Tienda" / "Indice").
local TOOL_PILL_ASPECT = 2.714 -- 190 x 70
local TOOL_PILL_CORNER = UDim.new(0.3, 0)
local LEFT_BOX_ASPECT = 0.6 -- 190 x 317: room for 4 pills + gaps, and the premium pill on its own row
local LEFT_BOX_WIDTH = 0.1494 -- of the Elements content width, BEFORE Left's own UIScale (1.1) -> 190 px
-- left edge, vertically centred (UIScale scales about the AnchorPoint, so the 1.1 scale keeps the centre)
local LEFT_BOX_POSITION = UDim2.fromScale(0.012, 0.5)
local LEFT_BOX_ANCHOR = Vector2.new(0, 0.5)
local LEFT_ROW_PADDING = 0.032 -- of the box height -> ~10 px gap
local TOOL_ICON = {
	size = UDim2.fromScale(0.26, 0.7), position = UDim2.fromScale(0.055, 0.5), anchor = Vector2.new(0, 0.5),
}
local TOOL_LABEL = {
	size = UDim2.fromScale(0.6, 0.5), position = UDim2.fromScale(0.355, 0.5), anchor = Vector2.new(0, 0.5),
	aspect = 0.6 / 0.5 * TOOL_PILL_ASPECT, -- 3.257: the label box inside the pill, so SpAspect cannot shrink it
}
-- The "!" badge hangs off the pill's top-right corner instead of a square's.
local PILL_BADGE_POSITION = UDim2.fromScale(0.95, 0.18)
-- Stack order in the sidebar (UIListLayout SortOrder = LayoutOrder; without this, ties are resolved by insertion
-- order, which put Index above Shop).
local LEFT_ORDER = { Shop = 1, Index = 2, TreadmillSpeedShop = 3, DoubleYourSpeed = 4, Rebirth = 5, Trading = 6, FreeGifts = 7 }

-- Right-edge tabs (owner brief, 5th pass): glossy ROUNDED SQUARES as tall as the left pills (70 px at 720p), icon only -
-- EGGS shows the Steal an Egg egg, HERO INDEX a big "H" - stacked on the right edge and vertically centred.
local TAB_GAP = 0.06 -- of the Tabs box height (~9 px)
local TAB_ROW = (1 - TAB_GAP) / 2 -- each square's share of the box height
local TABS_BOX_ASPECT = TAB_ROW -- one square wide: width / height of two squares + one gap
local TABS_BOX_SIZE = UDim2.fromScale(LEFT_BOX_WIDTH / TOOL_PILL_ASPECT, 0.6) -- square side = the left pills' height
local TABS_BOX_POSITION = UDim2.fromScale(0.988, 0.5)
local TAB_ICON_SIZE = UDim2.fromScale(0.74, 0.74)
local TAB_BADGE_SIZE = UDim2.fromScale(0.44, 0.44)
local TAB_LETTER = "H"
-- Steal a Hero's own egg sticker (the art on Elements.Tabs.GrowingEggs.Icon in the base place; Speedsters Escape
-- has no egg icon in materials.json). The hero/index icon is the Speedsters one.
local EGG_ICON = 96783034607256
local HERO_ICON = 140189242202677
-- The owner's own minimalist HERO INDEX tab icon (Steal an Egg style), not uploaded yet: nil = no icon on that tab.
local HERO_TAB_ICON: number? = nil

-- Elements.Right promo column (GroupReward / LimitedStarterPack, both script-driven Visible): moved to the
-- top-right and scaled down so it can never reach the tabs. The grid's 130 px fixed cells became scale cells.
local RIGHT_BOX_SIZE = UDim2.new(0.13, 0, 0.26, 0)
local RIGHT_BOX_POSITION = UDim2.new(0.9858, 0, 0, 40)
local RIGHT_BOX_ASPECT = 0.47
local RIGHT_CELL_SIZE = UDim2.fromScale(0.89, 0.42)
local RIGHT_CELL_PADDING = UDim2.fromScale(0, 0.05)

-- Speedsters toast (BoostNotifier.client.luau:22-92): #0f121c @0.12 card, 10 px corner, 2 px #32b4ff @0.3 outline.
local TOAST = {
	color = hex("#0f121c"),
	transparency = 0.12,
	corner = UDim.new(0, 10),
	stroke = hex("#32b4ff"),
	strokeTransparency = 0.3,
	padding = UDim.new(0, 14),
}
local HOVER_TILT_PREMIUM = 5

---------------------------------------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------------------------------------

local notes = {} -- human-readable summary lines
local warnings = {}

local function note(fmt, ...)
	table.insert(notes, string.format(fmt, ...))
end

local function warn(fmt, ...)
	table.insert(warnings, string.format(fmt, ...))
end

local function isImage(inst)
	return inst ~= nil and (inst:IsA("ImageLabel") or inst:IsA("ImageButton"))
end

local function child(parent, name, className)
	return Kit.findChild(parent, name, className)
end

-- Existing UIAspectRatioConstraint (reused) or a new SpAspect.
local function aspect(inst, ratio)
	local c = inst:FindFirstChildOfClass("UIAspectRatioConstraint")
	if not c then
		c = Kit.ensureChild(inst, "UIAspectRatioConstraint", Kit.Names.aspect)
	end
	c.AspectRatio = ratio
	c.AspectType = Enum.AspectType.FitWithinMaxSize
	c.DominantAxis = Enum.DominantAxis.Width
	return c
end

local function place(inst, size, position, anchor)
	if anchor then
		inst.AnchorPoint = anchor
	end
	if position then
		inst.Position = position
	end
	if size then
		inst.Size = size
	end
end

-- UIPadding children of a label would offset the text away from the Speedsters geometry: neutralise (keep them).
local function zeroPadding(inst)
	for _, c in ipairs(inst:GetChildren()) do
		if c:IsA("UIPadding") then
			c.PaddingLeft = UDim.new(0, 0)
			c.PaddingRight = UDim.new(0, 0)
			c.PaddingTop = UDim.new(0, 0)
			c.PaddingBottom = UDim.new(0, 0)
		end
	end
end

local function textSizeCap(label, maxSize)
	for _, c in ipairs(label:GetChildren()) do
		if c:IsA("UITextSizeConstraint") then
			c.MaxTextSize = math.max(c.MaxTextSize, maxSize)
		end
	end
end

-- Every TextLabel/TextButton/TextBox in the subtree (root included when it is one).
local function eachText(root, fn)
	if Kit.isText(root) then
		fn(root)
	end
	for _, d in ipairs(root:GetDescendants()) do
		if Kit.isText(d) then
			fn(d)
		end
	end
end

-- Strokes with the dormant InterfaceScaling attribute: a restyled stroke clears it (sah_structure C10).
local function clearOldp(stroke)
	if stroke:GetAttribute("oldp_Thickness") ~= nil then
		stroke:SetAttribute("oldp_Thickness", nil)
	end
end

-- Speedsters sidebar label geometry (Mainhud.LeftSideBar.*.Name).
local function placeSidebarLabel(label)
	local g = Sz.sidebarButton
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = g.labelPosition
	label.Size = g.labelSize
	label.Rotation = 0
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = math.max(label.ZIndex, 4)
	zeroPadding(label)
	textSizeCap(label, 48)
	aspect(label, g.labelAspect)
end

-- Left tool pill: the word sits to the RIGHT of the icon, left-aligned. TextScaled needs TextWrapped = true: with
-- TextWrapped = false Roblox renders the text at its fixed (tiny) TextSize. The label box keeps the pill's aspect
-- (SpAspect), so a one-line "Hero Index" is always larger than a two-line break and TextScaled keeps one line.
local function placePillLabel(label)
	label.AnchorPoint = TOOL_LABEL.anchor
	label.Position = TOOL_LABEL.position
	label.Size = TOOL_LABEL.size
	label.Rotation = 0
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.None
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = math.max(label.ZIndex, 4)
	zeroPadding(label)
	textSizeCap(label, 48)
	aspect(label, TOOL_LABEL.aspect)
end

-- The juice script's markers (see header).
local function markHover(button, target, degrees)
	if button and target then
		button:SetAttribute("SpHover", degrees or HOVER_TILT)
		button:SetAttribute("SpHoverTarget", target.Name)
	end
end

local function markBounce(button, interval, offset)
	if button then
		button:SetAttribute("SpBounce", interval)
		button:SetAttribute("SpBounceOffset", offset or 0)
	end
end

---------------------------------------------------------------------------------------------------
-- Material recipes on top of the kit
---------------------------------------------------------------------------------------------------

local function familyStrokes(holder, spec)
	Kit.addStroke(holder, {
		name = Kit.Names.strokeLight, color = C.white, thickness = spec.light.thickness,
		borderOffset = spec.light.offset, zIndex = spec.light.zIndex, gradient = spec.light.gradient,
		gradientRotation = spec.light.rotation or 90,
	})
	Kit.addStroke(holder, {
		name = Kit.Names.strokeDark, color = spec.dark.color, thickness = spec.dark.thickness,
		borderOffset = spec.dark.offset, zIndex = spec.dark.zIndex,
	})
end

-- Square Speedsters button from a custom sidebar-shaped spec (colour, optional fill, light/dark strokes) on an
-- ImageButton/ImageLabel. opts.keepImage: the image is script-owned (ShiftLock): colour + strokes only.
local function paintSquare(button, spec, opts)
	opts = opts or {}
	if isImage(button) and not opts.keepImage then
		Kit.setImage(button, Kit.Images.sidebarBase)
		button.ImageColor3 = C.white
		button.ImageTransparency = 0
		button.ScaleType = Enum.ScaleType.Stretch
	end
	button.BackgroundColor3 = spec.color
	button.BackgroundTransparency = 0
	button.BorderSizePixel = 0
	if spec.fill then
		Kit.addGradient(button, spec.fill, 90, Kit.Names.fill)
	end
	Kit.setCorner(button, opts.corner or Sz.sidebarButton.corner)
	familyStrokes(button, spec)
	Kit.hideLegacyStrokes(button)
	return button
end

-- A Speedsters icon ImageLabel child (SpIcon) with the sidebar icon geometry.
local function sidebarIcon(parent, iconId, geometry)
	local icon = Kit.ensureChild(parent, "ImageLabel", Kit.Names.icon)
	Kit.setImage(icon, iconId)
	icon.BackgroundTransparency = 1
	icon.ImageTransparency = 0
	icon.ImageColor3 = C.white
	icon.ScaleType = Enum.ScaleType.Stretch
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Size = (geometry and geometry.size) or Sz.sidebarButton.iconSize
	icon.Position = (geometry and geometry.position) or Sz.sidebarButton.iconPosition
	icon.Rotation = 0
	icon.ZIndex = (geometry and geometry.zIndex) or 3
	icon.Active = false
	aspect(icon, (geometry and geometry.aspect) or 1)
	return icon
end

-- Hides a legacy visual child (the SAH "Frame" painter behind a tool button, its bevel/inlet/pattern) by
-- transparency, recursively (images, texts, strokes, backgrounds).
local function hideVisual(inst)
	if inst then
		Kit.hideDecoration(inst, { recursive = true })
	end
end

-- Speedsters "!" badge look on an SAH badge circle Frame (gradient circle + stroke).
local function paintBadgeCircle(frame, variant)
	local v = BADGE[variant or "red"]
	frame.BackgroundColor3 = C.white
	frame.BackgroundTransparency = 0
	Kit.setCorner(frame, BADGE.corner)
	local gradient = nil
	for _, c in ipairs(frame:GetChildren()) do
		if c:IsA("UIGradient") then
			if gradient == nil then
				gradient = c
			else
				c.Enabled = false
			end
		end
	end
	if gradient then
		gradient.Color = Kit.seq(v.gradient)
		gradient.Rotation = 90
		gradient.Offset = Vector2.new(0, 0)
		gradient.Transparency = Kit.numberSeq(0)
		gradient.Enabled = true
	else
		Kit.addGradient(frame, v.gradient, 90, Kit.Names.fill)
	end
	local stroke = nil
	for _, c in ipairs(frame:GetChildren()) do
		if c:IsA("UIStroke") then
			if stroke == nil then
				stroke = c
			else
				c.Transparency = 1
			end
		end
	end
	stroke = stroke or Kit.ensureChild(frame, "UIStroke", Kit.Names.stroke)
	clearOldp(stroke)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Thickness = v.strokeThickness or 0.08
	stroke.Color = v.stroke
	stroke.Transparency = 0
	stroke.Enabled = true
end

local function badgeText(label, variant)
	local v = BADGE[variant or "red"]
	Kit.styleText(label, "badge", {
		strokeColor = v.labelStroke, strokeThickness = v.labelStrokeThickness, disableGradients = true,
	})
	if v.font then
		label.FontFace = v.font -- bold upright number (the count is script-written: Text only)
	end
	if v.labelSize and label.Name ~= "Shadow" then
		place(label, v.labelSize, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
		label.TextScaled = true
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
	end
end

-- SAH badge structures -> Speedsters "!" badge. The badge's Visible (and, for some, a runtime UIScale) stay
-- script-owned; only colours, fonts, strokes and (opts.speedstersPlace) geometry change.
--   a) Tools NotificationBadge / CanRebirth: Frame > Frame > {Pulse, BadgeFrame > Frame (circle), TextLabelFrame > TextLabel}
--   b) FreeGifts Notification: the Frame is the circle, Count TextLabel inside.
--   c) Tabs Badge / Notification / ReadyNotification: Frame (red circle) > {InletTexture > TextLabel > Shadow, Frame (circle)}
local function skinBadge(badge, variant, opts)
	if badge == nil then
		return false
	end
	opts = opts or {}
	if opts.speedstersPlace then
		place(badge, opts.size or BADGE.size, opts.position or BADGE.position, BADGE.anchor)
		aspect(badge, 1)
	end
	local circles = {}
	for _, d in ipairs(badge:GetDescendants()) do
		if d:IsA("Frame") and d.Name == "Frame" and d:FindFirstChildOfClass("UIGradient") then
			table.insert(circles, d)
		end
	end
	if #circles == 0 and badge:FindFirstChildOfClass("UIGradient") then
		table.insert(circles, badge) -- (b)
	elseif badge:FindFirstChildOfClass("UICorner") then
		-- (c): the outer frame also paints a red circle; the inner circle carries the Speedsters look
		badge.BackgroundTransparency = 1
		Kit.hideLegacyStrokes(badge)
	end
	for _, circle in ipairs(circles) do
		paintBadgeCircle(circle, variant)
	end
	for _, d in ipairs(badge:GetDescendants()) do
		if d:IsA("ImageLabel") and d.Name == "InletTexture" then
			d.ImageTransparency = 1
		end
	end
	eachText(badge, function(label)
		local face = label:FindFirstChild("Shadow")
		if face and face:IsA("TextLabel") then
			-- SAH two-face text: the back face (black) is hidden, the front face "Shadow" becomes the label
			label.TextTransparency = 1
			for _, c in ipairs(label:GetChildren()) do
				if c:IsA("UIStroke") then
					c.Transparency = 1
				end
			end
		else
			badgeText(label, variant)
			if label.Name == "Shadow" then
				label.Position = UDim2.fromScale(0.5, 0.5)
			end
		end
	end)
	badge:SetAttribute("SpShake", true)
	return true
end

---------------------------------------------------------------------------------------------------
-- Sidebar tool buttons (Elements.Left.Tools / Elements.Right.Tools)
---------------------------------------------------------------------------------------------------

-- SAH tool button = transparent ImageButton click box over a visual "Frame" (+ Label/Vector or an Icon holding the
-- label). The Speedsters skin goes on the ImageButton itself (it is an image object: base 77444378011596 over the
-- per-button BackgroundColor3); the legacy visuals are hidden by transparency.
--   spec: { key = Kit.Sidebar key | custom = PREMIUM_GOLD_SQUARE, icon = id, iconChild = existing icon name,
--           label = function(button) -> text object, pill = true for the wide top-left pill shape }
local function skinToolButton(wrapperName, button, spec)
	if button == nil or not button:IsA("ImageButton") then
		warn("%s: tool Button missing or not an ImageButton", wrapperName)
		return nil
	end
	-- click box = the whole square
	place(button, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	button.Rotation = 0
	button.BorderSizePixel = 0

	-- legacy visuals
	hideVisual(child(button, "Frame"))
	local vector = child(button, "Vector")
	if vector and isImage(vector) then
		vector.ImageTransparency = 1
	end
	local legacyIcon = child(button, "Icon")
	if legacyIcon and isImage(legacyIcon) then
		-- the SAH icon holder may parent the label: fill the button so the label can use button-relative geometry
		legacyIcon.ImageTransparency = 1
		place(legacyIcon, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
		legacyIcon.ZIndex = 4
		local ratio = legacyIcon:FindFirstChildOfClass("UIAspectRatioConstraint")
		if ratio then
			ratio.AspectRatio = 1
		end
		for _, c in ipairs(legacyIcon:GetChildren()) do
			if c:IsA("ImageLabel") and (c.Name == "Closure" or c.Name == "New") then
				c.ImageTransparency = 1
			end
		end
	end

	-- icon: reuse the kit's HeroIcon/ShopIcon, else SpIcon
	local icon = spec.iconChild and child(button, spec.iconChild) or nil
	local label = spec.label and spec.label(button) or nil

	if spec.key then
		local _, placedIcon = Kit.skinSidebarButton(button, spec.key, spec.icon, {
			target = button, icon = icon, placeIcon = not spec.pill, iconZIndex = 3, label = label,
		})
		icon = placedIcon
	else
		paintSquare(button, spec.custom)
		icon = icon or sidebarIcon(button, spec.icon)
		if icon.Name ~= Kit.Names.icon then
			Kit.setImage(icon, spec.icon)
			place(icon, Sz.sidebarButton.iconSize, Sz.sidebarButton.iconPosition, Vector2.new(0.5, 0.5))
			icon.ZIndex = 3
			aspect(icon, 1)
		end
		if label then
			Kit.styleText(label, "sidebar", { strokeThickness = spec.custom.labelStroke })
		end
	end
	if spec.pill then
		-- rounded RECTANGLE: icon on the left, word on the right
		Kit.setCorner(button, TOOL_PILL_CORNER)
		local skin = child(button, Kit.Names.skin)
		if skin then
			Kit.setCorner(skin, TOOL_PILL_CORNER)
		end
		if icon then
			place(icon, TOOL_ICON.size, TOOL_ICON.position, TOOL_ICON.anchor)
			icon.ScaleType = Enum.ScaleType.Stretch
			icon.ZIndex = math.max(icon.ZIndex, 3)
			aspect(icon, 1)
		end
		if label then
			placePillLabel(label)
		end
	elseif label then
		placeSidebarLabel(label)
	end
	if icon then
		icon.Rotation = 0
	end

	-- badges: Speedsters "!" corner badge
	local badgePos = spec.pill and PILL_BADGE_POSITION or BADGE.position
	skinBadge(child(button, "NotificationBadge"), "red", { speedstersPlace = true, position = badgePos })
	skinBadge(child(button, "CanRebirth"), "red", { speedstersPlace = true, position = badgePos })
	skinBadge(child(button, "Notification"), "red", { speedstersPlace = true, position = badgePos })
	local notif = child(button, "Notif")
	if notif and notif:IsA("GuiObject") then
		place(notif, BADGE.size, badgePos, BADGE.anchor)
		notif.ZIndex = math.max(notif.ZIndex, 6)
		notif:SetAttribute("SpShake", true)
	end
	-- ConsoleButton glyph stays above the skin (it is a hidden ImageLabel with its ConsoleButton attribute)
	local console = child(button, "ConsoleButton")
	if console and console:IsA("GuiObject") then
		console.ZIndex = math.max(console.ZIndex, 15)
	end

	markHover(button, icon, HOVER_TILT)
	return button, icon, label
end

-- Tiled UI stud texture (6927295847) filling `parent`, clipped by the same corner.
local function studLayer(parent, tile, transparency, corner, zIndex)
	local layer = Kit.ensureChild(parent, "ImageLabel", "SpStuds")
	Kit.setImage(layer, Kit.Images.stud)
	layer.BackgroundTransparency = 1
	layer.BorderSizePixel = 0
	layer.ScaleType = Enum.ScaleType.Tile
	layer.TileSize = tile
	layer.ImageColor3 = C.white
	layer.ImageTransparency = transparency
	layer.AnchorPoint = Vector2.new(0.5, 0.5)
	layer.Position = UDim2.fromScale(0.5, 0.5)
	layer.Size = UDim2.fromScale(1, 1)
	layer.Rotation = 0
	layer.ZIndex = zIndex
	layer.Active = false
	Kit.setCorner(layer, corner)
	return layer
end

-- Glass highlight over the top of a glossy face: a white band that fades out downwards.
local function glossLayer(parent, g, zIndex)
	local band = Kit.ensureChild(parent, "Frame", "SpGloss")
	band.BackgroundColor3 = C.white
	band.BackgroundTransparency = 0
	band.BorderSizePixel = 0
	band.AnchorPoint = Vector2.new(0.5, 0)
	band.Position = UDim2.fromScale(0.5, g.glossTop)
	band.Size = UDim2.fromScale(g.glossWidth, g.glossHeight)
	band.Rotation = 0
	band.ZIndex = zIndex
	band.Active = false
	local corner = Kit.setCorner(band, g.glossCornerTop)
	corner.BottomLeftRadius = UDim.new(g.glossCornerBottom, 0)
	corner.BottomRightRadius = UDim.new(g.glossCornerBottom, 0)
	Kit.addGradient(band, C.white, 90, Kit.Names.gradient, { transparency = { { 0, g.glossFrom }, { 1, g.glossTo } } })
	return band
end

-- D7 glossy stud pill (ref 10) on a Left.Tools ImageButton that skinToolButton already skinned as a pill: the face
-- is a white background under the family fill gradient (the square sidebar base art is dropped: it stretched on a
-- 2.7:1 pill), a tiled stud layer, a top gloss band, a thick outer outline and an inset light ring. The official
-- icon sits on a white-rimmed sticker plate; the label keeps its text and gets a thick family outline; the Index
-- count badge becomes the round red badge. Position, size and corner radius of the pill are unchanged.
-- Protected children (ShopIcon / HeroIcon, Label, NotificationBadge, Notif, ConsoleButton) keep name, class and
-- parent; ButtonFX keeps owning the button scale (no UIScale is added).
local function skinGlossyTool(button, spec, icon, label)
	local g = GLOSSY_GEOMETRY
	if isImage(button) then
		button.ImageTransparency = 1
	end
	button.BackgroundColor3 = C.white
	button.BackgroundTransparency = 0
	button.BorderSizePixel = 0
	Kit.addGradient(button, spec.fill, 90, Kit.Names.fill)
	Kit.setCorner(button, TOOL_PILL_CORNER)
	Kit.addStroke(button, {
		name = Kit.Names.strokeDark, color = spec.outline, thickness = g.outline, zIndex = 3,
	})
	Kit.addStroke(button, {
		name = Kit.Names.strokeLight, color = C.white, thickness = g.ring, borderOffset = g.ringOffset, zIndex = 2,
		gradient = spec.ring, gradientRotation = 90,
	})
	local skin = child(button, Kit.Names.skin)
	if skin and isImage(skin) then
		skin.ImageTransparency = 1 -- a kit tint layer from an earlier pass would cover the gradient
		skin.BackgroundTransparency = 1
	end
	studLayer(button, UDim2.fromScale(1 / g.studColumns, TOOL_PILL_ASPECT / g.studColumns), g.studTransparency,
		TOOL_PILL_CORNER, g.z.studs)
	glossLayer(button, g, g.z.gloss)

	-- sticker plate: a darker disc with a white rim and an ink edge, behind the (slightly larger) official icon
	local plate = Kit.ensureChild(button, "Frame", "SpIconPlate")
	plate.AnchorPoint = Vector2.new(0.5, 0.5)
	plate.Position = g.iconCenter
	plate.Size = g.plateSize
	plate.SizeConstraint = Enum.SizeConstraint.RelativeYY
	plate.BackgroundColor3 = spec.plate
	plate.BackgroundTransparency = g.plateTransparency
	plate.BorderSizePixel = 0
	plate.Rotation = 0
	plate.ZIndex = g.z.plate
	plate.Active = false
	Kit.setCorner(plate, 0.5)
	Kit.addStroke(plate, { name = "SpStrokeRim", color = C.white, thickness = g.plateRim, zIndex = 2 })
	Kit.addStroke(plate, { name = Kit.Names.strokeDark, color = spec.outline, thickness = g.plateInk, zIndex = 1 })
	if icon then
		place(icon, g.iconSize, g.iconCenter, Vector2.new(0.5, 0.5))
		icon.BackgroundTransparency = 1
		icon.ImageTransparency = 0
		icon.ImageColor3 = C.white
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Rotation = 0
		icon.Visible = true
		icon.ZIndex = g.z.icon
		aspect(icon, 1)
	end
	if label then
		place(label, g.labelSize, g.labelPosition, Vector2.new(0, 0.5))
		label.ZIndex = g.z.label
		Kit.styleText(label, "sidebar", { strokeThickness = g.labelStroke, strokeColor = spec.outline })
		aspect(label, g.labelSize.X.Scale / g.labelSize.Y.Scale * TOOL_PILL_ASPECT)
	end

	-- count badge: red circle, bold white number, ink outline, hanging off the top-right corner
	local badge = child(button, "NotificationBadge")
	if badge and badge:IsA("GuiObject") then
		skinBadge(badge, "round", { speedstersPlace = true, size = g.badgeSize, position = g.badgePosition })
		badge.ZIndex = math.max(badge.ZIndex, g.z.badge)
	end
	local notif = child(button, "Notif") -- unscripted legacy "!" art (hidden): parked on the same corner
	if notif and notif:IsA("GuiObject") then
		place(notif, g.badgeSize, g.badgePosition, BADGE.anchor)
		notif.ZIndex = math.max(notif.ZIndex, g.z.badge)
	end
	return plate
end

-- Speedsters premium pill (hud.premium_button) on an SAH ImageButton that shows a price tag + multiplier text.
--   parts: { frame = legacy visual frame, icon = legacy icon, sunburst = rotated rays, multiplier = label,
--            priceTag = Frame with the price TextLabel "Text" }
local function skinPremiumPill(button, family, parts, opts)
	opts = opts or {}
	Kit.skinButton(button, family, { mode = "direct", adoptGradient = true })
	button.BorderSizePixel = 0
	if parts.frame then
		hideVisual(parts.frame)
	end
	if parts.icon and isImage(parts.icon) then
		parts.icon.ImageTransparency = 1
	end
	if parts.sunburst and isImage(parts.sunburst) then
		parts.sunburst.ImageTransparency = 1 -- its SunburstLocalScript keeps owning Rotation
	end
	-- centre currency icon (Rightbuttons.2xSpeed.Icon)
	local icon = sidebarIcon(button, opts.iconId or Kit.Icons.speed, {
		size = UDim2.fromScale(0.3434, 1.0225), position = UDim2.fromScale(0.4936, 0.4888), aspect = 1.0127, zIndex = 3,
	})
	-- multiplier / name label (Rightbuttons.2xSpeed.Name)
	local label = parts.multiplier
	if label and Kit.isText(label) then
		place(label, UDim2.fromScale(0.5291, 0.595), UDim2.fromScale(0.4977, 0.4904), Vector2.new(0.5, 0.5))
		label.BackgroundTransparency = 1
		label.ZIndex = math.max(label.ZIndex, 5)
		label.TextScaled = true
		label.TextWrapped = true
		zeroPadding(label)
		aspect(label, 2.6812)
		Kit.styleText(label, "button", { strokeThickness = 0.09 })
	end
	-- price tag below the pill; the scripts write "ONLY <robux glyph> N" (the glyph is part of the text, so it takes
	-- the Speedsters green price gradient with the digits instead of a second 108805296006809 ImageLabel)
	local tag = parts.priceTag
	if tag and tag:IsA("GuiObject") then
		place(tag, UDim2.fromScale(0.8, 0.45), UDim2.fromScale(0.5, 1.16), Vector2.new(0.5, 0.5))
		tag.BackgroundTransparency = 1
		eachText(tag, function(t)
			Kit.styleText(t, "price", { color = C.white, strokeThickness = 0.06, gradient = Kit.Gradients.price, gradientRotation = 90 })
		end)
	end
	local shine = Kit.addShine(button)
	markHover(button, icon, HOVER_TILT_PREMIUM)
	markBounce(button, 7, opts.bounceOffset or 2)
	return icon, shine
end

---------------------------------------------------------------------------------------------------
-- Sections
---------------------------------------------------------------------------------------------------

local LEFT_TOOLS = {
	-- name, Kit.Sidebar key, icon (nil = kit default for the key), existing icon child, label getter
	{ "Shop", "Shop", nil, "ShopIcon", function(b) return child(b, "Label") end },
	{ "Index", "Index", HERO_ICON, "HeroIcon", function(b) return child(b, "Label") end },
	{ "Rebirth", "Rebirth", nil, nil, function(b) return child(b, "Label") end },
	{ "TreadmillSpeedShop", "Ability", nil, nil, function(b) return child(b, "Label") end },
	-- no Speedsters trading icon exists: the SAH trade art keeps the meaning, on the Backpack-orange square
	{ "Trading", "Backpack", 80807460450475, nil, function(b)
		local i = child(b, "Icon")
		return i and child(i, "TextLabel")
	end },
	{ "FreeGifts", "TimeGifts", nil, nil, function(b)
		local i = child(b, "Icon")
		return i and child(i, "TextLabel")
	end },
}

local function applyLeft(sg)
	local elements = child(sg, "Elements")
	local left = elements and child(elements, "Left")
	local tools = left and child(left, "Tools")
	if not tools then
		warn("Elements.Left.Tools missing")
		return
	end
	-- Column of pills on the LEFT EDGE, vertically centred (AnchorPoint Y 0.5 at Y scale 0.5): it clears the Roblox
	-- topbar on every device (desktop 1280x720 / 1920x1080 and phones) without a fixed offset. The box height comes
	-- from the AspectRatio constraint (AspectType.ScaleWithParentSize / DominantAxis.Width: height = width /
	-- AspectRatio), so it holds on every aspect ratio.
	local leftScale = 1
	for _, c in ipairs(left:GetChildren()) do
		if c:IsA("UIScale") then
			leftScale = c.Scale -- Left's own UIScale is pre-existing (not a button): divide the box by it
		end
	end
	left.AnchorPoint = LEFT_BOX_ANCHOR
	left.Position = LEFT_BOX_POSITION
	left.Size = UDim2.fromScale(LEFT_BOX_WIDTH / leftScale, LEFT_BOX_WIDTH / LEFT_BOX_ASPECT / leftScale)
	local leftRatio = left:FindFirstChildOfClass("UIAspectRatioConstraint")
	if leftRatio then
		leftRatio.AspectRatio = LEFT_BOX_ASPECT
	end
	place(tools, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Vector2.new(0, 0))
	-- one column, the VISIBLE pills centred in the box (the UIListLayout instance is kept; TreadmillUI/Visibility
	-- toggles the tools' Visible and a list layout collapses hidden ones, so Shop + Index at rest and
	-- TreadmillSpeedShop + DoubleYourSpeed on a treadmill both sit at mid-height)
	local layout = tools:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.Wraps = false
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(LEFT_ROW_PADDING, 0)
	else
		warn("Elements.Left.Tools has no UIListLayout")
	end

	local done = {}
	for _, spec in ipairs(LEFT_TOOLS) do
		local wrapper = child(tools, spec[1])
		if wrapper then
			-- rounded rectangle, wider than tall; the full box width so every pill is the same size
			wrapper.AnchorPoint = Vector2.new(0, 0)
			wrapper.Size = UDim2.fromScale(1, LEFT_BOX_ASPECT / TOOL_PILL_ASPECT)
			wrapper.LayoutOrder = LEFT_ORDER[spec[1]] or wrapper.LayoutOrder
			aspect(wrapper, TOOL_PILL_ASPECT)
			local button = child(wrapper, "Button")
			local b, icon, label = skinToolButton("Left.Tools." .. spec[1], button, {
				key = spec[2], icon = spec[3], iconChild = spec[4], label = spec[5], pill = true,
			})
			if b then
				local glossy = GLOSSY[spec[1]]
				if glossy then
					skinGlossyTool(b, glossy, icon, label)
					table.insert(done, spec[1] .. "(glossy)")
				else
					table.insert(done, spec[1])
				end
			end
		else
			warn("Elements.Left.Tools.%s missing", spec[1])
		end
	end

	-- BALANCE 2026-09-23 (owner approved): no server handles Rebirth yet, so its sidebar button is hidden (the
	-- list layout closes the gap). Show it again when rebirth is implemented.
	local rebirthTool = child(tools, "Rebirth")
	if rebirthTool and rebirthTool:IsA("GuiObject") then
		rebirthTool.Visible = false
	end

	-- Shop: attention bounce every 6 s (MainHUDController :990-1028)
	local shop = child(tools, "Shop")
	markBounce(shop and child(shop, "Button"), 6, 0)

	-- DoubleYourSpeed (shown on a treadmill): the same glossy pill as Shop (owner 2026-09-23: the premium pill was
	-- "outdated"), the shoe on the sticker plate and the price tag hanging below. Script-owned: Button.Interactable,
	-- Multiplier.Text, PriceTag.Text.Text/Visible, Frame.Sunburst.Rotation.
	local dys = child(tools, "DoubleYourSpeed")
	local dysButton = dys and child(dys, "Button")
	if dysButton and dysButton:IsA("ImageButton") then
		dys.AnchorPoint = Vector2.new(0, 0)
		dys.Size = UDim2.fromScale(1, LEFT_BOX_ASPECT / TOOL_PILL_ASPECT)
		dys.LayoutOrder = LEFT_ORDER.DoubleYourSpeed
		aspect(dys, TOOL_PILL_ASPECT)
		place(dysButton, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
		dysButton.BorderSizePixel = 0
		local frame = child(dysButton, "Frame")
		if frame then
			hideVisual(frame)
			for _, name in ipairs({ "Icon", "Sunburst" }) do
				local art = child(frame, name)
				if art and isImage(art) then
					art.ImageTransparency = 1 -- the Sunburst's LocalScript keeps owning Rotation
				end
			end
		end
		local oldShine = child(dysButton, "SpShine")
		if oldShine and oldShine:IsA("GuiObject") then
			oldShine.Visible = false
		end
		local icon = sidebarIcon(dysButton, Kit.Icons.speed, {
			size = GLOSSY_GEOMETRY.iconSize, position = GLOSSY_GEOMETRY.iconCenter, aspect = 1, zIndex = 3,
		})
		local label = child(dysButton, "Multiplier")
		if label and Kit.isText(label) then
			label.BackgroundTransparency = 1
			label.TextScaled = true
			label.TextWrapped = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			zeroPadding(label)
		end
		skinGlossyTool(dysButton, GLOSSY.DoubleYourSpeed, icon, label)
		local tag = child(dysButton, "PriceTag")
		if tag and tag:IsA("GuiObject") then
			place(tag, UDim2.fromScale(0.8, 0.45), UDim2.fromScale(0.5, 1.16), Vector2.new(0.5, 0.5))
			tag.BackgroundTransparency = 1
			eachText(tag, function(t)
				Kit.styleText(t, "price", { color = C.white, strokeThickness = 0.06, gradient = Kit.Gradients.price, gradientRotation = 90 })
			end)
		end
		local notif = child(dysButton, "Notif")
		if notif and notif:IsA("GuiObject") then
			place(notif, GLOSSY_GEOMETRY.badgeSize, GLOSSY_GEOMETRY.badgePosition, BADGE.anchor)
			notif:SetAttribute("SpShake", true)
		end
		markHover(dysButton, icon, HOVER_TILT)
		markBounce(dysButton, 7, 2)
		table.insert(done, "DoubleYourSpeed(glossy)")
	else
		warn("Elements.Left.Tools.DoubleYourSpeed.Button missing")
	end
	note("Left.Tools: %s", table.concat(done, ", "))
end

local function applyRight(sg)
	local elements = child(sg, "Elements")
	local right = elements and child(elements, "Right")
	local tools = right and child(right, "Tools")
	if not tools then
		warn("Elements.Right.Tools missing")
		return
	end
	-- The promo column moves to the TOP-RIGHT and shrinks, so it can never reach the tabs further down the right
	-- edge. Its UIGridLayout used fixed 130 px cells (huge on a phone): scale cells now follow the box.
	place(right, RIGHT_BOX_SIZE, RIGHT_BOX_POSITION, Vector2.new(1, 0))
	aspect(right, RIGHT_BOX_ASPECT)
	place(tools, UDim2.fromScale(1, 1), UDim2.fromScale(1, 0.5), Vector2.new(1, 0.5))
	local grid = tools:FindFirstChildOfClass("UIGridLayout")
	if grid then
		grid.CellSize = RIGHT_CELL_SIZE
		grid.CellPadding = RIGHT_CELL_PADDING
	end
	local done = {}
	local gr = child(tools, "GroupReward")
	if gr then
		local b = skinToolButton("Right.Tools.GroupReward", child(gr, "Button"), {
			key = "Teleport", icon = Kit.Icons.groupRewards, label = function(btn)
				local i = child(btn, "Icon")
				return i and child(i, "TextLabel")
			end,
		})
		if b then
			table.insert(done, "GroupReward")
		end
	end
	local sp = child(tools, "LimitedStarterPack")
	if sp then
		local button = child(sp, "Button")
		local b, icon = skinToolButton("Right.Tools.LimitedStarterPack", button, {
			custom = PREMIUM_GOLD_SQUARE, icon = Kit.Icons.shopPasses, label = function(btn)
				local i = child(btn, "Icon")
				return i and child(i, "Timer")
			end,
		})
		if b then
			local holder = child(button, "Icon")
			-- "LIMITED" ribbon + price keep their SAH tilt, in the Speedsters type
			local ribbon = holder and child(holder, "Timer_2")
			if ribbon and Kit.isText(ribbon) then
				Kit.styleText(ribbon, "badge", { color = hex("#ff194f"), strokeColor = C.ink, strokeThickness = 0.1 })
				ribbon.ZIndex = 5
			end
			local price = holder and child(holder, "Price")
			if price and Kit.isText(price) then
				Kit.styleText(price, "price", { color = C.white, strokeThickness = 0.08, gradient = Kit.Gradients.price })
				price.ZIndex = 5
			end
			Kit.addShine(button)
			markHover(button, icon, HOVER_TILT_PREMIUM)
			markBounce(button, 7, 5)
			table.insert(done, "LimitedStarterPack(premium gold)")
		end
	end
	note("Right.Tools: %s", table.concat(done, ", "))
end

local function applyRightFrame(sg)
	local elements = child(sg, "Elements")
	local rf = elements and child(elements, "RightFrame")
	local bf = rf and child(rf, "ButtonsFrame")
	local dys = bf and child(bf, "DoubleYourSpeed")
	if not (dys and dys:IsA("ImageButton")) then
		warn("Elements.RightFrame.ButtonsFrame.DoubleYourSpeed missing")
		return
	end
	-- Hidden alternate container for the 2X Speed pill; it used to span the right edge on top of the tabs. Park it
	-- left of the tab column so it cannot overlap them if a script ever shows it.
	if rf:IsA("GuiObject") then
		rf.Position = UDim2.fromScale(0.86, 0.5)
		rf.AnchorPoint = Vector2.new(1, 0.5)
	end
	aspect(dys, Sz.premiumButton.aspect)
	skinPremiumPill(dys, "premium_blue", {
		icon = child(dys, "Icon"), sunburst = child(dys, "Sunburst"),
		multiplier = child(dys, "Multiplier"), priceTag = child(dys, "PriceTag"),
	}, { bounceOffset = 5 })
	note("RightFrame.ButtonsFrame.DoubleYourSpeed: premium pill")
end

local function applyTabs(sg)
	local elements = child(sg, "Elements")
	local tabs = elements and child(elements, "Tabs")
	if not tabs then
		warn("Elements.Tabs missing")
		return
	end
	local done = {}
	-- Right-edge column, vertically centred like the left one: exactly one pill wide, two pills + one gap tall.
	place(tabs, TABS_BOX_SIZE, TABS_BOX_POSITION, Vector2.new(1, 0.5))
	local tabsRatio = tabs:FindFirstChildOfClass("UIAspectRatioConstraint")
	if tabsRatio then
		tabsRatio.AspectRatio = TABS_BOX_ASPECT
		tabsRatio.AspectType = Enum.AspectType.FitWithinMaxSize
		tabsRatio.DominantAxis = Enum.DominantAxis.Width
	end
	local tabsLayout = tabs:FindFirstChildOfClass("UIListLayout")
	if tabsLayout then
		tabsLayout.FillDirection = Enum.FillDirection.Vertical
		tabsLayout.Wraps = false
		tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tabsLayout.Padding = UDim.new(TAB_GAP, 0)
	end

	-- Both tabs are the left column's glossy material on a rounded square: same corner, gloss and studs, the icon
	-- centred and large, no sticker plate and no caption (the captions stay for the scripts and tests, hidden).
	local function squareTab(tab, order, family, iconId, iconChild, glossy)
		tab.AnchorPoint = Vector2.new(0, 0)
		tab.Size = UDim2.fromScale(1, TAB_ROW)
		tab.LayoutOrder = order
		tab.Text = ""
		aspect(tab, 1)
		for _, name in ipairs({ "InletTexture", "BevelEffect" }) do
			local legacy = child(tab, name)
			if legacy and isImage(legacy) then
				legacy.ImageTransparency = 1 -- the base square art would show through the corners
			end
		end
		local label = child(tab, "Label")
		local _, icon = Kit.skinSidebarButton(tab, family, iconId, {
			target = tab, icon = iconChild, placeIcon = false, iconZIndex = 3, label = label,
		})
		skinGlossyTool(tab, glossy, icon, label)
		-- square geometry on top of the pill material
		local g = GLOSSY_GEOMETRY
		studLayer(tab, UDim2.fromScale(1 / 4, 1 / 4), g.studTransparency, TOOL_PILL_CORNER, g.z.studs)
		local plate = child(tab, "SpIconPlate")
		if plate and plate:IsA("GuiObject") then
			plate.Visible = false
		end
		if icon and icon:IsA("GuiObject") then
			place(icon, TAB_ICON_SIZE, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
			aspect(icon, 1)
		end
		if label and label:IsA("GuiObject") then
			label.Visible = false
		end
		-- the base tab's own gradient and outline would paint over the square (no script drives them)
		for _, c in ipairs(tab:GetChildren()) do
			if c:IsA("UIGradient") and c.Name ~= Kit.Names.fill then
				c.Enabled = false
			end
		end
		Kit.hideLegacyStrokes(tab)
		markHover(tab, icon, HOVER_TILT)
		return icon
	end

	-- A big glossy letter in place of an icon (HERO INDEX until the owner's own icon is uploaded).
	local function letterIcon(tab, letter, stroke)
		local face = Kit.ensureChild(tab, "TextLabel", "SpLetter")
		face.Text = letter
		face.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
		face.TextColor3 = C.white
		face.TextScaled = true
		face.TextWrapped = true
		face.TextXAlignment = Enum.TextXAlignment.Center
		face.TextYAlignment = Enum.TextYAlignment.Center
		face.TextStrokeTransparency = 1
		face.BackgroundTransparency = 1
		face.Rotation = 0
		face.Visible = true
		place(face, UDim2.fromScale(0.7, 0.7), UDim2.fromScale(0.5, 0.52), Vector2.new(0.5, 0.5))
		face.ZIndex = GLOSSY_GEOMETRY.z.icon
		zeroPadding(face)
		Kit.addGradient(face, { { 0, "#ffffff" }, { 0.55, "#ffffff" }, { 1, "#e2d2ff" } }, 90, Kit.Names.textGradient)
		Kit.addStroke(face, { name = "SpTextStroke", color = stroke, thickness = 0.12, mode = "Contextual", zIndex = 1 })
		return face
	end

	local eggs = child(tabs, "GrowingEggs")
	if eggs and eggs:IsA("GuiButton") then
		-- Steal a Hero's own egg sticker as a new SpIcon layer: the protected `Icon` child (same art) stays hidden,
		-- exactly like Pets keeps its paw `Vector` hidden behind HeroIcon. The caption keeps the text "EGGS".
		squareTab(eggs, 1, "Rebirth", EGG_ICON, nil, GLOSSY.Eggs)
		-- script-owned: Visible of Notification / ReadyNotification / NightText / NightImage and their counts.
		-- The two counters hang off the pill's top corners so they never sit on the caption.
		skinBadge(child(eggs, "Notification"), "red", { speedstersPlace = true, size = TAB_BADGE_SIZE, position = UDim2.fromScale(0.1, 0.1) })
		skinBadge(child(eggs, "ReadyNotification"), "green", { speedstersPlace = true, size = TAB_BADGE_SIZE, position = UDim2.fromScale(0.9, 0.1) })
		-- night indicators (script-owned Visible): moon above-left, the multiplier above-right of the square
		local night = child(eggs, "NightText")
		if night and Kit.isText(night) then
			Kit.styleText(night, "body", { keepColor = true, strokeColor = hex("#003f05"), strokeThickness = 0.1 })
			place(night, UDim2.fromScale(0.8, 0.34), UDim2.fromScale(0.72, -0.04), Vector2.new(0.5, 1))
		end
		local nightImage = child(eggs, "NightImage")
		if nightImage and nightImage:IsA("GuiObject") then
			place(nightImage, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.22, -0.04), Vector2.new(0.5, 1))
			aspect(nightImage, 1)
		end
		table.insert(done, "GrowingEggs(square, egg icon)")
	end

	local pets = child(tabs, "Pets")
	if pets and pets:IsA("GuiButton") then
		local icon = squareTab(pets, 2, "Index", HERO_ICON, child(pets, "HeroIcon"), GLOSSY.HeroTab) -- caption keeps "HERO INDEX" (hidden)
		-- owner 2026-09-23: a big "H" until the owner's own minimalist icon is uploaded (HERO_TAB_ICON)
		if HERO_TAB_ICON then
			if icon and isImage(icon) then
				icon.ImageContent = Content.fromAssetId(HERO_TAB_ICON)
			end
			local letter = child(pets, "SpLetter")
			if letter then
				letter.Visible = false
			end
		else
			for _, name in ipairs({ "HeroIcon", "Vector", "Icon" }) do
				local art = child(pets, name)
				if art and art:IsA("GuiObject") then
					art.Visible = false
				end
			end
			if icon and icon:IsA("GuiObject") then
				icon.Visible = false
			end
			local letter = letterIcon(pets, TAB_LETTER, GLOSSY.HeroTab.outline)
			markHover(pets, letter, HOVER_TILT)
		end
		-- script-owned: Visible, Badge.Visible + its runtime UIScale (PetPenCapacityGuidanceController)
		skinBadge(child(pets, "Badge"), "red", { speedstersPlace = true, size = TAB_BADGE_SIZE, position = UDim2.fromScale(0.1, 0.1) })
		local close = child(pets, "Close")
		if close and Kit.isText(close) then
			place(close, UDim2.fromScale(0.7, 0.7), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
			close.ZIndex = math.max(close.ZIndex, GLOSSY_GEOMETRY.z.label)
			close.TextScaled = true
			close.TextWrapped = true
		end
		table.insert(done, "Pets(square, " .. (if HERO_TAB_ICON then "owner icon" else "letter H") .. ")")
	end
	note("Tabs: %s", table.concat(done, ", "))
end

-- Currency counters (hud.currency_counter): GothamSSm Bold numbers, ScaledSize 0.05 ink outline, icon beside them.
local function counterText(label, opts)
	if label and Kit.isText(label) then
		Kit.styleText(label, "number", opts)
		for _, c in ipairs(label:GetChildren()) do
			if c:IsA("UIStroke") then
				clearOldp(c)
			end
		end
	end
end

-- Currency ribbon (owner brief, 3rd pass) on a row Frame: the band is the row's own background (SpeedValue and
-- Money hold a UIListLayout, so a GuiObject layer would be laid out as a row item): flat translucent navy, a small
-- corner, a faint INNER light hairline, no gradient / gloss / outline. The row keeps a fixed aspect (SpAspect or its
-- existing constraint), which the H-unit geometry of RIBBON relies on. Only Visible is script-owned on these rows.
local function ribbon(row, size, ratio)
	row.Size = size
	aspect(row, ratio)
	row.BackgroundColor3 = RIBBON.color
	row.BackgroundTransparency = RIBBON.transparency
	row.BorderSizePixel = 0
	row.Rotation = 0
	for _, c in ipairs(row:GetChildren()) do
		if c:IsA("UIGradient") then
			c.Enabled = false -- flat band (legacy tint, or the D7 SpFill of an already skinned place)
		end
	end
	Kit.setCorner(row, RIBBON.corner)
	Kit.hideLegacyStrokes(row)
	local outline = child(row, Kit.Names.strokeDark, "UIStroke")
	if outline then
		outline.Enabled = false -- the D7 pill outline (re-run on an already skinned place)
	end
	Kit.addStroke(row, {
		name = Kit.Names.strokeLight, color = C.white, thickness = RIBBON.edge.thickness,
		transparency = RIBBON.edge.transparency, position = "Inner", zIndex = 1,
	})
end

-- The row's UIPadding (left inset only, so child scales are fractions of the full ribbon height) and horizontal
-- UIListLayout (both kept, reconfigured): icon, gap, value.
local function ribbonRow(row, ratio)
	local pad = row:FindFirstChildOfClass("UIPadding") or Kit.ensureChild(row, "UIPadding", "SpPadding")
	pad.PaddingLeft = UDim.new(RIBBON.padLeft / ratio, 0)
	pad.PaddingRight = UDim.new(0, 0)
	pad.PaddingTop = UDim.new(0, 0)
	pad.PaddingBottom = UDim.new(0, 0)
	local list = row:FindFirstChildOfClass("UIListLayout")
	if list then
		list.FillDirection = Enum.FillDirection.Horizontal
		list.Wraps = false
		list.HorizontalAlignment = Enum.HorizontalAlignment.Left
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(RIBBON.gap / (ratio - RIBBON.padLeft), 0)
	else
		warn("Money.Bottom.Frame.%s has no UIListLayout", row.Name)
	end
end

-- Icon at the left end of a ribbon row (a list item): square, RIBBON.icon x the ribbon height, centred on the band.
local function ribbonIcon(icon)
	icon.Size = UDim2.fromScale(RIBBON.icon, RIBBON.icon)
	icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
	icon.Rotation = 0
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.ZIndex = math.max(icon.ZIndex, 3)
	aspect(icon, 1)
end

-- Value text in the Shop / Index label type: FredokaOne, white (or opts.color) with the thick ink Contextual outline,
-- left-aligned, TextScaled + TextWrapped (TextScaled alone renders at the tiny fixed TextSize) under a size cap.
--   opts.color | opts.scriptOwned (TextColor3 left alone) | opts.keepColor; opts.outline == false: font + box only
--   (the hidden face of a two-face label: its own strokes stay as authored).
local function ribbonText(label, opts)
	opts = opts or {}
	label.AutomaticSize = Enum.AutomaticSize.None
	label.BackgroundTransparency = 1
	label.Rotation = 0
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	zeroPadding(label)
	local cap = label:FindFirstChildOfClass("UITextSizeConstraint") or Kit.ensureChild(label, "UITextSizeConstraint", "SpTextCap")
	cap.MinTextSize = 1
	cap.MaxTextSize = RIBBON.textMax
	if opts.outline == false then
		Kit.setFont(label, "sidebar")
		return label
	end
	Kit.styleText(label, "sidebar", {
		color = opts.color, keepColor = opts.keepColor, scriptOwned = opts.scriptOwned,
		strokeThickness = RIBBON.textStroke, strokeColor = C.ink,
	})
	for _, c in ipairs(label:GetChildren()) do
		if c:IsA("UIStroke") then
			clearOldp(c)
		end
	end
	return label
end

-- A two-face value label (hidden face + visible "Shadow" child, both written by UpdateTextAndShadow; "White" is a
-- hidden flash layer): box/font on the hidden face, the full type on the visible face through `faceOpts`.
local function valueFaces(label, faceOpts)
	ribbonText(label, { outline = false })
	for _, name in ipairs({ "Shadow", "White" }) do
		local face = child(label, name)
		if face and Kit.isText(face) then
			if name == "Shadow" then
				ribbonText(face, faceOpts)
			else
				ribbonText(face, { keepColor = true })
			end
		end
	end
end

-- The Speed "+" shortcut (SpeedValue.ImageLabel.ImageButton, ButtonFX-bound by SpeedShopShortcut: name, class and
-- parent kept). It stays a child of the icon holder but sits at the RIGHT end of the speed ribbon, inset like a key
-- cap: its box is expressed in holder units (the holder is RIBBON.icon H square, starts RIBBON.padLeft H into the
-- ribbon and is centred on it). A gold square with a thin ink outline and a big white "+" (SpPlus) drawn by us; the
-- legacy plus art is kept, transparent.
local function skinPlusButton(button, rowAspect)
	local P = RIBBON.plus
	local unit = 1 / RIBBON.icon -- 1 H in holder scale
	local centreX = rowAspect - P.inset - P.size / 2 - RIBBON.padLeft -- H, from the holder's left edge
	place(button, UDim2.fromScale(P.size * unit, P.size * unit), UDim2.fromScale(centreX * unit, 0.5), Vector2.new(0.5, 0.5))
	button.SizeConstraint = Enum.SizeConstraint.RelativeXY
	aspect(button, 1)
	button.ImageTransparency = 1
	button.BackgroundColor3 = C.white
	button.BackgroundTransparency = 0
	button.BorderSizePixel = 0
	button.Rotation = 0
	button.ZIndex = math.max(button.ZIndex, 5)
	Kit.addGradient(button, P.fill, 90, Kit.Names.fill)
	Kit.setCorner(button, P.corner)
	Kit.hideLegacyStrokes(button)
	Kit.addStroke(button, { name = Kit.Names.strokeDark, color = P.stroke, thickness = P.strokeThickness, zIndex = 2 })
	local glyph = Kit.ensureChild(button, "TextLabel", "SpPlus")
	glyph.Text = "+"
	glyph.BackgroundTransparency = 1
	glyph.BorderSizePixel = 0
	place(glyph, UDim2.fromScale(0.9, 0.9), UDim2.fromScale(0.5, 0.47), Vector2.new(0.5, 0.5))
	glyph.Rotation = 0
	glyph.AutomaticSize = Enum.AutomaticSize.None
	glyph.TextScaled = true
	glyph.TextWrapped = true -- (TextScaled + TextWrapped = false renders the "+" at the tiny fixed TextSize)
	glyph.TextXAlignment = Enum.TextXAlignment.Center
	glyph.TextYAlignment = Enum.TextYAlignment.Center
	glyph.ZIndex = button.ZIndex + 1
	glyph.Active = false
	Kit.styleText(glyph, "sidebar", { strokeThickness = P.glyphStroke, strokeColor = C.ink })
	return glyph
end

-- FriendBoost / TemporarySpeedBoost: a slimmer ribbon with no layout inside, so the icon is a free SpIcon layer at
-- the left end and the value line is placed after it.
local function lineRibbon(line, iconId)
	ribbon(line, RIBBON.lineSize, RIBBON.lineAspect)
	local icon = Kit.ensureChild(line, "ImageLabel", Kit.Names.icon)
	Kit.setImage(icon, iconId)
	icon.ImageTransparency = 0
	icon.ImageColor3 = C.white
	icon.ScaleType = Enum.ScaleType.Fit
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.fromScale(RIBBON.padLeft / RIBBON.lineAspect, 0.5)
	icon.Active = false
	ribbonIcon(icon)
	return icon
end

local function placeLineText(label)
	local x0 = RIBBON.padLeft + RIBBON.icon + RIBBON.gap -- H
	local width = RIBBON.lineAspect - x0 - RIBBON.textRight
	place(label, UDim2.fromScale(width / RIBBON.lineAspect, RIBBON.textHeight), UDim2.fromScale(x0 / RIBBON.lineAspect, 0.5),
		Vector2.new(0, 0.5))
	label.SizeConstraint = Enum.SizeConstraint.RelativeXY
end

-- The Money icon: the Shop's banknotes art (RIBBON.cashIconPath), else the recorded id.
local function cashIcon(sg)
	local source = Kit.findPath(sg, RIBBON.cashIconPath)
	local id = source and isImage(source) and Kit.imageId(source)
	if id then
		return id, "StarterGui." .. RIBBON.cashIconPath
	end
	warn("StarterGui.%s missing: Money icon uses the recorded cash id %d", RIBBON.cashIconPath, RIBBON.cashIcon)
	return RIBBON.cashIcon, "fallback"
end

local function applyMoney(sg)
	local money = child(sg, "Money")
	local frame = money and Kit.findPath(money, "Bottom.Frame")
	if not frame then
		warn("Money.Bottom.Frame missing")
		return
	end
	local done = {}
	-- the vertical column (bottom-aligned: FriendBoost at the bottom, Money, then SpeedValue on top), its left edge
	-- lined up with the Elements.Left column, with a real gap between the ribbons
	frame.AnchorPoint = RIBBON.frameAnchor
	frame.Position = RIBBON.framePosition
	local column = frame:FindFirstChildOfClass("UIListLayout")
	if column then
		column.Padding = RIBBON.listPadding
	else
		warn("Money.Bottom.Frame has no UIListLayout")
	end
	local rowContent = RIBBON.rowAspect - RIBBON.padLeft -- the rows' list content width, H
	local valueStart = RIBBON.padLeft + RIBBON.icon + RIBBON.gap -- H

	-- Money: Money.Money is the hidden face (TextTransparency 1), Shadow the visible face, White a spare flash layer.
	-- MoneyUpdate writes Text on Money and Shadow only (UpdateTextAndShadow without a colour): the green is ours.
	local card = child(frame, "Money")
	local label = card and child(card, "Money")
	if card and label and Kit.isText(label) then
		ribbon(card, RIBBON.rowSize, RIBBON.rowAspect)
		ribbonRow(card, RIBBON.rowAspect)
		label.Size = UDim2.fromScale((RIBBON.rowAspect - valueStart - RIBBON.textRight) / rowContent, RIBBON.textHeight)
		label.SizeConstraint = Enum.SizeConstraint.RelativeXY
		-- (a list item: the layout places it; the anchor is only the SpPulse UIScale pivot -> grow from the left edge)
		label.AnchorPoint = Vector2.new(0, 0.5)
		valueFaces(label, { color = RIBBON.moneyColor })
		label:SetAttribute("SpPulse", true)
		local icon = child(card, "CurrencyIcon")
		if icon and isImage(icon) then
			local id, source = cashIcon(sg)
			Kit.setImage(icon, id)
			icon.ImageTransparency = 0
			icon.ImageColor3 = C.white
			icon.ScaleType = Enum.ScaleType.Fit
			ribbonIcon(icon)
			table.insert(done, string.format("Money(ribbon, cash icon %s from %s)", tostring(id), source))
		else
			warn("Money.Bottom.Frame.Money.CurrencyIcon missing")
			table.insert(done, "Money(ribbon)")
		end
	else
		warn("Money.Bottom.Frame.Money.Money missing")
	end

	-- Speed: CurrentBoost (hidden face) + Shadow (visible; Text AND TextColor3 written by TreadmillUI from the authored
	-- colour or the trail rarity colour -> never written here). ImageLabel holds the shoe + the "+" button.
	local speed = child(frame, "SpeedValue")
	if speed and speed:IsA("GuiObject") then
		ribbon(speed, RIBBON.rowSize, RIBBON.rowAspect)
		ribbonRow(speed, RIBBON.rowAspect)
		local holder = child(speed, "ImageLabel")
		if holder and holder:IsA("GuiObject") then
			holder.LayoutOrder = 0
			ribbonIcon(holder)
			local shoe = child(holder, "SpeedtersShoe")
			if shoe and isImage(shoe) then
				-- Speedsters speed currency icon (Rightbuttons.2xSpeed.Icon / Speedbuy.*.Icon)
				Kit.setImage(shoe, Kit.Icons.speed)
				shoe.ScaleType = Enum.ScaleType.Fit
				shoe.ImageTransparency = 0
				shoe.ZIndex = math.max(shoe.ZIndex, 3)
				place(shoe, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
				aspect(shoe, 1)
			end
			local plus = child(holder, "ImageButton")
			if plus and plus:IsA("ImageButton") then
				skinPlusButton(plus, RIBBON.rowAspect)
			else
				warn("Money.Bottom.Frame.SpeedValue.ImageLabel.ImageButton missing")
			end
		end
		local boost = child(speed, "CurrentBoost")
		if boost and Kit.isText(boost) then
			boost.LayoutOrder = 1
			-- the value ends before the "+" (inset + size + gap from the ribbon's right end)
			local P = RIBBON.plus
			local width = RIBBON.rowAspect - P.inset - P.size - P.gap - valueStart
			boost.Size = UDim2.fromScale(width / rowContent, RIBBON.textHeight)
			boost.SizeConstraint = Enum.SizeConstraint.RelativeXY
			valueFaces(boost, { scriptOwned = { TextColor3 = true } })
		end
		table.insert(done, "SpeedValue(ribbon, + at the right end)")
	end

	-- buff lines (Visible + Text script-owned)
	local temp = child(frame, "TemporarySpeedBoost")
	local tempLabel = temp and child(temp, "CurrentBoost")
	if temp and tempLabel and Kit.isText(tempLabel) then
		lineRibbon(temp, RIBBON.boostIcon)
		placeLineText(tempLabel)
		ribbonText(tempLabel, { color = C.accentCyan })
		table.insert(done, "TemporarySpeedBoost(ribbon)")
	end
	local friend = child(frame, "FriendBoost")
	local friendLabel = friend and child(friend, "CurrentBoost")
	if friend and friendLabel and Kit.isText(friendLabel) then
		lineRibbon(friend, RIBBON.friendIcon)
		placeLineText(friendLabel)
		valueFaces(friendLabel, { color = C.white })
		table.insert(done, "FriendBoost(ribbon)")
	end
	-- hover-info boost list (hidden at rest): Speedsters stat box panels + FredokaOne rows
	local boosts = child(frame, "BoostsList")
	if boosts then
		for _, d in ipairs(boosts:GetDescendants()) do
			if Kit.isText(d) then
				Kit.styleText(d, "row", { keepColor = true })
			elseif d:IsA("Frame") and d.Name == "Frame" and d.Parent and d.Parent:IsA("Folder") then
				-- the hover panel's backdrop (afk.stat_box: #000 @0.45, corner 0.1, ink hairline)
				d.BackgroundColor3 = C.black
				d.BackgroundTransparency = 0.45
				Kit.setCorner(d, 0.1)
				Kit.hideLegacyStrokes(d)
				Kit.addStroke(d, { name = Kit.Names.stroke, thickness = 0.012, color = C.ink })
			end
		end
		table.insert(done, "BoostsList")
	end
	note("Money counters: %s", table.concat(done, ", "))
end

local function applyHud(sg)
	local hud = child(sg, "Hud")
	if not hud then
		warn("StarterGui.Hud missing")
		return
	end
	local done = {}

	-- RightHUD (hidden at rest): premium gold squares with the 3D preview kept on top
	local rightHud = child(hud, "RightHUD")
	if rightHud then
		for _, name in ipairs({ "Btn_TreadmillUpgrade", "Btn_HorizonStep" }) do
			local btn = child(rightHud, name)
			if btn and btn:IsA("ImageButton") then
				paintSquare(btn, PREMIUM_GOLD_SQUARE)
				local rays = child(btn, "sunburst67")
				if rays and isImage(rays) then
					rays.ImageTransparency = 1 -- its LocalScript keeps owning Rotation
				end
				Kit.addShine(btn)
				local info = child(btn, "Info")
				if info then
					eachText(info, function(t)
						if t.Name == "Txt_Price" then
							-- Text written by TreadmillUpgradeButton (robux glyph + price)
							Kit.styleText(t, "price", { color = C.white, stroke = false, gradient = Kit.Gradients.price })
						else
							Kit.setFont(t, "body")
						end
						for _, c in ipairs(t:GetChildren()) do
							if c:IsA("UIStroke") then
								c.Color = C.ink
							end
						end
					end)
				end
				-- juice: tilt/bounce the price + title block (the ViewportFrame preview is left alone)
				markHover(btn, info, HOVER_TILT_PREMIUM)
				markBounce(btn, 7, 3)
				table.insert(done, "RightHUD." .. name)
			end
		end
	end

	-- MoneyFrame speed-buy buttons (hud.speed_buy_button): premium pill tinted speed_buy_gold on a layer (the
	-- TextButton draws no text of its own: TextTransparency 1; TextOverlay.Text written by BoostStaminaClient)
	local moneyFrame = child(hud, "MoneyFrame")
	local row = moneyFrame and child(moneyFrame, "Frame")
	if row then
		for i = 1, 3 do
			local boost = child(row, "FrameBoost" .. i)
			local btn = boost and child(boost, "Money" .. i)
			if btn and btn:IsA("GuiButton") then
				boost.BackgroundTransparency = 1
				Kit.hideLegacyStrokes(boost)
				btn.BorderSizePixel = 0
				Kit.skinButton(btn, "speed_buy_gold", { mode = "layer" })
				local shoe = child(btn, "ShoeIcon")
				if shoe and isImage(shoe) then
					Kit.setImage(shoe, Kit.Icons.speed)
					shoe.ScaleType = Enum.ScaleType.Stretch
					shoe.Rotation = 0
					place(shoe, UDim2.fromScale(0.26, 0.9), UDim2.fromScale(0.16, 0.5), Vector2.new(0.5, 0.5))
					aspect(shoe, 1)
				end
				local overlay = child(btn, "TextOverlay")
				if overlay and Kit.isText(overlay) then
					place(overlay, UDim2.fromScale(0.66, 0.7), UDim2.fromScale(0.31, 0.5), Vector2.new(0, 0.5))
					zeroPadding(overlay)
					Kit.styleText(overlay, "button", { strokeThickness = 0.08 })
				end
				markHover(btn, shoe, HOVER_TILT_PREMIUM)
				table.insert(done, "MoneyFrame.FrameBoost" .. i)
			end
		end
	end

	-- LeftHUD: admin-panel promo (Visible toggled by HideImportantUI / AdminEntryVisibility) + promo card
	local leftHud = child(hud, "LeftHUD")
	local list = leftHud and child(leftHud, "Uilistlayout")
	local admin = list and child(list, "AdminPanel")
	local adminBtn = admin and child(admin, "ImageButton")
	if adminBtn and adminBtn:IsA("GuiButton") then
		Kit.skinButton(adminBtn, "premium_gold", { mode = "layer" })
		for _, d in ipairs(adminBtn:GetDescendants()) do
			if d:IsA("ImageLabel") and d.Name == "ImageLabel" then
				Kit.setImage(d, Kit.Icons.adminCrown)
			elseif d:IsA("UIStroke") and d.Parent and d.Parent:IsA("Frame") then
				d.Transparency = 1 -- rainbow outline of the inner row
			elseif Kit.isText(d) then
				Kit.styleText(d, "button", { strokeThickness = 0.08 })
			end
		end
		table.insert(done, "LeftHUD.AdminPanel")
	end
	local promo = leftHud and child(leftHud, "Notification")
	if promo and promo:IsA("GuiObject") then
		local bg = Kit.findPath(promo, "Background.Background")
		if bg and bg:IsA("Frame") then
			-- Speedsters ticker card (MessageHandler: white + theme gradient + theme stroke + stud texture)
			bg.BackgroundColor3 = C.white
			bg.BackgroundTransparency = 0
			Kit.addGradient(bg, { { 0, TICKER.top }, { 1, TICKER.bottom } }, 90, Kit.Names.fill)
			Kit.setCorner(bg, 0.12)
			Kit.addStroke(bg, { name = Kit.Names.stroke, thickness = 0.025, color = TICKER.stroke })
			local studs = Kit.ensureChild(bg, "ImageLabel", "SpStuds")
			Kit.setImage(studs, Kit.Images.stud)
			studs.BackgroundTransparency = 1
			studs.ScaleType = Enum.ScaleType.Tile
			studs.TileSize = TICKER.studsTile
			studs.ImageTransparency = TICKER.studsTransparency
			studs.Size = UDim2.fromScale(1, 1)
			studs.ZIndex = 0
			Kit.setCorner(studs, 0.12)
			for _, name in ipairs({ "BG", "BottomBar", "InsideStroke" }) do
				hideVisual(child(bg, name))
			end
		end
		hideVisual(Kit.findPath(promo, "Background.ProgressBar"))
		eachText(promo, function(t)
			Kit.styleText(t, "button", { strokeThickness = 0.08 })
		end)
		table.insert(done, "LeftHUD.Notification")
	end

	-- JoinGroup (zero-width at rest): claim-green action pill
	local join = child(hud, "JoinGroup")
	if join and join:IsA("ImageButton") then
		Kit.skinButton(join, "claim_green", { mode = "direct" })
		join.BorderSizePixel = 0
		table.insert(done, "JoinGroup")
	end
	note("Hud: %s", table.concat(done, ", "))
end

-- Toast/ticker text: FredokaOne + ScaledSize ink outline (colours stay: the notification scripts pass their own).
local function toastText(t, thickness)
	Kit.styleText(t, "body", { keepColor = true, strokeThickness = thickness or 0.08 })
	t.TextStrokeTransparency = 1
end

local function paintTickerCard(frame)
	frame.BackgroundColor3 = C.white
	frame.BackgroundTransparency = 0
	local g = frame:FindFirstChildOfClass("UIGradient")
	if g then
		g.Color = Kit.seq({ { 0, TICKER.top }, { 1, TICKER.bottom } })
		g.Transparency = Kit.numberSeq(0)
		g.Rotation = 90
		g.Offset = Vector2.new(0, 0)
		g.Enabled = true
	else
		Kit.addGradient(frame, { { 0, TICKER.top }, { 1, TICKER.bottom } }, 90, Kit.Names.fill)
	end
	Kit.setCorner(frame, 0.12)
	Kit.addStroke(frame, { name = Kit.Names.stroke, thickness = 0.02, color = TICKER.stroke })
	local studs = Kit.ensureChild(frame, "ImageLabel", "SpStuds")
	Kit.setImage(studs, Kit.Images.stud)
	studs.BackgroundTransparency = 1
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = TICKER.studsTile
	studs.ImageTransparency = TICKER.studsTransparency
	studs.AnchorPoint = Vector2.new(0.5, 0.5)
	studs.Position = UDim2.fromScale(0.5, 0.5)
	studs.Size = UDim2.fromScale(1, 1)
	studs.ZIndex = 0
	studs.Active = false
	Kit.setCorner(studs, 0.12)
end

local function applyNotifications(sg, rs)
	local done = {}
	local notifications = child(sg, "Notifications")
	if notifications then
		-- Top: the host NotificationInstance slides in (Visible/Position script-owned); it becomes the ticker card
		local top = child(notifications, "Top")
		if top and top:IsA("Frame") then
			paintTickerCard(top)
		end
		eachText(notifications, function(t)
			toastText(t)
		end)
		table.insert(done, "StarterGui.Notifications")
	end
	local templates = rs and Kit.findPath(rs, "Assets.UI.Notifications")
	if templates then
		local n = 0
		eachText(templates, function(t)
			toastText(t)
			n += 1
		end)
		-- Bottom text toasts (Message / Discover / Warn): the row Frame (UIListLayout of icon + text) hugs its
		-- content and becomes the Speedsters toast card. NotificationCmds writes the texts, the icon, the
		-- CanvasGroup's Size and the Shadow's Visible/ImageTransparency; the row Frame's size is ours.
		local bottom = child(templates, "Bottom")
		for _, name in ipairs({ "Message", "Discover", "Warn" }) do
			local group = bottom and child(bottom, name)
			local row = group and child(group, "Frame")
			if row and row:IsA("Frame") and row:FindFirstChildOfClass("UIListLayout") then
				local height = row.Size.Y.Scale
				row.AutomaticSize = Enum.AutomaticSize.X
				row.Size = UDim2.new(0, 0, if height > 0 then height else 1, 0)
				row.AnchorPoint = Vector2.new(0.5, row.AnchorPoint.Y)
				row.Position = UDim2.new(0.5, 0, row.Position.Y.Scale, row.Position.Y.Offset)
				row.BackgroundColor3 = TOAST.color
				row.BackgroundTransparency = TOAST.transparency
				row.BorderSizePixel = 0
				Kit.setCorner(row, TOAST.corner)
				Kit.addStroke(row, {
					name = Kit.Names.stroke, thickness = 2, sizing = "FixedSize", color = TOAST.stroke,
					transparency = TOAST.strokeTransparency,
				})
				local pad = Kit.ensureChild(row, "UIPadding", "SpPadding")
				pad.PaddingLeft = TOAST.padding
				pad.PaddingRight = TOAST.padding
			end
		end
		-- Bottom item tiles: Speedsters ink hairline instead of the px black outline
		for _, d in ipairs(templates:GetDescendants()) do
			if d:IsA("Frame") and d.Name == "ItemHolder" then
				Kit.setCorner(d, 0.2)
				for _, c in ipairs(d:GetChildren()) do
					if c:IsA("UIStroke") and c.Enabled then
						c.Color = C.ink
						c.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
						c.Thickness = 0.05
						clearOldp(c)
					end
				end
			end
		end
		table.insert(done, string.format("RS.Assets.UI.Notifications (%d texts)", n))
	end

	-- Friend_Notification: its LocalScript snapshots every TextLabel/UIStroke/ImageLabel that starts fully opaque and
	-- tweens only those back in (Frames lose their background on show), so the card lives on the Background
	-- ImageLabel (image + background) and every new stroke starts at Transparency 0.
	local friend = child(sg, "Friend_Notification")
	local card = friend and Kit.findPath(friend, "Frame.Frame.Background")
	if card and card:IsA("ImageLabel") then
		Kit.setImage(card, Kit.Images.windowArt)
		card.ScaleType = Enum.ScaleType.Stretch
		card.ImageTransparency = 0
		card.BackgroundColor3 = C.white
		card.BackgroundTransparency = 0
		Kit.setCorner(card, 0.08)
		Kit.addStroke(card, { name = Kit.Names.stroke, thickness = 0.012, color = C.ink })
		local buttons = Kit.findPath(card, "Holder.Frame")
		if buttons then
			local accept = child(buttons, "Accept")
			if accept and accept:IsA("ImageButton") then
				Kit.skinButton(accept, "claim_green", { mode = "direct" })
				accept.BorderSizePixel = 0
			end
			local decline = child(buttons, "Decline")
			if decline and decline:IsA("ImageButton") then
				Kit.skinButton(decline, "red", { mode = "direct" })
				decline.BorderSizePixel = 0
			end
		end
		eachText(card, function(t)
			if t.Name == "Description" then
				Kit.styleText(t, "button", { strokeThickness = 0.08 })
			elseif t.Name == "TitleTabel" then
				Kit.styleText(t, "title", { strokeThickness = 0.06 })
			else
				Kit.styleText(t, "body", { keepColor = true, strokeThickness = 0.07 })
			end
			t.TextStrokeTransparency = 1
		end)
		table.insert(done, "Friend_Notification")
	end
	note("Toasts: %s", table.concat(done, ", "))
end

-- D7 night / sleep timer (ref 08). GameResetTimer.{TimeLeft, EndingSoon} = Background (decorative vignette) + Main
-- (UIListLayout: Frame icon holder + TextLabel). Script-owned (GameResetTimer.client): TimeLeft Position (X on
-- mobile) + Visible, EndingSoon Visible, Main.TextLabel Text + TextColor3 (the authored colour is its "normal"
-- colour, red while blinking) and Main.Frame.ImageLabel Image (moon by day, sun by night). The Background becomes
-- the floating night-blue pill, an SpShadow sits under it, the icon gets an SpGlow halo and the label a fixed box
-- (no AutomaticSize) with the stylised type.
local function nightPill(pill, size)
	place(pill, size, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	pill.BackgroundColor3 = C.white
	pill.BackgroundTransparency = NIGHT.transparency
	pill.BorderSizePixel = 0
	pill.Rotation = 0
	local gradient = nil
	for _, c in ipairs(pill:GetChildren()) do
		if c:IsA("UIGradient") then
			if gradient == nil then
				gradient = c -- the vignette gradient becomes the night fill
			else
				c.Enabled = false
			end
		end
	end
	if gradient then
		gradient.Color = Kit.seq(NIGHT.fill)
		gradient.Transparency = Kit.numberSeq(0)
		gradient.Rotation = 90
		gradient.Offset = Vector2.new(0, 0)
		gradient.Enabled = true
	else
		Kit.addGradient(pill, NIGHT.fill, 90, Kit.Names.fill)
	end
	Kit.setCorner(pill, NIGHT.corner)
	Kit.hideLegacyStrokes(pill)
	Kit.addStroke(pill, {
		name = Kit.Names.stroke, color = NIGHT.rim, thickness = NIGHT.rimThickness, transparency = NIGHT.rimTransparency,
	})
end

-- Soft drop shadow under the pill (a sibling one ZIndex lower, shifted down) so it reads as floating.
local function nightShadow(root, pill)
	local shadow = Kit.ensureChild(root, "Frame", "SpShadow")
	shadow.AnchorPoint = pill.AnchorPoint
	shadow.Position = pill.Position + UDim2.fromScale(0, NIGHT.shadowOffset)
	shadow.Size = pill.Size
	shadow.BackgroundColor3 = C.black
	shadow.BackgroundTransparency = NIGHT.shadowTransparency
	shadow.BorderSizePixel = 0
	shadow.Rotation = 0
	shadow.ZIndex = pill.ZIndex - 1
	shadow.Active = false
	Kit.setCorner(shadow, NIGHT.corner)
	return shadow
end

-- Glow behind the moon/sun: stacked translucent discs (no image asset needed) centred on the icon, round whatever the
-- holder's aspect (SizeConstraint RelativeYY). The icon itself is drawn above them.
local function nightGlow(holder, icon)
	local center = if icon and icon:IsA("GuiObject") then icon.Position else UDim2.fromScale(0.5, 0.5)
	for i, g in ipairs(NIGHT.glow) do
		local disc = Kit.ensureChild(holder, "Frame", "SpGlow" .. i)
		disc.AnchorPoint = Vector2.new(0.5, 0.5)
		disc.Position = center
		disc.Size = UDim2.fromScale(g[1], g[1])
		disc.SizeConstraint = Enum.SizeConstraint.RelativeYY
		disc.BackgroundColor3 = NIGHT.glowColor
		disc.BackgroundTransparency = g[2]
		disc.BorderSizePixel = 0
		disc.Rotation = 0
		disc.ZIndex = 1
		disc.Active = false
		Kit.setCorner(disc, 0.5)
	end
	if icon and icon:IsA("GuiObject") then
		icon.ZIndex = math.max(icon.ZIndex, 2)
	end
end

-- The timer label: fixed box inside the row (TextScaled shrinks long times instead of overflowing the pill), heavy
-- italic type, thick ink outline, a light moonlit gradient that multiplies the scripted TextColor3.
local function nightText(label, size)
	place(label, size, label.Position, label.AnchorPoint)
	label.AutomaticSize = Enum.AutomaticSize.None
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextWrapped = true -- (TextScaled + TextWrapped = false renders at the tiny fixed TextSize)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	zeroPadding(label)
	Kit.styleText(label, "number", {
		scriptOwned = { TextColor3 = true }, strokeThickness = NIGHT.textStroke,
		gradient = NIGHT.textGradient, gradientRotation = 90,
	})
	label.FontFace = FONT_STYLISED
	for _, c in ipairs(label:GetChildren()) do
		if c:IsA("UIStroke") then
			clearOldp(c)
		end
	end
end

local function skinNightTimer(root, geometry, pillSize)
	local pill = child(root, "Background")
	if not (pill and pill:IsA("GuiObject")) then
		warn("GameResetTimer.%s.Background missing", root.Name)
		return false
	end
	nightPill(pill, pillSize)
	nightShadow(root, pill)
	local main = child(root, "Main")
	if not main then
		warn("GameResetTimer.%s.Main missing", root.Name)
		return false
	end
	place(main, geometry.main, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	local list = main:FindFirstChildOfClass("UIListLayout")
	if list then
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = NIGHT.listPadding
	end
	local holder = child(main, "Frame")
	if holder and holder:IsA("GuiObject") then
		holder.Size = geometry.icon
		holder.LayoutOrder = 0
		nightGlow(holder, child(holder, "ImageLabel"))
	end
	local label = child(main, "TextLabel")
	if label and Kit.isText(label) then
		label.LayoutOrder = 2
		nightText(label, geometry.text)
	end
	return true
end

local function applyNightTimer(sg)
	local timer = child(sg, "GameResetTimer")
	if not timer then
		warn("StarterGui.GameResetTimer missing")
		return
	end
	local done = {}
	local timeLeft = child(timer, "TimeLeft")
	if timeLeft and timeLeft:IsA("GuiObject") then
		-- bottom-right floating pill; Position/AnchorPoint stay authored (the script moves X on mobile)
		timeLeft.Size = NIGHT.timeLeft.size
		aspect(timeLeft, NIGHT.timeLeft.aspect)
		if skinNightTimer(timeLeft, NIGHT.timeLeft, UDim2.fromScale(1, 1)) then
			table.insert(done, "TimeLeft")
		end
	end
	local endingSoon = child(timer, "EndingSoon")
	if endingSoon and endingSoon:IsA("GuiObject") then
		-- the top-centre warning banner keeps its box; the pill hugs the centred icon + time
		if skinNightTimer(endingSoon, NIGHT.endingSoon, NIGHT.endingSoon.pill) then
			table.insert(done, "EndingSoon")
		end
	end
	note("Night timer: %s", table.concat(done, ", "))
end

local function applyMisc(sg)
	local done = {}

	-- SpeedGainAnimation popups (cloned + faded by GUIFX.SpeedGainAnimation: TextTransparency, ImageTransparency and
	-- UIStroke.Transparency of every descendant; Text written)
	local gain = child(sg, "SpeedGainAnimation")
	if gain then
		for _, name in ipairs({ "Frame", "X2Gain" }) do
			local frame = child(gain, name)
			if frame then
				local label = child(frame, "CurrentBoost")
				if label and Kit.isText(label) then
					if name == "Frame" then
						Kit.styleText(label, "body", { color = C.accentCyan, strokeThickness = 0.08 })
					else
						Kit.styleText(label, "body", { keepColor = true, strokeThickness = 0.08 })
					end
					label.TextStrokeTransparency = 1
				end
				local icon = child(frame, "ImageLabel")
				if icon and isImage(icon) then
					Kit.setImage(icon, Kit.Icons.speed)
					icon.ScaleType = Enum.ScaleType.Fit
					aspect(icon, 1)
				end
			end
		end
		table.insert(done, "SpeedGainAnimation")
	end

	-- TreadmillClickX2 (dormant): Ability-orange sidebar square with the speed icon
	local x2 = child(sg, "TreadmillClickX2")
	local x2Button = x2 and Kit.findPath(x2, "Frame.Button")
	if x2Button and x2Button:IsA("ImageButton") then
		local label = child(x2Button, "CurrentBoost")
		Kit.skinSidebarButton(x2Button, "Ability", false, { target = x2Button, label = label })
		x2Button.BorderSizePixel = 0
		local inner = child(x2Button, "ImageLabel")
		if inner and isImage(inner) then
			Kit.setImage(inner, Kit.Icons.speed)
			inner.ScaleType = Enum.ScaleType.Fit
		end
		table.insert(done, "TreadmillClickX2")
	end

	-- ShiftLockButton: Image (lock on/off) and Visible are written by ShiftGUI -> colour + strokes only
	local shift = child(sg, "ShiftLockButton")
	local shiftButton = shift and child(shift, "ImageButton")
	if shiftButton and shiftButton:IsA("ImageButton") then
		paintSquare(shiftButton, Kit.Sidebar.Index, { keepImage = true, corner = 0.25 })
		table.insert(done, "ShiftLockButton")
	end

	-- RunButton (dormant, Enabled=false): Speedsters touch action button (hud.mobile_sprint)
	local run = child(sg, "RunButton")
	local runButton = run and child(run, "Button")
	if runButton and runButton:IsA("ImageButton") then
		runButton.ImageTransparency = 1
		runButton.PressedImageContent = Content.none
		runButton.BackgroundColor3 = hex("#03c8ff")
		runButton.BackgroundTransparency = 0
		runButton.BorderSizePixel = 0
		for _, c in ipairs(runButton:GetChildren()) do
			if c:IsA("UIGradient") then
				c.Enabled = false
			end
		end
		Kit.setCorner(runButton, 0.5)
		Kit.hideLegacyStrokes(runButton)
		Kit.addStroke(runButton, { name = Kit.Names.stroke, thickness = 2.5, sizing = "FixedSize", color = C.ink })
		local label = child(runButton, "TextLabel")
		if label and Kit.isText(label) then
			Kit.styleText(label, "button", { strokeThickness = 0.08 })
		end
		table.insert(done, "RunButton")
	end
	note("Misc HUD: %s", table.concat(done, ", "))
end

-- Backpack hotbar / inventory slots (sah_structure C8): clones of Main.HotbarTemplate / Main.InventoryTemplate,
-- coloured at runtime from Main's attributes (BackgroundColor, DraggableColor, SlotLockedTransparency, BorderColor,
-- EquippedColor, CornerRadius, SlotFont, LabelFont, ToolTipFont...). The slot's own BackgroundColor3,
-- BackgroundTransparency, UIStroke.Thickness/Color, Size and ZIndex are script-owned, so the Speedsters square base
-- is a tint layer (SpSkin 77444378011596 over the scripted colour, like Mainhud.ActiveBuffsHolder cards) and the
-- colours come from the attributes.
local BACKPACK_ATTRIBUTES = {
	BackgroundColor = Kit.Sidebar.Backpack.color, -- #ff580a, Speedsters Backpack / buff-card square
	DraggableColor = Kit.Sidebar.Ability.color, -- #ffaa00
	EquippedColor = C.accentCyan, -- equipped outline, reads on the orange square
	BorderColor = C.ink,
	DefaultStrokeColor = C.ink,
	SlotLockedTransparency = 0,
	CornerRadius = Sz.sidebarButton.corner,
	SearchBoxColor = hex("#003658"), -- Speedsters codes TextBox
	SearchBoxTransparency = 0.2,
	SlotFont = Kit.Fonts.body,
	LabelFont = Kit.Fonts.body,
	ToolTipFont = Kit.Fonts.body,
}

local function skinSlotTemplate(template)
	Kit.setCorner(template, Sz.sidebarButton.corner)
	local skin = Kit.ensureChild(template, "ImageLabel", Kit.Names.skin)
	Kit.setImage(skin, Kit.Images.sidebarBase)
	skin.ImageColor3 = C.white
	skin.ImageTransparency = 0
	skin.BackgroundTransparency = 1
	skin.ScaleType = Enum.ScaleType.Stretch
	skin.AnchorPoint = Vector2.new(0.5, 0.5)
	skin.Position = UDim2.fromScale(0.5, 0.5)
	skin.Size = UDim2.fromScale(1, 1)
	skin.BorderSizePixel = 0
	skin.Active = false
	local minZ = nil
	for _, c in ipairs(template:GetChildren()) do
		if c ~= skin and c:IsA("GuiObject") then
			minZ = if minZ then math.min(minZ, c.ZIndex) else c.ZIndex
		end
	end
	skin.ZIndex = (minZ or 2) - 1
	Kit.setCorner(skin, Sz.sidebarButton.corner)
	familyStrokes(skin, Kit.Sidebar.Backpack)

	local number = child(template, "Number")
	if number and Kit.isText(number) then
		counterText(number, { color = C.white })
	end
	for _, name in ipairs({ "ToolName", "Weight" }) do
		local t = child(template, name)
		if t and Kit.isText(t) then
			Kit.styleText(t, "row", { keepColor = true, strokeThickness = 0.08 })
			for _, c in ipairs(t:GetChildren()) do
				if c:IsA("UIStroke") then
					clearOldp(c)
				end
			end
		end
	end
	local base = child(template, "BaseTemplate")
	local amount = base and child(base, "Amount")
	if amount and Kit.isText(amount) then
		counterText(amount, { keepColor = true })
	end
	local tip = child(template, "ToolTip")
	if tip and Kit.isText(tip) then
		Kit.setFont(tip, "body")
		tip.BackgroundColor3 = C.ink
		tip.BackgroundTransparency = 0.1
		Kit.setCorner(tip, 0.2)
	end
	local strokeFrame = child(template, "StrokeFrame")
	if strokeFrame then
		Kit.setCorner(strokeFrame, Sz.sidebarButton.corner)
	end
	-- the slot's own ButtonUIScale (ButtonFX) and UIStroke (BorderColor, Thickness 0) are left to the script
end

local function applyBackpack(place)
	local main = Kit.findPath(place, "StarterPlayer.StarterPlayerScripts.GUI.BackpackController.Main")
	if not main then
		warn("StarterPlayerScripts.GUI.BackpackController.Main missing")
		return
	end
	local done = {}
	for _, name in ipairs({ "HotbarTemplate", "InventoryTemplate" }) do
		local t = child(main, name)
		if t and t:IsA("GuiButton") then
			skinSlotTemplate(t)
			table.insert(done, name)
		else
			warn("BackpackController.Main.%s missing", name)
		end
	end
	local attrs = {}
	for key, value in pairs(BACKPACK_ATTRIBUTES) do
		local current = main:GetAttribute(key)
		if current ~= nil and typeof(current) ~= typeof(value) then
			warn("BackpackController.Main attribute %s is a %s, not %s: left alone", key, typeof(current), typeof(value))
		else
			main:SetAttribute(key, value)
			table.insert(attrs, key)
		end
	end
	table.sort(attrs)
	note("Backpack: %s; attributes %s", table.concat(done, ", "), table.concat(attrs, ", "))
end

---------------------------------------------------------------------------------------------------
-- Entry point
---------------------------------------------------------------------------------------------------

function HUD.Apply(place, spPlace, ctx)
	table.clear(notes)
	table.clear(warnings)
	local sg = place:GetService("StarterGui")
	local rs = place:GetService("ReplicatedStorage")
	local sections = {
		{ "left", function() applyLeft(sg) end },
		{ "right", function() applyRight(sg) end },
		{ "rightFrame", function() applyRightFrame(sg) end },
		{ "tabs", function() applyTabs(sg) end },
		{ "money", function() applyMoney(sg) end },
		{ "hud", function() applyHud(sg) end },
		{ "notifications", function() applyNotifications(sg, rs) end },
		{ "misc", function() applyMisc(sg) end },
		{ "nightTimer", function() applyNightTimer(sg) end },
		{ "backpack", function() applyBackpack(place) end },
	}
	local failed = {}
	for _, section in ipairs(sections) do
		local ok, err = pcall(section[2])
		if not ok then
			table.insert(failed, section[1] .. ": " .. tostring(err))
		end
	end
	for _, line in ipairs(notes) do
		print("[UI-HUD] " .. line)
	end
	for _, line in ipairs(warnings) do
		print("[UI-HUD] warning: " .. line)
	end
	if #failed > 0 then
		error("[UI-HUD] section(s) failed:\n  " .. table.concat(failed, "\n  "))
	end
	print(string.format("[UI-HUD] Speedsters HUD applied (%d notes, %d warnings).", #notes, #warnings))
end

return HUD
