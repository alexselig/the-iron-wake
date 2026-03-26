extends AdventureRoom

## Fogwound Ruins Outer Court — Act 2, Room 14
## Broken white stone court. Puzzle 6: Bypass Excavation Gate (shadow puzzle).

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var fallen_statue: Area2D
var brass_scaffolding: Area2D
var camp_note: Area2D
var lantern_plinth: Area2D
var rotating_panels: Area2D
var rods_frame: Area2D
var archways: Area2D
var path_back: Area2D
var path_forward: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act2_06_fogwound_ruins.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	SceneBuilder.build_prop(props, "FallenStatue", Vector2(250, 275),
		"a fallen statue", "res://assets/props/boundary_stone.png",
		Vector2(15, 5), false, false, Vector2(60, 32))

	SceneBuilder.build_hotspot(props, "BrassScaffolding", Vector2(420, 230),
		"Rook's scaffolding", Vector2(-20, 35), Vector2(50, 40))

	SceneBuilder.build_prop(props, "CampNote", Vector2(460, 270),
		"a camp note", "res://assets/props/cipher_plates.png",
		Vector2(-15, 10), true, false, Vector2(28, 20))

	SceneBuilder.build_hotspot(props, "LanternPlinth", Vector2(270, 260),
		"the statue plinth", Vector2(10, 15), Vector2(40, 24))

	SceneBuilder.build_hotspot(props, "RotatingPanels", Vector2(380, 255),
		"three rotating panels", Vector2(-15, 15), Vector2(50, 30))

	SceneBuilder.build_hotspot(props, "RodsFrame", Vector2(340, 240),
		"metal rods and frame", Vector2(0, 25), Vector2(30, 20))

	SceneBuilder.build_hotspot(props, "Archways", Vector2(320, 200),
		"broken archways", Vector2(0, 55), Vector2(100, 40))

	SceneBuilder.build_hotspot(hotspots, "PathBack", Vector2(60, 275),
		"back to the air dock", Vector2(30, 5), Vector2(40, 60))

	var fwd = SceneBuilder.build_hotspot(hotspots, "PathForward", Vector2(500, 270),
		"the hidden passage", Vector2(-25, 5), Vector2(40, 50))
	if not GameState.has_flag("excavation_gate_open"):
		fwd.hide_object()

func _on_room_ready() -> void:
	room_name = "fogwound_ruins"

	fallen_statue = $Props/FallenStatue
	brass_scaffolding = $Props/BrassScaffolding
	camp_note = $Props/CampNote
	lantern_plinth = $Props/LanternPlinth
	rotating_panels = $Props/RotatingPanels
	rods_frame = $Props/RodsFrame
	archways = $Props/Archways
	path_back = $Hotspots/PathBack
	path_forward = $Hotspots/PathForward

	for node in [fallen_statue, brass_scaffolding, camp_note, lantern_plinth,
				 rotating_panels, rods_frame, archways, path_back, path_forward]:
		if node:
			connect_clickable(node)

	if GameState.has_flag("read_camp_note") and camp_note:
		camp_note.hide_object()

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"transit_vault":
			return Vector2(480, 285)
		_:
			return Vector2(100, 290)

