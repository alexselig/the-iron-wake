#!/usr/bin/env python3
"""Forged-metal control buttons in the style of the reference UI plates:
thick beveled metal frame + riveted corner brackets + weathered copper face
with a diagonal sheen.

  normal  -> steel frame  + copper face        (assets_new/ui/verb_normal.png)
  selected-> brass frame  + brighter copper face(assets_new/ui/verb_selected.png)

Rendered 2x then downsampled to 190x46 (keeps the existing 14/14/12/15 9-slice
margins used by verb_panel.gd).
"""
import os, math, random
from PIL import Image, ImageDraw, ImageChops, ImageFilter

OUT = os.path.expanduser("~/SteampunkBeachDemo/assets_new/ui")
os.makedirs(OUT, exist_ok=True)

SS = 2
W, H = 190 * SS, 46 * SS

STEEL = dict(lt=(206, 211, 218), md=(140, 147, 156), dk=(78, 84, 92), deep=(44, 48, 54))
BRASS = dict(lt=(240, 212, 138), md=(192, 154, 74), dk=(120, 90, 40), deep=(72, 54, 24))
COPPER = dict(lt=(150, 96, 70), md=(120, 73, 52), dk=(92, 56, 41), deep=(68, 41, 30))
COPPER_HOT = dict(lt=(178, 116, 84), md=(140, 86, 60), dk=(104, 64, 46), deep=(78, 47, 33))


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def rrect_mask(w, h, r):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w - 1, h - 1], radius=r, fill=255)
    return m


def grad_v(w, h, c0, c1):
    g = Image.new("RGB", (w, h)); px = g.load()
    for y in range(h):
        c = lerp(c0, c1, y / max(1, h - 1))
        for x in range(w):
            px[x, y] = c
    return g


def emboss(shape_mask, depth, light=(255, 255, 255, 150), dark=(0, 0, 0, 160)):
    w, h = shape_mask.size
    ov = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    hl = ImageChops.subtract(shape_mask, ImageChops.offset(shape_mask, depth, depth))
    sh = ImageChops.subtract(shape_mask, ImageChops.offset(shape_mask, -depth, -depth))
    ov = Image.composite(Image.new("RGBA", (w, h), light), ov, hl)
    ov = Image.composite(Image.new("RGBA", (w, h), dark), ov, sh)
    return ov


def brushed(img, mask, amt):
    px = img.load(); mpx = mask.load(); w, h = img.size
    for y in range(h):
        streak = random.randint(-amt, amt)
        for x in range(w):
            if mpx[x, y] > 0:
                r, g, b, a = px[x, y]
                n = streak + random.randint(-amt // 2, amt // 2)
                px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)), a)


def sheen(w, h):
    """diagonal bright band, brighter toward upper-left."""
    ov = Image.new("RGBA", (w, h), (0, 0, 0, 0)); px = ov.load()
    for y in range(h):
        for x in range(w):
            d = (x / w) * 0.6 + (y / h) * 0.4
            a = max(0, 1 - abs(d - 0.32) * 3.2)
            px[x, y] = (255, 244, 222, int(70 * a))
    return ov.filter(ImageFilter.GaussianBlur(SS * 2))


def rivet(d, cx, cy, r, metal):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=metal["deep"])
    d.ellipse([cx - r + 1, cy - r + 1, cx + r - 1, cy + r - 1], fill=lerp(metal["dk"], metal["md"], 0.5))
    d.ellipse([cx - r + 1, cy - r + 1, cx, cy], fill=metal["lt"])


def corner_bracket(im, x, y, s, metal, flip_x=False, flip_y=False):
    """small beveled metal corner cap centered at (x,y), size s."""
    w, h = im.size
    br = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    bm = rrect_mask(s, s, s // 3)
    face = grad_v(s, s, metal["lt"], metal["dk"]).convert("RGBA")
    br.paste(face, (0, 0), bm)
    br.alpha_composite(emboss(bm, max(1, SS), (255, 255, 255, 170), (0, 0, 0, 150)))
    d = ImageDraw.Draw(br)
    rivet(d, s // 2, s // 2, max(2, s // 6), metal)
    im.alpha_composite(br, (int(x - s / 2), int(y - s / 2)))


def make_button(selected):
    metal = BRASS if selected else STEEL
    face_c = COPPER_HOT if selected else COPPER
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pad = 2 * SS
    r = 13 * SS
    fw = 7 * SS  # frame thickness

    outer = Image.new("L", (W, H), 0)
    ImageDraw.Draw(outer).rounded_rectangle([pad, pad, W - 1 - pad, H - 1 - pad], radius=r, fill=255)
    inner = Image.new("L", (W, H), 0)
    ImageDraw.Draw(inner).rounded_rectangle(
        [pad + fw, pad + fw, W - 1 - pad - fw, H - 1 - pad - fw], radius=max(3, r - fw), fill=255)
    frame_mask = ImageChops.subtract(outer, inner)

    # frame metal
    fmetal = grad_v(W, H, metal["lt"], metal["deep"]).convert("RGBA")
    im.paste(fmetal, (0, 0), frame_mask)
    brushed(im, frame_mask, 4)
    im.alpha_composite(emboss(outer, max(1, SS + 1), (255, 255, 255, 185), (0, 0, 0, 165)))
    im.alpha_composite(emboss(inner, max(1, SS), (0, 0, 0, 165), (255, 255, 255, 80)))  # inner groove

    # copper face
    fimg = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cf = grad_v(W, H, face_c["lt"], face_c["dk"]).convert("RGBA")
    fimg.paste(cf, (0, 0), inner)
    brushed(fimg, inner, 3)
    fimg = Image.composite(fimg, Image.new("RGBA", (W, H), (0, 0, 0, 0)), inner)
    fimg.alpha_composite(Image.composite(sheen(W, H), Image.new("RGBA", (W, H), (0, 0, 0, 0)), inner))
    im.alpha_composite(fimg)

    d = ImageDraw.Draw(im)
    # corner brackets only (no scattered rivets)
    bs = 12 * SS
    corner_bracket(im, pad + 6 * SS, pad + 6 * SS, bs, metal)
    corner_bracket(im, W - pad - 6 * SS, pad + 6 * SS, bs, metal)
    corner_bracket(im, pad + 6 * SS, H - pad - 6 * SS, bs, metal)
    corner_bracket(im, W - pad - 6 * SS, H - pad - 6 * SS, bs, metal)

    im = im.resize((190, 46), Image.LANCZOS)
    im.save(os.path.join(OUT, "verb_selected.png" if selected else "verb_normal.png"))


make_button(False)
make_button(True)
print("wrote verb_normal.png, verb_selected.png to", OUT)
