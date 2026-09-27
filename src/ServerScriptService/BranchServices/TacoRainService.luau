-- ServerScriptService.BranchServices.TacoRainService (Branch service; injected by scripts/inject/admin_panel.luau,
-- started by ServerScriptService.BranchServer)
-- Owner 2026-09-27: "migrate the taco event (without the treadmill) to the admin panel: a rain of tacos, where there is a
-- chance a taco falls on an egg in your base or on the stages, which multiplies that egg x3, with the taco explosion VFX,
-- the taco particle emitter and the taco music". Server-authoritative:
--   * Start(duration) / Stop() (the admin panel's World tab, through BranchServices.HeroAdminService). While it runs the
--     Workspace attribute TacoRainUntil holds the end (server time) and TacoRainHits the eggs hit so far: every client
--     (BranchControllers.TacoRainController) draws the sky, the music and the decorative tacos from them alone, so a
--     player who joins mid-event sees it too.
--   * every TICK seconds, with EGG_CHANCE, one taco is aimed at an egg: an egg placed on a player's base (profile
--     EggInventory with a Placement: Library.Database) or a stage egg resting in its nest (Controllers.AreaEggService
--     GetRestingEggs). The two pools get an even share when both have eggs. The server broadcasts
--     Network["TacoRain: Event"] { Action = "Drop", Id, Kind = "Plot" | "Stage", Uid, OwnerUserId, Position, FallTime },
--     every client drops a taco from the sky onto Position in FallTime seconds, and when it lands the server re-checks the
--     egg and gives it the "Taco" mutation (Library.Modules.Mutations: x3 value): { Action = "Hit", ... } (the explosion
--     and a floating "x3 TACO!") or { Action = "Miss", Id } when the egg was hatched / stolen / claimed meanwhile.
--   * an egg is never hit twice (an egg that already has the mutation is skipped, and every egg aimed at is remembered
--     for the server's life); a carried or dropped stage egg is never touched (AddRestingEggMutation only takes nest
--     eggs); at most MAX_HITS eggs per event.
--   * the mutation lives in the egg record, so it carries through: a stage egg's claim copies record.Mutations into the
--     thief's EggInventory, EggItemUtil.BuildAssetItemData copies an egg's Mutations into the hatched hero, and
--     AssetGenerationUtil.GetRate multiplies the hero's income by Mutations.GetTotalMutationsEarningMulti (x3).
-- The remote is server -> client only (anything a client fires at it is ignored).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local TacoRainService = {}

TacoRainService.REMOTE_NAME = "TacoRain: Event"
TacoRainService.MUTATION = "Taco"
TacoRainService.UNTIL_ATTRIBUTE = "TacoRainUntil"
TacoRainService.HITS_ATTRIBUTE = "TacoRainHits"
TacoRainService.DEFAULT_DURATION = 75
TacoRainService.MIN_DURATION = 15
TacoRainService.MAX_DURATION = 300
TacoRainService.TICK = 1 -- s between two egg rolls
TacoRainService.EGG_CHANCE = 0.15 -- chance per tick that a taco is aimed at an egg (~11 eggs in a 75 s rain)
TacoRainService.FALL_TIME = 1.7 -- s from the sky to the egg (the clients animate the same fall)
TacoRainService.MAX_HITS = 30 -- eggs per event
TacoRainService.NOTICE_COLOR = Color3.fromRGB(255, 196, 36)

local remote = nil
local current = nil -- token of the running rain, nil when none
local hitsThisRain = 0
local dropId = 0
local aimed = {} -- [key] = true: every egg a taco was ever aimed at (never twice)
local pending = {} -- [key] = true while its taco falls

----------------------------------------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------------------------------------

local modules = {}
local function lazy(key, locate)
	local cached = modules[key]
	if cached ~= nil then
		return cached or nil
	end
	local module = locate()
	local ok, result = false, "not found"
	if module and module:IsA("ModuleScript") then
		ok, result = pcall(require, module)
	end
	modules[key] = if ok and type(result) == "table" then result else false
	if not ok then
		warn("[TacoRain] " .. key .. " unavailable: " .. tostring(result))
	end
	return modules[key] or nil
end

local function controller(name)
	return lazy(name, function()
		local controllers = ServerScriptService:FindFirstChild("Controllers")
		return controllers and controllers:FindFirstChild(name)
	end)
end

local function database()
	return lazy("Database", function()
		local library = ServerScriptService:FindFirstChild("Library")
		return library and library:FindFirstChild("Database")
	end)
end

local function heroName(category)
	local assets = lazy("Directory.Assets", function()
		local directory = ReplicatedStorage:FindFirstChild("Directory")
		return directory and directory:FindFirstChild("Assets")
	end)
	local ok, name = pcall(function()
		return assets.Directory[category].DisplayName
	end)
	return if ok and type(name) == "string" and name ~= "" then name else tostring(category or "hero")
end

