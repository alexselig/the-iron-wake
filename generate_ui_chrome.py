#!/usr/bin/env python3
"""Generate a cohesive, professional steampunk control-bar UI set.

Outputs (into assets_new/ui/ so they apply only in the NEW version):
  panel_bg.png        640x108  bar background: dark wood + brass top molding + rivets
  verb_normal.png     190x46   riveted brass plaque (9-slice 14/14/12/15)
  verb_selected.png   190x46   lit brass plaque
  slot_normal.png     64x64    recessed brass-rimmed inventory socket (9-slice 6)
  slot_selected.png   64x64    lit brass-rimmed socket
  hover_plate.png     200x24   subtle brass nameplate behind the hover text
"""
import os, math, random
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.expanduser("~/SteampunkBeachDemo/assets_new/ui")
os.makedirs(OUT, exist_ok=True)
random.seed(7)

# --- palette ---
WOOD_T = (46, 32, 17); WOOD_B = (20, 14, 8)
BRASS_HI = (226, 190, 110); BRASS = (170, 128, 58); BRASS_DK = (84, 62, 30)
GOLD = (243, 205, 130); AMBER = (255, 214, 150)
INK = (16, 11, 6)

def lerp(a, b, t): return tuple(int(a[i] + (b[i]-a[i])*t) for i in range(3))

def vgrad(w, h, c0, c1):
    im = Image.new("RGB", (w, h))
    px = im.load()
    for y in range(h):
        c = lerp(c0, c1, y/max(1, h-1))
        for x in range(w):
            px[x, y] = c
    return im

def rounded_mask(w, h, r):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w-1, h-1], radius=r, fill=255)
    return m

def rivet(draw, cx, cy, r=3):
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=BRASS_DK)
    draw.ellipse([cx-r+1, cy-r+1, cx+r-1, cy+r-1], fill=BRASS)
    draw.ellipse([cx-r+1, cy-r+1, cx, cy], fill=BRASS_HI)

# ---------------------------------------------------------------- panel_bg
def make_panel_bg():
    w, h = 640, 108
    im = vgrad(w, h, WOOD_T, WOOD_B).convert("RGBA")
    px = im.load()
    # subtle brushed horizontal grain
    for y in range(8, h):
        n = random.randint(-6, 6)
        for x in range(w):
            r, g, b, a = px[x, y]
            px[x, y] = (max(0, min(255, r+n)), max(0, min(255, g+n)), max(0, min(255, b+n)), a)
    d = ImageDraw.Draw(im)
    # brass top molding
    mold = 8
    for y in range(mold):
        t = y/(mold-1)
        c = lerp(BRASS_DK, BRASS_HI, 1-abs(t-0.35)*1.6) if t < 0.6 else lerp(BRASS, BRASS_DK, (t-0.6)/0.4)
        d.line([(0, y), (w, y)], fill=c)
    d.line([(0, 1), (w, 1)], fill=BRASS_HI)            # bright highlight
    d.line([(0, mold), (w, mold)], fill=INK)           # crisp shadow under molding
    # inner top shadow fade
    sh = Image.new("RGBA", (w, 24), (0, 0, 0, 0))
    sd = sh.load()
    for y in range(24):
        a = int(120 * (1 - y/23))
        for x in range(w):
            sd[x, y] = (0, 0, 0, a)
    im.alpha_composite(sh, (0, mold))
    # rivets along molding
    for x in range(20, w, 48):
        rivet(d, x, 4, 3)
    # side vignette
    vig = Image.new("RGBA", (w, h), (0, 0, 0, 0)); vd = vig.load()
    for x in range(w):
        edge = min(x, w-1-x)
        a = int(90 * max(0, 1 - edge/70)) if edge < 70 else 0
        for y in range(mold, h):
            vd[x, y] = (0, 0, 0, a)
    im.alpha_composite(vig)
    im.save(os.path.join(OUT, "panel_bg.png"))

