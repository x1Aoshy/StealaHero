-- StarterPlayerScripts.Game.StageWeather (docs/HERO_MODELS_PLAN.md H5, injected by scripts/inject/weather.luau)
-- Justice League (Lake) rain, built the way the owner's ZeroDown weather does it (ReplicatedStorage.Shared.Replication.
-- Global.Weather + Workspace.Map.Weather.Drops / Splashes) and RobloxBall's WeatherController refines it:
--   * a rain CEILING that follows the camera (unrotated sheet ~42 studs above it) emitting streaks downward; the
--     particles are NOT locked to the sheet, so they stay where they fall while the sheet moves with you;
--   * a small NEAR sheet just above the camera with bigger, fainter streaks for depth;
--   * ground SPLASHES on the real surfaces: raycasts from above pick where drops land (floor, roofs, props, other
--     players) and a pool of attachments emits a flat ripple ring, a few droplets and a small puff there with :Emit;
--   * a low street MIST and rare LIGHTNING flashes (a ColorCorrectionEffect under the camera, like ZeroDown's storm);
--   * the darker sky / atmosphere / clouds / colour grading is StageAmbience's stage-2 preset (LightingsController
--     modifier); both scripts fade over ~2 s when the player crosses into or out of the stage.
-- It only rains while the local player is inside the Lake stage: the region of Workspace.StageEnvironments.Lake.Rain.
-- RainVolume (the stage X range between the side walls, built by scripts/steps/env_a.luau; the owner can move / resize
-- it in Studio and set its attributes Intensity (0..3), Lightning (bool), StreakTexture (optional image for the streaks)).
-- Without the marker the stage's X range 169.5..315.6 (StageAmbience's stage 2) is used.
-- Everything is created once, on the first visit, and reused: per frame only CFrames, a few rates and a handful of
-- raycasts change. Emission scales with the graphics quality (Library.Functions.GraphicsQuality, which also honours
-- the game's potato mode and mobile). Built-in rbxasset:// textures only (they load in every experience); no sounds
-- (audio whitelist).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Where and when ------------------------------------------------------------------------------------------------
local MARKER_PATH = { "StageEnvironments", "Lake", "Rain", "RainVolume" }
local FALLBACK_REGION = { xMin = 169.5, xMax = 315.6, zMin = -85.5, zMax = 81.5, floorY = 2.08 }
local Z_PADDING = 6 -- the marker covers the floor band; the rain reaches the side walls (Z -88 / +86)
local POLL_SECONDS = 0.25 -- region check (StageAmbience polls at the same rate)
local FADE_IN_SECONDS = 2 -- StageAmbience's lighting transition takes 2 s too
local FADE_OUT_SECONDS = 1.5
local QUALITY_SECONDS = 3

-- Look (built-in engine particle textures) ------------------------------------------------------------------------
local TEXTURE_STREAK = "rbxasset://textures/particles/explosion01_implosion_main.dds" -- soft round glow, squashed = tapered streak
local TEXTURE_RIPPLE = "rbxasset://textures/particles/explosion01_shockwave_main.dds" -- thin ring, laid flat = ripple
local TEXTURE_MIST = "rbxasset://textures/particles/smoke_main.dds"
local RAIN_COLOR = Color3.fromRGB(172, 192, 226)
local SPLASH_COLOR = Color3.fromRGB(200, 214, 240)
local MIST_COLOR = Color3.fromRGB(128, 142, 172)
local FLASH_TINT = Color3.fromRGB(226, 234, 255)

local FALL_SPEED_MIN, FALL_SPEED_MAX = 105, 125
local CEILING_HEIGHT = 42 -- the far sheet, above the camera (or the street, whichever is higher)
local FAR_SIZE_MIN, FAR_SIZE_MAX = 84, 120 -- side of the far sheet at the lowest / highest quality
local FAR_DENSITY = 0.085 -- streaks per stud^2 per second at full quality
local FAR_EMITTERS = 3 -- the far rate is split so no emitter goes over MAX_EMITTER_RATE
local NEAR_HEIGHT = 16
local NEAR_SIZE = 34
local NEAR_DENSITY = 0.14
local NEAR_MIN_QUALITY = 0.4
local MAX_EMITTER_RATE = 420
local SPLASH_RATE = 260 -- splashes per second at full quality
local SPLASH_RADIUS = 40
local SPLASH_POOL = 24
local SPLASHES_PER_FRAME = 10 -- <= SPLASH_POOL: a pooled attachment is never moved twice in one frame
local PROBE_ABOVE = 60
local PROBE_DEPTH = 240
local SHELTER_PROBE = 90
local SHELTER_SECONDS = 0.3
local SHELTERED_RATE = 0.15 -- under a roof most of the streaks are hidden (they would fall through it)
local MIST_RATE = 5
local MIST_MIN_QUALITY = 0.55
local LIGHTNING_MIN, LIGHTNING_MAX = 12, 26
local FLASH_STEPS = { { 0.24, 0.05 }, { 0.05, 0.07 }, { 0.16, 0.05 }, { 0.03, 0.12 } } -- { brightness, seconds }
local MAX_EXCLUDED = 96

-- State -------------------------------------------------------------------------------------------------------------
local region = table.clone(FALLBACK_REGION)
region.zMin, region.zMax = FALLBACK_REGION.zMin - Z_PADDING, FALLBACK_REGION.zMax + Z_PADDING
local intensity = 1
local lightningEnabled = true
local customStreakTexture = ""

local built = false
local folder, flash
local farSheet, nearSheet, mistSheet, splashAnchor
local farEmitters, nearEmitter, mistEmitter = {}, nil, nil
local pool, poolIndex = {}, 0
local lastRate = {} -- emitter -> rate last written (never read engine properties back)
local lastSize = {} -- sheet -> size last written
local lastLifetime = {} -- emitter -> lifetime last written
local appliedStreakTexture = nil

local weight, target = 0, 0
local running, renderConnection = false, nil
local quality, qualityTimer, qualityFn, qualityLookedUp = 0.68, 0, nil, false
local shelter, shelterTimer, sheltered = 1, 0, false
local splashBudget = 0
local lightningTimer, flashing = 0, false
local clock = 0

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false
local excluded = {}

-- Helpers -------------------------------------------------------------------------------------------------------------
local function approach(value, goal, step)
	if value < goal then
		return math.min(goal, value + step)
	end
	return math.max(goal, value - step)
end

local function seq(points)
	local keypoints = {}
	for _, p in ipairs(points) do
		table.insert(keypoints, NumberSequenceKeypoint.new(p[1], p[2], p[3] or 0))
	end
	return NumberSequence.new(keypoints)
end

local function readQuality()
	if not qualityLookedUp then
		pcall(function()
			local library = ReplicatedStorage:FindFirstChild("Library")
			local functions = library and library:FindFirstChild("Functions")
			local module = functions and functions:FindFirstChild("GraphicsQuality")
			if module then
				qualityLookedUp = true
				local fn = require(module)
				if type(fn) == "function" then
					qualityFn = fn
				end
			end
		end)
	end
	local level = nil
	if qualityFn then
		local ok, value = pcall(qualityFn)
		if ok and type(value) == "number" then
			level = value
		end
	end
	if level == nil then
		local ok, saved = pcall(function()
			return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
		end)
		level = if ok and type(saved) == "number" and saved > 0 then saved else 6
	end
	return math.clamp(0.2 + 0.08 * level, 0.28, 1)
end

local function findMarker()
	local node = workspace
	for _, name in ipairs(MARKER_PATH) do
		node = node and node:FindFirstChild(name)
	end
	return node
end

local function readRegion()
	local marker = findMarker()
	if marker and marker:IsA("BasePart") then
		local cf, size = marker.CFrame, marker.Size
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local hx = (math.abs(r.X) * size.X + math.abs(u.X) * size.Y + math.abs(l.X) * size.Z) / 2
		local hy = (math.abs(r.Y) * size.X + math.abs(u.Y) * size.Y + math.abs(l.Y) * size.Z) / 2
		local hz = (math.abs(r.Z) * size.X + math.abs(u.Z) * size.Y + math.abs(l.Z) * size.Z) / 2
		local p = cf.Position
		region.xMin, region.xMax = p.X - hx, p.X + hx
		region.zMin, region.zMax = p.Z - hz - Z_PADDING, p.Z + hz + Z_PADDING
		region.floorY = p.Y - hy
		local value = marker:GetAttribute("Intensity")
		intensity = if type(value) == "number" then math.clamp(value, 0, 3) else 1
		lightningEnabled = marker:GetAttribute("Lightning") ~= false
		local texture = marker:GetAttribute("StreakTexture")
		customStreakTexture = if type(texture) == "string" then texture else ""
	else
		for key, value in pairs(FALLBACK_REGION) do
			region[key] = value
		end
		region.zMin, region.zMax = FALLBACK_REGION.zMin - Z_PADDING, FALLBACK_REGION.zMax + Z_PADDING
		intensity, lightningEnabled, customStreakTexture = 1, true, ""
	end
end

local function insideXZ(x, z)
	return x >= region.xMin and x <= region.xMax and z >= region.zMin and z <= region.zMax
end

local function focusPosition()
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		return root.Position
	end
	local camera = workspace.CurrentCamera
	return camera and camera.CFrame.Position
end

local excludedCharacter = nil
local function resetExcluded()
	table.clear(excluded)
	if folder then
		table.insert(excluded, folder)
	end
	excludedCharacter = LocalPlayer.Character
	if excludedCharacter then
		table.insert(excluded, excludedCharacter) -- no splashes on your own head, in front of the camera
	end
	rayParams.FilterDescendantsInstances = excluded
end

-- A ray that lets the rain through invisible parts (zone bounds, invisible walls, hitboxes): the first time one is
-- hit it joins the exclusion list, so it costs one extra cast once.
local function cast(origin, direction)
	for _ = 1, 3 do
		local hit = workspace:Raycast(origin, direction, rayParams)
		if not hit then
			return nil
		end
		local instance = hit.Instance
		if instance and instance:IsA("BasePart") and not instance:IsA("Terrain") and instance.Transparency >= 0.9 then
			if #excluded >= MAX_EXCLUDED then
				resetExcluded()
			end
			table.insert(excluded, instance)
			rayParams.FilterDescendantsInstances = excluded
		else
			return hit
		end
	end
	return nil
end

-- Construction (once) --------------------------------------------------------------------------------------------
local function newSheet(name, size)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = size
	part.CFrame = CFrame.new(0, -500, 0)
	part.Parent = folder
	lastSize[part] = size
	return part
end

local function newEmitter(name, parent)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.Enabled = false
	emitter.Rate = 0
	emitter.LockedToPart = false
	emitter.VelocityInheritance = 0
	emitter.Parent = parent
	lastRate[emitter] = 0
	return emitter
end

-- Streak shape: a soft round particle squashed to the maximum and aligned with its velocity reads as a tapered rain
-- streak. With VelocityParallel a POSITIVE Squash widens the particle across the fall direction (the owner saw
-- sideways streaks, 2026-09-23), so the streaks use a NEGATIVE Squash (-3 = thinnest, longest along the fall). `size` is the particle side before the squash; the first knobs to tune in
-- Studio if the streaks look too thick / short. `texturedSize` is used with a painted StreakTexture (no squash).
local STREAK_LOOK = {
	far = { size = 1.1, envelope = 0.2, squash = -3, transparency = 0.5, texturedSize = 2.2 },
	near = { size = 1.5, envelope = 0.25, squash = -3, transparency = 0.66, texturedSize = 3 },
}

local function applyStreakLook(emitter, look)
	if customStreakTexture ~= "" then
		-- a painted streak image (e.g. the ZeroDown / RobloxBall rain drop, once the owner approves the id): shown as
		-- drawn, upright, without squash
		emitter.Texture = customStreakTexture
		emitter.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
		emitter.Size = NumberSequence.new(look.texturedSize)
		emitter.Squash = NumberSequence.new(0)
	else
		emitter.Texture = TEXTURE_STREAK
		emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
		emitter.Size = seq({ { 0, look.size, look.envelope }, { 1, look.size, look.envelope } })
		emitter.Squash = NumberSequence.new(look.squash)
	end
end

local function newStreaks(name, parent, look)
	local emitter = newEmitter(name, parent)
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Speed = NumberRange.new(FALL_SPEED_MIN, FALL_SPEED_MAX)
	emitter.SpreadAngle = Vector2.new(2, 2)
	emitter.Acceleration = Vector3.new(0, -10, 0)
	emitter.Lifetime = NumberRange.new(0.5, 0.55)
	emitter.Rotation = NumberRange.new(0, 0)
	emitter.RotSpeed = NumberRange.new(0, 0)
	emitter.Color = ColorSequence.new(RAIN_COLOR)
	emitter.Transparency = seq({ { 0, 1 }, { 0.1, look.transparency }, { 0.9, look.transparency }, { 1, 0.85 } })
	emitter.LightEmission = 0.25
	emitter.LightInfluence = 0.4
	emitter.Brightness = 1.2
	applyStreakLook(emitter, look)
	lastLifetime[emitter] = 0.5
	return emitter
end

local function build()
	folder = Instance.new("Folder")
	folder.Name = "StageWeather"

	farSheet = newSheet("RainCeiling", Vector3.new(FAR_SIZE_MAX, 8, FAR_SIZE_MAX))
	for i = 1, FAR_EMITTERS do
		farEmitters[i] = newStreaks("Streaks" .. i, farSheet, STREAK_LOOK.far)
	end
	nearSheet = newSheet("RainNear", Vector3.new(NEAR_SIZE, 4, NEAR_SIZE))
	nearEmitter = newStreaks("NearStreaks", nearSheet, STREAK_LOOK.near)
	appliedStreakTexture = customStreakTexture

	mistSheet = newSheet("RainMist", Vector3.new(90, 3, 90))
	mistEmitter = newEmitter("Mist", mistSheet)
	mistEmitter.Texture = TEXTURE_MIST
	mistEmitter.Shape = Enum.ParticleEmitterShape.Box
	mistEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	mistEmitter.EmissionDirection = Enum.NormalId.Top
	mistEmitter.Speed = NumberRange.new(0.5, 1.5)
	mistEmitter.SpreadAngle = Vector2.new(80, 80)
	mistEmitter.Acceleration = Vector3.new(1.2, 0, 0.4)
	mistEmitter.Lifetime = NumberRange.new(5, 8)
	mistEmitter.Rotation = NumberRange.new(0, 360)
	mistEmitter.RotSpeed = NumberRange.new(-8, 8)
	mistEmitter.Size = seq({ { 0, 9, 2 }, { 1, 15, 3 } })
	mistEmitter.Transparency = seq({ { 0, 1 }, { 0.3, 0.9 }, { 0.7, 0.92 }, { 1, 1 } })
	mistEmitter.Color = ColorSequence.new(MIST_COLOR)
	mistEmitter.LightEmission = 0
	mistEmitter.LightInfluence = 0.8

	-- splash pool: attachments on an anchor at the origin, so Attachment.Position is the world position
	splashAnchor = newSheet("SplashAnchor", Vector3.new(1, 1, 1))
	splashAnchor.CFrame = CFrame.new(0, 0, 0)
	for i = 1, SPLASH_POOL do
		local attachment = Instance.new("Attachment")
		attachment.Name = "Splash" .. i
		attachment.Parent = splashAnchor

		local ripple = newEmitter("Ripple", attachment) -- flat ring on the ground (VelocityPerpendicular + upward velocity)
		ripple.Texture = TEXTURE_RIPPLE
		ripple.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		ripple.EmissionDirection = Enum.NormalId.Top
		ripple.Speed = NumberRange.new(0.05, 0.05)
		ripple.SpreadAngle = Vector2.new(0, 0)
		ripple.Lifetime = NumberRange.new(0.4, 0.55)
		ripple.Rotation = NumberRange.new(0, 360)
		ripple.Size = seq({ { 0, 0.3 }, { 1, 2.3, 0.3 } })
		ripple.Transparency = seq({ { 0, 0 }, { 0.6, 0.45 }, { 1, 1 } })
		ripple.Color = ColorSequence.new(SPLASH_COLOR)
		ripple.LightEmission = 0.6
		ripple.LightInfluence = 0.4
		ripple.Brightness = 1.5

		local droplets = newEmitter("Droplets", attachment) -- a few drops bouncing off the surface
		droplets.Texture = TEXTURE_STREAK
		droplets.Orientation = Enum.ParticleOrientation.VelocityParallel
		droplets.EmissionDirection = Enum.NormalId.Top
		droplets.Speed = NumberRange.new(5, 9)
		droplets.SpreadAngle = Vector2.new(35, 35)
		droplets.Acceleration = Vector3.new(0, -60, 0)
		droplets.Lifetime = NumberRange.new(0.18, 0.32)
		droplets.Size = seq({ { 0, 0.22, 0.05 }, { 1, 0.12 } })
		droplets.Squash = NumberSequence.new(-1.5)
		droplets.Transparency = seq({ { 0, 0.25 }, { 1, 1 } })
		droplets.Color = ColorSequence.new(SPLASH_COLOR)
		droplets.LightEmission = 0.4
		droplets.LightInfluence = 0.4

		local puff = newEmitter("Puff", attachment) -- the white crown of the impact
		puff.Texture = TEXTURE_STREAK
		puff.Orientation = Enum.ParticleOrientation.FacingCamera
		puff.EmissionDirection = Enum.NormalId.Top
		puff.Speed = NumberRange.new(0.5, 1)
		puff.Lifetime = NumberRange.new(0.12, 0.2)
		puff.Size = seq({ { 0, 0.45 }, { 1, 0.95 } })
		puff.Squash = NumberSequence.new(1.5)
		puff.Transparency = seq({ { 0, 0.45 }, { 1, 1 } })
		puff.Color = ColorSequence.new(SPLASH_COLOR)
		puff.LightEmission = 0.5
		puff.LightInfluence = 0.4

		pool[i] = { attachment = attachment, ripple = ripple, droplets = droplets, puff = puff }
	end

	flash = Instance.new("ColorCorrectionEffect")
	flash.Name = "StageWeatherLightning"
	flash.Enabled = false
	flash.Brightness = 0
	flash.Contrast = 0
	flash.Saturation = 0
	flash.TintColor = FLASH_TINT

	-- under the camera: local to this client, never replicated, and the post effect applies from there
	local camera = workspace.CurrentCamera
	folder.Parent = camera
	flash.Parent = camera
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local newCamera = workspace.CurrentCamera
		if newCamera then
			folder.Parent = newCamera
			flash.Parent = newCamera
		end
	end)
	resetExcluded()
	built = true
