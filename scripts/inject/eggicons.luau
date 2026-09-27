-- scripts/inject/eggicons.luau (HATCH owner, 2026-09-23)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
-- EggIcons: owner "Add Inventory Icons for each egg (once Ani has made them)". A data module mapping hero id ->
-- egg icon image id (0 = not uploaded yet, the generic egg image stays). The backpack / hotbar
-- (StarterPlayerScripts.GUI.BackpackController.Main, scripts/inject/backpack.luau) resolves every egg icon through it.
return {
	{
		target = "ReplicatedStorage/Directory/EggIcons",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Directory/EggIcons.luau",
		create = true,
	},
}
