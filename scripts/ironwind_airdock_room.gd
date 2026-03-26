extends AdventureRoom

## Ironwind Air Dock — Act 2, Room 13
## Cliffside dock with derelict airships. Bram Kett. Puzzle 5: Convince Bram to Fly.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var bram_npc: Area2D
var patient_gull: Area2D
var mooring_winch: Area2D
var fuel_gauge: Area2D
var stabilizer: Area2D
var wind_flags: Area2D
var path_back: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act2_05_ironwind_airdock.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	# Bram Kett — lounging under the hull, facing left
	SceneBuilder.build_npc(props, "BramNPC", Vector2(350, 275),
		"Bram Kett", "bram", Vector2(-25, 5), true, Vector2(40, 50))

	# The Patient Gull — large airship
	SceneBuilder.build_hotspot(props, "PatientGull", Vector2(400, 220),
		"The Patient Gull", Vector2(-30, 45), Vector2(100, 60))

	# Mooring winch
	SceneBuilder.build_prop(props, "MooringWinch", Vector2(500, 265),
		"a mooring winch", "res://assets/props/beacon_crank.png",
		Vector2(-15, 15), false, false, Vector2(32, 32))

	# Fuel gauge
	SceneBuilder.build_hotspot(props, "FuelGauge", Vector2(440, 245),
		"the fuel gauge", Vector2(-20, 25), Vector2(24, 20))

	# Stabilizer linkage (broken)
	SceneBuilder.build_hotspot(props, "Stabilizer", Vector2(380, 240),
		"the stabilizer linkage", Vector2(-10, 30), Vector2(40, 24))

	# Wind-torn flags
	SceneBuilder.build_hotspot(props, "WindFlags", Vector2(200, 210),
		"signal flags", Vector2(20, 50), Vector2(40, 30))

	SceneBuilder.build_hotspot(hotspots, "PathBack", Vector2(60, 275),
		"the causeway path", Vector2(30, 5), Vector2(40, 60))

func _on_room_ready() -> void:
	room_name = "ironwind_airdock"

	bram_npc = $Props/BramNPC
	patient_gull = $Props/PatientGull
	mooring_winch = $Props/MooringWinch
	fuel_gauge = $Props/FuelGauge
	stabilizer = $Props/Stabilizer
	wind_flags = $Props/WindFlags
	path_back = $Hotspots/PathBack

	speaker_to_node = {
		"BRAM": "BramNPC"
	}

	for node in [bram_npc, patient_gull, mooring_winch, fuel_gauge,
				 stabilizer, wind_flags, path_back]:
		if node:
			connect_clickable(node)

func _get_entry_position() -> Vector2:
	return Vector2(100, 290)

