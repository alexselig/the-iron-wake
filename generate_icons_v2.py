#!/usr/bin/env python3
"""Generate high-quality 64x64 inventory icons with bold, clear designs."""

import os
import math
from PIL import Image, ImageDraw

OUTPUT_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/inventory_icons")
S = 64  # Icon size

# Colors - bright enough to read on dark bg
BG = (32, 20, 10, 255)
BRASS = (200, 160, 70)
BRASS_HI = (240, 200, 100)
BRASS_DK = (140, 100, 45)
BRASS_EDGE = (100, 70, 30)
COPPER = (200, 120, 70)
COPPER_HI = (230, 150, 90)
BROWN = (120, 80, 45)
BROWN_HI = (150, 105, 65)
BROWN_DK = (70, 45, 25)
WOOD = (140, 95, 55)
WOOD_HI = (170, 125, 80)
WOOD_DK = (90, 60, 35)
GREY = (160, 160, 165)
GREY_HI = (200, 200, 205)
GREY_DK = (100, 100, 105)
BLUE = (100, 170, 240)
BLUE_HI = (150, 210, 255)
BLUE_DK = (60, 110, 170)
WHITE = (240, 235, 220)
CREAM = (230, 215, 185)
CREAM_DK = (190, 175, 145)
BLACK = (25, 18, 12)
RED = (180, 55, 45)
RED_DK = (130, 35, 30)
GLASS = (170, 200, 215)
GLASS_HI = (210, 230, 240)
PAPER = (225, 215, 190)
PAPER_DK = (195, 185, 160)
INK = (50, 40, 60)


def new():
    img = Image.new("RGBA", (S, S), BG)
    return img, ImageDraw.Draw(img)


def circ(d, cx, cy, r, fill, outline=None, w=1):
    d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=fill, outline=outline, width=w)


def rect(d, x1, y1, x2, y2, fill, outline=None, w=1):
    d.rectangle([x1, y1, x2, y2], fill=fill, outline=outline, width=w)


def rrect(d, x1, y1, x2, y2, r, fill, outline=None):
    d.rounded_rectangle([x1, y1, x2, y2], radius=r, fill=fill, outline=outline)


def save(img, name):
    img.save(os.path.join(OUTPUT_DIR, f"{name}.png"))


def icon_spyglass():
    img, d = new()
    # Main tube
    pts = [(10, 42), (48, 18), (52, 26), (14, 50)]
    d.polygon(pts, fill=BRASS, outline=BRASS_EDGE)
    # Highlight stripe
    d.line([(14, 43), (49, 20)], fill=BRASS_HI, width=2)
    # Lens end
    circ(d, 50, 22, 9, GLASS, BRASS_DK, 2)
    circ(d, 50, 22, 5, GLASS_HI)
    # Crack
    d.line([(46, 18), (54, 26)], fill=GREY_DK, width=2)
    # Eyepiece
    circ(d, 12, 46, 6, BRASS_DK, BRASS_EDGE, 2)
    circ(d, 12, 46, 3, BLACK)
    save(img, "spyglass")


def icon_medallion():
    img, d = new()
    # Chain links
    for i in range(4):
        circ(d, 20 + i*5, 12 - i*1, 3, BRASS_DK, BRASS_EDGE)
    # Main disc
    circ(d, 32, 34, 18, BRASS, BRASS_EDGE, 2)
    circ(d, 32, 34, 14, BRASS_HI, BRASS)
    # Inner geometric pattern
    circ(d, 32, 34, 8, BRASS)
    circ(d, 32, 34, 3, BRASS_HI)
    d.line([(24, 34), (40, 34)], fill=BRASS_EDGE, width=2)
    d.line([(32, 26), (32, 42)], fill=BRASS_EDGE, width=2)
    # Diagonal lines
    d.line([(26, 28), (38, 40)], fill=BRASS_DK, width=1)
    d.line([(38, 28), (26, 40)], fill=BRASS_DK, width=1)
    save(img, "medallion")


