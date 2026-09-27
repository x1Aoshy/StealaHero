#!/usr/bin/env python3
"""Software previews of assets/hero_weapons/weapon_models.json (numpy + Pillow, no Blender): each weapon alone and in
the owner's attack clip on the block R15 rig (rest pose and the Impact keyframe), so the grip orientation is checked
against the animations before a build. Writes assets/hero_weapons/previews/<WeaponId>.png and contact_sheet.png.

Run:  python3 scripts/tools/hero_weapons/weapon_models.py --render
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from rig import GRIP_ATTACHMENT, ROOT, clip_poses, from_components, load_rig, pose_rig  # noqa: E402

PREVIEW_DIR = os.path.join(ROOT, "assets", "hero_weapons", "previews")
CLIP_OF = {"CapShield": "Shield_Bash", "PowerPole": "Pole_Strike", "WebShooter": "Web_Shoot",
           "Batarang": "Batarang_Throw", "BakugoGauntlet": "Gauntlet_Blast", "Mjolnir": "Mjolnir_Slam",
           "GomuFist": "Gomu_Pistol"}
SIZE = 420
LIGHT = np.array([0.45, 0.8, -0.4])
LIGHT = LIGHT / np.linalg.norm(LIGHT)


def box_mesh():
    v = np.array([[x, y, z] for x in (-.5, .5) for y in (-.5, .5) for z in (-.5, .5)])
    quads = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    tris = []
    for a, b, c, d in quads:
        tris += [(a, b, c), (a, c, d)]
    return v, tris


def wedge_mesh():
    # WedgePart: bottom face, back face (+Z), slope from the top-back edge to the bottom-front edge
    v = np.array([[-.5, -.5, -.5], [.5, -.5, -.5], [-.5, -.5, .5], [.5, -.5, .5], [-.5, .5, .5], [.5, .5, .5]])
    tris = [(0, 2, 3), (0, 3, 1), (2, 4, 5), (2, 5, 3), (0, 1, 5), (0, 5, 4), (0, 4, 2), (1, 3, 5)]
    return v, tris


def cylinder_mesh(n=20):
    v = []
    for x in (-.5, .5):
        for k in range(n):
            a = 2 * math.pi * k / n
            v.append([x, .5 * math.cos(a), .5 * math.sin(a)])
    v.append([-.5, 0, 0])
    v.append([.5, 0, 0])
    tris = []
    for k in range(n):
        k2 = (k + 1) % n
        tris += [(k, k2, n + k2), (k, n + k2, n + k), (2 * n, k2, k), (2 * n + 1, n + k, n + k2)]
    return np.array(v), tris


def ball_mesh(nu=16, nv=10):
    v = []
    for i in range(nv + 1):
        th = math.pi * i / nv
        for j in range(nu):
            ph = 2 * math.pi * j / nu
            v.append([.5 * math.sin(th) * math.cos(ph), .5 * math.cos(th), .5 * math.sin(th) * math.sin(ph)])
    tris = []
    for i in range(nv):
        for j in range(nu):
            a, b = i * nu + j, i * nu + (j + 1) % nu
            c, d = a + nu, b + nu
            tris += [(a, c, d), (a, d, b)]
    return np.array(v), tris


MESHES = {"Block": box_mesh(), "Wedge": wedge_mesh(), "Cylinder": cylinder_mesh(), "Ball": ball_mesh()}


def part_triangles(shape, size, frame, color):
    verts, tris = MESHES[shape]
    size = np.array(size, dtype=float)
    if shape == "Cylinder":
        d = min(size[1], size[2])
        size = np.array([size[0], d, d])
    elif shape == "Ball":
        size = np.full(3, min(size))
    world = (frame[:3, :3] @ (verts * size).T).T + frame[:3, 3]
    return [(world[a], world[b], world[c], color) for a, b, c in tris]


def look_at(eye, target):
    eye, target = np.asarray(eye, float), np.asarray(target, float)
    back = eye - target
    back /= np.linalg.norm(back)
    right = np.cross([0, 1, 0], back)
    right /= np.linalg.norm(right)
    up = np.cross(back, right)
    return eye, np.array([right, up, back])


def render(triangles, eye, target, fov=38, size=SIZE, bg=(238, 242, 248)):
    eye, basis = look_at(eye, target)
    img = np.zeros((size, size, 3), dtype=np.float64)
    img[:] = bg
    zbuf = np.full((size, size), np.inf)
    f = (size / 2) / math.tan(math.radians(fov) / 2)
    for a, b, c, color in triangles:
        pts = np.array([basis @ (p - eye) for p in (a, b, c)])  # camera space, looking down -Z
        if np.any(pts[:, 2] > -0.05):
            continue
        normal = np.cross(b - a, c - a)
        n = np.linalg.norm(normal)
        if n < 1e-12:
            continue
        normal /= n
        to_eye = eye - (a + b + c) / 3
        if np.dot(normal, to_eye) < 0:
            normal = -normal  # two-sided
        shade = 0.42 + 0.58 * max(0.0, float(np.dot(normal, LIGHT)))
        rgb = np.array(color, dtype=float) * shade
        sx = size / 2 + f * pts[:, 0] / -pts[:, 2]
        sy = size / 2 - f * pts[:, 1] / -pts[:, 2]
        depth = -pts[:, 2]
        x0, x1 = int(max(0, math.floor(sx.min()))), int(min(size - 1, math.ceil(sx.max())))
        y0, y1 = int(max(0, math.floor(sy.min()))), int(min(size - 1, math.ceil(sy.max())))
        if x0 > x1 or y0 > y1:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        d = (sy[1] - sy[2]) * (sx[0] - sx[2]) + (sx[2] - sx[1]) * (sy[0] - sy[2])
        if abs(d) < 1e-9:
            continue
        w0 = ((sy[1] - sy[2]) * (xs - sx[2]) + (sx[2] - sx[1]) * (ys - sy[2])) / d
        w1 = ((sy[2] - sy[0]) * (xs - sx[2]) + (sx[0] - sx[2]) * (ys - sy[2])) / d
        w2 = 1 - w0 - w1
        inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
        z = w0 * depth[0] + w1 * depth[1] + w2 * depth[2]
        region = zbuf[y0:y1 + 1, x0:x1 + 1]
        mask = inside & (z < region)
        region[mask] = z[mask]
        img[y0:y1 + 1, x0:x1 + 1][mask] = rgb
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))


def weapon_triangles(weapon, palettes, grip_world):
    tris = []
    for p in weapon["Parts"]:
        frame = grip_world @ from_components(p["cframe"])
        tris += part_triangles(p["shape"], p["size"], frame, palettes[p["palette"]]["Color"])
    return tris


def rig_triangles(parts, world):
    tris = []
    colors = {"Head": (250, 214, 90), "UpperTorso": (60, 110, 200), "LowerTorso": (60, 110, 200)}
    for name, frame in world.items():
        if name == "HumanoidRootPart":
            continue
        color = colors.get(name, (120, 190, 110) if "Leg" in name or "Foot" in name else (250, 214, 90))
        tris += part_triangles("Block", parts[name]["size"], frame, color)
    return tris


def label(img, text):
    ImageDraw.Draw(img).text((8, 6), text, fill=(20, 20, 30))
    return img


def main(data=None):
    if data is None:
        with open(os.path.join(ROOT, "assets", "hero_weapons", "weapon_models.json")) as f:
            data = json.load(f)
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    parts, joints = load_rig()
    palettes = data["Palettes"]
    rows = []
    for weapon in data["Weapons"]:
        wid = weapon["WeaponId"]
        alone = weapon_triangles(weapon, palettes, np.eye(4))
        pts = np.array([t[0] for t in alone])
        centre = (pts.min(0) + pts.max(0)) / 2
        radius = max(np.linalg.norm(pts.max(0) - pts.min(0)) / 2, 0.8)
        views = [label(render(alone, centre + np.array([0.9, 0.55, -1.0]) * radius * 2.6, centre), wid + " (front)"),
                 label(render(alone, centre + np.array([-0.7, 0.5, 1.0]) * radius * 2.6, centre), wid + " (back)")]
        poses, _ = clip_poses(CLIP_OF[wid])
        for t, transforms, is_impact in [poses[0]] + [p for p in poses if p[2]]:
            world = pose_rig(parts, joints, transforms)
            grip = world["RightHand"] @ GRIP_ATTACHMENT
            tris = rig_triangles(parts, world) + weapon_triangles(weapon, palettes, grip)
            views.append(label(render(tris, (7.5, 6.5, -11), (0.3, 2.8, -1.5), fov=40),
                               f"{CLIP_OF[wid]} {'IMPACT' if is_impact else 'rest'} t={t:.2f}"))
            views.append(label(render(tris, (9.5, 4.0, 3.0), (0.3, 2.8, -1.5), fov=40), "side"))
        sheet = Image.new("RGB", (SIZE * len(views), SIZE), (255, 255, 255))
        for i, v in enumerate(views):
            sheet.paste(v, (i * SIZE, 0))
        sheet.save(os.path.join(PREVIEW_DIR, wid + ".png"))
        rows.append(sheet)
        print("preview", wid)
    contact = Image.new("RGB", (max(r.width for r in rows), SIZE * len(rows)), (255, 255, 255))
    for i, r in enumerate(rows):
        contact.paste(r, (0, i * SIZE))
    contact = contact.resize((contact.width // 2, contact.height // 2))
    contact.save(os.path.join(PREVIEW_DIR, "contact_sheet.png"))


if __name__ == "__main__":
    main()
