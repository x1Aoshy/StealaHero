-- ReplicatedStorage.Library.Modules.BaseDoors
-- Automatic base doors (owner 2026-09-26: "make sure the doors open ... for all the bases ... when you go up").
-- Every plot's gate gets a themed, purely visual door (built on each client by
-- StarterPlayerScripts.Game.Plots.BaseDoorController): it opens while ANY player's character is within
-- TRIGGER_RADIUS studs of the door centre and closes CLOSE_DELAY seconds after the last one left. Everything in the
-- bases is non-collidable, so the door never blocks anyone: it only has to look right and move nicely.
--
-- Data (written at build time by scripts/steps/post_zzz_base_doors.luau on every Workspace.Plots.<n>):
--   GateOrigin (Vector3)   the gate centre on the floor (the StarterPen gate), world space
--   GateOutward (Vector3)  unit, out of the pen through the gate;  GateRight (Vector3) unit, across the gate
--   GateHalfWidth          half the StarterPen gate (post centre to post centre)
--   PenOrigin / PenHalfDepth / PenHalfWidth   the pen frame (post_zz_base_themes Step.measurePen)
--   DoorGeometry_<Key>     (string, Key = a Directory.BaseThemes key or "None") the clear opening of that look:
--                          "vMin=.. vMax=.. top=.. wLeft=.. wRight=.. uMin=.. uMax=.." in the gate frame
--                          (v across from the gate centre, u outward from the fence line, h up from the floor):
--                          the opening spans vMin..vMax under the lintel `top`, the pylons are wLeft / wRight wide and
--                          stand between uMin and uMax. Measured from the modelled pen (layout pieces) per plot.
-- Door frame: CFrame.fromMatrix(GateOrigin, GateRight, up, -GateOutward): local x = v, y = h, z = -u (inside the pen
-- is +z). A player outside looking in sees local +x on their LEFT.
--
-- Styles (one per theme + "None" for the plain pen), all Anchored / CanCollide / CanQuery / CanTouch false, plain
-- SmoothPlastic / Plastic / Marble / Wood / Metal / DiamondPlate (never a glowing material, never a light object):
--   None     hub-fence gate: two navy + wood stud leaves (the plaza fence style) swinging inward on the posts
--   Forest   Stark Lab: telescopic sci-fi panels with a cyan strip and a split arc-reactor ring, sliding into the
--            pylons (the tower side parks deeper: its inner face curves in toward the floor)
--   Lake     Hall of Justice: marble double doors with gold trim and a blue "J" / "L", swinging inward
--   Desert   Brooklyn Rooftop: a graffiti roll-up shutter that rolls into a housing under the crest
--   Jungle   U.A. Hero Arena: heavy "U" / "A" blast doors (hazard kick plates) sliding into the pylons
--   Snow     Capsule Corp: rounded white / blue split doors with the Capsule Corp logo; the halves part, then sink
--            into the floor (its pylons are round columns, nothing could park in them)
--   Volcano  Sunny Pirate Wharf: wooden plank gates with iron bands swinging inward
-- Loadable at build time with Lune: nothing at file scope touches game / script / services.

local BaseDoors = {}

BaseDoors.TRIGGER_RADIUS = 10 -- studs from the door centre: any player's character this close opens it
BaseDoors.CLOSE_DELAY = 2.5 -- seconds with nobody in range before it closes
BaseDoors.CHECK_INTERVAL = 0.1 -- proximity checks run at ~10 Hz
BaseDoors.FAR_DISTANCE = 150 -- doors farther than this from the camera are not checked (nor animated)
BaseDoors.SOUND_RANGE = 40 -- the open / close cue rolls off to silence at this distance
BaseDoors.CENTRE_HEIGHT = 3 -- the trigger centre sits this high above the floor (a character's root)

BaseDoors.NONE = "None"
BaseDoors.THEME_KEYS = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }
BaseDoors.ATTR = {
	Origin = "GateOrigin",
	Outward = "GateOutward",
	Right = "GateRight",
	HalfWidth = "GateHalfWidth",
	PenOrigin = "PenOrigin",
	PenHalfDepth = "PenHalfDepth",
	PenHalfWidth = "PenHalfWidth",
	GeometryPrefix = "DoorGeometry_",
}
BaseDoors.GEOMETRY_FIELDS = { "vMin", "vMax", "top", "wLeft", "wRight", "uMin", "uMax" }

-- Fallback openings (the six modelled pens as measured on 2026-09-26, and the plain StarterPen): used when a plot has
-- no DoorGeometry_<Key> attribute (an older build) or it does not parse.
BaseDoors.DefaultGeometry = {
	None = { vMin = -4.65, vMax = 4.65, top = 4.2, wLeft = 1.2, wRight = 1.2, uMin = -0.6, uMax = 0.6 },
	Forest = { vMin = -4.49, vMax = 4.04, top = 7.52, wLeft = 1.38, wRight = 2.33, uMin = -0.52, uMax = 1.41 },
	Lake = { vMin = -3.95, vMax = 3.95, top = 7.55, wLeft = 2.4, wRight = 2.4, uMin = -0.62, uMax = 2.16 },
	Desert = { vMin = -4.0, vMax = 4.0, top = 7.96, wLeft = 2.46, wRight = 2.39, uMin = -0.56, uMax = 1.6 },
	Jungle = { vMin = -3.97, vMax = 3.97, top = 7.5, wLeft = 2.46, wRight = 2.46, uMin = -0.56, uMax = 1.9 },
	Snow = { vMin = -3.97, vMax = 3.97, top = 8.49, wLeft = 2.1, wRight = 2.1, uMin = -0.5, uMax = 1.5 },
	Volcano = { vMin = -3.96, vMax = 3.96, top = 7.52, wLeft = 1.58, wRight = 1.58, uMin = -0.52, uMax = 0.72 },
}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Open / close cues: whitelisted Library.Audio ids (Audio.SPEEDSTERS_AUDIO[Id]) pitched down into a soft mechanical
-- thump; quiet, and only audible within SOUND_RANGE.
local function cue(speedOpen, speedClose, volume)
	return {
		Open = { Id = "UI_POP", Speed = speedOpen, Volume = volume },
		Close = { Id = "UI_POP", Speed = speedClose, Volume = volume * 0.85 },
	}
