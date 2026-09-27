# Vegeta (Dragon Ball, Legendary) - HeroMotion style "float" + blue Aura.
#   Idle     Saiyan pride: arms crossed, chin up, feet planted wide, slow proud breathing and a weight shift
#   Move     Saiyan flight: body tilted forward, fists pulled back along the body, legs trailing (one knee bent)
#   Special  Final Flash: arms thrown wide charging both palms, then slammed together in front and fired
from hero_anim.api import *  # noqa: F401,F403

HERO = "Vegeta"
SPECIAL_EVERY = (9, 16)

SUIT = (38, 58, 158)
ARMOR = (238, 238, 244)
GOLD = (236, 190, 60)
SKIN = (246, 204, 164)
COLORS = palette(Torso=SUIT, UpperTorso=ARMOR, Arms=SUIT, Hands=ARMOR, Legs=SUIT, Feet=ARMOR, Head=SKIN)
EXTRAS = [
    # flame hair with the widow's peak
    extra("Head", "spikes", size=(0.75, 1.55, 0.8), offset=(0, 0.35, 0.12), rot=(-8, 0, 0), color=(22, 22, 30)),
    extra("Head", "box", size=(1.25, 0.28, 1.2), offset=(0, 0.52, 0.05), color=(22, 22, 30)),
    # armour shoulder straps / belly band
    extra("UpperTorso", "box", size=(2.08, 0.22, 1.08), offset=(0, -0.72, 0), color=GOLD),
]

# ------------------------------------------------------------------------------------------------ Idle
STANCE = plant_feet({"Waist": (4, 0, 0), "Neck": (9, 0, 0)},
                    feet={"Left": (-0.72, 0.252, 0.05), "Right": (0.72, 0.252, -0.05)})
PROUD = merge(STANCE, arms_crossed())
PROUD_IN = add(PROUD, {"Waist": (3, 0, 0), "Neck": (-2, 0, 0)})
SHIFT = plant_feet(merge(PROUD, {"Root": (0, 4, 2), "RootOffset": (0.08, -0.03, 0)}),
                   feet={"Left": (-0.72, 0.252, 0.05), "Right": (0.72, 0.252, -0.05)})
SHIFT = merge(SHIFT, arms_crossed(), {"Neck": (11, -12, 0), "Waist": (5, -4, 0)})

IDLE = clip("Idle", 4.0, {
    0.0: PROUD,
    1.2: PROUD_IN,
    2.2: SHIFT,
    3.2: merge(PROUD_IN, {"Neck": (10, 6, 0)}),
})

# ------------------------------------------------------------------------------------------------ Move
FLY = fly_saiyan(lead=None, tilt=52)
FLY_B = add(FLY, {"Root": (4, 0, 0), "RightHip": (-6, 0, 0), "LeftHip": (8, 0, 0), "LeftKnee": (-10, 0, 0),
                  "RightShoulder": (-6, 0, 0), "LeftShoulder": (-6, 0, 0), "RootOffset": (0, 0.12, 0)})
MOVE = clip("Move", 1.1, {
    0.0: FLY,
    0.55: FLY_B,
}, motion=motion(lift=1.0, lean=0.6), footsteps=False)

# ------------------------------------------------------------------------------------------------ Special: Final Flash
WIDE = crouch(drop=0.25, width=0.45, lean=-6, knee_out=0.6)
WIDE.update({"Waist": (10, 0, 0), "Neck": (16, 0, 0)})
WIDE.update(aim_arm("Right", out=1.0, back=0.25, up=0.15, twist=-80, wrist=(-50, 0, 0)))
WIDE.update(aim_arm("Left", out=1.0, back=0.25, up=0.15, twist=80, wrist=(-50, 0, 0)))
WIDE_TENSE = add(WIDE, {"Waist": (4, 0, 0), "RightShoulder": (-8, 0, 0), "LeftShoulder": (-8, 0, 0), "RootOffset": (0, -0.08, 0)})
FIRE = crouch(drop=0.35, width=0.5, lean=4, knee_out=0.6)
FIRE.update({"Waist": (-6, 0, 0), "Neck": (4, 0, 0)})
FIRE.update(thrust_palms())
FIRE["ease"] = "quart_out"
RECOIL = add(FIRE, {"Root": (6, 0, 0), "RootOffset": (0, 0, 0.25), "Waist": (4, 0, 0)})

SPECIAL = clip("Special", 3.6, {
    0.0: PROUD,
    0.45: merge(WIDE, {"ease": "back_out"}),
    1.7: WIDE_TENSE,
    2.0: FIRE,
    2.35: RECOIL,
    2.95: FIRE,
    3.6: PROUD,
}, loop=False, effects=[
    charge("Both", 0.4, 1.95, color=(255, 226, 90), size=0.9),
    charge("Both", 2.0, 2.95, color=(255, 250, 200), size=1.6),
    burst("Both", 2.02, color=(255, 240, 140), count=40, speed=18),
    accent(boost=3.0, t0=0.3, t1=3.0),
])

CLIPS = [IDLE, MOVE, SPECIAL]
THUMB_TIMES = {"Idle": 0.0, "Move": 0.0, "Special": 2.35}
CAMERAS = {"Move": "side"}
