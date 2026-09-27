# scripts/tools/blender/base_themes/common.py
"""
Steal a Hero - Blender base-theme framework, API v3.1 ("stealahero-base-theme/3", owner art direction 2026-09-24, amended
2026-09-25: NO NEON and no lights anywhere in the bases, landmark buildings for Lake / Desert / Jungle, stale-import
fingerprints). THE THEME API: read this whole header before writing a theme; themes/forest.py ("Stark Lab") is the
reference theme.

WHAT CHANGED ON 2026-09-25 (owner: "remove ALL the neon from the bases, it is very disruptive for the players")
  * Roblox Neon is gone: look(..., "Neon") raises. The family keeps its NAME Neon_Emissive_* (the owner's Studio imports
    and the build's tests carry that name) but it is now the plain ACCENT family: SmoothPlastic / Plastic / Glass, no
    glow. Bright colours read through saturation, SmoothPlastic gloss and a little reflectance, never emission.
  * No lights: B.light() is a no-op (counted, never exported); the JSON "lights" lists are empty and the build loader
    never creates a PointLight / SpotLight in a base. The loader fails the build if any base part is Neon.
  * Landmarks (LANDMARK_KEYS = Lake, Desert, Jungle only): one landmark building behind the back fence (see LANDMARK).
  * Stale imports: every layout carries "geometry_fingerprint" (geometry only: object bounds, tris, every piece). The
    Studio helper stamps it on the import; the build ignores an import whose stamp differs ("re-import <Name>.fbx") and
    keeps the procedural theme. A palette-only change keeps the fingerprint, so the owner's import stays valid.

WHAT IT MAKES
  One pen (player plot base) per Directory.BaseThemes key (Forest, Lake, Desert, Jungle, Snow, Volcano) at the standard
  of the top Roblox games (Steal an Egg, Pet Simulator 99, BedWars): premium toy plastic, chunky bevelled silhouettes,
  3D relief logos, ONE unique perimeter per theme, an open plot with 360-degree visibility of the map.
  Run (from the repo root):
      "C:/Program Files/Blender Foundation/Blender 4.5/blender.exe" --background --factory-startup \
          --python scripts/tools/blender/base_themes/run.py -- --themes Forest,Lake [--no-render]
      --dry-run      validate + build + self-check + evaluated tri counts, nothing written (also --themes _template)
      --sheet-only   recompose assets/models/bases/preview/_coherence.png + the Studio helper from what is on disk
      --view         (without --background) the Blender window with the themes laid out, nothing written
      showcase_all.py  every v3 theme side by side in one studio shot: assets/models/bases/preview/_lineup.png
  Per theme it writes assets/models/bases/<Key>/:
      <NAME>.fbx     ONE file, both pen variants: objects "Std_<Role>" / "Deep_<Role>", one mesh per role (= one Roblox
                     MeshPart: one colour + one material), modifiers applied, custom (weighted) normals, FBX Units Scale,
                     -Z forward, Y up, origin = the pen's floor centre at Y = 0
      <NAME>.blend   the same scene with the LIVE modifier stacks and one collection per material family (to tweak)
      <NAME>.json    the layout the build loader reads (variants, footprint, per-role bounds, every primitive's box,
                     palette + families, lights, evaluated tri counts, self-check results)
      preview/<NAME>_hero.png, _gate.png, _detail.png, _top.png   (EEVEE, 50 mm, 3-point studio light)
                     + _landmark.png, _playercam.png for a theme with a landmark (see LANDMARK)
  then refreshes assets/models/bases/preview/_coherence.png (every v3 theme's hero shot side by side, same camera and
  light) and the Studio helper assets/models/bases/BaseThemesImport.lua.

HARD RULES (owner, 2026-09-24 / 2026-09-25; Builder.check / pipeline enforce them)
  * NO Neon, no lights (see above). Allowed Roblox materials: SmoothPlastic, Plastic, Glass.
  * NO backdrop: nothing behind the back fence but the perimeter itself (u >= -D - BACK_REACH), EXCEPT the landmark
    module of a LANDMARK_KEYS theme (Lake, Desert, Jungle), in its own zone. Forest, Snow and Volcano stay open.
  * NO shared fence: every theme models its OWN perimeter silhouette (span / post / corner / gate_pylon / gate_lintel /
    emblem have no default: a theme that does not override them fails validation). No X-cross farm fence anywhere.
  * NO flat decals: logos, cores and floor art are extruded 3D geometry with steps and bevels (relief, relief_disc).
  * Every rigid piece is bevelled by a real Blender Bevel modifier (limit method ANGLE 35 deg, 1-2 segments, clamp overlap)
    followed by a Weighted Normal modifier (face area, keep sharp) on smooth-shaded meshes whose edges above 35 deg are
    marked sharp: flat faces stay flat, bevels catch the light (premium toy plastic). Studs are chamfered by construction.
  * Budget: TRI_MIN .. TRI_MAX (6000 .. 9000) evaluated triangles (after the modifiers) per COMPLETE variant, the
    landmark included. A landmark theme that truly needs more may set TRI_STRETCH = <= TRI_STRETCH_MAX (10000) with a
    TRI_STRETCH_REASON string (printed and written to the JSON; say so to the owner).

ROLES = MATERIAL FAMILIES  (a role is one Blender object per variant = one Roblox MeshPart; ~8-12 roles per theme)
  Role name = <Family>_<Colour>, Family one of:
      Structure_*       perimeter, posts, pylons, terminal, landmark Plastic | SmoothPlastic | Glass   bevel 0.09 x 1
      Floor_*           the floor, tiles, studs, inlays              Plastic | SmoothPlastic   default bevel 0.03 x 1
      Core_3D_*         the centre core, logos, reliefs              Plastic | SmoothPlastic   default bevel 0.05 x 1
      Neon_Emissive_*   ACCENT colours: gems, strips, the screen     SmoothPlastic | Plastic | Glass   bevel 0 (none)
                        bezel (the historical name stays; NOT emissive since 2026-09-25, never Roblox Neon)
  e.g. Structure_Crimson, Structure_Gold, Floor_Metal, Floor_Stud, Core_3D_Gold, Neon_Emissive_Cyan.
  Two FIXED anchor roles every theme has (the loader locates and orients the import with them):
      Floor_Base             the floor slab / tiles: EXACTLY the footprint -W..W x -D..D, h 0..0.1, nothing else in it
      Neon_Emissive_Screen   the terminal's accent bezel around the PlotUpgrade sign (centred on it, see the contract)
  PALETTE = {role: look(rgb, material="SmoothPlastic", transparency=0, reflectance=0, bevel=None, segs=None)}
  (bevel / segs = that role's default bevel width / segments; None = the family default).
  Accent colours without glow: pick the saturated hue a notch darker than a neon swatch (e.g. neon (86, 255, 118) ->
  (60, 214, 98)), SmoothPlastic, reflectance 0.04 .. 0.08 for a glossy "lamp glass" read; Glass (transparency <= 0.3)
  only over an opaque backing.

UNITS AND FRAME
  1 Blender unit = 1 stud. Pen frame: X = v (right, looking OUT of the gate), Y = u (toward the gate = the plot's
  front), Z = h (up). Origin = pen centre on the ground (h 0). The FBX export (-Z forward, Y up) maps Blender +Y to
  Roblox -Z, so the gate ends up on the model's LookVector side. Half width W = 26.25 for both variants; half depth
  B.D = 26.25 ("Std": plots 1, 4, 5 and the Index preview) or 31.5 ("Deep": plots 2, 3, 6). theme.build(B) runs once
  per variant: always read B.D / B.W, never hard-code the depth.

THE PEN CONTRACT (B.check(); run.py fails the theme on any problem)
  * Fence line: the plot's StarterPen post stations every 10.5 studs (B.vs / B.us), corners at (+-W, +-D), gate posts
    at v = +-5.25 on the front (u = +D). The plot's own fence is hidden under an imported pen, so the perimeter IS the
    fence: build it along those lines (any rhythm / silhouette you like, but on those lines).
  * Nothing but floor work reaches more than INSET = 0.62 studs into the pen (the heroes stand ~1.1 inside).
    "Floor work" = Floor_Base (h 0 .. FLOOR_TOP 0.1, exactly the footprint) and any piece entirely below
    FLOOR_DETAIL_TOP = 0.3 (tiles, studs, the 3D core relief, inlays; the heroes walk at h 0.127).
  * Gate passage: nothing but floor work in |v| < 3.95, u in D-2.5 .. D+3, below h 7.5 (players walk in there).
  * Upgrade terminal: the plot's functional PlotUpgrade sign (v 7.51..13.36, h 0.98..4.69, u D+0.86..D+2.10), its
    support column (v 10..11, u D+0.94..D+1.94, h 0..1.64) and plinth (v 9.55..11.45, u D+0.49..D+2.39, h 0..0.36) are
    never touched and the sign's screen (v 7.95..12.92, h 1.42..4.25, facing +u) is never covered: the terminal WRAPS
    them. Neon_Emissive_Screen = its bezel, centred on v 10.435, within u D+0.46 .. D+2.4.
  * Zone: u <= D+2.4 (front), |v| <= W+2 (sides), u >= -D-1.3 (back: the perimeter only), h <= 16; corner work reaches
    <= 1.3 past both fence lines (plot 6's front-right corner stands next to the money leaderboard).
  * scripts/tools/blender/base_themes/plot_obstacles.json (from a build: lune run scripts/tools/test_base_imports.luau
    obstacles <build.rbxl>) = every real plot's obstacles (the pen zone AND the landmark zone behind it: hub walls
    Workspace.WorldWalls, neighbouring plots, leaderboards, ...); every piece is checked against them with no margin.

LANDMARK  (Lake, Desert, Jungle only: LANDMARK_KEYS; owner 2026-09-25 "U.A. / Hall of Justice / Spider-Verse buildings")
  PenTheme.landmark(B) (default: nothing) runs last, in B.landmark_frame() and B.module("landmark"): the theme's
  landmark building behind its pen (the U.A. towers, the Hall of Justice, the Brooklyn skyline). Its zone (checked on
  every piece drawn inside landmark(), whatever sub-modules / frames it uses):
      LANDMARK_NEAR (1.3) <= studs behind the back fence line <= LANDMARK_BACK (24)   i.e. u in -D-24 .. -D-1.3
      |v| <= W + LANDMARK_SIDE (2.0),  h 0 .. LANDMARK_TOP (34)
  The world ground behind every plot is the pen's ground (h 0 = world Y 2.05) and the zone is clear on all six plots
  (plots 1-5 back onto Workspace.WorldWalls.Hub.HubWall_West 43-54 studs behind, plot 6 onto HubWall_North 56 behind,
  HubWall_EastNorth 0.6 past plot 6's side limit); plot_obstacles.json covers it, with no margin.
  B.landmark_frame()   origin on the back fence line at v 0; local X = the right of a player in the pen looking at the
                       landmark (= -v), +Y = away from the pen (depth: landmark work at y 1.3 .. 24), Z up. The facade
                       that faces the pen is at the landmark's small y; draw logos on it with
                       B.frame(T(0, y_face, z) @ B.facing((0, -1))) (facing(...) is relative to the current frame).
  CAMERA GUIDANCE (warnings, not failures; printed and written to the JSON "camera_warnings"): the parts are
  CanCollide off, so Roblox's camera passes THROUGH them instead of popping in front. A player standing at the back of
  the pen looking at the gate has the default camera ~10 studs behind the fence line at h ~9: keep the first
  CAMERA_GAP (8) studs behind the fence line low (h <= CAMERA_H 3: lawns, pools, steps, walkways, low hedges), put the
  building's mass further back, and keep openings / glass above the players' heads. B.check() lists every landmark
  piece taller than CAMERA_H in that band; the _playercam.png render shows that exact camera.
  The landmark counts in the tri budget (see TRI_STRETCH) and must stay readable from the hub: a big simple silhouette
  (2-4 masses), a few large bevelled details, no tiny parts.

BUILDER  (B, one per variant; all positions are in the CURRENT frame, see FRAMES)
  B.D, B.W, B.variant ("Std"/"Deep"), B.vs / B.us (post stations along v / u), B.posts(),
  B.runs(terminal_gap=None) / B.spans(terminal_gap=None): the continuous runs / the spans between stations; pass the
      theme's TERMINAL_GAP (v0, v1) so the front-right run stops where the terminal module closes the fence
  Every primitive takes  bevel=None|0|width, segs=None|1|2  (None = the role default) and M= (a local matrix applied
  first). Pieces with the same (role, bevel, segs) share one Blender object with its own modifier stack; the export
  joins a role's objects into one mesh. Downward faces lying on the ground / floor (h <= 0.105) are culled.
  -- perimeter modules (draw your OWN silhouette; open ends that butt into a post cost nothing and are not bevelled)
  B.sweep(role, profile, x0, x1, open_ends=(False, False), open="")
        extrude a cross-section profile [(y, z), ...] (y = outward, z = up; any simple polygon) along local X from x0 to
        x1: barriers, walls, rails, copings, skirts. In a side_frame: y >= -INSET keeps it out of the pen. Sweep a
        whole side in one go (B.runs(), cost independent of length) and let posts / corners cover the joints; open
        drops faces hidden under a coping or on a plinth ("-z +z").
  B.sweep_path(role, profile, path, closed=False)     the same along a polyline [(x, y), ...] (mitred): curved walls,
        rings of walls, zig-zag battlements. Profile y = offset to the LEFT of the path direction.
  B.silhouette(role, outline, y0, y1)   outline [(x, z), ...] drawn in the fence plane (x along it, z up), extruded
        across it from y0 to y1: crenellations, spikes, pickets, fins, arches with cut-outs (concave outlines are fine).
  B.repeat(x0, x1, pitch)               evenly spaced stations in x0..x1 (repeating modules, vents, studs, lamps)
  2D helpers (module level): rect_profile(y0, y1, z0, z1), chamfer_profile(y0, y1, z0, z1, c_in, c_out),
        rect_poly(x0, x1, y0, y1, k=0) (k cuts the corners: loft sections), offset_poly(poly, d), arc_points(cx, cy,
        r, a0, a1, n), mirror_x(pts); face_frame(a, b) = a drawing frame on the face a -> b of a swept (y, z) profile
        (Z out of that face): put modules / plates / logos on sloped barrier faces
  -- 3D logos / reliefs (never decals)
  B.relief(poly, steps)                 stepped extrusion of a 2D outline in the frame's XY plane:
        steps = [(role, inset, z0, z1), ...]: each step is the outline offset inward by `inset` and extruded z0..z1
        (0.00 / 0..0.18 + 0.07 / 0.18..0.26 = a letter with a bevelled rim step). Draw in emblem_frame / facing frames
        for upright logos, on the floor (z <= 0.3) for floor emblems.
  B.relief_disc(pos, steps, n=32)       stepped round medallion: steps = [(role, r_out, r_in, z0, z1), ...]
  B.ring_cells(role, r0, r1, z0, z1, n, fill=0.7, a0=pi/2)   n trapezoid cells around a circle (coils, petals, marks)
  -- studs and gems
  B.stud(role, pos, r=0.3, h=0.14, chamfer=0.05, n=8)         a toy stud with a chamfered top face (never a raw cylinder;
        n = 11 reads round with a crisp chamfer, floor studs stay below h 0.3)
  B.stud_grid(role, x0, y0, x1, y1, nx, ny, z, skip=None)     studs on a grid (skip(x, y) -> True drops one)
  B.gem_cube(role, pos, size, rot=pi/4, on_vertex=False)     bevelled cubic gem (on_vertex: standing on a corner)
  B.gem(role, pos, r, h_top, h_bot=None, n=4)               bipyramid crystal
  -- solids
  B.box(role, center, size, rot=0, open="")  open: faces to drop ("-z", "+x -x", ...) where they butt into something
  B.slab(role, mn, mx, open="")        axis-aligned box from two corners
  B.column(role, x, y, rings=[(z, hx, hy), ...], chamfer=0.12)   stepped (octagonal) column
  B.cyl(role, p0, p1, r, n=12) / B.disc(role, pos, r, height, n=16, axis="z") / B.ring(role, pos, r_in, r_out, height, n)
  B.arch(role, center, r_in, r_out, depth, a0=0, a1=pi, n=12) / B.lathe(role, pos, profile=[(r, z), ...], n=12, cap=True)
  B.loft(role, sections=[(z, [(x, y), ...]), ...]) / B.prism(role, poly, z0, z1) / B.plate(role, poly_xz, y0, y1)
  B.beam(role, p0, p1, w, t=None) / B.tiles(role, x0, y0, x1, y1, nx, ny, inset=0.14) / B.strip(role, p0, p1, width)
  B.sphere(role, pos, r, subdiv=1) / B.rock(role, pos, size, seed) / B.tri_ring(role, pos, r_out, r_in, height)
  B.mesh(role, bm, M=None)             any bmesh you built yourself
  B.light(...)                         REMOVED 2026-09-25 (no lights in the bases): a no-op, counted in B.ignored_lights
  Cylinders: n >= 12 sides stay round (side angles below 35 deg are not bevelled and shade smooth).
  BUDGET TIPS: a bevelled closed box costs ~44 tris, the same box open at the bottom ~38, a sweep with open ends and
  hidden faces dropped 8..20; rings cost 2 tris per face per segment (n=24 rings with 3 visible faces ~150): drop
  hidden faces (open=, cap=False), share one sweep per side, keep n low on small round things; on pieces thinner than
  ~0.1 the clamped bevel is invisible (bevel=0 saves ~30 tris each). Measure with --dry-run.
FRAMES (context managers; nest freely)
  with B.frame(T(x, y, z) @ Rz(a)):     any matrix         with B.module("gate"):   tags pieces (problem messages)
  B.side_frame(side, s)   origin on the fence line of side "back"/"front"/"left"/"right" at coordinate s along it,
                          local X along the fence, +Y OUTWARD, Z up (so y >= -INSET is the rule for fence work)
  B.post_frame(post)      origin at a post, +Y outward, X along the fence
  B.corner_frame(sx, sy)  origin at corner (sx*W, sy*D); +X outward along v, +Y outward along u (mirrored as needed:
                          draw one corner, all four match; x, y in -INSET .. CORNER_REACH)
  B.gate_frame()          origin (0, D, 0), X = +v, Y = outward
  B.pylon_frame(side)     origin at gate post side*5.25; +X away from the passage (x >= -1.3 below h 7.5), +Y out
  B.emblem_frame(z, out)  a drawing plane facing out of the gate at height z: local X = the viewer's right, local
                          Y = up, +Z toward the viewer (draw logos with B.relief in XY, extrude along +Z)
  B.terminal_frame()      origin on the ground under the sign centre (v 10.435, u D+1.48), pen axes
  B.landmark_frame()      origin on the back fence line at v 0, X = -v, +Y away from the pen, Z up (see LANDMARK)
  B.facing(normal)        the drawing-plane rotation for any horizontal normal
  Matrices: T(x, y, z), Rx(a), Ry(a), Rz(a), S(sx, sy, sz); AXES["y"] etc.

MODULES (PenTheme methods, run in this order by theme.build(B); the ones marked * have NO default: model your own)
  floor(B)                 Floor_Base tiles over the whole footprint (+ your inlays / studs: floor work only)
  centerpiece(B)           the 3D core in the middle (floor work only: h <= 0.3)
  fence(B)                 calls rail_run() per continuous run, span() per span between stations, post() per post
                           station, corner() per corner (override fence() itself for another rhythm); the runs and
                           spans skip TERMINAL_GAP (v 6.61 .. 14.26 on the front by default): terminal() closes it
  rail_run(B, side, L)     in side_frame at the run's middle, the run spans x -L/2..L/2 (optional)
  span(B, side, L, s0, s1) * in side_frame at the span's middle (s0 / s1 = its ends' world coordinates along the side)
  post(B, post)            * in post_frame
  corner(B)                * in corner_frame (drawn once, mirrored to the four corners)
  gate(B)                  gate_pylon(B, side) * in pylon_frame, gate_lintel(B) * in gate_frame, emblem(B) * in
                           emblem_frame(EMBLEM_Z, EMBLEM_OUT) (radius <= ~2, its lowest point above 7.5)
  terminal(B)              housing around the PlotUpgrade sign (default: a plain frame + bezel; restyle it)
  landmark(B)              LANDMARK_KEYS themes only: the building behind the pen, in landmark_frame (see LANDMARK)

VISUAL LANGUAGE (the six bases read as one family, each with its own silhouette)
  * Same materials: glossy SmoothPlastic structure, matte or glossy floor, ONE bright accent family (non-emissive: no
    Neon, no lights, owner 2026-09-25), readable floor.
  * Same craft: bevel on everything rigid, chunky proportions (players are 5 studs tall), 3D logo on the gate lintel,
    a 3D core relief in the middle of the floor, chamfered studs somewhere (floor or copings).
  * Silhouette: the perimeter stays low (<= ~4.5; the heroes must be seen from outside), corners and gate pylons are
    the accents (6..12 tall), nothing above h 16 over the pen; nothing behind the back fence but a LANDMARK_KEYS
    theme's landmark (<= 34 tall, its mass >= CAMERA_GAP behind the fence).
"""

