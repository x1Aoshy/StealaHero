# Forest / Stark Lab: restrained architectural redesign, 2026-09-25.
# The user's Avengers Tower reference replaces the repetitive Iron Man ornament.
# One sculpted tower at the open gate, fitted glass panels, graphite stone and brushed silver.
# All geometry stays on the existing perimeter; no hero slots or screen are covered.
# Polish pass 2026-09-25 (design kept): nothing floats, nothing z-fights (verify_forest.py checks both), one smooth
# steel band on the curved edge, logo in relief on the pod, the kiosk closes the fence around the sign, the lone gate
# post shares the tower's plinth and glazing.
import math

import bmesh
from common import *

FLOOR = "Floor_Base"
DARK = "Structure_Graphite"
STEEL = "Structure_Steel"
GLASS = "Structure_Glazing"
INLAY = "Core_3D_Graphite"
LOGO = "Core_3D_Silver"
LIGHT = "Neon_Emissive_Architectural"
SCREEN = "Neon_Emissive_Screen"
A_OUTLINE = [(-1.05, -1.15), (-0.62, -1.15), (0.0, 0.62), (0.62, -1.15),
             (1.05, -1.15), (0.2, 1.2), (-0.2, 1.2)]
A_ARROW = [(-0.52, -0.46), (1.12, -0.46), (1.12, -0.7), (1.66, -0.3),
           (1.12, 0.1), (1.12, -0.14), (-0.52, -0.14)]
# The tower's curved inner edge (tower-local x into the gate, z up): shared by the glass volume and its steel band,
# so the band always hugs the facade (polish pass 2026-09-25: one continuous mitred band, base to terrace).
TOWER_KEYS = [(0.66, 0.48), (0.75, 4.6), (0.94, 6.45), (1.12, 7.7), (1.50, 8.8), (2.02, 9.66),
              (3.05, 10.35), (4.40, 10.68)]


def chaikin(pts, iterations):
    """Corner-cutting subdivision of an open polyline (end points kept): the facets of the sweep melt into a curve."""
    for _ in range(iterations):
        out = [pts[0]]
        for a, b in zip(pts, pts[1:]):
            out += [(0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]),
                    (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1])]
        out.append(pts[-1])
        pts = out
    return pts


TOWER_EDGE = chaikin(TOWER_KEYS, 2)
# Fence rhythm: the kiosk closes this stretch of the front fence; the rails end hidden inside its back wall.
KIOSK_GAP = (7.05, 13.80)


def clip_window(poly, axis, boundary, keep_greater):
    """Clip the facade to a mullion line, preserving the sloped boundary of the building."""
    result = []
    for a, b in zip(poly, poly[1:] + poly[:1]):
        da, db = a[axis] - boundary, b[axis] - boundary
        ina = da >= -1e-8 if keep_greater else da <= 1e-8
        inb = db >= -1e-8 if keep_greater else db <= 1e-8
        if ina:
            result.append(a)
        if ina != inb:
            t = da / (da - db)
            result.append((a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1])))
    clean = []
    for p in result:
        if not clean or math.dist(p, clean[-1]) > 1e-6:
            clean.append(p)
    if len(clean) > 1 and math.dist(clean[0], clean[-1]) < 1e-6:
        clean.pop()
    return clean


def window_panels(B, outline, xs, zs, faces, border=0.065):
    """Closed glass panes sit on an opaque backing; the evenly spaced gaps form flush frames.
    All panes share one material mesh in Roblox, regardless of the number of windows.
    """
    outline = offset_poly(outline, border)
    for x0, x1 in zip(xs, xs[1:]):
        for z0, z1 in zip(zs, zs[1:]):
            pane = outline
            for axis, edge, greater in ((0, x0 + 0.022, True), (0, x1 - 0.022, False),
                                        (1, z0 + 0.025, True), (1, z1 - 0.025, False)):
                pane = clip_window(pane, axis, edge, greater)
                if len(pane) < 3:
                    break
            if len(pane) < 3 or abs(poly_area(pane)) < 0.012:
                continue
            for y0, y1 in faces:
                B.plate(GLASS, pane, y0, y1, bevel=0)


def offset_line(line, d):
    """Mitred offset of an open polyline [(x, z), ...] by d to its RIGHT (negative = left)."""
    out = []
    n = len(line)
    for i in range(n):
        segs = []
        if i > 0:
            segs.append((line[i][0] - line[i - 1][0], line[i][1] - line[i - 1][1]))
        if i < n - 1:
            segs.append((line[i + 1][0] - line[i][0], line[i + 1][1] - line[i][1]))
        normals = []
        for dx, dz in segs:
            L = math.hypot(dx, dz)
            normals.append((dz / L, -dx / L))
        mx = sum(nv[0] for nv in normals) / len(normals)
        mz = sum(nv[1] for nv in normals) / len(normals)
        m = math.hypot(mx, mz)
        mx, mz = mx / m, mz / m
        k = max(mx * normals[0][0] + mz * normals[0][1], 0.3)
        out.append((line[i][0] + mx * d / k, line[i][1] + mz * d / k))
    return out


