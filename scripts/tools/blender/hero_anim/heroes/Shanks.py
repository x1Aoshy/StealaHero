# "Red-Haired" Shanks (One Piece, Emperor of the Sea) - HeroMotion style "walk" (red Aura accent).
#   Idle     the Emperor at ease: relaxed contrapposto under the black cape, right hand resting on the hilt of Gryphon at
#            his left hip (shoulder turned in), the empty left side still under the cape, slow deep breathing, chin up,
#            an unhurried glance around and a small easy tilt of the head
#   Move     a calm, confident stroll: measured strides, chest open, hand never leaving the hilt, the left side barely
#            swinging under the cape, head level - nobody hurries an Emperor
#   Special  Conqueror's Haki + Kamusari (Divine Departure): he goes still, the head drops, then snaps up in a glare and
#            the Haki explodes off him (red aura blast, crackling sword hand); he draws high over the left shoulder
#            and cuts one huge diagonal slash down and across (red/white burst), holds the follow-through, then calmly
#            sheathes and is back at ease
from hero_anim import rbx
from hero_anim.api import *  # noqa: F401,F403

HERO = "Shanks"
SPECIAL_EVERY = (10, 18)

SHIRT = (238, 236, 226)
SKIN = (236, 196, 156)
CAPE = (22, 22, 26)
SASH = (132, 36, 36)
PANTS = (170, 138, 94)
HAIR = (196, 28, 32)
BLADE = (222, 226, 234)
COLORS = palette(UpperTorso=SHIRT, LowerTorso=SASH, Arms=SHIRT, Hands=SKIN, Legs=PANTS, Feet=(104, 70, 42), Head=SKIN,
                 # the lost left arm: in the previews that side stays hidden under the cape
                 LeftUpperArm=CAPE, LeftLowerArm=CAPE, LeftHand=CAPE)

ARM_JOINTS = ("RightShoulder", "RightElbow", "RightWrist")
FEET = {"Left": (-0.72, 0.252, -0.38), "Right": (0.52, 0.252, 0.18)}
HILT = (-0.24, 2.56, -0.94)            # right fist on the hilt (rig space, for the at-ease base pose)
SHEATH_DIR = (-0.62, -0.28, 0.73)      # the saber runs from the hilt back / down / out along the left hip


def at_ease(extra_pose=None):
    """Base stance: hips turned a little right, chest turned in to the left so the right hand rests on the hilt."""
    p = merge({"Root": (0, -12, 1.5), "RootOffset": (0.08, -0.06, 0), "Waist": (2, 24, -2), "Neck": (6, -12, 3)},
              extra_pose or {})
    p = plant_feet(p, feet=FEET, knee_hint=(0.2, 0, -1))
    p.update(aim_arm("Left", down=1.0, back=0.1, inward=0.03, elbow=6))
    return p


def _hilt_grip():
    """Right arm on the hilt, the wrist turned so the fist's -Z (the drawn blade) lies along the scabbard."""
    base = reach(at_ease(), "Right", HILT, elbow_hint=(1.0, -0.2, 0.35))
    parts, _ = rig().fk(transforms_of(base))
    local = rbx.m_vec(rbx.m_transpose(parts["RightHand"][0]), rbx.v_norm(SHEATH_DIR))
    wrist = rbx.to_euler_xyz(rbx.rotation_between((0.0, 0.0, -1.0), local))
    base["RightWrist"] = tuple(round(v, 3) for v in wrist)
    return {k: base[k] for k in ARM_JOINTS}


GRIP = _hilt_grip()


def on_hilt(pose):
    return merge(pose, GRIP)


def _saber(part):
    """Gryphon, gripped in the fist: the blade leaves along the hand's -Z (like the Zoro katanas)."""
    return [
        extra(part, "box", size=(0.2, 0.2, 0.9), offset=(0, 0, 0.1), color=(40, 30, 26)),
        extra(part, "box", size=(0.5, 0.14, 0.34), offset=(0, 0, -0.42), color=(214, 176, 72)),
        extra(part, "box", size=(0.08, 0.3, 3.0), offset=(0, 0, -1.98), color=BLADE, emissive=True),
    ]


def _scabbard():
    """The scabbard on the LowerTorso, exactly around the blade of the at-ease pose (so the blade reads sheathed)."""
    pose = on_hilt(at_ease())
    parts, _ = rig().fk(transforms_of(pose))
    hand, hips = parts["RightHand"], parts["LowerTorso"]
    world = rbx.cf_mul(hand, rbx.cf((0.0, 0.0, -2.08)))
    local = rbx.cf_mul(rbx.cf_inv(hips), world)
    off = tuple(round(v, 3) for v in local[1])
    rot = tuple(round(v, 2) for v in rbx.to_euler_xyz(local[0]))
    return [extra("LowerTorso", "box", size=(0.26, 0.46, 3.4), offset=off, rot=rot, color=(26, 20, 20))]


