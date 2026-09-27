--!nocheck
-- scripts/steps/post_x_hero_board.luau (owner HEROBOARD 2026-09-26)
-- Owner: "Fix lbs positions pls make sure they attached to walls and top 3 have their podium placings" and "si quieres
-- las tablas haz una sola y que sea un surface gui estilo steal a hero bonita y ahi que se pueda seleccionar cualquier
-- leaderboard". The four free-standing boards of the old pass are gone (scripts/steps/post_leaderboards.luau retires
-- them BEFORE post_world_sae, so they never push a hub wall); this step builds the ONE board that replaces them:
--
--   Workspace.Hub.HeroBoard (Model, attributes HeroBoard, LeaderboardRows, DefaultStat, PodiumStat, WallFaceX)
--     Screen (Part) > BoardGui (SurfaceGui, Front face, PixelsPerStud, LightInfluence 0) > Board (Frame)
--       SpHeaderBand + Title "HERO BOARD" + trophy icon + TopPill        glossy gold band (Free Gift / Sell style)
--       Tabs > Tab_<stat> (Icon, Caption, Pop UIScale) + Pointer_<stat>  one tab per stat (attribute LeaderboardStat)
--       Hint                                                            "CLICK A TAB!" (the client rewords it on touch)
--       List > Pages > Page_<stat> (attribute LeaderboardStat)          Header + Row01..Row10 + Empty
--         RowNN > Rank > Label, Avatar, PlayerName, Value                  (LeaderboardService fills them)
--     TabButtons > TabHit_<stat> (invisible Part + ClickDetector)         laid exactly over each tab, just in front of
--                                                                         the screen face (a Workspace SurfaceGui gets no
--                                                                         clicks); StarterPlayerScripts.Game.HeroBoard
--                                                                         switches the page LOCALLY for its viewer
--     Podium > Spot1..3 > Tier / TierTop / TierEdge, FrontFace > NamePlate (SurfaceGui: Card > Ordinal, PlayerName,
--              Value), Stand (invisible anchor: feet level + facing)   ServerScriptService.LeaderboardService stands
--                                                                         the R15 avatars of EVERY page's top 3 on the
--                                                                         Stand anchors (attribute PodiumStat) and
--                                                                         publishes the plates as Spot attributes; each
--                                                                         viewer's client shows the selected tab's set
--                                                                         ("???" while a spot is empty); BaseSign "TOP 3"
--     frame / crown / trophy / pillars / ledge parts (HeroBoard* names)
--
-- Placement: the board hangs FLUSH on HubWall_EastSouth's inner face (read from Workspace.WorldWalls.Hub, 71.2 in the
-- stock layout): the back plate's back face IS the wall face (no gap, nothing past it), the screen faces -X toward the
-- hub, centred on Step.CENTER_Z, bottom high enough that the podium avatars never cover the rows. The podium stands in
-- front of it, a few studs off the wall: 1st (gold, tallest) in the centre, 2nd (silver) on the viewer's LEFT, 3rd
-- (bronze) on the viewer's RIGHT (viewer = a player facing the board, looking +X: left = -Z). Reserved region: X 40..
-- 71.2, Z -200..-95 (away from the lane mouth Z -87..85 and the plots).
-- Runs after post_world_sae (walls final) and before post_zz_base_themes (name order: post_w < post_x < post_zz), under
-- Workspace.Hub.HeroBoard, a root post_world_sae's hub-content push never looks at.
-- Lune: no lookAt / PivotTo (explicit CFrame.Angles frames, WorldPivotData), FontFace / ImageContent / per-corner radii
-- through the kit writers, TextScaled always with TextWrapped. Idempotent (the model is rebuilt on every run).

local roblox = require("@lune/roblox")
local UiKit = require("../lib/ui_kit")
local Kit = UiKit.Kit

local Instance = roblox.Instance
local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local ColorSequence = roblox.ColorSequence
local NumberSequence = roblox.NumberSequence
local NumberSequenceKeypoint = roblox.NumberSequenceKeypoint
local NumberRange = roblox.NumberRange
local UDim2 = roblox.UDim2
local Enum = roblox.Enum
local Content = roblox.Content

local hex = Kit.hex

local Step = {}

local LOG = "[hero_board]"

---------------------------------------------------------------------------------------------------
-- Contract (tests/smoke_heroboard.luau reads the built place, not these tables)
---------------------------------------------------------------------------------------------------

Step.MODEL_NAME = "HeroBoard"
Step.WALL_NAME = "HubWall_EastSouth"
Step.WALL_FACE_X = 71.2 -- stock inner face of HubWall_EastSouth (post_world_sae Step.HUB_INNER.East)
Step.WALL_TOP_FALLBACK = 38.28
Step.CENTER_Z = -140
Step.REGION = { xMin = 40, xMax = 71.2, zMin = -200, zMax = -95 }
Step.LANE_MOUTH_Z = { -87, 85 }
Step.SCREEN_W = 32 -- studs
Step.SCREEN_H = 19.2
Step.SCREEN_BOTTOM = 10.2 -- above the floor: the podium avatars' heads stay under the rows seen from the hub
Step.PIXELS_PER_STUD = 36
Step.MAX_DISTANCE = 260
Step.CLICK_DISTANCE = 90
Step.ROWS = 10
Step.DEFAULT_STAT = "Networth"
Step.PODIUM_STAT = "Networth"
Step.CLEARANCE = 1.5
Step.PLOT_FRONT_MAX = 2.4 -- post_zz_base_themes props reach this far past a plot's fences

Step.STATS = {
	{
		stat = "Networth", title = "TOTAL NETWORTH", caption = "TOTAL\nNETWORTH", icon = UiKit.Icons.cash,
		on = "#2bd63c", value = "#52ff2e", gradient = { { 0, "#eaff9a" }, { 0.5, "#5dff3a" }, { 1, "#16c43b" } },
	},
	{
		stat = "SpeedPower", title = "TOTAL SPEED", caption = "TOTAL\nSPEED", icon = UiKit.Icons.speed,
		on = "#1fa8ff", value = "#2af5ff", gradient = { { 0, "#e6fdff" }, { 0.5, "#5ce8ff" }, { 1, "#1a8cff" } },
	},
	{
		stat = "TimePlayed", title = "IN-GAME TIME", caption = "IN-GAME\nTIME", icon = UiKit.Icons.clock,
		on = "#9a52ff", value = "#e0a8ff", gradient = { { 0, "#f6e8ff" }, { 0.5, "#c07bff" }, { 1, "#7a2bff" } },
	},
	{
		stat = "EggsHatched", title = "EGGS HATCHED", caption = "EGGS\nHATCHED", icon = UiKit.Icons.egg,
		on = "#ff9a1a", value = "#ffd23a", gradient = { { 0, "#fff6c4" }, { 0.5, "#ffc23a" }, { 1, "#ff7a1a" } },
	},
}

