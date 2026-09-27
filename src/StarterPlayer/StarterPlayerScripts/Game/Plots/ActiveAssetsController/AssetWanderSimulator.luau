-- StarterPlayerScripts.Game.Plots.ActiveAssetsController.AssetWanderSimulator
-- (decompiled base module, reworked by ANIMPOLISH: injected from this mirror by scripts/inject/animpolish.luau)
-- Where a pen hero goes (client side, per viewer): personality-driven wandering, idles, greetings, affection, retreats,
-- jumps. ANIMPOLISH additions (all optional: a simulator nobody configures behaves like before, with the pen space):
--   SetFootprint(radius)      the hero's footprint: wander margin = radius + clearance (no more fence poking) and its
--                             size in the pen space (AssetPenSpace: neighbours / terminal / eggs are steered around,
--                             destinations are picked where there is room, crowded idlers walk off)
--   SetSpeedProfile(profile)  { Scale, Min, Max, Tremble }: the rolled walk speeds follow the hero's size and stay in the
--                             band its Move clip can play without skating (AssetComponent from HeroClipPlayer's gait)
--   ExtendIdle(seconds)       holds the current idle (HeroClipPlayer wants to play its Special)
--   IsIdle(), Destroy()       Destroy leaves the pen space
-- Step keeps its contract: target CFrame, moving, grounded, speed (ground studs/s actually covered), greeting effects,
-- bubble text; the target is always inside the hero's wander rectangle and outside the pen's obstacles.
-- NPC pass 2026-09-26 (owner: "i think the heroes are getting stuck too"; measured by scripts/tools/sim_pen_wander.luau
-- "stuck" / "retarget"):
--   * a retreating hero (Shy / Scared) commits to one retreat spot (re-planned only when it arrives, is blocked, or the
--     owner cuts the way, never more often than RETREAT_REPICK_COOLDOWN); cornered (no spot RETREAT_MIN_GAIN farther
--     from the owner) it cowers in place for a moment instead of re-picking a random point every frame (jitter)
--   * the owner's character missing (streamed out / respawning / left) no longer freezes the pen: heroes keep wandering
--   * no-progress watchdog: a hero trying to walk that covered < STUCK_STUDS in STUCK_SECONDS pauses briefly and picks a
--     new destination with a clear straight path (AssetPenSpace.PathClear); greeting approaches end early, followers
--     (Loyal / UltraLoyal) take a roomier spot round the owner
--   * destinations whose straight path crosses an obstacle rank last; obstacle push-out keeps to the wander rectangle
--     (AssetPenSpace.Resolve with the rectangle) so the fence clamp and the push no longer fight in corners
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetItem = require(ReplicatedStorage.Library.Types.AssetItem)
local Personalities = require(ReplicatedStorage.Directory.Assets.Personalities)

require(ReplicatedStorage.Directory.Assets.Types.Personality)

local Log = require(ReplicatedStorage.Library.Modules.Packages.Log)
local Asserts = require(ReplicatedStorage.Library.Asserts)
local AssetMutationWalkSpeed = require(script.Parent.AssetMutationWalkSpeed)
local AssetPersonalityMotion = require(script.Parent.AssetPersonalityMotion)
local AssetWanderArea = require(script.Parent.AssetWanderArea)
local AssetWanderMotion = require(script.Parent.AssetWanderMotion)
local AssetRetreatMotion = require(script.Parent.AssetRetreatMotion)
local AssetPenSpace = require(script.Parent.AssetPenSpace)

local MARGIN_CLEARANCE = 0.8 -- studs between a hero's footprint and the fence line of its wander rectangle
local DESTINATION_TRIES = 5
local DESTINATION_ROOM = 1.2 -- studs of free room a destination should have around the hero
local CROWDED_IDLE_SECONDS = 0.6
local APPROACH_TIMEOUT = 6.0
local ORBIT_SPEED = 22.0
local STUCK_SECONDS = 1.5 -- no-progress watchdog: trying to walk for this long ...
local STUCK_STUDS = 0.5 -- ... without getting this far from where it stood = stuck, re-plan
local UNSTICK_TRIES = 8
local UNSTICK_PAUSE_MIN, UNSTICK_PAUSE_MAX = 0.3, 0.7 -- a short "hm, blocked" pause before the new destination
local PATH_BLOCKED_PENALTY = 1000.0 -- room score of a destination whose straight path crosses an obstacle
local RETREAT_REPICK_COOLDOWN = 0.8 -- s between two retreat plans (the old retreat re-planned every frame)
local RETREAT_MIN_GAIN = 2.0 -- studs a new retreat spot must add to the distance from the owner, else cower
local RETREAT_HYSTERESIS = 2.0 -- studs past the trigger distance before a retreat ends
local COWER_SECONDS_MIN, COWER_SECONDS_MAX = 0.8, 1.6
local v12 = Log.new()
local t1 = {}

t1.__index = t1
t1.__class = "AssetWanderSimulator"

function t1.new(n1: number, p1, p2, p3, b1: boolean, n2: number, n3: number) -- line: 114
	-- upvalues: Asserts (copy), AssetItem (copy), Players (copy), Personalities (copy), t1 (copy), AssetPersonalityMotion (copy), v12 (copy)
	Asserts.number(n1)
	Asserts.Player(p1)
	Asserts.BasePart(p2)
	assert(AssetItem.AssetItemData(p3), "Invalid asset item data")
	Asserts.boolean(b1)
	Asserts.number(n2)
	Asserts.number(n3)

	local random = Random.new(n1)
	local LocalPlayer = Players.LocalPlayer

	assert(LocalPlayer ~= nil, "Asset wander simulator requires a local player")

	local v23 = Personalities.GetConfig(p3.Personality)
	local self = setmetatable({}, t1)

	self._random = random
	self._owner = p1
	self._localPlayer = LocalPlayer
	self._assetArea = p2
	self._itemData = p3
	self._config = v23
	self._speedScale = 1.0 -- ANIMPOLISH speed profile (SetSpeedProfile), before the first roll
	self._speedMin = 0.0
	self._speedMax = math.huge
	self._greetingOrbitRadius = math.max(n2, 2.5)
	self._jumpHeight = math.min(math.max(n3, 1.0) * 2.0, 20.0)
	self._destination = p2.Position
	self._idleRemaining = 0.0
	self._idleAnchorCFrame = nil
	self._idleElapsed = 0.0
	self._walkSpeed = self:_rollWalkSpeed()
	self._mode = "Destination"
	self._phase = "Normal"
	self._greetRemaining = 0.0
	self._randomOrbitInsideSeconds = 0.0
	self._farSeconds = 0.0
	self._farRequiredSeconds = random:NextNumber(105.0, 180.0)
	self._joinGreetingPending = true
	self._finishJumpsRemaining = 0.0
	self._finishJumpCooldown = 0.0
	self._returnGreetingHoldRemaining = 0.0
	self._returnGreetingJumpsRemaining = 0.0
	self._returnGreetingJumpCooldown = 0.0
	self._returnGreetingOwnerOffset = nil
	self._affectionInsideSeconds = 0.0
	self._affectionHoldRemaining = 0.0
	self._affectionJumpsRemaining = 0.0
	self._affectionJumpCooldown = 0.0
	self._affectionOwnerOffset = nil
	self._loyalOwnerOffset = AssetPersonalityMotion.RandomOwnerOffset(p2, random, self._greetingOrbitRadius)
	self._pendingBubbleText = nil
	self._jumpRemaining = 0.0
	self._jumpElapsed = 0.0
	self._spinYaw = 0.0
	self._spinAppliedYaw = 0.0
	self._curveAngle = random:NextNumber(-3.141592653589793, 3.141592653589793)
	self._curveRotationSpeed = random:NextNumber(-0.8, 0.8)
	self._nextCurveChangeSeconds = random:NextNumber(5.0, 10.0)
	self._curveChangeElapsed = 0.0
	self._retreatOwnerWasClose = false
	self._retreatActive = false
	self._lastOwnerPosition = nil
	-- ANIMPOLISH: footprint, pen space, speed profile
	self._radius = math.max((n2 - 2.5) / 0.8, 0.8)
	self._margin = math.max(AssetWanderArea.DefaultMargin, self._radius + MARGIN_CLEARANCE)
	self._space = AssetPenSpace.Join(p2, self._radius)
	self._trembleScale = 1.0
	self._trembleSource = nil
	self._trembleScaled = nil
	self._crowdedSeconds = 0.0
	self._destinationElapsed = 0.0
	self._destinationBudget = math.huge
	self._approachElapsed = 0.0
	self._avoid = nil
	-- NPC pass: retreat commitment + no-progress watchdog
	self._retreatCooldown = 0.0
	self._progressAnchor = nil
	self._progressSeconds = 0.0
	self._progressTouched = false
	self:_chooseNextDestination()

	if b1 then
		self:_tryStartFirstPlacementGreeting()
	end

	v12:AtDebug():Log(`Created asset wander simulator with seed { n1 }`)

	return self
end
function t1._rollWalkSpeed(p4) -- line: 197
	-- upvalues: AssetMutationWalkSpeed (copy)
	local Movement = p4._config.Movement

	return p4:_profileSpeed(math.max(p4._random:NextNumber(Movement.WalkSpeedMin, Movement.WalkSpeedMax), 4.5) * AssetMutationWalkSpeed.GetMultiplier(p4._itemData))
end
-- A personality speed seen through the hero's speed profile (size factor, then the band its Move clip can play).
function t1._profileSpeed(self, speed: number): number
	return math.clamp(speed * self._speedScale, self._speedMin, math.max(self._speedMin, self._speedMax))
end
function t1._ownerRootPosition(p5) -- line: 204
	-- upvalues: AssetPersonalityMotion (copy)
	return AssetPersonalityMotion.OwnerRootPosition(p5._owner)
end
function t1._distanceFromLocalPlayerToAreaCenter(p6) -- line: 208
	-- upvalues: AssetPersonalityMotion (copy)
	return AssetPersonalityMotion.DistanceFromPlayerToAreaCenter(p6._localPlayer, p6._assetArea)
end
function t1._chooseNextDestination(p7, unstick: boolean?) -- line: 212
	-- upvalues: AssetPersonalityMotion (copy)
	local v30 = p7:_ownerRootPosition()
	local Movement = p7._config.Movement
	local space = p7._space

	p7._walkSpeed = p7:_rollWalkSpeed()
	-- ANIMPOLISH: a few candidates of the personality's choice; the first with room around it (other heroes, where they
	-- are heading, the terminal, eggs) wins, else the roomiest. NPC pass: a candidate whose straight path crosses an
	-- obstacle ranks last (the hero would push into it); `unstick` (the watchdog) samples the whole pen and wants a
	-- spot a few studs away
	local from = if space then Vector3.new(space.X, 0.0, space.Z) else nil
	local best, bestRoom = nil, -math.huge
	for _ = 1, if unstick then UNSTICK_TRIES else DESTINATION_TRIES do
		local candidate = if unstick then AssetWanderArea.RandomPoint(p7._assetArea, p7._random, p7._margin)
			else AssetPersonalityMotion.ChooseDestination(p7._assetArea, p7._random, Movement, v30, p7._margin)
		local room = if space then AssetPenSpace.Clearance(space, candidate) else math.huge
		if space and from and not AssetPenSpace.PathClear(space, from, candidate) then
			room -= PATH_BLOCKED_PENALTY
		end
		if unstick and from and Vector3.new(candidate.X - from.X, 0.0, candidate.Z - from.Z).Magnitude < 3.0 then
			room -= 10.0
		end
		if room > bestRoom then
			best, bestRoom = candidate, room
		end
		if room >= DESTINATION_ROOM then
			break
		end
	end
	p7._destination = best
	p7:_trackDestination()
	p7._mode = if not unstick and p7._random:NextNumber() < Movement.CurvedWanderChance then "Curve" else "Destination"
