--!nocheck
-- tests/plan_data.luau
-- The Steal a Hero game plan as test data (docs/STAGES_PLAN.md §1, §2, §4b + docs/VISUAL_PASS_PLAN.md D1-D9 +
-- docs/HERO_MODELS_PLAN.md H1/H2). Loaded
-- once by tests/run_all_tests.luau into H.PLAN; not a suite. Every number here is copied from the plans, never from
-- the build scripts, so the suites check the build against the contract and not against itself.

local PLAN = {}

-- §1. xMin/xMax = the stage's X range, floor top ~2.05-2.08. D9: spots = EggSpot markers (the egg ring), stage 1's
-- spots stay at X >= 95 (the hub-side entrance plaza).
PLAN.STAGES = {
	{ number = 1, key = "Forest", name = "The Avengers", villain = "Thanos", villainName = "Thanos", scale = 1.6, eggs = 6, spots = 12,
		xMin = 72, xMax = 170, incomeFactor = 1, minSpotX = 95 },
	{ number = 2, key = "Lake", name = "Justice League", villain = "Darkseid", villainName = "Darkseid", scale = 1.5, eggs = 6, spots = 12,
		xMin = 170, xMax = 316, incomeFactor = 2 },
	{ number = 3, key = "Desert", name = "Spider-Verse", villain = "Carnage", villainName = "Carnage", scale = 1.2, eggs = 6, spots = 12,
		xMin = 316, xMax = 526, incomeFactor = 4 },
	{ number = 4, key = "Jungle", name = "My Hero Academia", villain = "Shigaraki", villainName = "Shigaraki", scale = 1.1, eggs = 6, spots = 12,
		xMin = 526, xMax = 762, incomeFactor = 8 },
	{ number = 5, key = "Snow", name = "Dragon Ball", villain = "Frieza", villainName = "Frieza", scale = 1.0, eggs = 6, spots = 12,
		xMin = 762, xMax = 1086, incomeFactor = 16 },
	{ number = 6, key = "Volcano", name = "One Piece", villain = "Kaido", villainName = "Kaido", scale = 1.9, eggs = 8, spots = 14,
		xMin = 1086, xMax = 1471, incomeFactor = 32 },
}
PLAN.RETIRED = { "Abyss Ocean", "Prehistoric", "Cosmic" }
PLAN.HUB_MAX_X = 75 -- safe zone (villains stop at X = 80)
PLAN.GUARD_MIN_X = 80
PLAN.SHOP_MAX_X = 70 -- A5/A6: hub props and the moved shops stay at X <= 70
PLAN.STREET_HALF_WIDTH = 12 -- §3: clear main street |Z| <= 12, nothing collidable in it
PLAN.STREET_OVERHEAD_HALF_WIDTH = 15 -- A6: over |Z| <= 15, collidable undersides >= 12 studs up
PLAN.STREET_HEADROOM = 12
PLAN.WALL_NORTH_Z = 86 -- A5: side walls at Z ~ +86 / -88, 40 tall
PLAN.WALL_SOUTH_Z = -88
PLAN.WALL_HEIGHT = 40
PLAN.ADMIN_EGG_SPAWN = { x = 120, z = -20 } -- A1
PLAN.MAX_PARTS_PER_STAGE = 450 -- §3 budget (the D8 archive of each stage keeps the same build rules)
PLAN.ALLOWED_MATERIALS = { "Plastic", "SmoothPlastic", "Neon", "Glass", "Wood", "Metal", "Slate" }

