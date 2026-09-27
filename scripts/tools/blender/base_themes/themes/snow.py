# scripts/tools/blender/base_themes/themes/snow.py
# Snow = DRAGON BALL: "Capsule Corp Arena" (owner art direction 2026-09-24, base theme API v3; reference: forest.py).
#   Perimeter: futuristic curved Capsule Corporation walls (a silhouette no other base has: a row of domes). A navy
#   plinth carries a pearl-white wall with a turquoise capsule seam band, aqua accent lines on both faces and a turquoise
#   pilaster at every module joint; every span is crowned by an orange Capsule Corp dome (a half-ellipse) with a round
#   aqua porthole, and a spherical Bulma capsule stud (turquoise bottom, pearl top) sits in each valley between two
#   domes. No crosses, no straight barrier.
#   Corners: rounded-square Capsule Corp towers (navy foot, pearl shaft with the turquoise seam band, an orange rounded
#   cap) each holding a full 3D Dragon Ball (glossy amber sphere, raised red stars: 4 / 1 / 7 / 3) in a turquoise cup.
#   Gate: two standing Hoi-Poi capsules (pearl body, turquoise seam, orange cap, a turquoise window with an aqua slot)
#   carry a giant lying capsule (pearl body, turquoise seams, orange rounded ends, a chamfered push button) with the 3D
#   Capsule Corp "C" medallion in front (navy disc, stepped pearl rim, pearl "C" with a turquoise top step, a two-tone
#   capsule in its mouth).
#   Floor: the Tenkaichi Budokai ring: big chamfered grey stone slabs on a dark stone bed (the grout), a darker stepped
#   curb with chamfered pearl studs at its corners and a stone path from the gate with aqua guide lines, all in a
#   ring-out lawn (Floor_Base, chamfered turf slabs).
#   Centre: a sunken round navy podium (stepped pearl rim, turquoise accent ring) holding the 7 Dragon Balls in 3D:
#   glossy amber half-ellipsoids (their steep rounded edge shades like a sphere) with faceted raised red stars 1..7,
#   the 4-star ball in the middle, everything below h 0.3.
#   Terminal: a giant Dragon Radar. A round pearl casing on the fence line with a dark green radar face, a glossy green
#   grid and amber Dragon Ball blips; a 24-segment pearl rim with a turquoise lip wraps the upgrade sign (the
#   Neon_Emissive_Screen bezel is the radar's green screen); it stands on two navy feet over a navy console with neon
#   slots and has the radar's crown push button on top.
#   No backdrop: the plot stays open.
#   Budget (evaluated): Std ~8.6k, Deep ~8.9k tris of 9000; round things are smooth-shaded lathes with few sides.

import math

import bmesh
from mathutils import Vector

from common import *

GRASS, TILE, STONE = "Floor_Base", "Floor_Tile", "Floor_Stone"
PEARL, ORANGE, TEAL, NAVY, RADAR = ("Structure_Pearl", "Structure_Orange", "Structure_Teal", "Structure_Navy",
                                    "Structure_Radar")
AMBER, RED = "Core_3D_Amber", "Core_3D_Red"
GLOW, SCREEN = "Neon_Emissive_Teal", "Neon_Emissive_Screen"

TEAL_RGB = (46, 236, 226)
GREEN_RGB = (86, 255, 118)
KI_RGB = (255, 176, 60)
# the accents without glow (owner 2026-09-25: no neon, no lights in the bases): the same hues a notch deeper, glossy
TEAL_ACCENT_RGB = (40, 214, 206)
GREEN_ACCENT_RGB = (62, 216, 100)

# ring-out lawn + the Budokai ring (the ring's edge is BAND inside the fence lines, its curb CURB wide)
BAND, CURB = 4.2, 0.9
RING_TILES = {"Std": (8, 8), "Deep": (8, 8)}
TILE_TOP, CURB_TOP, PODIUM_TOP = 0.2, 0.14, 0.14
PATH_V = 3.3

