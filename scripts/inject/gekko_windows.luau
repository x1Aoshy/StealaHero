-- scripts/inject/gekko_windows.luau (BASES, owner 2026-09-25: window lights in the modelled bases)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The pane Parts themselves are built by
-- scripts/steps/post_zz_base_themes.luau section 8 (one flat SmoothPlastic pane per window slot of a layout, in the
-- per-plot model's "ThemeWindows" group, tagged "BaseWindowLights"); this client script makes them turn off / on like a
-- city at night (nearby plots only, no per-frame work, cleaned up when the theme is unequipped).
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/BaseWindowLights",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/BaseWindowLights.client.luau",
		create = true,
	},
}
