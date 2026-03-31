#!/usr/bin/env python3
"""Generate inventory icons programmatically using Pillow.
Creates simple, clear steampunk-style icons on dark backgrounds."""

import os
from PIL import Image, ImageDraw, ImageFont
import math

OUTPUT_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/inventory_icons")
SIZE = 36
PAD = 4  # inner padding

# Colors
BG = (42, 26, 10, 255)
BRASS = (180, 140, 60)
BRASS_LIGHT = (220, 180, 80)
BRASS_DARK = (120, 90, 40)
COPPER = (180, 100, 60)
BROWN = (100, 70, 40)
BROWN_DARK = (60, 40, 25)
GREY = (140, 140, 140)
GREY_DARK = (80, 80, 80)
BLUE_GLOW = (100, 160, 220)
WHITE = (230, 220, 200)
CREAM = (220, 200, 170)
BLACK = (20, 15, 10)
RED_WAX = (160, 50, 40)
GREEN_GLASS = (100, 180, 140)


def new_icon():
    img = Image.new("RGBA", (SIZE, SIZE), BG)
    return img, ImageDraw.Draw(img)


def draw_circle(d, cx, cy, r, fill, outline=None):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=outline)


def draw_rect(d, x1, y1, x2, y2, fill, outline=None):
    d.rectangle([x1, y1, x2, y2], fill=fill, outline=outline)


def save(img, name):
    img.save(os.path.join(OUTPUT_DIR, f"{name}.png"))


def icon_spyglass():
    img, d = new_icon()
    # Tube body
    d.polygon([(8, 22), (28, 12), (30, 16), (10, 26)], fill=BRASS, outline=BRASS_DARK)
    # Lens end (wider)
    draw_circle(d, 28, 14, 5, BRASS_LIGHT, BRASS_DARK)
    draw_circle(d, 28, 14, 3, (160, 200, 220))
    # Crack line
    d.line([(26, 12), (30, 16)], fill=GREY_DARK, width=1)
    # Eyepiece
    draw_circle(d, 9, 24, 3, BRASS_DARK, BRASS)
    save(img, "spyglass")


def icon_medallion():
    img, d = new_icon()
    # Chain
    for i in range(3):
        draw_circle(d, 14 + i * 3, 8, 2, BRASS_DARK)
    # Medallion body
    draw_circle(d, 18, 20, 9, BRASS, BRASS_DARK)
    draw_circle(d, 18, 20, 7, BRASS_LIGHT)
    # Geometric pattern
    draw_circle(d, 18, 20, 4, BRASS)
    d.line([(14, 20), (22, 20)], fill=BRASS_DARK, width=1)
    d.line([(18, 16), (18, 24)], fill=BRASS_DARK, width=1)
    save(img, "medallion")


def icon_stamp():
    img, d = new_icon()
    # Handle (wood)
    draw_rect(d, 13, 6, 23, 20, BROWN, BROWN_DARK)
    draw_rect(d, 15, 8, 21, 12, (120, 85, 50))
    # Base (wider, ink-stained)
    draw_rect(d, 10, 20, 26, 28, BROWN_DARK, BLACK)
    # Ink residue
    draw_rect(d, 11, 26, 25, 28, (40, 30, 50))
    save(img, "stamp")


def icon_brass_strip():
    img, d = new_icon()
    # Long thin brass strip
    draw_rect(d, 6, 14, 30, 22, BRASS, BRASS_DARK)
    # Engraved symbols
    for x in [10, 16, 22]:
        draw_circle(d, x, 18, 2, BRASS_DARK)
        d.point((x, 16), fill=BRASS_LIGHT)
        d.point((x, 20), fill=BRASS_LIGHT)
    save(img, "brass_strip")


def icon_black_shard():
    img, d = new_icon()
    # Irregular shard shape
    d.polygon([(18, 6), (26, 14), (24, 28), (14, 30), (10, 18)],
              fill=(30, 30, 35), outline=(50, 50, 55))
    # Glowing lines
    d.line([(14, 16), (22, 20)], fill=BLUE_GLOW, width=1)
    d.line([(16, 24), (24, 18)], fill=BLUE_GLOW, width=1)
    save(img, "black_shard")


