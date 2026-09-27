-- scripts/inject/admin_panel.luau (owner 2026-09-27: "an admin panel for the devs ... blocky like everything, only
-- 767108248, the owners and people with Studio access"; round 10: "migrate the taco event to the admin panel")
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The BranchServices / BranchControllers roots
-- are created earlier by scripts/steps/post_branch_framework.luau, so nothing here touches scripts/inject/branch.luau.
--   ServerScriptService/HeroAdminAccess                    the admin rule (UserId 767108248, the game's owner, Studio)
--   ServerScriptService/BranchServices/HeroAdminService    Network["Admin: Command"], the commands, hands out the panel
--   ServerScriptService/BranchServices/TacoRainService     the Taco Rain event (tacos falling on eggs: x3 "Taco")
--   StarterPlayerScripts/BranchControllers/TacoRainController   its sky, music, falling tacos and explosions
--   ReplicatedStorage/Library/Modules/Mutations            the base module (its src mirror equalled the base Source)
--                                                          plus the "Taco" mutation (x3, never rolled)
-- The panel itself (ServerStorage.HeroAdminPanel + its LocalScript HeroAdminClient) is built by
-- scripts/steps/ui_85_admin_panel.luau: ServerStorage does not exist for clients, so only admins ever receive it. The
-- taco assets are published by scripts/steps/post_taco_rain.luau.
return {
	{
		target = "ServerScriptService/HeroAdminAccess",
		class = "ModuleScript",
		source = "src/ServerScriptService/HeroAdminAccess.luau",
		create = true,
	},
	{
		target = "ServerScriptService/BranchServices/HeroAdminService",
		class = "ModuleScript",
		source = "src/ServerScriptService/BranchServices/HeroAdminService.luau",
		create = true,
	},
	{
		target = "ServerScriptService/BranchServices/TacoRainService",
		class = "ModuleScript",
		source = "src/ServerScriptService/BranchServices/TacoRainService.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/BranchControllers/TacoRainController",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/BranchControllers/TacoRainController.luau",
		create = true,
	},
	{
		target = "ReplicatedStorage/Library/Modules/Mutations",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Modules/Mutations.luau",
		create = false,
	},
}
