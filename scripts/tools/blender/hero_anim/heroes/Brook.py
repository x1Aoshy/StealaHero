# Brook (One Piece, Straw Hat musician, the Soul King skeleton) - HeroMotion style "bounce".
#   Idle     violin solo: the violin tucked under his jaw, left hand on the neck, right arm sawing the bow in long
#            down/up strokes, the whole lanky body swaying and bobbing to the tune, skull tilted onto the violin
#   Move     jaunty skeleton strut: stiff lanky legs kicked high and straight with the toes up, knees snapping up on
#            the passing step, long arms swinging wide, upright gentleman posture (the HeroMotion hop mostly off)
#   Special  the gentleman's bow: hand on the heart, a deep bow from the hips... then the head flies back in a
#            "Yohohoho!" laugh with the arms thrown open and the ribs shaking (a pale soul-blue puff)
import math

from hero_anim import rbx
from hero_anim.api import *  # noqa: F401,F403

HERO = "Brook"
SPECIAL_EVERY = (9, 16)

BONE = (236, 230, 214)
SUIT = (40, 38, 52)
AFRO = (18, 18, 22)
WOOD = (150, 70, 30)
COLORS = palette(Torso=SUIT, Arms=SUIT, Hands=BONE, Legs=SUIT, Feet=(12, 12, 14), Head=BONE)

# ------------------------------------------------------------------------------------------------ violin hold (arms)
# Arm joints are solved on an upright body and merged into every key: they are relative to the torso, so the violin
# stays tucked under the jaw however the body sways.
VIOLIN_HAND = (-1.55, 3.95, -1.72)   # left hand on the violin neck (rest-body rig space)
CHIN = (-0.42, 4.02, -0.62)          # where the violin body rests (under the jaw, left of the chin)
BOW_IN = (-0.05, 3.92, -1.28)        # right hand at the frog end of a stroke (bow pushed across the strings)
BOW_OUT = (1.35, 3.62, -0.95)        # right hand at the tip end (bow drawn out)


def violin_arms(bow):
    """bow 0 = pushed in (up-bow end), 1 = drawn out (down-bow end)."""
    p = reach({}, "Left", VIOLIN_HAND, elbow_hint=(-1.0, -0.7, 0.1), wrist=(65, 0, -20))
    target = tuple(BOW_IN[i] + (BOW_OUT[i] - BOW_IN[i]) * bow for i in range(3))
    p = reach(p, "Right", target, elbow_hint=(1.0, -0.4, 0.3), wrist=(0, 0, 10))
    return {k: v for k, v in p.items() if "Shoulder" in k or "Elbow" in k or "Wrist" in k}


def _prop_in_hand(pose, part, center, axis_z, up=(0.0, 1.0, 0.0)):
    """(offset, rot) of a preview prop whose local Z runs along axis_z and whose centre sits at `center` (rig space)
    for `pose`, expressed in `part`'s frame (for extra(...))."""
    parts, _ = rig().fk(transforms_of(pose))
    frame = parts[part]
    z = rbx.v_norm(axis_z)
    y = rbx.v_norm(rbx.v_sub(up, rbx.v_scale(z, rbx.v_dot(up, z))))
    x = rbx.v_cross(y, z)
    world = (rbx.m_from_columns(x, y, z), tuple(center))
    local = rbx.cf_mul(rbx.cf_inv(frame), world)
    return tuple(round(v, 3) for v in local[1]), tuple(round(v, 2) for v in rbx.to_euler_xyz(local[0]))


def _violin_extras():
    pose = violin_arms(0.5)
    axis = rbx.v_sub(VIOLIN_HAND, CHIN)
    d = rbx.v_norm(axis)
    body_c = rbx.v_add(CHIN, rbx.v_scale(d, 0.5))
    neck_c = rbx.v_add(CHIN, rbx.v_scale(d, 0.5 * (1.0 + rbx.v_len(axis))))
    out = []
    for center, size, color in ((body_c, (0.85, 0.26, 1.2), WOOD), (body_c, (0.45, 0.28, 0.5), (110, 50, 20)),
                                (neck_c, (0.14, 0.12, rbx.v_len(axis) - 0.9), (30, 20, 16))):
        off, rot = _prop_in_hand(pose, "LeftHand", center, d)
        out.append(extra("LeftHand", "box", size=size, offset=off, rot=rot, color=color))
    return out


