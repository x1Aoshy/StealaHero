# Trunks (Dragon Ball, Common) - HeroMotion style "dash" + pale blue Sparks. Future Trunks: jacket, sword on the back.
#   Idle     ready fighter: knees soft, fists clenched, chin down glaring; weight shift, then the guard snaps up
#            (fists at the chin) for a beat and drops again
#   Move     super-speed dash: sprint leaning hard forward with both arms swept straight back
#   Special  sword strike: grabs the hilt, jumps drawing the blade two-handed overhead, slashes down on landing,
#            a flourish to the side and sheathes it again
from hero_anim.api import *  # noqa: F401,F403

HERO = "Trunks"
SPECIAL_EVERY = (9, 16)

JACKET = (38, 50, 100)
TANK = (28, 28, 32)
PANTS = (72, 72, 84)
SKIN = (246, 204, 164)
HAIR = (190, 160, 222)
COLORS = palette(UpperTorso=JACKET, LowerTorso=TANK, UpperArms=JACKET, LowerArms=SKIN, Hands=SKIN, Legs=PANTS,
                 Feet=(228, 186, 56), Head=SKIN)
EXTRAS = [
    # lavender bowl cut
    extra("Head", "box", size=(1.24, 0.42, 1.18), offset=(0, 0.45, 0.04), color=HAIR),
    extra("Head", "box", size=(1.24, 0.5, 0.2), offset=(0, 0.25, 0.52), color=HAIR),
    extra("Head", "box", size=(0.8, 0.22, 0.16), offset=(0, 0.3, -0.54), color=HAIR),
    # the sword on the back (hilt over the right shoulder)
    extra("UpperTorso", "box", size=(0.18, 2.6, 0.08), offset=(0.1, 0.1, 0.62), rot=(0, 0, -35), color=(196, 200, 210)),
    extra("UpperTorso", "box", size=(0.62, 0.12, 0.22), offset=(0.84, 1.17, 0.62), rot=(0, 0, -35), color=(90, 60, 30)),
    extra("UpperTorso", "box", size=(0.2, 0.62, 0.2), offset=(1.02, 1.45, 0.62), rot=(0, 0, -35), color=(60, 40, 26)),
]

# ------------------------------------------------------------------------------------------------ Idle
FEET = {"Left": (-0.72, 0.252, -0.2), "Right": (0.72, 0.252, 0.14)}
HILT = (1.0, 4.62, 0.62)  # rig space: the grip over the right shoulder


def stance(shift=0.0, head=(-8, 10, 0), drop=0.12):
    """Ready fighter: knees soft, fists clenched a little out and forward, chin down, glaring."""
    p = plant_feet({"Root": (-3, 4 * shift - 8, -2 * shift), "RootOffset": (0.08 * shift, -drop, 0), "Waist": (0, -4, 0),
                    "Neck": head}, FEET, knee_hint=(0.5, 0.0, -1.0))
    p.update(aim_arm("Right", down=1.0, out=0.3, forward=0.2, elbow=35, twist=-25))
    p.update(aim_arm("Left", down=1.0, out=0.3, forward=0.28, elbow=40, twist=25))
    return p


CALM = stance()
CALM_B = stance(1.0, head=(-6, 20, 0), drop=0.16)
GUARD = merge(stance(0.4, head=(-10, -4, 0), drop=0.22), guard(), {"ease": "quart_out"})

IDLE = clip("Idle", 4.6, {
    0.0: CALM,
    1.2: CALM_B,
    2.2: GUARD,
    3.1: add(GUARD, {"Neck": (2, 12, 0), "Waist": (0, 6, 0)}),
    3.8: CALM,
})

# ------------------------------------------------------------------------------------------------ Move: dash
# super-speed sprint: the run_cycle legs with the arms swept straight back (the anime speed dash)
RUN = run_cycle(length=0.5, stride=60.0, knee=95.0, arm=40.0, bounce=0.2, lean=30.0)
for i, t in enumerate(sorted(RUN)):
    swing = 8 if i == 0 else -8 if i == 2 else 0
    RUN[t]["Neck"] = (22, 0, 0)
    RUN[t].update(aim_arm("Right", down=0.95, back=1.0, out=0.22, elbow=6, twist=-40, wrist=(-25, 0, 0)))
    RUN[t].update(aim_arm("Left", down=0.95, back=1.0, out=0.22, elbow=6, twist=40, wrist=(-25, 0, 0)))
    RUN[t] = add(RUN[t], {"RightShoulder": (swing, 0, 0), "LeftShoulder": (-swing, 0, 0)})
