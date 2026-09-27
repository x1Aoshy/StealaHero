# scripts/tools/blender/base_themes/run.py
# Runner for the Blender base themes (the theme API v3: common.py; one module per theme: themes/<key>.py).
#
#   "C:/Program Files/Blender Foundation/Blender 4.5/blender.exe" --background --factory-startup \
#       --python scripts/tools/blender/base_themes/run.py -- --themes Forest,Lake [--no-render] [--sheet-only]
#   View (the lead): the same without --background, with --view: opens the Blender window with every requested theme
#   (both variants side by side, a player and heroes for scale); nothing is written.
#
# Per theme: validates it (families, anchors, its own perimeter), builds both variants, self-checks the pen contract
# (common.Builder.check, incl. the real plots' obstacles from base_themes/plot_obstacles.json), renders the Std variant
# (assets/models/bases/<Key>/preview/<NAME>_hero|gate|detail|top.png), writes <NAME>.blend (live modifier stacks),
# <NAME>.fbx (modifiers applied, both variants) and <NAME>.json, checks the evaluated triangle budget
# (TRI_MIN..TRI_MAX per variant), then refreshes assets/models/bases/preview/_coherence.png (every v3 theme's hero shot)
# and the Studio helper assets/models/bases/BaseThemesImport.lua. Run from the repo root. Exit code 1 when a theme
# fails (its files are still written, so you can look at them; the build loader skips a variant whose JSON lists
# "problems"; a clash with one real plot's obstacles goes to "plot_problems" and only keeps that plot procedural).
# --sheet-only: just recompose the coherence sheet and the helper from what is on disk.
# --dry-run: validate, build, self-check and count the evaluated triangles; write nothing (works for themes/_template.py
# too: --themes _template).
# 2026-09-25 (owner): no Neon and no lights in the bases (a theme's B.light() calls are ignored and reported), a
# landmark behind the pen for Lake / Desert / Jungle (camera guidance printed as "camera:" notes), the JSON's
# geometry_fingerprint (printed: "geometry unchanged" = the owner's Studio import stays valid).

import importlib
import os
import sys
import time
import traceback

sys.dont_write_bytecode = True  # no __pycache__ next to the theme modules
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import bpy  # noqa: E402,F401

import common as C  # noqa: E402
import pipeline as P  # noqa: E402

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def arg_value(name, default=None):
    if name in ARGV:
        i = ARGV.index(name)
        if i + 1 < len(ARGV):
            return ARGV[i + 1]
    return default


def load_theme(key):
    mod = importlib.import_module("themes." + key.lower())
    importlib.reload(mod)
    theme = getattr(mod, "THEME", None)
    if theme is None:
        raise RuntimeError("themes/%s.py defines no THEME" % key.lower())
    return theme


def report_notes(key, vname, theme, B):
    """The 2026-09-25 notes of a built variant: ignored B.light() calls, the landmark, camera guidance, a stretch."""
    if B.ignored_lights:
        print("[base_themes] %s %s: %d B.light() call(s) ignored (no lights in the bases since 2026-09-25)" % (
            key, vname, B.ignored_lights))
    lb = B.landmark_bounds()
    if lb:
        n = sum(1 for i in range(len(B.pieces)) if B.zone_of(i) == C.ZONE_LANDMARK)
        print("[base_themes] %s %s: landmark %d pieces, v %.2f..%.2f, %.2f..%.2f studs behind the back fence, h 0..%.2f" % (
            key, vname, n, lb[0][0], lb[1][0], -B.D - lb[1][1], -B.D - lb[0][1], lb[1][2]))
    for w in B.camera_warnings()[:12]:
        print("[base_themes] (guidance) %s %s: %s" % (key, vname, w))
    if theme.TRI_STRETCH:
        print("[base_themes] %s %s: tri budget stretched to %d: %s" % (key, vname, theme.tri_max(), theme.TRI_STRETCH_REASON))