end

BaseDoors.Styles = {
	None = {
		Name = "Hub fence gate",
		Kind = "swing",
		InLine = true, -- hung between the posts, in the fence line
		Open = 0.9,
		Close = 1.0,
		Ease = "Cubic",
		Angle = 100,
		MaxHeight = 3.95,
		Bottom = 0.12,
		Thickness = 0.42,
		Overlap = 0,
		Gap = 0.06,
		MaterialVariant = "Studs", -- the plaza's stud look (MaterialService, scripts/steps/ground.luau)
		Colors = {
			navy = rgb(27, 39, 66), navyLight = rgb(43, 60, 102), wood = rgb(207, 118, 48), woodDark = rgb(176, 96, 31),
			woodTop = rgb(227, 139, 55), gold = rgb(255, 194, 26),
		},
		Sound = cue(0.8, 0.7, 0.35),
	},
	Forest = {
		Name = "Stark Lab sliding panels",
		Kind = "slide",
		Open = 0.65,
		Close = 0.8,
		Ease = "Quint",
		MaxHeight = 7.45,
		Bottom = 0.1,
		Thickness = 0.22,
		Overlap = 0.06,
		MaxSegments = 5,
		-- the +x pylon is the glass tower, whose inner face curves in toward the floor: park that leaf deeper
		Park = { [1] = 0.6 },
		Colors = {
			steel = rgb(160, 172, 184), graphite = rgb(36, 44, 53), cyan = rgb(95, 211, 255), white = rgb(235, 244, 255),
			red = rgb(179, 32, 42),
		},
		Sound = cue(0.95, 0.85, 0.4),
	},
	Lake = {
		Name = "Hall of Justice doors",
		Kind = "swing",
		Open = 1.3,
		Close = 1.4,
		Ease = "Sine",
		Angle = 92,
		MaxHeight = 7.5,
		Bottom = 0.1,
		Thickness = 0.36,
		Overlap = 0.22,
		Gap = 0.05,
		Letters = { Left = "J", Right = "L" }, -- as read from outside: the +x leaf is on the left
		Colors = {
			marble = rgb(238, 228, 204), gold = rgb(238, 184, 62), goldLight = rgb(250, 214, 96), blue = rgb(30, 50, 112),
			blueDark = rgb(18, 32, 80),
		},
		Sound = cue(0.55, 0.5, 0.45),
	},
	Desert = {
		Name = "Brooklyn roll-up shutter",
		Kind = "rollup",
		Open = 1.1,
		Close = 1.2,
		Ease = "Quad",
		Bottom = 0.1,
		Housing = 0.92,
		Colors = {
			shutter = rgb(96, 106, 128), slat = rgb(52, 58, 78), housing = rgb(66, 84, 118), iron = rgb(30, 30, 38),
			bar = rgb(255, 206, 46), magenta = rgb(255, 47, 180), cyan = rgb(34, 228, 255), yellow = rgb(255, 226, 58),
			white = rgb(238, 240, 246), red = rgb(214, 24, 40),
		},
		Sound = cue(0.5, 0.45, 0.4),
	},
	Jungle = {
		Name = "U.A. blast doors",
		Kind = "slide",
		Open = 1.2,
		Close = 1.3,
		Ease = "Quart",
		MaxHeight = 7.45,
		Bottom = 0.1,
		Thickness = 0.46,
		Overlap = 0.06,
		MaxSegments = 4,
		Letters = { Left = "U", Right = "A" },
		Colors = {
			steel = rgb(196, 202, 212), kick = rgb(240, 196, 60), black = rgb(24, 24, 32), red = rgb(212, 42, 42),
			navy = rgb(28, 61, 110), gold = rgb(244, 200, 42), white = rgb(244, 246, 250),
		},
		Sound = cue(0.38, 0.34, 0.5),
	},
	Snow = {
		Name = "Capsule Corp split doors",
		Kind = "sink", -- the pylons are round columns: the halves part, then drop into the floor
		Open = 1.1,
		Close = 1.2,
		Ease = "Cubic",
		MaxHeight = 7.2,
		Bottom = 0.1,
		Thickness = 0.34,
		Reach = 0.06, -- each half reaches this far into its column
		Part = 0.45, -- the halves first part this far sideways ...
		PartShare = 0.3, -- ... during this share of the move, then sink
		Colors = {
			pearl = rgb(246, 244, 236), blue = rgb(31, 95, 214), blueDark = rgb(18, 52, 130), orange = rgb(255, 138, 31),
			white = rgb(255, 255, 255),
		},
		Sound = cue(0.85, 0.75, 0.4),
	},
	Volcano = {
		Name = "Sunny wharf gates",
		Kind = "swing",
		Open = 1.0,
		Close = 1.15,
		Ease = "Cubic",
		Angle = 104,
		MaxHeight = 6.4,
		Bottom = 0.1,
		Thickness = 0.34,
		Overlap = 0.2,
		Gap = 0.04,
		Colors = {
			plank = rgb(178, 88, 48), wood = rgb(140, 92, 46), woodLight = rgb(186, 132, 76), woodDark = rgb(91, 58, 30),
			iron = rgb(58, 52, 52), gold = rgb(224, 176, 64), red = rgb(192, 40, 45),
		},
		Sound = cue(0.6, 0.52, 0.45),
	},
}

