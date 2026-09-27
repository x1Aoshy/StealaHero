# Hawkeye (Avengers, Common) - HeroMotion style "walk".
#   Idle     the archer on watch: bow hanging in the left hand, scanning the horizon; then he turns side-on, nocks, draws to
#            the cheek and holds the aim, tracking a target left and right, before easing the string off and lowering
#   Move     a marksman's purposeful walk: bow carried low and steady in the left hand, the right arm swinging, head up
#   Special  quick-draw double shot: hand to the quiver over the shoulder, nock, full draw, RELEASE (arrow streak + burst),
#            the drawing hand flying back; reaches again and fires a second arrow high into the sky, then lowers the bow
import math

from hero_anim import rbx
from hero_anim.api import *  # noqa: F401,F403

HERO = "Hawkeye"
SPECIAL_EVERY = (9, 16)

PURPLE = (74, 44, 116)
BLACK = (32, 30, 40)
SKIN = (232, 190, 152)
HAIR = (150, 112, 70)
COLORS = palette(Head=SKIN, Torso=PURPLE, LowerTorso=BLACK, UpperArms=SKIN, LowerArms=BLACK, Hands=BLACK, Legs=BLACK,
                 Feet=(22, 22, 26))
EXTRAS = [
    # short sandy hair
    extra("Head", "box", size=(1.26, 0.3, 1.24), offset=(0, 0.52, 0.04), color=HAIR),
    # black vest panel + quiver on the back with purple fletchings
    extra("UpperTorso", "box", size=(0.7, 1.62, 1.04), offset=(0.35, 0, 0), color=BLACK),
    extra("UpperTorso", "box", size=(0.45, 1.6, 0.45), offset=(0.45, 0.2, 0.72), rot=(0, 0, -25), color=(70, 52, 40)),
    extra("UpperTorso", "box", size=(0.35, 0.3, 0.35), offset=(0.9, 1.1, 0.72), rot=(0, 0, -25), color=(150, 90, 220)),
    # the bow in the left hand: grip + two limbs (hand-local Z = vertical when the bow arm points at the target)
    extra("LeftHand", "box", size=(0.2, 0.2, 0.7), offset=(0, -0.1, 0), color=(40, 36, 52)),
    extra("LeftHand", "box", size=(0.12, 0.14, 1.6), offset=(0, 0.08, -1.1), rot=(-12, 0, 0), color=(90, 60, 140)),
    extra("LeftHand", "box", size=(0.12, 0.14, 1.6), offset=(0, 0.08, 1.1), rot=(12, 0, 0), color=(90, 60, 140)),
]

BOW_DOWN = (80, 0, 0)   # left wrist: bow hanging vertical along the leg
BOW_UP = (0, 0, 0)      # left wrist when the bow arm points at the target (bow vertical)
TARGET = (-30.0, 4.0, -8.0)   # off to his left: the drawn bow faces the viewer
SKY = (-18.0, 26.0, -12.0)

# ------------------------------------------------------------------------------------------------ Idle: watch + draw


def watch(look=0.0, breath=0.0):
    """Relaxed ready stance: feet apart, bow hanging in the left hand, right hand loose; look = head yaw."""
    base = {"Root": (0, 0, 0), "RootOffset": (0.0, -0.08 - breath * 0.02, 0.0), "Waist": (breath * 3, look * 0.2, 0), "Neck": (4, look, 0)}
    p = plant_feet(base, feet={"Left": (-0.7, 0.252, -0.15), "Right": (0.65, 0.252, 0.15)}, knee_hint=(0.3, 0.0, -1.0),
                   foot_yaw={"Left": -12, "Right": 15})
    p.update(aim_arm("Left", down=1.0, out=0.28, forward=0.12, elbow=12, twist=10, wrist=BOW_DOWN))
    p.update(aim_arm("Right", down=1.0, out=0.15, forward=0.05, elbow=18 + breath * 4))
    return p


def _yaw(point, deg):
    """Rig-space point turned `deg` degrees about Y (+ = to the hero's left)."""
    c, n = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return (point[0] * c + point[2] * n, point[1], -point[0] * n + point[2] * c)


