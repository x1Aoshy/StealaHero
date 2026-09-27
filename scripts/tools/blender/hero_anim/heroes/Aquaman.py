# Aquaman (Justice League) - HeroMotion style "walk" + aqua Glitter. The model holds a trident welded to the right hand
# (it runs along the hand-local -Z axis, prongs forward when the arm hangs); these clips pose the wrist so it reads.
#   Idle     King of Atlantis: wide planted stance, chest out, left fist on the hip, the trident held upright at his
#            side; slow regal breathing, a weight shift and a look over the shoulder
#   Move     swimming glide: body tipped forward and lifted off the ground as if riding a current, legs together in a
#            dolphin kick, the trident levelled ahead like a spear, the free arm pulling breaststrokes
#   Special  tidal strike: trident raised high (aqua charge, Glitter x3), then a lunging thrust that fires a water
#            blast along the ground (beam + burst) and a proud recovery
from hero_anim.api import *  # noqa: F401,F403
from hero_anim.heroes._avjl import aim_hand, HAND_FRONT

HERO = "Aquaman"
SPECIAL_EVERY = (10, 18)

ORANGE = (226, 142, 36)
GREEN = (38, 118, 70)
SKIN = (234, 184, 146)
HAIR = (30, 24, 20)
GOLD = (236, 196, 72)
WATER = (90, 210, 255)
COLORS = palette(Head=SKIN, UpperTorso=ORANGE, LowerTorso=GREEN, Arms=ORANGE, Hands=GREEN, Legs=GREEN, Feet=GREEN)
_T = (0.064, -0.186, -1.236)  # trident centre, RightHand-local (from the model's weld)
EXTRAS = [
    extra("Head", "box", size=(1.3, 1.5, 0.5), offset=(0, -0.2, 0.36), color=HAIR),
    extra("Head", "box", size=(1.28, 0.3, 1.24), offset=(0, 0.5, 0.04), color=HAIR),
    extra("Head", "box", size=(0.96, 0.5, 0.22), offset=(0, -0.38, -0.52), color=HAIR),
    extra("LowerTorso", "box", size=(2.06, 0.22, 1.06), offset=(0, 0.1, 0), color=GOLD),
    # the trident: shaft along hand-local -Z, crossbar + three prongs at the far end
    extra("RightHand", "box", size=(0.12, 0.12, 6.25), offset=_T, color=GOLD),
    extra("RightHand", "box", size=(0.12, 0.78, 0.14), offset=(_T[0], _T[1], _T[2] - 2.95), color=GOLD),
    extra("RightHand", "cone", size=(0.16, 0.95, 0.16), offset=(_T[0], _T[1], _T[2] - 3.0), rot=(-90, 0, 0), color=GOLD),
    extra("RightHand", "cone", size=(0.14, 0.7, 0.14), offset=(_T[0], _T[1] - 0.34, _T[2] - 3.0), rot=(-90, 0, 0), color=GOLD),
    extra("RightHand", "cone", size=(0.14, 0.7, 0.14), offset=(_T[0], _T[1] + 0.34, _T[2] - 3.0), rot=(-90, 0, 0), color=GOLD),
]

UP = (0.0, 1.0, 0.0)

# ------------------------------------------------------------------------------------------------ Idle
FEET = {"Left": (-0.78, 0.252, -0.08), "Right": (0.78, 0.252, 0.06)}
STANCE = plant_feet({"Root": (0, -6, 0), "RootOffset": (0, -0.1, 0), "Waist": (6, 0, 0), "Neck": (8, 6, 0)},
                    feet=FEET, knee_hint=(0.5, 0, -1))
_LEFT_HIP = {k: v for k, v in fists_on_hips().items() if k.startswith("Left")}
KING = merge(STANCE, _LEFT_HIP)
KING = reach(KING, "Right", (1.6, 2.7, -0.55), elbow_hint=(1.0, -0.4, 0.8))
KING = aim_hand(KING, "Right", HAND_FRONT, (0.08, 1.0, 0.0))
KING_IN = aim_hand(add(KING, {"Waist": (3, 0, 0), "Neck": (-2, 0, 0), "RootOffset": (0, 0.03, 0)}), "Right", HAND_FRONT, (0.08, 1.0, 0.0))
SHIFT = plant_feet(merge(KING, {"Root": (0, -2, 3), "RootOffset": (0.12, -0.14, 0)}), feet=FEET, knee_hint=(0.5, 0, -1))
SHIFT = aim_hand(merge(SHIFT, {"Neck": (6, 34, 0), "Waist": (4, 8, 0)}), "Right", HAND_FRONT, (0.12, 1.0, 0.0))

