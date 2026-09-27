# Deku (My Hero Academia, Legendary) - HeroMotion style "dash" + green Sparks. One For All: Full Cowl.
#   Idle     Full Cowl ready stance: low, fists up, springing on the balls of his feet; he raises his right fist,
#            stares at it and clenches it (the green lightning surges), back to the bounce
#   Move     Full Cowl dash: a low, hard-leaning sprint with pumping arms, the sparks pumped the whole time
#   Special  DETROIT SMASH: the body winds back, right fist cocked at the hip charging green, then a lunging
#            straight punch that bursts with the shockwave
from hero_anim.api import *  # noqa: F401,F403

HERO = "Deku"
SPECIAL_EVERY = (9, 15)

GREEN = (38, 122, 92)
DARK = (26, 42, 36)
SKIN = (246, 204, 164)
HAIR = (22, 58, 42)
COLORS = palette(Torso=GREEN, LowerTorso=DARK, Arms=GREEN, Hands=(238, 238, 240), Legs=GREEN, Feet=(210, 42, 42),
                 Head=SKIN)
EXTRAS = [
    # messy dark green hair
    extra("Head", "spikes", size=(0.8, 0.95, 0.8), offset=(0, 0.35, 0.05), rot=(-10, 0, 0), color=HAIR),
    extra("Head", "box", size=(1.3, 0.4, 1.2), offset=(0, 0.45, 0.05), color=HAIR),
    # grey mouth guard + red belt pouches + knee pads
    extra("Head", "box", size=(0.9, 0.3, 0.08), offset=(0, -0.25, -0.54), color=(150, 155, 160)),
    extra("LowerTorso", "box", size=(2.08, 0.25, 1.08), offset=(0, 0, 0), color=(190, 40, 40)),
    extra("LeftLowerLeg", "box", size=(1.06, 0.3, 1.06), offset=(0, 0.4, 0), color=DARK),
    extra("RightLowerLeg", "box", size=(1.06, 0.3, 1.06), offset=(0, 0.4, 0), color=DARK),
]

# ------------------------------------------------------------------------------------------------ Idle
FEET = {"Left": (-0.82, 0.252, -0.35), "Right": (0.82, 0.252, 0.35)}


def stance(drop=0.45, look=(4, 0, 0)):
    p = plant_feet({"Root": (-12, -12, 0), "RootOffset": (0, -drop, 0), "Waist": (-4, -4, 0), "Neck": (look[0] + 10, look[1] + 16, look[2])},
                   FEET, knee_hint=(0.6, 0.0, -1.0))
    p = reach(p, "Right", (0.6, 3.3 - drop, -1.15), elbow_hint=(0.7, -1.0, 0.2), wrist=(0, 0, 0))
    return reach(p, "Left", (-0.65, 3.2 - drop, -1.45), elbow_hint=(-0.7, -1.0, 0.2), wrist=(0, 0, 0))


LOW = stance(0.5)
HIGH = stance(0.3)
LOW["ease"] = "quad_out"
HIGH["ease"] = "quad_in"
# the fist stare: right fist raised in front of the face, head bowed to it
STARE = plant_feet({"Root": (-4, -6, 0), "RootOffset": (0, -0.3, 0), "Waist": (-2, 6, 0), "Neck": (-14, -12, 0)}, FEET,
                   knee_hint=(0.6, 0.0, -1.0))
STARE = reach(STARE, "Right", (0.3, 4.1, -1.15), elbow_hint=(1.0, -0.8, 0.2), wrist=(-20, 0, 0))
STARE.update(aim_arm("Left", down=1.0, out=0.3, forward=0.1, elbow=30, twist=20))
STARE["ease"] = "quart_out"
CLENCH = add(STARE, {"RightElbow": (6, 0, 0), "RightWrist": (-10, 0, 0), "Neck": (-4, 0, 0), "RootOffset": (0, -0.06, 0)})

IDLE = clip("Idle", 4.0, {
    0.0: LOW,
    0.4: HIGH,
    0.8: LOW,
    1.2: HIGH,
    1.7: STARE,
    2.3: CLENCH,
    2.7: add(CLENCH, {"RightElbow": (-4, 0, 0)}),
    3.4: HIGH,
}, effects=[accent(boost=2.5, t0=2.2, t1=3.0)])

# ------------------------------------------------------------------------------------------------ Move: Full Cowl dash
RUN = run_cycle(length=0.48, stride=62.0, knee=95.0, arm=75.0, bounce=0.24, lean=30.0)
for pose in RUN.values():
    pose["Neck"] = (24, 0, 0)
MOVE = clip("Move", 0.48, RUN, speed="auto", effects=[accent(boost=2.0)])

# ------------------------------------------------------------------------------------------------ Special: Detroit Smash
WIND = plant_feet({"Root": (-10, -38, 0), "RootOffset": (0, -0.7, 0.15), "Waist": (-4, -26, 0), "Neck": (6, 56, 0)},
                  {"Left": (-0.85, 0.252, -0.85), "Right": (0.9, 0.252, 0.7)}, knee_hint=(0.6, 0.0, -1.0))
WIND = reach(WIND, "Right", (0.95, 2.25, 0.85), elbow_hint=(0.6, 0.2, 1.0), wrist=(0, 0, 0))
WIND.update(aim_arm("Left", forward=1.0, out=0.2, up=0.15, elbow=25, wrist=(-40, 0, 0)))
WIND["ease"] = "sine_out"
WIND_TENSE = add(WIND, {"RootOffset": (0, -0.06, 0.05), "Waist": (-2, -4, 0), "Neck": (-2, 2, 0)})
WIND_TENSE["ease"] = "quad_in"

SMASH = plant_feet({"Root": (-16, 30, 0), "RootOffset": (0, -0.75, -0.75), "Waist": (-6, 20, 0), "Neck": (12, -46, 0)},
                   {"Left": (-0.85, 0.252, -1.55), "Right": (0.9, 0.252, 0.8)}, knee_hint=(0.6, 0.0, -1.0))
SMASH = aim_arm_at(SMASH, "Right", (0.2, 3.1, -30.0), reach_frac=0.99)
SMASH.update(aim_arm("Left", back=0.8, down=0.6, out=0.3, elbow=70))
SMASH["ease"] = "quart_out"
HOLD = add(SMASH, {"RootOffset": (0, -0.04, -0.05)})

SPECIAL = clip("Special", 3.2, {
    0.0: LOW,
    0.45: WIND,
    1.15: WIND_TENSE,
    1.35: SMASH,
    2.0: HOLD,
    3.2: LOW,
}, loop=False, effects=[
    charge("RightHand", 0.4, 1.35, color=(90, 255, 130), size=1.0),
    charge("RightHand", 1.35, 2.0, color=(200, 255, 210), size=1.8),
    burst("RightHand", 1.37, color=(110, 255, 150), count=55, speed=26),
    accent(boost=3.5, t0=0.4, t1=2.2),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.35}
CAMERAS = {"Move": "side", "Special": "side34"}
