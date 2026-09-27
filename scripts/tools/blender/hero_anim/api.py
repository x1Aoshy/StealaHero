# scripts/tools/blender/hero_anim/api.py
# Clip authoring API for the pen hero animations (ANIMCORE). Pure Python (no bpy): a hero module imports it, the
# Blender runner (run.py) turns the clips into Blender actions on the "HeroRig" armature, renders previews and exports
# src/ReplicatedStorage/Directory/HeroAnimations/<HeroId>.luau, which the game plays with HeroClipPlayer.
#
# ==================================================================================================================
# CLIP CONTRACT (what every hero module must define)
# ==================================================================================================================
#   HERO   = "Vegeta"                      the AssetModels / HeroId name (file heroes/<HeroId>.py)
#   CLIPS  = [clip("Idle", ...), clip("Move", ...), clip("Special", ...)]
#   COLORS = palette(...)                  preview mannequin colours (optional, previews only)
#   EXTRAS = [extra(...), ...]             preview-only props (hair spikes, eyes...) (optional)
#   SPECIAL_EVERY = (10, 18)               seconds of idling between two Specials (optional, default (10, 20))
#
#   Idle     REQUIRED, loop. The signature idle: a character pose + breathing (1.5-4 s loop).
#   Move     REQUIRED, loop. Locomotion while the hero wanders: Saiyan flying pose for flyers, web-swing arc for spider
#            heroes, sprint for speedsters, heavy stomp, hop... Replaces the Roblox walk cycle.
#   Special  optional, NOT looped. A short signature emote (1-4 s) played now and then while the hero idles
#            (Kamehameha charge, arms-crossed smirk, web-shoot...). Starts and ends near the Idle pose (it cross-fades).
#   Any other clip name is exported but not played by the runtime.
#
#   Runtime (HeroClipPlayer): Idle <-> Move cross-fade 0.25 s on the hero's movement, Special fades in 0.2 s / out
#   0.3 s. The HeroMotion style layer (hover / lean / bank / burst / hop / stomp dip) keeps moving the whole model on top
#   of the clips unless a clip's motion(...) scales it down (e.g. a web swing sets lift=0 so the bounce hop does not fight
#   the swing arc). Clips are authored for the block R15 template at visual scale 1 (5.0 studs tall, hip joint 2.0 above
#   the soles); the player scales RootOffset by the rendered rig's size.
#
# ==================================================================================================================
# AXES (read this before posing anything)
# ==================================================================================================================
#   Rig space: +X = the hero's RIGHT, +Y = UP, +Z = BACK (the hero faces -Z, Roblox LookVector). Blender: the runner
#   maps Roblox (x, y, z) -> Blender (-x, z, y) so the hero faces Blender -Y (Front view) with its left side on +X,
#   which is Blender's usual character convention (bones named like the Roblox Motor6Ds).
#
#   A joint value is (x, y, z) DEGREES = CFrame.Angles(rad(x), rad(y), rad(z)) applied at the joint (Motor6D.Transform,
#   rotation order X then Y then Z composed as Rx*Ry*Rz). Every template joint frame is axis-aligned with the rig at
#   rest, so the axes below are the rig axes of the PARENT part (torso axes for shoulders/hips, upper-limb axes for
#   elbows/knees...). Right-hand rule; the table says what a POSITIVE angle does from the rest pose:
#
#   joint            +X (pitch)                     +Y (yaw / twist)                +Z (roll)
#   Root             whole body leans BACK          body turns to its LEFT          body tilts to its LEFT
#                    (-X = lean/dive forward; the pivot is the hip centre 2.0 studs up)
#   Waist            upper body leans back          upper body turns left           upper body tilts left
#   Neck             look UP (-X nods down)         look to its left                head tilts to its left
#   RightShoulder    arm swings FORWARD/up          arm twists (palm turns in)      arm raises SIDEWAYS (out)
#                    (90 = arm straight ahead, 180 = straight up, -40 = arm back)   (90 = T-pose)
#   LeftShoulder     arm swings FORWARD/up          arm twists                      arm moves INWARD (use -Z to raise:
#                                                                                   -90 = T-pose)
#   Right/LeftElbow  forearm bends FORWARD/up (+X = flex; 0..150)                  (keep Y/Z ~0: it is a hinge)
#   Right/LeftWrist  hand flexes forward            hand twists                     hand bends sideways
#   RightHip         leg swings FORWARD (kick)      leg twists (toes in)            leg swings OUT (sideways)
#   LeftHip          leg swings FORWARD             leg twists                      leg swings IN (-Z = out)
#   Right/LeftKnee   -X BENDS the knee (shin goes back; 0..-150)                   (hinge)
#   Right/LeftAnkle  toes up (-X = toes point down)
#
#   Rule of thumb for sides: X means the same on both sides; Y and Z flip sign between Left and Right
#   (mirror() does it for you). Examples:
#       {"RightShoulder": (180, 0, 0)}            right arm straight up (through the front)
#       {"RightShoulder": (0, 0, 90), "LeftShoulder": (0, 0, -90)}   T-pose
#       {"RightShoulder": (90, 0, 0), "RightElbow": (0, 0, 0)}       right arm points straight ahead (punch)
#       {"Root": (-80, 0, 0), "RootOffset": (0, 1, 0)}               body horizontal, face down (flying), 1 stud up
#       {"RightHip": (70, 0, 0), "RightKnee": (-90, 0, 0)}          right knee raised
#   "RootOffset": (x, y, z) STUDS moves the whole body (Root joint translation, rig axes: y up, -z forward).
#   The rest pose has the arms hanging down along the body, legs straight, feet flat.
#
# ==================================================================================================================
# KEYS AND EASING
# ==================================================================================================================
#   clip(name, length, keys={time: pose, ...}, loop=..., ease="sine_inout", effects=[...], motion=motion(...),
#        speed=None, footsteps=True)
#   pose = {"Neck": (x, y, z), ..., "RootOffset": (x, y, z), "ease": "back_out"}  (a key's "ease" shapes the segment
#          from this key to the next one, for every joint of the key; a single joint can override it with
#          {"RightShoulder": key((170, 0, 10), "quad_out")}).
#   Keys are FULL poses (default): a joint used anywhere in the clip but missing from a key is at REST in that key
#   (build keys with merge()/add() from a base pose). clip(..., sparse=True) switches to per-joint tracks: a joint
#   missing from a key is interpolated between the keys that do name it (Root rotation and RootOffset share one
#   track: a sparse key naming only one of them gets the other interpolated from its neighbours). A joint named in no
#   key stays at rest.
#   Loops: the value at `length` is the value at the joint's first key (seamless) - so do NOT put a key at t = length
#   in a looping clip unless it repeats the t = 0 pose (run.py rejects it: the loop would pop at the wrap); a track
#   whose first key is after 0 holds that value from 0.
#   Easings: linear, constant, <family>_in / _out / _inout for sine, quad, cubic, quart, quint, circ, back, bounce
#   (Blender's curves: the game evaluates them identically). Aliases: smooth/ease/sine = sine_inout, back = back_out,
#   bounce = bounce_out, snap = quart_out, hold = constant.
#   speed=<studs/s>: Move plays at 1x when the hero walks that fast (scaled with the speed; None = fixed rate).
#   speed="auto" (ANIMPOLISH, use it for every stepping gait): footlock.py rebuilds the legs so the planted feet slide
#   back at one constant ground speed, flat on the floor, and that measured speed is exported as Speed. The player
#   plays Move at rate = ground speed / (Speed * rig scale) (clamped 0.45x..2.4x) and caps the hero's wander speed so
#   the feet never skate. footsteps=False: no footstep sound while this clip is the Move (flyers, swingers).
#   HeroMotion interplay (src/ReplicatedStorage/Directory/HeroMotion.luau style of the hero, still applied to the root):
#   float = hovers 1.2 studs + bob + 14 deg lean while moving (do not add a big RootOffset y; motion(lean=0.6) if the
#   clip already tilts); bounce = hops while moving (motion(lift=0) when the clip owns the height, e.g. swings);
#   stomp = a dip per footfall (stomp_cycle already drops: motion(lift=0.5)); dash = bursts + lean 16 deg.
#
# ==================================================================================================================
# EFFECTS (runtime visuals bound to a clip; times in seconds of that clip; None = whole clip)
# ==================================================================================================================
#   web(hand="RightHand", anchor=(0, 11, -3), t0, t1)   a white Beam from the hand to a point in rig space (anchor
#                                                         above/ahead of the hero) - the spider swing / web shot
#   charge(hand="Both", t0, t1, color, size)            glowing energy + light on the hand(s): Kamehameha / Final Flash
#   burst(hand="Both", t, color, count)                  one-shot spark burst at time t (the release)
#   accent(boost, t0, t1)                                pumps the hero's HeroMotion accent (Aura / Sparks / Thrusters /
#                                                         Glitter / Feathers) by `boost` x while active (power-up)
#   motion(lift=1, lean=1)                               how much of the HeroMotion hover/hop/dip (lift) and lean/bank/
#                                                         sway (lean) stays on while the clip plays (weights blend)
#
# ==================================================================================================================
# POSE HELPERS (all return pose dicts; combine with merge(a, b, ...), later wins)
# ==================================================================================================================
#   rest(), tpose(), mirror(p), merge(*ps), add(a, b), scale(p, f), blend(a, b, t)
#   aim_arm(side, forward=, up=, out=, twist=, elbow=)   point the upper arm along a direction (torso axes)
#   aim_leg(side, forward=, down=, out=, twist=, knee=)  point the thigh along a direction (hip axes)
#   reach(pose, side, target, elbow_hint)                IK: put the hand centre at a rig-space point
#   aim_arm_at(pose, side, point)                        IK: straight arm pointing at a rig-space point (web anchor)
#   plant_feet(pose, feet=None, knee_hint)               IK: keep both feet flat on their ground spots (crouches)
#   crouch(drop, width, lean)                            squat with planted feet (hips drop `drop` studs)
#   fist_forward(side), fists_on_hips(), arms_crossed(), guard(), point(side), wave(side, t)
#   fly_saiyan(lead=None), fly_superman(side), hover_pose()
#   web_swing(side, phase), web_shoot(side), spider_crouch()
#   charge_hands(side), thrust_palms(), power_up()
#   walk_cycle(length, ...), run_cycle(length, ...), stomp_cycle(length, ...), hop_cycle(length, ...)  -> keys dicts
#   breathe(base, amount)                                -> 3 keys that breathe around a base pose (loop helper)
#
# Validate + preview: run.py (see its header) renders assets/animations/preview/<HeroId>_sheet.png and <HeroId>.mp4,
# exports the Luau module and runs scripts/tools/verify_hero_anims.luau (round trip < 0.01 studs).

