"""Compose delivery contact sheets from the generator's transparent renders."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import json
import re
import shutil

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'eggs'
PUBLIC=Path('C:/Users/Public/HeroEggs')
DATA=json.loads((OUT/'manifest.json').read_text())
FONT=Path('C:/Windows/Fonts')
BG='#0B1321'; CARD='#152236'; INK='#F0F5FC'; MUTED='#96ABC6'
RARITY={'Common':'#B7C5D4','Rare':'#57AFF5','Epic':'#B994FF','Legendary':'#F6C555','Mythic':'#FF718B','Secret':'#8EF1E0','Boss':'#FF9867'}
NAMES=['The Avengers','Justice League','Spider-Verse','My Hero Academia','Dragon Ball','One Piece']
LOCATIONS=['Forest / Stark Lab','Lake / Hall of Justice','Desert / Brooklyn Rooftop','Jungle / UA Hero Arena','Snow / Capsule Corp','Volcano / Sunny Pirate Wharf']
def font(n,bold=False): return ImageFont.truetype(str(FONT/('segoeuib.ttf' if bold else 'segoeui.ttf')),n)
def name(hero):
    return {'SpiderMan2099':'Spider-Man 2099','SpiderGwen':'Spider-Gwen','JoyBoy':'Joy Boy','Flash':'The Flash'}.get(hero,re.sub(r'(?<=[a-z])(?=[A-Z])',' ',hero))
def card(im,rect,asset,small=False):
    x,y,w,h=rect; draw=ImageDraw.Draw(im)
    draw.rounded_rectangle((x,y,x+w,y+h),radius=12,fill=CARD)
    draw.rounded_rectangle((x+12,y+13,x+15,y+40),radius=1,fill=RARITY[asset['rarity']])
    pic=Image.open(OUT/'previews'/(asset['hero_id']+'.png')).convert('RGBA')
    thumb_w=w-16; thumb_h=h-75
    pic.thumbnail((thumb_w,thumb_h),Image.Resampling.LANCZOS)
    # A restrained contact shadow keeps the transparent renders grounded.
    shadow=Image.new('RGBA',im.size)
    sd=ImageDraw.Draw(shadow); cy=y+h-72
    sd.ellipse((x+w*.23,cy-10,x+w*.78,cy+8),fill=(0,0,0,100))
    shadow=shadow.filter(ImageFilter.GaussianBlur(7)); im.alpha_composite(shadow)
    im.alpha_composite(pic,(int(x+(w-pic.width)/2),int(y+8+(thumb_h-pic.height)/2)))
    draw=ImageDraw.Draw(im)
    fs=19 if small else 25
    draw.text((x+15,y+h-61),name(asset['hero_id']),font=font(fs,True),fill=INK)
    desc=asset['rarity'].upper()
    if asset['rarity']=='Boss': desc+='  /  '+str(asset['boss_scale'])+'x'
    draw.text((x+16,y+h-32),desc,font=font(13 if small else 16),fill=RARITY[asset['rarity']])

def main():
    sheets=OUT/'previews'
    for stage in range(1,7):
        assets=[a for a in DATA['assets'] if a['stage']==stage]
        cols=5 if len(assets)>8 else 4
        w=1800; h=1160; margin=48; gap=20; cw=(w-margin*2-gap*(cols-1))//cols; ch=446
        im=Image.new('RGBA',(w,h),BG); d=ImageDraw.Draw(im)
        d.text((margin,30),'STEAL A HERO  /  VOXEL EGG COLLECTION',font=font(21,True),fill='#72DACF')
        d.text((margin,75),f'{stage:02d}  {NAMES[stage-1].upper()}',font=font(48,True),fill=INK)
        d.text((margin,137),LOCATIONS[stage-1],font=font(22),fill=MUTED)
        for i,a in enumerate(assets):
            card(im,(margin+(i%cols)*(cw+gap),190+(i//cols)*(ch+gap),cw,ch),a)
        d=ImageDraw.Draw(im)
        d.text((margin,1122),'FACELESS COSTUME EGGS  /  SQUARE STUD TEXTURE  /  INDIVIDUAL FBX',font=font(16),fill=MUTED)
        d.text((1360,1122),f'{len(assets)-1} HEROES + 1 BOSS',font=font(16,True),fill=INK)
        im.convert('RGB').save(sheets/f'Stage{stage:02d}_ContactSheet.jpg',quality=95)
    # Every stage occupies one row; bosses remain the last asset in each row.
    w=2600; margin=40; gap=15; cw=266; ch=310; rowh=365
    im=Image.new('RGBA',(w,2405),BG); d=ImageDraw.Draw(im)
    d.text((margin,25),'STEAL A HERO',font=font(57,True),fill=INK)
    d.text((margin,97),'VOXEL EGGS + STUD TEXTURE  /  38 HEROES + 6 BOSSES  /  SIX STAGES',font=font(25),fill='#72DACF')
    for stage in range(1,7):
        y=159+(stage-1)*rowh
        d=ImageDraw.Draw(im); d.text((margin,y),f'{stage:02d}  {NAMES[stage-1].upper()}',font=font(21,True),fill=INK)
        assets=[a for a in DATA['assets'] if a['stage']==stage]
        for i,a in enumerate(assets): card(im,(margin+i*(cw+gap),y+36,cw,ch),a,True)
        if len(assets)<9:
            x=margin+7*(cw+gap)+17
            d=ImageDraw.Draw(im)
            d.text((x,y+147),LOCATIONS[stage-1].split(' / ')[0].upper(),font=font(28,True),fill='#48617F')
            d.text((x,y+185),LOCATIONS[stage-1].split(' / ')[1],font=font(19),fill=MUTED)
    d=ImageDraw.Draw(im)
    d.text((margin,2370),'3.2 STUD HERO HEIGHT  /  BOSSES SCALED PER ROSTER  /  THUMBNAILS FIT INDIVIDUALLY',font=font(18),fill=MUTED)
    im.convert('RGB').save(sheets/'HeroEggs_Overview.jpg',quality=96)
    # A large detail board for the reference-derived pirate designs.
    im=Image.new('RGBA',(1800,890),BG); d=ImageDraw.Draw(im)
    d.text((40,28),'THE PIRATE COLLECTION',font=font(43,True),fill=INK)
    d.text((43,88),'FACELESS SHELLS  /  ROBLOX-STYLE STUD TEXTURE  /  SIGNATURE ACCESSORIES',font=font(20),fill='#72DACF')
    for i,h in enumerate(('Luffy','Zoro','JoyBoy')):
        a=next(a for a in DATA['assets'] if a['hero_id']==h)
        card(im,(40+i*585,146,550,688),a)
    im.convert('RGB').save(sheets/'Pirate_Detail.jpg',quality=96)
    for p in sheets.glob('*.jpg'): shutil.copy2(p,PUBLIC/'previews'/p.name)
    print('Created overview, six stage sheets and pirate detail board.')

if __name__=='__main__': main()
