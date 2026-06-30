extends Node

## Screenshot harness for design review.
## Loads each room, skips its intro, grounds the player, waits for fade-in,
## then captures the 640x480 viewport to shots/<mode>/<name>.png.
##
## Run windowed (NOT headless — GL compatibility needs a real swapchain):
##   Godot --path . res://_shot.tscn -- both     (default: orig + new)
##   Godot --path . res://_shot.tscn -- new
##   Godot --path . res://_shot.tscn -- orig

const ROOMS := [
	["res://scenes/main.tscn", "01_blackwake_harbor"],
	["res://scenes/rooms/customs_shack.tscn", "02_customs_shack"],
	["res://scenes/rooms/salvage_warehouse.tscn", "03_salvage_warehouse"],
	["res://scenes/rooms/brass_bazaar.tscn", "04_brass_bazaar"],
	["res://scenes/rooms/tibbit_workshop.tscn", "05_tibbit_workshop"],
	["res://scenes/rooms/harbor_cliffs.tscn", "06_harbor_cliffs"],
	["res://scenes/rooms/lighthouse_exterior.tscn", "07_lighthouse_exterior"],
	["res://scenes/rooms/lighthouse_chamber.tscn", "08_lighthouse_chamber"],
	["res://scenes/rooms/smuggler_path.tscn", "09_smuggler_path"],
	["res://scenes/rooms/brackmarsh.tscn", "10_brackmarsh"],
	["res://scenes/rooms/relay_tower.tscn", "11_relay_tower"],
	["res://scenes/rooms/sunken_waystation.tscn", "12_sunken_waystation"],
	["res://scenes/rooms/ironwind_airdock.tscn", "13_ironwind_airdock"],
	["res://scenes/rooms/fogwound_ruins.tscn", "14_fogwound_ruins"],
	["res://scenes/rooms/transit_vault.tscn", "15_transit_vault"],
	["res://scenes/rooms/cinderglass_valley.tscn", "16_cinderglass_valley"],
	["res://scenes/rooms/mountain_breach.tscn", "17_mountain_breach"],
	["res://scenes/rooms/undersea_transit.tscn", "18_undersea_transit"],
	["res://scenes/rooms/wake_passage.tscn", "19_wake_passage"],
	["res://scenes/rooms/isle_auric.tscn", "20_isle_auric"],
	["res://scenes/rooms/harmonic_gate.tscn", "21_harmonic_gate"],
]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := "both"
	if args.size() > 0:
		mode = args[0]
	var modes := []
	if mode == "new":
		modes = ["new"]
	elif mode == "orig":
		modes = ["orig"]
	else:
		modes = ["orig", "new"]

	# Hide the on-screen version indicator so it never covers room art.
	var indicator := GameState.get_node_or_null("VersionIndicator")
	if indicator:
		indicator.visible = false

	for m in modes:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/%s" % m))
		for room in ROOMS:
			await _capture_room(room[0], room[1], m)
	print("SHOT_HARNESS_DONE")
	get_tree().quit()

func _capture_room(scene_path: String, out_name: String, mode: String) -> void:
	GameState.reset()
	GameState.visited_rooms[""] = true   # skip the first-visit intro
	GameState.previous_room = ""          # fresh entry -> ground player on floor
	GameState.use_new_assets = (mode == "new")
	GameState._new_asset_cache.clear()

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_warning("Could not load %s" % scene_path)
		return
	var room := packed.instantiate()
	add_child(room)

	# Wait for build + the 0.8s revisit fade-in to finish.
	await get_tree().process_frame
	await get_tree().create_timer(1.7).timeout

	var img := get_viewport().get_texture().get_image()
	var out_path := "res://shots/%s/%s.png" % [mode, out_name]
	img.save_png(ProjectSettings.globalize_path(out_path))
	print("  saved %s/%s" % [mode, out_name])

	room.queue_free()
	await get_tree().process_frame
