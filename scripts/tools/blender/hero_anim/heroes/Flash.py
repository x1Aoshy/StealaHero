# The Flash (Justice League) - HeroMotion style "dash" (bursts + yellow / red Sparks).
#   Idle     can't stand still: hands on the hips, weight on the left leg, the right foot tapping at blur speed, a quick
#            bounce on the toes and restless glances left and right
#   Move     lean-forward sprint: torso pitched hard into the run, knees driving high, knife-hand arms pumping - a short
#            fast loop that the dash bursts speed up further
#   Special  Speed Force: drops into a sprinter's set position, vibrates (phasing) while lightning crackles in both
#            hands, explodes out of the blocks in a frozen stride (burst) and skids to a braking stop
from hero_anim.api import *  # noqa: F401,F403

HERO = "Flash"
SPECIAL_EVERY = (9, 15)

RED = (200, 26, 30)
GOLD = (246, 204, 40)
BOLT = (255, 226, 70)
COLORS = palette(Head=RED, Torso=RED, Arms=RED, Hands=RED, Legs=RED, Feet=GOLD)
EXTRAS = [
    # cowl lightning "ears", the open face, the emblem and the belt
    extra("Head", "cone", size=(0.2, 0.62, 0.2), offset=(0.62, 0.12, 0), rot=(0, 0, -62), color=GOLD),
    extra("Head", "cone", size=(0.2, 0.62, 0.2), offset=(-0.62, 0.12, 0), rot=(0, 0, 62), color=GOLD),
    extra("Head", "box", size=(0.86, 0.46, 0.1), offset=(0, -0.28, -0.56), color=(246, 204, 164)),
    extra("UpperTorso", "sphere", size=(0.72, 0.72, 0.12), offset=(0, 0.18, -0.52), color=(245, 245, 245)),
    extra("UpperTorso", "box", size=(0.14, 0.56, 0.16), offset=(0, 0.18, -0.54), rot=(0, 0, 28), color=GOLD),
    extra("LowerTorso", "box", size=(2.04, 0.16, 1.04), offset=(0, 0.08, 0), color=GOLD),
]

# ------------------------------------------------------------------------------------------------ Idle
_HIPS = fists_on_hips()
BASE = plant_feet({"Root": (0, -6, 4), "RootOffset": (0.12, -0.05, 0), "Waist": (2, 4, -3), "Neck": (4, 6, 0)},
                  feet={"Left": (-0.55, 0.252, 0.0), "Right": (0.72, 0.252, -0.3)}, knee_hint=(0.3, 0, -1))
BASE.update(_HIPS)
# the tapping foot: heel planted, toes flick up and slap down
TAP_UP = add(BASE, {"RightAnkle": (40, 0, 0), "RightKnee": (-14, 0, 0), "RightHip": (6, 0, 0)})
TAP_UP["ease"] = "quad_out"
TAP_DN = dict(BASE)
TAP_DN["ease"] = "quad_in"
BOUNCE = add(BASE, {"RootOffset": (0, 0.12, 0), "RightAnkle": (-18, 0, 0), "LeftAnkle": (-14, 0, 0), "Neck": (0, -30, 0)})
BOUNCE["ease"] = "quad_out"
GLANCE = add(BASE, {"Neck": (2, 34, 0), "Waist": (0, 6, 0)})
GLANCE["ease"] = "quart_out"

IDLE_KEYS = {}
for _i in range(4):
    IDLE_KEYS[round(0.16 * _i * 2, 3)] = TAP_DN
    IDLE_KEYS[round(0.16 * (_i * 2 + 1), 3)] = TAP_UP
IDLE_KEYS[1.28] = TAP_DN
IDLE_KEYS[1.5] = BOUNCE
IDLE_KEYS[1.72] = merge(BASE, {"ease": "quad_out"})
IDLE_KEYS[1.95] = GLANCE
IDLE_KEYS[2.45] = merge(GLANCE, {"ease": "quart_out"})
IDLE_KEYS[2.6] = add(BASE, {"Neck": (0, -24, 0)})
IDLE = clip("Idle", 3.0, IDLE_KEYS)

