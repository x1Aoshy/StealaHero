-- scripts/inject/animpolish.luau (ANIMPOLISH, "improve hero animations in your pen")
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b: the pen wander simulation modules of
-- ActiveAssetsController, rewritten from their decompiled base Sources (the src mirrors were verified equal to the base
-- place before the rework) plus the new pen space. HeroClipPlayer / AssetComponent / AssetHeroMotion are injected by
-- gekko_anims.luau / hideheroes.luau / gekko_heroes.luau from their mirrors.
--   AssetWanderArea         wander rectangle with a per-hero margin (footprint + clearance: no fence poking)
--   AssetWanderMotion       eased, rate-limited turning; walking where the hero faces (no crab-walk / moonwalk)
--   AssetWanderSimulator    footprint, speed profile (clip cadence band), pen spacing, Special idle hold
--   AssetPersonalityMotion  destination helpers take the margin
--   AssetRetreatMotion      retreat destinations take the margin
--   AssetPenSpace (new)     heroes / obstacles / eggs of a pen: steering, destination room, overlap resolution
local base = "StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/"
local src = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/"

local entries = {}
for _, name in ipairs({ "AssetWanderArea", "AssetWanderMotion", "AssetWanderSimulator", "AssetPersonalityMotion", "AssetRetreatMotion" }) do
	table.insert(entries, { target = base .. name, class = "ModuleScript", source = src .. name .. ".luau", create = false })
end
table.insert(entries, { target = base .. "AssetPenSpace", class = "ModuleScript", source = src .. "AssetPenSpace.luau", create = true })

return entries