---------------------------------------------------------------------------------------------------
-- geometry / attributes
---------------------------------------------------------------------------------------------------

-- The style key for a plot's BaseTheme attribute ("" / nil / unknown = the plain pen).
function BaseDoors.StyleKey(themeKey)
	if type(themeKey) == "string" and themeKey ~= "" and themeKey ~= BaseDoors.NONE and BaseDoors.Styles[themeKey] then
		return themeKey
	end
	return BaseDoors.NONE
end

function BaseDoors.FormatGeometry(g)
	local out = {}
	for _, field in ipairs(BaseDoors.GEOMETRY_FIELDS) do
		table.insert(out, string.format("%s=%.3f", field, g[field]))
	end
	return table.concat(out, " ")
end

-- A geometry table from a DoorGeometry string (nil when a field is missing or the opening is implausible).
function BaseDoors.ParseGeometry(text)
	if type(text) ~= "string" then
		return nil
	end
	local g = {}
	for field, value in string.gmatch(text, "(%a+)=(%-?[%d%.]+)") do
		g[field] = tonumber(value)
	end
	for _, field in ipairs(BaseDoors.GEOMETRY_FIELDS) do
		if type(g[field]) ~= "number" or g[field] ~= g[field] then
			return nil
		end
	end
	if g.vMax - g.vMin < 4 or g.vMax - g.vMin > 16 or g.top < 3 or g.top > 20 or g.uMax <= g.uMin then
		return nil
	end
	return g
end

local function copyGeometry(g)
	local out = {}
	for _, field in ipairs(BaseDoors.GEOMETRY_FIELDS) do
		out[field] = g[field]
	end
	return out
end

function BaseDoors.ReadGeometry(plot, styleKey)
	local key = BaseDoors.StyleKey(styleKey)
	local g = BaseDoors.ParseGeometry(plot:GetAttribute(BaseDoors.ATTR.GeometryPrefix .. key))
	return g or copyGeometry(BaseDoors.DefaultGeometry[key] or BaseDoors.DefaultGeometry.None)
end

-- The door frame of a plot (nil when the build did not write the gate attributes).
function BaseDoors.GateFrame(plot)
	local origin = plot:GetAttribute(BaseDoors.ATTR.Origin)
	local outward = plot:GetAttribute(BaseDoors.ATTR.Outward)
	local right = plot:GetAttribute(BaseDoors.ATTR.Right)
	if typeof(origin) ~= "Vector3" or typeof(outward) ~= "Vector3" or typeof(right) ~= "Vector3" then
		return nil
	end
	return CFrame.fromMatrix(origin, right.Unit, Vector3.new(0, 1, 0), -outward.Unit)
end

---------------------------------------------------------------------------------------------------
-- open / close state machine (pure: the controller and the offline tests drive it)
---------------------------------------------------------------------------------------------------

function BaseDoors.NewState()
	return { open = false, alpha = 0, lastNear = -math.huge }
end

-- One proximity sample. Returns "open" / "close" when the door's target changes, else nil.
function BaseDoors.Update(state, now, near)
	if near then
		state.lastNear = now
		if not state.open then
			state.open = true
			return "open"
		end
	elseif state.open and now - state.lastNear >= BaseDoors.CLOSE_DELAY then
		state.open = false
		return "close"
	end
	return nil
end

-- Moves the linear progress toward the target over the style's Open / Close seconds. True while still moving.
function BaseDoors.Advance(state, dt, style)
	local target = if state.open then 1 else 0
	if state.alpha == target then
		return false
	end
	local duration = if state.open then (style and style.Open or 1) else (style and style.Close or 1)
	local step = dt / math.max(duration, 0.05)
	if target > state.alpha then
		state.alpha = math.min(1, state.alpha + step)
	else
		state.alpha = math.max(0, state.alpha - step)
	end
	return state.alpha ~= target
end

-- In-out easing curves (0..1 -> 0..1, no overshoot so nothing ever leaves the opening / pylons).
function BaseDoors.Ease(kind, t)
	t = math.clamp(t, 0, 1)
	if kind == "Linear" then
		return t
	elseif kind == "Sine" then
		return -(math.cos(math.pi * t) - 1) / 2
	end
	local power = if kind == "Quad" then 2 elseif kind == "Quart" then 4 elseif kind == "Quint" then 5 else 3
	if t < 0.5 then
		return 2 ^ (power - 1) * t ^ power
	end
	return 1 - (-2 * t + 2) ^ power / 2
end

