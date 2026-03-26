# TERMINAL 3: Act 2 Second Half (Rooms 13-15 + Act 2 Finale)
# STATUS: NOT STARTED
# CLAIMED BY: (write your terminal ID here when you start)

## Instructions
1. Read `design/act2_script.md` Scenes 5-7 for full dialogue and puzzle design
2. Read `scripts/customs_shack_room.gd` as the reference pattern for room scripts
3. Copy `scenes/rooms/customs_shack.tscn` as template for each new room scene
4. New NPCs: Bram Kett (Room 13). Sprites at `assets/characters/bram/`
5. Room 15 is the HEAVIEST room in Act 2 (2 puzzles + 2 cutscenes + Rook confrontation)

## Task List

### Pre-Work: Act 2 Art Generation (Rooms 13-15)
- [ ] Generate ~15 prop sprites for Rooms 13-15 using Gemini API:
  - Room 13: Airship (Patient Gull), mooring winch, fuel gauge, stabilizer parts
  - Room 14: Fallen statue, brass scaffolding, camp notes, lantern, foil reflector, rotating panels
  - Room 15: Huge circular door, compass mechanism, split civic crest, archive node, ring assembly, transit shutter
- [ ] Generate ~7 inventory icons for Act 2 second-half items:
  - Second relay core, aerial transit prism, white civic signet half
  - Council strip, mooring wire, valve pin, foil reflector

### Room 13 — Ironwind Air Dock
- [ ] Create `scripts/ironwind_airdock_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/ironwind_airdock.tscn`
- [ ] Background: `act2_05_ironwind_airdock.png`
- [ ] NEW NPC: Bram Kett (`assets/characters/bram/`) — disgraced pilot
- [ ] Props: The Patient Gull (airship), mooring winch, fuel gauge, stabilizer
- [ ] Puzzle 5: Convince Bram to Fly (show route map → repair stabilizer → correct dialogue: "Rook will get there first")
- [ ] Bram dialogue tree (3 branches: need pilot, can pay, historic mission)
- [ ] Aerial Transit cutscene (Patient Gull flight, Rook pursuit in black-hulled airship)
- [ ] Room transitions: back to Sunken Waystation, forward to Fogwound Ruins
- [ ] Look/Talk/Pick up/Use handlers for all objects

### Room 14 — Fogwound Ruins Outer Court
- [ ] Create `scripts/fogwound_ruins_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/fogwound_ruins.tscn`
- [ ] Background: `act2_06_fogwound_ruins.png`
- [ ] Props: Fallen statue, brass scaffolding, camp notes, lantern, foil reflector, rotating panels
- [ ] Puzzle 6: Bypass Excavation Gate (position lantern → add foil reflector → arrange rods → cast symbol shadow on 3 panels → hidden passage)
- [ ] Easter egg: Wrong arrangement casts duck silhouette
- [ ] Room transitions: back to Air Dock, forward to Transit Vault
- [ ] Look/Talk/Pick up/Use handlers for all objects

### Room 15 — Ruins Transit Vault (HEAVIEST ROOM IN ACT 2)
- [ ] Create `scripts/transit_vault_room.gd` extending AdventureRoom
- [ ] Create `scenes/rooms/transit_vault.tscn`
- [ ] Background: `act2_07_transit_vault.png`
- [ ] Props: Huge circular door, compass mechanism, split civic crest, archive node, ring assembly
- [ ] Puzzle 7: Reconcile Split Crest (map plate → sigil fragment → council strip → tone cylinder replay → rotate rings → relay key)
- [ ] Archive Revelation cutscene (council argument projection, Rowan's father, mother's final line)
- [ ] Rook confrontation dialogue ("Hand over the key...")
- [ ] Puzzle 8: Escape the Vault (aerial transit prism → compass rotation → overload light → Tibbit pulls lever → transit shutter → maintenance conduit)
- [ ] Act 2 ending cutscene (ridge at dawn, Marrow's reveal about being Rowan's guardian, island glimpse)
- [ ] Room transitions: forward to Act 3 opener
- [ ] Look/Talk/Pick up/Use handlers for all objects
- [ ] NOTE: Ring rotation mechanic may need engine extension (discuss with Terminal 4)

## Key References
- Act 2 script: `design/act2_script.md` (Scenes 5-7)
- Room pattern: `scripts/customs_shack_room.gd`
- CutscenePlayer: `scripts/cutscene_player.gd`
- Prop generation: `generate_props.py`
- Scene template: `scenes/rooms/customs_shack.tscn`
