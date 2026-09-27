# Agent Venom (Spider-Verse, Legendary) - HeroMotion style "walk".
#   Idle     soldier's combat stance: bladed southpaw stance, knees loaded, guard up (lead hand open, rear fist by the jaw), sharp
#            tactical head sweeps, and a comms check (hand to the earpiece) now and then
#   Move     tactical run: forward lean, tight pumping arms held high like a combat sprint, long driving strides
#   Special  symbiote flare: curls in tight (dark energy gathering on the hands), then EXPLODES open - arms flung wide and
#            back, chest out, head thrown back, tendrils bursting off both hands - and snaps back into the stance
from hero_anim.api import *  # noqa: F401,F403

HERO = "AgentVenom"
SPECIAL_EVERY = (10, 17)

BLACK = (20, 20, 26)
WHITE = (238, 238, 242)
GEAR = (96, 102, 92)
COLORS = palette(Head=BLACK, Torso=BLACK, Arms=BLACK, Hands=BLACK, Legs=BLACK, Feet=(40, 42, 40))
EXTRAS = [
    # angular white symbiote eyes
    extra("Head", "box", size=(0.42, 0.26, 0.08), offset=(-0.26, 0.14, -0.6), rot=(0, 0, -28), color=WHITE),
    extra("Head", "box", size=(0.42, 0.26, 0.08), offset=(0.26, 0.14, -0.6), rot=(0, 0, 28), color=WHITE),
    # big white spider across the chest
    extra("UpperTorso", "box", size=(0.34, 0.7, 0.08), offset=(0, 0.0, -0.52), color=WHITE),
    extra("UpperTorso", "box", size=(1.7, 0.14, 0.08), offset=(0, 0.3, -0.52), rot=(0, 0, 24), color=WHITE),
    extra("UpperTorso", "box", size=(1.7, 0.14, 0.08), offset=(0, 0.3, -0.52), rot=(0, 0, -24), color=WHITE),
    # tactical gear: belt, thigh holster, shoulder straps
    extra("LowerTorso", "box", size=(2.08, 0.3, 1.08), offset=(0, 0.02, 0), color=GEAR),
    extra("RightUpperLeg", "box", size=(0.5, 0.6, 0.7), offset=(0.35, 0.05, 0), color=GEAR),
    extra("UpperTorso", "box", size=(0.24, 2.0, 1.05), offset=(0.1, 0, 0), rot=(0, 0, 38), color=GEAR),
    extra("LeftUpperArm", "box", size=(1.06, 0.4, 1.06), offset=(0, 0.3, 0), color=GEAR),
]

# ------------------------------------------------------------------------------------------------ Idle: combat stance
FEET = {"Left": (-0.6, 0.252, -0.55), "Right": (0.75, 0.252, 0.5)}


def _orthodox(look=0.0, sink=0.0, twist=0.0):
    """Bladed stance, left foot forward, body turned a bit to the right; guard up (authored orthodox, used mirrored)."""
    base = {"Root": (-8, -18 + twist, 0), "RootOffset": (0.0, -0.45 - sink, 0.0), "Waist": (-4, 6 + look * 0.2, 0),
            "Neck": (4, 12 + look, 0)}
    p = plant_feet(base, feet=FEET, knee_hint=(0.6, 0.0, -1.0), foot_yaw={"Left": -10, "Right": -35})
    p = reach(p, "Left", (-0.55, 3.55, -1.9), elbow_hint=(-0.7, -1.0, 0.2), wrist=(0, 0, -10))   # lead hand open, forward
    p = reach(p, "Right", (0.35, 3.75, -1.0), elbow_hint=(0.8, -1.0, 0.2), wrist=(-10, 0, 0))    # rear fist by the jaw
    return p


def stance(look=0.0, sink=0.0, twist=0.0):
    """Southpaw version (right foot and right hand lead, chest turned toward the hero's left); look + = to its left."""
    return mirror(_orthodox(-look, sink, -twist))


GUARD = stance()
GUARD_IN = stance(sink=0.05)
SWEEP_L = merge(stance(look=44, sink=0.02, twist=6), {"ease": "quart_out"})  # snap the head, hold, snap back
SWEEP_R = merge(stance(look=-48), {"ease": "quart_out"})
COMMS = stance(look=12, sink=0.02)
COMMS = reach(COMMS, "Left", (-0.62, 4.45, -0.15), elbow_hint=(-1.0, 0.2, 0.2), wrist=(0, 0, -20))  # finger to the earpiece
COMMS["Neck"] = (6, -8, 12)
COMMS["ease"] = "quad_out"