-- True when any of the positions lies within `radius` of `centre`.
function BaseDoors.AnyWithin(centre, positions, radius)
	local r2 = radius * radius
	for _, position in ipairs(positions) do
		local d = position - centre
		if d.X * d.X + d.Y * d.Y + d.Z * d.Z <= r2 then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------------------------------
-- building (client side; the offline tests build every style with Lune)
---------------------------------------------------------------------------------------------------

local Door = {}
Door.__index = Door

function Door:Pose(e)
	local frame = self.frame
	for _, piece in ipairs(self.pieces) do
		local cf, size = piece.pose(e)
		if size then
			piece.part.Size = size
		end
		piece.part.CFrame = frame * cf
	end
	self.eased = e
end

function Door:Destroy()
	if self.model then
		self.model:Destroy()
	end
	self.pieces = {}
end

local function newPart(parent, name, size, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.Parent = parent
	return part
end

local function addPiece(door, part, pose)
	table.insert(door.pieces, { part = part, pose = pose })
	table.insert(door.parts, part)
end

-- A SurfaceGui on the part's Front face (the side facing out of the pen), in pixels per stud; returns its clipping root.
local function frontGui(part, pixelsPerStud)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "DoorArt"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud
	gui.LightInfluence = 1
	gui.Parent = part
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.ClipsDescendants = true
	root.Parent = gui
	return root
end

local function guiFrame(parent, name, color, anchor, position, size, round)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.AnchorPoint = anchor
	frame.Position = position
	frame.Size = size
	frame.Parent = parent
	if round then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(round, 0)
		corner.Parent = frame
	end
	return frame
end

local function guiText(parent, name, text, color, font, anchor, position, size, strokeColor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.FontFace = Font.fromEnum(font)
	label.TextScaled = true
	label.TextWrapped = true
	label.AnchorPoint = anchor
	label.Position = position
	label.Size = size
	label.Parent = parent
	if strokeColor then
		local stroke = Instance.new("UIStroke")
		stroke.Color = strokeColor
		stroke.Thickness = 2
		stroke.Parent = label
	end
	return label
end

-- An emblem drawn centred on a leaf's leading edge (the centre seam), so the two leaves' halves read as one emblem
-- when closed. Front-face canvas: its right edge is the part's -x side, so the +x leaf's seam is the right edge.
local function seamEmblem(part, side, partHeight, centreY, radiusStuds, draw)
	local pps = 50
	local root = frontGui(part, pps)
	local size = math.floor(radiusStuds * 2 * pps)
	local holder = Instance.new("Frame")
	holder.Name = "Emblem"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(if side > 0 then 1 else 0, 0, 0, math.floor((partHeight - centreY) * pps))
	holder.Size = UDim2.fromOffset(size, size)
	holder.Parent = root
	draw(holder)
	return holder
end

---------------------------------------------------------------------------------------------------
-- swing doors: two leaves on vertical hinges at the opening edges, swinging into the pen
---------------------------------------------------------------------------------------------------

local LEAVES = {}

-- leaf helper: `x` = distance of the part centre from the hinge along the leaf, y = height, z = offset from the leaf's
-- centre plane (negative = the outer face).
local function leafAdder(leaf, side, list, material, variant)
	return function(name, size, x, y, z, color, mat, shape, rotation)
		local part = newPart(leaf, name, size, color, mat or material, shape)
		if variant then
			part.MaterialVariant = variant
		end
		table.insert(list, { part, CFrame.new(-side * x, y, z or 0) * (rotation or CFrame.new()) })
		return part
	end
end

-- None: the hub fence gate (navy hinge stile, wood rails / pickets / Z brace, gold knob), Plastic + the stud variant.
LEAVES.None = function(leaf, side, L, H, bottom, t, style)
	local C = style.Colors
	local list = {}
	local add = leafAdder(leaf, side, list, Enum.Material.Plastic, style.MaterialVariant)
	local low, high = 0.83, math.min(3.58, H - 0.4)
	add("HingeStile", Vector3.new(0.5, H - bottom, 0.5), 0.25, bottom + (H - bottom) / 2, 0, C.navy)
	add("LatchStile", Vector3.new(0.42, H - bottom - 0.35, t), L - 0.21, bottom + (H - bottom - 0.35) / 2, 0, C.wood)
	add("RailLow", Vector3.new(L - 0.9, 0.55, t), 0.5 + (L - 0.9) / 2, low, 0, C.woodDark)
	add("RailTop", Vector3.new(L - 0.9, 0.62, t + 0.04), 0.5 + (L - 0.9) / 2, high, 0, C.woodTop)
	for i = 1, 2 do
		local x = 0.5 + (L - 0.9) * i / 3
		add("Picket", Vector3.new(0.34, high - low, t - 0.08), x, (low + high) / 2, 0, C.wood)
	end
	-- the Z brace from the low hinge corner to the high latch corner
	local dx, dy = L - 1.1, (high - 0.31) - (low + 0.28)
	local length = math.sqrt(dx * dx + dy * dy)
	add("Brace", Vector3.new(length, 0.36, t - 0.04), 0.55 + dx / 2, (low + 0.28 + high - 0.31) / 2, 0, C.wood, nil, nil,
		CFrame.Angles(0, 0, math.atan2(dy, -side * dx)))
	add("Strap", Vector3.new(0.9, 0.2, t + 0.1), 0.45, high, 0, C.navyLight)
	add("Strap", Vector3.new(0.9, 0.2, t + 0.1), 0.45, low, 0, C.navyLight)
	add("Knob", Vector3.new(0.42, 0.42, 0.42), L - 0.22, 2.1, -t / 2 - 0.16, C.gold, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	return list
end

-- Lake: a marble leaf, gold frame and band, a blue inset with the gold "J" / "L", a gold ring pull.
LEAVES.Lake = function(leaf, side, L, H, bottom, t, style)
	local C = style.Colors
	local list = {}
	local add = leafAdder(leaf, side, list, Enum.Material.SmoothPlastic)
	local face = -t / 2 - 0.04
	add("Slab", Vector3.new(L, H - bottom, t), L / 2, bottom + (H - bottom) / 2, 0, C.marble, Enum.Material.Marble)
	add("TrimTop", Vector3.new(L, 0.3, 0.08), L / 2, H - 0.15, face, C.gold)
	add("TrimLow", Vector3.new(L, 0.42, 0.08), L / 2, bottom + 0.21, face, C.gold)
	add("TrimHinge", Vector3.new(0.28, H - bottom, 0.08), 0.14, bottom + (H - bottom) / 2, face, C.gold)
	add("TrimLatch", Vector3.new(0.28, H - bottom, 0.08), L - 0.14, bottom + (H - bottom) / 2, face, C.gold)
	local bandY = bottom + (H - bottom) * 0.42
	add("Band", Vector3.new(L - 0.3, 0.26, t + 0.1), L / 2, bandY, 0, C.gold)
	local upperLow, upperHigh = bandY + 0.4, H - 0.55
	local inset = add("InsetHigh", Vector3.new(L - 1.0, upperHigh - upperLow, 0.06), L / 2, (upperLow + upperHigh) / 2, face + 0.01, C.blue)
	local lowerLow, lowerHigh = bottom + 0.7, bandY - 0.4
	add("InsetLow", Vector3.new(L - 1.0, lowerHigh - lowerLow, 0.06), L / 2, (lowerLow + lowerHigh) / 2, face + 0.01, C.blue)
	add("Pull", Vector3.new(0.5, 0.5, 0.5), L - 0.6, bandY - 0.75, -t / 2 - 0.2, C.goldLight, nil, Enum.PartType.Ball)
	add("PullIn", Vector3.new(0.44, 0.44, 0.44), L - 0.6, bandY - 0.75, t / 2 + 0.18, C.goldLight, nil, Enum.PartType.Ball)
	-- the letter reads from outside: the +x leaf is on the viewer's left
	local letter = if side > 0 then style.Letters.Left else style.Letters.Right
	local root = frontGui(inset, 40)
	guiText(root, "Letter", letter, C.goldLight, Enum.Font.GothamBlack, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5),
		UDim2.fromScale(0.8, 0.62), C.blueDark)
	return list
end

-- Volcano: four rough planks of varied height, two iron bands, an iron pull on a plate.
LEAVES.Volcano = function(leaf, side, L, H, bottom, t, style)
	local C = style.Colors
	local list = {}
	local add = leafAdder(leaf, side, list, Enum.Material.Wood)
	local planks = 4
	local width = L / planks
	local heights = { 0.96, 1.0, 0.93, 0.98 }
	local colours = { C.plank, C.wood, C.woodLight, C.plank }
	for i = 1, planks do
		local h = (H - bottom) * heights[i]
		add("Plank", Vector3.new(width - 0.04, h, t), (i - 0.5) * width, bottom + h / 2, 0, colours[i])
	end
	for _, y in ipairs({ bottom + 1.2, bottom + (H - bottom) * 0.72 }) do
		add("Band", Vector3.new(L - 0.05, 0.36, t + 0.1), L / 2, y, 0, C.iron, Enum.Material.Metal)
	end
	add("Plate", Vector3.new(0.62, 0.62, 0.06), L - 0.55, bottom + 2.9, -t / 2 - 0.03, C.iron, Enum.Material.Metal)
	add("Pull", Vector3.new(0.34, 0.34, 0.34), L - 0.55, bottom + 2.9, -t / 2 - 0.16, C.gold, Enum.Material.Metal, Enum.PartType.Ball)
	return list
end

local function buildSwing(door, g, style)
	local t = style.Thickness
	local c = (g.vMin + g.vMax) / 2
	local H = math.min(g.top - 0.05, style.MaxHeight)
	local bottom = style.Bottom
	local z = if style.InLine then -(g.uMin + g.uMax) / 2 else -g.uMin + t / 2 + 0.04
	local angle = math.rad(style.Angle)
	local build = LEAVES[door.key] or LEAVES.None
	for _, side in ipairs({ -1, 1 }) do
		local edge = if side > 0 then g.vMax else g.vMin
		local hingeX = if style.InLine then edge - side * 0.02 else edge + side * style.Overlap
		local L = math.abs(hingeX - c) - style.Gap / 2
		local hinge = CFrame.new(hingeX, 0, z)
		local leaf = Instance.new("Model")
		leaf.Name = if side > 0 then "LeafPlusX" else "LeafMinusX"
		leaf.Parent = door.model
		for _, entry in ipairs(build(leaf, side, L, H, bottom, t, style)) do
			local rest = entry[2]
			addPiece(door, entry[1], function(e)
				return hinge * CFrame.Angles(0, side * angle * e, 0) * rest
			end)
		end
	end
	door.height = H
	door.plane = z
end

---------------------------------------------------------------------------------------------------
-- sliding doors: each leaf is 1..MaxSegments telescopic segments that all park inside the pylon
---------------------------------------------------------------------------------------------------

local SEGMENTS = {}

-- segment helper: parts relative to the segment centre (x across, y = height above the floor, z = offset from the
-- segment plane; negative = the outer face).
local function segmentAdder(segment, list, material)
	return function(name, size, x, y, z, color, mat, shape, rotation)
		local part = newPart(segment, name, size, color, mat or material, shape)
		table.insert(list, { part, CFrame.new(x, y, z or 0) * (rotation or CFrame.new()) })
		return part
	end
end

-- Forest: steel panel, graphite kick plate, a cyan strip across every segment, a cyan leading edge and the
-- arc-reactor ring split across the seam.
SEGMENTS.Forest = function(segment, side, k, _n, sw, H, bottom, t, style)
	local C = style.Colors
	local list = {}
	local add = segmentAdder(segment, list)
	local panel = add("Panel", Vector3.new(sw, H - bottom, t), 0, bottom + (H - bottom) / 2, 0, C.steel)
	add("Kick", Vector3.new(sw, 0.45, t + 0.04), 0, bottom + 0.225, 0, C.graphite)
	add("Strip", Vector3.new(sw, 0.14, t + 0.05), 0, bottom + (H - bottom) * 0.58, 0, C.cyan)
	add("Cap", Vector3.new(sw, 0.16, t + 0.04), 0, H - 0.08, 0, C.graphite)
	if k == 1 then
		add("Edge", Vector3.new(0.14, H - bottom - 0.9, t + 0.05), -side * (sw / 2 - 0.07), bottom + 0.45 + (H - bottom - 0.9) / 2, 0, C.cyan)
		seamEmblem(panel, side, H - bottom, (H - bottom) * 0.58 + 1.1, 0.62, function(holder)
			local ring = guiFrame(holder, "Ring", C.graphite, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1), 0.5)
			local stroke = Instance.new("UIStroke")
			stroke.Color = C.cyan
			stroke.Thickness = 5
			stroke.Parent = ring
			guiFrame(ring, "Core", C.white, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.42, 0.42), 0.5)
		end)
	end
	return list
