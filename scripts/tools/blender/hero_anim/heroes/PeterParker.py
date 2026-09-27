# Peter Parker / Spider-Man (Spider-Verse, Common) - HeroMotion style "bounce".
#   Idle     crouched spider stance: low and wide, one hand on the ground, head scanning (spider sense), breathing
#   Move     web-swing loop: right-hand swing (web to an anchor high ahead), release, left-hand swing; the body hangs
#            under the web (feet back at the start of the arc, feet forward at the release) - Web effect per swing,
#            HeroMotion hops switched off (lift 0) so the swing arc owns the height
#   Special  thwip-thwip: right web shot straight ahead, tug, left web shot, back to the crouch
from hero_anim.api import *  # noqa: F401,F403

HERO = "PeterParker"
SPECIAL_EVERY = (8, 15)

RED = (205, 28, 34)
BLUE = (32, 64, 186)
COLORS = palette(Torso=RED, LowerTorso=BLUE, Arms=RED, Hands=RED, Legs=BLUE, Feet=RED, Head=RED)
EXTRAS = [
    # the big white mask eyes (Roblox part-local: -Z is the face)
    extra("Head", "box", size=(0.34, 0.42, 0.08), offset=(-0.27, 0.12, -0.6), rot=(0, 0, -18), color=(245, 245, 250)),
    extra("Head", "box", size=(0.34, 0.42, 0.08), offset=(0.27, 0.12, -0.6), rot=(0, 0, 18), color=(245, 245, 250)),
    # black spider on the chest
    extra("UpperTorso", "box", size=(0.3, 0.55, 0.08), offset=(0, 0.1, -0.52), color=(20, 20, 24)),
]

# ------------------------------------------------------------------------------------------------ Idle
CROUCH = spider_crouch(drop=1.05, hand="Left")
CROUCH_IN = add(CROUCH, {"Waist": (4, 0, 0), "Neck": (-3, 0, 0), "RootOffset": (0, 0.05, 0)})
LOOK_L = add(CROUCH, {"Neck": (4, 32, 6), "Waist": (0, 8, 0)})
LOOK_R = add(CROUCH, {"Neck": (2, -34, -6), "Waist": (0, -8, 0)})

IDLE = clip("Idle", 4.2, {
    0.0: CROUCH,
    0.9: CROUCH_IN,
    1.6: merge(LOOK_L, {"ease": "quart_out"}),
    2.5: LOOK_L,
    3.0: merge(LOOK_R, {"ease": "quart_out"}),
    3.7: CROUCH_IN,
})

# ------------------------------------------------------------------------------------------------ Move: web swing
ANCHOR_R = (2.2, 15.0, -6.0)  # rig space: up and ahead, a bit to the right (right-hand web)
ANCHOR_L = (-2.2, 15.0, -6.0)


def swing_pose(root_pitch, offset, hips, knees, other_arm):
    p = {"Root": (root_pitch, 0, -4), "RootOffset": offset, "Neck": (20 - root_pitch * 0.35, 0, 0), "Waist": (-6, -8, 0)}
    p.update(aim_leg("Right", down=1.0, forward=hips[0], knee=knees[0], ankle=(-35, 0, 0)))
    p.update(aim_leg("Left", down=1.0, forward=hips[1], knee=knees[1], ankle=(-30, 0, 0)))
    p.update(other_arm)
    return aim_arm_at(p, "Right", ANCHOR_R, elbow_hint=(1, 0, 1))


BACK = swing_pose(-32, (0, 1.0, 0.6), (0.9, 0.6), (95, 115), aim_arm("Left", out=1.0, back=0.6, down=0.2, elbow=35))
BOTTOM = swing_pose(0, (0, 0.15, 0.0), (0.35, 0.15), (30, 45), aim_arm("Left", out=1.0, down=0.6, back=0.3, elbow=25))
FRONT = swing_pose(38, (0, 1.35, -0.6), (1.4, 1.1), (35, 55), aim_arm("Left", out=0.8, up=0.3, back=0.5, elbow=40))
BACK["ease"] = "quad_in"      # drop into the arc
BOTTOM["ease"] = "quad_out"   # rise out of it
FRONT["ease"] = "sine_inout"  # release, tuck and fly into the next web

MOVE = clip("Move", 2.2, {
    0.0: BACK,
    0.45: BOTTOM,
    0.8: FRONT,
    1.1: mirror(BACK),
    1.55: mirror(BOTTOM),
    1.9: mirror(FRONT),
}, effects=[
    web("RightHand", anchor=ANCHOR_R, t0=0.0, t1=0.8),
    web("LeftHand", anchor=ANCHOR_L, t0=1.1, t1=1.9),
], motion=motion(lift=0.0, lean=0.4), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: thwip-thwip
RISE = crouch(drop=0.7, width=0.45, lean=10, knee_out=1.0)
RISE.update({"Neck": (6, 0, 0)})
RISE.update(aim_arm("Right", forward=0.7, down=0.5, out=0.3, elbow=95, wrist=(40, 0, 0)))
RISE.update(aim_arm("Left", forward=0.7, down=0.5, out=0.3, elbow=95, wrist=(40, 0, 0)))
SHOOT_R = merge(RISE, web_shoot("Right"), {"Waist": (0, 14, 0), "ease": "quart_out"})
TUG_R = merge(RISE, aim_arm("Right", forward=1.0, down=0.1, elbow=55, wrist=(40, 0, 0)), aim_arm("Left", down=1.0, out=0.4, elbow=30),
              {"Waist": (8, 18, 0), "Root": (-6, 0, 0)})
SHOOT_L = merge(RISE, web_shoot("Left"), {"Waist": (0, -14, 0), "ease": "quart_out"})
TUG_L = merge(RISE, aim_arm("Left", forward=1.0, down=0.1, elbow=55, wrist=(40, 0, 0)), aim_arm("Right", down=1.0, out=0.4, elbow=30),
              {"Waist": (8, -18, 0), "Root": (-6, 0, 0)})

SPECIAL = clip("Special", 2.4, {
    0.0: CROUCH,
    0.35: merge(RISE, {"ease": "quad_out"}),
    0.5: SHOOT_R,
    0.85: TUG_R,
    1.15: SHOOT_L,
    1.5: TUG_L,
    2.4: CROUCH,
}, loop=False, effects=[
    web("RightHand", anchor=(1.2, 3.6, -18.0), t0=0.5, t1=1.0, width=0.1),
    web("LeftHand", anchor=(-1.2, 3.6, -18.0), t0=1.15, t1=1.7, width=0.1),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 1.6, "Move": 0.45, "Special": 0.5}
CAMERAS = {"Move": "side"}
