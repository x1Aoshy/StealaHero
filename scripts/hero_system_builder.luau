-- scripts/hero_system_builder.luau
-- Builds the Steal a Hero game-plan hero ecosystem (build step 12, HeroSystem.Apply(place, spPlace)):
-- A. hero template rigs in ReplicatedStorage.Assets.Models.Heroes, one plain R15 character per roster hero
-- B. R15 hero AssetModels in ReplicatedStorage.AssetModels (contract C1): the 38 roster heroes
-- C. hero egg models in ReplicatedStorage.Assets.Models.Eggs (the base place's generic egg - its Chicken egg, the
--    only neutral egg mesh it ships - recoloured per hero; scripts/steps/post_purge.luau deletes the animal eggs
--    themselves, template included, AFTER this step; the EGGS post step repaints them per hero)
-- D. hero config ModuleScripts in ReplicatedStorage.Directory.Assets._Index (R15 animations, plan rarity/income/growth)
-- E. stage area configs in ReplicatedStorage.Directory.Areas._Index (DropTable, stage DisplayName/StageNumber/Emoji;
--    the 3 retired zones get DropTable = {})
-- F. the 6 stage villains as R15 zone guards in Workspace.__OBJECTS.Areas.GuardAreas (contract C2)
-- G. ReplicatedStorage.Directory.HeroCatalog, generated from HeroSystem.Heroes (also written back to src/)
-- H. build-time validation of all of the above (errors loudly on any violation)
--
-- Source of truth: docs/STAGES_PLAN.md §1/§2/§4b (roster, stages, rarity) and docs/HERO_MODELS_PLAN.md (looks).
-- HeroSystem.Heroes below IS the roster: stage, rarity, display name and egg colours per hero;
-- EarningRate/GrowthTime/DropWeight are derived from the plan formulas (HeroSystem.Plan).
--
-- Looks (H1/H2): every hero and villain is the OWNER'S model, read from assets/hero_models/*.rbxm (extracted from the
-- read-only snapshot assets/user_models/StealaHero_user_models_0747.rbxl by scripts/tools/extract_hero_models.luau,
-- whose MAPPING table says which model is which hero). scripts/lib/rig_convert.luau normalises each one to a standard
-- R15 body (R6 models are converted onto the owner's default block R15 body, assets/hero_models/R15Template.rbxm), so
-- the default Roblox R15 idle / walk / run animations drive every hero in the pens and every villain.
-- The build does not need the Speedsters (Update2) place any more; `spPlace` is ignored.

local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local fs = require("@lune/fs")
local Factory = require("./r15_rig_factory")
local RigConvert = require("./lib/rig_convert")

local Instance = roblox.Instance
local Color3 = roblox.Color3

local HeroSystem = {}

--------------------------------------------------------------------------------------------------
-- plan (docs/STAGES_PLAN.md §1, §2)
--------------------------------------------------------------------------------------------------

HeroSystem.Plan = {
    RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" },
    BaseIncome = { Common = 25, Rare = 60, Epic = 120, Legendary = 300, Mythic = 850, Secret = 2500 },
    GrowthTime = { Common = 20, Rare = 30, Epic = 45, Legendary = 60, Mythic = 90, Secret = 120 },
    DropWeight = { Common = 30, Rare = 18, Epic = 12, Legendary = 7, Mythic = 3 },
    OnePieceDropWeight = { Common = 25, Rare = 14, Epic = 9, Legendary = 5, Mythic = 2.5, Secret = 0.5 },
    RarityColor = {
        Common = Color3.fromRGB(180, 180, 180), Rare = Color3.fromRGB(50, 150, 255), Epic = Color3.fromRGB(180, 50, 255),
        Legendary = Color3.fromRGB(255, 180, 0), Mythic = Color3.fromRGB(255, 40, 80), Secret = Color3.fromRGB(0, 255, 200),
    },
}

-- Internal zone keys stay (scripts reference them); DisplayName/StageNumber/Emoji are what players see.
HeroSystem.Stages = {
    { Number = 1, Key = "Forest", Name = "The Avengers", IncomeFactor = 1, Villain = "Thanos", VillainScale = 1.6, Emoji = utf8.char(0x1F6E1, 0xFE0F) },
    { Number = 2, Key = "Lake", Name = "Justice League", IncomeFactor = 2, Villain = "Darkseid", VillainScale = 1.5, Emoji = utf8.char(0x1F987) },
    { Number = 3, Key = "Desert", Name = "Spider-Verse", IncomeFactor = 4, Villain = "Carnage", VillainScale = 1.2, Emoji = utf8.char(0x1F577, 0xFE0F) },
    { Number = 4, Key = "Jungle", Name = "My Hero Academia", IncomeFactor = 8, Villain = "Shigaraki", VillainScale = 1.1, Emoji = utf8.char(0x1F4A5) },
    { Number = 5, Key = "Snow", Name = "Dragon Ball", IncomeFactor = 16, Villain = "Frieza", VillainScale = 1.0, Emoji = utf8.char(0x1F409) },
    { Number = 6, Key = "Volcano", Name = "One Piece", IncomeFactor = 32, Villain = "Kaido", VillainScale = 1.9, Emoji = utf8.char(0x1F452) },
}
HeroSystem.RetiredZones = { "Abyss Ocean", "Prehistoric", "Cosmic" }

HeroSystem.ZoneOrder = {}
HeroSystem.ZoneGuards = {}
HeroSystem.ZoneScale = {}
for _, stage in ipairs(HeroSystem.Stages) do
    table.insert(HeroSystem.ZoneOrder, stage.Key)
    HeroSystem.ZoneGuards[stage.Key] = stage.Villain
    HeroSystem.ZoneScale[stage.Key] = stage.VillainScale
end

-- Roblox-owned default R15 Animate animations (the old R6 ids 180435571/180426354 do nothing on R15).
HeroSystem.R15Animations = {
    Idle = "rbxassetid://507766388",
    Walk = "rbxassetid://507777826",
}

HeroSystem.CatalogPath = "src/ReplicatedStorage/Directory/HeroCatalog.luau"

-- the owner's models (docs/HERO_MODELS_PLAN.md); Extras.rbxm holds models kept for later and is not built
HeroSystem.ModelFiles = {
    Heroes = "assets/hero_models/Heroes.rbxm",
    Villains = "assets/hero_models/Villains.rbxm",
    Template = "assets/hero_models/R15Template.rbxm",
}

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

--------------------------------------------------------------------------------------------------
-- the 38 heroes (docs/STAGES_PLAN.md §2), in plan order. PrimaryColor tints the egg and is the config's base
-- colour; SecondaryColor is catalog data. The model of each hero is assets/hero_models/Heroes.rbxm.<Id>.
--------------------------------------------------------------------------------------------------

HeroSystem.Heroes = {
    -- STAGE 1: THE AVENGERS (Forest)
    { Id = "Hawkeye", DisplayName = "Hawkeye", Stage = 1, Rarity = "Common", PrimaryColor = rgb(80, 35, 120), SecondaryColor = rgb(35, 30, 40) },
    { Id = "BlackWidow", DisplayName = "Black Widow", Stage = 1, Rarity = "Common", PrimaryColor = rgb(30, 30, 35), SecondaryColor = rgb(190, 40, 30) },
    { Id = "CaptainAmerica", DisplayName = "Captain America", Stage = 1, Rarity = "Rare", PrimaryColor = rgb(30, 60, 160), SecondaryColor = rgb(200, 30, 40) },
    { Id = "Hulk", DisplayName = "Hulk", Stage = 1, Rarity = "Epic", PrimaryColor = rgb(70, 160, 50), SecondaryColor = rgb(100, 45, 140) },
    { Id = "Thor", DisplayName = "Thor", Stage = 1, Rarity = "Legendary", PrimaryColor = rgb(70, 75, 90), SecondaryColor = rgb(180, 25, 30) },
    { Id = "IronMan", DisplayName = "Iron Man", Stage = 1, Rarity = "Mythic", PrimaryColor = rgb(180, 25, 30), SecondaryColor = rgb(220, 175, 50) },
    -- STAGE 2: JUSTICE LEAGUE (Lake)
    { Id = "Aquaman", DisplayName = "Aquaman", Stage = 2, Rarity = "Common", PrimaryColor = rgb(230, 140, 20), SecondaryColor = rgb(20, 130, 70) },
    { Id = "GreenLantern", DisplayName = "Green Lantern", Stage = 2, Rarity = "Common", PrimaryColor = rgb(30, 160, 60), SecondaryColor = rgb(25, 25, 30) },
    { Id = "Flash", DisplayName = "The Flash", Stage = 2, Rarity = "Rare", PrimaryColor = rgb(205, 25, 35), SecondaryColor = rgb(255, 215, 0) },
    { Id = "WonderWoman", DisplayName = "Wonder Woman", Stage = 2, Rarity = "Epic", PrimaryColor = rgb(175, 25, 35), SecondaryColor = rgb(30, 50, 150) },
    { Id = "Batman", DisplayName = "Batman", Stage = 2, Rarity = "Legendary", PrimaryColor = rgb(28, 28, 32), SecondaryColor = rgb(230, 180, 20) },
    { Id = "Superman", DisplayName = "Superman", Stage = 2, Rarity = "Mythic", PrimaryColor = rgb(0, 85, 205), SecondaryColor = rgb(205, 25, 35) },
    -- STAGE 3: SPIDER-VERSE (Desert)
    { Id = "PeterParker", DisplayName = "Peter Parker", Stage = 3, Rarity = "Common", PrimaryColor = rgb(200, 25, 30), SecondaryColor = rgb(25, 60, 180) },
    { Id = "SpiderGwen", DisplayName = "Spider-Gwen", Stage = 3, Rarity = "Common", PrimaryColor = rgb(235, 235, 245), SecondaryColor = rgb(230, 40, 140) },
    { Id = "MilesMorales", DisplayName = "Miles Morales", Stage = 3, Rarity = "Rare", PrimaryColor = rgb(20, 20, 22), SecondaryColor = rgb(220, 20, 30) },
    { Id = "SpiderMan2099", DisplayName = "Spider-Man 2099", Stage = 3, Rarity = "Epic", PrimaryColor = rgb(12, 28, 85), SecondaryColor = rgb(255, 30, 40) },
    { Id = "AgentVenom", DisplayName = "Agent Venom", Stage = 3, Rarity = "Legendary", PrimaryColor = rgb(15, 15, 18), SecondaryColor = rgb(240, 240, 245) },
    { Id = "Venom", DisplayName = "Venom (Anti-Hero)", Stage = 3, Rarity = "Mythic", PrimaryColor = rgb(12, 12, 16), SecondaryColor = rgb(240, 240, 250) },
    -- STAGE 4: MY HERO ACADEMIA (Jungle)
    { Id = "Uraraka", DisplayName = "Uraraka", Stage = 4, Rarity = "Common", PrimaryColor = rgb(240, 130, 170), SecondaryColor = rgb(25, 25, 35) },
    { Id = "Bakugo", DisplayName = "Bakugo", Stage = 4, Rarity = "Common", PrimaryColor = rgb(30, 30, 35), SecondaryColor = rgb(240, 130, 40) },
    { Id = "Todoroki", DisplayName = "Todoroki", Stage = 4, Rarity = "Rare", PrimaryColor = rgb(45, 70, 130), SecondaryColor = rgb(220, 60, 50) },
    { Id = "Hawks", DisplayName = "Hawks", Stage = 4, Rarity = "Epic", PrimaryColor = rgb(190, 20, 30), SecondaryColor = rgb(90, 70, 50) },
    { Id = "Deku", DisplayName = "Deku", Stage = 4, Rarity = "Legendary", PrimaryColor = rgb(35, 120, 90), SecondaryColor = rgb(210, 40, 40) },
    { Id = "AllMight", DisplayName = "All Might", Stage = 4, Rarity = "Mythic", PrimaryColor = rgb(35, 80, 190), SecondaryColor = rgb(255, 215, 60) },
    -- STAGE 5: DRAGON BALL (Snow)
    { Id = "Krillin", DisplayName = "Krillin", Stage = 5, Rarity = "Common", PrimaryColor = rgb(245, 120, 30), SecondaryColor = rgb(40, 70, 180) },
    { Id = "Trunks", DisplayName = "Trunks", Stage = 5, Rarity = "Common", PrimaryColor = rgb(190, 160, 220), SecondaryColor = rgb(35, 45, 90) },
    { Id = "Piccolo", DisplayName = "Piccolo", Stage = 5, Rarity = "Rare", PrimaryColor = rgb(100, 170, 70), SecondaryColor = rgb(90, 40, 120) },
    { Id = "Gohan", DisplayName = "Gohan", Stage = 5, Rarity = "Epic", PrimaryColor = rgb(85, 40, 120), SecondaryColor = rgb(200, 40, 40) },
    { Id = "Vegeta", DisplayName = "Vegeta", Stage = 5, Rarity = "Legendary", PrimaryColor = rgb(40, 60, 160), SecondaryColor = rgb(240, 240, 245) },
    { Id = "Goku", DisplayName = "Goku", Stage = 5, Rarity = "Mythic", PrimaryColor = rgb(245, 120, 30), SecondaryColor = rgb(35, 60, 170) },
    -- STAGE 6: ONE PIECE (Volcano)
    { Id = "Usopp", DisplayName = "Usopp", Stage = 6, Rarity = "Common", PrimaryColor = rgb(180, 140, 70), SecondaryColor = rgb(30, 25, 25) },
    { Id = "Nami", DisplayName = "Nami", Stage = 6, Rarity = "Common", PrimaryColor = rgb(240, 120, 30), SecondaryColor = rgb(60, 90, 170) },
    { Id = "Brook", DisplayName = "Brook", Stage = 6, Rarity = "Rare", PrimaryColor = rgb(25, 25, 30), SecondaryColor = rgb(240, 235, 220) },
    { Id = "Sanji", DisplayName = "Sanji", Stage = 6, Rarity = "Rare", PrimaryColor = rgb(20, 20, 25), SecondaryColor = rgb(245, 215, 110) },
    { Id = "Zoro", DisplayName = "Zoro", Stage = 6, Rarity = "Epic", PrimaryColor = rgb(80, 170, 80), SecondaryColor = rgb(240, 240, 240) },
    { Id = "Shanks", DisplayName = "Shanks", Stage = 6, Rarity = "Legendary", PrimaryColor = rgb(190, 30, 30), SecondaryColor = rgb(20, 20, 25) },
    { Id = "Luffy", DisplayName = "Luffy", Stage = 6, Rarity = "Mythic", PrimaryColor = rgb(200, 30, 30), SecondaryColor = rgb(235, 200, 90) },
    { Id = "JoyBoy", DisplayName = "Joy Boy", Stage = 6, Rarity = "Secret", PrimaryColor = rgb(250, 250, 255), SecondaryColor = rgb(255, 220, 120) },
}

-- legacy heroes: none. D1 (docs/VISUAL_PASS_PLAN.md) purged the 10 pre-plan Speedsters heroes; the list stays
-- (empty) so the validator and the generated HeroCatalog.Legacy / LegacyById keep their shape.
HeroSystem.LegacyHeroes = {}

-- the 6 stage villains (§1): the model is assets/hero_models/Villains.rbxm.<Id>, scaled by the stage's VillainScale
-- (RigScale) inside the guard (Factory.ApplyGuard)
HeroSystem.Villains = {
    Thanos = { DisplayName = "Thanos" },
    Darkseid = { DisplayName = "Darkseid" },
    Carnage = { DisplayName = "Carnage" },
    Shigaraki = { DisplayName = "Shigaraki" },
    Frieza = { DisplayName = "Frieza" },
    Kaido = { DisplayName = "Kaido" },
}

--------------------------------------------------------------------------------------------------
-- derived plan values
--------------------------------------------------------------------------------------------------

local stageByNumber = {}
for _, stage in ipairs(HeroSystem.Stages) do
    stageByNumber[stage.Number] = stage
end

for _, hero in ipairs(HeroSystem.Heroes) do
    local stage = assert(stageByNumber[hero.Stage], "[HeroSystem] " .. hero.Id .. " has no stage " .. tostring(hero.Stage))
    hero.StageKey = stage.Key
    hero.StageName = stage.Name
    hero.EarningRate = HeroSystem.Plan.BaseIncome[hero.Rarity] * stage.IncomeFactor
    hero.GrowthTime = HeroSystem.Plan.GrowthTime[hero.Rarity]
    local weights = if hero.Stage == 6 then HeroSystem.Plan.OnePieceDropWeight else HeroSystem.Plan.DropWeight
    hero.DropWeight = assert(weights[hero.Rarity], "[HeroSystem] no plan drop weight for " .. hero.Id .. " (" .. hero.Rarity .. ")")
end
for _, hero in ipairs(HeroSystem.LegacyHeroes) do
    hero.Legacy = true
end

-- stage DropTables: only that stage's heroes, plan weights
HeroSystem.ZoneDropTables = {}
for _, stage in ipairs(HeroSystem.Stages) do
    local list = {}
    for _, hero in ipairs(HeroSystem.Heroes) do
        if hero.Stage == stage.Number then
            table.insert(list, { hero.Id, hero.DropWeight })
        end
    end
    HeroSystem.ZoneDropTables[stage.Key] = list
end


--------------------------------------------------------------------------------------------------
-- build helpers
--------------------------------------------------------------------------------------------------

-- Walkable floor under a guard: the build's solid Baseplate (Bounds parts are 0-thick and non-colliding).
local function groundTopAt(ws, zone, position)
    local bp = ws:FindFirstChild("Baseplate")
    if bp and bp:IsA("BasePart") then
        local c, h = bp.CFrame.Position, bp.Size / 2
        if math.abs(position.X - c.X) <= h.X and math.abs(position.Z - c.Z) <= h.Z then
            return c.Y + h.Y
        end
    end
    local bounds = zone:FindFirstChild("Bounds")
    assert(bounds and bounds:IsA("BasePart"), "[HeroSystem] no Baseplate or Bounds floor under guard in " .. zone.Name)
    return bounds.CFrame.Position.Y + bounds.Size.Y / 2
end

-- Hero portrait icons (config Icon). A Speedsters suit preview thumbnail is used ONLY where the hero
-- truly is that Speedsters character; every other hero gets the Speedsters Hero Index fallback icon (the Index and
-- Sell Heroes cards render live ViewportFrame headshots of the models instead, docs/HERO_MODELS_PLAN.md H3).
HeroSystem.HeroIconAssetIds = {
    Flash = 97111421088356, -- FlashSuit
}
HeroSystem.FallbackHeroIcon = "rbxassetid://140189242202677"

function HeroSystem.IconFor(heroId)
    local assetId = HeroSystem.HeroIconAssetIds[heroId]
    if assetId then
        return string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", assetId)
    end
    return HeroSystem.FallbackHeroIcon
end

local function num(n)
    if n == math.floor(n) then
        return string.format("%d", n)
    end
    return string.format("%g", n)
end

local function c3(c)
    return string.format("Color3.fromRGB(%d, %d, %d)", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end

local function configSource(hero)
    local extra = ""
    if hero.Legacy then
        extra = "\tDontRoll = true, -- legacy hero (pre game-plan roster): kept only so old saves resolve\n"
    end
    -- The owner's models are the characters: every part is DontModify and a single colour entry keeps
    -- AssetColorUtil a no-op (no runtime colour variants).
    return string.format([[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script.Parent.Parent.Types.Interface)
local Default = require(script.Parent.Parent.BaseConfigs.Default)
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local Rarity = require(ReplicatedStorage.Directory.Rarity)

-- Generated by scripts/hero_system_builder.luau (the owner's model as an R15 rig; Roblox R15 Animate idle/walk).
return (setmetatable({
	DisplayName = %q,
	Icon = %q,
	EarningRate = %.1f,
	IndexSpeedReward = 500.0,
	DropWeight = %s,
	VisualOdds = 2.0,
	ModelWeight = 80.0,
	BaseModelScale = 1.0,
%s	Egg = {
		DisplayName = %q,
		Icon = "rbxassetid://133004694392561",
		GrowthTime = %.1f,
		WeightKg = 1.0
	},
	Animations = {
		Idle = Pipeline:GetAndSerializeAnimation(%q).anim,
		Walk = Pipeline:GetAndSerializeAnimation(%q).anim
	},
	Rarity = Rarity.Rarities.%s,
	BaseModelColor = %s,
	PossibleModelColors = {
		{ %s, 1.0 }
	},
}, {
	__index = Default
}))
]],
        hero.DisplayName,
        HeroSystem.IconFor(hero.Id),
        hero.EarningRate,
        num(hero.DropWeight or 0.5),
        extra,
        hero.DisplayName .. " Egg",
        hero.GrowthTime,
        HeroSystem.R15Animations.Idle,
        HeroSystem.R15Animations.Walk,
        hero.Rarity,
        c3(hero.PrimaryColor),
        c3(hero.PrimaryColor)
    )
end

--------------------------------------------------------------------------------------------------
-- G. HeroCatalog.luau, generated from HeroSystem.Heroes
--------------------------------------------------------------------------------------------------

function HeroSystem.RenderCatalog()
    local plan = HeroSystem.Plan
    local L = {}
    local function add(s)
        table.insert(L, s)
    end
    add("-- ReplicatedStorage.Directory.HeroCatalog")
    add("-- GENERATED by scripts/hero_system_builder.luau (HeroSystem.RenderCatalog) from HeroSystem.Heroes - edit the builder,")
    add("-- not this file; every build rewrites it. The 38 heroes of the Steal a Hero game plan (docs/STAGES_PLAN.md §2),")
    add("-- the 6 stages they drop in and the stage villains (§1). Formulas:")
    add("--   EarningRate ($/s) = Rarities[r].BaseIncome * Stages[s].IncomeFactor")
    add("--   GrowthTime (s)    = Rarities[r].GrowthTime")
    add("--   DropWeight        = Rarities[r].DropWeight (stage 6 One Piece: Rarities[r].OnePieceDropWeight)")
    add("")
    add("local HeroCatalog = {}")
    add("")
    local order = {}
    for _, r in ipairs(plan.RarityOrder) do
        table.insert(order, string.format("%q", r))
    end
    add("HeroCatalog.RarityOrder = { " .. table.concat(order, ", ") .. " }")
    add("")
    add("HeroCatalog.Rarities = {")
    for _, r in ipairs(plan.RarityOrder) do
        add(string.format("\t%s = { Color = %s, BaseIncome = %s, GrowthTime = %s, DropWeight = %s, OnePieceDropWeight = %s, Multiplier = %s },",
            r, c3(plan.RarityColor[r]), num(plan.BaseIncome[r]), num(plan.GrowthTime[r]), num(plan.DropWeight[r] or 0),
            num(plan.OnePieceDropWeight[r] or 0), num(plan.BaseIncome[r] / plan.BaseIncome.Common)))
    end
    add("}")
    add("")
    add("-- Key = the internal zone key (Workspace.__OBJECTS.Areas.GuardAreas.<Key>, Directory.Areas._Index.<Key>).")
    add("HeroCatalog.Stages = {")
    for _, s in ipairs(HeroSystem.Stages) do
        add(string.format("\t{ Number = %d, Key = %q, Name = %q, IncomeFactor = %s, Villain = %q, VillainScale = %s },",
            s.Number, s.Key, s.Name, num(s.IncomeFactor), s.Villain, num(s.VillainScale)))
    end
    add("}")
    add("")
    add("-- Legacy zones removed from play (no eggs, no villain).")
    local retired = {}
    for _, z in ipairs(HeroSystem.RetiredZones) do
        table.insert(retired, string.format("%q", z))
    end
    add("HeroCatalog.RetiredZones = { " .. table.concat(retired, ", ") .. " }")
    add("")
    add("HeroCatalog.Villains = {")
    for _, s in ipairs(HeroSystem.Stages) do
        local v = HeroSystem.Villains[s.Villain]
        add(string.format("\t%s = { Id = %q, DisplayName = %q, Stage = %d, StageKey = %q, Scale = %s },",
            s.Villain, s.Villain, v.DisplayName, s.Number, s.Key, num(s.VillainScale)))
    end
    add("}")
    add("")
    add("HeroCatalog.List = {")
    local lastStage = nil
    for _, h in ipairs(HeroSystem.Heroes) do
        if h.Stage ~= lastStage then
            lastStage = h.Stage
            local s = stageByNumber[h.Stage]
            add(string.format("\t-- STAGE %d: %s (x%s)", s.Number, string.upper(s.Name), num(s.IncomeFactor)))
        end
        add(string.format("\t{ Id = %q, DisplayName = %q, Stage = %d, Rarity = %q, EarningRate = %s, GrowthTime = %s, DropWeight = %s,",
            h.Id, h.DisplayName, h.Stage, h.Rarity, num(h.EarningRate), num(h.GrowthTime), num(h.DropWeight)))
        add(string.format("\t\tPrimaryColor = %s, SecondaryColor = %s },", c3(h.PrimaryColor), c3(h.SecondaryColor)))
    end
    add("}")
    add("")
    add("-- Pre game-plan heroes: none (D1 purge; old saves drop them in Database.EnsureStatDefaults). Kept, empty, so")
    add("-- HeroCatalog.Legacy / LegacyById / Get keep their shape.")
    add("HeroCatalog.Legacy = {")
    for _, h in ipairs(HeroSystem.LegacyHeroes) do
        add(string.format("\t{ Id = %q, DisplayName = %q, Stage = 0, Rarity = %q, EarningRate = %s, GrowthTime = %s, DontRoll = true,",
            h.Id, h.DisplayName, h.Rarity, num(h.EarningRate), num(h.GrowthTime)))
        add(string.format("\t\tPrimaryColor = %s, SecondaryColor = %s },", c3(h.PrimaryColor), c3(h.SecondaryColor)))
    end
    add("}")
    add([[

HeroCatalog.ById = {}
HeroCatalog.LegacyById = {}
HeroCatalog.ByStage = {}
HeroCatalog.StageByNumber = {}
HeroCatalog.StageByKey = {}

for _, stage in ipairs(HeroCatalog.Stages) do
	HeroCatalog.StageByNumber[stage.Number] = stage
	HeroCatalog.StageByKey[stage.Key] = stage
	HeroCatalog.ByStage[stage.Number] = {}
end

for _, hero in ipairs(HeroCatalog.List) do
	local stage = HeroCatalog.StageByNumber[hero.Stage]
	hero.StageKey = stage and stage.Key
	hero.StageName = stage and stage.Name
	-- legacy field names (pre game-plan catalog)
	hero.BaseIncome = hero.EarningRate
	hero.GrowthDuration = hero.GrowthTime
	HeroCatalog.ById[hero.Id] = hero
	HeroCatalog.ByStage[hero.Stage] = HeroCatalog.ByStage[hero.Stage] or {}
	table.insert(HeroCatalog.ByStage[hero.Stage], hero)
end

for _, hero in ipairs(HeroCatalog.Legacy) do
	hero.BaseIncome = hero.EarningRate
	hero.GrowthDuration = hero.GrowthTime
	HeroCatalog.LegacyById[hero.Id] = hero
end

-- Roster hero by id (LegacyById is empty since the D1 purge).
function HeroCatalog.Get(heroId)
	local id = tostring(heroId or "")
	return HeroCatalog.ById[id] or HeroCatalog.LegacyById[id]
end

function HeroCatalog.GetStageHeroes(stageNum)
	return HeroCatalog.ByStage[stageNum] or {}
end

-- Stage by number (1..6) or by internal zone key ("Forest", ...).
function HeroCatalog.GetStage(stage)
	if type(stage) == "number" then
		return HeroCatalog.StageByNumber[stage]
	end
	return HeroCatalog.StageByKey[tostring(stage or "")]
end

function HeroCatalog.GetVillain(villainId)
	return HeroCatalog.Villains[tostring(villainId or "")]
end

return HeroCatalog]])
    return table.concat(L, "\n") .. "\n"
end

-- Load a HeroCatalog source in Lune (Color3 is the only Roblox global it needs).
local function loadCatalog(source)
    local chunk = luau.load(source, { debugName = "HeroCatalog", environment = { Color3 = Color3 } })
    return chunk()
end

--------------------------------------------------------------------------------------------------
-- E. area config patching
--------------------------------------------------------------------------------------------------

local function dropTableSource(dropTable)
    if #dropTable == 0 then
        return "DropTable = {}"
    end
    local lines = {}
    for _, entry in ipairs(dropTable) do
        table.insert(lines, string.format("\t\t{\n\t\t\t%q,\n\t\t\t%.1f\n\t\t},", entry[1], entry[2]))
    end
    return "DropTable = {\n" .. table.concat(lines, "\n") .. "\n\t}"
end

-- Rewrites DropTable (and for kept stages DisplayName/StageNumber/Emoji); Rarity/GuardId/IndexBatGearId/Icon untouched.
local function patchAreaSource(src, zoneName, dropTable, stage)
    local out, n = string.gsub(src, "DropTable%s*=%s*%b{}", function()
        return dropTableSource(dropTable)
    end)
    assert(n == 1, string.format("[HeroSystem] Areas._Index.%s: expected exactly one DropTable, found %d", zoneName, n))
    if stage then
        out, n = string.gsub(out, "DisplayName%s*=%s*[^\n,]+,", function()
            return string.format("DisplayName = %q,", stage.Name)
        end, 1)
        assert(n == 1, "[HeroSystem] Areas._Index." .. zoneName .. ": no DisplayName field")
        out, n = string.gsub(out, "Emoji%s*=%s*\"[^\"]*\"", function()
            return string.format("Emoji = %q", stage.Emoji)
        end, 1)
        assert(n == 1, "[HeroSystem] Areas._Index." .. zoneName .. ": no Emoji field")
        if string.find(out, "StageNumber%s*=") then
            out = string.gsub(out, "StageNumber%s*=%s*[%d%.]+", "StageNumber = " .. stage.Number, 1)
        else
            out = string.gsub(out, "(DisplayName%s*=%s*\"[^\"]*\",)", function(line)
                return line .. "\n\tStageNumber = " .. stage.Number .. ","
            end, 1)
        end
    end
    return out
end

-- ids listed in an area config's DropTable
local function dropTableIds(src)
    local block = string.match(src, "DropTable%s*=%s*(%b{})")
    local ids = {}
    for id in string.gmatch(block or "", "\"([^\"]+)\"") do
        table.insert(ids, id)
    end
    return ids
end

--------------------------------------------------------------------------------------------------
-- apply
--------------------------------------------------------------------------------------------------

local function allHeroes()
    local list = {}
    for _, h in ipairs(HeroSystem.Heroes) do
        table.insert(list, h)
    end
    for _, h in ipairs(HeroSystem.LegacyHeroes) do
        table.insert(list, h)
    end
    return list
end

-- The owner's models: { Heroes = { [id] = Model }, Villains = { [id] = Model }, Template = prepared block R15 body }
function HeroSystem.LoadModels()
    local out = { Heroes = {}, Villains = {} }
    for _, key in ipairs({ "Heroes", "Villains" }) do
        local path = HeroSystem.ModelFiles[key]
        assert(fs.isFile(path), "[HeroSystem] " .. path .. " missing (run: lune run scripts/tools/extract_hero_models.luau)")
        for _, m in ipairs(roblox.deserializeModel(fs.readFile(path))) do
            assert(out[key][m.Name] == nil, "[HeroSystem] duplicate model " .. m.Name .. " in " .. path)
            out[key][m.Name] = m
        end
    end
    assert(fs.isFile(HeroSystem.ModelFiles.Template), "[HeroSystem] " .. HeroSystem.ModelFiles.Template .. " missing")
    local raw = roblox.deserializeModel(fs.readFile(HeroSystem.ModelFiles.Template))[1]
    out.Template = RigConvert.PrepareTemplate(raw)
    return out
end

local function sourceOf(model, file)
    return {
        File = file,
        Model = model:GetAttribute("SourceName") or model.Name,
        Rig = model:GetAttribute("SourceRig") or RigConvert.RigType(model),
        Path = model:GetAttribute("SourcePath") or "",
    }
end

-- one owner's model -> a standard R15 body with the owner's look protected (scripts/lib/rig_convert.luau)
local function convert(model, template, opts)
    local body, notes, info = RigConvert.ToR15(model, template, opts)
    Factory.ProtectLook(body)
    return body, notes, info
end

local function conversionLine(id, source, info)
    return string.format("%s <- %s %q (%s%s): %d accessories on their attachments, %d extras welded%s", id, source.File,
        source.Model, source.Rig, if source.Rig == "R6" then " -> R15" else "", info.Accessories, info.Extras,
        if #info.Lost > 0 then "; LOST: " .. table.concat(info.Lost, ", ") else "")
end

function HeroSystem.Apply(place, _spPlace)

    local ws = place.Workspace
    local rs = place:GetService("ReplicatedStorage")
    local dir = rs:FindFirstChild("Directory")
    local assetsDir = dir and dir:FindFirstChild("Assets")
    local assetsIndex = assetsDir and assetsDir:FindFirstChild("_Index")
    local areasDir = dir and dir:FindFirstChild("Areas")
    local areasIndex = areasDir and areasDir:FindFirstChild("_Index")

    local assetModels = rs:FindFirstChild("AssetModels")
    if not assetModels then
        assetModels = Instance.new("Folder")
        assetModels.Name = "AssetModels"
        assetModels.Parent = rs
    end

    local rsAssets = rs:FindFirstChild("Assets")
    local modelsFolder = rsAssets and rsAssets:FindFirstChild("Models")
    local eggsFolder = modelsFolder and modelsFolder:FindFirstChild("Eggs")
    local heroesFolder = modelsFolder and modelsFolder:FindFirstChild("Heroes")
    if not heroesFolder and modelsFolder then
        heroesFolder = Instance.new("Folder")
        heroesFolder.Name = "Heroes"
        heroesFolder.Parent = modelsFolder
    end

    local models = HeroSystem.LoadModels()
    local template = models.Template
    print(string.format("[HeroSystem] Owner models loaded: %s (%d), %s (%d), block R15 template %s.",
        HeroSystem.ModelFiles.Heroes, #HeroSystem.Heroes, HeroSystem.ModelFiles.Villains, #HeroSystem.ZoneOrder,
        HeroSystem.ModelFiles.Template))

    local heroes = allHeroes()
    print(string.format("[HeroSystem] Building %d roster heroes + %d legacy heroes into AssetModels, Eggs and Assets._Index...",
        #HeroSystem.Heroes, #HeroSystem.LegacyHeroes))

    local templateEgg = eggsFolder and (eggsFolder:FindFirstChild("Chicken") or eggsFolder:FindFirstChildWhichIsA("Model"))
    local heroById = {}
    local rosterIds = {}
    for _, hero in ipairs(HeroSystem.Heroes) do
        rosterIds[hero.Id] = true
    end

    -- A. the template rig cache holds exactly the roster
    if heroesFolder then
        for _, c in ipairs(heroesFolder:GetChildren()) do
            if not rosterIds[c.Name] then
                c:Destroy()
            end
        end
    end

    HeroSystem.LastConversion = {}
    for _, hero in ipairs(heroes) do
        heroById[hero.Id] = hero
        local src = assert(models.Heroes[hero.Id], "[HeroSystem] " .. HeroSystem.ModelFiles.Heroes .. " has no model " .. hero.Id)
        local source = sourceOf(src, HeroSystem.ModelFiles.Heroes)
        local body, notes, info = convert(src, template, { Label = hero.Id })
        HeroSystem.LastConversion[hero.Id] = { Source = source, Info = info, Notes = notes }
        print("[HeroSystem] " .. conversionLine(hero.Id, source, info))

        -- A. template rig in Assets.Models.Heroes (a plain R15 character)
        if heroesFolder and not hero.Legacy then
            local existing = heroesFolder:FindFirstChild(hero.Id)
            if existing then
                existing:Destroy()
            end
            local rig = Factory.WrapTemplateRig(hero.Id, body:Clone(), info.HipHeight)
            Factory.TagSource(rig, source)
            rig.Parent = heroesFolder
        end

        -- B. R15 AssetModel (contract C1)
        local existingAm = assetModels:FindFirstChild(hero.Id)
        if existingAm then
            existingAm:Destroy()
        end
        local amHero = Factory.WrapAssetModel(hero.Id, body, { ClothingHumanoid = true, HipHeight = info.HipHeight })
        Factory.TagSource(amHero, source)
        amHero.Parent = assetModels

        -- C. Themed egg model in Assets.Models.Eggs
        if eggsFolder and templateEgg then
            local existingEgg = eggsFolder:FindFirstChild(hero.Id)
            if existingEgg then
                existingEgg:Destroy()
            end
            local eggClone = templateEgg:Clone()
            eggClone.Name = hero.Id
            if not eggClone.PrimaryPart then
                eggClone.PrimaryPart = eggClone:FindFirstChild("Hitbox") or eggClone:FindFirstChildWhichIsA("BasePart")
            end
            for _, pt in ipairs(eggClone:GetDescendants()) do
                if pt:IsA("BasePart") and pt.Name ~= "Hitbox" then
                    pt.Color = hero.PrimaryColor
                    if pt:IsA("UnionOperation") then
                        pcall(function()
                            (pt :: any).UsePartColor = true -- a union shows its baked colours otherwise
                        end)
                    end
                end
                if pt:IsA("Sound") then
                    pt:Destroy()
                end
            end
            eggClone:SetAttribute("HeroId", hero.Id)
            pcall(function()
                (eggClone :: any).Scale = 1.0
            end)
            eggClone.Parent = eggsFolder
        end

        -- D. Config ModuleScript in Directory.Assets._Index
        if assetsIndex then
            local mod = assetsIndex:FindFirstChild(hero.Id) or Instance.new("ModuleScript")
            mod.Name = hero.Id
            mod.Source = configSource(hero)
            mod.Parent = assetsIndex
        end
    end

    -- E. Area configs in Directory.Areas._Index: the 6 stages get their DropTable + stage name/number/emoji,
    -- the retired zones an empty DropTable (the Index skips empty sections); anything else is left alone.
    local retiredSet = {}
    for _, z in ipairs(HeroSystem.RetiredZones) do
        retiredSet[z] = true
    end
    local stageByKey = {}
    for _, s in ipairs(HeroSystem.Stages) do
        stageByKey[s.Key] = s
    end
    if areasIndex then
        print("[HeroSystem] Updating stage area configs in ReplicatedStorage.Directory.Areas._Index...")
        for _, areaMod in ipairs(areasIndex:GetChildren()) do
            if areaMod:IsA("ModuleScript") then
                local stage = stageByKey[areaMod.Name]
                if stage then
                    areaMod.Source = patchAreaSource(areaMod.Source, areaMod.Name, HeroSystem.ZoneDropTables[stage.Key], stage)
                    print(string.format("[HeroSystem] Stage %d '%s' (%s): DropTable with %d heroes.", stage.Number, stage.Name,
                        areaMod.Name, #HeroSystem.ZoneDropTables[stage.Key]))
                elseif retiredSet[areaMod.Name] then
                    areaMod.Source = patchAreaSource(areaMod.Source, areaMod.Name, {}, nil)
                    print(string.format("[HeroSystem] Retired zone '%s': DropTable = {}.", areaMod.Name))
                else
                    print(string.format("[HeroSystem] WARNING: unknown area config '%s' left untouched.", areaMod.Name))
                end
            end
        end
    end

    -- F. Zone guards -> the 6 stage villains (contract C2). Only the 6 kept keys are touched; the retired zones'
    -- GuardAreas models are destroyed by the stages step before this runs (and are never indexed here).
    local objs = ws:FindFirstChild("__OBJECTS")
    local ga = objs and objs:FindFirstChild("Areas") and objs.Areas:FindFirstChild("GuardAreas")
    assert(ga, "[HeroSystem] Workspace.__OBJECTS.Areas.GuardAreas not found")
    local guardGround = {}
    print(string.format("[HeroSystem] Rebuilding %d stage guards as R15 villains...", #HeroSystem.ZoneOrder))
    for _, zoneName in ipairs(HeroSystem.ZoneOrder) do
        local villainId = HeroSystem.ZoneGuards[zoneName]
        local villain = assert(HeroSystem.Villains[villainId], "[HeroSystem] ZoneGuards." .. zoneName .. " names unknown villain " .. tostring(villainId))
        local scale = HeroSystem.ZoneScale[zoneName]
        local zone = ga:FindFirstChild(zoneName)
        local guard = zone and zone:FindFirstChild("Guard")
        assert(guard and guard:IsA("Model"), "[HeroSystem] GuardAreas." .. zoneName .. ".Guard not found")
        local hrp = assert(guard:FindFirstChild("HumanoidRootPart"), "[HeroSystem] " .. zoneName .. " guard has no HumanoidRootPart")
        local groundTop = groundTopAt(ws, zone, hrp.CFrame.Position)
        guardGround[zoneName] = groundTop
        local src = assert(models.Villains[villainId], "[HeroSystem] " .. HeroSystem.ModelFiles.Villains .. " has no model " .. villainId)
        local source = sourceOf(src, HeroSystem.ModelFiles.Villains)
        -- RigScale 1 = the owner's model at its authored size, root re-seated 2 studs above the feet (HipHeight 2)
        local body, _, info = convert(src, template, { Label = villainId, HipHeight = 2 })
        HeroSystem.LastConversion[villainId] = { Source = source, Info = info }
        print("[HeroSystem] " .. conversionLine(villainId, source, info))
        local notes = Factory.ApplyGuard(guard, zone, villainId, body, scale, groundTop)
        Factory.TagSource(guard, source)
        guard:SetAttribute("VillainName", villain.DisplayName)
        guard:SetAttribute("StageNumber", stageByKey[zoneName].Number)
        for _, note in ipairs(notes) do
            if note:find("WARNING", 1, true) then
                print(string.format("[HeroSystem] %s guard: %s", zoneName, note))
            end
        end
        print(string.format("[HeroSystem] Stage %d guard in '%s' is now %s (RigScale %.2f) at (%.1f, %.2f, %.1f).",
            stageByKey[zoneName].Number, zoneName, villainId, scale, guard.HumanoidRootPart.CFrame.Position.X,
            guard.HumanoidRootPart.CFrame.Position.Y, guard.HumanoidRootPart.CFrame.Position.Z))
    end
    local leftovers = {}
    for _, z in ipairs(ga:GetChildren()) do
        if retiredSet[z.Name] then
            table.insert(leftovers, z.Name)
        end
    end
    if #leftovers > 0 then
        print("[HeroSystem] NOTE: retired zone(s) still present in GuardAreas (the stages step removes them): "
            .. table.concat(leftovers, ", ") .. " - left untouched.")
    end

    -- G. HeroCatalog: generated from HeroSystem.Heroes, injected, and written back to src/ when it drifted
    local catalogSource = HeroSystem.RenderCatalog()
    if dir then
        local catalogModule = dir:FindFirstChild("HeroCatalog")
        if not catalogModule then
            catalogModule = Instance.new("ModuleScript")
            catalogModule.Name = "HeroCatalog"
            catalogModule.Parent = dir
        end
        catalogModule.Source = catalogSource
    end
    local onDisk = if fs.isFile(HeroSystem.CatalogPath) then fs.readFile(HeroSystem.CatalogPath) else nil
    if onDisk ~= catalogSource then
        fs.writeFile(HeroSystem.CatalogPath, catalogSource)
        print("[HeroSystem] Regenerated " .. HeroSystem.CatalogPath .. " from HeroSystem.Heroes.")
    end

    -- H. Validation: contracts C1/C2, configs, area configs, catalog, leftovers. Any violation fails the step.
    local errs = {}
    local function E(fmt, ...)
        table.insert(errs, string.format(fmt, ...))
    end

    -- plan roster shape
    local perStage, seen = {}, {}
    for _, hero in ipairs(HeroSystem.Heroes) do
        if seen[hero.Id] then
            E("duplicate roster id %s", hero.Id)
        end
        seen[hero.Id] = true
        perStage[hero.Stage] = (perStage[hero.Stage] or 0) + 1
        if not HeroSystem.Plan.BaseIncome[hero.Rarity] then
            E("%s: unknown rarity %s", hero.Id, tostring(hero.Rarity))
        end
    end
    for _, hero in ipairs(HeroSystem.LegacyHeroes) do
        if seen[hero.Id] then
            E("legacy id %s is also a roster id", hero.Id)
        end
    end
    if #HeroSystem.Heroes ~= 38 then
        E("roster must have 38 heroes, has %d", #HeroSystem.Heroes)
    end
    for n = 1, 6 do
        local expected = if n == 6 then 8 else 6
        if perStage[n] ~= expected then
            E("stage %d must have %d heroes, has %s", n, expected, tostring(perStage[n]))
        end
    end

    local amCount, humanoidCount, rigCount, eggCount, configCount = 0, 0, 0, 0, 0
    local minH, maxH = math.huge, -math.huge
    HeroSystem.LastStats = {}
    for _, hero in ipairs(heroes) do
        local am = assetModels:FindFirstChild(hero.Id)
        if not am then
            E("AssetModels.%s missing", hero.Id)
        else
            local e, stats = Factory.ValidateAssetModel(am, hero.Id)
            for _, s in ipairs(e) do
                table.insert(errs, s)
            end
            if #e == 0 then
                amCount += 1
            end
            if stats.humanoid then
                humanoidCount += 1
            end
            if stats.height then
                minH = math.min(minH, stats.height)
                maxH = math.max(maxH, stats.height)
            end
            HeroSystem.LastStats[hero.Id] = { height = stats.height, parts = stats.parts }
        end
        if not hero.Legacy then
            local rig = heroesFolder and heroesFolder:FindFirstChild(hero.Id)
            if rig then
                local e = Factory.ValidateTemplateRig(rig, hero.Id)
                for _, s in ipairs(e) do
                    table.insert(errs, s)
                end
                if #e == 0 then
                    rigCount += 1
                end
            elseif heroesFolder then
                E("Assets.Models.Heroes.%s missing", hero.Id)
            end
        end
        if eggsFolder then
            local egg = eggsFolder:FindFirstChild(hero.Id)
            if egg and egg.PrimaryPart then
                eggCount += 1
            else
                E("egg model Assets.Models.Eggs.%s missing or without PrimaryPart", hero.Id)
            end
        end
        local mod = assetsIndex and assetsIndex:FindFirstChild(hero.Id)
        if not mod then
            E("config Directory.Assets._Index.%s missing", hero.Id)
        else
            local src = mod.Source
            local ok, err = pcall(luau.compile, src)
            if not ok then
                E("config %s does not compile: %s", hero.Id, tostring(err))
            else
                configCount += 1
            end
            local rate = tonumber(string.match(src, "EarningRate%s*=%s*([%d%.]+)"))
            local growth = tonumber(string.match(src, "GrowthTime%s*=%s*([%d%.]+)"))
            local rarity = string.match(src, "Rarity%.Rarities%.(%w+)")
            if rate ~= hero.EarningRate or growth ~= hero.GrowthTime or rarity ~= hero.Rarity then
                E("config %s: EarningRate/GrowthTime/Rarity %s/%s/%s, expected %s/%s/%s", hero.Id, tostring(rate), tostring(growth),
                    tostring(rarity), num(hero.EarningRate), num(hero.GrowthTime), hero.Rarity)
            end
            if not (string.find(src, "507766388", 1, true) and string.find(src, "507777826", 1, true)) then
                E("config %s must use the R15 idle/walk animations", hero.Id)
            end
            if string.find(src, "87733160598688", 1, true) then
                E("config %s uses the Chicken icon", hero.Id)
            end
            local dontRoll = string.find(src, "DontRoll%s*=%s*true") ~= nil
            if dontRoll ~= (hero.Legacy == true) then
                E("config %s: DontRoll must be %s", hero.Id, tostring(hero.Legacy == true))
            end
        end
    end
    if heroesFolder and #heroesFolder:GetChildren() ~= #HeroSystem.Heroes then
        E("Assets.Models.Heroes must hold exactly the %d roster rigs, holds %d", #HeroSystem.Heroes, #heroesFolder:GetChildren())
    end

    -- area configs: the 6 stages list exactly their heroes (plan weights), the retired ones nothing
    local areaSummary = {}
    if areasIndex then
        for _, stage in ipairs(HeroSystem.Stages) do
            local mod = areasIndex:FindFirstChild(stage.Key)
            if not mod then
                E("area config Directory.Areas._Index.%s missing", stage.Key)
                continue
            end
            local src = mod.Source
            local ok, err = pcall(luau.compile, src)
            if not ok then
                E("area config %s does not compile: %s", stage.Key, tostring(err))
            end
            local ids = dropTableIds(src)
            local expected = {}
            for _, entry in ipairs(HeroSystem.ZoneDropTables[stage.Key]) do
                expected[entry[1]] = true
            end
            local got = {}
            for _, id in ipairs(ids) do
                got[id] = true
                if not expected[id] then
                    E("area %s DropTable lists %s, which is not a stage %d hero", stage.Key, id, stage.Number)
                end
                if not (assetsIndex and assetsIndex:FindFirstChild(id)) then
                    E("area %s DropTable id %s has no Directory.Assets._Index config", stage.Key, id)
                end
                if not assetModels:FindFirstChild(id) then
                    E("area %s DropTable id %s has no AssetModel", stage.Key, id)
                end
            end
            for id in pairs(expected) do
                if not got[id] then
                    E("area %s DropTable misses stage hero %s", stage.Key, id)
                end
            end
            if not string.find(src, string.format("DisplayName = %q,", stage.Name), 1, true) then
                E("area %s DisplayName must be %q", stage.Key, stage.Name)
            end
            if not string.find(src, "StageNumber = " .. stage.Number .. ",", 1, true) then
                E("area %s StageNumber must be %d", stage.Key, stage.Number)
            end
            table.insert(areaSummary, string.format("%s=%d", stage.Key, #ids))
        end
        for _, z in ipairs(HeroSystem.RetiredZones) do
            local mod = areasIndex:FindFirstChild(z)
            if mod and #dropTableIds(mod.Source) > 0 then
                E("retired area %s must have an empty DropTable", z)
            end
        end
    end

    -- catalog: compiles, loads, and matches HeroSystem.Heroes
    do
        local ok, err = pcall(luau.compile, catalogSource)
        if not ok then
            E("generated HeroCatalog does not compile: %s", tostring(err))
        else
            local okLoad, catalog = pcall(loadCatalog, catalogSource)
            if not okLoad then
                E("generated HeroCatalog does not load: %s", tostring(catalog))
            else
                if #catalog.List ~= #HeroSystem.Heroes then
                    E("HeroCatalog.List has %d heroes, expected %d", #catalog.List, #HeroSystem.Heroes)
                end
                for _, hero in ipairs(heroes) do
                    local c = catalog.Get(hero.Id)
                    if not c then
                        E("HeroCatalog.Get(%q) is nil", hero.Id)
                    elseif c.Rarity ~= hero.Rarity or c.EarningRate ~= hero.EarningRate or c.GrowthTime ~= hero.GrowthTime
                        or c.DisplayName ~= hero.DisplayName or (not hero.Legacy and (c.Stage ~= hero.Stage or c.DropWeight ~= hero.DropWeight)) then
                        E("HeroCatalog entry %s does not match HeroSystem.Heroes", hero.Id)
                    end
                end
                for _, stage in ipairs(HeroSystem.Stages) do
                    if #catalog.GetStageHeroes(stage.Number) ~= #HeroSystem.ZoneDropTables[stage.Key] then
                        E("HeroCatalog.GetStageHeroes(%d) size mismatch", stage.Number)
                    end
                end
            end
        end
    end

    -- guards (the 6 kept zones only)
    local guardCount = 0
    HeroSystem.LastGuardStats = {}
    for _, zoneName in ipairs(HeroSystem.ZoneOrder) do
        local zone = ga:FindFirstChild(zoneName)
        local guard = zone and zone:FindFirstChild("Guard")
        if not guard then
            E("GuardAreas.%s.Guard missing after the build", zoneName)
            continue
        end
        local scale = HeroSystem.ZoneScale[zoneName]
        local e, stats = Factory.ValidateGuard(guard, zone, HeroSystem.ZoneGuards[zoneName], scale, guardGround[zoneName])
        for _, s in ipairs(e) do
            table.insert(errs, s)
        end
        if guard:GetAttribute("VillainName") ~= HeroSystem.Villains[HeroSystem.ZoneGuards[zoneName]].DisplayName then
            E("%s.Guard: VillainName attribute missing", zoneName)
        end
        if #e == 0 then
            guardCount += 1
        end
        HeroSystem.LastGuardStats[zoneName] = stats
    end

    -- no hero limbs anywhere else in Workspace (old builds left R6 limbs floating at the hub, ~(15, 2, 80));
    -- every existing guard is exempt (a retired zone still present in a partial build keeps its own rig)
    local limbNames = {}
    for _, n in ipairs(Factory.R15_PARTS) do
        limbNames[n] = n ~= "Head"
    end
    for _, n in ipairs({ "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }) do
        limbNames[n] = true
    end
    local guardModels = {}
    for _, z in ipairs(ga:GetChildren()) do
        local g = z:FindFirstChild("Guard")
        if g then
            table.insert(guardModels, g)
        end
    end
    local stray = {}
    for _, d in ipairs(ws:GetDescendants()) do
        if d:IsA("BasePart") and limbNames[d.Name] then
            local inGuard = false
            for _, g in ipairs(guardModels) do
                if d:IsDescendantOf(g) then
                    inGuard = true
                    break
                end
            end
            if not inGuard then
                table.insert(stray, d:GetFullName())
            end
        end
    end
    if #stray > 0 then
        E("%d hero limb part(s) outside the guards in Workspace: %s", #stray, table.concat(stray, ", ", 1, math.min(#stray, 10)))
    end

    if #errs > 0 then
        error(string.format("[HeroSystem] contract validation FAILED (%d violation(s)):\n  %s", #errs, table.concat(errs, "\n  ")))
    end
    print(string.format("[HeroSystem] Validation OK: %d/%d R15 AssetModels (C1; %d roster + %d legacy, %d with render-only clothing "
        .. "Humanoid, visible height %.2f-%.2f), %d/%d R15 stage villains (C2), %d R15 template rigs, %d eggs, %d configs compile, "
        .. "DropTables %s, HeroCatalog generated (%d heroes), 0 stray limbs.",
        amCount, #heroes, #HeroSystem.Heroes, #HeroSystem.LegacyHeroes, humanoidCount, minH, maxH, guardCount,
        #HeroSystem.ZoneOrder, rigCount, eggCount, configCount, table.concat(areaSummary, " "), #HeroSystem.Heroes))
    print("[HeroSystem] Hero System applied successfully!")
end

return HeroSystem