import math
import random
from contextlib import contextmanager

import bmesh
from mathutils import Matrix, Vector

# ----------------------------------------------------------------------------------------------------------------------
# the pen contract (keep in step with scripts/steps/post_zz_base_themes.luau)
# ----------------------------------------------------------------------------------------------------------------------

FORMAT = "stealahero-base-theme/3"
LEGACY_FORMATS = ("stealahero-base-theme/2",)
W = 26.25
VARIANTS = (("Std", "Std_", 26.25), ("Deep", "Deep_", 31.5))  # (name, object prefix, half depth D)
POST_STEP = 10.5
GATE_V = 5.25
GATE_CLEAR_V = 3.95
GATE_CLEAR_H = 7.5
GATE_CLEAR_U = (-2.5, 3.0)  # relative to D
INSET = 0.62
FLOOR_TOP = 0.1
FLOOR_DETAIL_TOP = 0.3
CORNER_REACH = 1.3
FRONT_MAX = 2.4
SIDE_MAX = 2.0
BACK_REACH = 1.3  # the perimeter may stand this far behind the back fence line; nothing else is behind it
TOP_MAX = 16.0
SIGN_V, SIGN_H, SIGN_U = (7.51, 13.36), (0.98, 4.69), (0.86, 2.10)  # u relative to D
SIGN_SCREEN_V, SIGN_SCREEN_H = (7.95, 12.92), (1.42, 4.25)  # the sign's live screen (never covered from the front)
# the sign's support column and plinth: ((v0, u0 - D, h0), (v1, u1 - D, h1))
SUPPORTS = (((10.0, 0.94, 0.0), (11.0, 1.94, 1.64)), ((9.55, 0.49, 0.0), (11.45, 2.39, 0.36)))
SUPPORT_V = (9.55, 11.45)
TRI_MIN, TRI_MAX = 6000, 9000  # evaluated triangles per complete variant
TRI_STRETCH_MAX = 10000  # a landmark theme's TRI_STRETCH ceiling (owner 2026-09-25: "only if a landmark truly needs it")
FLOOR_ROLE = "Floor_Base"
SCREEN_ROLE = "Neon_Emissive_Screen"  # the name stays (imports); its material is non-emissive since 2026-09-25
MAX_LIGHTS = 0  # no lights in the bases (owner 2026-09-25); B.light() is a no-op
BEVEL_ANGLE = 35.0  # degrees: the Bevel modifier's angle limit and the sharp-edge threshold
# the landmark (LANDMARK in the header): which themes may have one and its zone behind the back fence line
LANDMARK_KEYS = ("Lake", "Desert", "Jungle")
LANDMARK_NEAR = BACK_REACH  # landmark pieces stand entirely behind u = -D - 1.3 (the perimeter owns 0 .. 1.3)
LANDMARK_BACK = 24.0        # ... and within 24 studs of the back fence line (u >= -D - 24)
LANDMARK_TOP = 34.0
LANDMARK_SIDE = SIDE_MAX    # |v| <= W + 2
CAMERA_GAP = 8.0            # camera guidance: nothing taller than CAMERA_H closer than this to the back fence line
CAMERA_H = 3.0
ZONE_PEN, ZONE_LANDMARK = "pen", "landmark"

