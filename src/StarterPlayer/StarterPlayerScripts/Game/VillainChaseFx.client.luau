-- StarterPlayer.StarterPlayerScripts.Game.VillainChaseFx (LocalScript)
-- Client presentation of the stage villains' chases (docs/STAGES_PLAN.md §1 chase signatures, A2, A12).
-- Everything is driven by replicated guard attributes (GuardChaseService on the server):
--   GuardState / TargetPlayer   -> footsteps, trails, camera shake (no on-screen banner or safe-zone meter: the
--                                  owner removed them, the original game has none)
--   HeroId / ChaseSignature     -> which villain's signature to show (unknown ids: no world effect)
--   RigScale                    -> effect sizes (HEROES)
--   Hovering                    -> Frieza's hover ring
--   ChaseFx "<Kind>;<seq>;<targetUserId>;<seconds>[;<x,y,z>;<x,y,z>]"
--                               -> one-shots: Spawn / Vanish (every villain: themed teleport burst), Punch (every
--                                  villain: the catch swing), Surge (Darkseid eye beams), Leap (Carnage lunge trail),
--                                  Beam (Frieza energy beam), Roar (Kaido shockwave)
-- plus the remote "Guards: ServerHit" for the catch punch.
--
-- Signatures: Thanos heavy footstep thumps + proximity camera shake; Darkseid red eye glow + eye beams on each
-- surge; Carnage lunge trail; Shigaraki decay particle trail + crumbling ground; Frieza hover ring + energy beam;
-- Kaido giant footsteps + ground-shake roar. All effects are silent (no Sound), non-colliding parts in
-- Workspace.__DEBRIS (only emitter/trail/beam attachments sit on the villain's own parts), are only built near
-- the camera and are cleaned up by Debris / when the chase ends. Spawn / Vanish play a particle-only teleport burst
-- themed per villain (teleportBurst; owner 2026-09-27). Villains wear no aura (the SabVfx fire aura is gone).
-- Camera shake: only for the chased carrier outside the safe zone, amplitude <= 0.5, off with Reduced Motion.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local LOCAL_USER_ID = tostring(LocalPlayer.UserId)

local LOOKUP_TIMEOUT = 30
local SAFE_ZONE_X = 75 -- the hub; villains stop at X = 80
local FX_RANGE = 240 -- world effects only for villains this close to the camera
local MAX_SHAKE = 0.5
local SHAKE_FREQUENCY = 20
local THUMP_MIN_INTERVAL = 0.16
local TELEPORT_STEP = 20 -- a per-frame move longer than this is a teleport, not a footstep

local AWAKE_STATES = { Waking = true, Chasing = true, Returning = true, Retrieving = true }
local MOVING_STATES = { Chasing = true, Returning = true, Retrieving = true }
local CHASE_STATES = { Waking = true, Chasing = true }

-- Legacy zones 7-9 are destroyed by the build (A1); if one is still there it is ignored.
local RETIRED_ZONES = { ["Abyss Ocean"] = true, Prehistoric = true, Cosmic = true }

local WHITE = Color3.new(1, 1, 1)
local DANGER_RED = Color3.fromRGB(230, 25, 45)
local DANGER_ORANGE = Color3.fromRGB(255, 140, 0)
local FONT = Font.fromEnum(Enum.Font.FredokaOne)

local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

-- Per-villain presentation. Sizes are multiplied by the villain's RigScale.
local VILLAINS = {
	Thanos = {
		Name = "THANOS",
		Color = Color3.fromRGB(150, 90, 215),
		Footsteps = { Stride = 4.2, Diameter = 6, Color = Color3.fromRGB(125, 100, 160), Dust = 7 },
		StepShake = { Range = 70, Amplitude = 0.35 },
		Rumble = { Range = 30, Amplitude = 0.12 },
	},
	Darkseid = { Name = "DARKSEID", Color = Color3.fromRGB(255, 45, 30), Eyes = true },
	Carnage = { Name = "CARNAGE", Color = Color3.fromRGB(215, 20, 35) },
	Shigaraki = { Name = "SHIGARAKI", Color = Color3.fromRGB(160, 160, 175), Decay = true },
	Frieza = { Name = "FRIEZA", Color = Color3.fromRGB(200, 95, 255), HoverRing = true },
	Kaido = {
		Name = "KAIDO",
		Color = Color3.fromRGB(255, 130, 40),
		Footsteps = { Stride = 4.6, Diameter = 8, Color = Color3.fromRGB(165, 115, 70), Dust = 10 },
		StepShake = { Range = 45, Amplitude = 0.18 },
		Roar = { Range = 70, Amplitude = 0.5 },
	},
}
local DEFAULT_VILLAIN_COLOR = Color3.fromRGB(255, 60, 60)

local SIGNATURE_ALIASES = {
	{ "thanos", "Thanos" },
	{ "darkseid", "Darkseid" },
	{ "carnage", "Carnage" },
	{ "shigaraki", "Shigaraki" },
	{ "frieza", "Frieza" },
	{ "freeza", "Frieza" },
	{ "kaido", "Kaido" },
}

local function resolveSignatureKey(heroId)
	if type(heroId) ~= "string" or heroId == "" then
		return nil
	end
	local normalized = string.lower((string.gsub(heroId, "[^%w]", "")))
	for _, alias in ipairs(SIGNATURE_ALIASES) do
		if normalized == alias[1] then
			return alias[2]
		end
	end
	for _, alias in ipairs(SIGNATURE_ALIASES) do
		if string.find(normalized, alias[1], 1, true) then
			return alias[2]
		end
	end
	return nil
end

local function isRetiredZone(zone)
	return RETIRED_ZONES[zone.Name] == true or zone:GetAttribute("Retired") == true
end

local function isInSafeZone(position)
	return position.X <= SAFE_ZONE_X
end

local function getMyRoot()
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function parsePosition(text)
	if type(text) ~= "string" or text == "" then
		return nil
	end
	local x, y, z = string.match(text, "^(-?[%d%.]+),(-?[%d%.]+),(-?[%d%.]+)$")
	if not x then
		return nil
	end
	return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end

---------------------------------------------------------------------------------------------------
-- Effect helpers (all local, silent, non-colliding)
---------------------------------------------------------------------------------------------------

local fxFolder = nil
local function getFxFolder()
	if fxFolder and fxFolder.Parent then
		return fxFolder
	end
	local debris = Workspace:FindFirstChild("__DEBRIS")
	if not debris then
		debris = Instance.new("Folder")
		debris.Name = "__DEBRIS"
		debris.Parent = Workspace
	end
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "VillainChaseFx"
	fxFolder.Parent = debris
	return fxFolder
end

local function newFxPart(name, shape, size, cframe, color, transparency, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.Neon
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = getFxFolder()
	return part
end

local FLAT = CFrame.Angles(0, 0, math.pi / 2) -- a Cylinder's axis is X: lay it flat as a disc

-- Teleport VFX (owner 2026-09-27: "no weird part effect, emit a TP VFX that fits the villain's theme and colour").
-- Particles only, textures from the V40 SAB reference effects (egg glow / rays / pixel stars / space puffs /
-- lightning arcs / pixel blobs / pixel smoke / fire specs): a soft flash, rays, sparkles and a smoke puff at the feet
-- in the villain's colour, plus one themed layer. Sizes follow the villain's RigScale.
local TP_TEX = {
	glow = "rbxassetid://13580351149",
	rays = "rbxassetid://3048527478",
	star = "rbxassetid://8733414465",
	pixelStar = "rbxassetid://13448020277",
	puff = "rbxassetid://11866495294",
	space = "rbxassetid://92739826225814",
	arc = "rbxassetid://13778464872",
	blob = "rbxassetid://8733488500",
	decay = "rbxassetid://11847035494",
	fire = "rbxassetid://123944207040840",
	wave = "rbxassetid://119676097455144", -- CrystalSpinWheel "Waves": a soft ring, drawn flat on the ground
	ring = "rbxassetid://14444570452", -- Witch Fuse "shockwave1Ring" flipbook
}
-- V40 4x4 flipbook sheets (every V40 emitter using them sets Grid4x4, nearly all OneShot: one animation per particle
-- life). Without the layout Roblox draws the whole sheet, a grid of 16 tiny frames (owner 2026-09-27: "the TP
-- flipbooks are wrong, badly emitted").
local TP_FLIPBOOK = {
	star = true, pixelStar = true, puff = true, space = true, arc = true, blob = true, decay = true, fire = true, ring = true,
}

local function seq(points)
	local keys = {}
	for _, p in ipairs(points) do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

-- spec: tex, count, life {min,max}, size (points, x scale), speed {min,max} (x scale), spread, drag, accel (x scale),
-- light, rotation, transparency points, colour mix toward white (0..1) or a fixed colour
local TP_BASE = {
	{ tex = "glow", count = 2, life = { 0.35, 0.45 }, size = { { 0, 0 }, { 0.3, 7 }, { 1, 0 } }, speed = { 0, 0 }, light = 1, transparency = { { 0, 0.15 }, { 1, 1 } } },
	{ tex = "rays", count = 6, life = { 0.45, 0.6 }, size = { { 0, 0 }, { 1, 4.5 } }, speed = { 0, 0 }, light = 1, rotation = true, mix = 0.3,
		transparency = { { 0, 0.2 }, { 1, 1 } } },
	{ tex = "star", count = 16, life = { 0.4, 0.8 }, size = { { 0, 0.45 }, { 1, 0 } }, speed = { 8, 16 }, spread = 180, drag = 4, light = 1, mix = 0.45 },
}
local TP_PUFF = { tex = "puff", count = 10, life = { 0.5, 0.8 }, size = { { 0, 1.5 }, { 1, 3 } }, speed = { 5, 9 }, spread = 85, drag = 5, light = 0,
	rotation = true, dark = 0.45, transparency = { { 0, 0.45 }, { 1, 1 } } }
local TP_THEME = {
	Thanos = { tex = "space", count = 6, life = { 0.6, 0.9 }, size = { { 0, 0.8 }, { 0.4, 2.2 }, { 1, 0 } }, speed = { 3, 6 }, spread = 180, drag = 3, light = 0, rotation = true },
	Darkseid = { tex = "arc", count = 5, life = { 0.08, 0.2 }, size = { { 0, 4 }, { 1, 4 } }, speed = { 0, 0 }, light = 1, rotation = true },
	Carnage = { tex = "blob", count = 14, life = { 0.3, 0.7 }, size = { { 0, 0.8 }, { 1, 0 } }, speed = { 12, 22 }, spread = 180, accel = { 0, -30, 0 }, light = 0, dark = 0.35 },
	Shigaraki = { tex = "decay", count = 10, life = { 0.8, 1.2 }, size = { { 0, 1.2 }, { 1, 2.2 } }, speed = { 2, 5 }, spread = 180, accel = { 0, 3, 0 }, light = 0, rotation = true,
		transparency = { { 0, 0.3 }, { 1, 1 } } },
	Frieza = { tex = "pixelStar", count = 14, life = { 0.5, 0.9 }, size = { { 0, 0.5 }, { 1, 0 } }, speed = { 4, 9 }, spread = 60, accel = { 0, 14, 0 }, light = 1, mix = 0.25 },
	Kaido = { tex = "fire", count = 14, life = { 0.4, 0.8 }, size = { { 0, 1.2 }, { 1, 0 } }, speed = { 6, 12 }, spread = 70, accel = { 0, 10, 0 }, light = 0.6 },
}

-- extra spec keys: flat (lies on the ground: VelocityPerpendicular, emitted straight up at a crawl), brightness, zOffset
local function tpEmitter(host, spec, color, scale, strength)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Tp_" .. spec.tex
	e.Texture = TP_TEX[spec.tex]
	if TP_FLIPBOOK[spec.tex] then
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		e.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	end
	if spec.flat then
		e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	end
	if spec.brightness then
		e.Brightness = spec.brightness
	end
	if spec.zOffset then
		e.ZOffset = spec.zOffset
	end
	e.Enabled = false
	e.LightEmission = spec.light or 0
	e.LightInfluence = 0
	e.Lifetime = NumberRange.new(spec.life[1], spec.life[2])
	local speed = spec.speed or (if spec.flat then { 0.01, 0.01 } else { 0, 0 })
	e.Speed = NumberRange.new(speed[1] * scale, speed[2] * scale)
	local spread = spec.spread or 0
	e.SpreadAngle = Vector2.new(spread, spread)
	e.EmissionDirection = Enum.NormalId.Top
	e.Drag = spec.drag or 0
	local a = spec.accel or { 0, 0, 0 }
	e.Acceleration = Vector3.new(a[1], a[2], a[3]) * scale
	local points = {}
	for _, p in ipairs(spec.size) do
		table.insert(points, { p[1], p[2] * scale })
	end
	e.Size = seq(points)
	e.Transparency = seq(spec.transparency or { { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } })
	if spec.rotation then
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-60, 60)
	end
	local c = color
	if spec.mix then
		c = c:Lerp(WHITE, spec.mix)
	elseif spec.dark then
		c = c:Lerp(Color3.new(0, 0, 0), spec.dark)
	end
	e.Color = ColorSequence.new(c)
	e.Parent = host
	if spec.count > 0 and strength > 0 then
		e:Emit(math.max(1, math.floor(spec.count * strength + 0.5)))
	end
	return e
end

-- One teleport burst at `position` (the villain's root) with a smoke puff at its feet.
local function teleportBurst(entry, position, strength)
	local scale = entry.scale
	local color = entry.color
	local host = newFxPart("VillainFxTeleport", Enum.PartType.Block, Vector3.new(1, 1, 1) * scale, CFrame.new(position), WHITE, 1)
	for _, spec in ipairs(TP_BASE) do
		tpEmitter(host, spec, color, scale, strength)
	end
	local theme = entry.key and TP_THEME[entry.key]
	if theme then
		tpEmitter(host, theme, color, scale, strength)
	end
	local feet = newFxPart("VillainFxTeleportFeet", Enum.PartType.Block, Vector3.new(2, 0.2, 2) * scale,
		CFrame.new(position - Vector3.new(0, 3 * scale, 0)), WHITE, 1)
	tpEmitter(feet, TP_PUFF, color, scale, strength)
	Debris:AddItem(host, 2.5)
	Debris:AddItem(feet, 2.5)
end

-- Ground ring (footstep thump, landing, shockwave; owner 2026-09-27: "remove that ugly mesh when they step, put a
-- nice VFX"): particles only, a soft wave ring lying flat on the floor growing from `fromDiameter` to `toDiameter`,
-- plus a flipbook shockwave ring on the big ones. Same signature as the old Neon disc it replaces.
local function pulseDisc(position, color, fromDiameter, toDiameter, duration, transparency)
	local host = newFxPart("VillainFxGround", Enum.PartType.Block, Vector3.new(1, 0.1, 1), CFrame.new(position + Vector3.new(0, 0.05, 0)), WHITE, 1)
	local alpha = math.clamp(transparency or 0.3, 0, 0.9)
	tpEmitter(host, {
		tex = "wave", flat = true, count = 1, life = { duration, duration }, light = 1, brightness = 2, zOffset = 0.05,
		size = { { 0, fromDiameter * 0.6 }, { 1, toDiameter * 0.6 } }, transparency = { { 0, alpha }, { 0.6, 0.55 }, { 1, 1 } },
	}, color, 1, 1)
	if toDiameter >= 12 then
		tpEmitter(host, {
			tex = "ring", flat = true, count = 1, life = { duration * 0.7, duration * 0.7 }, light = 1, brightness = 2,
			size = { { 0, 0 }, { 0.15, toDiameter * 0.35 }, { 1, toDiameter * 0.55 } }, transparency = { { 0, 0.1 }, { 0.5, 0.3 }, { 1, 1 } },
		}, color, 1, 1)
	end
	Debris:AddItem(host, duration + 0.3)
	return host
end

-- One shared invisible host moved to a point and emitting a burst (particles stay in world space).
local burstHost, dustEmitter, sparkEmitter = nil, nil, nil
local function ensureBurstHost()
	if burstHost and burstHost.Parent then
		return
	end
	burstHost = newFxPart("VillainFxEmitters", Enum.PartType.Block, Vector3.new(1, 0.2, 1), CFrame.new(0, -500, 0), WHITE, 1)
	dustEmitter = Instance.new("ParticleEmitter")
	dustEmitter.Name = "Dust"
	dustEmitter.Texture = TP_TEX.puff
	dustEmitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	dustEmitter.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	dustEmitter.Enabled = false
	dustEmitter.Lifetime = NumberRange.new(0.6, 1.1)
	dustEmitter.Speed = NumberRange.new(6, 12)
	dustEmitter.SpreadAngle = Vector2.new(80, 80)
	dustEmitter.Drag = 4
	dustEmitter.Acceleration = Vector3.new(0, 4, 0)
	dustEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3) })
	dustEmitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	dustEmitter.Rotation = NumberRange.new(0, 360)
	dustEmitter.RotSpeed = NumberRange.new(-40, 40)
	dustEmitter.Parent = burstHost
	sparkEmitter = Instance.new("ParticleEmitter")
	sparkEmitter.Name = "Spark"
	sparkEmitter.Texture = TP_TEX.blob
	sparkEmitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	sparkEmitter.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	sparkEmitter.Enabled = false
	sparkEmitter.LightEmission = 1
	sparkEmitter.Lifetime = NumberRange.new(0.4, 0.8)
	sparkEmitter.Speed = NumberRange.new(10, 22)
	sparkEmitter.SpreadAngle = Vector2.new(180, 180)
	sparkEmitter.Drag = 3
	sparkEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	sparkEmitter.Parent = burstHost
end

-- Built at startup (hidden under the map) so the first spawn / footstep burst does not create it mid-chase.
pcall(ensureBurstHost)

local function emitAt(kind, position, count, color, sizeScale)
	ensureBurstHost()
	local emitter = if kind == "Spark" then sparkEmitter else dustEmitter
	burstHost.CFrame = CFrame.new(position)
	emitter.Color = ColorSequence.new(color)
	local s = sizeScale or 1
	if kind == "Spark" then
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6 * s), NumberSequenceKeypoint.new(1, 0) })
	else
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2 * s), NumberSequenceKeypoint.new(1, 3 * s) })
	end
	emitter:Emit(count)
