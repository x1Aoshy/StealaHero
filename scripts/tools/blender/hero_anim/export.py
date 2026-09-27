# scripts/tools/blender/hero_anim/export.py
# Clips -> Blender actions on the HeroRig -> Roblox Motor6D.Transform keyframes -> the generated Luau data module.
#
#   build_actions(built, hero)            one action per clip ("<HeroId>_<Clip>"): quaternion (+ Root location) keys at
#                                         the authored times (fractional frames at FPS), Blender interpolation / easing
#                                         set per key from the clip's easing (rbx.EASINGS)
#   export_module(built, hero, actions)   reads the ACTIONS back (keyframe values + interpolation), converts every
#                                         pose-bone key to Motor6D.Transform (rig.basis_to_transform) and writes
#                                         src/ReplicatedStorage/Directory/HeroAnimations/<HeroId>.luau
#   roundtrip_dump(built, hero, actions)  poses the rig at sample times, stores every mannequin part's CFrame (Roblox rig
#                                         space) in assets/animations/roundtrip/<HeroId>.json for
#                                         scripts/tools/verify_hero_anims.luau (rebuilds the parts in Lune from the
#                                         exported Transforms with Part1 = Part0 * C0 * Transform * C1:Inverse())
#
# Generated module format (Format = 1):
#   return { Format = 1, HeroId = "Vegeta", SpecialEvery = { 10, 18 }, Clips = { Idle = {
#       Length = 3.2, Loop = true, Speed = nil, Footsteps = true, Motion = { Lift = 1, Lean = 1 }, Effects = { ... },
#       Tracks = { Neck = { { t, "sine_inout", qx, qy, qz, qw }, ... }, Root = { { t, ease, qx, qy, qz, qw, px, py, pz }, ... } },
#   }, ... } }
#   A key's easing shapes the segment to the next key. Joints without a track stay at rest (identity Transform).

import json
import math
import os

import bpy

from . import api, rbx, rig

FPS = 60
MODULE_DIR = os.path.join(api.REPO_ROOT, "src", "ReplicatedStorage", "Directory", "HeroAnimations")
ROUNDTRIP_DIR = os.path.join(api.REPO_ROOT, "assets", "animations", "roundtrip")

_BLENDER_TO_EASING = {}
for _name, (_fn, _interp, _easing) in rbx.EASINGS.items():
    _BLENDER_TO_EASING[(_interp, _easing)] = _name


def _fcurves(action):
    """The action's F-curves (legacy accessor, or the first layer / strip / slot channelbag on layered actions)."""
    try:
        curves = action.fcurves
        if curves is not None and len(curves) > 0:
            return list(curves)
    except AttributeError:
        pass
    out = []
    for layer in getattr(action, "layers", []):
        for strip in layer.strips:
            for slot in action.slots:
                bag = strip.channelbag(slot)
                if bag is not None:
                    out.extend(bag.fcurves)
    return out


def _set_action(arm, action):
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = action
    if hasattr(arm.animation_data, "action_slot") and arm.animation_data.action_slot is None:
        slots = getattr(action, "slots", None)
        if slots:
            arm.animation_data.action_slot = slots[0]


def build_actions(built, hero):
    arm = built.arm
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.render.fps_base = 1.0
    actions = {}
    for c in hero.ordered_clips():
        name = "%s_%s" % (hero.id, c.name)
        old = bpy.data.actions.get(name)
        if old is not None:
            bpy.data.actions.remove(old)
        action = bpy.data.actions.new(name)
        action.use_fake_user = True
        _set_action(arm, action)
        tracks = hero.compiled[c.name]
        for pb in arm.pose.bones:
            pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
            pb.location = (0.0, 0.0, 0.0)
        # key every bone of the clip; bones without a track get a single identity key so they stay at rest
        for joint in api.JOINTS:
            pb = arm.pose.bones[joint]
            track = tracks.get(joint) or [(0.0, "linear", (0.0, 0.0, 0.0, 1.0), (0.0, 0.0, 0.0))]
            prev = None
            for t, ease, q, p in track:
                quat, loc = rig.transform_to_basis(joint, q, p)
                if prev is not None and prev.dot(quat) < 0:
                    quat.negate()
                prev = quat.copy()
                pb.rotation_quaternion = quat
                frame = t * FPS
                pb.keyframe_insert("rotation_quaternion", frame=frame, group=joint)
                if joint == "Root":
                    pb.location = loc
                    pb.keyframe_insert("location", frame=frame, group=joint)
        # interpolation / easing per key (a key's easing shapes the segment after it)
        for fc in _fcurves(action):
            joint = fc.data_path.split('"')[1]
            track = tracks.get(joint) or [(0.0, "linear", None, None)]
            by_frame = {round(k[0] * FPS, 3): k[1] for k in track}
            for kp in fc.keyframe_points:
                ease = by_frame.get(round(kp.co[0], 3), "linear")
                _curve, interp, easing = rbx.EASINGS[ease]
                kp.interpolation = interp
                kp.easing = easing
                if interp == "BACK":
                    kp.back = rbx.BACK_OVERSHOOT
            fc.update()
        actions[c.name] = action
    return actions


