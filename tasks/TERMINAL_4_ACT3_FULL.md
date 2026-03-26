# TERMINAL 4: Act 3 Complete (Rooms 16-21 + Endings + Engine Extensions)
# STATUS: COMPLETE
# CLAIMED BY: Claude Terminal — gstack session 2

## Instructions
1. Read `design/act3_script.md` for full dialogue and puzzle design
2. This terminal builds ALL of Act 3 (7 rooms, 7 puzzles, 3 endings)
3. New NPCs: Archivist Sel, Councilor Ilyan, Warden Seraphine (Rooms 20-21)
4. This terminal also owns engine extensions needed for Acts 2-3
5. MUST complete engine extensions FIRST so Terminals 2-3 can use them

## Task List

### Engine Extensions (DO FIRST — other terminals depend on these)
- [ ] **Ring rotation UI**: New scene/script for rotating concentric rings (needed by Act 2 Room 15 + Act 3 Room 21)
  - Visual: 3 concentric brass rings with symbols, rotatable by click-drag or buttons
  - Logic: Each ring has N positions; puzzle defines which alignment is correct
  - Integration: AdventureRoom can show/hide ring puzzle overlay
- [ ] **Timing/rhythm puzzle UI**: Simple beat-matching for tone sequences (Act 2 Room 11, Act 3 Room 17)
  - Visual: Horizontal bar with timing markers, player clicks to match notes
  - Logic: Configurable sequence, tolerance window for timing
- [ ] **Multiple endings support**: GameState needs `ending_choice` flag + branching in final cutscene
- [ ] **Memory Vision system**: Standardize the cutscene pattern for visions (4 total, only 1 exists)
  - Fade to sepia/golden overlay, dreamlike dialogue, fade back
  - Reusable CutscenePlayer extension or helper function

### Pre-Work: Act 3 Art Generation
- [ ] Generate ~25 prop sprites for Rooms 16-21 using Gemini API:
  - Room 16: Vent wheels, glass outcroppings, transit plinths, warning bells, cable tram, heat shutters
  - Room 17: Resonator pipes, scaffold pipe, auxiliary panel, maintenance hatch
  - Room 18: Relay core socket, harmonic bridge, light rails, archive basin, docking clamps
  - Room 19: (Cutscene room — minimal props, mostly dialogue)
  - Room 20: Luminous terraces, canals, silver-leaf trees, garden benches
  - Room 21: Resonance rings, gate nexus, console, bloodline socket, override drill
- [ ] Generate ~12 inventory icons for Act 3 items:
  - Complete civic signet, insulated gloves, conductive links, valve handle
  - Coil clamp, reflective cinderglass, scaffold pipe, signal flare
  - Warden seal, council seal, archive code

### Room 16 — Cinderglass Valley
- [ ] Create `scripts/cinderglass_valley_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/cinderglass_valley.tscn`
- [ ] Background: `act3_01_cinderglass_valley.png`
- [ ] Act 3 opening cutscene: Dawn, Patient Gull over valley, Map Plate glowing, Rook's airship on horizon
- [ ] Props: Vent wheels, glass outcroppings, transit plinths, warning bells, heat shutters
- [ ] Puzzle 1: Cross the Steam Terrace (valve redirect → prop shutter → cinderglass mirror → cross during lull)
- [ ] Bram anchor dialogue: "I prefer my crimes terrestrial"
- [ ] Discovery: Ancient plinth with whole civic crest (pre-split)
- [ ] Room transitions: from Act 2 ending, forward to Mountain Breach

### Room 17 — The Mountain Breach
- [ ] Create `scripts/mountain_breach_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/mountain_breach.tscn`
- [ ] Background: `act3_02_mountain_breach.png`
- [ ] Props: Rook's scaffolding, survey equipment, resonator pipes, auxiliary panel, maintenance hatch
- [ ] Puzzle 2: Open Maintenance Hatch (tone cylinder → broken playback → scaffold pipe low note → whistle high note → prism light → full sequence)
- [ ] NOTE: Uses rhythm puzzle UI from engine extensions
- [ ] Room transitions: back to Cinderglass Valley, forward to Undersea Transit

