# Uraraka (My Hero Academia, Common) - HeroMotion style "float" + pink Glitter. Zero Gravity.
#   Idle     weightless drift: floating with the knees folded under her, fingertips pressed together at the chest
#            (her quirk gesture), the body slowly pitching / rolling as if in orbit
#   Move     zero-gravity tumble: a slow forward somersault per loop - stretched out, tucked, upside down, unfurl
#   Special  "Release!": palms touch the air ahead (pink glow), she floats up spinning with the arms wide, then presses
#            her fingertips together - release burst - and settles back into the drift
from hero_anim.api import *  # noqa: F401,F403

HERO = "Uraraka"
SPECIAL_EVERY = (9, 16)

BLACK = (34, 30, 44)
PINK = (240, 130, 170)
SKIN = (248, 212, 180)
HAIR = (112, 70, 48)
COLORS = palette(Torso=BLACK, LowerTorso=PINK, Arms=BLACK, Hands=PINK, Legs=BLACK, Feet=(236, 236, 242), Head=SKIN)
EXTRAS = [
    # brown bob + the fringe
    extra("Head", "box", size=(1.3, 0.5, 1.2), offset=(0, 0.42, 0.06), color=HAIR),
    extra("Head", "box", size=(0.3, 0.8, 1.0), offset=(-0.58, 0.02, 0.05), color=HAIR),
    extra("Head", "box", size=(0.3, 0.8, 1.0), offset=(0.58, 0.02, 0.05), color=HAIR),
    # pink blush + collar / gauntlet cuffs
    extra("Head", "box", size=(0.22, 0.1, 0.05), offset=(-0.32, -0.12, -0.53), color=(240, 140, 150)),
    extra("Head", "box", size=(0.22, 0.1, 0.05), offset=(0.32, -0.12, -0.53), color=(240, 140, 150)),
    extra("UpperTorso", "box", size=(1.2, 0.3, 1.06), offset=(0, 0.66, 0), color=PINK),
    extra("LeftLowerArm", "box", size=(1.12, 0.45, 1.12), offset=(0, -0.3, 0), color=(236, 236, 242)),
    extra("RightLowerArm", "box", size=(1.12, 0.45, 1.12), offset=(0, -0.3, 0), color=(236, 236, 242)),
]

# ------------------------------------------------------------------------------------------------ Idle: drift
KNEEL = merge(aim_leg("Right", down=1.0, back=0.4, knee=105, ankle=(-40, 0, 0)),
              aim_leg("Left", down=1.0, forward=0.25, knee=85, ankle=(-35, 0, 0)))


def fingertips(pose, height=3.35, reach_z=-0.95):
    """Both forearms turned inward so the fingertips (the hands' ends) meet in front of the chest."""
    p = reach(pose, "Right", (0.28, height, reach_z), elbow_hint=(1.0, -0.5, 0.2), wrist=(0, 0, 25))
    return reach(p, "Left", (-0.28, height, reach_z), elbow_hint=(-1.0, -0.5, 0.2), wrist=(0, 0, -25))


def drift(pitch=6.0, roll=4.0, yaw=0.0, up=0.5):
    p = merge({"RootOffset": (0, up, 0), "Root": (pitch, yaw, roll), "Waist": (2, 0, 0), "Neck": (4, -yaw * 0.5, -roll)},
              KNEEL)
    return fingertips(p, 3.35 + up)


FLOAT = drift()
FLOAT_B = add(drift(14, -5, 8, 0.66), {"LeftHip": (8, 0, 0), "RightKnee": (12, 0, 0)})
FLOAT_C = add(drift(0, 9, -6, 0.58), {"RightHip": (10, 0, 0), "LeftKnee": (-10, 0, 0)})

IDLE = clip("Idle", 5.4, {
    0.0: FLOAT,
    1.4: FLOAT_B,
    2.7: add(FLOAT, {"RootOffset": (0, 0.08, 0)}),
    4.0: FLOAT_C,
})

# ------------------------------------------------------------------------------------------------ Move: tumble
# one full forward somersault per loop (Root pitch keys 90 degrees apart, linear so the spin is even); the body
# stretches out on the way up and tucks through the bottom. RootOffset keeps the head clear of the ground.
LIFT = 1.25
STRETCH = merge({"RootOffset": (0, LIFT, 0), "Neck": (10, 0, 0), "Waist": (6, 0, 0)},
                aim_arm("Right", out=1.0, up=0.35, forward=0.2, elbow=20), aim_arm("Left", out=1.0, up=0.35, forward=0.2, elbow=20),
                aim_leg("Right", down=1.0, back=0.2, out=0.25, knee=20, ankle=(-40, 0, 0)),
                aim_leg("Left", down=1.0, back=0.35, out=0.2, knee=45, ankle=(-40, 0, 0)))
