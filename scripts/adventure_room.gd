class_name AdventureRoom
extends Node2D

## Base class for all rooms in The Iron Wake.
## Provides: verb-based click handling, dialogue, room transitions,
## inventory integration, and player control.
## Subclasses override _look_at(), _talk_to(), _pick_up(), etc.

# Room identity
@export var room_name: String = ""
@export var room_scene_path: String = ""  # res:// path to this room's .tscn

# Walkable area bounds (override per room for different layouts)
@export var walkable_y_min: float = 200.0
@export var walkable_y_max: float = 350.0

# The character sprite is 96px tall and centered on its position, so the feet
# rest at position.y + 48. PLAYER_FEET_OFFSET converts a desired floor line into
# a position.y. ROOM_FLOOR maps each room (scene file basename) to the spot where
# the character should stand: x = default spawn column, y = floor line under the feet.
const PLAYER_FEET_OFFSET := 48.0
const ROOM_FLOOR := {
	"main": Vector2(150, 332),
	"customs_shack": Vector2(110, 348),
	"ironwind_airdock": Vector2(185, 340),
	"brass_bazaar": Vector2(110, 342),
	"salvage_warehouse": Vector2(110, 345),
	"tibbit_workshop": Vector2(110, 348),
	"lighthouse_exterior": Vector2(110, 338),
	"harbor_cliffs": Vector2(110, 345),
	"isle_auric": Vector2(120, 342),
	"lighthouse_chamber": Vector2(110, 348),
	"brackmarsh": Vector2(110, 345),
	"cinderglass_valley": Vector2(110, 345),
	"fogwound_ruins": Vector2(110, 348),
	"harmonic_gate": Vector2(110, 348),
	"mountain_breach": Vector2(110, 342),
	"relay_tower": Vector2(110, 345),
	"smuggler_path": Vector2(120, 335),
	"sunken_waystation": Vector2(110, 345),
	"transit_vault": Vector2(110, 348),
	"undersea_transit": Vector2(110, 345),
	"wake_passage": Vector2(110, 345),
}

# UI references — set in _ready or by scene tree
@onready var player: CharacterBody2D = $Player
@onready var dialogue_box = $UI/DialogueBox
var inventory: GridContainer
var hover_text: Label
@onready var fade_overlay: ColorRect = $UI/FadeOverlay
var verb_panel

var is_busy := false
var _in_scripted_sequence := false
var selected_inventory_item: String = ""
var current_verb: String = "look_at"

# SFX players (loaded once, shared across rooms)
var _sfx_pickup: AudioStreamPlayer
var _sfx_door: AudioStreamPlayer
var _sfx_puzzle: AudioStreamPlayer
var _sfx_steam: AudioStreamPlayer
var _sfx_combine: AudioStreamPlayer
var _sfx_vision: AudioStreamPlayer
var _sfx_ui_click: AudioStreamPlayer
var _sfx_error: AudioStreamPlayer

# Music player
var _music_player: AudioStreamPlayer
var _current_music: String = ""

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	_load_sfx()
	_load_room_background()
	_fit_background()
	_build_room()
	_setup_player()
	_connect_ui()
	_style_control_bar()
	_sync_inventory()

	# Check if first visit BEFORE registering
	var is_first_visit := not GameState.has_visited(room_name)

	# Register room visit
	if room_name != "":
		GameState.enter_room(room_name)

	# Room-specific setup (before any fade/intro)
	_on_room_ready()

	# Apply the "new" design pass (clean placeholder overlays, reskin pickups to
	# match inventory icons, fix overlaps). Original version is left untouched so
	# F1 toggles a true before/after.
	if GameState.use_new_assets:
		_apply_new_polish()

	# Start room music (deferred to avoid transition artifacts)
	var music_path := _get_music_path()
	if music_path != "":
		_start_music_deferred.call_deferred(music_path)

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