local TROPHY_ICON = 107664846509614 -- Speedsters trophy (speedsters_ui_kit Icons.trophy)
local STUDS = "Studs" -- MaterialVariant of the hub remodel / floor
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

-- hub remodel palette (post_hub_remodel C) + medals
local C = {
	ink = hex("#0b1b3d"),
	navy = hex("#1b2742"),
	navyLight = hex("#2b3c66"),
	navyDark = hex("#121b30"),
	gold = hex("#ffc21a"),
	goldDark = hex("#e39a00"),
	goldPale = hex("#ffe27a"),
	cyan = hex("#2af5ff"),
	blueDeep = hex("#0a55c8"),
	screen = hex("#0c1830"),
	white = hex("#ffffff"),
	offTab = hex("#2c3252"),
}

-- rank 1..3: medal gradient (GUI), solid colour (3D), rim colour, ordinal
Step.MEDALS = {
	{ stops = { { 0, "#fff3a0" }, { 0.5, "#ffc21a" }, { 1, "#d98a00" } }, solid = hex("#ffc21a"), rim = hex("#ffd84a"), ordinal = "1ST" },
	{ stops = { { 0, "#ffffff" }, { 0.5, "#cfd8e3" }, { 1, "#8e9bb0" } }, solid = hex("#c9d3e0"), rim = hex("#e3ebf5"), ordinal = "2ND" },
	{ stops = { { 0, "#ffd0a0" }, { 0.5, "#e0893a" }, { 1, "#a3531a" } }, solid = hex("#d9803a"), rim = hex("#f0a060"), ordinal = "3RD" },
}
local MEDAL_OTHER = { { 0, "#4a5f96" }, { 1, "#2b3c66" } }

-- the board's window theme: gold band (trophy), the Free Gift body, faint stars
local THEME = {
	band = { { 0, "#fff27a" }, { 0.45, "#ffbf1f" }, { 1, "#ff7a00" } },
	body = hex("#252a50"), list = hex("#0f1220"), card = hex("#0e1124"), cardStroke = hex("#3c4270"),
	pattern = UiKit.Patterns.stars, patternTile = UDim2.fromOffset(110, 110), patternTransparency = 0.93,
}

-- GUI layout (fractions of the Board root frame)
local ROOT_W, ROOT_H = 0.985, 0.98 -- the root is inset so its ink rim is not clipped by the SurfaceGui
local CORNER = 0.035
local BAND_H = 0.135
local TAB_X0, TAB_X1 = 0.015, 0.235
local TAB_Y0, TAB_Y1, TAB_GAP = 0.162, 0.905, 0.018
local LIST_X0, LIST_X1, LIST_Y0, LIST_Y1 = 0.252, 0.982, 0.162, 0.965
local PAGE_INSET = 0.012

-- 3D layout (board frame F: origin on the wall face at floor level, x = viewer's LEFT (world -Z), y up, z toward the
-- wall (world +X): every board part stays at z <= 0, the back plate's back face at z = 0)
local TRIM = 0.3
local BAR = 1.3
local BACK_DEPTH = 0.6
local FRAME_FRONT = -2.0
local TRIM_FRONT = -1.55
local SCREEN_FRONT = -1.3
local CROWN_H = 1.9
local RIM_H = 0.35

-- close to the board (less of the screen hidden behind the avatars' heads), name plates on the tier fronts (below the
-- avatars, never in front of the rows)
Step.PODIUM = {
	base = { halfX = 10.4, z0 = -10.8, z1 = -2.4, h = 0.7 },
	z0 = -9.6, -- tier front (toward the hub)
	z1 = -3.0, -- tier back
	standZ = -6.3,
	tiers = {
		{ rank = 1, x0 = -3.6, x1 = 3.6, top = 3.8, yaw = 0 },
		{ rank = 2, x0 = 3.6, x1 = 10.0, top = 3.2, yaw = 12 }, -- viewer's left, turned a little toward the centre
		{ rank = 3, x0 = -10.0, x1 = -3.6, top = 2.6, yaw = -12 }, -- viewer's right
	},
}

---------------------------------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------------------------------

local warnings = {}
local function warnf(fmt, ...)
	local message = string.format(fmt, ...)
	table.insert(warnings, message)
	print(LOG .. " WARNING: " .. message)
end

local function findPath(root, path)
	local node = root
	for _, name in ipairs(string.split(path, "/")) do
		node = node and node:FindFirstChild(name)
	end
	return node
end

local function numberSeq(stops)
	local keypoints = {}
	for _, stop in ipairs(stops) do
		table.insert(keypoints, NumberSequenceKeypoint.new(stop[1], stop[2]))
	end
	return NumberSequence.new(keypoints)
end

local partCount = 0

-- opts: shape "Cylinder", look "studs" (default) | "smooth", collide, query, transparency, shadow
local function newPart(parent, name, size, cframe, color, opts)
	opts = opts or {}
	local part = Instance.new(opts.class or "Part")
	part.Name = name
	if opts.shape == "Cylinder" then
		part.Shape = Enum.PartType.Cylinder
	end
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Anchored = true
	part.CanCollide = opts.collide == true
	part.CanQuery = opts.query == true or opts.collide == true
	part.CanTouch = false
	part.CastShadow = opts.shadow ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if opts.look == "smooth" then
		part.Material = Enum.Material.SmoothPlastic
	else
		part.Material = Enum.Material.Plastic
		part.MaterialVariant = STUDS
	end
	part.Transparency = opts.transparency or 0
	part.Parent = parent
	partCount += 1
	return part
end

-- box between two corners given in the local coordinates of `frame`
local function boxIn(parent, name, frame, x0, x1, y0, y1, z0, z1, color, opts)
	local size = Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0))
	local center = Vector3.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	return newPart(parent, name, size, frame * CFrame.new(center), color, opts)
end

local AXIS = {
	x = CFrame.new(),
	y = CFrame.Angles(0, 0, math.pi / 2),
	z = CFrame.Angles(0, math.pi / 2, 0),
}
local function cylinderIn(parent, name, frame, center, length, diameter, axis, color, opts)
	opts = table.clone(opts or {})
	opts.shape = "Cylinder"
	return newPart(parent, name, Vector3.new(length, diameter, diameter), frame * CFrame.new(center) * AXIS[axis], color, opts)
end

-- a cube turned 45 degrees about the frame's depth axis (a diamond gem seen from the front)
local function gemIn(parent, name, frame, center, size, depth, color)
	return newPart(parent, name, Vector3.new(size, size, depth), frame * CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 4), color,
		{ look = "smooth" })
