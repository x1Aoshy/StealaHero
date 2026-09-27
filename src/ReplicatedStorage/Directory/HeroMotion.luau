-- ReplicatedStorage.Directory.HeroMotion (HEROES, Gekko #7 "Hero VFX and Movement Polish")
-- How each pen hero moves on top of the shared wander simulation (AssetWanderSimulator keeps deciding WHERE a hero
-- goes; this table only changes HOW it looks while doing it). Read by
-- StarterPlayerScripts.Game.Plots.ActiveAssetsController.AssetHeroMotion, keyed by the hero ids of Directory.Assets._Index
-- (the AssetModels names / HeroId attribute). A hero missing here walks (Styles.walk) with no accent.
--
-- Styles
--   walk    default R15 walk; slight lean into the stride, slow idle look-around
--   float   hovers above the ground (bob + forward tilt + banking into turns), no walk cycle (plays Idle while moving)
--   dash    walks, then bursts: short sprints (the simulation runs faster for BurstSeconds) with a streak trail
--   stomp   slow heavy cadence, a dip and a dust puff on every footfall
--   bounce  springy hops while moving (spider-agile / rubber)
-- Pace (ANIMPOLISH): a hero's wander speed = personality speed x Pace.Scale x rig scale ^ Pace.SizeExponent (a
-- small hero takes smaller steps, a big one covers more ground), kept inside CadenceRange x its Move clip's ground
-- speed (Directory.HeroAnimations Move.Speed x rig scale) so the foot-locked walk plays between those rates and never
-- skates; Moves without a Speed (flights, swings) only get Pace.FlyScale. Hover (studs at scale 1, float heroes) is how
-- high the hero hovers on top of its Idle clip: every floater's lowest point ends ~1 stud over the floor.
-- Accents (cheap VFX on built-in rbxasset:// particle textures, only drawn near the camera, off while the hero is
-- hidden by Hide Your Heroes / Hide Other Heroes or on the silent presentation path)
--   Thrusters  flames under both feet + an orange glow      Aura      energy motes around the torso + soft light
--   Sparks     sparks burst when a dash starts              Feathers  slow drifting feathers off the back
--   Glitter    gentle sparkles around the body              (stomp heroes always get their dust puffs)

local HeroMotion = {}

HeroMotion.DefaultStyle = "walk"

