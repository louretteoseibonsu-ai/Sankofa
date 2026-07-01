#!/usr/bin/env python3
"""Sankofa Twi — IG profile pics, Highlight covers, Lens Reel kit, campaign reels."""
from PIL import Image, ImageDraw, ImageFont, ImageChops
import os, math

CHAR=(43,43,45); CREAM=(237,228,211); TERRA=(190,82,53)
GOLD=(227,169,44); RED=(155,45,42); GREEN=(46,107,59); TERRACOTTA=(226,114,91)
SLATE=(120,126,133); KENTE=[GOLD,RED,GREEN,CHAR,TERRACOTTA]
FD="/usr/share/fonts/truetype"
POP_B=f"{FD}/google-fonts/Poppins-Bold.ttf"
LATO=f"{FD}/lato/Lato-Regular.ttf"; LATO_B=f"{FD}/lato/Lato-Bold.ttf"
LATO_BLK=f"{FD}/lato/Lato-Black.ttf"; LATO_L=f"{FD}/lato/Lato-Light.ttf"
G="/tmp/glyphs"; ICON="../../app/assets/icon/app_icon_foreground.png"
APPICON="../../app/assets/icon/app_icon.png"
def F(p,s): return ImageFont.truetype(p,s)

def recolor(png,color):
    im=Image.open(png).convert("RGBA");a=im.getchannel("A")
    o=Image.new("RGBA",im.size,color+(0,));o.putalpha(a);return o
def brand_glyph(color):
    fg=Image.open(ICON).convert("RGBA");L=fg.convert("L");sa=fg.getchannel("A")
    op=sa.point(lambda p:255 if p>127 else 0);lo,hi=95,155
    a=L.point(lambda p:255 if p<=lo else (0 if p>=hi else int(255*(hi-p)/(hi-lo))))
    a=ImageChops.multiply(a,op);g=Image.new("RGBA",fg.size,color+(0,));g.putalpha(a)
    return g.crop(a.getbbox())
def fit(base,glyph,cx,cy,box):
    gw,gh=glyph.size;sc=min(box/gw,box/gh);nw,nh=int(gw*sc),int(gh*sc)
    base.alpha_composite(glyph.resize((nw,nh),Image.LANCZOS),(int(cx-nw/2),int(cy-nh/2)))
def kente_bar(d,x,y,w,h,unit=44):
    i=0;cx=x
    while cx<x+w: d.rectangle([cx,y,min(cx+unit,x+w),y+h],fill=KENTE[i%5]);cx+=unit;i+=1
def center(d,cx,y,t,f,fill): d.text((cx-d.textlength(t,font=f)/2,y),t,font=f,fill=fill)
def tracked(d,cx,y,t,f,fill,tr=8):
    tw=sum(d.textlength(c,font=f)+tr for c in t)-tr;x=cx-tw/2
    for c in t: d.text((x,y),c,font=f,fill=fill);x+=d.textlength(c,font=f)+tr
def fitfont(d,text,path,start,maxw,floor=44):
    s=start
    while s>floor and d.textlength(text,font=F(path,s))>maxw: s-=4
    return F(path,s)

# ── PROFILE PICTURES (1080) ──────────────────────────────────────────────────
def cover(img,zoom,out=1080):
    w,h=img.size;s=int(w*zoom);r=img.resize((s,s),Image.LANCZOS);l=(s-out)//2
    return r.crop((l,l,l+out,l+out))
ic=Image.open(APPICON).convert("RGBA");b=Image.new("RGBA",ic.size,CHAR+(255,));b.alpha_composite(ic);b=b.convert("RGB")
cover(b,1080/1024*1.10).save("ig_profile_full_kente.png")
cover(b,1080/1024*1.55).save("ig_profile_glyph.png")

# ── line icons ───────────────────────────────────────────────────────────────
def icon_camera(sz=700,color=GOLD):
    im=Image.new("RGBA",(sz,sz),(0,0,0,0));d=ImageDraw.Draw(im);w=34;c=color+(255,)
    d.rounded_rectangle([120,240,580,520],radius=40,outline=c,width=w)
    d.rounded_rectangle([250,190,410,250],radius=20,outline=c,width=w)
    d.ellipse([280,300,420,440],outline=c,width=w);d.ellipse([500,285,536,321],fill=c);return im
def icon_speech(sz=700,color=GOLD):
    im=Image.new("RGBA",(sz,sz),(0,0,0,0));d=ImageDraw.Draw(im);w=34;c=color+(255,)
    d.rounded_rectangle([140,180,560,440],radius=60,outline=c,width=w)
    d.polygon([(250,430),(250,540),(340,435)],fill=c)
    for cx in (270,350,430): d.ellipse([cx-16,296,cx+16,328],fill=c)
    return im
