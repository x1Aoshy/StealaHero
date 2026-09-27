# Captain America (Avengers) - HeroMotion style "walk".
#   Idle     shield-raised ready stance: left foot forward, shield forearm up across the chest, right fist cocked at
#            the hip, eyes over the rim of the shield; breathing, a small shield adjust and a look round
#   Move     soldier's march: long determined strides, the shield arm held up in front, the right arm pumping
#   Special  shield throw: backhand wind-up across the body, a whipping release (lunge + burst), watch it ricochet,
#            catch it on the rebound (recoil + burst) and settle back behind the shield
# The in-game model carries no shield prop (see the ANIM_AVJL notes); the preview shows one strapped to the left
# forearm where the clips expect it.
from hero_anim.api import *  # noqa: F401,F403
from hero_anim.heroes._avjl import prop_frame

HERO = "CaptainAmerica"
SPECIAL_EVERY = (10, 18)

NAVY = (34, 58, 150)
RED = (190, 32, 40)
WHITE = (240, 240, 245)
SKIN = (246, 204, 164)
BROWN = (120, 60, 30)
COLORS = palette(Head=NAVY, UpperTorso=NAVY, LowerTorso=RED, Arms=NAVY, Hands=BROWN, Legs=(30, 48, 120), Feet=BROWN)

# ------------------------------------------------------------------------------------------------ Idle
FEET = {"Left": (-0.62, 0.252, -0.42), "Right": (0.66, 0.252, 0.38)}
STANCE = plant_feet({"Root": (-4, -8, 0), "RootOffset": (0.0, -0.16, 0.0), "Waist": (2, -4, 0), "Neck": (6, 12, 0)},
                    feet=FEET, knee_hint=(0.3, 0, -1))
# shield forearm across the chest (the elbow down / out, fist in front of the right pec), right fist at the hip
GUARD = reach(STANCE, "Left", (0.35, 3.3, -1.1), elbow_hint=(-1.0, -0.9, -0.2), wrist=(0, 0, -10))
GUARD = reach(GUARD, "Right", (1.05, 2.55, 0.25), elbow_hint=(1.0, 0.2, 1.0), wrist=(0, 0, 8))
GUARD_IN = add(GUARD, {"Waist": (3, 0, 0), "Neck": (-2, 0, 0), "RootOffset": (0, 0.03, 0)})
GUARD_UP = add(GUARD, {"LeftShoulder": (8, 0, 0), "LeftElbow": (6, 0, 0), "Neck": (-4, -6, 0)})
LOOK = add(GUARD, {"Neck": (2, 14, 0), "Waist": (0, 4, 0)})

IDLE = clip("Idle", 3.8, {
    0.0: GUARD,
    1.1: GUARD_IN,
    1.9: merge(GUARD_UP, {"ease": "quad_out"}),
    2.6: LOOK,
    3.2: GUARD_IN,
})

# ------------------------------------------------------------------------------------------------ preview shield
# a round shield strapped to the left forearm, facing forward in the guard pose (red / white / red rings, blue star disc)
_SHIELD_AT = (-0.15, 3.12, -1.62)
_OFF, _ROT = prop_frame(GUARD, "LeftLowerArm", _SHIELD_AT, (0.12, 0.08, -1.0))
_N = [v for v in _OFF]


def _layer(size, depth, color):
    # rings stacked toward the viewer along the prop's local Z (they share the offset / rot; deeper = further out)
    return extra("LeftLowerArm", "sphere", size=(size, size, depth), offset=tuple(_N), rot=_ROT, color=color)


EXTRAS = [
    _layer(2.1, 0.3, RED), _layer(1.64, 0.38, WHITE), _layer(1.2, 0.46, RED), _layer(0.76, 0.54, NAVY),
    extra("LeftLowerArm", "sphere", size=(0.34, 0.34, 0.6), offset=tuple(_N), rot=_ROT, color=WHITE),
    # the "A" on the cowl and the chest star
    extra("Head", "box", size=(0.22, 0.3, 0.08), offset=(0, 0.3, -0.6), color=WHITE),
    extra("UpperTorso", "box", size=(0.42, 0.42, 0.08), offset=(0, 0.2, -0.52), rot=(0, 0, 45), color=WHITE),
    extra("LowerTorso", "box", size=(2.04, 0.1, 1.04), offset=(0, 0.06, 0), color=WHITE),
    extra("Head", "box", size=(0.9, 0.42, 0.1), offset=(0, -0.28, -0.56), color=SKIN),
]

