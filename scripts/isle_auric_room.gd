extends AdventureRoom

## Isle Auric — Act 3, Rooms 20-21 combined (Harbor + Council Gardens)
## Meet Sel, Ilyan, Seraphine. Island truth revealed. Rook arrives.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var sel_npc: Area2D
var ilyan_npc: Area2D
var seraphine_npc: Area2D
var harbor_view: Area2D
var gardens: Area2D
var terraces: Area2D
var canals: Area2D
var path_gate: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act3_05_isle_auric_harbor.png")
	if not tex: tex = _load_texture("res://assets/backgrounds/act3_06_council_gardens.png")
	if tex: bg.texture = tex

func _build_room() -> void:
	var props := $Props; var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)
	SceneBuilder.build_npc(props, "SelNPC", Vector2(200, 270),
		"Archivist Sel", "sel", Vector2(25, 5), false, Vector2(40, 50))
	SceneBuilder.build_npc(props, "IlyanNPC", Vector2(350, 265),
		"Councilor Ilyan", "ilyan", Vector2(-20, 10), true, Vector2(40, 50))
	SceneBuilder.build_npc(props, "SeraphineNPC", Vector2(480, 270),
		"Warden Seraphine", "seraphine", Vector2(-25, 5), true, Vector2(40, 50))
	SceneBuilder.build_hotspot(props, "HarborView", Vector2(320, 190),
		"the luminous harbor", Vector2(0, 65), Vector2(200, 60))
	SceneBuilder.build_hotspot(props, "Gardens", Vector2(150, 240),
		"the silver-leaf gardens", Vector2(20, 30), Vector2(60, 40))
	SceneBuilder.build_hotspot(props, "Terraces", Vector2(500, 230),
		"white terraces", Vector2(-20, 35), Vector2(50, 30))
	SceneBuilder.build_hotspot(props, "Canals", Vector2(320, 280),
		"clear canals", Vector2(0, 0), Vector2(80, 20))
	SceneBuilder.build_hotspot(hotspots, "PathGate", Vector2(580, 260),
		"the path to the Harmonic Gate", Vector2(-30, 15), Vector2(40, 60))

func _on_room_ready() -> void:
	room_name = "isle_auric"
	sel_npc = $Props/SelNPC; ilyan_npc = $Props/IlyanNPC; seraphine_npc = $Props/SeraphineNPC
	harbor_view = $Props/HarborView; gardens = $Props/Gardens
	terraces = $Props/Terraces; canals = $Props/Canals; path_gate = $Hotspots/PathGate
	speaker_to_node = {"SEL": "SelNPC", "ILYAN": "IlyanNPC", "SERAPHINE": "SeraphineNPC"}
	for node in [sel_npc, ilyan_npc, seraphine_npc, harbor_view, gardens,
				 terraces, canals, path_gate]:
		if node: connect_clickable(node)

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"harmonic_gate": return Vector2(550, 285)
		_: return Vector2(100, 290)

