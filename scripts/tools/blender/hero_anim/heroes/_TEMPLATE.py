# TEMPLATE - copy to heroes/<HeroId>.py (HeroId = the AssetModels name, e.g. Goku, IronMan, Hulk) and edit.
# Files starting with "_" are skipped by run.py. Build, preview and verify one hero (from the repo root):
#   "C:/Program Files/Blender Foundation/Blender 4.5/blender.exe" --background --factory-startup \
#       --python scripts/tools/blender/hero_anim/run.py -- --heroes <HeroId> [--no-video]
# then LOOK at assets/animations/preview/<HeroId>_sheet.png (and <HeroId>.mp4) and iterate.
# Axes (details in ../api.py): +X = the hero's right, +Y = up, -Z = forward. Joint values are (x, y, z) degrees:
#   X = pitch (shoulder/hip +X swings the limb FORWARD, knee -X bends, elbow +X bends, Root/Waist +X leans BACK),
#   Y = yaw / twist (+Y turns to the hero's left), Z = roll (RightShoulder +Z raises the arm sideways, LeftShoulder -Z).
from hero_anim.api import *  # noqa: F401,F403

HERO = "MyHero"
SPECIAL_EVERY = (10, 18)  # seconds of idling between two Specials

# preview mannequin colours (previews only; the game uses the real hero model)
COLORS = palette(Head=(245, 205, 160), Torso=(40, 60, 160), Arms=(40, 60, 160), Hands=(240, 240, 240),
                 Legs=(30, 30, 40), Feet=(20, 20, 20))
EXTRAS = []  # e.g. extra("Head", "spikes", size=(0.8, 1.2, 0.8), offset=(0, 0.4, 0.1), color=(20, 20, 20))

# ---- Idle (REQUIRED, loops): a character pose + breathing ---------------------------------------------------
BASE = merge({"Neck": (6, 0, 0)}, fists_on_hips())          # hero stance; try arms_crossed(), guard(), crouch(...)
IDLE = clip("Idle", 3.0, breathe(BASE, amount=1.0, length=3.0))

# ---- Move (REQUIRED, loops): locomotion that matches the hero ----------------------------------------------
# walk_cycle / run_cycle / stomp_cycle / hop_cycle return {time: pose} keys; flyers use fly_saiyan / fly_superman /
# hover_pose; spider heroes swing (see PeterParker.py). speed="auto" for any stepping gait
# (the legs get foot-locked and the measured ground speed is exported: no skating in the pen; gait.py / gaitstrip.py check it).
MOVE = clip("Move", 0.9, walk_cycle(length=0.9), speed="auto")

# ---- Special (optional, one-shot): the signature emote --------------------------------------------------------
POWER = power_up()
SPECIAL = clip("Special", 2.0, {
    0.0: BASE,
    0.4: merge(POWER, {"ease": "back_out"}),
    1.5: add(POWER, {"Waist": (4, 0, 0)}),
    2.0: BASE,
}, loop=False, effects=[accent(boost=2.5, t0=0.3, t1=1.6)])

CLIPS = [IDLE, MOVE, SPECIAL]
