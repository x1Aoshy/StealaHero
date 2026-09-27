#!/usr/bin/env python3
"""Previews of the owner's weapon FBX models (assets/hero_weapons/fbx/weapons/*.fbx) held the way their kit holds them
(HeroWeaponTools: RightGrip C0 = identity, C1 = GripFromHand:Inverse(), GripFromHand = gripRotations[id] * the model
origin -> Handle), posed on the owner's attack clips. Checks the Studio-import path before the owner imports.
Writes assets/hero_weapons/previews/fbx_<WeaponId>.png.   Run: python3 scripts/tools/hero_weapons/render_fbx_weapons.py
"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fbx_inspect as F  # noqa: E402
import render_weapons as R  # noqa: E402
from rig import ROOT, clip_poses, load_rig, pose_rig, rot_x, cf  # noqa: E402

GRIP_ROTATIONS = {"Mjolnir": rot_x(-90), "PowerPole": rot_x(-90), "PowerPole_GoldToy": rot_x(-90), "CapShield": rot_x(-90),
                  "WebShooter": np.eye(3), "GomuFist": rot_x(180), "Batarang": rot_x(-90), "Bakugo_Gauntlet": np.eye(3)}
CLIP_OF = {"CapShield": "Shield_Bash", "PowerPole": "Pole_Strike", "PowerPole_GoldToy": "Pole_Strike",
           "WebShooter": "Web_Shoot", "Batarang": "Batarang_Throw", "Bakugo_Gauntlet": "Gauntlet_Blast",
           "Mjolnir": "Mjolnir_Slam", "GomuFist": "Gomu_Pistol"}
PALETTE = {"red": (200, 30, 36), "blue": (30, 60, 160), "silver": (196, 202, 212), "steel": (45, 48, 56), "metal": (150, 156, 168),
           "leather": (104, 64, 38), "brass": (214, 160, 60), "ink": (20, 20, 24), "edge": (70, 72, 80), "grip": (50, 50, 56),
           "matte": (28, 28, 34), "olive_light": (110, 128, 90), "olive": (70, 86, 60), "groove": (40, 44, 38), "orange": (255, 124, 20),
           "skin": (250, 200, 158), "shadow": (220, 160, 120), "gold_energy": (255, 170, 60), "gold": (255, 190, 40),
           "forged": (128, 134, 146), "inlay": (88, 94, 106), "neon": (236, 248, 255)}


def colour(material_name):
    name = material_name.lower()
    for key in sorted(PALETTE, key=len, reverse=True):
        if key in name:
            return PALETTE[key]
    return (180, 180, 180)


def weapon_mesh(path):
    sc = F.Scene(path)
    tris_all, cols = [], []
    for oid, o in sc.models():
        if len(o.props) > 2 and o.props[2] == "Mesh":
            tris, _ = sc.mesh_triangles(oid)
            if tris is None or not len(tris):
                continue
            mats = sc.materials_of(oid)
            c = colour(mats[0].props[1].split("\x00")[0] if mats else "")
            tris_all.append(tris)
            cols += [c] * len(tris)
    return np.concatenate(tris_all), cols


def main():
    parts, joints = load_rig()
    out_dir = os.path.join(ROOT, "assets", "hero_weapons", "previews")
    for wid, clip in CLIP_OF.items():
        path = os.path.join(ROOT, "assets", "hero_weapons", "fbx", "weapons", wid + ".fbx")
        tris, cols = weapon_mesh(path)
        views = []
        alone = [(t[0], t[1], t[2], c) for t, c in zip(tris, cols)]
        pts = tris.reshape(-1, 3)
        centre = (pts.min(0) + pts.max(0)) / 2
        radius = max(np.linalg.norm(pts.max(0) - pts.min(0)) / 2, 0.8)
        views.append(R.label(R.render(alone, centre + np.array([0.9, 0.55, -1.0]) * radius * 2.6, centre), wid + " FBX"))
        poses, _ = clip_poses(clip)
        for t, transforms, is_impact in [poses[0]] + [p for p in poses if p[2]]:
            world = pose_rig(parts, joints, transforms)
            m = world["RightHand"] @ cf(rot=GRIP_ROTATIONS[wid])
            posed = [tuple((m[:3, :3] @ v) + m[:3, 3] for v in tri) + (c,) for tri, c in zip(tris, cols)]
            views.append(R.label(R.render(R.rig_triangles(parts, world) + posed, (7.5, 6.5, -11), (0.3, 2.8, -1.5), fov=40),
                                 f"{clip} {'IMPACT' if is_impact else 'rest'}"))
        sheet = Image.new("RGB", (R.SIZE * len(views), R.SIZE), (255, 255, 255))
        for i, v in enumerate(views):
            sheet.paste(v, (i * R.SIZE, 0))
        sheet.save(os.path.join(out_dir, "fbx_" + wid + ".png"))
        print("preview fbx_" + wid, len(tris), "tris")


if __name__ == "__main__":
    main()
