# Black Widow (Avengers, Common) - HeroMotion style "bounce".
#   Idle     spy's confidence: hip cocked, weight on one leg, hand on the hip, head tilted; now and then she lifts her
#            wrist and test-fires the Widow's Bite gauntlet (blue spark) with a glance at it
#   Move     acrobatic run: two quick light sprint strides, a hurdle and a tucked FRONT FLIP, landing low and flowing back
#            into the run (the clip owns the height, HeroMotion hops off)
#   Special  Widow's Bite combo: guard up, a spinning double roundhouse kick pivoting on the left foot, drops into a low
#            wide stance and fires both Widow's Bites (electric blue charge + bursts), then straightens up to the hip pose
import math

from hero_anim.api import *  # noqa: F401,F403

HERO = "BlackWidow"
SPECIAL_EVERY = (9, 16)

SUIT = (24, 24, 30)
SKIN = (242, 200, 170)
HAIR = (178, 46, 28)
STEEL = (178, 180, 190)
BITE = (90, 190, 255)
COLORS = palette(Head=SKIN, Torso=SUIT, Arms=SUIT, Hands=SUIT, Legs=SUIT, Feet=(16, 16, 20))
EXTRAS = [
    # red hair: shoulder-length bob
    extra("Head", "box", size=(1.32, 0.42, 1.28), offset=(0, 0.5, 0.06), color=HAIR),
    extra("Head", "box", size=(1.34, 1.05, 0.55), offset=(0, 0.02, 0.4), color=HAIR),
    extra("Head", "box", size=(0.2, 0.95, 0.9), offset=(-0.62, -0.05, 0.12), color=HAIR),
    extra("Head", "box", size=(0.2, 0.95, 0.9), offset=(0.62, -0.05, 0.12), color=HAIR),
    # belt with the red hourglass buckle
    extra("LowerTorso", "box", size=(2.06, 0.22, 1.06), offset=(0, 0.05, 0), color=STEEL),
    extra("LowerTorso", "box", size=(0.3, 0.3, 0.08), offset=(0, 0.05, -0.55), rot=(0, 0, 45), color=(210, 30, 30)),
    # Widow's Bite gauntlets
    extra("LeftLowerArm", "box", size=(1.06, 0.4, 1.06), offset=(0, -0.2, 0), color=STEEL),
    extra("RightLowerArm", "box", size=(1.06, 0.4, 1.06), offset=(0, -0.2, 0), color=STEEL),
    extra("RightLowerArm", "box", size=(0.3, 0.2, 0.1), offset=(0, -0.2, -0.56), color=BITE, emissive=True),
    extra("LeftLowerArm", "box", size=(0.3, 0.2, 0.1), offset=(0, -0.2, -0.56), color=BITE, emissive=True),
]

# ------------------------------------------------------------------------------------------------ Idle: hip-cocked spy
FEET_HIP = {"Left": (-0.72, 0.252, -0.45), "Right": (0.5, 0.252, 0.05)}


def hip_pose(breath=0.0, look=0.0, tilt=0.0):
    """Weight on the right leg (hip pushed right, pelvis tilted), left foot forward and turned out, left fist on the
    hip, right arm loose; breath 0..1, look/tilt = head yaw/roll."""
    base = {"Root": (0, 10, 9), "RootOffset": (0.32, -0.14, 0.0), "Waist": (-2 + breath * 3, -8, -13),
            "Neck": (4 - breath * 2, 14 + look, 8 + tilt)}
    p = plant_feet(base, feet=FEET_HIP, knee_hint=(0.2, 0.0, -1.0), foot_yaw={"Left": 25, "Right": -10})
    p = reach(p, "Left", (-1.02, 2.28, -0.05), elbow_hint=(-1.0, 0.1, 0.4), wrist=(0, 0, -20))
    p.update(aim_arm("Right", down=1.0, out=0.12, forward=0.05, elbow=12 + breath * 4, twist=-10))
    return p