func _fit_background() -> void:
	## Backgrounds are authored 640x360 but the viewport is 640x480 with a
	## ~108px UI panel at the bottom. Native size leaves an unpainted band just
	## above the panel. In the "new" version we scale the Background sprite so the
	## art fills the entire play area (top of screen down to the panel), removing
	## the black seam. The original version is left untouched for comparison.
	var bg := get_node_or_null("Background")
	if bg == null or not (bg is Sprite2D) or bg.texture == null:
		return
	if not GameState.use_new_assets:
		bg.scale = Vector2.ONE
		bg.position = Vector2.ZERO
		return
	var tex_size: Vector2 = bg.texture.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return
	# Fill the full viewport width and down to just past the panel top (372),
	# so props/characters standing on the painted floor stay aligned.
	const TARGET := Vector2(640, 376)
	bg.position = Vector2.ZERO
	bg.scale = Vector2(TARGET.x / tex_size.x, TARGET.y / tex_size.y)

# ============================================================
# "NEW" DESIGN PASS (gated on GameState.use_new_assets)
# ============================================================
const PolishData = preload("res://scripts/polish_data.gd")

func _apply_new_polish() -> void:
	var room_id := String(get_scene_file_path().get_file().get_basename())
	var ops: Dictionary = PolishData.get_ops().get(room_id, {})
	if ops.is_empty():
		return
	# Make clashing placeholder scenery invisible — keep the Area2D so the
	# object is still hoverable/clickable as a hotspot over the painted art.
	for n in ops.get("hide", []):
		var node := _find_built_node(n)
		if node:
			var spr := node.get_node_or_null("Sprite")
			if spr:
				spr.visible = false
			if node is Clickable:
				node._bob_enabled = false
	# Reskin pickup items to their inventory icon so the scene item visibly
	# matches what lands in the inventory bar.
	for n in ops.get("reskin", {}).keys():
		_reskin_prop(node_path_name(n), ops["reskin"][n])
	# Reposition to remove overlaps / floating-over-water.
	for n in ops.get("move", {}).keys():
		_move_built_node(n, ops["move"][n])
	# Optional per-node scale tweaks.
	for n in ops.get("scale", {}).keys():
		var node := _find_built_node(n)
		if node:
			var spr := node.get_node_or_null("Sprite")
			if spr:
				spr.scale *= float(ops["scale"][n])

func node_path_name(n: String) -> String:
	return n

func _find_built_node(node_name: String) -> Node:
	for parent_name in ["Props", "Hotspots"]:
		var p := get_node_or_null(parent_name)
		if p and p.has_node(node_name):
			return p.get_node(node_name)
	if has_node(node_name):
		return get_node(node_name)
	return null

func _reskin_prop(node_name: String, icon_base: String, target_h: float = 34.0) -> void:
	var node := _find_built_node(node_name)
	if node == null:
		return
	var spr: Sprite2D = node.get_node_or_null("Sprite")
	if spr == null:
		return
	var tex := _load_texture("res://assets/inventory_icons/%s.png" % icon_base)
	if tex == null:
		return
	spr.texture = tex
	var h: float = tex.get_size().y
	if h > 0.0:
		var s := target_h / h
		spr.scale = Vector2(s, s)
	spr.visible = true

func _move_built_node(node_name: String, pos: Vector2) -> void:
	var node := _find_built_node(node_name)
	if node == null:
		return
	node.position = pos
	if node is Clickable:
		node._base_y = pos.y

# ============================================================
# CONTROL BAR (professional brass/wood styling, NEW version only)
# ============================================================
func _style_control_bar() -> void:
	if not GameState.use_new_assets:
		return
	var panel := get_node_or_null("UI/BottomPanel")
	if panel == null:
		return
	var tex := _load_texture("res://assets_new/ui/panel_bg.png")
	if tex == null:
		return
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.set_content_margin(SIDE_TOP, 11)
	sb.set_content_margin(SIDE_LEFT, 12)
	sb.set_content_margin(SIDE_RIGHT, 12)
	sb.set_content_margin(SIDE_BOTTOM, 8)
	panel.add_theme_stylebox_override("panel", sb)


func _build_room() -> void:
	pass

func _on_room_ready() -> void:
	pass

func _play_intro() -> void:
	pass

func _on_room_entered() -> void:
	pass

