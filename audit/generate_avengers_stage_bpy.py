"""Stage 1 / Avengers: 94 x 152 stud modular toy city.
Run with Blender 4.5 in background, --factory-startup --python this_file.
All outputs use C:/Users/Public/AvengersStage (ASCII paths only).
Front entry is -Y. The active play area remains open between the sidewalks.
"""
import bpy
import bmesh
import math
import random
import json
import shutil
import argparse
import sys
from pathlib import Path
from mathutils import Vector

OUT=Path('C:/Users/Public/AvengersStage')
ROOT=Path(__file__).resolve().parents[1]
RNG=random.Random(104)
PALETTE={
 'asphalt':'344557','asphalt2':'405264','crack':'172433','concrete':'B7C5CF','curb':'D6E0E5',
 'white':'F5F1E3','black':'131F30','steel':'576E82','silver':'9FB8C8','navy':'183B63',
 'blue':'2468B6','glass':'297D9C','glasslight':'59B8D0','glassdark':'18455F',
 'brick':'A7553E','bricklight':'C97A55','brownstone':'CE986D','sand':'E4C9A0',
 'roof':'4C626B','wood':'76472C','woodlight':'AC7147','green':'498966','leaf':'79B45B',
 'red':'DC3441','gold':'DCA836','yellow':'F4C943','purple':'7447A4','purpledark':'33274F',
 'orange':'ED843A','hotdog':'A3492D','bun':'E8B66A','water':'3279A5',
 'cyanGlow':'56DCEB','warmGlow':'FFE3A0','redGlow':'FF4D4A','blueGlow':'54A5FF',
 'purpleGlow':'B588FF','greenGlow':'83F9A4','orangeGlow':'FFB05C','goldGlow':'FFE36B',
}
MATS={}; COLS={}; ASSETS=[]; ANCHORS=[]
MODULES=['Avengers_Skyline','Avengers_Road_Floor','Avengers_Vehicles_Taxis','Avengers_Props_Kit','Avengers_ThanosPlatform']

def linear(c):
    c/=255
    return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4

def init_materials():
    for name,hx in PALETTE.items():
        rgb=tuple(linear(int(hx[i:i+2],16)) for i in (0,2,4))
        m=bpy.data.materials.new('AV_'+name); m.use_nodes=True; m.diffuse_color=(*rgb,1)
        p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        p.inputs['Base Color'].default_value=(*rgb,1)
        p.inputs['Roughness'].default_value=.40 if name in ('glass','glasslight','glassdark','gold','silver') else .59
        p.inputs['Metallic'].default_value=.22 if name in ('gold','silver','steel') else 0
        if name.endswith('Glow'):
            p.inputs['Emission Color'].default_value=(*rgb,1); p.inputs['Emission Strength'].default_value=2.3
        m['RobloxMaterial']='Neon' if name.endswith('Glow') else 'SmoothPlastic'
        MATS[name]=m

class Mesh:
    def __init__(self,name):
        self.name=name; self.v=[]; self.f=[]; self.mi=[]; self.smooth=[]; self.pal=[]; self.bevel_points=set(); self.studs=0
    def face(self,points,color,smooth=False,bevel=True):
        n=len(self.v); self.v.extend(tuple(p) for p in points); self.f.append(tuple(range(n,n+len(points))))
        if color not in self.pal: self.pal.append(color)
        self.mi.append(self.pal.index(color)); self.smooth.append(smooth)
        if bevel: self.bevel_points.update(tuple(round(c,5) for c in p) for p in points)
    def box(self,p,size,color,rz=0,rx=0,ry=0):
        from mathutils import Euler
        x,y,z=p; a,b,c=[d/2 for d in size]; rot=Euler((rx,ry,rz)).to_matrix()
        vs=[Vector(p)+rot@Vector(q) for q in [(-a,-b,-c),(a,-b,-c),(a,b,-c),(-a,b,-c),(-a,-b,c),(a,-b,c),(a,b,c),(-a,b,c)]]
        for ids in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]: self.face([vs[i] for i in ids],color)
    def beam(self,a,b,width,color,depth=None):
        a,b=Vector(a),Vector(b); d=b-a; q=d.to_track_quat('Z','Y'); w=width/2; t=(depth or width)/2; h=d.length/2
        vs=[(a+b)/2+q@Vector(p) for p in [(-w,-t,-h),(w,-t,-h),(w,t,-h),(-w,t,-h),(-w,-t,h),(w,-t,h),(w,t,h),(-w,t,h)]]
        for ids in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]: self.face([vs[i] for i in ids],color)
    def line(self,points,width,color):
        for a,b in zip(points,points[1:]): self.beam(a,b,width,color)
    def cylinder(self,p,r,h,color,n=16,axis=(0,0,1),r2=None,chamfer=0):
        q=Vector(axis).to_track_quat('Z','Y'); p=Vector(p); r2=r if r2 is None else r2
        if chamfer:
            rings=[(r-chamfer,-h/2),(r,-h/2+chamfer),(r2,h/2-chamfer),(r2-chamfer,h/2)]
        else: rings=[(r,-h/2),(r2,h/2)]
        verts=[[p+q@Vector((rr*math.cos(i*math.tau/n),rr*math.sin(i*math.tau/n),z)) for i in range(n)] for rr,z in rings]
        self.face(list(reversed(verts[0])),color,False,False); self.face(verts[-1],color,False,False)
        for a,b in zip(verts,verts[1:]):
            for i in range(n): self.face([a[i],a[(i+1)%n],b[(i+1)%n],b[i]],color,True,False)
    def ring(self,p,outer,inner,h,color,n=48):
        x,y,z=p
        for i in range(n):
            a=i*math.tau/n; b=(i+1)*math.tau/n
            v=[(x+r*math.cos(t),y+r*math.sin(t),zz) for zz in (z-h/2,z+h/2) for r,t in ((outer,a),(outer,b),(inner,b),(inner,a))]
            for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(2,3,7,6)]: self.face([v[j] for j in f],color,False,False)
    def studs_grid(self,center,size,z,color,pitch=1.7,r=.28):
        x,y=center; w,d=size
        for i in range(max(1,int((w-.5)/pitch))):
            for j in range(max(1,int((d-.5)/pitch))):
                xx=x+(i-(max(1,int((w-.5)/pitch))-1)/2)*pitch
                yy=y+(j-(max(1,int((d-.5)/pitch))-1)/2)*pitch
                self.cylinder((xx,yy,z+.10),r,.20,color,12,chamfer=.035); self.studs+=1
    def prism(self,points,z,h,color):
        bot=[(x,y,z) for x,y in points]; top=[(x,y,z+h) for x,y in points]
        self.face(bot[::-1],color); self.face(top,color)
        for i in range(len(points)): self.face([bot[i],bot[(i+1)%len(points)],top[(i+1)%len(points)],top[i]],color)
    def finish(self,module,loc=(0,0,0),rz=0,bevel=.055):
        mesh=bpy.data.meshes.new(self.name+'_Mesh'); mesh.from_pydata(self.v,[],self.f); mesh.update()
        for col in self.pal: mesh.materials.append(MATS[col])
        for p,m,s in zip(mesh.polygons,self.mi,self.smooth): p.material_index=m; p.use_smooth=s
        bm=bmesh.new(); bm.from_mesh(mesh); bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00002)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); weights=bm.edges.layers.float.new('bevel_weight_edge')
        for e in bm.edges:
            on=all(tuple(round(c,5) for c in v.co) in self.bevel_points for v in e.verts)
            angle=e.calc_face_angle(0) if e.is_manifold else math.pi
            e[weights]=1 if on and angle>.6 else 0
        bm.to_mesh(mesh); bm.free()
        obj=bpy.data.objects.new(self.name,mesh); COLS[module].objects.link(obj); obj.location=loc; obj.rotation_euler.z=rz
        if bevel:
            mod=obj.modifiers.new('Toy_edge_bevel','BEVEL'); mod.width=bevel; mod.segments=2
            valid=[i.identifier for i in mod.bl_rna.properties['limit_method'].enum_items]
            if 'WEIGHT' in valid: mod.limit_method='WEIGHT'
        obj['Module']=module; obj['Units']='1 Blender unit = 1 Roblox stud'; obj['CylindricalStudCount']=self.studs
        obj['FrontAxis']='-Y'; ASSETS.append(obj)
        return obj