end

-- Jungle: heavy silver slabs with a hazard kick plate, a red band and a navy cap; the leading segments carry the big
-- gold "U" / "A" on navy plates.
SEGMENTS.Jungle = function(segment, side, k, _n, sw, H, bottom, t, style)
	local C = style.Colors
	local list = {}
	local add = segmentAdder(segment, list)
	add("Panel", Vector3.new(sw, H - bottom, t), 0, bottom + (H - bottom) / 2, 0, C.steel, Enum.Material.Metal)
	local kick = add("Kick", Vector3.new(sw, 0.8, t + 0.06), 0, bottom + 0.4, 0, C.kick)
	add("Band", Vector3.new(sw, 0.5, t + 0.05), 0, bottom + (H - bottom) * 0.74, 0, C.red)
	add("Cap", Vector3.new(sw, 0.34, t + 0.06), 0, H - 0.17, 0, C.navy)
	add("Rib", Vector3.new(sw, 0.18, t + 0.04), 0, bottom + 1.0, 0, C.navy, Enum.Material.DiamondPlate)
	-- hazard stripes on the kick plate
	local root = frontGui(kick, 30)
	local bars = math.max(2, math.floor(sw * 30 / 16))
	for i = 0, bars - 1, 2 do
		guiFrame(root, "Hazard", C.black, Vector2.new(0, 0), UDim2.new(i / bars, 0, 0, 0), UDim2.new(1 / bars, 0, 1, 0))
	end
	if k == 1 then
		local plateW = math.min(sw - 0.3, 2.0)
		local plate = add("Crest", Vector3.new(plateW, 2.3, 0.06), -side * (sw / 2 - 0.15 - plateW / 2), bottom + (H - bottom) * 0.45, -t / 2 - 0.03, C.navy)
		local letter = if side > 0 then style.Letters.Left else style.Letters.Right
		local art = frontGui(plate, 40)
		guiText(art, "Letter", letter, C.gold, Enum.Font.GothamBlack, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5),
			UDim2.fromScale(0.86, 0.86), C.white)
	end
	return list
