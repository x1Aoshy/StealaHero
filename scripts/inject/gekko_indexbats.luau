-- scripts/inject/gekko_indexbats.luau (INDEXBATS, owner batch item 2: "Equip button in index for bats not working")
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
--
-- AreaIndexProgressComponent (ModuleScript, base place, src mirror checked equal before patching): a stage card's
-- reward row in the Index. Its EQUIP button now equips / unequips the stage bat (EQUIP -> EQUIPPED, hover or first
-- tap arms a red UNEQUIP) instead of going dead once the bat is owned. The request is answered by
-- ServerScriptService.GearService (scripts/inject/gear.luau); the Index LocalScript that renders the cards
-- (src/StarterPlayer/StarterPlayerScripts/GUI/Index/init.client.luau) is injected by build_stealahero.luau itself.
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/Index/AreaIndexProgressComponent",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/Index/AreaIndexProgressComponent/init.luau",
		create = false,
	},
}