local function notify(target, message)
	local network = ReplicatedStorage:FindFirstChild("Network")
	local notices = network and network:FindFirstChild("Notifications_Show")
	if not (notices and notices:IsA("RemoteEvent")) then
		return
	end
	local payload = { Time = 6, Message = message, Color = TacoRainService.NOTICE_COLOR }
	if target == nil then
		pcall(notices.FireAllClients, notices, "Message", "Top", payload)
	elseif target.Parent == Players then
		pcall(notices.FireClient, notices, target, "Message", "Top", payload)
	end
end

local function broadcast(payload)
	if remote then
		remote:FireAllClients(payload)
	end
end

local function hasMutation(mutations)
	return type(mutations) == "table" and table.find(mutations, TacoRainService.MUTATION) ~= nil
end

local function loadedProfile(player)
	local db = database()
	if db == nil then
		return nil, nil
	end
	local ok, profile = pcall(db.Get, player)
	if not ok or type(profile) ~= "table" or (type(db.IsPlayerLoaded) == "function" and db.IsPlayerLoaded(player) ~= true) then
		return nil, db
	end
	return profile, db
end

local function plotCenter(player)
	local plots = controller("PlotService")
	if not (plots and type(plots.GetPlotId) == "function") then
		return nil
	end
	local ok, plotId = pcall(plots.GetPlotId, player)
	local folder = Workspace:FindFirstChild("Plots")
	local plot = ok and plotId ~= nil and folder and folder:FindFirstChild(tostring(plotId))
	local center = plot and plot:FindFirstChild("CenterPoint")
	return if center and center:IsA("BasePart") then center.CFrame else nil
end

local function placedCFrame(center, egg)
	local placement = type(egg) == "table" and egg.Placement
	local components = type(placement) == "table" and placement.LocalCFrame
	if type(components) ~= "table" or #components ~= 12 then
		return nil
	end
	local ok, local_ = pcall(CFrame.new, table.unpack(components))
	return if ok then center * local_ else nil
end

----------------------------------------------------------------------------------------------------
-- targets
----------------------------------------------------------------------------------------------------

local function free(key)
	return not aimed[key] and not pending[key]
end

-- Eggs placed on the bases of the players in the server.
local function plotTargets()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = loadedProfile(player)
		local center = profile and plotCenter(player)
		if center and type(profile.EggInventory) == "table" then
			for uid, egg in pairs(profile.EggInventory) do
				local key = "Plot:" .. player.UserId .. ":" .. tostring(uid)
				if type(uid) == "string" and free(key) and not hasMutation(egg.Mutations) then
					local cframe = placedCFrame(center, egg)
					if cframe then
						table.insert(list, { Kind = "Plot", Key = key, Uid = uid, Owner = player, Position = cframe.Position,
							Category = egg.AssetCategory })
					end
				end
			end
		end
	end
	return list
end

-- Stage eggs resting in their nests.
local function stageTargets()
	local list = {}
	local area = controller("AreaEggService")
	if not (area and type(area.GetRestingEggs) == "function") then
		return list
	end
	local ok, eggs = pcall(area.GetRestingEggs)
	for _, egg in ipairs(ok and type(eggs) == "table" and eggs or {}) do
		local key = "Stage:" .. tostring(egg.Uid)
		if free(key) and not hasMutation(egg.Mutations) and typeof(egg.Position) == "Vector3" then
			table.insert(list, { Kind = "Stage", Key = key, Uid = egg.Uid, Position = egg.Position, Category = egg.AssetCategory })
		end
	end
	return list
end