func _get_music_path() -> String:
	## Override to return ambient music path for this room
	return ""

func _load_sfx() -> void:
	_sfx_pickup = _create_sfx_player("res://assets/sfx/pickup.wav", -6.0)
	_sfx_door = _create_sfx_player("res://assets/sfx/door.wav", -4.0)
	_sfx_puzzle = _create_sfx_player("res://assets/sfx/puzzle_solve.wav", -4.0)
	_sfx_steam = _create_sfx_player("res://assets/sfx/steam_valve.wav", -6.0)
	_sfx_combine = _create_sfx_player("res://assets/sfx/item_combine.wav", -6.0)
	_sfx_vision = _create_sfx_player("res://assets/sfx/memory_vision.wav", -4.0)
	_sfx_ui_click = _create_sfx_player("res://assets/sfx/ui_click.wav", -8.0)
	_sfx_error = _create_sfx_player("res://assets/sfx/error_buzz.wav", -8.0)

	# Music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -12.0
	add_child(_music_player)

func _create_sfx_player(path: String, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "Master"
	player.volume_db = volume
	add_child(player)
	var stream := _load_audio(path)
	if stream:
		player.stream = stream
	return player

func _load_audio(res_path: String) -> AudioStream:
	if ResourceLoader.exists(res_path):
		return load(res_path)
	# Fallback: load from absolute path
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var stream := AudioStreamWAV.new()
		var file := FileAccess.open(abs_path, FileAccess.READ)
		if file:
			# Simple WAV loading — skip header, read PCM data
			file.seek(44)  # Skip WAV header
			stream.data = file.get_buffer(file.get_length() - 44)
			stream.format = AudioStreamWAV.FORMAT_16_BITS
			stream.mix_rate = 44100
			stream.stereo = false
			return stream
	return null

func play_sfx(sfx_player: AudioStreamPlayer) -> void:
	if sfx_player and sfx_player.stream:
		sfx_player.play()

func _start_music_deferred(music_path: String) -> void:
	await get_tree().create_timer(1.5).timeout
	play_music(music_path)

func play_music(music_path: String, volume_db: float = -12.0) -> void:
	if _current_music == music_path:
		return  # Already playing
	_current_music = music_path
	if _music_player:
		_music_player.stop()
		var stream := _load_audio(music_path)
		if stream:
			_music_player.stream = stream
			# Fade in from silence to avoid abrupt start
			_music_player.volume_db = -60.0
			_music_player.play()
			var tween := create_tween()
			tween.tween_property(_music_player, "volume_db", volume_db, 2.0)

func stop_music(fade_dur: float = 1.0) -> void:
	if _music_player and _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_dur)
		await tween.finished
		_music_player.stop()
		_current_music = ""

func _setup_player() -> void:
	if player:
		player.init_sprite()
		# Position player based on which room we came from
		var entry := _get_entry_position()
		if entry == Vector2.ZERO:
			entry = player.global_position
		# Drop the feet onto the room's floor line so the character is never floating.
		# On a fresh entry (no door we came through) use the room's default standing
		# column; when arriving through a specific door keep that door's column.
		var room_id := String(get_scene_file_path().get_file().get_basename())
		if ROOM_FLOOR.has(room_id):
			var f: Vector2 = ROOM_FLOOR[room_id]
			var fresh := String(GameState.previous_room) == ""
			var fx: float = f.x if fresh else entry.x
			entry = Vector2(fx, f.y - PLAYER_FEET_OFFSET)
		player.global_position = entry

func _get_entry_position() -> Vector2:
	## Override to return spawn position based on GameState.previous_room
	return Vector2.ZERO

