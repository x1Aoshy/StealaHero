--!nocheck
-- scripts/steps/post_hub_zlayout.luau
-- Build step "post_hub_zlayout" (HUB LAYOUT pass 2026-09-26; owner, on the hub screenshots: Sell stand "Fix position for
-- this too", Free Gift "This" / "Open space here"). Runs in the post_* pass right after post_hub_remodel (name order:
-- post_hub_remodel < post_hub_zlayout < post_leaderboards < ... < post_world_sae < post_zz_base_themes), so the hub walls
-- (post_world_sae) and the base-theme clearance check (post_zz_base_themes) see the final hub.
--
--   1. Sell stand (Workspace.Stands.Models."Sell Stands" + Stands.Prompts.SellAll / SellHeldAsset): the remodelled stud
--      stall (post_hub_remodel) is re-seated, unchanged, as one rigid piece on the south side of the main street next
--      to the stage-1 entrance, axis-aligned and facing the street (+Z): the market pair of the Trails shop across the
--      street. It stands on a bevelled two-tier stud pedestal (HubSellPedestal*: wedge ramps on every side, gold corner
--      blocks, walkable), has a glowing floor zone in front of the counter (HubSellZone*: translucent cyan pad, neon
--      rim, a "$" floor emblem, a sparkle shimmer and a soft cyan light) and a tall SELL HEROES pylon with a gold coin
--      on the spawn-side corner (HubSellPylon*). The old round glow disc (HubStallGlow) makes way for the zone. The two
--      prompts (names, keys, texts untouched: AssetSellerNpc binds them by name) stand at the counter front.
--   2. Free Gift (Workspace.Hub.FreeGift ClaimSign + GiftChest + Workspace.__OBJECTS.GroupReward): moved together, as
--      built, right in front of the hub spawn, facing +Z so the players see it as they spawn (they face -Z). The
--      GroupReward prompt host keeps its spot on the chest lid (rigid move), every name HubFreeGift / GroupRewards use
--      is kept.
--   3. HERO PARK (Workspace.Hub.HeroPark) fills the empty south of the hub (X -95..35, Z -208..-160; >= 3 studs from
--      the SAE walls, clear of the plots, the street and the HERO BOARD strip X 40..71.2): an east arch ("HERO PARK")
--      opening on a red-carpet avenue lined with the six stage Mythic heroes on pedestals (statues cloned from
--      ReplicatedStorage.AssetModels: IronMan, Superman, Venom, AllMight, Goku, Luffy; anchored, non-collidable, each
--      with a plaque and a "View Hero" prompt), a round plaza with the stepped octagonal Hero Fountain (water jets,
--      spout, mist and ripples from built-in particle textures; "Toss a Coin" prompt), a west Champions' garden with a
--      giant gold trophy ("Admire" prompt), benches (Seats), lamp posts (PointLights), low-poly trees, planters,
--      bollards and a signpost for the players coming down the east corridor. The prompts are handled on the client by
--      StarterPlayerScripts.Game.HeroPark (scripts/inject/heropark.luau): coin splash + top notification, the Hall of
--      Heroes card (StarterGui.HeroParkCard, scripts/steps/ui_85_hero_park.luau). Purely cosmetic: no remote, no
--      currency, no save data.
--
-- Solid only what players walk around (pedestals, fountain rim and column, arch pillars, planters, bollards, lamp bases,
-- trophy plinth, the Sell pedestal they walk onto); every prop on a walking line is non-collidable. Silent (no Sound),
-- particles use built-in rbxasset textures only (suite_audio_vfx). Everything is anchored.
-- Lune persistence: FontFace, ImageContent / TextureContent (Content.fromUri), per-corner UICorner radii,
-- WorldPivotData, CFrame.Angles yaw (never CFrame.lookAt). Idempotent (generated pieces are rebuilt from scratch).

local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local ColorSequence = roblox.ColorSequence
local ColorSequenceKeypoint = roblox.ColorSequenceKeypoint
local NumberSequence = roblox.NumberSequence
local NumberSequenceKeypoint = roblox.NumberSequenceKeypoint
local NumberRange = roblox.NumberRange
local Enum = roblox.Enum
local Font = roblox.Font
local Content = roblox.Content
local UDim = roblox.UDim
local UDim2 = roblox.UDim2

local Step = {}

local LOG_PREFIX = "[hub_zlayout]"
local STUDS = "Studs" -- MaterialVariant of the hub floor and the remodel
local STUD_TILE = "rbxassetid://6927295847"

-- Built-in particle textures (tests/suite_audio_vfx BUILTIN_PARTICLE_TEXTURES)
local TEX = {
	sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	drop = "rbxasset://textures/particles/explosion01_implosion_main.dds", -- soft round glow: water droplets
	ring = "rbxasset://textures/particles/explosion01_shockwave_main.dds", -- thin ring: ripples
	mist = "rbxasset://textures/particles/smoke_main.dds",
}

local FREDOKA = Font.fromEnum(Enum.Font.FredokaOne)

---------------------------------------------------------------------------------------------------
-- Layout (world studs; Y is added to the floor top)
---------------------------------------------------------------------------------------------------

-- 1. Sell stand: ground point under the stall's counter centre, facing the street (+Z)
Step.SELL_STAND = Vector3.new(57, 0, -28)
Step.SELL_FACING = Vector3.new(0, 0, 1)
Step.SELL_TIER = 0.45 -- two walkable tiers: the stall stands 0.9 up
Step.SELL_PEDESTAL = {
	{ x = 8.5, front = -10.5, back = 5.5, bevel = 1.1 }, -- tier 1 (frame-local: front = -Z, the street side)
	{ x = 7.0, front = -9.0, back = 4.2, bevel = 0.9 }, -- tier 2
}
Step.SELL_PROMPTS = { -- stall-frame offsets (on top of the pedestal): the counter front
	SellAll = Vector3.new(2.2, 3.1, -3.8),
	SellHeldAsset = Vector3.new(-2.2, 3.6, -3.8),
}

-- 2. Free Gift: ground point under the CLICK TO CLAIM board (the chest stays 5.6 studs in front of it), facing +Z
Step.FREE_GIFT_BOARD = Vector3.new(37, 0, -30.5)
Step.FREE_GIFT_FACING = Vector3.new(0, 0, 1)

-- 3. Hero Park
Step.PARK_REGION = { minX = -95, maxX = 35, minZ = -208, maxZ = -160 }
Step.PARK_AXIS_Z = -184 -- east-west axis of the park (arch, avenue, fountain, garden)
Step.PARK_ARCH_X = 30.5
Step.PARK_FOUNTAIN = Vector3.new(-36, 0, -184)
Step.PARK_GARDEN = Vector3.new(-77, 0, -184)
Step.PARK_ROW_Z = { north = -175.2, south = -192.8 } -- statue rows either side of the avenue
Step.STATUE_TURN = math.rad(25) -- statues face the avenue, turned this much toward the arch
-- The six Mythic heroes, one per stage (docs/STAGES_PLAN.md), zig-zagging down the avenue from the arch.
Step.STATUES = {
	{ id = "IronMan", name = "IRON MAN", team = "THE AVENGERS", stage = 1, x = 22, row = "north", accent = "#ff3b3b" },
	{ id = "Superman", name = "SUPERMAN", team = "JUSTICE LEAGUE", stage = 2, x = 22, row = "south", accent = "#1f63ff" },
	{ id = "Venom", name = "VENOM", team = "SPIDER-VERSE", stage = 3, x = 8, row = "north", accent = "#8c3dff" },
	{ id = "AllMight", name = "ALL MIGHT", team = "MY HERO ACADEMIA", stage = 4, x = 8, row = "south", accent = "#18c94c" },
	{ id = "Goku", name = "GOKU", team = "DRAGON BALL", stage = 5, x = -6, row = "north", accent = "#ff7a00" },
	{ id = "Luffy", name = "LUFFY", team = "ONE PIECE", stage = 6, x = -6, row = "south", accent = "#0a9bff" },
}
Step.PEDESTAL_TOP = 3.5 -- statue feet above the floor
Step.STATUE_SCALE = 1.5 -- the rigs are ~5-7 studs of visible hero (player size): statues stand 1.5x taller

local function hex(s)
	return Color3.fromRGB(tonumber(string.sub(s, 2, 3), 16), tonumber(string.sub(s, 4, 5), 16), tonumber(string.sub(s, 6, 7), 16))
end

-- Palette: the hub remodel's (post_hub_remodel C) + park greens / stone / water
local C = {
	ink = hex("#0b1b3d"),
	navy = hex("#1b2742"),
	navyLight = hex("#2b3c66"),
	navyBright = hex("#3d5290"),
	navyDark = hex("#121b30"),
	gold = hex("#ffc21a"),
	goldDark = hex("#e39a00"),
	goldPale = hex("#ffe27a"),
	wood = hex("#cf7630"),
	woodTop = hex("#e38b37"),
	woodPost = hex("#7a3f1f"),
	red = hex("#e8262e"),
	redDark = hex("#a3121a"),
	carpet = hex("#d62a36"),
	white = hex("#f4f6fa"),
	cream = hex("#fff1b8"),
	stone = hex("#dfe5ef"),
	stoneWarm = hex("#f0d58e"),
	cyan = hex("#2af5ff"),
	cyanSoft = hex("#7ffcff"),
	water = hex("#35c8ff"),
	blue = hex("#1e8cff"),
	leaf = hex("#2fae4b"),
	leafMid = hex("#43c95a"),
	leafLight = hex("#74e27c"),
	hedge = hex("#27933f"),
	pink = hex("#ff5fcf"),
	yellow = hex("#ffd21f"),
}

