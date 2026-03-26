extends AdventureRoom

## Tibbit's Workshop Cart — Act 1, Room 5
## Half tool chest, half explosion apology. Assemble the Memory Lens.

# Room-specific clickables
var tibbit_npc: Area2D
var workbench_prop: Area2D
var clock_spring: Area2D
var lamp_oil: Area2D
var whistle: Area2D
var lens_frame_prop: Area2D
var burner_pot_prop: Area2D
var door_bazaar: Area2D
var door_cliffs: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act1_05_tibbit_workshop.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	var SceneBuilder = preload("res://scripts/scene_builder.gd")

	# Build player sprite
	SceneBuilder.build_player_sprite($Player)

	# Tibbit NPC — animated, facing right toward workbench
	SceneBuilder.build_npc(props, "TibbitNPC", Vector2(280, 275),
		"Tibbit Wrench", "tibbit", Vector2(25, 5), false, Vector2(40, 50))

	# Workbench — large, center of room
	SceneBuilder.build_prop(props, "Workbench", Vector2(400, 260),
		"the workbench", "res://assets/props/workbench.png",
		Vector2(-20, 25), false, false, Vector2(70, 40))

	# Clock spring — on shelf
	SceneBuilder.build_prop(props, "ClockSpring", Vector2(460, 235),
		"a clock spring", "res://assets/props/broken_gear.png",
		Vector2(-15, 30), true, false, Vector2(24, 24))

	# Lamp oil — on shelf
	SceneBuilder.build_prop(props, "LampOil", Vector2(520, 240),
		"a bottle of lamp oil", "res://assets/props/oilskin_pouch.png",
		Vector2(-15, 25), false, false, Vector2(20, 28))

	# Whistle — hanging from hook
	SceneBuilder.build_prop(props, "Whistle", Vector2(350, 220),
		"a tiny brass whistle", "res://assets/props/brass_key.png",
		Vector2(0, 40), true, false, Vector2(20, 20))

	# Lens frame — on workbench
	SceneBuilder.build_prop(props, "LensFrame", Vector2(420, 250),
		"an empty lens frame", "res://assets/props/lens_frame.png",
		Vector2(-15, 25), true, false, Vector2(28, 28))

	# Burner/pot — hissing
	SceneBuilder.build_prop(props, "BurnerPot", Vector2(200, 265),
		"a bubbling pot", "res://assets/props/burner_pot.png",
		Vector2(15, 15), false, false, Vector2(28, 32))

	# Exit to Brass Bazaar
	SceneBuilder.build_hotspot(hotspots, "DoorBazaar", Vector2(60, 260),
		"the way back to the bazaar", Vector2(30, 15), Vector2(40, 60))

	# Exit to Harbor Cliffs
	SceneBuilder.build_hotspot(hotspots, "DoorCliffs", Vector2(580, 260),
		"the path to the cliffs", Vector2(-30, 15), Vector2(40, 60))

func _on_room_ready() -> void:
	room_name = "tibbit_workshop"

	tibbit_npc = $Props/TibbitNPC
	workbench_prop = $Props/Workbench
	clock_spring = $Props/ClockSpring
	lamp_oil = $Props/LampOil
	whistle = $Props/Whistle
	lens_frame_prop = $Props/LensFrame
	burner_pot_prop = $Props/BurnerPot
	door_bazaar = $Hotspots/DoorBazaar
	door_cliffs = $Hotspots/DoorCliffs

	# Map speaker names to NPC node names for talk animations
	speaker_to_node = {
		"TIBBIT": "TibbitNPC"
	}

	for node in [tibbit_npc, workbench_prop, clock_spring, lamp_oil,
				 whistle, lens_frame_prop, burner_pot_prop, door_bazaar, door_cliffs]:
		if node:
			connect_clickable(node)

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"harbor_cliffs":
			return Vector2(550, 290)
		_:
			return Vector2(100, 290)

