# Owner hero models + rain pass — contract (owner request 2026-09-23, binding)

Single pass, no review loops. Pipeline rules + Lune gotchas as in docs/VISUAL_PASS_PLAN.md (Content props via
roblox.Content, FontFace not Font, per-corner UICorner radii, whole-subtree Clone, WorldPivotData, no PivotTo/WaitForChild,
Instance.new(class, parent) ignores parent, read BasePart position via CFrame.Position). NEW rule: every TextLabel with
TextScaled = true must also have TextWrapped = true (Roblox renders TextScaled + TextWrapped=false at the tiny TextSize).
Build ONLY to your own scratch output: STEALAHERO_LENIENT=1 STEALAHERO_OUT=<your scratch>/build.rbxl. NEVER write the
repo's StealaHero.rbxl (LEAD builds it). Test with STEALAHERO_PLACE=<your build> lune run tests/run_all_tests.luau.

## Source of the models
The owner placed the models in Studio and saved them into StealaHero.rbxl. That snapshot is preserved read-only at
`assets/user_models/StealaHero_user_models_0747.rbxl` (Workspace root, Workspace.Downloaded_Heroes_R15,
Workspace.Model, Workspace["Replacement  Guards"] — note the TWO spaces). The build must not read models from the
generated StealaHero.rbxl (it is overwritten by every build): HEROES extracts them once into
`assets/hero_models/*.rbxm` with a re-runnable tool script and the build reads those files.

## Mapping (model in the snapshot -> id). Paths are Workspace-relative; "?" = verify, see below.
| Stage (key) | id | model |
|---|---|---|
| The Avengers (Forest) | Hawkeye | Model > ... > "Hawkeye" (R6) |
| | BlackWidow | ? "StarterCharacter" (R15, WavyPopularGirlGingerHair, near Thor) — alt "Jean Grey (X-Men)" (R6, ginger hair) |
| | CaptainAmerica | "Captain America." (R15) |
| | Hulk | "Hulk" (R15) |
| | Thor | "Thor" (R15) |
| | IronMan | ? unnamed "" (R15 at ~(111,5,-21), shirt+pants, no accessories) |
| Justice League (Lake) | Aquaman | "Aquaman" (R6) |
| | GreenLantern | "Green Lantern" (R15) |
| | Flash | Downloaded_Heroes_R15 > "Flash" (R15) |
| | WonderWoman | "Wonder Woman. " (R15) |
| | Batman | Downloaded_Heroes_R15 > "Batman" (R15) |
| | Superman | Downloaded_Heroes_R15 > "Superman.     " (R15) |
| Spider-Verse (Desert) | PeterParker | "Spiderman" (R6) |
| | SpiderGwen | "Gwen" (R6) |
| | MilesMorales | "MilesMoralesK" (R6) |
| | SpiderMan2099 | "Spiderman 2099" (R6) |
| | AgentVenom | "Venom" (R6, CharacterMesh monster package) — owner: "two venoms: agent venom and ultimate venom" |
| | Venom | "Ultimate Venom" (R6) |
| My Hero Academia (Jungle) | Uraraka / Bakugo / Hawks / Deku | same-name R6 models |
| | Todoroki | "Shoto Todoroki" (R15) |
| | AllMight | "All Might" (R6, 22 parts) |
| Dragon Ball (Snow) | Krillin / Trunks / Gohan / Goku | same-name R6 models |
| | Piccolo | the R6 rig with the GREEN head inside Workspace.Model (~(560,4,-86)) |
| | Vegeta | ? unnamed " " R15 at ~(526,8,-85) OR unnamed " " R6 at ~(594,44,-85) |
| One Piece (Volcano) | Usopp / Brook / Sanji / Zoro / Shanks | same-name models |
| | Nami | "Nami Onigashima" (R6) |
| | Luffy | "--" (R15, StrawHat + Luffy Hair accessories) |
| | JoyBoy | "Luffy - Gear 5" (R15) — owner: "el luffy es gear5 el joyboy" |
| Villains (guards) | Thanos | Replacement  Guards > "THANOS" (R6) |
| | Darkseid | Replacement  Guards > "Darkseid" (R15) |
| | Carnage | Replacement  Guards > "Venom" > "Zombie" (R15) |
| | Shigaraki | Replacement  Guards > "Shoto" (R6, "Shigaraki" accessories) |
| | Frieza | Replacement  Guards > "Freeza" (R15) |
| | Kaido | Replacement  Guards > "Kaidos" > "Kaido" (R15) |

