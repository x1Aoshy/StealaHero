-- scripts/inject/npc.luau (NPC pass 2026-09-26: players never collide with NPCs, pen heroes never get stuck)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The src mirror below was checked equal to the
-- base place Source before the patch. The rest of the pass is injected by existing entries: Bootstrap (collision groups
-- Players / NPCs / Guards / HoverProbe + unconditional "Players" on every character) by the build script itself,
-- ItemDisplay (pen heroes in "NPCs") by gekko_lead.luau, GuardChaseService by chaser.luau, GearService (held gear never
-- collides) by gear.luau, the wander simulation modules (retreat commitment, owner-absent wandering, no-progress
-- watchdog, fence-aware obstacle push-out) by animpolish.luau; the static part (gear templates, invisible effect
-- templates, villains filed in "Guards") is scripts/steps/post_zzzz_npc_colliders.luau.
--   ModelMouseHover  the pen hero hover raycast runs as the "HoverProbe" group (it ran as "Players", which no longer
--                    sees the heroes in "NPCs")
return {
	{
		target = "ReplicatedStorage/Library/Client/UI/ModelMouseHover",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Client/UI/ModelMouseHover.luau",
		create = false,
	},
}
