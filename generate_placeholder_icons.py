#!/usr/bin/env python3
"""Generate simple placeholder inventory icons for missing items."""

from PIL import Image, ImageDraw, ImageFont
import os

ICONS_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/inventory_icons")
SIZE = 36

# Colors
BRASS = (139, 105, 20)
DARK_BG = (61, 43, 26)
BORDER = (160, 112, 32)
TEXT_COLOR = (212, 168, 80)

MISSING = {
    "automaton_hand": "AH",
    "clock_spring": "CS",
    "whistle": "WH",
    "lens_frame": "LF",
}

os.makedirs(ICONS_DIR, exist_ok=True)

for name, label in MISSING.items():
    path = os.path.join(ICONS_DIR, f"{name}.png")
    if os.path.exists(path):
        print(f"  [SKIP] {name}.png already exists")
        continue

    img = Image.new("RGBA", (SIZE, SIZE), DARK_BG + (255,))
    draw = ImageDraw.Draw(img)

    # Brass border
    draw.rectangle([0, 0, SIZE - 1, SIZE - 1], outline=BORDER, width=2)
    # Corner dots (rivets)
    for x, y in [(3, 3), (SIZE - 4, 3), (3, SIZE - 4), (SIZE - 4, SIZE - 4)]:
        draw.ellipse([x - 1, y - 1, x + 1, y + 1], fill=BRASS)

    # Center label
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 12)
    except Exception:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), label, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((SIZE - tw) // 2, (SIZE - th) // 2 - 1), label, fill=TEXT_COLOR, font=font)

    img.save(path)
    print(f"  [OK] Placeholder: {name}.png")

print("\nDone! Replace with Gemini art when API key is renewed.")
