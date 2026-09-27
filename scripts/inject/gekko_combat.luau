-- scripts/inject/gekko_combat.luau (COMBAT / Gekko TO DO 2 + 3)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
--
-- BatCombatFx (LocalScript): the bat swing every client animates (procedural wind-up + horizontal swing on the
-- waist / right-arm Motor6Ds, a white trail on the bat) and the hit feedback (SlapVFX impact burst, white flash,
-- pop sound), driven by the local click and by ServerScriptService.GearService's Network["Gear: BatFx"] events.
-- The server side (swing timing, contact-moment hit, carrier rules) lives in GearService (scripts/inject/gear.luau);
-- the remotes are created by scripts/steps/gear.luau.
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Tools/BatCombatFx",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Tools/BatCombatFx.client.luau",
		create = true,
	},
}
