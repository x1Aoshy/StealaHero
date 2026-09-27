# Steal a Hero — project guide for Claude sessions

Roblox game "Steal a Hero" (stages of superhero eggs, a treadmill/speed economy, villains that chase egg carriers).
The playable place `StealaHero.rbxl` is **compiled offline** with Lune from the base place plus this repo; it is a build
artifact the owner opens in Roblox Studio.

## Owner and working style
- The owner writes specs in English but chats in **Spanish**: reply in Spanish, keep code, comments and docs in English.
- Do not ask design questions: decide and deliver (faithful to the spec, creative, low-poly Roblox toy style that looks
  "brutal"). Only ask when truly blocked (e.g. which repo, a credential, an upload).
- Loop per change: quick smoke, then compile. Full suites only for big structural passes or to diagnose.
- Sessions can drop (usage limits): keep work resumable (notes files, small commits).
- Other assistants (Gemini/Antigravity, GPT "Astra", other Claude sessions) sometimes edit this repo. Before building
  or cleaning up, check what changed and who did it; never revert someone else's approved work (Astra's Stark Lab base
  is owner-approved).

## Setup
- Lune 0.10.5 (`rokit.toml`): `rokit install` (or install lune 0.10.5 manually).
- Blender 4.5 is only needed for the base/animation authoring tools under `scripts/tools/blender/`.
- The owner's `Update2` sources the build uses are snapshotted in `vendor/Update2/` (World1Update3New.rbxl + 3 UI
  modules); `vendor/sab_vfx.rbxl` holds only the effect subtrees `scripts/steps/vfx.luau` ports (built by
  `scripts/tools/vendor_sab_vfx.luau`). The owner's local `c:/Users/Aoshy´/Desktop/Update2` is the fallback.

## Build and test
```
lune run scripts/build_stealahero.luau                    # writes StealaHero.rbxl
STEALAHERO_OUT=/tmp/x.rbxl lune run scripts/build_stealahero.luau   # scratch output (use this while iterating)
STEALAHERO_PLACE=/tmp/x.rbxl lune run tests/run_all_tests.luau smoke   # quick smoke (smoke.luau + tests/smoke_*.luau)
STEALAHERO_PLACE=/tmp/x.rbxl lune run tests/run_all_tests.luau         # full suites
```
Env: `STEALAHERO_LENIENT=1` (a failing step is logged, not fatal), `STEALAHERO_UPDATE2`, `STEALAHERO_SAB_PLACE`,
`STEALAHERO_BASE_IMPORTS` (synthetic base imports for tests).
Before overwriting `StealaHero.rbxl`: if the owner saved it from Studio after the last build (mtime/size), back it up
to `assets/user_models/` and extract any `ServerStorage.BaseThemeImports` with
`lune run scripts/tools/extract_base_imports.luau StealaHero.rbxl` (the build also does this on its output file).

## Layout
- `Steal An Egg with treadmill V2.rbxl` — base place (its server scripts are empty stubs: all server features live in
  `src/ServerScriptService`).
- `src/` — Rojo-style mirrors of every script; `scripts/build_stealahero.luau` + `scripts/steps/*.luau` (ordered: env /
  plots / treadmill / stages, heroes, `post_*` in name order, `ui_*` in name order, `ui_99_textwrap` last);
  `scripts/inject/*.luau` manifests `{ target, class, source, create }` copy src files into the place. To patch a
  base-place script that is not injected yet: check its src mirror equals the base Source, edit it, add an entry.
- `tests/` — `plan_data.luau` (stages/heroes roster), `smoke.luau`, `smoke_<feature>.luau`, `suite_*.luau`.
- `assets/hero_models/*.rbxm` — the owner's hero/villain models (extracted by `scripts/tools/extract_hero_models.luau`
  from `assets/user_models/StealaHero_user_models_0747.rbxl`), converted to R15 by `scripts/lib/rig_convert.luau`.
- `assets/models/bases/<Stage>/` — the 6 stage bases (see below). `assets/animations/` — hero animation rig/previews.
  `assets/eggs/` — hero egg models/textures. `docs/` — plans. `design/`, `audit/` — references and one-off tools.
- `assets/vfx_library/VfxLibrary.rbxl` — standalone place with every VFX model of Steal a Hero, Steal an Egg,
  Speedsters (sibling `../Speedsters`) and V40 (`reference/`), built by `scripts/tools/build_vfx_library.luau`.

