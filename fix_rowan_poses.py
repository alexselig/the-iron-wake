#!/usr/bin/env python3
"""Regenerate Rowan's poses using idle.png as reference for consistency."""

import os
import time
import shutil
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
POSE_DIR = os.path.expanduser("~/SteampunkBeachDemo/design/character_poses/01_rowan")
FRAMES_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/characters/frames")
RATE_LIMIT_DELAY = 6

client = genai.Client(api_key=API_KEY)

STYLE = "hand-drawn cartoon character concept art, full body standing pose, very big oversized head on a thin lanky body, head is nearly half the character height, long thin limbs and tiny feet, thin ink outlines around all shapes, muted earthy color palette with subtle flat shading, warm beige solid background, droopy expressive facial features, exaggerated bobblehead proportions with skinny body, classic European comic book illustration style, adventure game character design, hand-drawn feel with visible linework"

ROWAN_DESC = "mature man in his 30s with short dark brown hair and stubble, strong angular jaw, confident dry expression, wearing a practical dark brown leather longcoat with brass buckles and utility belt, cream shirt underneath, dark trousers tucked into sturdy brown boots, brass medallion necklace visible at collar, leather satchel across body"

# Poses to regenerate (idle stays as-is since it's our reference)
POSES_TO_FIX = {
    "talking": "same character in EXACTLY the same outfit, now with mouth open mid-speech, slight head tilt, one hand slightly raised as if making a point, same stance otherwise",
    "walk_1": "same character in EXACTLY the same outfit, now mid-stride walking to the right, left leg forward, arms swinging naturally, same face and expression, slight lean forward",
    "walk_2": "same character in EXACTLY the same outfit, now mid-stride walking to the right, right leg forward, opposite arm swing, same face and expression, slight lean forward",
}


def generate_pose_with_reference(ref_image_path, pose_key, pose_desc):
    """Generate a new pose using the idle image as reference."""
    output_path = os.path.join(POSE_DIR, f"{pose_key}.png")

    # Archive the old one
    old_path = os.path.join(POSE_DIR, f"{pose_key}_old2.png")
    if os.path.exists(output_path) and not os.path.exists(old_path):
        shutil.copy2(output_path, old_path)
        print(f"  Archived old {pose_key}")

    # Load reference image
    ref_img = Image.open(ref_image_path)

    prompt = (
        f"Here is a reference image of a cartoon character. "
        f"Generate a NEW image of this EXACT SAME character — same face, same hair, same outfit, same colors, same proportions, same art style — "
        f"but in a different pose: {pose_desc}. "
        f"The character MUST look identical to the reference — same dark brown leather longcoat, same cream shirt, same belt, same boots, same hair. "
        f"ONLY the body pose and limb positions should change. Keep the warm beige background. Full body visible."
    )

    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=[ref_img, prompt],
            config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
        )
        for part in response.candidates[0].content.parts:
            if part.inline_data is not None:
                raw_path = output_path + ".raw.png"
                part.as_image().save(raw_path)
                img = Image.open(raw_path).resize((512, 768), Image.LANCZOS)
                img.save(output_path)
                os.remove(raw_path)
                time.sleep(RATE_LIMIT_DELAY)
                return "ok"

        time.sleep(RATE_LIMIT_DELAY)
        return "no_image"

    except Exception as e:
        time.sleep(RATE_LIMIT_DELAY)
        return f"error: {e}"


def process_sprites():
    """Process the new poses into game sprites."""
    import subprocess
    print("\nProcessing into game sprites...")
    # Run the existing processor for just Rowan
    subprocess.run(["python3", os.path.expanduser("~/SteampunkBeachDemo/process_characters.py")],
                   capture_output=True)
    print("Done processing sprites.")


if __name__ == "__main__":
    ref_path = os.path.join(POSE_DIR, "idle.png")
    if not os.path.exists(ref_path):
        print("ERROR: No idle.png reference found!")
        exit(1)

    print("=== Fixing Rowan's Poses (using idle.png as reference) ===\n")
    print(f"Reference: {ref_path}")

    for pose_key, pose_desc in POSES_TO_FIX.items():
        print(f"\nGenerating {pose_key}...")
        result = generate_pose_with_reference(ref_path, pose_key, pose_desc)
        print(f"  Result: {result}")
        if result != "ok":
            print(f"  Retrying {pose_key}...")
            time.sleep(RATE_LIMIT_DELAY)
            result = generate_pose_with_reference(ref_path, pose_key, pose_desc)
            print(f"  Retry result: {result}")

    # Process into game sprites
    process_sprites()

    print("\n=== Done! Check the new poses and restart Godot. ===")