local function log(fmt, ...)
	print(string.format(LOG_PREFIX .. " " .. fmt, ...))
end

local warnings = {}
local function warnf(fmt, ...)
	local message = string.format(fmt, ...)
	table.insert(warnings, message)
	print(LOG_PREFIX .. " WARNING: " .. message)
end

local function findPath(root, path)
	local node = root
	for _, name in ipairs(string.split(path, "/")) do
		if node == nil then
			return nil
		end
		node = node:FindFirstChild(name)
	end
	return node
end

-- Ground frame whose LookVector (local -Z, the "front") points along (dirX, dirZ).
local function facingFrame(position, dirX, dirZ)
	local yaw = math.atan2(-dirX, -dirZ)
	return CFrame.new(position) * CFrame.Angles(0, yaw, 0)
end

local function yawFrame(x, y, z, yaw)
	return CFrame.new(x, y, z) * CFrame.Angles(0, yaw or 0, 0)
end

---------------------------------------------------------------------------------------------------
-- Part helpers (the remodel's recipe)
---------------------------------------------------------------------------------------------------

local partCount = 0

-- opts: shape ("Cylinder"), class ("Part" | "WedgePart" | "Seat"), look ("studs" | "smooth" | "neon"), collide (false),
-- query (false), touch (false), transparency (0), shadow (true), reflect (0)
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
	part.CanTouch = opts.touch == true
	part.CastShadow = opts.shadow ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local look = opts.look or "studs"
	if look == "neon" then
		part.Material = Enum.Material.Neon
	elseif look == "smooth" then
		part.Material = Enum.Material.SmoothPlastic
	else
		part.Material = Enum.Material.Plastic
		part.MaterialVariant = STUDS
	end
	part.Transparency = opts.transparency or 0
	if opts.reflect then
		part.Reflectance = opts.reflect
	end
	part.Parent = parent
	partCount += 1
	return part
end

-- Box between two corners given in the local coordinates of `frame`.
local function boxIn(parent, name, frame, x0, x1, y0, y1, z0, z1, color, opts)
	local size = Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0))
	local center = Vector3.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	return newPart(parent, name, size, frame * CFrame.new(center), color, opts)
end

-- Box of `size` centred at local `center` of `frame`, optionally turned `yaw` about its own vertical axis.
local function blockAt(parent, name, frame, center, size, color, opts, yaw)
	return newPart(parent, name, size, frame * CFrame.new(center) * CFrame.Angles(0, yaw or 0, 0), color, opts)
end

local AXIS_ROTATION = {
	x = CFrame.new(),
	y = CFrame.Angles(0, 0, math.pi / 2),
	z = CFrame.Angles(0, math.pi / 2, 0),
}
local function cylinderIn(parent, name, frame, center, length, diameter, axis, color, opts)
	opts = table.clone(opts or {})
	opts.shape = "Cylinder"
	return newPart(parent, name, Vector3.new(length, diameter, diameter), frame * CFrame.new(center) * AXIS_ROTATION[axis], color, opts)
end

-- Upright cylinder (axis Y) from y0 to y1 at local (x, z) of `frame`.
local function pillarIn(parent, name, frame, x, z, y0, y1, diameter, color, opts)
	return cylinderIn(parent, name, frame, Vector3.new(x, (y0 + y1) / 2, z), y1 - y0, diameter, "y", color, opts)
end

-- Rounded-rectangle slab in the XY plane of `frame` (depth along Z). Returns the main box.
local function roundedSlab(parent, name, frame, cx, cy, w, h, z0, z1, r, color, opts)
	r = math.min(r, w / 2 - 0.05, h / 2 - 0.05)
	local depth = math.abs(z1 - z0)
	local cz = (z0 + z1) / 2
	local main = boxIn(parent, name, frame, cx - w / 2, cx + w / 2, cy - h / 2 + r, cy + h / 2 - r, z0, z1, color, opts)
	boxIn(parent, name .. "Round", frame, cx - w / 2 + r, cx + w / 2 - r, cy - h / 2, cy + h / 2, z0, z1, color, opts)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			cylinderIn(parent, name .. "Round", frame, Vector3.new(cx + sx * (w / 2 - r), cy + sy * (h / 2 - r), cz), depth, 2 * r, "z", color, opts)
		end
	end
	return main
end

-- A gem: a cube turned 45 degrees about Y and tipped 35 degrees (the fence-cap gem of the remodel).
local function gemAt(parent, name, frame, center, size, color, opts)
	return newPart(parent, name, Vector3.new(size, size, size),
		frame * CFrame.new(center) * CFrame.Angles(0, math.pi / 4, 0) * CFrame.Angles(math.rad(35), 0, 0), color, opts)
end

-- Right-triangle prism: full at local -Y (bottom) and +Z (back); `yaw` turns it so its tall side faces inward.
local function wedgeAt(parent, name, frame, center, size, yaw, color, opts)
	opts = table.clone(opts or {})
	opts.class = "WedgePart"
	return newPart(parent, name, size, frame * CFrame.new(center) * CFrame.Angles(0, yaw, 0), color, opts)
end

-- Invisible, non-collidable host part (prompts, emitters).
local function hostPart(parent, name, size, cframe)
	return newPart(parent, name, size, cframe, C.white, { look = "smooth", transparency = 1, shadow = false })
end

local function newModel(parent, name, pivot)
	local model = Instance.new("Model")
	model.Name = name
	model.WorldPivotData = pivot
	model.Parent = parent
	return model
end

-- The place streams (Workspace.StreamingEnabled): a statue, the fountain or the arch arrives whole, never half built.
local function streamWhole(model)
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
end