-- D8 scratch layout: what stays in Workspace.StageEnvironments.<Key>; the procedural buildings live in
-- ReplicatedStorage.Archived_ProceduralEnvironments.<Key>. Boundary (invisible side walls) belongs to stages 1-3 (the
-- EndWall model carries the side walls of stages 4-6), Rain to stage 2 only.
PLAN.SCRATCH_KEEP = { EggSpots = "all", VillainPost = "all", EggCover = "all", Boundary = { 1, 2, 3 }, Rain = { 2 } }
PLAN.ARCHIVE_NAME = "Archived_ProceduralEnvironments"
PLAN.ARCHIVED_HAZARDS = 28 -- every A8 slow hazard moved to the archive with its building (none left in Workspace)
PLAN.SIDE_WALL_COUNT = 8 -- Boundary north/south of stages 1-3 + EndWall.SideWalls north/south
-- D9 egg ring around each villain
PLAN.POST_ABS_Z = 40 -- VillainPost mid-stage at |Z| ~ 40: stages 1/3/5 on +Z, 2/4/6 on -Z
PLAN.POST_ABS_Z_TOLERANCE = 4
PLAN.POST_X_TOLERANCE = 1
PLAN.POST_PAD = 20 -- 20x20 pad, clear up to 14 studs (only the villain stands on it)
PLAN.POST_CLEAR_HEIGHT = 14
PLAN.RING_MIN, PLAN.RING_MAX = 12, 28 -- EggSpots 12-28 studs (XZ) from the post
PLAN.SPOT_MIN_ABS_Z, PLAN.SPOT_MAX_ABS_Z = 16, 72
PLAN.SPOT_MIN_GAP = 3
PLAN.OPENING_MIN_DEG = 40 -- horseshoe: no spot within 40 degrees of the post -> street direction
PLAN.ROCK_MAX_HEIGHT = 3.5 -- cover rocks: Slate, <= 3.5 studs over the floor, anchored, collidable
PLAN.ROCK_ROUTE_WIDTH = 8 -- >= 8-stud walkways between the rocks of different spots
PLAN.NEST_MAX_FOOTPRINT = { hidden = 2.8, open = 5.0 } -- build-time nest footprint (studs) behind / without a rock
PLAN.PLAYER_RADIUS = 1.5 -- walkable-access checks: an R15 player; villains path with max(2, 1.6 x scale) (A3)

-- D3: no gear on the lobby floor; every player spawns with the basic kit (Backpack + StarterGear). The advanced
-- Subspace Trap still exists as gear but is never granted at start.
PLAN.STARTER_GEAR = { "Bat", "Trap" }
PLAN.NOT_STARTER_GEAR = { "SubspaceMine" }

-- §2. Base $/s and egg GrowthTime by rarity; drop weights inside a stage (One Piece has its own column).
PLAN.BASE_INCOME = { Common = 25, Rare = 60, Epic = 120, Legendary = 300, Mythic = 850, Secret = 2500 }
PLAN.GROWTH_TIME = { Common = 20, Rare = 30, Epic = 45, Legendary = 60, Mythic = 90, Secret = 120 }
PLAN.DROP_WEIGHT = { Common = 30, Rare = 18, Epic = 12, Legendary = 7, Mythic = 3 }
PLAN.DROP_WEIGHT_ONE_PIECE = { Common = 25, Rare = 14, Epic = 9, Legendary = 5, Mythic = 2.5, Secret = 0.5 }
PLAN.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