end

local function newModel(parent, name, pivot)
	local model = Instance.new("Model")
	model.Name = name
	model.WorldPivotData = pivot
	model.Parent = parent
	return model
end

-- world AABB of one part
local function partAabb(part)
	local cf, h = part.CFrame, part.Size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local ext = Vector3.new(
		math.abs(r.X) * h.X + math.abs(u.X) * h.Y + math.abs(l.X) * h.Z,
		math.abs(r.Y) * h.X + math.abs(u.Y) * h.Y + math.abs(l.Y) * h.Z,
		math.abs(r.Z) * h.X + math.abs(u.Z) * h.Y + math.abs(l.Z) * h.Z
	)
	return cf.Position - ext, cf.Position + ext
end

local function groupAabb(root, skip)
	local mn, mx = nil, nil
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") and not (skip and d:IsDescendantOf(skip)) then
			local a, b = partAabb(d)
			mn = if mn then Vector3.new(math.min(mn.X, a.X), math.min(mn.Y, a.Y), math.min(mn.Z, a.Z)) else a
			mx = if mx then Vector3.new(math.max(mx.X, b.X), math.max(mx.Y, b.Y), math.max(mx.Z, b.Z)) else b
		end
	end
	return mn, mx
end

---------------------------------------------------------------------------------------------------
-- GUI helpers (kit style: FredokaOne, ink outline, TextScaled + TextWrapped)
---------------------------------------------------------------------------------------------------

local function frame(parent, name, anchor, position, size, zIndex)
	local f = UiKit.layer(parent, "Frame", name, zIndex or 1)
	f.BackgroundTransparency = 1
	UiKit.setBox(f, anchor or Vector2.new(0, 0), position, size)
	return f
end

-- FredokaOne label (kind "button": white, ink Contextual stroke), optional gradient and size cap
local function text(parent, name, value, anchor, position, size, opts)
	opts = opts or {}
	local label = UiKit.text(parent, name, value, opts.kind or "button", {
		anchor = anchor, position = position, size = size, zIndex = opts.zIndex or 4, color = opts.color,
		stroke = opts.stroke or 0.1, strokeColor = opts.strokeColor, gradient = opts.gradient, alignX = opts.alignX,
	})
	label.TextYAlignment = Enum.TextYAlignment.Center
	if opts.maxSize then
		local cap = Kit.ensureChild(label, "UITextSizeConstraint", "SizeCap")
		cap.MinTextSize = 1
		cap.MaxTextSize = opts.maxSize
	end
	return label
end

local function image(parent, name, id, anchor, position, size, zIndex)
	local img = UiKit.layer(parent, "ImageLabel", name, zIndex or 3)
	Kit.setImage(img, id)
	img.BackgroundTransparency = 1
	img.ScaleType = Enum.ScaleType.Fit
	UiKit.setBox(img, anchor, position, size)
	return img
end

-- round medal disc with its rank number (RelativeYY square)
local function medal(parent, rank, position, sizeY, zIndex)
	local disc = UiKit.layer(parent, "Frame", "Rank", zIndex or 2)
	disc.SizeConstraint = Enum.SizeConstraint.RelativeYY
	UiKit.setBox(disc, Vector2.new(0, 0.5), position, UDim2.fromScale(sizeY, sizeY))
	disc.BackgroundColor3 = C.white
	disc.BackgroundTransparency = 0
	Kit.setCorner(disc, 0.5)
	Kit.addGradient(disc, rank <= 3 and Step.MEDALS[rank].stops or MEDAL_OTHER, 90, "SpFill")
	Kit.addStroke(disc, { name = "SpStroke", color = C.ink, thickness = 0.09, mode = "Border" })
	UiKit.gloss(disc, 1, { top = 0.06, width = 0.74, height = 0.4, strength = 0.55 })
	text(disc, "Label", tostring(rank), Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.52), UDim2.fromScale(0.74, 0.66),
		{ zIndex = 3, stroke = 0.14 })
	return disc
end

---------------------------------------------------------------------------------------------------
-- the screen GUI
---------------------------------------------------------------------------------------------------

