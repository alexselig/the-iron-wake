#!/usr/bin/env python3
"""Generate an AI crowd image (Google Gemini) to replace the programmatic
vector crowd prop in the Blackwake Harbor beach scene (Act 1, Room 1).

Matches the game's hand-drawn editorial steampunk illustration style, keys
out the background for transparency, crops, and fits the result to the same
dimensions as the existing crowd.png so it drops straight into scene_builder.

Usage:
  python3 generate_crowd_image.py             # generate candidates -> design/crowd_candidates/
  python3 generate_crowd_image.py --install N # install candidate N as assets/props/crowd.png
"""

import os
import sys
import time
import warnings

warnings.filterwarnings("ignore")

import numpy as np
from PIL import Image

from google import genai
from google.genai import types

HERE = os.path.dirname(os.path.abspath(__file__))

# ---- API key (never hardcode; load from env or .env) ----
API_KEY = os.environ.get("GEMINI_API_KEY", "")
if not API_KEY:
    _env = os.path.join(HERE, ".env")
    if os.path.exists(_env):
        for _line in open(_env):
            if _line.startswith("GEMINI_API_KEY="):
                API_KEY = _line.strip().split("=", 1)[1]
if not API_KEY:
    print("ERROR: Set GEMINI_API_KEY in .env or environment. Never hardcode it.")
    sys.exit(1)

MODEL = "gemini-2.5-flash-image"
client = genai.Client(api_key=API_KEY)

PROPS = os.path.join(HERE, "assets", "props")
PREVIEW = os.path.join(HERE, "design", "crowd_candidates")
BEACH_BG = os.path.join(HERE, "assets", "backgrounds", "act1_01_blackwake_harbor.png")
TARGET = (200, 90)        # huddled 2-row group is more square than the old wide strip
CROWD_POS = (190, 270)    # sprite center in scene_builder (for the context preview)
BG_TOLERANCE = 45
ENCLOSED_WHITE_TOL = 22    # remove flat near-white pockets trapped between figures
N_CANDIDATES = 3

PROMPT = (
    "A tight, huddled group of exactly five steampunk Victorian townsfolk standing close "
    "together in animated conversation with one another, clustered in two loose rows so "
    "the group reads as a dense huddle rather than a straight line. They are turned toward "
    "each other, chatting and gossiping: some seen from the side or three-quarter-back, "
    "heads tilted together, mouths open mid-sentence, gesturing with their hands and "
    "leaning in to listen to each other. "
    "Drawn as cartoon character sprites in the SAME style as a hand-painted "
    "point-and-click adventure game cast: slightly oversized heads, thin lanky bodies, "
    "expressive caricatured faces, soft cel shading with clean smooth outlines. "
    "They wear brown and olive longcoats, waistcoats, a top hat, a bowler hat, a flat "
    "cap, and brass goggles, in a warm muted earthy palette of browns, tans, copper and "
    "olive green. Full bodies visible, overlapping naturally as a chatting group. "
    "Isolated on a plain flat solid white background, with no ground, no shadow and no "
    "scenery. Centered composition, the whole group not touching the edges."
)


def generate_raw(path):
    """Call Gemini and save the first returned image to path."""
    resp = client.models.generate_content(
        model=MODEL,
        contents=PROMPT,
        config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
    )
    for part in resp.candidates[0].content.parts:
        if part.inline_data is not None:
            part.as_image().save(path)
            return True
    return False


def key_out_bg(img):
    """Flood-fill from the border to make the solid background transparent."""
    img = img.convert("RGBA")
    data = np.array(img)
    corners = [data[5, 5, :3], data[5, -5, :3], data[-5, 5, :3], data[-5, -5, :3]]
    bg = np.mean(corners, axis=0).astype(int)

    h, w = data.shape[:2]
    visited = np.zeros((h, w), dtype=bool)
    stack = []
    for x in range(w):
        stack.append((0, x))
        stack.append((h - 1, x))
    for y in range(h):
        stack.append((y, 0))
        stack.append((y, w - 1))

    while stack:
        y, x = stack.pop()
        if not (0 <= y < h and 0 <= x < w) or visited[y, x]:
            continue
        visited[y, x] = True
        if np.max(np.abs(data[y, x, :3].astype(int) - bg)) < BG_TOLERANCE:
            data[y, x, 3] = 0
            for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                ny, nx = y + dy, x + dx
                if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                    stack.append((ny, nx))

    # Remove enclosed background pockets (flat near-white trapped between the
    # huddled figures) that the border flood fill can't reach. The figures'
    # off-white shirts/collars sit well outside this tight tolerance, so they
    # are preserved.
    rgb = data[:, :, :3].astype(int)
    enclosed = np.abs(rgb - bg).max(axis=2) < ENCLOSED_WHITE_TOL
    data[enclosed, 3] = 0

    return Image.fromarray(data)


