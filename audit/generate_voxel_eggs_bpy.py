"""Steal a Hero: deterministic, editable voxel egg library for Blender 4.5.

Run: blender -b --factory-startup --python audit/generate_voxel_eggs_bpy.py
Optional args after --: --only Luffy,Zoro --no-render --no-validate
All FBX writes go through the ASCII-only PUBLIC folder before project copies.
One Blender unit = one stud; TOTAL asset height is 3.2 * boss scale.
Front is -Y, up is Z, origin is ground center. No external texture dependencies.
Art direction revision 3: NO FACES. Broad voxel tiers with UV-mapped square-stud PBR texture.
"""
import argparse
import bpy
import bmesh
import json
import math
import os
import shutil
import sys
import time
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'eggs'
PUBLIC = Path('C:/Users/Public/HeroEggs')
STAGES = ['Avengers', 'JusticeLeague', 'SpiderVerse', 'MyHeroAcademia', 'DragonBall', 'OnePiece']
ROSTER = [
 ('Hawkeye',1,'Common',1),('BlackWidow',1,'Common',1),('CaptainAmerica',1,'Rare',1),
 ('Hulk',1,'Epic',1),('Thor',1,'Legendary',1),('IronMan',1,'Mythic',1),('Thanos',1,'Boss',1.6),
 ('Aquaman',2,'Common',1),('GreenLantern',2,'Common',1),('Flash',2,'Rare',1),
 ('WonderWoman',2,'Epic',1),('Batman',2,'Legendary',1),('Superman',2,'Mythic',1),('Darkseid',2,'Boss',1.5),
 ('PeterParker',3,'Common',1),('SpiderGwen',3,'Common',1),('MilesMorales',3,'Rare',1),
 ('SpiderMan2099',3,'Epic',1),('AgentVenom',3,'Legendary',1),('Venom',3,'Mythic',1),('Carnage',3,'Boss',1.2),
 ('Uraraka',4,'Common',1),('Bakugo',4,'Common',1),('Todoroki',4,'Rare',1),
 ('Hawks',4,'Epic',1),('Deku',4,'Legendary',1),('AllMight',4,'Mythic',1),('Shigaraki',4,'Boss',1.1),
 ('Krillin',5,'Common',1),('Trunks',5,'Common',1),('Piccolo',5,'Rare',1),
 ('Gohan',5,'Epic',1),('Vegeta',5,'Legendary',1),('Goku',5,'Mythic',1),('Frieza',5,'Boss',1),
 ('Usopp',6,'Common',1),('Nami',6,'Common',1),('Brook',6,'Rare',1),('Sanji',6,'Rare',1),
 ('Zoro',6,'Epic',1),('Shanks',6,'Legendary',1),('Luffy',6,'Mythic',1),('JoyBoy',6,'Secret',1),('Kaido',6,'Boss',1.9),
]
COLORS = {
 'coal':'101626','black':'070B12','graphite':'303C50','steel':'657A91','silver':'C7D7E3',
 'white':'F2F5F8','pearl':'FFF5E8','skin':'F4BB8D','skinshade':'C67E58','brown':'603729',
 'auburn':'A22F20','red':'D82236','scarlet':'F34342','wine':'70172E','orange':'F98626',
 'gold':'EEB534','yellow':'FFDC55','straw':'F1CC61','strawshade':'C49032','blue':'205ED1',
 'navy':'142C69','teal':'179B8C','cyan':'54DCEF','green':'36A755','jade':'238743',
 'darkgreen':'104838','lime':'96DB51','purple':'713CA6','lavender':'B89DDF','pink':'F286B3',
 'magenta':'D62D7E','bone':'DFD5BF','stone':'75808F','tan':'B68952',
 'glowcyan':'7FEFFF','glowgreen':'6AFFA1','glowred':'FF382B','glowgold':'FFECA3',
 'gemblue':'238BFF','gempurple':'C26FFF',
}
MATS = {}
GEOMETRIC_STUDS = False

def linear(c):
    c = c / 255
    return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4

def materials():
    for key, hx in COLORS.items():
        rgb = tuple(linear(int(hx[i:i+2],16)) for i in (0,2,4))
        mat = bpy.data.materials.new('HE_' + key)
        mat.use_nodes = True
        mat.diffuse_color = (*rgb,1)
        p = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        p.inputs['Base Color'].default_value = (*rgb,1)
        p.inputs['Roughness'].default_value = .31 if key in ('gold','silver','black') else .52
        p.inputs['Metallic'].default_value = .32 if key in ('gold','silver','steel') else 0
        nodes=mat.node_tree.nodes; links=mat.node_tree.links
        for map_type,filename in [('albedo','HE_'+key+'_Stud.png'),('normal','Stud_Normal.png'),('roughness','Stud_Roughness.png')]:
            texture_path=PUBLIC/'textures'/filename
            if not texture_path.exists(): raise RuntimeError('Generate stud textures first: audit/generate_stud_textures.py')
            image=bpy.data.images.load(str(texture_path),check_existing=True)
            tex=nodes.new('ShaderNodeTexImage'); tex.image=image
            tex.label='Roblox_Stud_'+map_type
            if map_type=='albedo': links.new(tex.outputs['Color'],p.inputs['Base Color'])
            elif map_type=='normal':
                image.colorspace_settings.name='Non-Color'
                normal=nodes.new('ShaderNodeNormalMap'); normal.inputs['Strength'].default_value=.82
                links.new(tex.outputs['Color'],normal.inputs['Color']); links.new(normal.outputs['Normal'],p.inputs['Normal'])
            else:
                image.colorspace_settings.name='Non-Color'
                links.new(tex.outputs['Color'],p.inputs['Roughness'])
        if key.startswith('glow') or key.startswith('gem'):
            p.inputs['Emission Color'].default_value = (*rgb,1)
            p.inputs['Emission Strength'].default_value = 2.1
        mat['RobloxMaterial'] = 'Neon' if key.startswith(('glow','gem')) else 'SmoothPlastic'
        MATS[key] = mat

