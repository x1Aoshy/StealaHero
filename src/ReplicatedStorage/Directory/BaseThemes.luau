-- ReplicatedStorage.Directory.BaseThemes
-- Index completion rewards (Gekko TO DO #5, owner BASES): completing a stage's Hero Index (every hero of that stage
-- discovered) unlocks that stage's exclusive base theme, which the owner can equip on their plot. One theme per stage,
-- keyed by the stage's internal zone key (HeroCatalog.Stages[i].Key, Directory.StageArt), so saves read
-- UnlockedBaseThemes = { Forest = true, ... } and EquippedBaseTheme = "Forest" ("" = none).
--
-- Who reads this module:
--   ServerScriptService.Controllers.IndexService   unlocks (GetProgress / IsComplete) and validates equips (IsValidKey)
--   ServerScriptService.Controllers.PlotService    recolours the plot's StarterPen fence (Fence / FenceMaterials)
--   StarterPlayerScripts.GUI.BaseThemes            the Index "STAGE BASES" page (names, colours, progress)
--   scripts/steps/post_zz_base_themes.luau         (build time, loaded with Lune) the themed props (Palette) built per
--                                                  plot into ServerStorage.BaseThemes.<Key>.<plotId>
--   scripts/steps/ui_75_base_themes.luau           (build time) the page cards
-- It must stay loadable at build time: nothing at file scope may touch `script`, `game` or require(); the only global
-- used at load is Color3 (HeroCatalog is required lazily by the progress helpers).
--
-- Fence roles (PlotService classifies every visible StarterPen part, see post_hub_remodel.luau for the fence):
--   Post (navy stud posts), Cap (post caps), Gem (the small diamond on each cap), RailTop / RailLow (top / bottom
--   rail), Brace (the X brace), Gate (gate slats), Hinge (gate hinge bars).

-- Names / taglines follow the Blender v3 bases (assets/models/bases/<Key>, INTEGRATE3 2026-09-25); until the owner's
-- Studio import of each FBX, PlotService / post_zz_base_themes show the procedural fallback in the same stage colours.

local BaseThemes = {}

BaseThemes.Order = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }

local rgb = Color3.fromRGB