EXTRAS = [
    # swept-back red hair with the long side locks and the three scars over the left eye
    extra("Head", "sphere", size=(1.46, 0.62, 1.46), offset=(0, 0.42, 0.06), color=HAIR),
    extra("Head", "cone", size=(0.34, 0.55, 0.34), offset=(0, 0.5, 0.66), rot=(-70, 0, 0), color=HAIR),
    extra("Head", "box", size=(1.3, 0.8, 0.34), offset=(0, 0.02, 0.52), color=HAIR),
    extra("Head", "box", size=(0.2, 0.62, 0.95), offset=(-0.64, 0.1, 0.14), color=HAIR),
    extra("Head", "box", size=(0.2, 0.62, 0.95), offset=(0.64, 0.1, 0.14), color=HAIR),
    extra("Head", "cone", size=(0.34, 0.34, 0.18), offset=(-0.34, 0.36, -0.58), rot=(180, 0, 12), color=HAIR),
    extra("Head", "cone", size=(0.34, 0.3, 0.18), offset=(0.3, 0.38, -0.58), rot=(180, 0, -10), color=HAIR),
    extra("Head", "box", size=(0.05, 0.46, 0.04), offset=(-0.17, 0.02, -0.61), rot=(0, 0, -14), color=(150, 40, 40)),
    extra("Head", "box", size=(0.05, 0.46, 0.04), offset=(-0.26, 0.02, -0.61), rot=(0, 0, -14), color=(150, 40, 40)),
    extra("Head", "box", size=(0.05, 0.46, 0.04), offset=(-0.35, 0.02, -0.61), rot=(0, 0, -14), color=(150, 40, 40)),
    # the black Emperor's cape over both shoulders, open shirt
    extra("UpperTorso", "box", size=(2.7, 2.75, 0.14), offset=(0, -0.55, 0.64), rot=(-4, 0, 0), color=CAPE),
    extra("UpperTorso", "box", size=(1.0, 0.24, 1.3), offset=(-0.95, 0.9, 0.06), rot=(0, 0, 10), color=CAPE),
    extra("UpperTorso", "box", size=(1.0, 0.24, 1.3), offset=(0.95, 0.9, 0.06), rot=(0, 0, -10), color=CAPE),
    extra("UpperTorso", "box", size=(0.55, 1.5, 0.06), offset=(0, 0.05, -0.51), color=SKIN),
    # the sheathed saber at the left hip + the drawn Gryphon in the right fist (hidden in the scabbard at ease)
] + _scabbard() + _saber("RightHand")

# ------------------------------------------------------------------------------------------------ Idle: at ease
BASE = on_hilt(at_ease())
INHALE = on_hilt(at_ease({"Waist": (3.5, 24, -2), "Neck": (3, -12, 3), "RootOffset": (0.06, -0.02, 0), "Root": (1, -12, 1.5)}))
INHALE["LeftShoulder"] = add(INHALE, {"LeftShoulder": (0, 0, -3)})["LeftShoulder"]
GLANCE = on_hilt(at_ease({"Waist": (3, 24, -2), "Neck": (8, 14, -2), "RootOffset": (0.1, -0.07, 0)}))
GLANCE["ease"] = "quad_inout"
SMILE = on_hilt(at_ease({"Waist": (2, 24, -2), "Neck": (3, -18, 9), "RootOffset": (0.07, -0.08, 0)}))

IDLE = clip("Idle", 5.0, {
    0.0: BASE,
    1.5: INHALE,
    2.4: GLANCE,
    3.2: merge(GLANCE, {"Neck": (7, 12, -2)}),
    3.9: SMILE,
})

# ------------------------------------------------------------------------------------------------ Move: calm stroll
WALK = 1.1
KEYS = walk_cycle(length=WALK, stride=30.0, knee=36.0, arm=0.0, bounce=0.06)
for i, t in enumerate(sorted(KEYS)):
    k = KEYS[t]
    sgn = (1, 0, -1, 0)[i]
    swing = (0.18, 0.0, -0.18, 0.0)[i]
    k["Root"] = (-1, 4 * sgn, 0)
    k["Waist"] = (2, 24, -2)                 # the chest stays turned in: the hand never leaves the hilt
    k["Neck"] = (5, -20 - 3 * sgn, 0)        # ...and the head looks where he walks
    k.update(aim_arm("Left", forward=swing, down=1.0, back=0.1, inward=0.03, elbow=8))
    k.update(GRIP)
    k["RootOffset"] = add(k, {"RootOffset": (0, (-0.15, -0.08, -0.15, -0.08)[i], 0)})["RootOffset"]
