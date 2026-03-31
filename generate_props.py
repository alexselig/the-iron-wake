#!/usr/bin/env python3
"""Generate all missing room-specific prop sprites for Act 1 using Gemini API."""

import os
import time
import warnings
warnings.filterwarnings("ignore")

from google import genai
from google.genai import types
from PIL import Image
import io

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
PROPS_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/props")
RATE_LIMIT_DELAY = 5

client = genai.Client(api_key=API_KEY)

STYLE = "tiny pixel art sprite on transparent background, steampunk adventure game prop, flat color areas with brass and copper tones, clean silhouette, no text, no labels, game asset icon style, warm muted palette"

# All missing Act 1 props with target sizes
PROPS = {
    # === ROOM 1: Blackwake Harbor ===
    "ancient_relic": {
        "prompt": f"{STYLE}, a large smooth ovoid alien capsule half-buried in sand, dark metallic surface with faint glowing blue-white geometric line patterns, barnacles and patina on the bottom half, brass gears visible on the front panel, mysterious ancient technology",
        "size": (96, 72),
    },
    "steam_valve": {
        "prompt": f"{STYLE}, a brass steam valve wheel mounted on a rusty pipe, round handwheel with spokes, small wisps of steam escaping from joints, industrial steampunk machinery, bolted to a wall",
        "size": (36, 36),
    },
    "warning_placard": {
        "prompt": f"{STYLE}, a small metal warning sign on a post, tarnished brass plate with etched text and an official seal, slightly bent and weathered, official harbor warning notice",
        "size": (40, 32),
    },

    # === ROOM 2: Customs Shack ===
    "permit_ledger": {
        "prompt": f"{STYLE}, a thick leather-bound ledger book open on a desk, filled pages with handwritten entries and official stamps, ink stains on pages, brass corner protectors, bureaucratic record book",
        "size": (48, 36),
    },
    "ink_pad": {
        "prompt": f"{STYLE}, a small brass ink pad box with black ink surface visible, next to a wooden rubber stamp, desk accessory, official document stamping tool",
        "size": (32, 24),
    },
    "seal_press": {
        "prompt": f"{STYLE}, an ornate brass wax seal press on a desk, heavy mechanical lever press with engraved crest on the stamp face, official document sealing device, steampunk office tool",
        "size": (36, 40),
    },
    "blank_forms_prop": {
        "prompt": f"{STYLE}, a neat stack of blank paper forms on a shelf, official government documents with printed lines and header, three copies clipped together, bureaucratic paperwork",
        "size": (36, 28),
    },

    # === ROOM 3: Salvage Warehouse ===
    "automaton_hand": {
        "prompt": f"{STYLE}, a detached mechanical hand made of brass and copper, articulated finger joints with tiny gears visible, sitting on a shelf, steampunk robot part, ancient technology",
        "size": (40, 36),
    },
    "black_shard": {
        "prompt": f"{STYLE}, a sharp angular shard of polished black obsidian-like material with faint glowing blue veins, alien technology fragment, sitting on a cloth on a table, mysterious artifact",
        "size": (32, 32),
    },
    "symbol_archive_board": {
        "prompt": f"{STYLE}, a large cork board covered in pinned papers and sketches of ancient symbols, connected by red string, research board, investigation wall with mysterious glyphs",
        "size": (64, 48),
    },
    "chain_hoist": {
        "prompt": f"{STYLE}, an industrial chain hoist hanging from a ceiling beam, heavy brass pulley with iron chain, warehouse lifting equipment, steampunk industrial tool",
        "size": (32, 64),
    },
    "lighthouse_crate": {
        "prompt": f"{STYLE}, a wooden shipping crate with stenciled text LIGHTHOUSE TRANSFER on the side, nailed shut, rope handles, warehouse cargo",
        "size": (48, 40),
    },

    # === ROOM 4: Brass Bazaar ===
    "mechanical_parrot": {
        "prompt": f"{STYLE}, a small mechanical parrot made of brass and copper perched on a wooden stand, articulated wings with tiny gears, glass eyes, steampunk automaton bird, market curiosity",
        "size": (36, 44),
    },
    "copper_masks": {
        "prompt": f"{STYLE}, three ornate copper face masks hanging from hooks, theatrical comedy tragedy masks in steampunk style with gear decorations, market display",
        "size": (48, 40),
    },
    "fake_springs_box": {
        "prompt": f"{STYLE}, an open wooden box full of loose brass springs and coils, some spilling over the side, junk market merchandise, steampunk parts",
        "size": (36, 32),
    },

    # === ROOM 5: Tibbit's Workshop ===
    "workbench": {
        "prompt": f"{STYLE}, a cluttered inventor's workbench surface with scattered tools, brass gears, magnifying glass on an arm, small vise, soldering iron, blueprints underneath, steampunk workshop",
        "size": (80, 48),
    },
    "lens_frame": {
        "prompt": f"{STYLE}, an empty brass lens frame, circular mount with adjustment screws and a mounting bracket, unfinished optical instrument part, workshop piece",
        "size": (32, 32),
    },
    "burner_pot": {
        "prompt": f"{STYLE}, a small brass camping burner with a bubbling pot on top, blue flame underneath, steam rising, labeled DO NOT TASTE, workshop cooking setup",
        "size": (32, 40),
    },

    # === ROOM 6: Harbor Cliffs ===
    "boundary_stone": {
        "prompt": f"{STYLE}, an ancient weathered stone marker with carved geometric symbols glowing faintly blue, mossy base, standing upright in wild grass, mysterious ancient waymarker",
        "size": (32, 48),
    },

    # === ROOM 7: Lighthouse Exterior ===
    "door_mechanism": {
        "prompt": f"{STYLE}, an ancient circular brass mechanism embedded in a stone door, concentric rings with symbol slots, keyhole in center, lighthouse door lock, mysterious puzzle device",
        "size": (48, 48),
    },
    "beacon_crank": {
        "prompt": f"{STYLE}, a large iron crank wheel mounted on a wall, chain drive mechanism, rusty but functional, lighthouse beacon winding mechanism, industrial steampunk",
        "size": (40, 40),
    },

    # === ROOM 8: Lighthouse Chamber ===
    "lens_pedestal": {
        "prompt": f"{STYLE}, a brass pedestal in the center of a room with an empty circular mount on top for a lens, adjustment dials and brass rails, lighthouse lens assembly base",
        "size": (48, 56),
    },
    "beacon_controls": {
        "prompt": f"{STYLE}, a panel of brass wheels, levers, and dials mounted on a wall, steampunk control panel for a lighthouse beacon, labels with nautical terms, industrial controls",
        "size": (64, 48),
    },
    "wall_mural": {
        "prompt": f"{STYLE}, a faded wall painting showing ships sailing toward a radiant island beneath a star symbol, ancient map mural with compass roses and sea creatures, mysterious and beautiful fresco",
        "size": (80, 48),
    },
    "chart_table": {
        "prompt": f"{STYLE}, a navigation chart table with old maps spread out, brass dividers and rulers, pinned notes, nautical charts with marked routes, lighthouse navigation station",
        "size": (56, 40),
    },
    "window_shutters": {
        "prompt": f"{STYLE}, a pair of heavy wooden window shutters with brass hinges and a latch, half-open revealing light streaming in, lighthouse window",
        "size": (40, 48),
    },
}


