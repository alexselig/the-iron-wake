extends AdventureRoom

## The Sunken Waystation — Act 2, Room 12
## Submerged transit stop. Puzzle 4: Make the Waystation Talk.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var transit_map_arch: Area2D
var ticket_slot: Area2D
var vacuum_lockers: Area2D
var pump_mechanism: Area2D
var map_contacts: Area2D
var signal_wire: Area2D
var benches: Area2D
var path_back: Area2D
var path_forward: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act2_04_sunken_waystation.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	SceneBuilder.build_prop(props, "TransitMapArch", Vector2(320, 230),
		"the transit map arch", "res://assets/props/beacon_controls.png",
		Vector2(0, 30), false, false, Vector2(60, 50))

	SceneBuilder.build_hotspot(props, "TicketSlot", Vector2(380, 260),
		"a ticket slot", Vector2(-15, 10), Vector2(24, 20))

	SceneBuilder.build_prop(props, "VacuumLockers", Vector2(480, 255),
		"vacuum-sealed lockers", "res://assets/props/lighthouse_crate.png",
		Vector2(-20, 15), false, false, Vector2(40, 40))

	SceneBuilder.build_prop(props, "PumpMechanism", Vector2(150, 270),
		"a water pump", "res://assets/props/beacon_crank.png",
		Vector2(15, 10), false, false, Vector2(28, 36))

	SceneBuilder.build_hotspot(props, "MapContacts", Vector2(300, 240),
		"the map contacts", Vector2(10, 25), Vector2(40, 20))

	SceneBuilder.build_hotspot(props, "SignalWire", Vector2(420, 240),
		"a broken signal wire", Vector2(-10, 25), Vector2(30, 20))

	SceneBuilder.build_hotspot(props, "Benches", Vector2(220, 280),
		"impossible-material benches", Vector2(15, 5), Vector2(50, 24))

	SceneBuilder.build_hotspot(hotspots, "PathBack", Vector2(60, 275),
		"the causeway", Vector2(30, 5), Vector2(40, 60))

	var fwd = SceneBuilder.build_hotspot(hotspots, "PathForward", Vector2(580, 265),
		"the way forward", Vector2(-30, 10), Vector2(40, 60))
	if not GameState.has_flag("waystation_activated"):
		fwd.hide_object()

func _get_music_path() -> String:
	return "res://assets/music/lighthouse_ambient.wav"

