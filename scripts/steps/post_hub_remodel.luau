-- scripts/steps/post_hub_remodel.luau
-- Build step "post_hub_remodel" (owner HUB3D, docs/VISUAL_PASS_PLAN.md D6; references design/references/02-05).
-- Runs in the post_* pass (after the hero builder; scripts/steps/stages.luau has already moved the shops) and
-- remodels the hub in the stud style: clean blocks, Plastic + MaterialVariant "Studs", vibrant Speedsters colours.
--
--   1. Plot fences (Plots.<n>.ToUpdate.StarterPen, all 6 plots): navy #1b2742 studded posts with stepped
--      geometric caps, polished-wood rails with an X brace per span. Same footprints, still non-collidable
--      (nothing references the pen parts by name; the invisible Prompt1-3 / GridCenter parts are untouched).
--   2. Upgrade signs (Plots.<n>.PlotUpgrade / TreadmillUpgrade): navy studded 3D frame with rounded corners around
--      the Sign part, navy stud face and a glossy gold-to-red price button on the existing SurfaceGui. Every
--      name the controllers read is kept (Sign, Support, Sign.CanUpgrade, SurfaceGui.Info/Level/Frame/Upgrade/
--      RobuxUpgrade/Cost); the affordability channel (Upgrade.BackgroundColor3 + first UIGradient.Enabled) stays
--      with PlotUpgradeController / TreadmillUpgrade. The treadmill sign's Info reads "Upgrade Treadmill". New
--      parts live inside the sign models, so LocalPlotUpgradeVisibility hides them with the sign.
--   3. Money leaderboard (__OBJECTS.Leaderboards.Models.Leaderboard1): electric-blue studded frame with 3D studs,
--      angled crown, clean stepped base. The screen part "Leaderboard" (and its SurfaceGui > Frame >
--      ScrollingFrame) and the "LeaderboardTItle" part keep their names, SurfaceGuis and faces.
--   4. Free Gift corner (Workspace.Hub.FreeGift): the base place has no ad system (Workspace.Amonetization was a
--      brainrot gamepass showcase, not an ad board), so the "Watch Ad" board is rebuilt as an emerald studded
--      "CLICK TO CLAIM" board that opens the real Free Gift window (StarterGui.GroupReward, server-verified claim in
--      GroupRewardService). The gift chest (the base Giftbox + Build.GroupRewards "FREE!" decor) is rebuilt at its
--      original spot with gold studs, a big cubic lock, a floating glow and a "FREE!" label, and its original
--      opener is restored: Workspace.__OBJECTS.GroupReward (whose ProximityPrompt GUI/GroupRewards toggles) moves
--      onto the chest lid and its prompt is enabled; a "TAP TO OPEN" pill (GiftChest.Lid.OpenHint) marks the chest.
--      Clicks / taps on the board, the chest or the pill are handled by
--      StarterPlayerScripts.Game.HubFreeGift (scripts/inject/hub.luau). No join prompt is ever shown (the
--      GroupRewards client is the nogroup build).
--   5. Sell and Trails stalls (Workspace.Stands.Models "Sell Stands" / "GearShopStand"): stud stalls with curved
--      striped awnings (red/white, yellow/white), bevelled counters and bold 3D signs ("SELL" with a neon outline,
--      "TRAILS SHOP"). Stands.Prompts / Stands.Pads and their positions are untouched; the stalls stay
--      walk-through like the originals so the pad and prompts remain reachable.
--   (HUB LAYOUT 2026-09-26: scripts/steps/post_hub_zlayout.luau, the next post_* step, then moves the Sell stall + its
--   prompts onto a pedestal beside the street and the whole Free Gift corner in front of the spawn, as built here.)
--
-- Sign faces vs ui_40_world: scripts/steps/ui_40_world.luau (ui_* pass, runs after this step) re-skins the same
-- sign faces with the generic Speedsters card and family button colours. To keep D6 the sign-face styling is
-- applied here AND re-applied right after ui_40_world by wrapping that module's Apply at build time (its file
-- is not edited). If the wrapper cannot be installed, the navy face still survives (it is drawn above the card)
-- but the price button keeps ui_40_world's family colour; the build log says which case happened.
--
-- Everything is anchored, silent, and never touches the stage street (|Z| <= 15), the spawn, the plots or gates.
-- Lune persistence: FontFace, ImageContent/TextureContent and per-corner UICorner radii only.

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

local LOG_PREFIX = "[hub_remodel]"
local STUDS = "Studs" -- MaterialVariant used by the hub floor (scripts/steps/ground.luau)
local STUD_TILE = "rbxassetid://6927295847" -- Speedsters UI stud tile
local GIFT_ICON = "rbxassetid://127191998618608" -- Speedsters gift box icon (speedsters_ui_kit Icons.gift)
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds" -- built-in (hub particles must be rbxasset)
local FREE_GIFT_TAB_REWARD = "+1K Speed" -- ReplicatedStorage.Library.Types.GroupReward.GetDisplayName()

local FREDOKA = Font.fromEnum(Enum.Font.FredokaOne)

local function hex(s)
	return Color3.fromRGB(tonumber(string.sub(s, 2, 3), 16), tonumber(string.sub(s, 4, 5), 16), tonumber(string.sub(s, 6, 7), 16))
end

