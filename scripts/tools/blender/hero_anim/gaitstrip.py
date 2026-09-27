# scripts/tools/blender/hero_anim/gaitstrip.py
# Foot-planting check renders for the pen heroes' Move clips (ANIMPOLISH). Run from the repo root:
#
#   "C:/Program Files/Blender Foundation/Blender 4.5/blender.exe" --background --factory-startup \
#       --python scripts/tools/blender/hero_anim/gaitstrip.py -- --heroes CaptainAmerica,Hulk [--out <dir>] [--frames 8]
#       [--auto]   (--auto: foot-lock Move even if the module does not ask for speed="auto" yet)
#
# For every hero: builds the rig + actions exactly like run.py (so speed="auto" clips are foot-locked), then renders one
# Move cycle from a FIXED orthographic side camera while the rig travels forward at the clip's Speed (the rate the game
# plays it at when the hero walks that fast). Writes <out>/<HeroId>_gait.png: the frames side by side (top) and all of
# them overlaid (bottom, brightest pixel wins). A planted foot must stay on the same floor tile in consecutive frames
# and show as ONE crisp foot in the overlay; a smeared foot = sliding. Default out: assets/animations/preview/gait.
# Exports nothing (the modules are written by run.py only).

import importlib
import math
import os
import sys
import tempfile
import traceback

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

from hero_anim import api, export, preview, rig  # noqa: E402

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TILE = 360


def _arg(name, default=None):
    if name in ARGV:
        i = ARGV.index(name)
        if i + 1 < len(ARGV):
            return ARGV[i + 1]
    return default


def render_hero(hero_id, out_dir, frames, tmp_dir):
    import numpy as np
    module = importlib.import_module("hero_anim.heroes." + hero_id)
    if "--auto" in ARGV:  # try the foot lock on a module that does not ask for it yet
        clips = module.CLIPS() if callable(module.CLIPS) else module.CLIPS
        for c in clips:
            if c.name == "Move":
                c.speed = "auto"
        module.CLIPS = clips
    hero = api.load_hero(module)
    move = hero.clips["Move"]
    speed = move.speed if isinstance(move.speed, (int, float)) else 0.0
    rig.clear_scene()
    rig._MATERIALS.clear()
    built = rig.build(hero)
    actions = export.build_actions(built, hero)
    scene = bpy.context.scene
    preview.setup_look(scene, accent=(90, 170, 255))
    scene.render.resolution_x = scene.render.resolution_y = TILE
    scene.render.image_settings.file_format = "PNG"
    cam_data = bpy.data.cameras.new("GaitCam")
    cam_data.type = "ORTHO"
    travel = speed * move.length
    cam_data.ortho_scale = max(6.0, travel + 3.0)
    cam = bpy.data.objects.new("GaitCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    mid_y = -travel * 0.5
    cam.location = Vector((16.0, mid_y, 1.9))
    cam.rotation_euler = (Vector((0.0, mid_y, 1.9)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    # floor ruler behind the legs: a bright tick every stud (a planted foot must not move against it)
    tick_mat = rig.material((255, 230, 120), emissive=True)
    for k in range(-3, int(travel) + 4):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.4, -float(k), 0.05))
        tick = bpy.context.active_object
        tick.scale = (0.1, 0.04 if k % 5 else 0.08, 0.1 if k % 5 else 0.25)
        tick.data.materials.append(tick_mat)
    for name in ("Ring",):
        obj = bpy.data.objects.get(name)
        if obj:
            obj.hide_render = True
    tiles = []
    for i in range(frames):
        t = move.length * i / frames
        export.pose_at(built, actions["Move"], t)
        built.arm.location = (0.0, -speed * t, 0.0)
        path = os.path.join(tmp_dir, "%s_%02d.png" % (hero_id, i))
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        tiles.append(preview._load_pixels(path))
    built.arm.location = (0.0, 0.0, 0.0)
    strip = preview._grid([tiles], frames, TILE, TILE)
    overlay = np.max(np.stack(tiles), axis=0)
    big = np.zeros((TILE * 2, TILE * frames, 4), dtype=np.float32)
    big[:, :] = (0.02, 0.022, 0.04, 1.0)
    big[TILE:TILE * 2, :] = strip
    ox = (TILE * frames - TILE * 2) // 2
    big[0:TILE, ox:ox + TILE] = overlay
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, "%s_gait.png" % hero_id)
    preview._save_pixels(big, path)
    bpy.data.objects.remove(cam, do_unlink=True)
    info = hero.gait.get("Move")
    print("[gaitstrip] %s: Speed %s, %s -> %s" % (hero_id, move.speed, "locked, hips drop %.2f" % info["drop"] if info and info["valid"] else "not locked", path))


def main():
    wanted = _arg("--heroes")
    if not wanted:
        print("[gaitstrip] --heroes A,B required")
        sys.exit(1)
    out_dir = _arg("--out", os.path.join(api.REPO_ROOT, "assets", "animations", "preview", "gait"))
    frames = int(_arg("--frames", "8"))
    tmp_dir = tempfile.mkdtemp(prefix="gaitstrip_")
    failed = []
    for hero_id in [h.strip() for h in wanted.split(",") if h.strip()]:
        try:
            render_hero(hero_id, out_dir, frames, tmp_dir)
        except Exception:
            traceback.print_exc()
            failed.append(hero_id)
    if failed:
        print("[gaitstrip] FAILED: %s" % ", ".join(failed))
        sys.stdout.flush()
        os._exit(1)
    sys.stdout.flush()


try:
    main()
except SystemExit:
    raise
except BaseException:
    traceback.print_exc()
    sys.stdout.flush()
    os._exit(1)
