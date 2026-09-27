-- StarterPlayerScripts.Game.Plots.ActiveAssetsController.HeroClipPlayer (ANIMCORE, hero animation pipeline; ANIMPOLISH)
-- Plays a pen hero's authored clips (ReplicatedStorage.Directory.HeroAnimations.<HeroId>, generated in Blender by
-- scripts/tools/blender/hero_anim/run.py) without any uploaded animation asset: every frame it evaluates the clips with
-- ReplicatedStorage.Library.Modules.HeroClipMath and writes each Motor6D.Transform of the rig itself.
--
-- Why a Transform writer and not KeyframeSequences: animations cannot be uploaded (no asset ids) and
-- KeyframeSequenceProvider:RegisterKeyframeSequence is not reliable in live games. AssetComponent owns one player per
-- hero that has clips; for those heroes it never plays the default Idle / Walk tracks and unparents the model's
-- Animator (kept aside), so nothing else writes the joints and a pose written on a skipped (LOD) frame stays put. The
-- player is stepped from AssetComponent._step, i.e. inside AssetMovementBatch's RunService.PreRender callback, before the
-- batch moves the root: the Transforms written there are what this frame renders.
--
-- Behaviour (clip contract: api.py header):
--   Idle <-> Move cross-fade (eased, MOVE_IN / MOVE_OUT s) on the wander simulation's moving flag. Move restarts from its
--   contact pose when the hero sets off and follows the ground speed: rate = speed / (Move.Speed * rig scale), the
--   speed low-passed like the movement batch renders it, so a foot-locked Move (speed="auto" in the authoring modules)
--   keeps its planted feet on the floor, big and small heroes alike (GetGait gives AssetComponent the speed band the clip
--   can play: the wander speeds are kept in it). A hop in place keeps Idle; in the air the legs tuck (jump pose).
--   Idle: every hero starts at its own phase and plays at its own rate (0.9x..1.1x), so a pen never breathes in sync;
--   with SetLookTarget the head (and a little of the chest) turns to the viewer when they are close and in front,
--   otherwise it glances around now and then. Special plays about every SpecialEvery seconds (the timer runs while the
--   hero walks too; a due Special waits for the next stop and WantsSpecial() asks the wander simulation to hold that
--   idle) - fade in SPECIAL_IN, out SPECIAL_OUT; moving cancels it.
--   Effects of the dominant clip: Web (Beam hand -> anchor), Charge (glow + light on the hands), Burst (one-shot sparks),
--   Accent (GetAccentBoost -> AssetHeroMotion pumps the hero's accent emitters). Motion Lift / Lean weights
--   (GetMotionModifiers) scale AssetHeroMotion's hover / hop and lean / bank on the root; GetGaitPhase syncs its stomp
--   dips / hops with the clip's footfalls.
--   Cost rules: nothing is written on the silent path (hidden by Hide Your Heroes / Hide Other Heroes, or suppressed
--   foreign heroes); the pose update rate follows the distance to the camera (every frame within NEAR_FULL, NEAR_HZ up
--   to NEAR_RANGE, MID_HZ up to FAR_RANGE, frozen beyond) and drops to OFFSCREEN_HZ for heroes off screen, staggered per
--   hero; a joint whose pose did not move since the last write is not rewritten; effects only within EFFECT_RANGE;
--   effect instances are built lazily, named HeroClipFx*, and never touched while the hero is hidden (AssetComponent's
--   hide snapshot owns their Enabled state then). A Burst fires once per pass through its time window (loops included).
--   No table / closure is allocated per frame.
-- Every entry point is safe on a partial rig or odd data: new() returns nil (the hero keeps the default animations).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MOVE_IN = 0.28
local MOVE_OUT = 0.34
local SPECIAL_IN = 0.2
local SPECIAL_OUT = 0.3
local SPECIAL_CANCEL = 0.2
local SPECIAL_WAIT_MOVE = 0.05 -- a due Special starts once the Move weight fell under this
local SPEED_SMOOTH = 8.0 -- 1/s: AssetMovementBatch's lerp toward the target (the speed the viewer sees)
local MIN_RATE = 0.35 -- Move playback rate band (the wander speed band is narrower: AssetComponent / GetGait)
local SLOW_MOVE_WEIGHT = 0.15 -- turning on the spot / setting off: Move blends over Idle down to this weight
local MAX_RATE = 2.6
local AIR_IN = 0.08
local AIR_OUT = 0.14
local HOP_SPEED = 0.8 -- studs/s: an airborne hero slower than this hops in place (keeps Idle)
local NEAR_FULL = 45
local NEAR_RANGE = 120
local FAR_RANGE = 260
local NEAR_HZ = 30
local MID_HZ = 12
local OFFSCREEN_HZ = 5
local EFFECT_RANGE = 140
local LOD_INTERVAL = 0.25
local BURST_WINDOW = 0.25 -- s of clip time in which a Burst may fire (once per pass)
local WRITE_EPSILON = 1e-6 -- a joint whose sample moved less than this keeps its Transform (no write, no CFrame)
local TEMPLATE_HIP_HEIGHT = 2.0 -- hip joint above the soles on the block R15 template (clips are authored for it)
local TEMPLATE_HRP_HEIGHT = 3.0 -- HumanoidRootPart centre above the soles on the template
local TEMPLATE_EYE_HEIGHT = 1.6 -- eyes above the HumanoidRootPart centre on the template
local DEFAULT_SPECIAL_EVERY = { 10, 20 }
local LOOK_RANGE = 26 -- studs (x rig scale, at least 1x): the viewer closer than this and in front gets looked at
local LOOK_YAW = math.rad(70)
local LOOK_PITCH_UP = math.rad(30)
local LOOK_PITCH_DOWN = math.rad(25)
local LOOK_BEHIND = math.rad(115) -- beyond this the viewer is behind: glance instead
local LOOK_SMOOTH = 5.0
local LOOK_REFRESH = 0.12
local LOOK_FADE = 3.0 -- 1/s
local NECK_SHARE = 0.72 -- of the look yaw (the waist turns the rest)
local TUCK_HIP = math.rad(38)
local TUCK_KNEE = math.rad(62)
local TUCK_ARM = math.rad(24)

local TEXTURE_SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local TEXTURE_FIRE = "rbxasset://textures/particles/fire_main.dds"

local JOINTS = {
	"Root", "Waist", "Neck",
	"LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow", "RightWrist",
	"LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle",
}

local HeroClipMath = nil
do
	local library = ReplicatedStorage:FindFirstChild("Library")
	local modules = library and library:FindFirstChild("Modules")
	local module = modules and modules:FindFirstChild("HeroClipMath")
	if module and module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" then
			HeroClipMath = result
		else
			warn("[HeroClipPlayer] HeroClipMath unavailable, heroes keep the default animations: " .. tostring(result))
		end
	end
end

local HeroClipPlayer = {}
HeroClipPlayer.__index = HeroClipPlayer

local cache: { [string]: any } = {} -- heroId -> { Clips, SpecialEvery } | false

-- The prepared clips of a hero, or nil (no module / broken data: the hero keeps the default animations).
function HeroClipPlayer.Load(heroId: string?)
	if HeroClipMath == nil or type(heroId) ~= "string" then
		return nil
	end
	local cached = cache[heroId]
	if cached ~= nil then
		return cached or nil
	end
	local result = false
	local directory = ReplicatedStorage:FindFirstChild("Directory")
	local folder = directory and directory:FindFirstChild("HeroAnimations")
	local module = folder and folder:FindFirstChild(heroId)
	if module and module:IsA("ModuleScript") then
		local ok, data = pcall(require, module)
		if ok then
			local okPrepare, clips = pcall(HeroClipMath.PrepareModule, data)
			if okPrepare then
				local every = DEFAULT_SPECIAL_EVERY
				if type(data.SpecialEvery) == "table" and type(data.SpecialEvery[1]) == "number" and type(data.SpecialEvery[2]) == "number" then
					every = { math.max(2, data.SpecialEvery[1]), math.max(2, data.SpecialEvery[1], data.SpecialEvery[2]) }
				end
				result = { Clips = clips, SpecialEvery = every }
			else
				warn(`[HeroClipPlayer] {heroId} clips rejected: {clips}`)
			end
		else
			warn(`[HeroClipPlayer] {heroId} clips failed to load: {data}`)
		end
	end
	cache[heroId] = result
	return result or nil
end

function HeroClipPlayer.Has(heroId: string?): boolean
	return HeroClipPlayer.Load(heroId) ~= nil
end

local function findMotors(model: Model): ({ [string]: Motor6D }, number)
	local motors, count = {}, 0
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Motor6D") and motors[descendant.Name] == nil and table.find(JOINTS, descendant.Name) then
			motors[descendant.Name] = descendant
			count += 1
		end
	end
	return motors, count
end

-- Rendered rig size / template size, measured on the hip -> sole chain (includes the Hero Size visual scale).
local function measureRigScale(motors: { [string]: Motor6D }): number
	local hip, knee, ankle = motors.LeftHip, motors.LeftKnee, motors.LeftAnkle
	local foot = ankle and ankle.Part1
	if hip and knee and ankle and foot then
		local height = math.abs(hip.C1.Position.Y) + math.abs(knee.C0.Position.Y) + math.abs(knee.C1.Position.Y)
			+ math.abs(ankle.C0.Position.Y) + math.abs(ankle.C1.Position.Y) + foot.Size.Y * 0.5
		if height > 0.05 then
			return height / TEMPLATE_HIP_HEIGHT
		end
	end
	local root = motors.Root and motors.Root.Part0
	if root then
		return math.max(root.Size.Y / 2, 0.1)
	end
	return 1
end

function HeroClipPlayer.new(model: Model, heroId: string?, seed: number?)
	local entry = HeroClipPlayer.Load(heroId)
	if entry == nil then
		return nil
	end
	local motors, count = findMotors(model)
	if count < #JOINTS or motors.Root.Part0 == nil then
		return nil -- not a full R15 rig: default animations
	end
	local random = Random.new(if typeof(seed) == "number" then seed else 0)
	local clips = entry.Clips
	local self = setmetatable({}, HeroClipPlayer)
	self._model = model
	self._motors = motors
	self._rootPart = motors.Root.Part0
	self._scale = measureRigScale(motors)
	self._clips = clips
	self._idle = clips.Idle
	self._move = clips.Move
	self._special = clips.Special
	self._specialEvery = entry.SpecialEvery
	self._random = random
	self._tIdle = random:NextNumber(0, self._idle.Length)
	self._idleRate = random:NextNumber(0.9, 1.1) -- no two heroes breathe in sync
	self._tMove = 0
	self._tSpecial = 0
	self._wMove = 0
	self._wSpecial = 0
	self._wAir = 0
	self._tuck = clips.Move.Footsteps ~= false -- grounded Moves tuck their legs in a jump (flyers do not)
	self._speed = 0 -- ground speed as the viewer sees it (low-passed like the movement batch)
	self._specialState = nil -- nil | "in" | "cancel"
	self._specialTimer = random:NextNumber(3, entry.SpecialEvery[2])
	self._moveRate = 1
	self._bufIdle, self._bufMove, self._bufSpecial = {}, {}, {}
	self._mix = table.create(7, 0)
	self._written = {} -- joint -> the sample last written to its Transform (unchanged joints are not rewritten)
	self._lodElapsed = LOD_INTERVAL + random:NextNumber(0, LOD_INTERVAL)
	self._distance = 0
	self._poseInterval = 0
	self._poseElapsed = random:NextNumber(0, 1 / MID_HZ) -- staggered: throttled heroes do not all update on one frame
	self._lookEnabled = false -- SetLookTarget turns the look layer on (the offline sim never does)
	self._lookTarget = nil
	self._lookWeight = 0
	self._lookYaw, self._lookPitch = 0, 0
	self._lookGoalYaw, self._lookGoalPitch = 0, 0
	self._lookElapsed = random:NextNumber(0, LOOK_REFRESH)
	self._glancing = false
	self._glanceTimer = random:NextNumber(1, 4)
	self._effectsOn = false
	self._fx = {} -- per effect table -> instances
	self._burstDone = {} -- per burst effect -> activation already emitted
	self._accentBoost = 1
	self._gait = { Speed = clips.Move.Speed, Scale = self._scale, Footsteps = clips.Move.Footsteps ~= false }
	self._destroyed = false
	return self
end

local function ease(w: number): number
	return w * w * (3 - 2 * w)
end

-- Motion weights for AssetHeroMotion (1 = full hover/hop, full lean/bank).
function HeroClipPlayer.GetMotionModifiers(self): (number, number)
	local wMove = ease(self._wMove)
	local lift = self._idle.Lift + (self._move.Lift - self._idle.Lift) * wMove
	local lean = self._idle.Lean + (self._move.Lean - self._idle.Lean) * wMove
	local special = self._special
	if special and self._wSpecial > 0 then
		local wSpecial = ease(self._wSpecial)
		lift += (special.Lift - lift) * wSpecial
		lean += (special.Lean - lean) * wSpecial
	end
	return lift, lean
end

-- The accent multiplier the active clips ask for (>= 1).
function HeroClipPlayer.GetAccentBoost(self): number
	return self._accentBoost
end

-- Whether the footstep sound should run while this hero moves (the Move clip's Footsteps flag).
function HeroClipPlayer.UsesFootsteps(self): boolean
	return self._move.Footsteps
end

-- { Speed = the Move clip's ground speed at rig scale 1 (nil: fixed rate), Scale = rendered rig / template,
--   Footsteps = a stepping gait }. The same table every call (read only).
function HeroClipPlayer.GetGait(self)
	return self._gait
end

-- Phase (0..1) of the Move cycle (its contacts are at 0 and 0.5 for the gait helpers) and the eased Move weight.
function HeroClipPlayer.GetGaitPhase(self): (number, number)
	local length = self._move.Length
	return (self._tMove % length) / length, ease(self._wMove)
end

-- True while a Special is due and waits for the hero to stand still (AssetComponent holds the wander idle for it).
function HeroClipPlayer.WantsSpecial(self): boolean
	return self._special ~= nil and self._specialState == nil and self._specialTimer <= 0
end

function HeroClipPlayer.GetSpecialLength(self): number
	return if self._special then self._special.Length else 0
end

-- Where the hero may look while idling (the viewer's head), or nil. Enables the look layer.
function HeroClipPlayer.SetLookTarget(self, position: Vector3?)
	self._lookEnabled = true
	self._lookTarget = if typeof(position) == "Vector3" then position else nil
end

function HeroClipPlayer._updateLod(self, dt: number)
	self._lodElapsed += dt
	if self._lodElapsed < LOD_INTERVAL then
		return
	end
	self._lodElapsed = 0
	local camera = Workspace.CurrentCamera
	local root = self._rootPart
	if camera == nil or root == nil or root.Parent == nil then
		self._distance = math.huge
		self._poseInterval = math.huge
		return
	end
	local position = root.CFrame.Position
	local distance = (camera.CFrame.Position - position).Magnitude
	self._distance = distance
	-- on screen (with a margin: a hero whose root is just off the edge still shows its body)
	local onScreen = true
	local ok, point = pcall(camera.WorldToViewportPoint, camera, position)
	if ok and typeof(point) == "Vector3" then
		local size = camera.ViewportSize
		onScreen = point.Z > 0 and point.X > -size.X * 0.15 and point.X < size.X * 1.15
			and point.Y > -size.Y * 0.2 and point.Y < size.Y * 1.2
	end
	if distance > FAR_RANGE then
		self._poseInterval = math.huge
	elseif not onScreen then
		self._poseInterval = if distance <= NEAR_RANGE then 1 / OFFSCREEN_HZ else math.huge
	elseif distance <= NEAR_FULL then
		self._poseInterval = 0
	elseif distance <= NEAR_RANGE then
		self._poseInterval = 1 / NEAR_HZ
	else
		self._poseInterval = 1 / MID_HZ
	end
end

-- Look layer: where the head turns (radians, rig space: yaw + = to its left, pitch + = up), refreshed at LOOK_REFRESH.
function HeroClipPlayer._updateLook(self, dt: number)
	self._lookWeight = math.clamp(self._lookWeight + (if self._lookEnabled then dt else -dt) * LOOK_FADE, 0, 1)
	if not self._lookEnabled then
		return
	end
	self._lookElapsed += dt
	if self._lookElapsed >= LOOK_REFRESH then
		local elapsed = self._lookElapsed
		self._lookElapsed = 0
		local target = self._lookTarget
		local root = self._rootPart
		local found = false
		if target ~= nil and root ~= nil and root.Parent ~= nil then
			local l = root.CFrame:PointToObjectSpace(target)
			local flat = math.sqrt(l.X * l.X + l.Z * l.Z)
			local yaw = math.atan2(-l.X, -l.Z)
			if flat < LOOK_RANGE * math.max(self._scale, 1) and flat > 0.5 and math.abs(yaw) < LOOK_BEHIND then
				found = true
				self._lookGoalYaw = math.clamp(yaw, -LOOK_YAW, LOOK_YAW)
				self._lookGoalPitch = math.clamp(math.atan2(l.Y - TEMPLATE_EYE_HEIGHT * self._scale, flat), -LOOK_PITCH_DOWN, LOOK_PITCH_UP)
				self._glancing = false
				self._glanceTimer = self._random:NextNumber(1.5, 3.5)
			end
		end
		if not found then
			-- nobody to look at: glance around now and then, then face ahead again
			self._glanceTimer -= elapsed
			if self._glanceTimer <= 0 then
				self._glancing = not self._glancing
				if self._glancing then
					self._glanceTimer = self._random:NextNumber(0.8, 2.0)
					self._lookGoalYaw = self._random:NextNumber(-0.8, 0.8)
					self._lookGoalPitch = self._random:NextNumber(-0.14, 0.18)
				else
					self._glanceTimer = self._random:NextNumber(2.5, 6.5)
					self._lookGoalYaw, self._lookGoalPitch = 0, 0
				end
			end
		end
	end
	local k = 1 - math.exp(-LOOK_SMOOTH * dt)
	self._lookYaw += (self._lookGoalYaw - self._lookYaw) * k
	self._lookPitch += (self._lookGoalPitch - self._lookPitch) * k
end

function HeroClipPlayer._advance(self, dt: number, moving: boolean, speed: number, grounded: boolean)
	-- the ground speed the viewer sees (the movement batch eases the root toward the simulation)
	self._speed += (speed - self._speed) * math.min(dt * SPEED_SMOOTH, 1)
	if grounded then
		self._wAir = math.max(0, self._wAir - dt / AIR_OUT)
	else
		self._wAir = math.min(1, self._wAir + dt / AIR_IN)
	end
	-- Idle <-> Move (a hop in place is not a walk). A stepping Move slower than its slowest rate (turning on the spot,
	-- setting off) only partly covers Idle, so the feet do not paddle over the floor.
	local move = self._move
	local wantMove = moving and (grounded or speed >= HOP_SPEED)
	local target = 0
	if wantMove then
		target = 1
		if move.Speed ~= nil and move.Footsteps ~= false then
			target = math.clamp(self._speed / (MIN_RATE * move.Speed * self._scale), SLOW_MOVE_WEIGHT, 1)
		end
	end
	local wasStill = self._wMove <= 0
	if self._wMove < target then
		self._wMove = math.min(target, self._wMove + dt / MOVE_IN)
		if wasStill then
			self._tMove = 0 -- set off from the contact pose
		end
	elseif self._wMove > target then
		self._wMove = math.max(target, self._wMove - dt / MOVE_OUT)
	end
	local rate = 1
	if move.Speed ~= nil then
		-- stopping: the stride slows down with the body (down to a standstill), so the planted foot stays planted
		local exact = self._speed / (move.Speed * self._scale)
		rate = math.clamp(exact, if wantMove then MIN_RATE else 0, MAX_RATE)
	end
	rate *= 1 - 0.8 * self._wAir -- the legs hang in the air
	self._moveRate = rate
	self._tIdle += dt * self._idleRate
	if self._wMove > 0 then
		self._tMove += dt * rate
	end
	-- Special: the timer runs all the time; a due Special starts at the next stop
	local special = self._special
	if special == nil then
		return
	end
	local state = self._specialState
	if state == nil then
		if self._specialTimer > 0 then
			self._specialTimer -= dt
		end
		if self._specialTimer <= 0 and not moving and grounded and self._wMove <= SPECIAL_WAIT_MOVE then
			self._specialState = "in"
			self._tSpecial = 0
			table.clear(self._burstDone)
		end
		return
	end
	self._tSpecial += dt
	if state == "in" and moving then
		self._specialState = "cancel"
		state = "cancel"
	end
	if state == "cancel" then
		self._wSpecial = math.max(0, self._wSpecial - dt / SPECIAL_CANCEL)
	elseif self._tSpecial >= special.Length - SPECIAL_OUT then
		self._wSpecial = math.max(0, math.min(self._wSpecial, (special.Length - self._tSpecial) / SPECIAL_OUT))
	else
		self._wSpecial = math.min(1, self._wSpecial + dt / SPECIAL_IN)
	end
	if self._tSpecial >= special.Length or (state == "cancel" and self._wSpecial <= 0) then
		self._specialState = nil
		self._wSpecial = 0
		local every = self._specialEvery
		self._specialTimer = self._random:NextNumber(every[1], every[2])
	end
end

-- out = a (x, y, z, w) * out (Hamilton): rotation a applied on top of out, in the joint's parent axes.
local function premultiply(out: { number }, ax: number, ay: number, az: number, aw: number)
	local bx, by, bz, bw = out[1], out[2], out[3], out[4]
	out[1] = aw * bx + ax * bw + ay * bz - az * by
	out[2] = aw * by - ax * bz + ay * bw + az * bx
	out[3] = aw * bz + ax * by - ay * bx + az * bw
	out[4] = aw * bw - ax * bx - ay * by - az * bz
end

function HeroClipPlayer._pose(self)
	local rawMove, rawSpecial = self._wMove, self._wSpecial
	local wMove, wSpecial = ease(rawMove), ease(rawSpecial)
	local bufIdle, bufMove, bufSpecial = self._bufIdle, self._bufMove, self._bufSpecial
	if rawMove < 1 then
		HeroClipMath.SampleClip(self._idle, self._tIdle, bufIdle)
	end
	if rawMove > 0 then
		HeroClipMath.SampleClip(self._move, self._tMove, bufMove)
	end
	local special = self._special
	if special and rawSpecial > 0 then
		HeroClipMath.SampleClip(special, self._tSpecial, bufSpecial)
	end
	-- additive layers: the idle look (neck + waist) and the jump tuck (hips, knees, arms)
	local lookW = self._lookWeight * (1 - wMove) * (1 - wSpecial)
	local nyS, nyC, npS, npC, wyS, wyC = 0, 1, 0, 1, 0, 1
	if lookW > 1e-3 then
		local yaw, pitch = self._lookYaw * lookW, self._lookPitch * lookW
		nyS, nyC = math.sin(yaw * NECK_SHARE * 0.5), math.cos(yaw * NECK_SHARE * 0.5)
		npS, npC = math.sin(pitch * 0.5), math.cos(pitch * 0.5)
		wyS, wyC = math.sin(yaw * (1 - NECK_SHARE) * 0.5), math.cos(yaw * (1 - NECK_SHARE) * 0.5)
	end
	local airW = if self._tuck then ease(self._wAir) * (1 - wSpecial) else 0
	local hS, hC, kS, kC, aS, aC = 0, 1, 0, 1, 0, 1
	if airW > 1e-3 then
		hS, hC = math.sin(TUCK_HIP * airW * 0.5), math.cos(TUCK_HIP * airW * 0.5)
		kS, kC = math.sin(-TUCK_KNEE * airW * 0.5), math.cos(-TUCK_KNEE * airW * 0.5)
		aS, aC = math.sin(TUCK_ARM * airW * 0.5), math.cos(TUCK_ARM * airW * 0.5)
	end
	local mix = self._mix
	local scale = self._scale
	local identity = HeroClipMath.Identity
	local written = self._written
	for name, motor in pairs(self._motors) do
		if rawMove >= 1 then
			HeroClipMath.Blend(bufMove[name], identity, 0, mix)
		elseif rawMove <= 0 then
			HeroClipMath.Blend(bufIdle[name], identity, 0, mix)
		else
			HeroClipMath.Blend(bufIdle[name], bufMove[name], wMove, mix)
		end
		if rawSpecial > 0 then
			HeroClipMath.Blend(mix, bufSpecial[name], wSpecial, mix)
		end
		if lookW > 1e-3 then
			if name == "Neck" then
				premultiply(mix, npS, 0, 0, npC)
				premultiply(mix, 0, nyS, 0, nyC)
			elseif name == "Waist" then
				premultiply(mix, 0, wyS, 0, wyC)
			end
		end
		if airW > 1e-3 then
			if name == "LeftHip" or name == "RightHip" then
				premultiply(mix, hS, 0, 0, hC)
			elseif name == "LeftKnee" or name == "RightKnee" then
				premultiply(mix, kS, 0, 0, kC)
			elseif name == "RightShoulder" then
				premultiply(mix, 0, 0, aS, aC)
			elseif name == "LeftShoulder" then
				premultiply(mix, 0, 0, -aS, aC)
			end
		end
		-- Most tracks hold still for long stretches (a crossed arm, a planted leg): nothing else writes these joints (the
		-- Animator is unparented), so an unchanged joint keeps its Transform and costs no CFrame nor engine joint update.
		local last = written[name]
		if last == nil then
			last = table.create(7, 0)
			written[name] = last
		elseif math.abs(last[1] - mix[1]) < WRITE_EPSILON and math.abs(last[2] - mix[2]) < WRITE_EPSILON
			and math.abs(last[3] - mix[3]) < WRITE_EPSILON and math.abs(last[4] - mix[4]) < WRITE_EPSILON
			and math.abs(last[5] - mix[5]) < WRITE_EPSILON and math.abs(last[6] - mix[6]) < WRITE_EPSILON
			and math.abs(last[7] - mix[7]) < WRITE_EPSILON then
			continue
		end
		last[1], last[2], last[3], last[4], last[5], last[6], last[7] = mix[1], mix[2], mix[3], mix[4], mix[5], mix[6], mix[7]
		motor.Transform = HeroClipMath.ToCFrame(mix, scale)
	end
end

-- Clip weights of the dominant clips for effects.
function HeroClipPlayer._clipWeights(self)
	local wSpecial = ease(self._wSpecial)
	local wMove = ease(self._wMove) * (1 - wSpecial)
	local wIdle = (1 - ease(self._wMove)) * (1 - wSpecial)
	return wIdle, wMove, wSpecial
end

local function inWindow(effect, t: number): boolean
	local from = if type(effect.From) == "number" then effect.From else -math.huge
	local to = if type(effect.To) == "number" then effect.To else math.huge
	return t >= from and t <= to
end

local function color3(c): Color3
	if type(c) == "table" and type(c[1]) == "number" then
		return Color3.fromRGB(c[1], c[2] or c[1], c[3] or c[1])
	end
	return Color3.new(1, 1, 1)
end

local function handsOf(self, hand: string?): { BasePart }
	local out = {}
	for _, name in ipairs(if hand == "Both" then { "LeftHand", "RightHand" } elseif hand == "LeftHand" then { "LeftHand" } else { "RightHand" }) do
		local wrist = self._motors[if name == "LeftHand" then "LeftWrist" else "RightWrist"]
		local part = wrist and wrist.Part1
		if part and part:IsA("BasePart") then
			table.insert(out, part)
		end
	end
	return out
end

local function palmAttachment(hand: BasePart, name: string, scale: number): Attachment
	local attachment = hand:FindFirstChild(name)
	if attachment and attachment:IsA("Attachment") then
		return attachment
	end
	attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Position = Vector3.new(0, -hand.Size.Y * 0.5 - 0.12 * scale, 0)
	attachment.Parent = hand
	return attachment
end

function HeroClipPlayer._buildEffect(self, effect)
	local s = self._scale
	local kind = effect.Type
	local built = { Instances = {}, Toggles = {}, Emitters = {} }
	if kind == "Web" then
		local hands = handsOf(self, effect.Hand)
		local hand = hands[1]
		if hand == nil then
			return built
		end
		local handAttachment = palmAttachment(hand, "HeroClipFxWebHand", s)
		local anchor = Instance.new("Attachment")
		anchor.Name = "HeroClipFxWebAnchor"
		local a = type(effect.Anchor) == "table" and effect.Anchor or { 0, 11, -3 }
		anchor.Position = Vector3.new((a[1] or 0) * s, ((a[2] or 11) - TEMPLATE_HRP_HEIGHT) * s, (a[3] or 0) * s)
		anchor.Parent = self._rootPart
		local beam = Instance.new("Beam")
		beam.Name = "HeroClipFxWeb"
		beam.Enabled = false
		beam.Attachment0 = handAttachment
		beam.Attachment1 = anchor
		local width = (if type(effect.Width) == "number" then effect.Width else 0.12) * s
		beam.Width0 = width
		beam.Width1 = width * 0.55
		beam.Color = ColorSequence.new(color3(effect.Color))
		beam.Transparency = NumberSequence.new(0.05)
		beam.LightEmission = 0.35
		beam.LightInfluence = 0.5
		beam.FaceCamera = true
		beam.Segments = 1
		beam.Parent = self._rootPart
		table.insert(built.Instances, anchor)
		table.insert(built.Instances, beam)
		table.insert(built.Toggles, beam)
	elseif kind == "Charge" then
		local size = (if type(effect.Size) == "number" then effect.Size else 1) * s
		local color = color3(effect.Color)
		for _, hand in ipairs(handsOf(self, effect.Hand)) do
			local attachment = palmAttachment(hand, "HeroClipFxPalm", s)
			local core = Instance.new("ParticleEmitter")
			core.Name = "HeroClipFxCharge"
			core.Enabled = false
			core.Texture = TEXTURE_SPARKLE
			core.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
			core.LightEmission = 1
			core.LightInfluence = 0
			core.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1 * size), NumberSequenceKeypoint.new(1, 0.2 * size) })
			core.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
			core.Lifetime = NumberRange.new(0.12, 0.22)
			core.Rate = 40
			core.Speed = NumberRange.new(0, 0.5 * s)
			core.SpreadAngle = Vector2.new(180, 180)
			core.RotSpeed = NumberRange.new(-300, 300)
			core.Rotation = NumberRange.new(0, 360)
			core.LockedToPart = true
			core.ZOffset = 0.5
			core.Parent = attachment
			local sparks = Instance.new("ParticleEmitter")
			sparks.Name = "HeroClipFxChargeSparks"
			sparks.Enabled = false
			sparks.Texture = TEXTURE_FIRE
			sparks.Color = ColorSequence.new(color)
			sparks.LightEmission = 1
			sparks.LightInfluence = 0
			sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35 * size), NumberSequenceKeypoint.new(1, 0) })
			sparks.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
			sparks.Lifetime = NumberRange.new(0.2, 0.4)
			sparks.Rate = 30
			sparks.Speed = NumberRange.new(-2.5 * s, -1.2 * s) -- converge onto the palm
			sparks.SpreadAngle = Vector2.new(180, 180)
			sparks.Parent = attachment
			table.insert(built.Instances, core)
			table.insert(built.Instances, sparks)
			table.insert(built.Toggles, core)
			table.insert(built.Toggles, sparks)
			if effect.Light ~= false then
				local light = Instance.new("PointLight")
				light.Name = "HeroClipFxChargeLight"
				light.Enabled = false
				light.Color = color
				light.Range = 7 * size
				light.Brightness = 2.5
				light.Shadows = false
				light.Parent = attachment
				table.insert(built.Instances, light)
				table.insert(built.Toggles, light)
			end
		end
	elseif kind == "Burst" then
		local color = color3(effect.Color)
		for _, hand in ipairs(handsOf(self, effect.Hand)) do
			local attachment = palmAttachment(hand, "HeroClipFxPalm", s)
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "HeroClipFxBurst"
			emitter.Enabled = false
			emitter.Rate = 0
			emitter.Texture = TEXTURE_SPARKLE
			emitter.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
			emitter.LightEmission = 1
			emitter.LightInfluence = 0
			emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7 * s), NumberSequenceKeypoint.new(1, 0) })
			emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
			emitter.Lifetime = NumberRange.new(0.25, 0.55)
			local speed = (if type(effect.Speed) == "number" then effect.Speed else 14) * s
			emitter.Speed = NumberRange.new(speed * 0.5, speed)
			emitter.SpreadAngle = Vector2.new(60, 60)
			emitter.EmissionDirection = Enum.NormalId.Bottom -- out of the palm
			emitter.Drag = 4
			emitter.Parent = attachment
			table.insert(built.Instances, emitter)
			table.insert(built.Emitters, emitter)
		end
	end
	return built
