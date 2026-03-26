extends AdventureRoom

## Wake Sea Passage — Act 3, Room 19 (Cutscene/Dialogue)
## Transit through submerged channels. Memory Vision 4. Marrow confrontation.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var sea_view: Area2D
var cradle_interior: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act3_04_wake_passage.png")
	if tex: bg.texture = tex

func _build_room() -> void:
	var props := $Props
	SceneBuilder.build_player_sprite($Player)
	SceneBuilder.build_hotspot(props, "SeaView", Vector2(320, 200),
		"the sea beyond the glass", Vector2(0, 60), Vector2(200, 80))
	SceneBuilder.build_hotspot(props, "CradleInterior", Vector2(320, 280),
		"the cradle interior", Vector2(0, 0), Vector2(100, 40))

func _on_room_ready() -> void:
	room_name = "wake_passage"
	sea_view = $Props/SeaView; cradle_interior = $Props/CradleInterior
	for node in [sea_view, cradle_interior]:
		if node: connect_clickable(node)

func _get_entry_position() -> Vector2:
	return Vector2(320, 290)

func _play_intro() -> void:
	is_busy = true; _in_scripted_sequence = true
	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 1.2)
		await tw.finished; fade_overlay.visible = false

	await _say("Glass-smooth walls. Illuminated current veins. Impossible arches beneath the sea. Vast fish drift past like thoughts.")
	await _say_as("TIBBIT", "I revise every opinion I've ever held about engineering.")
	await _say("All of them?")
	await _say_as("TIBBIT", "No. Rivets remain excellent.")
	await get_tree().create_timer(0.5).timeout

	# Rowan confronts Marrow
	await _say("You knew, didn't you. About me.")
	await _say_as("MARROW", "Yes.")
	await _say("Why didn't you tell me at the start?")
	await _say_as("MARROW", "Because truths given too early become costumes. I needed you to arrive as yourself.")
	await get_tree().create_timer(0.3).timeout

	# Memory Vision 4
	if fade_overlay:
		fade_overlay.visible = true
		var tw2 := create_tween()
		tw2.tween_property(fade_overlay, "color", Color(0.95, 0.9, 0.7, 0.8), 0.5)
		await tw2.finished

	await _say("Night on the island. Panic. Alarm bells. Rowan's mother places a child into a transit cradle with a young Marrow.")
	await _say("MOTHER: If the councils fail, the road must survive outside us.")
	await _say("YOUNG MARROW: I'll bring the child back.")
	await _say("MOTHER: No. Bring them back only when the island is ready to be remembered.")

	if fade_overlay:
		var tw3 := create_tween()
		tw3.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 0.8)
		await tw3.finished; fade_overlay.visible = false

	await _say("You were there. You took me away.")
	await _say_as("MARROW", "I saved what I could.")
	await _say("Then let's see what you saved it for.")
	GameState.set_flag("memory_vision_4")
	await get_tree().create_timer(0.5).timeout
	await _say("A great gate of white stone opens in the sea. Light floods in.")

	_in_scripted_sequence = false; is_busy = false
	go_to_room("res://scenes/rooms/isle_auric.tscn")

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"SeaView": await _say("The ocean floor passes beneath us. Ancient architecture lines the route like a highway.")
		"CradleInterior": await _say("The cradle hums around us. Warm, clean, and profoundly alien.")
		_: await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	await _say(_random_response(_TALK_RESPONSES))
func _pick_up(obj: Clickable) -> void:
	await _say(_random_response(_PICK_UP_RESPONSES))
func _use(obj: Clickable) -> void:
	await _say(_random_response(_USE_RESPONSES))
func _open(obj: Clickable) -> void:
	await _say(_random_response(_OPEN_RESPONSES))
func _push(obj: Clickable) -> void:
	await _say(_random_response(_PUSH_RESPONSES))
func _on_use_item(_item_name: String, _target: Clickable) -> bool:
	return false
