extends AdventureRoom

## Ruins Transit Vault — Act 2, Room 15
## Pristine underground chamber. Puzzle 7: Reconcile Split Crest.
## Archive Revelation + Rook Confrontation + Puzzle 8: Escape.
## Act 2 ending cutscene.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var circular_door: Area2D
var compass_mechanism: Area2D
var split_crest: Area2D
var archive_node: Area2D
var ring_assembly: Area2D
var key_interface: Area2D
var vault_walls: Area2D
var path_back: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act2_07_transit_vault.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	SceneBuilder.build_hotspot(props, "CircularDoor", Vector2(320, 220),
		"the great circular door", Vector2(0, 40), Vector2(80, 50))

	SceneBuilder.build_prop(props, "CompassMechanism", Vector2(320, 260),
		"the compass mechanism", "res://assets/props/door_mechanism.png",
		Vector2(0, 15), false, false, Vector2(56, 48))

	SceneBuilder.build_hotspot(props, "SplitCrest", Vector2(250, 240),
		"the split civic crest", Vector2(20, 25), Vector2(40, 30))

	SceneBuilder.build_prop(props, "ArchiveNode", Vector2(450, 255),
		"the archive node", "res://assets/props/beacon_controls.png",
		Vector2(-20, 15), false, false, Vector2(44, 36))

	SceneBuilder.build_hotspot(props, "RingAssembly", Vector2(320, 230),
		"the suspended ring assembly", Vector2(0, 30), Vector2(60, 30))

	SceneBuilder.build_hotspot(props, "KeyInterface", Vector2(320, 275),
		"the central key interface", Vector2(0, 5), Vector2(30, 20))

	SceneBuilder.build_hotspot(props, "VaultWalls", Vector2(160, 230),
		"the glowing walls", Vector2(30, 35), Vector2(60, 50))

	SceneBuilder.build_hotspot(hotspots, "PathBack", Vector2(60, 275),
		"the ruins court", Vector2(30, 5), Vector2(40, 60))

