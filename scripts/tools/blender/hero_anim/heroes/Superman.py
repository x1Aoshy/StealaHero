# Superman (Justice League) - HeroMotion style "float" + pale blue Aura (the model wears a long cape on the UpperTorso).
#   Idle     the classic hover: fists on the hips, chest out, chin up, legs straight together with the toes pointed
#            down; slow heroic breathing and a look to the horizon
#   Move     Superman flight: body horizontal, the right fist punched straight ahead, the left arm along the side,
#            legs straight behind, a slow powerful undulation
#   Special  breaking the chains: curls up gathering power (fists together at the chest, charge + Aura x3.5), then
#            bursts out - arms flung wide, chest out, legs apart (burst) - and settles back to fists on hips
from hero_anim.api import *  # noqa: F401,F403

HERO = "Superman"
SPECIAL_EVERY = (10, 18)

BLUE = (30, 72, 190)
RED = (196, 24, 32)
YELLOW = (250, 210, 40)
SKIN = (234, 184, 146)
POWER = (190, 220, 255)
COLORS = palette(Head=SKIN, Torso=BLUE, LowerTorso=RED, Arms=BLUE, Hands=BLUE, Legs=BLUE, LowerLegs=RED, Feet=RED)
EXTRAS = [
    extra("Head", "box", size=(1.24, 0.24, 1.2), offset=(0, 0.52, 0.06), color=(20, 20, 26)),
    extra("Head", "box", size=(1.26, 0.6, 0.3), offset=(0, 0.25, 0.5), color=(20, 20, 26)),
    extra("Head", "cone", size=(0.2, 0.3, 0.1), offset=(0.12, 0.42, -0.6), rot=(0, 0, 150), color=(20, 20, 26)),
    # the S shield and the belt
    extra("UpperTorso", "box", size=(0.66, 0.66, 0.1), offset=(0, 0.16, -0.52), rot=(0, 0, 45), color=RED),
    extra("UpperTorso", "box", size=(0.44, 0.44, 0.12), offset=(0, 0.16, -0.53), rot=(0, 0, 45), color=YELLOW),
    extra("LowerTorso", "box", size=(2.06, 0.14, 1.06), offset=(0, 0.14, 0), color=YELLOW),
    # the long red cape hangs from the shoulders (welded to the UpperTorso in the model)
    extra("UpperTorso", "box", size=(2.5, 4.3, 0.12), offset=(0, -1.35, 0.66), rot=(-7, 0, 0), color=RED),
    extra("UpperTorso", "box", size=(2.2, 0.26, 1.08), offset=(0, 0.72, 0.02), color=RED),
]

LEGS = merge(aim_leg("Right", down=1.0, out=0.02, knee=4, ankle=(-40, 0, 0)),
             aim_leg("Left", down=1.0, back=0.04, out=0.02, knee=14, ankle=(-44, 0, 0)))

# ------------------------------------------------------------------------------------------------ Idle
HERO_POSE = merge({"Waist": (6, 0, 0), "Neck": (10, 0, 0)}, LEGS, fists_on_hips())
HERO_IN = add(HERO_POSE, {"Waist": (3, 0, 0), "RootOffset": (0, 0.06, 0), "Neck": (-2, 0, 0)})
HORIZON = add(HERO_POSE, {"Neck": (4, 26, 0), "Waist": (0, 6, 0), "Root": (0, 4, 0)})
IDLE = clip("Idle", 4.6, {0.0: HERO_POSE, 1.4: HERO_IN, 2.6: HORIZON, 3.6: HORIZON})

# ------------------------------------------------------------------------------------------------ Move: flight
FLY = merge(fly_superman("Right"), aim_arm("Right", up=1.0, inward=0.3))
FLY_B = add(FLY, {"Root": (4, 0, 0), "RootOffset": (0, 0.12, 0), "RightShoulder": (-4, 0, 0), "LeftHip": (-4, 0, 0),
                  "RightHip": (3, 0, 0), "Neck": (-3, 0, 0)})
MOVE = clip("Move", 1.8, {0.0: FLY, 0.9: FLY_B}, motion=motion(lift=1.0, lean=0.3), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: chains
CURL = merge({"Root": (-14, 0, 0), "Waist": (-16, 0, 0), "Neck": (6, 0, 0), "RootOffset": (0, 0.3, 0)},
             aim_leg("Right", forward=0.7, down=1.0, knee=70, ankle=(-30, 0, 0)),
             aim_leg("Left", forward=0.55, down=1.0, knee=80, ankle=(-30, 0, 0)))
CURL = reach(CURL, "Right", (0.3, 3.45, -1.15), elbow_hint=(1.0, -0.6, 0.2), wrist=(0, 0, 10))
CURL = reach(CURL, "Left", (-0.3, 3.45, -1.15), elbow_hint=(-1.0, -0.6, 0.2), wrist=(0, 0, -10))
CURL["ease"] = "quad_out"
STRAIN = add(CURL, {"Waist": (-4, 0, 0), "RootOffset": (0, -0.08, 0), "RightShoulder": (0, 0, 4), "LeftShoulder": (0, 0, -4)})
STRAIN["ease"] = "quint_in"
BREAK = merge({"Root": (6, 0, 0), "Waist": (14, 0, 0), "Neck": (22, 0, 0), "RootOffset": (0, 0.45, 0)},
              aim_leg("Right", down=1.0, out=0.45, knee=6, ankle=(-30, 0, 0)),
              aim_leg("Left", down=1.0, out=0.45, knee=6, ankle=(-30, 0, 0)),
              aim_arm("Right", out=1.0, up=0.25, back=0.15, elbow=12, twist=-40),
              aim_arm("Left", out=1.0, up=0.25, back=0.15, elbow=12, twist=40))
BREAK["ease"] = "quart_out"
BREAK_HOLD = add(BREAK, {"Waist": (3, 0, 0), "RightShoulder": (0, 0, 4), "LeftShoulder": (0, 0, -4), "RootOffset": (0, 0.08, 0)})

SPECIAL = clip("Special", 3.6, {
    0.0: HERO_POSE,
    0.5: CURL,
    1.25: STRAIN,
    1.4: BREAK,
    2.3: BREAK_HOLD,
    3.6: HERO_POSE,
}, loop=False, effects=[
    charge("Both", 0.45, 1.45, color=POWER, size=0.9),
    burst("Both", 1.4, color=(225, 240, 255), count=50, speed=22),
    accent(boost=3.5, t0=0.4, t1=2.6),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.4}
CAMERAS = {"Move": "side"}
