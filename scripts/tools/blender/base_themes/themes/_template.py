# scripts/tools/blender/base_themes/themes/_template.py
# Starting point for a theme on API v3 (read the header of common.py first; themes/forest.py "Stark Lab" is the full
# reference: per-run barrier sweeps, a module per span, posts, bastions, helmet pylons, a crested lintel, the 3D arc
# reactor, the console terminal). Copy to themes/<key lowercase>.py, change KEY / NAME / TITLE / FRANCHISE, then REPLACE
# every silhouette below with your franchise's own (the owner wants six unique perimeters: never reuse Forest's
# barrier profile, and never an X-cross fence). Run:
#     "C:/Program Files/Blender Foundation/Blender 4.5/blender.exe" --background --factory-startup \
#         --python scripts/tools/blender/base_themes/run.py -- --themes <Key>
# look at assets/models/bases/<Key>/preview/<NAME>_hero|gate|detail|top.png and assets/models/bases/preview/
# _coherence.png, iterate until it looks like a top Roblox game, keep both variants in 6000..9000 tris; finally
#     lune run scripts/tools/test_base_imports.luau all <your scratch dir> <Key>     (0 problems expected)
# As is, this template is a complete, valid pen (a placeholder "castle" silhouette in four colours).

import math

from common import *

FLOOR, STUD = "Floor_Base", "Floor_Stud"
WALL, TRIM, DARK = "Structure_Wall", "Structure_Trim", "Structure_Dark"
C_TRIM, C_DARK = "Core_3D_Trim", "Core_3D_Dark"
GLOW, SCREEN = "Neon_Emissive_Glow", "Neon_Emissive_Screen"

GLOW_RGB = (58, 123, 255)
WALL_PROFILE = [(-0.6, 0.0), (0.9, 0.0), (0.9, 0.5), (0.7, 0.7), (0.7, 2.6), (-0.6, 2.6)]  # (y out, z up)
COPING = [(-0.6, 2.6), (0.82, 2.6), (0.82, 2.9), (-0.6, 2.9)]


class Theme(PenTheme):
    KEY, NAME, TITLE, FRANCHISE = "Lake", "TemplatePen", "Template Pen", "Template"  # <- change all four
    PALETTE = {
        FLOOR: look((200, 196, 186), "SmoothPlastic"),       # anchor: exactly the footprint, h 0..0.1
        STUD: look((226, 222, 212), "SmoothPlastic"),
        WALL: look((29, 63, 143), "SmoothPlastic", bevel=0.1),
        TRIM: look((217, 165, 32), "SmoothPlastic", bevel=0.06),
        DARK: look((40, 44, 60), "SmoothPlastic"),
        C_TRIM: look((217, 165, 32), "SmoothPlastic"),
        C_DARK: look((40, 44, 60), "SmoothPlastic"),
        GLOW: look(GLOW_RGB, "Neon"),
        SCREEN: look(GLOW_RGB, "Neon"),                      # anchor: the terminal's bezel
    }
    TILES = {"Std": (5, 5), "Deep": (5, 6)}

    def floor(self, B):
        super().floor(B)  # Floor_Base tiles over the footprint
        tx, ty = 2 * B.W / 5, 2 * B.D / self.TILES[B.variant][1]
        B.stud_grid(STUD, -B.W + tx, -B.D + ty, B.W - tx, B.D - ty, 4, self.TILES[B.variant][1] - 1, 0.0,
                    skip=lambda x, y: math.hypot(x, y) < 8, r=0.6, h=0.26, n=11)

    def centerpiece(self, B):
        # a 3D relief (floor work: everything below h 0.3): stepped disc, ring, a star with a bevelled rim step
        B.relief_disc((0, 0, 0), [(C_DARK, 7.0, 0.0, FLOOR_TOP, 0.16), (C_TRIM, 7.4, 6.6, FLOOR_TOP, 0.28)], n=32)
        star = [(math.cos(math.pi / 2 + k * math.pi / 5) * (4.2 if k % 2 == 0 else 1.9),
                 math.sin(math.pi / 2 + k * math.pi / 5) * (4.2 if k % 2 == 0 else 1.9)) for k in range(10)]
        B.relief(star, [(C_TRIM, 0.0, 0.16, 0.24), (GLOW, 0.3, 0.24, 0.29, 0)])
        B.light((0, 0, 2.5), 16, 1.0, GLOW_RGB)

    def rail_run(self, B, side, L):
        # ONE sweep per continuous run (the posts and corners hide the joints); open ends cost nothing
        B.sweep(WALL, WALL_PROFILE, -L / 2, L / 2, open_ends=(True, True))
        B.sweep(TRIM, COPING, -L / 2, L / 2, open_ends=(True, True), open="-z")

    def span(self, B, side, L, s0, s1):
        # a module per span: placeholder merlons cut out of one silhouette (x along the fence, z up)
        merlons = []
        for x in B.repeat(-L / 2 + 1.2, L / 2 - 1.2, 2.2):
            merlons += [(x - 0.6, 2.9), (x - 0.6, 3.6), (x + 0.6, 3.6), (x + 0.6, 2.9)]
        B.silhouette(TRIM, [(-L / 2 + 0.8, 2.9)] + merlons + [(L / 2 - 0.8, 2.9)], -0.5, 0.7)
        B.box(GLOW, (0.0, 0.93, 1.6), (L - 2.4, 0.06, 0.16), open="-y")

    def post(self, B, post):
        B.box(DARK, (0.0, 0.15, 2.1), (1.4, 1.54, 4.2), open="-z")
        B.gem_cube(GLOW, (0.0, 0.15, 4.9), 0.6, on_vertex=True)

    def corner(self, B):
        B.box(DARK, (0.34, 0.34, 3.0), (1.92, 1.92, 6.0), open="-z")
        B.gem_cube(GLOW, (0.34, 0.34, 7.0), 0.9, on_vertex=True)

    def gate_pylon(self, B, side):
        # pylon frame: +X away from the passage (x >= -1.3 below 7.5), +Y out, inner face on y -0.62
        B.box(DARK, (0.0, 0.6, 5.0), (2.4, 2.44, 10.0), open="-z")
        B.box(TRIM, (0.0, 0.6, 10.2), (2.6, 2.44, 0.4), open="-z")

    def gate_lintel(self, B):
        B.plate(WALL, [(-4.2, 7.8), (4.2, 7.8), (4.2, 9.4), (2.4, 9.4), (1.2, 12.0), (-1.2, 12.0), (-2.4, 9.4), (-4.2, 9.4)],
                -0.4, 1.2)

    def emblem(self, B):
        # emblem frame: x right, y up, +z toward the viewer; a stepped medallion + an extruded logo
        B.relief_disc((0, 0, 0), [(C_DARK, 1.8, 0.0, 0.0, 0.16), (C_TRIM, 2.0, 1.7, 0.0, 0.32)], n=24)
        B.relief([(-0.9, -0.9), (0.9, -0.9), (0.0, 1.1)], [(C_TRIM, 0.0, 0.16, 0.34), (GLOW, 0.2, 0.34, 0.4, 0)])

    def terminal(self, B):
        super().terminal(B, housing=WALL)  # a plain housing + the Neon_Emissive_Screen bezel: restyle it


THEME = Theme()