class Builder:
    def __init__(self, hero):
        self.hero = hero
        self.verts = []
        self.faces = []
        self.mats = []
        self.palette = []
        self.features = []
        self.stud_count = 0
        self.front_surfaces = []

    def mount_y(self,x,y,z,depth):
        # Seat thin front decoration on the surface already built underneath it.
        # Existing plates are considered too, so stacked emblems keep their order.
        if not (-.96<=x<=.96 and .5<=z<=2.74 and y<-.60 and depth<=.35): return y
        surfaces=[p[4] for p in self.front_surfaces if p[0]-.005<=x<=p[1]+.005 and p[2]-.005<=z<=p[3]+.005]
        if not surfaces: return y
        return max(y,min(surfaces)-depth/2+.008)

    def stud(self, center, axis, sign, color, size=.115):
        # Low-poly square Roblox-style button. Built-in chamfers; excluded from
        # the weighted bevel on the main assembly.
        if not GEOMETRIC_STUDS: return
        if not hasattr(self,'stud_specs'): self.stud_specs=[]
        self.stud_specs.append((center,axis,sign,color,size))
        self.stud_count+=1

    def build_stud_geometry(self):
        for center,axis,sign,color,size in getattr(self,'stud_specs',[]):
            u,v=(axis+1)%3,(axis+2)%3; r=size/2; chamfer=.012
            outline=[(-r+chamfer,-r),(r-chamfer,-r),(r,-r+chamfer),(r,r-chamfer),(r-chamfer,r),(-r+chamfer,r),(-r,r-chamfer),(-r,-r+chamfer)]
            bottom=[]; top=[]
            for a,b in outline:
                p=list(center); p[u]+=a; p[v]+=b; p[axis]-=sign*.005; bottom.append(tuple(p))
                p=list(center); p[u]+=a*.85; p[v]+=b*.85; p[axis]+=sign*.030; top.append(tuple(p))
            if sign<0: bottom.reverse(); top.reverse()
            for i in range(8): self.face([bottom[i],bottom[(i+1)%8],top[(i+1)%8],top[i]],color)
            self.face(top,color)

    def tag(self, name):
        self.features.append(name)

    def face(self, vertices, color):
        if len(vertices)>=3 and max(p[1] for p in vertices)-min(p[1] for p in vertices)<.00001:
            a,c,d=vertices[:3]
            ny=(c[2]-a[2])*(d[0]-a[0])-(c[0]-a[0])*(d[2]-a[2])
            if ny<-.000001:
                self.front_surfaces.append((min(p[0] for p in vertices),max(p[0] for p in vertices),min(p[2] for p in vertices),max(p[2] for p in vertices),a[1]))
        n = len(self.verts)
        self.verts.extend(vertices)
        self.faces.append(tuple(range(n, n+len(vertices))))
        if color not in self.palette:
            self.palette.append(color)
        self.mats.append(self.palette.index(color))

    def box(self, p, size, color, rotation=0):
        x,y,z=p; a,b,c=[v/2 for v in size]
        if rotation==0: y=self.mount_y(x,y,z,size[1])
        points=[(-a,-b,-c),(a,-b,-c),(a,b,-c),(-a,b,-c),(-a,-b,c),(a,-b,c),(a,b,c),(-a,b,c)]
        co,si=math.cos(rotation),math.sin(rotation)
        points=[(x+vx*co+vz*si,y+vy,z-vx*si+vz*co) for vx,vy,vz in points]
        for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]:
            self.face([points[i] for i in f],color)
        if rotation==0:
            # The repeating stud finish also continues over larger outfit panels.
            if size[0]>=.34 and size[2]>=.31:
                nx=max(1,int((size[0]-.10)/.29)); nz=max(1,int((size[2]-.10)/.29))
                for i in range(nx):
                    for j in range(nz): self.stud((x+(i-(nx-1)/2)*.29,y-b,z+(j-(nz-1)/2)*.29),1,-1,color,.095)
            if size[0]>=.34 and size[1]>=.34:
                nx=max(1,int((size[0]-.10)/.29)); ny=max(1,int((size[1]-.10)/.29))
                for i in range(nx):
                    for j in range(ny): self.stud((x+(i-(nx-1)/2)*.29,y+(j-(ny-1)/2)*.29,z+c),2,1,color,.095)

    def beam(self, a,b,width,color,depth=None,_mount=True):
        a,b=Vector(a),Vector(b)
        if _mount and width<.36 and max(a.y,b.y)<-.75 and max(abs(a.x),abs(b.x))<.96 and min(a.z,b.z)>.50 and max(a.z,b.z)<2.74:
            count=max(1,math.ceil((b-a).length/.12))
            if count>1:
                points=[a.lerp(b,i/count) for i in range(count+1)]
                for p in points: p.y=self.mount_y(p.x,p.y,p.z,depth or width)
                for p,q in zip(points,points[1:]): self.beam(p,q,width,color,depth,_mount=False)
                return
            a.y=self.mount_y(a.x,a.y,a.z,depth or width)
            b.y=self.mount_y(b.x,b.y,b.z,depth or width)
        delta=b-a
        q=delta.to_track_quat('Z','Y')
        r=width/2; d=(depth or width)/2; h=delta.length/2
        points=[(q @ Vector(v))+(a+b)/2 for v in [(-r,-d,-h),(r,-d,-h),(r,d,-h),(-r,d,-h),(-r,-d,h),(r,-d,h),(r,d,h),(-r,d,h)]]
        for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]:
            self.face([tuple(points[i]) for i in f],color)

    def line(self, points, width, color):
        for a,b in zip(points,points[1:]): self.beam(a,b,width,color)

    def pixel(self, rows, center, step, color, depth=.075, palette=None):
        x,y,z=center
        y=self.mount_y(x,y,z,depth)
        cells={}
        for j,row in enumerate(rows):
            for i,c in enumerate(row):
                if c not in (' ','.','0'):
                    cells[i,0,-j]=palette[c] if palette else color
        start=len(self.verts); origin=(x-len(rows[0])*step/2,y-depth/2,z+(len(rows)/2-1)*step)
        self.vox(cells,step,origin)
        for k in range(start,len(self.verts)):
            a,b,c=self.verts[k]; self.verts[k]=(a,origin[1]+(b-origin[1])*depth/step,c)

    def vox(self, cells, step, origin=(0,0,0)):
        # Greedy-merge exposed coplanar voxel faces, by color. Interior faces omitted.
        ox,oy,oz=origin
        for axis in range(3):
            u,v=(axis+1)%3,(axis+2)%3
            for sign in (-1,1):
                planes={}
                for pos,col in cells.items():
                    neighbor=list(pos); neighbor[axis]+=sign
                    if tuple(neighbor) in cells: continue
                    plane=pos[axis]+(1 if sign>0 else 0)
                    planes.setdefault((plane,col),set()).add((pos[u],pos[v]))
                for (plane,col),grid in planes.items():
                    while grid:
                        a,b=min(grid); w=1
                        while (a+w,b) in grid: w+=1
                        h=1
                        while all((a+i,b+h) in grid for i in range(w)): h+=1
                        for i in range(w):
                            for j in range(h): grid.remove((a+i,b+j))
                        points=[]
                        for du,dv in ((0,0),(w,0),(w,h),(0,h)):
                            p=[0,0,0]; p[axis]=plane; p[u]=a+du; p[v]=b+dv
                            points.append((p[0]*step+ox,p[1]*step+oy,p[2]*step+oz))
                        if sign<0: points.reverse()
                        self.face(points,col)

    def disk(self, x,y,z,rx,ry,height,color,step=.12):
        cells={}
        for i in range(math.floor(-rx/step),math.ceil(rx/step)):
            for j in range(math.floor(-ry/step),math.ceil(ry/step)):
                if ((i+.5)*step/rx)**2+((j+.5)*step/ry)**2<=1:
                    cells[i,j,0]=color
        # Use voxel disk footprint, then scale only its z.
        start=len(self.verts); self.vox(cells,step,(x,y,z-height/2))
        for k in range(start,len(self.verts)):
            a,b,c=self.verts[k]; self.verts[k]=(a,b,z-height/2+(c-(z-height/2))*height/step)
        for i in range(-5,6):
            for j in range(-5,6):
                sx,sy=i*.30,j*.30
                if ((abs(sx)+.10)/rx)**2+((abs(sy)+.10)/ry)**2<1:
                    self.stud((x+sx,y+sy,z+height/2),2,1,color,.11)

    def spike(self, base, tip, width, color, steps=5, depth=None):
        # Deliberately stair-stepped taper, never a smooth cone.
        a,b=Vector(base),Vector(tip)
        for i in range(steps):
            f=(i+.5)/steps; p=a.lerp(b,f); w=width*(1-i/steps)
            self.box(tuple(p),(max(w,.07),depth or max(w,.07),(b-a).length/steps+.06),color)

    def finish(self, collection, scale):
        # Studs have their own chamfers. Bevel only the main assembly, avoiding
        # thousands of unnecessary edges on the repeating stud finish.
        main_coords={tuple(round(c,5) for c in p) for p in self.verts}
        self.build_stud_geometry()
        mesh=bpy.data.meshes.new(self.hero+'_Egg_Mesh')
        mesh.from_pydata(self.verts,[],self.faces); mesh.update()
        for key in self.palette: mesh.materials.append(MATS[key])
        for p,m in zip(mesh.polygons,self.mats): p.material_index=m
        obj=bpy.data.objects.new(self.hero+'_Egg',mesh); collection.objects.link(obj)
        bm=bmesh.new(); bm.from_mesh(mesh)
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00005)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        weights=bm.edges.layers.float.new('bevel_weight_edge')
        for edge in bm.edges:
            main_edge=all(tuple(round(c,5) for c in v.co) in main_coords for v in edge.verts)
            angle=edge.calc_face_angle(0.0) if edge.is_manifold else math.pi
            edge[weights]=1.0 if main_edge and angle>.6 else 0.0
        bm.to_mesh(mesh); bm.free()
        zmin=min(v.co.z for v in mesh.vertices); zmax=max(v.co.z for v in mesh.vertices)
        factor=3.2*scale/(zmax-zmin)
        for v in mesh.vertices:
            v.co.z-=zmin; v.co*=factor
        # Consistent world-scale planar UVs, on every shell/accessory polygon.
        # FBX carries these UVs; maps repeat every 0.30 stud (scaled for bosses).
        uv=mesh.uv_layers.new(name='StudUV')
        pitch=.30*scale
        mesh.update()
        for poly in mesh.polygons:
            axis=max(range(3),key=lambda a:abs(poly.normal[a])); sign=1 if poly.normal[axis]>=0 else -1
            for loop_index in poly.loop_indices:
                p=mesh.vertices[mesh.loops[loop_index].vertex_index].co
                if axis==2: pair=(p.x,sign*p.y)
                elif axis==1: pair=(-sign*p.x,p.z)
                else: pair=(sign*p.y,p.z)
                uv.data[loop_index].uv=(pair[0]/pitch,pair[1]/pitch)
        # Micro bevel is editable in the blend and baked once into FBX.
        mod=obj.modifiers.new('Voxel_edge_highlights','BEVEL'); mod.width=.008*factor; mod.segments=1
        valid=[i.identifier for i in mod.bl_rna.properties['limit_method'].enum_items]
        if 'WEIGHT' in valid: mod.limit_method='WEIGHT'
        mod.angle_limit=.6
        obj['HeroId']=self.hero
        obj['Units']='1 Blender unit = 1 Roblox stud'
        obj['Front']='-Y'
        obj['TargetHeightStuds']=3.2*scale
        obj['BossScale']=scale
        obj['SignatureFeatures']=' | '.join(self.features)
        obj['NeonMaterials']=','.join(c for c in self.palette if c.startswith(('glow','gem')))
        obj['ArtDirection']='Faceless costume egg, broad voxel tiers, UV square-stud texture'
        obj['StudTexture']='Stud_Normal.png + per-material albedo + Stud_Roughness.png'
        obj['StudCount']=self.stud_count
        return obj

