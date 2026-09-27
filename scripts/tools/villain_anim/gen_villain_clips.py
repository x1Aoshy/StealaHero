#!/usr/bin/env python3
"""Generates the stage villains' procedural animation clips (owner 2026-09-27: "Frieza floats but has no float
animation; each boss must have its own unique attack and run when they chase you, and an idle as if distracted or
asleep").

Writes src/ReplicatedStorage/Directory/VillainAnimations/<Villain>.luau in the hero clip Format 1
(ReplicatedStorage.Library.Modules.HeroClipMath): Clips.<Name> = { Length, Loop, Speed?, Tracks = { <Motor6D> =
{ { time, easing, qx, qy, qz, qw [, px, py, pz] } } } }, played on the villains' Motor6D.Transform by
StarterPlayerScripts.Game.VillainClipPlayer. Poses are authored here as Euler degrees (CFrame.Angles order X, Y, Z) on
the R15 joints of the converted villain rigs (identity C0 rotations), Root positions in studs at rig scale 1.

Sign conventions (R15, character facing -Z):
  Root / Waist rx < 0 leans forward, Neck rx < 0 looks down, ry > 0 turns to the character's left;
  Shoulder rx > 0 raises the arm forward, RightShoulder rz > 0 / LeftShoulder rz < 0 lift the arm out sideways;
  Elbow rx > 0 bends the forearm up; Hip rx > 0 swings the thigh forward, Knee rx < 0 bends; Ankle rx > 0 toes up.

Clips per villain: Idle (loop, distracted / dozing at the post), Wake (one-shot alert), Move (loop, chase run),
Walk (loop, going home / carrying), Attack (one-shot, the catch hit). Run:  python3 scripts/tools/villain_anim/gen_villain_clips.py
"""
import math
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "..", "src", "ReplicatedStorage", "Directory", "VillainAnimations")
JOINTS = ["Root", "Waist", "Neck", "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow", "RightWrist",
          "LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle"]
MIRROR = {"Left": "Right", "Right": "Left"}


def quat(rx, ry, rz):
    """CFrame.Angles(rx, ry, rz) (= Rx * Ry * Rz) as x, y, z, w."""
    def axis(a, v):
        h = math.radians(a) / 2
        s = math.sin(h)
        return (v[0] * s, v[1] * s, v[2] * s, math.cos(h))

    def mul(a, b):
        ax, ay, az, aw = a
        bx, by, bz, bw = b
        return (aw * bx + ax * bw + ay * bz - az * by,
                aw * by - ax * bz + ay * bw + az * bx,
                aw * bz + ax * by - ay * bx + az * bw,
                aw * bw - ax * bx - ay * by - az * bz)
    q = mul(mul(axis(rx, (1, 0, 0)), axis(ry, (0, 1, 0))), axis(rz, (0, 0, 1)))
    if q[3] < 0:
        q = tuple(-c for c in q)
    return q


def mirror_pose(pose):
    """Left <-> right: swap sides, negate ry / rz (and the Root / Waist / Neck twist and tilt, and x offsets)."""
    out = {}
    for joint, v in pose.items():
        target = joint
        for a, b in MIRROR.items():
            if joint.startswith(a):
                target = b + joint[len(a):]
        v = list(v) + [0] * (6 - len(v))
        out[target] = (v[0], -v[1], -v[2], -v[3], v[4], v[5])
    return out


def merge(*poses):
    out = {}
    for p in poses:
        for k, v in p.items():
            out[k] = v
    return out