end

BaseDoors.PARK = 0.16 -- parked segments stop this far inside the pylon
BaseDoors.TAIL = 0.16 -- the outermost closed segment reaches this far behind the pylon face (no light slit)

local function buildSlide(door, g, style)
	local c = (g.vMin + g.vMax) / 2
	local zMid = -(g.uMin + g.uMax) / 2
	local depth = math.max(g.uMax - g.uMin, 0.6)
	local H = math.min(g.top - 0.05, style.MaxHeight)
	local bottom = style.Bottom
	local t = style.Thickness
	local tail = BaseDoors.TAIL
	local build = SEGMENTS[door.key] or SEGMENTS.Forest
	local sides = {}
	local nMax = 1
	for _, side in ipairs({ -1, 1 }) do
		local edge = if side > 0 then g.vMax else g.vMin
		local w = if side > 0 then g.wRight else g.wLeft
		local L = math.abs(edge - c)
		local park = math.min(style.Park and style.Park[side] or BaseDoors.PARK, math.max(w - 1, BaseDoors.PARK))
		-- every segment (the widest is the outermost one, with its tail) must park inside the pylon
		local usable = math.max(w - park - style.Overlap - tail - 0.02, 0.8)
		local n = math.clamp(math.ceil(L / usable - 1e-6), 1, style.MaxSegments or 5)
		sides[side] = { edge = edge, L = L, n = n, park = park }
		nMax = math.max(nMax, n)
	end
	-- layers: the leading segments share the outermost layer, the rest step inward (all inside the pylon depth)
	local stepZ = math.min(t + 0.04, math.max(depth - t - 0.1, 0) / math.max(nMax - 1, 1))
	local zFront = zMid - (nMax - 1) / 2 * stepZ
	for _, side in ipairs({ -1, 1 }) do
		local info = sides[side]
		local s = info.L / info.n
		for k = 1, info.n do
			-- closed: the leading edge sits at the seam (k = 1) or under the previous segment's trailing overlap; only the
			-- trailing side is extended, so the two leading segments meet at the seam without overlapping
			local sw = s + style.Overlap + (if k == info.n then tail else 0)
			local x0 = c + side * (s * (k - 1) + sw / 2)
			local x1 = info.edge + side * (info.park + sw / 2)
			local zk = zFront + (k - 1) * stepZ
			local segment = Instance.new("Model")
			segment.Name = string.format("Segment%s%d", if side > 0 then "PlusX" else "MinusX", k)
			segment.Parent = door.model
			for _, entry in ipairs(build(segment, side, k, info.n, sw, H, bottom, t, style)) do
				local rest = entry[2]
				addPiece(door, entry[1], function(e)
					return CFrame.new(x0 + (x1 - x0) * e, 0, zk) * rest
				end)
			end
		end
		info.segmentWidth = s
	end
	door.height = H
	door.plane = zMid
	door.segments = { [-1] = sides[-1].n, [1] = sides[1].n }
