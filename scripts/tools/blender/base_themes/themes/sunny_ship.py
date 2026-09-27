"""The Thousand Sunny crowning the Sunny Pirate Wharf gate (v2, THEME3_Volcano_Sunny 2026-09-25).

Remodelled from the owner's reference (a premium toy Thousand Sunny on two wooden cradles on a short wharf): a round
clinker-planked walnut hull, the red bulwark with the thick cream scroll frame around the lawn waist (volutes curling at
both ends), gold-rimmed black portholes, the sun-lion figurehead (orange petal mane, round yellow face, cream muzzle,
crossed bones) in front of the red bow shield, the tall cream main sail with the Straw Hat Jolly Roger in 3D relief on
BOTH faces, the red / white striped aft sail, the striped crow's nest, the domed red / yellow aft cabin, the balustrades,
the lawn, a round tree, a lantern, rope ladders and two black Jolly Roger flags. Real geometry only (lofts, sweeps,
lathes), shared bevel / weighted-normal craft, no textures, no subdivision.

Local frame = the gate's ship origin, pen (0, D + 0.88, 8.30) (post_zz_base_themes.luau pins it): bow -X, starboard +Y
(the street side), Z up. Envelope: y -1.46 .. 1.48 (u D-0.62 .. D+2.4 with room for the wind swing), z >= -0.8,
z <= 7.62 (world <= 15.92). The figurehead turns toward the street so the lion reads from outside the plot.
Animated groups (the "_Sunny<Group>_" role names; SunnyWind.luau pivots):
    Hull  hull, figurehead, masts, cabin, rigging    Main  the Straw Hat main sail + yard (swings about MAIN_PIVOT)
    Aft   the striped aft sail + yard + aft flag     Flag  the main mast flag (yaws about the main mast)
"""
import math

import bmesh
from mathutils import Vector

from common import *

# -- roles (one Roblox MeshPart each) ------------------------------------------------------------------------------------
PLANK = "Structure_SunnyHull_Plank"      # walnut hull planks, decks, rudder, doors
RED = "Structure_SunnyHull_Red"          # bulwark, bow shield, dome gores, crow's nest stripes
CREAM = "Core_3D_SunnyHull_Ivory"        # scroll trims, cap rails, bones, balustrades, muzzle, cabin
GOLD = "Core_3D_SunnyHull_Gold"          # porthole rims, studs, the lion's face, dome gores
ORANGE = "Core_3D_SunnyHull_Orange"      # the sun mane
INK = "Core_3D_SunnyHull_Wood"           # porthole glass, eyes, nose, smile, windows, lantern cage
MAST = "Structure_SunnyHull_Wood"        # masts, crow's nest floor, tree trunk, lantern arm
ROPE = "Structure_SunnyHull_Rope"        # rope ladders, stays, sheets
GRASS = "Structure_SunnyHull_Grass"      # the lawn deck, the round tree
M_SAIL = "Core_3D_SunnyMain_Sail"        # the main sail cloth
M_WHITE = "Core_3D_SunnyMain_Ivory"      # skull + bones
M_INK = "Core_3D_SunnyMain_Wood"         # outlines, eyes, nose, teeth
M_HAT = "Core_3D_SunnyMain_Gold"         # the straw hat
M_BAND = "Structure_SunnyMain_Red"       # its red band
M_YARD = "Structure_SunnyMain_Wood"      # the main yard
A_RED = "Structure_SunnyAft_Red"
A_WHITE = "Core_3D_SunnyAft_Ivory"       # stripes + the aft flag's skull
A_YARD = "Structure_SunnyAft_Wood"
A_INK = "Core_3D_SunnyAft_Wood"          # the aft flag
F_INK = "Core_3D_SunnyFlag_Wood"         # the main flag
F_WHITE = "Core_3D_SunnyFlag_Ivory"
LANTERN = "Neon_Emissive_Lantern"        # the base's (static) lantern glass: the hull swell is < 0.03 studs

PALETTE = {
    PLANK: look((116, 68, 40), "SmoothPlastic", bevel=0),
    RED: look((198, 44, 42), "SmoothPlastic", bevel=0),
    CREAM: look((244, 234, 210), "SmoothPlastic", bevel=0),
    GOLD: look((255, 208, 64), "SmoothPlastic", reflectance=0.03, bevel=0),
    ORANGE: look((240, 122, 36), "SmoothPlastic", bevel=0),
    INK: look((34, 30, 32), "SmoothPlastic", bevel=0),
    MAST: look((104, 64, 40), "SmoothPlastic", bevel=0),
    ROPE: look((176, 132, 84), "Plastic", bevel=0),
    GRASS: look((96, 168, 72), "SmoothPlastic", bevel=0),
    M_SAIL: look((236, 224, 196), "Plastic", bevel=0),
    M_WHITE: look((252, 251, 247), "SmoothPlastic", bevel=0),
    M_INK: look((30, 28, 30), "SmoothPlastic", bevel=0),
    M_HAT: look((248, 200, 74), "SmoothPlastic", bevel=0),
    M_BAND: look((206, 40, 40), "SmoothPlastic", bevel=0),
    M_YARD: look((104, 64, 40), "SmoothPlastic", bevel=0),
    A_RED: look((200, 44, 42), "Plastic", bevel=0),
    A_WHITE: look((246, 240, 226), "Plastic", bevel=0),
    A_YARD: look((104, 64, 40), "SmoothPlastic", bevel=0),
    A_INK: look((30, 28, 30), "SmoothPlastic", bevel=0),
    F_INK: look((30, 28, 30), "SmoothPlastic", bevel=0),
    F_WHITE: look((250, 250, 248), "SmoothPlastic", bevel=0),
}


def add_palette(palette):
    for role, lk in PALETTE.items():
        palette.setdefault(role, lk)


# -- the hull: stations, keel line, beam, the red's lower edge (zb), the gunwale (G), the deck levels ---------------------
X_BOW, X_STERN, X_MID = -5.55, 6.15, 0.45
Z_KEEL = -0.24
EXP = 1.0          # section fullness (y = beam * sin(th) ** EXP): a round toy belly with firm shoulders
LIP = 0.08          # clinker plank lip
WAIST = (-1.98, 2.66)                       # the lawn waist between the bow volute and the stern volute
DECK = (2.62, 1.74, 2.74)                   # bow deck / lawn / stern castle deck tops
ZB = [(-5.55, 2.1), (-4.4, 1.96), (-3.1, 1.76), (-2.1, 1.58), (-1.3, 1.34), (0.4, 1.2), (2.0, 1.32), (2.9, 1.6),
      (4.5, 1.68), (6.15, 1.74)]
GW = [(-5.55, 3.42), (-4.4, 3.22), (-3.2, 3.04), (-2.12, 2.9), (-1.94, 2.3), (2.58, 2.3), (2.74, 2.96), (4.5, 3.0),
      (6.15, 3.04)]
HULL_X = [-5.55, -4.85, -3.85, -2.65, -1.25, 0.4, 2.0, 3.4, 4.6, 5.55, 6.15]
BW_X = [-5.55, -4.9, -4.1, -3.2, -2.4, -2.1, -1.92, -1.0, 0.3, 1.5, 2.45, 2.6, 2.76, 3.8, 4.8, 5.6, 6.15]
STRAKES = (0.26, 0.6, 0.94)                # plank lines (absolute heights at midship, rising with the sheer)