end

-- Short-lived effects that follow something every frame (beams, charge balls). update(now) returns false
-- to end early; cleanup() always runs.
local transients = {}
local function addTransient(duration, update, cleanup)
	table.insert(transients, { endsAt = os.clock() + duration, update = update, cleanup = cleanup })
end

local function newBeam(attachment0, attachment1, color, width0, width1)
	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Color = ColorSequence.new(color)
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Segments = 1
	beam.Width0 = width0
	beam.Width1 = width1
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 0.3) })
	return beam
end

---------------------------------------------------------------------------------------------------
-- Camera shake (chased carrier only, outside the safe zone, <= MAX_SHAKE, off with Reduced Motion)
---------------------------------------------------------------------------------------------------

local shakeImpulses = {}
local shakeRumble = 0
local shakeAllowed = false
local reducedMotion = false
local reducedMotionCheckedAt = -math.huge

local function refreshReducedMotion(now)
	if now - reducedMotionCheckedAt < 2 then
		return
	end
	reducedMotionCheckedAt = now
	local ok, value = pcall(function()
		return UserSettings():GetService("UserGameSettings").ReducedMotion
	end)
	reducedMotion = ok and value == true
end

local function addShake(amplitude, duration)
	if not shakeAllowed or reducedMotion or amplitude <= 0.01 then
		return
	end
	if #shakeImpulses >= 6 then
		table.remove(shakeImpulses, 1)
	end
	table.insert(shakeImpulses, { amplitude = math.min(amplitude, MAX_SHAKE), duration = duration, startedAt = os.clock() })