-- Palette (VISUAL_PASS_PLAN D6 + Speedsters materials)
local C = {
	ink = hex("#0b1b3d"),
	navy = hex("#1b2742"),
	navyLight = hex("#2b3c66"),
	navyDark = hex("#121b30"),
	woodTop = hex("#e38b37"),
	wood = hex("#cf7630"),
	woodDark = hex("#b0601f"),
	woodPost = hex("#7a3f1f"),
	gold = hex("#ffc21a"),
	goldDark = hex("#e39a00"),
	goldPale = hex("#ffe27a"),
	red = hex("#e8262e"),
	redDark = hex("#a3121a"),
	white = hex("#f4f6fa"),
	cream = hex("#fff8dc"),
	yellow = hex("#ffd21f"),
	counter = hex("#9aa6b8"),
	counterTop = hex("#dde3ec"),
	emerald = hex("#13b35b"),
	emeraldLight = hex("#3ee07f"),
	emeraldDark = hex("#0a7a3c"),
	blue = hex("#1e8cff"),
	blueLight = hex("#7fd4ff"),
	bluePale = hex("#dff3ff"),
	blueDeep = hex("#0a55c8"),
	screen = hex("#0c1830"),
	cyan = hex("#2af5ff"),
	glowGreen = hex("#3dff6e"),
	neonRed = hex("#ff2d4b"),
	black = hex("#111111"),
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

local function rotationOf(cf)
	return cf - cf.Position
end

-- Ground frame whose LookVector (local -Z, the "front") points along (dirX, dirZ).
local function facingFrame(position, dirX, dirZ)
	local yaw = math.atan2(-dirX, -dirZ)
	return CFrame.new(position) * CFrame.Angles(0, yaw, 0)
end

---------------------------------------------------------------------------------------------------
-- Part helpers
---------------------------------------------------------------------------------------------------

local partCount = 0

-- opts: shape ("Block" | "Cylinder"), class ("Part" | "WedgePart"), look ("studs" | "smooth" | "neon"),
-- collide (false), query (false), transparency (0), shadow (true)
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

-- Cylinder whose axis follows `axis` ("x" | "y" | "z") of `frame`.
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

-- Rounded-rectangle slab in the XY plane of `frame` (depth along Z): two crossed boxes + 4 corner cylinders.
-- Returns the main (widest) box.
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

-- Flat glowing disc on the floor.
local function floorDisc(parent, name, frame, x, z, diameter, groundLift, color, transparency)
	return cylinderIn(parent, name, frame, Vector3.new(x, groundLift, z), 0.1, diameter, "y", color,
		{ look = "neon", transparency = transparency, shadow = false })
end

-- Right-triangle prism (WedgePart) from explicit axis images: the wedge's local X/Y/Z are mapped to xAxis/yAxis/
-- zAxis (frame-relative, right-handed). The wedge is full at local -Y (bottom) and +Z (back).
local function wedgeIn(parent, name, frame, center, size, xAxis, yAxis, zAxis, color, opts)
	opts = table.clone(opts or {})
	opts.class = "WedgePart"
	local rotation = CFrame.fromMatrix(Vector3.new(0, 0, 0), xAxis, yAxis, zAxis)
	return newPart(parent, name, size, frame * CFrame.new(center) * rotation, color, opts)
end

local function newModel(parent, name, pivot)
	local model = Instance.new("Model")
	model.Name = name
	model.WorldPivotData = pivot
	model:SetAttribute("HubRemodel", true)
	model.Parent = parent
	return model
end

local function clearGenerated(container, prefix)
	for _, child in ipairs(container:GetChildren()) do
		if string.sub(child.Name, 1, #prefix) == prefix then
			child:Destroy()
		end
	end
end

---------------------------------------------------------------------------------------------------
-- GUI helpers
---------------------------------------------------------------------------------------------------

local function seq(stops)
	local keypoints = {}
	for _, stop in ipairs(stops) do
		table.insert(keypoints, ColorSequenceKeypoint.new(stop[1], hex(stop[2])))
	end
	return ColorSequence.new(keypoints)
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

-- UIStroke. mode "Border" | "Contextual"; scaled = ScaledSize thickness (fraction), else pixels.
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

-- TextLabel; opts: font, color, stroke {color, thickness(scaled)}, gradient {stops, rotation}, align, zIndex
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
	if opts.gradient then
		setGradient(label, "UIGradient", opts.gradient, opts.gradientRotation or 90)
	end
	return label
end

local function newSurface(part, name, face, pixelsPerStud, brightness)
	local surface = Instance.new("SurfaceGui")
	surface.Name = name
	surface.Face = face
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = pixelsPerStud
	surface.LightInfluence = 0
	surface.Brightness = brightness or 1
	surface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	surface.ClipsDescendants = true
	surface.MaxDistance = 220
	surface.AlwaysOnTop = false
	surface.Parent = part
	return surface
end

-- Stud tile overlay (UI stud texture of the Speedsters language).
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

-- Glossy rounded sign face filling a SurfaceGui whose part is exactly the rounded board (corner radius
-- `radiusPx`): a white rim ring, a vertical colour gradient, faint studs and a soft top gloss. Returns the inner
-- frame (children use scale coordinates of the inner area).
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

-- Big readable sign text: white FredokaOne, thick dark contextual outline and a dark drop copy below it.
local function signText(parent, name, text, position, size, strokeColor, opts)
	opts = opts or {}
	local maxSize = opts.maxSize or 100
	local drop = newLabel(parent, name .. "Drop", text, position + UDim2.fromScale(0, opts.drop or 0.045), size, {
		font = opts.font, color = strokeColor, stroke = { strokeColor, opts.thickness or 0.14 }, zIndex = 4,
	})
	local face = newLabel(parent, name, text, position, size, {
		font = opts.font, color = opts.color or C.white, stroke = { strokeColor, opts.thickness or 0.14 }, zIndex = 5,
	})
	for _, label in ipairs({ drop, face }) do
		local limit = Instance.new("UITextSizeConstraint")
		limit.MinTextSize = 1
		limit.MaxTextSize = maxSize
		limit.Parent = label
	end
	return face, drop
end

---------------------------------------------------------------------------------------------------
-- 1. Plot fences
---------------------------------------------------------------------------------------------------

local RAIL_BOTTOM_LEVEL = 0.83 -- rail centre heights above the floor in the base pens
local RAIL_TOP_LEVEL = 3.58
local POST_SIZE = Vector3.new(1.2, 4.2, 1.2)
local POST_SPACING = 10.5

local function isUpright(part)
	return part.CFrame.UpVector.Y > 0.99
end

local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 0.15)
end

local function remodelPen(pen, groundY, stats)
	if pen:GetAttribute("HubRemodel") then
		return
	end
	local capped = {}
	-- brace geometry between the top and bottom rails, posts POST_SPACING apart
	local innerHalfX = (POST_SPACING - POST_SIZE.X) / 2
	local railGapHalf = ((RAIL_TOP_LEVEL - 0.35) - (RAIL_BOTTOM_LEVEL + 0.31)) / 2
	local braceAngle = math.atan2(railGapHalf, innerHalfX)
	local braceLength = 2 * math.sqrt(innerHalfX * innerHalfX + railGapHalf * railGapHalf)
	local braceY = groundY + (RAIL_BOTTOM_LEVEL + 0.31 + RAIL_TOP_LEVEL - 0.35) / 2

	for _, part in ipairs(pen:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local parentName = part.Parent and part.Parent.Name or ""
			local size = part.Size
			local cf = part.CFrame
			local pos = cf.Position
			if parentName == "GateLeft" or parentName == "GateRight" then
				part.Material = Enum.Material.Plastic
				part.MaterialVariant = STUDS
				part.Color = if part.Name == "Hinge" then C.navy else C.wood
				stats.gate += 1
			elseif isUpright(part) and near(size.Y, 4) and near(size.X, 1) and near(size.Z, 1) then
				-- post: chunkier navy stud post on the same spot, bottom kept on the floor
				local bottom = pos.Y - size.Y / 2
				part.Size = POST_SIZE
				part.CFrame = CFrame.new(pos.X, bottom + POST_SIZE.Y / 2, pos.Z) * rotationOf(cf)
				part.Color = C.navy
				part.Material = Enum.Material.Plastic
				part.MaterialVariant = STUDS
				stats.posts += 1
				local key = string.format("%d,%d", math.floor(pos.X * 2 + 0.5), math.floor(pos.Z * 2 + 0.5))
				if not capped[key] then
					capped[key] = true
					local top = bottom + POST_SIZE.Y
					local yaw = rotationOf(cf)
					newPart(part.Parent, "HubFenceCap", Vector3.new(1.6, 0.32, 1.6), CFrame.new(pos.X, top + 0.16, pos.Z) * yaw, C.navyLight)
					newPart(part.Parent, "HubFenceGem", Vector3.new(0.62, 0.62, 0.62),
						CFrame.new(pos.X, top + 0.32 + 0.31, pos.Z) * yaw * CFrame.Angles(0, math.pi / 4, 0), C.gold)
					stats.caps += 1
				end
			elseif isUpright(part) and near(size.X, 9.5, 0.3) and size.Y < 0.8 and size.Z < 0.8 then
				local level = pos.Y - groundY
				part.Material = Enum.Material.Plastic
				part.MaterialVariant = STUDS
				local middleLevel = (RAIL_BOTTOM_LEVEL + RAIL_TOP_LEVEL) / 2
				if level < (RAIL_BOTTOM_LEVEL + middleLevel) / 2 then
					part.Size = Vector3.new(9.5, 0.62, 0.56)
					part.Color = C.woodDark
				elseif level > (RAIL_TOP_LEVEL + middleLevel) / 2 then
					part.Size = Vector3.new(9.5, 0.7, 0.62)
					part.Color = C.woodTop
				else
					-- middle rail becomes one leg of the X brace; the other leg is new
					local base = CFrame.new(pos.X, braceY, pos.Z) * rotationOf(cf)
					part.Size = Vector3.new(braceLength, 0.46, 0.46)
					part.CFrame = base * CFrame.Angles(0, 0, braceAngle)
					part.Color = C.wood
					newPart(part.Parent, "HubFenceBrace", Vector3.new(braceLength, 0.46, 0.46), base * CFrame.Angles(0, 0, -braceAngle), C.wood)
					stats.braces += 1
				end
				stats.rails += 1
			end
		end
	end
	pen:SetAttribute("HubRemodel", true)
end

local function remodelFences(ws, groundY)
	local plots = ws:FindFirstChild("Plots")
	if plots == nil then
		warnf("Workspace.Plots missing; fences skipped")
		return
	end
	local stats = { posts = 0, caps = 0, rails = 0, braces = 0, gate = 0 }
	local done = 0
	for _, plot in ipairs(plots:GetChildren()) do
		local pen = findPath(plot, "ToUpdate/StarterPen")
		if pen then
			remodelPen(pen, groundY, stats)
			done += 1
		else
			warnf("Plots.%s.ToUpdate.StarterPen missing; fence skipped", plot.Name)
		end
	end
	log("Fences: %d plots, %d posts (%d capped), %d rails (%d X braces), %d gate parts.",
		done, stats.posts, stats.caps, stats.rails, stats.braces, stats.gate)
end

---------------------------------------------------------------------------------------------------
-- 2. Upgrade signs (3D frame) + sign faces (SurfaceGui restyle)
---------------------------------------------------------------------------------------------------

-- Sign-local axes for a SurfaceGui face: `normal` points out of the face, `width`/`height` span it.
local function faceAxes(face)
	if face == Enum.NormalId.Left then
		return Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 1, 0), "x"
	elseif face == Enum.NormalId.Right then
		return Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 1, 0), "x"
	elseif face == Enum.NormalId.Back then
		return Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), "z"
	end
	return Vector3.new(0, 0, -1), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), "z"
