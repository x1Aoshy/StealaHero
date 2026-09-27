# scripts/tools/blender/hero_eggs/export_parts.py
# Converts the voxel Hero Eggs kit (audit/generate_voxel_eggs_bpy.py, the generator of assets/eggs/fbx/*.fbx) into
# plain Roblox Part lists, so the build can make every egg offline with Lune (an FBX needs Studio's 3D importer).
#
#   "C:/Program Files/Blender Foundation/Blender 4.5/blender.exe" -b --factory-startup \
#       --python scripts/tools/blender/hero_eggs/export_parts.py [-- --only Luffy,Zoro] [-- --preview]
#
# It re-runs the generator's own Builder (same shell, accessories and costume finish, same front-plate mounting), but
# records every primitive instead of only its faces:
#   box / spike -> one Part (optional roll around the front axis)      beam / line -> one Part along a->b
#   vox / pixel / disk -> the voxel cells merged into the fewest boxes (hidden cells are wildcards)
# then applies the generator's final normalisation (ground origin, total height 3.2 * boss scale).
# Output: assets/eggs/egg_parts.json, in Roblox space: X = -x, Y = z, Z = y (the Blender front -Y becomes -Z, the
# model's LookVector), rotations R = P * R_blender * P^T. The micro-bevel and the stud normal map are replaced in
# Roblox by the game's "Studs" material look (scripts/steps/post_hero_eggs.luau).
# --preview also renders assets/eggs/parts_preview/<Hero>.png from the Part list (cubes), to compare with previews/.

import importlib.util
import json
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
GEN_PATH = os.path.join(ROOT, "audit", "generate_voxel_eggs_bpy.py")
OUT_PATH = os.path.join(ROOT, "assets", "eggs", "egg_parts.json")
PREVIEW_DIR = os.path.join(ROOT, "assets", "eggs", "parts_preview")

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ONLY = None
PREVIEW = "--preview" in ARGV
if "--only" in ARGV:
    ONLY = set(ARGV[ARGV.index("--only") + 1].split(","))

spec = importlib.util.spec_from_file_location("hero_egg_gen", GEN_PATH)
G = importlib.util.module_from_spec(spec)
spec.loader.exec_module(G)  # defines Builder / shell / accessories / costume_finish; main() is not run

EPS = 1e-6
IDENTITY = ((1, 0, 0), (0, 1, 0), (0, 0, 1))


def rot_y(angle):
    co, si = math.cos(angle), math.sin(angle)
    # the generator's box(): x' = x + vx*co + vz*si ; z' = z - vx*si + vz*co
    return ((co, 0, si), (0, 1, 0), (-si, 0, co))


def merge_cells(cells):
    """Greedy 3D box merge per colour. Visible cells must be covered exactly once by a box of their colour; hidden
    cells (all 6 neighbours present) are wildcards that any box may cross. Returns [(color, lo(i,j,k), hi(i,j,k))]."""
    hidden = set()
    for (i, j, k) in cells:
        if all(n in cells for n in ((i + 1, j, k), (i - 1, j, k), (i, j + 1, k), (i, j - 1, k), (i, j, k + 1), (i, j, k - 1))):
            hidden.add((i, j, k))
    covered = set()
    boxes = []

    def ok(c, color):
        if c not in cells:
            return False
        if c in hidden:
            return True
        return cells[c] == color and c not in covered

    # seeds in a stable order (bottom-up, then front-to-back, left-to-right) so rebuilds are deterministic
    for seed in sorted((c for c in cells if c not in hidden), key=lambda c: (c[2], c[1], c[0])):
        if seed in covered:
            continue
        color = cells[seed]
        i0, j0, k0 = seed
        i1 = i0
        while ok((i1 + 1, j0, k0), color):
            i1 += 1
        j1 = j0
        while all(ok((i, j1 + 1, k0), color) for i in range(i0, i1 + 1)):
            j1 += 1
        k1 = k0
        while all(ok((i, j, k1 + 1), color) for i in range(i0, i1 + 1) for j in range(j0, j1 + 1)):
            k1 += 1
        # trim wildcard-only borders: a box never ends on a slab made only of hidden cells
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                for k in range(k0, k1 + 1):
                    if (i, j, k) not in hidden:
                        covered.add((i, j, k))
        boxes.append((color, (i0, j0, k0), (i1 + 1, j1 + 1, k1 + 1)))
    return boxes


class Recorder:
    def __init__(self):
        self.prims = []  # (color, center Vector, size (sx,sy,sz), rotation 3x3 tuple)
        self.scale = None  # (axis, pivot, factor) applied to vox boxes (pixel depth / disk height)


