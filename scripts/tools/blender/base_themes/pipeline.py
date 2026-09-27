# scripts/tools/blender/base_themes/pipeline.py
# Build / check / export / render machinery behind run.py (the theme API is common.py; themes never import this).
#
#   build_theme(theme)                  -> {variant: Builder} + problems (contract)
#   scene_objects(theme, B)             -> Blender objects with LIVE modifier stacks (Bevel ANGLE 35 + Weighted Normal
#                                          + Triangulate), one per (role, bevel class), in one collection per family
#   flatten(theme, B, objs)             -> one mesh per role, modifiers applied (custom normals kept), triangulated
#   export_theme(...)                   -> <NAME>.fbx (both variants) + <NAME>.blend (live stacks) + <NAME>.json
#   render_theme(theme, B, objs)        -> preview/<NAME>_hero|gate|detail|top.png (EEVEE, 50 mm, 3-point studio)
#                                          + _landmark|_playercam.png for a theme with a landmark
#   coherence_sheet()                   -> assets/models/bases/preview/_coherence.png (every v3 theme's hero shot)
#   write_studio_helper()               -> assets/models/bases/BaseThemesImport.lua from every theme JSON
#   geometry_fingerprint(layout)        -> the layout's geometry id (stale-import detection; the build loader computes
#                                          the same string: post_zz_base_themes Step.geometryFingerprint)
#   view(themes)                        -> Blender window layout (both variants, props for scale)
#
# 2026-09-25 (owner): no Neon and no lights in the bases. Nothing here makes a Neon material or an emissive preview
# material for a theme role, the JSON "lights" lists are empty and the helper never sets Enum.Material.Neon.

import hashlib
import json
import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

import common as C

ROOT = os.getcwd()
BASES_DIR = os.path.join(ROOT, "assets", "models", "bases")
SHEET_DIR = os.path.join(BASES_DIR, "preview")
TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
OBSTACLES_PATH = os.path.join(TOOL_DIR, "plot_obstacles.json")
ORDER = ["Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano"]
SHOTS = ("hero", "gate", "detail", "top")  # render_theme's shots, in this order
LANDMARK_SHOTS = ("landmark", "playercam")  # extra shots of a theme with a landmark
LEGACY_SHOTS = ("back", "terminal", "coherence")  # pre-v3 shots, removed when a theme renders
UV_STUDS = 6.0  # cube-projected UVs: one material texture tile per 6 studs
LENS = 50.0
VIEW_EXPOSURE = -0.3
FINGERPRINT_FORMAT = "stealahero-geometry/1"
# Roblox's default camera (the playercam shot): FieldOfView 70 (vertical), 12.5 studs from the head
ROBLOX_FOV = 70.0
ROBLOX_ZOOM = 12.5


def rel(path):
    return os.path.relpath(path, ROOT).replace("\\", "/")


def load_obstacles():
    if not os.path.isfile(OBSTACLES_PATH):
        return None
    with open(OBSTACLES_PATH, encoding="utf-8") as fh:
        return json.load(fh).get("plots")


# ----------------------------------------------------------------------------------------------------------------------
# validation + build
# ----------------------------------------------------------------------------------------------------------------------

def validate_theme(theme, check_layouts=True):
    problems = []
    for attr in ("KEY", "NAME", "TITLE"):
        if not getattr(theme, attr, None):
            problems.append("%s missing" % attr)
    if theme.KEY and theme.KEY not in ORDER:
        problems.append("KEY %r is not a Directory.BaseThemes key %s" % (theme.KEY, ORDER))
    if theme.NAME and not (theme.NAME[:1].isalpha() and theme.NAME.isascii() and theme.NAME.replace("_", "").isalnum()):
        problems.append("NAME %r must be CamelCase letters / digits" % theme.NAME)
    for role, lk in theme.PALETTE.items():
        if not isinstance(lk, C.Look):
            problems.append("PALETTE[%r] is not a look(...)" % role)
            continue
        if not (role[:1].isalpha() and role.isascii() and role.replace("_", "").isalnum()):
            problems.append("role %r: a letter first, then letters, digits and _ only" % role)
        fam = C.family_of(role)
        if fam is None:
            problems.append("role %r: name it <Family>_<Colour> with Family in %s" % (role, ", ".join(C.FAMILY_ORDER)))
        elif lk.material not in C.FAMILIES[fam]["materials"]:
            problems.append("role %r: family %s maps to %s, not %s" % (role, fam, "/".join(C.FAMILIES[fam]["materials"]), lk.material))
        if role.lower().startswith("backdrop"):
            problems.append("role %r: backdrops are gone (owner 2026-09-24); a landmark theme names its roles by family" % role)
        if lk.material in C.BANNED_MATERIALS:
            problems.append("role %r: %s" % (role, C.BANNED_MATERIALS[lk.material]))
    if getattr(type(theme), "landmark", None) is not getattr(C.PenTheme, "landmark") and theme.KEY not in C.LANDMARK_KEYS:
        problems.append("landmark(): only %s have a landmark (owner 2026-09-25); %s keeps its plot open"
                        % ("/".join(C.LANDMARK_KEYS), theme.KEY))
    if theme.TRI_STRETCH:
        if theme.KEY not in C.LANDMARK_KEYS:
            problems.append("TRI_STRETCH: only a landmark theme may stretch the %d-tri budget" % C.TRI_MAX)
        if theme.TRI_STRETCH > C.TRI_STRETCH_MAX:
            problems.append("TRI_STRETCH %d > %d (the owner's hard ceiling)" % (theme.TRI_STRETCH, C.TRI_STRETCH_MAX))
        if not theme.TRI_STRETCH_REASON:
            problems.append("TRI_STRETCH needs a TRI_STRETCH_REASON (why the landmark truly needs it)")
    for role in (C.FLOOR_ROLE, C.SCREEN_ROLE):
        if role not in theme.PALETTE:
            problems.append("PALETTE needs the anchor role %r" % role)
    for name in C.OWN_MODULES:
        if getattr(type(theme), name, None) is getattr(C.PenTheme, name):
            problems.append("%s(): every theme models its own perimeter / gate / emblem (no shared fence)" % name)
    # one layout per key: the build loader (post_zz_base_themes Step.findLayout) reads the first v3 JSON by name
    if check_layouts and theme.KEY in ORDER:
        for data, path in theme_layouts(theme.KEY, legacy=True):
            if data.get("name") != theme.NAME:
                problems.append("%s is another %s layout (NAME %r): delete it (and its .fbx / .blend / .rbxm / previews) or "
                                "keep NAME %r" % (rel(path), theme.KEY, data.get("name"), data.get("name")))
    return problems


def build_theme(theme, obstacles=None):
    builders, problems = {}, {}
    for vname, prefix, D in C.VARIANTS:
        B = C.Builder(theme, vname, prefix, D)
        theme.build(B)
        builders[vname] = B
        problems[vname] = B.check(obstacles)
    return builders, problems


# ----------------------------------------------------------------------------------------------------------------------
# Blender objects / materials
# ----------------------------------------------------------------------------------------------------------------------

