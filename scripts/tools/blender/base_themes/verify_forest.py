"""Verify the delivered Stark Lab FBX and its fit against the actual saved stage.

    blender --background --factory-startup --python-exit-code 1 \
        --python scripts/tools/blender/base_themes/verify_forest.py [-- --obstacles <plot_obstacles.json> ...]

Checks (both variants): the pen contract + every plot's obstacles with zero margin (the base_themes
plot_obstacles.json, the current-stage file saved next to the Volcano theme and any --obstacles file given), the
6000..9000 triangle budget, the exported FBX (object count, triangles, custom normals, no degenerate triangles) and
two assembly checks from the polish pass (2026-09-25): no piece floats (every piece above the floor rests on, or is
embedded in, another piece or the ground) and no two pieces share a coplanar outer face (z-fighting in Roblox).
"""
import json
import os
import sys
import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True
import common as C  # noqa: E402
import pipeline as P  # noqa: E402
from themes.forest import THEME  # noqa: E402

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.join(P.BASES_DIR, "Forest")
GROUND = 0.005     # a piece whose bottom is at most this high stands on the ground
CONTACT = 0.004    # studs: boxes this close count as touching (bevels embed the real contact)
COPLANAR = 0.004   # studs: same-side faces closer than this, overlapping in area, z-fight


def obstacle_sets():
    paths = [P.OBSTACLES_PATH, os.path.join(P.BASES_DIR, "Volcano", "reference", "current-stage-obstacles.json")]
    for i, a in enumerate(ARGV):
        if a == "--obstacles" and i + 1 < len(ARGV):
            paths.append(os.path.abspath(ARGV[i + 1]))
    out = []
    for path in paths:
        if os.path.isfile(path):
            with open(path, encoding="utf-8") as fh:
                out.append((path, json.load(fh)["plots"]))
    return out


def touching(a, b, tol=CONTACT):
    return all(a[1][k] < b[2][k] + tol and a[2][k] > b[1][k] - tol for k in range(3))


def floating_pieces(B):
    """Pieces above the ground touching no other piece (bounding boxes; the glass panes and logos count too)."""
    pieces = [(role, mn, mx, mod) for role, mn, mx, mod in B.pieces]
    bad = []
    for i, p in enumerate(pieces):
        if p[1][2] <= GROUND:
            continue
        if not any(i != j and touching(p, q) for j, q in enumerate(pieces)):
            bad.append("%s %s %s..%s" % (p[3], p[0], C.fmt(p[1]), C.fmt(p[2])))
    return bad


def _covers(q, k, c, rect, o, inside):
    """Piece q covers the rectangle `rect` (over axes o) at coordinate c on axis k: strictly inside (a hidden face)
    or with its own face on c (a face resting on q)."""
    if not all(q[1][m] <= rect[n][0] + 1e-4 and q[2][m] >= rect[n][1] - 1e-4 for n, m in enumerate(o)):
        return False
    if inside:
        return q[1][k] < c - 0.005 and q[2][k] > c + 0.005
    return True


def coplanar_faces(B):
    """Pairs of pieces whose outer faces lie in one plane and overlap in area (a z-fight in Roblox), unless a third
    piece hides that overlap or the faces rest on another piece (a bottom on a plinth, a logo's back on its wall)."""
    pieces = B.pieces
    bad = []
    for i in range(len(pieces)):
        ri, ai, bi, mi = pieces[i]
        if ri == C.FLOOR_ROLE:
            continue
        for j in range(i + 1, len(pieces)):
            rj, aj, bj, mj = pieces[j]
            if rj == C.FLOOR_ROLE:
                continue
            for k in range(3):
                o = [m for m in range(3) if m != k]
                rect = [(max(ai[m], aj[m]), min(bi[m], bj[m])) for m in o]
                if not all(hi - lo > 0.02 for lo, hi in rect):
                    continue
                for side, vi, vj in (("min", ai[k], aj[k]), ("max", bi[k], bj[k])):
                    if abs(vi - vj) >= COPLANAR or (k == 2 and side == "min" and vi <= 0.105):
                        continue
                    c = (vi + vj) / 2
                    hidden = False
                    for n, q in enumerate(pieces):
                        if n in (i, j):
                            continue
                        rest = abs((q[2][k] if side == "min" else q[1][k]) - c) < COPLANAR
                        if _covers(q, k, c, rect, o, True) or (rest and _covers(q, k, c, rect, o, False)):
                            hidden = True
                            break
                    if not hidden:
                        bad.append("%s %s / %s %s share the %s%s face at %.3f" % (mi, ri, mj, rj, side, "xyz"[k], c))
    return bad


problems = []
report = {"current_stage_obstacles": True, "studio_play_test": False, "obstacle_files": [], "variants": {}}
builders = None
for path, plots in obstacle_sets():
    builders, found = P.build_theme(THEME, plots)
    rel = P.rel(path)
    report["obstacle_files"].append(rel if not rel.startswith("..") else "external:" + os.path.basename(path))
    for vname, probs in found.items():
        problems += ["%s (%s): %s" % (vname, os.path.basename(path), p) for p in probs]
assert builders is not None, "no obstacle file found"
assembly = {}
for vname, B in builders.items():
    floating, coplanar = floating_pieces(B), coplanar_faces(B)
    assembly[vname] = (floating, coplanar)
    problems += ["%s: floating %s" % (vname, p) for p in floating]
    problems += ["%s: coplanar %s" % (vname, p) for p in coplanar]
layout = json.load(open(os.path.join(OUT, "StarkLab.json"), encoding="utf-8"))
P.clear_scene()
bpy.ops.import_scene.fbx(filepath=os.path.join(OUT, "StarkLab.fbx"), use_custom_normals=True)
for name, variant in layout["variants"].items():
    objects = [o for o in bpy.context.scene.objects if o.type == "MESH" and o.name.startswith(variant["prefix"])]
    tris = sum(P.mesh_stats(o)[0] for o in objects)
    if tris != variant["total_tris"] or len(objects) != variant["objects"]:
        problems.append("%s: FBX has %d tris / %d objects, JSON says %d / %d" % (
            name, tris, len(objects), variant["total_tris"], variant["objects"]))
    if not (C.TRI_MIN <= tris <= C.TRI_MAX):
        problems.append("%s: %d tris outside %d..%d" % (name, tris, C.TRI_MIN, C.TRI_MAX))
    if not all(o.data.has_custom_normals for o in objects):
        problems.append("%s: an object lost its custom normals" % name)
    bad = sum(p.area < 1e-10 for o in objects for p in o.data.polygons)
    if bad:
        problems.append("%s: %d degenerate triangles" % (name, bad))
    if variant["problems"] or variant["plot_problems"]:
        problems.append("%s: the exported JSON lists problems (%s)" % (name, (variant["problems"] + variant["plot_problems"])[:3]))
    floating, coplanar = assembly.get(name, ([], []))
    report["variants"][name] = {"triangles": tris, "objects": len(objects), "custom_normals": True,
                                "degenerate_triangles": bad, "problems": variant["problems"],
                                "plot_problems": variant["plot_problems"], "plots": variant.get("plots", {}),
                                "floating_pieces": len(floating), "coplanar_faces": len(coplanar)}
report["ok"] = not problems
with open(os.path.join(OUT, "reference", "validation.json"), "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2)
for p in problems[:60]:
    print("[StarkLab] !!", p, flush=True)
assert not problems, "%d problems" % len(problems)
print("[StarkLab] FBX, contract, stage fit and assembly verified:", report, flush=True)
