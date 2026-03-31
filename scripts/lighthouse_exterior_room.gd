extends AdventureRoom

## Hushlight Lighthouse Exterior — Act 1, Room 7
## Marrow Quill waits at the door. Puzzle 5: Open the lighthouse door.
## Salt paste → engraved strip → beacon crank.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var marrow_npc: Area2D
var lighthouse_door: Area2D
var beacon_crank: Area2D
var conductive_grooves: Area2D
var salt_deposits: Area2D
var signal_wires: Area2D
var boundary_stones: Area2D
var path_back: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act1_07_lighthouse_exterior.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	# Marrow Quill — waiting by the door, facing left toward the player
	SceneBuilder.build_npc(props, "MarrowNPC", Vector2(360, 270),
		"Marrow Quill", "marrow", Vector2(-30, 10), true, Vector2(40, 50))

	# Lighthouse door — the main puzzle target
	SceneBuilder.build_hotspot(props, "LighthouseDoor", Vector2(420, 240),
		"the lighthouse door", Vector2(-30, 30), Vector2(60, 70))

	# Beacon crank — exterior mechanism
	SceneBuilder.build_prop(props, "BeaconCrank", Vector2(500, 260),
		"the beacon crank", "res://assets/props/beacon_crank.png",
		Vector2(-20, 20), false, false, Vector2(36, 36))

	# Conductive grooves around the door
	SceneBuilder.build_hotspot(props, "ConductiveGrooves", Vector2(380, 260),
		"conductive grooves", Vector2(0, 15), Vector2(50, 30))

	# Salt deposits on the cliff face
	SceneBuilder.build_prop(props, "SaltDeposits", Vector2(150, 270),
		"salt deposits", "res://assets/props/seashell.png",
		Vector2(15, 15), true, false, Vector2(30, 30))

	# Dead signal wires along the tower
	SceneBuilder.build_hotspot(props, "SignalWires", Vector2(460, 210),
		"dead signal wires", Vector2(-10, 50), Vector2(40, 30))

	# Boundary stones with ancient markings
	SceneBuilder.build_prop(props, "BoundaryStones", Vector2(220, 285),
		"boundary stones", "res://assets/props/boundary_stone.png",
		Vector2(10, 5), false, false, Vector2(40, 30))

	# Path back to harbor cliffs
	SceneBuilder.build_hotspot(hotspots, "PathBack", Vector2(60, 280),
		"the cliffs path", Vector2(30, 5), Vector2(50, 50))

func _get_music_path() -> String:
	return "res://assets/music/lighthouse_ambient.wav"

func _on_room_ready() -> void:
	room_name = "lighthouse_exterior"

	speaker_to_node = {
		"MARROW": "MarrowNPC"
	}

	marrow_npc = $Props/MarrowNPC
	lighthouse_door = $Props/LighthouseDoor
	beacon_crank = $Props/BeaconCrank
	conductive_grooves = $Props/ConductiveGrooves
	salt_deposits = $Props/SaltDeposits
	signal_wires = $Props/SignalWires
	boundary_stones = $Props/BoundaryStones
	path_back = $Hotspots/PathBack

	for node in [marrow_npc, lighthouse_door, beacon_crank, conductive_grooves,
				 salt_deposits, signal_wires, boundary_stones, path_back]:
		if node:
			connect_clickable(node)

	# Hide salt deposits if already collected
	if GameState.has_item("salt_paste") and salt_deposits:
		salt_deposits.hide_object()

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"lighthouse_chamber":
			return Vector2(400, 290)
		_:
			return Vector2(100, 290)

func _play_intro() -> void:
	is_busy = true
	_in_scripted_sequence = true

	# Fade in
	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw.finished
		fade_overlay.visible = false

	await _say("Hushlight Lighthouse. Salt-grey tower, brass braces, dead signal wires. Long shuttered. Not forgotten.")

	# Marrow is already there
	await _say_as("MARROW", "You came quickly.")
	await _say("I dislike being expected by strangers.")
	await _say_as("MARROW", "Then you will dislike the rest of this story.")

	await get_tree().create_timer(0.3).timeout
	GameState.set_flag("met_marrow")

	_in_scripted_sequence = false
	is_busy = false