def text_obj(name,body,loc,size,color,module,rz=0,on_ground=False,align='CENTER'):
    data=bpy.data.curves.new(name+'_Text','FONT'); data.body=body; data.align_x=align; data.size=size
    data.extrude=.015; data.bevel_depth=.006; data.bevel_resolution=0
    obj=bpy.data.objects.new(name,data); COLS[module].objects.link(obj); data.materials.append(MATS[color])
    obj.location=loc; obj.rotation_euler=(0,0,rz) if on_ground else (math.pi/2,0,rz)
    bpy.context.view_layer.objects.active=obj; obj.select_set(True); bpy.ops.object.convert(target='MESH'); obj.select_set(False)
    obj['Module']=module; obj['Units']='1 Blender unit = 1 Roblox stud'; ASSETS.append(obj)
    return obj

def anchor(name,p,role):
    o=bpy.data.objects.new(name,None); COLS['Gameplay_Anchors'].objects.link(o); o.location=p; o.empty_display_size=1.5; o['Role']=role
    ANCHORS.append({'name':name,'position':p,'role':role})

def floor():
    module='Avengers_Road_Floor'
    m=Mesh('Ground_94x152'); m.box((0,0,-.65),(94,152,1.3),'navy'); m.box((0,0,-.09),(93.8,151.8,.18),'concrete'); m.finish(module,bevel=.10)
    m=Mesh('Avenue_Asphalt'); m.box((0,0,.035),(52,150,.07),'asphalt')
    # Slab repairs and utility covers give the large ground planes a readable scale.
    for x,y,w,d in [(-8,-44,12,16),(15,41,15,12),(-15,58,9,14),(18,-12,10,15)]: m.box((x,y,.083),(w,d,.025),'asphalt2')
    for y in range(-69,-23,10):
        for x in (-.48,.48): m.box((x,y,.115),(.17,6,.025),'yellow')
    for y in list(range(-65,-22,12))+[39,51,63]:
        for x in (-14,14): m.box((x,y,.12),(.23,4.5,.03),'white')
    for y in (-57,-24,38,53):
        for x in range(-21,22,4): m.box((x,y,.14),(2.35,4.2,.04),'white')
        m.box((0,y-3,.13),(47,.27,.03),'white')
    for x in (-24.7,24.7): m.box((x,0,.15),(.24,147,.045),'white')
    m.finish(module,bevel=.015)
    for side in (-1,1):
        for j in range(12):
            y=-69+j*12
            m=Mesh(('West' if side<0 else 'East')+'_Sidewalk_%02d'%j)
            m.box((side*29,y,.32),(6,11.85,.58),'concrete')
            m.box((side*25.8,y,.33),(.35,11.85,.66),'curb')
            m.studs_grid((side*29,y),(5.5,11.5),.61,'concrete',1.7,.255)
            m.finish(module)
    for x,y in [(-16,-46),(19,31),(-18,42),(17,-61)]:
        m=Mesh('Utility_Cover_%s_%s'%(x,y)); m.cylinder((x,y,.15),1.05,.10,'steel',24)
        for j in range(-2,3): m.box((x,y+j*.31,.21),(1.4,.065,.025),'black')
        m.finish(module,bevel=.015)
    text_obj('Entry_Road_Lettering','AVENGERS',(0,-71,.15),3.3,'white',module,on_ground=True)
    anchor('Player_Entry',(0,-68,1),'Main entry, faces +Y')

def tank(m,x,y,z):
    for xx in (-1.55,1.55):
        for yy in (-1.55,1.55): m.beam((x+xx,y+yy,z),(x+xx*.8,y+yy*.8,z+2.4),.20,'steel')
    m.cylinder((x,y,z+4.1),2.0,3.9,'wood',16,chamfer=.09)
    for zz in (z+2.55,z+4.1,z+5.65): m.ring((x,y,zz),2.06,1.95,.16,'steel',16)
    m.cylinder((x,y,z+6.35),2.25,.72,'roof',16,r2=.08)
    m.beam((x+2.02,y,z+1),(x+2.02,y,z+5.8),.10,'steel')
    m.beam((x+2.65,y,z+1),(x+2.65,y,z+5.8),.10,'steel')
    for zz in range(8): m.beam((x+2.02,y,z+1+zz*.60),(x+2.65,y,z+1+zz*.60),.08,'steel')

def fire_escape(m,w,d,height):
    y=-d/2-.82
    for z in range(6,int(height)-2,5):
        m.box((0,y,z),(w*.68,1.6,.22),'black')
        for x in (-w*.33,w*.33): m.beam((x,y-.72,z),(x,y-.72,z+1.6),.09,'steel')
        m.beam((-w*.33,y-.72,z+1.6),(w*.33,y-.72,z+1.6),.10,'steel')
        for x in range(-int(w*.30),int(w*.30)+1): m.beam((x,y-.72,z),(x,y-.72,z+1.55),.055,'steel')
        if z>6:
            for x in (-1.7,-.7): m.beam((x,y-.50,z-5),(x+2.5,y-.50,z),.10,'steel')
            for k in range(9):
                zz=z-5+k*.56; xx=-1.7+k*.28
                m.beam((xx,y-.5,zz),(xx+1,y-.5,zz),.075,'steel')

