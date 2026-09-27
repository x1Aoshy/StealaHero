# scripts/tools/blender/base_themes/themes/jungle.py
# Jungle = MY HERO ACADEMIA: "U.A. Hero Arena", minimalist redesign 2026-09-25 (owner: "make it a bit more minimalist,
# with the U.A. buildings identical to the reference, with the glass buildings and the logos, but NOT the trees").
# Reference: the U.A. High School front (twin glass towers behind the blue gate). API v3.1 (common.py header), no Neon,
# no lights; the landmark lives in PenTheme.landmark() (Jungle is a LANDMARK_KEYS theme).
#   Perimeter: the U.A. campus wall: cream panels with recessed V joints under a cream coping, a teal glass band framed
#   by gold rails and slim gold posts (one per panel joint). Corners: square cream piers with a gold collar and a white
#   crown. Gate: the bold blue DOUBLE-FRAME arch with chamfered top corners (an outer blue frame, a white piping line, a
#   recessed inner blue frame) standing on white plinths, the gold U.A. plaque on its crown (the logo of the reference:
#   a 3D gold U holding a 3D gold A, the navy backing showing through the gaps and the A's counter). Floor: clean light
#   plaza plates, the terracotta path running from the gate through the pen to the back wall (white edging), and the
#   U.A. badge in the middle (the same gold logo on a navy plate in a white rim).
#   Terminal: the same double frame in miniature (cream / white / blue) around the upgrade sign, a cream back panel, a
#   gold bezel and a small gold U.A. plaque on its crown.
#   Landmark (behind the back wall): the U.A. building of the reference: two tall deep-blue glass towers with thin white
#   mullions (8 bays), dark floor bands (14 floors: nearly square panes), white corner fins and a white parapet rim
#   around a light-grey roof with a rooftop unit, one diagonal streak of light panes (the sky reflection) on each front;
#   between them the lower glass block (white mullions, white roof railing), the projecting sky bridge (white frame,
#   2 x 6 light-glass windows) and the white portico lobby with a gold U.A. plaque, everything on a white base; in
#   front, the terracotta path between two lawns and a white walkway. No trees. Mass >= 12 studs behind the back fence
#   (the default camera stays in front of it: only flat lawns and paths, h <= 0.15, in the first 10.5 studs).

import math

import bmesh

from common import *

FLOOR, TURF, F_WHITE = "Floor_Base", "Floor_Turf", "Floor_White"
WHITE, NAVY, RED = "Structure_White", "Structure_Navy", "Structure_Red"   # NAVY = the U.A. blue; RED = terracotta
BEIGE, GLASS, ROOF = "Structure_Beige", "Structure_Glass", "Structure_Silver"
C_GOLD, C_WHITE, C_NAVY = "Core_3D_Gold", "Core_3D_White", "Core_3D_Navy"
GREEN, LAMP, SCREEN = "Neon_Emissive_Green", "Neon_Emissive_Lamp", "Neon_Emissive_Screen"  # teal band, sky glass, bezel

# -- the campus wall (side frame: y outward, z up; the pen side stays at y >= -0.56)
PANEL_H = 2.6
PANEL_T = 0.5            # half thickness of the cream panels
FIN_EDGE = 0.15          # the panels' bevel: two neighbouring panels make the recessed V joint of the reference
COPING = rect_profile(-0.56, 0.56, PANEL_H, PANEL_H + 0.12)
RAIL_LOW = rect_profile(-0.19, 0.19, PANEL_H + 0.12, PANEL_H + 0.22)
BAND = rect_profile(-0.085, 0.085, PANEL_H + 0.22, PANEL_H + 1.12)
RAIL_TOP = rect_profile(-0.2, 0.2, PANEL_H + 1.12, PANEL_H + 1.26)
WALL_TOP = PANEL_H + 1.26
PITCH = 3.5              # panel joints (a gold post above each)

# -- the corner pier (corner frame: x, y outward from the corner, pier centre at (0.3, 0.3): -0.58 .. 1.18)
PIER_C, PIER_R = 0.3, 0.88
# the pier crown (loft sections: z, half size): a chamfered white cap over the pier
MAST_RIB = [(WALL_TOP, PIER_R + 0.04), (WALL_TOP + 0.26, PIER_R + 0.04), (WALL_TOP + 0.44, PIER_R - 0.2)]