end

---------------------------------------------------------------------------------------------------
-- roll-up shutter (Desert): the shutter shortens into a housing under the crest; its graffiti rides up with the
-- bottom edge and disappears into the housing like real slats
---------------------------------------------------------------------------------------------------

local function buildRollup(door, g, style)
	local C = style.Colors
	local c = (g.vMin + g.vMax) / 2
	local z = -(g.uMin + g.uMax) / 2
	local bottom = style.Bottom
	local housingBottom = g.top - style.Housing - 0.02
	local shutterTop = housingBottom + 0.3
	local Hs = shutterTop - bottom
	local W = g.vMax - g.vMin - 0.1
	local model = door.model
	local housingDepth = math.min(math.max(g.uMax - g.uMin, 0.6), 1.0)
	local housing = newPart(model, "Housing", Vector3.new(W + 0.3, style.Housing, housingDepth), C.housing)
	addPiece(door, housing, function()
		return CFrame.new(c, housingBottom + style.Housing / 2, z)
	end)
	local label = frontGui(housing, 40)
	guiText(label, "Stencil", "BROOKLYN", C.white, Enum.Font.GothamBlack, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.52),
		UDim2.fromScale(0.62, 0.6))
	for _, side in ipairs({ -1, 1 }) do
		local x = (if side > 0 then g.vMax else g.vMin) - side * 0.11
		local rail = newPart(model, "Rail", Vector3.new(0.22, housingBottom - bottom + 0.05, 0.42), C.iron)
		addPiece(door, rail, function()
			return CFrame.new(x, bottom + (housingBottom - bottom + 0.05) / 2, z)
		end)
	end
	local shutter = newPart(model, "Shutter", Vector3.new(W, Hs, 0.16), C.shutter, Enum.Material.Metal)
	addPiece(door, shutter, function(e)
		local h = math.max(Hs * (1 - e), 0.06)
		return CFrame.new(c, shutterTop - h / 2, z), Vector3.new(W, h, 0.16)
	end)
	local bar = newPart(model, "Bar", Vector3.new(W - 0.3, 0.2, 0.3), C.bar)
	addPiece(door, bar, function(e)
		local h = math.max(Hs * (1 - e), 0.06)
		return CFrame.new(c, shutterTop - h + 0.12, z)
	end)
	-- graffiti + slats, anchored to the shutter's bottom edge (pixel offsets), clipped at its top
	local pps = 40
	local root = frontGui(shutter, pps)
	for i = 1, math.floor(Hs / 0.42) do
		local line = guiFrame(root, "Slat", C.slat, Vector2.new(0, 1), UDim2.new(0, 0, 1, -math.floor(i * 0.42 * pps)), UDim2.new(1, 0, 0, 2))
		line.BackgroundTransparency = 0.25
	end
	local tagY = math.floor(math.min(3.5, Hs * 0.62) * pps)
	guiText(root, "TagShadow", "SPIDER", C.cyan, Enum.Font.PermanentMarker, Vector2.new(0.5, 1), UDim2.new(0.5, -5, 1, -tagY + 4),
		UDim2.new(0.9, 0, 0, 92))
	guiText(root, "Tag", "SPIDER", C.magenta, Enum.Font.PermanentMarker, Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -tagY),
		UDim2.new(0.9, 0, 0, 92), C.slat)
	guiText(root, "Verse", "VERSE", C.yellow, Enum.Font.PermanentMarker, Vector2.new(0.5, 1), UDim2.new(0.56, 0, 1, -tagY + 70),
		UDim2.new(0.6, 0, 0, 58), C.red)
	for i, x in ipairs({ 0.22, 0.34, 0.47, 0.61, 0.76 }) do
		guiFrame(root, "Drip", C.magenta, Vector2.new(0.5, 0), UDim2.new(x, 0, 1, -tagY + 2), UDim2.fromOffset(4, 10 + (i * 7) % 26), 0.5)
	end
	guiText(root, "Crew", "BK", C.white, Enum.Font.PermanentMarker, Vector2.new(1, 1), UDim2.new(0.97, 0, 1, -8), UDim2.fromOffset(48, 30))
	door.height = housingBottom
	door.plane = z