# ------------------------------------------------------------------------------------------------ Move: march
SHIELD_CARRY = reach({"Root": (-6, 0, 0)}, "Left", (0.1, 3.2, -1.15), elbow_hint=(-1.0, -0.9, -0.2), wrist=(0, 0, -10))
SHIELD_CARRY = {k: v for k, v in SHIELD_CARRY.items() if k.startswith("Left") and ("Shoulder" in k or "Elbow" in k or "Wrist" in k)}
MARCH = walk_cycle(length=0.9, stride=34.0, knee=40.0, arm=32.0, bounce=0.1)
for _t, _p in MARCH.items():
    _p.update(SHIELD_CARRY)
    _p["Neck"] = (3, 0, 0)
    _p["Root"] = add({"Root": _p.get("Root", (0, 0, 0))}, {"Root": (-4, 0, 0)})["Root"]
    if "RightElbow" in _p:
        _p["RightElbow"] = (max(_p["RightElbow"][0], 40.0), 0, 0)
MOVE = clip("Move", 0.9, MARCH, speed="auto")

# ------------------------------------------------------------------------------------------------ Special: shield throw
WIND_FEET = {"Left": (-0.7, 0.252, -0.5), "Right": (0.7, 0.252, 0.45)}
WINDUP = plant_feet({"Root": (-10, -30, 0), "RootOffset": (0.12, -0.3, 0.12), "Waist": (4, -24, 0), "Neck": (4, 48, 0)},
                    feet=WIND_FEET, knee_hint=(0.3, 0, -1))
WINDUP = reach(WINDUP, "Left", (1.15, 3.35, 0.35), elbow_hint=(0.0, -1.0, -0.6), wrist=(0, 0, -20))
WINDUP = merge(WINDUP, aim_arm("Right", down=1.0, out=0.5, back=0.3, elbow=30))
WINDUP_HOLD = add(WINDUP, {"Waist": (0, -6, 0), "RootOffset": (0, -0.04, 0.04)})
WINDUP_HOLD["ease"] = "quint_in"
THROW = plant_feet({"Root": (-14, 30, 0), "RootOffset": (-0.1, -0.36, -0.35), "Waist": (-6, 24, 0), "Neck": (6, -42, 0)},
                   feet={"Left": (-0.7, 0.252, -0.95), "Right": (0.7, 0.252, 0.45)}, knee_hint=(0.3, 0, -1))
THROW = merge(THROW, aim_arm("Left", forward=0.8, out=1.0, up=0.08, twist=10, wrist=(0, 0, -20)),
              aim_arm("Right", back=0.8, out=0.5, down=0.6, elbow=40))
THROW["ease"] = "quart_out"
FOLLOW = add(THROW, {"Waist": (0, 10, 0), "LeftShoulder": (-6, 0, -8), "Neck": (0, -10, 0)})
WATCH_L = merge(STANCE, fists_on_hips(), {"Neck": (8, 40, 0), "Waist": (2, 8, 0)})
WATCH_R = merge(STANCE, fists_on_hips(), {"Neck": (8, -8, 0), "Waist": (2, -6, 0), "ease": "quad_in"})
CATCH = plant_feet({"Root": (6, -8, 0), "RootOffset": (0.0, -0.2, 0.3), "Waist": (6, -4, 0), "Neck": (6, 16, 0)},
                   feet=FEET, knee_hint=(0.3, 0, -1))
CATCH = merge(CATCH, aim_arm("Left", forward=1.0, up=0.25, out=0.1, elbow=25, wrist=(-20, 0, 0)),
              aim_arm("Right", down=1.0, out=0.45, back=0.2, elbow=30))
CATCH["ease"] = "quad_out"
ABSORB = add(GUARD, {"Root": (5, 0, 0), "RootOffset": (0, -0.08, 0.15)})

SPECIAL = clip("Special", 3.6, {
    0.0: GUARD,
    0.5: WINDUP,
    0.72: WINDUP_HOLD,
    0.9: THROW,
    1.2: FOLLOW,
    1.6: WATCH_L,
    2.15: WATCH_R,
    2.4: CATCH,
    2.75: ABSORB,
    3.6: GUARD,
}, loop=False, effects=[
    burst("LeftHand", 0.9, color=(235, 240, 255), count=34, speed=16),
    # the thrown shield's streak flying off ahead, then the ricochet coming back into the catch
    web("LeftHand", anchor=(-2.0, 3.6, -22.0), t0=0.9, t1=1.12, color=(236, 240, 255), width=0.45),
    web("LeftHand", anchor=(-7.0, 4.2, -16.0), t0=2.18, t1=2.4, color=(230, 60, 64), width=0.4),
    burst("LeftHand", 2.4, color=(255, 90, 90), count=24, speed=10),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.2}  # must be one of the sheet times
CAMERAS = {"Special": "front"}