# -- the gate arch (gate frame: X = +v, Y outward, Z up). Every arch ring is split at SPLIT_Z into two legs and a crown
#    (the gate-passage contract checks each piece's box); the seam faces are dropped so the ring reads as one piece.
SPLIT_Z = GATE_CLEAR_H
ARCH_OUT = 6.43          # the outer faces (the terminal starts at v 6.435)
ARCH_IN = 4.0            # the passage (>= 3.95)
OUTER = (ARCH_OUT, 10.2, 1.7)   # (half width, top, chamfer) of the outline
MID = (5.18, 9.55, 1.12)        # the white piping line between the two frames
INNER = (ARCH_IN, 8.7, 0.9)
PIPE = 0.17
ARCH_Y = (-0.56, 1.9)     # the outer frame's depth (pen side .. front)
INNER_FRONT = 1.62       # the inner frame is recessed
PLAQUE_S = 1.9           # the gate plaque's height (LOGO_W times as wide)
PIPE_FRONT = 1.76

# -- the terminal (terminal frame: x = v - 10.435, y = u - (D + 1.48); fence line y -1.48, pen side >= -2.1)
T_OUTER = (4.0, 6.25, 0.95)
T_MID = (3.52, 5.8, 0.62)
T_INNER = (3.05, 5.35, 0.5)
T_SPLIT = 4.74           # the sign's top is h 4.69
T_Y = (-1.98, 0.64)
TERM_V = ((SIGN_V[0] + SIGN_V[1]) / 2 - T_OUTER[0], (SIGN_V[0] + SIGN_V[1]) / 2 + T_OUTER[0])

# -- the landmark (landmark frame: x = -v, y = depth behind the back fence line, z up; symmetric about x = 0)
TX = (3.45, 20.2)        # each tower's x span (16.75 wide), the gap between them 6.9
TY = (12.0, 23.2)        # the towers' depth span (the default camera stays in front: <= ~11 behind the fence)
BASE_Z = 1.0             # the white base
TOP_Z = 32.3             # the glass top, under the white parapet
PARAPET = 0.9            # the white parapet rim above the glass
FLOORS = 14              # dark floor bands: nearly square panes, as on the reference
BAY = 2.1                # mullion pitch
STREAK = 4               # the light-pane reflection streak on the tower fronts: row k - column i in STREAK .. +1
CONN_Y = (16.0, 22.6)    # the lower central glass block between the towers
CONN_TOP = 24.0
BRIDGE_Z = (12.4, 19.2)  # the sky bridge (white frame) projecting in front of the towers
BRIDGE_Y0 = 11.3

# -- the U.A. logo of the reference plaque (drawing plane: x right, y up; 1.0 tall, LOGO_W wide, centred): a gold U
#    whose cavity holds a gold A, the navy backing showing through the thin gaps, the A's counter and the two dark
#    wedges beside its flat top (the plaque reads as a gold block cut by dark "U A" lines, like the reference).
LOGO_W = 1.6
U_OUT = [(-0.8, 0.5), (-0.8, -0.5), (0.8, -0.5), (0.8, 0.5), (0.5, 0.5), (0.5, -0.34), (-0.5, -0.34), (-0.5, 0.5)]
# the A is drawn in two halves (its counter is a notch in each) that meet on an open seam at x 0: plain n-gon caps
A_HALF = [(-0.43, -0.27), (-0.2, -0.27), (-0.15, -0.1), (0.0, -0.1), (0.0, 0.04), (-0.1, 0.04), (0.0, 0.3),
          (0.0, 0.5), (-0.2, 0.5)]


def sc(poly, s, dx=0.0, dy=0.0):
    return [(x * s + dx, y * s + dy) for x, y in poly]


def glyphs_ua(s):
    """The U.A. logo as [(outline, seam_x)] in a drawing plane, s tall, LOGO_W * s wide, centred on the origin;
    seam_x = the x of the open seam of the A's two halves (None for the U)."""
    half = sc(A_HALF, s)
    return [(sc(U_OUT, s), None), (half, 0.0), ([(-x, y) for x, y in reversed(half)], 0.0)]


