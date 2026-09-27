--!nonstrict
-- ServerScriptService.GearService (server Script, injected by scripts/inject/gear.luau)
--
-- The server half of the gear: every player's starter kit (D3) and the behaviour of that gear - the Bat swing with
-- its ragdoll (D2) and the two placeable traps.
--
-- Why this exists instead of the original scripts: the base place was produced by a save-instance ripper, and
-- every server `Script` in it is a one-line comment stub ("[FilteringEnabled] Server Scripts are IMPOSSIBLE to
-- save"). So `GearTools.ShopItems.Bat.Controller` (Script), `Assets.ToolEffects.SubspaceTrap.ActiveSubspaceTrap`
-- and the gear/inventory server services are all empty. The surviving client halves
-- (`GearTools.ShopItems.Trap.TrapScript`, `Library.Modules.BatController.Client`) fire remotes that no longer
-- have a listener, and `BatController.Server` / `Library.Modules.Ragdoll` cannot be revived: they require
-- `ServerScriptService.Controllers.AntiCheatService`, `ServerScriptService.Library.Network`,
-- `ServerScriptService.Library.Modules.ClientCharacterAction` and `...Tools.Internal.{GameplayToolGuard,SlapShared}`,
-- none of which exist in the base place. This script is therefore a clean, minimal, self-contained reimplementation
-- - no exploit/admin code, no Sound creation (audio stays on the build's whitelist).
--
-- It keeps the conventions the *surviving client* scripts already understand, so the existing UI reacts for free:
--   * Tool attributes `GearName` + `ItemType = "Gear"` -> BackpackController shows it as gear and locks the Bat to
--     hotbar slot 1 and the Trap to slot 2; ToolGameplayGuard shows "Cannot use items in the safe zone!"
--   * `player.StarterGear` copies               -> Roblox re-gives them on every respawn; BackpackController puts
--     StarterGear tools at the front of the hotbar
--   * profile `GearInventory[<gear>] >= 1`      -> the Index / shop see the starter gear as owned
--   * character attribute `IsTrapped`           -> Game/Tools/TrappedBackpackController locks the backpack
--   * character attribute `Ragdolled`           -> set while a bat hit has the character ragdolled
--   * placed-trap BasePart attributes `Owner` (player name) and `TrapActive`
--   * CollectionService tags `PlacedTrap` and `TrapUnplacePrompt`
--     (Library.Globals.Constants.TAGS_MAP.Traps) -> TrapGameplayHighlightController highlights your own traps
--     and TrapUnplacePromptController shows the pick-up prompt only on yours.
--
-- Bat swing (owner 2026-09-24, Gekko TO DO 2 "Bat Rework", Steal a Brainrot reference). A click (Tool.Activated)
-- only STARTS a swing: the server checks the cooldown / state and broadcasts Network["Gear: BatFx"]
-- { Action = "Swing", Attacker, WindUp, Duration } to every client, which animate a wind-up + horizontal swing on
-- that character (StarterPlayerScripts.Game.Tools.BatCombatFx; no animation asset needed). The hit registers only at
-- the contact moment, SWING_WINDUP seconds later, re-validated here (same character alive and still holding the bat,
-- not ragdolled / trapped / carrying, outside the safe zone) against the players in reach and in front at THAT
-- moment. A landed hit broadcasts { Action = "Hit", Attacker, Victim, Position, Direction, Dropped } (impact burst,
-- white flash, pop) and shakes both cameras through the base game's Network["ReplicateEffects: ShakeOnce"]
-- (Game.CameraShake). Reach and fling force come from each bat's Directory.Gears BatControllerData.
--
-- Hero weapons (owner 2026-09-27, "MISSION: replace the bat system with Hero Gadgets"). The melee tools named in
-- ReplicatedStorage.Library.Modules.HeroWeapons.BY_TOOL are hero weapons (scripts/steps/post_hero_weapons.luau built
-- them: Bat = Cap's shield, Forest = Power Pole, Desert = web shooter, Lake = batarang, Jungle = Bakugo's gauntlet,
-- Snow / Cosmic = Mjolnir, Volcano = Gum-Gum fist). Their click broadcasts the same "Swing" with Weapon = <id>, and
-- the hit is resolved at the attack clip's Impact keyframe (HeroWeapons.Timing) by the weapon's Kind (line thrust,
-- blast cone, ground slam, the Power Pole's full-turn sweep, and the AIMED throws: Cap's shield flies out on a curve
-- and comes back, the batarang explodes where it lands, the web shoots straight - the client sends its aim point with
-- the click, the server clamps it and flies the projectile itself, see "Aimed throws"). A landed hit applies the weapon's 2.5 s
-- state (Webbed, Electrocuted, CleanKnockback, Dazed, SmokeStun, ExplosionBlast, SpinTornado) INSTEAD of the ragdoll:
-- WalkSpeed / jump / AutoRotate are held here (saved and restored like the trap freeze), character attributes
-- `HeroDebuff` = <effect> and `BatFlung` are set, and { Action = "Debuff", Victim, Weapon, Effect, Token, Duration,
-- Direction, Push, Slide } goes to every client (StarterPlayerScripts.BranchControllers.HeroWeaponController draws
-- the state; the victim's own client does the knockback slide / spin). A carrier still drops the egg first and always
-- takes the state; a short immunity follows every state. The admin panel's training dummies (HeroWeapons.DUMMY_TAG)
-- are hit like players (the server moves them itself). The villain catch keeps the ragdoll (GearRagdollRequest); the
-- classic bats not in BY_TOOL keep the swing and ragdoll below.
--
-- Carrier rules (owner 2026-09-24, Gekko TO DO 3). AreaEggService mirrors an egg carry on the player as the
-- attribute `CarryingEgg`. A carrier cannot swing or hold any tool: every server-known Tool is put back in the
-- Backpack when the carry starts and whenever one is equipped during it (the client backpack refuses too). Others
-- can still bat a carrier: the egg drops at once through AreaEggService.DropCarriedEggFrom (the normal Dropped egg
-- path; AreaEggService keeps the carrier off THAT egg for 3 s) and the carrier ragdolls CARRIER_RAGDOLL_DURATION.
--
-- Bat ragdoll (D2). Validated here (the attacker's client never names a victim), then:
--   * server: every limb Motor6D (all but the root joint and the Neck - a disabled Neck kills a Humanoid with
--     RequiresNeck) is swapped for a BallSocketConstraint whose attachments are oriented per joint family (arms /
--     legs swing in a cone around the hanging limb, elbows / knees bend one way only, the waist twists a little),
--     with friction scaled by the limb's mass, plus a NoCollisionConstraint between the two joined parts (all tagged
--     `GearRagdoll`). Humanoid.PlatformStand is set (a stun even a client that ignores the event cannot skip), the
--     victim keeps network ownership of every limb, and the victim alone gets
--     `Network["Gear: Ragdoll"]` { Action = "Start", Token, Duration, Velocity }. The joint swap is server-side so
--     the limp body replicates to every player; the victim's client (StarterPlayerScripts.Game.Tools.
--     GearRagdollController) owns the character's physics and does the rest: Physics state, limb collisions, the
--     knockback along the swing, standing back up.
--   * after the duration the joints are restored, PlatformStand cleared and { Action = "End" } sent; a short
--     immunity stops stun-locking. Death mid-ragdoll leaves the body limp until respawn; a respawn or leave simply
--     discards the state (the new character is clean). The remotes are server -> client only: anything a client
--     fires at them is ignored.
--   * server-only entry points: ServerScriptService.GearRagdollRequest:Invoke(player, direction[, { Duration }])
--     (villain catches, GuardChaseService) and ServerScriptService.GearReleaseRequest:Invoke(player) (lifts a
--     ragdoll / trap freeze at once; the night teleport, AreaEggService).
--
-- Index stage bats (owner batch item 2, "Equip button in index for bats not working"). Every stage card of the Index
-- (GUI.Index + its AreaIndexProgressComponent) shows an EQUIP button once all of that stage's heroes are discovered;
-- it invokes Network["Index: RequestEquipAreaBat"](sectionId, "Equip" | "Unequip") -> (ok, err?, equippedBat), which
-- StubService used to answer "Not available". It is answered here: the section id is the Directory.Areas key, its
-- IndexBatGearId names the bat (Forest ... Volcano Bat, tools in GearTools.ShopItems); only the stages the Index lists
-- (Directory.StageArt) can be equipped, never a retired zone's bat. The first equip needs the
-- stage's Index complete on the server (the same hero list the page counts) and records the bat as owned
-- (profile GearInventory[bat] = 1, VisitedGears[bat] = true: the page's "!" badge goes away); later equips only need
-- that ownership. profile.EquippedBat (a bat id, "" / missing = the plain Bat) picks the melee tool of the kit: the
-- equipped stage bat REPLACES the Bat in the Backpack and StarterGear (same hotbar slot 1), and "Unequip" gives the
-- plain Bat back. A bat held in hand at the swap is swapped in hand, except while carrying an egg (the carrier rule
-- below still applies, and only while `CarryingEgg` is set: equipping from the Index is never refused for it).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local TRAP_FOLDER = "PlacedTraps"
local TAG_PLACED_TRAP = "PlacedTrap"
local TAG_UNPLACE_PROMPT = "TrapUnplacePrompt"
local ACTIVE_TRAP_ATTRIBUTE = "ActiveTrapCount" -- Directory.Gears._Index.Other.Trap.ActiveDeploymentAttribute
local CARRY_ATTRIBUTE = "CarryingEgg" -- set by AreaEggService while the player carries a stolen egg

-- D3: the kit every player spawns with, in hotbar order. The Subspace Trap (SubspaceMine) is NOT part of it.
-- STARTER_GEAR[1] is the melee slot: the player's equipped Index stage bat takes its place (kitFor below).
local STARTER_GEAR = { "Bat", "Trap" }
local DEFAULT_BAT = "Bat"

-- Index stage bats: profile field, remote (NETWORK_MAP.Index.REQUEST_EQUIP_AREA_BAT) and its per-player rate limit.
local EQUIPPED_BAT_FIELD = "EquippedBat"
local EQUIP_AREA_BAT_REMOTE_NAME = "Index: RequestEquipAreaBat"
local AREA_BAT_REQUEST_COOLDOWN = 0.3
local MAX_SECTION_ID_LENGTH = 64

-- Melee gear. Defaults mirror Directory.Gears._Index.Other.Bat.BatControllerData (Force 35, RangeBonus 0); each bat
-- is overridden from its own config when that loads (the stage bats reach further and fling harder).
local MELEE_GEAR = {
	["Bat"] = true,
	["Forest Bat"] = true,
	["Desert Bat"] = true,
	["Lake Bat"] = true,
	["Jungle Bat"] = true,
	["Snow Bat"] = true,
	["Volcano Bat"] = true,
	["Prehistoric Bat"] = true,
	["Cosmic Bat"] = true,
	["Abyss Ocean Bat"] = true,
}
local MELEE_RANGE = 12 -- studs from the swinger's root to the victim's root at the contact moment
local MELEE_MAX_HEIGHT = 8 -- the victim's root is at most this far above / below the swinger's
local MELEE_MIN_DOT = 0.25 -- the victim must be roughly in front of the swing (~75 degrees either side)
-- Lag-compensated swings (owner 2026-09-27: "the hitbox between players must be super accurate, no lag"): the swinger's
-- screen showed the other player one round trip + the interpolation buffer late, so the hit is judged against the victim
-- REWOUND to what the swinger saw (BranchServices.LagCompensationService.SeenBy); the victim must also still be within
-- reach + MELEE_SEEN_SLACK now (a stale position never lands a hit on someone who is far away by now).
local MELEE_SEEN_SLACK = 6
local LagComp = nil
do
	local services = ServerScriptService:FindFirstChild("BranchServices")
	local module = services and services:FindFirstChild("LagCompensationService")
	if module then
		local ok, result = pcall(require, module)
		LagComp = if ok and type(result) == "table" then result else nil
	end
end
local MELEE_COOLDOWN = 0.7
local MELEE_COOLDOWN_SLACK = 0.1 -- two clicks MELEE_COOLDOWN apart can arrive a little closer (network jitter)
local MELEE_FORCE = 35

-- Swing timeline, shared with the clients' animation (Game.Tools.BatCombatFx): wind-up until the contact moment,
-- then the swing and the recovery. The hit is resolved exactly SWING_WINDUP after the swing started.
local SWING_WINDUP = 0.18
local SWING_DURATION = 0.45
local BAT_FX_REMOTE_NAME = "Gear: BatFx"
local SHAKE_REMOTE_NAME = "ReplicateEffects: ShakeOnce" -- NETWORK_MAP.ReplicatedEffects.SHAKE_ONCE (Game.CameraShake)

-- Ragdoll tuning. The knockback scales with the bat's configured Force (35 -> ~52 studs/s along the swing, ~21 up).
local RAGDOLL_REMOTE_NAME = "Gear: Ragdoll"
local RAGDOLL_TAG = "GearRagdoll"
local RAGDOLL_DURATION = 1.75 -- a bat hit on a player who carries nothing, and a villain catch
local CARRIER_RAGDOLL_DURATION = 3 -- a bat hit on an egg carrier (the egg drops at once)
local RAGDOLL_MIN_DURATION, RAGDOLL_MAX_DURATION = 0.5, 5
local RAGDOLL_IMMUNITY = 1.5 -- after getting up, a new hit cannot ragdoll again for this long
local FLING_HORIZONTAL_PER_FORCE = 1.5
local FLING_VERTICAL_PER_FORCE = 0.6
local FLING_MAX_HORIZONTAL = 115

-- BallSocket per joint family: { name match, axis, cone (UpperAngle), twist lower, twist upper, friction factor }.
-- `axis` orients the socket's primary axis in the joint frame (Motor6D C0 / C1): "down" = along the hanging limb
-- (the cone is how far the limb swings, the twist its roll), "hinge" = the joint's right axis (the twist is the
-- bend: elbows forward, knees backward), "up" = along the spine. Degrees. The friction factor x the limb's weight
-- damps the flailing without holding the limb up.
local JOINT_SPECS = {
	{ "Shoulder", "down", 95, -60, 60, 0.9 },
	{ "Hip", "down", 55, -25, 25, 1.2 },
	{ "Elbow", "hinge", 8, -5, 125, 0.5 },
	{ "Knee", "hinge", 8, -120, 5, 0.7 },
	{ "Wrist", "hinge", 20, -35, 35, 0.3 },
	{ "Ankle", "hinge", 15, -30, 25, 0.3 },
	{ "Waist", "up", 20, -25, 25, 2 },
}
local DEFAULT_JOINT_SPEC = { "", "down", 30, -30, 30, 0.8 }
local JOINT_AXIS_FRAMES = {
	down = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, -1, 0), Vector3.new(0, 0, -1)),
	up = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 1, 0), Vector3.new(0, 0, -1)),
	hinge = CFrame.identity,
}
local JOINT_FRICTION_PER_WEIGHT = 0.1 -- x mass x gravity

