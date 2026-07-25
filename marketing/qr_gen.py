#!/usr/bin/env python3
"""Minimal, self-contained QR encoder (byte mode, EC level M, versions 1-10).
Faithful port of the standard algorithm (Nayuki reference). No dependencies
beyond Pillow for rendering."""
from PIL import Image, ImageDraw, ImageFont, ImageChops

# ── Per-version tables (EC level M), versions 1..10 ──────────────────────────
TOTAL_CODEWORDS = {1:26,2:44,3:70,4:100,5:134,6:172,7:196,8:242,9:292,10:346}
NUM_BLOCKS_M    = {1:1,2:1,3:1,4:2,5:2,6:4,7:4,8:4,9:5,10:5}
ECC_PER_BLOCK_M = {1:10,2:16,3:26,4:18,5:24,6:16,7:18,8:22,9:22,10:26}
ALIGN_POS = {1:[],2:[6,18],3:[6,22],4:[6,26],5:[6,30],6:[6,34],
             7:[6,22,38],8:[6,24,42],9:[6,26,46],10:[6,28,50]}

def gf_mul(x,y):
    z=0
    for i in range(7,-1,-1):
        z=((z<<1) ^ ((z>>7)*0x11d)) & 0x1ff
        z ^= ((y>>i)&1)*x
    return z & 0xff

def rs_divisor(degree):
    result=[0]*(degree-1)+[1]
    root=1
    for _ in range(degree):
        for j in range(degree):
            result[j]=gf_mul(result[j],root)
            if j+1<degree: result[j]^=result[j+1]
        root=gf_mul(root,0x02)
    return result

def rs_remainder(data,divisor):
    result=[0]*len(divisor)
    for b in data:
        factor=b ^ result.pop(0); result.append(0)
        for i in range(len(result)):
            result[i]^=gf_mul(divisor[i],factor)
    return result

def append_bits(bits,val,n):
    for i in range(n-1,-1,-1): bits.append((val>>i)&1)

def choose_version(nbytes):
    for v in range(1,11):
        cap=(TOTAL_CODEWORDS[v]-NUM_BLOCKS_M[v]*ECC_PER_BLOCK_M[v])*8
        need=4+(8 if v<=9 else 16)+8*nbytes
        if cap>=need: return v
    raise ValueError("data too long for v1-10")

def encode_data(url):
    data=url.encode("utf-8"); v=choose_version(len(data))
    cap_cw=TOTAL_CODEWORDS[v]-NUM_BLOCKS_M[v]*ECC_PER_BLOCK_M[v]
    cap_bits=cap_cw*8
    bits=[]; append_bits(bits,0b0100,4)
    append_bits(bits,len(data),8 if v<=9 else 16)
    for b in data: append_bits(bits,b,8)
    append_bits(bits,0,min(4,cap_bits-len(bits)))
    while len(bits)%8: bits.append(0)
    pad=[0xEC,0x11]; i=0
    while len(bits)<cap_bits: append_bits(bits,pad[i%2],8); i+=1
    cw=[int("".join(map(str,bits[j:j+8])),2) for j in range(0,len(bits),8)]
    return v,cw

def interleave(cw,v):
    nb=NUM_BLOCKS_M[v]; ecclen=ECC_PER_BLOCK_M[v]; raw=TOTAL_CODEWORDS[v]
    numshort=nb-raw%nb; shortlen=raw//nb; div=rs_divisor(ecclen); blocks=[]; k=0
    shortdata=shortlen-ecclen
    for i in range(nb):
        dlen=shortdata+(0 if i<numshort else 1)
        dat=list(cw[k:k+dlen]); k+=dlen
        ecc=rs_remainder(dat,div)
        blk=list(dat)
        if i<numshort: blk.append(0)   # placeholder for equal-length interleave
        blk+=ecc; blocks.append(blk)
    out=[]
    L=len(blocks[0])
    for i in range(L):
        for j in range(nb):
            if not (i==shortdata and j<numshort):
                out.append(blocks[j][i])
    return out

