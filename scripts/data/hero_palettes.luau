--!nocheck
-- scripts/data/hero_palettes.luau
-- Egg palette of every roster hero (docs/HERO_MODELS_PLAN.md H4, owner EGGS): "los huevos los pintas con los colores
-- de ellos". Plain data (no requires), read by scripts/steps/post_egg_colors.luau and tests/suite_eggs.luau.
--
--   Base   = the egg shell (the dominant colour of the egg)
--   Accent = the band around the upper egg
--   Detail = the spots
-- Colours are {R, G, B} 0-255, picked from each character's canon look (suit / hair / signature item). Heroes that
-- share a scheme (Goku / Krillin, Superman / All Might, Venom / Agent Venom ...) differ in at least one role, so no two
-- eggs are identical. The 38 ids are the roster of docs/STAGES_PLAN.md §2 (tests/plan_data.luau PLAN.HEROES).

return {
	-- Stage 1 · The Avengers
	Hawkeye = { Base = { 104, 52, 146 }, Accent = { 34, 30, 42 }, Detail = { 205, 205, 215 }, Why = "purple suit, black straps, silver arrowheads" },
	BlackWidow = { Base = { 30, 30, 36 }, Accent = { 206, 30, 40 }, Detail = { 196, 92, 42 }, Why = "black catsuit, red hourglass, red hair" },
	CaptainAmerica = { Base = { 32, 62, 164 }, Accent = { 192, 30, 40 }, Detail = { 242, 242, 246 }, Why = "blue suit, red stripes, white star" },
	Hulk = { Base = { 72, 162, 52 }, Accent = { 102, 46, 142 }, Detail = { 34, 92, 30 }, Why = "green skin, purple pants, dark green shading" },
	Thor = { Base = { 62, 72, 96 }, Accent = { 182, 26, 36 }, Detail = { 204, 208, 218 }, Why = "dark armour, red cape, silver discs" },
	IronMan = { Base = { 178, 26, 32 }, Accent = { 222, 176, 52 }, Detail = { 150, 232, 255 }, Why = "red armour, gold faceplate, arc-reactor blue" },

	-- Stage 2 · Justice League
	Aquaman = { Base = { 232, 142, 34 }, Accent = { 32, 132, 72 }, Detail = { 244, 204, 72 }, Why = "orange scale shirt, green legs, gold trident" },
	GreenLantern = { Base = { 34, 168, 66 }, Accent = { 22, 24, 26 }, Detail = { 244, 244, 244 }, Why = "lantern green, black suit, white gloves" },
	Flash = { Base = { 196, 22, 28 }, Accent = { 250, 204, 32 }, Detail = { 246, 246, 246 }, Why = "red suit, yellow lightning, white emblem" },
	WonderWoman = { Base = { 178, 26, 36 }, Accent = { 32, 52, 146 }, Detail = { 228, 184, 46 }, Why = "red top, blue skirt, gold tiara and belt" },
	Batman = { Base = { 112, 112, 118 }, Accent = { 24, 24, 28 }, Detail = { 246, 202, 40 }, Why = "grey suit, black cowl and cape, yellow belt" },
	Superman = { Base = { 32, 72, 194 }, Accent = { 204, 26, 32 }, Detail = { 252, 212, 42 }, Why = "blue suit, red cape, yellow shield" },

	-- Stage 3 · Spider-Verse
	PeterParker = { Base = { 204, 26, 32 }, Accent = { 32, 62, 172 }, Detail = { 26, 26, 30 }, Why = "red suit, blue sides, black webbing" },
	SpiderGwen = { Base = { 242, 242, 246 }, Accent = { 222, 52, 142 }, Detail = { 38, 192, 192 }, Why = "white hood, pink and teal trims" },
	MilesMorales = { Base = { 24, 24, 30 }, Accent = { 214, 30, 36 }, Detail = { 238, 238, 242 }, Why = "black suit, red spider and webs, white eyes" },
	SpiderMan2099 = { Base = { 22, 36, 92 }, Accent = { 206, 30, 42 }, Detail = { 72, 132, 232 }, Why = "navy suit, red spider skull, blue highlights" },
	AgentVenom = { Base = { 20, 20, 24 }, Accent = { 242, 242, 246 }, Detail = { 132, 140, 124 }, Why = "black symbiote, white spider, tactical grey" },
	Venom = { Base = { 16, 16, 20 }, Accent = { 240, 240, 244 }, Detail = { 202, 30, 42 }, Why = "black symbiote, white spider and eyes, red tongue" },

	-- Stage 4 · My Hero Academia
	Uraraka = { Base = { 242, 132, 172 }, Accent = { 40, 40, 52 }, Detail = { 246, 240, 246 }, Why = "pink suit, black panels, white boots" },
	Bakugo = { Base = { 44, 44, 50 }, Accent = { 246, 132, 36 }, Detail = { 246, 226, 150 }, Why = "black suit, orange X and gauntlets, ash-blond hair" },
	Todoroki = { Base = { 236, 236, 242 }, Accent = { 202, 40, 42 }, Detail = { 168, 220, 255 }, Why = "white and red hair, ice blue" },
	Hawks = { Base = { 192, 22, 32 }, Accent = { 96, 72, 50 }, Detail = { 242, 192, 60 }, Why = "red wings, brown jacket, yellow goggles" },
	Deku = { Base = { 40, 128, 90 }, Accent = { 30, 30, 36 }, Detail = { 212, 40, 42 }, Why = "green suit, black details, red shoes" },
	AllMight = { Base = { 246, 202, 52 }, Accent = { 40, 82, 196 }, Detail = { 202, 36, 42 }, Why = "golden hair, blue suit, red trims" },

	-- Stage 5 · Dragon Ball
	Krillin = { Base = { 242, 136, 40 }, Accent = { 36, 70, 172 }, Detail = { 40, 40, 44 }, Why = "orange gi, blue belt, forehead dots" },
	Trunks = { Base = { 46, 56, 122 }, Accent = { 188, 162, 228 }, Detail = { 30, 30, 34 }, Why = "Capsule Corp jacket, lavender hair, black top" },
	Piccolo = { Base = { 84, 164, 62 }, Accent = { 96, 46, 132 }, Detail = { 242, 242, 242 }, Why = "green skin, purple gi, white cape" },
	Gohan = { Base = { 98, 52, 152 }, Accent = { 202, 40, 42 }, Detail = { 24, 24, 30 }, Why = "purple gi, red sash, black hair" },
	Vegeta = { Base = { 36, 66, 172 }, Accent = { 246, 246, 246 }, Detail = { 230, 186, 50 }, Why = "blue suit, white armour and gloves, gold trim" },
	Goku = { Base = { 246, 132, 30 }, Accent = { 32, 62, 172 }, Detail = { 252, 214, 52 }, Why = "orange gi, blue undershirt, Super Saiyan gold" },

	-- Stage 6 · One Piece
	Usopp = { Base = { 150, 104, 58 }, Accent = { 176, 192, 62 }, Detail = { 30, 26, 26 }, Why = "brown overalls, yellow-green bandana, curly black hair" },
	Nami = { Base = { 250, 146, 50 }, Accent = { 246, 246, 246 }, Detail = { 90, 166, 232 }, Why = "tangerine hair, white top, blue Clima-Tact" },
	Brook = { Base = { 236, 230, 214 }, Accent = { 24, 24, 30 }, Detail = { 122, 122, 132 }, Why = "bone white, black suit and afro, grey cane" },
	Sanji = { Base = { 242, 212, 92 }, Accent = { 28, 28, 34 }, Detail = { 62, 92, 172 }, Why = "blond hair, black suit, blue shirt" },
	Zoro = { Base = { 60, 142, 76 }, Accent = { 242, 242, 242 }, Detail = { 28, 28, 28 }, Why = "green hair and haramaki, white shirt, black bandana" },
	Shanks = { Base = { 172, 30, 32 }, Accent = { 28, 28, 34 }, Detail = { 240, 240, 236 }, Why = "red hair, black cloak, white shirt" },
	Luffy = { Base = { 204, 30, 32 }, Accent = { 236, 202, 92 }, Detail = { 42, 82, 182 }, Why = "red vest, straw hat yellow, blue shorts" },
	JoyBoy = { Base = { 248, 248, 250 }, Accent = { 242, 212, 150 }, Detail = { 152, 92, 212 }, Why = "Gear 5 white, cream cloud trims, purple accents" },
}
