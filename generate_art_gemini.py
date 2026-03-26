#!/usr/bin/env python3
"""Generate art assets for The Brass Tide using Google Gemini API."""

import os
import sys
import time
from PIL import Image, ImageOps

# Suppress warnings
import warnings
warnings.filterwarnings("ignore")

from google import genai
from google.genai import types

API_KEY = os.environ.get("GEMINI_API_KEY", "REDACTED")
MODEL = "gemini-2.5-flash-image"  # Free tier with image generation

client = genai.Client(api_key=API_KEY)

ASSETS = os.path.expanduser("~/SteampunkBeachDemo/assets")
RATE_LIMIT_DELAY = 4  # seconds between API calls to avoid rate limits

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def generate_image(prompt, output_path, resize_to=None, aspect_ratio="1:1"):
    """Generate an image with Gemini and save it."""
    if os.path.exists(output_path):
        print(f"  [SKIP] Already exists: {os.path.basename(output_path)}")
        return True

    print(f"  Generating: {os.path.basename(output_path)}...")
    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_modalities=["TEXT", "IMAGE"],
            ),
        )

        for part in response.candidates[0].content.parts:
            if part.inline_data is not None:
                # Save raw image first, then resize with PIL
                raw_path = output_path + ".raw.png"
                part.as_image().save(raw_path)

                # Open with PIL for resize
                pil_img = Image.open(raw_path)
                if resize_to:
                    pil_img = pil_img.resize(resize_to, Image.NEAREST)
                pil_img.save(output_path)

                # Clean up raw
                os.remove(raw_path)

                print(f"  [OK] Saved: {os.path.basename(output_path)} ({pil_img.size[0]}x{pil_img.size[1]})")
                time.sleep(RATE_LIMIT_DELAY)
                return True

        print(f"  [WARN] No image in response for {os.path.basename(output_path)}")
        return False

    except Exception as e:
        print(f"  [ERROR] {e}")
        time.sleep(RATE_LIMIT_DELAY)
        return False

def mirror_image(src_path, dst_path):
    """Mirror an image horizontally for left-facing versions."""
    if os.path.exists(dst_path):
        print(f"  [SKIP] Already exists: {os.path.basename(dst_path)}")
        return
    if not os.path.exists(src_path):
        print(f"  [SKIP] Source missing: {os.path.basename(src_path)}")
        return
    img = Image.open(src_path)
    mirrored = ImageOps.mirror(img)
    mirrored.save(dst_path)
    print(f"  [OK] Mirrored: {os.path.basename(dst_path)}")

# ============================================================
# BACKGROUND
# ============================================================
def generate_background():
    print("\n=== BACKGROUND ===")
    ensure_dir(os.path.join(ASSETS, "backgrounds"))

    prompt = """Create a wide panoramic pixel art scene of a steampunk beach at dusk.
    The art style should be detailed 16-bit pixel art suitable for a point-and-click adventure game.

    Left side: A rickety wooden workbench made from driftwood with a brass lantern hanging from a pole. A tattered canvas tarp overhead.

    Left-center: A large brass capsule half-buried in wet sand where tide meets shore. It's ovoid, waist-height, covered in green patina with gear mechanisms on the front.

    Center: Open wet beach with sand reflecting an amber-copper sunset. Small waves lap at the shore. Footprints in the sand.

    Right-center: A natural rock tide pool with clear water and seaweed-draped rocks.

    Far right: A tangled driftwood pile with mechanical debris. In the background, the tail rudder of a crashed airship juts from rocks, with faded lettering "H.M.S. COGSWORTH".

    Sky: Dramatic amber-copper sunset through heavy clouds. Three distant airship silhouettes with searchlight beams. Columns of steam rising from geothermal vents in the dark teal ocean.

    The color palette is warm amber, deep copper, brass gold, and dark teal. The mood is mysterious and atmospheric."""

    generate_image(
        prompt,
        os.path.join(ASSETS, "backgrounds", "beach_ai.png"),
        resize_to=(640, 360),
        aspect_ratio="16:9"
    )