## Pipelines
- **Stage bases** (Stark Lab, Hall of Justice, Brooklyn Rooftop, U.A. Hero Arena, Capsule Corp Arena, Sunny Pirate
  Wharf): `scripts/tools/blender/base_themes/` (common.py API at its top, run.py, themes/<key>.py) -> `<Name>.fbx`
  (Std 52.5x52.5 + Deep 52.5x63 variants) + `<Name>.json` (layout, palette, geometry fingerprint) + renders. The owner
  imports the FBX in Studio (Import 3D), runs `assets/models/bases/BaseThemesImport.lua` in the command bar, saves;
  the extracted `<Name>.rbxm` files are placed on every plot by `scripts/steps/post_zz_base_themes.luau` (zero-margin
  clearance checks, stale-import guard by geometry fingerprint). A geometry change needs a re-import; a palette-only
  change does not. NO Neon and no lights in any base (build guard). Spider-Verse window panes flicker at runtime
  (`BaseWindowLights`). Claude cannot upload meshes: only the owner's Studio import creates the mesh assets.
- **Owner Studio saves**: when the owner edits a compiled place in Studio and sends it back, keep it in
  `assets/user_models/`, diff it against the build (`lune run scripts/tools/diff_places.luau <build.rbxl> <save.rbxl>`)
  and replay the real edits in `scripts/steps/post_zzz_owner_layout.luau` (`OWNER_SAVE`, rigid `MOVES` read from the
  save, `DELETES`, baseplate tiles). Moved groups carry `OwnerLayout`, and the old layout tests give way to them.
- **Villain animations**: `scripts/tools/villain_anim/gen_villain_clips.py` (Euler poses, python3, no Blender) generates
  `src/ReplicatedStorage/Directory/VillainAnimations/<Villain>.luau`. Never edit those by hand. They are published by
  `post_villain_animations` and played by `Game/VillainClipPlayer` (Idle / Wake / Move / Walk / Attack on
  Motor6D.Transform). GuardChaseService loads no Animator track for a villain that has clips (`ClientClips`).
- **Branch framework**: Branch 2.0.0 is vendored in `vendor/Branch` (MIT) and installed at
  `ReplicatedStorage.Packages.Branch`. New systems go in as segments:
  - `ServerScriptService.BranchServices` (`*Service`, started by `BranchServer`);
  - `StarterPlayerScripts.BranchControllers` (`*Controller`, started by `BranchClient`): UiLife, Perf, UiScale,
    EggHealth, MenuMotion.

  Branch.Data is not used (the player saves stay on `Library.Database`). Branch.Network is not used either: it needs
  the Branch Studio plugin's codegen.
- **Scenery**: `post_zzzzz_scenery` builds `Workspace.Scenery` (woods, treeline, rocks, pebbles), deterministically,
  against the built world's occupancy.
