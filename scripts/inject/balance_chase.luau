-- BALANCE (chase) injection manifest, owner-approved balancing 2026-09-23 (economy simulation):
--   #6 villain speeds for stages 4-6: Directory.Guards._Index.{Jungle,Snow,Volcano} WalkSpeed 82 -> 88, 98 -> 102,
--      113 -> 122 (base-place ModuleScripts; each src mirror == the base Source before the patch, CRLF aside).
--   #7 far-side eggs: GuardChaseService.resolveSpawnCFrame and GuardEscapeSignController._buildScenario are already
--      injected by scripts/inject/chaser.luau, so they have no entry here.
return {
	{
		target = "ReplicatedStorage/Directory/Guards/_Index/Jungle",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Directory/Guards/_Index/Jungle.luau",
		create = false,
	},
	{
		target = "ReplicatedStorage/Directory/Guards/_Index/Snow",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Directory/Guards/_Index/Snow.luau",
		create = false,
	},
	{
		target = "ReplicatedStorage/Directory/Guards/_Index/Volcano",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Directory/Guards/_Index/Volcano.luau",
		create = false,
	},
}