function TacoRainService.PickTarget(random)
	random = random or Random.new()
	local plots, stages = plotTargets(), stageTargets()
	local pool = nil
	if #plots > 0 and #stages > 0 then
		pool = if random:NextNumber() < 0.5 then plots else stages
	elseif #plots > 0 then
		pool = plots
	elseif #stages > 0 then
		pool = stages
	end
	return pool and pool[random:NextInteger(1, #pool)] or nil
end

-- Gives the mutation to the egg a taco just landed on; false when the egg is gone / moving / already taco'd.
local function applyMutation(target)
	if target.Kind == "Stage" then
		local area = controller("AreaEggService")
		local ok, done = pcall(function()
			return area.AddRestingEggMutation(target.Uid, TacoRainService.MUTATION)
		end)
		return ok and done == true
	end
	local owner = target.Owner
	if owner == nil or owner.Parent ~= Players then
		return false
	end
	local profile, db = loadedProfile(owner)
	local egg = profile and type(profile.EggInventory) == "table" and profile.EggInventory[target.Uid]
	if type(egg) ~= "table" or type(egg.Placement) ~= "table" or hasMutation(egg.Mutations) then
		return false
	end
	egg.Mutations = if type(egg.Mutations) == "table" then egg.Mutations else {}
	table.insert(egg.Mutations, TacoRainService.MUTATION)
	db.Set(owner, { EggInventory = profile.EggInventory })
	local eggs = controller("EggService")
	if eggs and type(eggs.BroadcastOwnerRecords) == "function" then
		pcall(eggs.BroadcastOwnerRecords, owner)
	end
	return true
end

local function payloadOf(action, id, target)
	return {
		Action = action,
		Id = id,
		Kind = target.Kind,
		Uid = target.Uid,
		OwnerUserId = if target.Owner then target.Owner.UserId else 0,
		Position = target.Position,
		FallTime = TacoRainService.FALL_TIME,
	}
end

function TacoRainService.DropOnEgg(target)
	target = target or TacoRainService.PickTarget()
	if target == nil then
		return false
	end
	dropId += 1
	local id = dropId
	pending[target.Key] = true
	broadcast(payloadOf("Drop", id, target))
	task.delay(TacoRainService.FALL_TIME, function()
		pending[target.Key] = nil
		aimed[target.Key] = true
		local ok, hit = pcall(applyMutation, target)
		if ok and hit then
			hitsThisRain += 1
			if current ~= nil then
				Workspace:SetAttribute(TacoRainService.HITS_ATTRIBUTE, hitsThisRain)
			end
			local payload = payloadOf("Hit", id, target)
			payload.Label = "x3 TACO!"
			broadcast(payload)
			if target.Kind == "Plot" then
				notify(target.Owner, string.format("A taco landed on your %s egg: x3!", heroName(target.Category)))
			end
			print(string.format("[TacoRain] %s egg %s (%s) got the Taco mutation", target.Kind, tostring(target.Uid),
				heroName(target.Category)))
		else
			if not ok then
				warn("[TacoRain] landing failed: " .. tostring(hit))
			end
			broadcast({ Action = "Miss", Id = id })
		end
	end)
	return true
end

----------------------------------------------------------------------------------------------------
-- the event
----------------------------------------------------------------------------------------------------

function TacoRainService.IsActive()
	return current ~= nil
end

function TacoRainService.TimeLeft()
	local untilAt = Workspace:GetAttribute(TacoRainService.UNTIL_ATTRIBUTE)
	return if current and type(untilAt) == "number" then math.max(0, untilAt - Workspace:GetServerTimeNow()) else 0
end

function TacoRainService.Stop(reason)
	if current == nil then
		return false, "The Taco Rain is not running"
	end
	current = nil
	Workspace:SetAttribute(TacoRainService.UNTIL_ATTRIBUTE, nil)
	broadcast({ Action = "Stop" })
	local message = string.format("The Taco Rain is over: %d egg%s got the x3 taco.", hitsThisRain, if hitsThisRain == 1 then "" else "s")
	notify(nil, message)
	print("[TacoRain] stopped (" .. tostring(reason or "admin") .. "): " .. message)
	return true, message
end

function TacoRainService.Start(duration)
	duration = math.clamp(math.floor(tonumber(duration) or TacoRainService.DEFAULT_DURATION), TacoRainService.MIN_DURATION,
		TacoRainService.MAX_DURATION)
	local token = {}
	local restarted = current ~= nil
	current = token
	hitsThisRain = 0
	Workspace:SetAttribute(TacoRainService.UNTIL_ATTRIBUTE, Workspace:GetServerTimeNow() + duration)
	Workspace:SetAttribute(TacoRainService.HITS_ATTRIBUTE, 0)
	if not restarted then
		notify(nil, "IT'S RAINING TACOS! A taco that lands on an egg makes it x3.")
	end
	task.spawn(function()
		local random = Random.new()
		local endsAt = os.clock() + duration
		while current == token and os.clock() < endsAt do
			task.wait(TacoRainService.TICK)
			if current ~= token then
				break
			end
			if hitsThisRain < TacoRainService.MAX_HITS and random:NextNumber() < TacoRainService.EGG_CHANCE then
				local ok, err = pcall(TacoRainService.DropOnEgg, TacoRainService.PickTarget(random))
				if not ok then
					warn("[TacoRain] drop failed: " .. tostring(err))
				end
			end
		end
		if current == token then
			TacoRainService.Stop("time")
		end
	end)
	print(string.format("[TacoRain] %s for %d s", if restarted then "restarted" else "started", duration))
	return true, string.format("Taco Rain %s: %d s", if restarted then "restarted" else "started", duration)
end

function TacoRainService:Init()
	local network = ReplicatedStorage:FindFirstChild("Network") or ReplicatedStorage:WaitForChild("Network", 4)
	if network == nil then
		network = Instance.new("Folder")
		network.Name = "Network"
		network.Parent = ReplicatedStorage
	end
	local existing = network:FindFirstChild(TacoRainService.REMOTE_NAME)
	if existing and not existing:IsA("RemoteEvent") then
		existing:Destroy()
		existing = nil
	end
	remote = existing
	if remote == nil then
		remote = Instance.new("RemoteEvent")
		remote.Name = TacoRainService.REMOTE_NAME
		remote.Parent = network
	end
	remote.OnServerEvent:Connect(function() end) -- server -> client only
	-- a server that restarts mid-rain (Studio) must not show a rain nobody runs
	Workspace:SetAttribute(TacoRainService.UNTIL_ATTRIBUTE, nil)
	Workspace:SetAttribute(TacoRainService.HITS_ATTRIBUTE, nil)
end

-- Test hooks
TacoRainService._aimed = aimed
TacoRainService._pending = pending

return TacoRainService