# ---------------------------------------------------------------- verb plaque
def make_verb(selected):
    w, h, r = 190, 46, 9
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    if selected:
        face = vgrad(w, h, (74, 52, 24), (52, 36, 16))
    else:
        face = vgrad(w, h, (52, 37, 19), (34, 24, 12))
    face = face.convert("RGBA")
    mask = rounded_mask(w, h, r)
    im.paste(face, (0, 0), mask)
    d = ImageDraw.Draw(im)
    # outer + inner bevel
    bcol = GOLD if selected else BRASS
    d.rounded_rectangle([0, 0, w-1, h-1], radius=r, outline=BRASS_DK, width=2)
    d.rounded_rectangle([2, 2, w-3, h-3], radius=r-2, outline=bcol, width=1)
    # top inner highlight, bottom inner shadow
    hl = Image.new("RGBA", (w, h), (0, 0, 0, 0)); hd = ImageDraw.Draw(hl)
    hd.line([(6, 3), (w-7, 3)], fill=(255, 240, 200, 90))
    hd.line([(6, h-4), (w-7, h-4)], fill=(0, 0, 0, 110))
    im.alpha_composite(hl)
    if selected:
        # warm inner glow
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0)); gd = glow.load()
        cx, cy = w/2, h/2
        for y in range(h):
            for x in range(w):
                dd = math.hypot((x-cx)/(w*0.5), (y-cy)/(h*0.5))
                a = int(70 * max(0, 1-dd))
                if a: gd[x, y] = (255, 198, 120, a)
        glow = glow.filter(ImageFilter.GaussianBlur(2))
        im.alpha_composite(Image.composite(glow, Image.new("RGBA", (w, h), (0, 0, 0, 0)), mask))
    for (cx, cy) in [(11, 10), (w-11, 10), (11, h-10), (w-11, h-10)]:
        rivet(d, cx, cy, 3)
    name = "verb_selected.png" if selected else "verb_normal.png"
    im.save(os.path.join(OUT, name))

# ---------------------------------------------------------------- slot
def make_slot(selected):
    w, h, r = 64, 64, 8
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mask = rounded_mask(w, h, r)
    # recessed dark interior
    inner = vgrad(w, h, (12, 9, 5), (28, 20, 11)).convert("RGBA")
    im.paste(inner, (0, 0), mask)
    d = ImageDraw.Draw(im)
    # inset shadow (top/left darker)
    ins = Image.new("RGBA", (w, h), (0, 0, 0, 0)); idr = ImageDraw.Draw(ins)
    idr.line([(5, 5), (w-6, 5)], fill=(0, 0, 0, 150))
    idr.line([(5, 5), (5, h-6)], fill=(0, 0, 0, 150))
    idr.line([(6, h-6), (w-6, h-6)], fill=(90, 70, 40, 90))
    im.alpha_composite(Image.composite(ins, Image.new("RGBA", (w, h), (0, 0, 0, 0)), mask))
    # brass rim
    rim = GOLD if selected else BRASS
    d.rounded_rectangle([1, 1, w-2, h-2], radius=r, outline=BRASS_DK, width=3)
    d.rounded_rectangle([2, 2, w-3, h-3], radius=r-1, outline=rim, width=2)
    if selected:
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0)); gd = ImageDraw.Draw(glow)
        gd.rounded_rectangle([3, 3, w-4, h-4], radius=r-2, outline=(255, 210, 140, 130), width=2)
        glow = glow.filter(ImageFilter.GaussianBlur(2))
        im.alpha_composite(glow)
    for (cx, cy) in [(9, 9), (w-9, 9), (9, h-9), (w-9, h-9)]:
        rivet(d, cx, cy, 2)
    name = "slot_selected.png" if selected else "slot_normal.png"
    im.save(os.path.join(OUT, name))

# ---------------------------------------------------------------- hover plate
def make_hover_plate():
    w, h, r = 200, 24, 10
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    face = vgrad(w, h, (40, 28, 14), (24, 16, 8)).convert("RGBA")
    mask = rounded_mask(w, h, r)
    im.paste(face, (0, 0), mask)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, w-1, h-1], radius=r, outline=BRASS, width=1)
    im.putalpha(Image.composite(im.getchannel("A").point(lambda a: int(a*0.92)), Image.new("L",(w,h),0), mask))
    im.save(os.path.join(OUT, "hover_plate.png"))

make_panel_bg()
make_verb(False); make_verb(True)
make_slot(False); make_slot(True)
make_hover_plate()
print("UI chrome written to", OUT)
for f in sorted(os.listdir(OUT)):
    if f.endswith(".png"): print("  ", f)