func _on_room_ready() -> void:
	room_name = "sunken_waystation"

	transit_map_arch = $Props/TransitMapArch
	ticket_slot = $Props/TicketSlot
	vacuum_lockers = $Props/VacuumLockers
	pump_mechanism = $Props/PumpMechanism
	map_contacts = $Props/MapContacts
	signal_wire = $Props/SignalWire
	benches = $Props/Benches
	path_back = $Hotspots/PathBack
	path_forward = $Hotspots/PathForward

	for node in [transit_map_arch, ticket_slot, vacuum_lockers, pump_mechanism,
				 map_contacts, signal_wire, benches, path_back, path_forward]:
		if node:
			connect_clickable(node)

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"ironwind_airdock":
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

	await _say("Beneath the causeway: a station. Benches of impossible material. A flickering arch. Someone expected travelers.")
	await _say_as("TIBBIT", "It's a waiting room. For a transit system that hasn't run in centuries. I love it.")

	_in_scripted_sequence = false
	is_busy = false

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"TransitMapArch":
			await _say("The map is trying very hard to exist. Points flicker in and out.")
			if GameState.has_flag("contacts_dried"):
				await _say("The contacts are dry. It needs data to display.")
			else:
				await _say("Water damage has shorted the contacts beneath.")
		"TicketSlot":
			await _say("A civilization advanced enough to hide an island and still cursed with access control.")
		"VacuumLockers":
			await _say("Storage units sealed by pressure differential. Contents preserved for centuries.")
		"PumpMechanism":
			await _say("A hand pump for drainage. Someone added it later — brass against ancient stone.")
		"MapContacts":
			if GameState.has_flag("contacts_dried"):
				await _say("The contacts are dry and ready for input.")
			else:
				await _say("Submerged electrical contacts. The water needs to be pumped out.")
		"SignalWire":
			if GameState.has_flag("wire_reconnected"):
				await _say("The wire is patched. Signal can flow.")
			else:
				await _say("A broken signal wire. The connection to the transit network is severed.")
		"Benches":
			await _say("Smooth, warm to the touch, and made of something that shouldn't exist. Comfortable, though.")
		"PathBack":
			await _say("Back up the causeway to the relay tower.")
		"PathForward":
			if GameState.has_flag("waystation_activated"):
				await _say("The map shows the way to Ironwind Air Dock.")
			else:
				await _say("Nowhere to go until the waystation can tell me where.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"PumpMechanism":
			await _say("It's bolted to the floor. And full of ancient swamp water. No thank you.")
		_:
			await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"PathBack":
			go_to_room("res://scenes/rooms/relay_tower.tscn")
		"PathForward":
			if GameState.has_flag("waystation_activated"):
				go_to_room("res://scenes/rooms/ironwind_airdock.tscn")
			else:
				await _say("The waystation hasn't told me where to go yet.")
		"PumpMechanism":
			if not GameState.has_flag("water_pumped"):
				await _say("I work the pump handle. Water drains from the lower chamber, revealing the map contacts.")
				GameState.set_flag("water_pumped")
			else:
				await _say("Already pumped dry.")
		"MapContacts":
			if GameState.has_flag("water_pumped") and not GameState.has_flag("contacts_dried"):
				await _say("I dry the exposed contacts with my sleeve. They spark faintly.")
				GameState.set_flag("contacts_dried")
			elif not GameState.has_flag("water_pumped"):
				await _say("They're underwater. I need to pump the chamber first.")
			else:
				await _say("Already dried.")
		"TransitMapArch":
			if GameState.has_flag("waystation_activated"):
				await _say("The map shows relay active, routes to Ironwind and Fogwound, and a final offshore marker.")
			elif _waystation_ready():
				await _activate_waystation()
			else:
				await _say("The arch flickers. It needs: dry contacts, a tone cylinder, a sigil in the ticket slot, and a working signal wire.")
		"TicketSlot":
			await _say("The slot is empty. It wants some kind of authorization token.")
		_:
			await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"VacuumLockers":
			await _say("The vacuum seal is intact. I'd need specialized tools to open these.")
		"PathBack":
			go_to_room("res://scenes/rooms/relay_tower.tscn")
		"PathForward":
			if GameState.has_flag("waystation_activated"):
				go_to_room("res://scenes/rooms/ironwind_airdock.tscn")
			else:
				await _say("No destination yet.")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"TransitMapArch", "MapContacts":
			if item_name == "tone_cylinder":
				if GameState.has_flag("contacts_dried"):
					await _say("I insert the Tone Cylinder into the arch's input port. It clicks and hums.")
					GameState.set_flag("cylinder_inserted")
					if _waystation_ready():
						await _activate_waystation()
					return true
				else:
					await _say("The contacts are wet. The cylinder would short out.")
					return true
		"TicketSlot":
			if item_name == "transit_sigil_fragment":
				await _say("The Sigil Fragment slides into the ticket slot. The arch brightens.")
				GameState.set_flag("sigil_inserted")
				if _waystation_ready():
					await _activate_waystation()
				return true
			else:
				await _say("I've just attempted to board an ancient transit system with a %s. I want credit for initiative." % item_name.replace("_", " "))
				return true
		"SignalWire":
			if item_name == "coil_line" or item_name == "copper_wire":
				await _say("I splice the wire using Tibbit's coil clip. The connection holds.")
				await _say_as("TIBBIT", "Ugly but functional. My motto.")
				GameState.set_flag("wire_reconnected")
				if _waystation_ready():
					await _activate_waystation()
				return true
	return false

func _waystation_ready() -> bool:
	return (GameState.has_flag("water_pumped") and GameState.has_flag("contacts_dried")
		and GameState.has_flag("cylinder_inserted") and GameState.has_flag("sigil_inserted")
		and GameState.has_flag("wire_reconnected"))

func _activate_waystation() -> void:
	is_busy = true
	_in_scripted_sequence = true

	await _say("The waystation hums to life. The arch blazes with a map of glowing routes.")
	await get_tree().create_timer(0.3).timeout
	await _say("A recorded voice, cracked with age:")
	await _say("'Wake sequence incomplete. Aerial transfer required. Authorized bloodline recognized.'")
	await _say("'Warning: civic division remains unresolved.'")
	await get_tree().create_timer(0.3).timeout
	await _say("A message strip ejects from a slot: 'SECOND ACCESS RESTRICTED BY ORDER OF THE WESTERN COUNCIL.'")
	give_item("message_strip")

	await _say("There were factions.")
	await _say_as("TIBBIT", "Naturally. No civilization ever gets shiny enough to outgrow politics.")

	GameState.set_flag("waystation_activated")
	if path_forward:
		path_forward.show_object()

	_in_scripted_sequence = false
	is_busy = false
