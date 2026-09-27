-- scripts/lib/speedsters_ui_kit.luau
-- Speedsters Escape UI material library + Lune build helpers for the Steal a Hero UI port (Phase 3, owner KIT).
--
-- REQUIRE (Lune resolves require paths relative to the requiring FILE; verified with lune 0.10.5):
--   from a UI step (scripts/steps/ui_*.luau):  local Kit = require("../lib/speedsters_ui_kit")
--   from scripts/*.luau:                       local Kit = require("./lib/speedsters_ui_kit")
-- Lune caches the module, so every requirer gets the SAME table: the kit keeps no per-build state.
--
-- VALUES come from scratchpad uiport/materials.json, which was read from Update2/World1Update3New.rbxl. The rules
-- come from CONTRACTS_PHASE3 D1-D3.
--   D1: windows are white @0.15 + Background art, scale corners, hairline ScaledSize #0b1b3d stroke. Titles use
--       GothamSSm Bold; buttons, tabs, rows and prices use FredokaOne.
--   D3: never use the SPEEDSTER ESCAPE logo 92044769924002. setImage refuses it and cloneExemplar blanks it.
--
-- PERSISTENCE (Lune 0.10.5). Helpers only write properties that survive serializePlace:
--   * images:  ImageContent = Content.fromUri(...). `.Image` is never written.
--   * fonts:   FontFace. `.Font` is never written.
--   * corners: the four per-corner radii. CornerRadius is lost on save, even on a new UICorner, and reads error.
--   * strokes: StrokeSizingMode, BorderOffset, BorderStrokePosition, LineJoinMode and ZIndex persist.
--
-- IDEMPOTENT. Each layer a helper adds has an `Sp` + Capital name (SpBackground, SpSkin, SpStroke, SpFill,
-- SpTextStroke, SpShine, SpIcon, SpCloseArt, SpHeaderIcon...). A second run finds that layer and reconfigures it
-- instead of adding a new one.
--
-- D2 GUARD RAILS (all helpers):
--   * never rename, reclass, Destroy or set Visible=false on an instance they did not create;
--   * hide legacy decoration with transparency only;
--   * never add a UIScale;
--   * leave a property alone when the caller declares it script-owned:
--       opts.scriptOwned = { BackgroundColor3 = true, ImageColor3 = true, Image = true, UIGradient = true,
--                            TextColor3 = true, BackgroundTransparency = true };
--   * never add a GuiObject layer to an instance that holds a UIListLayout / UIGridLayout / UIPageLayout /
--     UITableLayout. The layout would position the layer; the helper falls back to direct properties.
--
-- API (details at each function):
--   Constants:    Kit.Colors, Kit.Gradients, Kit.Images, Kit.Icons, Kit.Fonts, Kit.TextKinds,
--                 Kit.ButtonFamilies, Kit.Sidebar, Kit.Sizes, Kit.Anim, Kit.Names, Kit.FORBIDDEN_IMAGE_IDS
--   Values:       Kit.hex, Kit.seq, Kit.numberSeq, Kit.uri, Kit.imageId, Kit.udim
--   Tree:         Kit.findChild, Kit.findPath, Kit.ensureChild, Kit.hasLayout, Kit.isText
--   Writers:      Kit.setImage, Kit.setFont, Kit.setCorner, Kit.addStroke, Kit.addGradient,
--                 Kit.hideDecoration, Kit.hideLegacyStrokes
--   Recipes:      Kit.styleText, Kit.skinWindow, Kit.skinTitle, Kit.skinCloseButton, Kit.addHeaderIcon,
--                 Kit.skinButton, Kit.skinSidebarButton, Kit.addShine, Kit.skinBar
--   Speedsters:   Kit.cloneExemplar, Kit.guardConsoleContracts

local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Color3 = roblox.Color3
local ColorSequence = roblox.ColorSequence
local ColorSequenceKeypoint = roblox.ColorSequenceKeypoint
local NumberSequence = roblox.NumberSequence
local NumberSequenceKeypoint = roblox.NumberSequenceKeypoint
local UDim = roblox.UDim
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2
local Enum = roblox.Enum
local Content = roblox.Content
local Font = roblox.Font

local Kit = {}
Kit.VERSION = 1

---------------------------------------------------------------------------------------------------
-- Value helpers
---------------------------------------------------------------------------------------------------

-- "#rrggbb" (or a Color3) -> Color3
local function hex(value)
	if typeof(value) == "Color3" then
		return value
	end
	local digits = string.gsub(tostring(value), "#", "")
	assert(#digits == 6 and string.match(digits, "^%x+$"), "Kit.hex: expected #rrggbb, got " .. tostring(value))
	return Color3.fromRGB(
		tonumber(string.sub(digits, 1, 2), 16),
		tonumber(string.sub(digits, 3, 4), 16),
		tonumber(string.sub(digits, 5, 6), 16)
	)
end
Kit.hex = hex

-- A ColorSequence from a ColorSequence, a single colour, or stops { {t, "#hex"}, ... } / { {t = , c = }, ... }.
local function seq(stops)
	local kind = typeof(stops)
	if kind == "ColorSequence" then
		return stops
	end
	if kind == "Color3" or kind == "string" then
		local c = hex(stops)
		return ColorSequence.new({ ColorSequenceKeypoint.new(0, c), ColorSequenceKeypoint.new(1, c) })
	end
	assert(type(stops) == "table" and #stops >= 1, "Kit.seq: expected a ColorSequence, a colour or a stop list")
	local keypoints = {}
	for _, stop in ipairs(stops) do
		table.insert(keypoints, ColorSequenceKeypoint.new(stop.t or stop[1], hex(stop.c or stop[2])))
	end
	if #keypoints == 1 then
		table.insert(keypoints, ColorSequenceKeypoint.new(1, keypoints[1].Value))
	end
	return ColorSequence.new(keypoints)
end
Kit.seq = seq

-- A NumberSequence from a NumberSequence, a number, or stops { {t, v}, ... }.
local function numberSeq(stops)
	local kind = typeof(stops)
	if kind == "NumberSequence" then
		return stops
	end
	if type(stops) == "number" then
		return NumberSequence.new({ NumberSequenceKeypoint.new(0, stops), NumberSequenceKeypoint.new(1, stops) })
	end
	local keypoints = {}
	for _, stop in ipairs(stops) do
		table.insert(keypoints, NumberSequenceKeypoint.new(stop.t or stop[1], stop.v or stop[2]))
	end
	return NumberSequence.new(keypoints)
end
Kit.numberSeq = numberSeq

-- A number is a scale radius/offset ratio: 0.05 -> UDim(0.05, 0). UDims pass through; { s = , o = } works too.
local function udim(value)
	if typeof(value) == "UDim" then
		return value
	end
	if type(value) == "number" then
		return UDim.new(value, 0)
	end
	if type(value) == "table" then
		return UDim.new(value.s or value.Scale or value[1] or 0, value.o or value.Offset or value[2] or 0)
	end
	error("Kit.udim: expected a number, a UDim or { s, o }, got " .. tostring(value))
end
Kit.udim = udim

local function enumOf(enumType, value)
	if typeof(value) == "EnumItem" then
		return value
	end
	return (enumType :: any)[value]
end

-- Asset id (number / digit string / full uri) -> uri string, or nil for "no image".
local function uri(id)
	if id == nil or id == 0 or id == "" or id == false then
		return nil
	end
	if type(id) == "number" then
		return "rbxassetid://" .. string.format("%d", id)
	end
	local s = tostring(id)
	if string.match(s, "^%d+$") then
		return "rbxassetid://" .. s
	end
	return s
end
Kit.uri = uri

local function assetDigits(u)
	if u == nil then
		return nil
	end
	return string.match(u, "^rbxassetid://(%d+)$") or string.match(u, "[?&]id=(%d+)") or string.match(u, "^(%d+)$")
end

-- Safe property read (unknown or unset properties read as nil instead of erroring).
local function prop(inst, name)
	local ok, value = pcall(function()
		return (inst :: any)[name]
	end)
	if ok then
		return value
	end
	return nil
end
Kit.prop = prop

-- The asset id (digits) an ImageLabel/ImageButton draws, or nil.
function Kit.imageId(inst)
	local content = prop(inst, "ImageContent")
	local u = content and prop(content, "Uri")
	return assetDigits(u)
end

---------------------------------------------------------------------------------------------------
-- Material constants (materials.json)
---------------------------------------------------------------------------------------------------

Kit.Colors = {
	ink = hex("#0b1b3d"), -- authored text/border ink (D1). GamePanelStyle's code ink #0b1b2d is NOT used.
	white = hex("#ffffff"),
	black = hex("#000000"),
	windowFill = hex("#ffffff"), -- @ Kit.Sizes.window.fillTransparency
	dim = hex("#000000"), -- @ 0.55
	accentCyan = hex("#00fff7"),
	accentGold = hex("#ffcc00"),
	accentGreen = hex("#88ff00"),
	warningRed = hex("#ff4548"),
	warningPink = hex("#ff194f"),
	buyLabelStroke = hex("#3d062e"),
	darkButtonStroke = hex("#430043"),
	levelFill = hex("#00eaff"),
	staminaFill = hex("#ffea00"),
	rowStrip = hex("#324e6f"), -- @ 0.4 + Kit.Gradients.rowStripTransparency
	badgeStroke = hex("#3d0607"),
	badgeLabelStroke = hex("#861416"),
	barHighlight = hex("#f2fdff"),
	sliderTrack = hex("#1e222e"),
	sliderFill = hex("#46d255"),
	toggleOn = hex("#84ff00"),
	toggleStroke = hex("#034c09"),
	timeGiftReady = hex("#9dff00"),
	timeGiftWaiting = hex("#ff0011"),
}

-- Stop lists (feed them to Kit.seq / Kit.addGradient). Rotation noted per entry.
Kit.Gradients = {
	price = { { 0, "#00ff08" }, { 1, "#cbff10" } }, -- rot 90, price text + Robux glyph
	multiplier = { { 0, "#ffd900" }, { 0.5335, "#ffe30e" }, { 1, "#ffcc00" } }, -- rot 270
	badge = { { 0, "#ff0e42" }, { 1, "#ff6b6d" } }, -- rot 90
	badgeBlue = { { 0, "#05bcff" }, { 1, "#03f2ff" } }, -- rot 90 (AFK badge)
	windowProgress = { { 0, "#01ff2b" }, { 0.2694, "#4aff1a" }, { 1, "#afff03" } }, -- rot 270
	codes = { { 0, "#00eaff" }, { 1, "#0088ff" } },
	potion = { { 0, "#ff4000" }, { 1, "#ffa220" } }, -- rot 270
	dailyDay = { { 0, "#02ffee" }, { 0.4577, "#00e3f8" }, { 1, "#20acb9" } },
	rowStripTransparency = { { 0, 0.5625 }, { 0.0453, 0.7188 }, { 0.3196, 0.575 }, { 0.6955, 0.7563 }, { 1, 1 } },
}

-- Image ids by role (backgrounds, bases, textures). Numbers; pass them to Kit.setImage.
Kit.Images = {
	windowArt = 106477372921851, -- BlockyBackground: the standard window art (D1)
	shopArt = 91870898439604,
	giftArt = 122921796667560,
	treadmillLockArt = 79974345669191,
	afkArt = 105291788173155,
	questArt = 108169324078907,
	codesArt = 99135647289179,
	close = 110882579806743,
	sidebarBase = 77444378011596, -- square menu button base, tinted by the button's BackgroundColor3
	actionPill = 135496826236732, -- Buy/Claim/Redeem/Rebirth/Evolve base, tinted by a UIGradient
	premiumPill = 116981003258590,
	pricePill = 118171558421884,
	squareButton = 113508505333448, -- Gift / Backpack tabs
	equipButton = 86704273357127,
	worldsButton = 133513554479085,
	timeGiftClaim = 122958477384059,
	giftPlayerPrice = 128107282290684,
	shine = 72314714453458, -- rays, rotated 45 deg/s on premium buttons
	hudBar = 119680268934075, -- HUD progress track + Crop fill
	windowBar = 127033942711974,
	stud = 6927295847, -- Tile texture
	passPattern = 125961309868308,
	passRightArt = 131618750425930,
	rowBackground = 90451917704726,
	stageRow = 104524451317398,
	dailyCard = 108669468337223,
	timeGiftCard = 133533008459753,
	indexCard = 130296238496581,
	indexPortraitFrame = 91304690104557,
	statPill = 88362369363649,
	arrow = 74885007861450,
	shopCategoryArt = 117088684729837,
	potionCard = 121965118922177,
	speedometer = 124021406267245,
}

-- Speedsters icon ids by meaning.
Kit.Icons = {
	shop = 96787567013749,
	index = 140189242202677,
	rebirth = 129578402198506,
	evolve = 92164600998462,
	evolveHeader = 116946301675584,
	teleport = 134300317257422,
	backpack = 139874655682754,
	timeGifts = 94279344773398,
	gift = 127191998618608, -- gift box header icon
	giftGlyph = 101338943117617,
	ability = 123961542220277, -- lightning bolt (on)
	boltOff = 106423900726418,
	settings = 77188882273275,
	daily = 114699417085635,
	codes = 138738878130228,
	codesHeader = 102193985057745,
	worlds = 120872694749486,
	afk = 91936490991168,
	afkStreak = 135011356419232,
	groupRewards = 75521963910910,
	treadmillLock = 121834855888887,
	close = 110882579806743,
	adminCrown = 10723374641,
	quests = 10734975692,
	questTask = 81485053065474,
	speed = 71111471194517, -- speed currency
	speedPassArt = 97058106405348,
	speedStat = 100073133960339,
	levelMax = 87652741759727,
	victory = 89981527304241,
	trophy = 107664846509614,
	robuxInBuyButton = 100368332193769,
	robuxInPill = 133198102339401,
	winsInPill = 117634545914295,
	robuxGlyph = 108805296006809, -- tint with Kit.Gradients.price
	speedometer = 124021406267245, -- WalkSpeedModeButton (the "shoe" of the speed card)
	trail = 78795694520145,
	aura = 91489463626893,
	vip = 125916107464931,
	shopExclusive = 113221127098716,
	shopTreadmills = 140429435591753,
	shopPotions = 75719417627899,
	shopPasses = 76936003828964,
	spinArrow = 18209578499,
	heart = "rbxthumb://type=Asset&id=12492678216&w=420&h=420",
}

-- D3: never shown as Steal a Hero branding.
Kit.FORBIDDEN_IMAGE_IDS = {
	["92044769924002"] = "SPEEDSTER ESCAPE game logo (CONTRACTS_PHASE3 D3)",
}

Kit.FontFamilies = {
	gotham = "rbxasset://fonts/families/GothamSSm.json",
	fredoka = "rbxasset://fonts/families/FredokaOne.json",
}

Kit.Fonts = {
	title = Font.new(Kit.FontFamilies.gotham, Enum.FontWeight.Bold), -- titles, subtitles, numbers, buy labels
	body = Font.fromEnum(Enum.Font.FredokaOne), -- buttons, tabs, rows, prices
	heavy = Font.new(Kit.FontFamilies.gotham, Enum.FontWeight.Heavy),
}

-- Text roles: font key, Contextual ScaledSize stroke thickness, stroke colour, TextColor3 (nil = keep).
Kit.TextKinds = {
	title = { font = "title", stroke = 0.05, color = Kit.Colors.white },
	subtitle = { font = "title", stroke = 0.07 },
	number = { font = "title", stroke = 0.05 },
	buy = { font = "title", stroke = 0.07, strokeColor = Kit.Colors.buyLabelStroke, color = Kit.Colors.white },
	heavy = { font = "heavy", stroke = 0.05 },
	button = { font = "body", stroke = 0.08, color = Kit.Colors.white },
	tab = { font = "body", stroke = 0.09, color = Kit.Colors.white },
	sidebar = { font = "body", stroke = 0.11, color = Kit.Colors.white },
	row = { font = "body", stroke = 0.06 },
	price = { font = "body", stroke = 0.06 },
	body = { font = "body", stroke = 0.06 },
	badge = { font = "body", stroke = 0.08, strokeColor = Kit.Colors.badgeLabelStroke, color = Kit.Colors.white },
}

-- Button families: white base image tinted by a vertical UIGradient (`fill`), a white Border stroke with its own
-- gradient (`light`) and a dark Border stroke (`dark`). Thickness/offset are ScaledSize fractions.
-- `solid` = the colour used when a gradient cannot be used (a TextButton that draws its own text).
local function family(spec)
	spec.fillRotation = spec.fillRotation or 90
	spec.bg = spec.bg or Kit.Colors.white
	spec.bgTransparency = spec.bgTransparency or 0
	spec.imageColor = spec.imageColor or Kit.Colors.white
	spec.labelStroke = spec.labelStroke or Kit.Colors.buyLabelStroke
	spec.light.rotation = spec.light.rotation or 90
	return spec
end

Kit.ButtonFamilies = {
	buy_green = family({
		source = "StarterGui.Shop.Shop.ScrollingFrame.Pass.2X Win.Buy",
		image = Kit.Images.actionPill, corner = 0.2, aspect = 2.8519, solid = hex("#36f800"),
		fill = { { 0, "#f2ff00" }, { 0.4877, "#36f800" }, { 1, "#0ea52c" } },
		light = { thickness = 0.06, offset = -0.1, zIndex = 1, gradient = { { 0, "#9fff89" }, { 0.7588, "#12f80e" }, { 1, "#0a510a" } } },
		dark = { color = hex("#430043"), thickness = 0.05, offset = -0.05, zIndex = 2 },
	}),
	equip_green = family({
		source = "StarterGui.Index.Index.ScrollingFrame.Template.EquippedTemplate",
		image = Kit.Images.equipButton, corner = 0.25, aspect = 4.1111, solid = hex("#36f800"),
		fill = { { 0, "#02ff41" }, { 0.4577, "#36f800" }, { 1, "#0ea52c" } },
		light = { thickness = 0.06, offset = -0.1, zIndex = 1, gradient = { { 0, "#9fff89" }, { 0.7588, "#12f80e" }, { 1, "#0a510a" } } },
		dark = { color = hex("#430043"), thickness = 0.05, offset = -0.05, zIndex = 2 },
	}),
	claim_green = family({
		source = "StarterGui.AfkRewardsGui.Earnings.Claim",
		image = Kit.Images.actionPill, corner = 0.25, aspect = 2.8, solid = hex("#4af800"),
		fill = { { 0, "#26ff00" }, { 0.4577, "#4af800" }, { 1, "#53a713" } },
		light = { thickness = 0.06, offset = -0.1, zIndex = 1, gradient = { { 0, "#a8ff80" }, { 0.6356, "#06f81a" }, { 1, "#1e5909" } } },
		dark = { color = hex("#104300"), thickness = 0.06, offset = -0.05, zIndex = 2 },
	}),
	equip_grey = family({
		source = "StarterGui.Index.Index.ScrollingFrame.UnequippedTemplate.Equip",
		image = Kit.Images.equipButton, corner = 0.25, aspect = 4.1111, solid = hex("#bebebe"), bg = hex("#bebebe"),
		fill = { { 0, "#ffffff" }, { 0.4577, "#f8f8f8" }, { 1, "#9c9697" } }, -- white-based: keeps a scripted tint readable
		light = { thickness = 0.06, offset = -0.1, zIndex = 1, gradient = { { 0, "#9fff89" }, { 0.7588, "#12f80e" }, { 1, "#0a510a" } } },
		dark = { color = hex("#430043"), thickness = 0.05, offset = -0.05, zIndex = 2 },
	}),
	magenta = family({
		source = "StarterGui.Rebirth.Rebirth.Rebirth#ImageButton",
		image = Kit.Images.actionPill, corner = 0.25, aspect = 2.8, solid = hex("#e405f8"),
		bgTransparency = 1, imageColor = hex("#ff29a9"),
		fill = { { 0, "#ff0687" }, { 0.4577, "#e405f8" }, { 1, "#9d12a7" } },
		light = { thickness = 0.06, offset = -0.1, zIndex = 1, gradient = { { 0, "#ff9cfa" }, { 0.6356, "#e405f8" }, { 1, "#540a59" } } },
		dark = { color = hex("#430043"), thickness = 0.05, offset = -0.05, zIndex = 2 },
	}),
	gold_magenta = family({
		source = "StarterGui.Rebirth.Rebirth.RebirthBuy",
		image = Kit.Images.actionPill, corner = 0.25, aspect = 2.8, solid = hex("#ffd500"), bgTransparency = 1,
		fill = { { 0, "#ffd500" }, { 0.9419, "#e405f8" }, { 1, "#9d12a7" } },
		light = { thickness = 0.06, offset = -0.1, zIndex = 1, gradient = { { 0, "#fdff78" }, { 0.7588, "#e552f8" }, { 1, "#f01dff" } } },
		dark = { color = hex("#000000"), thickness = 0.05, offset = -0.05, zIndex = 2 },
	}),
	cyan = family({
		source = "StarterGui.Shop.Shop.ScrollingFrame.CodesFrame.Reddem",
		image = Kit.Images.actionPill, corner = 0.2, aspect = 2.8519, solid = hex("#00f4f8"),
		fill = { { 0, "#00ffff" }, { 0.4877, "#00f4f8" }, { 1, "#00c7c7" } },
		light = { thickness = 0.06, offset = -0.1, zIndex = 1, gradient = { { 0, "#00ddff" }, { 0.7588, "#00f8db" }, { 1, "#00ffe1" } } },
		dark = { color = hex("#430043"), thickness = 0.05, offset = -0.05, zIndex = 2 },
	}),
	cyan_lock = family({
		source = "StarterGui.Treadmill.TimeGift.Reddem",
		image = Kit.Images.actionPill, corner = 0.25, aspect = 2.8173, solid = hex("#0be4f8"),
		fill = { { 0, "#08fff7" }, { 0.4577, "#0be4f8" }, { 1, "#129ba7" } },
		light = { thickness = 0.06, offset = -0.1, zIndex = 1, gradient = { { 0, "#93f4ff" }, { 0.6356, "#07f4f8" }, { 1, "#095956" } } },
		dark = { color = hex("#003535"), thickness = 0.05, offset = -0.05, zIndex = 2 },
	}),
	world_green = family({
		source = "StarterGui.Worlds.Worlds.ScrollingFrame.World1.Frame.Button",
		image = Kit.Images.worldsButton, corner = 0.25, aspect = 6.3802, solid = hex("#1ed22d"), labelStroke = hex("#000000"),
		fill = { { 0, "#84ff00" }, { 0.7799, "#1ed22d" }, { 1, "#38a55d" } },
		light = { thickness = 0.13, offset = -0.12, zIndex = 2, gradient = { { 0, "#7dff37" }, { 0.5088, "#7bff4b" }, { 1, "#00ff11" } } },
		dark = { color = hex("#000000"), thickness = 0.07, offset = -0.04, zIndex = 3 },
	}),
	world_gold = family({
		source = "StarterGui.Worlds.Worlds.ScrollingFrame.World2.Frame.Button",
		image = Kit.Images.worldsButton, corner = 0.25, aspect = 6.3802, solid = hex("#d2cb0e"), labelStroke = hex("#000000"),
		fill = { { 0, "#ffe203" }, { 0.7799, "#d2cb0e" }, { 1, "#a57413" } },
		light = { thickness = 0.13, offset = -0.12, zIndex = 2, gradient = { { 0, "#fbff03" }, { 0.5088, "#fff01d" }, { 1, "#ffbb34" } } },
		dark = { color = hex("#000000"), thickness = 0.07, offset = -0.04, zIndex = 3 },
	}),
	price_robux = family({
		source = "StarterGui.Backpack.MainFrame.Trail#ScrollingFrame.Frame.Frame.RobuxPurchase",
		image = Kit.Images.pricePill, corner = 0.25, aspect = 3.0152, solid = hex("#aa1cd2"), labelStroke = hex("#000000"),
		fill = { { 0, "#ee00ff" }, { 0.7799, "#aa1cd2" }, { 1, "#6638a5" } },
		light = { thickness = 0.13, offset = -0.12, zIndex = 3, gradient = { { 0, "#ff8cf9" }, { 0.5088, "#ff47f6" }, { 1, "#d900ff" } } },
		dark = { color = hex("#000000"), thickness = 0.07, offset = -0.04, zIndex = 4 },
	}),
	price_wins = family({
		source = "StarterGui.Backpack.MainFrame.Trail#ScrollingFrame.Frame.Frame.WinsPurchase",
		image = Kit.Images.pricePill, corner = 0.25, aspect = 3.0152, solid = hex("#1ed22d"), labelStroke = hex("#000000"),
		fill = { { 0, "#84ff00" }, { 0.7799, "#1ed22d" }, { 1, "#38a55d" } },
		light = { thickness = 0.13, offset = -0.12, zIndex = 2, gradient = { { 0, "#7dff37" }, { 0.5088, "#7bff4b" }, { 1, "#00ff11" } } },
		dark = { color = hex("#000000"), thickness = 0.07, offset = -0.04, zIndex = 3 },
	}),
	gift_square = family({
		source = "StarterGui.Shop.Shop.ScrollingFrame.Pass.2X Win.Gift",
		image = Kit.Images.squareButton, corner = 0.25, aspect = 0.988, solid = hex("#aa1cd2"), bgTransparency = 1,
		labelStroke = hex("#000000"),
		fill = { { 0, "#ee00ff" }, { 0.7799, "#aa1cd2" }, { 1, "#6638a5" } },
		light = { thickness = 0.13, offset = -0.12, zIndex = 3, gradient = { { 0, "#ff8cf9" }, { 0.5088, "#ff47f6" }, { 1, "#d900ff" } } },
		dark = { color = hex("#000000"), thickness = 0.06, offset = -0.04, zIndex = 4 },
	}),
	tab_magenta = family({
		source = "StarterGui.Backpack.MainFrame.Aura#ImageButton",
		image = Kit.Images.squareButton, corner = 0.25, aspect = 0.988, solid = hex("#aa1cd2"), labelStroke = hex("#000000"),
		fill = { { 0, "#ee00ff" }, { 0.7799, "#aa1cd2" }, { 1, "#6638a5" } },
		light = { thickness = 0.06, offset = -0.09, zIndex = 3, gradient = { { 0, "#ff8cf9" }, { 0.5088, "#ff47f6" }, { 1, "#d900ff" } } },
		dark = { color = hex("#000000"), thickness = 0.04, offset = -0.04, zIndex = 4 },
	}),
	tab_red = family({
		source = "StarterGui.Backpack.MainFrame.Trail#ImageButton",
		image = Kit.Images.squareButton, corner = 0.25, aspect = 0.988, solid = hex("#d21522"), labelStroke = hex("#000000"),
		fill = { { 0, "#ff0004" }, { 0.7799, "#d21522" }, { 1, "#a53163" } },
		light = { thickness = 0.06, offset = -0.09, zIndex = 3, gradient = { { 0, "#ffa1a3" }, { 0.5088, "#ff8688" }, { 1, "#ff272b" } } },
		dark = { color = hex("#000000"), thickness = 0.04, offset = -0.04, zIndex = 4 },
	}),
	premium_blue = family({
		source = "StarterGui.Mainhud.Rightbuttons.2xSpeed",
		image = Kit.Images.premiumPill, corner = 0.25, aspect = 3.0152, solid = hex("#1ea0ff"), labelStroke = Kit.Colors.ink,
		fill = { { 0, "#78ebff" }, { 0.55, "#1ea0ff" }, { 1, "#145cd6" } },
		light = { thickness = 0.05, offset = -0.1, zIndex = 2, rotation = 270, gradient = { { 0, "#96f0ff" }, { 0.5088, "#d7faff" }, { 1, "#5ac8ff" } } },
		dark = { color = Kit.Colors.ink, thickness = 0.06, offset = -0.04, zIndex = 3 },
	}),
	premium_gold = family({
		source = "StarterGui.Mainhud.Rightbuttons.2xVictory",
		image = Kit.Images.premiumPill, corner = 0.25, aspect = 3.0152, solid = hex("#ffbe00"), labelStroke = Kit.Colors.ink,
		fill = { { 0, "#ffe85a" }, { 0.5, "#ffbe00" }, { 1, "#de8000" } },
		light = { thickness = 0.05, offset = -0.1, zIndex = 2, rotation = 270, gradient = { { 0, "#ff893a" }, { 0.5088, "#ffea47" }, { 1, "#ffd500" } } },
		dark = { color = hex("#583312"), thickness = 0.06, offset = -0.04, zIndex = 3 },
	}),
	speed_buy_gold = family({
		source = "StarterGui.Mainhud.LevelProgressBar.Frame.Speedbuy.Buy1Speed",
		image = Kit.Images.premiumPill, corner = 0.25, aspect = 3.0152, solid = hex("#d2c31a"), labelStroke = Kit.Colors.ink,
		fill = { { 0, "#ff9500" }, { 0.7799, "#d2c31a" }, { 1, "#a57c35" } },
		light = { thickness = 0.13, offset = -0.12, zIndex = 2, gradient = { { 0, "#ffff35" }, { 0.5088, "#ffea47" }, { 1, "#f2ff00" } } },
		dark = { color = hex("#583312"), thickness = 0.06, offset = -0.04, zIndex = 3 },
	}),
	-- DERIVED (no authored red action pill): the Backpack Trail-tab red gradients on the action pill base, with the
	-- Shop sidebar's dark stroke. For "danger"/close-style actions.
	red = family({
		source = "derived: tabs.backpack Trail colours + hud.sidebar_button Shop dark stroke",
		image = Kit.Images.actionPill, corner = 0.2, aspect = 2.85, solid = hex("#d21522"),
		fill = { { 0, "#ff0004" }, { 0.7799, "#d21522" }, { 1, "#a53163" } },
		light = { thickness = 0.06, offset = -0.1, zIndex = 1, gradient = { { 0, "#ffa1a3" }, { 0.5088, "#ff8688" }, { 1, "#ff272b" } } },
		dark = { color = hex("#540b0c"), thickness = 0.05, offset = -0.05, zIndex = 2 },
	}),
}

-- Sidebar buttons (Mainhud.LeftSideBar): base image over a per-button BackgroundColor3, white Border stroke
-- 0.04 @ -0.06 z2 with a gradient + dark Border stroke 0.04 @ -0.02 z3, icon, FredokaOne label.
local function sidebar(color, icon, iconSize, iconPos, labelStroke, light, dark)
	return {
		color = hex(color), icon = icon,
		iconSize = UDim2.new(iconSize[1], 0, iconSize[2], 0),
		iconPosition = UDim2.new(iconPos[1], 0, iconPos[2], 0),
		labelStroke = labelStroke,
		light = { thickness = 0.04, offset = -0.06, zIndex = 2, rotation = 90, gradient = light },
		dark = { color = hex(dark), thickness = 0.04, offset = -0.02, zIndex = 3 },
	}
end
Kit.Sidebar = {
	Ability = sidebar("#ffaa00", Kit.Icons.ability, { 0.6358, 0.6358 }, { 0.5387, 0.4214 }, 0.08, { { 0, "#eaff00" }, { 0.1127, "#ffbb0e" }, { 1, "#f2ff00" } }, "#544725"),
	Shop = sidebar("#ff0037", Kit.Icons.shop, { 0.7163, 0.7163 }, { 0.5, 0.441 }, 0.08, { { 0, "#ff7779" }, { 0.1127, "#ff2226" }, { 1, "#ff6b6d" } }, "#540b0c"),
	Index = sidebar("#0ad2ff", Kit.Icons.index, { 0.7163, 0.7163 }, { 0.5445, 0.441 }, 0.08, { { 0, "#00fbff" }, { 0.1127, "#06ffff" }, { 1, "#58e9ff" } }, "#073d39"),
	Rebirth = sidebar("#ff0586", Kit.Icons.rebirth, { 0.6358, 0.6358 }, { 0.5, 0.4283 }, 0.11, { { 0, "#eb0bff" }, { 0.1127, "#ea05ff" }, { 1, "#ff52e8" } }, "#3b073d"),
	Evolve = sidebar("#10ff2c", Kit.Icons.evolve, { 0.6358, 0.6358 }, { 0.5, 0.4283 }, 0.11, { { 0, "#afff01" }, { 1, "#afff01" } }, "#0c3d04"),
	Teleport = sidebar("#dfff0e", Kit.Icons.teleport, { 0.6358, 0.6358 }, { 0.4905, 0.4444 }, 0.11, { { 0, "#ffd900" }, { 1, "#ffa006" } }, "#3d3804"),
	Backpack = sidebar("#ff580a", Kit.Icons.backpack, { 0.6358, 0.6358 }, { 0.5387, 0.4283 }, 0.11, { { 0, "#ffaf0e" }, { 0.1144, "#ffa811" }, { 1, "#ffa154" } }, "#3d2406"),
	TimeGifts = sidebar("#ff55ff", Kit.Icons.timeGifts, { 0.5875, 0.539 }, { 0.5146, 0.3049 }, 0.11, { { 0, "#ffaaff" }, { 1, "#ffaaff" } }, "#3d2406"),
}
Kit.Sidebar["Time Gifts"] = Kit.Sidebar.TimeGifts

-- Speedsters proportions (all scale-based; `aspect` = UIAspectRatioConstraint). D1: keep SAH container sizes and
-- positions (UX); use these for the decorations you add.
Kit.Sizes = {
	window = {
		size = UDim2.new(0.32, 0, 0.5861, 0), position = UDim2.new(0.5, 0, 0.48, 0), anchor = Vector2.new(0.5, 0.5),
		aspect = 1.2795, corner = UDim.new(0.05, 0), stroke = 0.007, fillTransparency = 0.15, artTransparency = 0.15,
	},
	title = { size = UDim2.new(1.0744, 0, 0.1367, 0), position = UDim2.new(0.5, 0, -0.0041, 0), anchor = Vector2.new(0.5, 0.5), aspect = 9.3683, stroke = 0.05 },
	titleCompact = { size = UDim2.new(0.6218, 0, 0.1435, 0), position = UDim2.new(0.5, 0, -0.0041, 0), anchor = Vector2.new(0.5, 0.5), aspect = 5.1644, stroke = 0.05 },
	subtitle = { size = UDim2.new(0.5148, 0, 0.0655, 0), position = UDim2.new(0.5, 0, 0.0884, 0), anchor = Vector2.new(0.5, 0.5), aspect = 9.3683, stroke = 0.07 },
	headerIcon = { size = UDim2.new(0.1617, 0, 0.1928, 0), position = UDim2.new(0.033, 0, 0.0063, 0), anchor = Vector2.new(0.5, 0.5), aspect = 1, zIndex = 2 },
	closeButton = { size = UDim2.new(0.1128, 0, 0.1344, 0), position = UDim2.new(0.9693, 0, 0.0165, 0), anchor = Vector2.new(0.5, 0.5), aspect = 1 },
	dim = { size = UDim2.new(2, 0, 2, 0), position = UDim2.new(0.5, 0, 0.5, 0), anchor = Vector2.new(0.5, 0.5), transparency = 0.55 },
	sidebar = {
		size = UDim2.new(0.1365, 0, 0.3287, 0), position = UDim2.new(0.0745, 0, 0.4458, 0), aspect = 0.738,
		cellSize = UDim2.new(0.6, 0, 0.35, 0), cellPadding = UDim2.new(0.05, 0, 0.03, 0),
	},
	sidebarButton = {
		size = UDim2.new(0.4742, 0, 0.35, 0), corner = UDim.new(0.2, 0), aspect = 1,
		iconSize = UDim2.new(0.7163, 0, 0.7163, 0), iconPosition = UDim2.new(0.5, 0, 0.441, 0),
		labelSize = UDim2.new(0.6778, 0, 0.4977, 0), labelPosition = UDim2.new(0.4975, 0, 0.7986, 0), labelAspect = 1.3618,
	},
	badge = { size = UDim2.new(0.4588, 0, 0.4588, 0), position = UDim2.new(0.9747, 0, 0.1397, 0), anchor = Vector2.new(0.5, 0.5), corner = UDim.new(0.9, 0) },
	premiumButton = {
		size = UDim2.new(0.8634, 0, 0.1887, 0), aspect = 3.0152, corner = UDim.new(0.25, 0),
		columnSize = UDim2.new(0.1674, 0, 0.4514, 0), columnPosition = UDim2.new(0.9115, 0, 0.5313, 0), columnAspect = 0.659,
		columnPadding = UDim.new(0.12, 0),
	},
	shine = { heightScale = 2.0326, position = UDim2.new(0.4993, 0, 0.4511, 0), transparency = 0.69, zIndex = -11 },
	levelBar = { size = UDim2.new(0.4939, 0, 0.0638, 0), position = UDim2.new(0.5, 0, 0.775, 0), aspect = 13.7439, corner = UDim.new(0.15, 0), innerCorner = UDim.new(0.18, 0), stroke = 0.067 },
	staminaBar = { size = UDim2.new(0.4084, 0, 0.089, 0), position = UDim2.new(0.5, 0, 0.8571, 0), aspect = 13.7439 },
	actionButton = { aspect = 2.85, corner = UDim.new(0.2, 0) },
	pricePill = { aspect = 3.0152, corner = UDim.new(0.25, 0) },
	row = { aspect = 3.6917, corner = UDim.new(0.25, 0), listPadding = UDim.new(0.02, 0) },
}

-- Animation catalogue (materials.json `animations`), as plain numbers for owners writing Roblox-side code.
-- TweenInfo args: { time, EasingStyle, EasingDirection, repeatCount?, reverses?, delay? }.
Kit.Anim = {
	windowClosedPosition = UDim2.new(0.5, 0, 1.28, 0),
	windowOpenPosition = UDim2.new(0.5, 0, 0.48, 0),
	windowOpen = { 0.24, "Back", "Out" },
	windowClose = { 0.18, "Quad", "In" },
	dimIn = { 0.20, "Sine", "Out", target = 0.55 },
	dimOut = { 0.18, "Sine", "In" },
	modalPopIn = { 0.26, "Back", "Out", from = 0.88 },
	modalPopOut = { 0.18, "Quad", "In", to = 0.88 },
	closeHover = { 0.18, "Back", "Out", scale = 1.15, rotation = -8 },
	closeLeave = { 0.15, "Quad", "Out" },
	closePress = { 0.08, "Quad", "Out", scale = 0.88, rotation = -4 },
	iconHoverIn = { 0.20, "Back", "Out", scale = 1.18, rotation = 3 },
	iconHoverOut = { 0.16, "Quad", "Out" },
	attentionBounce = {
		{ 0.14, "Back", "Out", scale = 1.22, rotation = 5 },
		{ 0.10, "Back", "Out", scale = 1.1834, rotation = -5 },
		{ 0.22, "Quad", "Out", scale = 1, rotation = 0 },
		shopEvery = 6, premiumEvery = 7,
	},
	headerBounce = { every = { 4.5, 7.0 }, { 0.14, "Back", "Out", scale = 1.22, rotation = 6 }, { 0.10, "Back", "Out", scale = 1.16, rotation = -6 }, { 0.22, "Quad", "Out", scale = 1, rotation = 0 } },
	badgeShake = { 0.12, "Linear", "InOut", -1, true, px = 5 },
	shineDegreesPerSecond = 45,
	valuePulse = { { 0.07, "Back", "Out", scale = 1.18 }, { 0.12, "Quad", "Out", scale = 1 } },
	progressFill = { 0.18, "Quad", "Out" },
}

-- Names of the layers the kit creates (idempotency keys; find them with FindFirstChild).
Kit.Names = {
	background = "SpBackground", -- window art ImageLabel (skinWindow)
	stroke = "SpStroke", -- window hairline / generic stroke
	strokeLight = "SpStrokeLight", -- white gradient Border stroke (buttons)
	strokeDark = "SpStrokeDark", -- dark Border stroke (buttons)
	textStroke = "SpTextStroke", -- Contextual text outline (only when no existing Contextual stroke could be reused)
	fill = "SpFill", -- family UIGradient
	skin = "SpSkin", -- child ImageLabel layer (skinButton/skinSidebarButton layer & tint modes)
	shine = "SpShine", -- rays ImageLabel (addShine); runtime juice rotates it 45 deg/s
	icon = "SpIcon",
	headerIcon = "SpHeaderIcon",
	closeArt = "SpCloseArt", -- close art for Close buttons without a TextButton ImageLabel glyph
	barTrack = "SpBarTrack",
	barFill = "SpBarFill",
	aspect = "SpAspect",
	gradient = "SpGradient",
	textGradient = "SpTextGradient",
}

-- Legacy SAH decoration names that windows/buttons may hide (transparency only).
Kit.DECOR_NAMES = { InletTexture = true, BevelEffect = true, DropShadow = true, Pattern = true, shadow = true }

---------------------------------------------------------------------------------------------------
-- Tree helpers
---------------------------------------------------------------------------------------------------

local function isText(inst)
	return inst ~= nil and (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox"))
end
Kit.isText = isText

local function isImage(inst)
	return inst ~= nil and (inst:IsA("ImageLabel") or inst:IsA("ImageButton"))
end

local function isKitName(name)
	return string.match(name, "^Sp%u") ~= nil
end
Kit.isKitName = isKitName

-- First child with that Name (and ClassName / IsA class when given).
function Kit.findChild(parent, name, className)
	if parent == nil then
		return nil
	end
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == name and (className == nil or child:IsA(className)) then
			return child
		end
	end
	return nil
end

-- The child named `name` of class `className` (exact ClassName), created (and parented) when missing.
local function ensureChild(parent, className, name)
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == name and child.ClassName == className then
			return child, false
		end
	end
	local child = Instance.new(className)
	child.Name = name
	child.Parent = parent
	return child, true
end
Kit.ensureChild = ensureChild

-- "Name#Class" -> name, class
local function parseSegment(segment)
	local name, className = string.match(segment, "^(.*)#(%u%a+)$")
	if name and name ~= "" then
		return name, className
	end
	return segment, nil
end

-- Resolves "A.B.C" (materials.json sourcePath style, `Name#Class` disambiguates same-named siblings) or a
-- segment array under `root`. When `root` is a DataModel, the first segment names a service.
function Kit.findPath(root, path)
	local segments = path
	if type(path) == "string" then
		segments = string.split(path, ".")
	end
	local node = root
	for i, segment in ipairs(segments) do
		if node == nil then
			return nil
		end
		local name, className = parseSegment(segment)
		local nextNode = nil
		if i == 1 and node.ClassName == "DataModel" then
			local ok, service = pcall(function()
				return node:GetService(name)
			end)
			nextNode = ok and service or nil
		end
		if nextNode == nil then
			for _, child in ipairs(node:GetChildren()) do
				if child.Name == name and (className == nil or child.ClassName == className) then
					nextNode = child
					break
				end
			end
		end
		node = nextNode
	end
	return node
end

local LAYOUT_CLASSES = { "UIListLayout", "UIGridLayout", "UIPageLayout", "UITableLayout" }
-- True when `inst` holds a layout object (a GuiObject layer added there would be laid out as an item).
function Kit.hasLayout(inst)
	for _, className in ipairs(LAYOUT_CLASSES) do
		if inst:FindFirstChildOfClass(className) then
			return true
		end
	end
	return false
end

local function ownedSet(opts)
	return (opts and opts.scriptOwned) or {}
end

-- ZIndex for a background layer added under `parent`: below every other GuiObject child in Sibling mode; equal to
-- the parent's ZIndex in Global mode (a lower value would render beneath the parent itself).
local function layerZ(parent, layer)
	local collector = parent:FindFirstAncestorWhichIsA("LayerCollector")
	local behavior = collector and prop(collector, "ZIndexBehavior")
	if behavior == Enum.ZIndexBehavior.Global and parent:IsA("GuiObject") then
		return parent.ZIndex
	end
	local minZ = nil
	for _, child in ipairs(parent:GetChildren()) do
		if child ~= layer and child:IsA("GuiObject") and not isKitName(child.Name) then
			minZ = if minZ then math.min(minZ, child.ZIndex) else child.ZIndex
		end
	end
	return if minZ then minZ - 1 else 1
end

local function fullSize(inst)
	return inst.Size.X.Scale >= 0.98 and inst.Size.Y.Scale >= 0.98
end

---------------------------------------------------------------------------------------------------
-- Writers
---------------------------------------------------------------------------------------------------

-- ImageContent write (persists in Lune; `.Image` does not). `id`: number, digit string, uri, or nil/0 = no image.
-- Refuses the SPEEDSTER ESCAPE logo (D3).
function Kit.setImage(inst, id)
	assert(isImage(inst), "Kit.setImage: expected an ImageLabel/ImageButton, got " .. (inst and inst.ClassName or "nil"))
	local u = uri(id)
	if u == nil then
		inst.ImageContent = Content.none
		return inst
	end
	local digits = assetDigits(u)
	if digits and Kit.FORBIDDEN_IMAGE_IDS[digits] then
		error(string.format("Kit.setImage: %s on %s is the %s", digits, inst:GetFullName(), Kit.FORBIDDEN_IMAGE_IDS[digits]))
	end
	inst.ImageContent = Content.fromUri(u)
	return inst
end

-- FontFace write (`.Font` is lost on save). kind: a Kit.TextKinds key, 'title' | 'body' | 'heavy', or a Font.
function Kit.setFont(label, kind)
	assert(isText(label), "Kit.setFont: expected a text object, got " .. (label and label.ClassName or "nil"))
	local font = kind
	if typeof(kind) ~= "Font" then
		local textKind = Kit.TextKinds[kind or "body"]
		local key = if textKind then textKind.font else kind
		font = Kit.Fonts[key]
		assert(font, "Kit.setFont: unknown font kind " .. tostring(kind))
	end
	label.FontFace = font
	return label
end

-- Writes the four per-corner radii (CornerRadius is not persisted by Lune) on the first UICorner, creating one
-- when absent. radius: UDim or a scale number (0.05 -> UDim(0.05, 0)).
-- Owner 2026-09-27: "no more rounded UI, leave them square with a separation": with Kit.SQUARE_UI every corner the
-- kits and steps write is square (radius 0), whatever radius the caller asks for.
Kit.SQUARE_UI = true
function Kit.setCorner(inst, radius)
	local r = if Kit.SQUARE_UI then UDim.new(0, 0) else udim(radius)
	local corner = inst:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Name = "UICorner"
		corner.Parent = inst
	end
	corner.TopLeftRadius = r
	corner.TopRightRadius = r
	corner.BottomLeftRadius = r
	corner.BottomRightRadius = r
	return corner
end

-- UIGradient child `name` (default "SpGradient"), created or reconfigured. colors: ColorSequence, colour or stops.
-- opts.transparency: NumberSequence / number / stops. opts.offset: Vector2.
-- Returns the gradient and, as a 2nd value, a foreign enabled UIGradient on the same instance if any (Roblox
-- renders only one gradient per object, so the caller should resolve that conflict).
function Kit.addGradient(inst, colors, rotation, name, opts)
	opts = opts or {}
	local gradient = ensureChild(inst, "UIGradient", name or Kit.Names.gradient)
	gradient.Color = seq(colors)
	gradient.Rotation = rotation or 90
	gradient.Offset = opts.offset or Vector2.new(0, 0)
	gradient.Transparency = numberSeq(opts.transparency or 0)
	gradient.Enabled = true
	local foreign = nil
	for _, child in ipairs(inst:GetChildren()) do
		if child ~= gradient and child:IsA("UIGradient") and prop(child, "Enabled") ~= false then
			foreign = child
			break
		end
	end
	return gradient, foreign
end

-- UIStroke child `opts.name` (default "SpStroke"), created or reconfigured. Every property is written, so a
-- re-run with other options yields exactly the new look.
--   opts.thickness (0.05)  opts.color (ink)  opts.mode ("Border" | "Contextual" | Enum)  opts.sizing ("ScaledSize")
--   opts.transparency (0)  opts.borderOffset (UDim | number, 0)  opts.zIndex (1)  opts.position ("Outer")
--   opts.gradient (ColorSequence | stops) + opts.gradientRotation (90): a UIGradient child "UIGradient" on the
--   stroke; opts.gradient == false disables that child if present.
function Kit.addStroke(inst, opts)
	opts = opts or {}
	local stroke = ensureChild(inst, "UIStroke", opts.name or Kit.Names.stroke)
	stroke.Color = hex(opts.color or Kit.Colors.ink)
	stroke.Thickness = opts.thickness or 0.05
	stroke.ApplyStrokeMode = enumOf(Enum.ApplyStrokeMode, opts.mode or "Border")
	stroke.StrokeSizingMode = enumOf(Enum.StrokeSizingMode, opts.sizing or "ScaledSize")
	stroke.LineJoinMode = enumOf(Enum.LineJoinMode, opts.lineJoin or "Round")
	stroke.BorderStrokePosition = enumOf(Enum.BorderStrokePosition, opts.position or "Outer")
	stroke.BorderOffset = udim(opts.borderOffset or 0)
	stroke.ZIndex = opts.zIndex or 1
	stroke.Transparency = opts.transparency or 0
	stroke.Enabled = true
	if opts.gradient then
		Kit.addGradient(stroke, opts.gradient, opts.gradientRotation or 90, "UIGradient")
	elseif opts.gradient == false then
		local g = stroke:FindFirstChild("UIGradient")
		if g and g:IsA("UIGradient") then
			g.Enabled = false
		end
	end
	return stroke
end

-- Hides legacy drawing with transparency only (never Destroy / Visible=false, D2):
--   GuiObject -> BackgroundTransparency 1; image -> ImageTransparency 1; text -> TextTransparency 1 +
--   TextStrokeTransparency 1; CanvasGroup -> GroupTransparency 1; ScrollingFrame -> ScrollBarImageTransparency 1;
--   its UIStroke children -> Transparency 1. A UIStroke passed directly -> Transparency 1.
--   opts.recursive: also every GuiObject/UIStroke descendant.
function Kit.hideDecoration(inst, opts)
	if inst == nil then
		return nil
	end
	if inst:IsA("UIStroke") then
		inst.Transparency = 1
		return inst
	end
	if not inst:IsA("GuiObject") then
		return inst
	end
	inst.BackgroundTransparency = 1
	if isImage(inst) or inst:IsA("ViewportFrame") then
		inst.ImageTransparency = 1
	end
	if isText(inst) then
		inst.TextTransparency = 1
		inst.TextStrokeTransparency = 1
	end
	if inst:IsA("CanvasGroup") then
		inst.GroupTransparency = 1
	end
	if inst:IsA("ScrollingFrame") then
		inst.ScrollBarImageTransparency = 1
	end
	for _, child in ipairs(inst:GetChildren()) do
		if child:IsA("UIStroke") then
			child.Transparency = 1
		end
	end
	if opts and opts.recursive then
		for _, d in ipairs(inst:GetDescendants()) do
			if d:IsA("GuiObject") then
				Kit.hideDecoration(d)
			end
		end
	end
	return inst
end

-- Transparency 1 on `inst`'s own UIStroke children that the kit did not create. opts.borderOnly keeps Contextual
-- strokes (a TextButton's text outline). Returns how many were hidden.
function Kit.hideLegacyStrokes(inst, opts)
	local n = 0
	for _, child in ipairs(inst:GetChildren()) do
		if child:IsA("UIStroke") and not isKitName(child.Name)
			and not (opts and opts.borderOnly and child.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual) then
			child.Transparency = 1
			n += 1
		end
	end
	return n
end

-- Hides the DECOR_NAMES children of `inst` (and opts.patternLayers: full-size children named "ImageLabel", the
-- SAH pattern ImageLabel/CanvasGroup behind a panel).
local function hideDecorChildren(inst, patternLayers, hidden)
	for _, child in ipairs(inst:GetChildren()) do
		if child:IsA("GuiObject") and not isKitName(child.Name) then
			local isPattern = patternLayers and child.Name == "ImageLabel"
				and (child:IsA("ImageLabel") or child:IsA("CanvasGroup")) and fullSize(child)
			if Kit.DECOR_NAMES[child.Name] or isPattern then
				Kit.hideDecoration(child)
				if hidden then
					table.insert(hidden, child)
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Text
---------------------------------------------------------------------------------------------------

-- The Contextual stroke to (re)use as the text outline: SpTextStroke, else the label's first Contextual UIStroke
-- that no script sizes (strokes carrying an OriginalThickness attribute are animated by DoubleYourSpeed).
local function textStrokeOf(label)
	local own = Kit.findChild(label, Kit.Names.textStroke, "UIStroke")
	if own then
		return own
	end
	for _, child in ipairs(label:GetChildren()) do
		if child:IsA("UIStroke") and child.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual
			and child:GetAttribute("OriginalThickness") == nil then
			return child
		end
	end
	return nil
end

-- Speedsters text recipe: FontFace per role + a Contextual ScaledSize outline (reuses the label's existing
-- Contextual UIStroke, else adds SpTextStroke) + legacy TextStroke off.
--   kind: Kit.TextKinds key ('title', 'subtitle', 'number', 'buy', 'button', 'tab', 'sidebar', 'row', 'price',
--         'body', 'badge', 'heavy').
--   opts.color (TextColor3; default per kind, nil kinds keep theirs)  opts.keepColor
--   opts.strokeColor  opts.strokeThickness  opts.stroke == false (no outline change)
--   opts.scaled (TextScaled = true, TextWrapped = true)  opts.keepTextStroke
--   opts.gradient (+ opts.gradientRotation): text UIGradient "SpTextGradient" (e.g. Kit.Gradients.price)
--   opts.disableGradients: Enabled = false on the label's other UIGradients (SAH title gradients)
--   opts.scriptOwned.TextColor3 / .FontFace: left alone.
function Kit.styleText(label, kind, opts)
	opts = opts or {}
	if not isText(label) then
		return nil
	end
	local owned = ownedSet(opts)
	local spec = Kit.TextKinds[kind or "body"]
	assert(spec, "Kit.styleText: unknown text kind " .. tostring(kind))
	if not owned.FontFace then
		Kit.setFont(label, kind or "body")
	end
	local color = opts.color or spec.color
	if color and not opts.keepColor and not owned.TextColor3 then
		label.TextColor3 = hex(color)
	end
	if opts.scaled then
		label.TextScaled = true
		label.TextWrapped = true
	end
	if not opts.keepTextStroke then
		label.TextStrokeTransparency = 1
	end
	local stroke = nil
	if opts.stroke ~= false then
		stroke = textStrokeOf(label)
		if stroke == nil then
			stroke = Instance.new("UIStroke")
			stroke.Name = Kit.Names.textStroke
			stroke.Parent = label
		end
		if stroke:GetAttribute("oldp_Thickness") ~= nil then
			-- dormant InterfaceScaling would rescale a px thickness from this attribute (sah_structure C10)
			stroke:SetAttribute("oldp_Thickness", nil)
		end
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		stroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Thickness = opts.strokeThickness or spec.stroke
		stroke.Color = hex(opts.strokeColor or spec.strokeColor or Kit.Colors.ink)
		stroke.Transparency = 0
		stroke.Enabled = true
	end
	if opts.disableGradients then
		for _, child in ipairs(label:GetChildren()) do
			if child:IsA("UIGradient") and child.Name ~= Kit.Names.textGradient then
				child.Enabled = false
			end
		end
	end
	if opts.gradient then
		Kit.addGradient(label, opts.gradient, opts.gradientRotation or 90, Kit.Names.textGradient)
	end
	return label, stroke
end

---------------------------------------------------------------------------------------------------
-- Windows
---------------------------------------------------------------------------------------------------

-- Title recipe (window.title): GothamSSm Bold, white, Contextual ScaledSize 0.05 ink outline, SAH title
-- gradients disabled, DropShadow text copies hidden.
-- `title`: a text object, or a container whose TextLabel children are the title faces (e.g. Index.Index.Title).
-- Nested TextLabels named DropShadow are hidden; other nested TextLabels (stacked faces) get the same style.
--   opts.kind ('title'), opts.color, opts.strokeThickness, opts.scaled, opts.keepGradient, opts.scriptOwned
--   opts.position / opts.size / opts.anchor: optional placement of `title` (e.g. Kit.Sizes.title.position).
function Kit.skinTitle(title, opts)
	opts = opts or {}
	local styled = {}
	local textOpts = {
		color = opts.color, strokeThickness = opts.strokeThickness, scaled = opts.scaled,
		disableGradients = not opts.keepGradient, scriptOwned = opts.scriptOwned,
	}
	local function visit(label)
		if label.Name == "DropShadow" then
			Kit.hideDecoration(label)
			return
		end
		Kit.styleText(label, opts.kind or "title", textOpts)
		table.insert(styled, label)
		for _, child in ipairs(label:GetChildren()) do
			if child:IsA("TextLabel") then
				visit(child)
			end
		end
	end
	if isText(title) then
		visit(title)
	else
		for _, child in ipairs(title:GetChildren()) do
			if child:IsA("TextLabel") then
				visit(child)
			end
		end
	end
	if opts.position then
		title.Position = opts.position
	end
	if opts.size then
		title.Size = opts.size
	end
	if opts.anchor then
		title.AnchorPoint = opts.anchor
	end
	return styled
end

-- Close-button recipe (window.close_button, D2 + ConsoleCmds C3): the Speedsters X art 110882579806743 goes on
-- Close.TextButton (the ImageLabel glyph ConsoleCmds asserts and whose Image/Visible it caches). When there is no
-- such glyph (PetList/GrowingEggList use a Close.TextLabel), the art goes on a new child ImageLabel SpCloseArt.
-- The glyph keeps Name/Class/Visible; its UIGradients are disabled; the 'X' TextLabel, DropShadow, bevel/inlet
-- layers, legacy strokes and the button's own background are hidden by transparency. No UIScale is added
-- (ButtonFX owns the button scale), nothing is renamed.
--   opts.place: Speedsters corner geometry on the Close itself (Kit.Sizes.closeButton + an AR 1 constraint).
--   opts.keepGlyphGeometry: keep the glyph's Size/Position (default: fills the button, centred).
--   opts.keepText: keep the Close's TextLabel visible.  opts.scriptOwned.BackgroundTransparency: keep the bg.
-- Returns the ImageLabel that draws the art.
function Kit.skinCloseButton(close, opts)
	opts = opts or {}
	assert(close ~= nil and close:IsA("GuiButton"), "Kit.skinCloseButton: expected a GuiButton")
	local owned = ownedSet(opts)
	local glyph = close:FindFirstChild("TextButton")
	local art
	if glyph and glyph:IsA("ImageLabel") then
		art = glyph
	else
		art = ensureChild(close, "ImageLabel", Kit.Names.closeArt)
		local z = close.ZIndex
		for _, child in ipairs(close:GetChildren()) do
			if child ~= art and child:IsA("GuiObject") then
				z = math.max(z, child.ZIndex)
			end
		end
		art.ZIndex = z
	end
	Kit.setImage(art, Kit.Images.close)
	art.ImageColor3 = Kit.Colors.white
	art.ImageTransparency = 0
	art.BackgroundTransparency = 1
	art.ScaleType = Enum.ScaleType.Fit
	if not opts.keepGlyphGeometry then
		art.AnchorPoint = Vector2.new(0.5, 0.5)
		art.Position = UDim2.fromScale(0.5, 0.5)
		art.Size = UDim2.fromScale(1, 1)
	end
	for _, child in ipairs(art:GetChildren()) do
		if child:IsA("UIGradient") then
			child.Enabled = false
		elseif child:IsA("UIStroke") then
			child.Transparency = 1
		end
	end
	for _, child in ipairs(close:GetChildren()) do
		if child ~= art and child:IsA("GuiObject") then
			if Kit.DECOR_NAMES[child.Name] or (child.Name == "TextLabel" and child:IsA("TextLabel") and not opts.keepText) then
				Kit.hideDecoration(child, { recursive = child:IsA("TextLabel") })
			end
		end
	end
	if not owned.BackgroundTransparency then
		close.BackgroundTransparency = 1
	end
	if isImage(close) and not owned.Image and Kit.imageId(close) ~= nil then
		close.ImageTransparency = 1 -- legacy art on the button itself (the glyph draws the X)
	end
	Kit.hideLegacyStrokes(close)
	if opts.place then
		local s = Kit.Sizes.closeButton
		close.AnchorPoint = s.anchor
		close.Position = s.position
		close.Size = s.size
		local aspect = close:FindFirstChildOfClass("UIAspectRatioConstraint") or ensureChild(close, "UIAspectRatioConstraint", Kit.Names.aspect)
		aspect.AspectRatio = s.aspect
	end
	return art
end

-- Header icon (window.header_icon): ImageLabel SpHeaderIcon on the window's top-left corner, half outside, AR 1.
--   opts.size / opts.position / opts.zIndex override Kit.Sizes.headerIcon.
function Kit.addHeaderIcon(window, iconId, opts)
	opts = opts or {}
	local s = Kit.Sizes.headerIcon
	local icon = ensureChild(window, "ImageLabel", Kit.Names.headerIcon)
	Kit.setImage(icon, iconId)
	icon.BackgroundTransparency = 1
	icon.ImageTransparency = 0
	icon.ScaleType = Enum.ScaleType.Stretch
	icon.AnchorPoint = s.anchor
	icon.Size = opts.size or s.size
	icon.Position = opts.position or s.position
	local z = s.zIndex
	for _, child in ipairs(window:GetChildren()) do
		if child ~= icon and child:IsA("GuiObject") and not isKitName(child.Name) then
			z = math.max(z, child.ZIndex + 1)
		end
	end
	icon.ZIndex = opts.zIndex or z
	local aspect = ensureChild(icon, "UIAspectRatioConstraint", "UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	return icon
end

-- Window recipe (D1). Paints `painter` (the child that draws the panel; may be `windowRoot` itself). The root's
-- Position/AnchorPoint/UIScale belong to TabController and are never touched.
--   * painter: BackgroundColor3 white, BackgroundTransparency 0.15, own legacy image hidden, scale corner 0.05,
--     hairline Border stroke SpStroke (0.007 ScaledSize #0b1b3d);
--   * SpBackground: ImageLabel child of the painter, window art @0.15, Stretch, full size, UICorner, ZIndex below
--     the painter's other children;
--   * legacy look hidden (transparency): the painter's and the root's own UIStrokes, their DECOR_NAMES children,
--     and full-size "ImageLabel" pattern layers (ImageLabel/CanvasGroup) of the painter.
--   opts.art (id; e.g. Kit.Images.shopArt)  opts.fillTransparency  opts.artTransparency  opts.corner
--   opts.strokeThickness  opts.hide = { instances }  opts.keepLegacyStrokes  opts.keepPainterImage
--   opts.scriptOwned (painter props)  opts.title / opts.titleOpts  opts.close / opts.closeOpts
--   opts.icon (id) / opts.iconOpts -> Kit.addHeaderIcon(opts.iconParent or windowRoot, ...)
-- Returns { background, stroke, corner, hidden = {...}, title = {...}, close, icon, warning }.
function Kit.skinWindow(windowRoot, painter, opts)
	opts = opts or {}
	painter = painter or windowRoot
	assert(painter ~= nil and painter:IsA("GuiObject"), "Kit.skinWindow: expected a GuiObject painter")
	local owned = ownedSet(opts)
	local s = Kit.Sizes.window
	local result = { hidden = {} }

	if not owned.BackgroundColor3 then
		painter.BackgroundColor3 = Kit.Colors.windowFill
	end
	if not owned.BackgroundTransparency then
		painter.BackgroundTransparency = opts.fillTransparency or s.fillTransparency
	end
	if isImage(painter) and not opts.keepPainterImage and not owned.Image then
		painter.ImageTransparency = 1
	end
	if painter:IsA("CanvasGroup") then
		painter.GroupTransparency = 0
	end
	local corner = opts.corner or s.corner
	result.corner = Kit.setCorner(painter, corner)

	if Kit.hasLayout(painter) then
		result.warning = painter:GetFullName() .. " holds a layout object: SpBackground not added"
	else
		local bg = ensureChild(painter, "ImageLabel", Kit.Names.background)
		Kit.setImage(bg, opts.art or Kit.Images.windowArt)
		bg.ImageTransparency = opts.artTransparency or s.artTransparency
		bg.ImageColor3 = Kit.Colors.white
		bg.ScaleType = Enum.ScaleType.Stretch
		bg.BackgroundTransparency = 1
		bg.BorderSizePixel = 0
		bg.AnchorPoint = Vector2.new(0.5, 0.5)
		bg.Position = UDim2.fromScale(0.5, 0.5)
		bg.Size = UDim2.fromScale(1, 1)
		bg.ZIndex = layerZ(painter, bg)
		Kit.setCorner(bg, corner)
		result.background = bg
		local collector = painter:FindFirstAncestorWhichIsA("LayerCollector")
		if collector and prop(collector, "ZIndexBehavior") == Enum.ZIndexBehavior.Global then
			for _, child in ipairs(painter:GetChildren()) do
				if child ~= bg and child:IsA("GuiObject") and not isKitName(child.Name) and not Kit.DECOR_NAMES[child.Name]
					and child.ZIndex <= bg.ZIndex then
					result.warning = string.format("%s: Global ZIndexBehavior and %s has ZIndex <= the painter's; SpBackground may cover it",
						collector.Name, child.Name)
					break
				end
			end
		end
	end
	result.stroke = Kit.addStroke(painter, {
		name = Kit.Names.stroke, thickness = opts.strokeThickness or s.stroke, color = Kit.Colors.ink, mode = "Border",
	})

	if not opts.keepLegacyStrokes then
		Kit.hideLegacyStrokes(painter)
		if windowRoot and windowRoot ~= painter then
			Kit.hideLegacyStrokes(windowRoot)
		end
	end
	hideDecorChildren(painter, true, result.hidden)
	if windowRoot and windowRoot ~= painter then
		hideDecorChildren(windowRoot, false, result.hidden)
	end
	for _, inst in ipairs(opts.hide or {}) do
		Kit.hideDecoration(inst)
		table.insert(result.hidden, inst)
	end

	if opts.title then
		result.title = Kit.skinTitle(opts.title, opts.titleOpts)
	end
	if opts.close then
		result.close = Kit.skinCloseButton(opts.close, opts.closeOpts)
	end
	if opts.icon then
		result.icon = Kit.addHeaderIcon(opts.iconParent or windowRoot or painter, opts.icon, opts.iconOpts)
	end
	return result
end

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

local function resolveFamily(fam)
	if type(fam) == "string" then
		local spec = Kit.ButtonFamilies[fam]
		assert(spec, "Kit: unknown button family " .. fam)
		return spec
	end
	assert(type(fam) == "table" and fam.fill, "Kit: expected a button family key or table")
	return fam
end

local function foreignGradient(inst)
	for _, child in ipairs(inst:GetChildren()) do
		if child:IsA("UIGradient") and not isKitName(child.Name) and prop(child, "Enabled") ~= false then
			return child
		end
	end
	return nil
end

local function ownText(inst)
	return isText(inst) and inst.Text ~= "" and inst.TextTransparency < 1
end

-- The full-size child ImageLabel SpSkin (layer + tint modes), ZIndex below the button's other children.
local function skinLayer(button)
	local skin = ensureChild(button, "ImageLabel", Kit.Names.skin)
	skin.AnchorPoint = Vector2.new(0.5, 0.5)
	skin.Position = UDim2.fromScale(0.5, 0.5)
	skin.Size = UDim2.fromScale(1, 1)
	skin.BorderSizePixel = 0
	skin.ScaleType = Enum.ScaleType.Stretch
	skin.ImageTransparency = 0
	skin.ZIndex = layerZ(button, skin)
	return skin
end

local function familyStrokes(target, fam)
	Kit.addStroke(target, {
		name = Kit.Names.strokeLight, color = Kit.Colors.white, thickness = fam.light.thickness,
		borderOffset = fam.light.offset, zIndex = fam.light.zIndex, gradient = fam.light.gradient,
		gradientRotation = fam.light.rotation,
	})
	Kit.addStroke(target, {
		name = Kit.Names.strokeDark, color = fam.dark.color, thickness = fam.dark.thickness,
		borderOffset = fam.dark.offset, zIndex = fam.dark.zIndex,
	})
end

-- Button-family recipe (D1 families, D2 ownership). Modes (opts.mode overrides the automatic choice):
--   "direct": the family base image + ImageColor3 + white background + SpFill gradient go on the button itself.
--             Auto when the button is an ImageButton/ImageLabel and none of BackgroundColor3/ImageColor3/Image/
--             UIGradient is script-owned and it has no foreign enabled UIGradient.
--   "tint":   SpSkin child with the TINT base (sidebar base 77444378011596, drawn over a colour) and no fill, so
--             the button's scripted BackgroundColor3/ImageColor3 still reads through. Auto when BackgroundColor3,
--             ImageColor3 or Image is script-owned.
--   "layer":  SpSkin child ImageLabel with the family image + background + SpFill. It covers the button's own
--             drawing (its scripted UIGradient keeps running under it). Auto when UIGradient is script-owned, a
--             foreign gradient exists, or the button cannot draw an image (TextButton without own text, Frame).
--   "solid":  the button draws its own text (a gradient would tint it, a child layer would cover it): background
--             = family.solid (unless script-owned), strokes and corner only. Auto for TextButtons with Text, and
--             instead of a layer when the button holds a layout object.
-- Always: family corner (also on SpSkin), SpStrokeLight + SpStrokeDark (on the skin holder), legacy strokes
-- hidden (Contextual text strokes kept in solid mode), DECOR_NAMES children hidden. Never adds a UIScale.
--   opts.scriptOwned  opts.mode  opts.keepLegacyStrokes  opts.keepDecor  opts.adoptGradient (direct mode:
--   re-colour a foreign gradient instead of adding SpFill)
-- Returns the instance holding the skin (button or SpSkin), the mode, and the family.
function Kit.skinButton(button, fam, opts)
	opts = opts or {}
	fam = resolveFamily(fam)
	local owned = ownedSet(opts)
	local canImage = isImage(button)
	local foreign = foreignGradient(button)
	local mode = opts.mode
	if not mode then
		if ownText(button) then
			mode = "solid"
		elseif owned.BackgroundColor3 or owned.ImageColor3 or owned.Image then
			mode = "tint"
		elseif canImage and not owned.UIGradient and (foreign == nil or opts.adoptGradient) then
			mode = "direct"
		else
			mode = "layer"
		end
	end
	if (mode == "layer" or mode == "tint") and Kit.hasLayout(button) then
		mode = "solid"
	end

	local target = button
	if mode == "direct" then
		assert(canImage, "Kit.skinButton: direct mode needs an ImageButton/ImageLabel")
		Kit.setImage(button, fam.image)
		button.ImageColor3 = fam.imageColor
		button.ImageTransparency = 0
		button.ScaleType = Enum.ScaleType.Stretch
		button.BackgroundColor3 = fam.bg
		button.BackgroundTransparency = fam.bgTransparency
		if foreign and opts.adoptGradient then
			foreign.Color = seq(fam.fill)
			foreign.Rotation = fam.fillRotation
			foreign.Offset = Vector2.new(0, 0)
		else
			Kit.addGradient(button, fam.fill, fam.fillRotation, Kit.Names.fill)
		end
	elseif mode == "layer" then
		target = skinLayer(button)
		Kit.setImage(target, fam.image)
		target.ImageColor3 = fam.imageColor
		target.BackgroundColor3 = fam.bg
		target.BackgroundTransparency = fam.bgTransparency
		Kit.addGradient(target, fam.fill, fam.fillRotation, Kit.Names.fill)
		if not owned.BackgroundTransparency and not owned.BackgroundColor3 then
			button.BackgroundTransparency = 1
		end
		if canImage and not owned.Image and not owned.ImageTransparency then
			button.ImageTransparency = 1
		end
	elseif mode == "tint" then
		target = skinLayer(button)
		Kit.setImage(target, Kit.Images.sidebarBase)
		target.ImageColor3 = Kit.Colors.white
		target.BackgroundTransparency = 1
		local fill = target:FindFirstChild(Kit.Names.fill)
		if fill and fill:IsA("UIGradient") then
			fill.Enabled = false
		end
	elseif mode == "solid" then
		if not owned.BackgroundColor3 then
			button.BackgroundColor3 = fam.solid
		end
		if not owned.BackgroundTransparency then
			button.BackgroundTransparency = 0
		end
	else
		error("Kit.skinButton: unknown mode " .. tostring(mode))
	end

	Kit.setCorner(button, fam.corner)
	if target ~= button then
		Kit.setCorner(target, fam.corner)
	end
	familyStrokes(target, fam)
	if not opts.keepLegacyStrokes then
		Kit.hideLegacyStrokes(button, { borderOnly = isText(button) })
	end
	if not opts.keepDecor then
		hideDecorChildren(button, false, nil)
	end
	return target, mode, fam
end

-- Sidebar recipe (hud.sidebar_button): base 77444378011596 over the per-button colour (Kit.Sidebar[colourKey]),
-- corner 0.2, SpStrokeLight (white 0.04 @ -0.06 z2 + gradient) and SpStrokeDark (0.04 @ -0.02 z3), icon, label.
--   colourKey: Ability | Shop | Index | Rebirth | Evolve | Teleport | Backpack | TimeGifts ("Time Gifts").
--   iconId: an id, nil = the Speedsters icon of that key, false = no icon change.
--   opts.target: the GuiObject that draws the button (default `button`; e.g. the visual Frame of a SAH tool button).
--             ImageButton/ImageLabel targets get the base image directly; other targets get a SpSkin layer
--             (or a solid colour when they draw their own text or hold a layout).
--   opts.icon: an existing icon ImageLabel to reuse (e.g. HeroIcon); else a child `opts.iconName` (SpIcon) of
--             `button` is created. opts.placeIcon: write the Speedsters icon size/position (default: only on a
--             newly created icon). opts.iconZIndex.
--   opts.label: a text object to style as a sidebar label (FredokaOne + the key's outline thickness).
--   opts.scriptOwned, opts.keepLegacyStrokes, opts.keepDecor.
-- Returns the skin holder and the icon.
function Kit.skinSidebarButton(button, colourKey, iconId, opts)
	opts = opts or {}
	local spec = Kit.Sidebar[colourKey]
	assert(spec, "Kit.skinSidebarButton: unknown sidebar colour key " .. tostring(colourKey))
	local owned = ownedSet(opts)
	local target = opts.target or button
	local holder = target
	if isImage(target) and not owned.Image then
		Kit.setImage(target, Kit.Images.sidebarBase)
		target.ImageColor3 = Kit.Colors.white
		target.ImageTransparency = 0
		target.ScaleType = Enum.ScaleType.Stretch
		if not owned.BackgroundColor3 then
			target.BackgroundColor3 = spec.color
		end
		if not owned.BackgroundTransparency then
			target.BackgroundTransparency = 0
		end
	elseif ownText(target) or Kit.hasLayout(target) then
		if not owned.BackgroundColor3 then
			target.BackgroundColor3 = spec.color
		end
		if not owned.BackgroundTransparency then
			target.BackgroundTransparency = 0
		end
	else
		holder = skinLayer(target)
		Kit.setImage(holder, Kit.Images.sidebarBase)
		holder.ImageColor3 = Kit.Colors.white
		holder.BackgroundColor3 = spec.color
		holder.BackgroundTransparency = 0
		if not owned.BackgroundTransparency and not owned.BackgroundColor3 then
			target.BackgroundTransparency = 1
		end
	end
	Kit.setCorner(target, Kit.Sizes.sidebarButton.corner)
	if holder ~= target then
		Kit.setCorner(holder, Kit.Sizes.sidebarButton.corner)
	end
	familyStrokes(holder, spec)
	if not opts.keepLegacyStrokes then
		Kit.hideLegacyStrokes(target, { borderOnly = isText(target) })
	end
	if not opts.keepDecor then
		hideDecorChildren(target, false, nil)
	end

	local icon = opts.icon
	if iconId ~= false then
		local created = false
		if icon == nil then
			icon, created = ensureChild(button, "ImageLabel", opts.iconName or Kit.Names.icon)
		end
		Kit.setImage(icon, iconId or spec.icon)
		icon.BackgroundTransparency = 1
		icon.ImageTransparency = 0
		if opts.placeIcon or (created and opts.placeIcon ~= false) then
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Size = spec.iconSize
			icon.Position = spec.iconPosition
			icon.ScaleType = Enum.ScaleType.Stretch
			local aspect = icon:FindFirstChildOfClass("UIAspectRatioConstraint") or ensureChild(icon, "UIAspectRatioConstraint", "UIAspectRatioConstraint")
			aspect.AspectRatio = 1
		end
		if opts.iconZIndex then
			icon.ZIndex = opts.iconZIndex
		elseif holder ~= target and icon.Parent == holder.Parent then
			icon.ZIndex = math.max(icon.ZIndex, holder.ZIndex + 1) -- above its SpSkin sibling
		end
	end
	if opts.label then
		Kit.styleText(opts.label, "sidebar", { strokeThickness = spec.labelStroke, scriptOwned = opts.labelScriptOwned })
	end
	return holder, icon
end

-- Premium rays (hud.premium_button Shine): ImageLabel SpShine 72314714453458 centred on the button, a square of
-- 2.0326 x the button height (SizeConstraint RelativeYY), ImageTransparency 0.69, ZIndex -11, AR 1. Runtime juice
-- (D4) rotates it 45 deg/s; the kit only places it.
--   opts.zIndex, opts.transparency, opts.heightScale.
function Kit.addShine(button, opts)
	opts = opts or {}
	if Kit.hasLayout(button) then
		return nil, button:GetFullName() .. " holds a layout object: SpShine not added"
	end
	local s = Kit.Sizes.shine
	local shine = ensureChild(button, "ImageLabel", Kit.Names.shine)
	Kit.setImage(shine, Kit.Images.shine)
	shine.BackgroundTransparency = 1
	shine.ImageTransparency = opts.transparency or s.transparency
	shine.ImageColor3 = Kit.Colors.white
	shine.ScaleType = Enum.ScaleType.Stretch
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Position = UDim2.fromScale(0.5, 0.5)
	local h = opts.heightScale or s.heightScale
	shine.Size = UDim2.fromScale(h, h)
	shine.SizeConstraint = Enum.SizeConstraint.RelativeYY
	shine.Rotation = 0
	shine.ZIndex = opts.zIndex or s.zIndex
	shine.Active = false
	local aspect = ensureChild(shine, "UIAspectRatioConstraint", "UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	return shine
end

-- Progress-bar recipe (hud.progress_bar_level / _stamina / progress.window). The fill's Size, Position and
-- AnchorPoint are script-owned (tweened) and never written.
--   track: ImageLabel -> bar texture 119680268934075 @0.3 on white @0.3; other GuiObject -> an SpBarTrack layer
--          (or plain white @0.3 when it holds a layout). Corner 0.15, ink stroke 0.067 @T0.16 z3.
--   fill:  ImageLabel -> same texture, ScaleType Crop, background = colour; Frame -> background = colour.
--          Corner 0.15, same stroke. colourKey 'window' adds the green window gradient (rot 270).
--   colourKey: 'level' | 'speed' (#00eaff), 'stamina' (#ffea00), 'green' (#46d255), 'window', or a colour.
--   opts.scriptOwned (fill props), opts.trackOwned (track props), opts.stroke == false.
function Kit.skinBar(track, fill, colourKey, opts)
	opts = opts or {}
	local s = Kit.Sizes.levelBar
	local colors = {
		level = Kit.Colors.levelFill, speed = Kit.Colors.levelFill, stamina = Kit.Colors.staminaFill,
		green = Kit.Colors.sliderFill, window = hex("#4aff1a"),
	}
	local color = colors[colourKey] or hex(colourKey or Kit.Colors.levelFill)
	local result = {}
	if track then
		local trackOwned = opts.trackOwned or {}
		local holder = track
		if isImage(track) and not trackOwned.Image then
			Kit.setImage(track, Kit.Images.hudBar)
			track.ScaleType = Enum.ScaleType.Stretch
			track.ImageTransparency = 0.3
			track.ImageColor3 = Kit.Colors.white
		elseif not isImage(track) and not Kit.hasLayout(track) then
			holder = ensureChild(track, "ImageLabel", Kit.Names.barTrack)
			Kit.setImage(holder, Kit.Images.hudBar)
			holder.ScaleType = Enum.ScaleType.Stretch
			holder.ImageTransparency = 0.3
			holder.AnchorPoint = Vector2.new(0.5, 0.5)
			holder.Position = UDim2.fromScale(0.5, 0.5)
			holder.Size = UDim2.fromScale(1, 1)
			holder.ZIndex = layerZ(track, holder)
		end
		if not trackOwned.BackgroundColor3 then
			holder.BackgroundColor3 = Kit.Colors.white
		end
		if not trackOwned.BackgroundTransparency then
			holder.BackgroundTransparency = 0.3
		end
		if holder ~= track and not trackOwned.BackgroundTransparency then
			track.BackgroundTransparency = 1
		end
		Kit.setCorner(track, s.corner)
		if holder ~= track then
			Kit.setCorner(holder, s.corner)
		end
		if opts.stroke ~= false then
			Kit.hideLegacyStrokes(track)
			Kit.addStroke(holder, { name = Kit.Names.stroke, thickness = s.stroke, color = Kit.Colors.ink, transparency = 0.16, zIndex = 3 })
		end
		result.track = holder
	end
	if fill then
		local owned = ownedSet(opts)
		if isImage(fill) and not owned.Image then
			Kit.setImage(fill, Kit.Images.hudBar)
			fill.ScaleType = Enum.ScaleType.Crop
			fill.ImageTransparency = 0
			fill.ImageColor3 = Kit.Colors.white
		end
		if not owned.BackgroundColor3 then
			fill.BackgroundColor3 = color
		end
		if not owned.BackgroundTransparency then
			fill.BackgroundTransparency = 0
		end
		Kit.setCorner(fill, s.corner)
		if opts.stroke ~= false then
			Kit.hideLegacyStrokes(fill)
			Kit.addStroke(fill, { name = Kit.Names.stroke, thickness = s.stroke, color = Kit.Colors.ink, transparency = 0.16, zIndex = 3 })
		end
		if colourKey == "window" and not owned.UIGradient then
			Kit.addGradient(fill, Kit.Gradients.windowProgress, 270, Kit.Names.fill)
		end
		result.fill = fill
	end
	return result
end

---------------------------------------------------------------------------------------------------
-- Speedsters exemplars
---------------------------------------------------------------------------------------------------

-- Makes a subtree safe for SAH's ConsoleCmds scanners (sah_structure C3/C4), renaming only:
--   * a GuiButton named "Close" without an ImageLabel child "TextButton" -> "SpClose"
--     (ConsoleCmds asserts Close.TextButton is an ImageLabel; PetList/GrowingEggList need Close.TextLabel);
--   * a GuiObject named "ConsoleButton" without a string attribute ConsoleButton or without a GuiButton ancestor
--     inside `root` -> "SpConsoleButton".
-- Use it on NEW subtrees only (clones); never on SAH's own protected nodes. Returns the list of renames.
function Kit.guardConsoleContracts(root)
	local renamed = {}
	local nodes = { root }
	for _, d in ipairs(root:GetDescendants()) do
		table.insert(nodes, d)
	end
	for _, node in ipairs(nodes) do
		if node.Name == "Close" and node:IsA("GuiButton") then
			local glyph = node:FindFirstChild("TextButton")
			if not (glyph and glyph:IsA("ImageLabel")) then
				table.insert(renamed, { path = node:GetFullName(), from = "Close", to = "SpClose" })
				node.Name = "SpClose"
			end
		elseif node.Name == "ConsoleButton" and node:IsA("GuiObject") then
			local attr = node:GetAttribute("ConsoleButton")
			local hasButton = false
			local p = node.Parent
			while p ~= nil and p ~= root.Parent do
				if p:IsA("GuiButton") then
					hasButton = true
					break
				end
				if p == root then
					break
				end
				p = p.Parent
			end
			if type(attr) ~= "string" or not hasButton then
				table.insert(renamed, { path = node:GetFullName(), from = "ConsoleButton", to = "SpConsoleButton" })
				node.Name = "SpConsoleButton"
			end
		end
	end
	return renamed
end

-- Clones an authored Speedsters subtree from spPlace as ONE whole-subtree Clone (per-child cloning breaks refs).
--   sourcePath: materials.json sourcePath ("StarterGui.Rebirth.Rebirth.Close", `Name#Class` for same-named
--               siblings) or a segment array.
-- Guards applied to the (still unparented) clone:
--   * Kit.guardConsoleContracts (Close / ConsoleButton renames);
--   * Speedsters scripts removed (Script/LocalScript/ModuleScript; they need Speedsters remotes) unless
--     opts.keepScripts;
--   * UIScales directly under a GuiButton, or on the clone root, removed (ButtonFX/TabController own scale, D2)
--     unless opts.keepUIScales;
--   * any image showing the SPEEDSTER ESCAPE logo blanked (Content.none + ImageTransparency 1, D3).
--   opts.name (renames the clone root), opts.parent (parents the clone after the guards).
-- Returns clone, report { renamed, scripts, uiScales, logos } -- or nil, reason (spPlace missing / path not found).
function Kit.cloneExemplar(spPlace, sourcePath, opts)
	opts = opts or {}
	if spPlace == nil then
		return nil, "spPlace not loaded (Update2/World1Update3New.rbxl missing)"
	end
	local source = Kit.findPath(spPlace, sourcePath)
	if source == nil then
		return nil, "Speedsters exemplar not found: " .. (if type(sourcePath) == "table" then table.concat(sourcePath, ".") else tostring(sourcePath))
	end
	local clone = source:Clone()
	local report = { renamed = {}, scripts = 0, uiScales = 0, logos = 0 }

	local doomed = {}
	for _, d in ipairs(clone:GetDescendants()) do
		if not opts.keepScripts and (d:IsA("BaseScript") or d:IsA("ModuleScript")) then
			table.insert(doomed, d)
			report.scripts += 1
		elseif not opts.keepUIScales and d:IsA("UIScale") and d.Parent ~= nil
			and (d.Parent:IsA("GuiButton") or d.Parent == clone) then
			table.insert(doomed, d)
			report.uiScales += 1
		end
	end
	for _, d in ipairs(doomed) do
		d.Parent = nil
		d:Destroy()
	end

	local images = { clone }
	for _, d in ipairs(clone:GetDescendants()) do
		table.insert(images, d)
	end
	for _, d in ipairs(images) do
		if isImage(d) then
			local digits = Kit.imageId(d)
			if digits and Kit.FORBIDDEN_IMAGE_IDS[digits] then
				d.ImageContent = Content.none
				d.ImageTransparency = 1
				report.logos += 1
			end
		end
	end

	if opts.name then
		clone.Name = opts.name
	end
	report.renamed = Kit.guardConsoleContracts(clone)
	if opts.parent then
		clone.Parent = opts.parent
	end
	return clone, report
end

return Kit
