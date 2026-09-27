-- scripts/steps/env_b.luau
-- Build step (ENV-B; owner SCRATCH in the visual pass): the themed environments of game-plan stages 4-6 and their slow
-- hazards, each stage's villain post and egg ring (docs/VISUAL_PASS_PLAN.md D9), plus the closed world boundary after
-- stage 6 (contract: docs/STAGES_PLAN.md §3 and §4b).
--
--   Stage 4  My Hero Academia  zone key Jungle   X  526 -  762  U.A. High grounds: gym, main hall with the glass towers,
--                                                                dorm, suburban row, sports field + grandstand, USJ ruins
--   Stage 5  Dragon Ball       zone key Snow     X  762 - 1086  Namek: Capsule Corp domes, tournament ring, Namekian
--                                                                village, two-tier mesa, canyon pool, lake, Frieza's ship
--   Stage 6  One Piece         zone key Volcano  X 1086 - 1471  pirate port: piers, rock islet, docked pirate ship, harbour
--                                                                town, lookout, lighthouse, Marine fortress
--   EndWall                                      X 1472 - 1475  "Red Line" cliff wall over Z -90..90 + invisible side walls
--                                                                Z 85..87 / -89..-87 over X 526-1475 (A5, flush with ENV-A)
--
-- Output (all under Workspace.StageEnvironments, a folder shared with ENV-A; only this step's children are rebuilt):
--   <Key> (Model)                  one per stage: themed parts in section folders (archived to
--                                  ReplicatedStorage.Archived_ProceduralEnvironments.<Key> by the D8 post step
--                                  scripts/steps/post_scratch_layout.luau; the ring below stays in the Workspace)
--     VillainPost                  invisible marker on the floor, middle of the stage X range, |Z| = 40 (stages 4 and 6
--                                  on -Z, stage 5 on +Z), facing -X toward the hub (D9)
--     EggSpots.EggSpot_<n>         invisible 1x1x1 floor markers in a horseshoe 12-28 studs around the post, opening
--                                  toward the main street; attrs Hidden/Elevation/Label/RingRadius/RingAngle (D9)
--     EggCover                     one low Slate cover rock per hidden spot, between the egg and the villain (D9)
--   EndWall (Model)                Red Line wall + SideWallNorth/SideWallSouth (stays in the Workspace)
-- The ring is placed and validated by post_scratch_layout's BuildRing / ValidateRing (shared with ENV-A).
-- It also recolours Workspace.Ground.ZoneFloor_<Key> of its three stages (colour only; the floor stays visual-only).
--
-- Layout rules this file is written against (verify with a probe on the built place after any edit):
--   * main street |Z| <= 15: nothing collidable (A6); stage-entrance gate area X [start, start+14] and the last 6 studs
--     of each stage keep |Z| <= 32 free of collidables for the STAGES gates;
--   * the themed buildings keep their no-jump routes: ramps at RAMP_DEG (<= 35), no riser above 1 stud, >= 8-stud-wide
--     routes with >= 12 studs of headroom (Kaido);
--   * D9 ring: see post_scratch_layout.luau (spots 12-28 studs from the post, |Z| 16..72, >= 3 apart, >= 50% hidden,
--     rocks <= 3.5 studs off the villain's 20x20 pad). The ring may overlap buildings: those are archived by D8;
--   * water = flat visual plane <= groundY + 0.05; slow hazards = invisible volumes tagged StageHazard="Slow" + Factor
--     (A8), CanCollide/CanQuery false, CanTouch true, at |Z| > 15;
--   * <= 450 parts per stage, Anchored, Plastic/SmoothPlastic/Neon/Glass/Wood/Metal/Slate only, no scripts, sounds,
--     meshes, decals or textures; decorative parts CanCollide/CanQuery false; no limb-like part names (A10).
--
-- Idempotent: the three stage models and EndWall are destroyed and rebuilt on every run.

local roblox = require("@lune/roblox")
local ScratchLayout = require("./post_scratch_layout")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local M = Enum.Material
local SP, NEON, GLASS, METAL, WOOD, SLATE = M.SmoothPlastic, M.Neon, M.Glass, M.Metal, M.Wood, M.Slate
local rgb = Color3.fromRGB

local Step = {}

Step.FOLDER_NAME = "StageEnvironments"
Step.END_WALL_NAME = "EndWall"
Step.MAX_PARTS_PER_STAGE = 450
Step.RAMP_DEG = 29.5
Step.STREET_CLEAR_Z = 15
Step.WATER_TOP = 0.045 -- above groundY; the zone floors sit at +0.026
Step.HAZARD_TOP = 0.9 -- slow volumes reach a grounded player's legs but not anyone standing on a 1-stud island/pier

Step.STAGES = {
	{ Key = "Jungle", Number = 4, DisplayName = "My Hero Academia", XMin = 526, XMax = 762, EggSpots = 12, Floor = rgb(112, 178, 84) },
	{ Key = "Snow", Number = 5, DisplayName = "Dragon Ball", XMin = 762, XMax = 1086, EggSpots = 12, Floor = rgb(96, 186, 138) },
	{ Key = "Volcano", Number = 6, DisplayName = "One Piece", XMin = 1086, XMax = 1471, EggSpots = 14, Floor = rgb(236, 210, 152) },
}
Step.END_WALL = { XMin = 1472, XMax = 1475, ZMin = -90, ZMax = 90, Height = 60 }
Step.SIDE_WALLS = { XMin = 526, XMax = 1475, North = 85, South = -87, Thickness = 2, Height = 40 }

local LOG_PREFIX = "[StealaHero Build][env_b]"
local RUN_PER_RISE = 1 / math.tan(math.rad(Step.RAMP_DEG))

--------------------------------------------------------------------------------------------------------------------
-- Part builder. Coordinates are world X/Z; heights are studs above the floor (groundY).
--------------------------------------------------------------------------------------------------------------------

local Builder = {}
Builder.__index = Builder

local function newBuilder(model, groundY)
	return setmetatable({ model = model, G = groundY, folder = model, parts = 0, hazards = 0 }, Builder)
end

function Builder:group(name)
	local folder = self.model:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = self.model
	end
	self.folder = folder
	return folder
end

-- kind "solid" = collidable + queryable (structures, walkable floors, ramps); anything else = visual only.
function Builder:part(name, size, cf, color, material, kind, opts)
	opts = opts or {}
	local p = Instance.new("Part")
	if opts.shape == "Ball" then
		p.Shape = Enum.PartType.Ball
	elseif opts.shape == "Cylinder" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.Locked = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local solid = kind == "solid"
	p.CanCollide = solid
	p.CanQuery = solid
	p.CanTouch = false
	p.CastShadow = opts.shadow ~= false
	if opts.transparency then
		p.Transparency = opts.transparency
	end
	if opts.reflectance then
		p.Reflectance = opts.reflectance
	end
	p.Parent = self.folder
	self.parts += 1
	return p
end

function Builder:box(name, x0, x1, z0, z1, y0, y1, color, material, kind, opts)
	return self:part(name, Vector3.new(x1 - x0, y1 - y0, z1 - z0), CFrame.new((x0 + x1) / 2, self.G + (y0 + y1) / 2, (z0 + z1) / 2), color, material, kind, opts)
end

-- floor decal: flat visual slab with its top `top` studs over the floor
function Builder:flat(name, x0, x1, z0, z1, top, color, material)
	return self:box(name, x0, x1, z0, z1, top - 0.2, top, color, material or SP, "deco", { shadow = false })
end

-- block centred on (cx, cz), yawed around Y
function Builder:block(name, cx, cz, sx, sz, y0, y1, yaw, color, material, kind, opts)
	return self:part(name, Vector3.new(sx, y1 - y0, sz), CFrame.new(cx, self.G + (y0 + y1) / 2, cz) * CFrame.Angles(0, yaw or 0, 0), color, material, kind, opts)
end

-- vertical cylinder (a Part cylinder's axis is its local X; rotate it onto world Y)
function Builder:cyl(name, cx, cz, d, y0, y1, color, material, kind, opts)
	opts = opts or {}
	opts.shape = "Cylinder"
	return self:part(name, Vector3.new(y1 - y0, d, d), CFrame.new(cx, self.G + (y0 + y1) / 2, cz) * CFrame.Angles(0, 0, math.pi / 2), color, material, kind, opts)
end

function Builder:disc(name, cx, cz, d, top, color, material)
	return self:cyl(name, cx, cz, d, top - 0.2, top, color, material or SP, "deco", { shadow = false })
end

function Builder:ball(name, cx, cy, cz, d, color, material, kind, opts)
	opts = opts or {}
	opts.shape = "Ball"
	return self:part(name, Vector3.new(d, d, d), CFrame.new(cx, self.G + cy, cz), color, material, kind, opts)
end

-- Ramp whose top surface ends at (topX, topZ) at height h1 and climbs along the unit direction (dx, dz) from h0,
-- at Step.RAMP_DEG. Optional visual curbs on both edges.
function Builder:ramp(name, topX, topZ, dx, dz, h0, h1, width, color, material, curbColor)
	local rise = h1 - h0
	local run = rise * RUN_PER_RISE
	local ax, az = topX - dx * run, topZ - dz * run
	local len = math.sqrt(run * run + rise * rise)
	local f = Vector3.new(dx * run, rise, dz * run) / len
	local r = Vector3.new(-f.Z, 0, f.X).Unit
	local n = r:Cross(f)
	local back = r:Cross(n)
	local mid = Vector3.new((ax + topX) / 2, self.G + (h0 + h1) / 2, (az + topZ) / 2)
	local p = self:part(name, Vector3.new(width, 1, len), CFrame.fromMatrix(mid - n * 0.5, r, n, back), color, material, "solid")
	p:SetAttribute("RampDeg", Step.RAMP_DEG)
	if curbColor then
		for _, side in { -1, 1 } do
			local c = mid + r * (side * (width / 2 - 0.3)) + n * 0.35
			self:part(name .. "Curb", Vector3.new(0.6, 0.7, len), CFrame.fromMatrix(c, r, n, back), curbColor, SP, "deco")
		end
	end
	return p
end

-- flat visual water plane (<= groundY + 0.05, contract A6); never collidable
function Builder:water(name, x0, x1, z0, z1, color)
	return self:box(name .. "Water", x0, x1, z0, z1, Step.WATER_TOP - 0.1, Step.WATER_TOP, color, GLASS, "deco", { shadow = false, reflectance = 0.15 })
end

-- Slow hazard (A8): invisible touch volume at floor level, optionally with a water plane on top. STAGES' runtime
-- (StageHazardService) slows a player whose HumanoidRootPart is over the volume and at most 7 studs above its top, so
-- volumes must not extend under dry platforms lower than ~7 studs (piers, quays): split them around those instead.
function Builder:hazard(name, x0, x1, z0, z1, factor, waterColor)
	if waterColor then
		self:water(name, x0, x1, z0, z1, waterColor)
	end
	local v = self:box(name, x0, x1, z0, z1, -0.5, Step.HAZARD_TOP, rgb(255, 255, 255), SP, "deco", { transparency = 1, shadow = false })
	v.CanTouch = true
	v:SetAttribute("StageHazard", "Slow")
	v:SetAttribute("Factor", factor)
	self.hazards += 1
	return v
end

local function addSign(part, face, text, textColor, strokeColor)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "SignText"
	label.Size = roblox.UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = textColor
	label.TextStrokeColor3 = strokeColor
	label.TextStrokeTransparency = 0
	label.FontFace = roblox.Font.fromEnum(Enum.Font.FredokaOne)
	label.Parent = gui
end

--------------------------------------------------------------------------------------------------------------------
-- Shared props
--------------------------------------------------------------------------------------------------------------------

local function streetLamp(b, x, z, poleColor, lightColor)
	local toStreet = z > 0 and -1 or 1
	b:box("LampPole", x - 0.4, x + 0.4, z - 0.4, z + 0.4, 0, 11, poleColor, METAL, "solid")
	local z0, z1 = z, z + toStreet * 3
	b:box("LampHead", x - 0.8, x + 0.8, math.min(z0, z1), math.max(z0, z1), 10.6, 11.3, lightColor, NEON, "deco")
end

local function stackedRoof(b, name, x0, x1, z0, z1, top, color)
	b:box(name, x0 - 0.8, x1 + 0.8, z0 - 0.8, z1 + 0.8, top, top + 1, color, SP, "deco")
	b:box(name .. "Mid", x0 + 1.5, x1 - 1.5, z0 + 1.5, z1 - 1.5, top + 1, top + 2.4, color, SP, "deco")
	local zc = (z0 + z1) / 2
	b:box(name .. "Ridge", x0 + 4, x1 - 4, zc - 1.5, zc + 1.5, top + 2.4, top + 3.4, color, SP, "deco")
end

-- house with its front door facing -Z (street side for houses north of the street)
local function house(b, name, x0, x1, z0, z1, h, wall, roof, trim)
	b:box(name, x0, x1, z0, z1, 0, h, wall, SP, "solid")
	stackedRoof(b, name .. "Roof", x0, x1, z0, z1, h, roof)
	local cx = (x0 + x1) / 2
	b:box(name .. "Door", cx - 1.6, cx + 1.6, z0 - 0.25, z0 + 0.05, 0, 6, trim, WOOD, "deco")
	b:box(name .. "Windows", x0 + 1.5, x1 - 1.5, z0 - 0.25, z0 + 0.05, h * 0.62, h * 0.62 + 2, rgb(120, 186, 226), GLASS, "deco")
end

local function sakura(b, x, z, yaw)
	b:box("SakuraTrunk", x - 0.7, x + 0.7, z - 0.7, z + 0.7, 0, 6.5, rgb(112, 78, 58), WOOD, "solid")
	b:block("SakuraBlossom", x, z, 8, 8, 5.5, 10, yaw, rgb(255, 176, 206), SP, "deco")
	b:block("SakuraBlossomTop", x + 0.6, z - 0.4, 5.5, 5.5, 9.5, 12, yaw + 0.4, rgb(255, 206, 226), SP, "deco")
end

local function ajisa(b, x, z, scale)
	b:cyl("AjisaTrunk", x, z, 1.2, 0, 9 * scale, rgb(150, 122, 84), WOOD, "solid")
	b:ball("AjisaCrown", x, 10 * scale, z, 6.5 * scale, rgb(80, 150, 205), SP, "deco")
	b:ball("AjisaCrownTop", x + 0.5, 13 * scale, z - 0.4, 3.8 * scale, rgb(120, 205, 190), SP, "deco")
end

local function palm(b, x, z, yaw, baseY)
	baseY = baseY or 0
	local G = b.G
	b:box("PalmTrunk", x - 0.7, x + 0.7, z - 0.7, z + 0.7, baseY, baseY + 7, rgb(150, 110, 70), WOOD, "solid")
	local lean = CFrame.new(x, G + baseY + 7, z) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0.22, 0, 0)
	b:part("PalmTrunkTop", Vector3.new(1.1, 6, 1.1), lean * CFrame.new(0, 3, 0), rgb(160, 118, 76), WOOD, "deco")
	local crown = lean * CFrame.new(0, 6, 0)
	for i = 0, 3 do
		local leaf = CFrame.new(crown.Position) * CFrame.Angles(0, yaw + i * math.pi / 2 + 0.4, 0) * CFrame.Angles(-0.38, 0, 0) * CFrame.new(0, 0, -3.4)
		b:part("PalmLeaf", Vector3.new(2.6, 0.3, 7), leaf, i % 2 == 0 and rgb(60, 170, 80) or rgb(78, 190, 92), SP, "deco")
	end
	b:ball("PalmCoconuts", crown.Position.X, crown.Position.Y - G - 0.6, crown.Position.Z, 1.6, rgb(110, 76, 44), SP, "deco")
end

local function spire(b, name, x, z, w, y0, y1, color, capColor)
	b:block(name, x, z, w, w, y0, y1, 0.2, color, SLATE, "solid")
	b:block(name .. "Cap", x, z, w * 1.6, w * 1.6, y1, y1 + w * 0.6, 0.6, capColor, SLATE, "deco")
end

local function barrel(b, x, z, baseY)
	baseY = baseY or 0
	b:cyl("Barrel", x, z, 2.4, baseY, baseY + 3.2, rgb(126, 84, 50), WOOD, "solid")
	b:cyl("BarrelBand", x, z, 2.5, baseY + 1.3, baseY + 1.9, rgb(70, 74, 84), METAL, "deco")
end

--------------------------------------------------------------------------------------------------------------------
-- Stage 4: My Hero Academia (Jungle)
--------------------------------------------------------------------------------------------------------------------

local C4 = {
	road = rgb(208, 212, 220), navy = rgb(30, 40, 86), white = rgb(238, 240, 245), blue = rgb(56, 98, 190),
	glass = rgb(92, 156, 220), glassDark = rgb(52, 84, 130), red = rgb(214, 44, 52), gold = rgb(246, 196, 40),
	concrete = rgb(172, 175, 184), steel = rgb(120, 130, 150), wood = rgb(196, 150, 96), hedge = rgb(62, 140, 72),
	dorm = rgb(198, 164, 128), dormTrim = rgb(106, 72, 54), track = rgb(190, 82, 60), infield = rgb(98, 172, 82),
	ruin = rgb(146, 146, 150), ruinDark = rgb(104, 102, 104), rock = rgb(132, 114, 96), fence = rgb(70, 120, 92),
	houseA = rgb(236, 226, 206), houseB = rgb(214, 232, 240), houseC = rgb(246, 220, 196), roofA = rgb(70, 76, 96),
	roofB = rgb(150, 60, 50), water = rgb(64, 150, 210), mud = rgb(120, 96, 70), lamp = rgb(210, 236, 255),
}

local function buildMHA(b, stage)
	local C = C4
	local x0, x1 = stage.XMin, stage.XMax

	b:group("Street")
	b:flat("Road", x0, x1, -12, 12, 0.1, C.road)
	b:flat("RoadLineNorth", x0, x1, 11.2, 12.2, 0.15, C.navy)
	b:flat("RoadLineSouth", x0, x1, -12.2, -11.2, 0.15, C.navy)
	for i = 0, 8 do
		local x = 637 + i * 3.2
		b:flat("Crosswalk", x, x + 1.6, -10, 10, 0.15, C.white)
	end
	for _, x in { 560, 612, 690, 730 } do
		streetLamp(b, x, 16.5, C.navy, C.lamp)
	end
	for _, x in { 566, 606, 662, 735 } do
		streetLamp(b, x, -16.5, C.navy, C.lamp)
	end
	for _, t in { { 610, 21, 0.3 }, { 690, 22, 1.1 }, { 708, 26, 0.6 }, { 742, 24, 0.2 }, { 578, -22, 0.9 }, { 676, -21, 0.4 } } do
		sakura(b, t[1], t[2], t[3])
	end

	b:group("Entrance")
	b:box("BusShelterBack", 544, 558, -24.6, -24, 0.4, 7, C.glass, GLASS, "solid", { transparency = 0.35 })
	b:box("BusShelterRoof", 543.4, 558.6, -25.2, -19.6, 7, 7.6, C.navy, SP, "deco")
	b:box("BusShelterPostWest", 543.8, 544.4, -20.4, -19.8, 0, 7, C.steel, METAL, "deco")
	b:box("BusShelterPostEast", 557.6, 558.2, -20.4, -19.8, 0, 7, C.steel, METAL, "deco")
	b:box("BusBench", 546, 556, -23.8, -22.4, 0, 1.4, C.wood, WOOD, "solid")
	local board = b:box("SchoolBoard", 548, 572, 17.6, 18.1, 3.2, 9.4, C.navy, SP, "deco")
	addSign(board, Enum.NormalId.Front, "U.A. HIGH - HEROES IN TRAINING", C.white, C.red)
	b:box("SchoolBoardLegWest", 549, 550, 17.6, 18.1, 0, 3.2, C.steel, METAL, "solid")
	b:box("SchoolBoardLegEast", 570, 571, 17.6, 18.1, 0, 3.2, C.steel, METAL, "solid")

	-- Gym Gamma: open interior (12-stud door on the east side) + roof reached by a ramp along its north side
	b:group("GymGamma")
	b:box("GymWallSouth", 542, 584, 36, 37.5, 0, 13, C.white, SP, "solid")
	b:box("GymWallNorth", 542, 584, 60.5, 62, 0, 13, C.white, SP, "solid")
	b:box("GymWallWest", 542, 543.5, 37.5, 60.5, 0, 13, C.white, SP, "solid")
	b:box("GymWallEastA", 582.5, 584, 37.5, 43, 0, 13, C.white, SP, "solid")
	b:box("GymWallEastB", 582.5, 584, 55, 60.5, 0, 13, C.white, SP, "solid")
	b:box("GymDoorLintel", 582.5, 584, 43, 55, 12.5, 13, C.white, SP, "solid")
	b:box("GymRoof", 542, 584, 36, 62, 13, 14, C.blue, SP, "solid")
	b:box("GymTrimSouth", 541.7, 584.3, 35.7, 36.1, 12.4, 14.3, C.navy, SP, "deco")
	b:box("GymTrimEast", 583.9, 584.3, 35.7, 62.3, 12.4, 14.3, C.navy, SP, "deco")
	b:box("GymTrimBase", 541.7, 584.3, 35.7, 36.1, 0, 0.9, C.navy, SP, "deco")
	b:box("GymWindows", 546, 580, 35.75, 36.05, 4, 8.5, C.glass, GLASS, "deco")
	for _, x in { 554.5, 563, 571.5 } do
		b:box("GymMullion", x - 0.4, x + 0.4, 35.6, 35.9, 4, 8.5, C.white, SP, "deco")
	end
	local gymSign = b:box("GymSign", 553, 573, 35.5, 35.8, 9, 11.6, C.red, SP, "deco")
	addSign(gymSign, Enum.NormalId.Front, "GYM GAMMA", C.white, C.navy)
	b:box("GymDoorAccent", 583.9, 584.4, 42.6, 55.4, 12.1, 12.8, C.gold, SP, "deco")
	b:flat("GymFloor", 543.5, 582.5, 37.5, 60.5, 0.12, C.wood, WOOD)
	b:flat("GymMat", 562, 578, 40, 52, 0.18, C.blue)
	b:ramp("GymRoofRamp", 572, 67, 1, 0, 0, 14, 10, C.concrete, SP, C.navy)
	b:box("GymRoofLanding", 572, 582, 62, 72, 0, 14, C.concrete, SP, "solid")
	b:cyl("GymWaterTank", 576, 42, 5, 14, 19, C.navy, METAL, "solid")
	b:box("GymRoofUnit", 546, 552, 55, 59, 14, 16, C.concrete, METAL, "solid")

	-- U.A. main hall: glass towers + sky bridge silhouette, entrance terrace, gate
	b:group("UAHigh")
	b:box("UAHall", 598, 704, 50, 64, 0, 18, C.white, SP, "solid")
	b:box("UAGlassLow", 600, 702, 49.7, 50.05, 3.8, 8, C.glass, GLASS, "deco")
	b:box("UAGlassHigh", 600, 702, 49.7, 50.05, 10.5, 14.8, C.glass, GLASS, "deco")
	for _, x in { 610, 624, 638, 664, 678, 692 } do
		b:box("UAPilaster", x - 0.7, x + 0.7, 49.3, 50, 0, 18, C.white, SP, "deco")
	end
	b:box("UADoors", 642, 660, 49.6, 50.05, 3, 9.6, C.glassDark, GLASS, "deco")
	b:box("UACornice", 597.6, 704.4, 49.4, 64.4, 17.6, 18.8, C.navy, SP, "deco")
	b:box("UATowerWest", 608, 628, 52, 62, 18.8, 46, C.glass, GLASS, "deco")
	b:box("UATowerEast", 674, 694, 52, 62, 18.8, 46, C.glass, GLASS, "deco")
	b:box("UATowerWestCap", 607.4, 628.6, 51.4, 62.6, 46, 47.4, C.white, SP, "deco")
	b:box("UATowerEastCap", 673.4, 694.6, 51.4, 62.6, 46, 47.4, C.white, SP, "deco")
	b:box("UATowerWestRib", 617.3, 618.7, 51.6, 52.05, 18.8, 46, C.white, SP, "deco")
	b:box("UATowerEastRib", 683.3, 684.7, 51.6, 52.05, 18.8, 46, C.white, SP, "deco")
	b:box("UASkyBridge", 628, 674, 53.5, 60.5, 33, 42, C.glass, GLASS, "deco")
	b:box("UASkyBridgeTop", 627.6, 674.4, 53.1, 60.9, 42, 43, C.white, SP, "deco")
	b:box("UASkyBridgeBase", 627.6, 674.4, 53.1, 60.9, 32, 33, C.white, SP, "deco")
	local emblem = b:box("UAEmblem", 638, 664, 52.7, 53.1, 34, 41, C.white, SP, "deco")
	addSign(emblem, Enum.NormalId.Front, "U.A.", C.red, C.navy)
	b:box("UATerrace", 618, 684, 38, 50, 0, 3, C.concrete, SP, "solid")
	b:box("UATerraceTrim", 617.7, 684.3, 37.7, 38.1, 2.2, 3.2, C.navy, SP, "deco")
	b:ramp("UATerraceSteps", 651, 38, 0, 1, 0, 3, 36, C.concrete, SP, C.navy)
	b:box("UAPlanterWest", 621, 631, 41, 47, 3, 4.5, C.concrete, SP, "solid")
	b:box("UABushWest", 621.4, 630.6, 41.4, 46.6, 4.5, 6.6, C.hedge, SP, "deco")
	b:box("UAPlanterEast", 671, 681, 41, 47, 3, 4.5, C.concrete, SP, "solid")
	b:box("UABushEast", 671.4, 680.6, 41.4, 46.6, 4.5, 6.6, C.hedge, SP, "deco")
	b:box("UAGatePillarWest", 624, 630, 26, 30, 0, 16, C.steel, METAL, "solid")
	b:box("UAGatePillarEast", 672, 678, 26, 30, 0, 16, C.steel, METAL, "solid")
	local lintel = b:box("UAGateLintel", 623, 679, 26, 30, 16, 19.5, C.navy, SP, "deco")
	addSign(lintel, Enum.NormalId.Front, "U.A. HIGH SCHOOL", C.white, C.red)
	b:box("UAGateNeon", 623, 679, 25.6, 26, 15.4, 15.9, C.red, NEON, "deco")

	b:group("HeightsAlliance")
	b:box("Dorm", 716, 756, 50, 66, 0, 16, C.dorm, SP, "solid")
	b:box("DormWindowsLow", 718, 754, 49.7, 50.05, 4, 6.8, C.glassDark, GLASS, "deco")
	b:box("DormWindowsHigh", 718, 754, 49.7, 50.05, 9.6, 12.4, C.glassDark, GLASS, "deco")
	stackedRoof(b, "DormRoof", 716, 756, 50, 66, 16, C.dormTrim)
	b:box("DormDoor", 732, 740, 49.6, 50.05, 0, 3.6, C.dormTrim, WOOD, "deco")
	b:box("DormHedge", 720, 752, 36, 38.5, 0, 3.5, C.hedge, SP, "solid")

	-- suburban row at the south-west edge, backyards behind it
	b:group("SuburbanRow")
	house(b, "RowHouseA", 538, 554, -60, -44, 9, C.houseA, C.roofA, C.dormTrim)
	house(b, "RowHouseB", 554, 570, -60, -44, 10, C.houseB, C.roofB, C.dormTrim)
	house(b, "RowHouseC", 570, 586, -60, -44, 9, C.houseC, C.roofA, C.dormTrim)
	b:box("BackyardShed", 538, 546, -80, -74, 0, 5, C.houseB, WOOD, "solid")

	b:group("SportsField")
	b:flat("TrackStraight", 616, 656, -53, -19, 0.07, C.track)
	b:disc("TrackEndWest", 616, -36, 34, 0.07, C.track)
	b:disc("TrackEndEast", 656, -36, 34, 0.07, C.track)
	b:flat("Infield", 616, 656, -47, -25, 0.12, C.infield)
	b:disc("InfieldWest", 616, -36, 22, 0.12, C.infield)
	b:disc("InfieldEast", 656, -36, 22, 0.12, C.infield)
	for _, z in { -51, -49, -23, -21 } do
		b:flat("TrackLane", 616, 656, z - 0.15, z + 0.15, 0.12, C.white)
	end
	b:flat("TrackStartLine", 634, 634.5, -25, -19, 0.12, C.white)
	b:box("StandRow1", 600, 660, -58, -56, 0, 1.5, C.blue, SP, "solid")
	b:box("StandRow2", 600, 660, -60, -58, 0, 3, C.white, SP, "solid")
	b:box("StandRow3", 600, 660, -62, -60, 0, 4.5, C.blue, SP, "solid")
	b:box("StandDeck", 600, 660, -76, -62, 0, 6, C.concrete, SP, "solid")
	b:ramp("StandRamp", 600, -69, 1, 0, 0, 6, 10, C.concrete, SP, C.navy)
	b:box("PressBox", 614, 646, -65, -62, 6, 12, C.white, SP, "solid")
	b:box("PressBoxGlass", 616, 644, -62, -61.7, 7.8, 11, C.glass, GLASS, "deco")
	b:box("PressBoxRoof", 613.6, 646.4, -65.4, -61.4, 12, 12.8, C.navy, SP, "deco")

	-- USJ training ground: collapsed-city ruins, flood zone, landslide, control deck
	b:group("USJ")
	b:box("USJRuinWest", 680, 694, -44, -19, 0, 6, C.ruin, SP, "solid")
	b:box("USJRuinEast", 704, 718, -44, -30, 0, 10, C.ruin, SP, "solid")
	b:box("USJFallenSlab", 694, 718, -21, -19, 0, 5, C.ruinDark, SP, "solid")
	b:box("USJRuinWestCrack", 679.7, 694.3, -44.3, -18.7, 5, 6.2, C.ruinDark, SP, "deco")
	b:box("USJRuinEastCrack", 703.7, 718.3, -44.3, -29.7, 8.6, 10.2, C.ruinDark, SP, "deco")
	b:box("USJRuinTower", 684, 704, -76, -56, 0, 8, C.ruinDark, SP, "solid")
	b:ramp("USJRuinRamp", 704, -66, -1, 0, 0, 8, 10, C.concrete, SP, C.navy)
	b:box("USJBrokenWall", 684, 696, -62, -60, 8, 11.5, C.ruin, SP, "solid")
	b:block("USJRockA", 732, -32, 12, 10, 0, 9, 0.25, C.rock, SLATE, "solid")
	b:block("USJRockB", 741, -30, 9, 8, 0, 7, -0.35, C.rock, SLATE, "solid")
	b:block("USJRockC", 725, -37, 8, 7, 0, 5, 0.6, C.rock, SLATE, "solid")
	b:block("USJRockD", 740, -39, 7, 6, 0, 4, 0.1, C.rock, SLATE, "solid")
	b:box("USJControlDeck", 724, 758, -76, -56, 0, 10, C.concrete, SP, "solid")
	b:ramp("USJDeckRamp", 752, -56, 0, -1, 0, 10, 10, C.concrete, SP, C.navy)
	b:box("USJBooth", 726, 746, -61, -58, 10, 15, C.white, SP, "solid")
	b:box("USJBoothGlass", 728, 744, -58, -57.7, 11.5, 14, C.glass, GLASS, "deco")
	b:box("USJBoothRoof", 725.6, 746.4, -61.4, -57.6, 15, 15.8, C.navy, SP, "deco")
	local usj = b:box("USJSign", 730, 742, -57.9, -57.6, 15.8, 18.4, C.navy, SP, "deco")
	addSign(usj, Enum.NormalId.Back, "U.S.J.", C.gold, C.navy)
	b:hazard("USJFloodZone", 682, 722, -54, -46, 0.7, C.water)
	b:hazard("USJMudslide", 722, 746, -54, -45, 0.75, C.mud)

	b:group("Perimeter")
	b:box("SchoolFenceNorth", x0, x1, 80.2, 80.8, 0, 6, C.fence, METAL, "solid", { transparency = 0.35 })
	b:box("SchoolFenceNorthRail", x0, x1, 80.05, 80.95, 6, 6.6, C.navy, SP, "deco")
	b:box("SchoolFenceSouth", x0, x1, -84.8, -84.2, 0, 6, C.fence, METAL, "solid", { transparency = 0.35 })
	b:box("SchoolFenceSouthRail", x0, x1, -84.95, -84.05, 6, 6.6, C.navy, SP, "deco")
end

--------------------------------------------------------------------------------------------------------------------
-- Stage 5: Dragon Ball (Snow)
--------------------------------------------------------------------------------------------------------------------

local C5 = {
	path = rgb(214, 204, 152), pathEdge = rgb(170, 150, 100), rock = rgb(206, 196, 164), rockDark = rgb(158, 146, 118),
	rockTeal = rgb(120, 150, 138), white = rgb(246, 246, 242), ccBlue = rgb(40, 112, 204), metal = rgb(150, 160, 175),
	tile = rgb(228, 224, 210), tileLine = rgb(170, 164, 150), skirt = rgb(150, 144, 130), templeRed = rgb(196, 58, 44),
	roof = rgb(236, 128, 40), gold = rgb(250, 202, 56), pillar = rgb(206, 44, 40), water = rgb(70, 196, 170),
	house = rgb(236, 240, 226), window = rgb(40, 60, 70), band = rgb(70, 150, 110), dragonBall = rgb(255, 150, 30),
	ship = rgb(214, 214, 224), shipDark = rgb(120, 120, 140), shipNeon = rgb(170, 90, 255), pod = rgb(226, 226, 232),
	podWindow = rgb(200, 30, 50), crater = rgb(110, 110, 96),
}

local function buildDragonBall(b, stage)
	local C = C5
	local x0, x1 = stage.XMin, stage.XMax
	local G = b.G

	b:group("Path")
	b:flat("SandPath", x0, x1, -12, 12, 0.1, C.path)
	b:flat("PathEdgeNorth", x0, x1, 11.2, 12.4, 0.15, C.pathEdge)
	b:flat("PathEdgeSouth", x0, x1, -12.4, -11.2, 0.15, C.pathEdge)
	for _, t in { { 788, 20, 1 }, { 846, 24, 0.9 }, { 962, 22, 1.1 }, { 1020, 26, 1 }, { 1062, 24, 0.9 }, { 796, -22, 1 }, { 904, -18, 1.1 }, { 1012, -46, 1 }, { 1076, -42, 0.9 } } do
		ajisa(b, t[1], t[2], t[3])
	end

	b:group("CapsuleCorp")
	b:ball("CCFrontDome", 806, 0, 34, 16, C.white, SP, "solid")
	b:cyl("CCFrontDomeStripe", 806, 34, 16.4, 2.2, 3.4, C.ccBlue, SP, "deco")
	b:cyl("CCTower", 792, 58, 10, 0, 22, C.white, SP, "solid")
	b:cyl("CCTowerBand", 792, 58, 10.5, 16, 17.6, C.ccBlue, SP, "deco")
	b:cyl("CCTowerWindows", 792, 58, 10.3, 8, 10, C.window, GLASS, "deco")
	b:ball("CCTowerTop", 792, 22, 58, 10, C.white, SP, "deco")
	b:ball("CCMainDome", 822, 0, 56, 28, C.white, SP, "solid")
	b:cyl("CCMainDomeStripe", 822, 56, 28.6, 3, 4.4, C.ccBlue, SP, "deco")
	b:cyl("CCMainDomeCap", 822, 56, 7, 13.4, 14.6, C.ccBlue, SP, "deco")
	b:box("CCMainDoor", 818, 826, 41.4, 43.4, 0, 5, C.ccBlue, SP, "deco")
	b:box("CCHangar", 836, 866, 44, 68, 0, 8, C.white, SP, "solid")
	b:box("CCHangarBand", 835.7, 866.3, 43.7, 68.3, 6.4, 7.4, C.ccBlue, SP, "deco")
	b:box("CCHangarDoor", 840, 852, 43.7, 44.05, 0, 5.6, C.metal, METAL, "deco")
	local parapet = b:box("CCParapet", 836, 857, 44, 45, 8, 11, C.white, SP, "solid")
	addSign(parapet, Enum.NormalId.Front, "CAPSULE CORP.", C.ccBlue, C.white)
	b:box("CCRoofUnit", 836, 840.5, 45, 51, 8, 10.5, C.metal, METAL, "solid")
	b:ramp("CCHangarRamp", 861, 44, 0, 1, 0, 8, 10, C.metal, METAL, C.ccBlue)
	b:box("CCGardenWall", 776, 814, 45, 47.5, 0, 5, C.white, SP, "solid")
	b:box("CCGardenWallTrim", 775.8, 814.2, 44.8, 47.7, 4.2, 5.2, C.ccBlue, SP, "deco")

	b:group("Tournament")
	b:box("TourneyRing", 902, 952, 28, 64, 0, 3, C.tile, SP, "solid")
	b:box("TourneyRingSkirt", 901.6, 952.4, 27.6, 64.4, 0, 2.4, C.skirt, SLATE, "deco")
	for i = 1, 4 do
		local x = 902 + i * 10
		b:box("TourneyTileLine", x - 0.1, x + 0.1, 28, 64, 2.9, 3.06, C.tileLine, SP, "deco", { shadow = false })
	end
	for i = 1, 3 do
		local z = 28 + i * 9
		b:box("TourneyTileLine", 902, 952, z - 0.1, z + 0.1, 2.9, 3.06, C.tileLine, SP, "deco", { shadow = false })
	end
	b:ramp("TourneySteps", 927, 28, 0, 1, 0, 3, 16, C.tile, SP, C.gold)
	for _, c in { { 903.5, 29.5 }, { 950.5, 29.5 }, { 903.5, 62.5 }, { 950.5, 62.5 } } do
		b:box("TourneyLanternPost", c[1] - 0.4, c[1] + 0.4, c[2] - 0.4, c[2] + 0.4, 3, 8, C.gold, METAL, "deco")
		b:ball("TourneyLantern", c[1], 8.8, c[2], 1.8, C.roof, NEON, "deco")
	end
	b:box("StandRow1", 896, 900, 30, 62, 0, 1.5, C.rockDark, SP, "solid")
	b:box("StandRow2", 892, 896, 30, 62, 0, 3, C.tile, SP, "solid")
	b:box("StandRow3", 888, 892, 30, 62, 0, 4.5, C.rockDark, SP, "solid")
	b:box("StandDeck", 870, 888, 30, 62, 0, 6, C.tile, SP, "solid")
	b:ramp("StandRamp", 879, 30, 0, 1, 0, 6, 10, C.tile, SP, C.gold)
	b:box("StandBooth", 878, 888, 44, 50, 6, 11, C.templeRed, SP, "solid")
	b:box("StandBoothRoof", 877.6, 888.4, 43.6, 50.4, 11, 11.8, C.roof, SP, "deco")
	b:box("TempleBody", 907, 947, 68, 80, 0, 10, C.templeRed, SP, "solid")
	b:box("TempleRoofLow", 904, 950, 66, 80.8, 10, 11.6, C.roof, SP, "deco")
	b:box("TempleUpper", 912, 942, 70, 79, 11.6, 15, C.templeRed, SP, "deco")
	b:box("TempleRoofHigh", 909, 945, 68.6, 80.4, 15, 16.6, C.roof, SP, "deco")
	b:box("TempleRidge", 917, 937, 72.5, 76.5, 16.6, 18, C.gold, SP, "deco")
	for _, x in { 909, 917, 937, 945 } do
		b:cyl("TemplePillar", x, 67, 1.6, 0, 10, C.pillar, SP, "solid")
	end
	local templeSign = b:box("TempleSign", 920, 934, 66.9, 67.3, 5.5, 9, C.gold, SP, "deco")
	addSign(templeSign, Enum.NormalId.Front, "WORLD TOURNAMENT", C.templeRed, C.gold)

	-- village: the hidden courtyard is closed toward the street by a rock ridge and entered from the west
	b:group("NamekVillage")
	for _, h in { { "NamekHouseA", 972, 40, 12 }, { "NamekHouseB", 1000, 44, 14 }, { "NamekHouseC", 974, 66, 10 } } do
		local name, x, z, d = h[1], h[2], h[3], h[4]
		b:ball(name, x, 0, z, d, C.house, SP, "solid")
		b:cyl(name .. "Band", x, z, d + 0.3, d * 0.18, d * 0.18 + 0.8, C.band, SP, "deco")
		b:ball(name .. "Window", x - d * 0.22, d * 0.22, z - d * 0.43, d * 0.16, C.window, GLASS, "deco")
		b:ball(name .. "Door", x + d * 0.14, d * 0.1, z - d * 0.46, d * 0.22, C.window, SP, "deco")
		b:cyl(name .. "Tube", x, z, d * 0.14, d * 0.45, d * 0.64, C.house, SP, "deco")
	end
	b:block("NamekRockA", 1012, 66, 8, 6, 0, 7, 0.4, C.rock, SLATE, "solid")
	b:box("NamekRidge", 1004, 1030, 47, 53, 0, 7, C.rockDark, SLATE, "solid")
	b:block("NamekRidgeTop", 1017, 50, 24, 5, 7, 9, 0.05, C.rockTeal, SLATE, "deco")

	b:group("NamekMesa")
	b:box("MesaLower", 1030, 1078, 38, 80, 0, 12, C.rock, SLATE, "solid")
	b:box("MesaLowerBand", 1029.7, 1078.3, 37.7, 80.3, 4, 6, C.rockDark, SLATE, "deco")
	b:ramp("MesaRamp", 1036, 38, 0, 1, 0, 12, 10, C.rockDark, SLATE, C.rockTeal)
	b:box("MesaUpper", 1056, 1078, 50, 78, 12, 18, C.rock, SLATE, "solid")
	b:box("MesaUpperBand", 1055.7, 1078.3, 49.7, 78.3, 14.5, 15.5, C.rockDark, SLATE, "deco")
	b:ramp("MesaUpperRamp", 1056, 60, 1, 0, 12, 18, 10, C.rockDark, SLATE, C.rockTeal)
	spire(b, "MesaSpireA", 1040, 72, 5, 12, 26, C.rock, C.rockTeal)
	spire(b, "MesaSpireB", 1072, 54, 4, 18, 30, C.rock, C.rockTeal)

	-- canyon cut: west mesa, cliff walls, stream + pool with a rock island (slow water)
	b:group("Canyon")
	b:box("MesaWest", 790, 836, -80, -40, 0, 12, C.rock, SLATE, "solid")
	b:box("MesaWestBand", 789.7, 836.3, -80.3, -39.7, 5, 7, C.rockDark, SLATE, "deco")
	b:ramp("MesaWestRamp", 812, -40, 0, -1, 0, 12, 10, C.rockDark, SLATE, C.rockTeal)
	spire(b, "MesaWestSpire", 826, -72, 5, 12, 28, C.rock, C.rockTeal)
	b:box("CliffEast", 846, 900, -56, -22, 0, 18, C.rock, SLATE, "solid")
	b:box("CliffEastBand", 845.7, 900.3, -56.3, -21.7, 8, 10, C.rockDark, SLATE, "deco")
	b:box("CliffSouth", 870, 906, -80, -56, 0, 16, C.rockDark, SLATE, "solid")
	b:box("CliffSouthBand", 869.7, 906.3, -80.3, -55.7, 6, 7.5, C.rock, SLATE, "deco")
	b:box("RockArchFoot", 828, 834, -48, -42, 12, 20, C.rock, SLATE, "solid")
	b:box("RockArchSpan", 828, 852, -48, -42, 20, 23.5, C.rock, SLATE, "deco")
	b:hazard("CanyonStream", 836, 846, -56, -22, 0.6, C.water)
	b:hazard("CanyonPool", 836, 870, -80, -56, 0.6, C.water)
	b:box("CanyonIsland", 850, 864, -72, -62, 0, 1, C.rockTeal, SLATE, "solid")
	b:ramp("CanyonIslandRamp", 857, -62, 0, -1, 0, 1, 10, C.rockTeal, SLATE)
	b:block("CanyonRock", 842, -76, 4, 4, 0, 3, 0.3, C.rockDark, SLATE, "solid")

	b:group("NamekLake")
	b:hazard("NamekLake", 910, 1000, -72, -32, 0.55, C.water)
	spire(b, "LakeSpireA", 922, -46, 6, 0, 16, C.rock, C.rockTeal)
	spire(b, "LakeSpireB", 930, -64, 5, 0, 20, C.rock, C.rockTeal)
	spire(b, "LakeSpireC", 966, -36, 5, 0, 14, C.rock, C.rockTeal)
	b:box("LakeRockWall", 940, 962, -50, -44, 0, 14, C.rock, SLATE, "solid")
	b:block("LakeRockWallTop", 951, -47, 26, 9, 14, 17, 0.08, C.rockTeal, SLATE, "deco")
	b:box("LakeIsland", 944, 958, -66, -56, 0, 1, C.rockTeal, SLATE, "solid")
	b:ramp("LakeIslandRamp", 951, -66, 0, 1, 0, 1, 10, C.rockTeal, SLATE)
	b:box("LedgeRock", 972, 994, -66, -48, 0, 10, C.rock, SLATE, "solid")
	b:box("LedgeRockBand", 971.7, 994.3, -66.3, -47.7, 3.5, 5, C.rockDark, SLATE, "deco")
	b:ramp("LedgeRamp", 994, -58, -1, 0, 0, 10, 10, C.rockDark, SLATE, C.rockTeal)
	b:block("LedgeSpire", 978, -52.5, 12, 3, 10, 20, 0, C.rock, SLATE, "solid")
	b:block("LedgeSpireCap", 978, -52.5, 15, 5, 20, 22, 0.1, C.rockTeal, SLATE, "deco")

	b:group("FriezaShip")
	b:box("ShipDeckA", 1039, 1069, -67, -53, 11, 12, C.ship, METAL, "solid")
	b:box("ShipDeckB", 1047, 1061, -75, -45, 11, 12, C.ship, METAL, "solid")
	b:box("ShipDeckC", 1042, 1066, -72, -48, 11, 12, C.ship, METAL, "solid")
	b:cyl("ShipSkirt", 1054, -60, 31, 11.2, 12.05, C.ship, METAL, "deco")
	b:cyl("ShipHull", 1054, -60, 27, 8.6, 11.2, C.shipDark, METAL, "deco")
	b:cyl("ShipLights", 1054, -60, 31.4, 10.2, 10.9, C.shipNeon, NEON, "deco")
	b:ball("ShipDome", 1054, 12, -60, 9, C.ship, GLASS, "solid")
	for _, l in { { 1044, -50 }, { 1064, -50 }, { 1044, -70 }, { 1064, -70 } } do
		b:box("ShipLeg", l[1] - 1.5, l[1] + 1.5, l[2] - 1.5, l[2] + 1.5, 0, 11, C.shipDark, METAL, "solid")
	end
	b:ramp("ShipRamp", 1054, -45, 0, -1, 0, 12, 10, C.shipDark, METAL, C.shipNeon)

	b:group("SaiyanPod")
	b:disc("PodCrater", 1008, -26, 16, 0.12, C.crater)
	b:disc("PodCraterInner", 1010, -28, 9, 0.16, C.rockDark)
	b:ball("SaiyanPod", 1011, 2.3, -28.5, 5, C.pod, METAL, "solid")
	b:part("SaiyanPodWindow", Vector3.new(0.4, 2.2, 2.2), CFrame.new(1011, G + 3, -26.1) * CFrame.Angles(0, math.pi / 2, 0), C.podWindow, GLASS, "deco", { shape = "Cylinder" })
	b:block("PodRimRockA", 1000, -33, 4, 3, 0, 1.6, 0.3, C.rockDark, SLATE, "solid")
	b:block("PodRimRockB", 1017, -33, 5, 3, 0, 2, -0.4, C.rockDark, SLATE, "solid")
	b:block("PodRimRockC", 1018, -21.5, 3, 3, 0, 1.2, 0.2, C.rockDark, SLATE, "solid")

	b:group("DragonBalls")
	for _, d in { { 860.5, 1, -64 }, { 1057, 12, -73 }, { 804, 12, -62 }, { 1071, 18, 70 }, { 796, 0, 73 }, { 850, 8, 62 }, { 936, 3, 58 } } do
		b:ball("DragonBall", d[1], d[2] + 0.65, d[3], 1.3, C.dragonBall, NEON, "deco")
	end

	b:group("CliffRing")
	local heights = { 14, 20, 11, 17, 22, 13, 18, 12, 21, 15, 19, 12 }
	local segment = (x1 - x0) / #heights
	for i, h in heights do
		local sx0 = x0 + (i - 1) * segment
		b:box("CliffRingNorth", sx0, sx0 + segment, 81, 85.8, 0, h, i % 2 == 0 and C.rock or C.rockDark, SLATE, "solid")
		b:box("CliffRingSouth", sx0, sx0 + segment, -87, -81, 0, heights[#heights - i + 1], i % 2 == 0 and C.rockDark or C.rock, SLATE, "solid")
	end
end

--------------------------------------------------------------------------------------------------------------------
-- Stage 6: One Piece (Volcano)
--------------------------------------------------------------------------------------------------------------------

local C6 = {
	plank = rgb(160, 112, 68), darkWood = rgb(104, 70, 44), water = rgb(38, 150, 214), foam = rgb(236, 248, 255),
	rock = rgb(120, 110, 100), rockDark = rgb(88, 80, 74), stone = rgb(150, 146, 140), hull = rgb(206, 138, 64),
	hullLight = rgb(232, 180, 100), cream = rgb(250, 244, 226), lawn = rgb(96, 182, 84), cabin = rgb(150, 96, 56),
	sail = rgb(250, 246, 232), black = rgb(24, 24, 28), white = rgb(248, 248, 250), lion = rgb(252, 206, 60),
	mane = rgb(232, 118, 40), marineWhite = rgb(242, 244, 248), marineBlue = rgb(36, 78, 168), coral = rgb(240, 124, 96),
	yellow = rgb(250, 212, 92), mint = rgb(126, 212, 172), sky = rgb(112, 182, 232), roof = rgb(190, 90, 60),
	roofBlue = rgb(52, 92, 170), glass = rgb(120, 190, 230), warmLight = rgb(255, 200, 90), crate = rgb(180, 130, 76),
	red = rgb(210, 50, 44), metal = rgb(70, 74, 84), awning = rgb(230, 70, 60), tar = rgb(40, 34, 30),
	quicksand = rgb(200, 170, 110),
}

local function buildOnePiece(b, stage)
	local C = C6
	local x0, x1 = stage.XMin, stage.XMax
	local G = b.G

	b:group("Boardwalk")
	b:flat("Boardwalk", x0, x1, -12, 12, 0.1, C.plank, WOOD)
	b:flat("BoardwalkEdgeNorth", x0, x1, 11, 12.4, 0.16, C.darkWood, WOOD)
	b:flat("BoardwalkEdgeSouth", x0, x1, -12.4, -11, 0.16, C.darkWood, WOOD)
	for x = x0 + 16, x1 - 8, 24 do
		b:flat("BoardwalkSeam", x - 0.2, x + 0.2, -11, 11, 0.14, C.darkWood, WOOD)
	end
	for _, p in { { 1150, -24, 0.3 }, { 1190, -22, 1.2 }, { 1330, -22, 2.1 }, { 1362, -24, 0.8 }, { 1445, -25, 1.7 }, { 1234, 30, 2.6 }, { 1300, 26, 0.5 }, { 1440, 50, 1.4 }, { 1456, 68, 2.9 } } do
		palm(b, p[1], p[2], p[3])
	end

	b:group("Sea")
	b:water("SeaWest", 1090, 1280, -88, -30, C.water)
	b:water("SeaEast", 1280, x1, -88, -30, C.water)
	b:box("SeaFoam", 1090, x1, -30, -29, Step.WATER_TOP - 0.1, Step.WATER_TOP, C.foam, SP, "deco", { shadow = false })
	-- slow shallows over the open water only: the west pier, the islet and the quay (3 studs high) stay dry
	for _, r in {
		{ 1090, 1102, -88, -30 }, { 1102, 1112, -88, -72 }, { 1112, 1130, -88, -30 }, { 1130, 1162, -88, -74 },
		{ 1130, 1162, -56, -30 }, { 1162, 1196, -88, -30 }, { 1196, 1300, -88, -54 }, { 1196, 1300, -36, -30 }, { 1300, x1, -88, -30 },
	} do
		b:hazard("SeaShallows", r[1], r[2], r[3], r[4], 0.5)
	end

	b:group("WestPier")
	b:box("WestPier", 1102, 1112, -72, -30, 0, 3, C.plank, WOOD, "solid")
	b:ramp("WestPierRamp", 1107, -30, 0, -1, 0, 3, 10, C.plank, WOOD, C.darkWood)
	for _, z in { -38, -50, -62, -71 } do
		b:cyl("WestPierPost", 1101.6, z, 1, 0, 5, C.darkWood, WOOD, "deco")
		b:cyl("WestPierPost", 1112.4, z, 1, 0, 5, C.darkWood, WOOD, "deco")
	end
	b:box("RowboatHull", 1115, 1119, -64, -54, -0.3, 1.3, C.hull, WOOD, "deco")
	b:box("RowboatInside", 1115.5, 1118.5, -63.3, -54.7, 0.9, 1.35, C.darkWood, WOOD, "deco")

	b:group("RockIslet")
	b:box("Islet", 1130, 1162, -74, -56, 0, 3, C.rock, SLATE, "solid")
	b:ramp("IsletRamp", 1156, -56, 0, -1, 0, 3, 10, C.rock, SLATE)
	b:box("IsletBoulder", 1132, 1150, -62, -57, 3, 12, C.rockDark, SLATE, "solid")
	b:block("IsletBoulderTop", 1140, -59.5, 14, 6, 12, 14.5, 0.12, C.rock, SLATE, "deco")
	palm(b, 1158, -70, 0.4, 3)

	b:group("Harbour")
	b:box("Quay", 1196, 1300, -54, -36, 0, 3, C.plank, WOOD, "solid")
	b:box("QuayEdge", 1195.7, 1300.3, -54.3, -35.7, 0, 2.2, C.darkWood, WOOD, "deco")
	b:ramp("QuayRampWest", 1220, -36, 0, -1, 0, 3, 12, C.plank, WOOD, C.darkWood)
	b:ramp("QuayRampEast", 1272, -36, 0, -1, 0, 3, 12, C.plank, WOOD, C.darkWood)
	b:box("CargoCrates", 1282, 1300, -42, -38, 3, 9, C.crate, WOOD, "solid")
	b:box("CargoCratesTop", 1284, 1292, -41.5, -38.5, 9, 12, C.crate, WOOD, "deco")
	for _, p in { { 1202, -40 }, { 1205, -41.5 }, { 1230, -38.5 } } do
		barrel(b, p[1], p[2], 3)
	end
	for _, x in { 1210, 1256, 1280 } do
		b:cyl("Bollard", x, -53, 1.4, 3, 4.4, C.metal, METAL, "deco")
	end

	-- docked pirate ship: lawn main deck (8), stern deck (12) behind the helm cabin, bow deck (10), lion figurehead
	b:group("PirateShip")
	b:box("ShipSterncastle", 1204, 1218, -76, -54, 0, 12, C.hull, WOOD, "solid")
	b:box("ShipHull", 1218, 1262, -76, -54, 0, 8, C.hull, WOOD, "solid")
	b:box("ShipForecastle", 1262, 1276, -76, -54, 0, 10, C.hull, WOOD, "solid")
	b:block("ShipBow", 1276, -65, 15.5, 15.5, 0, 10, math.rad(45), C.hull, WOOD, "solid")
	b:box("ShipWaterline", 1203.7, 1276.3, -76.3, -53.7, 0, 2.2, C.darkWood, WOOD, "deco")
	b:block("ShipBowWaterline", 1276, -65, 15.8, 15.8, 0, 2.2, math.rad(45), C.darkWood, WOOD, "deco")
	b:box("ShipStripe", 1203.7, 1276.3, -76.3, -53.7, 5.2, 6.2, C.cream, SP, "deco")
	b:block("ShipBowStripe", 1276, -65, 15.8, 15.8, 5.2, 6.2, math.rad(45), C.cream, SP, "deco")
	b:box("ShipLawn", 1218.5, 1261.5, -74.8, -55.2, 7.9, 8.07, C.lawn, SP, "deco", { shadow = false })
	b:box("ShipBulwarkNorthA", 1218, 1239, -55, -54, 8, 10.5, C.hullLight, WOOD, "solid")
	b:box("ShipBulwarkNorthB", 1249, 1262, -55, -54, 8, 10.5, C.hullLight, WOOD, "solid")
	b:box("ShipBulwarkSouth", 1218, 1262, -76, -75, 8, 10.5, C.hullLight, WOOD, "solid")
	b:box("ShipAftRailSouth", 1204, 1218, -76, -75, 12, 13.6, C.hullLight, WOOD, "solid")
	b:box("ShipAftRailWest", 1204, 1205, -75, -58, 12, 13.6, C.hullLight, WOOD, "solid")
	b:box("ShipForeRailNorth", 1262, 1276, -55, -54, 10, 12.4, C.hullLight, WOOD, "solid")
	b:box("ShipForeRailSouth", 1262, 1276, -76, -75, 10, 12.4, C.hullLight, WOOD, "solid")
	b:box("ShipHelmCabin", 1204, 1218, -58, -54, 12, 17.5, C.cabin, WOOD, "solid")
	b:box("ShipCabinRoof", 1203.6, 1218.4, -58.4, -53.6, 17.5, 18.3, C.darkWood, WOOD, "deco")
	b:box("ShipCabinWindows", 1206, 1216, -58.3, -58, 13.8, 16, C.glass, GLASS, "deco")
	b:ramp("ShipAftStairs", 1218, -66, -1, 0, 8, 12, 10, C.darkWood, WOOD, C.hullLight)
	b:ramp("ShipForeStairs", 1262, -65, 1, 0, 8, 10, 10, C.darkWood, WOOD, C.hullLight)
	b:ramp("ShipGangplank", 1244, -54, 0, -1, 3, 8, 10, C.plank, WOOD, C.darkWood)
	b:box("ShipCargoHatch", 1233, 1239, -61, -56, 8, 10.5, C.darkWood, WOOD, "solid")
	b:box("ShipWinch", 1270, 1276, -58, -55, 10, 12.5, C.darkWood, WOOD, "solid")
	b:cyl("MainMast", 1244, -65, 2.6, 8, 46, C.darkWood, WOOD, "solid")
	b:box("MainYardLow", 1245.3, 1246.3, -78, -52, 29, 30, C.darkWood, WOOD, "deco")
	b:box("MainSailLow", 1245.6, 1246, -77, -53, 16, 29, C.sail, SP, "deco")
	b:box("MainYardHigh", 1245.3, 1246.3, -75, -55, 41, 41.8, C.darkWood, WOOD, "deco")
	b:box("MainSailHigh", 1245.6, 1246, -74, -56, 31, 41, C.sail, SP, "deco")
	b:cyl("CrowsNest", 1244, -65, 5, 42.5, 45, C.darkWood, WOOD, "deco")
	b:box("MainFlag", 1244.1, 1244.4, -71, -65.2, 46.5, 50.5, C.black, SP, "deco")
	local jx = 1246.1
	b:part("JollyRogerDisc", Vector3.new(0.2, 9, 9), CFrame.new(jx, G + 22.5, -65), C.black, SP, "deco", { shape = "Cylinder" })
	b:part("JollyRogerBoneA", Vector3.new(0.3, 0.9, 8), CFrame.new(jx + 0.2, G + 22, -65) * CFrame.Angles(math.rad(45), 0, 0), C.white, SP, "deco")
	b:part("JollyRogerBoneB", Vector3.new(0.3, 0.9, 8), CFrame.new(jx + 0.2, G + 22, -65) * CFrame.Angles(math.rad(-45), 0, 0), C.white, SP, "deco")
	b:ball("JollyRogerSkull", jx + 1.4, 22.6, -65, 3.6, C.white, SP, "deco")
	b:part("JollyRogerHat", Vector3.new(0.5, 1.3, 4), CFrame.new(jx + 2.6, G + 24.8, -65), C.lion, SP, "deco")
	b:part("JollyRogerHatBand", Vector3.new(0.55, 0.4, 4.05), CFrame.new(jx + 2.6, G + 24.3, -65), C.red, SP, "deco")
	b:part("JollyRogerHatBrim", Vector3.new(0.5, 0.35, 6.6), CFrame.new(jx + 2.6, G + 24, -65), C.lion, SP, "deco")
	b:cyl("ForeMast", 1270, -65, 2, 10, 36, C.darkWood, WOOD, "solid")
	b:box("ForeYard", 1270.8, 1271.8, -76, -54, 26, 26.8, C.darkWood, WOOD, "deco")
	b:box("ForeSail", 1271.1, 1271.5, -75, -55, 14, 26, C.sail, SP, "deco")
	b:box("LionCollar", 1284, 1290, -67, -63, 7, 12, C.lion, SP, "deco")
	b:part("LionManeSquare", Vector3.new(1.6, 11, 11), CFrame.new(1289.6, G + 14.5, -65), C.mane, SP, "deco")
	b:part("LionManeDiamond", Vector3.new(1.6, 11, 11), CFrame.new(1289.5, G + 14.5, -65) * CFrame.Angles(math.rad(45), 0, 0), C.mane, SP, "deco")
	b:part("LionFace", Vector3.new(4, 6.4, 6.4), CFrame.new(1291.8, G + 14.5, -65), C.lion, SP, "deco")
	b:part("LionEyeLeft", Vector3.new(0.4, 1.3, 1.3), CFrame.new(1293.9, G + 15.8, -66.6), C.black, SP, "deco")
	b:part("LionEyeRight", Vector3.new(0.4, 1.3, 1.3), CFrame.new(1293.9, G + 15.8, -63.4), C.black, SP, "deco")
	b:part("LionNose", Vector3.new(1, 1.1, 1.8), CFrame.new(1294.2, G + 14.3, -65), C.mane, SP, "deco")
	b:part("LionMouth", Vector3.new(0.4, 0.7, 3.6), CFrame.new(1293.9, G + 12.9, -65), C.red, SP, "deco")

	b:group("Lighthouse")
	b:box("LighthouseRock", 1420, 1462, -74, -44, 0, 6, C.rock, SLATE, "solid")
	b:box("LighthouseRockBand", 1419.7, 1462.3, -74.3, -43.7, 2, 3.4, C.rockDark, SLATE, "deco")
	b:ramp("LighthouseRamp", 1428, -44, 0, -1, 0, 6, 10, C.plank, WOOD, C.darkWood)
	b:cyl("LighthouseTower", 1450, -58, 10, 6, 30, C.white, SP, "solid")
	b:cyl("LighthouseBandLow", 1450, -58, 10.4, 11, 14, C.red, SP, "deco")
	b:cyl("LighthouseBandHigh", 1450, -58, 10.4, 19, 22, C.red, SP, "deco")
	b:cyl("LighthouseGallery", 1450, -58, 13, 30, 31, C.darkWood, WOOD, "deco")
	b:cyl("LighthouseLantern", 1450, -58, 7, 31, 35, C.glass, GLASS, "deco", { transparency = 0.3 })
	b:ball("LighthouseLight", 1450, 33, -58, 4, C.warmLight, NEON, "deco")
	b:cyl("LighthouseCap", 1450, -58, 8, 35, 36.6, C.red, SP, "deco")
	b:box("KeeperHut", 1436, 1445, -62, -54, 6, 11, C.white, SP, "solid")
	b:box("KeeperHutRoof", 1435.6, 1445.4, -62.4, -53.6, 11, 12, C.roof, SP, "deco")

	b:group("HarbourTown")
	house(b, "RowHouseA", 1106, 1124, 40, 56, 10, C.coral, C.roof, C.darkWood)
	house(b, "RowHouseB", 1124, 1142, 40, 56, 12, C.yellow, C.roofBlue, C.darkWood)
	b:hazard("AlleyQuicksand", 1098, 1146, 60, 72, 0.6, C.quicksand)
	b:box("Tavern", 1152, 1182, 46, 70, 0, 12, C.mint, SP, "solid")
	stackedRoof(b, "TavernRoof", 1152, 1182, 46, 70, 12, C.roof)
	b:box("TavernBalcony", 1152, 1182, 36, 46, 7, 8, C.darkWood, WOOD, "solid")
	b:box("TavernBalconyRail", 1152, 1182, 36, 36.8, 8, 10.5, C.darkWood, WOOD, "solid")
	b:box("TavernBalconyPostWest", 1152, 1153, 36, 37, 0, 7, C.darkWood, WOOD, "deco")
	b:box("TavernBalconyPostEast", 1181, 1182, 36, 37, 0, 7, C.darkWood, WOOD, "deco")
	b:ramp("TavernStairs", 1182, 41, -1, 0, 0, 8, 10, C.plank, WOOD, C.darkWood)
	local tavernSign = b:box("TavernSign", 1158, 1176, 45.6, 45.95, 9, 11.5, C.darkWood, WOOD, "deco")
	addSign(tavernSign, Enum.NormalId.Front, "TAVERN", C.warmLight, C.black)
	for _, s in { { "StallFruit", 1146, C.awning }, { "StallFish", 1170, C.marineBlue } } do
		local name, sx = s[1], s[2]
		b:box(name .. "Counter", sx, sx + 10, 18, 21, 0, 3, C.plank, WOOD, "solid")
		b:box(name .. "PostWest", sx, sx + 0.6, 21.4, 22, 0, 7, C.darkWood, WOOD, "deco")
		b:box(name .. "PostEast", sx + 9.4, sx + 10, 21.4, 22, 0, 7, C.darkWood, WOOD, "deco")
		for k = 0, 2 do
			b:box(name .. "Awning", sx - 0.5 + k * 3.667, sx - 0.5 + (k + 1) * 3.667, 17, 22.4, 7, 7.5, k % 2 == 0 and s[3] or C.white, SP, "deco")
		end
		b:ball(name .. "Goods", sx + 3, 3.6, 19.5, 1.4, C.mane, SP, "deco")
		b:ball(name .. "Goods", sx + 7, 3.6, 19.5, 1.4, C.lawn, SP, "deco")
	end
	b:box("Lookout", 1206, 1226, 52, 74, 0, 20, C.stone, SLATE, "solid")
	b:box("LookoutBand", 1205.7, 1226.3, 51.7, 74.3, 9, 10.5, C.darkWood, WOOD, "deco")
	b:ramp("LookoutRamp", 1216, 52, 0, 1, 0, 20, 10, C.plank, WOOD, C.darkWood)
	b:box("LookoutRailWest", 1206, 1206.6, 52, 74, 20, 21.4, C.darkWood, WOOD, "deco")
	b:box("LookoutRailEast", 1225.4, 1226, 52, 74, 20, 21.4, C.darkWood, WOOD, "deco")
	b:box("LookoutRailNorth", 1206, 1226, 73.4, 74, 20, 21.4, C.darkWood, WOOD, "deco")
	b:box("LookoutFlagPole", 1224.4, 1225.1, 72.3, 73, 20, 32, C.darkWood, WOOD, "deco")
	b:box("LookoutFlag", 1225.1, 1231, 72.5, 72.8, 28, 31.6, C.black, SP, "deco")
	house(b, "HarbourHouseC", 1236, 1254, 44, 62, 10, C.sky, C.roof, C.darkWood)
	house(b, "HarbourHouseD", 1262, 1284, 50, 68, 11, C.coral, C.roofBlue, C.darkWood)
	house(b, "HarbourHouseE", 1290, 1304, 40, 54, 9, C.yellow, C.roof, C.darkWood)
	local wanted = b:box("WantedBoard", 1286, 1298, 18, 18.5, 3, 10, C.cream, WOOD, "deco")
	addSign(wanted, Enum.NormalId.Front, "WANTED", C.black, C.cream)
	b:box("WantedBoardLegWest", 1287, 1288, 18, 18.5, 0, 3, C.darkWood, WOOD, "solid")
	b:box("WantedBoardLegEast", 1296, 1297, 18, 18.5, 0, 3, C.darkWood, WOOD, "solid")
	for _, p in { { 1146, 34 }, { 1198, 30 }, { 1258, 36 } } do
		barrel(b, p[1], p[2])
	end
	b:box("HarbourWallNorth", x0, x1, 81, 83, 0, 5, C.stone, SLATE, "solid")
	b:box("HarbourWallNorthCap", x0, x1, 80.7, 83.3, 5, 5.6, C.rockDark, SLATE, "deco")

	-- Marine fortress: ramparts (14) with parapet, gate towers, round corner towers, HQ, courtyard
	b:group("MarineFortress")
	local W, Bl = C.marineWhite, C.marineBlue
	b:box("RampartWest", 1318, 1348, 30, 44, 0, 14, W, SP, "solid")
	b:box("RampartEast", 1380, 1412, 30, 44, 0, 14, W, SP, "solid")
	b:box("ParapetWest", 1318, 1348, 30, 31, 14, 16.5, W, SP, "solid")
	b:box("ParapetEast", 1380, 1412, 30, 31, 14, 16.5, W, SP, "solid")
	b:box("RampartTrimWest", 1318, 1348, 29.7, 30.05, 10, 11.5, Bl, SP, "deco")
	b:box("RampartTrimEast", 1380, 1412, 29.7, 30.05, 10, 11.5, Bl, SP, "deco")
	b:box("GateTowerWest", 1348, 1354, 28, 46, 0, 22, W, SP, "solid")
	b:box("GateTowerEast", 1374, 1380, 28, 46, 0, 22, W, SP, "solid")
	b:box("GateTowerWestCap", 1347.5, 1354.5, 27.5, 46.5, 22, 23.5, Bl, SP, "deco")
	b:box("GateTowerEastCap", 1373.5, 1380.5, 27.5, 46.5, 22, 23.5, Bl, SP, "deco")
	local arch = b:box("GateArch", 1347.5, 1380.5, 29, 35, 22, 26, Bl, SP, "deco")
	addSign(arch, Enum.NormalId.Front, "MARINE", W, Bl)
	b:box("FortWallWest", 1310, 1316, 44, 80, 0, 14, W, SP, "solid")
	b:box("FortWallEast", 1414, 1420, 44, 80, 0, 14, W, SP, "solid")
	for _, t in { { "FortTowerWest", 1313 }, { "FortTowerEast", 1417 } } do
		b:cyl(t[1], t[2], 37, 12, 0, 24, W, SP, "solid")
		b:cyl(t[1] .. "Cap", t[2], 37, 13.4, 24, 26, Bl, SP, "deco")
		b:cyl(t[1] .. "Top", t[2], 37, 8, 26, 30, Bl, SP, "deco")
	end
	b:ramp("RampartRamp", 1333, 44, 0, -1, 0, 14, 10, C.stone, SP, Bl)
	b:box("MarineHQ", 1348, 1392, 60, 80, 0, 16, W, SP, "solid")
	b:box("MarineHQRoof", 1347.4, 1392.6, 59.4, 80.6, 16, 17.4, Bl, SP, "deco")
	b:box("MarineHQRoofTop", 1356, 1384, 64, 76, 17.4, 20, Bl, SP, "deco")
	local banner = b:box("MarineHQBanner", 1360, 1380, 59.6, 59.95, 8, 14, W, SP, "deco")
	addSign(banner, Enum.NormalId.Front, "JUSTICE", Bl, W)
	b:box("MarineHQDoor", 1364, 1376, 59.6, 59.95, 0, 7, Bl, SP, "deco")
	for _, x in { 1326, 1392, 1404 } do
		b:part("RampartCannon", Vector3.new(6, 1.6, 1.6), CFrame.new(x, G + 15.4, 32.5) * CFrame.Angles(0, math.pi / 2, 0), C.metal, METAL, "deco", { shape = "Cylinder" })
	end
	b:hazard("CourtyardTar", 1356, 1372, 47, 57, 0.6, C.tar)
end

--------------------------------------------------------------------------------------------------------------------
-- End of the world: Red Line cliff wall + invisible side walls (A5)
--------------------------------------------------------------------------------------------------------------------

local function buildEndWall(b)
	local E, S = Step.END_WALL, Step.SIDE_WALLS
	local red, redDark, redLight = rgb(160, 48, 38), rgb(118, 32, 28), rgb(196, 86, 62)
	local metal, gold = rgb(52, 50, 56), rgb(236, 180, 60)

	b:group("RedLine")
	b:box("RedLineWall", E.XMin, E.XMax, E.ZMin, E.ZMax, 0, E.Height, red, SLATE, "solid")
	b:box("RedLineFoot", 1470, E.XMin, -88, 86, -0.1, 1.2, redDark, SLATE, "deco")
	b:box("RedLineStrataLow", E.XMin - 0.6, E.XMin, E.ZMin, E.ZMax, 8, 12, redDark, SLATE, "deco")
	b:box("RedLineStrataMid", E.XMin - 0.5, E.XMin, E.ZMin, E.ZMax, 26, 29, redLight, SLATE, "deco")
	b:box("RedLineStrataHigh", E.XMin - 0.4, E.XMin, E.ZMin, E.ZMax, 44, 48, redDark, SLATE, "deco")
	for _, r in { { -84, -58, 7 }, { -46, -20, 11 }, { 20, 44, 9 }, { 56, 86, 13 } } do
		b:box("RedLineCrest", E.XMin, E.XMax + 1, r[1], r[2], E.Height, E.Height + r[3], red, SLATE, "deco")
	end
	for _, r in { { 1466, -70, -52, 18 }, { 1464, -40, -22, 12 }, { 1466, 24, 40, 16 }, { 1464, 52, 74, 22 } } do
		b:box("RedLineButtress", r[1], E.XMin, r[2], r[3], 0, r[4], redDark, SLATE, "solid")
	end
	-- the closed gate at the end of the main street
	b:box("RedLineGate", E.XMin - 0.8, E.XMin, -14, 14, 0, 28, metal, METAL, "deco")
	b:box("RedLineGateBandLow", E.XMin - 1, E.XMin - 0.8, -14, 14, 8, 9.2, gold, METAL, "deco")
	b:box("RedLineGateBandHigh", E.XMin - 1, E.XMin - 0.8, -14, 14, 19, 20.2, gold, METAL, "deco")
	b:box("RedLineGateSeam", E.XMin - 1, E.XMin - 0.8, -0.4, 0.4, 0, 28, gold, METAL, "deco")
	b:box("RedLineGateArch", E.XMin - 1.2, E.XMin, -16, 16, 28, 31, redDark, SLATE, "deco")
	b:box("RedLineGateNeon", E.XMin - 1.3, E.XMin - 1.1, -14, 14, 27.4, 28, rgb(255, 60, 40), NEON, "deco")
	local sign = b:box("RedLineSign", E.XMin - 1.4, E.XMin - 1.1, -18, 18, 32, 39, rgb(30, 18, 16), SP, "deco")
	addSign(sign, Enum.NormalId.Left, "THE RED LINE\nEND OF THE MAP", gold, rgb(30, 18, 16))

	b:group("SideWalls")
	local invisible = { transparency = 1, shadow = false }
	b:box("SideWallNorth", S.XMin, S.XMax, S.North, S.North + S.Thickness, 0, S.Height, rgb(255, 255, 255), SP, "solid", invisible)
	b:box("SideWallSouth", S.XMin, S.XMax, S.South - S.Thickness, S.South, 0, S.Height, rgb(255, 255, 255), SP, "solid", invisible)
end

--------------------------------------------------------------------------------------------------------------------
-- Apply
--------------------------------------------------------------------------------------------------------------------

local BUILDERS = { Jungle = buildMHA, Snow = buildDragonBall, Volcano = buildOnePiece }

local function findBounds(ws, key)
	local objects = ws:FindFirstChild("__OBJECTS")
	local areas = objects and objects:FindFirstChild("Areas")
	local guardAreas = areas and areas:FindFirstChild("GuardAreas")
	local zone = guardAreas and guardAreas:FindFirstChild(key)
	local bounds = zone and zone:FindFirstChild("Bounds")
	if bounds and bounds:IsA("BasePart") then
		return bounds
	end
	return nil
end

local function recolourFloor(ws, stage)
	local ground = ws:FindFirstChild("Ground")
	local floor = ground and ground:FindFirstChild("ZoneFloor_" .. stage.Key)
	if not (floor and floor:IsA("BasePart")) then
		print(string.format("%s WARNING: Workspace.Ground.ZoneFloor_%s not found; floor not recoloured.", LOG_PREFIX, stage.Key))
		return
	end
	floor.Color = stage.Floor
end

function Step.Apply(place, spPlace, ctx)
	ctx = ctx or {}
	local ws = place.Workspace
	local baseplate = ctx.baseplate or ws:FindFirstChild("Baseplate")
	local groundY = ctx.groundY or (baseplate and baseplate.CFrame.Position.Y + baseplate.Size.Y / 2)
	assert(type(groundY) == "number", "env_b: groundY unavailable (no ctx.groundY and no Workspace.Baseplate)")
	local floorTopY = ScratchLayout.FloorTopY(ws, groundY)

	local root = ws:FindFirstChild(Step.FOLDER_NAME)
	if not root then
		root = Instance.new("Folder")
		root.Name = Step.FOLDER_NAME
		root.Parent = ws
	end
	-- rebuild only what this step owns (ENV-A shares the folder)
	local owned = { [Step.END_WALL_NAME] = true }
	for _, stage in Step.STAGES do
		owned[stage.Key] = true
	end
	for _, child in root:GetChildren() do
		if owned[child.Name] then
			child:Destroy()
		end
	end

	local summary = {}
	for _, stage in Step.STAGES do
		local model = Instance.new("Model")
		model.Name = stage.Key
		model:SetAttribute("StageKey", stage.Key)
		model:SetAttribute("StageNumber", stage.Number)
		model:SetAttribute("DisplayName", stage.DisplayName)
		model:SetAttribute("XMin", stage.XMin)
		model:SetAttribute("XMax", stage.XMax)
		model:SetAttribute("BuiltBy", "env_b")
		model.Parent = root
		local b = newBuilder(model, groundY)
		BUILDERS[stage.Key](b, stage)
		-- D9: villain post + egg ring + cover rocks (kept in the Workspace by the D8 scratch layout)
		local ringOpts = {
			key = stage.Key,
			number = stage.Number,
			x0 = stage.XMin,
			x1 = stage.XMax,
			groundY = groundY,
			floorTopY = floorTopY,
			count = stage.EggSpots,
			bounds = findBounds(ws, stage.Key),
		}
		local built = ScratchLayout.BuildRing(model, ringOpts)
		b.parts += built.parts
		local ring = ScratchLayout.ValidateRing(model, ringOpts)
		model:SetAttribute("EggSpotCount", stage.EggSpots)
		model:SetAttribute("HiddenEggSpots", ring.hidden)
		model:SetAttribute("PartCount", b.parts)
		pcall(function()
			model.WorldPivotData = CFrame.new((stage.XMin + stage.XMax) / 2, groundY, 0)
		end)
		assert(b.parts <= Step.MAX_PARTS_PER_STAGE, string.format("%s: %d parts (limit %d)", stage.Key, b.parts, Step.MAX_PARTS_PER_STAGE))
		recolourFloor(ws, stage)
		table.insert(summary, string.format("%s %d parts, %d hazards; egg ring: VillainPost (%.1f, %.0f), %d EggSpots %.1f-%.1f studs out (%d hidden, %d cover rock parts, spots >= %.1f apart, rock walkways >= %.1f, opening %.0f deg)",
			stage.Key, b.parts, b.hazards, ring.post.x, ring.post.z, stage.EggSpots, ring.minDist, ring.maxDist, ring.hidden, ring.rocks, ring.minGap, ring.minRoute, ring.opening))
	end

	local wallModel = Instance.new("Model")
	wallModel.Name = Step.END_WALL_NAME
	wallModel:SetAttribute("BuiltBy", "env_b")
	wallModel.Parent = root
	local wb = newBuilder(wallModel, groundY)
	buildEndWall(wb)
	pcall(function()
		wallModel.WorldPivotData = CFrame.new((Step.END_WALL.XMin + Step.END_WALL.XMax) / 2, groundY, 0)
	end)
	table.insert(summary, string.format("EndWall %d parts", wb.parts))

	print(string.format("[StealaHero Build] Stage environments 4-6 (env_b): %s.", table.concat(summary, "; ")))
end

return Step
