# scripts/tools/blender/base_themes/themes/lake.py
# Lake = JUSTICE LEAGUE: "Hall of Justice" (owner art direction 2026-09-25: the Super Friends Hall of Justice, reference
# images 14 / 15; API v3.1: no Neon, no lights, a landmark behind the pen).
#   Landmark (behind the back fence): the Hall of Justice itself, facing the pen (drawn 12 % wider and taller than its
#   plan, S(HS, 1, HS)). Cream stone, a huge semicircular arch between two massive square pylons (stepped crowns, raised
#   panels, gold stars), "HALL OF" / "JUSTICE" in navy 3D relief letters along the arch band, the arch filled with deep
#   blue glass divided by vertical cream mullions, two central fins rising just above the arch, a ledge with a gold
#   band at the springing line over the glazed ground floor, the curved warm-grey vault rolling back into the flat roof
#   of a long body with vertical panels, the League shield (gold / blue / gold star) on the roof; a three-step terrace,
#   a white forecourt, low hedges, side lawns and small round trees. Its mass starts 10.4 studs behind the fence (the
#   default camera of a player at the back of the pen stays in front of it); everything nearer is low.
#   Pen = the plaza in front of the Hall: cream paving (the heroes' band along the fence), white walkways (a ring around
#   the pool, the entrance and the back walk that continues into the Hall's forecourt), six lawns with hedge lines, and
#   the light-blue reflecting pool with a cream coping; in its centre the golden STAR on a stone plinth with the
#   stylised red flame and its gold heart (all floor relief, h <= 0.3: the heroes walk over it).
#   Perimeter: a clean cream balustrade (moulded plinth, flat Art Deco balusters, a moulded rail with a gold top strip),
#   cream piers with gold caps, corner mini-pylons (stepped crowns, gold bands, gold stars). Gate: a LOW Art Deco portal
#   (two stepped pylons with raised panels and gold stars, a lintel with gold bands, the 3D Justice League badge on its
#   face) so that from the approach the Hall's arch and letters rise above it, framed by it. Terminal: a cream stone
#   pedestal with a gold frame around the upgrade sign (gold bezel), a gold star crest; a gold star toward the pen.

import math

import bmesh

from common import *

FLOOR, F_GREY, F_WALK, F_WATER, F_LAWN = "Floor_Base", "Floor_Grey", "Floor_Walk", "Floor_Water", "Floor_Lawn"
MARBLE, GOLD, BLUE = "Structure_Marble", "Structure_Gold", "Structure_Blue"
LEAF, BARK = "Structure_Leaf", "Structure_Bark"
C_GOLD, C_BLUE, C_FLAME = "Core_3D_Gold", "Core_3D_Blue", "Core_3D_Flame"
SAPPHIRE, SCREEN = "Neon_Emissive_Sapphire", "Neon_Emissive_Screen"

rect = rect_poly

# ----------------------------------------------------------------------------------------------------------------------
# the plaza (pen frame): paving band along the fence, the pool, walkways and lawns
# ----------------------------------------------------------------------------------------------------------------------

EDGE = 3.4          # the cream paving band along the fence (where the heroes stand)
POOL_V = 14.0       # the pool's half width (water)
POOL_BACK = 15.5    # the pool's half length = D - POOL_BACK (Std 10.75, Deep 16.0)
COPE = 1.0          # the coping's width outside the water
RING = 2.4          # the white walkway ring around the coping
GAP = 0.7           # cream paving between the walkways and the lawns
ENTRY_V = 3.95      # the entrance walkway's half width (= the gate passage)
BACK_V = 3.2        # the back walkway's half width (continues into the Hall's forecourt)
# the coping (swept around the water, ccw path: y = inward over the water, z up; floor work below 0.3)
COPING = [(-COPE, FLOOR_TOP), (0.14, FLOOR_TOP), (0.14, 0.22), (0.04, 0.28), (-COPE + 0.1, 0.28), (-COPE, 0.2)]

# ----------------------------------------------------------------------------------------------------------------------
# the balustrade (side frame: y outward, z up; the piers, corners, pylons and the terminal own the y = -0.62 line)
# ----------------------------------------------------------------------------------------------------------------------

PLINTH = [(-0.55, 0.0), (0.66, 0.0), (0.66, 0.4), (0.52, 0.54), (-0.41, 0.54), (-0.55, 0.4)]
RAIL = [(-0.46, 2.08), (0.58, 2.08), (0.58, 2.32), (0.46, 2.44), (-0.34, 2.44), (-0.46, 2.32)]
RAIL_GOLD = [(-0.2, 2.44), (0.32, 2.44), (0.32, 2.52), (-0.2, 2.52)]
BAL_W, BAL_T = 0.46, 0.3      # flat Art Deco baluster: width along the fence, thickness
BAL_Y = 0.06
BAL_N = 6                     # balusters per 10.5-stud span
PIER = 0.62                   # half width of a pier along the fence

# ----------------------------------------------------------------------------------------------------------------------
# the League shield (drawing plane: x right, y up; ~7 x 7.2 at scale 1) and its letters / star
# ----------------------------------------------------------------------------------------------------------------------

