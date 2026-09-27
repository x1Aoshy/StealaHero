# Hawks (My Hero Academia, Epic) - HeroMotion style "float" + red Feathers. Fierce Wings (the wing accessory rides
# the UpperTorso, so torso poses spread / fold them).
#   Idle     the laid-back pro hero: lounging on the air, leaning back with the hands behind his head, ankles
#            crossed, a lazy foot swing and a cocky look around
#   Move     wings-spread glide: body tilted into the flight, arms swept out and back like wings, legs together,
#            banking left and right
#   Special  feather barrage: arms fold across the chest, then fling out wide (a volley of feathers), a slash with
#            each arm, and a wings-open pose before lounging again
import math

from hero_anim.api import *  # noqa: F401,F403

HERO = "Hawks"
SPECIAL_EVERY = (9, 16)

JACKET = (132, 98, 64)
BLACK = (30, 30, 36)
RED = (214, 32, 42)
SKIN = (246, 204, 164)
HAIR = (238, 196, 96)
COLORS = palette(UpperTorso=JACKET, LowerTorso=BLACK, Arms=JACKET, Hands=BLACK, Legs=BLACK, Feet=BLACK, Head=SKIN)
EXTRAS = [
    extra("Head", "spikes", size=(0.75, 1.0, 0.8), offset=(0, 0.3, 0.1), rot=(-20, 0, 0), color=HAIR),
    extra("Head", "box", size=(1.2, 0.28, 1.15), offset=(0, 0.5, 0.05), color=HAIR),
    # yellow-tinted goggles
    extra("Head", "box", size=(1.1, 0.2, 0.06), offset=(0, 0.12, -0.54), color=(240, 200, 60)),
    # fur collar + the red wings (preview stand-ins for the wing accessory on the back)
    extra("UpperTorso", "box", size=(2.2, 0.35, 1.2), offset=(0, 0.72, 0), color=(200, 170, 120)),
]
# each wing is a fan of three long primary feathers rooted at the shoulder blades (length, angle from vertical, width)
for _side in (1.0, -1.0):
    for _len, _ang, _w, _z, _tone in ((3.4, 28.0, 0.5, 0.6, RED), (3.0, 54.0, 0.46, 0.67, (188, 24, 34)),
                                      (2.4, 80.0, 0.42, 0.74, (158, 18, 28))):
        _dx, _dy = math.sin(math.radians(_ang)), math.cos(math.radians(_ang))
        EXTRAS.append(extra("UpperTorso", "box", size=(_w, _len, 0.12),
                            offset=(_side * (0.35 + 0.5 * _len * _dx), 0.25 + 0.5 * _len * _dy, _z),
                            rot=(0, 0, -_side * _ang), color=_tone))

# ------------------------------------------------------------------------------------------------ Idle: lounging


def behind_head(pose, side, local=(0.42, 0.05, 0.62)):
    parts, _ = rig().fk(transforms_of(pose))
    r, p = parts["Head"]
    s = 1.0 if side == "Right" else -1.0
    return rbx.v_add(p, rbx.m_vec(r, (s * local[0], local[1], local[2])))


def lounge(lean=16.0, swing=0.0, look=(4, 0, 0)):
    p = merge({"RootOffset": (0, 0.55, 0), "Root": (lean, 0, 0), "Waist": (4, 0, 0), "Neck": look},
              aim_leg("Right", down=1.0, forward=0.55 + swing, knee=18, ankle=(-35, 0, 0)),
              aim_leg("Left", down=1.0, forward=0.5 - swing, inward=0.25, knee=26, ankle=(-40, 0, 0)))
    for side in ("Right", "Left"):
        s = 1.0 if side == "Right" else -1.0
        p = reach(p, side, behind_head(p, side), elbow_hint=(s * 1.0, 0.6, -0.4))
    return p


LOUNGE = lounge()
LOUNGE_B = lounge(20, 0.2, (8, -8, 4))
LOOK = lounge(14, -0.1, (-2, 34, -6))
LOOK["ease"] = "quart_out"

IDLE = clip("Idle", 4.8, {
    0.0: LOUNGE,
    1.4: LOUNGE_B,
    2.6: LOOK,
    3.5: add(LOOK, {"Neck": (2, -4, 0)}),
})

