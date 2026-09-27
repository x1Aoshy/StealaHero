# Steal a Hero — Game-plan restructure contract (binding for every agent)

Source of truth: `Steal_A_Hero_Game_Plan.docx` (project root). Owner decision (2026-09-22): "follow the plan, restructure everything".
Pipeline rules still apply (scratchpad CONTRACTS.md §0: Lune gotchas — Content props, FontFace, per-corner radii, whole-subtree
Clone, WorldPivotData, CFrame.lookAt mirrored yaw, WeldConstraint.CFrame0; injection manifests in scripts/inject/*.luau; rule 4 for
patching non-injected base-place scripts; injected code = real Roblox, no infinite yields). Build to your own output:
`STEALAHERO_LENIENT=1 STEALAHERO_OUT=<scratch>/<agent>.rbxl lune run scripts/build_stealahero.luau`. Never write StealaHero.rbxl.
Tests in tests/ describe the OLD 9-zone/18-hero game; the lead rewrites them at the end — do not edit tests.

## 1. Stages (6) — internal zone keys stay, everything the player sees is the plan

The world has 9 legacy zones in a line along +X (Workspace.__OBJECTS.Areas.GuardAreas.<Key>, Directory.Areas._Index.<Key>,
Workspace.Ground.ZoneFloor_<Key>). Scripts hard-reference these keys ("Forest" has special runtime code), so the KEYS STAY; only
display, content and theme change. Zones 7-9 are retired.

| # | Stage (DisplayName) | Internal key | X range (floor top ≈ 2.05-2.08) | Active eggs | Hidden EggSpots | Villain (HeroId) | Villain scale | Chase signature |
|---|---|---|---|---|---|---|---|---|
| 1 | The Avengers | Forest | 72 – 170 | 6 | 12 | Thanos | 1.6 | heavy footsteps + camera shake when close |
| 2 | Justice League | Lake | 170 – 316 | 6 | 12 | Darkseid | 1.5 | heavy; glowing red eye beams VFX, slow-then-surge |
| 3 | Spider-Verse | Desert | 316 – 526 | 6 | 12 | Carnage | 1.2 | fast; leaps/lunges toward the carrier (burst jumps) |
| 4 | My Hero Academia | Jungle | 526 – 762 | 6 | 12 | Shigaraki | 1.1 | leaves a decay particle trail |
| 5 | Dragon Ball | Snow | 762 – 1086 | 6 | 12 | Frieza | 1.0 | floats (hover pose) + energy-beam VFX |
| 6 | One Piece | Volcano | 1086 – 1471 | 8 | 14 | Kaido | 1.9 | massive; ground-shake roar when close |
| — | retired | Abyss Ocean, Prehistoric, Cosmic | 1471 – 3045 | 0 | 0 | none | — | removed from play; the world ends in a closed wall after stage 6 |

Zone Z band ≈ −85 … +81. The hub/safe zone is X ≤ 75 (unchanged; villains stop at X = 80).

## 2. Heroes (38) — replaces the 18-hero Speedsters roster

Hero ids (AssetModels / Directory.Assets._Index / egg models / DropTables) with rarity per stage.
Base $/s by rarity: Common 25, Rare 60, Epic 120, Legendary 300, Mythic 850, Secret 2500 — multiplied by the stage factor
1 / 2 / 4 / 8 / 16 / 32 (stage 1 … 6). Egg GrowthTime by rarity: Common 20, Rare 30, Epic 45, Legendary 60, Mythic 90, Secret 120.

| Stage | Heroes (id — rarity) |
|---|---|
| 1 The Avengers | Hawkeye — Common · BlackWidow — Common · CaptainAmerica — Rare · Hulk — Epic · Thor — Legendary · IronMan — Mythic |
| 2 Justice League | Aquaman — Common · GreenLantern — Common · Flash — Rare · WonderWoman — Epic · Batman — Legendary · Superman — Mythic |
| 3 Spider-Verse | PeterParker — Common · SpiderGwen — Common · MilesMorales — Rare · SpiderMan2099 — Epic · AgentVenom — Legendary · Venom — Mythic |
| 4 My Hero Academia | Uraraka — Common · Bakugo — Common · Todoroki — Rare · Hawks — Epic · Deku — Legendary · AllMight — Mythic |
| 5 Dragon Ball | Krillin — Common · Trunks — Common · Piccolo — Rare · Gohan — Epic · Vegeta — Legendary · Goku — Mythic |
| 6 One Piece | Usopp — Common · Nami — Common · Brook — Rare · Sanji — Rare · Zoro — Epic · Shanks — Legendary · Luffy — Mythic · JoyBoy — Secret |

Display names: "Hawkeye", "Black Widow", "Captain America", "Hulk", "Thor", "Iron Man", "Aquaman", "Green Lantern", "The Flash",
"Wonder Woman", "Batman", "Superman", "Peter Parker", "Spider-Gwen", "Miles Morales", "Spider-Man 2099", "Agent Venom",
"Venom (Anti-Hero)", "Uraraka", "Bakugo", "Todoroki", "Hawks", "Deku", "All Might", "Krillin", "Trunks", "Piccolo", "Gohan",
"Vegeta", "Goku", "Usopp", "Nami", "Brook", "Sanji", "Zoro", "Shanks", "Luffy", "Joy Boy".

Drop weights inside a stage: Common 30 · Rare 18 · Epic 12 · Legendary 7 · Mythic 3 (One Piece: Common 25 · Rare 14 · Epic 9 ·
Legendary 5 · Mythic 2.5 · Secret 0.5). Each stage's DropTable lists ONLY its own heroes. Area config DisplayName = stage name,
plus StageNumber = 1…6.
Looks: no authentic models exist for most of these characters, so they are built procedurally (generic R15 body + colours +
part-built signature accessories: capes, helmets, hair, hats, shields, hammers, swords, wings, masks…) so each is recognisable
at a glance; heroes that already have authentic/near builds (Superman, Batman, Flash, Aquaman, Miles, Gwen, 2099, Venom, Spider-Man
→ PeterParker) keep them. Villains are built the same way at the scale in §1. Owner may later supply real models.

## 3. Stage environments and hidden eggs

Each stage gets a themed, blocky-stylised environment inside its X range (plan §Stage 1-6): Avengers = sleek sci-fi city,
Avengers-Tower-like tower, rooftops, glass/metal/blue holo; Justice League = dark rainy Gotham street with neon + a grand
Hall-of-Justice facade at the far end; Spider-Verse = Queens rooftops, fire escapes, water towers, cranes, rooftop gaps, web-line
beams (verticality); MHA = U.A. High grounds / training area (school building, track, training blocks); Dragon Ball = Namek /
tournament arena: teal-green grass, rocky spires, cliffs, capsule domes, arena ring; One Piece = pirate port: sand, wooden docks,
water, marine fortress towers, a docked pirate ship. Recolour that stage's ZoneFloor_<Key> to the theme.
Hard constraints (villain PathfindingService + players on mobile):
- a clear main street |Z| ≤ 12 along the whole stage with nothing collidable in it;
- every EggSpot reachable on foot from X = 75 without jumping (ramps/stairs ≤ 35°; villain has AgentCanJump = false);
- elevated spots ≤ 14 studs high; hazards allowed off the main street (no instant-kill; e.g. slowing puddles);
- difficulty grows stage to stage via layout complexity/verticality/hazards (plan §Build notes), not only villain speed;
- ≤ 450 parts per stage, all Anchored, Plastic/SmoothPlastic/Neon/Glass/Wood/Metal/Slate materials only, no scripts, no sounds,
  no meshes/textures from unknown owners; decorative parts CanQuery=false where possible.
EggSpot markers: `Workspace.StageEnvironments.<StageKey>.EggSpots.EggSpot_<n>` = invisible anchored non-collidable Part
(1x1x1), CFrame = the exact spot where the egg should sit (top of a walkable surface, upright), attribute `Hidden` = true/false.
StageKey = the internal zone key (Forest, Lake, …). Environments live in `Workspace.StageEnvironments.<StageKey>` (Model).

## 4. Hub
- A stage entrance gate at the start of each stage (X ≈ stage start) with the stage number + name and villain name; stage 1's
  gate faces the hub. A progression board in the hub lists the 6 stages in order.
- The two shops of the plan (Sell Heroes = Workspace.Stands Sell Stands/SellAll/SellHeldAsset; Trails = Stands.Pads.TrailShop)
  are placed around the stage-1 entrance on the hub side (X ≤ 75).
- Lobby = safe zone (unchanged).

## 4b. Amendments (lead decisions after the plan-coverage and integration-risk critics — binding)

A1 Retired zones (Abyss Ocean, Prehistoric, Cosmic): STAGES `:Destroy()`s their whole GuardAreas models, their
   Workspace.Ground.ZoneFloor_* parts and ZoneDivider_7, and moves AdminAbuseEggSpawn (CFrame only) to stage 1's street
   (X≈120, Z≈-20). HEROES iterates ONLY the 6 kept keys (ZoneOrder/ZoneGuards/section F/validator/stray-limb loops), never
   indexes a missing zone, keeps the 3 retired Directory.Areas._Index modules but writes `DropTable = {}` in them. CHASE and
   STAGES tolerate missing zones.
A2 Villain post + spawn: ENV-A/ENV-B place `Workspace.StageEnvironments.<Key>.VillainPost` (invisible anchored non-collidable
   1x1x1 Part at floor level, near the middle of the stage, at |Z| 14-20 beside the main street, with a clear 20x20 footprint
   and nothing collidable up to 14 studs over it). STAGES moves the whole Guard (every BasePart by the same CFrame delta, keep
   yaw facing -X toward the hub) onto it before the hero builder runs. CHASE: on pickup the villain "spawns" — it teleports with
   an arrival VFX to a reachable main-street point ~35 studs from the carrier on the side AWAY from the hub (or stays if already
   closer), then chases; after the chase it walks/teleports back to its post.
A3 Catches are 3D: catch only when |dy| ≤ 2.5*scale + 3 (and optionally line of sight); AgentRadius = max(2, 1.6*scale),
   AgentHeight = collider height. Carnage's leap = scripted arc/speed burst, never a Humanoid jump.
A4 One chase per stage: STAGES' attemptCarry refuses a new carry in a stage whose Guard GuardState is Waking/Chasing for another
   player, with the message "<Villain> is already hunting someone! Try again in a moment." (villain name from Guard attribute
   VillainName, fallback HeroId).
A5 Walls: ENV-A (X 76-526) and ENV-B (X 526-1471) build invisible, anchored, collidable side walls at Z≈+86 and Z≈-88, 40 tall,
   joined to ENV-B's end wall. STAGES removes the DeliveryHitbox branch from isInSafeZone (or moves DeliveryHitbox into the hub,
   X ≤ 70) so the hub is the only safe zone.
A6 Clearances: over the main street (|Z| ≤ 15) every collidable part's underside is ≥ 12 studs above the floor, otherwise
   CanCollide=false; decorative overheads CanQuery=false. Every route to an EggSpot is ≥ 8 studs wide with ≥ 12 studs headroom
   (Kaido). Gate pillars at |Z| ≥ 15. Keep the pads/corridors of A2 clear.
A7 Heights: elevated EggSpot budget per stage: 1 Avengers 8, 2 Justice League 10, 3 Spider-Verse 16, 4 MHA 14, 5 Dragon Ball
   18, 6 One Piece 20 studs; always a no-jump ramp route (≤ 35°, risers ≤ 1 stud); optional player-only parkour shortcuts allowed.
   EggSpots stay strictly inside the zone Bounds XZ (|Z| ≤ 72; stage 1 X ≥ 95), ≥ 3 studs apart; ≥ 50% have Hidden=true, and
   STAGES' rotation keeps ≥ 2 hidden spots among the active eggs and at least one Epic-or-better egg active per stage when possible.
A8 Hazards: parts with attribute `StageHazard` = "Slow" and number attribute `Factor` (0.4-0.8) — CanCollide=false,
   CanTouch=true, CanQuery=false, at |Z| > 15, never in the hub — slow players (not villains) while overlapping; density grows
   from stage 1 to 6. ENV agents only tag parts; STAGES owns the runtime (server Script via scripts/inject/stages.luau).
A9 Ambience: STAGES injects a client StageAmbience script choosing a lighting preset by the player's X (hub default; stage 2
   dark/rainy blue, 3 and 5 saturated, 6 warm) with tweened transitions. ENV-A adds a rain ParticleEmitter (built-in rbxasset
   texture) over the Gotham street. Optional: ≤ 1 outline Highlight per stage model (DepthMode Occluded).
A10 Names: never name a Workspace part like a character limb (Torso, Head, LeftArm, UpperTorso, ...) — prefix decor
   (e.g. Statue_Torso) — and never use the substring "cloud_" (the build deletes it). Gates, board and markers live under
   Workspace.StageEnvironments or Workspace.Hub, never under __OBJECTS.Areas.GuardAreas. Keep Bounds, ClosestExitPoint and
   RequiredSpeedSign in the 6 kept zones; STAGES moves RequiredSpeedSign next to its stage gate and ClosestExitPoint to the
   gate's hub-side edge (whole-model CFrame deltas, names kept).
A11 HEROES: guard attributes HeroId (Thanos|Darkseid|Carnage|Shigaraki|Frieza|Kaido), VillainName (display) and RigScale (the
   §1 scale); HipHeight scales. HeroCatalog.luau is generated from the same table as HeroSystem.Heroes (keep Get/GetStageHeroes
   and the rarity strings). The 9 removed Speedsters heroes and SpiderMan stay as legacy configs/AssetModels with DontRoll=true
   and in no DropTable, so old saves never index nil. Area configs also get a stage Emoji.
A12 CHASE: keep a single manifest for its files; banner + effects driven by replicated guard attributes; effects in
   Workspace.__DEBRIS, non-colliding; camera shake only for the chased carrier outside the safe zone, amplitude ≤ 0.5, respect
   a reduced-motion setting if one exists; no duplicate of the SabVfx villain aura; footsteps/roars are visual (no sounds).
   CHASE also owns ReplicatedStorage.Directory.Guards per-villain configs if it needs them.

## 5. Ownership (exclusive)
| Agent | Owns |
|---|---|
| ENV-A | `scripts/steps/env_a.luau` — environments + EggSpots for stages 1-3 (Forest, Lake, Desert) |
| ENV-B | `scripts/steps/env_b.luau` — environments + EggSpots for stages 4-6 (Jungle, Snow, Volcano) + the closing wall after stage 6 |
| STAGES | `scripts/steps/stages.luau` (runs after env_*; retire zones 7-9 safely, nests on EggSpots, gates, board, shop layout), `src/ServerScriptService/Controllers/AreaEggService.luau` (active-egg rotation: N active of M spots per stage), any retired-zone reference fixes in files nobody else owns (rule 4 + `scripts/inject/stages.luau`) |
| HEROES | `scripts/hero_system_builder.luau`, `scripts/r15_rig_factory.luau`, `src/ReplicatedStorage/Directory/HeroCatalog.luau` (38 heroes, stage metadata) — heroes, eggs, configs (DisplayName, rarity, income, R15 anims), area configs (DropTable + DisplayName + StageNumber), the 6 villain guards (HeroId per §1, scale, look) |
| CHASE | `src/ServerScriptService/Controllers/GuardChaseService.luau`, client guard files under `src/StarterPlayer/StarterPlayerScripts/Game/GuardAreas/`, new `src/StarterPlayer/StarterPlayerScripts/Game/VillainChaseFx.client.luau` (+ `scripts/inject/chase.luau`) — per-villain chase signatures (§1) and a clear "<VILLAIN> IS CHASING YOU!" banner on pickup; must ignore retired zones |
| LEAD | `scripts/build_stealahero.luau` (hooks ready: env_*.luau then stages.luau after the gear hook), tests, final build |
