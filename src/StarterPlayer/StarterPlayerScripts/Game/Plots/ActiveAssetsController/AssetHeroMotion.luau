-- StarterPlayerScripts.Game.Plots.ActiveAssetsController.AssetHeroMotion (HEROES, Gekko #7)
-- Per-hero movement style and VFX accent for one pen hero (AssetComponent owns one per component). The wander
-- simulation still decides where the hero goes; this layer returns a presentation offset (hover, bob, lean, bank, hops,
-- step dips) that AssetMovementBatch applies on top of the grounded pose, tells AssetComponent whether to play the walk
-- cycle and how fast, speeds the simulation up during a dash burst, and drives the hero's accent effects.
-- Styles and accents per hero: ReplicatedStorage.Directory.HeroMotion.
-- Authored clips (ANIMCORE, HeroClipPlayer) pose the limbs; this layer keeps moving the root on top of them. A clip
-- can scale the lift (hover / hop / dip) and the lean (lean / bank / sway) through SetClipModifiers, and pump the
-- accent (Aura / Sparks / Thrusters / Glitter / Feathers emitters and lights) during a power-up.
--
-- ANIMPOLISH: a floating hero hovers at its own HeroMotion Hover (studs at scale 1: every floater's lowest point ends
-- ~1 stud over the pen floor whatever height its Idle clip already owns); stomp dips / dust and bounce hops follow the
-- Move clip's footfalls (SetGaitPhase from HeroClipPlayer) instead of a guessed stride length; with clips the idle
-- body sway is smaller (the clip's head look does the looking around).
--
-- Cost / visibility rules: accents are built once per model from built-in rbxasset:// particle textures (no uploads,
-- no sounds, no Highlight), are only enabled within ACCENT_RANGE of the camera, and are never touched while the hero is
-- hidden (AssetComponent:SetHidden snapshots and disables every emitter/trail/light; Emit() would still spawn particles,
-- so nothing is emitted while hidden or on the silent path).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HeroMotionDirectory = nil
do
	local directory = ReplicatedStorage:FindFirstChild("Directory")
	local module = directory and directory:FindFirstChild("HeroMotion")
	if module and module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" and type(result.Get) == "function" then
			HeroMotionDirectory = result
		else
			warn("[AssetHeroMotion] Directory.HeroMotion unavailable, heroes walk: " .. tostring(result))
		end
	end
end

local FALLBACK_STYLE = { WalkCycle = true, AnimationSpeed = 1.0, LeanDegrees = 4.0, IdleSwayDegrees = 5.0 }
local REFERENCE_HEIGHT = 5.5 -- rendered height (studs) of a hero at visual scale 1
local ACCENT_RANGE = 140.0 -- accents only near the camera
local LOD_INTERVAL = 0.5
local SMOOTHING = 8.0
local STEP_DIP_SECONDS = 0.18

local TEXTURE_FIRE = "rbxasset://textures/particles/fire_main.dds"
local TEXTURE_SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local TEXTURE_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local AssetHeroMotion = {}
AssetHeroMotion.__index = AssetHeroMotion

local function sizeSequence(from: number, to: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, from), NumberSequenceKeypoint.new(1, to) })
end

