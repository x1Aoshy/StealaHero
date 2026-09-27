# Usopp (One Piece, Straw Hat sniper) - HeroMotion style "walk".
#   Idle     sniper aim: side-on archer stance, left arm locked out holding the slingshot, right hand drawing the band
#            back to the cheek; the aim trembles, then he jumps at a noise and snaps his head left and right
#            (nervous), and re-aims
#   Move     panic run: leaning back, knees pumping fast, both arms flailing up in the air, head turned back over
#            the shoulder at whatever is chasing him
#   Special  Hissatsu Kaen Boshi (fire star): draws the band all the way back (fire glowing in the pouch), lets it fly
#            with a recoil (fire burst from the slingshot), then strikes the proud "Great Captain Usopp" pose
from hero_anim.api import *  # noqa: F401,F403

HERO = "Usopp"
SPECIAL_EVERY = (9, 16)

OVERALLS = (150, 104, 58)
SKIN = (196, 142, 102)
BANDANA = (176, 192, 62)
HAIR = (30, 26, 26)
WOOD = (120, 72, 36)
COLORS = palette(UpperTorso=(236, 226, 196), LowerTorso=OVERALLS, Arms=SKIN, Hands=SKIN, Legs=OVERALLS,
                 Feet=(70, 50, 36), Head=SKIN)
EXTRAS = [
    # the long nose, curly black hair bundle, yellow-green bandana
    extra("Head", "cone", size=(0.28, 0.95, 0.28), offset=(0, -0.02, -0.55), rot=(-90, 0, 0), color=SKIN),
    extra("Head", "sphere", size=(1.5, 1.2, 1.2), offset=(0, 0.2, 0.35), color=HAIR),
    extra("Head", "box", size=(1.34, 0.32, 1.32), offset=(0, 0.45, 0.02), color=BANDANA),
    # overall straps on the shirt
    extra("UpperTorso", "box", size=(0.3, 1.6, 1.06), offset=(-0.55, 0, 0), color=OVERALLS),
    extra("UpperTorso", "box", size=(0.3, 1.6, 1.06), offset=(0.55, 0, 0), color=OVERALLS),
    # the slingshot in the left fist: grip along the hand's Z, the fork opening along -Z
    extra("LeftHand", "box", size=(0.18, 0.18, 0.8), offset=(0, 0, -0.05), color=WOOD),
    extra("LeftHand", "box", size=(0.14, 0.14, 0.6), offset=(-0.2, 0, -0.62), rot=(0, -25, 0), color=WOOD),
    extra("LeftHand", "box", size=(0.14, 0.14, 0.6), offset=(0.2, 0, -0.62), rot=(0, 25, 0), color=WOOD),
    # the ammo pouch on the hip
    extra("LowerTorso", "box", size=(0.5, 0.5, 0.4), offset=(0.75, -0.1, -0.45), color=(90, 60, 30)),
]

AIM_FEET = {"Left": (-0.55, 0.252, -0.75), "Right": (0.75, 0.252, 0.55)}
TARGET = (-0.4, 3.9, -12.0)  # what he aims at (rig space, ahead of him)


def aim(drop=0.3, draw=0.0, turn=0.0, head=None, wobble=(0.0, 0.0)):
    """Archer stance aimed at TARGET: body side-on (turned right), left arm straight at the target (+wobble in
    studs on the target), right hand drawing the band back toward the cheek (draw 0..1 = how far behind it goes)."""
    p = {"Root": (-2, -38 + turn, 0), "RootOffset": (0.05, -drop, 0.05), "Waist": (-4, -12, 0),
         "Neck": head or (4, 46 - turn * 0.5, 0)}
    p = plant_feet(p, feet=AIM_FEET, knee_hint=(0.4, 0, -1))
    p = aim_arm_at(p, "Left", (TARGET[0] + wobble[0], TARGET[1] + wobble[1], TARGET[2]), reach_frac=0.98, wrist=(0, 0, 0))
    return reach(p, "Right", (0.5 + 0.3 * draw, 3.95 - 0.1 * draw, 0.05 + 0.45 * draw), elbow_hint=(1.0, 0.1, 0.6),
                 wrist=(20, 0, 0))


# ------------------------------------------------------------------------------------------------ Idle
AIM = aim()
AIM_TENSE = aim(drop=0.36, draw=0.35)
TREMBLE_A = aim(drop=0.34, draw=0.3, wobble=(0.35, 0.25))
TREMBLE_B = aim(drop=0.35, draw=0.32, wobble=(-0.3, -0.2))
JUMP_L = aim(drop=0.2, turn=6, head=(10, 88, 8), wobble=(1.5, -2.5))
JUMP_R = aim(drop=0.24, turn=-4, head=(6, 8, -8), wobble=(-1.0, -2.0))
for k in (JUMP_L, JUMP_R):
    k["ease"] = "quart_out"
