-- ServerScriptService.BranchServices.HeroAdminService (Branch service; injected by scripts/inject/admin_panel.luau,
-- started by ServerScriptService.BranchServer)
-- Owner 2026-09-27: "an admin panel for the devs so we can test things like give all stuff". The server half of the
-- Hero admin panel (the window is ServerStorage.HeroAdminPanel, built by scripts/steps/ui_85_admin_panel.luau; its
-- LocalScript HeroAdminClient wires the buttons):
--   * who: ServerScriptService.HeroAdminAccess (UserId 767108248, the game's owner, anyone in Studio). An admin gets the
--     Player attribute HeroAdmin = true and a copy of the panel in their PlayerGui (ResetOnSpawn off); nobody else ever
--     receives the window or its script.
--   * how: one RemoteFunction ReplicatedStorage.Network["Admin: Command"](command, targetUserId?, args?) ->
--     (ok, message, summary). Every call is rate limited (RATE_PER_SECOND per player), re-checked against
--     HeroAdminAccess (a non-admin is refused and warned), every argument is type / range checked, and the call is
--     logged as "[HeroAdmin] <caller> <command> -> <target>". targetUserId picks a player in this server (nil = the
--     caller); summary is the target's { Money, SpeedPower, Rebirth, Eggs, Heroes, Plot } after the command.
-- Commands (COMMANDS below; the panel's buttons carry the name in their Command attribute, args in Arg* attributes):
--   GiveAllWeapons / GiveWeapon{Tool}   the 7 hero weapon Tools of GearTools.ShopItems into the target's Backpack
--                                       (skipped when already held), GearName "Dev <tool>" so the hotbar puts them in
--                                       slots 3-8; GearService hooks any melee Tool that lands in a Backpack. A respawn
--                                       re-deals the normal kit (the dev copies are gone then).
--   RemoveDevWeapons                    destroys the target's Tools whose GearName starts with "Dev ".
--   UnlockIndexWeapons                  completes every stage's Index (Directory.Areas DropTable, the stages of
--                                       Directory.StageArt) so the Index EQUIP buttons of the stage weapons show; the
--                                       same data as GearService's Studio DevCompleteIndex hook (re-implemented here).
--   GiveMoney / TakeMoney{Amount}       profile Money (Database.SetAndBroadcast, like CmdrAdminHandler); Amount is the
--                                       text typed in the panel ("10m", "2.5B", "1e12"), parsed here (ParseAmount);
--                                       taking more than they have leaves 0. ResetMoney: 0.
--   GiveSpeed / TakeSpeed{Amount}       profile SpeedPower (clamped to [10, MAX_SPEED_POWER]) + SpeedService.Refresh;
--   SetSpeed{Value}                     MAX / RESET.
--   GiveEgg{Stage, Pick}                an egg of a stage's DropTable ("Random" = weighted roll, "Rarest" = the highest
--                                       rarity) through EggService.GrantEgg + GrantEggTool (in hand).
--   GrowEggs                            every placed egg of the target ready to hatch (Placement.ReadyAt).
--   Teleport{Place}                     the CALLER to "Lobby", "Plot" (their own base) or a stage key.
--   NightNow / DayNow / NormalCycle     the egg night cycle (Library.Util.AreaEggResetTimeUtil schedule attributes on
--                                       Workspace): start a night now; end the night (or restart the day); back to the
--                                       server clock.
--   UnlockBaseThemes                    every Directory.BaseThemes entry unlocked (IndexService's Studio hook, live).
--   TacoRainStart{Duration, Scope} / TacoRainStop{Scope}   the Taco Rain event (BranchServices.TacoRainService: tacos
--                                       falling on eggs give them the x3 "Taco" mutation). Scope "Server" (default) =
--                                       this server; "All" = this server at once, then every other server through
--                                       BranchServices.HeroBroadcastService (MessagingService topic "HeroAdmin_Global";
--                                       the handler registered at Start runs it there). An all-server send inside the
--                                       admin's cooldown is refused before anything runs; when MessagingService fails
--                                       the action stays on this server and the answer says so (kind "warn").
--   Announce{Text, Scope}               a filtered announcement banner on every screen of this server / of every server
--                                       (HeroBroadcastService.Announce: TextService filter first, rate limited).
--   WipeData{ConfirmUserId}             resets the target's saved profile to a brand new player's
--                                       (Library.Database.WipeProfile: saved at once, every later save of that session
--                                       writes the fresh payload), kicks them with WIPE_KICK_MESSAGE after
--                                       WIPE_KICK_DELAY s and, once they are gone, removes them from the leaderboard
--                                       OrderedDataStores (LEADERBOARD_STORES). The panel's second tap sends
--                                       ConfirmUserId = the target's UserId; anything else is refused. One wipe per
--                                       WIPE_COOLDOWN s per admin, logged as "[HeroAdmin] WIPE ...".
--   Release / Respawn / Heal            ServerScriptService.GearReleaseRequest (ragdoll / trap / weapon state), a fresh
--                                       character, full health.
--   GoTo / Bring                        the caller to the target / the target to the caller.
--   SpawnDummy / ClearDummies           R15 "TrainingDummy" models in Workspace.HeroWeaponDummies (tag HeroWeaponDummy,
--                                       attribute DummyOwner, at most MAX_DUMMIES), standing, server-owned physics.
--   Inspect                             only the summary (the panel's target card).
-- A handler returns (ok, message[, "warn"]); the remote answers (ok, message, summary, kind) - kind "warn" = done, but
-- only partly (e.g. an all-server action that stayed on this server).
-- The older admin systems of the place (AdminStatusHandler, CmdrAdminHandler, TrollFreeAdmin...) are not touched.

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local HeroAdminService = {}

HeroAdminService.REMOTE_NAME = "Admin: Command"
HeroAdminService.PANEL_NAME = "HeroAdminPanel"
HeroAdminService.RATE_PER_SECOND = 8 -- commands per second per player (token bucket, burst of the same size)
HeroAdminService.MAX_COMMAND_LENGTH = 32
HeroAdminService.MAX_ARG_KEYS = 8
HeroAdminService.MAX_ARG_STRING = 48
HeroAdminService.MAX_SPEED_POWER = 5e11 -- walk speed is capped at 300 well before this (TreadmillUtil)
HeroAdminService.MIN_SPEED_POWER = 10 -- TreadmillUtil.DEFAULT_BASE_SPEED_POWER
HeroAdminService.DEV_PREFIX = "Dev "
HeroAdminService.WEAPON_TOOLS = { "Bat", "Forest Bat", "Desert Bat", "Lake Bat", "Jungle Bat", "Snow Bat", "Volcano Bat" }
HeroAdminService.MAX_DUMMIES = 4
HeroAdminService.DUMMY_FOLDER = "HeroWeaponDummies"
HeroAdminService.DUMMY_TAG = "HeroWeaponDummy"
HeroAdminService.DUMMY_NAME = "TrainingDummy"
HeroAdminService.DUMMY_DISTANCE = 8
HeroAdminService.STAGE_INSET = 14 -- studs past a stage's entrance (its ClosestExitPoint) a stage teleport lands
HeroAdminService.REFUSAL_WARN_EVERY = 10 -- s between two "refused" warnings for the same player
HeroAdminService.LONG_ARGS = { Text = 600 } -- string args allowed past MAX_ARG_STRING (bytes): the announcement text
HeroAdminService.SCOPES = { Server = true, All = true }
HeroAdminService.WIPE_COOLDOWN = 15 -- s between two wipes of the same admin
HeroAdminService.WIPE_KICK_DELAY = 2 -- s: the answer reaches the panel first (a self-wipe reads its toast)
HeroAdminService.WIPE_KICK_MESSAGE = "Your data was reset by an admin. Rejoin to start from zero."
-- the per-player entries a wipe removes once the player is gone (their own services write them again from the fresh
-- profile): ServerScriptService.LeaderboardService's "Leaderboard_<stat>_v1" stores (the HERO BOARD pages; Money is the
-- old page name) and FlappyService's "FlappyBest_v1" (it only ever raises a best, so it would never go back to 0)
HeroAdminService.LEADERBOARD_STORES = {
	"Leaderboard_Networth_v1", "Leaderboard_SpeedPower_v1", "Leaderboard_TimePlayed_v1", "Leaderboard_EggsHatched_v1",
	"Leaderboard_Money_v1", "FlappyBest_v1",
}
HeroAdminService.LEADERBOARD_CLEAR_DELAY = 8 -- s after the kick (the leave saves / the Flappy flush land first)

local Access = require(ServerScriptService:WaitForChild("HeroAdminAccess", 10))

local remote = nil
local buckets = {} -- [Player] = { tokens = n, at = os.clock() }
local lastRefusalWarn = {} -- [Player] = os.clock()
local lastWipe = {} -- [Player] = os.clock() of their last wipe

----------------------------------------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------------------------------------

local cachedModules = {}
-- require(module) once, pcall'd; nil (and one warn) when it cannot load.
local function lazyRequire(key, locate)
	local cached = cachedModules[key]
	if cached ~= nil then
		return cached or nil
	end
	local module = locate()
	local ok, result = false, "not found"
	if module and module:IsA("ModuleScript") then
		ok, result = pcall(require, module)
	end
	if ok and type(result) == "table" then
		cachedModules[key] = result
		return result
	end
	cachedModules[key] = false
	warn("[HeroAdmin] " .. key .. " unavailable: " .. tostring(result))
	return nil
end

local function database()
	return lazyRequire("Database", function()
		local library = ServerScriptService:FindFirstChild("Library")
		return library and library:FindFirstChild("Database")
	end)
end

local function controller(name)
	return lazyRequire(name, function()
		local controllers = ServerScriptService:FindFirstChild("Controllers")
		return controllers and controllers:FindFirstChild(name)
	end)
end

local function directory(name)
	return lazyRequire("Directory." .. name, function()
		local dir = ReplicatedStorage:FindFirstChild("Directory")
		return dir and dir:FindFirstChild(name)
	end)
end

-- Directory.Areas / Directory.Assets keep their data in .Directory (strict tables: an unknown key errors).
local function directoryTable(name)
	local module = directory(name)
	return if module and type(module.Directory) == "table" then module.Directory else nil
end

local function entryOf(dirTable, key)
	if dirTable == nil or type(key) ~= "string" then
		return nil
	end
	local ok, entry = pcall(function()
		return dirTable[key]
	end)
	return if ok and type(entry) == "table" then entry else nil
end

local function nightUtil()
	return lazyRequire("AreaEggResetTimeUtil", function()
		local library = ReplicatedStorage:FindFirstChild("Library")
		local util = library and library:FindFirstChild("Util")
		return util and util:FindFirstChild("AreaEggResetTimeUtil")
	end)
end

-- The loaded profile of `player`, or nil (never read or write a profile that is still loading).
local function profileOf(player)
	local db = database()
	if db == nil then
		return nil, nil
	end
	local ok, profile = pcall(db.Get, player)
	if not ok or type(profile) ~= "table" then
		return nil, db
	end
	if type(db.IsPlayerLoaded) == "function" and db.IsPlayerLoaded(player) ~= true then
		return nil, db
	end
	return profile, db
end

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx" }
local function compact(n)
	n = tonumber(n) or 0
	local sign = if n < 0 then "-" else ""
	n = math.abs(n)
	if n < 1000 then
		if n % 1 == 0 then
			return sign .. tostring(math.floor(n))
		end
		return sign .. (string.gsub(string.gsub(string.format("%.2f", n), "0+$", ""), "%.$", ""))
	end
	local magnitude = 0
	while n >= 1000 and magnitude < #SUFFIXES do
		n /= 1000
		magnitude += 1
	end
	local text = if n >= 100 then string.format("%d", math.floor(n)) else string.format("%.3g", n)
	return sign .. text .. SUFFIXES[magnitude]
end
HeroAdminService.Compact = compact

local function finiteNumber(value, min, max)
	return type(value) == "number" and value == value and value >= min and value <= max
end

-- The amount typed in a text box -> amount (a positive number, cents at most) | nil, reason. Suffixes K M B T Qa Qi in any
-- case ("10m" = "10M" = 10,000,000; "2.5b" = 2.5e9), exponents ("1e12"), thousands separators ("1,000,000"), a leading
-- "+". Negative, NaN, infinite, zero and anything over MAX_INPUT_AMOUNT are refused. A plain number is checked the same.
HeroAdminService.MAX_INPUT_AMOUNT = 1e15
HeroAdminService.AMOUNT_SUFFIXES = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, qi = 1e18 }
function HeroAdminService.ParseAmount(value)
	local number = nil
	if type(value) == "number" then
		number = value
	elseif type(value) == "string" then
		if #value == 0 or #value > 32 then
			return nil, "Type an amount first (e.g. 10M)"
		end
		local text = string.lower((string.gsub(value, "[%s,_]", "")))
		if string.sub(text, 1, 1) == "+" then
			text = string.sub(text, 2)
		end
		local digits, exponent, suffix = string.match(text, "^(%d*%.?%d+)(e?[%+%-]?%d*)(%a*)$")
		if digits == nil or (exponent ~= "" and not string.match(exponent, "^e[%+%-]?%d+$")) then
			return nil, "Not an amount: " .. value .. " (use 500, 25K, 10M, 2.5B, 1e12)"
		end
		local multiplier = if suffix == "" then 1 else HeroAdminService.AMOUNT_SUFFIXES[suffix]
		if multiplier == nil then
			return nil, "Unknown suffix '" .. suffix .. "' (K, M, B, T, Qa, Qi)"
		end
		local base = tonumber(digits .. exponent)
		number = if base then base * multiplier else nil
	else
		return nil, "Type an amount first (e.g. 10M)"
	end
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return nil, "Not a valid amount"
	end
	if number > HeroAdminService.MAX_INPUT_AMOUNT then
		return nil, "Too big: the most is " .. compact(HeroAdminService.MAX_INPUT_AMOUNT)
	end
	number = math.floor(number * 100 + 0.5) / 100
	if number <= 0 then
		return nil, "The amount must be more than 0"
	end
	return number