def read_action(action):
    """joint -> [(t, ease, (qx, qy, qz, qw), (px, py, pz))] read back from the action's F-curves."""
    channels = {}
    for fc in _fcurves(action):
        joint = fc.data_path.split('"')[1]
        prop = fc.data_path.rsplit(".", 1)[1]
        entry = channels.setdefault(joint, {})
        for kp in fc.keyframe_points:
            frame = round(kp.co[0], 4)
            slot = entry.setdefault(frame, {"rot": [1.0, 0.0, 0.0, 0.0], "loc": [0.0, 0.0, 0.0], "ease": "linear"})
            if prop == "rotation_quaternion":
                slot["rot"][fc.array_index] = kp.co[1]
                slot["ease"] = _BLENDER_TO_EASING.get((kp.interpolation, kp.easing), "linear")
            elif prop == "location":
                slot["loc"][fc.array_index] = kp.co[1]
    tracks = {}
    for joint, frames in channels.items():
        keys = []
        for frame in sorted(frames):
            slot = frames[frame]
            q, p = rig.basis_to_transform(joint, slot["rot"], slot["loc"])
            keys.append((frame / FPS, slot["ease"], q, p))
        tracks[joint] = keys
    return tracks


def _num(v, digits):
    r = round(v, digits)
    if r == 0:
        r = 0.0
    text = ("%." + str(digits) + "f") % r
    text = text.rstrip("0").rstrip(".") if "." in text else text
    return "0" if text in ("-0", "") else text


def _lua_value(v, indent):
    pad = "\t" * indent
    if v is None:
        return "nil"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return _num(float(v), 4)
    if isinstance(v, str):
        return '"%s"' % v.replace("\\", "\\\\").replace('"', '\\"')
    if isinstance(v, (list, tuple)):
        if all(isinstance(x, (int, float)) for x in v):
            return "{ " + ", ".join(_num(float(x), 4) for x in v) + " }"
        return "{\n" + "".join("%s\t%s,\n" % (pad, _lua_value(x, indent + 1)) for x in v) + pad + "}"
    if isinstance(v, dict):
        items = []
        for k in sorted(v):
            if v[k] is None:
                continue
            items.append("%s\t%s = %s,\n" % (pad, k, _lua_value(v[k], indent + 1)))
        return "{\n" + "".join(items) + pad + "}"
    raise TypeError("cannot write %r" % (v,))


def module_source(hero, tracks_by_clip, source_path):
    lines = [
        "-- ReplicatedStorage.Directory.HeroAnimations.%s (GENERATED - do not edit by hand)" % hero.id,
        "-- Authored in %s, exported by scripts/tools/blender/hero_anim/run.py" % source_path,
        "-- (Blender HeroRig actions -> Motor6D.Transform keys). Played by",
        "-- StarterPlayerScripts.Game.Plots.ActiveAssetsController.HeroClipPlayer (evaluation: Library.Modules.HeroClipMath).",
        "-- Tracks: joint -> { { time, easing, qx, qy, qz, qw [, px, py, pz for Root] }, ... }; a key's easing shapes the",
        "-- segment to the next key; joints without a track stay at rest. Studs are for the block R15 template at scale 1.",
        "",
        "return {",
        "\tFormat = 1,",
        '\tHeroId = "%s",' % hero.id,
        "\tSpecialEvery = { %s, %s }," % (_num(hero.special_every[0], 2), _num(hero.special_every[1], 2)),
        "\tClips = {",
    ]
    for c in hero.ordered_clips():
        tracks = tracks_by_clip[c.name]
        lines.append("\t\t%s = {" % c.name)
        lines.append("\t\t\tLength = %s," % _num(c.length, 4))
        lines.append("\t\t\tLoop = %s," % ("true" if c.loop else "false"))
        if c.speed is not None:
            lines.append("\t\t\tSpeed = %s," % _num(float(c.speed), 3))
        lines.append("\t\t\tFootsteps = %s," % ("true" if c.footsteps else "false"))
        m = c.motion or {"Lift": 1.0, "Lean": 1.0}
        lines.append("\t\t\tMotion = { Lift = %s, Lean = %s }," % (_num(m["Lift"], 3), _num(m["Lean"], 3)))
        if c.effects:
            lines.append("\t\t\tEffects = %s," % _lua_value(c.effects, 3))
        else:
            lines.append("\t\t\tEffects = {},")
        lines.append("\t\t\tTracks = {")
        for joint in api.JOINTS:
            keys = tracks.get(joint)
            if not keys:
                continue
            # a single identity key (a bone kept at rest) is dropped: no track == rest
            if len(keys) == 1 and max(abs(v) for v in keys[0][2][:3]) < 1e-6 and max(abs(v) for v in keys[0][3]) < 1e-6:
                continue
            rows = []
            for t, ease, q, p in keys:
                nums = [_num(t, 4), '"%s"' % ease] + [_num(v, 5) for v in q]
                if joint == "Root":
                    nums += [_num(v, 4) for v in p]
                rows.append("{ " + ", ".join(nums) + " }")
            lines.append("\t\t\t\t%s = { %s }," % (joint, ", ".join(rows)))
        lines.append("\t\t\t},")
        lines.append("\t\t},")
    lines.append("\t},")
    lines.append("}")
    return "\n".join(lines) + "\n"