def icon_stamp():
    img, d = new()
    # Handle
    rrect(d, 20, 8, 44, 36, 3, WOOD, WOOD_DK)
    # Wood grain highlight
    rect(d, 24, 12, 40, 18, WOOD_HI)
    d.line([(26, 22), (38, 22)], fill=WOOD_HI, width=1)
    # Grip ridges
    for y in [24, 28, 32]:
        d.line([(22, y), (42, y)], fill=WOOD_DK, width=1)
    # Base pad (rubber)
    rrect(d, 16, 36, 48, 52, 2, BROWN_DK, BLACK)
    # Ink stain
    rect(d, 18, 46, 46, 52, INK)
    # Ink residue drip
    circ(d, 24, 54, 2, INK)
    save(img, "stamp")


def icon_brass_strip():
    img, d = new()
    # Main strip
    rrect(d, 8, 22, 56, 42, 3, BRASS, BRASS_EDGE)
    # Highlight
    d.line([(12, 26), (52, 26)], fill=BRASS_HI, width=2)
    # Engraved symbols - 3 distinct geometric marks
    # Symbol 1: circle with dot
    circ(d, 20, 32, 5, BRASS_DK, BRASS_EDGE)
    circ(d, 20, 32, 2, BRASS_HI)
    # Symbol 2: triangle
    d.polygon([(32, 27), (37, 37), (27, 37)], outline=BRASS_EDGE, fill=BRASS_DK)
    # Symbol 3: crossed lines
    d.line([(43, 27), (51, 37)], fill=BRASS_EDGE, width=2)
    d.line([(51, 27), (43, 37)], fill=BRASS_EDGE, width=2)
    save(img, "brass_strip")


def icon_black_shard():
    img, d = new()
    # Irregular crystal shard
    pts = [(32, 6), (48, 20), (44, 50), (24, 56), (16, 38), (20, 16)]
    d.polygon(pts, fill=(35, 35, 42), outline=(60, 60, 70))
    # Glowing geometric lines
    d.line([(22, 22), (40, 32)], fill=BLUE, width=2)
    d.line([(26, 40), (42, 26)], fill=BLUE, width=2)
    d.line([(30, 14), (36, 46)], fill=BLUE_DK, width=1)
    # Glow spots
    circ(d, 32, 30, 3, BLUE_HI)
    circ(d, 28, 38, 2, BLUE)
    save(img, "black_shard")


def icon_automaton_hand():
    img, d = new()
    # Palm
    rrect(d, 18, 26, 46, 50, 3, BRASS, BRASS_EDGE)
    # Fingers
    for x in [20, 28, 36]:
        rrect(d, x, 8, x+6, 28, 2, BRASS_HI, BRASS_EDGE)
        # Joint lines
        d.line([(x, 18), (x+6, 18)], fill=BRASS_EDGE, width=1)
    # Thumb
    rrect(d, 10, 30, 18, 44, 2, BRASS_HI, BRASS_EDGE)
    d.line([(10, 36), (18, 36)], fill=BRASS_EDGE, width=1)
    # Gear in palm
    circ(d, 32, 38, 6, BRASS_DK, BRASS_EDGE)
    circ(d, 32, 38, 3, BRASS_HI)
    # Wrist
    rect(d, 22, 50, 42, 58, BRASS_DK, BRASS_EDGE)
    save(img, "automaton_hand")


def icon_guild_badge():
    img, d = new()
    # Outer ring
    circ(d, 32, 32, 20, BRASS, BRASS_EDGE, 2)
    circ(d, 32, 32, 15, BRASS_HI, BRASS)
    # Crest - shield shape
    d.polygon([(26, 24), (38, 24), (38, 36), (32, 42), (26, 36)],
              fill=BRASS, outline=BRASS_EDGE)
    # Star in crest
    circ(d, 32, 30, 4, BRASS_HI, BRASS_DK)
    # Break/scratch across
    d.line([(18, 14), (46, 50)], fill=BG, width=3)
    d.line([(17, 15), (45, 51)], fill=BRASS_EDGE, width=1)
    # Pin on back (visible at edge)
    d.line([(42, 48), (48, 56)], fill=GREY, width=2)
    save(img, "guild_badge")


