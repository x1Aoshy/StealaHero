"""Independently audit FBX UVs, shader texture links, and embedded media."""
import bpy
import json
import math
import shutil
import importlib.util
from pathlib import Path
from io_scene_fbx import parse_fbx

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'eggs'
PUBLIC=Path('C:/Users/Public/HeroEggs')
def descendants(elem):
    yield elem
    for child in elem.elems: yield from descendants(child)

def main():
    records=[]
    for filepath in sorted((OUT/'fbx').glob('*.fbx')):
        for obj in list(bpy.data.objects): bpy.data.objects.remove(obj,do_unlink=True)
        root,version=parse_fbx.parse(str(filepath))
        embedded=[len(e.props[0]) for e in descendants(root) if e.id==b'Content' and e.props and isinstance(e.props[0],bytes) and e.props[0]]
        bpy.ops.import_scene.fbx(filepath=str(filepath))
        objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
        material_checks=[]
        for obj in objects:
            for mat in obj.data.materials:
                p=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
                images=[n.image for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
                normal_nodes=[n for n in mat.node_tree.nodes if n.type=='NORMAL_MAP']
                material_checks.append({'name':mat.name,'albedo_linked':bool(p and p.inputs['Base Color'].is_linked),
                    'normal_linked':bool(p and p.inputs['Normal'].is_linked and normal_nodes),
                    'image_count':len(images),'all_images_available':all(im.size[0]>0 for im in images)})
        uv_ok=all(o.data.uv_layers and all(math.isfinite(c) for loop in o.data.uv_layers.active.data for c in loop.uv) for o in objects)
        r={'hero_id':filepath.stem.removesuffix('_Egg'),'has_finite_uvs':bool(uv_ok),'embedded_texture_count':len(embedded),
            'embedded_texture_bytes':sum(embedded),'materials':material_checks}
        r['passed']=bool(objects and uv_ok and embedded and material_checks and all(m['albedo_linked'] and m['normal_linked'] and m['all_images_available'] for m in material_checks))
        records.append(r)
        print('TEXTURE_CHECK',r['hero_id'],r['passed'],len(embedded),flush=True)
    result={'all_passed':all(r['passed'] for r in records),'count':len(records),'checks':records}
    for dest in (OUT,PUBLIC): (dest/'texture_validation.json').write_text(json.dumps(result,indent=2),encoding='ascii')
    # Render an independently imported FBX as visual confirmation of the maps.
    for obj in list(bpy.data.objects): bpy.data.objects.remove(obj,do_unlink=True)
    bpy.ops.import_scene.fbx(filepath=str(OUT/'fbx'/'Luffy_Egg.fbx'))
    obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    spec=importlib.util.spec_from_file_location('egg_generator',ROOT/'audit'/'generate_voxel_eggs_bpy.py')
    generator=importlib.util.module_from_spec(spec); spec.loader.exec_module(generator)
    cam,_=generator.setup_studio(bpy.context.scene)
    checkdir=ROOT/'audit'/'egg_checks'; checkdir.mkdir(exist_ok=True)
    generator.render_one(bpy.context.scene,cam,obj,checkdir/'Luffy_FBX_Reimport.png')
    if not result['all_passed']: raise RuntimeError('Texture verification failed')
    print('TEXTURE_VALIDATION_COMPLETE',len(records),flush=True)

if __name__=='__main__': main()