BaseThemes.Themes = {
	Forest = {
		Number = 1,
		Franchise = "The Avengers",
		Name = "Stark Lab",
		Short = "AVENGERS",
		Tagline = "Avengers Tower lab in graphite, steel and glass",
		Ui = { Top = rgb(255, 214, 92), Mid = rgb(206, 38, 46), Bottom = rgb(92, 14, 22), Accent = rgb(95, 211, 255) },
		Fence = {
			Post = rgb(34, 48, 79), Cap = rgb(179, 32, 42), Gem = rgb(95, 211, 255), RailTop = rgb(224, 176, 48),
			Brace = rgb(143, 26, 34), RailLow = rgb(58, 70, 96), Gate = rgb(179, 32, 42), Hinge = rgb(224, 176, 48),
		},
		FenceMaterials = { Gem = "SmoothPlastic" },
		Palette = {
			steel = rgb(42, 53, 80), steelDark = rgb(24, 31, 50), steelLight = rgb(86, 98, 126), red = rgb(179, 32, 42),
			redDark = rgb(120, 18, 26), gold = rgb(224, 176, 48), glow = rgb(95, 211, 255), glass = rgb(90, 150, 220),
			white = rgb(235, 244, 255),
		},
	},
	Lake = {
		Number = 2,
		Franchise = "Justice League",
		Name = "Hall of Justice",
		Short = "JUSTICE LEAGUE",
		Tagline = "Marble balustrade, gold portico, League shield",
		Ui = { Top = rgb(255, 231, 140), Mid = rgb(46, 92, 204), Bottom = rgb(18, 36, 96), Accent = rgb(255, 208, 64) },
		Fence = {
			Post = rgb(236, 234, 228), Cap = rgb(217, 165, 32), Gem = rgb(58, 123, 255), RailTop = rgb(217, 165, 32),
			Brace = rgb(29, 63, 143), RailLow = rgb(207, 202, 192), Gate = rgb(29, 63, 143), Hinge = rgb(217, 165, 32),
		},
		FenceMaterials = { Post = "Marble", RailLow = "Marble", Gem = "SmoothPlastic" },
		Palette = {
			marble = rgb(236, 234, 228), marbleShade = rgb(200, 196, 186), gold = rgb(217, 165, 32), goldLight = rgb(250, 214, 96),
			blue = rgb(29, 63, 143), blueLight = rgb(58, 123, 255), red = rgb(190, 30, 45), dome = rgb(220, 226, 236),
		},
	},
	Desert = {
		Number = 3,
		Franchise = "Spider-Verse",
		Name = "Brooklyn Rooftop",
		Short = "SPIDER-VERSE",
		Tagline = "Brick parapet, fire escapes and water towers",
		Ui = { Top = rgb(92, 244, 255), Mid = rgb(255, 47, 180), Bottom = rgb(40, 12, 60), Accent = rgb(255, 226, 58) },
		Fence = {
			Post = rgb(26, 26, 36), Cap = rgb(255, 47, 180), Gem = rgb(34, 228, 255), RailTop = rgb(255, 47, 180),
			Brace = rgb(34, 228, 255), RailLow = rgb(43, 43, 56), Gate = rgb(255, 226, 58), Hinge = rgb(26, 26, 36),
		},
		FenceMaterials = { Gem = "SmoothPlastic" },
		Palette = {
			asphalt = rgb(30, 28, 40), brick = rgb(74, 40, 62), brickDark = rgb(46, 26, 42), magenta = rgb(255, 47, 180),
			cyan = rgb(34, 228, 255), yellow = rgb(255, 226, 58), web = rgb(240, 240, 250), black = rgb(16, 16, 22),
			red = rgb(214, 24, 40), blue = rgb(40, 70, 190),
		},
	},
	Jungle = {
		Number = 4,
		Franchise = "My Hero Academia",
		Name = "U.A. Hero Arena",
		Short = "U.A. HIGH",
		Tagline = "Stadium barriers, floodlights and the 3D U.A. crest",
		Ui = { Top = rgb(140, 240, 170), Mid = rgb(31, 157, 85), Bottom = rgb(12, 60, 40), Accent = rgb(212, 42, 42) },
		Fence = {
			Post = rgb(242, 242, 242), Cap = rgb(212, 42, 42), Gem = rgb(47, 214, 122), RailTop = rgb(31, 157, 85),
			Brace = rgb(212, 42, 42), RailLow = rgb(201, 204, 212), Gate = rgb(28, 61, 110), Hinge = rgb(242, 242, 242),
		},
		FenceMaterials = { Gem = "SmoothPlastic" },
		Palette = {
			white = rgb(242, 242, 242), grey = rgb(170, 176, 188), concrete = rgb(196, 198, 204), red = rgb(212, 42, 42),
			green = rgb(31, 157, 85), greenLight = rgb(47, 214, 122), navy = rgb(28, 61, 110), glass = rgb(60, 120, 190),
			gold = rgb(240, 196, 60),
		},
	},
	Snow = {
		Number = 5,
		Franchise = "Dragon Ball",
		Name = "Capsule Corp Arena",
		Short = "CAPSULE CORP",
		Tagline = "Capsule domes and the 7 Dragon Balls",
		Ui = { Top = rgb(255, 222, 120), Mid = rgb(255, 138, 31), Bottom = rgb(20, 60, 160), Accent = rgb(31, 95, 214) },
		Fence = {
			Post = rgb(255, 138, 31), Cap = rgb(31, 95, 214), Gem = rgb(255, 178, 31), RailTop = rgb(31, 95, 214),
			Brace = rgb(255, 138, 31), RailLow = rgb(233, 226, 207), Gate = rgb(255, 138, 31), Hinge = rgb(31, 95, 214),
		},
		FenceMaterials = { Gem = "SmoothPlastic" },
		Palette = {
			orange = rgb(255, 138, 31), orangeDark = rgb(210, 96, 16), blue = rgb(31, 95, 214), blueDark = rgb(18, 52, 130),
			white = rgb(245, 245, 240), stone = rgb(226, 216, 190), stoneDark = rgb(170, 158, 130), star = rgb(214, 30, 30),
			ball = rgb(255, 170, 30), roof = rgb(46, 150, 90),
		},
	},
	Volcano = {
		Number = 6,
		Franchise = "One Piece",
		Name = "Sunny Pirate Wharf",
		Short = "STRAW HATS",
		Tagline = "The Thousand Sunny moored at a pirate wharf",
		Ui = { Top = rgb(255, 226, 140), Mid = rgb(192, 40, 45), Bottom = rgb(60, 34, 18), Accent = rgb(232, 199, 90) },
		Fence = {
			Post = rgb(107, 68, 35), Cap = rgb(224, 176, 64), Gem = rgb(255, 74, 42), RailTop = rgb(168, 116, 63),
			Brace = rgb(192, 40, 45), RailLow = rgb(91, 58, 30), Gate = rgb(168, 116, 63), Hinge = rgb(42, 42, 42),
		},
		FenceMaterials = { Post = "Wood", RailTop = "Wood", RailLow = "Wood", Gate = "Wood", Gem = "SmoothPlastic" },
		Palette = {
			wood = rgb(140, 92, 46), woodDark = rgb(91, 58, 30), woodLight = rgb(186, 132, 76), plank = rgb(160, 110, 60),
			sail = rgb(242, 230, 201), red = rgb(192, 40, 45), gold = rgb(224, 176, 64), black = rgb(24, 22, 22),
			white = rgb(245, 245, 240), straw = rgb(232, 199, 90), rope = rgb(196, 160, 100), iron = rgb(60, 60, 64),
		},
	},
}

