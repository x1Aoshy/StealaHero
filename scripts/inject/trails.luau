-- scripts/inject/trails.luau (TRAILS owner, 2026-09-23; owner: "Trails unpurchasable, needs fixing")
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
--
-- TrailService (server Script, new): answers the four Trails RemoteFunctions (Money purchase validated against
-- Directory.Trails, equip/unequip, active snapshot) and fires Trails: ActiveTrailChanged; every base-place server
-- Script is an empty stub and StubService only answered "Not available".
-- TrailShop (LocalScript, patched mirror): pcall'ed + debounced requests, purchase confirmation, Robux button hidden
-- (the configs' ProductIds are the ripped game's products). The build's step 6 also injects this same mirror.
-- TrailController (LocalScript, patched mirror): pcall'ed snapshot keyed by tostring(UserId).
-- Themed trails (TRAILS 2026-09-24, Gekko TO DO #4): scripts/steps/post_trail_fx.luau polishes every
-- Assets.Trails ribbon and builds Assets.TrailFx.<TrailId> for Legendary+; TrailService mounts that FX on the
-- character (server instances) and removes it on unequip / death / respawn / leave.
return {
	{
		target = "ServerScriptService/TrailService",
		class = "Script",
		source = "src/ServerScriptService/TrailService.server.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/Shops/TrailShop",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/Shops/TrailShop.client.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/TrailController",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/TrailController.client.luau",
		create = false,
	},
}