func _play_intro() -> void:
	is_busy = true
	_in_scripted_sequence = true

	# Fade in
	if fade_overlay:
		var tween := create_tween()
		tween.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tween.finished
		fade_overlay.visible = false

	await _say_as("TIBBIT", "Ah! Perfect timing. Hold this. Don't breathe on it.")
	await _say("What is—")
	await _say_as("TIBBIT", "It's NOT a whistle. Anymore.")

	_in_scripted_sequence = false
	is_busy = false

# ============================================================
# VERB ACTIONS
# ============================================================

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"TibbitNPC":
			await _say("Tibbit is surrounded by a halo of brass dust and enthusiasm.")
		"Workbench":
			await _say("The workbench is covered in half-finished contraptions. Each one labeled in Tibbit's cramped handwriting.")
			if not GameState.has_flag("examined_workbench"):
				await _say("There's a blueprint for something called a 'Memory Lens' pinned under a teacup.")
				GameState.set_flag("examined_workbench")
		"ClockSpring":
			await _say("A tightly coiled clock spring. Still has tension.")
		"LampOil":
			await _say("Lamp oil. The label says 'MULTI-PURPOSE' in three languages, all misspelled.")
		"Whistle":
			await _say("A tiny brass whistle. It has an absurd number of valves for something so small.")
		"LensFrame":
			await _say("An empty brass lens frame with adjustment screws. Needs a lens and some kind of focusing element.")
		"BurnerPot":
			await _say("A pot bubbles ominously. The sign says 'DO NOT TASTE AGAIN.'")
			if not GameState.has_flag("read_pot_sign"):
				await _say("The 'AGAIN' is underlined three times.")
				GameState.set_flag("read_pot_sign")
		"DoorBazaar":
			await _say("The way back to the Brass Bazaar.")
		"DoorCliffs":
			await _say("A narrow path leads toward the harbor cliffs.")
		_:
			await _say("Nothing remarkable about that.")

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"TibbitNPC":
			var tree := _build_tibbit_workshop_dialogue()
			await run_dialogue_tree(tree)
		"BurnerPot":
			await _say("I'm not going to have a conversation with soup. Probably.")
		_:
			await _say("Talking to that seems optimistic.")

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"ClockSpring":
			if not GameState.has_item("clock_spring"):
				await _say("I carefully pocket the clock spring. It vibrates faintly.")
				give_item("clock_spring")
				obj.hide_object()
			else:
				await _say("I already have one.")
		"Whistle":
			if not GameState.has_item("whistle"):
				await _say("I take the whistle. Tibbit doesn't notice — or doesn't care.")
				give_item("whistle")
				obj.hide_object()
			else:
				await _say("I already have one.")
		"LensFrame":
			if not GameState.has_item("lens_frame"):
				await _say("I take the lens frame from the bench.")
				give_item("lens_frame")
				obj.hide_object()
			else:
				await _say("I already have one.")
		"LampOil":
			await _say("I'll leave the lamp oil. My pockets have enough flammable things already.")
		_:
			await _say("I can't pick that up.")

func _use(obj: Clickable) -> void:
	match obj.name:
		"DoorBazaar":
			go_to_room("res://scenes/rooms/brass_bazaar.tscn")
		"DoorCliffs":
			go_to_room("res://scenes/rooms/harbor_cliffs.tscn")
		"Workbench":
			if GameState.has_item("memory_lens"):
				await _say("The lens is complete. Nothing more to build.")
			elif GameState.has_item("lens_frame") and GameState.has_item("focusing_disc") and GameState.has_item("clock_spring"):
				await _say("I set the components on the workbench...")
				await _say_as("TIBBIT", "Oh! You have everything. Let me see, let me see...")
				take_item("lens_frame")
				take_item("focusing_disc")
				take_item("clock_spring")
				await _say_as("TIBBIT", "Disc into frame... spring for tension... and...")
				await _say("Tibbit fastens the last piece. The lens emits a soft note.")
				await _say("Why did it whistle.")
				await _say_as("TIBBIT", "Atmosphere.")
				give_item("memory_lens")
				GameState.set_flag("lens_assembled")
			else:
				await _say("I need the right components. A lens frame, a focusing disc, and something for tension.")
		"BurnerPot":
			await _say("I resist the urge. The sign was very specific about 'AGAIN.'")
		_:
			await _say("I don't know how to use that on its own.")