# ------------------------------------------------------------------------------------------------ Move: glide
GLIDE = merge({"Root": (-60, 0, 0), "RootOffset": (0, 0.9, 0), "Neck": (42, 0, 0), "Waist": (4, 0, 0)},
              aim_arm("Right", out=1.0, back=0.35, down=0.2, elbow=12, twist=-20),
              aim_arm("Left", out=1.0, back=0.35, down=0.2, elbow=12, twist=20),
              aim_leg("Right", down=1.0, back=0.08, knee=8, ankle=(-50, 0, 0)),
              aim_leg("Left", down=1.0, back=0.04, knee=16, ankle=(-50, 0, 0)))
BANK_L = add(GLIDE, {"Root": (0, 0, 12), "RightShoulder": (0, 0, 8), "LeftShoulder": (0, 0, 4)})
BANK_R = add(GLIDE, {"Root": (0, 0, -12), "RootOffset": (0, 0.12, 0), "RightShoulder": (0, 0, -4), "LeftShoulder": (0, 0, -8)})

MOVE = clip("Move", 2.4, {
    0.0: BANK_L,
    1.2: BANK_R,
}, motion=motion(lift=1.0, lean=0.35), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: feathers
BASE = {"RootOffset": (0, 0.5, 0), "Root": (0, 0, 0)}
LEGS = merge(aim_leg("Right", down=1.0, forward=0.2, knee=35, ankle=(-40, 0, 0)),
             aim_leg("Left", down=1.0, back=0.15, knee=45, ankle=(-40, 0, 0)))
FOLD = merge(BASE, LEGS, {"Waist": (-10, 0, 0), "Neck": (-6, 0, 0), "Root": (-6, 0, 0)})
FOLD = reach(FOLD, "Right", (-0.55, 3.95, -0.75), elbow_hint=(1.0, -0.4, -0.6))
FOLD = reach(FOLD, "Left", (0.55, 3.75, -0.85), elbow_hint=(-1.0, -0.4, -0.6))
FOLD["ease"] = "quad_in"
FLING = merge(BASE, LEGS, {"Root": (10, 0, 0), "Waist": (10, 0, 0), "Neck": (10, 0, 0)},
              aim_arm("Right", out=1.0, forward=0.45, down=0.15, elbow=4, wrist=(0, 0, 0)),
              aim_arm("Left", out=1.0, forward=0.45, down=0.15, elbow=4, wrist=(0, 0, 0)))
FLING["ease"] = "quart_out"
SLASH_R = merge(BASE, LEGS, {"Root": (2, 20, 0), "Waist": (0, 22, 0), "Neck": (4, -30, 0)},
                aim_arm("Right", forward=1.0, inward=0.7, down=0.1, elbow=6),
                aim_arm("Left", out=1.0, back=0.4, down=0.3, elbow=20))
SLASH_R["ease"] = "quart_out"
SLASH_L = merge(BASE, LEGS, {"Root": (2, -20, 0), "Waist": (0, -22, 0), "Neck": (4, 30, 0)},
                aim_arm("Left", forward=1.0, inward=0.7, down=0.1, elbow=6),
                aim_arm("Right", out=1.0, back=0.4, down=0.3, elbow=20))
SLASH_L["ease"] = "quart_out"
SPREAD = merge(BASE, LEGS, {"Root": (12, 0, 0), "Waist": (10, 0, 0), "Neck": (16, 0, 0), "RootOffset": (0, 0.75, 0)},
               aim_arm("Right", out=1.0, down=0.35, back=0.25, elbow=10), aim_arm("Left", out=1.0, down=0.35, back=0.25, elbow=10))
SPREAD["ease"] = "back_out"

SPECIAL = clip("Special", 3.6, {
    0.0: LOUNGE,
    0.4: FOLD,
    0.62: FLING,
    1.05: SLASH_R,
    1.45: SLASH_L,
    2.0: SPREAD,
    2.8: add(SPREAD, {"Neck": (-4, 10, 0)}),
    3.6: LOUNGE,
}, loop=False, effects=[
    burst("Both", 0.64, color=(230, 36, 48), count=36, speed=24),
    burst("RightHand", 1.07, color=(230, 36, 48), count=22, speed=24),
    burst("LeftHand", 1.47, color=(230, 36, 48), count=22, speed=24),
    accent(boost=3.5, t0=0.4, t1=2.9),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.05}
CAMERAS = {"Move": "front34"}