end

local function absV(v)
	return Vector3.new(math.abs(v.X), math.abs(v.Y), math.abs(v.Z))
end

local function frameSign(model, sign, support, surface, groundY)
	clearGenerated(model, "HubSign")
	sign.Color = C.navy
	sign.Material = Enum.Material.Plastic
	sign.MaterialVariant = STUDS

	local normal, widthAxis, heightAxis, normalAxisName = faceAxes(surface.Face)
	local size = sign.Size
	local thickness = math.abs(size:Dot(normal))
	local width = math.abs(size:Dot(widthAxis))
	local height = math.abs(size:Dot(heightAxis))
	local bar = 0.44
	local front, back = 0.16, 0.08 -- protrusion in front of the face / behind the back
	local depth = thickness + front + back
	local centerOffset = (front - back) / 2 -- along the normal
	local cf = sign.CFrame
	local function at(a, w, h)
		return cf * CFrame.new(normal * a + widthAxis * w + heightAxis * h)
	end
	local function sized(a, w, h)
		return absV(normal * a) + absV(widthAxis * w) + absV(heightAxis * h)
	end
	local opts = { query = false }
	local hy = height / 2 + bar / 2
	local wz = width / 2 + bar / 2
	newPart(model, "HubSignFrameTop", sized(depth, width, bar), at(centerOffset, 0, hy), C.navy, opts)
	newPart(model, "HubSignFrameBottom", sized(depth, width, bar), at(centerOffset, 0, -hy), C.navy, opts)
	newPart(model, "HubSignFrameSideA", sized(depth, bar, height), at(centerOffset, wz, 0), C.navy, opts)
	newPart(model, "HubSignFrameSideB", sized(depth, bar, height), at(centerOffset, -wz, 0), C.navy, opts)
	-- soft corners: a cylinder (axis = face normal, radius = bar) centred on each face corner rounds the frame
	local cornerRotation = if normalAxisName == "x" then CFrame.new() else CFrame.Angles(0, math.pi / 2, 0)
	for _, s in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
		newPart(model, "HubSignFrameCorner", Vector3.new(depth, bar * 2, bar * 2),
			at(centerOffset, width / 2 * s[1], height / 2 * s[2]) * cornerRotation, C.navy, { shape = "Cylinder" })
	end
	-- post + plinth
	if support and support:IsA("BasePart") then
		support.Color = C.navyDark
		support.Material = Enum.Material.Plastic
		support.MaterialVariant = STUDS
		local p = support.CFrame.Position
		newPart(model, "HubSignPlinth", Vector3.new(1.9, 0.36, 1.9), CFrame.new(p.X, groundY + 0.18, p.Z) * rotationOf(support.CFrame), C.navy)
	end
end

-- Gold-to-red glossy price button (vertical: gold top, red body, deep red bottom = relief).
local PRICE_FILL = { { 0, "#ffd23c" }, { 0.36, "#ff7a1f" }, { 0.58, "#ee2b2b" }, { 1, "#9c0b14" } }
local PRICE_LIGHT = { { 0, "#fff0a0" }, { 0.55, "#ffc21a" }, { 1, "#c45a00" } }

local function stylePriceButton(button)
	if button == nil or not button:IsA("GuiButton") then
		return false
	end
	-- the controllers cache BackgroundColor3 and the first UIGradient (+ its Enabled) as the "affordable" look
	button.BackgroundColor3 = Color3.new(1, 1, 1)
	button.BackgroundTransparency = 0
	local gradient = button:FindFirstChildOfClass("UIGradient")
	if gradient == nil then
		gradient = Instance.new("UIGradient")
		gradient.Name = "UIGradient"
		gradient.Parent = button
	end
	gradient.Color = seq(PRICE_FILL)
	gradient.Rotation = 90
	gradient.Offset = Vector2.new(0, 0)
	gradient.Transparency = NumberSequence.new(0)
	gradient.Enabled = true
	setCorner(button, 0.3)
	local light = setStroke(button, "SpStrokeLight", C.white, 0.06, "Border", true)
	setGradient(light, "UIGradient", PRICE_LIGHT, 90)
	light.ZIndex = 1
	local dark = setStroke(button, "SpStrokeDark", hex("#4a0a0a"), 0.05, "Border", true)
	dark.ZIndex = 2
	-- gloss band over the top half (below the icon and price)
	local gloss = ensureChild(button, "Frame", "HubGloss")
	gloss.AnchorPoint = Vector2.new(0.5, 0)
	gloss.Position = UDim2.fromScale(0.5, 0.07)
	gloss.Size = UDim2.fromScale(0.92, 0.42)
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0
	gloss.BorderSizePixel = 0
	gloss.Active = false
	gloss.ZIndex = 2
	setCorner(gloss, 0.45)
	setGradient(gloss, "HubGlossFade", { { 0, "#ffffff" }, { 1, "#ffffff" } }, 90, { { 0, 0.45 }, { 1, 0.95 } })
	for _, name in ipairs({ "Icon", "Cost" }) do
		local child = button:FindFirstChild(name)
		if child and child:IsA("GuiObject") then
			child.ZIndex = math.max(child.ZIndex, 3)
		end
	end
	local cost = button:FindFirstChild("Cost")
	if cost and cost:IsA("TextLabel") then
		cost.TextColor3 = C.white
		local stroke = cost:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = hex("#4a0a0a")
		end
	end
	return true
end

