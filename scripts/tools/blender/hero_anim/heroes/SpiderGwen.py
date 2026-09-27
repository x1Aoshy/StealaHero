# Spider-Gwen (Spider-Verse, Common) - HeroMotion style "bounce" + pink Glitter.
#   Idle     ballerina wall-crawler: low perch on the left leg, right leg stretched out to the side with the toes
#            pointed, left hand down, right hand on the thigh, head bobbing to a drum beat (she is a drummer)
#   Move     ballet web-swing: right web, grand jete split at the bottom of the arc, release into a tucked FRONT FLIP;
#            left web, split again, release into a mid-air PIROUETTE - Web effect per swing, HeroMotion hops off
#            (lift 0) so the swing owns the height, Glitter pumped through the tricks
#   Special  arabesque thwip: rises onto the right leg into an arabesque and web-shoots with the right hand, pirouettes,
#            web-shoots with the left hand in a deep plie, curtsies, drops back into the perch
from hero_anim.api import *  # noqa: F401,F403

HERO = "SpiderGwen"
SPECIAL_EVERY = (8, 15)

WHITE = (240, 240, 246)
BLACK = (30, 30, 38)
PINK = (236, 72, 160)
TEAL = (40, 200, 210)
COLORS = palette(Head=WHITE, UpperTorso=WHITE, LowerTorso=BLACK, UpperArms=WHITE, LowerArms=BLACK, Hands=TEAL,
                 UpperLegs=BLACK, LowerLegs=WHITE, Feet=TEAL)
EXTRAS = [
    # the hood (pink lining peeking out round the white hood)
    extra("Head", "box", size=(1.32, 1.3, 0.08), offset=(0, 0.04, -0.12), color=PINK),
    extra("Head", "box", size=(1.3, 1.28, 0.7), offset=(0, 0.04, 0.26), color=WHITE),
    # big mask eyes: black rims round pale lenses
    extra("Head", "box", size=(0.42, 0.5, 0.06), offset=(-0.27, 0.1, -0.6), rot=(0, 0, -18), color=(20, 20, 26)),
    extra("Head", "box", size=(0.42, 0.5, 0.06), offset=(0.27, 0.1, -0.6), rot=(0, 0, 18), color=(20, 20, 26)),
    extra("Head", "box", size=(0.3, 0.38, 0.06), offset=(-0.27, 0.1, -0.63), rot=(0, 0, -18), color=(215, 235, 255)),
    extra("Head", "box", size=(0.3, 0.38, 0.06), offset=(0.27, 0.1, -0.63), rot=(0, 0, 18), color=(215, 235, 255)),
    # black web shoulders / pink spider
    extra("UpperTorso", "box", size=(2.04, 0.34, 1.04), offset=(0, 0.64, 0), color=BLACK),
    extra("UpperTorso", "box", size=(0.26, 0.5, 0.06), offset=(0, 0.1, -0.52), color=PINK),
]

POINT = (-55, 0, 0)  # ankle: toes pointed (ballet)

# ------------------------------------------------------------------------------------------------ Idle: drummer perch
FEET_PERCH = {"Left": (-0.7, 0.252, -0.2), "Right": (2.05, 0.28, -0.15)}


def perch(bob=0.0, tilt=0.0, turn=0.0):
    """The ballerina perch; bob = head/shoulder beat (0 = down, 1 = up), tilt/turn = head roll/yaw degrees."""
    base = {"Root": (-14, -6, 10), "RootOffset": (-0.3, -1.12 + bob * 0.05, 0.0), "Waist": (-6 + bob * 3, 4, -6),
            "Neck": (20 + bob * 9, turn, tilt + 4)}
    p = plant_feet(base, feet=FEET_PERCH, knee_hint=(1.0, 0.0, -1.0))
    p["RightAnkle"] = add({"RightAnkle": p["RightAnkle"]}, {"RightAnkle": (-45, 0, 0)})["RightAnkle"]
    p = reach(p, "Left", (-0.55, 0.45, -1.35), elbow_hint=(-1.0, 0.3, 0.2), wrist=(-35, 0, 0))
    # right arm follows the stretched leg (ballet line), hand floating over the shin
    p.update(aim_arm("Right", out=1.0, down=0.55 - bob * 0.06, forward=0.2, elbow=12, wrist=(0, 0, 12)))
    return p