def edge_band(B, role, line, out, inset, y0, y1, z_min, z_cuts, bevel, segs):
    """A band hugging a polyline edge: `out` proud of it (to its right), `inset` sunk into the volume, extruded
    y0..y1. Cut into pieces at the heights `z_cuts` (the gate-clearance check is per piece); the cut faces and the
    bottom lying on z_min are left open, so the pieces read as one continuous band."""
    poly = offset_line(line, out) + list(reversed(offset_line(line, -inset)))
    poly = clip_window(poly, 1, z_min, True)
    bounds = [z_min] + list(z_cuts) + [None]
    flip = basis((1.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, 1.0, 0.0))
    for lo, hi in zip(bounds, bounds[1:]):
        part = clip_window(poly, 1, lo, True)
        if hi is not None:
            part = clip_window(part, 1, hi, False)
        if len(part) < 3:
            continue
        bm = bm_prism(part, y0, y1)
        bm.normal_update()
        cuts = [lo] + ([hi] if hi is not None else [])
        dead = [f for f in bm.faces if abs(f.normal.y) > 0.999 and
                any(all(abs(v.co.y - c) < 1e-5 for v in f.verts) for c in cuts)]
        if dead:
            bmesh.ops.delete(bm, geom=dead, context="FACES_ONLY")
        B.mesh(role, bm, flip, bevel=bevel, segs=segs)