-- Navy stud face, drawn below every script-owned label (and above the generic card of ui_40_world).
local function styleSignFace(sign, kind)
	local surface = sign:FindFirstChild("SurfaceGui")
	if surface == nil or not surface:IsA("SurfaceGui") then
		return false
	end
	local minZ = nil
	for _, child in ipairs(surface:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "HubFace" and string.match(child.Name, "^Sp%u") == nil then
			minZ = if minZ then math.min(minZ, child.ZIndex) else child.ZIndex
		end
	end
	local face = ensureChild(surface, "Frame", "HubFace")
	face.AnchorPoint = Vector2.new(0, 0)
	face.Position = UDim2.fromScale(0, 0)
	face.Size = UDim2.fromScale(1, 1)
	face.BackgroundColor3 = C.navy
	face.BackgroundTransparency = 0
	face.BorderSizePixel = 0
	face.Active = false
	face.ZIndex = (minZ or 1) - 1
	local studs = face:FindFirstChild("HubStuds") or studOverlay(face, hex("#6f8fd6"), 0.72, 30, face.ZIndex)
	studs.ZIndex = face.ZIndex
	local shade = ensureChild(face, "Frame", "HubShade")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0
	shade.BorderSizePixel = 0
	shade.ZIndex = face.ZIndex
	setGradient(shade, "UIGradient", { { 0, "#000000" }, { 1, "#000000" } }, 90, { { 0, 1 }, { 0.55, 1 }, { 1, 0.62 } })
	surface.Brightness = 1
	-- the generic Speedsters card of ui_40_world (if present) is replaced by the navy face
	local card = surface:FindFirstChild("SpBackground")
	if card and card:IsA("ImageLabel") then
		card.ImageTransparency = 1
		card.BackgroundTransparency = 1
		for _, child in ipairs(card:GetChildren()) do
			if child:IsA("UIStroke") then
				child.Transparency = 1
			end
		end
	end

	-- Info / Level: FredokaOne with an ink outline (reusing the label's own UIStroke); Level.Text stays scripted
	local function styleLabel(label, color)
		if label == nil or not label:IsA("TextLabel") then
			return
		end
		label.FontFace = FREDOKA
		label.TextColor3 = color
		label.TextStrokeTransparency = 1
		local existing = label:FindFirstChildOfClass("UIStroke")
		setStroke(label, if existing then existing.Name else "UIStroke", C.ink, 0.09, "Contextual", true)
	end
	local info = surface:FindFirstChild("Info")
	if kind == "TreadmillUpgrade" and info and info:IsA("TextLabel") then
		info.Text = "Upgrade Treadmill"
	end
	styleLabel(info, C.white)
	styleLabel(surface:FindFirstChild("Level"), hex("#8cff2e"))
	local frame = surface:FindFirstChild("Frame")
	local upgrade = frame and frame:FindFirstChild("Upgrade")
	return stylePriceButton(upgrade)
end

-- Every sign face + the FirstUpgrade template (the price button shown before the pen is unlocked).
function Step.RestyleSignFaces(place)
	local ws = place:GetService("Workspace")
	local faces, buttons = 0, 0
	local plots = ws:FindFirstChild("Plots")
	for _, plot in ipairs(plots and plots:GetChildren() or {}) do
		for _, kind in ipairs({ "PlotUpgrade", "TreadmillUpgrade" }) do
			local sign = findPath(plot, kind .. "/Sign")
			if sign and sign:IsA("BasePart") then
				faces += 1
				if styleSignFace(sign, kind) then
					buttons += 1
				end
			end
		end
	end
	local first = findPath(place:GetService("ReplicatedStorage"), "Assets/UI/PlotUpgrade/FirstUpgrade")
	if stylePriceButton(first) then
		buttons += 1
	end
	return faces, buttons
end

local function remodelSigns(ws, groundY)
	local plots = ws:FindFirstChild("Plots")
	local framed = 0
	for _, plot in ipairs(plots and plots:GetChildren() or {}) do
		for _, kind in ipairs({ "PlotUpgrade", "TreadmillUpgrade" }) do
			local model = plot:FindFirstChild(kind)
			local sign = model and model:FindFirstChild("Sign")
			local surface = sign and sign:FindFirstChild("SurfaceGui")
			if sign and sign:IsA("BasePart") and surface and surface:IsA("SurfaceGui") then
				frameSign(model, sign, model:FindFirstChild("Support"), surface, groundY)
				framed += 1
			else
				warnf("Plots.%s.%s sign (Sign + SurfaceGui) missing; not remodelled", plot.Name, kind)
			end
		end
	end
	return framed
end

-- ui_40_world (ui_* pass) runs after this step and re-skins the same faces: re-apply ours right after it.
local function installLateSignPass()
	local ok, world = pcall(require, "./ui_40_world")
	if not ok or type(world) ~= "table" or type(world.Apply) ~= "function" then
		log("ui_40_world not loadable (%s); sign faces keep this step's styling only.", tostring(world))
		return false
	end
	if world.__hubRemodelLatePass then
		return true
	end
	local original = world.Apply
	world.Apply = function(place, spPlace, ctx)
		local okWorld, errWorld = pcall(original, place, spPlace, ctx)
		local okLate, faces, buttons = pcall(Step.RestyleSignFaces, place)
		if okLate then
			log("Late sign pass after ui_40_world: %d sign faces, %d price buttons re-styled (D6).", faces, buttons)
		else
			print(LOG_PREFIX .. " !! late sign pass after ui_40_world failed: " .. tostring(faces))
		end
		if not okWorld then
			error(errWorld, 0)
		end
	end
	world.__hubRemodelLatePass = true
	return true
end

---------------------------------------------------------------------------------------------------
-- 3. Money leaderboard
---------------------------------------------------------------------------------------------------

local function remodelLeaderboard(ws, groundY)
	local board = findPath(ws, "__OBJECTS/Leaderboards/Models/Leaderboard1")
	local screen = board and board:FindFirstChild("Leaderboard")
	local title = board and board:FindFirstChild("LeaderboardTItle")
	if not (board and screen and screen:IsA("BasePart")) then
		warnf("__OBJECTS.Leaderboards.Models.Leaderboard1.Leaderboard missing; leaderboard not remodelled")
		return 0
	end
	local screenGui = screen:FindFirstChildOfClass("SurfaceGui")
	local look = screen.CFrame.LookVector -- the screen SurfaceGui is on its Front face
	if screenGui and screenGui.Face == Enum.NormalId.Back then
		look = -look
	end
	local sp = screen.CFrame.Position
	local frame = facingFrame(Vector3.new(sp.X, groundY, sp.Z), look.X, look.Z)
	local screenBottom = sp.Y - screen.Size.Y / 2 - groundY
	local screenTop = sp.Y + screen.Size.Y / 2 - groundY
	local halfW = screen.Size.X / 2

	-- only the screen + title stay; the old trim is rebuilt
	for _, child in ipairs(board:GetChildren()) do
		if child ~= screen and child ~= title then
			child:Destroy()
		end
	end
	screen.Color = C.screen
	screen.Material = Enum.Material.SmoothPlastic
	screen.MaterialVariant = ""

	local solid = { collide = true }
	local deco = {}
	local bevel = 0.35
	local innerW = halfW + bevel
	local barW = 1.2
	local outerW = innerW + barW
	local frameBottom = screenBottom - bevel - barW
	local frameTop = screenTop + bevel + 0.75
	-- inner bevel (deep blue) hugging the screen
	boxIn(board, "HubBoardBevel", frame, -innerW, -halfW, screenBottom - bevel, screenTop + bevel, -0.3, 0.2, C.blueDeep, { look = "smooth" })
	boxIn(board, "HubBoardBevel", frame, halfW, innerW, screenBottom - bevel, screenTop + bevel, -0.3, 0.2, C.blueDeep, { look = "smooth" })
	boxIn(board, "HubBoardBevel", frame, -halfW, halfW, screenBottom - bevel, screenBottom, -0.3, 0.2, C.blueDeep, { look = "smooth" })
	boxIn(board, "HubBoardBevel", frame, -halfW, halfW, screenTop, screenTop + bevel, -0.3, 0.2, C.blueDeep, { look = "smooth" })
	-- electric-blue studded frame + back plate
	boxIn(board, "HubBoardFrame", frame, -outerW, -innerW, frameBottom, frameTop, -0.55, 0.65, C.blue, solid)
	boxIn(board, "HubBoardFrame", frame, innerW, outerW, frameBottom, frameTop, -0.55, 0.65, C.blue, solid)
	boxIn(board, "HubBoardFrame", frame, -innerW, innerW, frameBottom, screenBottom - bevel, -0.55, 0.65, C.blue, solid)
	boxIn(board, "HubBoardFrame", frame, -innerW, innerW, screenTop + bevel, frameTop, -0.55, 0.65, C.blue, solid)
	boxIn(board, "HubBoardBack", frame, -outerW, outerW, frameBottom, frameTop, 0.65, 0.95, C.blueDeep, solid)
	-- prominent 3D studs on the frame face
	local studFront = -0.55 - 0.13
	local studY = frameBottom + 1.2
	while studY < frameTop - 0.6 do
		cylinderIn(board, "HubBoardStud", frame, Vector3.new(-(innerW + barW / 2), studY, studFront), 0.26, 0.62, "z", C.blueLight, deco)
		cylinderIn(board, "HubBoardStud", frame, Vector3.new(innerW + barW / 2, studY, studFront), 0.26, 0.62, "z", C.blueLight, deco)
		studY += 1.8
	end
	local studX = -innerW + 1.0
	while studX < innerW - 0.5 do
		cylinderIn(board, "HubBoardStud", frame, Vector3.new(studX, frameBottom + barW / 2, studFront), 0.26, 0.62, "z", C.blueLight, deco)
		studX += 1.8
	end

	-- angled crown: banner with outward-sloping ends, a raised centre peak and gold accents
	local crownBottom = frameTop
	local crownTop = crownBottom + 2.8
	local bannerHalf = outerW + 0.1
	local slope = 1.25
	boxIn(board, "HubBoardCrown", frame, -bannerHalf, bannerHalf, crownBottom, crownTop, -0.6, 0.7, C.blue, solid)
	local wedgeSize = Vector3.new(1.3, crownTop - crownBottom, slope)
	local wedgeY = (crownBottom + crownTop) / 2
	wedgeIn(board, "HubBoardCrownWing", frame, Vector3.new(-(bannerHalf + slope / 2), wedgeY, 0.05), wedgeSize,
		Vector3.new(0, 0, 1), Vector3.new(0, -1, 0), Vector3.new(1, 0, 0), C.blue, deco)
	wedgeIn(board, "HubBoardCrownWing", frame, Vector3.new(bannerHalf + slope / 2, wedgeY, 0.05), wedgeSize,
		Vector3.new(0, 0, -1), Vector3.new(0, -1, 0), Vector3.new(-1, 0, 0), C.blue, deco)
	boxIn(board, "HubBoardCrownRim", frame, -(bannerHalf + slope), bannerHalf + slope, crownTop, crownTop + 0.35, -0.7, 0.8, C.blueLight, deco)
	local peakHalf, peakRise = 2.4, 1.0
	local peakBottom = crownTop + 0.35
	boxIn(board, "HubBoardCrownPeak", frame, -peakHalf, peakHalf, peakBottom, peakBottom + peakRise, -0.5, 0.6, C.blue, deco)
	local peakWedge = Vector3.new(1.1, peakRise, 0.9)
	wedgeIn(board, "HubBoardCrownPeakWing", frame, Vector3.new(-(peakHalf + 0.45), peakBottom + peakRise / 2, 0.05), peakWedge,
		Vector3.new(0, 0, -1), Vector3.new(0, 1, 0), Vector3.new(1, 0, 0), C.blue, deco)
	wedgeIn(board, "HubBoardCrownPeakWing", frame, Vector3.new(peakHalf + 0.45, peakBottom + peakRise / 2, 0.05), peakWedge,
		Vector3.new(0, 0, 1), Vector3.new(0, 1, 0), Vector3.new(-1, 0, 0), C.blue, deco)
	newPart(board, "HubBoardCrownGem", Vector3.new(0.9, 0.9, 0.9),
		frame * CFrame.new(0, peakBottom + peakRise + 0.35, 0.05) * CFrame.Angles(0, math.pi / 4, 0) * CFrame.Angles(math.rad(35), 0, 0), C.gold, deco)
	for _, x in ipairs({ -(bannerHalf + slope - 0.45), bannerHalf + slope - 0.45 }) do
		cylinderIn(board, "HubBoardCrownStud", frame, Vector3.new(x, crownTop + 0.35 + 0.13, 0.05), 0.26, 0.7, "y", C.gold, deco)
	end
	local rimStud = -(bannerHalf + slope) + 1.6
	while rimStud < bannerHalf + slope - 1.4 do
		if math.abs(rimStud) > peakHalf + 1.1 then
			cylinderIn(board, "HubBoardStud", frame, Vector3.new(rimStud, crownTop + 0.35 + 0.13, 0.05), 0.26, 0.62, "y", C.blueLight, deco)
		end
		rimStud += 1.6
	end

	-- title: the LeaderboardTItle part (SurfaceGui on its viewer-facing face) sits flush on the banner front
	if title and title:IsA("BasePart") then
		local titleGui = title:FindFirstChildOfClass("SurfaceGui")
		local faceNormal = title.CFrame.LookVector
		if titleGui and titleGui.Face == Enum.NormalId.Back then
			faceNormal = -faceNormal
		end
		-- faceNormal points at the viewer (-z of the frame): the title face sits 0.04 in front of the banner front
		-- (z = -0.6), the rest of the part is buried in the banner
		local halfDepth = math.abs(title.Size:Dot(title.CFrame:VectorToObjectSpace(faceNormal))) / 2
		local target = (frame * CFrame.new(0, (crownBottom + crownTop) / 2, 0)).Position + faceNormal * (0.6 + 0.04 - halfDepth)
		title.CFrame = CFrame.new(target) * rotationOf(title.CFrame)
		title.Color = C.blue
		title.Material = Enum.Material.Plastic
		title.MaterialVariant = STUDS
		local label = titleGui and titleGui:FindFirstChildWhichIsA("TextLabel")
		if label then
			label.FontFace = FREDOKA
			label.TextColor3 = C.white
			setGradient(label, "HubTitleGradient", { { 0, "#d9ff5c" }, { 0.5, "#5dff3a" }, { 1, "#16c43b" } }, 90)
			local stroke = label:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = hex("#0b3d12")
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
				stroke.Transparency = 0
			end
		end
	else
		warnf("Leaderboard1.LeaderboardTItle missing; crown has no title")
	end

	-- clean stepped base
	boxIn(board, "HubBoardBase", frame, -(outerW + 1.35), outerW + 1.35, 0, 0.5, -2.9, 1.7, C.bluePale, solid)
	boxIn(board, "HubBoardBase", frame, -(outerW + 0.7), outerW + 0.7, 0.5, 1.1, -2.3, 1.3, C.blueLight, solid)
	boxIn(board, "HubBoardBase", frame, -outerW, outerW, 1.1, frameBottom, -1.4, 1.0, C.blue, solid)
	board.WorldPivotData = frame
	board:SetAttribute("HubRemodel", true)
	local n = 0
	for _, d in ipairs(board:GetDescendants()) do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

---------------------------------------------------------------------------------------------------
-- 4. Free Gift corner: CLICK TO CLAIM board + gift chest (Workspace.Hub.FreeGift)
---------------------------------------------------------------------------------------------------

Step.FREE_GIFT_BOARD = Vector3.new(68.4, 0, 69) -- ground point (Y from the floor), faces -X (the hub)
Step.FREE_GIFT_CHEST = Vector3.new(62.8, 0, 69)

local function buildClaimBoard(parent, groundY)
	local origin = Step.FREE_GIFT_BOARD
	local frame = facingFrame(Vector3.new(origin.X, groundY, origin.Z), -1, 0)
	local model = newModel(parent, "ClaimSign", frame)
	local solid = { collide = true, look = "smooth" }
	-- clean rounded billboard: two round posts on round feet, a dark green outline ring and a green rounded board
	local boardW, boardH, radius = 12, 8, 1.3
	local bottom = 3.6
	local cy = bottom + boardH / 2
	for _, x in ipairs({ -3.6, 3.6 }) do
		cylinderIn(model, "StandPost", frame, Vector3.new(x, cy / 2, 0.15), cy, 0.95, "y", C.emeraldDark, solid)
		cylinderIn(model, "StandFoot", frame, Vector3.new(x, 0.2, 0.15), 0.4, 1.9, "y", hex("#0a4d25"), solid)
	end
	local outline = 0.4
	roundedSlab(model, "Outline", frame, 0, cy, boardW + 2 * outline, boardH + 2 * outline, -0.28, 0.28, radius + outline, hex("#0a4d25"), solid)
	roundedSlab(model, "Panel", frame, 0, cy, boardW, boardH, -0.36, 0.36, radius, C.emerald, solid)
	-- invisible face carrier (exactly the board, faces just proud of it); clicks on it reach the ClickDetector
	local carrier = boxIn(model, "Face", frame, -boardW / 2, boardW / 2, cy - boardH / 2, cy + boardH / 2, -0.38, 0.38, C.emerald,
		{ collide = false, query = true, look = "smooth", transparency = 1, shadow = false })
	local pps = 40
	local greenFace = { { 0, "#6dff9a" }, { 0.5, "#22cf5f" }, { 1, "#0b9444" } }
	local ink = hex("#0a4d25")

	-- front: FREE GIFT! title, the gift icon on a soft glow, 1,000 SPEED, and a gold CLICK TO CLAIM button
	local front = newSurface(carrier, "ClaimFace", Enum.NormalId.Front, pps, 1.12)
	local inner = roundedFace(front, math.floor(radius * pps), 11, greenFace, hex("#c8ffd9"))
	signText(inner, "Title", "FREE GIFT!", UDim2.fromScale(0.06, 0.04), UDim2.fromScale(0.88, 0.25), ink, { drop = 0.03 })
	local glow = newFrame(inner, "IconGlow", UDim2.fromScale(0.06, 0.3), UDim2.fromScale(0.36, 0.44), C.white, 0.72, 2)
	glow.SizeConstraint = Enum.SizeConstraint.RelativeXY
	setCorner(glow, 0.5)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = glow
	local icon = Instance.new("ImageLabel")
	icon.Name = "GiftIcon"
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromScale(1.08, 1.08)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ImageContent = Content.fromUri(GIFT_ICON)
	icon.ZIndex = 3
	icon.Parent = glow
	signText(inner, "Amount", "1,000", UDim2.fromScale(0.44, 0.31), UDim2.fromScale(0.52, 0.24), ink, { drop = 0.025 })
	signText(inner, "Unit", "SPEED", UDim2.fromScale(0.44, 0.54), UDim2.fromScale(0.52, 0.17), hex("#6b3300"),
		{ color = hex("#ffe45c"), drop = 0.02 })
	local pill = newFrame(inner, "ClaimButton", UDim2.fromScale(0.12, 0.77), UDim2.fromScale(0.76, 0.18), C.white, 0, 6)
	setCorner(pill, 0.5)
	setGradient(pill, "UIGradient", { { 0, "#fff27a" }, { 0.5, "#ffc21a" }, { 1, "#ff9000" } }, 90)
	setStroke(pill, "UIStroke", hex("#6b3300"), 4, "Border", false)
	local pillGloss = newFrame(pill, "Gloss", UDim2.fromScale(0.05, 0.08), UDim2.fromScale(0.9, 0.42), C.white, 0, 7)
	setCorner(pillGloss, 0.5)
	setGradient(pillGloss, "UIGradient", { { 0, "#ffffff" }, { 1, "#ffffff" } }, 90, { { 0, 0.5 }, { 1, 0.95 } })
	local label = signText(pill, "Label", "CLICK TO CLAIM", UDim2.fromScale(0.06, 0.12), UDim2.fromScale(0.88, 0.76), hex("#6b3300"),
		{ drop = 0.06, thickness = 0.16 })
	label.ZIndex = 9
	local labelDrop = pill:FindFirstChild("LabelDrop")
	if labelDrop then
		labelDrop.ZIndex = 8
	end

	-- back: the same face with only the title
	local back = newSurface(carrier, "ClaimBack", Enum.NormalId.Back, pps, 1.12)
	local backInner = roundedFace(back, math.floor(radius * pps), 11, greenFace, hex("#c8ffd9"))
	signText(backInner, "Title", "FREE GIFT!", UDim2.fromScale(0.06, 0.2), UDim2.fromScale(0.88, 0.6), ink)

	local detector = Instance.new("ClickDetector")
	detector.Name = "ClaimClick"
	detector.MaxActivationDistance = 32
	detector.Parent = model
	return model
end

-- The chest's opener sits on the chest (UIFIX 2026-09-24, owner report "Free gift tap to open not at chest"): the
-- GroupReward prompt host floats FREE_GIFT_PROMPT_LIFT over the lid, and a glossy "TAP TO OPEN" pill (OpenHint, on the
-- lid) marks the chest from afar. StarterPlayerScripts.Game.HubFreeGift clones the pill into PlayerGui so a tap / click
-- on it opens the window, words it per input (TAP / CLICK / OPEN), hides it while the prompt is up and once claimed.
Step.FREE_GIFT_PROMPT_LIFT = 1.0 -- studs over the lid top (stays inside the chest bounds, at the gem)
Step.FREE_GIFT_PROMPT_DISTANCE = 12
Step.FREE_GIFT_HINT_LIFT = 2.5 -- pill centre over the lid top
local TAP_ICON = "rbxassetid://120727748405394" -- the base game's tap hand (ReplicatedStorage.Assets.UI.Tutorial.ClickOn2DTarget)

local function buildOpenHint(lid, lidHalfHeight)
	local hint = Instance.new("BillboardGui")
	hint.Name = "OpenHint"
	hint.Size = UDim2.new(5.6, 0, 1.5, 0)
	hint.StudsOffsetWorldSpace = Vector3.new(0, lidHalfHeight + Step.FREE_GIFT_HINT_LIFT, 0)
	hint.LightInfluence = 0
	hint.MaxDistance = 80
	hint.AlwaysOnTop = false
	hint.Active = true
	hint.ClipsDescendants = false
	hint.ResetOnSpawn = false
	hint.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	hint:SetAttribute("FreeGiftHint", true)
	hint.Parent = lid
	-- pill: ink rim frame + gold gradient fill (scale insets, so it reads the same at any distance), soft top gloss
	local ink = hex("#6b3300")
	local rim = newFrame(hint, "Pill", UDim2.fromScale(0.12, 0.1), UDim2.fromScale(0.86, 0.8), ink, 0, 2)
	setCorner(rim, 0.5)
	local fill = newFrame(rim, "Fill", UDim2.fromScale(0.018, 0.08), UDim2.fromScale(0.964, 0.84), C.white, 0, 3)
	setCorner(fill, 0.5)
	setGradient(fill, "UIGradient", { { 0, "#fff27a" }, { 0.5, "#ffc21a" }, { 1, "#ff9000" } }, 90)
	local gloss = newFrame(fill, "Gloss", UDim2.fromScale(0.05, 0.06), UDim2.fromScale(0.9, 0.42), C.white, 0, 4)
	setCorner(gloss, 0.5)
	setGradient(gloss, "UIGradient", { { 0, "#ffffff" }, { 1, "#ffffff" } }, 90, { { 0, 0.45 }, { 1, 0.95 } })
	local label = signText(fill, "Label", "TAP TO OPEN", UDim2.fromScale(0.21, 0.1), UDim2.fromScale(0.75, 0.8), ink,
		{ drop = 0.06, thickness = 0.16 })
	label.ZIndex = 9
	local labelDrop = fill:FindFirstChild("LabelDrop")
	if labelDrop then
		labelDrop.ZIndex = 8
	end
	-- the tap hand over the pill's left end
	local hand = Instance.new("ImageLabel")
	hand.Name = "Hand"
	hand.BackgroundTransparency = 1
	hand.AnchorPoint = Vector2.new(0, 0.5)
	hand.Position = UDim2.fromScale(0, 0.52)
	hand.Size = UDim2.fromScale(0.3, 1.25)
	hand.ScaleType = Enum.ScaleType.Fit
	hand.ImageContent = Content.fromUri(TAP_ICON)
	hand.ZIndex = 10
	hand.Parent = hint
	local handAspect = Instance.new("UIAspectRatioConstraint")
	handAspect.AspectRatio = 1
	handAspect.Parent = hand
	-- click / tap catcher (live once HubFreeGift moves the pill into PlayerGui; inert in the world)
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Text = ""
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Size = UDim2.fromScale(1, 1)
	button.ZIndex = 12
	button.Selectable = false
	button.Parent = hint
	return hint
end

local function buildGiftChest(parent, groundY, ws)
	local origin = Step.FREE_GIFT_CHEST
	local frame = facingFrame(Vector3.new(origin.X, groundY, origin.Z), -1, 0)
	local model = newModel(parent, "GiftChest", frame)
	local solid = { collide = true }
	floorDisc(model, "GlowPad", frame, 0, 0, 8.6, 0.06, C.glowGreen, 0.45)
	floorDisc(model, "GlowRing", frame, 0, 0, 9.4, 0.04, hex("#b8ffc8"), 0.72)
	local lift = 0.55 -- the chest floats over its glow pad
	local bw, bh, bd = 2.3, 2.5, 1.6 -- half width, height, half depth
	local body = boxIn(model, "ChestBody", frame, -bw, bw, lift, lift + bh, -bd, bd, C.gold, solid)
	-- red panels either side of the lock, gold corner bands, bottom trim
	boxIn(model, "Panel", frame, -bw + 0.35, -0.85, lift + 0.35, lift + bh - 0.35, -bd - 0.08, -bd + 0.05, C.red, {})
	boxIn(model, "Panel", frame, 0.85, bw - 0.35, lift + 0.35, lift + bh - 0.35, -bd - 0.08, -bd + 0.05, C.red, {})
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			boxIn(model, "Band", frame, sx * bw - 0.25, sx * bw + 0.25, lift - 0.05, lift + bh + 0.05, sz * bd - 0.25, sz * bd + 0.25, C.goldDark, {})
		end
	end
	boxIn(model, "Trim", frame, -bw - 0.1, bw + 0.1, lift - 0.12, lift + 0.3, -bd - 0.1, bd + 0.1, C.goldDark, {})
	-- lid: gold slab + rounded red top with a gold strap
	local lidBottom = lift + bh
	local lid = boxIn(model, "Lid", frame, -bw - 0.12, bw + 0.12, lidBottom, lidBottom + 0.75, -bd - 0.12, bd + 0.12, C.gold, solid)
	cylinderIn(model, "LidRound", frame, Vector3.new(0, lidBottom + 0.75 - 0.95, 0), 2 * bw + 0.2, 2 * bd, "x", C.red, {})
	cylinderIn(model, "LidStrap", frame, Vector3.new(0, lidBottom + 0.75 - 0.95, 0), 0.7, 2 * bd + 0.12, "x", C.gold, {})
	-- big cubic lock on the front seam, with a keyhole
	local lockY = lidBottom - 0.1
	boxIn(model, "Lock", frame, -0.72, 0.72, lockY - 0.75, lockY + 0.75, -bd - 0.72, -bd + 0.1, C.goldPale, { collide = false, query = true })
	boxIn(model, "LockFace", frame, -0.52, 0.52, lockY - 0.55, lockY + 0.55, -bd - 0.8, -bd - 0.6, C.goldDark, {})
	cylinderIn(model, "Keyhole", frame, Vector3.new(0, lockY + 0.12, -bd - 0.82), 0.06, 0.34, "z", C.black, { look = "smooth" })
	boxIn(model, "Keyhole", frame, -0.08, 0.08, lockY - 0.3, lockY + 0.1, -bd - 0.86, -bd - 0.8, C.black, { look = "smooth" })
	-- gem on top, glow and sparkles
	local gemY = lidBottom + 0.75 + 0.55 + 0.35
	local gem = newPart(model, "Gem", Vector3.new(0.75, 0.75, 0.75),
		frame * CFrame.new(0, gemY, 0) * CFrame.Angles(0, math.pi / 4, 0) * CFrame.Angles(math.rad(35), 0, 0), C.glowGreen, { look = "neon" })
	local light = Instance.new("PointLight")
	light.Name = "Glow"
	light.Color = hex("#9dff8a")
	light.Brightness = 1.4
	light.Range = 12
	light.Shadows = false
	light.Parent = gem
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkles"
	sparkles.TextureContent = Content.fromUri(SPARKLE_TEXTURE)
	sparkles.Rate = 6
	sparkles.Lifetime = NumberRange.new(1.2, 2)
	sparkles.Speed = NumberRange.new(0.6, 1.6)
	sparkles.SpreadAngle = Vector2.new(70, 70)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.LightEmission = 1
	sparkles.Color = ColorSequence.new(hex("#fff3a0"))
	sparkles.Size = numberSeq({ { 0, 0.35 }, { 0.5, 0.55 }, { 1, 0 } })
	sparkles.Transparency = numberSeq({ { 0, 0.1 }, { 1, 1 } })
	sparkles.Parent = gem
	-- "FREE!" label floating over the chest (above the TAP TO OPEN pill)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FreeLabel"
	billboard.Size = UDim2.new(7, 0, 3.2, 0)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 6.8, 0)
	billboard.LightInfluence = 0
	billboard.MaxDistance = 110
	billboard.AlwaysOnTop = false
	billboard.ClipsDescendants = false
	billboard.Parent = body
	signText(billboard, "Free", "FREE!", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.62), hex("#0a4d25"), { drop = 0.04 })
	signText(billboard, "Reward", FREE_GIFT_TAB_REWARD, UDim2.fromScale(0.1, 0.62), UDim2.fromScale(0.8, 0.34), C.ink,
		{ color = hex("#ffe45c"), drop = 0.03 })

	local lidTop = lidBottom + 0.75
	buildOpenHint(lid, lidTop - (lidBottom + 0.375))

	local detector = Instance.new("ClickDetector")
	detector.Name = "ChestClick"
	detector.MaxActivationDistance = 32
	detector.Parent = model

	-- restore the chest's original opener: the GroupReward prompt (GUI/GroupRewards toggles the Free Gift tab). Its host
	-- part sits ON the chest, just above the lid (inside the chest's bounds, at the gem), so the "Open / Free Gift!"
	-- prompt pops up on the chest itself; tap (touch), click (ClickablePrompt), E and ButtonX all trigger it.
	local promptPart = findPath(ws, "__OBJECTS/GroupReward")
	local prompt = promptPart and promptPart:FindFirstChildOfClass("ProximityPrompt")
	if promptPart and promptPart:IsA("BasePart") and prompt then
		promptPart.Size = Vector3.new(2, 1, 2)
		promptPart.CFrame = frame * CFrame.new(0, lidTop + Step.FREE_GIFT_PROMPT_LIFT, 0)
		promptPart.Anchored = true
		promptPart.Transparency = 1
		promptPart.CanCollide = false
		promptPart.CanQuery = false
		promptPart.CanTouch = false
		promptPart.CastShadow = false
		prompt.Enabled = true
		prompt.MaxActivationDistance = Step.FREE_GIFT_PROMPT_DISTANCE
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.ClickablePrompt = true
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		prompt.UIOffset = Vector2.new(0, 0)
		prompt.ActionText = "Open"
		prompt.ObjectText = "Free Gift!"
		prompt:SetAttribute("Theme", "Green")
		log("Free Gift chest: __OBJECTS.GroupReward sits on the chest lid (prompt %d studs, no line of sight, clickable), opens StarterGui.GroupReward.",
			Step.FREE_GIFT_PROMPT_DISTANCE)
	else
		warnf("__OBJECTS.GroupReward.ProximityPrompt missing; the chest only opens the window by click / tap")
	end
	return model, lid
end

local function buildFreeGift(ws, groundY)
	local hub = ws:FindFirstChild("Hub")
	if hub == nil then
		hub = Instance.new("Folder")
		hub.Name = "Hub"
		hub.Parent = ws
	end
	local old = hub:FindFirstChild("FreeGift")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "FreeGift"
	folder.Parent = hub
	local before = partCount
	buildClaimBoard(folder, groundY)
	buildGiftChest(folder, groundY, ws)
	return partCount - before
end

---------------------------------------------------------------------------------------------------
-- 5. Sell + Trails stalls
---------------------------------------------------------------------------------------------------

-- Awning profile (front = -Z): segments from the back ridge curving down to the front edge.
local AWNING_SEGMENTS = { { 1.9, 4 }, { 1.6, 14 }, { 1.4, 28 }, { 1.2, 46 } } -- { length, slope deg }

local function buildStall(model, frame, spec)
	local posts = { collide = false }
	local halfW = 5.0
	local backZ, frontZ = 2.1, -2.1
	-- counter: grey stud body, light top with a bevelled front edge, coloured accent band
	boxIn(model, "HubStallCounter", frame, -halfW + 0.3, halfW - 0.3, 0, 2.5, -2.0, -0.6, C.counter, posts)
	boxIn(model, "HubStallCounterTop", frame, -halfW + 0.1, halfW - 0.1, 2.5, 2.85, -2.35, -0.45, C.counterTop, posts)
	wedgeIn(model, "HubStallCounterBevel", frame, Vector3.new(0, 2.85 + 0.16, -2.35 + 0.16), Vector3.new(2 * halfW - 0.2, 0.32, 0.32),
		Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1), C.counterTop, posts)
	boxIn(model, "HubStallCounterBand", frame, -halfW + 0.5, halfW - 0.5, 1.45, 2.05, -2.08, -1.95, spec.accent, posts)
	boxIn(model, "HubStallKick", frame, -halfW + 0.3, halfW - 0.3, 0, 0.35, -2.12, -0.6, hex("#6f7a8c"), posts)
	boxIn(model, "HubStallShelf", frame, -halfW + 0.6, halfW - 0.6, 0, 1.7, 1.2, 2.0, C.counter, posts)
	boxIn(model, "HubStallShelfTop", frame, -halfW + 0.5, halfW - 0.5, 1.7, 1.95, 1.1, 2.1, C.counterTop, posts)
	-- posts (front lower, back taller) on grey plinths
	local frontTop, backTop = 8.1, 9.5
	for _, x in ipairs({ -halfW + 0.45, halfW - 0.45 }) do
		boxIn(model, "HubStallPost", frame, x - 0.4, x + 0.4, 0, frontTop, frontZ - 0.4, frontZ + 0.4, C.woodPost, posts)
		boxIn(model, "HubStallPost", frame, x - 0.4, x + 0.4, 0, backTop, backZ - 0.4, backZ + 0.4, C.woodPost, posts)
		boxIn(model, "HubStallPlinth", frame, x - 0.6, x + 0.6, 0, 0.4, frontZ - 0.6, frontZ + 0.6, C.counter, posts)
		boxIn(model, "HubStallPlinth", frame, x - 0.6, x + 0.6, 0, 0.4, backZ - 0.6, backZ + 0.6, C.counter, posts)
	end
	-- curved striped awning: stripes across the width, each a chain of segments bending down to the front
	local stripes = 7
	local awningHalf = halfW + 0.45
	local stripeW = (2 * awningHalf) / stripes
	local profile = {}
	local z, y = backZ + 0.6, backTop + 0.55
	for _, segment in ipairs(AWNING_SEGMENTS) do
		local length, slope = segment[1], math.rad(segment[2])
		local dz, dy = -length * math.cos(slope), -length * math.sin(slope)
		table.insert(profile, { z = z + dz / 2, y = y + dy / 2, length = length, slope = slope })
		z += dz
		y += dy
	end
	local edgeZ, edgeY = z, y
	for i = 1, stripes do
		local color = if i % 2 == 1 then spec.stripe else spec.stripeAlt
		local x = -awningHalf + (i - 0.5) * stripeW
		for _, seg in ipairs(profile) do
			-- tilt about local X: front edge down (positive angle lowers -Z)
			newPart(model, "HubStallAwning", Vector3.new(stripeW + 0.02, 0.3, seg.length + 0.08),
				frame * CFrame.new(x, seg.y, seg.z) * CFrame.Angles(-seg.slope, 0, 0), color, posts)
		end
		-- scalloped valance: a half-round tab hanging from each stripe
		cylinderIn(model, "HubStallScallop", frame, Vector3.new(x, edgeY - 0.1, edgeZ + 0.05), 0.24, stripeW * 0.98, "z", color, posts)
	end
	-- back ridge beam
	boxIn(model, "HubStallRidge", frame, -awningHalf - 0.1, awningHalf + 0.1, backTop + 0.25, backTop + 0.85, backZ + 0.2, backZ + 1.0, spec.stripe, posts)

	-- rounded sign on two short posts above the ridge, readable from both sides: dark outline ring, coloured
	-- rounded board, and on both faces a glossy rounded face (white rim) with big white text
	local signW, signH, radius = spec.signWidth, spec.signHeight, spec.signRadius
	local signBottom = backTop + 1.55
	local signZ = backZ + 0.6
	local cy = signBottom + signH / 2
	for _, x in ipairs({ -signW / 2 + 1.1, signW / 2 - 1.1 }) do
		boxIn(model, "HubStallSignPost", frame, x - 0.22, x + 0.22, backTop + 0.85, cy, signZ - 0.22, signZ + 0.22, C.woodPost, posts)
	end
	local smooth = { collide = false, look = "smooth" }
	local outline = 0.3
	roundedSlab(model, "HubStallSignOutline", frame, 0, cy, signW + 2 * outline, signH + 2 * outline, signZ - 0.24, signZ + 0.24,
		radius + outline, spec.outline, smooth)
	roundedSlab(model, "HubStallSign", frame, 0, cy, signW, signH, signZ - 0.32, signZ + 0.32, radius, spec.board, smooth)
	-- invisible face carrier: exactly the board outline, its Front/Back faces just proud of the board
	local carrier = boxIn(model, "HubStallSignFace", frame, -signW / 2, signW / 2, cy - signH / 2, cy + signH / 2, signZ - 0.34, signZ + 0.34,
		spec.board, { collide = false, look = "smooth", transparency = 1, shadow = false })
	local pps = 40
	for _, faceId in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = newSurface(carrier, "HubSignFace", faceId, pps, 1.15)
		local inner = roundedFace(gui, math.floor(radius * pps), 9, spec.face, spec.studs)
		signText(inner, "Title", spec.text, UDim2.fromScale(0.06, 0.08), UDim2.fromScale(0.88, 0.8), spec.textStroke, { thickness = 0.13 })
	end
	-- optional floor glow (decor only, not a Stands.Pads pad)
	if spec.glow then
		floorDisc(model, "HubStallGlow", frame, 0, -3.3, 11, 0.05, spec.glow, 0.55)
	end
