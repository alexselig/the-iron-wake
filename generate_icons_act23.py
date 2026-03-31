#!/usr/bin/env python3
"""Generate 64x64 inventory icons for Act 2-3 items."""

import os
import math
from PIL import Image, ImageDraw

OUTPUT_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/inventory_icons")
S = 64

BG = (32, 20, 10, 255)
BRASS = (200, 160, 70)
BRASS_HI = (240, 200, 100)
BRASS_DK = (140, 100, 45)
BRASS_EDGE = (100, 70, 30)
COPPER = (200, 120, 70)
BROWN = (120, 80, 45)
BROWN_DK = (70, 45, 25)
GREY = (160, 160, 165)
BLUE = (100, 170, 240)
BLUE_HI = (150, 210, 255)
BLUE_DK = (60, 110, 170)
WHITE = (240, 235, 220)
CREAM = (230, 215, 185)
GREEN = (100, 180, 120)
GREEN_HI = (140, 220, 160)
PURPLE = (140, 100, 180)
PURPLE_HI = (180, 140, 220)
TEAL = (80, 180, 180)
TEAL_HI = (120, 220, 220)
ORANGE = (220, 140, 60)
GLASS = (170, 200, 215)


def new():
    img = Image.new("RGBA", (S, S), BG)
    return img, ImageDraw.Draw(img)

def circ(d, cx, cy, r, fill, outline=None, w=1):
    d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=fill, outline=outline, width=w)

def rrect(d, x1, y1, x2, y2, r, fill, outline=None):
    d.rounded_rectangle([x1, y1, x2, y2], radius=r, fill=fill, outline=outline)

def save(img, name):
    img.save(os.path.join(OUTPUT_DIR, f"{name}.png"))


def icon_ceramic_bottles():
    img, d = new()
    # Two small bottles
    for xoff in [-10, 10]:
        cx = 32 + xoff
        # Bottle body
        rrect(d, cx-7, 24, cx+7, 52, 3, BROWN, BROWN_DK)
        # Neck
        rrect(d, cx-4, 14, cx+4, 26, 2, BROWN, BROWN_DK)
        # Cork
        rrect(d, cx-3, 10, cx+3, 16, 1, (180, 160, 120), (140, 120, 80))
        # Label
        rrect(d, cx-5, 32, cx+5, 42, 1, CREAM, BRASS_DK)
    save(img, "ceramic_bottles")


def icon_reflective_cinderglass():
    img, d = new()
    # Irregular glassy shard with warm glow
    pts = [(30, 6), (48, 18), (52, 38), (40, 54), (20, 52), (12, 34), (16, 16)]
    d.polygon(pts, fill=(60, 50, 45), outline=(90, 75, 55))
    # Reflective streaks
    d.line([(20, 20), (42, 36)], fill=ORANGE, width=2)
    d.line([(18, 34), (44, 24)], fill=(240, 180, 80), width=2)
    d.line([(24, 46), (40, 44)], fill=ORANGE, width=1)
    # Bright spots
    circ(d, 34, 28, 4, (255, 220, 120))
    circ(d, 28, 40, 3, (240, 180, 80))
    save(img, "reflective_cinderglass")


def icon_transit_sigil_fragment():
    img, d = new()
    # Broken stone/metal fragment
    pts = [(16, 10), (48, 8), (50, 44), (36, 54), (12, 48)]
    d.polygon(pts, fill=GREY, outline=(100, 100, 105))
    # Glowing sigil lines
    d.line([(22, 20), (42, 20)], fill=TEAL, width=2)
    d.line([(32, 14), (32, 44)], fill=TEAL, width=2)
    circ(d, 32, 30, 8, None, TEAL_HI, 2)
    # Glow dots at intersections
    circ(d, 32, 20, 3, TEAL_HI)
    circ(d, 32, 44, 2, TEAL)
    save(img, "transit_sigil_fragment")


def icon_tone_cylinder():
    img, d = new()
    # Brass cylinder
    rrect(d, 18, 10, 46, 54, 6, BRASS, BRASS_EDGE)
    # Highlight
    d.line([(24, 14), (24, 50)], fill=BRASS_HI, width=3)
    # Engraved rings
    for y in [18, 28, 38, 48]:
        d.line([(20, y), (44, y)], fill=BRASS_EDGE, width=1)
    # Sound holes
    circ(d, 36, 23, 3, BRASS_DK)
    circ(d, 36, 33, 3, BRASS_DK)
    circ(d, 36, 43, 3, BRASS_DK)
    save(img, "tone_cylinder")


def icon_second_relay_core():
    img, d = new()
    # Hexagonal core
    pts = [(32, 8), (50, 20), (50, 44), (32, 56), (14, 44), (14, 20)]
    d.polygon(pts, fill=BRASS_DK, outline=BRASS_EDGE)
    # Inner glow
    circ(d, 32, 32, 12, BLUE_DK, BRASS)
    circ(d, 32, 32, 7, BLUE)
    circ(d, 32, 32, 3, BLUE_HI)
    # Connection nodes
    for angle in [0, 60, 120, 180, 240, 300]:
        r = math.radians(angle)
        x = 32 + math.cos(r) * 18
        y = 32 + math.sin(r) * 18
        circ(d, int(x), int(y), 3, BRASS_HI, BRASS_EDGE)
    save(img, "second_relay_core")


