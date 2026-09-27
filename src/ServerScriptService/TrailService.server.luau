-- ServerScriptService.TrailService (Script) - server side of the Trails shop.
-- TRAILS 2026-09-23, owner: "Trails unpurchasable, needs fixing". Every server Script in the base place is an empty
-- ripper stub, so the four Trails RemoteFunctions were only answered by StubService's placeholders ("Not available").
--
-- Contract, read from the ripped clients:
--   GUI.Shops.TrailShop    Network.Invoke("Trails: RequestPurchase", trailId) -> ok, err?
--                          Network.Invoke("Trails: RequestSelect", trailId)   -> ok, err?
--                          Network.Invoke("Trails: RequestUnequip")           -> ok, err?
--   Game.TrailController   Network.Invoke("Trails: RequestActiveSnapshot")    -> { [tostring(userId)] = trailId }
--                          Network.Fired("Trails: ActiveTrailChanged")(player, trailId?) clones
--                          ReplicatedStorage.Assets.Trails[trailId] onto that player's HumanoidRootPart on every client
--                          and re-applies it on each CharacterAdded (respawn).
-- Profile fields (Library.Database): TrailInventory = { [trailId] = true }, EquippedTrail = trailId.
-- The active trail is EquippedTrail only while it is also owned: the same rule as
-- TreadmillUtil.ResolveEquippedTrailSpeedStepMultiplier, which applies the trail's Speed boost on the server.
-- "No trail" is stored as "": Database.Set cannot write nil (pairs skips it) and a missing EquippedTrail is refilled
-- with the "GreyTrail" default on the next load.
-- Robux: the trail configs carry the ripped game's developer product ids (another creator's experience, so they
-- cannot be sold here) and MarketplaceService.ProcessReceipt belongs to AmonetizationPurchaseService, so the shop
-- hides the Robux button and trails are bought with Money only. TrailService.GrantOwnedTrail (a BindableFunction
-- under this Script) is the hook a future ProcessReceipt branch can call.
-- Themed FX (TRAILS 2026-09-24, Gekko TO DO #4): a Legendary+ trail also gets its superpower effect,
-- ReplicatedStorage.Assets.TrailFx.<trailId> (built by scripts/steps/post_trail_fx.luau: Attachments with a core
-- Trail, ParticleEmitters, a PointLight, a Beam halo). This Script mounts it on the character as server instances
-- (replicated to everyone) next to the client-rendered ribbon, and removes it on unequip, death, respawn and leave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Network = ReplicatedStorage:WaitForChild("Network")
local Database = require(ServerScriptService:WaitForChild("Library"):WaitForChild("Database"))

local NONE = ""
local MAX_ID_LENGTH = 64
local REQUEST_COOLDOWN = 0.2

local REMOTE_PURCHASE = "Trails: RequestPurchase"
local REMOTE_SELECT = "Trails: RequestSelect"
local REMOTE_UNEQUIP = "Trails: RequestUnequip"
local REMOTE_SNAPSHOT = "Trails: RequestActiveSnapshot"
local EVENT_ACTIVE = "Trails: ActiveTrailChanged"

-- StubService binds "Not available" placeholders on the Trails remotes and Bootstrap requires it last, i.e. possibly
-- after this Script bound the real handlers. A ModuleScript body runs only once, so requiring it here first means its
-- placeholders are set before ours and can never overwrite them afterwards (every other stub it binds is unchanged).
do
	local controllers = ServerScriptService:WaitForChild("Controllers", 30)
	local stub = controllers and controllers:WaitForChild("StubService", 30)
	if stub and stub:IsA("ModuleScript") then
		local ok, err = pcall(require, stub)
		if not ok then
			warn("[TrailService] StubService failed to load first: " .. tostring(err))
		end
	end
end

local Trails = nil
do
	local directory = ReplicatedStorage:WaitForChild("Directory", 30)
	local module = directory and directory:WaitForChild("Trails", 30)
	local ok, result = false, "Directory.Trails missing"
	if module then
		ok, result = pcall(require, module)
	end
	if ok and type(result) == "table" then
		Trails = result
	else
		warn("[TrailService] Directory.Trails unavailable, trail requests will be refused: " .. tostring(result))
	end
end

local trailAssets = nil
do
	local assets = ReplicatedStorage:WaitForChild("Assets", 30)
	trailAssets = assets and assets:WaitForChild("Trails", 30)
	if not trailAssets then
		warn("[TrailService] ReplicatedStorage.Assets.Trails missing, no trail can be sold or shown")
	end
end

-- The directory config of a sellable trail, or nil. Rejects anything a client could send that is not a trail id
-- with a directory entry, a finite Money price and the BasePart asset TrailController clones.
local function getConfig(trailId)
	if Trails == nil or type(trailId) ~= "string" or #trailId == 0 or #trailId > MAX_ID_LENGTH then
		return nil
	end
	local okExists, exists = pcall(Trails.Types.TrailNameExists, trailId)
	if not okExists or exists ~= true then
		return nil
	end
	local okConfig, config = pcall(function()
		return Trails.Directory[trailId]
	end)
	if not okConfig or type(config) ~= "table" then
		return nil
	end
	local price = config.Price
	if type(price) ~= "number" or price ~= price or price < 0 or price == math.huge then
		return nil
	end
	local asset = trailAssets and trailAssets:FindFirstChild(trailId)
	if not (asset and asset:IsA("BasePart")) then
		return nil
	end
	return config
end

local function loadedProfile(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") or not Database.IsPlayerLoaded(player) then
		return nil
	end
	return Database.Get(player)
end

local function inventoryOf(profile)
	return if type(profile.TrailInventory) == "table" then profile.TrailInventory else {}
end

local function activeTrailOf(player)
	local profile = loadedProfile(player)
	if not profile then
		return nil
	end
	local equipped = profile.EquippedTrail
	if type(equipped) ~= "string" or equipped == NONE or inventoryOf(profile)[equipped] ~= true then
		return nil
	end
	return if getConfig(equipped) then equipped else nil
end

-- Themed FX on the character (see the header). fxState[player] = { character, trailId, instances, died }.
local FX_ATTRIBUTE = "TrailFx"
local FX_ROOT = "HumanoidRootPart"
local fxTemplates = nil
do
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	fxTemplates = assets and assets:WaitForChild("TrailFx", 10)
	if not fxTemplates then
		warn("[TrailService] ReplicatedStorage.Assets.TrailFx missing, trails show without their themed FX")
	end
end

local fxState = {}

local function clearFx(player)
	local state = fxState[player]
	if not state then
		return
	end
	fxState[player] = nil
	if state.died then
		state.died:Disconnect()
	end
	for _, inst in ipairs(state.instances) do
		pcall(inst.Destroy, inst)
	end
end

-- Clones the template and parents each Attachment to its character part (HumanoidRootPart unless the attachment's
-- TrailFxMount names another part; TrailFxAbove lifts it above that part's top). Attachments whose part is missing
-- are dropped. Returns the mounted attachments.
local function mountFx(template, character, trailId)
	local root = character:FindFirstChild(FX_ROOT)
	if not (root and root:IsA("BasePart")) then
		return {}
	end
	local clone = template:Clone()
	local mounted = {}
	for _, child in ipairs(clone:GetChildren()) do
		if child:IsA("Attachment") then
			local mountName = child:GetAttribute("TrailFxMount")
			local part = root
			if type(mountName) == "string" then
				local other = character:FindFirstChild(mountName)
				part = if other and other:IsA("BasePart") then other else nil
			end
			if part then
				local above = child:GetAttribute("TrailFxAbove")
				if type(above) == "number" then
					local frame = child.CFrame
					child.CFrame = frame + Vector3.new(0, part.Size.Y / 2 + above - frame.Position.Y, 0)
				end
				child:SetAttribute(FX_ATTRIBUTE, trailId)
				child.Parent = part
				table.insert(mounted, child)
			end
		end
	end
	clone:Destroy()
	return mounted
end

-- Makes the character show exactly the FX of the player's active trail (idempotent; cheap when nothing changed).
local function refreshFx(player)
	if fxTemplates == nil or player.Parent ~= Players then
		clearFx(player)
		return
	end
	local active = activeTrailOf(player)
	local template = active and fxTemplates:FindFirstChild(active)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild(FX_ROOT)
	local alive = humanoid == nil or humanoid.Health > 0
	if not (template and root and alive) then
		clearFx(player)
		return
	end
	local state = fxState[player]
	if state and state.character == character and state.trailId == active and #state.instances > 0
		and state.instances[1].Parent ~= nil then
		return
	end
	clearFx(player)
	local instances = mountFx(template, character, active)
	fxState[player] = {
		character = character,
		trailId = active,
		instances = instances,
		died = humanoid and humanoid.Died:Connect(function()
			clearFx(player)
		end),
	}
end

local function safeRefreshFx(player)
	local ok, err = pcall(refreshFx, player)
	if not ok then
		warn("[TrailService] trail FX refresh failed for " .. tostring(player) .. ": " .. tostring(err))
	end
end

-- Tells every client which trail a player shows (only when it changed since the last broadcast).
local activeEvent = Network:FindFirstChild(EVENT_ACTIVE) or Network:WaitForChild(EVENT_ACTIVE, 10)
if not (activeEvent and activeEvent:IsA("RemoteEvent")) then
	activeEvent = Instance.new("RemoteEvent")
	activeEvent.Name = EVENT_ACTIVE
	activeEvent.Parent = Network
end

local lastBroadcast = {}
local function broadcast(player)
	if not player or player.Parent ~= Players then
		return
	end
	safeRefreshFx(player)
	local active = activeTrailOf(player)
	local key = active or NONE
	if lastBroadcast[player] == key then
		return
	end
	lastBroadcast[player] = key
	activeEvent:FireAllClients(player, active)
end

-- Adds the trail to the inventory (and equips it). Used by the Money purchase and by GrantOwnedTrail.
local function grantOwnedTrail(player, trailId, equip, extraChanges)
	local profile = loadedProfile(player)
	if not profile or not getConfig(trailId) then
		return false
	end
	local inventory = table.clone(inventoryOf(profile))
	inventory[trailId] = true
	local changes = extraChanges or {}
	changes.TrailInventory = inventory
	if equip ~= false then
		changes.EquippedTrail = trailId
	end
	Database.Set(player, changes)
	broadcast(player)
	return true
end

local lastRequest = {}
local function throttled(player)
	local now = os.clock()
	local last = lastRequest[player]
	if last and now - last < REQUEST_COOLDOWN then
		return true
	end
	lastRequest[player] = now
	return false
end

local function handlePurchase(player, trailId)
	if throttled(player) then
		return false, "Please wait a moment"
	end
	local config = getConfig(trailId)
	if not config then
		return false, "This trail is not for sale"
	end
	local profile = loadedProfile(player)
	if not profile then
		return false, "Your data is still loading"
	end
	if inventoryOf(profile)[trailId] == true then
		return false, "You already own this trail"
	end
	local money = tonumber(profile.Money) or 0
	if money ~= money or money < config.Price then
		return false, "Not enough money"
	end
	if not grantOwnedTrail(player, trailId, true, { Money = money - config.Price }) then
		return false, "Trail purchase failed"
	end
	print(string.format("[TrailService] %s bought %s for %s", player.Name, trailId, tostring(config.Price)))
	return true
end

local function handleSelect(player, trailId)
	if throttled(player) then
		return false, "Please wait a moment"
	end
	if not getConfig(trailId) then
		return false, "Unknown trail"
	end
	local profile = loadedProfile(player)
	if not profile then
		return false, "Your data is still loading"
	end
	if inventoryOf(profile)[trailId] ~= true then
		return false, "You do not own this trail"
	end
	if profile.EquippedTrail ~= trailId then
		Database.Set(player, { EquippedTrail = trailId })
	end
	broadcast(player)
	return true
end

local function handleUnequip(player)
	if throttled(player) then
		return false, "Please wait a moment"
	end
	local profile = loadedProfile(player)
	if not profile then
		return false, "Your data is still loading"
	end
	if profile.EquippedTrail ~= NONE then
		Database.Set(player, { EquippedTrail = NONE })
	end
	broadcast(player)
	return true
end

-- String keys: a remote turns a sparse numeric-keyed table into string keys anyway; TrailController tonumber()s them.
local function handleSnapshot(_player)
	local snapshot = {}
	for _, other in ipairs(Players:GetPlayers()) do
		local active = activeTrailOf(other)
		if active then
			snapshot[tostring(other.UserId)] = active
		end
	end
	return snapshot
end

local function bind(name, handler, fallback)
	local remote = Network:FindFirstChild(name) or Network:WaitForChild(name, 10)
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = Network
	end
	if not remote:IsA("RemoteFunction") then
		warn("[TrailService] " .. name .. " is not a RemoteFunction")
		return
	end
	remote.OnServerInvoke = function(player, ...)
		local ok, a, b = pcall(handler, player, ...)
		if not ok then
			warn("[TrailService] " .. name .. " failed: " .. tostring(a))
			return fallback()
		end
		return a, b
	end
end

local function failed()
	return false, "Trail request failed"
end

bind(REMOTE_PURCHASE, handlePurchase, failed)
bind(REMOTE_SELECT, handleSelect, failed)
bind(REMOTE_UNEQUIP, handleUnequip, failed)
bind(REMOTE_SNAPSHOT, handleSnapshot, function()
	return {}
end)

-- Any other writer of these fields (admin tools, a future Robux grant) also updates every client's render.
Database.OnFieldChanged("EquippedTrail", function(player)
	broadcast(player)
end)
Database.OnFieldChanged("TrailInventory", function(player)
	broadcast(player)
end)
Database.OnLoaded(function(player)
	broadcast(player)
end)

-- Themed FX follow the character: mounted on each spawn (once the HumanoidRootPart exists), dropped when it goes.
local characterConnections = {}
local function bindCharacters(player)
	if characterConnections[player] then
		return
	end
	local function onCharacter(character)
		if not character:FindFirstChild(FX_ROOT) then
			character:WaitForChild(FX_ROOT, 10)
		end
		if player.Character == character then
			safeRefreshFx(player)
		end
	end
	characterConnections[player] = {
		player.CharacterAdded:Connect(onCharacter),
		player.CharacterRemoving:Connect(function()
			clearFx(player)
		end),
	}
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(bindCharacters)
for _, player in ipairs(Players:GetPlayers()) do
	bindCharacters(player)
end

Players.PlayerRemoving:Connect(function(player)
	lastBroadcast[player] = nil
	lastRequest[player] = nil
	clearFx(player)
	for _, connection in ipairs(characterConnections[player] or {}) do
		connection:Disconnect()
	end
	characterConnections[player] = nil
end)

-- Server-only hook for a future ProcessReceipt branch: GrantOwnedTrail:Invoke(player, trailId) -> boolean
local grantHook = script:FindFirstChild("GrantOwnedTrail") or Instance.new("BindableFunction")
grantHook.Name = "GrantOwnedTrail"
grantHook.OnInvoke = function(player, trailId)
	local ok, granted = pcall(grantOwnedTrail, player, trailId, true)
	return ok and granted == true
end
grantHook.Parent = script

print("[TrailService] Trails shop online (Money purchases, equip/unequip, character trails)")
