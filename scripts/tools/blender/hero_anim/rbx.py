# scripts/tools/blender/hero_anim/rbx.py
# Pure-Python Roblox CFrame math + the easing curves shared by the whole hero animation pipeline (no bpy: hero modules
# and api.py import this outside Blender too).
#
# Conventions (Roblox rig space, see api.py for the per-joint table):
#   +X = the rig's right, +Y = up, +Z = back (a rig faces -Z). Rotations are 3x3 row-major tuples (r00..r22) exactly
#   like CFrame:GetComponents(); euler_xyz(x, y, z) in DEGREES == CFrame.Angles(rad(x), rad(y), rad(z)) == Rx*Ry*Rz.
#   Quaternions are (x, y, z, w) like Roblox's CFrame.new(px, py, pz, qx, qy, qz, qw).
#
# Easing: the curves are Blender's (BLI_easing.cc, Penner) so an fcurve segment evaluated in Blender and the same
# segment evaluated by the game runtime (ReplicatedStorage.Library.Modules.HeroClipMath) are identical. A key's easing
# shapes the segment that STARTS at that key (Blender / Roblox Pose semantics).

import math

# ------------------------------------------------------------------------------------------------ vectors / matrices

IDENTITY = (1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0)


def v_add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def v_sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def v_scale(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def v_dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def v_cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def v_len(a):
    return math.sqrt(v_dot(a, a))


def v_norm(a):
    n = v_len(a)
    if n < 1e-12:
        return (0.0, 0.0, 0.0)
    return (a[0] / n, a[1] / n, a[2] / n)


def m_mul(a, b):
    return (
        a[0] * b[0] + a[1] * b[3] + a[2] * b[6], a[0] * b[1] + a[1] * b[4] + a[2] * b[7], a[0] * b[2] + a[1] * b[5] + a[2] * b[8],
        a[3] * b[0] + a[4] * b[3] + a[5] * b[6], a[3] * b[1] + a[4] * b[4] + a[5] * b[7], a[3] * b[2] + a[4] * b[5] + a[5] * b[8],
        a[6] * b[0] + a[7] * b[3] + a[8] * b[6], a[6] * b[1] + a[7] * b[4] + a[8] * b[7], a[6] * b[2] + a[7] * b[5] + a[8] * b[8],
    )


def m_vec(m, v):
    return (m[0] * v[0] + m[1] * v[1] + m[2] * v[2], m[3] * v[0] + m[4] * v[1] + m[5] * v[2], m[6] * v[0] + m[7] * v[1] + m[8] * v[2])


def m_transpose(m):
    return (m[0], m[3], m[6], m[1], m[4], m[7], m[2], m[5], m[8])


def m_from_columns(x, y, z):
    return (x[0], y[0], z[0], x[1], y[1], z[1], x[2], y[2], z[2])


def rot_x(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return (1.0, 0.0, 0.0, 0.0, c, -s, 0.0, s, c)


def rot_y(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return (c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c)


def rot_z(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return (c, -s, 0.0, s, c, 0.0, 0.0, 0.0, 1.0)


def euler_xyz(x, y, z):
    """CFrame.Angles(rad(x), rad(y), rad(z)) as a rotation matrix (degrees in)."""
    return m_mul(m_mul(rot_x(x), rot_y(y)), rot_z(z))


def to_euler_xyz(m):
    """Inverse of euler_xyz: degrees (x, y, z) with m == Rx(x) Ry(y) Rz(z)."""
    sy = max(-1.0, min(1.0, m[2]))
    y = math.asin(sy)
    if abs(sy) < 0.999999:
        x = math.atan2(-m[5], m[8])
        z = math.atan2(-m[1], m[0])
    else:  # gimbal lock: put everything in x
        x = math.atan2(m[7], m[4])
        z = 0.0
    return (math.degrees(x), math.degrees(y), math.degrees(z))


def axis_angle(axis, deg):
    x, y, z = v_norm(axis)
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    t = 1.0 - c
    return (
        t * x * x + c, t * x * y - s * z, t * x * z + s * y,
        t * x * y + s * z, t * y * y + c, t * y * z - s * x,
        t * x * z - s * y, t * y * z + s * x, t * z * z + c,
    )


def rotation_between(a, b):
    """Smallest rotation taking direction a onto direction b."""
    a, b = v_norm(a), v_norm(b)
    d = max(-1.0, min(1.0, v_dot(a, b)))
    axis = v_cross(a, b)
    if v_len(axis) < 1e-9:
        if d > 0:
            return IDENTITY
        # 180 degrees about any axis perpendicular to a
        axis = v_cross(a, (1.0, 0.0, 0.0)) if abs(a[0]) < 0.9 else v_cross(a, (0.0, 0.0, 1.0))
        return axis_angle(axis, 180.0)
    return axis_angle(axis, math.degrees(math.acos(d)))


# ------------------------------------------------------------------------------------------------ quaternions (x, y, z, w)


def quat_from_matrix(m):
    r00, r01, r02, r10, r11, r12, r20, r21, r22 = m
    tr = r00 + r11 + r22
    if tr > 0:
        s = math.sqrt(tr + 1.0) * 2
        w, x, y, z = 0.25 * s, (r21 - r12) / s, (r02 - r20) / s, (r10 - r01) / s
    elif r00 > r11 and r00 > r22:
        s = math.sqrt(1.0 + r00 - r11 - r22) * 2
        w, x, y, z = (r21 - r12) / s, 0.25 * s, (r01 + r10) / s, (r02 + r20) / s
    elif r11 > r22:
        s = math.sqrt(1.0 + r11 - r00 - r22) * 2
        w, x, y, z = (r02 - r20) / s, (r01 + r10) / s, 0.25 * s, (r12 + r21) / s
    else:
        s = math.sqrt(1.0 + r22 - r00 - r11) * 2
        w, x, y, z = (r10 - r01) / s, (r02 + r20) / s, (r12 + r21) / s, 0.25 * s
    q = quat_normalize((x, y, z, w))
    if q[3] < 0:  # canonical: w >= 0
        q = (-q[0], -q[1], -q[2], -q[3])
    return q


def quat_normalize(q):
    n = math.sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3])
    if n < 1e-12:
        return (0.0, 0.0, 0.0, 1.0)
    return (q[0] / n, q[1] / n, q[2] / n, q[3] / n)


def quat_to_matrix(q):
    x, y, z, w = quat_normalize(q)
    return (
        1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w),
        2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w),
        2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y),
    )


