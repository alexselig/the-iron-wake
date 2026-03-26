#!/usr/bin/env python3
"""Generate pixel art assets for The Brass Tide demo."""
from PIL import Image, ImageDraw
import os

ASSETS = os.path.expanduser("~/SteampunkBeachDemo/assets")

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

# ============================================================
# COLOR PALETTE - Steampunk Beach
# ============================================================
SKY_TOP = (45, 30, 50)        # Dark purple-grey
SKY_MID = (180, 100, 40)      # Amber
SKY_LOW = (220, 140, 50)      # Copper-gold
OCEAN_DARK = (20, 50, 60)     # Dark teal
OCEAN_MID = (30, 70, 80)      # Teal
OCEAN_GLOW = (200, 120, 40)   # Orange glow near vents
STEAM = (200, 200, 210, 160)  # Semi-transparent white
SAND_WET = (140, 110, 70)     # Wet sand
SAND_DRY = (170, 140, 90)    # Dry sand
SAND_DARK = (110, 85, 55)    # Dark sand
BRASS = (180, 150, 60)        # Brass
BRASS_DARK = (120, 95, 30)    # Dark brass
BRASS_LIGHT = (220, 190, 100) # Light brass
PATINA = (70, 130, 100)       # Green patina
WOOD = (90, 60, 35)           # Driftwood
WOOD_LIGHT = (120, 85, 50)    # Light wood
COPPER = (180, 100, 50)       # Copper wire
ROCK = (70, 65, 60)           # Rock
ROCK_LIGHT = (95, 90, 80)     # Light rock
WATER_CLEAR = (80, 140, 150, 180) # Clear tide pool water
CRAB_BLUE = (40, 70, 140)     # Blue crab
CRAB_LIGHT = (60, 100, 170)   # Light blue crab
SHELL_PINK = (200, 160, 140)  # Conch shell
SHELL_DARK = (160, 120, 100)  # Dark shell
CANVAS = (160, 145, 120)      # Tattered canvas
LANTERN = (255, 200, 80)      # Lantern glow
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
ELARA_COAT = (60, 45, 35)     # Dark leather coat
ELARA_SKIN = (200, 160, 130)  # Skin tone
ELARA_HAIR = (50, 30, 20)     # Dark brown hair
ELARA_GOGGLE = (150, 140, 100) # Goggle brass
ELARA_BELT = (100, 70, 40)    # Utility belt
ELARA_BOOT = (40, 30, 25)     # Boots
SEAWEED = (40, 80, 50)        # Seaweed green