def icon_star(sz=700,color=GOLD):
    im=Image.new("RGBA",(sz,sz),(0,0,0,0));d=ImageDraw.Draw(im);c=color+(255,);cx=cy=350;R=180;r=74;pts=[]
    for i in range(10):
        ang=-math.pi/2+i*math.pi/5;rad=R if i%2==0 else r;pts.append((cx+rad*math.cos(ang),cy+rad*math.sin(ang)))
    d.polygon(pts,fill=c);return im

# ── HIGHLIGHT COVERS ─────────────────────────────────────────────────────────
def highlight(name,maker):
    S=1080;im=Image.new("RGBA",(S,S),CHAR+(255,));d=ImageDraw.Draw(im)
    d.ellipse([70,70,S-70,S-70],outline=GOLD+(90,),width=6);fit(im,maker(),S/2,S/2,430)
    os.makedirs("highlights",exist_ok=True);im.convert("RGB").save(f"highlights/{name}.png");return f"highlights/{name}.png"
hl=[highlight("1_start",lambda:brand_glyph(GOLD)),
    highlight("2_words",lambda:icon_speech()),
    highlight("3_adinkra",lambda:recolor(f"{G}/gyenyame.png",GOLD)),
    highlight("4_culture",lambda:recolor(f"{G}/nkyinkyim.png",GOLD)),
    highlight("5_lens",lambda:icon_camera()),
    highlight("6_beta",lambda:icon_star())]
labels=["Start","Words","Adinkra","Culture","Lens","Beta"]
prev=Image.new("RGBA",(1080,300),(255,255,255,255));pd=ImageDraw.Draw(prev)
for i,(p,lab) in enumerate(zip(hl,labels)):
    c=Image.open(p).convert("RGBA").resize((150,150),Image.LANCZOS)
    m=Image.new("L",(150,150),0);ImageDraw.Draw(m).ellipse((0,0,149,149),fill=255);c.putalpha(m)
    x=30+i*172;prev.alpha_composite(c,(x,50));center(pd,x+75,215,lab,F(LATO,26),(60,60,62))
prev.convert("RGB").save("highlights_preview.png")

# ── REEL KIT (1080x1920) ─────────────────────────────────────────────────────
W,H=1080,1920;os.makedirs("reel",exist_ok=True)
def base(bg=CHAR):
    im=Image.new("RGBA",(W,H),bg+(255,));d=ImageDraw.Draw(im);kente_bar(d,0,0,W,18);kente_bar(d,0,H-18,W,18);return im,d
cx=W/2
im,d=base(CHAR)
tracked(d,cx,300,"SANKOFA LENS",F(LATO_B,40),GOLD,10)
for i,line in enumerate(["POINT.","LEARN.","SPEAK."]): center(d,cx,420+i*150,line,F(POP_B,150),CREAM)
fit(im,icon_camera(color=GOLD),cx,1080,360)
center(d,cx,1320,"Point your camera at anything.",F(LATO_L,46),CREAM)
center(d,cx,1385,"Learn its name in Twi. Instantly.",F(LATO_L,46),CREAM)
fit(im,brand_glyph(GOLD),cx-190,1620,70);d.text((cx-120,1592),"Sankofa Twi",font=F(POP_B,44),fill=CREAM)
im.convert("RGB").save("reel/1_cover.png")
def label_card(twi,eng,fname):
    card=Image.new("RGBA",(W,H),(0,0,0,0));d=ImageDraw.Draw(card);y0=1360
    d.rounded_rectangle([90,y0,W-90,y0+300],radius=44,fill=CHAR+(235,))
    d.rounded_rectangle([90,y0,124,y0+300],radius=0,fill=GOLD+(255,))
    tracked(d,W/2+16,y0+44,"SANKOFA LENS",F(LATO_B,26),GOLD,6)
    center(d,W/2+16,y0+92,twi,F(LATO_BLK,96),CREAM);center(d,W/2+16,y0+210,eng,F(LATO,44),(210,205,192))
    sx,sy=150,y0+120
    d.polygon([(sx,sy+20),(sx+26,sy+20),(sx+50,sy),(sx+50,sy+70),(sx+26,sy+50),(sx,sy+50)],fill=GOLD)
    for r in (18,34): d.arc([sx+52,sy+5,sx+52+r*2,sy+5+40+r],300,60,fill=GOLD,width=6)
    card.save(f"reel/{fname}.png")