HIP = hip_pose()
HIP_IN = hip_pose(breath=1.0, look=-6)
CHECK = hip_pose(look=-20, tilt=-4)
CHECK = reach(CHECK, "Right", (0.62, 3.45, -1.5), elbow_hint=(1.0, -0.6, 0.2), wrist=(10, -60, 0))  # gauntlet to the eyes
CHECK["Neck"] = (-14, -18, 4)
CHECK["ease"] = "quad_out"
CHECK_T = add(CHECK, {"RightWrist": (-8, 0, 0), "Neck": (-2, -4, 0)})

IDLE = clip("Idle", 4.4, {
    0.0: HIP,
    1.1: HIP_IN,
    1.9: CHECK,
    2.75: CHECK_T,
    3.3: merge(hip_pose(breath=0.5, look=10, tilt=4), {"ease": "sine_inout"}),
}, effects=[
    charge("RightHand", 2.2, 2.55, color=BITE, size=0.35, light=True),
])

# ------------------------------------------------------------------------------------------------ Move: sprint + front flip
STEP = 0.3
RUN = run_cycle(length=STEP * 2, stride=50, knee=85, arm=55, bounce=0.2, lean=12)
MOVE_KEYS = {}
for _t, _p in RUN.items():
    MOVE_KEYS[round(_t, 3)] = dict(_p)
    MOVE_KEYS[round(_t + STEP * 2, 3)] = dict(_p)
# hurdle: both feet together, sunk low, arms thrown back ready to swing up
HURDLE = crouch(drop=0.55, width=0.0, lean=22, knee_out=0.3)
HURDLE.update(merge(aim_arm("Right", back=1.0, down=0.6, out=0.2, elbow=10), aim_arm("Left", back=1.0, down=0.6, out=0.2, elbow=10)))
HURDLE["ease"] = "quad_out"
TUCK = merge(aim_leg("Right", forward=1.0, up=0.5, down=0, knee=140, ankle=(-40, 0, 0)),
             aim_leg("Left", forward=1.0, up=0.5, down=0, knee=140, ankle=(-40, 0, 0)),
             aim_arm("Right", forward=1.0, down=0.4, out=0.2, elbow=80), aim_arm("Left", forward=1.0, down=0.4, out=0.2, elbow=80),
             {"Waist": (-20, 0, 0), "Neck": (-18, 0, 0)})
LAUNCH = merge(aim_leg("Right", down=1.0, back=0.2, ankle=(-40, 0, 0)), aim_leg("Left", down=1.0, back=0.2, ankle=(-40, 0, 0)),
               aim_arm("Right", up=1.0, forward=0.3, out=0.15), aim_arm("Left", up=1.0, forward=0.3, out=0.15),
               {"Root": (-30, 0, 0), "RootOffset": (0, 0.9, -0.3), "Neck": (10, 0, 0), "ease": "sine_out"})
LAND = crouch(drop=0.85, width=0.25, lean=26, knee_out=0.6)
LAND.update(merge(aim_arm("Right", out=1.0, forward=0.4, down=0.2, elbow=20), aim_arm("Left", out=1.0, forward=0.4, down=0.2, elbow=20)))
LAND["Neck"] = (26, 0, 0)
LAND["ease"] = "quad_out"
T0 = STEP * 4
MOVE_KEYS.update({
    round(T0, 3): HURDLE,
    round(T0 + 0.14, 3): LAUNCH,
    round(T0 + 0.3, 3): merge(TUCK, {"Root": (-120, 0, 0), "RootOffset": (0, 2.0, -0.2)}),
    round(T0 + 0.45, 3): merge(TUCK, {"Root": (-225, 0, 0), "RootOffset": (0, 2.25, 0.0)}),
    round(T0 + 0.6, 3): merge(TUCK, {"Root": (-320, 0, 0), "RootOffset": (0, 1.3, 0.2), "ease": "quad_in"}),
    round(T0 + 0.75, 3): LAND,
})
MOVE = clip("Move", T0 + 1.05, MOVE_KEYS, motion=motion(lift=0.0, lean=0.5), speed="auto")

