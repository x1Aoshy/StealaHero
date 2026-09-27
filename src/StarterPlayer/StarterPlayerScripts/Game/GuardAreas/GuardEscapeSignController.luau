-- StarterPlayer.StarterPlayerScripts.Game.GuardAreas.GuardEscapeSignController (ModuleScript)
-- Drives a stage's RequiredSpeedSign: the SpeedPower a carrier needs to outrun that stage's villain.
--
-- Game-plan restructure (docs/STAGES_PLAN.md A2/A3/A10): the sign now sits at the stage gate, eggs rotate over
-- the stage's EggSpots, the villain appears ~35 studs behind a carrier (GuardChaseService spawn-on-pickup)
-- and the chase lasts until the hub's safe zone. So the requirement is solved for the hardest active egg:
--   player start   = the active egg farthest from the safe zone (EggCmds area-egg records of this stage,
--                    else Workspace.StageEnvironments.<Key>.EggSpots, else the zone's ClosestExitPoint)
--   exit distance  = from there to the safe-zone line (X = 75) along the exit direction
--   villain start  = SPAWN_DISTANCE behind the player, or its post when that is closer and not between the player
--                    and the hub (post X >= player X, as GuardChaseService.resolveSpawnCFrame)
--   reach / speed  = the server's: HitDistance * (0.6 + 0.4 * RigScale), zone WalkSpeed x the guard's
--                    ChaseSpeedFactor (the steady speed a carrier must beat to survive the villain's surges or
--                    lunges, which GuardChaseService derives from its chase signatures; not their time average)
-- It recomputes when the active eggs rotate or the villain changes. Missing pieces never error: the sign
-- keeps its last value.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Areas = require(ReplicatedStorage.Directory.Areas)
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Guards = require(ReplicatedStorage.Directory.Guards)
local GuardChasePolicy = require(ReplicatedStorage.Library.Modules.GuardAreas.GuardChasePolicy)
local GuardEscapePrediction = require(ReplicatedStorage.Library.Modules.GuardAreas.GuardEscapePrediction)
local ResolveGuardSpeedRequirement = require(ReplicatedStorage.Library.Functions.ResolveGuardSpeedRequirement)
local SpeedPowerProjection = require(ReplicatedStorage.Library.Client.SpeedPowerProjection)
local TreadmillUtil = require(ReplicatedStorage.Library.Util.TreadmillUtil)
local Trove = require(ReplicatedStorage.Library.Modules.Packages.Trove)

local SAFE_ZONE_X = 75 -- the hub; the server chase ends there
local SPAWN_DISTANCE = 35 -- GuardChaseService SPAWN_DISTANCE
local REACH_FACTOR_BASE = 0.6
local REACH_FACTOR_PER_SCALE = 0.4
local RECOMPUTE_DELAY = 0.25
-- Burst-equivalent speed factor per chase signature: the effective steady speed (x zone WalkSpeed) a carrier must beat to
-- survive Darkseid's surge (0.8x/1.75x cycle) or Carnage's 1.5x lunge, relative to the same villain without it. The
-- server publishes the value it derives from its SIGNATURES as the guard's ChaseSpeedFactor attribute; this table is
-- only the fallback until that attribute replicates (it matches GuardChaseService's current signatures).
local SIGNATURE_SPEED_FACTOR = {
	Darkseid = 1.24,
	Carnage = 1.19,
}
local MIN_SPEED_FACTOR = 0.4 -- a replicated ChaseSpeedFactor outside this range is ignored
local MAX_SPEED_FACTOR = 4

local function resolveSpeedFactor(guard, signature)
	local published = guard and guard:GetAttribute("ChaseSpeedFactor")
	if type(published) == "number" and published >= MIN_SPEED_FACTOR and published <= MAX_SPEED_FACTOR then
		return published
	end
	return SIGNATURE_SPEED_FACTOR[signature] or 1
end

local GuardEscapeSignController = {}
GuardEscapeSignController.__index = GuardEscapeSignController
GuardEscapeSignController.__class = "GuardEscapeSignController"

local warned = {}
local function warnOnce(key, message)
	if not warned[key] then
		warned[key] = true
		warn("[GuardEscapeSignController] " .. message)
	end
end

local function lookup(directory, key)
	local ok, value = pcall(function()
		return directory[key]
	end)
	if ok then
		return value
	end
	return nil
end

local function resolveExitDirection()
	local objects = Workspace:FindFirstChild("__OBJECTS")
	local areas = objects and objects:FindFirstChild("Areas")
	local separationLine = areas and areas:FindFirstChild("SeparationLine")
	if separationLine and separationLine:IsA("BasePart") then
		local look = -separationLine.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 1e-3 then
			return flat.Unit
		end
	end
	return Vector3.new(-1, 0, 0)
end

-- Stage egg positions: the active eggs (records sitting in a nest), else every EggSpot marker, else nil.
local function collectCandidateSpots(areaModel, eggCmds)
	local spots = {}
	if eggCmds then
		local ok, snapshot = pcall(eggCmds.GetAreaEggSnapshot)
		if ok and type(snapshot) == "table" and type(snapshot.Records) == "table" then
			for _, record in ipairs(snapshot.Records) do
				if type(record) == "table" and record.AreaId == areaModel.Name and record.State == "Slot" and typeof(record.BottomCFrame) == "CFrame" then
					table.insert(spots, record.BottomCFrame.Position)
				end
			end
		end
	end
	if #spots > 0 then
		return spots
	end
	local environments = Workspace:FindFirstChild("StageEnvironments")
	local stage = environments and environments:FindFirstChild(areaModel.Name)
	local eggSpots = stage and stage:FindFirstChild("EggSpots")
	if eggSpots then
		for _, marker in ipairs(eggSpots:GetChildren()) do
			if marker:IsA("BasePart") then
				table.insert(spots, marker.Position)
			end
		end
	end
	if #spots > 0 then
		return spots
	end
	local exitPoint = areaModel:FindFirstChild("ClosestExitPoint")
	if exitPoint and exitPoint:IsA("BasePart") then
		return { exitPoint.Position }
	end
	return spots
end

function GuardEscapeSignController.new(areaModel, guardPostPosition: Vector3, requiredSpeedSign)
	Asserts.Model(areaModel)
	Asserts.Vector3(guardPostPosition)
	Asserts.table(requiredSpeedSign)

	local self = setmetatable({}, GuardEscapeSignController)
	self._areaModel = areaModel
	self._guardPostPosition = guardPostPosition
	self._requiredSpeedSign = requiredSpeedSign
	self._exitDirection = resolveExitDirection()
	self._playerWalkSpeed = TreadmillUtil.SpeedPowerToWalkSpeed(SpeedPowerProjection.GetSpeedPower())
	self._minimumEscapeWalkSpeed = nil
	self._eggCmds = nil
	self._recomputeQueued = false
	self._destroyed = false
	self._trove = Trove.new()

	self._trove:Add(SpeedPowerProjection.Changed:Connect(function(speedPower: number)
		self._playerWalkSpeed = TreadmillUtil.SpeedPowerToWalkSpeed(speedPower)
		self:_render()
	end))

	local guard = areaModel:FindFirstChild("Guard")
	if guard then
		for _, attribute in ipairs({ "RigScale", "ChaseSignature", "ChaseSpeedFactor", "HeroId" }) do
			self._trove:Add(guard:GetAttributeChangedSignal(attribute):Connect(function()
				self:_queueRecompute()
			end))
		end
	end

	self:_recompute()

	-- Active eggs rotate over the EggSpots: follow the client's area-egg records (required here, lazily, so
	-- the GuardAreas script never waits on it at load).
	task.spawn(function()
		local ok, eggCmds = pcall(function()
			return require(ReplicatedStorage.Library.Client.EggCmds)
		end)
		if self._destroyed or not ok or type(eggCmds) ~= "table" then
			return
		end
		self._eggCmds = eggCmds
		for _, signalName in ipairs({ "AreaEggSnapshotUpdated", "AreaEggUpdated", "AreaEggRemoved" }) do
			local signal = eggCmds[signalName]
			if signal and signal.Connect then
				self._trove:Add(signal:Connect(function()
					self:_queueRecompute()
				end))
			end
		end
		self:_queueRecompute()
	end)

	return self
end

function GuardEscapeSignController._queueRecompute(self)
	if self._recomputeQueued or self._destroyed then
		return
	end
	self._recomputeQueued = true
	task.delay(RECOMPUTE_DELAY, function()
		self._recomputeQueued = false
		if not self._destroyed then
			self:_recompute()
		end
	end)
end

function GuardEscapeSignController._buildScenario(self)
	local areaModel = self._areaModel
	local areaConfig = lookup(Areas.Directory, areaModel.Name)
	local guardConfig = areaConfig and lookup(Guards.Directory, areaConfig.GuardId)
	if type(guardConfig) ~= "table" then
		warnOnce("config:" .. areaModel.Name, areaModel.Name .. ": no guard config, sign left unchanged")
		return nil
	end
	local walkSpeed = tonumber(guardConfig.WalkSpeed)
	local flatRadius = tonumber(guardConfig.FlatRadius)
	if not walkSpeed or walkSpeed <= 0 or not flatRadius or flatRadius <= 0 then
		return nil
	end

	local guard = areaModel:FindFirstChild("Guard")
	local scale = tonumber(guard and guard:GetAttribute("RigScale")) or 1
	local signature = guard and guard:GetAttribute("ChaseSignature")
	local exitDirection = self._exitDirection
	local safePoint = Vector3.new(SAFE_ZONE_X, 0, 0)

	local playerStart, exitDistance = nil, -1
	for _, spot in ipairs(collectCandidateSpots(areaModel, self._eggCmds)) do
		local distance = (spot - safePoint):Dot(-exitDirection)
		if distance > exitDistance then
			playerStart, exitDistance = spot, distance
		end
	end
	if not playerStart then
		return nil
	end

	-- GuardChaseService: the villain appears SPAWN_DISTANCE behind the carrier unless its post is closer AND on the far
	-- side of the carrier (post X >= carrier X, balance #7). A post between the carrier and the hub (the far-side eggs of
	-- the post's EggSpot cluster) never counts: the server spawns the villain behind the carrier instead.
	local guardStart = playerStart - exitDirection * SPAWN_DISTANCE
	local post = self._guardPostPosition
	local postOnFarSide = (post - playerStart):Dot(exitDirection) <= 0 -- exit = -X: post.X >= playerStart.X
	if postOnFarSide and Vector3.new(post.X - playerStart.X, 0, post.Z - playerStart.Z).Magnitude < SPAWN_DISTANCE then
		guardStart = post
	end

	return {
		BaseGuardWalkSpeed = walkSpeed * resolveSpeedFactor(guard, signature),
		ExitDirection = exitDirection,
		ExitDistance = math.max(exitDistance, 0),
		FlatRadius = flatRadius,
		GuardStartPosition = guardStart,
		HitDistance = GuardChasePolicy.ResolveHitDistance(guardConfig.HitDistance) * (REACH_FACTOR_BASE + REACH_FACTOR_PER_SCALE * scale),
		PlayerStartPosition = playerStart,
	}
end

function GuardEscapeSignController._recompute(self)
	local ok, err = pcall(function()
		local scenario = self:_buildScenario()
		if not scenario then
			return
		end
		self._minimumEscapeWalkSpeed = GuardEscapePrediction.ResolvePlayerWalkSpeedRequirement(scenario, 1.0)
		self._requiredSpeedSign:SetSpeedPowerRequirement(ResolveGuardSpeedRequirement(scenario))
	end)
	if not ok then
		warnOnce("recompute:" .. self._areaModel.Name, self._areaModel.Name .. ": " .. tostring(err))
	end
	self:_render()
end

function GuardEscapeSignController._render(self)
	if self._minimumEscapeWalkSpeed == nil then
		return
	end
	local tolerance = GuardEscapePrediction.ResolveSlowdownTolerance(self._minimumEscapeWalkSpeed, self._playerWalkSpeed)
	self._requiredSpeedSign:SetSlowdownTolerance(tolerance)
end

function GuardEscapeSignController.Destroy(self)
	self._destroyed = true
	self._trove:Destroy()
end

return GuardEscapeSignController
