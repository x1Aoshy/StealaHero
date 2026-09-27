# Todoroki (My Hero Academia, Rare) - HeroMotion style "walk" + ice / fire Aura. Half-Cold Half-Hot.
#   Idle     calm and still: upright, both hands a little away from the body, palms down; he glances at his right
#            hand (frost gathers on it), then at his left (a flame flickers) - the two halves, one after the other
#   Move     calm walk: small steps, arms barely swinging, chin level, unbothered
#   Special  Heaven-Piercing Ice Wall + Flashfire Fist: right hand raised then slammed to the ground in a deep crouch
#            (ice burst), he rises turning the left side forward and thrusts a flaming palm, ending half-cold
#            half-hot with both arms out
from hero_anim.api import *  # noqa: F401,F403

HERO = "Todoroki"
SPECIAL_EVERY = (10, 17)

NAVY = (44, 68, 128)
DARK = (34, 40, 60)
SKIN = (246, 212, 186)
ICE = (170, 225, 255)
FLAME = (255, 110, 60)
COLORS = palette(Torso=NAVY, LowerTorso=(230, 230, 236), Arms=NAVY, Hands=SKIN, Legs=DARK, Feet=(40, 40, 50), Head=SKIN)
EXTRAS = [
    # split hair: white on his right, red on his left
    extra("Head", "box", size=(0.66, 0.42, 1.18), offset=(0.31, 0.45, 0.05), color=(238, 240, 246)),
    extra("Head", "box", size=(0.66, 0.42, 1.18), offset=(-0.31, 0.45, 0.05), color=(210, 56, 48)),
    extra("Head", "box", size=(0.3, 0.55, 0.9), offset=(0.6, 0.15, 0.1), color=(238, 240, 246)),
    extra("Head", "box", size=(0.3, 0.55, 0.9), offset=(-0.6, 0.15, 0.1), color=(210, 56, 48)),
    # burn scar over the left eye
    extra("Head", "box", size=(0.34, 0.3, 0.05), offset=(-0.28, 0.1, -0.53), color=(170, 70, 70)),
    # white harness belt + frost on the right shoulder
    extra("UpperTorso", "box", size=(2.06, 0.22, 1.06), offset=(0, -0.3, 0), color=(230, 230, 236)),
    extra("RightUpperArm", "box", size=(1.1, 0.5, 1.1), offset=(0, 0.35, 0), color=ICE),
]

# ------------------------------------------------------------------------------------------------ Idle
FEET = {"Left": (-0.6, 0.252, -0.05), "Right": (0.6, 0.252, 0.05)}


def calm(head=(-4, 0, 0), right=None, left=None, breath=0.0):
    p = plant_feet({"Root": (0, 0, 0), "RootOffset": (0, -0.03, 0), "Waist": (breath, 0, 0), "Neck": head}, FEET)
    p.update(right or aim_arm("Right", down=1.0, out=0.3, forward=0.12, elbow=14, twist=-60, wrist=(0, 0, -25)))
    p.update(left or aim_arm("Left", down=1.0, out=0.3, forward=0.12, elbow=14, twist=60, wrist=(0, 0, 25)))
    return p


CALM = calm()
CALM_IN = calm(head=(-2, 0, 0), breath=3.0)
PALM_R = aim_arm("Right", down=0.7, forward=0.75, out=0.35, elbow=55, twist=-80, wrist=(-20, 0, 0))
PALM_L = aim_arm("Left", down=0.7, forward=0.75, out=0.35, elbow=55, twist=80, wrist=(-20, 0, 0))
LOOK_ICE = calm(head=(-16, -30, 0), right=PALM_R)
LOOK_FIRE = calm(head=(-16, 30, 0), left=PALM_L)

IDLE = clip("Idle", 5.6, {
    0.0: CALM,
    1.1: CALM_IN,
    2.0: LOOK_ICE,
    2.9: add(LOOK_ICE, {"Neck": (2, 4, 0)}),
    3.5: LOOK_FIRE,
    4.4: add(LOOK_FIRE, {"Neck": (2, -4, 0)}),
    5.0: CALM,
}, effects=[
    charge("RightHand", 2.0, 3.2, color=ICE, size=0.45, light=True),
    charge("LeftHand", 3.5, 4.7, color=FLAME, size=0.45, light=True),
])

