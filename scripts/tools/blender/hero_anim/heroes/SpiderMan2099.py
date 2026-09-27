# Spider-Man 2099 (Spider-Verse, Epic) - HeroMotion style "bounce" + blue Glitter.
#   Idle     predator perch: crouched up on the toes, both talon hands raised and curled like claws, head low and
#            tilting slowly (hunting), a sudden talon flex
#   Move     talon glide: right web swing, release and DIVE into a flat glide with the arms spread wide (the web-wing
#            membranes open) and the legs trailing, banking left then right, then the left web and a second glide -
#            Web effect per swing, Glitter pumped through the glides, HeroMotion hops off (lift 0)
#   Special  thwip + talon slash: right web-shot, yanks the target in, rears up with both talons high and rips an X
#            slash down across the front (red Burst), then settles back into the perch
from hero_anim.api import *  # noqa: F401,F403

HERO = "SpiderMan2099"
SPECIAL_EVERY = (9, 16)

NAVY = (26, 38, 118)
DARK = (16, 20, 52)
RED = (222, 34, 46)
COLORS = palette(Head=NAVY, Torso=NAVY, Arms=NAVY, Hands=DARK, Legs=NAVY, Feet=RED)
EXTRAS = [
    # red skull face plate with dark eye cut-outs
    extra("Head", "box", size=(0.95, 0.9, 0.08), offset=(0, 0.02, -0.58), color=RED),
    extra("Head", "box", size=(0.34, 0.26, 0.06), offset=(-0.24, 0.12, -0.63), rot=(0, 0, -20), color=(10, 10, 20)),
    extra("Head", "box", size=(0.34, 0.26, 0.06), offset=(0.24, 0.12, -0.63), rot=(0, 0, 20), color=(10, 10, 20)),
    # red skull-spider on the chest and the back
    extra("UpperTorso", "box", size=(0.9, 0.95, 0.08), offset=(0, 0.1, -0.52), color=RED),
    extra("UpperTorso", "box", size=(0.5, 0.7, 0.08), offset=(0, 0.1, 0.52), color=RED),
    extra("UpperTorso", "box", size=(0.22, 0.2, 0.06), offset=(-0.2, 0.28, -0.57), color=NAVY),
    extra("UpperTorso", "box", size=(0.22, 0.2, 0.06), offset=(0.2, 0.28, -0.57), color=NAVY),
    # web-wing membranes under the arms (show when the arms spread)
    extra("RightUpperArm", "box", size=(0.9, 1.05, 0.06), offset=(-0.95, -0.05, 0.1), color=RED),
    extra("LeftUpperArm", "box", size=(0.9, 1.05, 0.06), offset=(0.95, -0.05, 0.1), color=RED),
    # talons
    extra("RightHand", "cone", size=(0.18, 0.45, 0.18), offset=(0.3, -0.15, -0.3), rot=(180, 0, 0), color=RED),
    extra("RightHand", "cone", size=(0.18, 0.45, 0.18), offset=(0.0, -0.15, -0.3), rot=(180, 0, 0), color=RED),
    extra("LeftHand", "cone", size=(0.18, 0.45, 0.18), offset=(-0.3, -0.15, -0.3), rot=(180, 0, 0), color=RED),
    extra("LeftHand", "cone", size=(0.18, 0.45, 0.18), offset=(0.0, -0.15, -0.3), rot=(180, 0, 0), color=RED),
]

# ------------------------------------------------------------------------------------------------ Idle: predator perch
FEET = {"Left": (-0.95, 0.36, 0.1), "Right": (0.95, 0.36, 0.1)}


def perch(look=0.0, tilt=0.0, claw=0.0, sink=0.0):
    """Crouched on the toes (heels up), talons raised in front; claw 0..1 = talons flexed/snapped up."""
    base = {"Root": (-22, look * 0.15, 0), "RootOffset": (0.0, -0.9 - sink, -0.1), "Waist": (-6 + claw * 6, look * 0.2, 0),
            "Neck": (34 - claw * 6, look, tilt)}
    p = plant_feet(base, feet=FEET, knee_hint=(1.1, 0.0, -1.0))
    for side in ("Left", "Right"):
        p[side + "Ankle"] = add({"a": p[side + "Ankle"]}, {"a": (-28, 0, 0)})["a"]  # up on the toes
    # asymmetric rake: right talon high by the face, left talon low and forward
    p = reach(p, "Right", (0.85, 3.05 + claw * 0.35, -1.45), elbow_hint=(1.0, -0.6, 0.2), wrist=(-50 + claw * 25, 0, -10))
    p = reach(p, "Left", (-1.05, 2.05 + claw * 0.35, -1.65), elbow_hint=(-1.0, -0.2, 0.5), wrist=(-55 + claw * 25, 0, 10))
    return p