import json
import math
import os
import sys

from . import rbx

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.normpath(os.path.join(HERE, "..", "..", "..", ".."))
RIG_JSON = os.path.join(REPO_ROOT, "assets", "animations", "r15_rig.json")

JOINTS = [
    "Root", "Waist", "Neck",
    "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow", "RightWrist",
    "LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle",
]
ROOT_OFFSET = "RootOffset"
CLIP_NAMES = ("Idle", "Move", "Special")
REQUIRED_CLIPS = ("Idle", "Move")
HANDS = ("LeftHand", "RightHand", "Both")
LEFT_RIGHT = {"Left": "Right", "Right": "Left"}

# ------------------------------------------------------------------------------------------------ rig


class Rig:
    """The template rig (assets/animations/r15_rig.json) with FK."""

    def __init__(self, path=RIG_JSON):
        with open(path, "r", encoding="utf-8") as handle:
            data = json.load(handle)
        self.data = data
        self.height = data["height"]
        self.hip_height = data["hipHeight"]
        self.hrp_height = data["hrpHeight"]
        self.parts = {}
        for name, part in data["parts"].items():
            self.parts[name] = {"size": tuple(part["size"]), "cframe": rbx.cf_from_components(part["cframe"]), "shape": part["shape"]}
        self.joints = []
        self.joint = {}
        for j in data["joints"]:
            entry = {
                "name": j["name"], "part0": j["part0"], "part1": j["part1"],
                "c0": rbx.cf_from_components(j["c0"]), "c1": rbx.cf_from_components(j["c1"]),
            }
            self.joints.append(entry)
            self.joint[j["name"]] = entry
        self.joint_of_part = {j["part1"]: j["name"] for j in self.joints}
        self.parent_joint = {}
        for j in self.joints:
            self.parent_joint[j["name"]] = self.joint_of_part.get(j["part0"])
        assert [j["name"] for j in self.joints] == JOINTS, "r15_rig.json joint order changed"

    def hrp(self):
        return rbx.cf((0.0, self.hrp_height, 0.0))

    def fk(self, transforms):
        """transforms: joint -> (R, p) Motor6D.Transform. Returns (part frames, joint frames) in rig space."""
        parts = {"HumanoidRootPart": self.hrp()}
        joints = {}
        for j in self.joints:
            t = transforms.get(j["name"], rbx.cf())
            jf = rbx.cf_mul(rbx.cf_mul(parts[j["part0"]], j["c0"]), t)
            joints[j["name"]] = jf
            parts[j["part1"]] = rbx.cf_mul(jf, rbx.cf_inv(j["c1"]))
        return parts, joints

    def child_joint(self, joint):
        part1 = self.joint[joint]["part1"]
        for j in self.joints:
            if j["part0"] == part1:
                return j["name"]
        return None


_RIG = None


def rig():
    global _RIG
    if _RIG is None:
        _RIG = Rig()
    return _RIG


# ------------------------------------------------------------------------------------------------ pose values


class Key:
    """A joint value with its own easing: {"RightShoulder": key((170, 0, 10), "quad_out")}."""

    def __init__(self, value, ease):
        self.value = value
        self.ease = rbx.canonical_easing(ease)

    def __repr__(self):
        return "key(%r, %r)" % (self.value, self.ease)


def key(value, ease):
    return Key(value, ease)


def _unwrap(value):
    return value.value if isinstance(value, Key) else value


def _rewrap(original, value):
    return Key(value, original.ease) if isinstance(original, Key) else value


def _check_triplet(name, value):
    if not (isinstance(value, (tuple, list)) and len(value) == 3 and all(isinstance(v, (int, float)) for v in value)):
        raise ValueError("%s must be (x, y, z) numbers, got %r" % (name, value))
    return (float(value[0]), float(value[1]), float(value[2]))


def rot_matrix(value):
    x, y, z = _check_triplet("rotation", _unwrap(value))
    return rbx.euler_xyz(x, y, z)


def _euler(m):
    return tuple(round(v, 3) + 0.0 for v in rbx.to_euler_xyz(m))


