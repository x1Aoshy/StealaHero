# Gohan (Dragon Ball, Epic) - HeroMotion style "float" + white Aura. Piccolo-style gi, cape and the scholar's glasses.
#   Idle     the scholar afloat: the thinker (knuckles under the chin, elbow propped on the other arm), looks up and
#            pushes his glasses up with one finger, then fists on hips looking over the pen, back to thinking
#   Move     power flight: body tilted hard forward, both arms swept back with open hands, legs straight behind, cape
#            streaming (a slow bank)
#   Special  Masenko: both palms snapped up over the forehead gathering a golden ball, then thrust ahead - "HA!"
from hero_anim.api import *  # noqa: F401,F403

HERO = "Gohan"
SPECIAL_EVERY = (10, 17)

PURPLE = (86, 42, 124)
SASH = (206, 44, 44)
SKIN = (246, 204, 164)
HAIR = (18, 18, 24)
CAPE = (236, 236, 240)
COLORS = palette(Torso=PURPLE, LowerTorso=SASH, UpperArms=PURPLE, LowerArms=SKIN, Hands=SKIN, Legs=PURPLE,
                 Feet=(120, 72, 42), Head=SKIN)
EXTRAS = [
    extra("Head", "spikes", size=(0.7, 1.1, 0.7), offset=(0, 0.32, 0.12), rot=(-14, 0, 0), color=HAIR),
    extra("Head", "box", size=(1.2, 0.3, 1.15), offset=(0, 0.5, 0.05), color=HAIR),
    # glasses
    extra("Head", "box", size=(1.1, 0.2, 0.06), offset=(0, 0.1, -0.54), color=(20, 20, 26)),
    # cape + shoulder pads
    extra("UpperTorso", "box", size=(2.2, 2.6, 0.14), offset=(0, -0.45, 0.6), rot=(-6, 0, 0), color=CAPE),
    extra("UpperTorso", "box", size=(2.5, 0.28, 1.2), offset=(0, 0.78, 0), color=CAPE),
]

# ------------------------------------------------------------------------------------------------ Idle: the scholar
LEGS = merge(aim_leg("Right", down=1.0, forward=0.15, knee=22, ankle=(-35, 0, 0)),
             aim_leg("Left", down=1.0, back=0.08, knee=40, ankle=(-40, 0, 0)))
BODY = merge({"RootOffset": (0, 0.3, 0), "Root": (-3, 0, 0)}, LEGS)


def elbow_of(pose, side):
    _, joints = rig().fk(transforms_of(pose))
    return joints[side + "Elbow"][1]


def thinking(head=(-8, 10, 6), chin=(0.12, 3.98, -0.82)):
    """The thinker: right knuckles under the chin, left forearm across the belly propping the right elbow."""
    p = merge(BODY, {"Neck": head, "Waist": (-4, 6, 0)})
    p = reach(p, "Right", chin, elbow_hint=(0.4, -1.0, -0.2), wrist=(-30, 0, 0))
    e = elbow_of(p, "Right")
    return reach(p, "Left", (e[0] - 0.05, e[1] - 0.3, e[2] - 0.1), elbow_hint=(-1.0, -0.6, 0.2), wrist=(0, 0, 0))


THINK = thinking()
THINK_B = thinking(head=(-4, 18, 8), chin=(0.1, 4.02, -0.8))
LOOK_UP = merge(thinking(head=(6, 0, 0)), {"Waist": (2, 0, 0)})
LOOK_UP = reach(LOOK_UP, "Right", (0.32, 4.35, -0.95), elbow_hint=(1.0, -0.6, 0.2), wrist=(-40, 0, 0))
PUSH = reach(merge(LOOK_UP, {"Neck": (10, -6, 0)}), "Right", (0.18, 4.55, -0.78), elbow_hint=(1.0, -0.7, 0.2),
             wrist=(-50, 0, 0))
PUSH["ease"] = "back_out"
GLANCE = merge(BODY, {"Neck": (4, -22, 0), "Waist": (2, -6, 0), "ease": "quad_out"}, fists_on_hips())