end
-- Publishes the destination to the pen space and gives the walk a time budget (a blocked hero picks another one).
function t1._trackDestination(self)
	local destination = self._destination
	local space = self._space
	if space then
		AssetPenSpace.SetDestination(space, destination)
	end
	self._destinationElapsed = 0.0
	local distance = if space then Vector3.new(destination.X - space.X, 0.0, destination.Z - space.Z).Magnitude else 0.0
	self._destinationBudget = distance / math.max(self._walkSpeed, 1.0) * 2.0 + 3.0
end
-- Retreat (Shy / Scared) from the owner. NPC pass: the hero commits to one retreat spot; it is re-planned (at most every
-- RETREAT_REPICK_COOLDOWN s) only when the owner cut the way (the spot is no longer farther from the owner than where
-- the hero stands) or after the hero arrived / got blocked and cowered (the walk in _stepInner). The old code picked a
-- new destination every frame, and a random one when cornered: heroes jittered in place.
function t1._tryRetreatFromOwner(p8, cFrame: CFrame, vector3_2: Vector3, dt: number) -- line: 222
	-- upvalues: AssetRetreatMotion (copy), AssetPersonalityMotion (copy)
	local Retreat = p8._config.Movement.Retreat

	if Retreat == nil then
		p8._retreatOwnerWasClose = false
		p8._retreatActive = false

		return false
	end

	local position = cFrame.Position
	local ownerDistance = Vector3.new(position.X - vector3_2.X, 0.0, position.Z - vector3_2.Z).Magnitude

	if ownerDistance > Retreat.TriggerDistance + (if p8._retreatActive then RETREAT_HYSTERESIS else 0.0) then
		p8._retreatOwnerWasClose = false
		p8._retreatActive = false

		return false
	end

	if p8._retreatActive then
		p8._retreatCooldown = math.max(p8._retreatCooldown - dt, 0.0)

		if p8._idleRemaining <= 0.0 and p8._retreatCooldown <= 0.0 then
			local destination = p8._destination
			local destinationDistance = Vector3.new(destination.X - vector3_2.X, 0.0, destination.Z - vector3_2.Z).Magnitude

			if destinationDistance < ownerDistance + 0.5 then
				p8:_retreatReplan(cFrame, vector3_2, ownerDistance)
			end
		end

		return true
	end

	if p8._retreatOwnerWasClose then
		return false
	end

	p8._retreatOwnerWasClose = true

	if not AssetPersonalityMotion.RollChance(p8._random, Retreat.Chance) then
		return false
	end

	p8._retreatActive = true
	p8._walkSpeed = p8:_rollWalkSpeed()
	p8:_retreatReplan(cFrame, vector3_2, ownerDistance)

	return true