# the rig
MX, AX = -0.35, 3.95                        # main / aft mast x
MAIN = dict(xc=-0.35, w_top=4.4, w_bot=5.5, z0=2.98, h=3.52, y0=0.17, a=0.84, foot=0.32)
AFT = dict(xc=3.95, w_top=2.2, w_bot=2.5, z0=4.55, h=1.45, y0=0.13, a=0.32, foot=0.1)
MAIN_PIVOT = (MX, 0.0, 6.5)                 # the yard: SunnyWind.Pivots.Main = CFrame.new(MX, 6.5, 0)
AFT_PIVOT = (AX, 0.0, 6.05)                 # SunnyWind.Pivots.Aft = CFrame.new(AX, 6.05, 0)
FLAG_PIVOT = (MX, 0.0, 7.35)                # SunnyWind.Pivots.Flag = CFrame.new(MX, 7.35, 0)
MAST_TOP = 7.6

# the bow: the red shield and the lion (turned toward the street)
SHIELD = dict(x=-5.72, z=2.18, r=1.19, turn=math.radians(8.0))
LION = dict(x=-6.34, y=0.05, z=2.86, turn=math.radians(40.0))


def spline(tab, x):
    """Cubic Hermite through the keys (x, value): smooth sheer lines."""
    xs = [p[0] for p in tab]
    vs = [p[1] for p in tab]
    n = len(tab)
    if x <= xs[0]:
        return vs[0]
    if x >= xs[-1]:
        return vs[-1]
    i = max(k for k in range(n - 1) if xs[k] <= x)

    def m(k):
        if k == 0:
            return (vs[1] - vs[0]) / (xs[1] - xs[0])
        if k == n - 1:
            return (vs[-1] - vs[-2]) / (xs[-1] - xs[-2])
        return (vs[k + 1] - vs[k - 1]) / (xs[k + 1] - xs[k - 1])

    h = xs[i + 1] - xs[i]
    t = (x - xs[i]) / h
    t2, t3 = t * t, t * t * t
    return ((2 * t3 - 3 * t2 + 1) * vs[i] + (t3 - 2 * t2 + t) * h * m(i) + (-2 * t3 + 3 * t2) * vs[i + 1]
            + (t3 - t2) * h * m(i + 1))


def lerp(tab, x):
    if x <= tab[0][0]:
        return tab[0][1]
    for (x0, v0), (x1, v1) in zip(tab, tab[1:]):
        if x <= x1:
            return v0 + (v1 - v0) * (x - x0) / (x1 - x0)
    return tab[-1][1]


def _t(x):
    if x < X_MID:
        return (X_MID - x) / (X_MID - X_BOW), -1
    return (x - X_MID) / (X_STERN - X_MID), 1


def keel(x):
    t, s = _t(x)
    return Z_KEEL + (1.4 * t ** 1.7 if s < 0 else 1.02 * t ** 1.9)


def beam(x):
    t, s = _t(x)
    return 1.12 * (1.0 - (0.29 * t ** 2.4 if s < 0 else 0.2 * t ** 3.0))


def zb(x):
    return spline(ZB, x)


def gunwale(x):
    return lerp(GW, x)


def deck(x):
    return DECK[0] if x < WAIST[0] else (DECK[1] if x < WAIST[1] else DECK[2])


def sec(x, th):
    """Hull section point (y, z) at angle th (0 = keel, pi/2 = the red's lower edge) + its outward normal (ny, nz)."""
    b, k, top = beam(x), keel(x), zb(x)
    s, c = math.sin(th), math.cos(th)
    y = b * s ** EXP if s > 0 else 0.0
    z = top - (top - k) * c
    dy = b * EXP * (s ** (EXP - 1.0) if s > 1e-3 else 1e3) * c
    dz = (top - k) * s
    L = math.hypot(dy, dz) or 1.0
    return y, z, dz / L, -dy / L


def theta_at(x, z):
    k, top = keel(x), zb(x)
    return math.acos(max(-1.0, min(1.0, (top - z) / max(top - k, 1e-3))))


def surf_y(x, z):
    """The hull's (or the bulwark's) outer half-breadth at height z."""
    top = zb(x)
    if z <= top:
        return sec(x, theta_at(x, z))[0]
    g = max(gunwale(x), top + 0.05)
    return beam(x) - 0.05 * min(1.0, (z - top) / (g - top))


# -- bmesh helpers --------------------------------------------------------------------------------------------------------
def quad_rows(bm, rows, closed=False):
    """Faces between rows of verts: (r[i][j], r[i][j+1], r[i+1][j+1], r[i+1][j])."""
    for a, b in zip(rows, rows[1:]):
        n = len(a)
        for j in range(n if closed else n - 1):
            k = (j + 1) % n
            bm.faces.new((a[j], a[k], b[k], b[j]))


def sweep3d(prof, path, side, closed_prof=False, caps=(True, True), scale=None):
    """Profile [(p, q)] (ccw) swept along a 3D polyline: p along the `side` vector (per point or one Vector), q = t x p.
    Mitred at corners; scale = per-point (sp, sq) factors. Returns a bmesh with outward normals."""
    bm = bmesh.new()
    pts = [Vector(p) for p in path]
    n = len(pts)
    rows = []
    for i in range(n):
        t_in = (pts[i] - pts[i - 1]).normalized() if i > 0 else (pts[1] - pts[0]).normalized()
        t_out = (pts[i + 1] - pts[i]).normalized() if i < n - 1 else t_in
        t = (t_in + t_out)
        t = t.normalized() if t.length > 1e-6 else t_out
        miter = 1.0 / max(0.35, t.dot(t_out))
        a = Vector(side[i] if isinstance(side, (list, tuple)) and not isinstance(side[0], (int, float)) else side)
        a = (a - t * a.dot(t)).normalized()
        b = t.cross(a)
        sp, sq = scale[i] if scale else (1.0, 1.0)
        rows.append([bm.verts.new(pts[i] + a * (p * sp) + b * (q * sq * miter)) for p, q in prof])
    quad_rows(bm, rows, closed_prof)
    if caps[0]:
        bm.faces.new(list(reversed(rows[0])))
    if caps[1]:
        bm.faces.new(rows[-1])
    return bm


def band_prof(w, h, c=0.05, embed=0.03):
    """A flat band standing out of a surface (p outward), chamfered outer edges; the face on the surface is dropped."""
    return [(-embed, -h / 2), (w - c, -h / 2), (w, -h / 2 + c), (w, h / 2 - c), (w - c, h / 2), (-embed, h / 2)]


def lathe_seg(profile, a0, a1, n=1):
    """A lathe profile [(r, z)] revolved from angle a0 to a1 (n steps), open: a gore / panel."""
    bm = bmesh.new()
    rows = []
    for i in range(n + 1):
        a = a0 + (a1 - a0) * i / n
        ca, sa = math.cos(a), math.sin(a)
        rows.append([bm.verts.new((r * ca, r * sa, z)) for r, z in profile])
    # rows along the angle, columns up the profile: outward = (up) x (around)... fix by the first face
    for a, b in zip(rows, rows[1:]):
        for j in range(len(a) - 1):
            if a[j].co.xy.length < 1e-6 and a[j + 1].co.xy.length < 1e-6:
                continue
            vs = [a[j], b[j], b[j + 1], a[j + 1]]
            uniq = []
            for v in vs:
                if all((v.co - u.co).length > 1e-7 for u in uniq):
                    uniq.append(v)
            if len(uniq) >= 3:
                bm.faces.new(uniq)
    bm.normal_update()
    # outward: away from the axis
    for f in bm.faces:
        c = f.calc_center_median()
        if f.normal.dot(Vector((c.x, c.y, 0.0))) < 0 and Vector((c.x, c.y)).length > 1e-4:
            f.normal_flip()
    return bm