def icon_automaton_hand():
    img, d = new_icon()
    # Palm
    draw_rect(d, 12, 14, 24, 26, BRASS, BRASS_DARK)
    # Fingers
    for x in [13, 17, 21]:
        draw_rect(d, x, 6, x + 3, 14, BRASS_LIGHT, BRASS_DARK)
    # Thumb
    draw_rect(d, 8, 16, 12, 22, BRASS_LIGHT, BRASS_DARK)
    # Gear detail on palm
    draw_circle(d, 18, 20, 3, BRASS_DARK)
    draw_circle(d, 18, 20, 1, BRASS_LIGHT)
    save(img, "automaton_hand")


def icon_guild_badge():
    img, d = new_icon()
    # Circular badge
    draw_circle(d, 18, 18, 10, BRASS, BRASS_DARK)
    draw_circle(d, 18, 18, 7, BRASS_LIGHT, BRASS)
    # Crest (simple cross)
    d.line([(14, 18), (22, 18)], fill=BRASS_DARK, width=2)
    d.line([(18, 14), (18, 22)], fill=BRASS_DARK, width=2)
    # Scratch/break
    d.line([(12, 10), (24, 26)], fill=BG, width=2)
    save(img, "guild_badge")


def icon_fancy_teacup():
    img, d = new_icon()
    # Cup body
    d.arc([10, 12, 26, 28], 0, 180, fill=CREAM, width=2)
    draw_rect(d, 10, 12, 26, 22, CREAM)
    draw_rect(d, 12, 22, 24, 24, CREAM)
    # Handle
    d.arc([24, 14, 32, 24], -60, 60, fill=BRASS, width=2)
    # Gold trim
    d.line([(10, 12), (26, 12)], fill=BRASS, width=1)
    d.line([(12, 24), (24, 24)], fill=BRASS, width=1)
    # Saucer
    d.ellipse([8, 26, 28, 30], fill=CREAM, outline=BRASS)
    save(img, "fancy_teacup")


def icon_focusing_disc():
    img, d = new_icon()
    # Brass frame
    draw_circle(d, 18, 18, 12, BRASS_DARK, BRASS)
    # Glass lens
    draw_circle(d, 18, 18, 9, (140, 180, 200, 180))
    # Light refraction
    draw_circle(d, 18, 18, 4, (180, 210, 230, 160))
    draw_circle(d, 16, 16, 2, (220, 240, 255, 120))
    save(img, "focusing_disc")


def icon_blank_form():
    img, d = new_icon()
    # Paper
    draw_rect(d, 8, 6, 28, 30, CREAM, BROWN)
    # Lines
    for y in [12, 16, 20, 24]:
        d.line([(12, y), (24, y)], fill=GREY, width=1)
    # Box
    draw_rect(d, 10, 8, 18, 10, GREY)
    save(img, "blank_form")


def icon_filled_form():
    img, d = new_icon()
    # Paper
    draw_rect(d, 8, 6, 28, 30, CREAM, BROWN)
    # "Writing" lines
    for y in [12, 16, 20]:
        d.line([(12, y), (22, y)], fill=BROWN_DARK, width=1)
    # Stamp mark
    draw_circle(d, 22, 24, 4, (100, 40, 30, 160))
    save(img, "filled_form")


def icon_fake_permit():
    img, d = new_icon()
    # Paper
    draw_rect(d, 8, 6, 28, 30, CREAM, BROWN)
    # "Writing"
    for y in [10, 14, 18]:
        d.line([(12, y), (24, y)], fill=BROWN_DARK, width=1)
    # Red wax seal
    draw_circle(d, 22, 25, 5, RED_WAX, (120, 30, 20))
    draw_circle(d, 22, 25, 2, (180, 60, 50))
    save(img, "fake_permit")