def main():
    keys = [k.strip() for k in (arg_value("--themes", "Forest") or "").split(",") if k.strip()]
    render = "--no-render" not in ARGV
    if "--view" in ARGV:
        themes = []
        for key in keys:
            try:
                themes.append(load_theme(key))
            except Exception:
                traceback.print_exc()
        P.view(themes)
        print("[base_themes] view: %s (rows: themes, columns: Std / Deep)" % ", ".join(t.KEY for t in themes))
        return
    failed = []
    if "--dry-run" in ARGV:
        obstacles = P.load_obstacles()
        for key in keys:
            try:
                theme = load_theme(key)
                problems = P.validate_theme(theme, check_layouts=False)
                builders, variant_problems = P.build_theme(theme, obstacles)
                counts = P.dry_run(theme, builders)
            except Exception:
                traceback.print_exc()
                failed.append(key)
                continue
            for vname, _, _ in C.VARIANTS:
                total, tris = counts[vname]
                if total > theme.tri_max() or total < C.TRI_MIN:
                    variant_problems[vname].append("%d tris outside %d..%d" % (total, C.TRI_MIN, theme.tri_max()))
                print("[base_themes] dry-run %s %s: %d tris, %d pieces: %s" % (key, vname, total, len(builders[vname].pieces),
                      ", ".join("%s %d" % (r, n) for r, n in sorted(tris.items()))))
                report_notes(key, vname, theme, builders[vname])
                for p in variant_problems[vname][:40]:
                    print("[base_themes] !! %s %s: %s" % (key, vname, p))
            for p in problems:
                print("[base_themes] !! %s: %s" % (key, p))
            if problems or any(variant_problems.values()):
                failed.append(key)
        print("[base_themes] dry-run %s" % ("FAILED: " + ", ".join(failed) if failed else "OK"))
        sys.stdout.flush()
        sys.exit(1 if failed else 0)
    if "--sheet-only" not in ARGV:
        obstacles = P.load_obstacles()
        if obstacles is None:
            print("[base_themes] (no plot_obstacles.json: the per-plot obstacle check is skipped; make it with "
                  "lune run scripts/tools/test_base_imports.luau obstacles <build.rbxl>)")
        for key in keys:
            t0 = time.time()
            try:
                theme = load_theme(key)
                problems = P.validate_theme(theme)
                if problems:
                    for p in problems:
                        print("[base_themes] !! %s: %s" % (key, p))
                    failed.append(key)
                    continue
                P.clear_scene()
                builders, variant_problems = P.build_theme(theme, obstacles)
                renders = P.render_theme(theme, builders["Std"]) if render else []
                fbx, js, blend, layout, totals = P.export_theme(theme, builders, variant_problems, renders)
            except Exception:
                traceback.print_exc()
                failed.append(key)
                continue
            bad = False
            for vname, _, _ in C.VARIANTS:
                v = layout["variants"][vname]
                print("[base_themes] %s %s: %d tris (%d..%d), %d objects, %d pieces, %d lights: %s" % (
                    key, vname, v["total_tris"], C.TRI_MIN, theme.tri_max(), v["objects"], len(v["pieces"]), len(v["lights"]),
                    ", ".join("%s %d" % (r, n) for r, n in sorted(v["tris"].items()))))
                report_notes(key, vname, theme, builders[vname])
                probs = v["problems"] + v["plot_problems"]
                for p in probs[:40]:
                    print("[base_themes] !! %s %s: %s" % (key, vname, p))
                if len(probs) > 40:
                    print("[base_themes] !! ... %d more" % (len(probs) - 40))
                bad = bad or bool(probs)
            print("[base_themes] %s -> %s, %s, %s%s (%.1fs), geometry %s" % (
                key, P.rel(fbx), P.rel(js), P.rel(blend), (", %d renders" % len(renders)) if renders else "", time.time() - t0,
                layout.get("geometry_fingerprint")))
            if bad:
                failed.append(key)
    if render or "--sheet-only" in ARGV:
        found = P.coherence_sheet()
        print("[base_themes] coherence sheet (%s) -> %s" % (", ".join(found) or "no v3 theme yet",
                                                          P.rel(os.path.join(P.SHEET_DIR, "_coherence.png"))))
    helper, helper_keys = P.write_studio_helper()
    print("[base_themes] Studio helper %s: %s" % (P.rel(helper), ", ".join(helper_keys) or "no themes"))
    if failed:
        print("[base_themes] FAILED: %s" % ", ".join(failed))
        sys.stdout.flush()
        sys.exit(1)
    print("[base_themes] OK")


main()
