# Wonder Woman (Justice League) - HeroMotion style "walk" + gold Glitter.
#   Idle     Amazon guard: wide warrior stance, both bracers crossed in an X in front of the face; steady breathing and
#            a deflection - the bracers snap tighter with a spark (burst) as if a bullet just rang off them
#   Move     warrior's stride: upright, chest proud, long confident steps with strong fist swings
#   Special  Lasso of Truth: whirls the golden lasso over her head (a gold rope sweeping round), casts it forward (the
#            rope shoots out), braces and hauls it back with both hands, then returns to the bracer guard
from hero_anim.api import *  # noqa: F401,F403
from hero_anim.heroes._avjl import ring

HERO = "WonderWoman"
SPECIAL_EVERY = (10, 18)

RED = (186, 26, 36)
BLUE = (34, 52, 146)
GOLD = (240, 196, 66)
SKIN = (234, 184, 146)
SILVER = (208, 210, 220)
HAIR = (26, 20, 18)
LASSO = (255, 214, 90)
COLORS = palette(Head=SKIN, UpperTorso=RED, LowerTorso=BLUE, UpperArms=SKIN, LowerArms=SILVER, Hands=SKIN,
                 UpperLegs=SKIN, LowerLegs=RED, Feet=RED)
EXTRAS = [
    extra("Head", "box", size=(1.34, 1.9, 0.56), offset=(0, -0.35, 0.36), color=HAIR),
    extra("Head", "box", size=(1.32, 0.34, 1.26), offset=(0, 0.5, 0.04), color=HAIR),
    extra("Head", "box", size=(1.24, 0.14, 1.24), offset=(0, 0.32, 0), color=GOLD),
    extra("Head", "cone", size=(0.26, 0.3, 0.1), offset=(0, 0.3, -0.64), color=(220, 30, 40)),
    extra("UpperTorso", "box", size=(1.4, 0.3, 0.1), offset=(0, 0.3, -0.52), rot=(0, 0, 0), color=GOLD),
    extra("UpperTorso", "box", size=(2.04, 0.16, 1.04), offset=(0, -0.72, 0), color=GOLD),
    # the coiled golden lasso on the right hip (preview only: the model has no lasso part, the Special draws the rope)
    extra("LowerTorso", "sphere", size=(0.26, 0.8, 0.8), offset=(1.08, -0.2, 0.0), color=LASSO),
]

# ------------------------------------------------------------------------------------------------ Idle
FEET = {"Left": (-0.8, 0.252, -0.45), "Right": (0.8, 0.252, 0.35)}
STANCE = plant_feet({"Root": (-4, -10, 0), "RootOffset": (0, -0.3, 0), "Waist": (-2, -4, 0), "Neck": (-2, 14, 0)},
                    feet=FEET, knee_hint=(0.7, 0, -1))
# bracers crossed at the wrists in front of the face, elbows out
CROSS = reach(STANCE, "Right", (-0.14, 3.5, -1.12), elbow_hint=(0.5, -1.0, -0.1), wrist=(30, 0, 0))
CROSS = reach(CROSS, "Left", (0.14, 3.62, -1.26), elbow_hint=(-0.5, -1.0, -0.1), wrist=(30, 0, 0))
CROSS_IN = add(CROSS, {"Waist": (3, 0, 0), "RootOffset": (0, 0.04, 0)})
CLANG = add(CROSS, {"Root": (5, 0, 0), "RootOffset": (0, -0.05, 0.12), "Neck": (-4, 0, 0), "RightElbow": (6, 0, 0), "LeftElbow": (6, 0, 0)})
CLANG["ease"] = "quad_out"
_pre = dict(CROSS_IN)
_pre["ease"] = "quint_in"

IDLE = clip("Idle", 4.0, {
    0.0: CROSS,
    1.3: CROSS_IN,
    2.3: _pre,
    2.42: CLANG,
    3.0: merge(CROSS, {"Neck": (-2, 22, 0)}),
}, effects=[burst("Both", 2.42, color=(255, 240, 170), count=18, speed=12)])