### Room 18 — Undersea Transit Chamber (COMPLEX — 3 puzzles + Rook)
- [ ] Create `scripts/undersea_transit_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/undersea_transit.tscn`
- [ ] Background: `act3_03_undersea_transit.png`
- [ ] Props: Relay core socket, harmonic bridge, light rails, archive basin, docking clamps, guidance arm
- [ ] Puzzle 3: Restore Final Relay Power (insert core → bridge links → re-seat rails → Marrow arrives with signet half → Complete Civic Signet)
- [ ] Puzzle 4: Choose Wake Authorization (NARRATIVE CHOICE — 3 options affecting ending)
  - Personal transit only / Authorized emergency / Open signal broadcast
- [ ] Rook Breach cutscene (huge door forced open, Rook strides in)
- [ ] Rook confrontation dialogue ("Clean energy... one merely invoices it")
- [ ] Puzzle 5: Launch Transit Cradle (escape: signet → Tibbit override → prism in guidance → release clamps → optional signal flare)
- [ ] Room transitions: forward to Wake Passage

### Room 19 — Wake Sea Passage (CUTSCENE ROOM)
- [ ] Create `scripts/wake_passage_room.gd` (mostly cutscene-driven, minimal interaction)
- [ ] Create `scenes/rooms/wake_passage.tscn`
- [ ] Background: `act3_04_wake_passage.png`
- [ ] Dialogue sequence: Tibbit/Rowan/Marrow banter during transit
- [ ] Key scene: Rowan confronts Marrow ("You knew about me")
- [ ] Marrow's explanation: "Truths given too early become costumes"
- [ ] Memory Vision 4: Final childhood fragment (night on island, panic, mother places Rowan in cradle with young Marrow)
- [ ] Room transition: forward to Isle Auric

### Room 20 — Isle Auric Harbor + Council Gardens
- [ ] Create `scripts/isle_auric_room.gd` extending AdventureRoom (or split into 2 rooms)
- [ ] Create `scenes/rooms/isle_auric_harbor.tscn`
- [ ] Create `scenes/rooms/council_gardens.tscn` (if split)
- [ ] Backgrounds: `act3_05_isle_auric_harbor.png` + `act3_06_council_gardens.png`
- [ ] NEW NPCs (all sprites exist):
  - Archivist Sel (`assets/characters/sel/`) — calm scholar
  - Councilor Ilyan (`assets/characters/ilyan/`) — worn by compromise
  - Warden Seraphine (`assets/characters/seraphine/`) — formal, wary
- [ ] Island truth revealed: Harmony systems failing, demanding resolution
- [ ] Rook arrival cutscene (damaged airship limps into lagoon)
- [ ] 3 NPC dialogue trees (Sel, Ilyan, Seraphine — island history, factions, Rowan's role)
- [ ] Room transitions: forward to Harmonic Gate

### Room 21 — The Central Harmonic Gate (FINALE)
- [ ] Create `scripts/harmonic_gate_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/harmonic_gate.tscn`
- [ ] Background: `act3_07_harmonic_gate.png`
- [ ] Props: Resonance rings, gate nexus, console, bloodline socket
- [ ] Puzzle 6: Rebuild Civic Harmony (medallion in socket → convince Seraphine → convince Ilyan → Sel's archive code → Tibbit tunes rings → stop Rook)
- [ ] NOTE: Uses ring rotation UI from engine extensions
- [ ] Rook confrontation: Forces channel open, rings spin, transit tear opens
- [ ] Puzzle 7: Defeat Rook (rotate outer→civic consensus, middle→emergency transit, inner→reflective lock → insert signet → wait for drill → pull choke lever)
- [ ] **FINAL DECISION** — 3 endings:
  1. Seal the island completely (bittersweet)
  2. Open limited diplomatic contact (balanced — recommended)
  3. Fully reopen Wake Road (hopeful but volatile)
- [ ] Rowan's Final Speech (per ending variant)
- [ ] Ending sequence cutscene per variant:
  - Harbor calm, Rook under guard, Bram/Tibbit banter
  - Marrow/Rowan lagoon scene, Sel asks about new road
  - Final image: white light extending to mainland, transit cradle glides out
- [ ] Post-credits scene: Pindle receives island envelope, "reciprocal customs delegation" — "They have forms."

## Key References
- Act 3 script: `design/act3_script.md`
- Room pattern: `scripts/customs_shack_room.gd`
- CutscenePlayer: `scripts/cutscene_player.gd`
- DialogueTree: `scripts/dialogue_tree.gd`
- Prop generation: `generate_props.py`
- Scene template: `scenes/rooms/customs_shack.tscn`