def clip(length, loop, frames, speed=None, easing="sine_inout"):
    """frames: [(t_fraction, pose)] or [(t_fraction, pose, easing)]; every joint used anywhere gets a track."""
    used = []
    for f in frames:
        for j in f[1]:
            if j not in used:
                used.append(j)
    tracks = {}
    for j in JOINTS:
        if j not in used:
            continue
        keys = []
        for f in frames:
            t = round(f[0] * length, 4)
            ease = f[2] if len(f) > 2 else easing
            v = list(f[1].get(j, (0, 0, 0))) + [0] * 6
            qx, qy, qz, qw = quat(v[0], v[1], v[2])
            key = [t, ease, round(qx, 5), round(qy, 5), round(qz, 5), round(qw, 5)]
            if j == "Root":
                key += [round(v[3], 3), round(v[4], 3), round(v[5], 3)]
            keys.append(key)
        tracks[j] = keys
    return {"Length": length, "Loop": loop, "Speed": speed, "Tracks": tracks}


def cycle(length, poses, speed=None, easing="sine_inout"):
    """A loop through evenly spaced poses, closing on the first one."""
    n = len(poses)
    frames = [(i / n, p) for i, p in enumerate(poses)] + [(1.0, poses[0])]
    return clip(length, True, frames, speed, easing)


def gait(base, hip, knee_back, knee_lift, arm, elbow, bob, lean_twist=6, sway=0, arms=True, legs=True):
    """Four poses of a run / walk cycle over `base` (the villain's carriage): right foot strike, passing, left foot
    strike, passing. Arms swing against the legs unless arms=False (the base keeps the arms)."""
    strike = {}
    passing = {}
    if legs:
        strike.update({"RightHip": (hip, 0, 0), "RightKnee": (-knee_back * 0.25, 0, 0), "RightAnkle": (10, 0, 0),
                       "LeftHip": (-hip * 0.7, 0, 0), "LeftKnee": (-knee_back, 0, 0), "LeftAnkle": (-15, 0, 0)})
        passing.update({"RightHip": (hip * 0.1, 0, 0), "RightKnee": (-knee_back * 0.35, 0, 0),
                        "LeftHip": (hip * 0.45, 0, 0), "LeftKnee": (-knee_lift, 0, 0), "LeftAnkle": (5, 0, 0)})
    if arms:
        strike.update({"LeftShoulder": (arm, 0, -6), "LeftElbow": (elbow, 0, 0),
                       "RightShoulder": (-arm * 0.8, 0, 6), "RightElbow": (elbow * 0.7, 0, 0)})
        passing.update({"LeftShoulder": (arm * 0.2, 0, -6), "LeftElbow": (elbow, 0, 0),
                        "RightShoulder": (-arm * 0.1, 0, 6), "RightElbow": (elbow, 0, 0)})
    r = base.get("Root", (0, 0, 0, 0, 0, 0))
    r = list(r) + [0] * (6 - len(r))
    w = list(base.get("Waist", (0, 0, 0))) + [0] * 3
    strike["Root"] = (r[0], r[1] + lean_twist * 0.4, r[2] + sway, r[3], r[4] - bob, r[5])
    passing["Root"] = (r[0], r[1], r[2], r[3], r[4] + bob, r[5])
    strike["Waist"] = (w[0], w[1] - lean_twist, w[2])
    passing["Waist"] = (w[0], w[1], w[2])
    a = merge(base, strike)
    b = merge(base, passing)
    return [a, b, merge(base, mirror_pose(strike)), merge(base, mirror_pose(passing))]


def breathe(pose, chest=2.5, lift=0.05):
    """Pose with an inhale: chest up a little, shoulders rise."""
    out = dict(pose)
    w = list(out.get("Waist", (0, 0, 0))) + [0] * 3
    out["Waist"] = (w[0] + chest, w[1], w[2])
    r = list(out.get("Root", (0, 0, 0, 0, 0, 0))) + [0] * 6
    out["Root"] = (r[0], r[1], r[2], r[3], r[4] + lift, r[5])
    return out


# ---------------------------------------------------------------------------------------------------------------------
# Shared pieces
ARMS_CROSSED = {"RightShoulder": (72, 0, -38), "RightElbow": (112, 0, 0), "LeftShoulder": (68, 0, 36), "LeftElbow": (118, 0, 0)}
HANDS_BEHIND = {"RightShoulder": (-28, 0, -12), "RightElbow": (68, 0, 0), "LeftShoulder": (-28, 0, 12), "LeftElbow": (68, 0, 0)}


