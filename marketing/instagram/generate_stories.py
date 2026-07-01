#!/usr/bin/env python3
"""Sankofa Twi — Story slides for each Highlight (9:16, 1080x1920)."""
from PIL import Image, ImageDraw, ImageFont, ImageChops
import os, shutil
CHAR=(43,43,45); CREAM=(237,228,211); GOLD=(227,169,44); TERRA=(190,82,53)
RED=(155,45,42); GREEN=(46,107,59); TERRACOTTA=(226,114,91); KENTE=[GOLD,RED,GREEN,CHAR,TERRACOTTA]
FD="/usr/share/fonts/truetype"; POP_B=f"{FD}/google-fonts/Poppins-Bold.ttf"
LATO=f"{FD}/lato/Lato-Regular.ttf"; LATO_B=f"{FD}/lato/Lato-Bold.ttf"; LATO_L=f"{FD}/lato/Lato-Light.ttf"
ICON="../../app/assets/icon/app_icon_foreground.png"
W,H=1080,1920
def F(p,s): return ImageFont.truetype(p,s)
def center(d,cx,y,t,f,fill): d.text((cx-d.textlength(t,font=f)/2,y),t,font=f,fill=fill)
def kente_bar(d,x,y,w,h,unit=44):
    i=0;cx=x
    while cx<x+w: d.rectangle([cx,y,min(cx+unit,x+w),y+h],fill=KENTE[i%5]);cx+=unit;i+=1
def brand_glyph(color):
    fg=Image.open(ICON).convert("RGBA");L=fg.convert("L");sa=fg.getchannel("A")
    op=sa.point(lambda p:255 if p>127 else 0);lo,hi=95,155
    a=L.point(lambda p:255 if p<=lo else (0 if p>=hi else int(255*(hi-p)/(hi-lo))))
    a=ImageChops.multiply(a,op);g=Image.new("RGBA",fg.size,color+(0,));g.putalpha(a);return g.crop(a.getbbox())
def fitg(base,g,cx,cy,box):
    gw,gh=g.size;sc=min(box/gw,box/gh);nw,nh=int(gw*sc),int(gh*sc)
    base.alpha_composite(g.resize((nw,nh),Image.LANCZOS),(int(cx-nw/2),int(cy-nh/2)))

def story_from_square(src,out,handle="@sankofatwi"):
    im=Image.new("RGBA",(W,H),CHAR+(255,));d=ImageDraw.Draw(im)
    kente_bar(d,0,0,W,18);kente_bar(d,0,H-18,W,18)
    card=Image.open(src).convert("RGBA").resize((1000,1000),Image.LANCZOS)
    # soft border card, centered
    im.alpha_composite(card,(40,int((H-1000)/2)-40))
    center(d,W/2,H-150,handle,F(LATO_B,40),GOLD)
    center(d,W/2,H-96,"sankofaapp.io",F(LATO,34),CREAM)
    im.convert("RGB").save(out)

def beta_slide(out):
    im=Image.new("RGBA",(W,H),CHAR+(255,));d=ImageDraw.Draw(im)
    kente_bar(d,0,0,W,18);kente_bar(d,0,H-18,W,18);cx=W/2
    fitg(im,brand_glyph(GOLD),cx,560,300)
    center(d,cx,800,"Get the app.",F(POP_B,110),CREAM)
    center(d,cx,940,"Free Android beta · one tap to install",F(LATO_L,42),CREAM)
    # faux link pill (real tap = add IG Link sticker here)
    lab="  sankofaapp.io  ";f=F(LATO_B,46);tw=d.textlength(lab,font=f)
    d.rounded_rectangle([cx-tw/2-40,1120,cx+tw/2+40,1230],radius=54,fill=TERRA)
    center(d,cx,1150,lab,f,(255,255,255))
    center(d,cx,1300,"Add a LINK sticker over this button in Instagram",F(LATO_L,34),(200,196,188))
    im.convert("RGB").save(out)

MAP={
 "start":[("posts/00_intro.png",)],
 "words":[("posts/02_wotd_akwaaba.png",),("posts/05_wotd_medaase.png",),("posts/06_wotd_etesen.png",)],
 "adinkra":[("posts/01_adinkra_sankofa.png",),("posts/04_adinkra_gyenyame.png",),("posts/07_adinkra_dwennimmen.png",)],
 "culture":[("posts/03_culture_daynames.png",),("posts/08_culture_greetings.png",)],
 "lens":[("reel/1_cover.png",)],   # already 9:16
}
os.makedirs("stories",exist_ok=True)
for hl,items in MAP.items():
    os.makedirs(f"stories/{hl}",exist_ok=True)
    for i,(src,) in enumerate(items,1):
        out=f"stories/{hl}/{i}.png"
        if src.startswith("reel/"): shutil.copy(src,out)   # lens cover is already vertical
        else: story_from_square(src,out)
os.makedirs("stories/beta",exist_ok=True); beta_slide("stories/beta/1.png")
print("Story slides built for:", ", ".join(list(MAP.keys())+["beta"]))