def ball(r, n=6, rings=3):
    """A smooth-shaded low ball (lathe): n sides, rings latitude bands."""
    prof = [(r * math.sin(math.pi * i / rings), -r * math.cos(math.pi * i / rings)) for i in range(rings + 1)]
    prof[0] = (0.0, -r)
    prof[-1] = (0.0, r)
    return bm_lathe(prof, n, 0.0)


def rect_band(w, h, embed=0.03):
    """A plain band standing out of a surface (p outward): 3 faces, the face on the surface dropped."""
    return [(-embed, -h / 2), (w, -h / 2), (w, h / 2), (-embed, h / 2)]


def rope_bm(a, b, r, n=4):
    """An open rope (n-sided tube, no caps) from a to b."""
    a, b = Vector(a), Vector(b)
    d = (b - a).normalized()
    ref = Vector((0.0, 0.0, 1.0)) if abs(d.z) < 0.9 else Vector((1.0, 0.0, 0.0))
    x = ref.cross(d).normalized()
    y = d.cross(x)
    bm = bmesh.new()
    rows = [[bm.verts.new(p + (x * math.cos(2 * math.pi * k / n + math.pi / 4) + y * math.sin(2 * math.pi * k / n + math.pi / 4)) * r)
             for k in range(n)] for p in (a, b)]
    quad_rows(bm, rows, closed=True)
    bm.normal_update()
    bm.faces.ensure_lookup_table()
    f = bm.faces[0]
    if f.normal.dot(f.calc_center_median() - (a + b) / 2) < 0:
        for f in bm.faces:
            f.normal_flip()
    return bm


# -- the hull --------------------------------------------------------------------------------------------------------------
def hull_ring(x):
    """Starboard half of the hull section at x, keel first: (y, z) points with the clinker lips."""
    b, k, top = beam(x), keel(x), zb(x)
    t, _ = _t(x)
    sheer = 0.16 * t * t
    zs = [z + sheer for z in STRAKES]
    # keep the lines inside the section, ordered, with at least 0.07 per plank
    hi = top - 0.12
    for i in reversed(range(len(zs))):
        zs[i] = min(zs[i], hi)
        hi = zs[i] - 0.07
    lo = k + 0.07
    for i in range(len(zs)):
        zs[i] = max(zs[i], lo)
        lo = zs[i] + 0.07
    ths = [theta_at(x, z) for z in zs]
    pts = [(0.0, k)]
    for f in (0.36, 0.7):
        y, z, ny, nz = sec(x, ths[0] * f)
        pts.append((y, z))
    for th in ths:
        y, z, ny, nz = sec(x, th)
        pts.append((y, z))
        pts.append((y + ny * LIP, z + nz * LIP))
    pts.append((b, top))
    return pts


def hull(B):
    bm = bmesh.new()
    rows = []
    for x in HULL_X:
        stb = hull_ring(x)
        ring = [(x, -y, z) for y, z in reversed(stb[1:])] + [(x, 0.0, stb[0][1])] + [(x, y, z) for y, z in stb[1:]]
        rows.append([bm.verts.new(p) for p in ring])
    quad_rows(bm, rows)
    for row, want in ((rows[0], -1.0), (rows[-1], 1.0)):
        f = bm.faces.new(row)
        f.normal_update()
        if f.normal.x * want < 0:
            f.normal_flip()
    B.mesh(PLANK, bm)
    # the rudder under the stern
    B.plate(PLANK, [(5.98, 0.5), (6.42, 0.58), (6.5, 1.46), (6.24, 1.6), (6.06, 1.5)], -0.07, 0.07, bevel=0)


def bulwark(B):
    """The red bulwark per side (outer + inner face; the cap rails cover its top), the stern transom, the decks."""
    for side in (1, -1):
        bm = bmesh.new()
        rows = []
        for x in BW_X:
            b, top, g = beam(x), zb(x), gunwale(x)
            d = deck(x) if not (WAIST[0] - 0.12 < x < WAIST[0] + 0.1) else DECK[1]
            if WAIST[1] - 0.1 < x < WAIST[1] + 0.12:
                d = DECK[1]
            pts = [(b, top - 0.02), (b - 0.05, g), (b - 0.26, g), (b - 0.26, min(d, g - 0.05))]
            rows.append([bm.verts.new((x, side * y, z)) for y, z in pts])
        for a, c in zip(rows, rows[1:]):
            for j in (0, 1, 2):
                vs = (a[j], a[j + 1], c[j + 1], c[j])
                bm.faces.new(vs if side > 0 else tuple(reversed(vs)))
        end = rows[0]
        bm.faces.new(tuple(reversed(end)) if side > 0 else tuple(end))
        B.mesh(RED, bm)
    # the stern transom (red) under the cap rail
    bs = beam(X_STERN)
    B.box(RED, (X_STERN - 0.03, 0.0, (zb(X_STERN) + gunwale(X_STERN)) / 2), (0.1, 2 * bs - 0.04,
          gunwale(X_STERN) - zb(X_STERN) + 0.02), bevel=0)
    # decks: the lawn in the waist, walnut decks fore and aft (top faces only: the bulwark hides their edges)
    def deck_face(role, x0, x1, z, n=5):
        xs = [x0 + (x1 - x0) * i / n for i in range(n + 1)]
        stb = [(x, beam(x) - 0.24) for x in xs]
        poly = stb + [(x, -y) for x, y in reversed(stb)]
        bm = bmesh.new()
        f = bm.faces.new([bm.verts.new((x, y, z)) for x, y in poly])
        f.normal_update()
        if f.normal.z < 0:
            f.normal_flip()
        B.mesh(role, bm)

    deck_face(GRASS, WAIST[0] - 0.02, WAIST[1] + 0.02, DECK[1], 5)
    deck_face(PLANK, X_BOW + 0.05, WAIST[0] + 0.02, DECK[0], 4)
    deck_face(PLANK, WAIST[1] - 0.02, X_STERN - 0.05, DECK[2], 4)
    # the walls facing the lawn: the bow deck's aft wall, the stern castle's front wall with two arched doors
    for x, z1, role in ((WAIST[0], DECK[0], PLANK), (WAIST[1], DECK[2], RED)):
        hw = beam(x) - 0.24
        B.box(role, (x, 0.0, (DECK[1] + z1) / 2), (0.08, 2 * hw, z1 - DECK[1]), bevel=0)
    door = [(-0.2, 0.0), (0.2, 0.0), (0.2, 0.46), (0.12, 0.6), (0.0, 0.64), (-0.12, 0.6), (-0.2, 0.46)]
    for y in (-0.5, 0.5):
        with B.frame(T(WAIST[1] - 0.04, y, DECK[1]) @ facing((-1.0, 0.0))):
            B.prism(PLANK, door, 0.0, 0.05, bevel=0)


