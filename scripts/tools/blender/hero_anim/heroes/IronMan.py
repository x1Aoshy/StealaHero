# Iron Man (Avengers) - HeroMotion style "float" + orange Thrusters under the boots.
#   Idle     repulsor hover: arms held a little out and back with the palms flat to the ground (glowing repulsors),
#            legs locked together, toes down; tiny stabilising corrections and a HUD scan of the head
#   Move     jet flight: body tipped forward, arms swept back along the sides with the palms pushing backwards, legs
#            straight together (thrusters), a slight banking roll
#   Special  repulsor volley + unibeam: right palm up and fire (beam + recoil), left palm fire, then the chest thrusts
#            out with the arms flung back (thrusters roar), the hands snap in to frame the arc reactor while it charges
#            and the unibeam fires straight out of the chest (the beams leave the palms framing the reactor), pushing
#            him back through the air
from hero_anim.api import *  # noqa: F401,F403
from hero_anim.heroes._avjl import aim_hand, HAND_FINGERS

HERO = "IronMan"
SPECIAL_EVERY = (10, 17)

RED = (176, 26, 32)
GOLD = (232, 184, 60)
GLOW = (180, 225, 255)
COLORS = palette(Head=RED, Torso=RED, LowerTorso=GOLD, Arms=RED, Hands=GOLD, Legs=RED, LowerLegs=GOLD, Feet=RED)
EXTRAS = [
    extra("Head", "box", size=(0.92, 0.7, 0.1), offset=(0, -0.05, -0.58), color=GOLD),
    extra("Head", "box", size=(0.52, 0.1, 0.06), offset=(0, 0.12, -0.64), color=GLOW, emissive=True),
    extra("UpperTorso", "sphere", size=(0.42, 0.42, 0.14), offset=(0, 0.22, -0.52), color=GLOW, emissive=True),
    extra("UpperTorso", "box", size=(2.04, 0.3, 1.04), offset=(0, -0.55, 0), color=GOLD),
    # palm repulsors on the finger face of the block hands (hand-local -Y)
    extra("RightHand", "box", size=(0.5, 0.06, 0.5), offset=(0, -0.16, 0), color=GLOW, emissive=True),
    extra("LeftHand", "box", size=(0.5, 0.06, 0.5), offset=(0, -0.16, 0), color=GLOW, emissive=True),
]

DOWN = (0.0, -1.0, 0.0)


def _palms_down(pose, back=0.25):
    p = aim_hand(pose, "Right", HAND_FINGERS, (0.15, -1.0, back))
    return aim_hand(p, "Left", HAND_FINGERS, (-0.15, -1.0, back))


LEGS = merge(aim_leg("Right", down=1.0, out=0.02, knee=6, ankle=(-34, 0, 0)),
             aim_leg("Left", down=1.0, out=0.02, back=0.05, knee=12, ankle=(-34, 0, 0)))

# ------------------------------------------------------------------------------------------------ Idle
HOVER = merge({"Waist": (3, 0, 0), "Neck": (2, 0, 0)}, LEGS,
              aim_arm("Right", down=1.0, out=0.62, back=0.2, elbow=12, twist=-15),
              aim_arm("Left", down=1.0, out=0.62, back=0.2, elbow=12, twist=15))
HOVER = _palms_down(HOVER)
TRIM_A = _palms_down(add(HOVER, {"RightShoulder": (0, 0, 5), "LeftShoulder": (0, 0, -2), "Root": (0, 0, 3),
                                 "Neck": (0, 24, 0), "RootOffset": (0.04, 0.05, 0)}))
TRIM_B = _palms_down(add(HOVER, {"RightShoulder": (0, 0, -2), "LeftShoulder": (0, 0, -5), "Root": (0, 0, -3),
                                 "Neck": (-4, -26, 0), "RootOffset": (-0.04, 0.0, 0)}))
TRIM_A["ease"] = TRIM_B["ease"] = "quad_inout"

IDLE = clip("Idle", 3.6, {0.0: HOVER, 0.9: TRIM_A, 2.0: TRIM_B, 2.9: HOVER},
            effects=[charge("Both", None, None, color=GLOW, size=0.42, light=True)])

# ------------------------------------------------------------------------------------------------ Move: jet flight
JET = {"Root": (-66, 0, 0), "RootOffset": (0, 0.45, 0), "Waist": (4, 0, 0), "Neck": (42, 0, 0)}
JET.update(LEGS)
JET.update(aim_leg("Right", down=1.0, knee=4, ankle=(-45, 0, 0)))
JET.update(aim_leg("Left", down=1.0, knee=8, ankle=(-45, 0, 0)))
JET.update(aim_arm("Right", down=1.0, back=0.35, out=0.3, elbow=6, twist=-20))
JET.update(aim_arm("Left", down=1.0, back=0.35, out=0.3, elbow=6, twist=20))
JET = aim_hand(JET, "Right", HAND_FINGERS, (0.2, -0.75, 1.0))
JET = aim_hand(JET, "Left", HAND_FINGERS, (-0.2, -0.75, 1.0))
BANK_R = add(JET, {"Root": (0, 0, -6), "RootOffset": (0.05, 0.08, 0)})
BANK_L = add(JET, {"Root": (-3, 0, 6), "RootOffset": (-0.05, 0.0, 0)})
MOVE = clip("Move", 1.6, {0.0: JET, 0.4: BANK_R, 1.2: BANK_L}, motion=motion(lift=1.0, lean=0.5), footsteps=False,
            effects=[charge("Both", None, None, color=GLOW, size=0.5, light=True)])