"?" rows: decide from clothing / accessory evidence (Shirt/Pants template ids, accessory names, colours). You may look
up public asset names (e.g. https://economy.roblox.com/v2/assets/<id>/details) with WebFetch; never log in or send
credentials. If still unsure, keep the table's first choice and report it.
Extras NOT in the roster this pass (the owner will confirm their category/rarity): Nico Robin, Franky, Chopper,
Jean Grey (if unused), LJTheSecond, the unused unnamed rig, SilverSurfer, and the Flash family (ReverseFlash, KidFlash,
BlackFlash, WallyWest, MobiusWallyWest, WhiteSpeedster, Savitar, Zoom). Extract them too (assets/hero_models/Extras) so
they can be added later. The Sonic family (Sonic, SuperSonic, SuperSaiyanSonic, DarkZonic, Shadow) is excluded entirely.

## Decisions
H1 The 38 roster heroes and 6 villains use the owner's models, converted to R15 where they are R6. The procedural /
   "authentic" looks generated before (hero_system_builder look tables, r15_rig_factory suits, Update2 SkinRig / World2
   Sonic heads, procedural villain parts) are removed. The structure stays: same ids, same instance names and places
   (ReplicatedStorage.AssetModels.<id> in-game models, Assets.Models.Heroes.<id>, Directory.Assets._Index configs,
   Assets.Models.Eggs.<id>, HeroCatalog, drop tables, zone guards), same attributes (HeroId, VillainName, RigScale...),
   rarity / income / stage data unchanged (docs/STAGES_PLAN.md §2).
H2 R6 -> R15 conversion: a real R15 rig (15 body parts as MeshParts with the standard Roblox R15 body meshes so classic
   Shirt / Pants / ShirtGraphic render, standard Motor6D + RigAttachment names, Humanoid.RigType R15, sensible
   HipHeight), body colours from BodyColors / the R6 limbs, the R6 Head part kept (SpecialMesh + face Decal +
   attachments, plus NeckRigAttachment), accessories re-welded to the matching R15 attachment, extra welded R6 parts
   re-welded to the nearest R15 part keeping their world offset. CharacterMesh packages cannot carry over (report).
   The default Roblox R15 walk / idle animations must drive every hero and villain (standard joint names; whatever
   animates heroes / guards in the game today must work with the new rigs — find it and verify it).
H3 Index face renders: the Index shows a live headshot of every hero (ViewportFrame with the hero model, camera on the
   face) instead of the old icon; also used anywhere a hero card shows its icon in windows you own (Sell Heroes cards).
   (No image upload is possible, so portraits are live ViewportFrame renders.)
H4 Eggs painted with each hero's own colours (a curated 2-3 colour palette per hero: base + accent + spots / bands),
   in a post step after the builder, on Assets.Models.Eggs.<id> (and any other egg model the game renders per hero).
H5 Rain: Justice League (Lake) gets a proper rain modelled on the owner's ZeroDown weather system
   (C:\Users\Aoshy´\Desktop\ZeroDown — read only; also C:\Users\Aoshy´\Desktop\RobloxBall if relevant): client-side,
   follows the camera, only while the player is inside the Lake stage, streaks + ground splashes, darker lighting /
   atmosphere blend, performant. Audio stays on the whitelist (no new sound ids unless a public Roblox-library id is
   justified and added deliberately — prefer no sound).

## Ownership (exclusive)
| Agent | Owns |
|---|---|
| HEROES | scripts/hero_system_builder.luau, scripts/r15_rig_factory.luau (may become the converter), NEW scripts/tools/extract_hero_models.luau, NEW assets/hero_models/*, any NEW scripts/lib/rig_convert.luau, scripts/steps/post_purge.luau (only if the purge must adapt), tests/suite_heroes.luau + tests/plan_data.luau |
| PORTRAITS | src/StarterPlayer/StarterPlayerScripts/GUI/Index/init.client.luau, NEW src/ReplicatedStorage/Library/Client/HeroPortrait.luau (+ manifest scripts/inject/portraits.luau), src/StarterPlayer/StarterPlayerScripts/GUI/SellHeroes.client.luau, tests/suite_ui.luau |
| EGGS | NEW scripts/steps/post_egg_colors.luau, NEW scripts/data/hero_palettes.luau, tests/suite_eggs.luau |
| RAIN | the Lake rain in scripts/steps/env_a.luau (addRain and its call only), src/StarterPlayer/StarterPlayerScripts/Game/StageAmbience.client.luau, NEW src/StarterPlayer/StarterPlayerScripts/Game/StageWeather.client.luau (+ scripts/inject/weather.luau), tests/suite_audio_vfx.luau |
| LEAD | scripts/build_stealahero.luau, tests/run_all_tests.luau, final build |