-- Placeable gear. Both templates live in ReplicatedStorage.Assets.ToolEffects.
local TRAP_GEAR = {
	["Trap"] = { template = "PlayerTrap", freeze = 7, maxActive = 3, cooldown = 1.5 },
	["SubspaceMine"] = { template = "SubspaceTrap", freeze = 7, maxActive = 3, cooldown = 1.5 },
}
local TRAP_LIFETIME = 180 -- an untriggered trap cleans itself up rather than littering the map forever

-- Safe zone: the base game's ToolGameplayGuard lets gear work only past Workspace.__OBJECTS.Areas.SeparationLine
-- (its LookVector points into the stages). Enforced here too, so what the client says is what the server does.
local SAFE_ZONE_FALLBACK_X = 75

----------------------------------------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------------------------------------

local function log(message)
	warn("[GearService] " .. message)
end

local shopItems do
	local gearTools = ReplicatedStorage:WaitForChild("GearTools", 20)
	shopItems = gearTools and gearTools:WaitForChild("ShopItems", 20)
	if not shopItems then
		log("ReplicatedStorage.GearTools.ShopItems is missing - no gear can be handed out.")
	end
end

local toolEffects do
	local assets = ReplicatedStorage:WaitForChild("Assets", 20)
	toolEffects = assets and assets:WaitForChild("ToolEffects", 20)
	if not toolEffects then
		log("ReplicatedStorage.Assets.ToolEffects is missing - traps will not be placeable.")
	end
end

-- The gear events (built into ReplicatedStorage.Network by scripts/steps/gear.luau; created here if missing).
local network = ReplicatedStorage:FindFirstChild("Network")
if not network then
	network = Instance.new("Folder")
	network.Name = "Network"
	network.Parent = ReplicatedStorage
end

local function serverToClientRemote(name)
	local remote = network:FindFirstChild(name)
	if not (remote and remote:IsA("RemoteEvent")) then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = network
	end
	-- Server -> client only. A listener keeps client spam from queueing up; its payload is ignored.
	remote.OnServerEvent:Connect(function() end)
	return remote
end

local ragdollRemote = serverToClientRemote(RAGDOLL_REMOTE_NAME)
local batFxRemote = serverToClientRemote(BAT_FX_REMOTE_NAME)
-- Game.CameraShake binds this one when it starts, so it only works when the build put it in the place file; a copy
-- made here is harmless and keeps the fire calls below valid.
local shakeRemote = serverToClientRemote(SHAKE_REMOTE_NAME)
do
	-- The surviving Bat client controller (Library.Modules.BatController.Client) still fires "Bat:Activate" with its
	-- own target guess on every click; the swing is driven by Tool.Activated here, so that request is only drained.
	local legacyActivate = network:FindFirstChild("Bat:Activate")
	if legacyActivate and legacyActivate:IsA("RemoteEvent") then
		legacyActivate.OnServerEvent:Connect(function() end)
	end
end

-- Integration: a Bat hit or a sprung trap makes a thief drop the area egg they are carrying, exactly like a
-- villain catch. AreaEggService (ModuleScript, ServerScriptService.Controllers, loaded by Bootstrap) owns the
-- carry state; use only its public DropCarriedEggFrom and never hard-fail when it is absent.
-- Required in the background so its load (profiles, remotes, guard areas) never delays gear hookup; a hit
-- landing before it is ready simply drops nothing.
local areaEggService = nil
task.spawn(function()
	local controllers = ServerScriptService:WaitForChild("Controllers", 30)
	local module = controllers and controllers:WaitForChild("AreaEggService", 30)
	if not module or not module:IsA("ModuleScript") then
		log("ServerScriptService.Controllers.AreaEggService not found - gear hits will not drop carried eggs.")
		return
	end
	local ok, result = pcall(require, module)
	if ok and type(result) == "table" and type(result.DropCarriedEggFrom) == "function" then
		areaEggService = result
	else
		log("AreaEggService unavailable, gear hits will not drop carried eggs: " .. tostring(result))
	end
end)

-- `victim` loses the egg they carry (if any). `attacker` can never make themselves drop. Returns true on a drop.
local function dropCarriedEggOf(victim, attacker, hitCFrame, reason)
	if areaEggService == nil or victim == nil or victim == attacker then
		return false
	end
	local ok, dropped = pcall(areaEggService.DropCarriedEggFrom, victim, hitCFrame, reason)
	if not ok then
		log("DropCarriedEggFrom failed for " .. tostring(victim) .. ": " .. tostring(dropped))
		return false
	end
	return dropped ~= nil
end

local function isCarrying(player)
	return player:GetAttribute(CARRY_ATTRIBUTE) == true
end

-- Bottom-of-screen message through the game's notification remote (NotificationCmds.Message), like AreaEggService.
local function notify(player, message, color)
	local remote = network:FindFirstChild("Notifications_Show")
	if player.Parent and remote and remote:IsA("RemoteEvent") then
		pcall(remote.FireClient, remote, player, "Message", "Bottom", { Time = 2.5, Message = message, Color = color })
	end
end
local NOTICE_BAD = Color3.fromRGB(255, 96, 96)
local NOTICE_GOOD = Color3.fromRGB(110, 255, 120)

-- Bat config per tool name from the shared gear directory when it is loadable; silent fallback to the constants.
local gearDirectory = nil
do
	local directory = ReplicatedStorage:FindFirstChild("Directory")
	local gears = directory and directory:FindFirstChild("Gears")
	if gears then
		local ok, module = pcall(require, gears)
		if ok and type(module) == "table" and type(module.Directory) == "table" then
			gearDirectory = module.Directory
		end
	end
end

-- Hero weapons (owner 2026-09-27): the shared weapon table and the owner's weapon kit. Without them every melee tool
-- simply keeps the classic bat swing and ragdoll.
local HeroWeapons, WeaponKit = nil, nil
do
	local library = ReplicatedStorage:FindFirstChild("Library")
	local modules = library and library:FindFirstChild("Modules")
	for name, assign in pairs({
		HeroWeapons = function(module)
			HeroWeapons = module
		end,
		HeroWeaponTools = function(module)
			WeaponKit = module
		end,
	}) do
		local module = modules and modules:FindFirstChild(name)
		if module and module:IsA("ModuleScript") then
			local ok, result = pcall(require, module)
			if ok and type(result) == "table" then
				assign(result)
			else
				log("Library.Modules." .. name .. " failed to load: " .. tostring(result))
			end
		else
			log("Library.Modules." .. name .. " is missing - melee tools keep the classic bat.")
		end
	end
end
local DEBUFF_ATTRIBUTE = "HeroDebuff" -- HeroWeapons.DEBUFF_ATTRIBUTE: the victim's active effect

-- The hero weapon of a melee tool, or nil (a classic bat, or the weapon table is missing).
local function heroWeaponOf(tool)
	if HeroWeapons == nil then
		return nil
	end
	local ok, weapon = pcall(HeroWeapons.Of, tool)
	return if ok then weapon else nil
end

local meleeConfigCache = {}
local function meleeConfigFor(toolName)
	local cached = meleeConfigCache[toolName]
	if cached then
		return cached
	end
	local config = { force = MELEE_FORCE, range = MELEE_RANGE }
	local ok, data = pcall(function()
		local entry = gearDirectory and (gearDirectory[toolName] or gearDirectory["Bat"])
		return entry and entry.BatControllerData
	end)
	if ok and type(data) == "table" then
		local force, bonus = tonumber(data.Force), tonumber(data.RangeBonus)
		if force and force > 0 then
			config.force = math.min(force, 100)
		end
		if bonus and bonus > 0 then
			config.range = MELEE_RANGE + math.min(bonus, 16)
		end
	end
	meleeConfigCache[toolName] = config
	return config
end

local function characterOf(player)
	local character = player.Character
	if not character or not character.Parent then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil
	end
	return character, humanoid, root
end

-- Hero weapon victims: every player's character, plus the admin panel's training dummies (a Model tagged
-- HeroWeapons.DUMMY_TAG with a live Humanoid). A `victim` below is the Player, or the dummy Model itself.
local function targetCharacter(victim)
	if typeof(victim) ~= "Instance" then
		return nil
	end
	if victim:IsA("Player") then
		return characterOf(victim)
	end
	if victim:IsA("Model") and victim:IsDescendantOf(Workspace) and HeroWeapons
		and CollectionService:HasTag(victim, HeroWeapons.DUMMY_TAG) then
		local humanoid = victim:FindFirstChildOfClass("Humanoid")
		local root = victim:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			return victim, humanoid, root
		end
	end
	return nil
end

