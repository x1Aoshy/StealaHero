-- CHASE injection manifest (the single manifest for the villain chase; STAGES_PLAN A12): server-side
-- villain chase + per-villain signatures, the client guard patches and the client chase presentation.
-- AreaEggService, GenericGuardRuntime and ForestGuardRuntime are injected by build_stealahero.luau itself.
return {
	{
		target = "ServerScriptService/Controllers/GuardChaseService",
		class = "ModuleScript",
		source = "src/ServerScriptService/Controllers/GuardChaseService.luau",
		create = true,
	},
	{
		-- Base-place LocalScript (StarterPlayer.StarterPlayerScripts.Game.GuardAreas), patched to skip the
		-- client chase runtime for ServerChase zones, ignore retired zones and apply "Guards: ServerHit" knockback.
		target = "StarterPlayer/StarterPlayerScripts/Game/GuardAreas",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/GuardAreas/init.client.luau",
		create = false,
	},
	{
		-- Base-place ModuleScript under that LocalScript (mirror == base Source before the patch): the stage's
		-- RequiredSpeedSign now solves for the farthest active egg and the spawn-on-pickup villain.
		target = "StarterPlayer/StarterPlayerScripts/Game/GuardAreas/GuardEscapeSignController",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/GuardAreas/GuardEscapeSignController.luau",
		create = false,
	},
	{
		-- New LocalScript: "<VILLAIN> IS CHASING YOU!" banner, safe-zone meter, per-villain chase effects.
		target = "StarterPlayer/StarterPlayerScripts/Game/VillainChaseFx",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/VillainChaseFx.client.luau",
		create = true,
	},
}
