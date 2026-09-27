# scripts/tools/blender/hero_anim/showcase.py
# The owner's showcase of every hero clip at once (INTEGRATE, 2026-09-24). Run from the repo root:
#
#   "C:/Program Files/Blender Foundation/Blender 4.5/blender.exe" --background --factory-startup \
#       --python scripts/tools/blender/hero_anim/showcase.py -- [--no-video] [--size 1920] [--samples 16]
#
# Builds one mannequin per roster hero (tests/plan_data.luau PLAN.HEROES order, in its heroes/<HeroId>.py colours and
# preview extras) on six trophy shelves, one per stage (the stage's base-theme neon, the franchise plaque), labelled
# with the hero name + rarity, turned 3/4 to the camera. Writes into assets/animations/preview/:
#   showcase.png   two stacked panels: every hero in its Idle pose, then every hero mid-Move (the sheet thumb times)
#   showcase.mp4   ~16 s: Idle -> Move (in place) -> Idle -> Special (all at once) -> Idle, with the runtime's
#                  cross-fades (HeroClipPlayer: 0.25 s Idle <-> Move, Special 0.2 s in / 0.3 s out) and the effect
#                  stand-ins of preview.py (web strands shortened so they stay near their shelf)
# Nothing in the game reads these files; the clips come from the same heroes/<HeroId>.py modules as run.py's export.

import importlib
import math
import os
import re
import sys
import tempfile
import time
import traceback

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

from hero_anim import api, export, preview, rbx, rig  # noqa: E402

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []

FPS = 30
CELL_W = 7.0  # studs per hero column
PLAQUE_W = 7.5  # the stage plaque column on the left
COLS = 8
ROW_H = 9.6  # studs between two shelves
SHELF_T = 1.35  # shelf thickness (the name plates are on its front face)
SHELF_D = 5.6
YAW = math.radians(36)  # heroes turned 3/4 to the camera (facing screen-right)
PITCH = math.radians(7)
WEB_MAX = 5.5  # web strands are shortened to this length (studs) so they stay near their own shelf

STAGES = {
    1: ("THE AVENGERS", (70, 220, 255)),
    2: ("JUSTICE LEAGUE", (58, 123, 255)),
    3: ("SPIDER-VERSE", (255, 47, 180)),
    4: ("MY HERO\nACADEMIA", (47, 214, 122)),
    5: ("DRAGON BALL", (255, 170, 30)),
    6: ("ONE PIECE", (255, 74, 42)),
}
RARITY = {
    "Common": (175, 182, 196), "Rare": (70, 150, 255), "Epic": (180, 95, 255), "Legendary": (255, 200, 50),
    "Mythic": (255, 60, 80), "Secret": (60, 255, 225),
}


def _arg(name, default=None):
    if name in ARGV:
        i = ARGV.index(name)
        if i + 1 < len(ARGV):
            return ARGV[i + 1]
    return default


def roster():
    """[(HeroId, display name, stage, rarity)] from tests/plan_data.luau PLAN.HEROES."""
    path = os.path.join(api.REPO_ROOT, "tests", "plan_data.luau")
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    block = text[text.index("PLAN.HEROES = {"):]
    block = block[:block.index("\n}")]
    rows = re.findall(r'\{\s*"([A-Za-z0-9_]+)",\s*"([^"]+)",\s*(\d+),\s*"([A-Za-z]+)"\s*\}', block)
    return [(r[0], r[1], int(r[2]), r[3]) for r in rows]


# ------------------------------------------------------------------------------------------------ scene pieces


_FONTS = {}


def font(kind):
    if kind in _FONTS:
        return _FONTS[kind]
    candidates = {"title": ["C:/Windows/Fonts/impact.ttf", "C:/Windows/Fonts/arialbd.ttf"],
                  "name": ["C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/segoeuib.ttf"]}[kind]
    loaded = None
    for path in candidates:
        if os.path.isfile(path):
            try:
                loaded = bpy.data.fonts.load(path, check_existing=True)
                break
            except RuntimeError:
                pass
    _FONTS[kind] = loaded
    return loaded


