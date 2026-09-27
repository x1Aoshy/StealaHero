# Piccolo (Dragon Ball, Rare) - HeroMotion style "float". Turban, weighted cape, arms always crossed.
#   Idle     meditation: floating cross-legged with the arms folded, slow deep breathing, head bowed; now and then
#            the head lifts a little (an eye opening to check on the pen) and bows again
#   Move     the stern cape hover: upright-ish glide, arms crossed, legs together and trailing, a slow sway
#   Special  Special Beam Cannon: legs drop out of the lotus, two fingers to the forehead crackling with energy,
#            then the arm snaps straight ahead (the other hand bracing the forearm) and fires the drill beam
from hero_anim.api import *  # noqa: F401,F403

HERO = "Piccolo"
SPECIAL_EVERY = (11, 18)

GREEN = (104, 172, 74)
PURPLE = (92, 42, 124)
SASH = (70, 170, 220)
WHITE = (238, 238, 242)
COLORS = palette(Torso=PURPLE, LowerTorso=SASH, Arms=GREEN, Hands=GREEN, Legs=PURPLE, Feet=(118, 70, 40), Head=GREEN)
EXTRAS = [
    # turban + its purple top
    extra("Head", "box", size=(1.25, 0.55, 1.2), offset=(0, 0.55, 0.02), color=WHITE),
    extra("Head", "box", size=(0.6, 0.18, 0.6), offset=(0, 0.88, 0.02), color=PURPLE),
    # weighted cape + shoulder pads
    extra("UpperTorso", "box", size=(2.4, 3.2, 0.14), offset=(0, -0.7, 0.62), rot=(-5, 0, 0), color=WHITE),
    extra("UpperTorso", "box", size=(2.7, 0.35, 1.3), offset=(0, 0.78, 0), color=WHITE),
    # pink arm patches
    extra("LeftUpperArm", "box", size=(1.04, 0.35, 1.04), offset=(0, 0.0, 0), color=(222, 130, 150)),
    extra("RightUpperArm", "box", size=(1.04, 0.35, 1.04), offset=(0, 0.0, 0), color=(222, 130, 150)),
]

# ------------------------------------------------------------------------------------------------ Idle: meditation
# lotus: thighs forward and out, each thigh twisted so the knee bend folds the shin INWARD, shins crossed in front
LOTUS = merge(aim_leg("Right", forward=1.0, out=0.72, down=0.12, twist=-90, knee=150, ankle=(0, 0, 0)),
              aim_leg("Left", forward=1.0, out=0.72, down=0.32, twist=90, knee=150, ankle=(0, 0, 0)))
MEDITATE = merge({"RootOffset": (0, 0.55, 0), "Root": (2, 0, 0), "Waist": (-4, 0, 0), "Neck": (-16, 0, 0)}, LOTUS,
                 arms_crossed())
INHALE = add(MEDITATE, {"Waist": (5, 0, 0), "Neck": (-2, 0, 0), "RootOffset": (0, 0.1, 0),
                        "RightShoulder": (0, 0, 2), "LeftShoulder": (0, 0, -2)})
PEEK = merge(MEDITATE, {"Neck": (2, -14, 0), "Waist": (-2, -3, 0)})

IDLE = clip("Idle", 6.0, {
    0.0: MEDITATE,
    1.6: INHALE,
    3.0: MEDITATE,
    3.7: merge(PEEK, {"ease": "quart_out"}),
    4.6: PEEK,
    5.3: add(MEDITATE, {"RootOffset": (0, 0.04, 0)}),
})

# ------------------------------------------------------------------------------------------------ Move: cape hover
GLIDE = merge({"Root": (-26, 0, 0), "RootOffset": (0, 0.55, 0), "Neck": (12, 0, 0), "Waist": (-2, 0, 0)}, arms_crossed(),
              aim_leg("Right", down=1.0, back=0.35, knee=24, ankle=(-50, 0, 0)),
              aim_leg("Left", down=1.0, back=0.25, knee=38, ankle=(-50, 0, 0)))
GLIDE_A = add(GLIDE, {"Root": (0, 0, 4)})
GLIDE_B = add(GLIDE, {"Root": (-3, 0, -4), "RootOffset": (0, 0.12, 0), "LeftHip": (-6, 0, 0), "LeftKnee": (-8, 0, 0),
                      "RightHip": (5, 0, 0)})

MOVE = clip("Move", 1.8, {
    0.0: GLIDE_A,
    0.9: GLIDE_B,
}, motion=motion(lift=1.0, lean=0.5), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: Makankosappo
HOVER_LEGS = merge(aim_leg("Right", down=1.0, back=0.2, knee=30, ankle=(-40, 0, 0)),
                   aim_leg("Left", down=1.0, forward=0.45, knee=55, ankle=(-35, 0, 0)))
AIM_BASE = merge({"RootOffset": (0, 0.55, 0), "Root": (-4, -12, 0), "Waist": (-4, -8, 0), "Neck": (-6, 20, 0)},
                 HOVER_LEGS)
# two fingers on the forehead, elbow high and out, the other arm across the belly
FOCUS = reach(AIM_BASE, "Right", (0.1, 4.95, -0.72), elbow_hint=(1.0, 0.2, 0.0), wrist=(20, 0, 0))
FOCUS = reach(FOCUS, "Left", (0.15, 2.95, -0.85), elbow_hint=(-1.0, -0.5, 0.2))
FOCUS_TENSE = add(FOCUS, {"Waist": (-4, 0, 0), "Neck": (-4, 0, 0), "RootOffset": (0, -0.05, 0)})


def fire_pose(push=0.0):
    p = merge({"RootOffset": (0, 0.5, -push), "Root": (-8, -22, 0), "Waist": (-6, -10, 0), "Neck": (-4, 32, 0)}, HOVER_LEGS)
    p = aim_arm_at(p, "Right", (0.4, 3.9, -30.0), reach_frac=0.99, wrist=(-8, 0, 0))
    parts, _ = rig().fk(transforms_of(p))
    forearm = parts["RightLowerArm"][1]
    return reach(p, "Left", (forearm[0] - 0.35, forearm[1] - 0.12, forearm[2] + 0.1), elbow_hint=(-1.0, -0.6, 0.3))


FIRE = merge(fire_pose(0.1), {"ease": "quart_out"})
RECOIL = fire_pose(-0.3)

SPECIAL = clip("Special", 4.4, {
    0.0: MEDITATE,
    0.55: merge(FOCUS, {"ease": "back_out"}),
    1.6: FOCUS_TENSE,
    2.2: add(FOCUS_TENSE, {"Neck": (-3, 0, 0), "Waist": (-2, 0, 0)}),
    2.4: FIRE,
    3.1: RECOIL,
    4.4: MEDITATE,
}, loop=False, effects=[
    charge("RightHand", 0.55, 2.4, color=(255, 232, 120), size=0.7),
    charge("RightHand", 2.4, 3.2, color=(214, 140, 255), size=1.4),
    burst("RightHand", 2.42, color=(255, 236, 140), count=40, speed=22),
    burst("RightHand", 2.7, color=(200, 130, 255), count=25, speed=16),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 2.4}
CAMERAS = {"Move": "side"}