def building(name,x,y,w,d,h,color,rz=0,kind='brownstone',shop=None):
    module='Avengers_Skyline'; m=Mesh(name)
    m.box((0,0,h/2+.5),(w,d,h),color)
    m.box((0,0,.65),(w+.35,d+.35,1.1),'steel')
    for z in (4,h-.5): m.box((0,0,z),(w+.55,d+.55,.45),'sand' if kind=='brownstone' else 'silver')
    # Both street facade and visible side walls carry inset windows and mullions.
    floors=max(2,int((h-5)/4.4)); cols=max(2,int(w/3.4))
    for iz in range(floors):
        z=6+iz*4.3
        for ix in range(cols):
            xx=(ix-(cols-1)/2)*(w-2.7)/max(1,cols-1)
            window='warmGlow' if (ix+iz*3)%7==0 else 'glassdark' if kind=='brownstone' else 'glass'
            m.box((xx,-d/2-.06,z),(2.0,.14,2.65),'black')
            m.box((xx,-d/2-.15,z),(1.68,.08,2.32),window)
            m.box((xx,-d/2-.23,z),(.095,.08,2.32),'sand' if kind=='brownstone' else 'silver')
            m.box((xx,-d/2-.23,z),(1.68,.08,.095),'sand' if kind=='brownstone' else 'silver')
            m.box((xx,-d/2-.26,z-1.42),(2.23,.40,.22),'sand' if kind=='brownstone' else 'silver')
        for side in (-1,1):
            for j in range(max(2,int(d/3.6))):
                yy=(j-(max(2,int(d/3.6))-1)/2)*3.4
                m.box((side*(w/2+.055),yy,z),(.14,2.1,2.6),'black')
                m.box((side*(w/2+.14),yy,z),(.075,1.8,2.30),'glassdark' if (j+iz)%5 else 'warmGlow')
    if kind=='brownstone':
        for xx in (-w/2+.25,w/2-.25): m.box((xx,-d/2-.20,h/2),(.4,.3,h-1),'bricklight')
        fire_escape(m,w,d,h)
    else:
        for xx in range(-int(w/2)+1,int(w/2),4): m.box((xx,-d/2-.25,h/2+2),(.18,.18,h-4),'silver')
    for xx in (-w*.28,w*.28):
        m.box((xx,-d/2-.12,2),(w*.36,.2,3.3),'glassdark')
        m.box((xx,-d/2-.26,2),(.12,.1,3.3),'silver')
    m.box((0,-d/2-.5,.35),(4.2,1.25,.6),'concrete')
    if shop:
        m.box((0,-d/2-.48,4.1),(w-.8,.30,1.1),'navy')
        for i in range(int(w)):
            m.box((i-(int(w)-1)/2,-d/2-1.0,3.35),(.98,1.75,.15),'red' if i%2 else 'white',rx=-.13)
    m.box((0,0,h+.46),(w+.6,d+.6,.52),'roof')
    for side in (-1,1):
        m.box((side*w/2,0,h+1.02),(.48,d,1.0),'sand' if kind=='brownstone' else 'silver')
        m.box((0,side*d/2,h+1.02),(w,.48,1.0),'sand' if kind=='brownstone' else 'silver')
    m.studs_grid((0,0),(w-.7,d-.7),h+.73,'roof',1.8,.29)
    if kind=='brownstone': tank(m,w*.23,d*.12,h+.76)
    else:
        m.box((w*.20,d*.15,h+1.50),(4.2,4.8,1.5),'silver')
        for yy in (-1,0,1): m.box((w*.20,d*.15+yy,h+2.3),(3.4,.23,.1),'steel')
        m.beam((-w*.24,d*.20,h+.8),(-w*.24,d*.20,h+7),.16,'steel')
        m.beam((-w*.24-1.4,d*.20,h+4.8),(-w*.24+1.4,d*.20,h+4.8),.12,'steel')
    obj=m.finish(module,(x,y,0),rz)
    if shop:
        local=Vector((0,-d/2-.67,3.77)); p=obj.matrix_world@local
        # Update matrix explicitly before transforming a local shop sign.
        from mathutils import Matrix
        p=Vector((x,y,0))+Matrix.Rotation(rz,3,'Z')@local
        text_obj(name+'_ShopSign',shop,tuple(p),.69,'white',module,rz=rz)

