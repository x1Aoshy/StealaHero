# Roronoa Zoro (One Piece, Straw Hat swordsman) - HeroMotion style "walk".
#   Idle     Santoryu (three-sword style) guard: low wide stance, torso over the knees, both fists forward at chest
#            height holding the blades up and out, head down glaring, slow heavy breathing and a grip re-set
#   Move     stalking walk: heavy deliberate strides, torso forward, fists held low and out in front (blades ready),
#            head down - small arm swing, a samurai that is about to cut
#   Special  Oni Giri: sinks and crosses both fists in front of the chest, then lunges forward and rips both arms
#            out and back in the demon slash (burst from both blades), holds the follow-through, hops back to guard
from hero_anim.api import *  # noqa: F401,F403

HERO = "Zoro"
SPECIAL_EVERY = (9, 16)

SHIRT = (242, 242, 242)
HARAMAKI = (60, 142, 76)
PANTS = (32, 32, 36)
SKIN = (236, 190, 150)
GREEN_HAIR = (84, 170, 92)
BLADE = (214, 220, 230)
COLORS = palette(UpperTorso=SHIRT, LowerTorso=HARAMAKI, Arms=SKIN, Hands=SKIN, Legs=PANTS, Feet=(22, 22, 24), Head=SKIN)


def katana(part, handle_color, pos=(0.0, 0.0, 0.0)):
    """Preview katana gripped in a fist: the blade leaves the fist along the hand's -Z (the thumb side)."""
    x, y, z = pos
    return [
        extra(part, "box", size=(0.2, 0.2, 0.8), offset=(x, y, z + 0.05), color=handle_color),
        extra(part, "box", size=(0.48, 0.48, 0.08), offset=(x, y, z - 0.42), color=(200, 170, 70)),
        extra(part, "box", size=(0.08, 0.26, 3.1), offset=(x, y, z - 2.0), color=BLADE, emissive=True),
    ]


EXTRAS = [
    # green buzz-cut hair, three gold earrings, the black bandana tied on the left arm
    extra("Head", "box", size=(1.28, 0.34, 1.28), offset=(0, 0.46, 0.02), color=GREEN_HAIR),
    extra("Head", "box", size=(0.1, 0.3, 0.1), offset=(-0.66, -0.12, 0.0), color=(240, 200, 60)),
    extra("LeftUpperArm", "box", size=(1.06, 0.34, 1.06), offset=(0, 0.18, 0), color=(20, 20, 22)),
    # the third sword (Wado Ichimonji) in the teeth, blade out to his right
    extra("Head", "box", size=(0.7, 0.16, 0.16), offset=(-0.15, -0.22, -0.66), color=(240, 240, 240)),
    extra("Head", "box", size=(0.08, 0.42, 0.42), offset=(0.24, -0.22, -0.66), color=(200, 170, 70)),
    extra("Head", "box", size=(2.8, 0.24, 0.08), offset=(1.7, -0.22, -0.72), rot=(0, 10, 0), color=BLADE, emissive=True),
] + katana("RightHand", (190, 30, 40)) + katana("LeftHand", (24, 24, 28))

FEET = {"Left": (-0.95, 0.252, -0.45), "Right": (1.0, 0.252, 0.45)}


def guard_arms(pose, lift=0.0, spread=0.0):
    """Fists forward at chest height, blades up and out (wrists cocked)."""
    p = reach(pose, "Right", (0.95 + spread, 3.05 + lift, -1.45), elbow_hint=(1.0, -0.6, 0.3), wrist=(-45, -18, 0))
    return reach(p, "Left", (-0.75 - spread, 2.85 + lift, -1.6), elbow_hint=(-1.0, -0.6, 0.3), wrist=(-45, 42, 0))


def stance(drop, extra_pose=None):
    p = merge({"Root": (-10, 8, 0), "RootOffset": (0, -drop, 0), "Waist": (-8, 6, 0), "Neck": (4, -14, 0)}, extra_pose or {})
    return plant_feet(p, feet=FEET, knee_hint=(0.7, 0, -1))


# ------------------------------------------------------------------------------------------------ Idle
GUARD = guard_arms(stance(0.55))
GUARD_IN = guard_arms(stance(0.62, {"Waist": (-5, 6, 0), "Neck": (2, -14, 0)}), lift=0.08)
GUARD_REGRIP = guard_arms(stance(0.5, {"Waist": (-10, 12, 0), "Neck": (8, -20, 0)}), lift=-0.05, spread=0.15)
GUARD_REGRIP["RightWrist"] = (-60, -40, 0)
GUARD_REGRIP["LeftWrist"] = (-60, 40, 0)
GUARD_REGRIP["ease"] = "back_out"

