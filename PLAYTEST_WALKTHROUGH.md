# The Iron Wake -- Complete Playtest Walkthrough

> This walkthrough is derived directly from the GDScript room code, not the design docs.
> Every step below references actual `_on_use_item`, `_pick_up`, `_use`, `_talk_to`,
> `_look_at`, and dialogue tree logic as implemented. Items, flags, and transitions
> are the ground truth.
>
> **Controls reminder:**
> - Select a VERB (Look at, Talk to, Pick up, Use, Open, Push) then click an object.
> - RIGHT CLICK to quick-examine anything.
> - ENTER or SPACE to advance dialogue.
> - Click items in INVENTORY to select them, then click a target object to use them on it.

---

## ACT 1: THE THING THE TIDE BROUGHT IN

---

### ROOM 1: Blackwake Harbor Shore (`beach_room.gd`)

**On entry:** Intro cutscene plays automatically (Pindle, Tibbit, Rowan exchange).
Controls tutorial overlay appears -- click or press ENTER/SPACE to dismiss.
You receive the **Medallion** automatically at room start.

#### Puzzle 1: Activate the Relic

**Step 1 -- Examine the area (optional but recommended)**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 1 | Look at | Ancient Relic | "Smooth, seamless, and smug..." + "There's a circular recess packed with wet sand..." (sets `examined:relic_recess`) |
| 2 | Look at | Crowd | "Opportunists, mystics..." + "A fishmonger near the front looks particularly territorial." (sets `examined:fishmonger`) |
| 3 | Look at | Warning Placard | "'NO UNAUTHORIZED RESONANCE EVENTS.'" |

**Step 2 -- Pick up the Spyglass**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 4 | Pick up | SpyglassCrate | "A cracked spyglass. Might still focus enough light to be useful." Receive **Spyglass**. Crate hides. |

> Alternative: **Open** the SpyglassCrate also works and gives the spyglass.

**Step 3 -- Use Spyglass on Relic (dry the sand)**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 5 | (Select Spyglass in inventory) | spyglass | Ancient Relic | "The cracked lens focuses the morning sun onto the wet sand... It starts to dry and crack." (sets flag `relic_dried`) |

**Step 4 -- Distract Pindle (provoke the Fishmonger)**

| # | Verb | Target | Dialogue Choice | Expected Result |
|---|------|--------|----------------|-----------------|
| 6 | Talk to | Crowd | "Provoke the fishmonger" | Rowan says "Excuse me -- didn't this relic land right on your fish stall?" etc. "The fishmonger storms over to Pindle." (sets flag `pindle_distracted`) |
| 7 | -- | -- | -- | Game says: "Pindle's stamp is sitting unattended on his crate. Interesting." StampProp appears. |

**Step 5 -- Steal the Stamp**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 8 | Pick up | StampProp | "I grab the stamp while Pindle's busy arguing." Receive **Stamp**. |

**Step 6 -- Use Stamp on Relic (scrape dried sand)**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 9 | (Select Stamp in inventory) | stamp | Ancient Relic | "The flat edge of the stamp handle scrapes the dried sand out... Underneath: a circular groove with geometric patterns." (sets flag `recess_scraped`) |

**Step 7 -- Insert Medallion**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 10 | (Select Medallion in inventory) | medallion | Ancient Relic | "The medallion slides into the groove with a satisfying click." Tibbit reacts. (sets flag `medallion_inserted`, Medallion consumed) |

**Step 8 -- Pull Steam Valve**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 11 | Use | Steam Valve | Relic activation cutscene fires: memory vision plays (white flash, childhood memories). Receive **Brass Strip**. Tibbit says to check the warehouse. (sets flags `relic_activated`, `need_permit`) |

> **Wrong order catches:** Using Steam Valve before medallion: "The valve blares... Nothing else happens." / Using Medallion before scraping: "I'm not grinding a mystery heirloom into dried sand." / Using Spyglass after already dry: "The sand is already dry."

**Exit to Customs Shack:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 12 | Use | CustomsShack | Transitions to Customs Shack (only works AFTER you have fake_permit; otherwise "That shack is for authorized personnel") |

> **NOTE:** You need to forge the permit first. The Customs Shack door from the beach only opens once you have the permit. Go there using the fake_permit on the CustomsShack hotspot.

---

### ROOM 2: Customs Shack (`customs_shack_room.gd`)

**On entry:** Intro plays: Pindle argues about the restricted closet.

#### Puzzle 2: Forge a Permit

**Step 1 -- Study the jargon**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 13 | Look at | PermitLedger | "A ledger of permits issued..." + "The jargon on these forms is impressively meaningless." (sets flag `read_ledger`) |
| 14 | Look at | WallNotices | "'ALL SALVAGE MUST BE DECLARED...'" + "The circular logic is almost beautiful." (sets flag `read_notices`) |

**Step 2 -- Distract Pindle (in office)**

| # | Verb | Target | Dialogue Choice | Expected Result |
|---|------|--------|----------------|-----------------|
| 15 | Talk to | PindleDesk | "Distract him" | Rowan says "Is that a discrepancy in your stamp log?" Pindle panics and checks entries. (sets flag `pindle_distracted`) |

> Note: If Pindle was already distracted at the beach, this choice may not appear. The "Distract him" dialogue has `condition_not_flag: "pindle_distracted"`.

**Step 3 -- Grab a blank form**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 16 | Pick up | BlankForms | "I slide a blank form off the stack while Pindle argues with his stamp." Receive **Blank Form**. (Requires `pindle_distracted` flag) |

**Step 4 -- Fill in the form using the ledger**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 17 | (Select blank_form) | blank_form | PermitLedger | "I copy the jargon from the ledger onto the blank form. 'Pursuant to Article 7, Section Nothing...'" Blank Form consumed, receive **Filled Form**. (Requires BOTH `read_ledger` AND `read_notices` flags) |

> If you haven't looked at both the ledger AND the wall notices: "I need to study the proper jargon first."

**Step 5 -- Seal the form**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 18 | (Select filled_form) | filled_form | SealPress | "I press the seal into wax on the form. A perfect Blackwake crest." Filled Form consumed, receive **Fake Permit**. (sets flag `has_permit`) |

> Alternative: **Use** the SealPress directly (while holding filled_form) also works.