def text(body, location, size, color, kind="name", align="CENTER", emission=True, parent=None, rotation=(math.pi / 2, 0, 0)):
    curve = bpy.data.curves.new("Txt", "FONT")
    curve.body = body
    curve.size = size
    curve.align_x = align
    curve.align_y = "CENTER"
    f = font(kind)
    if f is not None:
        curve.font = f
    obj = bpy.data.objects.new("Txt", curve)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(rig.material(color, emissive=emission))
    if parent is not None:
        obj.parent = parent
        obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.location = location
    obj.rotation_euler = rotation
    no_shadow(obj)
    return obj


def no_shadow(obj):
    for attr in ("visible_shadow",):
        if hasattr(obj, attr):
            setattr(obj, attr, False)


def box(name, center, size, color, emissive=False, bevel=0.06, shadow=False):
    obj = bpy.data.objects.new(name, rig._box_mesh(name, size, bevel=bevel))
    obj.data.materials.append(rig.material(color, emissive=emissive, roughness=0.35))
    bpy.context.scene.collection.objects.link(obj)
    obj.location = center
    if not shadow:
        no_shadow(obj)
    return obj


def ring(center, color):
    import bmesh
    mesh = bpy.data.meshes.new("Ring")
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=False, segments=40, radius=1.9)
    ret = bmesh.ops.extrude_edge_only(bm, edges=list(bm.edges))
    for v in [e for e in ret["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co *= 1.1
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Ring", mesh)
    mesh.materials.append(rig.material(color, emissive=True))
    bpy.context.scene.collection.objects.link(obj)
    obj.location = center
    no_shadow(obj)
    return obj


def lights():
    def sun(name, energy, rot, color=(1.0, 1.0, 1.0), shadow=True, angle=4.0):
        data = bpy.data.lights.new(name, "SUN")
        data.energy = energy
        data.color = color
        data.angle = math.radians(angle)
        if hasattr(data, "use_shadow"):
            data.use_shadow = shadow
        obj = bpy.data.objects.new(name, data)
        obj.rotation_euler = rot
        bpy.context.scene.collection.objects.link(obj)
        return obj
    # key from the front-left, high enough that a shelf's heroes throw their shadows behind their own shelf
    sun("Key", 3.4, (math.radians(55), 0.0, math.radians(-28)))
    sun("Rim", 3.0, (math.radians(-58), 0.0, math.radians(200)), (0.55, 0.75, 1.0), shadow=False)
    sun("Fill", 0.8, (math.radians(70), 0.0, math.radians(140)), (0.8, 0.85, 1.0), shadow=False)


# ------------------------------------------------------------------------------------------------ heroes


class Entry:
    def __init__(self, hero, built, name, stage, rarity, origin):
        self.hero = hero
        self.built = built
        self.name = name
        self.stage = stage
        self.rarity = rarity
        self.origin = origin
        self.fx = {}


def load_hero(hero_id):
    module = importlib.import_module("hero_anim.heroes." + hero_id)
    importlib.reload(module)
    return api.load_hero(module)


def shorten_webs(fx):
    """Web anchors can sit 15-40 studs away (swing anchors, arrow streaks): keep their direction, cap the length."""
    for e, objs in fx.items:
        if e["Type"] == "Web" and len(objs) > 1:
            a = Vector(e["Anchor"])
            centre = Vector((0.0, 3.0, 0.0))
            d = a - centre
            if d.length > WEB_MAX:
                a = centre + d.normalized() * WEB_MAX
            objs[1].location = rig.M3 @ a
        elif e["Type"] == "Burst":
            for obj in objs:
                obj.data.transform(Matrix.Scale(0.55, 4))


def pose_rig(entry, pose):
    arm = entry.built.arm
    for joint in api.JOINTS:
        r, p = pose.get(joint, (rbx.IDENTITY, (0.0, 0.0, 0.0)))
        quat, loc = rig.transform_to_basis(joint, rbx.quat_from_matrix(r), p)
        pb = arm.pose.bones[joint]
        pb.rotation_quaternion = quat
        if joint == "Root":
            pb.location = loc


def build_scene(entries_spec):
    rig.clear_scene()
    rig._MATERIALS.clear()
    scene = bpy.context.scene
    looks = preview.setup_look(scene, accent=(120, 170, 255))
    for obj in [looks["floor"], looks["ring"]] + looks["lights"]:
        bpy.data.objects.remove(obj, do_unlink=True)
    lights()
    scene.eevee.taa_render_samples = int(_arg("--samples", "16"))

    by_stage = {}
    for spec in entries_spec:
        by_stage.setdefault(spec[2], []).append(spec)
    entries = []
    width = PLAQUE_W + COLS * CELL_W
    for stage in sorted(by_stage):
        row = stage - 1
        z = -row * ROW_H
        title, accent = STAGES.get(stage, ("STAGE %d" % stage, (200, 200, 200)))
        # shelf, neon edge, back wall
        box("Shelf", (width / 2, 0.0, z - SHELF_T / 2), (width + 0.6, SHELF_D, SHELF_T), (26, 28, 38))
        box("ShelfEdge", (width / 2, -SHELF_D / 2 - 0.02, z - 0.08), (width + 0.6, 0.08, 0.14), accent, emissive=True, bevel=0.0)
        box("ShelfLip", (width / 2, -SHELF_D / 2 - 0.02, z - SHELF_T + 0.06), (width + 0.6, 0.08, 0.1), accent, emissive=True, bevel=0.0)
        wall = box("Wall", (width / 2, SHELF_D / 2 + 0.3, z + (ROW_H - SHELF_T) / 2 - 0.05), (width + 0.6, 0.3, ROW_H - SHELF_T - 0.1),
                   tuple(int(c * 0.10 + 10) for c in accent))
        wall.data.materials[0] = rig.material(tuple(int(c * 0.10 + 10) for c in accent), roughness=0.9)
        # stage plaque: STAGE n + franchise
        box("Plaque", (PLAQUE_W / 2, -0.4, z + 3.2), (PLAQUE_W - 1.0, 0.5, 6.2), (18, 20, 30), shadow=False)
        box("PlaqueFrame", (PLAQUE_W / 2, -0.66, z + 6.2), (PLAQUE_W - 1.0, 0.06, 0.14), accent, emissive=True, bevel=0.0)
        box("PlaqueFrame", (PLAQUE_W / 2, -0.66, z + 0.2), (PLAQUE_W - 1.0, 0.06, 0.14), accent, emissive=True, bevel=0.0)
        text("STAGE", (PLAQUE_W / 2, -0.7, z + 5.25), 0.95, (230, 235, 245), "title")
        text(str(stage), (PLAQUE_W / 2, -0.7, z + 3.4), 2.9, accent, "title")
        text(title, (PLAQUE_W / 2, -0.7, z + (1.25 if "\n" in title else 1.1)), 0.78 if "\n" not in title else 0.72,
             (240, 242, 250), "title")
        heroes = by_stage[stage]
        first = (COLS - len(heroes)) / 2.0
        for i, (hero_id, name, _, rarity) in enumerate(heroes):
            x = PLAQUE_W + (first + i + 0.5) * CELL_W
            hero = load_hero(hero_id)
            for obj in bpy.context.selected_objects:
                obj.select_set(False)
            built = rig.build(hero, name="Rig_" + hero_id)
            built.arm.location = (x, 0.0, z)
            built.arm.rotation_euler = (0.0, 0.0, YAW)
            built.arm.show_in_front = False
            built.arm.hide_render = True
            entry = Entry(hero, built, name, stage, rarity, (x, 0.0, z))
            for c in hero.ordered_clips():
                fx = preview.Effects(built, c)
                shorten_webs(fx)
                fx.hide_all()
                entry.fx[c.name] = fx
            rcol = RARITY.get(rarity, (200, 200, 200))
            ring((x, 0.0, z + 0.01), rcol)
            text(name.upper(), (x, -SHELF_D / 2 - 0.06, z - 0.5), min(0.6, 6.4 / (0.64 * len(name))), (245, 246, 252), "name")
            text(rarity.upper(), (x, -SHELF_D / 2 - 0.06, z - 1.06), 0.34, rcol, "name")
            entries.append(entry)
    bpy.context.view_layer.update()
    bottom = -(max(by_stage) - 1) * ROW_H - SHELF_T
    top = ROW_H - SHELF_T + 3.2
    title = text("STEAL A HERO", (1.0, -1.0, top - 1.2), 2.2, (255, 214, 70), "title", align="LEFT")
    bpy.context.view_layer.update()
    sub = text("%d HEROES  -  IDLE  /  MOVE  /  SPECIAL" % len(entries), (1.0 + title.dimensions.x + 1.2, -1.0, top - 1.45),
               0.95, (215, 222, 240), "title", align="LEFT")
    phases = {}
    for label, col in (("IDLE", (120, 200, 255)), ("MOVE", (90, 255, 150)), ("SPECIAL", (255, 120, 60))):
        phases[label] = text(label, (width - 0.8, -1.0, top - 1.2), 2.2, col, "title", align="RIGHT")
    return entries, (width, bottom, top), phases, (title, sub)


def camera(bounds, size_x):
    width, bottom, top = bounds
    scene = bpy.context.scene
    data = bpy.data.cameras.new("ShowCam")
    data.type = "ORTHO"
    cam = bpy.data.objects.new("ShowCam", data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    height = top - bottom
    margin = 1.2
    w, h = width + 2 * margin, height * math.cos(PITCH) + SHELF_D * math.sin(PITCH) + 2 * margin
    res_x = size_x
    res_y = int(round(size_x * h / w / 2.0)) * 2
    scene.render.resolution_x, scene.render.resolution_y = res_x, res_y
    data.ortho_scale = w
    centre = Vector((width / 2, 0.0, (top + bottom) / 2))
    direction = Vector((0.0, math.cos(PITCH), -math.sin(PITCH)))
    cam.location = centre - direction * 200.0
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    data.clip_end = 1000.0
    return cam


def bloom(scene):
    try:
        scene.use_nodes = True
        tree = scene.node_tree
        tree.nodes.clear()
        rl = tree.nodes.new("CompositorNodeRLayers")
        glare = tree.nodes.new("CompositorNodeGlare")
        try:
            glare.glare_type = "BLOOM"
        except TypeError:
            glare.glare_type = "FOG_GLOW"
        for key, val in (("quality", "HIGH"), ("threshold", 1.0), ("size", 6)):
            if hasattr(glare, key):
                try:
                    setattr(glare, key, val)
                except (AttributeError, TypeError):
                    pass
        comp = tree.nodes.new("CompositorNodeComposite")
        tree.links.new(rl.outputs["Image"], glare.inputs["Image"])
        tree.links.new(glare.outputs["Image"], comp.inputs["Image"])
    except Exception as exc:  # compositor API changes between Blender versions: bloom is optional
        scene.use_nodes = False
        print("[showcase] bloom skipped:", exc)


def show_phase(phases, which):
    for label, obj in phases.items():
        obj.hide_render = label != which


# ------------------------------------------------------------------------------------------------ outputs


def render_stills(entries, phases, tmp_dir):
    scene = bpy.context.scene
    scene.render.image_settings.file_format = "PNG"
    panels = []
    for clip_name in ("Idle", "Move"):
        for e in entries:
            c = e.hero.clips[clip_name]
            t = e.hero.thumb_times.get(clip_name, c.length * (0.35 if clip_name == "Move" else 0.0))
            pose_rig(e, api.sample_clip(c, t, e.hero.compiled[clip_name]))
            for name, fx in e.fx.items():
                if name == clip_name:
                    fx.apply(t, c.length)
                else:
                    fx.hide_all()
        show_phase(phases, clip_name.upper())
        path = os.path.join(tmp_dir, "still_%s.png" % clip_name)
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        panels.append(preview._load_pixels(path))
    import numpy as np
    sheet = np.concatenate([panels[1], panels[0]], axis=0)  # Blender images are bottom-up: Idle ends on top
    out = os.path.join(preview.PREVIEW_DIR, "showcase.png")
    preview._save_pixels(sheet, out)
    for e in entries:
        for fx in e.fx.values():
            fx.hide_all()
    return out


TIMELINE = [("Idle", 3.5), ("Move", 5.0), ("Idle", 1.0), ("Special", None), ("Idle", 1.6)]


def timeline(entries):
    special = max((e.hero.clips["Special"].length for e in entries if "Special" in e.hero.clips), default=0.0)
    return [(n, d if d is not None else special + 0.3) for n, d in TIMELINE]


def _key_all(action_curves, frames, values):
    """Replace every F-curve's keys with one linear key per frame (values[data_path, index] -> list)."""
    for fc in action_curves:
        vals = values.get((fc.data_path, fc.array_index))
        if vals is None:
            continue
        fc.keyframe_points.clear()
        fc.keyframe_points.add(len(frames))
        co = []
        for f, v in zip(frames, vals):
            co += [float(f), float(v)]
        fc.keyframe_points.foreach_set("co", co)
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
        fc.update()


def bake_video(entries, phases):
    scene = bpy.context.scene
    segments = timeline(entries)
    total = sum(d for _, d in segments)
    frames = int(total * FPS)
    dt = 1.0 / FPS
    # the phase caption per frame (the dominant clip)
    seg_of_frame = []
    start, index = 0.0, 0
    for f in range(frames + 1):
        now = f * dt
        while index < len(segments) - 1 and now >= start + segments[index][1]:
            start += segments[index][1]
            index += 1
        seg_of_frame.append(index)
    for label, obj in phases.items():
        prev = None
        for f in range(frames + 1):
            name = segments[seg_of_frame[f]][0].upper()
            hidden = name != label
            if hidden != prev:
                obj.hide_render = hidden
                obj.keyframe_insert("hide_render", frame=f)
                prev = hidden
    for n, e in enumerate(entries):
        hero, arm = e.hero, e.built.arm
        idle, move = hero.clips["Idle"], hero.clips["Move"]
        special = hero.clips.get("Special")
        action = bpy.data.actions.new("%s_Showcase" % hero.id)
        export._set_action(arm, action)
        values = {}
        w_move, w_special = 0.0, 0.0
        t_idle, t_move, t_special = 0.0, 0.0, -1.0
        fx_state = []
        last_seg = -1
        prev_quats = {}
        for f in range(frames + 1):
            seg = seg_of_frame[f]
            name = segments[seg][0]
            if seg != last_seg and name == "Special":
                t_special = 0.0
            last_seg = seg
            moving = name == "Move"
            if moving and w_move <= 1e-6:
                t_move = 0.0
            w_move = min(1.0, w_move + dt / 0.25) if moving else max(0.0, w_move - dt / 0.25)
            if name == "Special" and special is not None and 0.0 <= t_special < special.length:
                fade_out = special.length - t_special < 0.3
                w_special = max(0.0, w_special - dt / 0.3) if fade_out else min(1.0, w_special + dt / 0.2)
            else:
                w_special = max(0.0, w_special - dt / 0.3)
            a = api.sample_clip(idle, t_idle, hero.compiled["Idle"])
            b = api.sample_clip(move, t_move, hero.compiled["Move"])
            pose = preview._blend(a, b, w_move)
            if special is not None and w_special > 0:
                s = api.sample_clip(special, min(max(t_special, 0.0), special.length), hero.compiled["Special"])
                pose = preview._blend(pose, s, w_special)
            for joint in api.JOINTS:
                r, p = pose.get(joint, (rbx.IDENTITY, (0.0, 0.0, 0.0)))
                quat, loc = rig.transform_to_basis(joint, rbx.quat_from_matrix(r), p)
                last = prev_quats.get(joint)
                if last is not None and last.dot(quat) < 0:
                    quat.negate()
                prev_quats[joint] = quat
                path = 'pose.bones["%s"].rotation_quaternion' % joint
                for i in range(4):
                    values.setdefault((path, i), []).append(quat[i])
                if joint == "Root":
                    lpath = 'pose.bones["Root"].location'
                    for i in range(3):
                        values.setdefault((lpath, i), []).append(loc[i])
            fx_state.append((w_move, w_special, t_idle, t_move, t_special))
            t_idle += dt
            if w_move > 0:
                t_move += dt
            if t_special >= 0:
                t_special += dt
        # one keyframe_insert per channel creates the F-curves (bound to the action slot), then bulk-replace the keys
        for pb in arm.pose.bones:
            pb.keyframe_insert("rotation_quaternion", frame=0, group=pb.name)
            if pb.name == "Root":
                pb.keyframe_insert("location", frame=0, group=pb.name)
        _key_all(export._fcurves(action), list(range(frames + 1)), values)
        # effect stand-ins: the dominant clip's windows (keys only where something changes)
        clips = {"Idle": idle, "Move": move, "Special": special}
        for clip_name, fx in e.fx.items():
            c = clips.get(clip_name)
            if c is None:
                continue
            prev_vis = {}
            for f, (wm, ws, ti, tm, ts) in enumerate(fx_state):
                on = {"Idle": wm <= 0.5 and ws <= 0.3, "Move": wm > 0.5 and ws <= 0.3, "Special": ws > 0.3}[clip_name]
                t = {"Idle": ti, "Move": tm, "Special": ts}[clip_name]
                t = t % c.length if c.loop else t
                for objs, visible, s in fx.state(t, c.length):
                    for obj in objs:
                        if obj.type == "EMPTY":
                            continue
                        vis = on and visible
                        if prev_vis.get(obj.name) != vis:
                            obj.hide_render = not vis
                            obj.keyframe_insert("hide_render", frame=f)
                            prev_vis[obj.name] = vis
                        if vis and "Orb" in obj.name:
                            obj.scale = (s, s, s)
                            obj.keyframe_insert("scale", frame=f)
        if n % 8 == 7:
            print("[showcase] baked %d/%d heroes" % (n + 1, len(entries)))
    scene.frame_start, scene.frame_end = 0, frames
    return frames


def render_video(frames, size_x):
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.render.fps_base = 1.0
    scene.render.image_settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format = "MPEG4"
    scene.render.ffmpeg.codec = "H264"
    scene.render.ffmpeg.constant_rate_factor = "MEDIUM"
    scene.render.ffmpeg.ffmpeg_preset = "GOOD"
    path = os.path.join(preview.PREVIEW_DIR, "showcase.mp4")
    if os.path.exists(path):
        os.remove(path)
    scene.render.filepath = path
    t0 = time.time()
    bpy.ops.render.render(animation=True)
    print("[showcase] video %d frames in %.0fs" % (frames + 1, time.time() - t0))
    return path


def main():
    size_x = int(_arg("--size", "1920"))
    heroes = roster()
    only = _arg("--heroes")
    if only:
        wanted = set(h.strip() for h in only.split(","))
        heroes = [h for h in heroes if h[0] in wanted]
    t0 = time.time()
    entries, bounds, phases, _ = build_scene(heroes)
    camera(bounds, size_x)
    bloom(bpy.context.scene)
    print("[showcase] scene: %d heroes in %.1fs, %dx%d" % (len(entries), time.time() - t0, bpy.context.scene.render.resolution_x,
                                                            bpy.context.scene.render.resolution_y))
    tmp_dir = tempfile.mkdtemp(prefix="showcase_")
    png = render_stills(entries, phases, tmp_dir)
    print("[showcase] -> %s" % os.path.relpath(png, api.REPO_ROOT))
    if "--no-video" not in ARGV:
        frames = bake_video(entries, phases)
        mp4 = render_video(frames, size_x)
        print("[showcase] -> %s" % os.path.relpath(mp4, api.REPO_ROOT))
    if "--save-blend" in ARGV:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(tmp_dir, "showcase.blend"), copy=True)
        print("[showcase] blend: %s" % os.path.join(tmp_dir, "showcase.blend"))
    print("[showcase] OK")
    sys.stdout.flush()


try:
    main()
except SystemExit:
    raise
except BaseException:
    traceback.print_exc()
    print("[showcase] FAILED")
    sys.stdout.flush()
    os._exit(1)
