# Goku (Dragon Ball, Mythic) - HeroMotion style "float" + gold Aura.
#   Idle     mid-air Turtle School stance: body turned, open left hand leading, right fist chambered, one knee up;
#            a boxer's ready bounce and a cocky glance around (the hover / bob comes from HeroMotion)
#   Move     Superman-style flight: body flat out, right fist punching ahead, left arm along the body, legs trailing
#            with a slow flutter and a banking roll
#   Special  Kamehameha: "Ka-me-ha-me" charge cupped at the right hip (blue orb growing), "HA!" palms thrust ahead,
#            beam recoil, back to the stance
from hero_anim.api import *  # noqa: F401,F403

HERO = "Goku"
SPECIAL_EVERY = (9, 16)

ORANGE = (240, 118, 28)
BLUE = (34, 58, 168)
SKIN = (246, 204, 164)
HAIR = (18, 18, 24)
COLORS = palette(Torso=ORANGE, LowerTorso=BLUE, UpperArms=ORANGE, LowerArms=SKIN, Hands=SKIN, Legs=ORANGE, Feet=BLUE,
                 Head=SKIN)
EXTRAS = [
    # the wild spiky hair: a crown of spikes + side spikes + the fringe
    extra("Head", "spikes", size=(0.8, 1.35, 0.8), offset=(0, 0.3, 0.15), rot=(-12, 0, 0), color=HAIR),
    extra("Head", "spikes", size=(0.6, 1.0, 0.6), offset=(0.45, 0.2, 0.1), rot=(0, 0, -55), color=HAIR),
    extra("Head", "spikes", size=(0.6, 1.0, 0.6), offset=(-0.45, 0.2, 0.1), rot=(0, 0, 55), color=HAIR),
    extra("Head", "box", size=(1.2, 0.3, 1.15), offset=(0, 0.5, 0.05), color=HAIR),
    # blue undershirt collar + wristbands
    extra("UpperTorso", "box", size=(0.9, 0.35, 1.04), offset=(0, 0.55, 0), color=BLUE),
    extra("LeftLowerArm", "box", size=(1.06, 0.3, 1.06), offset=(0, -0.35, 0), color=BLUE),
    extra("RightLowerArm", "box", size=(1.06, 0.3, 1.06), offset=(0, -0.35, 0), color=BLUE),
]

# ------------------------------------------------------------------------------------------------ Idle
HOVER_LEGS = merge(aim_leg("Left", down=1.0, forward=0.75, knee=78, ankle=(-35, 0, 0)),
                   aim_leg("Right", down=1.0, back=0.12, knee=28, ankle=(-45, 0, 0)))


def stance(bounce=0.0, look=0.0):
    p = merge({"Root": (-6, -16, 0), "RootOffset": (0, 0.35 + bounce, 0), "Waist": (-4, -6, 0), "Neck": (-4, 22 + look, 0)},
              HOVER_LEGS)
    p = reach(p, "Left", (-1.3, 3.85 + bounce, -1.45), elbow_hint=(-1.0, -1.0, 0.0), wrist=(-45, 0, -15))
    p = reach(p, "Right", (0.95, 2.75 + bounce, 0.2), elbow_hint=(1.0, 0.0, 1.0))
    return p


STANCE = stance()
STANCE_UP = add(stance(0.12), {"LeftHip": (6, 0, 0), "LeftKnee": (-8, 0, 0), "RightKnee": (6, 0, 0)})
STANCE_LOOK = stance(0.04, look=-38)

IDLE = clip("Idle", 3.6, {
    0.0: STANCE,
    0.6: STANCE_UP,
    1.2: STANCE,
    1.8: merge(STANCE_UP, {"ease": "quart_out"}),
    2.4: STANCE_LOOK,
    3.0: STANCE_UP,
})

# ------------------------------------------------------------------------------------------------ Move: flight
FLY = fly_superman("Right")
FLY.update({"Root": (-76, 0, 0), "RootOffset": (0, 1.1, 0), "Neck": (48, 0, 0)})
FLY.update(aim_arm("Right", up=1.0, inward=0.08, wrist=(0, 0, 0)))
FLY.update(aim_leg("Left", down=1.0, back=0.05, knee=22, ankle=(-45, 0, 0)))
FLY_A = add(FLY, {"Root": (0, 0, 6), "LeftHip": (-6, 0, 0), "RightHip": (4, 0, 0)})
FLY_B = add(FLY, {"Root": (3, 0, -6), "RootOffset": (0, 0.12, 0), "LeftHip": (6, 0, 0), "LeftKnee": (-14, 0, 0),
                  "RightHip": (-5, 0, 0), "LeftShoulder": (-8, 0, 0)})

MOVE = clip("Move", 1.3, {
    0.0: FLY_A,
    0.65: FLY_B,
}, motion=motion(lift=1.0, lean=0.25), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: Kamehameha
FEET_WIDE = {"Left": (-0.95, 0.252, -0.35), "Right": (0.9, 0.252, 0.45)}


def kame_charge(drop=0.45, twist=55.0):
    base = {"Root": (-6, -18, 0), "RootOffset": (0, -drop, 0), "Waist": (0, -twist, 0), "Neck": (-4, twist - 4, 0)}
    base = plant_feet(base, FEET_WIDE, knee_hint=(0.6, 0.0, -1.0))
    p = reach(base, "Right", (0.95, 2.6 - drop, 0.35), elbow_hint=(0.6, -0.5, 1.0), wrist=(0, 0, 30))
    p = reach(p, "Left", (0.78, 2.8 - drop, 0.12), elbow_hint=(-0.3, -0.5, 1.0), wrist=(0, 0, -30))
    return p


def kame_fire(drop=0.55, push=0.0):
    base = {"Root": (-4, 0, 0), "RootOffset": (0, -drop, -push), "Waist": (-8, 0, 0), "Neck": (4, 0, 0)}
    base = plant_feet(base, {"Left": (-0.95, 0.252, -0.55), "Right": (0.95, 0.252, 0.55)}, knee_hint=(0.6, 0.0, -1.0))
    return merge(base, thrust_palms())


CHARGE = kame_charge()
CHARGE_DEEP = add(kame_charge(0.55, 62), {"Neck": (6, 0, 0)})
FIRE = merge(kame_fire(0.55, 0.15), {"ease": "quart_out"})
RECOIL = kame_fire(0.5, -0.2)

SPECIAL = clip("Special", 4.4, {
    0.0: STANCE,
    0.55: merge(CHARGE, {"ease": "sine_inout"}),
    1.7: CHARGE_DEEP,
    2.55: add(CHARGE_DEEP, {"Waist": (0, -4, 0), "RootOffset": (0, -0.05, 0)}),
    2.8: FIRE,
    3.55: RECOIL,
    4.4: STANCE,
}, loop=False, effects=[
    charge("Both", 0.5, 2.8, color=(110, 190, 255), size=0.9),
    charge("Both", 2.8, 3.7, color=(210, 240, 255), size=1.8),
    burst("Both", 2.82, color=(140, 210, 255), count=45, speed=20),
    accent(boost=3.0, t0=0.4, t1=3.8),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 2.8}
CAMERAS = {"Move": "side", "Special": "front"}