# perimeter cross-sections (y outward, z up); the corner towers, pylons and studs own the y = -0.62 line
PLINTH = [(-0.6, 0.0), (0.88, 0.0), (0.88, 0.56), (0.72, 0.72), (-0.6, 0.72)]
WALL = [(-0.5, 0.72), (0.56, 0.72), (0.56, 2.2), (-0.5, 2.2)]
BAND_T = [(-0.58, 2.12), (0.64, 2.12), (0.64, 2.44), (-0.58, 2.44)]
GLOW_OUT = [(0.56, 1.2), (0.62, 1.2), (0.62, 1.36), (0.56, 1.36)]
GLOW_IN = [(-0.56, 1.2), (-0.5, 1.2), (-0.5, 1.36), (-0.56, 1.36)]
WALL_TOP = 2.44
DOME_H = 1.3     # the dome crest above the band
DOME_Y = (-0.56, 0.62)

# the Dragon Radar (terminal frame: x = v - 10.435, y = u - (D + 1.48), z up; the fence line is y -1.48)
RADAR_HC = 2.9                     # the radar's centre height (the sign's centre is 2.835)
RIM_IN, RIM_OUT = 3.95, 4.35       # 24-segment rim: every segment's box clears the sign's box
RIM_Y = (-1.0, 0.8)
LIP_Y = (0.8, 0.92)
FACE_Y = -1.0                      # the radar's green face (the grid lines stand on it)
FOOT_X = (3.25, 4.3)

# the stars of each Dragon Ball in units of its radius (x right, y up on its face) and their size
STAR_LAYOUT = {
    1: [(0.0, 0.0)],
    2: [(-0.3, 0.0), (0.3, 0.0)],
    3: [(0.0, 0.3), (-0.3, -0.2), (0.3, -0.2)],
    4: [(0.0, 0.34), (-0.34, 0.0), (0.34, 0.0), (0.0, -0.34)],
    5: [(0.0, 0.38), (-0.38, 0.1), (0.38, 0.1), (-0.23, -0.33), (0.23, -0.33)],
    6: [(-0.2, 0.37), (0.2, 0.37), (-0.42, 0.0), (0.42, 0.0), (-0.2, -0.37), (0.2, -0.37)],
    7: [(0.0, 0.0), (-0.21, 0.38), (0.21, 0.38), (-0.43, 0.0), (0.43, 0.0), (-0.21, -0.38), (0.21, -0.38)],
}
STAR_SIZE = {1: 0.4, 2: 0.3, 3: 0.27, 4: 0.25, 5: 0.22, 6: 0.2, 7: 0.19}


# ----------------------------------------------------------------------------------------------------------------------
# shapes
# ----------------------------------------------------------------------------------------------------------------------

def star_poly(r_out, r_in, rot=math.pi / 2):
    return [((r_out if k % 2 == 0 else r_in) * math.cos(rot + k * math.pi / 5),
             (r_out if k % 2 == 0 else r_in) * math.sin(rot + k * math.pi / 5)) for k in range(10)]


def bm_star(r_out, r_in, z0, z1, rot=math.pi / 2):
    """Faceted raised five-point star: the outline at z0, the centre raised to z1, open bottom (10 tris)."""
    bm = bmesh.new()
    rim = [bm.verts.new((x, y, z0)) for x, y in star_poly(r_out, r_in, rot)]
    top = bm.verts.new((0.0, 0.0, z1))
    for i in range(10):
        bm.faces.new((rim[i], rim[(i + 1) % 10], top))
    return bm


def bm_ring_arc(r_in, r_out, z0, z1, a0, a1, n=1, faces="oi01"):
    """An arc of a ring (XY plane, angles a0..a1, z0..z1) WITHOUT end caps: `faces` picks the outer (o), inner (i),
    bottom (0) and top (1) surfaces. Neighbouring arcs meet seamlessly."""
    bm = bmesh.new()
    loops = []
    for r, z in ((r_out, z0), (r_out, z1), (r_in, z1), (r_in, z0)):
        loops.append([bm.verts.new((r * math.cos(a0 + (a1 - a0) * i / n), r * math.sin(a0 + (a1 - a0) * i / n), z))
                      for i in range(n + 1)])
    for k, tag in enumerate("o1i0"):
        if tag not in faces:
            continue
        ra, rb = loops[k], loops[(k + 1) % 4]
        for i in range(n):
            bm.faces.new((ra[i], ra[i + 1], rb[i + 1], rb[i]))
    return bm


def bm_plate(outline_xz, y0, y1, open=""):
    """Outline [(x, z)] extruded along Y from y0 to y1 (a proper rotation, so `open` can drop faces afterwards)."""
    bm = bm_prism(outline_xz, -y1, -y0)
    bm.transform(Rx(math.pi / 2))  # (x, y, z) -> (x, -z, y)
    bm.normal_update()
    if open:
        from common import _drop_faces
        _drop_faces(bm, open)
    return bm


