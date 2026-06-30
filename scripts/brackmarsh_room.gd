extends AdventureRoom

## The Brackmarsh — Act 2, Room 10
## Vast wetland with fog. Sister Caligo. Puzzle 2: Navigate the Mirror Fog.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var caligo_npc: Area2D
var standing_mirror_1: Area2D
var standing_mirror_2: Area2D
var standing_mirror_3: Area2D
var bell_rope: Area2D
var reed_skiff: Area2D
var chapel_door: Area2D
var brass_curtain_rod: Area2D
var chapel_hand_mirror: Area2D
var path_back: Area2D
var path_forward: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act2_02_brackmarsh.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	# Sister Caligo — sardonic chapel caretaker
	SceneBuilder.build_npc(props, "CaligoNPC", Vector2(200, 270),
		"Sister Caligo", "caligo", Vector2(25, 5), false, Vector2(40, 50))

	# Standing mirrors in the marsh
	SceneBuilder.build_prop(props, "StandingMirror1", Vector2(350, 255),
		"a standing mirror", "res://assets/props/black_shard.png",
		Vector2(0, 20), false, false, Vector2(24, 48))

	SceneBuilder.build_prop(props, "StandingMirror2", Vector2(430, 245),
		"a standing mirror", "res://assets/props/black_shard.png",
		Vector2(0, 25), false, false, Vector2(24, 48))

	SceneBuilder.build_prop(props, "StandingMirror3", Vector2(500, 260),
		"a standing mirror", "res://assets/props/black_shard.png",
		Vector2(-15, 15), false, false, Vector2(24, 48))

	# Bell rope at the chapel
	SceneBuilder.build_hotspot(props, "BellRope", Vector2(170, 210),
		"the bell rope", Vector2(10, 50), Vector2(20, 40))

	# Reed skiff in the marsh
	SceneBuilder.build_prop(props, "ReedSkiff", Vector2(300, 290),
		"a reed skiff", "res://assets/props/lighthouse_crate.png",
		Vector2(10, 0), false, false, Vector2(44, 24))

	# Brass curtain rod — leaning against the chapel wall
	SceneBuilder.build_prop(props, "BrassCurtainRod", Vector2(130, 280),
		"a brass curtain rod", "res://assets/props/brass_key.png",
		Vector2(15, 5), true, false, Vector2(28, 20))

	# Chapel hand mirror — on the chapel steps
	SceneBuilder.build_prop(props, "ChapelHandMirror", Vector2(220, 285),
		"a small hand mirror", "res://assets/props/black_shard.png",
		Vector2(5, 5), true, false, Vector2(20, 20))

	# Chapel door
	SceneBuilder.build_hotspot(props, "ChapelDoor", Vector2(160, 250),
		"the chapel", Vector2(20, 20), Vector2(40, 40))

	SceneBuilder.build_hotspot(hotspots, "PathBack", Vector2(60, 275),
		"the smuggler path", Vector2(30, 5), Vector2(40, 60))

	var fwd = SceneBuilder.build_hotspot(hotspots, "PathForward", Vector2(580, 255),
		"the tower path", Vector2(-30, 15), Vector2(40, 60))
	if not GameState.has_flag("fog_cleared"):
		fwd.hide_object()

func _get_music_path() -> String:
	return "res://assets/music/lighthouse_ambient.wav"

