# Vinsmoke Sanji (One Piece, Straw Hat cook) - HeroMotion style "dash" + orange Sparks.
#   Idle     too cool: hands in his pockets, weight on one leg, head tilted; he takes a drag and exhales up at the
#            sky, then taps his shoe - Sanji never takes his hands out of his pockets (the hands are for cooking)
#   Move     kick-dash: a long-legged sprint with the hands still in the pockets, torso leaning into it, legs
#            flicking out almost straight like kicks (the HeroMotion dash bursts on top)
#   Special  Diable Jambe: pivots on his left foot and spins twice, right leg chambered, the friction setting his
#            leg on fire (flames at the right hip), stops and snaps a head-high flaming side kick, then back to cool
from hero_anim.api import *  # noqa: F401,F403

HERO = "Sanji"
SPECIAL_EVERY = (8, 15)

SUIT = (28, 28, 34)
SHIRT = (62, 92, 172)
SKIN = (240, 200, 160)
BLOND = (242, 212, 92)
COLORS = palette(Torso=SUIT, Arms=SUIT, Hands=SKIN, Legs=SUIT, Feet=(40, 30, 26), Head=SKIN)
EXTRAS = [
    # blond hair with the long fringe over one eye
    extra("Head", "box", size=(1.3, 0.36, 1.3), offset=(0, 0.46, 0.04), color=BLOND),
    extra("Head", "box", size=(0.62, 0.62, 0.12), offset=(0.3, 0.2, -0.62), rot=(0, 0, -8), color=BLOND),
    extra("Head", "box", size=(1.3, 0.9, 0.3), offset=(0, 0.1, 0.52), color=BLOND),
    # the curly eyebrow + cigarette (glowing tip)
    extra("Head", "box", size=(0.3, 0.06, 0.05), offset=(-0.22, 0.28, -0.62), rot=(0, 0, 12), color=(40, 30, 10)),
    extra("Head", "box", size=(0.07, 0.07, 0.4), offset=(0.18, -0.22, -0.76), rot=(-10, -20, 0), color=(245, 245, 240)),
    extra("Head", "box", size=(0.08, 0.08, 0.08), offset=(0.25, -0.26, -0.95), color=(255, 120, 40), emissive=True),
    # blue shirt + black tie inside the open jacket
    extra("UpperTorso", "box", size=(0.7, 1.5, 0.06), offset=(0, 0.02, -0.5), color=SHIRT),
    extra("UpperTorso", "box", size=(0.18, 1.1, 0.07), offset=(0, 0.15, -0.53), color=(12, 12, 14)),
]

REST_FEET = {"Left": (-0.55, 0.252, 0.12), "Right": (0.62, 0.252, -0.32)}


def pockets(pose):
    """Both hands deep in the trouser pockets, elbows bent a little out and back. Solved in the hips' frame (only the
    Waist of `pose` matters), so the hands stay in the pockets however the body leans, tilts or spins."""
    local = {"Waist": pose["Waist"]} if "Waist" in pose else {}
    p = reach(local, "Right", (1.02, 2.28, 0.02), elbow_hint=(1.0, 0.0, 0.8), wrist=(10, 0, -8))
    p = reach(p, "Left", (-1.02, 2.28, 0.02), elbow_hint=(-1.0, 0.0, 0.8), wrist=(10, 0, 8))
    return merge(pose, {k: v for k, v in p.items() if k != "Waist"})


def cool(neck=(-4, -12, 7), waist=(-3, 10, 0), shift=0.0, drop=0.08):
    """Weight on the left leg (hip cocked left), right foot forward and relaxed."""
    p = {"Root": (0, 4, 4 + 2 * shift), "RootOffset": (-0.14 - 0.05 * shift, -drop, 0), "Waist": waist, "Neck": neck}
    p = plant_feet(p, feet=REST_FEET, knee_hint=(0.3, 0, -1))
    return pockets(p)


# ------------------------------------------------------------------------------------------------ Idle
COOL = cool()
COOL_IN = cool(neck=(-6, -10, 6), waist=(-1, 10, 0), shift=1.0, drop=0.1)
EXHALE = cool(neck=(22, -4, 4), waist=(4, 6, 0), drop=0.05)
EXHALE["ease"] = "quad_out"
TAP = add(COOL, {"RightAnkle": (22, 0, 0), "RightKnee": (-4, 0, 0)})
TAP["ease"] = "quad_out"

IDLE = clip("Idle", 4.6, {
    0.0: COOL,
    1.0: COOL_IN,
    1.6: EXHALE,
    2.4: merge(EXHALE, {"Neck": (18, 8, 2)}),
    3.0: COOL,
    3.35: TAP, 3.55: COOL, 3.75: TAP, 3.95: COOL,
})

