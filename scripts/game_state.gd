extends Node

## Global game state singleton — persists across room transitions

# Current room tracking
var current_room: String = ""
var previous_room: String = ""
var visited_rooms: Dictionary = {}

# Inventory — the authoritative item list (inventory UI reads from this)
var inventory_items: Array[String] = []

# Puzzle flags — generic dictionary for any room/puzzle state
var flags: Dictionary = {}

# Track what's been picked up (legacy compat + flag-based)
var items_collected: Dictionary = {}

# Track first-time examinations
var first_examine: Dictionary = {}

# Dialogue history — tracks which dialogue nodes have been seen
var dialogue_seen: Dictionary = {}

# Room entry points — where the player should spawn when entering from a specific room
var room_entry_points: Dictionary = {}

# ============================================================
# VERSION TOGGLE — "original" vs "new" (design pass)
# ============================================================
# When use_new_assets is true, any texture path under res://assets/ is
# transparently redirected to res://assets_new/ when a replacement exists.
# This lets the whole game flip between the shipped ("original") art/layout
# and the polished ("new") pass with a single key (F1), with zero changes to
# call sites beyond routing every _load_texture() through resolve_asset().
var use_new_assets: bool = true
const VERSION_PREF_PATH := "user://version_pref.cfg"
var _version_label: Label = null
var _new_asset_cache: Dictionary = {}

func _ready() -> void:
	_load_version_pref()
	_setup_version_indicator.call_deferred()

func resolve_asset(res_path: String) -> String:
	## Redirect an asset path to its "new" variant when the new version is
	## active and a replacement file exists. Falls back to the original path.
	if not use_new_assets:
		return res_path
	if not res_path.begins_with("res://assets/"):
		return res_path
	if _new_asset_cache.has(res_path):
		return _new_asset_cache[res_path]
	var candidate := res_path.replace("res://assets/", "res://assets_new/")
	var resolved := candidate if _asset_exists(candidate) else res_path
	_new_asset_cache[res_path] = resolved
	return resolved

func _asset_exists(res_path: String) -> bool:
	if ResourceLoader.exists(res_path):
		return true
	return FileAccess.file_exists(ProjectSettings.globalize_path(res_path))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		toggle_version()

func toggle_version() -> void:
	use_new_assets = not use_new_assets
	_new_asset_cache.clear()
	_save_version_pref()
	_update_version_label()
	var tree := get_tree()
	if tree and tree.current_scene:
		tree.reload_current_scene()

func _load_version_pref() -> void:
	if not FileAccess.file_exists(VERSION_PREF_PATH):
		return
	var file := FileAccess.open(VERSION_PREF_PATH, FileAccess.READ)
	if file:
		use_new_assets = file.get_as_text().strip_edges() != "original"
		file.close()

func _save_version_pref() -> void:
	var file := FileAccess.open(VERSION_PREF_PATH, FileAccess.WRITE)
	if file:
		file.store_string("new" if use_new_assets else "original")
		file.close()

func _setup_version_indicator() -> void:
	var layer := CanvasLayer.new()
	layer.name = "VersionIndicator"
	layer.layer = 128
	add_child(layer)
	var lbl := Label.new()
	lbl.name = "VersionLabel"
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl.offset_left = 6
	lbl.offset_top = 4
	lbl.offset_right = -6
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", 4)
	layer.add_child(lbl)
	_version_label = lbl
	_update_version_label()

func _update_version_label() -> void:
	if not is_instance_valid(_version_label):
		return
	if use_new_assets:
		_version_label.text = "NEW  ·  F1"
		_version_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55))
	else:
		_version_label.text = "ORIGINAL  ·  F1"
		_version_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))

# ============================================================
# FLAGS
# ============================================================

func set_flag(flag_name: String, value: Variant = true) -> void:
	flags[flag_name] = value

func get_flag(flag_name: String, default: Variant = false) -> Variant:
	return flags.get(flag_name, default)

func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false) == true

# ============================================================
# INVENTORY
# ============================================================

func add_item(item_name: String) -> void:
	if item_name not in inventory_items:
		inventory_items.append(item_name)
	items_collected[item_name] = true

func remove_item(item_name: String) -> void:
	inventory_items.erase(item_name)
	# Don't reset items_collected — it tracks "ever collected" history

func has_item(item_name: String) -> bool:
	return item_name in inventory_items

func get_items() -> Array[String]:
	return inventory_items

# Legacy compat
func collect_item(item_name: String) -> void:
	add_item(item_name)

# ============================================================
# EXAMINATIONS
# ============================================================

func has_examined(thing: String) -> bool:
	return first_examine.get(thing, false)

func mark_examined(thing: String) -> void:
	first_examine[thing] = true

# ============================================================
# ROOMS
# ============================================================

func enter_room(room_name: String) -> void:
	previous_room = current_room
	current_room = room_name
	visited_rooms[room_name] = true

func has_visited(room_name: String) -> bool:
	return visited_rooms.get(room_name, false)

# ============================================================
# DIALOGUE
# ============================================================

func mark_dialogue_seen(dialogue_id: String) -> void:
	dialogue_seen[dialogue_id] = true

func has_seen_dialogue(dialogue_id: String) -> bool:
	return dialogue_seen.get(dialogue_id, false)

# ============================================================
# SAVE / LOAD
# ============================================================

func save_game() -> void:
	var data := {
		"current_room": current_room,
		"previous_room": previous_room,
		"visited_rooms": visited_rooms,
		"inventory_items": inventory_items,
		"flags": flags,
		"items_collected": items_collected,
		"first_examine": first_examine,
		"dialogue_seen": dialogue_seen,
	}
	var file := FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> bool:
	if not FileAccess.file_exists("user://savegame.dat"):
		return false
	var file := FileAccess.open("user://savegame.dat", FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return false
	var data: Dictionary = json.data
	current_room = data.get("current_room", "")
	previous_room = data.get("previous_room", "")
	visited_rooms = data.get("visited_rooms", {})
	var loaded_items = data.get("inventory_items", [])
	inventory_items.clear()
	for item in loaded_items:
		inventory_items.append(item)
	flags = data.get("flags", {})
	items_collected = data.get("items_collected", {})
	first_examine = data.get("first_examine", {})
	dialogue_seen = data.get("dialogue_seen", {})
	return true

func reset() -> void:
	current_room = ""
	previous_room = ""
	visited_rooms.clear()
	inventory_items.clear()
	flags.clear()
	items_collected.clear()
	first_examine.clear()
	dialogue_seen.clear()