**Exit back to Harbor:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 19 | Use | DoorOut | Returns to Blackwake Harbor (main.tscn = beach) |

---

### Returning to Harbor Shore (with permit)

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 20 | Use (or Open) | CustomsShack | Now that you have the permit, transitions to Customs Shack |

> OR: Use the fake_permit inventory item on CustomsShack: "Let's see if Pindle respects his own paperwork." Sets `has_permit` and transitions.

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 21 | Use | Docks | "Time to check the salvage warehouse." Transitions to Salvage Warehouse. (Requires `has_permit`) |

---

### ROOM 3: Salvage Warehouse (`salvage_warehouse_room.gd`)

**On entry:** Intro cutscene plays: Rowan explores, brass strip matches the symbol board (if you have it), then **Commodore Rook** appears for the first time. Full confrontation dialogue plays automatically. (sets flags `lighthouse_discovered`, `met_rook`)

#### Items to collect (no puzzle -- exploration room)

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 22 | Pick up | BlackShard | "I pocket the shard. It hums faintly, like a tuning fork with opinions." Receive **Black Shard**. |
| 23 | Pick up | AutomatonHand | "I take the hand. It's heavier than expected and disturbingly warm." Receive **Automaton Hand**. |
| 24 | Open | LighthouseCrate | "The crate is empty -- just straw packing and a label. The lens housing was moved already." + "Someone wanted that lens. Recently." (sets flag `lighthouse_crate_opened`) |

**Exit to Brass Bazaar:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 25 | Use (or Open) | DoorBazaar | Transitions to Brass Bazaar |

---

### ROOM 4: The Brass Bazaar (`brass_bazaar_room.gd`)

**On entry:** Mirelle greets you: "Welcome to Soot and Sundries. Buy quickly, doubt later."

#### Puzzle 3: The Bazaar Bluff

**Step 1 -- Gather the props**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 26 | Pick up | GuildBadge | "I pocket the badge. It's broken, but confidence is a glue." Receive **Guild Badge**. |
| 27 | Pick up | FancyTeacup | "I borrow the teacup." Receive **Fancy Teacup**. |

**Step 2 -- Learn the jargon**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 28 | Look at | NobleStall | "Two well-dressed merchants haggle..." + "I catch phrases: 'Third Conservatory Circle,' 'provisional survey class,' 'preservation review.'" (sets flags `eavesdropped`, `heard_jargon`) |

> Alternative: The MechParrot sometimes squawks jargon lines containing "CONSERVATORY" or "SURVEY", which also sets `heard_jargon`. But the NobleStall eavesdrop is guaranteed.

**Step 3 -- Execute the bluff**

You need ALL THREE: Guild Badge + Fancy Teacup (in inventory) + `heard_jargon` flag.

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 29 | (Select guild_badge) | guild_badge | MirelleNPC | Bluff sequence triggers: "Third Conservatory Circle. Provisional survey class..." Mirelle laughs. Guild Badge and Fancy Teacup consumed. Receive **Focusing Disc**. (sets flag `got_focusing_disc`) |

> Alternative: **Use** MirelleNPC directly (no item selected) also triggers the bluff if `_can_bluff()` returns true (all 3 conditions met).

> **Wrong approach:** Using guild_badge on Mirelle without jargon: "That badge is upside down and from a stove manufacturer."

**Exit to Tibbit's Workshop:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 30 | Use (or Open) | DoorWorkshop | Transitions to Tibbit's Workshop |

---

### ROOM 5: Tibbit's Workshop Cart (`tibbit_workshop_room.gd`)

**On entry:** Tibbit greets you with typical chaos.

#### Puzzle 4: Assemble the Memory Lens

**Step 1 -- Collect components**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 31 | Pick up | ClockSpring | "I carefully pocket the clock spring. It vibrates faintly." Receive **Clock Spring**. |
| 32 | Pick up | LensFrame | "I take the lens frame from the bench." Receive **Lens Frame**. |

> Optional: Pick up Whistle ("I take the whistle.") -- used later in Act 3.

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 33 | Pick up | Whistle | Receive **Whistle**. (Not needed for this puzzle, but needed in Mountain Breach) |

**Step 2 -- Assemble on the workbench**

You need: **Lens Frame** + **Focusing Disc** + **Clock Spring** (all three in inventory).

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 34 | Use | Workbench | "I set the components on the workbench..." Tibbit assembles them. "The lens emits a soft note." / "Why did it whistle." / "Atmosphere." All three items consumed. Receive **Memory Lens**. (sets flag `lens_assembled`) |

> Alternative: Use any of the three component items on the Workbench -- if all three are in inventory, it triggers assembly.

> **Wrong combination:** Using Whistle on Workbench: "No. Memory does not need an entrance theme." / "Counterpoint: everything improves with one."

**Exit to Harbor Cliffs:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 35 | Use (or Open) | DoorCliffs | Transitions to Harbor Cliffs |

---

### ROOM 6: Harbor Cliffs Path (`harbor_cliffs_room.gd`)

**On entry:** Wind description. First meeting with **Marrow Quill**: "You came quickly." / "I dislike being expected by strangers." / "Then you will dislike the rest of this story." (sets flag `met_marrow`)

#### Exploration and Dialogue (no puzzle)

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 36 | Talk to | MarrowNPC | Dialogue tree with options: "Who are you?" / "What do you know about the relic?" / "Why are you waiting here?" |
| 37 | Look at | BoundaryStone1 | "Ancient carved stone..." + "Same symbol family as the relic." (sets flag `examined_boundary_stone`) |

**Exit to Lighthouse Exterior:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 38 | Use | DoorLighthouse | Transitions to Lighthouse Exterior |

---

### ROOM 7: Hushlight Lighthouse Exterior (`lighthouse_exterior_room.gd`)

**On entry:** Description + Marrow greeting. (sets flag `met_marrow`)

#### Puzzle 5: Open the Lighthouse Door

**Step 1 -- Collect salt paste**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 39 | Pick up | SaltDeposits | "I scrape the mineral deposits into a crude paste. Gritty, conductive, and deeply unpleasant." Receive **Salt Paste**. Salt deposits hide. |

**Step 2 -- Apply salt paste to grooves**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 40 | (Select salt_paste) | salt_paste | ConductiveGrooves | "I smear the salt paste into the grooves." (sets flag `grooves_filled`) |

