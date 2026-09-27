-- scripts/inject/backpack.luau (LEAD)
-- Owner 2026-09-23: the inventory's "Pets" category reads "Heroes" and shows a big "H" instead of the paw image (its
-- internal key "Pets" is unchanged). BackpackController.Main was checked equal to the base place before patching.
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/BackpackController/Main",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/BackpackController/Main/init.luau",
		create = false,
	},
}
