extends AdventureRoom

## The First Relay Tower — Act 2, Room 11
## Ancient tower in shallow water. Puzzle 3: Restore Harmonic Circuit.
## Memory Vision 3 after puzzle completion.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var relay_pedestal: Area2D
var socket_1: Area2D
var socket_2: Area2D
var socket_3: Area2D
var tone_forks: Area2D
var tower_grooves: Area2D
var path_back: Area2D
var path_forward: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act2_03_relay_tower.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	SceneBuilder.build_prop(props, "RelayPedestal", Vector2(320, 260),
		"the relay pedestal", "res://assets/props/lens_pedestal.png",
		Vector2(0, 15), false, false, Vector2(52, 44))

	SceneBuilder.build_hotspot(props, "Socket1", Vector2(280, 255),
		"the first socket", Vector2(15, 15), Vector2(24, 24))

	SceneBuilder.build_hotspot(props, "Socket2", Vector2(320, 245),
		"the second socket", Vector2(0, 20), Vector2(24, 24))

	SceneBuilder.build_hotspot(props, "Socket3", Vector2(360, 255),
		"the third socket", Vector2(-15, 15), Vector2(24, 24))

	SceneBuilder.build_prop(props, "ToneForks", Vector2(450, 250),
		"embedded tone forks", "res://assets/props/tone_forks.png",
		Vector2(-20, 20), false, false, Vector2(36, 28))

	SceneBuilder.build_hotspot(props, "TowerGrooves", Vector2(320, 200),
		"luminous grooves on the tower", Vector2(0, 55), Vector2(80, 40))

	SceneBuilder.build_hotspot(hotspots, "PathBack", Vector2(60, 275),
		"the marsh path", Vector2(30, 5), Vector2(40, 60))

	var fwd = SceneBuilder.build_hotspot(hotspots, "PathForward", Vector2(580, 265),
		"the causeway path", Vector2(-30, 10), Vector2(40, 60))
	if not GameState.has_flag("relay_tower_activated"):
		fwd.hide_object()

func _get_music_path() -> String:
	return "res://assets/music/lighthouse_ambient.wav"