def ua_letters(B, s, z0, z1, role="Core_3D_Gold", bevel=None):
    """The 3D U.A. logo s tall, standing z0..z1 on the current drawing plane (bottoms open, the A's seam open)."""
    for poly, seam in glyphs_ua(s):
        bm = bm_prism(poly, z0, z1, cap_bottom=False)
        if seam is not None:
            dead = [f for f in bm.faces if all(abs(v.co.x - seam) < 1e-5 for v in f.verts)]
            bmesh.ops.delete(bm, geom=dead, context="FACES_ONLY")
        B.mesh(role, bm, bevel=bevel)


def ua_plaque(B, s, depth, face=0.04, relief=None):
    """The gold U.A. plaque of the reference in the current drawing plane (x right, y up, +z toward the viewer), s tall,
    LOGO_W * s wide: a gold block from z -depth to 0 (gold from behind and on its edges), the navy backing face and the
    gold U + A standing proud of it."""
    relief = relief if relief is not None else min(0.14, 0.09 * s)
    w = LOGO_W * s
    B.box(C_GOLD, (0.0, 0.0, -depth / 2), (w, s, depth), open="+z", bevel=min(0.06, 0.05 * s))
    B.box(C_NAVY, (0.0, 0.0, face / 2), (w - 0.02, s - 0.02, face), open="-z", bevel=0)
    ua_letters(B, s, face, face + relief, bevel=min(0.035, 0.3 * relief))


def _drop_plane(bm, z):
    """Deletes the prism side faces lying on the outline height z (prism local y == z): the hidden seam of a split ring."""
    dead = [f for f in bm.faces if all(abs(v.co.y - z) < 1e-4 for v in f.verts)]
    bmesh.ops.delete(bm, geom=dead, context="FACES_ONLY")


PLATE_FLIP = basis((1.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, 1.0, 0.0))


def plate_open(B, role, poly, y0, y1, seam_z=(), bevel=None, segs=None):
    """B.plate (outline (x, z) extruded along y0..y1) with the faces on the seam heights seam_z dropped."""
    bm = bm_prism(poly, y0, y1)
    for z in seam_z:
        _drop_plane(bm, z)
    B.mesh(role, bm, PLATE_FLIP, bevel=bevel, segs=segs)


def arch_ring(B, role, out, inn, y0, y1, split, bevel=None):
    """A frame ring between two chamfered arch outlines out / inn = (half, top, chamfer), extruded y0..y1, cut at
    `split` into two legs (plain rectangles below it) and the crown (above it); the seams are open, so the ring reads
    as one piece. Both outlines must still be vertical at `split`."""
    oh, ot, oc = out
    ih, it, ic = inn
    assert ot - oc >= split - 1e-6 and it - ic >= split - 1e-6, "arch outlines must be vertical at the split"
    for s in (-1, 1):
        x0, x1 = sorted((s * ih, s * oh))
        plate_open(B, role, [(x0, 0.0), (x1, 0.0), (x1, split), (x0, split)], y0, y1, (split,), bevel=bevel)
    poly = [(-oh, split), (-ih, split), (-ih, it - ic), (-ih + ic, it), (ih - ic, it), (ih, it - ic), (ih, split),
            (oh, split), (oh, ot - oc), (oh - oc, ot), (-oh + oc, ot), (-oh, ot - oc)]
    plate_open(B, role, poly, y0, y1, (split,), bevel=bevel)


def offset_arch(a, d):
    """The arch outline (half, top, chamfer) moved inward by d (45-degree chamfer)."""
    return (a[0] - d, a[1] - d, max(0.05, a[2] - d * (2.0 - math.sqrt(2.0))))


