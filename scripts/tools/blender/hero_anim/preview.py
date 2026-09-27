# scripts/tools/blender/hero_anim/preview.py
# Preview renders for the hero clips (Eevee, headless). Writes into assets/animations/preview/:
#   <HeroId>_sheet.png      contact sheet: one row per clip (Idle, Move, Special...), columns = poses across the clip
#                           (every key time, up to 6), each tile labelled "<Clip> <time>s"
#   <HeroId>.mp4            ~14 s turntable-free showcase: Idle -> Move (travelling at the clip's Speed, or 9 studs/s,
#                           the camera follows) -> Idle -> Special -> Idle, cross-faded like the game (HeroClipPlayer:
#                           eased 0.25 s Idle<->Move, Special 0.2 s in / 0.3 s out)
#   thumbs/<HeroId>_<Clip>.png   256 px hero frames, combined by combined_sheet() into _all_heroes.png
# Effects are drawn as stand-ins: Web = a white strand from the hand to its anchor, Charge = a glowing orb on the
# hand(s), Burst = a flash. They follow the clip's effect windows.

import math
import os

import bpy
from mathutils import Matrix, Vector

from . import api, rbx, rig

PREVIEW_DIR = os.path.join(api.REPO_ROOT, "assets", "animations", "preview")
THUMB_DIR = os.path.join(PREVIEW_DIR, "thumbs")
TILE = 420
THUMB = 256
VIDEO_FPS = 30
VIDEO_SIZE = 540
MOVE_SPEED = 9.0  # studs / s the preview rig travels while Move plays


def _hex(c):
    return tuple(v / 255.0 for v in c)


# ------------------------------------------------------------------------------------------------ look