- **Hero weapons** (the bats, owner 2026-09-27): the melee Tools keep their names (Bat = Cap's shield, Forest = Power
  Pole, Desert = web shooter, Lake = batarang, Jungle = Bakugo's gauntlet, Snow / Cosmic = Mjolnir, Volcano = Gum-Gum
  fist; `Library.Modules.HeroWeapons.BY_TOOL`, Prehistoric / Abyss Ocean stay classic bats). The owner's files are in
  `assets/hero_weapons/` (7 R15 attack KeyframeSequences `.rbxmx` - animations only, no meshes -, baked samples, their
  `HeroWeaponTools.luau` kit, now `Library.Modules.HeroWeaponTools`). `scripts/tools/hero_weapons/gen_weapon_clips.py`
  -> `src/ReplicatedStorage/Directory/WeaponAnimations/<WeaponId>.luau` (never edit by hand; Impact keyframe = hit
  time); `weapon_models.py [--render]` authors the part models in grip space -> `assets/hero_weapons/weapon_models.json`
  (+ previews posed on the clips); `post_hero_weapons` builds the Tools like `Kit.Prepare`. GearService resolves the
  hit at Impact by the weapon's Kind and applies a 2.5 s state (`HeroDebuff` attribute) instead of the ragdoll;
  `BranchControllers.HeroWeaponController` plays the clips, projectiles and states; `Library.Client.WeaponPortrait`
  draws the weapon in the hotbar / Index.
  **The owner's real models** are FBX (`assets/hero_weapons/fbx/weapons` 8, `fbx/vfx` 7 effect meshes; `fbx/anim` are
  the same clips on a dummy, not needed). Claude cannot upload meshes, so the owner imports them in Studio: Import 3D
  the 15 files into the latest build, paste `assets/hero_weapons/HeroWeaponsImport.lua` in the command bar (generated
  by `gen_import_helper.py` with `fbx_manifest.json`: it fixes scale / pivot against the FBX, runs the owner's
  `Kit.Prepare`, files everything in `ServerStorage.HeroWeaponImports`), saves and sends the place. The build extracts
  it to `assets/hero_weapons/imports/{weapons,vfx}/*.rbxm` (`scripts/lib/hero_weapon_imports.luau`, also
  `lune run scripts/tools/extract_hero_weapon_imports.luau <save.rbxl | .rbxm>`); an imported weapon replaces its part
  stand-in (`Handle = RightHand * GripFromHand`), the effects go to `ReplicatedStorage.HeroWeaponVfx` and the
  controller uses them (cocoon, star ring, bolts, comic explosion, bat smoke, web blob / net). Test the path without
  Studio with `STEALAHERO_WEAPON_IMPORTS=synthetic` (block stand-ins at the FBX bounds). Previews:
  `render_fbx_weapons.py` (the owner's meshes held with their kit's grip on their clips).
  **Round 9 (owner 2026-09-27)**:
  - Mjolnir, the Power Pole, Cap's shield, the batarang and the web shooter play clips authored in
    `scripts/tools/hero_weapons/author_weapon_clips.py` (Euler poses; `--render` writes filmstrips
    `assets/hero_weapons/previews/clip_<Id>.png` with the owner's FBX at the build's grip). `gen_weapon_clips.py` now only
    converts Bakugo's and Luffy's rbxmx. Extra clip fields: `FullBody` (legs play while running), `Extend` (the pole's
    length keys), `Release`.
  - `assets/hero_weapons/grip_adjust.json` shifts / twists a model in the hand (Mjolnir: held above the pommel, head
    along the forearm).
  - The shield, batarang and web are AIMED (`Kind` Boomerang / Grenade / Shot): the client sends its aim point on
    `Network["Gear: WeaponAim"]`, the server clamps it (`HeroWeapons.AimEnd`) and flies the projectile itself
    (`HeroWeapons.PathPoint`, shared with the clients: `Launch` / `ProjectileEnd` broadcasts).
  - Weapons carry no mesh VFX (the pole's energy arc is dropped); VFX are particles: `vendor/weapon_vfx.rbxm`
    (`scripts/tools/vendor_weapon_vfx.luau`: Speedsters' Eggman missile blast, the Ban Hammer lightning / impact) ->
    `ReplicatedStorage.Assets.VFX.HeroWeapons`, plus the place's LightningHit and Mutation_FX.Shocked.
  - Training dummies (CollectionService tag `HeroWeaponDummy`, spawned by the admin panel) are hit like players.
    GearService's dummy keeper (`watchDummy` / `settleDummy`) turns their trip states off and stands them back up at
    their spawn spot 0.8 s after each state ends.
  **Round 10 (owner 2026-09-27)**:
  - Luffy's fist plays the authored `Gomu_Pistol_Long` clip: a straight-ahead punch with `Stretch` keys up to x7.5.
    `Kit.SetStretch` scales the rubber arm, and the fist rides its end by `StretchLength` (1.55, set by post_hero_weapons).
  - Hitboxes match what the weapon draws. Thrusts are a line of `Range` x `Width` starting `LineOffset` to the right
    of the root, at the right hand (GomuFist 15.5 x 2.3, offset 1.35); Bakugo reaches 10.5; the Power Pole sweep 13.5.
  - Cap's shield: `grip_adjust.json` `BackfaceCopies` lists palettes whose single-sided meshes get a copy turned 180°
    (`HeroBackface`), because DoubleSided alone still drew only the rim from behind.
- **Admin panel** (owner 2026-09-27):
  - `HeroAdminAccess` holds the access rule: anyone in Studio, UserId 767108248, the game's owner (user, or rank 255 of
    the owning group). The old Cmdr / AdminStatusHandler whitelists are separate systems and are left alone.
  - `BranchServices.HeroAdminService` answers `Network["Admin: Command"]`: it re-checks access on every call, rate-limits,
    validates, logs `[HeroAdmin]`, sets the `HeroAdmin` player attribute and clones `ServerStorage.HeroAdminPanel` into
    an admin's PlayerGui.
  - `scripts/steps/ui_85_admin_panel.luau` builds the panel with ui_kit; its LocalScript is
    `src/ServerStorage/HeroAdminPanel/HeroAdminClient.client.luau`.
  - The TopbarPlus `HeroAdminIcon` (a part-built 3D crown in a ViewportFrame) sits next to Backpack / Settings; F4
    also toggles it.
  - Tabs: weapons (give all / one / remove, unlock the Index weapons), training dummies, economy, eggs, world
    (teleports, base themes, night / day), player, server stats.
- **Treadmills** (`scripts/steps/treadmill.luau`, round 10): the skins used to sit ~1.2 studs sunk. Now each model
  keeps its full size and is lifted as far as its hull allows without clashing with plot furniture (lowest point
  `GROUND_CLEARANCE` above the floor). The Tool carries `BeltLift` (belt top above the floor).
  - An invisible `BeltDeck` under the belt plus a `BeltRamp` wedge behind it (`TreadmillDeck`, CanCollide, no query /
    touch) carry the runner; both renderers keep only those solid.
  - A pre-pass nudges the PlotUpgrade / TreadmillUpgrade sign models away from the plate (0.25 steps, at most 2 studs)
    when the lifted hull would hit them.
- **Hero animations**: `scripts/tools/blender/hero_anim/` (R15 rig from `assets/animations/r15_rig.json`, one module per
  hero in `heroes/`, run.py) -> generated `src/ReplicatedStorage/Directory/HeroAnimations/<HeroId>.luau` (never edit by
  hand) -> played by `Game/Plots/ActiveAssetsController/HeroClipPlayer.luau` (Motor6D transforms, no uploaded
  animation ids). Verify with `scripts/tools/verify_hero_anims.luau` and `scripts/tools/sim_hero_clips.luau`.

## Hard rules
- No asset uploads by Claude, never invent asset ids (reuse ids already in the place/assets). Never use the Speedster
  Escape logo 92044769924002.
- Audio whitelist only: 77120543307812, 72264591133889, 127039883737564, 136993031050456, 80736831159506.
- UI: every window/popup uses the Free Gift / Sell All studded glossy style (`scripts/lib/ui_kit.luau`).
- Economy: money was scaled down x125 on 2026-09-25 (Black Widow ~4 $/s max); publishing it needs a full server
  shutdown. Server-authoritative gameplay; validate remotes; keep identifiers other code looks up.
- Lune 0.10.5 gotchas: Content props via `roblox.Content.fromUri/fromAssetId/none`; write `FontFace =
  roblox.Font.fromEnum(...)` (`.Font` is lost); UICorner: set the 4 per-corner radii; clone whole subtrees only (per-child
  clones break Motor6D/Weld refs; moving one instance across deserialized DOMs drops its refs); no
  PivotTo/GetPivot/ScaleTo/WaitForChild (write `WorldPivotData`); `CFrame.lookAt` is Z-mirrored (use
  `CFrame.fromMatrix`/`Angles`); `Instance.new(class, parent)` ignores parent; a Lune WeldConstraint needs
  `CFrame0 = Part0.CFrame:ToObjectSpace(Part1.CFrame)`. Roblox: `TextScaled` needs `TextWrapped`; a second Humanoid
  nested in a character breaks it.

## Open items (2026-09-26)
- Pen animation feedback from teammate "Sung" was never shared: ask for it before re-tuning.
- Sanji's Move still slides a little; the Eggs Hatched leaderboard is partly hidden from the spawn (move 3-5 studs).
- Test in Studio Play: the 6 imported bases (dev unlock: server command bar
  `for _, p in game.Players:GetPlayers() do p:SetAttribute("DevUnlockBaseThemes", true) end`), bat equip from the
  Index, the 4 leaderboards, the new economy, egg pass-through.
- (2026-09-27) Test in Studio Play:
  - each villain's clips (dozing idle, wake, chase run, Frieza's glide, attack) and a villain carrying an egg home;
  - the per-hero auras (Goku white ki, Gohan SSJ, Superman red stars, Zoro green, Iron Man blue, Hawks none);
  - the particle ground rings and the fixed flipbooks;
  - the night wall closing the whole lane;
  - the scenery;
  - the UI life animations;
  - NetGuardService limits (it must never kick a real player: read its warn lines);
  - the `ServerHz` / `ServerFrameMs` / `ServerMemoryMB` workspace attributes;
  - lag compensation (`LagCompensationService`): villain catches and bat hits with simulated latency
    (Studio > Network > Incoming Replication Lag);
  - the device sizing (`UiScaleController`, `PlayerGui.UiDeviceProfile`) in the phone, tablet and console emulators,
    and the round egg-grab prompts.

  The owner may send a moon icon of their own: until then every moon / sun image shows the pixel-art icons
  (`HUD.PIXEL_MOON` / `HUD.PIXEL_SUN` in ui_30_hud; the SpPixelIcon layers are driven by `GUI/PixelNightIcon`).