# ============================================================
# CHARACTER SPRITES
# ============================================================
def generate_character():
    print("\n=== CHARACTER: ELARA ===")
    frames_dir = os.path.join(ASSETS, "characters", "frames")
    ensure_dir(frames_dir)

    style = "chibi cartoon steampunk female character, large round brass goggles pushed up on forehead, dark brown hair in a ponytail, brown leather longcoat with brass buttons and buckles, utility belt with gear buckle and pouches, tall leather boots, warm brown and copper color palette, clean cartoon line art style, white background, full body view, game character sprite"

    # Idle right
    generate_image(
        f"{style}, standing relaxed facing right, arms at sides, confident pose",
        os.path.join(frames_dir, "idle_right_0.png"),
        resize_to=(64, 96)
    )
    generate_image(
        f"{style}, standing facing right, slight weight shift, breathing idle animation frame",
        os.path.join(frames_dir, "idle_right_1.png"),
        resize_to=(64, 96)
    )

    # Walk right (4 frames)
    walk_descs = [
        "walking right, left foot forward, arms swinging, mid-stride",
        "walking right, feet together, passing position, arms at center",
        "walking right, right foot forward, arms swinging opposite, mid-stride",
        "walking right, feet coming together, contact position",
    ]
    for i, desc in enumerate(walk_descs):
        generate_image(
            f"{style}, {desc}",
            os.path.join(frames_dir, f"walk_right_{i}.png"),
            resize_to=(64, 96)
        )

    # Talk right (2 frames)
    generate_image(
        f"{style}, facing right, mouth closed, one hand raised gesturing, talking pose",
        os.path.join(frames_dir, "talk_right_0.png"),
        resize_to=(64, 96)
    )
    generate_image(
        f"{style}, facing right, mouth open speaking, hand gesturing expressively, talking pose",
        os.path.join(frames_dir, "talk_right_1.png"),
        resize_to=(64, 96)
    )

    # Mirror all right-facing to left-facing
    for name in ["idle_right_0", "idle_right_1",
                  "walk_right_0", "walk_right_1", "walk_right_2", "walk_right_3",
                  "talk_right_0", "talk_right_1"]:
        left_name = name.replace("_right_", "_left_")
        mirror_image(
            os.path.join(frames_dir, f"{name}.png"),
            os.path.join(frames_dir, f"{left_name}.png")
        )

# ============================================================
# PROPS
# ============================================================
def generate_props():
    print("\n=== PROPS ===")
    props_dir = os.path.join(ASSETS, "props")
    ensure_dir(props_dir)
    ensure_dir(os.path.join(props_dir, "capsule_frames"))
    ensure_dir(os.path.join(props_dir, "crab_frames"))

    prop_style = "detailed cartoon game prop, steampunk style, warm brown and brass color palette, clean illustration, white background, isolated object"

    # Capsule states
    generate_image(
        f"{prop_style}, large sealed brass capsule half-buried in sand, ovoid shape covered in green patina, three interlocking gears on front with center gear missing, barnacles on bottom, faint phosphorescent glow",
        os.path.join(props_dir, "capsule_frames", "closed.png"),
        resize_to=(96, 72)
    )
    generate_image(
        f"{prop_style}, large brass capsule half-buried in sand, gears mechanism partially turned, small keyhole revealed in center panel, green patina, glowing seams",
        os.path.join(props_dir, "capsule_frames", "keyhole.png"),
        resize_to=(96, 72)
    )
    generate_image(
        f"{prop_style}, large brass capsule opened, top half swung up on hinges, inside reveals dark red velvet lining with metal plates, steam wisps, green patina on exterior",
        os.path.join(props_dir, "capsule_frames", "open.png"),
        resize_to=(96, 72)
    )

    # Individual props
    props = [
        ("magnifying_lens.png", "brass magnifying lens with ornate handle, steampunk style, circular glass lens with brass frame", (32, 32)),
        ("copper_wire.png", "coil of shiny copper wire, spiral coiled, reddish copper color", (32, 24)),
        ("seashell.png", "large pink and cream conch shell, beautiful spiral, natural colors", (32, 32)),
        ("oilskin_pouch.png", "dark leather oilskin pouch sealed with cord, small canvas bag with brass clasp, contains oil", (32, 32)),
        ("broken_gear.png", "large broken brass gear with missing teeth, steampunk mechanical gear, damaged and worn, some teeth snapped off", (36, 36)),
        ("brass_key.png", "small ornate brass key with gear-shaped bow, steampunk skeleton key, intricate design", (24, 32)),
        ("cipher_plates.png", "stack of thin brass metal plates with tiny etched symbols and grid markings, cipher documents, intelligence papers", (48, 36)),
    ]

    for filename, desc, size in props:
        generate_image(
            f"{prop_style}, {desc}",
            os.path.join(props_dir, filename),
            resize_to=size
        )

    # Crab
    generate_image(
        f"{prop_style}, blue crab with raised claws in defensive pose, bright blue shell, aggressive stance, cartoon style",
        os.path.join(props_dir, "crab_frames", "idle.png"),
        resize_to=(36, 28)
    )
    generate_image(
        f"{prop_style}, blue crab retreating sideways, claws lowered, moving away, cartoon style",
        os.path.join(props_dir, "crab_frames", "retreat.png"),
        resize_to=(36, 28)
    )

