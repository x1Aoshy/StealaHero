-- PRELOAD injection manifest (CHASE, owner 2026-09-23: "the first chase is dumb - maybe it needs a preloader"):
-- a client LocalScript that downloads the villain chase animations, the stage villains and the hero models at join,
-- so the first chase does not fetch them mid-chase. The server side of the cold start (navmesh warm-up, track priming)
-- lives in GuardChaseService (scripts/inject/chaser.luau).
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/AssetPreloader",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/AssetPreloader.client.luau",
		create = true,
	},
}
