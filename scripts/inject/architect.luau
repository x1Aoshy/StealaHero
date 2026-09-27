-- scripts/inject/architect.luau
-- ARCHITECT injection manifest (read by build_stealahero.luau step 13b).
-- Bootstrap, Database, NetworkInit, PlotService, EggService, AssetService and
-- OfflineAssetsService are already injected by build_stealahero.luau itself; only files the
-- build does not inject are listed here.
return {
	{
		-- Client/server $/s total (OfflineMoneyInPlotUI preview): base-place Source + the
		-- SpeedPower income factor, mirroring AssetService (also exports SpeedPowerFactor and
		-- ApplySpeedPower for the per-hero client displays).
		target = "ReplicatedStorage/Library/Util/PlayerMoneyPerSecondUtil",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Util/PlayerMoneyPerSecondUtil.luau",
		create = false,
	},
	{
		-- Placed-heroes list: base-place Source + per-hero $/s with the SpeedPower factor, so the
		-- rows match what AssetService pays and the pen billboards show.
		target = "StarterPlayer/StarterPlayerScripts/GUI/PetList",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/PetList/init.client.luau",
		create = false,
	},
}
