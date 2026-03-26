#!/usr/bin/env python3
"""Fix specific character poses that don't match their target look."""

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

STYLE = "hand-drawn cartoon character concept art, full body standing pose, very big oversized head on a thin lanky body, head is nearly half the character height, long thin limbs and tiny feet, thin ink outlines around all shapes, muted earthy color palette with subtle flat shading, warm beige solid background, exaggerated bobblehead proportions with skinny body, classic European comic book illustration style, adventure game character design, hand-drawn feel with visible linework, not digital vector style"

POSES = {
    "idle": "standing still in a neutral relaxed pose, arms at sides, facing slightly to the right, default standing position",
    "talking": "mouth open mid-speech, one hand raised with index finger pointing up as if making a point, animated speaking expression",
    "walk_1": "mid-stride walking to the right, left leg forward right leg back, arms swinging naturally, body leaning slightly forward",
    "walk_2": "mid-stride walking to the right, right leg forward left leg back, opposite arm swing, body leaning slightly forward",
    "gesture_point": "standing still, right arm extended pointing to the right at something offscreen, looking in that direction",
    "gesture_shrug": "standing still, both hands raised palms up in a shrug gesture, shoulders raised, eyebrows up with uncertain expression",
    "gesture_arms_crossed": "standing still, both arms crossed over chest, slightly defiant or thoughtful expression, weight on one leg",
    "head_tilt_up": "standing still, head tilted up looking upward at something above, arms at sides, curious or surprised expression",
    "head_tilt_down": "standing still, head tilted down looking at the ground, contemplative expression",
}

# === FIXES NEEDED ===
# Each entry: (character_folder, head_description, poses_to_fix)
# Head descriptions are HYPER-SPECIFIC to match their target image exactly

