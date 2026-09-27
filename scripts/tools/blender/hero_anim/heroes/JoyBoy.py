# Joy Boy - Luffy Gear 5 "Sun God Nika" (One Piece, Mythical) - HeroMotion style "bounce" + white Glitter.
#   Idle     cartoon laugh: fists on the hips, leaning way back, head thrown up to the sky, the whole body shaking with
#            rapid laugh bounces; then he doubles over and slaps his knee with the other arm flung up, and bounces back
#   Move     toon skip: every step is a springy hop, legs cycling in the air like a cartoon runner, both arms flung
#            up and waving - the clip owns the height (HeroMotion hop mostly off)
#   Special  Drums of Liberation: a rhythmic knee-up drum dance (don-don-don-don) with fists pumping to the sky on
#            every beat, glitter bursting on the off-beats, finishing in the wide-armed Nika pose with a laugh
from hero_anim.api import *  # noqa: F401,F403

HERO = "JoyBoy"
SPECIAL_EVERY = (7, 13)

WHITE = (248, 248, 250)
CREAM = (242, 212, 150)
PURPLE = (152, 92, 212)
SKIN = (246, 204, 164)
COLORS = palette(Torso=WHITE, LowerTorso=WHITE, Arms=SKIN, Hands=SKIN, Legs=WHITE, LowerLegs=SKIN, Feet=CREAM, Head=SKIN)
EXTRAS = [
    # white flame hair (spiky, wild) + the straw hat hanging off the back is left out: Nika wears it on his back
    extra("Head", "spikes", size=(1.0, 1.1, 1.0), offset=(0, 0.4, 0.15), rot=(-22, 0, 0), color=WHITE, emissive=True),
    extra("Head", "box", size=(1.34, 0.36, 1.3), offset=(0, 0.46, 0.06), color=WHITE, emissive=True),
    extra("Head", "sphere", size=(0.7, 0.7, 0.7), offset=(-0.5, 0.35, 0.3), color=WHITE, emissive=True),
    extra("Head", "sphere", size=(0.7, 0.7, 0.7), offset=(0.5, 0.35, 0.3), color=WHITE, emissive=True),
    # the cloud scarf around the neck and the purple rope sash
    extra("UpperTorso", "sphere", size=(0.8, 0.55, 0.8), offset=(-0.6, 0.78, -0.1), color=CREAM),
    extra("UpperTorso", "sphere", size=(0.8, 0.55, 0.8), offset=(0.6, 0.78, -0.1), color=CREAM),
    extra("UpperTorso", "sphere", size=(0.9, 0.6, 0.8), offset=(0, 0.72, 0.25), color=CREAM),
    extra("UpperTorso", "box", size=(0.62, 1.5, 0.06), offset=(0, 0.02, -0.5), color=SKIN),
    extra("LowerTorso", "box", size=(2.06, 0.2, 1.06), offset=(0, 0.1, 0), color=PURPLE),
    extra("LowerTorso", "box", size=(0.25, 0.7, 0.1), offset=(0.55, -0.35, -0.52), rot=(0, 0, 10), color=PURPLE),
]

WIDE = {"Left": (-0.85, 0.252, 0.0), "Right": (0.85, 0.252, 0.0)}


def legs(pose, feet=WIDE):
    return plant_feet(pose, feet=feet, knee_hint=(0.8, 0, -1))


def akimbo(pose, shake=0.0):
    """Fists on the hips, elbows flared (the hearty-laugh stance); shake lifts the shoulders with the laugh."""
    p = reach(pose, "Right", (1.2, 2.05 + 0.15 * shake, 0.0), elbow_hint=(1, 0.25, 0.1), wrist=(0, 0, 25))
    return reach(p, "Left", (-1.2, 2.05 + 0.15 * shake, 0.0), elbow_hint=(-1, 0.25, 0.1), wrist=(0, 0, -25))