end

local function isStageKey(key)
	if type(key) ~= "string" or #key == 0 or #key > HeroAdminService.MAX_ARG_STRING then
		return false
	end
	local areas = Workspace:FindFirstChild("__OBJECTS")
	areas = areas and areas:FindFirstChild("Areas")
	local guardAreas = areas and areas:FindFirstChild("GuardAreas")
	local stage = guardAreas and guardAreas:FindFirstChild(key)
	return stage ~= nil and stage:GetAttribute("StageNumber") ~= nil
end

local function stageName(key)
	local stageArt = directory("StageArt")
	local ok, stage = pcall(function()
		return stageArt and stageArt.Get(key)
	end)
	if ok and type(stage) == "table" and type(stage.Name) == "string" then
		return stage.Name
	end
	return key
end

-- The stage keys the Index lists (Directory.StageArt.Order), else every stage zone of the world.
local function stageKeys()
	local stageArt = directory("StageArt")
	if stageArt and type(stageArt.Order) == "table" and #stageArt.Order > 0 then
		return stageArt.Order
	end
	local keys = {}
	local objects = Workspace:FindFirstChild("__OBJECTS")
	local areas = objects and objects:FindFirstChild("Areas")
	local guardAreas = areas and areas:FindFirstChild("GuardAreas")
	for _, stage in ipairs(guardAreas and guardAreas:GetChildren() or {}) do
		if stage:GetAttribute("StageNumber") ~= nil then
			table.insert(keys, stage.Name)
		end
	end
	return keys
