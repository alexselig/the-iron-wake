extends AdventureRoom

## Customs Shack — Act 1, Room 2
## Pindle's tiny steam-puffing office. Forge a permit to access the warehouse.

# Room-specific clickables
var pindle_desk: Area2D
var permit_ledger: Area2D
var ink_pad: Area2D
var wall_notices: Area2D
var seal_press: Area2D
var blank_forms: Area2D
var door_out: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act1_02_customs_shack.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	var SceneBuilder = preload("res://scripts/scene_builder.gd")

	# Build player sprite
	SceneBuilder.build_player_sprite($Player)

	# Pindle at his desk
	SceneBuilder.build_hotspot(props, "PindleDesk", Vector2(320, 260),
		"Dockmaster Pindle", Vector2(-30, 20), Vector2(60, 60))

	# Props around the office
	SceneBuilder.build_prop(props, "PermitLedger", Vector2(380, 240),
		"a permit ledger", "res://assets/props/cipher_plates.png",
		Vector2(-20, 30), false, false, Vector2(36, 28))

	SceneBuilder.build_prop(props, "InkPad", Vector2(280, 250),
		"an ink pad", "res://assets/props/oilskin_pouch.png",
		Vector2(0, 20), false, false, Vector2(24, 24))

	SceneBuilder.build_hotspot(props, "WallNotices", Vector2(200, 200),
		"wall notices", Vector2(20, 50), Vector2(60, 40))

	SceneBuilder.build_prop(props, "SealPress", Vector2(440, 255),
		"a wax seal press", "res://assets/props/broken_gear.png",
		Vector2(-15, 20), false, false, Vector2(28, 28))

	SceneBuilder.build_prop(props, "BlankForms", Vector2(160, 260),
		"blank forms", "res://assets/props/magnifying_lens.png",
		Vector2(20, 15), true, false, Vector2(32, 24))

	# Exit door
	SceneBuilder.build_hotspot(hotspots, "DoorOut", Vector2(80, 260),
		"the door outside", Vector2(30, 15), Vector2(40, 60))

func _on_room_ready() -> void:
	room_name = "customs_shack"

	pindle_desk = $Props/PindleDesk
	permit_ledger = $Props/PermitLedger
	ink_pad = $Props/InkPad
	wall_notices = $Props/WallNotices
	seal_press = $Props/SealPress
	blank_forms = $Props/BlankForms
	door_out = $Hotspots/DoorOut

	for node in [pindle_desk, permit_ledger, ink_pad, wall_notices,
				 seal_press, blank_forms, door_out]:
		if node:
			connect_clickable(node)

func _get_entry_position() -> Vector2:
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

	await _say_as("PINDLE", "Ah. You again. This is a restricted area.")
	await _say_as("ROWAN", "It's the size of a closet.")
	await _say_as("PINDLE", "A RESTRICTED closet.")

	_in_scripted_sequence = false
	is_busy = false

# ============================================================
# VERB ACTIONS
# ============================================================

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"PindleDesk":
			await _say("Pindle sits behind a desk barely wider than his authority.")
		"PermitLedger":
			await _say("A ledger of permits issued. The handwriting is aggressively legible.")
			if not GameState.has_flag("read_ledger"):
				await _say("The jargon on these forms is... impressively meaningless.")
				GameState.set_flag("read_ledger")
		"InkPad":
			await _say("Black ink. The lifeblood of bureaucracy.")
		"WallNotices":
			await _say("'ALL SALVAGE MUST BE DECLARED. ALL DECLARATIONS MUST BE STAMPED. ALL STAMPS MUST BE AUTHORIZED.'")
			if not GameState.has_flag("read_notices"):
				await _say("The circular logic is almost beautiful.")
				GameState.set_flag("read_notices")
		"SealPress":
			await _say("An official wax seal press. The Blackwake harbor crest.")
		"BlankForms":
			await _say("Blank salvage permit forms. Three copies of everything, naturally.")
		"DoorOut":
			await _say("The door back to the harbor. Fresh air and fewer stamps.")
		_:
			await _say("Nothing remarkable about that.")

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"PindleDesk":
			var tree := _build_pindle_office_dialogue()
			await run_dialogue_tree(tree)
		_:
			await _say("Talking to that seems optimistic.")

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"BlankForms":
			if not GameState.has_item("blank_form"):
				if GameState.has_flag("pindle_distracted"):
					await _say("I slide a blank form off the stack while Pindle argues with his stamp.")
					give_item("blank_form")
				else:
					await _say("Pindle is watching. I'd need to distract him first.")
			else:
				await _say("I already have one.")
		"InkPad":
			await _say("It's bolted to the desk. Pindle trusts no one.")
		"SealPress":
			await _say("Pindle would notice immediately. I need another approach.")
		_:
			await _say("I can't pick that up.")