def sphere_profile(r, bands=6, z0=None, z1=None):
    """Lathe profile of a sphere of radius r centred on z 0 (pole to pole, `bands` latitude bands), optionally cut to
    the z0..z1 slice (a ring at the cut)."""
    pts = [(r * math.sin(math.pi * k / bands), -r * math.cos(math.pi * k / bands)) for k in range(bands + 1)]
    pts[0], pts[-1] = (0.0, -r), (0.0, r)
    out = []
    for p in pts:
        if (z0 is None or p[1] >= z0 - 1e-6) and (z1 is None or p[1] <= z1 + 1e-6):
            out.append(p)
    return out


def dome_z(r, a, z_b, z_t):
    """Height of a spherical cap (base radius a at z_b, apex z_t) at radius r."""
    h = z_t - z_b
    R = (a * a + h * h) / (2 * h)
    return z_t - R + math.sqrt(max(R * R - r * r, 0.0))


def hump(L, H, n=6):
    """A Capsule Corp dome in the fence plane: half-ellipse over x -L/2..L/2, crest H (z 0 = its base)."""
    return [(-(L / 2) * math.cos(math.pi * k / n), H * math.sin(math.pi * k / n)) for k in range(n + 1)]


def c_outline(r_in, r_out, gap=0.8, n=14):
    """The Capsule Corp "C": a thick ring arc open toward +x (gap = the half opening angle)."""
    outer = [(r_out * math.cos(gap + (2 * math.pi - 2 * gap) * i / n), r_out * math.sin(gap + (2 * math.pi - 2 * gap) * i / n))
             for i in range(n + 1)]
    inner = [(r_in * math.cos(gap + (2 * math.pi - 2 * gap) * i / n), r_in * math.sin(gap + (2 * math.pi - 2 * gap) * i / n))
             for i in reversed(range(n + 1))]
    return outer + inner


def squircle(hw, rc, n=2, cx=0.0, cy=0.0):
    """Counter-clockwise rounded square (half width hw, corner radius rc, n segments per corner) centred on (cx, cy)."""
    k = hw - rc
    pts = []
    for q, (sx, sy) in enumerate(((1, -1), (1, 1), (-1, 1), (-1, -1))):
        a0 = -math.pi / 2 + q * math.pi / 2
        for i in range(n + 1):
            a = a0 + (math.pi / 2) * i / n
            pts.append((cx + sx * k + rc * math.cos(a), cy + sy * k + rc * math.sin(a)))
    return pts


def ellipsoid_profile(a, h, z_b, rings=(1.0, 0.94, 0.72)):
    """Lathe profile of a half ellipsoid (base radius a at z_b, height h): steep rounded edge, flat crown, pole."""
    return [(a * t, z_b + h * math.sqrt(max(0.0, 1.0 - t * t))) for t in rings] + [(0.0, z_b + h)]


def stadium(x0, x1, r, n=4):
    """A pill outline from x0 to x1 (radius r, centred on y 0), n segments per rounded end."""
    pts = []
    for k in range(n + 1):
        a = -math.pi / 2 + math.pi * k / n
        pts.append((x1 - r + r * math.cos(a), r * math.sin(a)))
    for k in range(n + 1):
        a = math.pi / 2 + math.pi * k / n
        pts.append((x0 + r + r * math.cos(a), r * math.sin(a)))
    return pts