def attack(frames, length):
    return clip(length, False, frames)


VILLAINS = {}

# THANOS: the titan admires his gauntlet at the post; heavy stomping run; overhead two-handed gauntlet smash.
thanos_idle_a = {"Root": (0, 8, 0), "Neck": (-14, 22, 4), "LeftShoulder": (78, 0, 24), "LeftElbow": (74, 0, 0),
                 "LeftWrist": (0, -30, 0), "RightShoulder": (4, 0, 6), "RightElbow": (12, 0, 0), "Waist": (2, 6, 0),
                 "LeftHip": (4, 0, -3), "RightHip": (-2, 0, 3)}
thanos_idle_b = merge(thanos_idle_a, {"LeftWrist": (0, 35, 0), "Neck": (-18, 26, 6), "LeftElbow": (80, 0, 0)})
thanos_base = {"Root": (-12, 0, 0), "Waist": (-6, 0, 0), "Neck": (8, 0, 0)}
VILLAINS["Thanos"] = {
    "Idle": clip(5.2, True, [(0, thanos_idle_a), (0.3, breathe(thanos_idle_b)), (0.55, thanos_idle_b), (0.8, breathe(thanos_idle_a)),
                             (1, thanos_idle_a)]),
    "Wake": attack([(0, thanos_idle_a), (0.35, {"Root": (-4, 0, 0, 0, -0.25, 0), "Neck": (6, 0, 0), "RightShoulder": (60, 0, -30),
                                                   "RightElbow": (95, 0, 0), "LeftShoulder": (60, 0, 30), "LeftElbow": (95, 0, 0)}),
                    (0.7, {"Root": (0, 0, 0, 0, 0.1, 0), "Neck": (8, 0, 0), "RightShoulder": (20, 0, 20), "RightElbow": (60, 0, 0),
                           "LeftShoulder": (20, 0, -20), "LeftElbow": (60, 0, 0)}), (1, {"Neck": (4, 0, 0)})], 1.2),
    "Move": cycle(0.82, gait(thanos_base, hip=38, knee_back=62, knee_lift=70, arm=42, elbow=58, bob=0.28, lean_twist=8), speed=16),
    "Walk": cycle(1.15, gait({"Root": (-4, 0, 0), "Neck": (4, 0, 0)}, hip=24, knee_back=30, knee_lift=38, arm=20, elbow=22, bob=0.12), speed=8),
    "Attack": attack([(0, {}), (0.35, {"Root": (6, 0, 0, 0, 0.1, 0), "Waist": (14, 0, 0), "RightShoulder": (172, 0, -8), "RightElbow": (28, 0, 0),
                                       "LeftShoulder": (172, 0, 8), "LeftElbow": (28, 0, 0), "Neck": (12, 0, 0)}),
                      (0.55, {"Root": (-16, 0, 0, 0, -0.45, 0), "Waist": (-26, 0, 0), "RightShoulder": (58, 0, -12), "RightElbow": (8, 0, 0),
                              "LeftShoulder": (58, 0, 12), "LeftElbow": (8, 0, 0), "Neck": (-6, 0, 0), "RightHip": (22, 0, 0),
                              "RightKnee": (-35, 0, 0), "LeftHip": (-10, 0, 0), "LeftKnee": (-20, 0, 0)}),
                      (1, {})], 0.62),
}

