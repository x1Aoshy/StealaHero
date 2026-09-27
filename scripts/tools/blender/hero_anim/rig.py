# scripts/tools/blender/hero_anim/rig.py
# Builds the "HeroRig" armature from assets/animations/r15_rig.json: one bone per Motor6D (named like the joint),
# blocky R15 mannequin meshes (one object per body part, named like the part) parented to the bones, per-hero colours.
#
# Axis mapping (Roblox rig space <-> Blender world, 1 stud = 1 Blender unit):
#   Blender (x, y, z) = M * Roblox (x, y, z) with M = [[-1, 0, 0], [0, 0, 1], [0, 1, 0]]   (M is its own inverse)
#   so the hero faces Blender -Y (Front view), its left side is Blender +X, up is +Z.
# Frames: a Roblox frame F (rotation R, position p, Roblox-local axes) is the Blender matrix M4 @ F: its columns keep
# the Roblox local axes, so a part mesh is modelled in Roblox part-local coordinates and a part's CFrame comes back
# as M4 @ matrix_world.
# Bones: bone rest matrix (armature space) = M4 @ J_rest @ Q, J_rest = the joint frame (Part0 * C0) at rest and Q a
# fixed per-bone rotation that points the bone's Y axis along the limb: Q = I for Root / Waist / Neck (bone points up),
# Q = Rx(180 deg) for arm and leg joints (bone points down). Then Motor6D.Transform T and the pose bone's
# matrix_basis B relate as T = Q @ B @ Q^-1 (see export.py): for down bones the quaternion (w, x, y, z) of B is
# (w, x, -y, -z) of T and the location flips y / z the same way.

import math

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

from . import api, rbx

M3 = Matrix(((-1.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)))
M4 = M3.to_4x4()
UP_BONES = ("Root", "Waist", "Neck")
Q_DOWN = Matrix.Rotation(math.pi, 4, "X")


def q_of(joint):
    return Matrix.Identity(4) if joint in UP_BONES else Q_DOWN.copy()


def frame_to_matrix(f):
    """rbx (R, p) -> 4x4 Matrix (Roblox coordinates)."""
    r, p = f
    return Matrix(((r[0], r[1], r[2], p[0]), (r[3], r[4], r[5], p[1]), (r[6], r[7], r[8], p[2]), (0.0, 0.0, 0.0, 1.0)))


def matrix_to_frame(m):
    return ((m[0][0], m[0][1], m[0][2], m[1][0], m[1][1], m[1][2], m[2][0], m[2][1], m[2][2]), (m[0][3], m[1][3], m[2][3]))


def blender_from_roblox(f):
    return M4 @ frame_to_matrix(f)


def roblox_from_blender(m):
    return matrix_to_frame(M4 @ m)


def transform_to_basis(joint, q_xyzw, p):
    """Motor6D.Transform (quaternion x, y, z, w + position) -> pose bone (Quaternion w, x, y, z; location Vector)."""
    x, y, z, w = q_xyzw
    if joint in UP_BONES:
        return Quaternion((w, x, y, z)), Vector(p)
    return Quaternion((w, x, -y, -z)), Vector((p[0], -p[1], -p[2]))


def basis_to_transform(joint, quat, loc):
    """Inverse of transform_to_basis: pose bone -> ((qx, qy, qz, qw), (px, py, pz))."""
    w, x, y, z = quat[0], quat[1], quat[2], quat[3]
    if joint in UP_BONES:
        return (x, y, z, w), (loc[0], loc[1], loc[2])
    return (x, -y, -z, w), (loc[0], -loc[1], -loc[2])


# ------------------------------------------------------------------------------------------------ scene


def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.armatures, bpy.data.materials, bpy.data.actions, bpy.data.curves,
                 bpy.data.cameras, bpy.data.lights, bpy.data.images):
        for block in list(coll):
            try:
                coll.remove(block)
            except (RuntimeError, ReferenceError):
                pass


_MATERIALS = {}