end

local function characterOf(player)
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return character, root, humanoid
	end
	return nil, nil, nil
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function rayExclusions()
	local list = {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Character then
			table.insert(list, other.Character)
		end
	end
	local dummies = Workspace:FindFirstChild(HeroAdminService.DUMMY_FOLDER)
	if dummies then
		table.insert(list, dummies)
	end
	return list
end

-- yaw that makes a CFrame look along the flat direction `direction`
local function yawAlong(direction)
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 1e-3 then
		return 0
	end
	flat = flat.Unit
	return math.atan2(-flat.X, -flat.Z)
end

-- Root CFrame standing on the floor under `position` (a first probe from just above, so a stage prop overhead is not
-- taken as the floor; then one from high up), facing `yaw`.
local function standingCFrame(position, yaw, rootSize, hipHeight)
	rayParams.FilterDescendantsInstances = rayExclusions()
	local hit = Workspace:Raycast(position + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), rayParams)
		or Workspace:Raycast(position + Vector3.new(0, 60, 0), Vector3.new(0, -140, 0), rayParams)
	local y = if hit then hit.Position.Y + hipHeight + rootSize.Y / 2 + 0.25 else position.Y + 4
	return CFrame.new(position.X, y, position.Z) * CFrame.Angles(0, yaw, 0)
end

local function legsOf(humanoid)
	return if humanoid.RigType == Enum.HumanoidRigType.R15 then math.max(humanoid.HipHeight, 0.5) else 2
end

local function moveCharacter(player, position, yaw)
	local character, root, humanoid = characterOf(player)
	if not character then
		return false
	end
	if humanoid.Sit then
		humanoid.Sit = false
	end
	character:PivotTo(standingCFrame(position, yaw, root.Size, legsOf(humanoid)))
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
	return true
end

local function shopItems()
	local gearTools = ReplicatedStorage:FindFirstChild("GearTools")
	return gearTools and gearTools:FindFirstChild("ShopItems")
end

local function isWeaponTool(name)
	return table.find(HeroAdminService.WEAPON_TOOLS, name) ~= nil
end

local function holdsTool(player, toolName)
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child.Name == toolName then
					return true
				end
			end
		end
	end
	return false
end

-- "given" | "held" | "missing" | "nobackpack"
local function giveWeapon(player, toolName)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack == nil then
		return "nobackpack"
	end
	local items = shopItems()
	local template = items and items:FindFirstChild(toolName)
	if not (template and template:IsA("Tool")) then
		return "missing"
	end
	if holdsTool(player, toolName) then
		return "held"
	end
	local tool = template:Clone() -- the whole subtree in one Clone
	tool:SetAttribute("ItemType", "Gear")
	tool:SetAttribute("GearName", HeroAdminService.DEV_PREFIX .. toolName)
	tool:SetAttribute("HeroAdminDev", true)
	tool.CanBeDropped = false
	for _, descendant in ipairs(tool:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
		end
	end
	tool.Parent = backpack
	return "given"
end

local function weaponLabel(toolName)
	local heroWeapons = lazyRequire("HeroWeapons", function()
		local library = ReplicatedStorage:FindFirstChild("Library")
		local modules = library and library:FindFirstChild("Modules")
		return modules and modules:FindFirstChild("HeroWeapons")
	end)
	local ok, name = pcall(function()
		local id = heroWeapons.BY_TOOL[toolName]
		return heroWeapons.WEAPONS[id].DisplayName
	end)
	return if ok and type(name) == "string" then name else toolName
end

local function summaryOf(player)
	local profile = profileOf(player)
	local summary = { Name = player.Name, UserId = player.UserId }
	if profile then
		summary.Money = tonumber(profile.Money) or 0
		summary.SpeedPower = tonumber(profile.SpeedPower) or 0
		summary.Rebirth = tonumber(profile.Rebirth) or 0
		local eggs, heroes = 0, 0
		for _ in pairs(type(profile.EggInventory) == "table" and profile.EggInventory or {}) do
			eggs += 1
		end
		for _ in pairs(type(profile.Inventory) == "table" and profile.Inventory or {}) do
			heroes += 1
		end
		summary.Eggs, summary.Heroes = eggs, heroes
	end
	local plots = controller("PlotService")
	if plots and type(plots.GetPlotId) == "function" then
		local ok, plotId = pcall(plots.GetPlotId, player)
		if ok and plotId ~= nil then
			summary.Plot = tostring(plotId)
		end
	end
	return summary
end

----------------------------------------------------------------------------------------------------
-- training dummies
----------------------------------------------------------------------------------------------------

local DUMMY_COLORS = {
	HeadColor = Color3.fromRGB(226, 190, 128), -- burlap
	TorsoColor = Color3.fromRGB(196, 46, 36), -- red practice vest
	LeftArmColor = Color3.fromRGB(226, 190, 128),
	RightArmColor = Color3.fromRGB(226, 190, 128),
	LeftLegColor = Color3.fromRGB(78, 64, 54),
	RightLegColor = Color3.fromRGB(78, 64, 54),
}

local function dummyFolder()
	local folder = Workspace:FindFirstChild(HeroAdminService.DUMMY_FOLDER)
	if folder and not folder:IsA("Folder") then
		folder = nil
	end
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = HeroAdminService.DUMMY_FOLDER
		folder.Parent = Workspace
	end
	return folder
end

local function dummies()
	local list = {}
	local folder = Workspace:FindFirstChild(HeroAdminService.DUMMY_FOLDER)
	for _, child in ipairs(folder and folder:GetChildren() or {}) do
		if child:IsA("Model") and CollectionService:HasTag(child, HeroAdminService.DUMMY_TAG) then
			table.insert(list, child)
		end
	end
	return list
end
HeroAdminService.GetDummies = dummies

local function dummyTag(head)
	local tag = Instance.new("BillboardGui")
	tag.Name = "DummyTag"
	tag.Size = UDim2.fromScale(4.2, 0.9)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 2.1, 0)
	tag.MaxDistance = 90
	tag.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(21, 19, 42)
	label.BackgroundTransparency = 0.1
	label.BorderSizePixel = 0
	label.Text = "Training Dummy"
	label.TextColor3 = Color3.fromRGB(255, 214, 90)
	label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = tag
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(11, 27, 61)
	stroke.Thickness = 2
	stroke.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.12, 0)
	padding.PaddingBottom = UDim.new(0.12, 0)
	padding.Parent = label
	tag.Adornee = head
	tag.Parent = head
	return tag
