# Monkey D. Luffy (One Piece, Straw Hat captain) - HeroMotion style "bounce".
#   Idle     straw-hat grin: right hand pressing the hat down on his head, left fist on the hip, springy rubber bounce
#            on the knees, then a "shishishi" chuckle (head back, shoulders shaking)
#   Move     rubber run: huge strides, knees high, noodle arms flung far forward / back with loose elbows and floppy
#            wrists, body bobbing up on every stride (the HeroMotion hop stays on, halved)
#   Special  Gomu Gomu no... PISTOL!: twist and wind the right arm far back, hold the tension, then snap the fist
#            straight ahead with a big lunge (impact burst), the rubber arm yanks back and he bounces back to the grin
from hero_anim.api import *  # noqa: F401,F403

HERO = "Luffy"
SPECIAL_EVERY = (8, 15)

VEST = (204, 30, 32)
SHORTS = (42, 82, 182)
SKIN = (246, 204, 164)
STRAW = (236, 202, 92)
HAIR = (22, 20, 24)
COLORS = palette(Torso=VEST, LowerTorso=SHORTS, Arms=SKIN, Hands=SKIN, UpperLegs=SHORTS, LowerLegs=SKIN,
                 Feet=(150, 96, 52), Head=SKIN)
EXTRAS = [
    # messy black hair under the hat
    extra("Head", "box", size=(1.3, 0.34, 1.3), offset=(0, 0.42, 0.04), color=HAIR),
    extra("Head", "box", size=(1.16, 0.16, 0.12), offset=(0, 0.4, -0.58), color=HAIR),
    extra("Head", "cone", size=(0.26, 0.3, 0.14), offset=(-0.3, 0.42, -0.6), rot=(180, 0, 0), color=HAIR),
    extra("Head", "cone", size=(0.26, 0.3, 0.14), offset=(0.08, 0.42, -0.62), rot=(180, 0, 0), color=HAIR),
    extra("Head", "cone", size=(0.26, 0.26, 0.14), offset=(0.38, 0.42, -0.58), rot=(180, 0, 0), color=HAIR),
    # the straw hat: brim, crown, red band
    extra("Head", "sphere", size=(2.35, 0.14, 2.35), offset=(0, 0.66, 0.02), color=STRAW),
    extra("Head", "sphere", size=(1.34, 0.95, 1.34), offset=(0, 0.78, 0.02), color=STRAW),
    extra("Head", "sphere", size=(1.38, 0.3, 1.38), offset=(0, 0.8, 0.02), color=(200, 26, 30)),
    # open vest: bare chest strip + the X scar
    extra("UpperTorso", "box", size=(0.62, 1.5, 0.06), offset=(0, 0.02, -0.5), color=SKIN),
    extra("UpperTorso", "box", size=(0.5, 0.07, 0.07), offset=(0, 0.25, -0.54), rot=(0, 0, 35), color=(200, 120, 110)),
    extra("UpperTorso", "box", size=(0.5, 0.07, 0.07), offset=(0, 0.25, -0.54), rot=(0, 0, -35), color=(200, 120, 110)),
    # yellow sash
    extra("LowerTorso", "box", size=(2.06, 0.18, 1.06), offset=(0, 0.12, 0), color=(236, 196, 64)),
]

FEET = {"Left": (-0.72, 0.252, 0.05), "Right": (0.72, 0.252, -0.08)}


def stance(drop, extra_pose=None):
    p = merge({"RootOffset": (0, -drop, 0), "Root": (-3, 0, 0), "Waist": (2, 0, 0)}, extra_pose or {})
    return plant_feet(p, feet=FEET, knee_hint=(0.35, 0, -1))


def hat_hand(pose, press=0.0):
    """Right hand holding the straw hat down by its right brim (elbow up and out), left fist on the hip."""
    p = reach(pose, "Right", (1.02, 4.98 - press, -0.28), elbow_hint=(1.0, 0.35, 0.2), wrist=(0, 0, -25))
    return reach(p, "Left", (-1.25, 2.25 - 0.1, -0.12), elbow_hint=(-1, 0.2, 0.3))


# ------------------------------------------------------------------------------------------------ Idle
UP = hat_hand(stance(0.08, {"Neck": (4, 0, -4)}))
DIP = hat_hand(stance(0.34, {"Neck": (-2, 0, 3), "Waist": (-3, 0, 0)}), press=0.3)
UP2 = hat_hand(stance(0.04, {"Neck": (6, 6, 5)}))
DIP2 = hat_hand(stance(0.3, {"Neck": (-1, -4, -3), "Waist": (-3, 0, 0)}), press=0.28)
# "shishishi": leaning back, head thrown back, shoulders bouncing with the laugh
LAUGH_A = hat_hand(stance(0.12, {"Root": (-1, 0, 0), "Waist": (12, 8, 0), "Neck": (18, 6, 6)}))
LAUGH_B = hat_hand(stance(0.2, {"Root": (-2, 0, 0), "Waist": (7, 8, 0), "Neck": (10, 6, 6)}), press=0.12)
UP["ease"] = UP2["ease"] = "quad_out"    # spring up fast, hang...
DIP["ease"] = DIP2["ease"] = "quad_in"   # ...and drop back into the knees