def icon_fancy_teacup():
    img, d = new()
    # Saucer
    d.ellipse([10, 44, 54, 56], fill=CREAM, outline=BRASS)
    # Cup body
    d.chord([14, 18, 46, 48], 0, 180, fill=CREAM, outline=CREAM_DK)
    rect(d, 14, 18, 46, 34, CREAM)
    # Gold rim
    d.line([(14, 18), (46, 18)], fill=BRASS_HI, width=2)
    d.line([(16, 44), (44, 44)], fill=BRASS, width=1)
    # Handle
    d.arc([42, 22, 56, 40], -70, 70, fill=BRASS_HI, width=3)
    # Decorative line
    d.line([(18, 30), (42, 30)], fill=BRASS, width=1)
    # Steam wisps
    d.arc([24, 6, 32, 16], 0, 180, fill=(200, 200, 200, 120), width=1)
    d.arc([32, 4, 40, 14], 0, 180, fill=(200, 200, 200, 100), width=1)
    save(img, "fancy_teacup")


def icon_focusing_disc():
    img, d = new()
    # Brass frame
    circ(d, 32, 32, 24, BRASS, BRASS_EDGE, 2)
    # Glass lens
    circ(d, 32, 32, 18, GLASS, BRASS_DK, 2)
    # Light refraction rings
    circ(d, 32, 32, 12, GLASS_HI)
    circ(d, 32, 32, 6, (230, 240, 250))
    # Bright center
    circ(d, 30, 30, 3, WHITE)
    # Frame notches
    for angle in [0, 90, 180, 270]:
        r = math.radians(angle)
        x = 32 + math.cos(r) * 21
        y = 32 + math.sin(r) * 21
        circ(d, int(x), int(y), 3, BRASS_HI, BRASS_EDGE)
    save(img, "focusing_disc")


def icon_blank_form():
    img, d = new()
    # Paper with fold
    d.polygon([(12, 8), (44, 8), (52, 16), (52, 56), (12, 56)], fill=PAPER, outline=BROWN)
    # Corner fold
    d.polygon([(44, 8), (52, 16), (44, 16)], fill=PAPER_DK, outline=BROWN)
    # Ruled lines
    for y in [22, 28, 34, 40, 46]:
        d.line([(18, y), (46, y)], fill=(170, 165, 150), width=1)
    # Header box
    rect(d, 16, 12, 32, 18, None, (170, 165, 150))
    save(img, "blank_form")


def icon_filled_form():
    img, d = new()
    # Paper
    d.polygon([(12, 8), (44, 8), (52, 16), (52, 56), (12, 56)], fill=PAPER, outline=BROWN)
    d.polygon([(44, 8), (52, 16), (44, 16)], fill=PAPER_DK, outline=BROWN)
    # "Handwriting" scribble lines
    for y in [22, 28, 34, 40]:
        length = 22 + (y % 7) * 2
        d.line([(18, y), (18 + length, y)], fill=INK, width=1)
    # Ink stamp mark
    circ(d, 40, 48, 7, (100, 40, 30, 180), (80, 30, 25))
    save(img, "filled_form")


def icon_fake_permit():
    img, d = new()
    # Paper
    d.polygon([(10, 6), (42, 6), (50, 14), (50, 58), (10, 58)], fill=PAPER, outline=BROWN)
    d.polygon([(42, 6), (50, 14), (42, 14)], fill=PAPER_DK, outline=BROWN)
    # Official-looking text lines
    d.line([(16, 12), (36, 12)], fill=INK, width=2)  # Title
    for y in [20, 26, 32]:
        d.line([(16, y), (44, y)], fill=INK, width=1)
    # Big red wax seal
    circ(d, 38, 46, 10, RED, RED_DK, 2)
    circ(d, 38, 46, 5, (200, 70, 60))
    # Cross on seal
    d.line([(34, 46), (42, 46)], fill=RED_DK, width=2)
    d.line([(38, 42), (38, 50)], fill=RED_DK, width=2)
    save(img, "fake_permit")


def icon_clock_spring():
    img, d = new()
    # Draw a tight spiral
    points = []
    for i in range(80):
        angle = i * 0.25
        r = 4 + i * 0.25
        x = 32 + math.cos(angle) * r
        y = 32 + math.sin(angle) * r
        points.append((x, y))
    # Draw as connected line segments
    for i in range(len(points) - 1):
        d.line([points[i], points[i+1]], fill=BRASS_HI, width=3)
    # Highlight inner coil
    for i in range(20):
        angle = i * 0.25
        r = 4 + i * 0.25
        x = 32 + math.cos(angle) * r
        y = 32 + math.sin(angle) * r
        circ(d, int(x), int(y), 1, BRASS_HI)
    save(img, "clock_spring")


