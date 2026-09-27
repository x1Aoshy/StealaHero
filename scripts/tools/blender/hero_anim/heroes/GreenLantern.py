# Green Lantern (Justice League) - HeroMotion style "float" + green Aura.
#   Idle     floating ready: legs loose, the ring fist raised forward at chest height (the ring glows green), the free
#            hand open at his side; calm breathing, the fist turning the ring to the light
#   Move     ring-led flight: body tipped forward, the ring fist punched straight ahead (glowing), the free arm tucked
#            back, legs trailing
#   Special  construct: "In brightest day..." - the ring fist raised to the face while the power gathers (charge,
#            Aura x3), then a punch that launches a giant green construct fist (a thick beam + a big glow + burst)
from hero_anim.api import *  # noqa: F401,F403

HERO = "GreenLantern"
SPECIAL_EVERY = (10, 18)

GREEN = (46, 176, 76)
BLACK = (28, 30, 34)
WHITE = (236, 238, 240)
SKIN = (222, 190, 160)
RING = (90, 255, 130)
COLORS = palette(Head=SKIN, UpperTorso=GREEN, LowerTorso=GREEN, Arms=BLACK, Hands=WHITE, Legs=GREEN, Feet=GREEN)
EXTRAS = [
    extra("Head", "box", size=(1.26, 0.3, 1.24), offset=(0, 0.5, 0.04), color=(92, 62, 40)),
    extra("Head", "box", size=(1.04, 0.2, 0.1), offset=(0, 0.14, -0.58), color=(40, 150, 60)),
    extra("UpperTorso", "box", size=(2.04, 0.5, 1.04), offset=(0, 0.56, 0), color=BLACK),
    extra("UpperTorso", "sphere", size=(0.62, 0.62, 0.12), offset=(0, 0.14, -0.52), color=WHITE),
    extra("UpperTorso", "sphere", size=(0.36, 0.36, 0.18), offset=(0, 0.14, -0.52), color=GREEN),
    extra("RightHand", "box", size=(0.3, 0.12, 0.3), offset=(0.52, 0.0, -0.1), color=RING, emissive=True),
]


def _float_legs(k=1.0):
    return merge(aim_leg("Right", down=1.0, forward=0.08 * k, knee=12 * k, ankle=(-30, 0, 0)),
                 aim_leg("Left", down=1.0, back=0.05 * k, knee=28 * k, ankle=(-34, 0, 0)))


# ------------------------------------------------------------------------------------------------ Idle
READY = merge({"Waist": (4, -10, 0), "Neck": (4, 10, 0)}, _float_legs(),
              aim_arm("Right", forward=1.0, down=0.22, out=0.12, elbow=34, twist=-10, wrist=(-10, 0, 0)),
              aim_arm("Left", down=1.0, out=0.38, back=0.1, elbow=18, twist=20, wrist=(0, 0, -10)))
READY_IN = add(READY, {"Waist": (3, 0, 0), "RootOffset": (0, 0.05, 0), "RightShoulder": (4, 0, 0)})
TURN = add(READY, {"RightShoulder": (0, 18, 0), "RightWrist": (0, 0, 16), "Neck": (2, -6, 0)})
IDLE = clip("Idle", 3.8, {0.0: READY, 1.3: READY_IN, 2.5: TURN},
            effects=[charge("RightHand", None, None, color=RING, size=0.4, light=True)])

# ------------------------------------------------------------------------------------------------ Move: ring-led flight
FLY = {"Root": (-62, 0, 0), "RootOffset": (0, 0.5, 0), "Waist": (4, 0, 0), "Neck": (44, 0, 0)}
FLY.update(aim_arm("Right", up=1.0, forward=0.08))
FLY.update(aim_arm("Left", down=1.0, back=0.3, out=0.28, elbow=60, twist=30))
FLY.update(aim_leg("Right", down=1.0, back=0.05, knee=8, ankle=(-40, 0, 0)))
FLY.update(aim_leg("Left", down=1.0, forward=0.1, knee=36, ankle=(-40, 0, 0)))
FLY_B = add(FLY, {"Root": (3, 0, -3), "RootOffset": (0, 0.1, 0), "LeftHip": (6, 0, 0), "LeftKnee": (-8, 0, 0)})
MOVE = clip("Move", 1.3, {0.0: FLY, 0.65: FLY_B}, motion=motion(lift=1.0, lean=0.6), footsteps=False,
            effects=[charge("RightHand", None, None, color=RING, size=0.6, light=True)])

# ------------------------------------------------------------------------------------------------ Special: construct
OATH = merge({"Waist": (8, 0, 0), "Neck": (10, 0, 0), "RootOffset": (0, 0.25, 0)}, _float_legs(0.6))
OATH = reach(OATH, "Right", (0.35, 4.55, -1.0), elbow_hint=(1.0, -0.6, 0.0), wrist=(0, 0, 0))
OATH.update(aim_arm("Left", down=1.0, out=0.5, elbow=30, twist=40))
OATH["ease"] = "back_out"
GATHER = add(OATH, {"Waist": (3, 0, 0), "RootOffset": (0, 0.12, 0), "LeftShoulder": (0, 0, -8), "LeftElbow": (15, 0, 0)})
WIND = merge({"Root": (0, -24, 0), "Waist": (0, -20, 0), "Neck": (6, 40, 0), "RootOffset": (0, 0.35, 0.1)}, _float_legs(1.2),
             aim_arm("Right", back=0.6, out=0.5, down=0.3, elbow=95), aim_arm("Left", forward=1.0, out=0.3, elbow=20))
WIND["ease"] = "quint_in"
PUNCH = merge({"Root": (-14, 22, 0), "Waist": (-6, 16, 0), "Neck": (8, -32, 0), "RootOffset": (0, 0.3, -0.3)},
              aim_arm("Right", forward=1.0, up=0.08), aim_arm("Left", back=0.6, out=0.6, down=0.4, elbow=40),
              aim_leg("Right", down=1.0, back=0.4, knee=24, ankle=(-40, 0, 0)),
              aim_leg("Left", down=1.0, forward=0.3, knee=48, ankle=(-36, 0, 0)))
PUNCH["ease"] = "quart_out"
HOLD = add(PUNCH, {"RootOffset": (0, 0.05, 0.08), "Root": (3, 0, 0)})

SPECIAL = clip("Special", 3.6, {
    0.0: READY,
    0.5: OATH,
    1.2: GATHER,
    1.5: WIND,
    1.68: PUNCH,
    2.4: HOLD,
    3.6: READY,
}, loop=False, effects=[
    charge("RightHand", 0.45, 1.6, color=RING, size=1.0),
    charge("RightHand", 1.68, 2.5, color=RING, size=2.6),
    web("RightHand", anchor=(1.2, 3.6, -18.0), t0=1.7, t1=2.45, color=RING, width=0.9),
    burst("RightHand", 1.68, color=(160, 255, 180), count=46, speed=18),
    accent(boost=3.0, t0=0.45, t1=2.6),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 2.4}
CAMERAS = {"Move": "side34"}