-- one leaderboard row: [medal] [avatar] name / value (two lines)
local function buildRow(page, index, spec, box, rowAspect)
	local row = UiKit.layer(page, "Frame", string.format("Row%02d", index), 2)
	row.LayoutOrder = index
	UiKit.setBox(row, Vector2.new(0, 0), UDim2.fromScale(box[1], box[2]), UDim2.fromScale(box[3], box[4]))
	local top3 = index <= 3
	UiKit.card(row, {
		color = THEME.card, transparency = 0.06, corner = 0.24,
		strokeColor = top3 and Step.MEDALS[index].rim or THEME.cardStroke, stroke = top3 and 0.06 or 0.035,
	})
	row.Visible = false -- LeaderboardService shows the rows it fills
	if top3 then
		-- a soft medal-coloured glow from the left
		local glow = UiKit.layer(row, "Frame", "Glow", 1)
		glow.BackgroundColor3 = Step.MEDALS[index].solid
		glow.BackgroundTransparency = 0
		UiKit.setBox(glow, Vector2.new(0, 0), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
		Kit.setCorner(glow, 0.24)
		Kit.addGradient(glow, { { 0, "#ffffff" }, { 1, "#ffffff" } }, 0, "SpGlowGradient", { transparency = { { 0, 0.72 }, { 0.55, 0.95 }, { 1, 1 } } })
	end
	local medalSize = 0.74
	medal(row, index, UDim2.fromScale(0.02, 0.5), medalSize, 3)
	local avatarX = 0.02 + medalSize / rowAspect + 0.022
	local avatar = UiKit.layer(row, "ImageLabel", "Avatar", 3)
	avatar.SizeConstraint = Enum.SizeConstraint.RelativeYY
	UiKit.setBox(avatar, Vector2.new(0, 0.5), UDim2.fromScale(avatarX, 0.5), UDim2.fromScale(0.8, 0.8))
	avatar.BackgroundColor3 = C.navyLight
	avatar.BackgroundTransparency = 0
	avatar.ScaleType = Enum.ScaleType.Fit
	Kit.setImage(avatar, nil)
	Kit.setCorner(avatar, 0.24)
	Kit.addStroke(avatar, { name = "SpStroke", color = C.white, thickness = 0.05, mode = "Border" })
	local textX = avatarX + 0.8 / rowAspect + 0.03
	text(row, "PlayerName", "", Vector2.new(0, 0), UDim2.fromScale(textX, 0.08), UDim2.fromScale(0.975 - textX, 0.46),
		{ zIndex = 4, alignX = Enum.TextXAlignment.Left, stroke = 0.12 })
	text(row, "Value", "", Vector2.new(0, 0), UDim2.fromScale(textX, 0.53), UDim2.fromScale(0.975 - textX, 0.39),
		{ zIndex = 4, alignX = Enum.TextXAlignment.Left, color = hex(spec.value), stroke = 0.14 })
	return row
end

local function buildPage(pages, spec, pageAspect)
	local page = frame(pages, "Page_" .. spec.stat, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1), 2)
	page:SetAttribute("LeaderboardStat", spec.stat)
	-- the podium follows the selected tab (StarterPlayerScripts.Game.HeroBoard): its sign title and plate value colour
	page:SetAttribute("LeaderboardTitle", spec.title)
	page:SetAttribute("ValueColor", hex(spec.value))
	page:SetAttribute("LeaderboardTitle", spec.title)
	page:SetAttribute("LeaderboardRows", Step.ROWS)
	page.Visible = spec.stat == Step.DEFAULT_STAT
	local pop = Instance.new("UIScale")
	pop.Name = "Pop"
	pop.Scale = 1
	pop.Parent = page

	-- header strip: the stat's name in its colours, its icon on both sides
	local header = frame(page, "Header", Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.012), UDim2.fromScale(0.985, 0.112), 2)
	header.BackgroundTransparency = 0
	UiKit.card(header, { color = THEME.card, transparency = 0.1, corner = 0.4, strokeColor = hex(spec.on), stroke = 0.07 })
	local headerAspect = pageAspect * 0.985 / 0.112
	local iconH = 0.9
	image(header, "IconLeft", spec.icon, Vector2.new(0.5, 0.5), UDim2.fromScale(0.05, 0.5), UDim2.fromScale(iconH / headerAspect, iconH), 3)
	image(header, "IconRight", spec.icon, Vector2.new(0.5, 0.5), UDim2.fromScale(0.95, 0.5), UDim2.fromScale(iconH / headerAspect, iconH), 3)
	text(header, "Title", spec.title, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.52), UDim2.fromScale(0.78, 0.8),
		{ zIndex = 4, gradient = spec.gradient, stroke = 0.13 })

	-- 10 rows: ranks 1-5 in the left column, 6-10 in the right one
	local top, bottom, gap = 0.148, 0.99, 0.016
	local rowH = (bottom - top - 4 * gap) / 5
	local colW = 0.485
	local colX = { 0.01, 0.505 }
	local rowAspect = pageAspect * colW / rowH
	for index = 1, Step.ROWS do
		local col = if index <= 5 then 1 else 2
		local r = (index - 1) % 5
		buildRow(page, index, spec, { colX[col], top + r * (rowH + gap), colW, rowH }, rowAspect)
	end
	local empty = text(page, "Empty", "No heroes yet!", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.56), UDim2.fromScale(0.7, 0.13),
		{ zIndex = 5, color = hex("#dff3ff"), stroke = 0.12 })
	empty.Visible = true -- LeaderboardService hides it once a row is filled
	return page
end

local function buildTab(tabs, spec, index, rootAspect)
	local count = #Step.STATS
	local h = (TAB_Y1 - TAB_Y0 - (count - 1) * TAB_GAP) / count
	local y0 = TAB_Y0 + (index - 1) * (h + TAB_GAP)
	local selected = spec.stat == Step.DEFAULT_STAT
	local on, off = hex(spec.on), C.offTab

	-- pointer diamond on the tab's right edge (behind the tab: only its tip shows, pointing at the list)
	local pointer = UiKit.layer(tabs, "Frame", "Pointer_" .. spec.stat, 5)
	pointer.SizeConstraint = Enum.SizeConstraint.RelativeYY
	UiKit.setBox(pointer, Vector2.new(0.5, 0.5), UDim2.fromScale(TAB_X1 - 0.004, y0 + h / 2), UDim2.fromScale(h * 0.42, h * 0.42))
	pointer.Rotation = 45
	pointer.BackgroundColor3 = on
	pointer.BackgroundTransparency = 0
	Kit.setCorner(pointer, 0.12)
	Kit.addStroke(pointer, { name = "SpStroke", color = C.ink, thickness = 0.1, mode = "Border" })
	pointer:SetAttribute("LeaderboardStat", spec.stat)
	pointer.Visible = selected

	local tab = UiKit.layer(tabs, "Frame", "Tab_" .. spec.stat, 6)
	-- centre anchor: the client's selection pop (UIScale "Pop") grows the tab from its middle
	UiKit.setBox(tab, Vector2.new(0.5, 0.5), UDim2.fromScale((TAB_X0 + TAB_X1) / 2, y0 + h / 2), UDim2.fromScale(TAB_X1 - TAB_X0, h))
	tab.LayoutOrder = index
	UiKit.glossButton(tab, { color = if selected then on else off, corner = 0.2, stroke = 0.05, glossStrength = 0.45 })
	tab:SetAttribute("LeaderboardStat", spec.stat)
	tab:SetAttribute("LeaderboardTitle", spec.title)
	tab:SetAttribute("OnColor", on)
	tab:SetAttribute("OffColor", off)
	local tabAspect = rootAspect * (TAB_X1 - TAB_X0) / h
	local iconH = 0.66
	local icon = image(tab, "Icon", spec.icon, Vector2.new(0, 0.5), UDim2.fromScale(0.05, 0.5), UDim2.fromScale(iconH / tabAspect, iconH), 3)
	icon.ImageTransparency = if selected then 0 else 0.3
	local captionX = 0.07 + iconH / tabAspect
	-- one text size for every caption (TextScaled alone would give TOTAL SPEED bigger letters than TOTAL NETWORTH)
	local caption = text(tab, "Caption", spec.caption, Vector2.new(0, 0.5), UDim2.fromScale(captionX, 0.5),
		UDim2.fromScale(0.97 - captionX, 0.74), { zIndex = 3, stroke = 0.12, maxSize = 28 })
	caption.TextTransparency = if selected then 0 else 0.2
	local pop = Instance.new("UIScale")
	pop.Name = "Pop"
	pop.Scale = 1
	pop.Parent = tab
	return tab, { x0 = TAB_X0, x1 = TAB_X1, y0 = y0, y1 = y0 + h }
end

