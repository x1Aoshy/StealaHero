# scripts/tools/blender/hero_anim/gait.py
# Foot-contact analysis of the pen hero clips (ANIMPOLISH). Pure Python (no bpy), runs with any Python 3:
#
#   python scripts/tools/blender/hero_anim/gait.py [HeroId ...] [--json out.json]
#
# For every hero module (default: all heroes/<HeroId>.py) it samples the clips on the template rig with the exact
# runtime math (api.sample_clip + Rig.fk) and measures, from the ankles and the soles (the four bottom corners of both
# feet):
#   Move  speed      the ground speed (studs/s at rig scale 1) that keeps the planted feet still: the mean backward
#                    velocity of the ankles while their sole is on the ground. It is what the clip's `speed=` must be:
#                    HeroClipPlayer plays Move at rate = ground speed / (Speed * rig scale).
#         slide      RMS of the planted ankles' velocity around that speed, relative to it (the stick-slip the keys'
#                    easing causes by itself even at the right rate; the gait helpers keep the stance leg linear)
#         stance     share of the cycle with a foot planted; airborne = no foot planted (hops, flips, flights)
#         contact    lowest sole height (studs, 0 = the ground) over the cycle
#   Idle  low / high lowest and highest sole height over the loop (a grounded idle keeps low ~ 0; floaters hover)
# api.py uses measure_move() for clip(..., speed="auto"): the exported Speed is the measured ground speed (None when
# the feet do not travel while planted: hops in place, swings, flights keep a fixed rate).

import json
import math
import os
import sys

sys.dont_write_bytecode = True  # keep __pycache__ out of the repo

if __package__ in (None, ""):
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    __package__ = "hero_anim"  # noqa: A001

from hero_anim import rbx  # noqa: E402

SAMPLE_HZ = 240.0
STANCE_EPS = 0.04  # a sole within this height of the cycle's lowest sole touches the floor
FEET = ("LeftFoot", "RightFoot")


def _api():
    from hero_anim import api
    return api


def sole_points(parts, rig):
    """foot -> the 4 bottom corners of the foot part in rig space."""
    out = {}
    for foot in FEET:
        sx, sy, sz = rig.parts[foot]["size"]
        frame = parts[foot]
        out[foot] = [rbx.cf_point(frame, (x * sx * 0.5, -sy * 0.5, z * sz * 0.5)) for x in (-1, 1) for z in (-1, 1)]
    return out


def foot_state(parts, joints, rig):
    """foot -> (sole height = lowest corner y, the 4 sole corners) in rig space (+z = backward)."""
    out = {}
    for foot, corners in sole_points(parts, rig).items():
        out[foot] = (min(c[1] for c in corners), corners)
    return out


def _samples(clip, compiled, rig, hz=SAMPLE_HZ):
    api = _api()
    n = max(8, int(round(clip.length * hz)))
    rows = []
    for i in range(n + 1):
        t = clip.length * i / n
        parts, joints = rig.fk(api.sample_clip(clip, t, compiled))
        rows.append((t, foot_state(parts, joints, rig)))
    return rows


def measure_move(clip, compiled=None):
    """Stride analysis of a looping locomotion clip on the template rig (scale 1). Returns a dict:
    speed      ground speed (studs/s): mean backward velocity of the sole corner touching the floor (the lowest corner
               of a foot within STANCE_EPS of the cycle's lowest sole) - what the clip's speed= must be for
               HeroClipPlayer (rate = ground speed / (Speed * rig scale)) to play it without sliding
    slide      RMS of that contact velocity around `speed`, relative to it (0 = glued; heel-toe pivots included)
    stance     share of the cycle with a foot on the floor; airborne = no foot on the floor
    contact    lowest sole height over the cycle (studs, 0 = the floor)
    valid      False when the feet do not travel backward while planted (hops in place, swings, flights)"""
    api = _api()
    rig = api.rig()
    compiled = compiled or api.compile_clip(clip)
    rows = _samples(clip, compiled, rig)
    lowest = min(min(s[foot][0] for foot in FEET) for _, s in rows)
    velocities, stance_time, airborne = [], 0.0, 0.0
    for i in range(1, len(rows)):
        t0, s0 = rows[i - 1]
        t1, s1 = rows[i]
        dt = t1 - t0
        any_planted = False
        for f in FEET:
            low0, c0 = s0[f]
            low1, c1 = s1[f]
            if low0 - lowest > STANCE_EPS or low1 - lowest > STANCE_EPS:
                continue
            any_planted = True
            k = min(range(4), key=lambda j: c1[j][1])
            velocities.append((c1[k][2] - c0[k][2]) / dt)
        if any_planted:
            stance_time += dt
        else:
            airborne += dt
    length = clip.length
    speed = sum(velocities) / len(velocities) if velocities else 0.0
    spread = math.sqrt(sum((v - speed) ** 2 for v in velocities) / len(velocities)) if velocities else 0.0
    return {
        "speed": speed,
        "slide": spread / speed if speed > 1e-6 else 0.0,
        "stance": stance_time / length if length > 0 else 0.0,
        "contact": lowest,
        "airborne": airborne / length if length > 0 else 0.0,
        "valid": speed > 0.8 and stance_time > 0.1 * length,
    }


def measure_idle(clip, compiled=None):
    api = _api()
    rig = api.rig()
    compiled = compiled or api.compile_clip(clip)
    rows = _samples(clip, compiled, rig, hz=60.0)
    lows = [min(s[foot][0] for foot in FEET) for _, s in rows]
    return {"low": min(lows), "high": max(lows)}


def _load(hero_id):
    import importlib
    api = _api()
    module = importlib.import_module("hero_anim.heroes." + hero_id)
    return api.load_hero(module)


def main(argv):
    out_json = None
    if "--json" in argv:
        i = argv.index("--json")
        out_json = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    here = os.path.dirname(os.path.abspath(__file__))
    ids = argv or sorted(f[:-3] for f in os.listdir(os.path.join(here, "heroes")) if f.endswith(".py") and not f.startswith("_"))
    report = {}
    print("%-14s %8s %7s %6s %6s %7s %6s | %6s %6s" % ("hero", "authored", "speed", "slide", "stance", "contact", "air",
                                                     "idleLo", "idleHi"))
    for hero_id in ids:
        hero = _load(hero_id)
        move = hero.clips["Move"]
        m = measure_move(move, hero.compiled["Move"])
        idle = measure_idle(hero.clips["Idle"], hero.compiled["Idle"])
        authored = move.speed if isinstance(move.speed, (int, float)) else None
        report[hero_id] = {"authored": authored, "footsteps": move.footsteps, "move": m, "idle": idle, "length": move.length}
        print("%-14s %8s %7s %6.2f %6.2f %7.2f %6.2f | %6.2f %6.2f%s" % (
            hero_id, "%.2f" % authored if authored else "-", "%.2f" % m["speed"] if m["valid"] else "(%.2f)" % m["speed"],
            m["slide"], m["stance"], m["contact"], m["airborne"], idle["low"], idle["high"],
            "" if move.footsteps else "  (no footsteps)"))
    if out_json:
        with open(out_json, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=1, sort_keys=True)


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    main(sys.argv[1:])
