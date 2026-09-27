-- ServerScriptService.Controllers.TreadmillGrindService
-- "Caminar en tu cinta te sube la velocidad poco a poco" -- standing on your own plot's
-- treadmill grants SpeedPower over time, using the game's real formula
-- (ReplicatedStorage.Library.Util.TreadmillUtil.ResolveSpeedPowerPerSecond, confirmed safe to
-- require and tested directly: ~8 SpeedPower/sec at the starter treadmill from a fresh profile).
--
-- Detection is a simple server-side proximity check against Plots.<N>.TreadmillBottom (the
-- physical belt part, confirmed to exist on every plot) -- not a perfect region match to
-- whatever zone the original client used, but a safe, honest approximation: stand within the
-- belt's footprint and you grind, same as the real game's core loop.
--
-- FEATURE (user request: "al rozar la treadmill se te pone ahi y mira hacia los videos" --
-- stepping on your treadmill is supposed to trigger a whole "active session": camera looks at
-- a video wall, TreadmillUI shows a speed-gain projection, etc). Root cause found reading the
-- client: SEVEN different controllers (TreadmillUI, TreadmillCharacterPresentationController,
-- TreadmillVideoController, MusicController, ActiveAssetsController, TreadmillStaticController,
-- TreadmillShiftLockController, SlowToggle, GameResetTimer, EggPlacementController) all listen
-- for "Treadmills: ActiveTreadmillChanged" and are FULLY built to react to it -- but nothing on
-- the server ever fired it (confirmed: zero matches anywhere in ServerScriptService), so none of
-- that ever activated -- same "client built, server never wired" pattern as everywhere else in
-- this project. Now fires it using the same on-treadmill detection this service already has.
-- Contract confirmed by reading TreadmillUI's handler in full: fires (treadmillId: string,
-- speedMultiplier: number, nextAwardServerTime: number, mediaFeedState: table) to activate, or
-- just (nil) to deactivate. treadmillId must be a real Treadmills.Directory key (= config._id,
-- confirmed via Treadmills.lua's own t4[v._id]=i indexing).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local SpeedService = require(game.ServerScriptService.Controllers.SpeedService)
local PlotService = require(game.ServerScriptService.Controllers.PlotService)
local TreadmillUtil = require(ReplicatedStorage.Library.Util.TreadmillUtil)
local Treadmills = require(ReplicatedStorage.Directory.Treadmills)

-- BUG FIX (user report 2026-09-02: "cuando piso la treadmill me congela pero no me sube" --
-- player froze on the belt but got zero SpeedPower. Root cause in the Play log:
--   [TreadmillGrindService] ResolveSpeedPowerPerSecond failed for <name> (no gain this tick):
--   ReplicatedStorage.Library.Util.TreadmillUtil:245: invalid argument #1 to 'floor' (number
--   expected, got nil)
-- TreadmillUtil.ResolveSpeedBoostTierIndex(profile) does math.floor(profile.SpeedBoostTierIndex)
-- with no nil coercion; profiles saved before that field existed have it as nil, so every tick
-- errors out of the pcall below and the elseif type(gain) == "number" branch never runs -> no
-- gain awarded. Same pattern is likely for the other numeric stat fields the util walks. Fill
-- the missing defaults directly on the live profile (Database.Get returns the real table so the
-- backfill sticks, and this also self-heals the DB on the next autosave). Values match
-- ReplicatedStorage.Library.Modules.DefaultStats exactly.
-- The shared Database.EnsureStatDefaults (run at profile load) is the primary healer; the local
-- fallback below only replaces missing or wrongly typed values, so it never fights the shared
-- helper's clamping and still protects the util calls if the shared helper is absent or throws.
local NUMERIC_STAT_DEFAULTS = {
	Money = 0,
	SpeedPower = 10, -- TreadmillUtil.DEFAULT_BASE_SPEED_POWER
	Rebirth = 0,
	BaseUpgradeLevel = 0,
	TreadmillUpgradeLevel = 1,
	SpeedBoostTierIndex = 0,
	TemporarySpeedBoostRemainingSeconds = 0,
	TemporarySpeedBoostActiveStartedAt = 0,
}
local TABLE_STAT_FIELDS = { "TrailInventory", "Gamepasses" }
-- TreadmillUI/TreadmillVideoController read these from the ActiveTreadmillChanged payload
-- (FeedSequencer does table.clone(feedState.SeenPendingMediaKeys)), so a partial table throws client-side.
local MEDIA_FEED_DEFAULTS = {
	Seed = 0,
	CurrentIndex = 0,
	AlgorithmVersion = 3,
	ReleaseTrackingInitialized = false,
	FullFeedReleaseVersion = 0,
	CompletedReleaseVersion = 0,
	PendingReleaseVersion = 0,
}

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- PURCHASE GATE (owner report: "puedo usar sin comprar" -- the treadmill worked before buying it).
-- In the original game the plot has no treadmill until its owner buys the first base upgrade
-- (Plots: RequestBaseUpgrade, BaseUpgradeLevel 0 -> 1, "Unlock:" on the PlotUpgrade sign): only then
-- do TreadmillSpawnService and the client TreadmillStaticController render it (both skip
-- BaseUpgradeLevel <= 0), and the client only starts a session on a rendered treadmill. This
-- service detects runners geometrically on TreadmillBottom, which exists on every plot, so it
-- must apply the same condition itself: no session, SpeedPower or coins until it is bought.
local function isTreadmillUnlocked(profile)
	local level = tonumber(profile.BaseUpgradeLevel)
	return level ~= nil and level == level and level > 0
end

local function localEnsureStatDefaults(profile)
	for field, default in pairs(NUMERIC_STAT_DEFAULTS) do
		local value = profile[field]
		if not isFiniteNumber(value) then
			value = tonumber(value)
			profile[field] = if isFiniteNumber(value) then value else default
		end
	end
	for _, field in ipairs(TABLE_STAT_FIELDS) do
		if type(profile[field]) ~= "table" then
			profile[field] = {}
		end
	end
	if profile.EquippedTrail ~= nil and type(profile.EquippedTrail) ~= "string" then
		profile.EquippedTrail = nil
	end
	local feedState = profile.TreadmillMediaFeedState
	if type(feedState) ~= "table" then
		feedState = {}
		profile.TreadmillMediaFeedState = feedState
	end
	for field, default in pairs(MEDIA_FEED_DEFAULTS) do
		if type(feedState[field]) ~= type(default) then
			feedState[field] = default
		end
	end
	if type(feedState.SeenPendingMediaKeys) ~= "table" then
		feedState.SeenPendingMediaKeys = {}
	end
end

local warnedSharedDefaultsFailure = false
-- Database.EnsureStatDefaults also normalises unrelated state (e.g. prunes EquippedAssets), so it
-- runs once per live profile table rather than every tick; the cheap local guard runs every tick.
local sharedHealedProfiles = setmetatable({}, { __mode = "k" }) -- profile table -> true
local function ensureStatDefaults(profile)
	if type(profile) ~= "table" then
		return false
	end
	local sharedEnsure = Database.EnsureStatDefaults
	if type(sharedEnsure) == "function" and not sharedHealedProfiles[profile] then
		sharedHealedProfiles[profile] = true
		-- Heals in place; the live table stays the one Database.Get returned.
		local ok, err = pcall(sharedEnsure, profile)
		if not ok and not warnedSharedDefaultsFailure then
			warnedSharedDefaultsFailure = true
			warn("[TreadmillGrindService] Database.EnsureStatDefaults failed (using local fallback): " .. tostring(err))
		end
	end
	localEnsureStatDefaults(profile)
	return true
end

local Network = ReplicatedStorage:WaitForChild("Network")
local ActiveTreadmillEventRemote = Network:WaitForChild("Treadmills: ActiveTreadmillChanged")
local RequestUnequipRemote = Network:WaitForChild("Treadmills: RequestUnequip")
local RequestEquipStaticRemote = Network:WaitForChild("Treadmills: RequestEquipStatic")

local PlotsFolder = Workspace:WaitForChild("Plots")

local TreadmillGrindService = {}
local DEBUG = false -- true prints the throttled per-player detection diagnostics (diagLog below)
local wasOnTreadmill = {} -- Player -> boolean, to only fire on actual on/off transitions
local sessionCharacter = {} -- Player -> the character whose session is running (see isAlive below)
local TICK_INTERVAL = 0.2 -- seconds; see the two BUG FIX comments below the loop for why
local MAX_TICK_SECONDS = 1 -- clamp for the measured tick length after a server hitch
local jumpCooldownUntil = {} -- Player -> os.clock() timestamp; see BUG FIX below RequestUnequipRemote
local JUMP_COOLDOWN_SECONDS = 3

-- Coins while running: TREADMILL_COINS_PER_SECOND x the treadmill's SpeedMultiplier (starter
-- Treadmill x6 -> 60 coins/s; this is the rate the old per-tick formula already paid). The
-- fractional remainder carries over between ticks so low rates are not rounded away.
-- ECON 2026-09-24: 10 -> 0.08 with the whole money economy /125 (AssetGenerationUtil.MONEY_SCALE): the starter
-- Treadmill (x2) now trickles $0.16/s, the Angelic (x2560) $204.8/s.
local TREADMILL_COINS_PER_SECOND = 0.08
local coinCarry = {} -- Player -> fractional coins not yet added to profile.Money

