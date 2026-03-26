# TERMINAL 3: Rooms 7-8 (Lighthouse Exterior + Chamber)
# STATUS: COMPLETE
# CLAIMED BY: Claude Terminal — Session 2

## Instructions
1. Read `design/act1_script.md` Scenes 7-8 for full dialogue and puzzle design
2. Read `scripts/customs_shack_room.gd` as the reference pattern for room scripts
3. Copy `scenes/rooms/customs_shack.tscn` as template for each new room scene
4. Change the script reference in the .tscn from customs_shack_room.gd to your new script
5. Test each room by temporarily changing title_screen.gd to load your room directly

## Task List

### Room 7 — Hushlight Lighthouse Exterior
- [x] Create `scripts/lighthouse_exterior_room.gd` extending AdventureRoom
- [x] Create `scenes/rooms/lighthouse_exterior.tscn` (copy template, update script ref)
- [x] Background: `act1_07_lighthouse_exterior.png`
- [x] NPC: Marrow Quill (`assets/characters/marrow/`) — first appearance, cryptic
- [x] Puzzle 5: Open Lighthouse Door (salt paste → brass strip → beacon crank)
- [x] Marrow dialogue tree (cryptic hints about the relic, the island, Rowan's past)
- [x] Room transitions: back to Harbor Cliffs, forward to Lighthouse Chamber
- [x] Look/Talk/Pick up/Use handlers for all objects

### Room 8 — Lighthouse Main Chamber
- [x] Create `scripts/lighthouse_chamber_room.gd` extending AdventureRoom
- [x] Create `scenes/rooms/lighthouse_chamber.tscn` (copy template, update script ref)
- [x] Background: `act1_08_lighthouse_chamber.png`
- [x] Props: Lens pedestal, Chart table, Mural, Beacon controls, Shutters
- [x] Puzzle 6: Align the Lens (shutters → install memory lens → rotate mirrors → key)
- [x] Second memory vision cutscene (Act 1 climax — council argument, Rowan's parents)
- [x] Act 1 ending cutscene: Rook arrives, confrontation, escape sequence
- [x] Rook NPC — Rook dialogue used in ending (voice only, no on-screen NPC needed)
- [x] Room transitions: back to Exterior. Act 1 ends here → title screen.
- [x] Look/Talk/Pick up/Use handlers for all objects

## Key References
- Act 1 script: `design/act1_script.md` (Scenes 7-8)
- Room pattern: `scripts/customs_shack_room.gd`
- Scene template: `scenes/rooms/customs_shack.tscn`
- SceneBuilder methods: `scripts/scene_builder.gd` (build_prop, build_hotspot, build_npc)