# ------------------------------------------------------------------------------------------------ Move: sprint
# the pelvis leans 22 deg and the chest another 22 on top (a ~45 deg Speed Force lean); the hips are swung forward to
# keep the strides under the body instead of kicking out behind, the head stays up looking down the track
SPRINT = run_cycle(length=0.44, stride=62.0, knee=100.0, arm=80.0, bounce=0.22, lean=22.0)
for _p in SPRINT.values():
    _p["Waist"] = add({"Waist": _p.get("Waist", (0, 0, 0))}, {"Waist": (-22, 0, 0)})["Waist"]
    _p["Neck"] = (40, 0, 0)
    _p["RootOffset"] = add({"RootOffset": _p.get("RootOffset", (0, 0, 0))}, {"RootOffset": (0, -0.34, 0)})["RootOffset"]
    for _s in ("Right", "Left"):
        x, y, z = _p.get(_s + "Hip", (0, 0, 0))
        _p[_s + "Hip"] = (x + 14, y, z)
        _p[_s + "Wrist"] = (-10, 0, 0)
MOVE = clip("Move", 0.44, SPRINT, speed="auto", motion=motion(lift=1.0, lean=0.4))

# ------------------------------------------------------------------------------------------------ Special: Speed Force
SET = plant_feet({"Root": (-70, 0, 0), "RootOffset": (0, -0.5, 0.45), "Waist": (-6, 0, 0), "Neck": (58, 0, 0)},
                 feet={"Left": (-0.5, 0.252, -0.35), "Right": (0.5, 0.252, 1.25)}, knee_hint=(0.2, 0, -1))
SET = reach(SET, "Right", (0.7, 0.2, -1.55), elbow_hint=(1.0, 0.0, 0.3), wrist=(-10, 0, 0))
SET = reach(SET, "Left", (-0.7, 0.2, -1.55), elbow_hint=(-1.0, 0.0, 0.3), wrist=(-10, 0, 0))
SET["ease"] = "quad_out"
SPECIAL_KEYS = {0.0: BASE, 0.4: SET}
for _i in range(8):
    _s = 1 if _i % 2 == 0 else -1
    _k = add(SET, {"Root": (0, 0, 4.0 * _s), "RootOffset": (0.08 * _s, 0.04, 0.0), "Neck": (0, 4.0 * _s, 0)})
    _k["ease"] = "linear"
    SPECIAL_KEYS[round(0.55 + 0.1 * _i, 3)] = _k
_hold = dict(SET)
_hold["ease"] = "quint_in"
SPECIAL_KEYS[1.4] = _hold
LAUNCH = {"Root": (-34, 0, 0), "RootOffset": (0, 0.35, -0.6), "Waist": (-6, 0, 0), "Neck": (30, 0, 0)}
LAUNCH.update(aim_leg("Left", forward=1.0, down=0.3, knee=100, ankle=(-20, 0, 0)))
LAUNCH.update(aim_leg("Right", back=0.9, down=1.0, knee=30, ankle=(-40, 0, 0)))
LAUNCH.update(aim_arm("Right", forward=1.0, up=0.3, elbow=75, wrist=(-10, 0, 0)))
LAUNCH.update(aim_arm("Left", back=1.0, down=0.5, elbow=40, wrist=(-10, 0, 0)))
LAUNCH["ease"] = "quart_out"
SKID = plant_feet({"Root": (18, 22, 0), "RootOffset": (0, -0.35, 0.2), "Waist": (4, 10, 0), "Neck": (0, -26, 0)},
                  feet={"Left": (-0.7, 0.252, -1.2), "Right": (0.7, 0.252, 0.5)}, knee_hint=(0.3, 0, -1))
SKID.update(aim_arm("Right", out=1.0, down=0.3, back=0.3, elbow=20))
SKID.update(aim_arm("Left", out=1.0, down=0.1, forward=0.4, elbow=30))
SKID["ease"] = "back_out"
SPECIAL_KEYS[1.55] = LAUNCH
SPECIAL_KEYS[1.95] = SKID
SPECIAL_KEYS[2.35] = merge(SKID, {"ease": "sine_inout"})
SPECIAL_KEYS[3.0] = BASE
SPECIAL = clip("Special", 3.0, SPECIAL_KEYS, loop=False, effects=[
    charge("Both", 0.5, 1.5, color=BOLT, size=0.9),
    burst("Both", 1.5, color=(255, 236, 120), count=44, speed=22),
    burst("RightHand", 1.97, color=(255, 90, 60), count=24, speed=12),
    accent(boost=3.0, t0=0.5, t1=2.2),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 2.6, "Move": 0.0, "Special": 1.55}
CAMERAS = {"Move": "side", "Special": "side"}
