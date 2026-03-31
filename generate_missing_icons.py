#!/usr/bin/env python3
"""Generate missing inventory icons for Act 1 items via Gemini API."""

import os
import time
from google import genai
from google.genai import types
from PIL import Image

API_KEY = os.environ.get("GEMINI_API_KEY", "")

# Load from .env if present
_env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
if not API_KEY and os.path.exists(_env_path):
    for _line in open(_env_path):
        if _line.startswith("GEMINI_API_KEY="):
            API_KEY = _line.strip().split("=", 1)[1]
if not API_KEY:
    print("ERROR: Set GEMINI_API_KEY in .env or environment. Never hardcode it.")
    exit(1)
MODEL = "gemini-2.5-flash-image"
ICONS_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/inventory_icons")
RATE_LIMIT_DELAY = 5

client = genai.Client(api_key=API_KEY)

ICON_STYLE = (
    "game inventory icon, steampunk style, detailed small square icon, "
    "dark background with brass border frame, centered object, "
    "warm brown and brass color palette, pixel art feel"
)

MISSING_ICONS = {
    "black_shard": "jagged shard of obsidian-black crystal with faint glowing runes etched on surface, sharp angular fragment",
    "automaton_hand": "detached brass mechanical hand with articulated gear fingers, steampunk robot hand, copper joints",
    "clock_spring": "coiled steel clock mainspring, tightly wound spiral spring, silvery metallic with brass housing",
    "whistle": "ornate brass steam whistle with valve handle, steampunk train whistle, small handheld",
    "lens_frame": "empty circular brass lens frame with gear mounting brackets, monocle-like frame without glass",
}


def generate_icon(name, desc):
    output_path = os.path.join(ICONS_DIR, f"{name}.png")
    if os.path.exists(output_path):
        print(f"  [SKIP] Already exists: {name}.png")
        return True

    print(f"  Generating: {name}.png...")
    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=f"{ICON_STYLE}, {desc}",
            config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
        )
        for part in response.candidates[0].content.parts:
            if part.inline_data is not None:
                raw_path = output_path + ".raw.png"
                part.as_image().save(raw_path)
                img = Image.open(raw_path).resize((36, 36), Image.LANCZOS)
                img.save(output_path)
                os.remove(raw_path)
                print(f"  [OK] Saved: {name}.png")
                time.sleep(RATE_LIMIT_DELAY)
                return True

        print(f"  [WARN] No image in response for {name}")
        time.sleep(RATE_LIMIT_DELAY)
        return False

    except Exception as e:
        print(f"  [ERROR] {e}")
        time.sleep(RATE_LIMIT_DELAY)
        return False


if __name__ == "__main__":
    print("=== Generating Missing Inventory Icons ===\n")
    os.makedirs(ICONS_DIR, exist_ok=True)

    for name, desc in MISSING_ICONS.items():
        success = generate_icon(name, desc)
        if not success:
            print(f"  Retrying {name}...")
            time.sleep(RATE_LIMIT_DELAY)
            generate_icon(name, desc)

    print("\n=== Done! ===")