# DARKSEID: hands behind his back, slowly surveying his domain; a stiff, relentless march; a sweeping backhand.
darkseid_idle = merge(HANDS_BEHIND, {"Neck": (8, 0, 0), "Waist": (3, 0, 0)})
darkseid_base = merge({"Root": (-3, 0, 0), "Neck": (6, 0, 0)})
VILLAINS["Darkseid"] = {
    "Idle": clip(7.0, True, [(0, merge(darkseid_idle, {"Neck": (8, -28, 0)})), (0.25, breathe(merge(darkseid_idle, {"Neck": (10, 0, 0)}), 2)),
                             (0.5, merge(darkseid_idle, {"Neck": (8, 28, 0)})), (0.75, breathe(merge(darkseid_idle, {"Neck": (10, 0, 0)}), 2)),
                             (1, merge(darkseid_idle, {"Neck": (8, -28, 0)}))]),
    "Wake": attack([(0, darkseid_idle), (0.4, {"Neck": (2, 0, 0), "RightShoulder": (8, 0, 28), "RightElbow": (30, 0, 0),
                                               "LeftShoulder": (8, 0, -28), "LeftElbow": (30, 0, 0), "Waist": (5, 0, 0)}),
                    (1, {"Neck": (4, 0, 0), "RightShoulder": (4, 0, 12), "LeftShoulder": (4, 0, -12)})], 1.1),
    "Move": cycle(0.95, gait(darkseid_base, hip=30, knee_back=34, knee_lift=40, arm=18, elbow=14, bob=0.1, lean_twist=3), speed=15),
    "Walk": cycle(1.3, gait(merge(darkseid_base, HANDS_BEHIND), hip=20, knee_back=22, knee_lift=26, arm=0, elbow=0, bob=0.06, arms=False), speed=8),
    "Attack": attack([(0, {}), (0.3, {"Waist": (0, 30, 0), "Root": (0, 10, 0), "RightShoulder": (82, 0, -62), "RightElbow": (36, 0, 0),
                                      "Neck": (0, -10, 0)}),
                      (0.55, {"Waist": (-6, -34, 0), "Root": (0, -12, 0, 0, -0.1, 0), "RightShoulder": (88, 0, 78), "RightElbow": (6, 0, 0),
                              "Neck": (0, 12, 0), "LeftShoulder": (10, 0, -20)}),
                      (1, {})], 0.6),
}

# CARNAGE: hunched and twitchy, sniffing the air; a feral low sprint with the arms trailing; a crossing double claw slash.
carnage_base = {"Root": (-10, 0, 0, 0, -0.35, 0), "Waist": (-30, 0, 0), "Neck": (26, 0, 0),
                "RightShoulder": (22, 0, 12), "RightElbow": (28, 0, 0), "LeftShoulder": (22, 0, -12), "LeftElbow": (28, 0, 0),
                "RightHip": (18, 0, 4), "RightKnee": (-28, 0, 0), "LeftHip": (18, 0, -4), "LeftKnee": (-28, 0, 0),
                "RightAnkle": (10, 0, 0), "LeftAnkle": (10, 0, 0)}
