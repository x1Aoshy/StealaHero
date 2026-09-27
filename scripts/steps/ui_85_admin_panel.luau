--!nocheck
-- scripts/steps/ui_85_admin_panel.luau (owner 2026-09-27: "create an admin panel for the devs so we can test things like
-- give all stuff. Make it blocky like the style of everything, pretty, and it must not look AI-made, no emojis. Only
-- user 767108248 and the owners or people with Studio access can have it in game. The admin icon goes in the topbar next
-- to Backpack and Settings, and make the icon 3D art.")
--
-- Builds the Hero admin panel at BUILD time into ServerStorage.HeroAdminPanel (a ScreenGui, ResetOnSpawn off,
-- ScreenInsets None = IgnoreGuiInset on, disabled until opened). ServerStorage never replicates, so a non-admin never
-- receives the window or its script: ServerScriptService.BranchServices.HeroAdminService clones it into an admin's
-- PlayerGui (the rule is ServerScriptService.HeroAdminAccess). The LocalScript HeroAdminClient inside it
-- (src/ServerStorage/HeroAdminPanel/HeroAdminClient.client.luau) wires every button to Network["Admin: Command"] and
-- adds the topbar icon (TopbarPlus, next to Backpack and Settings) with the 3D crown of this step spinning in it.
--
-- The look is the game's window kit (scripts/lib/ui_kit.luau, the Free Gift / Sell Heroes "studded glossy" style):
-- dark studded body with the ink rim, a glossy gold header band with the white ink-outlined title, the round red close,
-- chunky glossy buttons, dark cards and panels, square corners (Kit.SQUARE_UI), the stud texture only (the window art
-- under the studs is hidden, like ui_98_square_studs does for StarterGui). Typography is capped per role
-- (UITextSizeConstraint) so a short label never balloons next to a long one; colours carry meaning (green = give, gold =
-- unlock, blue = move, cyan = speed, purple = night, red = destructive, confirmed by a second tap).
--
-- Layout: the window is designed at 820 x 500 px (offsets) and fitted to the screen at runtime with its UIScale
-- "SpPanelScale" (the client keeps every touch target >= 44 px on a phone: the smallest button is 64 px tall and the
-- fit never goes under 0.69 on a 375 px tall landscape phone).
--   header band   3D crown (ViewportFrame "Crown3D" with the part-built crown), "ADMIN PANEL", mode badge, close X
--   Tabs          6 chunky tabs: WEAPONS, ECONOMY, EGGS, WORLD, PLAYER, SERVER (attribute Tab)
--   Content       TargetBar (< target card >, ME), Pages.Page_<Tab> (ScrollingFrames), Toast (status line)
-- Every command button carries its command in the Command attribute and its arguments in Arg<Name> attributes
-- (Confirm = true: needs a second tap). The service answers exactly these names (tests/smoke_admin_panel.luau checks it).
-- Also creates ReplicatedStorage.Network["Admin: Command"] (RemoteFunction; the service re-creates it if missing).

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local UiKit = require("../lib/ui_kit")
local Kit = UiKit.Kit

local Instance = roblox.Instance
local UDim2 = roblox.UDim2
local UDim = roblox.UDim
local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum
local hex = Kit.hex

local Step = {}

Step.NAME = "HeroAdminPanel"
Step.CLIENT_NAME = "HeroAdminClient"
Step.CLIENT_SOURCE = "src/ServerStorage/HeroAdminPanel/HeroAdminClient.client.luau"
Step.REMOTE = "Admin: Command"
Step.W, Step.H = 820, 500
Step.BAND = 64
Step.DISPLAY_ORDER = 40
-- the base game's admin crown image (StarterGui.Hud...AdminPanel): already in the place; shown only if the 3D crown
-- cannot render (the client hides it under the ViewportFrame)
Step.FALLBACK_ICON = 10723374641

Step.THEME = {
	band = { { 0, "#ffe98a" }, { 0.45, "#ffb627" }, { 1, "#f0681c" } },
	body = hex("#211d3c"), panel = hex("#15132a"), list = hex("#110f22"), card = hex("#2c2850"), cardStroke = hex("#4a4484"),
	accent = hex("#ffd35a"), icon = Step.FALLBACK_ICON,
}

Step.COLORS = {
	give = hex("#2bd63c"),
	gold = hex("#ffb627"),
	travel = hex("#2f8cff"),
	speed = hex("#1fc3f2"),
	night = hex("#8b5cff"),
	day = hex("#27c4f5"),
	danger = hex("#e8363d"),
	neutral = hex("#4f5674"),
	tabOff = hex("#394273"),
	tabOn = hex("#ffb627"),
	header = hex("#ffd35a"),
	muted = hex("#b7b1e4"),
	rule = hex("#3a3570"),
}

-- tab id -> icon (every id is an image already in the place)
Step.TABS = {
	{ id = "Weapons", caption = "WEAPONS", icon = 131099804712161 }, -- bat (gear)
	{ id = "Economy", caption = "ECONOMY", icon = 107418433037502 }, -- banknotes
	{ id = "Eggs", caption = "EGGS", icon = 96783034607256 }, -- egg sticker
	{ id = "World", caption = "WORLD", icon = 71850546752124 }, -- clock (day / night, travel)
	{ id = "Player", caption = "PLAYER", icon = 71111471194517 }, -- running shoe
	{ id = "Server", caption = "SERVER", icon = 77188882273275 }, -- cog
}

-- the hero weapon Tools (GearTools.ShopItems), labels read from Library.Modules.HeroWeapons when it parses
Step.WEAPON_TOOLS = { "Bat", "Forest Bat", "Desert Bat", "Lake Bat", "Jungle Bat", "Snow Bat", "Volcano Bat" }
Step.WEAPON_FALLBACK = {
	["Bat"] = { "Cap's Shield", "Captain America" },
	["Forest Bat"] = { "Power Pole", "Goku" },
	["Desert Bat"] = { "Web Shooter", "Spider-Man" },
	["Lake Bat"] = { "Batarang", "Batman" },
	["Jungle Bat"] = { "Grenade Gauntlet", "Bakugo" },
	["Snow Bat"] = { "Mjolnir", "Thor" },
	["Volcano Bat"] = { "Gum-Gum Fist", "Luffy" },
}
Step.STAGE_FALLBACK = {
	{ key = "Forest", name = "The Avengers" }, { key = "Lake", name = "Justice League" },
	{ key = "Desert", name = "Spider-Verse" }, { key = "Jungle", name = "My Hero Academia" },
	{ key = "Snow", name = "Dragon Ball" }, { key = "Volcano", name = "One Piece" },
}

-- text size caps per role (px at the 820 x 500 design size)
Step.TEXT = { button = 22, sub = 15, header = 18, tab = 21, card = 17, small = 14, value = 30, name = 22, title = 40 }

-- geometry (design px)
Step.TABS_BOX = { x = 16, y = 78, w = 154, h = 410 }
Step.CONTENT_X, Step.CONTENT_W = 184, 620
Step.TARGET_Y, Step.ROW_H = 78, 64
Step.PAGE_Y, Step.PAGE_H = 152, 288
Step.TOAST_Y, Step.TOAST_H = 448, 40
Step.PAGE_INSET = 4 -- keeps the outer ink rims inside the scrolling clip
Step.PAGE_INNER_W = 596
Step.GAP = 8
Step.SECTION_GAP = 14
-- header row (design px, all inside the 64 px band; tests/smoke_admin_panel.luau checks none of them overlap):
--   crown 12..98 (pops out of the band on purpose) | title 104..544 (the drag handle 100..580 lies over it) |
--   mode badge 598..740 | close 761..807 (ink rim included it stays 9 px from the window's right edge)
Step.TITLE_X, Step.TITLE_W = 104, 440
Step.DRAG_X, Step.DRAG_W = 100, 480
Step.BADGE = { x = 598, y = 17, w = 142, h = 30 }
Step.CLOSE = { x = 784, y = 32, size = 46 } -- centre and side
Step.CLOSE_Z = 20
-- the amount boxes of the Economy page and the button columns next to them
Step.INPUT_W = 180
Step.INPUT_BUTTON_W = 96
Step.STUD_TRANSPARENCY = 0.62 -- the stud texture reads on every surface (ui_98_square_studs' rule)
Step.BUTTON_STUD_TILE = UDim2.fromOffset(14, 14)

local function log(fmt, ...)
	print(string.format("[ui_85_admin_panel] " .. fmt, ...))
end

---------------------------------------------------------------------------------------------------
-- small builders
---------------------------------------------------------------------------------------------------

local function place(node, x, y, w, h)
	node.AnchorPoint = Vector2.new(0, 0)
	node.Position = UDim2.fromOffset(x, y)
	node.Size = UDim2.fromOffset(w, h)
	return node
end

local function cap(label, maxSize)
	local constraint = Kit.ensureChild(label, "UITextSizeConstraint", "SpTextSize")
	constraint.MaxTextSize = maxSize
	constraint.MinTextSize = 1
	return label
end

local function blank(parent, className, name, zIndex)
	local node = UiKit.layer(parent, className, name, zIndex)
	node.BackgroundTransparency = 1
	return node
end

local function text(parent, name, value, kind, x, y, w, h, opts)
	opts = opts or {}
	local label = UiKit.text(parent, name, value, kind, {
		anchor = Vector2.new(0, 0), position = UDim2.fromOffset(x, y), size = UDim2.fromOffset(w, h),
		zIndex = opts.zIndex or 6, color = opts.color, alignX = opts.alignX, stroke = opts.stroke,
	})
	cap(label, opts.max or Step.TEXT.small)
	return label
end

-- A chunky glossy command button (TextButton + Label [+ Sub]); command / args / confirm go in attributes.
local function button(parent, name, caption, x, y, w, h, color, command, args, opts)
	opts = opts or {}
	local node, label = UiKit.labelButton(parent, name, caption, {
		color = color, anchor = Vector2.new(0, 0), position = UDim2.fromOffset(x, y), size = UDim2.fromOffset(w, h),
		zIndex = opts.zIndex or 5, kind = "button", labelSize = UDim2.fromScale(0.88, 0.56),
	})
	cap(label, opts.max or Step.TEXT.button)
	UiKit.studs(node, 2, { tile = Step.BUTTON_STUD_TILE, transparency = Step.STUD_TRANSPARENCY })
	if opts.sub then
		label.Position = UDim2.fromScale(0.5, 0.62)
		label.Size = UDim2.fromScale(0.9, 0.44)
		local sub = UiKit.text(node, "Sub", opts.sub, "body", {
			anchor = Vector2.new(0.5, 0.5), position = UDim2.fromScale(0.5, 0.25), size = UDim2.fromScale(0.86, 0.28), zIndex = 3,
		})
		cap(sub, Step.TEXT.sub)
	end
	node:SetAttribute("Caption", caption)
	if command then
		node:SetAttribute("Command", command)
		for key, value in pairs(args or {}) do
			node:SetAttribute("Arg" .. key, value)
		end
	end
	if opts.confirm then
		node:SetAttribute("Confirm", true)
	end
	return node, label
end

-- A dark amount box (UiKit.input look): the TextBox `name` the Give / Take buttons read (their InputFrom attribute).
local function amountInput(parent, name, x, y, w, h, placeholder)
	local holder = UiKit.layer(parent, "Frame", name .. "Holder", 5)
	place(holder, x, y, w, h)
	local box = UiKit.layer(holder, "TextBox", name, 6)
	box.Active = true
	box.Selectable = true
	box.Text = ""
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Step.COLORS.muted
	box.ClearTextOnFocus = false
	box.MultiLine = false
	box.BackgroundTransparency = 1
	box.TextXAlignment = Enum.TextXAlignment.Center
	box.TextYAlignment = Enum.TextYAlignment.Center
	place(box, 10, 8, w - 20, h - 16)
	UiKit.input(holder, box, Step.THEME)
	Kit.styleText(box, "body", { color = UiKit.WHITE, scaled = true })
	cap(box, 26)
	box:SetAttribute("AmountInput", true)
	return box
end

-- n equal columns across `width` with `gap` between them -> { {x, w}, ... }
local function columns(n, width, gap, x0)
	local w = (width - gap * (n - 1)) / n
	local list = {}
	for i = 1, n do
		table.insert(list, { (x0 or 0) + (i - 1) * (w + gap), w })
	end
	return list
end

local function sectionHeader(page, name, caption, y)
	local x = Step.PAGE_INSET
	text(page, name, caption, "subtitle", x, y, Step.PAGE_INNER_W, 22, {
		color = Step.COLORS.header, alignX = Enum.TextXAlignment.Left, max = Step.TEXT.header,
	})
	local rule = UiKit.layer(page, "Frame", name .. "Rule", 5)
	rule.BackgroundColor3 = Step.COLORS.rule
	rule.BackgroundTransparency = 0
	place(rule, x, y + 25, Step.PAGE_INNER_W, 2)
	return y + 34
end

local function scrollPage(parent, id)
	local page = UiKit.layer(parent, "ScrollingFrame", "Page_" .. id, 5)
	page.BackgroundTransparency = 1
	page.ScrollBarThickness = 6
	page.ScrollBarImageColor3 = Step.COLORS.gold
	page.ScrollBarImageTransparency = 0.1
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	page.VerticalScrollBarInset = Enum.ScrollBarInset.None
	page.ClipsDescendants = true
	page.Active = true
	page.Visible = id == Step.TABS[1].id
	page:SetAttribute("Tab", id)
	place(page, 0, 0, Step.CONTENT_W, Step.PAGE_H)
	return page
end

local function finishPage(page, y)
	page.CanvasSize = UDim2.fromOffset(0, math.max(y + 6, Step.PAGE_H))
end

---------------------------------------------------------------------------------------------------
-- data read from the built place
---------------------------------------------------------------------------------------------------

-- { key, name, number } of the 6 stages, in stage order (the stage zones the stages step built).
function Step.stages(place_)
	local ws = place_:GetService("Workspace")
	local objects = ws:FindFirstChild("__OBJECTS")
	local areas = objects and objects:FindFirstChild("Areas")
	local guardAreas = areas and areas:FindFirstChild("GuardAreas")
	local list = {}
	for _, stage in ipairs(guardAreas and guardAreas:GetChildren() or {}) do
		local number = stage:GetAttribute("StageNumber")
		if type(number) == "number" then
			table.insert(list, { key = stage.Name, name = stage:GetAttribute("StageName") or stage.Name, number = number })
		end
	end
	table.sort(list, function(a, b)
		return a.number < b.number
	end)
	if #list == 0 then
		for i, stage in ipairs(Step.STAGE_FALLBACK) do
			table.insert(list, { key = stage.key, name = stage.name, number = i })
		end
	end
	return list
end

-- tool name -> { display, hero } from ReplicatedStorage.Library.Modules.HeroWeapons (plain text patterns; the
-- fallback table when the module is missing or reads differently).
function Step.weaponLabels(place_)
	local labels = {}
	for tool, pair in pairs(Step.WEAPON_FALLBACK) do
		labels[tool] = { pair[1], pair[2] }
	end
	local rs = place_:GetService("ReplicatedStorage")
	local module = Kit.findPath(rs, "Library.Modules.HeroWeapons")
	local source = module and module:IsA("ModuleScript") and module.Source or ""
	local weapons = {}
	for id, display, hero in string.gmatch(source, "\n%s*(%w+)%s*=%s*{%s*DisplayName%s*=%s*\"([^\"]+)\"%s*,%s*Hero%s*=%s*\"([^\"]+)\"") do
		weapons[id] = { display, hero }
	end
	for tool, id in string.gmatch(source, "%[\"([^\"]+)\"%]%s*=%s*\"(%w+)\"") do
		if weapons[id] and labels[tool] then
			labels[tool] = weapons[id]
		end
	end
	return labels
end

---------------------------------------------------------------------------------------------------
-- the 3D crown (topbar icon + header): a chunky toy crown built from parts
---------------------------------------------------------------------------------------------------

Step.CROWN = {
	gold = Color3.fromRGB(255, 196, 36),
	goldDark = Color3.fromRGB(212, 138, 14),
	goldLight = Color3.fromRGB(255, 228, 118),
	ruby = Color3.fromRGB(228, 30, 52),
	shine = Color3.fromRGB(255, 236, 236),
	pearl = Color3.fromRGB(255, 246, 226),
	velvet = Color3.fromRGB(150, 20, 52),
	center = Vector3.new(0, 1.15, 0), -- the point the camera orbits
	distance = 6.4,
	fieldOfView = 32,
	elevation = math.rad(16),
}

local function crownPart(model, name, className, size, cframe, color, material, shape)
	local part = Instance.new(className)
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = model
	return part
end

-- Octagonal gold band with a dark lower lip and a light top rim, a stepped (blocky) point on every face - tall and
-- short alternating - each tipped with a pearl, a ruby diamond with a glint on every face, a velvet cap, an orb and a
-- cross. ~80 anchored parts, centred on the Y axis, base at Y = 0.
function Step.buildCrown()
	local c = Step.CROWN
	local model = Instance.new("Model")
	model.Name = "HeroAdminCrown"
	local radius = 1.2
	local faceWidth = 2 * radius * math.tan(math.rad(22.5)) + 0.04
	for i = 0, 7 do
		local face = CFrame.Angles(0, math.rad(i * 45), 0) * CFrame.new(0, 0, -radius)
		crownPart(model, "Band", "Part", Vector3.new(faceWidth, 0.72, 0.32), face * CFrame.new(0, 0.46, 0), c.gold)
		crownPart(model, "RimLow", "Part", Vector3.new(faceWidth + 0.08, 0.2, 0.42), face * CFrame.new(0, 0.1, 0), c.goldDark)
		crownPart(model, "RimHigh", "Part", Vector3.new(faceWidth + 0.06, 0.14, 0.4), face * CFrame.new(0, 0.86, 0), c.goldLight)
		-- stepped point: 3 blocks on even faces, 2 on odd ones
		local steps = if i % 2 == 0 then 3 else 2
		local y = 0.93
		for s = 1, steps do
			local width = 0.84 - (s - 1) * 0.28
			crownPart(model, "Point", "Part", Vector3.new(width, 0.24, 0.26), face * CFrame.new(0, y + 0.12, 0), if s == steps then c.goldLight else c.gold)
			y += 0.24
		end
		crownPart(model, "Pearl", "Part", Vector3.new(0.26, 0.26, 0.26), face * CFrame.new(0, y + 0.11, 0), c.pearl,
			Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		-- ruby diamond (a square turned 45 degrees) with a small glint
		local gem = face * CFrame.new(0, 0.47, -0.2) * CFrame.Angles(0, 0, math.rad(45))
		crownPart(model, "Gem", "Part", Vector3.new(0.38, 0.38, 0.14), gem, c.ruby)
		crownPart(model, "Glint", "Part", Vector3.new(0.09, 0.09, 0.05), gem * CFrame.new(-0.08, 0.08, -0.08), c.shine)
	end
	crownPart(model, "Velvet", "Part", Vector3.new(2.2, 2.2, 2.2), CFrame.new(0, 0.42, 0), c.velvet, Enum.Material.Fabric, Enum.PartType.Ball)
	crownPart(model, "Orb", "Part", Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 1.74, 0), c.gold, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	crownPart(model, "CrossV", "Part", Vector3.new(0.14, 0.52, 0.14), CFrame.new(0, 2.18, 0), c.goldLight)
	crownPart(model, "CrossH", "Part", Vector3.new(0.4, 0.14, 0.14), CFrame.new(0, 2.24, 0), c.goldLight)
	model.WorldPivot = CFrame.new(c.center)
	return model
end

-- The camera the client orbits: at `distance` from the crown's centre, `elevation` above it, looking at it.
function Step.crownCamera(yaw)
	local c = Step.CROWN
	return CFrame.new(c.center) * CFrame.Angles(0, yaw or math.rad(-24), 0) * CFrame.Angles(-c.elevation, 0, 0) * CFrame.new(0, 0, c.distance)
end

function Step.crownViewport(parent, name, x, y, size, zIndex)
	local viewport = UiKit.layer(parent, "ViewportFrame", name, zIndex)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(150, 146, 160)
	viewport.LightColor = Color3.fromRGB(255, 248, 232)
	viewport.LightDirection = Vector3.new(-0.55, -1, -0.65)
	place(viewport, x, y, size, size)
	local camera = Kit.ensureChild(viewport, "Camera", "CrownCamera")
	camera.FieldOfView = Step.CROWN.fieldOfView
	camera.CFrame = Step.crownCamera()
	viewport.CurrentCamera = camera -- the client re-assigns it at runtime too
	local old = viewport:FindFirstChild("HeroAdminCrown")
	if old then
		old:Destroy()
	end
	Step.buildCrown().Parent = viewport
	viewport:SetAttribute("CrownCenter", Step.CROWN.center)
	viewport:SetAttribute("CrownDistance", Step.CROWN.distance)
	viewport:SetAttribute("CrownElevation", Step.CROWN.elevation)
	return viewport
end

---------------------------------------------------------------------------------------------------
-- pages
---------------------------------------------------------------------------------------------------

local C = Step.COLORS
local T = Step.TEXT

local function weaponsPage(pages, labels)
	local page = scrollPage(pages, "Weapons")
	local x0, W, gap = Step.PAGE_INSET, Step.PAGE_INNER_W, Step.GAP
	local y = sectionHeader(page, "HeaderActions", "QUICK ACTIONS", Step.PAGE_INSET)
	local cols = columns(3, W, gap, x0)
	button(page, "GiveAllWeapons", "GIVE ALL WEAPONS", cols[1][1], y, cols[1][2], Step.ROW_H, C.give, "GiveAllWeapons")
	button(page, "UnlockIndexWeapons", "UNLOCK INDEX WEAPONS", cols[2][1], y, cols[2][2], Step.ROW_H, C.gold, "UnlockIndexWeapons")
	button(page, "RemoveDevWeapons", "REMOVE DEV WEAPONS", cols[3][1], y, cols[3][2], Step.ROW_H, C.danger, "RemoveDevWeapons", nil, { confirm = true })
	y += Step.ROW_H + Step.SECTION_GAP

	y = sectionHeader(page, "HeaderWeapons", "HERO WEAPONS  -  TAP ONE TO GIVE IT", y)
	cols = columns(4, W, gap, x0)
	local cardH = 128
	for i, tool in ipairs(Step.WEAPON_TOOLS) do
		local col = cols[(i - 1) % 4 + 1]
		local rowY = y + math.floor((i - 1) / 4) * (cardH + gap)
		local card = UiKit.layer(page, "TextButton", "Weapon_" .. string.gsub(tool, " ", ""), 5)
		card.Text = ""
		card.AutoButtonColor = false
		card.Active = true
		card.Selectable = true
		place(card, col[1], rowY, col[2], cardH)
		UiKit.card(card, { color = Step.THEME.card, strokeColor = Step.THEME.cardStroke, stroke = 0.02 })
		card:SetAttribute("Command", "GiveWeapon")
		card:SetAttribute("ArgTool", tool)
		card:SetAttribute("Caption", "GIVE")
		UiKit.studs(card, 1, { transparency = Step.STUD_TRANSPARENCY })
		local portrait = UiKit.layer(card, "ImageLabel", "Portrait", 3)
		Kit.setImage(portrait, Step.TABS[1].icon)
		portrait.BackgroundTransparency = 1
		portrait.ScaleType = Enum.ScaleType.Fit
		place(portrait, (col[2] - 60) / 2, 6, 60, 60)
		local pair = labels[tool] or { tool, "" }
		text(card, "WeaponName", string.upper(pair[1]), "button", 6, 68, col[2] - 12, 20, { max = T.card, zIndex = 3 })
		text(card, "Hero", pair[2], "body", 6, 87, col[2] - 12, 15, { max = 14, zIndex = 3, color = C.muted })
		local strip = UiKit.layer(card, "Frame", "Label", 3) -- "Label": the client's busy / confirm text goes here
		place(strip, 8, cardH - 28, col[2] - 16, 22)
		UiKit.glossButton(strip, { color = C.give, stroke = 0.08 })
		local give = text(strip, "Text", "GIVE", "button", 0, 0, col[2] - 16, 22, { max = 15, zIndex = 3 })
		give.Position = UDim2.fromScale(0, 0)
		give.Size = UDim2.fromScale(1, 1)
	end
	y += 2 * cardH + gap + Step.SECTION_GAP

	y = sectionHeader(page, "HeaderDummies", "TRAINING DUMMIES", y)
	local count = text(page, "DummyCount", "0 / 4", "number", x0 + W - 120, y - 34, 120, 22, {
		color = C.muted, alignX = Enum.TextXAlignment.Right, max = T.header,
	})
	count.ZIndex = 6
	cols = columns(2, W, gap, x0)
	button(page, "SpawnDummy", "SPAWN DUMMY", cols[1][1], y, cols[1][2], Step.ROW_H, C.travel, "SpawnDummy", nil, { sub = "IN FRONT OF YOU" })
	button(page, "ClearDummies", "CLEAR DUMMIES", cols[2][1], y, cols[2][2], Step.ROW_H, C.danger, "ClearDummies", nil, { confirm = true })
	y += Step.ROW_H
	finishPage(page, y)
	return page
end

local function economyPage(pages)
	local page = scrollPage(pages, "Economy")
	local x0, W, gap = Step.PAGE_INSET, Step.PAGE_INNER_W, Step.GAP
	local inputW, buttonW = Step.INPUT_W, Step.INPUT_BUTTON_W
	local col = function(i) -- the button columns right of the box
		return x0 + inputW + gap + (i - 1) * (buttonW + gap)
	end
	local y = sectionHeader(page, "HeaderMoney", "MONEY", Step.PAGE_INSET)
	amountInput(page, "MoneyAmount", x0, y, inputW, Step.ROW_H, "e.g. 10M")
	local give = button(page, "GiveMoney", "GIVE", col(1), y, buttonW, Step.ROW_H, C.give, "GiveMoney", nil, { max = 24 })
	give:SetAttribute("InputFrom", "MoneyAmount")
	local take = button(page, "TakeMoney", "TAKE", col(2), y, buttonW, Step.ROW_H, C.danger, "TakeMoney", nil, { max = 24 })
	take:SetAttribute("InputFrom", "MoneyAmount")
	button(page, "ResetMoney", "SET TO 0", col(3), y, 2 * buttonW + gap, Step.ROW_H, C.danger, "ResetMoney", nil, { confirm = true })
	y += Step.ROW_H + Step.SECTION_GAP

	y = sectionHeader(page, "HeaderSpeed", "SPEED POWER", y)
	amountInput(page, "SpeedAmount", x0, y, inputW, Step.ROW_H, "e.g. 2.5B")
	give = button(page, "GiveSpeed", "GIVE", col(1), y, buttonW, Step.ROW_H, C.speed, "GiveSpeed", nil, { max = 24 })
	give:SetAttribute("InputFrom", "SpeedAmount")
	take = button(page, "TakeSpeed", "TAKE", col(2), y, buttonW, Step.ROW_H, C.danger, "TakeSpeed", nil, { max = 24 })
	take:SetAttribute("InputFrom", "SpeedAmount")
	button(page, "MaxSpeed", "MAX", col(3), y, buttonW, Step.ROW_H, C.gold, "SetSpeed", { Value = 5e11 }, { sub = "TOP SPEED" })
	button(page, "ResetSpeed", "RESET", col(4), y, buttonW, Step.ROW_H, C.danger, "SetSpeed", { Value = 10 }, { sub = "BACK TO 10", confirm = true })
	y += Step.ROW_H + 12
	text(page, "Hint", "Type an amount: 500, 25K, 10M, 2.5B or 1e12 (K M B T Qa Qi, up to 1Qa). Enter gives it.", "body", x0, y,
		W, 18, { color = C.header, alignX = Enum.TextXAlignment.Left, max = T.small })
	y += 22
	text(page, "Note", "Taking more than they have leaves 0 (speed power stays at least 10). Saved to their profile.",
		"body", x0, y, W, 18, { color = C.muted, alignX = Enum.TextXAlignment.Left, max = T.small })
	y += 18
	finishPage(page, y)
	return page
end

local function eggsPage(pages, stages)
	local page = scrollPage(pages, "Eggs")
	local x0, W, gap = Step.PAGE_INSET, Step.PAGE_INNER_W, Step.GAP
	local y = sectionHeader(page, "HeaderStages", "EGG FROM A STAGE  -  STRAIGHT TO THE TARGET'S HAND", Step.PAGE_INSET)
	local cols = columns(3, W, gap, x0)
	local cardH = 128
	for i, stage in ipairs(stages) do
		local col = cols[(i - 1) % 3 + 1]
		local rowY = y + math.floor((i - 1) / 3) * (cardH + gap)
		local card = UiKit.layer(page, "Frame", "Stage_" .. stage.key, 5)
		place(card, col[1], rowY, col[2], cardH)
		UiKit.card(card, { color = Step.THEME.card, strokeColor = Step.THEME.cardStroke, stroke = 0.02 })
		UiKit.studs(card, 1, { transparency = Step.STUD_TRANSPARENCY })
		text(card, "Number", "STAGE " .. tostring(stage.number), "subtitle", 10, 6, col[2] - 20, 16, { color = C.header, max = 13, zIndex = 3, alignX = Enum.TextXAlignment.Left })
		text(card, "StageName", string.upper(stage.name), "button", 10, 22, col[2] - 20, 24, { max = T.card, zIndex = 3, alignX = Enum.TextXAlignment.Left })
		local inner = columns(2, col[2] - 16, gap, 8)
		button(card, "Random", "RANDOM", inner[1][1], 56, inner[1][2], Step.ROW_H, C.give, "GiveEgg", { Stage = stage.key, Pick = "Random" }, { zIndex = 3, max = 18 })
		button(card, "Rarest", "RAREST", inner[2][1], 56, inner[2][2], Step.ROW_H, C.night, "GiveEgg", { Stage = stage.key, Pick = "Rarest" }, { zIndex = 3, max = 18 })
	end
	local rows = math.ceil(#stages / 3)
	y += rows * cardH + (rows - 1) * gap + Step.SECTION_GAP

	y = sectionHeader(page, "HeaderPlaced", "PLACED EGGS", y)
	cols = columns(2, W, gap, x0)
	button(page, "GrowEggs", "GROW ALL PLACED EGGS", cols[1][1], y, cols[1][2], Step.ROW_H, C.give, "GrowEggs", nil, { sub = "READY TO HATCH" })
	text(page, "GrowNote", "Every egg the target placed on their base becomes ready to hatch.", "body", cols[2][1] + 6, y + 8,
		cols[2][2] - 6, Step.ROW_H - 16, { color = C.muted, alignX = Enum.TextXAlignment.Left, max = T.small })
	y += Step.ROW_H
	finishPage(page, y)
	return page
end

local function worldPage(pages, stages)
	local page = scrollPage(pages, "World")
	local x0, W, gap = Step.PAGE_INSET, Step.PAGE_INNER_W, Step.GAP
	local y = sectionHeader(page, "HeaderTaco", "TACO RAIN EVENT", Step.PAGE_INSET)
	local cols = columns(3, W, gap, x0)
	button(page, "TacoRain60", "START 60 S", cols[1][1], y, cols[1][2], Step.ROW_H, C.gold, "TacoRainStart", { Duration = 60 },
		{ sub = "TACO RAIN" })
	button(page, "TacoRain90", "START 90 S", cols[2][1], y, cols[2][2], Step.ROW_H, C.gold, "TacoRainStart", { Duration = 90 },
		{ sub = "TACO RAIN" })
	button(page, "TacoRainStop", "STOP", cols[3][1], y, cols[3][2], Step.ROW_H, C.danger, "TacoRainStop", nil, { sub = "END IT NOW" })
	y += Step.ROW_H + gap
	local status = UiKit.layer(page, "Frame", "TacoStatus", 5)
	place(status, x0, y, W, 34)
	UiKit.panel(status, { color = Step.THEME.panel, strokeColor = Step.THEME.cardStroke, stroke = 0.04 })
	text(status, "Text", "Off. Tacos fall around everyone; one that lands on an egg (bases and stages) makes it x3.", "body", 12, 5,
		W - 24, 24, { color = C.muted, alignX = Enum.TextXAlignment.Left, max = 15, zIndex = 3 })
	y += 34 + Step.SECTION_GAP

	y = sectionHeader(page, "HeaderTeleport", "TELEPORT YOURSELF", y)
	cols = columns(4, W, gap, x0)
	local spots = {
		{ name = "TeleportLobby", caption = "LOBBY", sub = "HUB SPAWN", place = "Lobby" },
		{ name = "TeleportPlot", caption = "MY BASE", sub = "YOUR PLOT", place = "Plot" },
	}
	for _, stage in ipairs(stages) do
		table.insert(spots, { name = "Teleport" .. stage.key, caption = string.upper(stage.name), sub = "STAGE " .. stage.number, place = stage.key })
	end
	for i, spot in ipairs(spots) do
		local col = cols[(i - 1) % 4 + 1]
		local rowY = y + math.floor((i - 1) / 4) * (Step.ROW_H + gap)
		button(page, spot.name, spot.caption, col[1], rowY, col[2], Step.ROW_H, C.travel, "Teleport", { Place = spot.place },
			{ sub = spot.sub, max = 18 })
	end
	local rows = math.ceil(#spots / 4)
	y += rows * Step.ROW_H + (rows - 1) * gap + Step.SECTION_GAP

	y = sectionHeader(page, "HeaderNight", "DAY AND NIGHT", y)
	cols = columns(3, W, gap, x0)
	button(page, "NightNow", "NIGHT NOW", cols[1][1], y, cols[1][2], Step.ROW_H, C.night, "NightNow", nil, { sub = "START THE NIGHT" })
	button(page, "DayNow", "DAY NOW", cols[2][1], y, cols[2][2], Step.ROW_H, C.day, "DayNow", nil, { sub = "END / RESTART DAY" })
	button(page, "NormalCycle", "NORMAL CYCLE", cols[3][1], y, cols[3][2], Step.ROW_H, C.neutral, "NormalCycle", nil, { sub = "SERVER CLOCK" })
	y += Step.ROW_H + Step.SECTION_GAP

	y = sectionHeader(page, "HeaderBases", "BASE THEMES", y)
	cols = columns(2, W, gap, x0)
	button(page, "UnlockBaseThemes", "UNLOCK ALL BASE THEMES", cols[1][1], y, cols[1][2], Step.ROW_H, C.gold, "UnlockBaseThemes", nil, { sub = "FOR THE TARGET" })
	text(page, "BasesNote", "The target equips them from the Index, like a completed stage.", "body", cols[2][1] + 6, y + 8,
		cols[2][2] - 6, Step.ROW_H - 16, { color = C.muted, alignX = Enum.TextXAlignment.Left, max = T.small })
	y += Step.ROW_H
	finishPage(page, y)
	return page
end

local function playerPage(pages)
	local page = scrollPage(pages, "Player")
	local x0, W, gap = Step.PAGE_INSET, Step.PAGE_INNER_W, Step.GAP
	local y = sectionHeader(page, "HeaderState", "TARGET PLAYER", Step.PAGE_INSET)
	local cols = columns(3, W, gap, x0)
	button(page, "Release", "RELEASE", cols[1][1], y, cols[1][2], Step.ROW_H, C.give, "Release", nil, { sub = "RAGDOLL / TRAP / STUN" })
	button(page, "Respawn", "RESPAWN", cols[2][1], y, cols[2][2], Step.ROW_H, C.travel, "Respawn", nil, { sub = "NEW CHARACTER" })
	button(page, "Heal", "HEAL", cols[3][1], y, cols[3][2], Step.ROW_H, C.give, "Heal", nil, { sub = "FULL HEALTH" })
	y += Step.ROW_H + Step.SECTION_GAP

	y = sectionHeader(page, "HeaderMove", "MOVE", y)
	cols = columns(2, W, gap, x0)
	button(page, "GoTo", "GO TO PLAYER", cols[1][1], y, cols[1][2], Step.ROW_H, C.travel, "GoTo", nil, { sub = "YOU MOVE" })
	button(page, "Bring", "BRING PLAYER", cols[2][1], y, cols[2][2], Step.ROW_H, C.travel, "Bring", nil, { sub = "THEY MOVE" })
	y += Step.ROW_H + 12
	text(page, "Note", "Pick the target with the arrows above. The WORLD teleports always move you.", "body", x0, y, W, 18, {
		color = C.muted, alignX = Enum.TextXAlignment.Left, max = T.small,
	})
	y += 18
	finishPage(page, y)
	return page
end

local function serverPage(pages)
	local page = scrollPage(pages, "Server")
	local x0, W, gap = Step.PAGE_INSET, Step.PAGE_INNER_W, Step.GAP
	local y = sectionHeader(page, "HeaderStats", "LIVE SERVER STATS", Step.PAGE_INSET)
	local cols = columns(3, W, gap, x0)
	local tiles = {
		{ "ServerHz", "SERVER HZ" }, { "FrameMs", "SLOWEST FRAME MS" }, { "MemoryMB", "MEMORY MB" },
		{ "Players", "PLAYERS" }, { "Uptime", "UPTIME" }, { "NextNight", "NEXT NIGHT" },
	}
	local tileH = 72
	for i, tile in ipairs(tiles) do
		local col = cols[(i - 1) % 3 + 1]
		local rowY = y + math.floor((i - 1) / 3) * (tileH + gap)
		local card = UiKit.layer(page, "Frame", "Stat_" .. tile[1], 5)
		place(card, col[1], rowY, col[2], tileH)
		UiKit.card(card, { color = Step.THEME.panel, strokeColor = Step.THEME.cardStroke, stroke = 0.025 })
		text(card, "Caption", tile[2], "subtitle", 10, 6, col[2] - 20, 16, { color = C.header, max = 13, zIndex = 3, alignX = Enum.TextXAlignment.Left })
		text(card, "Value", "--", "number", 10, 24, col[2] - 20, 40, { max = T.value, zIndex = 3, alignX = Enum.TextXAlignment.Left })
	end
	y += 2 * tileH + gap + Step.SECTION_GAP

	y = sectionHeader(page, "HeaderSession", "SESSION", y)
	local session = UiKit.layer(page, "Frame", "SessionInfo", 5)
	place(session, x0, y, W, 56)
	UiKit.panel(session, { color = Step.THEME.panel, strokeColor = Step.THEME.cardStroke, stroke = 0.03 })
	text(session, "Text", "Mode, place version and server id show here once the panel opens.", "body", 12, 8, W - 24, 40, {
		color = C.muted, alignX = Enum.TextXAlignment.Left, max = 16, zIndex = 3,
	})
	y += 56
	finishPage(page, y)
	return page
end

---------------------------------------------------------------------------------------------------
-- window
---------------------------------------------------------------------------------------------------

local function targetBar(content)
	local bar = blank(content, "Frame", "TargetBar", 5)
	place(bar, 0, 0, Step.CONTENT_W, Step.ROW_H)
	button(bar, "Prev", "<", 0, 0, 64, Step.ROW_H, C.neutral, nil, nil, { max = 30 })
	local card = UiKit.layer(bar, "Frame", "TargetCard", 5)
	place(card, 70, 0, 356, Step.ROW_H)
	UiKit.panel(card, { color = Step.THEME.panel, strokeColor = Step.THEME.cardStroke, stroke = 0.03 })
	local avatarBack = UiKit.layer(card, "Frame", "AvatarBack", 3)
	avatarBack.BackgroundColor3 = Step.THEME.card
	avatarBack.BackgroundTransparency = 0
	place(avatarBack, 8, 8, 48, 48)
	Kit.addStroke(avatarBack, { name = "SpStroke", color = UiKit.INK, thickness = 0.05 })
	local avatar = UiKit.layer(avatarBack, "ImageLabel", "Avatar", 4)
	avatar.BackgroundTransparency = 1
	avatar.ScaleType = Enum.ScaleType.Fit
	avatar.ImageTransparency = 0
	place(avatar, 0, 0, 48, 48)
	text(card, "Caption", "TARGET", "subtitle", 66, 5, 280, 15, { color = C.header, max = 13, zIndex = 4, alignX = Enum.TextXAlignment.Left })
	text(card, "PlayerName", "YOU", "button", 66, 19, 280, 25, { max = T.name, zIndex = 4, alignX = Enum.TextXAlignment.Left })
	text(card, "Info", "", "body", 66, 44, 280, 15, { color = C.muted, max = 13, zIndex = 4, alignX = Enum.TextXAlignment.Left })
	button(bar, "Next", ">", 432, 0, 64, Step.ROW_H, C.neutral, nil, nil, { max = 30 })
	button(bar, "Me", "ME", 502, 0, 118, Step.ROW_H, C.gold, nil, nil, { sub = "TARGET" })
	return bar
end

local function toast(content)
	local frame = UiKit.layer(content, "Frame", "Toast", 5)
	place(frame, 0, Step.TOAST_Y - Step.TARGET_Y, Step.CONTENT_W, Step.TOAST_H)
	UiKit.panel(frame, { color = Step.THEME.list, strokeColor = Step.THEME.cardStroke, stroke = 0.04 })
	local dot = UiKit.layer(frame, "Frame", "Dot", 3)
	dot.BackgroundColor3 = C.neutral
	dot.BackgroundTransparency = 0
	place(dot, 14, 13, 14, 14)
	Kit.addStroke(dot, { name = "SpStroke", color = UiKit.INK, thickness = 0.12 })
	text(frame, "Text", "Ready. Every button acts on the target player.", "body", 38, 7, Step.CONTENT_W - 50, 26, {
		alignX = Enum.TextXAlignment.Left, max = 17, zIndex = 3,
	})
	return frame
end

local function tabs(window)
	local column = blank(window, "Frame", "Tabs", 5)
	local b = Step.TABS_BOX
	place(column, b.x, b.y, b.w, b.h)
	local count = #Step.TABS
	local gap = 5
	local h = (b.h - gap * (count - 1)) / count
	for i, tab in ipairs(Step.TABS) do
		local node, label = UiKit.labelButton(column, "Tab_" .. tab.id, tab.caption, {
			color = if i == 1 then C.tabOn else C.tabOff, anchor = Vector2.new(0, 0),
			position = UDim2.fromOffset(0, (i - 1) * (h + gap)), size = UDim2.fromOffset(b.w, h), zIndex = 5, kind = "tab",
			labelPosition = UDim2.new(0, 56, 0.5, 0), labelSize = UDim2.new(1, -62, 0.46, 0),
		})
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.TextXAlignment = Enum.TextXAlignment.Left
		cap(label, T.tab)
		UiKit.studs(node, 2, { tile = Step.BUTTON_STUD_TILE, transparency = Step.STUD_TRANSPARENCY })
		node:SetAttribute("Tab", tab.id)
		local icon = UiKit.layer(node, "ImageLabel", "Icon", 3)
		Kit.setImage(icon, tab.icon)
		icon.BackgroundTransparency = 1
		icon.ScaleType = Enum.ScaleType.Fit
		place(icon, 10, (h - 38) / 2, 38, 38)
	end
	return column
end

function Step.build(place_)
	local labels = Step.weaponLabels(place_)
	local stages = Step.stages(place_)

	local gui = Instance.new("ScreenGui")
	gui.Name = Step.NAME
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.None -- = IgnoreGuiInset on (Lune 0.10.5 only serializes ScreenInsets)
	gui.Enabled = false
	gui.DisplayOrder = Step.DISPLAY_ORDER
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui:SetAttribute("HeroAdminPanel", true)
	gui:SetAttribute("BuiltBy", "scripts/steps/ui_85_admin_panel.luau")
	gui:SetAttribute("DesignWidth", Step.W)
	gui:SetAttribute("DesignHeight", Step.H)

	local window = UiKit.layer(gui, "Frame", "Window", 1)
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromOffset(Step.W, Step.H)
	window.Active = true
	local fit = Instance.new("UIScale")
	fit.Name = "SpPanelScale"
	fit.Scale = 1
	fit.Parent = window

	-- chrome: studded body, glossy band, title, close (the kit's Free Gift recipe)
	local close = UiKit.layer(window, "TextButton", "Close", 14)
	close.Text = ""
	close.Active = true
	close.AutoButtonColor = false
	-- the X glyph the kit skins (the ConsoleCmds name "TextButton", like every window's close): drawn above the kit's dark
	-- emboss disc. Without it the kit made its own art layer UNDER the disc and the X looked dim (owner round 10)
	local glyph = UiKit.layer(close, "ImageLabel", "TextButton", 3)
	glyph.BackgroundTransparency = 1
	local chrome = UiKit.chrome(window, window, Step.THEME, {
		text = "ADMIN PANEL", placement = "inside", bandHeight = Step.BAND / Step.H, noIcon = true, close = close,
		corner = 0.035, zBand = 3, zTop = 12,
	})
	local bg = window:FindFirstChild(Kit.Names.background)
	if bg and bg:IsA("ImageLabel") then
		bg.ImageTransparency = 1 -- the stud texture is the only texture (owner 2026-09-27)
	end
	local title = chrome.title
	if title then
		UiKit.placeTitle(title, chrome.box, { left = Step.TITLE_X / Step.W, width = Step.TITLE_W / Step.W, zIndex = 12 })
		cap(title, Step.TEXT.title)
	end
	-- the close sits fully inside the band, above everything of the header, bright (the X over its emboss disc)
	local c = Step.CLOSE
	close.AnchorPoint = Vector2.new(0.5, 0.5)
	close.Position = UDim2.fromOffset(c.x, c.y)
	close.Size = UDim2.fromOffset(c.size, c.size)
	close.ZIndex = Step.CLOSE_Z
	glyph.ZIndex = 3
	glyph.ImageTransparency = 0
	glyph.ImageColor3 = UiKit.WHITE
	local emboss = close:FindFirstChild("SpEmboss")
	if emboss then
		emboss.ZIndex = glyph.ZIndex - 1
	end

	-- header art: the 3D crown, popping out of the band
	local crown = Step.crownViewport(window, "Crown3D", 12, -16, 86, 13)
	crown:SetAttribute("SpHeaderIcon", true)

	-- mode badge (the client writes STUDIO / LIVE SERVER)
	local badge = UiKit.layer(window, "Frame", "ModeBadge", 12)
	place(badge, Step.BADGE.x, Step.BADGE.y, Step.BADGE.w, Step.BADGE.h)
	UiKit.panel(badge, { color = Step.THEME.panel, strokeColor = UiKit.INK, stroke = 0.08, transparency = 0.05 })
	local badgeText = text(badge, "Text", "DEV TOOLS", "button", 0, 0, Step.BADGE.w, Step.BADGE.h, { max = 15, zIndex = 3 })
	badgeText.Size = UDim2.fromScale(0.9, 0.8)
	badgeText.Position = UDim2.fromScale(0.05, 0.1)

	-- drag handle over the band (not over the close button)
	local drag = UiKit.layer(window, "TextButton", "DragHandle", 15)
	drag.Text = ""
	drag.BackgroundTransparency = 1
	drag.AutoButtonColor = false
	drag.Active = true
	drag.Selectable = false
	place(drag, Step.DRAG_X, 0, Step.DRAG_W, Step.BAND)

	tabs(window)

	local content = blank(window, "Frame", "Content", 5)
	place(content, Step.CONTENT_X, Step.TARGET_Y, Step.CONTENT_W, Step.H - Step.TARGET_Y - 12)
	targetBar(content)
	local pages = blank(content, "Frame", "Pages", 5)
	place(pages, 0, Step.PAGE_Y - Step.TARGET_Y, Step.CONTENT_W, Step.PAGE_H)
	weaponsPage(pages, labels)
	economyPage(pages)
	eggsPage(pages, stages)
	worldPage(pages, stages)
	playerPage(pages)
	serverPage(pages)
	toast(content)

	return gui
end

function Step.Apply(place_, _spPlace, _ctx)
	local serverStorage = place_:GetService("ServerStorage")
	local old = serverStorage:FindFirstChild(Step.NAME)
	if old then
		old:Destroy()
	end
	local gui = Step.build(place_)

	assert(fs.isFile(Step.CLIENT_SOURCE), Step.CLIENT_SOURCE .. " missing")
	local client = Instance.new("LocalScript")
	client.Name = Step.CLIENT_NAME
	client.Source = fs.readFile(Step.CLIENT_SOURCE)
	client.Parent = gui

	local fallback = Instance.new("StringValue")
	fallback.Name = "FallbackIcon"
	fallback.Value = "rbxassetid://" .. tostring(Step.FALLBACK_ICON)
	fallback.Parent = gui

	gui.Parent = serverStorage

	-- the command remote (HeroAdminService answers it; it re-creates it when a place lacks it)
	local rs = place_:GetService("ReplicatedStorage")
	local network = rs:FindFirstChild("Network")
	if network == nil then
		network = Instance.new("Folder")
		network.Name = "Network"
		network.Parent = rs
	end
	local remote = network:FindFirstChild(Step.REMOTE)
	if remote and not remote:IsA("RemoteFunction") then
		remote:Destroy()
		remote = nil
	end
	if remote == nil then
		remote = Instance.new("RemoteFunction")
		remote.Name = Step.REMOTE
		remote.Parent = network
	end

	local buttons, parts = 0, 0
	for _, d in ipairs(gui:GetDescendants()) do
		if d:GetAttribute("Command") ~= nil then
			buttons += 1
		elseif d:IsA("BasePart") then
			parts += 1
		end
	end
	log("ServerStorage.%s built: %d command buttons, %d tabs, 3D crown of %d parts, remote Network[%q]", Step.NAME, buttons,
		#Step.TABS, parts, Step.REMOTE)
end

return Step
