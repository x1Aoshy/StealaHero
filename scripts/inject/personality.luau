-- scripts/inject/personality.luau (LEAD)
-- Owner 2026-09-23 ("algunos npc de mi plot se ponen de cabeza"): Steal an Egg's "InvertedModel" personality showed
-- ~1.5% of heroes upside down on purpose. It no longer rolls (RollWeight 0) and AssetInvertedModelPresentation is a
-- no-op, so heroes that already have it in a save are shown upright. Both sources were checked equal to the base place
-- before patching (CONTRACTS rule 4).
return {
	{
		target = "ReplicatedStorage/Directory/Assets/Personalities",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Directory/Assets/Personalities.luau",
		create = false,
	},
	{
		target = "ReplicatedStorage/Library/Modules/AssetInvertedModelPresentation",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Modules/AssetInvertedModelPresentation.luau",
		create = false,
	},
}