label_card("Aduane","Food","2_label_food");label_card("Nsuo","Water","3_label_water");label_card("Ɛpono","Table / Door","4_label_epono")
im,d=base(CHAR);fit(im,brand_glyph(GOLD),cx,560,320)
center(d,cx,820,"Learn Twi.",fitfont(d,"Learn Twi.",POP_B,120,W-160),CREAM)
center(d,cx,955,"Reclaim your roots.",fitfont(d,"Reclaim your roots.",POP_B,120,W-160),CREAM)
lab="JOIN THE BETA  ·  sankofaapp.io";f=F(LATO_B,42);tw=d.textlength(lab,font=f)
d.rounded_rectangle([cx-tw/2-56,1180,cx+tw/2+56,1290],radius=54,fill=TERRA);center(d,cx,1210,lab,f,(255,255,255))
center(d,cx,1380,"Free · Android",F(LATO_L,46),CREAM);im.convert("RGB").save("reel/5_endcard.png")

# ── CAMPAIGN REELS ───────────────────────────────────────────────────────────
os.makedirs("campaign",exist_ok=True)
def cta_pill(d,cx,y,label,f):
    tw=d.textlength(label,font=f);d.rounded_rectangle([cx-tw/2-56,y,cx+tw/2+56,y+110],radius=54,fill=TERRA);center(d,cx,y+30,label,f,(255,255,255))
# World Cup cover
im,d=base(CHAR)
for i,col in enumerate([RED,GOLD,GREEN]): d.rectangle([0,150+i*22,W,172+i*22],fill=col)
tracked(d,cx,280,"MATCH DAY · GHANA vs COLOMBIA",F(LATO_B,32),GOLD,4)
for i,ln in enumerate(["Can you talk","noise in Twi?"]): center(d,cx,470+i*160,ln,F(POP_B,132),CREAM)
center(d,cx,860,"Learn match-day Twi before kickoff.",F(LATO_L,46),CREAM)
fit(im,recolor(f"{G}/gyenyame.png",GOLD),cx,1200,300)
center(d,cx,1420,"Don't just watch Ghana.",F(LATO,46),CREAM);center(d,cx,1478,"Talk like Ghana.",F(LATO_B,50),GOLD)
fit(im,brand_glyph(GOLD),cx-190,1650,70);d.text((cx-120,1622),"Sankofa Twi",font=F(POP_B,44),fill=CREAM)
im.convert("RGB").save("campaign/worldcup_cover.png")
# World Cup endcard
im,d=base(CHAR)
for i,col in enumerate([RED,GOLD,GREEN]): d.rectangle([0,150+i*20,W,170+i*20],fill=col)
tracked(d,cx,520,"SAY IT ON MATCH DAY",F(LATO_B,34),GOLD,6)
center(d,cx,600,"Yɛbɛdi nkonim!",fitfont(d,"Yɛbɛdi nkonim!",LATO_BLK,150,W-140),CREAM)
center(d,cx,800,"“We will win.”",F(LATO_L,52),GOLD)
cta_pill(d,cx,1150,"JOIN THE BETA  ·  sankofaapp.io",F(LATO_B,42))
center(d,cx,1330,"Learn match-day Twi free · Android",F(LATO_L,42),CREAM)
im.convert("RGB").save("campaign/worldcup_endcard.png")
# Detty December cover
im,d=base(CHAR);d.rectangle([0,150,W,158],fill=TERRACOTTA)
tracked(d,cx,250,"DETTY DECEMBER · ACCRA",F(LATO_B,34),GOLD,6)
for i,ln in enumerate(["Traveling to","Ghana?"]): center(d,cx,430+i*160,ln,F(POP_B,140),CREAM)
center(d,cx,800,"Learn Twi before you land.",F(LATO_L,50),CREAM)
fit(im,recolor(f"{G}/nkyinkyim.png",GOLD),cx,1150,300)
center(d,cx,1370,"Stop paying obroni price.",F(LATO,46),CREAM);center(d,cx,1430,"Land speaking.",F(LATO_B,54),GOLD)
fit(im,brand_glyph(GOLD),cx-190,1650,70);d.text((cx-120,1622),"Sankofa Twi",font=F(POP_B,44),fill=CREAM)
im.convert("RGB").save("campaign/detty_cover.png")
# Detty December endcard
im,d=base(CHAR);fit(im,brand_glyph(GOLD),cx,520,300)
center(d,cx,760,"Land speaking.",fitfont(d,"Land speaking.",POP_B,120,W-140),CREAM)
center(d,cx,910,"Detty December hits different",F(LATO_L,46),CREAM)
center(d,cx,968,"when you can actually talk.",F(LATO_L,46),CREAM)
cta_pill(d,cx,1150,"JOIN THE BETA  ·  sankofaapp.io",F(LATO_B,42))
center(d,cx,1330,"Free travel Twi · Android",F(LATO_L,42),CREAM)
im.convert("RGB").save("campaign/detty_endcard.png")

