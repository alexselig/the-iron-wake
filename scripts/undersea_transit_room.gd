extends AdventureRoom

## Undersea Transit Chamber — Act 3, Room 18
## Puzzles 3-5: Restore relay, choose authorization, escape from Rook.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var relay_socket: Area2D
var harmonic_bridge: Area2D
var light_rails: Area2D
var archive_basin: Area2D
var transit_cradle: Area2D
var route_console: Area2D
var docking_clamps: Area2D
var path_back: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act3_03_undersea_transit.png")
	if tex: bg.texture = tex

func _build_room() -> void:
	var props := $Props; var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)
	SceneBuilder.build_hotspot(props, "RelaySocket", Vector2(200, 255),
		"the final relay socket", Vector2(20, 15), Vector2(36, 36))
	SceneBuilder.build_hotspot(props, "HarmonicBridge", Vector2(320, 240),
		"the harmonic bridge", Vector2(0, 25), Vector2(80, 20))
	SceneBuilder.build_hotspot(props, "LightRails", Vector2(400, 250),
		"the light rails", Vector2(-15, 20), Vector2(50, 20))
	SceneBuilder.build_hotspot(props, "ArchiveBasin", Vector2(480, 265),
		"an archive basin", Vector2(-20, 10), Vector2(36, 28))
	SceneBuilder.build_prop(props, "TransitCradle", Vector2(320, 270),
		"the transit cradle", "res://assets/props/lighthouse_crate.png",
		Vector2(0, 5), false, false, Vector2(60, 36))
	SceneBuilder.build_hotspot(props, "RouteConsole", Vector2(260, 260),
		"the route console", Vector2(15, 10), Vector2(36, 28))
	SceneBuilder.build_hotspot(props, "DockingClamps", Vector2(370, 275),
		"docking clamps", Vector2(-10, 0), Vector2(40, 20))
	SceneBuilder.build_hotspot(hotspots, "PathBack", Vector2(60, 275),
		"the hatch back", Vector2(30, 5), Vector2(40, 60))

func _on_room_ready() -> void:
	room_name = "undersea_transit"
	relay_socket = $Props/RelaySocket; harmonic_bridge = $Props/HarmonicBridge
	light_rails = $Props/LightRails; archive_basin = $Props/ArchiveBasin
	transit_cradle = $Props/TransitCradle; route_console = $Props/RouteConsole
	docking_clamps = $Props/DockingClamps; path_back = $Hotspots/PathBack
	for node in [relay_socket, harmonic_bridge, light_rails, archive_basin,
				 transit_cradle, route_console, docking_clamps, path_back]:
		if node: connect_clickable(node)

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"mountain_breach":
			return Vector2(520, 285)
		_:
			return Vector2(100, 290)

func _play_intro() -> void:
	is_busy = true; _in_scripted_sequence = true
	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw.finished; fade_overlay.visible = false
	await _say("An immense station suspended over black seawater. Luminous rails arc across the chasm.")
	await _say("At center: a transit cradle — half vessel, half machine.")
	await _say_as("TIBBIT", "A boat designed by someone who thought elegance should be waterproof.")
	_in_scripted_sequence = false; is_busy = false

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"RelaySocket":
			if GameState.has_flag("relay_core_inserted"): await _say("The final relay core hums with power.")
			else: await _say("The final relay socket. Empty. Waiting for a core.")
		"HarmonicBridge":
			if GameState.has_flag("bridge_linked"): await _say("The bridge conducts cleanly. Nodes all connected.")
			else: await _say("A broken harmonic bridge. Dead nodes need conductive links between them.")
		"LightRails":
			if GameState.has_flag("rails_seated"): await _say("The rails glow. Power flows.")
			else: await _say("Light rails displaced from their mounts. Need re-seating — carefully.")
		"ArchiveBasin": await _say("A shallow basin of liquid data. Memories float beneath the surface.")
		"TransitCradle": await _say("A boat designed by someone who thought elegance should be waterproof.")
		"RouteConsole": await _say("Currently set to 'closed,' 'forbidden,' and 'I said no.'")
		"DockingClamps": await _say("Heavy clamps holding the cradle in dock. Three release levers.")
		"PathBack": await _say("The maintenance hatch back to the mountain.")
		_: await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"PathBack": go_to_room("res://scenes/rooms/mountain_breach.tscn")
		"ArchiveBasin":
			if GameState.has_flag("relay_powered") and not GameState.has_flag("basin_searched"):
				await _say("I search the archive basin. A record surfaces: the missing signet half was entrusted to 'a warden of the gate.'")
				GameState.set_flag("basin_searched")
				await _trigger_marrow_arrival()
			elif GameState.has_flag("basin_searched"): await _say("Already searched. Marrow had the missing piece.")
			else: await _say("The basin is dormant. It needs relay power first.")
		"RouteConsole":
			if GameState.has_flag("has_complete_signet") and not GameState.has_flag("wake_authorized"):
				await _trigger_authorization_choice()
			elif GameState.has_flag("wake_authorized"):
				await _say("Authorization set. The cradle is ready for launch.")
			else: await _say("The console needs the Complete Civic Signet.")
		"DockingClamps":
			if GameState.has_flag("wake_authorized") and GameState.has_flag("cradle_prepared"):
				await _trigger_launch_and_escape()
			elif GameState.has_flag("wake_authorized"):
				await _say("I need to prepare the cradle before releasing clamps.")
			else: await _say("Releasing clamps without authorization would be... educational. And fatal.")
		"TransitCradle":
			if GameState.has_flag("wake_authorized"):
				await _say("The cradle awaits. I need to set the prism and prepare for launch.")
			else: await _say("Beautiful machine. Going nowhere until I authorize the route.")
		_: await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"PathBack": go_to_room("res://scenes/rooms/mountain_breach.tscn")
		_: await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"RelaySocket":
			if item_name == "second_relay_core":
				await _say("The Second Relay Core slides into place. Power surges through the station.")
				GameState.set_flag("relay_core_inserted"); return true
		"HarmonicBridge":
			if item_name == "copper_wire" or item_name == "conductive_links":
				if GameState.has_flag("relay_core_inserted"):
					await _say("I place conductive links between the dead nodes. The bridge sparks to life.")
					GameState.set_flag("bridge_linked"); _check_relay_power(); return true
				else: await _say("No power yet. Insert the relay core first."); return true
		"LightRails":
			if item_name == "insulated_gloves" or item_name == "oilskin_pouch":
				if GameState.has_flag("bridge_linked"):
					await _say("Using insulation, I re-seat the displaced light rails. They lock and glow.")
					GameState.set_flag("rails_seated"); _check_relay_power(); return true
				else: await _say("The bridge needs to be connected first."); return true
		"RouteConsole":
			if item_name == "complete_civic_signet" or item_name == "white_civic_signet_half":
				if GameState.has_flag("has_complete_signet"):
					await _say("I insert the Complete Civic Signet.")
					await _trigger_authorization_choice(); return true
		"TransitCradle":
			if item_name == "aerial_transit_prism":
				if GameState.has_flag("wake_authorized"):
					await _say("I set the Aerial Transit Prism into the guidance arm. The cradle aligns.")
					GameState.set_flag("cradle_prepared"); return true
				else: await _say("I need route authorization first."); return true
	return false