PERCH = perch()
PERCH_IN = perch(sink=0.06)
HUNT_L = merge(perch(look=28, tilt=16, sink=0.03), {"ease": "sine_inout"})
FLEX = merge(perch(look=-6, tilt=-4, claw=1.0, sink=-0.1), {"ease": "back_out"})

IDLE = clip("Idle", 4.2, {
    0.0: PERCH,
    1.0: PERCH_IN,
    1.9: HUNT_L,
    2.6: HUNT_L,
    2.95: FLEX,
    3.35: merge(FLEX, {"ease": "sine_inout"}),
})

# ------------------------------------------------------------------------------------------------ Move: talon glide
ANCHOR_R = (2.2, 15.0, -7.0)
ANCHOR_L = (-2.2, 15.0, -7.0)


def hang(side, root_pitch, offset, legs, free_arm):
    p = {"Root": (root_pitch, 0, -4 if side == "Right" else 4), "RootOffset": offset, "Neck": (20 - root_pitch * 0.35, 0, 0),
         "Waist": (-4, 0, 0)}
    p.update(legs)
    p.update(free_arm)
    return aim_arm_at(p, side, ANCHOR_R if side == "Right" else ANCHOR_L, elbow_hint=(1 if side == "Right" else -1, 0, 1),
                      wrist=(-20, 0, 0))


LEGS_HANG = merge(aim_leg("Right", down=1.0, forward=0.5, knee=70, ankle=(-30, 0, 0)), aim_leg("Left", down=1.0, forward=0.15, knee=40, ankle=(-30, 0, 0)))
LEGS_SWEEP = merge(aim_leg("Right", down=0.5, forward=1.0, knee=25, ankle=(-35, 0, 0)), aim_leg("Left", down=0.8, forward=1.0, knee=50, ankle=(-35, 0, 0)))
TALON_OUT = aim_arm("Left", out=1.0, down=0.25, back=0.15, elbow=35, wrist=(-45, 0, 0))

BACK_R = hang("Right", -32, (0, 1.05, 0.6), LEGS_HANG, TALON_OUT)
BOTTOM_R = hang("Right", 0, (0, 0.3, 0.0), LEGS_HANG, TALON_OUT)
FRONT_R = hang("Right", 34, (0, 1.5, -0.6), LEGS_SWEEP, TALON_OUT)
BACK_R["ease"] = "quad_in"
BOTTOM_R["ease"] = "quad_out"
FRONT_R["ease"] = "quad_out"
BACK_L = hang("Left", -32, (0, 1.05, 0.6), mirror(LEGS_HANG), mirror(TALON_OUT))
BOTTOM_L = hang("Left", 0, (0, 0.3, 0.0), mirror(LEGS_HANG), mirror(TALON_OUT))
FRONT_L = hang("Left", 34, (0, 1.5, -0.6), mirror(LEGS_SWEEP), mirror(TALON_OUT))
BACK_L["ease"] = "quad_in"
BOTTOM_L["ease"] = "quad_out"
FRONT_L["ease"] = "quad_out"


def glide(bank, pitch=-72, lift=1.7):
    """Flat glide: arms spread wide and a little back (the web-wings open), legs together trailing, banking `bank`."""
    p = {"Root": (pitch, 0, bank), "RootOffset": (0, lift, 0), "Neck": (48, 0, -bank * 0.4), "Waist": (6, 0, 0)}
    p.update(aim_arm("Right", out=1.0, back=0.3, up=0.05, elbow=12, wrist=(-35, 0, 0)))
    p.update(aim_arm("Left", out=1.0, back=0.3, up=0.05, elbow=12, wrist=(-35, 0, 0)))
    p.update(aim_leg("Right", down=1.0, back=0.12, out=0.05, knee=6, ankle=(-45, 0, 0)))
    p.update(aim_leg("Left", down=1.0, back=0.08, out=0.05, knee=14, ankle=(-45, 0, 0)))
    return p


GLIDE_A = merge(glide(16, lift=1.85), {"ease": "sine_inout"})
GLIDE_B = merge(glide(-12, pitch=-60, lift=1.55), {"ease": "quad_in"})
GLIDE_C = merge(glide(-16, lift=1.85), {"ease": "sine_inout"})
GLIDE_D = merge(glide(12, pitch=-60, lift=1.55), {"ease": "quad_in"})