def srgb_to_linear(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def lin(rgb):
    return (srgb_to_linear(rgb[0]), srgb_to_linear(rgb[1]), srgb_to_linear(rgb[2]), 1.0)


def _set(sock_owner, name, value):
    sock = sock_owner.inputs.get(name)
    if sock is not None:
        try:
            sock.default_value = value
        except (TypeError, ValueError):
            pass


def material_for(theme, role):
    """Preview material: premium toy plastic (glossy SmoothPlastic with a clear coat, satin Plastic, Glass). Nothing
    emits (no Neon since 2026-09-25). Roblox gets the same colour / material from the palette, never these node trees."""
    name = "%s_%s" % (theme.NAME, role)
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
    lk = theme.PALETTE[role]
    mat = bpy.data.materials.new(name)
    col = lin(lk.rgb)
    mat.diffuse_color = col
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        _set(bsdf, "Base Color", col)
        rough = {"SmoothPlastic": 0.26, "Plastic": 0.5}.get(lk.material, 0.4)
        rough = max(0.08, rough - 0.5 * lk.reflectance)
        _set(bsdf, "Roughness", rough)
        _set(bsdf, "Metallic", min(0.35, lk.reflectance))
        _set(bsdf, "Specular IOR Level", 0.55)
        floor = (C.family_of(role) == "Floor")
        if floor:
            _set(bsdf, "Roughness", max(rough, 0.46))
        if lk.material == "SmoothPlastic":
            _set(bsdf, "Coat Weight", 0.08 if floor else 0.35)
            _set(bsdf, "Coat Roughness", 0.12)
        if lk.material == "Glass":
            _set(bsdf, "Metallic", 0.0)
            _set(bsdf, "Roughness", 0.12)
            _set(bsdf, "IOR", 1.45)
            _set(bsdf, "Transmission Weight", 0.82)
            _set(bsdf, "Coat Weight", 0.0)
            if hasattr(mat, "use_raytrace_refraction"):
                mat.use_raytrace_refraction = True
        if lk.transparency > 0 and lk.material != "Glass":
            _set(bsdf, "Alpha", max(0.3, 1.0 - lk.transparency))
            try:
                mat.surface_render_method = "BLENDED"
            except AttributeError:
                pass
    return mat


def plain_material(name, rgb, rough=0.5, emission=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    col = lin(rgb)
    mat.diffuse_color = col
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    _set(bsdf, "Base Color", col)
    _set(bsdf, "Roughness", rough)
    if emission:
        _set(bsdf, "Emission Color", col)
        _set(bsdf, "Emission Strength", emission)
    return mat


def _uv_project(bm):
    uv = bm.loops.layers.uv.get("UVMap") or bm.loops.layers.uv.new("UVMap")
    bm.normal_update()
    for f in bm.faces:
        n = f.normal
        ax = max(range(3), key=lambda k: abs(n[k]))
        for loop in f.loops:
            co = loop.vert.co
            a, b = (co.y, co.z) if ax == 0 else (co.x, co.z) if ax == 1 else (co.x, co.y)
            loop[uv].uv = (a / UV_STUDS, b / UV_STUDS)


def family_collection(root, prefix, family):
    name = "%s%s" % (prefix, family)
    coll = bpy.data.collections.get(name)
    if coll is None:
        coll = bpy.data.collections.new(name)
        root.children.link(coll)
    return coll


def add_modifiers(obj, width, segs):
    """The craft stack: Bevel (ANGLE 35 deg, clamp overlap) when width > 0, then Weighted Normal (face area, keep
    sharp), then Triangulate (the export's exact triangles, concave caps included)."""
    if width > 0:
        bv = obj.modifiers.new("Bevel", "BEVEL")
        bv.width = width
        bv.segments = max(1, min(2, segs))
        bv.limit_method = "ANGLE"
        bv.angle_limit = math.radians(C.BEVEL_ANGLE)
        bv.use_clamp_overlap = True
        bv.offset_type = "OFFSET"
        bv.profile = 0.5 if segs <= 1 else 0.7
        bv.harden_normals = False
        bv.miter_outer = "MITER_ARC" if segs > 1 else "MITER_SHARP"
    wn = obj.modifiers.new("WeightedNormal", "WEIGHTED_NORMAL")
    wn.mode = "FACE_AREA"
    wn.weight = 50
    wn.keep_sharp = True
    tri = obj.modifiers.new("Triangulate", "TRIANGULATE")
    tri.quad_method = "BEAUTY"
    tri.ngon_method = "BEAUTY"
    if hasattr(tri, "keep_custom_normals"):
        tri.keep_custom_normals = True


def scene_objects(theme, B, root=None, offset=(0.0, 0.0, 0.0), consume=True):
    """One object per (role, bevel class) of builder B with its live modifier stack, in <prefix><Family> collections
    under `root` (default: the scene collection). Returns [(role, obj)]. Consumes B.acc unless consume=False."""
    root = root or bpy.context.scene.collection
    out = []
    counts = {}
    for key in sorted(B.acc, key=lambda k: (k[0], -k[1], k[2], k[3])):
        role, width, segs, smooth = key
        bm = B.acc[key] if consume else B.acc[key].copy()
        _uv_project(bm)
        n = counts.get(role, 0)
        counts[role] = n + 1
        name = B.prefix + role + ("" if n == 0 else ".b%d" % n)
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        bm.free()
        mesh.shade_smooth()
        if not smooth:
            mesh.set_sharp_from_angle(angle=math.radians(C.BEVEL_ANGLE))
        mesh.materials.append(material_for(theme, role))
        obj = bpy.data.objects.new(name, mesh)
        obj.location = offset
        obj["role"] = role
        obj["bevel"] = width
        obj["segments"] = segs
        obj["smooth"] = smooth
        family_collection(root, B.prefix, C.family_of(role) or "Other").objects.link(obj)
        add_modifiers(obj, width, segs)
        out.append((role, obj))
    if consume:
        B.acc = {}
    return out


def flatten(theme, B, objs, root=None):
    """Joins each role's objects into ONE mesh with the modifiers applied (custom normals kept). Returns {role: obj}."""
    root = root or bpy.context.scene.collection
    dg = bpy.context.evaluated_depsgraph_get()
    by_role = {}
    for role, obj in objs:
        me = bpy.data.meshes.new_from_object(obj.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
        flat = bpy.data.objects.new(obj.name + "__flat", me)
        flat.location = obj.location
        root.objects.link(flat)
        by_role.setdefault(role, []).append(flat)
    out = {}
    for role, parts in by_role.items():
        if len(parts) > 1:
            with bpy.context.temp_override(active_object=parts[0], object=parts[0], selected_objects=parts,
                                           selected_editable_objects=parts):
                bpy.ops.object.join()
        obj = parts[0]
        obj.name = B.prefix + role
        obj.data.name = B.prefix + role
        obj.data.materials.clear()
        obj.data.materials.append(material_for(theme, role))
        out[role] = obj
    return out


def dry_run(theme, builders):
    """{variant: (total tris, {role: tris})} without writing anything (the live stacks evaluated, then discarded)."""
    out = {}
    for vname, _, _ in C.VARIANTS:
        clear_scene()
        objs = scene_objects(theme, builders[vname], consume=False)
        flat = flatten(theme, builders[vname], objs)
        tris = {role: mesh_stats(obj)[0] for role, obj in flat.items()}
        out[vname] = (sum(tris.values()), tris)
    clear_scene()
    return out


def mesh_stats(obj):
    me = obj.data
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    if not me.vertices:
        return tris, None
    xs = [v.co.x + obj.location.x for v in me.vertices]
    ys = [v.co.y + obj.location.y for v in me.vertices]
    zs = [v.co.z + obj.location.z for v in me.vertices]
    return tris, ([min(xs), min(ys), min(zs)], [max(xs), max(ys), max(zs)])


def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for coll in list(bpy.data.collections):
        bpy.data.collections.remove(coll)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras, bpy.data.curves,
                  bpy.data.images):
        for item in list(block):
            block.remove(item)


def remove_objects(objs):
    for obj in objs:
        if obj and obj.name in bpy.data.objects:
            data = obj.data
            bpy.data.objects.remove(obj, do_unlink=True)
            if isinstance(data, bpy.types.Mesh) and data.users == 0:
                bpy.data.meshes.remove(data)


# ----------------------------------------------------------------------------------------------------------------------
# export: one FBX with both variants + the .blend with the live stacks + the layout JSON
# ----------------------------------------------------------------------------------------------------------------------

def r3(v):
    return [round(c, 3) for c in v]


def export_theme(theme, builders, problems, renders=None):
    """Builds every variant's objects (live stacks), saves <NAME>.blend, flattens, exports <NAME>.fbx and writes
    <NAME>.json. Returns (fbx, json, blend, layout, tris {variant: total})."""
    out_dir = os.path.join(BASES_DIR, theme.KEY)
    os.makedirs(out_dir, exist_ok=True)
    if not renders:  # --no-render: keep listing the previews already on disk
        renders = [p for p in (os.path.join(out_dir, "preview", "%s_%s.png" % (theme.NAME, shot))
                               for shot in SHOTS + LANDMARK_SHOTS) if os.path.isfile(p)]
    clear_scene()
    scene = bpy.context.scene
    live = {}
    for vname, prefix, D in C.VARIANTS:
        B = builders[vname]
        root = bpy.data.collections.new("%s_%s" % (theme.NAME, vname))
        scene.collection.children.link(root)
        live[vname] = (root, scene_objects(theme, B, root))
        # the Deep variant sits beside the Std one in the .blend (the FBX keeps both at the origin)
    blend_path = os.path.join(out_dir, theme.NAME + ".blend")
    # the .blend: both variants side by side with their live modifier stacks (nothing else in it)
    shift = 2 * C.W + 20
    for role, obj in live["Deep"][1]:
        obj.location.x += shift
    try:
        bpy.context.preferences.filepaths.save_version = 0  # no <NAME>.blend1 backups next to the asset
    except AttributeError:
        pass
    bpy.ops.wm.save_as_mainfile(filepath=blend_path, compress=True, copy=True)
    for role, obj in live["Deep"][1]:
        obj.location.x -= shift
    layout = {
        "format": C.FORMAT,
        "key": theme.KEY,
        "name": theme.NAME,
        "title": theme.TITLE,
        "franchise": theme.FRANCHISE,
        "fbx": theme.NAME + ".fbx",
        "blend": theme.NAME + ".blend",
        "import": theme.NAME + ".rbxm",
        "generated_by": "scripts/tools/blender/base_themes/run.py (themes/%s.py)" % theme.KEY.lower(),
        "units": "1 Blender unit = 1 stud; pen frame x = v (right, looking out of the gate), y = u (toward the gate), z = h",
        "anchors": {"floor": C.FLOOR_ROLE, "screen": C.SCREEN_ROLE},
        "families": list(C.FAMILY_ORDER),
        "policy": {"neon": False, "lights": False, "note": "owner 2026-09-25: no Neon, no glow lights in the bases"},
        "craft": {"bevel_limit": "ANGLE", "bevel_angle_deg": C.BEVEL_ANGLE, "weighted_normal": "FACE_AREA keep_sharp",
                  "shading": "smooth + sharp above %g deg" % C.BEVEL_ANGLE},
        "contract": {
            "half_width": C.W, "inset": C.INSET, "floor_top": C.FLOOR_TOP, "floor_detail_top": C.FLOOR_DETAIL_TOP,
            "gate_half": C.GATE_V,
            "gate_clear": {"half_v": C.GATE_CLEAR_V, "height": C.GATE_CLEAR_H, "u_from_front": list(C.GATE_CLEAR_U)},
            "sign": {"v": list(C.SIGN_V), "h": list(C.SIGN_H), "u_from_front": list(C.SIGN_U),
                     "screen_v": list(C.SIGN_SCREEN_V), "screen_h": list(C.SIGN_SCREEN_H)},
            "zone": {"front": C.FRONT_MAX, "side": C.SIDE_MAX, "back": C.BACK_REACH, "top": C.TOP_MAX,
                     "corner_reach": C.CORNER_REACH},
            "budget": {"min": C.TRI_MIN, "max": theme.tri_max()},
        },
        "palette": {role: {"rgb": list(lk.rgb), "material": lk.material, "transparency": lk.transparency,
                           "reflectance": lk.reflectance, "family": C.family_of(role)}
                    for role, lk in theme.PALETTE.items()},
        "variant_order": [v[0] for v in C.VARIANTS],
        "variants": {},
        "renders": [rel(r) for r in (renders or [])],
    }
    has_landmark = any(builders[v[0]].landmark_bounds() for v in C.VARIANTS)
    if has_landmark:
        # the landmark zone (the loader places and checks landmark pieces, tagged "landmark", against it)
        layout["contract"]["landmark"] = {"near": C.LANDMARK_NEAR, "back": C.LANDMARK_BACK, "side": C.LANDMARK_SIDE,
                                          "top": C.LANDMARK_TOP, "camera_gap": C.CAMERA_GAP, "camera_h": C.CAMERA_H}
    if theme.TRI_STRETCH:
        layout["contract"]["budget"]["stretch_reason"] = theme.TRI_STRETCH_REASON
    tri_max = theme.tri_max()
    obstacles = load_obstacles()
    export_objs, totals = [], {}
    for vname, prefix, D in C.VARIANTS:
        B = builders[vname]
        flat = flatten(theme, B, live[vname][1])
        tris, bounds = {}, {}
        for role, obj in sorted(flat.items()):
            n, bb = mesh_stats(obj)
            tris[role] = n
            if bb:
                bounds[role] = [r3(bb[0]), r3(bb[1])]
        total = sum(tris.values())
        totals[vname] = total
        if total > tri_max:
            problems[vname].append("%d tris > budget %d" % (total, tri_max))
        if total < C.TRI_MIN:
            problems[vname].append("%d tris < the %d minimum (under-detailed)" % (total, C.TRI_MIN))
        # every modelled primitive's box; a landmark piece carries a 4th field "landmark" (its own zone in the loader)
        pieces = []
        for i, (role, mn, mx, _) in enumerate(B.pieces):
            entry = [role, r3(mn), r3(mx)]
            if B.zone_of(i) == C.ZONE_LANDMARK:
                entry.append(C.ZONE_LANDMARK)
            pieces.append(entry)
        lb = B.landmark_bounds()
        fits = {}
        for plot in obstacles or []:
            if abs(plot["half_depth"] - D) < 0.5:
                bad = [p for p in problems[vname] if p.startswith("plot %s:" % plot["plot"])]
                fits[plot["plot"]] = "fits" if not bad else bad[0]
        # "problems" = contract / budget problems: the build loader rejects the whole variant on any. A clash with one
        # real plot's obstacles (plot_obstacles.json, possibly older than the world) only goes to "plot_problems": the
        # loader re-checks every plot against the live world and keeps the procedural theme where the pen does not fit.
        plot_tags = tuple("plot %s:" % plot["plot"] for plot in obstacles or [])
        per_plot = [p for p in problems[vname] if plot_tags and p.startswith(plot_tags)]
        layout["variants"][vname] = {
            "prefix": prefix, "half_depth": D, "half_width": C.W, "footprint": [2 * C.W, 2 * D],
            "tris": tris, "total_tris": total, "objects": len(flat),
            "object_bounds": bounds, "pieces": pieces,
            "lights": [],  # no lights in the bases (owner 2026-09-25)
            "landmark": ({"bounds": [r3(lb[0]), r3(lb[1])],
                          "pieces": sum(1 for i in range(len(B.pieces)) if B.zone_of(i) == C.ZONE_LANDMARK)} if lb else None),
            "camera_warnings": B.camera_warnings(),
            "plots": fits, "problems": [p for p in problems[vname] if p not in per_plot],
            "plot_problems": per_plot,
        }
        export_objs += list(flat.values())
    path = os.path.join(out_dir, theme.NAME + ".fbx")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in export_objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = export_objs[0]
    bpy.ops.export_scene.fbx(
        filepath=path, use_selection=True, object_types={"MESH"}, apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="-Z", axis_up="Y", use_mesh_modifiers=False,
        mesh_smooth_type="OFF", use_triangles=True, add_leaf_bones=False, bake_anim=False, path_mode="AUTO",
        use_custom_props=False)
    json_path = os.path.join(out_dir, theme.NAME + ".json")
    previous = None
    if os.path.isfile(json_path):
        try:
            with open(json_path, encoding="utf-8") as fh:
                previous = json.load(fh)
        except (OSError, ValueError):
            previous = None
    layout["geometry_fingerprint"] = geometry_fingerprint(layout)
    layout["geometry_note"] = ("geometry only (object bounds, tris, every piece): a palette / light change keeps it and the "
                               "owner's Studio import stays valid; any other change means re-import %s.fbx" % theme.NAME)
    if previous and previous.get("variants") and previous.get("format") == C.FORMAT:
        try:
            before = geometry_fingerprint(previous)
        except (KeyError, TypeError, ValueError, IndexError):
            before = None
        layout["geometry_changed"] = before != layout["geometry_fingerprint"]
        print("[base_themes] %s geometry %s (%s -> %s)%s" % (
            theme.KEY, "CHANGED: the owner must re-import %s.fbx" % theme.NAME if layout["geometry_changed"] else "unchanged",
            before, layout["geometry_fingerprint"], "" if layout["geometry_changed"] else ": the Studio import stays valid"))
    with open(json_path, "w", encoding="utf-8") as fh:
        json.dump(layout, fh, indent=1)
    clear_scene()
    return path, json_path, blend_path, layout, totals


def _f3(x):
    return "%.3f" % (float(x) + 0.0)


def geometry_fingerprint(layout):
    """The geometry id of a layout: sha1 over every variant's prefix, depth, footprint, per-role object bounds and tris
    and every piece box (%.3f), nothing else (palette, lights, renders, plots and problems do not count). The build
    loader (post_zz_base_themes Step.geometryFingerprint) computes the same string from the JSON; the Studio helper
    stamps it on the import (attribute GeometryFingerprint) and the build ignores an import whose stamp differs."""
    lines = [FINGERPRINT_FORMAT]
    for vname in layout["variant_order"]:
        v = layout["variants"][vname]
        lines.append("variant %s %s %s %s %s" % (vname, v["prefix"], _f3(v["half_depth"]), _f3(v["footprint"][0]),
                                                 _f3(v["footprint"][1])))
        for role in sorted(v["object_bounds"]):
            b = v["object_bounds"][role]
            lines.append("bounds %s %s" % (role, " ".join(_f3(x) for x in list(b[0]) + list(b[1]))))
        for role in sorted(v["tris"]):
            lines.append("tris %s %d" % (role, int(v["tris"][role])))
        for p in v["pieces"]:
            tail = (" " + str(p[3])) if len(p) > 3 else ""
            lines.append("piece %s %s%s" % (p[0], " ".join(_f3(x) for x in list(p[1]) + list(p[2])), tail))
    return "g1:" + hashlib.sha1("\n".join(lines).encode("utf-8")).hexdigest()[:24]


# ----------------------------------------------------------------------------------------------------------------------
# renders: EEVEE, 50 mm, 3-point studio light on a seamless studio floor
# ----------------------------------------------------------------------------------------------------------------------

def solid(name, rgb, center, size, emission=0.0, collection=None, rough=0.5):
    bm = C.bm_box(size[0], size[1], size[2])
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(plain_material(name, rgb, rough, emission))
    obj = bpy.data.objects.new(name, mesh)
    (collection or bpy.context.scene.collection).objects.link(obj)
    obj.location = center
    bv = obj.modifiers.new("Bevel", "BEVEL")
    bv.width = min(0.08, 0.2 * min(size))
    bv.segments = 2
    return obj


def figure(prefix, x, y, colors, scale=1.0, collection=None):
    """A blocky 5-stud player / hero stand-in."""
    legs, torso, head = colors
    s = scale
    return [solid(prefix + "Legs", legs, (x, y, 1.0 * s), (1.9 * s, 0.95 * s, 2.0 * s), collection=collection),
            solid(prefix + "Torso", torso, (x, y, 3.0 * s), (1.9 * s, 0.95 * s, 2.0 * s), collection=collection),
            solid(prefix + "Head", head, (x, y, 4.6 * s), (1.1 * s, 1.1 * s, 1.1 * s), collection=collection)]


def preview_props(theme, D, collection=None, figures=True):
    """Render-only context: the plot's upgrade sign inside the terminal, a player and two heroes for scale."""
    extra = []
    sv, su, sh = C.SIGN_V, (D + C.SIGN_U[0], D + C.SIGN_U[1]), C.SIGN_H
    extra.append(solid("Preview_UpgradeSign", (26, 34, 58), ((sv[0] + sv[1]) / 2, (su[0] + su[1]) / 2, (sh[0] + sh[1]) / 2),
                       (sv[1] - sv[0], su[1] - su[0], sh[1] - sh[0]), collection=collection))
    extra.append(solid("Preview_SignScreen", (40, 70, 130), ((sv[0] + sv[1]) / 2, su[1] + 0.02, (sh[0] + sh[1]) / 2),
                       (C.SIGN_SCREEN_V[1] - C.SIGN_SCREEN_V[0], 0.04, C.SIGN_SCREEN_H[1] - C.SIGN_SCREEN_H[0]), 0.6,
                       collection=collection))
    extra.append(solid("Preview_SignText", (255, 214, 92), ((sv[0] + sv[1]) / 2, su[1] + 0.05, (sh[0] + sh[1]) / 2 + 0.55),
                       (3.4, 0.04, 0.62), 2.0, collection=collection))
    extra.append(solid("Preview_SignSupport", (40, 44, 58), (10.5, D + 1.44, 0.82), (1.0, 1.0, 1.64), collection=collection))
    extra.append(solid("Preview_SignPlinth", (40, 44, 58), (10.5, D + 1.44, 0.18), (1.9, 1.9, 0.36), collection=collection))
    if figures:
        extra += figure("Preview_Player", -1.4, D + 6.5, ((40, 70, 160), (220, 70, 60), (245, 205, 70)), collection=collection)
        for i, (x, y, cols) in enumerate(((-9.5, 5.0, ((60, 60, 70), (230, 200, 40), (240, 190, 150))),
                                          (10.0, -8.0, ((30, 30, 120), (60, 150, 230), (240, 190, 150))))):
            extra += figure("Preview_Hero%d" % i, x, y, cols, 1.2, collection=collection)
    for name, rgb, center, size in theme.preview_extras():
        extra.append(solid("Preview_" + name, rgb, center, size, collection=collection))
    return extra


def look_at(obj, target):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def _try(obj, attr, val):
    try:
        setattr(obj, attr, val)
        return True
    except (AttributeError, TypeError, ValueError):
        return False


def setup_studio(width=1600, height=900, studio_rgb=(208, 214, 224), floor=True):
    """World, 3-point lights (key / fill / rim suns), studio floor, EEVEE settings, bloom, a 50 mm camera."""
    scene = bpy.context.scene
    world = bpy.data.worlds.get("World") or bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs["Color"].default_value = lin((196, 204, 218))
        bg.inputs["Strength"].default_value = 0.3
    lights = []
    # 3-point: key from the front-left above (warm), fill from the front-right low (cool, no shadow), rim from behind
    for name, energy, rgb, toward_light, angle in (
            ("Key", 5.2, (255, 242, 224), (-0.62, 0.55, 0.72), 3.0),
            ("Fill", 0.9, (200, 220, 255), (0.9, 0.42, 0.3), 14.0),
            ("Rim", 3.2, (236, 244, 255), (0.3, -1.0, 0.55), 2.5)):
        rot = (-Vector(toward_light).normalized()).to_track_quat("-Z", "Y").to_euler()
        data = bpy.data.lights.new(name, "SUN")
        data.energy = energy
        data.color = tuple(lin(rgb)[:3])
        data.angle = math.radians(angle)
        if name != "Key":
            _try(data, "use_shadow", False)
        obj = bpy.data.objects.new(name, data)
        obj.rotation_euler = rot
        scene.collection.objects.link(obj)
        lights.append(obj)
    if floor:
        ground = solid("Studio_Floor", studio_rgb, (0.0, 0.0, -0.26), (900.0, 900.0, 0.5), rough=0.8)
        ground.modifiers.clear()
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    ee = scene.eevee
    for attr, val in (("taa_render_samples", 48), ("use_shadows", True), ("use_raytracing", True),
                      ("shadow_ray_count", 2), ("shadow_step_count", 8), ("use_fast_gi", True),
                      ("fast_gi_distance", 6.0), ("fast_gi_resolution", "2")):
        _try(ee, attr, val)
    # Khronos PBR Neutral keeps the toy colours faithful (AgX turns saturated crimson orange); fallback AgX
    names = [v.identifier for v in scene.view_settings.bl_rna.properties["view_transform"].enum_items]
    for vt in ("Khronos PBR Neutral", "AgX", "Filmic"):
        if vt in names:
            scene.view_settings.view_transform = vt
            break
    scene.view_settings.look = "None"
    scene.view_settings.exposure = VIEW_EXPOSURE
    scene.render.resolution_x, scene.render.resolution_y = width, height
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    # no bloom: nothing in a base glows any more (owner 2026-09-25: no Neon, no lights)
    scene.use_nodes = False
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = LENS
    cam_data.sensor_width = 36.0
    cam_data.clip_end = 3000.0
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def fit_camera(cam, box_min, box_max, direction, width, height, margin=0.06):
    """Places the 50 mm camera looking along `direction` so the box fills the frame (with a margin), centred."""
    corners = [Vector((x, y, z)) for x in (box_min[0], box_max[0]) for y in (box_min[1], box_max[1])
               for z in (box_min[2], box_max[2])]
    d = Vector(direction).normalized()
    target = sum(corners, Vector()) / 8
    quat = d.to_track_quat("-Z", "Y")
    rot = quat.to_matrix()
    right, up = rot @ Vector((1, 0, 0)), rot @ Vector((0, 1, 0))
    fx = (cam.data.sensor_width / 2) / cam.data.lens  # tan of the half field of view (horizontal)
    fy = fx * height / width
    dist = 80.0
    for _ in range(60):
        pos = target - d * dist
        xs, ys = [], []
        for c in corners:
            v = c - pos
            depth = max(v.dot(d), 1e-3)
            xs.append(v.dot(right) / depth / fx)
            ys.append(v.dot(up) / depth / fy)
        cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
        target = target + right * (cx * fx * dist * 0.8) + up * (cy * fy * dist * 0.8)
        ext = max((max(xs) - min(xs)) / 2, (max(ys) - min(ys)) / 2)
        dist *= 0.5 + 0.5 * ext / (1.0 - margin)
    cam.location = target - d * dist
    cam.rotation_euler = quat.to_euler()
    cam.data.type = "PERSP"
    return cam.location.copy()


def render_to(path, width, height):
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = width, height
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def add_theme_lights(B, offset=(0.0, 0.0, 0.0), collection=None):
    """The theme's own point lights in the preview: none since 2026-09-25 (B.lights is always empty)."""
    out = []
    for i, l in enumerate(B.lights):
        data = bpy.data.lights.new("PenLight%d" % i, "POINT")
        data.energy = 90.0 * l[4]
        data.color = tuple(lin(l[5])[:3])
        data.shadow_soft_size = 0.4
        _try(data, "use_shadow", False)
        obj = bpy.data.objects.new(data.name, data)
        obj.location = (l[0] + offset[0], l[1] + offset[1], l[2] + offset[2])
        (collection or bpy.context.scene.collection).objects.link(obj)
        out.append(obj)
    return out


# shot look directions (camera -> subject); the hero one is the coherence camera, identical for every theme
HERO_DIR = (0.46, -0.69, -0.56)    # from the front-left, 34 degrees up: gate, terminal and the whole pen
GATE_DIR = (-0.42, -1.0, -0.36)    # from the front-right at player height: the entrance and the terminal
DETAIL_DIR = (0.62, -1.0, -0.5)    # the front-left corner, a post and the barrier up close


LANDMARK_DIR = (0.2, -1.0, -0.3)    # from the front-right over the gate: the pen with its landmark behind it


def playercam_frame(D):
    """Roblox's default camera for a player standing at the back of the pen (u = -D + 1.6, v 0) looking at the gate:
    12.5 studs behind the head (h 4.5), pitched 20 degrees down. Returns (camera position, look target)."""
    head = Vector((0.0, -D + 1.6, 4.5))
    pitch = math.radians(20.0)
    cam = head + Vector((0.0, -math.cos(pitch) * ROBLOX_ZOOM, math.sin(pitch) * ROBLOX_ZOOM))
    return cam, head


def render_theme(theme, B, objs=None):
    """Renders the Std variant (live modifier stacks) with the preview props: hero (the coherence camera), gate
    (entrance + terminal), detail (corner, post, barrier close-up), top (orthographic contract view); a theme with a
    landmark also gets landmark (the pen and the building from the front) and playercam (Roblox's default camera of a
    player at the back of the pen: the landmark must not swallow it)."""
    prev_dir = os.path.join(BASES_DIR, theme.KEY, "preview")
    os.makedirs(prev_dir, exist_ok=True)
    for old in LEGACY_SHOTS:  # shots of the pre-v3 renderer
        path = os.path.join(prev_dir, "%s_%s.png" % (theme.NAME, old))
        if os.path.isfile(path):
            os.remove(path)
    clear_scene()
    if objs is None:
        objs = scene_objects(theme, B, consume=False)
    D, Wd = B.D, B.W
    lb = B.landmark_bounds()
    preview_props(theme, D)
    add_theme_lights(B)
    cam = setup_studio(studio_rgb=theme.STUDIO_RGB)
    written = []
    hero_mn, hero_mx = [-Wd - 1.5, -D - 1.5, 0.0], [Wd + 1.5, D + 7.5, 7.0]
    if lb:  # the hero shot keeps its camera direction and takes the landmark in
        hero_mn = [min(hero_mn[0], lb[0][0]), min(hero_mn[1], lb[0][1]), 0.0]
        hero_mx = [max(hero_mx[0], lb[1][0]), hero_mx[1], max(hero_mx[2], lb[1][2])]
    shots = [
        ("hero", (hero_mn, hero_mx), HERO_DIR, 0.04),
        ("gate", ((-8.0, D - 5.0, 0.0), (15.5, D + 3.0, C.TOP_MAX + 0.4)), GATE_DIR, 0.05),
        ("detail", ((-Wd - 1.4, D - 12.0, 0.0), (-Wd + 12.0, D + 1.4, 9.0)), DETAIL_DIR, 0.03),
    ]
    if lb:
        shots.append(("landmark", ((min(-Wd - 1.5, lb[0][0]), lb[0][1], 0.0), (max(Wd + 1.5, lb[1][0]), D + 3.0, lb[1][2])),
                      LANDMARK_DIR, 0.04))
    for name, (mn, mx), direction, margin in shots:
        fit_camera(cam, mn, mx, direction, 1600, 900, margin)
        path = os.path.join(prev_dir, "%s_%s.png" % (theme.NAME, name))
        render_to(path, 1600, 900)
        written.append(path)
    if lb:
        # the player's own view from the back of the pen (Roblox FieldOfView 70 vertical, 12.5-stud zoom), player drawn
        extra = figure("Preview_BackPlayer", 0.0, -D + 1.6, ((40, 70, 160), (220, 70, 60), (245, 205, 70)))
        pos, target = playercam_frame(D)
        cam.data.type = "PERSP"
        cam.data.sensor_fit = "VERTICAL"
        cam.data.angle = math.radians(ROBLOX_FOV)
        cam.location = pos
        look_at(cam, target)
        path = os.path.join(prev_dir, "%s_playercam.png" % theme.NAME)
        render_to(path, 1600, 900)
        written.append(path)
        remove_objects(extra)
        cam.data.sensor_fit = "AUTO"
        cam.data.lens = LENS
    # top: orthographic, the whole plot zone (+ the landmark)
    cam.data.type = "ORTHO"
    u0, u1 = -D - 6.0, D + 6.0
    if lb:
        u0 = min(u0, lb[0][1] - 2.0)
    cam.data.ortho_scale = max(u1 - u0, 2 * Wd + 12)
    cam.location = (0.0, (u0 + u1) / 2, 120.0)
    cam.rotation_euler = (0.0, 0.0, 0.0)
    path = os.path.join(prev_dir, "%s_top.png" % theme.NAME)
    render_to(path, 1100, 1100)
    written.append(path)
    if not lb:  # a theme that lost its landmark: no stale landmark shots next to the new ones
        for shot in LANDMARK_SHOTS:
            old = os.path.join(prev_dir, "%s_%s.png" % (theme.NAME, shot))
            if os.path.isfile(old):
                os.remove(old)
    clear_scene()
    return written


# ----------------------------------------------------------------------------------------------------------------------
# the coherence sheet: every v3 theme's hero shot (same camera, same light) in a 3 x 2 grid with labels
# ----------------------------------------------------------------------------------------------------------------------

def _text(body, size, rgb, location, align="CENTER", emission=1.0, collection=None):
    curve = bpy.data.curves.new("Label", "FONT")
    curve.body = body
    curve.size = size
    curve.align_x = align
    curve.align_y = "CENTER"
    for path in ("C:/Windows/Fonts/impact.ttf", "C:/Windows/Fonts/arialbd.ttf"):
        if os.path.isfile(path):
            try:
                curve.font = bpy.data.fonts.load(path, check_existing=True)
                break
            except RuntimeError:
                pass
    obj = bpy.data.objects.new("Label", curve)
    (collection or bpy.context.scene.collection).objects.link(obj)
    mat = bpy.data.materials.new("LabelMat")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = lin(rgb)
    em.inputs["Strength"].default_value = emission
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    curve.materials.append(mat)
    obj.location = location
    return obj


def _image_plane(name, path, center, w, h):
    img = bpy.data.images.load(path, check_existing=False)
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    vs = [bm.verts.new((center[0] + x * w / 2, center[1] + y * h / 2, 0.0)) for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    f = bm.faces.new(vs)
    uv = bm.loops.layers.uv.new("UVMap")
    for loop, co in zip(f.loops, ((0, 0), (1, 0), (1, 1), (0, 1))):
        loop[uv].uv = co
    bm.to_mesh(mesh)
    bm.free()
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Cubic"
    em = nt.nodes.new("ShaderNodeEmission")
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(tex.outputs["Color"], em.inputs["Color"])
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _flat_plane(name, rgb, center, w, h, z=-0.01):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    vs = [bm.verts.new((center[0] + x * w / 2, center[1] + y * h / 2, z)) for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    bm.faces.new(vs)
    bm.to_mesh(mesh)
    bm.free()
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = lin(rgb)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def coherence_sheet(out_path=None):
    """assets/models/bases/preview/_coherence.png: the hero shot of every v3 theme (Directory order; a slot without a
    v3 theme says so), 3 x 2, labelled, composed in an emission-only Blender scene (colours pass through unchanged)."""
    out_path = out_path or os.path.join(SHEET_DIR, "_coherence.png")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    clear_scene()
    scene = bpy.context.scene
    world = bpy.data.worlds.get("World") or bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = lin((16, 18, 26))
    tw, th, gap, label_h, head_h = 16.0, 9.0, 0.5, 1.5, 2.2
    sheet_w = 3 * tw + 4 * gap
    sheet_h = head_h + 2 * (th + label_h) + 3 * gap
    found = []
    by_key = {data["key"]: (data, path) for data, path in theme_layouts()}
    for i, key in enumerate(ORDER):
        col, row = i % 3, i // 3
        cx = -sheet_w / 2 + gap + tw / 2 + col * (tw + gap)
        top = sheet_h / 2 - head_h - gap - row * (th + label_h + gap)
        cy = top - th / 2
        entry = by_key.get(key)
        hero = None
        if entry:
            hero = os.path.join(BASES_DIR, key, "preview", entry[0]["name"] + "_hero.png")
            if not os.path.isfile(hero):
                hero = None
        if hero:
            _image_plane("Tile_" + key, hero, (cx, cy), tw, th)
            data = entry[0]
            _text(str(data["title"]).upper(), 0.62, (255, 255, 255), (cx, top - th - 0.55, 0.01))
            tris = [data["variants"][v].get("total_tris", 0) for v in data["variant_order"]]
            _text("%s  |  %s  |  %s tris" % (str(data.get("franchise") or "").upper(), key.upper(),
                                              " / ".join(str(t) for t in tris)), 0.36, (170, 184, 210), (cx, top - th - 1.15, 0.01))
            found.append(key)
        else:
            _flat_plane("Tile_" + key, (34, 38, 50), (cx, cy), tw, th)
            _text(key.upper(), 0.9, (120, 130, 150), (cx, cy + 0.5, 0.01))
            _text("pending: rebuild on the v3 theme API", 0.4, (120, 130, 150), (cx, cy - 0.6, 0.01))
            _text(key.upper(), 0.62, (120, 130, 150), (cx, top - th - 0.55, 0.01))
    _text("STEAL A HERO  -  PLAYER BASES  (one silhouette per stage, same studio light and camera)", 0.62, (255, 255, 255),
          (0.0, sheet_h / 2 - head_h / 2 - 0.1, 0.01))
    cam_data = bpy.data.cameras.new("SheetCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = sheet_w
    cam = bpy.data.objects.new("SheetCam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = (0.0, 0.0, 10.0)
    scene.camera = cam
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    _try(scene.eevee, "taa_render_samples", 16)
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0.0
    scene.use_nodes = False
    px_w = 2400
    render_to(out_path, px_w, int(round(px_w * sheet_h / sheet_w / 2)) * 2)
    clear_scene()
    return found


# ----------------------------------------------------------------------------------------------------------------------
# the Studio helper (generated from every theme JSON)
# ----------------------------------------------------------------------------------------------------------------------

def theme_layouts(only_key=None, legacy=False):
    """[(layout, path)] of every v3 theme JSON on disk (Directory order, then by file name); legacy=True adds the old
    v2 layouts (made before the 2026-09-24 art direction; the build ignores them)."""
    formats = (C.FORMAT,) + (C.LEGACY_FORMATS if legacy else ())
    out = []
    for key in ORDER:
        d = os.path.join(BASES_DIR, key)
        if (only_key and key != only_key) or not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            if name.endswith(".json"):
                path = os.path.join(d, name)
                try:
                    with open(path, encoding="utf-8") as fh:
                        data = json.load(fh)
                except (OSError, ValueError):
                    continue
                if isinstance(data, dict) and data.get("format") in formats:
                    out.append((data, path))
    return out


HELPER_HEAD = """-- assets/models/bases/BaseThemesImport.lua  -  Studio command bar helper for the Blender-modelled base themes.
-- GENERATED by scripts/tools/blender/base_themes/run.py from every assets/models/bases/<Key>/<Name>.json (do not edit).
--
-- 1. Studio: Avatar (or Home) > Import 3D > assets/models/bases/<Key>/<Name>.fbx (one per theme; each file holds both
--    pen variants, "Std_*" and "Deep_*" parts, overlapping at the origin). Keep the importer defaults; any scale /
--    position / yaw is fine (the build normalises them from the floor and the terminal). Import as many themes as
--    you like before step 2.
-- 2. Paste this whole file into the command bar (View > Command Bar) and press Enter. It finds the imported models
--    (the selection, else every Workspace model), recognises each theme by its model name (else by its part names),
--    applies the palette (one colour + material per material family mesh: Structure_* / Floor_* / Core_3D_* /
--    Neon_Emissive_* = the accent colours, NOT emissive: no Neon and no lights in the bases, owner 2026-09-25),
--    anchors the parts, turns collisions / queries / touches off, removes any light, stamps the theme's geometry
--    fingerprint (attribute GeometryFingerprint: the build uses the import only while the layout's geometry is the
--    one you imported; after a geometry change it logs "re-import <Name>.fbx") and moves each model to
--    ServerStorage.BaseThemeImports.<Key> as <Name>.
-- 3. Save the place (Ctrl+S on StealaHero.rbxl: the next build extracts ServerStorage.BaseThemeImports to
--    assets/models/bases/<Key>/<Name>.rbxm before it overwrites the file), or right-click each model > Save to
--    File... as assets/models/bases/<Key>/<Name>.rbxm. Rebuild: every plot where a pen fits gets it
--    (scripts/steps/post_zz_base_themes.luau, section 4).
-- Themes marked legacy = true come from the old (v2) layouts made before the 2026-09-24 art direction: the build
-- ignores them until their theme is rebuilt on the v3 API (the helper still files them, and says so).
"""

HELPER_BODY = """
local ServerStorage = game:GetService("ServerStorage")
local Selection = game:GetService("Selection")

local function norm(s)
	return (string.gsub(string.lower(s), "[^%w]", ""))
end

-- the theme role of a part name: variant prefix stripped, the longest palette role it contains
local function roleOf(theme, name)
	local rest = name
	for _, prefix in ipairs(theme.prefixes) do
		if string.lower(string.sub(name, 1, #prefix)) == string.lower(prefix) then
			rest = string.sub(name, #prefix + 1)
			break
		end
	end
	local best
	for role in pairs(theme.palette) do
		if string.find(string.lower(rest), string.lower(role), 1, true) and (best == nil or #role > #best) then
			best = role
		end
	end
	return best
end

local function hasPrefix(theme, name)
	for _, prefix in ipairs(theme.prefixes) do
		if string.lower(string.sub(name, 1, #prefix)) == string.lower(prefix) then
			return true
		end
	end
	return false
end

-- the theme of an imported model: by its name ("StarkLab", "StarkLab.fbx", ...; the longest theme name it contains), else
-- by its parts (the theme whose own roles, not the shared anchors, name the most "Std_*" / "Deep_*" parts); nil for
-- anything that is not an import
local function detect(model)
	local key = norm(model.Name)
	local named, best, bestScore = nil, nil, 0
	for _, theme in ipairs(THEMES) do
		local score, prefixed = 0, 0
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and hasPrefix(theme, d.Name) then
				prefixed += 1
				local role = roleOf(theme, d.Name)
				if role and not theme.anchors[role] then
					score += 1
				end
			end
		end
		if prefixed > 0 and string.find(key, norm(theme.name), 1, true) and (named == nil or #theme.name > #named.name) then
			named = theme
		end
		if score > bestScore then
			best, bestScore = theme, score
		end
	end
	if named then
		return named
	end
	return if bestScore >= 3 then best else nil
end

local picked = Selection:Get()
local candidates = {}
for _, inst in ipairs(if #picked > 0 then picked else workspace:GetChildren()) do
	if inst:IsA("Model") and not inst:FindFirstChildOfClass("Humanoid") then
		local theme = detect(inst)
		if theme then
			table.insert(candidates, { inst, theme })
		end
	end
end
if #candidates == 0 then
	warn("[BaseThemesImport] no imported base theme found: select the imported model(s) (or leave them in Workspace) and run again")
	return
end

local imports = ServerStorage:FindFirstChild("BaseThemeImports") or Instance.new("Folder")
imports.Name = "BaseThemeImports"
imports.Parent = ServerStorage
for _, entry in ipairs(candidates) do
	local model, theme = entry[1], entry[2]
	local folder = imports:FindFirstChild(theme.key) or Instance.new("Folder")
	folder.Name = theme.key
	folder.Parent = imports
	local styled, unknown, perPrefix = 0, 0, {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("SurfaceAppearance") or d:IsA("Light") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			local role = roleOf(theme, d.Name)
			local look = role and theme.palette[role]
			if look then
				d.Color = Color3.fromRGB(look[1], look[2], look[3])
				d.Material = Enum.Material[look[4]] -- SmoothPlastic / Plastic / Glass only: no neon in a base (2026-09-25)
				d.Transparency = look[5]
				d.Reflectance = look[6]
				d.CastShadow = look[5] < 0.5
				styled += 1
				for _, prefix in ipairs(theme.prefixes) do
					if string.lower(string.sub(d.Name, 1, #prefix)) == string.lower(prefix) then
						perPrefix[prefix] = (perPrefix[prefix] or 0) + 1
					end
				end
			else
				unknown += 1
			end
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	local old = folder:FindFirstChild(theme.name)
	if old and old ~= model then
		old:Destroy()
	end
	model.Name = theme.name
	model:SetAttribute("GeometryFingerprint", theme.fingerprint)
	model:SetAttribute("ImportedFrom", theme.name .. ".fbx")
	model.Parent = folder
	local counts = {}
	for _, prefix in ipairs(theme.prefixes) do
		table.insert(counts, string.format("%s%d", prefix, perPrefix[prefix] or 0))
	end
	print(string.format("[BaseThemesImport] %s (%s) -> ServerStorage.BaseThemeImports.%s.%s: %d parts styled (%s), %d unknown, geometry %s",
		theme.title, theme.key, theme.key, theme.name, styled, table.concat(counts, " "), unknown, theme.fingerprint))
	if theme.legacy then
		warn(string.format("[BaseThemesImport] %s is a LEGACY (v2) layout: the build ignores it until themes/%s.py is rebuilt on the v3 API",
			theme.name, string.lower(theme.key)))
	end
end
print("[BaseThemesImport] done: save the place (Ctrl+S) or Save to File each model as assets/models/bases/<Key>/<Name>.rbxm, then rebuild")
"""


def write_studio_helper():
    layouts = [data for data, _ in theme_layouts(legacy=True)]
    lines = [HELPER_HEAD, "local THEMES = {"]
    for data in layouts:
        prefixes = ", ".join('"%s"' % data["variants"][v]["prefix"] for v in data["variant_order"])
        title = str(data["title"]).replace("\\", "\\\\").replace('"', '\\"')
        anchors = data.get("anchors") or {"floor": "Base_Floor", "screen": "Sign_Screen"}
        legacy = data.get("format") != C.FORMAT
        try:
            fingerprint = data.get("geometry_fingerprint") or geometry_fingerprint(data)
        except (KeyError, TypeError, ValueError, IndexError):
            fingerprint = ""
        lines.append('\t{ key = "%s", name = "%s", title = "%s", legacy = %s, prefixes = { %s }, fingerprint = "%s",'
                     % (data["key"], data["name"], title, "true" if legacy else "false", prefixes, fingerprint))
        lines.append('\t\tanchors = { %s = true, %s = true }, palette = {' % (anchors["floor"], anchors["screen"]))
        for role in sorted(data["palette"]):
            p = data["palette"][role]
            material = "SmoothPlastic" if p["material"] in C.BANNED_MATERIALS else p["material"]  # never Neon
            lines.append('\t\t%s = { %d, %d, %d, "%s", %s, %s },' % (role, p["rgb"][0], p["rgb"][1], p["rgb"][2], material,
                                                                    fmt_num(p["transparency"]), fmt_num(p["reflectance"])))
        lines.append("\t} },")
    lines.append("}")
    text = "\n".join(lines) + "\n" + HELPER_BODY
    path = os.path.join(BASES_DIR, "BaseThemesImport.lua")
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    return path, [d["key"] + ("" if d.get("format") == C.FORMAT else " (legacy)") for d in layouts]


def fmt_num(x):
    return ("%g" % x) if x else "0"


# ----------------------------------------------------------------------------------------------------------------------
# view mode (Blender window, nothing written)
# ----------------------------------------------------------------------------------------------------------------------

def view(themes):
    clear_scene()
    scene = bpy.context.scene
    row = 0.0
    for theme in themes:
        builders, _ = build_theme(theme)
        col = 0.0
        for vname, prefix, D in C.VARIANTS:
            coll = bpy.data.collections.new("%s_%s" % (theme.NAME, vname))
            scene.collection.children.link(coll)
            objs = [o for _, o in scene_objects(theme, builders[vname], coll, (col, row, 0.0))]
            props = preview_props(theme, D, coll)
            for obj in props:
                obj.location.x += col
                obj.location.y += row
            col += 2 * C.W + 30
        row -= 2 * 31.5 + 40
    setup_studio(floor=True)
    scene.unit_settings.system = "NONE"

    def setup_view():
        for window in bpy.context.window_manager.windows:
            for area in window.screen.areas:
                if area.type != "VIEW_3D":
                    continue
                space = area.spaces.active
                space.shading.type = "MATERIAL"
                space.clip_end = 4000
                region = next((r for r in area.regions if r.type == "WINDOW"), None)
                if region:
                    with bpy.context.temp_override(window=window, area=area, region=region):
                        bpy.ops.view3d.view_all()
        return None

    bpy.app.timers.register(setup_view, first_interval=0.6)
