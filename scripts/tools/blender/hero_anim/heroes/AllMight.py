# All Might (My Hero Academia, Mythic) - HeroMotion style "stomp" (golden dust). The Symbol of Peace.
#   Idle     "I AM HERE!": huge proud stance, feet planted wide, fists on the hips, chest out and chin up, deep heroic
#            breaths; then a big thumbs-up with the grin turned to the crowd
#   Move     heavy hero stomp: wide slamming steps, chest out, arms pumping (HeroMotion adds the dip and dust)
#   Special  UNITED STATES OF SMASH: a deep crouch, a leap with the right fist cocked high behind him, he dives down
#            punching (golden shockwave), superhero landing with the fist on the ground, then rises with the fist
#            thrust to the sky - PLUS ULTRA
from hero_anim.api import *  # noqa: F401,F403

HERO = "AllMight"
SPECIAL_EVERY = (10, 17)

BLUE = (36, 82, 192)
GOLD = (255, 214, 60)
RED = (206, 40, 40)
WHITE = (240, 240, 244)
SKIN = (244, 204, 164)
COLORS = palette(UpperTorso=BLUE, LowerTorso=GOLD, UpperArms=BLUE, LowerArms=WHITE, Hands=WHITE, Legs=BLUE, Feet=RED,
                 Head=SKIN)
EXTRAS = [
    # golden hair with the two famous V bangs
    extra("Head", "box", size=(1.25, 0.4, 1.2), offset=(0, 0.45, 0.05), color=GOLD),
    extra("Head", "cone", size=(0.35, 1.6, 0.3), offset=(0.25, 0.5, -0.35), rot=(0, 0, -24), color=GOLD),
    extra("Head", "cone", size=(0.35, 1.6, 0.3), offset=(-0.25, 0.5, -0.35), rot=(0, 0, 24), color=GOLD),
    # the grin + shadowed eyes
    extra("Head", "box", size=(0.9, 0.18, 0.05), offset=(0, -0.22, -0.53), color=(250, 250, 250)),
    extra("Head", "box", size=(0.95, 0.22, 0.05), offset=(0, 0.12, -0.53), color=(30, 40, 70)),
    # red / white chest stripes
    extra("UpperTorso", "box", size=(0.4, 1.0, 0.06), offset=(-0.45, 0.25, -0.52), rot=(0, 0, -20), color=RED),
    extra("UpperTorso", "box", size=(0.4, 1.0, 0.06), offset=(0.45, 0.25, -0.52), rot=(0, 0, 20), color=RED),
]

# ------------------------------------------------------------------------------------------------ Idle: I AM HERE
FEET = {"Left": (-0.95, 0.252, -0.05), "Right": (0.95, 0.252, 0.05)}


def proud(chest=8.0, chin=12.0, look=0.0, up=0.0):
    p = plant_feet({"Root": (0, look * 0.2, 0), "RootOffset": (0, -0.12 + up, 0), "Waist": (chest, look * 0.3, 0),
                    "Neck": (chin, look, 0)}, FEET, knee_hint=(0.6, 0.0, -1.0))
    return merge(p, fists_on_hips())


PROUD = proud()
PROUD_IN = proud(14, 16, up=0.06)
THUMBS = proud(10, 10, look=26)
THUMBS = reach(THUMBS, "Right", (0.85, 4.05, -1.45), elbow_hint=(1.0, -0.8, 0.0), wrist=(-10, 0, 0))
THUMBS["ease"] = "back_out"

IDLE = clip("Idle", 5.0, {
    0.0: PROUD,
    1.5: PROUD_IN,
    2.5: THUMBS,
    3.7: add(THUMBS, {"Neck": (2, -6, 0)}),
    4.3: PROUD,
})

# ------------------------------------------------------------------------------------------------ Move: heavy stomp
STOMP = stomp_cycle(length=1.3, stride=28.0, knee=42.0, arm=30.0, drop=0.28)
for t in list(STOMP):
    ease = STOMP[t].get("ease")
    STOMP[t] = add(STOMP[t], {"Waist": (8, 0, 0), "Neck": (10, 0, 0)})
    if ease:
        STOMP[t]["ease"] = ease