MOVE = clip("Move", 3.0, {
    0.0: BACK_R,
    0.42: BOTTOM_R,
    0.74: FRONT_R,
    1.0: GLIDE_A,
    1.34: GLIDE_B,
    1.5: BACK_L,
    1.92: BOTTOM_L,
    2.24: FRONT_L,
    2.5: GLIDE_C,
    2.84: GLIDE_D,
}, effects=[
    web("RightHand", anchor=ANCHOR_R, t0=0.0, t1=0.74),
    web("LeftHand", anchor=ANCHOR_L, t0=1.5, t1=2.24),
    accent(2.5, 0.8, 1.45),
    accent(2.5, 2.3, 2.95),
], motion=motion(lift=0.0, lean=0.35), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: thwip + talon X-slash
STANCE = plant_feet({"RootOffset": (0.0, -0.55, 0.0), "Root": (-8, 0, 0), "Neck": (10, 0, 0)},
                    feet={"Left": (-0.95, 0.252, -0.2), "Right": (0.95, 0.252, 0.25)}, knee_hint=(0.9, 0.0, -1.0))
RISE = merge(STANCE, aim_arm("Right", forward=0.7, down=0.5, out=0.3, elbow=95, wrist=(40, 0, 0)),
             aim_arm("Left", forward=0.6, out=0.5, down=0.3, elbow=60, wrist=(-45, 0, 0)), {"ease": "quad_out"})
SHOOT = merge(STANCE, web_shoot("Right"), {"Waist": (0, 16, 0), "ease": "quart_out"})
SHOOT.update(aim_arm("Left", forward=0.6, out=0.5, down=0.3, elbow=60, wrist=(-45, 0, 0)))
YANK = merge(STANCE, aim_arm("Right", back=0.6, down=0.5, out=0.4, elbow=110, wrist=(30, 0, 0)),
             aim_arm("Left", forward=0.6, out=0.5, down=0.3, elbow=60, wrist=(-45, 0, 0)),
             {"Waist": (12, 26, 0), "Root": (4, 8, 0), "Neck": (6, -18, 0), "ease": "back_out"})
REAR = plant_feet({"RootOffset": (0.0, -0.15, 0.1), "Root": (8, 0, 0), "Waist": (10, 0, 0), "Neck": (18, 0, 0)},
                  feet={"Left": (-0.95, 0.35, -0.2), "Right": (0.95, 0.35, 0.25)}, knee_hint=(0.9, 0.0, -1.0))
REAR.update(aim_arm("Right", up=1.0, out=0.55, back=0.25, elbow=35, wrist=(40, 0, 0)))
REAR.update(aim_arm("Left", up=1.0, out=0.55, back=0.25, elbow=35, wrist=(40, 0, 0)))
REAR["LeftAnkle"] = (-25, 0, 0)
REAR["RightAnkle"] = (-25, 0, 0)
REAR["ease"] = "quart_in"  # wind up slow, then rip down
SLASH = plant_feet({"RootOffset": (0.0, -0.8, -0.35), "Root": (-26, 0, 0), "Waist": (-14, 0, 0), "Neck": (40, 0, 0)},
                   feet={"Left": (-0.95, 0.252, -0.2), "Right": (0.95, 0.252, 0.25)}, knee_hint=(0.9, 0.0, -1.0))
SLASH.update(aim_arm("Right", forward=1.0, down=0.9, inward=0.75, elbow=8, wrist=(-35, 0, 0)))
SLASH.update(aim_arm("Left", forward=1.0, down=0.75, inward=0.75, elbow=8, wrist=(-35, 0, 0)))
SLASH["ease"] = "quad_out"
SLASH_HOLD = add(SLASH, {"Waist": (-4, 0, 0), "RootOffset": (0, -0.05, 0)})

SPECIAL = clip("Special", 3.0, {
    0.0: PERCH,
    0.3: RISE,
    0.48: SHOOT,
    0.85: YANK,
    1.2: REAR,
    1.42: SLASH,
    1.9: SLASH_HOLD,
    3.0: PERCH,
}, loop=False, effects=[
    web("RightHand", anchor=(1.0, 3.8, -18.0), t0=0.48, t1=0.95, width=0.1),
    burst("Both", 1.36, color=RED, count=36, speed=16),
    accent(2.8, 1.1, 1.9),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 1.0, "Special": 1.42}
CAMERAS = {"Move": "side34"}
