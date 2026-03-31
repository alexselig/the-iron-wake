#!/usr/bin/env python3
"""Generate flat geometric editorial-style crowd using drawsvg + cairosvg.
Style: bold blocky shapes, no outlines, clean color blocks, warm muted palette.
Matching reference: flat geometric editorial illustration style."""

import drawsvg as draw
import cairosvg
import os
import random
import math

OUTPUT_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/props")

# Steampunk color palette — warm, muted, earthy
SKIN_TONES = [
    "#D4A574", "#C49060", "#E0B88A", "#B8845C", "#CDAA82",
]
COAT_COLORS = [
    "#4A3728", "#3D3225", "#5B4233", "#2E2820", "#4F3D2E",  # dark browns
    "#3A4550", "#2D3A42", "#4B5660",                          # slate blues
    "#5C3A28", "#6B4A35",                                     # russet
]
HAT_COLORS = [
    "#6B5030", "#5A4228", "#7A5E3E", "#4D3A22", "#8B6E4A",
]
SHIRT_COLORS = [
    "#B85A3A", "#8B6B4A", "#6A7B5A", "#9B7A5A", "#7B5A4A",
    "#A0785A", "#887058",
]
HAIR_COLORS = [
    "#3A2515", "#2E1C10", "#4A3020", "#5A4030", "#1E1510",
]
BRASS = "#B89638"
BRASS_DK = "#8A7028"


