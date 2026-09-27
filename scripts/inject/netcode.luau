-- scripts/inject/netcode.luau (owner 2026-09-27: "no lag, server Hz, network")
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. A base-place script patched in place (its src
-- mirror was checked equal to the base Source before the change):
--   Controllers/LeaderstatsService   one pair of Database callbacks for every player (it added two per join, never
--                                    removed) and the replicated Money text flushed at most once a second
return {
	{
		target = "ServerScriptService/Controllers/LeaderstatsService",
		class = "ModuleScript",
		source = "src/ServerScriptService/Controllers/LeaderstatsService.luau",
		create = false,
	},
}