end

-- Built once per effect (lazily, first time it turns on); a failing build leaves the effect empty, never the hero.
function HeroClipPlayer._effectInstances(self, effect)
	local built = self._fx[effect]
	if built == nil then
		local ok, result = pcall(HeroClipPlayer._buildEffect, self, effect)
		if ok then
			built = result
		else
			warn("[HeroClipPlayer] effect skipped: " .. tostring(result))
			built = { Instances = {}, Toggles = {}, Emitters = {} }
		end
		self._fx[effect] = built
	end
	return built
end

local function setToggles(built, on: boolean)
	for _, instance in ipairs(built.Toggles) do
		if instance.Parent ~= nil and instance.Enabled ~= on then
			instance.Enabled = on
		end
	end
end

-- Effects of one clip at clip time t with weight w. Returns the accent boost it asks for.
function HeroClipPlayer._clipEffects(self, clip, t: number, w: number, allowed: boolean, threshold: number): number
	local boost = 1
	for _, effect in ipairs(clip.Effects) do
		local kind = effect.Type
		local active = allowed and w > threshold and inWindow(effect, t)
		if kind == "Accent" then
			if active and type(effect.Boost) == "number" then
				boost = math.max(boost, 1 + (effect.Boost - 1) * w)
			end
		elseif kind == "Burst" then
			local at = if type(effect.Time) == "number" then effect.Time else 0
			-- fires once per pass through [at, at + window); re-armed as soon as the clip time leaves that window, so a
			-- burst at t = 0 of a looping clip (or of a Move that restarts from 0) fires on every pass, not only the first
			local window = math.min(BURST_WINDOW, clip.Length * 0.5)
			if t >= at and t < at + window then
				if allowed and w > threshold and not self._burstDone[effect] then
					self._burstDone[effect] = true
					local built = self:_effectInstances(effect)
					local count = if type(effect.Count) == "number" then math.clamp(effect.Count, 1, 80) else 30
					for _, emitter in ipairs(built.Emitters) do
						if emitter.Parent ~= nil then
							emitter:Emit(count)
						end
					end
				end
			else
				self._burstDone[effect] = nil
			end
		elseif kind == "Web" or kind == "Charge" then
			local built = self._fx[effect]
			if active and built == nil then
				built = self:_effectInstances(effect)
			end
			if built then
				setToggles(built, active)
			end
		end
	end
	return boost
