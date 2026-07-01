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
- `VoiceOver` (`scripts/voice_over.gd`) — plays pre-generated ElevenLabs dialogue clips by content hash. No-op if a clip is missing. Press **V** in-game to mute/unmute.

### Core Scripts (`scripts/`)
- `adventure_room.gd` — base class for ALL rooms (verb handling, dialogue, inventory, transitions, hover text, dialogue tree runner)
- `dialogue_tree.gd` — branching NPC conversations (RefCounted, chainable API, supports conditions/flags/items)
- `cutscene_player.gd` — scripted sequences (walk, say, fade, give items) via builder pattern
- `scene_builder.gd` — factory: `build_prop()`, `build_hotspot()`, `build_npc()`, `build_player_sprite()`. Note: `build_all()` only works for beach room
- `clickable.gd` — base for all interactive objects (click/hover detection, highlight, bobbing)
- `player.gd` — CharacterBody2D, walk-to-target, facing, animation (sprite loaded from `assets/characters/frames/`)
- `npc.gd` — NPC class (currently unused — SceneBuilder.build_npc uses Clickable with AnimatedSprite2D instead)
- `verb_panel.gd` — 6-verb LucasArts-style panel (look, talk, pick up, use, open, push)
- `dialogue_box.gd` — Popochiu-style overhead floating text with per-character colors, word-by-word reveal, semi-transparent background, black outline. NO dialogue box panel.
- `inventory.gd` — 8-slot grid with item icons and combination support. Syncs with GameState on room load.
- `voice_over.gd` — `VoiceOver` autoload; `dialogue_box.gd` calls `VoiceOver.play(speaker, text)` when a line shows and `.stop()` when it dismisses.

### Room Scripts
- `beach_room.gd` — Room 1: Blackwake Harbor (full Puzzle 1: spyglass→dry sand→distract Pindle→steal stamp→scrape→medallion→steam valve→memory vision)
- `customs_shack_room.gd` — Room 2: Pindle's customs office (Puzzle 2: forge a permit)

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
6. **IMPORTANT**: Set `speaker_to_node` dict in `_on_room_ready()` mapping speaker names to NPC node names (e.g., `speaker_to_node = {"PINDLE": "PindleDesk"}`) — without this, NPCs won't animate when talking
7. Set `walkable_y_min`/`walkable_y_max` exports if the room needs a different walk zone (default: 200-350)

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

## Parallel Development (4 Terminals)

This project is built in parallel across 4 Claude terminal windows. Each terminal has a dedicated task file:

- `tasks/TERMINAL_1_ROOMS_3_4.md` — Salvage Warehouse + Brass Bazaar
- `tasks/TERMINAL_2_ROOMS_5_6.md` — Tibbit's Workshop + Harbor Cliffs
- `tasks/TERMINAL_3_ROOMS_7_8.md` — Lighthouse Exterior + Chamber
- `tasks/TERMINAL_4_ART_POLISH.md` — Art, inventory icons, NPC consistency, connectivity

**When starting work:**
1. Check `grep "STATUS:" tasks/TERMINAL_*.md` to see which are unclaimed
2. Pick an unclaimed task file
3. Update its STATUS to `IN PROGRESS` and CLAIMED BY to your terminal ID
4. Follow the task list in that file
5. Mark tasks with `[x]` as you complete them
6. When done, set STATUS to `COMPLETE`

**Rules:**
- Do NOT work on another terminal's files
- Each terminal creates independent room scripts — no merge conflicts
- Shared files (`adventure_room.gd`, `scene_builder.gd`) are only edited by Terminal 4
- Full plan: `PARALLEL_PLAN.md`

## Known Issues (remaining)
- `player.gd` has dead code: `speech_finished` signal, `is_talking` variable, stale "Elara Voss" comment
- `clickable.gd` has unused `item_used` signal
- Missing inventory icons for `blank_form` and `filled_form`

## Voiceover (ElevenLabs)
Dialogue is voiced with **pre-generated** ElevenLabs TTS. The API key is used only
by the build-time generator and **never ships in the game** — only the resulting
`.mp3` files do. Full docs: `tools/README.md`.

- **Key**: `tools/.env` → `ELEVENLABS_API_KEY=...` (gitignored — NEVER commit the key).
- **Casting**: `tools/voice_config.json` maps speaker → premade voice ID (no secrets).
- **Generate**: `python3 tools/generate_voiceover.py` (default = opening + beach room).
  `--dry-run` previews lines/char count; `--all` does every room; `--force` re-renders.
  Idempotent — existing clips are skipped.
- **Runtime**: clips live at `assets/voice/<sha1(speaker|text)>.mp3`. `VoiceOver`
  recomputes the same hash to find them. The hash/normalization in
  `scripts/voice_over.gd` (`line_hash`) MUST stay identical to `normalize()` in
  `tools/generate_voiceover.py`. Missing clip = silent (text-only), nothing breaks.

## Commands
- Run game: `/Applications/Godot.app/Contents/MacOS/Godot --path ~/SteampunkBeachDemo`
- Open editor (triggers reimport): `/Applications/Godot.app/Contents/MacOS/Godot --editor --path ~/SteampunkBeachDemo`
- Generate character poses: `python3 generate_poses.py` (Gemini API, generates all 11 characters)
- Fix character consistency: `python3 fix_rowan_poses.py` (uses idle.png as reference image)
- Process poses into sprites: `python3 process_characters.py` (removes bg, crops, resizes, mirrors)
- After adding new assets: must open Godot editor to trigger reimport, or clear `.godot/imported/`

## GitHub
- Repo: https://github.com/alexselig/the-iron-wake (personal account)
- Push requires PAT (keychain defaults to corporate). Use: `git -c credential.helper= push`
- Remote URL should NOT contain the PAT — pass it via credential helper override

## gstack
Use the /browse skill from gstack for all web browsing. Available skills:
/office-hours, /plan-ceo-review, /plan-eng-review, /plan-design-review,
/design-consultation, /review, /ship, /land-and-deploy, /canary, /benchmark,
/browse, /qa, /qa-only, /design-review, /setup-browser-cookies, /setup-deploy,
/retro, /investigate, /document-release, /codex, /cso, /autoplan, /careful,
/freeze, /guard, /unfreeze, /gstack-upgrade