> Alternative: Using salt_paste on LighthouseDoor also works.

**Step 3 -- Insert brass strip**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 41 | (Select brass_strip) | brass_strip | LighthouseDoor | "I slide the engraved strip into the slot above the door. It clicks into place." (sets flag `strip_inserted`; requires `grooves_filled`) |

> Alternative: Using brass_strip on ConductiveGrooves also works (if grooves are filled).

**Step 4 -- Turn the beacon crank**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 42 | Use | BeaconCrank | "I turn the crank... A deep hum rises through the tower." Marrow: "It still knows the route." Door opens. (sets flag `door_opened`) |

> **Requires BOTH** `grooves_filled` AND `strip_inserted`.

**Step 5 -- Enter the lighthouse**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 43 | Use (or Open) | LighthouseDoor | Transitions to Lighthouse Chamber |

---

### ROOM 8: Hushlight Lighthouse Main Chamber (`lighthouse_chamber_room.gd`)

**On entry:** Description of circular chamber. Marrow: "The chamber remembers what the town forgot."

#### Puzzle 6: Align the Lens

**Step 1 -- Open the shutters**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 44 | Use (or Open) | WindowShutters | "I wrench the shutters open. Sunset light floods the chamber." (sets flag `shutters_open`) |

**Step 2 -- Install the Memory Lens**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 45 | (Select memory_lens) | memory_lens | LensPedestal | "I place the Memory Lens into the pedestal mount. It clicks into place." Memory Lens consumed. (sets flag `lens_installed`) |

**Step 3 -- Align the beacon mirrors**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 46 | Use | BeaconControls | "I adjust the mirrors. Light bounces between them... I rotate until the light locks into the mural pattern." (sets flag `mirrors_aligned`; requires `shutters_open` AND `lens_installed`) |

**Step 4 -- Insert brass strip as selector key**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 47 | (Select brass_strip) | brass_strip | BeaconControls | "I slide the brass strip into the selector slot... The symbols align. The beam sharpens. The mural begins to glow." Brass Strip consumed. (sets flag `lens_aligned`; requires `mirrors_aligned`) |

#### ACT 1 CLIMAX -- Second Memory Vision (automatic)

The memory vision triggers immediately after step 47:
- Chamber darkens, Wake Road pattern revealed
- Marrow: "The Wake Road."
- Vision: Father and Mother speak. Alarm bells. Island. Darkness.
- Post-vision: "I remember them. I was there. That island is real."
- Receive **Relay Key** + **Map Plate** (sets flags `act1_vision_complete`)
- Act 1 ending cutscene: Rook pounds on the door. Marrow directs escape. Tibbit wants lunch.
- (sets flag `act1_complete`)
- **Fade to END OF ACT 1** -- returns to title screen.

---

## ACT 2: THE ROAD BENEATH THE WORLD

---

### ROOM 9: Undercliff Smuggler Path (`smuggler_path_room.gd`)

**On entry:** Act 2 opening cutscene: Tibbit and Rowan check the Map Plate. (sets flag `act2_intro_seen`)

#### Puzzle 1: Cross the Tide Bridge

**Step 1 -- Examine the lift and get bottles**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 48 | Look at | CliffLift | "Held together by rope, optimism, and previous owners' lies." + "The counterweight basket is empty." (sets flag `examined_lift`) |
| 49 | Pick up (or Open) | ContrabandCrate | "I pry open the rotten wood. Inside: dense ceramic bottles. Heavy. Perfect ballast." Receive **Ceramic Bottles**. (sets flag `opened_crate`) |

**Step 2 -- Load bottles into lift**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 50 | (Select ceramic_bottles) | ceramic_bottles | CliffLift | "I load the heavy ceramic bottles into the lift basket. Good ballast." Bottles consumed. (sets flag `lift_loaded`) |

**Step 3 -- Redirect the line**

> **NOTE:** The code checks for `coil_line` item. This item is referenced in the design doc as Tibbit's coil line. It is NOT given via `give_item` in any room script. This appears to be an **unimplemented item**. The code also does not provide an alternative. **POTENTIAL BLOCKER:** You may need a `coil_line` item that is not obtainable in the current build.

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 51 | (Select coil_line) | coil_line | CliffLift | "I hook the coil line to the lift cable and redirect it toward the bridge tension system." (sets flag `line_redirected`; requires `lift_loaded`) |

**Step 4 -- Lock the line**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 52 | (Select coil_line) | coil_line | SignalLantern | "I use the lantern's shutter bracket to lock the redirected line in place. Solid." (sets flag `line_locked`; requires `line_redirected`) |

**Step 5 -- Activate the lift**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 53 | Use | CliffLift | "The lift descends. The cable tightens. The bridge groans... and holds." Ancient markings revealed. Tibbit comments. (sets flag `bridge_crossed`; PathForward appears) |

> **Requires ALL THREE:** `lift_loaded` + `line_redirected` + `line_locked`

**Exit to Brackmarsh:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 54 | Use | PathForward (or RopeBridge) | Transitions to The Brackmarsh |

---

### ROOM 10: The Brackmarsh (`brackmarsh_room.gd`)

**On entry:** Fog and marsh. Sister Caligo greets you: "Travelers usually come here to disappear." (sets flag `met_caligo`)

#### Puzzle 2: Navigate the Mirror Fog

**Step 1 -- Examine the standing mirrors**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 55 | Look at | StandingMirror1 (or 2 or 3) | "Black glass panels sunk in the mud..." + "Not mirrors. Markers. They can be rotated." (sets flag `examined_mirrors`) |

**Step 2 -- Get the chapel hand mirror from Caligo**

| # | Verb | Target | Dialogue Choice | Expected Result |
|---|------|--------|----------------|-----------------|
| 56 | Talk to | CaligoNPC | "I need a hand mirror" | (Only appears if `examined_mirrors` flag is set.) Caligo: "The chapel mirror? Take it." Receive **Chapel Hand Mirror**. (sets flag `has_chapel_mirror`) |

> If the "I need a hand mirror" option does not appear, make sure you have examined the mirrors first (step 55).

**Step 3 -- Ring the bell softly**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 57 | Use | BellRope | "I give the bell a gentle pull. A soft tone rings out... One of the standing markers vibrates. The first one." (sets flags `bell_rung_soft`, `first_marker_found`; requires `examined_mirrors`) |