def stark_tower():
    module='Avengers_Skyline'; m=Mesh('Avengers_Tower_Structure')
    m.box((0,62,3.7),(27,23,7.4),'navy')
    m.box((0,62,7.6),(29,25,1.0),'silver')
    for x in range(-10,11,4):
        m.box((x,50.35,3.9),(3.3,.30,5.9),'glasslight')
        m.box((x,50.10,3.9),(.17,.12,6),'silver')
    m.box((0,49.5,1),(13,3,1.5),'concrete'); m.box((0,48.5,.42),(15,3,.65),'curb')
    for side in (-1,1): m.box((side*10.5,62,4),(1.8,25,8),'red')
    m.box((3,64,35),(16,18,54),'glassdark')
    for floor_z in range(10,63,4):
        m.box((3,64,floor_z),(17.2,19.2,.6),'silver')
        for x in range(-3,10,3):
            m.box((x,54.86,floor_z+1.75),(2.64,.22,2.55),'glasslight' if (floor_z+x)%3 else 'glass')
            m.box((x,73.14,floor_z+1.75),(2.64,.22,2.55),'glass')
        for s in (-1,1):
            for yy in range(57,73,3): m.box((3+s*8.15,yy,floor_z+1.7),(.20,2.6,2.5),'glass')
    for x in (-5.3,11.3): m.beam((x,54.6,9),(x-3,54.6,64),.60,'silver')
    for i in range(5):
        m.box((3-i*.70,64,64+i*1.9),(18-i*1.4,20-i*.9,1.8),'silver' if i%2==0 else 'navy')
    m.box((-.1,64,73),(10.2,15,1.5),'red')
    m.studs_grid((-.1,64),(9.8,14.7),73.76,'red',1.75,.29)
    m.beam((2,65,74),(2,65,83),.24,'silver'); m.cylinder((2,65,83.3),.45,.5,'cyanGlow',12)
    # Glass spine and cyan perimeter accents.
    for x in (-5.7,11.7): m.box((x,54.5,37),(.20,.20,50),'cyanGlow')
    m.box((0,49.8,8.4),(20,.3,.22),'cyanGlow')
    m.finish(module,bevel=.09)
    text_obj('Stark_Lobby_Sign','STARK INDUSTRIES',(0,49.87,6.7),1.02,'white',module)
    m=Mesh('Avengers_Illuminated_A')
    # Oversized A + orbit mark on the front of the tower, intentionally geometric.
    m.beam((-3.5,53.8,46),(1.2,53.8,59.5),1.35,'cyanGlow',.36)
    m.beam((1.2,53.8,59.5),(6.6,53.8,46),1.35,'cyanGlow',.36)
    m.beam((-1.8,53.7,50.7),(5.8,53.7,50.7),1.2,'cyanGlow',.38)
    m.line([(-5.8,53.95,47.5),(-7,53.95,53),(-4.5,53.95,59),(1,53.95,62),(7,53.95,58.5),(8.7,53.95,53)],.37,'white')
    m.finish(module,bevel=.035)
    m=Mesh('Stark_Helipad_Balcony')
    m.cylinder((-.5,45.0,35.8),10.5,1.1,'steel',32,chamfer=.15)
    m.cylinder((-.5,45.0,36.39),9.6,.12,'navy',32)
    m.ring((-.5,45,36.48),8.8,8.5,.05,'white',48)
    for x in (-2.5,1.5): m.box((x,45,36.53),(.70,6,.06),'white')
    m.box((-.5,45,36.53),(4.5,.7,.06),'white')
    for a in range(0,360,30):
        r=math.radians(a); m.cylinder((-.5+9.85*math.cos(r),45+9.85*math.sin(r),36.58),.28,.16,'cyanGlow',12)
    for x in (-7,6): m.beam((x,54,27),(x,39,35.5),.7,'steel')
    m.finish(module)
    quinjet((-.5,45,37.2),module)
    # Two compact hologram signs frame the lower tower without closing the route.
    for s in (-1,1):
        m=Mesh('Stark_HoloPanel_'+str(s)); x=s*15.9
        m.box((x,57,18),(6.3,.65,8.6),'navy'); m.box((x,56.6,18),(5.7,.08,8),'glass')
        for zz,w in [(20.5,4.0),(19.4,3.4),(18.3,4.5),(16.0,3.6)]: m.box((x,56.50,zz),(w,.055,.14),'cyanGlow')
        m.box((x,56.48,22),(6.2,.1,.14),'cyanGlow'); m.box((x,56.48,14),(6.2,.1,.14),'cyanGlow')
        m.beam((x,58,8),(x,58,18),.40,'steel'); m.finish(module)
    text_obj('Stark_Holo_01','STARK',(-15.9,56.4,21.0),.68,'cyanGlow',module)
    text_obj('Stark_Holo_02','ARC CORE',(15.9,56.4,21.0),.60,'cyanGlow',module)

def quinjet(loc,module):
    m=Mesh('Quinjet_Helipad_Display')
    m.prism([(-1.2,-4),(1.2,-4),(1.5,2.2),(0,4),(-1.5,2.2)],0,1.0,'steel')
    m.prism([(-1.1,-2),(-6.5,-.3),(-5.9,1.5),(-.5,1.9)],.25,.22,'silver')
    m.prism([(1.1,-2),(.5,1.9),(5.9,1.5),(6.5,-.3)],.25,.22,'silver')
    m.box((0,-1.6,1.15),(1.65,2.9,.6),'glasslight',rx=.13)
    for s in (-1,1):
        m.box((s*1.9,2.3,.3),(1.2,2.4,.6),'navy')
        m.cylinder((s*1.9,3.55,.3),.4,.22,'cyanGlow',12,axis=(0,1,0))
        m.box((s*4.8,.45,.58),(1.5,.55,.08),'red')
        m.box((s*.85,2.2,1.25),(.2,1.7,1.7),'navy',rx=-.35)
    m.finish(module,loc,rz=math.pi)

def skyline():
    specs=[
      ('Manhattan_W01',-38,-46,20,16,22,'brick',math.pi/2,'brownstone','SHAWARMA'),
      ('Manhattan_W02',-38,-18,22,16,31,'brownstone',math.pi/2,'brownstone','EXCELSIOR'),
      ('Manhattan_W03',-38,12,23,16,39,'navy',math.pi/2,'office',None),
      ('Manhattan_W04',-38,43,23,16,27,'brick',math.pi/2,'brownstone','1943 SUPPLY'),
      ('Manhattan_E01',38,-47,22,16,27,'brownstone',-math.pi/2,'brownstone','NYC DELI'),
      ('Manhattan_E02',38,-16,23,16,35,'steel',-math.pi/2,'office','DAILY BUGLE'),
      ('Manhattan_E03',38,15,21,16,23,'brick',-math.pi/2,'brownstone','PIZZA'),
      ('Manhattan_E04',38,47,24,16,43,'navy',-math.pi/2,'office',None),
    ]
    for args in specs: building(*args)
    building('Rear_Skyline_W',-25,68,17,13,44,'steel',0,'office')
    building('Rear_Skyline_E',26,68,16,13,52,'glassdark',0,'office')
    stark_tower()

def vehicle(name,loc,rz=0,police=False,wreck=False,overturned=False):
    m=Mesh(name); c='white' if police else 'yellow'
    m.box((0,0,1.1),(4.65,8.9,1.5),c)
    m.box((0,-.3,2.32),(4.1,4.4,1.4),c)
    m.box((0,-2.42,2.36),(3.70,.15,1.07),'glassdark',rx=-.12)
    m.box((0,1.96,2.36),(3.70,.13,1.07),'glassdark',rx=.12)
    for s in (-1,1):
        for y in (-1.25,.83): m.box((s*2.10,y,2.37),(.085,1.75,1.07),'glasslight')
        m.box((s*2.13,-.15,2.39),(.11,.18,1.2),c)
        for y in (-1.12,1.06): m.box((s*2.37,y,1.54),(.09,.44,.08),'black')
        if police:
            m.box((s*2.38,0,1.28),(.08,7.2,.49),'blue')
        else:
            for j in range(9): m.box((s*2.375,-3.6+j*.8,1.65),(.06,.36,.23),'black')
        for yy in (-2.8,2.75):
            m.cylinder((s*2.30,yy,.85),1.03,.48,'black',16,axis=(1,0,0),chamfer=.09)
            m.cylinder((s*2.56,yy,.85),.54,.07,'silver',12,axis=(1,0,0))
            m.cylinder((s*2.60,yy,.85),.22,.085,'navy',12,axis=(1,0,0))
    for yy in (-4.55,4.55): m.box((0,yy,1.05),(4.7,.24,.38),'silver')
    m.box((0,-4.48,1.45),(1.65,.10,.57),'black')
    for x in (-1.63,1.63):
        m.box((x,-4.48,1.49),(.74,.12,.51),'warmGlow')
        m.box((x,4.48,1.45),(.72,.12,.43),'redGlow')
    m.box((0,3.6,1.94),(3.9,1.2,.15),c,rx=.15 if wreck else 0)
    if police:
        m.box((0,0,3.14),(2.9,.88,.25),'black')
        m.box((-.78,0,3.38),(1.15,.82,.32),'redGlow')
        m.box((.78,0,3.38),(1.15,.82,.32),'blueGlow')
    else:
        m.box((0,0,3.2),(1.72,.85,.46),'white')
        for x in (-.50,0,.50): m.box((x,-.46,3.2),(.15,.035,.20),'black')
    if wreck:
        m.box((.8,-3.55,2.00),(2.7,1.8,.16),c,rx=-.38,ry=.10)
        m.line([(-1.3,-2.53,2.9),(-.6,-2.58,2.48),(-.1,-2.54,2.65),(.5,-2.56,2.12)],.055,'white')
        m.box((2.6,-.2,1.2),(.18,2.5,1.28),c,rz=-.55)
    obj=m.finish('Avengers_Vehicles_Taxis',loc,rz,bevel=.095)
    if overturned: obj.rotation_euler.y=math.radians(107)
    obj['VehicleType']='NYPD patrol car' if police else 'NYC taxi'
    obj['Condition']='Overturned' if overturned else 'Battle damaged' if wreck else 'Parked'
    return obj