func _use(obj: Clickable) -> void:
	match obj.name:
		"DoorOut":
			go_to_room("res://scenes/main.tscn")
		"SealPress":
			if GameState.has_item("filled_form"):
				await _say("I press the seal into the wax. It leaves a perfect Blackwake crest.")
				take_item("filled_form")
				give_item("fake_permit")
				GameState.set_flag("has_permit")
				await _say("One forged salvage permit. Pindle would be furious. Or impressed. Same thing.")
			else:
				await _say("I have nothing to seal.")
		_:
			await _say("I don't know how to use that on its own.")

func _open(obj: Clickable) -> void:
	match obj.name:
		"PermitLedger":
			await _look_at(obj)
		"DoorOut":
			go_to_room("res://scenes/main.tscn")
		_:
			await _say("That doesn't open.")

func _push(obj: Clickable) -> void:
	match obj.name:
		"PindleDesk":
			await _say("Pushing Pindle's desk would be satisfying but counterproductive.")
		_:
			await _say("Pushing that accomplishes nothing except proving I tried.")

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"PermitLedger":
			if item_name == "blank_form":
				if GameState.has_flag("read_ledger") and GameState.has_flag("read_notices"):
					await _say("I copy the jargon from the ledger onto the blank form. 'Pursuant to Article 7, Section Nothing...'")
					take_item("blank_form")
					give_item("filled_form")
					return true
				else:
					await _say("I need to study the proper jargon first. The ledger and wall notices should help.")
					return true
		"InkPad":
			if item_name == "filled_form":
				await _say("I stamp the form with the ink pad. It looks almost official.")
				return true
		"SealPress":
			if item_name == "filled_form":
				await _say("I press the seal into wax on the form. A perfect Blackwake crest.")
				take_item("filled_form")
				give_item("fake_permit")
				GameState.set_flag("has_permit")
				await _say("One forged salvage permit. Pindle would be furious.")
				return true
	return false

# ============================================================
# DIALOGUE TREES
# ============================================================

func _build_pindle_office_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	tree.add_node("start", "PINDLE", "State your business. Quickly. I have forms to deny.")
	tree.add_choice("start", "Ask about the salvage permit", "permit_q")
	tree.add_choice("start", "Distract him", "distract_q", "", "pindle_distracted")
	tree.add_choice("start", "Compliment his organization", "compliment_q")

	tree.add_node("permit_q", "PINDLE", "A salvage permit requires a completed SP-7 form, properly inked, and sealed with the harbor crest.")
	tree.add_node("permit_2", "ROWAN", "And if I don't have one?")
	tree.add_node("permit_3", "PINDLE", "Then you don't salvage. System works perfectly.", "end")
	tree.nodes["permit_q"].next_id = "permit_2"
	tree.nodes["permit_2"].next_id = "permit_3"

	tree.add_node("distract_q", "ROWAN", "Is that a discrepancy in your stamp log?")
	tree.add_node("distract_2", "PINDLE", "WHAT? Where?! No discrepancy has EVER occurred on my watch!")
	tree.add_node("distract_3", "PINDLE", "Let me check every entry... starting from the beginning...")
	tree.nodes["distract_q"].next_id = "distract_2"
	tree.nodes["distract_2"].next_id = "distract_3"
	tree.set_node_flag("distract_3", "pindle_distracted")
	tree.nodes["distract_3"].next_id = "end"

	tree.add_node("compliment_q", "ROWAN", "I have to say, this is the most organized closet I've ever been in.")
	tree.add_node("compliment_2", "PINDLE", "It is not a closet. It is a customs office. The distinction is legal.")
	tree.add_node("compliment_3", "PINDLE", "But... thank you. No one ever notices the filing system.", "end")
	tree.nodes["compliment_q"].next_id = "compliment_2"
	tree.nodes["compliment_2"].next_id = "compliment_3"

	tree.add_node("end", "PINDLE", "Now then. Is there anything else, or may I return to not approving things?")

	return tree