end

RunService:BindToRenderStep("VillainChaseFxShake", Enum.RenderPriority.Camera.Value + 1, function()
	if not shakeAllowed or reducedMotion then
		table.clear(shakeImpulses)
		return
	end
	local now = os.clock()
	local amplitude = shakeRumble
	for index = #shakeImpulses, 1, -1 do
		local impulse = shakeImpulses[index]
		local t = (now - impulse.startedAt) / impulse.duration
		if t >= 1 then
			table.remove(shakeImpulses, index)
		else
			amplitude += impulse.amplitude * (1 - t) * (1 - t)
		end
	end
	amplitude = math.min(amplitude, MAX_SHAKE)
	if amplitude < 0.01 then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera or camera.CameraType == Enum.CameraType.Scriptable then
		return
	end
	local t = now * SHAKE_FREQUENCY
	local offset = Vector3.new(math.noise(t, 0.37), math.noise(0.61, t), 0) * 1.6
	if offset.Magnitude > 1 then
		offset = offset.Unit
	end
	offset *= amplitude -- never more than MAX_SHAKE studs
	local rotation = CFrame.Angles(math.noise(t, 2.3) * amplitude * 0.035, math.noise(3.1, t) * amplitude * 0.035, 0)
	camera.CFrame = camera.CFrame * CFrame.new(offset) * rotation
end)