IDLE = clip("Idle", 4.4, {
    0.0: KING,
    1.3: KING_IN,
    2.3: SHIFT,
    3.2: merge(SHIFT, {"Neck": (6, 20, 0)}),
})

# ------------------------------------------------------------------------------------------------ Move: swim glide


def _glide(kick, stroke, lift):
    p = {"Root": (-60 + kick * 8, 0, 0), "RootOffset": (0, 1.0 + lift, 0), "Waist": (-2 - kick * 6, 0, 0), "Neck": (42, 0, 0)}
    # dolphin kick: both legs together, the knees whip on the down beat
    p.update(aim_leg("Right", down=1.0, forward=0.05 + kick * 0.42, knee=12 + kick * 42, ankle=(-45, 0, 0)))
    p.update(aim_leg("Left", down=1.0, forward=0.02 + kick * 0.42, knee=16 + kick * 42, ankle=(-45, 0, 0)))
    # the trident levelled forward, spear first
    p.update(aim_arm("Right", forward=1.0, up=0.62, out=0.08, elbow=10))
    p = aim_hand(p, "Right", HAND_FRONT, (0.0, 0.08, -1.0))
    # breaststroke with the free arm: reach forward (stroke 0) -> sweep out and back to the hip (stroke 1)
    if stroke < 0.5:
        p.update(aim_arm("Left", forward=1.0, up=0.55, out=0.2, elbow=12))
    else:
        p.update(aim_arm("Left", down=1.0, out=0.55, back=0.35, elbow=22, twist=30))
    return p


REACH = _glide(0.0, 0.0, 0.0)
PULL = _glide(1.0, 1.0, 0.14)
REACH["ease"] = "quad_inout"
PULL["ease"] = "sine_inout"
MOVE = clip("Move", 1.6, {0.0: REACH, 0.7: PULL}, motion=motion(lift=1.0, lean=0.5), speed=7.0, footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: tidal strike
RAISE = plant_feet({"Root": (4, 0, 0), "RootOffset": (0, -0.05, 0), "Waist": (10, 0, 0), "Neck": (18, 0, 0)},
                   feet=FEET, knee_hint=(0.5, 0, -1))
RAISE.update(aim_arm("Right", up=1.0, out=0.28, elbow=8))
RAISE.update(aim_arm("Left", out=1.0, up=0.3, forward=0.2, elbow=30, twist=50))
RAISE = aim_hand(RAISE, "Right", HAND_FRONT, (0.1, 1.0, 0.0))
RAISE["ease"] = "back_out"
TENSE = aim_hand(add(RAISE, {"Waist": (4, 0, 0), "RootOffset": (0, 0.06, 0.04)}), "Right", HAND_FRONT, (0.1, 1.0, 0.0))
TENSE["ease"] = "quint_in"
STRIKE = plant_feet({"Root": (-16, 16, 0), "RootOffset": (0.05, -0.45, -0.45), "Waist": (-8, 8, 0), "Neck": (18, -18, 0)},
                    feet={"Left": (-0.72, 0.252, -1.15), "Right": (0.75, 0.252, 0.5)}, knee_hint=(0.4, 0, -1))
STRIKE.update(aim_arm("Right", forward=1.0, down=0.25, inward=0.1, elbow=6))
STRIKE.update(aim_arm("Left", back=0.7, out=0.8, up=0.1, elbow=24))
STRIKE = aim_hand(STRIKE, "Right", HAND_FRONT, (0.0, -0.45, -1.0))
STRIKE["ease"] = "quart_out"
HOLD = add(STRIKE, {"Waist": (4, 0, 0), "RootOffset": (0, 0.05, 0.06)})

SPECIAL = clip("Special", 3.4, {
    0.0: KING,
    0.55: RAISE,
    1.25: TENSE,
    1.45: STRIKE,
    2.0: HOLD,
    3.4: KING,
}, loop=False, effects=[
    charge("RightHand", 0.5, 1.5, color=WATER, size=1.0),
    web("RightHand", anchor=(1.0, 0.4, -16.0), t0=1.45, t1=2.0, color=WATER, width=0.55),
    burst("RightHand", 1.45, color=(150, 230, 255), count=50, speed=16),
    accent(boost=3.0, t0=0.5, t1=2.2),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.45}
CAMERAS = {"Move": "side"}