def draw_person(d, cx, cy, scale=1.0, seed=0):
    """Draw one flat-geometric editorial character."""
    rng = random.Random(seed)
    s = scale

    skin = rng.choice(SKIN_TONES)
    coat = rng.choice(COAT_COLORS)
    shirt = rng.choice(SHIRT_COLORS)
    hair = rng.choice(HAIR_COLORS)
    hat_col = rng.choice(HAT_COLORS)
    has_hat = rng.random() > 0.3
    hat_type = rng.choice(["top", "bowler", "cap", "none" if not has_hat else "top"])
    facing = rng.choice([-1, 1])

    # === BOOTS ===
    boot_w = 5 * s
    boot_h = 6 * s
    for side in [-1, 1]:
        bx = cx + side * 4.5 * s
        d.append(draw.Rectangle(
            bx - boot_w/2, cy + 28*s, boot_w, boot_h,
            fill="#2A2018", rx=1*s
        ))

    # === PANTS/LEGS ===
    pant_color = rng.choice(["#5A6B48", "#6B6048", "#4A5540", "#686050"])
    # Left leg
    leg_pts = [
        (cx - 7*s, cy + 14*s),   # top left
        (cx - 1*s, cy + 14*s),   # top right
        (cx - 1.5*s, cy + 29*s), # bottom right
        (cx - 7.5*s, cy + 29*s), # bottom left
    ]
    d.append(draw.Lines(*[c for p in leg_pts for c in p], close=True, fill=pant_color))
    # Right leg
    leg_pts2 = [
        (cx + 1*s, cy + 14*s),
        (cx + 7*s, cy + 14*s),
        (cx + 7.5*s, cy + 29*s),
        (cx + 1.5*s, cy + 29*s),
    ]
    d.append(draw.Lines(*[c for p in leg_pts2 for c in p], close=True, fill=pant_color))

    # === BODY / COAT ===
    # Coat — trapezoidal shape, wider at bottom
    coat_pts = [
        (cx - 8*s, cy - 2*s),    # top left shoulder
        (cx + 8*s, cy - 2*s),    # top right shoulder
        (cx + 10*s, cy + 16*s),  # bottom right (wider)
        (cx - 10*s, cy + 16*s),  # bottom left (wider)
    ]
    d.append(draw.Lines(*[c for p in coat_pts for c in p], close=True, fill=coat))

    # Coat lapels / opening — show shirt underneath
    lapel_pts = [
        (cx - 2*s, cy - 1*s),
        (cx + 2*s, cy - 1*s),
        (cx + 3*s, cy + 14*s),
        (cx - 3*s, cy + 14*s),
    ]
    d.append(draw.Lines(*[c for p in lapel_pts for c in p], close=True, fill=shirt))

    # Belt
    d.append(draw.Rectangle(cx - 9*s, cy + 11*s, 18*s, 2.5*s, fill=BRASS_DK, rx=0.5*s))
    # Belt buckle
    d.append(draw.Rectangle(cx - 1.5*s, cy + 11*s, 3*s, 2.5*s, fill=BRASS, rx=0.5*s))

    # === ARMS (hands in pockets / at sides) ===
    arm_coat = coat
    # Left arm
    arm_l = [
        (cx - 8*s, cy - 1*s),
        (cx - 12*s, cy + 0*s),
        (cx - 13*s, cy + 12*s),
        (cx - 10*s, cy + 13*s),
    ]
    d.append(draw.Lines(*[c for p in arm_l for c in p], close=True, fill=arm_coat))
    # Right arm
    arm_r = [
        (cx + 8*s, cy - 1*s),
        (cx + 12*s, cy + 0*s),
        (cx + 13*s, cy + 12*s),
        (cx + 10*s, cy + 13*s),
    ]
    d.append(draw.Lines(*[c for p in arm_r for c in p], close=True, fill=arm_coat))

    # Hands (skin-colored circles at arm ends)
    d.append(draw.Circle(cx - 11.5*s, cy + 13*s, 2*s, fill=skin))
    d.append(draw.Circle(cx + 11.5*s, cy + 13*s, 2*s, fill=skin))

    # === NECK ===
    d.append(draw.Rectangle(cx - 2.5*s, cy - 6*s, 5*s, 5*s, fill=skin))

    # === HEAD ===
    head_w = 11 * s
    head_h = 12 * s
    head_cy = cy - 14 * s
    # Main head shape — rounded rectangle
    d.append(draw.Rectangle(
        cx - head_w/2, head_cy - head_h/2, head_w, head_h,
        fill=skin, rx=3.5*s, ry=3.5*s
    ))

    # Jaw — slightly wider bottom, gives character
    jaw_w = 10 * s
    d.append(draw.Rectangle(
        cx - jaw_w/2, head_cy + 1*s, jaw_w, 5*s,
        fill=skin, rx=2*s, ry=2*s
    ))

    # === HAIR ===
    # Top hair block
    d.append(draw.Rectangle(
        cx - head_w/2 - 0.5*s, head_cy - head_h/2 - 1*s,
        head_w + 1*s, head_h * 0.45,
        fill=hair, rx=3*s, ry=2*s
    ))
    # Side hair
    side_x = cx + facing * (head_w/2 - 1*s)
    d.append(draw.Rectangle(
        side_x - 2*s, head_cy - head_h/2, 3*s, head_h * 0.6,
        fill=hair, rx=1*s
    ))

    # === FACE ===
    # Eyes — simple bold rectangles
    eye_y = head_cy - 1 * s
    for side in [-1, 1]:
        ex = cx + side * 3 * s
        # Eye white area (subtle)
        d.append(draw.Rectangle(ex - 1.5*s, eye_y - 1*s, 3*s, 2.2*s, fill="#F5F0E8", rx=0.5*s))
        # Pupil
        d.append(draw.Circle(ex + facing * 0.3*s, eye_y, 0.9*s, fill="#2A1F15"))

    # Eyebrows — bold flat lines
    for side in [-1, 1]:
        bx = cx + side * 3 * s
        d.append(draw.Rectangle(bx - 2.2*s, eye_y - 2.8*s, 4.4*s, 1.2*s, fill=hair, rx=0.3*s))

    # Nose — simple triangle/block
    d.append(draw.Lines(
        cx, head_cy + 0.5*s,
        cx + 2*s * facing, head_cy + 3*s,
        cx - 0.5*s * facing, head_cy + 3*s,
        close=True, fill="#C4915A" if skin == "#D4A574" else "#B08050"
    ))

    # Mouth — small line
    d.append(draw.Rectangle(cx - 2*s, head_cy + 4.5*s, 4*s, 0.8*s, fill="#8B5E3C", rx=0.4*s))

    # === HAT ===
    if has_hat and hat_type == "top":
        brim_y = head_cy - head_h/2 - 1*s
        # Brim
        d.append(draw.Rectangle(cx - 8*s, brim_y - 0.5*s, 16*s, 2*s, fill=hat_col, rx=1*s))
        # Crown
        d.append(draw.Rectangle(cx - 5.5*s, brim_y - 9*s, 11*s, 9*s, fill=hat_col, rx=2*s, ry=1*s))
        # Brass band
        d.append(draw.Rectangle(cx - 5.5*s, brim_y - 3*s, 11*s, 1.5*s, fill=BRASS, rx=0.5*s))
    elif has_hat and hat_type == "bowler":
        brim_y = head_cy - head_h/2 - 1*s
        d.append(draw.Rectangle(cx - 7*s, brim_y - 0.5*s, 14*s, 2*s, fill=hat_col, rx=1*s))
        # Rounded crown
        d.append(draw.Ellipse(cx, brim_y - 4*s, 6*s, 4.5*s, fill=hat_col))
        d.append(draw.Rectangle(cx - 5*s, brim_y - 2*s, 10*s, 1*s, fill=BRASS, rx=0.5*s))
    elif has_hat and hat_type == "cap":
        brim_y = head_cy - head_h/2
        # Flat cap
        d.append(draw.Ellipse(cx + facing*2*s, brim_y - 2*s, 8*s, 3.5*s, fill=hat_col))
        # Brim (front only)
        visor_pts = [
            (cx + facing * 4*s, brim_y),
            (cx + facing * 10*s, brim_y + 1*s),
            (cx + facing * 8*s, brim_y + 2.5*s),
            (cx + facing * 3*s, brim_y + 1.5*s),
        ]
        d.append(draw.Lines(*[c for p in visor_pts for c in p], close=True, fill=hat_col))

    # === ACCESSORIES ===
    # Medallion on some characters
    if rng.random() > 0.6:
        d.append(draw.Circle(cx, cy + 2*s, 2*s, fill=BRASS))
        # Chain
        d.append(draw.Line(cx - 3*s, cy - 2*s, cx, cy + 0.5*s, stroke=BRASS, stroke_width=0.5*s))
        d.append(draw.Line(cx + 3*s, cy - 2*s, cx, cy + 0.5*s, stroke=BRASS, stroke_width=0.5*s))

    # Satchel/bag strap on some
    if rng.random() > 0.5:
        d.append(draw.Line(
            cx - 6*s, cy - 2*s, cx + 6*s, cy + 12*s,
            stroke="#3A2A1A", stroke_width=1.5*s
        ))


