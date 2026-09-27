# scripts/tools/blender/base_themes/themes/volcano.py
# Volcano = ONE PIECE: "Sunny Pirate Wharf" (owner art direction 2026-09-24, API v3; replaces the v2 "Straw Hat Ship").
#   The pen is a pirate-galleon wharf the Straw Hats moor at. Perimeter: fat wooden mooring bollards (a mushroom head on a
#   turned body) standing on the fence line, every other one wrapped in a 3D coil of hemp rope, the others carrying a
#   slanted bronze bracket with a hanging bronze lantern (glossy amber glass); between them two thick horizontal planks under
#   a chunky cap rail (the railing runs through the posts, no crosses anywhere).
#   Corners: mooring dolphins (a tall pile and two shorter piles lashed together with hemp rope) crowned by a big bronze
#   harbour lantern. Gate (2026-09-25, THEME3_Volcano_Sunny): the Thousand Sunny of the owner's reference image
#   (themes/sunny_ship.py) on two cradles on a short wharf carried by two timber piles; its material groups animate the
#   hull, main sail, striped aft sail and flag in Roblox (SunnyWind). The floor has honey deck planks with staggered
#   joints and a low nautical compass with the Sunny's sun. The ship takes ~4,800 of the triangles, so the repeated
#   perimeter details are economical (smooth-shaded 8/10-sided bollards and piles) and both variants stay below 9,000.
#   Terminal: the ship's helm: a big wooden wheel standing right behind the PlotUpgrade sign so the upgrade screen is its
#   hub; turned handles protrude past the rim, the lower half sinks into a wooden helm box. No backdrop: the plot is open.

import math

import bmesh

from common import *
from themes import sunny_ship

FLOOR, TEAK, NAIL, F_DARK = "Floor_Base", "Floor_Teak", "Floor_Iron", "Floor_Dark"
WOOD, PLANK, BRONZE, ROPE, RED = "Structure_Wood", "Structure_Plank", "Structure_Bronze", "Structure_Rope", "Structure_Red"
C_WOOD, C_GOLD, C_IVORY = "Core_3D_Wood", "Core_3D_Gold", "Core_3D_Ivory"
LAMP, SCREEN = "Neon_Emissive_Lantern", "Neon_Emissive_Screen"

LAMP_RGB = (255, 170, 60)
# the lantern glass without glow (owner 2026-09-25: no neon, no lights in the bases): warm amber, glossy
LAMP_ACCENT_RGB = (250, 164, 52)

# ----------------------------------------------------------------------------------------------------------------------
# the railing (side frame: y outward, z up). The bollards (r 0.58), dolphins and masts own the fence line; the planks and
# the cap rail stay inside them (|y| <= 0.44) and run through every post.
# ----------------------------------------------------------------------------------------------------------------------
LOWER = chamfer_profile(-0.24, 0.36, 0.52, 1.46, 0.1, 0.1)
UPPER = chamfer_profile(-0.24, 0.36, 1.76, 2.66, 0.1, 0.1)
CAP = [(-0.36, 2.66), (0.48, 2.66), (0.48, 2.84), (0.36, 2.98), (-0.24, 2.98), (-0.36, 2.84)]
CAP_TOP = 2.98
# the mooring bollard (post frame, its axis PY outward so the head's pen side sits on the INSET line): turned body, a
# mushroom head, a low dome; the hemp coil wraps it under the head, right above the cap rail
PY = 0.2
BOLLARD = [(0.62, 0.0), (0.62, 3.5), (0.82, 3.74), (0.0, 4.06)]
BOLLARD_TOP = 4.06

# the helm (terminal frame: x = v - 10.435, y = u - (D + 1.48)): the wheel stands between the railing and the sign
WHEEL_H = (SIGN_H[0] + SIGN_H[1]) / 2          # the wheel's axle = the sign's centre (h 2.835)
WHEEL_Y = (-0.99, -0.69)                        # u D+0.49 .. D+0.79 (the cap rail ends at D+0.48, the sign at D+0.86)
RIM = (3.25, 3.85)
RIM_A = (math.radians(-25.0), math.radians(205.0))
HANDLE_TIP = 4.8
SPOKES = 8
HELM_BOX_TOP = 1.6


# ----------------------------------------------------------------------------------------------------------------------
# small meshes of our own
# ----------------------------------------------------------------------------------------------------------------------

