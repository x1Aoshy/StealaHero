-- scripts/inject/topbar.luau
-- TOPBAR injection manifest (scripts/build_stealahero.luau step 13b). Owner report 2026-09-23: the TopbarPlus
-- InventoryIcon (backpack) and settings gear disappeared. TreadmillUI.Visibility no longer disables the TopbarPlus
-- container (PlayerGui.TopbarStandard) during treadmill sessions; see the header of the patched source.
-- The runtime topbar hardening / diagnostics live in GUI.SpeedstersJuice (scripts/inject/ui_hud.luau).
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/TreadmillUI/Visibility",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/TreadmillUI/Visibility.luau",
		create = false,
	},
}