def export_module(built, hero, actions, source_path):
    tracks_by_clip = {name: read_action(action) for name, action in actions.items()}
    # the read-back keys must be the authored ones (catches a lossy Blender step)
    worst = 0.0
    for name, tracks in tracks_by_clip.items():
        for joint, keys in hero.compiled[name].items():
            got = tracks.get(joint, [])
            if len(got) != len(keys):
                raise RuntimeError("%s.%s.%s: %d keys authored, %d read back" % (hero.id, name, joint, len(keys), len(got)))
            for a, b in zip(keys, got):
                worst = max(worst, abs(a[0] - b[0]), 1.0 - abs(rbx.quat_dot(a[2], b[2])), rbx.v_len(rbx.v_sub(a[3], b[3])))
                if a[1] != b[1]:
                    raise RuntimeError("%s.%s.%s @%.3f: easing %s read back as %s" % (hero.id, name, joint, a[0], a[1], b[1]))
    os.makedirs(MODULE_DIR, exist_ok=True)
    path = os.path.join(MODULE_DIR, hero.id + ".luau")
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(module_source(hero, tracks_by_clip, source_path))
    return path, worst, tracks_by_clip


def pose_at(built, action, t):
    """Evaluates `action` at clip time t (seconds) on the rig."""
    _set_action(built.arm, action)
    frame = t * FPS
    base = math.floor(frame)
    bpy.context.scene.frame_set(int(base), subframe=float(frame - base))


def part_frames(built):
    out = {}
    for name, obj in built.parts.items():
        f = rig.roblox_from_blender(obj.matrix_world)
        out[name] = rbx.cf_components(f)
    return out


def roundtrip_dump(built, hero, actions, samples_per_clip=24):
    data = {"hero": hero.id, "fps": FPS, "clips": {}}
    for c in hero.ordered_clips():
        action = actions[c.name]
        times = set(round(c.length * i / samples_per_clip, 4) for i in range(samples_per_clip + 1))
        for keys in hero.compiled[c.name].values():
            for i, k in enumerate(keys):
                times.add(round(k[0], 4))
                if i + 1 < len(keys):
                    times.add(round((k[0] + keys[i + 1][0]) * 0.5, 4))
                    times.add(round(k[0] + (keys[i + 1][0] - k[0]) * 0.3, 4))
        samples = []
        for t in sorted(times):
            if t > c.length:
                continue
            pose_at(built, action, t)
            samples.append({"t": t, "parts": {n: [round(v, 6) for v in comps] for n, comps in part_frames(built).items()}})
        data["clips"][c.name] = {"length": c.length, "loop": c.loop, "samples": samples}
    os.makedirs(ROUNDTRIP_DIR, exist_ok=True)
    path = os.path.join(ROUNDTRIP_DIR, hero.id + ".json")
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, separators=(",", ":"))
    return path


def python_check(built, hero, actions):
    """In-Blender check: the pure-Python evaluator (api.sample_clip, the runtime's math) against Blender's posed
    mannequin at the roundtrip sample times. Returns the worst part-corner error (studs)."""
    r = api.rig()
    worst = 0.0
    for c in hero.ordered_clips():
        for i in range(13):
            t = c.length * i / 12.0
            pose_at(built, actions[c.name], t)
            got = part_frames(built)
            parts, _ = r.fk(api.sample_clip(c, t, hero.compiled[c.name]))
            for name, comps in got.items():
                f = rbx.cf_from_components(comps)
                size = r.parts[name]["size"]
                for corner in ((1, 1, 1), (-1, 1, -1), (1, -1, -1), (-1, -1, 1)):
                    local = (corner[0] * size[0] / 2, corner[1] * size[1] / 2, corner[2] * size[2] / 2)
                    a = rbx.cf_point((f[0], f[1]), local)
                    b = rbx.cf_point(parts[name], local)
                    worst = max(worst, rbx.v_len(rbx.v_sub(a, b)))
    return worst
