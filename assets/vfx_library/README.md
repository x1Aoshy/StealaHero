# VFX Library

`VfxLibrary.rbxl` is a standalone place holding every model, part and effect set with visual effects
(ParticleEmitter, Beam, Trail, Fire, Smoke, Sparkles) from:

| Hall | Sources |
|---|---|
| Steal a Hero | `StealaHero.rbxl`, `assets/hero_models/*.rbxm`, `Treadmills.rbxl`, `assets/models/bases/*` |
| Steal an Egg (base) | `Steal An Egg with treadmill V2.rbxl` (only what Steal a Hero no longer has) |
| Speedsters | `World1/2/3` places, `AURAS/`, `src/assets`, `src/ui`, `design/` kits, the root kits (sibling `../Speedsters` checkout) |
| V40 (Steal a Brainrot) | `reference/V40 SAB by FaypleStudios.rbxl`, plus the V40 ports/captures found in the games (`FoundIn`) |

Each asset is kept once: byte-identical copies (compared at the origin, so the same prop placed 14 times on a map
counts once) are listed in the item's `AlsoIn` attribute. `VfxLibrary_manifest.json` lists every item with its
source file and path.

## Using it in Studio
- `Workspace.VfxLibrary.<Hall>.<Category>.<Item>`: select an item in the Explorer and press F to fly to it;
  right-click > Save to File... (.rbxm) or Save to Roblox to take it.
- Item attributes: `SourceFile`, `SourcePath` (where it lives in its game), `AlsoIn`, `FoundIn`, `OriginalName`.
- `ScriptsDisabled` (server Scripts turned off for the showcase) and `ScaledPreview` (weather / map volumes up to
  2000 studs, shrunk to fit a pedestal; `RealSize` gives the original size): the untouched copy, with the same
  name and folders, is in `ServerStorage.VfxLibraryOriginals`.
- A loose effect (lone Attachment / emitter / Beam / Trail, or a Folder of them) is a Model holding the untouched
  effect plus a `_Preview` part with a copy that renders.
- Press Play to see burst effects: `ServerScriptService.VfxLibraryPreviewer` anchors the showcase, mutes it and
  replays the emitters their games fire by code (`EmitCount` / `EmitDelay` attributes) every 3 s.

## Rebuilding
```
lune run scripts/tools/build_vfx_library.luau [--v40=<V40 place>] [--speedsters=<dir>] [--out=<rbxl>]
```
Env: `SAB_V40_PLACE`, `SPEEDSTERS_DIR`, `VFX_LIBRARY_OUT`. Without the full V40 place it falls back to
`vendor/sab_vfx.rbxl` (10 effects only).
