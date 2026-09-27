# Nami (One Piece, Straw Hat navigator) - HeroMotion style "walk".
#   Idle     sassy stance: left hand on the hip, weight on one leg, head tilted, the right hand twirling the
#            Clima-Tact in front of her like a baton (the wrist spins about the forearm, the forearm circles a bit)
#   Move     runway strut: hips swaying side to side, feet crossing a little, left arm swinging, still twirling the
#            Clima-Tact in the right hand on every step
#   Special  Thunderbolt Tempo: raises the Clima-Tact overhead and spins it fast while a thundercloud charges (blue
#            spark glow on the staff), then points it at the sky - lightning burst - and a pleased hair flip
from hero_anim.api import *  # noqa: F401,F403

HERO = "Nami"
SPECIAL_EVERY = (9, 16)

HAIR = (250, 146, 50)
TOP = (246, 246, 246)
SKIRT = (70, 110, 190)
SKIN = (246, 206, 170)
STAFF = (90, 166, 232)
COLORS = palette(UpperTorso=TOP, LowerTorso=SKIRT, Arms=SKIN, Hands=SKIN, UpperLegs=SKIN, LowerLegs=SKIN,
                 Feet=(150, 90, 50), Head=SKIN)
EXTRAS = [
    # long tangerine hair down the back + fringe
    extra("Head", "box", size=(1.32, 0.34, 1.3), offset=(0, 0.46, 0.04), color=HAIR),
    extra("Head", "box", size=(1.34, 1.9, 0.42), offset=(0, -0.3, 0.46), color=HAIR),
    extra("Head", "box", size=(1.2, 0.2, 0.12), offset=(0, 0.36, -0.6), color=HAIR),
    # blue stripes on the white top, orange tattoo band on the left arm
    extra("UpperTorso", "box", size=(2.04, 0.16, 1.04), offset=(0, 0.3, 0), color=(60, 110, 200)),
    extra("UpperTorso", "box", size=(2.04, 0.16, 1.04), offset=(0, -0.05, 0), color=(60, 110, 200)),
    extra("LeftUpperArm", "box", size=(1.04, 0.28, 1.04), offset=(0, 0.05, 0), color=(60, 120, 200)),
    # the Clima-Tact: a three-section blue staff gripped in the middle (along the hand's Z)
    extra("RightHand", "box", size=(0.15, 0.15, 3.1), offset=(0, -0.02, 0), color=STAFF),
    extra("RightHand", "box", size=(0.22, 0.22, 0.12), offset=(0, -0.02, 0.55), color=(220, 230, 245)),
    extra("RightHand", "box", size=(0.22, 0.22, 0.12), offset=(0, -0.02, -0.55), color=(220, 230, 245)),
    extra("RightHand", "sphere", size=(0.3, 0.3, 0.3), offset=(0, -0.02, 1.55), color=(40, 90, 200)),
    extra("RightHand", "sphere", size=(0.3, 0.3, 0.3), offset=(0, -0.02, -1.55), color=(40, 90, 200)),
]

FEET = {"Left": (-0.42, 0.252, -0.22), "Right": (0.6, 0.252, 0.12)}


def body(tilt, head, drop=0.06):
    """Weight on the right leg, hip cocked, left fist on the hip; tilt = -1..1 sways the hip / head."""
    p = {"Root": (0, -6, -5 - 2 * tilt), "RootOffset": (0.16 + 0.04 * tilt, -drop, 0), "Waist": (2, 8, 3 + 2 * tilt),
         "Neck": head}
    p = plant_feet(p, feet=FEET, knee_hint=(-0.2, 0, -1))
    p = reach(p, "Left", (-1.22, 2.3, -0.05), elbow_hint=(-1, 0.25, 0.2), wrist=(0, 0, -20))
    return p


def twirl_arm(circle):
    """Right forearm held forward at waist height; `circle` (radians) moves it round a small circle (the twirl)."""
    import math
    return aim_arm("Right", down=1.0, forward=0.12 + 0.08 * math.sin(circle), out=0.25 + 0.08 * math.cos(circle),
                   elbow=80 + 6 * math.sin(circle))


def twirl_keys(length, turns, pose_at, wrist_flex=0.0, step=90.0):
    """Keys every `step` degrees of twirl: pose_at(u) gives the body at loop fraction u (0..1); the wrist spins
    `turns` full turns over the clip, linear so the spin speed stays constant."""
    import math
    n = int(round(turns * 360.0 / step))
    keys = {}
    for i in range(n):
        u = i / n
        p = merge(pose_at(u), twirl_arm(u * 2 * math.pi * max(1, round(turns / 2))))
        p["RightWrist"] = key((wrist_flex, -(step * i) % 360.0, 0.0), "linear")
        keys[round(length * u, 4)] = p
    return keys