IDLE = clip("Idle", 5.6, {
    0.0: THINK,
    1.1: THINK_B,
    2.1: LOOK_UP,
    2.45: PUSH,
    3.0: add(PUSH, {"Neck": (-2, 0, 0)}),
    3.5: GLANCE,
    4.4: add(GLANCE, {"Neck": (0, 30, 0)}),
})
READ = THINK

# ------------------------------------------------------------------------------------------------ Move: power flight
FLY = {"Root": (-66, 0, 0), "RootOffset": (0, 1.0, 0), "Neck": (40, 0, 0), "Waist": (4, 0, 0)}
FLY.update(aim_arm("Right", down=1.0, out=0.42, elbow=4, twist=-30, wrist=(20, 0, 0)))
FLY.update(aim_arm("Left", down=1.0, out=0.42, elbow=4, twist=30, wrist=(20, 0, 0)))
FLY.update(aim_leg("Right", down=1.0, back=0.1, out=0.05, knee=6, ankle=(-45, 0, 0)))
FLY.update(aim_leg("Left", down=1.0, back=0.06, knee=18, ankle=(-45, 0, 0)))
FLY_A = add(FLY, {"Root": (0, 0, 5)})
FLY_B = add(FLY, {"Root": (4, 0, -5), "RootOffset": (0, 0.14, 0), "RightShoulder": (-8, 0, 0), "LeftShoulder": (-8, 0, 0),
                  "LeftKnee": (-10, 0, 0), "RightHip": (-4, 0, 0)})

MOVE = clip("Move", 1.4, {
    0.0: FLY_A,
    0.7: FLY_B,
}, motion=motion(lift=1.0, lean=0.4), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: Masenko
FEET = {"Left": (-0.9, 0.252, -0.3), "Right": (0.9, 0.252, 0.35)}


def masenko_up(drop=0.3, arch=10):
    base = plant_feet({"Root": (4, 0, 0), "RootOffset": (0, -drop, 0), "Waist": (arch, 0, 0), "Neck": (8, 0, 0)}, FEET,
                      knee_hint=(0.5, 0.0, -1.0))
    base.update(aim_arm("Right", up=1.0, inward=0.42, forward=0.2, elbow=18, wrist=(-70, 0, 0)))
    base.update(aim_arm("Left", up=1.0, inward=0.42, forward=0.2, elbow=18, wrist=(-70, 0, 0)))
    return base


def masenko_fire(drop=0.45, push=0.2):
    base = plant_feet({"Root": (-6, 0, 0), "RootOffset": (0, -drop, -push), "Waist": (-6, 0, 0), "Neck": (6, 0, 0)},
                      {"Left": (-0.9, 0.252, -0.55), "Right": (0.9, 0.252, 0.55)}, knee_hint=(0.5, 0.0, -1.0))
    return merge(base, thrust_palms())


UP = merge(masenko_up(), {"ease": "back_out"})
UP_TENSE = masenko_up(0.36, 14)
FIRE = merge(masenko_fire(), {"ease": "quart_out"})
RECOIL = masenko_fire(0.4, -0.15)

SPECIAL = clip("Special", 3.8, {
    0.0: READ,
    0.45: UP,
    1.5: UP_TENSE,
    1.75: add(UP_TENSE, {"Waist": (6, 0, 0), "RightShoulder": (-8, 0, 0), "LeftShoulder": (-8, 0, 0)}),
    1.95: FIRE,
    2.7: RECOIL,
    3.8: READ,
}, loop=False, effects=[
    charge("Both", 0.45, 1.95, color=(255, 226, 80), size=1.1),
    charge("Both", 1.95, 2.8, color=(255, 246, 190), size=1.7),
    burst("Both", 1.97, color=(255, 230, 110), count=45, speed=20),
    accent(boost=3.0, t0=0.4, t1=2.9),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.5}
CAMERAS = {"Move": "side"}