# -- the cream scroll trims ------------------------------------------------------------------------------------------------
def spiral(cx, cz, r0, r1, a0, a1, n):
    """Points of a spiral in the XZ plane (angle in the XZ plane from +X toward +Z), radius r0 -> r1."""
    return [(cx + (r0 + (r1 - r0) * i / n) * math.cos(a0 + (a1 - a0) * i / n),
             cz + (r0 + (r1 - r0) * i / n) * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]


BOW_VOLUTE = (WAIST[0] + 0.5, 2.8, 0.5)     # centre x, z, radius (the band rises on its bow side)
STERN_VOLUTE = (WAIST[1] - 0.42, 2.62, 0.42)


def u_frame_path():
    """The waist's scroll frame (x, z): bow volute (inner end -> out), down the bow arm, the belly, up the stern arm,
    into the stern volute."""
    cx, cz, r = BOW_VOLUTE
    bow = spiral(cx, cz, r * 0.34, r, math.radians(-180.0), math.radians(180.0), 6)
    sx, sz, sr = STERN_VOLUTE
    stern = spiral(sx, sz, sr, sr * 0.34, 0.0, math.radians(360.0), 6)
    x0, x1 = cx - r, sx + sr
    belly = [(x0, 2.1), (x0 + 0.04, 1.84), (x0 + 0.16, 1.62), (x0 + 0.42, zb(x0 + 0.42) + 0.06), (-0.7, zb(-0.7)),
             (0.4, zb(0.4)), (1.4, zb(1.4)), (x1 - 0.42, zb(x1 - 0.42) + 0.06), (x1 - 0.16, 1.64), (x1 - 0.04, 1.84),
             (x1, 2.05)]
    pts = bow + belly + stern
    n_bow, n_stern = len(bow), len(stern)
    scale = [(1.0, 0.55 + 0.45 * i / (n_bow - 1)) for i in range(n_bow)] + [(1.0, 1.0)] * len(belly) + \
            [(1.0, 1.0 - 0.45 * i / (n_stern - 1)) for i in range(n_stern)]
    return pts, scale


def trims(B):
    for side in (1, -1):
        with B.frame(S(1.0, side, 1.0)):
            trims_side(B)
    stern_rails(B)


def trims_side(B):
    """Starboard trims (mirrored for port): the waist scroll frame with its volute cheeks, the bow's cap rail and lower
    band, the waist cap rail."""
    pts, scale = u_frame_path()
    path = [(x, surf_y(x, min(z, zb(x) + 0.8)) - 0.02, z) for x, z in pts]
    prof = [(-0.03, -0.16), (0.2, -0.16), (0.2, 0.1), (0.14, 0.16), (-0.03, 0.16)]
    B.mesh(CREAM, sweep3d(prof, path, (0.0, 1.0, 0.0), scale=scale), smooth=False)
    # the volutes' cheeks: cream discs the scrolls curl on (they also close the waist's steps)
    for cx, cz, r in (BOW_VOLUTE, STERN_VOLUTE):
        y0 = surf_y(cx, zb(cx) + 0.6)
        ring = [(cx + (r + 0.19) * math.cos(2 * math.pi * i / 8), cz + (r + 0.19) * math.sin(2 * math.pi * i / 8))
                for i in range(8)]
        B.plate(CREAM, ring, y0 - 0.2, y0 - 0.02, bevel=0)
    # the bow's cap rail (on the bulwark) and the lower band (along the red's lower edge), both into the shield
    xs = [BOW_VOLUTE[0] - 0.2, -2.9, -3.8, -4.7, -5.62]
    rail = [(x, beam(x) - 0.155, gunwale(x)) for x in xs]
    B.mesh(CREAM, sweep3d(rect_band(0.13, 0.34, 0.02), rail, (0.0, 0.0, 1.0)))
    xs = [WAIST[0] - 0.05, -2.9, -3.8, -4.7, -5.62]
    low = [(x, surf_y(x, zb(x)) - 0.02, zb(x)) for x in xs]
    B.mesh(CREAM, sweep3d(rect_band(0.15, 0.26), low, (0.0, 1.0, 0.0)))
    # the waist cap rail between the volutes (the inner cream U of the reference)
    xs = [WAIST[0] + 0.3, -0.6, 1.2, WAIST[1] - 0.3]
    rail = [(x, beam(x) - 0.155, gunwale(x)) for x in xs]
    B.mesh(CREAM, sweep3d(rect_band(0.13, 0.36, 0.02), rail, (0.0, 0.0, 1.0)))


def stern_rails(B):
    """The stern castle: the cap rail and the wale running round the stern, the corner pillars."""
    def round_path(f, z_of, x0):
        xs = [x0, 4.3, 5.6]
        stb = [(x, f(x), z_of(x)) for x in xs]
        bs = f(X_STERN)
        corner = [(X_STERN - 0.02, bs * 0.8, z_of(X_STERN)), (X_STERN + 0.04, bs * 0.3, z_of(X_STERN))]
        half = stb + corner
        return half + [(x, -y, z) for x, y, z in reversed(half)]

    rail = round_path(lambda x: beam(x) - 0.155, gunwale, WAIST[1] + 0.25)
    B.mesh(CREAM, sweep3d(rect_band(0.13, 0.34, 0.02), rail, (0.0, 0.0, 1.0)))
    wale = round_path(lambda x: beam(x) - 0.02, zb, STERN_VOLUTE[0] + 0.1)
    sides = []
    for x, y, z in wale:
        if x > X_STERN - 0.2:
            sides.append((1.0, 0.35 * (1 if y > 0 else -1), 0.0))
        else:
            sides.append((0.0, 1.0 if y > 0 else -1.0, 0.0))
    B.mesh(CREAM, sweep3d(rect_band(0.15, 0.26), wale, sides))
    for s in (1, -1):
        x = X_STERN - 0.08
        y = s * (beam(x) - 0.06)
        B.box(CREAM, (x, y, (zb(x) + gunwale(x)) / 2), (0.24, 0.24, gunwale(x) - zb(x)), rot=math.radians(45 * s),
              open="-z +z", bevel=0)


def portholes(B):
    ports = [(-4.3, 2.56), (-3.1, 2.42), (-0.75, 1.86), (0.75, 1.86), (3.75, 2.3), (5.0, 2.32)]
    for side in (1, -1):
        for x, z in ports:
            y = side * (surf_y(x, z) - 0.02)
            with B.frame(T(x, y, z) @ facing((0.0, side))):
                B.mesh(GOLD, bm_lathe([(0.32, -0.04), (0.29, 0.1), (0.18, 0.04)], 10, 0.0, cap=False), bevel=0,
                       smooth=True)
                bm = bmesh.new()
                bm.faces.new([bm.verts.new((0.19 * math.cos(k * math.pi / 5), 0.19 * math.sin(k * math.pi / 5), 0.045))
                              for k in range(10)])
                B.mesh(INK, bm)


# -- the bow: red shield, crossed bones, the sun-lion ----------------------------------------------------------------------
def turned(x, y, z, turn):
    """A drawing frame at (x, y, z) facing forward (-X) turned `turn` toward the street (+Y)."""
    return T(x, y, z) @ facing((-math.cos(turn), math.sin(turn)))


def bow(B):
    sh = SHIELD
    with B.frame(turned(sh["x"], 0.0, sh["z"], sh["turn"])):
        r = sh["r"]
        B.disc(RED, (0, 0, -0.34), r, 0.3, n=16, bevel=0)
        B.mesh(CREAM, bm_lathe([(r - 0.04, -0.4), (r + 0.27, -0.2), (r - 0.02, 0.06)], 16, 0.0, cap=False), bevel=0,
               smooth=True)
        for a in (-135, -80, -30):
            ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
            B.mesh(GOLD, bm_lathe([(0.11, 0.0), (0.08, 0.07), (0.0, 0.1)], 6, 0.0, cap=False),
                   T(0.95 * ca, 0.95 * sa, -0.06), bevel=0, smooth=True)
        # the gold ring behind the lion
        B.mesh(GOLD, bm_lathe([(0.6, -0.06), (0.69, 0.05), (0.78, -0.06)], 12, 0.0, cap=False), bevel=0, smooth=True)
    lion(B)


def lion(B):
    L = LION
    with B.frame(turned(L["x"], L["y"], L["z"], L["turn"])):
        # crossed bones behind the mane
        for a in (52.0, -52.0):
            d = Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0.0))
            p = d.cross(Vector((0.0, 0.0, 1.0)))
            z = Vector((0.0, 0.0, -0.44))
            for s in (1, -1):
                end = d * (1.86 * s) + z
                M = basis(d, p, Vector((0.0, 0.0, 1.0)), end) @ S(0.85, 1.6, 0.9)
                B.mesh(CREAM, ball(0.23, 6, 3), M, bevel=0, smooth=True)
            B.mesh(CREAM, rope_bm(d * -1.8 + z, d * 1.8 + z, 0.13, 6), bevel=0, smooth=True)
        # the mane: 14 fat petals, long and short, curving forward
        for k in range(12):
            a = math.radians(90.0 + 360.0 * k / 12 + 8.0)
            long = k % 2 == 0
            B.mesh(ORANGE, petal(1.64 if long else 1.4, 0.44 if long else 0.38, a), smooth=True)
        # the face: a round yellow head
        B.mesh(GOLD, bm_lathe([(0.0, -0.36), (0.72, -0.26), (0.97, 0.0), (0.92, 0.28), (0.7, 0.53), (0.35, 0.67),
                               (0.0, 0.7)], 14, 0.0), bevel=0, smooth=True)
        # cream muzzle, brown nose, the smile
        mz = Vector((0.0, -0.24, 0.5))
        B.mesh(CREAM, bm_lathe([(0.0, 0.0), (0.44, 0.03), (0.41, 0.17), (0.24, 0.29), (0.0, 0.32)], 8, math.pi / 8),
               T(*mz) @ S(1.24, 0.94, 1.0), bevel=0, smooth=True)
        B.mesh(INK, bm_lathe([(0.0, 0.0), (0.13, 0.02), (0.1, 0.09), (0.0, 0.11)], 6, 0.0),
               T(0.0, mz.y + 0.15, mz.z + 0.26) @ S(1.3, 0.9, 1.0), bevel=0, smooth=True)
        smile = [(-0.3, -0.04), (-0.15, -0.16), (0.0, -0.1), (0.15, -0.16), (0.3, -0.04)]
        path = []
        for sx, sy in smile:
            u = (sx / (0.44 * 1.24)) ** 2 + (sy / (0.44 * 0.94)) ** 2
            path.append((sx, mz.y + sy, mz.z + 0.32 * math.sqrt(max(0.0, 1.0 - u)) + 0.0))
        B.mesh(INK, sweep3d([(-0.025, -0.03), (0.03, 0.0), (-0.025, 0.03)], path, (0.0, 0.0, 1.0), closed_prof=True))
        # eyes: white ring + black pupil, set on the face's surface
        for sx in (-0.36, 0.36):
            n = Vector((sx, 0.26, 0.62)).normalized()
            pos = Vector((n.x * 0.94, n.y * 0.94, n.z * 0.72))
            up = Vector((0.0, 1.0, 0.0))
            xx = up.cross(n).normalized()
            M = basis(xx, n.cross(xx), n, pos)
            B.mesh(CREAM, bm_lathe([(0.19, -0.05), (0.18, 0.03), (0.0, 0.06)], 8, 0.0), M, bevel=0, smooth=True)
            B.mesh(INK, bm_lathe([(0.13, 0.02), (0.11, 0.07), (0.0, 0.09)], 8, 0.0), M, bevel=0, smooth=True)