# ------------------------------------------------------------------------------------------------ Move: calm walk
WALK = walk_cycle(length=1.1, stride=24.0, knee=30.0, arm=10.0, bounce=0.05)
for pose in WALK.values():
    pose["Neck"] = (-3, 0, 0)
MOVE = clip("Move", 1.1, WALK, speed="auto")

# ------------------------------------------------------------------------------------------------ Special: ice + fire
RAISE = plant_feet({"Root": (4, 10, 0), "RootOffset": (0, -0.15, 0), "Waist": (6, 6, 0), "Neck": (4, -10, 0)},
                   {"Left": (-0.7, 0.252, 0.1), "Right": (0.8, 0.252, -0.35)})
RAISE.update(aim_arm("Right", up=1.0, out=0.35, back=0.15, elbow=20, twist=-60))
RAISE.update(aim_arm("Left", down=1.0, out=0.4, elbow=20, twist=60))
RAISE["ease"] = "quad_in"

SLAM = plant_feet({"Root": (-34, 6, 0), "RootOffset": (0, -1.05, -0.2), "Waist": (-12, 0, 0), "Neck": (36, -6, 0)},
                  {"Left": (-0.85, 0.252, 0.5), "Right": (0.95, 0.252, -0.7)}, knee_hint=(0.8, 0.0, -1.0))
SLAM = reach(SLAM, "Right", (0.85, 0.3, -1.45), elbow_hint=(1.0, 0.3, 0.3), wrist=(-60, 0, 0))
SLAM.update(aim_arm("Left", out=1.0, back=0.6, up=0.1, elbow=25))
SLAM["ease"] = "quart_out"
SLAM_HOLD = add(SLAM, {"RootOffset": (0, -0.04, 0), "Neck": (-4, 0, 0)})

FIRE = plant_feet({"Root": (-8, -36, 0), "RootOffset": (0, -0.4, -0.2), "Waist": (-4, -18, 0), "Neck": (6, 50, 0)},
                  {"Left": (-0.8, 0.252, -0.7), "Right": (0.85, 0.252, 0.55)}, knee_hint=(0.6, 0.0, -1.0))
FIRE = aim_arm_at(FIRE, "Left", (-0.4, 3.9, -30.0), reach_frac=0.99, wrist=(-70, 0, 0))
FIRE.update(aim_arm("Right", back=0.7, down=0.6, out=0.4, elbow=40))
FIRE["ease"] = "quart_out"

HALVES = plant_feet({"Root": (2, 0, 0), "RootOffset": (0, -0.3, 0), "Waist": (6, 0, 0), "Neck": (8, 0, 0)},
                    {"Left": (-0.85, 0.252, -0.1), "Right": (0.85, 0.252, 0.1)}, knee_hint=(0.6, 0.0, -1.0))
HALVES.update(aim_arm("Right", out=1.0, down=0.55, forward=0.2, elbow=12, twist=-70, wrist=(-15, 0, 0)))
HALVES.update(aim_arm("Left", out=1.0, down=0.55, forward=0.2, elbow=12, twist=70, wrist=(-15, 0, 0)))
HALVES["ease"] = "back_out"

SPECIAL = clip("Special", 4.2, {
    0.0: CALM,
    0.45: RAISE,
    0.72: SLAM,
    1.4: SLAM_HOLD,
    1.85: FIRE,
    2.5: add(FIRE, {"RootOffset": (0, 0, 0.1), "Root": (3, 0, 0)}),
    3.05: HALVES,
    3.6: add(HALVES, {"Neck": (2, 0, 0)}),
    4.2: CALM,
}, loop=False, effects=[
    burst("RightHand", 0.74, color=ICE, count=55, speed=22),
    charge("RightHand", 0.72, 1.6, color=(220, 245, 255), size=1.5),
    burst("LeftHand", 1.87, color=FLAME, count=45, speed=24),
    charge("LeftHand", 1.85, 2.7, color=(255, 170, 90), size=1.5),
    charge("RightHand", 3.05, 3.9, color=ICE, size=0.7),
    charge("LeftHand", 3.05, 3.9, color=FLAME, size=0.7),
    accent(boost=3.0, t0=0.6, t1=3.9),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 2.0, "Move": 0.0, "Special": 0.72}
CAMERAS = {"Special": "side34"}
