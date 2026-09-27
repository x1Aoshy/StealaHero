-- scripts/inject/eggs_polish.luau (owner 2026-09-27 egg pass)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. Three base-place scripts, patched (each src
-- mirror was checked equal to the base Source before the change):
--   AreaEggResetTimeUtil  NightGrowthSkipSeconds = 1000 (a whole night of the x100 bonus; the client's night animation
--                         ended at 300 and the egg visibly shrank at dawn). The commit itself is EggService's.
--   GrowingEggList        each row shows the hero's own voxel egg (Library.Client.EggPortrait) over its image.
--   AreaEggs              an egg the stage villain lifted (State "GuardCarried") rides in the villain's arms until it is
--                         set down in its nest (GuardChaseService retrieval).
return {
	{
		target = "ReplicatedStorage/Library/Util/AreaEggResetTimeUtil",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Util/AreaEggResetTimeUtil.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/GrowingEggList",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/GrowingEggList.client.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/AreaEggs",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/AreaEggs/init.client.luau",
		create = false,
	},
}