IDLE = clip("Idle", 5.0, {
    0.0: GUARD,
    0.8: GUARD_IN,
    1.3: SWEEP_L,
    1.9: SWEEP_L,
    2.15: SWEEP_R,
    2.7: SWEEP_R,
    3.1: COMMS,
    4.0: COMMS,
    4.4: GUARD_IN,
})

# ------------------------------------------------------------------------------------------------ Move: tactical run
RUN_LEN = 0.62
RUN = run_cycle(length=RUN_LEN, stride=52, knee=80, arm=38, bounce=0.2, lean=16)
for _t, _p in RUN.items():
    # tight combat sprint: forearms high and bent hard, fists near the chest, head level
    RUN[_t] = add(_p, {"RightElbow": (22, 0, 0), "LeftElbow": (22, 0, 0), "Neck": (12, 0, 0), "Waist": (-4, 0, 0)})
MOVE = clip("Move", RUN_LEN, RUN, speed="auto")

# ------------------------------------------------------------------------------------------------ Special: symbiote flare
CURL = plant_feet({"Root": (-20, 0, 0), "RootOffset": (0.0, -0.8, 0.0), "Waist": (-22, 0, 0), "Neck": (-10, 0, 0)},
                  feet={"Left": (-0.8, 0.252, -0.25), "Right": (0.8, 0.252, 0.2)}, knee_hint=(0.8, 0.0, -1.0))
CURL = reach(CURL, "Right", (-0.3, 2.9, -1.2), elbow_hint=(1.0, -0.8, 0.0), wrist=(-20, 0, 0))
CURL = reach(CURL, "Left", (0.3, 3.2, -1.25), elbow_hint=(-1.0, -0.8, 0.0), wrist=(-20, 0, 0))
CURL["ease"] = "quad_out"
CURL_T = add(CURL, {"Waist": (-4, 0, 0), "RootOffset": (0, -0.06, 0), "Neck": (-4, 0, 0)})
CURL_T["ease"] = "quint_in"  # coil ... then explode
FLARE = plant_feet({"Root": (10, 0, 0), "RootOffset": (0.0, -0.3, 0.1), "Waist": (18, 0, 0), "Neck": (26, 0, 0)},
                   feet={"Left": (-1.15, 0.252, -0.3), "Right": (1.15, 0.252, 0.25)}, knee_hint=(0.9, 0.0, -1.0),
                   foot_yaw={"Left": -20, "Right": 20})
FLARE.update(aim_arm("Right", out=1.0, up=0.55, back=0.45, elbow=10, twist=-60, wrist=(55, 0, 0)))
FLARE.update(aim_arm("Left", out=1.0, up=0.55, back=0.45, elbow=10, twist=60, wrist=(55, 0, 0)))
FLARE["ease"] = "quad_out"
SHAKE_A = add(FLARE, {"Waist": (0, 4, 2), "Neck": (4, -6, 0), "RightShoulder": (0, 0, 6), "LeftShoulder": (0, 0, 6)})
SHAKE_B = add(FLARE, {"Waist": (0, -4, -2), "Neck": (2, 6, 0), "RightShoulder": (0, 0, -6), "LeftShoulder": (0, 0, -6)})
SNAP = merge(stance(look=0), {"ease": "back_out"})

SPECIAL = clip("Special", 3.2, {
    0.0: GUARD,
    0.35: CURL,
    1.05: CURL_T,
    1.2: FLARE,
    1.45: SHAKE_A,
    1.65: SHAKE_B,
    1.85: SHAKE_A,
    2.05: FLARE,
    2.7: SNAP,
    3.2: GUARD,
}, loop=False, effects=[
    charge("Both", 0.35, 1.2, color=(70, 70, 86), size=0.8, light=False),
    burst("Both", 1.2, color=(16, 16, 22), count=55, speed=22),
    burst("Both", 1.22, color=(235, 235, 245), count=18, speed=14),
    charge("Both", 1.2, 2.05, color=(30, 30, 38), size=1.4, light=False),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.2}