-- Gains are applied to the live profile table every tick (so saves and other services always see
-- them), but Database.Set -- which fires "New Stats" to the client and every OnFieldChanged
-- callback -- runs at most every STAT_FLUSH_INTERVAL per runner, plus immediately when a session
-- ends. TreadmillUI animates the gain client-side in between.
local STAT_FLUSH_INTERVAL = 0.5
local pendingStatFlush = {} -- Player -> true when SpeedPower/Money changed since the last Database.Set
local lastStatFlushAt = {} -- Player -> os.clock() of the last Database.Set
local lastGainWarnAt = {} -- Player -> os.clock(); throttles the ResolveSpeedPowerPerSecond warning
local GAIN_WARN_INTERVAL = 10

local maxTreadmillLevel = 1
do
	local ok, ordered = pcall(Treadmills.GetOrdered)
	if ok and type(ordered) == "table" and #ordered > 0 then
		maxTreadmillLevel = #ordered
	end
end

-- Treadmills.GetByUpgradeLevel returns nil for fractional/out-of-range levels; clamp so a bad
-- TreadmillUpgradeLevel still maps to a real treadmill instead of silently disabling the session.
local function resolveTreadmillConfig(profile)
	local level = math.clamp(math.floor(tonumber(profile.TreadmillUpgradeLevel) or 1), 1, maxTreadmillLevel)
	local ok, config = pcall(Treadmills.GetByUpgradeLevel, level)
	if ok and type(config) == "table" then
		return config
	end
	return nil