def icon_clock_spring():
    img, d = new_icon()
    # Spiral spring
    for i in range(40):
        angle = i * 0.4
        r = 3 + i * 0.2
        x = 18 + math.cos(angle) * r
        y = 18 + math.sin(angle) * r
        if 4 < x < 32 and 4 < y < 32:
            d.point((int(x), int(y)), fill=BRASS)
            d.point((int(x) + 1, int(y)), fill=BRASS_LIGHT)
    save(img, "clock_spring")


def icon_lens_frame():
    img, d = new_icon()
    # Outer ring
    draw_circle(d, 18, 18, 12, BRASS, BRASS_DARK)
    # Inner empty
    draw_circle(d, 18, 18, 8, BG)
    # Mounting notches
    for angle in [0, 90, 180, 270]:
        rad = math.radians(angle)
        x = 18 + math.cos(rad) * 10
        y = 18 + math.sin(rad) * 10
        draw_circle(d, int(x), int(y), 2, BRASS_LIGHT)
    save(img, "lens_frame")


def icon_memory_lens():
    img, d = new_icon()
    # Brass frame
    draw_circle(d, 18, 18, 12, BRASS, BRASS_DARK)
    # Glowing lens
    draw_circle(d, 18, 18, 8, (80, 120, 180))
    draw_circle(d, 18, 18, 5, (120, 170, 220))
    draw_circle(d, 18, 18, 2, (180, 220, 255))
    save(img, "memory_lens")


def icon_whistle():
    img, d = new_icon()
    # Tube
    draw_rect(d, 8, 16, 28, 22, BRASS, BRASS_DARK)
    # Mouthpiece
    draw_rect(d, 6, 14, 10, 24, BRASS_LIGHT, BRASS_DARK)
    # Sound hole
    draw_circle(d, 26, 14, 3, BRASS_DARK)
    draw_circle(d, 26, 14, 1, BG)
    save(img, "whistle")


def icon_relay_key():
    img, d = new_icon()
    # Bow (handle ring)
    draw_circle(d, 12, 14, 6, BRASS, BRASS_DARK)
    draw_circle(d, 12, 14, 3, BG)
    # Shaft
    draw_rect(d, 16, 12, 30, 16, BRASS, BRASS_DARK)
    # Teeth
    draw_rect(d, 26, 16, 30, 20, BRASS_LIGHT, BRASS_DARK)
    draw_rect(d, 22, 16, 26, 18, BRASS_LIGHT, BRASS_DARK)
    save(img, "relay_key")


def icon_map_plate():
    img, d = new_icon()
    # Brass plate
    draw_rect(d, 6, 8, 30, 28, BRASS, BRASS_DARK)
    # Engraved coastline
    d.line([(10, 14), (14, 18), (18, 16), (22, 20), (26, 18)], fill=BRASS_DARK, width=1)
    # Island dot
    draw_circle(d, 20, 24, 2, BRASS_LIGHT)
    # Compass mark
    d.line([(26, 10), (26, 14)], fill=BRASS_LIGHT, width=1)
    d.line([(24, 12), (28, 12)], fill=BRASS_LIGHT, width=1)
    save(img, "map_plate")


def icon_copper_wire():
    img, d = new_icon()
    # Coil of wire
    for i in range(30):
        angle = i * 0.5
        r = 4 + (i * 0.15)
        x = 18 + math.cos(angle) * r
        y = 18 + math.sin(angle) * r
        if 4 < x < 32 and 4 < y < 32:
            draw_circle(d, int(x), int(y), 1, COPPER)
    save(img, "copper_wire")


def icon_broken_gear():
    img, d = new_icon()
    # Gear body
    draw_circle(d, 18, 18, 10, BRASS, BRASS_DARK)
    draw_circle(d, 18, 18, 4, BG)
    # Teeth
    for i in range(8):
        angle = math.radians(i * 45)
        x = 18 + math.cos(angle) * 12
        y = 18 + math.sin(angle) * 12
        if i not in [2, 5]:  # Missing teeth
            draw_circle(d, int(x), int(y), 2, BRASS_LIGHT)
    save(img, "broken_gear")


