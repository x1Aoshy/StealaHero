-- scripts/steps/post_trail_fx.luau
-- TRAILS (Gekko TO DO #4, 2026-09-24): "Themed Trails: starting from Legendary rarity, add themed trails such as
-- Lightning, Galaxy/Cosmic, Energy/Flame, and other superpower effects."
-- Build hook: scripts/build_stealahero.luau step 12b runs every scripts/steps/post_*.luau in name order:
-- Apply(place, spPlace, ctx). Idempotent (the ribbons are rebuilt, Assets.TrailFx is recreated).
--
-- Two layers make a trail:
--   1. The ribbon, ReplicatedStorage.Assets.Trails.<TrailId> (every rarity). Game.TrailController clones it onto the
--      HumanoidRootPart on every client (so everyone sees it) and cleans it on unequip / respawn / leave. Kept: the
--      invisible BasePart and its MainPartTrailWeldConstraint (TrailController and Directory.Trails assert both).
--      Rebuilt here as one clean Trail between MainTrailAttachment1/2: a colour gradient that fades and tapers toward
--      the tail, and a Lifetime + MaxLength pair that keeps it readable from WalkSpeed 16 (~4 studs) to 300 (see
--      RIBBON_FULL_SPEED: the cap only trims a tail that has already faded).
--      GreyTrail was pink and DivineTrail hung its trails off nested Attachments (not parented to a BasePart).
--   2. The superpower FX, ReplicatedStorage.Assets.TrailFx.<TrailId> (Legendary and above only, see THEMES). A Folder
--      of Attachments holding a thin hot-core Trail, two ParticleEmitters, a PointLight and, for Divine, a Beam halo.
--      ServerScriptService.TrailService clones the folder and parents its Attachments to the character (server
--      instances, replicated to everyone), and removes them on unequip, death, respawn and leave.
--      Attachment attributes read by TrailService: TrailFxMount = "Head" (mount on that character part instead of the
--      HumanoidRootPart), TrailFxAbove = n (move the attachment n studs above the top of that part).
--
-- Speed: the emitters are split so the effect reads at any WalkSpeed. One emitter per theme is LockedToPart (a fixed
-- size jet / aura that moves rigidly with the runner, so it looks the same at 16 and at 200 studs/s); the other sheds
-- particles into the world with a partial VelocityInheritance (a wake whose length grows with speed but stays dense).
-- Cost: at most 2 emitters (<= 40 particles/s together) + 1 light per player.
--
-- Textures: only IDs already used by emitters in this place (the source of each is noted) and the built-in
-- rbxasset:// particle textures; Apply warns when one is no longer present in the place.

local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum
local ColorSequence = roblox.ColorSequence
local ColorSequenceKeypoint = roblox.ColorSequenceKeypoint
local NumberSequence = roblox.NumberSequence
local NumberSequenceKeypoint = roblox.NumberSequenceKeypoint
local NumberRange = roblox.NumberRange
local Content = roblox.Content

local Step = {}

Step.FX_FOLDER = "TrailFx"
Step.RIBBON_TEXTURE = "rbxassetid://1314109432" -- the base game's trail texture (every Assets.Trails ribbon)
Step.MIN_FX_RARITY = 5 -- Directory.Rarity RarityNumber of Legendary

-- Trail length cap (REVIEW 2026-09-24). A Trail fades and tapers over its Lifetime (Transparency / WidthScale are per
-- segment age) while MaxLength drops the oldest segments, so a cap tighter than Lifetime x speed cuts the tail while it
-- is still opaque: with the first caps (30-40 studs) every ribbon ended in a blunt, ~25%-transparent bar at the top
-- WalkSpeed of 300 (TreadmillUtil.SpeedPowerToWalkSpeed). MaxLength = Lifetime x RIBBON_FULL_SPEED instead: up to that
-- speed the whole faded ribbon shows; at 300 only the last ~20% of the lifetime (already ~70% transparent) is trimmed.
Step.RIBBON_FULL_SPEED = 240
local function capLength(lifetime)
	return math.floor(lifetime * Step.RIBBON_FULL_SPEED + 0.5)
end

-- Ribbons (layer 1). colors: { t, r, g, b }; width = distance between the two attachments (FaceCamera ribbon);
-- MaxLength = capLength(lifetime) unless a row sets maxLength.
local FADE = { { 0, 0 }, { 0.55, 0.3 }, { 1, 1 } }
local TAPER = { { 0, 1 }, { 1, 0.35 } }
Step.RIBBONS = {
	GreyTrail = { width = 1.4, lifetime = 0.22, brightness = 1.6, colors = { { 0, 250, 250, 255 }, { 1, 165, 170, 182 } } },
	GreenTrail = { width = 1.4, lifetime = 0.22, brightness = 1.8, colors = { { 0, 175, 255, 175 }, { 0.45, 45, 225, 95 }, { 1, 0, 150, 60 } } },
	BlueTrail = { width = 1.5, lifetime = 0.23, brightness = 1.8, colors = { { 0, 175, 238, 255 }, { 0.45, 45, 165, 255 }, { 1, 0, 90, 230 } } },
	PurpleTrail = { width = 1.5, lifetime = 0.24, brightness = 1.9, colors = { { 0, 242, 185, 255 }, { 0.45, 185, 75, 255 }, { 1, 100, 0, 190 } } },
	GoldenTrail = { width = 1.7, lifetime = 0.26, brightness = 2, colors = { { 0, 255, 246, 195 }, { 0.4, 255, 202, 55 }, { 1, 255, 128, 0 } } },
	RedTrail = { width = 1.7, lifetime = 0.26, brightness = 2, colors = { { 0, 255, 238, 160 }, { 0.35, 255, 138, 22 }, { 1, 205, 22, 0 } } },
	GalaxyTrail = { width = 1.8, lifetime = 0.3, brightness = 2, colors = { { 0, 205, 175, 255 }, { 0.3, 135, 75, 255 }, { 0.65, 70, 45, 205 }, { 1, 40, 10, 125 } } },
	-- dark storm cloud (Secret's dark identity); the electric core and the arcs come from its FX
	SecretTrail = { width = 1.8, lifetime = 0.28, brightness = 1, emission = 0.15, colors = { { 0, 120, 150, 210 }, { 0.4, 42, 52, 95 }, { 1, 12, 14, 28 } } },
	EternalTrail = { width = 1.9, lifetime = 0.3, brightness = 1.8, emission = 0.6, colors = { { 0, 255, 120, 245 }, { 0.4, 200, 22, 222 }, { 1, 60, 0, 92 } } },
	DivineTrail = { width = 2, lifetime = 0.3, brightness = 2.4, colors = { { 0, 255, 255, 255 }, { 0.4, 255, 246, 195 }, { 1, 255, 214, 90 } } },
}

-- Superpower FX (layer 2). Attachment positions are HumanoidRootPart space (+Z = behind the runner).
local BACK = Vector3.new(0, 0.2, 0.7)
local BODY = Vector3.new(0, 0, 0)
Step.THEMES = {
	GoldenTrail = {
		theme = "Golden Energy",
		core = { width = 0.5, colors = { { 0, 255, 252, 230 }, { 1, 255, 205, 80 } }, brightness = 3 },
		light = { color = { 255, 200, 90 }, brightness = 0.8, range = 8 },
		emitters = {
			{ -- golden energy sparks shed behind, falling (TreadmillUpgrade.sparks streak texture)
				name = "GoldSparks", at = BACK, texture = "rbxassetid://7451822955",
				rate = 20, lifetime = { 0.35, 0.6 }, speed = { 10, 18 }, spread = { 55, 55 }, direction = "Back",
				size = { { 0, 0.32 }, { 0.3, 0.28 }, { 1, 0 } }, transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
				colors = { { 0, 255, 250, 210 }, { 0.4, 255, 215, 90 }, { 1, 255, 150, 20 } },
				emission = 1, brightness = 3, acceleration = { 0, -28, 0 }, drag = 2.5,
				locked = false, inherit = 0.3, orientation = "VelocityParallel", squash = { { 0, -2 }, { 1, -1.5 } },
			},
			{ -- glints bursting off the body (Particles.Sparkles.Sparkles)
				name = "GoldGlints", at = BODY, texture = "rbxassetid://1084970835",
				rate = 7, lifetime = { 0.45, 0.75 }, speed = { 2.5, 4.5 }, spread = { 180, 180 }, direction = "Top",
				size = { { 0, 0 }, { 0.25, 0.5 }, { 1, 0 } }, transparency = { { 0, 0 }, { 1, 0.3 } },
				colors = { { 0, 255, 240, 170 }, { 1, 255, 200, 70 } },
				emission = 1, brightness = 2.5, drag = 3, rotation = { -180, 180 }, rotSpeed = { 60, 120 }, zOffset = 0.5,
				locked = true, inherit = 0,
			},
		},
	},
	RedTrail = {
		theme = "Inferno Flame",
		core = { width = 0.5, colors = { { 0, 255, 255, 215 }, { 1, 255, 180, 50 } }, brightness = 3 },
		light = { color = { 255, 110, 35 }, brightness = 1.1, range = 9 },
		emitters = {
			{ -- fixed-length flame jet off the back (Demon Slap Fire2 flipbook)
				name = "FlameJet", at = Vector3.new(0, 0.1, 0.6), texture = "rbxassetid://11844017484",
				flipbook = { layout = "Grid4x4", mode = "OneShot" },
				rate = 24, lifetime = { 0.28, 0.42 }, speed = { 7, 10 }, spread = { 14, 14 }, direction = "Back",
				size = { { 0, 1.2 }, { 0.5, 1.05 }, { 1, 0.35 } }, transparency = { { 0, 0.15 }, { 0.6, 0.35 }, { 1, 1 } },
				colors = { { 0, 255, 235, 140 }, { 0.35, 255, 130, 25 }, { 1, 190, 20, 0 } },
				emission = 0.7, brightness = 2.5, acceleration = { 0, 5, 0 }, drag = 1.5,
				rotation = { -180, 180 }, rotSpeed = { -40, 40 }, locked = true, inherit = 0,
			},
			{ -- rising embers left in the world (Volcano Bat Specs)
				name = "Embers", at = BACK, texture = "rbxassetid://8030760338",
				rate = 16, lifetime = { 0.5, 0.9 }, speed = { 4, 8 }, spread = { 70, 70 }, direction = "Back",
				size = { { 0, 0 }, { 0.15, 0.3 }, { 1, 0 } }, transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
				colors = { { 0, 255, 230, 120 }, { 0.5, 255, 120, 20 }, { 1, 200, 30, 0 } },
				emission = 1, brightness = 4, acceleration = { 0, 9, 0 }, drag = 2.5, locked = false, inherit = 0.3,
			},
		},
	},
	GalaxyTrail = {
		theme = "Cosmic Galaxy",
		core = { width = 0.45, colors = { { 0, 240, 228, 255 }, { 1, 165, 125, 255 } }, brightness = 3 },
		light = { color = { 150, 100, 255 }, brightness = 0.9, range = 9 },
		emitters = {
			{ -- twinkling stardust left in the world (Mutation_FX.Galactic.Sparkle, its squash twinkle)
				name = "Stardust", at = BACK, texture = "rbxassetid://96773826835360",
				rate = 16, lifetime = { 0.6, 1 }, speed = { 1.5, 4 }, spread = { 180, 180 }, direction = "Back",
				size = { { 0, 0 }, { 0.12, 0.55 }, { 0.5, 0.35 }, { 1, 0 } }, transparency = { { 0, 0 }, { 0.7, 0 }, { 1, 1 } },
				colors = { { 0, 255, 255, 255 }, { 1, 205, 175, 255 } },
				emission = 1, brightness = 3, drag = 2, rotation = { -180, 180 }, rotSpeed = { -90, 90 },
				squash = { { 0, -1.5 }, { 0.17, 0.48 }, { 0.5, 0.87 }, { 0.84, 0.48 }, { 1, -1.6 } },
				locked = false, inherit = 0.25,
			},
			{ -- nebula clouds streaming off the back (Aura_Mythic space flipbook)
				name = "Nebula", at = BACK, texture = "rbxassetid://92739826225814",
				flipbook = { layout = "Grid4x4", mode = "OneShot" },
				rate = 6, lifetime = { 0.7, 1 }, speed = { 3, 5 }, spread = { 18, 18 }, direction = "Back",
				size = { { 0, 1 }, { 1, 2.4 } }, transparency = { { 0, 1 }, { 0.3, 0.55 }, { 1, 1 } },
				colors = { { 0, 110, 70, 255 }, { 0.5, 60, 120, 255 }, { 1, 190, 70, 255 } },
				emission = 0.7, brightness = 2.5, drag = 1.5, rotation = { -180, 180 }, rotSpeed = { -30, 30 }, zOffset = -0.5,
				locked = true, inherit = 0,
			},
		},
	},
	SecretTrail = {
		theme = "Storm Lightning",
		core = { width = 0.4, colors = { { 0, 225, 248, 255 }, { 1, 90, 200, 255 } }, brightness = 4 },
		light = { color = { 130, 200, 255 }, brightness = 1.2, range = 10 },
		emitters = {
			{ -- lightning arcs crackling on the body (SAB Blurry Arc Lightning flipbook)
				name = "Arcs", at = BODY, texture = "rbxassetid://13778464872",
				flipbook = { layout = "Grid4x4", mode = "OneShot" },
				rate = 8, lifetime = { 0.1, 0.2 }, speed = { 0, 0 }, spread = { 0, 0 }, direction = "Top",
				size = { { 0, 2.6, 0.6 }, { 1, 3, 0.6 } }, transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
				colors = { { 0, 170, 228, 255 }, { 1, 220, 245, 255 } },
				emission = 1, brightness = 6, rotation = { -180, 180 }, zOffset = 0.3, locked = true, inherit = 0,
			},
			{ -- bolts left along the path (SAB Lightning19 flipbook)
				name = "Bolts", at = BACK, texture = "rbxassetid://17005524119",
				flipbook = { layout = "Grid4x4", mode = "OneShot" },
				rate = 6, lifetime = { 0.14, 0.24 }, speed = { 1, 3 }, spread = { 60, 60 }, direction = "Back",
				size = { { 0, 2, 0.5 }, { 1, 2.4, 0.5 } }, transparency = { { 0, 0 }, { 1, 0.2 } },
				colors = { { 0, 210, 245, 255 }, { 1, 90, 190, 255 } },
				emission = 1, brightness = 6, rotation = { -180, 180 }, locked = false, inherit = 0.4,
			},
		},
	},
	EternalTrail = {
		theme = "Void Shadow",
		-- a black rift core inside the magenta ribbon
		core = { width = 0.45, colors = { { 0, 22, 0, 32 }, { 1, 70, 0, 100 } }, brightness = 1, emission = 0, transparency = { { 0, 0.05 }, { 0.5, 0.3 }, { 1, 1 } } },
		light = { color = { 230, 40, 255 }, brightness = 0.9, range = 9 },
		emitters = {
			{ -- dark void smoke left in the world (VFX.SmokeBomb smoke)
				name = "VoidSmoke", at = BACK, texture = "rbxassetid://10439914655",
				rate = 12, lifetime = { 0.5, 0.85 }, speed = { 1, 3 }, spread = { 35, 35 }, direction = "Back",
				size = { { 0, 0.9 }, { 1, 2.3 } }, transparency = { { 0, 1 }, { 0.2, 0.4 }, { 0.7, 0.6 }, { 1, 1 } },
				colors = { { 0, 72, 0, 98 }, { 1, 20, 0, 30 } },
				emission = 0, brightness = 1, drag = 2, rotation = { -180, 180 }, rotSpeed = { -40, 40 },
				locked = false, inherit = 0.3,
			},
			{ -- magenta void specks flung off the body (Particles.EternalAura Spec-VFX)
				name = "VoidSpecks", at = BODY, texture = "rbxassetid://16511986084",
				rate = 12, lifetime = { 0.5, 0.8 }, speed = { 2, 4 }, spread = { 180, 180 }, direction = "Top",
				size = { { 0, 0 }, { 0.35, 0.45 }, { 1, 0 } }, transparency = { { 0, 0 }, { 1, 0.2 } },
				colors = { { 0, 255, 110, 245 }, { 1, 170, 40, 255 } },
				emission = 1, brightness = 3, acceleration = { 0, 2, 0 }, drag = 3, zOffset = 0.4, locked = true, inherit = 0,
			},
		},
	},
	DivineTrail = {
		theme = "Holy Light",
		core = { width = 0.55, colors = { { 0, 255, 255, 255 }, { 1, 255, 250, 215 } }, brightness = 4 },
		light = { color = { 255, 240, 190 }, brightness = 1.2, range = 10 },
		emitters = {
			{ -- holy rays glowing behind the silhouette (LuckyBlocks Divine Block Rays; ZOffset pushes it behind the body)
				name = "HolyRays", at = Vector3.new(0, 0.6, 0.5), texture = "rbxassetid://111342233376418",
				rate = 2.5, lifetime = { 1, 1.2 }, speed = { 0, 0 }, spread = { 0, 0 }, direction = "Top",
				size = { { 0, 0 }, { 0.35, 4.2 }, { 1, 4.4 } }, transparency = { { 0, 1 }, { 0.45, 0.72 }, { 1, 1 } },
				colors = { { 0, 255, 235, 160 }, { 1, 255, 235, 160 } },
				emission = 1, brightness = 1.5, rotation = { -180, 180 }, rotSpeed = { -35, 35 }, zOffset = -3,
				locked = true, inherit = 0,
			},
			{ -- golden-white sparkles drifting up behind (LuckyBlocks Divine Block Sparkles)
				name = "HolySparkles", at = BACK, texture = "rbxassetid://87209923432166",
				rate = 14, lifetime = { 0.6, 1 }, speed = { 1.5, 3.5 }, spread = { 180, 180 }, direction = "Back",
				size = { { 0, 0 }, { 0.3, 0.5 }, { 1, 0 } }, transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
				colors = { { 0, 255, 255, 235 }, { 1, 255, 215, 90 } },
				emission = 1, brightness = 2, acceleration = { 0, 2.5, 0 }, drag = 1.5, rotation = { -180, 180 },
				rotSpeed = { -20, 20 }, locked = false, inherit = 0.3,
			},
		},
		-- a glowing halo above the head: two semicircle Beams (cubic Bezier k = 4/3 r)
		halo = { radius = 0.6, above = 0.4, width = 0.14, colors = { { 0, 255, 238, 150 }, { 1, 255, 238, 150 } }, brightness = 3 },
	},
}

local function log(fmt, ...)
	print(string.format("[post_trail_fx] " .. fmt, ...))
end

local function colorSeq(points)
	local keypoints = {}
	for _, p in ipairs(points) do
		table.insert(keypoints, ColorSequenceKeypoint.new(p[1], Color3.fromRGB(p[2], p[3], p[4])))
	end
	return ColorSequence.new(keypoints)
end

local function numberSeq(points)
	local keypoints = {}
	for _, p in ipairs(points) do
		table.insert(keypoints, NumberSequenceKeypoint.new(p[1], p[2], p[3] or 0))
	end
	return NumberSequence.new(keypoints)
end

local function range(pair, fallback)
	pair = pair or fallback
	return NumberRange.new(pair[1], pair[2])
end

local function new(className, name, parent)
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

local function attachment(name, parent, position)
	local a = new("Attachment", name, parent)
	a.CFrame = CFrame.new(position)
	return a
end

-- A camera-facing ribbon between a0 and a1 (the width is their distance).
local function ribbonTrail(name, parent, a0, a1, spec)
	local trail = new("Trail", name, parent)
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Enabled = true
	trail.FaceCamera = true
	trail.Lifetime = spec.lifetime
	trail.MinLength = 0.1
	trail.MaxLength = spec.maxLength or capLength(spec.lifetime)
	trail.WidthScale = numberSeq(spec.taper or TAPER)
	trail.Transparency = numberSeq(spec.transparency or FADE)
	trail.Color = colorSeq(spec.colors)
	trail.LightEmission = spec.emission or 1
	trail.LightInfluence = 0
	trail.Brightness = spec.brightness or 2
	trail.TextureMode = Enum.TextureMode.Stretch
	trail.TextureLength = 1
	trail.TextureContent = if spec.texture then Content.fromUri(spec.texture) else Content.none
	return trail
end

-- Layer 1: rebuild every Assets.Trails ribbon. Everything but the weld is replaced.
local function polishRibbons(trailAssets)
	local done = {}
	for trailId, spec in pairs(Step.RIBBONS) do
		local part = trailAssets:FindFirstChild(trailId)
		if part and part:IsA("BasePart") and part:FindFirstChild("MainPartTrailWeldConstraint") then
			for _, child in ipairs(part:GetChildren()) do
				if child.Name ~= "MainPartTrailWeldConstraint" then
					child:Destroy()
				end
			end
			part.Transparency = 1
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			local a1 = attachment("MainTrailAttachment1", part, Vector3.new(spec.width / 2, 0, 0))
			local a2 = attachment("MainTrailAttachment2", part, Vector3.new(-spec.width / 2, 0, 0))
			ribbonTrail("Trail", a2, a1, a2, {
				lifetime = spec.lifetime,
				maxLength = spec.maxLength,
				colors = spec.colors,
				emission = spec.emission,
				brightness = spec.brightness,
				texture = Step.RIBBON_TEXTURE,
			})
			table.insert(done, trailId)
		else
			log("WARNING: Assets.Trails.%s missing or without MainPartTrailWeldConstraint, ribbon left as is", trailId)
		end
	end
	table.sort(done)
	return done
end

local function emitter(spec, parent)
	local e = new("ParticleEmitter", spec.name, parent)
	e.TextureContent = Content.fromUri(spec.texture)
	e.Enabled = true
	e.Rate = spec.rate
	e.Lifetime = range(spec.lifetime)
	e.Speed = range(spec.speed)
	e.SpreadAngle = Vector2.new(spec.spread[1], spec.spread[2])
	e.EmissionDirection = Enum.NormalId[spec.direction]
	e.Size = numberSeq(spec.size)
	e.Transparency = numberSeq(spec.transparency)
	e.Color = colorSeq(spec.colors)
	e.LightEmission = spec.emission
	e.LightInfluence = 0
	e.Brightness = spec.brightness
	e.ZOffset = spec.zOffset or 0
	e.Rotation = range(spec.rotation, { 0, 0 })
	e.RotSpeed = range(spec.rotSpeed, { 0, 0 })
	local acc = spec.acceleration or { 0, 0, 0 }
	e.Acceleration = Vector3.new(acc[1], acc[2], acc[3])
	e.Drag = spec.drag or 0
	e.LockedToPart = spec.locked
	e.VelocityInheritance = spec.inherit
	e.Orientation = Enum.ParticleOrientation[spec.orientation or "FacingCamera"]
	e.Squash = numberSeq(spec.squash or { { 0, 0 }, { 1, 0 } })
	e.TimeScale = 1
	if spec.flipbook then
		e.FlipbookLayout = Enum.ParticleFlipbookLayout[spec.flipbook.layout]
		e.FlipbookMode = Enum.ParticleFlipbookMode[spec.flipbook.mode]
		e.FlipbookFramerate = NumberRange.new(spec.flipbook.fps or 1, spec.flipbook.fps or 1)
		e.FlipbookStartRandom = false
	else
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.None
	end
	return e
end

-- The halo: HaloLeft / HaloRight on the Head, their X axis turned to +Z so the Bezier control points (CurveSize along
-- Attachment0's axis, minus CurveSize1 along Attachment1's) bulge behind (HaloBack) and in front (HaloFront).
local function buildHalo(folder, spec)
	local turn = CFrame.Angles(0, -math.pi / 2, 0)
	local left = new("Attachment", "HaloLeft", folder)
	left.CFrame = CFrame.new(-spec.radius, 0, 0) * turn
	local right = new("Attachment", "HaloRight", folder)
	right.CFrame = CFrame.new(spec.radius, 0, 0) * turn
	for _, a in ipairs({ left, right }) do
		a:SetAttribute("TrailFxMount", "Head")
		a:SetAttribute("TrailFxAbove", spec.above)
	end
	local k = 4 / 3 * spec.radius
	for _, half in ipairs({ { "HaloBack", k }, { "HaloFront", -k } }) do
		local beam = new("Beam", half[1], left)
		beam.Attachment0 = left
		beam.Attachment1 = right
		beam.CurveSize0 = half[2]
		beam.CurveSize1 = -half[2]
		beam.Segments = 16
		beam.Width0 = spec.width
		beam.Width1 = spec.width
		beam.FaceCamera = true
		beam.Color = colorSeq(spec.colors)
		beam.Transparency = numberSeq({ { 0, 0.1 }, { 1, 0.1 } })
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Brightness = spec.brightness
		beam.TextureContent = Content.none
		beam.Enabled = true
	end
end

-- Layer 2: one Folder of Attachments per Legendary+ trail.
local function buildTheme(parent, trailId, spec, ribbon)
	local folder = new("Folder", trailId, parent)
	folder:SetAttribute("Theme", spec.theme)

	local coreA = attachment("FxCoreA", folder, Vector3.new(spec.core.width / 2, 0, 0.1))
	local coreB = attachment("FxCoreB", folder, Vector3.new(-spec.core.width / 2, 0, 0.1))
	ribbonTrail("CoreTrail", coreB, coreA, coreB, {
		lifetime = math.max(0.15, (ribbon and ribbon.lifetime or 0.26) - 0.08), -- MaxLength: capLength(Lifetime)
		colors = spec.core.colors,
		emission = spec.core.emission,
		brightness = spec.core.brightness,
		transparency = spec.core.transparency or { { 0, 0 }, { 0.5, 0.25 }, { 1, 1 } },
		taper = { { 0, 1 }, { 1, 0.2 } },
	})

	local body = attachment("FxBody", folder, BODY)
	local light = new("PointLight", "FxLight", body)
	light.Color = Color3.fromRGB(spec.light.color[1], spec.light.color[2], spec.light.color[3])
	light.Brightness = spec.light.brightness
	light.Range = spec.light.range
	light.Shadows = false
	light.Enabled = true

	local byPosition = { [tostring(BODY)] = body }
	local count = 0
	for _, e in ipairs(spec.emitters) do
		local key = tostring(e.at)
		local host = byPosition[key]
		if host == nil then
			host = attachment(if e.at == BACK then "FxBack" else "Fx" .. e.name, folder, e.at)
			byPosition[key] = host
		end
		emitter(e, host)
		count += 1
	end
	if spec.halo then
		buildHalo(folder, spec.halo)
	end
	return count
end

-- Every TextureContent uri used by an emitter / beam / trail of the place (checked before this step adds its own).
local function knownTextures(place)
	local known = {}
	for _, d in ipairs(place:GetDescendants()) do
		if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
			local ok, uri = pcall(function()
				return (d :: any).TextureContent.Uri
			end)
			local id = ok and type(uri) == "string" and string.match(uri, "(%d+)$")
			if id then
				known[id] = true
			end
		end
	end
	return known
end

function Step.Apply(place, _spPlace, _ctx)
	local rs = place:GetService("ReplicatedStorage")
	local assets = rs:FindFirstChild("Assets")
	local trailAssets = assets and assets:FindFirstChild("Trails")
	assert(trailAssets, "ReplicatedStorage.Assets.Trails missing")

	local known = knownTextures(place)
	local unknown = {}
	local function checkTexture(uri)
		local id = uri and string.match(uri, "^rbxassetid://(%d+)$")
		if id and not known[id] then
			table.insert(unknown, uri)
		end
	end
	checkTexture(Step.RIBBON_TEXTURE)
	for _, spec in pairs(Step.THEMES) do
		for _, e in ipairs(spec.emitters) do
			checkTexture(e.texture)
		end
	end

	local ribbons = polishRibbons(trailAssets)

	local old = assets:FindFirstChild(Step.FX_FOLDER)
	while old do
		old:Destroy()
		old = assets:FindFirstChild(Step.FX_FOLDER)
	end
	local fxFolder = new("Folder", Step.FX_FOLDER, assets)
	fxFolder:SetAttribute("MinRarityNumber", Step.MIN_FX_RARITY)
	local themed, emitters = {}, 0
	for trailId, spec in pairs(Step.THEMES) do
		if trailAssets:FindFirstChild(trailId) then
			emitters += buildTheme(fxFolder, trailId, spec, Step.RIBBONS[trailId])
			table.insert(themed, trailId .. " (" .. spec.theme .. ")")
		else
			log("WARNING: no Assets.Trails.%s, its %s FX was not built", trailId, spec.theme)
		end
	end
	table.sort(themed)

	for _, uri in ipairs(unknown) do
		log("WARNING: texture %s is no longer used anywhere else in the place (check it still exists)", uri)
	end
	log("polished %d ribbons; built %d themed FX (%d emitters): %s", #ribbons, #themed, emitters, table.concat(themed, ", "))
end

return Step
