# Miles Morales (Spider-Verse, Rare) - HeroMotion style "bounce" + yellow/blue venom Sparks.
#   Idle     camo crouch: folded tight and low with both hands down (the "invisible" hide), head low, a sudden spider-sense
#            glance to each side, venom sparks crackling on one fist then the other
#   Move     venom-spark web-swing: right web while the free fist crackles with venom, release into a tucked corkscrew
#            (barrel roll), left web, release into a mid-air camo crouch that drops into the next web - Web effect per
#            swing, venom Charge on the free hand + a Burst at every release, HeroMotion hops off (lift 0)
#   Special  thwip + venom strike: left web-shot and yank, right fist wound back crackling with venom, lunging venom punch
#            (Burst + Sparks accent), back into the crouch
from hero_anim.api import *  # noqa: F401,F403

HERO = "MilesMorales"
SPECIAL_EVERY = (8, 14)

BLACK = (24, 24, 30)
RED = (212, 30, 42)
VENOM = (255, 226, 90)
VENOM_BLUE = (110, 205, 255)
COLORS = palette(Head=BLACK, Torso=BLACK, Arms=BLACK, Hands=RED, Legs=BLACK, Feet=RED)
EXTRAS = [
    # sharp white mask eyes
    extra("Head", "box", size=(0.36, 0.3, 0.08), offset=(-0.27, 0.12, -0.6), rot=(0, 0, -24), color=(248, 248, 252)),
    extra("Head", "box", size=(0.36, 0.3, 0.08), offset=(0.27, 0.12, -0.6), rot=(0, 0, 24), color=(248, 248, 252)),
    # big red spider on the chest (body + legs)
    extra("UpperTorso", "box", size=(0.3, 0.62, 0.08), offset=(0, 0.05, -0.52), color=RED),
    extra("UpperTorso", "box", size=(1.3, 0.1, 0.08), offset=(0, 0.3, -0.52), rot=(0, 0, 18), color=RED),
    extra("UpperTorso", "box", size=(1.3, 0.1, 0.08), offset=(0, 0.3, -0.52), rot=(0, 0, -18), color=RED),
    # red web stripes on the arms and white sneaker soles
    extra("LeftUpperArm", "box", size=(1.04, 0.12, 1.04), offset=(0, 0.1, 0), color=RED),
    extra("RightUpperArm", "box", size=(1.04, 0.12, 1.04), offset=(0, 0.1, 0), color=RED),
    extra("LeftFoot", "box", size=(1.04, 0.1, 1.04), offset=(0, -0.12, 0), color=(245, 245, 245)),
    extra("RightFoot", "box", size=(1.04, 0.1, 1.04), offset=(0, -0.12, 0), color=(245, 245, 245)),
]

# ------------------------------------------------------------------------------------------------ Idle: camo crouch


def camo(look=0.0, drop=0.0, tilt=0.0):
    """Tight low crouch, both hands down between the feet; look = head yaw, drop = extra sink."""
    p = crouch(drop=1.2 + drop, width=0.3, lean=34, knee_out=0.9)
    p.update({"Waist": (-16, look * 0.25, 0), "Neck": (44, look, tilt)})
    p = reach(p, "Right", (0.5, 0.42 - drop, -1.45), elbow_hint=(1.0, 0.2, 0.4), wrist=(-40, 0, 0))
    p = reach(p, "Left", (-0.5, 0.42 - drop, -1.45), elbow_hint=(-1.0, 0.2, 0.4), wrist=(-40, 0, 0))
    return p


CAMO = camo()
CAMO_IN = camo(drop=0.06)
SENSE_L = merge(camo(look=48, tilt=6, drop=-0.08), {"ease": "quart_out"})   # spider-sense snap
SENSE_R = merge(camo(look=-44, tilt=-6, drop=-0.08), {"ease": "quart_out"})

IDLE = clip("Idle", 4.4, {
    0.0: CAMO,
    0.9: CAMO_IN,
    1.5: SENSE_L,
    2.2: SENSE_L,
    2.55: SENSE_R,
    3.2: SENSE_R,
    3.7: CAMO_IN,
}, effects=[
    charge("RightHand", 0.6, 1.05, color=VENOM, size=0.45, light=True),
    charge("LeftHand", 3.3, 3.75, color=VENOM_BLUE, size=0.45, light=True),
])

# ------------------------------------------------------------------------------------------------ Move: venom-spark swing
ANCHOR_R = (2.4, 14.5, -6.0)
ANCHOR_L = (-2.4, 14.5, -6.0)