VILLAINS["Carnage"] = {
    "Idle": clip(3.4, True, [(0, carnage_base), (0.18, merge(carnage_base, {"Neck": (30, 32, 10), "Waist": (-28, 8, 4)}), "quad_out"),
                             (0.3, merge(carnage_base, {"Neck": (30, 32, 10), "Waist": (-28, 8, 4)})),
                             (0.42, merge(carnage_base, {"Neck": (22, -26, -12), "Waist": (-32, -8, -4), "RightShoulder": (30, 0, 18)}), "quad_out"),
                             (0.62, breathe(carnage_base, 4, 0.08)),
                             (0.72, merge(carnage_base, {"Neck": (40, 0, 0)}), "quad_out"), (0.78, merge(carnage_base, {"Neck": (18, 0, 0)}), "quad_out"),
                             (1, carnage_base)]),
    "Wake": attack([(0, carnage_base), (0.3, merge(carnage_base, {"Root": (-6, 0, 0, 0, -0.9, 0), "Waist": (-40, 0, 0), "Neck": (40, 0, 0),
                                                                  "RightShoulder": (60, 0, 40), "LeftShoulder": (60, 0, -40)})),
                    (0.7, merge(carnage_base, {"Root": (0, 0, 0, 0, 0.1, 0), "Waist": (-10, 0, 0), "Neck": (10, 0, 0),
                                               "RightShoulder": (40, 0, 70), "RightElbow": (60, 0, 0), "LeftShoulder": (40, 0, -70),
                                               "LeftElbow": (60, 0, 0)})), (1, carnage_base)], 1.0),
    "Move": cycle(0.56, gait({"Root": (-28, 0, 0), "Waist": (-16, 0, 0), "Neck": (30, 0, 0), "RightShoulder": (-58, 0, 16),
                              "RightElbow": (20, 0, 0), "LeftShoulder": (-58, 0, -16), "LeftElbow": (20, 0, 0)},
                             hip=58, knee_back=82, knee_lift=95, arm=10, elbow=10, bob=0.36, lean_twist=4, arms=False), speed=20),
    "Walk": cycle(0.9, gait(carnage_base, hip=26, knee_back=40, knee_lift=48, arm=14, elbow=10, bob=0.14), speed=9),
    "Attack": attack([(0, carnage_base), (0.3, merge(carnage_base, {"RightShoulder": (150, 0, 34), "RightElbow": (40, 0, 0),
                                                                   "LeftShoulder": (150, 0, -34), "LeftElbow": (40, 0, 0), "Waist": (-8, 0, 0),
                                                                   "Neck": (10, 0, 0)})),
                      (0.55, merge(carnage_base, {"RightShoulder": (24, 0, -42), "RightElbow": (6, 0, 0), "LeftShoulder": (24, 0, 42),
                                                  "LeftElbow": (6, 0, 0), "Waist": (-42, 0, 0), "Root": (-14, 0, 0, 0, -0.6, -0.5)})),
                      (1, carnage_base)], 0.56),
}

# SHIGARAKI: slouched and bored, scratching his neck; a lanky slouched jog; a lunging open-hand decay grab.
shig_base = {"Waist": (-15, 0, 4), "Neck": (-20, 0, 10), "LeftShoulder": (6, 0, -10), "LeftElbow": (16, 0, 0)}
shig_scratch_a = merge(shig_base, {"RightShoulder": (104, 0, -34), "RightElbow": (128, 0, 0), "Neck": (-16, -14, 16)})
shig_scratch_b = merge(shig_scratch_a, {"RightElbow": (142, 0, 0)})
shig_rest = merge(shig_base, {"RightShoulder": (8, 0, 10), "RightElbow": (18, 0, 0)})
scratch = []
for i in range(8):
    scratch.append((0.1 + i * 0.05, shig_scratch_b if i % 2 == 0 else shig_scratch_a, "quad_inout"))
VILLAINS["Shigaraki"] = {
    "Idle": clip(4.6, True, [(0, shig_rest), (0.1, shig_scratch_a)] + scratch + [(0.55, shig_scratch_a), (0.68, breathe(shig_rest, 3)),
                                                                                 (0.85, merge(shig_rest, {"Neck": (-24, 12, 14)})), (1, shig_rest)]),
    "Wake": attack([(0, shig_rest), (0.45, merge(shig_base, {"Neck": (2, 0, 6), "Waist": (-6, 0, 0), "RightShoulder": (30, 0, 36),
                                                            "RightElbow": (40, 0, 0), "LeftShoulder": (30, 0, -36), "LeftElbow": (40, 0, 0)})),
                    (1, merge(shig_base, {"Neck": (-6, 0, 6)}))], 1.1),
    "Move": cycle(0.74, gait({"Root": (-10, 0, 0), "Waist": (-12, 0, 4), "Neck": (-10, 0, 8)}, hip=36, knee_back=56, knee_lift=62, arm=26,
                             elbow=30, bob=0.2, lean_twist=7), speed=16),
    "Walk": cycle(1.2, gait(shig_base, hip=22, knee_back=28, knee_lift=34, arm=14, elbow=16, bob=0.08, arms=False), speed=8),
    "Attack": attack([(0, shig_rest), (0.3, merge(shig_base, {"RightShoulder": (70, 0, -10), "RightElbow": (70, 0, 0), "Waist": (-4, 12, 0)})),
                      (0.55, merge(shig_base, {"RightShoulder": (92, 0, 4), "RightElbow": (4, 0, 0), "RightWrist": (-34, 0, 0),
                                               "Waist": (-24, -10, 0), "Neck": (-4, 0, 0), "Root": (-10, 0, 0, 0, -0.2, -0.7),
                                               "RightHip": (30, 0, 0), "RightKnee": (-30, 0, 0), "LeftHip": (-16, 0, 0)})),
                      (0.75, merge(shig_base, {"RightShoulder": (92, 0, 4), "RightElbow": (4, 0, 0), "RightWrist": (-34, 0, 0),
                                               "Waist": (-24, -10, 0), "Root": (-10, 0, 0, 0, -0.2, -0.7)})),
                      (1, shig_rest)], 0.7),
}