func _play_intro() -> void:
	is_busy = true
	_in_scripted_sequence = true

	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw.finished
		fade_overlay.visible = false

	if not GameState.has_flag("met_bram"):
		await _say("Cliffside dock. Derelict airships creak in the wind. One of them has a person under it.")
		await _say_as("BRAM", "No.")
		await _say("We haven't asked anything yet.")
		await _say_as("BRAM", "Experience.")
		GameState.set_flag("met_bram")
	else:
		await _say("Back at the air dock. Bram and the Patient Gull await.")

	_in_scripted_sequence = false
	is_busy = false

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"BramNPC":
			await _say("Bram Kett. Disgraced pilot. The kind of man who looks at the sky the way other people look at regret.")
		"PatientGull":
			await _say("An airship with the expression of a dog that has eaten a chair.")
			if not GameState.has_flag("examined_gull"):
				await _say("Patched, pear-shaped, and somehow still airworthy. The stabilizer linkage is broken, though.")
				GameState.set_flag("examined_gull")
		"MooringWinch":
			await _say("Industrial confidence in spool form.")
		"FuelGauge":
			await _say("The needle appears to be pointing at 'ambition.'")
		"Stabilizer":
			if GameState.has_flag("stabilizer_repaired"):
				await _say("The stabilizer linkage holds. My best work, honestly.")
			else:
				await _say("The stabilizer linkage is snapped. Needs wire, a pin, and something to clamp it.")
		"WindFlags":
			await _say("Signal flags so weather-beaten they've stopped signaling and started meditating.")
		"PathBack":
			await _say("The causeway back to the waystation.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"BramNPC":
			if GameState.has_flag("bram_convinced"):
				await _say_as("BRAM", "I said I'd fly. Stop looking at me like I might change my mind. I might change my mind.")
			else:
				var tree := _build_bram_dialogue()
				await run_dialogue_tree(tree)
		_:
			await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"MooringWinch":
			await _say("It's bolted to the dock platform. And weighs approximately one stubbornness.")
		_:
			await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"PathBack":
			go_to_room("res://scenes/rooms/sunken_waystation.tscn")
		"PatientGull":
			if GameState.has_flag("bram_convinced") and GameState.has_flag("stabilizer_repaired"):
				await _trigger_aerial_transit()
			elif not GameState.has_flag("stabilizer_repaired"):
				await _say("The stabilizer is broken. We'd spin out before clearing the cliff.")
			elif not GameState.has_flag("bram_convinced"):
				await _say("Bram hasn't agreed to fly yet. I need to convince him.")
		"Stabilizer":
			if GameState.has_flag("stabilizer_repaired"):
				await _say("Already fixed. Tibbit is proud. I can tell because he's named it.")
			else:
				await _say("The linkage needs wire, a pin, and a clamp to hold it all together.")
		"BramNPC":
			if GameState.has_flag("bram_convinced"):
				await _say("He's ready. We need the ship ready too.")
			else:
				await _talk_to(obj)
		_:
			await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"PathBack":
			go_to_room("res://scenes/rooms/sunken_waystation.tscn")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	match obj.name:
		"PatientGull":
			await _say("I push against the hull. The airship shifts slightly. Bram glares. I stop.")
		_:
			await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"Stabilizer":
			if item_name == "copper_wire" or item_name == "coil_line":
				if not GameState.has_flag("stabilizer_wire"):
					await _say("I thread the wire through the broken linkage. It needs a pin and a clamp to hold.")
					GameState.set_flag("stabilizer_wire")
					return true
				else:
					await _say("Wire's already in place.")
					return true
			if item_name == "valve_pin" or item_name == "brass_key":
				if GameState.has_flag("stabilizer_wire") and not GameState.has_flag("stabilizer_pinned"):
					await _say("The pin slides through the linkage. One more piece — a clamp.")
					GameState.set_flag("stabilizer_pinned")
					return true
				elif not GameState.has_flag("stabilizer_wire"):
					await _say("The pin won't hold without wire threaded first.")
					return true
			if item_name == "coil_clamp" or item_name == "broken_gear":
				if GameState.has_flag("stabilizer_wire") and GameState.has_flag("stabilizer_pinned"):
					await _say("I clamp everything tight. The stabilizer linkage holds. It even looks intentional.")
					await _say_as("TIBBIT", "I'm calling it the Portable Coil of Selective Certainty.")
					GameState.set_flag("stabilizer_repaired")
					return true
				else:
					await _say("The linkage needs wire and a pin before clamping.")
					return true
		"BramNPC":
			if item_name == "map_plate" or item_name == "wake_road_map_plate":
				if not GameState.has_flag("showed_bram_map"):
					await _say("I show Bram the glowing map. His eyes widen.")
					await _say_as("BRAM", "That's... real. That's an actual ancient route.")
					await _say_as("BRAM", "I spent my career chasing rumors of these.")
					GameState.set_flag("showed_bram_map")
					return true
				else:
					await _say("He's already seen the map. Now I need the right words.")
					return true
	return false

func _build_bram_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	tree.add_node("start", "BRAM", "Whatever it is, no.")
	tree.add_choice("start", "We need a pilot", "pilot_q")
	tree.add_choice("start", "We can pay", "pay_q")
	tree.add_choice("start", "What if it's historic?", "historic_q")
	tree.add_choice("start", "Rook will get there first", "rook_q", "showed_bram_map")

	tree.add_node("pilot_q", "BRAM", "Then I recommend religion.", "end")

	tree.add_node("pay_q", "ROWAN", "Limited coin and unreasonable urgency.")
	tree.add_node("pay_q2", "BRAM", "So, not the good kind of job.", "end")
	tree.nodes["pay_q"].next_id = "pay_q2"

	tree.add_node("historic_q", "BRAM", "History crashes just as hard.", "end")

	# The winning dialogue — only available after showing map
	tree.add_node("rook_q", "ROWAN", "Rook will get there first if you stay here brooding.")
	tree.add_node("rook_q2", "BRAM", "That oily peacock?")
	tree.add_node("rook_q3", "BRAM", "Fine. I'll fly. But only because I hate being preempted by money.")
	tree.set_node_flag("rook_q3", "bram_convinced")
	tree.nodes["rook_q"].next_id = "rook_q2"
	tree.nodes["rook_q2"].next_id = "rook_q3"
	tree.nodes["rook_q3"].next_id = "end"

	tree.add_node("end", "BRAM", "Now fix that stabilizer before I change my mind.")

	return tree

func _trigger_aerial_transit() -> void:
	is_busy = true
	_in_scripted_sequence = true

	await _say("We climb aboard. Bram kicks something. The engine coughs, then roars.")
	await _say("The Patient Gull lurches skyward. The marsh glimmers below. Relay beams converge on ruins ahead.")

	if fade_overlay:
		fade_overlay.visible = true
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 1.0, 0.5)
		await tw.finished

	await _say("A sleek black-hulled airship appears behind us.")
	await _say("He followed us.")
	await _say_as("BRAM", "Of course he did. Villains never navigate. They pursue.")

	GameState.set_flag("aerial_transit_complete")

	if fade_overlay:
		var tw2 := create_tween()
		tw2.tween_property(fade_overlay, "color:a", 0.0, 0.5)
		await tw2.finished
		fade_overlay.visible = false

	_in_scripted_sequence = false
	is_busy = false
	go_to_room("res://scenes/rooms/fogwound_ruins.tscn")
