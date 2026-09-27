--!nocheck
-- scripts/steps/post_zz_base_themes.luau
-- Build step (owner BASES, Gekko TO DO #5 "Index Completion Rewards"): the six stage-themed bases a player unlocks by
-- completing a stage's Hero Index (Directory.BaseThemes; unlock / equip: Controllers.IndexService, applied to the
-- owner's plot by Controllers.PlotService). Runs in the post_* pass; the "zz" makes it the LAST post step, so it sees
-- the final plot fences (post_hub_remodel) and world walls (post_world_sae).
--
--   1. ServerStorage.BaseThemes.<StageKey>.<plotName> (Model): the theme's props built for that exact plot, in world
--      space. Every plot is measured (pen fence posts, gate = StarterPen.GridCenter, the side the gate is on = the
--      plot's front), so the deeper pens (plots 2, 3) and the rotated plot 6 get their own fit. PlotService clones the
--      model into the plot as "ThemeProps" and recolours the fence by role (Directory.BaseThemes Fence).
--      Pen frame: u toward the gate, v to the right, h above the floor; D / W = half depth / width of the pen (fence
--      line). Groups (sub-Models):
--        Floor      a themed floor inlay inside the fence (h 0 .. 0.1, under the heroes' ground at 2.177) with a
--                   SurfaceGui emblem on its top face;
--      (no backdrop group any more: owner 2026-09-24, the plots stay open with 360-degree visibility of the map; nothing
--      stands behind the back fence but the corner pylons, BACK_MAX)
--        Corner*    one themed pylon over each corner post (<= 2.4 wide, centred 0.6 outside the corner);
--        Gate       an arch whose pillars stand on the gate posts (centred 0.5 outside), lintel at h >= 10 with the name;
--        Sides      thin banners hugging the side fences (<= 1 stud outside).
--      Every part: Anchored, CanCollide / CanQuery / CanTouch false, name "Theme*" (never a name client code looks up
--      in a plot: PlotUpgrade, TreadmillUpgrade, Sign, ...). Clearance check (Step.enforceClearance): a group with a part
--      that reaches more than 0.62 studs into the pen (the heroes' PetArea starts ~1.1 studs inside the fence), stands
--      in the gate passage below 7.5 studs, leaves the plot's zone, or touches the plot's functional parts (upgrade
--      signs, treadmill, spawn, multiplier), another plot or any other world geometry is dropped and logged. So the
--      props never block a hero, an entrance or the treadmill. A dropped corner pylon is replaced by a slim finial on
--      the corner post (plot 6's front corner stands next to the money leaderboard).
--   2. ReplicatedStorage.Assets.BaseThemes.<StageKey> (Model): a canonical preview (a standard 52.5 x 52.5 pen centred
--      on the origin, gate toward -Z, a simple fence in the theme colours + the props) for the Index page's 3D preview.
--   3. ReplicatedStorage.Network["BaseThemes: RequestEquip"] (RemoteFunction, answered by IndexService).
--
--   4. Imported pens (Step.IMPORTED_PENS): a theme can replace its procedural fence/floor/corner/gate/side props with a
--      pen modelled in Blender (API v3, scripts/tools/blender/base_themes/common.py): run.py writes
--      assets/models/bases/<Key>/<Name>.fbx (both pen variants: "Std_<Role>" / "Deep_<Role>" meshes, one per material
--      family + colour: Structure_* / Floor_* / Core_3D_* / Neon_Emissive_*, bevelled, weighted normals) + <Name>.json
--      (format IMPORT_FORMAT: variants, footprint, object bounds, every modelled piece, palette, anchors, geometry
--      fingerprint; its "lights" are ignored since 2026-09-25);
--      Studio "Import 3D" + assets/models/bases/BaseThemesImport.lua store it as ServerStorage.BaseThemeImports.<Key>.
--      <Name>, which the build saves as assets/models/bases/<Key>/<Name>.rbxm (scripts/lib/base_imports.luau). The
--      loader finds the MeshParts by variant prefix + role, works out each variant's position / 90-degree yaw / unit
--      scale from its floor and terminal, checks every part lands on the layout's bounds, re-places them in every plot's
--      pen frame (the first variant whose size matches the pen and whose pieces fit), restyles them from the palette and
--      checks every modelled piece (the JSON's per-primitive boxes) against the plot's functional parts, the other
--      plots and the world with no margin. A plot where no variant fits keeps the procedural theme. The per-plot model
--      then carries HidesPenFence = true: PlotService hides the StarterPen fence under it. Layouts of the older format
--      (LEGACY_IMPORT_FORMATS: backdrops and a shared X-cross fence, made before the 2026-09-24 art direction) are
--      ignored with a log line until their theme is rebuilt. Offline test: lune run scripts/tools/test_base_imports.luau
--      all <scratchDir> [keys].
--
--   5. NO NEON, NO LIGHTS (owner 2026-09-25: "remove ALL the neon from the bases, it is very disruptive for the
--      players"): the procedural themes use SmoothPlastic for their former neon accents and never make a PointLight; an
--      imported pen is restyled from its layout palette with any Neon mapped to SmoothPlastic and its layout's lights
--      ignored; Step.assertNoNeon FAILS THE BUILD if any part under ServerStorage.BaseThemes or
--      ReplicatedStorage.Assets.BaseThemes is Neon or any light is left there (ui_80_plot_viewports re-checks the
--      Index previews it rebuilds).
--   6. Stale imports: every layout has a geometry fingerprint (Step.geometryFingerprint: object bounds, tris and every
--      modelled piece; run.py writes the same string as "geometry_fingerprint"). BaseThemesImport.lua stamps it on the
--      import (attribute GeometryFingerprint); an import made with the older helper (no stamp) is taken to be the
--      geometry the owner imported on 2026-09-25 (Step.PRESTAMP_IMPORTS). An import whose geometry is not the layout's
--      is ignored with "re-import <Name>.fbx" and the procedural theme stays; a palette-only change keeps the import.
--   7. Landmarks (owner 2026-09-25: the U.A. towers, the Hall of Justice, the Brooklyn skyline): a layout of a
--      Step.LANDMARK_KEYS theme may carry pieces tagged "landmark" behind its pen (Step.LANDMARK: 1.3 .. 24 studs behind
--      the back fence line, |v| <= W + 2, h <= 34); they are checked against every obstacle of that zone (hub walls,
--      neighbouring plots, leaderboards) with no margin. Everything else keeps the pen zone.
--   8. Window lights (owner 2026-09-25, Spider-Verse base: "make the windows have those lights; in Studio we will put
--      that effect where one turns off, one turns on"): the glass of a modelled building is NOT in the FBX. Any layout
--      variant may list pane SLOTS in "windows" (run.py / the theme writes them; generic, any theme may carry them):
--        { id, building, c = { v, u, h } (the pane's centre, pen frame), size = { width, height },
--          n = { nv, nu, 0 } (its horizontal facing normal, pen frame), zone = "landmark" | nil, lit_rgb = { r, g, b }? }
--      styled by the layout's top-level "window_lights" { format "stealahero-windows/1", material, lit_rgb, off_rgb,
--      thickness, lit_fraction, flicker = { min_gap_s, max_gap_s, tween_s, range_studs } } (Step.WINDOW_DEFAULTS fill
--      the gaps). Wherever the imported pen is placed (every fitting plot and the Index preview) the build makes one flat
--      pane Part per slot (Step.placeWindowPanes): Part "ThemeWindowPane", Size (width, height, thickness) facing n,
--      Anchored, CanCollide / CanQuery / CanTouch / CastShadow false, SmoothPlastic (a banned material is mapped like the
--      palette's), lit colour (the slot's lit_rgb or the style's); never Neon, never a light. They live in the group
--      Model "ThemeWindows" (a SIBLING of ThemeImportedPen, so the pen's parts stay exactly the layout's roles), tagged
--      Step.WINDOW_TAG with the style as attributes (WindowLitColor, WindowOffColor, WindowLitFraction, WindowMinGap,
--      WindowMaxGap, WindowTween, WindowRange). PlotService clones it with the rest of the props into the plot's
--      ThemeProps; StarterPlayerScripts.Game.Plots.BaseWindowLights turns a few panes off / on at a time (client only,
--      nearby plots only) and forgets them when the theme is unequipped. The Index preview keeps them static and lit
--      (ui_80_plot_viewports strips the tag). Every pane is checked like a modelled piece (zone + obstacles, no margin);
--      a malformed slot is skipped and logged. Slots are not geometry: they never change the geometry fingerprint.
--
-- Lune notes: explicit frames through CFrame.fromMatrix (never lookAt), FontFace, the four UICorner radii; no images.
-- Idempotent: both folders are rebuilt from scratch.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local serde = require("@lune/serde")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum
local Font = roblox.Font
local UDim = roblox.UDim
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2

local Step = {}

Step.DIRECTORY_SOURCE = "src/ReplicatedStorage/Directory/BaseThemes.luau"
Step.SERVER_FOLDER = "BaseThemes" -- ServerStorage.BaseThemes.<Key>.<plotName>
Step.PREVIEW_FOLDER = "BaseThemes" -- ReplicatedStorage.Assets.BaseThemes.<Key>
Step.REMOTE = "BaseThemes: RequestEquip"
Step.PREFIX = "Theme"
Step.FLOOR_TOP = 0.1 -- floor inlay top above the ground (2.05 + 0.1 = 2.15, under the heroes' ground at 2.177)

-- layout offsets (studs)
Step.CORNER_OUT = 0.6 -- corner pylons are centred this far outside the corner post (both axes)
Step.GATE_OUT = 0.5 -- gate pillars / lintel are centred this far outside the front fence line
-- clearance (studs)
Step.INTERIOR_INSET = 0.62 -- below HIGH_OVERHANG nothing but the floor reaches further into the pen
Step.HIGH_OVERHANG = 12 -- parts entirely above this height may overhang the fence line by up to 2.5 studs
Step.GATE_CLEAR_HEIGHT = 7.5 -- nothing but the floor below this height in the gate passage
Step.GATE_CLEAR_HALF = 1.3 -- the passage is the gate opening narrowed by this on each side
Step.SIDE_MAX = 2.0 -- how far props may reach past the side fences (the lanes between plots are ~7 studs)
Step.FRONT_MAX = 2.4 -- ... past the front fence (upgrade sign, spawn and treadmill are further out)
Step.BACK_MAX = 2.0 -- ... behind the back fence (corner pylons only: no backdrops, owner 2026-09-24)
Step.TOP_MAX = 20 -- the gate crests; the modelled pens stop at 16 (common.TOP_MAX)
Step.OBSTACLE_MARGIN = 0.3

-- Blender-modelled pens (section 4 of the header). Every key listed here may bring one: its folder under IMPORTS_ROOT
-- holds <Name>.json (format IMPORT_FORMAT, written by scripts/tools/blender/base_themes/run.py: both pen variants, the
-- palette, every modelled piece) and, once imported in Studio, <Name>.rbxm (the layout's "import"). A key without them
-- keeps its procedural theme. STEALAHERO_BASE_IMPORTS overrides the folder (offline tests with a synthetic import).
Step.IMPORTS_ROOT = process.env.STEALAHERO_BASE_IMPORTS or "assets/models/bases"
Step.IMPORT_FORMAT = "stealahero-base-theme/3"
Step.LEGACY_IMPORT_FORMATS = { "stealahero-base-theme/2" } -- older layouts on disk: logged and ignored
Step.IMPORTED_PENS = { Forest = true, Lake = true, Desert = true, Jungle = true, Snow = true, Volcano = true }
Step.IMPORT_KEEP = {} -- procedural group prefixes kept next to an imported pen (none: the pen replaces them all)
Step.IMPORT_SIGN_TOLERANCE = 0.35 -- the plot's PlotUpgrade.Sign must sit where the modelled terminal expects it
Step.IMPORT_BOUNDS_TOLERANCE = 0.2 -- studs: every imported part must land on the layout's object bounds
-- No Neon / no lights in the bases (owner 2026-09-25, section 5): a banned material -> what the build uses instead
Step.BANNED_MATERIALS = { Neon = "SmoothPlastic" }
-- The landmark zone behind the back fence (section 7; common.py LANDMARK_*): studs behind the back fence line (near ..
-- back), past the side fence lines (side), height (top). Only these theme keys may have one.
Step.LANDMARK = { near = 1.3, back = 24, side = 2.0, top = 34 }
Step.LANDMARK_KEYS = { Lake = true, Desert = true, Jungle = true }
-- Stale imports (section 6): the fingerprint format (pipeline.geometry_fingerprint writes the same) and the geometry of
-- every import the owner made with the pre-stamp helper (2026-09-25 06:35: the layouts written at 04:48). An unstamped
-- import of another name, or of a layout whose geometry changed since, is stale.
Step.FINGERPRINT_FORMAT = "stealahero-geometry/1"
Step.PRESTAMP_IMPORTS = {
	StarkLab = "g1:ca6a3f785e7fdcafc7ba0fd0",
	HallOfJustice = "g1:d0007fad5ca64bfe2f7d1a64",
	BrooklynRooftop = "g1:4c009072e8ab9a2869c28e34",
	UAHeroArena = "g1:51fe9693416455994f9cf06e",
	CapsuleCorp = "g1:02b7a6e0390c2d9f8dac6d5a",
	SunnyPirateWharf = "g1:37754577e17381b3a4036532",
}
-- Window lights (section 8): the pane group / part names, the client's tag, the style defaults and sanity limits.
Step.WINDOW_FORMAT = "stealahero-windows/1"
Step.WINDOW_GROUP = "Windows" -- Model Step.PREFIX .. "Windows", next to (never inside) ThemeImportedPen
Step.WINDOW_PANE = "WindowPane" -- Part Step.PREFIX .. "WindowPane"
Step.WINDOW_TAG = "BaseWindowLights" -- StarterPlayerScripts.Game.Plots.BaseWindowLights drives the tagged groups
Step.WINDOW_DEFAULTS = {
	material = "SmoothPlastic",
	lit = { 255, 204, 64 }, -- a lit room: warm yellow
	off = { 46, 56, 80 }, -- a dark room: blue-grey glass
	thickness = 0.08,
	litFraction = 0.8,
	minGap = 2, -- seconds between two toggles of one building group (client)
	maxGap = 12,
	tween = 0.25,
	range = 250, -- studs from the camera
}
Step.WINDOW_MAX = 256 -- slots per variant
Step.WINDOW_MAX_SIZE = 16 -- studs: a pane wider or taller than this is not a window

local log = function(fmt, ...)
	print(string.format("[base_themes] " .. fmt, ...))
end

---------------------------------------------------------------------------------------------------
-- geometry helpers
---------------------------------------------------------------------------------------------------

local function worldAabb(part)
	local cf, size = part.CFrame, part.Size
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, sx in ipairs({ -0.5, 0.5 }) do
		for _, sy in ipairs({ -0.5, 0.5 }) do
			for _, sz in ipairs({ -0.5, 0.5 }) do
				local corner = cf * Vector3.new(size.X * sx, size.Y * sy, size.Z * sz)
				minV = minV:Min(corner)
				maxV = maxV:Max(corner)
			end
		end
	end
	return minV, maxV
end

-- AABB of a part in the coordinates of `frame` (x = v, y = h, z = -u).
local function localAabb(part, frame)
	local cf, size = part.CFrame, part.Size
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, sx in ipairs({ -0.5, 0.5 }) do
		for _, sy in ipairs({ -0.5, 0.5 }) do
			for _, sz in ipairs({ -0.5, 0.5 }) do
				local corner = frame:PointToObjectSpace(cf * Vector3.new(size.X * sx, size.Y * sy, size.Z * sz))
				minV = minV:Min(corner)
				maxV = maxV:Max(corner)
			end
		end
	end
	return minV, maxV
end

local function boxesOverlap(aMin, aMax, bMin, bMax)
	return aMin.X < bMax.X and aMax.X > bMin.X and aMin.Y < bMax.Y and aMax.Y > bMin.Y and aMin.Z < bMax.Z and aMax.Z > bMin.Z
end

local function isPost(part)
	if not part:IsA("BasePart") or part.Transparency >= 1 then
		return false
	end
	local size = part.Size
	return size.Y >= 3 and size.X <= 2 and size.Z <= 2
end

-- The pen frame of a plot: origin = pen centre on the floor, look = toward the gate (the plot's front).
-- Returns { frame, D, W, g, gv } or nil.
function Step.measurePen(plot, groundY)
	local toUpdate = plot:FindFirstChild("ToUpdate")
	local pen = toUpdate and toUpdate:FindFirstChild("StarterPen")
	local gate = pen and pen:FindFirstChild("GridCenter")
	if not (pen and gate and gate:IsA("BasePart")) then
		return nil
	end
	local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
	local posts = 0
	for _, part in ipairs(pen:GetDescendants()) do
		if isPost(part) then
			local p = part.CFrame.Position
			minX, maxX = math.min(minX, p.X), math.max(maxX, p.X)
			minZ, maxZ = math.min(minZ, p.Z), math.max(maxZ, p.Z)
			posts += 1
		end
	end
	if posts < 4 then
		return nil
	end
	local g = gate.CFrame.Position
	local sides = {
		{ math.abs(g.X - maxX), Vector3.new(1, 0, 0) },
		{ math.abs(g.X - minX), Vector3.new(-1, 0, 0) },
		{ math.abs(g.Z - maxZ), Vector3.new(0, 0, 1) },
		{ math.abs(g.Z - minZ), Vector3.new(0, 0, -1) },
	}
	table.sort(sides, function(a, b)
		return a[1] < b[1]
	end)
	local forward = sides[1][2]
	local up = Vector3.new(0, 1, 0)
	local right = forward:Cross(up)
	local origin = Vector3.new((minX + maxX) / 2, groundY, (minZ + maxZ) / 2)
	local frame = CFrame.fromMatrix(origin, right, up, -forward)
	local halfX, halfZ = (maxX - minX) / 2, (maxZ - minZ) / 2
	local D = if forward.X ~= 0 then halfX else halfZ
	local W = if forward.X ~= 0 then halfZ else halfX
	local gv = (g - origin):Dot(right)
	-- gate opening: the two posts of the Gate model
	local gateModel = pen:FindFirstChild("Gate")
	local vs = {}
	for _, part in ipairs(gateModel and gateModel:GetChildren() or {}) do
		if isPost(part) then
			table.insert(vs, (part.CFrame.Position - origin):Dot(right))
		end
	end
	local halfGate = 5.25
	if #vs >= 2 then
		table.sort(vs)
		halfGate = (vs[#vs] - vs[1]) / 2
		gv = (vs[#vs] + vs[1]) / 2
	end
	return { frame = frame, D = D, W = W, g = halfGate, gv = gv }
end

---------------------------------------------------------------------------------------------------
-- builder: parts in pen-local coordinates
---------------------------------------------------------------------------------------------------

local MATERIALS = {}
local function material(name)
	if MATERIALS[name] == nil then
		MATERIALS[name] = Enum.Material[name]
	end
	return MATERIALS[name]
end

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function newBuilder(frame, root)
	local B = { count = 0 }
	local current = root

	-- following parts go into a new sub-Model (the unit the clearance check keeps or drops)
	function B.group(name)
		local model = Instance.new("Model")
		model.Name = Step.PREFIX .. name
		model.WorldPivotData = frame
		model.Parent = root
		current = model
		return model
	end

	local function finish(part, name, color, mat, opts)
		opts = opts or {}
		part.Name = Step.PREFIX .. name
		part.Color = color
		mat = Step.BANNED_MATERIALS[mat or ""] or mat -- never Neon in a base (section 5)
		if mat == "Studs" then
			part.Material = material("Plastic")
			part.MaterialVariant = "Studs"
		else
			part.Material = material(mat or "SmoothPlastic")
		end
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = opts.shadow ~= false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Transparency = opts.transparency or 0
		if opts.reflect then
			part.Reflectance = opts.reflect
		end
		-- (opts.light made a PointLight glow here until 2026-09-25: no lights in the bases any more)
		part.Parent = current
		B.count += 1
		return part
	end

	local function rot(opts)
		opts = opts or {}
		return CFrame.Angles(opts.pitch or 0, opts.yaw or 0, opts.roll or 0)
	end

	-- local point (u, v, h) -> CFrame
	function B.at(u, v, h)
		return frame * CFrame.new(v, h, -u)
	end

	-- box centred on (u, v) standing on h0; su along the look (u), sv along the right (v), sh tall
	function B.box(name, u, v, h0, su, sv, sh, color, mat, opts)
		local part = Instance.new("Part")
		part.Size = Vector3.new(sv, sh, su)
		part.CFrame = B.at(u, v, h0 + sh / 2) * rot(opts)
		return finish(part, name, color, mat, opts)
	end

	-- vertical cylinder
	function B.cyl(name, u, v, h0, height, dia, color, mat, opts)
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(height, dia, dia)
		part.CFrame = B.at(u, v, h0 + height / 2) * CFrame.Angles(0, 0, math.pi / 2)
		return finish(part, name, color, mat, opts)
	end

	-- horizontal cylinder centred on (u, v, hc), axis along "u" or "v"
	function B.hcyl(name, u, v, hc, length, dia, axis, color, mat, opts)
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(length, dia, dia)
		part.CFrame = B.at(u, v, hc) * (if axis == "u" then CFrame.Angles(0, math.pi / 2, 0) else CFrame.new())
		return finish(part, name, color, mat, opts)
	end

	function B.ball(name, u, v, hc, dia, color, mat, opts)
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(dia, dia, dia)
		part.CFrame = B.at(u, v, hc)
		return finish(part, name, color, mat, opts)
	end

	-- wedge whose high side faces `high` ("back" = -u, "front" = +u, "right" = +v, "left" = -v)
	function B.wedge(name, u, v, h0, su, sv, sh, high, color, mat, opts)
		local part = Instance.new("WedgePart")
		local yaw, size
		if high == "back" then
			yaw, size = 0, Vector3.new(sv, sh, su)
		elseif high == "front" then
			yaw, size = math.pi, Vector3.new(sv, sh, su)
		elseif high == "right" then
			yaw, size = math.pi / 2, Vector3.new(su, sh, sv)
		else
			yaw, size = -math.pi / 2, Vector3.new(su, sh, sv)
		end
		part.Size = size
		part.CFrame = B.at(u, v, h0 + sh / 2) * CFrame.Angles(0, yaw, 0)
		return finish(part, name, color, mat, opts)
	end

	-- square-section beam between two local points (webs, rigging, spider legs)
	function B.beam(name, u1, v1, h1, u2, v2, h2, thick, color, mat, opts)
		local a = Vector3.new(v1, h1, -u1)
		local b = Vector3.new(v2, h2, -u2)
		local d = b - a
		local z = d.Unit
		local ref = if math.abs(z.Y) > 0.95 then Vector3.new(1, 0, 0) else Vector3.new(0, 1, 0)
		local x = ref:Cross(z).Unit
		local y = z:Cross(x)
		local part = Instance.new("Part")
		part.Size = Vector3.new(thick, thick, d.Magnitude)
		part.CFrame = frame * CFrame.fromMatrix((a + b) / 2, x, y, z)
		return finish(part, name, color, mat, opts)
	end

	-- flat strip lying on the floor inlay (h 0.1 .. 0.1 + thick) from (u1, v1) to (u2, v2)
	function B.strip(name, u1, v1, u2, v2, width, thick, color, mat, opts)
		local du, dv = u2 - u1, v2 - v1
		local o = table.clone(opts or {})
		o.yaw = math.atan2(dv, -du)
		o.shadow = false
		return B.box(name, (u1 + u2) / 2, (v1 + v2) / 2, Step.FLOOR_TOP, math.sqrt(du * du + dv * dv) + width, width, thick or 0.05, color, mat, o)
	end

	-- Block letters built from floor strips, upright for a player walking in from the gate (who faces -u, with -v on
	-- the right). Parts rather than floor-SurfaceGui text, so their reading direction never depends on how a Top-face
	-- canvas is oriented. `text` uses the glyphs below; `size` = letter height in studs, centred on (u, v).
	local GLYPHS = {
		A = { { -0.5, -0.5, 0, 0.5 }, { 0.5, -0.5, 0, 0.5 }, { -0.27, -0.08, 0.27, -0.08 } },
		U = { { -0.42, 0.5, -0.42, -0.5 }, { 0.42, 0.5, 0.42, -0.5 }, { -0.42, -0.5, 0.42, -0.5 } },
		["."] = { { -0.02, -0.5, 0.02, -0.5 } },
	}
	function B.floorText(name, text, u, v, size, color, mat)
		local advance = { A = 1.15, U = 1.05, ["."] = 0.55 }
		local total = 0
		for ch in string.gmatch(text, ".") do
			total += (advance[ch] or 1) * size * 0.8
		end
		local x = -total / 2
		for ch in string.gmatch(text, ".") do
			local w = (advance[ch] or 1) * size * 0.8
			local cx = x + w / 2
			for _, s in ipairs(GLYPHS[ch] or {}) do
				-- letter space (x right, y up) -> floor: u = cu - y, v = cv - x
				local stroke = if ch == "." then size * 0.2 else size * 0.19
				B.strip(name, u - s[2] * size, v - (cx + s[1] * size * 0.8), u - s[4] * size, v - (cx + s[3] * size * 0.8), stroke, 0.05, color, mat)
			end
			x += w
		end
	end

	local FACING_YAW = { front = 0, back = math.pi, right = -math.pi / 2, left = math.pi / 2 }

	-- flat panel whose Front face (SurfaceGui side) looks toward `facing`; width along the panel, thick through it
	function B.panel(name, u, v, h0, width, height, thick, facing, color, mat, opts)
		local part = Instance.new("Part")
		part.Size = Vector3.new(width, height, thick)
		part.CFrame = B.at(u, v, h0 + height / 2) * CFrame.Angles(0, FACING_YAW[facing or "front"], 0) * rot(opts)
		return finish(part, name, color, mat, opts)
	end

	return B
end

---------------------------------------------------------------------------------------------------
-- SurfaceGui art
---------------------------------------------------------------------------------------------------

local function setCorner(node, scale)
	local corner = Instance.new("UICorner")
	local radius = UDim.new(scale, 0)
	corner.TopLeftRadius = radius
	corner.TopRightRadius = radius
	corner.BottomLeftRadius = radius
	corner.BottomRightRadius = radius
	corner.Parent = node
	return corner
end

local function addStroke(node, color, thickness, transparency, contextual)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.ApplyStrokeMode = if contextual then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border
	stroke.Parent = node
	return stroke
end

local function newSurface(part, face, pixelsPerStud, lightInfluence)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "ThemeArt"
	gui.Face = Enum.NormalId[face]
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud
	gui.LightInfluence = lightInfluence or 0
	gui.Brightness = 1
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ClipsDescendants = true
	gui.MaxDistance = 400
	gui.AlwaysOnTop = false
	gui.Parent = part
	return gui
end

local function newFrame(parent, name, color, transparency, zIndex)
	local node = Instance.new("Frame")
	node.Name = name
	node.BackgroundColor3 = color
	node.BackgroundTransparency = transparency or 0
	node.BorderSizePixel = 0
	node.AnchorPoint = Vector2.new(0.5, 0.5)
	node.ZIndex = zIndex or 1
	node.Parent = parent
	return node
end

local function newText(parent, name, text, color, font, zIndex)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Text = text
	label.TextColor3 = color
	label.FontFace = Font.fromEnum(font or Enum.Font.GothamBlack)
	label.TextScaled = true
	label.TextWrapped = true
	label.ZIndex = zIndex or 2
	label.Parent = parent
	return label
end

-- A sign: text filling a panel's Front face (scale layout), with an outline and an optional plate.
local function signText(part, text, textColor, strokeColor, font, opts)
	opts = opts or {}
	local gui = newSurface(part, "Front", opts.pps or 40, opts.light or 0)
	if opts.bg then
		local bg = newFrame(gui, "Plate", opts.bg, 0, 1)
		bg.Position = UDim2.fromScale(0.5, 0.5)
		bg.Size = UDim2.fromScale(1, 1)
		if opts.border then
			addStroke(bg, opts.border, opts.borderPx or 6, 0)
		end
	end
	local label = newText(gui, "Text", text, textColor, font, 3)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(opts.width or 0.92, opts.height or 0.8)
	label.Rotation = opts.rotation or 0
	if strokeColor then
		addStroke(label, strokeColor, opts.strokePx or 4, 0, true)
	end
	return gui, label
end

-- Floor canvas: a SurfaceGui on the Top face of the floor part. The floor is built with yaw pi, so the canvas top
-- edge is the pen's back and a player walking in from the gate reads it upright. Helpers take pen-local studs.
local function newFloorArt(part, su, sv, pixelsPerStud, lightInfluence)
	local gui = newSurface(part, "Top", pixelsPerStud, lightInfluence)
	local A = { gui = gui }
	local pps = pixelsPerStud

	local function place(node, u, v, lenU, lenV)
		node.Position = UDim2.fromOffset((sv / 2 - v) * pps, (u + su / 2) * pps)
		node.Size = UDim2.fromOffset(lenV * pps, lenU * pps)
		return node
	end

	function A.rect(name, u, v, lenU, lenV, color, opts)
		opts = opts or {}
		local node = place(newFrame(gui, name, color, opts.transparency, opts.z), u, v, lenU, lenV)
		node.Rotation = opts.rotation or 0
		if opts.corner then
			setCorner(node, opts.corner)
		end
		if opts.stroke then
			addStroke(node, opts.stroke[1], opts.stroke[2] * pps, opts.stroke[3] or 0)
		end
		return node
	end

	function A.circle(name, u, v, dia, color, opts)
		opts = table.clone(opts or {})
		opts.corner = 0.5
		return A.rect(name, u, v, dia, dia, color, opts)
	end

	-- ring of `width` studs (a stroke on a transparent circle)
	function A.ring(name, u, v, dia, color, width, opts)
		opts = opts or {}
		local node = place(newFrame(gui, name, color, 1, opts.z), u, v, dia, dia)
		setCorner(node, 0.5)
		addStroke(node, color, width * pps, opts.transparency or 0)
		return node
	end

	function A.line(name, u1, v1, u2, v2, width, color, opts)
		opts = opts or {}
		local dx = -(v2 - v1) * pps -- canvas x grows toward -v
		local dy = (u2 - u1) * pps -- canvas y grows toward +u
		local node = newFrame(gui, name, color, opts.transparency, opts.z)
		node.Position = UDim2.fromOffset((sv / 2 - (v1 + v2) / 2) * pps, ((u1 + u2) / 2 + su / 2) * pps)
		node.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), width * pps)
		node.Rotation = math.deg(math.atan2(dy, dx))
		return node
	end

	function A.text(name, u, v, lenU, lenV, text, color, font, opts)
		opts = opts or {}
		local node = place(newText(gui, name, text, color, font, opts.z or 4), u, v, lenU, lenV)
		node.Rotation = opts.rotation or 0
		if opts.stroke then
			addStroke(node, opts.stroke[1], opts.stroke[2], 0, true)
		end
		return node
	end

	-- border of `width` studs, `inset` studs inside the canvas edge
	function A.border(color, width, inset, transparency)
		local node = newFrame(gui, "Border", color, 1, 1)
		node.Position = UDim2.fromScale(0.5, 0.5)
		local shrink = (2 * (inset or 0) + width) * pps
		node.Size = UDim2.new(1, -shrink, 1, -shrink)
		addStroke(node, color, width * pps, transparency or 0)
		return node
	end

	return A
end

-- The floor inlay (its own group) + its canvas.
local function buildFloor(B, geo, color, mat, lightInfluence)
	B.group("Floor")
	local su, sv = 2 * geo.D - 1.4, 2 * geo.W - 1.4
	local floor = B.box("Floor", 0, 0, 0, su, sv, Step.FLOOR_TOP, color, mat, { yaw = math.pi, shadow = false })
	return floor, newFloorArt(floor, su, sv, 12, lightInfluence)
end

-- The four corners: fn(u, v, su, sv) with (u, v) the pylon centre (CORNER_OUT outside the corner post) and su / sv the
-- outward signs; each corner is its own group.
local function eachCorner(B, geo, fn)
	for _, su in ipairs({ -1, 1 }) do
		for _, sv in ipairs({ -1, 1 }) do
			B.group(string.format("Corner%s%s", su > 0 and "Front" or "Back", sv > 0 and "Right" or "Left"))
			fn(su * (geo.D + Step.CORNER_OUT), sv * (geo.W + Step.CORNER_OUT), su, sv)
		end
	end
end

local function sideFacing(sv)
	return if sv > 0 then "right" else "left"
end

---------------------------------------------------------------------------------------------------
-- the six themes: fn(B, geo, P) with P the theme's Palette
---------------------------------------------------------------------------------------------------

local Themes = {}

-- 1. THE AVENGERS: Stark lab tech, blue / red / gold, arc-reactor accents (no neon, no lights: section 5)
Themes.Forest = function(B, geo, P)
	local D, W, g, gv = geo.D, geo.W, geo.g, geo.gv
	local gu = D + Step.GATE_OUT
	-- floor: dark diamond plate, gold and red borders, glowing runway, the arc reactor with the A in the middle
	local _, A = buildFloor(B, geo, P.steelDark, "DiamondPlate", 0.35)
	A.border(P.gold, 0.7)
	A.border(P.red, 0.25, 1.2, 0.1)
	for _, side in ipairs({ -1, 1 }) do
		A.line("Runway", D - 1, gv + side * 2.6, 10, side * 2.6, 0.35, P.glow, { z = 2 })
		A.line("Runway", -D + 1, side * 2.6, -10, side * 2.6, 0.35, P.glow, { z = 2 })
	end
	A.circle("ReactorBase", 0, 0, 19, P.steel, { z = 3, stroke = { P.steelLight, 0.35 } })
	for i = 0, 9 do
		local a = math.rad(i * 36)
		A.rect("Coil", math.cos(a) * 7.4, math.sin(a) * 7.4, 1.4, 2.6, P.steelLight, { rotation = -math.deg(a), corner = 0.2, z = 4 })
	end
	A.ring("ReactorRing", 0, 0, 12.4, P.glow, 1.1, { z = 5 })
	A.circle("ReactorCore", 0, 0, 9.4, rgb(14, 26, 46), { z = 5 })
	A.ring("LogoRing", 0, 0, 8.2, P.white, 0.55, { z = 6 })
	B.floorText("FloorLetter", "A", 0.1, 0, 4.6, P.white, "SmoothPlastic")

	-- corners: tech pylons (steel column, red band, gold cap, glossy orb, accent strips on the outer faces)
	eachCorner(B, geo, function(u, v, su, sv)
		B.box("PylonBase", u, v, 0, 2.4, 2.4, 0.6, P.steelDark, "Metal")
		B.box("Pylon", u, v, 0.6, 1.9, 1.9, 7, P.steel, "Metal")
		B.box("PylonBand", u, v, 5, 2.1, 2.1, 0.7, P.red, "SmoothPlastic")
		B.box("PylonCap", u, v, 7.6, 2.4, 2.4, 0.45, P.gold, "Metal")
		B.ball("PylonOrb", u, v, 8.75, 1.3, P.glow, "SmoothPlastic", { shadow = false, reflect = 0.05 })
		B.box("PylonLight", u + su * 0.97, v, 1.2, 0.1, 0.35, 3.6, P.glow, "SmoothPlastic", { shadow = false, reflect = 0.05 })
		B.box("PylonLight", u, v + sv * 0.97, 1.2, 0.35, 0.1, 3.6, P.glow, "SmoothPlastic", { shadow = false, reflect = 0.05 })
	end)

	-- gate: steel pillars with red faces and accent strips, the named lintel, an arc reactor on top
	B.group("Gate")
	for _, side in ipairs({ -1, 1 }) do
		local v = gv + side * g
		B.box("GatePillar", gu, v, 0, 2, 2, 11, P.steel, "Metal")
		B.box("GatePillarFace", gu + 1.02, v, 0.8, 0.1, 1.2, 9, P.red, "SmoothPlastic")
		B.box("GatePillarLight", gu + 1.08, v, 1.5, 0.06, 0.3, 7.6, P.glow, "SmoothPlastic", { shadow = false, reflect = 0.05 })
		B.box("GatePillarCap", gu, v, 11, 2.2, 2.2, 0.3, P.gold, "Metal")
	end
	local lintel = B.panel("GateLintel", gu, gv, 11.3, 2 * g + 2.6, 2.4, 2, "front", P.steel, "Metal")
	signText(lintel, "AVENGERS", P.white, P.redDark, Enum.Font.Michroma, { bg = P.red, border = P.gold, borderPx = 8 })
	B.hcyl("GateReactor", gu, gv, 14.9, 1.2, 3, "u", P.steelDark, "Metal")
	B.hcyl("GateReactorGlow", gu + 0.35, gv, 14.9, 0.6, 2.2, "u", P.glow, "SmoothPlastic", { shadow = false, reflect = 0.05 })

	-- sides: red banners with a gold stripe
	B.group("Sides")
	for _, sv in ipairs({ -1, 1 }) do
		for _, u in ipairs({ -D / 2, D / 2 }) do
			B.panel("Banner", u, sv * (W + 0.75), 1.4, 3.6, 5.2, 0.12, sideFacing(sv), P.red, "Fabric")
			B.panel("BannerStripe", u, sv * (W + 0.83), 5.4, 3.6, 0.5, 0.06, sideFacing(sv), P.gold, "SmoothPlastic")
		end
	end
end

-- 2. JUSTICE LEAGUE: Hall of Justice, marble + gold columns
Themes.Lake = function(B, geo, P)
	local D, W, g, gv = geo.D, geo.W, geo.g, geo.gv
	local gu = D + Step.GATE_OUT
	-- floor: marble with a checker of darker tiles, a gold border and the emblem in the middle
	local _, A = buildFloor(B, geo, P.marble, "Marble", 0.8)
	local tile = 6.5
	local nu, nv = math.floor((2 * D - 1.4) / tile), math.floor((2 * W - 1.4) / tile)
	for iu = 0, nu - 1 do
		for iv = 0, nv - 1 do
			if (iu + iv) % 2 == 0 then
				A.rect("Tile", (iu - (nu - 1) / 2) * tile, (iv - (nv - 1) / 2) * tile, tile, tile, P.marbleShade, { transparency = 0.35, z = 2 })
			end
		end
	end
	A.border(P.gold, 0.8)
	A.circle("EmblemBase", 0, 0, 17, P.blue, { z = 3, stroke = { P.gold, 0.8 } })
	A.rect("EmblemDiamond", 0, 0, 10.5, 10.5, P.gold, { rotation = 45, z = 4 })
	A.rect("EmblemDiamondInner", 0, 0, 8.6, 8.6, P.blue, { rotation = 45, z = 5 })
	A.rect("EmblemStar", 0, 0, 5.2, 5.2, P.goldLight, { z = 6 })
	A.rect("EmblemStar", 0, 0, 5.2, 5.2, P.goldLight, { z = 6, rotation = 45 })
	A.circle("EmblemCore", 0, 0, 2.6, P.blue, { z = 7, stroke = { P.goldLight, 0.25 } })

	-- corners: plinth, marble column, gold capital and orb
	eachCorner(B, geo, function(u, v)
		B.box("ColumnPlinth", u, v, 0, 2.4, 2.4, 0.8, P.marbleShade, "Marble")
		B.cyl("Column", u, v, 0.8, 7.2, 1.9, P.marble, "Marble")
		B.box("ColumnCapital", u, v, 8, 2.4, 2.4, 0.55, P.gold, "Metal")
		B.ball("ColumnOrb", u, v, 9.2, 1.3, P.goldLight, "Metal")
	end)

	-- gate: marble columns, the named entablature, a gold pediment
	B.group("Gate")
	for _, side in ipairs({ -1, 1 }) do
		local v = gv + side * g
		B.box("GatePlinth", gu, v, 0, 2.2, 2.4, 0.8, P.marbleShade, "Marble")
		B.cyl("GateColumn", gu, v, 0.8, 9.6, 2, P.marble, "Marble")
		B.box("GateCapital", gu, v, 10.4, 2.2, 2.4, 0.5, P.gold, "Metal")
	end
	local lintel = B.panel("GateLintel", gu, gv, 10.9, 2 * g + 3, 2, 2.2, "front", P.marble, "Marble")
	signText(lintel, "JUSTICE LEAGUE", P.goldLight, P.blue, Enum.Font.GothamBlack, { bg = P.blue, border = P.gold, borderPx = 7 })
	B.wedge("GatePediment", gu, gv - (g + 1.5) / 2, 12.9, 2.2, g + 1.5, 2.2, "right", P.gold, "Metal")
	B.wedge("GatePediment", gu, gv + (g + 1.5) / 2, 12.9, 2.2, g + 1.5, 2.2, "left", P.gold, "Metal")

	-- sides: blue banners with gold trim
	B.group("Sides")
	for _, sv in ipairs({ -1, 1 }) do
		for _, u in ipairs({ -D / 2, D / 2 }) do
			B.panel("Banner", u, sv * (W + 0.75), 1.4, 3.4, 5.4, 0.12, sideFacing(sv), P.blue, "Fabric")
			B.panel("BannerTrim", u, sv * (W + 0.83), 1.4, 3.4, 0.45, 0.06, sideFacing(sv), P.gold, "Metal")
			B.panel("BannerTrim", u, sv * (W + 0.83), 6.35, 3.4, 0.45, 0.06, sideFacing(sv), P.gold, "Metal")
		end
	end
end

-- 3. SPIDER-VERSE: graffiti and painted webs, magenta / cyan
Themes.Desert = function(B, geo, P)
	local D, W, g, gv = geo.D, geo.W, geo.g, geo.gv
	local gu = D + Step.GATE_OUT
	-- floor: asphalt with a painted web, paint splashes, the spider emblem
	local _, A = buildFloor(B, geo, P.asphalt, "Asphalt", 0)
	A.border(P.magenta, 0.45)
	local reach = math.max(D, W) * 1.45
	for i = 0, 7 do
		local a = math.rad(i * 45 + 22.5)
		A.line("WebSpoke", 0, 0, math.cos(a) * reach, math.sin(a) * reach, 0.28, if i % 2 == 0 then P.cyan else P.magenta, { z = 3 })
	end
	for ring = 1, 6 do
		local r = ring * 4.6
		for i = 0, 7 do
			local a1, a2, mid = math.rad(i * 45 + 22.5), math.rad(i * 45 + 67.5), math.rad(i * 45 + 45)
			local mu, mv = math.cos(mid) * (r - 0.9), math.sin(mid) * (r - 0.9) -- the threads sag toward the centre
			A.line("WebRing", math.cos(a1) * r, math.sin(a1) * r, mu, mv, 0.2, P.web, { z = 3, transparency = 0.15 })
			A.line("WebRing", mu, mv, math.cos(a2) * r, math.sin(a2) * r, 0.2, P.web, { z = 3, transparency = 0.15 })
		end
	end
	for _, splash in ipairs({ { D * 0.62, W * 0.6, P.magenta, 7 }, { -D * 0.6, -W * 0.55, P.cyan, 8 }, { -D * 0.55, W * 0.62, P.yellow, 5.5 }, { D * 0.55, -W * 0.6, P.cyan, 6 } }) do
		A.circle("Splash", splash[1], splash[2], splash[4], splash[3], { transparency = 0.45, z = 2 })
		A.circle("Splash", splash[1] + 2.5, splash[2] - 2.2, splash[4] * 0.35, splash[3], { transparency = 0.35, z = 2 })
		A.circle("Splash", splash[1] - 2.8, splash[2] + 1.6, splash[4] * 0.22, splash[3], { transparency = 0.3, z = 2 })
	end
	A.circle("SpiderGlow", 0, 0, 9, P.magenta, { transparency = 0.25, z = 4 })
	A.circle("SpiderBody", 0.9, 0, 3.4, P.black, { z = 6 })
	A.circle("SpiderHead", -1.6, 0, 2, P.black, { z = 6 })
	for _, side in ipairs({ -1, 1 }) do
		for leg = 0, 3 do
			local a = math.rad(-60 + leg * 40)
			local ku, kv = math.sin(a) * 2.4, side * math.cos(a) * 2.4
			local fu, fv = math.sin(a) * 2.4 + (leg - 1.5) * 1.2, side * (math.cos(a) * 2.4 + 1.8)
			A.line("SpiderLeg", 0.4, 0, ku, kv, 0.35, P.black, { z = 6 })
			A.line("SpiderLeg", ku, kv, fu, fv, 0.3, P.black, { z = 6 })
		end
	end

	-- corners: graffiti pillars with painted stripes and a yellow ring, web strands down the fences (outside)
	eachCorner(B, geo, function(u, v, su, sv)
		B.box("Pillar", u, v, 0, 2.2, 2.2, 8, P.brickDark, "Brick")
		B.box("PillarNeon", u + su * 1.13, v, 0.6, 0.08, 0.3, 7, P.magenta, "SmoothPlastic", { shadow = false, reflect = 0.05 })
		B.box("PillarNeon", u, v + sv * 1.13, 0.6, 0.3, 0.08, 7, P.cyan, "SmoothPlastic", { shadow = false, reflect = 0.05 })
		B.cyl("PillarRing", u, v, 8, 0.3, 2.4, P.yellow, "SmoothPlastic", { shadow = false, reflect = 0.05 })
		B.ball("PillarTop", u, v, 8.9, 1.2, P.black, "SmoothPlastic")
		local ov, ou = v + sv * 0.3, u + su * 0.3 -- strands run 0.9 outside the fence line
		B.beam("Web", u - su * 0.5, ov, 7.6, u - su * 7, ov, 4.4, 0.12, P.web, "SmoothPlastic", { shadow = false })
		B.beam("Web", u - su * 0.5, ov, 6.2, u - su * 4, ov, 3.4, 0.12, P.web, "SmoothPlastic", { shadow = false })
		B.beam("Web", ou, v - sv * 0.5, 7.6, ou, v - sv * 7, 4.4, 0.12, P.web, "SmoothPlastic", { shadow = false })
		B.beam("Web", ou, v - sv * 0.5, 6.2, ou, v - sv * 4, 3.4, 0.12, P.web, "SmoothPlastic", { shadow = false })
	end)

	-- gate: magenta and cyan pillars with a glitch ghost, a black lintel with the glitched name, a hanging spider
	B.group("Gate")
	for _, side in ipairs({ -1, 1 }) do
		local v = gv + side * g
		local color, ghost = if side < 0 then P.magenta else P.cyan, if side < 0 then P.cyan else P.magenta
		B.box("GatePillar", gu, v, 0, 1.9, 1.9, 11, color, "SmoothPlastic")
		B.box("GatePillarGhost", gu + 0.3, v + side * 0.3, 0, 1.9, 1.9, 11, ghost, "SmoothPlastic", { transparency = 0.72, shadow = false })
	end
	local lintel = B.panel("GateLintel", gu, gv, 11, 2 * g + 2.6, 2.6, 1.9, "front", P.black, "SmoothPlastic")
	local gui = newSurface(lintel, "Front", 40, 0)
	for i, layer in ipairs({ { P.cyan, -0.012 }, { P.magenta, 0.012 }, { P.web, 0 } }) do
		local label = newText(gui, "Glitch" .. i, "SPIDER-VERSE", layer[1], Enum.Font.Bangers, i + 1)
		label.Position = UDim2.fromScale(0.5 + layer[2], 0.5 + layer[2] * 2)
		label.Size = UDim2.fromScale(0.94, 0.85)
	end
	B.beam("GateThread", gu + 0.2, gv + 1.6, 11, gu + 0.2, gv + 1.6, 8.6, 0.08, P.web, "SmoothPlastic", { shadow = false })
	B.ball("GateSpider", gu + 0.2, gv + 1.6, 8.2, 0.9, P.black, "SmoothPlastic")
	B.ball("GateSpiderMark", gu + 0.62, gv + 1.6, 8.2, 0.3, P.red, "SmoothPlastic", { shadow = false, reflect = 0.05 })

	-- sides: graffiti boards facing the lanes
	B.group("Sides")
	for _, sv in ipairs({ -1, 1 }) do
		for i, u in ipairs({ -D / 2, D / 2 }) do
			local board = B.panel("SideBoard", u, sv * (W + 0.75), 1, 5, 3.4, 0.12, sideFacing(sv), P.black, "SmoothPlastic")
			signText(board, if i == 1 then "THWIP!" else "SPIDEY", if sv > 0 then P.magenta else P.cyan, P.yellow, Enum.Font.PermanentMarker, { strokePx = 3, rotation = -5 })
		end
	end
end

-- 4. MY HERO ACADEMIA: U.A. academy panels, red / green / white
Themes.Jungle = function(B, geo, P)
	local D, W, g, gv = geo.D, geo.W, geo.g, geo.gv
	local gu = D + Step.GATE_OUT
	-- floor: training-ground concrete, green lanes, the U.A. crest and PLUS ULTRA by the gate
	local _, A = buildFloor(B, geo, P.concrete, "Concrete", 0.6)
	A.border(P.green, 0.7)
	for _, side in ipairs({ -1, 1 }) do
		A.rect("Lane", 0, side * (W * 0.62), 2 * D - 6, 2.4, P.green, { transparency = 0.2, z = 2 })
		A.rect("LaneLine", 0, side * (W * 0.62 - 1.6), 2 * D - 6, 0.25, P.white, { z = 2 })
		A.rect("LaneLine", 0, side * (W * 0.62 + 1.6), 2 * D - 6, 0.25, P.white, { z = 2 })
	end
	A.circle("CrestRing", 0, 0, 20, P.white, { z = 3, stroke = { P.red, 0.9 } })
	A.rect("CrestShield", -0.3, 0, 9.4, 14.5, P.navy, { corner = 0.2, z = 4, stroke = { P.gold, 0.45 } })
	A.rect("CrestStripe", 2.7, 0, 0.8, 12, P.red, { z = 5 })
	A.rect("CrestStripe", 3.6, 0, 0.55, 12, P.green, { z = 5 })
	B.floorText("FloorLetter", "U.A.", -1.1, 0, 4.2, P.white, "SmoothPlastic")

	-- corners: white academy panels, red and green bands, glass cap, a glossy green ball
	eachCorner(B, geo, function(u, v)
		B.box("Panel", u, v, 0, 2.2, 2.2, 8.5, P.white, "SmoothPlastic")
		B.box("PanelRed", u, v, 5.4, 2.4, 2.4, 0.8, P.red, "SmoothPlastic")
		B.box("PanelGreen", u, v, 6.4, 2.4, 2.4, 0.5, P.green, "SmoothPlastic")
		B.box("PanelCap", u, v, 8.5, 2.4, 2.4, 0.8, P.glass, "Glass", { transparency = 0.1 })
		B.ball("PanelLight", u, v, 9.7, 0.9, P.greenLight, "SmoothPlastic", { shadow = false, reflect = 0.05 })
	end)

	-- gate: the U.A. security gate (thick grey pillars with bands), navy lintel, the crest on top
	B.group("Gate")
	for _, side in ipairs({ -1, 1 }) do
		local v = gv + side * (g + 0.2)
		B.box("GatePillar", gu, v, 0, 2.2, 2.3, 12, P.grey, "Concrete")
		B.box("GatePillarBand", gu, v, 3, 2.2, 2.45, 0.8, P.red, "SmoothPlastic")
		B.box("GatePillarBand", gu, v, 8, 2.2, 2.45, 0.5, P.green, "SmoothPlastic")
	end
	local lintel = B.panel("GateLintel", gu, gv, 10.2, 2 * g + 3, 2.4, 2.2, "front", P.navy, "SmoothPlastic")
	signText(lintel, "U.A. HIGH SCHOOL", P.white, P.navy, Enum.Font.GothamBlack, { bg = P.navy, border = P.gold, borderPx = 6 })
	local crest = B.panel("GateCrest", gu + 0.2, gv, 12.6, 3.6, 3.6, 0.5, "front", P.red, "SmoothPlastic")
	local crestGui = newSurface(crest, "Front", 40, 0)
	local shield = newFrame(crestGui, "Shield", P.navy, 0, 1)
	shield.Position = UDim2.fromScale(0.5, 0.5)
	shield.Size = UDim2.fromScale(0.86, 0.86)
	setCorner(shield, 0.2)
	addStroke(shield, P.gold, 5, 0)
	local ua = newText(crestGui, "UA", "UA", P.white, Enum.Font.GothamBlack, 2)
	ua.Position = UDim2.fromScale(0.5, 0.5)
	ua.Size = UDim2.fromScale(0.72, 0.6)
	addStroke(ua, P.red, 4, 0, true)

	-- sides: red and green flags
	B.group("Sides")
	for _, sv in ipairs({ -1, 1 }) do
		for i, u in ipairs({ -D / 2, D / 2 }) do
			B.panel("Flag", u, sv * (W + 0.75), 1.4, 3, 5.4, 0.12, sideFacing(sv), if i == 1 then P.red else P.green, "Fabric")
			B.panel("FlagStripe", u, sv * (W + 0.83), 3.6, 3, 0.8, 0.06, sideFacing(sv), P.white, "SmoothPlastic")
		end
	end
end

-- 5. DRAGON BALL: Capsule Corp / tournament arena, orange / blue, the seven Dragon Balls
Themes.Snow = function(B, geo, P)
	local D, W, g, gv = geo.D, geo.W, geo.g, geo.gv
	local gu = D + Step.GATE_OUT
	-- floor: tournament stone tiles, the four-star ball in the middle, CAPSULE CORP. by the gate
	local _, A = buildFloor(B, geo, P.stone, "Limestone", 0.8)
	local tile = 5.25
	for i = 1, math.floor((2 * D - 1.4) / tile) do
		A.rect("Grout", -D + 0.7 + i * tile, 0, 0.22, 2 * W - 1.4, P.stoneDark, { z = 2 })
	end
	for i = 1, math.floor((2 * W - 1.4) / tile) do
		A.rect("Grout", 0, -W + 0.7 + i * tile, 2 * D - 1.4, 0.22, P.stoneDark, { z = 2 })
	end
	A.border(P.orange, 0.8)
	A.circle("BallGlow", 0, 0, 16, P.orange, { transparency = 0.55, z = 3 })
	A.circle("Ball", 0, 0, 12.5, P.ball, { z = 4, stroke = { P.orangeDark, 0.4 } })
	A.circle("BallShine", -3, -2.8, 3.2, P.white, { transparency = 0.35, z = 5 })
	for _, s in ipairs({ { -2.2, 0 }, { 2.2, 0 }, { 0, -2.2 }, { 0, 2.2 } }) do
		A.rect("Star", s[1], s[2], 1.7, 1.7, P.star, { z = 6 })
		A.rect("Star", s[1], s[2], 1.7, 1.7, P.star, { z = 6, rotation = 45 })
	end

	-- corners: stone lanterns with a green roof and a glossy Dragon Ball
	eachCorner(B, geo, function(u, v)
		B.box("LanternBase", u, v, 0, 2.4, 2.4, 1, P.stoneDark, "Limestone")
		B.box("Lantern", u, v, 1, 1.8, 1.8, 5.6, P.stone, "Limestone")
		B.box("LanternRoof", u, v, 6.6, 2.4, 2.4, 0.5, P.roof, "SmoothPlastic")
		B.box("LanternRoofTop", u, v, 7.1, 1.6, 1.6, 0.4, P.roof, "SmoothPlastic")
		B.ball("LanternBall", u, v, 8.3, 1.6, P.ball, "SmoothPlastic", { shadow = false, reflect = 0.05 })
	end)

	-- gate: tournament gate, stone pillars, the Capsule Corp lintel under a gabled green roof, a Dragon Ball on top
	B.group("Gate")
	for _, side in ipairs({ -1, 1 }) do
		local v = gv + side * g
		B.box("GatePillar", gu, v, 0, 2.2, 2.2, 10.4, P.stone, "Limestone")
		B.box("GatePillarBand", gu, v, 8.6, 2.2, 2.4, 0.6, P.orange, "SmoothPlastic")
	end
	local lintel = B.panel("GateLintel", gu, gv, 10.4, 2 * g + 3, 2.2, 2.2, "front", P.white, "SmoothPlastic")
	signText(lintel, "CAPSULE CORP.", P.blue, P.white, Enum.Font.GothamBlack, { bg = P.white, border = P.blue, borderPx = 6 })
	B.wedge("GateRoof", gu + 0.7, gv, 12.6, 1.4, 2 * g + 4.4, 1.4, "back", P.roof, "SmoothPlastic")
	B.wedge("GateRoof", gu - 0.7, gv, 12.6, 1.4, 2 * g + 4.4, 1.4, "front", P.roof, "SmoothPlastic")
	B.ball("GateBall", gu, gv, 14.6, 1.6, P.ball, "SmoothPlastic", { shadow = false, reflect = 0.05 })

	-- sides: orange banners with a blue stripe and a Dragon Ball
	B.group("Sides")
	for _, sv in ipairs({ -1, 1 }) do
		for _, u in ipairs({ -D / 2, D / 2 }) do
			B.panel("Banner", u, sv * (W + 0.75), 1.4, 3.2, 5.4, 0.12, sideFacing(sv), P.orange, "Fabric")
			B.panel("BannerStripe", u, sv * (W + 0.83), 5.6, 3.2, 0.7, 0.06, sideFacing(sv), P.blue, "SmoothPlastic")
			local disc = B.panel("BannerBall", u, sv * (W + 0.83), 2.8, 1.8, 1.8, 0.06, sideFacing(sv), P.orange, "SmoothPlastic", { transparency = 1 })
			local gui = newSurface(disc, "Front", 40, 0)
			local ball = newFrame(gui, "Ball", P.ball, 0, 1)
			ball.Position = UDim2.fromScale(0.5, 0.5)
			ball.Size = UDim2.fromScale(0.95, 0.95)
			setCorner(ball, 0.5)
			addStroke(ball, P.orangeDark, 3, 0)
			for s = 0, 1 do
				local star = newFrame(gui, "Star", P.star, 0, 2)
				star.Position = UDim2.fromScale(0.5, 0.5)
				star.Size = UDim2.fromScale(0.34, 0.34)
				star.Rotation = s * 45
			end
		end
	end
end

-- 6. ONE PIECE: the Straw Hat pirate ship (hull, mast, sails, the straw-hat Jolly Roger)
local function jollyRoger(gui, P, withDisc)
	local function node(name, color, x, y, w, h, corner, z, rotation)
		local f = newFrame(gui, name, color, 0, z)
		f.Position = UDim2.fromScale(x, y)
		f.Size = UDim2.fromScale(w, h)
		f.SizeConstraint = Enum.SizeConstraint.RelativeYY
		f.Rotation = rotation or 0
		if corner then
			setCorner(f, corner)
		end
		return f
	end
	if withDisc then
		node("Mark", P.black, 0.5, 0.52, 0.66, 0.66, 0.5, 1)
	end
	node("Bone", P.white, 0.5, 0.62, 0.62, 0.07, 0.5, 2, 40)
	node("Bone", P.white, 0.5, 0.62, 0.62, 0.07, 0.5, 2, -40)
	node("Skull", P.white, 0.5, 0.5, 0.34, 0.3, 0.5, 3)
	node("Jaw", P.white, 0.5, 0.63, 0.2, 0.1, 0.3, 3)
	-- (RelativeYY: the x scale of a square element is a fraction of the height, centred by AnchorPoint)
	local eyeL = node("Eye", P.black, 0.5, 0.52, 0.08, 0.08, 0.5, 4)
	local eyeR = node("Eye", P.black, 0.5, 0.52, 0.08, 0.08, 0.5, 4)
	eyeL.AnchorPoint = Vector2.new(1.25, 0.5)
	eyeR.AnchorPoint = Vector2.new(-0.25, 0.5)
	node("HatBrim", P.straw, 0.5, 0.39, 0.52, 0.09, 0.5, 5)
	node("HatCrown", P.straw, 0.5, 0.32, 0.28, 0.14, 0.45, 5)
	node("HatBand", P.red, 0.5, 0.36, 0.29, 0.04, nil, 6)
end

Themes.Volcano = function(B, geo, P)
	local D, W, g, gv = geo.D, geo.W, geo.g, geo.gv
	local gu = D + Step.GATE_OUT
	-- floor: the ship's deck, planks along the pen and a ship's wheel in the middle
	local _, A = buildFloor(B, geo, P.plank, "WoodPlanks", 0.9)
	local plank = 2.2
	for i = 1, math.floor((2 * W - 1.4) / plank) do
		A.rect("Seam", 0, -W + 0.7 + i * plank, 2 * D - 1.4, 0.12, P.woodDark, { z = 2, transparency = 0.2 })
	end
	A.border(P.woodDark, 0.7)
	A.ring("Wheel", 0, 0, 14, P.woodDark, 1.1, { z = 3 })
	A.ring("WheelInner", 0, 0, 6.2, P.woodDark, 0.7, { z = 3 })
	for i = 0, 7 do
		local a = math.rad(i * 45)
		A.line("Spoke", math.cos(a) * 3, math.sin(a) * 3, math.cos(a) * 9.1, math.sin(a) * 9.1, 0.7, P.woodDark, { z = 3 })
		A.circle("Handle", math.cos(a) * 9.3, math.sin(a) * 9.3, 1.3, P.woodLight, { z = 4, stroke = { P.woodDark, 0.2 } })
	end
	A.circle("Hub", 0, 0, 3, P.gold, { z = 4, stroke = { P.woodDark, 0.25 } })

	-- corners: mooring posts with rope rings and a lantern
	eachCorner(B, geo, function(u, v)
		B.cyl("Bollard", u, v, 0, 6.6, 1.9, P.woodDark, "Wood")
		B.cyl("Rope", u, v, 2, 0.45, 2.15, P.rope, "Fabric")
		B.cyl("Rope", u, v, 2.7, 0.45, 2.15, P.rope, "Fabric")
		B.cyl("BollardCap", u, v, 6.6, 0.4, 2.3, P.iron, "Metal")
		B.box("Lantern", u, v, 7, 1, 1, 1.3, P.gold, "Metal", { transparency = 0.15 })
		B.box("LanternFlame", u, v, 7.2, 0.6, 0.6, 0.9, rgb(255, 150, 60), "SmoothPlastic", { shadow = false, reflect = 0.05 })
	end)

	-- gate: gangway posts wrapped in rope, a crossbeam, the name board and two lanterns
	B.group("Gate")
	for _, side in ipairs({ -1, 1 }) do
		local v = gv + side * g
		B.cyl("GatePost", gu, v, 0, 10.8, 1.9, P.woodDark, "Wood")
		B.cyl("GateRope", gu, v, 8.4, 0.5, 2.15, P.rope, "Fabric")
		B.cyl("GateRope", gu, v, 9.1, 0.5, 2.15, P.rope, "Fabric")
		B.box("GateLantern", gu + 1.3, v + side * 0.3, 7.6, 0.9, 0.9, 1.2, P.gold, "Metal", { transparency = 0.15 })
		B.box("GateLanternFlame", gu + 1.3, v + side * 0.3, 7.8, 0.5, 0.5, 0.8, rgb(255, 150, 60), "SmoothPlastic", { shadow = false, reflect = 0.05 })
	end
	B.box("GateBeam", gu, gv, 10.8, 1.6, 2 * g + 3.2, 1.2, P.wood, "Wood")
	local board = B.panel("GateBoard", gu + 0.5, gv, 12.1, 2 * g + 1, 2.2, 0.4, "front", P.woodLight, "Wood")
	signText(board, "STRAW HAT PIRATES", P.sail, P.woodDark, Enum.Font.LuckiestGuy, { strokePx = 4, light = 0.6 })
	B.cyl("GateFlagPole", gu, gv - g - 0.2, 10.8, 6.6, 0.3, P.iron, "Metal")
	local flag = B.panel("GateFlag", gu + 0.2, gv - g + 1.6, 14.3, 3.6, 2.3, 0.12, "front", P.black, "Fabric")
	jollyRoger(newSurface(flag, "Front", 30, 0.5), P, false)

	-- sides: pennants on a rope along the side fences
	B.group("Sides")
	for _, sv in ipairs({ -1, 1 }) do
		for i = 0, 3 do
			local u = -D + (i + 0.5) * (2 * D / 4)
			B.panel("SideFlag", u, sv * (W + 0.75), 4.3, 2.4, 1.6, 0.1, sideFacing(sv), if i % 2 == 0 then P.red else P.straw, "Fabric")
		end
		B.beam("SideRope", -D + 1, sv * (W + 0.75), 5.95, D - 1, sv * (W + 0.75), 5.95, 0.16, P.rope, "Fabric", { shadow = false })
	end
end

---------------------------------------------------------------------------------------------------
-- clearance check
---------------------------------------------------------------------------------------------------

-- World AABBs of everything the props may not touch outside the plots (computed once).
local function worldObstacles(ws, plots)
	local out = {}
	for _, d in ipairs(ws:GetDescendants()) do
		if d:IsA("BasePart") and not d:IsDescendantOf(plots) and d.Name ~= "Baseplate" and (d.Transparency < 1 or d.CanCollide) then
			local mn, mx = worldAabb(d)
			local size = mx - mn
			-- huge floor / marker volumes (Ground, zone lines) are not obstacles; walls, boards and stalls are
			if size.X < 600 and size.Z < 600 and mx.Y > 2.3 then
				table.insert(out, { mn, mx, d:GetFullName() })
			end
		end
	end
	return out
end

-- Boxes nothing themed on `plot` may touch: its functional parts, every other plot, other world geometry.
local function obstaclesFor(plots, plot, zoneMin, zoneMax, world)
	local boxes = {}
	local m = Vector3.new(Step.OBSTACLE_MARGIN, Step.OBSTACLE_MARGIN, Step.OBSTACLE_MARGIN)
	local function add(mn, mx, why)
		if boxesOverlap(mn, mx, zoneMin, zoneMax) then
			table.insert(boxes, { mn - m, mx + m, why })
		end
	end
	for _, name in ipairs({ "PlotUpgrade", "TreadmillUpgrade", "Multiplier", "SpeedsterTreadmillDisplay", "TreadmillBottom", "SpawnPoint" }) do
		local node = plot:FindFirstChild(name)
		if node then
			for _, d in ipairs({ node, table.unpack(node:GetDescendants()) }) do
				if d:IsA("BasePart") then
					local mn, mx = worldAabb(d)
					add(mn, mx, plot.Name .. "." .. name)
				end
			end
		end
	end
	for _, other in ipairs(plots:GetChildren()) do
		if other ~= plot then
			for _, d in ipairs(other:GetDescendants()) do
				if d:IsA("BasePart") and d.Transparency < 1 then
					local mn, mx = worldAabb(d)
					add(mn, mx, "Plots." .. other.Name)
				end
			end
		end
	end
	for _, entry in ipairs(world) do
		add(entry[1], entry[2], entry[3])
	end
	return boxes
end

-- Why `part` breaks the zones (nil = fine). Pen-local AABB: x = v, y = h, z = -u.
function Step.clearanceIssue(part, geo, obstacles)
	local D, W, g, gv = geo.D, geo.W, geo.g, geo.gv
	local lmn, lmx = localAabb(part, geo.frame)
	local uMin, uMax = -lmx.Z, -lmn.Z
	local vMin, vMax = lmn.X, lmx.X
	local hMin, hMax = lmn.Y, lmx.Y
	local eps = 0.01
	if part.Name == Step.PREFIX .. "Floor" then
		if hMax > Step.FLOOR_TOP + 0.01 or uMax > D or uMin < -D or vMax > W or vMin < -W then
			return "floor out of place"
		end
		return nil
	end
	local function intoPen(inset)
		return hMax > 0.25 and uMax > -D + inset + eps and uMin < D - inset - eps and vMax > -W + inset + eps and vMin < W - inset - eps
	end
	if (hMin < Step.HIGH_OVERHANG and intoPen(Step.INTERIOR_INSET)) or intoPen(2.5) then
		return "hero area"
	end
	local clear = g - Step.GATE_CLEAR_HALF
	if hMin < Step.GATE_CLEAR_HEIGHT and uMax > D - 2.5 and uMin < D + 3 and vMax > gv - clear and vMin < gv + clear then
		return "gate passage"
	end
	if uMax > D + Step.FRONT_MAX + eps or uMin < -D - Step.BACK_MAX - eps or vMax > W + Step.SIDE_MAX + eps
		or vMin < -W - Step.SIDE_MAX - eps or hMax > Step.TOP_MAX then
		return "outside the plot zone"
	end
	if obstacles then
		local mn, mx = worldAabb(part)
		for _, box in ipairs(obstacles) do
			if boxesOverlap(mn, mx, box[1], box[2]) then
				return box[3]
			end
		end
	end
	return nil
end

-- Drops every group of `model` with a part that breaks the zones; returns "group (part: why)" strings and the dropped
-- group names.
local function enforceClearance(model, geo, obstacles)
	local dropped, names = {}, {}
	for _, group in ipairs(model:GetChildren()) do
		for _, part in ipairs(group:GetDescendants()) do
			if part:IsA("BasePart") then
				local why = Step.clearanceIssue(part, geo, obstacles)
				if why then
					table.insert(dropped, string.format("%s (%s: %s)", group.Name, part.Name, why))
					table.insert(names, group.Name)
					group:Destroy()
					break
				end
			end
		end
	end
	return dropped, names
end

-- A corner pylon that did not fit (e.g. plot 6's front corner next to the money leaderboard) becomes a slim finial
-- on the corner post itself: a stem and a glossy orb in the theme's gem colour (no neon), no wider than the post.
local function slimCorner(B, geo, groupName, theme)
	local front = string.match(groupName, "^" .. Step.PREFIX .. "Corner(Front)") or string.match(groupName, "^" .. Step.PREFIX .. "Corner(Back)")
	local right = string.match(groupName, "(Right)$") or string.match(groupName, "(Left)$")
	if front == nil or right == nil then
		return
	end
	local u = (if front == "Front" then 1 else -1) * geo.D
	local v = (if right == "Right" then 1 else -1) * geo.W
	B.group("Corner" .. front .. right .. "Slim")
	B.cyl("FinialStem", u, v, 6.9, 1, 0.5, theme.Fence.Post, "SmoothPlastic")
	B.ball("FinialOrb", u, v, 8.4, 1.2, theme.Fence.Gem, "SmoothPlastic", { shadow = false, reflect = 0.05 })
end

---------------------------------------------------------------------------------------------------
-- preview (canonical pen for the Index page)
---------------------------------------------------------------------------------------------------

local function buildPreviewFence(B, geo, theme)
	B.group("PreviewFence")
	local F = theme.Fence
	local D, W, g, gv = geo.D, geo.W, geo.g, geo.gv
	local posts = {}
	for i = 0, 5 do
		local t = -D + i * (2 * D / 5)
		table.insert(posts, { t, -W })
		table.insert(posts, { t, W })
	end
	for i = 1, 4 do
		local t = -W + i * (2 * W / 5)
		table.insert(posts, { -D, t })
		table.insert(posts, { D, t })
	end
	for _, p in ipairs(posts) do
		B.box("PreviewPost", p[1], p[2], 0, 1.2, 1.2, 4.2, F.Post, "SmoothPlastic")
		B.box("PreviewCap", p[1], p[2], 4.2, 1.6, 1.6, 0.3, F.Cap, "SmoothPlastic")
		B.box("PreviewGem", p[1], p[2], 4.5, 0.6, 0.6, 0.6, F.Gem, "SmoothPlastic", { yaw = math.pi / 4, reflect = 0.05 })
	end
	for _, sv in ipairs({ -1, 1 }) do
		B.box("PreviewRail", 0, sv * W, 3.2, 2 * D, 0.6, 0.7, F.RailTop, "SmoothPlastic")
		B.box("PreviewRail", 0, sv * W, 0.6, 2 * D, 0.6, 0.6, F.RailLow, "SmoothPlastic")
	end
	B.box("PreviewRail", -D, 0, 3.2, 0.6, 2 * W, 0.7, F.RailTop, "SmoothPlastic")
	B.box("PreviewRail", -D, 0, 0.6, 0.6, 2 * W, 0.6, F.RailLow, "SmoothPlastic")
	for _, side in ipairs({ -1, 1 }) do
		local inner, outer = gv + side * g, side * W
		local c, len = (inner + outer) / 2, math.abs(outer - inner)
		B.box("PreviewRail", D, c, 3.2, 0.6, len, 0.7, F.RailTop, "SmoothPlastic")
		B.box("PreviewRail", D, c, 0.6, 0.6, len, 0.6, F.RailLow, "SmoothPlastic")
	end
	-- a grass ground under the pen (the world ground is not in the viewport)
	B.box("PreviewGround", 0, 0, -0.5, 2 * D + 12, 2 * W + 12, 0.5, rgb(105, 208, 20), "SmoothPlastic", { shadow = false })
end

---------------------------------------------------------------------------------------------------
-- imported (Blender) pens
---------------------------------------------------------------------------------------------------

-- The plot's zone box (world AABB, h -10 .. 60) the props may use, the landmark zone behind the back fence included
-- (section 7): the obstacles outside it never matter.
function Step.plotZone(geo)
	local zMin, zMax = Vector3.new(math.huge, -10, math.huge), Vector3.new(-math.huge, 60, -math.huge)
	local back = math.max(Step.BACK_MAX, Step.LANDMARK.back)
	local side = math.max(Step.SIDE_MAX, Step.LANDMARK.side)
	for _, c in ipairs({ { -geo.D - back, -geo.W - side }, { -geo.D - back, geo.W + side },
		{ geo.D + Step.FRONT_MAX, -geo.W - side }, { geo.D + Step.FRONT_MAX, geo.W + side } }) do
		local p = (geo.frame * CFrame.new(c[2], 0, -c[1])).Position
		zMin = Vector3.new(math.min(zMin.X, p.X), -10, math.min(zMin.Z, p.Z))
		zMax = Vector3.new(math.max(zMax.X, p.X), 60, math.max(zMax.Z, p.Z))
	end
	return zMin, zMax
end

-- Every measured plot of a built place with its pen geometry and the obstacle boxes Apply checks the props against
-- (world AABBs grown by OBSTACLE_MARGIN, like obstaclesFor): { { plot, geo, obstacles } } sorted by plot number. For the
-- offline tools (scripts/tools/test_base_imports.luau exports them in the pen frame for the Blender self-check).
function Step.measurePlots(place, groundY)
	local ws = place:GetService("Workspace")
	local plots = ws:FindFirstChild("Plots")
	local out = {}
	if plots == nil then
		return out
	end
	local world = worldObstacles(ws, plots)
	for _, plot in ipairs(plots:GetChildren()) do
		local geo = if plot:IsA("Model") and tonumber(plot.Name) then Step.measurePen(plot, groundY or 2.05) else nil
		if geo then
			local zMin, zMax = Step.plotZone(geo)
			table.insert(out, { plot = plot, geo = geo, obstacles = obstaclesFor(plots, plot, zMin, zMax, world) })
		end
	end
	table.sort(out, function(a, b)
		return tonumber(a.plot.Name) < tonumber(b.plot.Name)
	end)
	return out
end

-- The newest-format layout of a theme folder: the first <root>/<key>/*.json with format IMPORT_FORMAT (sorted by name).
-- Returns layout, path, or nil, nil, legacyPath (the first layout of a LEGACY_IMPORT_FORMATS format there, if any).
function Step.findLayout(root, key)
	local dir = root .. "/" .. key
	if not fs.isDir(dir) then
		return nil
	end
	local names = fs.readDir(dir)
	table.sort(names)
	local legacy = nil
	for _, name in ipairs(names) do
		if string.sub(name, -5) == ".json" then
			local path = dir .. "/" .. name
			local ok, layout = pcall(serde.decode, "json", fs.readFile(path))
			if ok and type(layout) == "table" and type(layout.variants) == "table" and type(layout.palette) == "table"
				and type(layout.variant_order) == "table" then
				if layout.format == Step.IMPORT_FORMAT then
					return layout, path
				elseif table.find(Step.LEGACY_IMPORT_FORMATS, layout.format) then
					legacy = legacy or path
				end
			end
		end
	end
	return nil, nil, legacy
end

-- The variant and role of an imported part from its name ("Std_Structure_Crimson", "Deep_Neon_Emissive_Cyan.001", ...):
-- the variant prefix at the start, then the longest palette role in the rest (Studio may add suffixes).
local function importRole(layout, name)
	local lower = string.lower(name)
	for _, vname in ipairs(layout.variant_order) do
		local prefix = string.lower(layout.variants[vname].prefix)
		if string.sub(lower, 1, #prefix) == prefix then
			local rest = string.sub(lower, #prefix + 1)
			local best
			for role in pairs(layout.palette) do
				if string.find(rest, string.lower(role), 1, true) and (best == nil or #role > #best) then
					best = role
				end
			end
			return vname, best
		end
	end
	return nil, nil
end

local function unionAabb(parts)
	local mn = Vector3.new(math.huge, math.huge, math.huge)
	local mx = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in ipairs(parts) do
		local a, b = worldAabb(part)
		mn, mx = mn:Min(a), mx:Max(b)
	end
	return mn, mx
end

-- pen-frame boxes { v0, u0, h0, v1, u1, h1, role, zone } of every modelled piece of a layout variant (zone "landmark"
-- for the pieces of a landmark, section 7; nil = the pen)
local function penPieces(vlayout)
	local out = {}
	for _, piece in ipairs(vlayout.pieces) do
		local a, b = piece[2], piece[3]
		table.insert(out, { a[1], a[2], a[3], b[1], b[2], b[3], piece[1], piece[4] })
	end
	return out
end

-- Section 8: the window-light style of a layout (its "window_lights" over Step.WINDOW_DEFAULTS; never Neon).
local function colourOf(value, fallback)
	if type(value) == "table" and #value == 3 then
		local ok = true
		for k = 1, 3 do
			ok = ok and type(value[k]) == "number" and value[k] >= 0 and value[k] <= 255
		end
		if ok then
			return { math.floor(value[1] + 0.5), math.floor(value[2] + 0.5), math.floor(value[3] + 0.5) }
		end
	end
	return fallback
end

local function positive(value, fallback, max)
	if type(value) == "number" and value == value and value > 0 and value <= (max or math.huge) then
		return value
	end
	return fallback
end

function Step.windowStyle(layout)
	local d = Step.WINDOW_DEFAULTS
	local src = type(layout.window_lights) == "table" and layout.window_lights or {}
	local flicker = type(src.flicker) == "table" and src.flicker or {}
	local mat = type(src.material) == "string" and src.material or d.material
	mat = Step.BANNED_MATERIALS[mat] or mat
	if not pcall(function()
		return Enum.Material[mat]
	end) then
		mat = d.material
	end
	local minGap = positive(flicker.min_gap_s, d.minGap, 600)
	return {
		material = mat,
		lit = colourOf(src.lit_rgb, d.lit),
		off = colourOf(src.off_rgb, d.off),
		thickness = positive(src.thickness, d.thickness, 1),
		litFraction = math.clamp(tonumber(src.lit_fraction) or d.litFraction, 0, 1),
		minGap = minGap,
		maxGap = math.max(minGap, positive(flicker.max_gap_s, d.maxGap, 600)),
		tween = positive(flicker.tween_s, d.tween, 5),
		range = positive(flicker.range_studs, d.range, 5000),
	}
end

-- Section 8: the valid pane slots of a layout variant: { { id, building, c = { v, u, h }, w, h, n = { nv, nu }, lit, zone } }
-- + the reasons of the skipped ones.
function Step.windowSlots(vlayout)
	local out, skipped = {}, {}
	local list = type(vlayout.windows) == "table" and vlayout.windows or {}
	for i, slot in ipairs(list) do
		local c, size, n = type(slot) == "table" and slot.c, type(slot) == "table" and slot.size, type(slot) == "table" and slot.n
		local why = nil
		if #out >= Step.WINDOW_MAX then
			why = "more than " .. Step.WINDOW_MAX .. " slots"
		elseif type(c) ~= "table" or type(c[1]) ~= "number" or type(c[2]) ~= "number" or type(c[3]) ~= "number"
			or c[1] ~= c[1] or c[2] ~= c[2] or c[3] ~= c[3] then
			why = "no centre"
		elseif type(size) ~= "table" or positive(size[1], nil, Step.WINDOW_MAX_SIZE) == nil
			or positive(size[2], nil, Step.WINDOW_MAX_SIZE) == nil then
			why = "size not in 0.." .. Step.WINDOW_MAX_SIZE
		elseif type(n) ~= "table" or type(n[1]) ~= "number" or type(n[2]) ~= "number"
			or math.abs(tonumber(n[3]) or 0) > 0.05 or math.sqrt(n[1] * n[1] + n[2] * n[2]) < 0.5 then
			why = "facing normal not horizontal"
		end
		if why then
			table.insert(skipped, string.format("slot %s: %s", tostring(type(slot) == "table" and slot.id or i), why))
		else
			local len = math.sqrt(n[1] * n[1] + n[2] * n[2])
			table.insert(out, {
				id = tostring(slot.id or i),
				building = tostring(slot.building or ""),
				c = { c[1], c[2], c[3] },
				w = size[1],
				h = size[2],
				n = { n[1] / len, n[2] / len },
				lit = colourOf(slot.lit_rgb, nil),
				zone = if slot.zone == "landmark" then "landmark" else nil,
			})
		end
	end
	return out, skipped
end

-- Section 8: the pen-frame box of every pane (checked like a modelled piece: { v0, u0, h0, v1, u1, h1, role, zone }).
function Step.windowPieces(slots, thickness)
	local out = {}
	for _, s in ipairs(slots) do
		local nv, nu = math.abs(s.n[1]), math.abs(s.n[2])
		local hv = nv * thickness / 2 + nu * s.w / 2
		local hu = nu * thickness / 2 + nv * s.w / 2
		table.insert(out, { s.c[1] - hv, s.c[2] - hu, s.c[3] - s.h / 2, s.c[1] + hv, s.c[2] + hu, s.c[3] + s.h / 2,
			Step.WINDOW_PANE .. " " .. s.id, s.zone })
	end
	return out
end

-- Section 8: the pane Parts of an imported pen re-placed in `frame` (a plot's pen frame): Model ThemeWindows, tagged for
-- StarterPlayerScripts.Game.Plots.BaseWindowLights, every pane lit. nil when the layout has no slots.
function Step.placeWindowPanes(pen, frame)
	local slots = pen.windows
	if type(slots) ~= "table" or #slots == 0 then
		return nil
	end
	local style = pen.windowStyle or Step.windowStyle({})
	local group = Instance.new("Model")
	group.Name = Step.PREFIX .. Step.WINDOW_GROUP
	local lit = rgb(style.lit[1], style.lit[2], style.lit[3])
	local off = rgb(style.off[1], style.off[2], style.off[3])
	group:SetAttribute("WindowLitColor", lit)
	group:SetAttribute("WindowOffColor", off)
	group:SetAttribute("WindowLitFraction", style.litFraction)
	group:SetAttribute("WindowMinGap", style.minGap)
	group:SetAttribute("WindowMaxGap", style.maxGap)
	group:SetAttribute("WindowTween", style.tween)
	group:SetAttribute("WindowRange", style.range)
	group:SetAttribute("WindowCount", #slots)
	group:SetAttribute("ImportedPen", pen.name)
	local up = frame:VectorToWorldSpace(Vector3.new(0, 1, 0))
	local sum = Vector3.new(0, 0, 0)
	for _, slot in ipairs(slots) do
		local part = Instance.new("Part")
		part.Name = Step.PREFIX .. Step.WINDOW_PANE
		-- pen frame (v, u, h) -> the frame's axes (x = v, y = h, z = -u); the pane's local +Z = its facing normal
		local centre = frame:PointToWorldSpace(Vector3.new(slot.c[1], slot.c[3], -slot.c[2]))
		local normal = frame:VectorToWorldSpace(Vector3.new(slot.n[1], 0, -slot.n[2])).Unit
		local right = up:Cross(normal).Unit
		part.CFrame = CFrame.fromMatrix(centre, right, up, normal)
		part.Size = Vector3.new(slot.w, slot.h, style.thickness)
		part.Material = material(style.material)
		part.Color = if slot.lit then rgb(slot.lit[1], slot.lit[2], slot.lit[3]) else lit
		part.Reflectance = 0
		part.Transparency = 0
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part:SetAttribute("WindowId", slot.id)
		part:SetAttribute("Building", slot.building)
		if slot.lit then
			part:SetAttribute("LitColor", part.Color) -- an accent window (the client relights it in this colour)
		end
		part.Parent = group
		sum += centre
	end
	group.WorldPivotData = CFrame.fromMatrix(sum / #slots, frame.RightVector, frame.UpVector, -frame.LookVector)
	group:AddTag(Step.WINDOW_TAG)
	return group
end

-- The geometry fingerprint of a layout (section 6): sha1 over every variant's prefix, depth, footprint, per-role object
-- bounds and tris and every piece box (%.3f), nothing else (palette, lights, renders, plots and problems do not count).
-- scripts/tools/blender/base_themes/pipeline.py geometry_fingerprint() writes the same string into the JSON.
local function f3(x)
	return string.format("%.3f", (tonumber(x) or 0) + 0.0)
end

local function sortedKeys(t)
	local keys = {}
	for k in pairs(t or {}) do
		table.insert(keys, k)
	end
	table.sort(keys)
	return keys
end

function Step.geometryFingerprint(layout)
	local lines = { Step.FINGERPRINT_FORMAT }
	for _, vname in ipairs(layout.variant_order) do
		local v = layout.variants[vname]
		table.insert(lines, string.format("variant %s %s %s %s %s", vname, v.prefix, f3(v.half_depth), f3(v.footprint[1]), f3(v.footprint[2])))
		for _, role in ipairs(sortedKeys(v.object_bounds)) do
			local b = v.object_bounds[role]
			table.insert(lines, string.format("bounds %s %s %s %s %s %s %s", role, f3(b[1][1]), f3(b[1][2]), f3(b[1][3]), f3(b[2][1]),
				f3(b[2][2]), f3(b[2][3])))
		end
		for _, role in ipairs(sortedKeys(v.tris)) do
			table.insert(lines, string.format("tris %s %d", role, math.floor(tonumber(v.tris[role]) or 0)))
		end
		for _, p in ipairs(v.pieces or {}) do
			local a, b = p[2], p[3]
			table.insert(lines, string.format("piece %s %s %s %s %s %s %s%s", p[1], f3(a[1]), f3(a[2]), f3(a[3]), f3(b[1]), f3(b[2]),
				f3(b[3]), if p[4] ~= nil then " " .. tostring(p[4]) else ""))
		end
	end
	return "g1:" .. string.sub(serde.hash("sha1", table.concat(lines, "\n")), 1, 24)
end

-- Is an import (its root models' GeometryFingerprint stamp, or none) made from the layout's geometry? Returns true, or
-- false + why (the why names "re-import <fbx>").
function Step.importIsCurrent(layout, roots)
	local stamp = nil
	for _, root in ipairs(roots or {}) do
		local value = root:GetAttribute("GeometryFingerprint")
		if type(value) == "string" and value ~= "" then
			stamp = value
			break
		end
	end
	local current = Step.geometryFingerprint(layout)
	local fbx = tostring(layout.fbx or (tostring(layout.name) .. ".fbx"))
	if stamp == nil then
		local presumed = Step.PRESTAMP_IMPORTS[layout.name]
		if presumed == nil then
			return false, string.format("the import carries no geometry stamp (made before the 2026-09-25 helper): re-import %s and run"
				.. " assets/models/bases/BaseThemesImport.lua", fbx)
		elseif presumed ~= current then
			return false, string.format("stale import: the geometry of %s changed since the owner's import (%s, now %s): re-import %s"
				.. " and run assets/models/bases/BaseThemesImport.lua", tostring(layout.name), presumed, current, fbx)
		end
		return true, "unstamped (2026-09-25 import) " .. current
	elseif stamp ~= current then
		return false, string.format("stale import: made from geometry %s, the layout is %s: re-import %s and run"
			.. " assets/models/bases/BaseThemesImport.lua", stamp, current, fbx)
	end
	return true, "stamped " .. current
end

-- One variant of an imported theme against its layout. Returns the pen or nil, why.
-- pen = { name, key, variant, layout (the variant's), contract, anchors, palette, parts = { { part, role } }, frame (the
-- import's own pen frame), scale, pieces, lights (always empty), windows / windowStyle / windowPieces / windowSkipped
-- (section 8: the variant's pane slots, the layout's window-light style, the panes' boxes, the slots left out) }
local function loadImportedVariant(layout, vname, byRole, path)
	local vlayout = layout.variants[vname]
	if type(vlayout.problems) == "table" and #vlayout.problems > 0 then
		return nil, string.format("the layout lists %d self-check problem(s), e.g. %s", #vlayout.problems, tostring(vlayout.problems[1]))
	end
	local floorRole = layout.anchors and layout.anchors.floor or "Floor_Base"
	local screenRole = layout.anchors and layout.anchors.screen or "Neon_Emissive_Screen"
	local missing = {}
	for role in pairs(vlayout.object_bounds) do
		if byRole[role] == nil then
			table.insert(missing, role)
		end
	end
	if #missing > 0 then
		table.sort(missing)
		return nil, string.format("%s has no %s part (%s)", path, vlayout.prefix .. missing[1], table.concat(missing, ", "))
	end
	if byRole[floorRole] == nil or byRole[screenRole] == nil then
		return nil, "no " .. floorRole .. " / " .. screenRole .. " anchor parts"
	end
	local floorMin, floorMax = unionAabb(byRole[floorRole])
	local floorSize = floorMax - floorMin
	if floorSize.Y > 0.2 * math.min(floorSize.X, floorSize.Z) then
		return nil, "the floor is not horizontal (the import is tilted)"
	end
	local centre = (floorMin + floorMax) / 2
	local signMin, signMax = unionAabb(byRole[screenRole])
	local d = (signMin + signMax) / 2 - centre
	local front = if math.abs(d.X) > math.abs(d.Z) then Vector3.new(if d.X > 0 then 1 else -1, 0, 0)
		else Vector3.new(0, 0, if d.Z > 0 then 1 else -1)
	local up = Vector3.new(0, 1, 0)
	local right = front:Cross(up)
	if Vector3.new(d.X, 0, d.Z):Dot(right) <= 0 then
		return nil, "the import is mirrored (the terminal is on the wrong side of the gate)"
	end
	local flat = Vector3.new(floorSize.X, 0, floorSize.Z)
	local widthRaw, depthRaw = math.abs(flat:Dot(right)), math.abs(flat:Dot(front))
	local footprint = vlayout.footprint
	local scale = footprint[1] / widthRaw
	if math.abs(depthRaw * scale - footprint[2]) > 0.02 * footprint[2] then
		return nil, string.format("floor proportions %.2f x %.2f do not match the layout %.2f x %.2f", widthRaw * scale,
			depthRaw * scale, footprint[1], footprint[2])
	end
	local frame = CFrame.fromMatrix(Vector3.new(centre.X, floorMin.Y, centre.Z), right, up, -front)
	-- every part must land on its layout bounds (catches a wrong file, a partial or distorted import)
	local tol = Step.IMPORT_BOUNDS_TOLERANCE
	local parts = {}
	for role, list in pairs(byRole) do
		local bounds = vlayout.object_bounds[role]
		if bounds == nil then
			return nil, string.format("%s%s is not in the layout", vlayout.prefix, role)
		end
		local mn, mx = unionAabb(list)
		local a = frame:PointToObjectSpace(mn) * scale
		local b = frame:PointToObjectSpace(mx) * scale
		local lmn, lmx = a:Min(b), a:Max(b) -- x = v, y = h, z = -u
		local got = { lmn.X, -lmx.Z, lmn.Y, lmx.X, -lmn.Z, lmx.Y }
		local want = { bounds[1][1], bounds[1][2], bounds[1][3], bounds[2][1], bounds[2][2], bounds[2][3] }
		for k = 1, 6 do
			if math.abs(got[k] - want[k]) > tol + 0.005 * math.abs(want[k]) then
				return nil, string.format("%s%s lands at v %.2f..%.2f u %.2f..%.2f h %.2f..%.2f, the layout says v %.2f..%.2f u %.2f..%.2f h %.2f..%.2f"
					.. " (an import older than the layout? re-import %s)", vlayout.prefix, role, got[1], got[4], got[2], got[5], got[3],
					got[6], want[1], want[4], want[2], want[5], want[3], want[6], tostring(layout.fbx))
			end
		end
		for _, part in ipairs(list) do
			table.insert(parts, { part = part, role = role })
		end
	end
	table.sort(parts, function(x, y)
		return x.role < y.role
	end)
	local windowStyle = Step.windowStyle(layout)
	local windows, windowSkipped = Step.windowSlots(vlayout)
	return {
		name = layout.name,
		key = layout.key,
		variant = vname,
		layout = vlayout,
		contract = layout.contract,
		anchors = { floor = floorRole, screen = screenRole },
		palette = layout.palette,
		parts = parts,
		frame = frame,
		scale = scale,
		pieces = penPieces(vlayout),
		lights = {}, -- never used: no lights in the bases (section 5)
		windows = windows,
		windowStyle = windowStyle,
		windowPieces = Step.windowPieces(windows, windowStyle.thickness),
		windowSkipped = windowSkipped,
	}
end

-- Reads <root>/<key>/<layout.import> (a Studio "Import 3D" of the theme's FBX, saved to file) against the layout.
-- Returns { key, name, layout, variants = { pen, ... } (in the layout's order), rejected = { why, ... } } or nil, why.
function Step.loadImportedTheme(key, layout)
	local path = string.format("%s/%s/%s", Step.IMPORTS_ROOT, key, tostring(layout.import))
	if not fs.isFile(path) then
		return nil, "not imported yet (" .. path .. ")"
	end
	local ok, roots = pcall(roblox.deserializeModel, fs.readFile(path))
	if not ok or type(roots) ~= "table" then
		return nil, "unreadable " .. path .. ": " .. tostring(roots)
	end
	-- section 6: an import of an older geometry is ignored (the procedural theme stays until the owner re-imports)
	local current, why = Step.importIsCurrent(layout, roots)
	if not current then
		return nil, why, true
	end
	local byVariant, ignored = {}, 0
	for _, root in ipairs(roots) do
		for _, d in ipairs({ root, table.unpack(root:GetDescendants()) }) do
			if d:IsA("BasePart") then
				local vname, role = importRole(layout, d.Name)
				if vname and role then
					byVariant[vname] = byVariant[vname] or {}
					byVariant[vname][role] = byVariant[vname][role] or {}
					table.insert(byVariant[vname][role], d)
				else
					ignored += 1
				end
			end
		end
	end
	local out = { key = key, name = layout.name, layout = layout, variants = {}, rejected = {}, ignored = ignored, geometry = why }
	for _, vname in ipairs(layout.variant_order) do
		if byVariant[vname] == nil then
			table.insert(out.rejected, vname .. ": no " .. layout.variants[vname].prefix .. "* parts")
		else
			local pen, why = loadImportedVariant(layout, vname, byVariant[vname], path)
			if pen then
				table.insert(out.variants, pen)
			else
				table.insert(out.rejected, vname .. ": " .. why)
			end
		end
	end
	if #out.variants == 0 then
		return nil, table.concat(out.rejected, "; ")
	end
	return out
end

-- Every imported theme of IMPORTED_PENS: { [key] = { key, name, layout, variants = { pen, ... } } }.
function Step.loadImportedPens()
	local out = {}
	local keys = {}
	for key, on in pairs(Step.IMPORTED_PENS) do
		if on then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	for _, key in ipairs(keys) do
		local layout, _, legacy = Step.findLayout(Step.IMPORTS_ROOT, key)
		if layout then
			local theme, why, stale = Step.loadImportedTheme(key, layout)
			if theme then
				out[key] = theme
				local names = {}
				for _, pen in ipairs(theme.variants) do
					table.insert(names, string.format("%s (%d parts, import x%.3f)", pen.variant, #pen.parts, pen.scale))
				end
				log("%s: imported %s ready: %s; geometry %s", key, layout.name, table.concat(names, ", "), tostring(theme.geometry))
				for _, reason in ipairs(theme.rejected) do
					log("!! %s: imported %s variant rejected: %s", key, layout.name, reason)
				end
				for _, pen in ipairs(theme.variants) do
					if #pen.windows > 0 or #pen.windowSkipped > 0 then
						log("%s%s: %s %d window pane slot(s)%s", if #pen.windowSkipped > 0 then "!! " else "", key, pen.variant, #pen.windows,
							if #pen.windowSkipped > 0 then " (skipped: " .. table.concat(pen.windowSkipped, "; ", 1, math.min(#pen.windowSkipped, 4)) .. ")" else "")
					end
				end
				if theme.ignored > 0 then
					log("%s: %d part(s) of %s match no variant / role (ignored)", key, theme.ignored, tostring(layout.import))
				end
			elseif stale then
				log("!! %s: imported %s ignored (%s); the procedural theme stays", key, layout.name, why)
			elseif string.find(why, "^not imported yet") then
				log("%s: %s %s, the procedural theme stays", key, layout.name, why)
			else
				log("!! %s: imported %s rejected: %s", key, layout.name, why)
			end
		elseif legacy then
			log("%s: %s is a legacy layout (made before the 2026-09-24 art direction), ignored until themes/%s.py is rebuilt"
				.. " on the v3 API", key, legacy, string.lower(key))
		end
	end
	return out
end

-- The imported pen (Model ThemeImportedPen) re-placed in `frame` (a plot's pen frame), restyled from the layout palette
-- (never Neon, no lights: section 5).
function Step.placeImportedPen(pen, frame)
	local model = Instance.new("Model")
	model.Name = Step.PREFIX .. "ImportedPen"
	model:SetAttribute("ImportedPen", pen.name)
	model:SetAttribute("ImportedVariant", pen.variant)
	local anchor
	for _, entry in ipairs(pen.parts) do
		local src = entry.part
		local part = src:Clone() -- a lone MeshPart: no joints to break
		for _, child in ipairs(part:GetChildren()) do
			child:Destroy() -- importer extras (SurfaceAppearance, attachments, welds): the palette below is the look
		end
		local rel = pen.frame:ToObjectSpace(src.CFrame)
		local rotation = CFrame.fromMatrix(Vector3.new(), rel.RightVector, rel.UpVector, -rel.LookVector)
		part.CFrame = frame * CFrame.new(rel.Position * pen.scale) * rotation
		part.Size = src.Size * pen.scale
		local look = pen.palette[entry.role]
		if look then
			part.Color = rgb(look.rgb[1], look.rgb[2], look.rgb[3])
			-- never Neon in a base (section 5): an older palette's Neon accent becomes SmoothPlastic
			part.Material = material(Step.BANNED_MATERIALS[look.material] or look.material)
			part.Transparency = look.transparency or 0
			part.Reflectance = look.reflectance or 0
			part.CastShadow = (look.transparency or 0) < 0.5
		elseif part.Material == Enum.Material.Neon then
			part.Material = Enum.Material.SmoothPlastic
		end
		part.MaterialVariant = ""
		if part:IsA("MeshPart") then
			part.TextureContent = roblox.Content.none
		end
		part.Name = Step.PREFIX .. entry.role
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Parent = model
		if anchor == nil or entry.role == (pen.anchors and pen.anchors.floor or "Floor_Base") then
			anchor = part
		end
	end
	-- (a layout's "lights" made PointLights on the floor part until 2026-09-25: no lights in the bases any more, an
	-- older layout's lights are ignored)
	-- These material groups remain separate in FBX so the ship, sails and flag can move
	-- together on the client. An attachment preserves the origin through clones / PivotTo.
	if pen.name == "SunnyPirateWharf" and anchor then
		local sunnyOrigin = frame * CFrame.new(0, 8.30, -pen.layout.half_depth - 0.88)
		local animated = 0
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") then
				local group = string.match(part.Name, "_Sunny(%a+)_")
				if group == "Hull" or group == "Main" or group == "Aft" or group == "Flag" then
					part:SetAttribute("SunnyGroup", group)
					part:SetAttribute("SunnyRest", sunnyOrigin:ToObjectSpace(part.CFrame))
					if part:IsA("MeshPart") then
						part.CollisionFidelity = Enum.CollisionFidelity.Box
						part.RenderFidelity = Enum.RenderFidelity.Automatic
					end
					animated += 1
				end
			end
		end
		if animated > 0 then
			local attachment = Instance.new("Attachment")
			attachment.Name = "SunnyOrigin"
			attachment.CFrame = anchor.CFrame:ToObjectSpace(sunnyOrigin)
			attachment.Parent = anchor
			model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
			model:SetAttribute("SunnyWindEnabled", true)
			model:SetAttribute("SunnyWindStrength", 1)
			model:AddTag("SunnyWindRig")
		end
	end
	model.WorldPivotData = frame
	return model
end

-- Why the imported variant does not fit this plot (nil = it fits): the pen's size and the upgrade sign's spot, then
-- every modelled piece inside the plot zone and against the plot's obstacles with no margin (the terminal wraps the
-- PlotUpgrade sign by design). `plot` nil = the canonical preview.
function Step.importedPenIssue(pen, plot, geo, obstacles)
	if math.abs(pen.layout.footprint[2] - 2 * geo.D) > 0.5 or math.abs(pen.layout.footprint[1] - 2 * geo.W) > 0.5 then
		return "pen size"
	end
	-- the modelled gate pylons stand on the StarterPen gate posts: the plot's gate must be where the pen models it
	local gateHalf = pen.contract and pen.contract.gate_half or 5.25
	if math.abs(geo.gv) > Step.IMPORT_SIGN_TOLERANCE or math.abs(geo.g - gateHalf) > Step.IMPORT_SIGN_TOLERANCE then
		return string.format("the gate opening is at v %.2f, half width %.2f (the pen models v 0, half width %.2f)", geo.gv, geo.g, gateHalf)
	end
	if plot then
		local upgrade = plot:FindFirstChild("PlotUpgrade")
		local sign = upgrade and upgrade:FindFirstChild("Sign")
		if sign == nil or not sign:IsA("BasePart") then
			return "no PlotUpgrade.Sign"
		end
		local p = geo.frame:PointToObjectSpace(sign.CFrame.Position)
		local contract = pen.contract and pen.contract.sign or { v = { 7.51, 13.36 }, u_from_front = { 0.86, 2.10 } }
		local ev, eu = (contract.v[1] + contract.v[2]) / 2, geo.D + (contract.u_from_front[1] + contract.u_from_front[2]) / 2
		if math.abs(p.X - ev) > Step.IMPORT_SIGN_TOLERANCE or math.abs(-p.Z - eu) > Step.IMPORT_SIGN_TOLERANCE then
			return string.format("the PlotUpgrade sign is at v %.2f u %.2f (the terminal wraps v %.2f u %.2f)", p.X, -p.Z, ev, eu)
		end
	end
	local D, W, eps = geo.D, geo.W, 0.01
	local m = Vector3.new(Step.OBSTACLE_MARGIN, Step.OBSTACLE_MARGIN, Step.OBSTACLE_MARGIN)
	local exact = {}
	for _, box in ipairs(obstacles or {}) do
		table.insert(exact, { box[1] + m, box[2] - m, box[3] })
	end
	local L = Step.LANDMARK
	-- every modelled piece, then every window pane (section 8), with the same rules
	local checked = table.clone(pen.pieces or {})
	for _, box in ipairs(pen.windowPieces or {}) do
		table.insert(checked, box)
	end
	for _, piece in ipairs(checked) do
		local v0, u0, h0, v1, u1, h1 = piece[1], piece[2], piece[3], piece[4], piece[5], piece[6]
		if piece[8] == "landmark" then
			-- section 7: a landmark piece stays in the landmark zone behind the back fence (Lake / Desert / Jungle only)
			if not Step.LANDMARK_KEYS[pen.key] then
				return string.format("%s piece is a landmark, but %s keeps its plot open (no landmark)", piece[7], tostring(pen.key))
			end
			if u1 > -D - L.near + eps or u0 < -D - L.back - eps or v1 > W + L.side + eps or v0 < -W - L.side - eps
				or h1 > L.top + eps or h0 < -0.05 then
				return string.format("%s landmark piece v %.2f..%.2f u %.2f..%.2f h %.2f..%.2f leaves the landmark zone", piece[7], v0, v1,
					u0, u1, h0, h1)
			end
		elseif u1 > D + Step.FRONT_MAX + eps or u0 < -D - Step.BACK_MAX - eps or v1 > W + Step.SIDE_MAX + eps
			or v0 < -W - Step.SIDE_MAX - eps or h1 > Step.TOP_MAX + eps then
			return string.format("%s piece v %.2f..%.2f u %.2f..%.2f h %.2f..%.2f leaves the plot zone", piece[7], v0, v1, u0, u1, h0, h1)
		end
		if #exact > 0 then
			local mn = Vector3.new(math.huge, math.huge, math.huge)
			local mx = Vector3.new(-math.huge, -math.huge, -math.huge)
			for _, v in ipairs({ v0, v1 }) do
				for _, u in ipairs({ u0, u1 }) do
					for _, h in ipairs({ h0, h1 }) do
						local w = geo.frame * Vector3.new(v, h, -u)
						mn, mx = mn:Min(w), mx:Max(w)
					end
				end
			end
			for _, box in ipairs(exact) do
				if boxesOverlap(mn, mx, box[1], box[2]) then
					return string.format("%s piece touches %s", piece[7], box[3])
				end
			end
		end
	end
	return nil
end

-- Swaps the procedural groups of a theme model (all but the IMPORT_KEEP prefixes and `extraKeep`) for the imported pen.
function Step.useImportedPen(model, pen, frame, extraKeep)
	local keep = table.clone(Step.IMPORT_KEEP)
	for _, prefix in ipairs(extraKeep or {}) do
		table.insert(keep, prefix)
	end
	for _, group in ipairs(model:GetChildren()) do
		local kept = false
		for _, prefix in ipairs(keep) do
			if string.sub(group.Name, 1, #prefix) == prefix then
				kept = true
			end
		end
		if not kept then
			group:Destroy()
		end
	end
	Step.placeImportedPen(pen, frame).Parent = model
	-- section 8: the building windows' panes, next to the pen (never inside ThemeImportedPen)
	local panes = Step.placeWindowPanes(pen, frame)
	if panes then
		panes.Parent = model
	end
	model:SetAttribute("WindowPanes", if panes then #panes:GetChildren() else nil)
	model:SetAttribute("HidesPenFence", true)
	model:SetAttribute("ImportedPen", pen.name)
	model:SetAttribute("ImportedVariant", pen.variant)
end

-- Applies an imported theme to one plot's model (`plot` nil = the Index preview): the first variant that fits.
-- Returns the variant name ("Std" / "Deep") or nil, why.
function Step.applyImportedTheme(imported, model, plot, geo, obstacles, extraKeep)
	local chosen, reasons = nil, {}
	for _, pen in ipairs(imported.variants) do
		local why = Step.importedPenIssue(pen, plot, geo, obstacles)
		if why == nil then
			chosen = pen
			break
		end
		table.insert(reasons, pen.variant .. ": " .. why)
	end
	if chosen == nil then
		return nil, table.concat(reasons, "; ")
	end
	Step.useImportedPen(model, chosen, geo.frame, extraKeep)
	return chosen.variant
end

---------------------------------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------------------------------

function Step.loadDirectory()
	local source = fs.readFile(Step.DIRECTORY_SOURCE)
	local chunk = luau.load(source, { debugName = Step.DIRECTORY_SOURCE, environment = { Color3 = Color3 } })
	local directory = chunk()
	assert(type(directory) == "table" and type(directory.Order) == "table" and type(directory.Themes) == "table",
		Step.DIRECTORY_SOURCE .. " did not return the theme directory")
	return directory
end

local function freshFolder(parent, name)
	local existing = parent:FindFirstChild(name)
	while existing do
		existing:Destroy()
		existing = parent:FindFirstChild(name)
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function countParts(root)
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

-- Section 5: fails the build when a base part is Neon or a base holds a light. roots = { { instance, label }, ... }.
function Step.assertNoNeon(roots)
	local neon, lights, parts = {}, {}, 0
	for _, entry in ipairs(roots) do
		local root, label = entry[1], entry[2]
		for _, d in ipairs(root and root:GetDescendants() or {}) do
			if d:IsA("BasePart") then
				parts += 1
				if d.Material == Enum.Material.Neon then
					table.insert(neon, label .. ":" .. d:GetFullName())
				end
			elseif d:IsA("Light") then
				table.insert(lights, label .. ":" .. d:GetFullName())
			end
		end
	end
	if #neon > 0 or #lights > 0 then
		error(string.format("[base_themes] NO NEON / NO LIGHTS in the bases (owner 2026-09-25): %d Neon part(s) (%s), %d light(s) (%s)",
			#neon, table.concat(neon, ", ", 1, math.min(#neon, 6)), #lights, table.concat(lights, ", ", 1, math.min(#lights, 6))))
	end
	return parts
end

function Step.Apply(place, _spPlace, ctx)
	local ws = place:GetService("Workspace")
	local rs = place:GetService("ReplicatedStorage")
	local serverStorage = place:GetService("ServerStorage")
	local groundY = (ctx and ctx.groundY) or 2.05
	local plots = ws:FindFirstChild("Plots")
	assert(plots, "Workspace.Plots missing")
	local directory = Step.loadDirectory()

	-- 3. the equip remote (IndexService answers it; the Index page invokes it through Library.Client.Network)
	local network = rs:FindFirstChild("Network")
	if not network then
		network = Instance.new("Folder")
		network.Name = "Network"
		network.Parent = rs
	end
	local remote = network:FindFirstChild(Step.REMOTE)
	if remote and not remote:IsA("RemoteFunction") then
		remote:Destroy()
		remote = nil
	end
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = Step.REMOTE
		remote.Parent = network
	end

	-- measure every plot once, and collect what the props must not touch
	local plotGeo, plotList = {}, {}
	for _, plot in ipairs(plots:GetChildren()) do
		if plot:IsA("Model") and tonumber(plot.Name) then
			local geo = Step.measurePen(plot, groundY)
			if geo then
				plotGeo[plot] = geo
				table.insert(plotList, plot)
			else
				log("!! plot %s: no StarterPen posts / GridCenter, no themes for it", plot.Name)
			end
		end
	end
	table.sort(plotList, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)
	local world = worldObstacles(ws, plots)
	local plotObstacles = {}
	for _, plot in ipairs(plotList) do
		local zMin, zMax = Step.plotZone(plotGeo[plot]) -- the pen zone + the landmark zone behind it
		plotObstacles[plot] = obstaclesFor(plots, plot, zMin, zMax, world)
	end

	-- 4. Blender-modelled pens (used per plot where they fit, see Step.IMPORTED_PENS)
	local importedPens = Step.loadImportedPens()
	local importedUse, windowUse = {}, {}

	-- 1. per-plot props
	local serverFolder = freshFolder(serverStorage, Step.SERVER_FOLDER)
	local totalParts, totalDropped = 0, 0
	local summary = {}
	for _, key in ipairs(directory.Order) do
		local theme = directory.Themes[key]
		local build = Themes[key]
		assert(theme and build, "no theme builder for " .. tostring(key))
		local themeFolder = Instance.new("Folder")
		themeFolder.Name = key
		themeFolder:SetAttribute("ThemeName", theme.Name)
		themeFolder.Parent = serverFolder
		local counts = {}
		for _, plot in ipairs(plotList) do
			local geo = plotGeo[plot]
			local model = Instance.new("Model")
			model.Name = plot.Name
			model.WorldPivotData = geo.frame
			model:SetAttribute("BaseTheme", key)
			model:SetAttribute("PenDepth", 2 * geo.D)
			model:SetAttribute("PenWidth", 2 * geo.W)
			model.Parent = themeFolder
			local B = newBuilder(geo.frame, model)
			build(B, geo, theme.Palette)
			local dropped, droppedNames = enforceClearance(model, geo, plotObstacles[plot])
			if #dropped > 0 then
				local slim = 0
				for _, name in ipairs(droppedNames) do
					if string.find(name, "^" .. Step.PREFIX .. "Corner") then
						slimCorner(B, geo, name, theme)
						slim += 1
					end
				end
				local droppedAgain = enforceClearance(model, geo, plotObstacles[plot])
				for _, entry in ipairs(droppedAgain) do
					table.insert(dropped, entry)
				end
				-- a corner swapped for its slim finial is expected (plot 6 by the money leaderboard); anything else is not
				log("%s%s on plot %s: %d group(s) did not fit (%d corner(s) became a slim finial): %s",
					if slim == #dropped then "" else "!! ", key, plot.Name, #dropped, slim, table.concat(dropped, ", ", 1, math.min(#dropped, 8)))
			end
			local imported = importedPens[key]
			if imported then
				local used, why = Step.applyImportedTheme(imported, model, plot, geo, plotObstacles[plot])
				if used then
					table.insert(importedUse, string.format("%s/%s=%s", key, plot.Name, used))
					local panes = model:GetAttribute("WindowPanes")
					if panes then
						table.insert(windowUse, string.format("%s/%s=%d", key, plot.Name, panes))
					end
				else
					log("!! %s on plot %s: no imported pen fits (%s), procedural theme kept", key, plot.Name, why)
				end
			end
			model:SetAttribute("DroppedGroups", #dropped)
			local n = countParts(model)
			totalParts += n
			totalDropped += #dropped
			table.insert(counts, string.format("%s:%d", plot.Name, n))
		end
		table.insert(summary, string.format("%s [%s]", key, table.concat(counts, " ")))
	end

	-- 2. canonical previews (standard 52.5 x 52.5 pen centred on the origin, gate toward -Z)
	local assets = rs:FindFirstChild("Assets")
	if not assets then
		assets = Instance.new("Folder")
		assets.Name = "Assets"
		assets.Parent = rs
	end
	local previewFolder = freshFolder(assets, Step.PREVIEW_FOLDER)
	local previewGeo = { frame = CFrame.new(), D = 26.25, W = 26.25, g = 5.25, gv = 0 }
	local previewParts = 0
	for _, key in ipairs(directory.Order) do
		local theme = directory.Themes[key]
		local model = Instance.new("Model")
		model.Name = key
		model.WorldPivotData = CFrame.new()
		model:SetAttribute("ThemeName", theme.Name)
		model.Parent = previewFolder
		local B = newBuilder(previewGeo.frame, model)
		buildPreviewFence(B, previewGeo, theme)
		Themes[key](B, previewGeo, theme.Palette)
		local imported = importedPens[key]
		if imported then
			-- the imported pen replaces the preview fence and the pen props; the preview's grass ground stays
			if Step.applyImportedTheme(imported, model, nil, previewGeo, nil, { Step.PREFIX .. "PreviewFence" }) then
				local fence = model:FindFirstChild(Step.PREFIX .. "PreviewFence")
				for _, d in ipairs(fence and fence:GetChildren() or {}) do
					if d.Name ~= Step.PREFIX .. "PreviewGround" then
						d:Destroy()
					end
				end
			end
		end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CastShadow = false
			end
		end
		previewParts += countParts(model)
	end

	-- section 5: the build fails if anything in a base is Neon or holds a light
	local checked = Step.assertNoNeon({ { serverFolder, "ServerStorage" }, { previewFolder, "Preview" } })
	log("built %d themes x %d plots = %d props (%d group(s) dropped by the clearance check): %s", #directory.Order,
		#plotList, totalParts, totalDropped, table.concat(summary, "; "))
	log("no-neon guard: %d base parts, 0 Neon, 0 lights (owner 2026-09-25)", checked)
	log("previews in ReplicatedStorage.Assets.%s (%d parts); remote Network[%q] ready", Step.PREVIEW_FOLDER, previewParts, Step.REMOTE)
	if #importedUse > 0 then
		log("imported pens in use: %s", table.concat(importedUse, " "))
	end
	if #windowUse > 0 then
		log("window panes (section 8, lit; BaseWindowLights flickers them): %s", table.concat(windowUse, " "))
	end
end

return Step
