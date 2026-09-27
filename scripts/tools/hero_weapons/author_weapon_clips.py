#!/usr/bin/env python3
"""Hand-authored hero weapon attack clips (owner 2026-09-27, round 9: "Mjolnir is badly rotated in the animation, the
animation is a jump and a slam into the ground; Goku's staff grows big, stretches out of the hand and the character
spins; the shield and the batarangs must fly out of our hands; make the animations more realistic and polished").

Writes src/ReplicatedStorage/Directory/WeaponAnimations/<WeaponId>.luau (hero clip Format 1,
ReplicatedStorage.Library.Modules.HeroClipMath) for the weapons listed in CLIPS; the other weapons keep the owner's
KeyframeSequence clips (gen_weapon_clips.py skips the ones authored here). Extra module fields read by
StarterPlayerScripts.BranchControllers.HeroWeaponController:
    FullBody = true      the hips / legs / root play even while running (the jump, the spin)
    Extend = { {t, k} }  the Power Pole's length factor over time (it grows out of the hand, then slides back)
    Release = t          the moment an aimed weapon leaves the hand (= Impact: the server launches it then)

Poses are Euler degrees (CFrame.Angles order X, Y, Z) on the R15 joints (identity C0 rotations), Root offsets in studs.
Sign conventions (R15, character facing -Z):
  Root / Waist rx < 0 leans forward, ry > 0 turns to the character's left; Neck rx < 0 looks down;
  Shoulder rx > 0 raises the arm forward, RightShoulder rz > 0 / LeftShoulder rz < 0 lift the arm out sideways;
  Elbow rx > 0 bends the forearm up; Wrist rx < 0 bends the hand down; Hip rx > 0 swings the thigh forward,
  Knee rx < 0 bends; Ankle rx > 0 toes up.

Run:  python3 scripts/tools/hero_weapons/author_weapon_clips.py [--render]
      (--render writes assets/hero_weapons/previews/clip_<WeaponId>.png: filmstrips with the owner's FBX mesh held at
      the build's grip, assets/hero_weapons/grip_adjust.json + HeroWeaponTools.gripRotations)
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..", "..")
OUT_DIR = os.path.join(ROOT, "src", "ReplicatedStorage", "Directory", "WeaponAnimations")
GRIP_ADJUST = os.path.join(ROOT, "assets", "hero_weapons", "grip_adjust.json")
JOINTS = ["Root", "Waist", "Neck", "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow",
          "RightWrist", "LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle"]


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
    return mul(mul(axis(rx, (1, 0, 0)), axis(ry, (0, 1, 0))), axis(rz, (0, 0, 1)))


def fmt(x):
    s = f"{x:.5f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


# ---------------------------------------------------------------------------------------------------------------------
# the clips: (time, pose, easing of the segment that starts at this key)
# ---------------------------------------------------------------------------------------------------------------------

NEUTRAL_ARMS = {"RightShoulder": (78, 0, 6), "RightElbow": (12, 0, 0), "LeftShoulder": (0, 0, -4), "LeftElbow": (6, 0, 0)}


def mjolnir():
    """Thor: coil down, leap with the hammer cocked behind the head, and bring it down into the ground in front."""
    ready = {"Root": (0, 0, 0, 0, 0, 0), "Waist": (0, 0, 0), "Neck": (0, 0, 0),
             "RightShoulder": (70, 0, 8), "RightElbow": (18, 0, 0), "RightWrist": (0, 0, 0),
             "LeftShoulder": (0, 0, -6), "LeftElbow": (8, 0, 0),
             "RightHip": (0, 0, 0), "RightKnee": (0, 0, 0), "RightAnkle": (0, 0, 0),
             "LeftHip": (0, 0, 0), "LeftKnee": (0, 0, 0), "LeftAnkle": (0, 0, 0)}
    coil = {"Root": (-12, 18, 0, 0, -0.6, 0.1), "Waist": (-8, 12, 0), "Neck": (8, -10, 0),
            "RightShoulder": (140, 0, 28), "RightElbow": (70, 0, 0), "RightWrist": (-10, 0, 0),
            "LeftShoulder": (38, 0, -24), "LeftElbow": (32, 0, 0),
            "RightHip": (70, 0, 4), "RightKnee": (-98, 0, 0), "RightAnkle": (36, 0, 0),
            "LeftHip": (65, 0, -4), "LeftKnee": (-95, 0, 0), "LeftAnkle": (38, 0, 0)}
    apex = {"Root": (6, 0, 0, 0, 2.5, -0.5), "Waist": (10, -6, 0), "Neck": (-6, 6, 0),
            "RightShoulder": (160, 0, 6), "RightElbow": (4, 0, 0), "RightWrist": (-30, 0, 0),
            "LeftShoulder": (140, 0, -38), "LeftElbow": (22, 0, 0),
            "RightHip": (64, 0, 6), "RightKnee": (-100, 0, 0), "RightAnkle": (22, 0, 0),
            "LeftHip": (30, 0, -6), "LeftKnee": (-108, 0, 0), "LeftAnkle": (30, 0, 0)}
    swing = {"Root": (-12, 0, 0, 0, 1.3, -0.7), "Waist": (-14, 0, 0), "Neck": (-8, 0, 0),
             "RightShoulder": (120, 0, 0), "RightElbow": (10, 0, 0), "RightWrist": (-16, 0, 0),
             "LeftShoulder": (70, 0, -42), "LeftElbow": (20, 0, 0),
             "RightHip": (60, 0, 4), "RightKnee": (-50, 0, 0), "RightAnkle": (6, 0, 0),
             "LeftHip": (10, 0, -4), "LeftKnee": (-50, 0, 0), "LeftAnkle": (10, 0, 0)}
    # the strike (solved for the owner's mesh at the build's grip: the head's face flat on the ground ~3.9 studs out,
    # the handle level, the landing in a lunge with the back knee low)
    impact = {"Root": (-18, 0, 0, 0, -0.85, -0.7), "Waist": (-16, 0, 0), "Neck": (4, 0, 0),
              "RightShoulder": (50, 0, -10), "RightElbow": (0, 0, 0), "RightWrist": (-10, 0, 0),
              "LeftShoulder": (26, 0, -56), "LeftElbow": (28, 0, 0),
              "RightHip": (110, 0, 0), "RightKnee": (-85, 0, 0), "RightAnkle": (-20, 0, 0),
              "LeftHip": (-5, 0, 0), "LeftKnee": (-60, 0, 0), "LeftAnkle": (20, 0, 0)}
    settle = dict(impact)
    settle.update({"Root": (-16, 0, 0, 0, -0.78, -0.7), "RightShoulder": (54, 0, -10), "RightWrist": (-14, 0, 0)})
    recover = dict(ready)
    recover.update({"RightShoulder": (80, 0, 6), "RightElbow": (14, 0, 0)})
    return {
        "length": 1.05, "impact": 0.56, "full_body": True,
        "keys": [(0.0, ready, "sine_inout"), (0.13, coil, "quad_out"), (0.32, apex, "quad_in"),
                 (0.48, swing, "quad_in"), (0.56, impact, "quad_out"), (0.7, settle, "sine_inout"),
                 (1.05, recover, "linear")],
    }


def power_pole():
    """Goku: the arm swings out, the pole shoots out of the hand to full length and he spins a whole turn with it."""
    ready = {"Root": (0, 0, 0, 0, 0, 0), "Waist": (0, 0, 0), "Neck": (0, 0, 0),
             "RightShoulder": (75, 0, 10), "RightElbow": (16, 0, 0), "RightWrist": (0, 0, 0),
             "LeftShoulder": (0, 0, -6), "LeftElbow": (8, 0, 0),
             "RightHip": (0, 0, 0), "RightKnee": (0, 0, 0), "RightAnkle": (0, 0, 0),
             "LeftHip": (0, 0, 0), "LeftKnee": (0, 0, 0), "LeftAnkle": (0, 0, 0)}
    # coiled to the left, arm pulled across; then the arm straight out to the right (the pole points outward: the
    # wrist turns the hand's -Z along the arm), knees bent in a wide stance, spinning on the Root
    stance = {"RightHip": (18, 0, 14), "RightKnee": (-34, 0, 0), "RightAnkle": (14, 0, 0),
              "LeftHip": (18, 0, -14), "LeftKnee": (-34, 0, 0), "LeftAnkle": (14, 0, 0)}
    arm_out = {"RightShoulder": (8, 0, 92), "RightElbow": (4, 0, 0), "RightWrist": (-88, 0, 0),
               "LeftShoulder": (10, 0, -70), "LeftElbow": (30, 0, 0), "Waist": (-6, 0, 0), "Neck": (0, 0, 0)}
    coil = {"Root": (-6, -38, 0, 0, -0.45, 0), "Waist": (-6, -26, 0), "Neck": (0, 30, 0),
            "RightShoulder": (20, 0, 70), "RightElbow": (40, 0, 0), "RightWrist": (-60, 0, 0),
            "LeftShoulder": (40, 0, -30), "LeftElbow": (50, 0, 0)}
    coil.update({k: v for k, v in stance.items()})
    keys = [(0.0, ready, "sine_inout"), (0.14, coil, "quad_out")]
    # the spin: Root ry from -38 (coiled back to the right) all the way round counter-clockwise seen from above, so the
    # pole on the right leads the sweep forward
    spin_start, spin_end = 0.24, 0.72
    steps = 5
    for i in range(steps + 1):
        f = i / steps
        ry = -38 + 398 * f
        pose = {"Root": (-8, ry, 0, 0, -0.45 + 0.12 * math.sin(math.pi * f), 0)}
        pose.update(arm_out)
        pose.update(stance)
        keys.append((spin_start + (spin_end - spin_start) * f, pose, "linear"))
    keys[-1] = (keys[-1][0], keys[-1][1], "sine_out")
    recover = dict(ready)
    recover["Root"] = (0, 360, 0, 0, 0, 0)  # same facing as 0: the hemisphere fix keeps the short way round
    keys.append((1.0, recover, "linear"))
    return {"length": 1.0, "impact": 0.46, "full_body": True, "keys": keys,
            # the pole's length factor: out of the hand as the spin starts, full length through the turn, back in
            "extend": [(0.0, 1.0), (0.16, 1.0), (0.26, 3.6), (0.7, 3.6), (0.86, 1.0), (1.0, 1.0)]}


def cap_shield():
    """Cap: cock the shield across the chest, uncoil the torso and fling it out flat (a backhand frisbee throw)."""
    ready = {"Root": (0, 0, 0, 0, 0, 0), "Waist": (0, 0, 0), "Neck": (0, 0, 0),
             "RightShoulder": (72, 0, 8), "RightElbow": (20, 0, 0), "RightWrist": (0, 0, 0),
             "LeftShoulder": (0, 0, -6), "LeftElbow": (8, 0, 0),
             "RightHip": (0, 0, 0), "RightKnee": (0, 0, 0), "RightAnkle": (0, 0, 0),
             "LeftHip": (0, 0, 0), "LeftKnee": (0, 0, 0), "LeftAnkle": (0, 0, 0)}
    cock = {"Root": (-4, 22, 0, 0, -0.2, 0), "Waist": (-6, 34, 0), "Neck": (0, -44, 0),
            "RightShoulder": (84, 0, -58), "RightElbow": (112, 0, 0), "RightWrist": (0, 0, 0),
            "LeftShoulder": (30, 0, -34), "LeftElbow": (40, 0, 0),
            "RightHip": (-10, 0, 4), "RightKnee": (-22, 0, 0), "RightAnkle": (6, 0, 0),
            "LeftHip": (26, 0, -4), "LeftKnee": (-26, 0, 0), "LeftAnkle": (8, 0, 0)}
    release = {"Root": (-8, -14, 0, 0, -0.25, -0.2), "Waist": (-8, -24, 0), "Neck": (0, 30, 0),
               "RightShoulder": (92, 0, 28), "RightElbow": (6, 0, 0), "RightWrist": (0, 0, 0),
               "LeftShoulder": (20, 0, -50), "LeftElbow": (30, 0, 0),
               "RightHip": (-16, 0, 4), "RightKnee": (-14, 0, 0), "RightAnkle": (4, 0, 0),
               "LeftHip": (32, 0, -4), "LeftKnee": (-30, 0, 0), "LeftAnkle": (10, 0, 0)}
    follow = dict(release)
    follow.update({"Root": (-6, -22, 0, 0, -0.2, -0.2), "Waist": (-6, -32, 0), "Neck": (0, 36, 0),
                   "RightShoulder": (82, 0, 62), "RightElbow": (14, 0, 0)})
    recover = dict(ready)
    return {"length": 0.72, "impact": 0.26, "full_body": False,
            "keys": [(0.0, ready, "sine_inout"), (0.15, cock, "quad_in"), (0.26, release, "quad_out"),
                     (0.4, follow, "sine_inout"), (0.72, recover, "linear")]}


def batarang():
    """Batman: a quick sidearm flick - the arm whips from behind the hip across the body and lets go."""
    ready = {"Root": (0, 0, 0, 0, 0, 0), "Waist": (0, 0, 0), "Neck": (0, 0, 0),
             "RightShoulder": (70, 0, 8), "RightElbow": (22, 0, 0), "RightWrist": (0, 0, 0),
             "LeftShoulder": (0, 0, -6), "LeftElbow": (8, 0, 0),
             "RightHip": (0, 0, 0), "RightKnee": (0, 0, 0), "RightAnkle": (0, 0, 0),
             "LeftHip": (0, 0, 0), "LeftKnee": (0, 0, 0), "LeftAnkle": (0, 0, 0)}
    cock = {"Root": (-4, -24, 0, 0, -0.25, 0), "Waist": (-4, -28, 0), "Neck": (0, 40, 0),
            "RightShoulder": (30, 0, 64), "RightElbow": (70, 0, 0), "RightWrist": (0, 0, 20),
            "LeftShoulder": (46, 0, -26), "LeftElbow": (40, 0, 0),
            "RightHip": (20, 0, 4), "RightKnee": (-28, 0, 0), "RightAnkle": (10, 0, 0),
            "LeftHip": (-8, 0, -4), "LeftKnee": (-20, 0, 0), "LeftAnkle": (4, 0, 0)}
    release = {"Root": (-10, 14, 0, 0, -0.3, -0.2), "Waist": (-10, 22, 0), "Neck": (0, -18, 0),
               "RightShoulder": (88, 0, -18), "RightElbow": (6, 0, 0), "RightWrist": (0, 0, -24),
               "LeftShoulder": (16, 0, -40), "LeftElbow": (30, 0, 0),
               "RightHip": (30, 0, 4), "RightKnee": (-32, 0, 0), "RightAnkle": (10, 0, 0),
               "LeftHip": (-16, 0, -4), "LeftKnee": (-18, 0, 0), "LeftAnkle": (4, 0, 0)}
    follow = dict(release)
    follow.update({"Root": (-8, 20, 0, 0, -0.25, -0.2), "Waist": (-8, 30, 0),
                   "RightShoulder": (70, 0, -44), "RightElbow": (26, 0, 0)})
    recover = dict(ready)
    return {"length": 0.62, "impact": 0.22, "full_body": False,
            "keys": [(0.0, ready, "sine_inout"), (0.12, cock, "quad_in"), (0.22, release, "quad_out"),
                     (0.34, follow, "sine_inout"), (0.62, recover, "linear")]}


def web_shooter():
    """Spider-Man: the arm snaps out toward the aim, the wrist flicks back (thwip), a small recoil."""
    ready = {"Root": (0, 0, 0, 0, 0, 0), "Waist": (0, 0, 0), "Neck": (0, 0, 0),
             "RightShoulder": (70, 0, 8), "RightElbow": (22, 0, 0), "RightWrist": (0, 0, 0),
             "LeftShoulder": (0, 0, -6), "LeftElbow": (8, 0, 0),
             "RightHip": (0, 0, 0), "RightKnee": (0, 0, 0), "RightAnkle": (0, 0, 0),
             "LeftHip": (0, 0, 0), "LeftKnee": (0, 0, 0), "LeftAnkle": (0, 0, 0)}
    aim = {"Root": (-4, 8, 0, 0, -0.18, 0), "Waist": (-2, 10, 0), "Neck": (0, -12, 0),
           "RightShoulder": (94, 0, 2), "RightElbow": (2, 0, 0), "RightWrist": (-10, 0, 0),
           "LeftShoulder": (30, 0, -20), "LeftElbow": (60, 0, 0),
           "RightHip": (12, 0, 4), "RightKnee": (-20, 0, 0), "RightAnkle": (6, 0, 0),
           "LeftHip": (-8, 0, -4), "LeftKnee": (-14, 0, 0), "LeftAnkle": (4, 0, 0)}
    thwip = dict(aim)
    thwip.update({"RightShoulder": (98, 0, 2), "RightWrist": (52, 0, 0), "RightElbow": (0, 0, 0)})
    recoil = dict(aim)
    recoil.update({"Root": (2, 8, 0, 0, -0.14, 0.12), "RightShoulder": (104, 0, 2), "RightElbow": (14, 0, 0),
                   "RightWrist": (30, 0, 0)})
    recover = dict(ready)
    return {"length": 0.55, "impact": 0.16, "full_body": False,
            "keys": [(0.0, ready, "quad_out"), (0.1, aim, "quad_out"), (0.16, thwip, "quad_out"),
                     (0.26, recoil, "sine_inout"), (0.55, recover, "linear")]}


def gomu_fist():
    """Luffy: Gum-Gum Pistol - the arm winds back, the fist shoots out straight ahead at shoulder height on a long
    rubber arm (Stretch keys, ~7.5x), hangs out there a beat and snaps back (owner 2026-09-27: "Luffy's fist must
    stretch, and its hitbox must match"). The punch pose is solved so the stretch runs straight along -Z."""
    ready = {"Root": (0, 0, 0, 0, 0, 0), "Waist": (0, 0, 0), "Neck": (0, 0, 0),
             "RightShoulder": (70, 0, 8), "RightElbow": (22, 0, 0), "RightWrist": (0, 0, 0),
             "LeftShoulder": (0, 0, -6), "LeftElbow": (8, 0, 0),
             "RightHip": (0, 0, 0), "RightKnee": (0, 0, 0), "RightAnkle": (0, 0, 0),
             "LeftHip": (0, 0, 0), "LeftKnee": (0, 0, 0), "LeftAnkle": (0, 0, 0)}
    windup = {"Root": (-4, -18, 0, 0, -0.3, 0.2), "Waist": (-4, -26, 0), "Neck": (0, 30, 0),
              "RightShoulder": (30, 0, 40), "RightElbow": (110, 0, 0), "RightWrist": (0, 0, 0),
              "LeftShoulder": (70, 0, -10), "LeftElbow": (20, 0, 0),
              "RightHip": (-12, 0, 6), "RightKnee": (-26, 0, 0), "RightAnkle": (8, 0, 0),
              "LeftHip": (30, 0, -6), "LeftKnee": (-30, 0, 0), "LeftAnkle": (10, 0, 0)}
    punch = {"Root": (-6, 8, 0, 0, -0.3, -0.3), "Waist": (-4, 20, 0), "Neck": (0, -18, 0),
             "RightShoulder": (90, 20, 30), "RightElbow": (0, 0, 0), "RightWrist": (0, 0, 0),
             "LeftShoulder": (20, 0, -40), "LeftElbow": (60, 0, 0),
             "RightHip": (-20, 0, 6), "RightKnee": (-16, 0, 0), "RightAnkle": (6, 0, 0),
             "LeftHip": (40, 0, -6), "LeftKnee": (-40, 0, 0), "LeftAnkle": (14, 0, 0)}
    hold = dict(punch)
    hold.update({"Root": (-5, 8, 0, 0, -0.28, -0.25)})
    recover = dict(ready)
    return {"length": 0.72, "impact": 0.28, "full_body": False,
            "keys": [(0.0, ready, "sine_inout"), (0.16, windup, "quad_in"), (0.24, punch, "quad_out"),
                     (0.44, hold, "sine_inout"), (0.72, recover, "linear")],
            # the rubber arm's length factor (HeroWeaponTools.SetStretch): out at the punch, a beat, snaps back
            "stretch": [(0.0, 1.0), (0.2, 1.0), (0.28, 7.5), (0.42, 7.5), (0.54, 2.0), (0.64, 1.0), (0.72, 1.0)]}


CLIPS = {"Mjolnir": ("Mjolnir_JumpSlam", mjolnir), "GomuFist": ("Gomu_Pistol_Long", gomu_fist), "PowerPole": ("Pole_SpinSweep", power_pole),
         "CapShield": ("Shield_Throw", cap_shield), "Batarang": ("Batarang_Flick", batarang),
         "WebShooter": ("Web_Thwip", web_shooter)}


# ---------------------------------------------------------------------------------------------------------------------
# output
# ---------------------------------------------------------------------------------------------------------------------

def tracks_of(spec):
    used = [j for j in JOINTS if any(j in key[1] for key in spec["keys"])]
    tracks = {}
    for joint in used:
        keys = []
        previous = None
        for t, pose, easing in spec["keys"]:
            v = list(pose.get(joint, (0, 0, 0))) + [0] * 6
            q = list(quat(v[0], v[1], v[2]))
            if previous is not None and sum(q[c] * previous[c] for c in range(4)) < 0:
                q = [-c for c in q]  # same hemisphere as the previous key: the slerp takes the short way
            previous = q
            key = [t, easing] + q
            if joint == "Root":
                key += [v[3], v[4], v[5]]
            keys.append(key)
        tracks[joint] = keys
    return tracks


def write_module(weapon, clip_name, spec):
    tracks = tracks_of(spec)
    lines = [
        f"-- ReplicatedStorage.Directory.WeaponAnimations.{weapon} (GENERATED - do not edit by hand)",
        f"-- Authored in scripts/tools/hero_weapons/author_weapon_clips.py ({clip_name}), hero clip Format 1",
        "-- (ReplicatedStorage.Library.Modules.HeroClipMath). Played on the attacker by",
        "-- StarterPlayerScripts.BranchControllers.HeroWeaponController; the server (GearService) resolves the hit at",
        "-- Impact seconds. Keys: { time, easing, qx, qy, qz, qw [, px, py, pz] }.",
        "",
        "return {",
        "\tFormat = 1,",
        f"\tWeaponId = \"{weapon}\",",
        f"\tClip = \"{clip_name}\",",
        f"\tLength = {fmt(spec['length'])},",
        f"\tImpact = {fmt(spec['impact'])},",
        f"\tRelease = {fmt(spec['impact'])},",
        "\tLoop = false,",
    ]
    if spec.get("full_body"):
        lines.append("\tFullBody = true,")
    if spec.get("extend"):
        body = ", ".join("{ " + fmt(t) + ", " + fmt(k) + " }" for t, k in spec["extend"])
        lines.append(f"\tExtend = {{ {body} }},")
    if spec.get("stretch"):
        body = ", ".join("{ " + fmt(t) + ", " + fmt(k) + " }" for t, k in spec["stretch"])
        lines.append(f"\tStretch = {{ {body} }},")
    lines.append("\tTracks = {")
    for joint in JOINTS:
        keys = tracks.get(joint)
        if not keys:
            continue
        body = ", ".join("{ " + ", ".join([fmt(k[0]), f"\"{k[1]}\""] + [fmt(c) for c in k[2:]]) + " }" for k in keys)
        lines.append(f"\t\t{joint} = {{ {body} }},")
    lines += ["\t},", "}", ""]
    with open(os.path.join(OUT_DIR, weapon + ".luau"), "w", newline="\n") as f:
        f.write("\n".join(lines))
    print(f"{clip_name:18s} -> {weapon:12s} length {spec['length']:.2f}s impact {spec['impact']:.2f}s, "
          f"{len(tracks)} joints, {sum(len(k) for k in tracks.values())} keys")


# ---------------------------------------------------------------------------------------------------------------------
# previews (numpy renderer of render_weapons.py, the owner's FBX meshes)
# ---------------------------------------------------------------------------------------------------------------------

EASE = {
    "linear": lambda t: t,
    "sine_inout": lambda t: -(math.cos(math.pi * t) - 1) / 2,
    "sine_out": lambda t: math.sin(t * math.pi / 2),
    "quad_in": lambda t: t * t,
    "quad_out": lambda t: -t * (t - 2),
}


def sample(spec, t):
    """{joint: 4x4} at time t (slerp between keys, like HeroClipMath)."""
    import numpy as np
    from rig import quat_pos
    tracks = tracks_of(spec)
    out = {}
    for joint, keys in tracks.items():
        if t <= keys[0][0]:
            a, b, f = keys[0], keys[0], 0.0
        elif t >= keys[-1][0]:
            a, b, f = keys[-1], keys[-1], 0.0
        else:
            for i in range(len(keys) - 1):
                if keys[i][0] <= t <= keys[i + 1][0]:
                    a, b = keys[i], keys[i + 1]
                    f = (t - a[0]) / (b[0] - a[0])
                    f = EASE.get(a[1], EASE["linear"])(f)
                    break
        qa, qb = np.array(a[2:6]), np.array(b[2:6])
        dot = float(np.dot(qa, qb))
        if dot < 0:
            qb, dot = -qb, -dot
        if dot > 0.9995:
            q = qa + (qb - qa) * f
        else:
            th = math.acos(dot)
            q = (math.sin((1 - f) * th) * qa + math.sin(f * th) * qb) / math.sin(th)
        q = q / np.linalg.norm(q)
        pa = np.array(a[6:9]) if len(a) > 6 else np.zeros(3)
        pb = np.array(b[6:9]) if len(b) > 6 else np.zeros(3)
        p = pa + (pb - pa) * f
        out[joint] = quat_pos(list(q) + list(p))
    return out


def extend_at(spec, t):
    keys = spec.get("extend")
    if not keys:
        return 1.0
    for (ta, ka), (tb, kb) in zip(keys[:-1], keys[1:]):
        if ta <= t <= tb:
            f = (t - ta) / (tb - ta)
            f = f * f * (3 - 2 * f)
            return ka + (kb - ka) * f
    return 1.0


def stretch_at(spec, t):
    keys = spec.get("stretch")
    if not keys:
        return 1.0
    for (ta, ka), (tb, kb) in zip(keys[:-1], keys[1:]):
        if ta <= t <= tb:
            f = (t - ta) / (tb - ta)
            f = f * f * (3 - 2 * f)
            return ka + (kb - ka) * f
    return 1.0


def mesh_by_name(path):
    """{mesh name: (triangles, colours)} of an FBX (the preview's per-mesh stretch)."""
    import numpy as np
    import fbx_inspect as F
    import render_fbx_weapons as RF
    sc = F.Scene(path)
    out = {}
    for oid, o in sc.models():
        if len(o.props) > 2 and o.props[2] == "Mesh":
            tris, _ = sc.mesh_triangles(oid)
            if tris is None or not len(tris):
                continue
            mats = sc.materials_of(oid)
            c = RF.colour(mats[0].props[1].split("\x00")[0] if mats else "")
            out[o.props[1].split("\x00")[0]] = (tris, [c] * len(tris))
    return out


def render_clip(weapon, clip_name, spec, frames=7):
    import numpy as np
    from PIL import Image
    import render_weapons as R
    import render_fbx_weapons as RF
    from rig import load_rig, pose_rig, cf
    fbx_name = {"BakugoGauntlet": "Bakugo_Gauntlet"}.get(weapon, weapon)
    tris, cols = RF.weapon_mesh(os.path.join(ROOT, "assets", "hero_weapons", "fbx", "weapons", fbx_name + ".fbx"))
    keep = [i for i, c in enumerate(cols) if c != RF.PALETTE["gold_energy"]]  # the build drops the VFX meshes
    tris, cols = tris[keep], [cols[i] for i in keep]
    with open(GRIP_ADJUST) as f:
        adjust = json.load(f).get(weapon, {})
    shift = np.array(adjust.get("Shift", [0, 0, 0]), dtype=float)
    from rig import rot_y
    grip_rot = RF.GRIP_ROTATIONS[fbx_name] @ rot_y(adjust.get("Twist", 0))
    parts, joints = load_rig()
    times = sorted(set([round(spec["length"] * i / (frames - 1), 3) for i in range(frames)] + [spec["impact"]]))
    views = []
    for t in times:
        transforms = sample(spec, t)
        world = pose_rig(parts, joints, transforms)
        pts = tris.reshape(-1, 3).copy()
        s_rubber = stretch_at(spec, t)
        if s_rubber != 1.0:
            # like HeroWeaponTools.SetStretch: the rubber grows from the hand along +Y, the fist rides its end
            meshes = mesh_by_name(os.path.join(ROOT, "assets", "hero_weapons", "fbx", "weapons", fbx_name + ".fbx"))
            parts_pts = []
            rubber_far = 1.55
            for name, (mt, mc) in meshes.items():
                mp = mt.reshape(-1, 3).copy()
                if "Rubber" in name:
                    mp[:, 1] = mp[:, 1] * s_rubber
                elif "Fist" in name:
                    mp[:, 1] = mp[:, 1] + (s_rubber - 1) * rubber_far
                parts_pts.append(mp)
            pts = np.concatenate(parts_pts)
            cols = sum((mc for _, (_, mc) in meshes.items()), [])
        k = extend_at(spec, t)
        if k != 1.0:
            ymin = pts[:, 1].min()
            pts[:, 1] = (pts[:, 1] - ymin) * k + ymin  # the pole grows out of the hand (its -Y end stays)
        pts = pts + shift
        m = world["RightHand"] @ cf(rot=grip_rot)
        posed_pts = (m[:3, :3] @ pts.T).T + m[:3, 3]
        posed = [(posed_pts[3 * i], posed_pts[3 * i + 1], posed_pts[3 * i + 2], cols[i]) for i in range(len(cols))]
        ground = [(np.array([-8, 0, -12.0]), np.array([8, 0, -12.0]), np.array([8, 0, 6.0]), (205, 214, 226)),
                  (np.array([-8, 0, -12.0]), np.array([8, 0, 6.0]), np.array([-8, 0, 6.0]), (205, 214, 226))]
        scene = R.rig_triangles(parts, world) + posed + ground
        tag = " IMPACT" if abs(t - spec["impact"]) < 1e-6 else ""
        views.append(R.label(R.render(scene, (11, 8, -15), (0.5, 3.0, -2.5), fov=48, size=300),
                             f"{clip_name} t={t:.2f}{tag}"))
        views.append(R.label(R.render(scene, (17, 4.5, -2.5), (0.5, 3.0, -2.5), fov=48, size=300), "side"))
    sheet = Image.new("RGB", (300 * len(views) // 2, 600), (255, 255, 255))
    for i, v in enumerate(views):
        sheet.paste(v, ((i // 2) * 300, (i % 2) * 300))
    out = os.path.join(ROOT, "assets", "hero_weapons", "previews", "clip_" + weapon + ".png")
    sheet.save(out)
    print("preview", out)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    only = [a for a in sys.argv[1:] if not a.startswith("--")]
    for weapon, (clip_name, make) in CLIPS.items():
        if only and weapon not in only:
            continue
        spec = make()
        write_module(weapon, clip_name, spec)
        if "--render" in sys.argv:
            sys.path.insert(0, HERE)
            render_clip(weapon, clip_name, spec)


if __name__ == "__main__":
    main()
