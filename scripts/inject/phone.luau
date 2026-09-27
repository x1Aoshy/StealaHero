-- scripts/inject/phone.luau (TREADMILL owner, VISUAL_PASS_PLAN D4; FLAPPY 2026-09-23: full screen + leaderboard)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The treadmill's TikTok-style video player is
-- replaced by the SpeedPhone: a Speedsters smartphone with the "Hero Flap" minigame, shown while the local player
-- trains ON the treadmill's screen (the skin's PhoneScreen part from scripts/steps/treadmill.luau, through a PlayerGui
-- SurfaceGui), or as a 2D phone on the right side of the screen when the treadmill has no PhoneScreen, or FULL SCREEN
-- (a large centred 2D overlay the player toggles). Its template (StarterGui.SpeedPhone) and the screens' idle
-- SurfaceGuis are built by scripts/steps/ui_60_treadmill.luau; this LocalScript drives it.
-- FlappyService (server Script): validated Hero Flap scores, each player's best (profile FlappyBest) and the global
-- TOP 10 (OrderedDataStore "FlappyBest_v1", this server's players only when the store is unavailable).
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/SpeedPhone",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/SpeedPhone.client.luau",
		create = true,
	},
	{
		target = "ServerScriptService/FlappyService",
		class = "Script",
		source = "src/ServerScriptService/FlappyService.server.luau",
		create = true,
	},
}