# ------------------------------------------------------------------------------------------------ Special
AIM_R = merge(HOVER, {"Waist": (0, 18, 0), "Neck": (0, -14, 0)}, aim_arm("Right", forward=1.0, up=0.06, wrist=(8, 0, 0)))
AIM_R["ease"] = "quart_out"
FIRE_R = add(AIM_R, {"RightShoulder": (14, 0, 0), "Root": (6, 0, 0), "RootOffset": (0, 0, 0.18)})
AIM_L = merge(HOVER, {"Waist": (0, -18, 0), "Neck": (0, 14, 0)}, aim_arm("Left", forward=1.0, up=0.06, wrist=(8, 0, 0)))
AIM_L["ease"] = "quart_out"
FIRE_L = add(AIM_L, {"LeftShoulder": (14, 0, 0), "Root": (6, 0, 0), "RootOffset": (0, 0, 0.18)})
UNI_CHARGE = merge({"Waist": (24, 0, 0), "Neck": (-14, 0, 0), "Root": (4, 0, 0), "RootOffset": (0, 0.25, 0)},
                   aim_leg("Right", down=1.0, back=0.25, out=0.1, knee=30, ankle=(-40, 0, 0)),
                   aim_leg("Left", down=1.0, back=0.2, out=0.1, knee=40, ankle=(-40, 0, 0)),
                   aim_arm("Right", down=0.35, back=1.0, out=0.95, elbow=8, twist=-50, wrist=(-30, 0, 0)),
                   aim_arm("Left", down=0.35, back=1.0, out=0.95, elbow=8, twist=50, wrist=(-30, 0, 0)))
UNI_CHARGE["ease"] = "back_out"
UNI_TENSE = add(UNI_CHARGE, {"Waist": (4, 0, 0), "RootOffset": (0, 0.05, 0.05)})
UNI_TENSE["ease"] = "quart_out"
# the hands snap in front of the chest, palms forward, framing the arc reactor (the beams leave from there)
FRAME = merge({"Waist": (8, 0, 0), "Neck": (-6, 0, 0), "Root": (2, 0, 0), "RootOffset": (0, 0.25, 0.05)},
              aim_leg("Right", down=1.0, back=0.15, out=0.08, knee=20, ankle=(-38, 0, 0)),
              aim_leg("Left", down=1.0, back=0.1, out=0.08, knee=28, ankle=(-38, 0, 0)))
FRAME = reach(FRAME, "Right", (0.42, 3.45, -1.05), elbow_hint=(1.0, -0.3, 0.3))
FRAME = reach(FRAME, "Left", (-0.42, 3.45, -1.05), elbow_hint=(-1.0, -0.3, 0.3))
FRAME = aim_hand(FRAME, "Right", HAND_FINGERS, (-0.1, 0.1, -1.0))
FRAME = aim_hand(FRAME, "Left", HAND_FINGERS, (0.1, 0.1, -1.0))
FRAME["ease"] = "back_out"
FRAME_TENSE = add(FRAME, {"Waist": (3, 0, 0), "RootOffset": (0, 0.04, 0.06), "Neck": (-3, 0, 0)})
FRAME_TENSE["ease"] = "quint_in"
BLAST = add(FRAME, {"Waist": (-10, 0, 0), "Root": (-4, 0, 0), "Neck": (6, 0, 0), "RootOffset": (0, -0.02, -0.12)})
BLAST["ease"] = "quart_out"
PUSHED = add(FRAME, {"Root": (10, 0, 0), "Waist": (-4, 0, 0), "RootOffset": (0, 0.12, 0.7), "RightHip": (10, 0, 0),
                     "LeftHip": (14, 0, 0), "Neck": (4, 0, 0)})
PUSHED["ease"] = "sine_inout"

TARGET = (0.0, 3.3, -24.0)
SPECIAL = clip("Special", 4.0, {
    0.0: HOVER,
    0.35: AIM_R,
    0.5: FIRE_R,
    0.85: AIM_L,
    1.0: FIRE_L,
    1.45: UNI_CHARGE,
    1.8: UNI_TENSE,
    2.0: FRAME,
    2.35: FRAME_TENSE,
    2.5: BLAST,
    2.9: PUSHED,
    4.0: HOVER,
}, loop=False, effects=[
    web("RightHand", anchor=(2.0, 3.4, -24.0), t0=0.42, t1=0.62, color=GLOW, width=0.3),
    burst("RightHand", 0.42, color=(220, 240, 255), count=20, speed=14),
    web("LeftHand", anchor=(-2.0, 3.4, -24.0), t0=0.92, t1=1.12, color=GLOW, width=0.3),
    burst("LeftHand", 0.92, color=(220, 240, 255), count=20, speed=14),
    charge("Both", 2.0, 2.5, color=GLOW, size=0.8),
    web("RightHand", anchor=TARGET, t0=2.5, t1=3.2, color=(230, 245, 255), width=0.7),
    web("LeftHand", anchor=TARGET, t0=2.5, t1=3.2, color=(230, 245, 255), width=0.7),
    charge("Both", 2.5, 3.2, color=(230, 245, 255), size=1.4, light=True),
    burst("Both", 2.5, color=(230, 245, 255), count=44, speed=22),
    accent(boost=3.0, t0=1.4, t1=3.3),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 2.5}
CAMERAS = {"Move": "side"}