def archer(target, draw=1.0, sway=0.0, lean=0.0):
    """Side-on archer: left shoulder to the target, bow arm straight at `target`, right hand drawn to the cheek
    (draw 0 = hand at the bow, 1 = full draw); sway = small aim tracking (degrees). The whole stance turns with the
    target's direction (targets off to the hero's left read best: the full-draw silhouette faces the viewer)."""
    aim = math.degrees(math.atan2(-target[0], -target[2]))  # + = target to the hero's left
    base = {"Root": (0, aim - 68 + sway, 0), "RootOffset": (0.0, -0.18, 0.0), "Waist": (lean, -8 + sway * 0.4, 0), "Neck": (0, 72, 0)}
    feet = {"Left": _yaw((-0.35, 0.252, -0.65), aim), "Right": _yaw((0.55, 0.252, 0.55), aim)}
    p = plant_feet(base, feet=feet, knee_hint=(0.3, 0.0, -1.0), foot_yaw={"Left": aim - 35, "Right": aim - 80})
    p = aim_arm_at(p, "Left", target, reach_frac=0.98, elbow_hint=(-0.2, -1.0, 0.0), wrist=BOW_UP)
    # hand positions along the arrow line: at the bow grip (draw 0) back to the cheek (draw 1)
    _, joints = rig().fk(transforms_of(p))
    neck = joints["Neck"][1]
    grip = shoulder_position(p, "Left")
    d = rbx_dir(grip, target)
    bow_hand = (grip[0] + d[0] * 1.6, grip[1] + d[1] * 1.6, grip[2] + d[2] * 1.6)
    right = _yaw((0.18, 0.0, 0.0), aim)  # the anchor point sits on the right side of the jaw
    cheek = (neck[0] + d[0] * 0.3 + right[0], neck[1] + 0.02, neck[2] + d[2] * 0.3 + right[2])
    hand = tuple(bow_hand[i] + (cheek[i] - bow_hand[i]) * draw for i in range(3))
    p = reach(p, "Right", hand, elbow_hint=(-d[0], 0.2, -d[2]), wrist=(0, 0, -20))  # elbow straight back along the arrow
    return p


def arrow_line(pose, tip=0.7, reach_out=None):
    """The nocked arrow of `pose`: runs from the string hand's palm through the bow grip. Returns the rig-space point
    `tip` studs past the grip (the arrowhead: a Web beam from the right palm to it draws the arrow on the string), or
    with reach_out the point that far down the same line (where the loosed arrow streaks to)."""
    parts, _ = rig().fk(transforms_of(pose))
    grip = parts["LeftHand"][1]
    hand = parts["RightHand"]
    palm = rbx.v_add(hand[1], rbx.m_vec(hand[0], (0.0, -0.27, 0.0)))  # the runtime's palm attachment (web start)
    d = rbx_dir(palm, grip)
    k = reach_out if reach_out is not None else tip
    return (round(grip[0] + d[0] * k, 3), round(grip[1] + d[1] * k, 3), round(grip[2] + d[2] * k, 3))


def rbx_dir(a, b):
    v = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    n = (v[0] ** 2 + v[1] ** 2 + v[2] ** 2) ** 0.5
    return (v[0] / n, v[1] / n, v[2] / n)


WATCH = watch()
WATCH_IN = watch(look=-24, breath=1.0)
SCAN = merge(watch(look=30), {"ease": "sine_inout"})
NOCK = merge(archer(TARGET, draw=0.05), {"ease": "quad_out"})
DRAW = merge(archer(TARGET, draw=1.0), {"ease": "sine_inout"})
TRACK_L = archer(TARGET, draw=1.0, sway=4)
TRACK_R = archer(TARGET, draw=1.0, sway=-3.5)
EASE_OFF = merge(archer(TARGET, draw=0.2), {"Neck": (-6, 72, 0), "ease": "sine_inout"})

SHAFT = (205, 180, 255)
IDLE = clip("Idle", 6.0, {
    0.0: WATCH,
    1.0: WATCH_IN,
    1.8: SCAN,
    2.45: NOCK,
    2.85: DRAW,
    3.45: TRACK_L,
    4.1: TRACK_R,
    4.6: DRAW,
    5.15: EASE_OFF,
}, effects=[
    # the arrow on the string from the nock to the ease-off (the bow hand holds still: the tip stays on the grip)
    web("RightHand", anchor=arrow_line(DRAW), t0=2.45, t1=5.2, color=SHAFT, width=0.06),
])

