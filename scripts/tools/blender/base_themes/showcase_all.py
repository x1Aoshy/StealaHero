# scripts/tools/blender/base_themes/showcase_all.py
# The owner's line-up of every v3 base theme at once (API v3, 2026-09-24). Run from the repo root:
#
#   "C:/Program Files/Blender Foundation/Blender 4.5/blender.exe" --background --factory-startup \
#       --python scripts/tools/blender/base_themes/showcase_all.py -- [--themes Forest,Lake,...] [--width 3200]
#
# Builds the Std variant of every requested theme that loads and validates on the v3 API (themes/<key>.py, the same
# geometry run.py exports; the live Bevel + Weighted Normal stacks), puts the pens side by side in stage order on one
# seamless studio floor under the same 3-point light, and renders assets/models/bases/preview/_lineup.png with one
# 50 mm camera: the silhouettes compared at a glance (each one must be unique). Themes that do not load yet are
# listed and skipped. Nothing is exported: run.py stays the only writer of the FBX / JSON / .blend / Studio helper.
# 2026-09-25: no Neon / no lights (nothing glows in the line-up); the landmarks of Lake / Desert / Jungle stand behind
# their pens and the camera frames them too.

import importlib
import os
import sys
import time
import traceback

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import bpy  # noqa: E402,F401
from mathutils import Vector  # noqa: E402

import common as C  # noqa: E402
import pipeline as P  # noqa: E402

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SPACING = 2 * C.W + 18.0  # studs between two pen centres


def arg_value(name, default=None):
    if name in ARGV:
        i = ARGV.index(name)
        if i + 1 < len(ARGV):
            return ARGV[i + 1]
    return default


def main():
    t0 = time.time()
    keys = [k.strip() for k in (arg_value("--themes", ",".join(P.ORDER)) or "").split(",") if k.strip()]
    width = int(arg_value("--width", "3200"))
    P.clear_scene()
    placed, skipped = [], []
    for key in keys:
        try:
            mod = importlib.import_module("themes." + key.lower())
            importlib.reload(mod)
            theme = mod.THEME
            problems = [p for p in P.validate_theme(theme, check_layouts=False)]
            if problems:
                skipped.append("%s (%s)" % (key, problems[0]))
                continue
            builders, _ = P.build_theme(theme, None)
            placed.append((key, theme, builders["Std"]))
        except Exception as exc:  # noqa: BLE001  (a legacy theme module does not load on v3)
            skipped.append("%s (%s)" % (key, str(exc).splitlines()[0][:80] if str(exc) else type(exc).__name__))
    if not placed:
        print("[showcase_all] no v3 theme loads yet: %s" % "; ".join(skipped))
        return
    n = len(placed)
    for i, (key, theme, B) in enumerate(placed):
        ox = (i - (n - 1) / 2.0) * SPACING
        coll = bpy.data.collections.new("Lineup_" + key)
        bpy.context.scene.collection.children.link(coll)
        P.scene_objects(theme, B, coll, (ox, 0.0, 0.0))
        for obj in P.preview_props(theme, B.D, coll, figures=False):
            obj.location.x += ox
        P.add_theme_lights(B, (ox, 0.0, 0.0), coll)
    cam = P.setup_studio(width, int(width * 9 / 32 / 2) * 2)
    half = (n - 1) / 2.0 * SPACING + C.W + 2
    back, top = -C.W - 2, 10.0
    for _, _, B in placed:
        lb = B.landmark_bounds()
        if lb:
            back, top = min(back, lb[0][1]), max(top, lb[1][2])
    P.fit_camera(cam, (-half, back, 0.0), (half, C.W + 3, top), (0.0, -1.0, -0.62), width, int(width * 9 / 32 / 2) * 2, 0.03)
    out = os.path.join(P.SHEET_DIR, "_lineup.png")
    os.makedirs(P.SHEET_DIR, exist_ok=True)
    P.render_to(out, width, int(width * 9 / 32 / 2) * 2)
    P.clear_scene()
    print("[showcase_all] %s -> %s (%.1fs)%s" % (", ".join(k for k, _, _ in placed), P.rel(out), time.time() - t0,
                                                 ("; skipped: " + "; ".join(skipped)) if skipped else ""))
    print("[showcase_all] OK")
    sys.stdout.flush()


try:
    main()
except SystemExit:
    raise
except BaseException:
    traceback.print_exc()
    print("[showcase_all] FAILED")
    sys.stdout.flush()
    os._exit(1)