end

-- Per frame ---------------------------------------------------------------------------------------------------------
local function setRate(emitter, rate)
	rate = math.min(rate, MAX_EMITTER_RATE)
	if rate < 0.5 then
		rate = 0
	end
	local previous = lastRate[emitter] or 0
	if rate == previous then
		return
	end
	if rate == 0 or previous == 0 or math.abs(rate - previous) > math.max(1, previous * 0.03) then
		emitter.Rate = rate
		lastRate[emitter] = rate
		local on = rate > 0
		if (previous > 0) ~= on then
			emitter.Enabled = on
		end
	end
end

local function setLifetime(emitter, seconds)
	if math.abs((lastLifetime[emitter] or 0) - seconds) > 0.03 then
		emitter.Lifetime = NumberRange.new(seconds, seconds * 1.05)
		lastLifetime[emitter] = seconds
	end
end

-- Places a sheet centred at (cx, cz) with side `side`, clipped to the rain region. Returns the covered area.
local function placeSheet(sheet, cx, y, cz, side, height, tilt)
	local half = side / 2
	local x0, x1 = math.max(cx - half, region.xMin), math.min(cx + half, region.xMax)
	local z0, z1 = math.max(cz - half, region.zMin), math.min(cz + half, region.zMax)
	if x1 - x0 < 1 or z1 - z0 < 1 then
		return 0
	end
	local size = Vector3.new(x1 - x0, height, z1 - z0)
	local previous = lastSize[sheet]
	if not previous or math.abs(previous.X - size.X) > 0.25 or math.abs(previous.Z - size.Z) > 0.25 then
		sheet.Size = size
		lastSize[sheet] = size
	end
	sheet.CFrame = CFrame.new((x0 + x1) / 2, y, (z0 + z1) / 2) * tilt
	return size.X * size.Z