def generate_crowd(filename="crowd.png", width=160, height=60, num_people=7):
    """Generate a crowd scene."""
    d = draw.Drawing(width, height)

    # Background transparent

    # Place people with slight variation
    spacing = width / (num_people + 1)
    for i in range(num_people):
        cx = spacing * (i + 1) + random.uniform(-3, 3)
        cy = height * 0.45 + random.uniform(-2, 2)
        scale = random.uniform(0.55, 0.7)
        draw_person(d, cx, cy, scale=scale, seed=i * 17 + 42)

    # Save SVG
    svg_path = os.path.join(OUTPUT_DIR, filename.replace('.png', '.svg'))
    d.save_svg(svg_path)

    # Convert to PNG
    png_path = os.path.join(OUTPUT_DIR, filename)
    cairosvg.svg2png(url=svg_path, write_to=png_path, output_width=width*2, output_height=height*2)

    print(f"Generated: {svg_path}")
    print(f"Generated: {png_path} ({width*2}x{height*2})")
    return svg_path, png_path


def generate_single_character(filename, seed=0, width=60, height=80):
    """Generate a single character."""
    d = draw.Drawing(width, height)
    draw_person(d, width/2, height * 0.42, scale=0.9, seed=seed)

    svg_path = os.path.join(OUTPUT_DIR, filename.replace('.png', '.svg'))
    d.save_svg(svg_path)

    png_path = os.path.join(OUTPUT_DIR, filename)
    cairosvg.svg2png(url=svg_path, write_to=png_path, output_width=width*2, output_height=height*2)

    print(f"Generated: {png_path}")
    return png_path


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Generate the crowd
    generate_crowd("crowd.png", width=160, height=65, num_people=7)

    # Generate a single test character
    generate_single_character("test_character.png", seed=99)

    print("\nDone!")