# ============================================================
# BACKGROUND (640x360)
# ============================================================
def generate_background():
    img = Image.new("RGBA", (640, 360))
    draw = ImageDraw.Draw(img)

    # === SKY (top 130 pixels) ===
    for y in range(130):
        t = y / 130.0
        if t < 0.5:
            t2 = t / 0.5
            r = int(SKY_TOP[0] + (SKY_MID[0] - SKY_TOP[0]) * t2)
            g = int(SKY_TOP[1] + (SKY_MID[1] - SKY_TOP[1]) * t2)
            b = int(SKY_TOP[2] + (SKY_MID[2] - SKY_TOP[2]) * t2)
        else:
            t2 = (t - 0.5) / 0.5
            r = int(SKY_MID[0] + (SKY_LOW[0] - SKY_MID[0]) * t2)
            g = int(SKY_MID[1] + (SKY_LOW[1] - SKY_MID[1]) * t2)
            b = int(SKY_MID[2] + (SKY_LOW[2] - SKY_MID[2]) * t2)
        draw.line([(0, y), (639, y)], fill=(r, g, b, 255))

    # Cloud shapes
    for cx, cy, w, h in [(100, 30, 80, 15), (300, 20, 120, 20), (500, 40, 90, 12), (200, 55, 70, 10)]:
        for dy in range(h):
            for dx in range(w):
                px = cx + dx - w//2
                py = cy + dy - h//2
                if 0 <= px < 640 and 0 <= py < 360:
                    dist = ((dx - w/2)**2 / (w/2)**2 + (dy - h/2)**2 / (h/2)**2)
                    if dist < 1.0:
                        alpha = int(40 * (1.0 - dist))
                        existing = img.getpixel((px, py))
                        nr = min(255, existing[0] + alpha)
                        ng = min(255, existing[1] + alpha)
                        nb = min(255, existing[2] + alpha)
                        img.putpixel((px, py), (nr, ng, nb, 255))

    # === AIRSHIP SILHOUETTES ===
    def draw_airship(cx, cy, size):
        # Envelope (elongated oval)
        for dy in range(-size, size+1):
            w = int(size * 2.5 * (1.0 - (dy/size)**2)**0.5) if abs(dy) <= size else 0
            for dx in range(-w, w+1):
                px, py = cx + dx, cy + dy
                if 0 <= px < 640 and 0 <= py < 360:
                    img.putpixel((px, py), (25, 18, 30, 255))
        # Gondola
        for dy in range(size, size + size//2):
            w = size // 2
            for dx in range(-w, w+1):
                px, py = cx + dx, cy + dy
                if 0 <= px < 640 and 0 <= py < 360:
                    img.putpixel((px, py), (20, 15, 25, 255))
        # Searchlight beam
        for i in range(20):
            px = cx + i//3
            py = cy + size + size//2 + i
            if 0 <= px < 640 and 0 <= py < 360:
                alpha = max(0, 60 - i * 3)
                existing = img.getpixel((px, py))
                nr = min(255, existing[0] + alpha)
                ng = min(255, existing[1] + alpha)
                nb = min(255, existing[2] + alpha)
                img.putpixel((px, py), (nr, ng, nb, 255))

    draw_airship(150, 35, 8)
    draw_airship(380, 25, 10)
    draw_airship(540, 45, 7)

    # === OCEAN (130-210 pixels) ===
    for y in range(130, 210):
        t = (y - 130) / 80.0
        r = int(OCEAN_DARK[0] + (OCEAN_MID[0] - OCEAN_DARK[0]) * t)
        g = int(OCEAN_DARK[1] + (OCEAN_MID[1] - OCEAN_DARK[1]) * t)
        b = int(OCEAN_DARK[2] + (OCEAN_MID[2] - OCEAN_DARK[2]) * t)
        draw.line([(0, y), (639, y)], fill=(r, g, b, 255))

    # Ocean waves - lighter horizontal lines
    for y in range(135, 210, 6):
        for x in range(0, 640, 2):
            wave_offset = (x * 7 + y * 3) % 12
            if wave_offset < 3:
                px, py = x, y
                if 0 <= py < 360:
                    existing = img.getpixel((px, py))
                    img.putpixel((px, py), (min(255, existing[0]+15), min(255, existing[1]+20), min(255, existing[2]+25), 255))

    # Geothermal vent glow
    for vx in [350, 420]:
        for dy in range(-20, 5):
            for dx in range(-8, 9):
                px = vx + dx
                py = 160 + dy
                if 0 <= px < 640 and 0 <= py < 360:
                    dist = (dx**2 + dy**2)**0.5
                    if dist < 15:
                        alpha = int(60 * (1.0 - dist/15))
                        existing = img.getpixel((px, py))
                        nr = min(255, existing[0] + alpha)
                        ng = min(255, existing[1] + alpha // 2)
                        img.putpixel((px, py), (nr, ng, existing[2], 255))

    # Steam columns from vents
    for vx in [350, 420]:
        for dy in range(-50, 0):
            for dx in range(-3 + dy//15, 4 - dy//15):
                px = vx + dx + (dy % 5 - 2)
                py = 150 + dy
                if 0 <= px < 640 and 0 <= py < 360:
                    alpha = max(0, 30 + dy)
                    existing = img.getpixel((px, py))
                    nr = min(255, existing[0] + alpha)
                    ng = min(255, existing[1] + alpha)
                    nb = min(255, existing[2] + alpha)
                    img.putpixel((px, py), (nr, ng, nb, 255))

    # Floating debris in ocean
    # Barrel
    for dy in range(-4, 5):
        for dx in range(-3, 4):
            px, py = 280 + dx, 175 + dy
            if 0 <= px < 640 and 0 <= py < 360:
                img.putpixel((px, py), WOOD)
    # Plank
    for dx in range(0, 15):
        for dy in range(-1, 2):
            px, py = 200 + dx, 185 + dy
            img.putpixel((px, py), WOOD_LIGHT)

    # === BEACH (210-360) ===
    # Shoreline transition
    for y in range(210, 225):
        t = (y - 210) / 15.0
        for x in range(640):
            wave = ((x * 3 + y * 7) % 10) / 10.0
            if wave < t:
                r = int(OCEAN_MID[0] + (SAND_WET[0] - OCEAN_MID[0]) * t)
                g = int(OCEAN_MID[1] + (SAND_WET[1] - OCEAN_MID[1]) * t)
                b = int(OCEAN_MID[2] + (SAND_WET[2] - OCEAN_MID[2]) * t)
            else:
                r, g, b = OCEAN_MID
            img.putpixel((x, y), (r, g, b, 255))

    # Sand
    for y in range(225, 360):
        t = (y - 225) / 135.0
        for x in range(640):
            # Wet near shoreline, dry further down
            if t < 0.3:
                base = SAND_WET
            elif t < 0.5:
                t2 = (t - 0.3) / 0.2
                base = (
                    int(SAND_WET[0] + (SAND_DRY[0] - SAND_WET[0]) * t2),
                    int(SAND_WET[1] + (SAND_DRY[1] - SAND_WET[1]) * t2),
                    int(SAND_WET[2] + (SAND_DRY[2] - SAND_WET[2]) * t2),
                )
            else:
                base = SAND_DRY
            # Add noise
            noise = ((x * 7 + y * 13) % 11) - 5
            r = max(0, min(255, base[0] + noise))
            g = max(0, min(255, base[1] + noise))
            b = max(0, min(255, base[2] + noise))
            img.putpixel((x, y), (r, g, b, 255))

    # Wet sand reflections near shoreline
    for y in range(225, 245):
        for x in range(0, 640, 3):
            if (x * 5 + y * 3) % 7 < 2:
                existing = img.getpixel((x, y))
                img.putpixel((x, y), (min(255, existing[0]+20), min(255, existing[1]+15), min(255, existing[2]+10), 255))

    # === WORKBENCH (far left) ===
    # Tarp
    for dy in range(0, 25):
        for dx in range(0, 55):
            px, py = 20 + dx, 240 + dy
            if py < 360:
                img.putpixel((px, py), CANVAS if (dx + dy) % 3 != 0 else (150, 135, 110, 255))

    # Bench surface
    draw.rectangle([25, 265, 70, 275], fill=WOOD)
    draw.rectangle([25, 275, 70, 278], fill=WOOD_LIGHT)
    # Bench legs
    draw.rectangle([28, 278, 31, 295], fill=WOOD)
    draw.rectangle([65, 278, 68, 295], fill=WOOD)
    # Lantern pole
    draw.rectangle([72, 240, 74, 290], fill=WOOD)
    # Lantern
    for dy in range(-4, 5):
        for dx in range(-3, 4):
            px, py = 73 + dx, 238 + dy
            if 0 <= px < 640 and 0 <= py < 360:
                img.putpixel((px, py), BRASS)
    # Lantern glow
    for dy in range(-8, 9):
        for dx in range(-8, 9):
            dist = (dx**2 + dy**2)**0.5
            if dist < 8:
                px, py = 73 + dx, 238 + dy
                if 0 <= px < 640 and 0 <= py < 360:
                    alpha = int(40 * (1.0 - dist/8))
                    existing = img.getpixel((px, py))
                    nr = min(255, existing[0] + alpha)
                    ng = min(255, existing[1] + alpha * 3 // 4)
                    nb = min(255, existing[2] + alpha // 4)
                    img.putpixel((px, py), (nr, ng, nb, 255))

    # Rope coiled on hook
    for i in range(10):
        angle = i * 0.6
        rx = int(20 + 3 * (i % 3))
        ry = int(258 + i)
        if 0 <= rx < 640 and 0 <= ry < 360:
            img.putpixel((rx, ry), (120, 100, 60, 255))

    # === TIDE POOL (right-center, ~430-490) ===
    # Rocks around pool
    for rock_x, rock_y, rock_w, rock_h in [(425, 260, 15, 10), (480, 265, 12, 8), (445, 275, 20, 6), (470, 255, 10, 12)]:
        for dy in range(rock_h):
            for dx in range(rock_w):
                px, py = rock_x + dx, rock_y + dy
                if 0 <= px < 640 and 0 <= py < 360:
                    noise = ((dx * 3 + dy * 7) % 5) - 2
                    c = (ROCK[0] + noise, ROCK[1] + noise, ROCK[2] + noise, 255)
                    img.putpixel((px, py), c)

    # Pool water
    for dy in range(15):
        for dx in range(35):
            px, py = 435 + dx, 262 + dy
            if 0 <= px < 640 and 0 <= py < 360:
                noise = ((dx * 5 + dy * 3) % 7) - 3
                img.putpixel((px, py), (80 + noise, 140 + noise, 150 + noise, 255))

    # Seaweed on rocks
    for sy in range(255, 270):
        for sx in [425, 428, 483, 486]:
            if (sy + sx) % 3 == 0 and 0 <= sx < 640 and 0 <= sy < 360:
                img.putpixel((sx, sy), SEAWEED)

    # === DRIFTWOOD PILE (far right, ~530-630) ===
    # Tangled wood
    for i in range(20):
        x1 = 535 + (i * 17) % 90
        y1 = 245 + (i * 7) % 50
        for dx in range(-1, 12):
            for dy in range(-1, 2):
                px, py = x1 + dx, y1 + dy
                if 0 <= px < 640 and 0 <= py < 360:
                    c = WOOD if i % 2 == 0 else WOOD_LIGHT
                    img.putpixel((px, py), c)

    # Large broken gear poking out
    gear_cx, gear_cy = 570, 255
    for angle_step in range(36):
        import math
        angle = angle_step * math.pi * 2 / 36
        for r in range(8, 12):
            px = int(gear_cx + r * math.cos(angle))
            py = int(gear_cy + r * math.sin(angle))
            if 0 <= px < 640 and 0 <= py < 360:
                img.putpixel((px, py), BRASS_DARK)
        # Gear teeth (some missing)
        if angle_step % 4 < 3:  # Missing every 4th tooth
            for r in range(12, 15):
                px = int(gear_cx + r * math.cos(angle))
                py = int(gear_cy + r * math.sin(angle))
                if 0 <= px < 640 and 0 <= py < 360:
                    img.putpixel((px, py), BRASS)

    # Wreck rudder in background (far right)
    # Vertical fin
    for dy in range(0, 40):
        for dx in range(-3, 4):
            px, py = 610 + dx, 180 + dy
            if 0 <= px < 640 and 0 <= py < 360:
                c = (80, 75, 70, 255) if dy < 30 else ROCK
                img.putpixel((px, py), c)
    # "HMS COGSWORTH" text area (just colored blocks to suggest lettering)
    for dx in range(-8, 9):
        for dy in range(0, 4):
            px, py = 610 + dx, 195 + dy
            if 0 <= px < 640:
                img.putpixel((px, py), (100, 90, 80, 255))

    # === FOREGROUND DETAILS ===
    # Seaweed and pipes at bottom edge
    for x in range(0, 640, 8):
        for dy in range(3):
            py = 355 + dy
            if py < 360:
                img.putpixel((x, py), SEAWEED)
                img.putpixel((x+1, py), SEAWEED)

    # Mechanical crab (broken, twitching) in foreground
    mcx, mcy = 320, 340
    for dx in range(-4, 5):
        for dy in range(-2, 3):
            px, py = mcx + dx, mcy + dy
            if 0 <= px < 640 and 0 <= py < 360:
                img.putpixel((px, py), BRASS_DARK)
    # Tiny legs
    for leg_dx in [-5, -4, 4, 5]:
        img.putpixel((mcx + leg_dx, mcy + 2), BRASS)

    # Footprints from camp to capsule
    for i in range(8):
        fx = 100 + i * 18
        fy = 290 + (i % 2) * 3
        for dy in range(3):
            for dx in range(2):
                px, py = fx + dx, fy + dy
                if 0 <= px < 640 and 0 <= py < 360:
                    img.putpixel((px, py), SAND_DARK)

    # Bubbles from buried steam pipe
    for i in range(5):
        bx = 250 + i * 3
        by = 335 - i * 4
        if 0 <= bx < 640 and 0 <= by < 360:
            img.putpixel((bx, by), (200, 200, 210, 255))

    img.save(os.path.join(ASSETS, "backgrounds", "beach.png"))
    print("Generated: beach background")

# ============================================================
# PLAYER CHARACTER SPRITE SHEET
# ============================================================
def generate_character():
    """Generate a simple sprite sheet for Elara.
    Layout: 4 columns x 4 rows = 16 frames, each 32x48
    Row 0: idle_right (2 frames), idle_left (2 frames)
    Row 1: walk_right (4 frames)
    Row 2: walk_left (4 frames)
    Row 3: talk_right (2 frames), talk_left (2 frames)
    """
    frame_w, frame_h = 32, 48
    cols, rows = 4, 4
    sheet = Image.new("RGBA", (frame_w * cols, frame_h * rows), (0, 0, 0, 0))

    def draw_elara(frame_img, facing_right=True, frame_type="idle", frame_num=0):
        d = ImageDraw.Draw(frame_img)
        # Mirror x if facing left
        def mx(x):
            return x if facing_right else (frame_w - 1 - x)
        # Sorted rect helper (ensures x0 <= x1)
        def mrect(x0, y0, x1, y1, **kwargs):
            rx0, rx1 = min(mx(x0), mx(x1)), max(mx(x0), mx(x1))
            d.rectangle([rx0, y0, rx1, y1], **kwargs)

        # Boots
        mrect(12, 40, 15, 47, fill=ELARA_BOOT)
        mrect(17, 40, 20, 47, fill=ELARA_BOOT)

        # Walk animation - leg offset
        leg_offset = 0
        if frame_type == "walk":
            offsets = [0, 2, 0, -2]
            leg_offset = offsets[frame_num % 4]
            mrect(12, 40 - abs(leg_offset), 15, 47, fill=ELARA_BOOT)
            mrect(17, 40 + abs(leg_offset) - 2, 20, 47, fill=ELARA_BOOT)

        # Legs
        mrect(13, 33, 15, 40, fill=ELARA_COAT)
        mrect(17, 33, 19, 40, fill=ELARA_COAT)

        # Coat body
        mrect(11, 18, 21, 33, fill=ELARA_COAT)
        # Belt
        mrect(11, 28, 21, 30, fill=ELARA_BELT)
        # Belt buckle
        d.point([mx(16), 29], fill=BRASS)

        # Arms
        arm_y = 20
        if frame_type == "talk" and frame_num % 2 == 1:
            arm_y = 18  # Raised arm for talking
        mrect(9, arm_y, 11, 30, fill=ELARA_COAT)
        mrect(21, arm_y + 1, 23, 29, fill=ELARA_COAT)
        # Hands
        d.point([mx(9), 30], fill=ELARA_SKIN)
        d.point([mx(10), 30], fill=ELARA_SKIN)
        d.point([mx(22), 29], fill=ELARA_SKIN)

        # Head
        mrect(13, 8, 19, 17, fill=ELARA_SKIN)
        # Hair
        mrect(12, 6, 20, 10, fill=ELARA_HAIR)
        if facing_right:
            mrect(12, 10, 13, 14, fill=ELARA_HAIR)
        else:
            mrect(19, 10, 20, 14, fill=ELARA_HAIR)

        # Goggles on forehead
        mrect(14, 8, 18, 10, fill=ELARA_GOGGLE)

        # Eye
        eye_x = mx(17) if facing_right else mx(15)
        d.point([eye_x, 12], fill=(30, 30, 30))

        # Mouth (changes for talking)
        mouth_x = mx(16)
        if frame_type == "talk" and frame_num % 2 == 1:
            d.point([mouth_x, 15], fill=(150, 80, 80))
            d.point([mouth_x + (1 if facing_right else -1), 15], fill=(150, 80, 80))
        else:
            d.point([mouth_x, 15], fill=(170, 120, 100))

    # Generate all frames
    for row in range(rows):
        for col in range(cols):
            frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
            if row == 0:  # idle
                facing = col < 2
                draw_elara(frame, facing_right=facing, frame_type="idle", frame_num=col % 2)
            elif row == 1:  # walk_right
                draw_elara(frame, facing_right=True, frame_type="walk", frame_num=col)
            elif row == 2:  # walk_left
                draw_elara(frame, facing_right=False, frame_type="walk", frame_num=col)
            elif row == 3:  # talk
                facing = col < 2
                draw_elara(frame, facing_right=facing, frame_type="talk", frame_num=col % 2)

            sheet.paste(frame, (col * frame_w, row * frame_h))

    sheet.save(os.path.join(ASSETS, "characters", "elara_spritesheet.png"))
    print("Generated: elara spritesheet")

# ============================================================
# PROP SPRITES
# ============================================================
def generate_props():
    props_dir = os.path.join(ASSETS, "props")

    # --- Capsule (3 frames: closed, keyhole-revealed, open) ---
    # 64x48 per frame, 3 frames horizontal = 192x48
    capsule = Image.new("RGBA", (192, 48), (0, 0, 0, 0))
    for frame in range(3):
        ox = frame * 64
        d = ImageDraw.Draw(capsule)
        # Ovoid shape
        for dy in range(-20, 21):
            w = int(28 * (1.0 - (dy / 20.0) ** 2) ** 0.5)
            for dx in range(-w, w + 1):
                px, py = ox + 32 + dx, 24 + dy
                dist_from_edge = w - abs(dx)
                if dist_from_edge < 3:
                    c = BRASS_DARK
                elif abs(dy) > 15:
                    c = PATINA  # Barnacles at bottom
                else:
                    c = BRASS
                capsule.putpixel((px, py), c)

        # Gear mechanism on front
        gcx, gcy = ox + 32, 24
        if frame == 0:
            # Three gear circles, center one empty
            for g_off in [-8, 0, 8]:
                for gdx in range(-3, 4):
                    for gdy in range(-3, 4):
                        if gdx**2 + gdy**2 <= 9:
                            px, py = gcx + g_off + gdx, gcy + gdy
                            if 0 <= px < 192:
                                if g_off == 0:
                                    capsule.putpixel((px, py), BRASS_DARK)  # Missing gear
                                else:
                                    capsule.putpixel((px, py), BRASS_LIGHT)
        elif frame == 1:
            # Keyhole revealed
            for gdx in range(-2, 3):
                for gdy in range(-4, 5):
                    px, py = gcx + gdx, gcy + gdy
                    if 0 <= px < 192:
                        if abs(gdx) <= 1 and abs(gdy) <= 2:
                            capsule.putpixel((px, py), BLACK)  # Keyhole
                        else:
                            capsule.putpixel((px, py), BRASS_LIGHT)
        elif frame == 2:
            # Open - top half lifted
            # Draw open lid above
            for dy in range(-20, -5):
                w = int(20 * (1.0 - ((dy + 12) / 8.0) ** 2) ** 0.5) if abs(dy + 12) <= 8 else 0
                for dx in range(-w, w + 1):
                    px, py = gcx + dx, dy + 14
                    if 0 <= px < 192 and 0 <= py < 48:
                        capsule.putpixel((px, py), BRASS)
            # Inner velvet
            for dy in range(-5, 10):
                w = int(22 * (1.0 - (dy / 15.0) ** 2) ** 0.5) if abs(dy) <= 15 else 0
                for dx in range(-w, w + 1):
                    px, py = gcx + dx, 24 + dy
                    if 0 <= px < 192 and 0 <= py < 48:
                        capsule.putpixel((px, py), (80, 30, 40, 255))  # Dark velvet

        # Phosphorescent glow
        for dy in range(-22, 23):
            for dx in range(-30, 31):
                px, py = ox + 32 + dx, 24 + dy
                if 0 <= px < 192 and 0 <= py < 48:
                    dist = (dx**2 + dy**2)**0.5
                    if 20 < dist < 25:
                        existing = capsule.getpixel((px, py))
                        if existing[3] == 0:
                            alpha = int(30 * (1.0 - (dist - 20) / 5))
                            capsule.putpixel((px, py), (100, 200, 150, alpha))

    capsule.save(os.path.join(props_dir, "capsule.png"))
    print("Generated: capsule prop")

    # --- Magnifying Lens (16x16) ---
    lens = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(lens)
    # Handle
    d.line([(2, 13), (6, 9)], fill=WOOD, width=2)
    # Lens rim
    for dx in range(-4, 5):
        for dy in range(-4, 5):
            dist = (dx**2 + dy**2)**0.5
            if 3 < dist < 5:
                lens.putpixel((9 + dx, 6 + dy), BRASS)
            elif dist <= 3:
                lens.putpixel((9 + dx, 6 + dy), (180, 200, 220, 120))  # Glass
    lens.save(os.path.join(props_dir, "magnifying_lens.png"))

    # --- Copper Wire (24x16) ---
    wire = Image.new("RGBA", (24, 16), (0, 0, 0, 0))
    import math
    for i in range(40):
        t = i / 40.0
        x = int(12 + 8 * math.cos(t * math.pi * 3))
        y = int(8 + 5 * math.sin(t * math.pi * 3))
        if 0 <= x < 24 and 0 <= y < 16:
            wire.putpixel((x, y), COPPER)
            if x + 1 < 24:
                wire.putpixel((x + 1, y), COPPER)
    wire.save(os.path.join(props_dir, "copper_wire.png"))

    # --- Crab (24x16, 2 frames: idle and retreating) ---
    crab_sheet = Image.new("RGBA", (48, 16), (0, 0, 0, 0))
    for frame in range(2):
        ox = frame * 24
        d = ImageDraw.Draw(crab_sheet)
        # Body
        for dx in range(-5, 6):
            for dy in range(-3, 4):
                if dx**2/25 + dy**2/9 < 1:
                    px, py = ox + 12 + dx, 10 + dy
                    if 0 <= px < 48:
                        crab_sheet.putpixel((px, py), CRAB_BLUE)
        # Eyes
        crab_sheet.putpixel((ox + 9, 6), (255, 200, 100, 255))
        crab_sheet.putpixel((ox + 15, 6), (255, 200, 100, 255))
        # Claws
        if frame == 0:  # Raised claws
            for cy in range(4, 8):
                crab_sheet.putpixel((ox + 5, cy), CRAB_LIGHT)
                crab_sheet.putpixel((ox + 19, cy), CRAB_LIGHT)
            crab_sheet.putpixel((ox + 4, 4), CRAB_LIGHT)
            crab_sheet.putpixel((ox + 20, 4), CRAB_LIGHT)
        else:  # Retreating (claws down)
            for cy in range(10, 14):
                crab_sheet.putpixel((ox + 5, cy), CRAB_LIGHT)
                crab_sheet.putpixel((ox + 19, cy), CRAB_LIGHT)
        # Legs
        for leg in range(3):
            lx = ox + 7 + leg * 3
            crab_sheet.putpixel((lx, 13), CRAB_BLUE)
            crab_sheet.putpixel((lx, 14), CRAB_BLUE)
            rx = ox + 14 + leg * 3 - 3
    crab_sheet.save(os.path.join(props_dir, "crab.png"))

    # --- Seashell (16x16) ---
    shell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(shell)
    # Spiral conch
    for i in range(60):
        t = i / 60.0
        r = 3 + t * 4
        angle = t * math.pi * 3
        x = int(8 + r * math.cos(angle))
        y = int(8 + r * math.sin(angle))
        if 0 <= x < 16 and 0 <= y < 16:
            c = SHELL_PINK if i % 3 != 0 else SHELL_DARK
            shell.putpixel((x, y), c)
            if x + 1 < 16:
                shell.putpixel((x + 1, y), c)
    shell.save(os.path.join(props_dir, "seashell.png"))

    # --- Oilskin Pouch (16x20) ---
    pouch = Image.new("RGBA", (16, 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(pouch)
    # Pouch body
    d.rectangle([3, 4, 12, 17], fill=(50, 45, 35, 255))
    d.rectangle([4, 3, 11, 4], fill=(50, 45, 35, 255))  # Flap
    # Tie
    d.line([(6, 4), (9, 4)], fill=(120, 100, 60, 255))
    # Oil stain
    d.rectangle([5, 10, 10, 14], fill=(40, 35, 25, 255))
    pouch.save(os.path.join(props_dir, "oilskin_pouch.png"))

    # --- Broken Gear (20x20) ---
    gear = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    for angle_step in range(24):
        angle = angle_step * math.pi * 2 / 24
        for r_val in range(4, 8):
            px = int(10 + r_val * math.cos(angle))
            py = int(10 + r_val * math.sin(angle))
            if 0 <= px < 20 and 0 <= py < 20:
                gear.putpixel((px, py), BRASS)
        # Teeth (some broken)
        if angle_step % 3 != 0 and angle_step < 16:  # Some teeth missing
            for r_val in range(8, 10):
                px = int(10 + r_val * math.cos(angle))
                py = int(10 + r_val * math.sin(angle))
                if 0 <= px < 20 and 0 <= py < 20:
                    gear.putpixel((px, py), BRASS_LIGHT)
    # Center hole
    for dx in range(-2, 3):
        for dy in range(-2, 3):
            if dx**2 + dy**2 <= 4:
                gear.putpixel((10 + dx, 10 + dy), BRASS_DARK)
    gear.save(os.path.join(props_dir, "broken_gear.png"))

    # --- Brass Key (12x16) ---
    key = Image.new("RGBA", (12, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(key)
    # Bow (head)
    for dx in range(-3, 4):
        for dy in range(-3, 4):
            if dx**2 + dy**2 <= 9:
                px, py = 6 + dx, 4 + dy
                if 0 <= px < 12 and 0 <= py < 16:
                    key.putpixel((px, py), BRASS_LIGHT if dx**2 + dy**2 > 4 else BRASS)
    # Shaft
    d.rectangle([5, 7, 7, 14], fill=BRASS)
    # Bit (teeth)
    d.rectangle([7, 12, 9, 13], fill=BRASS_LIGHT)
    d.rectangle([7, 14, 10, 15], fill=BRASS_LIGHT)
    key.save(os.path.join(props_dir, "brass_key.png"))

    # --- Cipher Plates (32x24) ---
    plates = Image.new("RGBA", (32, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(plates)
    # Stack of thin metal plates
    for plate_i in range(3):
        y_off = plate_i * 3
        d.rectangle([4 + plate_i, 6 + y_off, 27 - plate_i, 10 + y_off], fill=BRASS_LIGHT)
        # Etched symbols (tiny dots)
        for sx in range(6 + plate_i, 26 - plate_i, 3):
            d.point([sx, 8 + y_off], fill=BRASS_DARK)
    plates.save(os.path.join(props_dir, "cipher_plates.png"))

    print("Generated: all props")

# ============================================================
# INVENTORY ICONS (24x24 each)
# ============================================================
def generate_inventory_icons():
    icons_dir = os.path.join(ASSETS, "inventory_icons")
    import math

    def make_icon(name, draw_func):
        img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        draw_func(img, d)
        img.save(os.path.join(icons_dir, f"{name}.png"))

    # Magnifying Lens
    def draw_mag(img, d):
        d.line([(3, 20), (9, 14)], fill=WOOD, width=2)
        for dx in range(-5, 6):
            for dy in range(-5, 6):
                dist = (dx**2 + dy**2)**0.5
                if 3 < dist < 5.5:
                    img.putpixel((14 + dx, 10 + dy), BRASS)
                elif dist <= 3:
                    img.putpixel((14 + dx, 10 + dy), (180, 200, 220, 100))
    make_icon("magnifying_lens", draw_mag)

    # Copper Wire
    def draw_wire(img, d):
        for i in range(50):
            t = i / 50.0
            x = int(12 + 8 * math.cos(t * math.pi * 3))
            y = int(12 + 8 * math.sin(t * math.pi * 3))
            if 0 <= x < 24 and 0 <= y < 24:
                img.putpixel((x, y), COPPER)
    make_icon("copper_wire", draw_wire)

    # Oilskin Pouch
    def draw_pouch(img, d):
        d.rectangle([6, 6, 17, 19], fill=(50, 45, 35, 255))
        d.rectangle([7, 5, 16, 6], fill=(50, 45, 35, 255))
        d.line([(9, 6), (14, 6)], fill=(120, 100, 60, 255))
        d.rectangle([8, 12, 15, 16], fill=(40, 35, 25, 255))
    make_icon("oilskin_pouch", draw_pouch)

    # Broken Gear
    def draw_bgear(img, d):
        for angle_step in range(24):
            angle = angle_step * math.pi * 2 / 24
            for r in range(3, 7):
                px = int(12 + r * math.cos(angle))
                py = int(12 + r * math.sin(angle))
                if 0 <= px < 24 and 0 <= py < 24:
                    img.putpixel((px, py), BRASS)
            if angle_step % 3 != 0 and angle_step < 16:
                for r in range(7, 9):
                    px = int(12 + r * math.cos(angle))
                    py = int(12 + r * math.sin(angle))
                    if 0 <= px < 24 and 0 <= py < 24:
                        img.putpixel((px, py), BRASS_LIGHT)
    make_icon("broken_gear", draw_bgear)

    # Seashell
    def draw_shell(img, d):
        for i in range(60):
            t = i / 60.0
            r = 3 + t * 7
            angle = t * math.pi * 3
            x = int(12 + r * math.cos(angle))
            y = int(12 + r * math.sin(angle))
            if 0 <= x < 24 and 0 <= y < 24:
                c = SHELL_PINK if i % 3 != 0 else SHELL_DARK
                img.putpixel((x, y), c)
    make_icon("seashell", draw_shell)

    # Brass Key
    def draw_key(img, d):
        for dx in range(-3, 4):
            for dy in range(-3, 4):
                if dx**2 + dy**2 <= 9:
                    px, py = 12 + dx, 7 + dy
                    if 0 <= px < 24 and 0 <= py < 24:
                        img.putpixel((px, py), BRASS_LIGHT if dx**2 + dy**2 > 4 else BRASS)
        d.rectangle([11, 10, 13, 20], fill=BRASS)
        d.rectangle([13, 18, 16, 19], fill=BRASS_LIGHT)
        d.rectangle([13, 20, 17, 21], fill=BRASS_LIGHT)
    make_icon("brass_key", draw_key)

    # Cipher Plates
    def draw_plates(img, d):
        for i in range(3):
            y = 7 + i * 4
            d.rectangle([4 + i, y, 19 - i, y + 3], fill=BRASS_LIGHT)
            for sx in range(6 + i, 18 - i, 3):
                d.point([sx, y + 1], fill=BRASS_DARK)
    make_icon("cipher_plates", draw_plates)

    # Repaired Gear
    def draw_rgear(img, d):
        for angle_step in range(24):
            angle = angle_step * math.pi * 2 / 24
            for r in range(3, 7):
                px = int(12 + r * math.cos(angle))
                py = int(12 + r * math.sin(angle))
                if 0 <= px < 24 and 0 <= py < 24:
                    img.putpixel((px, py), BRASS)
            # All teeth present (some copper-colored for repairs)
            for r in range(7, 9):
                px = int(12 + r * math.cos(angle))
                py = int(12 + r * math.sin(angle))
                if 0 <= px < 24 and 0 <= py < 24:
                    c = COPPER if angle_step % 3 == 0 else BRASS_LIGHT
                    img.putpixel((px, py), c)
    make_icon("repaired_gear", draw_rgear)

    print("Generated: all inventory icons")

# ============================================================
# RUN ALL
# ============================================================
if __name__ == "__main__":
    ensure_dir(os.path.join(ASSETS, "backgrounds"))
    ensure_dir(os.path.join(ASSETS, "characters"))
    ensure_dir(os.path.join(ASSETS, "props"))
    ensure_dir(os.path.join(ASSETS, "inventory_icons"))

    generate_background()
    generate_character()
    generate_props()
    generate_inventory_icons()
    print("\nAll assets generated!")