local function newAttachment(part: BasePart, position: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = "HeroMotionAttachment"
	attachment.Position = position
	attachment.Parent = part
	return attachment
end

local function newEmitter(parent: Instance, properties: { [string]: any }): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "HeroMotionEmitter"
	emitter.Enabled = false
	emitter.LightInfluence = 0
	for property, value in pairs(properties) do
		emitter[property] = value
	end
	emitter.Parent = parent
	return emitter
end

local function newLight(parent: Instance, color: Color3, range: number, brightness: number): PointLight
	local light = Instance.new("PointLight")
	light.Name = "HeroMotionLight"
	light.Enabled = false
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = parent
	return light
end

local function smooth(current: number, target: number, dt: number): number
	return current + (target - current) * (1 - math.exp(-SMOOTHING * dt))
end

local function wrapAngle(angle: number): number
	return (angle + math.pi) % (2 * math.pi) - math.pi
end

function AssetHeroMotion.new(model: Model, heroId: string?, seed: number?, height: number?)
	local entry, style = nil, nil
	if HeroMotionDirectory then
		entry, style = HeroMotionDirectory.Get(heroId)
	end
	entry = entry or { Style = "walk" }
	style = style or FALLBACK_STYLE

	local self = setmetatable({}, AssetHeroMotion)
	local random = Random.new(typeof(seed) == "number" and seed or 0)
	local renderedHeight = if typeof(height) == "number" and height > 0 then height else REFERENCE_HEIGHT

	self._model = model
	self._entry = entry
	self._styleName = entry.Style
	self._style = style
	self._height = renderedHeight
	self._scale = math.clamp(renderedHeight / REFERENCE_HEIGHT, 0.15, 5.0)
	self._random = random
	self._clock = random:NextNumber(0, 20)
	self._lean = 0.0
	self._bank = 0.0
	self._sway = 0.0
	self._lift = 0.0
	self._hover = 0.0
	self._lastYaw = nil
	self._yawRate = 0.0
	self._burstRemaining = 0.0
	self._burstCooldown = random:NextNumber(0.5, 2.0)
	self._stepPhase = 0.0
	self._stepFoot = 1
	self._dipRemaining = 0.0
	self._hopPhase = 0.0
	self._lodElapsed = LOD_INTERVAL
	self._near = false
	self._accentsOn = false
	self._clipLift = 1.0 -- SetClipModifiers
	self._clipLean = 1.0
	self._clipsDriven = false
	self._gaitPhase = nil -- SetGaitPhase (0..1 of the Move cycle) and the Move weight
	self._gaitWeight = 0.0
	self._gaitStep = nil
	self._hoverHeight = if typeof(entry.Hover) == "number" then math.max(entry.Hover, 0.0) else (style.HoverHeight or 1.2)
	self._accentBoost = 1.0
	self._accentBase = {} -- continuous accent instance -> its base Rate (emitter) / Brightness (light)

	-- accent instances
	self._continuous = {} -- emitters / lights on while the accent is active
	self._sparks = nil -- emitter bursting when a dash starts
	self._trail = nil -- dash streak
	self._dust = {} -- stomp footfall emitters (one per foot)

	self:_buildAccents()
	for _, instance in ipairs(self._continuous) do
		if instance:IsA("ParticleEmitter") then
			self._accentBase[instance] = instance.Rate
		elseif instance:IsA("Light") then
			self._accentBase[instance] = instance.Brightness
		end
	end

	return self
end

-- ANIMCORE: how much of the lift (hover / hop / stomp dip) and of the lean (lean / bank / idle sway) the playing clips
-- keep (1 = all, 0 = none), and the accent multiplier they ask for (>= 1). HeroClipPlayer computes them each frame.
function AssetHeroMotion.SetClipModifiers(self, lift: number?, lean: number?, accentBoost: number?)
	self._clipLift = if typeof(lift) == "number" then math.clamp(lift, 0, 2) else 1.0
	self._clipLean = if typeof(lean) == "number" then math.clamp(lean, 0, 2) else 1.0
	self._accentBoost = if typeof(accentBoost) == "number" then math.clamp(accentBoost, 1, 6) else 1.0
	self._clipsDriven = true
end

-- ANIMPOLISH: the Move clip's cycle phase (0..1, footfalls at 0 and 0.5) and its weight; nil phase = no clip gait.
function AssetHeroMotion.SetGaitPhase(self, phase: number?, weight: number?)
	if typeof(phase) ~= "number" or phase ~= phase then
		self._gaitPhase = nil
		self._gaitStep = nil
		return
	end
	self._gaitPhase = phase % 1
	self._gaitWeight = if typeof(weight) == "number" then math.clamp(weight, 0, 1) else 1.0
end

function AssetHeroMotion._part(self, name: string): BasePart?
	local part = self._model:FindFirstChild(name, true)
	return if part and part:IsA("BasePart") then part else nil
end

function AssetHeroMotion._buildAccents(self)
	local entry, s = self._entry, self._scale
	local color = typeof(entry.Color) == "Color3" and entry.Color or Color3.new(1, 1, 1)
	local color2 = typeof(entry.Color2) == "Color3" and entry.Color2 or color
	local torso = self:_part("UpperTorso")
	local root = self._model.PrimaryPart

	if self._styleName == "stomp" then
		local dustColor = typeof(entry.DustColor) == "Color3" and entry.DustColor or Color3.fromRGB(170, 150, 120)
		for _, footName in ipairs({ "LeftFoot", "RightFoot" }) do
			local foot = self:_part(footName)
			if foot then
				local attachment = newAttachment(foot, Vector3.new(0, -foot.Size.Y * 0.5, 0))
				table.insert(self._dust, newEmitter(attachment, {
					Texture = TEXTURE_SMOKE,
					Color = ColorSequence.new(dustColor),
					LightInfluence = 1,
					Size = sizeSequence(0.6 * s, 1.7 * s),
					Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) }),
					Lifetime = NumberRange.new(0.45, 0.8),
					Rate = 0,
					Speed = NumberRange.new(2.0 * s, 4.0 * s),
					SpreadAngle = Vector2.new(80, 80),
					Acceleration = Vector3.new(0, -1.5 * s, 0),
					Drag = 5,
					RotSpeed = NumberRange.new(-40, 40),
					Rotation = NumberRange.new(0, 360),
				}))
			end
		end
	end

	if self._styleName == "dash" and torso then
		local lower = self:_part("LowerTorso") or torso
		local top = newAttachment(torso, Vector3.new(0, torso.Size.Y * 0.5, 0))
		local bottom = newAttachment(lower, Vector3.new(0, -lower.Size.Y * 0.5, 0))
		local trail = Instance.new("Trail")
		trail.Name = "HeroMotionTrail"
		trail.Enabled = false
		trail.Attachment0 = top
		trail.Attachment1 = bottom
		trail.Lifetime = 0.22
		trail.MinLength = 0.05
		trail.FaceCamera = true
		trail.LightEmission = 0.7
		trail.Color = ColorSequence.new(color, color2)
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2) })
		trail.Parent = torso
		self._trail = trail
	end

	local accent = entry.Accent
	if accent == "Thrusters" then
		for _, footName in ipairs({ "LeftFoot", "RightFoot" }) do
			local foot = self:_part(footName)
			if foot then
				local attachment = newAttachment(foot, Vector3.new(0, -foot.Size.Y * 0.5, 0))
				table.insert(self._continuous, newEmitter(attachment, {
					Texture = TEXTURE_FIRE,
					Color = ColorSequence.new(Color3.fromRGB(255, 250, 220), color),
					LightEmission = 1,
					Size = sizeSequence(0.45 * s, 0.05 * s),
					Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
					Lifetime = NumberRange.new(0.12, 0.25),
					Rate = 40,
					Speed = NumberRange.new(5 * s, 8 * s),
					SpreadAngle = Vector2.new(8, 8),
					EmissionDirection = Enum.NormalId.Bottom,
				}))
			end
		end
		if root then
			table.insert(self._continuous, newLight(root, color, 7 * s, 1.2))
		end
	elseif accent == "Aura" and torso then
		table.insert(self._continuous, newEmitter(torso, {
			Texture = TEXTURE_SPARKLE,
			Color = ColorSequence.new(color, color2),
			LightEmission = 1,
			Size = sizeSequence(0.35 * s, 0),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(0.5, 0.9),
			Rate = 12,
			Speed = NumberRange.new(0.5 * s, 1.5 * s),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 2.5 * s, 0),
			Drag = 1,
		}))
		table.insert(self._continuous, newLight(torso, color, 5 * s, 0.7))
	elseif accent == "Sparks" and torso then
		local sparks = newEmitter(torso, {
			Texture = TEXTURE_SPARKLE,
			Color = ColorSequence.new(color, color2),
			LightEmission = 1,
			Size = sizeSequence(0.4 * s, 0),
			Lifetime = NumberRange.new(0.15, 0.35),
			Rate = if entry.Continuous then 5 else 0,
			Speed = NumberRange.new(6 * s, 12 * s),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 4,
		})
		self._sparks = sparks
		if entry.Continuous then
			table.insert(self._continuous, sparks)
		end
	elseif accent == "Feathers" and torso then
		table.insert(self._continuous, newEmitter(torso, {
			Texture = TEXTURE_SPARKLE,
			Color = ColorSequence.new(color),
			Size = sizeSequence(0.3 * s, 0.2 * s),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(1.5, 2.5),
			Rate = 3,
			Speed = NumberRange.new(0.5 * s, 1.5 * s),
			EmissionDirection = Enum.NormalId.Back,
			SpreadAngle = Vector2.new(40, 40),
			Acceleration = Vector3.new(0, -1.2 * s, 0),
			RotSpeed = NumberRange.new(-90, 90),
			Rotation = NumberRange.new(0, 360),
		}))
	elseif accent == "Glitter" and torso then
		table.insert(self._continuous, newEmitter(torso, {
			Texture = TEXTURE_SPARKLE,
			Color = ColorSequence.new(color, color2),
			LightEmission = 1,
			Size = sizeSequence(0.25 * s, 0),
			Lifetime = NumberRange.new(0.6, 1.2),
			Rate = 4,
			Speed = NumberRange.new(0.3 * s, 0.8 * s),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 0.8 * s, 0),
		}))
	end
