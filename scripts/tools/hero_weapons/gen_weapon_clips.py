#!/usr/bin/env python3
"""Converts the owner's hero weapon attack animations (assets/hero_weapons/animations/<Clip>.rbxmx, R15
KeyframeSequences, 60 fps) into hero clip Format 1 modules (ReplicatedStorage.Library.Modules.HeroClipMath):

    src/ReplicatedStorage/Directory/WeaponAnimations/<WeaponId>.luau

No animation asset is uploaded: StarterPlayerScripts.BranchControllers.HeroWeaponController plays these keys on the
attacker's Motor6D.Transform. A KeyframeSequence Pose.CFrame IS the Transform of the Motor6D whose Part1 is the pose's
name (the HumanoidRootPart pose is the root and is skipped). Keys are thinned with a Douglas-Peucker pass per joint
(QUAT_TOL / POS_TOL), keeping every "Impact" keyframe exactly: the server resolves the hit at that time.

Lune cannot read these files (the XML declaration is `<?xml version='1.0' encoding='utf-8'?>`), hence Python.
Run:  python3 scripts/tools/hero_weapons/gen_weapon_clips.py
"""
import math
import os
import xml.etree.ElementTree as ET

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..")
SRC_DIR = os.path.join(ROOT, "assets", "hero_weapons", "animations")
OUT_DIR = os.path.join(ROOT, "src", "ReplicatedStorage", "Directory", "WeaponAnimations")

# clip file -> weapon id (keep in sync with HeroWeapons.WEAPONS in src/ReplicatedStorage/Library/Modules/HeroWeapons.luau).
# Round 9 (owner 2026-09-27): Mjolnir, the Power Pole, Cap's shield, the batarang and the web shooter play the clips
# authored in author_weapon_clips.py (the jump slam, the spin sweep, the aimed throws), round 10 Luffy's fist too;
# their rbxmx stay in the assets.
CLIPS = {
    "Gauntlet_Blast": "BakugoGauntlet",
}  # round 10: Luffy's long Gum-Gum Pistol is authored too (author_weapon_clips.py)

# R15 pose (Part1) name -> Motor6D name
JOINT_OF_POSE = {
    "LowerTorso": "Root", "UpperTorso": "Waist", "Head": "Neck",
    "LeftUpperArm": "LeftShoulder", "LeftLowerArm": "LeftElbow", "LeftHand": "LeftWrist",
    "RightUpperArm": "RightShoulder", "RightLowerArm": "RightElbow", "RightHand": "RightWrist",
    "LeftUpperLeg": "LeftHip", "LeftLowerLeg": "LeftKnee", "LeftFoot": "LeftAnkle",
    "RightUpperLeg": "RightHip", "RightLowerLeg": "RightKnee", "RightFoot": "RightAnkle",
}
JOINT_ORDER = ["Root", "Waist", "Neck", "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow",
               "RightWrist", "LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle"]

QUAT_TOL = 0.0025  # quaternion component (~0.3 degrees)
POS_TOL = 0.004  # studs


def prop(item, kind, name):
    props = item.find("Properties")
    node = props.find(f"{kind}[@name='{name}']") if props is not None else None
    return node


def matrix_to_quat(r):
    (r00, r01, r02), (r10, r11, r12), (r20, r21, r22) = r
    trace = r00 + r11 + r22
    if trace > 0:
        s = math.sqrt(trace + 1.0) * 2
        w, x, y, z = 0.25 * s, (r21 - r12) / s, (r02 - r20) / s, (r10 - r01) / s
    elif r00 > r11 and r00 > r22:
        s = math.sqrt(1.0 + r00 - r11 - r22) * 2
        w, x, y, z = (r21 - r12) / s, 0.25 * s, (r01 + r10) / s, (r02 + r20) / s
    elif r11 > r22:
        s = math.sqrt(1.0 + r11 - r00 - r22) * 2
        w, x, y, z = (r02 - r20) / s, (r01 + r10) / s, 0.25 * s, (r12 + r21) / s
    else:
        s = math.sqrt(1.0 + r22 - r00 - r11) * 2
        w, x, y, z = (r10 - r01) / s, (r02 + r20) / s, (r12 + r21) / s, 0.25 * s
    m = math.sqrt(x * x + y * y + z * z + w * w)
    return [x / m, y / m, z / m, w / m]


def read_cframe(pose):
    cf = prop(pose, "CoordinateFrame", "CFrame")
    v = {c.tag: float(c.text) for c in cf}
    rot = ((v["R00"], v["R01"], v["R02"]), (v["R10"], v["R11"], v["R12"]), (v["R20"], v["R21"], v["R22"]))
    return matrix_to_quat(rot) + [v["X"], v["Y"], v["Z"]]