# ------------------------------------------------------------------------------------------------ Idle: cartoon laugh
def laugh_back(shake):
    """Leaning back, head up to the sky; shake 0 = up, 1 = down beat of the laugh."""
    p = legs({"Root": (8, 0, 0), "RootOffset": (0, -0.22 - 0.16 * shake, 0.12), "Waist": (18 - 6 * shake, 0, 0),
              "Neck": (38 - 14 * shake, 0, 5 * (1 - 2 * shake))})
    return akimbo(p, 1.0 - shake)


def knee_slap(slap):
    """Doubled over to his right, right hand slapping the right knee, left arm flung up waving."""
    p = legs({"Root": (-12, -8, -6), "RootOffset": (0.12, -0.42 - 0.12 * slap, -0.1), "Waist": (-20 + 6 * slap, -10, -8),
              "Neck": (36 - 10 * slap, 10, 8)})
    p = reach(p, "Right", (1.05, 1.45 - 0.2 * slap, -1.0), elbow_hint=(1, 0.3, 0.5), wrist=(-20, 0, 0))
    p.update(aim_arm("Left", up=0.9, out=0.8, back=0.1, elbow=25 + 30 * slap, wrist=(0, 0, -20 * slap)))
    return p


UPB, DOWNB = laugh_back(0.0), laugh_back(1.0)
UPB["ease"], DOWNB["ease"] = "quad_out", "quad_in"
SLAP_UP, SLAP_DOWN = knee_slap(0.0), knee_slap(1.0)
SLAP_UP["ease"], SLAP_DOWN["ease"] = "quad_in", "quad_out"

IDLE = clip("Idle", 3.6, {
    0.0: UPB, 0.17: DOWNB, 0.34: UPB, 0.51: DOWNB, 0.68: UPB, 0.85: DOWNB, 1.02: UPB,
    1.45: SLAP_UP, 1.62: SLAP_DOWN, 1.82: SLAP_UP, 1.99: SLAP_DOWN, 2.2: merge(SLAP_UP, {"ease": "sine_inout"}),
    2.8: merge(DOWNB, {"ease": "back_out"}),
    3.1: UPB, 3.27: DOWNB,
})

# ------------------------------------------------------------------------------------------------ Move: toon skip
SKIP = 0.72


def skip_land(side):
    """Landing on `side`'s foot, the other knee high, arms up waving."""
    other = "Left" if side == "Right" else "Right"
    s = 1.0 if side == "Right" else -1.0
    p = {"Root": (-8, s * 8, s * 4), "RootOffset": (0, -0.24, 0), "Waist": (4, -s * 10, 0), "Neck": (18, s * 6, 0)}
    p.update(aim_leg(side, down=1.0, forward=0.15, knee=38, ankle=(12, 0, 0)))
    p.update(aim_leg(other, down=0.4, forward=1.0, knee=110, ankle=(-30, 0, 0)))
    p.update(aim_arm(side, up=0.35, out=1.0, back=0.2, elbow=40, wrist=(0, 0, s * 25)))
    p.update(aim_arm(other, up=0.2, out=1.0, forward=0.35, elbow=60, wrist=(0, 0, -s * 25)))
    p["ease"] = "quad_out"
    return p


def skip_air(side):
    """Top of the hop after `side`'s step: legs cycling (that leg kicked back, the other knee forward), arms flung up."""
    other = "Left" if side == "Right" else "Right"
    s = 1.0 if side == "Right" else -1.0
    p = {"Root": (6, -s * 6, 0), "RootOffset": (0, 0.85, 0), "Waist": (8, s * 8, 0), "Neck": (26, 0, 0)}
    p.update(aim_leg(side, down=1.0, back=0.8, knee=95, ankle=(-40, 0, 0)))
    p.update(aim_leg(other, down=0.7, forward=1.0, knee=70, ankle=(-20, 0, 0)))
    p.update(aim_arm(side, up=1.0, out=0.9, forward=0.2, elbow=15, wrist=(0, 0, -s * 30)))
    p.update(aim_arm(other, up=1.0, out=0.9, back=0.2, elbow=15, wrist=(0, 0, s * 30)))
    p["ease"] = "quad_in"
    return p