# FRIEZA: always floating: arms crossed, legs dangling, a slow bob; glides leaning forward with the legs trailing;
# death-beam finger point.
frieza_legs = {"RightHip": (12, 0, 3), "RightKnee": (-26, 0, 0), "RightAnkle": (-38, 0, 0), "LeftHip": (6, 0, -3),
               "LeftKnee": (-14, 0, 0), "LeftAnkle": (-40, 0, 0)}
frieza_idle = merge(ARMS_CROSSED, frieza_legs, {"Neck": (6, 0, 0), "Waist": (2, 0, 0)})
VILLAINS["Frieza"] = {
    "Idle": clip(3.2, True, [(0, merge(frieza_idle, {"Root": (0, 0, 0, 0, -0.18, 0)})),
                             (0.5, merge(frieza_idle, {"Root": (2, 0, 2, 0, 0.22, 0), "RightKnee": (-32, 0, 0), "LeftKnee": (-20, 0, 0)})),
                             (1, merge(frieza_idle, {"Root": (0, 0, 0, 0, -0.18, 0)}))]),
    "Wake": attack([(0, frieza_idle), (0.45, merge(frieza_legs, {"Neck": (10, 0, 0), "RightShoulder": (40, 0, 30), "RightElbow": (40, 0, 0),
                                                                 "LeftShoulder": (20, 0, -20), "LeftElbow": (30, 0, 0), "Root": (0, 0, 0, 0, 0.3, 0)})),
                    (1, frieza_idle)], 1.0),
    "Move": clip(1.4, True, [(0, merge(frieza_legs, {"Root": (-16, 0, 0, 0, 0, 0), "Waist": (-6, 0, 0), "Neck": (18, 0, 0),
                                                      "RightShoulder": (-32, 0, 18), "RightElbow": (14, 0, 0), "LeftShoulder": (-32, 0, -18),
                                                      "LeftElbow": (14, 0, 0), "RightHip": (-18, 0, 4), "RightKnee": (-36, 0, 0),
                                                      "LeftHip": (-8, 0, -4), "LeftKnee": (-22, 0, 0)})),
                             (0.5, merge(frieza_legs, {"Root": (-13, 0, 3, 0, 0.18, 0), "Waist": (-6, 0, 0), "Neck": (16, 0, 0),
                                                        "RightShoulder": (-36, 0, 20), "RightElbow": (16, 0, 0), "LeftShoulder": (-36, 0, -20),
                                                        "LeftElbow": (16, 0, 0), "RightHip": (-10, 0, 4), "RightKnee": (-28, 0, 0),
                                                        "LeftHip": (-16, 0, -4), "LeftKnee": (-34, 0, 0)})),
                             (1, merge(frieza_legs, {"Root": (-16, 0, 0, 0, 0, 0), "Waist": (-6, 0, 0), "Neck": (18, 0, 0),
                                                      "RightShoulder": (-32, 0, 18), "RightElbow": (14, 0, 0), "LeftShoulder": (-32, 0, -18),
                                                      "LeftElbow": (14, 0, 0), "RightHip": (-18, 0, 4), "RightKnee": (-36, 0, 0),
                                                      "LeftHip": (-8, 0, -4), "LeftKnee": (-22, 0, 0)}))], speed=16),
    "Walk": clip(2.4, True, [(0, merge(frieza_idle, {"Root": (-8, 0, 0, 0, -0.1, 0)})), (0.5, merge(frieza_idle, {"Root": (-6, 0, 2, 0, 0.15, 0)})),
                             (1, merge(frieza_idle, {"Root": (-8, 0, 0, 0, -0.1, 0)}))], speed=8),
    "Attack": attack([(0, frieza_idle), (0.25, merge(frieza_legs, {"LeftShoulder": (68, 0, 36), "LeftElbow": (118, 0, 0),
                                                                    "RightShoulder": (70, 0, 20), "RightElbow": (60, 0, 0), "Neck": (4, 0, 0)})),
                      (0.45, merge(frieza_legs, {"LeftShoulder": (68, 0, 36), "LeftElbow": (118, 0, 0), "RightShoulder": (92, 0, 4),
                                                 "RightElbow": (0, 0, 0), "RightWrist": (-8, 0, 0), "Waist": (-4, -12, 0), "Neck": (0, -8, 0)})),
                      (0.55, merge(frieza_legs, {"LeftShoulder": (68, 0, 36), "LeftElbow": (118, 0, 0), "RightShoulder": (100, 0, 4),
                                                 "RightElbow": (0, 0, 0), "Waist": (2, -12, 0), "Root": (4, 0, 0, 0, 0, 0.2)})),
                      (0.8, merge(frieza_legs, {"LeftShoulder": (68, 0, 36), "LeftElbow": (118, 0, 0), "RightShoulder": (92, 0, 4),
                                                "RightElbow": (0, 0, 0), "Waist": (-4, -12, 0)})),
                      (1, frieza_idle)], 0.7),
}

