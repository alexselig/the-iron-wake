#!/usr/bin/env python3
"""Generate proper prop sprites for objects that were using mismatched placeholder art.

Matches the style/pipeline of generate_props.py, but adds background cleanup,
autocrop, and bottom-anchoring so each sprite sits tightly on its surface
(content is flush with the bottom edge of the target canvas).
"""

import os
import time
import warnings
warnings.filterwarnings("ignore")

from google import genai
from google.genai import types
from PIL import Image
import io

API_KEY = os.environ.get("GEMINI_API_KEY", "")
_env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
if not API_KEY and os.path.exists(_env_path):
    for _line in open(_env_path):
        if _line.startswith("GEMINI_API_KEY="):
            API_KEY = _line.strip().split("=", 1)[1]
if not API_KEY:
    print("ERROR: Set GEMINI_API_KEY in .env or environment. Never hardcode it.")
    exit(1)

MODEL = "gemini-2.5-flash-image"
PROPS_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/props")
RATE_LIMIT_DELAY = 5

client = genai.Client(api_key=API_KEY)

# Same base style as generate_props.py so new props blend with the existing set.
STYLE = ("tiny pixel art sprite on transparent background, steampunk adventure "
         "game prop, flat color areas with brass and copper tones, clean "
         "silhouette, no text, no labels, game asset icon style, warm muted "
         "palette, single centered object")

PROPS = {
    # Brass Bazaar
    "guild_badge": {
        "prompt": f"{STYLE}, a round tarnished brass guild badge or membership medallion "
                  "with an engraved crest, cracked and broken down the middle, pin on the back",
        "size": (34, 34),
    },
    "fancy_teacup": {
        "prompt": f"{STYLE}, an ornate porcelain teacup with delicate gold filigree resting "
                  "on a matching saucer, fine luxury china, small handle",
        "size": (32, 26),
    },
    # Harbor Cliffs
    "iron_lantern": {
        "prompt": f"{STYLE}, an old weathered iron harbor lantern with four glass panes, a "
                  "domed brass cap and a carry ring on top, an unlit candle inside, standing upright",
        "size": (28, 42),
    },
    # Smuggler Path
    "signal_lantern": {
        "prompt": f"{STYLE}, a nautical signal lantern with a round red glass lens, a brass hood "
                  "and shutter, a carry handle, sailor's signaling lamp, standing upright",
        "size": (28, 40),
    },
    # Mountain Breach
    "scaffold_pipe": {
        "prompt": f"{STYLE}, a single length of riveted iron scaffold pipe lying horizontally, "
                  "flanged coupling joint at one end, construction material, worn metal",
        "size": (48, 18),
    },
    # Brackmarsh
    "standing_mirror": {
        "prompt": f"{STYLE}, a tall standing cheval floor mirror in an ornate brass frame on a "
                  "swivel wooden stand with two feet, oval reflective silver glass, antique full length mirror",
        "size": (28, 52),
    },
    "hand_mirror": {
        "prompt": f"{STYLE}, a small ornate antique hand mirror with a long decorative brass "
                  "handle and a round reflective silver glass, vanity mirror",
        "size": (22, 36),
    },
    "reed_skiff": {
        "prompt": f"{STYLE}, a small woven reed skiff canoe made of bundled dried rushes, low "
                  "curved hull with a single wooden paddle across it, marsh boat, side view",
        "size": (54, 26),
    },
    "brass_curtain_rod": {
        "prompt": f"{STYLE}, a long slender horizontal brass curtain rod with decorative round "
                  "finial knobs on both ends, polished metal pole",
        "size": (50, 12),
    },
    # Relay Tower
    "tone_forks": {
        "prompt": f"{STYLE}, a pair of two upright brass tuning forks of different heights mounted "
                  "in a small wooden base block, resonating instruments, gleaming metal",
        "size": (34, 38),
    },
}


def _remove_flat_background(img: Image.Image) -> Image.Image:
    """If the image has no real transparency, knock out a near-uniform background
    sampled from the corners."""
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    opaque_corners = [c for c in corners if c[3] > 200]
    if len(opaque_corners) < 3:
        return img  # already has transparency; trust it
    # Average corner color as the background key.
    kr = sum(c[0] for c in opaque_corners) // len(opaque_corners)
    kg = sum(c[1] for c in opaque_corners) // len(opaque_corners)
    kb = sum(c[2] for c in opaque_corners) // len(opaque_corners)
    tol = 42
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if abs(r - kr) <= tol and abs(g - kg) <= tol and abs(b - kb) <= tol:
                px[x, y] = (r, g, b, 0)
    return img


def _fit_bottom_anchored(img: Image.Image, target: tuple) -> Image.Image:
    """Autocrop to content, scale to fit target box preserving aspect, then
    paste bottom-centered on a transparent target-sized canvas."""
    tw, th = target
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    cw, ch = img.size
    scale = min(tw / cw, th / ch)
    nw, nh = max(1, round(cw * scale)), max(1, round(ch * scale))
    img = img.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    canvas.alpha_composite(img, ((tw - nw) // 2, th - nh))  # bottom-centered
    return canvas


def generate_prop(name: str, config: dict) -> bool:
    output_path = os.path.join(PROPS_DIR, f"{name}.png")
    if os.path.exists(output_path):
        print(f"  SKIP: {name} (already exists)")
        return True

    target = config["size"]
    prompt = config["prompt"] + f", {target[0]}x{target[1]} pixels, game sprite"
    print(f"  Generating: {name} {target}...")
    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(response_modalities=["image", "text"]),
        )
        for part in response.candidates[0].content.parts:
            if part.inline_data:
                img = Image.open(io.BytesIO(part.inline_data.data)).convert("RGBA")
                img = _remove_flat_background(img)
                img = _fit_bottom_anchored(img, target)
                img.save(output_path)
                print(f"  OK: {name} -> {output_path}")
                return True
        print(f"  WARN: {name} - no image in response")
        return False
    except Exception as e:
        print(f"  ERROR: {name} - {e}")
        return False


def main():
    os.makedirs(PROPS_DIR, exist_ok=True)
    names = list(PROPS.keys())
    success, failed = 0, []
    print(f"\nGenerating {len(names)} replacement prop sprites...\n")
    for i, name in enumerate(names):
        if generate_prop(name, PROPS[name]):
            success += 1
        else:
            failed.append(name)
        if i < len(names) - 1:
            time.sleep(RATE_LIMIT_DELAY)
    print(f"\n{'=' * 40}\nDone: {success}/{len(names)} generated")
    if failed:
        print(f"Failed: {', '.join(failed)}")


if __name__ == "__main__":
    main()
