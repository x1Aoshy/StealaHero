"""Generate seamless Roblox-style recessed square-stud PBR tiles.

No photographic input: exact repeatable height profile, tangent normals, and
palette-colored albedo maps. Export textures are written to the ASCII path first.
"""
import ast
import json
import math
import shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'eggs'/'textures'
PUBLIC=Path('C:/Users/Public/HeroEggs/textures')
def smoothstep(a,b,x):
    t=np.clip((x-a)/(b-a),0,1)
    return t*t*(3-2*t)

def main():
    OUT.mkdir(parents=True,exist_ok=True); PUBLIC.mkdir(parents=True,exist_ok=True)
    tree=ast.parse((ROOT/'audit'/'generate_voxel_eggs_bpy.py').read_text(encoding='utf-8'))
    colors=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='COLORS' for t in n.targets))
    n=256; uv=(np.arange(n)+.5)/n-.5; x,y=np.meshgrid(uv,uv)
    # Rounded square inlet: a narrow raised lip, shallow recessed center, flat
    # surroundings. The wide quiet margins exactly repeat across tile borders.
    corner=.045
    qx=np.abs(x)-(.315-corner); qy=np.abs(y)-(.315-corner)
    distance=np.sqrt(np.maximum(qx,0)**2+np.maximum(qy,0)**2)+np.minimum(np.maximum(qx,qy),0)-corner
    outer=1-smoothstep(-.005,.028,distance)
    inner=1-smoothstep(-.067,-.040,distance)
    height=.5+.30*outer-.48*inner
    # Height amplitude is 0.025 studs across one 0.30 stud tile.
    dzdu=(np.roll(height,-1,axis=1)-np.roll(height,1,axis=1))*(n/2)*(.025/.30)
    dzdv=-(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0))*(n/2)*(.025/.30)
    normal=np.stack([-dzdu,-dzdv,np.ones_like(height)],axis=-1)
    normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
    Image.fromarray(np.uint8(np.clip((normal*.5+.5)*255,0,255))).save(PUBLIC/'Stud_Normal.png')
    Image.fromarray(np.uint8(height*255)).save(PUBLIC/'Stud_Height.png')
    roughness=.50+.045*inner-.05*np.clip(outer-inner,0,1)
    Image.fromarray(np.uint8(roughness*255)).save(PUBLIC/'Stud_Roughness.png')
    # Albedo is nearly flat: bevel illumination comes from the true normal map.
    factor=1-.045*inner-.015*np.maximum(0,outer-inner)
    for key,hx in colors.items():
        rgb=np.array([int(hx[i:i+2],16) for i in (0,2,4)])
        pixels=np.clip(factor[...,None]*rgb,0,255).astype('uint8')
        Image.fromarray(pixels).save(PUBLIC/('HE_'+key+'_Stud.png'))
    # A lit tiled material swatch documents the actual PBR surface.
    light=np.array([-.45,.58,1.0]); light/=np.linalg.norm(light)
    shade=.63+.42*np.maximum(0,np.sum(normal*light,axis=-1))
    rgb=np.array([108,179,50]); lit=np.clip(shade[...,None]*rgb*factor[...,None],0,255).astype('uint8')
    swatch=Image.fromarray(np.tile(lit,(4,4,1)))
    canvas=Image.new('RGB',(1280,1190),'#0B1321'); canvas.paste(swatch,(128,128))
    d=ImageDraw.Draw(canvas); f=ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf',34)
    d.text((128,42),'ROBLOX-STYLE SQUARE STUD / INLET',font=f,fill='#EFF6FF')
    d.text((128,1149),'UV tile + tangent normal + roughness',font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',23),fill='#9BAEC5')
    canvas.save(PUBLIC/'Stud_MaterialPreview.png')
    for p in PUBLIC.glob('*.png'): shutil.copy2(p,OUT/p.name)
    (OUT/'texture_info.json').write_text(json.dumps({'tile_pixels':256,'tile_size_studs':.30,'height_amplitude_studs':.025,'normal_convention':'OpenGL tangent-space +Y','albedo_color_space':'sRGB','normal_roughness_color_space':'Non-Color','geometry_studs':False,'style':'Rounded square inset with beveled lip, based on user gameplay reference'},indent=2),encoding='ascii')
    shutil.copy2(OUT/'texture_info.json',PUBLIC/'texture_info.json')
    print('Generated',len(list(OUT.glob('*.png'))),'texture PNGs and material swatch.')

if __name__=='__main__': main()