def icon_magnifying_lens():
    img, d = new_icon()
    # Handle
    draw_rect(d, 22, 22, 30, 30, BRASS, BRASS_DARK)
    # Lens ring
    draw_circle(d, 16, 16, 10, BRASS, BRASS_DARK)
    draw_circle(d, 16, 16, 7, (180, 200, 210, 160))
    # Glint
    draw_circle(d, 13, 13, 2, (220, 230, 240, 120))
    save(img, "magnifying_lens")


def icon_oilskin_pouch():
    img, d = new_icon()
    # Pouch body
    d.polygon([(10, 14), (26, 14), (28, 28), (8, 28)], fill=BROWN, outline=BROWN_DARK)
    # Tied top
    d.line([(12, 14), (18, 10), (24, 14)], fill=BROWN_DARK, width=1)
    # String tie
    d.line([(18, 10), (18, 6)], fill=BROWN_DARK, width=1)
    d.line([(16, 6), (20, 6)], fill=BROWN_DARK, width=1)
    save(img, "oilskin_pouch")


def icon_seashell():
    img, d = new_icon()
    # Spiral shell
    draw_circle(d, 18, 18, 10, CREAM, (180, 170, 150))
    draw_circle(d, 16, 16, 6, (210, 200, 180))
    draw_circle(d, 15, 15, 3, (230, 220, 200))
    # Spiral lines
    d.arc([10, 10, 26, 26], 30, 300, fill=(180, 170, 150), width=1)
    d.arc([13, 13, 23, 23], 60, 280, fill=(170, 160, 140), width=1)
    save(img, "seashell")


def icon_brass_key():
    img, d = new_icon()
    # Bow
    draw_circle(d, 12, 16, 5, BRASS, BRASS_DARK)
    draw_circle(d, 12, 16, 2, BG)
    # Shaft
    draw_rect(d, 16, 14, 28, 18, BRASS, BRASS_DARK)
    # Bit
    draw_rect(d, 26, 18, 28, 22, BRASS_LIGHT, BRASS_DARK)
    draw_rect(d, 22, 18, 24, 20, BRASS_LIGHT, BRASS_DARK)
    save(img, "brass_key")


def icon_cipher_plates():
    img, d = new_icon()
    # Stack of plates
    for i, y_off in enumerate([4, 2, 0]):
        draw_rect(d, 8 + y_off, 10 + i * 4, 28 + y_off, 16 + i * 4,
                  BRASS if i == 2 else BRASS_DARK, BRASS_DARK)
    # Symbols on top plate
    d.line([(12, 20), (16, 20)], fill=BRASS_LIGHT, width=1)
    draw_circle(d, 22, 20, 2, BRASS_LIGHT)
    save(img, "cipher_plates")


def icon_repaired_gear():
    img, d = new_icon()
    # Gear body (shiny, all teeth intact)
    draw_circle(d, 18, 18, 10, BRASS_LIGHT, BRASS)
    draw_circle(d, 18, 18, 4, BG)
    # All teeth present
    for i in range(8):
        angle = math.radians(i * 45)
        x = 18 + math.cos(angle) * 12
        y = 18 + math.sin(angle) * 12
        draw_circle(d, int(x), int(y), 2, BRASS_LIGHT, BRASS)
    save(img, "repaired_gear")


def icon_inspection_stamp():
    img, d = new_icon()
    # Same as stamp but with visible seal pattern
    draw_rect(d, 13, 6, 23, 18, BROWN, BROWN_DARK)
    draw_rect(d, 10, 18, 26, 28, BROWN_DARK, BLACK)
    # Seal pattern on base
    draw_circle(d, 18, 23, 4, (60, 40, 60))
    d.line([(15, 23), (21, 23)], fill=GREY, width=1)
    d.line([(18, 20), (18, 26)], fill=GREY, width=1)
    save(img, "inspection_stamp")


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("=== Generating Inventory Icons (Pillow) ===\n")

    generators = [
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

    for gen in generators:
        name = gen.__name__.replace("icon_", "")
        gen()
        print(f"  [OK] {name}")

    print(f"\n=== Done! {len(generators)} icons generated ===")