def hang(side, root_pitch, offset, legs, free_arm):
    p = {"Root": (root_pitch, 0, -5 if side == "Right" else 5), "RootOffset": offset, "Neck": (22 - root_pitch * 0.35, 0, 0),
         "Waist": (-8, -10 if side == "Right" else 10, 0)}
    p.update(legs)
    p.update(free_arm)
    return aim_arm_at(p, side, ANCHOR_R if side == "Right" else ANCHOR_L, elbow_hint=(1 if side == "Right" else -1, 0, 1))


# street style: knees tucked and loose, the free fist cocked by the head crackling with venom
LEGS_TUCK = merge(aim_leg("Right", down=1.0, forward=0.9, knee=105, ankle=(-25, 0, 0)), aim_leg("Left", down=1.0, forward=0.4, knee=120, ankle=(-20, 0, 0)))
LEGS_KICK = merge(aim_leg("Right", down=1.0, forward=0.2, knee=35, ankle=(-30, 0, 0)), aim_leg("Left", down=1.0, back=0.3, knee=70, ankle=(-30, 0, 0)))
LEGS_FRONT = merge(aim_leg("Right", down=0.4, forward=1.0, knee=40, ankle=(-30, 0, 0)), aim_leg("Left", down=0.7, forward=1.0, knee=80, ankle=(-25, 0, 0)))
FIST_COCK = aim_arm("Left", out=0.8, forward=0.3, down=0.2, elbow=115, twist=-30)     # venom fist cocked by the chest
FIST_OUT = aim_arm("Left", out=1.0, down=0.6, back=0.3, elbow=40)

BACK_R = hang("Right", -30, (0, 1.0, 0.6), LEGS_TUCK, FIST_COCK)
BOTTOM_R = hang("Right", 2, (0, 0.2, 0.0), LEGS_KICK, FIST_COCK)
FRONT_R = hang("Right", 36, (0, 1.45, -0.6), LEGS_FRONT, FIST_OUT)
BACK_R["ease"] = "quad_in"
BOTTOM_R["ease"] = "quad_out"
FRONT_R["ease"] = "quad_out"

# tucked corkscrew after the right web (barrel roll about the travel axis, Root +Z = roll to its left)
BALL = merge(aim_leg("Right", forward=1.0, up=0.3, down=0, knee=140, ankle=(-30, 0, 0)),
             aim_leg("Left", forward=1.0, up=0.3, down=0, knee=140, ankle=(-30, 0, 0)),
             aim_arm("Right", forward=1.0, down=0.2, out=0.25, elbow=95), aim_arm("Left", forward=1.0, down=0.2, out=0.25, elbow=95),
             {"Waist": (-22, 0, 0), "Neck": (-15, 0, 0)})
ROLL_A = merge(BALL, {"Root": (-25, 0, 115), "RootOffset": (0, 2.2, -0.2)})
ROLL_B = merge(BALL, {"Root": (-25, 0, 235), "RootOffset": (0, 2.45, 0.0)})
ROLL_C = merge(BALL, {"Root": (-25, 0, 330), "RootOffset": (0, 1.9, 0.2), "ease": "sine_out"})

BACK_L = hang("Left", -30, (0, 1.0, 0.6), mirror(LEGS_TUCK), mirror(FIST_COCK))
BOTTOM_L = hang("Left", 2, (0, 0.2, 0.0), mirror(LEGS_KICK), mirror(FIST_COCK))
FRONT_L = hang("Left", 36, (0, 1.45, -0.6), mirror(LEGS_FRONT), mirror(FIST_OUT))
BACK_L["ease"] = "quad_in"
BOTTOM_L["ease"] = "quad_out"
FRONT_L["ease"] = "quad_out"

# mid-air camo crouch: folds up small, one hand down like landing on a wall, then drops into the next web
AIR_CROUCH = merge(camo(), {"RootOffset": (0, 1.6, 0.2), "Root": (-20, 0, 0)})
AIR_CROUCH = reach(AIR_CROUCH, "Right", (1.4, 3.6, -0.6), elbow_hint=(1.0, -0.3, 0.3))  # arm out to shoot the next web
AIR_CROUCH["ease"] = "sine_in"

