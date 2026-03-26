# TERMINAL 1: Rooms 3-4 (Salvage Warehouse + Brass Bazaar)
# STATUS: COMPLETE
# CLAIMED BY: Claude Terminal — Main Window

## Instructions
1. Read `design/act1_script.md` Scenes 3-4 for full dialogue and puzzle design
2. Read `scripts/customs_shack_room.gd` as the reference pattern for room scripts
3. Copy `scenes/rooms/customs_shack.tscn` as template for each new room scene
4. Change the script reference in the .tscn from customs_shack_room.gd to your new script
5. Test each room by temporarily changing title_screen.gd to load your room directly

## Task List

### Room 3 — Salvage Warehouse
- [x] Create `scripts/salvage_warehouse_room.gd` extending AdventureRoom
- [x] Create `scenes/rooms/salvage_warehouse.tscn` (copy template, update script ref)
- [x] Background: `act1_03_salvage_warehouse.png`
- [x] Props: symbol archive board, black shard, lighthouse crate, automaton hand
- [x] Rook first appearance cutscene (use `assets/characters/rook/` for NPC sprite)
- [x] Discovery scene: brass_strip matches symbol archive → lighthouse connection
- [x] Room transitions: back to Harbor (main.tscn), forward to Brass Bazaar
- [x] Look/Talk/Pick up/Use handlers for all objects
- [x] Dialogue tree for Rook encounter

### Room 4 — Brass Bazaar
- [x] Create `scripts/brass_bazaar_room.gd` extending AdventureRoom
- [x] Create `scenes/rooms/brass_bazaar.tscn` (copy template, update script ref)
- [x] Background: `act1_04_brass_bazaar.png`
- [x] NPCs: Mirelle Soot (`assets/characters/mirelle/`), Mechanical Parrot (hotspot)
- [x] Puzzle 3: Bazaar Bluff (eavesdrop jargon → guild badge + teacup → bluff Mirelle)
- [x] Mirelle dialogue tree (haggling)
- [x] Room transitions: back to Warehouse, forward to Tibbit's Workshop
- [x] Look/Talk/Pick up/Use handlers for all objects

## Key References
- Act 1 script: `design/act1_script.md` (Scenes 3-4)
- Room pattern: `scripts/customs_shack_room.gd`
- Scene template: `scenes/rooms/customs_shack.tscn`
- SceneBuilder methods: `scripts/scene_builder.gd` (build_prop, build_hotspot, build_npc)
