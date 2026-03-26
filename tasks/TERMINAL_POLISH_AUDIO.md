# CROSS-CUTTING: Polish, Audio & QA (Run after all rooms are built)
# STATUS: NOT STARTED
# CLAIMED BY: (write your terminal ID here when you start)

## Instructions
1. This task list runs AFTER Terminals 1-4 complete their rooms
2. Handles cross-cutting polish that touches all rooms
3. Can be split across multiple terminals if needed
4. Audio is a stretch goal — game works without it

## Task List

### NPC Sprite Consistency Pass
- [ ] Run reference-based regeneration for all 11 characters (use `fix_rowan_poses.py` pattern)
- [ ] After regeneration, run `process_characters.py` to update game sprites
- [ ] Verify all NPCs have consistent style: idle_right_0/1, idle_left_0/1, talk_right_0/1, talk_left_0/1
- [ ] Special attention: Sel, Ilyan, Seraphine (only used in Act 3, may not match Act 1 NPCs)

### Wrong-Item Dialogue Polish (ALL 22 rooms)
- [ ] Act 1 rooms (1-8): Ensure every verb × object combo has a response
- [ ] Act 2 rooms (9-15): Same
- [ ] Act 3 rooms (16-21): Same
- [ ] Add running gags consistency:
  - Pindle's forms (reference in Rooms 2, 15, post-credits)
  - Tibbit's invention naming (Rooms 1, 5, 11, 15, 18, 21)
  - Literal machines (throughout)
  - Rowan's dry item descriptions (every pickup)
- [ ] Fourth-wall meta joke for combining obviously unrelated items

### Full Game Connectivity Test
- [ ] Walk all 22 rooms end-to-end: title → harbor → ... → harmonic gate → ending
- [ ] Verify all `go_to_room()` paths are bidirectional where appropriate
- [ ] Verify all `_get_entry_position()` returns for every previous_room
- [ ] Test inventory persistence across ALL room transitions
- [ ] Test save/load at each room, verify all flags restore correctly
- [ ] Test all 3 ending paths trigger correctly based on Room 18 choice

### Audio — Music (STRETCH GOAL)
- [ ] Generate or source ambient tracks for regions:
  - Harbor/Town (Rooms 1-4): Industrial brass, seagulls, crowd hum
  - Workshop/Cliffs (Rooms 5-6): Tinkering, wind, waves
  - Lighthouse (Rooms 7-8): Creaking, wind, mystery
  - Smuggler/Marsh (Rooms 9-10): Night sounds, fog, chapel bells
  - Towers/Waystation (Rooms 11-12): Hum of ancient machines, water
  - Air Dock/Ruins (Rooms 13-14): Wind, airship engines, ruins ambiance
  - Transit Vault (Room 15): Deep underground resonance
  - Act 3 wilderness (Rooms 16-17): Volcanic hiss, mountain wind
  - Undersea/Wake (Rooms 18-19): Deep ocean, luminous hum
  - Isle Auric (Rooms 20-21): Serene, crystalline, building to finale
- [ ] Wire up AudioStreamPlayer per room in adventure_room.gd

### Audio — Sound Effects (STRETCH GOAL)
- [ ] Create/source SFX files in `assets/sfx/`:
  - `pickup.wav` — item collected
  - `door.wav` — room transition
  - `dialogue_blip.wav` — typewriter text sound
  - `puzzle_solve.wav` — puzzle completed
  - `puzzle_fail.wav` — wrong combination
  - `steam_hiss.wav` — steam vents
  - `bell.wav` — chapel/tower bells
  - `tone_resonance.wav` — relay tower/harmonic puzzles
  - `airship_engine.wav` — aerial transit
  - `water_splash.wav` — ocean/waystation
  - `wind.wav` — cliffs/mountain
  - `memory_vision.wav` — entering memory
  - `ending_chime.wav` — final decision made
- [ ] Wire up pickup sound in `give_item()` in adventure_room.gd
- [ ] Wire up door sound in `go_to_room()`
- [ ] Wire up puzzle solve/fail sounds

### Title Screen & Menu Polish
- [ ] Add "Continue" button (loads save game)
- [ ] Add "Settings" for text speed, volume
- [ ] Fade title music into game music
- [ ] Credits sequence accessible from menu

## Key References
- All room scripts: `scripts/*_room.gd`
- Character processing: `process_characters.py`, `fix_rowan_poses.py`
- Design docs: `design/act1_script.md`, `design/act2_script.md`, `design/act3_script.md`
- GDD: `design/the_gilded_wake_gdd.md`