def transforms_of(pose):
    """pose dict -> joint -> (R, p) Transform (RootOffset goes into Root's translation)."""
    out = {}
    for name in JOINTS:
        if name in pose:
            out[name] = (rot_matrix(pose[name]), (0.0, 0.0, 0.0))
    if ROOT_OFFSET in pose:
        r = out.get("Root", rbx.cf())[0]
        out["Root"] = (r, _check_triplet(ROOT_OFFSET, _unwrap(pose[ROOT_OFFSET])))
    return out


def rest():
    return {}


def merge(*poses):
    out = {}
    for p in poses:
        if p:
            out.update(p)
    return out


def _mirror_name(name):
    for a, b in (("Left", "Right"), ("Right", "Left")):
        if name.startswith(a):
            return b + name[len(a):]
    return name


def mirror(pose):
    """Left <-> Right: joint names swap, (x, y, z) -> (x, -y, -z); RootOffset x -> -x."""
    out = {}
    for name, value in pose.items():
        if name == "ease":
            out[name] = value
            continue
        v = _unwrap(value)
        if name == ROOT_OFFSET:
            out[name] = _rewrap(value, (-v[0], v[1], v[2]))
        else:
            out[_mirror_name(name)] = _rewrap(value, (v[0], -v[1] + 0.0, -v[2] + 0.0))
    return out


def add(a, b):
    """b applied on top of a (joint frame): rotations compose (a then b), offsets add."""
    out = dict(a)
    for name, value in b.items():
        if name == "ease":
            out[name] = value
        elif name == ROOT_OFFSET:
            base = _unwrap(a.get(name, (0, 0, 0)))
            v = _unwrap(value)
            out[name] = _rewrap(value, (base[0] + v[0], base[1] + v[1], base[2] + v[2]))
        elif name in a:
            out[name] = _rewrap(value, _euler(rbx.m_mul(rot_matrix(a[name]), rot_matrix(value))))
        else:
            out[name] = value
    return out


def scale(pose, f):
    """Scales every angle and offset by f (approximate 'intensity' knob)."""
    out = {}
    for name, value in pose.items():
        if name == "ease":
            out[name] = value
            continue
        v = _unwrap(value)
        out[name] = _rewrap(value, (v[0] * f, v[1] * f, v[2] * f))
    return out


def blend(a, b, t):
    """Pose between a (t=0) and b (t=1): quaternion nlerp per joint, offsets lerp."""
    out = {}
    names = set(a) | set(b)
    for name in names:
        if name == "ease":
            continue
        if name == ROOT_OFFSET:
            va, vb = _unwrap(a.get(name, (0, 0, 0))), _unwrap(b.get(name, (0, 0, 0)))
            out[name] = tuple(round(va[i] + (vb[i] - va[i]) * t, 4) for i in range(3))
            continue
        qa = rbx.quat_from_matrix(rot_matrix(a.get(name, (0, 0, 0))))
        qb = rbx.quat_from_matrix(rot_matrix(b.get(name, (0, 0, 0))))
        out[name] = _euler(rbx.quat_to_matrix(rbx.nlerp(qa, qb, t)))
    return out


def tpose():
    return {"RightShoulder": (0, 0, 90), "LeftShoulder": (0, 0, -90)}


# ------------------------------------------------------------------------------------------------ direction helpers


def _side(side):
    side = side.capitalize()
    if side not in LEFT_RIGHT:
        raise ValueError("side must be 'Left' or 'Right', got %r" % side)
    return side


def direction(side, forward=0.0, up=0.0, out=0.0, down=0.0, back=0.0, inward=0.0):
    """Rig-space direction from friendly components (out = away from the body on that side)."""
    sx = 1.0 if _side(side) == "Right" else -1.0
    v = (sx * (out - inward), up - down, back - forward)
    if rbx.v_len(v) < 1e-9:
        raise ValueError("direction needs a non-zero component")
    return rbx.v_norm(v)


def _aim(rest_dir, target_dir, twist):
    if rbx.v_dot(rbx.v_norm(rest_dir), rbx.v_norm(target_dir)) < -0.9999:
        r = rbx.axis_angle((1.0, 0.0, 0.0), 180.0)  # straight up goes through the front
    else:
        r = rbx.rotation_between(rest_dir, target_dir)
    if twist:
        r = rbx.m_mul(r, rbx.rot_y(twist))
    return r


def aim_arm(side, forward=0.0, up=0.0, out=0.0, down=0.0, back=0.0, inward=0.0, twist=0.0, elbow=0.0, wrist=None):
    """Upper arm pointing along a direction in TORSO axes (same as rig axes when the torso is upright).
    aim_arm("Right", forward=1) = arm straight ahead; aim_arm("Left", up=1) = arm straight up; elbow = flex degrees."""
    side = _side(side)
    d = direction(side, forward, up, out, down, back, inward)
    pose = {side + "Shoulder": _euler(_aim((0.0, -1.0, 0.0), d, twist)), side + "Elbow": (float(elbow), 0.0, 0.0)}
    if wrist is not None:
        pose[side + "Wrist"] = _check_triplet("wrist", wrist)
    return pose


def aim_leg(side, forward=0.0, down=1.0, out=0.0, up=0.0, back=0.0, inward=0.0, twist=0.0, knee=0.0, ankle=None):
    """Thigh pointing along a direction in HIP axes; knee = bend degrees (positive number bends)."""
    side = _side(side)
    d = direction(side, forward, up, out, down, back, inward)
    pose = {side + "Hip": _euler(_aim((0.0, -1.0, 0.0), d, twist)), side + "Knee": (-abs(float(knee)), 0.0, 0.0)}
    if ankle is not None:
        pose[side + "Ankle"] = _check_triplet("ankle", ankle)
    return pose


# ------------------------------------------------------------------------------------------------ IK


def _solve_two_bone(v1, v2, hinge_sign, target, hint, bend_local):
    """Chain pivot -> R*(v1 + Rx(hinge_sign*phi)*v2) == target (all in the joint's parent frame, pivot at origin).
    The swivel about the pivot->target axis turns the limb's local `bend_local` direction (where the elbow / knee
    points) toward `hint`, which stays well defined when the limb is straight. Returns (R, phi_degrees)."""
    d = rbx.v_len(target)

    def reach_len(phi):
        return rbx.v_len(rbx.v_add(v1, rbx.m_vec(rbx.rot_x(hinge_sign * phi), v2)))

    lo, hi = 0.0, 175.0
    if d >= reach_len(0.0):
        phi = 0.0
    elif d <= reach_len(hi):
        phi = hi
    else:
        for _ in range(60):
            mid = (lo + hi) * 0.5
            if reach_len(mid) > d:
                lo = mid
            else:
                hi = mid
        phi = (lo + hi) * 0.5
    local_end = rbx.v_add(v1, rbx.m_vec(rbx.rot_x(hinge_sign * phi), v2))
    r0 = rbx.rotation_between(local_end, target)
    axis = rbx.v_norm(target)
    bend = rbx.m_vec(r0, bend_local)
    bend_perp = rbx.v_sub(bend, rbx.v_scale(axis, rbx.v_dot(bend, axis)))
    hint_perp = rbx.v_sub(hint, rbx.v_scale(axis, rbx.v_dot(hint, axis)))
    if rbx.v_len(bend_perp) > 1e-6 and rbx.v_len(hint_perp) > 1e-6:
        a, b = rbx.v_norm(bend_perp), rbx.v_norm(hint_perp)
        ang = math.degrees(math.atan2(rbx.v_dot(rbx.v_cross(a, b), axis), rbx.v_dot(a, b)))
        r0 = rbx.m_mul(rbx.axis_angle(axis, ang), r0)
    return r0, phi


