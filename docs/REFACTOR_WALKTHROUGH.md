# Steal a Hero — Refactor Walkthrough

Status (2026-09-21): `lune run scripts/build_stealahero.luau` builds `StealaHero.rbxl` cleanly (strict mode, no failed steps) and `lune run tests/run_all_tests.luau` passes **9/9 suites, 5,126 checks, 0 failures**.
Latest pass (owner playtest feedback): original green map floor restored; one treadmill per plot; the treadmill must be bought before it trains (§6, §6b).
Everything below was verified offline (Lune static checks, build-time validators, mock simulations, mutation testing). **Nothing has been playtested in Roblox Studio yet** — see §9 for what needs a live check.

---

## 1. Audit check

- The pipeline reads only `Steal An Egg with treadmill V2.rbxl` (`scripts/build_stealahero.luau`). The outdated VIP place is not referenced by any build step (only by old `scripts/audit_*` diagnostics).
- All 2,164 scripts in the built place pass `luau.compile`.

## 2. Build pipeline

`scripts/build_stealahero.luau` now supports parallel/isolated builds and pluggable steps:

| Feature | How |
|---|---|
| Output path | `STEALAHERO_OUT=<path>` (default `StealaHero.rbxl`) |
| Lenient mode | `STEALAHERO_LENIENT=1` logs and skips a failing step instead of aborting |
| Build steps | `scripts/steps/plots.luau`, `scripts/steps/treadmill.luau` (after plots are shifted), `scripts/steps/audio.luau` (after the final sound sanitize) |
| Injection manifests | `scripts/inject/*.luau` return `{ target, class, source, create }` entries; new scripts and patched base-place scripts are injected from here (tested automatically by `test_scripts_integrity`) |
| Model pivots | the plot/zone shift now also moves `WorldPivotData`, so pivots no longer sit ~600 studs away |
| Tests | `STEALAHERO_PLACE=<path>` points the suites at any build; `lune run tests/run_all_tests.luau test_plots` runs a subset |

## 3. Updated files

| Area | Files |
|---|---|
| Build | `scripts/build_stealahero.luau`, `scripts/steps/{plots,treadmill,ground,audio}.luau` (new), `scripts/inject/{architect,chaser,treadmill,uiaudio}.luau` (new) |
| Hero rigs | `scripts/r15_rig_factory.luau` (new), `scripts/hero_system_builder.luau` (rewritten) |
| Plots / data / network | `src/ServerScriptService/Controllers/PlotService.luau`, `Library/Database.luau`, `NetworkInit.server.luau`, `Bootstrap.server.luau` |
| Eggs / income | `Controllers/EggService.luau`, `Controllers/AssetService.luau`, `src/ReplicatedStorage/Library/Util/PlayerMoneyPerSecondUtil.luau`, `src/StarterPlayer/StarterPlayerScripts/GUI/PetList/init.client.luau` |
| Villain chase | `Controllers/GuardChaseService.luau` (new), `Controllers/AreaEggService.luau`, `StarterPlayerScripts/Game/GuardAreas/{init.client,GenericGuardRuntime,ForestGuardRuntime}.luau` |
| Treadmill | `Controllers/TreadmillGrindService.luau`, `Controllers/TreadmillSpawnService.luau`, `StarterPlayerScripts/Game/Plots/TreadmillStaticController/{init.client,Render}.luau` (the earlier `SpeedsterTreadmillVisibility` script was removed) |
| UI / audio | `scripts/apply_speedters_ui.luau`, `Library/Audio/{init,CreateMusicSound}.luau`, `Globals/Constants/_Index/BUTTON_FX.luau`, whitelist gates in `Functions/PreloadSounds`, `Client/Eggs/EggPlaceAnimation`, `Client/TreadmillVideoController/init`, `ObbyStages/BreakableBlocks/Sounds`, `Tools/Megaphone.client` |
| Tests | `tests/run_all_tests.luau` (hardened runner), `tests/_helpers.luau` (new), the 5 required suites (updated), `test_r15_rigs`, `test_treadmill`, `test_scripts_integrity`, `test_ground` (new) |

## 4. R15 hero rendering flow

