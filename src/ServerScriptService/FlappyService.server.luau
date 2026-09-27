-- ServerScriptService.FlappyService (server Script, injected by scripts/inject/phone.luau)
-- Hero Flap leaderboard: the server side of the SpeedPhone minigame (StarterPlayerScripts.GUI.SpeedPhone).
--
--   * Each player's all-time best lives in the profile (Library.Database, field FlappyBest; written on the live
--     profile table, so it is saved with the next profile save) and in the OrderedDataStore "FlappyBest_v1"
--     (key = UserId, value = best, only ever raised through UpdateAsync) that feeds the global TOP 10.
--   * Scores come from the client, so they are validated: the client announces a run ("Flappy: RunStarted") and
--     submits its score once when it ends ("Flappy: SubmitScore"). A score is rejected when it is not a whole number
--     in 0..MAX_SCORE, when no run was announced, or when it is higher than the game physics allow for the time the
--     run took (see MAX_POINTS_PER_SECOND). Submissions are rate-limited, one per announced run.
--   * "Flappy: GetTop" returns the TOP 10 (the global store's top merged with the live bests of the players in this
--     server, so a new best shows right away) plus the caller's best and rank. Without DataStore access (Studio
--     without API access, outages) it keeps working with the players in this server only (same pattern as
--     ServerScriptService.LeaderboardService).
-- The remotes are created here in ReplicatedStorage.Network when missing (NetworkInit does not list them).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LOG_PREFIX = "[FlappyService]"

local STORE_NAME = "FlappyBest_v1"
local PROFILE_FIELD = "FlappyBest"
local TOP_COUNT = 10
local REFRESH_INTERVAL = 60 -- global top read
local FLUSH_INTERVAL = 30 -- pending bests written to the store
local MAX_SCORE = 100000

-- Physics bound, from the SpeedPhone tuning: pipe pairs are PIPE_SPACING = 0.42 screen heights apart and scroll at
-- most SPEED_MAX = 0.47 screen heights / s, so a point takes at least 0.42 / 0.47 = 0.89 s (the first one longer).
-- A low frame rate or a pause only slows the game down. 1.25 points / s + GRACE_POINTS (network latency) is a
-- generous ceiling a real run never reaches.
local MAX_POINTS_PER_SECOND = 1.25
local GRACE_POINTS = 2
local MIN_SUBMIT_INTERVAL = 1 -- a run (fall + death animation + retry delay) always takes longer
local MIN_RUN_INTERVAL = 0.3 -- two run starts closer than this: the run is void (spam)
local MIN_TOP_INTERVAL = 0.25

local REMOTE_RUN_STARTED = "Flappy: RunStarted"
local REMOTE_SUBMIT = "Flappy: SubmitScore"
local REMOTE_GET_TOP = "Flappy: GetTop"

local function log(message: string)
	print(LOG_PREFIX .. " " .. message)
end

local Database = nil
do
	local ok, result = pcall(function()
		return require(ServerScriptService:WaitForChild("Library", 30):WaitForChild("Database", 30))
	end)
	if ok and type(result) == "table" then
		Database = result
	else
		warn(LOG_PREFIX .. " Library.Database unavailable, bests are kept for this server only: " .. tostring(result))
	end
end

----------------------------------------------------------------------------------------------------
-- Remotes
----------------------------------------------------------------------------------------------------

local network = ReplicatedStorage:FindFirstChild("Network")
if network == nil then
	network = Instance.new("Folder")
	network.Name = "Network"
	network.Parent = ReplicatedStorage
end

local function ensureRemote(className: string, name: string): Instance
	local existing = network:FindFirstChild(name)
	if existing ~= nil and existing:IsA(className) then
		return existing
	end
	if existing ~= nil then
		warn(string.format("%s Network.%s is a %s, expected a %s: replacing it", LOG_PREFIX, name, existing.ClassName, className))
		existing:Destroy()
	end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = network
	return remote
end

local runStartedRemote = ensureRemote("RemoteEvent", REMOTE_RUN_STARTED) :: RemoteEvent
local submitRemote = ensureRemote("RemoteFunction", REMOTE_SUBMIT) :: RemoteFunction
local getTopRemote = ensureRemote("RemoteFunction", REMOTE_GET_TOP) :: RemoteFunction

----------------------------------------------------------------------------------------------------
-- Values
----------------------------------------------------------------------------------------------------

local function sanitizeBest(value: any): number
	value = tonumber(value)
	if value == nil or value ~= value or value <= 0 then
		return 0
	end
	return math.clamp(math.floor(value), 0, MAX_SCORE)
end

type Session = {
	best: number,
	dirty: boolean, -- a best not written to the store yet
	runStartedAt: number?,
	lastRunAt: number,
	lastSubmitAt: number,
	lastTopAt: number,
	rejected: number,
}

local sessions: { [Player]: Session } = {}