end

local function resolveMultiplier(config)
	local multiplier = config and tonumber(config.SpeedMultiplier)
	if isFiniteNumber(multiplier) and multiplier > 0 then
		return multiplier
	end
	return 1
end

local function flushStats(player, profile)
	pendingStatFlush[player] = nil
	lastStatFlushAt[player] = os.clock()
	Database.Set(player, { SpeedPower = profile.SpeedPower, Money = profile.Money })
	SpeedService.Refresh(player)
end

-- BUG FIX (real Play log from the user, 2026-08-24: "me salgo y sigue dandome dinero" / "solo
-- saltando deja de ganar velocidad" -- once onTreadmill went true it was NEVER re-checked
-- against position again (see the removed "Once active, only the jump-triggered RequestUnequip
-- handler... turns it off" branch below), so walking off the belt without jumping left the
-- session running forever and kept granting SpeedPower. Confirmed directly in the user's own
-- log: rel drifted from (-0.5,3.0,-6.6) to (-10.5,2.9,17.4) -- way outside the declared
-- tolerance -- while onTreadmill kept printing true).
-- offTreadmillSince tracks, per player, the moment geometry FIRST left tolerance while a
-- session was active. Position is re-checked every tick again (so leaving the belt actually
-- ends the session reliably), but the session only actually turns off once the player has been
-- continuously off-geometry for EXIT_GRACE_SECONDS -- this is what the ORIGINAL report ("me
-- muevo sin querer y ya se va") really needed: a debounce against one bad tick of physics
-- jitter/settling, not a permanent disable of the exit check.
local offTreadmillSince = {} -- Player -> os.clock() timestamp
local EXIT_GRACE_SECONDS = 1

Players.PlayerRemoving:Connect(function(player)
	wasOnTreadmill[player] = nil
	sessionCharacter[player] = nil
	jumpCooldownUntil[player] = nil
	offTreadmillSince[player] = nil
	-- Gains already live in the profile table Database saves on leave; only drop the bookkeeping.
	coinCarry[player] = nil
	pendingStatFlush[player] = nil
	lastStatFlushAt[player] = nil
	lastGainWarnAt[player] = nil
end)

-- BUG FIX (user report: "la treadmill como se me pone corriendo y para salir de la treadmill
-- tengo que saltar" -- jumping calls this remote (see TreadmillUI's UserInputService.
-- JumpRequest handler), but it was FAIL-stubbed, so the exit never actually worked). Mirrors
-- the "off" branch the poll loop below already fires, just triggered immediately instead of
-- waiting up to 1s for the next tick.
-- BUG FIX (user's own log: "TreadmillStaticController: [Warning] Static treadmill entry
-- rejected: Not available" -- fires whenever a player stands near their OWN idle/static
-- treadmill, right before it registers the model in RuntimeInstanceRegistry; no arguments are
-- sent, this is just a "yes, you're allowed to be here" ack tied to a purely client-side
-- raycast against the player's own rendered model). The client only asks once its own treadmill
-- is rendered, i.e. after the purchase; anyone else is told it is locked (see PURCHASE GATE).
RequestEquipStaticRemote.OnServerInvoke = function(player)
	local profile = Database.Get(player)
	if type(profile) ~= "table" or not isTreadmillUnlocked(profile) then
		return false, "Treadmill locked"
	end
	if player:GetAttribute("CarryingEgg") == true then
		return false, "Carrying an egg" -- carrier rules: no training while carrying (see notifyCarrier)
	end
	return true
end

-- BUG FIX (user report, confirmed in a real Play log: jumps straight up with WalkSpeed=0 so
-- there's no horizontal air control -- you land right back on the same spot on the belt,
-- re-triggering onTreadmill on the very next tick and re-activating the session immediately).
-- Suppress re-detection for a few seconds after a jump-exit so there's time to actually walk
-- away before the poll below is allowed to turn it back on.
RequestUnequipRemote.OnServerInvoke = function(player)
	jumpCooldownUntil[player] = os.clock() + JUMP_COOLDOWN_SECONDS
	offTreadmillSince[player] = nil

	local profile = Database.Get(player)
	if pendingStatFlush[player] and type(profile) == "table" then
		flushStats(player, profile)
	end

	if wasOnTreadmill[player] then
		wasOnTreadmill[player] = false
		sessionCharacter[player] = nil
		local ok, err = pcall(function()
			ActiveTreadmillEventRemote:FireClient(player, nil)
		end)
		if not ok then
			warn("[TreadmillGrindService] Failed firing ActiveTreadmillChanged (manual unequip) for " .. player.Name .. ": " .. tostring(err))
		end
	end
	return true
end

-- Carrier rules (owner 2026-09-24, Gekko TO DO 3): AreaEggService mirrors an active egg carry on the player as this
-- attribute; a carrier never starts (and immediately ends) a session and is told why, at most every few seconds,
-- through the game's bottom notification (NotificationCmds.Message, the same remote AreaEggService uses).
local CARRY_ATTRIBUTE = "CarryingEgg"
local CARRIER_NOTICE_INTERVAL = 3
local lastCarrierNoticeAt = {} -- Player -> os.clock()

local function notifyCarrier(player)
	local now = os.clock()
	if now - (lastCarrierNoticeAt[player] or -math.huge) < CARRIER_NOTICE_INTERVAL then
		return
	end
	lastCarrierNoticeAt[player] = now
	local remote = Network:FindFirstChild("Notifications_Show")
	if remote and remote:IsA("RemoteEvent") then
		pcall(remote.FireClient, remote, player, "Message", "Bottom", {
			Time = 2.5,
			Message = "Drop the egg to train!",
			Color = Color3.fromRGB(255, 96, 96),
		})
	end
end

Players.PlayerRemoving:Connect(function(player)
	lastCarrierNoticeAt[player] = nil
end)

local function isOnTreadmill(hrp, treadmillBottom)
	local relative = treadmillBottom.CFrame:PointToObjectSpace(hrp.Position)
	local size = treadmillBottom.Size
	return math.abs(relative.X) <= size.X / 2 + 1
		and math.abs(relative.Z) <= size.Z / 2 + 1
		and math.abs(relative.Y) <= size.Y / 2 + 10 -- generous vertical allowance (standing on top)
end

-- DIAGNOSTIC (user report: "al tocar la treadmill no se me sube" -- could not reproduce live,
-- the MCP plugin loses its server-target connection during a running playtest, so this couldn't
-- be root-caused directly this session). TreadmillBottom.Size.Y is ~0.001 (a thin flat trigger
-- plate, same "collapsed part" pattern seen elsewhere in this rip), so the vertical tolerance
-- above is doing all the work -- widened it a bit as a safe first guess, but the real cause
-- might be horizontal (wrong plot part, or the visual belt not aligned with this detector) or
-- something else entirely. This prints the exact relative offsets (throttled to once per 5s per
-- player) so next time paste the Output and it'll show exactly why the check does/doesn't pass,
-- instead of guessing again blind. Only active with DEBUG = true (top of file).
local lastDiagAt = {}
local function diagLog(player, hrp, treadmillBottom, passed)
	if not DEBUG then
		return
	end
	local now = os.clock()
	if lastDiagAt[player] and now - lastDiagAt[player] < 5 then
		return
	end
	lastDiagAt[player] = now
	local relative = treadmillBottom.CFrame:PointToObjectSpace(hrp.Position)
	local size = treadmillBottom.Size
	print(("[TreadmillGrindService DIAG] %s onTreadmill=%s rel=(%.1f,%.1f,%.1f) size=(%.2f,%.2f,%.2f) tolerance=(X:%.1f Y:%.1f Z:%.1f)")
		:format(player.Name, tostring(passed), relative.X, relative.Y, relative.Z,
			size.X, size.Y, size.Z, size.X / 2 + 1, size.Y / 2 + 10, size.Z / 2 + 1))
end

Players.PlayerRemoving:Connect(function(player)
	lastDiagAt[player] = nil
end)

-- A session belongs to the character that started it (review finding 2026-09-22: a dead body left on the
-- belt kept the session -- and the SpeedPower/coin grant -- alive until the respawn, and a respawned runner
-- back on the belt within EXIT_GRACE_SECONDS was never sent a new ActiveTreadmillChanged(id), so the client
-- lock, released on death, never came back). Death, a reset, a respawn or a missing character end it on
-- the next tick with no exit grace, and a dead character never starts one, so a return to the belt always
-- starts a fresh session.
local function isAlive(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function fireSessionEnded(player, profile, reason)
	wasOnTreadmill[player] = false
	sessionCharacter[player] = nil
	-- Session ended: push the final SpeedPower/Money right away.
	if pendingStatFlush[player] and type(profile) == "table" then
		flushStats(player, profile)
	end
	local ok, err = pcall(function()
		ActiveTreadmillEventRemote:FireClient(player, nil)
	end)
	if not ok then
		warn("[TreadmillGrindService] Failed firing ActiveTreadmillChanged (" .. reason .. ") for " .. player.Name .. ": " .. tostring(err))
	end
end

-- One player's poll tick; run under pcall by the loop below so an unexpected error for one
-- player never kills the grind loop for everyone.
local function tickPlayer(player, dt)
	local profile = Database.Get(player)
	local plotId = PlotService.GetPlotId(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if type(profile) == "table" and plotId and hrp and ensureStatDefaults(profile) then
		local plot = PlotsFolder:FindFirstChild(tostring(plotId))
		local treadmillBottom = plot and plot:FindFirstChild("TreadmillBottom")
		if treadmillBottom and not treadmillBottom:IsA("BasePart") then
			treadmillBottom = nil
		end
		local alive = isAlive(character)
		local onTreadmill
		if not isTreadmillUnlocked(profile) then
			-- Not bought (or reset): no treadmill on the plot, so no session and no gains. An active
			-- session ends on this tick through the normal transition below.
			offTreadmillSince[player] = nil
			onTreadmill = false
		elseif player:GetAttribute(CARRY_ATTRIBUTE) == true then
			-- Carrier rules (owner 2026-09-24): no training while carrying a stolen egg. A running session
			-- ends on this tick; stepping on the belt only shows the notice.
			offTreadmillSince[player] = nil
			onTreadmill = false
			if alive and treadmillBottom ~= nil and isOnTreadmill(hrp, treadmillBottom) then
				notifyCarrier(player)
			end
		elseif wasOnTreadmill[player] and (character ~= sessionCharacter[player] or not alive) then
			-- Died, reset or respawned: the session ends now (see isAlive).
			offTreadmillSince[player] = nil
			onTreadmill = false
		elseif wasOnTreadmill[player] then
			-- See the offTreadmillSince BUG FIX comment near the top of this file:
			-- keep re-checking geometry (so walking away actually ends the session and
			-- stops the money/SpeedPower grant), but debounce the exit by
			-- EXIT_GRACE_SECONDS so one bad tick of physics jitter/settling on the
			-- belt's collider doesn't instantly kill a session the player never left.
			local stillOnGeometry = treadmillBottom ~= nil and isOnTreadmill(hrp, treadmillBottom)
			if stillOnGeometry then
				offTreadmillSince[player] = nil
				onTreadmill = true
			else
				local since = offTreadmillSince[player]
				if since == nil then
					since = os.clock()
					offTreadmillSince[player] = since
				end
				onTreadmill = (os.clock() - since) < EXIT_GRACE_SECONDS
				if not onTreadmill then
					offTreadmillSince[player] = nil
				end
			end
		elseif (jumpCooldownUntil[player] or 0) > os.clock() then
			onTreadmill = false
		else
			onTreadmill = alive and treadmillBottom ~= nil and isOnTreadmill(hrp, treadmillBottom)
		end
		if treadmillBottom then
			diagLog(player, hrp, treadmillBottom, onTreadmill)
		end

		local config = resolveTreadmillConfig(profile)
		local multiplier = resolveMultiplier(config)

		-- Only fire on an actual on/off transition, not every tick -- matches how
		-- TreadmillUI's handler treats it as a session start/end, not a per-tick update.
		if onTreadmill ~= wasOnTreadmill[player] then
			if onTreadmill then
				wasOnTreadmill[player] = true
				sessionCharacter[player] = character
			end
			if onTreadmill and config then
				local nextAwardAt = Workspace:GetServerTimeNow() + 1
				local mediaFeedState = profile.TreadmillMediaFeedState -- healed to a full table above
				local ok, err = pcall(function()
					ActiveTreadmillEventRemote:FireClient(player, config._id, multiplier, nextAwardAt, mediaFeedState)
				end)
				if not ok then
					warn("[TreadmillGrindService] Failed firing ActiveTreadmillChanged (on) for " .. player.Name .. ": " .. tostring(err))
				end
			elseif not onTreadmill then
				fireSessionEnded(player, profile, "off")
			end
		end

		if onTreadmill then
			local ok, gain = pcall(TreadmillUtil.ResolveSpeedPowerPerSecond, profile, multiplier)
			if not ok then
				local now = os.clock()
				if now - (lastGainWarnAt[player] or -math.huge) >= GAIN_WARN_INTERVAL then
					lastGainWarnAt[player] = now
					warn("[TreadmillGrindService] ResolveSpeedPowerPerSecond failed for " .. player.Name .. " (no SpeedPower gain): " .. tostring(gain))
				end
			elseif isFiniteNumber(gain) and gain > 0 then
				profile.SpeedPower += gain * dt
				pendingStatFlush[player] = true
			end

			-- Treadmill coins: TREADMILL_COINS_PER_SECOND x multiplier, fractional carry.
			local carry = (coinCarry[player] or 0) + TREADMILL_COINS_PER_SECOND * multiplier * dt
			local wholeCoins = math.floor(carry)
			coinCarry[player] = carry - wholeCoins
			if wholeCoins > 0 then
				profile.Money += wholeCoins
				pendingStatFlush[player] = true
			end
		end
	elseif wasOnTreadmill[player] then
		-- The session's character is gone (removed between respawns, or lost its HumanoidRootPart), or the
		-- profile / plot is: no treadmill to run on, so the session ends now.
		offTreadmillSince[player] = nil
		fireSessionEnded(player, profile, "character gone")
	end

	if pendingStatFlush[player] and os.clock() - (lastStatFlushAt[player] or -math.huge) >= STAT_FLUSH_INTERVAL then
		if type(profile) == "table" then
			flushStats(player, profile)
		else
			pendingStatFlush[player] = nil
		end
	end
end

local lastTickErrorAt = -math.huge
task.spawn(function()
	while true do
		-- BUG FIX (user report: "vas tan rapido que no cuenta" -- walking onto the treadmill
		-- fast enough could cross the belt within the old 1s sample window without ever being
		-- caught standing on it). Sampled more often for the INITIAL step-on detection. The gain
		-- below is scaled by the tick length to compensate (ResolveSpeedPowerPerSecond returns a
		-- PER-SECOND rate -- ticking 5x more often without scaling would have handed out 5x the
		-- real SpeedPower/sec, a real balance/exploit bug, not just a detection fix). The measured
		-- wait (clamped) is used so per-second rates stay exact when the server runs slow.
		local dt = math.clamp(task.wait(TICK_INTERVAL), 0, MAX_TICK_SECONDS)
		for _, player in ipairs(Players:GetPlayers()) do
			local ok, err = pcall(tickPlayer, player, dt)
			if not ok and os.clock() - lastTickErrorAt >= GAIN_WARN_INTERVAL then
				lastTickErrorAt = os.clock()
				warn("[TreadmillGrindService] Tick failed for " .. player.Name .. ": " .. tostring(err))
			end
		end
	end
end)

return TreadmillGrindService