MOVE = clip("Move", WALK, KEYS, speed="auto", motion=motion(lift=1.0, lean=0.7))

# ------------------------------------------------------------------------------------------------ Special: Haki + Kamusari
WIDE = {"Left": (-0.95, 0.252, -0.45), "Right": (0.8, 0.252, 0.35)}


def stance(root, off, waist, neck, feet=WIDE, hint=(0.45, 0, -1)):
    p = plant_feet({"Root": root, "RootOffset": off, "Waist": waist, "Neck": neck}, feet=feet, knee_hint=hint)
    p.update(aim_arm("Left", down=1.0, back=0.1, inward=0.03, elbow=6))
    return p


STILL = on_hilt(at_ease({"Neck": (-14, -12, 0), "RootOffset": (0.05, -0.12, 0), "Waist": (-2, 24, -2)}))
STILL["ease"] = "quad_in"
# Conqueror's Haki: feet set wide, sinks, chest out, head snaps up into the glare; the empty sleeve flares back
HAKI = on_hilt(stance((-2, -12, 0), (0.05, -0.45, 0.05), (6, 24, 0), (10, -14, 0)))
HAKI.update(aim_arm("Left", down=0.8, back=0.45, out=0.45, elbow=10))
HAKI["ease"] = "back_out"
HAKI_HOLD = on_hilt(stance((-2, -12, 0), (0.05, -0.5, 0.05), (8, 24, 0), (7, -14, 0)))
HAKI_HOLD.update(aim_arm("Left", down=0.8, back=0.5, out=0.5, elbow=12))
HAKI_HOLD["ease"] = "quad_in"

# the draw: blade swept up over the left shoulder, body coiled to the left
DRAW = stance((0, 24, 0), (0.05, -0.35, 0.1), (4, 26, 4), (10, -40, 0))
DRAW = reach(DRAW, "Right", (-0.55, 4.55, -0.45), elbow_hint=(0.6, 0.4, 0.6), wrist=(50, 0, 30))
DRAW.update(aim_arm("Left", down=0.9, back=0.5, out=0.3, elbow=10))
DRAW["ease"] = "quart_in"

# Kamusari: one huge diagonal cut down and across to the right, lunging onto the left foot
CUT_FEET = {"Left": (-0.8, 0.252, -1.55), "Right": (0.95, 0.252, 0.55)}
def cut(lean, drop, fwd, reach_to):
    p = stance((-lean, -26, 0), (0.1, -drop, -fwd), (-4, -22, -4), (10, 36, 0), feet=CUT_FEET, hint=(0.35, 0, -1))
    return reach(p, "Right", reach_to, elbow_hint=(1.0, -0.3, 0.2), wrist=(-70, 0, 0))


CUT = cut(8, 0.78, 0.6, (1.5, 1.8, -1.5))
CUT.update(aim_arm("Left", back=0.5, down=1.0, out=0.45, elbow=12))
CUT["ease"] = "quart_out"
FOLLOW = cut(10, 0.84, 0.66, (1.75, 1.6, -1.2))
FOLLOW.update(aim_arm("Left", back=0.55, down=1.0, out=0.5, elbow=14))
FOLLOW["ease"] = "sine_inout"
# the calm re-sheathe: straightening up, blade brought back round to the hip
SHEATHE = on_hilt(stance((0, -10, 1), (0.08, -0.2, 0.0), (2, 24, -2), (4, -10, 2), feet=FEET, hint=(0.2, 0, -1)))
SHEATHE["RightWrist"] = add(SHEATHE, {"RightWrist": (0, 0, 20)})["RightWrist"]
SHEATHE["ease"] = "quad_out"

SPECIAL = clip("Special", 4.4, {
    0.0: BASE,
    0.55: STILL,
    0.95: HAKI,
    1.45: HAKI_HOLD,
    1.85: DRAW,
    2.07: CUT,
    2.6: FOLLOW,
    3.3: SHEATHE,
    3.75: merge(BASE, {"ease": "sine_inout"}),
    4.4: BASE,
}, loop=False, effects=[
    accent(4.0, 0.9, 2.9),
    burst("Both", 0.97, color=(230, 36, 48), count=46, speed=18),
    burst("Both", 1.0, color=(255, 255, 255), count=16, speed=9),
    charge("RightHand", 0.95, 2.05, color=(210, 30, 44), size=0.8, light=True),
    burst("RightHand", 2.09, color=(255, 60, 70), count=40, speed=24),
    burst("RightHand", 2.12, color=(255, 255, 255), count=22, speed=12),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 2.07}
CAMERAS = {"Move": "side34", "Special": "front34"}