# KAIDO: drunk and dozing, swaying with his head drooping, a swig from the gourd now and then; a lumbering stomp;
# a huge two-handed club swing.
kaido_sway_l = {"Root": (0, 0, 5), "Waist": (-8, 0, 6), "Neck": (-30, 10, 8), "RightShoulder": (8, 0, 14), "RightElbow": (20, 0, 0),
                "LeftShoulder": (6, 0, -18), "LeftElbow": (14, 0, 0), "RightHip": (0, 0, 4), "LeftHip": (0, 0, -6)}
kaido_sway_r = mirror_pose(kaido_sway_l)
kaido_sip = merge(kaido_sway_l, {"RightShoulder": (118, 0, -30), "RightElbow": (120, 0, 0), "Neck": (18, 0, 0), "Waist": (6, 0, 0)})
VILLAINS["Kaido"] = {
    "Idle": clip(7.0, True, [(0, kaido_sway_l), (0.18, breathe(kaido_sway_r, 3, 0.08)), (0.36, kaido_sway_l), (0.5, kaido_sip),
                             (0.62, kaido_sip), (0.74, kaido_sway_r), (0.88, breathe(kaido_sway_l, 3, 0.08)), (1, kaido_sway_l)]),
    "Wake": attack([(0, kaido_sway_l), (0.4, {"Neck": (24, 0, 0), "Waist": (10, 0, 0), "RightShoulder": (60, 0, 70), "RightElbow": (40, 0, 0),
                                              "LeftShoulder": (60, 0, -70), "LeftElbow": (40, 0, 0), "Root": (4, 0, 0, 0, 0.15, 0)}),
                    (0.75, {"Neck": (20, 0, 0), "Waist": (8, 0, 0), "RightShoulder": (70, 0, 76), "RightElbow": (30, 0, 0),
                            "LeftShoulder": (70, 0, -76), "LeftElbow": (30, 0, 0)}), (1, {"Neck": (2, 0, 0)})], 1.4),
    "Move": cycle(1.0, gait({"Root": (-8, 0, 0), "Waist": (-6, 0, 0), "Neck": (4, 0, 0)}, hip=32, knee_back=46, knee_lift=54, arm=36,
                            elbow=42, bob=0.32, lean_twist=10, sway=5), speed=16),
    "Walk": cycle(1.5, gait({"Root": (-2, 0, 0), "Neck": (-10, 0, 0)}, hip=20, knee_back=26, knee_lift=30, arm=18, elbow=20, bob=0.14,
                            sway=6), speed=8),
    "Attack": attack([(0, {}), (0.35, {"Waist": (8, -38, 0), "Root": (0, -14, 0), "RightShoulder": (140, 0, -30), "RightElbow": (40, 0, 0),
                                       "LeftShoulder": (130, 0, 36), "LeftElbow": (60, 0, 0), "Neck": (6, -10, 0)}),
                      (0.6, {"Waist": (-18, 42, 0), "Root": (-6, 16, 0, 0, -0.35, 0), "RightShoulder": (62, 0, 50), "RightElbow": (6, 0, 0),
                             "LeftShoulder": (70, 0, 20), "LeftElbow": (10, 0, 0), "Neck": (-4, 14, 0), "RightHip": (-10, 0, 0),
                             "LeftHip": (24, 0, 0), "LeftKnee": (-30, 0, 0)}),
                      (1, {})], 0.75),
}