# material families: role prefix -> allowed Roblox materials, default bevel (width, segments), Blender collection.
# Neon_Emissive keeps its name (the owner's imports: Std_Neon_Emissive_* MeshParts) but is the plain accent family now.
FAMILIES = {
    "Structure": {"materials": ("SmoothPlastic", "Plastic", "Glass"), "bevel": (0.09, 1)},
    "Floor": {"materials": ("SmoothPlastic", "Plastic"), "bevel": (0.03, 1)},
    "Core_3D": {"materials": ("SmoothPlastic", "Plastic"), "bevel": (0.05, 1)},
    "Neon_Emissive": {"materials": ("SmoothPlastic", "Plastic", "Glass"), "bevel": (0.0, 1)},
}
FAMILY_ORDER = ("Structure", "Floor", "Core_3D", "Neon_Emissive")
ROBLOX_MATERIALS = {"Plastic", "SmoothPlastic", "Glass"}  # never "Neon" (owner 2026-09-25)
BANNED_MATERIALS = {"Neon": "Neon is banned in the bases (owner 2026-09-25: 'remove ALL the neon from the bases'): use "
                            "SmoothPlastic (a notch darker than the neon swatch, reflectance 0.04..0.08), Plastic or Glass"}


def family_of(role):
    """The material family of a role name ("Core_3D_Gold" -> "Core_3D"), None when it has none."""
    best = None
    for fam in FAMILIES:
        if role.startswith(fam + "_") and len(role) > len(fam) + 1 and (best is None or len(fam) > len(best)):
            best = fam
    return best


class Look:
    """A role's appearance in Roblox: sRGB colour 0..255, material, transparency, reflectance + its default bevel."""

    def __init__(self, rgb, material="SmoothPlastic", transparency=0.0, reflectance=0.0, bevel=None, segs=None):
        if material in BANNED_MATERIALS:
            raise ValueError("look(%r, %r): %s" % (tuple(rgb), material, BANNED_MATERIALS[material]))
        assert material in ROBLOX_MATERIALS, "unsupported Roblox material %r" % material
        self.rgb = tuple(int(c) for c in rgb)
        self.material = material
        self.transparency = float(transparency)
        self.reflectance = float(reflectance)
        self.bevel = bevel
        self.segs = segs


def look(rgb, material="SmoothPlastic", transparency=0.0, reflectance=0.0, bevel=None, segs=None):
    return Look(rgb, material, transparency, reflectance, bevel, segs)


# ----------------------------------------------------------------------------------------------------------------------
# matrices
# ----------------------------------------------------------------------------------------------------------------------

I4 = Matrix.Identity(4)


def T(x=0.0, y=0.0, z=0.0):
    return Matrix.Translation((x, y, z))


def Rx(a):
    return Matrix.Rotation(a, 4, "X")


def Ry(a):
    return Matrix.Rotation(a, 4, "Y")


def Rz(a):
    return Matrix.Rotation(a, 4, "Z")


def S(sx, sy=None, sz=None):
    sy = sx if sy is None else sy
    sz = sx if sz is None else sz
    return Matrix.Diagonal((sx, sy, sz, 1.0))


def basis(x, y, z, origin=(0.0, 0.0, 0.0)):
    """Matrix whose local X / Y / Z axes are the given world vectors."""
    m = Matrix.Identity(4)
    for i in range(3):
        m[i][0], m[i][1], m[i][2], m[i][3] = x[i], y[i], z[i], origin[i]
    return m


# primitive's local +Z mapped to a world axis
AXES = {"z": I4, "-z": Rx(math.pi), "y": Rx(-math.pi / 2), "-y": Rx(math.pi / 2), "x": Ry(math.pi / 2),
        "-x": Ry(-math.pi / 2)}


def facing(normal):
    """Drawing plane facing a horizontal `normal`: local X = the viewer's right, local Y = up, local +Z = normal."""
    n = Vector((normal[0], normal[1], 0.0)).normalized()
    up = Vector((0.0, 0.0, 1.0))
    x = up.cross(n)
    return basis(x, up, n)


# ----------------------------------------------------------------------------------------------------------------------
# 2D helpers (profiles, outlines)
# ----------------------------------------------------------------------------------------------------------------------

def poly_area(pts):
    return 0.5 * sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1] for i in range(len(pts)))


def ccw(pts):
    pts = [tuple(p) for p in pts]
    return pts if poly_area(pts) >= 0 else list(reversed(pts))


def rect_profile(y0, y1, z0, z1):
    return [(y0, z0), (y1, z0), (y1, z1), (y0, z1)]


def chamfer_profile(y0, y1, z0, z1, c_in=0.0, c_out=0.0):
    """Rectangle y0..y1 x z0..z1 whose top corners are cut by c_in (at y0, the pen side) / c_out (at y1, outside)."""
    pts = [(y0, z0), (y1, z0)]
    if c_out > 0:
        pts += [(y1, z1 - c_out), (y1 - c_out, z1)]
    else:
        pts.append((y1, z1))
    if c_in > 0:
        pts += [(y0 + c_in, z1), (y0, z1 - c_in)]
    else:
        pts.append((y0, z1))
    return pts


