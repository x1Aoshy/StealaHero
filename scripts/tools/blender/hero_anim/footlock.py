# scripts/tools/blender/hero_anim/footlock.py
# Foot locking for the pen heroes' Move clips (ANIMPOLISH). Pure Python (no bpy).
#
# Why: the gait helpers (walk_cycle / run_cycle / stomp_cycle) and hand-made strides key a few poses per cycle and
# ease between them, so the planted foot does not move backward at a constant speed (it stops at every key and
# catches up in between) and the passing pose lifts the stance foot off the ground while the swing foot scrapes it.
# At any playback rate the feet slide ("ice skating"). HeroClipPlayer now plays Move at
#     rate = ground speed / (Speed * rig scale)
# so a clip whose planted feet move backward at exactly Speed studs/s looks glued to the pen floor.
#
# lock(api, clip, tracks) -> (tracks, info): resamples the legs of a looping locomotion clip at RATE keys/s and, with
# two-bone IK on the template rig, rebuilds Hip / Knee / Ankle so that
#   - during each stance run (a foot moving backward near the ground) the foot's floor spot slides back at the constant
#     ground speed v with a heel-toe roll (heel strike, flat, toe-off pivot); the swing blends onto / off that path in
#     the air (EDGE), so nothing slides while it touches the floor,
#   - during the swing the foot keeps the authored path but clears the floor by at least CLEAR studs mid-swing,
#   - when a straight leg cannot reach the floor (a passing pose that bounces the body up) the hips drop just enough.
# Everything else (upper body, arms, Root rotation, easing of the authored keys) is untouched: only the six leg tracks
# (and the Root track when the hips had to drop) become dense linear tracks. v is the clip's measured Speed.
# api.clip(..., speed="auto") runs it (api.Hero); gait.py reports the result (slide ~ 0 after locking).

import math

from . import rbx

SIDES = ("Left", "Right")
LEG_JOINTS = ("Hip", "Knee", "Ankle")
RATE = 45.0  # dense leg keys per second of clip
MIN_KEYS = 24
BAND = 0.3  # a foot within this height of the cycle's lowest sole can be planted
EDGE = 0.3  # the swing blends onto / off the locked path over this share of the stance run (in the air)
CLEAR = 0.22  # swing sole clearance mid-swing (studs, template scale)
HEEL_PITCH = 14.0  # heel strike: toes up (degrees), rolled flat by HEEL_END of the stance
HEEL_END = 0.2
TOE_PITCH = -24.0  # toe-off: rolls onto the toe from TOE_START of the stance
TOE_START = 0.62
MIN_RUN = 2  # stance runs shorter than this (samples) are noise


def _smoothstep(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3.0 - 2.0 * x)


def _runs(flags):
    """Circular runs of True in flags -> [(start, length)]."""
    n = len(flags)
    if all(flags):
        return [(0, n)]
    if not any(flags):
        return []
    start = next(i for i in range(n) if not flags[i])  # begin scanning right after a False
    runs, i, count = [], (start + 1) % n, 0
    run_start = None
    for _ in range(n):
        if flags[i]:
            if run_start is None:
                run_start, count = i, 0
            count += 1
        elif run_start is not None:
            runs.append((run_start, count))
            run_start = None
        i = (i + 1) % n
    if run_start is not None:
        runs.append((run_start, count))
    return runs


def _sole_low(parts, rig, side):
    sx, sy, sz = rig.parts[side + "Foot"]["size"]
    frame = parts[side + "Foot"]
    return min(rbx.cf_point(frame, (x * sx * 0.5, -sy * 0.5, z * sz * 0.5))[1] for x in (-1, 1) for z in (-1, 1))


def _leg_ik(api, rig, transforms, side, target, foot_rot, knee_dir):
    """Hip / Knee / Ankle (R, p) Transforms putting the ankle joint of `side` at `target` (rig space) with the foot
    part's world rotation `foot_rot`; the knee bends toward `knee_dir` (rig space)."""
    parts, _ = rig.fk(transforms)
    j1, v1, v2, sign = api._chain_vectors(side, "leg")
    parent = rbx.cf_mul(parts[j1["part0"]], j1["c0"])
    rt = rbx.m_transpose(parent[0])
    local_target = rbx.m_vec(rt, rbx.v_sub(tuple(target), parent[1]))
    local_hint = rbx.m_vec(rt, rbx.v_norm(knee_dir))
    rot, phi = api._solve_two_bone(v1, v2, sign, local_target, local_hint, (0.0, 0.0, -1.0))
    knee = rbx.rot_x(-phi)
    chain = rbx.m_mul(rbx.m_mul(parent[0], rot), knee)
    ankle = rbx.m_mul(rbx.m_transpose(chain), foot_rot)
    zero = (0.0, 0.0, 0.0)
    return {side + "Hip": (rot, zero), side + "Knee": (knee, zero), side + "Ankle": (ankle, zero)}


