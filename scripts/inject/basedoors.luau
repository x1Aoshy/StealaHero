-- scripts/inject/basedoors.luau (BASE DOORS + THEME VFX, owner 2026-09-26: "make sure the doors open ... for all the
-- bases ... when you go up" + "add some vfx to the bases for each one, something related to their theme")
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The gate data these read is written on every
-- Workspace.Plots.<n> by scripts/steps/post_zzz_base_doors.luau; the doors and effects are built on each client.
--   Modules.BaseDoors               door styles (6 themes + the plain pen), open / close state machine, builders
--   Modules.BaseThemeVfx            per-theme ambience (particles / beams on invisible anchors), distance gating
--   Game.Plots.BaseDoorController   builds / swaps each plot's door, opens it near any player, closes 2.5 s later
--   Game.Plots.BaseThemeVfxController  builds / swaps each themed plot's ambience, off beyond 180 studs
return {
	{
		target = "ReplicatedStorage/Library/Modules/BaseDoors",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Modules/BaseDoors.luau",
		create = true,
	},
	{
		target = "ReplicatedStorage/Library/Modules/BaseThemeVfx",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Modules/BaseThemeVfx.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/BaseDoorController",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/BaseDoorController.client.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/BaseThemeVfxController",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/BaseThemeVfxController.client.luau",
		create = true,
	},
}
