-- scripts/inject/weather.luau (RAIN owner, docs/HERO_MODELS_PLAN.md H5)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
-- The Justice League (Lake) rain is drawn on each client: a camera-following rain ceiling, raycast-placed splashes,
-- street mist and lightning flashes, only while the local player is inside the stage region declared by
-- Workspace.StageEnvironments.Lake.Rain.RainVolume (scripts/steps/env_a.luau). The darker lighting of the stage is
-- StageAmbience's stage-2 preset (scripts/inject/stages.luau).
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/StageWeather",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/StageWeather.client.luau",
		create = true,
	},
}