def quat_dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3]


def nlerp(a, b, alpha, shortest=True):
    """Component lerp + normalise (what Blender does between quaternion keys; the runtime does the same)."""
    if shortest and quat_dot(a, b) < 0:
        b = (-b[0], -b[1], -b[2], -b[3])
    return quat_normalize(tuple(a[i] + (b[i] - a[i]) * alpha for i in range(4)))


# ------------------------------------------------------------------------------------------------ frames (R, p)


def cf(p=(0.0, 0.0, 0.0), r=IDENTITY):
    return (tuple(r), tuple(p))


def cf_from_components(c):
    return (tuple(c[3:12]), (c[0], c[1], c[2]))


def cf_components(f):
    r, p = f
    return [p[0], p[1], p[2]] + list(r)


def cf_mul(a, b):
    ra, pa = a
    rb, pb = b
    return (m_mul(ra, rb), v_add(m_vec(ra, pb), pa))


def cf_inv(a):
    r, p = a
    rt = m_transpose(r)
    return (rt, v_scale(m_vec(rt, p), -1.0))


def cf_point(a, v):
    r, p = a
    return v_add(m_vec(r, v), p)


# ------------------------------------------------------------------------------------------------ easing (Blender curves)

BACK_OVERSHOOT = 1.70158


def _bounce_out(t):
    if t < 1 / 2.75:
        return 7.5625 * t * t
    if t < 2 / 2.75:
        t -= 1.5 / 2.75
        return 7.5625 * t * t + 0.75
    if t < 2.5 / 2.75:
        t -= 2.25 / 2.75
        return 7.5625 * t * t + 0.9375
    t -= 2.625 / 2.75
    return 7.5625 * t * t + 0.984375