MOVE = clip("Move", 2.7, {
    0.0: BACK_R,
    0.42: BOTTOM_R,
    0.76: FRONT_R,
    0.92: ROLL_A,
    1.07: ROLL_B,
    1.21: ROLL_C,
    1.36: BACK_L,
    1.78: BOTTOM_L,
    2.12: FRONT_L,
    2.4: AIR_CROUCH,
}, effects=[
    web("RightHand", anchor=ANCHOR_R, t0=0.0, t1=0.76),
    web("LeftHand", anchor=ANCHOR_L, t0=1.36, t1=2.12),
    charge("LeftHand", 0.0, 0.8, color=VENOM, size=0.6),
    charge("RightHand", 1.36, 2.16, color=VENOM_BLUE, size=0.6),
    burst("LeftHand", 0.78, color=VENOM, count=24, speed=12),
    burst("RightHand", 2.14, color=VENOM_BLUE, count=24, speed=12),
], motion=motion(lift=0.0, lean=0.4), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: thwip + venom strike
RISE = crouch(drop=0.65, width=0.5, lean=8, knee_out=0.9)
RISE.update({"Neck": (8, 0, 0), "Waist": (0, 0, 0)})
RISE.update(merge(aim_arm("Right", forward=0.6, down=0.6, out=0.4, elbow=100, wrist=(40, 0, 0)),
                  aim_arm("Left", forward=0.6, down=0.6, out=0.4, elbow=100, wrist=(40, 0, 0))))
RISE["ease"] = "quad_out"
SHOOT_L = merge(RISE, web_shoot("Left"), {"Waist": (0, -16, 0), "ease": "quart_out"})
SHOOT_L.update(aim_arm("Right", out=0.6, forward=0.3, down=0.3, elbow=110, twist=30))
YANK = merge(RISE, aim_arm("Left", forward=0.7, down=0.4, out=0.2, elbow=100, wrist=(30, 0, 0)), {"Waist": (10, 20, 0), "Root": (-4, 0, 0)})
YANK.update(aim_arm("Right", out=0.6, forward=0.3, down=0.3, elbow=110, twist=30))
# wind-up: body twisted to the right, right fist drawn back by the hip, crackling
WIND = plant_feet({"Root": (-10, -22, 0), "RootOffset": (0.0, -0.75, 0.15), "Waist": (-4, -34, 0), "Neck": (4, 50, 0)},
                  feet={"Left": (-0.75, 0.252, -0.6), "Right": (0.85, 0.252, 0.55)}, knee_hint=(0.8, 0.0, -1.0))
WIND.update(aim_arm("Right", back=1.0, down=0.6, out=0.3, elbow=95))
WIND.update(aim_arm("Left", forward=1.0, out=0.3, down=0.1, elbow=25, wrist=(20, 0, 0)))
WIND["ease"] = "back_out"
WIND_T = add(WIND, {"Waist": (0, -6, 0), "RootOffset": (0, -0.05, 0.05)})
WIND_T["ease"] = "quart_in"
# the venom strike: lunging right cross, the whole body thrown into it
PUNCH = plant_feet({"Root": (-16, 18, 0), "RootOffset": (0.0, -0.8, -0.55), "Waist": (-8, 22, 0), "Neck": (12, -36, 0)},
                   feet={"Left": (-0.75, 0.252, -1.25), "Right": (0.8, 0.252, 0.9)}, knee_hint=(0.8, 0.0, -1.0))
PUNCH.update(aim_arm("Right", forward=1.0, up=0.08, inward=0.1))
PUNCH.update(aim_arm("Left", back=0.8, down=0.6, out=0.4, elbow=70))
PUNCH["ease"] = "quart_out"
HOLD = add(PUNCH, {"Waist": (4, -4, 0), "RightElbow": (12, 0, 0)})
# recover: back foot steps in, shake the venom off the hand, sink back down
RECOVER = crouch(drop=0.75, width=0.35, lean=18, knee_out=0.9)
RECOVER.update({"Neck": (18, 0, 0), "Waist": (-6, 0, 0)})
RECOVER.update(merge(aim_arm("Right", forward=0.5, down=1.0, out=0.3, elbow=40, wrist=(0, 0, 25)),
                     aim_arm("Left", forward=0.4, down=1.0, out=0.3, elbow=50)))

SPECIAL = clip("Special", 3.0, {
    0.0: CAMO,
    0.3: RISE,
    0.48: SHOOT_L,
    0.82: YANK,
    1.15: WIND,
    1.55: WIND_T,
    1.68: PUNCH,
    2.15: HOLD,
    2.35: add(blend(HOLD, RECOVER, 0.5), {"RootOffset": (0, 0.3, 0), "RightKnee": (-25, 0, 0)}),
    2.55: RECOVER,
    3.0: CAMO,
}, loop=False, effects=[
    web("LeftHand", anchor=(-1.0, 3.8, -18.0), t0=0.48, t1=1.0, width=0.1),
    charge("RightHand", 0.95, 1.95, color=VENOM, size=1.1),
    charge("RightHand", 1.68, 2.2, color=VENOM_BLUE, size=0.8, light=False),
    burst("RightHand", 1.7, color=VENOM, count=45, speed=18),
    accent(3.0, 0.95, 2.3),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.9, "Move": 1.07, "Special": 1.68}
CAMERAS = {"Move": "side"}