def parse(path):
    root = ET.parse(path).getroot()
    seq = root.find("Item[@class='KeyframeSequence']")
    keyframes = []
    impact = None
    for kf in seq.findall("Item[@class='Keyframe']"):
        t = float(prop(kf, "float", "Time").text)
        name = prop(kf, "string", "Name").text
        if name == "Impact" and impact is None:
            impact = t
        poses = {}
        for pose in kf.iter("Item"):
            if pose.get("class") != "Pose":
                continue
            joint = JOINT_OF_POSE.get(prop(pose, "string", "Name").text)
            if joint:
                poses[joint] = read_cframe(pose)
        keyframes.append((t, poses))
    keyframes.sort(key=lambda k: k[0])
    return keyframes, impact


def interp_error(keys, a, b):
    """Largest deviation of keys a+1..b-1 from the straight lerp between keys a and b (-1 if none)."""
    ta, va = keys[a]
    tb, vb = keys[b]
    worst, where = -1.0, -1
    for i in range(a + 1, b):
        t, v = keys[i]
        f = (t - ta) / (tb - ta)
        q = [va[c] + (vb[c] - va[c]) * f for c in range(4)]
        m = math.sqrt(sum(c * c for c in q)) or 1
        err_q = max(abs(q[c] / m - v[c]) for c in range(4)) / QUAT_TOL
        err_p = max(abs(va[c] + (vb[c] - va[c]) * f - v[c]) for c in range(4, 7)) / POS_TOL
        err = max(err_q, err_p)
        if err > worst:
            worst, where = err, i
    return worst, where


def thin(keys, pinned):
    keep = {0, len(keys) - 1} | pinned
    stack = sorted(keep)
    segments = list(zip(stack[:-1], stack[1:]))
    while segments:
        a, b = segments.pop()
        if b - a < 2:
            continue
        err, where = interp_error(keys, a, b)
        if err > 1:
            keep.add(where)
            segments.append((a, where))
            segments.append((where, b))
    return [keys[i] for i in sorted(keep)]


def fmt(x):
    s = f"{x:.5f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def build(clip, weapon):
    keyframes, impact = parse(os.path.join(SRC_DIR, clip + ".rbxmx"))
    assert impact is not None, clip + " has no Impact keyframe"
    length = keyframes[-1][0]
    tracks = {}
    raw_keys = 0
    for joint in JOINT_ORDER:
        keys = []
        previous = None
        for t, poses in keyframes:
            v = poses.get(joint)
            if v is None:
                continue
            v = list(v)
            if previous is not None and sum(v[c] * previous[c] for c in range(4)) < 0:
                v[:4] = [-c for c in v[:4]]  # same hemisphere as the previous key: the lerp takes the short way
            previous = v
            keys.append((t, v))
        if not keys:
            continue
        raw_keys += len(keys)
        pinned = {i for i, (t, _) in enumerate(keys) if abs(t - impact) < 1e-6}
        keys = thin(keys, pinned)
        if all(max(abs(v[c] - (1 if c == 3 else 0)) for c in range(7)) < 1e-4 for _, v in keys):
            continue  # a joint the clip never moves stays with the Animator
        tracks[joint] = keys
    kept = sum(len(k) for k in tracks.values())
    lines = [
        f"-- ReplicatedStorage.Directory.WeaponAnimations.{weapon} (GENERATED - do not edit by hand)",
        f"-- From the owner's assets/hero_weapons/animations/{clip}.rbxmx by scripts/tools/hero_weapons/gen_weapon_clips.py",
        "-- (KeyframeSequence poses -> Motor6D.Transform keys, hero clip Format 1, ReplicatedStorage.Library.Modules.HeroClipMath).",
        "-- Played on the attacker by StarterPlayerScripts.BranchControllers.HeroWeaponController; the server",
        "-- (GearService) resolves the hit at Impact seconds. Keys: { time, easing, qx, qy, qz, qw, px, py, pz }.",
        "",
        "return {",
        "\tFormat = 1,",
        f"\tWeaponId = \"{weapon}\",",
        f"\tClip = \"{clip}\",",
        f"\tLength = {fmt(length)},",
        f"\tImpact = {fmt(impact)},",
        "\tLoop = false,",
        "\tTracks = {",
    ]
    for joint in JOINT_ORDER:
        keys = tracks.get(joint)
        if not keys:
            continue
        body = ", ".join(
            "{ " + ", ".join([fmt(t), "\"linear\""] + [fmt(c) for c in v]) + " }" for t, v in keys
        )
        lines.append(f"\t\t{joint} = {{ {body} }},")
    lines += ["\t},", "}", ""]
    with open(os.path.join(OUT_DIR, weapon + ".luau"), "w", newline="\n") as f:
        f.write("\n".join(lines))
    print(f"{clip:15s} -> {weapon:15s} length {length:.3f}s impact {impact:.3f}s, {len(tracks)} joints, "
          f"{kept}/{raw_keys} keys kept")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for clip, weapon in CLIPS.items():
        build(clip, weapon)


if __name__ == "__main__":
    main()
