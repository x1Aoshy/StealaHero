# Venom (Spider-Verse, Mythic) - HeroMotion style "stomp" (dark dust on every footfall).
#   Idle     hulking predator: hunched deep, shoulders rolled forward, long arms hanging low and wide with the claws curled,
#            knees bent wide; heavy heaving breaths, the head swaying and cocking like a hunter sizing up its prey
#   Move     predator stomp: huge hunched strides, arms swinging wide and low (claws dragging), head thrust forward,
#            every footfall slammed down (HeroMotion stomp dip kept at half since the cycle drops itself)
#   Special  "WE ARE VENOM" roar: sinks and gathers, then rears up to full height, claws spread wide, head thrown
#            forward in a shaking roar (symbiote tendrils burst off both claws), then a lunge-snap and back to the hunch
from hero_anim.api import *  # noqa: F401,F403

HERO = "Venom"
SPECIAL_EVERY = (10, 18)

BLACK = (16, 16, 22)
SHEEN = (30, 34, 52)
WHITE = (240, 240, 244)
COLORS = palette(Head=BLACK, Torso=SHEEN, Arms=SHEEN, Hands=BLACK, Legs=SHEEN, Feet=BLACK)
EXTRAS = [
    # huge angular white eyes
    extra("Head", "box", size=(0.5, 0.36, 0.08), offset=(-0.27, 0.2, -0.6), rot=(0, 0, -32), color=WHITE),
    extra("Head", "box", size=(0.5, 0.36, 0.08), offset=(0.27, 0.2, -0.6), rot=(0, 0, 32), color=WHITE),
    # the grin: white fangs over a red tongue
    extra("Head", "box", size=(0.95, 0.28, 0.06), offset=(0, -0.22, -0.6), color=(120, 10, 20)),
    extra("Head", "spikes", size=(0.9, 0.2, 0.12), offset=(0, -0.1, -0.64), rot=(180, 0, 0), color=WHITE),
    extra("Head", "spikes", size=(0.9, 0.18, 0.12), offset=(0, -0.34, -0.64), color=WHITE),
    extra("Head", "cone", size=(0.22, 0.7, 0.14), offset=(0.1, -0.3, -0.7), rot=(160, 0, 12), color=(205, 40, 70)),
    # the big white spider, wrapping over the shoulders to the back
    extra("UpperTorso", "box", size=(0.5, 1.0, 0.08), offset=(0, 0.0, -0.52), color=WHITE),
    extra("UpperTorso", "box", size=(2.0, 0.2, 0.08), offset=(0, 0.35, -0.52), rot=(0, 0, 26), color=WHITE),
    extra("UpperTorso", "box", size=(2.0, 0.2, 0.08), offset=(0, 0.35, -0.52), rot=(0, 0, -26), color=WHITE),
    extra("UpperTorso", "box", size=(1.6, 0.2, 0.08), offset=(0, -0.25, -0.52), rot=(0, 0, -20), color=WHITE),
    extra("UpperTorso", "box", size=(1.6, 0.2, 0.08), offset=(0, -0.25, -0.52), rot=(0, 0, 20), color=WHITE),
    # claws
    extra("RightHand", "spikes", size=(0.8, 0.5, 0.6), offset=(0, -0.15, 0), rot=(180, 0, 0), color=(200, 200, 210)),
    extra("LeftHand", "spikes", size=(0.8, 0.5, 0.6), offset=(0, -0.15, 0), rot=(180, 0, 0), color=(200, 200, 210)),
]

# ------------------------------------------------------------------------------------------------ Idle: hulking predator
FEET = {"Left": (-1.0, 0.252, -0.05), "Right": (1.0, 0.252, 0.1)}


def hunch(heave=0.0, look=0.0, cock=0.0, sink=0.0):
    """Deep hunch; heave 0..1 = breath (chest and shoulders up), look/cock = head yaw/roll degrees."""
    base = {"Root": (-24, look * 0.12, 0), "RootOffset": (0.0, -0.55 - sink + heave * 0.04, 0.0),
            "Waist": (-20 + heave * 7, look * 0.2, 0), "Neck": (38 - heave * 4, look, cock)}
    p = plant_feet(base, feet=FEET, knee_hint=(1.0, 0.0, -1.0), foot_yaw={"Left": -12, "Right": 12})
    # long heavy arms hanging low and wide in front of the knees, claws curled, shoulders rolled forward
    p.update(aim_arm("Right", down=1.0, out=0.55, forward=0.55, elbow=28 - heave * 6, twist=-25, wrist=(-35, 0, 0)))
    p.update(aim_arm("Left", down=1.0, out=0.55, forward=0.55, elbow=28 - heave * 6, twist=25, wrist=(-35, 0, 0)))
    p = add(p, {"RightShoulder": (0, 0, heave * 4), "LeftShoulder": (0, 0, -heave * 4)})
    return p


REST = hunch()
HEAVE = merge(hunch(heave=1.0), {"ease": "quad_out"})
SIZE_UP = merge(hunch(look=26, cock=18, sink=0.03), {"ease": "sine_inout"})
SIZE_UP_R = merge(hunch(look=-20, cock=-14, heave=0.6), {"ease": "sine_inout"})

