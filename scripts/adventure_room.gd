class_name AdventureRoom
extends Node2D

## Base class for all rooms in The Iron Wake.
## Provides: verb-based click handling, dialogue, room transitions,
## inventory integration, and player control.
## Subclasses override _look_at(), _talk_to(), _pick_up(), etc.

# Room identity
@export var room_name: String = ""
@export var room_scene_path: String = ""  # res:// path to this room's .tscn

# UI references — set in _ready or by scene tree
@onready var player: CharacterBody2D = $Player
@onready var dialogue_box: PanelContainer = $UI/DialogueBox
@onready var inventory: GridContainer = $UI/BottomPanel/HBox/Inventory
@onready var hover_text: Label = $UI/HoverText
@onready var fade_overlay: ColorRect = $UI/FadeOverlay
@onready var verb_panel: GridContainer = $UI/BottomPanel/HBox/VerbPanel

var is_busy := false
var _in_scripted_sequence := false
var selected_inventory_item: String = ""
var current_verb: String = "look_at"

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	_load_room_background()
	_build_room()
	_setup_player()
	_connect_ui()
	_sync_inventory()

	# Check if first visit BEFORE registering
	var is_first_visit := not GameState.has_visited(room_name)

	# Register room visit
	if room_name != "":
		GameState.enter_room(room_name)

	# Room-specific setup (before any fade/intro)
	_on_room_ready()

	# Start screen black for transition
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)
		fade_overlay.visible = true
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if is_first_visit:
		# Intro sequences handle their own fade-in
		_play_intro()
	else:
		# Standard fade-in for revisits
		if fade_overlay:
			var tween := create_tween()
			tween.tween_property(fade_overlay, "color:a", 0.0, 0.8)
			await tween.finished
			fade_overlay.visible = false
		_on_room_entered()

# Override these in subclasses
func _load_room_background() -> void:
	pass

func _build_room() -> void:
	pass

func _on_room_ready() -> void:
	pass

func _play_intro() -> void:
	pass

func _on_room_entered() -> void:
	pass

func _setup_player() -> void:
	if player:
		player.init_sprite()
		# Position player based on which room we came from
		var entry := _get_entry_position()
		if entry != Vector2.ZERO:
			player.global_position = entry

func _get_entry_position() -> Vector2:
	## Override to return spawn position based on GameState.previous_room
	return Vector2.ZERO

func _connect_ui() -> void:
	if verb_panel:
		verb_panel.verb_selected.connect(_on_verb_selected)
	if inventory:
		inventory.item_selected.connect(_on_inventory_item_selected)
		inventory.item_deselected.connect(_on_inventory_item_deselected)
		inventory.items_combined.connect(_on_items_combined)
	if dialogue_box and has_node("UI/DialogueNameLabel"):
		dialogue_box.name_label = $UI/DialogueNameLabel

func _sync_inventory() -> void:
	## Restore inventory from GameState
	if inventory:
		inventory.items = GameState.get_items().duplicate()
		inventory._rebuild_ui()

# ============================================================
# HOVER & INPUT
# ============================================================

func _process(_delta: float) -> void:
	_update_hover()

func _update_hover() -> void:
	if is_busy or not hover_text:
		hover_text.text = "" if hover_text else ""
		return

	var space_state := get_world_2d().direct_space_state
	var mouse_pos := get_global_mouse_position()
	var query := PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var results := space_state.intersect_point(query, 1)

	if results.size() > 0:
		var collider = results[0]["collider"]
		if collider is Clickable and collider.visible:
			var verb_text: String = verb_panel.get_verb_text() if verb_panel else ""
			if selected_inventory_item != "":
				hover_text.text = "Use " + selected_inventory_item.replace("_", " ") + " with " + collider.description
			else:
				hover_text.text = verb_text + " " + collider.description
			return

	hover_text.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if is_busy and dialogue_box and dialogue_box.is_showing and not _in_scripted_sequence:
		if event is InputEventMouseButton and event.pressed:
			dialogue_box.force_dismiss()
			is_busy = false
	if is_busy:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_global_mouse_position()
		if mouse_pos.y > 200 and mouse_pos.y < 350:
			if selected_inventory_item == "" and current_verb != "use":
				player.walk_to(mouse_pos)

# ============================================================
# VERB SYSTEM
# ============================================================

func _on_verb_selected(verb: String) -> void:
	current_verb = verb
	selected_inventory_item = ""
	if inventory:
		inventory.selected_item = ""
		inventory._rebuild_ui()