def material(color, emissive=False, name=None, roughness=0.55):
    key = (tuple(int(c) for c in color), emissive)
    mat = _MATERIALS.get(key)
    if mat is not None and mat.name in bpy.data.materials:
        return mat
    mat = bpy.data.materials.new(name or "Mat_%d_%d_%d%s" % (key[0] + ("_E" if emissive else "",)))
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    rgb = tuple((c / 255.0) ** 2.2 for c in key[0]) + (1.0,)
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = rgb
        bsdf.inputs["Roughness"].default_value = roughness
        if emissive:
            bsdf.inputs["Emission Color"].default_value = rgb
            bsdf.inputs["Emission Strength"].default_value = 6.0
    mat.diffuse_color = rgb
    _MATERIALS[key] = mat
    return mat


def _box_mesh(name, size, bevel=0.07):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    if bevel > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=min(bevel, min(size) * 0.3), segments=2, affect="EDGES", profile=0.5)
    bm.to_mesh(mesh)
    bm.free()
    return mesh


def _head_mesh(name, size):
    """Classic Roblox head: a bevelled cylinder along local Y, radius ~0.6 for a 2x1x1 head part."""
    radius = 0.6 * size[1]
    height = 1.2 * size[1]
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=20, radius1=radius, radius2=radius, depth=height)
    # the cone is built along Z: turn it to Y (Roblox up in part-local coordinates)
    bmesh.ops.rotate(bm, verts=bm.verts, matrix=Matrix.Rotation(math.pi / 2, 3, "X"))
    bmesh.ops.bevel(bm, geom=[e for e in bm.edges if len(e.link_faces) == 2 and abs(e.calc_face_angle(0)) > 0.8],
                    offset=0.14 * size[1], segments=3, affect="EDGES", profile=0.5)
    bm.to_mesh(mesh)
    bm.free()
    return mesh


def _shape_mesh(name, shape, size):
    if shape == "box":
        return _box_mesh(name, size, bevel=0.04)
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    if shape == "sphere":
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.5)
        for v in bm.verts:
            v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    elif shape in ("cone", "spikes"):
        spikes = 1 if shape == "cone" else 5
        for i in range(spikes):
            geo = bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=0.5, radius2=0.0, depth=1.0)
            verts = geo["verts"]
            # cone along local +Y (Roblox up), base at y = 0
            bmesh.ops.rotate(bm, verts=verts, matrix=Matrix.Rotation(-math.pi / 2, 3, "X"))
            bmesh.ops.translate(bm, verts=verts, vec=Vector((0.0, 0.5, 0.0)))
            for v in verts:
                v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
            if spikes > 1:
                ang = (i - (spikes - 1) / 2) * 0.42
                bmesh.ops.rotate(bm, verts=verts, matrix=Matrix.Rotation(ang, 3, "Z") @ Matrix.Rotation(-0.15 * abs(i - 2), 3, "X"))
    else:
        raise ValueError("unknown extra shape %r" % shape)
    bm.to_mesh(mesh)
    bm.free()
    return mesh


def _face(head_obj, size, color=(25, 25, 30)):
    """Two eyes and a smirk on the head's front (-Z Roblox local) so the facing reads in previews."""
    radius = 0.6 * size[1]
    mat = material(color)
    for sx in (-0.2, 0.2):
        eye = bpy.data.objects.new(head_obj.name + "_Eye", _box_mesh("Eye", (0.13, 0.22, 0.06), bevel=0.02))
        eye.data.materials.append(mat)
        bpy.context.scene.collection.objects.link(eye)
        eye.parent = head_obj
        eye.matrix_parent_inverse = Matrix.Identity(4)
        eye.location = Vector((sx * size[1], 0.1 * size[1], -radius + 0.005))
    mouth = bpy.data.objects.new(head_obj.name + "_Mouth", _box_mesh("Mouth", (0.3, 0.05, 0.06), bevel=0.01))
    mouth.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(mouth)
    mouth.parent = head_obj
    mouth.matrix_parent_inverse = Matrix.Identity(4)
    mouth.location = Vector((0.05 * size[1], -0.22 * size[1], -radius + 0.005))
    mouth.rotation_euler = (0.0, 0.0, 0.12)


class BuiltRig:
    def __init__(self, arm, parts, bone_len):
        self.arm = arm
        self.parts = parts  # part name -> mesh object (HumanoidRootPart included, hidden)
        self.bone_len = bone_len


