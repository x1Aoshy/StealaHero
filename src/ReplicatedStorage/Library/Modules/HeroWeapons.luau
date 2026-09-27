--!strict
-- ReplicatedStorage.Library.Modules.HeroWeapons (ModuleScript, injected by scripts/inject/hero_weapons.luau)
-- Owner 2026-09-27 ("MISSION: replace the bat system with Hero Gadgets"): the classic bats become hero weapons. The
-- melee Tools keep their names ("Bat", "Forest Bat"...): the kit, the Index equip, the hotbar slot lock (GearName) and
-- the saves all key off them. scripts/steps/post_hero_weapons.luau rebuilds each Tool's visuals from the part models of
-- assets/hero_weapons/weapon_models.json and tags it with the HeroWeaponId attribute.
--
-- Shared by ServerScriptService.GearService (targeting, timing, the 2.5 s debuff states that replace the bat ragdoll)
-- and StarterPlayerScripts.BranchControllers.HeroWeaponController (the attack clip on every attacker, projectiles,
-- the victim's themed state). Timing comes from the owner's clips (ReplicatedStorage.Directory.WeaponAnimations.<Id>,
-- generated from assets/hero_weapons/animations/*.rbxmx): the hit is resolved at the clip's Impact keyframe.
--
-- Kinds (how GearService picks the victims; every range is from the attacker's root):
--   Slam       up to MaxTargets players around a point Reach studs in front (lag compensated)
--   Spin       up to MaxTargets players all around within Radius (the extended Power Pole sweeping a full turn)
--   Blast      up to MaxTargets players in a cone (lag compensated)
--   Thrust     the nearest player along a narrow line (MinDot, Width studs either side of the line)
--   Boomerang  AIMED: flies out along a curved path to the aim point and comes back to the hand; every rival it passes
--              within HitRadius (the model's own radius, stamped on the Tool by the build as HeroModelRadius) is hit
--              once, at most MaxTargets
--   Grenade    AIMED: flies along a curved path to the aim point and explodes there (or on the first rival it touches,
--              or a wall): every rival within BlastRadius, at most MaxTargets
--   Shot       AIMED: a straight line to the aim point; the first rival within HitRadius of it is hit
-- Aimed weapons: the client sends the aim point (Network["Gear: WeaponAim"]) with the click; the server clamps it
-- (HeroWeapons.AimEnd) and simulates the flight itself (HeroWeapons.PathPoint), every client draws the same path.
-- Effects (the victim's state for Duration seconds; GearService owns movement, the controller draws it):
--   Webbed         frozen standing in a web net, struggling
--   Electrocuted   frozen standing, shaking comically, lightning arcs
--   CleanKnockback slides back standing along the punch (Push studs), then runs back
--   Dazed          stars circling the head, stumbling slowly
--   SmokeStun      a smoke cloud, disoriented and slow, the screen greys out
--   ExplosionBlast a comic explosion pushes them back (Push studs), singed and slow
--   SpinTornado    spins like a top on the spot

local HeroWeapons = {}

HeroWeapons.EFFECT_DURATION = 2.5
HeroWeapons.IMMUNITY = 1.2 -- after a debuff ends, a new hit cannot debuff again for this long (carriers excepted)
HeroWeapons.TOOL_ATTRIBUTE = "HeroWeaponId"
HeroWeapons.DEBUFF_ATTRIBUTE = "HeroDebuff" -- character attribute: the active effect name while debuffed
HeroWeapons.AIM_REMOTE = "Gear: WeaponAim" -- client -> server: (tool, aim point) with an aimed weapon's click
HeroWeapons.DUMMY_TAG = "HeroWeaponDummy" -- CollectionService tag of the admin panel's training dummies (hittable)
HeroWeapons.MIN_AIM_DISTANCE = 6 -- an aim point closer than this still throws this far
HeroWeapons.MAX_AIM_PITCH = math.rad(22) -- a throw never climbs or dives steeper than this

-- Tool name -> weapon (owner's mapping, 2026-09-27). Prehistoric / Abyss Ocean / Admin Bat stay classic bats.
HeroWeapons.BY_TOOL = {
	["Bat"] = "CapShield",
	["Forest Bat"] = "PowerPole",
	["Desert Bat"] = "WebShooter",
	["Lake Bat"] = "Batarang",
	["Jungle Bat"] = "BakugoGauntlet",
	["Snow Bat"] = "Mjolnir",
	["Cosmic Bat"] = "Mjolnir",
	["Volcano Bat"] = "GomuFist",
}

export type Weapon = {
	Id: string,
	DisplayName: string,
	Hero: string,
	Effect: string,
	Kind: string,
	Cooldown: number,
	Range: number,
	MinDot: number,
	Aimed: boolean?,
	Width: number?,
	Speed: number?,
	ReturnSpeed: number?,
	Curve: number?,
	HitRadius: number?,
	BlastRadius: number?,
	MaxTargets: number?,
	Reach: number?,
	Radius: number?,
	Push: number?,
	Shake: number?,
	Color: Color3,
	Accent: Color3,
}

HeroWeapons.WEAPONS = {
	CapShield = {
		DisplayName = "Cap's Shield", Hero = "Captain America", Effect = "Dazed", Kind = "Boomerang", Aimed = true,
		Cooldown = 1.2, Range = 42, MinDot = -1, Speed = 92, ReturnSpeed = 105, Curve = 0.22, HitRadius = 1.5,
		MaxTargets = 3, Shake = 0.6,
		Color = Color3.fromRGB(196, 28, 36), Accent = Color3.fromRGB(255, 225, 90),
	},
	PowerPole = {
		DisplayName = "Power Pole", Hero = "Goku", Effect = "SpinTornado", Kind = "Spin", Cooldown = 1.3,
		Range = 12.5, MinDot = -1, Radius = 12.5, MaxTargets = 4, Shake = 0.8,
		Color = Color3.fromRGB(204, 30, 34), Accent = Color3.fromRGB(255, 190, 40),
	},
	WebShooter = {
		DisplayName = "Web Shooter", Hero = "Spider-Man", Effect = "Webbed", Kind = "Shot", Aimed = true, Cooldown = 1.2,
		Range = 46, MinDot = -1, Speed = 150, HitRadius = 2.2, Shake = 0.35,
		Color = Color3.fromRGB(240, 248, 255), Accent = Color3.fromRGB(206, 30, 40),
	},
	Batarang = {
		DisplayName = "Batarang", Hero = "Batman", Effect = "SmokeStun", Kind = "Grenade", Aimed = true, Cooldown = 1.3,
		Range = 38, MinDot = -1, Speed = 82, Curve = 0.16, HitRadius = 1.4, BlastRadius = 8, MaxTargets = 4, Shake = 0.5,
		Color = Color3.fromRGB(30, 30, 36), Accent = Color3.fromRGB(255, 212, 40),
	},
	BakugoGauntlet = {
		DisplayName = "Grenade Gauntlet", Hero = "Bakugo", Effect = "ExplosionBlast", Kind = "Blast", Cooldown = 1.3,
		Range = 15, MinDot = 0.5, MaxTargets = 3, Push = 26, Shake = 1,
		Color = Color3.fromRGB(255, 140, 30), Accent = Color3.fromRGB(255, 230, 120),
	},
	Mjolnir = {
		DisplayName = "Mjolnir", Hero = "Thor", Effect = "Electrocuted", Kind = "Slam", Cooldown = 1.5,
		Range = 14, MinDot = -1, Reach = 4, Radius = 12, MaxTargets = 4, Shake = 1.2,
		Color = Color3.fromRGB(150, 220, 255), Accent = Color3.fromRGB(235, 250, 255),
	},
	GomuFist = {
		DisplayName = "Gum-Gum Fist", Hero = "Luffy", Effect = "CleanKnockback", Kind = "Thrust", Cooldown = 1.1,
		Range = 17, MinDot = 0.6, Width = 3.4, Push = 45, Shake = 0.7,
		Color = Color3.fromRGB(250, 200, 158), Accent = Color3.fromRGB(204, 30, 34),
	},
} :: { [string]: any }

for id, weapon in pairs(HeroWeapons.WEAPONS) do
	weapon.Id = id
end

-- Movement per effect while it lasts (GearService): WalkSpeed (nil = untouched), NoJump, Slide (seconds of input lock
-- while the victim's client slides it along Velocity), AutoRotate false while spinning.
HeroWeapons.EFFECTS = {
	Webbed = { WalkSpeed = 0, NoJump = true, Duration = 2.5 },
	Electrocuted = { WalkSpeed = 0, NoJump = true, Duration = 2.5 },
	CleanKnockback = { WalkSpeed = 0, NoJump = true, Slide = 0.85, Duration = 2.5, ReleaseAfterSlide = true },
	Dazed = { WalkSpeed = 4, NoJump = true, Duration = 2.2 },
	SmokeStun = { WalkSpeed = 7, NoJump = true, Duration = 2.5 },
	ExplosionBlast = { WalkSpeed = 0, NoJump = true, Slide = 0.5, Duration = 2.5, SlowAfterSlide = 6 },
	SpinTornado = { WalkSpeed = 0, NoJump = true, NoAutoRotate = true, Duration = 2.5 },
} :: { [string]: any }

function HeroWeapons.IdOfToolName(toolName: string?): string?
	if type(toolName) ~= "string" then
		return nil
	end
	return HeroWeapons.BY_TOOL[toolName]
end

-- The weapon of a Tool (its HeroWeaponId attribute, else its name), or nil for a classic bat / other gear.
function HeroWeapons.Of(tool: Instance?): any
	if typeof(tool) ~= "Instance" or not (tool :: Instance):IsA("Tool") then
		return nil
	end
	local id = (tool :: Instance):GetAttribute(HeroWeapons.TOOL_ATTRIBUTE)
	if type(id) ~= "string" then
		id = HeroWeapons.BY_TOOL[(tool :: Instance).Name]
	end
	return if type(id) == "string" then HeroWeapons.WEAPONS[id] else nil
end

function HeroWeapons.Get(weaponId: string?): any
	return if type(weaponId) == "string" then HeroWeapons.WEAPONS[weaponId] else nil
end

-- The owner's clip data for a weapon (ReplicatedStorage.Directory.WeaponAnimations.<Id>), cached; nil when missing.
local clipCache: { [string]: any } = {}
function HeroWeapons.Clip(weaponId: string): any
	local cached = clipCache[weaponId]
	if cached ~= nil then
		return cached or nil
	end
	local data = nil
	local ok, result = pcall(function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local folder = ReplicatedStorage:FindFirstChild("Directory")
		folder = folder and folder:FindFirstChild("WeaponAnimations")
		local module = folder and folder:FindFirstChild(weaponId)
		return if module and module:IsA("ModuleScript") then require(module) else nil
	end)
	if ok and type(result) == "table" then
		data = result
	end
	clipCache[weaponId] = data or false
	return data
end

-- (impact, length) seconds of a weapon's attack: the clip's Impact keyframe and its length (fallbacks if missing).
function HeroWeapons.Timing(weaponId: string): (number, number)
	local clip = HeroWeapons.Clip(weaponId)
	local impact = if clip and type(clip.Impact) == "number" then clip.Impact else 0.25
	local length = if clip and type(clip.Length) == "number" then clip.Length else 0.55
	return math.clamp(impact, 0.05, 1), math.clamp(length, impact + 0.05, 2)
end

-- Travel seconds of a projectile over `distance` studs (`speed` defaults to the weapon's Speed).
function HeroWeapons.Travel(weapon: any, distance: number, speed: number?): number
	local s = speed or weapon.Speed
	s = if type(s) == "number" and s > 0 then s else 100
	return math.clamp(distance / s, 0.05, 0.9)
end

----------------------------------------------------------------------------------------------------
-- aimed throws: the same path on the server (hits) and on every client (drawing)
----------------------------------------------------------------------------------------------------

local function flat(v: Vector3, fallback: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 0.01 then f.Unit else fallback
end
HeroWeapons.Flat = flat

-- Where an aimed weapon leaves from: the thrower's right shoulder, facing the aim (both sides use this, so the path
-- the server checks is the path every client draws). `rootCFrame` is the thrower's HumanoidRootPart.
function HeroWeapons.ThrowOrigin(rootCFrame: CFrame, aim: Vector3): Vector3
	local forward = flat(aim - rootCFrame.Position, flat(rootCFrame.LookVector, Vector3.new(0, 0, -1)))
	local right = forward:Cross(Vector3.yAxis)
	return rootCFrame.Position + Vector3.new(0, 0.9, 0) + forward * 1.2 + right * 0.9
end

-- The clamped end of an aimed throw from `origin` toward `aim`: at least MIN_AIM_DISTANCE, at most the weapon's Range,
-- never steeper than MAX_AIM_PITCH. `raycast(origin, vector)` (optional) returns a wall hit position, which shortens it.
function HeroWeapons.AimEnd(weapon: any, origin: Vector3, aim: Vector3, raycast: ((Vector3, Vector3) -> Vector3?)?): Vector3
	local offset = aim - origin
	local distance = offset.Magnitude
	local direction = if distance > 0.01 then offset / distance else Vector3.new(0, 0, -1)
	local horizontal = Vector3.new(direction.X, 0, direction.Z)
	local pitch = math.atan2(direction.Y, math.max(horizontal.Magnitude, 1e-4))
	pitch = math.clamp(pitch, -HeroWeapons.MAX_AIM_PITCH, HeroWeapons.MAX_AIM_PITCH)
	local heading = if horizontal.Magnitude > 1e-3 then horizontal.Unit else Vector3.new(0, 0, -1)
	direction = heading * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)
	distance = math.clamp(distance, HeroWeapons.MIN_AIM_DISTANCE, weapon.Range or 40)
	local finish = origin + direction * distance
	if raycast then
		local wall = raycast(origin, finish - origin)
		if wall then
			-- stop short of the wall, never through it (a wall at arm's length ends the throw right there)
			local reach = math.max((wall - origin).Magnitude - 0.6, 0.5)
			finish = origin + direction * reach
		end
	end
	return finish
end

-- Where a returning weapon flies back to: the thrower's catching hand, the same point on the server and every client.
function HeroWeapons.ReturnHome(rootCFrame: CFrame): Vector3
	return HeroWeapons.ThrowOrigin(rootCFrame, rootCFrame.Position + rootCFrame.LookVector)
end

-- A launched projectile's path. path = { Origin, End, Side (+1 / -1), Curve (0 = straight), OutTime, Returns,
-- BackTime }. Out: a quadratic curve bowing Side of the line by Curve x its length; back (Returns): the mirror bow from
-- End to `home` (HeroWeapons.ReturnHome of the thrower now), so the way back sweeps the other side of the line.
-- Returns the position at `t` seconds and whether the flight is over.
local function bezier(a: Vector3, c: Vector3, b: Vector3, u: number): Vector3
	local v = 1 - u
	return a * (v * v) + c * (2 * v * u) + b * (u * u)
end

function HeroWeapons.PathPoint(path: any, t: number, home: Vector3?): (Vector3, boolean)
	local origin, finish = path.Origin, path.End
	local line = finish - origin
	local length = line.Magnitude
	local side = flat(line, Vector3.new(0, 0, -1)):Cross(Vector3.yAxis) * (path.Side or 1)
	local bow = side * (length * (path.Curve or 0))
	if t <= path.OutTime then
		local u = math.clamp(t / path.OutTime, 0, 1)
		-- ease out a little: fast off the hand, gliding into the turn
		u = 1 - (1 - u) * (1 - u) * 0.35 - (1 - u) * 0.65
		return bezier(origin, origin + line * 0.5 + bow, finish, u), (not path.Returns) and u >= 1
	end
	if not path.Returns then
		return finish, true
	end
	local target = home or origin
	local back = target - finish
	local u = math.clamp((t - path.OutTime) / math.max(path.BackTime or path.OutTime, 0.05), 0, 1)
	u = u * u * (3 - 2 * u)
	local control = finish + back * 0.5 - bow * 0.8
	return bezier(finish, control, target, u), u >= 1
end

return HeroWeapons