func _on_object_clicked(obj: Clickable) -> void:
	if is_busy and dialogue_box and dialogue_box.is_showing and not _in_scripted_sequence:
		dialogue_box.force_dismiss()
		is_busy = false
	if is_busy:
		return

	if selected_inventory_item != "":
		_use_item_on(selected_inventory_item, obj)
		return

	is_busy = true
	await player.walk_to_and_wait(obj.get_walk_position())
	player.face_position(obj.global_position)

	match current_verb:
		"look_at":
			await _look_at(obj)
		"talk_to":
			await _talk_to(obj)
		"pick_up":
			await _pick_up(obj)
		"use":
			await _use(obj)
		"open":
			await _open(obj)
		"push":
			await _push(obj)

	is_busy = false

func _on_object_examined(obj: Clickable) -> void:
	if is_busy and dialogue_box and dialogue_box.is_showing and not _in_scripted_sequence:
		dialogue_box.force_dismiss()
		is_busy = false
	if is_busy:
		return
	is_busy = true
	player.face_position(obj.global_position)
	await _look_at(obj)
	is_busy = false

# Override these in subclasses for room-specific responses
func _look_at(obj: Clickable) -> void:
	await _say("Nothing remarkable about that.")

func _talk_to(obj: Clickable) -> void:
	await _say("Talking to that seems optimistic.")

func _pick_up(obj: Clickable) -> void:
	await _say("I can't pick that up.")

func _use(obj: Clickable) -> void:
	await _say("I don't know how to use that on its own.")

func _open(obj: Clickable) -> void:
	await _say("That doesn't open.")

func _push(obj: Clickable) -> void:
	await _say("Pushing that accomplishes nothing except proving I tried.")

func _use_item_on(item_name: String, target: Clickable) -> void:
	is_busy = true
	await player.walk_to_and_wait(target.get_walk_position())
	player.face_position(target.global_position)

	# Subclasses override _on_use_item for room-specific logic
	var handled := await _on_use_item(item_name, target)
	if not handled:
		await _say("I can't use that here.")

	selected_inventory_item = ""
	if inventory:
		inventory.selected_item = ""
		inventory._rebuild_ui()
	is_busy = false

## Override in subclass. Return true if handled.
func _on_use_item(_item_name: String, _target: Clickable) -> bool:
	return false

# ============================================================
# INVENTORY
# ============================================================

func _on_inventory_item_selected(item_name: String) -> void:
	selected_inventory_item = item_name
	current_verb = "use"
	if verb_panel:
		verb_panel._highlight_verb("use")

func _on_inventory_item_deselected() -> void:
	selected_inventory_item = ""

func _on_items_combined(item_a: String, item_b: String) -> void:
	if is_busy:
		return
	is_busy = true
	var handled := await _on_combine_items(item_a, item_b)
	if not handled:
		await _say("I don't think combining those will help.")
	selected_inventory_item = ""
	is_busy = false

## Override in subclass. Return true if handled.
func _on_combine_items(_item_a: String, _item_b: String) -> bool:
	return false

func give_item(item_name: String) -> void:
	GameState.add_item(item_name)
	if inventory:
		inventory.items = GameState.get_items().duplicate()
		inventory._rebuild_ui()

func take_item(item_name: String) -> void:
	GameState.remove_item(item_name)
	if inventory:
		inventory.items = GameState.get_items().duplicate()
		inventory._rebuild_ui()

# ============================================================
# DIALOGUE HELPERS
# ============================================================

func _say(text: String) -> void:
	if not dialogue_box:
		return
	dialogue_box.show_dialogue("ROWAN", text)
	if player:
		player._play_talk()
	await dialogue_box.dialogue_finished
	if player:
		player._play_idle()
	await get_tree().create_timer(0.1).timeout

## Map speaker names to NPC node names for talk animations
var speaker_to_node: Dictionary = {}

func _say_as(speaker: String, text: String) -> void:
	if not dialogue_box:
		return
	dialogue_box.show_dialogue(speaker, text)

	# Animate the speaker
	var npc_sprite: AnimatedSprite2D = null
	if speaker == "ROWAN" and player:
		player._play_talk()
	elif speaker in speaker_to_node:
		var node_name: String = speaker_to_node[speaker]
		var npc := get_node_or_null("Props/" + node_name)
		if npc:
			npc_sprite = npc.get_node_or_null("AnimatedSprite2D")
			if npc_sprite:
				# Play talk animation matching current facing
				var current_anim: String = npc_sprite.animation
				var talk_anim := "talk_left" if "left" in current_anim else "talk_right"
				if npc_sprite.sprite_frames.has_animation(talk_anim):
					npc_sprite.play(talk_anim)

	await dialogue_box.dialogue_finished

	# Return to idle
	if speaker == "ROWAN" and player:
		player._play_idle()
	elif npc_sprite:
		var current_anim: String = npc_sprite.animation
		var idle_anim := "idle_left" if "left" in current_anim else "idle_right"
		if npc_sprite.sprite_frames.has_animation(idle_anim):
			npc_sprite.play(idle_anim)

	await get_tree().create_timer(0.1).timeout