def _chain_vectors(side, limb):
    r = rig()
    if limb == "arm":
        j1, j2 = r.joint[side + "Shoulder"], r.joint[side + "Elbow"]
        j3 = r.joint[side + "Wrist"]
        v1 = rbx.v_sub(j2["c0"][1], j1["c1"][1])
        # elbow -> hand centre (wrist straight): lower arm (elbow C1 -> wrist C0) + wrist C1 -> hand centre
        v2 = rbx.v_add(rbx.v_sub(j3["c0"][1], j2["c1"][1]), rbx.v_scale(j3["c1"][1], -1.0))
        return j1, v1, v2, 1.0
    j1, j2 = r.joint[side + "Hip"], r.joint[side + "Knee"]
    j3 = r.joint[side + "Ankle"]
    v1 = rbx.v_sub(j2["c0"][1], j1["c1"][1])
    v2 = rbx.v_sub(j3["c0"][1], j2["c1"][1])  # knee -> ankle joint
    return j1, v1, v2, -1.0


def reach(pose, side, target, elbow_hint=None, wrist=None):
    """IK: the hand centre of `side` goes to `target` (rig space, studs; the ground is y = 0). The rest of `pose`
    (Root / Waist...) is honoured. elbow_hint = rig-space direction the elbow should point (default out / down / back)."""
    side = _side(side)
    r = rig()
    base = transforms_of(pose)
    parts, _ = r.fk(base)
    j1, v1, v2, sign = _chain_vectors(side, "arm")
    parent = rbx.cf_mul(parts[j1["part0"]], j1["c0"])  # shoulder joint frame with no shoulder rotation
    rt = rbx.m_transpose(parent[0])
    local_target = rbx.m_vec(rt, rbx.v_sub(tuple(target), parent[1]))
    sx = 1.0 if side == "Right" else -1.0
    hint = elbow_hint if elbow_hint is not None else (sx * 1.0, -0.6, 0.4)
    local_hint = rbx.m_vec(rt, rbx.v_norm(hint))
    rot, phi = _solve_two_bone(v1, v2, sign, local_target, local_hint, (0.0, 0.0, 1.0))  # elbow points back
    out = dict(pose)
    out[side + "Shoulder"] = _euler(rot)
    out[side + "Elbow"] = (round(phi, 3), 0.0, 0.0)
    out[side + "Wrist"] = _check_triplet("wrist", wrist) if wrist is not None else (0.0, 0.0, 0.0)
    return out


def shoulder_position(pose, side):
    """Rig-space position of the shoulder pivot of `side` for `pose` (Root / RootOffset / Waist honoured)."""
    r = rig()
    parts, _ = r.fk(transforms_of(pose))
    j = r.joint[_side(side) + "Shoulder"]
    return rbx.cf_mul(parts[j["part0"]], j["c0"])[1]


def aim_arm_at(pose, side, point, reach_frac=0.97, elbow_hint=None, wrist=None):
    """IK: the (almost straight) arm of `side` points at a rig-space point - e.g. a web anchor high above. Honours the
    rest of `pose` (a tilted Root / Waist), so the arm keeps pointing at the same spot while the body swings."""
    side = _side(side)
    s = shoulder_position(pose, side)
    d = rbx.v_norm(rbx.v_sub(tuple(point), s))
    j1, v1, v2, _ = _chain_vectors(side, "arm")
    length = rbx.v_len(rbx.v_add(v1, v2)) * reach_frac
    return reach(pose, side, rbx.v_add(s, rbx.v_scale(d, length)), elbow_hint=elbow_hint, wrist=wrist)


def rest_foot(side):
    """Rest ankle-joint position of a foot in rig space."""
    _, joints = rig().fk({})
    return joints[_side(side) + "Ankle"][1]


def plant_feet(pose, feet=None, knee_hint=(0.0, 0.0, -1.0), foot_yaw=None):
    """IK: legs reach the ankle spots `feet` = {"Left": (x, y, z), "Right": ...} (rig space, default the rest spots)
    with each foot flat on the ground (only turned by foot_yaw = {"Left": deg} about Y). Honours Root/RootOffset."""
    r = rig()
    out = dict(pose)
    for side in ("Left", "Right"):
        target = (feet or {}).get(side) or rest_foot(side)
        base = transforms_of(out)
        parts, _ = r.fk(base)
        j1, v1, v2, sign = _chain_vectors(side, "leg")
        parent = rbx.cf_mul(parts[j1["part0"]], j1["c0"])
        rt = rbx.m_transpose(parent[0])
        local_target = rbx.m_vec(rt, rbx.v_sub(tuple(target), parent[1]))
        sx = 1.0 if side == "Right" else -1.0
        hint = knee_hint if knee_hint is not None else (0.0, 0.0, -1.0)
        hint = (hint[0] * sx, hint[1], hint[2])
        local_hint = rbx.m_vec(rt, rbx.v_norm(hint))
        rot, phi = _solve_two_bone(v1, v2, sign, local_target, local_hint, (0.0, 0.0, -1.0))  # knee points forward
        out[side + "Hip"] = _euler(rot)
        out[side + "Knee"] = (round(-phi, 3), 0.0, 0.0)
        # flat foot: world foot rotation = yaw only
        yaw = (foot_yaw or {}).get(side, 0.0)
        chain = rbx.m_mul(rbx.m_mul(parent[0], rot), rbx.rot_x(-phi))
        out[side + "Ankle"] = _euler(rbx.m_mul(rbx.m_transpose(chain), rbx.rot_y(yaw)))
    return out


# ------------------------------------------------------------------------------------------------ ready-made poses


def crouch(drop=0.6, width=0.0, lean=12.0, forward=0.0, knee_out=0.35):
    """Squat: hips drop `drop` studs, feet stay planted `width` studs wider than rest on each side, torso leans
    forward `lean` degrees (Root). forward = hips shift (studs, + = forward)."""
    base = {"Root": (-lean, 0, 0), ROOT_OFFSET: (0.0, -drop, -forward)}
    feet = {}
    for side in ("Left", "Right"):
        p = rest_foot(side)
        sx = 1.0 if side == "Right" else -1.0
        feet[side] = (p[0] + sx * width, p[1], p[2])
    return plant_feet(base, feet, knee_hint=(knee_out, 0.0, -1.0))


def fists_on_hips():
    p = reach({}, "Right", (1.25, 2.2, -0.1), elbow_hint=(1, 0.2, 0.3))
    p = reach(p, "Left", (-1.25, 2.2, -0.1), elbow_hint=(-1, 0.2, 0.3))
    return {k: v for k, v in p.items() if "Shoulder" in k or "Elbow" in k or "Wrist" in k}


def arms_crossed():
    """Arms folded across the chest (block-rig version): elbows out and down, forearms stacked in front of the chest
    (right one low, left one high), fists meeting in the middle."""
    p = reach({}, "Right", (0.42, 2.84, -1.02), elbow_hint=(1.0, -1.0, 0.3), wrist=(0, 0, 12))
    p = reach(p, "Left", (-0.42, 3.22, -0.98), elbow_hint=(-1.0, -1.0, 0.3), wrist=(0, 0, -12))
    return {k: v for k, v in p.items() if "Shoulder" in k or "Elbow" in k or "Wrist" in k}