end

local function projectXZ(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function remodelStalls(ws, groundY)
	local stands = ws:FindFirstChild("Stands")
	local models = stands and stands:FindFirstChild("Models")
	if models == nil then
		warnf("Workspace.Stands.Models missing; stalls not remodelled")
		return 0
	end
	local built = 0
	local before = partCount

	-- Sell: centred on its old counter, facing the SellAll / SellHeldAsset prompts (the customers' side)
	local sell = models:FindFirstChild("Sell Stands")
	local sellAll = findPath(stands, "Prompts/SellAll")
	local sellHeld = findPath(stands, "Prompts/SellHeldAsset")
	if sell and sellAll and sellHeld then
		local counter = sell:FindFirstChild("Shop Stand")
		local center = if counter and counter:IsA("BasePart") then counter.CFrame.Position else (sellAll.CFrame.Position + sellHeld.CFrame.Position) / 2
		local mid = (sellAll.CFrame.Position + sellHeld.CFrame.Position) / 2
		local dir = projectXZ(mid - center)
		if dir.Magnitude < 0.5 then
			dir = Vector3.new(-1, 0, 0)
		end
		dir = dir.Unit
		for _, child in ipairs(sell:GetChildren()) do
			child:Destroy()
		end
		local frame = facingFrame(Vector3.new(center.X, groundY, center.Z), dir.X, dir.Z)
		buildStall(sell, frame, {
			stripe = C.red, stripeAlt = C.white, accent = C.red, text = "SELL",
			signWidth = 7.6, signHeight = 3.4, signRadius = 1.0,
			board = hex("#e8262e"), outline = hex("#4a0610"), textStroke = hex("#5c0010"), studs = hex("#ffd0d0"),
			face = { { 0, "#ff8f8f" }, { 0.45, "#ff3444" }, { 1, "#c40f24" } },
			glow = C.cyan,
		})
		sell.WorldPivotData = frame
		sell:SetAttribute("HubRemodel", true)
		built += 1
	else
		warnf("Stands.Models.Sell Stands / Prompts.SellAll / Prompts.SellHeldAsset missing; Sell stall not remodelled")
	end

	-- Trails: centred on Pads.TrailShop, facing the hub spawn
	local trails = models:FindFirstChild("GearShopStand")
	local pad = findPath(stands, "Pads/TrailShop")
	if trails and pad and pad:IsA("BasePart") then
		local center = pad.CFrame.Position
		local spawn = ws:FindFirstChild("SpawnLocation")
		local target = if spawn and spawn:IsA("BasePart") then spawn.CFrame.Position else Vector3.new(37, 0, 0)
		local dir = projectXZ(target - center)
		dir = if dir.Magnitude > 0.5 then dir.Unit else Vector3.new(-1, 0, 0)
		for _, child in ipairs(trails:GetChildren()) do
			if child.Name ~= "StandBounds" then
				child:Destroy()
			end
		end
		local frame = facingFrame(Vector3.new(center.X, groundY, center.Z), dir.X, dir.Z)
		buildStall(trails, frame, {
			stripe = C.yellow, stripeAlt = C.cream, accent = C.yellow, text = "TRAILS SHOP",
			signWidth = 10.4, signHeight = 4.6, signRadius = 1.2,
			board = hex("#ffa90f"), outline = hex("#5a2d00"), textStroke = hex("#6b3300"), studs = hex("#fff1c2"),
			face = { { 0, "#ffe46b" }, { 0.5, "#ffb21a" }, { 1, "#f07a00" } },
		})
		trails.WorldPivotData = frame
		trails:SetAttribute("HubRemodel", true)
		built += 1
	else
		warnf("Stands.Models.GearShopStand / Pads.TrailShop missing; Trails stall not remodelled")
	end
	log("Stalls: %d rebuilt (%d parts).", built, partCount - before)
	return built
end

---------------------------------------------------------------------------------------------------

function Step.Apply(place, _spPlace, ctx)
	local ws = place:GetService("Workspace")
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

	section("fences", function()
		remodelFences(ws, groundY)
	end)
	section("signs", function()
		local framed = remodelSigns(ws, groundY)
		local faces, buttons = Step.RestyleSignFaces(place)
		log("Upgrade signs: %d framed, %d faces, %d price buttons (incl. the FirstUpgrade template).", framed, faces, buttons)
		if installLateSignPass() then
			log("Sign faces will be re-applied right after ui_40_world (its Apply is wrapped at build time).")
		end
	end)
	section("leaderboard", function()
		local n = remodelLeaderboard(ws, groundY)
		log("Leaderboard1: %d parts (screen + title kept).", n)
	end)
	section("free gift", function()
		local n = buildFreeGift(ws, groundY)
		log("Free Gift corner (Workspace.Hub.FreeGift): CLICK TO CLAIM board + gift chest, %d parts.", n)
	end)
	section("stalls", function()
		remodelStalls(ws, groundY)
	end)

	log("Done: %d new parts, %d warning(s).", partCount, #warnings)
	if #failures > 0 then
		error("post_hub_remodel failed: " .. table.concat(failures, " | "))
	end
end

return Step