def _inout(f_in, f_out):
    # generic in-out built from the in / out halves (matches Blender for the polynomial / sine / circ families)
    def f(t):
        if t < 0.5:
            return f_in(t * 2) * 0.5
        return f_out(t * 2 - 1) * 0.5 + 0.5
    return f


def _back_in(t, s=BACK_OVERSHOOT):
    return t * t * ((s + 1) * t - s)


def _back_out(t, s=BACK_OVERSHOOT):
    t -= 1
    return t * t * ((s + 1) * t + s) + 1


def _back_inout(t):
    s = BACK_OVERSHOOT * 1.525
    t *= 2
    if t < 1:
        return 0.5 * (t * t * ((s + 1) * t - s))
    t -= 2
    return 0.5 * (t * t * ((s + 1) * t + s) + 2)


def _bounce_inout(t):
    if t < 0.5:
        return (1 - _bounce_out(1 - t * 2)) * 0.5
    return _bounce_out(t * 2 - 1) * 0.5 + 0.5


_FAMILIES = {
    "sine": (lambda t: 1 - math.cos(t * math.pi / 2), lambda t: math.sin(t * math.pi / 2), lambda t: -0.5 * (math.cos(math.pi * t) - 1)),
    "quad": (lambda t: t * t, lambda t: -t * (t - 2), None),
    "cubic": (lambda t: t ** 3, lambda t: (t - 1) ** 3 + 1, None),
    "quart": (lambda t: t ** 4, lambda t: -((t - 1) ** 4 - 1), None),
    "quint": (lambda t: t ** 5, lambda t: (t - 1) ** 5 + 1, None),
    "circ": (lambda t: -(math.sqrt(max(0.0, 1 - t * t)) - 1), lambda t: math.sqrt(max(0.0, 1 - (t - 1) ** 2)), None),
    "back": (_back_in, _back_out, _back_inout),
    "bounce": (lambda t: 1 - _bounce_out(1 - t), _bounce_out, _bounce_inout),
}

# name -> (curve, blender interpolation, blender easing)
EASINGS = {
    "linear": (lambda t: t, "LINEAR", "AUTO"),
    "constant": (lambda t: 0.0, "CONSTANT", "AUTO"),
}
for _family, (_fin, _fout, _finout) in _FAMILIES.items():
    EASINGS[_family + "_in"] = (_fin, _family.upper(), "EASE_IN")
    EASINGS[_family + "_out"] = (_fout, _family.upper(), "EASE_OUT")
    EASINGS[_family + "_inout"] = (_finout or _inout(_fin, _fout), _family.upper(), "EASE_IN_OUT")

# friendly aliases (the canonical name is what gets exported)
EASING_ALIASES = {
    "smooth": "sine_inout", "ease": "sine_inout", "sine": "sine_inout", "quad": "quad_inout", "cubic": "cubic_inout",
    "quart": "quart_inout", "quint": "quint_inout", "circ": "circ_inout", "back": "back_out", "bounce": "bounce_out",
    "snap": "quart_out", "hold": "constant", "step": "constant",
}

DEFAULT_EASING = "sine_inout"


def canonical_easing(name):
    if name is None:
        return DEFAULT_EASING
    name = EASING_ALIASES.get(name, name)
    if name not in EASINGS:
        raise ValueError("unknown easing %r (known: %s)" % (name, ", ".join(sorted(EASINGS))))
    return name


def ease(name, t):
    return EASINGS[canonical_easing(name)][0](max(0.0, min(1.0, t)))