local function newFolder(parent, name)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function clearGenerated(container, prefix)
	for _, child in ipairs(container:GetChildren()) do
		if string.sub(child.Name, 1, #prefix) == prefix then
			child:Destroy()
		end
	end
end

local function numberSeq(stops)
	if type(stops) == "number" then
		return NumberSequence.new(stops)
	end
	local keypoints = {}
	for _, stop in ipairs(stops) do
		table.insert(keypoints, NumberSequenceKeypoint.new(stop[1], stop[2]))
	end
	return NumberSequence.new(keypoints)
end

local function colorSeq(stops)
	if typeof(stops) == "Color3" then
		return ColorSequence.new(stops)
	end
	local keypoints = {}
	for _, stop in ipairs(stops) do
		table.insert(keypoints, ColorSequenceKeypoint.new(stop[1], if type(stop[2]) == "string" then hex(stop[2]) else stop[2]))
	end
	return ColorSequence.new(keypoints)
end

-- ParticleEmitter with a built-in texture. spec: texture, rate, life {a,b}, speed {a,b}, spread {x,y}, accel, size,
-- transparency, color, light, direction (NormalId), orientation, drag, rotation {a,b}, rotSpeed {a,b}, zOffset
local function emitter(parent, name, spec)
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.TextureContent = Content.fromUri(spec.texture)
	e.Rate = spec.rate or 0
	e.Lifetime = NumberRange.new(spec.life[1], spec.life[2])
	e.Speed = NumberRange.new(spec.speed[1], spec.speed[2])
	e.SpreadAngle = Vector2.new(spec.spread and spec.spread[1] or 0, spec.spread and spec.spread[2] or 0)
	e.Acceleration = spec.accel or Vector3.new(0, 0, 0)
	e.Size = numberSeq(spec.size)
	e.Transparency = numberSeq(spec.transparency or 0)
	e.Color = colorSeq(spec.color or C.white)
	e.LightEmission = spec.light or 0
	e.LightInfluence = spec.lightInfluence or 0
	e.EmissionDirection = spec.direction or Enum.NormalId.Top
	if spec.orientation then
		e.Orientation = spec.orientation
	end
	e.Drag = spec.drag or 0
	if spec.rotation then
		e.Rotation = NumberRange.new(spec.rotation[1], spec.rotation[2])
	end
	if spec.rotSpeed then
		e.RotSpeed = NumberRange.new(spec.rotSpeed[1], spec.rotSpeed[2])
	end
	e.ZOffset = spec.zOffset or 0
	e.Enabled = true
	e.Parent = parent
	return e
end

local function pointLight(parent, name, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Name = name
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = parent
	return light
end

-- ProximityPrompt in the hub's custom prompt style (Game.ProximityPromptScript themes).
local function prompt(host, spec)
	local p = Instance.new("ProximityPrompt")
	p.Name = "ProximityPrompt"
	p.ActionText = spec.action
	p.ObjectText = spec.object
	p.MaxActivationDistance = spec.distance or 10
	p.HoldDuration = 0
	p.RequiresLineOfSight = false
	p.ClickablePrompt = true
	p.KeyboardKeyCode = spec.key or Enum.KeyCode.E
	p.Style = Enum.ProximityPromptStyle.Custom
	p.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	p.UIOffset = Vector2.new(0, 0)
	p.Enabled = true
	if spec.theme then
		p:SetAttribute("Theme", spec.theme)
	end
	p.Parent = host
	return p
end

---------------------------------------------------------------------------------------------------
-- GUI helpers (sign faces in the remodel's look)
---------------------------------------------------------------------------------------------------

local function seq(stops)
	local keypoints = {}
	for _, stop in ipairs(stops) do
		table.insert(keypoints, ColorSequenceKeypoint.new(stop[1], hex(stop[2])))
	end
	return ColorSequence.new(keypoints)
end

local function ensureChild(parent, className, name)
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == name and child.ClassName == className then
			return child
		end
	end
	local child = Instance.new(className)
	child.Name = name
	child.Parent = parent
	return child
end

local function setCorner(inst, radius)
	local corner = inst:FindFirstChildOfClass("UICorner")
	if corner == nil then
		corner = Instance.new("UICorner")
		corner.Name = "UICorner"
		corner.Parent = inst
	end
	local r = if typeof(radius) == "UDim" then radius else UDim.new(radius, 0)
	corner.TopLeftRadius = r
	corner.TopRightRadius = r
	corner.BottomLeftRadius = r
	corner.BottomRightRadius = r
	return corner
end

local function setGradient(inst, name, stops, rotation, transparency)
	local gradient = ensureChild(inst, "UIGradient", name)
	gradient.Color = seq(stops)
	gradient.Rotation = rotation or 90
	gradient.Offset = Vector2.new(0, 0)
	gradient.Transparency = numberSeq(transparency or 0)
	gradient.Enabled = true
	return gradient
end

local function setStroke(inst, name, color, thickness, mode, scaled)
	local stroke = ensureChild(inst, "UIStroke", name)
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = if mode == "Contextual" then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border
	stroke.StrokeSizingMode = if scaled then Enum.StrokeSizingMode.ScaledSize else Enum.StrokeSizingMode.FixedSize
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Transparency = 0
	stroke.Enabled = true
	return stroke
end

local function newFrame(parent, name, position, size, color, transparency, zIndex)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency or 0
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.ZIndex = zIndex or 1
	frame.Parent = parent
	return frame
end

local function newLabel(parent, name, text, position, size, opts)
	opts = opts or {}
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.FontFace = opts.font or FREDOKA
	label.TextScaled = true
	label.TextWrapped = true -- TextScaled without TextWrapped renders at the tiny fixed TextSize
	label.TextColor3 = opts.color or C.white
	label.TextStrokeTransparency = 1
	label.TextXAlignment = opts.align or Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Position = position
	label.Size = size
	label.ZIndex = opts.zIndex or 2
	label.Parent = parent
	if opts.stroke then
		setStroke(label, "UIStroke", opts.stroke[1], opts.stroke[2], "Contextual", true)
	end
	return label
end

local function newSurface(part, name, face, pixelsPerStud, maxDistance)
	local surface = Instance.new("SurfaceGui")
	surface.Name = name
	surface.Face = face
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = pixelsPerStud
	surface.LightInfluence = 0
	surface.Brightness = 1.1
	surface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	surface.ClipsDescendants = true
	surface.MaxDistance = maxDistance or 220
	surface.AlwaysOnTop = false
	surface.Parent = part
	return surface
end

local function studOverlay(parent, color, transparency, tile, zIndex)
	local studs = Instance.new("ImageLabel")
	studs.Name = "HubStuds"
	studs.BackgroundTransparency = 1
	studs.BorderSizePixel = 0
	studs.Size = UDim2.fromScale(1, 1)
	studs.ImageContent = Content.fromUri(STUD_TILE)
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.fromOffset(tile, tile)
	studs.ImageColor3 = color
	studs.ImageTransparency = transparency
	studs.ZIndex = zIndex or 1
	studs.Parent = parent
	return studs
end

-- Glossy rounded sign face (white rim, vertical gradient, faint studs, top gloss). Returns the inner frame.
local function roundedFace(gui, radiusPx, rimPx, stops, studColor)
	local rim = newFrame(gui, "Rim", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), C.white, 0, 1)
	setCorner(rim, UDim.new(0, radiusPx))
	local inner = newFrame(rim, "Fill", UDim2.fromOffset(rimPx, rimPx), UDim2.new(1, -2 * rimPx, 1, -2 * rimPx), C.white, 0, 1)
	setCorner(inner, UDim.new(0, math.max(radiusPx - rimPx, 2)))
	setGradient(inner, "UIGradient", stops, 90)
	local studs = studOverlay(inner, studColor, 0.9, 26, 1)
	setCorner(studs, UDim.new(0, math.max(radiusPx - rimPx, 2)))
	local gloss = newFrame(inner, "Gloss", UDim2.fromScale(0.03, 0.05), UDim2.fromScale(0.94, 0.42), C.white, 0, 1)
	setCorner(gloss, UDim.new(0, math.max(radiusPx - rimPx - 4, 2)))
	setGradient(gloss, "UIGradient", { { 0, "#ffffff" }, { 1, "#ffffff" } }, 90, { { 0, 0.62 }, { 1, 0.97 } })
	return inner
end

-- Big readable sign text: white FredokaOne, thick dark outline and a dark drop copy below it.
local function signText(parent, name, text, position, size, strokeColor, opts)
	opts = opts or {}
	local drop = newLabel(parent, name .. "Drop", text, position + UDim2.fromScale(0, opts.drop or 0.045), size, {
		color = strokeColor, stroke = { strokeColor, opts.thickness or 0.14 }, zIndex = 4,
	})
	local face = newLabel(parent, name, text, position, size, {
		color = opts.color or C.white, stroke = { strokeColor, opts.thickness or 0.14 }, zIndex = 5,
	})
	for _, label in ipairs({ drop, face }) do
		local limit = Instance.new("UITextSizeConstraint")
		limit.MinTextSize = 1
		limit.MaxTextSize = opts.maxSize or 120
		limit.Parent = label
	end
	return face, drop
end

-- A rounded sign board (outline ring + coloured board) in the XY plane of `frame` centred at (cx, cy), readable from
-- both sides: returns the invisible face carrier whose Front / Back SurfaceGuis hold the text (fill(inner, faceId)).
local function signBoard(parent, name, frame, cx, cy, w, h, radius, palette, fill, opts)
	opts = opts or {}
	local smooth = { look = "smooth", collide = false }
	local outline = 0.3
	roundedSlab(parent, name .. "Outline", frame, cx, cy, w + 2 * outline, h + 2 * outline, -0.24, 0.24, radius + outline, palette.outline, smooth)
	roundedSlab(parent, name .. "Board", frame, cx, cy, w, h, -0.32, 0.32, radius, palette.board, smooth)
	local carrier = boxIn(parent, name .. "Face", frame, cx - w / 2, cx + w / 2, cy - h / 2, cy + h / 2, -0.34, 0.34, palette.board,
		{ look = "smooth", transparency = 1, shadow = false })
	local pps = opts.pps or 40
	for _, faceId in ipairs(opts.faces or { Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = newSurface(carrier, name .. "Gui", faceId, pps, opts.maxDistance)
		local inner = roundedFace(gui, math.floor(radius * pps), opts.rim or 9, palette.face, palette.studs)
		fill(inner, faceId)
	end
	return carrier
end

---------------------------------------------------------------------------------------------------
-- Shared transforms
---------------------------------------------------------------------------------------------------

local function baseParts(root)
	local list = {}
	if root:IsA("BasePart") then
		table.insert(list, root)
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

-- Rigid move of every BasePart under the roots by T (world), models' pivots too.
local function moveRigid(roots, T)
	local n = 0
	for _, root in ipairs(roots) do
		for _, part in ipairs(baseParts(root)) do
			part.CFrame = T * part.CFrame
			n += 1
		end
		local models = if root:IsA("Model") then { root } else {}
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("Model") then
				table.insert(models, d)
			end
		end
		for _, model in ipairs(models) do
			local ok, pivot = pcall(function()
				return model.WorldPivotData
			end)
			if ok and typeof(pivot) == "CFrame" then
				model.WorldPivotData = T * pivot
			end
		end
	end
	return n
end

local function worldAabb(part)
	local cf, half = part.CFrame, part.Size * 0.5
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local ext = Vector3.new(
		math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
		math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
		math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z
	)
	return cf.Position - ext, cf.Position + ext
end

local function groupAabb(root, visibleOnly)
	local mn, mx
	for _, part in ipairs(baseParts(root)) do
		if not visibleOnly or part.Transparency < 1 then
			local a, b = worldAabb(part)
			mn = if mn then mn:Min(a) else a
			mx = if mx then mx:Max(b) else b
		end
	end
	return mn, mx
end

---------------------------------------------------------------------------------------------------
-- 1. Sell stand
---------------------------------------------------------------------------------------------------

-- One walkable tier: a flat top slab, a wedge ramp on each side (tall side inward) and a gold block on each corner.
local function bevelTier(parent, name, frame, spec, y0, height, colors)
	local b = spec.bevel
	local x0, x1, z0, z1 = -spec.x, spec.x, spec.front, spec.back
	local solid = { collide = true }
	boxIn(parent, name .. "Top", frame, x0 + b, x1 - b, y0, y0 + height, z0 + b, z1 - b, colors.body, solid)
	local lengthX, lengthZ = (x1 - x0) - 2 * b, (z1 - z0) - 2 * b
	local cy = y0 + height / 2
	local cxm, czm = (x0 + x1) / 2, (z0 + z1) / 2
	-- front (outward -Z): tall side toward +Z; back: turned 180; right (+X): -90; left (-X): +90
	wedgeAt(parent, name .. "Bevel", frame, Vector3.new(cxm, cy, z0 + b / 2), Vector3.new(lengthX, height, b), 0, colors.bevel, solid)
	wedgeAt(parent, name .. "Bevel", frame, Vector3.new(cxm, cy, z1 - b / 2), Vector3.new(lengthX, height, b), math.pi, colors.bevel, solid)
	wedgeAt(parent, name .. "Bevel", frame, Vector3.new(x1 - b / 2, cy, czm), Vector3.new(lengthZ, height, b), -math.pi / 2, colors.bevel, solid)
	wedgeAt(parent, name .. "Bevel", frame, Vector3.new(x0 + b / 2, cy, czm), Vector3.new(lengthZ, height, b), math.pi / 2, colors.bevel, solid)
	for _, cx in ipairs({ x0 + b / 2, x1 - b / 2 }) do
		for _, cz in ipairs({ z0 + b / 2, z1 - b / 2 }) do
			blockAt(parent, name .. "Corner", frame, Vector3.new(cx, cy, cz), Vector3.new(b, height, b), colors.corner, solid)
		end
	end
end

local SELL_SIGN = {
	board = hex("#e8262e"), outline = hex("#4a0610"), studs = hex("#ffd0d0"),
	face = { { 0, "#ff8f8f" }, { 0.45, "#ff3444" }, { 1, "#c40f24" } },
}

local function buildSellExtras(sell, ground, groundY)
	local tier = Step.SELL_TIER
	-- pedestal
	bevelTier(sell, "HubSellPedestal1", ground, Step.SELL_PEDESTAL[1], 0, tier, { body = C.navy, bevel = C.navyLight, corner = C.gold })
	bevelTier(sell, "HubSellPedestal2", ground, Step.SELL_PEDESTAL[2], tier, tier, { body = C.navyLight, bevel = C.navyBright, corner = C.gold })
	-- gold trim strip along the tier-2 front edge (just proud of its top)
	local t2 = Step.SELL_PEDESTAL[2]
	boxIn(sell, "HubSellPedestalTrim", ground, -t2.x + t2.bevel, t2.x - t2.bevel, 2 * tier, 2 * tier + 0.04, t2.front + t2.bevel,
		t2.front + t2.bevel + 0.3, C.gold, { collide = false, shadow = false })

	-- glowing floor zone in front of the counter (on the tier-2 top)
	local top = ground * CFrame.new(0, 2 * tier, 0)
	local zx, z0, z1 = 4.3, -7.7, -3.1
	local pad = boxIn(sell, "HubSellZonePad", top, -zx, zx, 0, 0.06, z0, z1, C.cyan,
		{ look = "smooth", transparency = 0.55, shadow = false })
	local rim = 0.28
	local neon = { look = "neon", transparency = 0.2, shadow = false }
	boxIn(sell, "HubSellZoneRim", top, -zx - rim, zx + rim, 0, 0.1, z0 - rim, z0, C.cyanSoft, neon)
	boxIn(sell, "HubSellZoneRim", top, -zx - rim, zx + rim, 0, 0.1, z1, z1 + rim, C.cyanSoft, neon)
	boxIn(sell, "HubSellZoneRim", top, -zx - rim, -zx, 0, 0.1, z0, z1, C.cyanSoft, neon)
	boxIn(sell, "HubSellZoneRim", top, zx, zx + rim, 0, 0.1, z0, z1, C.cyanSoft, neon)
	-- floor emblem: a gold "$" coin (point-symmetric, reads the same from every side)
	local floorGui = newSurface(pad, "HubSellZoneGui", Enum.NormalId.Top, 30, 160)
	floorGui.Brightness = 1.3
	local coin = newFrame(floorGui, "Coin", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 0.86), C.white, 0, 2)
	coin.AnchorPoint = Vector2.new(0.5, 0.5)
	local coinAspect = Instance.new("UIAspectRatioConstraint")
	coinAspect.AspectRatio = 1
	coinAspect.Parent = coin
	setCorner(coin, 0.5)
	setGradient(coin, "UIGradient", { { 0, "#fff27a" }, { 0.5, "#ffc21a" }, { 1, "#ff9000" } }, 90)
	setStroke(coin, "UIStroke", hex("#6b3300"), 5, "Border", false)
	signText(coin, "Dollar", "$", UDim2.fromScale(0.12, 0.08), UDim2.fromScale(0.76, 0.84), hex("#6b3300"), { drop = 0, thickness = 0.1 })
	for _, name in ipairs({ "DollarDrop" }) do
		local d = coin:FindFirstChild(name)
		if d then
			d:Destroy() -- a drop copy would break the point symmetry
		end
	end
	emitter(pad, "Shimmer", {
		texture = TEX.sparkle, rate = 9, life = { 1.2, 2.2 }, speed = { 1, 2.4 }, spread = { 12, 12 },
		size = { { 0, 0.25 }, { 0.5, 0.45 }, { 1, 0 } }, transparency = { { 0, 0.15 }, { 1, 1 } },
		color = { { 0, "#7ffcff" }, { 1, "#ffe27a" } }, light = 1,
	})
	pointLight(pad, "Glow", hex("#6ff6ff"), 13, 1.1)

	-- SELL HEROES pylon on the spawn-side BACK corner of tier 1 (its gold corner block is the base): a tall post with a
	-- billboard above the stall's roofline and a gold "$" coin on top, seen down the street and from the spawn without
	-- ever covering the stall's own SELL sign or its counter
	local t1 = Step.SELL_PEDESTAL[1]
	local px, pz = t1.x - t1.bevel / 2, t1.back - t1.bevel / 2
	local solid = { collide = true }
	boxIn(sell, "HubSellPylonPost", ground, px - 0.45, px + 0.45, tier, 15.4, pz - 0.45, pz + 0.45, C.navy, solid)
	boxIn(sell, "HubSellPylonCollar", ground, px - 0.6, px + 0.6, 7.6, 7.9, pz - 0.6, pz + 0.6, C.gold, {})
	local signFrame = ground * CFrame.new(px, 0, pz)
	signBoard(sell, "HubSellPylonSign", signFrame, 0, 17.0, 6.2, 3.2, 0.85, SELL_SIGN, function(inner)
		signText(inner, "Title", "SELL", UDim2.fromScale(0.06, 0.02), UDim2.fromScale(0.88, 0.6), hex("#5c0010"), { thickness = 0.13 })
		signText(inner, "Sub", "HEROES", UDim2.fromScale(0.14, 0.6), UDim2.fromScale(0.72, 0.34), hex("#5c0010"),
			{ color = hex("#ffe45c"), drop = 0.03, thickness = 0.13 })
	end)
	-- gold coin crown with a "$" on both faces
	local coinCenter = Vector3.new(px, 20.85, pz)
	cylinderIn(sell, "HubSellPylonCoin", ground, coinCenter, 0.5, 3.1, "z", C.gold, {})
	cylinderIn(sell, "HubSellPylonCoinRim", ground, coinCenter, 0.36, 3.5, "z", C.goldDark, {})
	local coinFace = boxIn(sell, "HubSellPylonCoinFace", ground, px - 1.3, px + 1.3, 19.55, 22.15, pz - 0.27, pz + 0.27, C.gold,
		{ look = "smooth", transparency = 1, shadow = false })
	for _, faceId in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = newSurface(coinFace, "HubSellCoinGui", faceId, 40, 260)
		signText(gui, "Dollar", "$", UDim2.fromScale(0.1, 0.04), UDim2.fromScale(0.8, 0.9), hex("#6b3300"),
			{ color = hex("#fff3a0"), drop = 0.03, thickness = 0.1 })
	end
	gemAt(sell, "HubSellPylonGem", ground, Vector3.new(px, 23.1, pz), 0.8, C.goldPale, {})
end

local function reseatSellStand(ws, groundY)
	local stands = ws:FindFirstChild("Stands")
	local sell = stands and findPath(stands, "Models/Sell Stands")
	local sellAll = stands and findPath(stands, "Prompts/SellAll")
	local sellHeld = stands and findPath(stands, "Prompts/SellHeldAsset")
	if not (sell and sellAll and sellHeld) then
		warnf("Stands.Models.Sell Stands / Prompts.SellAll / Prompts.SellHeldAsset missing; Sell stand not moved")
		return false
	end
	local anchor = Vector3.new(Step.SELL_STAND.X, groundY, Step.SELL_STAND.Z)
	local ground = facingFrame(anchor, Step.SELL_FACING.X, Step.SELL_FACING.Z)
	local target = ground * CFrame.new(0, 2 * Step.SELL_TIER, 0)

	-- earlier runs' extras go first (idempotent), then the stall moves as one rigid piece
	clearGenerated(sell, "HubSell")
	local ok, old = pcall(function()
		return sell.WorldPivotData
	end)
	if not (ok and typeof(old) == "CFrame") then
		local mn, mx = groupAabb(sell)
		old = CFrame.new(Vector3.new((mn.X + mx.X) / 2, groundY, (mn.Z + mx.Z) / 2))
		warnf("Sell Stands has no pivot; moved from its bounds centre")
	end
	local T = target * old:Inverse()
	local moved = moveRigid({ sell }, T)
	sell.WorldPivotData = target
	for _, child in ipairs(sell:GetChildren()) do
		if child.Name == "HubStallGlow" then
			child:Destroy() -- the round glow disc gives way to the sell zone
		end
	end
	for name, offset in pairs(Step.SELL_PROMPTS) do
		local part = if name == "SellAll" then sellAll else sellHeld
		part.CFrame = target * CFrame.new(offset)
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.Transparency = 1
	end
	buildSellExtras(sell, ground, groundY)
	sell:SetAttribute("HubLayout", "post_hub_zlayout")
	local mn, mx = groupAabb(sell)
	log("Sell stand: %d stall parts re-seated on the pedestal at (%.1f, %.1f) facing +Z; stand X %.1f..%.1f Z %.1f..%.1f; prompts at the counter.",
		moved, anchor.X, anchor.Z, mn.X, mx.X, mn.Z, mx.Z)
	return true
end

---------------------------------------------------------------------------------------------------
-- 2. Free Gift
---------------------------------------------------------------------------------------------------

local function reseatFreeGift(ws, groundY)
	local freeGift = findPath(ws, "Hub/FreeGift")
	local board = freeGift and freeGift:FindFirstChild("ClaimSign")
	local chest = freeGift and freeGift:FindFirstChild("GiftChest")
	if not (board and chest) then
		warnf("Workspace.Hub.FreeGift ClaimSign / GiftChest missing; Free Gift not moved")
		return false
	end
	local ok, old = pcall(function()
		return board.WorldPivotData
	end)
	if not (ok and typeof(old) == "CFrame") then
		warnf("Hub.FreeGift.ClaimSign has no pivot; Free Gift not moved")
		return false
	end
	local target = facingFrame(Vector3.new(Step.FREE_GIFT_BOARD.X, groundY, Step.FREE_GIFT_BOARD.Z), Step.FREE_GIFT_FACING.X, Step.FREE_GIFT_FACING.Z)
	local T = target * old:Inverse()
	local roots = { freeGift }
	local gift = findPath(ws, "__OBJECTS/GroupReward")
	if gift and gift:IsA("BasePart") then
		table.insert(roots, gift)
	else
		warnf("__OBJECTS.GroupReward missing; the chest keeps only its click / tap opener")
	end
	local moved = moveRigid(roots, T)
	board.WorldPivotData = target
	freeGift:SetAttribute("HubLayout", "post_hub_zlayout")
	local cp = chest.WorldPivotData.Position
	log("Free Gift: %d parts moved in front of the spawn; board at (%.1f, %.1f), chest at (%.1f, %.1f), facing +Z.", moved,
		target.Position.X, target.Position.Z, cp.X, cp.Z)
	return true
end

---------------------------------------------------------------------------------------------------
-- 3. Hero Park
---------------------------------------------------------------------------------------------------

local function bench(parent, index, frame)
	local model = newModel(parent, "Bench_" .. index, frame)
	-- the Seat is the only solid / touchable piece (players sit on it); front = -Z (the sitter looks that way)
	local seat = boxIn(model, "Seat", frame, -2.3, 2.3, 1.38, 1.72, -0.75, 0.75, C.wood, { class = "Seat", collide = true, touch = true })
	seat.Disabled = false
	for _, x in ipairs({ -1.95, 1.95 }) do
		boxIn(model, "Leg", frame, x - 0.22, x + 0.22, 0, 1.38, -0.65, 0.65, C.navy, {})
		boxIn(model, "BackPost", frame, x - 0.18, x + 0.18, 1.38, 3.35, 0.62, 0.92, C.navy, {})
		blockAt(model, "PostCap", frame, Vector3.new(x, 3.45, 0.77), Vector3.new(0.46, 0.2, 0.46), C.gold, {})
	end
	for i, y in ipairs({ 2.2, 2.9 }) do
		newPart(model, "BackBoard", Vector3.new(4.6, 0.48, 0.24), frame * CFrame.new(0, y, 0.72 + 0.05 * i) * CFrame.Angles(math.rad(8), 0, 0),
			if i == 1 then C.wood else C.woodTop, {})
	end
	return model
end

local function lamp(parent, index, x, y, z)
	local frame = CFrame.new(x, y, z)
	local model = newModel(parent, "Lamp_" .. index, frame)
	boxIn(model, "Base", frame, -0.65, 0.65, 0, 0.5, -0.65, 0.65, C.navy, { collide = true })
	pillarIn(model, "Pole", frame, 0, 0, 0.5, 8.0, 0.45, C.navy, { collide = true })
	boxIn(model, "Collar", frame, -0.4, 0.4, 6.0, 6.3, -0.4, 0.4, C.gold, {})
	boxIn(model, "Holder", frame, -0.6, 0.6, 7.95, 8.2, -0.6, 0.6, C.gold, {})
	local lantern = boxIn(model, "Lantern", frame, -0.45, 0.45, 8.2, 9.45, -0.45, 0.45, C.cream, { look = "neon", shadow = false })
	boxIn(model, "Cap", frame, -0.7, 0.7, 9.45, 9.8, -0.7, 0.7, C.gold, {})
	gemAt(model, "Finial", frame, Vector3.new(0, 10.15, 0), 0.5, C.goldPale, {})
	pointLight(lantern, "Light", hex("#ffd89a"), 16, 0.9)
	return model
end

-- Low-poly tree: trunk + three stacked leaf blocks alternately turned 45 degrees. Nothing solid.
local function tree(parent, index, x, y, z, scale, yawDeg)
	local s = scale or 1
	local frame = yawFrame(x, y, z, math.rad(yawDeg or 0))
	local model = newModel(parent, "Tree_" .. index, frame)
	local ghost = { collide = false }
	boxIn(model, "Trunk", frame, -0.45 * s, 0.45 * s, 0, 4.4 * s, -0.45 * s, 0.45 * s, C.woodPost, ghost)
	blockAt(model, "Leaves", frame, Vector3.new(0, 5.4 * s, 0), Vector3.new(5 * s, 3 * s, 5 * s), C.leaf, ghost, math.pi / 4)
	blockAt(model, "Leaves", frame, Vector3.new(0, 7.6 * s, 0), Vector3.new(4 * s, 2.6 * s, 4 * s), C.leafMid, ghost)
	blockAt(model, "Leaves", frame, Vector3.new(0, 9.35 * s, 0), Vector3.new(2.3 * s, 1.7 * s, 2.3 * s), C.leafLight, ghost, math.pi / 4)
	return model
end

local FLOWER_COLORS = { C.pink, C.yellow, C.red, C.white }
local function planter(parent, index, x, y, z)
	local frame = CFrame.new(x, y, z)
	local model = newModel(parent, "Planter_" .. index, frame)
	boxIn(model, "Box", frame, -1.6, 1.6, 0, 1.1, -1.6, 1.6, C.navy, { collide = true })
	boxIn(model, "Rim", frame, -1.75, 1.75, 1.1, 1.35, -1.75, 1.75, C.gold, {})
	boxIn(model, "Hedge", frame, -1.4, 1.4, 1.1, 2.0, -1.4, 1.4, C.hedge, {})
	local i = 0
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			i += 1
			blockAt(model, "Flower", frame, Vector3.new(sx * 0.7, 2.15, sz * 0.7), Vector3.new(0.55, 0.55, 0.55), FLOWER_COLORS[i], {}, math.pi / 4)
		end
	end
	return model
end

local function bollard(parent, index, x, y, z)
	local frame = CFrame.new(x, y, z)
	local model = newModel(parent, "Bollard_" .. index, frame)
	pillarIn(model, "Post", frame, 0, 0, 0, 2.0, 0.9, C.navy, { collide = true })
	pillarIn(model, "Cap", frame, 0, 0, 2.0, 2.3, 1.05, C.gold, {})
	return model
end

-- Frame at `center` turned toward `target` (XZ), front = -Z.
local function faceToward(center, target)
	local d = target - center
	return facingFrame(center, d.X, d.Z)
end

local function ringPoint(center, radius, degrees, y)
	local a = math.rad(degrees)
	return Vector3.new(center.X + radius * math.cos(a), y, center.Z + radius * math.sin(a))
end

---------------------------------------------------------------------------------------------------

local function buildPaving(park, g)
	local model = newModel(park, "Paving", CFrame.new(0, g, Step.PARK_AXIS_Z))
	local walk = { collide = true }
	local z0 = Step.PARK_AXIS_Z
	local F, G = Step.PARK_FOUNTAIN, Step.PARK_GARDEN
	-- avenue slab + red carpet with gold edges (each layer a little higher: nothing is coplanar)
	newPart(model, "AvenueSlab", Vector3.new(49, 0.15, 26), CFrame.new(8.5, g + 0.075, z0), C.stone, walk)
	newPart(model, "Carpet", Vector3.new(50, 0.19, 6), CFrame.new(8, g + 0.095, z0), C.carpet, walk)
	for _, dz in ipairs({ -3.15, 3.15 }) do
		newPart(model, "CarpetEdge", Vector3.new(50, 0.2, 0.3), CFrame.new(8, g + 0.1, z0 + dz), C.gold, walk)
	end
	-- fountain plaza: outer navy ring, stone disc, navy + gold inner bands, stone centre
	local function disc(name, center, radius, top, color)
		return cylinderIn(model, name, CFrame.new(center.X, g, center.Z), Vector3.new(0, top / 2, 0), top, 2 * radius, "y", color, walk)
	end
	disc("PlazaRim", F, 20.6, 0.14, C.navyLight)
	disc("PlazaDisc", F, 20, 0.16, C.stone)
	disc("PlazaBand", F, 13, 0.18, C.navyLight)
	disc("PlazaBandGold", F, 12.2, 0.2, C.gold)
	disc("PlazaCentre", F, 11.4, 0.22, C.stone)
	-- garden circle + the path between the plaza and the garden
	disc("GardenRim", G, 12.6, 0.14, C.gold)
	disc("GardenDisc", G, 12, 0.16, C.stone)
	disc("GardenBand", G, 7.4, 0.18, C.navyLight)
	disc("GardenCentre", G, 6.6, 0.2, C.stoneWarm)
	newPart(model, "GardenPath", Vector3.new(13, 0.17, 6), CFrame.new((F.X - 20 + G.X + 12) / 2, g + 0.085, z0), C.stoneWarm, walk)
	return model
end

local ARCH_SIGN = {
	board = hex("#1e8cff"), outline = hex("#0b1b3d"), studs = hex("#dff3ff"),
	face = { { 0, "#8fe3ff" }, { 0.45, "#3fa9ff" }, { 1, "#2d62ff" } },
}

local function buildArch(park, g)
	local frame = facingFrame(Vector3.new(Step.PARK_ARCH_X, g, Step.PARK_AXIS_Z), 1, 0) -- front (local -Z) = east
	local model = newModel(park, "Arch", frame)
	streamWhole(model)
	local solid = { collide = true }
	for _, x in ipairs({ -9.5, 9.5 }) do
		boxIn(model, "Plinth", frame, x - 1.7, x + 1.7, 0, 1.2, -1.7, 1.7, C.gold, solid)
		boxIn(model, "Pillar", frame, x - 1.3, x + 1.3, 1.2, 14.4, -1.3, 1.3, C.navy, solid)
		boxIn(model, "Capital", frame, x - 1.6, x + 1.6, 14.4, 15.1, -1.6, 1.6, C.gold, {})
		-- hanging banners on both faces of each pillar
		for _, side in ipairs({ -1, 1 }) do
			local z = side * 1.36
			boxIn(model, "Banner", frame, x - 1.0, x + 1.0, 6.2, 12.6, z - 0.06, z + 0.06, C.red, {})
			boxIn(model, "BannerStripe", frame, x - 1.02, x + 1.02, 6.2, 6.6, z - 0.08, z + 0.08, C.gold, {})
			gemAt(model, "BannerGem", frame, Vector3.new(x, 10.6, side * 1.55), 0.8, C.gold, {})
		end
	end
	boxIn(model, "Beam", frame, -11.4, 11.4, 15.1, 16.9, -1.4, 1.4, C.navyLight, {})
	boxIn(model, "BeamTrim", frame, -11.6, 11.6, 16.9, 17.2, -1.55, 1.55, C.gold, {})
	for _, x in ipairs({ -10.8, 10.8 }) do
		gemAt(model, "BeamGem", frame, Vector3.new(x, 17.75, 0), 0.9, C.gold, {})
	end
	signBoard(model, "Sign", frame, 0, 19.5, 15, 4.2, 1.1, ARCH_SIGN, function(inner)
		signText(inner, "Title", "HERO PARK", UDim2.fromScale(0.05, 0.03), UDim2.fromScale(0.9, 0.62), hex("#0b1b3d"), { thickness = 0.12 })
		signText(inner, "Sub", "HALL OF HEROES", UDim2.fromScale(0.2, 0.64), UDim2.fromScale(0.6, 0.3), hex("#0b1b3d"),
			{ color = hex("#ffe45c"), drop = 0.03, thickness = 0.12 })
	end)
	local crown = gemAt(model, "Crown", frame, Vector3.new(0, 22.6, 0), 1.6, C.gold, {})
	emitter(crown, "Sparkles", {
		texture = TEX.sparkle, rate = 3, life = { 1.2, 2 }, speed = { 0.5, 1.4 }, spread = { 60, 60 },
		size = { { 0, 0.4 }, { 0.5, 0.7 }, { 1, 0 } }, transparency = { { 0, 0.1 }, { 1, 1 } }, color = C.goldPale, light = 1,
	})
	return model
end

local function buildSignpost(park, g)
	local frame = facingFrame(Vector3.new(31, g, -163.5), 0, 1) -- faces the players coming down the east corridor
	local model = newModel(park, "Signpost", frame)
	boxIn(model, "Post", frame, -0.3, 0.3, 0, 6.8, -0.3, 0.3, C.woodPost, { collide = true })
	boxIn(model, "PostCap", frame, -0.45, 0.45, 6.8, 7.1, -0.45, 0.45, C.gold, {})
	signBoard(model, "Board", frame, 0, 5.2, 5.2, 2.3, 0.7, ARCH_SIGN, function(inner)
		signText(inner, "Title", "HERO PARK", UDim2.fromScale(0.05, 0.04), UDim2.fromScale(0.9, 0.56), hex("#0b1b3d"), { thickness = 0.12 })
		signText(inner, "Sub", "STATUES  FOUNTAIN", UDim2.fromScale(0.08, 0.6), UDim2.fromScale(0.84, 0.32), hex("#0b1b3d"),
			{ color = hex("#ffe45c"), drop = 0.03, thickness = 0.12 })
	end)
	return model
end

-- Hero statue: a clone of the whole rig (cloned once: its joints stay inside the clone), scripts / sounds / effects /
-- animation stripped, every part anchored and non-collidable, no nameplate, no HeroId (hero-rig scripts ignore it).
local STRIP = {
	"LuaSourceContainer", "Sound", "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles", "Light", "BillboardGui",
	"SurfaceGui", "ProximityPrompt", "ClickDetector", "Highlight", "AnimationController", "Animator", "ForceField",
}
local function statueModel(template, heroId)
	local model = template:Clone()
	model.Name = "Hero"
	local doomed = {}
	for _, d in ipairs(model:GetDescendants()) do
		for _, className in ipairs(STRIP) do
			if d:IsA(className) then
				table.insert(doomed, d)
				break
			end
		end
	end
	for _, d in ipairs(doomed) do
		if d.Parent ~= nil then
			d:Destroy()
		end
	end
	for key in pairs(model:GetAttributes()) do
		model:SetAttribute(key, nil)
	end
	model:SetAttribute("HeroParkStatue", heroId)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		elseif d:IsA("Humanoid") then
			d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			d.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			pcall(function()
				d.NameDisplayDistance = 0
				d.HealthDisplayDistance = 0
				d.BreakJointsOnDeath = false
				d.RequiresNeck = false
			end)
			pcall(function()
				d.EvaluateStateMachine = false
			end)
		end
	end
	return model
end

-- Uniform scale of a rig about (0, baseY, 0) of its authored space (no ScaleTo in Lune): part sizes and positions,
-- joint offsets, attachments (and bones), FileMesh scales and mesh offsets; everything else is size-relative.
local function scaleCFrame(cf, s)
	return CFrame.new(cf.Position * s) * (cf - cf.Position)
end
local function scaleRig(model, s, baseY)
	local origin = Vector3.new(0, baseY, 0)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local cf = d.CFrame
			d.Size = d.Size * s
			d.CFrame = CFrame.new(origin + (cf.Position - origin) * s) * (cf - cf.Position)
		elseif d:IsA("JointInstance") then
			d.C0 = scaleCFrame(d.C0, s)
			d.C1 = scaleCFrame(d.C1, s)
		elseif d:IsA("Attachment") then
			d.CFrame = scaleCFrame(d.CFrame, s)
		elseif d:IsA("SpecialMesh") then
			if d.MeshType == Enum.MeshType.FileMesh then
				d.Scale = d.Scale * s
			end
			d.Offset = d.Offset * s
		elseif d:IsA("Texture") then
			d.StudsPerTileU = d.StudsPerTileU * s
			d.StudsPerTileV = d.StudsPerTileV * s
		end
	end
end

local function plaqueGui(part, spec)
	local gui = newSurface(part, "PlaqueGui", Enum.NormalId.Front, 60, 70)
	local accent = hex(spec.accent)
	local panel = newFrame(gui, "Panel", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), C.navyDark, 0, 1)
	setCorner(panel, 0.18)
	setStroke(panel, "UIStroke", C.gold, 4, "Border", false)
	local band = newFrame(panel, "Band", UDim2.fromScale(0, 0.64), UDim2.fromScale(1, 0.36), accent, 0, 2)
	setCorner(band, 0.18)
	studOverlay(panel, hex("#6f8fd6"), 0.85, 22, 1)
	signText(panel, "Name", spec.name, UDim2.fromScale(0.05, 0.04), UDim2.fromScale(0.9, 0.56), C.ink, { drop = 0.03, thickness = 0.12 })
	newLabel(panel, "Team", spec.team .. "  \u{2022}  STAGE " .. spec.stage, UDim2.fromScale(0.06, 0.66), UDim2.fromScale(0.88, 0.3), {
		color = C.white, stroke = { C.ink, 0.12 }, zIndex = 6,
	})
end

local function buildStatues(park, g, rs)
	local folder = newModel(park, "Statues", CFrame.new(8, g, Step.PARK_AXIS_Z))
	local assetModels = rs and rs:FindFirstChild("AssetModels")
	local built = 0
	local solid = { collide = true }
	for _, spec in ipairs(Step.STATUES) do
		local z = Step.PARK_ROW_Z[spec.row]
		-- face the avenue, turned toward the arch (east)
		local dirZ = if spec.row == "north" then -1 else 1
		local dir = Vector3.new(math.sin(Step.STATUE_TURN), 0, dirZ * math.cos(Step.STATUE_TURN))
		local frame = facingFrame(Vector3.new(spec.x, g, z), dir.X, dir.Z)
		local model = newModel(folder, "Statue_" .. spec.id, frame)
		model:SetAttribute("StatueOf", spec.id)
		streamWhole(model)
		boxIn(model, "PedestalBase", frame, -2.4, 2.4, 0, 0.6, -2.4, 2.4, C.navy, solid)
		boxIn(model, "PedestalBody", frame, -2.0, 2.0, 0.6, 3.0, -2.0, 2.0, C.navyLight, solid)
		boxIn(model, "PedestalBand", frame, -2.07, 2.07, 0.95, 1.25, -2.07, 2.07, C.gold, {})
		boxIn(model, "PedestalCap", frame, -2.3, 2.3, 3.0, Step.PEDESTAL_TOP, -2.3, 2.3, C.gold, solid)
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				gemAt(model, "PedestalGem", frame, Vector3.new(sx * 2.05, Step.PEDESTAL_TOP + 0.3, sz * 2.05), 0.45, hex(spec.accent), {})
			end
		end
		local plaque = boxIn(model, "Plaque", frame, -1.7, 1.7, 1.38, 2.72, -2.14, -2.0, C.gold, { look = "smooth" })
		plaqueGui(plaque, spec)
		local host = hostPart(model, "InfoPrompt", Vector3.new(1, 1, 1), frame * CFrame.new(0, 2.2, -2.9))
		host:SetAttribute("HeroId", spec.id)
		prompt(host, { action = "View Hero", object = spec.name, distance = 9 })
		local template = assetModels and assetModels:FindFirstChild(spec.id)
		if template and template:IsA("Model") then
			local hero = statueModel(template, spec.id)
			-- feet on the pedestal: the rig is authored at the origin facing -Z, feet near Y 0
			local minY = math.huge
			for _, part in ipairs(baseParts(hero)) do
				if part.Transparency < 1 then
					local a = worldAabb(part)
					minY = math.min(minY, a.Y)
				end
			end
			if minY == math.huge then
				minY = 0
			end
			scaleRig(hero, Step.STATUE_SCALE, minY) -- about the feet: they stay at minY
			local T = frame * CFrame.new(0, Step.PEDESTAL_TOP - minY, 0)
			for _, part in ipairs(baseParts(hero)) do
				part.CFrame = T * part.CFrame
			end
			hero.WorldPivotData = frame * CFrame.new(0, Step.PEDESTAL_TOP, 0)
			hero.Parent = model
			built += 1
		else
			warnf("ReplicatedStorage.AssetModels.%s missing: the %s pedestal stands empty", spec.id, spec.name)
		end
	end
	return folder, built
end

local function buildFountain(park, g)
	local F = Step.PARK_FOUNTAIN
	local base = CFrame.new(F.X, g + 0.22, F.Z) -- on the plaza centre disc
	local model = newModel(park, "Fountain", base)
	streamWhole(model)
	local solid = { collide = true }
	local ghost = { collide = false }
	cylinderIn(model, "BasinFloor", base, Vector3.new(0, 0.15, 0), 0.3, 16.4, "y", C.navyDark, solid)
	-- octagonal stud rim (low-poly) with a gold cap; every block's long side is tangential
	local tan = math.tan(math.rad(22.5))
	for k = 0, 7 do
		local phi = math.rad(k * 45)
		local yaw = math.pi / 2 - phi
		local a = 8.1
		newPart(model, "Rim", Vector3.new(2 * (a + 0.7) * tan, 1.5, 1.4),
			base * CFrame.new(a * math.cos(phi), 0.75, a * math.sin(phi)) * CFrame.Angles(0, yaw, 0), C.navyLight, solid)
		newPart(model, "RimCap", Vector3.new(2 * (a + 0.9) * tan, 0.3, 1.8),
			base * CFrame.new(a * math.cos(phi), 1.65, a * math.sin(phi)) * CFrame.Angles(0, yaw, 0), C.gold, solid)
	end
	local waterLook = { look = "smooth", collide = false, transparency = 0.3, shadow = false, reflect = 0.12 }
	cylinderIn(model, "Water", base, Vector3.new(0, 0.3 + 0.425, 0), 0.85, 15.6, "y", C.water, waterLook)
	-- stepped centre column with two bowls
	pillarIn(model, "Column", base, 0, 0, 0.3, 3.4, 3.2, C.navy, solid)
	pillarIn(model, "BowlFoot", base, 0, 0, 3.0, 3.4, 4.6, C.goldDark, solid)
	pillarIn(model, "Bowl", base, 0, 0, 3.4, 4.1, 7.2, C.gold, solid)
	pillarIn(model, "BowlWater", base, 0, 0, 4.1, 4.22, 6.4, C.water, waterLook)
	pillarIn(model, "UpperColumn", base, 0, 0, 4.1, 6.4, 1.6, C.navyLight, solid)
	pillarIn(model, "UpperBowl", base, 0, 0, 6.4, 6.9, 3.8, C.gold, solid)
	pillarIn(model, "UpperWater", base, 0, 0, 6.9, 7.0, 3.2, C.water, waterLook)
	pillarIn(model, "Stem", base, 0, 0, 6.9, 7.8, 0.9, C.goldDark, solid)
	local emblem = gemAt(model, "Emblem", base, Vector3.new(0, 8.75, 0), 1.7, C.gold, {})
	pointLight(emblem, "Glow", hex("#ffe6a8"), 20, 1.1)
	emitter(emblem, "Sparkles", {
		texture = TEX.sparkle, rate = 4, life = { 1.2, 2 }, speed = { 0.6, 1.5 }, spread = { 70, 70 },
		size = { { 0, 0.35 }, { 0.5, 0.6 }, { 1, 0 } }, transparency = { { 0, 0.1 }, { 1, 1 } }, color = C.goldPale, light = 1,
	})
	-- water: an umbrella spout from the emblem, six arcing jets from the basin, mist and ripples on the pool
	local droplet = { { 0, "#e2fcff" }, { 1, "#6fdcff" } }
	local spout = hostPart(model, "Spout", Vector3.new(0.4, 0.4, 0.4), base * CFrame.new(0, 7.95, 0))
	emitter(spout, "Spray", {
		texture = TEX.drop, rate = 40, life = { 1.1, 1.4 }, speed = { 7, 9 }, spread = { 22, 22 }, accel = Vector3.new(0, -22, 0),
		size = { { 0, 0.34 }, { 1, 0.2 } }, transparency = { { 0, 0.15 }, { 0.75, 0.45 }, { 1, 1 } }, color = droplet, light = 0.3,
	})
	for k = 0, 5 do
		local deg = 30 + k * 60
		local p = ringPoint(Vector3.new(0, 0, 0), 6.3, deg, 1.2)
		local yaw = math.atan2(p.X, p.Z) -- local -Z points at the centre
		local jet = hostPart(model, "Jet", Vector3.new(0.3, 0.3, 0.3), base * CFrame.new(p) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.rad(-18), 0, 0))
		emitter(jet, "Stream", {
			texture = TEX.drop, rate = 22, life = { 0.9, 1.0 }, speed = { 11.5, 12.5 }, spread = { 3, 3 }, accel = Vector3.new(0, -24, 0),
			size = { { 0, 0.3 }, { 1, 0.18 } }, transparency = { { 0, 0.2 }, { 0.8, 0.5 }, { 1, 1 } }, color = droplet, light = 0.3,
		})
	end
	-- (the Water cylinder is turned on its side: its Top face is not up, so the pool effects get a flat host)
	local pool = hostPart(model, "Pool", Vector3.new(11, 0.1, 11), base * CFrame.new(0, 1.2, 0))
	emitter(pool, "Mist", {
		texture = TEX.mist, rate = 2.5, life = { 2.5, 3.5 }, speed = { 0.3, 0.8 }, spread = { 20, 20 },
		size = { { 0, 2.5 }, { 1, 5 } }, transparency = { { 0, 0.88 }, { 1, 1 } }, color = hex("#e6fbff"), light = 0.2,
	})
	emitter(pool, "Ripples", {
		texture = TEX.ring, rate = 2.2, life = { 1.4, 2 }, speed = { 0.01, 0.02 }, orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		size = { { 0, 0.6 }, { 1, 4.5 } }, transparency = { { 0, 0.55 }, { 1, 1 } }, color = hex("#bff4ff"), light = 0.4,
	})
	-- coin splash (bursts only: the HeroPark client emits them), on the avenue side of the pool
	local splash = hostPart(model, "SplashPoint", Vector3.new(0.5, 0.5, 0.5), base * CFrame.new(4.8, 1.05, 0))
	emitter(splash, "CoinSplash", {
		texture = TEX.drop, rate = 0, life = { 0.55, 0.95 }, speed = { 6, 12 }, spread = { 35, 35 }, accel = Vector3.new(0, -30, 0),
		size = { { 0, 0.4 }, { 1, 0.15 } }, transparency = { { 0, 0.1 }, { 1, 1 } }, color = droplet, light = 0.4,
	})
	emitter(splash, "CoinRing", {
		texture = TEX.ring, rate = 0, life = { 0.8, 1.1 }, speed = { 0.01, 0.02 }, orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		size = { { 0, 0.5 }, { 1, 5 } }, transparency = { { 0, 0.3 }, { 1, 1 } }, color = hex("#e2fcff"), light = 0.6,
	})
	emitter(splash, "CoinSparkle", {
		texture = TEX.sparkle, rate = 0, life = { 0.8, 1.4 }, speed = { 2, 5 }, spread = { 60, 60 },
		size = { { 0, 0.5 }, { 1, 0 } }, transparency = { { 0, 0 }, { 1, 1 } }, color = C.goldPale, light = 1,
	})
	local host = hostPart(model, "CoinPrompt", Vector3.new(1, 1, 1), base * CFrame.new(0, 2.4, 0))
	prompt(host, { action = "Toss a Coin", object = "Hero Fountain", distance = 13, theme = "Green" })
	return model
end

local function buildGarden(park, g)
	local G = Step.PARK_GARDEN
	local frame = facingFrame(Vector3.new(G.X, g + 0.2, G.Z), 1, 0) -- plaque faces the fountain (east)
	local model = newModel(park, "Garden", frame)
	streamWhole(model)
	local solid = { collide = true }
	boxIn(model, "Plinth", frame, -3, 3, 0, 1.0, -3, 3, C.navy, solid)
	boxIn(model, "PlinthTrim", frame, -3.15, 3.15, 1.0, 1.3, -3.15, 3.15, C.gold, solid)
	boxIn(model, "PlinthTop", frame, -2.2, 2.2, 1.3, 2.1, -2.2, 2.2, C.navyLight, solid)
	boxIn(model, "TrophyBase", frame, -1.6, 1.6, 2.1, 3.3, -1.6, 1.6, C.woodPost, solid)
	local plaque = boxIn(model, "TrophyPlaque", frame, -1.3, 1.3, 2.3, 3.1, -1.72, -1.6, C.gold, { look = "smooth" })
	local gui = newSurface(plaque, "PlaqueGui", Enum.NormalId.Front, 60, 70)
	signText(gui, "Title", "CHAMPIONS", UDim2.fromScale(0.05, 0.1), UDim2.fromScale(0.9, 0.8), hex("#6b3300"), { drop = 0.04, thickness = 0.12 })
	pillarIn(model, "Stem", frame, 0, 0, 3.3, 5.3, 1.0, C.gold, {})
	pillarIn(model, "Knob", frame, 0, 0, 4.0, 4.5, 1.9, C.goldDark, {})
	pillarIn(model, "CupFoot", frame, 0, 0, 5.1, 5.7, 3.0, C.gold, {})
	pillarIn(model, "Cup", frame, 0, 0, 5.6, 9.0, 4.4, C.gold, {})
	pillarIn(model, "CupRim", frame, 0, 0, 9.0, 9.35, 4.9, C.goldPale, {})
	for _, sx in ipairs({ -1, 1 }) do
		boxIn(model, "Handle", frame, sx * 3.25 - 0.28, sx * 3.25 + 0.28, 6.3, 8.5, -0.28, 0.28, C.gold, {})
		boxIn(model, "Handle", frame, math.min(sx * 2.2, sx * 3.3), math.max(sx * 2.2, sx * 3.3), 8.0, 8.5, -0.25, 0.25, C.gold, {})
		boxIn(model, "Handle", frame, math.min(sx * 2.2, sx * 3.3), math.max(sx * 2.2, sx * 3.3), 6.3, 6.8, -0.25, 0.25, C.gold, {})
	end
	local star = gemAt(model, "Star", frame, Vector3.new(0, 10.3, 0), 1.3, C.goldPale, {})
	emitter(star, "Sparkles", {
		texture = TEX.sparkle, rate = 3, life = { 1.2, 2 }, speed = { 0.6, 1.5 }, spread = { 70, 70 },
		size = { { 0, 0.4 }, { 0.5, 0.7 }, { 1, 0 } }, transparency = { { 0, 0.1 }, { 1, 1 } }, color = C.goldPale, light = 1,
	})
	pointLight(star, "Glow", hex("#ffe6a8"), 16, 0.9)
	local host = hostPart(model, "TrophyPrompt", Vector3.new(1, 1, 1), frame * CFrame.new(0, 2.4, -3.8))
	prompt(host, { action = "Admire", object = "Champion Trophy", distance = 10 })
	return model
end

local function buildProps(park, g)
	local props = newModel(park, "Props", CFrame.new(-30, g, Step.PARK_AXIS_Z))
	local F, G = Step.PARK_FOUNTAIN, Step.PARK_GARDEN
	local z0 = Step.PARK_AXIS_Z
	local counts = { bench = 0, lamp = 0, tree = 0, planter = 0, bollard = 0 }
	local function addBench(position, target)
		counts.bench += 1
		bench(props, counts.bench, faceToward(position, target))
	end
	local function addLamp(p)
		counts.lamp += 1
		lamp(props, counts.lamp, p.X, g, p.Z)
	end
	local function addTree(x, z, s, yaw)
		counts.tree += 1
		tree(props, counts.tree, x, g, z, s, yaw)
	end
	local function addPlanter(x, z)
		counts.planter += 1
		planter(props, counts.planter, x, g, z)
	end
	local function addBollard(x, z)
		counts.bollard += 1
		bollard(props, counts.bollard, x, g, z)
	end

	-- avenue: a bench between the first two statues of each row (facing the carpet), lamps further down
	local rowN, rowS = Step.PARK_ROW_Z.north, Step.PARK_ROW_Z.south
	addBench(Vector3.new(15, g + 0.15, rowN), Vector3.new(15, g, z0))
	addBench(Vector3.new(15, g + 0.15, rowS), Vector3.new(15, g, z0))
	for _, x in ipairs({ 1, -13 }) do
		addLamp(Vector3.new(x, 0, rowN))
		addLamp(Vector3.new(x, 0, rowS))
	end
	-- fountain plaza: four benches facing the fountain, eight lamps on the outer ring
	for _, deg in ipairs({ 45, 135, 225, 315 }) do
		addBench(ringPoint(F, 14.5, deg, g + 0.16), Vector3.new(F.X, g, F.Z)) -- on PlazaDisc (top 0.16)
	end
	for _, deg in ipairs({ 20, 70, 110, 160, 200, 250, 290, 340 }) do
		addLamp(ringPoint(F, 17.5, deg, 0))
	end
	-- Champions' garden: four benches around the trophy, four lamps, two planters
	for _, deg in ipairs({ 60, 120, 240, 300 }) do
		addBench(ringPoint(G, 8.5, deg, g + 0.16), Vector3.new(G.X, g, G.Z)) -- on GardenDisc (top 0.16)
	end
	for _, deg in ipairs({ 25, 155, 205, 335 }) do
		addLamp(ringPoint(G, 11, deg, 0))
	end
	addPlanter(G.X, G.Z + 10.5)
	addPlanter(G.X, G.Z - 10.5)
	-- entrance: planters beside the arch, bollards flanking the carpet; planters at the avenue / plaza junction
	addPlanter(33, z0 + 14.5)
	addPlanter(33, z0 - 14.5)
	addPlanter(-16.5, z0 + 12.5)
	addPlanter(-16.5, z0 - 12.5)
	addBollard(34.3, z0 + 4.2)
	addBollard(34.3, z0 - 4.2)
	addBollard(-61, z0 + 4.2)
	addBollard(-61, z0 - 4.2)
	-- tree lines along the park's north and south edges (the plaza's north side stays open), two on the west edge
	local north = { { -91, 1.0 }, { -80, 1.15 }, { -69, 0.95 }, { -58, 1.1 }, { -49, 1.0 }, { -21, 1.05 }, { -10, 1.15 }, { 3, 0.95 },
		{ 12, 1.1 }, { 22, 1.0 } }
	for i, t in ipairs(north) do
		addTree(t[1], -166, t[2], i * 17)
	end
	local south = { { -91, 1.05 }, { -80, 0.95 }, { -69, 1.15 }, { -58, 1.0 }, { -47, 1.1 }, { -25, 1.0 }, { -12, 1.15 }, { 0, 0.95 },
		{ 12, 1.1 }, { 24, 1.0 } }
	for i, t in ipairs(south) do
		addTree(t[1], -203.5, t[2], i * 23)
	end
	addTree(-91, -175, 1.0, 40)
	addTree(-91, -193, 0.95, 70)
	return props, counts