def crop_content(img, pad=2):
    bbox = img.getbbox()
    if not bbox:
        return img
    l, t, r, b = bbox
    return img.crop((max(0, l - pad), max(0, t - pad),
                     min(img.width, r + pad), min(img.height, b + pad)))


def fit_canvas(img, size):
    """Scale to fit within size (preserve aspect), center horizontally,
    bottom-align, on a transparent canvas of exactly `size`."""
    tw, th = size
    ratio = min(tw / img.width, th / img.height)
    nw, nh = max(1, int(img.width * ratio)), max(1, int(img.height * ratio))
    img = img.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.paste(img, ((tw - nw) // 2, th - nh), img)
    return canvas


def process(raw_path, out_path):
    img = Image.open(raw_path)
    img = key_out_bg(img)
    img = crop_content(img)
    img = fit_canvas(img, TARGET)
    img.save(out_path)
    return img


def context_preview(crowd_img, out_path):
    """Composite the cutout over the beach background where the prop sits."""
    if not os.path.exists(BEACH_BG):
        return
    bg = Image.open(BEACH_BG).convert("RGBA")
    cx, cy = CROWD_POS
    x = cx - crowd_img.width // 2
    y = cy - crowd_img.height // 2
    bg.alpha_composite(crowd_img, (x, y))
    bg.save(out_path)


def main():
    os.makedirs(PREVIEW, exist_ok=True)
    print(f"Generating {N_CANDIDATES} crowd candidates with {MODEL}...")
    for i in range(1, N_CANDIDATES + 1):
        raw = os.path.join(PREVIEW, f"raw_{i}.png")
        out = os.path.join(PREVIEW, f"crowd_candidate_{i}.png")
        ctx = os.path.join(PREVIEW, f"context_{i}.png")
        print(f"[{i}/{N_CANDIDATES}] generating...")
        try:
            if generate_raw(raw):
                img = process(raw, out)
                context_preview(img, ctx)
                print(f"  [OK] {os.path.basename(out)}  +  {os.path.basename(ctx)}")
            else:
                print("  [WARN] no image in response")
        except Exception as e:
            print(f"  [ERROR] {e}")
        time.sleep(4)
    print(f"\nDone. Review candidates in: {PREVIEW}")
    print("Install your pick with:  python3 generate_crowd_image.py --install N")


def install(n):
    src = os.path.join(PREVIEW, f"crowd_candidate_{n}.png")
    if not os.path.exists(src):
        print(f"ERROR: candidate not found: {src}")
        sys.exit(1)
    # Archive the ORIGINAL vector crowd once (convention: never delete art
    # iterations). On later re-installs the archive already exists, so we just
    # overwrite crowd.png and leave the original archive untouched.
    archive = os.path.join(HERE, "design", "crowd_archive_vector")
    if not os.path.exists(os.path.join(archive, "crowd.png")):
        os.makedirs(archive, exist_ok=True)
        for f in ["crowd.png", "crowd.svg", "crowd.png.import", "crowd.svg.import"]:
            p = os.path.join(PROPS, f)
            if os.path.exists(p):
                os.replace(p, os.path.join(archive, f))
    # Install the chosen candidate. The .import was archived on first install, so
    # the game's _load_texture() fallback loads the fresh PNG immediately (Godot
    # regenerates the import next time the editor is opened).
    Image.open(src).save(os.path.join(PROPS, "crowd.png"))
    print(f"Installed candidate {n} -> assets/props/crowd.png")


if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "--install":
        install(int(sys.argv[2]))
    elif len(sys.argv) >= 2 and sys.argv[1] == "--reprocess":
        # Re-key existing raw generations with the current pipeline (no API calls).
        for i in range(1, N_CANDIDATES + 1):
            raw = os.path.join(PREVIEW, f"raw_{i}.png")
            if os.path.exists(raw):
                img = process(raw, os.path.join(PREVIEW, f"crowd_candidate_{i}.png"))
                context_preview(img, os.path.join(PREVIEW, f"context_{i}.png"))
                print(f"reprocessed candidate {i}")
    else:
        main()