local function sessionOf(player: Player): Session
	local session = sessions[player]
	if session == nil then
		local keep = player.Parent ~= nil -- a late call from a player who already left gets a throwaway session
		session = {
			best = 0,
			dirty = false,
			runStartedAt = nil,
			lastRunAt = -math.huge,
			lastSubmitAt = -math.huge,
			lastTopAt = -math.huge,
			rejected = 0,
		}
		if keep then
			sessions[player] = session
		end
		if Database then
			local okProfile, profile = pcall(Database.Get, player)
			if okProfile and type(profile) == "table" then
				session.best = sanitizeBest(profile[PROFILE_FIELD])
			end
		end
	end
	return session
end

local function writeProfileBest(player: Player, best: number)
	if Database == nil then
		return
	end
	pcall(function()
		local profile = Database.Get(player)
		if type(profile) == "table" and Database.IsPlayerLoaded(player) then
			profile[PROFILE_FIELD] = best -- the live profile: saved with the next profile save
		end
	end)
end

----------------------------------------------------------------------------------------------------
-- Global top (OrderedDataStore)
----------------------------------------------------------------------------------------------------

local store: OrderedDataStore? = nil
local storeOnline = true
local globalTop: { { userId: number, best: number } } = {}
local names: { [number]: string } = {}
local nameLookups: { [number]: boolean } = {}

local function goOffline(reason: any)
	if storeOnline then
		storeOnline = false
		log("OrderedDataStore unavailable (" .. tostring(reason) .. "): the TOP PLAYERS board shows this server's players only")
	end
end

-- Errors that will not go away by retrying (no API access in Studio, unpublished place): stop using the store.
local function isPermanent(err: any): boolean
	local text = string.lower(tostring(err))
	return string.find(text, "api", 1, true) ~= nil or string.find(text, "publish", 1, true) ~= nil
		or string.find(text, "403", 1, true) ~= nil or string.find(text, "forbidden", 1, true) ~= nil
end

local function getStore(): OrderedDataStore?
	if not storeOnline then
		return nil
	end
	if store == nil then
		local ok, result = pcall(function()
			return DataStoreService:GetOrderedDataStore(STORE_NAME)
		end)
		if not ok then
			goOffline(result)
			return nil
		end
		store = result
	end
	return store
end

local function flushPlayer(player: Player)
	local session = sessions[player]
	if session == nil or not session.dirty or session.best <= 0 then
		return
	end
	local target = getStore()
	if target == nil then
		return
	end
	local best = session.best
	local ok, err = pcall(function()
		target:UpdateAsync(tostring(player.UserId), function(old)
			local stored = sanitizeBest(old)
			if stored >= best then
				return nil -- already as high (another server): no write
			end
			return best
		end)
	end)
	if ok then
		if session.best == best then
			session.dirty = false
		end
	elseif isPermanent(err) then
		goOffline(err)
	else
		log("save for " .. player.Name .. " failed: " .. tostring(err))
	end
end

local function resolveName(userId: number)
	if names[userId] ~= nil or nameLookups[userId] then
		return
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		names[userId] = player.Name
		return
	end
	nameLookups[userId] = true -- one lookup in flight per user
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(name) == "string" then
		names[userId] = name
	else
		nameLookups[userId] = nil -- retried by a later refresh / request
	end
end

local function refreshGlobal()
	local target = getStore()
	if target == nil then
		return
	end
	local ok, result = pcall(function()
		return target:GetSortedAsync(false, TOP_COUNT):GetCurrentPage()
	end)
	if ok and type(result) == "table" then
		local top = {}
		for _, entry in ipairs(result) do
			local userId = tonumber(entry.key)
			local best = sanitizeBest(entry.value)
			if userId and best > 0 then
				table.insert(top, { userId = userId, best = best })
			end
		end
		globalTop = top
		for _, entry in ipairs(top) do
			resolveName(entry.userId)
		end
	elseif isPermanent(result) then
		goOffline(result)
	else
		log("top read failed: " .. tostring(result))
	end
end

local function nameOf(userId: number): string
	local player = Players:GetPlayerByUserId(userId)
	if player then
		return player.Name
	end
	if names[userId] then
		return names[userId]
	end
	if not nameLookups[userId] then
		task.spawn(resolveName, userId)
	end
	return "..."
end

-- The global top merged with the live bests of this server's players (newer than the last read).
local function mergedTop(): { { userId: number, best: number } }
	local byUser: { [number]: number } = {}
	for _, entry in ipairs(globalTop) do
		byUser[entry.userId] = entry.best
	end
	for player, session in pairs(sessions) do
		if player.Parent ~= nil and session.best > (byUser[player.UserId] or 0) then
			byUser[player.UserId] = session.best
		end
	end
	local list = {}
	for userId, best in pairs(byUser) do
		if best > 0 then
			table.insert(list, { userId = userId, best = best })
		end
	end
	table.sort(list, function(a, b)
		if a.best ~= b.best then
			return a.best > b.best
		end
		return a.userId < b.userId
	end)
	while #list > TOP_COUNT do
		table.remove(list)
	end
	return list