# ------------------------------------------------------------------------------------------------ Idle
POSE_A = body(-1.0, (-4, -14, 10))
POSE_B = body(1.0, (2, -6, -4), drop=0.1)
IDLE_LEN = 3.2


def idle_at(u):
    import math
    return blend(POSE_A, POSE_B, 0.5 - 0.5 * math.cos(u * 2 * math.pi))


IDLE = clip("Idle", IDLE_LEN, twirl_keys(IDLE_LEN, 4, idle_at), ease="linear")

# ------------------------------------------------------------------------------------------------ Move: twirling strut
WALK = 1.0
GAIT = walk_cycle(length=WALK, stride=30.0, knee=30.0, arm=26.0, bounce=0.07)
GT = sorted(GAIT)
for i, t in enumerate(GT):
    s = 1.0 if i == 0 else -1.0 if i == 2 else 0.0
    # hip sway + the feet crossing in a little (catwalk); the contact poses drop so the heel really lands
    GAIT[t] = add(GAIT[t], {"Root": (0, 0, 7 * s), "Waist": (0, 0, -9 * s), "Neck": (0, 0, 4 * s),
                            "RightHip": (0, 0, -4), "LeftHip": (0, 0, 4), "RootOffset": (0, -0.2 if i % 2 == 0 else -0.09, 0)})


def walk_at(u):
    """Gait pose at loop fraction u: the 4 walk keys blended with the sine in/out the gait keys use (the clip is
    linear between these samples, so the body keeps the gait's eased rhythm while the wrist spins evenly)."""
    import math
    x = u * 4.0
    i = int(x) % 4
    f = x - int(x)
    return blend(GAIT[GT[i]], GAIT[GT[(i + 1) % 4]], 0.5 - 0.5 * math.cos(math.pi * f))


MOVE = clip("Move", WALK, twirl_keys(WALK, 2, walk_at), ease="linear", speed="auto")

# ------------------------------------------------------------------------------------------------ Special: Thunderbolt Tempo
RAISE = body(0.0, (18, -6, 0), drop=0.04)
RAISE.update(aim_arm("Right", up=1.0, out=0.25, forward=0.1, elbow=25))
STRIKE = plant_feet({"Root": (2, 12, -4), "RootOffset": (0.1, -0.2, 0.05), "Waist": (4, 10, 2), "Neck": (22, -12, 0)},
                    feet={"Left": (-0.55, 0.252, -0.35), "Right": (0.7, 0.252, 0.3)}, knee_hint=(0.3, 0, -1))
STRIKE.update(aim_arm("Right", up=1.0, forward=0.6, out=0.15, elbow=0, wrist=(-60, 0, 0)))
STRIKE = reach(STRIKE, "Left", (-1.22, 2.3, -0.05), elbow_hint=(-1, 0.25, 0.2), wrist=(0, 0, -20))
STRIKE["ease"] = "quart_out"
FLIP = body(0.0, (14, 26, 14), drop=0.06)
FLIP.update(aim_arm("Right", down=1.0, out=0.45, forward=0.2, elbow=40))
FLIP = reach(FLIP, "Left", (-0.75, 4.55, 0.35), elbow_hint=(-1, 0.3, 0.2), wrist=(0, 0, -40))  # hand flicks the hair
FLIP["ease"] = "back_out"

keys = {0.0: merge(idle_at(0.0), twirl_arm(0.0), {"RightWrist": key((0, 0, 0), "linear")})}
# spin overhead: 90-degree steps getting faster (0.12 s -> 0.06 s)
t, i = 0.35, 0
while t < 1.55:
    p = merge(RAISE, {"RightWrist": key((0, -(90.0 * (i + 1)) % 360.0, 0), "linear")})
    keys[round(t, 3)] = p
    t += max(0.06, 0.12 - 0.012 * i)
    i += 1
keys[round(t + 0.12, 3)] = merge(STRIKE, {"RightWrist": (-60, 0, 0)})
STRIKE_T = round(t + 0.12, 3)
keys[round(STRIKE_T + 0.6, 3)] = merge(add(STRIKE, {"Root": (2, 0, 0)}), {"ease": "sine_inout"})
keys[round(STRIKE_T + 1.0, 3)] = FLIP
keys[round(STRIKE_T + 1.5, 3)] = merge(FLIP, {"ease": "sine_inout"})
SPECIAL_LEN = round(STRIKE_T + 2.0, 3)
keys[SPECIAL_LEN] = keys[0.0]

SPECIAL = clip("Special", SPECIAL_LEN, keys, loop=False, effects=[
    charge("RightHand", 0.4, STRIKE_T, color=(120, 200, 255), size=1.0),
    burst("RightHand", STRIKE_T + 0.01, color=(255, 240, 110), count=45, speed=24),
    burst("RightHand", STRIKE_T + 0.08, color=(160, 220, 255), count=25, speed=12),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": STRIKE_T}
CAMERAS = {"Move": "side34", "Special": "front34"}