> **Wrong order (without examining mirrors):** "I yank the bell rope. The marsh erupts with birds. A mud vent explodes." Caligo: "Congratulations. You have summoned every creature except wisdom."

**Step 4 -- Rotate the markers**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 58 | Use | StandingMirror1 (or 2 or 3) | "I use the rusted bar to rotate each marker toward the next. They grind into alignment." (sets flag `markers_rotated`; requires `first_marker_found`) |

**Step 5 -- Use hand mirror to reveal the path**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 59 | (Select chapel_hand_mirror) | chapel_hand_mirror | StandingMirror1 (or 2 or 3) | "I hold the hand mirror up. Light catches, refracts through the aligned markers. The fog parts like a curtain. A black stone tower rises from the marsh." (sets flag `fog_cleared`; PathForward appears; requires `markers_rotated`) |

**Exit to Relay Tower:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 60 | Use | PathForward | Transitions to The First Relay Tower |

---

### ROOM 11: The First Relay Tower (`relay_tower_room.gd`)

**On entry:** Tower description. Tibbit: "Now THAT is architecture with opinions."

#### Puzzle 3: Restore the Harmonic Circuit

You need 3 conductor rods for the 3 sockets. The code accepts:
- `brass_curtain_rod` -- **NOT obtainable via give_item in any current script.** Caligo dialogue mentions it in design doc but it is not implemented as a gettable item. **POTENTIAL BLOCKER.**
- `copper_wire` -- listed in inventory icon names but **not given by any give_item call.** **POTENTIAL BLOCKER.**
- `automaton_hand` -- obtained in Salvage Warehouse (step 23).

> **NOTE:** In the current build, only the **Automaton Hand** is obtainable. The `brass_curtain_rod` and `copper_wire` items do not have `give_item` calls in any room script. This puzzle may be **partially blocked** in the current build. The walkthrough below assumes these items exist.

**Step 1 -- Insert conductors into sockets**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 61 | (Select brass_curtain_rod) | brass_curtain_rod | Socket1 (or 2 or 3) | "The brass curtain rod slides into the socket." Rod consumed. (sets flag `socket_rod`) |
| 62 | (Select copper_wire) | copper_wire | Socket1 (or 2 or 3) | "I twist the wire and reeds into a makeshift conductor." Wire consumed. (sets flag `socket_wire`) |
| 63 | (Select automaton_hand) | automaton_hand | Socket1 (or 2 or 3) | "The automaton finger slides in with mechanical precision." Hand consumed. (sets flag `socket_finger`) |

**Step 2 -- Insert Relay Key**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 64 | (Select relay_key) | relay_key | RelayPedestal | "I insert the Relay Key into the central interface. It turns with a satisfying click." (sets flag `relay_key_inserted`; requires 3 sockets filled) |

**Step 3 -- Activate the tower**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 65 | Use | RelayPedestal | "The pedestal hums. The tone forks await calibration... I match the sequence..." Tones align. Tower activation cutscene fires. (sets flag `tone_matched`) |

#### Memory Vision 3 (automatic)

- Lesson hall vision plays. Instructor teaches about relay harmony.
- Tower beam shoots skyward.
- Receive **Transit Sigil Fragment** + **Tone Cylinder**.
- (sets flags `relay_tower_activated`, `memory_vision_3`)
- PathForward appears.

**Exit to Sunken Waystation:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 66 | Use | PathForward | Transitions to The Sunken Waystation |

---

### ROOM 12: The Sunken Waystation (`sunken_waystation_room.gd`)

**On entry:** Tibbit admires the ancient waiting room.

#### Puzzle 4: Make the Waystation Talk

**Step 1 -- Pump out the water**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 67 | Use | PumpMechanism | "I work the pump handle. Water drains from the lower chamber, revealing the map contacts." (sets flag `water_pumped`) |

**Step 2 -- Dry the contacts**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 68 | Use | MapContacts | "I dry the exposed contacts with my sleeve. They spark faintly." (sets flag `contacts_dried`; requires `water_pumped`) |

**Step 3 -- Insert Tone Cylinder**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 69 | (Select tone_cylinder) | tone_cylinder | TransitMapArch | "I insert the Tone Cylinder into the arch's input port." (sets flag `cylinder_inserted`; requires `contacts_dried`) |

**Step 4 -- Insert Sigil Fragment in ticket slot**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 70 | (Select transit_sigil_fragment) | transit_sigil_fragment | TicketSlot | "The Sigil Fragment slides into the ticket slot. The arch brightens." (sets flag `sigil_inserted`) |

> **Wrong item in ticket slot:** "I've just attempted to board an ancient transit system with a [item]. I want credit for initiative."

**Step 5 -- Reconnect the signal wire**

> **NOTE:** The code accepts `coil_line` or `copper_wire`. Same potential blocker as before. If you do not have either, this step is blocked.

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 71 | (Select copper_wire or coil_line) | copper_wire | SignalWire | "I splice the wire using Tibbit's coil clip. The connection holds." Tibbit: "Ugly but functional. My motto." (sets flag `wire_reconnected`) |

#### Waystation Activation (automatic if all 5 flags set)

If all conditions are met (`water_pumped` + `contacts_dried` + `cylinder_inserted` + `sigil_inserted` + `wire_reconnected`), activation triggers automatically:
- Recorded voice plays. Message strip ejects.
- Receive **Message Strip**.
- "There were factions." / Tibbit: "No civilization ever gets shiny enough to outgrow politics."
- (sets flag `waystation_activated`; PathForward appears)

**Exit to Ironwind Air Dock:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 72 | Use | PathForward | Transitions to Ironwind Air Dock |

---

### ROOM 13: Ironwind Air Dock (`ironwind_airdock_room.gd`)

**On entry:** First meeting with **Bram Kett**: "No." / "We haven't asked anything yet." / "Experience." (sets flag `met_bram`)

#### Puzzle 5: Convince Bram to Fly

**Step 1 -- Show Bram the map**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 73 | (Select map_plate) | map_plate | BramNPC | "I show Bram the glowing map. His eyes widen." Bram: "That's real. That's an actual ancient route." (sets flag `showed_bram_map`) |

**Step 2 -- Use the right dialogue**

