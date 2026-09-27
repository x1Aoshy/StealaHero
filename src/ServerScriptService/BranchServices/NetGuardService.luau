-- ServerScriptService.BranchServices.NetGuardService (Branch service; injected by scripts/inject/branch.luau, started
-- by ServerScriptService.BranchServer)
-- Owner 2026-09-27: "improve the network replication, make the game bullet-proof". Every handler already validates its
-- own arguments; this is the flood guard in front of all of them. It listens to every RemoteEvent / UnreliableRemoteEvent
-- under ReplicatedStorage (the game's Network folder, ByteNet's, the packages') and counts each player's traffic:
--   * sustained floods: more than PER_REMOTE_LIMIT events/s on one remote for FLOOD_SECONDS in a row, or more than
--     TOTAL_LIMIT events/s over all remotes in one second (generous: ByteNet batches once per frame, so a 240 fps client
--     fires 240/s on its remote);
--   * oversized payloads: a string longer than MAX_STRING or a table with more than MAX_TABLE entries (shallow count) in
--     any argument.
-- Offenders are kicked (a flood like that only comes from an exploit and it is what drags a server's heartbeat down).
-- Counting is O(1) per event, one table per player, cleared when they leave.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetGuardService = {}

NetGuardService.PER_REMOTE_LIMIT = 400
NetGuardService.TOTAL_LIMIT = 900
NetGuardService.FLOOD_SECONDS = 3
NetGuardService.MAX_STRING = 100000
NetGuardService.MAX_TABLE = 5000

local traffic = {} -- [Player] = { second = integer, total = n, perRemote = { [remote] = n }, strikes = { [remote] = n } }
local kicked = setmetatable({}, { __mode = "k" })

local function kick(player, reason)
	if kicked[player] then
		return
	end
	kicked[player] = true
	warn(string.format("[NetGuardService] kicking %s (%d): %s", player.Name, player.UserId, reason))
	pcall(player.Kick, player, "Disconnected: too many network requests.")
end

local function oversized(value)
	local kind = type(value)
	if kind == "string" then
		return #value > NetGuardService.MAX_STRING
	elseif kind == "table" then
		local count = 0
		for _ in pairs(value) do
			count += 1
			if count > NetGuardService.MAX_TABLE then
				return true
			end
		end
	end
	return false
end

local function onEvent(remote, player, ...)
	if typeof(player) ~= "Instance" or kicked[player] then
		return
	end
	local now = math.floor(os.clock())
	local t = traffic[player]
	if t == nil then
		t = { second = now, total = 0, perRemote = {}, strikes = {} }
		traffic[player] = t
	end
	if t.second ~= now then
		-- close the previous second: a remote over its limit earns a strike; strikes only count seconds IN A ROW, so a
		-- gap (a silent second, or a remote quiet or under its limit that second) clears them
		if now > t.second + 1 then
			table.clear(t.strikes)
		end
		for r in pairs(t.strikes) do
			if (t.perRemote[r] or 0) <= NetGuardService.PER_REMOTE_LIMIT then
				t.strikes[r] = nil
			end
		end
		for r, n in pairs(t.perRemote) do
			if n > NetGuardService.PER_REMOTE_LIMIT then
				t.strikes[r] = (t.strikes[r] or 0) + 1
				if t.strikes[r] >= NetGuardService.FLOOD_SECONDS then
					kick(player, string.format("%d events/s on %s for %d s", n, r:GetFullName(), t.strikes[r]))
					return
				end
			end
		end
		table.clear(t.perRemote)
		t.total = 0
		t.second = now
	end
	t.total += 1
	t.perRemote[remote] = (t.perRemote[remote] or 0) + 1
	if t.total > NetGuardService.TOTAL_LIMIT then
		kick(player, string.format("%d events in one second", t.total))
		return
	end
	for i = 1, select("#", ...) do
		if oversized((select(i, ...))) then
			kick(player, "oversized payload on " .. remote:GetFullName())
			return
		end
	end
end

local watched = setmetatable({}, { __mode = "k" })
local function guard(inst)
	if watched[inst] then
		return
	end
	if inst:IsA("RemoteEvent") or inst:IsA("UnreliableRemoteEvent") then
		watched[inst] = true
		inst.OnServerEvent:Connect(function(player, ...)
			onEvent(inst, player, ...)
		end)
	end
end

function NetGuardService:Start()
	for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
		guard(d)
	end
	ReplicatedStorage.DescendantAdded:Connect(guard)
end

function NetGuardService:PlayerRemoving(player)
	traffic[player] = nil
end

-- Test hook: the counters of one player (nil when they sent nothing).
function NetGuardService.GetTraffic(player)
	return traffic[player]
end
NetGuardService._onEvent = onEvent

return NetGuardService
