-- ServerScriptService.BranchServices.HeroBroadcastService (Branch service; injected by scripts/inject/admin_panel.luau,
-- started by ServerScriptService.BranchServer)
-- Owner 2026-09-27: "events like Taco Rain can be activated in every server of the game" and "global announcements
-- inside Server, with the stud UI style: nice, sober and simple". The transport half of the Hero admin panel's
-- cross-server tools; ServerScriptService.BranchServices.HeroAdminService is the only caller (its commands run after its
-- own HeroAdminAccess check, and Publish / Announce re-check that access here).
--   * cross-server: one MessagingService topic, TOPIC ("HeroAdmin_Global"). Every server subscribes at Start (pcall'd,
--     retried with a back-off; Studio without API access simply stays "offline"). Publish(kind, data, admin) wraps the
--     data in an envelope { V, Kind, Origin = this server's id, Nonce, By, ById, At } and publishes it; the caller has
--     already run the action on its own server, so a server ignores its own echo (Origin) and any nonce it has seen.
--     Every message received is validated before anything runs (ValidatePayload: known Kind / Action, types, Duration
--     clamped to [MIN_DURATION, MAX_DURATION], texts length-capped and cleaned, stale or oversized messages dropped) and
--     is rate limited (RECEIVE_PER_MINUTE); a valid one goes to the handler HeroAdminService registered for its Kind
--     (OnGlobal), except "Announce", handled here. When MessagingService errors, Publish returns false + a short reason
--     and the admin panel says the action ran on this server only.
--   * announcements: Announce(admin, text, scope) cleans the text (plain text, one line, 1..MAX_ANNOUNCE_CHARS
--     characters), filters it with TextService (FilterStringAsync from the admin, then GetNonChatStringForBroadcastAsync)
--     BEFORE anything is shown or published (a filter error refuses the send: nothing unfiltered ever goes out), and
--     fires Network[REMOTE_NAME] { Kind = "Server" | "Global", Text } to every client
--     (BranchControllers.AnnouncementController draws the banner). Scope "All" also publishes the filtered text; the
--     other servers show it as a GLOBAL announcement. Sends are rate limited per admin (ANNOUNCE_COOLDOWN) and global
--     publishes per admin (GLOBAL_COOLDOWN) and per server (GLOBAL_PER_MINUTE).
--   * the remote is server -> client only: anything a client fires at it is ignored. Its attribute CrossServer ("ready" /
--     "offline") tells the admin panel whether this server is subscribed.
-- Branch lifecycle: Init creates the remote, Start subscribes (no dot-style Start(arg): Branch calls :Start() at boot).

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")

local HeroBroadcastService = {}

HeroBroadcastService.TOPIC = "HeroAdmin_Global"
HeroBroadcastService.REMOTE_NAME = "Announcement: Show"
HeroBroadcastService.VERSION = 1
HeroBroadcastService.KINDS = { TacoRain = true, Announce = true }
HeroBroadcastService.ACTIONS = { TacoRain = { Start = true, Stop = true } }
HeroBroadcastService.MIN_DURATION = 15 -- = TacoRainService.MIN_DURATION / MAX_DURATION (tests/smoke_admin_panel checks)
HeroBroadcastService.MAX_DURATION = 300
HeroBroadcastService.MAX_ANNOUNCE_CHARS = 150
HeroBroadcastService.MAX_TEXT_BYTES = 600 -- 150 characters of 4-byte UTF-8 at most
HeroBroadcastService.MAX_ID_LENGTH = 64
HeroBroadcastService.MAX_NAME_LENGTH = 32
HeroBroadcastService.MAX_MESSAGE_BYTES = 900 -- MessagingService takes 1 kB per message
HeroBroadcastService.MAX_AGE = 300 -- s: an older message is dropped (os.time, UTC on every server)
HeroBroadcastService.ANNOUNCE_COOLDOWN = 3 -- s between two announcements of the same admin
HeroBroadcastService.GLOBAL_COOLDOWN = 4 -- s between two cross-server publishes of the same admin
HeroBroadcastService.GLOBAL_PER_MINUTE = 10 -- cross-server publishes per server per minute
HeroBroadcastService.RECEIVE_PER_MINUTE = 30 -- messages this server acts on per minute
HeroBroadcastService.SEEN_SECONDS = 600 -- nonces remembered this long
HeroBroadcastService.SUBSCRIBE_RETRIES = { 15, 30, 60, 120 } -- s between subscribe attempts

local remote = nil
local subscribed = false
local lastError = nil
local handlers = {} -- [Kind] = function(cleanData)
local seen = {} -- [nonce] = os.clock()
local lastSendAt = {} -- [key] = os.clock()
local publishTimes = {} -- os.clock() of this server's recent publishes
local receiveTimes = {} -- os.clock() of the recent messages acted on
local announceSerial = 0
local lastDropWarn = -math.huge

local function newId()
	local ok, id = pcall(HttpService.GenerateGUID, HttpService, false)
	if ok and type(id) == "string" and id ~= "" then
		return id
	end
	return string.format("%x-%x", math.random(0, 0x7fffffff), math.floor(os.clock() * 1e6) % 0x7fffffff)
end

HeroBroadcastService.SERVER_ID = newId()

local accessModule = nil
local function isAdmin(player)
	if accessModule == nil then
		local module = ServerScriptService:FindFirstChild("HeroAdminAccess")
		local ok, result = false, nil
		if module and module:IsA("ModuleScript") then
			ok, result = pcall(require, module)
		end
		accessModule = if ok and type(result) == "table" then result else false
	end
	if not accessModule then
		return false
	end
	local ok, allowed = pcall(accessModule.IsAdmin, player)
	return ok and allowed == true
end

-- seconds before `key` may be used again (0 = now); `stamp` records a use
local function cooldownLeft(key, interval)
	local last = lastSendAt[key]
	if last == nil then
		return 0
	end
	return math.max(0, interval - (os.clock() - last))
end

local function stamp(key)
	lastSendAt[key] = os.clock()
end

-- keeps the timestamps of the last 60 s; true while under `limit` (`add` stamps one more)
local function perMinute(list, limit, add)
	local now = os.clock()
	for i = #list, 1, -1 do
		if now - list[i] > 60 then
			table.remove(list, i)
		end
	end
	if #list >= limit then
		return false
	end
	if add ~= false then
		table.insert(list, now)
	end
	return true
end

local function shortError(err)
	local text = tostring(err or "unknown error")
	text = string.gsub(text, "%s+", " ")
	if #text > 90 then
		text = string.sub(text, 1, 87) .. "..."
	end
	return text
end

local function setStatus(ok, err)
	subscribed = ok
	lastError = if ok then nil else shortError(err)
	if remote then
		remote:SetAttribute("CrossServer", if ok then "ready" else "offline")
	end
end

----------------------------------------------------------------------------------------------------
-- text
----------------------------------------------------------------------------------------------------

-- Plain one-line text: valid UTF-8, control characters and line breaks turned into spaces, runs of spaces collapsed,
-- trimmed, 1..maxChars characters. -> text | nil, reason
function HeroBroadcastService.CleanText(text, maxChars)
	maxChars = maxChars or HeroBroadcastService.MAX_ANNOUNCE_CHARS
	if type(text) ~= "string" then
		return nil, "Type a message first"
	end
	if #text > HeroBroadcastService.MAX_TEXT_BYTES then
		return nil, string.format("Too long: %d characters at most", maxChars)
	end
	if utf8.len(text) == nil then
		return nil, "The message is not valid text"
	end
	local clean = string.gsub(text, "[%z\1-\31\127]", " ")
	clean = string.gsub(clean, "%s+", " ")
	clean = string.match(clean, "^%s*(.-)%s*$") or ""
	local length = utf8.len(clean) or 0
	if length == 0 then
		return nil, "Type a message first"
	end
	if length > maxChars then
		return nil, string.format("Too long: %d characters at most (this one has %d)", maxChars, length)
	end
	return clean
end

-- TextService filter for text every player will read: FilterStringAsync from the sender, then
-- GetNonChatStringForBroadcastAsync. -> filtered | nil, reason (never the unfiltered text)
function HeroBroadcastService.FilterText(fromPlayer, text)
	local okFilter, result = pcall(TextService.FilterStringAsync, TextService, text, fromPlayer.UserId, Enum.TextFilterContext.PublicChat)
	if not okFilter or result == nil then
		warn("[HeroBroadcast] text filter failed: " .. shortError(result))
		return nil, "The Roblox text filter is unavailable right now: try again in a moment"
	end
	local okText, filtered = pcall(function()
		return result:GetNonChatStringForBroadcastAsync()
	end)
	if not okText or type(filtered) ~= "string" then
		warn("[HeroBroadcast] text filter failed: " .. shortError(filtered))
		return nil, "The Roblox text filter is unavailable right now: try again in a moment"
	end
	return filtered
end

----------------------------------------------------------------------------------------------------
-- payloads
----------------------------------------------------------------------------------------------------

local function shortString(value, maxLength)
	return type(value) == "string" and #value > 0 and #value <= maxLength
end

local function finite(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- A message's Data -> a clean copy with only the known fields, or nil, reason. Durations are clamped, texts cleaned.
function HeroBroadcastService.ValidatePayload(data)
	if type(data) ~= "table" then
		return nil, "not a table"
	end
	if data.V ~= HeroBroadcastService.VERSION then
		return nil, "unknown version"
	end
	local kind = data.Kind
	if type(kind) ~= "string" or HeroBroadcastService.KINDS[kind] ~= true then
		return nil, "unknown kind"
	end
	if not shortString(data.Origin, HeroBroadcastService.MAX_ID_LENGTH) or not shortString(data.Nonce, HeroBroadcastService.MAX_ID_LENGTH) then
		return nil, "bad origin / nonce"
	end
	if data.By ~= nil and not shortString(data.By, HeroBroadcastService.MAX_NAME_LENGTH) then
		return nil, "bad sender name"
	end
	if data.ById ~= nil and not (finite(data.ById) and data.ById % 1 == 0) then
		return nil, "bad sender id"
	end
	if not finite(data.At) then
		return nil, "bad time"
	end
	if math.abs(os.time() - data.At) > HeroBroadcastService.MAX_AGE then
		return nil, "stale"
	end
	local clean = { V = data.V, Kind = kind, Origin = data.Origin, Nonce = data.Nonce, By = data.By, ById = data.ById, At = data.At }
	if kind == "TacoRain" then
		local action = data.Action
		if type(action) ~= "string" or HeroBroadcastService.ACTIONS.TacoRain[action] ~= true then
			return nil, "unknown action"
		end
		clean.Action = action
		if action == "Start" then
			if not finite(data.Duration) then
				return nil, "bad duration"
			end
			clean.Duration = math.clamp(math.floor(data.Duration), HeroBroadcastService.MIN_DURATION, HeroBroadcastService.MAX_DURATION)
		end
	elseif kind == "Announce" then
		local text, reason = HeroBroadcastService.CleanText(data.Text)
		if text == nil then
			return nil, "bad text (" .. tostring(reason) .. ")"
		end
		clean.Text = text
	end
	return clean
end

----------------------------------------------------------------------------------------------------
-- announcements
----------------------------------------------------------------------------------------------------

local function showAnnouncement(kind, text)
	if remote == nil then
		return false
	end
	announceSerial += 1
	remote:FireAllClients({ Kind = kind, Text = text, Id = announceSerial })
	return true
end

----------------------------------------------------------------------------------------------------
-- cross-server
----------------------------------------------------------------------------------------------------

function HeroBroadcastService.OnGlobal(kind, handler)
	assert(HeroBroadcastService.KINDS[kind] == true and kind ~= "Announce", "HeroBroadcastService.OnGlobal: unknown kind " .. tostring(kind))
	handlers[kind] = handler
end

function HeroBroadcastService.IsReady()
	return subscribed
end

function HeroBroadcastService.Status()
	return { Subscribed = subscribed, LastError = lastError, ServerId = HeroBroadcastService.SERVER_ID }
end

-- Whether `fromPlayer` may publish now (the admin's GLOBAL_COOLDOWN and this server's GLOBAL_PER_MINUTE). Checked
-- BEFORE an all-server action runs anywhere, so a refused one does nothing at all. -> ok, reason
function HeroBroadcastService.CanPublish(fromPlayer)
	if typeof(fromPlayer) ~= "Instance" or not isAdmin(fromPlayer) then
		return false, "Not allowed"
	end
	local wait = cooldownLeft("global:" .. tostring(fromPlayer.UserId), HeroBroadcastService.GLOBAL_COOLDOWN)
	if wait > 0 then
		return false, string.format("Wait %d s between two all-server sends", math.ceil(wait))
	end
	if not perMinute(publishTimes, HeroBroadcastService.GLOBAL_PER_MINUTE, false) then
		return false, "Too many all-server sends this minute: wait a little"
	end
	return true
end

-- Publishes { kind, data } to every server (the caller already ran it here). -> ok, reason
function HeroBroadcastService.Publish(kind, data, fromPlayer)
	if HeroBroadcastService.KINDS[kind] ~= true then
		return false, "unknown kind"
	end
	local allowed, why = HeroBroadcastService.CanPublish(fromPlayer)
	if not allowed then
		return false, why
	end
	stamp("global:" .. tostring(fromPlayer.UserId))
	perMinute(publishTimes, HeroBroadcastService.GLOBAL_PER_MINUTE)
	local payload = {
		V = HeroBroadcastService.VERSION,
		Kind = kind,
		Origin = HeroBroadcastService.SERVER_ID,
		Nonce = newId(),
		By = string.sub(fromPlayer.Name, 1, HeroBroadcastService.MAX_NAME_LENGTH),
		ById = fromPlayer.UserId,
		At = os.time(),
	}
	for key, value in pairs(data or {}) do
		if payload[key] == nil then
			payload[key] = value
		end
	end
	local okSize, encoded = pcall(HttpService.JSONEncode, HttpService, payload)
	if okSize and type(encoded) == "string" and #encoded > HeroBroadcastService.MAX_MESSAGE_BYTES then
		return false, "message too big for MessagingService"
	end
	seen[payload.Nonce] = os.clock()
	local ok, err = pcall(MessagingService.PublishAsync, MessagingService, HeroBroadcastService.TOPIC, payload)
	if not ok then
		lastError = shortError(err)
		warn("[HeroBroadcast] publish failed (" .. kind .. "): " .. lastError)
		return false, "cross-server messaging is unavailable (" .. lastError .. ")"
	end
	print(string.format("[HeroBroadcast] %s published %s%s to every server", fromPlayer.Name, kind,
		if data and data.Action then " " .. tostring(data.Action) else ""))
	return true
end

local function onMessage(message)
	local data = type(message) == "table" and message.Data or nil
	local clean, reason = HeroBroadcastService.ValidatePayload(data)
	if clean == nil then
		warn("[HeroBroadcast] ignored a cross-server message: " .. tostring(reason))
		return false
	end
	if clean.Origin == HeroBroadcastService.SERVER_ID or seen[clean.Nonce] ~= nil then
		return false -- our own echo (it already ran here) or a duplicate
	end
	local now = os.clock()
	for nonce, at in pairs(seen) do
		if now - at > HeroBroadcastService.SEEN_SECONDS then
			seen[nonce] = nil
		end
	end
	seen[clean.Nonce] = now
	if not perMinute(receiveTimes, HeroBroadcastService.RECEIVE_PER_MINUTE) then
		if now - lastDropWarn > 30 then
			lastDropWarn = now
			warn("[HeroBroadcast] too many cross-server messages: dropping some")
		end
		return false
	end
	print(string.format("[HeroBroadcast] %s from %s (another server)", clean.Kind .. (if clean.Action then " " .. clean.Action else ""),
		tostring(clean.By or "?")))
	if clean.Kind == "Announce" then
		return showAnnouncement("Global", clean.Text)
	end
	local handler = handlers[clean.Kind]
	if handler == nil then
		return false
	end
	local ok, err = pcall(handler, clean)
	if not ok then
		warn("[HeroBroadcast] " .. clean.Kind .. " handler failed: " .. shortError(err))
		return false
	end
	return true
end
HeroBroadcastService._onMessage = onMessage

-- scope "Server" | "All". -> ok, message, kind ("warn" when it only reached this server)
function HeroBroadcastService.Announce(fromPlayer, rawText, scope)
	if typeof(fromPlayer) ~= "Instance" or not isAdmin(fromPlayer) then
		return false, "Not allowed"
	end
	if scope ~= "Server" and scope ~= "All" then
		return false, "Scope must be this server or all servers"
	end
	local text, reason = HeroBroadcastService.CleanText(rawText)
	if text == nil then
		return false, reason
	end
	local key = "announce:" .. tostring(fromPlayer.UserId)
	local wait = cooldownLeft(key, HeroBroadcastService.ANNOUNCE_COOLDOWN)
	if wait > 0 then
		return false, string.format("Wait %d s before the next announcement", math.ceil(wait))
	end
	if scope == "All" then
		local allowed, why = HeroBroadcastService.CanPublish(fromPlayer)
		if not allowed then
			return false, why
		end
	end
	stamp(key)
	local filtered, filterReason = HeroBroadcastService.FilterText(fromPlayer, text)
	if filtered == nil then
		return false, filterReason
	end
	if not string.find(filtered, "[^#%s]") then
		return false, "The Roblox filter blocked this message: nothing was sent"
	end
	if scope == "Server" then
		showAnnouncement("Server", filtered)
		return true, "Announcement shown on this server"
	end
	showAnnouncement("Global", filtered)
	local ok, err = HeroBroadcastService.Publish("Announce", { Text = filtered }, fromPlayer)
	if ok then
		return true, "Announcement sent to every server"
	end
	return true, "Announcement shown on THIS server only: " .. tostring(err), "warn"
end

----------------------------------------------------------------------------------------------------
-- Branch lifecycle
----------------------------------------------------------------------------------------------------

function HeroBroadcastService:Init()
	local network = ReplicatedStorage:FindFirstChild("Network") or ReplicatedStorage:WaitForChild("Network", 4)
	if network == nil then
		network = Instance.new("Folder")
		network.Name = "Network"
		network.Parent = ReplicatedStorage
	end
	local existing = network:FindFirstChild(HeroBroadcastService.REMOTE_NAME)
	if existing and not existing:IsA("RemoteEvent") then
		existing:Destroy()
		existing = nil
	end
	remote = existing
	if remote == nil then
		remote = Instance.new("RemoteEvent")
		remote.Name = HeroBroadcastService.REMOTE_NAME
		remote.Parent = network
	end
	remote.OnServerEvent:Connect(function() end) -- server -> client only
	remote:SetAttribute("CrossServer", "offline")
end

local function subscribe()
	local ok, err = pcall(MessagingService.SubscribeAsync, MessagingService, HeroBroadcastService.TOPIC, function(message)
		local okMessage, problem = pcall(onMessage, message)
		if not okMessage then
			warn("[HeroBroadcast] message failed: " .. shortError(problem))
		end
	end)
	setStatus(ok, err)
	return ok, err
end

function HeroBroadcastService:Start()
	local ok, err = subscribe()
	if ok then
		print("[HeroBroadcast] subscribed to " .. HeroBroadcastService.TOPIC)
		return
	end
	warn("[HeroBroadcast] cross-server messaging unavailable (" .. shortError(err) .. "): admin events and announcements reach this server only")
	for _, delay in ipairs(HeroBroadcastService.SUBSCRIBE_RETRIES) do
		task.wait(delay)
		if subscribe() then
			print("[HeroBroadcast] subscribed to " .. HeroBroadcastService.TOPIC .. " (retry)")
			return
		end
	end
end

function HeroBroadcastService:PlayerRemoving(player)
	lastSendAt["global:" .. tostring(player.UserId)] = nil
	lastSendAt["announce:" .. tostring(player.UserId)] = nil
end

return HeroBroadcastService
