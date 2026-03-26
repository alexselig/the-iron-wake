# TERMINAL 4: Art, Polish & Connectivity
# STATUS: IN PROGRESS
# CLAIMED BY: Claude Terminal — Main Session (Mar 26)

## Instructions
1. This terminal handles cross-cutting concerns: art, icons, NPC consistency, room connections
2. Do NOT create new rooms — that's Terminals 1-3
3. Focus on making existing content look and feel polished
4. Coordinate with other terminals by checking their room scripts for go_to_room() paths

## Task List

### Inventory Icon Art
- [ ] Generate proper inventory icons for all Act 1 items (currently using placeholders):
  - medallion, stamp, brass_strip, blank_form, filled_form
  - guild_badge, fancy_teacup, focusing_disc, memory_lens
  - relay_key, map_plate, black_shard, automaton_hand
- [ ] Use `generate_art_gemini.py` as reference for Gemini API icon generation
- [ ] Icons should be 36x36, steampunk brass style, transparent background
- [ ] Save to `assets/inventory_icons/{item_name}.png`

### NPC Sprite Consistency
- [ ] Run reference-based regeneration (like `fix_rowan_poses.py`) for:
  - Tibbit (check if idle/talking/walk are consistent)
  - Pindle (already fixed — talk uses idle frames)
  - Mirelle, Marrow, Rook (needed for Terminals 1 and 3)
- [ ] After regeneration, run `process_characters.py` to update game sprites
- [ ] Verify all NPCs in `assets/characters/*/` have: idle_right_0/1, idle_left_0/1, talk_right_0/1, talk_left_0/1

### Room Connectivity
- [ ] Once Terminals 1-3 finish their rooms, verify all `go_to_room()` paths:
  ```
  Harbor (main.tscn) ←→ Customs Shack
  Harbor → Salvage Warehouse → Brass Bazaar → Tibbit's Workshop
  Tibbit's Workshop → Harbor Cliffs → Lighthouse Exterior → Lighthouse Chamber
  ```
- [ ] Each room's `_get_entry_position()` should position player based on `previous_room`
- [ ] Test walking between all rooms end-to-end

### Wrong-Item Dialogue Polish
- [ ] Add funny catch-all responses in each room for wrong item combinations
- [ ] Ensure every verb (look, talk, pick up, use, open, push) has a response for every object
- [ ] Add running gags: Pindle's forms, Tibbit's naming conventions, literal machines

### Sound Effects (stretch goal)
- [ ] Add basic SFX files to `assets/sfx/`: pickup.wav, door.wav, dialogue_blip.wav
- [ ] Wire up pickup sound in `give_item()` in adventure_room.gd
- [ ] Wire up door sound in `go_to_room()`

## Key References
- Gemini art generation: `generate_art_gemini.py`, `fix_rowan_poses.py`
- Character processing: `process_characters.py`
- All room scripts: `scripts/*_room.gd`
- Design docs: `design/act1_script.md`, `design/the_gilded_wake_gdd.md`
