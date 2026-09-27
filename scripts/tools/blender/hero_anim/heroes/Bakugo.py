# Bakugo (My Hero Academia, Common) - HeroMotion style "dash" + orange Sparks. Explosion.
#   Idle     hunched and hostile: low stance, arms out with the palms open, small explosions popping in each palm
#            (pop... pop... BOOM with both), the head jutting forward
#   Move     explosion-propelled dash: body tilted forward in the air, arms thrown back with the palms blasting
#            behind him in turns (a burst per blast), legs trailing
#   Special  HOWITZER IMPACT: crouch, a blast launches him up, he spins like a drill with the arms out and the
#            palms on fire, then slams both palms forward in a huge explosion and lands
from hero_anim.api import *  # noqa: F401,F403

HERO = "Bakugo"
SPECIAL_EVERY = (8, 14)

BLACK = (32, 32, 36)
ORANGE = (240, 132, 40)
SKIN = (246, 206, 168)
HAIR = (240, 228, 170)
FIRE = (255, 150, 40)
COLORS = palette(UpperTorso=BLACK, LowerTorso=(40, 40, 44), UpperArms=SKIN, LowerArms=(90, 94, 100),
                 Hands=(60, 62, 66), Legs=(44, 46, 50), Feet=BLACK, Head=SKIN)
EXTRAS = [
    # the spiky ash-blond hair
    extra("Head", "spikes", size=(0.9, 1.2, 0.9), offset=(0, 0.3, 0.1), rot=(-6, 0, 0), color=HAIR),
    extra("Head", "spikes", size=(0.7, 0.9, 0.7), offset=(0.5, 0.15, 0.1), rot=(0, 0, -60), color=HAIR),
    extra("Head", "spikes", size=(0.7, 0.9, 0.7), offset=(-0.5, 0.15, 0.1), rot=(0, 0, 60), color=HAIR),
    extra("Head", "box", size=(1.2, 0.3, 1.15), offset=(0, 0.5, 0.05), color=HAIR),
    # black eye mask with the orange rim + the orange X on the chest
    extra("Head", "box", size=(1.1, 0.26, 0.06), offset=(0, 0.1, -0.54), color=(26, 26, 30)),
    extra("UpperTorso", "box", size=(0.25, 1.7, 0.06), offset=(0, 0.0, -0.52), rot=(0, 0, 35), color=ORANGE),
    extra("UpperTorso", "box", size=(0.25, 1.7, 0.06), offset=(0, 0.0, -0.52), rot=(0, 0, -35), color=ORANGE),
    # the grenade gauntlets
    extra("LeftLowerArm", "box", size=(1.3, 0.8, 1.3), offset=(0, -0.1, 0), color=(110, 114, 120)),
    extra("RightLowerArm", "box", size=(1.3, 0.8, 1.3), offset=(0, -0.1, 0), color=(110, 114, 120)),
    extra("LeftLowerArm", "box", size=(1.34, 0.18, 1.34), offset=(0, 0.2, 0), color=ORANGE),
    extra("RightLowerArm", "box", size=(1.34, 0.18, 1.34), offset=(0, 0.2, 0), color=ORANGE),
]

# ------------------------------------------------------------------------------------------------ Idle
FEET = {"Left": (-0.9, 0.252, -0.25), "Right": (0.9, 0.252, 0.2)}


def hunch(drop=0.35, pop_r=0.0, pop_l=0.0, head=(22, 0, 0)):
    p = plant_feet({"Root": (-18, 0, 0), "RootOffset": (0, -drop, 0), "Waist": (-6, 0, 0), "Neck": head}, FEET,
                   knee_hint=(0.7, 0.0, -1.0))
    p.update(aim_arm("Right", out=0.85, down=0.7 - pop_r, forward=0.4, elbow=35 - pop_r * 25, twist=-20, wrist=(-50, 0, 0)))
    p.update(aim_arm("Left", out=0.85, down=0.7 - pop_l, forward=0.4, elbow=35 - pop_l * 25, twist=20, wrist=(-50, 0, 0)))
    return p


HUNCH = hunch()
POP_R = merge(hunch(0.37, pop_r=0.45), {"ease": "quart_out"})
POP_L = merge(hunch(0.37, pop_l=0.45, head=(20, 10, 0)), {"ease": "quart_out"})
BOOM = merge(hunch(0.45, 0.6, 0.6, head=(28, 0, 0)), {"ease": "quart_out"})

IDLE = clip("Idle", 3.4, {
    0.0: HUNCH,
    0.55: POP_R,
    0.85: HUNCH,
    1.35: POP_L,
    1.65: add(HUNCH, {"Neck": (0, -10, 0)}),
    2.3: BOOM,
    2.75: HUNCH,
}, effects=[
    burst("RightHand", 0.56, color=FIRE, count=10, speed=7),
    burst("LeftHand", 1.36, color=FIRE, count=10, speed=7),
    burst("Both", 2.31, color=(255, 190, 80), count=16, speed=10),
])

# ------------------------------------------------------------------------------------------------ Move: blast flight
FLY = merge({"Root": (-58, 0, 0), "RootOffset": (0, 1.1, 0), "Waist": (4, 0, 0), "Neck": (40, 0, 0)},
            aim_leg("Right", down=1.0, back=0.15, knee=30, ankle=(-40, 0, 0)),
            aim_leg("Left", down=1.0, forward=0.3, knee=70, ankle=(-40, 0, 0)))
