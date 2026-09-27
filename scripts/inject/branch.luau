-- scripts/inject/branch.luau (owner 2026-09-27: Branch framework, network hardening, performance)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. scripts/steps/post_branch_framework.luau installs
-- the Branch runtime (ReplicatedStorage.Packages.Branch) and the segment roots these go into.
--   ServerScriptService/BranchServer                 Branch:Start(BranchServices)
--   BranchServices/NetGuardService                    flood / oversized-payload guard on every RemoteEvent
--   BranchServices/ServerStatsService                 ServerHz / ServerFrameMs / ServerMemoryMB workspace attributes
--   BranchServices/LagCompensationService             position history + "where did this player see it" for hit checks
--   StarterPlayerScripts/BranchClient                 Branch:Start(BranchControllers)
--   BranchControllers/UiLifeController                idle UI animations (breathe / bob / sweep / twinkle)
--   BranchControllers/PerfController                  plot billboards capped to a render distance; phone budget
--   BranchControllers/UiScaleController               HUD groups scaled per device (phone / tablet / console)
return {
	{
		target = "ServerScriptService/BranchServer",
		class = "Script",
		source = "src/ServerScriptService/BranchServer.server.luau",
		create = true,
	},
	{
		target = "ServerScriptService/BranchServices/NetGuardService",
		class = "ModuleScript",
		source = "src/ServerScriptService/BranchServices/NetGuardService.luau",
		create = true,
	},
	{
		target = "ServerScriptService/BranchServices/ServerStatsService",
		class = "ModuleScript",
		source = "src/ServerScriptService/BranchServices/ServerStatsService.luau",
		create = true,
	},
	{
		target = "ServerScriptService/BranchServices/LagCompensationService",
		class = "ModuleScript",
		source = "src/ServerScriptService/BranchServices/LagCompensationService.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/BranchClient",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/BranchClient.client.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/BranchControllers/UiLifeController",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/BranchControllers/UiLifeController.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/BranchControllers/UiScaleController",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/BranchControllers/UiScaleController.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/BranchControllers/PerfController",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/BranchControllers/PerfController.luau",
		create = true,
	},
}
