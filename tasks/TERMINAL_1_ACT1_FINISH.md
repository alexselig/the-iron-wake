# TERMINAL 1: Finish Act 1 (Rooms 7-8 + Act 1 Playtest)
# STATUS: COMPLETE
# CLAIMED BY: Claude Terminal — gstack session 2 (rooms by T3, connectivity verified)

## Instructions
1. Read `design/act1_script.md` Scenes 7-8 for full dialogue and puzzle design
2. Read `scripts/customs_shack_room.gd` as the reference pattern for room scripts
3. Copy `scenes/rooms/customs_shack.tscn` as template for each new room scene
4. After rooms are built, do a full Act 1 connectivity + playtest pass

## Task List

### Room 7 — Hushlight Lighthouse Exterior
- [ ] Create `scripts/lighthouse_exterior_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/lighthouse_exterior.tscn` (copy template, update script ref)
- [ ] Background: `act1_07_lighthouse_exterior.png`
- [ ] NPC: Marrow Quill (`assets/characters/marrow/`) — cryptic, waiting at door
- [ ] Props: Door mechanism (circular slot), Beacon crank, Courtyard bench, Signal wires
- [ ] Puzzle 5: Open Lighthouse Door (salt paste → brass strip into groove → beacon crank)
- [ ] Marrow dialogue tree (cryptic hints about the relic, island, Rowan's past)
- [ ] Room transitions: back to Harbor Cliffs, forward to Lighthouse Chamber
- [ ] Look/Talk/Pick up/Use handlers for all objects

### Room 8 — Lighthouse Main Chamber (HEAVIEST ROOM IN ACT 1)
- [ ] Create `scripts/lighthouse_chamber_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/lighthouse_chamber.tscn` (copy template, update script ref)
- [ ] Background: `act1_08_lighthouse_chamber.png`
- [ ] Props: Lens pedestal, Chart table, Wall mural, Beacon controls, Window shutters
- [ ] Puzzle 6: Align the Lens (open shutters → install memory lens → rotate mirrors → get relay key)
- [ ] Second Memory Vision cutscene (Act 1 climax — council argument, Rowan's parents)
- [ ] Act 1 ending cutscene: Rook arrives, confrontation, escape down rear stairs
- [ ] Rook NPC (`assets/characters/rook/`) for ending scene
- [ ] Room transitions: back to Exterior; Act 1 ends here (transition to Act 2 opener)
- [ ] Look/Talk/Pick up/Use handlers for all objects

### Act 1 End-to-End Connectivity
- [ ] Verify ALL `go_to_room()` paths form a complete chain:
  ```
  Harbor (main.tscn) ↔ Customs Shack
  Harbor → Salvage Warehouse → Brass Bazaar → Tibbit's Workshop
  Tibbit's Workshop → Harbor Cliffs → Lighthouse Exterior → Lighthouse Chamber
  ```
- [ ] Each room's `_get_entry_position()` returns correct position for every adjacent room
- [ ] Test inventory persistence across all 8 room transitions
- [ ] Test save/load at each room
- [ ] Verify all 6 puzzles are solvable end-to-end (items carry forward correctly)
- [ ] Opening cinematic plays correctly on first visit to Harbor

## Key References
- Act 1 script: `design/act1_script.md` (Scenes 7-8)
- Room pattern: `scripts/customs_shack_room.gd`
- CutscenePlayer pattern: `scripts/cutscene_player.gd`
- Scene template: `scenes/rooms/customs_shack.tscn`
- SceneBuilder methods: `scripts/scene_builder.gd`
