-- ServerScriptService.BranchServices.LagCompensationService (Branch service; injected by scripts/inject/branch.luau)
-- Owner 2026-09-27: "the NPC hitbox must be super accurate, also between players when they hit each other, even when
-- the servers lag". A player sees the world late: a server-simulated rig (a villain) reaches their screen about one
-- round trip plus the engine's interpolation buffer after it was there, and every other player's character is late by
-- their upload plus that player's round trip. Judging a hit with the rigs' CURRENT server positions therefore hits
-- players who were visibly out of reach and misses players who were visibly hit.
-- This keeps a short position history of every character root and of every registered NPC root (a ring buffer per
-- root, sampled on Branch's shared Heartbeat) and answers "where did `viewer` see `root`": the position `root` had
-- ViewDelay(viewer) seconds ago (their round trip + INTERP_DELAY, capped at MAX_REWIND so a huge ping cannot buy
-- reach). Hit checks (GuardChaseService catches, gear / melee hits) compare the attacker's or victim's own position
-- with the other side rewound to that moment.
--
-- API (require the module; Branch starts the sampling):
--   LagCompensationService.Track(root: BasePart)            NPC roots (character roots are tracked automatically)
--   LagCompensationService.ViewDelay(viewer: Player?) -> seconds
--   LagCompensationService.PositionAt(root, t) -> Vector3   position at os.clock() time t (interpolated; the current
--                                                          position when there is no history)
--   LagCompensationService.SeenBy(root, viewer) -> Vector3  PositionAt(root, now - ViewDelay(viewer))
-- Cost: one Vector3 per tracked root per frame in preallocated rings (no allocation once warm), histories dropped when a
-- root leaves the DataModel.

local Players = game:GetService("Players")

local LagCompensationService = {}

LagCompensationService.HISTORY_SECONDS = 1
LagCompensationService.CAPACITY = 90 -- samples per root (60 Hz covers the history with room for frame spikes)
LagCompensationService.INTERP_DELAY = 0.08 -- the engine's replication interpolation buffer, roughly
LagCompensationService.MAX_REWIND = 0.4 -- never rewind further than this, whatever the ping

local rings = {} -- [BasePart] = { times = {}, positions = {}, head = n, count = n }
local tracked = {} -- [BasePart] = true (explicitly tracked NPC roots)

local function ringFor(root)
	local ring = rings[root]
	if ring == nil then
		ring = { times = table.create(LagCompensationService.CAPACITY, 0), positions = table.create(LagCompensationService.CAPACITY, Vector3.zero),
			head = 0, count = 0 }
		rings[root] = ring
	end
	return ring
end

local function record(root, now)
	local ring = ringFor(root)
	local head = ring.head % LagCompensationService.CAPACITY + 1
	ring.head = head
	ring.times[head] = now
	ring.positions[head] = root.Position
	if ring.count < LagCompensationService.CAPACITY then
		ring.count += 1
	end
end

function LagCompensationService.Track(root)
	if typeof(root) == "Instance" and root:IsA("BasePart") then
		tracked[root] = true
	end
end

function LagCompensationService.ViewDelay(viewer)
	local ping = 0
	if typeof(viewer) == "Instance" and viewer:IsA("Player") then
		local ok, value = pcall(viewer.GetNetworkPing, viewer)
		if ok and type(value) == "number" and value == value and value >= 0 then
			ping = value
		end
	end
	return math.clamp(ping + LagCompensationService.INTERP_DELAY, 0, LagCompensationService.MAX_REWIND)
end

function LagCompensationService.PositionAt(root, t)
	local ring = rings[root]
	if ring == nil or ring.count == 0 then
		return root.Position
	end
	local capacity = LagCompensationService.CAPACITY
	local index = ring.head
	local newerTime, newerPosition = nil, nil
	for _ = 1, ring.count do
		local time, position = ring.times[index], ring.positions[index]
		if time <= t then
			if newerTime == nil then
				return position -- t is at or after the newest sample
			end
			local span = newerTime - time
			local alpha = if span > 1e-6 then (t - time) / span else 0
			return position:Lerp(newerPosition, alpha)
		end
		newerTime, newerPosition = time, position
		index = if index == 1 then capacity else index - 1
	end
	return newerPosition or root.Position -- t is older than the whole history: the oldest sample
end

function LagCompensationService.SeenBy(root, viewer)
	return LagCompensationService.PositionAt(root, os.clock() - LagCompensationService.ViewDelay(viewer))
end

function LagCompensationService:Heartbeat()
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			record(root, now)
		end
	end
	for root in pairs(tracked) do
		if root.Parent then
			record(root, now)
		else
			tracked[root] = nil
			rings[root] = nil
		end
	end
	-- drop the histories of character roots that are gone (respawns)
	for root in pairs(rings) do
		if root.Parent == nil then
			rings[root] = nil
			tracked[root] = nil
		end
	end
end

-- Test hooks
LagCompensationService._record = record
function LagCompensationService._reset()
	table.clear(rings)
	table.clear(tracked)
end

return LagCompensationService