end
-- One retreat plan: walk to a spot at least RETREAT_MIN_GAIN farther from the owner, or (cornered) cower where it is.
-- `explore` = re-planning after the watchdog: a randomised direction whose straight path is clear of obstacles.
function t1._retreatReplan(self, cFrame: CFrame, ownerPosition: Vector3, ownerDistance: number, explore: boolean?): boolean
	local position = cFrame.Position
	-- (Destination takes the owner first, then the hero)
	local candidate = AssetRetreatMotion.Destination(self._assetArea, self._random, self._config.Movement.Retreat, ownerPosition, position,
		self._margin, explore == true)

	self._retreatCooldown = RETREAT_REPICK_COOLDOWN
	self._mode = "Destination"

	if candidate ~= nil and explore == true and self._space ~= nil and not AssetPenSpace.PathClear(self._space, position, candidate) then
		candidate = nil
	end

	if candidate ~= nil and Vector3.new(candidate.X - ownerPosition.X, 0.0, candidate.Z - ownerPosition.Z).Magnitude >= ownerDistance + RETREAT_MIN_GAIN then
		self._destination = candidate
		self._idleRemaining = 0.0
		self._idleAnchorCFrame = nil
		self:_trackDestination()

		return true
	end

	-- cornered: stand still (the Scared tremble plays) and look again in a moment
	self._destination = position
	self:_trackDestination()
	self:_beginCower(cFrame)

	return false
end
function t1._beginCower(self, cFrame: CFrame)
	self._idleRemaining = self._random:NextNumber(COWER_SECONDS_MIN, COWER_SECONDS_MAX)
	self._idleAnchorCFrame = cFrame
	self._idleElapsed = 0.0
end
-- No-progress watchdog (NPC pass). `trying` = the hero wants to walk this frame. Returns true once the hero has been
-- trying for STUCK_SECONDS without getting STUCK_STUDS away from where it stood (the caller re-plans).
function t1._watchProgress(self, dt: number, position: Vector3, trying: boolean): boolean
	self._progressTouched = true

	local anchor = self._progressAnchor

	if not trying or anchor == nil or Vector3.new(position.X - anchor.X, 0.0, position.Z - anchor.Z).Magnitude >= STUCK_STUDS then
		self._progressAnchor = if trying then position else nil
		self._progressSeconds = 0.0

		return false
	end

	self._progressSeconds += dt

	if self._progressSeconds < STUCK_SECONDS then
		return false
	end

	self._progressAnchor = nil
	self._progressSeconds = 0.0

	return true
end
-- The watchdog fired on a plain walk: a short pause, then a destination with a clear path somewhere else in the pen
-- (a retreating hero re-plans its retreat instead).
function t1._unstick(self, cFrame: CFrame, ownerPosition: Vector3?)
	if self._retreatActive and ownerPosition ~= nil then
		local position = cFrame.Position

		-- a new (randomised, clear) way out after a short pause, or cower when there is none
		if self:_retreatReplan(cFrame, ownerPosition, Vector3.new(position.X - ownerPosition.X, 0.0, position.Z - ownerPosition.Z).Magnitude, true) then
			self._idleRemaining = self._random:NextNumber(UNSTICK_PAUSE_MIN, UNSTICK_PAUSE_MAX)
			self._idleAnchorCFrame = cFrame
			self._idleElapsed = 0.0
		end

		return
	end

	self._idleRemaining = self._random:NextNumber(UNSTICK_PAUSE_MIN, UNSTICK_PAUSE_MAX)
	self._idleAnchorCFrame = cFrame
	self._idleElapsed = 0.0
	self:_chooseNextDestination(true)
end
function t1._beginIdle(p9, cFrame: CFrame) -- line: 269
	local Movement = p9._config.Movement

	p9._idleRemaining = p9._random:NextNumber(Movement.IdleSecondsMin, Movement.IdleSecondsMax)
	p9._idleAnchorCFrame = cFrame
	p9._idleElapsed = 0.0
end
function t1._stepIdle(p10, n4: number) -- line: 276
	-- upvalues: AssetPersonalityMotion (copy)
	local _idleAnchorCFrame = p10._idleAnchorCFrame

	assert(_idleAnchorCFrame ~= nil, "Idle phase requires a stable anchor CFrame")

	local v42, v43, v44, v45 = AssetPersonalityMotion.StepIdle(n4, p10._idleRemaining, p10._idleElapsed, _idleAnchorCFrame, p10:_tremble())

	p10._idleRemaining = v43
	p10._idleElapsed = v44

	if v45 then
		p10._idleAnchorCFrame = nil
		p10._idleElapsed = 0.0
	end

	return p10:_applyJump(n4, v42)
end
-- The personality's idle tremble scaled by the profile (a hero shivers; sliding the whole rig 1.5 studs looked broken).
function t1._tremble(self)
	local source = self._config.Movement.IdleTremble
	if source == nil or self._trembleScale == 1.0 then
		return source
	end
	if self._trembleSource ~= source then
		self._trembleSource = source
		self._trembleScaled = { Amplitude = source.Amplitude * self._trembleScale, CyclesPerSecond = source.CyclesPerSecond }
	end
	return self._trembleScaled
end
function t1._tryAmbientJump(p11, n5: number) -- line: 296
	-- upvalues: AssetPersonalityMotion (copy)
	local Movement = p11._config.Movement

	if AssetPersonalityMotion.ShouldStartAmbientJump(p11._random, Movement.AmbientJumpRatePerSecond, n5, p11._jumpRemaining > 0.0) then
		p11:_startJump(Movement.AmbientSpinJumpChance)
	end
end
function t1._startJump(p12, n6: number?) -- line: 310
	if p12._jumpRemaining > 0.0 then
		return
	end

	local v51 = if n6 == nil then p12._config.Greeting.SpinJumpChance else n6

	p12._jumpRemaining = 0.45
	p12._jumpElapsed = 0.0
	p12._spinAppliedYaw = 0.0

	local v52 = not (p12._random:NextNumber() < 0.5) and 1.0 or -1.0

	p12._spinYaw = not (v51 > p12._random:NextNumber()) and 0.0 or 6.283185307179586 * v52
end
function t1._resetGreetingFinish(p13) -- line: 323
	p13._finishJumpsRemaining = 0.0
	p13._finishJumpCooldown = 0.0
end
function t1._resetReturnGreeting(p14) -- line: 328
	p14._returnGreetingHoldRemaining = 0.0
	p14._returnGreetingJumpsRemaining = 0.0
	p14._returnGreetingJumpCooldown = 0.0
	p14._returnGreetingOwnerOffset = nil
end
function t1._resetAffection(p15) -- line: 335
	p15._affectionHoldRemaining = 0.0
	p15._affectionJumpsRemaining = 0.0
	p15._affectionJumpCooldown = 0.0
	p15._affectionOwnerOffset = nil
	p15._pendingBubbleText = nil
end
function t1._popBubbleText(p16) -- line: 343
	local _pendingBubbleText = p16._pendingBubbleText

	p16._pendingBubbleText = nil

	return _pendingBubbleText
