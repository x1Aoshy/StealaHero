# Hulk (Avengers) - HeroMotion style "stomp" (dust puff per footfall).
#   Idle     hulking brute: knees bent wide, back hunched, head low and forward, huge arms hanging in front with the
#            fists half clenched; heavy heaving breaths (chest and shoulders pump) and a snarling look aside
#   Move     heavy stomp: slow ground-shaking steps, hunched, arms swinging wide and low (the stomp dip stays at half)
#   Special  HULK SMASH: rears up with both hammer fists raised overhead, slams them into the ground (deep squat,
#            dust burst), then straightens into a chest-out roar with the arms flung wide
from hero_anim.api import *  # noqa: F401,F403

HERO = "Hulk"
SPECIAL_EVERY = (9, 16)

GREEN = (78, 156, 60)
DARK = (56, 118, 44)
PURPLE = (96, 52, 132)
COLORS = palette(Head=DARK, Torso=GREEN, LowerTorso=PURPLE, Arms=GREEN, Hands=DARK, Legs=PURPLE, Feet=DARK)
EXTRAS = [
    # messy black hair, a heavy brow and torn trouser hems
    extra("Head", "box", size=(1.26, 0.22, 1.1), offset=(0, 0.5, 0.1), rot=(8, 0, 0), color=(24, 26, 24)),
    extra("Head", "box", size=(1.28, 0.8, 0.36), offset=(0, 0.2, 0.46), color=(24, 26, 24)),
    extra("Head", "spikes", size=(0.7, 0.45, 0.7), offset=(0, 0.5, -0.3), rot=(-70, 0, 0), color=(24, 26, 24)),
    extra("Head", "spikes", size=(0.8, 0.4, 0.8), offset=(0, 0.58, 0.2), rot=(-15, 0, 0), color=(24, 26, 24)),
    extra("RightLowerLeg", "box", size=(1.08, 0.26, 1.08), offset=(0, 0.1, 0), rot=(0, 0, 8), color=PURPLE),
    extra("LeftLowerLeg", "box", size=(1.08, 0.26, 1.08), offset=(0, 0.1, 0), rot=(0, 0, -8), color=PURPLE),
]


def _brute_arms(out=0.38, forward=0.4, elbow=30, twist=25):
    return merge(aim_arm("Right", down=1.0, out=out, forward=forward, elbow=elbow, twist=-twist, wrist=(-15, 0, 0)),
                 aim_arm("Left", down=1.0, out=out, forward=forward, elbow=elbow, twist=twist, wrist=(-15, 0, 0)))


# ------------------------------------------------------------------------------------------------ Idle
HUNCH = crouch(drop=0.42, width=0.32, lean=6, knee_out=0.9)
HUNCH.update({"Waist": (-18, 0, 0), "Neck": (16, 0, 0)})
HUNCH.update(_brute_arms())
HEAVE = add(HUNCH, {"Waist": (9, 0, 0), "Neck": (-5, 0, 0), "RootOffset": (0, 0.08, 0),
                    "RightShoulder": (0, 0, 7), "LeftShoulder": (0, 0, -7), "RightElbow": (-6, 0, 0), "LeftElbow": (-6, 0, 0)})
HEAVE["ease"] = "quad_in"
BLOW = add(HUNCH, {"Waist": (-4, 0, 0), "RootOffset": (0, -0.04, 0), "RightElbow": (10, 0, 0), "LeftElbow": (10, 0, 0),
                   "RightWrist": (-20, 0, 0), "LeftWrist": (-20, 0, 0)})
SNARL = add(HUNCH, {"Neck": (4, 34, 8), "Waist": (0, 10, 0), "RightShoulder": (6, 0, 6), "RightElbow": (18, 0, 0)})
SNARL["ease"] = "back_out"

IDLE = clip("Idle", 4.2, {
    0.0: HUNCH,
    0.9: HEAVE,
    1.25: BLOW,
    2.1: HEAVE,
    2.45: merge(BLOW, {"ease": "quad_out"}),
    3.0: SNARL,
    3.6: HUNCH,
})