# ------------------------------------------------------------------------------------------------ Special: Widow's Bite combo
READY = plant_feet({"Root": (-6, -20, 0), "RootOffset": (0.0, -0.4, 0.0), "Neck": (4, 20, 0)},
                   feet={"Left": (-0.55, 0.252, -0.55), "Right": (0.7, 0.252, 0.45)}, knee_hint=(0.5, 0.0, -1.0),
                   foot_yaw={"Left": -15, "Right": -40})
READY.update(guard())
READY["ease"] = "quad_out"


def spin_kick(turn, kick=1.0):
    """Pivoting on the left foot (kept planted under the left hip), right leg kicked out high, arms flung for balance.
    turn = body yaw (degrees, negative = spinning to its right)."""
    a = math.radians(turn)
    hip = (-0.5 * math.cos(a), -0.5 * -math.sin(a))  # left hip (x, z) after the yaw
    base = {"Root": (0, turn, 14 * kick), "RootOffset": (-0.5 - hip[0], -0.15, 0.0 - hip[1]), "Waist": (0, 0, 8 * kick),
            "Neck": (0, 10, -10 * kick)}
    p = plant_feet(base, feet={"Left": (-0.5, 0.33, 0.0)}, foot_yaw={"Left": turn})
    p["LeftAnkle"] = add({"a": p["LeftAnkle"]}, {"a": (-20, 0, 0)})["a"]  # up on the ball of the foot
    p.update(aim_leg("Right", out=1.0, up=0.35 * kick, down=0.0, forward=0.15, knee=12, ankle=(-40, 0, 0)))
    p.update(aim_arm("Right", out=0.6, down=0.6, back=0.4, elbow=30))
    p.update(aim_arm("Left", out=1.0, up=0.2, forward=0.3, elbow=40))
    return p


AIM = plant_feet({"Root": (-12, 0, 0), "RootOffset": (0.0, -0.95, 0.0), "Waist": (-4, 0, 0), "Neck": (18, 0, 0)},
                 feet={"Left": (-1.3, 0.252, -0.15), "Right": (1.3, 0.252, 0.15)}, knee_hint=(1.0, 0.0, -0.6),
                 foot_yaw={"Left": -30, "Right": 30})
AIM.update(aim_arm("Right", forward=1.0, inward=0.08, up=0.12, wrist=(70, 0, 0)))  # palms out: the Bites fire from the wrists
AIM.update(aim_arm("Left", forward=1.0, inward=0.08, up=0.12, wrist=(70, 0, 0)))
AIM["ease"] = "quart_out"
KICK_BACK = add(AIM, {"Root": (6, 0, 0), "RootOffset": (0, 0.05, 0.2), "RightShoulder": (8, 0, 0), "LeftShoulder": (8, 0, 0)})
SET = merge(HIP, {"ease": "sine_inout"})

SPECIAL = clip("Special", 3.3, {
    0.0: HIP,
    0.3: READY,
    0.52: spin_kick(-120, 0.8),
    0.68: spin_kick(-240, 1.0),
    0.84: spin_kick(-350, 1.0),
    1.02: AIM,
    1.3: KICK_BACK,
    1.5: AIM,
    1.78: KICK_BACK,
    2.4: merge(AIM, {"RootOffset": (0.0, -0.8, 0.0), "Neck": (8, 10, 0)}),
    3.3: SET,
}, loop=False, effects=[
    charge("Both", 1.0, 1.95, color=BITE, size=0.8),
    burst("Both", 1.28, color=BITE, count=30, speed=20),
    burst("Both", 1.76, color=(200, 235, 255), count=30, speed=20),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 1.65, "Special": 0.68}
CAMERAS = {"Move": "side"}