1. **Source rigs.** `r15_rig_factory.luau` whole-clones `Workspace.Folder.Zoom` and `Workspace.Folder.ReverseFlashBoss` from `Update2/World1Update3New.rbxl`. It strips scripts, tools, VFX, sounds and dangling joints, then rescales them by hand from boss size (Scale 5.03 / 4.10) to Scale 1, about 5.2 studs tall. The generic body is ReverseFlashBoss without its suit.
2. **Per hero.** Zoom and Reverse Flash are authentic. The other 16 use the generic R15 body painted in hero colours, plus valid clothing, SkinRigs accessories (Superman, A-Train) and capes.
3. **AssetModel structure** (`ReplicatedStorage.AssetModels.<HeroId>`):
   - `HumanoidRootPart`: the PrimaryPart, 2×2×1, Massless, invisible. Its `AssetWeld` (WeldConstraint) joins it to the inner root.
   - `CENTER`: a small billboard anchor above the head, with `CenterWeld`.
   - `Model`: holds the inner `HumanoidRootPart`, `AnimationController > Animator`, the 15 R15 parts and the 15 standard Motor6Ds (Root, Waist, Neck, shoulders, elbows, wrists, hips, knees, ankles).
4. **Animation.** Configs use the Roblox-owned R15 Animate set: idle `507766388`, walk `507777826`.
5. **Hatch → plot.** When a hatch completes, EggService auto-places the hero on the owner's PetArea through `AssetService.EquipFromInventory`. The client `AssetComponent` wanders it with idle/walk. It falls back to a Backpack tool when the pen is full. No ghost tools are left behind.
6. **Icons.** Seven heroes show authentic Speedsters portraits (`rbxthumb://type=Asset&id=<SuitCatalog PreviewAssetId>`, the same method Speedsters uses): Flash, Reverse Flash, Zoom, Savitar, Sonic, Super Sonic and Silver Surfer. The rest use the Speedsters Hero Index icon, no longer the Chicken.
7. **Guarantees.** A build-time validator plus `test_r15_rigs` (2,931 checks) enforce joint integrity (no nil or external Part0/Part1), part and motor names, WeldConstraint classes, Scale = 1, height 4–7 studs, and no forbidden classes.

## 5. Villain pathfinding behaviour

Zone villains:

| Zone | Villain | Zone | Villain |
|---|---|---|---|
| Forest | Flash | Volcano | Red Death |
| Lake | Aquaman | Abyss Ocean | A-Train |
| Desert | Homelander | Prehistoric | Reverse Flash |
| Jungle | Spider-Man | Cosmic | Zoom |
| Snow | Batman | | |

Each guard is a jointed R15 villain at RigScale 1.25 with a Humanoid. It is driven **server-side** by `GuardChaseService`; the old client runtime is disabled for these zones via `ServerChase=true`.

- **Sleeping.** The guard is anchored at its post. The "!" alert and sleep VFX follow the `GuardState` / `TargetPlayer` attributes.
- **Wake.** A successful `Eggs: RequestAreaEggCarry` calls `startVillainChase`. The guard spends 0.63 s in Waking, then Chasing.
- **Chase.**
  - Unanchored and server-owned (`SetNetworkOwner(nil)`).
  - Paths use `PathfindingService:CreatePath` + `ComputeAsync` + `GetWaypoints`, recomputed at most every 0.3 s, with a straight `MoveTo` fallback when close or when a path fails.
  - Speed follows the zone config via `GuardChasePolicy`, catching up to 3× (capped at 360) when far behind.
  - Re-stealing a dropped egg makes the villain 1.6× faster for 8 s.
- **Safe zone.** The guard never goes below X = 80 and stops chasing once the carrier reaches X ≤ 75. It then returns to its post, snaps home and re-anchors. It teleports home if stuck or if it falls below Y = −200.
- **Catch.** Horizontal distance ≤ HitDistance plus a latency pad, with a 0.75 s cooldown. On a catch:
  1. the attack animation plays;
  2. `Guards: ServerHit` knockback fires to the carrier;
  3. the egg drops as `Dropped` and the carry resets;
  4. the guard walks the egg back to its nest (a 30 s timer covers other cases).
- **Hardening.**
  - A carry requires being within about 20 studs of the nest and outside the safe zone.
  - Dying, respawning or leaving while carrying returns the egg.
  - `ForestDeposit` claims only count inside the safe zone.
  - Client `Guards: ForestHit` is ignored for server-chased zones.
  - The bounty is paid exactly once.
