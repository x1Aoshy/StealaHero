-- scripts/inject/gekko_anims.luau (ANIMCORE, hero animation pipeline)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The authored clip data itself is published by
-- scripts/steps/post_hero_animations.luau (ReplicatedStorage.Directory.HeroAnimations.<HeroId>, one ModuleScript per
-- src/ReplicatedStorage/Directory/HeroAnimations/*.luau); AssetComponent / AssetHeroMotion carry the integration and are
-- injected by hideheroes.luau / gekko_heroes.luau from their src mirrors.
--   Library/Modules/HeroClipMath              pure clip evaluation (Blender easing curves, per-joint key tracks)
--   ActiveAssetsController/HeroClipPlayer     per-hero Motor6D.Transform writer: Idle / Move / Special + effects
return {
	{
		target = "ReplicatedStorage/Library/Modules/HeroClipMath",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Modules/HeroClipMath.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/HeroClipPlayer",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/HeroClipPlayer.luau",
		create = true,
	},
}