-- Builds the SurfaceGui on `screen`; returns the tab boxes (Board root scale) by stat.
local function buildGui(screen)
	local W, H = Step.SCREEN_W, Step.SCREEN_H
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = Step.PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.Brightness = 1.1
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ClipsDescendants = true
	gui.MaxDistance = Step.MAX_DISTANCE
	gui.AlwaysOnTop = false
	gui.Enabled = true
	gui.Parent = screen

	local root = UiKit.layer(gui, "Frame", "Board", 1)
	UiKit.setBox(root, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(ROOT_W, ROOT_H))
	local rootAspect = (W * ROOT_W) / (H * ROOT_H)

	-- dark studded body + glossy gold band (the Free Gift / Sell Heroes recipe)
	UiKit.body(root, root, { color = THEME.body, corner = CORNER, theme = THEME })
	UiKit.headerBand(root, { colors = THEME.band, height = BAND_H, zIndex = 4, rootCorner = CORNER, rootAspect = rootAspect })
	local iconSize = BAND_H * 1.28
	local iconX = 0.012 + iconSize * 0.5 / rootAspect
	UiKit.headerIcon(root, TROPHY_ICON, {
		position = UDim2.fromScale(iconX, BAND_H * 0.47), size = UDim2.fromScale(iconSize / rootAspect, iconSize), zIndex = 9,
	})
	local titleX = iconX + iconSize * 0.55 / rootAspect
	text(root, "TitleShadow", "HERO BOARD", Vector2.new(0, 0.5), UDim2.fromScale(titleX, BAND_H * 0.53), UDim2.fromScale(0.56, BAND_H * 0.72),
		{ zIndex = 7, color = C.ink, strokeColor = C.ink, stroke = 0.14, alignX = Enum.TextXAlignment.Left })
	text(root, "Title", "HERO BOARD", Vector2.new(0, 0.5), UDim2.fromScale(titleX, BAND_H * 0.47), UDim2.fromScale(0.56, BAND_H * 0.72),
		{ zIndex = 8, stroke = 0.14, alignX = Enum.TextXAlignment.Left, gradient = { { 0, "#ffffff" }, { 0.6, "#ffffff" }, { 1, "#fff0b8" } } })
	-- TOP 10 pill at the band's right end
	local pill = UiKit.layer(root, "Frame", "TopPill", 8)
	UiKit.setBox(pill, Vector2.new(1, 0.5), UDim2.fromScale(0.975, BAND_H * 0.5), UDim2.fromScale(0.13, BAND_H * 0.62))
	UiKit.glossButton(pill, { color = C.navy, corner = 0.5, stroke = 0.08, glossStrength = 0.35 })
	text(pill, "Label", "TOP 10", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.8, 0.7),
		{ zIndex = 3, color = C.goldPale, stroke = 0.14 })

	-- stat tabs (left column) + the hint under them
	local tabs = frame(root, "Tabs", Vector2.new(0, 0), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 6)
	local boxes = {}
	for index, spec in ipairs(Step.STATS) do
		local _, box = buildTab(tabs, spec, index, rootAspect)
		boxes[spec.stat] = box
	end
	text(root, "Hint", "CLICK A TAB!", Vector2.new(0.5, 0.5), UDim2.fromScale((TAB_X0 + TAB_X1) / 2, (TAB_Y1 + LIST_Y1) / 2 + 0.004),
		UDim2.fromScale(TAB_X1 - TAB_X0, 0.046), { zIndex = 6, color = C.goldPale, stroke = 0.12 })

	-- list panel with one page per stat (only the viewer's selected page is visible)
	local list = frame(root, "List", Vector2.new(0, 0), UDim2.fromScale(LIST_X0, LIST_Y0), UDim2.fromScale(LIST_X1 - LIST_X0, LIST_Y1 - LIST_Y0), 5)
	UiKit.panel(list, { color = THEME.list, transparency = 0.12, corner = 0.03, stroke = 0.01 })
	local pages = frame(list, "Pages", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1 - 2 * PAGE_INSET, 1 - 2 * PAGE_INSET * rootAspect * (LIST_X1 - LIST_X0) / (LIST_Y1 - LIST_Y0)), 2)
	local pageAspect = rootAspect * (LIST_X1 - LIST_X0) * pages.Size.X.Scale / ((LIST_Y1 - LIST_Y0) * pages.Size.Y.Scale)
	for _, spec in ipairs(Step.STATS) do
		buildPage(pages, spec, pageAspect)
	end
	return gui, boxes
end

---------------------------------------------------------------------------------------------------
-- the 3D board
---------------------------------------------------------------------------------------------------

-- Board-frame local position of a point given in Board-root GUI scale (u right, v down).
local function guiToLocal(u, v)
	local su = (1 - ROOT_W) / 2 + u * ROOT_W -- SurfaceGui scale
	local sv = (1 - ROOT_H) / 2 + v * ROOT_H
	local x = (0.5 - su) * Step.SCREEN_W -- GUI +x runs along the viewer's right = the frame's -x
	local y = Step.SCREEN_BOTTOM + Step.SCREEN_H - sv * Step.SCREEN_H
	return x, y
end