# ------------------------------------------------------------------------------------------------ Move: warrior stride
STRIDE = walk_cycle(length=0.95, stride=36.0, knee=40.0, arm=36.0, bounce=0.1)
for _p in STRIDE.values():
    _p["Neck"] = (2, 0, 0)
    _p["Waist"] = add({"Waist": _p.get("Waist", (0, 0, 0))}, {"Waist": (4, 0, 0)})["Waist"]
    for _s in ("Right", "Left"):
        x, y, z = _p.get(_s + "Shoulder", (0, 0, 0))
        _p[_s + "Shoulder"] = (x, y, z + (6 if _s == "Right" else -6))
        _p[_s + "Elbow"] = (max(_p.get(_s + "Elbow", (0, 0, 0))[0], 22.0), 0, 0)
MOVE = clip("Move", 0.95, STRIDE, speed="auto")

# ------------------------------------------------------------------------------------------------ Special: lasso
WHIRL = plant_feet({"Root": (0, 8, 0), "RootOffset": (0, -0.22, 0), "Waist": (4, 6, 0), "Neck": (12, -6, 0)},
                   feet=FEET, knee_hint=(0.7, 0, -1))
WHIRL.update(aim_arm("Left", down=1.0, out=0.45, forward=0.3, elbow=40, twist=30))
_whirl = {}
for _i, _a in enumerate((0, 90, 180, 270, 360, 450, 540, 630, 720)):
    _k = merge(WHIRL, aim_arm("Right", up=1.0, out=0.35, elbow=35, twist=-_a))
    _k["ease"] = "linear"
    _whirl[round(0.5 + 0.12 * _i, 3)] = _k
CAST = plant_feet({"Root": (-12, -16, 0), "RootOffset": (0, -0.4, -0.4), "Waist": (-6, -10, 0), "Neck": (8, 22, 0)},
                  feet={"Left": (-0.8, 0.252, -1.05), "Right": (0.8, 0.252, 0.45)}, knee_hint=(0.6, 0, -1))
CAST.update(aim_arm("Right", forward=1.0, up=0.1, elbow=4))
CAST.update(aim_arm("Left", back=0.6, out=0.7, down=0.3, elbow=30))
CAST["ease"] = "quart_out"
HAUL = plant_feet({"Root": (14, 8, 0), "RootOffset": (0, -0.55, 0.3), "Waist": (8, 6, 0), "Neck": (-6, 4, 0)},
                  feet={"Left": (-0.8, 0.252, -0.85), "Right": (0.8, 0.252, 0.55)}, knee_hint=(0.6, 0, -1))
HAUL = reach(HAUL, "Right", (0.35, 3.0, -0.4), elbow_hint=(1.0, -0.3, 0.6), wrist=(-20, 0, 0))
HAUL = reach(HAUL, "Left", (-0.1, 3.05, -1.05), elbow_hint=(-1.0, -0.4, 0.3), wrist=(-20, 0, 0))
HAUL["ease"] = "quad_inout"
HAUL2 = add(HAUL, {"Root": (4, 0, 0), "RootOffset": (0, -0.04, 0.12), "RightShoulder": (-10, 0, 0)})

_keys = {0.0: CROSS, 0.4: merge(WHIRL, aim_arm("Right", up=1.0, out=0.35, elbow=35), {"ease": "quad_out"})}
_keys.update(_whirl)
_keys[1.72] = merge(_whirl[1.46], {"ease": "quint_in"})
_keys[1.86] = CAST
_keys[2.3] = HAUL
_keys[2.65] = HAUL2
_keys[3.6] = CROSS
_rope = (0.9, 2.9, -8.0)
SPECIAL = clip("Special", 3.6, _keys, loop=False, effects=ring("RightHand", (1.0, 6.3, 0.2), 1.8, 0.5, 1.46, n=8, color=LASSO, width=0.1, turns=2.0) + [
    web("RightHand", anchor=_rope, t0=1.86, t1=2.95, color=LASSO, width=0.12),
    burst("RightHand", 1.86, color=(255, 230, 140), count=26, speed=12),
    accent(boost=3.0, t0=0.4, t1=2.9),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.86}