MOVE = clip("Move", SKIP, {
    0.0: skip_land("Right"),
    SKIP * 0.25: skip_air("Right"),
    SKIP * 0.5: skip_land("Left"),
    SKIP * 0.75: skip_air("Left"),
}, speed="auto", motion=motion(lift=0.15, lean=0.7))

# ------------------------------------------------------------------------------------------------ Special: Drums of Liberation
BEAT = 0.3


def drum(side, down):
    """One beat of the drum dance: `side`'s knee up and the other fist pumped to the sky; down = the stomp between."""
    other = "Left" if side == "Right" else "Right"
    s = 1.0 if side == "Right" else -1.0
    if down:
        p = legs({"Root": (-4, 0, 0), "RootOffset": (0, -0.38, 0), "Waist": (-4, s * 12, 0), "Neck": (6, -s * 10, 0)})
        p.update(aim_arm(other, up=0.35, out=1.0, forward=0.2, elbow=95, wrist=(0, 0, 0)))
        p.update(aim_arm(side, down=0.3, out=1.0, forward=0.3, elbow=90))
        p["ease"] = "quad_out"
        return p
    p = {"Root": (2, s * 10, -s * 8), "RootOffset": (0, -0.1, 0), "Waist": (8, s * 6, -s * 6), "Neck": (24, -s * 8, s * 10)}
    p.update(aim_leg(side, forward=1.0, down=0.25, out=0.35, knee=100, ankle=(-20, 0, 0)))
    p.update(aim_leg(other, down=1.0, out=0.08, knee=6))
    p.update(aim_arm(other, up=1.0, out=0.55, elbow=10, wrist=(0, 0, 0)))
    p.update(aim_arm(side, out=1.0, down=0.2, forward=0.3, elbow=100))
    p["ease"] = "quad_in"
    return p


NIKA = legs({"Root": (8, 0, 0), "RootOffset": (0, -0.2, 0.05), "Waist": (14, 0, 0), "Neck": (32, 0, 0)})
NIKA.update(aim_arm("Right", up=0.9, out=1.0, back=0.15, elbow=20, wrist=(0, 0, 20)))
NIKA.update(aim_arm("Left", up=0.9, out=1.0, back=0.15, elbow=20, wrist=(0, 0, -20)))
NIKA["ease"] = "back_out"

keys = {0.0: UPB, 0.3: merge(drum("Left", True), {"ease": "back_out"})}
t = 0.3
for i in range(8):
    side = "Right" if i % 2 == 0 else "Left"
    keys[round(t + BEAT * 0.5, 3)] = drum(side, False)
    keys[round(t + BEAT, 3)] = drum(side, True)
    t += BEAT
keys[round(t + 0.35, 3)] = NIKA
keys[round(t + 0.6, 3)] = add(NIKA, {"Waist": (4, 0, 0), "Neck": (6, 0, 0), "RootOffset": (0, -0.08, 0)})
keys[round(t + 0.8, 3)] = merge(NIKA, {"ease": "sine_inout"})
keys[round(t + 1.35, 3)] = UPB
SPECIAL_LEN = round(t + 1.35, 3)

SPECIAL = clip("Special", SPECIAL_LEN, keys, loop=False, effects=[
    accent(boost=3.5, t0=0.3, t1=SPECIAL_LEN - 0.3),
    burst("Both", 0.3 + BEAT * 2, color=(255, 255, 255), count=18, speed=9),
    burst("Both", 0.3 + BEAT * 4, color=(255, 240, 200), count=18, speed=9),
    burst("Both", 0.3 + BEAT * 6, color=(255, 255, 255), count=18, speed=9),
    burst("Both", 0.3 + BEAT * 8 + 0.36, color=(255, 250, 225), count=45, speed=16),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 1.62, "Move": 0.18, "Special": 0.75}  # sheet key times (a thumb off the sheet falls back to the last frame)
CAMERAS = {"Move": "side34", "Special": "front34"}