| # | Verb | Target | Dialogue Choice | Expected Result |
|---|------|--------|----------------|-----------------|
| 74 | Talk to | BramNPC | "Rook will get there first" | (Only visible after `showed_bram_map`.) Rowan: "Rook will get there first if you stay here brooding." Bram: "That oily peacock? Fine. I'll fly." (sets flag `bram_convinced`) |

**Step 3 -- Repair the stabilizer**

The stabilizer needs three steps in order: wire, pin, clamp.

> **NOTE:** These items (`copper_wire`/`coil_line`, `valve_pin`/`brass_key`, `coil_clamp`/`broken_gear`) may not all be obtainable. The code accepts alternatives for each step.

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 75 | (Select copper_wire or coil_line) | copper_wire | Stabilizer | "I thread the wire through the broken linkage." (sets flag `stabilizer_wire`) |
| 76 | (Select valve_pin or brass_key) | valve_pin | Stabilizer | "The pin slides through the linkage. One more piece -- a clamp." (sets flag `stabilizer_pinned`; requires `stabilizer_wire`) |
| 77 | (Select coil_clamp or broken_gear) | coil_clamp | Stabilizer | "I clamp everything tight. The stabilizer linkage holds." Tibbit: "I'm calling it the Portable Coil of Selective Certainty." (sets flag `stabilizer_repaired`; requires `stabilizer_wire` + `stabilizer_pinned`) |

**Step 4 -- Board the airship**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 78 | Use | PatientGull | Aerial transit cutscene: Gull lifts off. Rook's airship appears behind. "He followed us." / Bram: "Villains never navigate. They pursue." (sets flag `aerial_transit_complete`; auto-transitions to Fogwound Ruins) |

> **Requires BOTH** `bram_convinced` AND `stabilizer_repaired`.

---

### ROOM 14: Fogwound Ruins Outer Court (`fogwound_ruins_room.gd`)

**On entry:** Ruins description. Bram stays with the ship. (sets flag `fogwound_intro`)

#### Puzzle 6: Bypass the Excavation Gate (Shadow Puzzle)

**Step 1 -- Read Rook's camp note**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 79 | Look at | CampNote | "'Subject site exhibits sealed transit logic...' + 'Light-lock sequence not yet solved. Team reports intermittent shadow responses from panels.'" (sets flag `read_camp_note`; note hides) |

**Step 2 -- Place lantern on plinth**

> **NOTE:** The code checks for `lantern` or `signal_lantern`. Neither is given via `give_item` in any room. **POTENTIAL BLOCKER.** However, the `chapel_hand_mirror` can also be used as the reflector (step 3).

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 80 | (Select lantern) | lantern | LanternPlinth | "I set the lantern on the plinth. It casts a beam toward the panels." (sets flag `lantern_placed`) |

**Step 3 -- Add reflector**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 81 | (Select chapel_hand_mirror or foil_reflector) | chapel_hand_mirror | LanternPlinth (or RodsFrame) | "I position the reflector behind the lantern. The light intensifies and focuses." (sets flag `reflector_placed`; requires `lantern_placed`) |

**Step 4 -- Arrange the rods**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 82 | Use | RodsFrame | "I arrange the rods and frame between the lantern and the panels. The amplified light casts a crisp symbol shadow onto the rotating panels." (sets flag `rods_arranged`; requires `lantern_placed` + `reflector_placed`) |

**Step 5 -- Rotate the panels**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 83 | Use | RotatingPanels | "I rotate the panels to match the shadow... The symbols align. Stone grinds. A hidden passage opens in the side wall." (sets flag `excavation_gate_open`; PathForward appears; requires `lantern_placed` + `reflector_placed` + `rods_arranged`) |

**Exit to Transit Vault:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 84 | Use | PathForward | Transitions to Transit Vault |

---

### ROOM 15: Ruins Transit Vault (`transit_vault_room.gd`)

**On entry:** Pristine chamber. Tibbit: "This place was built to last forever. Which makes it deeply suspicious."

#### Puzzle 7: Reconcile the Split Crest

**Step 1 -- Insert Map Plate into compass**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 85 | (Select map_plate) | map_plate | CompassMechanism | "The Map Plate slides into the transit compass. Routes illuminate." (sets flag `map_plate_inserted`) |

**Step 2 -- Place Sigil Fragment in crest**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 86 | (Select transit_sigil_fragment) | transit_sigil_fragment | CompassMechanism | "The Sigil Fragment clicks into the missing slot of the split crest." (sets flag `sigil_placed_vault`) |

**Step 3 -- Insert Tone Cylinder**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 87 | (Select tone_cylinder) | tone_cylinder | CompassMechanism | "I insert the Tone Cylinder. Two overlapping melodies fill the chamber." (sets flag `tones_playing`) |

**Step 4 -- Retrieve opposing seal from archive**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 88 | (Select message_strip) | message_strip | ArchiveNode | "I feed the Council Strip into the archive node... The opposing faction's seal materializes." (sets flag `council_seal_retrieved`) |

**Step 5 -- Harmonize the ring assembly**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 89 | Use | RingAssembly | "I rotate the rings. The two tone patterns shift... overlap... and harmonize." (sets flag `rings_harmonized`; requires `tones_playing` + `council_seal_retrieved`) |

**Step 6 -- Insert Relay Key to confirm**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 90 | (Select relay_key) | relay_key | KeyInterface | "I insert the Relay Key. It turns. The mechanism accepts." (sets flag `crest_reconciled`) |

> Alternative: **Use** KeyInterface directly also works if `_puzzle_ready()` returns true.

#### Archive Revelation + Escape (automatic cutscene)

After step 90, the following plays automatically:
- Archive projection: Western and Eastern councilors argue. Father speaks. Mother says to send the child away.
- Tibbit: "You weren't lost." / Rowan: "No." / "You were hidden." / "Yes."
- Receive **Second Relay Core** + **Aerial Transit Prism** + **White Civic Signet Half**.
- Rook confrontation: "Magnificent. I do so appreciate arriving after the difficult part."
- Automatic escape sequence: prism, compass, lever, transit shutter.
- "This is temporary." / "That's true of all disappointing men."
- Act 2 ending narration. Marrow on the ridge. Final offshore marker visible.
- **END OF ACT 2**
- Auto-transitions to Cinderglass Valley (Act 3).

---

## ACT 3: THE SEA REMEMBERS

---

### ROOM 16: Cinderglass Valley (`cinderglass_valley_room.gd`)

