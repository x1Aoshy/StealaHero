-- scripts/inject/portraits.luau (PORTRAITS owner, docs/HERO_MODELS_PLAN.md H3)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. HeroPortrait mounts live ViewportFrame
-- headshots of the hero models (no image upload is possible); the Hero Index (StarterPlayerScripts.GUI.Index, injected
-- by the build's step 8 block) and the Sell Heroes window (GUI.SellHeroes, scripts/inject/windows.luau) use it
-- instead of the old hero icons.
return {
	{
		target = "ReplicatedStorage/Library/Client/HeroPortrait",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Client/HeroPortrait.luau",
		create = true,
	},
	-- owner 2026-09-27: egg icons (hotbar / backpack, growing-egg list, Sell Heroes) show the hero's own voxel egg
	{
		target = "ReplicatedStorage/Library/Client/EggPortrait",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Client/EggPortrait.luau",
		create = true,
	},
}
