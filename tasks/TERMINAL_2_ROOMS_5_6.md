# TERMINAL 2: Rooms 5-6 (Tibbit's Workshop + Harbor Cliffs)
# STATUS: COMPLETE
# CLAIMED BY: Claude Terminal — gstack session

## Instructions
1. Read `design/act1_script.md` Scenes 5-6 for full dialogue and puzzle design
2. Read `scripts/customs_shack_room.gd` as the reference pattern for room scripts
3. Copy `scenes/rooms/customs_shack.tscn` as template for each new room scene
4. Change the script reference in the .tscn from customs_shack_room.gd to your new script
5. Test each room by temporarily changing title_screen.gd to load your room directly

## Task List

### Room 5 — Tibbit's Workshop Cart
- [x] Create `scripts/tibbit_workshop_room.gd` extending AdventureRoom
- [x] Create `scenes/rooms/tibbit_workshop.tscn` (copy template, update script ref)
- [x] Background: `act1_05_tibbit_workshop.png`
- [x] NPC: Tibbit (`assets/characters/tibbit/`)
- [x] Props: Workbench, Clock spring, Lamp oil, Whistle, Lens frame, Burner pot
- [x] Puzzle 4: Assemble Memory Lens (inventory crafting — combine lens frame + focusing disc + clock spring)
- [x] Override `_on_combine_items()` for the crafting puzzle
- [x] Tibbit dialogue tree (hints about lens assembly, naming things, boundary stones)
- [x] Room transitions: back to Brass Bazaar, forward to Harbor Cliffs
- [x] Look/Talk/Pick up/Use handlers for all objects
- [x] Wrong-item humor: whistle + lens = "Memory does not need an entrance theme"

### Room 6 — Harbor Cliffs Path
- [x] Create `scripts/harbor_cliffs_room.gd` extending AdventureRoom
- [x] Create `scenes/rooms/harbor_cliffs.tscn` (copy template, update script ref)
- [x] Background: `act1_06_harbor_cliffs.png`
- [x] Short atmospheric transition room — NO major puzzle
- [x] NPC: Marrow Quill first appearance (cryptic dialogue, 3-branch tree)
- [x] Props: Two boundary stones with ancient markings, iron railings, sea view
- [x] Room transitions: back to Tibbit's Workshop, forward to Lighthouse Exterior
- [x] Look handlers for atmospheric descriptions
- [x] Intro cutscene: Marrow Quill meeting ("You came quickly" / "I dislike being expected")

## Key References
- Act 1 script: `design/act1_script.md` (Scenes 5-6)
- Room pattern: `scripts/customs_shack_room.gd`
- Scene template: `scenes/rooms/customs_shack.tscn`
- SceneBuilder methods: `scripts/scene_builder.gd` (build_prop, build_hotspot, build_npc)