IDLE = clip("Idle", 4.0, {
    0.0: GUARD,
    1.3: GUARD_IN,
    2.3: merge(GUARD, {"ease": "quad_in"}),
    2.55: GUARD_REGRIP,
    3.2: GUARD_IN,
})

# ------------------------------------------------------------------------------------------------ Move: stalking walk
WALK = 1.0
KEYS = walk_cycle(length=WALK, stride=30.0, knee=38.0, arm=10.0, bounce=0.06)
for i, t in enumerate(sorted(KEYS)):
    sw = (0.08 if i in (0, 3) else -0.08)  # a small counter-swing of the held blades
    k = add(KEYS[t], {"Root": (-8, 0, 0), "RootOffset": (0, -0.1, 0)})
    k.update({"Waist": (-6, (-6 if i == 0 else 6 if i == 2 else 0), 0), "Neck": (-2, 0, 0)})
    k.update(aim_arm("Right", forward=0.55 + sw, down=1.0, out=0.3, elbow=38, wrist=(-30, -20, 0)))
    k.update(aim_arm("Left", forward=0.55 - sw, down=1.0, out=0.3, elbow=38, wrist=(-30, 20, 0)))
    KEYS[t] = k
MOVE = clip("Move", WALK, KEYS, speed="auto")

# ------------------------------------------------------------------------------------------------ Special: Oni Giri
def cross(drop, back):
    """Fists crossed in front of the chest (blades swept back over the shoulders), sunk low, ready to lunge."""
    p = plant_feet({"Root": (-16 - 4 * back, 0, 0), "RootOffset": (0, -drop, 0.15 + back * 0.1), "Waist": (-6, 0, 0), "Neck": (8, 0, 0)},
                   feet={"Left": (-0.9, 0.252, -0.35), "Right": (0.9, 0.252, 0.35)}, knee_hint=(0.7, 0, -1))
    p = reach(p, "Right", (-0.15, 3.1 - 0.12 * back, -1.05), elbow_hint=(1, -0.5, 0.2), wrist=(-20, 60, 0))
    return reach(p, "Left", (0.2, 3.35 - 0.12 * back, -1.15), elbow_hint=(-1, -0.5, 0.2), wrist=(-20, -60, 0))


CROSS = cross(0.75, 0.0)
CROSS["ease"] = "quad_out"
CROSS_TENSE = cross(0.85, 1.0)
CROSS_TENSE["ease"] = "quart_in"

SLASH_FEET = {"Left": (-0.9, 0.252, -2.3), "Right": (0.9, 0.252, -0.2)}
SLASH = plant_feet({"Root": (-24, 0, 0), "RootOffset": (0, -0.85, -1.5), "Waist": (-4, 0, 0), "Neck": (18, 0, 0)},
                   feet=SLASH_FEET, knee_hint=(0.6, 0, -1))
SLASH.update(aim_arm("Right", out=1.0, back=0.75, down=0.1, elbow=5, twist=-30, wrist=(0, 0, 0)))
SLASH.update(aim_arm("Left", out=1.0, back=0.75, down=0.1, elbow=5, twist=30, wrist=(0, 0, 0)))
SLASH["ease"] = "quart_out"
FOLLOW = add(SLASH, {"RootOffset": (0, -0.05, -0.1), "Waist": (-3, 0, 0), "RightShoulder": (-6, 0, 0), "LeftShoulder": (-6, 0, 0)})
FOLLOW["ease"] = "quad_in"
HOP = merge(guard_arms(stance(0.1, {"RootOffset": (0, 0.35, -0.6)})), aim_leg("Right", down=1.0, forward=0.3, knee=50),
            aim_leg("Left", down=1.0, forward=0.4, knee=60))
HOP["ease"] = "quad_in"

SPECIAL = clip("Special", 3.3, {
    0.0: GUARD,
    0.35: CROSS,
    0.9: CROSS_TENSE,
    1.02: SLASH,
    1.75: FOLLOW,
    2.35: HOP,
    2.65: merge(guard_arms(stance(0.72)), {"ease": "quad_out"}),
    3.3: GUARD,
}, loop=False, effects=[
    burst("Both", 1.04, color=(210, 255, 220), count=40, speed=20),
    burst("Both", 1.08, color=(255, 255, 255), count=20, speed=8),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.02}
CAMERAS = {"Move": "side34", "Special": "front34"}
