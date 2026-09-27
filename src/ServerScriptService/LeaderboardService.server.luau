-- ServerScriptService.LeaderboardService (server Script, injected by scripts/inject/leaderboards.luau)
-- Fills the hub's HERO BOARD (Workspace.Hub.HeroBoard, built by scripts/steps/post_x_hero_board.luau: one wall-mounted
-- SurfaceGui with one page per stat, Screen > BoardGui > Board > List > Pages > Page_<stat>; every page carries the
-- attribute LeaderboardStat and holds static rows Row01..RowNN (Rank.Label, Avatar, PlayerName, Value) plus an "Empty"
-- label) and stands every page's top 3 on its podium:
--
--   Page_Networth     TOTAL NETWORTH  Money + the sell value of every hero the player owns (pen and backpack,
--                                     AssetService.HeroSellPrice = what the Sell stall pays) + the sell value of every
--                                     unhatched egg (AssetService.EggSellPrice). Computed here from the profile, never
--                                     stored.
--   Page_SpeedPower   TOTAL SPEED     the profile's SpeedPower.
--   Page_TimePlayed   IN-GAME TIME    seconds played (persisted stat, Database default 0). Accumulated HERE,
--                                     server-side, once a second for every player whose profile is loaded; shown as
--                                     "3h 07m".
--   Page_EggsHatched  EGGS HATCHED    hatches completed (persisted stat, Database default 0), incremented by EggService
--                                     when RequestCompleteHatchEgg succeeds.
--
--   * Every SAVE_INTERVAL seconds each loaded player's values are written to one OrderedDataStore per stat, then the
--     global top is read back. Values are stored as an order-preserving log10 encoding, so any value (money and speed
--     grow far past what an OrderedDataStore integer can hold) keeps its rank.
--   * Every RENDER_INTERVAL seconds every page shows that global top merged with the live values of the players in
--     this server, so a player sees their own row move right away. All pages are filled for everyone; which page a
--     player SEES is chosen on their own client (StarterPlayerScripts.Game.HeroBoard, the tab ClickDetectors), so the
--     server never writes a page's Visible.
--   * Podium (Podium > Spot1..3 > Stand, NamePlate) follows the tabs (owner 2026-09-27: "the Top 3 podiums change with
--     them"): for EVERY page stat the real R15 avatars of its current top 3 (mergedTop ordering) stand on the tiers in
--     a static superhero pose each (1st hands on hips, 2nd arms crossed, 3rd fist raised + fist to chest), tagged with
--     the attribute PodiumStat; the plates are published as Spot attributes Name_<stat> / Value_<stat>. Each viewer's
--     client (StarterPlayerScripts.Game.HeroBoard) shows only the selected tab's avatars (LocalTransparencyModifier)
--     and writes that tab's plate texts, so the server never writes a plate label nor hides an avatar. A user's look
--     is built ONCE (Players:GetHumanoidDescriptionFromUserId + Players:CreateHumanoidModelFromDescription, every call
--     pcall'd, a failed user retried after AVATAR_RETRY_SECONDS) into a template kept in ServerStorage and cloned for
--     each podium spot that user holds (one user can top several pages); a spot's clone is only re-created when its
--     user changes. Avatars: HumanoidRootPart anchored, no collision / query / touch, CollisionGroup "NPCs", no
--     Humanoid name / health display (the NamePlate is ours). An empty spot shows its pedestal with a "???" plate.
--   * Without DataStore access (Studio without API access, outages) the board keeps working with the players in
--     this server only.
-- Everything is server-authoritative: clients never send a value. The server edits the board SurfaceGui directly (it
-- lives in Workspace, so the rows replicate to everyone).

local DataStoreService = game:GetService("DataStoreService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local SAVE_INTERVAL = 60
local RENDER_INTERVAL = 5
local PLAYTIME_INTERVAL = 1 -- seconds between two TimePlayed accruals
local PLAYTIME_MAX_STEP = 30 -- never credit more than this in one accrual (server hitch / long yield)
local PRICE_CACHE_SECONDS = 60 -- a hero / egg record's sell value is re-priced at most once a minute
local NAME_RETRY_SECONDS = 60 -- a failed GetNameFromUserIdAsync is tried again after this long
local STORE_VERSION = "v1"
local LOG_SCALE = 1e13 -- log10 fixed-point: 308 * 1e13 stays far below 2^63
local BOARD_WAIT_SECONDS = 30
local PODIUM_SIZE = 3
local AVATAR_RETRY_SECONDS = 30 -- a user whose avatar could not be built is tried again after this long
local NPC_COLLISION_GROUP = "NPCs"

local Database = require(ServerScriptService:WaitForChild("Library"):WaitForChild("Database"))

local function log(message)
	print("[LeaderboardService] " .. message)
end

----------------------------------------------------------------------------------------------------
-- Values
----------------------------------------------------------------------------------------------------

local function finite(value)
	value = tonumber(value)
	if value == nil or value ~= value or value == math.huge or value == -math.huge then
		return 0
	end
	return math.max(value, 0)
end

local function encode(value)
	return math.floor(math.log10(finite(value) + 1) * LOG_SCALE)
end

local function decode(stored)
	local value = math.max(10 ^ ((tonumber(stored) or 0) / LOG_SCALE) - 1, 0)
	-- counters and seconds come back as 3599.9999...: round what an integer can still represent exactly
	if value < 1e15 then
		value = math.floor(value + 0.5)
	end
	return value
end

local SUFFIXES = { -- the game's own FormatNumber.Simple suffixes
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg",
}

local function compact(value)
	value = finite(value)
	if value < 1000 then
		return tostring(math.floor(value))
	end
	local tier = math.min(math.floor(math.log10(value) / 3), #SUFFIXES - 1)
	local scaled = value / 10 ^ (tier * 3)
	local text = if scaled >= 100 then string.format("%d", math.floor(scaled)) else string.format("%.1f", math.floor(scaled * 10) / 10)
	text = string.gsub(text, "%.0$", "")
	return text .. SUFFIXES[tier + 1]
end

-- 42 -> "42s", 754 -> "12m", 11220 -> "3h 07m", 3.6e7 -> "10K h"
local function duration(value)
	local seconds = math.floor(finite(value))
	local hours = seconds // 3600
	local minutes = (seconds % 3600) // 60
	if hours >= 10000 then
		return compact(hours) .. " h"
	elseif hours > 0 then
		return string.format("%dh %02dm", hours, minutes)
	elseif minutes > 0 then
		return string.format("%dm", minutes)
	end
	return string.format("%ds", seconds)
end

----------------------------------------------------------------------------------------------------
-- Networth: Money + sell value of every owned hero and unhatched egg
----------------------------------------------------------------------------------------------------

-- Priced through AssetService (the same functions the Sell stall pays with), required lazily: Bootstrap has long
-- loaded it by the first render. Fallback without it: GetPriceValueForItem x the multiplier AssetService publishes on
-- the RequestSell remote (heroes only).
local pricers = nil
local function getPricers()
	if pricers ~= nil then
		return pricers
	end
	local found = {}
	local controllers = ServerScriptService:FindFirstChild("Controllers")
	local module = controllers and controllers:FindFirstChild("AssetService")
	if module and module:IsA("ModuleScript") then
		local ok, service = pcall(require, module)
		if ok and type(service) == "table" then
			found.hero = if type(service.HeroSellPrice) == "function" then service.HeroSellPrice else nil
			found.egg = if type(service.EggSellPrice) == "function" then service.EggSellPrice else nil
		end
	end
	if found.hero == nil then
		local library = ReplicatedStorage:FindFirstChild("Library")
		local util = library and library:FindFirstChild("Util")
		local priceModule = util and util:FindFirstChild("GetPriceValueForItem")
		local ok, getPrice = pcall(function()
			return require(priceModule)
		end)
		if ok and type(getPrice) == "function" then
			found.hero = function(item)
				local network = ReplicatedStorage:FindFirstChild("Network")
				local remote = network and network:FindFirstChild("ActiveAssets: RequestSell")
				local multiplier = tonumber(remote and remote:GetAttribute("HeroSellMultiplier")) or 1
				local okPrice, price = pcall(getPrice, item)
				return if okPrice then math.floor(finite(price) * multiplier) else 0
			end
		end
		log("AssetService.HeroSellPrice unavailable: heroes priced with GetPriceValueForItem")
	end
	pricers = found
	return found
end

local priceCache = setmetatable({}, { __mode = "k" }) -- [record table] = { value, at }

local function cachedPrice(record, pricer)
	if type(record) ~= "table" or pricer == nil then
		return 0
	end
	local now = os.clock()
	local entry = priceCache[record]
	if entry and now - entry.at < PRICE_CACHE_SECONDS then
		return entry.value
	end
	local ok, price = pcall(pricer, record)
	local value = if ok then finite(price) else 0
	priceCache[record] = { value = value, at = now }
	return value
end

local function networthOf(profile)
	local total = finite(profile.Money)
	local found = getPricers()
	if type(profile.Inventory) == "table" then
		for _, item in pairs(profile.Inventory) do
			total += cachedPrice(item, found.hero)
		end
	end
	if type(profile.EggInventory) == "table" then
		for _, egg in pairs(profile.EggInventory) do
			total += cachedPrice(egg, found.egg)
		end
	end
	return total
end

-- stat -> how a loaded profile's value is read and how a board shows it (any other stat: profile[stat], compact)
local STATS = {
	Networth = {
		read = networthOf,
		format = function(value)
			return "$" .. compact(value)
		end,
	},
	Money = { -- kept for a board still labelled with the old stat
		format = function(value)
			return "$" .. compact(value)
		end,
	},
	SpeedPower = { format = compact },
	TimePlayed = { format = duration },
	EggsHatched = { format = compact },
}

local function readStat(stat, profile)
	local spec = STATS[stat]
	if spec and spec.read then
		local ok, value = pcall(spec.read, profile)
		return if ok then finite(value) else 0
	end
	return finite(profile[stat])
end

local function formatStat(stat, value)
	local spec = STATS[stat]
	return (spec and spec.format or compact)(value)
end

----------------------------------------------------------------------------------------------------
-- In-game time (TimePlayed): accumulated server-side
----------------------------------------------------------------------------------------------------

local playtimeClock: { [Player]: number } = {}

local function accruePlaytime()
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = Database.Get(player)
		if type(profile) == "table" and Database.IsPlayerLoaded(player) then
			local last = playtimeClock[player]
			if last then
				profile.TimePlayed = finite(profile.TimePlayed) + math.clamp(now - last, 0, PLAYTIME_MAX_STEP)
			end
			playtimeClock[player] = now
		else
			playtimeClock[player] = nil
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Boards
----------------------------------------------------------------------------------------------------

-- one page of the HERO BOARD (one stat)
type Board = { stat: string, rows: { Frame }, empty: TextLabel? }

local boards: { Board } = {}
local stats: { [string]: boolean } = {}
local heroBoard: Model? = nil

-- Every page of Workspace.Hub.HeroBoard: a GuiObject carrying LeaderboardStat that holds Row01.
local function collectBoards()
	local hub = Workspace:WaitForChild("Hub", BOARD_WAIT_SECONDS)
	local root = hub and hub:WaitForChild("HeroBoard", BOARD_WAIT_SECONDS)
	if root == nil then
		log("Workspace.Hub.HeroBoard not found - no board to fill")
		return
	end
	heroBoard = root
	local rowCount = tonumber(root:GetAttribute("LeaderboardRows")) or 10
	for _, page in ipairs(root:GetDescendants()) do
		local stat = page:GetAttribute("LeaderboardStat")
		if type(stat) == "string" and page:IsA("GuiObject") and page:FindFirstChild("Row01") then
			local rows = {}
			for index = 1, (tonumber(page:GetAttribute("LeaderboardRows")) or rowCount) do
				local row = page:FindFirstChild(string.format("Row%02d", index))
				if row then
					table.insert(rows, row)
				end
			end
			local empty = page:FindFirstChild("Empty")
			table.insert(boards, { stat = stat, rows = rows, empty = if empty and empty:IsA("TextLabel") then empty else nil })
			stats[stat] = true
		end
	end
	local names = {}
	for stat in pairs(stats) do
		table.insert(names, stat)
	end
	table.sort(names)
	log(string.format("HERO BOARD: %d page(s) found (%s)", #boards, table.concat(names, ", ")))
end

----------------------------------------------------------------------------------------------------
-- Global top (OrderedDataStore)
----------------------------------------------------------------------------------------------------

local stores = {}
local storeOnline = true
local globalTop: { [string]: { { userId: number, value: number } } } = {}
local lastSaved: { [Player]: { [string]: number } } = {}
local names: { [number]: string } = {}
local nameLookups: { [number]: boolean } = {}

local function goOffline(reason)
	if storeOnline then
		storeOnline = false
		log("OrderedDataStore unavailable (" .. tostring(reason) .. "): the boards show this server's players only")
	end
end

-- Errors that will not go away by retrying (no API access in Studio, unpublished place): stop using the store.
-- Not a bare "api" match: Roblox's transient outage errors read "502: API Services rejected request with error.
-- HTTP 500 (Internal Server Error)", and one of those must not turn the global boards off for the server's lifetime.
local function isPermanent(err)
	local text = string.lower(tostring(err))
	return string.find(text, "studioaccesstoapisnotallowed", 1, true) ~= nil
		or string.find(text, "studio access", 1, true) ~= nil or string.find(text, "api access", 1, true) ~= nil
		or string.find(text, "publish", 1, true) ~= nil
		or string.find(text, "403", 1, true) ~= nil or string.find(text, "forbidden", 1, true) ~= nil
end

local function storeFor(stat)
	if not storeOnline then
		return nil
	end
	if stores[stat] == nil then
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore("Leaderboard_" .. stat .. "_" .. STORE_VERSION)
		end)
		if not ok then
			goOffline(store)
			return nil
		end
		stores[stat] = store
	end
	return stores[stat]
end

local function savePlayer(player)
	local profile = Database.Get(player)
	if type(profile) ~= "table" or not Database.IsPlayerLoaded(player) then
		return
	end
	local saved = lastSaved[player] or {}
	lastSaved[player] = saved
	for stat in pairs(stats) do
		local encoded = encode(readStat(stat, profile))
		local store = storeFor(stat)
		if store and saved[stat] ~= encoded then
			local ok, err = pcall(function()
				store:SetAsync(tostring(player.UserId), encoded)
			end)
			if ok then
				saved[stat] = encoded
			elseif isPermanent(err) then
				goOffline(err)
				return
			else
				log("save " .. stat .. " for " .. player.Name .. " failed: " .. tostring(err))
			end
		end
	end
end

local function refreshGlobal()
	for stat in pairs(stats) do
		local store = storeFor(stat)
		if store then
			local ok, result = pcall(function()
				return store:GetSortedAsync(false, 10):GetCurrentPage()
			end)
			if ok and type(result) == "table" then
				local top = {}
				for _, entry in ipairs(result) do
					local userId = tonumber(entry.key)
					if userId then
						table.insert(top, { userId = userId, value = decode(entry.value) })
					end
				end
				globalTop[stat] = top
			elseif isPermanent(result) then
				goOffline(result)
				return
			else
				log("top " .. stat .. " read failed: " .. tostring(result))
			end
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Names
----------------------------------------------------------------------------------------------------

local function nameOf(userId)
	if names[userId] then
		return names[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		names[userId] = player.Name
		return player.Name
	end
	if not nameLookups[userId] then
		nameLookups[userId] = true
		task.spawn(function()
			local ok, name = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if ok and type(name) == "string" then
				names[userId] = name
			else
				-- a failed lookup (web hiccup) is retried later instead of leaving the row at "..." for good
				task.wait(NAME_RETRY_SECONDS)
				nameLookups[userId] = nil
			end
		end)
	end
	return "..."
end

----------------------------------------------------------------------------------------------------
-- Render
----------------------------------------------------------------------------------------------------

-- live values of the loaded players, read once per render for every stat on a board
local function liveValues()
	local live = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = Database.Get(player)
		if type(profile) == "table" and Database.IsPlayerLoaded(player) then
			local values = {}
			for stat in pairs(stats) do
				values[stat] = readStat(stat, profile)
			end
			live[player.UserId] = values
		end
	end
	return live
end

local function mergedTop(stat, count, live)
	local byUser = {}
	for _, entry in ipairs(globalTop[stat] or {}) do
		byUser[entry.userId] = entry.value
	end
	-- live values win: they are newer than the last save
	for userId, values in pairs(live) do
		byUser[userId] = values[stat] or 0
	end
	local list = {}
	for userId, value in pairs(byUser) do
		table.insert(list, { userId = userId, value = value })
	end
	table.sort(list, function(a, b)
		if a.value ~= b.value then
			return a.value > b.value
		end
		return a.userId < b.userId
	end)
	while #list > count do
		table.remove(list)
	end
	return list
end

local function setText(label, text)
	if label and label:IsA("TextLabel") and label.Text ~= text then
		label.Text = text
	end
end

----------------------------------------------------------------------------------------------------
-- Podium: every page's top 3 as real avatars (each viewer sees the selected tab's)
----------------------------------------------------------------------------------------------------

-- Joint rotation (degrees) in the joint's own frame (R15: X = the rig's right, Y = up, Z = back), applied Z first,
-- then Y, then X.
local function R(x: number, y: number, z: number): CFrame
	return CFrame.Angles(math.rad(x), 0, 0) * CFrame.Angles(0, math.rad(y), 0) * CFrame.Angles(0, 0, math.rad(z))
end

-- Static superhero poses by podium rank: Motor6D.C0 = the rig's own C0 * rotation (no animation asset needed,
-- deterministic, replicates like any property). Joints a rig lacks are skipped.
local POSES = {
	[1] = { -- hands on hips, chest out, chin up
		Waist = R(5, 0, 0), Neck = R(10, 0, 0),
		RightShoulder = R(-12, 0, 42), RightElbow = R(0, 0, -112), RightWrist = R(0, 0, -15),
		LeftShoulder = R(-12, 0, -42), LeftElbow = R(0, 0, 112), LeftWrist = R(0, 0, 15),
		RightHip = R(0, 0, 9), LeftHip = R(0, 0, -9), RightAnkle = R(0, 0, -9), LeftAnkle = R(0, 0, 9),
	},
	[2] = { -- arms crossed, weight on one leg
		Waist = R(3, 0, 0), Neck = R(6, -8, 0),
		RightShoulder = R(20, 75, 0), RightElbow = R(100, 0, 0),
		LeftShoulder = R(28, -78, 0), LeftElbow = R(92, 0, 0),
		RightHip = R(0, 0, 6), LeftHip = R(0, 0, -10), RightAnkle = R(0, 0, -6), LeftAnkle = R(0, 0, 10),
	},
	[3] = { -- fist raised high, the other fist to the chest
		Waist = R(4, -8, 0), Neck = R(12, -12, 0),
		RightShoulder = R(0, 0, 128), RightElbow = R(0, 0, 45),
		LeftShoulder = R(25, -60, 0), LeftElbow = R(118, 0, 0),
		RightHip = R(0, 0, 12), LeftHip = R(0, 0, -8), RightAnkle = R(0, 0, -12), LeftAnkle = R(0, 0, 8),
	},
}

type Spot = { rank: number, model: Instance, stand: BasePart }
-- one avatar standing on one spot for one stat (a clone of the user's template)
type Placed = { model: Model, userId: number, baseC0: { [Motor6D]: CFrame } }

local podiumStat = "Networth" -- the board's default tab (attribute PodiumStat); every page stat gets a podium set
local podiumStats: { string } = {}
local spots: { [number]: Spot } = {}
local placed: { [string]: { [number]: Placed } } = {} -- [stat][rank]
local templates: { [number]: Model } = {} -- [userId]: the user's unposed avatar, parented under ServerStorage
local templatePending: { [number]: boolean } = {}
local templateRetryAt: { [number]: number } = {}
local templateFolder: Folder? = nil
local collisionGroupReady = false

local function collectPodium()
	local podium = heroBoard and heroBoard:FindFirstChild("Podium")
	if podium == nil then
		log("HERO BOARD has no Podium - no avatars")
		return
	end
	podiumStat = heroBoard:GetAttribute("PodiumStat") or podium:GetAttribute("PodiumStat") or podiumStat
	for rank = 1, PODIUM_SIZE do
		local spot = podium:FindFirstChild("Spot" .. rank)
		local stand = spot and spot:FindFirstChild("Stand")
		if stand and stand:IsA("BasePart") then
			spots[rank] = { rank = rank, model = spot, stand = stand }
		end
	end
	if next(spots) == nil then
		log("podium has no Stand anchors - no avatars")
		return
	end
	-- one podium set per page, in board order (the default tab first)
	local seen = {}
	for _, stat in ipairs({ podiumStat }) do
		seen[stat] = true
		table.insert(podiumStats, stat)
	end
	for _, board in ipairs(boards) do
		if not seen[board.stat] then
			seen[board.stat] = true
			table.insert(podiumStats, board.stat)
		end
	end
	for _, stat in ipairs(podiumStats) do
		stats[stat] = true
		placed[stat] = {}
	end
	local folder = Instance.new("Folder")
	folder.Name = "HeroBoardPodiumAvatars"
	folder.Parent = ServerStorage
	templateFolder = folder
	log(string.format("podium: %d spot(s), top %d of %s", #spots, PODIUM_SIZE, table.concat(podiumStats, ", ")))
end

-- "NPCs" (non-collidable with players; ServerScriptService.Bootstrap sets its rules) registered defensively.
local function ensureCollisionGroup(): boolean
	if collisionGroupReady then
		return true
	end
	local okCheck, registered = pcall(function()
		return PhysicsService:IsCollisionGroupRegistered(NPC_COLLISION_GROUP)
	end)
	if okCheck and not registered then
		pcall(function()
			PhysicsService:RegisterCollisionGroup(NPC_COLLISION_GROUP)
		end)
		okCheck, registered = pcall(function()
			return PhysicsService:IsCollisionGroupRegistered(NPC_COLLISION_GROUP)
		end)
	end
	collisionGroupReady = okCheck and registered == true
	return collisionGroupReady
end

-- The user's avatar look: their published avatar, else (Studio test players have negative ids, web hiccups) the
-- character in this server, else the default avatar for a test id. nil = try again later.
local function descriptionFor(userId: number): HumanoidDescription?
	if userId > 0 then
		local ok, description = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(userId)
		end)
		if ok and typeof(description) == "Instance" and description:IsA("HumanoidDescription") then
			return description
		end
	end
	local player = Players:GetPlayerByUserId(userId)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local ok, description = pcall(function()
			return humanoid:GetAppliedDescription()
		end)
		if ok and typeof(description) == "Instance" and description:IsA("HumanoidDescription") then
			return description
		end
	end
	if userId <= 0 then
		return Instance.new("HumanoidDescription")
	end
	return nil
end

-- A statue-like R15 model of the user: anchored root, nothing collides / queries / touches, no Humanoid overhead UI.
local function buildAvatar(userId: number): Model?
	local description = descriptionFor(userId)
	if description == nil then
		return nil
	end
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or typeof(model) ~= "Instance" or not model:IsA("Model") then
		log("podium avatar for " .. tostring(userId) .. " could not be built: " .. tostring(model))
		return nil
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart") and humanoid) then
		model:Destroy()
		return nil
	end
	model.Name = "PodiumAvatar_" .. tostring(userId)
	model:SetAttribute("PodiumUserId", userId)
	model.PrimaryPart = root
	pcall(function()
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoid.NameDisplayDistance = 0
		humanoid.HealthDisplayDistance = 0
		humanoid.DisplayName = ""
		humanoid.BreakJointsOnDeath = false
		humanoid.RequiresNeck = false
	end)
	pcall(function()
		humanoid.EvaluateStateMachine = false -- a statue: no state machine, no physics fighting the anchored root
	end)
	local grouped = ensureCollisionGroup()
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = d == root
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			if grouped then
				pcall(function()
					d.CollisionGroup = NPC_COLLISION_GROUP
				end)
			end
		elseif d:IsA("LuaSourceContainer") or d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke")
			or d:IsA("Sparkles") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Light") or d:IsA("Highlight") then
			-- no scripts; no accessory effects either (every stat has its own stacked set: the client hides the unused
			-- ones with LocalTransparencyModifier, which effects ignore)
			d:Destroy()
		end
	end
	root.Anchored = true
	return model
end

local function applyPose(entry: Placed, rank: number)
	local pose = POSES[rank] or {}
	for motor, base in pairs(entry.baseC0) do
		if motor.Parent ~= nil then
			local rotation = pose[motor.Name]
			motor.C0 = if rotation then base * rotation else base
		end
	end
end

-- Stands a clone of the user's template on `spot` for `stat` (feet on the tier top, facing where the Stand faces),
-- in the spot's pose.
local function placeClone(stat: string, spot: Spot, userId: number): Placed?
	local template = templates[userId]
	if template == nil then
		return nil
	end
	local model = template:Clone()
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and root:IsA("BasePart")) then
		model:Destroy()
		return nil
	end
	model.Name = "PodiumAvatar_" .. stat .. "_" .. tostring(userId)
	model:SetAttribute("PodiumStat", stat)
	model:SetAttribute("PodiumRank", spot.rank)
	local baseC0 = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") then
			baseC0[d] = d.C0
		end
	end
	local entry: Placed = { model = model, userId = userId, baseC0 = baseC0 }
	local stand = spot.stand
	local ground = stand.Position.Y - stand.Size.Y / 2
	local hip = if humanoid.HipHeight > 0 then humanoid.HipHeight else 2
	model:PivotTo(CFrame.new(stand.Position.X, ground + hip + root.Size.Y / 2, stand.Position.Z) * stand.CFrame.Rotation)
	model.Parent = spot.model
	applyPose(entry, spot.rank)
	-- a rig can be rebuilt from its attachments once it is in Workspace: pose it again a moment later
	local rank = spot.rank
	task.delay(1, function()
		if model.Parent ~= nil then
			applyPose(entry, rank)
		end
	end)
	return entry
end

-- Builds the user's template once (asynchronously); the next render places the clones.
local function requestTemplate(userId: number)
	if templates[userId] or templatePending[userId] or os.clock() < (templateRetryAt[userId] or 0) then
		return
	end
	templatePending[userId] = true
	task.spawn(function()
		local ok, model = pcall(buildAvatar, userId)
		templatePending[userId] = nil
		if not ok or model == nil then
			templateRetryAt[userId] = os.clock() + AVATAR_RETRY_SECONDS
			if not ok then
				log("podium avatar for " .. tostring(userId) .. " failed: " .. tostring(model))
			end
			return
		end
		if templates[userId] ~= nil then
			model:Destroy()
			return
		end
		model.Parent = templateFolder
		templates[userId] = model
	end)
end

local function updatePodium(live)
	local wanted: { [number]: boolean } = {}
	for _, stat in ipairs(podiumStats) do
		local entries = mergedTop(stat, PODIUM_SIZE, live)
		local set = placed[stat]
		for rank, spot in pairs(spots) do
			local entry = entries[rank]
			local userId = entry and entry.userId
			-- the plate of this stat, written by each viewer's client for the tab it shows
			spot.model:SetAttribute("Name_" .. stat, if entry then nameOf(entry.userId) else "???")
			spot.model:SetAttribute("Value_" .. stat, if entry then formatStat(stat, entry.value) else "")
			local current = set[rank]
			if current and (current.userId ~= userId or current.model.Parent == nil) then
				set[rank] = nil
				current.model:Destroy()
				current = nil
			end
			if userId then
				wanted[userId] = true
				if current == nil then
					if templates[userId] then
						local ok, result = pcall(placeClone, stat, spot, userId)
						if ok and result then
							set[rank] = result
						elseif not ok then
							log("podium avatar for " .. tostring(userId) .. " could not be placed: " .. tostring(result))
						end
					else
						requestTemplate(userId)
					end
				end
			end
		end
	end
	-- templates of users who hold no spot any more go away
	for userId, template in pairs(templates) do
		if not wanted[userId] then
			templates[userId] = nil
			template:Destroy()
		end
	end
end

local function render()
	local live = liveValues()
	for _, board in ipairs(boards) do
		local entries = mergedTop(board.stat, #board.rows, live)
		for index, row in ipairs(board.rows) do
			local entry = entries[index]
			if entry then
				setText(row:FindFirstChild("PlayerName"), nameOf(entry.userId))
				setText(row:FindFirstChild("Value"), formatStat(board.stat, entry.value))
				local avatar = row:FindFirstChild("Avatar")
				local image = "rbxthumb://type=AvatarHeadShot&id=" .. entry.userId .. "&w=150&h=150"
				if avatar and avatar:IsA("ImageLabel") and avatar.Image ~= image then
					avatar.Image = image
				end
				row.Visible = true
			else
				row.Visible = false
			end
		end
		if board.empty then
			board.empty.Visible = #entries == 0
		end
	end
	if next(spots) ~= nil then
		local ok, err = pcall(updatePodium, live)
		if not ok then
			log("podium update failed: " .. tostring(err))
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Lifecycle
----------------------------------------------------------------------------------------------------

-- TimePlayed accrues whether or not any board exists (it is a persisted stat of its own).
task.spawn(function()
	while true do
		local ok, err = pcall(accruePlaytime)
		if not ok then
			log("playtime accrual failed: " .. tostring(err))
		end
		task.wait(PLAYTIME_INTERVAL)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	pcall(accruePlaytime) -- credit the last partial second(s) before Database saves on leave
	pcall(savePlayer, player)
	lastSaved[player] = nil
	playtimeClock[player] = nil
end)

collectBoards()
if #boards == 0 then
	return
end
collectPodium()

game:BindToClose(function()
	pcall(accruePlaytime)
	for _, player in ipairs(Players:GetPlayers()) do
		pcall(savePlayer, player)
	end
end)

task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(savePlayer, player)
			-- SetAsync yields: a player who left meanwhile (PlayerRemoving already ran) must not stay in lastSaved
			if player.Parent == nil then
				lastSaved[player] = nil
			end
		end
		pcall(refreshGlobal)
		task.wait(SAVE_INTERVAL)
	end
end)

while true do
	local ok, err = pcall(render)
	if not ok then
		log("render failed: " .. tostring(err))
	end
	task.wait(RENDER_INTERVAL)
end
