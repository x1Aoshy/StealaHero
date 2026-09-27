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
--   3. The HERO PARK (Hall of Heroes) that filled the south of the hub is gone (owner 2026-09-27: "Remove the Heroes
--      Hall area completely"): the step only clears a leftover Workspace.Hub.HeroPark / StarterGui.HeroParkCard.
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

-- 3. The Hero Park (Hall of Heroes) was removed on 2026-09-27 (owner: "Remove the Heroes Hall area completely"); this
--    step only clears a leftover one.

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
	section("hero park removal", function()
		local hub = ws:FindFirstChild("Hub")
		local removed = 0
		while hub and hub:FindFirstChild("HeroPark") do
			hub.HeroPark:Destroy()
			removed += 1
		end
		local starterGui = place:GetService("StarterGui")
		while starterGui:FindFirstChild("HeroParkCard") do
			starterGui.HeroParkCard:Destroy()
			removed += 1
		end
		log("Hero Park (Hall of Heroes): removed (owner 2026-09-27), %d leftover instance(s) cleared.", removed)
	end)
	log("Done: %d new parts, %d warning(s).", partCount, #warnings)
	if #failures > 0 then
		error("post_hub_zlayout failed: " .. table.concat(failures, " | "))
	end
end

return Step