TUCK = merge({"RootOffset": (0, LIFT, 0), "Neck": (-25, 0, 0), "Waist": (-18, 0, 0)},
             aim_leg("Right", forward=1.0, up=0.35, knee=125, ankle=(-30, 0, 0)),
             aim_leg("Left", forward=1.0, up=0.25, knee=130, ankle=(-30, 0, 0)))
TUCK = reach(TUCK, "Right", (0.62, 2.5 + LIFT, -1.25), elbow_hint=(1.0, 0.0, 0.3))
TUCK = reach(TUCK, "Left", (-0.62, 2.45 + LIFT, -1.25), elbow_hint=(-1.0, 0.0, 0.3))
UNFURL = merge({"RootOffset": (0, LIFT, 0), "Neck": (0, 0, 0), "Waist": (0, 0, 0)},
               aim_arm("Right", out=1.0, down=0.4, forward=0.4, elbow=35), aim_arm("Left", out=1.0, down=0.4, forward=0.4, elbow=35),
               aim_leg("Right", down=1.0, forward=0.4, knee=70, ankle=(-30, 0, 0)),
               aim_leg("Left", down=1.0, forward=0.2, knee=90, ankle=(-30, 0, 0)))


def spin(pose, pitch):
    return merge(pose, {"Root": key((pitch, 0, 0), "linear")})


MOVE = clip("Move", 4.0, {
    0.0: spin(STRETCH, -30),
    1.0: spin(TUCK, -120),
    2.0: spin(TUCK, -210),
    3.0: spin(UNFURL, -300),
}, motion=motion(lift=1.0, lean=0.0), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: Release!
TOUCH = merge({"RootOffset": (0, 0.35, -0.2), "Root": (-14, 0, 0), "Waist": (-4, 0, 0), "Neck": (10, 0, 0)}, KNEEL,
              aim_arm("Right", forward=1.0, up=0.1, inward=0.12, elbow=8, wrist=(-65, 0, 0)),
              aim_arm("Left", forward=1.0, up=0.1, inward=0.12, elbow=8, wrist=(-65, 0, 0)))
TOUCH["ease"] = "back_out"
WIDE = merge({"RootOffset": (0, 1.5, 0), "Waist": (8, 0, 0), "Neck": (14, 0, 0)},
             aim_arm("Right", out=1.0, up=0.45, elbow=15), aim_arm("Left", out=1.0, up=0.45, elbow=15),
             aim_leg("Right", down=1.0, back=0.3, knee=70, ankle=(-40, 0, 0)),
             aim_leg("Left", down=1.0, forward=0.3, knee=50, ankle=(-40, 0, 0)))


def turn(pose, yaw, up=0.0, ease="linear"):
    p = add(pose, {"RootOffset": (0, up, 0)})
    p["Root"] = key((6, yaw, 0), ease)
    return p


RELEASE = fingertips(merge({"RootOffset": (0, 0.7, 0), "Root": (4, 0, 0), "Waist": (-6, 0, 0), "Neck": (-8, 0, 0)}, KNEEL),
                     3.3 + 0.7, -0.9)
RELEASE["ease"] = "quart_out"

SPECIAL = clip("Special", 4.2, {
    0.0: FLOAT,
    0.45: TOUCH,
    1.05: turn(WIDE, 0, ease="sine_in"),
    1.5: turn(WIDE, 90, 0.15),
    1.95: turn(WIDE, 180, 0.2),
    2.4: turn(WIDE, 270, 0.1, "sine_out"),
    2.95: RELEASE,
    3.5: add(RELEASE, {"Neck": (4, 0, 0)}),
    4.2: FLOAT,
}, loop=False, effects=[
    charge("Both", 0.4, 1.2, color=(255, 150, 200), size=0.8),
    accent(boost=3.0, t0=1.0, t1=3.2),
    burst("Both", 2.97, color=(255, 170, 215), count=40, speed=16),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 1.0, "Special": 1.5}
CAMERAS = {"Move": "side", "Special": "front34"}
