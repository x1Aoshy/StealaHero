"""After run.py --themes Volcano and verify_sunny.luau: validate FBX, bake the Roblox wind into
the editable .blend and render a closeup / optional 12-second MP4. Re-running is safe.
blender --background --factory-startup --python scripts/tools/blender/base_themes/finish_volcano.py -- --video
"""
import json
import os
import re
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pipeline as P

OUT = os.path.join(P.BASES_DIR, "Volcano")
NAME = "SunnyPirateWharf"
layout = json.load(open(os.path.join(OUT, NAME + ".json"), encoding="utf-8"))

# Round-trip the deliverable itself, including custom normals and separated animation groups.
P.clear_scene()
bpy.ops.import_scene.fbx(filepath=os.path.join(OUT, NAME + ".fbx"), use_custom_normals=True)
report = {}
for variant, data in layout["variants"].items():
    imported = [o for o in bpy.context.scene.objects if o.type == "MESH" and o.name.startswith(data["prefix"])]
    tris = sum(P.mesh_stats(o)[0] for o in imported)
    assert len(imported) == data["objects"] and tris == data["total_tris"], (variant, len(imported), tris)
    degenerate = sum(p.area < 1e-10 for o in imported for p in o.data.polygons)
    assert degenerate == 0, (variant, "degenerate triangles", degenerate)
    assert all(o.data.has_custom_normals for o in imported), "lost FBX custom normals"
    report[variant] = {"objects": len(imported), "triangles": tris, "custom_normals": True,
                       "degenerate_triangles": degenerate}
with open(os.path.join(OUT, "reference", "fbx-validation.json"), "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2)
print("[Sunny] FBX round trip:", report, flush=True)

bpy.ops.wm.open_mainfile(filepath=os.path.join(OUT, NAME + ".blend"))
# Remove previous preview rig / camera / lights when re-running, keeping mesh world-space rest positions.
for obj in list(bpy.context.scene.objects):
    if obj.type == "MESH" and obj.get("role"):
        obj.parent = None
        obj.matrix_world = Matrix.Translation((72.5 if obj.name.startswith("Deep_") else 0, 0, 0))
    elif obj.type != "MESH":
        bpy.data.objects.remove(obj, do_unlink=True)

data = json.load(open(os.path.join(OUT, "reference", "wind-samples.json"), encoding="utf-8"))
scene = bpy.context.scene
scene.render.fps = data["fps"]
scene.frame_start, scene.frame_end = 1, 360
Q = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
for variant, v in layout["variants"].items():
    shift = 72.5 if variant == "Deep" else 0
    origin = Matrix.Translation((shift, v["half_depth"] + 0.88, 8.3))
    root = bpy.data.collections.new(variant + "_SunnyAnimation")
    scene.collection.children.link(root)
    for group in ("Hull", "Main", "Aft", "Flag"):
        pivot = bpy.data.objects.new(variant + "_Sunny" + group + "_Wind", None)
        root.objects.link(pivot)
        pivot.empty_display_size = 0.3
        pivot.matrix_world = origin
        pivot.rotation_mode = "QUATERNION"
        for obj in list(scene.objects):
            if obj.type == "MESH" and obj.name.startswith(v["prefix"]) and "_Sunny" + group + "_" in obj.name:
                world = obj.matrix_world.copy()
                obj.parent = pivot
                obj.matrix_world = world
        for frame, sample in enumerate(data["samples"], 1):
            a = sample[group]
            pose = Matrix(((a[3], a[4], a[5], a[0]), (a[6], a[7], a[8], a[1]),
                           (a[9], a[10], a[11], a[2]), (0, 0, 0, 1)))
            pivot.matrix_world = origin @ Q @ pose @ Q.inverted()
            pivot.keyframe_insert("location", frame=frame)
            pivot.keyframe_insert("rotation_quaternion", frame=frame)
        action = pivot.animation_data.action
        action.name = variant + "_Sunny_" + group + "_12s"
        for curve in action.fcurves:
            for key in curve.keyframe_points:
                key.interpolation = "LINEAR"
            curve.modifiers.new("CYCLES")

for obj in scene.objects:
    if obj.name.startswith("Deep_"):
        obj.hide_render = True
scene.frame_set(1)
cam = P.setup_studio(width=1400, height=900, floor=False)
D = layout["variants"]["Std"]["half_depth"]
P.fit_camera(cam, (-7.5, D - 0.7, 7.5), (6.8, D + 2.4, 16.0), (0.42, -1.0, -0.16), 1400, 900, 0.05)
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == "VIEW_3D":
            area.spaces.active.region_3d.view_distance = 26
            area.spaces.active.region_3d.view_location = Vector((0, D, 11.5))
            area.spaces.active.region_3d.view_rotation = cam.rotation_euler.to_quaternion()
            area.spaces.active.shading.type = "MATERIAL"
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, NAME + ".blend"), compress=True)
P.render_to(os.path.join(OUT, "preview", NAME + "_sunny.png"), 1400, 900)
if "--video" in sys.argv:
    scene.render.resolution_x, scene.render.resolution_y = 960, 620
    scene.eevee.taa_render_samples = 8
    scene.eevee.use_raytracing = False
    scene.render.image_settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format = "MPEG4"
    scene.render.ffmpeg.codec = "H264"
    scene.render.ffmpeg.constant_rate_factor = "MEDIUM"
    scene.render.filepath = os.path.join(OUT, "preview", NAME + "_wind.mp4")
    bpy.ops.render.render(animation=True)
print("[Sunny] Editable Blender wind actions and previews ready", flush=True)