IDLE = clip("Idle", 4.8, {
    0.0: REST,
    0.9: HEAVE,
    1.8: SIZE_UP,
    2.7: merge(hunch(heave=0.8, look=20, cock=16), {"ease": "sine_inout"}),
    3.5: SIZE_UP_R,
    4.2: HEAVE,
})

# ------------------------------------------------------------------------------------------------ Move: predator stomp
STOMP_LEN = 1.3
STOMP = stomp_cycle(length=STOMP_LEN, stride=30, knee=46, arm=26, drop=0.3)
for _t, _p in STOMP.items():
    # hunched predator on top of the heavy cycle: torso folded forward, head thrust out, arms swung wide and low
    _p = add(_p, {"Root": (-12, 0, 0), "Waist": (-16, 0, 0), "Neck": (34, 0, 0),
                  "RightShoulder": (0, -20, 22), "LeftShoulder": (0, 20, -22), "RightElbow": (10, 0, 0), "LeftElbow": (10, 0, 0)})
    _p["RightWrist"] = (-35, 0, 0)
    _p["LeftWrist"] = (-35, 0, 0)
    _p["RootOffset"] = (0, _p["RootOffset"][1] + 0.2, 0)
    STOMP[_t] = _p
MOVE = clip("Move", STOMP_LEN, STOMP, motion=motion(lift=0.5), speed="auto")

# ------------------------------------------------------------------------------------------------ Special: the roar
GATHER = plant_feet({"Root": (-30, 0, 0), "RootOffset": (0.0, -0.95, 0.1), "Waist": (-24, 0, 0), "Neck": (8, 0, 0)},
                    feet=FEET, knee_hint=(1.0, 0.0, -1.0), foot_yaw={"Left": -12, "Right": 12})
GATHER.update(aim_arm("Right", down=1.0, forward=0.8, inward=0.3, elbow=70, twist=-20, wrist=(-40, 0, 0)))
GATHER.update(aim_arm("Left", down=1.0, forward=0.8, inward=0.3, elbow=70, twist=20, wrist=(-40, 0, 0)))
GATHER["ease"] = "quad_out"
GATHER_T = add(GATHER, {"Waist": (-4, 0, 0), "RootOffset": (0, -0.05, 0)})
GATHER_T["ease"] = "quart_in"


def roar(shake=0.0):
    """Reared up to full height, chest out, claws spread wide and high, head thrust forward roaring; shake = +-1."""
    p = plant_feet({"Root": (6, 0, shake * 2), "RootOffset": (0.0, -0.2, 0.15), "Waist": (16, shake * 5, shake * 2),
                    "Neck": (-8, shake * 10, -shake * 6)},
                   feet={"Left": (-1.25, 0.252, 0.0), "Right": (1.25, 0.252, 0.1)}, knee_hint=(1.0, 0.0, -1.0),
                   foot_yaw={"Left": -18, "Right": 18})
    p.update(aim_arm("Right", out=1.0, up=0.7 + shake * 0.08, back=0.2, elbow=35, twist=-50, wrist=(50, 0, 0)))
    p.update(aim_arm("Left", out=1.0, up=0.7 - shake * 0.08, back=0.2, elbow=35, twist=50, wrist=(50, 0, 0)))
    return p


ROAR = merge(roar(), {"ease": "back_out"})
LUNGE = plant_feet({"Root": (-34, 0, 0), "RootOffset": (0.0, -0.75, -0.55), "Waist": (-12, 0, 0), "Neck": (48, 0, 0)},
                   feet={"Left": (-1.0, 0.252, -0.45), "Right": (1.0, 0.252, 0.6)}, knee_hint=(1.0, 0.0, -1.0),
                   foot_yaw={"Left": -12, "Right": 12})
LUNGE.update(aim_arm("Right", forward=1.0, down=0.25, out=0.45, elbow=30, wrist=(-45, 0, 0)))
LUNGE.update(aim_arm("Left", forward=1.0, down=0.1, out=0.5, elbow=30, wrist=(-45, 0, 0)))
LUNGE["ease"] = "quart_out"

SPECIAL = clip("Special", 3.8, {
    0.0: REST,
    0.45: GATHER,
    0.95: GATHER_T,
    1.15: ROAR,
    1.35: roar(1.0),
    1.5: roar(-1.0),
    1.65: roar(1.0),
    1.8: roar(-1.0),
    1.95: roar(0.6),
    2.15: roar(0.0),
    2.55: LUNGE,
    2.85: add(LUNGE, {"Neck": (-6, 0, 0), "RootOffset": (0, 0.05, 0.1)}),
    3.8: REST,
}, loop=False, effects=[
    burst("Both", 1.15, color=(14, 14, 20), count=60, speed=20),
    burst("Both", 1.2, color=(230, 230, 240), count=16, speed=12),
    charge("Both", 1.15, 2.2, color=(40, 40, 60), size=1.2, light=False),
    burst("Both", 2.55, color=(14, 14, 20), count=30, speed=16),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.35}