local function weaponVictims(player)
	local out = {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			table.insert(out, other)
		end
	end
	if HeroWeapons then
		for _, dummy in ipairs(CollectionService:GetTagged(HeroWeapons.DUMMY_TAG)) do
			if dummy:IsA("Model") and dummy:IsDescendantOf(Workspace) then
				table.insert(out, dummy)
			end
		end
	end
	return out
end

local function isOnGameplaySide(position)
	local objects = Workspace:FindFirstChild("__OBJECTS")
	local areas = objects and objects:FindFirstChild("Areas")
	local line = areas and areas:FindFirstChild("SeparationLine")
	if line and line:IsA("BasePart") then
		return line.CFrame.LookVector:Dot(position - line.Position) > 0
	end
	return position.X > SAFE_ZONE_FALLBACK_X
end

----------------------------------------------------------------------------------------------------
-- Bat ragdoll (D2)
----------------------------------------------------------------------------------------------------

local ragdolls = setmetatable({}, { __mode = "k" }) -- [character] = { token, motors, humanoid, died }
local ragdollImmuneUntil = setmetatable({}, { __mode = "k" }) -- [character] = os.clock() deadline (debuffs too)
local ragdollSerial = 0
local debuffs = setmetatable({}, { __mode = "k" }) -- [character] = hero weapon debuff state (see below)
local dummyCalmAt = setmetatable({}, { __mode = "k" }) -- [training dummy] = os.clock() when it may be put back
local endDebuff -- (victim, character, token?) defined with the hero weapons below

local function jointSpecFor(motorName)
	for _, spec in ipairs(JOINT_SPECS) do
		if string.find(motorName, spec[1], 1, true) then
			return spec
		end
	end
	return DEFAULT_JOINT_SPEC
end

local function tagRagdollPart(instance, motorName)
	instance:SetAttribute(RAGDOLL_TAG, motorName)
	return instance
end

-- Real body parts only (direct children of the character the Humanoid knows as R15 limbs, or the R6 limb names):
-- an aura / trail / accessory welded into the character is never a ragdoll limb (owner 2026-09-27: "with an aura or
-- a trail equipped the ragdoll goes stiff").
local R6_BODY = { Torso = true, Head = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true }
local R15_BODY = {
	HumanoidRootPart = true, LowerTorso = true, UpperTorso = true, Head = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
}
local function isBodyPart(character, humanoid, part)
	if not (part and part:IsA("BasePart")) or part.Parent ~= character then
		return false
	end
	if R6_BODY[part.Name] or R15_BODY[part.Name] then
		return true
	end
	if typeof(humanoid) ~= "Instance" or not humanoid:IsA("Humanoid") then
		return false
	end
	local ok, kind = pcall(humanoid.GetBodyPartR15, humanoid, part)
	return ok and kind ~= nil and kind ~= Enum.BodyPartR15.Unknown
end

-- Swap every limb Motor6D of `character` for a limited BallSocketConstraint; returns the motors it disabled.
local function buildRagdollJoints(character, root, humanoid)
	local disabled = {}
	for _, motor in ipairs(character:GetDescendants()) do
		if motor:IsA("Motor6D") and motor.Enabled then
			local part0, part1 = motor.Part0, motor.Part1
			local isRootJoint = part0 == root or part1 == root or motor.Name == "Root" or motor.Name == "RootJoint"
			local inTool = motor:FindFirstAncestorOfClass("Tool") ~= nil
				or (part1 ~= nil and part1:FindFirstAncestorOfClass("Tool") ~= nil)
			if part0 and part1 and not isRootJoint and not inTool and motor.Name ~= "Neck"
				and isBodyPart(character, humanoid, part0) and isBodyPart(character, humanoid, part1) then
				local spec = jointSpecFor(motor.Name)
				local axisFrame = JOINT_AXIS_FRAMES[spec[2]] or CFrame.identity

				-- Both attachments share the joint frame (C0 in Part0 = C1 in Part1 at rest), rotated so the socket's
				-- primary axis runs the way this joint family moves.
				local attachment0 = tagRagdollPart(Instance.new("Attachment"), motor.Name)
				attachment0.Name = "GearRagdoll0_" .. motor.Name
				attachment0.CFrame = motor.C0 * axisFrame
				attachment0.Parent = part0

				local attachment1 = tagRagdollPart(Instance.new("Attachment"), motor.Name)
				attachment1.Name = "GearRagdoll1_" .. motor.Name
				attachment1.CFrame = motor.C1 * axisFrame
				attachment1.Parent = part1

				local socket = tagRagdollPart(Instance.new("BallSocketConstraint"), motor.Name)
				socket.Name = "GearRagdoll_" .. motor.Name
				socket.Attachment0 = attachment0
				socket.Attachment1 = attachment1
				socket.LimitsEnabled = true
				socket.UpperAngle = spec[3]
				socket.TwistLimitsEnabled = true
				socket.TwistLowerAngle = spec[4]
				socket.TwistUpperAngle = spec[5]
				socket.Restitution = 0
				local massOk, mass = pcall(function()
					return part1:GetMass()
				end)
				socket.MaxFrictionTorque = spec[6] * JOINT_FRICTION_PER_WEIGHT * Workspace.Gravity
					* (if massOk and type(mass) == "number" then math.clamp(mass, 0.1, 5) else 0.7)
				socket.Parent = motor.Parent

				-- the two joined limbs overlap at the joint: never let them push each other apart
				local noCollide = tagRagdollPart(Instance.new("NoCollisionConstraint"), motor.Name)
				noCollide.Name = "GearRagdollNoCollide_" .. motor.Name
				noCollide.Part0 = part0
				noCollide.Part1 = part1
				noCollide.Parent = motor.Parent

				motor.Enabled = false
				table.insert(disabled, motor)
			end
		end
	end
	return disabled
end

local function clearRagdollJoints(character, motors)
	for _, motor in ipairs(motors) do
		if motor.Parent then
			motor.Enabled = true
		end
	end
	for _, d in ipairs(character:GetDescendants()) do
		if d.Parent and d:GetAttribute(RAGDOLL_TAG) ~= nil then
			d:Destroy()
		end
	end
end

-- The victim's client simulates its own limp body (smooth for them, replicated to everyone else). With the limb
-- motors off every limb is its own assembly, so the ownership is (re)asserted per part.
local function giveBodyToOwner(character, player)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored then
			pcall(part.SetNetworkOwner, part, player)
		end
	end
end

local function fireRagdoll(player, payload)
	if player.Parent then
		pcall(ragdollRemote.FireClient, ragdollRemote, player, payload)
	end
end

local function endRagdoll(victim, character, token)
	local state = ragdolls[character]
	if not state or (token ~= nil and state.token ~= token) then
		return
	end
	ragdolls[character] = nil
	if state.died then
		state.died:Disconnect()
	end
	if character.Parent then
		local ok, err = pcall(clearRagdollJoints, character, state.motors)
		if not ok then
			log("ragdoll restore failed for " .. tostring(victim) .. ": " .. tostring(err))
		end
		if state.humanoid.Parent and state.humanoid.Health > 0 then
			state.humanoid.PlatformStand = false
		end
		character:SetAttribute("Ragdolled", false)
		character:SetAttribute("BatFlung", false)
		ragdollImmuneUntil[character] = os.clock() + RAGDOLL_IMMUNITY
	end
	fireRagdoll(victim, { Action = "End", Token = state.token })
end

-- Returns true when `victim` was ragdolled. `direction` is a flat unit vector (the knockback heading).
-- options (all optional): Duration (seconds), Force (the bat's BatControllerData.Force), IgnoreImmunity.
local function ragdollVictim(victim, direction, options)
	options = type(options) == "table" and options or {}
	local character, humanoid, root = characterOf(victim)
	if not character then
		return false
	end
	if character:GetAttribute("IsTrapped") == true or ragdolls[character] ~= nil then
		return false
	end
	if options.IgnoreImmunity ~= true and (ragdollImmuneUntil[character] or 0) > os.clock() then
		return false
	end
	if not isOnGameplaySide(root.Position) then
		return false -- the safe zone protects
	end
	if debuffs[character] ~= nil and endDebuff then
		endDebuff(victim, character, nil) -- a villain catch takes over from a hero weapon state
	end

	local duration = math.clamp(tonumber(options.Duration) or RAGDOLL_DURATION, RAGDOLL_MIN_DURATION, RAGDOLL_MAX_DURATION)
	local force = math.clamp(tonumber(options.Force) or MELEE_FORCE, 1, 100)

	ragdollSerial += 1
	local token = ragdollSerial
	local ok, motors = pcall(buildRagdollJoints, character, root, humanoid)
	if not ok then
		log("ragdoll joints failed for " .. tostring(victim) .. ": " .. tostring(motors))
		motors = {}
	end
	local state = { token = token, motors = motors, humanoid = humanoid }
	ragdolls[character] = state
	character:SetAttribute("Ragdolled", true)
	character:SetAttribute("BatFlung", true)
	humanoid.PlatformStand = true
	giveBodyToOwner(character, victim)

	-- Dying mid-ragdoll: nothing to stand back up; the limp body stays until the respawn replaces it.
	state.died = humanoid.Died:Connect(function()
		if ragdolls[character] == state then
			ragdolls[character] = nil
			state.died:Disconnect()
			fireRagdoll(victim, { Action = "End", Token = token })
		end
	end)

	local horizontal = math.min(force * FLING_HORIZONTAL_PER_FORCE, FLING_MAX_HORIZONTAL)
	local velocity = direction * horizontal + Vector3.new(0, force * FLING_VERTICAL_PER_FORCE, 0)
	fireRagdoll(victim, { Action = "Start", Token = token, Duration = duration, Velocity = velocity })
	task.delay(duration, endRagdoll, victim, character, token)
	return true
end

----------------------------------------------------------------------------------------------------
-- Bat: wind-up, then the swing lands on the nearest player in front of you at the contact moment
----------------------------------------------------------------------------------------------------

local lastSwingAt = setmetatable({}, { __mode = "k" }) -- [player] = os.clock() of the last accepted swing
local swingSerial = 0

-- The swinger's own state, checked when the swing starts and again at the contact moment.
-- Owner 2026-09-27: "the weapons can be used while ragdolled - make that not happen": a body that is down (the
-- ragdoll, PlatformStand, or a Humanoid state the owning client reports as fallen / physics / getting up) cannot
-- attack either.
local DOWN_STATES = {
	[Enum.HumanoidStateType.FallingDown] = true,
	[Enum.HumanoidStateType.Ragdoll] = true,
	[Enum.HumanoidStateType.Physics] = true,
	[Enum.HumanoidStateType.PlatformStanding] = true,
	[Enum.HumanoidStateType.GettingUp] = true,
	[Enum.HumanoidStateType.Dead] = true,
}
local function isDown(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return true
	end
	if humanoid.PlatformStand then
		return true
	end
	local ok, state = pcall(humanoid.GetState, humanoid)
	return ok and DOWN_STATES[state] == true
end

local function canSwing(player, character)
	return character:GetAttribute("IsTrapped") ~= true and character:GetAttribute("Ragdolled") ~= true
		and character:GetAttribute(DEBUFF_ATTRIBUTE) == nil and not isCarrying(player) and not isDown(character)
end

local function fireBatFx(payload)
	pcall(batFxRemote.FireAllClients, batFxRemote, payload)
end

-- Game.CameraShake (CameraShaker.ShakeOnce): magnitude, roughness, fade in, fade out.
local function shakeCamera(player, magnitude, roughness, fadeOut)
	if player.Parent then
		pcall(shakeRemote.FireClient, shakeRemote, player, {
			Magnitude = magnitude,
			Roughness = roughness,
			FadeInTime = 0,
			FadeOutTime = fadeOut,
		})
	end
end

local function flatUnit(vector, fallback)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	return if flat.Magnitude > 0.01 then flat.Unit else fallback
end

-- Whether a bat hit on `other` can do anything (knock the egg loose or ragdoll them). Players it cannot touch (already
-- down, in the safe zone, frozen in a trap, or just back up) are skipped, so they never shadow a valid target behind
-- them (review 2026-09-24: the knocked-down ex-carrier lying at the egg made the swing at its new carrier whiff).
local function isHittable(other, otherCharacter, otherRoot)
	if ragdolls[otherCharacter] ~= nil or otherCharacter:GetAttribute("Ragdolled") == true then
		return false
	end
	if not isOnGameplaySide(otherRoot.Position) then
		return false -- the safe zone protects
	end
	if isCarrying(other) then
		return true -- a carrier always loses the egg
	end
	return otherCharacter:GetAttribute("IsTrapped") ~= true and debuffs[otherCharacter] == nil
		and (ragdollImmuneUntil[otherCharacter] or 0) <= os.clock()
end

-- The nearest other living, hittable player in reach and in front of `root`; also returns the knockback heading:
-- away from the swinger, bent the way a right-handed horizontal swing travels (to the swinger's left).
local function findSwingVictim(player, root, range)
	local flatForward = flatUnit(root.CFrame.LookVector, Vector3.new(0, 0, -1))
	local flatLeft = flatUnit(-root.CFrame.RightVector, Vector3.new(-1, 0, 0))
	local bestVictim, bestDistance, bestAway = nil, math.huge, nil
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherCharacter, _, otherRoot = characterOf(other)
			if otherCharacter and isHittable(other, otherCharacter, otherRoot) then
				local seen = if LagComp then LagComp.SeenBy(otherRoot, player) else otherRoot.Position
				local delta = seen - root.Position
				local distance = delta.Magnitude
				local nowDistance = (otherRoot.Position - root.Position).Magnitude
				if distance <= range and distance < bestDistance and math.abs(delta.Y) <= MELEE_MAX_HEIGHT
					and nowDistance <= range + MELEE_SEEN_SLACK then
					local away = flatUnit(delta, flatForward)
					if away:Dot(flatForward) >= MELEE_MIN_DOT then
						bestVictim, bestDistance, bestAway = other, distance, away
					end
				end
			end
		end
	end
	if not bestVictim then
		return nil
	end
	return bestVictim, flatUnit(bestAway + flatForward * 0.5 + flatLeft * 0.4, bestAway)
end

-- A landed hit: a carrier drops the egg right away (before the knockback moves them), then the ragdoll, feedback.
-- The carrier knock-down (3 s, through any immunity) goes with an actual drop: a carrier AreaEggService refuses to
-- drop (already home in its safe zone, or the service not loaded yet) takes a normal hit.
local function landHit(attacker, attackerRoot, victim, direction, config)
	local wasCarrying = isCarrying(victim)
	local dropped = false
	if wasCarrying then
		dropped = dropCarriedEggOf(victim, attacker, attackerRoot.CFrame, "BatHit")
	end
	local ragdolled = ragdollVictim(victim, direction, {
		Duration = if dropped then CARRIER_RAGDOLL_DURATION else RAGDOLL_DURATION,
		Force = config.force,
		IgnoreImmunity = dropped, -- a carrier who lost the egg is always knocked down
	})
	if not (ragdolled or dropped) then
		return -- trapped, just got up, or in the safe zone: no hit
	end

	local _, _, victimRoot = characterOf(victim)
	local hitPosition = if victimRoot then victimRoot.Position else attackerRoot.Position + direction * 3
	fireBatFx({
		Action = "Hit",
		Attacker = attacker,
		Victim = victim,
		Position = hitPosition,
		Direction = direction,
		Dropped = dropped,
	})
	shakeCamera(attacker, 1.8, 8, 0.2) -- a small bump for both
	shakeCamera(victim, 3.5, 10, 0.4)
	if dropped then
		notify(victim, "Bonk! You dropped the egg!", NOTICE_BAD)
		notify(attacker, "You knocked the egg loose!", NOTICE_GOOD)
	end
end

local function resolveSwingContact(player, tool, character, startedAt)
	if player.Parent == nil or os.clock() - startedAt < SWING_WINDUP - 0.02 then
		return
	end
	local current, _, root = characterOf(player)
	if current ~= character or tool.Parent ~= character or not canSwing(player, character) then
		return -- died, respawned, put the bat away, got knocked down or grabbed an egg during the wind-up
	end
	if not isOnGameplaySide(root.Position) then
		return
	end
	local config = meleeConfigFor(tool.Name)
	local victim, direction = findSwingVictim(player, root, config.range)
	if victim then
		landHit(player, root, victim, direction, config)
	end
end

----------------------------------------------------------------------------------------------------
-- Hero weapons (owner 2026-09-27, "MISSION: replace the bat system with Hero Gadgets"): the attack clip's Impact
-- keyframe resolves the hit, and a landed hit applies a 2.5 s themed state instead of the ragdoll
----------------------------------------------------------------------------------------------------

local speedServiceModule = nil
local function speedService()
	if speedServiceModule == nil then
		speedServiceModule = false
		local controllers = ServerScriptService:FindFirstChild("Controllers")
		local module = controllers and controllers:FindFirstChild("SpeedService")
		if module and module:IsA("ModuleScript") then
			local ok, result = pcall(require, module)
			speedServiceModule = if ok and type(result) == "table" then result else false
		end
	end
	return speedServiceModule or nil
end

-- Training dummies ragdoll for real (owner 2026-09-27, round 11: "the dummy's R15 ragdoll still does not work, its
-- legs stay anchored"): a hit used to slide / spin the dummy's root while its Humanoid kept balancing, so the body slid
-- on planted legs. No client owns a dummy, so the server does what GearRagdollController does for a player's own body:
-- limb sockets (buildRagdollJoints), the Physics state with PlatformStand (the Humanoid stops balancing), the limbs
-- collide (not the root box), every part server-owned and thrown along the hit with a tumble. The state's end puts the
-- joints back and the dummy keeper eases it up on its spot.
local DUMMY_FLING_MIN, DUMMY_FLING_MAX = 16, 46 -- studs/s along the hit (from the weapon's Push)
local DUMMY_FLING_UP = 18
local DUMMY_TUMBLE = 5 -- rad/s tipping the head along the flight
local dummyRagdolls = setmetatable({}, { __mode = "k" }) -- [dummy] = { motors, collisions }
local settleDummy -- (model, root) defined with the dummy keeper below

local function ragdollDummy(model, humanoid, root, direction, push)
	if dummyRagdolls[model] ~= nil then
		return
	end
	local ok, motors = pcall(buildRagdollJoints, model, root, humanoid)
	if not ok then
		log("training dummy ragdoll joints failed: " .. tostring(motors))
		motors = {}
	end
	local state = { motors = motors, collisions = {} }
	dummyRagdolls[model] = state
	model:SetAttribute("DummyRagdolled", true)
	pcall(humanoid.SetStateEnabled, humanoid, Enum.HumanoidStateType.Physics, true)
	humanoid.PlatformStand = true
	pcall(humanoid.ChangeState, humanoid, Enum.HumanoidStateType.Physics)
	local heading = if typeof(direction) == "Vector3" then Vector3.new(direction.X, 0, direction.Z) else Vector3.zero
	heading = if heading.Magnitude > 0.01 then heading.Unit else -root.CFrame.LookVector
	local speed = math.clamp((tonumber(push) or 0) * 0.9, DUMMY_FLING_MIN, DUMMY_FLING_MAX)
	local velocity = heading * speed + Vector3.new(0, DUMMY_FLING_UP, 0)
	local spin = Vector3.yAxis:Cross(heading) * DUMMY_TUMBLE
	for _, part in ipairs(model:GetDescendants()) do
		if isBodyPart(model, humanoid, part) then
			local wanted = part ~= root
			if part.CanCollide ~= wanted then
				state.collisions[part] = part.CanCollide
				part.CanCollide = wanted
			end
			-- every limb is its own assembly now: keep them all on the server (never a nearby player's client)
			pcall(part.SetNetworkOwner, part, nil)
			part.AssemblyLinearVelocity = velocity
			part.AssemblyAngularVelocity = spin
		end
	end
end

local function endDummyRagdoll(model)
	local state = dummyRagdolls[model]
	if state == nil then
		return
	end
	dummyRagdolls[model] = nil
	local ok, err = pcall(clearRagdollJoints, model, state.motors)
	if not ok then
		log("training dummy ragdoll restore failed: " .. tostring(err))
	end
	for part, canCollide in pairs(state.collisions) do
		if part.Parent then
			part.CanCollide = canCollide
		end
	end
	model:SetAttribute("DummyRagdolled", nil)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		pcall(root.SetNetworkOwner, root, nil)
	end
	if humanoid and humanoid.Parent and humanoid.Health > 0 then
		-- no engine GettingUp (it made the dummy flail on the floor): settleDummy eases it upright right away
		humanoid.PlatformStand = false
		pcall(humanoid.SetStateEnabled, humanoid, Enum.HumanoidStateType.Physics, false)
	end
end

-- Gives the victim their movement back (once). A trapped victim's movement belongs to the trap and is never touched.
local function restoreMovement(victim, state)
	if not state.moved or state.restored then
		return
	end
	state.restored = true
	local humanoid = state.humanoid
	if humanoid.Parent == nil or humanoid.Health <= 0 then
		return
	end
	if state.walkSpeed > 0 then
		humanoid.WalkSpeed = state.walkSpeed
	else
		humanoid.WalkSpeed = 16
		local speed = speedService()
		if speed and type(speed.Refresh) == "function" and victim:IsA("Player") then
			pcall(speed.Refresh, victim)
		end
	end
	humanoid.JumpPower = if state.jumpPower > 0 then state.jumpPower else 50
	humanoid.JumpHeight = if state.jumpHeight > 0 then state.jumpHeight else 7.2
	humanoid.AutoRotate = state.autoRotate
end

local debuffSerial = 0

endDebuff = function(victim, character, token)
	local state = debuffs[character]
	if not state or (token ~= nil and state.token ~= token) then
		return
	end
	debuffs[character] = nil
	if state.died then
		state.died:Disconnect()
	end
	restoreMovement(victim, state)
	if character.Parent then
		character:SetAttribute(DEBUFF_ATTRIBUTE, nil)
		if ragdolls[character] == nil then
			character:SetAttribute("BatFlung", false)
		end
		ragdollImmuneUntil[character] = os.clock() + (HeroWeapons and HeroWeapons.IMMUNITY or 1.2)
	end
	fireBatFx({ Action = "DebuffEnd", Victim = victim, Token = state.token })
	if not victim:IsA("Player") then
		endDummyRagdoll(character)
		dummyCalmAt[character] = os.clock() + 0.5 -- the keeper's fallback if the ease below cannot run
		local root = character:FindFirstChild("HumanoidRootPart")
		if settleDummy and root and root:IsA("BasePart") then
			task.spawn(function()
				local ok, err = pcall(settleDummy, character, root)
				if not ok then
					log("training dummy get-up failed: " .. tostring(err))
				end
			end)
		end
	end
end

-- `victim` enters `weapon`'s state (HeroWeapons.EFFECTS[weapon.Effect]) for its duration. Movement is server-side
-- (WalkSpeed / jump / AutoRotate saved and restored like the trap freeze); the slide / spin itself is the victim's
-- own client (it owns the character's physics), everything visible is drawn by every client from the broadcast.
-- `direction` is the flat unit knockback heading. options.IgnoreImmunity: a carrier who just lost the egg.
-- A training dummy has no client to move it: the server ragdolls it itself (ragdollDummy above).
local function applyDebuff(victim, weapon, direction, options)
	options = type(options) == "table" and options or {}
	local character, humanoid, root = targetCharacter(victim)
	if not character or ragdolls[character] ~= nil then
		return false -- a villain catch owns the body
	end
	if not isOnGameplaySide(root.Position) then
		return false -- the safe zone protects
	end
	local ignoreImmunity = options.IgnoreImmunity == true
	if not ignoreImmunity and (ragdollImmuneUntil[character] or 0) > os.clock() then
		return false
	end
	if debuffs[character] ~= nil then
		if not ignoreImmunity then
			return false
		end
		endDebuff(victim, character, nil)
	end
	local effectName = weapon.Effect
	local effect = HeroWeapons.EFFECTS[effectName] or {}
	local duration = tonumber(effect.Duration) or HeroWeapons.EFFECT_DURATION

	debuffSerial += 1
	local token = debuffSerial
	local state = { token = token, effect = effectName, humanoid = humanoid, moved = false, restored = false }
	if character:GetAttribute("IsTrapped") ~= true then
		state.moved = true
		state.walkSpeed, state.jumpPower, state.jumpHeight = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight
		state.autoRotate = humanoid.AutoRotate
		if type(effect.WalkSpeed) == "number" then
			humanoid.WalkSpeed = math.min(humanoid.WalkSpeed, effect.WalkSpeed)
		end
		if effect.NoJump then
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
		end
		if effect.NoAutoRotate then
			humanoid.AutoRotate = false
		end
	end
	debuffs[character] = state
	character:SetAttribute(DEBUFF_ATTRIBUTE, effectName)
	character:SetAttribute("BatFlung", true) -- AreaEggService: no grabbing an egg while stunned
	state.died = humanoid.Died:Connect(function()
		endDebuff(victim, character, token)
	end)

	local slide = tonumber(effect.Slide)
	if state.moved and slide and slide > 0 then
		task.delay(slide, function()
			if debuffs[character] ~= state or state.restored or humanoid.Parent == nil then
				return
			end
			if effect.ReleaseAfterSlide then
				restoreMovement(victim, state) -- CleanKnockback: slid back, now run back
			elseif type(effect.SlowAfterSlide) == "number" and state.walkSpeed > 0 then
				humanoid.WalkSpeed = math.min(state.walkSpeed, effect.SlowAfterSlide)
			end
		end)
	end
	fireBatFx({
		Action = "Debuff",
		Victim = victim,
		Weapon = weapon.Id,
		Effect = effectName,
		Token = token,
		Duration = duration,
		Direction = direction,
		Push = weapon.Push,
		Slide = slide,
	})
	if not victim:IsA("Player") then
		ragdollDummy(character, humanoid, root, direction, weapon.Push)
	end
	task.delay(duration, endDebuff, victim, character, token)
	return true
end

-- A landed hero weapon hit: a carrier drops the egg first, then the state, the feedback. Returns true when it did
-- anything.
local function landWeaponHit(attacker, attackerCFrame, victim, weapon, direction)
	local dropped = false
	local isPlayer = victim:IsA("Player")
	if isPlayer and isCarrying(victim) then
		dropped = dropCarriedEggOf(victim, attacker, attackerCFrame, "BatHit")
	end
	local debuffed = applyDebuff(victim, weapon, direction, { IgnoreImmunity = dropped })
	if not (debuffed or dropped) then
		return false
	end
	local _, _, victimRoot = targetCharacter(victim)
	fireBatFx({
		Action = "Hit",
		Attacker = attacker,
		Victim = victim,
		Weapon = weapon.Id,
		Effect = weapon.Effect,
		Position = if victimRoot then victimRoot.Position else attackerCFrame.Position + direction * 3,
		Direction = direction,
		Dropped = dropped,
	})
	shakeCamera(attacker, 1.8, 8, 0.2)
	if isPlayer then
		shakeCamera(victim, 3.5, 10, 0.4)
	end
	if dropped then
		notify(victim, weapon.DisplayName .. "! You dropped the egg!", NOTICE_BAD)
		notify(attacker, "You knocked the egg loose!", NOTICE_GOOD)
	end
	return true
end

-- Hittable players `weapon` reaches from `root`, nearest first, at most `maxTargets`. `centre` (optional) makes it a
-- radius around that point (Slam); otherwise the target must be in front (minDot) and, for a weapon with a Width,
-- within that many studs of the attack line. Positions are what the attacker saw (lag compensation), and the victim
-- must still be near now. Also returns the attacker's flat forward.
local function weaponTargets(player, root, weapon, range, minDot, maxTargets, centre)
	local flatForward = flatUnit(root.CFrame.LookVector, Vector3.new(0, 0, -1))
	local origin = centre or root.Position
	local found = {}
	for _, other in ipairs(weaponVictims(player)) do
		do
			local otherCharacter, _, otherRoot = targetCharacter(other)
			if otherCharacter and isHittable(other, otherCharacter, otherRoot) then
				local seen = if LagComp then LagComp.SeenBy(otherRoot, player) else otherRoot.Position
				local distance = (seen - origin).Magnitude
				local nowDistance = (otherRoot.Position - origin).Magnitude
				if distance <= range and math.abs(seen.Y - root.Position.Y) <= MELEE_MAX_HEIGHT
					and nowDistance <= range + MELEE_SEEN_SLACK then
					local away = flatUnit(seen - root.Position, flatForward)
					local inside = centre ~= nil or away:Dot(flatForward) >= minDot
					if inside and centre == nil and type(weapon.Width) == "number" then
						-- the attack line starts at the arm's shoulder (LineOffset studs to the right of the middle)
						local lineOrigin = root.Position + flatUnit(root.CFrame.RightVector, Vector3.new(1, 0, 0))
							* (tonumber(weapon.LineOffset) or 0)
						local offset = seen - lineOrigin
						local along = offset:Dot(flatForward)
						local lateral = (Vector3.new(offset.X, 0, offset.Z) - flatForward * along).Magnitude
						inside = along > 0 and lateral <= weapon.Width
					end
					if inside then
						table.insert(found, { player = other, distance = distance, away = away })
					end
				end
			end
		end
	end
	table.sort(found, function(a, b)
		return a.distance < b.distance
	end)
	for index = #found, math.max(maxTargets, 0) + 1, -1 do
		found[index] = nil
	end
	return found, flatForward
end

-- Aimed throws (owner 2026-09-27: "the shield must fly out of our hands with a bit of curve, a good hitbox from the
-- model; the batarangs do the same and explode where they land; batarang, shield and web must be aimable, they are
-- shots"). The client sends its aim point with the click (HeroWeapons.AIM_REMOTE); at the Impact keyframe the server
-- clamps it (HeroWeapons.AimEnd: range, pitch, the first wall), broadcasts the path ({ Action = "Launch", Id, Origin,
-- End, Side, Curve, OutTime, Returns, BackTime }: every client draws HeroWeapons.PathPoint) and flies it itself,
-- testing every hittable victim against each Heartbeat's segment (the victim where the thrower saw them, lag
-- compensated). Boomerang: every rival it passes, out and back, at most MaxTargets; Grenade: explodes on the first
-- rival it touches, a wall or the end (every rival within BlastRadius); Shot: the first rival. An early end is
-- broadcast as { Action = "ProjectileEnd", Id, Position, Reason = "Hit" | "Explode" | "Miss" }.
local AIM_FRESH = 1.5 -- an aim point older than this (seconds) is ignored: the throw goes straight ahead
local BODY_RADIUS = 1.6 -- a character's half width + a little: added to the projectile's own radius
local aims = setmetatable({}, { __mode = "k" }) -- [player] = { tool, point, at }
local projectiles = {} -- the flights in the air
local projectileSerial = 0

local aimRemote = network:FindFirstChild(HeroWeapons and HeroWeapons.AIM_REMOTE or "Gear: WeaponAim")
if not (aimRemote and aimRemote:IsA("RemoteEvent")) then
	aimRemote = Instance.new("RemoteEvent")
	aimRemote.Name = HeroWeapons and HeroWeapons.AIM_REMOTE or "Gear: WeaponAim"
	aimRemote.Parent = network
end
aimRemote.OnServerEvent:Connect(function(player, tool, point, seq)
	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") or typeof(point) ~= "Vector3" then
		return
	end
	if type(seq) ~= "number" or seq ~= seq or seq < 0 or seq > 2 ^ 31 then
		seq = nil -- the client's throw number, echoed in Launch so it adopts its own predicted flight
	end
	if point.X ~= point.X or point.Y ~= point.Y or point.Z ~= point.Z then
		return -- NaN
	end
	local character, _, root = characterOf(player)
	if not character or tool.Parent ~= character or (point - root.Position).Magnitude > 600 then
		return
	end
	local weapon = heroWeaponOf(tool)
	if weapon and weapon.Aimed then
		aims[player] = { tool = tool, point = point, at = os.clock(), seq = seq and math.floor(seq) }
	end
end)

-- The fresh aim point of `tool` (and the client's throw number), consumed by this throw.
local function aimOf(player, tool, root)
	local aim = aims[player]
	if aim and aim.tool == tool and os.clock() - aim.at <= AIM_FRESH then
		aims[player] = nil
		return aim.point, aim.seq
	end
	return root.Position + flatUnit(root.CFrame.LookVector, Vector3.new(0, 0, -1)) * 30, nil
end

-- Workspace raycast that only stops at collidable world geometry (never a character, a dummy or an effect).
local function wallRaycaster(player)
	local exclude = {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Character then
			table.insert(exclude, other.Character)
		end
	end
	for _, victim in ipairs(weaponVictims(player)) do
		if victim:IsA("Model") then
			table.insert(exclude, victim)
		end
	end
	for _, name in ipairs({ "HeroWeaponFx", TRAP_FOLDER }) do
		local folder = Workspace:FindFirstChild(name)
		if folder then
			table.insert(exclude, folder)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude
	params.RespectCanCollide = true
	params.IgnoreWater = true
	return function(origin, vector)
		local result = Workspace:Raycast(origin, vector, params)
		return if result then result.Position else nil
	end
end

-- Whether nothing collidable stands between two points (a blast does not reach behind a wall).
local function clearLine(raycast, from, to)
	return raycast(from, to - from) == nil
end

local function segmentDistance(point, a, b)
	local ab = b - a
	local lengthSquared = ab:Dot(ab)
	local t = if lengthSquared > 1e-8 then math.clamp((point - a):Dot(ab) / lengthSquared, 0, 1) else 0
	return (point - (a + ab * t)).Magnitude
end

-- Where the thrower saw `victim` (lag compensated), if the victim is still near there now.
local function seenPosition(flight, victim)
	local character, _, root = targetCharacter(victim)
	if not character or not isHittable(victim, character, root) then
		return nil
	end
	local seen = if LagComp and victim:IsA("Player") then LagComp.SeenBy(root, flight.player) else root.Position
	if (root.Position - seen).Magnitude > MELEE_SEEN_SLACK then
		seen = root.Position -- they moved on long since: judge where they are
	end
	return seen
end

local function endFlight(flight, position, reason)
	fireBatFx({
		Action = "ProjectileEnd",
		Id = flight.id,
		Attacker = flight.player,
		Weapon = flight.weapon.Id,
		Position = position,
		Reason = reason,
	})
end

local function explodeGrenade(flight, position)
	endFlight(flight, position, "Explode")
	local weapon = flight.weapon
	local radius = tonumber(weapon.BlastRadius) or 8
	local found = {}
	for _, victim in ipairs(weaponVictims(flight.player)) do
		local seen = seenPosition(flight, victim)
		if seen and (seen - position).Magnitude <= radius and clearLine(flight.raycast, position, seen) then
			table.insert(found, { victim = victim, distance = (seen - position).Magnitude, away = flatUnit(seen - position, flight.forward) })
		end
	end
	table.sort(found, function(a, b)
		return a.distance < b.distance
	end)
	for index = 1, math.min(#found, tonumber(weapon.MaxTargets) or 4) do
		landWeaponHit(flight.player, CFrame.new(position), found[index].victim, weapon, found[index].away)
	end
end

-- One Heartbeat of a flight. Returns true when it is over.
local function stepFlight(flight, now)
	if flight.player.Parent == nil then
		return true
	end
	local weapon, path = flight.weapon, flight.path
	local home = nil
	if path.Returns then
		local _, _, root = characterOf(flight.player)
		home = if root then HeroWeapons.ReturnHome(root.CFrame) else path.Origin
	end
	local t = now - flight.started
	local position, finished = HeroWeapons.PathPoint(path, t, home)
	-- the curve and the way back are checked against walls every step, not only the aimed line
	local wall = flight.raycast(flight.last, position - flight.last)
	if wall then
		local direction = position - flight.last
		direction = if direction.Magnitude > 1e-3 then direction.Unit else flight.forward
		local stop = wall - direction * 0.5
		if weapon.Kind == "Grenade" then
			explodeGrenade(flight, stop)
			return true
		elseif weapon.Kind == "Shot" then
			endFlight(flight, stop, "Miss")
			return true
		elseif path.Returns and t < path.OutTime then
			-- the shield bounces off and comes back from there
			path.End = stop
			path.BackTime = HeroWeapons.Travel(weapon, (stop - path.Origin).Magnitude, weapon.ReturnSpeed)
			path.OutTime = t
			fireBatFx({ Action = "ProjectileTurn", Id = flight.id, Attacker = flight.player, Weapon = weapon.Id,
				Position = stop, At = t, BackTime = path.BackTime })
			position = stop
		end
	end
	local reach = flight.hitRadius + BODY_RADIUS
	if flight.hits < flight.maxHits then
		for _, victim in ipairs(weaponVictims(flight.player)) do
			if not flight.hit[victim] then
				local seen = seenPosition(flight, victim)
				if seen and segmentDistance(seen, flight.last, position) <= reach then
					flight.hit[victim] = true
					local heading = flatUnit(position - flight.last, flight.forward)
					if weapon.Kind == "Grenade" then
						explodeGrenade(flight, position)
						return true
					end
					if landWeaponHit(flight.player, CFrame.new(flight.last), victim, weapon, heading) then
						flight.hits += 1
					end
					if weapon.Kind == "Shot" then
						endFlight(flight, position, "Hit")
						return true
					end
					if flight.hits >= flight.maxHits then
						break
					end
				end
			end
		end
	end
	flight.last = position
	if finished then
		if weapon.Kind == "Grenade" then
			explodeGrenade(flight, path.End)
		elseif weapon.Kind == "Shot" then
			endFlight(flight, path.End, "Miss")
		end
		return true
	end
	return false
end

RunService.Heartbeat:Connect(function()
	if #projectiles == 0 then
		return
	end
	local now = os.clock()
	for index = #projectiles, 1, -1 do
		local flight = projectiles[index]
		local ok, done = pcall(stepFlight, flight, now)
		if not ok then
			log(flight.weapon.Id .. " flight failed: " .. tostring(done))
			done = true
		end
		if done then
			table.remove(projectiles, index)
		end
	end
end)

-- The model's own radius (the build stamps HeroModelRadius on the Tool), never smaller than the weapon's HitRadius.
local function modelRadius(tool, weapon)
	local stamped = tool:GetAttribute("HeroModelRadius")
	local configured = tonumber(weapon.HitRadius) or 1.2
	return if type(stamped) == "number" then math.clamp(stamped, configured, configured * 1.6) else configured
end

local function launchAimed(player, tool, root, weapon)
	local aim, seq = aimOf(player, tool, root)
	local origin = HeroWeapons.ThrowOrigin(root.CFrame, aim)
	local raycast = wallRaycaster(player)
	local finish = HeroWeapons.AimEnd(weapon, origin, aim, raycast)
	local distance = (finish - origin).Magnitude
	local returns = weapon.Kind == "Boomerang"
	projectileSerial += 1
	local path = {
		Origin = origin,
		End = finish,
		Side = if returns then 1 else -1, -- the shield bows right (and comes back on the left), the batarang left
		Curve = if weapon.Kind == "Shot" then 0 else (tonumber(weapon.Curve) or 0),
		OutTime = HeroWeapons.Travel(weapon, distance),
		Returns = returns,
		BackTime = if returns then HeroWeapons.Travel(weapon, distance, weapon.ReturnSpeed) else nil,
	}
	fireBatFx({
		Action = "Launch",
		Attacker = player,
		Weapon = weapon.Id,
		Id = projectileSerial,
		Seq = seq,
		Origin = path.Origin,
		End = path.End,
		Side = path.Side,
		Curve = path.Curve,
		OutTime = path.OutTime,
		Returns = path.Returns,
		BackTime = path.BackTime,
	})
	table.insert(projectiles, {
		id = projectileSerial,
		player = player,
		weapon = weapon,
		path = path,
		started = os.clock(),
		last = origin,
		hit = {},
		hits = 0,
		maxHits = if weapon.Kind == "Boomerang" then (tonumber(weapon.MaxTargets) or 3) else 1,
		hitRadius = modelRadius(tool, weapon),
		forward = flatUnit(finish - origin, Vector3.new(0, 0, -1)),
		raycast = raycast,
	})
end

-- Training dummies (the admin panel's HeroWeaponDummy models, owner 2026-09-27: "the dummy bugs, it stays weird"):
-- no client moves them, so the server keeps them on their feet between hits (no trip / physics states: only
-- ragdollDummy turns Physics on while it lies limp) and eases them back upright on their spot a moment after every
-- state or lucky shove. A ragdolled, stunned or settling dummy is left alone.
local dummyHomes = setmetatable({}, { __mode = "k" }) -- [model] = its root's upright CFrame where it was placed
local DUMMY_TRIP_STATES = { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll,
	Enum.HumanoidStateType.Physics, Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.PlatformStanding }

local function watchDummy(model)
	if not model:IsA("Model") or dummyHomes[model] ~= nil then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and root:IsA("BasePart")) then
		return
	end
	for _, state in ipairs(DUMMY_TRIP_STATES) do
		pcall(humanoid.SetStateEnabled, humanoid, state, false)
	end
	local _, yaw = root.CFrame:ToOrientation()
	dummyHomes[model] = CFrame.new(root.Position) * CFrame.fromOrientation(0, yaw, 0)
end

local DUMMY_SETTLE_SECONDS = 0.45
local settling = setmetatable({}, { __mode = "k" }) -- [dummy] = true while it eases back up

-- Eases the dummy from where it lies back up onto its spot (the root carries the whole rig: its joints are back on).
-- Round 11 (owner 2026-09-27: "the dummy still does not recover well from the ragdoll"): the root is anchored for the
-- ease, so neither the Humanoid's balance nor a leftover tumble fights it, and every part stops dead at the end.
settleDummy = function(model, root)
	local home = dummyHomes[model]
	if not home or settling[model] then
		return
	end
	settling[model] = true
	local function still()
		return root.Parent ~= nil and debuffs[model] == nil and dummyRagdolls[model] == nil
	end
	local function stopParts()
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
	root.Anchored = true
	stopParts()
	local from = root.CFrame
	local startedAt = os.clock()
	while still() do
		local alpha = math.clamp((os.clock() - startedAt) / DUMMY_SETTLE_SECONDS, 0, 1)
		local eased = 1 - (1 - alpha) * (1 - alpha)
		model:PivotTo(from:Lerp(home, eased) * root.CFrame:ToObjectSpace(model:GetPivot()))
		if alpha >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	stopParts()
	if root.Parent then
		root.Anchored = false
		pcall(root.SetNetworkOwner, root, nil)
	end
	settling[model] = nil
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and still() then
		pcall(humanoid.ChangeState, humanoid, Enum.HumanoidStateType.Running)
	end
end

if HeroWeapons then
	CollectionService:GetInstanceAddedSignal(HeroWeapons.DUMMY_TAG):Connect(function(model)
		task.defer(watchDummy, model) -- after the panel placed and parented it
	end)
	for _, model in ipairs(CollectionService:GetTagged(HeroWeapons.DUMMY_TAG)) do
		watchDummy(model)
	end
	task.spawn(function()
		while true do
			task.wait(0.3)
			local now = os.clock()
			for model, home in pairs(dummyHomes) do
				local root = model.Parent and model:FindFirstChild("HumanoidRootPart")
				if not root then
					dummyHomes[model] = nil
				elseif debuffs[model] == nil and dummyRagdolls[model] == nil and not settling[model]
					and now >= (dummyCalmAt[model] or 0) then
					local tilted = root.CFrame.UpVector.Y < 0.95
					local away = (root.Position - home.Position).Magnitude > 0.75
					if tilted or away then
						task.spawn(function()
							local ok, err = pcall(settleDummy, model, root)
							if not ok then
								settling[model] = nil
								log("training dummy reset failed: " .. tostring(err))
							end
						end)
					end
				end
			end
		end
	end)
end

-- The Impact keyframe of the attack clip: pick the victims by the weapon's kind.
local function resolveWeaponContact(player, tool, character, startedAt, weapon, impact)
	if player.Parent == nil or os.clock() - startedAt < impact - 0.02 then
		return
	end
	local current, _, root = characterOf(player)
	if current ~= character or tool.Parent ~= character or not canSwing(player, character) then
		return -- died, respawned, put the weapon away, got stunned or grabbed an egg during the wind-up
	end
	if not isOnGameplaySide(root.Position) then
		return
	end
	local kind = weapon.Kind
	local maxTargets = tonumber(weapon.MaxTargets) or 1
	if weapon.Aimed then
		launchAimed(player, tool, root, weapon)
	elseif kind == "Slam" then
		local forward = flatUnit(root.CFrame.LookVector, Vector3.new(0, 0, -1))
		local centre = root.Position + forward * (tonumber(weapon.Reach) or 3)
		local targets = weaponTargets(player, root, weapon, tonumber(weapon.Radius) or 10, -1, maxTargets, centre)
		for _, target in ipairs(targets) do
			landWeaponHit(player, root.CFrame, target.player, weapon, target.away)
		end
	elseif kind == "Spin" then
		-- the extended pole sweeps a full turn: everyone within its length, flung along the sweep
		local targets = weaponTargets(player, root, weapon, tonumber(weapon.Radius) or 12, -1, maxTargets, root.Position)
		for _, target in ipairs(targets) do
			local away = target.away
			local tangent = Vector3.new(-away.Z, 0, away.X)
			landWeaponHit(player, root.CFrame, target.player, weapon, flatUnit(away + tangent * 0.6, away))
		end
	else -- Thrust (the punch / pole axis) and Blast (away from the attacker)
		local targets, forward = weaponTargets(player, root, weapon, weapon.Range, weapon.MinDot,
			if kind == "Blast" then maxTargets else 1)
		for _, target in ipairs(targets) do
			local heading = if kind == "Thrust" then forward else target.away
			landWeaponHit(player, root.CFrame, target.player, weapon, heading)
		end
	end
end

local function onHeroWeaponActivated(player, tool, weapon)
	local now = os.clock()
	local cooldown = tonumber(weapon.Cooldown) or MELEE_COOLDOWN
	if now - (lastSwingAt[player] or -math.huge) < cooldown - MELEE_COOLDOWN_SLACK then
		return
	end
	local character, _, root = characterOf(player)
	if not character or tool.Parent ~= character or not canSwing(player, character) then
		return
	end
	if not isOnGameplaySide(root.Position) then
		return
	end
	lastSwingAt[player] = now

	tool:SetAttribute("CooldownActive", true)
	tool:SetAttribute("CooldownDuration", cooldown)
	task.delay(cooldown, function()
		if tool.Parent then
			tool:SetAttribute("CooldownActive", false)
			tool:SetAttribute("CooldownDuration", 0)
		end
	end)

	local impact, length = HeroWeapons.Timing(weapon.Id)
	swingSerial += 1
	fireBatFx({
		Action = "Swing",
		Attacker = player,
		Id = swingSerial,
		Weapon = weapon.Id,
		WindUp = impact,
		Duration = length,
	})
	task.delay(impact, function()
		local ok, err = pcall(resolveWeaponContact, player, tool, character, now, weapon, impact)
		if not ok then
			log(tool.Name .. " (" .. weapon.Id .. ") contact failed: " .. tostring(err))
		end
	end)
end

local function onMeleeActivated(player, tool)
	local weapon = heroWeaponOf(tool)
	if weapon then
		onHeroWeaponActivated(player, tool, weapon)
		return
	end
	local now = os.clock()
	if now - (lastSwingAt[player] or -math.huge) < MELEE_COOLDOWN - MELEE_COOLDOWN_SLACK then
		return
	end

	local character, _, root = characterOf(player)
	if not character or tool.Parent ~= character or not canSwing(player, character) then
		return
	end
	if not isOnGameplaySide(root.Position) then
		return -- ToolGameplayGuard already told the player gear does not work in the safe zone
	end
	lastSwingAt[player] = now

	tool:SetAttribute("CooldownActive", true)
	tool:SetAttribute("CooldownDuration", MELEE_COOLDOWN)
	task.delay(MELEE_COOLDOWN, function()
		if tool.Parent then
			tool:SetAttribute("CooldownActive", false)
			tool:SetAttribute("CooldownDuration", 0)
		end
	end)

	swingSerial += 1
	fireBatFx({ Action = "Swing", Attacker = player, Id = swingSerial, WindUp = SWING_WINDUP, Duration = SWING_DURATION })
	task.delay(SWING_WINDUP, function()
		local ok, err = pcall(resolveSwingContact, player, tool, character, now)
		if not ok then
			log(tool.Name .. " swing contact failed: " .. tostring(err))
		end
	end)
end

----------------------------------------------------------------------------------------------------
-- Traps: place one at your feet; the first other player to walk into it is frozen
----------------------------------------------------------------------------------------------------

local lastPlacedAt = {}

local function trapFolder()
	local folder = Workspace:FindFirstChild(TRAP_FOLDER)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = TRAP_FOLDER
		folder.Parent = Workspace
	end
	return folder
end

local function activeTrapCount(player)
	local count = 0
	for _, trap in ipairs(CollectionService:GetTagged(TAG_PLACED_TRAP)) do
		if trap.Parent and trap:GetAttribute("Owner") == player.Name then
			count += 1
		end
	end
	return count
end

-- The hotbar (BackpackController) shows "x<Uses>" on gear whose config has an ActiveDeploymentAttribute (the
-- traps). Uses = traps this player can still place (maxActive - placed), kept on every trap tool they hold.
local function setTrapUses(tool, active)
	if tool:IsA("Tool") then
		local spec = TRAP_GEAR[tool:GetAttribute("GearName") or tool.Name]
		if spec then
			tool:SetAttribute("Uses", math.max(spec.maxActive - active, 0))
		end
	end
end

local function refreshTrapCount(player)
	if player.Parent then
		local active = activeTrapCount(player)
		player:SetAttribute(ACTIVE_TRAP_ATTRIBUTE, active)
		for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character, player:FindFirstChildOfClass("StarterGear") }) do
			for _, tool in ipairs(container and container:GetChildren() or {}) do
				setTrapUses(tool, active)
			end
		end
	end
end

local function groundBelow(root, character)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, trapFolder() }
	params.RespectCanCollide = true
	local origin = root.Position + root.CFrame.LookVector * 4
	local result = Workspace:Raycast(origin + Vector3.new(0, 4, 0), Vector3.new(0, -24, 0), params)
	return result and result.Position or (origin - Vector3.new(0, root.Size.Y / 2 + 2, 0))
end

local trapReleases = setmetatable({}, { __mode = "k" }) -- [character] = release() of the running freeze

local function freezeVictim(trap, victim, freezeSeconds)
	local character, humanoid = characterOf(victim)
	if not character or character:GetAttribute("IsTrapped") == true then
		return false
	end

	local walkSpeed, jumpPower, jumpHeight = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight
	-- A hero weapon state still slowing the victim (Dazed / SmokeStun, or pushed onto the trap by a knockback): the
	-- trap takes the movement over with the victim's real values, and the state no longer restores anything (review:
	-- it used to free the victim mid-freeze, and the trap then gave back the slowed speed for good).
	local debuff = debuffs[character]
	if debuff and debuff.moved and not debuff.restored then
		walkSpeed, jumpPower, jumpHeight = debuff.walkSpeed, debuff.jumpPower, debuff.jumpHeight
		humanoid.AutoRotate = debuff.autoRotate
		debuff.restored = true
	end
	character:SetAttribute("IsTrapped", true)
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0

	local released = false
	local function release()
		if released then
			return
		end
		released = true
		if trapReleases[character] == release then
			trapReleases[character] = nil
		end
		if humanoid.Parent then
			humanoid.WalkSpeed = walkSpeed > 0 and walkSpeed or 16
			humanoid.JumpPower = jumpPower > 0 and jumpPower or 50
			humanoid.JumpHeight = jumpHeight > 0 and jumpHeight or 7.2
		end
		if character.Parent then
			character:SetAttribute("IsTrapped", false)
		end
		if trap.Parent then
			trap:Destroy()
		end
	end
	trapReleases[character] = release

	local diedConnection
	diedConnection = humanoid.Died:Connect(function()
		if diedConnection then
			diedConnection:Disconnect()
		end
		release()
	end)

	task.delay(freezeSeconds, function()
		if diedConnection then
			diedConnection:Disconnect()
		end
		release()
	end)
	return true
end

local function placeTrap(player, tool, spec)
	if not toolEffects then
		return
	end
	local template = toolEffects:FindFirstChild(spec.template)
	if not template or not template:IsA("BasePart") then
		log("missing trap template " .. spec.template)
		return
	end

	local now = os.clock()
	if (lastPlacedAt[player] or 0) + spec.cooldown > now then
		return
	end

	local character, _, root = characterOf(player)
	if not character or not canSwing(player, character) then -- trapped, ragdolled or carrying an egg
		return
	end
	if not isOnGameplaySide(root.Position) then
		return -- ToolGameplayGuard already told the player gear does not work in the safe zone
	end
	if activeTrapCount(player) >= spec.maxActive then
		return
	end
	lastPlacedAt[player] = now

	-- Owner 2026-09-27: "the traps don't work". Every part of the clone is anchored, and it is moved before it has a
	-- parent, so its WeldConstraint never dragged the touch Hitbox along: every placed trap's Hitbox stayed where the
	-- template sits (in the lobby, freezing people there) while the visible trap on the stage caught nobody. Each
	-- child now keeps its offset from the trap and is moved with it explicitly; the (useless) welds are removed.
	local trap = template:Clone() -- whole subtree in one Clone, never child by child
	local pivot = trap.CFrame
	local offsets = {}
	for _, descendant in ipairs(trap:GetDescendants()) do
		if descendant:IsA("BasePart") then
			offsets[descendant] = pivot:ToObjectSpace(descendant.CFrame)
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = true
		elseif descendant:IsA("LuaSourceContainer") or descendant:IsA("Sound") or descendant:IsA("WeldConstraint")
			or descendant:IsA("JointInstance") then
			descendant:Destroy() -- everything is anchored: a weld would only mislead
		end
	end
	trap.Anchored = true
	trap.CanCollide = false
	trap.CanTouch = true
	trap.Name = tool.Name .. "_" .. player.Name

	local position = groundBelow(root, character)
	local _, yaw = root.CFrame:ToOrientation()
	trap.CFrame = CFrame.new(position + Vector3.new(0, trap.Size.Y / 2, 0)) * CFrame.Angles(0, yaw, 0)
	for part, offset in pairs(offsets) do
		if part.Parent then
			part.CFrame = trap.CFrame * offset
		end
	end

	trap:SetAttribute("Owner", player.Name)
	trap:SetAttribute("TrapActive", false)
	trap:SetAttribute("GearName", tool.Name)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UnplacePrompt"
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = tool.Name
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = trap
	CollectionService:AddTag(prompt, TAG_UNPLACE_PROMPT)
	prompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer == player and trap:GetAttribute("TrapActive") ~= true then
			trap:Destroy()
		end
	end)

	local hitbox = trap:FindFirstChild("Hitbox") or trap:FindFirstChild("Part") or trap
	if not hitbox:IsA("BasePart") then
		hitbox = trap
	end
	hitbox.Touched:Connect(function(hit)
		if trap:GetAttribute("TrapActive") == true or not trap.Parent then
			return
		end
		local victimCharacter = hit and hit.Parent
		local victim = victimCharacter and Players:GetPlayerFromCharacter(victimCharacter)
		if not victim and hit then
			-- an accessory / tool part touched it first: its character is further up
			victimCharacter = hit:FindFirstAncestorOfClass("Model")
			victim = victimCharacter and Players:GetPlayerFromCharacter(victimCharacter)
		end
		if not victim or victim == player then
			return
		end
		if not isOnGameplaySide(hitbox.Position) then
			return -- a trap never freezes anyone in the safe zone
		end
		trap:SetAttribute("TrapActive", true)
		if freezeVictim(trap, victim, spec.freeze) then
			dropCarriedEggOf(victim, player, trap.CFrame, "TrapHit")
		else
			trap:SetAttribute("TrapActive", false)
		end
	end)

	trap.Destroying:Connect(function()
		task.defer(refreshTrapCount, player)
	end)

	CollectionService:AddTag(trap, TAG_PLACED_TRAP)
	trap.Parent = trapFolder()
	refreshTrapCount(player)

	task.delay(TRAP_LIFETIME, function()
		if trap.Parent and trap:GetAttribute("TrapActive") ~= true then
			trap:Destroy()
		end
	end)
end

----------------------------------------------------------------------------------------------------
-- Tool wiring
----------------------------------------------------------------------------------------------------

local hookedTools = setmetatable({}, { __mode = "k" })

local function hookTool(player, tool)
	if not tool:IsA("Tool") or hookedTools[tool] then
		return
	end
	local trapSpec = TRAP_GEAR[tool.Name]
	if not (MELEE_GEAR[tool.Name] or trapSpec) then
		return
	end
	hookedTools[tool] = true
	tool.ManualActivationOnly = false
	if trapSpec then
		setTrapUses(tool, activeTrapCount(player))
	elseif WeaponKit and heroWeaponOf(tool) then
		-- the owner's kit grips the weapon in the R15 right hand once the engine made the RightGrip
		tool.Equipped:Connect(function()
			task.spawn(function()
				local character = player.Character
				if character and tool.Parent == character then
					local ok, err = pcall(WeaponKit.Attach, tool, character)
					if not ok then
						log(tool.Name .. " grip failed: " .. tostring(err))
					end
				end
			end)
		end)
	end
	tool.Activated:Connect(function()
		if player.Parent == nil then
			return
		end
		local ok, err = pcall(function()
			if trapSpec then
				placeTrap(player, tool, trapSpec)
			else
				onMeleeActivated(player, tool)
			end
		end)
		if not ok then
			log(tool.Name .. " activation failed: " .. tostring(err))
		end
	end)
end

local function hookContainer(player, container)
	if not container then
		return
	end
	for _, child in ipairs(container:GetChildren()) do
		hookTool(player, child)
	end
	container.ChildAdded:Connect(function(child)
		hookTool(player, child)
	end)
end

----------------------------------------------------------------------------------------------------
-- Carrier rules: no tools while carrying a stolen egg
----------------------------------------------------------------------------------------------------

-- Put an equipped Tool back in the Backpack while its owner carries an egg. Deferred: the engine refuses a reparent
-- from inside the ChildAdded that equipped it. (The client's own "CarriedEgg" hand Tool exists only on that client.)
local function stowIfCarrying(player, tool)
	task.defer(function()
		local character = player.Character
		if isCarrying(player) and character ~= nil and tool.Parent == character then
			local backpack = player:FindFirstChildOfClass("Backpack")
			if backpack then
				tool.Parent = backpack
			end
		end
	end)
end

local function stowAllIfCarrying(player)
	local character = player.Character
	for _, child in ipairs(character and character:GetChildren() or {}) do
		if child:IsA("Tool") then
			stowIfCarrying(player, child)
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Starter gear (D3): Bat + Trap in the Backpack and in StarterGear, exactly one of each
----------------------------------------------------------------------------------------------------

-- The attributes the base game's gear UI keys off (the Trap template ships without them).
local function prepareGearTool(tool, gearName)
	tool:SetAttribute("GearName", gearName)
	tool:SetAttribute("ItemType", "Gear")
	tool.CanBeDropped = false -- D3: no gear lying on the lobby floor
	-- NPC pass 2026-09-26 (owner: "invisible places that block you from walking"): a held tool is part of the
	-- character, and the slap family ships a CanCollide Handle plus an invisible 1 x 4.5 x 2.5 CanCollide block that
	-- snagged doorways / pushed other players. Melee hits are distance checks (findSwingVictim) and traps are placed
	-- as their own non-colliding clone, so no gear part needs to collide.
	for _, descendant in ipairs(tool:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
		end
	end
end

-- Copies of `gearName`. (The stage bat templates ship with GearName = "Bat"; ensureStarterGear removes every bat but
-- the kit's one first and prepareGearTool renames the attribute, so a stage bat never counts as the plain Bat.)
local function gearToolsIn(container, gearName, out)
	if container then
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and (child.Name == gearName or child:GetAttribute("GearName") == gearName) then
				table.insert(out, child)
			end
		end
	end
	return out
end

-- Profile access (ServerScriptService.Library.Database), resolved in the background further down; nil until then
-- (the kit is then the plain Bat + Trap and stage-bat requests answer "Profile not loaded").
local database = nil

local function profileOf(player)
	if database == nil then
		return nil
	end
	local ok, profile = pcall(database.Get, player)
	if not ok or type(profile) ~= "table" then
		return nil
	end
	if type(database.IsPlayerLoaded) == "function" and database.IsPlayerLoaded(player) ~= true then
		return nil -- never read or write a profile that is still loading
	end
	return profile
end

local function batTemplate(batName)
	local template = shopItems and shopItems:FindFirstChild(batName)
	if template and template:IsA("Tool") then
		return template
	end
	return nil
end

-- true when the profile owns the stage bat (recorded by its first Index equip).
local function ownsBat(profile, batName)
	if batName == DEFAULT_BAT then
		return true
	end
	local inventory = type(profile) == "table" and profile.GearInventory
	return type(inventory) == "table" and (tonumber(inventory[batName]) or 0) >= 1
end

-- The melee tool of the player's kit: their equipped, owned, existing stage bat, else the plain Bat.
local function equippedBatOf(player)
	local profile = profileOf(player)
	local batName = profile and profile[EQUIPPED_BAT_FIELD]
	if type(batName) == "string" and batName ~= "" and MELEE_GEAR[batName] and ownsBat(profile, batName)
		and batTemplate(batName) then
		return batName
	end
	return DEFAULT_BAT
end

local function kitFor(player)
	local kit = table.clone(STARTER_GEAR)
	kit[1] = equippedBatOf(player)
	return kit
end

-- Deals `kit` (default STARTER_GEAR; kit[1] is the melee slot). With `meleeGear` (a set of melee tool names), every
-- other melee tool first leaves StarterGear, the Backpack and the hand: one bat at a time (an Index equip / unequip
-- swap, or a copy Roblox re-gave from an older StarterGear).
local function ensureStarterGear(player, kit, meleeGear)
	if not shopItems or player.Parent == nil then
		return
	end
	kit = kit or STARTER_GEAR
	local starterGear = player:FindFirstChildOfClass("StarterGear")
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	if meleeGear then
		-- indexed, not ipairs: any of the three may be nil (a missing StarterGear must not skip the Backpack / hand)
		local containers = { starterGear, backpack, character }
		for slot = 1, 3 do
			local container = containers[slot]
			for _, child in ipairs(container and container:GetChildren() or {}) do
				if child:IsA("Tool") and meleeGear[child.Name] and child.Name ~= kit[1] then
					child:Destroy()
				end
			end
		end
	end
	for _, gearName in ipairs(kit) do
		local template = shopItems:FindFirstChild(gearName)
		if not (template and template:IsA("Tool")) then
			log("starter gear '" .. gearName .. "' is not a Tool in GearTools.ShopItems")
			continue
		end
		-- StarterGear: one copy, which Roblox puts in every new Backpack on respawn.
		if starterGear then
			local copies = gearToolsIn(starterGear, gearName, {})
			if #copies == 0 then
				local copy = template:Clone() -- whole subtree in one Clone
				prepareGearTool(copy, gearName)
				copy.Parent = starterGear
			else
				for index = 2, #copies do
					copies[index]:Destroy()
				end
			end
		end
		-- Live copy: one across Character (an equipped tool, kept first) + Backpack.
		if backpack then
			local live = gearToolsIn(character, gearName, {})
			gearToolsIn(backpack, gearName, live)
			if #live == 0 then
				local tool = template:Clone()
				prepareGearTool(tool, gearName)
				tool.Parent = backpack
				hookTool(player, tool)
			else
				for index = 2, #live do
					live[index]:Destroy()
				end
				prepareGearTool(live[1], gearName)
			end
		end
	end
end

local function ensureStarterGearSafe(player)
	local ok, err = pcall(function()
		ensureStarterGear(player, kitFor(player), MELEE_GEAR)
	end)
	if not ok then
		log("starter gear for " .. player.Name .. " failed: " .. tostring(err))
	end
end

-- The profile's GearInventory marks the kit as owned (the base game's Index / gear shop read it).
task.spawn(function()
	local library = ServerScriptService:WaitForChild("Library", 30)
	local module = library and library:WaitForChild("Database", 30)
	if not (module and module:IsA("ModuleScript")) then
		log("ServerScriptService.Library.Database not found - the starter gear is not recorded in GearInventory.")
		return
	end
	local ok, Database = pcall(require, module)
	if not (ok and type(Database) == "table" and type(Database.OnLoaded) == "function") then
		log("Database unavailable, the starter gear is not recorded in GearInventory: " .. tostring(Database))
		return
	end
	if type(Database.Get) == "function" and type(Database.Set) == "function" then
		database = Database
	else
		log("Database has no Get / Set - Index stage bats cannot be equipped.")
	end
	Database.OnLoaded(function(player, profile)
		local inventory = type(profile) == "table" and profile.GearInventory
		if type(inventory) ~= "table" then
			return
		end
		local changes = nil
		for _, gearName in ipairs(STARTER_GEAR) do
			if (tonumber(inventory[gearName]) or 0) < 1 then
				inventory[gearName] = 1
				changes = { GearInventory = inventory }
			end
		end
		-- a saved stage bat that is not owned (or no longer exists) falls back to the plain Bat
		local equipped = profile[EQUIPPED_BAT_FIELD]
		if equipped ~= nil and (type(equipped) ~= "string" or (equipped ~= "" and not (MELEE_GEAR[equipped]
			and ownsBat(profile, equipped) and batTemplate(equipped)))) then
			changes = changes or {}
			changes[EQUIPPED_BAT_FIELD] = ""
		end
		if changes and type(Database.Set) == "function" then
			pcall(Database.Set, player, changes)
		end
		-- the kit was handed out before the profile loaded: swap the plain Bat for the equipped stage bat now
		ensureStarterGearSafe(player)
	end)
end)

----------------------------------------------------------------------------------------------------
-- Index stage bats: Network["Index: RequestEquipAreaBat"](sectionId, "Equip" | "Unequip")
----------------------------------------------------------------------------------------------------

-- Directory.Areas (stage configs: DropTable + IndexBatGearId) and Directory.Assets (hero configs), required on the
-- first request and cached once both load; a missing or failing directory refuses the request instead of erroring.
local areaDirectories = nil

local function loadDirectoryTable(name)
	local directory = ReplicatedStorage:FindFirstChild("Directory")
	local module = directory and directory:FindFirstChild(name)
	if not (module and module:IsA("ModuleScript")) then
		log("Directory." .. name .. " is missing - Index stage bats cannot be validated.")
		return nil
	end
	local ok, result = pcall(require, module)
	if ok and type(result) == "table" and type(result.Directory) == "table" then
		return result.Directory
	end
	log("Directory." .. name .. " failed to load - Index stage bats cannot be validated: " .. tostring(result))
	return nil
end

local function getAreaDirectories()
	if areaDirectories == nil then
		local areas, assets = loadDirectoryTable("Areas"), loadDirectoryTable("Assets")
		if areas == nil or assets == nil then
			return nil, nil
		end
		areaDirectories = { Areas = areas, Assets = assets }
	end
	return areaDirectories.Areas, areaDirectories.Assets
end

-- Directory.StageArt lists the stages the Index shows (GUI.Index skips every other Directory.Areas zone once it
-- loads). The retired zones (Prehistoric, Cosmic, Abyss Ocean) keep an Areas entry with a stronger bat, but no card
-- ever offers it, so a crafted request must not unlock or equip it either (review fix). Loaded on the first request;
-- false when it cannot load, and then every area counts, exactly like the Index page without StageArt.
local stageArt = nil

local function isIndexStage(key)
	if stageArt == nil then
		stageArt = false
		local directory = ReplicatedStorage:FindFirstChild("Directory")
		local module = directory and directory:FindFirstChild("StageArt")
		local ok, result = false, "missing"
		if module and module:IsA("ModuleScript") then
			ok, result = pcall(require, module)
		end
		if ok and type(result) == "table" and type(result.Get) == "function" then
			stageArt = result
		else
			log("Directory.StageArt unavailable - every Directory.Areas stage may equip its bat: " .. tostring(result))
		end
	end
	if stageArt == false then
		return true
	end
	local ok, stage = pcall(stageArt.Get, key)
	return ok and type(stage) == "table"
end

-- Both directories are strict tables (an unknown key errors): every lookup is guarded.
local function directoryEntry(directoryTable, key)
	if directoryTable == nil or type(key) ~= "string" then
		return nil
	end
	local ok, entry = pcall(function()
		return directoryTable[key]
	end)
	return if ok and type(entry) == "table" then entry else nil
end

-- (discovered, total) of a stage's Index, counted exactly like the Index page (GUI.Index _buildEntries): the area's
-- DropTable heroes that have an Assets config, a positive drop weight and no DontRoll.
local function areaIndexProgress(profile, area)
	local _, assets = getAreaDirectories()
	local dropTable = area.DropTable
	if assets == nil or type(dropTable) ~= "table" then
		return 0, 0
	end
	local index = if type(profile.Index) == "table" then profile.Index else {}
	local found, total = 0, 0
	for _, entry in dropTable do
		local heroId = type(entry) == "table" and entry[1] or nil
		local weight = type(entry) == "table" and entry[2] or nil
		local config = directoryEntry(assets, heroId)
		if config ~= nil and type(weight) == "number" and weight > 0 and config.DontRoll ~= true then
			total += 1
			if index[heroId] == true then
				found += 1
			end
		end
	end
	return found, total
end

local function batDisplayName(batName)
	local weaponId = HeroWeapons and HeroWeapons.IdOfToolName(batName)
	local weapon = weaponId and HeroWeapons.Get(weaponId)
	if weapon then
		return weapon.DisplayName -- the stage bats are hero weapons now
	end
	local ok, name = pcall(function()
		local entry = gearDirectory and gearDirectory[batName]
		return entry and entry.DisplayName
	end)
	return if ok and type(name) == "string" and name ~= "" then name else batName
end

local function heldMeleeTool(player)
	local character = player.Character
	for _, child in ipairs(character and character:GetChildren() or {}) do
		if child:IsA("Tool") and MELEE_GEAR[child.Name] then
			return child
		end
	end
	return nil
end

-- Re-deals the kit after profile.EquippedBat changed. A bat that was in hand is replaced in hand, unless the player
-- carries an egg (then it stays in the Backpack, like every tool of a carrier).
local function swapKitBat(player)
	local wasHolding = heldMeleeTool(player) ~= nil
	ensureStarterGearSafe(player)
	if not wasHolding or isCarrying(player) or heldMeleeTool(player) ~= nil then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChildOfClass("Backpack")
	local tool = backpack and backpack:FindFirstChild(equippedBatOf(player))
	if humanoid and humanoid.Health > 0 and tool and tool:IsA("Tool") then
		pcall(humanoid.EquipTool, humanoid, tool)
	end
end

local lastAreaBatRequestAt = {} -- [player] = os.clock() of the last accepted request

-- -> (ok, err?, equippedBat) where equippedBat is the profile's EquippedBat after the request ("" = the plain Bat).
local function onEquipAreaBat(player, sectionId, action)
	if type(sectionId) ~= "string" or #sectionId == 0 or #sectionId > MAX_SECTION_ID_LENGTH then
		return false, "Invalid stage"
	end
	if action == nil then
		action = "Equip"
	end
	if action ~= "Equip" and action ~= "Unequip" then
		return false, "Invalid action"
	end
	local now = os.clock()
	if now - (lastAreaBatRequestAt[player] or -math.huge) < AREA_BAT_REQUEST_COOLDOWN then
		return false, "Too fast"
	end
	lastAreaBatRequestAt[player] = now

	local profile = profileOf(player)
	if profile == nil then
		return false, "Profile not loaded"
	end
	local areas = getAreaDirectories()
	local area = directoryEntry(areas, sectionId)
	local batName = area and area.IndexBatGearId
	if type(batName) ~= "string" or not MELEE_GEAR[batName] or batTemplate(batName) == nil then
		return false, "This stage has no bat"
	end
	-- only a stage the Index lists (see isIndexStage); unequipping stays possible from any stage key
	if action == "Equip" and not isIndexStage(sectionId) then
		return false, "Invalid stage"
	end
	local current = profile[EQUIPPED_BAT_FIELD]
	if type(current) ~= "string" then
		current = ""
	end
	local displayName = batDisplayName(batName)

	if action == "Unequip" then
		if current == batName then
			database.Set(player, { [EQUIPPED_BAT_FIELD] = "" })
			swapKitBat(player)
			notify(player, displayName .. " unequipped: back to the " .. batDisplayName(DEFAULT_BAT) .. ".", NOTICE_GOOD)
			current = ""
		end
		return true, nil, current
	end

	local changes = {}
	if not ownsBat(profile, batName) then
		local found, total = areaIndexProgress(profile, area)
		if total == 0 or found < total then
			notify(player, string.format("Discover every hero of this stage to unlock the %s! (%d/%d)", displayName,
				found, total), NOTICE_BAD)
			return false, "Stage Index not complete"
		end
		local inventory = if type(profile.GearInventory) == "table" then profile.GearInventory else {}
		inventory[batName] = 1
		changes.GearInventory = inventory
	end
	local visited = if type(profile.VisitedGears) == "table" then profile.VisitedGears else {}
	if visited[batName] ~= true then
		visited[batName] = true
		changes.VisitedGears = visited
	end
	if current ~= batName then
		changes[EQUIPPED_BAT_FIELD] = batName
	end
	if next(changes) ~= nil then
		database.Set(player, changes)
	end
	swapKitBat(player)
	if current ~= batName then
		notify(player, displayName .. " equipped!", NOTICE_GOOD)
	end
	return true, nil, batName
end

task.spawn(function()
	-- StubService answers this remote with "Not available" and Bootstrap requires it last, i.e. possibly after this
	-- Script bound the real handler. A ModuleScript body runs only once, so requiring it here first means its
	-- placeholder is set before ours and can never overwrite it afterwards (same as TrailService).
	local controllers = ServerScriptService:WaitForChild("Controllers", 30)
	local stub = controllers and controllers:WaitForChild("StubService", 30)
	if stub and stub:IsA("ModuleScript") then
		local ok, err = pcall(require, stub)
		if not ok then
			log("StubService failed to load first: " .. tostring(err))
		end
	end
	local remote = network:FindFirstChild(EQUIP_AREA_BAT_REMOTE_NAME)
	if remote == nil then
		remote = Instance.new("RemoteFunction")
		remote.Name = EQUIP_AREA_BAT_REMOTE_NAME
		remote.Parent = network
	elseif not remote:IsA("RemoteFunction") then
		log("Network['" .. EQUIP_AREA_BAT_REMOTE_NAME .. "'] is a " .. remote.ClassName .. " - Index bats cannot be equipped.")
		return
	end
	remote.OnServerInvoke = function(player, sectionId, action)
		local ok, success, err, equipped = pcall(onEquipAreaBat, player, sectionId, action)
		if not ok then
			log("Index bat request failed for " .. player.Name .. ": " .. tostring(success))
			return false, "Server error"
		end
		return success, err, equipped
	end
end)

-- Studio-only test hook (never in a live server), like IndexService's DevUnlockBaseThemes. From the server command bar
--   game.Players.<you>:SetAttribute("DevCompleteIndex", "Forest")   -- a Directory.Areas key, or "all"
-- marks every hero of that stage discovered, so its Index card shows the stage bat's EQUIP button at once.
local devIndexConnections = {} -- [player] = RBXScriptConnection
local function watchDevCompleteIndex(player)
	devIndexConnections[player] = player:GetAttributeChangedSignal("DevCompleteIndex"):Connect(function()
		local key = player:GetAttribute("DevCompleteIndex")
		local profile = profileOf(player)
		local areas = getAreaDirectories()
		if type(key) ~= "string" or key == "" or profile == nil or areas == nil then
			return
		end
		local index = if type(profile.Index) == "table" then profile.Index else {}
		local ok, err = pcall(function()
			for areaKey, area in areas do
				if (key == "all" or areaKey == key) and type(area) == "table" and type(area.DropTable) == "table" then
					for _, entry in area.DropTable do
						if type(entry) == "table" and type(entry[1]) == "string" then
							index[entry[1]] = true
						end
					end
				end
			end
		end)
		if not ok then
			log("DevCompleteIndex failed: " .. tostring(err))
			return
		end
		database.Set(player, { Index = index })
		log("Studio: Index of '" .. key .. "' completed for " .. player.Name)
	end)
end
if RunService:IsStudio() then
	Players.PlayerAdded:Connect(watchDevCompleteIndex)
	for _, player in ipairs(Players:GetPlayers()) do
		watchDevCompleteIndex(player)
	end
end

local function onCharacterAdded(player, character)
	character:SetAttribute("IsTrapped", false)
	character:SetAttribute("BatFlung", false)
	character:SetAttribute("Ragdolled", false)
	hookContainer(player, character)
	hookContainer(player, player:FindFirstChildOfClass("Backpack"))
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and isCarrying(player) then
			stowIfCarrying(player, child)
		end
	end)
	-- Roblox copies StarterGear into the new Backpack around CharacterAdded; check once right after and once
	-- more a moment later so a copy that lands late is de-duplicated instead of doubled.
	task.defer(ensureStarterGearSafe, player)
	task.delay(1, ensureStarterGearSafe, player)
end

local function onPlayerAdded(player)
	player:SetAttribute(ACTIVE_TRAP_ATTRIBUTE, 0)
	player:GetAttributeChangedSignal(CARRY_ATTRIBUTE):Connect(function()
		if isCarrying(player) then
			stowAllIfCarrying(player)
		end
	end)
	player:WaitForChild("StarterGear", 10)
	ensureStarterGearSafe(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player.CharacterRemoving:Connect(function(character)
		ragdolls[character] = nil
		ragdollImmuneUntil[character] = nil
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player)
	lastPlacedAt[player] = nil
	lastAreaBatRequestAt[player] = nil
	if devIndexConnections[player] then
		devIndexConnections[player]:Disconnect()
		devIndexConnections[player] = nil
	end
	for _, trap in ipairs(CollectionService:GetTagged(TAG_PLACED_TRAP)) do
		if trap:GetAttribute("Owner") == player.Name and trap:GetAttribute("TrapActive") ~= true then
			trap:Destroy()
		end
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Server-only entry for the same ragdoll from other systems (owner 2026-09-23: a villain's catch ragdolls the
-- carrier like a bat hit). ServerScriptService.GearRagdollRequest:Invoke(player, direction[, options]) -> true when
-- ragdolled. options (optional table): { Duration = seconds } (default RAGDOLL_DURATION, clamped).
local ragdollRequest = ServerScriptService:FindFirstChild("GearRagdollRequest")
if not (ragdollRequest and ragdollRequest:IsA("BindableFunction")) then
	ragdollRequest = Instance.new("BindableFunction")
	ragdollRequest.Name = "GearRagdollRequest"
	ragdollRequest.Parent = ServerScriptService
end
ragdollRequest.OnInvoke = function(victim, direction, options)
	if typeof(victim) ~= "Instance" or not victim:IsA("Player") or typeof(direction) ~= "Vector3" then
		return false
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.01 then
		return false
	end
	local duration = type(options) == "table" and tonumber(options.Duration) or nil
	local ok, ragdolled = pcall(ragdollVictim, victim, flat.Unit, { Duration = duration })
	return ok and ragdolled == true
end

-- Server-only: lift `player`'s bat ragdoll and trap freeze right now (AreaEggService's night teleport moves players
-- home and must not carry a limp or frozen body). ServerScriptService.GearReleaseRequest:Invoke(player) -> true when
-- something was lifted.
local releaseRequest = ServerScriptService:FindFirstChild("GearReleaseRequest")
if not (releaseRequest and releaseRequest:IsA("BindableFunction")) then
	releaseRequest = Instance.new("BindableFunction")
	releaseRequest.Name = "GearReleaseRequest"
	releaseRequest.Parent = ServerScriptService
end
releaseRequest.OnInvoke = function(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end
	local lifted = false
	if ragdolls[character] ~= nil then
		local ok, err = pcall(endRagdoll, player, character, nil)
		if not ok then
			log("ragdoll release failed for " .. player.Name .. ": " .. tostring(err))
		end
		lifted = true
	end
	local release = trapReleases[character]
	if release then
		pcall(release)
		lifted = true
	end
	if debuffs[character] ~= nil then
		pcall(endDebuff, player, character, nil)
		lifted = true
	end
	return lifted
end
