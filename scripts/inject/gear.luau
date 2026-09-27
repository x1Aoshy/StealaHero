-- scripts/inject/gear.luau (CLEANUP / gear owner)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
--
-- GearService (server Script): the starter kit every player spawns with (Bat + Trap in Backpack and StarterGear,
-- D3) and the gear itself (Bat swing + server-validated ragdoll, Trap / SubspaceMine placement), because every
-- server `Script` in the base place is an empty ripper stub and `Library.Modules.BatController.Server` requires a
-- ServerScriptService.Library tree that the base place does not contain.
-- GearRagdollController (LocalScript): the victim's side of the bat ragdoll (D2) - Physics state, limb collisions,
-- the fling impulse and the recovery - driven only by the server's Network["Gear: Ragdoll"] event.
return {
	{
		target = "ServerScriptService/GearService",
		class = "Script",
		source = "src/ServerScriptService/GearService.server.luau",
		create = true,
	},
	{
		-- the ToolController name check Directory.Gears.Types.Schema requires on the server (the base place has no
		-- ServerScriptService.Library.Tools, so Directory.Gears failed to load server-side)
		target = "ServerScriptService/Library/Tools",
		class = "ModuleScript",
		source = "src/ServerScriptService/Library/Tools.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Tools/GearRagdollController",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Tools/GearRagdollController.client.luau",
		create = true,
	},
}