def petal(r_tip, hw, a):
    """A pointed leaf-cone petal of the sun mane in the lion frame (radial angle a), its base buried behind the face."""
    d = Vector((math.cos(a), math.sin(a), 0.0))
    p = Vector((-math.sin(a), math.cos(a), 0.0))
    z = Vector((0.0, 0.0, 1.0))
    bm = bmesh.new()

    def ring(r, w, t, dz):
        c = d * r + z * dz
        return [bm.verts.new(c + p * w), bm.verts.new(c + z * t), bm.verts.new(c - p * w), bm.verts.new(c - z * t)]

    L = r_tip - 0.62
    base = ring(0.62, hw * 0.84, 0.16, -0.28)
    mid = ring(0.62 + L * 0.42, hw, 0.15, -0.14)
    top = ring(0.62 + L * 0.78, hw * 0.6, 0.1, -0.03)
    tip = bm.verts.new(d * r_tip + z * 0.04)
    for a0, b0 in ((base, mid), (mid, top)):
        for j in range(4):
            k = (j + 1) % 4
            bm.faces.new((a0[j], a0[k], b0[k], b0[j]))
    for j in range(4):
        bm.faces.new((top[j], top[(j + 1) % 4], tip))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return bm


# -- the stern castle: balustrades, the domed cabin, the tree, the lantern ------------------------------------------------
def balustrade(B, pts, z0, h=0.36, step=0.46):
    """Posts + a cream hand rail along a polyline [(x, y)] standing on z0 (z0 may be a function of x)."""
    zf = z0 if callable(z0) else (lambda x: z0)
    rail = [(x, y, zf(x) + h) for x, y in pts]
    B.mesh(CREAM, sweep3d(rect_profile(-0.05, 0.05, -0.05, 0.05), rail, (0.0, 0.0, 1.0), closed_prof=True))
    total = sum((Vector(b) - Vector(a)).length for a, b in zip(pts, pts[1:]))
    n = max(2, int(round(total / step)))
    seg = [(Vector(a), Vector(b)) for a, b in zip(pts, pts[1:])]
    lens = [(b - a).length for a, b in seg]
    for i in range(1, n):
        s = total * i / n
        for (a, b), L in zip(seg, lens):
            if s <= L + 1e-6:
                q = a + (b - a) * (s / L if L else 0)
                B.mesh(CREAM, bm_lathe([(0.055, 0.0), (0.055, h)], 3, math.pi / 6, cap=False), T(q.x, q.y, zf(q.x)),
                       bevel=0)
                break
            s -= L


