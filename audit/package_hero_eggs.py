"""Package the current library and verify the ASCII backup matches byte-for-byte."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import zipfile

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'eggs'
PUBLIC=Path('C:/Users/Public/HeroEggs')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    manifest=json.loads((OUT/'manifest.json').read_text())
    validation=json.loads((OUT/'validation.json').read_text())
    textures=json.loads((OUT/'texture_validation.json').read_text())
    catalog=(ROOT/'src/ReplicatedStorage/Directory/HeroCatalog.luau').read_text(encoding='utf-8')
    expected=set(re.findall(r'Id = "([A-Za-z0-9]+)"',catalog))
    actual={a['hero_id'] for a in manifest['assets']}
    assert expected==actual and len(actual)==44, (expected-actual,actual-expected)
    assert validation['all_passed'] and validation['count']==44
    assert textures['all_passed'] and textures['count']==44
    for name in ('HeroEggsKit.blend','README.md','manifest.json','validation.json','texture_validation.json','RobloxMaterialGuide.json'):
        shutil.copy2(OUT/name,PUBLIC/name)
    for name in ('generate_voxel_eggs_bpy.py','generate_stud_textures.py','compose_egg_previews.py','verify_egg_textures_bpy.py','package_hero_eggs.py'):
        shutil.copy2(ROOT/'audit'/name,PUBLIC/name)
    files=[]
    for p in sorted((OUT/'fbx').glob('*.fbx')):
        mirror=PUBLIC/'fbx'/p.name
        assert sha(p)==sha(mirror),p.name
        files.append({'file':'fbx/'+p.name,'bytes':p.stat().st_size,'sha256':sha(p)})
    assert sha(OUT/'HeroEggsKit.blend')==sha(PUBLIC/'HeroEggsKit.blend')
    report={'revision':3,'catalog_match':True,'asset_count':44,'heroes':38,'bosses':6,'ascii_backup_matches':True,
        'fbx_reimport_passed':True,'embedded_texture_validation_passed':True,'roblox_studio_validation':'Not run',
        'triangle_range':[min(a['triangles'] for a in manifest['assets']),max(a['triangles'] for a in manifest['assets'])],
        'files':files}
    for directory in (OUT,PUBLIC): (directory/'delivery_audit.json').write_text(json.dumps(report,indent=2),encoding='ascii')
    package=OUT/'HeroEggs_FBX_Textures.zip'
    with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as archive:
        for folder in ('fbx','textures'):
            for p in sorted((OUT/folder).glob('*')):
                if p.is_file(): archive.write(p,str(p.relative_to(OUT)))
        for name in ('README.md','manifest.json','validation.json','texture_validation.json','RobloxMaterialGuide.json','delivery_audit.json'):
            archive.write(OUT/name,name)
    shutil.copy2(package,PUBLIC/package.name)
    print(json.dumps({k:v for k,v in report.items() if k!='files'},indent=2))
    print('ZIP bytes',package.stat().st_size)

if __name__=='__main__': main()