IDLE = clip("Idle", 3.4, {
    0.0: DIP,
    0.3: merge(UP, {"ease": "quad_inout"}),
    0.62: DIP2,
    0.95: merge(UP2, {"ease": "sine_inout"}),
    1.55: merge(LAUGH_A, {"ease": "quad_in"}),
    1.75: LAUGH_B,
    1.95: merge(LAUGH_A, {"ease": "quad_in"}),
    2.15: LAUGH_B,
    2.35: merge(LAUGH_A, {"ease": "sine_inout"}),
    2.95: merge(UP, {"ease": "quad_in"}),
})

# ------------------------------------------------------------------------------------------------ Move: rubber run
RUN_LEN = 0.56
RUN = run_cycle(length=RUN_LEN, stride=62.0, knee=95.0, arm=80.0, bounce=0.42, lean=12.0)
T0, T1, T2, T3 = sorted(RUN)
for t in (T0, T2):
    RUN[t] = add(RUN[t], {"RootOffset": (0, -0.4, 0)})  # the contact foot really lands (the passing pose flies)


def noodle_arms(fwd, back, t_up):
    """Loose rubber arms: `fwd` arm flung high ahead, `back` arm flung far behind, both elbows soft, wrists floppy."""
    p = aim_arm(fwd, forward=1.0, up=0.55 * t_up, out=0.25, elbow=28, wrist=(-35, 0, 0))
    p.update(aim_arm(back, back=1.0, up=0.35 * t_up, out=0.3, elbow=18, wrist=(40, 0, 0)))
    return p


RUN[T0] = merge(RUN[T0], noodle_arms("Left", "Right", 1.0), {"Neck": (14, -6, 0), "ease": "quad_out"})
RUN[T1] = merge(RUN[T1], aim_arm("Right", back=0.5, down=1.0, out=0.35, elbow=35, wrist=(30, 0, 0)),
                aim_arm("Left", forward=0.5, down=1.0, out=0.35, elbow=45, wrist=(-30, 0, 0)), {"Neck": (12, 0, 0), "ease": "quad_in"})
RUN[T2] = merge(RUN[T2], noodle_arms("Right", "Left", 1.0), {"Neck": (14, 6, 0), "ease": "quad_out"})
RUN[T3] = merge(RUN[T3], aim_arm("Left", back=0.5, down=1.0, out=0.35, elbow=35, wrist=(30, 0, 0)),
                aim_arm("Right", forward=0.5, down=1.0, out=0.35, elbow=45, wrist=(-30, 0, 0)), {"Neck": (12, 0, 0), "ease": "quad_in"})
MOVE = clip("Move", RUN_LEN, RUN, speed="auto", motion=motion(lift=0.5, lean=0.8))

# ------------------------------------------------------------------------------------------------ Special: Gum-Gum Pistol
WIND_FEET = {"Left": (-0.55, 0.252, -0.55), "Right": (0.85, 0.252, 0.55)}
WIND = plant_feet({"Root": (-6, -22, 0), "RootOffset": (0.05, -0.35, 0.25), "Waist": (2, -38, 0), "Neck": (4, 55, 0)},
                  feet=WIND_FEET, knee_hint=(0.4, 0, -1))
WIND.update(aim_arm("Right", back=1.0, out=0.55, up=0.15, elbow=12, wrist=(0, 0, 0)))
WIND.update(aim_arm("Left", forward=1.0, up=0.15, inward=0.1, elbow=25, wrist=(-15, 0, 0)))
WIND_TENSE = add(WIND, {"RightShoulder": (-10, 0, 6), "Waist": (0, -6, 0), "RootOffset": (0, -0.05, 0.12), "Neck": (0, 6, 0)})
WIND["ease"] = "back_out"

PUNCH_FEET = {"Left": (-0.6, 0.252, -1.5), "Right": (0.8, 0.252, 0.15)}
PUNCH = plant_feet({"Root": (-14, 12, 0), "RootOffset": (-0.1, -0.55, -0.95), "Waist": (-4, 26, 0), "Neck": (8, -30, 0)},
                   feet=PUNCH_FEET, knee_hint=(0.3, 0, -1))
PUNCH.update(aim_arm("Right", forward=1.0, inward=0.22, up=0.3, elbow=0, wrist=(-10, 0, 0)))
PUNCH.update(aim_arm("Left", back=0.7, down=0.4, out=0.5, elbow=85))
PUNCH["ease"] = "quart_out"
HOLD = add(PUNCH, {"RootOffset": (0, 0.03, -0.12), "Root": (-3, 0, 0)})
HOLD["ease"] = "quad_in"
# the rubber arm snaps back: body yanked after it, fist whipping in to the shoulder
SNAP = plant_feet({"Root": (-4, -6, 0), "RootOffset": (0, -0.25, -0.35), "Waist": (6, -10, 0), "Neck": (10, 10, 0)},
                  feet=PUNCH_FEET, knee_hint=(0.3, 0, -1))
SNAP.update(aim_arm("Right", forward=0.6, out=0.6, up=0.2, elbow=135, wrist=(20, 0, 0)))
SNAP.update(aim_arm("Left", down=1.0, out=0.5, back=0.3, elbow=40))
SNAP["ease"] = "back_out"

SPECIAL = clip("Special", 2.9, {
    0.0: UP,
    0.4: WIND,
    0.95: WIND_TENSE,
    1.12: PUNCH,
    1.55: HOLD,
    1.8: SNAP,
    2.35: merge(DIP, {"ease": "quad_out"}),
    2.9: UP,
}, loop=False, effects=[
    burst("RightHand", 1.13, color=(255, 255, 255), count=40, speed=22),
    burst("RightHand", 1.16, color=(255, 214, 120), count=18, speed=10),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.12}
CAMERAS = {"Move": "side34", "Special": "side34"}
