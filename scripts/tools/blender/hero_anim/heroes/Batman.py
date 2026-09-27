# Batman (Justice League) - HeroMotion style "walk" (the model wears a cape and a utility belt).
#   Idle     brooding under the cape: feet planted apart, shoulders squared and slightly hunched, head lowered, fists
#            held out from the hips so the cape falls wide; almost no motion - a slow breath and a slow scan of the room
#   Move     predator prowl: low purposeful strides, torso forward, arms held back and out holding the cape open
#   Special  grapple: aims the grapnel high ahead and fires (a dark line), is yanked up into the air with the legs
#            tucked, lets go and drops into a three-point superhero landing (dust burst), then rises to brood again
from hero_anim.api import *  # noqa: F401,F403

HERO = "Batman"
SPECIAL_EVERY = (11, 20)

GRAY = (96, 100, 110)
BLACK = (24, 24, 30)
YELLOW = (230, 190, 50)
SKIN = (240, 200, 168)
COLORS = palette(Head=BLACK, UpperTorso=GRAY, LowerTorso=GRAY, Arms=GRAY, Hands=BLACK, Legs=GRAY, LowerLegs=BLACK, Feet=BLACK)
EXTRAS = [
    extra("Head", "cone", size=(0.22, 0.5, 0.22), offset=(0.34, 0.55, 0), color=BLACK),
    extra("Head", "cone", size=(0.22, 0.5, 0.22), offset=(-0.34, 0.55, 0), color=BLACK),
    extra("Head", "box", size=(0.8, 0.36, 0.1), offset=(0, -0.3, -0.56), color=SKIN),
    extra("Head", "box", size=(0.5, 0.08, 0.06), offset=(0, 0.1, -0.62), color=(235, 235, 240)),
    extra("UpperTorso", "box", size=(0.9, 0.3, 0.08), offset=(0, 0.25, -0.52), color=BLACK),
    extra("LowerTorso", "box", size=(2.06, 0.26, 1.06), offset=(0, 0.02, 0), color=YELLOW),
    # the cape (the model's cape is welded to the UpperTorso)
    extra("UpperTorso", "box", size=(2.5, 3.9, 0.12), offset=(0, -1.25, 0.64), rot=(-6, 0, 0), color=BLACK),
    extra("UpperTorso", "box", size=(2.1, 0.3, 1.06), offset=(0, 0.72, 0.02), color=BLACK),
]

# ------------------------------------------------------------------------------------------------ Idle
FEET = {"Left": (-0.72, 0.252, 0.0), "Right": (0.72, 0.252, 0.06)}
BROOD = plant_feet({"Root": (-2, 0, 0), "RootOffset": (0, -0.08, 0), "Waist": (-6, 0, 0), "Neck": (-10, 0, 0)},
                   feet=FEET, knee_hint=(0.3, 0, -1))
BROOD.update(aim_arm("Right", down=1.0, out=0.3, back=0.08, elbow=12, twist=-20, wrist=(0, 0, 6)))
BROOD.update(aim_arm("Left", down=1.0, out=0.3, back=0.08, elbow=12, twist=20, wrist=(0, 0, -6)))
BROOD_IN = add(BROOD, {"Waist": (2, 0, 0), "RootOffset": (0, 0.02, 0), "RightShoulder": (0, 0, 2), "LeftShoulder": (0, 0, -2)})
SCAN_L = add(BROOD, {"Neck": (2, 32, 0), "Waist": (0, 4, 0)})
SCAN_R = add(BROOD, {"Neck": (2, -30, 0), "Waist": (0, -4, 0)})

IDLE = clip("Idle", 5.2, {
    0.0: BROOD,
    1.2: BROOD_IN,
    2.2: SCAN_L,
    3.1: SCAN_L,
    4.1: SCAN_R,
})

