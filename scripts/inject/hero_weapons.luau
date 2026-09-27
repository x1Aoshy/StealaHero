-- scripts/inject/hero_weapons.luau (owner 2026-09-27, "MISSION: replace the bat system with Hero Gadgets")
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The weapon tools and the attack clips
-- (ReplicatedStorage.Directory.WeaponAnimations) are built by scripts/steps/post_hero_weapons.luau; GearService
-- (scripts/inject/gear.luau) resolves the hits and holds the victims' movement.
--   Library/Modules/HeroWeapons          the shared weapon table: tool -> weapon, kinds, ranges, effects, timing
--   Library/Modules/HeroWeaponTools      the owner's weapon kit (Prepare / Attach / SetGomuTime) + SetStretch / SetPoleTime
--   Library/Client/WeaponPortrait        the weapon's ViewportFrame icon (hotbar slot, Index stage card)
--   BranchControllers/HeroWeaponController  attack clips on every attacker, projectiles, the victims' 2.5 s states
return {
	{
		target = "ReplicatedStorage/Library/Modules/HeroWeapons",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Modules/HeroWeapons.luau",
		create = true,
	},
	{
		target = "ReplicatedStorage/Library/Modules/HeroWeaponTools",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Modules/HeroWeaponTools.luau",
		create = true,
	},
	{
		target = "ReplicatedStorage/Library/Client/WeaponPortrait",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Client/WeaponPortrait.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/BranchControllers/HeroWeaponController",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/BranchControllers/HeroWeaponController.luau",
		create = true,
	},
}
