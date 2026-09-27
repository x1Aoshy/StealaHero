# Krillin (Dragon Ball, Common) - HeroMotion style "walk" (see open issue: he is a Z fighter flyer; the Move clip
# owns its own lift, motion(lift=0), so it reads as flight under "walk" and stays right under "float").
#   Idle     Turtle School stance: low and wide, open left hand leading, right fist chambered, springing on the
#            balls of his feet, a quick glance around
#   Move     low Z-fighter flight: tilted forward, fists swept back, one knee tucked (lifted off the ground)
#   Special  Destructo Disc: right palm raised flat to the sky, the disc spins up above it and grows, a wind-up
#            behind the head and a side-arm throw - "KIENZAN!"
from hero_anim.api import *  # noqa: F401,F403

HERO = "Krillin"
SPECIAL_EVERY = (8, 15)

ORANGE = (240, 118, 28)
BLUE = (34, 58, 168)
SKIN = (246, 204, 164)
COLORS = palette(Torso=ORANGE, LowerTorso=BLUE, UpperArms=ORANGE, LowerArms=SKIN, Hands=SKIN, Legs=ORANGE, Feet=BLUE,
                 Head=SKIN)
EXTRAS = [
    # the six incense dots on the bald head
    extra("Head", "box", size=(0.1, 0.1, 0.1), offset=(-0.2, 0.5, -0.32), color=(40, 30, 30)),
    extra("Head", "box", size=(0.1, 0.1, 0.1), offset=(0.0, 0.5, -0.36), color=(40, 30, 30)),
    extra("Head", "box", size=(0.1, 0.1, 0.1), offset=(0.2, 0.5, -0.32), color=(40, 30, 30)),
    extra("Head", "box", size=(0.1, 0.1, 0.1), offset=(-0.2, 0.52, -0.08), color=(40, 30, 30)),
    extra("Head", "box", size=(0.1, 0.1, 0.1), offset=(0.0, 0.52, -0.1), color=(40, 30, 30)),
    extra("Head", "box", size=(0.1, 0.1, 0.1), offset=(0.2, 0.52, -0.08), color=(40, 30, 30)),
    # blue undershirt collar + wristbands
    extra("UpperTorso", "box", size=(0.9, 0.35, 1.04), offset=(0, 0.55, 0), color=BLUE),
    extra("LeftLowerArm", "box", size=(1.06, 0.3, 1.06), offset=(0, -0.35, 0), color=BLUE),
    extra("RightLowerArm", "box", size=(1.06, 0.3, 1.06), offset=(0, -0.35, 0), color=BLUE),
]

# ------------------------------------------------------------------------------------------------ Idle
FEET = {"Left": (-0.85, 0.252, -0.45), "Right": (0.85, 0.252, 0.4)}


def stance(drop=0.45, look=0.0):
    p = plant_feet({"Root": (-6, -16, 0), "RootOffset": (0, -drop, 0), "Waist": (-4, -6, 0), "Neck": (-2, 22 + look, 0)},
                   FEET, knee_hint=(0.7, 0.0, -1.0))
    p = reach(p, "Left", (-1.2, 3.75 - drop, -1.45), elbow_hint=(-1.0, -1.0, 0.0), wrist=(-45, 0, -15))
    p = reach(p, "Right", (0.95, 2.7 - drop, 0.2), elbow_hint=(1.0, 0.0, 1.0))
    return p


LOW = stance(0.5)
HIGH = stance(0.32)
LOW["ease"] = "quad_out"
HIGH["ease"] = "quad_in"

IDLE = clip("Idle", 3.2, {
    0.0: LOW,
    0.4: HIGH,
    0.8: LOW,
    1.2: HIGH,
    1.6: merge(stance(0.48, look=-35), {"ease": "quart_out"}),
    2.4: stance(0.42, look=-30),
    2.8: HIGH,
})

# ------------------------------------------------------------------------------------------------ Move: flight
FLY = fly_saiyan(lead=None, tilt=58)
FLY["RootOffset"] = (0, 1.5, 0)
FLY_B = add(FLY, {"Root": (3, 0, 0), "RootOffset": (0, 0.14, 0), "RightHip": (-6, 0, 0), "LeftHip": (8, 0, 0),
                  "LeftKnee": (-10, 0, 0), "RightShoulder": (-6, 0, 0), "LeftShoulder": (-6, 0, 0)})

MOVE = clip("Move", 1.0, {
    0.0: FLY,
    0.5: FLY_B,
}, motion=motion(lift=0.0, lean=0.5), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: Destructo Disc
BASE = plant_feet({"Root": (-2, 0, 0), "RootOffset": (0, -0.3, 0), "Waist": (4, 0, 0), "Neck": (14, 0, 0)},
                  {"Left": (-0.8, 0.252, -0.2), "Right": (0.8, 0.252, 0.2)}, knee_hint=(0.5, 0.0, -1.0))
RAISE = merge(BASE, aim_arm("Right", up=1.0, out=0.08, wrist=(0, 0, 0), twist=0),
              aim_arm("Left", down=1.0, out=0.35, forward=0.2, elbow=60, twist=20))
RAISE["ease"] = "back_out"
RAISE_HOLD = add(RAISE, {"Neck": (6, 0, 0), "Waist": (2, 0, 0), "RootOffset": (0, -0.04, 0)})

WIND = plant_feet({"Root": (4, -30, 0), "RootOffset": (0, -0.4, 0.1), "Waist": (4, -24, 0), "Neck": (0, 44, 0)},
                  {"Left": (-0.85, 0.252, -0.5), "Right": (0.85, 0.252, 0.45)}, knee_hint=(0.5, 0.0, -1.0))
WIND.update(aim_arm("Right", out=0.8, back=0.7, up=0.5, elbow=70, twist=-30))
WIND.update(aim_arm("Left", forward=1.0, out=0.3, up=0.1, elbow=15))
WIND["ease"] = "quad_in"

THROW = plant_feet({"Root": (-12, 34, 0), "RootOffset": (0, -0.5, -0.3), "Waist": (-8, 24, 0), "Neck": (4, -40, 0)},
                   {"Left": (-0.85, 0.252, -0.75), "Right": (0.85, 0.252, 0.5)}, knee_hint=(0.5, 0.0, -1.0))
THROW.update(aim_arm("Right", forward=1.0, out=0.15, down=0.1, elbow=4, wrist=(0, 0, 0)))
THROW.update(aim_arm("Left", back=0.6, out=1.0, down=0.3, elbow=30))
THROW["ease"] = "quart_out"
FOLLOW = add(THROW, {"Waist": (-4, 6, 0), "RootOffset": (0, -0.05, 0)})

SPECIAL = clip("Special", 3.6, {
    0.0: LOW,
    0.45: RAISE,
    1.2: RAISE_HOLD,
    1.8: add(RAISE_HOLD, {"Neck": (2, 0, 0)}),
    2.15: WIND,
    2.4: THROW,
    2.9: FOLLOW,
    3.6: LOW,
}, loop=False, effects=[
    charge("RightHand", 0.45, 1.2, color=(255, 214, 90), size=0.7),
    charge("RightHand", 1.2, 2.4, color=(255, 236, 140), size=1.5),
    burst("RightHand", 2.42, color=(255, 226, 110), count=40, speed=24),
    accent(boost=2.5, t0=0.4, t1=2.5),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.8}
CAMERAS = {"Move": "side", "Special": "front34"}