end
function t1._beginGreetingFinish(p17) -- line: 350
	p17._phase = "GreetingFinish"
	p17._greetRemaining = 1.2
	p17._finishJumpsRemaining = 2.0
	p17._finishJumpCooldown = 0.0
	p17._lastOwnerPosition = nil
end
function t1._beginGreetingOrbit(p18, b2: boolean) -- line: 358
	-- upvalues: Asserts (copy), AssetPersonalityMotion (copy)
	Asserts.boolean(b2)

	local Greeting = p18._config.Greeting

	p18._phase = "GreetingOrbit"
	p18._greetRemaining = math.min(Greeting.DurationSeconds, 3.0)
	p18._randomOrbitInsideSeconds = 0.0
	p18._idleRemaining = 0.0
	p18._lastOwnerPosition = nil
	p18:_resetGreetingFinish()
	p18:_resetReturnGreeting()
	p18:_resetAffection()

	if b2 then
		p18._pendingBubbleText = AssetPersonalityMotion.RandomConfiguredText(p18._random, Greeting.Texts, p18._config._id, "greeting")
	end
end
function t1._tryStartGreetingOrbit(p19, n7: number, b3: boolean) -- line: 376
	-- upvalues: Asserts (copy), AssetPersonalityMotion (copy)
	Asserts.boolean(b3)

	local Greeting = p19._config.Greeting

	if n7 <= 0.0 or Greeting.DurationSeconds <= 0.0 then
		return false
	end

	if not AssetPersonalityMotion.RollChance(p19._random, n7) then
		return false
	end

	p19:_beginGreetingOrbit(b3)

	return true
end
function t1._beginNormalGreeting(p20, vector3: Vector3, n8: number, n9: number, b4: boolean) -- line: 393
	-- upvalues: Asserts (copy), AssetPersonalityMotion (copy), AssetWanderArea (copy)
	Asserts.boolean(b4)

	local v71 = p20:_roomyOwnerOffset(vector3)

	p20._phase = "ReturnGreetingApproach"
	p20._returnGreetingOwnerOffset = v71
	p20._returnGreetingHoldRemaining = math.min(n9, 20.0)
	p20._returnGreetingJumpsRemaining = n8
	p20._returnGreetingJumpCooldown = 0.0
	p20._destination = AssetWanderArea.PointNearOwner(p20._assetArea, vector3, v71, p20._margin)
	p20._approachElapsed = 0.0
	p20._shuffles = 0
	p20._idleRemaining = 0.0
	p20._walkSpeed = p20:_rollWalkSpeed()
	p20._lastOwnerPosition = nil
	p20:_resetGreetingFinish()
	p20:_resetAffection()

	if b4 then
		p20._pendingBubbleText = AssetPersonalityMotion.RandomConfiguredText(p20._random, p20._config.Greeting.Texts, p20._config._id, "greeting")
	end
end
function t1._tryStartFirstPlacementGreeting(p21) -- line: 426
	-- upvalues: AssetPersonalityMotion (copy)
	p21._joinGreetingPending = false

	local Greeting = p21._config.Greeting

	if p21:_tryStartGreetingOrbit(Greeting.FirstPlacementChance, true) then
		return
	end

	local FirstPlacementBubbleChance = Greeting.FirstPlacementBubbleChance

	if FirstPlacementBubbleChance ~= nil and FirstPlacementBubbleChance > 0.0 and AssetPersonalityMotion.RollChance(p21._random, FirstPlacementBubbleChance) then
		p21._pendingBubbleText = AssetPersonalityMotion.RandomConfiguredText(p21._random, Greeting.Texts, p21._config._id, "greeting")

		return
	end

	local v75 = p21:_ownerRootPosition()

	if v75 == nil or not AssetPersonalityMotion.RollChance(p21._random, Greeting.FirstPlacementNormalChance) then
		return
	end

	local FirstPlacementNormalJumpCount = Greeting.FirstPlacementNormalJumpCount

	if FirstPlacementNormalJumpCount <= 0.0 then
		return
	end

	p21:_beginNormalGreeting(v75, FirstPlacementNormalJumpCount, 0.6 * FirstPlacementNormalJumpCount, true)
end
function t1._tryStartReturnGreeting(p22, vector3: Vector3, b5: boolean) -- line: 454
	-- upvalues: Asserts (copy), AssetPersonalityMotion (copy)
	Asserts.boolean(b5)

	local Greeting = p22._config.Greeting

	if Greeting.Chance <= 0.0 or Greeting.DurationSeconds <= 0.0 then
		return
	end

	if not AssetPersonalityMotion.RollChance(p22._random, Greeting.Chance) then
		return
	end

	if b5 and p22:_tryStartGreetingOrbit(Greeting.ReturnOrbitChance, false) then
		return
	end

	p22:_beginNormalGreeting(vector3, Greeting.ReturnNormalJumpCount, math.min(Greeting.DurationSeconds, 20.0), false)
end
function t1._beginAffection(p23, vector3: Vector3) -- line: 479
	-- upvalues: AssetPersonalityMotion (copy), AssetWanderArea (copy)
	local Affection = p23._config.Affection
	local v84 = p23:_roomyOwnerOffset(vector3)

	p23._phase = "AffectionApproach"
	p23._affectionOwnerOffset = v84
	p23._destination = AssetWanderArea.PointNearOwner(p23._assetArea, vector3, v84, p23._margin)
	p23._approachElapsed = 0.0
	p23._shuffles = 0
	p23._idleRemaining = 0.0
	p23._walkSpeed = p23:_rollWalkSpeed()
	p23._affectionHoldRemaining = Affection.DurationSeconds
	p23._affectionJumpsRemaining = Affection.JumpCount
	p23._affectionJumpCooldown = 0.0
	p23._pendingBubbleText = nil
	p23._lastOwnerPosition = nil
	p23:_resetGreetingFinish()
end
function t1._updateAffectionTrigger(p24, n10: number, vector3: Vector3?) -- line: 497
	-- upvalues: AssetWanderArea (copy), AssetPersonalityMotion (copy)
	if p24._phase ~= "Normal" then
		return
	end

	local Affection = p24._config.Affection

	if not Affection.Enabled or Affection.IntervalSeconds <= 0.0 or vector3 == nil then
		p24._affectionInsideSeconds = 0.0

		return
	end

	if not AssetWanderArea.IsPositionInside(p24._assetArea, vector3) then
		p24._affectionInsideSeconds = 0.0

		return
	end

	p24._affectionInsideSeconds = p24._affectionInsideSeconds + n10

	if p24._affectionInsideSeconds < Affection.IntervalSeconds then
		return
	end

	p24._affectionInsideSeconds = 0.0

	if AssetPersonalityMotion.RollChance(p24._random, Affection.Chance) then
		p24:_beginAffection(vector3)
	end
