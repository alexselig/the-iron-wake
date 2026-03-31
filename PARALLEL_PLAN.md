# The Iron Wake — Parallel Development Plan (4 Terminals)

## Current State
- Engine: complete (AdventureRoom, DialogueTree, CutscenePlayer, GameState)
- Room 1 (Blackwake Harbor): complete with full Puzzle 1 chain
- Room 2 (Customs Shack): complete with Puzzle 2 (Forge a Permit)
- All 11 character sprites processed
- Title screen, overhead dialogue, verb panel — all working

## Terminal Assignments

### Terminal 1: Rooms 3-4 (Salvage Warehouse + Brass Bazaar)
**Files to create/edit:**
- `scripts/salvage_warehouse_room.gd`
- `scenes/rooms/salvage_warehouse.tscn` (copy from customs_shack.tscn template)
- `scripts/brass_bazaar_room.gd`
- `scenes/rooms/brass_bazaar.tscn`

**Room 3 — Salvage Warehouse** (`act1_03_salvage_warehouse.png`)
- Background: long brick warehouse, crates, relic shelves
- Rook's first appearance cutscene (use `assets/characters/rook/`)
- Props: symbol archive board, black shard, lighthouse crate, automaton hand
- Discovery: brass strip matches → lighthouse connection
- Connects to: Harbor (back), Brass Bazaar (forward)

**Room 4 — Brass Bazaar** (`act1_04_brass_bazaar.png`)
- Background: market maze, canopies, dangling gears
- NPCs: Mirelle Soot (`assets/characters/mirelle/`), Mechanical Parrot (hotspot)
- Puzzle 3: Bazaar Bluff (eavesdrop jargon → guild badge + teacup → bluff Mirelle)
- See `design/act1_script.md` Scene 4 for full dialogue/puzzle
- Connects to: Warehouse (back), Tibbit's Workshop (forward)

### Terminal 2: Rooms 5-6 (Tibbit's Workshop + Harbor Cliffs)
**Files to create/edit:**
- `scripts/tibbit_workshop_room.gd`
- `scenes/rooms/tibbit_workshop.tscn`
- `scripts/harbor_cliffs_room.gd`
- `scenes/rooms/harbor_cliffs.tscn`

**Room 5 — Tibbit's Workshop Cart** (`act1_05_tibbit_workshop.png`)
- Background: mobile workshop, tools, blueprints, burners
- NPC: Tibbit (`assets/characters/tibbit/`)
- Props: Workbench, Clock spring, Lamp oil, Whistle, Lens frame
- Puzzle 4: Assemble Memory Lens (inventory crafting — combine lens frame + focusing disc + clock spring)
- See `design/act1_script.md` Scene 5
- Connects to: Bazaar (back), Cliffs (forward)

**Room 6 — Harbor Cliffs Path** (`act1_06_harbor_cliffs.png`)
- Background: wind-battered cliff path, iron railings, boundary stones
- Short atmospheric transition room — no major puzzle
- Ancient markings on stones (examine for lore)
- Connects to: Workshop (back), Lighthouse Exterior (forward)

### Terminal 3: Rooms 7-8 (Lighthouse Exterior + Chamber)
**Files to create/edit:**
- `scripts/lighthouse_exterior_room.gd`
- `scenes/rooms/lighthouse_exterior.tscn`
- `scripts/lighthouse_chamber_room.gd`
- `scenes/rooms/lighthouse_chamber.tscn`

**Room 7 — Hushlight Lighthouse Exterior** (`act1_07_lighthouse_exterior.png`)
- Background: salt-grey tower, brass braces, dead signal wires
- NPC: Marrow Quill (`assets/characters/marrow/`), first appearance
- Puzzle 5: Open Lighthouse Door (salt paste → brass strip → beacon crank)
- See `design/act1_script.md` Scene 7
- Connects to: Cliffs (back), Chamber (forward)

**Room 8 — Lighthouse Main Chamber** (`act1_08_lighthouse_chamber.png`)
- Background: circular chamber, broken mirrors, lens assembly, wall mural
- Puzzle 6: Align the Lens (shutters → install memory lens → rotate mirrors → key)
- Second memory vision (Act 1 climax)
- Act 1 ending cutscene (Rook arrives, escape sequence)
- See `design/act1_script.md` Scene 8
- Connects to: Exterior (back), Act 2 transition

### Terminal 4: Art, Polish & Connectivity
**Files to edit:**
- `scripts/scene_builder.gd` — update `build_all` or remove it, each room builds its own
- All room scripts — verify `go_to_room()` paths connect properly
- Inventory icons — generate proper art for: medallion, stamp, brass_strip, blank_form, filled_form, guild_badge, fancy_teacup, focusing_disc, memory_lens, relay_key, map_plate
- NPC consistency — run `fix_rowan_poses.py` approach for Tibbit, Pindle, Mirelle, Marrow, Rook
- Sound effects — add basic SFX (door, pickup, dialogue advance)
- Wrong-item dialogue — add catch-all funny responses for every room
- Running gags — seed Pindle's forms, Tibbit's naming, literal machines

## Key Rules for All Terminals
1. **Extend AdventureRoom** — every room script follows the same pattern
2. **Copy `scenes/rooms/customs_shack.tscn`** as template for new room scenes
3. **Use `SceneBuilder` static methods** (build_prop, build_hotspot, build_npc) to create objects
4. **Set `speaker_to_node`** in `_on_room_ready()` for NPC talk animations
5. **Use `GameState.set_flag()`/`has_flag()`** for puzzle state — never hardcoded booleans
6. **Use `give_item()`/`take_item()`** — never modify inventory directly
7. **Use `go_to_room("res://scenes/rooms/xxx.tscn")`** for transitions
8. **Read `design/act1_script.md`** for full dialogue text and puzzle solutions
9. **Background images already exist** in `assets/backgrounds/act1_0X_*.png`
10. **Character sprites already exist** in `assets/characters/{name}/`

## Room Connection Map
```
Harbor Shore ←→ Customs Shack
     ↓
Salvage Warehouse ←→ Brass Bazaar ←→ Tibbit's Workshop
                                            ↓
                                    Harbor Cliffs Path
                                            ↓
                                 Lighthouse Exterior ←→ Lighthouse Chamber
```
