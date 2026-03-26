#!/usr/bin/env python3
"""Generate all scene backgrounds for The Gilded Wake using Gemini API."""

import os
import time
import warnings
warnings.filterwarnings("ignore")

from google import genai
from google.genai import types
from PIL import Image

API_KEY = "REDACTED"
MODEL = "gemini-2.5-flash-image"
ASSETS_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/backgrounds")
REVIEW_DIR = os.path.expanduser("~/SteampunkBeachDemo/design/scenes")
RATE_LIMIT_DELAY = 5

client = genai.Client(api_key=API_KEY)

STYLE = "stylized cartoon steampunk scene, wide panoramic point-and-click adventure game background, clean flat color areas with subtle shadows for depth, warm muted brown sepia and brass color palette with blue and teal accents, cel-shaded look with crisp color blocks matching animated movie background design, cluttered and lived-in with many small details and potential interactive objects, classic LucasArts adventure game background style"

SCENES = {
    # === ACT 1 ===
    "act1_01_blackwake_harbor": {
        "name": "Blackwake Harbor Shore",
        "prompt": f"""{STYLE}, outdoor scene at dawn after a storm. A crooked harbor town of brass pipes, tide-worn brick buildings, leaning cranes, and hissing steam vents. Beach shoreline in foreground with wet sand and kelp. Left: wooden docks with fishing boats, rope coils, crates, a brass sign. Center: a large smooth black ancient relic half-buried in wet sand, glowing with faint blue-white geometric lines, crowd of small figures gathered around it. Right: customs shack with crooked chimney, crane machinery, stacked barrels. Sky: dawn light through storm clouds, warm orange and cool grey. Steam rising from street grates behind seawall."""
    },
    "act1_02_customs_shack": {
        "name": "Customs Shack Interior",
        "prompt": f"""{STYLE}, small cramped interior of a harbor customs office. Shelves overflowing with forms and ledgers stacked to ceiling. A heavy wooden desk dominates the center with ink pads, stamps, and papers scattered everywhere. Three cold teacups. One dead fern on windowsill. A large official seal press on the desk. Queue rope in front of desk. Wall covered in notices and regulations pinned haphazardly. Cabinet labeled IRREGULARITIES. A crooked chimney pipe runs through ceiling. Brass lamp on desk. The room feels stuffy, bureaucratic, and absurdly over-organized."""
    },
    "act1_03_salvage_warehouse": {
        "name": "Salvage Warehouse Interior",
        "prompt": f"""{STYLE}, large brick warehouse interior with high ceiling and iron braces. Rows of shelves stacked with tagged salvage crates and confiscated contraptions. A broken automaton hand on one shelf. Strange relic fragments in glass cases. A large symbol archive board on the wall with copied ancient symbols. A chain hoist hangs from the ceiling. Wooden crate marked LIGHTHOUSE TRANSFER. A suspiciously polished black shard on a table. Dim lighting from high windows. Damp timber walls. Industrial and mysterious."""
    },
    "act1_04_brass_bazaar": {
        "name": "The Brass Bazaar",
        "prompt": f"""{STYLE}, bustling outdoor market scene. A maze of colorful canvas canopies, rope-strung brass lamps, and dangling gears overhead. Market stalls piled with junk, fake relics, polished brass, bottled lightning, and suspicious tea. A mechanical parrot on a perch. Crates and barrels everywhere. A junk sorting conveyor belt in the background. Hidden back rooms behind curtains. Copper masks hanging from hooks. Warm lighting filtering through canopies. Busy, colorful, chaotic energy."""
    },
    "act1_05_tibbit_workshop": {
        "name": "Tibbit's Workshop Cart",
        "prompt": f"""{STYLE}, a cramped mobile workshop wedged between two warehouse walls. Half tool chest, half explosion apology. Springs and gears hang from hooks on walls. Blueprints pinned under teacups. A workbench covered in half-assembled brass contraptions. Coil spools, clock springs, lamp oil bottles, tiny whistles. One burner hissing under a pot labeled DO NOT TASTE AGAIN. Shelves of labeled jars. A lens frame on the bench. Tools everywhere. Organized chaos of an eccentric inventor."""
    },
    "act1_06_harbor_cliffs": {
        "name": "Harbor Cliffs Path",
        "prompt": f"""{STYLE}, dramatic outdoor cliff path winding upward above a rough sea. Iron railings bent by wind. Waves crashing on rocks below sending up spray. Ancient boundary stones along the path with carved symbols. Wild grass and sea plants growing from cracks. A distant lighthouse visible at the top of the cliffs. Moody overcast sky with breaks of warm light. The path feels windswept, exposed, and ancient. Seabirds in the distance."""
    },
    "act1_07_lighthouse_exterior": {
        "name": "Hushlight Lighthouse Exterior",
        "prompt": f"""{STYLE}, a tall white stone lighthouse turned grey by salt and neglect on a cliff top. Brass braces girdle the stone tower. Dead signal wires trail from the upper gallery. The main door has an ancient circular slot mechanism. Crumbling stone walls around a small courtyard. Wild ivy climbing the base. A weathered bench. Storm damage visible on the roof. The beacon is dark. Dramatic clouds behind. The building feels abandoned but not dead, like it is waiting."""
    },
    "act1_08_lighthouse_chamber": {
        "name": "Hushlight Lighthouse Main Chamber",
        "prompt": f"""{STYLE}, circular interior chamber of an old lighthouse. A towering lens assembly in the center on a brass pedestal. Broken mirrors and brass rails around the walls. Tide charts and old maps pinned to surfaces. A wall mural showing ships, stars, and an island beneath a radiant symbol. Rotating beacon controls with wheels and levers. Window shutters that can be opened. Dust hanging in slanting beams of light. The room feels abandoned by people but not by purpose. Mysterious and beautiful."""
    },

    # === ACT 2 ===
    "act2_01_smuggler_path": {
        "name": "Undercliff Smuggler Path",
        "prompt": f"""{STYLE}, a narrow trail cut into a seaside cliffside. Rope bridges swaying over crashing dark surf below. Rusty pulley lifts cling to the stone. Old smuggler crates wedged into cliff alcoves. A signal lantern on a bracket. Graffiti scratched into the rock. An old speaking tube pipe mounted on the wall. The path is precarious and weathered. Night or dusk lighting with moonlight on the water. The cliff face shows ancient markings beneath the smuggler additions."""
    },
    "act2_02_brackmarsh": {
        "name": "The Brackmarsh",
        "prompt": f"""{STYLE}, a vast wetland landscape of reeds, black pools, and low rolling fog. Half-drowned stone causeways stretch across the marsh. A small chapel on wooden stilts leans over the water with a bell tower and tied-down bell. Black glass standing panels (mirrors/markers) poke out of the reeds at intervals. Steam contraptions rust beside ruins far older than anything on the coast. A reed skiff tied to a post. Mud vents bubbling. Eerie, atmospheric, beautiful in a haunted way. Dawn light filtering through mist."""
    },
    "act2_03_relay_tower": {
        "name": "The First Relay Tower",
        "prompt": f"""{STYLE}, a slender ancient black stone tower rising from shallow marsh water. The tower is etched with luminous geometric grooves that glow faintly blue-white. Smooth dark surfaces with only a few brass repair patches added by later scavengers. At the base is a circular platform with three empty sockets and a central interface panel. Tone fork instruments embedded in the walls. A rusted scavenger ladder leaning against one side. Marsh reeds and still water surrounding. The tower feels impossibly old and elegant."""
    },
    "act2_04_sunken_waystation": {
        "name": "The Sunken Waystation",
        "prompt": f"""{STYLE}, a partially submerged underground ancient transit station. Elegant benches of impossibly smooth material line the walls. A large map arch flickers intermittently with geometric route lines. Small storage lockers with vacuum seals along one wall. A hand pump for water. A ticket slot terminal. Water on the floor reflects the flickering lights. The architecture is impossibly refined, smooth white stone with luminous grooves, half flooded. A message tube terminal on the wall. Beautiful and melancholy, a drowned waiting room for a civilization that vanished."""
    },
    "act2_05_ironwind_airdock": {
        "name": "The Ironwind Air Dock",
        "prompt": f"""{STYLE}, a dramatic cliffside air dock with derelict airships, tall mooring spines, and wind-torn signal flags. Center: a patched pear-shaped airship called The Patient Gull sits on a landing pad, looking barely airworthy. Dock winches and fuel lines snake across the platform. Broken mooring towers in the background. Wind-battered buildings. A fuel gauge on a post. The sky is dramatic with clouds. The whole scene feels like dangerous optimism at altitude. Far below, the landscape stretches out."""
    },
    "act2_06_fogwound_ruins": {
        "name": "Fogwound Ruins Outer Court",
        "prompt": f"""{STYLE}, a broken courtyard of white stone now swallowed by roots, moss, and ivy. Broken archways ring a central plaza. Brass salvage scaffolding shows recent excavation work. Ancient wall panels flicker under dirt. A fallen statue on a plinth. An excavation crane. Survey equipment and camp notes on a table. Three rotating shadow dial panels on pedestals. A collapsed gate blocks the main entrance. The ruins feel ancient and sacred, now being pried open by modern greed."""
    },
    "act2_07_transit_vault": {
        "name": "The Ruins Transit Vault",
        "prompt": f"""{STYLE}, a pristine underground chamber that glows faintly from within. The walls are smooth luminous white stone. A huge circular door dominates the far wall, ringed with dormant transit sigils. In the center, a suspended mechanism like a compass made of concentric rings floats above a pedestal. A broken civic crest split in two halves mounted on opposite walls. An archive node console. Power channels run along the floor. The room is impossibly intact beneath the ruins. Beautiful, solemn, and charged with ancient purpose."""
    },

    # === ACT 3 ===
    "act3_01_cinderglass_valley": {
        "name": "Cinderglass Valley",
        "prompt": f"""{STYLE}, a volcanic valley landscape with black glassy obsidian outcroppings catching the light like shattered mirrors. Steam hisses from vents in the ground. Narrow stone walkways weave between sinkholes and collapsed ancient transit pylons. Terraces of silver-leaf moss. Heat shutters and vent wheels mounted on posts. A broken cable tram system. Warning bells on posts. Half-buried ancient structures warped by heat and time. Dawn light makes the glass formations sparkle. Dramatic and alien landscape."""
    },
    "act3_02_mountain_breach": {
        "name": "The Mountain Breach",
        "prompt": f"""{STYLE}, a massive break in a mountainside revealing ancient transit architecture. A giant circular aperture of dark smooth stone sits behind modern brass salvage scaffolding. Ancient channels run into the rock like veins. Harmonic resonator pipes emerge from the stone. A maintenance crawl hatch to one side. Survey equipment scattered around. A broken lift. The scale is enormous, the ancient door dwarfs everything around it. The mountain looms above. Dramatic lighting from the sky."""
    },
    "act3_03_undersea_transit": {
        "name": "The Undersea Transit Chamber",
        "prompt": f"""{STYLE}, an immense subterranean station suspended over black seawater inside a mountain cavern. Narrow platforms with luminous rails and elegant arches stretch across a deep chasm where dark tide water moves far below. At the center, a dormant transit cradle sits on the rail, half vessel half machine, sleek and elegant. A route console with glowing map. A power lattice web of light. The chamber is impossibly intact and beautiful. Bioluminescent elements in the cave walls. The scale is cathedral-like."""
    },
    "act3_04_wake_passage": {
        "name": "The Wake Sea Passage",
        "prompt": f"""{STYLE}, interior view from inside a transit cradle traveling through ancient submerged channels beneath the sea. Glass-smooth tunnel walls with illuminated current veins glowing blue and white. Impossible arches visible through windows. Vast drowned machine complexes visible outside in the deep water. Enormous fish drifting past like thoughts. The transit cradle interior is sleek with smooth seats. Light ripples across every surface. Breathtaking, serene, otherworldly. The most beautiful scene in the game."""
    },
    "act3_05_isle_auric_harbor": {
        "name": "Isle Auric Outer Harbor",
        "prompt": f"""{STYLE}, a hidden island lagoon ringed by luminous white terraces and hanging gardens. Clear turquoise canals with elegant bridges that curve like calligraphy. Towers rise like tuned instruments, white and gleaming. Silent structures glide without smoke or noise. People in pale practical clothing along the harbor edge. The transit cradle has just arrived at a pristine white dock. The architecture is impossibly refined, clean, harmonious. Lush garden terraces. Clear sky. The island is real and beautiful enough to be almost offensive. Stark contrast to the steampunk mainland."""
    },
    "act3_06_council_gardens": {
        "name": "The Council Gardens",
        "prompt": f"""{STYLE}, a serene garden court on the island. White stone channels carry clear water between terraces. Silver-leaf trees with luminous foliage. Elegant benches overlooking the sea through a gap in low white walls. The garden is designed for calm civic thought. Geometric flower beds. A small pavilion with a table for council meetings. Everything is pristine, harmonious, and slightly too perfect. Warm golden hour lighting. Mountains visible in the distance. Peace that feels carefully maintained."""
    },
    "act3_07_harmonic_gate": {
        "name": "The Central Harmonic Gate",
        "prompt": f"""{STYLE}, a grand circular chamber open to the sky above. Concentric white platforms rise toward a central nexus. Suspended resonance rings of white stone and luminous metal float at different heights. A civic console at the center with sigil sockets. Power channels carved into the floor radiate outward like a sunburst. The chamber is the island's core machine, beautiful and imposing. The sky is visible through the open top, clouds drifting past. The rings glow faintly. This is the final puzzle chamber and emotional heart of the game. Epic scale."""
    },
}


