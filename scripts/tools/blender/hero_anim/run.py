# scripts/tools/blender/hero_anim/run.py
# Runner of the hero animation pipeline (run from the repo root):
#
#   "C:/Program Files/Blender Foundation/Blender 4.5/blender.exe" --background --factory-startup \
#       --python scripts/tools/blender/hero_anim/run.py -- --heroes Vegeta,PeterParker [--no-preview] [--no-video]
#       [--no-verify] [--save-blend]
#
# For every hero (default: every heroes/<HeroId>.py whose name does not start with "_"):
#   1. imports heroes/<HeroId>.py and validates it against the clip contract (api.Hero) and the hero ids of
#      src/ReplicatedStorage/Directory/HeroCatalog.luau (a typo would only fail later, in the strict build)
#   2. builds the HeroRig armature + mannequin (rig.py) and checks the rest pose against assets/animations/r15_rig.json
#   3. builds one Blender action per clip (export.build_actions) and checks the pure-Python evaluator against Blender
#   4. exports src/ReplicatedStorage/Directory/HeroAnimations/<HeroId>.luau from the actions
#   5. dumps assets/animations/roundtrip/<HeroId>.json (Blender's posed mannequin at sample times)
#   6. renders assets/animations/preview/<HeroId>_sheet.png (+ <HeroId>.mp4 unless --no-video) and the combined
#      assets/animations/preview/_all_heroes.png
#   7. runs `lune run scripts/tools/verify_hero_anims.luau <HeroIds>`: rebuilds the posed parts in Lune from the
#      exported Transforms with the game's own HeroClipMath and compares them with step 5 (max error < 0.01 studs)
# --save-blend also writes assets/animations/blend/<HeroId>.blend (the rig + actions, for hand inspection).
# Exit code 1 when any hero fails or the runner itself crashes (Blender alone would exit 0 on an uncaught exception).

import importlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import traceback

sys.dont_write_bytecode = True  # keep __pycache__ out of the repo
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))  # scripts/tools/blender -> "import hero_anim"

import bpy  # noqa: E402

from hero_anim import api, export, preview, rig  # noqa: E402

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def _arg(name, default=None):
    if name in ARGV:
        i = ARGV.index(name)
        if i + 1 < len(ARGV):
            return ARGV[i + 1]
    return default


def _hero_ids():
    wanted = _arg("--heroes")
    if wanted:
        return [h.strip() for h in wanted.split(",") if h.strip()]
    heroes_dir = os.path.join(HERE, "heroes")
    return sorted(f[:-3] for f in os.listdir(heroes_dir) if f.endswith(".py") and not f.startswith("_"))


def _lune():
    candidates = [os.environ.get("LUNE"), shutil.which("lune"), os.path.join(os.path.expanduser("~"), ".rokit", "bin", "lune.exe"),
                  os.path.join(os.path.expanduser("~"), ".rokit", "bin", "lune")]
    for c in candidates:
        if c and os.path.isfile(c):
            return c
    return None


def _catalog_ids():
    """Hero ids of src/ReplicatedStorage/Directory/HeroCatalog.luau (None when it cannot be read)."""
    path = os.path.join(api.REPO_ROOT, "src", "ReplicatedStorage", "Directory", "HeroCatalog.luau")
    try:
        with open(path, "r", encoding="utf-8") as handle:
            ids = set(re.findall(r'\bId\s*=\s*"([A-Za-z0-9_]+)"', handle.read()))
    except OSError:
        return None
    return ids or None