-- Distances are in studs for a hero at visual scale 1 (the AssetComponent multiplies them by the rendered model's
-- height / 5.5), angles in degrees, speeds in cycles per second.
HeroMotion.Styles = table.freeze({
	walk = table.freeze({
		WalkCycle = true,
		AnimationSpeed = 1.0,
		LeanDegrees = 4.0,
		IdleSwayDegrees = 5.0,
		CadenceRange = { 0.7, 1.9 },
	}),
	float = table.freeze({
		WalkCycle = false,
		AnimationSpeed = 1.0,
		HoverHeight = 1.2,
		BobAmplitude = 0.22,
		BobSpeed = 0.45,
		LeanDegrees = 14.0,
		BankDegrees = 12.0,
		IdleSwayDegrees = 4.0,
	}),
	dash = table.freeze({
		WalkCycle = true,
		AnimationSpeed = 1.15,
		LeanDegrees = 5.0,
		IdleSwayDegrees = 4.0,
		BurstLeanDegrees = 16.0,
		BurstSeconds = 0.35,
		BurstTimeScale = 2.6, -- how much faster the simulation runs during a burst
		BurstCooldown = { 1.4, 3.2 },
		CadenceRange = { 0.75, 2.2 },
	}),
	stomp = table.freeze({
		WalkCycle = true,
		AnimationSpeed = 0.8,
		LeanDegrees = 3.0,
		IdleSwayDegrees = 3.0,
		StrideLength = 4.4, -- studs per footfall (~the walk cycle's step at AnimationSpeed 0.8); clips sync the dips
		StepDip = 0.12,
		CadenceRange = { 0.65, 1.5 }, -- heavy: never a quick scurry
	}),
	bounce = table.freeze({
		WalkCycle = true,
		AnimationSpeed = 1.1,
		LeanDegrees = 6.0,
		IdleSwayDegrees = 5.0,
		HopHeight = 0.55,
		HopLength = 3.3, -- studs per hop (~one hop per walk-cycle step); clips sync the hops
		CadenceRange = { 0.7, 2.0 },
	}),
})

HeroMotion.Pace = table.freeze({
	Scale = 0.72,
	SizeExponent = 0.8,
	FlyScale = 0.85,
	DefaultCadence = { 0.7, 1.9 },
	Tremble = 0.06, -- a Scared hero shivers instead of sliding its whole rig 1.5 studs
	MinSpeedCap = 14.0, -- studs/s: the slowest a stepping hero may be held to never exceeds this (giant sprinters)
	MaxSpeedCap = 40.0,
})

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- Per hero: Style (a key of Styles), optional Accent (see header) with its Color (and a second Color2 for two-tone
-- accents). Roster order (docs/STAGES_PLAN.md §2).
HeroMotion.Heroes = table.freeze({
	-- STAGE 1: THE AVENGERS
	Hawkeye = { Style = "walk" },
	BlackWidow = { Style = "bounce" },
	CaptainAmerica = { Style = "walk" },
	Hulk = { Style = "stomp", DustColor = rgb(120, 150, 90) },
	Thor = { Style = "float", Hover = 1.25, Accent = "Sparks", Color = rgb(120, 190, 255), Continuous = true },
	IronMan = { Style = "float", Hover = 1.3, Accent = "Thrusters", Color = rgb(255, 160, 60) },
	-- STAGE 2: JUSTICE LEAGUE
	Aquaman = { Style = "walk", Accent = "Glitter", Color = rgb(90, 200, 255) },
	GreenLantern = { Style = "float", Hover = 1.25, Accent = "Aura", Color = rgb(70, 255, 110) },
	Flash = { Style = "dash", Accent = "Sparks", Color = rgb(255, 210, 40), Color2 = rgb(230, 40, 40) },
	WonderWoman = { Style = "walk", Accent = "Glitter", Color = rgb(255, 215, 90) },
	Batman = { Style = "walk" },
	Superman = { Style = "float", Hover = 1.3, Accent = "Aura", Color = rgb(170, 210, 255) },
	-- STAGE 3: SPIDER-VERSE
	PeterParker = { Style = "bounce" },
	SpiderGwen = { Style = "bounce", Accent = "Glitter", Color = rgb(255, 120, 200) },
	-- Continuous: only dash heroes burst their Sparks, so a bounce hero needs the steady trickle to show them at all
	MilesMorales = { Style = "bounce", Accent = "Sparks", Color = rgb(255, 230, 90), Color2 = rgb(90, 200, 255), Continuous = true },
	SpiderMan2099 = { Style = "bounce", Accent = "Glitter", Color = rgb(70, 140, 255) },
	-- dash: his Move clip is a tactical sprint (Speed 10); the bursts + a white / black streak sell it
	AgentVenom = { Style = "dash", Color = rgb(235, 240, 255), Color2 = rgb(40, 40, 52) },
	Venom = { Style = "stomp", DustColor = rgb(70, 70, 80) },
	-- STAGE 4: MY HERO ACADEMIA
	Uraraka = { Style = "float", Hover = 0.2, Accent = "Glitter", Color = rgb(255, 150, 200) },
	Bakugo = { Style = "dash", Accent = "Sparks", Color = rgb(255, 150, 40), Color2 = rgb(255, 230, 120) },
	Todoroki = { Style = "walk", Accent = "Aura", Color = rgb(160, 225, 255), Color2 = rgb(255, 110, 60) },
	Hawks = { Style = "float", Hover = 0.55, Accent = "Feathers", Color = rgb(220, 30, 40) },
	Deku = { Style = "dash", Accent = "Sparks", Color = rgb(90, 255, 130) },
	AllMight = { Style = "stomp", DustColor = rgb(200, 180, 140), Accent = "Sparks", Color = rgb(255, 214, 70),
		Color2 = rgb(255, 250, 220), Continuous = true },
	-- STAGE 5: DRAGON BALL
	-- float: a flying Z fighter (his Move clip owns its flight height; the Special pumps the Aura)
	Krillin = { Style = "float", Hover = 1.0, Accent = "Aura", Color = rgb(255, 225, 120) },
	Trunks = { Style = "dash", Accent = "Sparks", Color = rgb(190, 220, 255) },
	Piccolo = { Style = "float", Hover = 0.0, Accent = "Aura", Color = rgb(235, 225, 255), Color2 = rgb(170, 120, 255) },
	Gohan = { Style = "float", Hover = 0.95, Accent = "Aura", Color = rgb(240, 240, 255) },
	Vegeta = { Style = "float", Hover = 1.0, Accent = "Aura", Color = rgb(110, 170, 255) },
	Goku = { Style = "float", Hover = 0.7, Accent = "Aura", Color = rgb(255, 215, 70) },
	-- STAGE 6: ONE PIECE
	Usopp = { Style = "walk" },
	Nami = { Style = "walk" },
	Brook = { Style = "bounce" },
	Sanji = { Style = "dash", Accent = "Sparks", Color = rgb(255, 120, 40) },
	Zoro = { Style = "walk" },
	Shanks = { Style = "walk", Accent = "Aura", Color = rgb(230, 40, 50) },
	Luffy = { Style = "bounce" },
	JoyBoy = { Style = "bounce", Accent = "Glitter", Color = rgb(255, 255, 255) },
})

local DEFAULT_ENTRY = table.freeze({ Style = HeroMotion.DefaultStyle })

-- The entry for a hero id (never nil) and its style parameters.
function HeroMotion.Get(heroId: string?)
	local entry = if typeof(heroId) == "string" then HeroMotion.Heroes[heroId] else nil
	if entry == nil or HeroMotion.Styles[entry.Style] == nil then
		entry = DEFAULT_ENTRY
	end
	return entry, HeroMotion.Styles[entry.Style]
end

return HeroMotion