# ------------------------------------------------------------------------------------------------ Move: hands-in-pockets kick-dash
RUN_LEN = 0.52
KEYS = run_cycle(length=RUN_LEN, stride=66.0, knee=70.0, arm=0.0, bounce=0.3, lean=20.0)
for i, t in enumerate(sorted(KEYS)):
    k = KEYS[t]
    for side in ("Left", "Right"):
        for j in ("Shoulder", "Elbow"):
            k.pop(side + j, None)
    if i in (0, 2):  # contact: the front leg lands almost straight, like the end of a kick
        fwd = "Right" if i == 0 else "Left"
        k[fwd + "Knee"] = (-6, 0, 0)
        k[fwd + "Ankle"] = (20, 0, 0)
        k = add(k, {"RootOffset": (0, -0.5, 0)})
    k = merge(k, {"Neck": (16, 0, 0), "Waist": (-4, 0, 0)})
    KEYS[t] = pockets(k)
MOVE = clip("Move", RUN_LEN, KEYS, speed="auto", motion=motion(lift=1.0, lean=0.8))

# ------------------------------------------------------------------------------------------------ Special: Diable Jambe
PIVOT = {"Left": (0.0, 0.252, 0.0), "Right": (0.6, 0.252, 0.0)}


def spin_pose(yaw, lean=0.0):
    """On the left foot (under the hips, so the spin pivots in place), right leg chambered out to the side. Posed
    facing forward, then the whole body is turned by `yaw` about the vertical axis through the hips (the support foot
    turns on its ball, the hands stay in the pockets)."""
    p = {"Root": (lean, 0, 0), "RootOffset": (0.0, -0.22, 0), "Waist": (-4, 0, 0), "Neck": (10, 0, 0)}
    p = plant_feet(p, feet=PIVOT, knee_hint=(0.2, 0, -1))
    p.update(aim_leg("Right", out=0.9, down=0.35, back=0.3, knee=85, ankle=(-40, 0, 0)))
    p["Root"] = (lean, yaw, 0)
    return pockets(p)


CHAMBER = cool(neck=(6, 0, 0), waist=(-2, 0, 0), drop=0.25)
CHAMBER.update(aim_leg("Right", forward=0.9, down=0.5, knee=110, ankle=(-40, 0, 0)))
CHAMBER["ease"] = "quad_out"

keys = {0.0: COOL, 0.3: CHAMBER}
t = 0.5
for i in range(9):  # two full turns in 90-degree keys (linear = constant spin speed)
    k = spin_pose(-90.0 * i)
    k["ease"] = "quad_in" if i == 0 else "linear"
    keys[round(t, 3)] = k
    t += 0.14 if i < 2 else 0.11
SPIN_END = round(t - 0.11, 3)
keys[SPIN_END]["ease"] = "quad_out"
WIND = plant_feet({"Root": (-10, 20, 0), "RootOffset": (-0.1, -0.3, 0.1), "Waist": (-8, -10, 0), "Neck": (6, -14, 0)},
                  feet={"Left": (-0.3, 0.252, 0.2), "Right": (0.6, 0.252, 0.0)}, knee_hint=(0.3, 0, -1))
WIND.update(aim_leg("Right", forward=0.6, down=0.2, out=0.2, knee=125, ankle=(-40, 0, 0)))
WIND = pockets(WIND)
WIND["ease"] = "quart_in"
# high side kick: body tilted away over the left foot, the flaming right leg shot out sideways above head height
KICK = plant_feet({"Root": (4, 10, 30), "RootOffset": (-0.35, -0.32, 0.0), "Waist": (0, -4, 4), "Neck": (6, -18, -18)},
                  feet={"Left": (-0.55, 0.252, 0.1), "Right": (0.6, 0.252, 0.0)}, knee_hint=(0.3, 0, -1))
KICK.update(aim_leg("Right", out=1.0, up=0.45, forward=0.2, down=0.0, knee=0, ankle=(-40, 0, 0)))
KICK = pockets(KICK)
KICK["ease"] = "quad_out"
HOLD = add(KICK, {"Root": (0, 0, 3), "RightHip": (0, 0, 6)})
HOLD["ease"] = "quad_inout"
keys[round(SPIN_END + 0.25, 3)] = WIND
keys[round(SPIN_END + 0.37, 3)] = KICK
keys[round(SPIN_END + 0.85, 3)] = HOLD
keys[round(SPIN_END + 1.45, 3)] = merge(COOL_IN, {"ease": "sine_inout"})
SPECIAL_LEN = round(SPIN_END + 1.9, 3)
keys[SPECIAL_LEN] = COOL

SPECIAL = clip("Special", SPECIAL_LEN, keys, loop=False, effects=[
    charge("RightHand", 0.55, SPIN_END + 1.2, color=(255, 110, 30), size=1.1),
    charge("RightHand", SPIN_END + 0.2, SPIN_END + 1.0, color=(255, 200, 80), size=1.6),
    burst("RightHand", SPIN_END + 0.38, color=(255, 140, 40), count=40, speed=18),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 1.6, "Move": 0.0, "Special": round(SPIN_END + 0.37, 3)}
CAMERAS = {"Move": "side34", "Special": "front34"}