end

local function buildHeroPark(ws, rs, groundY)
	local hub = ws:FindFirstChild("Hub")
	if hub == nil then
		hub = Instance.new("Folder")
		hub.Name = "Hub"
		hub.Parent = ws
	end
	local old = hub:FindFirstChild("HeroPark")
	while old do
		old:Destroy()
		old = hub:FindFirstChild("HeroPark")
	end
	local region = Step.PARK_REGION
	local park = newModel(hub, "HeroPark", CFrame.new((region.minX + region.maxX) / 2, groundY, Step.PARK_AXIS_Z))
	park:SetAttribute("BuiltBy", "scripts/steps/post_hub_zlayout.luau")
	park:SetAttribute("RegionMin", Vector2.new(region.minX, region.minZ))
	park:SetAttribute("RegionMax", Vector2.new(region.maxX, region.maxZ))
	local before = partCount
	buildPaving(park, groundY)
	buildArch(park, groundY)
	buildSignpost(park, groundY)
	local _, statues = buildStatues(park, groundY, rs)
	buildFountain(park, groundY)
	buildGarden(park, groundY)
	local _, counts = buildProps(park, groundY)
	-- the park must stay inside its region (hub walls, plots, the HERO BOARD strip)
	local mn, mx = groupAabb(park)
	if mn.X < region.minX - 0.01 or mx.X > region.maxX + 0.01 or mn.Z < region.minZ - 0.01 or mx.Z > region.maxZ + 0.01 then
		error(string.format("HeroPark X %.2f..%.2f Z %.2f..%.2f leaves its region X %d..%d Z %d..%d", mn.X, mx.X, mn.Z, mx.Z,
			region.minX, region.maxX, region.minZ, region.maxZ))
	end
	log("Hero Park: %d parts + %d hero statues, %d benches, %d lamps, %d trees, %d planters, %d bollards; X %.1f..%.1f Z %.1f..%.1f.",
		partCount - before, statues, counts.bench, counts.lamp, counts.tree, counts.planter, counts.bollard, mn.X, mx.X, mn.Z, mx.Z)
	return park
end

---------------------------------------------------------------------------------------------------

function Step.Apply(place, _spPlace, ctx)
	local ws = place:GetService("Workspace")
	local rs = place:GetService("ReplicatedStorage")
	local groundY = (ctx and ctx.groundY) or 2.05
	partCount = 0
	table.clear(warnings)
	local failures = {}
	local function section(name, fn)
		local ok, err = pcall(fn)
		if not ok then
			table.insert(failures, name .. ": " .. tostring(err))
			print(string.format("%s !! section '%s' failed: %s", LOG_PREFIX, name, tostring(err)))
		end
	end
	section("sell stand", function()
		reseatSellStand(ws, groundY)
	end)
	section("free gift", function()
		reseatFreeGift(ws, groundY)
	end)
	section("hero park", function()
		buildHeroPark(ws, rs, groundY)
	end)
	log("Done: %d new parts, %d warning(s).", partCount, #warnings)
	if #failures > 0 then
		error("post_hub_zlayout failed: " .. table.concat(failures, " | "))
	end
end

return Step