def icon_aerial_transit_prism():
    img, d = new()
    # Triangular prism
    d.polygon([(32, 6), (54, 48), (10, 48)], fill=GLASS, outline=BRASS_EDGE)
    # Rainbow refraction
    colors = [(200, 80, 80), (220, 180, 60), (80, 200, 80), (80, 140, 220), (160, 80, 200)]
    for i, c in enumerate(colors):
        y = 50 + i
        d.line([(16, y), (48, y)], fill=c, width=1)
    # Light beam entering
    d.line([(8, 20), (28, 30)], fill=WHITE, width=2)
    # Bright spot
    circ(d, 30, 30, 4, (220, 240, 255))
    save(img, "aerial_transit_prism")


def icon_white_civic_signet_half():
    img, d = new()
    # Half-circle signet
    d.pieslice([8, 8, 56, 56], 180, 360, fill=WHITE, outline=BRASS)
    # Flat bottom edge
    d.line([(8, 32), (56, 32)], fill=BRASS, width=2)
    # Engraved pattern on face
    circ(d, 32, 24, 8, None, BRASS_DK, 2)
    d.line([(26, 18), (38, 18)], fill=BRASS_DK, width=1)
    d.line([(32, 14), (32, 28)], fill=BRASS_DK, width=1)
    # "Half" indicator - jagged break edge
    d.line([(10, 32), (14, 36), (20, 32), (26, 38), (32, 32), (38, 36), (44, 32), (50, 38), (54, 32)],
           fill=BRASS_EDGE, width=2)
    save(img, "white_civic_signet_half")


def icon_complete_civic_signet():
    img, d = new()
    # Full circle signet
    circ(d, 32, 32, 22, WHITE, BRASS, 2)
    # Engraved civic pattern
    circ(d, 32, 32, 14, None, BRASS_DK, 2)
    circ(d, 32, 32, 6, None, BRASS_DK, 2)
    d.line([(18, 32), (46, 32)], fill=BRASS_DK, width=2)
    d.line([(32, 18), (32, 46)], fill=BRASS_DK, width=2)
    # Glow
    circ(d, 32, 32, 4, BLUE_HI)
    # Gold edge detail
    for angle in range(0, 360, 30):
        r = math.radians(angle)
        x = 32 + math.cos(r) * 20
        y = 32 + math.sin(r) * 20
        circ(d, int(x), int(y), 2, BRASS_HI)
    save(img, "complete_civic_signet")


def icon_message_strip():
    img, d = new()
    # Thin brass message strip (like brass_strip but with text)
    rrect(d, 6, 20, 58, 44, 3, BRASS, BRASS_EDGE)
    d.line([(10, 24), (54, 24)], fill=BRASS_HI, width=1)
    # "Text" lines (small dashes)
    for y in [30, 36]:
        for x in range(12, 50, 5):
            d.line([(x, y), (x+3, y)], fill=BRASS_EDGE, width=1)
    # Seal mark at end
    circ(d, 50, 32, 5, BRASS_DK, BRASS_EDGE)
    circ(d, 50, 32, 2, BRASS_HI)
    save(img, "message_strip")


def icon_salt_paste():
    img, d = new()
    # Small jar/pot
    rrect(d, 16, 26, 48, 54, 4, BROWN, BROWN_DK)
    # Jar opening
    rrect(d, 18, 20, 46, 28, 2, BROWN_DK, BROWN)
    # Paste visible inside (white/grey)
    rrect(d, 20, 22, 44, 26, 1, (200, 200, 190))
    # Lid/cap
    rrect(d, 14, 16, 50, 22, 2, BRASS, BRASS_EDGE)
    # Salt crystals on top
    circ(d, 28, 18, 2, WHITE)
    circ(d, 36, 19, 2, WHITE)
    circ(d, 32, 17, 1, (220, 220, 215))
    save(img, "salt_paste")


def icon_scaffold_pipe():
    img, d = new()
    # Metal pipe at angle
    d.line([(10, 52), (54, 12)], fill=GREY, width=8)
    d.line([(12, 50), (52, 14)], fill=(180, 180, 185), width=4)
    # Highlight
    d.line([(14, 48), (50, 16)], fill=(210, 210, 215), width=1)
    # Threaded ends
    for pos in [(10, 52), (54, 12)]:
        circ(d, pos[0], pos[1], 6, GREY, (100, 100, 105), 2)
    # Rust spots
    circ(d, 30, 34, 3, (160, 100, 60))
    circ(d, 38, 26, 2, (150, 90, 55))
    save(img, "scaffold_pipe")


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("=== Generating Act 2-3 Inventory Icons ===\n")

    gens = [
        icon_ceramic_bottles, icon_reflective_cinderglass,
        icon_transit_sigil_fragment, icon_tone_cylinder,
        icon_second_relay_core, icon_aerial_transit_prism,
        icon_white_civic_signet_half, icon_complete_civic_signet,
        icon_message_strip, icon_salt_paste, icon_scaffold_pipe,
    ]

    for gen in gens:
        name = gen.__name__.replace("icon_", "")
        gen()
        print(f"  {name}")

    print(f"\n=== Done! {len(gens)} icons ===")