BASE = {
 'Hawkeye':('purple','coal'),'BlackWidow':('coal','coal'),'CaptainAmerica':('blue','blue'),
 'Hulk':('jade','purple'),'Thor':('graphite','coal'),'IronMan':('red','red'),'Thanos':('purple','navy'),
 'Aquaman':('orange','darkgreen'),'GreenLantern':('green','coal'),'Flash':('red','red'),
 'WonderWoman':('red','blue'),'Batman':('graphite','coal'),'Superman':('blue','blue'),'Darkseid':('stone','navy'),
 'PeterParker':('red','blue'),'SpiderGwen':('white','coal'),'MilesMorales':('coal','coal'),
 'SpiderMan2099':('navy','navy'),'AgentVenom':('coal','coal'),'Venom':('black','black'),'Carnage':('red','wine'),
 'Uraraka':('coal','pink'),'Bakugo':('coal','darkgreen'),'Todoroki':('navy','navy'),
 'Hawks':('tan','brown'),'Deku':('teal','teal'),'AllMight':('blue','blue'),'Shigaraki':('coal','coal'),
 'Krillin':('orange','orange'),'Trunks':('blue','coal'),'Piccolo':('purple','purple'),
 'Gohan':('purple','purple'),'Vegeta':('blue','blue'),'Goku':('orange','orange'),'Frieza':('white','white'),
 'Usopp':('tan','brown'),'Nami':('skin','blue'),'Brook':('coal','coal'),'Sanji':('coal','coal'),
 'Zoro':('darkgreen','darkgreen'),'Shanks':('pearl','brown'),'Luffy':('red','blue'),
 'JoyBoy':('pearl','pearl'),'Kaido':('stone','wine'),
}