func _connect_ui() -> void:
	# Find UI nodes (layout: BottomPanel/VBox/HoverText + BottomPanel/VBox/HBox/Verb+Inv)
	verb_panel = get_node_or_null("UI/BottomPanel/VBox/HBox/VerbPanel")
	if not verb_panel:
		verb_panel = get_node_or_null("UI/BottomPanel/HBox/VerbPanel")
	inventory = get_node_or_null("UI/BottomPanel/VBox/HBox/Inventory")
	if not inventory:
		inventory = get_node_or_null("UI/BottomPanel/HBox/Inventory")
	hover_text = get_node_or_null("UI/BottomPanel/VBox/HoverText")
	if not hover_text:
		hover_text = get_node_or_null("UI/HoverText")

	# Apply the steampunk command-bar background (brass molding + body).
	var bottom_panel := get_node_or_null("UI/BottomPanel")
	if bottom_panel is Control:
		var bar_tex := _load_texture("res://assets/ui/panel_bar.png")
		if bar_tex:
			var bar_style := StyleBoxTexture.new()
			bar_style.texture = bar_tex
			bar_style.set_texture_margin(SIDE_LEFT, 10)
			bar_style.set_texture_margin(SIDE_RIGHT, 10)
			bar_style.set_texture_margin(SIDE_TOP, 38)
			bar_style.set_texture_margin(SIDE_BOTTOM, 6)
			# Content margins must be set explicitly: a StyleBoxTexture
			# otherwise inherits the (38px) texture margins, which would push
			# the verb/inventory rows down and clip the bottom row off the bar.
			bar_style.set_content_margin(SIDE_LEFT, 10)
			bar_style.set_content_margin(SIDE_RIGHT, 10)
			bar_style.set_content_margin(SIDE_TOP, 4)
			bar_style.set_content_margin(SIDE_BOTTOM, 2)
			(bottom_panel as Control).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			bottom_panel.add_theme_stylebox_override("panel", bar_style)
	if hover_text:
		# Sentence-line amber (GODOT_INTEGRATION.md §2)
		hover_text.add_theme_color_override("font_color", Color("f3c873"))

	if verb_panel:
		verb_panel.verb_selected.connect(_on_verb_selected)
	if inventory:
		inventory.item_selected.connect(_on_inventory_item_selected)
		inventory.item_deselected.connect(_on_inventory_item_deselected)
		inventory.items_combined.connect(_on_items_combined)

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
		if mouse_pos.y > walkable_y_min and mouse_pos.y < walkable_y_max:
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
func _look_at(_obj: Clickable) -> void:
	await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(_obj: Clickable) -> void:
	await _say(_random_response(_TALK_RESPONSES))

func _pick_up(_obj: Clickable) -> void:
	await _say(_random_response(_PICK_UP_RESPONSES))

func _use(_obj: Clickable) -> void:
	await _say(_random_response(_USE_RESPONSES))

func _open(_obj: Clickable) -> void:
	await _say(_random_response(_OPEN_RESPONSES))

func _push(_obj: Clickable) -> void:
	await _say(_random_response(_PUSH_RESPONSES))

# Randomized generic response pools — Rowan's sarcastic defaults
const _LOOK_RESPONSES := [
	"Nothing remarkable about that.",
	"I've seen more interesting things at the bottom of a teacup.",
	"It exists. I can confirm that much.",
	"Unremarkable. Like Pindle's personality.",
	"My eyes say no.",
	"Exactly as boring as it looks.",
]

const _TALK_RESPONSES := [
	"Talking to that seems optimistic.",
	"It maintains a dignified silence.",
	"I tried. It left me on read.",
	"Even I have standards for conversation partners.",
	"If it could talk, I suspect it would ask me to stop.",
	"Surprisingly, no response. I'm devastated.",
]

const _PICK_UP_RESPONSES := [
	"I can't pick that up.",
	"My inventory has standards.",
	"That's attached to the concept of 'staying put.'",
	"Tibbit would name that impulse. Something like 'Acquisitive Folly Syndrome.'",
	"Heavy. Bolted. Uncooperative. My three least favorite adjectives.",
	"I could try, but my chiropractor would file a grievance.",
]

const _USE_RESPONSES := [
	"I don't know how to use that on its own.",
	"I stare at it purposefully. Nothing happens.",
	"If there's a way to use that, it's been classified above my pay grade.",
	"I could use it wrong, but where's the fun in that? Actually, everywhere.",
	"The instruction manual for that is in a language I don't speak.",
]

