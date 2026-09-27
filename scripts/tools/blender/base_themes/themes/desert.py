# scripts/tools/blender/base_themes/themes/desert.py
# Desert = SPIDER-VERSE: "Brooklyn Rooftop" (owner art direction 2026-09-24, API v3; redesigned 2026-09-25: "improve
# the Spider-Man base: the logo looks choppy; add more of that Spider-Verse style (Miles Morales, Spider-Gwen) like in
# v1, which even had the buildings"; second pass 2026-09-25: "work more on the detailed buildings and the spider webs,
# remove that Spider-Man; make the windows have those lights, in Roblox Studio we will put that effect where one turns
# off, one turns on"; no Neon anywhere, no lights).
#   Pen: a Brooklyn rooftop. Perimeter (kept identity): a low red brick parapet (a dark brick water table, four brick
#   courses over a recessed dark mortar core, a limestone coping) carrying black wrought-iron fire-escape railings
#   (bottom rail, square pickets, hand rail) and a hooked fire-escape drop ladder on the left wall. Posts: brick piers
#   with limestone caps and glossy pink / teal studs (Spider-Gwen). Corners: brick chimney stacks with limestone crowns
#   and galvanised mushroom vents on pink collars, each with a clean white quarter orb web spun between the stack and
#   the coping (evenly spaced radials and rings, anchored on both); another web between the left gate pylon and the
#   coping. Gate: two brick pylons (popped bricks, misregistered pink / teal glitch bars) under a black iron arch with an
#   orb web spun in it; in the web hangs the 3D emblem: a yellow comic burst with a pink print shadow behind a black
#   medallion carrying Miles Morales' smooth red spider. Floor: rooftop asphalt panels with a crisp white graffiti
#   spider web (eight radials and four evenly spaced sagging rings as flat paint strokes), a zebra crosswalk at the
#   gate, a yellow "THWIP!" comic burst with a pink shadow and black letters, a teal star burst with a pink offset, a
#   pink star burst, pink / teal halftone diamonds. Centre: the big Miles emblem in bevelled layers (pink / teal
#   misprint discs under a black medallion, the smooth red spider on top).
#   Terminal: a steel generator whose visor hood frames the upgrade sign's pink bezel.
#   Landmark (behind the back fence): a Brooklyn block on a sidewalk, no character figure (owner: "remove that
#   Spider-Man"):
#     A  a red brick walk-up: stone sill and belt courses, framed windows, a bracketed stone cornice with a parapet,
#        a bodega (two shop windows, a pink / white striped awning), a chimney and vent pipes, and the rooftop
#        "SPIDER-VERSE" billboard (white block letters on a black board, pink / teal misprint boards, legs, braces and
#        a catwalk);
#     B  a tall brownstone: a rusticated stone ground floor with a stoop (stone steps, iron rails, a bracketed door
#        hood, a red door), stone quoin pilasters, stone sill courses, framed windows (heavy heads), side windows over the
#        neighbours' roofs, a window air conditioner, a bracketed cornice, a black iron fire escape (four grated
#        platforms on wall brackets with railings, zig-zag stair flights with real steps and hand rails, a drop ladder,
#        a gooseneck ladder over the parapet, a small web draped in its railing) and the classic wooden water tower on
#        its stilts;
#     C  a limestone corner building: a teal-striped storefront (three shop windows), brick sill courses, framed
#        windows, a window air conditioner, a bracketed cornice, a Spider-Gwen mural on its side wall, a stair bulkhead, an AC unit and vents on the roof;
#     white web lines slung between the roofs and a big quarter orb web in the corner of the brownstone and the
#     limestone roof. Its mass stands >= 11.6 studs behind the fence (the players' camera stays in front of the facades).
# WINDOW LIGHTS (owner 2026-09-25): the windows' glass is NOT modelled. Every window records a pane SLOT (centre, size,
#   facing normal, building id, optional accent colour) that run.py writes into the layout JSON (variants[v].windows +
#   the top-level window_lights style); the build (scripts/steps/post_zz_base_themes.luau section 8) makes one flat
#   SmoothPlastic pane Part per slot on every plot where the pen is placed (lit warm yellow / Spider-Verse pink / teal,
#   off = dark blue-grey glass; never Neon, no lights) and StarterPlayerScripts.Game.Plots.BaseWindowLights turns a
#   few of them off / on every 2..12 s like a city at night. The Blender previews show the panes lit (render-only boxes
#   from preview_extras). The slots are not geometry: they never change the layout's geometry fingerprint.
# No Neon, no lights: the accent colours (Neon_Emissive_* = pink / teal / the bezel) are glossy SmoothPlastic.

import json
import math
import random
import sys

import bmesh
from mathutils import Vector

from common import *
from common import _drop_faces

FLOOR = "Floor_Base"
BRICK, BRICK_DK, STONE = "Structure_Brick", "Structure_BrickDark", "Structure_Concrete"
IRON, STEEL, WOOD = "Structure_Iron", "Structure_Steel", "Structure_Wood"
C_RED, C_BLACK, C_WHITE, C_YELLOW, C_METAL = "Core_3D_Red", "Core_3D_Black", "Core_3D_White", "Core_3D_Yellow", "Core_3D_Metal"
MAGENTA, CYAN, SCREEN = "Neon_Emissive_Magenta", "Neon_Emissive_Cyan", "Neon_Emissive_Screen"

PINK_RGB = (232, 58, 152)   # Spider-Gwen pink (non-emissive: a notch darker than the old neon swatch)
TEAL_RGB = (30, 190, 212)   # Spider-Gwen teal

# -- the parapet (side frame: y outward, z up). Posts, corners and pylons own the y = -0.62 line; the wall stays at
#    y >= -0.6 so their inner faces never z-fight with it.
WALL_IN, WALL_OUT = -0.5, 0.92
PLINTH = [(-0.6, 0.0), (1.06, 0.0), (1.06, 0.36), (0.98, 0.46), (-0.6, 0.46)]
BRICK_Z = (0.46, 2.32)
COURSE = 0.465          # four brick courses between the water table and the coping
COPING = [(-0.6, 2.32), (1.1, 2.32), (1.1, 2.48), (0.98, 2.62), (-0.46, 2.62), (-0.6, 2.5)]
COPE_TOP = 2.62
RAIL_Y = (0.52, 0.74)   # the iron railing's bars stand on the outer half of the coping
RAIL_TOP = 4.12
PICKET = 2.1            # picket pitch
WEB_Y = (RAIL_Y[0] + RAIL_Y[1]) / 2 - 0.13  # the fence webs hang just inside the pickets' plane

# -- the gate: the iron arch springs from the pylon caps (gate frame: X = +v, Y = outward)
ARCH_Z, ARCH_R, ARCH_T, ARCH_Y, ARCH_DEPTH = 7.96, 5.25, 0.5, 0.54, 0.64

# -- the landmark (landmark frame: X = -v = a player's right looking at it from the pen, Y = depth behind the back
#    fence line, Z up). Three buildings on a sidewalk; their facades face the pen (-Y).
GROUND, STOREY = 4.4, 3.6
SIDEWALK = (1.36, 13.3)
BLD_A = dict(x=(-27.2, -9.5), y=(11.6, 23.3), n=3)   # red brick walk-up + bodega + billboard
BLD_B = dict(x=(-9.6, 8.7), y=(13.0, 23.3), n=5)     # brownstone + fire escape + water tower
BLD_C = dict(x=(8.6, 27.2), y=(11.6, 23.3), n=2)     # limestone corner building + mural
WIN = (1.9, 2.3)        # window pane size (w, h)
TRIM = (0.5, 0.74)      # the stone / brick window frame plate: the pane + this (w, h)
TRIM_FOOT, TRIM_HEAD = 0.1, 0.44  # the frame plate's border under the pane (hidden by the sill) / its head over it
TRIM_OUT = 0.14         # the frame plate stands this proud of the facade

# -- window lights: the pane Parts the build makes from the slots (never modelled; see WINDOW LIGHTS above)
PANE_T, PANE_GAP = 0.08, 0.02   # pane thickness; its back face stands PANE_GAP in front of the frame plate
LIT_RGB = (255, 204, 64)        # a lit room: warm yellow
OFF_RGB = (46, 56, 80)          # a dark room: blue-grey glass
WINDOW_LIGHTS = {
    "format": "stealahero-windows/1",
    "material": "SmoothPlastic",
    "lit_rgb": list(LIT_RGB),
    "off_rgb": list(OFF_RGB),
    "thickness": PANE_T,
    "lit_fraction": 0.8,
    "flicker": {"min_gap_s": 2.0, "max_gap_s": 12.0, "tween_s": 0.25, "range_studs": 250.0},
    "note": ("one flat pane Part per slot (post_zz_base_themes section 8): Anchored, CanCollide / CanQuery / CanTouch / "
             "CastShadow off, SmoothPlastic, lit = the slot's lit_rgb or this lit_rgb, off = off_rgb; never Neon, no lights; "
             "StarterPlayerScripts.Game.Plots.BaseWindowLights turns a few off / on at a time. Slots: c = pane centre and n "
             "= its facing normal in the pen frame (x = v, y = u, z = h), size = (width, height)"),
}


def top_of(bld):
    """A building's roof height: the ground floor, its storeys and a 0.4 frieze under the cornice."""
    return GROUND + bld["n"] * STOREY + 0.4