class QR:
    def __init__(self,v):
        self.v=v; self.size=17+4*v
        self.mod=[[False]*self.size for _ in range(self.size)]
        self.fn=[[False]*self.size for _ in range(self.size)]
    def set(self,x,y,dark):
        self.mod[y][x]=dark; self.fn[y][x]=True
    def finder(self,x,y):
        for dy in range(-4,5):
            for dx in range(-4,5):
                xx,yy=x+dx,y+dy
                if 0<=xx<self.size and 0<=yy<self.size:
                    d=max(abs(dx),abs(dy)); self.set(xx,yy,d!=2 and d!=4)
    def align(self,x,y):
        for dy in range(-2,3):
            for dx in range(-2,3):
                self.set(x+dx,y+dy,max(abs(dx),abs(dy))!=1)
    def draw_function(self):
        for i in range(self.size):
            self.set(6,i,i%2==0); self.set(i,6,i%2==0)
        self.finder(3,3); self.finder(self.size-4,3); self.finder(3,self.size-4)
        pos=ALIGN_POS[self.v]; n=len(pos)
        for i in range(n):
            for j in range(n):
                if (i==0 and j==0) or (i==0 and j==n-1) or (i==n-1 and j==0): continue
                self.align(pos[i],pos[j])
        self.draw_format(0)   # reserve
    def draw_format(self,mask):
        data=mask  # EC level M formatbits=0 -> (0<<3)|mask
        rem=data
        for _ in range(10): rem=(rem<<1)^((rem>>9)*0x537)
        bits=((data<<10)|rem)^0x5412
        gb=lambda i:(bits>>i)&1
        for i in range(6): self.set(8,i,gb(i))
        self.set(8,7,gb(6)); self.set(8,8,gb(7)); self.set(7,8,gb(8))
        for i in range(9,15): self.set(14-i,8,gb(i))
        s=self.size
        for i in range(8): self.set(s-1-i,8,gb(i))
        for i in range(8,15): self.set(8,s-15+i,gb(i))
        self.set(s-8,8,True)   # always dark
    def draw_codewords(self,data):
        i=0; s=self.size; col=s-1
        while col>0:
            if col==6: col-=1
            for vert in range(s):
                for j in range(2):
                    x=col-j; upward=((col+1)&2)==0
                    y=(s-1-vert) if upward else vert
                    if not self.fn[y][x] and i<len(data)*8:
                        self.mod[y][x]=((data[i>>3]>>(7-(i&7)))&1)!=0; i+=1
            col-=2
    def mask_fn(self,m,x,y):
        return [ (x+y)%2==0, y%2==0, x%3==0, (x+y)%3==0,
                 (x//3+y//2)%2==0, (x*y)%2+(x*y)%3==0,
                 ((x*y)%2+(x*y)%3)%2==0, ((x+y)%2+(x*y)%3)%2==0 ][m]
    def apply_mask(self,m):
        for y in range(self.size):
            for x in range(self.size):
                if (not self.fn[y][x]) and self.mask_fn(m,x,y):
                    self.mod[y][x]=not self.mod[y][x]
    def penalty(self):
        s=self.size; sc=0; mod=self.mod
        for y in range(s):
            run=1; last=mod[y][0]
            for x in range(1,s):
                if mod[y][x]==last: run+=1
                else:
                    if run>=5: sc+=3+(run-5)
                    run=1; last=mod[y][x]
            if run>=5: sc+=3+(run-5)
        for x in range(s):
            run=1; last=mod[0][x]
            for y in range(1,s):
                if mod[y][x]==last: run+=1
                else:
                    if run>=5: sc+=3+(run-5)
                    run=1; last=mod[y][x]
            if run>=5: sc+=3+(run-5)
        for y in range(s-1):
            for x in range(s-1):
                if mod[y][x]==mod[y][x+1]==mod[y+1][x]==mod[y+1][x+1]: sc+=3
        patt=[True,False,True,True,True,False,True]
        def check(line):
            c=0
            for i in range(len(line)-6):
                if line[i:i+7]==patt:
                    before=line[max(0,i-4):i]; after=line[i+7:i+11]
                    if all(not b for b in before) or all(not b for b in after): c+=1
            return c
        for y in range(s): sc+=40*check(mod[y])
        for x in range(s): sc+=40*check([mod[y][x] for y in range(s)])
        dark=sum(row.count(True) for row in mod); total=s*s
        k=abs(dark*20-total*10)//total; sc+=10*k
        return sc

def make_matrix(url):
    v,cw=encode_data(url); data=interleave(cw,v)
    best=None; bestscore=None
    for m in range(8):
        q=QR(v); q.draw_function(); q.draw_codewords(data)
        q.apply_mask(m); q.draw_format(m)
        sc=q.penalty()
        if bestscore is None or sc<bestscore: bestscore=sc; best=q
    return [[1 if c else 0 for c in row] for row in best.mod]

def to_image(matrix,scale=20,quiet=4,dark=(43,43,45),light=(255,255,255)):
    n=len(matrix); size=(n+2*quiet)*scale
    img=Image.new("RGB",(size,size),light)
    d=ImageDraw.Draw(img)
    for y in range(n):
        for x in range(n):
            if matrix[y][x]:
                X=(x+quiet)*scale; Y=(y+quiet)*scale
                d.rectangle([X,Y,X+scale-1,Y+scale-1],fill=dark)
    return img

if __name__=="__main__":
    import sys
    url="https://appdistribution.firebase.dev/i/9586b57458a2b3d2"
    mat=make_matrix(url)
    print("version size:",len(mat))
    # ASCII sanity print
    for row in mat:
        print("".join("##" if c else "  " for c in row))
    to_image(mat,scale=16).save("qr_plain.png")
    print("saved qr_plain.png")