def offset_poly(poly, d):
    """Mitred inward offset of a simple polygon by d (negative = outward). Keep d below half the thinnest feature."""
    pts = ccw(poly)
    n = len(pts)
    out = []
    for i in range(n):
        p0, p1, p2 = Vector(pts[i - 1]), Vector(pts[i]), Vector(pts[(i + 1) % n])
        e0, e1 = (p1 - p0).normalized(), (p2 - p1).normalized()
        n0, n1 = Vector((-e0.y, e0.x)), Vector((-e1.y, e1.x))  # inward (left) normals of a ccw polygon
        m = (n0 + n1)
        if m.length < 1e-6:
            m = n0
        m.normalize()
        k = m.dot(n0)
        k = max(k, 0.25)
        q = p1 + m * (d / k)
        out.append((q.x, q.y))
    return out


def rect_poly(x0, x1, y0, y1, k=0.0):
    """Counter-clockwise rectangle x0..x1 x y0..y1, its corners cut by k (an octagon when k > 0): loft sections."""
    if k <= 0:
        return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
    return [(x0 + k, y0), (x1 - k, y0), (x1, y0 + k), (x1, y1 - k), (x1 - k, y1), (x0 + k, y1), (x0, y1 - k), (x0, y0 + k)]


def face_frame(a, b):
    """Drawing frame on the face a -> b of a (y, z) profile swept along X (a side frame): origin at the face's middle,
    local Y up the face, local Z its outward normal (toward +y), local X = Y x Z (right-handed)."""
    a, b = Vector(a), Vector(b)
    if b.y < a.y:
        a, b = b, a
    up = (b - a).normalized()
    out = Vector((up.y, -up.x))
    if out.x < 0:
        out = -out
    y3, z3 = Vector((0.0, up.x, up.y)), Vector((0.0, out.x, out.y))
    mid = (a + b) / 2
    return basis(y3.cross(z3), y3, z3, (0.0, mid.x, mid.y))