def guard():
    """Fighting guard: fists up in front of the face."""
    p = reach({}, "Right", (0.45, 3.9, -1.25), elbow_hint=(0.6, -1, 0.2))
    p = reach(p, "Left", (-0.5, 3.7, -1.45), elbow_hint=(-0.6, -1, 0.2))
    return {k: v for k, v in p.items() if "Shoulder" in k or "Elbow" in k or "Wrist" in k}


def fist_forward(side="Right", up=0.0):
    return aim_arm(side, forward=1.0, up=up)


def point(side="Right"):
    return aim_arm(side, forward=1.0, up=0.25, out=0.15, wrist=(-10, 0, 0))


def wave(side="Right", t=0.0):
    """Hand raised, waving: t in [0, 1] = the wave phase (side to side)."""
    swing = math.sin(t * 2 * math.pi) * 22
    s = 1 if _side(side) == "Right" else -1
    return {side + "Shoulder": (0, 0, s * (150 + swing * 0.3)), side + "Elbow": (25 + swing, 0, 0)}


def charge_hands(side="Right"):
    """Kamehameha charge: upper body wound back toward `side` (Root + Waist twist ~70 deg, head still facing forward),
    both hands cupped together at that hip. The blocky arms only meet with this much twist."""
    side = _side(side)
    s = 1.0 if side == "Right" else -1.0
    base = {"Root": (0, -s * 15, 0), "Waist": (0, -s * 55, 0), "Neck": (-5, s * 50, 0)}
    p = reach(base, side, (s * 0.95, 2.6, 0.3), elbow_hint=(s * 0.6, -0.5, 1.0), wrist=(0, 0, s * 30))
    p = reach(p, LEFT_RIGHT[side], (s * 0.8, 2.8, 0.1), elbow_hint=(-s * 0.3, -0.5, 1.0), wrist=(0, 0, -s * 30))
    return p


def thrust_palms():
    """Beam release: both arms straight ahead, palms together (Kamehameha / Final Flash fire)."""
    return merge(aim_arm("Right", forward=1.0, inward=0.28, up=0.05, wrist=(-60, 0, 0)),
                 aim_arm("Left", forward=1.0, inward=0.28, up=0.05, wrist=(-60, 0, 0)))


def power_up():
    """Fists clenched down at the sides, arms tense and a little out, chest up (powering up)."""
    return merge({"Waist": (8, 0, 0), "Neck": (12, 0, 0)},
                 aim_arm("Right", down=1.0, out=0.45, forward=0.15, elbow=30, twist=-30),
                 aim_arm("Left", down=1.0, out=0.45, forward=0.15, elbow=30, twist=30))


def fly_saiyan(lead=None, tilt=62.0):
    """Dragon Ball flight: body tilted `tilt` degrees forward, legs trailing (one knee bent).
    lead=None: both fists pulled back along the body (the classic dash); lead="Right": that fist punches ahead."""
    p = {"Root": (-tilt, 0, 0), ROOT_OFFSET: (0, 0.9, 0), "Neck": (tilt * 0.55, 0, 0), "Waist": (4, 0, 0)}
    p.update(aim_leg("Right", down=1.0, back=0.2, knee=8, ankle=(-35, 0, 0)))
    p.update(aim_leg("Left", down=1.0, forward=0.35, knee=62, ankle=(-40, 0, 0)))
    if lead is None:
        p.update(aim_arm("Right", down=1.0, back=0.6, out=0.38, elbow=14, twist=-20))
        p.update(aim_arm("Left", down=1.0, back=0.6, out=0.38, elbow=14, twist=20))
    else:
        lead = _side(lead)
        p.update(aim_arm(lead, up=1.0, forward=0.1, inward=0.1))
        p.update(aim_arm(LEFT_RIGHT[lead], down=1.0, back=0.45, out=0.25, elbow=18))
    return p


def fly_superman(side="Right"):
    """Superman flight: body horizontal, one fist straight ahead, the other arm along the body, legs straight."""
    side = _side(side)
    p = {"Root": (-84, 0, 0), ROOT_OFFSET: (0, 1.3, 0), "Neck": (55, 0, 0)}
    p.update(aim_arm(side, up=1.0))
    p.update(aim_arm(LEFT_RIGHT[side], down=1.0, back=0.15, out=0.1, elbow=8))
    p.update(aim_leg("Right", down=1.0, back=0.05, ankle=(-40, 0, 0)))
    p.update(aim_leg("Left", down=1.0, back=0.02, knee=12, ankle=(-40, 0, 0)))
    return p


def hover_pose():
    """Relaxed levitation: legs dangling (one knee bent), arms a little out."""
    return merge(aim_leg("Right", down=1.0, forward=0.1, knee=18, ankle=(-30, 0, 0)),
                 aim_leg("Left", down=1.0, back=0.1, knee=35, ankle=(-35, 0, 0)),
                 aim_arm("Right", down=1.0, out=0.3, elbow=15), aim_arm("Left", down=1.0, out=0.3, elbow=15))


def web_swing(side="Right", phase=0.5):
    """Web swing arm: `side` hand high above holding the web, the other arm out for balance, legs tucked.
    phase 0 = back of the arc, 0.5 = bottom, 1 = front (body swings under the web)."""
    side = _side(side)
    other = LEFT_RIGHT[side]
    s = 1.0 if side == "Right" else -1.0
    swing = (phase - 0.5) * 2.0  # -1 .. 1
    p = {"Root": (-8 + swing * 32, 0, -s * 6), "Neck": (18 - swing * 18, 0, 0)}
    p.update(aim_arm(side, up=1.0, forward=0.25 - swing * 0.2, inward=0.15, twist=0))
    p.update(aim_arm(other, out=1.0, down=0.3 + swing * 0.3, back=0.25, elbow=30))
    p.update(aim_leg("Right", down=1.0, forward=0.35 + swing * 0.45, knee=55 - swing * 25, ankle=(-30, 0, 0)))
    p.update(aim_leg("Left", down=1.0, forward=0.15 + swing * 0.45, knee=75 - swing * 20, ankle=(-30, 0, 0)))
    return p


def web_shoot(side="Right"):
    """Thwip: `side` arm snapped straight ahead, wrist cocked back (web-shooter), other hand low."""
    side = _side(side)
    p = aim_arm(side, forward=1.0, up=0.08, wrist=(62, 0, 0))
    p.update(aim_arm(LEFT_RIGHT[side], down=1.0, out=0.35, back=0.2, elbow=35))
    return p


def spider_crouch(drop=1.05, hand="Left", free="out"):
    """Low wide spider crouch: knees wide, torso over the knees, `hand` reaching down in front of the feet (the block
    arm is ~1.8 studs long: at the default drop the hand stops ~0.8 studs above the ground, it does not touch it;
    add a forward Waist lean, e.g. add(p, {"Waist": (-25, 0, 0)}) + re-reach, to get closer).
    free = what the other arm does: "out" (flung out and back, ready to pounce), "knee" (hand on its knee),
    "ground" (both hands down)."""
    p = crouch(drop=drop, width=0.55, lean=28.0, knee_out=1.2)
    p["Neck"] = (30, 0, 0)
    side = _side(hand)
    s = 1.0 if side == "Right" else -1.0
    p = reach(p, side, (s * 0.35, 0.15, -1.55), elbow_hint=(s * 1.0, 0.3, 0.2), wrist=(-30, 0, 0))
    other = LEFT_RIGHT[side]
    if free == "ground":
        p = reach(p, other, (-s * 0.35, 0.15, -1.45), elbow_hint=(-s * 1.0, 0.3, 0.2), wrist=(-30, 0, 0))
    elif free == "knee":
        p = reach(p, other, (-s * 1.15, 1.05, -1.05), elbow_hint=(-s * 1.0, 0.4, 0.3), wrist=(-20, 0, 0))
    else:
        p.update(aim_arm(other, out=1.0, back=0.55, up=0.25, elbow=45, twist=-s * 20))
    return p


