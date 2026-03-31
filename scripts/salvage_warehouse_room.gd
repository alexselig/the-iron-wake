extends AdventureRoom

## Salvage Warehouse — Act 1, Room 3
## Long brick warehouse with confiscated relics and salvage records.
## Rook's first appearance. Discovery: brass strip → lighthouse connection.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var symbol_board: Area2D
var black_shard: Area2D
var lighthouse_crate: Area2D
var automaton_hand: Area2D
var chain_hoist: Area2D
var relic_shelves: Area2D
var door_out: Area2D
var door_bazaar: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act1_03_salvage_warehouse.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	# Symbol archive board — center wall
	SceneBuilder.build_hotspot(props, "SymbolBoard", Vector2(320, 230),
		"the symbol archive board", Vector2(0, 40), Vector2(80, 50))

	# Suspiciously polished black shard
	SceneBuilder.build_prop(props, "BlackShard", Vector2(200, 270),
		"a polished black shard", "res://assets/props/cipher_plates.png",
		Vector2(15, 15), true, false, Vector2(28, 28))

	# Lighthouse transfer crate
	SceneBuilder.build_prop(props, "LighthouseCrate", Vector2(450, 275),
		"a crate marked 'Lighthouse Transfer'", "res://assets/props/capsule_frames/closed.png",
		Vector2(-15, 10), false, false, Vector2(50, 40))

	# Broken automaton hand
	SceneBuilder.build_prop(props, "AutomatonHand", Vector2(140, 280),
		"a broken automaton hand", "res://assets/props/broken_gear.png",
		Vector2(15, 10), true, false, Vector2(30, 30))

	# Chain hoist
	SceneBuilder.build_hotspot(props, "ChainHoist", Vector2(520, 240),
		"the chain hoist", Vector2(-20, 30), Vector2(40, 50))

	# Relic shelves
	SceneBuilder.build_hotspot(props, "RelicShelves", Vector2(80, 250),
		"shelves of tagged relic pieces", Vector2(30, 25), Vector2(60, 50))

	# Exit door — back to harbor
	SceneBuilder.build_hotspot(hotspots, "DoorOut", Vector2(60, 270),
		"the door back to the harbor", Vector2(20, 10), Vector2(40, 60))

	# Exit — forward to the Brass Bazaar
	SceneBuilder.build_hotspot(hotspots, "DoorBazaar", Vector2(580, 270),
		"the passage to the Brass Bazaar", Vector2(-20, 10), Vector2(40, 60))

func _get_music_path() -> String:
	return "res://assets/music/harbor_ambient.wav"

func _on_room_ready() -> void:
	room_name = "salvage_warehouse"

	symbol_board = $Props/SymbolBoard
	black_shard = $Props/BlackShard
	lighthouse_crate = $Props/LighthouseCrate
	automaton_hand = $Props/AutomatonHand
	chain_hoist = $Props/ChainHoist
	relic_shelves = $Props/RelicShelves
	door_out = $Hotspots/DoorOut
	door_bazaar = $Hotspots/DoorBazaar

	for node in [symbol_board, black_shard, lighthouse_crate, automaton_hand,
				 chain_hoist, relic_shelves, door_out, door_bazaar]:
		if node:
			connect_clickable(node)

	speaker_to_node = {}

	# Hide black shard if already picked up
	if GameState.has_item("black_shard") and black_shard:
		black_shard.hide_object()

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"brass_bazaar":
			return Vector2(500, 290)
		_:
			return Vector2(100, 290)

# ============================================================
# INTRO — Rook's first appearance
# ============================================================

func _play_intro() -> void:
	is_busy = true
	_in_scripted_sequence = true

	# Fade in
	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw.finished
		fade_overlay.visible = false

	await _say("Long brick warehouse. Crates of storm salvage, confiscated contraptions, broken automata.")
	await _say("Relic fragments nobody understands. My kind of shopping.")

	# Player walks to the symbol board
	await player.walk_to_and_wait(Vector2(280, 290))

	# Discovery sequence — brass strip on symbol board
	if GameState.has_item("brass_strip"):
		await _say("The engraved strip has three symbols. Let me check the archive board.")
		await _say("The archive identifies one as Hushlight Lighthouse. Another as Tide Transit. The third is missing.")
		await _say_as("TIBBIT", "This isn't a map, exactly. More like a machine telling another machine where to point.")
		await _say("To the lighthouse.")
		GameState.set_flag("lighthouse_discovered")

	# Rook entrance
	await get_tree().create_timer(0.5).timeout
	await _say("The warehouse doors swing open.")
	await _say_as("ROOK", "I leave town for three days and the tide develops taste.")

	await get_tree().create_timer(0.3).timeout
	await _say_as("ROOK", "That fragment belongs to my company's salvage claim.")
	await _say("Funny. It flew out of a machine that seemed to disagree.")
	await _say_as("ROOK", "Machines do not own themselves.")
	await _say("That depends how bitey they are.")

	await get_tree().create_timer(0.3).timeout
	await _say_as("ROOK", "Be careful with old things. The past tends to cut the hand that rummages through it.")
	await _say_as("TIBBIT", "And the present?")
	await _say_as("ROOK", "The present sends invoices.")

	await get_tree().create_timer(0.3).timeout
	await _say("He leaves.")
	await _say_as("TIBBIT", "Well. I hate him efficiently.")

	GameState.set_flag("met_rook")
	_in_scripted_sequence = false
	is_busy = false

