-- scripts/inject/gekko_lead.luau (LEAD, Gekko pass 2026-09-24)
-- ItemDisplay: the hero held as a Tool is drawn at AssetHeroSizePresentation.CompressScale(Scale) instead of its real
-- rolled Scale (a 10x-35x hero was 56-196 studs tall in the hand). The src mirror was checked byte-equal to the base
-- place Source before the patch. EggHatchAnimation (same change for the hatch reveal) is injected by hatch.luau.
return {
	{
		target = "ReplicatedStorage/Library/Modules/ItemDisplay",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Modules/ItemDisplay.luau",
		create = false,
	},
}
