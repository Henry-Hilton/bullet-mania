"""Export the current primitive-drawn character designs, without generated art."""
from pathlib import Path
import math
import zipfile
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).parent / 'characters'
OUT.mkdir(parents=True, exist_ok=True)
CYAN=(40,240,255); PINK=(255,55,155); GOLD=(255,210,80); VIOLET=(155,90,255)
BG=(6,8,22)
def model(kind):
    im=Image.new('RGBA',(400,340))
    d=ImageDraw.Draw(im)
    x,y=200,160
    scale=2 if kind>=3 else 3
    def circle(cx,cy,r,c,alpha=255,outline=False):
        box=(cx-r,cy-r,cx+r,cy+r)
        d.ellipse(box,outline=(*c,alpha) if outline else None,fill=None if outline else (*c,alpha),width=2)
    def glow(cx,cy,r,c):
        circle(cx,cy,r*2.6,c,15);circle(cx,cy,r*1.7,c,36);circle(cx,cy,r,c)
    if kind==-1:
        circle(x,y,26*scale,CYAN,38)
        def pt(r,a): return (x+math.cos(math.radians(a))*r*scale,y-math.sin(math.radians(a))*r*scale)
        points=[pt(18,90),pt(18,222),pt(18,318)]
        d.line(points+[points[0]],fill=CYAN,width=3)
        for p in points[1:]:d.line([p,(x,y+5*scale)],fill=CYAN,width=4)
        glow(x,y+17*scale,4*scale,VIOLET)
        circle(x,y,4*scale,(255,255,255))
    else:
        c=[PINK,VIOLET,GOLD,VIOLET,GOLD,CYAN][kind]
        r=(48 if kind>=3 else 20)*scale
        circle(x,y,r*1.8,c,25)
        sides=kind+1 if kind>=3 else 4
        points=[(x+math.cos(k*math.tau/sides)*r,y-math.sin(k*math.tau/sides)*r) for k in range(sides)]
        d.line(points+[points[0]],fill=c,width=6)
        glow(x,y,(12 if kind>=3 else 5)*scale,c)
        if kind>=3:circle(x,y,60*scale,c,outline=True)
        if kind==3:
            glow(x-64*scale,y,7*scale,PINK);glow(x+64*scale,y,7*scale,VIOLET)
        if kind==4:
            for offset in (-20,20):d.line([(x-80*scale,y+offset*scale),(x+80*scale,y+offset*scale)],fill=GOLD,width=6)
    return im

names=['PLAYER','AIMED SHOOTER','RING EMITTER','FAN SHOOTER','HELIX WARDEN','ION TEMPEST','PRISM ENGINE']
descriptions=['White core / cyan hull','Pink / aimed triple volleys','Violet / radial rings','Gold / sweeping fans','Twin cores / opposing spirals','Wide rails / bullet curtains','Reactor / rings and spiral arms']
files=[]
sheet=Image.new('RGB',(1600,1090),BG)
draw=ImageDraw.Draw(sheet)
font_path='C:/Windows/Fonts/consola.ttf'
title=ImageFont.truetype(font_path,40)
heading=ImageFont.truetype(font_path,21)
small=ImageFont.truetype(font_path,16)
draw.text((42,28),'BULLET MANIA / CHARACTER ROSTER',font=title,fill=CYAN)
draw.text((42,86),'CURRENT IN-GAME DESIGNS / ENLARGED STATIC POSES / DRAWN FROM PRIMITIVES',font=small,fill=(140,150,180))
for i,kind in enumerate(range(-1,6)):
    x=(i%4)*400;y=130+(i//4)*465
    im=model(kind)
    filename=names[i].lower().replace(' ','_')+'.png'
    im.save(OUT/filename);files.append(OUT/filename)
    draw.rectangle((x+12,y+10,x+388,y+437),fill=(11,15,32),outline=(38,47,72))
    sheet.paste(im,(x,y+8),im)
    draw.text((x+200,y+360),names[i],font=heading,anchor='mm',fill=(235,240,255))
    draw.text((x+200,y+398),descriptions[i],font=small,anchor='mm',fill=(140,150,180))
draw.text((1220,675),'NO SPRITE ASSETS',font=heading,fill=CYAN)
draw.text((1220,722),'The live game rotates',font=small,fill=(140,150,180))
draw.text((1220,750),'and animates these shapes.',font=small,fill=(140,150,180))
draw.text((42,1050),'Transparent PNG exports are visual references; gameplay continues to draw the models in code.',font=small,fill=(140,150,180))
sheet.save(OUT/'bullet_mania_roster.png')
with zipfile.ZipFile(OUT/'bullet_mania_characters.zip','w',zipfile.ZIP_DEFLATED) as z:
    for f in files:z.write(f,f.name)
print(OUT/'bullet_mania_roster.png')