**On entry:** Tibbit, Bram commentary. Bram anchors the Gull. (sets flag `act3_intro`)

#### Puzzle 1: Cross the Steam Terrace

**Step 1 -- Pick up reflective cinderglass**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 91 | Pick up | GlassOutcrop | "I snap off a flat piece. Reflective as a mirror." Receive **Reflective Cinderglass**. |

**Step 2 -- Redirect the vents**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 92 | Use | VentWheels | "I turn the wheel. One vent bank closes, another opens. The steam pattern shifts." (sets flag `vents_redirected`) |

**Step 3 -- Prop the heat shutter**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 93 | (Select coil_clamp or broken_gear) | coil_clamp | HeatShutters | "I prop the shutter open with the clamp. Steam diverts cleanly." (sets flag `shutter_propped`; requires `vents_redirected`) |

**Step 4 -- Use cinderglass to spot safe window**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 94 | (Select reflective_cinderglass) | reflective_cinderglass | WarningBells (or VentWheels) | "I angle the cinderglass to spot the safe rhythm... a three-second window. I cross." (sets flag `terrace_crossed`; PathForward appears; requires `shutter_propped`) |

**Exit to Mountain Breach:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 95 | Use | PathForward | Transitions to The Mountain Breach |

---

### ROOM 17: The Mountain Breach (`mountain_breach_room.gd`)

**On entry:** Rook's scaffolding. Tibbit: "He's been here. Recently." / "From the perfume of money and violation."

#### Puzzle 2: Open the Maintenance Hatch

**Step 1 -- Pick up scaffold pipe**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 96 | Pick up | ScaffoldPipe | "I wrench the pipe free. Hollow -- good resonance." Receive **Scaffold Pipe**. |

**Step 2 -- Insert Tone Cylinder in auxiliary panel**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 97 | (Select tone_cylinder) | tone_cylinder | AuxiliaryPanel | "I insert the Tone Cylinder. A broken playback pattern fills the chamber." (sets flag `cylinder_in_panel`) |

**Step 3 -- Produce the low note**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 98 | (Select scaffold_pipe) | scaffold_pipe | ResonatorPipes | "I use the scaffold pipe as a low-note resonator. The chamber vibrates." (sets flag `low_note`; requires `cylinder_in_panel`) |

> Alternative: **Use** ResonatorPipes directly (if you have scaffold_pipe in inventory and `cylinder_in_panel` set) also triggers this via the `_use` handler.

**Step 4 -- Produce the high note**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 99 | (Select whistle) | whistle | ResonatorPipes | "The whistle produces a perfect high note." (sets flag `high_note`; requires `low_note` already set, otherwise just "impressed a bird") |

> **IMPORTANT:** The high note only registers if the low note is done first. If you use the whistle before the scaffold pipe, you get: "We have not opened the hatch, but we may have impressed a particularly judgmental bird." and the flag is NOT set.

**Step 5 -- Align the prism**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 100 | (Select aerial_transit_prism) | aerial_transit_prism | ResonatorPipes | "I align the prism so the pulsing light matches the resonance beat." (sets flag `prism_aligned`; requires `low_note` + `high_note`) |

**Step 6 -- Trigger the full sequence**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 101 | Use | AuxiliaryPanel | "I trigger the full sequence. The resonance builds. The hatch shudders and opens." Tibbit loves the machines. (sets flag `hatch_open`; MaintenanceHatch appears; requires ALL: `cylinder_in_panel` + `low_note` + `high_note` + `prism_aligned`) |

**Exit to Undersea Transit:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 102 | Use (or Open) | MaintenanceHatch | Transitions to Undersea Transit Chamber |

---

### ROOM 18: Undersea Transit Chamber (`undersea_transit_room.gd`)

**On entry:** Immense station. Transit cradle. Tibbit: "A boat designed by someone who thought elegance should be waterproof."

#### Puzzle 3: Restore Final Relay Power

**Step 1 -- Insert Second Relay Core**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 103 | (Select second_relay_core) | second_relay_core | RelaySocket | "The Second Relay Core slides into place. Power surges." (sets flag `relay_core_inserted`) |

**Step 2 -- Link the harmonic bridge**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 104 | (Select copper_wire) | copper_wire | HarmonicBridge | "I place conductive links between the dead nodes. The bridge sparks to life." (sets flag `bridge_linked`; requires `relay_core_inserted`) |

**Step 3 -- Re-seat the light rails**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 105 | (Select insulated_gloves or oilskin_pouch) | oilskin_pouch | LightRails | "Using insulation, I re-seat the displaced light rails. They lock and glow." (sets flag `rails_seated`; requires `bridge_linked`) |

> When all three flags are set (`relay_core_inserted` + `bridge_linked` + `rails_seated`), the station powers up fully and the archive basin activates. (sets flag `relay_powered`)

**Step 4 -- Search the archive basin**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 106 | Use | ArchiveBasin | "I search the archive basin. A record surfaces: the missing signet half was entrusted to 'a warden of the gate.'" (sets flag `basin_searched`; requires `relay_powered`) |

**Marrow arrives (automatic):** She produces the missing signet half. "You had that." / "I had half of a decision." / "You are the most exhausting person I know." Receive **Complete Civic Signet**. (sets flag `has_complete_signet`)

#### Puzzle 4: Choose Wake Authorization

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 107 | Use | RouteConsole | Authorization dialogue tree appears. Three choices: |

| Dialogue Choice | Flag Set |
|----------------|----------|
| "Personal transit only" | `auth_personal` |
| "Authorized emergency transit" | `auth_emergency` (recommended) |
| "Open signal broadcast" | `auth_broadcast` |

All choices lead to: "Authorization accepted. Wake route initializing." (sets flag `wake_authorized`)

> Alternative: Use `complete_civic_signet` on RouteConsole also triggers this.

#### Puzzle 5: Launch the Transit Cradle

**Step 1 -- Set the prism in the cradle**

| # | Verb | Inventory Item | Target | Expected Result |
|---|------|---------------|--------|-----------------|
| 108 | (Select aerial_transit_prism) | aerial_transit_prism | TransitCradle | "I set the Aerial Transit Prism into the guidance arm. The cradle aligns." (sets flag `cradle_prepared`; requires `wake_authorized`) |

