-- scripts/inject/gekko_bases.luau (BASES, Gekko TO DO #5 "Index Completion Rewards": stage-themed bases)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. PlotService (theme application) and Database
-- (UnlockedBaseThemes / EquippedBaseTheme defaults) are injected by the build itself from their src mirrors; the
-- themed props, the preview models and the equip remote are built by scripts/steps/post_zz_base_themes.luau, the Index
-- page by scripts/steps/ui_75_base_themes.luau.
--   Directory/BaseThemes        the six themes (stage key, names, palettes, fence recolour) + progress helpers
--   Controllers/IndexService    unlocks a theme when its stage's Hero Index is complete (live + on join), answers
--                               Network["BaseThemes: RequestEquip"] (src mirror checked equal to the base place Source
--                               before patching)
--   GUI/BaseThemes              drives the Index "STAGE BASES" page (progress, 3D preview, EQUIP / EQUIPPED)
return {
	{
		target = "ReplicatedStorage/Library/Modules/SunnyWind",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Modules/SunnyWind.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/SunnyWindController",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/SunnyWindController.client.luau",
		create = true,
	},
	{
		target = "ReplicatedStorage/Directory/BaseThemes",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Directory/BaseThemes.luau",
		create = true,
	},
	{
		target = "ServerScriptService/Controllers/IndexService",
		class = "ModuleScript",
		source = "src/ServerScriptService/Controllers/IndexService.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/BaseThemes",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/BaseThemes.client.luau",
		create = true,
	},
}