def drop_down(bm):
    """Drops the faces looking straight down (a piece standing on something)."""
    bm.normal_update()
    dead = [f for f in bm.faces if f.normal.z < -0.99]
    if dead:
        bmesh.ops.delete(bm, geom=dead, context="FACES_ONLY")
    return bm


def bm_nail(r, h, top=0.58, n=4):
    """A chamfered square deck nail / rivet head: a frustum standing on z 0, open at the bottom (10 tris for n = 4)."""
    return drop_down(bm_lathe([(r, 0.0), (r * top, h)], n, math.pi / n))


def coil(r0, r1, z0, turns, pitch):
    """Lathe profile of a hemp rope coiled `turns` times around a post of radius r0 (the rope stands out to r1)."""
    pts = []
    for k in range(turns):
        pts.append((r0, z0 + pitch * k))
        pts.append((r1, z0 + pitch * (k + 0.5)))
    pts.append((r0, z0 + pitch * turns))
    return pts


def bm_rope_loop(path, r, m=4):
    """A closed rope (round-ish, m sides) along a closed polyline path [(x, y, z)]."""
    bm = bmesh.new()
    n = len(path)
    pts = [Vector(p) for p in path]
    rings = []
    for i in range(n):
        t = (pts[(i + 1) % n] - pts[i - 1]).normalized()
        side = t.cross(Vector((0.0, 0.0, 1.0)))
        if side.length < 1e-6:
            side = Vector((1.0, 0.0, 0.0))
        side.normalize()
        up = side.cross(t).normalized()
        rings.append([bm.verts.new(pts[i] + (side * math.cos(2 * math.pi * j / m + math.pi / 4)
                                              + up * math.sin(2 * math.pi * j / m + math.pi / 4)) * r) for j in range(m)])
    for i in range(n):
        a, b = rings[i], rings[(i + 1) % n]
        for j in range(m):
            k = (j + 1) % m
            bm.faces.new((a[j], a[k], b[k], b[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return bm


def bm_rose_half(a, tip, base_r, spread, z_base, z_ridge, z_tip, side):
    """One half of a compass-rose point: the ridge runs from the centre (z_ridge) to the tip (z_tip), the half slopes
    down to its base corner (radius base_r, `spread` off the point's axis on `side`). Two triangles: the top face and
    the flank facing the neighbouring point (the base on the card and the face under the ridge are never seen)."""
    bm = bmesh.new()
    ca, sa = math.cos(a), math.sin(a)
    b = a + side * spread
    c0 = bm.verts.new((0.0, 0.0, z_base))
    ct = bm.verts.new((0.0, 0.0, z_ridge))
    t = bm.verts.new((tip * ca, tip * sa, z_tip))
    s = bm.verts.new((base_r * math.cos(b), base_r * math.sin(b), z_base))
    top = bm.faces.new((ct, t, s))
    flank = bm.faces.new((c0, ct, s))
    bm.normal_update()
    if top.normal.z < 0:
        top.normal_flip()
    # the flank faces away from the point's axis (toward `side`)
    out = Vector((math.cos(a + side * math.pi / 2), math.sin(a + side * math.pi / 2), 0.0))
    if flank.normal.dot(out) < 0:
        flank.normal_flip()
    return bm


def star(points, r_out, r_in, a0=math.pi / 2):
    """A star of `points` petals around the origin (2 * points corners)."""
    return [((r_out if k % 2 == 0 else r_in) * math.cos(a0 + math.pi * k / points),
             (r_out if k % 2 == 0 else r_in) * math.sin(a0 + math.pi * k / points)) for k in range(2 * points)]


def ellipse(cx, cy, rx, ry, n, a0=0.0):
    return [(cx + rx * math.cos(a0 + 2 * math.pi * k / n), cy + ry * math.sin(a0 + 2 * math.pi * k / n)) for k in range(n)]


# the compass sun's grin (an arc band)
GRIN = ([(0.52 * math.cos(math.radians(a)), -0.08 + 0.4 * math.sin(math.radians(a))) for a in range(200, 341, 35)]
        + [(0.4 * math.cos(math.radians(a)), -0.06 + 0.26 * math.sin(math.radians(a))) for a in range(340, 199, -35)])
N_LETTER = [(-0.5, -0.65), (-0.24, -0.65), (-0.24, 0.2), (0.26, -0.65), (0.5, -0.65), (0.5, 0.65), (0.24, 0.65),
            (0.24, -0.2), (-0.26, 0.65), (-0.5, 0.65)]



class Theme(PenTheme):
    KEY, NAME, TITLE, FRANCHISE = "Volcano", "SunnyPirateWharf", "Sunny Pirate Wharf", "One Piece"
    PALETTE = {
        FLOOR: look((228, 182, 118), "SmoothPlastic"),                 # honey deck planks (anchor: the outer columns)
        TEAK: look((204, 148, 88), "SmoothPlastic"),                   # the darker boards mixed into the deck
        NAIL: look((58, 52, 52), "SmoothPlastic"),                     # iron deck nails
        F_DARK: look((104, 62, 38), "SmoothPlastic"),                  # walnut waterway border, gangway
        WOOD: look((98, 58, 36), "SmoothPlastic", bevel=0.09),         # walnut: bollards, piles, masts, cap rail, rim
        PLANK: look((178, 88, 48), "SmoothPlastic", bevel=0.08),       # mahogany: railing planks, spokes, yard, cleats
        BRONZE: look((226, 160, 62), "SmoothPlastic", reflectance=0.08, bevel=0.04),
        ROPE: look((236, 206, 142), "Plastic"),                        # hemp
        RED: look((204, 36, 42), "SmoothPlastic", bevel=0.04),         # Luffy red: hat bands, intercardinal points
        C_WOOD: look((58, 40, 32), "SmoothPlastic", bevel=0.04),       # ebony
        C_GOLD: look((250, 196, 70), "SmoothPlastic", reflectance=0.06, bevel=0.04),
        C_IVORY: look((246, 234, 208), "SmoothPlastic", bevel=0.04),
        LAMP: look(LAMP_ACCENT_RGB, "SmoothPlastic", reflectance=0.08),
        SCREEN: look(LAMP_ACCENT_RGB, "SmoothPlastic", reflectance=0.08),
    }
    sunny_ship.add_palette(PALETTE)
    PLANKS = 17              # deck plank columns across the pen (3.1 studs each; odd: both outer columns are Floor_Base)
    STUDIO_RGB = (206, 212, 224)  # render only: the shared studio tint (coherence sheet)

    # -- floor: deck planks, nails, the waterway border, the gangway ------------------------------------------------
    def floor(self, B):
        W, D = B.W, B.D
        pw = 2 * W / self.PLANKS
        beams = B.us[1:-1]
        joints_of = {}
        for i in range(self.PLANKS):
            k = (i // 2) % 3
            joints = [beams[j] for j in range(len(beams)) if (j + k) % 3 == 0][:1] if i % 2 else []
            joints_of[i] = joints
            cuts = [-D] + joints + [D]
            x = -W + pw * (i + 0.5)
            for seg, (a, b) in enumerate(zip(cuts, cuts[1:])):
                # a two-tone deck: some boards darker, the outer columns always Floor_Base (the loader's floor anchor)
                dark = 0 < i < self.PLANKS - 1 and (i * 3 + seg * 2) % 5 < 2
                B.mesh(TEAK if dark else FLOOR, bm_tile(pw, b - a, 0.2, 0.0, FLOOR_TOP), T(x, (a + b) / 2, 0.0), bevel=0)
        # square iron deck nails on the beam lines (the joints land on them), every other plank in a checkerboard
        for i in range(self.PLANKS):
            x = -W + pw * (i + 0.5)
            if abs(x) > W - 3.9:  # the two outer columns: the waterway border and the railing already frame them
                continue
            for j, y in enumerate(beams):
                if (i + j) % 10 or math.hypot(x, y) < 9.4 or (abs(x) < 3.8 and y > D - 3.0):
                    continue
                B.mesh(NAIL, bm_nail(0.26, 0.08), T(x, y, FLOOR_TOP), bevel=0)
        # the waterway: a dark plank border along the railing
        z0, z1, w = FLOOR_TOP, 0.17, 1.05
        # (0.07 thick: a clamped bevel would not show, so these stay sharp and cheap)
        B.slab(F_DARK, (-W, -D, z0), (W, -D + w, z1), open="-z", bevel=0)
        for s in (-1, 1):
            B.slab(F_DARK, (min(s * W, s * (W - w)), -D + w, z0), (max(s * W, s * (W - w)), D, z1), open="-z", bevel=0)
            B.slab(F_DARK, (min(s * (W - w), s * 3.55), D - w, z0), (max(s * (W - w), s * 3.55), D, z1), open="-z",
                   bevel=0)
        # the gangway through the gate: dark boards with cleats
        B.slab(F_DARK, (-3.3, D - 2.2, z0), (3.3, D + 2.3, 0.2), open="-z")
        for k in range(5):
            B.box(PLANK, (0.0, D - 1.6 + 0.9 * k, 0.235), (6.0, 0.26, 0.07), open="-z", bevel=0)

    # -- centre: the 3D nautical compass --------------------------------------------------------------------------
    def centerpiece(self, B):
        z = FLOOR_TOP
        # stepped ebony plate, the raised gold bezel, the ivory card
        B.relief_disc((0, 0, 0), [(C_WOOD, 8.4, 0.0, z, 0.15, 0, 0)], n=20)
        B.lathe(C_GOLD, (0, 0, 0), [(8.1, 0.15), (7.8, 0.28), (7.48, 0.15)], n=20, cap=False, bevel=0)
        B.relief_disc((0, 0, 0), [(C_IVORY, 7.48, 0.0, 0.15, 0.18, 0, 0)], n=20)
        # ebony ticks between the intercardinal and minor points
        # the rose: 4 cardinal points (gold | ebony), 4 intercardinal (red | ebony), 8 minor (gold | ebony)
        north = -math.pi / 2   # north points at the back fence: it reads upright for a player walking in
        for k in range(16):
            a = north + k * math.pi / 8
            if k % 4 == 0:
                tip, base_r, spread, zr, roles = 7.05, 1.25, math.pi / 4, 0.26, (C_GOLD, C_WOOD)
            elif k % 2 == 0:
                tip, base_r, spread, zr, roles = 5.1, 1.1, math.pi / 4, 0.24, (RED, C_WOOD)
            else:
                tip, base_r, spread, zr, roles = 3.5, 0.95, math.pi / 8, 0.22, (C_GOLD, C_WOOD)
            for side, role in zip((1, -1), roles):
                B.mesh(role, bm_rose_half(a, tip, base_r, spread, 0.18, zr, 0.19, side), bevel=0)
        # the gold N beyond the north tip
        with B.frame(T(0.0, -9.35, 0.0) @ Rz(math.pi)):
            B.relief([(x * 1.15, y * 1.15) for x, y in N_LETTER], [(C_GOLD, 0.0, FLOOR_TOP, 0.24, 0)])
        # the Thousand Sunny's sun as the pivot cap (upright for a player walking in, like the N)
        with B.frame(Rz(math.pi) @ S(1.22, 1.22, 1.0)):
            B.relief(star(10, 1.78, 1.28), [(C_GOLD, 0.0, 0.18, 0.25, 0, 0)])
            B.relief_disc((0, 0, 0), [(C_IVORY, 0.98, 0.0, 0.25, 0.28, 0, 0)], n=12)
            for sx in (-1, 1):
                B.relief(ellipse(sx * 0.33, 0.22, 0.12, 0.15, 6), [(C_WOOD, 0.0, 0.28, 0.3, 0)])
            B.relief(GRIN, [(C_WOOD, 0.0, 0.28, 0.3, 0)])

    # -- perimeter: planks + cap rail per run, rivets per span, bollards, dolphins ----------------------------------
    def fence(self, B):
        # no terminal gap: the railing runs on behind the helm (the wheel stands between it and the sign)
        for side, s0, s1 in B.runs():
            with B.module("railing"), B.frame(B.side_frame(side, (s0 + s1) / 2)):
                self.rail_run(B, side, s1 - s0)
        for side, s0, s1 in B.spans():
            with B.module("span"), B.frame(B.side_frame(side, (s0 + s1) / 2)):
                self.span(B, side, s1 - s0, s0, s1)
        for post in B.posts():
            if post.kind == "corner":
                with B.module("corner"), B.frame(B.corner_frame(1 if post.x > 0 else -1, 1 if post.y > 0 else -1)):
                    self.corner(B)
            elif post.kind == "post":
                along = post.x + B.W if post.side in ("front", "back") else post.y + B.D
                with B.module("post"), B.frame(B.post_frame(post)):
                    self.post(B, post, int(round(along / POST_STEP)) % 2 == 1)

    def rail_run(self, B, side, L):
        x0, x1 = -L / 2, L / 2
        B.sweep(PLANK, LOWER, x0, x1, open_ends=(True, True), bevel=0)
        B.sweep(PLANK, UPPER, x0, x1, open_ends=(True, True), open="+z", bevel=0)
        B.sweep(WOOD, CAP, x0, x1, open_ends=(True, True), open="-z", bevel=0)

    def span(self, B, side, L, s0, s1):
        """Nothing between the posts: the planks and the cap rail run through them (rail_run); the triangle budget of
        the old cap-rail rivets went to the Thousand Sunny on the gate (2026-09-25)."""
        return

    def post(self, B, post, lantern=False):
        """A mooring bollard: every other one carries a hanging bronze lantern, the others are wrapped in hemp rope
        under the head (post frame: X along the fence, +Y outward)."""
        B.mesh(WOOD, bm_lathe(BOLLARD, 8, math.pi / 8), T(0.0, PY, 0.0), bevel=0, smooth=True)
        if lantern:
            self.lantern(B, BOLLARD_TOP - 0.1)
        else:
            B.mesh(ROPE, bm_lathe(coil(0.62, 0.8, 3.10, 1, 0.38), 6, math.pi / 6, cap=False), T(0.0, PY, 0.0), bevel=0,
                   smooth=True)

    def lantern(self, B, z0):
        """A slanted bronze bracket on the bollard's head and a square bronze lantern hanging from it along the fence."""
        arm, x, y = 5.46, 1.3, PY
        B.beam(BRONZE, (0.0, y, z0), (x, y, arm + 0.06), 0.17, bevel=0)
        B.mesh(BRONZE, bm_lathe([(0.5, 0.0), (0.0, arm - 4.76)], 4, math.pi / 4), T(x, y, 4.76), bevel=0)
        B.box(LAMP, (x, y, 4.4), (0.5, 0.5, 0.72), open="+z")

    def corner(self, B):
        """A mooring dolphin: a tall pile on the corner point and two shorter piles, lashed with hemp rope, a bronze
        harbour lantern on top (corner frame: x, y outward, -0.62 .. 1.3)."""
        H = 6.1
        B.mesh(WOOD, bm_lathe([(0.55, 0.0), (0.55, H), (0.0, H + 0.3)], 10, 0.0), T(0.07, 0.07, 0.0), bevel=0, smooth=True)
        for px, py in ((0.66, 0.05), (0.05, 0.66)):
            B.mesh(WOOD, bm_lathe([(0.38, 0.0), (0.38, 4.4), (0.0, 4.64)], 8, 0.0), T(px, py, 0.0), bevel=0, smooth=True)
        # the lashing: a hemp rope around the outer piles, both ends dive into the tall one
        path = [(-0.15, 0.35)]
        for cx, cy, a0, a1 in ((0.05, 0.66, 160.0, 30.0), (0.66, 0.05, 60.0, -70.0)):
            for k in range(3):
                a = math.radians(a0 + (a1 - a0) * k / 2)
                path.append((cx + 0.48 * math.cos(a), cy + 0.48 * math.sin(a)))
        path.append((0.35, -0.15))
        z = 3.3
        prof = [(0.13 * math.cos(math.pi / 2 + j * 2 * math.pi / 3), z + 0.13 * math.sin(math.pi / 2 + j * 2 * math.pi / 3))
                for j in range(3)]
        B.mesh(ROPE, bm_sweep_path(prof, path, open_ends=(True, True)), bevel=0, smooth=True)
        self.harbour_lantern(B, (0.07, 0.07, H + 0.18))

    def harbour_lantern(self, B, pos, s=1.0):
        x, y, z = pos
        """A big square bronze harbour lantern standing on pos (the pile's top)."""
        B.box(BRONZE, (x, y, z + 0.08 * s), (0.9 * s, 0.9 * s, 0.16 * s), bevel=0)
        B.box(LAMP, (x, y, z + 0.54 * s), (0.66 * s, 0.66 * s, 0.76 * s), open="-z +z")
        B.mesh(BRONZE, bm_lathe([(0.7 * s, 0.0), (0.0, 0.62 * s)], 4, math.pi / 4), T(x, y, z + 0.92 * s), bevel=0)

    # -- gate: the Thousand Sunny on its cradles on a short wharf crowning the portal, clear of the playable floor ------
    #    gate frame: x = v, y = u - D (outward), z = h. The wharf (beam + planks + posts + rope railings) spans
    #    v -6.4..6.4, u D-0.6..D+2.36 (the pen contract's 3-stud front strip), its underside at h 7.52 (> 7.5 passage).
    SHIP_OUT, SHIP_Z = 0.88, 8.30      # the ship origin (post_zz_base_themes.luau / SunnyWind pin it): u D+0.88, h 8.30
    WHARF = (7.52, 7.84, 7.98)         # beam underside, beam top = plank underside, plank top
    WHARF_X = 6.4
    CRADLES = (-2.45, 2.75)            # ship x of the two cradles

    def gate(self, B):
        for side in (-1, 1):
            with B.module("gate pylon"), B.frame(B.pylon_frame(side)):
                self.gate_pylon(B, side)
        with B.module("gate lintel"), B.frame(B.gate_frame()):
            self.gate_lintel(B)
        with B.module("Sunny ship"), B.frame(T(0.0, B.D + self.SHIP_OUT, self.SHIP_Z)):
            self.emblem(B)

    def gate_pylon(self, B, side):
        """A timber mooring pile under the wharf: plinth, bronze collar, the tapering pile, a hemp lashing."""
        cx, my = -0.33, 0.1
        top = self.WHARF[0]
        B.column(WOOD, cx, 0.3, [(0.0, 0.9, 0.88), (1.1, 0.9, 0.88), (1.42, 0.74, 0.72)], chamfer=0.28)
        B.box(BRONZE, (cx, 0.3, 0.62), (1.92, 1.84, 0.18), open="-z +z", bevel=0.03)
        B.lathe(WOOD, (cx, my, 0.0), [(0.62, 1.42), (0.52, top)], n=12, cap=False, bevel=0)
        B.mesh(ROPE, bm_lathe(coil(0.54, 0.72, top - 1.0, 1, 0.42), 8, math.pi / 8, cap=False),
               T(cx, my, 0.0), bevel=0, smooth=True)

    def gate_lintel(self, B):
        """The wharf: a walnut beam on the piles, three mahogany planks, two cradles shaped to the hull, corner posts
        with sagging hemp rope railings at both ends (the middle stays open: the hull reads from below)."""
        z0, z1, z2 = self.WHARF
        yc, X = self.SHIP_OUT, self.WHARF_X
        B.box(PLANK, (0.0, yc - 0.12, (z0 + z1) / 2), (2 * X - 0.8, 2.5, z1 - z0), bevel=0.08)
        for k in (-1, 0, 1):
            B.box(WOOD, (0.0, yc + 0.98 * k, (z1 + z2) / 2), (2 * X, 0.94, z2 - z1), open="-z", bevel=0.04)
        # the cradles: the saddle follows the hull's bottom (sunk 0.04 into it: the swell never opens a gap)
        for cx in self.CRADLES:
            top = [(y, sunny_ship.hull_bottom(cx, y) + self.SHIP_Z - 0.04) for y in (0.92, 0.62, 0.31, 0.0, -0.31,
                                                                                      -0.62, -0.92)]
            poly = [(-1.02, z2 - 0.01), (1.02, z2 - 0.01)] + [(y + yc, z) for y, z in top]
            poly[2] = (poly[2][0] + 0.06, poly[2][1])
            poly[-1] = (poly[-1][0] - 0.06, poly[-1][1])
            poly = [(poly[0][0] + yc, poly[0][1]), (poly[1][0] + yc, poly[1][1])] + poly[2:]
            M = basis(Vector((0.0, 1.0, 0.0)), Vector((0.0, 0.0, 1.0)), Vector((1.0, 0.0, 0.0)), (cx - 0.22, 0.0, 0.0))
            B.mesh(WOOD, bm_prism(poly, 0.0, 0.44), M, bevel=0)
        # posts at the four corners (+ one inner post per end on the street side) with hemp lashings, a sagging rope
        # railing along the street side at both ends
        ys = (yc - 1.33, yc + 1.33)
        for sx in (-1, 1):
            xo, xi = sx * (X - 0.2), sx * (X - 2.1)
            for x, y in ((xo, ys[0]), (xo, ys[1]), (xi, ys[1])):
                B.box(WOOD, (x, y, (z0 + z2 + 0.95) / 2), (0.3, 0.3, z2 + 0.95 - z0), open="-z", bevel=0.03)
            B.lathe(ROPE, (xo, ys[1], z2 + 0.62), [(0.232, 0.0), (0.232, 0.16)], n=4, a0=math.pi / 4, cap=False, bevel=0)
            a, b = Vector((xo, ys[1], z2 + 0.78)), Vector((xi, ys[1], z2 + 0.78))
            mid = (a + b) / 2 - Vector((0.0, 0.0, 0.2))
            B.mesh(ROPE, sunny_ship.rope_bm(a, mid, 0.045, 4), bevel=0)
            B.mesh(ROPE, sunny_ship.rope_bm(mid, b, 0.045, 4), bevel=0)

    def emblem(self, B):
        sunny_ship.build(B)

    # -- terminal: the ship's wheel, the upgrade screen as its hub -------------------------------------------------
    def terminal(self, B):
        yc = (WHEEL_Y[0] + WHEEL_Y[1]) / 2
        depth = WHEEL_Y[1] - WHEEL_Y[0]
        with B.frame(B.terminal_frame()):
            # terminal frame: x = v - 10.435, y = u - (D + 1.48): the fence line is y -1.48
            # the rim (its lower half sinks into the helm box)
            B.arch(WOOD, (0.0, yc, WHEEL_H), RIM[0], RIM[1], depth, RIM_A[0], RIM_A[1], n=11)
            # the hub (hidden from the front by the sign, seen from the pen over the railing)
            hub = bm_lathe([(0.6, 0.0), (0.6, depth)], 11, 0.0)
            hub.transform(AXES["y"])
            hub.normal_update()
            bmesh.ops.delete(hub, geom=[f for f in hub.faces if f.normal.y > 0.99], context="FACES_ONLY")  # faces the sign
            B.mesh(BRONZE, hub, T(0.0, WHEEL_Y[0], WHEEL_H), bevel=0.03)
            # turned spokes running out through the rim into handles (kept behind the sign's back, u <= D+0.84)
            prof = [(0.14, 0.5), (0.14, RIM[1] + 0.04), (0.23, 4.4), (0.0, HANDLE_TIP)]
            for k in range(SPOKES):
                a = math.pi / 2 + 2 * math.pi * k / SPOKES
                if math.sin(a) < -0.2:
                    continue  # the lower spokes stand in the helm box
                d = Vector((math.cos(a), 0.0, math.sin(a)))
                M = basis(Vector((0.0, 1.0, 0.0)).cross(d), Vector((0.0, 1.0, 0.0)), d, (0.0, yc, WHEEL_H))
                B.mesh(PLANK, bm_lathe(prof, 6, 0.0, cap=False), M, bevel=0, smooth=True)  # no vertex toward the sign
            # Luffy's straw hat left on the top handle, tipped toward the player
            with B.frame(T(0.0, yc, WHEEL_H + HANDLE_TIP - 0.32) @ Rx(-0.38)):
                B.relief_disc((0, 0, 0), [(C_GOLD, 0.98, 0.0, 0.0, 0.08, 0)], n=10, open_bottom=False)
                B.lathe(RED, (0, 0, 0), [(0.56, 0.08), (0.56, 0.22)], n=8, a0=math.pi / 8, cap=False, bevel=0)
                B.lathe(C_GOLD, (0, 0, 0), [(0.54, 0.22), (0.5, 0.36), (0.32, 0.52), (0.0, 0.56)], n=8, a0=math.pi / 8, cap=False,
                        bevel=0)
            # the helm box the wheel sinks into: a block on the railing (clear of the sign's plinth, u <= D+0.46) and
            # cheeks in front of the rim's ends (beside the sign, |x| >= 2.95)
            B.slab(WOOD, (-3.95, -1.9, 0.0), (3.95, -1.02, HELM_BOX_TOP), open="-z")
            for s in (-1, 1):
                B.slab(WOOD, (min(s * 2.95, s * 3.95), -1.02, 0.0), (max(s * 2.95, s * 3.95), -0.58, HELM_BOX_TOP), open="-z")
            B.slab(BRONZE, (-4.05, -1.98, HELM_BOX_TOP), (4.05, -0.94, HELM_BOX_TOP + 0.12), open="-z")
        self.screen_bezel(B)


THEME = Theme()