# ============================================================
# VERB ACTIONS
# ============================================================

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"SymbolBoard":
			if GameState.has_flag("lighthouse_discovered"):
				await _say("The board confirms it: the brass strip points to Hushlight Lighthouse.")
			else:
				await _say("At last. Organized theft. Rows of symbols from salvaged relics, catalogued by shape.")
		"BlackShard":
			await _say("Same material as the beach relic. Which is unfortunate, because I was hoping this morning had been unique.")
		"LighthouseCrate":
			await _say("'HUSHLIGHT LENS HOUSING - FRAGILE.' That feels relevant in the way danger often does.")
		"AutomatonHand":
			await _say("A metal hand. Helpful if I need a handshake from someone extremely committed to being dead.")
		"ChainHoist":
			await _say("For moving heavy crates. Or dramatic escapes. Currently doing neither.")
		"RelicShelves":
			await _say("Shelves of tagged relic pieces. Each one a mystery someone gave up on.")
		"DoorOut":
			await _say("The door back to the harbor. And to bureaucracy.")
		"DoorBazaar":
			await _say("A passage deeper into the market district. Smells like brass polish and bad deals.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"AutomatonHand":
			await _say("I tried. It left me on read.")
		_:
			await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"BlackShard":
			if not GameState.has_item("black_shard"):
				await _say("I pocket the shard. It hums faintly, like a tuning fork with opinions.")
				give_item("black_shard")
				black_shard.hide_object()
			else:
				await _say("I already have it.")
		"AutomatonHand":
			if not GameState.has_item("automaton_hand"):
				await _say("I take the hand. It's heavier than expected and disturbingly warm.")
				give_item("automaton_hand")
				automaton_hand.hide_object()
			else:
				await _say("One disembodied hand is enough, thank you.")
		"LighthouseCrate":
			await _say("It's crate-sized. I'm person-sized. The math is unfavorable.")
		_:
			await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"SymbolBoard":
			if GameState.has_item("brass_strip") and not GameState.has_flag("lighthouse_discovered"):
				await _say("I hold the brass strip up to the board. The symbols align.")
				await _say("Hushlight Lighthouse. That's where I need to go.")
				GameState.set_flag("lighthouse_discovered")
			elif GameState.has_flag("lighthouse_discovered"):
				await _say("I already know where to go. The lighthouse.")
			else:
				await _say("I need something to compare against these symbols.")
		"ChainHoist":
			await _say("I pull the chain. A crate shifts overhead. Nothing useful falls out.")
		"DoorOut":
			go_to_room("res://scenes/main.tscn")
		"DoorBazaar":
			go_to_room("res://scenes/rooms/brass_bazaar.tscn")
		_:
			await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"LighthouseCrate":
			await _say("The crate is empty — just straw packing and a label. The lens housing was moved already.")
			if not GameState.has_flag("lighthouse_crate_opened"):
				await _say("Someone wanted that lens. Recently.")
				GameState.set_flag("lighthouse_crate_opened")
		"DoorOut":
			go_to_room("res://scenes/main.tscn")
		"DoorBazaar":
			go_to_room("res://scenes/rooms/brass_bazaar.tscn")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	match obj.name:
		"LighthouseCrate":
			await _say("I shove the crate. It scrapes across the floor. Nothing useful happens.")
		_:
			await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"SymbolBoard":
			if item_name == "brass_strip":
				await _say("The symbols on the strip match entries on the board.")
				await _say("One reads 'Hushlight Lighthouse.' Another 'Tide Transit.' The third is unknown.")
				await _say_as("TIBBIT", "This isn't a map. It's a machine telling another machine where to point.")
				await _say("To the lighthouse.")
				GameState.set_flag("lighthouse_discovered")
				return true
	return false