def run_hero(hero_id, opts, tmp_dir):
    t0 = time.time()
    module = importlib.import_module("hero_anim.heroes." + hero_id)
    importlib.reload(module)
    hero = api.load_hero(module)
    if hero.id != hero_id:
        raise ValueError("heroes/%s.py declares HERO = %r" % (hero_id, hero.id))
    known = _catalog_ids()
    if known is not None and hero_id not in known:
        # the strict build (scripts/steps/post_hero_animations.luau) rejects a module without AssetModels.<HeroId>
        raise ValueError("%r is not a hero Id of Directory/HeroCatalog.luau (case matters, e.g. SpiderMan2099)" % hero_id)
    for w in hero.warnings:
        print("[hero_anim] %s WARNING: %s" % (hero_id, w))

    rig.clear_scene()
    rig._MATERIALS.clear()
    built = rig.build(hero)
    rest_err = rig.check_rest(built)
    if rest_err > 1e-3:
        raise RuntimeError("rest pose mismatch %.5f (Blender <-> Roblox mapping broken)" % rest_err)

    actions = export.build_actions(built, hero)
    py_err = export.python_check(built, hero, actions)
    if py_err > 0.01:
        raise RuntimeError("Blender and the runtime math disagree by %.4f studs" % py_err)
    source_path = "scripts/tools/blender/hero_anim/heroes/%s.py" % hero_id
    module_path, read_err, _ = export.export_module(built, hero, actions, source_path)
    dump_path = export.roundtrip_dump(built, hero, actions)
    print("[hero_anim] %s: %d clips (%s), rest %.5f, python-vs-blender %.5f studs, read-back %.6f -> %s" % (
        hero_id, len(hero.clips), ", ".join("%s %.2fs%s" % (c.name, c.length, " loop" if c.loop else "") for c in hero.ordered_clips()),
        rest_err, py_err, read_err, os.path.relpath(module_path, api.REPO_ROOT)))

    outputs = [module_path, dump_path]
    if opts["preview"]:
        preview.setup_look(bpy.context.scene, accent=_accent(hero))
        outputs.append(preview.render_sheet(built, hero, actions, export, tmp_dir))
        if opts["video"]:
            outputs.append(preview.render_video(built, hero, tmp_dir))
    if opts["save_blend"]:
        blend_dir = os.path.join(api.REPO_ROOT, "assets", "animations", "blend")
        os.makedirs(blend_dir, exist_ok=True)
        path = os.path.join(blend_dir, hero_id + ".blend")
        bpy.ops.wm.save_as_mainfile(filepath=path, copy=True)
        outputs.append(path)
    print("[hero_anim] %s done in %.1fs: %s" % (hero_id, time.time() - t0, ", ".join(os.path.relpath(p, api.REPO_ROOT) for p in outputs)))
    return hero


def _accent(hero):
    return getattr(hero, "accent", None) or hero.colors.get("UpperTorso", (90, 170, 255))


def main():
    opts = {
        "preview": "--no-preview" not in ARGV,
        "video": "--no-video" not in ARGV,
        "verify": "--no-verify" not in ARGV,
        "save_blend": "--save-blend" in ARGV,
    }
    ids = _hero_ids()
    if not ids:
        print("[hero_anim] no heroes to build")
        sys.exit(1)
    tmp_dir = tempfile.mkdtemp(prefix="hero_anim_")
    failed = []
    done = []
    for hero_id in ids:
        try:
            run_hero(hero_id, opts, tmp_dir)
            done.append(hero_id)
        except Exception:
            traceback.print_exc()
            print("[hero_anim] !! %s FAILED" % hero_id)
            failed.append(hero_id)
    if opts["preview"]:
        # shared by every hero (parallel runs may race on it): a failure here never fails the heroes themselves
        try:
            path = preview.combined_sheet()
            if path:
                print("[hero_anim] combined preview -> %s" % os.path.relpath(path, api.REPO_ROOT))
        except Exception:
            traceback.print_exc()
            print("[hero_anim] WARNING: preview/_all_heroes.png not rebuilt (re-run later); per-hero outputs are fine")
    shutil.rmtree(tmp_dir, ignore_errors=True)
    if opts["verify"] and done:
        lune = _lune()
        if lune is None:
            print("[hero_anim] lune not found: run `lune run scripts/tools/verify_hero_anims.luau %s` yourself" % " ".join(done))
        else:
            result = subprocess.run([lune, "run", "scripts/tools/verify_hero_anims.luau"] + done, cwd=api.REPO_ROOT)
            if result.returncode != 0:
                failed.append("verify")
    if failed:
        print("[hero_anim] FAILED: %s" % ", ".join(failed))
        sys.stdout.flush()
        os._exit(1)
    print("[hero_anim] OK: %s" % ", ".join(done))
    sys.stdout.flush()


# Blender exits 0 after an uncaught exception in a --python script: turn any crash of the runner into exit code 1.
try:
    main()
except SystemExit:
    raise
except BaseException:
    traceback.print_exc()
    print("[hero_anim] FAILED: runner crashed")
    sys.stdout.flush()
    os._exit(1)