EXTRAS = [
    # the huge afro + top hat, skull eye sockets and grin
    extra("Head", "sphere", size=(2.4, 1.55, 1.75), offset=(0, 0.95, 0.28), color=AFRO),
    extra("Head", "box", size=(0.95, 0.85, 0.95), offset=(0, 2.08, 0.25), color=(10, 10, 12)),
    extra("Head", "box", size=(0.98, 0.14, 0.98), offset=(0, 1.78, 0.25), color=(150, 30, 40)),
    extra("Head", "box", size=(1.55, 0.07, 1.45), offset=(0, 1.68, 0.25), color=(10, 10, 12)),
    extra("Head", "box", size=(0.32, 0.3, 0.06), offset=(-0.24, 0.08, -0.6), color=(10, 10, 12)),
    extra("Head", "box", size=(0.32, 0.3, 0.06), offset=(0.24, 0.08, -0.6), color=(10, 10, 12)),
    extra("Head", "box", size=(0.6, 0.12, 0.06), offset=(0, -0.3, -0.6), color=(40, 40, 44)),
    # white cravat
    extra("UpperTorso", "box", size=(0.5, 0.9, 0.06), offset=(0, 0.3, -0.52), color=(240, 240, 236)),
    # the bow in the right hand (stick sideways from the fingers, toward the violin)
    extra("RightHand", "box", size=(2.4, 0.06, 0.06), offset=(-1.0, -0.12, -0.1), color=(90, 50, 24)),
] + _violin_extras()

FEET = {"Left": (-0.55, 0.252, -0.1), "Right": (0.6, 0.252, 0.12)}


def sway(s, bob, bow):
    """Swaying with the music: s = -1..1 side, bob = knee dip (studs), bow = stroke position."""
    p = {"Root": (0, 3 * s, 2.5 * s), "RootOffset": (0.04 * s, -0.05 - bob, 0), "Waist": (-3, 6 * s, 5 * s),
         "Neck": (-10, 26, 16 + 3 * s)}
    p = plant_feet(p, feet=FEET, knee_hint=(0.2, 0, -1))
    return merge(p, violin_arms(bow))


# ------------------------------------------------------------------------------------------------ Idle: violin solo
IDLE = clip("Idle", 4.0, {
    0.0: sway(-1, 0.0, 1.0),
    0.5: sway(-0.3, 0.14, 0.0),
    1.0: sway(0.6, 0.0, 1.0),
    1.5: sway(1.0, 0.14, 0.0),
    2.0: sway(0.3, 0.02, 1.0),
    2.3: sway(-0.2, 0.12, 0.4),   # quick up-bow flourish
    2.6: sway(-0.6, 0.0, 1.0),
    3.3: sway(-1.0, 0.16, 0.0),
})

# ------------------------------------------------------------------------------------------------ Move: skeleton strut
STRUT = 0.9