# ------------------------------------------------------------------------------------------------ Move: stomp
STOMP = stomp_cycle(length=1.3, stride=30.0, knee=44.0, arm=24.0, drop=0.32)
for _p in STOMP.values():
    _p["Waist"] = add({"Waist": _p.get("Waist", (0, 0, 0))}, {"Waist": (-16, 0, 0)})["Waist"]
    _p["Neck"] = (15, 0, 0)
    for _s in ("Right", "Left"):
        x, y, z = _p.get(_s + "Shoulder", (0, 0, 0))
        _p[_s + "Shoulder"] = (x + 8, y, z + (27 if _s == "Right" else -27))
        _p[_s + "Elbow"] = (max(_p.get(_s + "Elbow", (0, 0, 0))[0], 28.0), 0, 0)
        _p[_s + "Wrist"] = (-15, 0, 0)
MOVE = clip("Move", 1.3, STOMP, motion=motion(lift=0.5, lean=1.0), speed="auto")

# ------------------------------------------------------------------------------------------------ Special: HULK SMASH
REAR = {"Root": (4, 0, 0), "RootOffset": (0, 0.24, 0.1), "Waist": (10, 0, 0), "Neck": (14, 0, 0)}
REAR = plant_feet(REAR, feet={"Left": (-0.8, 0.252, 0.05), "Right": (0.8, 0.252, 0.05)}, knee_hint=(0.6, 0, -1))
# both hammer fists reared high over the shoulders, the elbows flared (the roaring head stays visible between them;
# the blocky arms are too short to lock the fists above the head without hiding it)
REAR = reach(REAR, "Right", (1.35, 5.6, 0.4), elbow_hint=(1.0, 0.2, 0.4), wrist=(0, 0, -15))
REAR = reach(REAR, "Left", (-1.35, 5.6, 0.4), elbow_hint=(-1.0, 0.2, 0.4), wrist=(0, 0, 15))
REAR_HOLD = add(REAR, {"Waist": (4, 0, 0), "RootOffset": (0, 0.06, 0.04)})
REAR_HOLD["ease"] = "quart_in"
SMASH = crouch(drop=1.15, width=0.62, lean=34, knee_out=1.1)
SMASH.update({"Waist": (-22, 0, 0), "Neck": (34, 0, 0)})
SMASH = reach(SMASH, "Right", (0.3, 0.22, -1.75), elbow_hint=(1.0, 0.3, 0.4), wrist=(-40, 0, 0))
SMASH = reach(SMASH, "Left", (-0.3, 0.22, -1.75), elbow_hint=(-1.0, 0.3, 0.4), wrist=(-40, 0, 0))
SMASH["ease"] = "quad_out"
SHAKE = add(SMASH, {"RootOffset": (0, 0.1, 0), "Neck": (4, 0, 0)})
ROAR = plant_feet({"Root": (8, 0, 0), "RootOffset": (0, -0.3, 0.05), "Waist": (14, 0, 0), "Neck": (28, 0, 0)},
                  feet={"Left": (-0.85, 0.252, 0.0), "Right": (0.85, 0.252, 0.0)}, knee_hint=(0.7, 0, -1))
ROAR.update(aim_arm("Right", out=1.0, up=0.35, back=0.2, elbow=65, twist=-60, wrist=(-20, 0, 0)))
ROAR.update(aim_arm("Left", out=1.0, up=0.35, back=0.2, elbow=65, twist=60, wrist=(-20, 0, 0)))
ROAR["ease"] = "back_out"
ROAR_SHAKE = add(ROAR, {"Waist": (4, 6, 0), "Neck": (4, -6, 0), "RightShoulder": (0, 0, 6), "LeftShoulder": (0, 0, -6)})

SPECIAL = clip("Special", 3.8, {
    0.0: HUNCH,
    0.55: merge(REAR, {"ease": "quad_out"}),
    0.95: REAR_HOLD,
    1.12: SMASH,
    1.4: SHAKE,
    1.75: merge(SMASH, {"ease": "sine_inout"}),
    2.25: ROAR,
    2.55: ROAR_SHAKE,
    2.85: ROAR,
    3.8: HUNCH,
}, loop=False, effects=[
    burst("Both", 1.12, color=(170, 150, 110), count=60, speed=20),
    burst("Both", 1.16, color=(120, 220, 90), count=24, speed=12),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.9, "Move": 0.0, "Special": 0.95}
CAMERAS = {"Move": "side34"}
