-- Injection manifest for owner INDEX (docs/VISUAL_PASS_PLAN.md D5). See scripts/build_stealahero.luau step 13b.
-- The Index LocalScript itself (StarterPlayerScripts.GUI.Index) is injected by the build's built-in step 8 block.
return {
	-- Stage card art (zone key -> Number, Name, File, ImageId, Colors); read by the Hero Index stage cards.
	{
		target = "ReplicatedStorage/Directory/StageArt",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Directory/StageArt.luau",
		create = true,
	},
}
