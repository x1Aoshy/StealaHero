-- scripts/inject/vfx.luau (VFX owner)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
-- One new client script drives the SAB brainrot effects that scripts/steps/vfx.luau ports into
-- ReplicatedStorage.Assets.VFX.SAB. It only listens to what the game already broadcasts
-- (workspace.ClientRenderedAssets, Guard GuardState attributes, the carry/treadmill/money remotes), so no
-- other owner's script is touched.
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/SabVfxController",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/SabVfxController.client.luau",
		create = true,
	},
}