def breathe(base, amount=1.0, length=3.0):
    """Keys for a breathing loop around `base`: chest rises (Waist back, shoulders lift), head counters."""
    inhale = add(base, {"Waist": (3.0 * amount, 0, 0), "Neck": (-2.0 * amount, 0, 0),
                        "RightShoulder": (0, 0, 2.0 * amount), "LeftShoulder": (0, 0, -2.0 * amount)})
    return {0.0: dict(base), length * 0.45: inhale, length: dict(base)}


# ------------------------------------------------------------------------------------------------ locomotion cycles


def _gait(length, stride, knee, arm, elbow, bounce, lean, lift_knee=0.0, drop=0.0, arm_out=0.08, twist=6.0):
    """4-pose biped cycle keys (contact R, passing, contact L, passing) for a loop of `length` seconds.
    Contact: one leg forward (heel), the other back, arms counter-swing. Passing: the support leg under the body, the
    swing leg passing with its knee bent, body up by `bounce`."""
    def side_z(side, v):
        return v if side == "Right" else -v

    def pose_at(sgn, passing):
        fwd, bwd = ("Right", "Left") if sgn > 0 else ("Left", "Right")
        if passing:
            # the leg that was forward now supports; the back leg swings through
            p = {"Root": (-lean, 0, 0), ROOT_OFFSET: (0, bounce - drop, 0), "Waist": (0, 0, 0)}
            p[fwd + "Hip"] = (-stride * 0.15, 0, 0)
            p[fwd + "Knee"] = (-knee * 0.2, 0, 0)
            p[fwd + "Ankle"] = (0, 0, 0)
            p[bwd + "Hip"] = (stride * 0.45 + lift_knee * 0.5, 0, 0)
            p[bwd + "Knee"] = (-(knee + lift_knee), 0, 0)
            p[bwd + "Ankle"] = (-10, 0, 0)
            for s in ("Right", "Left"):
                p[s + "Shoulder"] = (0, 0, side_z(s, arm_out * 40))
                p[s + "Elbow"] = (elbow, 0, 0)
            return p
        p = {"Root": (-lean, sgn * twist, 0), ROOT_OFFSET: (0, -drop, 0), "Waist": (0, -sgn * twist * 1.4, 0)}
        p[fwd + "Hip"] = (stride, 0, 0)
        p[fwd + "Knee"] = (-knee * 0.25, 0, 0)
        p[fwd + "Ankle"] = (10, 0, 0)
        p[bwd + "Hip"] = (-stride * 0.8, 0, 0)
        p[bwd + "Knee"] = (-knee * 0.55, 0, 0)
        p[bwd + "Ankle"] = (-15, 0, 0)
        # arms counter-swing: the arm on the back-leg side swings forward
        p[bwd + "Shoulder"] = (arm, 0, side_z(bwd, arm_out * 40))
        p[bwd + "Elbow"] = (elbow + arm * 0.35, 0, 0)
        p[fwd + "Shoulder"] = (-arm * 0.8, 0, side_z(fwd, arm_out * 40))
        p[fwd + "Elbow"] = (elbow, 0, 0)
        return p

    q = length / 4.0
    return {0.0: pose_at(1, False), q: pose_at(1, True), 2 * q: pose_at(-1, False), 3 * q: pose_at(-1, True)}


def walk_cycle(length=1.0, stride=28.0, knee=35.0, arm=22.0, bounce=0.08):
    """Plain walk loop keys (4 poses)."""
    return _gait(length, stride, knee, arm, 10.0, bounce, 3.0)


def run_cycle(length=0.55, stride=55.0, knee=85.0, arm=70.0, bounce=0.25, lean=18.0):
    """Sprint: big strides, high knees, pumping bent arms, torso leaning forward."""
    return _gait(length, stride, knee, arm, 80.0, bounce, lean, lift_knee=25.0, arm_out=0.05)


def stomp_cycle(length=1.3, stride=26.0, knee=40.0, arm=18.0, drop=0.25):
    """Heavy stomp: slow wide steps, hips low, arms out (Hulk / Venom); each contact slams down."""
    keys = _gait(length, stride, knee, arm, 25.0, 0.18, 6.0, drop=drop, arm_out=0.35, twist=10.0)
    for i, t in enumerate(sorted(keys)):
        keys[t]["ease"] = "quad_out" if i % 2 == 0 else "quad_in"  # rise slowly off a contact, slam into the next
    return keys


def hop_cycle(length=0.7, height=0.9, tuck=60.0):
    """Two-footed hop loop: crouch, spring up with tucked knees, land."""
    down = crouch(drop=0.45, lean=10)
    up = merge({ROOT_OFFSET: (0, height, 0), "Root": (-6, 0, 0)},
               aim_leg("Right", down=1.0, forward=0.3, knee=tuck), aim_leg("Left", down=1.0, forward=0.3, knee=tuck),
               aim_arm("Right", up=0.6, forward=0.6, out=0.4, elbow=20), aim_arm("Left", up=0.6, forward=0.6, out=0.4, elbow=20))
    down["ease"] = "quad_out"
    up["ease"] = "quad_in"
    return {0.0: down, length * 0.45: up}


# ------------------------------------------------------------------------------------------------ effects / motion


def _window(t0, t1):
    return {"From": t0, "To": t1}


def _color(c, name):
    if not (isinstance(c, (tuple, list)) and len(c) == 3 and all(0 <= v <= 255 for v in c)):
        raise ValueError("%s colour must be (r, g, b) 0-255, got %r" % (name, c))
    return [int(c[0]), int(c[1]), int(c[2])]


def web(hand="RightHand", anchor=(0.0, 11.0, -3.0), t0=None, t1=None, color=(236, 238, 245), width=0.12):
    if hand not in ("LeftHand", "RightHand"):
        raise ValueError("web hand must be LeftHand or RightHand")
    e = {"Type": "Web", "Hand": hand, "Anchor": list(_check_triplet("anchor", anchor)), "Color": _color(color, "web"), "Width": float(width)}
    e.update(_window(t0, t1))
    return e


def charge(hand="Both", t0=None, t1=None, color=(255, 214, 80), size=1.0, light=True):
    if hand not in HANDS:
        raise ValueError("charge hand must be one of %s" % (HANDS,))
    e = {"Type": "Charge", "Hand": hand, "Color": _color(color, "charge"), "Size": float(size), "Light": bool(light)}
    e.update(_window(t0, t1))
    return e


def burst(hand="Both", t=0.0, color=(255, 240, 150), count=30, speed=14.0):
    if hand not in HANDS:
        raise ValueError("burst hand must be one of %s" % (HANDS,))
    return {"Type": "Burst", "Hand": hand, "Time": float(t), "Color": _color(color, "burst"), "Count": int(count), "Speed": float(speed)}