---------------------------------------------------------------------------------------------------
-- Guard tracking
---------------------------------------------------------------------------------------------------

local entries = {} -- Guard Model -> entry

local function readScale(guard, hrp)
	local scale = tonumber(guard:GetAttribute("RigScale"))
	if not scale or scale <= 0 then
		scale = hrp.Size.Y / 2
	end
	return math.clamp(scale, 0.5, 4)
end

local function destroyPersistent(entry)
	for _, instance in ipairs(entry.persistent) do
		instance:Destroy()
	end
	table.clear(entry.persistent)
	entry.eyeParts = nil
	entry.eyeOffsets = nil
	entry.eyeHead = nil
	entry.eyeLight = nil
	entry.decayEmitter = nil
	entry.hoverRing = nil
	entry.hoverEmitters = nil
	entry.persistentBuilt = false
end

local function refreshIdentity(entry)
	local guard = entry.guard
	local signature = guard:GetAttribute("ChaseSignature")
	local key = if type(signature) == "string" and signature ~= "" then signature else resolveSignatureKey(guard:GetAttribute("HeroId"))
	local scale = readScale(guard, entry.hrp)
	if key ~= entry.key or scale ~= entry.scale then
		destroyPersistent(entry)
	end
	entry.key = key
	entry.cfg = key and VILLAINS[key] or nil
	entry.scale = scale
	entry.color = if entry.cfg then entry.cfg.Color else DEFAULT_VILLAIN_COLOR
end

local function floorY(entry)
	local humanoid = entry.humanoid
	local hip = if humanoid and humanoid.Parent then humanoid.HipHeight else 2 * entry.scale
	return entry.hrp.Position.Y - entry.hrp.Size.Y * 0.5 - hip
end

local function findBodyPart(entry, name)
	-- the villain body is flattened into the guard (a legacy nested Guard.Model is still read)
	local body = entry.guard:FindFirstChild("Model") or entry.guard
	local part = body and body:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return part
	end
	return nil
end

