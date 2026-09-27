-- scripts/inject/treadmill_shop.luau (owner 2026-09-27: the speed shop's Upgrade Treadmill card)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The base-place script, patched (its src mirror
-- was checked equal to the base Source before the change):
--   GUI/Shop/TreadmillSpeedShop   the current / next tier icons show ViewportFrames of the tiers' real treadmill models
--                                 (ReplicatedStorage.Assets.Models.Treadmills) instead of the old renders.
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/Shop/TreadmillSpeedShop",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/Shop/TreadmillSpeedShop.client.luau",
		create = false,
	},
}