# ── DETTY DECEMBER "OBRONI PRICE" REEL — storyboard + ready frames ────────────
os.makedirs("campaign/obroni",exist_ok=True)
# Hook cover
im,d=base(CHAR)
d.rectangle([0,150,W,158],fill=TERRACOTTA)
tracked(d,cx,250,"DETTY DECEMBER · ACCRA",F(LATO_B,32),GOLD,6)
for i,ln in enumerate(["The fastest way to","stop paying","obroni price"]):
    center(d,cx,430+i*150,ln,fitfont(d,ln,POP_B,118,W-120),CREAM)
center(d,cx,930,"Two phrases. Real Accra market energy.",F(LATO_L,44),CREAM)
fit(im,recolor(f"{G}/nkyinkyim.png",GOLD),cx,1230,280)
fit(im,brand_glyph(GOLD),cx-190,1600,70);d.text((cx-120,1572),"Sankofa Twi",font=F(POP_B,44),fill=CREAM)
im.convert("RGB").save("campaign/obroni/1_hook.png")
# Reusable market label overlays (transparent) — twi + english
def obroni_label(twi,eng,fname):
    card=Image.new("RGBA",(W,H),(0,0,0,0));d=ImageDraw.Draw(card);y0=1330
    d.rounded_rectangle([90,y0,W-90,y0+320],radius=44,fill=CHAR+(235,))
    d.rounded_rectangle([90,y0,124,y0+320],radius=0,fill=TERRACOTTA+(255,))
    tracked(d,W/2+16,y0+40,"SAY THIS IN THE MARKET",F(LATO_B,24),GOLD,4)
    center(d,W/2+16,y0+92,twi,fitfont(d,twi,LATO_BLK,92,W-260),CREAM)
    center(d,W/2+16,y0+230,eng,F(LATO,42),(210,205,192))
    card.save(f"campaign/obroni/{fname}.png")
obroni_label("Ɛyɛ sɛn?","How much is it?","2_label_price")
obroni_label("Te so kakra.","Reduce it a little.","3_label_reduce")
obroni_label("Medaase!","Thank you!","4_label_thanks")
# End card (Detty)
im,d=base(CHAR);fit(im,brand_glyph(GOLD),cx,520,300)
center(d,cx,760,"Land speaking.",fitfont(d,"Land speaking.",POP_B,120,W-140),CREAM)
center(d,cx,910,"Detty December hits different",F(LATO_L,46),CREAM)
center(d,cx,968,"when you can actually talk.",F(LATO_L,46),CREAM)
cta_pill(d,cx,1150,"JOIN THE BETA  ·  sankofaapp.io",F(LATO_B,42))
center(d,cx,1330,"Free travel Twi · Android",F(LATO_L,42),CREAM)
im.convert("RGB").save("campaign/obroni/5_endcard.png")
# Storyboard sheet (shots + notes)
shots=[("1_hook","0–2s  HOOK","Text on screen. Quick market b-roll."),
       ("2_label_price","2–6s  ASK","You ask in English → vendor quotes HIGH."),
       ("3_label_reduce","6–10s REWIND","Same ask in Twi → vendor smiles, quotes LOWER."),
       ("4_label_thanks","10–13s WIN","Banter + laugh. Overlay pops."),
       ("5_endcard","13–15s CTA","Hold end card ≥2s.")]
SB=Image.new("RGB",(1180,720),(255,255,255));sd=ImageDraw.Draw(SB)
sd.text((30,24),"OBRONI PRICE — Reel storyboard (≈15s, 9:16)",font=F(POP_B,34),fill=(43,43,45))
for i,(fn,t,note) in enumerate(shots):
    src=f"campaign/obroni/{fn}.png";th=Image.open(src).convert("RGBA")
    if "label" in fn:
        bgi=Image.new("RGBA",(W,H),(96,102,90,255));bgi.alpha_composite(th);th=bgi
    th=th.resize((196,348));x=30+i*228;SB.paste(th,(x,90))
    sd.text((x,450),t,font=F(LATO_B,24),fill=(190,82,53))
    for j,ln in enumerate(__import__("textwrap").wrap(note,26)): sd.text((x,486+j*26),ln,font=F(LATO,22),fill=(90,94,99))
SB.save("obroni_storyboard.png");print("obroni: hook + 3 overlays + endcard + storyboard")

cp=Image.new("RGBA",(760,1360),(241,242,244,255))
for i,fn in enumerate(["worldcup_cover","worldcup_endcard","detty_cover","detty_endcard"]):
    th=Image.open(f"campaign/{fn}.png").convert("RGBA").resize((338,600));r,c=divmod(i,2);cp.alpha_composite(th,(30+c*360,40+r*660))
cp.convert("RGB").save("campaign_preview.png")
print("Rebuilt: 2 profiles,",len(hl),"highlights, reel kit, 4 campaign frames.")