def arc_points(cx, cy, r, a0, a1, n):
    return [(cx + r * math.cos(a0 + (a1 - a0) * i / n), cy + r * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]


def mirror_x(pts):
    return [(-x, y) for x, y in reversed(pts)]


# ----------------------------------------------------------------------------------------------------------------------
# bmesh primitives (local space, closed solids unless stated, normals outward; SHARP geometry: the modifier bevels it)
# ----------------------------------------------------------------------------------------------------------------------

def _finish(bm):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return bm


def _drop_faces(bm, axes):
    """Deletes the box faces whose normal is one of `axes` ("-z", "+x", ...)."""
    if not axes:
        return
    bm.normal_update()
    want = []
    for tok in axes.split():
        s = -1.0 if tok[0] == "-" else 1.0
        k = "xyz".index(tok[-1])
        want.append((k, s))
    dead = [f for f in bm.faces if any(f.normal[k] * s > 0.99 for k, s in want)]
    bmesh.ops.delete(bm, geom=dead, context="FACES_ONLY")


def bm_box(sx, sy, sz, open=""):
    """Box centred on the origin; `open` drops faces ("-z" = open bottom, "-y +y" = open both ends along y ...)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=(sx, sy, sz), verts=bm.verts[:])
    _finish(bm)
    _drop_faces(bm, open)
    return bm


def chamfer_ring(hx, hy, c, z):
    if c <= 1e-6:
        return [Vector(p) for p in ((hx, -hy, z), (hx, hy, z), (-hx, hy, z), (-hx, -hy, z))]
    return [Vector(p) for p in (
        (hx - c, -hy, z), (hx, -hy + c, z), (hx, hy - c, z), (hx - c, hy, z),
        (-hx + c, hy, z), (-hx, hy - c, z), (-hx, -hy + c, z), (-hx + c, -hy, z))]


def _bridge(bm, ra, rb, closed=True):
    """Quads (or triangles at a pole) between two rings of equal count; a ring may be a single pole vertex."""
    if len(ra) == 1 and len(rb) == 1:
        return
    if len(ra) == 1:
        for i in range(len(rb) if closed else len(rb) - 1):
            bm.faces.new((ra[0], rb[i], rb[(i + 1) % len(rb)]))
        return
    if len(rb) == 1:
        for i in range(len(ra) if closed else len(ra) - 1):
            bm.faces.new((ra[i], ra[(i + 1) % len(ra)], rb[0]))
        return
    n = len(ra)
    for i in range(n if closed else n - 1):
        j = (i + 1) % n
        bm.faces.new((ra[i], ra[j], rb[j], rb[i]))


def bm_column(rings, chamfer=0.12):
    """Stepped square column: rings = [(z, hx, hy), ...] bottom to top, octagonal (chamfered) sections."""
    bm = bmesh.new()
    loops = [[bm.verts.new(p) for p in chamfer_ring(hx, hy, min(chamfer, 0.4 * hx, 0.4 * hy), z)] for z, hx, hy in rings]
    for a, b in zip(loops, loops[1:]):
        _bridge(bm, a, b)
    bm.faces.new(loops[-1])
    bm.faces.new(list(reversed(loops[0])))
    return _finish(bm)


def bm_loft(sections, cap_top=True, cap_bottom=True):
    """sections = [(z, [(x, y), ...]), ...] bottom to top, the same point count everywhere (counter-clockwise)."""
    bm = bmesh.new()
    loops = []
    for z, pts in sections:
        loops.append([bm.verts.new((p[0], p[1], z)) for p in pts])
    for a, b in zip(loops, loops[1:]):
        _bridge(bm, a, b)
    if cap_top and len(loops[-1]) > 2:
        bm.faces.new(loops[-1])
    if cap_bottom and len(loops[0]) > 2:
        bm.faces.new(list(reversed(loops[0])))
    return _finish(bm)


def bm_prism(poly, z0, z1, cap_bottom=True):
    """Extruded polygon (x, y) from z0 to z1; any simple polygon (concave allowed)."""
    return bm_loft([(z0, ccw(poly)), (z1, ccw(poly))], cap_bottom=cap_bottom)


def bm_sweep(profile, x0, x1, open_ends=(False, False)):
    """Cross-section profile [(y, z), ...] extruded along X from x0 to x1 (a ccw profile + x1 > x0 = outward normals)."""
    if x1 < x0:
        x0, x1 = x1, x0
        open_ends = (open_ends[1], open_ends[0])
    prof = ccw(profile)
    bm = bmesh.new()
    a = [bm.verts.new((x0, y, z)) for y, z in prof]
    b = [bm.verts.new((x1, y, z)) for y, z in prof]
    _bridge(bm, a, b)
    if not open_ends[0]:
        bm.faces.new(list(reversed(a)))
    if not open_ends[1]:
        bm.faces.new(b)
    return bm


def bm_sweep_path(profile, path, closed=False, open_ends=(False, False)):
    """Profile [(y, z)] (y = left of the path direction) swept along a polyline [(x, y)] in the XY plane, mitred."""
    prof = ccw(profile)
    pts = [Vector((p[0], p[1])) for p in path]
    n = len(pts)
    bm = bmesh.new()
    loops = []
    for i in range(n):
        if closed:
            d0 = (pts[i] - pts[i - 1]).normalized()
            d1 = (pts[(i + 1) % n] - pts[i]).normalized()
        else:
            d0 = (pts[i] - pts[i - 1]).normalized() if i > 0 else (pts[1] - pts[0]).normalized()
            d1 = (pts[i + 1] - pts[i]).normalized() if i < n - 1 else d0
        t = (d0 + d1)
        t = t.normalized() if t.length > 1e-6 else d1
        left = Vector((-t.y, t.x))
        seg_left = Vector((-d1.y, d1.x))
        k = max(left.dot(seg_left), 0.3)
        loops.append([bm.verts.new((pts[i].x + left.x * y / k, pts[i].y + left.y * y / k, z)) for y, z in prof])
    for i in range(n if closed else n - 1):
        _bridge(bm, loops[i], loops[(i + 1) % n])
    if not closed:
        if not open_ends[0]:
            bm.faces.new(list(reversed(loops[0])))
        if not open_ends[1]:
            bm.faces.new(loops[-1])
    return bm


def bm_lathe(profile, n=12, a0=0.0, cap=True):
    """Revolve profile [(r, z), ...] (bottom to top) about Z; r == 0 makes a pole; open ends are capped."""
    bm = bmesh.new()
    loops = []
    for r, z in profile:
        if r <= 1e-6:
            loops.append([bm.verts.new((0.0, 0.0, z))])
        else:
            loops.append([bm.verts.new((r * math.cos(a0 + 2 * math.pi * i / n), r * math.sin(a0 + 2 * math.pi * i / n), z))
                          for i in range(n)])
    for a, b in zip(loops, loops[1:]):
        _bridge(bm, a, b)
    if cap and len(loops[0]) > 2:
        bm.faces.new(list(reversed(loops[0])))
    if cap and len(loops[-1]) > 2:
        bm.faces.new(loops[-1])
    return _finish(bm)


def bm_ring(r_in, r_out, z0, z1, n=24, a0=0.0, a1=2 * math.pi):
    full = abs((a1 - a0) - 2 * math.pi) < 1e-6
    steps = max(1, n)
    count = steps if full else steps + 1
    bm = bmesh.new()
    rings = []
    for r, z in ((r_out, z0), (r_out, z1), (r_in, z1), (r_in, z0)):
        rings.append([bm.verts.new((r * math.cos(a0 + (a1 - a0) * i / steps), r * math.sin(a0 + (a1 - a0) * i / steps), z))
                      for i in range(count)])
    for k in range(4):
        ra, rb = rings[k], rings[(k + 1) % 4]
        for i in range(steps):
            j = (i + 1) % count
            bm.faces.new((ra[i], ra[j], rb[j], rb[i]))
    if not full:
        bm.faces.new([rings[k][0] for k in range(4)])
        bm.faces.new([rings[k][count - 1] for k in reversed(range(4))])
    return _finish(bm)


def bm_disc(r, z0, z1, n=16, a0=0.0):
    return bm_lathe([(r, z0), (r, z1)], n, a0)


def bm_stud(r=0.3, h=0.14, chamfer=0.05, n=8):
    """Toy stud standing on z 0: straight side, chamfered top edge, flat top (open bottom)."""
    c = min(chamfer, 0.45 * h, 0.4 * r)
    bm = bm_lathe([(r, 0.0), (r, h - c), (r - c, h)], n, math.pi / n)
    return bm


def bm_gem(r, h_top, h_bot=None, n=4, a0=math.pi / 4):
    return bm_lathe([(0.0, -(h_top if h_bot is None else h_bot)), (r, 0.0), (0.0, h_top)], n, a0)


def bm_tile(sx, sy, inset, z0, z1):
    """Floor tile: flat top inset by `inset`, chamfered down to the groove at z0."""
    bm = bmesh.new()
    hx, hy = sx / 2, sy / 2
    lo = [bm.verts.new(p) for p in ((-hx, -hy, z0), (hx, -hy, z0), (hx, hy, z0), (-hx, hy, z0))]
    hi = [bm.verts.new(p) for p in ((-hx + inset, -hy + inset, z1), (hx - inset, -hy + inset, z1),
                                    (hx - inset, hy - inset, z1), (-hx + inset, hy - inset, z1))]
    _bridge(bm, lo, hi)
    bm.faces.new(hi)
    bm.faces.new(list(reversed(lo)))
    return _finish(bm)


def bm_arch(r_in, r_out, depth, a0=0.0, a1=math.pi, n=12):
    """Arch band in the XZ plane (angle 0 = +X, pi/2 = up), `depth` along Y centred on y = 0."""
    bm = bm_ring(r_in, r_out, -depth / 2, depth / 2, n, a0, a1)
    bm.transform(Rx(math.pi / 2))  # ring plane XY -> XZ (its +Y goes up)
    return _finish(bm)


def bm_tri_ring(r_out, r_in, z0, z1, rot=math.pi / 2):
    bm = bmesh.new()

    def tri(r, z):
        return [bm.verts.new((r * math.cos(rot + 2 * math.pi * i / 3), r * math.sin(rot + 2 * math.pi * i / 3), z)) for i in range(3)]

    rings = [tri(r_out, z0), tri(r_out, z1), tri(r_in, z1), tri(r_in, z0)]
    for k in range(4):
        ra, rb = rings[k], rings[(k + 1) % 4]
        for i in range(3):
            j = (i + 1) % 3
            bm.faces.new((ra[i], ra[j], rb[j], rb[i]))
    return _finish(bm)


def bm_sphere(r, subdiv=1):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=r)
    return _finish(bm)


def bm_rock(size, seed=0, subdiv=1, jitter=0.22):
    rnd = random.Random(seed)
    bm = bm_sphere(1.0, subdiv)
    for v in bm.verts:
        k = 1.0 + rnd.uniform(-jitter, jitter)
        v.co = Vector((v.co.x * k * size[0] / 2, v.co.y * k * size[1] / 2, v.co.z * k * size[2] / 2))
    return _finish(bm)


# ----------------------------------------------------------------------------------------------------------------------
# the builder
# ----------------------------------------------------------------------------------------------------------------------

SIDES = {
    # name: (axis the fence runs along, fixed coordinate sign, outward normal, local X direction)
    "back": ("x", -1, (0.0, -1.0), (-1.0, 0.0)),
    "front": ("x", 1, (0.0, 1.0), (1.0, 0.0)),
    "left": ("y", -1, (-1.0, 0.0), (0.0, 1.0)),
    "right": ("y", 1, (1.0, 0.0), (0.0, -1.0)),
}


def stations(half):
    n = int(round(2 * half / POST_STEP))
    return [-half + POST_STEP * i for i in range(n + 1)]


class Post:
    """A fence post station: kind 'corner' | 'gate' | 'post', world position, its side and outward normal."""

    def __init__(self, kind, x, y, side, out):
        self.kind, self.x, self.y, self.side, self.out = kind, x, y, side, out

    def __repr__(self):
        return "Post(%s, %.2f, %.2f, %s)" % (self.kind, self.x, self.y, self.side)


class Builder:
    def __init__(self, theme, variant, prefix, D):
        self.theme = theme
        self.variant = variant
        self.prefix = prefix
        self.D = D
        self.W = W
        self.vs = stations(W)
        self.us = stations(D)
        self.acc = {}       # (role, bevel, segs) -> bmesh
        self.pieces = []    # (role, (min), (max), module)
        self.piece_zones = []  # ZONE_PEN | ZONE_LANDMARK, one per piece (same index as self.pieces)
        self.lights = []    # always empty since 2026-09-25 (no lights in the bases)
        self.ignored_lights = 0  # B.light() calls (a no-op now)
        self.stack = [I4.copy()]
        self.modules = ["pen"]
        self.zones = [ZONE_PEN]

    # -- frames ---------------------------------------------------------------------------------------------------
    @contextmanager
    def frame(self, M):
        self.stack.append(self.stack[-1] @ M)
        try:
            yield self
        finally:
            self.stack.pop()

    @contextmanager
    def module(self, name):
        self.modules.append(name)
        try:
            yield self
        finally:
            self.modules.pop()

    @contextmanager
    def zone(self, name):
        """The contract zone of the pieces drawn inside (ZONE_PEN, or ZONE_LANDMARK for PenTheme.landmark())."""
        assert name in (ZONE_PEN, ZONE_LANDMARK), name
        self.zones.append(name)
        try:
            yield self
        finally:
            self.zones.pop()

    def landmark_frame(self):
        """Origin on the back fence line at v 0: X = -v (a player's right looking at the landmark from the pen), +Y away
        from the pen (the landmark's depth, y 1.3 .. 24), Z up."""
        return self.side_frame("back", 0.0)

    def side_frame(self, side, s):
        axis, sign, out, xdir = SIDES[side]
        if axis == "x":
            origin = (s, sign * self.D, 0.0)
        else:
            origin = (sign * self.W, s, 0.0)
        return basis((xdir[0], xdir[1], 0.0), (out[0], out[1], 0.0), (0.0, 0.0, 1.0), origin)

    def post_frame(self, post):
        o = post.out
        return basis((o[1], -o[0], 0.0), (o[0], o[1], 0.0), (0.0, 0.0, 1.0), (post.x, post.y, 0.0))

    def corner_frame(self, sx, sy):
        return basis((sx, 0.0, 0.0), (0.0, sy, 0.0), (0.0, 0.0, 1.0), (sx * self.W, sy * self.D, 0.0))

    def gate_frame(self):
        return T(0.0, self.D, 0.0)

    def pylon_frame(self, side):
        return basis((side, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0), (side * GATE_V, self.D, 0.0))

    def emblem_frame(self, z, out):
        return T(0.0, self.D + out, z) @ facing((0.0, 1.0))

    def terminal_frame(self):
        """Origin on the ground under the sign's centre (v 10.435, u D+1.48), pen axes."""
        return T((SIGN_V[0] + SIGN_V[1]) / 2, self.D + (SIGN_U[0] + SIGN_U[1]) / 2, 0.0)

    facing = staticmethod(facing)

    # -- layout ---------------------------------------------------------------------------------------------------
    def posts(self):
        out = []
        D, Wd = self.D, self.W
        for x in self.vs:
            for y, side in ((-D, "back"), (D, "front")):
                o = SIDES[side][2]
                if abs(abs(x) - Wd) < 1e-6:
                    out.append(Post("corner", x, y, side, o))
                elif side == "front" and abs(abs(x) - GATE_V) < 1e-6:
                    out.append(Post("gate", x, y, side, o))
                else:
                    out.append(Post("post", x, y, side, o))
        for y in self.us[1:-1]:
            for x, side in ((-Wd, "left"), (Wd, "right")):
                out.append(Post("post", x, y, side, SIDES[side][2]))
        return out

    def runs(self, terminal_gap=None):
        """Continuous runs: (side, s0, s1) with s along the side's axis (world coordinate). terminal_gap = (v0, v1): the
        front-right run stops there (the terminal module closes that stretch around the PlotUpgrade sign)."""
        D, Wd = self.D, self.W
        front_right = [("front", GATE_V, Wd)]
        if terminal_gap:
            front_right = [("front", GATE_V, terminal_gap[0]), ("front", terminal_gap[1], Wd)]
        return [("back", -Wd, Wd), ("front", -Wd, -GATE_V)] + front_right + [("left", -D, D), ("right", -D, D)]

    def spans(self, terminal_gap=None):
        """(side, s0, s1) between neighbouring stations, the gate opening (and the front spans overlapping terminal_gap)
        excluded."""
        out = []
        for side, pts in (("back", self.vs), ("front", self.vs), ("left", self.us), ("right", self.us)):
            for s0, s1 in zip(pts, pts[1:]):
                if side == "front" and s0 >= -GATE_V - 1e-6 and s1 <= GATE_V + 1e-6:
                    continue
                if side == "front" and terminal_gap and s0 < terminal_gap[1] and s1 > terminal_gap[0]:
                    continue
                out.append((side, s0, s1))
        return out

    @staticmethod
    def repeat(x0, x1, pitch):
        """Evenly spaced stations inside x0..x1, about `pitch` apart, centred (at least one)."""
        n = max(1, int(round((x1 - x0) / pitch)))
        step = (x1 - x0) / n
        return [x0 + step * (i + 0.5) for i in range(n)]

    # -- core ------------------------------------------------------------------------------------------------------
    def bevel_of(self, role, bevel=None, segs=None, smooth=False):
        """Bucket key tail (bevel width, segments, smooth): smooth=True skips the sharp-by-angle marking (small round
        things like studs read round with 8 sides)."""
        lk = self.theme.PALETTE[role]
        fam = FAMILIES.get(family_of(role) or "", {"bevel": (0.0, 1)})
        w = bevel if bevel is not None else (lk.bevel if lk.bevel is not None else fam["bevel"][0])
        s = segs if segs is not None else (lk.segs if lk.segs is not None else fam["bevel"][1])
        w = round(float(w), 3)
        return (w, int(s) if w > 0 else 0, bool(smooth))

    def mesh(self, role, bm, M=None, cull=True, bevel=None, segs=None, smooth=False):
        """Adds a local-space bmesh to `role` through the current frame (and M). Consumes bm."""
        if role not in self.theme.PALETTE:
            raise KeyError("role %r is not in %s.PALETTE" % (role, type(self.theme).__name__))
        m = self.stack[-1] @ (M if M is not None else I4)
        bm.transform(m)
        if m.to_3x3().determinant() < 0:
            bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
        bm.normal_update()
        if cull:
            dead = [f for f in bm.faces if f.normal.z < -0.99 and max(v.co.z for v in f.verts) <= 0.105]
            if dead:
                bmesh.ops.delete(bm, geom=dead, context="FACES_ONLY")
        if not bm.faces:
            bm.free()
            return
        xs = [v.co.x for v in bm.verts]
        ys = [v.co.y for v in bm.verts]
        zs = [v.co.z for v in bm.verts]
        self.pieces.append((role, (min(xs), min(ys), min(zs)), (max(xs), max(ys), max(zs)), self.modules[-1]))
        self.piece_zones.append(self.zones[-1])
        key = (role,) + self.bevel_of(role, bevel, segs, smooth)
        dst = self.acc.get(key)
        if dst is None:
            dst = self.acc[key] = bmesh.new()
        vmap = {}
        for f in bm.faces:
            vs = []
            for v in f.verts:
                nv = vmap.get(v)
                if nv is None:
                    nv = vmap[v] = dst.verts.new(v.co)
                vs.append(nv)
            dst.faces.new(vs)
        bm.free()

    def _m(self, pos, M, axis="z", rot=0.0):
        m = T(*pos) @ AXES[axis] @ (Rz(rot) if rot else I4)
        return m @ M if M is not None else m

    # -- perimeter modules -----------------------------------------------------------------------------------------
    def sweep(self, role, profile, x0, x1, open_ends=(False, False), open="", M=None, bevel=None, segs=None):
        """open: faces to drop by their local normal ("-z" = the bottom resting on something, "+z" = a top hidden
        under a coping), like B.box."""
        bm = bm_sweep(profile, x0, x1, open_ends)
        _drop_faces(bm, open)
        self.mesh(role, bm, M, bevel=bevel, segs=segs)

    def sweep_path(self, role, profile, path, closed=False, open_ends=(False, False), open="", M=None, bevel=None, segs=None):
        bm = bm_sweep_path(profile, path, closed, open_ends)
        _drop_faces(bm, open)
        self.mesh(role, bm, M, bevel=bevel, segs=segs)

    def silhouette(self, role, outline, y0, y1, M=None, bevel=None, segs=None):
        """Outline [(x, z), ...] in the fence plane (x along it, z up), extruded across it from y0 to y1."""
        self.plate(role, outline, y0, y1, M=M, bevel=bevel, segs=segs)

    # -- reliefs ---------------------------------------------------------------------------------------------------
    def relief(self, poly, steps, M=None, open_bottom=True):
        """Stepped extrusion of a 2D outline (frame XY): steps = [(role, inset, z0, z1[, bevel]), ...]. The bottom
        faces (local -z, lying on the surface the relief stands on) are dropped unless open_bottom=False."""
        for st in steps:
            role, inset, z0, z1 = st[:4]
            bevel = st[4] if len(st) > 4 else None
            pts = offset_poly(poly, inset) if inset else ccw(poly)
            self.mesh(role, bm_prism(pts, z0, z1, cap_bottom=not open_bottom), M, bevel=bevel)

    def relief_disc(self, pos, steps, n=32, a0=0.0, axis="z", M=None, open_bottom=True):
        """Stepped round medallion: steps = [(role, r_out, r_in, z0, z1[, bevel]), ...] (r_in 0 = solid); bottom faces
        dropped unless open_bottom=False."""
        for st in steps:
            role, r_out, r_in, z0, z1 = st[:5]
            bevel = st[5] if len(st) > 5 else None
            if r_in > 1e-6:
                bm = bm_ring(r_in, r_out, z0, z1, n, a0, a0 + 2 * math.pi)
            else:
                bm = bm_disc(r_out, z0, z1, n, a0)
            if open_bottom:
                _drop_faces(bm, "-z")
            self.mesh(role, bm, self._m(pos, M, axis), bevel=bevel)

    def ring_cells(self, role, r0, r1, z0, z1, n, fill=0.7, a0=math.pi / 2, M=None, bevel=None, taper=1.0):
        """n trapezoid cells between radii r0 and r1 (frame XY, z0..z1); `taper` scales the inner width."""
        for k in range(n):
            a = a0 + 2 * math.pi * k / n
            h = math.pi / n * fill
            hi = h * taper
            pts = [(r0 * math.cos(a - hi), r0 * math.sin(a - hi)), (r1 * math.cos(a - h), r1 * math.sin(a - h)),
                   (r1 * math.cos(a + h), r1 * math.sin(a + h)), (r0 * math.cos(a + hi), r0 * math.sin(a + hi))]
            self.mesh(role, bm_prism(pts, z0, z1), M, bevel=bevel)

    # -- studs and gems ----------------------------------------------------------------------------------------------
    def stud(self, role, pos, r=0.3, h=0.14, chamfer=0.05, n=8, axis="z", M=None):
        """A toy stud (chamfered top face by construction, so no modifier bevel; shaded round)."""
        self.mesh(role, bm_stud(r, h, chamfer, n), self._m(pos, M, axis), bevel=0, smooth=True)

    def stud_grid(self, role, x0, y0, x1, y1, nx, ny, z, skip=None, **kw):
        n = 0
        for i in range(nx):
            for j in range(ny):
                x = x0 + (x1 - x0) * (i / (nx - 1) if nx > 1 else 0.5)
                y = y0 + (y1 - y0) * (j / (ny - 1) if ny > 1 else 0.5)
                if skip and skip(x, y):
                    continue
                self.stud(role, (x, y, z), **kw)
                n += 1
        return n

    def gem_cube(self, role, pos, size, rot=math.pi / 4, on_vertex=False, M=None, bevel=None, segs=None):
        """Bevelled cubic gem centred on pos, turned by `rot` about Z; on_vertex stands it on a corner (height
        size * sqrt(3))."""
        m = T(*pos) @ Rz(rot) @ (Ry(-math.atan(1 / math.sqrt(2))) @ Rx(math.pi / 4) if on_vertex else I4)
        w = bevel if bevel is not None else max(0.04, 0.12 * size)
        self.mesh(role, bm_box(size, size, size), m @ M if M is not None else m, bevel=w, segs=segs)

    def gem(self, role, pos, r, h_top, h_bot=None, n=4, rot=math.pi / 4, M=None, bevel=None):
        self.mesh(role, bm_gem(r, h_top, h_bot, n, rot), self._m(pos, M), bevel=bevel)

    # -- solids ----------------------------------------------------------------------------------------------------
    def box(self, role, center, size, rot=0.0, M=None, open="", bevel=None, segs=None):
        self.mesh(role, bm_box(size[0], size[1], size[2], open), self._m(center, M, "z", rot), bevel=bevel, segs=segs)

    def slab(self, role, mn, mx, open="", bevel=None, segs=None):
        c = ((mn[0] + mx[0]) / 2, (mn[1] + mx[1]) / 2, (mn[2] + mx[2]) / 2)
        self.box(role, c, (mx[0] - mn[0], mx[1] - mn[1], mx[2] - mn[2]), open=open, bevel=bevel, segs=segs)

    def plate(self, role, poly, y0, y1, M=None, bevel=None, segs=None):
        """Polygon [(x, z), ...] in the frame's XZ plane (x across, z up), extruded along Y from y0 to y1."""
        flip = basis((1.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, 1.0, 0.0))
        self.mesh(role, bm_prism(poly, y0, y1), flip if M is None else M @ flip, bevel=bevel, segs=segs)

    def strip(self, role, p0, p1, width, z0=FLOOR_TOP, z1=FLOOR_TOP + 0.05, bevel=None):
        """Raised strip on the floor from (x, y) p0 to p1 (circuits, lane lines, seams): floor work when z1 <= 0.3."""
        a, b = Vector((p0[0], p0[1], 0.0)), Vector((p1[0], p1[1], 0.0))
        d = b - a
        ang = math.atan2(d.y, d.x)
        mid = (a + b) / 2
        self.box(role, (mid.x, mid.y, (z0 + z1) / 2), (d.length + width, width, z1 - z0), rot=ang, bevel=bevel)

    def column(self, role, x, y, rings, chamfer=0.12, rot=0.0, M=None, bevel=None, segs=None):
        self.mesh(role, bm_column(rings, chamfer), self._m((x, y, 0.0), M, "z", rot), bevel=bevel, segs=segs)

    def cyl(self, role, p0, p1, r, n=12, a0=0.0, bevel=None):
        a, b = Vector(p0), Vector(p1)
        d = b - a
        z = d.normalized()
        ref = Vector((1.0, 0.0, 0.0)) if abs(z.z) > 0.95 else Vector((0.0, 0.0, 1.0))
        x = ref.cross(z).normalized()
        y = z.cross(x)
        self.mesh(role, bm_disc(r, 0.0, d.length, n, a0), basis(x, y, z, a), bevel=bevel)

    def disc(self, role, pos, r, height, n=16, axis="z", a0=0.0, M=None, bevel=None, segs=None):
        self.mesh(role, bm_disc(r, 0.0, height, n, a0), self._m(pos, M, axis), bevel=bevel, segs=segs)

    def ring(self, role, pos, r_in, r_out, height, n=24, a0=0.0, a1=2 * math.pi, axis="z", M=None, bevel=None, segs=None):
        self.mesh(role, bm_ring(r_in, r_out, 0.0, height, n, a0, a1), self._m(pos, M, axis), bevel=bevel, segs=segs)

    def arch(self, role, center, r_in, r_out, depth, a0=0.0, a1=math.pi, n=12, M=None, bevel=None):
        self.mesh(role, bm_arch(r_in, r_out, depth, a0, a1, n), self._m(center, M), bevel=bevel)

    def lathe(self, role, pos, profile, n=12, a0=0.0, axis="z", cap=True, M=None, bevel=None, segs=None):
        """Revolved profile [(r, z), ...]; cap=False leaves the ends open (a ring profile that starts and ends on the
        floor: stepped rims, collars)."""
        self.mesh(role, bm_lathe(profile, n, a0, cap), self._m(pos, M, axis), bevel=bevel, segs=segs)

    def loft(self, role, sections, pos=(0.0, 0.0, 0.0), cap_top=True, cap_bottom=True, M=None, bevel=None, segs=None):
        self.mesh(role, bm_loft(sections, cap_top, cap_bottom), self._m(pos, M), bevel=bevel, segs=segs)

    def prism(self, role, poly, z0, z1, M=None, bevel=None, segs=None):
        self.mesh(role, bm_prism(poly, z0, z1), M, bevel=bevel, segs=segs)

    def sphere(self, role, pos, r, subdiv=1, M=None, bevel=0):
        self.mesh(role, bm_sphere(r, subdiv), self._m(pos, M), bevel=bevel)

    def rock(self, role, pos, size, seed=0, subdiv=1, jitter=0.22, M=None, bevel=0):
        self.mesh(role, bm_rock(size, seed, subdiv, jitter), self._m(pos, M), bevel=bevel)

    def beam(self, role, p0, p1, w, t=None, bevel=None, open=""):
        a, b = Vector(p0), Vector(p1)
        d = b - a
        x = d.normalized()
        ref = Vector((0.0, 0.0, 1.0)) if abs(x.z) < 0.95 else Vector((1.0, 0.0, 0.0))
        y = ref.cross(x).normalized()
        z = x.cross(y)
        mid = (a + b) / 2
        self.mesh(role, bm_box(d.length, w, w if t is None else t, open), basis(x, y, z, mid), bevel=bevel)

    def tiles(self, role, x0, y0, x1, y1, nx, ny, inset=0.14, z0=0.0, z1=FLOOR_TOP, bevel=0):
        tx, ty = (x1 - x0) / nx, (y1 - y0) / ny
        for i in range(nx):
            for j in range(ny):
                self.mesh(role, bm_tile(tx, ty, inset, z0, z1), T(x0 + tx * (i + 0.5), y0 + ty * (j + 0.5), 0.0), bevel=bevel)

    def tri_ring(self, role, pos, r_out, r_in, height, rot=math.pi / 2, axis="z", M=None, bevel=None):
        self.mesh(role, bm_tri_ring(r_out, r_in, 0.0, height, rot), self._m(pos, M, axis), bevel=bevel)

    def light(self, pos, range=12.0, brightness=1.2, color=(255, 255, 255)):
        """REMOVED 2026-09-25 (owner: no glow in the bases): kept as a no-op so older theme code still runs; counted in
        ignored_lights and reported by run.py. Never exported."""
        self.ignored_lights += 1

    def zone_of(self, index):
        return self.piece_zones[index] if index < len(self.piece_zones) else ZONE_PEN

    def landmark_bounds(self):
        """(min, max) of the landmark pieces, None without a landmark."""
        boxes = [(p[1], p[2]) for i, p in enumerate(self.pieces) if self.zone_of(i) == ZONE_LANDMARK]
        if not boxes:
            return None
        return ([min(b[0][k] for b in boxes) for k in range(3)], [max(b[1][k] for b in boxes) for k in range(3)])

    def camera_warnings(self):
        """Landmark pieces taller than CAMERA_H within CAMERA_GAP of the back fence line (guidance, see LANDMARK)."""
        out = []
        D = self.D
        for i, (role, mn, mx, mod) in enumerate(self.pieces):
            if self.zone_of(i) == ZONE_LANDMARK and mx[2] > CAMERA_H + 1e-3 and mx[1] > -D - CAMERA_GAP + 1e-3:
                out.append("camera: %s %s %s..%s stands %.1f studs behind the back fence, %.1f tall (keep h <= %g within %g "
                           "studs: the player's camera passes through CanCollide-off parts)" % (
                               mod, role, fmt(mn), fmt(mx), -D - mx[1], mx[2], CAMERA_H, CAMERA_GAP))
        return out

    # -- results ---------------------------------------------------------------------------------------------------
    def check(self, plots=None):
        """Problems against the pen contract (strings; empty = fine). `plots`: the plot_obstacles.json entries."""
        problems = []
        D, Wd, eps = self.D, self.W, 1e-3
        roles = {p[0] for p in self.pieces}
        if FLOOR_ROLE not in roles:
            problems.append("no %s pieces (the loader's floor anchor)" % FLOOR_ROLE)
        if SCREEN_ROLE not in roles:
            problems.append("no %s pieces (the terminal bezel, the loader's anchor)" % SCREEN_ROLE)
        sign = ((SIGN_V[0], D + SIGN_U[0], SIGN_H[0]), (SIGN_V[1], D + SIGN_U[1], SIGN_H[1]))
        keep_out = [("PlotUpgrade sign", sign)] + [("sign support", ((a[0], D + a[1], a[2]), (b[0], D + b[1], b[2])))
                                                   for a, b in SUPPORTS]
        # the sign's live screen seen from the front: nothing in front of it (u > D + 2.10) over its face
        screen = ((SIGN_SCREEN_V[0], D + SIGN_U[1], SIGN_SCREEN_H[0]), (SIGN_SCREEN_V[1], D + FRONT_MAX + 1.0, SIGN_SCREEN_H[1]))
        keep_out.append(("sign's screen (covered from the front)", screen))
        floor_mn, floor_mx = [1e9] * 3, [-1e9] * 3
        landmark_key = getattr(self.theme, "KEY", None) in LANDMARK_KEYS
        for i, (role, mn, mx, mod) in enumerate(self.pieces):
            tag = "%s %s %s..%s" % (mod, role, fmt(mn), fmt(mx))
            if self.zone_of(i) == ZONE_LANDMARK:
                # the landmark zone behind the back fence (LANDMARK in the header)
                if not landmark_key:
                    problems.append("%s: a landmark, but %s is not a landmark theme %s (its plots stay open)" % (
                        tag, getattr(self.theme, "KEY", None), LANDMARK_KEYS))
                if role == FLOOR_ROLE or role == SCREEN_ROLE:
                    problems.append("%s: the anchor role %s belongs to the pen, not the landmark" % (tag, role))
                if mx[1] > -D - LANDMARK_NEAR + eps or mn[1] < -D - LANDMARK_BACK - eps:
                    problems.append("%s: outside the landmark zone (%g .. %g studs behind the back fence line)" % (
                        tag, LANDMARK_NEAR, LANDMARK_BACK))
                if abs(mn[0]) > Wd + LANDMARK_SIDE + eps or abs(mx[0]) > Wd + LANDMARK_SIDE + eps:
                    problems.append("%s: past the landmark's side limit |v| <= W+%g" % (tag, LANDMARK_SIDE))
                if mx[2] > LANDMARK_TOP + eps or mn[2] < -0.05:
                    problems.append("%s: outside the landmark's height limits (0..%g)" % (tag, LANDMARK_TOP))
                continue
            if mx[2] > TOP_MAX + eps or mn[2] < -0.05:
                problems.append("%s: outside the height limits (0..%g)" % (tag, TOP_MAX))
            if abs(mn[0]) > Wd + SIDE_MAX + eps or abs(mx[0]) > Wd + SIDE_MAX + eps:
                problems.append("%s: past the side limit |v| <= W+%g" % (tag, SIDE_MAX))
            if role == FLOOR_ROLE:
                for k in range(3):
                    floor_mn[k], floor_mx[k] = min(floor_mn[k], mn[k]), max(floor_mx[k], mx[k])
                continue
            if mn[1] < -D - BACK_REACH - eps:
                problems.append("%s: behind the back fence (the perimeter reaches at most %g behind it; a landmark theme draws "
                                "its building in landmark())" % (tag, BACK_REACH))
            if mx[1] > D + FRONT_MAX + eps:
                problems.append("%s: past the front limit u <= D+%g" % (tag, FRONT_MAX))
            floor_work = mx[2] <= FLOOR_DETAIL_TOP + eps
            inside_x = mx[0] > -Wd + INSET + eps and mn[0] < Wd - INSET - eps
            inside_y = mx[1] > -D + INSET + eps and mn[1] < D - INSET - eps
            if inside_x and inside_y and not floor_work:
                problems.append("%s: reaches into the pen (more than %g inside the fence, above h %g)" % (tag, INSET, FLOOR_DETAIL_TOP))
            if (not floor_work and mn[2] < GATE_CLEAR_H and mn[0] < GATE_CLEAR_V and mx[0] > -GATE_CLEAR_V
                    and mx[1] > D + GATE_CLEAR_U[0] and mn[1] < D + GATE_CLEAR_U[1]):
                problems.append("%s: blocks the gate passage (|v| < %g below h %g)" % (tag, GATE_CLEAR_V, GATE_CLEAR_H))
            for name, (a, b) in keep_out:
                if all(mn[k] < b[k] - 0.02 and mx[k] > a[k] + 0.02 for k in range(3)):
                    problems.append("%s: touches the %s" % (tag, name))
            # near a corner nothing reaches more than CORNER_REACH past either fence line
            near_side = mx[0] > Wd - 3 or mn[0] < -Wd + 3
            near_end = mx[1] > D - 3 or mn[1] < -D + 3
            if near_end and (mx[0] > Wd + CORNER_REACH + eps or mn[0] < -Wd - CORNER_REACH - eps):
                problems.append("%s: corner work reaches more than %g past the side fence" % (tag, CORNER_REACH))
            if near_side and mx[1] > D + CORNER_REACH + eps:
                problems.append("%s: corner work reaches more than %g past the front fence" % (tag, CORNER_REACH))
        if FLOOR_ROLE in roles:
            want_mn, want_mx = (-Wd, -D, 0.0), (Wd, D, FLOOR_TOP)
            if any(abs(floor_mn[k] - want_mn[k]) > 0.01 or abs(floor_mx[k] - want_mx[k]) > 0.01 for k in range(3)):
                problems.append("%s must span exactly v -W..W, u -D..D, h 0..%g (got %s..%s)" % (FLOOR_ROLE, FLOOR_TOP, fmt(floor_mn), fmt(floor_mx)))
        sb = self.role_bounds(SCREEN_ROLE)
        if sb:
            cv = (sb[0][0] + sb[1][0]) / 2
            if abs(cv - (SIGN_V[0] + SIGN_V[1]) / 2) > 0.1 or sb[0][1] < D + SIGN_U[0] - 0.4 or sb[1][1] > D + FRONT_MAX:
                problems.append("%s must frame the PlotUpgrade sign (centre v %.2f, u D+%.2f..D+%.2f)" % (
                    SCREEN_ROLE, (SIGN_V[0] + SIGN_V[1]) / 2, SIGN_U[0] - 0.4, FRONT_MAX))
        if len(self.lights) > MAX_LIGHTS:
            problems.append("lights are gone from the bases (owner 2026-09-25): %d found" % len(self.lights))
        for role, lk in self.theme.PALETTE.items():
            if getattr(lk, "material", None) in BANNED_MATERIALS:
                problems.append("PALETTE[%r]: %s" % (role, BANNED_MATERIALS[lk.material]))
        for plot in plots or []:
            if abs(plot["half_depth"] - D) > 0.5 or abs(plot["half_width"] - Wd) > 0.5:
                continue
            for role, mn, mx, mod in self.pieces:
                for label, a, b in plot["obstacles"]:
                    if all(mn[k] < b[k] and mx[k] > a[k] for k in range(3)):
                        problems.append("plot %s: %s %s %s..%s touches %s" % (plot["plot"], mod, role, fmt(mn), fmt(mx), label))
                        break
        return problems

    def role_bounds(self, role):
        boxes = [(mn, mx) for r, mn, mx, _ in self.pieces if r == role]
        if not boxes:
            return None
        return ([min(b[0][k] for b in boxes) for k in range(3)], [max(b[1][k] for b in boxes) for k in range(3)])


def fmt(v):
    return "(%.2f, %.2f, %.2f)" % tuple(v)


# ----------------------------------------------------------------------------------------------------------------------
# the theme base class: the module order; the perimeter modules have no default (every theme draws its own)
# ----------------------------------------------------------------------------------------------------------------------

OWN_MODULES = ("span", "post", "corner", "gate_pylon", "gate_lintel", "emblem")


class PenTheme:
    KEY = None          # Directory.BaseThemes key: "Forest" | "Lake" | "Desert" | "Jungle" | "Snow" | "Volcano"
    NAME = None         # file stem (CamelCase, no spaces): <NAME>.fbx / .json / .rbxm, the Studio model name
    TITLE = None        # display name ("Stark Lab")
    FRANCHISE = None
    PALETTE = {}

    TILES = {"Std": (7, 7), "Deep": (7, 8)}
    # the front-right stretch the terminal module owns (the runs stop there, its span gets no module): v range
    TERMINAL_GAP = (SIGN_V[0] - 0.9, SIGN_V[1] + 0.9)
    EMBLEM_Z = 9.6      # emblem centre height (its lowest point must stay above 7.5 over the passage)
    EMBLEM_OUT = 1.3    # emblem plane distance outside the front fence line
    # terminal housing around the sign (terminal frame x = v - 10.435, y = u - (D + 1.48))
    TERMINAL_TOP = SIGN_H[1] + 0.62
    TERMINAL_HALF_V = (SIGN_V[1] - SIGN_V[0]) / 2 + 0.56

    # the studio render: the floor tint under the pen (presentation only, never exported)
    STUDIO_RGB = (208, 214, 224)

    # the tri budget ceiling of this theme: TRI_MAX, or (a landmark theme that truly needs it) TRI_STRETCH <= 10000 with
    # a TRI_STRETCH_REASON that run.py prints and the JSON records
    TRI_STRETCH = None
    TRI_STRETCH_REASON = None

    def build(self, B):
        with B.module("floor"):
            self.floor(B)
        with B.module("centerpiece"):
            self.centerpiece(B)
        with B.module("fence"):
            self.fence(B)
        with B.module("gate"):
            self.gate(B)
        with B.module("terminal"):
            self.terminal(B)
        with B.module("landmark"), B.zone(ZONE_LANDMARK), B.frame(B.landmark_frame()):
            self.landmark(B)

    def tri_max(self):
        """This theme's evaluated-tri ceiling per variant (TRI_MAX, or its TRI_STRETCH up to TRI_STRETCH_MAX)."""
        if self.TRI_STRETCH:
            return int(min(max(self.TRI_STRETCH, TRI_MAX), TRI_STRETCH_MAX))
        return TRI_MAX

    # -- landmark (LANDMARK_KEYS themes only) -------------------------------------------------------------------------
    def landmark(self, B):
        """The landmark building behind the pen (Lake / Desert / Jungle): drawn in B.landmark_frame() (X = -v, +Y away
        from the pen, Z up), in the zone 1.3 .. 24 studs behind the back fence line, |v| <= W+2, h <= 34. Default:
        none (Forest, Snow and Volcano keep their plots open)."""
        pass

    # -- floor -----------------------------------------------------------------------------------------------------
    def floor(self, B):
        nx, ny = self.TILES[B.variant]
        B.tiles(FLOOR_ROLE, -B.W, -B.D, B.W, B.D, nx, ny)

    def centerpiece(self, B):
        pass

    # -- perimeter -------------------------------------------------------------------------------------------------
    def fence(self, B):
        for side, s0, s1 in B.runs(self.TERMINAL_GAP):
            with B.module("run"), B.frame(B.side_frame(side, (s0 + s1) / 2)):
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

    def rail_run(self, B, side, L):
        pass

    def span(self, B, side, L, s0, s1):
        raise NotImplementedError("%s: model your own perimeter span (no shared fence)" % type(self).__name__)

    def post(self, B, post):
        raise NotImplementedError("%s: model your own post" % type(self).__name__)

    def corner(self, B):
        raise NotImplementedError("%s: model your own corner" % type(self).__name__)

    # -- gate ------------------------------------------------------------------------------------------------------
    def gate(self, B):
        for side in (-1, 1):
            with B.module("gate pylon"), B.frame(B.pylon_frame(side)):
                self.gate_pylon(B, side)
        with B.module("gate lintel"), B.frame(B.gate_frame()):
            self.gate_lintel(B)
        with B.module("emblem"), B.frame(B.emblem_frame(self.EMBLEM_Z, self.EMBLEM_OUT)):
            self.emblem(B)

    def gate_pylon(self, B, side):
        raise NotImplementedError("%s: model your own gate pylon" % type(self).__name__)

    def gate_lintel(self, B):
        raise NotImplementedError("%s: model your own gate lintel" % type(self).__name__)

    def emblem(self, B):
        raise NotImplementedError("%s: model your own 3D emblem (B.relief / B.relief_disc)" % type(self).__name__)

    # -- terminal --------------------------------------------------------------------------------------------------
    def terminal(self, B, housing="Structure_Housing"):
        """A plain housing around the functional PlotUpgrade sign (a back plate closing TERMINAL_GAP on the fence line,
        frame bars, the Neon_Emissive_Screen accent bezel, non-emissive), for a theme to restyle; `housing` = the role (in
        PALETTE)."""
        D = B.D
        g0, g1 = self.TERMINAL_GAP
        # the back plate: the barrier of this stretch, clear of the sign's plinth (u >= D + 0.49)
        B.slab(housing, (g0 - 0.05, D - 0.6, 0.0), (g1 + 0.05, D + 0.44, SIGN_H[1] + 0.62), open="-z")
        u0, u1 = D + SIGN_U[0] - 0.12, D + SIGN_U[1] + 0.14
        v0, v1 = SIGN_V[0] - 0.56, SIGN_V[1] + 0.56
        h0, h1 = SIGN_H[0] - 0.46, SIGN_H[1] + 0.62
        bar = 0.46
        du, uc = u1 - u0, (u0 + u1) / 2
        B.box(housing, ((v0 + v1) / 2, uc, h1 - (bar + 0.1) / 2), (v1 - v0, du, bar + 0.1))
        for vc in (v0 + bar / 2, v1 - bar / 2):
            B.box(housing, (vc, uc, h1 / 2), (bar, du, h1), open="-z")
        self.screen_bezel(B)

    def screen_bezel(self, B, t=0.14, depth=0.16, gap=0.04):
        """The Neon_Emissive_Screen bezel: four accent bars (non-emissive) hugging the sign's front face outline (never
        over its screen)."""
        D = B.D
        u = D + SIGN_U[1] + gap + depth / 2
        v0, v1 = SIGN_V[0] - gap - t, SIGN_V[1] + gap + t
        h0, h1 = SIGN_H[0] - gap - t, SIGN_H[1] + gap + t
        B.box(SCREEN_ROLE, ((v0 + v1) / 2, u, h1 - t / 2), (v1 - v0, depth, t))
        B.box(SCREEN_ROLE, ((v0 + v1) / 2, u, h0 + t / 2), (v1 - v0, depth, t))
        for v in (v0 + t / 2, v1 - t / 2):
            B.box(SCREEN_ROLE, (v, u, (h0 + h1) / 2), (t, depth, h1 - h0 - 2 * t))

    # -- render / view context (never exported) ----------------------------------------------------------------------
    def preview_extras(self):
        """Extra render-only boxes: [(name, rgb, center, size)] in the pen frame of the Std variant."""
        return []