def storey_rows(n):
    """The window centres of n storeys above the ground floor."""
    return [GROUND + k * STOREY + 1.5 for k in range(n)]


def courses(z0=None, z1=None, course=COURSE, gap=0.07):
    """The brick courses between the water table and the coping: [(z0, z1), ...] with a mortar joint between two."""
    z0 = BRICK_Z[0] if z0 is None else z0
    z1 = BRICK_Z[1] if z1 is None else z1
    n = max(1, int(round((z1 - z0) / course)))
    step = (z1 - z0) / n
    out = []
    for i in range(n):
        a = z0 + i * step + (gap / 2 if i > 0 else 0.0)
        b = z0 + (i + 1) * step - (gap / 2 if i < n - 1 else 0.0)
        out.append((a, b))
    return out


def bar(y0, y1, z0, z1):
    return rect_profile(y0, y1, z0, z1)


def quad(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def chaikin(pts, iterations):
    """Corner-cutting subdivision of an open polyline (end points kept): smooth curves from a few control points."""
    for _ in range(iterations):
        out = [pts[0]]
        for a, b in zip(pts, pts[1:]):
            out += [(0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]),
                    (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1])]
        out.append(pts[-1])
        pts = out
    return pts


def resample(pts, n):
    """n points evenly spaced by arc length along an open polyline (end points kept): an even, smooth outline with a
    fixed point budget."""
    P = [Vector(p) for p in pts]
    seg = [(b - a).length for a, b in zip(P, P[1:])]
    total = sum(seg)
    out, i, acc = [], 0, 0.0
    for k in range(n):
        t = total * k / (n - 1)
        while i < len(seg) - 1 and acc + seg[i] < t:
            acc += seg[i]
            i += 1
        f = 0.0 if seg[i] <= 1e-9 else min(1.0, max(0.0, (t - acc) / seg[i]))
        p = P[i].lerp(P[i + 1], f)
        out.append((p.x, p.y))
    return out


# -- the spider (drawing plane: x right, y = the head's direction; ~2.5 wide x 2.5 long at scale 1). SMOOTH: the body
#    outline is chaikin-smoothed from these control points (right half, head to tail), resampled evenly by arc length
#    and mirrored; every leg is a tapered stroke with a rounded knee (quadratic Bezier) and a sharp tip.
SPIDER_BODY = [(0.0, 1.0), (0.1, 0.975), (0.165, 0.9), (0.175, 0.8), (0.13, 0.71), (0.09, 0.665), (0.2, 0.6),
               (0.29, 0.48), (0.31, 0.34), (0.27, 0.18), (0.16, 0.06), (0.14, 0.0), (0.22, -0.1), (0.27, -0.3),
               (0.25, -0.56), (0.18, -0.8), (0.09, -0.98), (0.0, -1.08)]
SPIDER_LEGS = [((0.04, 0.5), (0.62, 0.86), (0.46, 1.5)),     # hip (inside the thorax), knee, tip
               ((0.04, 0.38), (1.04, 0.6), (1.22, 1.18)),
               ((0.04, 0.24), (1.04, -0.1), (1.22, -0.78)),
               ((0.04, 0.12), (0.7, -0.52), (0.58, -1.4))]
LEG_W = (0.1, 0.092, 0.088, 0.082, 0.014)   # half widths along a rounded leg (hip .. tip)
LEG_W3 = (0.1, 0.09, 0.016)                 # half widths along a 3-point leg (hip, knee, tip)


def thick_line(pts, widths):
    """A polyline thickened into a simple polygon (mitred joints; widths = half widths per point)."""
    P = [Vector(p) for p in pts]
    n = len(P)
    left, right = [], []
    for i in range(n):
        if i == 0:
            d = (P[1] - P[0]).normalized()
            m, k = Vector((-d.y, d.x)), 1.0
        elif i == n - 1:
            d = (P[i] - P[i - 1]).normalized()
            m, k = Vector((-d.y, d.x)), 1.0
        else:
            d0, d1 = (P[i] - P[i - 1]).normalized(), (P[i + 1] - P[i]).normalized()
            n0, n1 = Vector((-d0.y, d0.x)), Vector((-d1.y, d1.x))
            m = (n0 + n1).normalized()
            k = max(m.dot(n0), 0.35)
        w = widths[i] / k
        left.append((P[i].x + m.x * w, P[i].y + m.y * w))
        right.append((P[i].x - m.x * w, P[i].y - m.y * w))
    return left + list(reversed(right))


def leg_line(hip, knee, tip, rounded=True):
    """hip -> a rounded knee (three points on a quadratic Bezier) -> tip; rounded=False: hip, knee, tip."""
    h, k, t = Vector(hip), Vector(knee), Vector(tip)
    if not rounded:
        return [tuple(h), tuple(k), tuple(t)]
    a = k + (h - k) * 0.24
    c = k + (t - k) * 0.2
    m = 0.25 * a + 0.5 * k + 0.25 * c
    return [tuple(h), tuple(a), tuple(m), tuple(c), tuple(t)]


def spider_polys(scale=1.0, head=1.0, dx=0.0, dy=0.0, body_pts=20, rounded=True):
    """[body, leg x 8] polygons of the smooth spider (head toward +y when head = 1, toward -y when head = -1).
    body_pts = outline points per half (arc-length resampled); rounded = legs with rounded knees (5 points per side)."""
    def tf(p):
        return (p[0] * scale + dx, p[1] * scale * head + dy)
    right = resample(chaikin(SPIDER_BODY, 2), body_pts)
    body = right + [(-x, y) for x, y in reversed(right[1:-1])]
    polys = [[tf(p) for p in body]]
    widths = LEG_W if rounded else LEG_W3
    for hip, knee, tip in SPIDER_LEGS:
        for s in (1, -1):
            line = [(s * x, y) for x, y in leg_line(hip, knee, tip, rounded)]
            polys.append([tf(p) for p in thick_line(line, widths)])
    return polys


def star_burst(n, r_out, r_in, seed, sx=1.0, rot=0.0, jitter=0.14):
    """A comic burst: 2n points alternating r_out / r_in (jittered), stretched by sx along x."""
    rnd = random.Random(seed)
    pts = []
    for k in range(2 * n):
        a = rot + math.pi * k / n
        r = (r_out if k % 2 == 0 else r_in) * (1.0 + rnd.uniform(-jitter, jitter))
        pts.append((r * math.cos(a) * sx, r * math.sin(a)))
    return pts


def splat(n, r, seed, jitter=0.3):
    """A spray-paint splat outline (n points, lumpy radius)."""
    rnd = random.Random(seed)
    return [(r * (1 + rnd.uniform(-jitter, jitter * 0.6)) * math.cos(2 * math.pi * k / n),
             r * (1 + rnd.uniform(-jitter, jitter * 0.6)) * math.sin(2 * math.pi * k / n)) for k in range(n)]


def stair_outline(xa, z, s, n, tread, rise, d=0.4):
    """A fire-escape stair flight in the XZ plane: n real steps (tread x rise) climbing from (xa, z) along s = +1 / -1,
    a stringer d thick under them (the underside parallel to the pitch), cut vertically at the top."""
    pts = [(xa, z)]
    for i in range(n):
        pts.append((xa + s * i * tread, z + (i + 1) * rise))
        pts.append((xa + s * (i + 1) * tread, z + (i + 1) * rise))
    pts.append((xa + s * n * tread, z + n * rise - d))
    pts.append((xa + s * d * tread / rise, z))
    return pts


# -- the block font (Spider-Verse title letters) in a 0.8 x 1.2 cell (x right, y up): each glyph = (width, polygons),
#    strokes merged into as few simple polygons as the counters allow (fewer side walls = fewer triangles).
_P = [[(0, 0), (0.2, 0), (0.2, 1.0), (0.8, 1.0), (0.8, 1.2), (0, 1.2)],
      [(0.2, 0.5), (0.8, 0.5), (0.8, 1.0), (0.6, 1.0), (0.6, 0.7), (0.2, 0.7)]]
GLYPHS = {
    "S": (0.8, [[(0, 0), (0.8, 0), (0.8, 0.7), (0.2, 0.7), (0.2, 1.0), (0.8, 1.0), (0.8, 1.2), (0, 1.2), (0, 0.5),
                 (0.6, 0.5), (0.6, 0.2), (0, 0.2)]]),
    "P": (0.8, _P),
    "I": (0.2, [quad(0, 0, 0.2, 1.2)]),
    "D": (0.8, [[(0, 0), (0.6, 0), (0.6, 0.2), (0.2, 0.2), (0.2, 1.0), (0.6, 1.0), (0.6, 1.2), (0, 1.2)],
                [(0.6, 0), (0.8, 0.2), (0.8, 1.0), (0.6, 1.2)]]),
    "E": (0.8, [[(0, 0), (0.8, 0), (0.8, 0.2), (0.2, 0.2), (0.2, 0.5), (0.66, 0.5), (0.66, 0.7), (0.2, 0.7), (0.2, 1.0),
                 (0.8, 1.0), (0.8, 1.2), (0, 1.2)]]),
    "R": (0.8, _P + [[(0.36, 0.5), (0.58, 0.5), (0.82, 0.0), (0.6, 0.0)]]),
    "-": (0.6, [quad(0.05, 0.5, 0.55, 0.7)]),
    "V": (0.8, [[(0, 1.2), (0.22, 1.2), (0.4, 0.36), (0.58, 1.2), (0.8, 1.2), (0.52, 0), (0.28, 0)]]),
    "T": (0.8, [[(0, 1.0), (0.3, 1.0), (0.3, 0), (0.5, 0), (0.5, 1.0), (0.8, 1.0), (0.8, 1.2), (0, 1.2)]]),
    "H": (0.8, [quad(0, 0, 0.2, 1.2), quad(0.6, 0, 0.8, 1.2), quad(0.2, 0.5, 0.6, 0.7)]),
    "W": (0.8, [[(0, 0), (0.8, 0), (0.8, 1.2), (0.62, 1.2), (0.62, 0.2), (0.49, 0.2), (0.49, 0.8), (0.31, 0.8),
                 (0.31, 0.2), (0.18, 0.2), (0.18, 1.2), (0, 1.2)]]),
    "!": (0.2, [quad(0, 0.4, 0.2, 1.2), quad(0, 0, 0.2, 0.22)]),
}