const _OPEN_RESPONSES := [
	"That doesn't open.",
	"Sealed by either physics or spite.",
	"Not everything opens. This is one of those things.",
	"I pull, I push, I bargain. Nothing.",
	"If Pindle had paperwork for opening that, I'd forge it.",
]

const _PUSH_RESPONSES := [
	"Pushing that accomplishes nothing except proving I tried.",
	"I push. It pushes back. We reach an impasse.",
	"Unmoved. Like a customs inspector at a bribe.",
	"I give it a shove. It gives me indifference.",
	"My pushing technique is flawless. The object simply refuses to cooperate.",
]

const _WRONG_ITEM_RESPONSES := [
	"I can't use that here.",
	"That combination makes about as much sense as Pindle's filing system.",
	"Interesting theory. Wrong, but interesting.",
	"I tried. The universe said no.",
	"Those two things have nothing to say to each other.",
]

const _WRONG_COMBINE_RESPONSES := [
	"I don't think combining those will help.",
	"Those don't go together. Like oil and Pindle's competence.",
	"I hold them near each other. They maintain a professional distance.",
	"Tibbit would call that 'creative engineering.' I call it nonsense.",
	"One plus one does not always equal useful.",
]

func _random_response(responses: Array) -> String:
	return responses[randi() % responses.size()]

func _use_item_on(item_name: String, target: Clickable) -> void:
	is_busy = true
	await player.walk_to_and_wait(target.get_walk_position())
	player.face_position(target.global_position)

	# Subclasses override _on_use_item for room-specific logic
	var handled := await _on_use_item(item_name, target)
	if not handled:
		await _say(_random_response(_WRONG_ITEM_RESPONSES))

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
		await _say(_random_response(_WRONG_COMBINE_RESPONSES))
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
	if _sfx_pickup and _sfx_pickup.stream:
		_sfx_pickup.play()

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
	# Position overhead text above Rowan
	if player:
		dialogue_box.show_dialogue_at("ROWAN", text, player.global_position)
		player._play_talk()
		# Stop talk animation when text finishes revealing (not when dismissed)
		if not dialogue_box.text_revealed.is_connected(_on_rowan_text_revealed):
			dialogue_box.text_revealed.connect(_on_rowan_text_revealed, CONNECT_ONE_SHOT)
	else:
		dialogue_box.show_dialogue("ROWAN", text)
	await dialogue_box.dialogue_finished
	# Ensure idle in case text_revealed didn't fire (e.g. skip)
	if player:
		player._play_idle()
	await get_tree().create_timer(0.1).timeout

func _on_rowan_text_revealed() -> void:
	if player:
		player._play_idle()

## Map speaker names to NPC node names for talk animations
var speaker_to_node: Dictionary = {}

func _say_as(speaker: String, text: String) -> void:
	if not dialogue_box:
		return

	# Find the speaker's position for overhead text
	var npc_sprite: AnimatedSprite2D = null
	if speaker == "ROWAN" and player:
		dialogue_box.show_dialogue_at(speaker, text, player.global_position)
		player._play_talk()
		# Stop talk when text finishes revealing
		if not dialogue_box.text_revealed.is_connected(_on_rowan_text_revealed):
			dialogue_box.text_revealed.connect(_on_rowan_text_revealed, CONNECT_ONE_SHOT)
	elif speaker in speaker_to_node:
		var node_name: String = speaker_to_node[speaker]
		var npc := get_node_or_null("Props/" + node_name)
		if npc:
			dialogue_box.show_dialogue_at(speaker, text, npc.global_position)
			npc_sprite = npc.get_node_or_null("AnimatedSprite2D")
			if npc_sprite:
				var current_anim: String = npc_sprite.animation
				var talk_anim := "talk_left" if "left" in current_anim else "talk_right"
				if npc_sprite.sprite_frames.has_animation(talk_anim):
					npc_sprite.play(talk_anim)
				# Stop talk when text finishes revealing
				var sprite_ref := npc_sprite
				dialogue_box.text_revealed.connect(
					func(): _stop_npc_talk(sprite_ref),
					CONNECT_ONE_SHOT
				)
		else:
			dialogue_box.show_dialogue(speaker, text)
	else:
		# Unknown speaker — show centered
		dialogue_box.show_dialogue_at(speaker, text, Vector2(320, 150))

	await dialogue_box.dialogue_finished

	# Ensure idle in case text_revealed didn't fire (e.g. skip)
	if speaker == "ROWAN" and player:
		player._play_idle()
	elif npc_sprite:
		_stop_npc_talk(npc_sprite)

	await get_tree().create_timer(0.1).timeout