def vehicles():
    vehicle('Taxi_Parked_01',(-20,-58,.28),.07)
    vehicle('Taxi_Crashed_02',(-19,-36,.30),-.45,wreck=True)
    vehicle('Taxi_Overturned_03',(18,-5,2.8),.30,wreck=True,overturned=True)
    vehicle('Taxi_Parked_04',(19,44,.25),math.pi-.05)
    vehicle('NYPD_Patrol_01',(19,-55,.26),math.pi+.08,police=True)
    vehicle('NYPD_Damaged_02',(-20,35,.28),-.17,police=True,wreck=True)

def streetlamp(x,y,index):
    m=Mesh('Streetlamp_%02d'%index)
    m.cylinder((0,0,.87),.58,1.1,'navy',12,chamfer=.06)
    m.cylinder((0,0,5.3),.18,8.1,'steel',12)
    m.line([(0,0,9.3),(0,0,10.1),(0,-1.7,10.8),(0,-3.4,10.8)],.23,'navy')
    m.box((0,-3.3,10.7),(1.3,2.2,.45),'navy'); m.box((0,-3.3,10.42),(.98,1.73,.09),'warmGlow')
    m.finish('Avengers_Props_Kit',(x,y,0),rz=-math.pi/2 if x<0 else math.pi/2)

def signal(x,y,index):
    m=Mesh('Traffic_Signal_%02d'%index)
    m.cylinder((0,0,4.8),.17,9.0,'steel',12); m.box((0,0,.4),(.85,.85,.75),'navy')
    m.beam((0,0,9.2),(0,-5.7,9.2),.24,'steel')
    m.box((0,-5.5,7.9),(1.15,.88,3.05),'yellow')
    m.box((0,-6.0,7.9),(.84,.10,2.82),'black')
    for i,col in enumerate(('redGlow','gold','green')): m.cylinder((0,-6.11,8.83-i*.92),.31,.14,col,12,axis=(0,-1,0))
    m.finish('Avengers_Props_Kit',(x,y,0),rz=-math.pi/2 if x<0 else math.pi/2)

def hydrant(x,y,index):
    m=Mesh('Fire_Hydrant_%02d'%index); m.cylinder((0,0,.75),.40,1.1,'red',12,chamfer=.06)
    m.cylinder((0,0,.21),.58,.17,'red',12); m.cylinder((0,0,1.41),.49,.26,'red',12,r2=.3)
    for s in (-1,1):
        m.cylinder((s*.51,0,.86),.24,.40,'red',12,axis=(1,0,0)); m.cylinder((s*.76,0,.86),.25,.10,'silver',8,axis=(1,0,0))
    m.cylinder((0,-.43,.86),.29,.18,'red',12,axis=(0,1,0)); m.finish('Avengers_Props_Kit',(x,y,.61),bevel=.03)

def barrier(x,y,index,rz=0):
    m=Mesh('Jersey_Barrier_%02d'%index)
    m.box((0,0,.22),(5.1,1.8,.44),'concrete'); m.box((0,0,.73),(5,1.18,.70),'concrete'); m.box((0,0,1.3),(4.9,.65,.65),'concrete')
    for xx in (-1.6,0,1.6): m.box((xx,-.36,1.31),(.65,.055,.31),'yellow')
    m.studs_grid((0,0),(4.5,.60),1.63,'concrete',1.25,.19)
    m.finish('Avengers_Props_Kit',(x,y,0),rz)

def hotdog_cart():
    m=Mesh('Battle_Damaged_Hotdog_Cart')
    m.box((0,0,1.3),(3.8,2.5,1.7),'silver'); m.box((0,-1.28,1.4),(3.5,.08,1.25),'red')
    m.box((0,0,2.21),(4.1,2.7,.18),'silver')
    for x in (-1.45,1.45):
        m.cylinder((x,0,.48),.61,.23,'black',12,axis=(1,0,0)); m.cylinder((x*1.05,0,.48),.25,.06,'silver',12,axis=(1,0,0))
    for x in (-1.7,1.7): m.beam((x,.85,2.2),(x,.85,4.45),.12,'steel')
    for i in range(8):
        a=i*math.tau/8; b=(i+1)*math.tau/8
        m.face([(0,0,5.15),(2.85*math.cos(a),2.85*math.sin(a),4.3),(2.85*math.cos(b),2.85*math.sin(b),4.3)],'red' if i%2 else 'yellow')
    for x in (-.95,-.32,.32):
        m.box((x,-.30,2.45),(.47,1.20,.30),'bun'); m.cylinder((x,-.30,2.62),.10,1.05,'hotdog',10,axis=(0,1,0))
    for x,col in ((1.05,'yellow'),(1.48,'red')): m.cylinder((x,.3,2.60),.13,.62,col,10)
    m.finish('Avengers_Props_Kit',(-28,-17,.60),rz=.15)
    text_obj('Hotdog_Cart_Menu','NYC DOGS',(-28,-18.39,1.85),.47,'white','Avengers_Props_Kit',rz=.15)
    m=Mesh('Pretzel_Cart_Debris'); m.box((0,0,.13),(2.2,1.8,.18),'wood',rz=.25)
    for x,y in [(-.45,0),(.35,.15)]:
        m.ring((x,y,.29),.36,.22,.14,'bun',16); m.ring((x+.35,y,.30),.36,.22,.14,'bun',16)
    m.finish('Avengers_Props_Kit',(-26,-21,.61),rz=-.2)