func _check_relay_power() -> void:
	if GameState.has_flag("relay_core_inserted") and GameState.has_flag("bridge_linked") and GameState.has_flag("rails_seated"):
		GameState.set_flag("relay_powered")
		await _say("All connections restored. The station powers up fully. The archive basin activates.")

func _trigger_marrow_arrival() -> void:
	is_busy = true; _in_scripted_sequence = true
	await _say("Marrow appears through a side entrance. She produces a half-signet.")
	await _say("You had that.")
	await _say_as("MARROW", "I had half of a decision.")
	await _say("You are the most exhausting person I know.")
	await _say_as("TIBBIT", "He's top three for me.")
	give_item("complete_civic_signet")
	GameState.set_flag("has_complete_signet")
	await _say("The two halves join. The Complete Civic Signet glows.")
	_in_scripted_sequence = false; is_busy = false

func _trigger_authorization_choice() -> void:
	is_busy = true; _in_scripted_sequence = true
	await _say("The console demands: Temporary wake authorization required.")
	await _say("Even now, their greatest invention remains procedural delay.")
	# Present choice via dialogue
	var tree := DialogueTree.new()
	tree.add_node("start", "TRANSIT CONSOLE", "Civic consensus absent. Temporary wake authorization required. Select mode:")
	tree.add_choice("start", "Personal transit only", "personal")
	tree.add_choice("start", "Authorized emergency transit", "emergency")
	tree.add_choice("start", "Open signal broadcast", "broadcast")
	tree.add_node("personal", "ROWAN", "Personal transit only. Minimum exposure.", "done")
	tree.set_node_flag("personal", "auth_personal")
	tree.add_node("emergency", "ROWAN", "Authorized emergency. Controlled but purposeful.", "done")
	tree.set_node_flag("emergency", "auth_emergency")
	tree.add_node("broadcast", "ROWAN", "Open signal. Let the road speak for itself.", "done")
	tree.set_node_flag("broadcast", "auth_broadcast")
	tree.add_node("done", "TRANSIT CONSOLE", "Authorization accepted. Wake route initializing.")
	await run_dialogue_tree(tree)
	GameState.set_flag("wake_authorized")
	_in_scripted_sequence = false; is_busy = false

func _trigger_launch_and_escape() -> void:
	is_busy = true; _in_scripted_sequence = true
	# Rook breach
	await _say("The huge circular door splits open under external force. Rook strides in.")
	await _say_as("ROOK", "At last. Miss Vale, you continue to do beautiful work for other people.")
	await _say("You continue to mistake theft for participation.")
	await _say_as("ROOK", "Ownership is simply participation with paperwork.")
	await _say_as("ROOK", "Clean energy. Transit beyond storms. Materials that do not corrode. With such tools, one need not conquer the world. One merely invoices it.")
	await _say("That may be the bleakest sentence I've heard this week.")
	# Escape sequence
	await _say("Rook's men advance. I release the docking clamps.")
	await _say_as("TIBBIT", "Holding the override!")
	await _say("Marrow topples a light bridge behind us. We leap into the cradle.")
	await _say_as("ROOK", "Miss Vale!")
	await _say("Commodore!")
	await _say_as("ROOK", "This is not over!")
	await _say("You keep saying that like it's comforting!")

	GameState.set_flag("rook_breach_act3")
	if fade_overlay:
		fade_overlay.visible = true
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 1.0, 0.5)
		await tw.finished
	await _say("The cradle vanishes into the dark sea channels.")
	_in_scripted_sequence = false; is_busy = false
	go_to_room("res://scenes/rooms/wake_passage.tscn")
