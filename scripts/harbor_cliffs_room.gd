extends AdventureRoom

## Harbor Cliffs Path — Act 1, Room 6
## Wind-battered cliff path above the sea. Atmospheric transition.
## Marrow Quill waits at the top near the lighthouse.

# Room-specific clickables
var boundary_stone_1: Area2D
var boundary_stone_2: Area2D
var iron_railings: Area2D
var sea_view: Area2D
var marrow_npc: Area2D
var door_workshop: Area2D
var door_lighthouse: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act1_06_harbor_cliffs.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	var SceneBuilder = preload("res://scripts/scene_builder.gd")

	# Build player sprite
	SceneBuilder.build_player_sprite($Player)

	# Boundary stones — ancient markings
	SceneBuilder.build_prop(props, "BoundaryStone1", Vector2(200, 270),
		"a boundary stone", "res://assets/props/boundary_stone.png",
		Vector2(15, 15), false, false, Vector2(28, 40))

	SceneBuilder.build_prop(props, "BoundaryStone2", Vector2(420, 255),
		"another boundary stone", "res://assets/props/boundary_stone.png",
		Vector2(-15, 20), false, false, Vector2(28, 40))

	# Iron railings — atmospheric hotspot
	SceneBuilder.build_hotspot(props, "IronRailings", Vector2(310, 240),
		"the iron railings", Vector2(0, 30), Vector2(100, 20))

	# Sea view — atmospheric hotspot
	SceneBuilder.build_hotspot(hotspots, "SeaView", Vector2(320, 180),
		"the sea below", Vector2(0, 60), Vector2(200, 60))

	# Marrow Quill — waiting near the lighthouse path, facing left
	SceneBuilder.build_npc(props, "MarrowNPC", Vector2(520, 270),
		"a hooded figure", "marrow", Vector2(-25, 5), true, Vector2(40, 50))

	# Exit back to Tibbit's Workshop
	SceneBuilder.build_hotspot(hotspots, "DoorWorkshop", Vector2(60, 270),
		"the path back to the workshop", Vector2(30, 10), Vector2(40, 60))

	# Exit forward to Lighthouse Exterior
	SceneBuilder.build_hotspot(hotspots, "DoorLighthouse", Vector2(580, 260),
		"the lighthouse path", Vector2(-30, 15), Vector2(40, 60))

func _on_room_ready() -> void:
	room_name = "harbor_cliffs"

	boundary_stone_1 = $Props/BoundaryStone1
	boundary_stone_2 = $Props/BoundaryStone2
	iron_railings = $Props/IronRailings
	sea_view = $Hotspots/SeaView
	marrow_npc = $Props/MarrowNPC
	door_workshop = $Hotspots/DoorWorkshop
	door_lighthouse = $Hotspots/DoorLighthouse

	# Map speaker names to NPC node names for talk animations
	speaker_to_node = {
		"MARROW": "MarrowNPC"
	}

	for node in [boundary_stone_1, boundary_stone_2, iron_railings, sea_view,
				 marrow_npc, door_workshop, door_lighthouse]:
		if node:
			connect_clickable(node)

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"lighthouse_exterior":
			return Vector2(550, 285)
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

	await _say("The wind hits immediately. Salt spray and the smell of old stone.")

	if not GameState.has_flag("met_marrow"):
		# First meeting with Marrow
		await _say("There's someone waiting at the top of the path.")
		await _say_as("MARROW", "You came quickly.")
		await _say("I dislike being expected by strangers.")
		await _say_as("MARROW", "Then you will dislike the rest of this story.")
		GameState.set_flag("met_marrow")

	_in_scripted_sequence = false
	is_busy = false