class Theme(PenTheme):
    KEY, NAME, TITLE, FRANCHISE = "Jungle", "UAHeroArena", "U.A. Hero Arena", "My Hero Academia"
    PALETTE = {
        FLOOR: look((222, 221, 214), "Plastic"),                                   # light plaza plates
        TURF: look((92, 168, 76), "Plastic"),                                      # the campus lawns
        F_WHITE: look((246, 246, 243), "SmoothPlastic"),                           # edging, walkways
        WHITE: look((244, 246, 250), "SmoothPlastic", bevel=0.08),                 # mullions, parapets, base, piping
        NAVY: look((46, 70, 206), "SmoothPlastic", reflectance=0.03, bevel=0.1),   # the U.A. blue of the gate arch
        RED: look((178, 88, 64), "Plastic", bevel=0.03),                           # terracotta path
        BEIGE: look((228, 214, 168), "SmoothPlastic", bevel=FIN_EDGE),             # cream wall panels
        GLASS: look((24, 74, 180), "SmoothPlastic", reflectance=0.14, bevel=0),    # deep blue curtain walls
        ROOF: look((196, 202, 212), "SmoothPlastic", bevel=0.06),                 # the towers' roofs, rooftop units
        C_GOLD: look((244, 200, 42), "SmoothPlastic", reflectance=0.06, bevel=0.04),
        C_WHITE: look((248, 248, 250), "SmoothPlastic", bevel=0.04),
        C_NAVY: look((20, 32, 78), "SmoothPlastic", bevel=0),                      # letter faces, floor bands
        GREEN: look((64, 158, 146), "SmoothPlastic", reflectance=0.08),            # the teal glass band (no glow)
        LAMP: look((74, 146, 222), "SmoothPlastic", reflectance=0.1),              # light sky glass (bridge, lobby)
        SCREEN: look((244, 200, 42), "SmoothPlastic", reflectance=0.06),           # the gold bezel of the sign
    }
    TILES = {"Std": (5, 5), "Deep": (5, 6)}   # 10.5-stud plaza plates
    EMBLEM_Z = OUTER[1]                       # the plaque straddles the arch crown
    EMBLEM_OUT = ARCH_Y[1]
    STUDIO_RGB = (204, 212, 222)
    PATH_HALF = 3.0
    BADGE = (5.75, 3.85, 0.9)                 # the floor badge's half size + corner cut
    BADGE_LOGO = 6.1                          # the floor logo's height (LOGO_W times as wide)

    # -- floor: plaza plates, the terracotta path, the U.A. badge ----------------------------------------------------
    def path(self, B, u0, u1, z0, z1, pitch=3.5):
        """Terracotta pavers (two per row) from u0 to u1 with white edging, standing on z0 (floor top or ground)."""
        ph = self.PATH_HALF
        n = max(1, int(round((u1 - u0) / pitch)))
        step = (u1 - u0) / n
        for j in range(n):
            for x0, x1 in ((-ph, 0.0), (0.0, ph)):
                B.mesh(RED, bm_tile(x1 - x0 - 0.06, step - 0.06, 0.05, z0, z1), T((x0 + x1) / 2, u0 + step * (j + 0.5), 0.0),
                       bevel=0)
        for s in (-1, 1):
            x0, x1 = sorted((s * ph, s * (ph + 0.28)))
            B.slab(F_WHITE, (x0, u0, z0), (x1, u1, z1 + 0.01), open="-z", bevel=0)

    def floor(self, B):
        W, D = B.W, B.D
        nx, ny = self.TILES[B.variant]
        B.tiles(FLOOR, -W, -D, W, D, nx, ny, inset=0.22)
        by = self.BADGE[1]
        self.path(B, by + 0.02, D, FLOOR_TOP, 0.17)               # gate -> badge
        self.path(B, -D + 0.52, -by - 0.02, FLOOR_TOP, 0.17)      # badge -> back wall (and on to the U.A. building)
        self.path(B, D, D + 2.3, 0.0, 0.17, pitch=2.3)             # through the arch

    # -- centre: the U.A. badge (the gold U.A. logo on a navy plate in a white rim) -------------------------------------
    def centerpiece(self, B):
        bx, by, k = self.BADGE
        outline = rect_poly(-bx, bx, -by, by, k)
        B.relief(outline, [(C_WHITE, 0.0, FLOOR_TOP, 0.2, 0.05)])
        B.relief(offset_poly(outline, 0.42), [(C_NAVY, 0.0, 0.2, 0.22, 0)])
        # the logo reads upright for someone walking in from the gate (local x = -v, local y = -u)
        with B.frame(Rz(math.pi)):
            ua_letters(B, self.BADGE_LOGO, 0.22, 0.3, bevel=0.04)

    # -- perimeter: cream panels, teal glass band between gold rails, gold posts, corner piers ------------------------
    def fence(self, B):
        D, W = B.D, B.W
        runs = [("back", -W, W), ("left", -D, D), ("right", -D, D), ("front", -W, -ARCH_OUT), ("front", TERM_V[1], W)]
        outs = {"back": ("x", -1, (0.0, -1.0)), "front": ("x", 1, (0.0, 1.0)), "left": ("y", -1, (-1.0, 0.0)),
                "right": ("y", 1, (1.0, 0.0))}
        for side, s0, s1 in runs:
            with B.module("run"), B.frame(B.side_frame(side, (s0 + s1) / 2)):
                self.rail_run(B, side, s1 - s0)
            n = max(1, int(round((s1 - s0) / PITCH)))
            cuts = [s0 + (s1 - s0) * i / n for i in range(n + 1)]
            for a, b in zip(cuts, cuts[1:]):
                with B.module("span"), B.frame(B.side_frame(side, (a + b) / 2)):
                    self.span(B, side, b - a, a, b)
            axis, sign, out = outs[side]
            for s in cuts[1:-1]:
                x, y = (s, sign * D) if axis == "x" else (sign * W, s)
                with B.module("post"), B.frame(B.side_frame(side, s)):
                    self.post(B, Post("post", x, y, side, out))
        for sx in (-1, 1):
            for sy in (-1, 1):
                with B.module("corner"), B.frame(B.corner_frame(sx, sy)):
                    self.corner(B)

    def rail_run(self, B, side, L):
        """The continuous parts of a run: the cream coping, the gold rails and the teal glass band between them."""
        x0, x1 = -L / 2, L / 2
        B.sweep(BEIGE, COPING, x0, x1, open_ends=(True, True), open="-z", bevel=0.06)
        B.sweep(C_GOLD, RAIL_LOW, x0, x1, open_ends=(True, True), open="-z", bevel=0.03)
        B.sweep(GREEN, BAND, x0, x1, open_ends=(True, True), open="-z +z", bevel=0)
        B.sweep(C_GOLD, RAIL_TOP, x0, x1, open_ends=(True, True), open="-z", bevel=0.04)

    def span(self, B, side, L, s0, s1):
        """One cream wall panel (the bevel of two neighbours makes the recessed V joint)."""
        B.box(BEIGE, (0.0, 0.0, PANEL_H / 2), (L, 2 * PANEL_T, PANEL_H), open="-z +z")

    def post(self, B, post):
        """The slim gold post of the glass band over a panel joint."""
        B.box(C_GOLD, (0.0, 0.0, PANEL_H + 0.67), (0.2, 0.25, 0.9), open="-z +z", bevel=0)

    def corner(self, B):
        """A square cream pier, a gold collar at the rail line and a chamfered white crown."""
        c, r = PIER_C, PIER_R
        B.column(BEIGE, c, c, [(0.0, r, r), (WALL_TOP, r, r)], chamfer=0.14)
        B.box(C_GOLD, (c, c, PANEL_H + 0.17), (2 * r + 0.04, 2 * r + 0.04, 0.1), open="-z", bevel=0.03)
        B.box(C_GOLD, (c, c, PANEL_H + 1.19), (2 * r + 0.04, 2 * r + 0.04, 0.14), open="-z", bevel=0.03)
        B.loft(WHITE, [(z, rect_poly(c - h, c + h, c - h, c + h, 0.12)) for z, h in MAST_RIB])

    # -- gate: the blue double-frame arch and the gold UA plaque ---------------------------------------------------------
    def gate_pylon(self, B, side):
        """The white plinth under each arch leg (pylon frame: +X away from the passage, x >= -1.3 below h 7.5)."""
        x0, x1 = ARCH_IN - GATE_V - 0.03, ARCH_OUT - GATE_V - 0.06
        y0, y1 = ARCH_Y[0] - 0.02, ARCH_Y[1] + 0.22
        B.box(WHITE, ((x0 + x1) / 2, (y0 + y1) / 2, 0.21), (x1 - x0, y1 - y0, 0.42), open="-z", bevel=0.06)

    def gate_lintel(self, B):
        """The whole arch (gate frame): the outer blue frame, the white piping line, the recessed inner blue frame."""
        y0, y1 = ARCH_Y
        pipe_in = offset_arch(MID, PIPE)
        arch_ring(B, NAVY, OUTER, MID, y0, y1, SPLIT_Z)
        arch_ring(B, WHITE, MID, pipe_in, y0 + 0.1, PIPE_FRONT, SPLIT_Z, bevel=0.03)
        arch_ring(B, NAVY, pipe_in, INNER, y0, INNER_FRONT, SPLIT_Z)

    def emblem(self, B):
        # emblem frame: x = the viewer's right, y = up, +z toward the viewer (z 0 = the arch's front face). As on the
        # reference, the gold U.A. plaque is mounted on the crown's front face and rises above the crown.
        with B.frame(T(0.0, 0.0, 0.02)):
            ua_plaque(B, PLAQUE_S, 0.8)

    # -- terminal: the blue double frame in miniature around the upgrade sign -------------------------------------------
    def terminal(self, B):
        with B.frame(B.terminal_frame()):
            y0, y1 = T_Y
            pipe_in = offset_arch(T_MID, 0.13)
            # the cream back panel inside the frame (behind the sign, clear of its plinth at y >= -0.99)
            B.box(BEIGE, (0.0, y0 + 0.49, T_INNER[1] / 2), (2 * T_INNER[0] + 0.1, 0.98, T_INNER[1] + 0.02), open="-z",
                  bevel=0.08)
            arch_ring(B, BEIGE, T_OUTER, T_MID, y0, y1, T_SPLIT, bevel=0.08)
            arch_ring(B, WHITE, T_MID, pipe_in, y0 + 0.1, y1 - 0.08, T_SPLIT, bevel=0.025)
            arch_ring(B, NAVY, pipe_in, T_INNER, y0, y1 - 0.16, T_SPLIT, bevel=0.06)
            # a small gold U.A. plaque on the crown (as on the gate arch)
            with B.frame(T(0.0, y1 + 0.02, T_OUTER[1] - 0.05) @ facing((0.0, 1.0))):
                ua_plaque(B, 0.95, 0.5)
        self.screen_bezel(B)

    # -- landmark: the U.A. building of the reference -----------------------------------------------------------------
    def landmark(self, B):
        with B.module("plaza"):
            self.plaza(B)
        with B.module("towers"):
            for s in (-1, 1):
                self.tower(B, s)
        with B.module("centre block"):
            self.centre_block(B)

    def plaza(self, B):
        """The low forecourt (h <= 0.2 in the first studs: the player's camera stays clear): lawns, the terracotta path,
        a white walkway and the white base with its entrance step."""
        ph = self.PATH_HALF
        y0, yw, yb = 1.4, 9.7, 11.1
        self.path(B, y0, yw, 0.0, 0.14)
        for s in (-1, 1):
            x0, x1 = sorted((s * (ph + 0.28), s * 19.6))
            B.slab(TURF, (x0, y0, 0.0), (x1, yw, 0.12), open="-z", bevel=0.03)
        B.slab(F_WHITE, (-19.6, yw, 0.0), (19.6, yb, 0.15), open="-z", bevel=0.03)
        # the white base under the whole building and the entrance step
        B.slab(WHITE, (-19.4, yb, 0.0), (19.4, 23.8, BASE_Z), open="-z", bevel=0.1)
        B.slab(WHITE, (-3.2, yb - 0.55, 0.0), (3.2, yb + 0.05, BASE_Z * 0.5), open="-z", bevel=0.06)

    def tower(self, B, s):
        """One glass tower: deep blue glass, white corner fins and mullions, dark floor bands, a white parapet."""
        x0, x1 = sorted((s * TX[0], s * TX[1]))
        y0, y1 = TY
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        B.box(GLASS, (cx, cy, (BASE_Z + TOP_Z) / 2), (x1 - x0, y1 - y0, TOP_Z - BASE_Z), open="-z +z", bevel=0)
        fh = (TOP_Z - BASE_Z) / FLOORS
        # dark floor bands around the tower
        path = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
        for k in range(1, FLOORS):
            z = BASE_Z + fh * k
            B.sweep_path(C_NAVY, [(-0.09, z - 0.1), (0.02, z - 0.1), (0.02, z + 0.1), (-0.09, z + 0.1)], path, closed=True,
                         bevel=0)
        # mullions: thin white fins on every face (open where they meet the glass, the base and the parapet)
        w, t = 0.24, 0.15
        zc, zh = (BASE_Z + TOP_Z) / 2, TOP_Z - BASE_Z
        nx = int(round((x1 - x0) / BAY))
        for i in range(1, nx):
            x = x0 + (x1 - x0) * i / nx
            for y, o in ((y0, "+y"), (y1, "-y")):
                yy = y - t / 2 + 0.01 if o == "+y" else y + t / 2 - 0.01
                B.box(WHITE, (x, yy, zc), (w, t + 0.02, zh), open="-z +z " + o, bevel=0.05)
        ny = int(round((y1 - y0) / BAY))
        inner_x = x0 if s > 0 else x1
        for j in range(1, ny):
            y = y0 + (y1 - y0) * j / ny
            for x, o in ((x0, "+x"), (x1, "-x")):
                xx = x - t / 2 + 0.01 if o == "+x" else x + t / 2 - 0.01
                z_lo = BASE_Z
                if abs(x - inner_x) < 1e-6 and y > BRIDGE_Y0 - 0.2:
                    z_lo = CONN_TOP + 0.5 if y > CONN_Y[0] - 0.2 else BRIDGE_Z[1]
                B.box(WHITE, (xx, y, (z_lo + TOP_Z) / 2), (t + 0.02, w, TOP_Z - z_lo), open="-z +z " + o, bevel=0.05)
        # white corner fins
        for x in (x0, x1):
            for y in (y0, y1):
                B.box(WHITE, (x, y, zc), (0.62, 0.62, zh), open="-z +z", bevel=0.08)
        # the sky reflection on the front (facing the pen): one diagonal streak of light panes, two panes wide
        bw = (x1 - x0) / nx
        for i in range(nx):
            for k in range(FLOORS):
                if not STREAK <= k - i <= STREAK + 1:
                    continue
                px0 = x0 + bw * i + (0.33 if i == 0 else 0.14)
                px1 = x0 + bw * (i + 1) - (0.33 if i == nx - 1 else 0.14)
                pz0 = BASE_Z + fh * k + (0.12 if k > 0 else 0.02)
                pz1 = BASE_Z + fh * (k + 1) - (0.12 if k < FLOORS - 1 else 0.28)
                B.box(LAMP, ((px0 + px1) / 2, y0 - 0.018, (pz0 + pz1) / 2), (px1 - px0, 0.036, pz1 - pz0), open="+y",
                      bevel=0)
        # the roof (light grey) inside a white parapet rim that overhangs the glass a little, and a rooftop unit
        B.box(ROOF, (cx, cy, TOP_Z + 0.15), (x1 - x0 - 0.2, y1 - y0 - 0.2, 0.3), open="-z", bevel=0)
        rim = rect_profile(-0.4, 0.45, TOP_Z - 0.25, TOP_Z + PARAPET)
        B.sweep_path(WHITE, rim, [(x0, y0), (x1, y0), (x1, y1), (x0, y1)], closed=True, bevel=0.1)
        ux = cx + s * 1.6
        B.box(ROOF, (ux, cy + 1.2, TOP_Z + 0.8), (6.0, 4.4, 1.0), open="-z", bevel=0.12)
        B.box(WHITE, (ux, cy + 1.2, TOP_Z + 1.4), (6.3, 4.7, 0.2), bevel=0.06)

    def centre_block(self, B):
        """Between the towers: the lower glass block (white roof and railing), the projecting sky bridge (white frame,
        2 x 6 light-glass windows) and the white portico lobby with the gold UA plaque."""
        gx = TX[0] + 0.1   # everything spans the gap and sinks 0.1 into the towers
        y0, y1 = CONN_Y
        B.box(GLASS, (0.0, (y0 + y1) / 2, (BASE_Z + CONN_TOP) / 2), (2 * gx, y1 - y0, CONN_TOP - BASE_Z), open="-z +z",
              bevel=0)
        fh = (TOP_Z - BASE_Z) / FLOORS
        for k in range(1, FLOORS):
            z = BASE_Z + fh * k
            if 7.2 < z < CONN_TOP - 0.4 and not (BRIDGE_Z[0] - 0.3 < z < BRIDGE_Z[1] + 0.3):
                B.box(C_NAVY, (0.0, y0 - 0.04, z), (2 * TX[0], 0.1, 0.2), open="+y", bevel=0)
            if z < CONN_TOP - 0.4:   # the back (seen from the hub)
                B.box(C_NAVY, (0.0, y1 + 0.04, z), (2 * TX[0], 0.1, 0.2), open="-y", bevel=0)
        # white mullions on the block's front (above the lobby canopy, behind the bridge) and back
        for x in (-1.73, 0.0, 1.73):
            B.box(WHITE, (x, y0 - 0.07, (6.7 + CONN_TOP) / 2), (0.22, 0.14, CONN_TOP - 6.7), open="-z +z +y", bevel=0.04)
            B.box(WHITE, (x, y1 + 0.07, (BASE_Z + CONN_TOP) / 2), (0.22, 0.14, CONN_TOP - BASE_Z), open="-z +z -y",
                  bevel=0.04)
        B.box(WHITE, (0.0, (y0 + y1) / 2 - 0.1, CONN_TOP + 0.25), (2 * gx, y1 - y0 + 0.4, 0.5), bevel=0.08)
        # the roof railing (white posts and a top rail)
        for x in (-2.7, -1.35, 0.0, 1.35, 2.7):
            B.box(WHITE, (x, y0 + 0.05, CONN_TOP + 1.0), (0.16, 0.16, 1.0), open="-z", bevel=0)
        B.box(WHITE, (0.0, y0 + 0.05, CONN_TOP + 1.55), (2 * TX[0], 0.2, 0.14), bevel=0)
        # the sky bridge
        z0, z1 = BRIDGE_Z
        yb0 = BRIDGE_Y0
        B.box(WHITE, (0.0, (yb0 + y0) / 2, z1 - 0.4), (2 * gx, y0 - yb0, 0.8), bevel=0.1)
        B.box(WHITE, (0.0, (yb0 + y0) / 2, z0 + 0.4), (2 * gx, y0 - yb0, 0.8), bevel=0.1)
        gw = TX[0] - 0.42
        for sx in (-1, 1):
            B.box(WHITE, (sx * (gw + gx) / 2, (yb0 + y0) / 2, (z0 + z1) / 2), (gx - gw, y0 - yb0, z1 - z0 - 1.6),
                  open="-z +z", bevel=0.06)
        gy = yb0 + 0.3
        B.box(LAMP, (0.0, (gy + y0) / 2, (z0 + z1) / 2), (2 * gw, y0 - gy, z1 - z0 - 1.6), open="-z +z +y", bevel=0)
        for i in range(1, 6):
            x = -gw + 2 * gw * i / 6
            B.box(WHITE, (x, gy - 0.05, (z0 + z1) / 2), (0.16, 0.14, z1 - z0 - 1.6), open="-z +z +y", bevel=0)
        B.box(WHITE, (0.0, gy - 0.05, (z0 + z1) / 2), (2 * gw, 0.14, 0.16), open="+y", bevel=0)
        # the lobby: white canopy, light glass behind four white columns, the gold UA plaque on the canopy front
        B.box(WHITE, (0.0, (yb0 - 0.1 + y0) / 2, 6.35), (2 * gx, y0 - yb0 + 0.1, 0.8), bevel=0.1)
        B.box(LAMP, (0.0, (13.6 + y0) / 2, (BASE_Z + 5.95) / 2), (2 * gx, y0 - 13.6, 5.95 - BASE_Z), open="-z +z +y",
              bevel=0)
        for x in (-1.05, 1.05):
            B.box(WHITE, (x, 13.55, (BASE_Z + 5.95) / 2), (0.16, 0.12, 5.95 - BASE_Z), open="-z +z +y", bevel=0)
        for x in (-2.6, -0.9, 0.9, 2.6):
            B.column(WHITE, x, yb0 + 0.9, [(BASE_Z, 0.26, 0.26), (5.95, 0.26, 0.26)], chamfer=0.07)
        with B.frame(T(0.0, yb0 - 0.2, 6.35) @ facing((0.0, -1.0))):
            ua_plaque(B, 1.25, 0.3)


THEME = Theme()