end

---------------------------------------------------------------------------------------------------
-- sinking split doors (Snow): two rounded halves part a little, then drop into the floor (the solid ground hides
-- them), so round pylons never show a parked panel
---------------------------------------------------------------------------------------------------

local SINKERS = {}

-- Snow: a pearl half with rounded beads along its top and leading edges (the two leading beads meet like a capsule
-- seam), a blue band, an orange line and the round Capsule Corp logo.
SINKERS.Snow = function(leaf, side, L, H, bottom, t, style)
	local C = style.Colors
	local list = {}
	local add = segmentAdder(leaf, list)
	local d = t + 0.16
	local body = H - bottom - d / 2
	local lead = -side * (L / 2 - d / 2)
	local panel = add("Panel", Vector3.new(L - d / 2, body, t), side * d / 4, bottom + body / 2, 0, C.pearl)
	add("TopBead", Vector3.new(L - d / 2, d, d), side * d / 4, H - d / 2, 0, C.pearl, nil, Enum.PartType.Cylinder)
	add("SeamBead", Vector3.new(body, d, d), lead, bottom + body / 2, 0, C.pearl, nil, Enum.PartType.Cylinder,
		CFrame.Angles(0, 0, math.pi / 2))
	add("Corner", Vector3.new(d, d, d), lead, H - d / 2, 0, C.pearl, nil, Enum.PartType.Ball)
	add("Band", Vector3.new(L - d / 2, 0.55, t + 0.04), side * d / 4, bottom + 0.95, 0, C.blue)
	add("Line", Vector3.new(L - d / 2, 0.14, t + 0.05), side * d / 4, H - d - 0.45, 0, C.orange)
	local pps = 50
	local root = frontGui(panel, pps)
	local diameter = math.floor(math.min(2.5, L - d - 0.4) * pps)
	local disc = guiFrame(root, "Logo", C.blue, Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0, math.floor((body - body * 0.56) * pps)),
		UDim2.fromOffset(diameter, diameter), 0.5)
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.white
	stroke.Thickness = 6
	stroke.Parent = disc
	guiText(disc, "Top", "CAPSULE", C.white, Enum.Font.GothamBlack, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.38),
		UDim2.fromScale(0.78, 0.2))
	guiText(disc, "Bottom", "CORP.", C.white, Enum.Font.GothamBlack, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.63),
		UDim2.fromScale(0.62, 0.22))
	return list
end

local function buildSink(door, g, style)
	local c = (g.vMin + g.vMax) / 2
	local z = -(g.uMin + g.uMax) / 2
	local H = math.min(g.top - 0.05, style.MaxHeight)
	local bottom = style.Bottom
	local t = style.Thickness
	local share = style.PartShare or 0.3
	local drop = H + 0.3
	local build = SINKERS[door.key] or SINKERS.Snow
	for _, side in ipairs({ -1, 1 }) do
		local edge = if side > 0 then g.vMax else g.vMin
		local L = math.abs(edge - c) + (style.Reach or 0)
		local x0 = c + side * L / 2
		local leaf = Instance.new("Model")
		leaf.Name = if side > 0 then "HalfPlusX" else "HalfMinusX"
		leaf.Parent = door.model
		for _, entry in ipairs(build(leaf, side, L, H, bottom, t, style)) do
			local rest = entry[2]
			addPiece(door, entry[1], function(e)
				local apart = math.min(e / share, 1)
				local down = math.max((e - share) / (1 - share), 0)
				return CFrame.new(x0 + side * (style.Part or 0) * apart, -drop * down, z) * rest
			end)
		end
	end
	door.height = H
	door.plane = z
end

local BUILDERS = { swing = buildSwing, slide = buildSlide, rollup = buildRollup, sink = buildSink }

-- Builds the door of style `styleKey` for opening `geometry` in the door frame `frame` (see header) and parents it to
-- `parent` (closed). Returns the door: { model, parts, pieces, centre (world trigger point), style, key, Pose(e),
-- Destroy() }.
function BaseDoors.Build(styleKey, geometry, frame, parent)
	local key = BaseDoors.StyleKey(styleKey)
	local style = BaseDoors.Styles[key]
	local model = Instance.new("Model")
	model.Name = "BaseDoor"
	local door = setmetatable({ key = key, style = style, frame = frame, geometry = geometry, pieces = {}, parts = {}, model = model }, Door)
	BUILDERS[style.Kind](door, geometry, style)
	door.centre = frame * Vector3.new((geometry.vMin + geometry.vMax) / 2, BaseDoors.CENTRE_HEIGHT, -(geometry.uMin + geometry.uMax) / 2)
	door:Pose(0)
	model.Parent = parent
	return door
end

return BaseDoors
