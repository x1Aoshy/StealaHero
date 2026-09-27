-- scripts/inject/ui_hud.luau
-- UI-HUD injection manifest (scripts/build_stealahero.luau step 13b). The HUD re-skin itself is a build step
-- (scripts/steps/ui_30_hud.luau); this adds the runtime Speedsters HUD juice LocalScript (CONTRACTS_PHASE3 D4).
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/SpeedstersJuice",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/SpeedstersJuice.client.luau",
		create = true,
	},
}