def stern_castle(B):
    top = lambda x: gunwale(x) + 0.12
    for s in (1, -1):
        pts = [(x, s * (beam(x) - 0.155)) for x in (WAIST[1] + 0.2, 4.2, 5.8)]
        balustrade(B, pts, top, step=0.52)
    for s in (1, -1):
        pts = [(x, s * (beam(x) - 0.155)) for x in (WAIST[0] + 0.5, 0.3, WAIST[1] - 0.5)]
        balustrade(B, pts, top, h=0.32, step=0.64)
    # the domed aft cabin: cream drum, arched windows, red / gold gores, a gold knob
    cx, z0 = 5.05, DECK[2]
    B.lathe(CREAM, (cx, 0.0, 0.0), [(0.78, z0 - 0.02), (0.78, z0 + 0.66)], n=12, cap=False, bevel=0)
    for k in range(8):
        a0, a1 = 2 * math.pi * k / 8, 2 * math.pi * (k + 1) / 8
        prof = [(0.86, z0 + 0.64), (0.8, z0 + 0.96), (0.62, z0 + 1.2), (0.34, z0 + 1.36), (0.0, z0 + 1.41)]
        B.mesh(RED if k % 2 == 0 else GOLD, lathe_seg(prof, a0, a1, 1), T(cx, 0.0, 0.0), smooth=True)
    B.mesh(GOLD, ball(0.1, 6, 2), T(cx, 0.0, z0 + 1.47), bevel=0, smooth=True)
    win = [(-0.14, 0.0), (0.14, 0.0), (0.14, 0.24), (0.07, 0.34), (0.0, 0.36), (-0.07, 0.34), (-0.14, 0.24)]
    for a in (90.0, -90.0, 30.0, -30.0):
        n = (math.cos(math.radians(a)), math.sin(math.radians(a)))
        with B.frame(T(cx + 0.79 * n[0], 0.79 * n[1], z0 + 0.14) @ facing(n)):
            bm = bmesh.new()
            bm.faces.new([bm.verts.new((x, y, 0.01)) for x, y in win])
            B.mesh(INK, bm)
    # the round tree on the stern deck
    B.cyl(MAST, (3.3, 0.3, z0 - 0.02), (3.3, 0.3, z0 + 0.3), 0.07, n=5, bevel=0)
    B.mesh(GRASS, ball(0.46, 8, 4), T(3.3, 0.3, z0 + 0.68) @ S(1.0, 1.0, 0.92), bevel=0, smooth=True)
    # the stern lantern on its arm
    lx = X_STERN + 0.14
    B.mesh(MAST, rope_bm((X_STERN - 0.05, 0.0, gunwale(X_STERN) + 0.1), (lx, 0.0, gunwale(X_STERN) + 0.72), 0.05, 5),
           bevel=0)
    lz = gunwale(X_STERN) + 0.5
    B.mesh(INK, bm_lathe([(0.2, 0.0), (0.0, 0.18)], 4, math.pi / 4), T(lx, 0.0, lz + 0.4), bevel=0)
    B.box(LANTERN, (lx, 0.0, lz + 0.2), (0.24, 0.24, 0.38), bevel=0)
    B.box(INK, (lx, 0.0, lz - 0.02), (0.3, 0.3, 0.06), bevel=0)


# -- masts, crow's nest, rigging ---------------------------------------------------------------------------------------------
def masts(B):
    B.lathe(MAST, (MX, 0.0, 0.0), [(0.17, DECK[1] - 0.05), (0.14, 6.6), (0.1, MAST_TOP - 0.04), (0.0, MAST_TOP)], n=8,
            cap=False, bevel=0)
    B.lathe(MAST, (AX, -0.05, 0.0), [(0.13, DECK[2] - 0.05), (0.1, 6.55), (0.0, 6.62)], n=8, cap=False, bevel=0)
    # the crow's nest: red / white staves on a walnut floor
    z0, z1, r0, r1 = 6.62, 7.02, 0.44, 0.52
    B.disc(MAST, (MX, 0.0, z0 - 0.06), r1 + 0.04, 0.08, n=8, bevel=0)
    for k in range(8):
        a0, a1 = 2 * math.pi * k / 8, 2 * math.pi * (k + 1) / 8
        bm = bmesh.new()
        ob = [bm.verts.new((MX + r1 * math.cos(a), r1 * math.sin(a), z)) for a in (a0, a1) for z in (z0,)]
        ot = [bm.verts.new((MX + r1 * math.cos(a), r1 * math.sin(a), z1)) for a in (a0, a1)]
        it = [bm.verts.new((MX + r0 * math.cos(a), r0 * math.sin(a), z1)) for a in (a0, a1)]
        ib = [bm.verts.new((MX + r0 * math.cos(a), r0 * math.sin(a), z0)) for a in (a0, a1)]
        bm.faces.new((ob[0], ob[1], ot[1], ot[0]))
        bm.faces.new((ot[0], ot[1], it[1], it[0]))
        bm.faces.new((it[0], it[1], ib[1], ib[0]))
        bm.normal_update()
        for f in bm.faces:
            c = f.calc_center_median()
            out = Vector((c.x - MX, c.y, 0.0))
            if (f.normal.z < 0.5 and f.normal.dot(out) < 0 and out.length > r0 + 0.02) or \
               (abs(f.normal.z) < 0.5 and out.length < r0 + 0.01 and f.normal.dot(out) > 0) or \
               (f.normal.z < -0.5):
                f.normal_flip()
        B.mesh(RED if k % 2 == 0 else CREAM, bm, smooth=False)


def rigging(B):
    rope = lambda a, b, r=0.028: B.mesh(ROPE, rope_bm(a, b, r), bevel=0)
    # two rope ladders on the port (pen) side, clear of the billowing main sail
    for x_bot in (WAIST[1] + 0.05, -2.45):
        top = Vector((MX + (0.12 if x_bot > MX else -0.12), -0.44, 6.66))
        bot = Vector((x_bot, -(beam(x_bot) - 0.02), gunwale(x_bot) + 0.12))
        d = bot - top
        side = d.cross(Vector((0.0, 0.0, 1.0))).normalized()
        ends = []
        for k in (1, -1):
            a = top + side * (0.1 * k)
            b = bot + side * (0.3 * k)
            rope(a, b)
            ends.append((a, b))
        for i in range(1, 6):
            t = i / 6
            rope(ends[0][0] + (ends[0][1] - ends[0][0]) * t, ends[1][0] + (ends[1][1] - ends[1][0]) * t, 0.022)
    # stays: fore stay to the bow shield, a back stay to the aft mast; the main sail's fore sheet
    rope((MX, 0.0, MAST_TOP - 0.2), (SHIELD["x"] + 0.3, 0.0, SHIELD["z"] + SHIELD["r"] + 0.12))
    rope((MX, 0.0, 6.9), (AX, -0.05, 6.4))
    x = MAIN["xc"] - MAIN["w_bot"] / 2 + 0.12
    rope(main_surf(-(x - MAIN["xc"]), 0.02), (x - 0.45, beam(x - 0.45) - 0.16, gunwale(x - 0.45) + 0.12))


# -- the sails -----------------------------------------------------------------------------------------------------------------
def sail_surf(spec, s, t):
    """Point of a sail at (s across, viewer's right from the street = -X; t up from its foot)."""
    v = max(0.0, min(1.0, t / spec["h"]))
    w = spec["w_bot"] + (spec["w_top"] - spec["w_bot"]) * v
    u = max(0.0, min(1.0, s / w + 0.5))
    x = spec["xc"] - s * (1.0 - 0.05 * math.sin(math.pi * v))     # the leeches curve in: the cloth billows
    z = spec["z0"] + t - spec["foot"] * math.sin(math.pi * u) * (1.0 - v) ** 2
    y = spec["y0"] + spec["a"] * (0.3 + 0.7 * math.sin(math.pi * u)) * math.sin(math.pi * 0.82 * (1.0 - v))
    return Vector((x, y, z))