def setup_look(scene, accent=(90, 170, 255)):
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE"
    try:
        scene.eevee.taa_render_samples = 24
        scene.eevee.use_shadows = True
    except AttributeError:
        pass
    views = [v.identifier for v in scene.view_settings.bl_rna.properties["view_transform"].enum_items]
    scene.view_settings.view_transform = "AgX" if "AgX" in views else "Filmic"
    try:
        scene.view_settings.look = "AgX - Punchy" if "AgX" in views else "None"
    except TypeError:
        scene.view_settings.look = "None"
    scene.render.film_transparent = False

    world = scene.world or bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    nt = world.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    grad = nt.nodes.new("ShaderNodeTexGradient")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    coord = nt.nodes.new("ShaderNodeTexCoord")
    mapping = nt.nodes.new("ShaderNodeMapping")
    mapping.inputs["Rotation"].default_value = (0.0, -math.pi / 2, 0.0)  # gradient along Z (window vertical)
    nt.links.new(coord.outputs["Window"], mapping.inputs["Vector"])
    nt.links.new(mapping.outputs["Vector"], grad.inputs["Vector"])
    nt.links.new(grad.outputs["Fac"], ramp.inputs["Fac"])
    ramp.color_ramp.elements[0].color = (0.010, 0.012, 0.030, 1.0)
    ramp.color_ramp.elements[1].color = (0.060, 0.075, 0.160, 1.0)
    nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 1.0
    nt.links.new(bg.outputs["Background"], out.inputs["Surface"])

    lights = []
    key = bpy.data.lights.new("Key", "SUN")
    key.energy = 3.6
    key.angle = math.radians(6)
    key_obj = bpy.data.objects.new("Key", key)
    key_obj.rotation_euler = (math.radians(50), math.radians(-12), math.radians(-38))
    lights.append(key_obj)
    rim = bpy.data.lights.new("Rim", "SUN")
    rim.energy = 4.5
    rim.color = _hex(accent)
    rim_obj = bpy.data.objects.new("Rim", rim)
    rim_obj.rotation_euler = (math.radians(-60), math.radians(20), math.radians(160))
    lights.append(rim_obj)
    fill = bpy.data.lights.new("Fill", "SUN")
    fill.energy = 0.9
    fill.color = (0.75, 0.82, 1.0)
    fill_obj = bpy.data.objects.new("Fill", fill)
    fill_obj.rotation_euler = (math.radians(70), 0.0, math.radians(120))
    lights.append(fill_obj)
    for obj in lights:
        scene.collection.objects.link(obj)

    # floor: large checker plane (reads travel speed) + a glowing ring under the hero
    mesh = bpy.data.meshes.new("Floor")
    size = 400.0
    mesh.from_pydata([(-size, -size, 0), (size, -size, 0), (size, size, 0), (-size, size, 0)], [], [(0, 1, 2, 3)])
    floor = bpy.data.objects.new("Floor", mesh)
    mat = bpy.data.materials.new("FloorMat")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    checker = nodes.new("ShaderNodeTexChecker")
    checker.inputs["Scale"].default_value = size / 2.0  # 4-stud tiles over the 800-stud plane (UV 0..1)
    checker.inputs["Color1"].default_value = (0.045, 0.05, 0.07, 1.0)
    checker.inputs["Color2"].default_value = (0.075, 0.085, 0.115, 1.0)
    mat.node_tree.links.new(checker.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.35
    mesh.uv_layers.new(name="UV")
    for loop, uv in zip(mesh.uv_layers[0].data, ((0, 0), (1, 0), (1, 1), (0, 1))):
        loop.uv = uv
    mesh.materials.append(mat)
    scene.collection.objects.link(floor)

    ring_mesh = bpy.data.meshes.new("Ring")
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=False, segments=48, radius=2.6)
    ret = bmesh.ops.extrude_edge_only(bm, edges=list(bm.edges))
    for v in [e for e in ret["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co *= 1.07
    bm.to_mesh(ring_mesh)
    bm.free()
    ring = bpy.data.objects.new("Ring", ring_mesh)
    ring.location.z = 0.01
    ring_mesh.materials.append(rig.material(accent, emissive=True))
    scene.collection.objects.link(ring)
    return {"floor": floor, "ring": ring, "lights": lights}


def _camera(scene):
    cam_data = bpy.data.cameras.new("PreviewCam")
    cam_data.lens = 50
    cam_data.sensor_fit = "AUTO"
    cam = bpy.data.objects.new("PreviewCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def _look_at(cam, eye, target):
    cam.location = Vector(eye)
    direction = Vector(target) - Vector(eye)
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


CAMERA_PRESETS = {
    # eye offset (Blender coords relative to the rig origin), target height, lens
    "front34": ((5.8, -9.6, 3.9), 2.5, 50),
    "front": ((0.0, -11.0, 3.2), 2.5, 50),
    "side34": ((9.6, -5.2, 3.4), 2.3, 50),
    "side": ((11.0, 0.0, 3.0), 2.3, 50),
    "wide": ((8.0, -12.0, 6.5), 3.2, 42),
    "chase": ((10.5, -7.5, 4.6), 2.7, 40),
}


def _place_camera(cam, preset, origin=(0.0, 0.0, 0.0), frame=None):
    """Aim a preset. frame = (centre Vector, radius): the camera looks at the centre from the preset's direction, far
    enough for a sphere of that radius to fill ~80 % of the view."""
    eye, target_z, lens = CAMERA_PRESETS.get(preset, CAMERA_PRESETS["front34"])
    o = Vector(origin)
    cam.data.lens = lens
    if frame is None:
        _look_at(cam, o + Vector(eye), o + Vector((0.0, 0.0, target_z)))
        return
    centre, radius = frame
    direction = Vector(eye) - Vector((0.0, 0.0, target_z))
    half_fov = math.atan(18.0 / lens)
    dist = max(radius / math.sin(half_fov) * 1.12, 6.0)
    _look_at(cam, centre + direction.normalized() * dist, centre)


def _bounds(built):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for name, obj in built.parts.items():
        if name == "HumanoidRootPart":
            continue
        for corner in obj.bound_box:
            w = obj.matrix_world @ Vector(corner)
            lo = Vector((min(lo.x, w.x), min(lo.y, w.y), min(lo.z, w.z)))
            hi = Vector((max(hi.x, w.x), max(hi.y, w.y), max(hi.z, w.z)))
    return lo, hi


def _clip_frame(built, action, c, times, export_mod):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for t in times:
        export_mod.pose_at(built, action, t)
        a, b = _bounds(built)
        lo = Vector((min(lo.x, a.x), min(lo.y, a.y), min(lo.z, a.z)))
        hi = Vector((max(hi.x, b.x), max(hi.y, b.y), max(hi.z, b.z)))
    lo.z = min(lo.z, 0.0)
    centre = (lo + hi) * 0.5
    radius = max((hi - lo).length * 0.5, 2.6)
    return centre, radius


def _default_camera(clip_name):
    return "side34" if clip_name == "Move" else "front34"


# ------------------------------------------------------------------------------------------------ labels


def _label(cam, text):
    curve = bpy.data.curves.new("Label", "FONT")
    curve.body = text
    curve.size = 0.07
    curve.align_x = "LEFT"
    obj = bpy.data.objects.new("Label", curve)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(rig.material((255, 255, 255), emissive=True))
    obj.parent = cam
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.location = (-0.66, -0.68, -2.0)
    return obj


# ------------------------------------------------------------------------------------------------ effect stand-ins


class Effects:
    def __init__(self, built, clip):
        self.items = []
        self.built = built
        for e in clip.effects:
            if e["Type"] == "Web":
                self.items.append((e, self._web(e)))
            elif e["Type"] == "Charge":
                self.items.append((e, self._orbs(e, 0.5 * e["Size"], e["Color"])))
            elif e["Type"] == "Burst":
                self.items.append((e, self._orbs(e, 1.4, e["Color"])))

    def _hand_objects(self, hand):
        names = ["LeftHand", "RightHand"] if hand == "Both" else [hand]
        return [self.built.parts[n] for n in names]

    def _orbs(self, e, radius, color):
        objs = []
        for hand in self._hand_objects(e["Hand"]):
            mesh = bpy.data.meshes.new("Orb")
            import bmesh
            bm = bmesh.new()
            bmesh.ops.create_icosphere(bm, subdivisions=2, radius=radius)
            bm.to_mesh(mesh)
            bm.free()
            obj = bpy.data.objects.new("FxOrb", mesh)
            bpy.context.scene.collection.objects.link(obj)
            mesh.materials.append(rig.material(color, emissive=True))
            obj.parent = hand
            obj.matrix_parent_inverse = Matrix.Identity(4)
            obj.location = (0.0, -0.35, 0.0)  # palm side (Roblox hand-local -Y is the fingertips)
            objs.append(obj)
        return objs

    def _web(self, e):
        mesh = bpy.data.meshes.new("Web")
        import bmesh
        bm = bmesh.new()
        geo = bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=e["Width"] * 0.5, radius2=e["Width"] * 0.35, depth=1.0)
        bmesh.ops.rotate(bm, verts=geo["verts"], matrix=Matrix.Rotation(-math.pi / 2, 3, "X"))
        bmesh.ops.translate(bm, verts=geo["verts"], vec=Vector((0.0, 0.5, 0.0)))
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new("FxWeb", mesh)
        bpy.context.scene.collection.objects.link(obj)
        mesh.materials.append(rig.material(e["Color"], emissive=False, roughness=0.3))
        hand = self.built.parts[e["Hand"]]
        obj.parent = hand
        obj.matrix_parent_inverse = Matrix.Identity(4)
        obj.location = (0.0, -0.1, 0.0)
        anchor = bpy.data.objects.new("FxWebAnchor", None)
        bpy.context.scene.collection.objects.link(anchor)
        anchor.parent = self.built.arm
        a = e["Anchor"]
        anchor.location = rig.M3 @ Vector((a[0], a[1], a[2]))
        con = obj.constraints.new("STRETCH_TO")
        con.target = anchor
        con.rest_length = 1.0
        con.volume = "NO_VOLUME"
        return [obj, anchor]

    def state(self, clip_time, length):
        """[(objects, visible, scale)] at clip time t."""
        out = []
        for e, objs in self.items:
            if e["Type"] == "Burst":
                dt = clip_time - e["Time"]
                visible = 0.0 <= dt < 0.25
                s = 0.4 + dt * 5.0 if visible else 1.0
            else:
                t0 = e["From"] if e.get("From") is not None else 0.0
                t1 = e["To"] if e.get("To") is not None else length + 1.0
                visible = t0 <= clip_time <= t1
                s = 1.0
                if e["Type"] == "Charge" and visible:
                    grow = min(1.0, (clip_time - t0) / 0.4)
                    s = (0.35 + 0.65 * grow) * (1.0 + 0.12 * math.sin(clip_time * 40.0))
            out.append((objs, visible, s))
        return out

    def apply(self, clip_time, length):
        for objs, visible, s in self.state(clip_time, length):
            for obj in objs:
                if obj.type == "EMPTY":
                    continue
                obj.hide_render = not visible
                obj.hide_viewport = not visible
                if "Orb" in obj.name:
                    obj.scale = (s, s, s)

    def hide_all(self):
        for _, objs in self.items:
            for obj in objs:
                if obj.type != "EMPTY":
                    obj.hide_render = True
                    obj.hide_viewport = True

    def remove(self):
        for _, objs in self.items:
            for obj in objs:
                bpy.data.objects.remove(obj, do_unlink=True)
        self.items = []


# ------------------------------------------------------------------------------------------------ images


def _load_pixels(path):
    import numpy as np
    img = bpy.data.images.load(path, check_existing=False)
    w, h = img.size
    buf = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    bpy.data.images.remove(img)
    return buf.reshape(h, w, 4)


def _save_pixels(arr, path):
    import numpy as np
    h, w = arr.shape[0], arr.shape[1]
    img = bpy.data.images.new("Sheet", width=w, height=h, alpha=True)
    img.pixels.foreach_set(np.ascontiguousarray(arr, dtype=np.float32).ravel())
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def _grid(tiles, cols, tile_w, tile_h, bg=(0.02, 0.022, 0.04, 1.0)):
    """tiles: rows of [pixel arrays or None] (top row first) -> one array (Blender images are bottom-up)."""
    import numpy as np
    rows = len(tiles)
    sheet = np.empty((rows * tile_h, cols * tile_w, 4), dtype=np.float32)
    sheet[:, :] = bg
    for r, row in enumerate(tiles):
        for c, px in enumerate(row):
            if px is None:
                continue
            y0 = (rows - 1 - r) * tile_h
            h, w = min(px.shape[0], tile_h), min(px.shape[1], tile_w)
            sheet[y0:y0 + h, c * tile_w:c * tile_w + w] = px[:h, :w]
    return sheet


def _downscale(px, size):
    import numpy as np
    h, w = px.shape[0], px.shape[1]
    ys = (np.arange(size) * h / size).astype(int)
    xs = (np.arange(size) * w / size).astype(int)
    return px[ys][:, xs]


# ------------------------------------------------------------------------------------------------ renders


def _sample_times(c, compiled, limit=6):
    times = sorted(set(round(k[0], 3) for keys in compiled.values() for k in keys))
    if c.loop and times and abs(times[-1] - c.length) < 1e-3 and len(times) > 1:
        times = times[:-1]  # the loop's closing key equals the first
    if len(times) > limit:
        step = (len(times) - 1) / (limit - 1)
        times = [times[round(i * step)] for i in range(limit)]
    if len(times) < 3:
        times = [round(c.length * i / 4.0, 3) for i in range(4 if c.loop else 5)]
    return times


def render_sheet(built, hero, actions, export_mod, tmp_dir):
    scene = bpy.context.scene
    scene.render.resolution_x = scene.render.resolution_y = TILE
    scene.render.image_settings.file_format = "PNG"
    cam = _camera(scene)
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    os.makedirs(THUMB_DIR, exist_ok=True)
    rows = []
    cols = 1
    for c in hero.ordered_clips():
        fx = Effects(built, c)
        preset = hero.cameras.get(c.name, _default_camera(c.name))
        times = _sample_times(c, hero.compiled[c.name])
        _place_camera(cam, preset, frame=_clip_frame(built, actions[c.name], c, times, export_mod))
        thumb_t = hero.thumb_times.get(c.name, c.length * (0.35 if c.name == "Move" else 0.6 if c.name == "Special" else 0.0))
        if thumb_t not in times:
            times = sorted(times + [round(thumb_t, 3)]) if len(times) < 6 else times
        row = []
        for t in times:
            export_mod.pose_at(built, actions[c.name], t)
            fx.apply(t, c.length)
            label = _label(cam, "%s  %s  %.2fs" % (hero.id, c.name, t))
            path = os.path.join(tmp_dir, "%s_%s_%03d.png" % (hero.id, c.name, int(round(t * 100))))
            scene.render.filepath = path
            bpy.ops.render.render(write_still=True)
            bpy.data.objects.remove(label, do_unlink=True)
            px = _load_pixels(path)
            row.append(px)
            if abs(t - thumb_t) < 1e-3 or (t == times[-1] and not any(abs(x - thumb_t) < 1e-3 for x in times)):
                _save_pixels(_downscale(px, THUMB), os.path.join(THUMB_DIR, "%s_%s.png" % (hero.id, c.name)))
        fx.remove()
        rows.append(row)
        cols = max(cols, len(row))
    sheet = _grid(rows, cols, TILE, TILE)
    path = os.path.join(PREVIEW_DIR, "%s_sheet.png" % hero.id)
    _save_pixels(sheet, path)
    bpy.data.objects.remove(cam, do_unlink=True)
    return path


def combined_sheet():
    """_all_heroes.png: one row per hero with a thumbnail (Idle / Move / Special), from thumbs/."""
    if not os.path.isdir(THUMB_DIR):
        return None
    heroes = {}
    for name in sorted(os.listdir(THUMB_DIR)):
        if not name.endswith(".png") or "_" not in name:
            continue
        hero, clip_name = name[:-4].rsplit("_", 1)
        heroes.setdefault(hero, {})[clip_name] = os.path.join(THUMB_DIR, name)
    if not heroes:
        return None
    rows = []
    for hero in sorted(heroes):
        rows.append([_load_pixels(heroes[hero][c]) if c in heroes[hero] else None for c in api.CLIP_NAMES])
    # 2 heroes per sheet row keeps the image readable: pack rows side by side
    packed = []
    for i in range(0, len(rows), 2):
        packed.append(rows[i] + (rows[i + 1] if i + 1 < len(rows) else [None] * 3))
    sheet = _grid(packed, 6, THUMB, THUMB)
    path = os.path.join(PREVIEW_DIR, "_all_heroes.png")
    _save_pixels(sheet, path)
    return path


# ------------------------------------------------------------------------------------------------ video


def _timeline(hero):
    segments = [("Idle", 3.0), ("Move", 5.0), ("Idle", 2.0)]
    if "Special" in hero.clips:
        segments += [("Special", hero.clips["Special"].length + 0.3), ("Idle", 1.5)]
    return segments


def render_video(built, hero, tmp_dir):
    """Bakes the showcase into a 'Preview' action (the runtime's cross-fade math) and renders an MP4."""
    scene = bpy.context.scene
    arm = built.arm
    segments = _timeline(hero)
    total = sum(d for _, d in segments)
    frames = int(total * VIDEO_FPS)
    dt = 1.0 / VIDEO_FPS
    idle, move = hero.clips["Idle"], hero.clips["Move"]
    special = hero.clips.get("Special")

    action = bpy.data.actions.new("%s_Preview" % hero.id)
    from . import export as export_mod
    export_mod._set_action(arm, action)
    fx_move = Effects(built, move)
    fx_special = Effects(built, special) if special else None
    fx_move.hide_all()
    if fx_special:
        fx_special.hide_all()
    cam = _camera(scene)
    scene.render.resolution_x = scene.render.resolution_y = VIDEO_SIZE

    w_move, w_special = 0.0, 0.0
    t_idle, t_move, t_special = 0.0, 0.0, -1.0
    travel = 0.0
    seg_start = 0.0
    seg_index = 0
    fx_keys = []
    for f in range(frames + 1):
        now = f * dt
        while seg_index < len(segments) - 1 and now >= seg_start + segments[seg_index][1]:
            seg_start += segments[seg_index][1]
            seg_index += 1
            if segments[seg_index][0] == "Special":
                t_special = 0.0
        name = segments[seg_index][0]
        moving = name == "Move"
        if moving and w_move <= 1e-6:
            t_move = 0.0
        w_move = min(1.0, w_move + dt / 0.25) if moving else max(0.0, w_move - dt / 0.25)
        if name == "Special" and special is not None and t_special < special.length:
            fade_out = special.length - t_special < 0.3
            w_special = max(0.0, w_special - dt / 0.3) if fade_out else min(1.0, w_special + dt / 0.2)
        else:
            w_special = max(0.0, w_special - dt / 0.3)
        a = api.sample_clip(idle, t_idle, hero.compiled["Idle"])
        b = api.sample_clip(move, t_move, hero.compiled["Move"])
        pose = _blend(a, b, w_move * w_move * (3.0 - 2.0 * w_move))  # HeroClipPlayer eases its cross-fades
        if special is not None and w_special > 0:
            s = api.sample_clip(special, min(max(t_special, 0.0), special.length), hero.compiled["Special"])
            pose = _blend(pose, s, w_special)
        for joint in api.JOINTS:
            r, p = pose.get(joint, (rbx.IDENTITY, (0.0, 0.0, 0.0)))
            q = rbx.quat_from_matrix(r)
            quat, loc = rig.transform_to_basis(joint, q, p)
            pb = arm.pose.bones[joint]
            pb.rotation_quaternion = quat
            pb.keyframe_insert("rotation_quaternion", frame=f, group=joint)
            if joint == "Root":
                pb.location = loc
                pb.keyframe_insert("location", frame=f, group=joint)
        # a Move with a Speed (foot-locked gaits) travels at exactly that speed: the planted feet must stay put
        travel += (move.speed if isinstance(move.speed, (int, float)) else MOVE_SPEED) * w_move * dt
        arm.location = (0.0, -travel, 0.0)
        arm.keyframe_insert("location", frame=f)
        # effects: the dominant clip's windows
        fx_keys.append((f, w_move > 0.5, t_move, w_special > 0.3, t_special))
        t_idle += dt
        if w_move > 0:
            t_move += dt
        if t_special >= 0:
            t_special += dt
    for fc in export_mod._fcurves(action):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    # effects visibility keys (constant)
    for f, move_on, tm, special_on, ts in fx_keys:
        for fx, on, t, c in ((fx_move, move_on, tm, move), (fx_special, special_on, ts, special)):
            if fx is None:
                continue
            for objs, visible, s in fx.state(t % c.length if c.loop else t, c.length):
                for obj in objs:
                    if obj.type == "EMPTY":
                        continue
                    obj.hide_render = not (on and visible)
                    obj.keyframe_insert("hide_render", frame=f)
                    if "Orb" in obj.name:
                        obj.scale = (s, s, s)
                        obj.keyframe_insert("scale", frame=f)
    # camera follows the travel
    for f in range(0, frames + 1, 2):
        scene.frame_set(f)
        origin = arm.location.copy()
        _place_camera(cam, "chase", origin)
        cam.keyframe_insert("location", frame=f)
        cam.keyframe_insert("rotation_euler", frame=f)
    scene.frame_start, scene.frame_end = 0, frames
    scene.render.fps = VIDEO_FPS
    scene.render.fps_base = 1.0
    scene.render.image_settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format = "MPEG4"
    scene.render.ffmpeg.codec = "H264"
    scene.render.ffmpeg.constant_rate_factor = "MEDIUM"
    scene.render.ffmpeg.ffmpeg_preset = "GOOD"
    try:
        scene.eevee.taa_render_samples = 12
    except AttributeError:
        pass
    path = os.path.join(PREVIEW_DIR, "%s.mp4" % hero.id)
    if os.path.exists(path):
        os.remove(path)
    scene.render.filepath = path
    bpy.ops.render.render(animation=True)
    # restore still settings
    scene.render.image_settings.file_format = "PNG"
    scene.render.fps = export_mod.FPS
    arm.animation_data.action = None
    arm.location = (0.0, 0.0, 0.0)
    fx_move.remove()
    if fx_special:
        fx_special.remove()
    bpy.data.objects.remove(cam, do_unlink=True)
    return path


def _blend(a, b, w):
    if w <= 0.0:
        return a
    if w >= 1.0:
        return b
    out = {}
    for joint in set(a) | set(b):
        ra, pa = a.get(joint, (rbx.IDENTITY, (0.0, 0.0, 0.0)))
        rb, pb = b.get(joint, (rbx.IDENTITY, (0.0, 0.0, 0.0)))
        q = rbx.nlerp(rbx.quat_from_matrix(ra), rbx.quat_from_matrix(rb), w)
        out[joint] = (rbx.quat_to_matrix(q), tuple(pa[i] + (pb[i] - pa[i]) * w for i in range(3)))
    return out
