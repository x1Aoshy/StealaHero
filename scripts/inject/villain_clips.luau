-- scripts/inject/villain_clips.luau (owner 2026-09-27: unique idle / run / attack per boss, Frieza's float)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The clip data is published by
-- scripts/steps/post_villain_animations.luau (ReplicatedStorage.Directory.VillainAnimations.<Villain>).
--   Game/VillainClipPlayer   writes the villains' Motor6D.Transform from their clips (GuardState / ChaseFx driven)
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/VillainClipPlayer",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/VillainClipPlayer.client.luau",
		create = true,
	},
}