def text_strokes(text, size, gap=0.22):
    """The glyph polygons of `text` (cell height 1.2 -> `size` studs), centred on the origin."""
    s = size / 1.2
    width = sum(GLYPHS[c][0] for c in text) + gap * (len(text) - 1)
    x = -width / 2
    out = []
    for c in text:
        w, polys = GLYPHS[c]
        for q in polys:
            out.append([((x + px) * s, (py - 0.6) * s) for px, py in q])
        x += w + gap
    return out


# ----------------------------------------------------------------------------------------------------------------------
# window slots -> the layout JSON (a guarded shim until pipeline.export_theme writes them itself)
# ----------------------------------------------------------------------------------------------------------------------

def _install_window_export():
    """run.py's pipeline.export_theme writes the layout JSON; this wraps it (once per Blender session) so that, for any
    theme whose builders recorded window slots (Builder attribute `window_slots`), the written JSON also carries
    variants[<v>].windows and the theme's WINDOW_LIGHTS style as "window_lights". Geometry-neutral: the fingerprint
    (pipeline.geometry_fingerprint / Step.geometryFingerprint) never reads them."""
    P = sys.modules.get("pipeline")
    if P is None or getattr(P.export_theme, "window_slots_shim", False):
        return
    base = P.export_theme

    def export_theme(theme, builders, problems, renders=None):
        result = base(theme, builders, problems, renders)
        slots = {vname: list(getattr(B, "window_slots", None) or []) for vname, B in builders.items()}
        if any(slots.values()):
            json_path, layout = result[1], result[3]
            with open(json_path, encoding="utf-8") as fh:
                data = json.load(fh)
            data["window_lights"] = dict(getattr(theme, "WINDOW_LIGHTS", None) or {})
            layout["window_lights"] = data["window_lights"]
            for vname, entries in slots.items():
                if vname in data["variants"]:
                    data["variants"][vname]["windows"] = entries
                    layout["variants"][vname]["windows"] = entries
            with open(json_path, "w", encoding="utf-8") as fh:
                json.dump(data, fh, indent=1)
            print("[base_themes] %s window slots: %s (panes the build makes; not geometry)" % (
                theme.KEY, ", ".join("%s %d" % (v, len(s)) for v, s in slots.items())))
        return result

    export_theme.window_slots_shim = True
    P.export_theme = export_theme


_install_window_export()