def sail_normal(spec, s, t):
    e = 0.02
    ds = sail_surf(spec, s + e, t) - sail_surf(spec, s - e, t)
    dt = sail_surf(spec, s, t + e) - sail_surf(spec, s, t - e)
    n = dt.cross(ds).normalized()
    return n if n.y > 0 else -n


def main_surf(s, t):
    return sail_surf(MAIN, s, t)


def shell(spec, s0, s1, t0, t1, nu, nv, th):
    """A thick curved cloth panel over s0..s1 x t0..t1 (front faces the street, +Y)."""
    bm = bmesh.new()
    F, Bk = [], []
    for i in range(nu + 1):
        fr, br = [], []
        for j in range(nv + 1):
            t = t0 + (t1 - t0) * j / nv
            v = t / spec["h"]
            w = spec["w_bot"] + (spec["w_top"] - spec["w_bot"]) * v
            s = (s0 + (s1 - s0) * i / nu) * w
            p, n = sail_surf(spec, s, t), sail_normal(spec, s, t)
            fr.append(bm.verts.new(p + n * th / 2))
            br.append(bm.verts.new(p - n * th / 2))
        F.append(fr)
        Bk.append(br)
    for i in range(nu):
        for j in range(nv):
            bm.faces.new((F[i][j], F[i + 1][j], F[i + 1][j + 1], F[i][j + 1]))
            bm.faces.new((Bk[i][j + 1], Bk[i + 1][j + 1], Bk[i + 1][j], Bk[i][j]))
    loop = [(i, 0) for i in range(nu)] + [(nu, j) for j in range(nv)] + [(i, nv) for i in range(nu, 0, -1)] + \
           [(0, j) for j in range(nv, 0, -1)]
    for k in range(len(loop)):
        i0, j0 = loop[k]
        i1, j1 = loop[(k + 1) % len(loop)]
        bm.faces.new((F[i0][j0], Bk[i0][j0], Bk[i1][j1], F[i1][j1]))
    return bm


def relief(spec, poly, h, th, fan=True):
    """A shape [(s, t)] (ccw seen from the street) raised h over BOTH faces of a sail of thickness th: one prism
    through the cloth, its caps following the belly (fanned from the centroid so big shapes do not sink)."""
    poly = ccw(poly)
    bm = bmesh.new()
    F, Bk = [], []
    for s, t in poly:
        p, n = sail_surf(spec, s, t), sail_normal(spec, s, t)
        F.append(bm.verts.new(p + n * (th / 2 + h)))
        Bk.append(bm.verts.new(p - n * (th / 2 + h)))
    m = len(poly)
    for i in range(m):
        k = (i + 1) % m
        bm.faces.new((F[i], Bk[i], Bk[k], F[k]))
    if fan:
        cs = sum(p[0] for p in poly) / m
        ct = sum(p[1] for p in poly) / m
        p, n = sail_surf(spec, cs, ct), sail_normal(spec, cs, ct)
        cf = bm.verts.new(p + n * (th / 2 + h))
        cb = bm.verts.new(p - n * (th / 2 + h))
        for i in range(m):
            k = (i + 1) % m
            bm.faces.new((cf, F[i], F[k]))
            bm.faces.new((cb, Bk[k], Bk[i]))
    else:
        bm.faces.new(F)
        bm.faces.new(list(reversed(Bk)))
    return bm


def _strip_pair(spec, a, b, w, h, th):
    """A bone shaft: a 2-segment band a -> b raised h over both faces of the sail."""
    a, b = Vector(a), Vector(b)
    d = (b - a).normalized()
    p = Vector((-d.y, d.x)) * (w / 2)
    left = [a + (b - a) * (i / 2) + p for i in range(3)]
    right = [a + (b - a) * (i / 2) - p for i in range(3)]
    return _strip_bm(spec, left, right, h, th)


def _strip_bm(spec, left, right, h, th):
    bm = bmesh.new()

    def vv(q, sgn):
        p, nn = sail_surf(spec, q.x, q.y), sail_normal(spec, q.x, q.y)
        return bm.verts.new(p + nn * (sgn * (th / 2 + h)))

    Lf = [vv(q, 1) for q in left]
    Rf = [vv(q, 1) for q in right]
    Lb = [vv(q, -1) for q in left]
    Rb = [vv(q, -1) for q in right]
    n = len(left) - 1
    for i in range(n):
        f = bm.faces.new((Rf[i], Rf[i + 1], Lf[i + 1], Lf[i]))
        bm.faces.new((Lb[i], Lb[i + 1], Rb[i + 1], Rb[i]))
    # walls
    loop_f = Rf + list(reversed(Lf))
    loop_b = Rb + list(reversed(Lb))
    m = len(loop_f)
    for i in range(m):
        k = (i + 1) % m
        bm.faces.new((loop_f[i], loop_b[i], loop_b[k], loop_f[k]))
    bm.normal_update()
    # orientation: the front faces must look at the street (+Y)
    if sum(f.normal.y for f in bm.faces[:n]) < 0:
        for f in bm.faces:
            f.normal_flip()
    return bm


def ellipse_pts(cx, cy, rx, ry, n, a0=0.0):
    return [(cx + rx * math.cos(a0 + 2 * math.pi * k / n), cy + ry * math.sin(a0 + 2 * math.pi * k / n)) for k in range(n)]


def bone_end(c, d, r=0.17, gap=0.13):
    """A bone knob (two lobes, 8 points) centred on c, the bone's axis d (unit, pointing outward)."""
    c, d = Vector(c), Vector(d)
    p = Vector((-d.y, d.x))
    pts = []
    for k in (1, -1):
        lobe = c + p * (gap * k)
        base = math.atan2(p.y * k, p.x * k)
        for da in (-80.0, 0.0, 80.0):
            a = base + math.radians(da) * k
            pts.append(tuple(lobe + Vector((math.cos(a), math.sin(a))) * r))
    # ccw: lobe +p (outer -> inner), the inner notch, lobe -p (inner -> outer), the outer notch
    lp, lm = pts[:3], pts[3:]
    return lp + [tuple(c - d * (r * 0.3))] + list(reversed(lm)) + [tuple(c + d * (r * 0.3))]