func _play_intro() -> void:
	is_busy = true; _in_scripted_sequence = true
	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 1.0)
		await tw.finished; fade_overlay.visible = false

	await _say_as("TIBBIT", "That's intolerably lovely.")
	await _say("I know.")
	await get_tree().create_timer(0.3).timeout
	await _say_as("SEL", "The key returns.")
	await _say_as("SERAPHINE", "Or the problem does.")
	await _say("I'm Rowan Vale.")
	await _say_as("SERAPHINE", "We know who you were.")
	await _say("That's convenient. I've only just found out.")

	if not GameState.has_flag("island_truth_revealed"):
		await get_tree().create_timer(0.3).timeout
		await _say_as("SEL", "We preserved knowledge. We preserved life. We preserved enough to become afraid of losing either.")
		await _say_as("ILYAN", "The road was meant to sleep, not to die. We hid from the world and called it wisdom until habit became doctrine.")
		await _say_as("SERAPHINE", "The mainland burned itself repeatedly. We survived because we refused its invitations.")
		await _say("So the island isn't calling me home.")
		await _say_as("SEL", "Not only you. It is calling for a decision.")
		await _say_as("TIBBIT", "Machines with constitutional anxiety. Splendid.")
		GameState.set_flag("island_truth_revealed")

	# Rook arrives
	if not GameState.has_flag("rook_at_island"):
		await get_tree().create_timer(0.5).timeout
		await _say("Alarm tones. Rook forced partial passage by chaining his airship to the wake pulse.")
		await _say_as("ROOK", "What a magnificent place. And all this time, hidden from the market.")
		await _say("You say that like it's a tragedy.")
		await _say_as("ROOK", "I say it like it's waste.")
		GameState.set_flag("rook_at_island")

	_in_scripted_sequence = false; is_busy = false

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"SelNPC": await _say("Archivist Sel. Calm, sharp-eyed. Records everything, judges nothing.")
		"IlyanNPC": await _say("Councilor Ilyan. Worn by decades of compromise. Tired but not finished.")
		"SeraphineNPC": await _say("Warden Seraphine. Formal, wary. She protected this place by keeping it sealed.")
		"HarborView": await _say("Luminous white terraces, hanging gardens, clear canals. It's everything the machines promised.")
		"Gardens": await _say("Silver-leaf trees catch light like trapped starlight.")
		"Terraces": await _say("Towers rise like tuned instruments. Bridges curve like calligraphy.")
		"Canals": await _say("Crystal-clear water flows through channels older than Blackwake's dreams.")
		"PathGate": await _say("The path to the Central Harmonic Gate. The island's heart.")
		_: await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"SelNPC":
			var tree := _build_sel_dialogue()
			await run_dialogue_tree(tree)
		"IlyanNPC":
			var tree := _build_ilyan_dialogue()
			await run_dialogue_tree(tree)
		"SeraphineNPC":
			var tree := _build_seraphine_dialogue()
			await run_dialogue_tree(tree)
		_: await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"PathGate": go_to_room("res://scenes/rooms/harmonic_gate.tscn")
		_: await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"PathGate": go_to_room("res://scenes/rooms/harmonic_gate.tscn")
		_: await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(_item_name: String, _target: Clickable) -> bool:
	return false

func _build_sel_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.add_node("start", "SEL", "I am the keeper of what was. Ask, and I will share what I can.")
	tree.add_choice("start", "Tell me about the island", "history")
	tree.add_choice("start", "What do I need to do?", "task")
	tree.add_node("history", "SEL", "Isle Auric was built as proof that harmony could govern. For centuries, it did. Then fear won a single vote.")
	tree.add_node("history2", "SEL", "The road closed. The world forgot. We remembered too much and decided too little.", "end")
	tree.nodes["history"].next_id = "history2"
	tree.add_node("task", "SEL", "The Harmonic Gate is the island's civic heart. It requires three seals to stabilize: bloodline, warden, and council.")
	tree.add_node("task2", "SEL", "You carry the bloodline. Seraphine holds the warden seal. Ilyan, the council's.", "end")
	tree.nodes["task"].next_id = "task2"
	tree.add_node("end", "SEL", "The gate is past the gardens. Go when you are ready.")
	return tree

func _build_ilyan_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.add_node("start", "ILYAN", "I have spent fifty years arguing for reopening. I am tired of being right and ignored.")
	tree.add_choice("start", "Will you help at the gate?", "help")
	tree.add_choice("start", "What happened to the factions?", "factions")
	tree.add_node("help", "ILYAN", "I will. But carefully. Opening a road carelessly proves every fear that closed it.", "end")
	tree.add_node("factions", "ILYAN", "One side wanted safety. One side wanted connection. Both were correct. Neither could admit the other was, too.", "end")
	tree.add_node("end", "ILYAN", "I will be at the gate. This time, I intend to finish what my generation started.")
	return tree

func _build_seraphine_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.add_node("start", "SERAPHINE", "You bring the outside world with you. Forgive me for being cautious.")
	tree.add_choice("start", "I understand your caution", "understand")
	tree.add_choice("start", "The island can't stay sealed forever", "challenge")
	tree.add_node("understand", "SERAPHINE", "Then you understand more than most who have come here with keys.", "end")
	tree.add_node("challenge", "SERAPHINE", "Perhaps not. But an open gate is not the same as an open invitation.")
	tree.add_node("challenge2", "SERAPHINE", "If you can convince me this will be controlled, I will place my seal.", "end")
	tree.nodes["challenge"].next_id = "challenge2"
	tree.add_node("end", "SERAPHINE", "I will be watching. As always.")
	return tree
