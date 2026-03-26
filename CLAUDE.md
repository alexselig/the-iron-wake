# The Iron Wake — Steampunk Point-and-Click Adventure

## Project Overview
A sarcastic drifter (Rowan Vale) follows washed-up ancient machines across a steampunk world, solving absurd puzzles and outwitting a velvet-voiced rival to uncover a hidden island utopia.

- **Engine**: Godot 4.6, GDScript, GL Compatibility renderer
- **Viewport**: 640x480 (scaled to 1280x960 window)
- **Genre**: Point-and-click adventure comedy
- **Art**: Flat geometric editorial style, Gemini AI-generated

## Architecture

### Autoloads
- `GameState` (`scripts/game_state.gd`) — global singleton for inventory, flags, room tracking, save/load

### Core Scripts (`scripts/`)
- `adventure_room.gd` — base class for ALL rooms (verb handling, dialogue, inventory, transitions, hover text)
- `dialogue_tree.gd` — branching NPC conversations (RefCounted, built in code with chainable API)
- `cutscene_player.gd` — scripted sequences (walk, say, fade, give items) via builder pattern
- `scene_builder.gd` — factory that builds all scene elements (player, props, hotspots, NPCs) in code
- `clickable.gd` — base for all interactive objects (click/hover detection, highlight, bobbing)
- `player.gd` — CharacterBody2D, walk-to-target, facing, animation
- `npc.gd` — NPC class (currently unused — SceneBuilder uses Clickable instead)
- `verb_panel.gd` — 6-verb LucasArts-style panel (look, talk, pick up, use, open, push)
- `dialogue_box.gd` — typewriter text display
- `inventory.gd` — 8-slot grid with item icons and combination support

### Room Scripts
- `beach_room.gd` — Room 1: Blackwake Harbor (intro, puzzles, Tibbit/Pindle NPCs)
- `customs_shack_room.gd` — Room 2: Pindle's customs office (permit forging puzzle)

### Scene Structure
- Each room is a full .tscn scene with its own UI copy
- GameState autoload persists across scene transitions
- `SceneBuilder.build_all()` only works for beach room; other rooms call individual methods

### Room Template
To create a new room:
1. Copy `scenes/rooms/customs_shack.tscn` as template
2. Create new script extending `AdventureRoom`
3. Override: `_load_room_background()`, `_build_room()`, `_on_room_ready()`, `_play_intro()`
4. Build props/NPCs via `SceneBuilder` static methods
5. Define verb handlers with match statements

### Art Conventions
- Backgrounds: `assets/backgrounds/{room_name}_full.png`
- Characters: `assets/characters/{name}/` with `idle_left_0.png`, `talk_left_0.png`, etc.
- Inventory icons: `assets/inventory_icons/{item_name}.png` (36x36)
- Character poses: `design/character_poses/`
- **Always archive art iterations** — never delete, move to `design/characters_archive_vN/`

### Texture Loading
All scripts use `_load_texture()` with fallback for missing .import files. Always use this pattern.

## Design Documents
- **GDD**: `design/the_gilded_wake_gdd.md`
- **Act 1 Script**: `design/act1_script.md`
- **Act 2 Script**: `design/act2_script.md`
- **Act 3 Script**: `design/act3_script.md`
- **Implementation Plan**: `~/.claude/plans/wiggly-gliding-flask.md`

## Known Issues
- `npc.gd` is unused (SceneBuilder creates NPCs as Clickable nodes)
- `player.gd` has dead code: `speech_finished` signal, `is_talking` variable, stale "Elara Voss" comment
- `clickable.gd` has unused `item_used` signal
- Missing inventory icons for `blank_form` and `filled_form`
- `customs_shack_room.gd` missing `speaker_to_node` mapping (Pindle won't animate)
- `GameState.items_collected` semantics are broken (remove_item sets to false)
- Hardcoded walkable y-range (200-350) in adventure_room.gd
- `previous_room` not saved/loaded in GameState persistence

## Commands
- Run game: Open in Godot 4.6, press F5
- Generate art: `python generate_characters.py` (requires Gemini API key)

## gstack
Use the /browse skill from gstack for all web browsing. Available skills:
/office-hours, /plan-ceo-review, /plan-eng-review, /plan-design-review,
/design-consultation, /review, /ship, /land-and-deploy, /canary, /benchmark,
/browse, /qa, /qa-only, /design-review, /setup-browser-cookies, /setup-deploy,
/retro, /investigate, /document-release, /codex, /cso, /autoplan, /careful,
/freeze, /guard, /unfreeze, /gstack-upgrade