BEAT = 0.3
IDLE_KEYS = {}
for i in range(8):
    up = i % 2 == 1
    if i < 4:
        pose = perch(bob=1.0 if up else 0.0)
    elif i < 6:
        pose = perch(bob=1.0 if up else 0.0, tilt=10 if up else 4, turn=18)
    else:
        pose = perch(bob=1.0 if up else 0.0, tilt=-10 if up else -4, turn=-12)
    pose["ease"] = "quad_out" if up else "quad_in"  # snap up on the beat, sink onto the next one
    IDLE_KEYS[round(i * BEAT, 3)] = pose
IDLE = clip("Idle", 8 * BEAT, IDLE_KEYS)

# ------------------------------------------------------------------------------------------------ Move: ballet web-swing
ANCHOR_R = (2.0, 15.0, -6.5)  # rig space: up and ahead, a bit to the right (right-hand web)
ANCHOR_L = (-2.0, 15.0, -6.5)


def hang(side, root_pitch, offset, legs, free_arm, neck=None):
    """Hanging on the `side` web: body pitched `root_pitch`, `legs` pose, the free arm posed like a dancer."""
    p = {"Root": (root_pitch, 0, 0), "RootOffset": offset, "Neck": neck or (18 - root_pitch * 0.4, 0, 0), "Waist": (-4, 0, 0)}
    p.update(legs)
    p.update(free_arm)
    return aim_arm_at(p, side, ANCHOR_R if side == "Right" else ANCHOR_L, elbow_hint=(1 if side == "Right" else -1, 0, 1),
                      wrist=(10, 0, 0))


# legs together, straight and pointed (stretched line at the back of the arc)
LEGS_LINE = merge(aim_leg("Right", down=1.0, back=0.25, ankle=POINT), aim_leg("Left", down=1.0, back=0.12, knee=10, ankle=POINT))
# grand jete: front leg kicked forward, back leg stretched behind - the split at the bottom of the arc
LEGS_JETE = merge(aim_leg("Right", forward=1.0, down=0.05, ankle=POINT), aim_leg("Left", back=1.0, down=0.12, knee=6, ankle=POINT))
# release: both legs swept forward, knees soft
LEGS_FRONT = merge(aim_leg("Right", forward=1.0, down=0.6, knee=20, ankle=POINT), aim_leg("Left", forward=0.7, down=1.0, knee=45, ankle=POINT))
ARM_OPEN = aim_arm("Left", out=1.0, up=0.25, back=0.2, elbow=18, wrist=(0, 0, -10))       # port de bras, second position
ARM_LOW = aim_arm("Left", out=1.0, down=0.35, back=0.35, elbow=22)
ARM_HIGH = aim_arm("Left", out=0.7, up=0.8, back=0.2, elbow=30)

BACK_R = hang("Right", -34, (0, 1.05, 0.6), LEGS_LINE, ARM_LOW)
BOTTOM_R = hang("Right", 0, (0, 0.35, 0.0), LEGS_JETE, ARM_OPEN)
FRONT_R = hang("Right", 32, (0, 1.55, -0.55), LEGS_FRONT, ARM_HIGH)
BACK_R["ease"] = "quad_in"      # drop into the arc
BOTTOM_R["ease"] = "quad_out"   # rise out of it
FRONT_R["ease"] = "quad_out"    # let go and throw the flip