func _stop_npc_talk(sprite: AnimatedSprite2D) -> void:
	if not is_instance_valid(sprite):
		return
	var current_anim: String = sprite.animation
	var idle_anim := "idle_left" if "left" in current_anim else "idle_right"
	if sprite.sprite_frames.has_animation(idle_anim):
		sprite.play(idle_anim)

# ============================================================
# DIALOGUE TREE RUNNER
# ============================================================

var _choice_result: String = ""

func run_dialogue_tree(tree: DialogueTree, start_id: String = "") -> void:
	if start_id == "":
		start_id = tree.start_id

	var current_id := start_id
	is_busy = true

	# Track which choices have been picked this conversation
	var picked_targets: Dictionary = {}
	# The "hub" node — the node with topic choices that we return to
	var hub_id: String = ""
	var returning_to_hub := false

	while current_id != "" and current_id in tree.nodes:
		var node: DialogueTree.DialogueNode = tree.nodes[current_id]

		# Check conditions
		if node.condition_flag != "" and not GameState.has_flag(node.condition_flag):
			break
		if node.condition_not_flag != "" and GameState.has_flag(node.condition_not_flag):
			break

		# On-enter effects (skip on hub return)
		if not returning_to_hub:
			if node.on_enter_flag != "":
				GameState.set_flag(node.on_enter_flag)
			if node.on_enter_item != "":
				give_item(node.on_enter_item)

			# Mark as seen
			GameState.mark_dialogue_seen(node.id)

			# Show the dialogue line
			await _say_as(node.speaker, node.text)

		returning_to_hub = false

		# Check for choices
		var choices := tree.get_available_choices(current_id)

		# Filter out already-picked topics
		var remaining: Array[DialogueTree.DialogueChoice] = []
		for c in choices:
			if c.target_id not in picked_targets:
				remaining.append(c)

		if remaining.size() > 0:
			# This is a hub node — remember it for returning
			if hub_id == "" or current_id == hub_id:
				hub_id = current_id

			# Add "That's all" exit option
			var exit_choice := DialogueTree.DialogueChoice.new()
			exit_choice.label = "That's all."
			exit_choice.target_id = "_exit"
			remaining.append(exit_choice)

			var chosen := await _show_choices(remaining)

			if chosen.target_id == "_exit":
				break  # Player chose to end conversation

			if chosen.set_flag != "":
				GameState.set_flag(chosen.set_flag)

			# Mark this topic as picked
			picked_targets[chosen.target_id] = true
			current_id = chosen.target_id

		elif node.next_id != "":
			current_id = node.next_id

		else:
			# Branch ended — return to hub if we have one with remaining topics
			if hub_id != "" and hub_id in tree.nodes:
				var hub_choices := tree.get_available_choices(hub_id)
				var hub_remaining: Array[DialogueTree.DialogueChoice] = []
				for c in hub_choices:
					if c.target_id not in picked_targets:
						hub_remaining.append(c)
				if hub_remaining.size() > 0:
					current_id = hub_id
					returning_to_hub = true
					continue
			# No hub or no remaining topics — conversation over
			break

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

	# Play door sound
	if _sfx_door and _sfx_door.stream:
		_sfx_door.play()

	# Save inventory to GameState and auto-save
	if inventory:
		GameState.inventory_items = inventory.items.duplicate()
	GameState.save_game()

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
	res_path = GameState.resolve_asset(res_path)
	if ResourceLoader.exists(res_path):
		return load(res_path)
	var abs_path := ProjectSettings.globalize_path(res_path)
	var img := Image.new()
	if img.load(abs_path) == OK:
		return ImageTexture.create_from_image(img)
	return null