# ------------------------------------------------------------------------------------------------ Move: marksman's walk
WALK_LEN = 1.0
WALK = walk_cycle(length=WALK_LEN, stride=30, knee=38, arm=24, bounce=0.09)
for _t, _p in WALK.items():
    # the bow arm stays low and steady (bow hanging), head up and scanning ahead
    _p.update(aim_arm("Left", down=1.0, out=0.3, forward=0.2, elbow=18, twist=10, wrist=BOW_DOWN))
    _p["Neck"] = (6, 0, 0)
    _p["Root"] = add({"r": _p.get("Root", (0, 0, 0))}, {"r": (-4, 0, 0)})["r"]
MOVE = clip("Move", WALK_LEN, WALK, speed="auto")

# ------------------------------------------------------------------------------------------------ Special: quick-draw double shot
QUIVER = archer(TARGET, draw=0.0)
QUIVER = reach(QUIVER, "Right", (0.65, 4.75, 0.55), elbow_hint=(0.6, 1.0, -0.2), wrist=(-30, 0, 0))  # hand over the shoulder
QUIVER["ease"] = "quad_out"
SHOT_DRAW = merge(archer(TARGET, draw=1.0), {"ease": "quad_in"})
RELEASE = archer(TARGET, draw=1.0)
_, _joints = rig().fk(transforms_of(RELEASE))
RELEASE = reach(RELEASE, "Right", (_joints["Neck"][1][0] + 0.5, _joints["Neck"][1][1] + 0.3, _joints["Neck"][1][2] + 0.9),
                elbow_hint=(0.3, 0.2, 1.0), wrist=(-40, 0, 0))  # the string hand flies back past the ear, open
RELEASE["ease"] = "quart_out"
QUIVER_2 = archer(SKY, draw=0.0, lean=10)
QUIVER_2 = reach(QUIVER_2, "Right", (0.6, 4.8, 0.6), elbow_hint=(0.6, 1.0, -0.2), wrist=(-30, 0, 0))
QUIVER_2["ease"] = "quad_out"
SKY_DRAW = merge(archer(SKY, draw=1.0, lean=14), {"ease": "quad_in"})
SKY_RELEASE = archer(SKY, draw=1.0, lean=16)
_, _joints = rig().fk(transforms_of(SKY_RELEASE))
SKY_RELEASE = reach(SKY_RELEASE, "Right", (_joints["Neck"][1][0] + 0.5, _joints["Neck"][1][1] + 0.1, _joints["Neck"][1][2] + 1.0),
                    elbow_hint=(0.3, 0.0, 1.0), wrist=(-40, 0, 0))
SKY_RELEASE["ease"] = "quart_out"

ARROW = (190, 150, 255)
SPECIAL = clip("Special", 3.6, {
    0.0: WATCH,
    0.3: QUIVER,
    0.55: NOCK,
    0.85: SHOT_DRAW,
    1.05: RELEASE,
    1.45: QUIVER_2,
    1.75: SKY_DRAW,
    2.05: SKY_RELEASE,
    2.7: merge(archer(SKY, draw=0.25, lean=8), {"ease": "sine_inout"}),
    3.6: WATCH,
}, loop=False, effects=[
    # nocked arrows on the string, then each one streaks off down the same line on the release
    web("RightHand", anchor=arrow_line(SHOT_DRAW), t0=0.55, t1=1.05, color=SHAFT, width=0.06),
    web("LeftHand", anchor=arrow_line(SHOT_DRAW, reach_out=40.0), t0=1.05, t1=1.2, color=ARROW, width=0.08),
    burst("LeftHand", 1.05, color=ARROW, count=18, speed=10),
    web("RightHand", anchor=arrow_line(SKY_DRAW), t0=1.6, t1=2.05, color=SHAFT, width=0.06),
    web("LeftHand", anchor=arrow_line(SKY_DRAW, reach_out=40.0), t0=2.05, t1=2.2, color=ARROW, width=0.08),
    burst("LeftHand", 2.05, color=(255, 210, 120), count=22, speed=12),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 3.45, "Move": 0.0, "Special": 1.05}
CAMERAS = {"Idle": "front", "Special": "front"}