AIM_BACK = merge(aim(drop=0.3, draw=0.1), {"ease": "back_out"})

IDLE = clip("Idle", 4.4, {
    0.0: AIM,
    0.9: AIM_TENSE,
    1.2: TREMBLE_A,
    1.3: TREMBLE_B,
    1.4: TREMBLE_A,
    1.5: TREMBLE_B,
    1.9: JUMP_L,
    2.35: merge(JUMP_L, {"Neck": (12, 84, 4)}),
    2.5: JUMP_R,
    2.95: merge(JUMP_R, {"Neck": (4, 14, -6)}),
    3.2: AIM_BACK,
})

# ------------------------------------------------------------------------------------------------ Move: panic run
RUN_LEN = 0.5
RUN = run_cycle(length=RUN_LEN, stride=52.0, knee=95.0, arm=0.0, bounce=0.3, lean=-4.0)
RT = sorted(RUN)


def flail(side_up, t_phase):
    """Both arms up in the air, flailing: `side_up` arm high, the other lower and bent."""
    other = "Left" if side_up == "Right" else "Right"
    s = 1.0 if side_up == "Right" else -1.0
    p = aim_arm(side_up, up=1.0, out=0.55, forward=0.15, elbow=30, wrist=(0, 0, s * 30))
    p.update(aim_arm(other, up=0.45, out=1.0, back=0.1, elbow=70, wrist=(0, 0, -s * 30)))
    return p


for i, t in enumerate(RT):
    k = RUN[t]
    for side in ("Left", "Right"):
        k.pop(side + "Shoulder", None)
        k.pop(side + "Elbow", None)
    if i % 2 == 0:
        k = add(k, {"RootOffset": (0, -0.52, 0)})
    k.update(flail("Right" if i < 2 else "Left", i))
    k["Neck"] = (8, 62 if i < 2 else 56, 6)  # looking back over the left shoulder
    k["Waist"] = (4, 10, 0)
    RUN[t] = k
MOVE = clip("Move", RUN_LEN, RUN, speed="auto", motion=motion(lift=1.0, lean=0.5))

# ------------------------------------------------------------------------------------------------ Special: Kaen Boshi
DRAW = aim(drop=0.42, draw=1.0)
DRAW["ease"] = "quad_out"
DRAW_T1 = aim(drop=0.44, draw=1.05, wobble=(0.25, 0.2))
DRAW_T2 = aim(drop=0.45, draw=1.08, wobble=(-0.2, -0.15))
RELEASE = aim(drop=0.36, draw=0.0, wobble=(0.0, 3.5))
RELEASE.update(aim_arm("Right", back=1.0, out=0.9, up=0.3, elbow=15, wrist=(0, 0, 0)))
RELEASE = add(RELEASE, {"Root": (6, 0, 0), "RootOffset": (0, 0, 0.2)})
RELEASE["ease"] = "quart_out"
PROUD = plant_feet({"Root": (4, 0, 0), "RootOffset": (0, -0.08, 0), "Waist": (10, 0, 0), "Neck": (16, -8, 0)},
                   feet={"Left": (-0.72, 0.252, 0.0), "Right": (0.72, 0.252, 0.0)}, knee_hint=(0.3, 0, -1))
PROUD = reach(PROUD, "Left", (-1.25, 2.25, -0.1), elbow_hint=(-1, 0.2, 0.3))
PROUD.update(aim_arm("Right", up=1.0, forward=0.65, out=0.3, elbow=0, wrist=(-30, 0, 0)))
PROUD["ease"] = "back_out"
PROUD_B = add(PROUD, {"Waist": (3, 0, 0), "RootOffset": (0, 0.04, 0), "Neck": (4, 0, 0)})

SPECIAL = clip("Special", 3.9, {
    0.0: AIM,
    0.45: DRAW,
    0.95: DRAW_T1,
    1.05: DRAW_T2,
    1.15: DRAW_T1,
    1.25: RELEASE,
    1.75: merge(RELEASE, {"ease": "sine_inout"}),
    2.15: PROUD,
    2.9: PROUD_B,
    3.35: merge(PROUD, {"ease": "sine_inout"}),
    3.9: AIM,
}, loop=False, effects=[
    charge("LeftHand", 0.45, 1.25, color=(255, 120, 40), size=0.7),
    burst("LeftHand", 1.26, color=(255, 140, 40), count=40, speed=26),
    burst("LeftHand", 1.3, color=(255, 230, 120), count=20, speed=12),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 2.9}
CAMERAS = {"Idle": "side", "Move": "side34", "Special": "front34"}
