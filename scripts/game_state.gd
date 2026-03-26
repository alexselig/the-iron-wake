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