def install(builder):
    rec = Recorder()
    builder._rec = rec
    return rec


ORIG_BOX = G.Builder.box
ORIG_BEAM = G.Builder.beam
ORIG_VOX = G.Builder.vox
ORIG_PIXEL = G.Builder.pixel
ORIG_DISK = G.Builder.disk


def box(self, p, size, color, rotation=0):
    x, y, z = p
    if rotation == 0:
        y = self.mount_y(x, y, z, size[1])
        self._rec.prims.append((color, Vector((x, y, z)), tuple(size), IDENTITY))
    else:
        self._rec.prims.append((color, Vector((x, y, z)), tuple(size), rot_y(rotation)))
    ORIG_BOX(self, p, size, color, rotation)


def beam(self, a, b, width, color, depth=None, _mount=True):
    a, b = Vector(a), Vector(b)
    if _mount and width < .36 and max(a.y, b.y) < -.75 and max(abs(a.x), abs(b.x)) < .96 and min(a.z, b.z) > .50 and max(a.z, b.z) < 2.74:
        count = max(1, math.ceil((b - a).length / .12))
        if count > 1:
            points = [a.lerp(b, i / count) for i in range(count + 1)]
            for pt in points:
                pt.y = self.mount_y(pt.x, pt.y, pt.z, depth or width)
            for pt, qt in zip(points, points[1:]):
                self.beam(pt, qt, width, color, depth, _mount=False)
            return
        a.y = self.mount_y(a.x, a.y, a.z, depth or width)
        b.y = self.mount_y(b.x, b.y, b.z, depth or width)
    delta = b - a
    if delta.length > EPS:
        m = delta.to_track_quat('Z', 'Y').to_matrix()
        rows = tuple(tuple(m[r][c] for c in range(3)) for r in range(3))
        self._rec.prims.append((color, (a + b) / 2, (width, depth or width, delta.length), rows))
    ORIG_BEAM(self, a, b, width, color, depth, _mount=False)


def vox(self, cells, step, origin=(0, 0, 0)):
    ox, oy, oz = origin
    sc = self._rec.scale
    for color, lo, hi in merge_cells(cells):
        mn = [lo[0] * step + ox, lo[1] * step + oy, lo[2] * step + oz]
        mx = [hi[0] * step + ox, hi[1] * step + oy, hi[2] * step + oz]
        if sc:
            axis, pivot, f = sc
            mn[axis] = pivot + (mn[axis] - pivot) * f
            mx[axis] = pivot + (mx[axis] - pivot) * f
        center = Vector(((mn[0] + mx[0]) / 2, (mn[1] + mx[1]) / 2, (mn[2] + mx[2]) / 2))
        size = (mx[0] - mn[0], mx[1] - mn[1], mx[2] - mn[2])
        self._rec.prims.append((color, center, size, IDENTITY))
    ORIG_VOX(self, cells, step, origin)


def pixel(self, rows, center, step, color, depth=.075, palette=None):
    x, y, z = center
    ym = self.mount_y(x, y, z, depth)
    self._rec.scale = (1, ym - depth / 2, depth / step)
    try:
        ORIG_PIXEL(self, rows, center, step, color, depth, palette)
    finally:
        self._rec.scale = None


def disk(self, x, y, z, rx, ry, height, color, step=.12):
    self._rec.scale = (2, z - height / 2, height / step)
    try:
        ORIG_DISK(self, x, y, z, rx, ry, height, color, step)
    finally:
        self._rec.scale = None


G.Builder.box = box
G.Builder.beam = beam
G.Builder.vox = vox
G.Builder.pixel = pixel
G.Builder.disk = disk

# Blender (x, y, z) -> Roblox (-x, z, y): right-handed, Blender front -Y -> Roblox -Z.
P = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))
PT = P.transposed()


def r4(v):
    return round(v, 4)


def build(hero, scale):
    b = G.Builder(hero)
    rec = install(b)
    G.shell(b, hero)
    G.accessories(b, hero)
    G.costume_finish(b, hero)
    zmin = min(v[2] for v in b.verts)
    zmax = max(v[2] for v in b.verts)
    factor = 3.2 * scale / (zmax - zmin)
    parts = []
    for color, center, size, rot in rec.prims:
        if min(size) <= EPS:
            continue
        c = Vector((center.x, center.y, center.z - zmin)) * factor
        s = [v * factor for v in size]
        rb = Matrix(rot)
        rr = P @ rb @ PT
        pos = P @ c
        parts.append([
            color,
            r4(pos.x), r4(pos.y), r4(pos.z),
            r4(s[0]), r4(s[2]), r4(s[1]),
            r4(rr[0][0]), r4(rr[0][1]), r4(rr[0][2]),
            r4(rr[1][0]), r4(rr[1][1]), r4(rr[1][2]),
            r4(rr[2][0]), r4(rr[2][1]), r4(rr[2][2]),
        ])
    return parts, b.features