end
function t1._updateOrbitGreetingTrigger(p25, n11: number, vector3: Vector3?) -- line: 528
	-- upvalues: AssetWanderArea (copy)
	if p25._phase ~= "Normal" then
		return
	end

	local Greeting = p25._config.Greeting

	if Greeting.RandomOrbitChance <= 0.0 or Greeting.RandomOrbitIntervalSeconds <= 0.0 or Greeting.DurationSeconds <= 0.0 or vector3 == nil then
		p25._randomOrbitInsideSeconds = 0.0

		return
	end

	if not AssetWanderArea.IsPositionInside(p25._assetArea, vector3) then
		p25._randomOrbitInsideSeconds = 0.0

		return
	end

	p25._randomOrbitInsideSeconds = p25._randomOrbitInsideSeconds + n11

	if p25._randomOrbitInsideSeconds < Greeting.RandomOrbitIntervalSeconds then
		return
	end

	p25._randomOrbitInsideSeconds = 0.0
	p25:_tryStartGreetingOrbit(Greeting.RandomOrbitChance, false)
end
function t1._updateReturnGreeting(p26, n12: number) -- line: 562
	-- upvalues: AssetWanderArea (copy)
	if p26._phase ~= "Normal" then
		return
	end

	if p26._joinGreetingPending then
		local v95 = p26:_ownerRootPosition()

		if v95 == nil then
			return
		end

		p26._joinGreetingPending = false
		p26._farSeconds = 0.0
		p26._farRequiredSeconds = p26._random:NextNumber(105.0, 180.0)
		p26:_tryStartReturnGreeting(v95, AssetWanderArea.IsPositionInside(p26._assetArea, v95))

		return
	end

	local v96 = p26:_distanceFromLocalPlayerToAreaCenter()

	if v96 == nil then
		return
	end

	if v96 >= 200.0 then
		p26._farSeconds = p26._farSeconds + n12

		return
	end

	if p26._farSeconds >= p26._farRequiredSeconds and v96 <= 200.0 then
		p26._farSeconds = 0.0
		p26._farRequiredSeconds = p26._random:NextNumber(105.0, 180.0)

		local v97 = p26:_ownerRootPosition()

		if v97 ~= nil and AssetWanderArea.IsPositionInside(p26._assetArea, v97) then
			p26:_tryStartReturnGreeting(v97, true)

			return
		end
	else
		p26._farSeconds = 0.0
	end
end
function t1._updateGreeting(p27, n13: number) -- line: 598
	if p27._phase ~= "GreetingOrbit" and p27._phase ~= "GreetingFinish" then
		return
	end

	local v100 = p27:_distanceFromLocalPlayerToAreaCenter()

	if v100 ~= nil and v100 > 300.0 then
		p27._phase = "Normal"
		p27._greetRemaining = 0.0
		p27:_resetGreetingFinish()
		p27:_resetReturnGreeting()
		p27:_resetAffection()
		p27:_chooseNextDestination()

		return
	end

	p27._greetRemaining = math.max(p27._greetRemaining - n13, 0.0)

	if p27._phase == "GreetingOrbit" then
		if p27._greetRemaining <= 0.0 then
			p27:_beginGreetingFinish()

			return
		end

		if p27._random:NextNumber() < p27._config.Greeting.JumpChancePerSecond * n13 then
			p27:_startJump()
		end

		return
	end

	p27._finishJumpCooldown = math.max(p27._finishJumpCooldown - n13, 0.0)

	if p27._finishJumpsRemaining > 0.0 and p27._finishJumpCooldown <= 0.0 then
		p27:_startJump(0.0)
		p27._finishJumpsRemaining = p27._finishJumpsRemaining - 1.0
		p27._finishJumpCooldown = 0.6
	end

	if p27._finishJumpsRemaining <= 0.0 and p27._jumpRemaining <= 0.0 and p27._greetRemaining <= 0.0 then
		p27._phase = "Normal"
		p27:_resetGreetingFinish()
		p27:_resetReturnGreeting()
		p27:_resetAffection()
		p27:_chooseNextDestination()
	end
end
function t1._stepReturnGreeting(p28, n14: number, cFrame: CFrame, vector3: Vector3) -- line: 642
	-- upvalues: AssetWanderArea (copy), AssetWanderMotion (copy)
	if p28._phase == "ReturnGreetingApproach" then
		local _returnGreetingOwnerOffset = p28._returnGreetingOwnerOffset

		assert(_returnGreetingOwnerOffset ~= nil, "Return greeting approach requires a stable owner offset")
		p28._destination = AssetWanderArea.PointNearOwner(p28._assetArea, vector3, _returnGreetingOwnerOffset, p28._margin)

		local v106, v107, v108 = AssetWanderMotion.StepMoveToward(n14, cFrame, p28._destination, p28._walkSpeed, p28:_avoidance(cFrame))

		p28._approachElapsed += n14

		-- NPC pass: blocked on the way (no progress) = greet from here
		local far = Vector3.new(p28._destination.X - v106.Position.X, 0.0, p28._destination.Z - v106.Position.Z).Magnitude > 2.25

		if far and p28._approachElapsed < APPROACH_TIMEOUT and not p28:_watchProgress(n14, cFrame.Position, true) then
			local v109, v110 = p28:_applyJump(n14, v106)

			return v109, v107 or p28._jumpRemaining > 0.0, v110, v108
		end

		p28._phase = "ReturnGreetingHold"
		p28._returnGreetingJumpCooldown = 0.0

		if p28._returnGreetingJumpsRemaining > 0.0 then
			p28:_startJump(0.0)
			p28._returnGreetingJumpsRemaining = p28._returnGreetingJumpsRemaining - 1.0
			p28._returnGreetingJumpCooldown = 0.6
		end

		local v111, v112 = p28:_applyJump(n14, (AssetWanderMotion.FaceOwnerCFrame(v106, vector3, n14, true)))

		return v111, v107 or p28._jumpRemaining > 0.0, v112, v108
	end

	if p28:_shuffleWhenCrowded(n14, cFrame, vector3, "ReturnGreetingApproach", "_returnGreetingOwnerOffset") then
		local shuffled, shuffledGrounded = p28:_applyJump(n14, cFrame)

		return shuffled, p28._jumpRemaining > 0.0, shuffledGrounded, 0.0
	end

	p28._returnGreetingHoldRemaining = math.max(p28._returnGreetingHoldRemaining - n14, 0.0)
	p28._returnGreetingJumpCooldown = math.max(p28._returnGreetingJumpCooldown - n14, 0.0)

	if p28._returnGreetingJumpsRemaining > 0.0 and p28._returnGreetingJumpCooldown <= 0.0 then
		p28:_startJump(0.0)
		p28._returnGreetingJumpsRemaining = p28._returnGreetingJumpsRemaining - 1.0
		p28._returnGreetingJumpCooldown = 0.6
	end

	local v113, v114 = p28:_applyJump(n14, (AssetWanderMotion.FaceOwnerCFrame(cFrame, vector3, n14)))

	if p28._returnGreetingHoldRemaining <= 0.0 and p28._returnGreetingJumpsRemaining <= 0.0 and p28._jumpRemaining <= 0.0 then
		p28._phase = "Normal"
		p28:_resetReturnGreeting()
		p28:_chooseNextDestination()
	end

	return v113, p28._jumpRemaining > 0.0, v114, 0.0 -- ANIMPOLISH: standing (the clips read this as ground speed)
