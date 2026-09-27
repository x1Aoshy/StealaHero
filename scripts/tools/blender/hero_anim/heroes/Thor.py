# Thor (Avengers) - HeroMotion style "float" + continuous blue Sparks.
#   Idle     God of Thunder hovering: chest out, left fist on the hip, Mjolnir hanging from the right fist, legs loose;
#            every loop he whirls the hammer (the forearm spins it round the upper arm twice) and lets it hang again
#   Move     hammer flight: Mjolnir thrown ahead and up (crackling), the arm locked straight as it drags him, body
#            tilted forward, the free arm and the legs trailing, a small tug-and-roll in the pull
#   Special  lightning call: hammer raised to the sky, bolts strike it (flickering beams from above, charge + light,
#            Sparks accent x3.5), then he levels it forward and fires the bolt ahead (beam + burst) and recoils
# The model's cape, hair and beard are welded to the Head, so these clips keep the Neck nearly still (the preview cape
# hangs from the head like in game); the model has no Mjolnir prop (the preview shows it in the right fist).
from hero_anim.api import *  # noqa: F401,F403

HERO = "Thor"
SPECIAL_EVERY = (10, 18)

SKIN = (240, 200, 172)
ARMOR = (58, 62, 74)
DARK = (40, 42, 52)
STEEL = (150, 156, 168)
BLONDE = (196, 158, 86)
BOLT = (196, 228, 255)
COLORS = palette(Head=SKIN, UpperTorso=ARMOR, LowerTorso=DARK, UpperArms=SKIN, LowerArms=(88, 96, 116), Hands=SKIN,
                 Legs=DARK, Feet=(74, 58, 44))
EXTRAS = [
    extra("Head", "box", size=(1.28, 1.1, 0.5), offset=(0, 0.02, 0.38), color=BLONDE),
    extra("Head", "box", size=(1.3, 0.32, 1.26), offset=(0, 0.5, 0.02), color=BLONDE),
    extra("Head", "box", size=(0.92, 0.46, 0.2), offset=(0, -0.42, -0.52), color=BLONDE),
    # the red cape hangs from the head (the model's cape is welded to the Head)
    extra("Head", "box", size=(2.3, 3.1, 0.12), offset=(0, -2.05, 0.62), rot=(-4, 0, 0), color=(150, 22, 28)),
    # the four armour discs
    extra("UpperTorso", "sphere", size=(0.46, 0.46, 0.16), offset=(-0.5, 0.37, -0.52), color=STEEL),
    extra("UpperTorso", "sphere", size=(0.46, 0.46, 0.16), offset=(0.5, 0.37, -0.52), color=STEEL),
    extra("UpperTorso", "sphere", size=(0.32, 0.32, 0.14), offset=(-0.5, -0.5, -0.52), color=STEEL),
    extra("UpperTorso", "sphere", size=(0.32, 0.32, 0.14), offset=(0.5, -0.5, -0.52), color=STEEL),
    # Mjolnir: the handle runs out of the fist along the fingers (hand-local -Y), the head beyond it
    extra("RightHand", "box", size=(0.2, 1.0, 0.2), offset=(0, -0.5, 0), color=(96, 66, 44)),
    extra("RightHand", "box", size=(0.66, 0.64, 1.1), offset=(0, -1.25, 0), color=STEEL),
]

HOLD_HAMMER = aim_arm("Right", down=1.0, out=0.28, forward=0.12, elbow=14, twist=-10)


def _hover_legs(k=1.0):
    return merge(aim_leg("Right", down=1.0, forward=0.12 * k, out=0.05, knee=14 * k, ankle=(-30, 0, 0)),
                 aim_leg("Left", down=1.0, back=0.1 * k, out=0.04, knee=34 * k, ankle=(-36, 0, 0)))


# ------------------------------------------------------------------------------------------------ Idle
_LEFT_HIP = {k: v for k, v in fists_on_hips().items() if k.startswith("Left")}
HOVER = merge({"Waist": (5, 0, 0), "Neck": (3, 0, 0)}, _hover_legs(), _LEFT_HIP, HOLD_HAMMER)
HOVER_IN = add(HOVER, {"Waist": (3, 0, 0), "RootOffset": (0, 0.06, 0), "RightShoulder": (4, 0, 3)})
SPIN_BASE = merge(HOVER, aim_arm("Right", down=1.0, out=0.75, forward=0.3, elbow=82, twist=0))


def _spin(deg):
    return add(SPIN_BASE, {"RightShoulder": (0, deg, 0)})


IDLE_KEYS = {0.0: HOVER, 1.1: HOVER_IN, 1.75: merge(SPIN_BASE, {"ease": "quad_in"})}
for _i in range(1, 9):
    _k = _spin(-90.0 * _i)
    _k["ease"] = "linear"
    IDLE_KEYS[round(1.75 + 0.1 * _i, 3)] = _k