class Theme(PenTheme):
    KEY, NAME, TITLE, FRANCHISE = "Desert", "BrooklynRooftop", "Brooklyn Rooftop", "Spider-Verse"
    PALETTE = {
        FLOOR: look((58, 60, 72), "Plastic"),
        BRICK: look((176, 60, 46), "SmoothPlastic", bevel=0.045),
        BRICK_DK: look((104, 38, 36), "SmoothPlastic", bevel=0.07),
        STONE: look((218, 210, 194), "SmoothPlastic", bevel=0.06),
        IRON: look((30, 30, 38), "SmoothPlastic", reflectance=0.04, bevel=0.035),
        STEEL: look((66, 84, 118), "SmoothPlastic", reflectance=0.04, bevel=0.08),
        WOOD: look((150, 98, 60), "SmoothPlastic", bevel=0.05),
        C_RED: look((214, 30, 44), "SmoothPlastic", bevel=0.04),
        C_BLACK: look((24, 24, 32), "SmoothPlastic", bevel=0.035),
        C_WHITE: look((238, 240, 246), "SmoothPlastic", bevel=0.0),
        C_YELLOW: look((255, 206, 46), "SmoothPlastic", bevel=0.0),
        C_METAL: look((150, 160, 174), "SmoothPlastic", reflectance=0.1, bevel=0.04),
        MAGENTA: look(PINK_RGB, "SmoothPlastic", reflectance=0.05),
        CYAN: look(TEAL_RGB, "SmoothPlastic", reflectance=0.05),
        SCREEN: look(PINK_RGB, "SmoothPlastic", reflectance=0.06),
    }
    WINDOW_LIGHTS = WINDOW_LIGHTS
    TILES = {"Std": (5, 5), "Deep": (5, 6)}  # 10.5-stud roof panels: every seam runs to a pier
    TERMINAL_GAP = (SIGN_V[0] - 1.0, SIGN_V[1] + 1.0)
    EMBLEM_Z = 10.72       # the emblem hangs in the arch's web (lowest point ~8.5, the arch apex 13.2)
    EMBLEM_OUT = ARCH_Y
    STUDIO_RGB = (206, 210, 220)
    GEN_X = (3.14, 3.95)   # generator cabinets: terminal-frame |x| range (the sign spans |x| <= 2.93, its bezel 3.11)
    MORTAR = BRICK_DK      # the recessed mortar core between the brick courses (dark: the courses read as brick)
    GEN_GATE_X = 4.14      # the gate-side cabinet reaches into the gate pylon (v 6.3): no slit between them
    MEDALLION_R = 7.4      # the centre emblem's black medallion (the spider's leg tips stay 0.25 inside)

    def __init__(self):
        self.preview_slots = []  # the last Std build's window slots (render-only lit panes, preview_extras)

    # -- helpers ---------------------------------------------------------------------------------------------------
    def stud(self, B, role, pos, r=0.27, h=0.15, chamfer=0.055, n=6, axis="z"):
        """A toy stud with a chamfered top and NO bottom face (it always stands on something): 28 tris at n = 6."""
        bm = bm_lathe([(r, 0.0), (r, h - chamfer), (r - chamfer, h)], n, math.pi / n, cap=True)
        _drop_faces(bm, "-z")
        B.mesh(role, bm, B._m(pos, None, axis), bevel=0, smooth=True)

    def pillow_brick(self, B, role, x, z, y, face=1, length=1.3, height=0.36, depth=0.08, c=0.035):
        """A brick popping out of a wall face at y (current frame; face +1 = toward +y, -1 = toward -y): a lofted block
        with chamfered edges by construction (10 tris, no modifier bevel needed)."""
        hl, hh = length / 2, height / 2
        bm = bm_loft([(0.0, rect_poly(-hl, hl, -hh, hh)), (depth, rect_poly(-hl + c, hl - c, -hh + c, hh - c))],
                     cap_bottom=False)
        B.mesh(role, bm, T(x, y, z) @ AXES["y" if face > 0 else "-y"], bevel=0)

    def strand(self, B, p0, p1, w=0.13, role=C_WHITE, t=0.03):
        """A web strand in a vertical plane: a flat two-faced ribbon (4 tris) from p0 to p1 (current frame), its broad
        faces across the plane's normal (the fence / gate / facade plane), `w` wide."""
        B.beam(role, p0, p1, t, w, bevel=0, open="+x -x +z -z")

    def thread(self, B, p0, p1, r=0.06, role=C_WHITE):
        """A free web line: an open triangular tube from p0 to p1 (6 tris), in the current frame."""
        a, b = Vector(p0), Vector(p1)
        d = b - a
        z = d.normalized()
        ref = Vector((0.0, 0.0, 1.0)) if abs(z.z) < 0.95 else Vector((1.0, 0.0, 0.0))
        x = ref.cross(z).normalized()
        y = z.cross(x)
        tri = [(r * math.cos(t), r * math.sin(t)) for t in (math.pi / 2, math.pi / 2 + 2.0944, math.pi / 2 + 4.1888)]
        bm = bm_loft([(0.0, tri), (d.length, tri)], cap_top=False, cap_bottom=False)
        B.mesh(role, bm, basis(x, y, z, a), bevel=0, cull=False)

    def corner_web(self, B, hub, a, b, xdir=1, n_rad=5, rings=(0.3, 0.52, 0.74, 0.95), w_rad=0.13, w_ring=0.1, y=None):
        """A clean quarter orb web in the frame's XZ plane (at y = hub[1]) spun in the corner at `hub` between a
        horizontal support (running toward x * xdir, `a` long) and a vertical one (up, `b` high): n_rad radials evenly
        spaced over the quarter (the first along the horizontal support, the last up the vertical one), their ends on
        the quarter ellipse (a, b); rings at the given fractions of every radial (straight threads between neighbouring
        radials: evenly spaced, the outermost one the frame thread)."""
        H = Vector(hub)
        ends = []
        for i in range(n_rad):
            t = (math.pi / 2) * i / (n_rad - 1)
            ends.append(H + Vector((xdir * a * math.cos(t), 0.0, b * math.sin(t))))
        for e in ends:
            self.strand(B, H, e, w_rad)
        for f in rings:
            pts = [H.lerp(e, f) for e in ends]
            for p, q in zip(pts, pts[1:]):
                self.strand(B, p, q, w_ring)

    def ribbon(self, B, role, path, w, z, closed=False):
        """A crisp flat paint stroke on the floor: ONE top-facing quad strip (mitred joints) along `path` [(x, y), ...]
        at height z, 2 tris per segment (no side walls: clean edges, reads like fresh graffiti)."""
        pts = [Vector((p[0], p[1])) for p in path]
        n = len(pts)
        bm = bmesh.new()
        L, R = [], []
        for i in range(n):
            if closed:
                d0 = (pts[i] - pts[i - 1]).normalized()
                d1 = (pts[(i + 1) % n] - pts[i]).normalized()
            else:
                d0 = (pts[i] - pts[i - 1]).normalized() if i > 0 else (pts[1] - pts[0]).normalized()
                d1 = (pts[i + 1] - pts[i]).normalized() if i < n - 1 else d0
            t = d0 + d1
            t = t.normalized() if t.length > 1e-6 else d1
            m = Vector((-t.y, t.x))
            k = max(m.dot(Vector((-d1.y, d1.x))), 0.35)
            off = m * (w / 2 / k)
            L.append(bm.verts.new((pts[i].x + off.x, pts[i].y + off.y, z)))
            R.append(bm.verts.new((pts[i].x - off.x, pts[i].y - off.y, z)))
        for i in range(n if closed else n - 1):
            j = (i + 1) % n
            bm.faces.new((R[i], R[j], L[j], L[i]))
        B.mesh(role, bm, bevel=0)

    def spider(self, B, scale, z0, z1, role, head=1.0, body_pts=20, rounded=True, body_bevel=0.03, leg_bevel=0.0,
               leg_drop=0.02):
        """The smooth spider in relief (frame XY, extruded z0..z1): the body a notch above the legs so their hips hide
        inside it."""
        polys = spider_polys(scale, head, body_pts=body_pts, rounded=rounded)
        B.relief(polys[0], [(role, 0.0, z0, z1, body_bevel)])
        for poly in polys[1:]:
            B.relief(poly, [(role, 0.0, z0, z1 - leg_drop, leg_bevel)])

    # -- floor: asphalt roof panels, the graffiti web, the crosswalk, comic bursts, halftone ----------------------------
    def floor(self, B):
        W, D = B.W, B.D
        nx, ny = self.TILES[B.variant]
        B.tiles(FLOOR, -W, -D, W, D, nx, ny, inset=0.24)
        # the zebra crosswalk at the gate: flat white paint bars
        for k in range(5):
            x = -2.6 + 1.3 * k
            self.ribbon(B, C_WHITE, [(x, D - 3.3), (x, D - 0.9)], 0.66, 0.13)
        # the graffiti web spun from the centre: eight radials (never toward the gate or the terminal) and four evenly
        # spaced rings sagging a little toward the hub between two radials, all crisp flat strokes (rings under radials)
        R0 = self.MEDALLION_R + 0.5
        angs = [math.pi / 8 + k * math.pi / 4 for k in range(8)]
        for r in (11.0, 15.0, 19.0, 23.0):
            path = []
            for a in angs:
                path.append((r * math.cos(a), r * math.sin(a)))
                am = a + math.pi / 8
                path.append((0.9 * r * math.cos(am), 0.9 * r * math.sin(am)))
            self.ribbon(B, C_WHITE, path, 0.26, 0.13, closed=True)
        for a in angs:
            c, s = math.cos(a), math.sin(a)
            t = min((W - 0.95) / abs(c), (D - 0.95) / abs(s))
            self.ribbon(B, C_WHITE, [(R0 * c, R0 * s), (t * c, t * s)], 0.3, 0.14)
        # "THWIP!": a yellow comic burst with a pink print shadow and black block letters (reads from the gate)
        with B.frame(T(-14.6, -13.2, 0.0) @ Rz(math.pi + 0.12)):
            burst = star_burst(11, 4.3, 3.0, 7, sx=1.34)
            with B.frame(T(0.4, -0.36, 0.0)):
                B.prism(MAGENTA, burst, 0.08, 0.16, bevel=0)
            B.prism(C_YELLOW, burst, 0.08, 0.19, bevel=0)
            for q in text_strokes("THWIP!", 1.8):
                B.relief(q, [(C_BLACK, 0.0, 0.19, 0.25, 0)])
        # a teal star burst with a pink misprint offset (back right), a pink star burst (front right)
        with B.frame(T(15.0, -14.0, 0.0) @ Rz(0.3)):
            star = star_burst(8, 3.9, 2.0, 3, sx=1.0)
            with B.frame(T(-0.34, 0.3, 0.0)):
                B.prism(MAGENTA, star, 0.08, 0.15, bevel=0)
            B.prism(CYAN, star, 0.08, 0.18, bevel=0)
        with B.frame(T(15.2, 12.6, 0.0) @ Rz(-0.2)):
            B.prism(MAGENTA, star_burst(7, 3.2, 1.7, 5, sx=1.0), 0.08, 0.17, bevel=0)
        # halftone diamonds (pink / teal), graded like a print
        for (cx, cy), role, rot in (((-15.2, 12.6), CYAN, math.pi / 2), ((-2.0, -18.6), MAGENTA, 0.9)):
            with B.frame(T(cx, cy, 0.0) @ Rz(rot)):
                for i in range(3):
                    for j in range(3 - i):
                        size = 1.1 - 0.26 * (i + j)
                        B.box(role, (i * 1.45 - 1.4, j * 1.45 - 1.4, 0.125), (size, size, 0.09), rot=math.pi / 4,
                              bevel=0)

    # -- centre: the big Miles Morales emblem ---------------------------------------------------------------------------
    def centerpiece(self, B):
        R = self.MEDALLION_R
        # misprint discs (pink / teal) peeking out from under the black medallion: the Spider-Verse colour split
        B.relief_disc((0.5, -0.5, 0.0), [(MAGENTA, R, 0.0, 0.08, 0.15, 0)], n=28)
        B.relief_disc((-0.5, 0.5, 0.0), [(CYAN, R, 0.0, 0.08, 0.16, 0)], n=28)
        # the black medallion with a bevelled rim
        B.relief_disc((0.0, 0.0, 0.0), [(C_BLACK, R, 0.0, 0.08, 0.2, 0.05)], n=36)
        # the smooth red spider on it (head toward the back: it reads upright from the gate)
        self.spider(B, 4.2, 0.2, 0.29, C_RED, head=-1.0, body_pts=22, body_bevel=0.035, leg_bevel=0.0, leg_drop=0.015)

    # -- perimeter -------------------------------------------------------------------------------------------------
    def fence(self, B):
        for side, s0, s1 in B.runs(self.TERMINAL_GAP):
            if s1 - s0 < 1.5:
                continue  # the stretch between the gate pylon and the generator: both cover it
            with B.module("parapet"), B.frame(B.side_frame(side, (s0 + s1) / 2)):
                self.rail_run(B, side, s1 - s0)
        for side, s0, s1 in B.spans(self.TERMINAL_GAP):
            with B.module("span"), B.frame(B.side_frame(side, (s0 + s1) / 2)):
                self.span(B, side, s1 - s0, s0, s1)
        for post in B.posts():
            if post.kind == "corner":
                with B.module("corner"), B.frame(B.corner_frame(1 if post.x > 0 else -1, 1 if post.y > 0 else -1)):
                    self.corner(B)
            elif post.kind == "post":
                with B.module("post"), B.frame(B.post_frame(post)):
                    self.post(B, post)

    def is_pier(self, B, s):
        """A brick pier stands at the middle of a side and >= 15 studs out; iron newel posts between."""
        return abs(s) < 0.01 or abs(s) >= 15.0

    def rail_run(self, B, side, L):
        """One continuous parapet along a whole run: the water table, the coursed brick, the coping and the fire-escape
        rails (piers, chimneys, pylons and the generator cover the joints)."""
        x0, x1 = -L / 2, L / 2
        ends = (True, True)
        B.sweep(BRICK_DK, PLINTH, x0, x1, open_ends=ends)
        B.sweep(self.MORTAR, bar(WALL_IN + 0.07, WALL_OUT - 0.07, BRICK_Z[0], BRICK_Z[1]), x0, x1, open_ends=ends,
                open="-z +z", bevel=0)
        for a, b in courses():
            B.sweep(BRICK, bar(WALL_IN, WALL_OUT, a, b), x0, x1, open_ends=ends, open="-z +z", bevel=0)
        B.sweep(STONE, COPING, x0, x1, open_ends=ends)
        B.sweep(IRON, bar(RAIL_Y[0] + 0.03, RAIL_Y[1] - 0.03, 2.82, 2.94), x0, x1, open_ends=ends, bevel=0)
        B.sweep(IRON, bar(RAIL_Y[0] - 0.08, RAIL_Y[1] + 0.08, RAIL_TOP - 0.1, RAIL_TOP + 0.05), x0, x1, open_ends=ends,
                bevel=0.04)

    def span(self, B, side, L, s0, s1):
        """Per span: the square iron pickets and, on the left wall, a hooked fire-escape drop ladder outside."""
        yc = (RAIL_Y[0] + RAIL_Y[1]) / 2
        for x in B.repeat(-1.5 * PICKET, 1.5 * PICKET, PICKET):
            B.box(IRON, (x, yc, (COPE_TOP + RAIL_TOP) / 2 - 0.05), (0.12, 0.12, RAIL_TOP - COPE_TOP - 0.1), open="-z +z",
                  bevel=0)
        c = (s0 + s1) / 2
        if side == "left" and -0.1 < c < 5.3:
            self.ladder(B, 0.0)

    def ladder(self, B, x):
        """A fire-escape drop ladder outside the wall: two stiles hooked over the hand rail, flat rungs."""
        y = WALL_OUT + 0.28
        top = RAIL_TOP + 0.22
        for s in (-1, 1):
            B.box(IRON, (x + s * 0.55, y, top / 2), (0.1, 0.12, top), open="-z", bevel=0)
            # the hook over the hand rail (back to the rail's outer edge; never past y 1.26: the back zone ends at 1.3)
            h0, h1 = RAIL_Y[1] - 0.05, y + 0.06
            B.box(IRON, (x + s * 0.55, (h0 + h1) / 2, top - 0.05), (0.1, h1 - h0, 0.1), open="-y", bevel=0)
        for k in range(5):
            B.box(IRON, (x, y, 0.7 + k * 0.72), (1.1, 0.1, 0.08), open="+x -x", bevel=0)

    def post(self, B, post):
        """Brick piers (limestone cap, a glossy stud, pink and teal in turn: Spider-Gwen) at the middle of a side and
        >= 15 studs out; between them the railing's black iron newel posts with a ball cap (a 21-stud brick rhythm)."""
        s = post.x if abs(post.y) >= B.D - 0.01 else post.y
        if not self.is_pier(B, s):
            yc = (RAIL_Y[0] + RAIL_Y[1]) / 2
            B.box(IRON, (0.0, yc, (COPE_TOP + RAIL_TOP) / 2 + 0.1), (0.26, 0.26, RAIL_TOP - COPE_TOP + 0.2),
                  open="-z", bevel=0)
            B.gem(IRON, (0.0, yc, RAIL_TOP + 0.42), 0.26, 0.3, 0.12, n=4, bevel=0)
            return
        B.box(BRICK, (0.0, 0.29, 2.0), (1.6, 1.74, 4.0), open="-z +z", bevel=0.08)
        B.box(STONE, (0.0, 0.3, 4.12), (1.88, 1.84, 0.3), open="-z")
        k = int(round((post.x + post.y) / 10.5))
        self.stud(B, MAGENTA if k % 2 else CYAN, (0.0, 0.3, 4.27), r=0.5, h=0.24, chamfer=0.09, n=6)

    def corner(self, B):
        """A brick chimney stack (a dark top band, a limestone crown) with a round galvanised mushroom roof vent on a
        pink collar, and a clean quarter orb web spun between the stack and the coping of the front / back fence."""
        c = 0.34  # the stack's centre (corner frame: x, y outward; -0.62 .. 1.3)
        B.box(BRICK, (c, c, 2.8), (1.74, 1.74, 5.6), open="-z +z", bevel=0.08)
        B.box(BRICK_DK, (c, c, 5.5), (1.86, 1.86, 0.6), bevel=0.07)
        B.box(STONE, (c, c, 5.98), (1.92, 1.92, 0.36), open="-z")
        B.lathe(C_METAL, (c, c, 0.0), [(0.36, 6.16), (0.36, 6.86), (0.94, 7.16), (0.34, 7.62), (0.0, 7.68)],
                n=6, a0=math.pi / 6, cap=False, bevel=0)
        B.lathe(MAGENTA, (c, c, 0.0), [(0.46, 6.46), (0.46, 6.66)], n=6, a0=math.pi / 6, cap=False)
        # the web: hub in the corner of the stack's inner face (x -0.53) and the coping (h 2.62), up to the dark band
        self.corner_web(B, (c - 0.87 - 0.05, WEB_Y, COPE_TOP + 0.06), 4.1, 2.9, xdir=-1, rings=(0.34, 0.6, 0.86))

    # -- gate: brick pylons with glitch bars, the iron arch with its web, the Miles emblem in a comic burst ----------
    def gate_pylon(self, B, side):
        # pylon frame: +X away from the passage (x >= -1.3 below h 7.5), +Y out of the pen, inner face on y -0.62
        B.box(BRICK_DK, (0.0, 0.54, 0.35), (2.5, 2.32, 0.7), open="-z", bevel=0.07)
        B.loft(BRICK, [(0.7, rect_poly(-1.14, 1.14, -0.56, 1.6)), (7.6, rect_poly(-1.06, 1.06, -0.52, 1.56))],
               cap_top=False, cap_bottom=False, bevel=0.08)
        B.box(STONE, (0.0, 0.54, 7.78), (2.46, 2.32, 0.36), open="-z")
        # popped bricks on the face the arriving players see
        for x, z in ((0.3, 1.6), (-0.4, 6.7)):
            self.pillow_brick(B, BRICK, x, z, 1.58 - 0.012 * z, 1, length=1.0, height=0.34, depth=0.1)
        # misregistered glitch bars on the outer face (+Y) and a pink / teal stripe on the passage side (the
        # Spider-Verse colour split)
        for z, x0, x1, role in ((4.2, -0.86, 0.5, MAGENTA), (4.66, -0.5, 0.86, CYAN), (5.12, -0.96, 0.2, MAGENTA)):
            B.box(role, ((x0 + x1) / 2, 1.6 + 0.05 - 0.04 * (z - 0.7) / 6.9, z), (x1 - x0, 0.1, 0.3), open="-y", bevel=0)
        B.box(MAGENTA, (-1.1, 0.34, 3.4), (0.08, 0.42, 4.6), open="+x", bevel=0)
        B.box(CYAN, (-1.09, 0.84, 4.2), (0.08, 0.3, 4.6), open="+x", bevel=0)
        if side < 0:
            # a quarter orb web between the left pylon's outer face and the coping of the front fence
            self.corner_web(B, (1.1 + 0.05, WEB_Y, COPE_TOP + 0.06), 4.3, 4.5, xdir=1)

    def gate_lintel(self, B):
        # gate frame: X = +v, Y = outward. The black iron arch from pylon cap to pylon cap and the orb web spun in it.
        r_in, r_out = ARCH_R - ARCH_T / 2, ARCH_R + ARCH_T / 2
        B.arch(IRON, (0.0, ARCH_Y, ARCH_Z), r_in, r_out, ARCH_DEPTH, 0.0, math.pi, n=12)
        # the web: evenly spaced radials from the emblem (the hub, hidden behind it) to the arch, three rings across
        # each side's sector (the burst hides the hub and the top sector)
        hub = Vector((0.0, ARCH_Y, self.EMBLEM_Z))
        rel = self.EMBLEM_Z - ARCH_Z
        for sector in ((-24.0, 2.0, 28.0), (152.0, 178.0, 204.0)):
            ends = []
            for deg in sector:
                a = math.radians(deg)
                sn = math.sin(a)
                t = -rel * sn + math.sqrt((rel * sn) ** 2 - rel * rel + (r_in - 0.05) ** 2)
                ends.append(hub + Vector((t * math.cos(a), 0.0, t * sn)))
            for e in ends:
                self.strand(B, hub + (e - hub).normalized() * 1.5, e, 0.13)
            for f in (0.62, 0.78, 0.94):
                pts = [hub.lerp(e, f) for e in ends]
                for p, q in zip(pts, pts[1:]):
                    self.strand(B, p, q, 0.1)

    def emblem(self, B):
        # emblem frame: x = the viewer's right, y = up, +z toward the viewer (the plane is the arch's mid-plane)
        R = 1.5
        burst = star_burst(9, 2.3, 1.78, 11, sx=1.06, rot=0.2, jitter=0.1)
        with B.frame(T(0.18, -0.16, 0.0)):
            B.prism(MAGENTA, burst, -0.34, -0.1, bevel=0)
        B.prism(C_YELLOW, burst, -0.22, 0.02, bevel=0)
        B.relief_disc((0.0, 0.0, 0.0), [(C_BLACK, R, 0.0, 0.02, 0.24, 0.05)], n=32)
        self.spider(B, 1.06, 0.24, 0.38, C_RED, head=1.0, body_pts=14, rounded=True, body_bevel=0.0,
                    leg_bevel=0.0, leg_drop=0.03)

    # -- terminal: the steel generator with a retro tube-screen hood -------------------------------------------
    def terminal(self, B):
        g0, g1 = self.GEN_X
        with B.frame(B.terminal_frame()):
            # terminal frame: x = v - 10.435, y = u - (D + 1.48): the fence line is y -1.48, the pen side ends at -2.1
            ym, yf = -2.08, 0.8
            for s in (-1, 1):
                xa, xb = (g0, g1) if s > 0 else (-self.GEN_GATE_X, -g0)
                xc = (xa + xb) / 2
                B.box(IRON, (xc, (ym + yf) / 2, 0.22), (xb - xa + 0.14, yf - ym, 0.44), open="-z", bevel=0.05)
                B.box(STEEL, (xc, (ym + yf) / 2, 2.66), (xb - xa, yf - ym, 4.44), open="-z +z")
            # the tube-screen hood: a heavy chamfered visor over the sign
            hood = [(ym, 4.88), (0.86, 4.88), (0.86, 5.22), (0.66, 5.7), (ym, 5.7)]
            B.sweep(STEEL, hood, -self.GEN_GATE_X, g1)
            for z in (5.0, 5.14):  # louvres across the visor
                B.box(IRON, (0.0, 0.89, z), (2 * g0 - 0.3, 0.06, 0.07), open="-y", bevel=0)
            # the back plate behind the sign (this span's wall), clear of the plinth (u >= D + 0.49): y -2.08 .. -1.04
            B.box(STEEL, (0.0, -1.56, 2.44), (2 * g0 + 0.02, 1.04, 4.88), open="-z +z")
            # the engine block under the sign, each side of its support: iron with pink slots
            for a, b in ((-2.92, -1.0), (1.12, 2.92)):
                B.box(IRON, ((a + b) / 2, -0.1, 0.38), (b - a, 1.8, 0.76), open="-z", bevel=0.05)
                B.box(MAGENTA, ((a + b) / 2, 0.81, 0.42), (b - a - 0.5, 0.06, 0.12), open="-y")
            # an exhaust stack and three pink vacuum tubes on top of the hood
            B.lathe(IRON, (2.9, -1.3, 0.0), [(0.28, 5.7), (0.28, 7.3), (0.38, 7.36), (0.0, 7.46)], n=6, a0=math.pi / 6,
                    cap=False, bevel=0)
            for x in (-1.4, -0.4, 0.6):
                B.lathe(MAGENTA, (x, -0.7, 0.0), [(0.2, 5.7), (0.2, 6.36), (0.0, 6.62)], n=6, cap=False)
        self.screen_bezel(B)

    # -- window slots (the lit panes the build makes) -------------------------------------------------------------------
    def slot(self, B, center, size, normal, building, lit=None):
        """Records one window pane SLOT (never modelled): `center` = the pane's centre and `normal` = its outward facing
        (horizontal), both in the current frame, `size` = (width, height); `lit` = an accent colour for this window
        when lit (None = WINDOW_LIGHTS lit_rgb). Stored on the builder (B.window_slots, pen frame x = v, y = u, z = h);
        run.py writes them into the layout JSON. The pane must stay in the landmark zone."""
        M = B.stack[-1]
        c = M @ Vector(center)
        n = (M.to_3x3() @ Vector(normal)).normalized()
        slots = B.__dict__.setdefault("window_slots", [])
        count = sum(1 for s in slots if s["building"] == building)
        entry = {"id": "%s%02d" % (building, count + 1), "building": building,
                 "c": [round(c.x, 3), round(c.y, 3), round(c.z, 3)], "size": [round(size[0], 3), round(size[1], 3)],
                 "n": [round(n.x, 4), round(n.y, 4), 0.0], "zone": B.zones[-1]}
        if lit is not None:
            entry["lit_rgb"] = list(lit)
        # the pane's box (pen frame) must stay in the landmark zone like every landmark piece
        hv = abs(n.x) * PANE_T / 2 + abs(n.y) * size[0] / 2
        hu = abs(n.y) * PANE_T / 2 + abs(n.x) * size[0] / 2
        D, Wd = B.D, B.W
        assert B.zones[-1] == ZONE_LANDMARK, "window slots belong to the landmark"
        assert c.y + hu <= -D - LANDMARK_NEAR + 1e-3 and c.y - hu >= -D - LANDMARK_BACK - 1e-3, entry
        assert abs(c.x) + hv <= Wd + LANDMARK_SIDE + 1e-3 and size[1] / 2 < c.z and c.z + size[1] / 2 <= LANDMARK_TOP, entry
        slots.append(entry)
        if B.variant == "Std":
            self.preview_slots = slots

    def window(self, B, xc, zc, y_face, trim, building, lit=None, size=WIN):
        """A window on a facade facing the pen (-Y) at y_face: the frame plate (the trim role, proud of the wall) and a
        pane slot in front of it (the build's lit / dark pane Part, the plate's border reads as the frame)."""
        w, h = size
        z0, z1 = zc - h / 2 - TRIM_FOOT, zc + h / 2 + TRIM_HEAD
        B.box(trim, (xc, y_face - TRIM_OUT / 2, (z0 + z1) / 2), (w + TRIM[0], TRIM_OUT, z1 - z0), open="+y -z", bevel=0)
        self.slot(B, (xc, y_face - TRIM_OUT - PANE_GAP - PANE_T / 2, zc), size, (0.0, -1.0, 0.0), building, lit)

    def window_ac(self, B, xc, zc, y_face):
        """A window air conditioner (Brooklyn summer): a grey box jutting out of the lower sash of the window at
        (xc, zc) on a facade facing -Y at y_face."""
        z = zc - WIN[1] / 2
        B.box(C_METAL, (xc, y_face - 0.62, z + 0.34), (1.2, 0.76, 0.62), open="+y", bevel=0)

    def side_window(self, B, x_face, yc, zc, sx, trim, building, lit=None, size=WIN):
        """A window on a side wall at x_face facing sx (+1 = +X, -1 = -X)."""
        w, h = size
        z0, z1 = zc - h / 2 - 0.3, zc + h / 2 + TRIM_HEAD
        B.box(trim, (x_face + sx * TRIM_OUT / 2, yc, (z0 + z1) / 2), (TRIM_OUT, w + TRIM[0], z1 - z0),
              open=("-x" if sx > 0 else "+x") + " -z", bevel=0)
        self.slot(B, (x_face + sx * (TRIM_OUT + PANE_GAP + PANE_T / 2), yc, zc), size, (sx, 0.0, 0.0), building, lit)

    def preview_extras(self):
        """Render-only lit panes (the Std variant's window slots) so the previews show the lights the build makes."""
        out = []
        for s in self.preview_slots:
            (cx, cy, cz), (w, h), n = s["c"], s["size"], s["n"]
            size = (PANE_T, w, h) if abs(n[0]) > abs(n[1]) else (w, PANE_T, h)
            out.append(("WindowPane_" + s["id"], tuple(s.get("lit_rgb") or LIT_RGB), (cx, cy, cz), size))
        return out

    # -- landmark: the Brooklyn block behind the pen --------------------------------------------------------------------
    def landmark(self, B):
        # landmark frame: X = -v (a player's right looking at it from the pen), +Y away from the pen, Z up
        B.window_slots = []
        x0, x1 = BLD_A["x"][0] - 0.2, BLD_C["x"][1] + 0.2
        B.slab(STONE, (x0, SIDEWALK[0], 0.0), (x1, SIDEWALK[1], 0.16), open="-z", bevel=0)
        self.building_a(B)
        self.building_b(B)
        self.building_c(B)
        # web lines slung between the roofs (Spider-Verse): the water tower's deck to the limestone roof, the
        # brownstone's cornice corner to the limestone front corner
        hb, hc = top_of(BLD_B), top_of(BLD_C)
        self.thread(B, (4.3, 17.0, hb + 2.4), (20.62, 19.2, hc + 2.2), 0.07)
        self.thread(B, (BLD_B["x"][1] + 0.5, BLD_B["y"][0] - 0.5, hb + 0.4), (BLD_C["x"][1] - 0.4, BLD_C["y"][0] - 0.4,
                                                                                hc + 0.5), 0.07)
        # a big quarter orb web in the corner of the brownstone's side wall and the limestone roof
        self.corner_web(B, (BLD_B["x"][1] + 0.08, BLD_B["y"][0] + 0.45, hc + 0.08), 4.6, 4.8, xdir=1,
                        rings=(0.34, 0.64, 0.94), w_rad=0.16, w_ring=0.12)

    def band(self, B, x0, x1, y_face, z0, z1, out, role):
        """A stone / brick course across a facade facing -Y (a sill, lintel or belt course), `out` proud of it."""
        B.box(role, ((x0 + x1) / 2, y_face - out / 2, (z0 + z1) / 2), (x1 - x0, out, z1 - z0), open="+y", bevel=0)

    def cornice(self, B, x0, x1, y0, y1, h, role, brackets=6, bracket_role=None):
        """A bracketed cornice with a parapet around the roof line (front + both sides; the back faces the hub wall):
        a frieze band, a sloped soffit, a deep fascia and a chamfered parapet cap; corbel brackets under the soffit."""
        path = [(x1, y1 - 0.3), (x1, y0), (x0, y0), (x0, y1 - 0.3)]
        prof = [(-0.35, h - 0.5), (0.12, h - 0.5), (0.12, h - 0.22), (0.66, h + 0.1), (0.66, h + 0.44), (0.54, h + 0.56),
                (-0.35, h + 0.56)]
        B.sweep_path(role, prof, path, open_ends=(True, True), bevel=0)
        for x in B.repeat(x0 + 0.4, x1 - 0.4, (x1 - x0 - 0.8) / max(1, brackets)):
            B.box(bracket_role or role, (x, y0 - 0.26, h - 0.62), (0.3, 0.52, 0.56), open="+y +z", bevel=0)

    def awning(self, B, x0, x1, y_face, z_top, colors, n=5):
        """A striped shop awning sloping out of the facade (colours alternate along X)."""
        prof = [(y_face + 0.02, z_top), (y_face - 1.84, z_top - 1.02), (y_face - 1.9, z_top - 1.46),
                (y_face - 1.96, z_top - 0.84), (y_face + 0.02, z_top + 0.2)]
        step = (x1 - x0) / n
        for k in range(n):
            a, b = x0 + k * step, x0 + (k + 1) * step
            B.sweep(colors[k % len(colors)], prof, a, b, open_ends=(k > 0, k < n - 1), bevel=0)

    def vent(self, B, x, y, z, r=0.24, h=1.3):
        """A galvanised roof vent pipe with a conical cap."""
        B.lathe(C_METAL, (x, y, 0.0), [(r, z), (r, z + h), (r * 1.7, z + h + 0.08), (0.0, z + h + 0.34)], n=6,
                cap=False, bevel=0)

    def building_a(self, B):
        """The red brick walk-up: three storeys over a bodega, the SPIDER-VERSE billboard on the roof."""
        (x0, x1), (y0, y1) = BLD_A["x"], BLD_A["y"]
        h = top_of(BLD_A)
        B.slab(BRICK, (x0, y0, 0.0), (x1, y1, h), open="-z")
        B.slab(BRICK_DK, (x0 - 0.12, y0 - 0.12, 0.0), (x1 + 0.12, y1 + 0.12, 0.7), open="-z")
        self.cornice(B, x0, x1, y0, y1, h, STONE, brackets=5)
        # three storeys: stone sill courses, framed windows (a few lit pink / teal: Spider-Verse), an AC unit
        xs = [-24.65, -20.45, -16.25, -12.05]
        accents = {(1, 0): PINK_RGB, (2, 2): TEAL_RGB, (0, 3): PINK_RGB}
        for r, zc in enumerate(storey_rows(BLD_A["n"])):
            self.band(B, x0, x1, y0, zc - WIN[1] / 2 - 0.28, zc - WIN[1] / 2, 0.36, STONE)
            for i, xc in enumerate(xs):
                self.window(B, xc, zc, y0, STONE, "A", accents.get((r, i)))
        self.window_ac(B, xs[1], storey_rows(BLD_A["n"])[0], y0)
        # the belt course over the bodega, the stone shop front, two shop windows, a black door, the striped awning
        self.band(B, x0, x1, y0, GROUND - 0.1, GROUND + 0.24, 0.28, STONE)
        B.box(STONE, (-18.7, y0 - 0.08, 2.3), (15.2, 0.16, 3.2), open="+y", bevel=0)
        yp = y0 - 0.16 - PANE_GAP - PANE_T / 2
        self.slot(B, (-22.8, yp, 2.3), (6.0, 2.3), (0.0, -1.0, 0.0), "A")
        self.slot(B, (-16.6, yp, 2.3), (5.0, 2.3), (0.0, -1.0, 0.0), "A")
        B.box(C_BLACK, (-12.4, y0 - 0.22, 1.95), (1.7, 0.12, 2.5), open="+y", bevel=0)
        self.awning(B, -26.0, -10.8, y0, 4.3, (MAGENTA, C_WHITE), n=5)
        # the roof: a brick chimney with a stone cap, vent pipes
        B.box(BRICK, (-25.6, 21.4, h + 1.2), (1.4, 1.4, 2.4), open="-z", bevel=0)
        B.box(STONE, (-25.6, 21.4, h + 2.5), (1.7, 1.7, 0.24), bevel=0)
        self.vent(B, -12.6, 20.6, h)
        # the billboard on the roof: legs, braces, a catwalk, the black board with pink / teal misprint boards behind it
        bx0, bx1, by, bz0, bz1 = -25.8, -11.2, 15.0, h + 2.0, h + 8.0
        for x in (-22.2, -14.8):
            B.box(IRON, (x, by + 0.9, (h + bz1 - 0.6) / 2), (0.34, 0.34, bz1 - 0.6 - h), open="-z", bevel=0)
            B.beam(IRON, (x, by + 3.6, h + 0.1), (x, by + 1.0, bz0 + 1.6), 0.2, bevel=0)
        B.slab(IRON, (bx0, by - 0.9, bz0 - 0.5), (bx1, by + 0.1, bz0 - 0.32), bevel=0)
        B.slab(MAGENTA, (bx0 - 0.46, by + 0.25, bz0 - 0.4), (bx1 - 0.46, by + 0.55, bz1 - 0.4), bevel=0)
        B.slab(CYAN, (bx0 + 0.46, by + 0.3, bz0 + 0.4), (bx1 + 0.46, by + 0.6, bz1 + 0.4), bevel=0)
        B.slab(C_BLACK, (bx0, by, bz0), (bx1, by + 0.5, bz1), bevel=0.08)
        with B.frame(T((bx0 + bx1) / 2, by, (bz0 + bz1) / 2) @ B.facing((0.0, -1.0))):
            for q in text_strokes("SPIDER-", 2.1):
                B.relief([(p[0] + 0.5, p[1] + 1.35) for p in q], [(C_WHITE, 0.0, 0.0, 0.22, 0)])
            for q in text_strokes("VERSE", 2.1):
                B.relief([(p[0], p[1] - 1.3) for p in q], [(C_WHITE, 0.0, 0.0, 0.22, 0)])

    def fire_escape(self, B, x0, x1, y_face, levels, ladder_to, roof_top):
        """A black iron fire escape on a facade facing -Y at y_face: a grated platform at every level (on two diagonal
        wall brackets) with a railing (corner and middle posts, a top and a mid rail, side rails back to the wall),
        zig-zag stair flights with real steps and a hand rail between the platforms, a drop ladder under the lowest one
        (down to ladder_to) and a gooseneck ladder from the top one over the parapet (roof_top)."""
        dep = 1.5
        yf = y_face - dep
        for k, z in enumerate(levels):
            B.slab(IRON, (x0, yf, z - 0.14), (x1, y_face, z), open="+y", bevel=0)
            for x in (x0 + 0.5, x1 - 0.5):  # wall brackets
                B.beam(IRON, (x, y_face - 0.05, z - 1.15), (x, yf + 0.25, z - 0.16), 0.1, bevel=0, open="+x -x")
            for zr in (z + 1.1, z + 0.56):  # the front rails
                B.box(IRON, ((x0 + x1) / 2, yf + 0.05, zr), (x1 - x0, 0.08, 0.08), open="+x -x", bevel=0)
            for x in (x0 + 0.05, (x0 + x1) / 2, x1 - 0.05):  # posts
                B.box(IRON, (x, yf + 0.05, z + 0.57), (0.1, 0.1, 1.14), open="-z +z", bevel=0)
            for x in (x0 + 0.05, x1 - 0.05):  # side rails back to the wall
                B.box(IRON, (x, (yf + y_face) / 2, z + 1.1), (0.08, dep - 0.1, 0.08), open="+y -y", bevel=0)
            if k + 1 < len(levels):
                zn = levels[k + 1]
                n = 6
                rise = (zn - 0.16 - z) / n
                s = 1 if k % 2 == 0 else -1
                xa = x0 + 0.35 if s > 0 else x1 - 0.35
                tread = 3.1 / n
                bm = bm_prism(stair_outline(xa, z, s, n, tread, rise), y_face - 1.3, y_face - 0.45)
                _drop_faces(bm, "+z")  # the flight's back (toward the wall)
                B.mesh(IRON, bm, basis((1.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)), bevel=0)
                run = (zn - 0.2 - z - 1.0) * tread / rise  # the hand rail stops under the next platform
                B.beam(IRON, (xa, y_face - 1.3, z + 1.0), (xa + s * run, y_face - 1.3, zn - 0.2), 0.08, bevel=0,
                       open="+x -x")
        # a small web draped in the railing corner of the second platform (between its end post and the grating)
        if len(levels) > 1:
            self.corner_web(B, (x0 + 0.14, yf + 0.14, levels[1] + 0.04), 1.9, 1.0, xdir=1, n_rad=4, rings=(0.5, 0.92),
                            w_rad=0.09, w_ring=0.07)
        # the drop ladder under the lowest platform (at the landing end), the gooseneck over the parapet
        z0 = levels[0]
        xl = x1 - 1.2
        for x in (xl - 0.4, xl + 0.4):
            B.box(IRON, (x, yf + 0.3, (ladder_to + z0) / 2), (0.08, 0.08, z0 - ladder_to), open="+z", bevel=0)
        for z in range(3):
            B.box(IRON, (xl, yf + 0.3, ladder_to + 0.45 + z * 0.8), (0.8, 0.06, 0.06), open="+x -x +y", bevel=0)
        zt = levels[-1]
        yg = y_face - 0.9  # in front of the cornice's fascia (0.66 proud)
        for x in (xl - 0.4, xl + 0.4):
            B.box(IRON, (x, yg, (zt + roof_top + 0.8) / 2), (0.08, 0.08, roof_top + 0.8 - zt), open="-z", bevel=0)
            B.box(IRON, (x, (yg + y_face + 0.4) / 2, roof_top + 0.76), (0.08, y_face + 0.4 - yg, 0.08), open="+y", bevel=0)
        z = zt + 1.2
        while z < roof_top + 0.3:
            B.box(IRON, (xl, yg, z), (0.8, 0.06, 0.06), open="+x -x +y", bevel=0)
            z += 1.1

    def building_b(self, B):
        """The brownstone tower: a rusticated stone ground floor with a stoop, five storeys with stone sill courses,
        stone quoins, a bracketed cornice, the black iron fire escape and the water tower on the roof."""
        (x0, x1), (y0, y1) = BLD_B["x"], BLD_B["y"]
        h = top_of(BLD_B)
        B.slab(BRICK_DK, (x0, y0, 0.0), (x1, y1, h), open="-z")
        self.cornice(B, x0, x1, y0, y1, h, STONE, brackets=6)
        # the rusticated stone ground floor (a joint groove course across it)
        B.slab(STONE, (x0 - 0.1, y0 - 0.16, 0.0), (x1 + 0.1, y0 + 0.2, GROUND + 0.3), open="-z +y", bevel=0)
        self.band(B, x0 - 0.1, x1 + 0.1, y0 - 0.16, 2.1, 2.22, 0.03, BRICK_DK)
        # stone quoin pilasters up both front corners
        for x in (x0 + 0.4, x1 - 0.4):
            B.box(STONE, (x, y0 - 0.07, (GROUND + h - 0.5) / 2), (0.8, 0.14, h - 0.5 - GROUND), open="+y -z +z", bevel=0)
        xs = [-6.2, -0.8, 5.0]
        accents = {(0, 0): TEAL_RGB, (2, 1): PINK_RGB, (4, 0): PINK_RGB, (3, 1): TEAL_RGB}
        for r, zc in enumerate(storey_rows(BLD_B["n"])):
            self.band(B, x0 + 0.8, x1 - 0.8, y0, zc - WIN[1] / 2 - 0.28, zc - WIN[1] / 2, 0.34, STONE)
            for i, xc in enumerate(xs):
                self.window(B, xc, zc, y0, STONE, "B", accents.get((r, i)))
        rows = storey_rows(BLD_B["n"])
        for yc in (16.4, 20.4):  # side windows above the limestone roof (right) and the walk-up's (left, top row)
            for zc in rows[3:]:
                self.side_window(B, x1, yc, zc, 1, STONE, "B", PINK_RGB if (yc, zc) == (20.4, rows[4]) else None)
            self.side_window(B, x0, yc, rows[4], -1, STONE, "B", TEAL_RGB if yc < 18 else None)
        self.window_ac(B, -6.2, rows[1], y0)
        # the door on a stoop: a stone surround with a bracketed hood, the red door, three steps with iron rails
        yd = y0 - 0.16
        B.box(STONE, (-3.4, yd - 0.06, 2.6), (2.7, 0.12, 3.4), open="+y", bevel=0)
        B.box(C_RED, (-3.4, yd - 0.15, 2.35), (1.7, 0.06, 2.9), open="+y", bevel=0)
        B.box(STONE, (-3.4, yd - 0.3, 4.44), (3.3, 0.6, 0.28), open="+y", bevel=0)
        for s in (-1, 1):
            B.box(STONE, (-3.4 + s * 1.35, yd - 0.22, 4.12), (0.26, 0.44, 0.4), open="+y +z", bevel=0)
        for k in range(3):
            B.slab(STONE, (-5.1, yd - 1.8 + 0.6 * k, 0.0), (-1.7, yd, 0.3 * (k + 1)), open="-z +y", bevel=0)
        for x in (-5.0, -1.8):
            B.beam(IRON, (x, yd - 1.8, 1.25), (x, yd - 0.2, 1.9), 0.08, bevel=0, open="+x -x")
            B.box(IRON, (x, yd - 1.8, 0.62), (0.1, 0.1, 1.24), open="-z", bevel=0)
        # the fire escape over the right column (platforms at every storey's floor line from the 2nd up)
        levels = [GROUND + k * STOREY for k in range(1, BLD_B["n"])]
        self.fire_escape(B, 2.3, 7.7, y0, levels, ladder_to=5.2, roof_top=h + 0.56)
        # the roof: the water tower on its stilts, vents
        self.water_tower(B, (2.4, 18.6), h)
        self.vent(B, -7.4, 20.8, h)

    def water_tower(self, B, c, z, r=2.1, legs=2.6, barrel=4.6, roof=2.4, n=10):
        """A Brooklyn rooftop water tower: four steel stilts with X braces, an iron deck, a hooped wooden barrel and a
        conical iron roof with a pink finial. z = the roof it stands on."""
        cx, cy = c
        q = r * 0.66
        zd = z + legs
        for sx in (-1, 1):
            for sy in (-1, 1):
                B.box(IRON, (cx + sx * q, cy + sy * q, z + legs / 2), (0.3, 0.3, legs), open="-z +z", bevel=0)
        for sy in (-1,):
            B.beam(IRON, (cx - q, cy + sy * q, z + 0.2), (cx + q, cy + sy * q, zd - 0.3), 0.14, bevel=0)
            B.beam(IRON, (cx + q, cy + sy * q, z + 0.2), (cx - q, cy + sy * q, zd - 0.3), 0.14, bevel=0)
        for sx in (-1, 1):
            B.beam(IRON, (cx + sx * q, cy - q, z + 0.2), (cx + sx * q, cy + q, zd - 0.3), 0.14, bevel=0, open="+x -x")
        B.slab(IRON, (cx - r * 0.95, cy - r * 0.95, zd - 0.26), (cx + r * 0.95, cy + r * 0.95, zd), bevel=0)
        B.lathe(WOOD, (cx, cy, 0.0), [(r * 0.97, zd), (r * 1.03, zd + barrel * 0.45), (r * 0.96, zd + barrel)], n=n,
                cap=False, bevel=0)
        for f, k in ((0.24, 1.04), (0.66, 1.045)):
            zh = zd + barrel * f
            B.lathe(IRON, (cx, cy, 0.0), [(r * k, zh - 0.1), (r * k, zh + 0.1)], n=n, cap=False, bevel=0)
        zt = zd + barrel
        B.lathe(IRON, (cx, cy, 0.0), [(r * 1.12, zt - 0.14), (r * 1.12, zt + 0.1), (0.24, zt + roof), (0.0, zt + roof + 0.1)],
                n=n, cap=True, bevel=0)
        B.gem(MAGENTA, (cx, cy, zt + roof + 0.34), 0.2, 0.36, 0.14, n=4, bevel=0)

    def building_c(self, B):
        """The limestone corner building: two storeys over a teal-striped storefront, a Spider-Gwen mural on its side,
        a stair bulkhead, an AC unit and vents on the roof."""
        (x0, x1), (y0, y1) = BLD_C["x"], BLD_C["y"]
        h = top_of(BLD_C)
        B.slab(STONE, (x0, y0, 0.0), (x1, y1, h), open="-z")
        B.slab(BRICK_DK, (x0 - 0.12, y0 - 0.12, 0.0), (x1 + 0.12, y1 + 0.12, 0.7), open="-z")
        self.cornice(B, x0, x1, y0, y1, h, BRICK_DK, brackets=5)
        xs = [11.9, 17.9, 23.9]
        accents = {(0, 1): TEAL_RGB, (1, 2): PINK_RGB}
        for r, zc in enumerate(storey_rows(BLD_C["n"])):
            self.band(B, x0, x1, y0, zc - WIN[1] / 2 - 0.28, zc - WIN[1] / 2, 0.34, BRICK_DK)
            for i, xc in enumerate(xs):
                self.window(B, xc, zc, y0, BRICK_DK, "C", accents.get((r, i)))
        self.window_ac(B, xs[0], storey_rows(BLD_C["n"])[1], y0)
        # the storefront: a brick frame, three shop windows, a black door, the teal / white striped awning
        self.band(B, x0, x1, y0, GROUND - 0.1, GROUND + 0.24, 0.28, BRICK_DK)
        B.box(BRICK_DK, (18.2, y0 - 0.08, 2.3), (15.2, 0.16, 3.2), open="+y", bevel=0)
        yp = y0 - 0.16 - PANE_GAP - PANE_T / 2
        for xc in (12.9, 17.3, 21.7):
            self.slot(B, (xc, yp, 2.3), (4.0, 2.3), (0.0, -1.0, 0.0), "C")
        B.box(C_BLACK, (24.9, y0 - 0.22, 1.95), (1.7, 0.12, 2.5), open="+y", bevel=0)
        self.awning(B, 10.4, 26.0, y0, 4.3, (CYAN, C_WHITE), n=5)
        # rooftop: a stair bulkhead with a door, an AC unit with its fan, vents
        B.slab(BRICK_DK, (20.6, 18.6, h), (24.4, 22.4, h + 2.7), open="-z", bevel=0)
        B.box(C_BLACK, (22.5, 18.55, h + 1.1), (1.3, 0.1, 2.2), open="+y", bevel=0)
        B.slab(C_METAL, (15.0, 17.2, h), (17.8, 19.0, h + 1.3), open="-z", bevel=0)
        B.disc(C_BLACK, (16.4, 18.1, h + 1.3), 0.7, 0.06, n=8, bevel=0)
        self.vent(B, 26.0, 20.8, h, r=0.3, h=0.9)
        # the Spider-Gwen mural on the side wall facing +X: teal + pink spray splats, a white web, pink halftone dots
        with B.frame(T(x1, (y0 + y1) / 2 - 0.6, 6.2) @ B.facing((1.0, 0.0))):
            with B.frame(T(-0.5, 0.45, 0.0)):
                B.relief(splat(12, 3.7, 5), [(CYAN, 0.0, 0.0, 0.1, 0)])
            B.relief(splat(12, 3.3, 9), [(MAGENTA, 0.0, 0.0, 0.16, 0)])
            for a in (0.3, 1.2, 2.1, 3.0, 3.9, 4.8):  # a white web spun over the splats
                self.strand(B, (0.0, 0.0, 0.2), (2.9 * math.cos(a), 2.9 * math.sin(a), 0.2), 0.16)
            for i, j in ((0, 0), (1, 0), (0, 1)):
                s = 0.62 - 0.14 * (i + j)
                B.box(MAGENTA, (3.7 + i * 0.9, -2.6 + j * 0.9, 0.05), (s, s, 0.1), rot=math.pi / 4, open="-z", bevel=0)


THEME = Theme()