# ============================================================
# VERB ACTIONS
# ============================================================

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"MarrowNPC":
			await _say("Tall. Still. The kind of patience that comes from knowing things nobody wants to hear.")
			if GameState.has_flag("met_marrow"):
				await _say("She looks at the lighthouse the way people look at homes they lost.")
		"LighthouseDoor":
			if GameState.has_flag("door_opened"):
				await _say("The door stands open. The lighthouse remembers its purpose.")
			else:
				await _say("Heavy iron door, sealed shut. Conductive grooves frame the edges like circuitry.")
				await _say("Something is supposed to flow through here. Current. Signal. Memory.")
		"BeaconCrank":
			await _say("An exterior beacon mechanism. The handle is stiff but intact.")
			if not GameState.has_flag("grooves_filled") or not GameState.has_flag("strip_inserted"):
				await _say("Turning it now would just grind gears. The circuit isn't complete.")
		"ConductiveGrooves":
			if GameState.has_flag("grooves_filled"):
				await _say("The grooves gleam with conductive salt paste. Ready for a signal.")
			else:
				await _say("Channels carved into the door frame. They need something conductive to carry current.")
		"SaltDeposits":
			await _say("Mineral crusts from the sea spray. Conductive, if you scraped enough of it together.")
		"SignalWires":
			await _say("Corroded copper. These once carried signals from the beacon to somewhere inland.")
			await _say("Whatever network this was part of, it went dark a long time ago.")
		"BoundaryStones":
			await _say("Same symbol family as the brass strip. Either I'm on the right path or the entire coastline has started following me.")
		"PathBack":
			await _say("The wind-battered path back down the cliffs.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"MarrowNPC":
			var tree := _build_marrow_dialogue()
			await run_dialogue_tree(tree)
		"LighthouseDoor":
			await _say("I knock. No answer. Lighthouses are famously poor conversationalists.")
		_:
			await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"SaltDeposits":
			if not GameState.has_item("salt_paste"):
				await _say("I scrape the mineral deposits into a crude paste. Gritty, conductive, and deeply unpleasant.")
				give_item("salt_paste")
				salt_deposits.hide_object()
			else:
				await _say("I have enough salt paste. More than enough, really.")
		"BeaconCrank":
			await _say("It's bolted to the tower. I'd need to remove the entire lighthouse.")
		"BoundaryStones":
			await _say("They've been here longer than Blackwake. I'll leave them be.")
		_:
			await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"BeaconCrank":
			if GameState.has_flag("grooves_filled") and GameState.has_flag("strip_inserted"):
				await _say("I turn the crank. It resists, then catches. A deep hum rises through the tower.")
				await _say("Current flows through the grooves. The brass strip vibrates. The door shudders.")
				await get_tree().create_timer(0.5).timeout
				await _say_as("MARROW", "It still knows the route.")
				await _say("Route to what.")
				await _say_as("MARROW", "To what was hidden.")
				GameState.set_flag("door_opened")
				play_sfx(_sfx_puzzle)
				await _say("The lighthouse door grinds open, spilling dust and stale light.")
			elif GameState.has_flag("grooves_filled"):
				await _say("The crank turns but nothing happens. The grooves have paste, but the circuit still needs a key.")
			elif GameState.has_flag("strip_inserted"):
				await _say("The crank turns. The strip buzzes. But without conductive paste in the grooves, the current has nowhere to go.")
			else:
				await _say("I crank the handle. Gears grind. Nothing happens. The circuit is incomplete.")
		"LighthouseDoor":
			if GameState.has_flag("door_opened"):
				go_to_room("res://scenes/rooms/lighthouse_chamber.tscn")
			else:
				await _say("Sealed shut. I need to complete the circuit first.")
		"PathBack":
			go_to_room("res://scenes/rooms/harbor_cliffs.tscn")
		_:
			await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"LighthouseDoor":
			if GameState.has_flag("door_opened"):
				go_to_room("res://scenes/rooms/lighthouse_chamber.tscn")
			else:
				await _say("The door won't budge. It's not locked — it's disconnected. The mechanism needs power.")
		"PathBack":
			go_to_room("res://scenes/rooms/harbor_cliffs.tscn")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	match obj.name:
		"LighthouseDoor":
			await _say("I throw my weight against it. The lighthouse is unimpressed.")
		"BeaconCrank":
			await _say("It's meant to be turned, not pushed. Even I know that.")
		_:
			await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"ConductiveGrooves":
			if item_name == "salt_paste":
				await _say("I smear the salt paste into the grooves. It fills the channels, gleaming faintly.")
				await _say("Conductive. Now something needs to flow through it.")
				GameState.set_flag("grooves_filled")
				return true
		"LighthouseDoor":
			if item_name == "salt_paste":
				await _say("I smear the paste into the grooves around the door. The channels fill perfectly.")
				GameState.set_flag("grooves_filled")
				return true
			if item_name == "brass_strip":
				if GameState.has_flag("grooves_filled"):
					await _say("I slide the engraved strip into the slot above the door. It clicks into place.")
					await _say("The symbols align with the grooves. Waiting for current.")
					GameState.set_flag("strip_inserted")
					return true
				else:
					await _say("The strip fits a slot in the door, but the grooves around it are empty. I need something conductive first.")
					return true
		"ConductiveGrooves":
			if item_name == "brass_strip":
				if GameState.has_flag("grooves_filled"):
					await _say("I slide the strip into the slot. It locks in, connecting to the conductive grooves.")
					GameState.set_flag("strip_inserted")
					return true
				else:
					await _say("The grooves are empty. I should fill them with something conductive first.")
					return true
		"BeaconCrank":
			if item_name == "salt_paste" or item_name == "brass_strip":
				await _say("The crank doesn't need that. The door mechanism does.")
				return true
	return false

# ============================================================
# DIALOGUE TREES
# ============================================================

func _build_marrow_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	tree.add_node("start", "MARROW", "The lighthouse has been waiting. As have I.")
	tree.add_choice("start", "Who are you?", "who_q")
	tree.add_choice("start", "Do you know this symbol?", "symbol_q", "lighthouse_discovered")
	tree.add_choice("start", "Are you going to explain anything plainly?", "plain_q")

	# Who are you branch
	tree.add_node("who_q", "MARROW", "Someone who stayed too near the shore for too long.")
	tree.add_node("who_2", "ROWAN", "That's not an answer.")
	tree.add_node("who_3", "MARROW", "It is the answer that fits this moment. Others will come.", "end")
	tree.nodes["who_q"].next_id = "who_2"
	tree.nodes["who_2"].next_id = "who_3"

	# Symbol knowledge branch
	tree.add_node("symbol_q", "MARROW", "I know what it guarded. I know what it forgot. I know what it has begun to remember.")
	tree.add_node("symbol_2", "ROWAN", "That's three things and none of them are useful.")
	tree.add_node("symbol_3", "MARROW", "Patience is the gap between noise and signal.", "end")
	tree.nodes["symbol_q"].next_id = "symbol_2"
	tree.nodes["symbol_2"].next_id = "symbol_3"

	# Plain explanation branch
	tree.add_node("plain_q", "MARROW", "Plain explanations are for plain times.")
	tree.add_node("plain_2", "ROWAN", "That's infuriating.")
	tree.add_node("plain_3", "MARROW", "Yes.", "end")
	tree.nodes["plain_q"].next_id = "plain_2"
	tree.nodes["plain_2"].next_id = "plain_3"

	tree.add_node("end", "MARROW", "Open the door. The rest follows.")

	return tree