def battle_marks():
    module='Avengers_Props_Kit'
    m=Mesh('Hulk_Smash_Crater'); cx,cy=-10,-35
    m.cylinder((cx,cy,.14),6.2,.05,'crack',20)
    for i in range(15):
        a=i*math.tau/15; r=5.7+RNG.uniform(-.2,.5)
        m.box((cx+r*math.cos(a),cy+r*math.sin(a),.33+RNG.random()*.22),(2.4,1.5,.65),'concrete',rz=a,ry=RNG.uniform(-.20,.25))
    for i in range(9):
        a=i*math.tau/9; points=[]
        for j in range(4):
            r=3+j*1.7; aa=a+(RNG.random()-.5)*.25; points.append((cx+r*math.cos(aa),cy+r*math.sin(aa),.16))
        m.line(points,.20,'crack')
    for x in (-1.1,1.1):
        m.box((cx+x,cy,.19),(1.7,2.0,.06),'green')
        for j in range(4): m.box((cx+x+(j-1.5)*.39,cy-1.15,.19),(.29,.62,.06),'green')
    m.finish(module,bevel=.055)
    m=Mesh('Thor_Lightning_Scorch'); cx,cy=12,-38
    m.cylinder((cx,cy,.14),4.3,.04,'crack',24)
    for i in range(6):
        a=i*math.tau/6
        points=[(cx,cy,.17),(cx+2*math.cos(a+.2),cy+2*math.sin(a+.2),.17),(cx+3.5*math.cos(a-.12),cy+3.5*math.sin(a-.12),.17),(cx+5.2*math.cos(a),cy+5.2*math.sin(a),.17)]
        m.line(points,.22,'black'); m.line([(x,y,z+.03) for x,y,z in points],.055,'cyanGlow')
    m.cylinder((cx,cy,.46),1.05,.65,'steel',12)
    m.box((cx,cy,1.24),(2.15,1.35,1.05),'silver')
    m.beam((cx,cy,1.75),(cx+.35,cy,3.05),.23,'wood')
    for z in (1.9,2.1,2.3,2.5,2.7): m.box((cx+(z-1.75)*.27,cy,z),(.28,.28,.06),'gold')
    m.finish(module,bevel=.07)
    m=Mesh('Captain_Shield_Impact_Wall')
    m.box((0,0,1.85),(6.8,1.0,3.7),'concrete')
    for r,col,y in [(1.32,'red',-.59),(1.03,'white',-.68),(.76,'red',-.76),(.48,'blue',-.83)]: m.cylinder((0,y,2.05),r,.12,col,24,axis=(0,-1,0))
    # Raised five-point star on the embedded shield.
    star=[]
    for i in range(10):
        a=math.pi/2+i*math.pi/5; r=.40 if i%2==0 else .18; star.append((r*math.cos(a),-.91,2.05+r*math.sin(a)))
    m.face(star,'white',bevel=False)
    for s in (-1,1): m.line([(s*1.2,-.54,2.3),(s*1.8,-.54,2.8),(s*2.1,-.54,2.65),(s*2.9,-.54,3.25)],.06,'crack')
    m.studs_grid((0,0),(6.6,.95),3.70,'concrete',1.2,.22)
    m.finish(module,(-23,-51,.2),rz=.25)
    # Hawkeye's arrows, Natasha's supply case, and Stark's portable arc generator.
    m=Mesh('Hawkeye_Arrow_Cluster')
    for i in range(3):
        a=(-.6+i*.45,.2,1.1+i*.3); b=(a[0]-.7,-1.2,2.2+i*.3)
        m.beam(a,b,.055,'black'); m.box(b,(.27,.28,.18),'purple')
    m.finish(module,(-23,40,.2))
    m=Mesh('Widow_Equipment_Case'); m.box((0,0,.8),(2.5,1.6,1.2),'black')
    for x in (-.95,.95): m.box((x,-.82,.85),(.16,.1,.4),'silver')
    m.box((0,-.86,.8),(.50,.06,.52),'red'); m.box((0,-.91,.8),(.62,.06,.09),'black')
    m.finish(module,(28,18,.62))
    m=Mesh('Stark_Arc_Generator'); m.box((0,0,1),(3.4,2.8,1.4),'navy')
    m.cylinder((0,0,1.8),1.15,.40,'silver',20); m.cylinder((0,0,2.05),.81,.12,'cyanGlow',20)
    for i in range(8):
        a=i*math.tau/8; m.box((1.08*math.cos(a),1.08*math.sin(a),2.04),(.2,.2,.18),'red')
    m.finish(module,(28,33,.65))

def props():
    for i,(x,y) in enumerate([(s*26.8,y) for s in (-1,1) for y in (-63,-32,3,37,61)],1): streetlamp(x,y,i)
    for i,(x,y) in enumerate([(-26.8,-55),(26.8,-22),(-26.8,37),(26.8,55)],1): signal(x,y,i)
    for i,(x,y) in enumerate([(-27,-43),(28,-31),(-27,29),(28,60)],1): hydrant(x,y,i)
    for i,(x,y,rz) in enumerate([(-15,-22,.05),(16,33,-.1),(-19,43,.15),(22,-26,.5),(11,43,0)],1): barrier(x,y,i,rz)
    for i,(x,y) in enumerate([(-29,-62),(29,-64),(-28,6),(28,45)],1):
        m=Mesh('Street_Bench_%02d'%i)
        for j in range(4): m.box((0,(j-1.5)*.28,1.0),(3.8,.23,.18),'woodlight')
        for j in range(3): m.box((0,.65,1.35+j*.30),(3.8,.16,.22),'wood')
        for xx in (-1.35,1.35): m.box((xx,0,.62),(.18,1.2,.65),'black')
        m.finish('Avengers_Props_Kit',(x,y,.60),rz=math.pi/2 if x<0 else -math.pi/2)
    for i,(x,y) in enumerate([(-28,-7),(28,-8),(-28,51),(28,4)],1):
        m=Mesh('Street_Planter_%02d'%i); m.box((0,0,1),(2.9,3.6,1.0),'concrete')
        m.box((0,0,1.56),(2.6,3.3,.14),'wood')
        for dx,dy,z in [(-.5,-.7,2.10),(.5,.4,2.3),(-.3,.85,2.0)]: m.box((dx,dy,z),(1.6,1.6,1.25),'leaf' if dx>0 else 'green')
        m.finish('Avengers_Props_Kit',(x,y,0))
    hotdog_cart(); battle_marks()