def accent(boost=2.5, t0=None, t1=None):
    e = {"Type": "Accent", "Boost": float(boost)}
    e.update(_window(t0, t1))
    return e


def motion(lift=1.0, lean=1.0):
    return {"Lift": float(lift), "Lean": float(lean)}


# ------------------------------------------------------------------------------------------------ preview-only look


GROUPS = {
    "Head": ["Head"], "Torso": ["UpperTorso", "LowerTorso"], "UpperTorso": ["UpperTorso"], "LowerTorso": ["LowerTorso"],
    "Arms": ["LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm"],
    "UpperArms": ["LeftUpperArm", "RightUpperArm"], "LowerArms": ["LeftLowerArm", "RightLowerArm"],
    "Hands": ["LeftHand", "RightHand"],
    "Legs": ["LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"],
    "UpperLegs": ["LeftUpperLeg", "RightUpperLeg"], "LowerLegs": ["LeftLowerLeg", "RightLowerLeg"],
    "Feet": ["LeftFoot", "RightFoot"],
}


def palette(**groups):
    """Preview colours: palette(Head=(r,g,b), Torso=..., Arms=..., Hands=..., Legs=..., Feet=..., <PartName>=...)."""
    out = {}
    order = ["Torso", "UpperTorso", "LowerTorso", "Arms", "UpperArms", "LowerArms", "Hands", "Legs", "UpperLegs",
             "LowerLegs", "Feet", "Head"]
    for g in order:
        if g in groups:
            for part in GROUPS[g]:
                out[part] = tuple(groups[g])
    for name, color in groups.items():
        if name not in GROUPS:
            out[name] = tuple(color)
    return out


def extra(part, shape="box", size=(1, 1, 1), offset=(0, 0, 0), rot=(0, 0, 0), color=(40, 40, 40), emissive=False):
    """Preview-only prop welded to a part (part-local offset, rig axes): shape box | cone | sphere | spikes."""
    return {"part": part, "shape": shape, "size": tuple(size), "offset": tuple(offset), "rot": tuple(rot),
            "color": tuple(color), "emissive": bool(emissive)}


# ------------------------------------------------------------------------------------------------ clips


class Clip:
    def __init__(self, name, length, keys, loop, ease, effects, motion_mod, speed, footsteps, sparse=False):
        self.sparse = sparse
        self.name = name
        self.length = float(length)
        self.keys = keys
        self.loop = loop
        self.ease = ease
        self.effects = effects
        self.motion = motion_mod
        self.speed = speed
        self.footsteps = footsteps

    def __repr__(self):
        return "<Clip %s %.2fs loop=%s keys=%d>" % (self.name, self.length, self.loop, len(self.keys))


def clip(name, length, keys, loop=None, ease="sine_inout", effects=(), motion=None, speed=None, footsteps=True, sparse=False):
    if not isinstance(name, str) or not name:
        raise ValueError("clip name must be a non-empty string")
    if loop is None:
        loop = name != "Special"
    if not (0.1 <= float(length) <= 20.0):
        raise ValueError("%s: length must be 0.1..20 s" % name)
    if not isinstance(keys, dict) or not keys:
        raise ValueError("%s: keys must be a non-empty {time: pose} dict" % name)
    clean = {}
    for t, pose in keys.items():
        t = float(t)
        if t < -1e-9 or t > float(length) + 1e-9:
            raise ValueError("%s: key time %.3f outside 0..%.3f" % (name, t, length))
        if not isinstance(pose, dict):
            raise ValueError("%s: key %.3f must be a pose dict" % (name, t))
        for joint, value in pose.items():
            if joint == "ease":
                rbx.canonical_easing(value)
                continue
            if joint != ROOT_OFFSET and joint not in JOINTS:
                raise ValueError("%s: key %.3f names unknown joint %r (joints: %s)" % (name, t, joint, ", ".join(JOINTS)))
            _check_triplet("%s.%s@%.3f" % (name, joint, t), _unwrap(value))
        clean[round(t, 4)] = pose
    for e in effects:
        if not isinstance(e, dict) or e.get("Type") not in ("Web", "Charge", "Burst", "Accent"):
            raise ValueError("%s: bad effect %r (use web / charge / burst / accent)" % (name, e))
    if motion is not None and not isinstance(motion, dict):
        raise ValueError("%s: motion must come from motion(lift=, lean=)" % name)
    if not (speed is None or speed == "auto" or (isinstance(speed, (int, float)) and speed > 0)):
        raise ValueError("%s: speed must be None, \"auto\" or studs/s > 0, got %r" % (name, speed))
    if speed == "auto" and not loop:
        raise ValueError("%s: speed=\"auto\" needs a looping clip" % name)
    return Clip(name, length, clean, bool(loop), rbx.canonical_easing(ease), list(effects), motion, speed, bool(footsteps),
                bool(sparse))


def _fill_root_half(keys, idx):
    """keys: [[t, ease, rotation | None, offset | None], ...] of the Root track. Fills the None entries of column idx
    (2 = rotation, 3 = RootOffset) from the neighbouring keys that have one (eased like the segment between them)."""
    have = [i for i, k in enumerate(keys) if k[idx] is not None]
    if not have:
        return
    for i, k in enumerate(keys):
        if k[idx] is not None:
            continue
        prev = max((j for j in have if j < i), default=None)
        nxt = min((j for j in have if j > i), default=None)
        if prev is None or nxt is None:
            k[idx] = keys[nxt if prev is None else prev][idx]
            continue
        a, b = keys[prev], keys[nxt]
        span = b[0] - a[0]
        alpha = rbx.ease(a[1], (k[0] - a[0]) / span) if span > 1e-9 else 0.0
        if a[1] == "constant":
            alpha = 0.0
        if idx == 3:
            va, vb = _check_triplet(ROOT_OFFSET, _unwrap(a[idx])), _check_triplet(ROOT_OFFSET, _unwrap(b[idx]))
            k[idx] = tuple(va[n] + (vb[n] - va[n]) * alpha for n in range(3))
        else:
            qa = rbx.quat_from_matrix(rot_matrix(a[idx]))
            qb = rbx.quat_from_matrix(rot_matrix(b[idx]))
            k[idx] = rbx.to_euler_xyz(rbx.quat_to_matrix(rbx.nlerp(qa, qb, alpha)))