- **Collision.** Guards pass through players (collision groups). Players still collide with each other, as in the base game.

## 6. Treadmill training experience

- **Buy first, as in the original game.**
  - At `BaseUpgradeLevel` 0 a plot shows only the buy sign: `PlotUpgrade`, "Unlock", **$8** (was $1,000 before the /125 money rescale of 2026-09-24).
  - Buying it (`Plots: RequestBaseUpgrade`) sets `BaseUpgradeLevel` to 1, and the treadmill appears with the base game's reveal.
  - Skins 1–10 are then sold on the `TreadmillUpgrade` sign.
- **The basic skin is the Speedsters treadmill.** The build step rewrites `ReplicatedStorage.Assets.Models.Treadmills.Treadmill` (tier 1) into the 17-part Speedsters `Workspace.neworld1.Basic.Treadmil`.
  - Scaled 0.699, so the belt matches `TreadmillBottom`.
  - Seated flush with the floor on every plot through the game's own grounding plus a `FloorAligned` / `TreadmillFloorY` correction.
  - It keeps the skin's functional parts: `Root`, `BoundingBoxPart`, the rate sign, and the video screen with its swap buttons.
  - Higher tiers keep their original skins.
- **Exactly one treadmill per plot.** Before this fix the owner saw two overlapping copies: the server render (`TreadmillSpawnService`, added by the rip) and the client render (`TreadmillStaticController`). The server copy still shows for everyone else. The owner's client hides it while it shows its own copy, which carries the video and effects.
- **Training.**
  - Stand on your own bought treadmill to gain SpeedPower plus **10 coins/s × the treadmill multiplier**. It is detected server-side against `TreadmillBottom`.
  - `TreadmillGrindService` pays nothing while `BaseUpgradeLevel` is 0, and `RequestEquipStatic` returns "Treadmill locked".
  - Fractional coins carry over, and database writes are batched to about 2 Hz.
- **Self-healing.** `Database.EnsureStatDefaults(profile)` runs at every profile load. `TreadmillGrindService.ensureStatDefaults` delegates to it and keeps a local per-tick guard, so fresh or corrupted profiles never nil-index.
- **Cash multiplier.** SpeedPower multiplies hero income by `1 + log10(max(SpeedPower,10)/10)`: 10 SP → 1×, 100 → 2×, 1000 → 3×. Online, offline and client displays all use the same formula.

## 6b. World ground

- The original floor was never in `Workspace.Map`; it lived in `Workspace.__OBJECTS.Build`, which is 1,320 instances of props, meshes, FX and invisible walls. That folder is still removed, and only its look and floor slabs are restored by `scripts/steps/ground.luau`.
- **Hub and plots.** The solid `Baseplate` (still 10000×20×3000, the only walkable floor) takes the original hub floor look: Plastic + MaterialVariant `Studs`, rgb(105,208,20), with the faint black 8-stud grid. This replaces the grey grid.
- **Zones.** `Workspace.Ground` holds the 9 original themed zone floors and 7 dividers, taken from `Build.1.BOTTOMS` / `Build.3` and shifted into place. They are visual only (no collide/query/touch), at their original height, groundY + 0.026, so nests are not buried.

  | Zone | Floor colour | Zone | Floor colour |
  |---|---|---|---|
  | Forest | 63,165,0 | Volcano | 49,43,39 |
  | Lake | 87,162,16 | Abyss Ocean | 0,32,96 |
  | Desert | 212,168,85 | Prehistoric | 171,126,44 |
  | Jungle | 36,126,16 | Cosmic | 0,0,0 |
  | Snow | 202,203,209 | | |

- Guard pathfinding, egg drops and the treadmill raycast still use the Baseplate, so their behaviour is unchanged. `test_ground` has 633 checks.

## 7. UI and audio

- Speedsters identity:
  - all 841 StarterGui texts use FredokaOne (via `FontFace`);
  - main windows and popups get the navy panel `#182644`, a 3 px ink `#0b1b2d` Border stroke and 10–14 px corners;
  - gold/cyan accents on the Money/Speed cards;
  - the HERO INDEX tab uses the Speedsters icon (the paw is hidden).