func _play_intro() -> void:
	is_busy = true
	_in_scripted_sequence = true

	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw.finished
		fade_overlay.visible = false

	if not GameState.has_flag("fogwound_intro"):
		await _say("Broken white stone court. Roots and moss reclaim what was once grand. Rook's scaffolding mars the edges.")
		await _say_as("BRAM", "I'll keep the ship warm.")
		await _say("That sounds optimistic.")
		await _say_as("BRAM", "No. It's a figure of speech. The ship leaks.")
		GameState.set_flag("fogwound_intro")

	_in_scripted_sequence = false
	is_busy = false

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"FallenStatue":
			await _say("A white stone figure, toppled. The plinth it once stood on is still intact. Flat surface.")
		"BrassScaffolding":
			await _say("Rook's people set this up. Pry bars, pulleys, the usual archaeology-by-force toolkit.")
		"CampNote":
			await _say("'Subject site exhibits sealed transit logic. Continue extraction.'")
			await _say("There's something uniquely dreadful about greed with penmanship.")
			if not GameState.has_flag("read_camp_note"):
				await _say("It also mentions: 'Light-lock sequence not yet solved. Team reports intermittent shadow responses from panels.'")
				GameState.set_flag("read_camp_note")
				camp_note.hide_object()
		"LanternPlinth":
			if GameState.has_flag("lantern_placed"):
				await _say("The lantern sits on the plinth, casting light toward the panels.")
			else:
				await _say("The fallen statue's plinth. Flat, elevated. Good for placing something that needs to project.")
		"RotatingPanels":
			await _say("Three stone panels embedded in the wall. Each can rotate to reveal different symbol faces.")
			if GameState.has_flag("read_camp_note"):
				await _say("Rook's team noticed 'shadow responses.' Light and shadows open the way.")
		"RodsFrame":
			await _say("Metal rods and a frame from Rook's scaffolding. Could be arranged to cast specific shadows.")
		"Archways":
			await _say("Broken archways ring the central plaza. Ancient and dignified in their ruin.")
		"PathBack":
			await _say("Back to where Bram and the Patient Gull wait.")
		"PathForward":
			await _say("The hidden passage into the transit vault.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"CampNote":
			await _look_at(obj)
		"RodsFrame":
			await _say("They're too large to carry but could be arranged in place.")
		_:
			await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"PathBack":
			go_to_room("res://scenes/rooms/ironwind_airdock.tscn")
		"PathForward":
			if GameState.has_flag("excavation_gate_open"):
				go_to_room("res://scenes/rooms/transit_vault.tscn")
			else:
				await _say("The passage is sealed. I need to solve the light-lock.")
		"RotatingPanels":
			if GameState.has_flag("lantern_placed") and GameState.has_flag("reflector_placed") and GameState.has_flag("rods_arranged"):
				await _say("I rotate the panels to match the shadow cast by the rods.")
				await _say("The symbols align. Stone grinds. A hidden passage opens in the side wall.")
				GameState.set_flag("excavation_gate_open")
				if path_forward:
					path_forward.show_object()
			elif not GameState.has_flag("lantern_placed"):
				await _say("I rotate a panel. Nothing happens. I need a light source first.")
			elif not GameState.has_flag("rods_arranged"):
				await _say("Light hits the panels but the shadows are wrong. I need to arrange something to cast the right symbol.")
			else:
				await _say("Almost. The shadow isn't quite right on all three panels.")
		"RodsFrame":
			if GameState.has_flag("lantern_placed"):
				await _say("I arrange the rods and frame between the lantern and the panels.")
				if GameState.has_flag("reflector_placed"):
					await _say("The amplified light casts a crisp symbol shadow onto the rotating panels.")
					GameState.set_flag("rods_arranged")
				else:
					await _say("The shadow is too dim. I need something to reflect and amplify the light.")
			else:
				await _say("I need a light source on the plinth first.")
		"LanternPlinth":
			await _say("An empty plinth. Good for placing a light source.")
		_:
			await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"PathBack":
			go_to_room("res://scenes/rooms/ironwind_airdock.tscn")
		"PathForward":
			if GameState.has_flag("excavation_gate_open"):
				go_to_room("res://scenes/rooms/transit_vault.tscn")
			else:
				await _say("Sealed by ancient light-lock. Rook couldn't solve it either.")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	match obj.name:
		"RotatingPanels":
			await _say("They rotate, not push. Subtlety was apparently important to the ancients.")
		"FallenStatue":
			await _say("It's fallen as far as it's going to fall.")
		_:
			await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"LanternPlinth":
			if item_name == "lantern" or item_name == "signal_lantern":
				await _say("I set the lantern on the plinth. It casts a beam toward the panels.")
				GameState.set_flag("lantern_placed")
				return true
		"LanternPlinth", "RodsFrame":
			if item_name == "foil_reflector" or item_name == "chapel_hand_mirror":
				if GameState.has_flag("lantern_placed"):
					await _say("I position the reflector behind the lantern. The light intensifies and focuses.")
					GameState.set_flag("reflector_placed")
					return true
				else:
					await _say("I need a light source on the plinth first.")
					return true
		"RotatingPanels":
			if item_name == "fancy_teacup":
				await _say("I throw the teacup at the ancient panels.")
				await _say("It shatters. The panels remain unmoved. As do I, emotionally.")
				await _say_as("TIBBIT", "That seems less like a secret of the ancients and more like a personal embarrassment.")
				return true
	return false