func _on_room_ready() -> void:
	room_name = "relay_tower"

	relay_pedestal = $Props/RelayPedestal
	socket_1 = $Props/Socket1
	socket_2 = $Props/Socket2
	socket_3 = $Props/Socket3
	tone_forks = $Props/ToneForks
	tower_grooves = $Props/TowerGrooves
	path_back = $Hotspots/PathBack
	path_forward = $Hotspots/PathForward

	for node in [relay_pedestal, socket_1, socket_2, socket_3,
				 tone_forks, tower_grooves, path_back, path_forward]:
		if node:
			connect_clickable(node)

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"sunken_waystation":
			return Vector2(550, 285)
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

	await _say("The tower rises from shallow water like a spearhead. Dark surfaces etched with luminous grooves.")
	await _say_as("TIBBIT", "Now THAT is architecture with opinions.")

	_in_scripted_sequence = false
	is_busy = false

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"RelayPedestal":
			await _say("Elegant, impossible, and one missing piece away from being rude.")
			if not GameState.has_flag("examined_pedestal"):
				await _say("Three sockets on a circular platform. Central interface with a key slot.")
				GameState.set_flag("examined_pedestal")
		"Socket1", "Socket2", "Socket3":
			var filled := _count_filled_sockets()
			await _say("An empty conductor socket. %d of 3 filled." % filled)
		"ToneForks":
			await _say("So the ancients built towers that run on harmony. Naturally.")
			await _say("Why use a lever when you can require emotional alignment from architecture.")
		"TowerGrooves":
			await _say("The grooves pulse faintly. The tower is dormant, not dead.")
		"PathBack":
			await _say("The marsh path back to Caligo's territory.")
		"PathForward":
			if GameState.has_flag("relay_tower_activated"):
				await _say("The causeway continues toward the old waystation.")
			else:
				await _say("The path ahead is dark. The tower needs to light the way.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"ToneForks":
			await _say("I tap a fork. It hums. I don't think it answered, but I appreciate the effort.")
		_:
			await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"ToneForks":
			await _say("They're embedded in stone. The ancients believed in permanent installation.")
		_:
			await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"PathBack":
			go_to_room("res://scenes/rooms/brackmarsh.tscn")
		"PathForward":
			if GameState.has_flag("relay_tower_activated"):
				go_to_room("res://scenes/rooms/sunken_waystation.tscn")
			else:
				await _say("The way is dark. The tower needs to activate first.")
		"RelayPedestal":
			if _count_filled_sockets() >= 3 and GameState.has_flag("relay_key_inserted"):
				if not GameState.has_flag("tone_matched"):
					await _say("The pedestal hums. The tone forks await calibration.")
					await _say("I match the sequence... low, high, middle...")
					await _say_as("TIBBIT", "No no, middle then high!")
					await _say("I adjust. The tones align. The tower resonates.")
					GameState.set_flag("tone_matched")
					await _activate_tower()
				else:
					await _say("The tower is already active.")
			elif _count_filled_sockets() >= 3:
				await _say("Three conductors in place. The central interface needs the Relay Key.")
			else:
				await _say("The sockets need conductor rods. Three of them. %d placed so far." % _count_filled_sockets())
		"ToneForks":
			if _count_filled_sockets() >= 3 and GameState.has_flag("relay_key_inserted"):
				await _use(relay_pedestal)
			else:
				await _say("The forks won't respond until the circuit is complete.")
		_:
			await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"PathBack":
			go_to_room("res://scenes/rooms/brackmarsh.tscn")
		"PathForward":
			if GameState.has_flag("relay_tower_activated"):
				go_to_room("res://scenes/rooms/sunken_waystation.tscn")
			else:
				await _say("The way ahead is sealed by darkness.")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	# Conductor rods for sockets
	if target.name in ["Socket1", "Socket2", "Socket3"]:
		if item_name == "brass_curtain_rod" and not GameState.has_flag("socket_rod"):
			await _say("The brass curtain rod slides into the socket. It hums faintly.")
			take_item("brass_curtain_rod")
			GameState.set_flag("socket_rod")
			return true
		if item_name == "copper_wire" and not GameState.has_flag("socket_wire"):
			await _say("I twist the wire and reeds into a makeshift conductor. It sparks but holds.")
			take_item("copper_wire")
			GameState.set_flag("socket_wire")
			return true
		if item_name == "automaton_hand" and not GameState.has_flag("socket_finger"):
			await _say("The automaton finger slides in with mechanical precision. Perfect fit.")
			take_item("automaton_hand")
			GameState.set_flag("socket_finger")
			return true
		if item_name in ["brass_curtain_rod", "copper_wire", "automaton_hand"]:
			await _say("That socket already has a conductor.")
			return true

	if target.name == "RelayPedestal":
		if item_name == "relay_key":
			if _count_filled_sockets() >= 3:
				await _say("I insert the Relay Key into the central interface. It turns with a satisfying click.")
				GameState.set_flag("relay_key_inserted")
				return true
			else:
				await _say("The pedestal won't accept the key until all three sockets have conductors.")
				return true
	return false

func _count_filled_sockets() -> int:
	var count := 0
	if GameState.has_flag("socket_rod"): count += 1
	if GameState.has_flag("socket_wire"): count += 1
	if GameState.has_flag("socket_finger"): count += 1
	return count

func _activate_tower() -> void:
	is_busy = true
	_in_scripted_sequence = true

	await _say("The tower erupts with light. A beam shoots skyward, bends horizontally through the fog.")
	await get_tree().create_timer(0.5).timeout

	# Memory Vision 3
	await _say("The light touches me. The world dissolves.")
	await get_tree().create_timer(0.3).timeout

	if fade_overlay:
		fade_overlay.visible = true
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color", Color(0.9, 0.8, 0.5, 0.8), 0.5)
		await tw.finished

	await _say("A lesson hall. White stone. Young Rowan and children before a map of glowing points.")
	await _say("INSTRUCTOR: The road remains hidden until the relays agree. Harmony is not decoration. It is permission.")
	await _say("YOUNG ROWAN: And if one tower refuses?")
	await _say("INSTRUCTOR: Then the road closes. And the world remains outside.")

	if fade_overlay:
		var tw2 := create_tween()
		tw2.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 0.8)
		await tw2.finished
		fade_overlay.visible = false

	await _say("They built the route to choose who could enter.")
	await _say_as("TIBBIT", "Yes. Which is either security or arrogance, depending on whether it's pointed at you.")

	GameState.set_flag("relay_tower_activated")
	GameState.set_flag("memory_vision_3")
	give_item("transit_sigil_fragment")
	give_item("tone_cylinder")
	await _say("The tower yields a sigil fragment and a tone cylinder. Pieces of a larger key.")

	if path_forward:
		path_forward.show_object()

	_in_scripted_sequence = false
	is_busy = false