# ============================================================
# VERB ACTIONS
# ============================================================

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"BoundaryStone1":
			await _say("Ancient carved stone. The symbols are worn but recognizable.")
			if not GameState.has_flag("examined_boundary_stone"):
				await _say("Same symbol family as the relic. Which means either I'm on the right path or the entire coastline has started following me.")
				GameState.set_flag("examined_boundary_stone")
		"BoundaryStone2":
			await _say("Another stone. The symbols here are clearer — arrows pointing up the path.")
			if GameState.has_flag("examined_boundary_stone"):
				await _say("Definitely directions. To what, though.")
		"IronRailings":
			await _say("Iron railings, bent by decades of wind. Some are held together with wire and stubbornness.")
		"SeaView":
			await _say("The sea churns below. Waves smash against the cliff face sending up columns of spray.")
			await _say("It's beautiful in the way that things trying to kill you sometimes are.")
		"MarrowNPC":
			if GameState.has_flag("met_marrow"):
				await _say("Marrow Quill. Hooded, patient, and irritatingly cryptic.")
			else:
				await _say("A hooded figure, standing very still. Either waiting or just... standing.")
		"DoorWorkshop":
			await _say("The path back down to Tibbit's workshop.")
		"DoorLighthouse":
			await _say("The path continues up to the Hushlight Lighthouse.")
		_:
			await _say("Nothing remarkable about that.")

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"MarrowNPC":
			var tree := _build_marrow_cliffs_dialogue()
			await run_dialogue_tree(tree)
		"BoundaryStone1", "BoundaryStone2":
			await _say("The stones have plenty to say. None of it in any language I speak.")
		_:
			await _say("Talking to that seems optimistic.")

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"BoundaryStone1", "BoundaryStone2":
			await _say("Ancient, sacred, and weighs more than my future. I'll leave it.")
		"IronRailings":
			await _say("The railings are bolted down. And also the only thing between me and a long fall.")
		_:
			await _say("I can't pick that up.")

func _use(obj: Clickable) -> void:
	match obj.name:
		"DoorWorkshop":
			go_to_room("res://scenes/rooms/tibbit_workshop.tscn")
		"DoorLighthouse":
			go_to_room("res://scenes/rooms/lighthouse_exterior.tscn")
		"IronRailings":
			await _say("I lean on the railing. It groans. I stop leaning.")
		_:
			await _say("I don't know how to use that on its own.")

func _open(obj: Clickable) -> void:
	match obj.name:
		"DoorWorkshop":
			go_to_room("res://scenes/rooms/tibbit_workshop.tscn")
		"DoorLighthouse":
			go_to_room("res://scenes/rooms/lighthouse_exterior.tscn")
		_:
			await _say("That doesn't open.")

func _push(obj: Clickable) -> void:
	match obj.name:
		"BoundaryStone1", "BoundaryStone2":
			await _say("Pushing an ancient boundary marker feels like it would come with consequences.")
		"IronRailings":
			await _say("I'd rather not test how well-anchored these are.")
		_:
			await _say("Pushing that accomplishes nothing except proving I tried.")

func _on_use_item(_item_name: String, _target: Clickable) -> bool:
	return false

# ============================================================
# DIALOGUE TREES
# ============================================================

func _build_marrow_cliffs_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	tree.add_node("start", "MARROW", "Ask your questions. The wind will not wait.")
	tree.add_choice("start", "Who are you?", "who_q", "", "asked_who_marrow")
	tree.add_choice("start", "What do you know about the relic?", "relic_q")
	tree.add_choice("start", "Why are you waiting here?", "waiting_q")

	# Who question
	tree.add_node("who_q", "MARROW", "I am Marrow Quill. I keep records of things people prefer to forget.")
	tree.add_node("who_q2", "ROWAN", "That sounds like a lonely profession.")
	tree.add_node("who_q3", "MARROW", "Accurate.", "end")
	tree.set_node_flag("who_q", "asked_who_marrow")
	tree.nodes["who_q"].next_id = "who_q2"
	tree.nodes["who_q2"].next_id = "who_q3"

	# Relic question
	tree.add_node("relic_q", "MARROW", "It is not a relic. It is a key. And you are not the first to turn it.")
	tree.add_node("relic_q2", "ROWAN", "What does it unlock?")
	tree.add_node("relic_q3", "MARROW", "The lighthouse will show you. If you can make it see.", "end")
	tree.nodes["relic_q"].next_id = "relic_q2"
	tree.nodes["relic_q2"].next_id = "relic_q3"

	# Waiting question
	tree.add_node("waiting_q", "MARROW", "Because the stones told me someone was coming.")
	tree.add_node("waiting_q2", "ROWAN", "The stones told you.")
	tree.add_node("waiting_q3", "MARROW", "You read them too. You just didn't listen.", "end")
	tree.nodes["waiting_q"].next_id = "waiting_q2"
	tree.nodes["waiting_q2"].next_id = "waiting_q3"

	tree.add_node("end", "MARROW", "The lighthouse is ahead. I suggest you hurry. Others are watching.")

	return tree
