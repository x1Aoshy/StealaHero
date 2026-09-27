# Shared authoring helpers of the Avengers / Justice League hero clips (ANIM_AVJL). The "_" prefix keeps run.py from
# treating this file as a hero. Pure Python on top of api.py (rig space: +X right, +Y up, -Z forward).
#   aim_hand(pose, side, local_axis, direction, flex_only)  sets the wrist so a hand-local axis points along a rig-space
#                                                          direction (a trident held upright, a palm turned to the ground)
#   hand_dir(pose, side, local_axis)                       where a hand-local axis points for a pose (rig space)
#   prop_frame(pose, part, point, normal)                  part-local offset + rot of a preview prop placed at a rig-space
#                                                          point with its thin local Z axis along `normal` in that pose
#   ring(hand, center, radius, y, t0, t1, n)               Web effects hopping round a circle (a whirled lasso / spin)
import math

from hero_anim import api, rbx

HAND_FINGERS = (0.0, -1.0, 0.0)  # hand-local -Y: the fingertips / palm face of the block hand
HAND_FRONT = (0.0, 0.0, -1.0)    # hand-local -Z: forward when the arm hangs (Aquaman's trident runs along it)


def _parent_frame(pose, joint):
    r = api.rig()
    j = r.joint[joint]
    p = dict(pose)
    p.pop(joint, None)
    parts, _ = r.fk(api.transforms_of(p))
    return rbx.cf_mul(parts[j["part0"]], j["c0"]), j


def hand_dir(pose, side, local_axis=HAND_FINGERS):
    parts, _ = api.rig().fk(api.transforms_of(pose))
    r, _ = parts[side + "Hand"]
    return rbx.v_norm(rbx.m_vec(r, local_axis))


def aim_hand(pose, side, local_axis, direction, flex_only=False, limit=85.0):
    """Returns pose with <side>Wrist set so the hand-local `local_axis` points along the rig-space `direction`.
    flex_only: only the wrist flex (X) is used (clamped to +-limit), the hand keeps its twist."""
    parent, j = _parent_frame(pose, side + "Wrist")
    target = rbx.v_norm(rbx.m_vec(rbx.m_transpose(parent[0]), rbx.v_norm(direction)))
    axis = rbx.m_vec(rbx.m_transpose(j["c1"][0]), local_axis)
    out = dict(pose)
    if flex_only:
        a = math.degrees(math.atan2(axis[2], axis[1]))
        b = math.degrees(math.atan2(target[2], target[1]))
        flex = (b - a + 180.0) % 360.0 - 180.0
        out[side + "Wrist"] = (round(max(-limit, min(limit, flex)), 3), 0.0, 0.0)
    else:
        out[side + "Wrist"] = api._euler(rbx.rotation_between(axis, target))
    return out


def prop_frame(pose, part, point, normal):
    """(offset, rot) for extra(part, ..., offset=, rot=): the prop's centre sits at the rig-space `point` and its
    local Z axis (the thin axis of a flattened sphere / box) along `normal`, for this pose."""
    parts, _ = api.rig().fk(api.transforms_of(pose))
    r, p = parts[part]
    rt = rbx.m_transpose(r)
    offset = rbx.m_vec(rt, rbx.v_sub(point, p))
    local_n = rbx.m_vec(rt, rbx.v_norm(normal))
    rot = rbx.to_euler_xyz(rbx.rotation_between((0.0, 0.0, 1.0), local_n))
    return tuple(round(v, 3) for v in offset), tuple(round(v, 2) for v in rot)


def ring(hand, center, radius, t0, t1, n=6, color=(255, 214, 90), width=0.1, turns=1.0):
    """n short Web effects whose anchors hop round a horizontal circle (rig space): a lasso whirled overhead."""
    out = []
    step = (t1 - t0) / n
    for i in range(n):
        a = 2.0 * math.pi * turns * i / n
        anchor = (center[0] + math.cos(a) * radius, center[1], center[2] + math.sin(a) * radius)
        out.append(api.web(hand, anchor=anchor, t0=round(t0 + i * step, 3), t1=round(t0 + (i + 1) * step, 3),
                           color=color, width=width))
    return out
