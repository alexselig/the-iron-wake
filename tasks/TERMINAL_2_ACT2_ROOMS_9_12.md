# TERMINAL 2: Act 2 First Half (Rooms 9-12)
# STATUS: COMPLETE
# CLAIMED BY: Claude Terminal — gstack session 2

## Instructions
1. Read `design/act2_script.md` Scenes 1-4 for full dialogue and puzzle design
2. Read `scripts/customs_shack_room.gd` as the reference pattern for room scripts
3. Copy `scenes/rooms/customs_shack.tscn` as template for each new room scene
4. New NPCs: Sister Caligo (Room 10). Sprites at `assets/characters/caligo/`
5. Generate prop art before building rooms (use `generate_props.py` as reference)

## Task List

### Pre-Work: Act 2 Art Generation
- [ ] Generate ~15 prop sprites for Rooms 9-12 using Gemini API:
  - Room 9: Cliff lift platform, signal lantern, contraband crate, rope bridge, speaking tube
  - Room 10: Standing mirrors, bell rope, reed skiff, chapel interior
  - Room 11: Relay tower sockets, resonator pipes, tone forks, harmonic bridge
  - Room 12: Vacuum lockers, map arch, transit compass, signal wire
- [ ] Generate ~7 inventory icons for Act 2 items:
  - Dense ceramic bottles, chapel hand mirror, transit sigil fragment
  - Ancient tone cylinder, message strip, brass curtain rod

### Room 9 — Undercliff Smuggler Path
- [ ] Create `scripts/smuggler_path_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/smuggler_path.tscn`
- [ ] Background: `act2_01_smuggler_path.png`
- [ ] Act 2 opening cutscene: Night under cliffs, Rowan+Tibbit descend, Rook's men behind
- [ ] Props: Cliff lift, signal lantern, contraband crate, rope bridge, smuggler graffiti, speaking tube
- [ ] Puzzle 1: Cross the Tide Bridge (ceramic bottles as ballast → coil line redirect → lock with shutter bracket)
- [ ] Room transitions: from Act 1 ending, forward to Brackmarsh
- [ ] Look/Talk/Pick up/Use handlers for all objects

### Room 10 — The Brackmarsh
- [ ] Create `scripts/brackmarsh_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/brackmarsh.tscn`
- [ ] Background: `act2_02_brackmarsh.png`
- [ ] NEW NPC: Sister Caligo (`assets/characters/caligo/`) — sardonic chapel caretaker
- [ ] Props: Standing mirrors, bell rope, reed skiff, chapel door
- [ ] Puzzle 2: Navigate the Mirror Fog (get hand mirror → ring bell → watch markers → rotate → catch light)
- [ ] Caligo dialogue tree (3 branches: towers, mirrors, other travelers)
- [ ] Room transitions: back to Smuggler Path, forward to Relay Tower
- [ ] Look/Talk/Pick up/Use handlers for all objects

### Room 11 — The First Relay Tower
- [ ] Create `scripts/relay_tower_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/relay_tower.tscn`
- [ ] Background: `act2_03_relay_tower.png`
- [ ] Props: Three sockets, resonator pipes, tone forks, auxiliary panel
- [ ] Puzzle 3: Restore Harmonic Circuit (brass rod + reed wire + automaton finger → sockets → relay key → tone matching)
- [ ] Memory Vision 3 cutscene (lesson hall on island, young Rowan, instructor)
- [ ] Room transitions: back to Brackmarsh, forward to Sunken Waystation
- [ ] Look/Talk/Pick up/Use handlers for all objects
- [ ] NOTE: May need engine extension for tone-matching minigame (discuss with Terminal 4)

### Room 12 — The Sunken Waystation
- [ ] Create `scripts/sunken_waystation_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/sunken_waystation.tscn`
- [ ] Background: `act2_04_sunken_waystation.png`
- [ ] Props: Vacuum lockers, map arch, transit compass, signal wire, pump mechanism
- [ ] Puzzle 4: Reactivate Waystation (pump water → dry contacts → insert cylinder → sigil in slot → reconnect wire)
- [ ] Story reveal: "Civic division remains unresolved" — factions existed
- [ ] Room transitions: back to Relay Tower, forward to Ironwind Air Dock
- [ ] Look/Talk/Pick up/Use handlers for all objects

## Key References
- Act 2 script: `design/act2_script.md` (Scenes 1-4)
- Room pattern: `scripts/customs_shack_room.gd`
- CutscenePlayer: `scripts/cutscene_player.gd`
- Prop generation: `generate_props.py`
- Scene template: `scenes/rooms/customs_shack.tscn`