def fmt(v):
    if isinstance(v, str):
        return '"' + v + '"'
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float):
        s = ("%.5f" % v).rstrip("0").rstrip(".")
        return s if s not in ("-0", "") else "0"
    return str(v)


def emit(name, clips):
    lines = [
        f"-- ReplicatedStorage.Directory.VillainAnimations.{name} (GENERATED - do not edit by hand)",
        "-- Authored in scripts/tools/villain_anim/gen_villain_clips.py (Euler poses -> Motor6D.Transform keys, hero clip Format 1,",
        "-- ReplicatedStorage.Library.Modules.HeroClipMath). Played by StarterPlayerScripts.Game.VillainClipPlayer.",
        "",
        "return {",
        "\tFormat = 1,",
        f'\tHeroId = "{name}",',
        "\tClips = {",
    ]
    for clip_name in ["Idle", "Wake", "Move", "Walk", "Attack"]:
        c = clips[clip_name]
        lines.append(f"\t\t{clip_name} = {{")
        lines.append(f"\t\t\tLength = {fmt(float(c['Length']))},")
        lines.append(f"\t\t\tLoop = {fmt(c['Loop'])},")
        if c["Speed"] is not None:
            lines.append(f"\t\t\tSpeed = {fmt(float(c['Speed']))},")
        lines.append("\t\t\tFootsteps = false,")
        lines.append("\t\t\tMotion = { Lift = 0, Lean = 0 },")
        lines.append("\t\t\tEffects = {},")
        lines.append("\t\t\tTracks = {")
        for j in JOINTS:
            if j not in c["Tracks"]:
                continue
            keys = ", ".join("{ " + ", ".join(fmt(x) for x in k) + " }" for k in c["Tracks"][j])
            lines.append(f"\t\t\t\t{j} = {{ {keys} }},")
        lines.append("\t\t\t},")
        lines.append("\t\t},")
    lines += ["\t},", "}", ""]
    return "\n".join(lines)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, clips in VILLAINS.items():
        path = os.path.join(OUT_DIR, name + ".luau")
        with open(path, "w", newline="\n") as f:
            f.write(emit(name, clips))
        print("wrote", os.path.normpath(path), ", ".join(f"{k} {v['Length']}s" for k, v in clips.items()))


if __name__ == "__main__":
    main()
