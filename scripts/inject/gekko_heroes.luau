-- scripts/inject/gekko_heroes.luau (HEROES, Gekko TO DO #6 Hero Size, #7 hero movement / VFX polish, #8 presentation)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The other scripts of this pass are already
-- injected from their src mirrors by other manifests (hideheroes.luau: ActiveAssetsController, AssetComponent,
-- GUI/Settings, Shared/Variables; vfx.luau: SabVfxController); the build-time model polish is
-- scripts/steps/post_heroes_polish.luau.
--   Directory/HeroMotion              per-hero movement style + VFX accent table (walk / float / dash / stomp / bounce)
--   Modules/AssetHeroSizePresentation visual-scale curve + the viewer's saved Hero Size choice (visual only)
--   ActiveAssetsController/AssetHeroMotion  the per-component motion / accent layer AssetComponent drives
--   Controllers/SettingsService       accepts ("HeroSize", "Small" | "Normal" | "Big") next to the boolean settings
--                                     (src mirror checked equal to the base place before patching)
return {
	{
		target = "ReplicatedStorage/Directory/HeroMotion",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Directory/HeroMotion.luau",
		create = true,
	},
	{
		target = "ReplicatedStorage/Library/Modules/AssetHeroSizePresentation",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Modules/AssetHeroSizePresentation.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/AssetHeroMotion",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/AssetHeroMotion.luau",
		create = true,
	},
	{
		target = "ServerScriptService/Controllers/SettingsService",
		class = "ModuleScript",
		source = "src/ServerScriptService/Controllers/SettingsService.luau",
		create = false,
	},
}