def strut(fwd, passing):
    back = "Left" if fwd == "Right" else "Right"
    s = 1.0 if fwd == "Right" else -1.0
    if passing:
        # the leg that was behind snaps its knee high, the support leg straight: body up
        p = {"Root": (4, 0, 0), "RootOffset": (0, 0.02, 0), "Waist": (2, 0, 0), "Neck": (10, 0, 0)}
        p.update(aim_leg(fwd, down=1.0, back=0.05, knee=4, ankle=(5, 0, 0)))
        p.update(aim_leg(back, forward=1.0, down=0.35, knee=100, ankle=(-30, 0, 0)))
        p.update(aim_arm("Right", down=1.0, out=0.3, elbow=10))
        p.update(aim_arm("Left", down=1.0, out=0.3, elbow=10))
        p["ease"] = "quad_in"
        return p
    # contact: the front leg kicked out long and straight, toes up; big opposite arm swing
    p = {"Root": (5, s * 8, 0), "RootOffset": (0, -0.3, 0), "Waist": (0, -s * 12, 0), "Neck": (6, s * 6, 0)}
    p.update(aim_leg(fwd, forward=0.75, down=1.0, knee=2, ankle=(30, 0, 0)))
    p.update(aim_leg(back, back=0.6, down=1.0, knee=25, ankle=(-25, 0, 0)))
    p.update(aim_arm(back, forward=1.0, down=0.9, out=0.15, elbow=18))
    p.update(aim_arm(fwd, back=0.9, down=1.0, out=0.15, elbow=8))
    p["ease"] = "quad_out"
    return p


MOVE = clip("Move", STRUT, {
    0.0: strut("Right", False),
    STRUT * 0.25: strut("Right", True),
    STRUT * 0.5: strut("Left", False),
    STRUT * 0.75: strut("Left", True),
}, speed="auto", motion=motion(lift=0.35, lean=0.7))

# ------------------------------------------------------------------------------------------------ Special: bow + Yohohoho
HEELS = {"Left": (-0.4, 0.252, 0.0), "Right": (0.4, 0.252, 0.0)}


def gentleman(lean, head):
    """Heels together, right hand on the heart, left arm (with the violin) swept out to the side."""
    p = plant_feet({"Root": (lean, 0, 0), "RootOffset": (0, -0.03 - 0.004 * abs(lean), 0.01 * abs(lean)),
                    "Waist": (lean * 0.3, 0, 0), "Neck": head}, feet=HEELS, knee_hint=(0.1, 0, -1))
    arms = reach({}, "Right", (0.35, 3.55, -0.78), elbow_hint=(1, -0.3, 0.4), wrist=(0, 0, 20))
    arms.update(aim_arm("Left", out=1.0, back=0.45, down=0.55, elbow=12))
    return merge(p, {k: v for k, v in arms.items() if "Shoulder" in k or "Elbow" in k or "Wrist" in k})


STAND = gentleman(0, (4, 0, 0))
STAND["ease"] = "quad_out"
BOW = gentleman(-30, (-14, 0, 0))
BOW["ease"] = "sine_inout"


def laugh(shake):
    p = plant_feet({"Root": (8, 0, 0), "RootOffset": (0, -0.08 - 0.12 * shake, 0.1), "Waist": (16 - 5 * shake, 0, 0),
                    "Neck": (40 - 12 * shake, 0, 0)}, feet=HEELS, knee_hint=(0.2, 0, -1))
    p.update(aim_arm("Right", up=0.7, out=1.0, back=0.2, elbow=25 + 10 * shake, wrist=(0, 0, 15)))
    p.update(aim_arm("Left", up=0.7, out=1.0, back=0.2, elbow=25 + 10 * shake, wrist=(0, 0, -15)))
    p["ease"] = "quad_out" if shake == 0 else "quad_in"
    return p


HA, HO = laugh(0), laugh(1)
SPECIAL = clip("Special", 4.6, {
    0.0: sway(-1, 0.0, 1.0),
    0.45: STAND,
    1.2: BOW,
    2.0: merge(add(BOW, {"Root": (-3, 0, 0)}), {"ease": "back_out"}),
    2.35: HA, 2.5: HO, 2.65: HA, 2.8: HO, 2.95: HA, 3.1: HO, 3.25: HA, 3.4: HO,
    3.7: merge(HA, {"ease": "sine_inout"}),
    4.6: sway(-1, 0.0, 1.0),
}, loop=False, effects=[
    burst("Both", 2.36, color=(190, 230, 255), count=22, speed=5),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 2.0}
CAMERAS = {"Move": "side34", "Special": "side34"}
