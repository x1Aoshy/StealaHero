-- scripts/inject/ui_square.luau (owner 2026-09-27 square UI)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. SquareUi squares the UICorners scripts create
-- at runtime (the build squares the ones in the place: scripts/steps/ui_98_square_studs.luau).
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/SquareUi",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/SquareUi.client.luau",
		create = true,
	},
}
