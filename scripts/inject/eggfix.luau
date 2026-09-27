-- scripts/inject/eggfix.luau (EGG-PLACEMENT fix owner)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
--
-- EggPlacementController: a freshly granted egg Tool (stolen-egg claim auto-equips it server-side
-- while the client still holds its local "CarriedEgg" visual Tool) could not be placed until it
-- was unequipped and re-equipped. The patched controller re-equips the egg Tool once the
-- overlapping Tool leaves and no longer relies only on Tool.Activated. Source = base-place
-- Source + that patch (see the header comment in the file).
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Eggs/EggPlacementController",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Eggs/EggPlacementController.client.luau",
		create = false,
	},
}