local function buildFrame(model, F)
	local W, H = Step.SCREEN_W, Step.SCREEN_H
	local halfW = W / 2
	local sb, st = Step.SCREEN_BOTTOM, Step.SCREEN_BOTTOM + H
	local innerW = halfW + TRIM
	local outerW = innerW + BAR
	local frameBottom = sb - TRIM - BAR
	local frameTop = st + TRIM + BAR
	local crownTop = frameTop + CROWN_H
	local solid = { collide = true }
	local smooth = { look = "smooth" }

	-- back plate on the wall (its back face is the wall face, z = 0)
	boxIn(model, "HeroBoardBack", F, -outerW, outerW, frameBottom, crownTop, -BACK_DEPTH, 0, C.navyDark, solid)
	-- chunky navy studded frame bars
	boxIn(model, "HeroBoardFrame", F, -outerW, -innerW, frameBottom, frameTop, FRAME_FRONT, -BACK_DEPTH, C.navy, solid)
	boxIn(model, "HeroBoardFrame", F, innerW, outerW, frameBottom, frameTop, FRAME_FRONT, -BACK_DEPTH, C.navy, solid)
	boxIn(model, "HeroBoardFrame", F, -innerW, innerW, frameBottom, sb - TRIM, FRAME_FRONT, -BACK_DEPTH, C.navy, solid)
	boxIn(model, "HeroBoardFrame", F, -innerW, innerW, st + TRIM, frameTop, FRAME_FRONT, -BACK_DEPTH, C.navy, solid)
	-- gold trim ring hugging the screen
	boxIn(model, "HeroBoardTrim", F, -innerW, -halfW, sb - TRIM, st + TRIM, TRIM_FRONT, -BACK_DEPTH, C.gold, smooth)
	boxIn(model, "HeroBoardTrim", F, halfW, innerW, sb - TRIM, st + TRIM, TRIM_FRONT, -BACK_DEPTH, C.gold, smooth)
	boxIn(model, "HeroBoardTrim", F, -halfW, halfW, sb - TRIM, sb, TRIM_FRONT, -BACK_DEPTH, C.gold, smooth)
	boxIn(model, "HeroBoardTrim", F, -halfW, halfW, st, st + TRIM, TRIM_FRONT, -BACK_DEPTH, C.gold, smooth)
	-- the screen (SurfaceGui carrier, recessed in the frame)
	local screen = boxIn(model, "Screen", F, -halfW, halfW, sb, st, SCREEN_FRONT, -BACK_DEPTH, C.screen,
		{ look = "smooth", collide = false, query = false, shadow = false })

	-- 3D gold studs along the bars
	local studZ = FRAME_FRONT - 0.13
	local barMidX = innerW + BAR / 2
	local y = frameBottom + 2.2
	while y < frameTop - 1.8 do
		cylinderIn(model, "HeroBoardStud", F, Vector3.new(-barMidX, y, studZ), 0.26, 0.64, "z", C.gold)
		cylinderIn(model, "HeroBoardStud", F, Vector3.new(barMidX, y, studZ), 0.26, 0.64, "z", C.gold)
		y += 2.1
	end
	local x = -innerW + 1.6
	while x < innerW - 1.4 do
		cylinderIn(model, "HeroBoardStud", F, Vector3.new(x, frameBottom + BAR / 2, studZ), 0.26, 0.64, "z", C.gold)
		cylinderIn(model, "HeroBoardStud", F, Vector3.new(x, frameTop - BAR / 2, studZ), 0.26, 0.64, "z", C.gold)
		x += 2.2
	end
	-- corner blocks with gold gems
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			local cx = sx * barMidX
			local cy = if sy > 0 then frameTop - BAR / 2 else frameBottom + BAR / 2
			boxIn(model, "HeroBoardCorner", F, cx - 0.8, cx + 0.8, cy - 0.8, cy + 0.8, FRAME_FRONT - 0.35, -BACK_DEPTH, C.navyLight, solid)
			gemIn(model, "HeroBoardGem", F, Vector3.new(cx, cy, FRAME_FRONT - 0.35 - 0.2), 0.85, 0.4, C.gold)
		end
	end

	-- crown banner with a gold rim, cyan gems and a low-poly gold trophy on top
	boxIn(model, "HeroBoardCrown", F, -outerW, outerW, frameTop, crownTop, FRAME_FRONT + 0.1, -BACK_DEPTH, C.navy, solid)
	boxIn(model, "HeroBoardCrownRim", F, -outerW - 0.1, outerW + 0.1, crownTop, crownTop + RIM_H, FRAME_FRONT - 0.1, 0, C.gold, solid)
	for _, gx in ipairs({ -12.5, -8.5, -4.5, 4.5, 8.5, 12.5 }) do
		gemIn(model, "HeroBoardCrownGem", F, Vector3.new(gx, frameTop + CROWN_H / 2, FRAME_FRONT + 0.1 - 0.2), 0.9, 0.4, C.cyan)
	end
	local tBase = crownTop + RIM_H
	local tz = -1.25
	boxIn(model, "HeroBoardTrophyPlinth", F, -1.9, 1.9, tBase, tBase + 0.55, -2.2, -0.2, C.navyLight, solid)
	boxIn(model, "HeroBoardTrophyStem", F, -0.35, 0.35, tBase + 0.55, tBase + 1.0, tz - 0.35, tz + 0.35, C.goldDark, smooth)
	cylinderIn(model, "HeroBoardTrophyCup", F, Vector3.new(0, tBase + 1.7, tz), 1.4, 2.1, "y", C.gold, smooth)
	cylinderIn(model, "HeroBoardTrophyRim", F, Vector3.new(0, tBase + 2.5, tz), 0.2, 2.35, "y", C.goldPale, smooth)
	for _, sx in ipairs({ -1, 1 }) do
		boxIn(model, "HeroBoardTrophyHandle", F, sx * 1.0, sx * 1.42, tBase + 1.3, tBase + 2.2, tz - 0.2, tz + 0.2, C.gold, smooth)
	end
	gemIn(model, "HeroBoardTrophyGem", F, Vector3.new(0, tBase + 1.7, tz - 1.05 - 0.1), 0.6, 0.3, C.cyan)

	-- ledge under the frame
	boxIn(model, "HeroBoardLedge", F, -outerW, outerW, frameBottom - 0.6, frameBottom, FRAME_FRONT - 0.5, 0, C.navyLight, solid)
	boxIn(model, "HeroBoardLedgeLip", F, -outerW, outerW, frameBottom - 0.45, frameBottom - 0.15, FRAME_FRONT - 0.6, FRAME_FRONT - 0.5, C.gold, smooth)

	-- side pillars from the floor to the crown, gold base / cap / gem
	for _, sx in ipairs({ -1, 1 }) do
		local x0, x1 = sx * (outerW + 0.2), sx * (outerW + 2.0)
		local lo, hi = math.min(x0, x1), math.max(x0, x1)
		local cx = (lo + hi) / 2
		boxIn(model, "HeroBoardPillar", F, lo, hi, 0.8, crownTop, -2.2, 0, C.navy, solid)
		boxIn(model, "HeroBoardPillarBase", F, cx - 1.1, cx + 1.1, 0, 0.8, -2.6, 0, C.gold, solid)
		boxIn(model, "HeroBoardPillarCap", F, cx - 1.1, cx + 1.1, crownTop, crownTop + 0.45, -2.6, 0, C.gold, solid)
		gemIn(model, "HeroBoardPillarGem", F, Vector3.new(cx, crownTop + 0.45 + 0.62, -1.3), 1.0, 1.0, C.cyan)
		local py = 2.4
		while py < crownTop - 1.2 do
			cylinderIn(model, "HeroBoardStud", F, Vector3.new(cx, py, -2.2 - 0.13), 0.26, 0.64, "z", C.gold)
			py += 2.4
		end
	end
	return screen, { outerW = outerW, frameBottom = frameBottom, frameTop = frameTop, crownTop = crownTop }
end

-- invisible click parts laid exactly over each tab, just in front of the screen face
local function buildTabButtons(model, F, boxes)
	local folder = Instance.new("Folder")
	folder.Name = "TabButtons"
	folder.Parent = model
	local z1 = SCREEN_FRONT - 0.04
	local z0 = z1 - 0.2
	for index, spec in ipairs(Step.STATS) do
		local box = boxes[spec.stat]
		local xa, ya = guiToLocal(box.x0, box.y0)
		local xb, yb = guiToLocal(box.x1, box.y1)
		local part = boxIn(folder, "TabHit_" .. spec.stat, F, math.min(xa, xb), math.max(xa, xb), math.min(ya, yb), math.max(ya, yb), z0, z1,
			C.white, { look = "smooth", collide = false, query = true, transparency = 1, shadow = false })
		part:SetAttribute("LeaderboardStat", spec.stat)
		part:SetAttribute("TabIndex", index)
		local detector = Instance.new("ClickDetector")
		detector.Name = "ClickDetector"
		detector.MaxActivationDistance = Step.CLICK_DISTANCE
		detector.Parent = part
	end
	return folder