# ============================================================
# DIALOGUE TREE RUNNER
# ============================================================

var _choice_result: String = ""

func run_dialogue_tree(tree: DialogueTree, start_id: String = "") -> void:
	if start_id == "":
		start_id = tree.start_id

	var current_id := start_id
	is_busy = true

	while current_id != "" and current_id in tree.nodes:
		var node: DialogueTree.DialogueNode = tree.nodes[current_id]

		# Check conditions
		if node.condition_flag != "" and not GameState.has_flag(node.condition_flag):
			break
		if node.condition_not_flag != "" and GameState.has_flag(node.condition_not_flag):
			break

		# On-enter effects
		if node.on_enter_flag != "":
			GameState.set_flag(node.on_enter_flag)
		if node.on_enter_item != "":
			give_item(node.on_enter_item)

		# Mark as seen
		GameState.mark_dialogue_seen(node.id)

		# Show the dialogue line
		await _say_as(node.speaker, node.text)

		# Check for choices
		var choices := tree.get_available_choices(current_id)
		if choices.size() > 0:
			var chosen := await _show_choices(choices)
			if chosen.set_flag != "":
				GameState.set_flag(chosen.set_flag)
			current_id = chosen.target_id
		elif node.next_id != "":
			current_id = node.next_id
		else:
			current_id = ""  # End of dialogue

	is_busy = false

func _show_choices(choices: Array[DialogueTree.DialogueChoice]) -> DialogueTree.DialogueChoice:
	_choice_result = ""

	# Create choice buttons container
	var choice_panel := VBoxContainer.new()
	choice_panel.name = "ChoicePanel"
	choice_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	choice_panel.offset_left = -180
	choice_panel.offset_top = -60
	choice_panel.offset_right = 180
	choice_panel.offset_bottom = 60
	choice_panel.add_theme_constant_override("separation", 4)

	for i in range(choices.size()):
		var choice := choices[i]
		var btn := Button.new()
		btn.text = choice.label
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", Color(0.83, 0.66, 0.25))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.4))

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.08, 0.04, 0.95)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.55, 0.41, 0.1)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_right = 3
		style.corner_radius_bottom_left = 3
		style.content_margin_left = 12
		style.content_margin_top = 4
		style.content_margin_right = 12
		style.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", style)

		var hover_style := style.duplicate()
		hover_style.border_color = Color(0.8, 0.6, 0.2)
		hover_style.bg_color = Color(0.18, 0.12, 0.06, 0.95)
		btn.add_theme_stylebox_override("hover", hover_style)

		btn.pressed.connect(func(): _choice_result = choice.target_id)
		choice_panel.add_child(btn)

	$UI.add_child(choice_panel)

	# Wait for a choice
	while _choice_result == "":
		await get_tree().process_frame

	choice_panel.queue_free()

	# Find the chosen choice
	for choice in choices:
		if choice.target_id == _choice_result:
			return choice

	return choices[0]

# ============================================================
# ROOM TRANSITIONS
# ============================================================

func go_to_room(scene_path: String) -> void:
	is_busy = true
	_in_scripted_sequence = true

	# Save inventory to GameState
	if inventory:
		GameState.inventory_items = inventory.items.duplicate()

	# Fade out
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		var tween := create_tween()
		tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)
		await tween.finished

	get_tree().change_scene_to_file(scene_path)

# ============================================================
# CLICKABLE HELPERS
# ============================================================

func connect_clickable(node: Area2D) -> void:
	if node.has_signal("clicked"):
		node.clicked.connect(_on_object_clicked)
	if node.has_signal("right_clicked"):
		node.right_clicked.connect(_on_object_examined)

# ============================================================
# TEXTURE LOADING (robust fallback for missing .import files)
# ============================================================

func _load_texture(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		return load(res_path)
	var abs_path := ProjectSettings.globalize_path(res_path)
	var img := Image.new()
	if img.load(abs_path) == OK:
		return ImageTexture.create_from_image(img)
	return null
