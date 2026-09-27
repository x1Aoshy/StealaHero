-- scripts/inject/night.luau (NIGHT owner; owner 2026-09-23: "Make Night tp you back to spawn")
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
-- The night reset sends every player still out in the stages back to their plot. The server half lives in
-- ServerScriptService.Controllers.AreaEggService (synced by the build's controller step) and creates
-- ReplicatedStorage.Network["Eggs: NightTeleport"]; this client script shows the fade and the toasts.
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/NightTeleportCue",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/NightTeleportCue.client.luau",
		create = true,
	},
}