MOVE = clip("Move", 1.3, STOMP, motion=motion(lift=0.5, lean=1.0), speed="auto")

# ------------------------------------------------------------------------------------------------ Special: US of Smash
CROUCH = merge(crouch(drop=0.85, width=0.5, lean=26, knee_out=0.8), {"Neck": (30, 0, 0)},
               aim_arm("Right", down=1.0, back=0.8, out=0.3, elbow=20), aim_arm("Left", down=1.0, back=0.8, out=0.3, elbow=20))
CROUCH["ease"] = "quad_in"
LEAP = merge({"Root": (16, 0, 0), "RootOffset": (0, 2.3, 0.2), "Waist": (10, 0, 0), "Neck": (6, 0, 0)},
             aim_arm("Right", up=1.0, back=0.75, out=0.2, elbow=75, twist=-20),
             aim_arm("Left", forward=1.0, up=0.2, out=0.3, elbow=15),
             aim_leg("Right", down=1.0, forward=0.6, knee=100, ankle=(-30, 0, 0)),
             aim_leg("Left", down=1.0, back=0.2, knee=80, ankle=(-30, 0, 0)))
LEAP["ease"] = "quad_out"
APEX = add(LEAP, {"RootOffset": (0, 0.35, 0), "Root": (6, 0, 0), "Waist": (4, 0, 0), "RightShoulder": (-10, 0, 0)})
APEX["ease"] = "quart_in"
SMASH = merge({"Root": (-40, 0, 0), "RootOffset": (0, 0.9, -0.9), "Waist": (-10, 0, 0), "Neck": (34, 0, 0)},
              aim_arm("Right", forward=0.8, down=1.0, elbow=0, wrist=(0, 0, 0)),
              aim_arm("Left", back=0.8, out=0.6, up=0.1, elbow=30),
              aim_leg("Right", down=1.0, back=0.3, knee=60, ankle=(-30, 0, 0)),
              aim_leg("Left", down=1.0, forward=0.2, knee=50, ankle=(-30, 0, 0)))
SMASH["ease"] = "quad_in"
LAND = plant_feet({"Root": (-22, 0, 0), "RootOffset": (0, -1.1, -0.6), "Waist": (-8, 0, 0), "Neck": (30, 0, 0)},
                  {"Left": (-0.9, 0.252, -0.9), "Right": (0.9, 0.252, 0.6)}, knee_hint=(0.7, 0.0, -1.0))
LAND = reach(LAND, "Right", (0.7, 0.3, -1.6), elbow_hint=(1.0, 0.2, 0.3), wrist=(0, 0, 0))
LAND.update(aim_arm("Left", out=1.0, back=0.5, up=0.1, elbow=20))
LAND["ease"] = "quart_out"
PLUS_ULTRA = merge(proud(10, 18), aim_arm("Right", up=1.0, out=0.15, elbow=4))
PLUS_ULTRA["ease"] = "back_out"

SPECIAL = clip("Special", 4.4, {
    0.0: PROUD,
    0.4: CROUCH,
    0.7: LEAP,
    1.3: APEX,
    1.6: SMASH,
    1.78: LAND,
    2.45: add(LAND, {"RootOffset": (0, -0.03, 0)}),
    3.1: PLUS_ULTRA,
    3.75: add(PLUS_ULTRA, {"Neck": (2, 0, 0)}),
    4.4: PROUD,
}, loop=False, effects=[
    charge("RightHand", 0.7, 1.6, color=(255, 226, 110), size=1.1),
    burst("RightHand", 1.62, color=(255, 214, 80), count=60, speed=28),
    burst("RightHand", 1.8, color=(255, 240, 200), count=40, speed=18),
    burst("RightHand", 3.12, color=(255, 226, 110), count=20, speed=12),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 1.6}
CAMERAS = {"Special": "wide"}
