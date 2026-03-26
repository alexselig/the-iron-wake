#!/usr/bin/env python3
"""Generate animation poses for all characters in The Gilded Wake."""

import os
import time
import warnings
warnings.filterwarnings("ignore")

from google import genai
from google.genai import types
from PIL import Image

API_KEY = "REDACTED"
MODEL = "gemini-2.5-flash-image"
OUTPUT_DIR = os.path.expanduser("~/SteampunkBeachDemo/design/character_poses")
RATE_LIMIT_DELAY = 4

client = genai.Client(api_key=API_KEY)

STYLE = "hand-drawn cartoon character concept art, full body standing pose, very big oversized head on a thin lanky body, head is nearly half the character height, long thin limbs and tiny feet, thin ink outlines around all shapes, muted earthy color palette with subtle flat shading, warm beige solid background, droopy expressive facial features, exaggerated bobblehead proportions with skinny body, classic European comic book illustration style, adventure game character design, hand-drawn feel with visible linework, not digital vector style"

# Locked character descriptions — these NEVER change between poses
CHARACTERS = {
    "01_rowan": {
        "name": "Rowan Vale",
        "desc": "mature man in his 30s with short dark brown hair and stubble, strong angular jaw, confident dry expression, wearing a practical dark brown leather longcoat with brass buckles and utility belt, cream shirt underneath, dark trousers tucked into sturdy brown boots, brass medallion necklace visible at collar, leather satchel across body",
    },
    "02_tibbit": {
        "name": "Tibbit Wrench",
        "desc": "eccentric wiry man with wild reddish-brown hair sticking up, large round brass goggles pushed up on forehead, wide enthusiastic grin, olive green vest covered in tool loops over cream rolled-up sleeves, utility belt with gadgets, knee-high brown boots with buckles",
    },
    "03_rook": {
        "name": "Commodore Rook",
        "desc": "tall imposing man with slicked-back dark hair and silver at temples, sharp handsome face with thin confident smile, elegant dark navy longcoat with polished brass buttons and gold details, white cravat, black gloves, ornate walking cane, polished boots",
    },
    "04_marrow": {
        "name": "Marrow Quill",
        "desc": "enigmatic older figure with long grey-streaked dark hair, weathered face with knowing deep-set eyes, long dark olive hooded cloak over simple pale tunic, ancient bracelet on wrist, simple sandals, carries a walking staff with faintly glowing tip",
    },
    "05_pindle": {
        "name": "Dockmaster Pindle",
        "desc": "short fussy middle-aged man with round spectacles on nose, thin mustache, oversized official cap with brass badge, brown uniform coat with too many pockets stuffed with papers, carries an enormous rubber stamp, ink-stained fingers",
    },
    "06_mirelle": {
        "name": "Mirelle Soot",
        "desc": "confident woman with sharp cunning smile, dark skin, elaborate terracotta and cream headwrap with small brass gear decorations, layered scarves in deep red and brown tones, leather apron with trinket-filled pockets, brass monocle on a chain, many bracelets",
    },
    "07_caligo": {
        "name": "Sister Caligo",
        "desc": "practical no-nonsense woman in her 50s with grey hair in tight bun, simple dark grey-green chapel robes with a brass bell pendant, thick rubber boots, sleeves rolled up showing strong forearms, carries a heavy iron lantern",
    },
    "08_bram": {
        "name": "Bram Kett",
        "desc": "gruff stocky man with stubble and tired eyes, leather aviator cap with goggles pushed up, heavy olive-brown flight jacket patched many times, thick scarf around neck, oil-stained hands, sturdy boots with metal toe caps, flask on hip",
    },
    "09_sel": {
        "name": "Archivist Sel",
        "desc": "calm scholarly person with close-cropped silver hair, smooth dark skin, flowing white robes with geometric pale blue embroidery and a golden belt sash, delicate brass spectacles, carries a thin crystal tablet, simple sandals, serene expression",
    },
    "10_ilyan": {
        "name": "Councilor Ilyan",
        "desc": "older man with silver beard neatly trimmed, white and pale blue council robes with golden sash, deep thoughtful eyes, simple circlet on brow, bare feet or simple sandals, dignified but tired posture",
    },
    "11_seraphine": {
        "name": "Warden Seraphine",
        "desc": "tall stern woman with angular features, black hair pulled back severely, white military-style uniform with silver clasps and geometric patterns, armored gauntlets, white cloak pinned at one shoulder, rigid authoritative stance",
    },
}

# Pose variations — only the pose changes, character stays identical
POSES = {
    "idle": "standing still in a neutral relaxed pose, arms at sides, facing slightly to the right, default standing position",
    "talking": "mouth open mid-speech, one hand raised with index finger pointing up as if making a point, animated speaking expression",
    "walk_1": "mid-stride walking to the right, left leg forward right leg back, arms swinging naturally, body leaning slightly forward",
    "walk_2": "mid-stride walking to the right, right leg forward left leg back, opposite arm swing from walk_1, body leaning slightly forward",
    "gesture_point": "standing still, right arm extended pointing to the right at something offscreen, looking in that direction, other hand at side",
    "gesture_shrug": "standing still, both hands raised palms up in a shrug gesture, shoulders raised, eyebrows up with uncertain expression",
    "gesture_arms_crossed": "standing still, both arms crossed over chest, slightly defiant or thoughtful expression, weight on one leg",
    "head_tilt_up": "standing still, head tilted up looking upward at something above, arms at sides, curious or surprised expression",
    "head_tilt_down": "standing still, head tilted down looking at the ground or at something held in hands, contemplative expression",
}


def generate_pose(char_key, char_info, pose_key, pose_desc):
    char_dir = os.path.join(OUTPUT_DIR, char_key)
    os.makedirs(char_dir, exist_ok=True)
    output_path = os.path.join(char_dir, f"{pose_key}.png")

    if os.path.exists(output_path):
        return "skip"

    prompt = f"{STYLE}, {char_info['desc']}, {pose_desc}, the character must look exactly the same as in all other poses with identical clothing hair and features, only the pose and expression changes"

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


if __name__ == "__main__":
    print("=== The Gilded Wake — Character Pose Generation ===")
    print(f"Characters: {len(CHARACTERS)}, Poses: {len(POSES)}")
    print(f"Total images: {len(CHARACTERS) * len(POSES)}\n")

    total = len(CHARACTERS) * len(POSES)
    done = 0
    skipped = 0
    failed = []

    for char_key in sorted(CHARACTERS.keys()):
        char = CHARACTERS[char_key]
        print(f"\n--- {char['name']} ---")

        for pose_key, pose_desc in POSES.items():
            result = generate_pose(char_key, char, pose_key, pose_desc)
            if result == "ok":
                done += 1
                print(f"  [OK] {pose_key}")
            elif result == "skip":
                skipped += 1
                print(f"  [SKIP] {pose_key}")
            else:
                failed.append(f"{char['name']}/{pose_key}: {result}")
                print(f"  [FAIL] {pose_key}: {result}")

    print(f"\n=== Done! {done} generated, {skipped} skipped, {len(failed)} failed out of {total} ===")
    if failed:
        print("Failed:")
        for f in failed:
            print(f"  {f}")
        print("\nRe-run to retry — existing files are skipped.")
