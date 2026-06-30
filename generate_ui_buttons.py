#!/usr/bin/env python3
"""Control-bar buttons + inventory slots baked from the real reference plate
(art_src/ref_button.png): a gold beveled frame with angular corner brackets and
a weathered rose-copper face.

We can't 1:1 stretch the tall ornate reference onto the flat 190x46 verb button,
so we re-render it with an image-space 9-slice: the gold corner brackets are kept
at a faithful (uniform) scale while only the copper face is stretched/compressed
to the target size. This preserves the exact look of the reference at any aspect.

Outputs (assets_new/ui/):
  verb_normal.png   190x46   gold frame + rose copper
  verb_selected.png 190x46   same, brightened ("lit" active verb)
  slot_normal.png    48x48   square slot, same frame
  slot_selected.png  48x48   brightened
"""
import os
from PIL import Image, ImageDraw, ImageEnhance, ImageChops
import numpy as np

ROOT = os.path.expanduser("~/SteampunkBeachDemo")
OUT = os.path.join(ROOT, "assets_new/ui")
REF = os.path.join(ROOT, "art_src/ref_button.png")
os.makedirs(OUT, exist_ok=True)
SS = 4  # supersample


def load_button():
    """Crop the plate from the reference and knock out the dark background."""
    ref = Image.open(REF).convert("RGB")
    crop = ref.crop((14, 20, 593, 247))
    w, h = crop.size
    ff = crop.copy()
    S = (255, 0, 255)
    seeds = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
             (w // 2, 0), (w // 2, h - 1), (2, h // 2), (w - 3, h // 2)]
    for s in seeds:
        ImageDraw.floodfill(ff, s, S, thresh=46)
    bg = np.all(np.asarray(ff) == S, axis=-1)
    rgba = np.dstack([np.asarray(crop), np.where(bg, 0, 255).astype(np.uint8)])
    return Image.fromarray(rgba)  # ~579x227 RGBA


BTN = load_button()


def nine_slice(target_w, target_h, wlr, wrr, htr, hbr):
    """Render BTN to target via 9-slice.

    Corner blocks are scaled uniformly (fit-to-height) so the gold brackets keep
    their true proportions; the edges/center stretch (or compress) to fill.
    wlr/wrr  = left/right corner-strip width as a fraction of natural width.
    htr/hbr  = top/bottom corner-strip height as a fraction of natural height.
    """
    tw, th = target_w * SS, target_h * SS
    # natural size: scale BTN so its HEIGHT equals th (keeps frame proportion)
    nh = th
    nw = round(BTN.width * (nh / BTN.height))
    nat = BTN.resize((nw, nh), Image.LANCZOS)

    wl, wr = round(nw * wlr), round(nw * wrr)
    ht, hb = round(nh * htr), round(nh * hbr)
    wl = min(wl, tw // 2 - 1); wr = min(wr, tw // 2 - 1)

    def piece(box):
        return nat.crop(box)

    mid_w = tw - wl - wr      # target middle width
    mid_h = th - ht - hb      # target middle height
    nmid_w = nw - wl - wr     # natural middle width
    nmid_h = nh - ht - hb

    out = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    # corners (kept)
    out.alpha_composite(piece((0, 0, wl, ht)), (0, 0))
    out.alpha_composite(piece((nw - wr, 0, nw, ht)), (tw - wr, 0))
    out.alpha_composite(piece((0, nh - hb, wl, nh)), (0, th - hb))
    out.alpha_composite(piece((nw - wr, nh - hb, nw, nh)), (tw - wr, th - hb))
    # edges (stretched along one axis)
    top = piece((wl, 0, nw - wr, ht)).resize((mid_w, ht), Image.LANCZOS)
    bot = piece((wl, nh - hb, nw - wr, nh)).resize((mid_w, hb), Image.LANCZOS)
    lft = piece((0, ht, wl, nh - hb)).resize((wl, mid_h), Image.LANCZOS)
    rgt = piece((nw - wr, ht, nw, nh - hb)).resize((wr, mid_h), Image.LANCZOS)
    out.alpha_composite(top, (wl, 0))
    out.alpha_composite(bot, (wl, th - hb))
    out.alpha_composite(lft, (0, ht))
    out.alpha_composite(rgt, (tw - wr, ht))
    # center
    ctr = piece((wl, ht, nw - wr, nh - hb)).resize((mid_w, mid_h), Image.LANCZOS)
    out.alpha_composite(ctr, (wl, ht))
    return out.resize((target_w, target_h), Image.LANCZOS)


def brighten(img, b=1.32, sat=1.28, con=1.06):
    r, g, bl, a = img.split()
    rgb = Image.merge("RGB", (r, g, bl))
    rgb = ImageEnhance.Brightness(rgb).enhance(b)
    rgb = ImageEnhance.Color(rgb).enhance(sat)
    rgb = ImageEnhance.Contrast(rgb).enhance(con)
    # warm "lit" overlay so the active plate reads as glowing brass.
    warm = Image.new("RGB", rgb.size, (255, 196, 96))
    rgb = Image.blend(rgb, ImageChops.screen(rgb, warm), 0.18)
    r, g, bl = rgb.split()
    return Image.merge("RGBA", (r, g, bl, a))


# Verb buttons: wide & flat -> stretch copper horizontally, brackets stay true.
verb = nine_slice(190, 46, wlr=0.165, wrr=0.165, htr=0.135, hbr=0.205)
verb.save(os.path.join(OUT, "verb_normal.png"))
brighten(verb).save(os.path.join(OUT, "verb_selected.png"))

# Inventory slots: square -> compress copper, keep frame brackets.
slot = nine_slice(48, 48, wlr=0.135, wrr=0.135, htr=0.135, hbr=0.205)
slot.save(os.path.join(OUT, "slot_normal.png"))
brighten(slot).save(os.path.join(OUT, "slot_selected.png"))

print("wrote verb_{normal,selected}.png (190x46), slot_{normal,selected}.png (48x48)")
