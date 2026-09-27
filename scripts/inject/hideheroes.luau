-- scripts/inject/hideheroes.luau (HIDE owner)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
-- Settings > "Hide Your Heroes" (new setting key HideMyPets, default off) hides the local player's own pen heroes
-- the same way "Hide Other Heroes" (HideOtherPets) hides everyone else's; the "Disable Videos" row is renamed
-- "Hide Treadmill Phone" (key DisableVideos unchanged).
--   ActiveAssetsController   own components follow HideMyPets (SetHidden + billboard/occlusion/hover suppression)
--   AssetComponent           SetHidden also hides decals (faces) and effects; hidden heroes run the silent path
--   GUI/Settings             clones the Hide Your Heroes row, renames the treadmill-phone row, fixes row order
--   Shared/Variables         SettingsInfo.HideMyPets (also injected by windows.luau from the same source file)
-- SabVfxController (auras) is created by scripts/inject/vfx.luau from its src mirror, which carries the change.
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/init.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/AssetComponent",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/AssetComponent.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/Settings",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/Settings.client.luau",
		create = false,
	},
	{
		target = "ReplicatedStorage/Library/Shared/Variables",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Shared/Variables/init.luau",
		create = false,
	},
}