end

local function spawnDummy(caller)
	local _, callerRoot = characterOf(caller)
	if callerRoot == nil then
		return false, "You need a character to place a dummy in front of"
	end
	if #dummies() >= HeroAdminService.MAX_DUMMIES then
		return false, string.format("Already %d dummies: clear them first", HeroAdminService.MAX_DUMMIES)
	end
	local description = Instance.new("HumanoidDescription")
	for property, color in pairs(DUMMY_COLORS) do
		description[property] = color
	end
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	description:Destroy()
	if not ok or typeof(model) ~= "Instance" then
		return false, "Could not build the dummy: " .. tostring(model)
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and root:IsA("BasePart")) then
		model:Destroy()
		return false, "Could not build the dummy (no Humanoid)"
	end
	model.Name = HeroAdminService.DUMMY_NAME
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	local look = callerRoot.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	look = if look.Magnitude > 1e-3 then look.Unit else Vector3.new(0, 0, -1)
	local spot = callerRoot.Position + look * HeroAdminService.DUMMY_DISTANCE
	model:PivotTo(standingCFrame(spot, yawAlong(-look), root.Size, legsOf(humanoid)))
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part.CollisionGroup = "Players" -- collides like a player (Bootstrap's groups)
			end)
		end
	end
	CollectionService:AddTag(model, HeroAdminService.DUMMY_TAG)
	model:SetAttribute("DummyOwner", caller.UserId)
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		dummyTag(head)
	end
	humanoid.Died:Connect(function()
		task.delay(4, function()
			if model.Parent then
				model:Destroy()
			end
		end)
	end)
	model.Parent = dummyFolder()
	pcall(root.SetNetworkOwner, root, nil) -- server physics: nobody's client can shove it around
	return true, string.format("Training dummy placed (%d / %d)", #dummies(), HeroAdminService.MAX_DUMMIES)
end

----------------------------------------------------------------------------------------------------
-- commands: handler(ctx) -> (ok, message); ctx = { Caller, Target, Args }
----------------------------------------------------------------------------------------------------

local COMMANDS = {}
HeroAdminService.COMMANDS = COMMANDS

COMMANDS.Inspect = function(ctx)
	return true, ctx.Target.Name
end

-- Weapons -----------------------------------------------------------------------------------------

COMMANDS.GiveAllWeapons = function(ctx)
	local given, held, missing = 0, 0, 0
	for _, toolName in ipairs(HeroAdminService.WEAPON_TOOLS) do
		local result = giveWeapon(ctx.Target, toolName)
		if result == "nobackpack" then
			return false, ctx.Target.Name .. " has no Backpack right now (respawning?)"
		elseif result == "given" then
			given += 1
		elseif result == "held" then
			held += 1
		else
			missing += 1
		end
	end
	local message = string.format("%d hero weapons given to %s", given, ctx.Target.Name)
	if held > 0 then
		message ..= string.format(", %d already held", held)
	end
	if missing > 0 then
		message ..= string.format(", %d missing from GearTools", missing)
	end
	return given > 0 or held > 0, message
end

COMMANDS.GiveWeapon = function(ctx)
	local toolName = ctx.Args.Tool
	if type(toolName) ~= "string" or not isWeaponTool(toolName) then
		return false, "Unknown weapon"
	end
	local result = giveWeapon(ctx.Target, toolName)
	local label = weaponLabel(toolName)
	if result == "given" then
		return true, string.format("%s given to %s", label, ctx.Target.Name)
	elseif result == "held" then
		return true, string.format("%s already holds the %s", ctx.Target.Name, label)
	elseif result == "nobackpack" then
		return false, ctx.Target.Name .. " has no Backpack right now (respawning?)"
	end
	return false, label .. " is missing from GearTools.ShopItems"
end

COMMANDS.RemoveDevWeapons = function(ctx)
	local removed = 0
	local target = ctx.Target
	for _, container in ipairs({ target:FindFirstChildOfClass("Backpack"), target.Character, target:FindFirstChildOfClass("StarterGear") }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				local gearName = child:IsA("Tool") and child:GetAttribute("GearName")
				if type(gearName) == "string" and string.sub(gearName, 1, #HeroAdminService.DEV_PREFIX) == HeroAdminService.DEV_PREFIX then
					child:Destroy()
					removed += 1
				end
			end
		end
	end
	return true, string.format("%d dev weapons removed from %s", removed, target.Name)
end

COMMANDS.UnlockIndexWeapons = function(ctx)
	local profile, db = profileOf(ctx.Target)
	if profile == nil then
		return false, ctx.Target.Name .. "'s profile is not loaded yet"
	end
	local areas = directoryTable("Areas")
	if areas == nil then
		return false, "Directory.Areas unavailable"
	end
	local index = if type(profile.Index) == "table" then profile.Index else {}
	local stages, discovered = 0, 0
	for _, key in ipairs(stageKeys()) do
		local area = entryOf(areas, key)
		if area and type(area.DropTable) == "table" then
			stages += 1
			for _, entry in ipairs(area.DropTable) do
				if type(entry) == "table" and type(entry[1]) == "string" and index[entry[1]] ~= true then
					index[entry[1]] = true
					discovered += 1
				end
			end
		end
	end
	if stages == 0 then
		return false, "No stage Index found"
	end
	db.Set(ctx.Target, { Index = index }) -- IndexService unlocks the base themes of the completed stages
	return true, string.format("Index of %d stages complete for %s (+%d heroes): every EQUIP button is live", stages,
		ctx.Target.Name, discovered)
end

COMMANDS.SpawnDummy = function(ctx)
	return spawnDummy(ctx.Caller)
end

COMMANDS.ClearDummies = function(_ctx)
	local list = dummies()
	for _, model in ipairs(list) do
		model:Destroy()
	end
	return true, string.format("%d training dummies cleared", #list)
end

-- Economy -----------------------------------------------------------------------------------------

-- Money / speed amounts come from the panel's text boxes as typed ("10m", "2.5B", "1e12", "1,000,000"): parsed here,
-- never trusted as a number from the client (ParseAmount).
local function amountArg(ctx)
	local amount, reason = HeroAdminService.ParseAmount(ctx.Args.Amount)
	if amount == nil then
		return nil, reason
	end
	return amount
end

local function changeMoney(ctx, sign)
	local amount, reason = amountArg(ctx)
	if amount == nil then
		return false, reason
	end
	local profile, db = profileOf(ctx.Target)
	if profile == nil then
		return false, ctx.Target.Name .. "'s profile is not loaded yet"
	end
	local before = tonumber(profile.Money) or 0
	local total = math.max(0, before + sign * amount) -- taking more than they have leaves 0
	db.SetAndBroadcast(ctx.Target, { Money = total })
	if sign > 0 then
		return true, string.format("+%s money to %s (now %s)", compact(amount), ctx.Target.Name, compact(total))
	end
	return true, string.format("-%s money from %s (now %s)", compact(math.min(amount, before)), ctx.Target.Name, compact(total))
end

COMMANDS.GiveMoney = function(ctx)
	return changeMoney(ctx, 1)
end

COMMANDS.TakeMoney = function(ctx)
	return changeMoney(ctx, -1)
end

COMMANDS.ResetMoney = function(ctx)
	local profile, db = profileOf(ctx.Target)
	if profile == nil then
		return false, ctx.Target.Name .. "'s profile is not loaded yet"
	end
	db.SetAndBroadcast(ctx.Target, { Money = 0 })
	return true, ctx.Target.Name .. "'s money reset to 0"
end

local function applySpeedPower(target, value)
	local profile, db = profileOf(target)
	if profile == nil then
		return nil
	end
	value = math.clamp(math.floor(value), HeroAdminService.MIN_SPEED_POWER, HeroAdminService.MAX_SPEED_POWER)
	db.SetAndBroadcast(target, { SpeedPower = value })
	local speed = controller("SpeedService")
	if speed and type(speed.Refresh) == "function" then
		local ok, err = pcall(speed.Refresh, target)
		if not ok then
			warn("[HeroAdmin] SpeedService.Refresh failed: " .. tostring(err))
		end
	end
	return value
end

local function changeSpeed(ctx, sign)
	local amount, reason = amountArg(ctx)
	if amount == nil then
		return false, reason
	end
	local profile = profileOf(ctx.Target)
	if profile == nil then
		return false, ctx.Target.Name .. "'s profile is not loaded yet"
	end
	local before = tonumber(profile.SpeedPower) or HeroAdminService.MIN_SPEED_POWER
	local value = applySpeedPower(ctx.Target, before + sign * amount) -- clamped to [MIN_SPEED_POWER, MAX_SPEED_POWER]
	if value == nil then
		return false, ctx.Target.Name .. "'s profile is not loaded yet"
	end
	if sign > 0 then
		return true, string.format("+%s speed to %s (now %s)", compact(amount), ctx.Target.Name, compact(value))
	end
	return true, string.format("-%s speed from %s (now %s)", compact(math.max(0, before - value)), ctx.Target.Name, compact(value))
end

COMMANDS.GiveSpeed = function(ctx)
	return changeSpeed(ctx, 1)
end

COMMANDS.TakeSpeed = function(ctx)
	return changeSpeed(ctx, -1)
end

COMMANDS.SetSpeed = function(ctx)
	local value = ctx.Args.Value
	if not finiteNumber(value, HeroAdminService.MIN_SPEED_POWER, HeroAdminService.MAX_SPEED_POWER) then
		return false, "Invalid speed power"
	end
	local applied = applySpeedPower(ctx.Target, value)
	if applied == nil then
		return false, ctx.Target.Name .. "'s profile is not loaded yet"
	end
	return true, string.format("%s's speed power set to %s", ctx.Target.Name, compact(applied))
end

-- Eggs --------------------------------------------------------------------------------------------

-- A hero id of the stage's DropTable: "Random" = weighted like the stage's own roll, "Rarest" = the highest rarity.
local function pickStageHero(stageKey, pick)
	local area = entryOf(directoryTable("Areas"), stageKey)
	local assets = directoryTable("Assets")
	if area == nil or type(area.DropTable) ~= "table" or assets == nil then
		return nil
	end
	local pool, total = {}, 0
	for _, entry in ipairs(area.DropTable) do
		local heroId = type(entry) == "table" and entry[1] or nil
		local weight = type(entry) == "table" and entry[2] or nil
		local config = entryOf(assets, heroId)
		if config and type(weight) == "number" and weight > 0 and config.DontRoll ~= true then
			local rarity = type(config.Rarity) == "table" and tonumber(config.Rarity.RarityNumber) or 0
			table.insert(pool, { id = heroId, weight = weight, rarity = rarity, config = config })
			total += weight
		end
	end
	if #pool == 0 then
		return nil
	end
	if pick == "Rarest" then
		table.sort(pool, function(a, b)
			if a.rarity ~= b.rarity then
				return a.rarity > b.rarity
			end
			return a.weight < b.weight
		end)
		return pool[1]
	end
	local roll = math.random() * total
	for _, item in ipairs(pool) do
		roll -= item.weight
		if roll <= 0 then
			return item
		end
	end
	return pool[#pool]
end

COMMANDS.GiveEgg = function(ctx)
	local stageKey, pick = ctx.Args.Stage, ctx.Args.Pick
	if not isStageKey(stageKey) then
		return false, "Unknown stage"
	end
	if pick ~= "Random" and pick ~= "Rarest" then
		return false, "Pick must be Random or Rarest"
	end
	local profile = profileOf(ctx.Target)
	if profile == nil then
		return false, ctx.Target.Name .. "'s profile is not loaded yet"
	end
	local eggs = controller("EggService")
	if not (eggs and type(eggs.GrantEgg) == "function") then
		return false, "EggService unavailable"
	end
	local hero = pickStageHero(stageKey, pick)
	if hero == nil then
		return false, "That stage has no egg to give"
	end
	local uid = eggs.GrantEgg(ctx.Target, hero.id)
	if uid == nil then
		return false, "EggService refused the egg"
	end
	local egg = type(profile.EggInventory) == "table" and profile.EggInventory[uid]
	if egg and type(eggs.GrantEggTool) == "function" then
		pcall(eggs.GrantEggTool, ctx.Target, uid, egg)
	end
	local rarity = type(hero.config.Rarity) == "table" and hero.config.Rarity._id or nil
	local name = if type(hero.config.DisplayName) == "string" and hero.config.DisplayName ~= "" then hero.config.DisplayName else hero.id
	return true, string.format("%s egg%s from %s given to %s", name, if rarity then " (" .. tostring(rarity) .. ")" else "",
		stageName(stageKey), ctx.Target.Name)
end

COMMANDS.GrowEggs = function(ctx)
	local profile, db = profileOf(ctx.Target)
	if profile == nil then
		return false, ctx.Target.Name .. "'s profile is not loaded yet"
	end
	local grown = 0
	for _, egg in pairs(type(profile.EggInventory) == "table" and profile.EggInventory or {}) do
		if type(egg) == "table" and type(egg.Placement) == "table" and egg.Placement.ReadyAt == nil then
			egg.Placement.ReadyAt = os.time()
			grown += 1
		end
	end
	if grown == 0 then
		return true, ctx.Target.Name .. " has no growing egg placed"
	end
	db.Set(ctx.Target, { EggInventory = profile.EggInventory })
	local eggs = controller("EggService")
	if eggs and type(eggs.BroadcastOwnerRecords) == "function" then
		pcall(eggs.BroadcastOwnerRecords, ctx.Target)
	end
	return true, string.format("%d placed eggs of %s are ready to hatch", grown, ctx.Target.Name)
end

-- World -------------------------------------------------------------------------------------------

local function plotSpawnPoint(player)
	local plots = controller("PlotService")
	if not (plots and type(plots.GetPlotId) == "function") then
		return nil
	end
	local ok, plotId = pcall(plots.GetPlotId, player)
	local folder = Workspace:FindFirstChild("Plots")
	local plot = ok and plotId ~= nil and folder and folder:FindFirstChild(tostring(plotId))
	local spawnPoint = plot and plot:FindFirstChild("SpawnPoint")
	return if spawnPoint and spawnPoint:IsA("BasePart") then spawnPoint else nil
end

local function stageEntrance(key)
	local objects = Workspace:FindFirstChild("__OBJECTS")
	local areas = objects and objects:FindFirstChild("Areas")
	local guardAreas = areas and areas:FindFirstChild("GuardAreas")
	local stage = guardAreas and guardAreas:FindFirstChild(key)
	local bounds = stage and stage:FindFirstChild("Bounds")
	local exit = stage and stage:FindFirstChild("ClosestExitPoint")
	if not (bounds and bounds:IsA("BasePart")) then
		return nil
	end
	if exit and exit:IsA("BasePart") then
		local inward = Vector3.new(bounds.Position.X - exit.Position.X, 0, 0)
		inward = if inward.Magnitude > 1e-3 then inward.Unit else Vector3.new(1, 0, 0)
		local spot = Vector3.new(exit.Position.X, bounds.Position.Y, bounds.Position.Z) + inward * HeroAdminService.STAGE_INSET
		return spot, yawAlong(inward)
	end
	return bounds.Position, yawAlong(Vector3.new(1, 0, 0))
end

COMMANDS.Teleport = function(ctx)
	local place = ctx.Args.Place
	local caller = ctx.Caller
	local position, yaw, label
	if place == "Lobby" then
		local spawn = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
		if not (spawn and spawn:IsA("BasePart")) then
			return false, "No lobby SpawnLocation"
		end
		local _, spawnYaw = spawn.CFrame:ToOrientation()
		position = spawn.Position + Vector3.new(math.random(-20, 20) / 10, 0, math.random(-20, 20) / 10)
		yaw, label = spawnYaw, "the lobby"
	elseif place == "Plot" then
		local spawnPoint = plotSpawnPoint(caller)
		if spawnPoint == nil then
			return false, "You have no plot yet"
		end
		local _, spawnYaw = spawnPoint.CFrame:ToOrientation()
		position, yaw, label = spawnPoint.Position, spawnYaw, "your base"
	elseif isStageKey(place) then
		position, yaw = stageEntrance(place)
		if position == nil then
			return false, "That stage has no Bounds"
		end
		label = stageName(place)
	else
		return false, "Unknown place"
	end
	if not moveCharacter(caller, position, yaw) then
		return false, "You have no character right now"
	end
	return true, "Teleported to " .. label
end

local function nextNightText(util)
	local now = Workspace:GetServerTimeNow()
	local seconds = math.max(0, math.floor(util.GetNextNightAt(now) - now))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

COMMANDS.NightNow = function(_ctx)
	local util = nightUtil()
	if util == nil then
		return false, "Night cycle unavailable"
	end
	local ok, started, err = pcall(util.StartNightAt, Workspace:GetServerTimeNow())
	if not ok then
		return false, "Night failed: " .. tostring(started)
	end
	if not started then
		return false, tostring(err or "It is already night")
	end
	return true, string.format("Night started (%d s): the night reset follows", math.floor(util.GetNightDurationSeconds()))
end

COMMANDS.DayNow = function(_ctx)
	local util = nightUtil()
	if util == nil then
		return false, "Night cycle unavailable"
	end
	local now = Workspace:GetServerTimeNow()
	if util.IsNight(now) then
		-- the next period starts now (the same schedule attributes the util writes): day begins, the night growth is
		-- committed by EggService's period watcher
		Workspace:SetAttribute("AreaEggCycleAnchorIndex", util.GetPeriodIndex(now) + 1)
		Workspace:SetAttribute("AreaEggCycleAnchorAt", now)
		return true, "Night ended: next night in " .. nextNightText(util)
	end
	util.DeferNextReset(now)
	return true, "Day restarted: next night in " .. nextNightText(util)
end

COMMANDS.NormalCycle = function(_ctx)
	local util = nightUtil()
	if util == nil then
		return false, "Night cycle unavailable"
	end
	util.ClearScheduleOverrides()
	return true, "Night cycle back on the server clock: next night in " .. nextNightText(util)
end

local function tacoRain()
	local module = script.Parent:FindFirstChild("TacoRainService")
	if not (module and module:IsA("ModuleScript")) then
		return nil
	end
	local ok, service = pcall(require, module) -- the same table Branch started
	return if ok and type(service) == "table" then service else nil
end

local function broadcast()
	local module = script.Parent:FindFirstChild("HeroBroadcastService")
	if not (module and module:IsA("ModuleScript")) then
		return nil
	end
	local ok, service = pcall(require, module) -- the same table Branch started
	return if ok and type(service) == "table" then service else nil
end

-- ctx.Args.Scope -> "Server" | "All" | nil, reason
local function scopeOf(ctx)
	local scope = ctx.Args.Scope
	if scope == nil then
		return "Server"
	end
	if type(scope) ~= "string" or HeroAdminService.SCOPES[scope] ~= true then
		return nil, "Scope must be this server or all servers"
	end
	return scope
end

-- An all-server action may start only when the cross-server send will not be refused by its rate limit (nothing runs
-- at all then). A missing HeroBroadcastService still lets it run here (publishAll reports it).
local function mayPublish(ctx)
	local service = broadcast()
	if service == nil then
		return true
	end
	return service.CanPublish(ctx.Caller)
end

-- After the local run: the same action to every other server. -> ok, message[, "warn"]
local function publishAll(ctx, kind, data, localMessage)
	local service = broadcast()
	local ok, err = false, "the cross-server service is not running"
	if service then
		ok, err = service.Publish(kind, data, ctx.Caller)
	end
	if ok then
		return true, localMessage .. " (sent to every server)"
	end
	return true, localMessage .. ". THIS SERVER ONLY: " .. tostring(err), "warn"
end

COMMANDS.TacoRainStart = function(ctx)
	local service = tacoRain()
	if service == nil then
		return false, "The Taco Rain service is not running"
	end
	local duration = ctx.Args.Duration
	if duration ~= nil and not finiteNumber(duration, service.MIN_DURATION, service.MAX_DURATION) then
		return false, string.format("Duration must be %d to %d s", service.MIN_DURATION, service.MAX_DURATION)
	end
	duration = duration or service.DEFAULT_DURATION
	local scope, why = scopeOf(ctx)
	if scope == nil then
		return false, why
	end
	if scope == "All" then
		local allowed, reason = mayPublish(ctx)
		if not allowed then
			return false, reason
		end
	end
	local ok, message = service.StartRain(duration)
	if not ok or scope == "Server" then
		return ok, message
	end
	return publishAll(ctx, "TacoRain", { Action = "Start", Duration = duration }, tostring(message))
end

COMMANDS.TacoRainStop = function(ctx)
	local service = tacoRain()
	if service == nil then
		return false, "The Taco Rain service is not running"
	end
	local scope, why = scopeOf(ctx)
	if scope == nil then
		return false, why
	end
	if scope == "Server" then
		return service.StopRain("admin")
	end
	local allowed, reason = mayPublish(ctx)
	if not allowed then
		return false, reason
	end
	-- the other servers may still be raining even when this one is not
	local _, message = service.StopRain("admin, all servers")
	return publishAll(ctx, "TacoRain", { Action = "Stop" }, "Stop: " .. tostring(message))
end

-- A Taco Rain another server's admin sent to every server (HeroBroadcastService validated and clamped it).
local function runGlobalTacoRain(data)
	local service = tacoRain()
	if service == nil then
		warn("[HeroAdmin] all-server Taco Rain ignored: the Taco Rain service is not running")
		return
	end
	if data.Action == "Start" then
		local duration = math.clamp(tonumber(data.Duration) or service.DEFAULT_DURATION, service.MIN_DURATION, service.MAX_DURATION)
		local _, message = service.StartRain(duration)
		print(string.format("[HeroAdmin] all-server Taco Rain from %s: %s", tostring(data.By or "?"), tostring(message)))
	elseif data.Action == "Stop" then
		service.StopRain("all servers, " .. tostring(data.By or "?"))
	end
end
HeroAdminService._runGlobalTacoRain = runGlobalTacoRain

-- Server ------------------------------------------------------------------------------------------

COMMANDS.Announce = function(ctx)
	local service = broadcast()
	if service == nil then
		return false, "The announcement service is not running"
	end
	local scope, why = scopeOf(ctx)
	if scope == nil then
		return false, why
	end
	return service.Announce(ctx.Caller, ctx.Args.Text, scope)
end

COMMANDS.UnlockBaseThemes = function(ctx)
	local profile, db = profileOf(ctx.Target)
	if profile == nil then
		return false, ctx.Target.Name .. "'s profile is not loaded yet"
	end
	local themes = directory("BaseThemes")
	if not (themes and type(themes.Order) == "table") then
		return false, "Directory.BaseThemes unavailable"
	end
	local unlocked = if type(profile.UnlockedBaseThemes) == "table" then profile.UnlockedBaseThemes else {}
	local count = 0
	for _, key in ipairs(themes.Order) do
		if unlocked[key] ~= true then
			unlocked[key] = true
			count += 1
		end
	end
	db.SetAndBroadcast(ctx.Target, { UnlockedBaseThemes = unlocked })
	return true, string.format("%d base themes unlocked for %s (equip them in the Index)", count, ctx.Target.Name)
end

-- Player ------------------------------------------------------------------------------------------

COMMANDS.Release = function(ctx)
	local release = ServerScriptService:FindFirstChild("GearReleaseRequest")
	if not (release and release:IsA("BindableFunction")) then
		return false, "GearReleaseRequest unavailable"
	end
	local ok, result = pcall(release.Invoke, release, ctx.Target)
	if not ok then
		return false, "Release failed: " .. tostring(result)
	end
	return true, if result then ctx.Target.Name .. " released" else ctx.Target.Name .. " was not held (nothing to release)"
end

COMMANDS.Respawn = function(ctx)
	local ok, err = pcall(ctx.Target.LoadCharacter, ctx.Target)
	if not ok then
		return false, "Respawn failed: " .. tostring(err)
	end
	return true, ctx.Target.Name .. " respawned"
end

COMMANDS.Heal = function(ctx)
	local _, _, humanoid = characterOf(ctx.Target)
	if humanoid == nil then
		return false, ctx.Target.Name .. " has no living character"
	end
	humanoid.Health = humanoid.MaxHealth
	return true, ctx.Target.Name .. " healed"
end

COMMANDS.GoTo = function(ctx)
	if ctx.Target == ctx.Caller then
		return false, "Pick another player first"
	end
	local _, targetRoot = characterOf(ctx.Target)
	if targetRoot == nil then
		return false, ctx.Target.Name .. " has no character"
	end
	local behind = targetRoot.CFrame * CFrame.new(0, 0, 4)
	if not moveCharacter(ctx.Caller, behind.Position, yawAlong(targetRoot.CFrame.LookVector)) then
		return false, "You have no character right now"
	end
	return true, "Moved to " .. ctx.Target.Name
end

COMMANDS.Bring = function(ctx)
	if ctx.Target == ctx.Caller then
		return false, "Pick another player first"
	end
	local _, callerRoot = characterOf(ctx.Caller)
	if callerRoot == nil then
		return false, "You have no character right now"
	end
	local front = callerRoot.CFrame * CFrame.new(0, 0, -5)
	if not moveCharacter(ctx.Target, front.Position, yawAlong(-callerRoot.CFrame.LookVector)) then
		return false, ctx.Target.Name .. " has no character"
	end
	return true, ctx.Target.Name .. " brought to you"
end

-- The wiped player's rows on the leaderboards (best effort: every call pcall'd, Studio without API access just logs).
local function clearLeaderboards(userId, name)
	local key, cleared, failed = tostring(userId), 0, nil
	for _, storeName in ipairs(HeroAdminService.LEADERBOARD_STORES) do
		local ok, err = pcall(function()
			DataStoreService:GetOrderedDataStore(storeName):RemoveAsync(key)
		end)
		if ok then
			cleared += 1
		else
			failed = failed or tostring(err)
		end
	end
	print(string.format("[HeroAdmin] WIPE %s (%d): %d / %d leaderboard entries removed%s", name, userId, cleared,
		#HeroAdminService.LEADERBOARD_STORES, if failed then " (" .. failed .. ")" else ""))
end
HeroAdminService._clearLeaderboards = clearLeaderboards

COMMANDS.WipeData = function(ctx)
	local caller, target = ctx.Caller, ctx.Target
	if ctx.Args.ConfirmUserId ~= target.UserId then
		return false, "Wipe not confirmed for " .. target.Name .. ": press WIPE, then CONFIRM within 4 s"
	end
	local now = os.clock()
	local last = lastWipe[caller]
	if last ~= nil and now - last < HeroAdminService.WIPE_COOLDOWN then
		return false, string.format("Wait %d s before the next wipe", math.ceil(HeroAdminService.WIPE_COOLDOWN - (now - last)))
	end
	local db = database()
	if not (db and type(db.WipeProfile) == "function") then
		return false, "Library.Database cannot wipe profiles"
	end
	if type(db.IsWiped) == "function" and db.IsWiped(target) then
		return false, target.Name .. " was already wiped: they are being kicked"
	end
	if profileOf(target) == nil then
		return false, target.Name .. "'s profile is not loaded yet"
	end
	lastWipe[caller] = now
	warn(string.format("[HeroAdmin] WIPE %s (%d) resets the saved data of %s (%d)", caller.Name, caller.UserId, target.Name, target.UserId))
	local ok, saved, reason = pcall(db.WipeProfile, target)
	if not ok then
		return false, "Wipe failed: " .. tostring(saved)
	end
	local userId, name = target.UserId, target.Name
	task.delay(HeroAdminService.WIPE_KICK_DELAY, function()
		if target.Parent == Players then
			pcall(target.Kick, target, HeroAdminService.WIPE_KICK_MESSAGE)
		end
	end)
	task.delay(HeroAdminService.WIPE_KICK_DELAY + HeroAdminService.LEADERBOARD_CLEAR_DELAY, clearLeaderboards, userId, name)
	if saved == true then
		return true, string.format("%s's data was wiped and saved. Kicking them in %d s", name, HeroAdminService.WIPE_KICK_DELAY)
	end
	return true, string.format("%s's data was wiped, but the save failed (%s). Kicking them: their leave save retries it", name,
		tostring(reason)), "warn"
end

----------------------------------------------------------------------------------------------------
-- remote
----------------------------------------------------------------------------------------------------

local function takeToken(player)
	local now = os.clock()
	local bucket = buckets[player]
	if bucket == nil then
		bucket = { tokens = HeroAdminService.RATE_PER_SECOND, at = now }
		buckets[player] = bucket
	end
	bucket.tokens = math.min(HeroAdminService.RATE_PER_SECOND, bucket.tokens + (now - bucket.at) * HeroAdminService.RATE_PER_SECOND)
	bucket.at = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

-- A shallow copy of the args with only short string keys and string / number / boolean values (nil when invalid).
local function cleanArgs(args)
	if args == nil then
		return {}
	end
	if type(args) ~= "table" then
		return nil
	end
	local clean, count = {}, 0
	for key, value in pairs(args) do
		count += 1
		if count > HeroAdminService.MAX_ARG_KEYS or type(key) ~= "string" or #key > 24 then
			return nil
		end
		local kind = type(value)
		if kind == "string" then
			if #value > (HeroAdminService.LONG_ARGS[key] or HeroAdminService.MAX_ARG_STRING) then
				return nil
			end
		elseif kind == "number" then
			if value ~= value or value == math.huge or value == -math.huge then
				return nil
			end
		elseif kind ~= "boolean" then
			return nil
		end
		clean[key] = value
	end
	return clean
end

local function onInvoke(player, command, targetUserId, args)
	if not takeToken(player) then
		return false, "Too fast: wait a moment"
	end
	if type(command) ~= "string" or #command == 0 or #command > HeroAdminService.MAX_COMMAND_LENGTH then
		return false, "Invalid command"
	end
	if not Access.IsAdmin(player) then
		local now = os.clock()
		if now - (lastRefusalWarn[player] or -math.huge) >= HeroAdminService.REFUSAL_WARN_EVERY then
			lastRefusalWarn[player] = now
			warn(string.format("[HeroAdmin] refused %s (%d): %s (not a Hero admin)", player.Name, player.UserId, command))
		end
		return false, "Not allowed"
	end
	local handler = COMMANDS[command]
	if handler == nil then
		return false, "Unknown command"
	end
	local target = player
	if targetUserId ~= nil then
		if not finiteNumber(targetUserId, -1e15, 1e15) or targetUserId % 1 ~= 0 then
			return false, "Invalid target"
		end
		target = Players:GetPlayerByUserId(targetUserId)
		if target == nil then
			return false, "That player is not in this server"
		end
	end
	local clean = cleanArgs(args)
	if clean == nil then
		return false, "Invalid arguments"
	end
	if command ~= "Inspect" then
		print(string.format("[HeroAdmin] %s %s -> %s", player.Name, command, target.Name))
	end
	local ok, success, message, kind = pcall(handler, { Caller = player, Target = target, Args = clean })
	if not ok then
		warn(string.format("[HeroAdmin] %s %s -> %s failed: %s", player.Name, command, target.Name, tostring(success)))
		return false, "Command failed (see the server log)", summaryOf(target)
	end
	return success == true, tostring(message or (if success then "Done" else "Failed")), summaryOf(target),
		if kind == "warn" then "warn" else nil
end
HeroAdminService._onInvoke = onInvoke

----------------------------------------------------------------------------------------------------
-- panel delivery
----------------------------------------------------------------------------------------------------

local function givePanel(player)
	local template = ServerStorage:FindFirstChild(HeroAdminService.PANEL_NAME)
	if not (template and template:IsA("ScreenGui")) then
		warn("[HeroAdmin] ServerStorage." .. HeroAdminService.PANEL_NAME .. " is missing: no panel for " .. player.Name)
		return
	end
	local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 30)
	if playerGui == nil or player.Parent ~= Players or playerGui:FindFirstChild(HeroAdminService.PANEL_NAME) then
		return
	end
	local panel = template:Clone()
	panel.Enabled = false
	panel.ResetOnSpawn = false
	panel.Parent = playerGui
end

function HeroAdminService:Init()
	local network = ReplicatedStorage:FindFirstChild("Network") or ReplicatedStorage:WaitForChild("Network", 4)
	if network == nil then
		network = Instance.new("Folder")
		network.Name = "Network"
		network.Parent = ReplicatedStorage
	end
	local existing = network:FindFirstChild(HeroAdminService.REMOTE_NAME)
	if existing and not existing:IsA("RemoteFunction") then
		existing:Destroy()
		existing = nil
	end
	remote = existing
	if remote == nil then
		remote = Instance.new("RemoteFunction")
		remote.Name = HeroAdminService.REMOTE_NAME
		remote.Parent = network
	end
end

function HeroAdminService:Start()
	remote.OnServerInvoke = onInvoke
	-- all-server Taco Rains sent by another server's admin (HeroBroadcastService validates them first)
	local service = broadcast()
	if service and type(service.OnGlobal) == "function" then
		service.OnGlobal("TacoRain", runGlobalTacoRain)
	else
		warn("[HeroAdmin] HeroBroadcastService missing: all-server events will not reach this server")
	end
end

function HeroAdminService:PlayerAdded(player)
	local isAdmin, reason = Access.IsAdmin(player)
	if player.Parent ~= Players then
		return
	end
	if not isAdmin then
		player:SetAttribute(Access.ATTRIBUTE, nil)
		return
	end
	player:SetAttribute(Access.ATTRIBUTE, true)
	print(string.format("[HeroAdmin] %s (%d) has the admin panel (%s)", player.Name, player.UserId, tostring(reason)))
	givePanel(player)
end

function HeroAdminService:PlayerRemoving(player)
	buckets[player] = nil
	lastRefusalWarn[player] = nil
	lastWipe[player] = nil
	Access.Forget(player)
	for _, model in ipairs(dummies()) do
		if model:GetAttribute("DummyOwner") == player.UserId then
			model:Destroy()
		end
	end
end

return HeroAdminService