-- Attached effects, built the first time the villain is awake near the camera.
local function buildPersistent(entry)
	entry.persistentBuilt = true
	local cfg = entry.cfg
	if not cfg then
		return
	end
	local scale = entry.scale
	if cfg.Eyes then
		local head = findBodyPart(entry, "Head")
		if head then
			local half = head.Size * 0.5
			entry.eyeHead = head
			entry.eyeParts = {}
			entry.eyeOffsets = {}
			for _, side in ipairs({ -1, 1 }) do
				local offset = CFrame.new(side * half.X * 0.36, half.Y * 0.12, -half.Z - 0.02)
				local eye = newFxPart("VillainFxEye", Enum.PartType.Ball, Vector3.one * math.max(0.18, 0.2 * scale), head.CFrame * offset, cfg.Color, 1)
				local attachment = Instance.new("Attachment")
				attachment.Name = "BeamOrigin"
				attachment.Parent = eye
				table.insert(entry.persistent, eye)
				table.insert(entry.eyeParts, eye)
				table.insert(entry.eyeOffsets, offset)
			end
			local light = Instance.new("PointLight")
			light.Name = "VillainFxEyeGlow"
			light.Color = cfg.Color
			light.Brightness = 2
			light.Range = 8 * scale
			light.Shadows = false
			light.Parent = head
			entry.eyeLight = light
			table.insert(entry.persistent, light)
		end
	end
	if cfg.Decay then
		local attachment = Instance.new("Attachment")
		attachment.Name = "VillainFxDecay"
		attachment.Position = Vector3.new(0, -(entry.hrp.Size.Y * 0.5 + 2 * scale) + 0.4, 0.4 * scale)
		attachment.Parent = entry.hrp
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Decay"
		emitter.Texture = TP_TEX.decay
		emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		emitter.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
		emitter.Enabled = false
		emitter.Rate = 28
		emitter.Lifetime = NumberRange.new(1.2, 2)
		emitter.Speed = NumberRange.new(0.5, 2)
		emitter.SpreadAngle = Vector2.new(35, 35)
		emitter.Acceleration = Vector3.new(0, 1.5, 0)
		emitter.Drag = 1
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-30, 30)
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(175, 170, 180)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 95, 85)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 38, 40)),
		})
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4 * scale), NumberSequenceKeypoint.new(1, 1.6 * scale) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
		emitter.Parent = attachment
		entry.decayEmitter = emitter
		table.insert(entry.persistent, attachment)
	end
	if cfg.HoverRing then
		-- Frieza's hover: soft energy waves rippling on the floor under him and a few rising pixel stars (particles on an
		-- invisible host kept under the villain; no Neon ring part)
		local host = newFxPart("VillainFxHover", Enum.PartType.Block, Vector3.new(2, 0.1, 2) * scale, CFrame.new(0, -500, 0), WHITE, 1)
		local waves = tpEmitter(host, {
			tex = "wave", flat = true, count = 0, life = { 0.9, 0.9 }, light = 1, brightness = 1.5, zOffset = 0.05,
			size = { { 0, 1.2 * scale }, { 1, 3.4 * scale } }, transparency = { { 0, 0.35 }, { 0.6, 0.7 }, { 1, 1 } },
		}, cfg.Color, 1, 0)
		waves.Rate = 2.5
		local stars = tpEmitter(host, {
			tex = "pixelStar", count = 0, life = { 0.6, 1 }, size = { { 0, 0.35 }, { 1, 0 } }, speed = { 1, 2.5 }, spread = 25,
			light = 1, mix = 0.35,
		}, cfg.Color, scale, 0)
		stars.Rate = 7
		waves.Enabled, stars.Enabled = false, false
		entry.hoverRing = host
		entry.hoverEmitters = { waves, stars }
		table.insert(entry.persistent, host)
	end
end

local setPersistentAwake

-- Cold start (owner 2026-09-23: the first chase looked worse than the later ones): the attached effects are built as soon
-- as the villain is tracked (or changes identity) and kept hidden until it wakes, instead of being created in the middle
-- of the first chase.
local function prebuildPersistent(entry)
	if entry.persistentBuilt or not entry.cfg then
		return
	end
	local ok, err = pcall(buildPersistent, entry)
	if ok then
		pcall(setPersistentAwake, entry, false, false, os.clock())
	elseif not entry.warned then
		entry.warned = true
		warn("[VillainChaseFx] " .. entry.guard:GetFullName() .. ": " .. tostring(err))
	end
end

function setPersistentAwake(entry, awake, moving, now)
	if entry.eyeParts then
		local head = entry.eyeHead
		local headCFrame = head and head.Parent and head.CFrame
		for index, eye in ipairs(entry.eyeParts) do
			eye.Transparency = if awake and headCFrame then 0 else 1
			if headCFrame and awake then
				eye.CFrame = headCFrame * entry.eyeOffsets[index]
			end
		end
	end
	if entry.eyeLight then
		entry.eyeLight.Enabled = awake
		entry.eyeLight.Brightness = if now < (entry.surgeUntil or 0) then 5 else 2
	end
	if entry.decayEmitter then
		entry.decayEmitter.Enabled = moving
	end
	if entry.hoverRing then
		local hovering = awake and entry.guard:GetAttribute("Hovering") == true
		if hovering then
			local position = entry.hrp.Position
			entry.hoverRing.CFrame = CFrame.new(position.X, floorY(entry) + 0.08, position.Z)
		end
		for _, emitter in ipairs(entry.hoverEmitters or {}) do
			if emitter.Enabled ~= hovering then
				emitter.Enabled = hovering
			end
		end
	end
end

local function footPosition(entry)
	entry.stepSide = -(entry.stepSide or 1)
	local foot = findBodyPart(entry, if entry.stepSide > 0 then "LeftFoot" else "RightFoot")
	local position = if foot then foot.Position else entry.hrp.Position + entry.hrp.CFrame.RightVector * (entry.stepSide * 0.6 * entry.scale)
	return Vector3.new(position.X, floorY(entry) + 0.06, position.Z)
end

local function distanceToMe(entry, myRoot)
	if not myRoot then
		return math.huge
	end
	return (entry.hrp.Position - myRoot.Position).Magnitude
end

local function isChasingMe(entry)
	return CHASE_STATES[entry.state] == true and entry.target == LOCAL_USER_ID
end

local function thump(entry, myRoot)
	local steps = entry.cfg.Footsteps
	local scale = entry.scale
	local position = footPosition(entry)
	pulseDisc(position, steps.Color, 1.5 * scale, steps.Diameter * scale, 0.45, 0.3)
	emitAt("Dust", position, steps.Dust, steps.Color, scale)
	local shake = entry.cfg.StepShake
	if shake and isChasingMe(entry) then
		local closeness = math.clamp(1 - distanceToMe(entry, myRoot) / shake.Range, 0, 1)
		addShake(shake.Amplitude * closeness ^ 1.5, 0.28)
	end
end

local function crumblePatch(entry)
	local position = entry.hrp.Position
	local spot = Vector3.new(position.X, floorY(entry) + 0.05, position.Z) - entry.hrp.CFrame.LookVector * (0.6 * entry.scale)
	-- a grey decay ripple and crumbling pixel smoke on the floor (particles; no ground part)
	pulseDisc(spot, Color3.fromRGB(120, 108, 112), 2.4 * entry.scale, 1.4 * entry.scale, 1.6, 0.35)
	emitAt("Dust", spot, 3, Color3.fromRGB(70, 60, 64), entry.scale * 0.6)
end

local function targetRootFor(userId)
	local player = userId and userId > 0 and Players:GetPlayerByUserId(userId)
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

---------------------------------------------------------------------------------------------------
-- One-shot events (ChaseFx)
---------------------------------------------------------------------------------------------------

-- Spawn / Vanish: a themed teleport burst where the villain leaves (smaller) and where it arrives.
local function playSpawn(entry, arrival, departure)
	local camera = Workspace.CurrentCamera
	local cameraPosition = camera and camera.CFrame.Position or arrival
	if departure and (departure - cameraPosition).Magnitude <= FX_RANGE then
		teleportBurst(entry, departure, 0.6)
	end
	if arrival and (arrival - cameraPosition).Magnitude <= FX_RANGE then
		teleportBurst(entry, arrival, 1)
	end