def generate_prop(name: str, config: dict) -> bool:
    """Generate a single prop sprite using Gemini."""
    output_path = os.path.join(PROPS_DIR, f"{name}.png")
    if os.path.exists(output_path):
        print(f"  SKIP: {name} (already exists)")
        return True

    target_w, target_h = config["size"]
    prompt = config["prompt"] + f", {target_w}x{target_h} pixels, game sprite"

    print(f"  Generating: {name} ({target_w}x{target_h})...")

    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_modalities=["image", "text"],
            ),
        )

        for part in response.candidates[0].content.parts:
            if part.inline_data:
                img_data = part.inline_data.data
                img = Image.open(io.BytesIO(img_data))
                # Resize to target if needed
                if img.size != (target_w, target_h):
                    img = img.resize((target_w, target_h), Image.LANCZOS)
                # Ensure RGBA
                if img.mode != "RGBA":
                    img = img.convert("RGBA")
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

    total = len(PROPS)
    success = 0
    failed = []

    print(f"\nGenerating {total} Act 1 prop sprites...\n")

    for i, (name, config) in enumerate(PROPS.items()):
        if generate_prop(name, config):
            success += 1
        else:
            failed.append(name)

        # Rate limiting between API calls
        if i < total - 1:
            time.sleep(RATE_LIMIT_DELAY)

    print(f"\n{'=' * 40}")
    print(f"Done: {success}/{total} props generated")
    if failed:
        print(f"Failed: {', '.join(failed)}")
    print(f"Output: {PROPS_DIR}")


if __name__ == "__main__":
    main()