def nest(x,y,index,col):
    m=Mesh('Egg_Nest_%02d'%index)
    m.cylinder((0,0,.21),3.0,.35,'purpledark',16); m.ring((0,0,.42),2.92,2.62,.15,'gold',24)
    m.cylinder((0,0,.44),2.20,.14,'wood',16)
    for layer in range(3):
        for i in range(11):
            a=i*math.tau/11+layer*.28; r=2.04+(.08 if i%2 else -.06)
            m.box((r*math.cos(a),r*math.sin(a),.62+layer*.23),(1.85,.40,.27),'woodlight' if i%3 else 'wood',rz=a+math.pi/2+(i%2)*.1)
    m.cylinder((0,0,.56),1.4,.08,'sand',16)
    m.box((0,-2.91,.65),(.92,.12,.33),col)
    m.finish('Avengers_ThanosPlatform',(x,y,0),bevel=.04)
    anchor('NestSlot_%02d'%index,(x,y,.78),'Empty nest / egg spawn anchor')

def thanos_platform():
    module='Avengers_ThanosPlatform'; cy=9
    m=Mesh('Thanos_Combat_Platform')
    m.cylinder((0,cy,.42),17,.72,'purpledark',16,chamfer=.16)
    m.cylinder((0,cy,.91),16.3,.28,'gold',16,chamfer=.065)
    m.cylinder((0,cy,1.11),15.65,.24,'purple',16)
    m.ring((0,cy,1.255),14.8,14.55,.06,'gold',48)
    m.ring((0,cy,1.265),8.4,8.18,.045,'gold',48)
    for i in range(16):
        a=i*math.tau/16
        m.box((16.2*math.cos(a),cy+16.2*math.sin(a),.97),(1.5,.35,.18),'goldGlow' if i%4==0 else 'gold',rz=a+math.pi/2)
    # Six gem sigils on the perimeter; the center remains a flat patrol area.
    colors=['purpleGlow','blueGlow','redGlow','orangeGlow','greenGlow','goldGlow']
    for i,col in enumerate(colors):
        a=i*math.tau/6; x,y=11.5*math.cos(a),cy+11.5*math.sin(a)
        m.cylinder((x,y,1.30),1.7,.10,'purpledark',6)
        m.ring((x,y,1.38),1.64,1.40,.07,'gold',6)
        m.prism([(x,y-1),(x+.72,y-.2),(x+.48,y+.82),(x-.48,y+.82),(x-.72,y-.2)],1.39,.07,col)
        m.beam((9.5*math.cos(a),cy+9.5*math.sin(a),1.3),(6.4*math.cos(a),cy+6.4*math.sin(a),1.3),.10,'gold')
    # Infinity emblem inlaid into the central flat floor.
    points=[]
    for i in range(65):
        a=i*math.tau/64; denom=1+math.sin(a)**2
        points.append((4.2*math.cos(a)/denom,cy+4.2*math.sin(a)*math.cos(a)/denom,1.31))
    m.line(points,.21,'goldGlow')
    for x in (-5.5,-3.8,3.8,5.5):
        for yy in (-4,0,4): m.cylinder((x,cy+yy,1.34),.26,.17,'purple',12,chamfer=.025); m.studs+=1
    m.finish(module,bevel=.03)
    for s in (-1,1):
        m=Mesh('Platform_Approach_'+str(s))
        for i in range(3): m.box((0,cy+s*(17.8-i*.75),.22+i*.28),(8.0,.85,.40+i*.10),'purpledark' if i%2==0 else 'gold')
        m.finish(module)
    for i,col in enumerate(colors):
        a=i*math.tau/6; nest(21.3*math.cos(a),cy+21.3*math.sin(a),i+1,col)
    anchor('Thanos_Patrol_Center',(0,cy,1.36),'Boss center / clear flat combat area')
    for i in range(8):
        a=i*math.tau/8; anchor('Thanos_Patrol_%02d'%(i+1),(6.1*math.cos(a),cy+6.1*math.sin(a),1.36),'Suggested patrol waypoint')

def studio(scene):
    c=COLS['Presentation']; camdata=bpy.data.cameras.new('Stage_Preview_Camera'); cam=bpy.data.objects.new('Stage_Preview_Camera',camdata); c.objects.link(cam); scene.camera=cam
    for name,loc,power,size in [('Key',(-70,-65,135),230000,90),('Fill',(100,-30,90),170000,75),('Rim',(20,100,130),240000,70)]:
        data=bpy.data.lights.new(name,'AREA'); data.energy=power; data.size=size
        o=bpy.data.objects.new(name,data); c.objects.link(o); o.location=loc; o.rotation_euler=(Vector((0,10,10))-o.location).to_track_quat('-Z','Y').to_euler()
    data=bpy.data.lights.new('Afternoon_Sun','SUN'); data.energy=1.6; data.angle=math.radians(18)
    o=bpy.data.objects.new('Afternoon_Sun',data); c.objects.link(o); o.rotation_euler=(.42,-.48,-.45)
    scene.world.use_nodes=True; bg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND'); bg.inputs['Color'].default_value=(.15,.22,.32,1); bg.inputs['Strength'].default_value=.40
    scene.render.engine='BLENDER_EEVEE_NEXT'; scene.render.image_settings.file_format='PNG'; scene.render.image_settings.color_mode='RGBA'
    scene.render.film_transparent=True; scene.render.resolution_percentage=100
    if hasattr(scene,'eevee'): scene.eevee.taa_render_samples=64
    transforms=[i.identifier for i in scene.view_settings.bl_rna.properties['view_transform'].enum_items]
    if 'AgX' in transforms: scene.view_settings.view_transform='AgX'
    scene.view_settings.exposure=.0
    return cam

def render(scene,cam,name,loc,target,ortho=None,res=(1800,1500),lens=38):
    cam.location=loc; cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO' if ortho else 'PERSP'; cam.data.ortho_scale=ortho or 100; cam.data.lens=lens
    cam.data.clip_end=1000; scene.render.resolution_x=res[0]; scene.render.resolution_y=res[1]
    scene.render.filepath=str(OUT/'previews'/(name+'.png')); bpy.ops.render.render(write_still=True)
    print('RENDERED',name,flush=True)

def bounds(objects):
    bpy.context.view_layer.update(); corners=[o.matrix_world@Vector(c) for o in objects if o.type=='MESH' for c in o.bound_box]
    lo=[min(p[i] for p in corners) for i in range(3)]; hi=[max(p[i] for p in corners) for i in range(3)]
    return {'min':[round(v,5) for v in lo],'max':[round(v,5) for v in hi],'size':[round(hi[i]-lo[i],5) for i in range(3)]}