end
function t1._stepAffection(p29, n15: number, cFrame: CFrame, vector3: Vector3) -- line: 699
	-- upvalues: AssetWanderArea (copy), AssetWanderMotion (copy), AssetPersonalityMotion (copy)
	if p29._phase == "AffectionApproach" then
		local _affectionOwnerOffset = p29._affectionOwnerOffset

		assert(_affectionOwnerOffset ~= nil, "Affection approach requires a stable owner offset")
		p29._destination = AssetWanderArea.PointNearOwner(p29._assetArea, vector3, _affectionOwnerOffset, p29._margin)

		local v120, v121, v122 = AssetWanderMotion.StepMoveToward(n15, cFrame, p29._destination, p29._walkSpeed, p29:_avoidance(cFrame))

		p29._approachElapsed += n15

		-- NPC pass: blocked on the way (no progress) = show affection from here
		local far = Vector3.new(p29._destination.X - v120.Position.X, 0.0, p29._destination.Z - v120.Position.Z).Magnitude > 2.25

		if far and p29._approachElapsed < APPROACH_TIMEOUT and not p29:_watchProgress(n15, cFrame.Position, true) then
			local v123, v124 = p29:_applyJump(n15, v120)

			return v123, v121 or p29._jumpRemaining > 0.0, v124, v122
		end

		p29._phase = "AffectionHold"
		p29._affectionJumpCooldown = 0.6
		p29._pendingBubbleText = AssetPersonalityMotion.RandomConfiguredText(p29._random, p29._config.Affection.Texts, p29._config._id, "affection")

		if p29._affectionJumpsRemaining > 0.0 then
			p29:_startJump(0.0)
			p29._affectionJumpsRemaining = p29._affectionJumpsRemaining - 1.0
		end

		local v125, v126 = p29:_applyJump(n15, (AssetWanderMotion.FaceOwnerCFrame(v120, vector3, n15, true)))

		return v125, v121 or p29._jumpRemaining > 0.0, v126, v122
	end

	if p29:_shuffleWhenCrowded(n15, cFrame, vector3, "AffectionApproach", "_affectionOwnerOffset") then
		local shuffled, shuffledGrounded = p29:_applyJump(n15, cFrame)

		return shuffled, p29._jumpRemaining > 0.0, shuffledGrounded, 0.0
	end

	p29._affectionHoldRemaining = math.max(p29._affectionHoldRemaining - n15, 0.0)
	p29._affectionJumpCooldown = math.max(p29._affectionJumpCooldown - n15, 0.0)

	if p29._affectionJumpsRemaining > 0.0 and p29._affectionJumpCooldown <= 0.0 then
		p29:_startJump(0.0)
		p29._affectionJumpsRemaining = p29._affectionJumpsRemaining - 1.0
		p29._affectionJumpCooldown = 0.6
	end

	local v127, v128 = p29:_applyJump(n15, (AssetWanderMotion.FaceOwnerCFrame(cFrame, vector3, n15)))

	if p29._affectionHoldRemaining <= 0.0 and p29._affectionJumpsRemaining <= 0.0 and p29._jumpRemaining <= 0.0 then
		p29._phase = "Normal"
		p29:_resetAffection()
		p29:_chooseNextDestination()
	end

	return v127, p29._jumpRemaining > 0.0, v128, 0.0 -- ANIMPOLISH: standing
end
function t1._updateCurve(p30, n16: number, vector3: Vector3) -- line: 755
	-- upvalues: AssetWanderArea (copy)
	p30._curveChangeElapsed = p30._curveChangeElapsed + n16

	if p30._curveChangeElapsed >= p30._nextCurveChangeSeconds then
		p30._curveChangeElapsed = 0.0
		p30._nextCurveChangeSeconds = p30._random:NextNumber(5.0, 10.0)
		p30._curveAngle = p30._random:NextNumber(-3.141592653589793, 3.141592653589793)
		p30._curveRotationSpeed = p30._random:NextNumber(-0.8, 0.8)
	end

	p30._curveAngle = p30._curveAngle + p30._curveRotationSpeed * n16

	local v132 = vector3 + Vector3.new(math.cos(p30._curveAngle), 0.0, (math.sin(p30._curveAngle))) * 9.0

	p30._destination = AssetWanderArea.ClampedPointToward(p30._assetArea, v132, p30._margin)
end
function t1._orbitGreetingCFrame(p31, n17: number, cFrame: CFrame, vector3: Vector3) -- line: 770
	-- upvalues: AssetWanderMotion (copy)
	local v137, v138 = AssetWanderMotion.OwnerMoveVector(n17, vector3, p31._lastOwnerPosition)

	p31._lastOwnerPosition = v138

	return AssetWanderMotion.OrbitGreetingCFrame(p31._assetArea, n17, cFrame, vector3, v137, p31._greetingOrbitRadius,
		math.min(ORBIT_SPEED * p31._speedScale, math.max(p31._speedMax, p31._speedMin)), 0.75, p31._margin)
end
function t1._applyJump(p32, n18: number, cFrame: CFrame) -- line: 791
	if p32._jumpRemaining <= 0.0 then
		return cFrame, true
	end

	p32._jumpRemaining = math.max(p32._jumpRemaining - n18, 0.0)
	p32._jumpElapsed = math.min(p32._jumpElapsed + n18, 0.45)

	local v142 = p32._jumpElapsed / 0.45
	local v143 = math.sin(v142 * 3.141592653589793) * p32._jumpHeight
	local v144 = p32._spinYaw == 0.0 and 0.0 or p32._spinYaw * v142
	local v145 = v144 - p32._spinAppliedYaw

	p32._spinAppliedYaw = v144

	local v146 = CFrame.new(cFrame.Position + Vector3.new(0.0, v143, 0.0)) * cFrame.Rotation

	if v145 ~= 0.0 then
		v146 *= CFrame.Angles(0.0, v145, 0.0)
	end

	if p32._jumpRemaining <= 0.0 then
		p32._spinAppliedYaw = 0.0
	end

	return v146, p32._jumpRemaining <= 0.0
end
function t1.SetAssetArea(p33, p34) -- line: 818
	-- upvalues: Asserts (copy), AssetPersonalityMotion (copy)
	Asserts.BasePart(p34)

	local v149 = p34 ~= p33._assetArea

	p33._assetArea = p34

	if v149 then
		AssetPenSpace.Leave(p33._space)
		p33._space = AssetPenSpace.Join(p34, p33._radius)
		p33._loyalOwnerOffset = AssetPersonalityMotion.RandomOwnerOffset(p34, p33._random, p33._greetingOrbitRadius)
		p33._returnGreetingOwnerOffset = if p33._returnGreetingOwnerOffset == nil then nil else AssetPersonalityMotion.RandomOwnerOffset(p34, p33._random, p33._greetingOrbitRadius)
		p33._affectionOwnerOffset = if p33._affectionOwnerOffset == nil then nil else AssetPersonalityMotion.RandomOwnerOffset(p34, p33._random, p33._greetingOrbitRadius)
	end

	p33:_chooseNextDestination()
end
function t1.SetItemData(p35, p36, b6: boolean) -- line: 836
	-- upvalues: AssetItem (copy), Asserts (copy), Personalities (copy)
	assert(AssetItem.AssetItemData(p36), "Invalid asset item data")
	Asserts.boolean(b6)
	p35._itemData = p36
	p35._config = Personalities.GetConfig(p36.Personality)

	if b6 then
		p35:_tryStartFirstPlacementGreeting()
	end