-- §2 roster: id, display name, stage, rarity.
PLAN.HEROES = {
	{ "Hawkeye", "Hawkeye", 1, "Common" },
	{ "BlackWidow", "Black Widow", 1, "Common" },
	{ "CaptainAmerica", "Captain America", 1, "Rare" },
	{ "Hulk", "Hulk", 1, "Epic" },
	{ "Thor", "Thor", 1, "Legendary" },
	{ "IronMan", "Iron Man", 1, "Mythic" },
	{ "Aquaman", "Aquaman", 2, "Common" },
	{ "GreenLantern", "Green Lantern", 2, "Common" },
	{ "Flash", "The Flash", 2, "Rare" },
	{ "WonderWoman", "Wonder Woman", 2, "Epic" },
	{ "Batman", "Batman", 2, "Legendary" },
	{ "Superman", "Superman", 2, "Mythic" },
	{ "PeterParker", "Peter Parker", 3, "Common" },
	{ "SpiderGwen", "Spider-Gwen", 3, "Common" },
	{ "MilesMorales", "Miles Morales", 3, "Rare" },
	{ "SpiderMan2099", "Spider-Man 2099", 3, "Epic" },
	{ "AgentVenom", "Agent Venom", 3, "Legendary" },
	{ "Venom", "Venom (Anti-Hero)", 3, "Mythic" },
	{ "Uraraka", "Uraraka", 4, "Common" },
	{ "Bakugo", "Bakugo", 4, "Common" },
	{ "Todoroki", "Todoroki", 4, "Rare" },
	{ "Hawks", "Hawks", 4, "Epic" },
	{ "Deku", "Deku", 4, "Legendary" },
	{ "AllMight", "All Might", 4, "Mythic" },
	{ "Krillin", "Krillin", 5, "Common" },
	{ "Trunks", "Trunks", 5, "Common" },
	{ "Piccolo", "Piccolo", 5, "Rare" },
	{ "Gohan", "Gohan", 5, "Epic" },
	{ "Vegeta", "Vegeta", 5, "Legendary" },
	{ "Goku", "Goku", 5, "Mythic" },
	{ "Usopp", "Usopp", 6, "Common" },
	{ "Nami", "Nami", 6, "Common" },
	{ "Brook", "Brook", 6, "Rare" },
	{ "Sanji", "Sanji", 6, "Rare" },
	{ "Zoro", "Zoro", 6, "Epic" },
	{ "Shanks", "Shanks", 6, "Legendary" },
	{ "Luffy", "Luffy", 6, "Mythic" },
	{ "JoyBoy", "Joy Boy", 6, "Secret" },
}

