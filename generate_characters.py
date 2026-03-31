#!/usr/bin/env python3
"""Generate character concept art for The Gilded Wake using Gemini API."""

import os
import sys
import time
import warnings
warnings.filterwarnings("ignore")

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
OUTPUT_DIR = os.path.expanduser("~/SteampunkBeachDemo/design/characters")
RATE_LIMIT_DELAY = 5

client = genai.Client(api_key=API_KEY)

STYLE_PREFIX = "hand-drawn cartoon character concept art, full body standing pose, very big oversized head on a thin lanky body, head is nearly half the character height, long thin limbs and tiny feet, thin ink outlines around all shapes, muted earthy color palette with subtle flat shading, warm beige solid background, droopy expressive facial features with big tired or characterful eyes, long pointy nose, exaggerated bobblehead proportions with skinny body, classic European comic book illustration style, adventure game character design, hand-drawn feel with visible linework, not digital vector style"

CHARACTERS = {
    "01_rowan_vale": {
        "name": "Rowan Vale (Protagonist)",
        "prompt": f"{STYLE_PREFIX}, mature man in his 30s, dark short hair and stubble, strong jaw, confident relaxed stance, wearing a practical dark brown leather coat over a rust-red sweater, dark trousers, sturdy boots, a brass medallion necklace visible at collar, worn leather satchel across body, hands in pockets, sharp observant expression with a dry half-smile, resourceful and slightly guarded demeanor"
    },
    "02_tibbit_wrench": {
        "name": "Tibbit Wrench (Inventor Companion)",
        "prompt": f"{STYLE_PREFIX}, eccentric wiry man with wild reddish-brown hair, large round brass goggles pushed up on forehead, olive green vest covered in tool loops over cream rolled-up sleeves, utility belt with gadgets, knee-high brown boots with buckles, wide enthusiastic grin, holding a bizarre brass contraption in one hand, slightly manic posture leaning forward"
    },
    "03_commodore_rook": {
        "name": "Commodore Silas Rook (Antagonist)",
        "prompt": f"{STYLE_PREFIX}, tall imposing man, slicked-back dark hair with silver at temples, sharp handsome face with thin confident smile, elegant dark navy longcoat with polished brass buttons and gold details, white cravat, black gloves, ornate walking cane, polished boots, every detail immaculate, standing tall and still, radiates controlled wealth and menace"
    },
    "04_marrow_quill": {
        "name": "Marrow Quill (Mysterious Guide)",
        "prompt": f"{STYLE_PREFIX}, enigmatic older figure, long grey-streaked dark hair, weathered face with knowing deep-set eyes, long dark olive hooded cloak over simple pale tunic, ancient bracelet on wrist, simple sandals, carries a walking staff with faintly glowing tip, melancholy but alert expression, stands slightly apart as if observing"
    },
    "05_dockmaster_pindle": {
        "name": "Dockmaster Pindle (Absurd Bureaucrat)",
        "prompt": f"{STYLE_PREFIX}, short fussy middle-aged man, round spectacles on nose, thin mustache, oversized official cap with brass badge, brown uniform coat with too many pockets stuffed with papers, carries an enormous rubber stamp in one hand and a clipboard in the other, ink-stained fingers, expression of perpetual bureaucratic offense, comically self-important stance"
    },
    "06_mirelle_soot": {
        "name": "Mirelle Soot (Junk Market Dealer)",
        "prompt": f"{STYLE_PREFIX}, confident woman with sharp cunning smile, dark skin, elaborate terracotta and cream headwrap with small brass gear decorations, layered scarves in deep red and brown tones, leather apron with trinket-filled pockets, brass monocle on a chain, many bracelets, coin-buckle boots, arms crossed, looks like she could sell you your own shoes"
    },
    "07_sister_caligo": {
        "name": "Sister Caligo (Marsh Chapel Caretaker)",
        "prompt": f"{STYLE_PREFIX}, practical no-nonsense woman in her 50s, grey hair in tight bun, simple dark grey-green chapel robes with a brass bell pendant, thick rubber boots, sleeves rolled up showing strong forearms, carries a heavy iron lantern, sardonic half-smile, mud-spattered hem, expression of someone done being surprised"
    },
    "08_bram_kett": {
        "name": "Bram Kett (Disgraced Airship Pilot)",
        "prompt": f"{STYLE_PREFIX}, gruff stocky man with stubble and tired eyes, leather aviator cap with goggles pushed up, heavy olive-brown flight jacket patched many times, thick scarf around neck, oil-stained hands, sturdy boots with metal toe caps, flask on hip, arms crossed, deeply skeptical expression, someone once great now aggressively mediocre by choice"
    },
    "09_archivist_sel": {
        "name": "Archivist Sel (Island Scholar)",
        "prompt": f"{STYLE_PREFIX}, calm elegant person with close-cropped silver hair, dark skin, flowing white robes with geometric pale blue embroidery, delicate brass spectacles, carries a thin crystal tablet, simple white sandals, standing very still, quiet intelligence and compassion, impossibly clean clothing, represents refined island civilization"
    },
    "10_councilor_ilyan": {
        "name": "Councilor Ilyan (Island Reopening Faction)",
        "prompt": f"{STYLE_PREFIX}, older man with weariness showing, silver beard neatly trimmed, white and pale blue council robes with golden sash, deep thoughtful eyes, hands clasped behind back, simple circlet on brow, dignified but tired posture, someone who has argued for decades and is running out of patience"
    },
    "11_warden_seraphine": {
        "name": "Warden Seraphine (Island Preservation Faction)",
        "prompt": f"{STYLE_PREFIX}, tall stern woman with angular features, black hair pulled back severely, white military-style uniform with silver clasps and geometric patterns, armored gauntlets, white cloak pinned at one shoulder, standing at rigid attention, disciplined wariness, carries no visible weapon but radiates authority"
    },
}

def generate_character(key, info):
    output_path = os.path.join(OUTPUT_DIR, f"{key}.png")
    if os.path.exists(output_path):
        print(f"  [SKIP] {info['name']} — already exists")
        return True

    print(f"  Generating: {info['name']}...")
    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=info["prompt"],
            config=types.GenerateContentConfig(
                response_modalities=["TEXT", "IMAGE"],
            ),
        )
        for part in response.candidates[0].content.parts:
            if part.inline_data is not None:
                raw_path = output_path + ".raw.png"
                part.as_image().save(raw_path)
                img = Image.open(raw_path)
                # Resize to consistent size for review
                img = img.resize((512, 768), Image.LANCZOS)
                img.save(output_path)
                os.remove(raw_path)
                print(f"  [OK] {info['name']}")
                time.sleep(RATE_LIMIT_DELAY)
                return True

        print(f"  [WARN] No image returned for {info['name']}")
        time.sleep(RATE_LIMIT_DELAY)
        return False

    except Exception as e:
        print(f"  [ERROR] {info['name']}: {e}")
        time.sleep(RATE_LIMIT_DELAY)
        return False

if __name__ == "__main__":
    print("=== The Gilded Wake — Character Generation ===\n")
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for key in sorted(CHARACTERS.keys()):
        generate_character(key, CHARACTERS[key])

    print("\n=== Done! ===")
    print(f"Characters saved to: {OUTPUT_DIR}")
    print("Open them with: open ~/SteampunkBeachDemo/design/characters/")
