-- Injection manifest for owner STAGES (docs/STAGES_PLAN.md A8/A9). See scripts/build_stealahero.luau step 13b.
return {
	-- A8: "Slow" stage hazards (attributes StageHazard/Factor placed by the env steps) slow players, not villains.
	{
		target = "ServerScriptService/StageHazardService",
		class = "Script",
		source = "src/ServerScriptService/StageHazardService.server.luau",
		create = true,
	},
	-- A9: per-stage lighting mood by the local player's X.
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/StageAmbience",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/StageAmbience.client.luau",
		create = true,
	},
}