**Step 2 -- Release docking clamps**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 109 | Use | DockingClamps | Rook breach cutscene triggers. Full confrontation: "Clean energy. Transit beyond storms..." Then escape: clamps released, Tibbit holds override, Marrow topples bridge, leap into cradle. "Miss Vale!" / "Commodore!" / "This is not over!" / "You keep saying that like it's comforting!" Auto-transitions to Wake Passage. |

> **Requires BOTH** `wake_authorized` AND `cradle_prepared`.

---

### ROOM 19: Wake Sea Passage (`wake_passage_room.gd`)

**Entirely a cutscene -- no player interaction needed.**

On entry, the following plays automatically:
- Beautiful undersea transit description.
- Tibbit revises opinions on engineering. "Rivets remain excellent."
- Rowan confronts Marrow about her past. "Why didn't you tell me at the start?"
- Memory Vision 4: Night on the island. Panic. Mother sends child with young Marrow.
- "You were there. You took me away." / "I saved what I could."
- Gate of white stone opens. Light floods in.
- (sets flag `memory_vision_4`)
- Auto-transitions to Isle Auric.

---

### ROOM 20: Isle Auric (`isle_auric_room.gd`)

**On entry:** Extended cutscene:
- Tibbit: "That's intolerably lovely."
- Meet Archivist Sel, Warden Seraphine, Councilor Ilyan.
- Island truth revealed: harmony systems failing, road demands resolution.
- Rook forces entry. "What a magnificent place."
- (sets flags `island_truth_revealed`, `rook_at_island`)

#### Dialogue (recommended but not required to proceed)

| # | Verb | Target | Dialogue Choice | Expected Result |
|---|------|--------|----------------|-----------------|
| 110 | Talk to | SelNPC | "What do I need to do?" | Sel explains: Harmonic Gate needs 3 seals -- bloodline, warden, council. |
| 111 | Talk to | IlyanNPC | "Will you help at the gate?" | Ilyan agrees: "I will. But carefully." |
| 112 | Talk to | SeraphineNPC | "The island can't stay sealed forever" | Seraphine: "If you can convince me this will be controlled, I will place my seal." |

**Exit to Harmonic Gate:**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 113 | Use (or Open) | PathGate | Transitions to Central Harmonic Gate |

---

### ROOM 21: Central Harmonic Gate -- FINALE (`harmonic_gate_room.gd`)

**On entry:** "The island's core. Concentric white platforms open to the sky. Suspended resonance rings catch the light."

#### Puzzle 6: Rebuild Civic Harmony

**Step 1 -- Place medallion in bloodline socket**

> **NOTE:** The medallion was consumed in Act 1 (step 10) when inserted into the beach relic. The code checks `GameState.has_item("medallion")`. If the medallion was NOT returned to inventory after Act 1, this step may be **BLOCKED**. Check if the game re-gives it during Act 2/3 transitions.

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 114 | Use | BloodlineSocket | "I place the medallion -- my medallion -- into the bloodline socket. It glows." (sets flag `medallion_placed`; requires `medallion` in inventory) |

> Alternative: Use medallion inventory item on BloodlineSocket.

**Step 2 -- Convince Seraphine**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 115 | Talk to | WardenStation | "You protected this place by closing it. I understand that. But a locked gate is still a gate." Seraphine: "...Very well. I commit the warden seal." (sets flag `seraphine_convinced`) |

**Step 3 -- Convince Ilyan**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 116 | Talk to | CouncilStation | "If you reopen the road carelessly, you prove every fear that closed it." Ilyan: "You sound like your father... I commit the council seal." (sets flag `ilyan_convinced`) |

**Step 4 -- Unlock ring calibration (Sel)**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 117 | Talk to | ArchiveTerminal | Sel: "All three voices present. I unlock ring calibration." (sets flag `sel_calibrated`; requires BOTH `seraphine_convinced` + `ilyan_convinced`) |

**Step 5 -- Tune the resonance rings**

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 118 | Use | ResonanceRings | Tibbit: "Allow me. This is what I was born for." Rings tune and harmonize. (sets flag `rings_tuned`; requires `sel_calibrated` + `medallion_placed`) |

#### Rook Confrontation (automatic)

After step 118, Rook forces one channel open. Rings spin wildly. Transit tear opens.
"Such power. And all you would do is ask politely for permission to use it."
He activates override drill. (sets flag `rook_override_active`)
"The rings shudder. Systems buckle. I need to stop him -- now."

#### Puzzle 7: Defeat Rook

| # | Verb | Target | Expected Result |
|---|------|--------|-----------------|
| 119 | Use | ChokeLever | "I pull the transit choke lever. The pulse folds around Rook. It strips his stolen tools." Rook: "What have you done?" / Rowan: "Filed an objection." / Tibbit: "With supporting documents." / "CIVIC GATE: Transit privileges revoked." (sets flag `rook_defeated`; requires `rook_override_active`) |

#### THE DECISION -- Final Choice (automatic dialogue tree)

After Rook's defeat, the final decision dialogue appears:

| Dialogue Choice | Effect | Tone |
|----------------|--------|------|
| "Seal the island completely" | Bittersweet ending. Safer, sadder. (sets flag `ending_seal`) | Somber |
| "Open limited diplomatic contact" | Best balanced. Earned, thoughtful. Recommended. (sets flag `ending_limited`) | Hopeful |
| "Fully reopen the Wake Road" | Hopeful but volatile. (sets flag `ending_open`) | Bold |

All three choices lead to: "Authorization accepted." Seals placed. Rings harmonize. Sky clears. Island steadies. (sets flag `game_complete`)

#### Ending Sequence (automatic)

- Harbor calm. Rook under polite guard.
- Bram hates the elegance. Tibbit offers floating trams.
- Marrow and Rowan overlook the lagoon. "So this is home." / "Partly."
- Sel: "They want you to help design the new road."
- "Carefully, then." / Tibbit: "I had no intention of going home and becoming sensible."
- Final image: thin line of white light extends across the sea.
- Post-credits: Pindle receives island envelope. "Reciprocal customs delegation." Horror. "They have forms."
- **THE END -- Thank you for playing The Iron Wake.**

---

## KNOWN BLOCKERS / MISSING ITEMS

The following items are **referenced in puzzle code** but have **no `give_item()` call** in any room script. They may not be obtainable in the current build:

| Item | Where Needed | Workaround |
|------|-------------|------------|
| `coil_line` | Smuggler Path (bridge), Sunken Waystation (wire), Ironwind (stabilizer) | Code also accepts `copper_wire` in some places |
| `copper_wire` | Relay Tower (socket), Sunken Waystation (wire), Ironwind (stabilizer), Undersea Transit (bridge) | Listed in inventory icons but no `give_item` |
| `brass_curtain_rod` | Relay Tower (socket) | No source. Design doc says "get from Caligo" but no dialogue gives it. |
| `lantern` / `signal_lantern` | Fogwound Ruins (light source) | No source. May need to add as pickup. |
| `foil_reflector` | Fogwound Ruins (amplify light) | Code also accepts `chapel_hand_mirror` |
| `valve_pin` | Ironwind (stabilizer pin) | Code also accepts `brass_key` |
| `coil_clamp` | Ironwind (stabilizer), Cinderglass (shutter) | Code also accepts `broken_gear` |
| `insulated_gloves` | Undersea Transit (light rails) | Code also accepts `oilskin_pouch` |
| `oilskin_pouch` | Undersea Transit (light rails) | Listed in icon names but no `give_item` |
| `medallion` (Act 3) | Harmonic Gate bloodline socket | Consumed in Act 1. May need re-grant at Act 3 start. |

**Recommendation:** Add `give_item` calls for the missing items in appropriate rooms, or ensure the alternative items (e.g., `broken_gear`, `brass_key`, `oilskin_pouch`) are obtainable somewhere. The most critical blockers are `coil_line`/`copper_wire` (needed in multiple rooms) and `lantern` (needed in Fogwound Ruins).

---

## FULL ITEM ACQUISITION SUMMARY

| Item | Obtained In | How |
|------|------------|-----|
| Medallion | Beach (auto) | Given at room start |
| Spyglass | Beach | Pick up SpyglassCrate |
| Stamp | Beach | Pick up StampProp (after distraction) |
| Brass Strip | Beach | Memory vision reward |
| Blank Form | Customs Shack | Pick up BlankForms (Pindle distracted) |
| Filled Form | Customs Shack | Use blank_form on PermitLedger |
| Fake Permit | Customs Shack | Use filled_form on SealPress |
| Black Shard | Salvage Warehouse | Pick up BlackShard |
| Automaton Hand | Salvage Warehouse | Pick up AutomatonHand |
| Guild Badge | Brass Bazaar | Pick up GuildBadge |
| Fancy Teacup | Brass Bazaar | Pick up FancyTeacup |
| Focusing Disc | Brass Bazaar | Complete bluff puzzle |
| Clock Spring | Tibbit's Workshop | Pick up ClockSpring |
| Whistle | Tibbit's Workshop | Pick up Whistle |
| Lens Frame | Tibbit's Workshop | Pick up LensFrame |
| Memory Lens | Tibbit's Workshop | Use Workbench (with all 3 parts) |
| Salt Paste | Lighthouse Exterior | Pick up SaltDeposits |
| Relay Key | Lighthouse Chamber | Memory vision reward |
| Map Plate | Lighthouse Chamber | Memory vision reward |
| Ceramic Bottles | Smuggler Path | Pick up/Open ContrabandCrate |
| Chapel Hand Mirror | Brackmarsh | Talk to Caligo, ask for mirror |
| Transit Sigil Fragment | Relay Tower | Tower activation reward |
| Tone Cylinder | Relay Tower | Tower activation reward |
| Message Strip | Sunken Waystation | Waystation activation reward |
| Scaffold Pipe | Mountain Breach | Pick up ScaffoldPipe |
| Second Relay Core | Transit Vault | Archive revelation reward |
| Aerial Transit Prism | Transit Vault | Archive revelation reward |
| White Civic Signet Half | Transit Vault | Archive revelation reward |
| Reflective Cinderglass | Cinderglass Valley | Pick up GlassOutcrop |
| Complete Civic Signet | Undersea Transit | Marrow arrival event |

---

## QUICK REFERENCE: ROOM TRANSITIONS

```
Beach (main.tscn)
  |-- CustomsShack (requires has_permit or fake_permit on door)
  |     |-- DoorOut -> Beach
  |
  |-- Docks -> Salvage Warehouse (requires has_permit)
        |-- DoorOut -> Beach
        |-- DoorBazaar -> Brass Bazaar
              |-- DoorWarehouse -> Salvage Warehouse
              |-- DoorWorkshop -> Tibbit's Workshop
                    |-- DoorBazaar -> Brass Bazaar
                    |-- DoorCliffs -> Harbor Cliffs
                          |-- DoorWorkshop -> Tibbit's Workshop
                          |-- DoorLighthouse -> Lighthouse Exterior
                                |-- PathBack -> Harbor Cliffs
                                |-- LighthouseDoor -> Lighthouse Chamber (requires door_opened)
                                      |-- DoorOut -> Lighthouse Exterior

[ACT 2]
Smuggler Path
  |-- PathBack -> Lighthouse Chamber
  |-- PathForward -> Brackmarsh (requires bridge_crossed)
        |-- PathBack -> Smuggler Path
        |-- PathForward -> Relay Tower (requires fog_cleared)
              |-- PathBack -> Brackmarsh
              |-- PathForward -> Sunken Waystation (requires relay_tower_activated)
                    |-- PathBack -> Relay Tower
                    |-- PathForward -> Ironwind Air Dock (requires waystation_activated)
                          |-- PathBack -> Sunken Waystation
                          |-- PatientGull -> Fogwound Ruins (cutscene)
                                |-- PathBack -> Ironwind Air Dock
                                |-- PathForward -> Transit Vault (requires excavation_gate_open)
                                      |-- PathBack -> Fogwound Ruins
                                      |-- [Auto -> Cinderglass Valley after Act 2 ending]

[ACT 3]
Cinderglass Valley
  |-- PathBack -> Transit Vault
  |-- PathForward -> Mountain Breach (requires terrace_crossed)
        |-- PathBack -> Cinderglass Valley
        |-- MaintenanceHatch -> Undersea Transit (requires hatch_open)
              |-- PathBack -> Mountain Breach
              |-- [Auto -> Wake Passage after launch]
                    |-- [Auto -> Isle Auric]
                          |-- PathGate -> Harmonic Gate (FINALE)
```