def build(hero=None, name="HeroRig"):
    """Build the armature + mannequin at the origin (soles on z = 0). hero: api.Hero (colours / extras) or None."""
    r = api.rig()
    scene = bpy.context.scene
    arm_data = bpy.data.armatures.new(name)
    arm = bpy.data.objects.new(name, arm_data)
    scene.collection.objects.link(arm)
    arm.show_in_front = True
    arm_data.display_type = "OCTAHEDRAL"
    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)

    _, rest_joints = r.fk({})
    bone_len = {}
    for j in r.joints:
        child = r.child_joint(j["name"])
        if child is not None:
            length = rbx.v_len(rbx.v_sub(rest_joints[child][1], rest_joints[j["name"]][1]))
        else:
            length = r.parts[j["part1"]]["size"][1] * 0.8
        bone_len[j["name"]] = max(length, 0.2)

    bpy.ops.object.mode_set(mode="EDIT")
    ebones = arm_data.edit_bones
    for j in r.joints:
        eb = ebones.new(j["name"])
        eb.head = (0.0, 0.0, 0.0)
        eb.tail = (0.0, bone_len[j["name"]], 0.0)
        eb.matrix = blender_from_roblox(rest_joints[j["name"]]) @ q_of(j["name"])
        parent = r.parent_joint[j["name"]]
        if parent is not None:
            eb.parent = ebones[parent]
            eb.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"

    colors = (hero.colors if hero is not None else None) or {}
    rest_parts, _ = r.fk({})
    parts = {}
    for part_name, part in r.parts.items():
        size = part["size"]
        if part["shape"] == "head":
            mesh = _head_mesh(part_name, size)
        else:
            mesh = _box_mesh(part_name, size)
        obj = bpy.data.objects.new(part_name, mesh)
        scene.collection.objects.link(obj)
        col = colors.get(part_name, (200, 200, 205))
        mesh.materials.append(material(col))
        for poly in mesh.polygons:
            poly.use_smooth = False
        world = blender_from_roblox(rest_parts[part_name])
        if part_name == "HumanoidRootPart":
            obj.parent = arm
            obj.matrix_parent_inverse = Matrix.Identity(4)
            obj.matrix_basis = world
            obj.hide_render = True
            obj.display_type = "WIRE"
        else:
            joint = r.joint_of_part[part_name]
            obj.parent = arm
            obj.parent_type = "BONE"
            obj.parent_bone = joint
            obj.matrix_parent_inverse = Matrix.Identity(4)
            bone = arm_data.bones[joint]
            tail = bone.matrix_local @ Matrix.Translation((0.0, bone.length, 0.0))
            obj.matrix_basis = tail.inverted() @ world
        parts[part_name] = obj
        if part_name == "Head":
            _face(obj, size)

    if hero is not None:
        for i, e in enumerate(hero.extras):
            if e["part"] not in parts:
                raise ValueError("%s: extra on unknown part %r" % (hero.id, e["part"]))
            mesh = _shape_mesh("Extra%d" % i, e["shape"], e["size"])
            obj = bpy.data.objects.new("Extra%d_%s" % (i, e["part"]), mesh)
            scene.collection.objects.link(obj)
            mesh.materials.append(material(e["color"], e["emissive"]))
            obj.parent = parts[e["part"]]
            obj.matrix_parent_inverse = Matrix.Identity(4)
            local = rbx.cf(e["offset"], rbx.euler_xyz(*e["rot"]))
            obj.matrix_basis = frame_to_matrix(local)
    bpy.context.view_layer.update()
    return BuiltRig(arm, parts, bone_len)


def check_rest(built):
    """Rest-pose self test: every mannequin part sits where the rig JSON says (Blender <-> Roblox mapping)."""
    r = api.rig()
    rest_parts, _ = r.fk({})
    for pb in built.arm.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = Vector()
    bpy.context.view_layer.update()
    worst = 0.0
    for name, obj in built.parts.items():
        got = roblox_from_blender(obj.matrix_world)
        want = rest_parts[name]
        worst = max(worst, rbx.v_len(rbx.v_sub(got[1], want[1])))
        for i in range(9):
            worst = max(worst, abs(got[0][i] - want[0][i]))
    return worst