# ------------------------------------------------------------------------------------------------ Move: prowl
PROWL = walk_cycle(length=1.0, stride=34.0, knee=46.0, arm=16.0, bounce=0.06)
for _p in PROWL.values():
    x, y, z = _p.get("Root", (0, 0, 0))
    _p["Root"] = (x - 10, y, z)
    _p["RootOffset"] = add({"RootOffset": _p.get("RootOffset", (0, 0, 0))}, {"RootOffset": (0, -0.16, 0)})["RootOffset"]
    _p["Waist"] = add({"Waist": _p.get("Waist", (0, 0, 0))}, {"Waist": (-4, 0, 0)})["Waist"]
    _p["Neck"] = (8, 0, 0)
    for _s in ("Right", "Left"):
        x, y, z = _p.get(_s + "Shoulder", (0, 0, 0))
        _p[_s + "Shoulder"] = (x * 0.6 - 16, y, z + (26 if _s == "Right" else -26))
        _p[_s + "Elbow"] = (18, 0, 0)
MOVE = clip("Move", 1.0, PROWL, speed="auto")

# ------------------------------------------------------------------------------------------------ Special: grapple
ANCHOR = (1.6, 17.0, -9.0)
AIM = plant_feet({"Root": (4, 10, 0), "RootOffset": (0, -0.2, 0), "Waist": (6, 6, 0), "Neck": (26, -6, 0)},
                 feet=FEET, knee_hint=(0.3, 0, -1))
AIM.update(aim_arm("Left", down=1.0, out=0.45, back=0.2, elbow=20))
AIM = aim_arm_at(AIM, "Right", ANCHOR, wrist=(30, 0, 0))
AIM["ease"] = "quart_out"
FIRE = add(AIM, {"RootOffset": (0, -0.05, 0.05), "RightShoulder": (6, 0, 0)})
FIRE["ease"] = "quad_in"


def _hang(lift, tuck):
    p = {"Root": (-10, 0, 0), "RootOffset": (0, lift, -0.4 * lift / 3.0), "Waist": (4, 0, 0), "Neck": (18, 0, 0)}
    p.update(aim_leg("Right", down=1.0, forward=0.3 + tuck * 0.5, knee=40 + tuck * 50, ankle=(-30, 0, 0)))
    p.update(aim_leg("Left", down=1.0, forward=0.15 + tuck * 0.5, knee=60 + tuck * 40, ankle=(-30, 0, 0)))
    p.update(aim_arm("Left", out=1.0, down=0.5, back=0.3, elbow=30))
    return aim_arm_at(p, "Right", ANCHOR, wrist=(30, 0, 0))


YANK = _hang(1.6, 0.4)
YANK["ease"] = "quad_out"
TOP = _hang(3.0, 1.0)
TOP["ease"] = "quad_in"
DROP = merge(_hang(1.4, 0.6), aim_arm("Right", out=1.0, up=0.2, elbow=20), aim_arm("Left", out=1.0, up=0.2, elbow=20))
DROP["ease"] = "quad_in"
LAND = plant_feet({"Root": (-30, 6, 0), "RootOffset": (0, -1.2, 0.1), "Waist": (-10, 4, 0), "Neck": (34, -4, 0)},
                  feet={"Left": (-0.7, 0.252, -0.7), "Right": (0.62, 0.252, 0.95)}, knee_hint=(0.4, 0, -1))
LAND = reach(LAND, "Left", (-0.5, 0.22, -1.35), elbow_hint=(-1.0, 0.3, 0.3), wrist=(-30, 0, 0))
LAND.update(aim_arm("Right", out=1.0, back=0.7, up=0.15, elbow=18))
LAND["ease"] = "quad_out"
LAND_HOLD = add(LAND, {"RootOffset": (0, 0.05, 0), "Neck": (4, 0, 0)})

SPECIAL = clip("Special", 4.0, {
    0.0: BROOD,
    0.45: AIM,
    0.62: FIRE,
    0.9: YANK,
    1.35: TOP,
    1.75: DROP,
    1.95: LAND,
    2.8: LAND_HOLD,
    4.0: BROOD,
}, loop=False, effects=[
    web("RightHand", anchor=ANCHOR, t0=0.62, t1=1.5, color=(52, 54, 62), width=0.08),
    burst("RightHand", 0.62, color=(200, 200, 210), count=12, speed=10),
    burst("LeftHand", 1.95, color=(160, 150, 130), count=40, speed=14),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.95}
CAMERAS = {"Special": "wide"}