def shell(b,hero):
    upper,lower=BASE[hero]; cells={}; step=.12
    for k in range(24):
        t=(k+.5)/24
        radius=next(r for limit,r in [(3,.84),(6,1.08),(12,1.20),(16,1.08),(20,.96),(23,.72),(24,.48)] if k<limit)
        ry=max(.96,radius*.90) if 4<=k<20 else radius*.90
        for i in range(-10,10):
            for j in range(-10,10):
                x,y=(i+.5)*step,(j+.5)*step
                if (abs(x)/radius)**5.5+(abs(y)/ry)**5.5<=1:
                    c=lower if k<5 else upper
                    if hero=='CaptainAmerica' and 5<=k<12: c='white' if (i//2)%2 else 'red'
                    if hero=='GreenLantern' and (abs(i)>6 or k<7): c='coal'
                    if hero=='PeterParker' and abs(i)>6 and k<16: c='blue'
                    if hero=='SpiderGwen' and k<15: c='coal'
                    if hero=='Hulk' and k in (5,6) and (i+j)%5<2: c='purple'
                    if hero in ('Krillin','Goku') and 5<=k<7: c='blue'
                    if hero=='Gohan' and 5<=k<7: c='red'
                    if hero=='Deku' and 5<=k<7: c='red'
                    if hero=='Krillin' and k>=17: c='skin'
                    if hero=='Todoroki' and k>=20: c='red' if i<0 else 'white'
                    if hero=='Piccolo' and k>=14: c='green'
                    if hero=='Luffy' and j<-5 and abs(i)<3 and 8<=k<20: c='skin'
                    if hero in ('Batman','Superman','Flash','WonderWoman') and k==6: c='gold'
                    if hero=='Aquaman' and k in (7,9,11,13,15) and (i+k//2)%3==0 and j<-5: c='gold'
                    if hero=='Darkseid' and ((i*13+j*7+k*3)%37==0): c='graphite'
                    cells[i,j,k]=c
    b.vox(cells,step); b.tag('20x24x20 stepped egg shell')
    for pos,color in cells.items():
        for axis in range(3):
            u,v=(axis+1)%3,(axis+2)%3
            if pos[u]%3!=1 or pos[v]%3!=1: continue
            for sign in (-1,1):
                neighbor=list(pos); neighbor[axis]+=sign
                if tuple(neighbor) in cells: continue
                p=[(pos[i]+.5)*step for i in range(3)]
                p[axis]=(pos[axis]+(1 if sign>0 else 0))*step
                if axis==2 and sign<0: continue
                b.stud(tuple(p),axis,sign,color)
    b.tag('broad stepped voxel tiers with UV-mapped recessed square stud texture')

STAR=['...#...','...#...','#######','.#####.','..###..','.##.##.','.#...#.']
BOLT=['...##','..##.','.###.','####.','..##.','.##..','##...']
SPIDER=['#.....#','#..#..#','.#####.','..###..','#######','..###..','.##.##.','#.#.#.#']
BAT=['#.......#','##..#..##','#########','.#######.','..#####..','....#....']
A_GLYPH=['.###.','##.##','##.##','#####','##.##','##.##']
S_GLYPH=['.#####.','##.....','##.....','.####..','.....##','.....##','######.']

def face(b,color='skin',eyes='coal',mouth=True):
    # User explicitly removed faces from the art direction.
    pass

def eyes(b,color='white',angry=False,outline='coal',z=2.22):
    pass

def hair(b,color='black',style='crop'):
    b.disk(0,0,2.75,.90,.82,.36,color)
    for s in (-1,1):
        b.box((s*.83,-.46,2.46),(.22,.45,.43),color)
    if style=='long':
        for s in (-1,1):
            for i in range(3): b.box((s*(1.01+.035*i),-.52+i*.35,1.98),(.27,.38,1.45-i*.14),color)
        b.box((0,.97,2.05),(1.42,.27,1.24),color)
    elif style=='spike':
        for x,z,dx in [(-.77,3.1,-.35),(-.42,3.4,-.18),(0,3.56,.08),(.38,3.31,.33),(.74,3.05,.39)]:
            b.spike((x*.82,.03,2.72),(x+dx,.05,z),.43,color,5,.48)
    for i in range(7):
        b.box(((i-3)*.22,-.74,2.55+(i%3)*.065),(.24,.28,.20+(i%2)*.09),color)
    b.tag(color+' '+style+' voxel hair')

def cape(b,color='red',width=1.13):
    for i in range(-5,6):
        x=i*width/5
        b.beam((x*.72,.66,2.35),(x,1.0,.35+(abs(i)%2)*.10),width/5+.04,color,.17)
    b.tag(color+' stepped back cape')

def belt(b,color='gold',z=.80):
    b.box((0,-1.02,z),(1.93,.13,.20),color)
    b.box((0,-1.11,z),(.31,.13,.29),'gold' if color!='gold' else 'yellow')

def fist(b,x,color='coal',z=1.28,large=False):
    w=.69 if large else .52
    b.box((x,-.45,z),(w,.64,w),color)
    b.box((x,-.72,z+.08),(w+.06,.27,w*.62),color)
    for i in range(3): b.box((x+(i-1)*w/3,-.89,z+.14),(w/3-.02,.14,w*.40),'graphite' if color=='black' else color)
    b.box((x-math.copysign(w*.40,x),-.80,z-.16),(w*.35,.28,w*.41),color)

def katana(b,x,y,z,lean=0,blade='silver',grip='purple',length=2.30):
    a=Vector((x,y,z)); d=Vector((math.sin(lean),0,math.cos(lean)))
    b.beam(a,a+d*length,.095,blade,.07)
    b.beam(a-d*.12,a-d*.59,.16,grip,.14)
    p=a-d*.07; b.box(tuple(p),(.43,.24,.095),'gold',-lean)
    for i in range(4): b.box(tuple(a-d*(.20+i*.09)),(.18,.16,.035),'white',-lean)
    b.tag('voxel katana')

def chest_disc(b,x,z,color='glowcyan',r=.19):
    b.box((x,-1.075,z),(r*2+.11,.14,r*2+.11),'silver')
    b.pixel(['.##.','####','####','.##.'],(x,-1.17,z),r/2,color,.06)

def insignia(b,rows,color='white',z=1.40,step=.09,y=-1.14):
    b.pixel(rows,(0,y,z),step,color)

def grin(b,z=1.90,w=.82):
    pass

def accessories(b,h):
    if h=='Hawkeye':
        face(b); hair(b,'auburn')
        b.beam((-.70,-1.10,1.95),(.65,-1.14,.55),.18,'black',.10)
        b.box((.84,.72,1.95),(.42,.43,1.27),'coal')
        for i in range(3):
            b.beam((.70+i*.13,.75,2.40),(.70+i*.13,.75,3.08),.045,'silver')
            b.box((.70+i*.13,.75,2.99),(.12,.11,.20),'purple')
        b.line([(-1.24,-.12,.4),(-1.54,-.14,.9),(-1.62,-.14,1.65),(-1.43,-.12,2.34)],.10,'purple')
        b.beam((-1.24,-.12,.4),(-1.43,-.12,2.34),.025,'silver')
        b.tag('crossbody strap, quiver and bow')
    elif h=='BlackWidow':
        face(b); hair(b,'auburn','long'); belt(b,'coal')
        b.beam((-.54,-1.08,1.82),(.25,-1.14,.88),.10,'steel')
        b.beam((.54,-1.08,1.82),(-.25,-1.14,.88),.10,'steel')
        b.pixel(['####','.##.','.##.','####'],(0,-1.23,.81),.078,'red')
        for s in (-1,1):
            fist(b,s*1.12,'coal'); b.box((s*1.12,-.81,1.31),(.38,.12,.11),'glowcyan')
        b.tag('red hourglass buckle and Widow bite gauntlets')
    elif h=='CaptainAmerica':
        face(b)
        b.pixel(A_GLYPH,(0,-.71,2.57),.062,'white')
        insignia(b,STAR,step=.10)
        # Shield faces the player, with concentric stair-step rings.
        for r,col,d,yy in [(.70,'red',.13,-.90),(.55,'white',.08,-1.00),(.42,'red',.065,-1.065),(.30,'blue',.05,-1.12)]:
            rows=[]; n=round(r/.09)
            for j in range(-n,n+1): rows.append(''.join('#' if i*i+j*j<=n*n else '.' for i in range(-n,n+1)))
            b.pixel(rows,(-1.12,yy,1.06),.09,col,d)
        b.pixel(STAR,(-1.12,-1.17,1.06),.065,'white')
        for i in range(8):
            a=i*math.tau/8
            b.stud((-1.12+.61*math.cos(a),-.974,1.06+.61*math.sin(a)),1,-1,'red',.063)
        b.tag('helmet A, chest star, red-white torso stripes, shield')
    elif h=='Hulk':
        face(b,'jade'); hair(b,'darkgreen'); grin(b)
        for s in (-1,1):
            b.box((s*.58,-1.0,1.42),(.75,.32,.61),'green')
            b.box((s*1.08,-.17,1.57),(.54,.80,.78),'jade')
            fist(b,s*1.22,'jade',.94,True)
        for z in (.98,1.19): b.box((0,-1.11,z),(.48,.16,.17),'green')
        b.tag('bulging muscle clusters and ragged purple shorts')
    elif h=='Thor':
        cape(b); face(b); hair(b,'straw','long')
        b.disk(0,0,2.80,.95,.86,.28,'silver')
        b.box((0,-.81,2.65),(.18,.18,.49),'steel')
        for s in (-1,1):
            for i in range(3): b.spike((s*(.83+i*.12),.0,2.68),(s*(1.08+i*.17),.03,3.10+i*.09),.22,'silver',4,.22)
            chest_disc(b,s*.48,1.50); chest_disc(b,s*.43,1.01,r=.14)
        b.beam((1.25,-.27,.69),(1.25,-.27,1.73),.15,'brown')
        b.box((1.25,-.27,1.84),(.78,.52,.49),'silver')
        b.box((1.25,-.55,1.84),(.49,.06,.27),'steel')
        b.tag('winged helmet, luminous armor discs, Mjolnir')
    elif h=='IronMan':
        b.pixel(['..####..','.######.','########','########','########','.######.','..####..'],(0,-.87,2.25),.16,'gold',.28)
        b.box((0,-1.035,1.80),(.70,.12,.17),'red')
        for s in (-1,1):
            b.box((s*.78,-.91,1.37),(.38,.18,.48),'gold')
            fist(b,s*1.03,'red',.91)
        chest_disc(b,0,1.37,r=.25)
        for z in (.61,.79,.97): b.box((0,-1.025,z),(.74,.12,.10),'wine')
        b.tag('gold helmet armor and cyan arc reactor')
    elif h=='Thanos':
        face(b,'purple'); grin(b)
        b.disk(0,0,2.75,.93,.85,.28,'gold')
        b.box((0,-.85,2.61),(.28,.22,.56),'gold')
        for s in (-1,1):
            b.box((s*.83,-.27,1.45),(.63,.84,.40),'gold')
            b.beam((s*.62,-1.02,1.72),(s*.34,-1.13,1.18),.22,'gold')
        belt(b)
        fist(b,-1.20,'gold',1.01,True)
        for i,c in enumerate(('gempurple','gemblue','glowred','glowgold')): b.box((-1.49+i*.19,-.995,1.28),(.13,.10,.14),c)
        b.box((-1.20,-1.02,.96),(.24,.11,.25),'glowgreen')
        b.box((-.87,-.96,.89),(.13,.10,.16),'orange')
        b.tag('gold helmet and six-color Infinity Gauntlet')
    elif h=='Aquaman':
        face(b); hair(b,'brown','long'); belt(b,'darkgreen')
        b.pixel(['#...#','.###.','..#..'],(0,-1.14,1.60),.16,'gold')
        b.beam((1.33,0,.20),(1.33,0,2.80),.10,'gold')
        for x,z in [(1.01,2.85),(1.33,3.18),(1.65,2.85)]:
            b.beam((x,0,2.47),(x,0,z),.11,'gold')
            b.spike((x,0,z-.04),(x,0,z+.18),.16,'gold',3)
        b.beam((1.01,0,2.49),(1.65,0,2.49),.11,'gold')
        b.tag('scale-patterned armor and golden trident')
    elif h=='GreenLantern':
        face(b); hair(b,'brown')
        b.pixel(['.#####.','##...##','##...##','##...##','.#####.'],(0,-1.14,1.41),.095,'white')
        b.pixel(['#####','..#..','..#..','#####'],(0,-1.20,1.41),.085,'glowgreen')
        fist(b,1.15,'green',1.17); b.box((1.16,-.97,1.27),(.17,.08,.17),'glowgreen')
        b.tag('lantern chest emblem and luminous power ring')
    elif h=='Flash':
        face(b)
        for s in (-1,1):
            b.pixel(BOLT,(s*1.0,-.15,2.30),.09,'gold',.18)
        b.pixel(['.#####.','#######','#######','#######','.#####.'],(0,-1.11,1.41),.115,'white')
        insignia(b,BOLT,'gold',1.41,.095,-1.20); belt(b)
        b.tag('lightning ear wings, lightning chest badge and belt')
    elif h=='WonderWoman':
        face(b); hair(b,'black','long')
        b.box((0,-.92,2.52),(1.32,.14,.17),'gold')
        b.pixel(STAR,(0,-1.01,2.54),.047,'red')
        b.pixel(['#.......#','##.....##','.##.#.##.','..#####..','...###...','....#....'],(0,-1.15,1.42),.12,'gold')
        for x in (-.62,0,.62): b.pixel(STAR,(x,-.88,.43),.047,'white')
        for s in (-1,1): fist(b,s*1.12,'silver',1.02)
        b.tag('tiara red star, golden eagle and star-patterned blue rim')
    elif h=='Batman':
        cape(b,'black'); face(b)
        for s in (-1,1):
            b.spike((s*.65,-.12,2.64),(s*.76,-.12,3.44),.32,'coal',5,.36)
        b.box((0,-1.15,1.42),(1.16,.11,.57),'gold')
        insignia(b,BAT,'black',1.42,.11,-1.23); belt(b)
        for x in (-.67,-.34,.34,.67): b.box((x,-1.13,.78),(.22,.16,.24),'strawshade')
        b.tag('tall bat ears, bat emblem and utility belt pouches')
    elif h=='Superman':
        face(b); hair(b); cape(b); belt(b)
        b.pixel(['###','..#','.##','.##'],(.15,-.95,2.52),.075,'black')
        b.pixel(['#########','.#######.','..#####..','...###...','....#....'],(0,-1.12,1.37),.14,'gold')
        insignia(b,S_GLYPH,'red',1.45,.082,-1.21)
        b.tag('S shield, forehead curl and red cape')
    elif h=='Darkseid':
        face(b,'stone',mouth=False)
        for s in (-1,1):
            b.box((s*.99,-.28,1.46),(.65,.95,.51),'navy')
            b.box((s*.90,-.80,1.54),(.55,.12,.15),'blue')
        for pts in [[(-.58,-1.05,2.46),(-.47,-1.09,2.31),(-.55,-1.08,2.11)],[(.30,-1.05,2.51),(.18,-1.09,2.35),(.28,-1.08,2.02)],[(0,-1.12,1.12),(.14,-1.14,1.30),(.10,-1.11,1.57)]]: b.line(pts,.035,'graphite')
        b.pixel(['##...##','###.###','.#####.','..###..'],(0,-1.14,1.41),.115,'navy')
        b.tag('fractured stone shell and blue armor')
    elif h in ('PeterParker','MilesMorales','SpiderMan2099','SpiderGwen','AgentVenom','Venom','Carnage'):
        spider_accessories(b,h)
    elif h in ('Uraraka','Bakugo','Todoroki','Hawks','Deku','AllMight','Shigaraki'):
        mha_accessories(b,h)
    elif h in ('Krillin','Trunks','Piccolo','Gohan','Vegeta','Goku','Frieza'):
        db_accessories(b,h)
    else:
        pirate_accessories(b,h)

def spider_accessories(b,h):
    if h=='SpiderGwen':
        b.pixel(['..######..','.########.','###....###','##......##','##......##','##......##','.##....##.','..######..'],(0,-.83,2.18),.16,'white',.29)
        b.box((0,-.95,2.20),(1.00,.12,.70),'coal')
        for s in (-1,1):
            b.box((s*.62,-1.0,2.19),(.12,.05,.64),'magenta')
            b.box((s*.90,-.48,1.67),(.26,.23,.48),'white')
            b.box((s*.88,-.65,1.68),(.11,.055,.25),'cyan')
        eyes(b,angry=True,z=2.20)
        insignia(b,SPIDER,'magenta',1.38,.071)
        b.tag('white hood, pink lining, teal insets and pink spider')
    else:
        eyes(b,angry=True,outline='red' if h=='MilesMorales' else 'coal')
        c='white' if h in ('Venom','AgentVenom') else 'red' if h in ('MilesMorales','SpiderMan2099') else 'coal'
        insignia(b,SPIDER,c,1.27,.12)
    if h in ('PeterParker','MilesMorales'):
        web='coal' if h=='PeterParker' else 'red'
        for x in (-.73,0,.73): b.beam((x*.72,-.82,2.65),(x,-1.035,1.79),.027,web)
        for z,w,y in [(2.51,.63,-.89),(2.12,.84,-.98),(1.86,.76,-1.035)]:
            b.line([(-w,y,z+.09),(0,y-.07,z),(w,y,z+.09)],.026,web)
        b.tag('raised web lines over blank studded shell')
    if h=='SpiderMan2099':
        for s in (-1,1):
            b.pixel(['####','###.','##..','#...'],(s*.77,-.86,2.40),.10,'red')
            for z in (.90,1.17,1.44): b.spike((s*1.00,0,z),(s*1.43,0,z+.35),.24,'red',4,.18)
        b.tag('red spider and arm blades')
    if h=='AgentVenom':
        for s in (-1,1):
            b.box((s*1.0,-.09,1.74),(.58,.68,.36),'white')
            b.box((s*.83,-.78,1.48),(.40,.24,.43),'graphite')
            fist(b,s*1.12,'coal',1.0)
        belt(b,'coal')
        b.tag('white shoulder armor, tactical plates and white spider')
    if h in ('Venom','Carnage'):
        if h=='Venom':
            for s in (-1,1):
                b.line([(s*.54,-1.02,2.15),(s*.82,-.94,2.00),(s*1.10,-.62,1.68)],.12,'white')
                b.line([(s*.65,.65,1.86),(s*1.30,.66,2.12),(s*1.48,.34,2.50)],.18,'black')
            b.tag('white alien spider and sculpted symbiote ridges')
        else:
            for s in (-1,1):
                for k in range(3):
                    b.line([(s*.92,.40,1.0+k*.5),(s*(1.37+k*.15),.35,1.32+k*.56),(s*(1.48+k*.11),.22,1.8+k*.43),(s*(1.29+k*.15),.05,2.02+k*.40)],.13,'red')
                b.line([(s*.55,-1.06,.55),(s*.77,-1.09,.86),(s*.52,-1.11,1.06)],.075,'black')
            b.tag('six jagged crimson tendrils and black symbiote veins')

def mha_accessories(b,h):
    if h=='Uraraka':
        face(b); hair(b,'brown')
        for s in (-1,1):
            b.box((s*.77,-.68,2.15),(.24,.35,.32),'pink')
            b.box((s*1.18,-.39,1.17),(.69,.68,.62),'white')
            b.box((s*1.18,-.76,1.17),(.51,.12,.43),'pink')
            b.box((s*.63,-1.02,1.35),(.22,.14,.61),'pink')
        belt(b,'pink'); b.tag('pink armor pads and oversized gravity wrist cuffs')
    elif h=='Bakugo':
        face(b); hair(b,'straw','spike')
        for s in (-1,1):
            for i in range(3):
                b.spike((s*.75,.05,2.36),(s*(1.34+i*.19),.03,2.64+i*.31),.29,'coal',4,.24)
                b.box((s*(1.08+i*.16),-.11,2.55+i*.22),(.15,.10,.33),'orange',s*-.45)
            b.beam((s*.69,-1.12,1.80),(-s*.59,-1.15,.75),.20,'orange',.11)
            b.box((s*1.23,-.40,1.16),(.74,.72,.88),'darkgreen')
            for z in (.85,1.10,1.35): b.box((s*1.23,-.81,z),(.76,.10,.065),'jade')
            for x in (-.18,.18): b.box((s*1.23+x,-.83,1.13),(.045,.05,.72),'coal')
            b.box((s*1.23,-.40,1.65),(.18,.27,.15),'silver')
        b.tag('orange X harness, explosion fins and ribbed grenade gauntlets')
    elif h=='Todoroki':
        face(b)
        for s,c in ((-1,'red'),(1,'white')):
            for i in range(4):
                b.box((s*(.12+i*.21),-.34,2.68),(.24,.95,.35-i*.035),c)
                b.box((s*(.12+i*.21),-.80,2.49),(.24,.22,.23+(i%2)*.16),c)
        for s,col in ((-1,'red'),(1,'glowcyan')):
            for i in range(3): b.spike((s*1.04,-.03,.8+i*.3),(s*(1.27+i*.1),-.03,1.30+i*.40),.30,col,4)
        belt(b,'white'); b.tag('split white-red hair, ice and fire')
    elif h=='Hawks':
        face(b); hair(b,'straw')
        for s in (-1,1):
            for i in range(6):
                b.beam((s*(.48+i*.12),.61,1.80-i*.12),(s*(1.28+i*.18),.81,2.98-i*.28),.25,'red' if i%2==0 else 'wine',.16)
            b.box((s*.88,-.26,2.34),(.26,.54,.42),'gold')
            b.box((s*.66,-1.07,1.79),(.36,.25,.29),'pearl')
            b.box((s*.40,-1.14,1.70),(.28,.20,.26),'pearl')
        b.box((0,-1.08,1.0),(.085,.09,1.08),'coal')
        b.line([(-.78,-1.05,1.94),(-.45,-1.10,1.74),(0,-1.12,1.64),(.45,-1.10,1.74),(.78,-1.05,1.94)],.17,'pearl')
        b.tag('layered crimson feather wings, aviator fur collar and headphones')
    elif h=='Deku':
        face(b); hair(b,'darkgreen')
        for s in (-1,1):
            b.spike((s*.57,0,2.70),(s*.79,0,3.40),.35,'teal',5,.31)
            b.box((s*.69,-.18,3.02),(.12,.10,.39),'coal')
            b.box((s*.61,-1.08,1.35),(.12,.12,.66),'coal')
        b.box((0,-1.06,1.83),(1.01,.19,.27),'silver')
        for i in range(5): b.box(((i-2)*.17,-1.17,1.83),(.055,.04,.16),'coal')
        belt(b,'red'); b.tag('rabbit-ear hood, respirator mouth guard and red utility belt')
    elif h=='AllMight':
        face(b); grin(b,w=1.05)
        b.disk(0,.05,2.80,.82,.79,.28,'yellow')
        for s in (-1,1):
            b.spike((s*.34,0,2.68),(s*.80,-.1,3.55),.40,'yellow',6,.34)
            b.beam((s*.74,-1.04,1.81),(0,-1.14,1.03),.32,'white',.10)
            b.beam((s*.77,-1.10,1.84),(s*.19,-1.21,1.21),.13,'red',.09)
            fist(b,s*1.15,'yellow',.87,True)
        belt(b); b.tag('V antenna bangs and flag-colored chevron suit')
    elif h=='Shigaraki':
        face(b); hair(b,'silver','spike')
        # Palm center and five separate articulated fingers clutch the face.
        b.box((0,-1.16,2.13),(.44,.19,.49),'bone')
        for i in range(4):
            x=(i-1.5)*.15
            b.box((x,-1.15,2.52),(.12,.17,.36+(.10 if i in (1,2) else 0)),'bone')
            b.box((x,-1.04,2.73),(.12,.26,.12),'bone')
        b.beam((.18,-1.19,2.17),(.49,-1.18,2.38),.14,'bone')
        b.box((0,-1.14,1.83),(.29,.17,.19),'red')
        for s in (-1,1):
            b.box((s*.89,-1.00,1.65),(.37,.20,.38),'bone')
            for i in range(4): b.box((s*(.70+i*.12),-1.08,1.38),(.10,.18,.32),'bone')
        b.tag('five-finger face-clutching hand and paired shoulder hands')

def db_accessories(b,h):
    if h=='Frieza':
        face(b,'white',eyes='red')
        b.disk(0,0,2.75,.74,.66,.29,'purple')
        for s in (-1,1):
            b.box((s*1.06,-.48,1.52),(.48,.52,.46),'purple')
            b.box((s*.72,-.84,2.19),(.20,.23,.62),'silver')
        b.pixel(['.####.','######','######','.####.'],(0,-1.12,1.42),.125,'purple')
        b.line([(.40,.83,.40),(1.12,1.09,.37),(1.59,.89,.58),(1.72,.43,.90)],.27,'white')
        b.tag('purple bio-armor gems and segmented tail')
        return
    face(b,'green' if h=='Piccolo' else 'skin')
    if h=='Krillin':
        b.disk(0,0,2.80,.80,.75,.31,'skin')
        for z in (2.48,2.66):
            for x in (-.21,0,.21): b.box((x,-.87,z),(.075,.065,.075),'brown')
        b.tag('six forehead dots and bald monk head')
    elif h=='Trunks':
        hair(b,'lavender')
        for s in (-1,1):
            b.beam((s*.16,-.87,2.75),(s*.65,-.89,2.40),.24,'lavender',.23)
            b.box((s*.62,-.95,1.38),(.37,.14,.27),'navy')
        b.beam((-.66,-1.12,1.76),(.62,-1.11,.70),.14,'brown',.08)
        katana(b,.72,.65,1.12,.33,'steel','brown',1.56)
        b.pixel(['.###.','##...','##...','.###.'],(.89,-.57,1.52),.055,'white')
        b.tag('parted lavender hair, denim jacket, Capsule badge and back sword')
    elif h=='Piccolo':
        cape(b,'white',1.35)
        for z,r in [(2.58,.94),(2.75,.83),(2.9,.68)]: b.disk(0,0,z,r,r*.88,.19,'white')
        for s in (-1,1):
            b.spike((s*.70,-.12,2.25),(s*1.21,-.12,2.51),.27,'green',4,.20)
            b.box((s*1.01,-.47,1.32),(.33,.27,.68),'pink')
            for z in (1.09,1.25,1.41,1.57): b.box((s*1.01,-.63,z),(.34,.05,.035),'wine')
            b.box((s*.65,-.80,1.77),(.77,.32,.27),'white')
        belt(b,'blue'); b.tag('layered turban, heavy white cape and pink Namekian arm patches')
    elif h=='Vegeta':
        hair(b,'black','spike')
        b.spike((0,-.73,2.63),(0,-.75,2.35),.24,'black',3,.15)
        b.box((0,-1.04,1.38),(1.48,.24,.78),'white')
        b.box((0,-1.18,1.10),(1.02,.10,.35),'gold')
        for x in (-.40,-.20,0,.20,.40): b.box((x,-1.245,1.10),(.025,.025,.35),'strawshade')
        for s in (-1,1):
            b.box((s*.79,-.31,1.80),(.56,.61,.24),'gold')
            fist(b,s*1.10,'white',.91)
        b.tag('flame hair, widow peak and white-gold Saiyan battle armor')
    else:
        hair(b,'black','spike')
        if h=='Goku':
            for s in (-1,1): b.spike((s*.77,.0,2.65),(s*1.40,.0,2.97),.45,'black',5,.44)
        else:
            b.spike((.0,-.77,2.69),(-.24,-.80,2.15),.22,'black',4,.18)
        b.tag('multi-point Saiyan hair silhouette')
    if h in ('Goku','Krillin','Gohan'):
        belt(b,'red' if h=='Gohan' else 'blue')
        for s in (-1,1):
            b.beam((s*.57,-1.04,1.78),(0,-1.16,1.23),.18,'blue' if h!='Gohan' else 'skin',.12)
            fist(b,s*1.07,'blue' if h!='Gohan' else 'red',.97)
        if h in ('Goku','Krillin'):
            b.box((.54,-1.13,1.35),(.43,.08,.45),'white')
            # Pixel kanji-inspired Kame school mark, composed of strokes.
            b.pixel(['.##..','#####','.#.#.','#####','.#.#.','#####','..#.#'],(.54,-1.19,1.35),.046,'coal')
        b.tag('layered gi collar, sash, wristbands and school badge' if h!='Gohan' else 'purple gi and red sash')

def straw_hat(b,white=False):
    c='pearl' if white else 'straw'
    b.disk(0,0,2.70,1.44,1.30,.16,'gold' if white else 'strawshade')
    b.disk(0,0,2.79,1.40,1.27,.16,c)
    b.disk(0,0,2.96,.94,.86,.19,'gold' if white else 'red')
    b.disk(0,0,3.12,.83,.76,.19,c)
    b.disk(0,0,3.25,.71,.65,.12,c)
    for i in range(16):
        a=i*math.tau/16
        b.box((1.17*math.cos(a),1.05*math.sin(a),2.885),(.17,.13,.035),'gold' if white else 'yellow')
    b.tag('stepped straw brim, woven ridges and ribbon')

def pirate_accessories(b,h):
    if h=='Luffy':
        face(b); hair(b); straw_hat(b); grin(b,w=.68)
        b.box((0,-1.10,1.35),(.64,.08,.82),'skin')
        for s in (-1,1):
            b.box((s*.59,-1.08,1.35),(.38,.21,.84),'red')
            b.box((s*.53,-1.21,1.38),(.24,.045,.40),'scarlet')
            for z in (1.05,1.57): b.box((s*.49,-1.23,z),(.075,.05,.075),'gold')
        b.pixel(['#...#','.#.#.','..#..','.#.#.','#...#'],(0,-1.17,1.25),.09,'skinshade')
        b.beam((-1.00,-.18,1.35),(-1.53,-.43,1.43),.47,'red')
        fist(b,-1.65,'black',1.42,True)
        b.box((0,-.93,.38),(1.53,.13,.13),'white')
        b.tag('open red vest, chest scar, blue shorts and projecting Haki fist')
    elif h=='Zoro':
        face(b); hair(b,'green'); b.box((0,-1.08,1.32),(.65,.16,.74),'skin')
        for s in (-1,1): b.beam((s*.71,-1.04,1.75),(s*.26,-1.14,.99),.31,'darkgreen',.13)
        belt(b,'green')
        for z in (.67,.78,.89): b.box((0,-1.14,z),(1.79,.06,.045),'jade')
        b.box((1.02,-.29,1.58),(.36,.49,.31),'black')
        katana(b,-1.12,.10,.47,-.31,grip='white',length=2.05)
        katana(b,1.15,.22,.43,.31,grip='purple',length=2.13)
        katana(b,.84,-.64,.54,.75,grip='coal',length=1.62)
        for x in (-.78,-.66,-.54): b.box((x,-.86,1.92),(.045,.055,.15),'gold')
        b.tag('green haramaki sash, black arm bandana, triple earrings and exactly three katanas')
    elif h=='Usopp':
        face(b); hair(b,'black')
        b.disk(0,0,2.85,.96,.86,.40,'yellow')
        for s in (-1,1):
            b.box((s*.36,-.86,2.64),(.46,.20,.31),'brown')
            b.box((s*.36,-.98,2.64),(.31,.065,.19),'cyan')
            b.box((s*.57,-1.04,1.43),(.19,.15,.76),'brown')
            b.box((s*.57,-1.14,1.11),(.09,.07,.09),'gold')
        b.box((0,-1.08,1.17),(.88,.18,.46),'brown')
        b.tag('yellow bandana, top-mounted sniper goggles and brown overalls')
    elif h=='Nami':
        face(b); hair(b,'orange','long')
        for s in (-1,1):
            b.box((s*.40,-1.07,1.48),(.70,.21,.48),'white')
            for z in (1.32,1.52,1.68): b.box((s*.40,-1.195,z),(.69,.05,.085),'blue')
            b.beam((s*.47,-1.06,1.70),(s*.64,-.92,1.91),.07,'blue')
        b.box((0,-1.04,1.03),(1.19,.14,.30),'skin')
        fist(b,1.13,'skin',1.12)
        b.box((1.13,-.85,1.33),(.36,.18,.28),'gold')
        b.box((1.13,-.96,1.34),(.23,.05,.20),'cyan')
        b.box((1.13,-1.00,1.34),(.04,.02,.16),'red',-.45)
        b.tag('orange locks, blue-white striped top and Log Pose wrist compass')
    elif h=='Brook':
        # Afro is a stepped voxel volume with an irregular rounded perimeter.
        cells={}; step=.15
        for i in range(-8,8):
            for j in range(-6,7):
                for k in range(-5,7):
                    if ((i+.5)/7.6)**2+((j+.5)/6.3)**2+((k+.5)/6)**2<1:
                        cells[i,j,k]='black'
        b.vox(cells,step,(0,.17,2.53))
        for z in (1.89,2.04,2.19): b.box((0,-1.05,z),(.92,.12,.065),'bone')
        b.box((0,-1.08,2.06),(.10,.14,.50),'bone')
        b.disk(0,.03,3.30,.99,.88,.16,'coal')
        b.disk(0,.03,3.72,.62,.57,.73,'coal')
        b.disk(0,.03,3.44,.65,.60,.17,'gold')
        b.pixel(['##..##','######','.####.','..##..','..##..'],(0,-1.15,1.47),.14,'pink')
        b.tag('giant voxel afro, ribcage motif, gentleman top hat and pink ascot')
    elif h=='Sanji':
        face(b); hair(b,'straw')
        for i in range(4): b.box((-.16-i*.17,-1.16,2.44-i*.07),(.24,.13,.58),'straw')
        b.box((0,-1.08,1.41),(.46,.15,.79),'blue')
        for s in (-1,1): b.beam((s*.63,-1.08,1.80),(s*.13,-1.20,1.02),.24,'graphite',.09)
        b.beam((0,-1.20,1.74),(0,-1.24,1.09),.105,'navy')
        b.tag('asymmetric blonde fringe, tailored lapels and blue tie')
    elif h=='Shanks':
        face(b); hair(b,'auburn'); cape(b,'black',1.25)
        b.box((0,-1.06,1.43),(.46,.13,.65),'skin')
        for s in (-1,1): b.beam((s*.52,-1.03,1.76),(s*.21,-1.13,1.12),.24,'pearl',.10)
        belt(b,'red'); katana(b,1.06,.23,.35,.35,'brown','coal',1.74)
        b.tag('swept red hair, captain cape and sword sheath')
    elif h=='JoyBoy':
        face(b,'pearl'); hair(b,'white'); grin(b,w=1.00)
        straw_hat(b,True); belt(b,'pearl')
        points=[]
        for i in range(29):
            a=i*math.tau/28
            p=(1.62*math.cos(a),.10+1.35*math.sin(a),1.70+.23*math.sin(a*2))
            points.append(p)
            if i%3==0: b.box(p,(.34,.31,.27),'white')
        b.line(points,.18,'pearl')
        b.tag('floating cloud ribbon halo and gold-rim white straw hat')
    elif h=='Kaido':
        face(b,'skinshade'); hair(b,'black','long'); grin(b,w=.88)
        for s in (-1,1):
            b.line([(s*.70,.04,2.67),(s*1.04,.04,2.79),(s*1.33,.04,3.11),(s*1.35,.04,3.52),(s*1.15,.04,3.69)],.25,'bone')
            b.box((s*1.04,-.25,1.45),(.64,.78,.84),'skinshade')
        for i in range(4):
            for j in range(3): b.pixel(['#.#','.#.'],(-.89+j*.13,-.73,.98+i*.17),.060,'blue')
        b.box((0,-1.04,1.23),(1.02,.23,.70),'skinshade')
        belt(b,'purple')
        b.beam((1.44,.04,.32),(1.70,.04,2.59),.21,'brown')
        b.beam((1.61,.04,1.84),(1.77,.04,3.03),.45,'coal')
        for z in (1.99,2.26,2.53,2.80):
            for s in (-1,1): b.spike((1.69+s*.16,.04,z),(1.69+s*.45,.04,z+.05),.19,'steel',3,.17)
        b.tag('curved bull horns, dragon-scale arm tattoo and spiked kanabo')

def costume_finish(b,h):
    """Secondary construction details: seams, hardware, layered trims and studs."""
    upper,lower=BASE[h]
    # Side seam runs follow the shell, rather than drawing a humanoid face.
    if h in ('Hawkeye','BlackWidow','AgentVenom','Batman','Deku','Trunks','Sanji'):
        trim='purple' if h=='Hawkeye' else 'steel' if h in ('BlackWidow','AgentVenom','Batman') else 'darkgreen' if h=='Deku' else 'navy'
        for s in (-1,1):
            b.line([(s*.84,-.91,.57),(s*.99,-.88,.94),(s*.99,-.87,1.40),(s*.87,-.80,1.76)],.045,trim)
            for z in (.70,.87,1.04):
                b.box((s*.76,-1.035,z),(.17,.06,.11),upper)
                b.box((s*.76,-1.075,z),(.05,.035,.04),'silver')
    if h in ('Luffy','Zoro','Shanks','Sanji','Hawks','Trunks','Usopp'):
        trim={'Luffy':'strawshade','Zoro':'jade','Shanks':'gold','Sanji':'steel','Hawks':'brown','Trunks':'silver','Usopp':'strawshade'}[h]
        for s in (-1,1):
            for j in range(5):
                b.box((s*.77,-1.055,.95+j*.16),(.055,.045,.027),trim)
        if h in ('Luffy','Zoro','Shanks'):
            for s in (-1,1): b.beam((s*.32,-1.065,2.16),(s*.67,-1.11,1.70),.12,BASE[h][0],.10)
    if h in ('CaptainAmerica','Batman','IronMan','Thanos','Darkseid','Vegeta','AgentVenom'):
        metal='gold' if h in ('Thanos','IronMan','Vegeta') else 'silver' if h=='CaptainAmerica' else 'steel'
        for s in (-1,1):
            b.box((s*1.075,-.37,1.79),(.38,.48,.18),BASE[h][0])
            for y in (-.51,-.26): b.stud((s*1.075,y,1.89),2,1,metal,.075)
        if h=='IronMan':
            for x in (-.48,-.16,.16,.48):
                for z in (2.03,2.35,2.51):
                    if abs(x)<.4 or z<2.4: b.stud((x,-1.018,z),1,-1,'gold',.095)
            for s in (-1,1): b.beam((s*.67,-.99,1.86),(s*.90,-.89,1.51),.07,'wine')
    if h=='Thor':
        for z in (.82,.99,1.16,1.33,1.50): b.box((1.25,-.36,z),(.16,.03,.05),'gold')
        b.pixel(['#..#','.##.','#..#'],(1.25,-.60,1.84),.068,'silver')
    if h=='Hawkeye':
        for z in (.97,1.15,1.33): b.box((-.49,-1.15,z),(.35,.09,.085),'purple')
        b.pixel(['..#..','.###.','##.##','...#.','...#.'],(.43,-1.08,2.16),.10,'lavender')
    if h=='BlackWidow':
        b.beam((0,-1.04,2.28),(0,-1.12,1.70),.045,'silver')
        b.box((0,-1.17,1.76),(.085,.045,.13),'steel')
    if h=='GreenLantern':
        for s in (-1,1): b.line([(s*.34,-1.03,2.10),(s*.63,-1.05,1.95),(s*.63,-1.10,1.66)],.045,'jade')
    if h in ('Uraraka','Todoroki','AllMight'):
        for s in (-1,1):
            b.box((s*.70,-1.02,.89),(.20,.15,.22),'pink' if h=='Uraraka' else 'white')
            b.box((s*.70,-1.11,.90),(.09,.045,.055),'coal')
    if h in ('Goku','Krillin','Gohan','Piccolo'):
        color='red' if h=='Gohan' else 'blue'
        for z in (.71,.78,.85): b.box((0,-1.145,z),(1.78,.035,.025),color)
        for x,z in ((.31,.63),(.44,.55),(.56,.47)): b.box((x,-1.00,z),(.20,.10,.21),color)
    if h=='Hawks':
        for s in (-1,1):
            b.box((s*.50,-1.07,1.20),(.47,.16,.33),'brown')
            b.box((s*.50,-1.16,1.31),(.48,.06,.09),'tan')
            b.box((s*.50,-1.20,1.30),(.06,.035,.06),'gold')
    if h=='JoyBoy':
        for s in (-1,1):
            b.box((s*.55,-1.055,1.36),(.36,.14,.65),'white')
            for z in (1.14,1.40,1.64): b.box((s*.47,-1.15,z),(.075,.06,.075),'gold')
    if h=='Brook':
        for s in (-1,1): b.beam((s*.62,-1.05,1.59),(s*.18,-1.19,.97),.16,'graphite',.10)
    b.tag('layered costume seams, hardware and polished micro-bevel edges')

def setup_studio(scene):
    col=bpy.data.collections.new('Presentation_Studio'); scene.collection.children.link(col)
    def link(obj): col.objects.link(obj); return obj
    cam=link(bpy.data.objects.new('Preview_Camera',bpy.data.cameras.new('Preview_Camera')))
    cam.data.type='ORTHO' if 'ORTHO' in [i.identifier for i in cam.data.bl_rna.properties['type'].enum_items] else cam.data.type
    scene.camera=cam
    for name,loc,energy,size in [('Key',(-4,-6,8),700,6),('Fill',(5,-2,5),450,5),('Rim',(1,5,7),900,4)]:
        data=bpy.data.lights.new(name,'AREA'); data.energy=energy; data.shape='DISK'; data.size=size
        o=link(bpy.data.objects.new(name,data)); o.location=loc; o.rotation_euler=(Vector((0,0,1.5))-o.location).to_track_quat('-Z','Y').to_euler()
    scene.world.color=(.15,.15,.15)
    scene.world.use_nodes=True
    bg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND')
    bg.inputs['Color'].default_value=(.20,.25,.34,1); bg.inputs['Strength'].default_value=.45
    scene.render.resolution_x=900; scene.render.resolution_y=1020; scene.render.resolution_percentage=100
    scene.render.film_transparent=True
    scene.render.image_settings.file_format='PNG'; scene.render.image_settings.color_mode='RGBA'
    scene.render.engine='BLENDER_EEVEE_NEXT'
    if hasattr(scene,'eevee'): scene.eevee.taa_render_samples=64
    transforms=[i.identifier for i in scene.view_settings.bl_rna.properties['view_transform'].enum_items]
    if 'Standard' in transforms: scene.view_settings.view_transform='Standard'
    scene.view_settings.exposure=-.25
    return cam,col

def render_one(scene,cam,obj,path):
    bpy.context.view_layer.update()
    corners=[obj.matrix_world @ Vector(c) for c in obj.bound_box]
    lo=Vector(tuple(min(p[i] for p in corners) for i in range(3)))
    hi=Vector(tuple(max(p[i] for p in corners) for i in range(3)))
    target=(lo+hi)/2
    cam.location=target+Vector((4.3,-10.5,5.0))
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.ortho_scale=max((hi.z-lo.z)*1.23,(hi.x-lo.x)*1.40)
    scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True)

def mesh_stats(obj):
    bpy.context.view_layer.update()
    deps=bpy.context.evaluated_depsgraph_get(); mesh=obj.evaluated_get(deps).to_mesh()
    mesh.calc_loop_triangles()
    stats={'vertices':len(mesh.vertices),'triangles':len(mesh.loop_triangles),'materials':len(mesh.materials)}
    obj.evaluated_get(deps).to_mesh_clear()
    return stats

def validate_exports(records):
    test=bpy.data.scenes.new('Validation_Temporary')
    bpy.context.window.scene=test
    results=[]
    for record in records:
        before=set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=str(PUBLIC/'fbx'/record['file']),use_custom_props=True)
        imported=list(set(bpy.data.objects)-before)
        meshes=[o for o in imported if o.type=='MESH']
        bpy.context.view_layer.update()
        corners=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box]
        lo=[min(p[i] for p in corners) for i in range(3)]; hi=[max(p[i] for p in corners) for i in range(3)]
        dims=[hi[i]-lo[i] for i in range(3)]
        bad=[]
        for o in meshes:
            for value in [o.name,o.data.name]+[m.name for m in o.data.materials if m]+list(o.keys())+[str(o[k]) for k in o.keys() if isinstance(o[k],str)]:
                if not value.isascii(): bad.append(value)
            for m in o.data.materials:
                if m:
                    for key in m.keys():
                        if not key.isascii() or (isinstance(m[key],str) and not m[key].isascii()): bad.append(str(key))
        r={'hero_id':record['hero_id'],'mesh_count':len(meshes),'dimensions_studs':[round(d,5) for d in dims],
           'expected_height':record['target_height'],'height_error':abs(dims[2]-record['target_height']),
           'ground_origin_error':abs(lo[2]),'ascii_metadata':not bad,'non_ascii':bad,
           'unit_scale':test.unit_settings.scale_length,'finite_vertices':all(math.isfinite(c) for o in meshes for v in o.data.vertices for c in v.co)}
        r['passed']=len(meshes)==1 and r['height_error']<.015 and r['ground_origin_error']<.015 and not bad and r['finite_vertices']
        results.append(r)
        for o in imported: bpy.data.objects.remove(o,do_unlink=True)
        print('VALIDATED',record['hero_id'],r['passed'],flush=True)
    bpy.context.window.scene=bpy.data.scenes['HeroEggs_Library']
    bpy.data.scenes.remove(test)
    return results