def icon_lens_frame():
    img, d = new()
    # Outer ornate ring
    circ(d, 32, 32, 24, BRASS, BRASS_EDGE, 3)
    circ(d, 32, 32, 20, BRASS_HI, BRASS)
    # Empty center
    circ(d, 32, 32, 15, BG)
    # Mounting tabs
    for angle in [0, 60, 120, 180, 240, 300]:
        r = math.radians(angle)
        x = 32 + math.cos(r) * 17
        y = 32 + math.sin(r) * 17
        circ(d, int(x), int(y), 3, BRASS_HI, BRASS_EDGE)
    save(img, "lens_frame")


def icon_memory_lens():
    img, d = new()
    # Brass frame
    circ(d, 32, 32, 24, BRASS, BRASS_EDGE, 2)
    # Glowing lens
    circ(d, 32, 32, 18, BLUE_DK, BRASS_DK, 2)
    circ(d, 32, 32, 13, BLUE)
    circ(d, 32, 32, 8, BLUE_HI)
    circ(d, 32, 32, 3, WHITE)
    # Glow rays
    for angle in range(0, 360, 45):
        r = math.radians(angle)
        x1 = 32 + math.cos(r) * 15
        y1 = 32 + math.sin(r) * 15
        x2 = 32 + math.cos(r) * 20
        y2 = 32 + math.sin(r) * 20
        d.line([(x1, y1), (x2, y2)], fill=BLUE, width=1)
    save(img, "memory_lens")


def icon_whistle():
    img, d = new()
    # Main tube body
    rrect(d, 10, 26, 50, 40, 4, BRASS, BRASS_EDGE)
    # Highlight
    d.line([(14, 30), (46, 30)], fill=BRASS_HI, width=2)
    # Mouthpiece (wider end)
    rrect(d, 6, 22, 16, 44, 3, BRASS_HI, BRASS_EDGE)
    # Sound hole
    circ(d, 46, 22, 6, BRASS_DK, BRASS_EDGE, 2)
    circ(d, 46, 22, 3, BLACK)
    # Sound lines
    d.arc([48, 16, 58, 28], -45, 45, fill=BRASS_HI, width=1)
    d.arc([52, 14, 62, 30], -45, 45, fill=BRASS, width=1)
    save(img, "whistle")


def icon_relay_key():
    img, d = new()
    # Bow (ornate ring handle)
    circ(d, 18, 28, 12, BRASS, BRASS_EDGE, 2)
    circ(d, 18, 28, 7, BG)
    # Decorative dots on bow
    for angle in [0, 90, 180, 270]:
        r = math.radians(angle)
        x = 18 + math.cos(r) * 9
        y = 28 + math.sin(r) * 9
        circ(d, int(x), int(y), 2, BRASS_HI)
    # Shaft
    rrect(d, 28, 24, 56, 32, 2, BRASS, BRASS_EDGE)
    d.line([(30, 26), (54, 26)], fill=BRASS_HI, width=1)
    # Teeth (geometric pattern)
    rect(d, 48, 32, 56, 40, BRASS_HI, BRASS_EDGE)
    rect(d, 40, 32, 48, 36, BRASS_HI, BRASS_EDGE)
    rect(d, 52, 36, 56, 42, BRASS, BRASS_EDGE)
    save(img, "relay_key")


def icon_map_plate():
    img, d = new()
    # Brass plate
    rrect(d, 6, 10, 58, 54, 4, BRASS, BRASS_EDGE)
    # Highlight edge
    d.line([(10, 14), (54, 14)], fill=BRASS_HI, width=1)
    # Engraved coastline
    coast = [(12, 24), (18, 30), (26, 28), (34, 34), (42, 30), (50, 32)]
    d.line(coast, fill=BRASS_EDGE, width=2)
    # Water side (below coast) - hatching
    for y in range(36, 48, 3):
        d.line([(14, y), (50, y)], fill=BRASS_DK, width=1)
    # Island
    circ(d, 36, 42, 4, BRASS_HI, BRASS_EDGE)
    # Compass rose
    d.line([(50, 16), (50, 24)], fill=BRASS_HI, width=2)
    d.line([(46, 20), (54, 20)], fill=BRASS_HI, width=2)
    save(img, "map_plate")