def preview(hero, parts):
    # Rebuild the Part list as cubes in Blender space (inverse mapping) and render it like the kit's previews.
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    scene = bpy.context.scene
    mats = {}
    for part in parts:
        color = part[0]
        if color not in mats:
            m = bpy.data.materials.new("P_" + color)
            hx = G.COLORS[color]
            m.diffuse_color = (*[G.linear(int(hx[i:i + 2], 16)) for i in (0, 2, 4)], 1)
            m.use_nodes = True
            bsdf = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
            bsdf.inputs['Base Color'].default_value = m.diffuse_color
            if color.startswith(('glow', 'gem')):
                bsdf.inputs['Emission Color'].default_value = m.diffuse_color
                bsdf.inputs['Emission Strength'].default_value = 2.0
            mats[color] = m
        px, py, pz, sx, sy, sz = part[1:7]
        rr = Matrix((part[7:10], part[10:13], part[13:16]))
        rb = PT @ rr @ P
        pos = PT @ Vector((px, py, pz))
        bpy.ops.mesh.primitive_cube_add(size=1)
        o = bpy.context.active_object
        o.scale = (sx, sz, sy)  # Roblox size (X, Y, Z) -> Blender local (x, z, y)
        o.matrix_world = Matrix.Translation(pos) @ rb.to_4x4() @ Matrix.Diagonal((sx, sz, sy, 1))
        o.data.materials.append(mats[color])
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    cam.data.type = 'ORTHO'
    scene.camera = cam
    for name, loc, energy in [('Key', (-4, -6, 8), 700), ('Fill', (5, -2, 5), 450), ('Rim', (1, 5, 7), 900)]:
        d = bpy.data.lights.new(name, 'AREA')
        d.energy = energy
        d.size = 5
        lo = bpy.data.objects.new(name, d)
        scene.collection.objects.link(lo)
        lo.location = loc
        lo.rotation_euler = (Vector((0, 0, 1.5)) - lo.location).to_track_quat('-Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    pts = [o.matrix_world @ Vector(c) for o in scene.objects if o.type == 'MESH' for c in o.bound_box]
    lo = Vector(tuple(min(p[i] for p in pts) for i in range(3)))
    hi = Vector(tuple(max(p[i] for p in pts) for i in range(3)))
    target = (lo + hi) / 2
    cam.location = target + Vector((4.3, -10.5, 5.0))
    cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
    cam.data.ortho_scale = max((hi.z - lo.z) * 1.23, (hi.x - lo.x) * 1.40)
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
    scene.render.resolution_x = 450
    scene.render.resolution_y = 510
    scene.render.film_transparent = True
    scene.render.filepath = os.path.join(PREVIEW_DIR, hero + ".png")
    bpy.ops.render.render(write_still=True)


def main():
    out = {}
    if os.path.isfile(OUT_PATH) and ONLY:
        with open(OUT_PATH, "r", encoding="ascii") as f:
            out = json.load(f).get("eggs", {})
    total = 0
    for hero, stage, rarity, scale in G.ROSTER:
        if ONLY and hero not in ONLY:
            continue
        parts, features = build(hero, scale)
        total += len(parts)
        out[hero] = {"stage": stage, "rarity": rarity, "bossScale": scale, "height": round(3.2 * scale, 4),
                     "features": features, "parts": parts}
        print("EGG", hero, len(parts), "parts", flush=True)
        if PREVIEW:
            os.makedirs(PREVIEW_DIR, exist_ok=True)
            preview(hero, parts)
    colors = {k: v for k, v in G.COLORS.items()}
    doc = {
        "schema": 1,
        "generator": "scripts/tools/blender/hero_eggs/export_parts.py (from audit/generate_voxel_eggs_bpy.py)",
        "space": "Roblox studs; origin = ground centre; front = -Z; part = [color, px,py,pz, sx,sy,sz, R00..R22]",
        "colors": colors,
        "neon": sorted(k for k in colors if k.startswith(("glow", "gem"))),
        "eggs": {k: out[k] for k in sorted(out)},
    }
    with open(OUT_PATH, "w", encoding="ascii") as f:
        json.dump(doc, f, separators=(",", ":"))
    print("COMPLETE", len(out), "eggs", total, "parts ->", OUT_PATH, flush=True)


main()
