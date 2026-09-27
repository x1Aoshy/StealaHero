-- scripts/inject/integrate3.luau (INTEGRATE3 2026-09-25)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. Base-place scripts patched while integrating
-- the owner batch of 2026-09-24 (each src mirror was verified equal to the base Source before the edit):
--   AssetMovementBatch  hero grounding no longer lands on placed eggs (eggs are pass-through, owner batch #5, and the
--                       heroes steer around them via AssetPenSpace): a hero clipping an egg's edge stays on the floor
local base = "StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/"
local src = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/"

return {
	{ target = base .. "AssetMovementBatch", class = "ModuleScript", source = src .. "AssetMovementBatch.luau", create = false },
}