end

-- Whether AssetComponent plays the Walk track while the hero moves (float heroes glide on their Idle).
function AssetHeroMotion.UsesWalkCycle(self): boolean
	return self._style.WalkCycle ~= false
end

-- Walk-cycle speed multiplier (heavy heroes step slower; a dash burst sprints).
function AssetHeroMotion.GetAnimationSpeedMultiplier(self): number
	local multiplier = self._style.AnimationSpeed or 1.0
	if self._burstRemaining > 0 then
		multiplier *= 1.6
	end
	return multiplier
end

-- How much faster the wander simulation runs this frame (> 1 only during a dash burst).
function AssetHeroMotion.GetTimeScale(self): number
	if self._burstRemaining > 0 then
		return self._style.BurstTimeScale or 1.0
	end
	return 1.0
end

function AssetHeroMotion._updateLod(self, dt: number)
	self._lodElapsed += dt
	if self._lodElapsed < LOD_INTERVAL then
		return
	end
	self._lodElapsed = 0
	local camera = Workspace.CurrentCamera
	local root = self._model.PrimaryPart
	self._near = camera ~= nil and root ~= nil and (camera.CFrame.Position - root.CFrame.Position).Magnitude <= ACCENT_RANGE
end

-- Keeps the continuous accents and the dash trail in the wanted state. Never called while hidden (the hide snapshot
-- owns Enabled then, and restores what was set here when the hero is shown again).
function AssetHeroMotion._applyAccents(self, accentsOn: boolean)
	local boost = self._accentBoost
	for _, instance in ipairs(self._continuous) do
		if instance.Parent ~= nil and instance.Enabled ~= accentsOn then
			instance.Enabled = accentsOn
		end
		local base = self._accentBase[instance]
		if base ~= nil and instance.Parent ~= nil then
			if instance:IsA("ParticleEmitter") then
				local rate = base * boost
				if instance.Rate ~= rate then
					instance.Rate = rate
				end
			elseif instance:IsA("Light") then
				local brightness = base * boost
				if instance.Brightness ~= brightness then
					instance.Brightness = brightness
				end
			end
		end
	end
	local trail = self._trail
	if trail and trail.Parent ~= nil then
		local wanted = accentsOn and self._burstRemaining > 0
		if trail.Enabled ~= wanted then
			trail.Enabled = wanted
		end
	end
	self._accentsOn = accentsOn
