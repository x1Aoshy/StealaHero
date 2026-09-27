-- scripts/inject/admin_panel.luau (owner 2026-09-27: "an admin panel for the devs ... blocky like everything, only
-- 767108248, the owners and people with Studio access")
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The BranchServices root is created earlier by
-- scripts/steps/post_branch_framework.luau, so the service needs no change to scripts/inject/branch.luau.
--   ServerScriptService/HeroAdminAccess                    the admin rule (UserId 767108248, the game's owner, Studio)
--   ServerScriptService/BranchServices/HeroAdminService    Network["Admin: Command"], the commands, hands out the panel
-- The panel itself (ServerStorage.HeroAdminPanel + its LocalScript HeroAdminClient) is built by
-- scripts/steps/ui_85_admin_panel.luau: ServerStorage does not exist for clients, so only admins ever receive it.
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
}