- `GamePanelStyle`, `StudUi` and `ModalJuice` are in `ReplicatedStorage.Library.Shared`.
- Plot sign: 230×64 Speedsters panel with a circular headshot (`rbxthumb://type=AvatarHeadShot&id=<userId>&w=150&h=150`), cyan ring and the player's DisplayName in FredokaOne.
- Audio whitelist — only these Speedsters ids are ever requested; everything else is silent:

  | Sound | Asset id |
  |---|---|
  | ui-bubble-click | 77120543307812 |
  | ui-pop-sound | 72264591133889 |
  | winner! | 127039883737564 |
  | SuccessSfx | 136993031050456 |
  | UpgradeBought | 80736831159506 |

  `Library.Audio` remaps legacy ids to these, uses bounded loads and never errors. Scripts that set `SoundId` directly (egg placement, treadmill video, the preloader, obby blocks, megaphone) are gated through `ResolveSoundUri` too.

## 8. Deliberate deviations from the mission spec

| Spec | Implemented | Why |
|---|---|---|
| `AssetWeld (Weld)` | WeldConstraint | the runtime (`AssetInvertedModelPresentation`) asserts WeldConstraint |
| CENTER 2×2×1 | small anchor above the head | the runtime sizes billboards from CENTER; 2×2×1 gives 35-stud billboards |
| Speedsters treadmill cloned onto every plot (`SpeedsterTreadmillModel`, `CanCollide = true`) | the Speedsters model is the look of the purchased tier-1 skin, rendered by the game's own treadmill system | a static always-present model gave a second treadmill and free training before purchase; skin parts stay non-collidable like the original skins, so the `TreadmillBottom` raycast keeps working |
| Villain chase inside AreaEggService | entry points in AreaEggService, engine in `GuardChaseService` | keeps egg state and guard physics separate; AreaEggService exposes `startVillainChase`/`onGuardCaughtPlayer`/`returnGuardToPost` |
| Bounty $150–$25,000 | table has all 9 tiers | no hero is Uncommon/Eternal/Divine, so the reachable maximum today is $7,500 (Secret) |
| Skip growth | refused | the old handler hatched every egg instantly for free; the ripped Robux product ids belong to another game |

## 9. Needs a Studio playtest or your input

1. **Audio 403s.** The 5 Speedsters ids load only if StealaHero and Speedsters share an owner (user or group). If not, grant the StealaHero experience access to each asset in Creator Dashboard.
2. **Hero clothing.** 10 heroes had catalog clothing ids that can't render as templates, so they show painted R15 bodies: Flash, Batman, Spider-Man, Miles Morales, Spider-Gwen, Red Death, Savitar, Sonic, Super Sonic, Silver Surfer. Open each catalog item in Studio, read its image template id, and put it in `HeroSystem.Heroes[..].ShirtId/PantsId`.
3. **Chase balance.** Guard speed against player speed. The tuning constants are at the top of `GuardChaseService.luau`.
4. **Engine behaviour.** Confirm in Studio:
   - R15 idle/walk on the AssetModels;
   - render-only Humanoid clothing;
   - server Humanoid chase physics at high WalkSpeed;
   - knockback feel;
   - that third-party meshes (Zoom mask, Reverse Flash suit) load.
5. **Egg skip growth.** To sell it, create your own developer products and wire a purchase receipt that sets `Placement.ReadyAt`.
6. **Eggs placed before this update** keep the old 50 s timer. New eggs use each hero's GrowthTime.
7. **Treadmill.** Check the look of the new basic skin, and whether the video screen sits well. It is 4.89 studs ahead of the runner and can be adjusted with `SCREEN_CENTER_HEIGHT` / `CONSOLE_CLEARANCE` in `scripts/steps/treadmill.luau`. Check the reveal animation and that the owner sees only one copy. Economy: new players ($2) need $8 from heroes before the treadmill pays, as in the original game (the /125 money rescale of 2026-09-24; it was $250 / $1,000).
8. **Ground.** The zone floors sit 0.026 studs above the green baseplate, as in the original. Check distant zones for z-fighting shimmer on low-end devices. If you'd rather have Roblox's literal `Grass` material texture instead of the original green `Studs` plastic, it's a one-line change in `scripts/steps/ground.luau`.

## 10. Commands

```bash
lune run scripts/build_stealahero.luau
```
```bash
lune run tests/run_all_tests.luau
```