FLY.update(aim_arm("Right", down=1.0, back=0.35, out=0.55, elbow=10, twist=-20, wrist=(-60, 0, 0)))
FLY.update(aim_arm("Left", down=1.0, back=0.35, out=0.55, elbow=10, twist=20, wrist=(-60, 0, 0)))
KICK_R = add(FLY, {"RightShoulder": (-14, 0, 6), "RootOffset": (0, 0.1, -0.12), "Root": (-3, 0, -5)})
KICK_R["ease"] = "quart_out"
KICK_L = add(FLY, {"LeftShoulder": (-14, 0, -6), "RootOffset": (0, 0.1, -0.12), "Root": (-3, 0, 5)})
KICK_L["ease"] = "quart_out"

MOVE = clip("Move", 0.8, {
    0.0: KICK_R,
    0.2: FLY,
    0.4: KICK_L,
    0.6: FLY,
}, effects=[
    charge("Both", color=FIRE, size=0.45, light=False),
    burst("RightHand", 0.0, color=FIRE, count=12, speed=12),
    burst("LeftHand", 0.4, color=FIRE, count=12, speed=12),
], motion=motion(lift=0.0, lean=0.5), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: Howitzer Impact


def spun(pitch, yaw):
    """Root euler for 'tilted by pitch, then spun about the world vertical by yaw' (the drill spin)."""
    return tuple(round(v, 3) + 0.0 for v in rbx.to_euler_xyz(rbx.m_mul(rbx.rot_y(yaw), rbx.rot_x(pitch))))


CROUCH = merge(crouch(drop=0.7, width=0.3, lean=24, knee_out=0.8), {"Neck": (26, 0, 0)},
               aim_arm("Right", down=1.0, back=0.9, out=0.4, elbow=20, wrist=(-60, 0, 0)),
               aim_arm("Left", down=1.0, back=0.9, out=0.4, elbow=20, wrist=(-60, 0, 0)))
CROUCH["ease"] = "quad_in"
DRILL = merge({"RootOffset": (0, 2.0, 0), "Waist": (0, 0, 0), "Neck": (12, 0, 0)},
              aim_arm("Right", out=1.0, down=0.25, back=0.2, elbow=10, wrist=(-60, 0, 0)),
              aim_arm("Left", out=1.0, down=0.25, back=0.2, elbow=10, wrist=(-60, 0, 0)),
              aim_leg("Right", down=1.0, forward=0.4, knee=95, ankle=(-40, 0, 0)),
              aim_leg("Left", down=1.0, forward=0.2, knee=110, ankle=(-40, 0, 0)))


def drill(yaw, up=0.0):
    p = add(DRILL, {"RootOffset": (0, up, 0)})
    p["Root"] = key(spun(-22, yaw), "linear")
    return p


IMPACT = merge({"Root": (-34, 0, 0), "RootOffset": (0, 1.3, -0.6), "Waist": (-8, 0, 0), "Neck": (30, 0, 0)},
               aim_leg("Right", down=1.0, back=0.3, knee=40, ankle=(-40, 0, 0)),
               aim_leg("Left", down=1.0, back=0.1, knee=60, ankle=(-40, 0, 0)),
               aim_arm("Right", forward=1.0, down=0.25, inward=0.25, elbow=2, wrist=(-70, 0, 0)),
               aim_arm("Left", forward=1.0, down=0.25, inward=0.25, elbow=2, wrist=(-70, 0, 0)))
IMPACT["ease"] = "quart_out"
LAND = merge(crouch(drop=0.75, width=0.45, lean=22, forward=0.3, knee_out=0.8), {"Neck": (30, 0, 0)},
             aim_arm("Right", forward=0.6, down=0.8, out=0.35, elbow=30, wrist=(-50, 0, 0)),
             aim_arm("Left", forward=0.6, down=0.8, out=0.35, elbow=30, wrist=(-50, 0, 0)))
LAND["ease"] = "quad_out"

SPECIAL = clip("Special", 3.7, {
    0.0: HUNCH,
    0.35: CROUCH,
    0.55: merge(drill(0), {"ease": "quad_out"}),
    0.72: drill(90, 0.15),
    0.88: drill(180, 0.25),
    1.04: drill(270, 0.3),
    1.2: drill(360, 0.3),
    1.36: drill(450, 0.25),
    1.52: drill(540, 0.15),
    1.68: drill(630, 0.05),
    1.84: IMPACT,
    2.4: LAND,
    3.7: HUNCH,
}, loop=False, effects=[
    burst("Both", 0.5, color=FIRE, count=24, speed=14),
    charge("Both", 0.55, 1.9, color=FIRE, size=1.1),
    burst("Both", 1.86, color=(255, 200, 90), count=60, speed=28),
    charge("Both", 1.84, 2.4, color=(255, 230, 160), size=1.8),
    accent(boost=3.5, t0=0.4, t1=2.4),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 2.3, "Move": 0.0, "Special": 1.04}
CAMERAS = {"Move": "side", "Special": "wide"}