func _on_room_ready() -> void:
	room_name = "transit_vault"

	circular_door = $Props/CircularDoor
	compass_mechanism = $Props/CompassMechanism
	split_crest = $Props/SplitCrest
	archive_node = $Props/ArchiveNode
	ring_assembly = $Props/RingAssembly
	key_interface = $Props/KeyInterface
	vault_walls = $Props/VaultWalls
	path_back = $Hotspots/PathBack

	for node in [circular_door, compass_mechanism, split_crest, archive_node,
				 ring_assembly, key_interface, vault_walls, path_back]:
		if node:
			connect_clickable(node)

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"fogwound_ruins":
			return Vector2(520, 285)
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

	await _say("A pristine chamber beneath the broken court. The walls glow. The air hums with dormant purpose.")
	await _say_as("TIBBIT", "This place was built to last forever. Which makes it deeply suspicious.")

	_in_scripted_sequence = false
	is_busy = false

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"CircularDoor":
			await _say("A huge circular door ringed with dormant transit sigils. Impressive and firmly shut.")
		"CompassMechanism":
			await _say("A suspended mechanism like a compass made by mathematicians who distrusted straight lines.")
			if not GameState.has_flag("examined_compass"):
				await _say("A slot for the Map Plate. Spaces for sigil fragments. A central key interface.")
				GameState.set_flag("examined_compass")
		"SplitCrest":
			await _say("Two halves of the same emblem, broken clean down the center. Well. That feels subtle.")
		"ArchiveNode":
			await _say("A machine specifically designed to preserve history. Which means it probably also edits it.")
		"RingAssembly":
			await _say("Concentric rings suspended above the compass. They can rotate independently.")
			if GameState.has_flag("tones_playing"):
				await _say("Two overlapping melodies play from the tone cylinder. The rings need to harmonize them.")
		"KeyInterface":
			await _say("The central slot. It awaits the Relay Key for final confirmation.")
		"VaultWalls":
			await _say("The walls pulse softly. Ancient circuitry embedded in stone. Beautiful and unnerving.")
		"PathBack":
			await _say("Back up to the ruins court.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"ArchiveNode":
			await _say("I press the playback interface. Static. Then silence. It needs input first.")
		_:
			await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"PathBack":
			if GameState.has_flag("rook_confrontation"):
				await _say("No going back now. The way is sealed.")
			else:
				go_to_room("res://scenes/rooms/fogwound_ruins.tscn")
		"RingAssembly":
			if GameState.has_flag("tones_playing") and GameState.has_flag("council_seal_retrieved"):
				await _say("I rotate the rings. The two tone patterns shift... overlap... and harmonize.")
				await _say("The chamber resonates. The split crest glows as one.")
				GameState.set_flag("rings_harmonized")
			elif GameState.has_flag("tones_playing"):
				await _say("The tones play but the opposing seal is missing. The system can't balance.")
			else:
				await _say("The rings are dormant. The compass needs data first.")
		"KeyInterface":
			if _puzzle_ready():
				await _say("I insert the Relay Key. It turns. The mechanism accepts.")
				GameState.set_flag("crest_reconciled")
				await _trigger_archive_revelation()
			elif GameState.has_flag("rings_harmonized"):
				await _say("Almost. The key interface awaits the Relay Key.")
			else:
				await _say("The mechanism isn't ready. I need to reconcile the crest first.")
		"CompassMechanism":
			await _say("The compass waits for input. Map Plate, sigil fragment, tone cylinder, council seal — then harmonize.")
		_:
			await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"CircularDoor":
			await _say("The door is sealed by transit logic. Reconcile the crest to open it.")
		"PathBack":
			if not GameState.has_flag("rook_confrontation"):
				go_to_room("res://scenes/rooms/fogwound_ruins.tscn")
			else:
				await _say("Sealed behind us.")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	match obj.name:
		"RingAssembly":
			await _say("The rings need to be rotated precisely, not shoved.")
		"CircularDoor":
			await _say("I push against a door designed to resist civilizations. It does not yield.")
		_:
			await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"CompassMechanism":
			if item_name == "map_plate" or item_name == "wake_road_map_plate":
				if not GameState.has_flag("map_plate_inserted"):
					await _say("The Map Plate slides into the transit compass. Routes illuminate across its surface.")
					GameState.set_flag("map_plate_inserted")
					return true
			if item_name == "transit_sigil_fragment":
				if not GameState.has_flag("sigil_placed_vault"):
					await _say("The Sigil Fragment clicks into the missing slot of the split crest. One half reconnects.")
					GameState.set_flag("sigil_placed_vault")
					return true
			if item_name == "tone_cylinder":
				if not GameState.has_flag("tones_playing"):
					await _say("I insert the Tone Cylinder. Two overlapping melodies fill the chamber — competing harmonics from two factions.")
					GameState.set_flag("tones_playing")
					return true
		"ArchiveNode":
			if item_name == "message_strip":
				if not GameState.has_flag("council_seal_retrieved"):
					await _say("I feed the Council Strip into the archive node. It hums, processes, and projects:")
					await _say("The opposing faction's seal materializes. Two halves of a divided government.")
					GameState.set_flag("council_seal_retrieved")
					return true
		"KeyInterface":
			if item_name == "relay_key":
				if _puzzle_ready():
					await _say("I insert the Relay Key.")
					GameState.set_flag("crest_reconciled")
					await _trigger_archive_revelation()
					return true
				else:
					await _say("The mechanism isn't ready for the key yet.")
					return true
		"RingAssembly":
			if item_name == "fancy_teacup":
				await _say("I briefly considered elegance as a weapon. I regret it already.")
				return true
	# Wrong items in wrong places
	if target.name == "CompassMechanism" or target.name == "ArchiveNode":
		await _say("Even their doors held grudges. That item doesn't fit here.")
		return true
	return false

func _puzzle_ready() -> bool:
	return (GameState.has_flag("map_plate_inserted") and GameState.has_flag("sigil_placed_vault")
		and GameState.has_flag("tones_playing") and GameState.has_flag("council_seal_retrieved")
		and GameState.has_flag("rings_harmonized"))

func _trigger_archive_revelation() -> void:
	is_busy = true
	_in_scripted_sequence = true

	# Projection fills the chamber
	if fade_overlay:
		fade_overlay.visible = true
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color", Color(0.95, 0.9, 0.7, 0.7), 0.5)
		await tw.finished

	await _say("A projection fills the chamber. Two figures argue before a council table.")
	await _say("WESTERN COUNCILOR: If we open the road again, the mainland will bring the old hunger with it.")
	await _say("EASTERN COUNCILOR: If we close it forever, we become a mausoleum with gardens.")
	await get_tree().create_timer(0.3).timeout
	await _say("Rowan's father steps forward.")
	await _say("FATHER: Then let the road remain sleeping, but not dead. Leave a path for return.")
	await get_tree().create_timer(0.3).timeout
	await _say("MOTHER: Send the child away. If the councils fracture, the key must survive outside the seal.")

	if fade_overlay:
		var tw2 := create_tween()
		tw2.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 0.8)
		await tw2.finished
		fade_overlay.visible = false

	await _say_as("TIBBIT", "You weren't lost.")
	await _say("No.")
	await _say_as("TIBBIT", "You were hidden.")
	await _say("Yes.")

	give_item("second_relay_core")
	give_item("aerial_transit_prism")
	give_item("white_civic_signet_half")
	GameState.set_flag("archive_revelation")
	await _say("The vault yields its treasures: a second relay core, an aerial transit prism, and half of a civic signet.")

	await get_tree().create_timer(0.5).timeout

	# Rook arrives
	await _say("Applause from the chamber entrance.")
	await _say_as("ROOK", "Magnificent. I do so appreciate arriving after the difficult part.")
	await _say_as("ROOK", "Hand over the key and I may permit you to remain a footnote in your own ancestry.")
	await _say("Tempting. But I've grown attached to being inconvenient.")
	GameState.set_flag("rook_confrontation")

	# Escape puzzle — automated sequence
	await _say("Rook advances. I need to get out. Now.")
	await _say("I jam the Aerial Transit Prism into the light channel. Beams refract wildly.")
	await _say("I rotate the compass. Light bounces everywhere. Rook shields his eyes.")
	await _say_as("TIBBIT", "Pulling the lever!")
	await _say("A false route activates. The transit shutter drops between us and Rook.")
	await _say_as("ROOK", "Miss Vale!")
	await _say("Commodore!")
	await _say_as("ROOK", "This is temporary.")
	await _say("That's true of all disappointing men.")

	GameState.set_flag("vault_escaped")

	# Act 2 ending
	if fade_overlay:
		fade_overlay.visible = true
		var tw3 := create_tween()
		tw3.tween_property(fade_overlay, "color:a", 1.0, 0.5)
		await tw3.finished

	await _say("Ruins ridge at dawn. The Map Plate shows progress: first relay active, Fogwound vault active, final offshore marker stronger.")
	await _say_as("MARROW", "The island split more deeply than I feared. One council sealed the road. Another left the means to restore it.")
	await _say("My parents were part of that second group.")
	await _say_as("MARROW", "Yes.")
	await _say("Then the island is not merely hidden. It's divided.")
	await _say_as("MARROW", "Worse. It may have mistaken stillness for peace.")
	await _say_as("BRAM", "Where's the next relay?")
	await _say_as("MARROW", "Under the mountain. The old undersea transit chamber.")
	await _say_as("TIBBIT", "Marvelous. From marshes and villains to caves and probable collapse.")
	await _say("One relay left.")
	await _say_as("MARROW", "One relay. One final route. Then the sea will answer.")
	await _say("Far offshore, through fog, a faint line of white architecture is almost visible. Almost.")
	await _say("END OF ACT 2")

	GameState.set_flag("act2_complete")

	_in_scripted_sequence = false
	is_busy = false

	# Transition to Act 3
	go_to_room("res://scenes/rooms/cinderglass_valley.tscn")