func _on_room_ready() -> void:
	room_name = "brackmarsh"

	caligo_npc = $Props/CaligoNPC
	standing_mirror_1 = $Props/StandingMirror1
	standing_mirror_2 = $Props/StandingMirror2
	standing_mirror_3 = $Props/StandingMirror3
	bell_rope = $Props/BellRope
	reed_skiff = $Props/ReedSkiff
	chapel_door = $Props/ChapelDoor
	brass_curtain_rod = $Props/BrassCurtainRod
	chapel_hand_mirror = $Props/ChapelHandMirror
	path_back = $Hotspots/PathBack
	path_forward = $Hotspots/PathForward

	speaker_to_node = {
		"CALIGO": "CaligoNPC"
	}

	for node in [caligo_npc, standing_mirror_1, standing_mirror_2, standing_mirror_3,
				 bell_rope, reed_skiff, chapel_door, brass_curtain_rod, chapel_hand_mirror,
				 path_back, path_forward]:
		if node:
			connect_clickable(node)

	# Hide brass curtain rod if already picked up
	if GameState.has_item("brass_curtain_rod") and brass_curtain_rod:
		brass_curtain_rod.hide_object()

	# Hide chapel hand mirror if already picked up
	if GameState.has_item("chapel_hand_mirror") and chapel_hand_mirror:
		chapel_hand_mirror.hide_object()

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"relay_tower":
			return Vector2(550, 280)
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

	if not GameState.has_flag("met_caligo"):
		await _say("The marsh stretches in every direction. Fog clings to everything like regret.")
		await _say_as("CALIGO", "Travelers usually come here to disappear. You look like you're trying to arrive.")
		await _say("I'm still deciding which would be more restful.")
		GameState.set_flag("met_caligo")
	else:
		await _say("Back in the marsh. The fog hasn't improved its personality.")

	_in_scripted_sequence = false
	is_busy = false

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"CaligoNPC":
			await _say("Sister Caligo. Lean, sharp-eyed, and dressed like the marsh tried to claim her and lost.")
		"StandingMirror1", "StandingMirror2", "StandingMirror3":
			await _say("Black glass panels sunk in the mud. They look less like they were placed here and more like the earth failed to digest them.")
			if not GameState.has_flag("examined_mirrors"):
				await _say("Not mirrors. Markers. They can be rotated.")
				GameState.set_flag("examined_mirrors")
		"BellRope":
			await _say("A rope that says, in no uncertain terms, 'Do not make the marsh louder.'")
		"ReedSkiff":
			await _say("Small, damp, and deeply committed to not being a full boat.")
		"BrassCurtainRod":
			await _say("A brass curtain rod from the chapel. Sturdy and surprisingly well-polished.")
		"ChapelHandMirror":
			await _say("A small hand mirror. The chapel uses these for the fog lanterns.")
		"ChapelDoor":
			await _say("A small chapel on stilts, leaning over the marsh with theological determination.")
		"PathBack":
			await _say("The path back to the smuggler trail.")
		"PathForward":
			await _say("The fog has parted. The tower path is clear.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"CaligoNPC":
			var tree := _build_caligo_dialogue()
			await run_dialogue_tree(tree)
		_:
			await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"BrassCurtainRod":
			if not GameState.has_item("brass_curtain_rod"):
				await _say("Sister Caligo won't miss one curtain rod. The chapel has plenty.")
				give_item("brass_curtain_rod")
				brass_curtain_rod.hide_object()
			else:
				await _say("I already have one.")
		"ChapelHandMirror":
			if not GameState.has_item("chapel_hand_mirror"):
				await _say("A hand mirror. Useful for fog navigation or checking my increasingly haunted expression.")
				give_item("chapel_hand_mirror")
				chapel_hand_mirror.hide_object()
			else:
				await _say("I already have one.")
		"BellRope":
			await _say("It's attached to a bell. Pulling it would ring it, not pocket it.")
		"ReedSkiff":
			await _say("It's a boat. A bad one, but still a boat. I can't carry a boat.")
		_:
			await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"PathBack":
			go_to_room("res://scenes/rooms/smuggler_path.tscn")
		"PathForward":
			if GameState.has_flag("fog_cleared"):
				go_to_room("res://scenes/rooms/relay_tower.tscn")
			else:
				await _say("The fog is too thick. I can't see the path.")
		"BellRope":
			if not GameState.has_flag("bell_rung_soft"):
				if GameState.has_flag("examined_mirrors"):
					await _say("I give the bell a gentle pull. A soft tone rings out across the marsh.")
					await _say("One of the standing markers vibrates. The first one.")
					GameState.set_flag("bell_rung_soft")
					GameState.set_flag("first_marker_found")
				else:
					await _say("I yank the bell rope. The marsh erupts with birds. A mud vent explodes.")
					await _say_as("CALIGO", "Congratulations. You have summoned every creature except wisdom.")
					await _say("I'll try a gentler approach next time. After examining those markers.")
			else:
				await _say("I've already found the resonant marker. Time to align them.")
		"StandingMirror1", "StandingMirror2", "StandingMirror3":
			if GameState.has_flag("first_marker_found"):
				if not GameState.has_flag("markers_rotated"):
					await _say("I use the rusted bar to rotate each marker toward the next. They grind into alignment.")
					GameState.set_flag("markers_rotated")
				else:
					await _say("The markers are aligned. I need to catch the light through them.")
			else:
				await _say("The markers are stuck. I need to figure out which one resonates first.")
		"ChapelDoor":
			await _say("The chapel is Caligo's domain. I should talk to her.")
		_:
			await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"PathBack":
			go_to_room("res://scenes/rooms/smuggler_path.tscn")
		"PathForward":
			if GameState.has_flag("fog_cleared"):
				go_to_room("res://scenes/rooms/relay_tower.tscn")
			else:
				await _say("Can't see where I'm going. The fog wins for now.")
		"ChapelDoor":
			await _say("Caligo's chapel. I should ask before barging in.")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	match obj.name:
		"StandingMirror1", "StandingMirror2", "StandingMirror3":
			await _say("They need to be rotated precisely, not shoved.")
		_:
			await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"StandingMirror1", "StandingMirror2", "StandingMirror3":
			if item_name == "chapel_hand_mirror":
				if GameState.has_flag("markers_rotated"):
					await _say("I hold the hand mirror up. Light catches, refracts through the aligned markers.")
					await _say("The fog parts like a curtain. A black stone tower rises from the marsh like a spearhead.")
					GameState.set_flag("fog_cleared")
					if path_forward:
						path_forward.show_object()
					return true
				else:
					await _say("The markers aren't aligned yet. The light just scatters.")
					return true
		"CaligoNPC":
			if item_name == "brass_curtain_rod":
				await _say("Caligo doesn't need a brass rod. She needs... actually, maybe I should ask her.")
				return true
	return false

func _build_caligo_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	tree.add_node("start", "CALIGO", "You have the look of someone who needs something they cannot name.")
	tree.add_choice("start", "Do you know about old towers in the marsh?", "towers_q")
	tree.add_choice("start", "What are those standing mirrors?", "mirrors_q")
	tree.add_choice("start", "Has anyone else come through?", "others_q")
	tree.add_choice("start", "I need a hand mirror", "mirror_ask", "examined_mirrors", "has_chapel_mirror")

	tree.add_node("towers_q", "CALIGO", "Plenty. The marsh swallows fools, the tower confuses survivors, and both have terrible hospitality.")
	tree.add_node("towers_q2", "ROWAN", "Encouraging.")
	tree.add_node("towers_q3", "CALIGO", "I didn't promise encouragement. I promised honesty. One of those is useful.", "end")
	tree.nodes["towers_q"].next_id = "towers_q2"
	tree.nodes["towers_q2"].next_id = "towers_q3"

	tree.add_node("mirrors_q", "CALIGO", "Not mirrors. Markers. They reflect what the fog wants you to see, which is usually nothing useful.")
	tree.add_node("mirrors_q2", "CALIGO", "But if you align them correctly... the fog yields. It respects geometry more than prayer.", "end")
	tree.nodes["mirrors_q"].next_id = "mirrors_q2"

	tree.add_node("others_q", "CALIGO", "Men in polished boots. Too clean for common sense. So yes, trouble is ahead of you.")
	tree.add_node("others_q2", "ROWAN", "Rook's people.")
	tree.add_node("others_q3", "CALIGO", "Whoever they serve, they serve loudly.", "end")
	tree.nodes["others_q"].next_id = "others_q2"
	tree.nodes["others_q2"].next_id = "others_q3"

	tree.add_node("mirror_ask", "CALIGO", "The chapel mirror? It's been collecting dust since before I arrived. Take it. It judges silently, like most useful tools.")
	tree.set_node_flag("mirror_ask", "has_chapel_mirror")
	tree.set_node_item("mirror_ask", "chapel_hand_mirror")
	tree.nodes["mirror_ask"].next_id = "end"

	tree.add_node("end", "CALIGO", "The marsh is patient. You shouldn't be.")

	return tree