# tucked front flip after the right web (Root -X = forward): knees to the chest, hands on the shins
TUCK = merge(aim_leg("Right", forward=1.0, up=0.45, down=0, knee=135, ankle=POINT), aim_leg("Left", forward=1.0, up=0.45, down=0, knee=135, ankle=POINT),
             aim_arm("Right", forward=1.0, down=0.3, out=0.2, elbow=70), aim_arm("Left", forward=1.0, down=0.3, out=0.2, elbow=70),
             {"Waist": (-18, 0, 0), "Neck": (-20, 0, 0)})
FLIP_A = merge(TUCK, {"Root": (-65, 0, 0), "RootOffset": (0, 2.55, -0.25)})
FLIP_B = merge(TUCK, {"Root": (-165, 0, 0), "RootOffset": (0, 2.95, 0.0)})
FLIP_C = merge(TUCK, {"Root": (-265, 0, 0), "RootOffset": (0, 2.45, 0.25), "ease": "sine_out"})

# second swing (left web) ends in a mid-air pirouette: supporting leg straight, the other in passe, arms en couronne
BACK_L = hang("Left", -34, (0, 1.05, 0.6), mirror(LEGS_LINE), mirror(ARM_LOW))
BOTTOM_L = hang("Left", 0, (0, 0.35, 0.0), mirror(LEGS_JETE), mirror(ARM_OPEN))
FRONT_L = hang("Left", 30, (0, 1.55, -0.55), mirror(LEGS_FRONT), mirror(ARM_HIGH))
BACK_L["ease"] = "quad_in"
BOTTOM_L["ease"] = "quad_out"
FRONT_L["ease"] = "quad_out"
COURONNE = merge(aim_arm("Right", up=1.0, out=0.35, forward=0.25, elbow=55, twist=40),
                 aim_arm("Left", up=1.0, out=0.35, forward=0.25, elbow=55, twist=-40))
PASSE = merge(aim_leg("Left", down=1.0, ankle=POINT), aim_leg("Right", forward=0.35, out=0.9, down=0.25, knee=120, ankle=POINT))


def pirouette(turn, lift):
    return merge(COURONNE, PASSE, {"Root": (0, turn, 0), "RootOffset": (0, lift, 0), "Neck": (6, 0, 0)})


