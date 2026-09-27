# scripts/tools/blender/hero_anim/gallery.py
# Renders every ready-made pose helper of api.py on the mannequin into assets/animations/preview/_pose_helpers.png
# (one labelled tile per helper) so an author can pick poses by eye:
#   "C:/Program Files/Blender Foundation/Blender 4.5/blender.exe" --background --factory-startup \
#       --python scripts/tools/blender/hero_anim/gallery.py

import os
import sys
import tempfile

sys.dont_write_bytecode = True  # keep __pycache__ out of the repo
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import bpy  # noqa: E402

from hero_anim import api, preview, rbx, rig  # noqa: E402


def poses():
    a = api
    return [
        ("rest()", a.rest()),
        ("tpose()", a.tpose()),
        ("arms_crossed()", a.arms_crossed()),
        ("fists_on_hips()", a.fists_on_hips()),
        ("guard()", a.guard()),
        ("fist_forward('Right')", a.fist_forward("Right")),
        ("point('Right')", a.point("Right")),
        ("wave('Right', 0.25)", a.wave("Right", 0.25)),
        ("power_up()", a.power_up()),
        ("charge_hands('Right')", a.charge_hands("Right")),
        ("thrust_palms()", a.thrust_palms()),
        ("crouch(0.6)", a.crouch(0.6)),
        ("spider_crouch()", a.spider_crouch()),
        ("fly_saiyan()", a.fly_saiyan()),
        ("fly_saiyan(lead='Right')", a.fly_saiyan(lead="Right")),
        ("fly_superman('Right')", a.fly_superman("Right")),
        ("hover_pose()", a.hover_pose()),
        ("web_swing('Right', 0)", a.web_swing("Right", 0.0)),
        ("web_swing('Right', 1)", a.web_swing("Right", 1.0)),
        ("web_shoot('Right')", a.web_shoot("Right")),
        ("run_cycle()[0]", a.run_cycle()[0.0]),
        ("stomp_cycle()[0]", a.stomp_cycle()[0.0]),
        ("hop_cycle() up", a.hop_cycle()[0.7 * 0.45]),
        ("walk_cycle()[0]", a.walk_cycle()[0.0]),
    ]


def apply_pose(built, pose):
    transforms = api.transforms_of(pose)
    for joint in api.JOINTS:
        r, p = transforms.get(joint, (rbx.IDENTITY, (0.0, 0.0, 0.0)))
        quat, loc = rig.transform_to_basis(joint, rbx.quat_from_matrix(r), p)
        pb = built.arm.pose.bones[joint]
        pb.rotation_quaternion = quat
        pb.location = loc
    bpy.context.view_layer.update()


def main():
    rig.clear_scene()
    built = rig.build(None)
    scene = bpy.context.scene
    preview.setup_look(scene)
    scene.render.resolution_x = scene.render.resolution_y = 300
    scene.render.image_settings.file_format = "PNG"
    cam = preview._camera(scene)
    tmp = tempfile.mkdtemp(prefix="hero_gallery_")
    tiles = []
    for i, (name, pose) in enumerate(poses()):
        apply_pose(built, pose)
        lo, hi = preview._bounds(built)
        lo.z = min(lo.z, 0.0)
        preview._place_camera(cam, "front34", frame=((lo + hi) * 0.5, max((hi - lo).length * 0.5, 2.6)))
        label = preview._label(cam, name)
        path = os.path.join(tmp, "%02d.png" % i)
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        bpy.data.objects.remove(label, do_unlink=True)
        tiles.append(preview._load_pixels(path))
    cols = 6
    rows = [tiles[i:i + cols] for i in range(0, len(tiles), cols)]
    os.makedirs(preview.PREVIEW_DIR, exist_ok=True)
    out = os.path.join(preview.PREVIEW_DIR, "_pose_helpers.png")
    preview._save_pixels(preview._grid(rows, cols, 300, 300), out)
    print("[hero_anim] pose helper gallery -> %s" % os.path.relpath(out, api.REPO_ROOT))


main()