end

-- Punch (owner 2026-09-27: "the villains need a hitting animation"): the catch swing, procedural on the villain's own
-- R15 joints (Motor6D.C0 offsets on top of whatever the Animator plays, restored afterwards): wind-up with the fist
-- pulled back and the waist turned away, a straight right punch with the waist snapping through, then recovery;
-- the left arm guards. Local to each client, broadcast by the server as ChaseFx "Punch".
local PUNCH_TIME = 0.5
local function jointAngles(x, y, z)
	return CFrame.Angles(math.rad(x), 0, 0) * CFrame.Angles(0, math.rad(y), 0) * CFrame.Angles(0, 0, math.rad(z))
end
-- phase keyframes (t, {joint = {x, y, z}}), eased between
local PUNCH_KEYS = {
	{ 0, {} },
	{ 0.22, { RightShoulder = { 35, 0, 18 }, RightElbow = { 105, 0, 0 }, Waist = { 0, -28, 0 }, LeftShoulder = { 45, 0, -10 }, LeftElbow = { 110, 0, 0 } } },
	{ 0.4, { RightShoulder = { 96, 0, 4 }, RightElbow = { 6, 0, 0 }, Waist = { 0, 24, 0 }, LeftShoulder = { 50, 0, -12 }, LeftElbow = { 115, 0, 0 } } },
	{ 0.6, { RightShoulder = { 92, 0, 4 }, RightElbow = { 10, 0, 0 }, Waist = { 0, 20, 0 }, LeftShoulder = { 48, 0, -12 }, LeftElbow = { 112, 0, 0 } } },
	{ 1, {} },
}
local PUNCH_JOINTS = { "RightShoulder", "RightElbow", "Waist", "LeftShoulder", "LeftElbow" }

local function punchPose(t)
	local a, b = PUNCH_KEYS[1], PUNCH_KEYS[#PUNCH_KEYS]
	for i = 1, #PUNCH_KEYS - 1 do
		if t >= PUNCH_KEYS[i][1] and t <= PUNCH_KEYS[i + 1][1] then
			a, b = PUNCH_KEYS[i], PUNCH_KEYS[i + 1]
			break
		end
	end
	local span = math.max(b[1] - a[1], 1e-3)
	local alpha = math.clamp((t - a[1]) / span, 0, 1)
	alpha = alpha * alpha * (3 - 2 * alpha) -- smoothstep
	local pose = {}
	for _, joint in ipairs(PUNCH_JOINTS) do
		local from = a[2][joint] or { 0, 0, 0 }
		local to = b[2][joint] or { 0, 0, 0 }
		pose[joint] = jointAngles(from[1] + (to[1] - from[1]) * alpha, from[2] + (to[2] - from[2]) * alpha, from[3] + (to[3] - from[3]) * alpha)
	end
	return pose
end

local function playPunch(entry)
	local motors = entry.punchMotors
	if motors == nil then
		motors = {}
		for _, d in ipairs(entry.guard:GetDescendants()) do
			if d:IsA("Motor6D") and table.find(PUNCH_JOINTS, d.Name) then
				-- the joint's rest C0, shared with the AreaEggs villain-carry pose (attribute VfxBaseC0)
				local base = d:GetAttribute("VfxBaseC0")
				if typeof(base) ~= "CFrame" then
					base = d.C0
					d:SetAttribute("VfxBaseC0", base)
				end
				motors[d.Name] = { motor = d, base = base }
			end
		end
		entry.punchMotors = motors
	end
	if next(motors) == nil then
		return
	end
	entry.punchToken = (entry.punchToken or 0) + 1
	local token = entry.punchToken
	local started = os.clock()
	addTransient(PUNCH_TIME, function(now)
		if entry.punchToken ~= token then
			return false -- a newer punch took over (it restores nothing: same base)
		end
		local pose = punchPose(math.clamp((now - started) / PUNCH_TIME, 0, 1))
		for name, info in pairs(motors) do
			if info.motor.Parent then
				info.motor.C0 = info.base * (pose[name] or CFrame.identity)
			end
		end
	end, function()
		if entry.punchToken == token then
			for _, info in pairs(motors) do
				if info.motor.Parent then
					info.motor.C0 = info.base
				end
			end
		end
	end)
end

local function playSurge(entry, userId, seconds)
	entry.surgeUntil = os.clock() + seconds
	if not entry.eyeParts then
		return
	end
	local target = targetRootFor(userId)
	local scale = entry.scale
	local endPart = newFxPart("VillainFxBeamEnd", Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.2), entry.hrp.CFrame, WHITE, 1)
	local endAttachment = Instance.new("Attachment")
	endAttachment.Parent = endPart
	for _, eye in ipairs(entry.eyeParts) do
		local origin = eye:FindFirstChild("BeamOrigin")
		if origin then
			local beam = newBeam(origin, endAttachment, entry.color, 0.3 * scale, 0.12 * scale)
			beam.Parent = endPart
		end
	end
	addTransient(seconds, function()
		local head = entry.eyeParts[1] and entry.eyeParts[1].Parent and entry.eyeParts[1]
		if not head then
			return false
		end
		local origin = head.Position
		local goal = if target and target.Parent then target.Position else origin + entry.hrp.CFrame.LookVector * 30
		local offset = goal - origin
		if offset.Magnitude > 40 then
			goal = origin + offset.Unit * 40
		end
		endPart.CFrame = CFrame.new(goal)
		return true
	end, function()
		endPart:Destroy()
	end)
end

local function playLeap(entry, seconds)
	local scale = entry.scale
	local position = entry.hrp.Position
	local ground = Vector3.new(position.X, floorY(entry) + 0.06, position.Z)
	pulseDisc(ground, entry.color, 2 * scale, 10 * scale, 0.4, 0.3)
	emitAt("Dust", ground, 12, Color3.fromRGB(90, 30, 35), scale)
	local torso = findBodyPart(entry, "UpperTorso") or entry.hrp
	local top = Instance.new("Attachment")
	top.Position = Vector3.new(0, 0.8 * scale, 0)
	top.Parent = torso
	local bottom = Instance.new("Attachment")
	bottom.Position = Vector3.new(0, -0.8 * scale, 0)
	bottom.Parent = torso
	local trail = Instance.new("Trail")
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Lifetime = 0.35
	trail.LightEmission = 0.3
	trail.Color = ColorSequence.new(entry.color, Color3.fromRGB(15, 5, 8))
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2) })
	trail.Parent = torso
	Debris:AddItem(trail, seconds + 0.5)
	Debris:AddItem(top, seconds + 0.5)
	Debris:AddItem(bottom, seconds + 0.5)