for key, theme in pairs(BaseThemes.Themes) do
	theme.Key = key
end

BaseThemes.FENCE_ROLES = { "Post", "Cap", "Gem", "RailTop", "Brace", "RailLow", "Gate", "Hinge" }

function BaseThemes.IsValidKey(key: any): boolean
	return type(key) == "string" and BaseThemes.Themes[key] ~= nil
end

function BaseThemes.Get(key: any)
	if type(key) ~= "string" then
		return nil
	end
	return BaseThemes.Themes[key]
end

-- Lazily required HeroCatalog (a missing or failing catalog yields empty stage lists, never an error).
local catalog = nil
local catalogTried = false

local function getCatalog()
	if catalogTried then
		return catalog
	end
	catalogTried = true
	local ok, result = pcall(function()
		local module = script.Parent:FindFirstChild("HeroCatalog")
		return module and require(module)
	end)
	if ok and type(result) == "table" then
		catalog = result
	else
		warn("[BaseThemes] Directory.HeroCatalog unavailable: " .. tostring(result))
	end
	return catalog
end

-- Hero ids (= Index categories) of the theme's stage, in roster order.
function BaseThemes.GetStageHeroIds(key: any): { string }
	local theme = BaseThemes.Get(key)
	local heroCatalog = getCatalog()
	local ids = {}
	if theme == nil or heroCatalog == nil or type(heroCatalog.List) ~= "table" then
		return ids
	end
	for _, hero in ipairs(heroCatalog.List) do
		if type(hero) == "table" and hero.Stage == theme.Number and type(hero.Id) == "string" then
			table.insert(ids, hero.Id)
		end
	end
	return ids
end

-- (discovered, total) for the theme's stage against a profile.Index table.
function BaseThemes.GetProgress(index: any, key: any): (number, number)
	local ids = BaseThemes.GetStageHeroIds(key)
	local found = 0
	if type(index) == "table" then
		for _, id in ipairs(ids) do
			if index[id] == true then
				found += 1
			end
		end
	end
	return found, #ids
end

-- true once every hero of the stage is discovered (a stage without roster heroes is never complete).
function BaseThemes.IsComplete(index: any, key: any): boolean
	local found, total = BaseThemes.GetProgress(index, key)
	return total > 0 and found >= total
end

return BaseThemes