def icon_copper_wire():
    img, d = new()
    # Coiled wire - draw as thick spiral
    points = []
    for i in range(60):
        angle = i * 0.35
        r = 6 + i * 0.3
        x = 32 + math.cos(angle) * r
        y = 32 + math.sin(angle) * r
        points.append((x, y))
    for i in range(len(points) - 1):
        d.line([points[i], points[i+1]], fill=COPPER, width=3)
    # Highlight on inner coils
    for i in range(20):
        angle = i * 0.35
        r = 6 + i * 0.3
        x = 32 + math.cos(angle) * r
        y = 32 + math.sin(angle) * r
        d.line([(int(x), int(y)), (int(x)+1, int(y))], fill=COPPER_HI, width=1)
    # Loose end sticking out
    d.line([(points[-1][0], points[-1][1]), (56, 12)], fill=COPPER, width=3)
    save(img, "copper_wire")


def icon_broken_gear():
    img, d = new()
    # Gear body
    circ(d, 32, 32, 18, BRASS, BRASS_EDGE, 2)
    circ(d, 32, 32, 8, BG)
    # Teeth (some missing)
    for i in range(8):
        angle = math.radians(i * 45 + 22)
        x = 32 + math.cos(angle) * 22
        y = 32 + math.sin(angle) * 22
        if i not in [2, 5]:  # Missing teeth
            circ(d, int(x), int(y), 5, BRASS_HI, BRASS_EDGE)
        else:
            # Broken stubs
            x2 = 32 + math.cos(angle) * 19
            y2 = 32 + math.sin(angle) * 19
            circ(d, int(x2), int(y2), 3, BRASS_DK)
    # Axle hole
    circ(d, 32, 32, 4, BRASS_EDGE)
    save(img, "broken_gear")


def icon_magnifying_lens():
    img, d = new()
    # Handle
    d.line([(38, 38), (54, 54)], fill=BRASS, width=5)
    d.line([(38, 38), (54, 54)], fill=BRASS_HI, width=3)
    # Lens ring
    circ(d, 26, 26, 18, BRASS, BRASS_EDGE, 3)
    # Glass
    circ(d, 26, 26, 14, GLASS)
    circ(d, 26, 26, 8, GLASS_HI)
    # Glint
    circ(d, 22, 20, 4, (240, 245, 250, 160))
    save(img, "magnifying_lens")


def icon_oilskin_pouch():
    img, d = new()
    # Pouch body
    d.polygon([(14, 24), (50, 24), (54, 52), (10, 52)], fill=BROWN, outline=BROWN_DK)
    # Leather texture lines
    d.line([(18, 30), (46, 30)], fill=BROWN_DK, width=1)
    d.line([(16, 40), (48, 40)], fill=BROWN_DK, width=1)
    # Gathered top
    d.polygon([(18, 24), (32, 14), (46, 24)], fill=BROWN_HI, outline=BROWN_DK)
    # String tie
    d.line([(32, 14), (32, 6)], fill=CREAM_DK, width=2)
    d.line([(26, 6), (38, 6)], fill=CREAM_DK, width=2)
    # String bow
    d.arc([24, 2, 32, 10], 180, 360, fill=CREAM_DK, width=2)
    d.arc([32, 2, 40, 10], 180, 360, fill=CREAM_DK, width=2)
    save(img, "oilskin_pouch")


def icon_seashell():
    img, d = new()
    # Main shell body
    circ(d, 30, 32, 18, CREAM, CREAM_DK, 2)
    # Spiral lines
    d.arc([16, 18, 44, 46], 20, 320, fill=CREAM_DK, width=2)
    d.arc([20, 22, 40, 42], 40, 300, fill=(180, 170, 150), width=2)
    d.arc([24, 26, 36, 38], 60, 280, fill=(170, 160, 140), width=2)
    # Inner whorl
    circ(d, 28, 30, 4, (200, 190, 170))
    circ(d, 28, 30, 2, CREAM)
    # Iridescent highlight
    d.arc([22, 24, 38, 40], 90, 180, fill=(200, 180, 210), width=1)
    # Opening
    d.arc([32, 28, 48, 44], -40, 60, fill=BROWN, width=3)
    save(img, "seashell")