end

function HeroClipPlayer._stepEffects(self, allowed: boolean)
	local wIdle, wMove, wSpecial = self:_clipWeights()
	local boost = self:_clipEffects(self._idle, HeroClipMath.ClipTime(self._idle, self._tIdle), wIdle, allowed, 0.5)
	boost = math.max(boost, self:_clipEffects(self._move, HeroClipMath.ClipTime(self._move, self._tMove), wMove, allowed, 0.5))
	local special = self._special
	if special then
		local t = if self._specialState ~= nil then self._tSpecial else -1
		boost = math.max(boost, self:_clipEffects(special, t, wSpecial, allowed and self._specialState ~= nil, 0.3))
	end
	self._accentBoost = if allowed then boost else 1
end

function HeroClipPlayer._effectsOff(self)
	for _, built in pairs(self._fx) do
		setToggles(built, false)
	end
	self._accentBoost = 1
end

-- One frame. moving / speed / grounded: this frame's wander result (speed = ground studs/s, grounded = false in a
-- jump; nil counts as grounded); silent: the suppressed presentation path (hidden or far foreign heroes); hidden:
-- AssetComponent's hide snapshot is active (effect instances must not be touched).
function HeroClipPlayer.Step(self, dt: number, moving: boolean, speed: number?, silent: boolean, hidden: boolean, grounded: boolean?)
	if self._destroyed then
		return
	end
	dt = math.clamp(dt, 0, 0.1)
	speed = if typeof(speed) == "number" then speed else 0
	self:_advance(dt, moving == true, speed :: number, grounded ~= false)
	if silent or hidden then
		if not hidden then
			self:_effectsOff()
		end
		self._accentBoost = 1
		self._poseElapsed = math.huge
		return
	end
	self:_updateLod(dt)
	if self._poseInterval == math.huge then
		self:_effectsOff()
		self._poseElapsed = math.huge
		return
	end
	self:_updateLook(dt)
	self._poseElapsed += dt
	if self._poseElapsed >= self._poseInterval then
		self._poseElapsed = 0
		self:_pose()
	end
	self:_stepEffects(self._distance <= EFFECT_RANGE)
end

-- Resets the joints (resetPose) and removes the effect instances. The player is dead afterwards.
function HeroClipPlayer.Destroy(self, resetPose: boolean?)
	if self._destroyed then
		return
	end
	self._destroyed = true
	table.clear(self._written)
	if resetPose then
		for _, motor in pairs(self._motors) do
			if motor.Parent ~= nil then
				motor.Transform = CFrame.identity
			end
		end
	end
	for _, built in pairs(self._fx) do
		for _, instance in ipairs(built.Instances) do
			instance:Destroy()
		end
	end
	table.clear(self._fx)
	for _, hand in ipairs(handsOf(self, "Both")) do
		for _, name in ipairs({ "HeroClipFxPalm", "HeroClipFxWebHand" }) do
			local attachment = hand:FindFirstChild(name)
			if attachment then
				attachment:Destroy()
			end
		end
	end
end

return HeroClipPlayer