-- docs/HERO_MODELS_PLAN.md H1/H2: every roster hero and villain is the OWNER'S model, extracted from the read-only snapshot
-- into assets/hero_models/*.rbxm (scripts/tools/extract_hero_models.luau) and converted to R15 where it is R6.
-- id -> { model name in the snapshot, its rig }. From the contract's mapping table; the "?" rows as decided with evidence:
-- BlackWidow = "Jean Grey (X-Men)" (the first choice "StarterCharacter" is the Iron Man armour), IronMan =
-- "StarterCharacter" (the unnamed R15 at ~(111,5,-21) wears "Flash Season 5"), Vegeta = the unnamed R6 at ~(594,44,-85)
-- ("Prince Vegeta Saiyan Battle Armor"), Piccolo = the unnamed green-headed R6 in Workspace.Model.
PLAN.MODEL_FILES = {
	heroes = "assets/hero_models/Heroes.rbxm",
	villains = "assets/hero_models/Villains.rbxm",
	extras = "assets/hero_models/Extras.rbxm",
	template = "assets/hero_models/R15Template.rbxm",
}
PLAN.HERO_SOURCES = {
	Hawkeye = { "Hawkeye", "R6" }, BlackWidow = { "Jean Grey (X-Men)", "R6" }, CaptainAmerica = { "", "R15" },
	Hulk = { "Hulk", "R15" }, Thor = { "Thor", "R15" }, IronMan = { "StarterCharacter", "R15" },
	Aquaman = { "Aquaman", "R6" }, GreenLantern = { "Green Lantern", "R15" }, Flash = { "Flash", "R15" },
	WonderWoman = { " ", "R15" }, Batman = { "Batman", "R15" }, Superman = { "     ", "R15" },
	PeterParker = { "Spiderman", "R6" }, SpiderGwen = { "Gwen", "R6" }, MilesMorales = { "MilesMoralesK", "R6" },
	SpiderMan2099 = { "Spiderman 2099", "R6" }, AgentVenom = { "Venom", "R6" }, Venom = { "Ultimate Venom", "R6" },
	Uraraka = { "Uraraka", "R6" }, Bakugo = { "Bakugo", "R6" }, Todoroki = { "Shoto Todoroki", "R15" },
	Hawks = { "Hawks", "R6" }, Deku = { "Deku", "R6" }, AllMight = { "All Might", "R6" },
	Krillin = { "Krillin", "R6" }, Trunks = { "Trunks", "R6" }, Piccolo = { "", "R6" },
	Gohan = { "Gohan", "R6" }, Vegeta = { " ", "R6" }, Goku = { "Goku", "R6" },
	Usopp = { "Usopp", "R6" }, Nami = { "Nami Onigashima", "R6" }, Brook = { "Brook", "R6" },
	Sanji = { "Sanji", "R6" }, Zoro = { "Zoro", "R6" }, Shanks = { "Shanks", "R15" },
	Luffy = { "--", "R15" }, JoyBoy = { "Luffy - Gear 5", "R15" },
}
PLAN.VILLAIN_SOURCES = {
	Thanos = { "THANOS", "R6" }, Darkseid = { "Darkseid", "R15" }, Carnage = { "Zombie", "R15" },
	Shigaraki = { "Shoto", "R6" }, Frieza = { "Freeza", "R15" }, Kaido = { "Kaido", "R15" },
}
-- kept for later in Extras.rbxm (not in the roster this pass); the Sonic family is excluded entirely
PLAN.EXTRA_MODELS = { "NicoRobin", "Franky", "Chopper", "LJTheSecond", "FlashSeason5", "UnnamedUsoppR15", "SilverSurfer",
	"ReverseFlash", "KidFlash", "BlackFlash", "WallyWest", "MobiusWallyWest", "WhiteSpeedster", "Savitar", "Zoom" }
PLAN.SONIC_FAMILY = { "Sonic", "SuperSonic", "SuperSaiyanSonic", "DarkZonic", "Shadow" }
-- the default Roblox R15 animations that must drive every hero (pens: config Idle / Walk) and villain (GuardChaseService)
PLAN.R15_ANIMATIONS = { idle = 507766388, walk = 507777826, run = 507767714 }
-- visible height of a scale-1 hero body (the owner's models: 5.0 ... 7.05 studs)
PLAN.HERO_HEIGHT = { min = 4, max = 8 }

-- D1: only the 38 plan heroes (+ the 6 villains) exist. These 10 legacy Speedsters heroes were purged together with every
-- animal/brainrot asset of the base game (the animal ids are read from the base place's Directory.Assets._Index; the
-- sample below is the fallback when that file is absent). None of them may exist as a config, model or catalog entry.
PLAN.PURGED_HEROES = { "Zoom", "ReverseFlash", "ATrain", "Homelander", "SpiderMan", "RedDeath", "Savitar", "Sonic", "SuperSonic", "SilverSurfer" }
PLAN.PURGED_ANIMALS_SAMPLE = { "Chicken", "Dog", "Dragon", "Tung Tung Sahur", "Tiger", "Penguin", "Unicorn", "Kraken", "Yeti", "Balrog" }

-- Derived lookups ---------------------------------------------------------------------------------------------
PLAN.STAGE_BY_KEY = {}
PLAN.STAGE_BY_NUMBER = {}
for _, s in ipairs(PLAN.STAGES) do
	PLAN.STAGE_BY_KEY[s.key] = s
	PLAN.STAGE_BY_NUMBER[s.number] = s
end
PLAN.RETIRED_SET = {}
for _, key in ipairs(PLAN.RETIRED) do
	PLAN.RETIRED_SET[key] = true
end
PLAN.HERO_BY_ID = {}
PLAN.HEROES_BY_STAGE = {}
for _, row in ipairs(PLAN.HEROES) do
	local id, display, stageNumber, rarity = row[1], row[2], row[3], row[4]
	local stage = PLAN.STAGE_BY_NUMBER[stageNumber]
	local weights = if stageNumber == 6 then PLAN.DROP_WEIGHT_ONE_PIECE else PLAN.DROP_WEIGHT
	local hero = {
		id = id,
		displayName = display,
		stage = stageNumber,
		stageKey = stage.key,
		rarity = rarity,
		earningRate = PLAN.BASE_INCOME[rarity] * stage.incomeFactor,
		growthTime = PLAN.GROWTH_TIME[rarity],
		dropWeight = weights[rarity],
		source = PLAN.HERO_SOURCES[id],
	}
	PLAN.HERO_BY_ID[id] = hero
	PLAN.HEROES_BY_STAGE[stageNumber] = PLAN.HEROES_BY_STAGE[stageNumber] or {}
	table.insert(PLAN.HEROES_BY_STAGE[stageNumber], hero)
end

return PLAN