end

local function playBeam(entry, userId, seconds)
	local scale = entry.scale
	local color = entry.color
	local hand = findBodyPart(entry, "RightHand") or entry.hrp
	local target = targetRootFor(userId)
	local charge = newFxPart("VillainFxCharge", Enum.PartType.Ball, Vector3.one * 0.3 * scale, hand.CFrame, color, 0.1)
	local chargeTime = 0.25
	local startedAt = os.clock()
	local beamPart, beam, handAttachment, impactDone = nil, nil, nil, false
	addTransient(chargeTime + seconds, function(now)
		if not hand.Parent then
			return false
		end
		local elapsed = now - startedAt
		local handPosition = hand.Position
		local goal = if target and target.Parent then target.Position else handPosition + entry.hrp.CFrame.LookVector * 30
		if elapsed < chargeTime then
			local size = (0.3 + 1.2 * elapsed / chargeTime) * scale
			charge.Size = Vector3.one * size
			charge.CFrame = CFrame.new(handPosition)
			return true
		end
		charge.CFrame = CFrame.new(handPosition)
		if not beam then
			handAttachment = Instance.new("Attachment")
			handAttachment.Parent = hand
			beamPart = newFxPart("VillainFxBeamEnd", Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.2), CFrame.new(goal), WHITE, 1)
			local endAttachment = Instance.new("Attachment")
			endAttachment.Parent = beamPart
			beam = newBeam(handAttachment, endAttachment, color, 0.9 * scale, 0.6 * scale)
			beam.Parent = beamPart
		end
		beamPart.CFrame = CFrame.new(goal)
		local fade = math.clamp((elapsed - chargeTime) / seconds, 0, 1)
		beam.Width0 = 0.9 * scale * (1 - fade) + 0.05
		beam.Width1 = 0.6 * scale * (1 - fade) + 0.05
		if not impactDone then
			impactDone = true
			local ground = Vector3.new(goal.X, goal.Y - 2.8, goal.Z)
			pulseDisc(ground, color, 1, 8, 0.4, 0.2)
			emitAt("Spark", goal, 16, color, 1)
		end
		return true
	end, function()
		charge:Destroy()
		if beamPart then
			beamPart:Destroy()
		end
		if handAttachment then
			handAttachment:Destroy()
		end
	end)
end

local function playRoar(entry, seconds, myRoot)
	local scale = entry.scale
	local position = entry.hrp.Position
	local ground = Vector3.new(position.X, floorY(entry) + 0.08, position.Z)
	local camera = Workspace.CurrentCamera
	if camera and (position - camera.CFrame.Position).Magnitude <= FX_RANGE then
		pulseDisc(ground, entry.color, 4 * scale, 24 * scale, 0.9, 0.25)
		task.delay(0.15, function()
			pulseDisc(ground, Color3.fromRGB(255, 60, 30), 3 * scale, 16 * scale, 0.7, 0.3)
		end)
		emitAt("Dust", ground, 24, Color3.fromRGB(150, 110, 80), scale)
	end
	local roar = entry.cfg and entry.cfg.Roar
	if roar and isChasingMe(entry) then
		local closeness = math.clamp(1 - distanceToMe(entry, myRoot) / roar.Range, 0, 1)
		addShake(roar.Amplitude * closeness, seconds)
	end
end

local function onChaseFx(entry)
	local value = entry.guard:GetAttribute("ChaseFx")
	if type(value) ~= "string" then
		return
	end
	local fields = string.split(value, ";")
	local seq = tonumber(fields[2])
	if not seq or seq <= entry.lastFxSeq then
		return
	end
	entry.lastFxSeq = seq
	local kind = fields[1]
	local userId = tonumber(fields[3]) or 0
	local seconds = math.clamp(tonumber(fields[4]) or 0, 0, 5)
	local myRoot = getMyRoot()
	if kind == "Spawn" or kind == "Vanish" then
		playSpawn(entry, parsePosition(fields[5]), parsePosition(fields[6]))
		return
	end
	if kind == "Punch" then
		local camera = Workspace.CurrentCamera
		if camera == nil or (entry.hrp.Position - camera.CFrame.Position).Magnitude <= FX_RANGE then
			playPunch(entry)
		end
		return
	end
	local camera = Workspace.CurrentCamera
	local near = camera ~= nil and (entry.hrp.Position - camera.CFrame.Position).Magnitude <= FX_RANGE
	if kind == "Roar" then
		playRoar(entry, seconds, myRoot)
	elseif not near then
		return
	elseif kind == "Surge" then
		playSurge(entry, userId, seconds)
	elseif kind == "Leap" then
		playLeap(entry, seconds)
	elseif kind == "Beam" then
		playBeam(entry, userId, seconds)
	end
end

---------------------------------------------------------------------------------------------------
-- Entries
---------------------------------------------------------------------------------------------------

local function removeEntry(guard)
	local entry = entries[guard]
	if not entry then
		return
	end
	entries[guard] = nil
	for _, connection in ipairs(entry.connections) do
		connection:Disconnect()
	end
	destroyPersistent(entry)
end

