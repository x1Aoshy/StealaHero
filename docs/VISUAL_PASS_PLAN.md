# Visual & gameplay pass — contract (owner request 2026-09-23, binding)

Single pass, no review loops. References: `design/references/01..10` (target look), stage art `assets/Stages/Stage1..6_*.png`
(941x1672, 9:16). Speedsters Visual Language: stud texture (UI: tiled ImageLabel rbxassetid://6927295847; 3D: Plastic +
MaterialVariant "Studs" as the ground uses), glossy vertical gradients (light top → saturated → dark bottom), thick ink outlines
(#0b1b3d UIStroke / SurfaceGui strokes), clean bold type (FredokaOne; GothamSSm Bold for big titles) — use
`scripts/lib/speedsters_ui_kit.luau` for UI. Pipeline rules + Lune gotchas: scratchpad CONTRACTS.md §0 (Content props via
roblox.Content, FontFace not Font, per-corner radii, whole-subtree Clone, WorldPivotData, CFrame.lookAt mirrored, injection
manifests scripts/inject/*.luau, rule 4 for patching non-injected base scripts). Keep every code identifier / protected GUI name
intact (only user-facing text changes). Build to your own output with STEALAHERO_LENIENT=1 STEALAHERO_OUT=<scratch path>.

## Decisions
D1 Only the 38 plan heroes + 6 villains exist: purge every legacy animal/brainrot asset (configs, AssetModels, egg models,
   drop/reward/limited/admin/mutation references) AND the 10 legacy Speedsters heroes (Zoom, ReverseFlash, Savitar, Sonic,
   SuperSonic, SilverSurfer, ATrain, Homelander, RedDeath, SpiderMan). Old saves: Database migration drops inventory/equipped
   entries whose asset id no longer exists (no refund needed; the game is pre-launch).
D2 Bat hit = real physics ragdoll on the victim (client-side BallSocket ragdoll of the Motor6Ds + fling impulse, ~1.5-2 s, then
   clean recovery), still drops a carried egg. Traps unchanged.
D3 No gear lying on the lobby floor: Workspace.GearGivers removed. Every player spawns with the basic Bat + Trap (Tier 1) in the
   Backpack (and StarterGear so respawns keep them). Subspace Trap (advanced) is NOT granted at start.
D4 Treadmill: new training HUD (clean spot that never covers the avatar; subtle stud frame; vibrant gradient "+SPEED" counter;
   progress bar). The TikTok-style vertical video player + comments (TreadmillVideoController, TreadmillScreen* SurfaceGuis,
   video/feed/comment/like/share/swap UI) is removed completely without leaving waits/errors. Replacement: a stylised
   SMARTPHONE frame with a playable Flappy-Bird-style minigame (tap / click / Space to flap, pipes, score, best score) shown
   while training, minimisable, also openable from a small phone button.
D5 Stage art: ReplicatedStorage.Directory.StageArt maps the 6 zone keys → { Name, Number, ImageId (0 = not uploaded yet),
   Colors }. The PNGs must be uploaded by the owner (we cannot upload); while ImageId is 0 the card shows a themed gradient +
   stud texture fallback. Index stage cards: vertical 9:16, ScaleType Crop, UICorner 10 px, floating title TextLabel + UIStroke.
   The 3 retired zones are formally removed from Directory.Areas._Index (and any other directory) if nothing breaks.
D6 Hub 3D remodel per refs 02-05 (plot fences + Upgrade Pen sign #1b2742 with red/gold price button; leaderboard with angled
   crown, electric-blue studded frame, stepped base; Watch-Ad sign emerald studded frame + "CLICK TO CLAIM" glossy button;
   gold-studded gift chest with a big cubic lock and floating glow; Sell stall red/white curved striped awning + 3D "SELL" sign;
   Trails stall yellow/white awning + 3D "TRAILS SHOP" sign). Keep every scripted contract (names/classes the controllers read,
   PlotUpgrade/TreadmillUpgrade sign structure, shop prompts/pads, leaderboard SurfaceGui targets).
D7 HUD/windows per refs 06-10: Shop/Index sidebar buttons keep position/shape (glossy stud gradients: green Shop, cyan Index,
   sticker icons with white border, red round badge); bottom-left currency pills (Speed with "+" button, Money, Friend Boost:
   dark translucent pills, rounded, bold icons, high-contrast UIStroke); night timer floating pill (translucent night blue, glowing
   moon); Sell Heroes window (header glossy green #00e676→#00b0ff, round embossed X, dark studs 15%, side tabs HEROES/EGGS, glossy
   Sell button); Free Gift window (cyan header "Free Gift!", speed bag, "~ LIMITED TIME! ~", "10,000 SPEED!", 3 step cards,
   giant green "Claim!"). "Pets" → "Heroes" in every user-facing text.

D8 SCRATCH LAYOUT (for the owner's builder, who will import real 3D buildings): the procedural stage buildings (towers,
   hangars, houses, roofs, rooftop chains, ships, fortresses, props) are NOT in the active Workspace. A post step moves them to
   `ReplicatedStorage.Archived_ProceduralEnvironments.<Key>` (kept as backup, not deleted). What STAYS in Workspace: the main
   street |Z| ≤ 15 clear; `Workspace.Ground.ZoneFloor_*` with their colours/heights; the perimeter walls (zone Bounds, side
   walls, the end wall) and the safe zone X ≤ 75; per-stage lighting/atmosphere presets (StageAmbience / LightingsController);
   the stage gates `Workspace.Hub.StageGates.StageGate_1..6` with their official names; the VillainPost / EggSpot markers and the
   small egg-cover rocks of D9.
D9 EGGS AROUND THE VILLAIN: in every stage the EggSpots (12; One Piece 14) form a ring / horseshoe on the ground around that
   stage's VillainPost at 12-28 studs from it. Move each VillainPost off the street to the middle of its stage at |Z| ≈ 40
   (alternate +Z/-Z per stage), facing -X toward the hub, with the horseshoe opening toward the street and every spot at
   |Z| ≥ 16 and |Z| ≤ 72, inside the stage X range, ≥ 3 studs apart, resting on the floor (walkable top = baseplate 2.05; nests
   keep Root / EggSpotBottom / EggFitBounds). ≥ 50% of spots Hidden=true, each hidden one tucked behind a low cover rock
   (Slate/Rock-coloured blocks ≤ 3.5 studs tall, anchored, collidable, never blocking the ring's walkable access) kept in
   `Workspace.StageEnvironments.<Key>.EggCover`. The nest-creation, N-of-M rotation and villain relocation code
   (scripts/steps/stages.luau, AreaEggService) keep working unchanged on the new markers.

## Ownership (exclusive)
| Agent | Owns |
|---|---|
| CLEANUP | NEW scripts/steps/post_purge.luau; scripts/hero_system_builder.luau + scripts/r15_rig_factory.luau (only to drop the legacy roster / HeroCatalog regeneration); src/ServerScriptService/Library/Database.luau (migration); src/ServerScriptService/GearService.server.luau; scripts/steps/gear.luau; NEW client ragdoll script + scripts/inject/gear.luau |
| TREADMILL | treadmill client scripts (src/StarterPlayer/StarterPlayerScripts/Game/Plots/Treadmill*, TreadmillPositionLockController), src/ReplicatedStorage/Library/Client/TreadmillVideoController/* and other Library.Client.Treadmill* modules, scripts/steps/treadmill.luau (video parts in skins), NEW scripts/steps/ui_60_treadmill.luau, NEW src/StarterPlayer/StarterPlayerScripts/GUI/SpeedPhone.client.luau (+ training HUD script if new), scripts/inject/treadmill.luau + NEW scripts/inject/phone.luau |
| INDEX | NEW src/ReplicatedStorage/Directory/StageArt.luau (+ scripts/inject/stageart.luau), src/StarterPlayer/StarterPlayerScripts/GUI/Index/init.client.luau, NEW scripts/steps/ui_25_index_stages.luau, NEW scripts/steps/post_areas_retire.luau |
| HUB3D | NEW scripts/steps/post_hub_remodel.luau (fences, signs, leaderboard, watch-ad sign, gift chest, stalls) + any hub-object script patch it truly needs via NEW scripts/inject/hub.luau |
| HUD | scripts/steps/ui_30_hud.luau |
| WINDOWS | scripts/steps/ui_20_windows.luau, NEW scripts/steps/ui_90_terms.luau (Pets→Heroes text pass, runs last) |
| SCRATCH | scripts/steps/env_a.luau, scripts/steps/env_b.luau (VillainPost + EggSpot ring + EggCover rocks; they may keep building their geometry at build time), NEW scripts/steps/post_scratch_layout.luau (archives buildings to ReplicatedStorage, keeps the D8 layout), scripts/steps/stages.luau only if a change is strictly needed for D9 |
| TESTS | tests/ (after all others) |
| LEAD | scripts/build_stealahero.luau (hooks: ui_*.luau after the base UI pass; post_*.luau after the hero builder), final build |
