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
-- Kinds (how GearService picks the victims at Impact; every range is from the attacker's root, lag compensated):
--   Melee      the nearest player in reach and in front (MinDot); CapShield throws itself (Throw*) when nobody is in reach
--   Thrust     the nearest player along a narrow line (MinDot, Width studs either side of the line)
--   Projectile the nearest player in a narrow cone; the hit lands Travel seconds later (distance / Speed)
--   Blast      up to MaxTargets players in a cone
--   Slam       up to MaxTargets players around a point Reach studs in front
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
	Width: number?,
	Speed: number?,
	ThrowRange: number?,
	ThrowMinDot: number?,
	MaxTargets: number?,
	Reach: number?,
	Radius: number?,
	Push: number?,
	Color: Color3,
	Accent: Color3,
}

HeroWeapons.WEAPONS = {
	CapShield = {
		DisplayName = "Cap's Shield", Hero = "Captain America", Effect = "Dazed", Kind = "Melee", Cooldown = 0.9,
		Range = 12, MinDot = 0.25, ThrowRange = 30, ThrowMinDot = 0.9, Speed = 110,
		Color = Color3.fromRGB(196, 28, 36), Accent = Color3.fromRGB(255, 225, 90),
	},
	PowerPole = {
		DisplayName = "Power Pole", Hero = "Goku", Effect = "SpinTornado", Kind = "Thrust", Cooldown = 1.1,
		Range = 19, MinDot = 0.6, Width = 3.2,
		Color = Color3.fromRGB(204, 30, 34), Accent = Color3.fromRGB(255, 190, 40),
	},
	WebShooter = {
		DisplayName = "Web Shooter", Hero = "Spider-Man", Effect = "Webbed", Kind = "Projectile", Cooldown = 1.3,
		Range = 40, MinDot = 0.9, Speed = 140,
		Color = Color3.fromRGB(240, 248, 255), Accent = Color3.fromRGB(206, 30, 40),
	},
	Batarang = {
		DisplayName = "Batarang", Hero = "Batman", Effect = "SmokeStun", Kind = "Projectile", Cooldown = 1.3,
		Range = 36, MinDot = 0.88, Speed = 90,
		Color = Color3.fromRGB(30, 30, 36), Accent = Color3.fromRGB(255, 212, 40),
	},
	BakugoGauntlet = {
		DisplayName = "Grenade Gauntlet", Hero = "Bakugo", Effect = "ExplosionBlast", Kind = "Blast", Cooldown = 1.3,
		Range = 15, MinDot = 0.5, MaxTargets = 3, Push = 26,
		Color = Color3.fromRGB(255, 140, 30), Accent = Color3.fromRGB(255, 230, 120),
	},
	Mjolnir = {
		DisplayName = "Mjolnir", Hero = "Thor", Effect = "Electrocuted", Kind = "Slam", Cooldown = 1.4,
		Range = 14, MinDot = -1, Reach = 3.5, Radius = 11, MaxTargets = 4,
		Color = Color3.fromRGB(150, 220, 255), Accent = Color3.fromRGB(235, 250, 255),
	},
	GomuFist = {
		DisplayName = "Gum-Gum Fist", Hero = "Luffy", Effect = "CleanKnockback", Kind = "Thrust", Cooldown = 1.1,
		Range = 17, MinDot = 0.6, Width = 3.4, Push = 45,
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
	CleanKnockback = { WalkSpeed = 0, NoJump = true, Slide = 0.7, Duration = 2.5, ReleaseAfterSlide = true },
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

-- Travel seconds of a projectile over `distance` studs.
function HeroWeapons.Travel(weapon: any, distance: number): number
	local speed = if type(weapon.Speed) == "number" and weapon.Speed > 0 then weapon.Speed else 100
	return math.clamp(distance / speed, 0.05, 0.6)
end

return HeroWeapons