func _open(obj: Clickable) -> void:
	match obj.name:
		"DoorBazaar":
			go_to_room("res://scenes/rooms/brass_bazaar.tscn")
		"DoorCliffs":
			go_to_room("res://scenes/rooms/harbor_cliffs.tscn")
		_:
			await _say("That doesn't open.")

func _push(obj: Clickable) -> void:
	match obj.name:
		"Workbench":
			await _say("It's bolted to the cart frame. Tibbit is paranoid about earthquakes. Or explosions. Same thing.")
		"BurnerPot":
			await _say("Pushing a pot of boiling mystery liquid seems like a poor life choice.")
		_:
			await _say("Pushing that accomplishes nothing except proving I tried.")

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"Workbench":
			if item_name == "lens_frame" or item_name == "focusing_disc" or item_name == "clock_spring":
				if GameState.has_item("lens_frame") and GameState.has_item("focusing_disc") and GameState.has_item("clock_spring"):
					# All pieces — assemble!
					await _use(target)
					return true
				else:
					await _say("I need all three components: the lens frame, focusing disc, and clock spring.")
					return true
			elif item_name == "whistle":
				await _say("No. Memory does not need an entrance theme.")
				await _say_as("TIBBIT", "Counterpoint: everything improves with one.")
				return true
	return false

func _on_combine_items(item_a: String, item_b: String) -> bool:
	var items := [item_a, item_b]
	if "whistle" in items and ("lens_frame" in items or "focusing_disc" in items):
		await _say("No. Memory does not need an entrance theme.")
		await _say_as("TIBBIT", "Counterpoint: everything improves with one.")
		return true
	return false

# ============================================================
# DIALOGUE TREES
# ============================================================

func _build_tibbit_workshop_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	tree.add_node("start", "TIBBIT", "What do you need? I'm in the middle of naming something.")
	tree.add_choice("start", "Ask about the Memory Lens", "lens_q")
	tree.add_choice("start", "Ask what he's building", "building_q")
	tree.add_choice("start", "Ask about the boundary stones", "stones_q", "", "asked_about_stones")

	# Memory Lens questions
	tree.add_node("lens_q", "TIBBIT", "The Memory Lens! Yes. It reads residual impressions from old relics. Needs three things.")
	tree.add_node("lens_q2", "ROWAN", "Three things?")
	tree.add_node("lens_q3", "TIBBIT", "A frame — I had one somewhere. A focusing element — the disc you found at the bazaar should work. And a tension spring. Clock spring, ideally.")
	tree.nodes["lens_q"].next_id = "lens_q2"
	tree.nodes["lens_q2"].next_id = "lens_q3"
	tree.nodes["lens_q3"].next_id = "end"

	# Building question
	tree.add_node("building_q", "TIBBIT", "I call it the Atmospheric Resonance Detector Mark Twelve.")
	tree.add_node("building_q2", "ROWAN", "What happened to Marks One through Eleven?")
	tree.add_node("building_q3", "TIBBIT", "Atmosphere.", "end")
	tree.nodes["building_q"].next_id = "building_q2"
	tree.nodes["building_q2"].next_id = "building_q3"

	# Boundary stones
	tree.add_node("stones_q", "TIBBIT", "The cliffs? Old as the harbor. Older, actually. Same symbols as the relic.")
	tree.add_node("stones_q2", "TIBBIT", "Someone carved directions. To where? Nobody knows. That's the fun part.", "end")
	tree.set_node_flag("stones_q", "asked_about_stones")
	tree.nodes["stones_q"].next_id = "stones_q2"

	tree.add_node("end", "TIBBIT", "Now then. Back to naming things. This spring needs a title.")

	return tree