end

-- The caller's rank in the TOP 10 (nil outside it) and the score to beat to enter it (nil while it has free rows).
local function standing(player: Player, top: { { userId: number, best: number } }): (number?, number?)
	local rank = nil
	for index, entry in ipairs(top) do
		if entry.userId == player.UserId then
			rank = index
			break
		end
	end
	local tenth = if #top >= TOP_COUNT then top[TOP_COUNT].best else nil
	return rank, tenth
end

----------------------------------------------------------------------------------------------------
-- Remote handlers (client input is untrusted: validated and rate-limited)
----------------------------------------------------------------------------------------------------

runStartedRemote.OnServerEvent:Connect(function(player: Player)
	local session = sessionOf(player)
	local now = os.clock()
	if now - session.lastRunAt < MIN_RUN_INTERVAL then
		session.runStartedAt = nil -- spam: this run cannot be submitted
	else
		session.runStartedAt = now
	end
	session.lastRunAt = now
end)

local function reply(player: Player, session: Session, accepted: boolean, reason: string?, newBest: boolean)
	local top = mergedTop()
	local rank, tenth = standing(player, top)
	return {
		ok = accepted,
		reason = reason,
		best = session.best,
		newBest = newBest,
		rank = rank,
		tenth = tenth,
		online = storeOnline,
	}
end

submitRemote.OnServerInvoke = function(player: Player, rawScore: any)
	local session = sessionOf(player)
	local now = os.clock()
	if now - session.lastSubmitAt < MIN_SUBMIT_INTERVAL then
		return reply(player, session, false, "rate", false)
	end
	session.lastSubmitAt = now
	local startedAt = session.runStartedAt
	session.runStartedAt = nil -- one submission per announced run

	if type(rawScore) ~= "number" or rawScore ~= rawScore or rawScore < 0 or rawScore > MAX_SCORE or rawScore % 1 ~= 0 then
		return reply(player, session, false, "invalid", false)
	end
	if startedAt == nil then
		return reply(player, session, false, "norun", false)
	end
	local elapsed = now - startedAt
	local ceiling = math.floor(elapsed * MAX_POINTS_PER_SECOND) + GRACE_POINTS
	if rawScore > ceiling then
		session.rejected += 1
		if session.rejected <= 3 then
			log(string.format("rejected %s's score %d after %.1f s (ceiling %d)", player.Name, rawScore, elapsed, ceiling))
		end
		return reply(player, session, false, "impossible", false)
	end

	local newBest = rawScore > session.best
	if newBest then
		session.best = rawScore
		session.dirty = true
		writeProfileBest(player, rawScore)
	end
	return reply(player, session, true, nil, newBest)
end

getTopRemote.OnServerInvoke = function(player: Player)
	local session = sessionOf(player)
	local now = os.clock()
	if now - session.lastTopAt < MIN_TOP_INTERVAL then
		return nil
	end
	session.lastTopAt = now
	local top = mergedTop()
	local entries = {}
	for index, entry in ipairs(top) do
		table.insert(entries, { rank = index, userId = entry.userId, name = nameOf(entry.userId), best = entry.best })
	end
	local rank, tenth = standing(player, top)
	return {
		online = storeOnline,
		entries = entries,
		you = { best = session.best, rank = rank },
		tenth = tenth,
	}
end

----------------------------------------------------------------------------------------------------
-- Lifecycle
----------------------------------------------------------------------------------------------------

if Database and type(Database.OnLoaded) == "function" then
	Database.OnLoaded(function(player: Player, profile)
		local session = sessionOf(player)
		local saved = sanitizeBest(type(profile) == "table" and profile[PROFILE_FIELD] or 0)
		if saved > session.best then
			session.best = saved
		elseif session.best > saved then
			writeProfileBest(player, session.best) -- a best set before the profile finished loading
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	sessionOf(player)
	names[player.UserId] = player.Name
end)
for _, player in ipairs(Players:GetPlayers()) do
	sessionOf(player)
end

Players.PlayerRemoving:Connect(function(player)
	pcall(flushPlayer, player)
	sessions[player] = nil
end)

game:BindToClose(function()
	for player in pairs(sessions) do
		pcall(flushPlayer, player)
	end
end)

task.spawn(function()
	local sinceRefresh = REFRESH_INTERVAL
	while true do
		for player in pairs(sessions) do
			if player.Parent ~= nil then
				pcall(flushPlayer, player)
			end
		end
		sinceRefresh += FLUSH_INTERVAL
		if sinceRefresh >= REFRESH_INTERVAL then
			sinceRefresh = 0
			pcall(refreshGlobal)
		end
		task.wait(FLUSH_INTERVAL)
	end
end)

log(string.format("ready (store %s, TOP %d)", STORE_NAME, TOP_COUNT))