- (2026-09-27, 4th pass) The owner saw EMPTY stages in a live server: the server spawned every egg
  ("Initial population done: 38/38") but the egg client (`Game/AreaEggs`) never drew one and logged nothing. The root
  cause was not found statically. The client now names the step it waits on after 10 s (`[AreaEggs] start-up still
  waiting at: ...`), loads the presentation-only modules in the background, reconciles drawn eggs every 4 s, and
  `BranchControllers.EggHealthController` logs `[EggHealth] ...` when the stages show no eggs. If the eggs are still
  missing, ask for those two log lines: they name the culprit.
- (2026-09-27, 4th pass) Test in Studio Play:
  - Zoro's `Aura_Blades`;
  - the egg / hero list pop-in and the HUD sliding away under menus (`MenuMotionController`);
  - the treadmill model viewports in the speed shop;
  - the "+" on the shoe's corner;
  - the pixel moons in the night countdown, on the egg tab and over growing eggs.
- (2026-09-27, 5th pass) The floating "+$" money amounts are the `ShowMoneyPopups` setting (Settings row "Money
  Popups", off by default; `GUI/MoneyUpdate` injected by `scripts/inject/hud_polish.luau`). The currency rows have no
  band (`RIBBON.band = false`). The Shop / Index icons are 0.95 of the pill height (`GLOSSY_GEOMETRY.iconSize`).
  HUD groups hidden under a menu travel `AWAY_SCALE` = 1.25 screens (their content spills outside their boxes).
- (2026-09-27, 6th pass) Hero weapons replaced the bats (see Pipelines). The owner's mapping puts the Power Pole on the
  Forest (Avengers) stage and Mjolnir on Snow (Dragon Ball) / Cosmic; swapping is one line in `HeroWeapons.BY_TOOL`.
  Traps: the placed trap's Hitbox used to stay at the template's lobby spot (anchored clone moved before parenting, the
  weld never dragged it) - fixed in `placeTrap`; a trap only catches OTHER players (test with 2 clients). The ragdoll
  only joints / collides real body parts (trail / aura parts made it stiff). Test in Studio Play (2+ clients):
  - each weapon's attack clip, the Power Pole extend and the Gum-Gum stretch;
  - the web line, the batarang and the shield throw;
  - the 7 states (web net, lightning, knockback slide, stars, smoke + grey screen, BOOM, spin);
  - the hotbar / Index weapon portraits;
  - the red target glow;
  - traps catching another player on a stage.
- (2026-09-27, 9th pass) Owner feedback on the weapons (see Pipelines > Hero weapons, Round 9):
  - the shield showed only its rim from behind (single-sided faces: every weapon MeshPart is DoubleSided now);
  - Mjolnir was held under its head: new grip + jump / ground-slam clip + a light attacker shake;
  - the batarang stayed in the hand: it flies out and explodes;
  - the Power Pole's yellow mesh is gone; it grows out of the hand and spins;
  - the Index weapon icons sat in the old rotated bat image: `WeaponPortrait.MountBadge` studded tiles.

  Test in Studio Play with 2+ clients (or a training dummy): aim with the mouse / a tap, the shield's curve and
  return, the batarang blast, Mjolnir's slam, the pole spin.
- (2026-09-27, 8th pass) The owner imported the 15 FBX models themselves and sent them as a raw `.rbxm`
  (`assets/user_models/HeroWeaponImports_owner_0927.rbxm`, extracted to `assets/hero_weapons/imports/`): every weapon
  now uses the owner's model (the kit's Prepare runs offline: grip from the import pivot = FBX origin, palette
  materials, energy palettes Neon with their colour) and the 7 effect models are in `ReplicatedStorage.HeroWeaponVfx`.
  **Owner rule: no VFX built from parts / meshes anywhere except their 7 effect models** - effects are particles
  (templates already in the place), Beams and Trails (the smoke test enforces it on HeroWeaponController).
- (2026-09-27, 7th pass) The owner sent the real weapon / effect FBX models (see Pipelines > Hero weapons;
  `HeroWeaponsImport.lua`). Ragdoll fix: the get-up loop called `bodyParts(character)`
  without the Humanoid, errored every frame and left the body frozen with PlatformStand on (and able to attack):
  fixed; a ragdoll now unequips the weapon, and GearService / the controller refuse attacks from a body that is down.
  Weapon victims no longer trip (FallingDown / Ragdoll states off during the state, stood back up after).