SHIELD = [(-2.3, 3.5), (-3.5, 2.3), (-3.5, -0.7), (-1.0, -3.7), (1.0, -3.7), (3.5, -0.7), (3.5, 2.3), (2.3, 3.5)]
J_GLYPH = [(0.0, 0.0), (1.6, 0.0), (1.6, 2.8), (0.96, 2.8), (0.96, 0.6), (0.6, 0.6), (0.6, 1.1), (0.0, 1.1)]
L_GLYPH = [(0.0, 0.0), (1.7, 0.0), (1.7, 0.6), (0.64, 0.6), (0.64, 2.8), (0.0, 2.8)]
ITALIC = 0.2

# the flame of the star sculpture (x right, y = up the flame): a round base, three tongues licking up and to the right
# (the middle one tallest), and a small golden heart low in the flame (a red flame with a gold heart, not an outline)
FLAME = [(0.0, -2.0), (1.2, -1.75), (2.0, -1.0), (2.35, 0.1), (2.2, 1.3), (1.95, 2.2), (2.35, 2.95), (2.75, 4.3),
         (1.8, 3.35), (1.3, 3.05), (1.35, 4.0), (1.1, 5.1), (0.45, 6.9), (-0.2, 5.5), (-0.55, 4.35), (-0.75, 3.35),
         (-1.1, 3.0), (-1.55, 3.85), (-2.15, 5.0), (-2.4, 3.65), (-2.45, 2.2), (-2.35, 0.6), (-2.0, -0.9),
         (-1.2, -1.75)]
FLAME_CORE = [(0.0, -1.0), (0.7, -0.8), (1.05, -0.2), (1.05, 0.6), (0.85, 1.35), (0.9, 2.1), (0.45, 1.7), (0.15, 2.9),
              (-0.35, 1.9), (-0.8, 1.2), (-1.05, 0.5), (-1.0, -0.25), (-0.65, -0.8)]

# ----------------------------------------------------------------------------------------------------------------------
# the Hall (landmark frame: x = the right of a player in the pen looking at it, y = depth away from the pen, z up)
# ----------------------------------------------------------------------------------------------------------------------

HS = 1.12           # the Hall's facade, letters and body are drawn in S(HS, 1, HS): 12 % wider and taller
H_FRONT = 10.4       # the pylons' front faces (the default player camera sits ~10.15 behind the back fence)
H_BACK = 23.6        # the body's back wall (the landmark zone ends at 24)
PYL_X = (13.2, 19.2)  # the outer pylons (|x|)
PYL_Y1 = 16.8
PYL_TOP = 20.4
ARCH_ZC = 7.2        # the arch's springing line (= the ledge top)
ARCH_RI, ARCH_RO = 10.6, 13.2
ARCH_Y = (10.9, 13.6)
FIN_X = (1.2, 3.0)   # the two central fins (|x|)
FIN_TOP = 22.6
GATE_TOP = 9.5       # the pen's gate pylons (low: the Hall's arch and letters show above the portal from the approach)
TERRACE = 1.35       # the terrace (3 steps) the ground floor stands on
BODY_TOP = 15.6
VAULT_END = 20.8     # where the vault disappears into the roof (the roof shield sits behind it)
MULLIONS = (4.5, 6.3, 8.0, 9.5)
TREES = ((24.7, 11.0), (24.7, 16.6), (24.7, 22.0))
SHRUBS = ((24.2, 3.4), (20.4, 5.6))   # low round shrubs near the fence (camera: h <= 3 within 8 studs)

# ----------------------------------------------------------------------------------------------------------------------
# block capitals (unit height 1.4, x 0..1, stroke 0.3): lists of simple polygons (a letter with a counter = two halves)
# ----------------------------------------------------------------------------------------------------------------------

_S = 0.3


def _halves(left):
    """A symmetric glyph from its left half (x 0..0.5): the two halves meet on x = 0.5."""
    return [left, [(1.0 - x, y) for x, y in reversed(left)]]