def export_all():
    records=[]
    for module in MODULES+['Avengers_Stage_Complete']:
        objs=ASSETS if module.endswith('Complete') else [o for o in ASSETS if o['Module']==module]
        bpy.ops.object.select_all(action='DESELECT')
        for o in objs: o.select_set(True)
        bpy.context.view_layer.objects.active=objs[0]
        path=OUT/'fbx'/(module+'.fbx')
        bpy.ops.export_scene.fbx(filepath=str(path),use_selection=True,object_types={'MESH'},global_scale=1,apply_unit_scale=True,use_mesh_modifiers=True,
            axis_forward='-Z',axis_up='Y',bake_anim=False,use_custom_props=True,add_leaf_bones=False,path_mode='AUTO')
        record={'file':path.name,'objects':len(objs),'bytes':path.stat().st_size,'bounds':bounds(objs)}; records.append(record)
        print('EXPORTED',json.dumps(record),flush=True)
    return records

def validate(records):
    original=bpy.context.scene; test=bpy.data.scenes.new('Import_Validation'); bpy.context.window.scene=test; checks=[]
    for record in records:
        before=set(bpy.data.objects); bpy.ops.import_scene.fbx(filepath=str(OUT/'fbx'/record['file']),use_custom_props=True)
        obs=list(set(bpy.data.objects)-before); meshes=[o for o in obs if o.type=='MESH']; b=bounds(meshes)
        metadata=[o.name for o in meshes]+[o.data.name for o in meshes]+[m.name for o in meshes for m in o.data.materials if m]
        for o in meshes:
            metadata.extend(o.keys()); metadata.extend(str(o[k]) for k in o.keys() if isinstance(o[k],str))
        finite=all(math.isfinite(c) for o in meshes for v in o.data.vertices for c in v.co)
        err=max(abs(b['size'][i]-record['bounds']['size'][i]) for i in range(3))
        r={'file':record['file'],'mesh_count':len(meshes),'bounds':b,'ascii_metadata':all(s.isascii() for s in metadata),'finite':finite,'bounds_error':err}
        r['passed']=len(meshes)==record['objects'] and r['ascii_metadata'] and finite and err<.05
        checks.append(r); print('VALIDATED',record['file'],r['passed'],flush=True)
        for o in obs: bpy.data.objects.remove(o,do_unlink=True)
    bpy.context.window.scene=original; bpy.data.scenes.remove(test)
    return {'all_passed':all(c['passed'] for c in checks),'checks':checks,'roblox_studio_tested':False}

def main():
    p=argparse.ArgumentParser(); p.add_argument('--no-render',action='store_true'); args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    if not bpy.app.background: raise RuntimeError('Run in a separate background Blender process.')
    for folder in (OUT,OUT/'fbx',OUT/'previews'): folder.mkdir(parents=True,exist_ok=True)
    for o in list(bpy.data.objects): bpy.data.objects.remove(o,do_unlink=True)
    for c in list(bpy.data.collections): bpy.data.collections.remove(c)
    scene=bpy.context.scene; scene.name='Stage01_TheAvengers'; scene.unit_settings.system='NONE'; scene.unit_settings.scale_length=1
    bpy.context.preferences.filepaths.save_version=0
    for name in MODULES+['Gameplay_Anchors','Presentation']:
        c=bpy.data.collections.new(name); scene.collection.children.link(c); COLS[name]=c
    init_materials(); floor(); skyline(); vehicles(); props(); thanos_platform()
    print('GENERATED_ASSETS',len(ASSETS),flush=True)
    records=export_all(); results=validate(records)
    cam=studio(scene)
    if not args.no_render:
        render(scene,cam,'01_Stage_Hero',(127,-157,140),(0,7,26),ortho=194,res=(1800,1600))
        render(scene,cam,'02_Player_Entry',(0,-72,7.5),(0,48,22),res=(1920,1080),lens=26)
        render(scene,cam,'03_Thanos_Plaza',(54,-43,54),(0,10,1.7),ortho=78,res=(1600,1250))
        render(scene,cam,'04_Stark_Tower',(63,3,75),(0,59,38),ortho=93,res=(1300,1500))
        render(scene,cam,'05_Battle_Street',(35,-73,38),(-2,-35,2),ortho=66,res=(1600,1200))
        render(scene,cam,'06_Layout_Top',(0,0,220),(0,0,0),ortho=164,res=(1150,1800))
    scene['Stage']='Stage 1: The Avengers'; scene['FootprintStuds']='94 x 152'; scene['Front']='Entry -Y, tower +Y'; scene['Scale']='1 Blender unit = 1 stud'
    scene['CylindricalStudCount']=sum(int(o.get('CylindricalStudCount',0)) for o in ASSETS)
    scene['ValidatedFBX']=results['all_passed']; scene['RobloxStudioTested']=False
    bpy.ops.object.select_all(action='DESELECT')
    COLS['Gameplay_Anchors'].hide_render=True
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=='VIEW_3D':
                sp=area.spaces.active; sp.shading.type='MATERIAL'; sp.overlay.show_floor=False
                sp.clip_end=1000; sp.region_3d.view_distance=225; sp.region_3d.view_location=(0,5,20)
                sp.region_3d.view_rotation=Vector((.72,-1,.9)).to_track_quat('Z','Y')
    # Leave the saved camera on the hero composition, not the diagnostic top view.
    cam.location=(127,-157,140); cam.rotation_euler=(Vector((0,7,26))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type='ORTHO'; cam.data.ortho_scale=194
    scene.render.resolution_x=1800; scene.render.resolution_y=1600
    bpy.data.orphans_purge(do_recursive=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'AvengersStageKit.blend'))
    manifest={'stage':'Stage 1: The Avengers','blender_version':bpy.app.version_string,'units':'1 Blender unit = 1 Roblox stud','footprint':[94,152],
        'asset_count':len(ASSETS),'cylindrical_studs':scene['CylindricalStudCount'],'world_bounds':bounds(ASSETS),
        'modules':records,'anchors':ANCHORS,'design':'Open central avenue; modular Manhattan streetscape; Stark tower; six Infinity gem nests; toy cylindrical studs',
        'material_palette':PALETTE,'validation':results}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='ascii')
    (OUT/'validation.json').write_text(json.dumps(results,indent=2),encoding='ascii')
    shutil.copy2(Path(__file__),OUT/'generate_avengers_stage_bpy.py')
    if not results['all_passed']: raise RuntimeError('Export verification failed; see validation.json')
    print('STAGE_COMPLETE',len(ASSETS),'studs',scene['CylindricalStudCount'],flush=True)

if __name__=='__main__': main()
