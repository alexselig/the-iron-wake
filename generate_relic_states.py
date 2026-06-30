#!/usr/bin/env python3
"""Generate the 5 story-state frames for the Blackwake Harbor ancient relic.

States (left->right in the puzzle):
  1 dormant  - circular recess packed with WET sand (start)
  2 dried    - recess filled with DRY CRACKED sand (after spyglass)
  3 scraped  - recess CLEAN, geometric groove socket (after stamp)
  4 medallion- bronze medallion seated, FAINT blue hum (after medallion)
  5 active   - fully AWAKENED, blue-white lines blaze (after steam valve)

The dormant frame is generated first and used as a reference image for the
other four so the relic body stays identical between states.
Output -> assets_new/props/relic/<state>.png (transparent), archived raw in
design/relic_states_raw/.
"""
import os, sys, time, warnings
warnings.filterwarnings("ignore")
from PIL import Image
from collections import deque
from google import genai
from google.genai import types

API_KEY = os.environ.get("GEMINI_API_KEY", "")
_env = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
if not API_KEY and os.path.exists(_env):
    for ln in open(_env):
        if ln.startswith("GEMINI_API_KEY="):
            API_KEY = ln.strip().split("=", 1)[1]
if not API_KEY:
    print("ERROR: GEMINI_API_KEY not set"); sys.exit(1)

client = genai.Client(api_key=API_KEY)
MODEL = "gemini-2.5-flash-image"
RAW = os.path.expanduser("~/SteampunkBeachDemo/design/relic_states_raw")
OUT = os.path.expanduser("~/SteampunkBeachDemo/assets_new/props/relic")
os.makedirs(RAW, exist_ok=True); os.makedirs(OUT, exist_ok=True)

STYLE = ("Flat cel-shaded cartoon steampunk style with clean flat color blocks, "
    "crisp dark outlines and subtle shadows, matching a LucasArts-style point-and-click "
    "adventure game prop. Single object centered, filling most of the frame, on a solid "
    "pure chroma-green background color #00FF00. No text, no characters, no extra objects.")

BASE = (f"{STYLE} The object is a large smooth obsidian-black domed ancient machine, "
    "half-buried in a small mound of damp grey-tan beach sand at its base. On its front "
    "face is a round inset circular recess. The relic is DORMANT with no glow. The recess "
    "is packed with dark WET sand and a crust of pale salt. Muted cool palette, heavy and old.")

VARS = {
    "dormant": None,  # the base
    "dried": ("Keep the relic body IDENTICAL to the reference image — same shape, size, "
        "outline, black dome and sand mound. ONLY change the circular front recess: it is now "
        "filled with DRY, PALE, CRACKED sand lit by a warm shaft of sunlight. Still NO energy glow."),
    "scraped": ("Keep the relic body IDENTICAL to the reference image. ONLY change the circular "
        "front recess: it is now CLEAN and EMPTY, revealing a dark hollow socket with concentric "
        "engraved geometric rings and tiny glyphs. No sand, NO energy glow."),
    "medallion": ("Keep the relic body IDENTICAL to the reference image. The circular front recess "
        "now holds a round bronze medallion seated flush in the groove. FAINT thin blue-white "
        "geometric light lines just begin to trace across the black dome. Gentle subtle hum glow only."),
    "active": ("Keep the relic body IDENTICAL to the reference image. The relic is now fully "
        "AWAKENED: brilliant blue-white geometric lines blaze and spiral across the entire black "
        "dome, the central recess radiates bright light, a glowing energy halo surrounds it. "
        "Same relic shape and sand mound, dramatic magical activation."),
}
ORDER = ["dormant", "dried", "scraped", "medallion", "active"]

def gen(contents, out_raw):
    for attempt in range(3):
        try:
            r = client.models.generate_content(model=MODEL, contents=contents,
                config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]))
            for part in r.candidates[0].content.parts:
                if getattr(part, "inline_data", None) and part.inline_data.data:
                    with open(out_raw, "wb") as f:
                        f.write(part.inline_data.data)
                    return True
            print("   no image in response, retrying...")
        except Exception as e:
            print(f"   error: {e}; retry {attempt+1}")
        time.sleep(5)
    return False

def key_out(path_in, path_out, target_w=240):
    """Flood-fill remove the contiguous green background -> transparent, trim, resize."""
    im = Image.open(path_in).convert("RGBA")
    w, h = im.size
    px = im.load()
    # background reference = average of the 4 corners
    corners = [px[0, 0], px[w-1, 0], px[0, h-1], px[w-1, h-1]]
    br = sum(c[0] for c in corners) // 4
    bg = sum(c[1] for c in corners) // 4
    bb = sum(c[2] for c in corners) // 4
    def is_bg(c):
        return (abs(c[0]-br) + abs(c[1]-bg) + abs(c[2]-bb)) < 120 and c[1] > c[0] and c[1] > c[2]
    seen = bytearray(w*h)
    q = deque()
    for x in range(w):
        for y in (0, h-1):
            q.append((x, y))
    for y in range(h):
        for x in (0, w-1):
            q.append((x, y))
    while q:
        x, y = q.pop()
        i = y*w + x
        if seen[i]:
            continue
        seen[i] = 1
        c = px[x, y]
        if not is_bg(c):
            continue
        px[x, y] = (c[0], c[1], c[2], 0)
        if x > 0: q.append((x-1, y))
        if x < w-1: q.append((x+1, y))
        if y > 0: q.append((x, y-1))
        if y < h-1: q.append((x, y+1))
    # soften any residual green fringe on semi-edge pixels
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] != 0 and c[1] > c[0]+60 and c[1] > c[2]+60:
                px[x, y] = (c[0], min(c[0], c[2]), c[2], c[3])
    # trim to content
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    nw, nh = im.size
    scale = target_w / nw
    im = im.resize((target_w, max(1, int(nh*scale))), Image.LANCZOS)
    im.save(path_out)
    return im.size

ref_img = None
for state in ORDER:
    raw = os.path.join(RAW, f"{state}.png")
    out = os.path.join(OUT, f"{state}.png")
    print(f"[{state}] generating...")
    if state == "dormant":
        ok = gen([BASE], raw)
    else:
        ok = gen([ref_img, VARS[state]], raw)
    if not ok:
        print(f"   FAILED {state}"); continue
    sz = key_out(raw, out)
    print(f"   saved {out} {sz}")
    if state == "dormant":
        ref_img = Image.open(raw)  # reference for the rest
    time.sleep(4)
print("RELIC_STATES_DONE")