MOVE = clip("Move", 2.8, {
    0.0: BACK_R,
    0.45: BOTTOM_R,
    0.8: FRONT_R,
    0.97: FLIP_A,
    1.13: FLIP_B,
    1.28: FLIP_C,
    1.42: BACK_L,
    1.86: BOTTOM_L,
    2.2: FRONT_L,
    2.36: pirouette(-120, 2.1),
    2.52: pirouette(-240, 2.0),
    2.67: merge(pirouette(-350, 1.6), {"ease": "sine_in"}),
}, effects=[
    web("RightHand", anchor=ANCHOR_R, t0=0.0, t1=0.8),
    web("LeftHand", anchor=ANCHOR_L, t0=1.42, t1=2.2),
    accent(2.2, 0.78, 1.4),
    accent(2.2, 2.18, 2.8),
], motion=motion(lift=0.0, lean=0.4), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: arabesque thwip
PERCH = perch()
RISE = plant_feet({"RootOffset": (0.0, -0.35, 0.0), "Root": (-6, 0, 0), "Neck": (8, 0, 0)},
                  feet={"Left": (-0.5, 0.252, -0.05), "Right": (0.25, 0.252, -0.35)}, knee_hint=(0.4, 0.0, -1.0))
RISE.update(merge(aim_arm("Right", forward=0.6, down=0.8, inward=0.25, elbow=60), aim_arm("Left", forward=0.6, down=0.8, inward=0.25, elbow=60)))
RISE["ease"] = "quad_out"


def arabesque():
    """Balanced on the right leg, body tipped forward, left leg stretched back at hip height, the right arm fires ahead
    and the left arm sweeps back along the leg (the swallow line)."""
    base = {"Root": (-36, 0, 0), "RootOffset": (0, -0.04, 0), "Waist": (8, 0, 0), "Neck": (32, 0, 0)}
    p = plant_feet(base, feet={"Right": (0.5, 0.252, 0.0)})
    p.update(aim_leg("Left", back=1.0, up=0.05, down=0, ankle=POINT))
    p.update(aim_arm("Right", forward=1.0, up=0.55, wrist=(62, 0, 0)))
    p.update(aim_arm("Left", back=1.0, out=0.55, up=0.15, elbow=10))
    return p


SHOOT_R = merge(arabesque(), {"ease": "quart_out"})
TUG_R = add(SHOOT_R, {"RightElbow": (45, 0, 0), "Root": (4, 0, 0), "Waist": (4, 0, 0), "RightShoulder": (-12, 0, 0)})


def spin(turn):
    """Pirouette on the right toes (left leg in passe), arms en couronne."""
    p = merge(mirror(PASSE), COURONNE, {"Root": (0, turn, 0), "RootOffset": (0, 0.1, 0), "Neck": (6, 0, 0)})
    p.update(plant_feet({"Root": p["Root"], "RootOffset": p["RootOffset"]}, feet={"Right": (0.1, 0.43, 0.0)},
                        foot_yaw={"Right": turn}))
    p.update(aim_leg("Left", forward=0.35, out=0.9, down=0.25, knee=120, ankle=POINT))
    p["RightAnkle"] = (-40, 0, 0)  # up on the toes (demi-pointe)
    return p


SPIN_A = spin(-120)
SPIN_B = spin(-240)
PLIE = plant_feet({"RootOffset": (0.0, -0.75, 0.0), "Root": (-4, 0, 0), "Waist": (4, 0, 0), "Neck": (6, 0, 0)},
                  feet={"Left": (-1.25, 0.252, 0.0), "Right": (1.25, 0.252, 0.0)}, knee_hint=(1.0, 0.0, -0.5),
                  foot_yaw={"Left": -35, "Right": 35})
SHOOT_L = merge(PLIE, aim_arm("Left", forward=1.0, up=0.2, wrist=(62, 0, 0)), aim_arm("Right", out=1.0, up=0.3, back=0.2, elbow=15),
                {"ease": "quart_out"})
TUG_L = add(SHOOT_L, {"LeftElbow": (45, 0, 0), "Waist": (6, 0, 0), "LeftShoulder": (-12, 0, 0)})
CURTSY = plant_feet({"RootOffset": (0.0, -0.55, 0.0), "Root": (-14, 0, 0), "Waist": (-8, 0, 0), "Neck": (-18, 0, 8)},
                    feet={"Left": (-0.45, 0.252, -0.15), "Right": (-0.05, 0.252, 0.75)}, knee_hint=(0.6, 0.0, -1.0))
CURTSY.update(merge(aim_arm("Right", out=1.0, down=0.8, forward=0.15, elbow=15, twist=-30),
                    aim_arm("Left", out=1.0, down=0.8, forward=0.15, elbow=15, twist=30)))

SPECIAL = clip("Special", 3.1, {
    0.0: PERCH,
    0.35: RISE,
    0.6: SHOOT_R,
    0.95: TUG_R,
    1.17: SPIN_A,
    1.34: SPIN_B,
    1.55: SHOOT_L,
    1.9: TUG_L,
    2.35: CURTSY,
    3.1: PERCH,
}, loop=False, effects=[
    web("RightHand", anchor=(1.0, 7.5, -18.0), t0=0.6, t1=1.1, width=0.1),
    web("LeftHand", anchor=(-1.2, 4.5, -18.0), t0=1.55, t1=2.05, width=0.1),
    accent(2.5, 1.1, 1.6),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.3, "Move": 1.86, "Special": 0.6}
CAMERAS = {"Idle": "front", "Move": "side", "Special": "side34"}