end
function t1._stepInner(p37, n19: number, cFrame: CFrame) -- line: 851
	-- upvalues: Asserts (copy), AssetWanderMotion (copy), AssetWanderArea (copy), AssetMutationWalkSpeed (copy)
	Asserts.number(n19)
	Asserts.CFrame(cFrame)
	p37:_updateReturnGreeting(n19)
	p37:_updateGreeting(n19)

	local cFramePosition = cFrame.Position
	local v157 = p37:_ownerRootPosition()

	if p37._phase ~= "Normal" and v157 == nil then
		p37._phase = "Normal"
		p37._greetRemaining = 0.0
		p37:_resetGreetingFinish()
		p37:_resetReturnGreeting()
		p37:_resetAffection()
		p37:_chooseNextDestination()
	end

	p37:_updateAffectionTrigger(n19, v157)
	p37:_updateOrbitGreetingTrigger(n19, v157)

	-- NPC pass: the decompiled `phase == Normal and (owner == nil or retreat)` froze every hero of a pen whose owner's
	-- character was missing (they walked to their last destination and stood there): no owner = no retreat, wander on
	if v157 == nil then
		p37._retreatActive = false
		p37._retreatOwnerWasClose = false
	end

	local v158 = p37._phase == "Normal" and v157 ~= nil and p37:_tryRetreatFromOwner(cFrame, v157, n19)

	if p37._phase == "Normal" then
		p37:_tryAmbientJump(n19)
	end

	if p37._idleRemaining > 0.0 and p37._phase == "Normal" and p37._space ~= nil then
		-- ANIMPOLISH: an idler somebody walked into (or who stopped on another) walks off instead of overlapping
		if AssetPenSpace.Crowded(p37._space, cFramePosition) then
			p37._crowdedSeconds += n19
			if p37._crowdedSeconds >= CROWDED_IDLE_SECONDS then
				p37._crowdedSeconds = 0.0
				p37._idleRemaining = 0.0
				p37._idleAnchorCFrame = nil
				if v158 then
					p37._retreatCooldown = 0.0
					p37:_retreatReplan(cFrame, v157, Vector3.new(cFramePosition.X - v157.X, 0.0, cFramePosition.Z - v157.Z).Magnitude)
				else
					p37:_chooseNextDestination()
				end
			end
		else
			p37._crowdedSeconds = 0.0
		end
	end

	if p37._idleRemaining > 0.0 and p37._phase == "Normal" then
		local v159, v160 = p37:_stepIdle(n19)

		return v159, p37._jumpRemaining > 0.0, v160, 0.0, false, p37:_popBubbleText()
	end

	if p37._phase == "GreetingOrbit" and v157 ~= nil then
		local v161, v162, v163 = p37:_orbitGreetingCFrame(n19, cFrame, v157)
		local v164, v165 = p37:_applyJump(n19, v161)

		return v164, v162 or p37._jumpRemaining > 0.0, v165, v163, true, p37:_popBubbleText()
	end

	if p37._phase == "GreetingFinish" and v157 ~= nil then
		local v166, v167 = p37:_applyJump(n19, (AssetWanderMotion.FaceOwnerCFrame(cFrame, v157, n19)))

		return v166, p37._jumpRemaining > 0.0, v167, 0.0, true, p37:_popBubbleText()
	end

	if (p37._phase == "ReturnGreetingApproach" or p37._phase == "ReturnGreetingHold") and v157 ~= nil then
		local v168, v169, v170, v171 = p37:_stepReturnGreeting(n19, cFrame, v157)

		return v168, v169, v170, v171, false, p37:_popBubbleText()
	end

	if (p37._phase == "AffectionApproach" or p37._phase == "AffectionHold") and v157 ~= nil then
		local v172, v173, v174, v175 = p37:_stepAffection(n19, cFrame, v157)

		return v172, v173, v174, v175, false, p37:_popBubbleText()
	end

	if p37._config.Movement.FollowOwnerInPen and v157 ~= nil and AssetWanderArea.IsPositionInside(p37._assetArea, v157) then
		-- NPC pass: a follower that cannot reach its spot by the owner (another hero, the terminal, an egg, the fence)
		-- pauses and takes a roomier spot of the ring instead of pushing into it forever
		local followPoint = AssetWanderArea.PointNearOwner(p37._assetArea, v157, p37._loyalOwnerOffset, p37._margin)
		local followFar = Vector3.new(followPoint.X - cFramePosition.X, 0.0, followPoint.Z - cFramePosition.Z).Magnitude > 2.5

		if p37:_watchProgress(n19, cFramePosition, followFar) then
			p37._loyalOwnerOffset = p37:_roomyOwnerOffset(v157)
			p37._idleRemaining = p37._random:NextNumber(UNSTICK_PAUSE_MIN, UNSTICK_PAUSE_MAX)
			p37._idleAnchorCFrame = cFrame
			p37._idleElapsed = 0.0

			local paused, pausedGrounded = p37:_applyJump(n19, cFrame)

			return paused, p37._jumpRemaining > 0.0, pausedGrounded, 0.0, false, p37:_popBubbleText()
		end

		local v176, v177, v178 = AssetWanderMotion.StepFollowOwner(p37._assetArea, n19, cFrame, v157, p37._loyalOwnerOffset, p37._walkSpeed, 2.25,
			p37._margin, p37:_avoidance(cFrame))
		local v179, v180 = p37:_applyJump(n19, v176)

		return v179, v177 or p37._jumpRemaining > 0.0, v180, v178, false, p37:_popBubbleText()
	end

	if p37._mode == "Curve" then
		p37:_updateCurve(n19, cFrame.Position)
	end

	local _destination = p37._destination
	local v182 = _destination - cFramePosition
	local remaining = Vector3.new(v182.X, 0.0, v182.Z).Magnitude

	-- ANIMPOLISH: a destination somebody else took (or one blocked for too long) counts as reached
	p37._destinationElapsed += n19
	local blocked = p37._destinationElapsed > p37._destinationBudget
		or (remaining <= p37._radius * 2.0 + 1.5 and p37._space ~= nil and AssetPenSpace.Crowded(p37._space, _destination))

	if remaining <= 0.35 or blocked then
		if v158 then
			-- NPC pass: a retreat that arrived (or got blocked) cowers a moment, then looks for a spot farther away
			p37:_beginCower(cFrame)
			p37._retreatCooldown = 0.0
		else
			p37:_beginIdle(cFrame)
			p37:_chooseNextDestination()
		end

		local v183, v184 = p37:_applyJump(n19, cFrame)

		return v183, p37._jumpRemaining > 0.0, v184, 0.0, false, p37:_popBubbleText()
	end

	-- NPC pass: no-progress watchdog (pushing into an obstacle / a hero / the fence corner)
	if p37:_watchProgress(n19, cFramePosition, true) then
		p37:_unstick(cFrame, v157)

		local v183, v184 = p37:_applyJump(n19, cFrame)

		return v183, p37._jumpRemaining > 0.0, v184, 0.0, false, p37:_popBubbleText()
	end

	local _walkSpeed = p37._walkSpeed

	if p37._random:NextNumber() < p37._config.Movement.BurstChance * n19 then
		_walkSpeed = math.min(p37._config.Movement.WalkSpeedMax * 1.25 * AssetMutationWalkSpeed.GetMultiplier(p37._itemData) * p37._speedScale,
			math.max(p37._speedMax, p37._speedMin) * 1.15)
		p37:_startJump()
	end

	local v186, v187, v188 = AssetWanderMotion.StepMoveToward(n19, cFrame, _destination, _walkSpeed, p37:_avoidance(cFrame))
	local v189, v190 = p37:_applyJump(n19, v186)

	return v189, v187 or p37._jumpRemaining > 0.0, v190, v188, false, p37:_popBubbleText()