end

local function flashSequence()
	if flashing or not flash then
		return
	end
	flashing = true
	flash.Enabled = true
	for _, step in ipairs(FLASH_STEPS) do
		flash.Brightness = step[1] * weight
		task.wait(step[2])
	end
	flash.Brightness = 0
	flash.Enabled = false
	flashing = false
end

local function stop()
	for _, emitter in ipairs(farEmitters) do
		setRate(emitter, 0)
	end
	setRate(nearEmitter, 0)
	setRate(mistEmitter, 0)
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	running = false
	splashBudget = 0
end

local function step(dt)
	dt = math.min(dt, 0.1)
	clock += dt
	if target > weight then
		weight = approach(weight, target, dt / FADE_IN_SECONDS)
	else
		weight = approach(weight, target, dt / FADE_OUT_SECONDS)
	end
	if weight <= 0 and target <= 0 then
		stop()
		return
	end

	qualityTimer -= dt
	if qualityTimer <= 0 then
		qualityTimer = QUALITY_SECONDS
		quality = readQuality()
	end
	if customStreakTexture ~= appliedStreakTexture then
		appliedStreakTexture = customStreakTexture
		for _, emitter in ipairs(farEmitters) do
			applyStreakLook(emitter, STREAK_LOOK.far)
		end
		applyStreakLook(nearEmitter, STREAK_LOOK.near)
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local camCF = camera.CFrame
	local camPos = camCF.Position
	local look = camCF.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(0, 0, 0)

	-- is the camera under a roof? (a few times a second)
	shelterTimer -= dt
	if shelterTimer <= 0 then
		shelterTimer = SHELTER_SECONDS
		sheltered = cast(camPos, Vector3.new(0, SHELTER_PROBE, 0)) ~= nil
	end
	shelter = approach(shelter, if sheltered then SHELTERED_RATE else 1, dt * 3)

	local amount = weight * quality * intensity
	local tilt = CFrame.Angles(0.04 * math.sin(clock * 0.23), 0, 0.12 + 0.05 * math.sin(clock * 0.35))

	-- far ceiling: shifted forward so most of it is in view
	local farSide = FAR_SIZE_MIN + (FAR_SIZE_MAX - FAR_SIZE_MIN) * quality
	local ceilingY = math.max(camPos.Y, region.floorY) + CEILING_HEIGHT
	local farCenter = camPos + flat * (farSide * 0.25)
	local farArea = placeSheet(farSheet, farCenter.X, ceilingY, farCenter.Z, farSide, 8, tilt)
	local farLifetime = (ceilingY - region.floorY) / FALL_SPEED_MIN
	local farRate = FAR_DENSITY * farArea * amount * shelter / FAR_EMITTERS
	for _, emitter in ipairs(farEmitters) do
		setLifetime(emitter, farLifetime)
		setRate(emitter, farRate)
	end

	-- near sheet: bigger, fainter streaks right in front of the camera
	local nearRate = 0
	if quality >= NEAR_MIN_QUALITY then
		local nearY = camPos.Y + NEAR_HEIGHT
		local nearCenter = camPos + flat * 6
		local nearArea = placeSheet(nearSheet, nearCenter.X, nearY, nearCenter.Z, NEAR_SIZE, 4, tilt)
		setLifetime(nearEmitter, math.max(0.2, (nearY - region.floorY) / FALL_SPEED_MIN))
		nearRate = NEAR_DENSITY * nearArea * amount * shelter
	end
	setRate(nearEmitter, nearRate)

	-- mist rolling along the street
	local focus = focusPosition() or camPos
	local mistRate = 0
	if quality >= MIST_MIN_QUALITY then
		local mistArea = placeSheet(mistSheet, focus.X, region.floorY + 1.5, focus.Z, 90, 3, CFrame.new())
		mistRate = if mistArea > 0 then MIST_RATE * amount else 0
	end
	setRate(mistEmitter, mistRate)

	-- splashes where the drops land, around the player and ahead of the camera
	splashBudget = math.min(splashBudget + SPLASH_RATE * amount * dt, SPLASHES_PER_FRAME)
	if splashBudget >= 1 then
		local centerX, centerZ = focus.X + flat.X * 10, focus.Z + flat.Z * 10
		local topY = math.max(camPos.Y, focus.Y, region.floorY) + PROBE_ABOVE
		while splashBudget >= 1 do
			splashBudget -= 1
			local angle = math.random() * 2 * math.pi
			local radius = SPLASH_RADIUS * math.sqrt(math.random())
			local x, z = centerX + math.cos(angle) * radius, centerZ + math.sin(angle) * radius
			if insideXZ(x, z) then
				local hit = cast(Vector3.new(x, topY, z), Vector3.new(0, -PROBE_DEPTH, 0))
				if hit then
					poolIndex = poolIndex % SPLASH_POOL + 1
					local slot = pool[poolIndex]
					slot.attachment.Position = hit.Position + Vector3.new(0, 0.06, 0)
					if hit.Normal.Y > 0.7 then
						slot.ripple:Emit(1)
					end
					if quality >= 0.45 or math.random() < 0.5 then
						slot.droplets:Emit(math.random(2, 3))
					end
					slot.puff:Emit(1)
				end
			end
		end
	end

	-- lightning
	if lightningEnabled and weight > 0.75 then
		lightningTimer -= dt
		if lightningTimer <= 0 then
			lightningTimer = LIGHTNING_MIN + math.random() * (LIGHTNING_MAX - LIGHTNING_MIN)
			task.spawn(flashSequence)
		end
	end
end

local warned = {}
local function warnOnce(err)
	local message = "[StageWeather] " .. tostring(err)
	if not warned[message] then
		warned[message] = true
		warn(message)
	end
end

local function start()
	if not built then
		build()
	end
	resetExcluded()
	quality = readQuality()
	qualityTimer = QUALITY_SECONDS
	shelterTimer = 0
	if lightningTimer <= 0 then
		lightningTimer = 6 + math.random() * 6
	end
	running = true
	renderConnection = RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(step, dt)
		if not ok then
			warnOnce(err)
			stop()
		end
	end)
end

-- Region poll (the only loop; the per-frame work runs only while it rains or fades) -------------------------------------
while true do
	local ok, err = pcall(function()
		readRegion()
		local position = focusPosition()
		target = if position and intensity > 0 and insideXZ(position.X, position.Z) then 1 else 0
		if target > 0 and not running then
			start()
		elseif running and LocalPlayer.Character ~= excludedCharacter then
			resetExcluded() -- respawned while it rains
		end
	end)
	if not ok then
		warnOnce(err)
	end
	task.wait(POLL_SECONDS)
end