end

---------------------------------------------------------------------------------------------------
-- the podium
---------------------------------------------------------------------------------------------------

local function surfaceOn(carrier, name, pps)
	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pps
	gui.LightInfluence = 0
	gui.Brightness = 1.05
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ClipsDescendants = true
	gui.MaxDistance = 200
	gui.AlwaysOnTop = false
	gui.Parent = carrier
	return gui
end

-- The tier's front plate (our name plate; the avatars' Humanoid names are hidden): [1ST] name / value, in a dark card
-- with the medal rim. LeaderboardService writes PlayerName / Value ("???" while the spot is empty).
local function buildNamePlate(spot, F, tier, bodyTop)
	local P = Step.PODIUM
	local rank = tier.rank
	local medalSpec = Step.MEDALS[rank]
	local carrier = boxIn(spot, "FrontFace", F, tier.x0 + 0.42, tier.x1 - 0.42, P.base.h + 0.14, bodyTop - 0.12, P.z0 - 0.06, P.z0 - 0.02,
		C.white, { look = "smooth", collide = false, query = false, transparency = 1, shadow = false })
	local gui = surfaceOn(carrier, "NamePlate", 50)
	local fw, fh = carrier.Size.X, carrier.Size.Y
	local card = frame(gui, "Card", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.new(1, -16, 1, -16), 1)
	card.BackgroundTransparency = 0
	UiKit.card(card, { color = THEME.card, transparency = 0.04, corner = 0.2, strokeColor = medalSpec.rim, stroke = 0.05 })
	local ordW = math.min(0.36, (fh * 1.3) / fw)
	text(card, "Ordinal", medalSpec.ordinal, Vector2.new(0, 0.5), UDim2.fromScale(0.03, 0.5), UDim2.fromScale(ordW, 0.78),
		{ zIndex = 3, gradient = medalSpec.stops, stroke = 0.12 })
	local textX = 0.05 + ordW
	text(card, "PlayerName", "???", Vector2.new(0, 0), UDim2.fromScale(textX, 0.1), UDim2.fromScale(0.95 - textX, 0.46),
		{ zIndex = 3, alignX = Enum.TextXAlignment.Left, stroke = 0.12 })
	text(card, "Value", "", Vector2.new(0, 0), UDim2.fromScale(textX, 0.56), UDim2.fromScale(0.95 - textX, 0.34),
		{ zIndex = 3, alignX = Enum.TextXAlignment.Left, color = hex(Step.STATS[1].value), stroke = 0.14 })
	return carrier
end

local function buildPodium(model, F)
	local P = Step.PODIUM
	local podium = newModel(model, "Podium", F * CFrame.new(0, 0, (P.z0 + P.z1) / 2))
	podium:SetAttribute("PodiumStat", Step.PODIUM_STAT)
	-- every page's top 3 stands here (LeaderboardService); each viewer sees the one of the tab they have selected
	podium:SetAttribute("PodiumFollowsTab", true)
	local solid = { collide = true }
	-- studded base slab, gold top lip, and a "TOP 3" sign along its front
	boxIn(podium, "PodiumBase", F, -P.base.halfX, P.base.halfX, 0, P.base.h, P.base.z0, P.base.z1, C.navyLight, solid)
	boxIn(podium, "PodiumBaseLip", F, -P.base.halfX - 0.1, P.base.halfX + 0.1, P.base.h - 0.12, P.base.h + 0.04, P.base.z0 - 0.12, P.base.z1,
		C.gold, { look = "smooth", collide = true })
	local sign = boxIn(podium, "BaseSign", F, -P.base.halfX + 0.3, P.base.halfX - 0.3, 0.08, P.base.h - 0.16, P.base.z0 - 0.06, P.base.z0 - 0.02,
		C.white, { look = "smooth", collide = false, query = false, transparency = 1, shadow = false })
	local signGui = surfaceOn(sign, "Sign", 50)
	text(signGui, "Label", "TOP 3  \u{00B7}  TOTAL NETWORTH", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.96, 0.9),
		{ zIndex = 3, color = C.goldPale, stroke = 0.12 })
	local spots = {}
	for _, tier in ipairs(P.tiers) do
		local rank = tier.rank
		local medalSpec = Step.MEDALS[rank]
		local cx = (tier.x0 + tier.x1) / 2
		local stand0 = F * CFrame.new(cx, tier.top + 0.05, P.standZ) * CFrame.Angles(0, math.rad(tier.yaw), 0)
		local spot = newModel(podium, "Spot" .. rank, stand0)
		spot:SetAttribute("PodiumRank", rank)
		local bodyTop = tier.top - 0.35
		-- navy studded tier, medal-coloured top slab (overhanging a little), medal corner strips
		boxIn(spot, "Tier", F, tier.x0, tier.x1, P.base.h, bodyTop, P.z0, P.z1, C.navy, solid)
		boxIn(spot, "TierTop", F, tier.x0 - 0.12, tier.x1 + 0.12, bodyTop, tier.top, P.z0 - 0.15, P.z1 + 0.12, medalSpec.solid, solid)
		for _, ex in ipairs({ tier.x0 + 0.18, tier.x1 - 0.18 }) do
			boxIn(spot, "TierEdge", F, ex - 0.18, ex + 0.18, P.base.h, bodyTop, P.z0 - 0.08, P.z0 + 0.3, medalSpec.solid, { look = "smooth" })
		end
		buildNamePlate(spot, F, tier, bodyTop)
		-- the avatar's anchor: bottom face on the tier top, facing the viewer (turned toward the centre on 2nd / 3rd)
		local stand = newPart(spot, "Stand", Vector3.new(1.2, 0.1, 1.2), stand0, C.white,
			{ look = "smooth", collide = false, query = false, transparency = 1, shadow = false })
		stand:SetAttribute("PodiumRank", rank)
		if rank == 1 then
			local sparkles = Instance.new("ParticleEmitter")
			sparkles.Name = "Sparkles"
			sparkles.TextureContent = Content.fromUri(SPARKLE_TEXTURE)
			sparkles.Rate = 3
			sparkles.Lifetime = NumberRange.new(1.4, 2.2)
			sparkles.Speed = NumberRange.new(0.8, 1.8)
			sparkles.SpreadAngle = Vector2.new(35, 35)
			sparkles.EmissionDirection = Enum.NormalId.Top
			sparkles.LightEmission = 1
			sparkles.Color = ColorSequence.new(hex("#fff3a0"))
			sparkles.Size = numberSeq({ { 0, 0.3 }, { 0.5, 0.5 }, { 1, 0 } })
			sparkles.Transparency = numberSeq({ { 0, 0.15 }, { 1, 1 } })
			sparkles.Parent = stand
		end
		spots[rank] = spot
	end
	return podium, spots