def _hip_pivot(rig, transforms, side):
    parts, _ = rig.fk(transforms)
    j = rig.joint[side + "Hip"]
    return rbx.cf_mul(parts[j["part0"]], j["c0"])[1]


def _max_reach(api, side):
    _, v1, v2, _ = api._chain_vectors(side, "leg")
    return rbx.v_len(v1) + rbx.v_len(v2)


def _dense_track(times, length, rots, offsets=None):
    out = []
    prev = None
    for i, t in enumerate(times):
        q = rbx.quat_from_matrix(rots[i])
        if prev is not None and rbx.quat_dot(prev, q) < 0:
            q = tuple(-v for v in q)
        prev = q
        p = offsets[i] if offsets else (0.0, 0.0, 0.0)
        out.append((round(t, 6), "linear", tuple(q), tuple(p)))
    first = out[0]
    q0 = first[2]
    if rbx.quat_dot(out[-1][2], q0) < 0:
        q0 = tuple(-v for v in q0)
    out.append((length, "linear", q0, first[3]))
    return out


def lock(api, clip, tracks):
    """Foot-locks a looping locomotion clip. Returns (tracks, info); info["valid"] is False (tracks unchanged) when
    the clip has no stance (hops in place, swings, flights)."""
    rig = api.rig()
    length = clip.length
    n = max(MIN_KEYS, int(round(length * RATE)))
    dt = length / n
    times = [dt * i for i in range(n)]
    samples = [api.sample_clip(clip, t, tracks) for t in times]
    ankle, sole, foot_rot, knee_dir = {}, {}, {}, {}
    for side in SIDES:
        ankle[side], sole[side], foot_rot[side], knee_dir[side] = [], [], [], []
    for s in samples:
        parts, joints = rig.fk(s)
        for side in SIDES:
            a = joints[side + "Ankle"][1]
            k = joints[side + "Knee"][1]
            h = rbx.cf_mul(parts[rig.joint[side + "Hip"]["part0"]], rig.joint[side + "Hip"]["c0"])[1]
            ankle[side].append(a)
            sole[side].append(_sole_low(parts, rig, side))
            foot_rot[side].append(parts[side + "Foot"][0])
            mid = rbx.v_scale(rbx.v_add(h, a), 0.5)
            d = rbx.v_sub(k, mid)
            knee_dir[side].append(rbx.v_norm(d) if rbx.v_len(d) > 0.05 else (0.0, 0.0, -1.0))
    lowest = min(min(sole[s]) for s in SIDES)

    # stance: the ankle moves backward (+z) with its sole near the floor
    stance, vel = {}, {}
    for side in SIDES:
        z = [p[2] for p in ankle[side]]
        vel[side] = [(z[(i + 1) % n] - z[(i - 1) % n]) / (2 * dt) for i in range(n)]
        flags = [vel[side][i] > 0.05 and sole[side][i] <= lowest + BAND for i in range(n)]
        for start, count in _runs(flags):
            if count < MIN_RUN:
                for k in range(count):
                    flags[(start + k) % n] = False
        stance[side] = flags
    planted = [vel[s][i] for s in SIDES for i in range(n) if stance[s][i]]
    info = {"valid": False, "speed": 0.0, "keys": n, "drop": 0.0}
    if len(planted) < MIN_RUN or sum(planted) / len(planted) < 0.8:
        return tracks, info
    v = sum(planted) / len(planted)
    info["speed"] = v

    fx, fy, fz = rig.parts["RightFoot"]["size"]
    heel = (0.0, -fy * 0.5, fz * 0.5)  # foot-part space (+z = back)
    toe = (0.0, -fy * 0.5, -fz * 0.5)
    corners = [(x * fx * 0.5, -fy * 0.5, z * fz * 0.5) for x in (-1, 1) for z in (-1, 1)]
    targets = {side: [None] * n for side in SIDES}
    rots = {side: [None] * n for side in SIDES}
    weights = {side: [0.0] * n for side in SIDES}

    def pivot(side, ground, point, pitch):
        """Ankle joint position + foot rotation when the foot-space `point` sits on the floor spot `ground` and the
        foot is pitched `pitch` degrees (+ = toes up) about it."""
        c1 = rig.joint[side + "Ankle"]["c1"][1]
        r = rbx.rot_x(pitch)
        return rbx.v_add(ground, rbx.m_vec(r, rbx.v_sub(c1, point))), r

    def pitch_at(u):
        """Heel-toe roll over a stance run (u = 0 heel strike .. 1 toe-off)."""
        if u < HEEL_END:
            return HEEL_PITCH * (1.0 - _smoothstep(u / HEEL_END)), heel
        if u > TOE_START:
            return TOE_PITCH * _smoothstep((u - TOE_START) / (1.0 - TOE_START)), toe
        return 0.0, heel

    for side in SIDES:
        c1 = rig.joint[side + "Ankle"]["c1"][1]
        for start, count in _runs(stance[side]):
            centre = start + (count - 1) * 0.5
            c0, c1i = int(math.floor(centre)) % n, int(math.ceil(centre)) % n
            # the heel's floor spot slides back at v; centred on the authored run (flat foot at the run centre)
            heel_c = (ankle[side][c0][2] + ankle[side][c1i][2]) * 0.5 + (heel[2] - c1[2])
            x_c = sum(ankle[side][(start + k) % n][0] for k in range(count)) / count

            def heel_spot(a, heel_c=heel_c, x_c=x_c, centre=centre):
                # a = unwrapped sample index (a run may wrap past the loop end; its ramps may reach before 0)
                return (x_c, 0.0, heel_c + v * (a - centre) * dt)

            for k in range(count):
                i = (start + k) % n
                pitch, point = pitch_at((k + 0.5) / count)
                ground = heel_spot(start + k)
                if point is toe:
                    ground = rbx.v_add(ground, (0.0, 0.0, toe[2] - heel[2]))
                targets[side][i], rots[side][i] = pivot(side, ground, point, pitch)
                weights[side][i] = 1.0
            # into / out of the run through the air: the swing blends onto the locked path over `edge` samples
            edge = max(2, int(round(count * EDGE)))
            for j in range(1, edge + 1):
                w = _smoothstep(1.0 - j / (edge + 1.0))
                for k, pitch, point in ((start - j, HEEL_PITCH, heel), (start + count - 1 + j, TOE_PITCH, toe)):
                    i = k % n
                    if stance[side][i] or w <= weights[side][i]:
                        continue
                    ground = heel_spot(k)
                    if point is toe:
                        ground = rbx.v_add(ground, (0.0, 0.0, toe[2] - heel[2]))
                    lock_pos, lock_rot = pivot(side, ground, point, pitch)
                    a = ankle[side][i]
                    targets[side][i] = tuple(a[m] + (lock_pos[m] - a[m]) * w for m in range(3))
                    qa = rbx.quat_from_matrix(foot_rot[side][i])
                    rots[side][i] = rbx.quat_to_matrix(rbx.nlerp(qa, rbx.quat_from_matrix(lock_rot), w))
                    weights[side][i] = w
        # the rest of the swing keeps the authored path; the sole clears the floor mid-swing
        for start, count in _runs([not f for f in stance[side]]):
            for k in range(count):
                i = (start + k) % n
                if targets[side][i] is None:
                    targets[side][i], rots[side][i] = ankle[side][i], foot_rot[side][i]
                rel = [rbx.m_vec(rots[side][i], rbx.v_sub(c, c1))[1] for c in corners]
                sole_now = targets[side][i][1] + min(rel)
                want = CLEAR * math.sin(math.pi * (k + 1.0) / (count + 1.0)) * (1.0 - weights[side][i])
                if sole_now < want:
                    t_ = targets[side][i]
                    targets[side][i] = (t_[0], t_[1] + (want - sole_now), t_[2])

    # hips drop where a straight leg cannot reach its planted spot
    reach = {side: _max_reach(api, side) * 0.995 for side in SIDES}
    drops = [0.0] * n
    for i in range(n):
        need = 0.0
        for side in SIDES:
            if weights[side][i] <= 0.0:
                continue
            h = _hip_pivot(rig, samples[i], side)
            d = rbx.v_sub(targets[side][i], h)
            horiz = math.sqrt(d[0] * d[0] + d[2] * d[2])
            if rbx.v_len(d) > reach[side] and horiz < reach[side]:
                need = max(need, -d[1] - math.sqrt(reach[side] ** 2 - horiz ** 2))
        drops[i] = max(0.0, need)
    if max(drops) > 1e-4:
        raw = drops
        dil = [max(raw[(i - 1) % n], raw[i], raw[(i + 1) % n]) for i in range(n)]
        drops = [max(raw[i], (dil[(i - 1) % n] + dil[i] * 2.0 + dil[(i + 1) % n]) * 0.25) for i in range(n)]
        info["drop"] = max(drops)

    # solve
    out_rot = {side + j: [None] * n for side in SIDES for j in LEG_JOINTS}
    root_rot, root_off = [None] * n, [None] * n
    for i in range(n):
        s = dict(samples[i])
        r0, p0 = s.get("Root", (rbx.IDENTITY, (0.0, 0.0, 0.0)))
        p = (p0[0], p0[1] - drops[i], p0[2])
        s["Root"] = (r0, p)
        root_rot[i], root_off[i] = r0, p
        for side in SIDES:
            legs = _leg_ik(api, rig, s, side, targets[side][i], rots[side][i], knee_dir[side][i])
            s.update(legs)
            for j in LEG_JOINTS:
                out_rot[side + j][i] = legs[side + j][0]
    new = dict(tracks)
    for name, rots_ in out_rot.items():
        new[name] = _dense_track(times, length, rots_)
    if info["drop"] > 1e-4:
        new["Root"] = _dense_track(times, length, root_rot, root_off)
    info["valid"] = True
    return new, info