class Theme(PenTheme):
    KEY, NAME, TITLE, FRANCHISE = "Forest", "StarkLab", "Stark Lab", "The Avengers"
    PALETTE = {
        FLOOR: look((87, 93, 101), "SmoothPlastic", bevel=0),
        DARK: look((36, 44, 53), "SmoothPlastic", bevel=0.065, segs=2),
        STEEL: look((149, 161, 172), "SmoothPlastic", reflectance=0.045, bevel=0.035, segs=2),
        GLASS: look((91, 132, 151), "Glass", transparency=0.28, reflectance=0.10, bevel=0),
        INLAY: look((55, 65, 74), "SmoothPlastic", bevel=0),
        LOGO: look((184, 197, 204), "SmoothPlastic", reflectance=0.045, bevel=0.025, segs=2),
        # accents, non-emissive since 2026-09-25 (owner: no neon in the bases): the same ice blue, a notch deeper
        # and glossy so the light slots and the bezel still read against the steel without glowing
        LIGHT: look((132, 184, 214), "SmoothPlastic", reflectance=0.06),
        SCREEN: look((96, 166, 204), "SmoothPlastic", reflectance=0.06),
    }
    TILES = {"Std": (5, 5), "Deep": (5, 6)}
    STUDIO_RGB = (202, 208, 217)
    ENTRY_Y = 0.45
    ENTRY_POST_TOP = 8.24
    ENTRY_CAP_THICKNESS = 0.10

    def floor(self, B):
        nx, ny = self.TILES[B.variant]
        B.tiles(FLOOR, -B.W, -B.D, B.W, B.D, nx, ny, inset=0.085)
        # A single flush entry mat; no chevrons, circuit spokes or oversized bolts. Inside the pen it lies on the
        # floor; past the fence line it comes down to the ground, so it never floats over the plot's grass.
        B.slab(INLAY, (-3.4, B.D - 4.7, FLOOR_TOP), (3.4, B.D, 0.15), open="-z +y", bevel=0)
        B.slab(INLAY, (-3.4, B.D, 0.0), (3.4, B.D + 1.8, 0.15), open="-z -y", bevel=0)
        for s in (-1, 1):
            B.slab(LOGO, (s * 3.05 - 0.035, B.D - 4.0, 0.15),
                   (s * 3.05 + 0.035, B.D + 1.35, 0.17), open="-z", bevel=0)

    def centerpiece(self, B):
        # Small tone-on-tone circular floor seal, deliberately leaving the field uncluttered.
        B.disc(INLAY, (0, 0, FLOOR_TOP), 4.15, 0.04, n=48, bevel=0)
        B.ring(LOGO, (0, 0, 0.14), 3.84, 3.91, 0.025, n=48, bevel=0)
        with B.frame(Rz(math.pi) @ S(1.72, 1.72, 1)):
            # seated on the seal (no hairline gap under the letter), a clear relief step above the ring; the arrow
            # tucks 0.01 under the A where they cross (no coplanar tops fighting)
            B.prism(LOGO, A_OUTLINE, 0.14, 0.2, bevel=0)
            B.prism(LOGO, A_ARROW, 0.14, 0.19, bevel=0)

    def fence(self, B):
        for side, a, b in B.runs(KIOSK_GAP):
            with B.module("architectural barrier"), B.frame(B.side_frame(side, (a + b) / 2)):
                self.rail_run(B, side, b - a)
        for post in B.posts():
            if post.kind == "corner":
                with B.module("corner"), B.frame(B.corner_frame(1 if post.x > 0 else -1, 1 if post.y > 0 else -1)):
                    self.corner(B)
            elif post.kind == "post":
                with B.module("post"), B.frame(B.post_frame(post)):
                    self.post(B, post)

    def rail_run(self, B, side, L):
        # A single layer of tinted glass; silver is a narrow coping only.
        B.sweep(DARK, [(-0.43, 0), (0.44, 0), (0.44, 0.72), (0.35, 0.88), (-0.43, 0.88)],
                -L/2, L/2, open_ends=(True, True), open="-z", bevel=0.035)
        B.box(GLASS, (0, 0.08, 1.66), (L, 0.25, 1.56), open="-x +x", bevel=0)
        B.box(STEEL, (0, 0.08, 2.5), (L, 0.45, 0.12), open="-x +x", bevel=0.025, segs=1)

    def span(self, B, side, L, s0, s1):
        # Intentionally no badges or accents repeated along each panel.
        pass

    def post(self, B, post):
        B.box(DARK, (0, 0.10, 1.38), (0.64, 0.88, 2.76), open="-z", bevel=0.06, segs=1)
        B.box(STEEL, (0, 0.10, 2.8), (0.69, 0.93, 0.08), bevel=0)

    def corner(self, B):
        B.box(DARK, (0.25, 0.25, 1.58), (1.55, 1.55, 3.16), open="-z", bevel=0.11)
        B.box(STEEL, (0.25, 0.25, 3.2), (1.59, 1.59, 0.08), bevel=0)
        # A light slot on both pen-facing faces, above the rail coping (at 2.37 it hid behind the glass rail).
        B.box(LIGHT, (-0.533, 0.25, 2.86), (0.022, 0.42, 0.13), bevel=0)
        B.box(LIGHT, (0.25, -0.533, 2.86), (0.42, 0.022, 0.13), bevel=0)

    def gate(self, B):
        for side in (-1, 1):
            with B.module("tower" if side == 1 else "gate post"), B.frame(B.pylon_frame(side)):
                self.gate_pylon(B, side)
        # The user removed the canopy: preserve the open entrance in both variants.

    def gate_pylon(self, B, side):
        if side == -1:
            y = self.ENTRY_Y
            # The tower's companion: same plinth height, same glazing module (0.58-ish columns, 1.02 floors),
            # so the lone post reads as a finished piece of the same building now that the canopy is gone.
            B.box(DARK, (0, y, 0.24), (1.52, 2.06, 0.48), open="-z", bevel=0.09)
            B.box(DARK, (0, y, self.ENTRY_POST_TOP / 2),
                  (1.24, 1.8, self.ENTRY_POST_TOP), open="-z", bevel=0.09)
            B.box(STEEL, (0, y, self.ENTRY_POST_TOP + self.ENTRY_CAP_THICKNESS / 2),
                  (1.3, 1.86, self.ENTRY_CAP_THICKNESS), bevel=0.025)
            front, back = y + 0.9, y - 0.9
            window_panels(B, rect_poly(-0.47, 0.47, 0.48, 7.62), [-0.47, 0.0, 0.47],
                          [0.48 + k * 1.02 for k in range(8)],
                          [(front - 0.003, front + 0.039), (back - 0.039, back + 0.003)])
            B.box(LIGHT, (-0.63, y + 0.01, 6.50), (0.025, 0.46, 0.12), bevel=0)
            return
        # Facing the entrance, the tall spine is on the left and the deck projects to the right,
        # matching the supplied building silhouette. Local tower +X points INTO the gate.
        with B.frame(S(-1, 1, 1)):
            self.tower(B)

    def tower(self, B):
        B.box(DARK, (0, 0.47, 0.24), (2.36, 2.02, 0.48), open="-z", bevel=0.09)
        top_left = (-1.06, 15.36)
        # The crown's back edge now runs straight up the spine (the old slanted edge left a slit beside it).
        outline = [(-1.06, 0.48)] + TOWER_EDGE + [(3.22, 11.1), (1.16, 12.82), (0.65, 15.68), top_left]
        # Separate the upper cantilever from the lower piece for exact gate-clearance checks.
        B.plate(DARK, clip_window(outline, 1, 7.7, False), -0.46, 1.35, bevel=0.045, segs=2)
        B.plate(DARK, clip_window(outline, 1, 7.7, True), -0.46, 1.35, bevel=0.045, segs=2)
        # Real fitted panes replace the floating, fixed-length facade lines.
        facade = [(-1.06, 0.48)] + TOWER_EDGE + [(3.22, 11.1), (-1.06, 10.68)]
        xs = [-1.06 + k * 0.58 for k in range(11)]
        zs = [0.48 + k * 1.02 for k in range(11)]
        window_panels(B, facade, xs, zs, [(1.347, 1.389), (-0.499, -0.457)])
        crown = [(-1.06, 13.57), (1.025, 13.57), (0.65, 15.68), top_left]
        window_panels(B, crown, xs, [13.57, 14.6, 15.72], [(1.347, 1.389), (-0.499, -0.457)])
        # The perimeter spine is structural, rather than a grid drawn over the facade; it now reaches the crown's
        # top corner (a slim fin just proud of it) instead of stopping short beside the slope.
        B.box(DARK, (-1.07, 0.44, (0.48 + 15.42) / 2), (0.10, 1.89, 15.42 - 0.48), open="-z", bevel=0.025)
        # Curving brushed-metal support: ONE mitred band that wraps the curved edge from the plinth to the terrace,
        # just proud of both glazed faces (cut at the gate-clearance height, the cut left open: no seam).
        edge_band(B, STEEL, TOWER_EDGE, 0.10, 0.03, -0.52, 1.41, 0.48, (GATE_CLEAR_H + 0.02,), 0.03, 2)
        # The recognizable forward observation box and the separate projecting landing terrace.
        terrace = [(-1.10, 10.65), (4.83, 10.65), (5.17, 10.79), (4.5, 11.02), (-1.10, 11.02)]
        B.plate(STEEL, terrace, -0.57, 1.74, bevel=0.045, segs=2)
        pod = [(-0.88, 11.18), (3.84, 11.18), (4.15, 12.63), (0.40, 13.50), (-0.88, 13.50)]
        # The pod stands clearly proud of the tower on the pen side too (its back face lay 0.01 off the tower's).
        B.plate(DARK, pod, -0.53, 1.55, bevel=0.075, segs=2)
        window = [(-0.66, 11.50), (3.59, 11.50), (3.82, 12.43), (0.35, 13.23), (-0.66, 13.23)]
        window_panels(B, window, [-0.66, 0.45, 1.56, 2.67, 3.84],
                      [11.50, 12.36, 13.26], [(1.547, 1.589), (-0.572, -0.527)], border=0.035)
        # Balcony rails under the logo: seated on the pod face (they floated 0.02 off the glass).
        for z in (11.27, 11.44):
            B.box(STEEL, (1.49, 1.58, z), (4.50, 0.08, 0.045), bevel=0)
        # One Avengers A, attached to the tower rather than repeated on the fence: its back now sits on the pod
        # face through the glazing (it floated 0.09 in front of the glass), centred in the window above the rails.
        with B.frame(T(0.78, 1.55, 12.32) @ facing((0, 1)) @ S(-0.56, 0.56, 0.56)):
            self.emblem(B)
        # (the soft PointLight on the A is gone: no lights in the bases, owner 2026-09-25)

    def gate_lintel(self, B):
        pass  # Open entrance, deliberately no beam or floating underside light.

    def emblem(self, B):
        # Stepped relief: the ring stands 0.10 off the pod, the A (with its arrow) 0.17, both bevelled.
        # (their backs sink 0.02 into the pod face; the arrow's face sits a step under the A's)
        B.ring(LOGO, (0, 0, -0.04), 1.35, 1.45, 0.22, n=48, bevel=0)
        B.prism(LOGO, A_OUTLINE, -0.04, 0.30, bevel=0.012, segs=1)
        B.prism(LOGO, A_ARROW, -0.04, 0.25, bevel=0.012, segs=1)

    def terminal(self, B):
        # Quiet kiosk around the existing functional upgrade display. It closes its stretch of the front fence
        # (the rails end inside the back wall), the steel jambs stand on the ground and frame the accent bezel flush,
        # and the roof covers the whole kiosk.
        with B.frame(B.terminal_frame()):
            B.box(DARK, (0, -1.495, 2.43), (7.0, 0.97, 4.86), open="-z +z", bevel=0.10)
            for side in (-1, 1):
                B.box(STEEL, (side * 3.15, -0.115, 2.42), (0.18, 1.83, 4.84), open="-z", bevel=0.035)
            B.box(DARK, (0, -0.59, 4.99), (7.04, 2.86, 0.34), bevel=0.07)
            # the pen-facing back wall carries the tower's glazing module instead of a blank slab
            window_panels(B, rect_poly(-3.36, 3.36, 0.48, 4.56), [-3.36 + k * 1.12 for k in range(7)],
                          [0.48 + k * 1.02 for k in range(5)], [(-2.022, -1.977)])
        self.screen_bezel(B, t=0.075, depth=0.10, gap=0.035)


THEME = Theme()