FONT = {
    "H": [[(0, 0), (_S, 0), (_S, 0.55), (1 - _S, 0.55), (1 - _S, 0), (1, 0), (1, 1.4), (1 - _S, 1.4), (1 - _S, 0.85),
           (_S, 0.85), (_S, 1.4), (0, 1.4)]],
    "A": _halves([(0, 0), (_S, 0), (_S, 0.5), (0.5, 0.5), (0.5, 0.8), (_S, 0.8), (_S, 1.1), (0.5, 1.1), (0.5, 1.4),
                  (0.3, 1.4), (0, 1.1)]),
    "L": [[(0, 0), (1, 0), (1, _S), (_S, _S), (_S, 1.4), (0, 1.4)]],
    "O": _halves([(0.22, 0), (0.5, 0), (0.5, _S), (_S, _S), (_S, 1.4 - _S), (0.5, 1.4 - _S), (0.5, 1.4), (0.22, 1.4),
                  (0, 1.18), (0, 0.22)]),
    "F": [[(0, 0), (_S, 0), (_S, 0.55), (0.82, 0.55), (0.82, 0.85), (_S, 0.85), (_S, 1.1), (1, 1.1), (1, 1.4), (0, 1.4)]],
    "J": [[(0.2, 0), (0.78, 0), (1, 0.22), (1, 1.4), (1 - _S, 1.4), (1 - _S, _S), (_S, _S), (_S, 0.48), (0, 0.48),
           (0, 0.2)]],
    "U": [[(0.22, 0), (0.78, 0), (1, 0.22), (1, 1.4), (1 - _S, 1.4), (1 - _S, _S), (_S, _S), (_S, 1.4), (0, 1.4),
           (0, 0.22)]],
    "S": [[(0, 0), (0.8, 0), (1, 0.2), (1, 0.85), (_S, 0.85), (_S, 1.1), (1, 1.1), (1, 1.4), (0.2, 1.4), (0, 1.2),
           (0, 0.55), (1 - _S, 0.55), (1 - _S, _S), (0, _S)]],
    "T": [[(0.35, 0), (0.65, 0), (0.65, 1.1), (1, 1.1), (1, 1.4), (0, 1.4), (0, 1.1), (0.35, 1.1)]],
    "I": [[(0.35, 0), (0.65, 0), (0.65, 1.4), (0.35, 1.4)]],
    "C": [[(0.22, 0), (1, 0), (1, _S), (_S, _S), (_S, 1.1), (1, 1.1), (1, 1.4), (0.22, 1.4), (0, 1.18), (0, 0.22)]],
    "E": [[(0, 0), (1, 0), (1, _S), (_S, _S), (_S, 0.55), (0.82, 0.55), (0.82, 0.85), (_S, 0.85), (_S, 1.1), (1, 1.1),
           (1, 1.4), (0, 1.4)]],
}
ADVANCE = {"I": 0.55, " ": 0.55}  # glyph advance in glyph units (default 1.0), + LETTER_GAP


def star_pts(r_out, r_in=None, n=5, rot=math.pi / 2, cx=0.0, cy=0.0):
    """Star outline (x, y), counter-clockwise, first point up."""
    r_in = r_out * 0.42 if r_in is None else r_in
    return [(cx + (r_out if k % 2 == 0 else r_in) * math.cos(rot + math.pi * k / n),
             cy + (r_out if k % 2 == 0 else r_in) * math.sin(rot + math.pi * k / n)) for k in range(2 * n)]


def glyph(pts, x0, y0, s=1.0):
    """A letter outline placed at (x0, y0), scaled by s and slanted (italic)."""
    return [(x0 + (x + ITALIC * y) * s, y0 + y * s) for x, y in pts]


def scaled(pts, s, dx=0.0, dy=0.0):
    return [(x * s + dx, y * s + dy) for x, y in pts]