end

---------------------------------------------------------------------------------------------------
-- checks (build log; tests/smoke_heroboard.luau asserts the same contract)
---------------------------------------------------------------------------------------------------

local function checkPlacement(ws, model, wallX, wallTop, groundY)
	local podium = model:FindFirstChild("Podium")
	local mn, mx = groupAabb(model, podium)
	local pmn, pmx = groupAabb(podium)
	if math.abs(mx.X - wallX) > 0.01 then
		warnf("board back at X %.3f, wall face at %.3f (must be flush)", mx.X, wallX)
	end
	if mx.Y > wallTop + 0.01 then
		warnf("board top Y %.2f pokes over the wall top %.2f", mx.Y, wallTop)
	end
	local R = Step.REGION
	for label, box in pairs({ board = { mn, mx }, podium = { pmn, pmx } }) do
		local a, b = box[1], box[2]
		if a.X < R.xMin or b.X > R.xMax + 0.01 or a.Z < R.zMin or b.Z > R.zMax then
			warnf("%s outside the reserved region (X %.1f..%.1f Z %.1f..%.1f)", label, a.X, b.X, a.Z, b.Z)
		end
		if b.Z > Step.LANE_MOUTH_Z[1] - 2 and a.Z < Step.LANE_MOUTH_Z[2] + 2 then
			warnf("%s reaches the lane mouth (Z %.1f..%.1f)", label, a.Z, b.Z)
		end
	end
	if pmx.X > wallX - 2 then
		warnf("podium reaches X %.2f: keep it a few studs off the wall", pmx.X)
	end
	-- other hub content (plots grown by the themed-prop reach, stalls, Free Gift, group reward, spawn)
	local all = { groupAabb(model) }
	local roots = {
		{ "Plots", ws:FindFirstChild("Plots"), Step.PLOT_FRONT_MAX }, { "Stands", ws:FindFirstChild("Stands"), 0 },
		{ "FreeGift", findPath(ws, "Hub/FreeGift"), 0 }, { "GroupReward", findPath(ws, "__OBJECTS/GroupReward"), 0 },
		{ "SpawnLocation", ws:FindFirstChild("SpawnLocation"), 0 },
	}
	local c = Step.CLEARANCE
	for _, entry in ipairs(roots) do
		local root = entry[2]
		local parts = if root == nil then {} elseif root:IsA("BasePart") then { root } else root:GetDescendants()
		for _, d in ipairs(parts) do
			if d:IsA("BasePart") and (d.Transparency < 1 or d.CanCollide) then
				local a, b = partAabb(d)
				local g = entry[3]
				if b.Y > groundY + 0.3 and a.X - g < all[2].X + c and b.X + g > all[1].X - c and a.Z - g < all[2].Z + c and b.Z + g > all[1].Z - c then
					warnf("near %s.%s", entry[1], d:GetFullName())
					break
				end
			end
		end
	end
	return mn, mx, pmn, pmx
end

---------------------------------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------------------------------

local function wallFace(ws)
	local walls = findPath(ws, "WorldWalls/Hub")
	local wall = walls and walls:FindFirstChild(Step.WALL_NAME)
	if wall and wall:IsA("BasePart") then
		local mn, mx = partAabb(wall)
		return mn.X, mx.Y, wall
	end
	warnf("Workspace.WorldWalls.Hub.%s not found; the board uses the stock face X %.2f", Step.WALL_NAME, Step.WALL_FACE_X)
	return Step.WALL_FACE_X, Step.WALL_TOP_FALLBACK, nil
end

function Step.Apply(place, _spPlace, ctx)
	table.clear(warnings)
	partCount = 0
	local ws = place:GetService("Workspace")
	local groundY = (ctx and ctx.groundY) or 2.05
	local hub = ws:FindFirstChild("Hub")
	if hub == nil then
		hub = Instance.new("Folder")
		hub.Name = "Hub"
		hub.Parent = ws
	end
	local old = hub:FindFirstChild(Step.MODEL_NAME)
	while old do
		old:Destroy()
		old = hub:FindFirstChild(Step.MODEL_NAME)
	end
	local legacy = findPath(ws, "__OBJECTS/Leaderboards")
	if legacy then
		warnf("__OBJECTS.Leaderboards still present (post_leaderboards should have retired it); removed here")
		legacy:Destroy()
	end

	local wallX, wallTop = wallFace(ws)
	-- board frame: origin on the wall face at floor level, LookVector -X (toward the hub), x = world -Z
	local F = CFrame.new(wallX, groundY, Step.CENTER_Z) * CFrame.Angles(0, math.pi / 2, 0)
	local model = newModel(hub, Step.MODEL_NAME, F)
	model:SetAttribute("HeroBoard", true)
	model:SetAttribute("LeaderboardRows", Step.ROWS)
	model:SetAttribute("DefaultStat", Step.DEFAULT_STAT)
	model:SetAttribute("PodiumStat", Step.PODIUM_STAT)
	model:SetAttribute("WallFaceX", wallX)

	local screen, dims = buildFrame(model, F)
	local _, boxes = buildGui(screen)
	buildTabButtons(model, F, boxes)
	buildPodium(model, F)

	local mn, mx, pmn, pmx = checkPlacement(ws, model, wallX, wallTop, groundY)
	print(string.format("%s HERO BOARD on %s: back X %.2f (wall %.2f), X %.1f..%.1f Y %.1f..%.1f Z %.1f..%.1f (top %.2f / wall %.2f); "
		.. "screen %dx%.1f studs @ %d px/stud, %d tabs, %d pages x %d rows; podium X %.1f..%.1f Z %.1f..%.1f; %d parts, %d warning(s)",
		LOG, Step.WALL_NAME, mx.X, wallX, mn.X, mx.X, mn.Y, mx.Y, mn.Z, mx.Z, dims.crownTop + groundY, wallTop, Step.SCREEN_W, Step.SCREEN_H,
		Step.PIXELS_PER_STUD, #Step.STATS, #Step.STATS, Step.ROWS, pmn.X, pmx.X, pmn.Z, pmx.Z, partCount, #warnings))
end

return Step
