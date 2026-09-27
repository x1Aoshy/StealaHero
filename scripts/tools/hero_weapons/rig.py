"""Small CFrame / R15 forward-kinematics helpers for the hero weapon tools (previews, grip checks). numpy only.

CFrames are 4x4 numpy matrices. The rig is assets/animations/r15_rig.json (block R15 template, faces -Z); a pose is
{ Motor6D name: 4x4 Transform } (the KeyframeSequence poses), exactly how Roblox evaluates
Part1 = Part0 * C0 * Transform * C1:Inverse().
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..", "..")
sys.path.insert(0, HERE)

# Default R15 RightGripAttachment (RightHand space): the Tool.Grip is relative to it.
GRIP_ATTACHMENT = None  # filled below


def cf(x=0.0, y=0.0, z=0.0, rot=None):
    m = np.eye(4)
    m[:3, 3] = (x, y, z)
    if rot is not None:
        m[:3, :3] = rot
    return m


def from_components(c):
    m = np.eye(4)
    m[:3, 3] = c[0:3]
    m[:3, :3] = np.array(c[3:12]).reshape(3, 3)
    return m


def rot_x(deg):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def rot_y(deg):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def rot_z(deg):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def angles(rx=0.0, ry=0.0, rz=0.0):
    """CFrame.Angles(rx, ry, rz) in degrees (= Rx * Ry * Rz)."""
    return rot_x(rx) @ rot_y(ry) @ rot_z(rz)


def quat_pos(q):
    """(qx, qy, qz, qw, px, py, pz) -> 4x4."""
    x, y, z, w, px, py, pz = q
    rot = np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ])
    return cf(px, py, pz, rot)


GRIP_ATTACHMENT = cf(0, -0.15, 0, rot_x(-90))


def load_rig():
    with open(os.path.join(ROOT, "assets", "animations", "r15_rig.json")) as f:
        data = json.load(f)
    parts = {name: dict(p, cframe=from_components(p["cframe"])) for name, p in data["parts"].items()}
    joints = [dict(j, c0=from_components(j["c0"]), c1=from_components(j["c1"])) for j in data["joints"]]
    return parts, joints


def pose_rig(parts, joints, transforms, root=None):
    """World CFrames of every part for a pose { joint: 4x4 }. root: HumanoidRootPart world CFrame."""
    world = {"HumanoidRootPart": root if root is not None else parts["HumanoidRootPart"]["cframe"]}
    pending = list(joints)
    while pending:
        rest = []
        for j in pending:
            if j["part0"] in world:
                t = transforms.get(j["name"], np.eye(4))
                world[j["part1"]] = world[j["part0"]] @ j["c0"] @ t @ np.linalg.inv(j["c1"])
            else:
                rest.append(j)
        if len(rest) == len(pending):
            break
        pending = rest
    return world


def clip_poses(clip):
    """[(time, { joint: 4x4 }, is_impact)] from the owner's rbxmx (via the clip generator's parser)."""
    import gen_weapon_clips as gen
    keyframes, impact = gen.parse(os.path.join(gen.SRC_DIR, clip + ".rbxmx"))
    out = []
    for t, poses in keyframes:
        out.append((t, {j: quat_pos(v) for j, v in poses.items()}, abs(t - impact) < 1e-6))
    return out, impact