local function addEntry(zone, guard, hrp)
	if entries[guard] then
		return
	end
	local humanoid = guard:FindFirstChild("Humanoid")
	local entry = {
		zone = zone,
		guard = guard,
		hrp = hrp,
		humanoid = if humanoid and humanoid:IsA("Humanoid") then humanoid else nil,
		persistent = {},
		persistentBuilt = false,
		connections = {},
		state = guard:GetAttribute("GuardState"),
		target = guard:GetAttribute("TargetPlayer"),
		lastPos = hrp.Position,
		stepAccum = 0,
		stepSide = 1,
		lastStepAt = 0,
		lastPatchAt = 0,
		lastFxSeq = 0,
		surgeUntil = 0,
	}
	-- The ChaseFx value present when we start watching is history, not an event.
	local current = guard:GetAttribute("ChaseFx")
	entry.lastFxSeq = (type(current) == "string" and tonumber(string.split(current, ";")[2])) or 0
	refreshIdentity(entry)
	entries[guard] = entry

	local function watch(attribute, callback)
		table.insert(entry.connections, guard:GetAttributeChangedSignal(attribute):Connect(callback))
	end
	watch("GuardState", function()
		entry.state = guard:GetAttribute("GuardState")
	end)
	watch("TargetPlayer", function()
		entry.target = guard:GetAttribute("TargetPlayer")
	end)
	watch("ChaseFx", function()
		local ok, err = pcall(onChaseFx, entry)
		if not ok then
			warn("[VillainChaseFx] effect failed: " .. tostring(err))
		end
	end)
	for _, attribute in ipairs({ "HeroId", "ChaseSignature", "VillainName", "RigScale" }) do
		watch(attribute, function()
			refreshIdentity(entry)
			prebuildPersistent(entry)
		end)
	end
	prebuildPersistent(entry)
	table.insert(entry.connections, guard.AncestryChanged:Connect(function()
		if not guard:IsDescendantOf(Workspace) then
			removeEntry(guard)
		end
	end))
end

local function trackZone(zone)
	if not zone:IsA("Model") or isRetiredZone(zone) then
		return
	end
	task.spawn(function()
		local guard = zone:FindFirstChild("Guard") or zone:WaitForChild("Guard", LOOKUP_TIMEOUT)
		if not guard or not guard:IsA("Model") or zone.Parent == nil then
			return
		end
		local hrp = guard:FindFirstChild("HumanoidRootPart") or guard:WaitForChild("HumanoidRootPart", LOOKUP_TIMEOUT)
		if hrp and hrp:IsA("BasePart") and guard:IsDescendantOf(Workspace) then
			addEntry(zone, guard, hrp)
		end
	end)
end

task.spawn(function()
	local objects = Workspace:WaitForChild("__OBJECTS", LOOKUP_TIMEOUT)
	local areas = objects and objects:WaitForChild("Areas", LOOKUP_TIMEOUT)
	local guardAreas = areas and areas:WaitForChild("GuardAreas", LOOKUP_TIMEOUT)
	if not guardAreas then
		warn("[VillainChaseFx] Workspace.__OBJECTS.Areas.GuardAreas not found; villain effects disabled")
		return
	end
	for _, zone in ipairs(guardAreas:GetChildren()) do
		trackZone(zone)
	end
	guardAreas.ChildAdded:Connect(trackZone)
	guardAreas.ChildRemoved:Connect(function(zone)
		for guard, entry in pairs(entries) do
			if entry.zone == zone then
				removeEntry(guard)
			end
		end
	end)
end)

---------------------------------------------------------------------------------------------------
-- The catch punch
---------------------------------------------------------------------------------------------------

task.spawn(function()
	local network = ReplicatedStorage:WaitForChild("Network", LOOKUP_TIMEOUT)
	if not network then
		return
	end
	local serverHit = network:WaitForChild("Guards: ServerHit", LOOKUP_TIMEOUT)
	if serverHit and serverHit:IsA("RemoteEvent") then
		serverHit.OnClientEvent:Connect(function()
			addShake(0.4, 0.3)
		end)
	end
end)

---------------------------------------------------------------------------------------------------
-- Frame update
---------------------------------------------------------------------------------------------------

local function updateEntry(entry, now, cameraPosition, myRoot)
	local hrp = entry.hrp
	local position = hrp.Position
	local moved = Vector3.new(position.X - entry.lastPos.X, 0, position.Z - entry.lastPos.Z).Magnitude
	entry.lastPos = position
	if moved > TELEPORT_STEP then
		moved = 0
	end

	local cfg = entry.cfg
	local awake = AWAKE_STATES[entry.state] == true
	local moving = MOVING_STATES[entry.state] == true and moved > 0.01
	if not cfg or (position - cameraPosition).Magnitude > FX_RANGE then
		if entry.persistentBuilt then
			setPersistentAwake(entry, false, false, now)
		end
		return
	end
	if awake and not entry.persistentBuilt then
		buildPersistent(entry)
	end
	if entry.persistentBuilt then
		setPersistentAwake(entry, awake, moving, now)
	end

	local steps = cfg.Footsteps
	if steps and moving then
		entry.stepAccum += moved
		if entry.stepAccum >= steps.Stride * entry.scale and now - entry.lastStepAt >= THUMP_MIN_INTERVAL then
			entry.stepAccum = 0
			entry.lastStepAt = now
			thump(entry, myRoot)
		end
	end
	if cfg.Decay and moving and now - entry.lastPatchAt >= 0.3 then
		entry.lastPatchAt = now
		crumblePatch(entry)
	end
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	refreshReducedMotion(now)
	local camera = Workspace.CurrentCamera
	local cameraPosition = if camera then camera.CFrame.Position else Vector3.zero
	local myRoot = getMyRoot()

	local chaser, chaserDistance = nil, math.huge
	for guard, entry in pairs(entries) do
		if entry.hrp.Parent == nil or guard.Parent == nil then
			removeEntry(guard)
		else
			local ok, err = pcall(updateEntry, entry, now, cameraPosition, myRoot)
			if not ok and not entry.warned then
				entry.warned = true
				warn("[VillainChaseFx] " .. guard:GetFullName() .. ": " .. tostring(err))
			end
			if isChasingMe(entry) then
				local distance = distanceToMe(entry, myRoot)
				if distance < chaserDistance then
					chaser, chaserDistance = entry, distance
				end
			end
		end
	end

	shakeAllowed = chaser ~= nil and myRoot ~= nil and not isInSafeZone(myRoot.Position)
	shakeRumble = 0
	local rumble = shakeAllowed and chaser.cfg and chaser.cfg.Rumble
	if rumble and not reducedMotion then
		local closeness = math.clamp(1 - chaserDistance / rumble.Range, 0, 1)
		shakeRumble = rumble.Amplitude * closeness * closeness
	end

	for index = #transients, 1, -1 do
		local transient = transients[index]
		local alive = now < transient.endsAt
		if alive then
			local ok, keep = pcall(transient.update, now)
			alive = ok and keep ~= false
		end
		if not alive then
			table.remove(transients, index)
			pcall(transient.cleanup)
		end
	end

end)