def compile_clip(c):
    """Per-joint tracks of Motor6D.Transform keys: joint -> [(t, ease, (qx, qy, qz, qw), (px, py, pz))].
    Hemisphere-continuous quaternions; loops closed at `length`; tracks start at t = 0."""
    times = sorted(c.keys)
    used = set()
    for pose in c.keys.values():
        used.update(pose)
    if ROOT_OFFSET in used:
        used.add("Root")
    tracks = {}
    for joint in JOINTS:
        keys = []
        for t in times:
            pose = c.keys[t]
            if not c.sparse and joint in used:
                # full-pose keys: a used joint missing from this key is at rest here
                pose = dict(pose)
                pose.setdefault(joint, (0.0, 0.0, 0.0))
                if joint == "Root":
                    pose.setdefault(ROOT_OFFSET, (0.0, 0.0, 0.0))
            has_rot = joint in pose
            has_off = joint == "Root" and ROOT_OFFSET in pose
            if not has_rot and not has_off:
                continue
            ease = c.ease
            if "ease" in pose:
                ease = rbx.canonical_easing(pose["ease"])
            value = pose.get(joint)
            if isinstance(value, Key):
                ease = value.ease
            keys.append([t, ease, value, pose.get(ROOT_OFFSET) if joint == "Root" else None])
        if not keys:
            continue
        # Root rotation and RootOffset share one track. In a sparse clip a key may name only one of them: the other
        # half is interpolated at that key time between the neighbouring keys that do name it (their easing), held
        # before the first / after the last such key (the loop closure then returns to the first key's value).
        if joint == "Root":
            _fill_root_half(keys, 2)
            _fill_root_half(keys, 3)
        out = []
        prev_q = None
        for t, ease, value, off in keys:
            if value is None:
                value = (0.0, 0.0, 0.0)
            if off is None:
                off = (0.0, 0.0, 0.0)
            q = rbx.quat_from_matrix(rot_matrix(value))
            if prev_q is not None and rbx.quat_dot(prev_q, q) < 0:
                q = tuple(-v for v in q)
            prev_q = q
            p = _check_triplet(ROOT_OFFSET, _unwrap(off)) if joint == "Root" else (0.0, 0.0, 0.0)
            out.append((t, ease, q, p))
        if out[0][0] > 1e-6:
            t0, e0, q0, p0 = out[0]
            out.insert(0, (0.0, e0, q0, p0))
        if c.loop and out[-1][0] < c.length - 1e-6:
            q_first, p_first = out[0][2], out[0][3]
            if rbx.quat_dot(out[-1][2], q_first) < 0:
                q_first = tuple(-v for v in q_first)
            out.append((c.length, out[-1][1], q_first, p_first))
        tracks[joint] = out
    return tracks


def sample_track(track, t):
    """Evaluate a compiled track at t (clamped): the exact runtime / Blender math (eased component lerp + normalise)."""
    if t <= track[0][0]:
        return track[0][2], track[0][3]
    for i in range(len(track) - 1):
        a, b = track[i], track[i + 1]
        if t < b[0]:
            span = b[0] - a[0]
            alpha = rbx.ease(a[1], (t - a[0]) / span) if span > 1e-9 else 1.0
            if a[1] == "constant":
                alpha = 0.0
            q = rbx.quat_normalize(tuple(a[2][k] + (b[2][k] - a[2][k]) * alpha for k in range(4)))
            p = tuple(a[3][k] + (b[3][k] - a[3][k]) * alpha for k in range(3))
            return q, p
    return track[-1][2], track[-1][3]


def sample_clip(c, t, compiled=None):
    """joint -> (R, p) Transform at clip time t (loops wrap)."""
    tracks = compiled or compile_clip(c)
    if c.loop:
        t = t % c.length
    t = max(0.0, min(c.length, t))
    out = {}
    for joint, track in tracks.items():
        q, p = sample_track(track, t)
        out[joint] = (rbx.quat_to_matrix(q), p)
    return out


class Hero:
    def __init__(self, module):
        self.id = getattr(module, "HERO", None)
        if not isinstance(self.id, str) or not self.id:
            raise ValueError("%s: HERO = \"<HeroId>\" missing" % module.__name__)
        clips = getattr(module, "CLIPS", None)
        if callable(clips):
            clips = clips()
        if not clips:
            raise ValueError("%s: CLIPS = [clip(...), ...] missing" % self.id)
        self.clips = {}
        for c in clips:
            if not isinstance(c, Clip):
                raise ValueError("%s: CLIPS entries must come from clip(...)" % self.id)
            if c.name in self.clips:
                raise ValueError("%s: duplicate clip %s" % (self.id, c.name))
            self.clips[c.name] = c
        for required in REQUIRED_CLIPS:
            if required not in self.clips:
                raise ValueError("%s: clip %r is required (contract: Idle + Move, optional Special)" % (self.id, required))
            if not self.clips[required].loop:
                raise ValueError("%s: %s must loop" % (self.id, required))
        if "Special" in self.clips and self.clips["Special"].loop:
            raise ValueError("%s: Special must not loop" % self.id)
        every = getattr(module, "SPECIAL_EVERY", (10.0, 20.0))
        if not (isinstance(every, (tuple, list)) and len(every) == 2 and 2.0 <= every[0] <= every[1] <= 120.0):
            raise ValueError("%s: SPECIAL_EVERY must be (min, max) seconds, 2 <= min <= max <= 120" % self.id)
        self.special_every = (float(every[0]), float(every[1]))
        self.colors = getattr(module, "COLORS", None) or palette(Head=(245, 205, 160), Torso=(80, 90, 110), Arms=(80, 90, 110),
                                                                  Hands=(245, 205, 160), Legs=(50, 55, 70), Feet=(35, 35, 40))
        self.extras = list(getattr(module, "EXTRAS", []) or [])
        self.thumb_times = dict(getattr(module, "THUMB_TIMES", {}) or {})
        self.cameras = dict(getattr(module, "CAMERAS", {}) or {})
        self.compiled = {name: compile_clip(c) for name, c in self.clips.items()}
        # speed="auto": foot-lock the legs (footlock.py) and export the measured ground speed as Speed
        self.gait = {}
        for name, c in self.clips.items():
            if c.speed == "auto":
                from . import footlock
                self.compiled[name], info = footlock.lock(sys.modules[__name__], c, self.compiled[name])
                c.speed = round(info["speed"], 3) if info["valid"] else None
                self.gait[name] = info
        self._check_loop_closure()
        self.warnings = self._sanity()

    def ordered_clips(self):
        names = [n for n in CLIP_NAMES if n in self.clips] + sorted(n for n in self.clips if n not in CLIP_NAMES)
        return [self.clips[n] for n in names]

    def _sanity(self):
        """Non-fatal checks: parts sinking far below the ground, runaway offsets."""
        warnings = []
        r = rig()
        for c in self.clips.values():
            for i in range(21):
                t = c.length * i / 20.0
                parts, _ = r.fk(sample_clip(c, t, self.compiled[c.name]))
                low = min(parts[n][1][1] - 0.5 * min(r.parts[n]["size"]) for n in parts if n != "HumanoidRootPart")
                if low < -0.6:
                    warnings.append("%s @%.2fs: a part reaches %.2f studs below the ground" % (c.name, t, low))
                    break
            for t, pose in c.keys.items():
                off = _unwrap(pose.get(ROOT_OFFSET, (0, 0, 0)))
                if max(abs(v) for v in off) > 6:
                    warnings.append("%s @%.2fs: RootOffset %s is more than 6 studs" % (c.name, t, off))
        return warnings

    def _check_loop_closure(self):
        """A looping clip wraps t = length back to t = 0 in game: an authored key at t = length must repeat the t = 0
        pose, otherwise the loop pops at the wrap (and Blender, which evaluates that key, disagrees with the runtime)."""
        for c in self.clips.values():
            if not c.loop:
                continue
            for joint, track in self.compiled[c.name].items():
                first, last = track[0], track[-1]
                if len(track) > 1 and abs(last[0] - c.length) < 1e-6 and (
                        abs(rbx.quat_dot(first[2], last[2])) < 0.999999 or rbx.v_len(rbx.v_sub(first[3], last[3])) > 1e-4):
                    raise ValueError("%s.%s: the key at t = length (%.3fs) differs from the t = 0 pose on %s - a loop wraps "
                                     "to t = 0 in game, so it would pop. Drop that key (loops close on their first pose by "
                                     "themselves) or make it repeat the t = 0 pose." % (self.id, c.name, c.length, joint))


def load_hero(module):
    return Hero(module)