def generate_scene(key, info):
    game_path = os.path.join(ASSETS_DIR, f"{key}.png")
    review_path = os.path.join(REVIEW_DIR, f"{key}_full.png")

    if os.path.exists(review_path):
        print(f"  [SKIP] {info['name']} — already exists")
        return True

    print(f"  Generating: {info['name']}...")
    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=info["prompt"],
            config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
        )
        for part in response.candidates[0].content.parts:
            if part.inline_data is not None:
                raw_path = review_path + ".raw.png"
                part.as_image().save(raw_path)
                img = Image.open(raw_path)

                # Save game-size (640x360)
                img_game = img.resize((640, 360), Image.LANCZOS)
                img_game.save(game_path)

                # Save review-size (1280x720)
                img_full = img.resize((1280, 720), Image.LANCZOS)
                img_full.save(review_path)

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
    print("=== The Gilded Wake — Scene Generation ===\n")
    os.makedirs(ASSETS_DIR, exist_ok=True)
    os.makedirs(REVIEW_DIR, exist_ok=True)

    total = len(SCENES)
    done = 0
    failed = []

    for key in sorted(SCENES.keys()):
        if generate_scene(key, SCENES[key]):
            done += 1
        else:
            failed.append(SCENES[key]["name"])

    print(f"\n=== Done! {done}/{total} scenes generated ===")
    if failed:
        print(f"Failed: {', '.join(failed)}")
        print("Re-run script to retry — it skips existing files.")
    print(f"\nGame backgrounds: {ASSETS_DIR}")
    print(f"Full-res review: {REVIEW_DIR}")
    print(f"Open review folder: open ~/SteampunkBeachDemo/design/scenes/")