def main_sail(B):
    sp, th = MAIN, 0.07
    B.mesh(M_SAIL, shell(sp, -0.5, 0.5, 0.0, sp["h"], 6, 4, th), smooth=True)
    B.cyl(M_YARD, (sp["xc"] - sp["w_top"] / 2 - 0.25, 0.24, 6.5), (sp["xc"] + sp["w_top"] / 2 + 0.25, 0.24, 6.5), 0.09,
          n=6, bevel=0)
    # the Straw Hat Jolly Roger (s: the viewer's right from the street), centred on the sail
    c = Vector((0.0, 1.86))
    S_ = 1.02

    def at(pts, k=1.0):
        return [tuple(c + Vector(p) * (S_ * k)) for p in pts]

    # crossed bones: black outline strips + knobs, white strips + knobs on top
    for a in (35.0, -35.0):
        d = Vector((math.cos(math.radians(a)), math.sin(math.radians(a))))
        e0, e1 = c - d * (1.36 * S_), c + d * (1.36 * S_)
        B.mesh(M_INK, _strip_pair(sp, e0, e1, 0.3 * S_, 0.03, th))
        B.mesh(M_WHITE, _strip_pair(sp, e0, e1, 0.19 * S_, 0.05, th))
        for e, dd in ((e1, d), (e0, -d)):
            B.mesh(M_INK, relief(sp, bone_end(e, dd, 0.23 * S_, 0.15 * S_), 0.03, th, fan=False))
            B.mesh(M_WHITE, relief(sp, bone_end(e, dd, 0.17 * S_, 0.15 * S_), 0.05, th, fan=False))
    # the skull: black outline, white skull, eyes, nose, teeth
    skull = [(0.78 * math.cos(math.radians(d)), 0.05 + 0.66 * math.sin(math.radians(d))) for d in range(-20, 201, 30)]
    skull += [(-0.62, -0.3), (-0.48, -0.76), (0.0, -0.86), (0.48, -0.76), (0.62, -0.3)]
    B.mesh(M_INK, relief(sp, at(skull, 1.1), 0.06, th))
    B.mesh(M_WHITE, relief(sp, at(skull), 0.08, th))
    for ex in (-0.3, 0.3):
        B.mesh(M_INK, relief(sp, at(ellipse_pts(ex, 0.02, 0.2, 0.23, 8)), 0.1, th, fan=False))
    B.mesh(M_INK, relief(sp, at([(0.0, -0.18), (0.1, -0.36), (-0.1, -0.36)]), 0.1, th, fan=False))
    B.mesh(M_INK, relief(sp, at([(-0.46, -0.565), (0.46, -0.565), (0.46, -0.515), (-0.46, -0.515)]), 0.1, th,
                         fan=False))
    for tx in (-0.24, 0.0, 0.24):
        B.mesh(M_INK, relief(sp, at([(tx - 0.022, -0.74), (tx + 0.022, -0.74), (tx + 0.022, -0.44),
                                     (tx - 0.022, -0.44)]), 0.1, th, fan=False))
    # the straw hat: black outline, gold brim + crown, red band
    brim = ellipse_pts(0.0, 0.5, 1.12, 0.21, 12)
    crown = [(-0.62, 0.52), (0.62, 0.52), (0.6, 0.74), (0.48, 0.94), (0.22, 1.05), (-0.22, 1.05), (-0.48, 0.94),
             (-0.6, 0.74)]
    B.mesh(M_INK, relief(sp, at(ellipse_pts(0.0, 0.5, 1.2, 0.28, 12)), 0.09, th, fan=False))
    B.mesh(M_HAT, relief(sp, at(brim), 0.11, th, fan=False))
    B.mesh(M_INK, relief(sp, at([(x * 1.06, 0.5 + (y - 0.5) * 1.08) for x, y in crown]), 0.1, th, fan=False))
    B.mesh(M_HAT, relief(sp, at(crown), 0.13, th, fan=False))
    B.mesh(M_BAND, relief(sp, at([(-0.61, 0.56), (0.61, 0.56), (0.6, 0.74), (-0.6, 0.74)]), 0.15, th, fan=False))


def aft_sail(B):
    sp, th = AFT, 0.06
    n = 7
    for k in range(n):
        B.mesh(A_RED if k % 2 == 0 else A_WHITE, shell(sp, -0.5 + k / n, -0.5 + (k + 1) / n, 0.0, sp["h"], 1, 2, th),
               smooth=True)
    B.cyl(A_YARD, (sp["xc"] - sp["w_top"] / 2 - 0.2, 0.17, 6.05), (sp["xc"] + sp["w_top"] / 2 + 0.2, 0.17, 6.05), 0.07,
          n=6, bevel=0)
    flag(B, A_INK, A_WHITE, AX, -0.05, 6.14, 0.9, 0.42)


def flag(B, ink, white, x0, y0, z0, length, height):
    """A black Jolly Roger flag streaming toward the bow (-X) from the pole at x0: a white skull and crossed bones
    through it (both faces)."""
    bm = bmesh.new()
    n = 3
    F, Bk = [], []
    for i in range(n + 1):
        u = i / n
        x = x0 - 0.06 - length * u
        y = y0 + 0.07 * math.sin(math.pi * 1.5 * u)
        col_f, col_b = [], []
        for z in (z0, z0 + height):
            col_f.append(bm.verts.new((x, y + 0.025, z - 0.04 * u)))
            col_b.append(bm.verts.new((x, y - 0.025, z - 0.04 * u)))
        F.append(col_f)
        Bk.append(col_b)
    for i in range(n):
        bm.faces.new((F[i][0], F[i][1], F[i + 1][1], F[i + 1][0]))
        bm.faces.new((Bk[i + 1][0], Bk[i + 1][1], Bk[i][1], Bk[i][0]))
        bm.faces.new((F[i][1], Bk[i][1], Bk[i + 1][1], F[i + 1][1]))
        bm.faces.new((Bk[i][0], F[i][0], F[i + 1][0], Bk[i + 1][0]))
    bm.faces.new((F[0][0], Bk[0][0], Bk[0][1], F[0][1]))
    bm.faces.new((F[n][1], Bk[n][1], Bk[n][0], F[n][0]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    B.mesh(ink, bm, smooth=False)
    u = 0.5
    cx = x0 - 0.06 - length * u
    cy = y0 + 0.07 * math.sin(math.pi * 1.5 * u)
    cz = z0 + height * 0.5 - 0.02
    hs = height / 0.46
    for a in (0.62, -0.62):
        d = Vector((math.cos(a), 0.0, math.sin(a))) * (0.17 * hs)
        B.mesh(white, rope_bm((cx + d.x, cy, cz + d.z), (cx - d.x, cy, cz - d.z), 0.03 * hs, 4), bevel=0)
    sk = [(0.13 * math.cos(2 * math.pi * k / 6), 0.12 * math.sin(2 * math.pi * k / 6) + 0.03) for k in range(6)]
    bm = bmesh.new()
    fr = [bm.verts.new((cx - s * hs, cy + 0.045, cz + t * hs)) for s, t in sk]
    bk = [bm.verts.new((cx - s * hs, cy - 0.045, cz + t * hs)) for s, t in sk]
    for i in range(6):
        k = (i + 1) % 6
        bm.faces.new((fr[i], bk[i], bk[k], fr[k]))
    bm.faces.new(fr)
    bm.faces.new(list(reversed(bk)))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    B.mesh(white, bm)


# -- the whole ship ----------------------------------------------------------------------------------------------------------
def build(B):
    """The Thousand Sunny in the ship frame (see the module doc)."""
    for name, fn in (("hull", hull), ("bulwark", bulwark), ("trims", trims), ("portholes", portholes), ("bow", bow),
                     ("stern castle", stern_castle), ("masts", masts), ("rigging", rigging), ("main sail", main_sail),
                     ("aft sail", aft_sail)):
        with B.module("Sunny " + name):
            fn(B)
    with B.module("Sunny flag"):
        flag(B, F_INK, F_WHITE, MX, 0.0, 7.12, 1.05, 0.46)


def hull_bottom(x, y):
    """The hull's lowest outer z at (x, y) (the cradles' saddles follow it)."""
    b = beam(x)
    if abs(y) >= b:
        return zb(x)
    th = math.asin(min(1.0, (abs(y) / b) ** (1.0 / EXP)))
    return sec(x, th)[1]