end

-- ANIMPOLISH: the spot next to the owner a greeting / affection walks to: a few random angles, the roomiest wins (the
-- other heroes gathering round the owner stand side by side instead of on top of each other).
function t1._roomyOwnerOffset(self, ownerPosition: Vector3): Vector3
	local best, bestRoom = nil, -math.huge
	for try = 1, 6 do
		-- the ring round the owner widens when it is full
		local offset = AssetPersonalityMotion.RandomOwnerOffset(self._assetArea, self._random, self._greetingOrbitRadius * (1 + math.floor((try - 1) / 2) * 0.35))
		local room = if self._space then AssetPenSpace.Clearance(self._space, AssetWanderArea.PointNearOwner(self._assetArea, ownerPosition, offset, self._margin)) else math.huge
		if room > bestRoom then
			best, bestRoom = offset, room
		end
		if room >= DESTINATION_ROOM then
			break
		end
	end
	return best
end
-- ANIMPOLISH: a hero standing by its owner that another hero crowds for a moment walks to a roomier spot of the ring
-- (at most twice per greeting). Returns true when it left the hold for the approach.
function t1._shuffleWhenCrowded(self, dt: number, cFrame: CFrame, ownerPosition: Vector3, approachPhase: string, offsetField: string): boolean
	local space = self._space
	if space == nil or (self._shuffles or 0) >= 2 or not AssetPenSpace.Crowded(space, cFrame.Position) then
		self._holdCrowded = 0.0
		return false
	end
	self._holdCrowded = (self._holdCrowded or 0.0) + dt
	if self._holdCrowded < CROWDED_IDLE_SECONDS then
		return false
	end
	self._holdCrowded = 0.0
	self._shuffles = (self._shuffles or 0) + 1
	self[offsetField] = self:_roomyOwnerOffset(ownerPosition)
	self._phase = approachPhase
	self._approachElapsed = 0.0
	return true
end
-- ANIMPOLISH: the steering push of this frame, computed once per Step: neighbours (now and where they are heading),
-- obstacles, and the wander rectangle's edges (a hero curves away from the fence instead of scraping along it).
function t1._avoidance(self, cFrame: CFrame): Vector3?
	local avoid = self._avoid
	if avoid == nil and self._space ~= nil then
		local look = cFrame.LookVector
		local position = cFrame.Position
		avoid = AssetPenSpace.Steer(self._space, position, look.X * self._walkSpeed, look.Z * self._walkSpeed)
		local area = self._assetArea
		local halfX, halfZ = AssetWanderArea.HalfExtents(area, self._margin)
		local l = area.CFrame:PointToObjectSpace(position)
		local band = 1.5 + self._radius * 0.5
		local wx = math.max(l.X - (halfX - band), 0) - math.max(-halfX + band - l.X, 0)
		local wz = math.max(l.Z - (halfZ - band), 0) - math.max(-halfZ + band - l.Z, 0)
		if wx ~= 0 or wz ~= 0 then
			avoid -= area.CFrame:VectorToWorldSpace(Vector3.new(wx, 0, wz)) * (1.2 / band)
		end
		self._avoid = avoid
	end
	if avoid == nil or avoid == Vector3.zero then
		return nil
	end
	return avoid
end
function t1.Step(self, n19: number, cFrame: CFrame)
	local space = self._space
	if space ~= nil then
		AssetPenSpace.Move(space, cFrame.Position, n19)
	end
	self._avoid = nil
	self._progressTouched = false
	local target, moving, grounded, speed, greeting, bubble = self:_stepInner(n19, cFrame)
	if not self._progressTouched then
		-- not walking this frame (idle, hold, orbit...): the watchdog starts over next time
		self._progressAnchor = nil
		self._progressSeconds = 0.0
	end
	-- inside the hero's own wander rectangle (its footprint never crosses the fence) and outside the obstacles; the
	-- obstacle push-out keeps to the rectangle (NPC pass: the clamp and the push fought where an obstacle meets the
	-- fence) and the fence has the last word
	local position = target.Position
	local clamped = AssetWanderArea.ClampKeepHeight(self._assetArea, position, self._margin)
	if space ~= nil then
		local halfX, halfZ = AssetWanderArea.HalfExtents(self._assetArea, self._margin)
		clamped = AssetPenSpace.Resolve(space, clamped, n19, halfX, halfZ)
		clamped = AssetWanderArea.ClampKeepHeight(self._assetArea, clamped, self._margin)
	end
	if clamped ~= position then
		target = CFrame.new(clamped) * target.Rotation
	end
	return target, moving, grounded, speed, greeting, bubble
end
-- Footprint radius (studs, flat) of the rendered hero: wander margin + pen space size.
function t1.SetFootprint(self, radius: number)
	if typeof(radius) ~= "number" or radius ~= radius or radius <= 0 then
		return
	end
	self._radius = math.clamp(radius, 0.5, 20.0)
	self._margin = math.max(AssetWanderArea.DefaultMargin, self._radius + MARGIN_CLEARANCE)
	if self._space ~= nil then
		AssetPenSpace.SetRadius(self._space, self._radius)
	end
	self._destination = AssetWanderArea.ClampedPointToward(self._assetArea, self._destination, self._margin)
end
-- profile = { Scale = walk speed multiplier, Min / Max = studs/s band, Tremble = idle tremble multiplier } (all optional).
function t1.SetSpeedProfile(self, profile)
	if type(profile) ~= "table" then
		return
	end
	local function number(value, default)
		return if typeof(value) == "number" and value == value then value else default
	end
	self._speedScale = math.max(number(profile.Scale, 1.0), 0.05)
	self._speedMin = math.max(number(profile.Min, 0.0), 0.0)
	self._speedMax = math.max(number(profile.Max, math.huge), 0.5)
	self._trembleScale = math.max(number(profile.Tremble, 1.0), 0.0)
	self._trembleSource = nil
	self._walkSpeed = self:_rollWalkSpeed()
end
-- Holds the current idle for at least `seconds` more (normal wandering only).
function t1.ExtendIdle(self, seconds: number)
	if self._phase == "Normal" and self._idleRemaining > 0.0 and typeof(seconds) == "number" then
		self._idleRemaining = math.max(self._idleRemaining, math.min(seconds, 12.0))
	end
end
function t1.IsIdle(self): boolean
	return self._phase == "Normal" and self._idleRemaining > 0.0
end
function t1.Destroy(self)
	if self._space ~= nil then
		AssetPenSpace.Leave(self._space)
		self._space = nil
	end
end

return t1