def arc_poly(r, zc, a0, a1, n):
    """Circular segment in the XZ plane (centre (0, zc)): the arc a0..a1 closed by its chord."""
    return [(r * math.cos(a0 + (a1 - a0) * i / n), zc + r * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]


def bm_vault(zc, r0, r1, y0, y1, z_cut, n=14, m=7, p=3.0):
    """The Hall's curved vault roof: a smooth shell of circular arcs (centre (0, zc) in XZ) from y0 (radius r0, right
    behind the arch band) to y1 (radius r1), the radius shrinking along a superellipse (exponent p: the vault holds its
    height, then rolls down into the flat roof); every arc is cut at z_cut (inside the body). Capped at both ends."""
    bm = bmesh.new()
    k = (1.0 - (r1 / r0) ** p) ** (1.0 / p)
    rows = []
    for j in range(m + 1):
        t = j / m
        r = r0 * max(0.0, 1.0 - (k * t) ** p) ** (1.0 / p)
        a = math.asin(min(1.0, (z_cut - zc) / r))
        y = y0 + (y1 - y0) * t
        rows.append([bm.verts.new((r * math.cos(a + (math.pi - 2 * a) * i / n), y,
                                   zc + r * math.sin(a + (math.pi - 2 * a) * i / n))) for i in range(n + 1)])
    for ra, rb in zip(rows, rows[1:]):   # wound so the normals face out (up / sideways)
        for i in range(n):
            bm.faces.new((ra[i], rb[i], rb[i + 1], ra[i + 1]))
    bm.faces.new(list(reversed(rows[-1])))  # the back cap faces +y
    bm.faces.new(rows[0])                   # the front cap faces -y (its rim shows just above the arch band)
    return bm


class Theme(PenTheme):
    KEY, NAME, TITLE, FRANCHISE = "Lake", "HallOfJustice", "Hall of Justice", "Justice League"
    PALETTE = {
        FLOOR: look((226, 214, 188), "SmoothPlastic"),                          # warm cream paving
        F_GREY: look((198, 190, 172), "SmoothPlastic"),                         # the star's stone plinth
        F_WALK: look((247, 244, 235), "SmoothPlastic"),                         # white walkways
        F_WATER: look((104, 186, 236), "SmoothPlastic", reflectance=0.12),      # the reflecting pool
        F_LAWN: look((104, 174, 84), "Plastic"),
        MARBLE: look((238, 228, 204), "SmoothPlastic"),                         # the Hall's cream stone
        GOLD: look((238, 184, 62), "SmoothPlastic", reflectance=0.06, bevel=0.06),
        BLUE: look((30, 50, 112), "SmoothPlastic", bevel=0.05),                 # navy: letters, ground floor
        LEAF: look((62, 132, 72), "Plastic", bevel=0.12),
        BARK: look((116, 88, 66), "Plastic", bevel=0.03),
        C_GOLD: look((246, 190, 58), "SmoothPlastic", reflectance=0.06, bevel=0.04),
        C_BLUE: look((30, 64, 160), "SmoothPlastic", bevel=0.04),
        C_FLAME: look((232, 80, 36), "SmoothPlastic", bevel=0.03),
        SAPPHIRE: look((40, 76, 156), "SmoothPlastic", reflectance=0.12),       # the Hall's blue glass (no glow)
        SCREEN: look((240, 188, 64), "SmoothPlastic", reflectance=0.06),        # the terminal's gold bezel
    }
    EMBLEM_Z = 9.25
    EMBLEM_OUT = 1.8     # the badge sits on the lintel's front face (low: the Hall shows above it)
    STUDIO_RGB = (206, 212, 224)

    # -- floor: paving, the pool, walkways, lawns ---------------------------------------------------------------------
    def floor(self, B):
        W, D = B.W, B.D
        pv, pu = POOL_V, D - POOL_BACK
        z0 = FLOOR_TOP
        B.slab(FLOOR, (-W, -D, 0.0), (W, D, z0), open="-z", bevel=0)
        # the reflecting pool: the water sheet and the cream coping around it
        B.slab(F_WATER, (-pv, -pu, z0), (pv, pu, 0.15), open="-z", bevel=0)
        B.sweep_path(MARBLE, COPING, [(-pv, -pu), (pv, -pu), (pv, pu), (-pv, pu)], closed=True, bevel=0.04)
        # the white walkways: a ring around the coping (front / back full width, sides between them), the entrance
        # walk to the gate and the back walk toward the Hall
        wz = 0.14
        ov, ou = pv + COPE, pu + COPE          # the coping's outer edge
        rv, ru = ov + RING, ou + RING          # the ring's outer edge
        for s in (-1, 1):
            B.slab(F_WALK, (-rv, min(s * ou, s * ru), z0), (rv, max(s * ou, s * ru), wz), open="-z")
            B.slab(F_WALK, (min(s * ov, s * rv), -ou, z0), (max(s * ov, s * rv), ou, wz), open="-z")
        B.slab(F_WALK, (-ENTRY_V, ru, z0), (ENTRY_V, D, wz), open="-z")
        B.slab(F_WALK, (-BACK_V, -D, z0), (BACK_V, -ru, wz), open="-z")
        # gold stars set in the entrance walk
        for u in (D - 3.4, ru + 3.2):
            with B.frame(T(0.0, u, wz)):
                B.relief(star_pts(1.05), [(C_GOLD, 0.0, 0.0, 0.07, 0)])
        # six lawns between the walkways and the heroes' paving band
        lz = 0.16
        e = W - EDGE
        eu = D - EDGE
        for s in (-1, 1):
            B.slab(F_LAWN, (min(s * (rv + GAP), s * e), -eu, z0), (max(s * (rv + GAP), s * e), eu, lz), open="-z")
            B.slab(F_LAWN, (min(s * (ENTRY_V + GAP), s * rv), ru + GAP, z0), (max(s * (ENTRY_V + GAP), s * rv), eu, lz),
                   open="-z")
            B.slab(F_LAWN, (min(s * (BACK_V + GAP), s * rv), -eu, z0), (max(s * (BACK_V + GAP), s * rv), -(ru + GAP), lz),
                   open="-z")
        # dark hedge lines along the lawns' edges that face the pool (the reference's green borders), floor level
        hz, hw = 0.27, 0.55
        for s in (-1, 1):
            x0 = rv + GAP + 0.3
            B.slab(LEAF, (min(s * x0, s * (x0 + hw)), -eu + 0.3, lz), (max(s * x0, s * (x0 + hw)), eu - 0.3, hz), open="-z",
                   bevel=0.04)
            for u0, u1 in ((ru + GAP + 0.3, ru + GAP + 0.3 + hw), (-(ru + GAP + 0.3 + hw), -(ru + GAP + 0.3))):
                a = (ENTRY_V if u0 > 0 else BACK_V) + GAP + 0.3
                B.slab(LEAF, (min(s * a, s * (rv - 0.3)), u0, lz), (max(s * a, s * (rv - 0.3)), u1, hz), open="-z", bevel=0.04)

    # -- centre: the star sculpture in the pool (floor relief: the golden star and its flame) --------------------------
    def centerpiece(self, B):
        with B.frame(Rz(math.pi)):  # local +y toward the Hall: the flame rises toward it, a star point too
            B.relief(star_pts(7.2, 3.35), [(F_GREY, 0.0, 0.15, 0.19)])
            B.relief(star_pts(6.5, 3.0), [(C_GOLD, 0.0, 0.19, 0.23), (C_GOLD, 0.34, 0.23, 0.25)])
            with B.frame(T(0.0, -0.4, 0.0) @ S(1.05, 1.05, 1.0)):
                B.relief(FLAME, [(C_FLAME, 0.0, 0.15, 0.28, 0.02)])
                B.relief(FLAME_CORE, [(C_GOLD, 0.0, 0.26, 0.3, 0.015)])

    def shield(self, B, s, z0, roles):
        """The League shield in the frame's XY plane, standing on z0: a blue field, a gold rim (level 1), the italic gold
        "JL" and star (level 2)."""
        gold, blue = roles
        outline = ccw(scaled(SHIELD, s))
        lv1, top = z0 + 0.16, z0 + 0.38
        B.relief(offset_poly(outline, 0.2), [(blue, 0.0, z0, lv1 - 0.04)])
        B.sweep_path(gold, [(-0.08, z0), (0.2, z0), (0.2, lv1), (-0.08, lv1)], outline, closed=True, bevel=0.03)
        k = s * 0.95
        base = -1.75 * s
        for pts in (glyph(J_GLYPH, -2.05 * s, base, k), glyph(L_GLYPH, 0.3 * s, base, k)):
            B.relief(pts, [(gold, 0.0, lv1 - 0.04, top)])
        B.relief(star_pts(0.82 * s, cx=0.42 * s, cy=2.2 * s), [(gold, 0.0, lv1 - 0.04, top)])

    # -- perimeter: the cream balustrade -------------------------------------------------------------------------------
    def rail_run(self, B, side, L):
        x0, x1 = -L / 2, L / 2
        B.sweep(MARBLE, PLINTH, x0, x1, open_ends=(True, True))
        B.sweep(MARBLE, RAIL, x0, x1, open_ends=(True, True))
        B.sweep(GOLD, RAIL_GOLD, x0, x1, open_ends=(True, True), open="-z", bevel=0)

    def span(self, B, side, L, s0, s1):
        free = L - 2 * PIER
        g = (free - BAL_N * BAL_W) / (BAL_N + 1)
        for i in range(BAL_N):
            self.baluster(B, -L / 2 + PIER + g + BAL_W / 2 + i * (g + BAL_W))

    def baluster(self, B, x):
        """A flat Art Deco baluster between the plinth and the rail (open ends: they sink into both). Flat-shaded slab,
        no modifier bevel: ~110 of them per pen at 8 tris each (the balustrade's biggest line)."""
        B.box(MARBLE, (x, BAL_Y, 1.31), (BAL_W, BAL_T, 1.54), open="-z +z", bevel=0)

    def post(self, B, post):
        """A cream pier with a gold cap (the plinth and the rail run through it)."""
        B.slab(MARBLE, (-PIER, -0.62, 0.0), (PIER, 0.74, 2.86), open="-z")
        B.slab(GOLD, (-PIER - 0.12, -0.62, 2.86), (PIER + 0.12, 0.86, 3.04), open="-z", bevel=0.04)

    def corner(self, B):
        """A mini Hall pylon: cream block, gold band, stepped crown, gold cap, gold stars on the two outer faces
        (corner frame: within -0.62 .. 1.3 of both fence lines)."""
        a, b = -0.62, 1.12
        B.slab(MARBLE, (a, a, 0.0), (b, b, 6.0), open="-z")
        B.slab(GOLD, (a + 0.1, a + 0.1, 6.0), (b - 0.1, b - 0.1, 6.2), open="-z", bevel=0.04)
        B.slab(MARBLE, (a + 0.26, a + 0.26, 6.2), (b - 0.26, b - 0.26, 7.2), open="-z")
        B.slab(GOLD, (a + 0.46, a + 0.46, 7.2), (b - 0.46, b - 0.46, 7.42), open="-z", bevel=0.04)
        c = (a + b) / 2
        for normal, pos in (((1.0, 0.0), (b, c, 4.7)), ((0.0, 1.0), (c, b, 4.7))):
            with B.frame(T(*pos) @ facing(normal)):
                B.relief(star_pts(0.62), [(GOLD, 0.0, 0.0, 0.14, 0)])

    # -- gate: a low Art Deco portal (the Hall rises behind it: from the approach its arch and letters stay in view) -----
    def gate_pylon(self, B, side):
        # pylon frame: +X away from the passage (x >= -1.3 below h 7.5), +Y out of the pen, inner face on y -0.62
        x0, x1, y0, y1 = -1.3, 1.1, -0.62, 2.0
        B.slab(MARBLE, (x0, y0, 0.0), (x1, y1, GATE_TOP), open="-z")
        B.slab(GOLD, (x0 + 0.12, y0 + 0.12, GATE_TOP), (x1 - 0.12, y1 - 0.12, GATE_TOP + 0.18), open="-z", bevel=0.04)
        B.slab(MARBLE, (x0 + 0.3, y0 + 0.3, GATE_TOP + 0.18), (x1 - 0.3, y1 - 0.3, GATE_TOP + 0.9), open="-z")
        B.slab(MARBLE, (x0 + 0.6, y0 + 0.6, GATE_TOP + 0.9), (x1 - 0.6, y1 - 0.6, GATE_TOP + 1.4), open="-z", bevel=0.07)
        B.slab(GOLD, (x0 + 0.78, y0 + 0.78, GATE_TOP + 1.4), (x1 - 0.78, y1 - 0.78, GATE_TOP + 1.55), open="-z", bevel=0.03)
        # the raised front panel and its gold star (outside)
        xc = (x0 + x1) / 2
        B.slab(MARBLE, (x0 + 0.45, y1, 1.0), (x1 - 0.45, y1 + 0.16, GATE_TOP - 1.2), open="-y", bevel=0.05)
        with B.frame(T(xc, y1 + 0.16, GATE_TOP - 2.3) @ facing((0.0, 1.0))):
            B.relief(star_pts(0.62), [(GOLD, 0.0, 0.0, 0.12, 0)])

    def gate_lintel(self, B):
        # gate frame: X = +v, Y = outward; everything over the passage stays above h 7.55
        B.slab(MARBLE, (-5.0, -0.5, 7.55), (5.0, 1.8, 8.5))                                   # the lintel
        for s in (-1, 1):                                                                        # its gold bands
            B.slab(GOLD, (min(s * 2.0, s * 3.9), 1.8, 7.82), (max(s * 2.0, s * 3.9), 1.92, 8.2), open="-y", bevel=0.02)
        B.slab(MARBLE, (-4.3, -0.3, 8.5), (4.3, 1.6, 9.15), open="-z")                         # the attic step
        B.slab(MARBLE, (-1.25, -0.1, 8.5), (1.25, 1.8, 10.05), open="-z")                      # the badge's backing

    def emblem(self, B):
        # emblem frame: x = the viewer's right, y = up, +z toward the viewer (just in front of the arch crown)
        self.shield(B, 0.42, 0.0, (C_GOLD, C_BLUE))

    # -- terminal: the cream stone pedestal with a gold frame -------------------------------------------------------------
    def terminal(self, B):
        with B.frame(B.terminal_frame()):
            # terminal frame: x = v - 10.435, y = u - (D + 1.48): the fence line is y -1.48, the pen side ends at -2.1
            g0 = self.TERMINAL_GAP[0] - 10.435
            g1 = self.TERMINAL_GAP[1] - 10.435
            # the back plate closing the fence stretch, clear of the sign's plinth (u >= D + 0.49)
            B.slab(MARBLE, (g0, -1.98, 0.0), (g1, -1.0, 5.2), open="-z")
            # pilasters (the left one clear of the gate pylon at v 6.35), a gold frame on their faces
            for a, b in ((-4.0, -3.15), (3.15, 4.3)):
                B.slab(MARBLE, (a, -1.98, 0.0), (b, 0.8, 5.3), open="-z")
                B.slab(GOLD, (a + 0.14, 0.8, 0.5), (b - 0.14, 0.9, 5.0), open="-y", bevel=0.02)
            # the entablature with a gold band, the stepped crest and its gold star
            B.slab(MARBLE, (-4.2, -1.98, 5.3), (4.5, 0.82, 5.95))
            B.slab(GOLD, (-4.0, 0.82, 5.45), (4.3, 0.9, 5.8), open="-y", bevel=0.02)
            B.slab(MARBLE, (-2.4, -1.6, 5.95), (2.4, 0.5, 6.5), open="-z")
            with B.frame(T(0.0, 0.2, 7.25) @ facing((0.0, 1.0))):
                B.relief(star_pts(0.95), [(GOLD, 0.0, -0.3, 0.12, 0)], open_bottom=False)
            # toward the pen: a gold star on the back plate
            with B.frame(T(0.0, -1.98, 2.9) @ facing((0.0, -1.0))):
                B.relief(star_pts(0.95), [(GOLD, 0.0, 0.0, 0.12, 0)])
        self.screen_bezel(B)

    # -- landmark: the Hall of Justice ----------------------------------------------------------------------------------
    def landmark(self, B):
        # landmark frame: x = -v, +y away from the pen (1.3 .. 24), z up
        self.hall_grounds(B)
        with B.frame(S(HS, 1.0, HS)):
            self.hall_steps(B)
            self.hall_facade(B)
            self.hall_letters(B)
            self.hall_body(B)

    def hall_grounds(self, B):
        px0, px1 = PYL_X[0] * HS, PYL_X[1] * HS
        # the white forecourt continuing the back walk, the side lawns (L-shaped: in front of the pylons and beside
        # the body), low hedges along the forecourt, small round trees
        B.slab(F_WALK, (-px0, 1.3, 0.0), (px0, H_FRONT - 3.8, 0.12), open="-z", bevel=0)
        for s in (-1, 1):
            lawn = [(px0, 1.3), (27.9, 1.3), (27.9, 23.9), (px1 + 0.4, 23.9), (px1 + 0.4, H_FRONT - 0.2), (px0, H_FRONT - 0.2)]
            B.prism(F_LAWN, [(s * x, y) for x, y in lawn], 0.0, 0.14)
            B.slab(LEAF, (min(s * (px0 + 0.3), s * (px0 + 1.4)), 1.8, 0.0), (max(s * (px0 + 0.3), s * (px0 + 1.4)), 8.6, 1.0),
                   open="-z")
        for s in (-1, 1):
            for x, y in TREES:
                B.cyl(BARK, (s * x, y, 0.0), (s * x, y, 2.6), 0.34, n=6, bevel=0)
                B.mesh(LEAF, bm_sphere(2.1, 1), T(s * x, y, 4.3), bevel=0, smooth=True)
            for x, y in SHRUBS:
                B.mesh(LEAF, bm_sphere(1.3, 1), T(s * x, y, 1.45) @ S(1.0, 1.0, 0.95), bevel=0, smooth=True)

    def hall_steps(self, B):
        """The three-step terrace the Hall stands on (in the scaled Hall frame)."""
        px0 = PYL_X[0]
        steps = ((H_FRONT - 3.8, 0.0, 0.45), (H_FRONT - 2.6, 0.45, 0.9), (H_FRONT - 1.4, 0.9, TERRACE))
        for y0, z0, z1 in steps:
            B.slab(MARBLE, (-px0, y0, z0), (px0, ARCH_Y[1], z1), open="-z", bevel=0.08)

    def hall_facade(self, B):
        px0, px1 = PYL_X
        zc, ri, ro = ARCH_ZC, ARCH_RI, ARCH_RO
        ay0, ay1 = ARCH_Y
        for s in (-1, 1):
            def xs(a, b):
                return min(s * a, s * b), max(s * a, s * b)
            # the outer pylon: block, setback crown, cap
            x0, x1 = xs(px0, px1)
            B.slab(MARBLE, (x0, H_FRONT, 0.0), (x1, PYL_Y1, PYL_TOP), open="-z", bevel=0.2)
            x0, x1 = xs(px0 + 0.3, px1 - 0.3)
            B.slab(GOLD, (x0, H_FRONT + 0.3, PYL_TOP), (x1, PYL_Y1 - 0.3, PYL_TOP + 0.3), open="-z", bevel=0.08)
            x0, x1 = xs(px0 + 0.6, px1 - 0.6)
            B.slab(MARBLE, (x0, H_FRONT + 0.6, PYL_TOP + 0.3), (x1, PYL_Y1 - 0.6, PYL_TOP + 1.3), open="-z", bevel=0.16)
            x0, x1 = xs(px0 + 1.3, px1 - 1.3)
            B.slab(MARBLE, (x0, H_FRONT + 1.3, PYL_TOP + 1.3), (x1, PYL_Y1 - 1.3, PYL_TOP + 1.9), open="-z", bevel=0.12)
            # raised front panel with a vertical rib and a gold star; a raised panel on the outer side
            x0, x1 = xs(px0 + 1.0, px1 - 1.0)
            B.slab(MARBLE, (x0, H_FRONT - 0.2, 1.8), (x1, H_FRONT, 18.8), open="+y", bevel=0.1)
            xm = s * (px0 + px1) / 2
            B.slab(MARBLE, (xm - 0.26, H_FRONT - 0.36, 3.0), (xm + 0.26, H_FRONT - 0.2, 14.6), open="+y", bevel=0.06)
            with B.frame(T(xm, H_FRONT - 0.2, 16.7) @ facing((0.0, -1.0))):
                B.relief(star_pts(1.4), [(GOLD, 0.0, 0.0, 0.24, 0.06)])
            x0, x1 = xs(px1, px1 + 0.2)
            B.slab(MARBLE, (x0, H_FRONT + 1.0, 1.8), (x1, PYL_Y1 - 1.0, 18.8), open=("-x" if s > 0 else "+x"), bevel=0.1)
            # the arch's jambs down to the terrace
            x0, x1 = xs(ri, px0)
            B.slab(MARBLE, (x0, ay0, TERRACE), (x1, ay1, zc), open="-z +z")
            # the central fins rising above the arch, with a stepped cap
            x0, x1 = xs(*FIN_X)
            B.slab(MARBLE, (x0, H_FRONT - 0.2, TERRACE), (x1, 15.5, FIN_TOP), open="-z", bevel=0.16)
            x0, x1 = xs(FIN_X[0] + 0.25, FIN_X[1] - 0.25)
            B.slab(MARBLE, (x0, H_FRONT + 0.1, FIN_TOP), (x1, 15.2, FIN_TOP + 0.8), open="-z", bevel=0.1)
        # the arch band and the blue glass fan behind it, cream mullions in front of the glass
        B.arch(MARBLE, (0.0, (ay0 + ay1) / 2, zc), ri, ro, ay1 - ay0, 0.0, math.pi, n=24, bevel=0.15)
        B.plate(SAPPHIRE, arc_poly(ri + 0.22, zc, 0.0, math.pi, 12), 12.9, 13.3)
        for x in MULLIONS:
            top = zc + math.sqrt(ri ** 2 - x ** 2) + 0.2
            for s in (-1, 1):
                B.slab(MARBLE, (s * x - 0.18, 12.45, zc), (s * x + 0.18, 12.9, top), open="-z +z +y", bevel=0.05)
        # the ledge at the springing line, the dark ground floor with its piers and entrance
        B.slab(MARBLE, (-ri, 10.0, zc - 0.7), (ri, 13.0, zc), bevel=0.12)
        B.slab(GOLD, (-ri + 0.2, 9.9, zc - 0.48), (ri - 0.2, 10.0, zc - 0.26), open="+y", bevel=0)
        B.slab(BLUE, (-ri, 13.0, TERRACE), (ri, 13.3, zc - 0.7), open="-z +z +y", bevel=0)
        for x in (-7.8, -5.2, 5.2, 7.8):
            B.slab(MARBLE, (x - 0.45, 11.6, TERRACE), (x + 0.45, 13.0, zc - 0.7), open="-z +z +y", bevel=0.08)

    def hall_letters(self, B):
        """HALL OF up the left of the arch band, JUSTICE down its right: navy block capitals in relief, their tops
        pointing out of the arch (drawn on the band's front face, facing the pen)."""
        k = 1.28                     # glyph scale (1.4 units -> 1.8 studs)
        gap = 0.2
        r_mid = (ARCH_RI + ARCH_RO) / 2
        y_face = ARCH_Y[0]
        for word, centre in (("HALL OF", math.radians(137.0)), ("JUSTICE", math.radians(43.0))):
            adv = [(ADVANCE.get(ch, 1.0) * k + gap) for ch in word]
            total = sum(adv) - gap
            t = centre + (total / 2) / r_mid     # arc position of the first letter's start (reading clockwise)
            for ch, a in zip(word, adv):
                w = ADVANCE.get(ch, 1.0) * k
                theta = t - (w / 2) / r_mid
                t -= a / r_mid
                if ch == " ":
                    continue
                px, pz = r_mid * math.cos(theta), ARCH_ZC + r_mid * math.sin(theta)
                with B.frame(T(px, y_face, pz) @ facing((0.0, -1.0)) @ Rz(theta - math.pi / 2)):
                    for poly in FONT[ch]:
                        pts = [((x - 0.5) * k, (y - 0.7) * k) for x, y in poly]
                        B.relief(pts, [(BLUE, 0.0, 0.0, 0.3, 0)])

    def hall_body(self, B):
        px1 = PYL_X[1]
        # the long body, its cornice, pilaster panels along both sides, the curved vault over the front part
        B.slab(MARBLE, (-px1, ARCH_Y[1], 0.0), (px1, H_BACK, BODY_TOP), open="-z", bevel=0.2)
        B.slab(MARBLE, (-px1 - 0.3, PYL_Y1 - 0.2, BODY_TOP - 0.4), (px1 + 0.3, H_BACK + 0.3, BODY_TOP + 0.4), bevel=0.12)
        for s in (-1, 1):
            for y in (18.6, 21.0, 23.25):
                x0, x1 = min(s * px1, s * (px1 + 0.3)), max(s * px1, s * (px1 + 0.3))
                B.slab(MARBLE, (x0, y - 0.45, 0.0), (x1, y + 0.45, BODY_TOP - 0.4), open="-z " + ("-x" if s > 0 else "+x"),
                       bevel=0.08)
        # the back wall's vertical panels (it faces the hub: no blank slab)
        for x in (-16.8, -12.6, -8.4, -4.2, 0.0, 4.2, 8.4, 12.6, 16.8):
            B.slab(MARBLE, (x - 0.5, H_BACK, 0.0), (x + 0.5, H_BACK + 0.25, BODY_TOP - 0.4), open="-z -y", bevel=0.06)
        # the curved vault behind the arch, dipping into the flat roof
        B.mesh(F_GREY, bm_vault(ARCH_ZC, ARCH_RO + 0.35, BODY_TOP + 0.55 - ARCH_ZC, ARCH_Y[1] + 0.02, VAULT_END,
                                BODY_TOP - 0.1),
               bevel=0, smooth=True)   # a warm grey stone shell (reference 15), a notch darker than the walls
        # the League's gold shield on the flat roof behind it (reference 15): gold rim, blue field, gold star (seen
        # from above only, so no letters)
        with B.frame(T(0.0, 22.3, BODY_TOP + 0.4) @ S(1.0 / HS, 1.0, 1.0)):
            outline = ccw(scaled(SHIELD, 0.34))
            B.relief(outline, [(GOLD, 0.0, 0.0, 0.14, 0.04), (BLUE, 0.26, 0.14, 0.2, 0)])
            B.relief(star_pts(0.72), [(GOLD, 0.0, 0.2, 0.32, 0)])


THEME = Theme()