# ============================================================
# INVENTORY ICONS
# ============================================================
def generate_inventory_icons():
    print("\n=== INVENTORY ICONS ===")
    icons_dir = os.path.join(ASSETS, "inventory_icons")
    ensure_dir(icons_dir)

    icon_style = "game inventory icon, steampunk style, detailed small icon, dark background with brass border frame, centered object"

    icons = [
        ("magnifying_lens.png", "brass magnifying lens icon"),
        ("copper_wire.png", "copper wire coil icon"),
        ("oilskin_pouch.png", "leather oilskin pouch icon"),
        ("broken_gear.png", "broken brass gear icon with missing teeth"),
        ("seashell.png", "pink conch seashell icon"),
        ("brass_key.png", "ornate brass key icon"),
        ("cipher_plates.png", "stack of brass cipher plates icon"),
        ("repaired_gear.png", "brass gear repaired with copper wire icon, wire wound around teeth"),
    ]

    for filename, desc in icons:
        generate_image(
            f"{icon_style}, {desc}",
            os.path.join(icons_dir, filename),
            resize_to=(32, 32)
        )

# ============================================================
# UI ELEMENTS
# ============================================================
def generate_ui():
    print("\n=== UI ELEMENTS ===")
    ui_dir = os.path.join(ASSETS, "ui")
    ensure_dir(ui_dir)

    # Dialogue box frame
    generate_image(
        "steampunk game UI dialog box frame, horizontal rectangular panel, dark brown riveted metal background, ornate brass gear decorations on corners, golden brass border with rivets, empty dark center for text, game user interface element, no text, transparent background",
        os.path.join(ui_dir, "dialogue_frame.png"),
        resize_to=(560, 90)
    )

    # Inventory bar
    generate_image(
        "steampunk game UI horizontal inventory bar, long narrow brass rail with gear mechanisms on both ends, dark riveted metal panel, 8 circular empty slots, game user interface element, no text, transparent background",
        os.path.join(ui_dir, "inventory_bar.png"),
        resize_to=(640, 36)
    )

    # Inventory slot
    generate_image(
        "steampunk circular brass gear frame, small medallion holder, ornate brass border with tiny gears, dark empty center, game UI inventory slot, transparent background, single isolated frame",
        os.path.join(ui_dir, "inventory_slot.png"),
        resize_to=(32, 32)
    )

    # Inventory slot selected (highlighted)
    generate_image(
        "steampunk circular brass gear frame glowing golden, small medallion holder, ornate brass border with tiny gears, bright golden glow effect, game UI selected inventory slot, transparent background",
        os.path.join(ui_dir, "inventory_slot_selected.png"),
        resize_to=(32, 32)
    )

    # Tutorial panel
    generate_image(
        "steampunk game UI large panel, ornate brass notice board, weathered brass frame with gear corners and rivets, dark brown metal center, decorative scrollwork at top, game user interface, no text, transparent background",
        os.path.join(ui_dir, "tutorial_panel.png"),
        resize_to=(400, 200)
    )

    # Hover label plate
    generate_image(
        "steampunk small brass nameplate, narrow horizontal riveted metal plate, tiny gear decorations on sides, dark center, game UI tooltip, transparent background",
        os.path.join(ui_dir, "hover_plate.png"),
        resize_to=(200, 24)
    )

# ============================================================
# MAIN
# ============================================================
if __name__ == "__main__":
    print("=== The Brass Tide — Gemini Art Generator ===")
    print(f"Using model: {MODEL}")
    print(f"Assets directory: {ASSETS}")

    # Create all directories
    for subdir in ["backgrounds", "characters/frames", "props/capsule_frames",
                    "props/crab_frames", "inventory_icons", "ui"]:
        ensure_dir(os.path.join(ASSETS, subdir))

    generate_background()
    generate_character()
    generate_props()
    generate_inventory_icons()
    generate_ui()

    print("\n=== Generation complete! ===")
    print("If any images failed, re-run the script — it skips existing files.")