FIXES = {
    "02_tibbit": {
        "head": "wild spiky reddish-brown hair sticking out in all directions, long angular face with prominent pointed chin, big wide enthusiastic grin showing teeth, large round brass goggles pushed up on forehead sitting on top of the messy hair, thin long nose, wide-set eyes, scruffy and energetic looking",
        "body": "olive green vest covered in tool loops and pockets over cream rolled-up sleeves, utility belt with gadgets hanging from it, knee-high brown boots with buckles, very thin lanky arms and legs",
        "poses": ["walk_2", "gesture_shrug", "head_tilt_up"],
    },
    "04_marrow": {
        "head": "very large oversized head with long grey-streaked dark hair hanging down past shoulders, deep hood from dark olive cloak framing the face, gaunt weathered face with deep-set sad knowing eyes, long hooked nose, thin mouth, ancient looking bracelet on wrist",
        "body": "long dark olive hooded cloak draped over simple pale cream tunic, thin lanky body underneath, simple sandals or bare feet, carries a walking staff with faintly glowing tip in one hand",
        "poses": ["walk_2"],
    },
    "05_pindle": {
        "head": "short grey hair visible under a large oversized dark olive military-style official cap with a brass badge on the front, round wire-rimmed spectacles on a bulbous nose, thin neat mustache, jowly fussy face with disapproving pursed expression, double chin, the cap is distinctly large and official-looking",
        "body": "brown official uniform coat with many pockets all stuffed with papers and documents sticking out, dark tie, holding an enormous wooden rubber stamp in one hand and a clipboard with papers in the other, ink-stained fingers, short stocky proportions relative to the big head, dark shoes",
        "poses": list(POSES.keys()),  # ALL poses
    },
    "06_mirelle": {
        "head": "dark brown skin, elaborate tall terracotta and cream striped headwrap with small brass gear decorations and a central ornament, sharp cunning face with a confident wide grin, one brass monocle on left eye attached to a chain, gold hoop earring, arched expressive eyebrows, angular jaw, beauty mark",
        "body": "layered red and brown scarves around neck, leather apron with pockets full of trinkets over brown clothing, many jingling bracelets on both wrists, thin lanky body, bare feet or simple sandals",
        "poses": ["idle", "walk_1", "walk_2", "gesture_point", "gesture_shrug", "gesture_arms_crossed", "head_tilt_up", "head_tilt_down"],
    },
    "07_caligo": {
        "head": "grey hair pulled up in a tight bun on top of head, long angular face with prominent cheekbones and a strong jaw, sardonic half-smile, slightly hooded skeptical eyes, wrinkles around eyes and mouth, no-nonsense expression, brass bell pendant visible at collar",
        "body": "simple dark grey-green chapel robes belted at waist, sleeves rolled up showing strong forearms, thick rubber boots, carries a heavy iron lantern in one hand, thin lanky body",
        "poses": ["talking", "walk_1", "walk_2", "gesture_point", "gesture_shrug", "head_tilt_up", "head_tilt_down"],
    },
    "10_ilyan": {
        "head": "bald on top with thin wispy grey-white hair on the sides, small golden circlet or cap on crown of head, long neat silver-grey beard, long droopy face with heavy sad eyes and deep wrinkles, large nose, tired dignified expression, light blue scarf or shawl wrapped around neck",
        "body": "flowing white robes with a golden belt sash at waist, simple and elegant, thin lanky body underneath, bare feet or simple sandals, hands often clasped or at sides",
        "poses": ["idle", "talking", "walk_1", "walk_2", "gesture_shrug", "gesture_arms_crossed", "head_tilt_up", "head_tilt_down"],
    },
    "08_bram": {
        "head": "leather aviator cap with large brass goggles pushed up on top, gruff square face with heavy stubble and tired droopy eyes, thick bulbous nose, frowning mouth, thick cream-colored scarf wrapped high around neck and chin, ear flaps from aviator cap hanging down",
        "body": "heavy olive-brown padded flight jacket patched many times with different leather, the jacket looks worn and bulky, thin lanky legs in contrast to bulky upper body, sturdy boots with metal toe caps, flask on hip",
        "poses": ["idle", "talking", "walk_1", "walk_2", "gesture_point", "gesture_shrug", "head_tilt_up", "head_tilt_down"],
    },
    "11_seraphine": {
        "head": "black hair pulled back very tightly into a high bun, angular stern face with sharp cheekbones and narrow piercing eyes, thin lips set in a firm disapproving line, pale skin, long thin neck, silver clasp or brooch at collar",
        "body": "white military-style uniform tunic with geometric silver patterns and clasps down the front, white half-cape or cloak pinned at one shoulder, armored gauntlets on forearms, dark leggings, the uniform is crisp and authoritarian, thin lanky body with rigid upright posture",
        "poses": ["idle", "talking", "walk_1", "walk_2", "gesture_point", "gesture_shrug", "head_tilt_up", "head_tilt_down"],
    },
}


def generate_fix(char_key, head_desc, body_desc, pose_key, pose_desc):
    char_dir = os.path.join(OUTPUT_DIR, char_key)
    output_path = os.path.join(char_dir, f"{pose_key}.png")

    # Archive old version
    old_path = os.path.join(char_dir, f"{pose_key}_old.png")
    if os.path.exists(output_path) and not os.path.exists(old_path):
        os.rename(output_path, old_path)
    elif os.path.exists(output_path):
        os.remove(output_path)

    prompt = f"{STYLE}, character has {head_desc}, wearing {body_desc}, pose: {pose_desc}, the head and face must remain exactly consistent across all poses with identical features hair and accessories, only the body pose changes"

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
    total_fixes = sum(len(f["poses"]) for f in FIXES.values())
    print(f"=== Fixing {total_fixes} poses across {len(FIXES)} characters ===\n")

    done = 0
    failed = []

    for char_key, fix_info in sorted(FIXES.items()):
        char_name = char_key.split("_", 1)[1]
        print(f"\n--- {char_name} ({len(fix_info['poses'])} poses) ---")

        for pose_key in fix_info["poses"]:
            pose_desc = POSES[pose_key]
            result = generate_fix(char_key, fix_info["head"], fix_info["body"], pose_key, pose_desc)
            if result == "ok":
                done += 1
                print(f"  [OK] {pose_key}")
            else:
                failed.append(f"{char_name}/{pose_key}: {result}")
                print(f"  [FAIL] {pose_key}: {result}")

    print(f"\n=== Done! {done}/{total_fixes} fixed, {len(failed)} failed ===")
    if failed:
        print("Failed:")
        for f in failed:
            print(f"  {f}")
        print("\nRe-run to retry.")