def icon_brass_key():
    img, d = new()
    # Bow (simple ring)
    circ(d, 18, 32, 10, BRASS, BRASS_EDGE, 2)
    circ(d, 18, 32, 5, BG)
    # Shaft
    rrect(d, 26, 28, 52, 36, 2, BRASS, BRASS_EDGE)
    d.line([(28, 30), (50, 30)], fill=BRASS_HI, width=1)
    # Bit (teeth)
    rect(d, 46, 36, 52, 44, BRASS_HI, BRASS_EDGE)
    rect(d, 38, 36, 44, 40, BRASS_HI, BRASS_EDGE)
    save(img, "brass_key")


def icon_cipher_plates():
    img, d = new()
    # Stack of 3 plates, slightly offset
    for i, (xoff, yoff) in enumerate([(4, 6), (2, 3), (0, 0)]):
        shade = BRASS_DK if i < 2 else BRASS
        rrect(d, 10+xoff, 14+yoff+i*6, 54+xoff, 26+yoff+i*6, 2, shade, BRASS_EDGE)
    # Symbols on top plate
    circ(d, 22, 32, 4, BRASS_HI, BRASS_EDGE)
    d.polygon([(32, 28), (36, 36), (28, 36)], outline=BRASS_EDGE, fill=BRASS_HI)
    d.line([(42, 28), (48, 36)], fill=BRASS_EDGE, width=2)
    d.line([(48, 28), (42, 36)], fill=BRASS_EDGE, width=2)
    save(img, "cipher_plates")


def icon_repaired_gear():
    img, d = new()
    # Shiny gear - all teeth intact
    circ(d, 32, 32, 18, BRASS_HI, BRASS, 2)
    circ(d, 32, 32, 8, BG)
    # All teeth present and shiny
    for i in range(8):
        angle = math.radians(i * 45 + 22)
        x = 32 + math.cos(angle) * 22
        y = 32 + math.sin(angle) * 22
        circ(d, int(x), int(y), 5, BRASS_HI, BRASS)
    # Shiny axle
    circ(d, 32, 32, 4, BRASS_HI)
    circ(d, 32, 32, 2, WHITE)
    save(img, "repaired_gear")


def icon_inspection_stamp():
    img, d = new()
    # Handle
    rrect(d, 20, 6, 44, 34, 3, WOOD, WOOD_DK)
    rect(d, 24, 10, 40, 16, WOOD_HI)
    for y in [22, 26, 30]:
        d.line([(22, y), (42, y)], fill=WOOD_DK, width=1)
    # Base with seal pattern
    rrect(d, 16, 34, 48, 52, 2, BROWN_DK, BLACK)
    # Official seal visible on base
    circ(d, 32, 43, 7, INK, (30, 25, 40))
    d.line([(28, 43), (36, 43)], fill=GREY, width=1)
    d.line([(32, 39), (32, 47)], fill=GREY, width=1)
    save(img, "inspection_stamp")


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("=== Generating 64x64 Inventory Icons ===\n")

    gens = [
        icon_spyglass, icon_medallion, icon_stamp, icon_brass_strip,
        icon_black_shard, icon_automaton_hand, icon_guild_badge,
        icon_fancy_teacup, icon_focusing_disc, icon_blank_form,
        icon_filled_form, icon_fake_permit, icon_clock_spring,
        icon_lens_frame, icon_memory_lens, icon_whistle, icon_relay_key,
        icon_map_plate, icon_copper_wire, icon_broken_gear,
        icon_magnifying_lens, icon_oilskin_pouch, icon_seashell,
        icon_brass_key, icon_cipher_plates, icon_repaired_gear,
        icon_inspection_stamp,
    ]

    for gen in gens:
        name = gen.__name__.replace("icon_", "")
        gen()
        print(f"  {name}")

    print(f"\n=== Done! {len(gens)} icons at 64x64 ===")