class Theme(PenTheme):
    KEY, NAME, TITLE, FRANCHISE = "Snow", "CapsuleCorp", "Capsule Corp Arena", "Dragon Ball"
    PALETTE = {
        GRASS: look((66, 168, 48), "Plastic"),
        TILE: look((178, 172, 160), "Plastic"),
        STONE: look((82, 78, 76), "Plastic", bevel=0.06),
        PEARL: look((246, 244, 236), "SmoothPlastic", bevel=0.1),
        ORANGE: look((255, 112, 10), "SmoothPlastic", reflectance=0.04, bevel=0.1),
        TEAL: look((18, 184, 196), "SmoothPlastic", bevel=0.06),
        NAVY: look((30, 50, 104), "SmoothPlastic", bevel=0.08),
        RADAR: look((22, 90, 54), "SmoothPlastic", bevel=0.05),
        AMBER: look((255, 132, 0), "SmoothPlastic", reflectance=0.12, bevel=0.04),
        RED: look((200, 14, 24), "SmoothPlastic", bevel=0),
        GLOW: look(TEAL_ACCENT_RGB, "SmoothPlastic", reflectance=0.05),
        SCREEN: look(GREEN_ACCENT_RGB, "SmoothPlastic", reflectance=0.05),
    }
    TERMINAL_GAP = (6.05, 14.55)  # the Dragon Radar closes this stretch of the front fence
    EMBLEM_Z = 10.55
    EMBLEM_OUT = 1.46   # the lintel capsule's front
    STUDIO_RGB = (208, 214, 224)
    CORNER_STARS = {(-1, 1): 4, (1, 1): 1, (-1, -1): 7, (1, -1): 3}
    PORTHOLES = True

    # -- helpers -----------------------------------------------------------------------------------------------------
    def dragon_ball(self, B, center, r, stars, normal, n=10, bands=5):
        """A full 3D Dragon Ball: a glossy amber sphere with `stars` raised red stars on the face pointing along
        `normal` (current frame)."""
        c = Vector(center)
        B.mesh(AMBER, bm_lathe(sphere_profile(r, bands), n, math.pi / n, cap=False), T(*c), bevel=0, smooth=True)
        n0 = Vector(normal).normalized()
        e1 = Vector((0.0, 0.0, 1.0)).cross(n0)
        e1 = e1.normalized() if e1.length > 1e-6 else Vector((1.0, 0.0, 0.0))
        e2 = n0.cross(e1)
        so = STAR_SIZE[stars] * r * 1.1
        for a, b in STAR_LAYOUT[stars]:
            d = (n0 + e1 * a * 1.2 + e2 * b * 1.2).normalized()
            x = (e1 - d * e1.dot(d)).normalized()
            y = d.cross(x)
            B.mesh(RED, bm_star(so, so * 0.46, 0.96 * r, 1.07 * r), basis(x, y, d, c), bevel=0)

    # -- floor: the ring-out lawn, the Budokai stone ring, its stepped curb, the path from the gate ------------------------
    def floor(self, B):
        W, D = B.W, B.D
        RX, RY = W - BAND, D - BAND
        cx, cy = RX + CURB, RY + CURB

        def turf(x0, y0, x1, y1, n, along_x):
            """Lawn (Floor_Base: exactly the footprint) as chamfered turf slabs in the band around the ring."""
            for k in range(n):
                if along_x:
                    a, b = x0 + (x1 - x0) * k / n, x0 + (x1 - x0) * (k + 1) / n
                    B.mesh(GRASS, bm_tile(b - a, y1 - y0, 0.16, 0.0, FLOOR_TOP), T((a + b) / 2, (y0 + y1) / 2, 0.0), bevel=0)
                else:
                    a, b = y0 + (y1 - y0) * k / n, y0 + (y1 - y0) * (k + 1) / n
                    B.mesh(GRASS, bm_tile(x1 - x0, b - a, 0.16, 0.0, FLOOR_TOP), T((x0 + x1) / 2, (a + b) / 2, 0.0), bevel=0)
        turf(-W, -D, W, -cy, 5, True)                      # back
        turf(-W, cy, -PATH_V, D, 2, True)                  # front, left of the path
        turf(PATH_V, cy, W, D, 2, True)                    # front, right of the path
        n_side = 4 if B.variant == "Std" else 5
        turf(-W, -cy, -cx, cy, n_side, False)              # left
        turf(cx, -cy, W, cy, n_side, False)                # right
        # the stepped curb (the ring's edge) and the stone path from the gate onto the ring
        B.slab(STONE, (-cx, -cy, 0.0), (cx, -RY, CURB_TOP), open="-z")
        B.slab(STONE, (-cx, -RY, 0.0), (-RX, RY, CURB_TOP), open="-z")
        B.slab(STONE, (RX, -RY, 0.0), (cx, RY, CURB_TOP), open="-z")
        B.slab(STONE, (-cx, RY, 0.0), (-PATH_V, cy, CURB_TOP), open="-z")
        B.slab(STONE, (PATH_V, RY, 0.0), (cx, cy, CURB_TOP), open="-z")
        B.slab(STONE, (-PATH_V, RY, 0.0), (PATH_V, D, CURB_TOP), open="-z")
        # the ring: a dark stone bed (the grout, and the podium well in the middle) under big chamfered stone slabs;
        # the 4 x 4 slabs in the middle make room for the podium
        B.slab(STONE, (-RX, -RY, 0.0), (RX, RY, FLOOR_TOP), open="-z", bevel=0)
        nx, ny = RING_TILES[B.variant]
        tx, ty = 2 * RX / nx, 2 * RY / ny
        mid_x = set(range(nx // 2 - 2, nx // 2 + 2))
        mid_y = set(range(ny // 2 - 2, ny // 2 + 2))
        g = 0.11  # half the grout joint
        for i in range(nx):
            for j in range(ny):
                if i in mid_x and j in mid_y:
                    continue
                B.mesh(TILE, bm_tile(tx - 2 * g, ty - 2 * g, 0.1, FLOOR_TOP, TILE_TOP), T(-RX + tx * (i + 0.5), -RY + ty * (j + 0.5), 0.0),
                       bevel=0)
        hx, hy = tx * 2, ty * 2
        oy = -RY + ty * (min(mid_y) + 2)
        self.well = (hx, hy, oy)
        # chamfered pearl studs at the ring's corners
        for sx in (-1, 1):
            for sy in (-1, 1):
                B.stud(PEARL, (sx * (RX + CURB / 2), sy * (RY + CURB / 2), CURB_TOP), r=0.38, h=0.13, chamfer=0.06, n=6)
        # aqua guide lines along the path
        for sx in (-1, 1):
            B.strip(GLOW, (sx * (PATH_V - 0.25), RY + 1.4), (sx * (PATH_V - 0.25), D - 1.5), 0.14, z0=CURB_TOP, z1=CURB_TOP + 0.04)

    # -- centre: the round podium and the 7 Dragon Balls in 3D (floor work: everything below h 0.3) -----------------------
    def centerpiece(self, B):
        hx, hy, oy = getattr(self, "well", (11.0, 11.0, 0.0))
        with B.frame(T(0.0, oy, 0.0)):
            R = min(hx, hy) - 1.2
            B.relief_disc((0, 0, 0), [(NAVY, R, 0.0, FLOOR_TOP, PODIUM_TOP, 0)], n=24)
            B.lathe(PEARL, (0, 0, 0), [(R + 0.72, FLOOR_TOP), (R + 0.64, 0.25), (R + 0.14, 0.28), (R, PODIUM_TOP)], n=24,
                    cap=False, bevel=0)
            B.relief_disc((0, 0, 0), [(GLOW, R - 0.45, R - 0.72, PODIUM_TOP, PODIUM_TOP + 0.04, 0)], n=24)
            balls = [((0.0, 0.0), 2.4, 4)]
            ring_r = R - 3.1
            for k, stars in enumerate((1, 2, 3, 7, 6, 5)):
                a = math.pi / 2 + k * math.pi / 3 + math.pi / 6
                balls.append(((ring_r * math.cos(a), ring_r * math.sin(a)), 1.65, stars))
            for (x, y), a, stars in balls:
                self.podium_ball(B, x, y, a, stars)

    def podium_ball(self, B, x, y, a, stars, z_b=PODIUM_TOP, z_t=0.262):
        """A Dragon Ball in relief: a glossy amber half ellipsoid (steep rounded edge, so it shades like a sphere) with
        raised faceted red stars, upright for a viewer at the gate."""
        h = z_t - z_b
        n = 18 if a > 2 else 14
        B.mesh(AMBER, bm_lathe(ellipsoid_profile(a, h, z_b), n, 0.0, cap=False), T(x, y, 0.0), bevel=0, smooth=True)

        def z(r):
            t = min(r / a, 1.0)
            return z_b + h * math.sqrt(max(0.0, 1.0 - t * t))

        so = STAR_SIZE[stars] * a * 1.2
        for px, py in STAR_LAYOUT[stars]:
            # upright for a viewer at the gate (+u): the layout's "up" points away from the gate
            sx, sy = x - px * a * 1.12, y - py * a * 1.12
            d = math.hypot(sx - x, sy - y)
            z0 = z(min(d + so, a)) - 0.008
            z1 = min(z(d) + 0.04, 0.298)
            B.mesh(RED, bm_star(so, so * 0.46, z0, z1, rot=-math.pi / 2), T(sx, sy, 0.0), bevel=0)

    # -- perimeter: Capsule Corp dome walls --------------------------------------------------------------------------
    def fence(self, B):
        D, W = B.D, B.W
        g0, g1 = self.TERMINAL_GAP
        runs = [("back", -W, W, (True, True)), ("left", -D, D, (True, True)), ("right", -D, D, (True, True)),
                ("front", -W, -GATE_V, (True, True)), ("front", g1, W, (False, True))]
        for side, s0, s1, ends in runs:
            with B.module("wall"), B.frame(B.side_frame(side, (s0 + s1) / 2)):
                self.wall(B, s1 - s0, ends)
        for side, s0, s1 in B.spans(self.TERMINAL_GAP):
            with B.module("span"), B.frame(B.side_frame(side, (s0 + s1) / 2)):
                self.span(B, side, s1 - s0, s0, s1)
        for post in B.posts():
            if post.kind == "corner":
                sx, sy = (1 if post.x > 0 else -1), (1 if post.y > 0 else -1)
                self.stars = self.CORNER_STARS[(sx, sy)]
                with B.module("corner"), B.frame(B.corner_frame(sx, sy)):
                    self.corner(B)
            elif post.kind == "post":
                with B.module("post"), B.frame(B.post_frame(post)):
                    self.post(B, post)

    def wall(self, B, L, ends):
        """One continuous Capsule Corp wall along a run: navy plinth, pearl wall, turquoise seam band, aqua accent lines."""
        x0, x1 = -L / 2, L / 2
        B.sweep(NAVY, PLINTH, x0, x1, open_ends=ends)
        B.sweep(PEARL, WALL, x0, x1, open_ends=ends, open="-z +z")
        B.sweep(TEAL, BAND_T, x0, x1, open_ends=ends)
        B.sweep(GLOW, GLOW_OUT, x0, x1, open_ends=ends, open="-y")
        B.sweep(GLOW, GLOW_IN, x0, x1, open_ends=ends, open="+y")

    def span(self, B, side, L, s0, s1):
        """An orange Capsule Corp dome crowning the span (a round aqua porthole on its outer face)."""
        B.mesh(ORANGE, bm_plate([(x, WALL_TOP + z) for x, z in hump(L, DOME_H)], DOME_Y[0], DOME_Y[1], open="-z"))
        if self.PORTHOLES:
            B.relief_disc((0.0, DOME_Y[1], WALL_TOP + 0.52 * DOME_H), [(GLOW, 0.36, 0.0, 0.0, 0.05, 0)], n=8, a0=math.pi / 8,
                          axis="y")

    def post(self, B, post):
        """A spherical Bulma capsule stud in the valley between two domes: turquoise bottom, pearl top, push button."""
        r = 0.64
        c = (0.0, 0.05, WALL_TOP + 0.5)
        B.mesh(TEAL, bm_lathe(sphere_profile(r, 4, z1=0.0), 8, math.pi / 8, cap=False), T(*c), bevel=0, smooth=True)
        B.mesh(PEARL, bm_lathe(sphere_profile(r, 4, z0=0.0), 8, math.pi / 8, cap=False), T(*c), bevel=0, smooth=True)
        # a turquoise pilaster down both faces of the wall: the module joint
        for y, op in ((WALL[1][0] + 0.03, "-y -z"), (WALL[0][0] - 0.03, "+y -z")):
            B.box(TEAL, (0.0, y, (0.72 + 2.12) / 2), (0.34, 0.06, 2.12 - 0.72), open=op, bevel=0)

    def corner(self, B):
        """A rounded-square Capsule Corp tower (corner frame: x, y outward, centre (0.34, 0.34)) crowned by a full 3D
        Dragon Ball in a turquoise cup."""
        cx = cy = 0.34

        def sq(hw, rc):
            return squircle(hw, rc, 2, cx, cy)
        B.loft(NAVY, [(0.0, sq(0.96, 0.42)), (0.46, sq(0.96, 0.42)), (0.58, sq(0.9, 0.38))], cap_top=False, cap_bottom=False)
        B.loft(PEARL, [(0.58, sq(0.9, 0.38)), (2.12, sq(0.9, 0.38))], cap_top=False, cap_bottom=False, bevel=0)
        B.loft(TEAL, [(2.12, sq(0.9, 0.38)), (2.44, sq(0.9, 0.38))], cap_top=False, cap_bottom=False, bevel=0)
        B.loft(PEARL, [(2.44, sq(0.9, 0.38)), (4.3, sq(0.9, 0.38))], cap_top=False, cap_bottom=False, bevel=0)
        B.loft(ORANGE, [(4.3, sq(0.96, 0.42)), (4.8, sq(0.96, 0.42)), (5.42, sq(0.56, 0.3))], cap_bottom=False)
        # the Dragon Ball on a turquoise cup
        B.lathe(TEAL, (cx, cy, 0.0), [(0.3, 5.4), (0.56, 5.56), (0.64, 5.7)], n=10, cap=False, bevel=0)
        self.dragon_ball(B, (cx, cy, 6.34), 0.95, self.stars, (0.62, 0.62, 0.36))

    # -- gate: standing Hoi-Poi capsules, a lying capsule lintel, the Capsule Corp "C" --------------------------------
    PYLON_C = (-0.18, 0.5)
    PYLON_R = 1.0

    def gate_pylon(self, B, side):
        # pylon frame: +X away from the passage (x >= -1.3 below h 7.5), +Y out of the pen, the pen side y >= -0.62
        cx, cy = self.PYLON_C
        r = self.PYLON_R
        B.box(NAVY, (cx, cy, 0.3), (2.2, 2.2, 0.6), open="-z")
        B.lathe(PEARL, (cx, cy, 0.0), [(r, 0.9), (r, 4.96)], n=12, cap=False, bevel=0)
        B.lathe(TEAL, (cx, cy, 0.0), [(r, 4.96), (r, 5.44)], n=12, cap=False, bevel=0)
        B.mesh(ORANGE, bm_lathe([(r, 5.44), (r, 8.66), (0.9 * r, 9.14), (0.6 * r, 9.5), (0.0, 9.66)], 12, 0.0, cap=False),
               T(cx, cy, 0.0), bevel=0, smooth=True)
        # a turquoise capsule window with an aqua slot, facing out of the plot
        with B.frame(T(cx, cy + r - 0.04, 3.0) @ facing((0.0, 1.0)) @ Rz(math.pi / 2)):
            B.relief(stadium(-1.0, 1.0, 0.3, 3), [(TEAL, 0.0, 0.0, 0.1, 0)])
            B.relief(stadium(-0.84, 0.84, 0.16, 3), [(GLOW, 0.0, 0.1, 0.14, 0)])

    def gate_lintel(self, B):
        # gate frame: X = +v, Y = outward; the capsule rests on the pylons' domes (its bottom above h 9.5)
        cy, cz, r = 0.5, 10.55, 0.95
        half = 6.07
        M = T(0.0, cy, cz) @ AXES["x"]  # lathe axis along +v
        B.lathe(PEARL, (0, 0, 0), [(r, -4.4), (r, 4.4)], n=12, cap=False, M=M, bevel=0)
        for s in (-1, 1):
            Ms = T(0.0, cy, cz) @ (AXES["x"] if s > 0 else AXES["-x"])
            B.lathe(TEAL, (0, 0, 0), [(r, 4.4), (r, 4.8)], n=12, cap=False, M=Ms, bevel=0)
            B.mesh(ORANGE, bm_lathe([(r, 4.8), (r, half - 0.95), (0.9 * r, half - 0.47), (0.6 * r, half - 0.12), (0.0, half)],
                                    12, 0.0, cap=False), Ms, bevel=0, smooth=True)
        B.stud(ORANGE, (0.0, cy, cz + r - 0.05), r=0.42, h=0.26, chamfer=0.08, n=10)

    def emblem(self, B):
        # emblem frame: x = the viewer's right, y = up, +z toward the viewer (the lintel's front at z 0)
        B.relief_disc((0, 0, 0), [(NAVY, 1.82, 0.0, -0.12, 0.16, 0.05)], n=20)
        B.lathe(PEARL, (0, 0, 0), [(2.06, -0.1), (2.06, 0.24), (1.9, 0.34), (1.8, 0.16)], n=20, cap=False, bevel=0.04)
        B.relief(c_outline(0.72, 1.36, 0.72, 10), [(PEARL, 0.0, 0.16, 0.36, 0.04), (TEAL, 0.07, 0.36, 0.44, 0)])
        B.relief(stadium(-0.5, 0.92, 0.26, 3), [(ORANGE, 0.0, 0.16, 0.4, 0.04)])
        B.relief(stadium(0.22, 0.86, 0.18, 3), [(PEARL, 0.0, 0.4, 0.45, 0)])

    # -- terminal: the giant Dragon Radar around the upgrade sign --------------------------------------------------
    def terminal(self, B):
        hc = RADAR_HC
        yf = -1.48 - 0.6  # the fence line - 0.6: the back of the casing (never more than INSET into the pen)
        with B.frame(B.terminal_frame()):
            # casing (pearl) and the dark green radar face, both clipped at the ground
            def disc_poly(R, n=16):
                lim = math.asin(min(1.0, hc / R))
                a0, a1 = -lim, math.pi + lim
                return [(R * math.cos(a0 + (a1 - a0) * i / n), hc + R * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]
            B.mesh(PEARL, bm_plate(disc_poly(RIM_OUT), yf, -1.17, open="-z"))
            B.mesh(RADAR, bm_plate(disc_poly(RIM_IN + 0.05), -1.17, FACE_Y, open="-z -y"), bevel=0.03)
            # the rim: 24 segments (the 16 above the feet), each one's box clear of the sign's box
            seg = math.pi / 12
            for k in range(-2, 14):
                a0, a1 = k * seg, (k + 1) * seg
                M = T(0.0, RIM_Y[1], hc) @ Rx(math.pi / 2)
                B.mesh(PEARL, bm_ring_arc(RIM_IN, RIM_OUT, 0.0, RIM_Y[1] - RIM_Y[0], a0, a1, 1, "oi0"), M)
                M2 = T(0.0, LIP_Y[1], hc) @ Rx(math.pi / 2)
                B.mesh(TEAL, bm_ring_arc(RIM_IN + 0.08, RIM_OUT - 0.1, 0.0, LIP_Y[1] - LIP_Y[0], a0, a1, 1, "oi0"), M2)
            # the glossy green radar grid on the face (symmetric about the sign's centre: the SCREEN role's anchor)
            for x in (-1.6, 1.6, -3.1, 3.1):
                h = math.sqrt(max(RIM_IN ** 2 - x * x, 0.0))
                z0, z1 = max(hc - h, 1.1), hc + h - 0.05
                B.box(SCREEN, (x, FACE_Y + 0.03, (z0 + z1) / 2), (0.07, 0.06, z1 - z0), open="-y", bevel=0)
            for dz in (-1.35, 1.35, 2.6):
                w = math.sqrt(max(RIM_IN ** 2 - dz * dz, 0.0)) - 0.05
                B.box(SCREEN, (0.0, FACE_Y + 0.03, hc + dz), (2 * w, 0.06, 0.07), open="-y", bevel=0)
            # radar blips: the Dragon Balls on the screen
            for x, z in ((-3.35, hc + 1.7), (3.1, hc - 1.5), (-2.2, hc + 3.1), (3.4, hc + 1.9)):
                B.relief_disc((x, FACE_Y, z), [(AMBER, 0.2, 0.0, 0.0, 0.08, 0)], n=6, axis="y")
            # the crown push button on top
            top = hc + RIM_OUT
            yc = (RIM_Y[0] + LIP_Y[1]) / 2
            B.lathe(PEARL, (0.0, yc, 0.0), [(0.46, top - 0.12), (0.46, top + 0.42), (0.6, top + 0.5)], n=12, cap=False)
            B.mesh(ORANGE, bm_lathe([(0.6, top + 0.5), (0.74, top + 0.58), (0.74, top + 0.88), (0.56, top + 1.02),
                                     (0.0, top + 1.04)], 12, 0.0, cap=False), T(0.0, yc, 0.0))
            # feet and the navy console under the sign (clear of its plinth and column)
            for s in (-1, 1):
                x0, x1 = s * FOOT_X[0], s * FOOT_X[1]
                B.box(NAVY, ((x0 + x1) / 2, (yf + LIP_Y[1]) / 2, 0.8), (abs(x1 - x0), LIP_Y[1] - yf, 1.6), open="-z")
            for a, b in ((-FOOT_X[0], -1.05), (1.15, FOOT_X[0])):
                B.box(NAVY, ((a + b) / 2, 0.5, 0.45), (b - a, 0.8, 0.9), open="-z")
                B.box(GLOW, ((a + b) / 2, 0.89, 0.5), (b - a - 0.5, 0.04, 0.12), open="-y", bevel=0)
        self.screen_bezel(B, t=0.16, depth=0.16)


THEME = Theme()