MOVE = clip("Move", 0.5, RUN, speed="auto")

# ------------------------------------------------------------------------------------------------ Special: sword strike
ANTICIPATE = reach(merge(crouch(drop=0.35, width=0.1, lean=10), {"Neck": (6, 0, 0)}), "Right", (1.0, 4.3, 0.62),
                   elbow_hint=(1.0, 0.8, -0.4), wrist=(30, 0, 0))
ANTICIPATE.update(aim_arm("Left", down=1.0, out=0.3, forward=0.3, elbow=45))
ANTICIPATE["ease"] = "quad_in"

LEAP = merge({"Root": (8, 0, 0), "RootOffset": (0, 1.5, 0.1), "Waist": (8, 0, 0), "Neck": (4, 0, 0)},
             aim_leg("Right", down=1.0, forward=0.8, knee=100, ankle=(-30, 0, 0)),
             aim_leg("Left", down=1.0, forward=0.3, knee=120, ankle=(-30, 0, 0)),
             aim_arm("Right", up=1.0, back=0.45, inward=0.25, elbow=35, wrist=(-30, 0, 0)),
             aim_arm("Left", up=1.0, back=0.45, inward=0.3, elbow=40, wrist=(-30, 0, 0)))
LEAP["ease"] = "quad_out"
APEX = add(LEAP, {"RootOffset": (0, 0.25, 0), "Waist": (4, 0, 0), "RightShoulder": (8, 0, 0), "LeftShoulder": (8, 0, 0)})
APEX["ease"] = "quart_in"

SLASH = plant_feet({"Root": (-20, 0, 0), "RootOffset": (0, -0.55, -0.55), "Waist": (-12, 0, 0), "Neck": (24, 0, 0)},
                   {"Left": (-0.7, 0.252, -1.1), "Right": (0.7, 0.252, 0.9)}, knee_hint=(0.4, 0.0, -1.0))
SLASH.update(aim_arm("Right", forward=0.9, down=0.75, inward=0.35, elbow=6, wrist=(10, 0, 0)))
SLASH.update(aim_arm("Left", forward=0.9, down=0.75, inward=0.4, elbow=10, wrist=(10, 0, 0)))
SLASH["ease"] = "quart_out"
FOLLOW = add(SLASH, {"Waist": (-4, 0, 0), "RootOffset": (0, -0.05, 0)})

FLOURISH = plant_feet({"Root": (-6, -20, 0), "RootOffset": (0, -0.35, -0.2), "Waist": (0, -18, 0), "Neck": (4, 36, 0)},
                      {"Left": (-0.7, 0.252, -0.6), "Right": (0.75, 0.252, 0.6)}, knee_hint=(0.4, 0.0, -1.0))
FLOURISH.update(aim_arm("Right", out=1.0, down=0.3, back=0.15, elbow=4, wrist=(0, 0, 0)))
FLOURISH.update(aim_arm("Left", forward=0.6, down=0.8, out=0.2, elbow=50))
FLOURISH["ease"] = "back_out"
SHEATHE = reach(stance(0.2, head=(-10, 0, 0)), "Right", HILT, elbow_hint=(1.0, 0.8, -0.4), wrist=(30, 0, 0))
SHEATHE["ease"] = "quad_out"

SPECIAL = clip("Special", 3.4, {
    0.0: CALM,
    0.3: ANTICIPATE,
    0.55: LEAP,
    0.85: APEX,
    1.05: SLASH,
    1.45: FOLLOW,
    1.95: FLOURISH,
    2.6: SHEATHE,
    3.4: CALM,
}, loop=False, effects=[
    charge("RightHand", 0.55, 1.05, color=(200, 230, 255), size=0.6),
    burst("RightHand", 1.07, color=(210, 235, 255), count=40, speed=22),
    burst("RightHand", 1.97, color=(180, 220, 255), count=18, speed=12),
    accent(boost=3.0, t0=0.5, t1=2.0),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 0.85}
CAMERAS = {"Move": "side", "Special": "side34"}
