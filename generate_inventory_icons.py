#!/usr/bin/env python3
"""Generate inventory icons for all Act 1 items using Gemini AI."""

import os
import time
import warnings
warnings.filterwarnings("ignore")

from google import genai
from google.genai import types
from PIL import Image
import numpy as np

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
OUTPUT_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/inventory_icons")
RATE_LIMIT_DELAY = 5

client = genai.Client(api_key=API_KEY)

STYLE = "simple clean inventory icon for a point-and-click adventure game, single object centered on solid dark brown background (#2a1a0a), steampunk brass and leather aesthetic, warm lighting, slightly stylized cartoon look, clear silhouette, no text, no border"

ITEMS = {
    "spyglass": "a cracked brass spyglass telescope, lens slightly cracked, copper and brass metal",
    "medallion": "a round brass medallion with geometric circular patterns engraved, on a short chain, ancient looking",
    "stamp": "a wooden rubber stamp with handle, official inspection stamp, ink-stained base",
    "brass_strip": "a thin engraved brass strip with mysterious geometric symbols etched into it",
    "black_shard": "a smooth polished black obsidian-like shard, faintly glowing blue geometric lines",
    "automaton_hand": "a detached mechanical brass hand with visible gears and joints, steampunk",
    "guild_badge": "a broken circular brass guild badge, crest partially scratched off, pin on back",
    "fancy_teacup": "an ornate porcelain teacup with gold brass trim, very fancy and pretentious",
    "focusing_disc": "a round glass lens disc with brass frame, light refracting through it",
    "blank_form": "a rolled-up blank paper form document with official lines and boxes",
    "filled_form": "a paper form document with handwriting and an ink stamp mark on it",
    "fake_permit": "an official-looking paper permit document with a red wax seal stamp",
    "clock_spring": "a coiled metal clock spring, brass colored, tightly wound spiral",
    "lens_frame": "a circular brass frame for holding a lens, empty center, ornate rim",
    "memory_lens": "a glowing assembled lens in brass frame, soft blue-white light emanating from center",
    "whistle": "a small brass steam whistle, simple tube shape with mouthpiece",
    "relay_key": "an ornate brass key with geometric teeth pattern, ancient looking",
    "map_plate": "a flat brass plate with an engraved map showing coastline and island",
    "copper_wire": "a coil of copper wire, thin gauge, slightly tarnished",
    "broken_gear": "a brass gear with two broken teeth, steampunk mechanical part",
    "magnifying_lens": "a small magnifying glass with brass handle and frame",
    "oilskin_pouch": "a small brown leather oilskin pouch tied with string",
    "seashell": "a spiral seashell, pale cream colored, slightly iridescent",
    "brass_key": "a simple brass key, old fashioned, barrel type",
    "cipher_plates": "a set of small brass plates with symbols, stacked together",
    "repaired_gear": "a shiny brass gear in perfect condition, all teeth intact",
    "inspection_stamp": "similar to stamp but with official seal pattern visible",
}


def remove_background(img):
    """Remove near-solid backgrounds, keep the item."""
    img = img.convert("RGBA")
    data = np.array(img)

    # Sample bg color from corners
    corners = [data[2, 2, :3], data[2, -2, :3], data[-2, 2, :3], data[-2, -2, :3]]
    bg_color = np.mean(corners, axis=0).astype(int)

    # Simple distance-based removal
    diff = np.max(np.abs(data[:, :, :3].astype(int) - bg_color), axis=2)
    mask = diff < 40
    data[mask, 3] = 0
    return Image.fromarray(data)


def process_icon(raw_img):
    """Process a raw generated image into a 36x36 game icon."""
    # Remove background
    img = remove_background(raw_img)

    # Crop to content
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    # Resize to fit in 32x32 with padding to 36x36
    img.thumbnail((32, 32), Image.LANCZOS)

    # Center on a dark background canvas
    canvas = Image.new("RGBA", (36, 36), (42, 26, 10, 255))
    x = (36 - img.width) // 2
    y = (36 - img.height) // 2
    canvas.paste(img, (x, y), img)
    return canvas


def generate_icon(item_name, item_desc):
    """Generate a single inventory icon."""
    output_path = os.path.join(OUTPUT_DIR, f"{item_name}.png")

    prompt = f"{STYLE}, {item_desc}"

    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
        )
        for part in response.candidates[0].content.parts:
            if part.inline_data is not None:
                raw_path = output_path + ".raw.png"
                part.as_image().save(raw_path)
                raw_img = Image.open(raw_path)
                icon = process_icon(raw_img)
                icon.save(output_path)
                os.remove(raw_path)
                time.sleep(RATE_LIMIT_DELAY)
                return "ok"

        time.sleep(RATE_LIMIT_DELAY)
        return "no_image"

    except Exception as e:
        time.sleep(RATE_LIMIT_DELAY)
        return f"error: {e}"


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"=== Generating {len(ITEMS)} Inventory Icons ===\n")

    done = 0
    failed = []

    for item_name, item_desc in ITEMS.items():
        print(f"  {item_name}...", end=" ", flush=True)
        result = generate_icon(item_name, item_desc)
        if result == "ok":
            done += 1
            print("OK")
        else:
            failed.append(f"{item_name}: {result}")
            print(f"FAIL: {result}")
            # Retry once
            print(f"  Retrying {item_name}...", end=" ", flush=True)
            time.sleep(RATE_LIMIT_DELAY)
            result = generate_icon(item_name, item_desc)
            if result == "ok":
                done += 1
                failed.pop()
                print("OK")
            else:
                print(f"FAIL again")

    print(f"\n=== Done! {done}/{len(ITEMS)} generated, {len(failed)} failed ===")
    if failed:
        print("Failed:")
        for f in failed:
            print(f"  {f}")