end

local function emit(emitter: ParticleEmitter?, count: number)
	if emitter and emitter.Parent ~= nil then
		emitter:Emit(count)
	end
end

-- One frame. Returns the presentation offset (CFrame in the hero's grounded local space), or nil on the silent path.
--   moving/speed/grounded: this frame's wander result; silent: suppressed presentation (hidden or far foreign heroes);
--   hidden: the hide snapshot is active; target: the simulation target CFrame (its heading drives the banking).
function AssetHeroMotion.Step(self, dt: number, moving: boolean, speed: number, grounded: boolean, silent: boolean, hidden: boolean, target: CFrame?)
	dt = math.clamp(dt, 0, 0.1)
	self._clock += dt
	local style, s = self._style, self._scale
	speed = if typeof(speed) == "number" then speed else 0

	self:_updateLod(dt)
	local accentsOn = self._near and not silent and not hidden
	if not hidden then
		self:_applyAccents(accentsOn)
	end

	-- dash bursts (the timers run even when silent so a hidden hero never freezes mid-burst)
	if self._styleName == "dash" then
		if self._burstRemaining > 0 then
			self._burstRemaining = math.max(self._burstRemaining - dt, 0)
		elseif moving then
			self._burstCooldown -= dt
			if self._burstCooldown <= 0 and grounded then
				local range = style.BurstCooldown or { 1.4, 3.2 }
				self._burstCooldown = self._random:NextNumber(range[1], range[2])
				self._burstRemaining = style.BurstSeconds or 0.35
				if accentsOn then
					emit(self._sparks, 14)
				end
			end
		end
	end

	if silent then
		self._lastYaw = nil
		return nil
	end

	-- heading change -> banking (float) ; positive yaw rate = turning left
	if target then
		local look = target.LookVector
		local yaw = math.atan2(-look.X, -look.Z)
		if self._lastYaw ~= nil and dt > 0 then
			self._yawRate = smooth(self._yawRate, wrapAngle(yaw - self._lastYaw) / dt, dt)
		end
		self._lastYaw = yaw
	end

	local moveFactor = if moving then math.clamp(speed / 14, 0.25, 1) else 0
	local leanTarget = math.rad(style.LeanDegrees or 0) * moveFactor
	local swayTarget = if moving then 0 else math.rad(style.IdleSwayDegrees or 0) * math.sin(self._clock * 0.55)
		* (if self._clipsDriven then 0.4 else 1.0)
	-- footfalls of the clip's gait (two per cycle): the step index changes when a foot lands
	local footfall = false
	local gaitPhase = self._gaitPhase
	if gaitPhase ~= nil then
		local step = math.floor(gaitPhase * 2)
		footfall = self._gaitStep ~= nil and step ~= self._gaitStep and self._gaitWeight > 0.5
		self._gaitStep = step
	end
	local bankTarget = 0.0
	local liftTarget = 0.0
	local pivotHeight = 0.0

	if self._styleName == "float" then
		local bob = math.sin(self._clock * 2 * math.pi * (style.BobSpeed or 0.45)) * (style.BobAmplitude or 0.2) * s
		self._hover = smooth(self._hover, self._hoverHeight * s, dt * 0.35)
		liftTarget = self._hover + bob
		bankTarget = math.clamp(self._yawRate * 0.15, -1, 1) * math.rad(style.BankDegrees or 0)
		pivotHeight = self._height * 0.5
	elseif self._styleName == "dash" then
		if self._burstRemaining > 0 then
			leanTarget = math.rad(style.BurstLeanDegrees or 16)
		end
	elseif self._styleName == "stomp" then
		if moving and grounded then
			local before = self._stepPhase
			self._stepPhase += speed * dt / ((style.StrideLength or 4.4) * s)
			if (gaitPhase ~= nil and footfall) or (gaitPhase == nil and math.floor(self._stepPhase) ~= math.floor(before)) then
				self._dipRemaining = STEP_DIP_SECONDS
				self._stepFoot = 3 - self._stepFoot
				if accentsOn then
					emit(self._dust[self._stepFoot] or self._dust[1], 4)
				end
			end
		end
		self._dipRemaining = math.max(self._dipRemaining - dt, 0)
		liftTarget = -(style.StepDip or 0.1) * s * (self._dipRemaining / STEP_DIP_SECONDS)
	elseif self._styleName == "bounce" then
		if moving and grounded then
			self._hopPhase += speed * dt / ((style.HopLength or 3.3) * s)
			-- one hop per step: up while the leg swings, down on the footfall (the clip's phase when it has one)
			local hop = if gaitPhase ~= nil then math.sin((gaitPhase * 2 % 1) * math.pi) * self._gaitWeight
				else math.abs(math.sin(self._hopPhase * math.pi))
			liftTarget = hop * (style.HopHeight or 0.5) * s * math.clamp(speed / 8, 0.4, 1)
		end
	end

	self._lean = smooth(self._lean, leanTarget, dt)
	self._sway = smooth(self._sway, swayTarget, dt)
	self._bank = smooth(self._bank, bankTarget, dt)
	-- hops and dips must keep their shape, only the float hover/bob is eased (above)
	self._lift = if self._styleName == "float" then liftTarget else smooth(self._lift, liftTarget, dt * 3)

	local liftK, leanK = self._clipLift, self._clipLean
	return CFrame.new(0, self._lift * liftK + pivotHeight, 0) * CFrame.Angles(-self._lean * leanK, self._sway * leanK, self._bank * leanK)
		* CFrame.new(0, -pivotHeight, 0)
end

function AssetHeroMotion.Destroy(self)
	table.clear(self._continuous)
	table.clear(self._accentBase)
	table.clear(self._dust)
	self._sparks = nil
	self._trail = nil
end

return AssetHeroMotion