IDLE_KEYS[2.75] = merge(HOVER_IN, {"ease": "back_out"})
IDLE_KEYS[3.7] = add(HOVER, {"Waist": (0, 8, 0), "Neck": (2, 4, 0)})
IDLE = clip("Idle", 4.6, IDLE_KEYS, effects=[charge("RightHand", 1.85, 2.7, color=BOLT, size=0.5, light=True)])

# ------------------------------------------------------------------------------------------------ Move: hammer flight
FLY = {"Root": (-56, 0, 0), "RootOffset": (0, 0.55, 0), "Waist": (6, 0, 0), "Neck": (8, 0, 0)}
FLY.update(aim_arm("Right", up=1.0, forward=0.3, inward=0.05))
FLY.update(aim_arm("Left", down=1.0, back=0.35, out=0.32, elbow=16, twist=20))
FLY.update(aim_leg("Right", down=1.0, back=0.12, knee=6, ankle=(-40, 0, 0)))
FLY.update(aim_leg("Left", down=1.0, forward=0.2, knee=44, ankle=(-40, 0, 0)))
TUG = add(FLY, {"Root": (-4, 0, 4), "RightShoulder": (6, 0, 0), "RootOffset": (0, 0.1, 0), "LeftHip": (6, 0, 0), "LeftKnee": (-10, 0, 0)})
TUG_B = add(FLY, {"Root": (2, 0, -4), "RightShoulder": (-4, 0, 0), "RightHip": (-6, 0, 0)})
MOVE = clip("Move", 1.4, {0.0: FLY, 0.45: TUG, 0.95: TUG_B}, motion=motion(lift=1.0, lean=0.6), footsteps=False,
            effects=[charge("RightHand", None, None, color=BOLT, size=0.45, light=True)])

# ------------------------------------------------------------------------------------------------ Special: lightning
RAISE = merge({"Waist": (8, 0, 0), "Neck": (6, 0, 0), "RootOffset": (0, 0.35, 0)},
              aim_arm("Right", up=1.0, out=0.08), aim_arm("Left", down=1.0, out=0.7, elbow=30, twist=40),
              aim_leg("Right", down=1.0, out=0.3, knee=10, ankle=(-30, 0, 0)),
              aim_leg("Left", down=1.0, out=0.3, knee=18, ankle=(-30, 0, 0)))
RAISE["ease"] = "back_out"
CHARGED = add(RAISE, {"Waist": (4, 0, 0), "LeftElbow": (20, 0, 0), "RootOffset": (0, 0.15, 0), "LeftShoulder": (0, 0, -8)})
LEVEL = merge({"Root": (-12, 18, 0), "Waist": (-4, 10, 0), "Neck": (4, -6, 0), "RootOffset": (0, 0.3, 0)},
              aim_arm("Right", forward=1.0, up=0.12), aim_arm("Left", down=1.0, back=0.4, out=0.5, elbow=25),
              aim_leg("Right", down=1.0, back=0.35, knee=20, ankle=(-30, 0, 0)),
              aim_leg("Left", down=1.0, forward=0.4, knee=50, ankle=(-30, 0, 0)))
LEVEL["ease"] = "quart_out"
RECOIL = add(LEVEL, {"Root": (10, 0, 0), "RootOffset": (0, 0.1, 0.35), "RightShoulder": (12, 0, 0)})

_SKY = [(1.8, 30.0, 3.0), (-0.5, 30.0, -2.0), (3.0, 30.0, -1.0), (0.5, 30.0, 4.0)]
SPECIAL = clip("Special", 3.6, {
    0.0: HOVER,
    0.5: RAISE,
    1.2: CHARGED,
    1.62: merge(CHARGED, {"ease": "quint_in"}),
    1.78: LEVEL,
    2.2: RECOIL,
    3.6: HOVER,
}, loop=False, effects=[
    web("RightHand", anchor=_SKY[0], t0=0.62, t1=0.76, color=BOLT, width=0.34),
    web("RightHand", anchor=_SKY[1], t0=0.82, t1=0.96, color=BOLT, width=0.3),
    web("RightHand", anchor=_SKY[2], t0=1.02, t1=1.18, color=BOLT, width=0.38),
    web("RightHand", anchor=_SKY[3], t0=1.24, t1=1.44, color=BOLT, width=0.3),
    charge("RightHand", 0.6, 1.9, color=BOLT, size=1.3),
    web("RightHand", anchor=(1.8, 3.4, -24.0), t0=1.78, t1=2.25, color=BOLT, width=0.5),
    burst("RightHand", 1.78, color=(220, 240, 255), count=40, speed=20),
    accent(boost=3.5, t0=0.5, t1=2.6),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 2.05, "Move": 0.0, "Special": 1.78}
CAMERAS = {"Move": "side34"}