def main():
    p=argparse.ArgumentParser(); p.add_argument('--only',default=''); p.add_argument('--no-render',action='store_true'); p.add_argument('--no-validate',action='store_true')
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    for folder in (OUT/'fbx',OUT/'previews',PUBLIC/'fbx',PUBLIC/'previews',ROOT/'audit'): folder.mkdir(parents=True,exist_ok=True)
    # Batch-only safety: never modify a running user's scene through this entrypoint.
    if not bpy.app.background: raise RuntimeError('Run this generator in a separate Blender background process.')
    bpy.context.preferences.filepaths.save_version=0
    for o in list(bpy.data.objects): bpy.data.objects.remove(o,do_unlink=True)
    for c in list(bpy.data.collections): bpy.data.collections.remove(c)
    scene=bpy.context.scene; scene.name='HeroEggs_Library'
    scene.unit_settings.system='NONE'; scene.unit_settings.scale_length=1.0
    materials()
    collections={}
    for i,name in enumerate(STAGES,1):
        c=bpy.data.collections.new('Stage%02d_%s'%(i,name)); scene.collection.children.link(c); collections[i]=c
    chosen=set(args.only.split(',')) if args.only else None
    records=[]; objects=[]
    for hero,stage,rarity,scale in ROSTER:
        if chosen and hero not in chosen: continue
        b=Builder(hero); shell(b,hero); accessories(b,hero); costume_finish(b,hero)
        obj=b.finish(collections[stage],scale); obj['Stage']=stage; obj['Rarity']=rarity
        bpy.context.view_layer.objects.active=obj; obj.select_set(True)
        for other in bpy.context.selected_objects:
            if other!=obj: other.select_set(False)
        file=hero+'_Egg.fbx'
        bpy.ops.export_scene.fbx(filepath=str(PUBLIC/'fbx'/file),use_selection=True,object_types={'MESH'},
            global_scale=1.0,apply_unit_scale=True,use_mesh_modifiers=True,axis_forward='-Z',axis_up='Y',
            bake_anim=False,use_custom_props=True,add_leaf_bones=False,path_mode='COPY',embed_textures=True)
        shutil.copy2(PUBLIC/'fbx'/file,OUT/'fbx'/file)
        record={'hero_id':hero,'stage':stage,'rarity':rarity,'boss_scale':scale,'target_height':3.2*scale,
                'file':file,'features':b.features,'art_direction':'faceless_textured_v3','stud_count':b.stud_count,
                'stud_texture':'Stud_Normal.png','uv_map':'StudUV',
                'neon_materials':[c for c in b.palette if c.startswith(('glow','gem'))],**mesh_stats(obj)}
        records.append(record); objects.append(obj)
        obj.select_set(False); obj.hide_render=True
        print('BUILT',hero,json.dumps(record),flush=True)
    camera,studio=setup_studio(scene)
    if not args.no_render:
        for obj in objects:
            obj.hide_render=False
            render_one(scene,camera,obj,PUBLIC/'previews'/(obj['HeroId']+'.png'))
            shutil.copy2(PUBLIC/'previews'/(obj['HeroId']+'.png'),OUT/'previews'/(obj['HeroId']+'.png'))
            obj.hide_render=True
            print('PREVIEW',obj.name,flush=True)
    # Arrange the editable kit in six labeled rows. FBXs were exported at origin.
    for stage in range(1,7):
        row=[o for o in objects if o['Stage']==stage]
        for i,obj in enumerate(row):
            obj.location=(i*5.5,(stage-1)*7.0,0); obj.hide_render=False
    # Keep presentation objects out of ordinary modeling selection.
    studio.hide_viewport=True; studio.hide_render=True
    validation=[] if args.no_validate else validate_exports(records)
    scene['AssetCount']=len(objects); scene['HeroCount']=sum(r['rarity']!='Boss' for r in records)
    scene['BossCount']=sum(r['rarity']=='Boss' for r in records)
    scene['UnitConvention']='1 Blender unit = 1 Roblox stud. Export assets have ground-center origin.'
    scene['FrontAxis']='-Y in Blender; FBX is Y-up / -Z-forward.'
    scene['ValidationPassed']=bool(validation) and all(r['passed'] for r in validation)
    # Present all rows in an orthographic material viewport when opened.
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=='VIEW_3D':
                space=area.spaces.active; space.shading.color_type='MATERIAL'; space.shading.light='STUDIO'
                if 'MATERIAL' in [i.identifier for i in space.shading.bl_rna.properties['type'].enum_items]: space.shading.type='MATERIAL'
                space.shading.show_cavity=True; space.overlay.show_floor=False
                space.region_3d.view_distance=53
                space.region_3d.view_location=(20,16,0)
                space.region_3d.view_rotation=Vector((.3,-1,.85)).to_track_quat('Z','Y')
    bpy.context.view_layer.update()
    manifest={'schema_version':3,'art_direction':'Faceless hero costume eggs, broad voxel tiers, actual UV-mapped square stud PBR texture','generator':'audit/generate_voxel_eggs_bpy.py','blender_version':bpy.app.version_string,
        'asset_count':len(records),'hero_count':sum(r['rarity']!='Boss' for r in records),'boss_count':sum(r['rarity']=='Boss' for r in records),
        'units':'1 Blender unit = 1 Roblox stud','size_policy':'Entire asset, including accessories, is 3.2 * boss_scale studs high. Width and depth vary with signature accessories.',
        'front':'-Y','origin':'ground center','ascii_export_directory':str(PUBLIC).replace('\\','/'),
        'fbx_axis_forward':'-Z','fbx_axis_up':'Y','assets':records}
    report={'all_passed':bool(validation) and all(r['passed'] for r in validation),'count':len(validation),'checks':validation}
    for dest in (OUT,PUBLIC):
        prefix='preview_' if chosen else ''
        (dest/(prefix+'manifest.json')).write_text(json.dumps(manifest,indent=2,ensure_ascii=True),encoding='ascii')
        (dest/(prefix+'validation.json')).write_text(json.dumps(report,indent=2,ensure_ascii=True),encoding='ascii')
        material_guide={('HE_'+key):{'srgb_hex':hx,'roblox_material':'Neon' if key.startswith(('glow','gem')) else 'SmoothPlastic',
            'color_map':'textures/HE_'+key+'_Stud.png','normal_map':'textures/Stud_Normal.png','roughness_map':'textures/Stud_Roughness.png'} for key,hx in COLORS.items()}
        (dest/'RobloxMaterialGuide.json').write_text(json.dumps(material_guide,indent=2),encoding='ascii')
    # A copy of the portable generator accompanies the ASCII backup.
    shutil.copy2(Path(__file__),PUBLIC/'generate_voxel_eggs_bpy.py')
    blend=OUT/('HeroEggsKit.blend' if not chosen else 'HeroEggsKit_Preview.blend')
    bpy.data.orphans_purge(do_recursive=True)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    shutil.copy2(blend,PUBLIC/blend.name)
    print('COMPLETE',len(objects),'validation',report['all_passed'],flush=True)
    if validation and not report['all_passed']: raise RuntimeError('FBX validation failed; inspect validation.json')

if __name__=='__main__': main()
