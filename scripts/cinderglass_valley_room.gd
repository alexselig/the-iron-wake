extends AdventureRoom

## Cinderglass Valley — Act 3, Room 16
## Volcanic valley. Puzzle 1: Cross the Steam Terrace.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var vent_wheels: Area2D
var glass_outcrop: Area2D
var heat_shutters: Area2D
var transit_plinth: Area2D
var cable_tram: Area2D
var warning_bells: Area2D
var path_back: Area2D
var path_forward: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act3_01_cinderglass_valley.png")
	if tex: bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	SceneBuilder.build_prop(props, "VentWheels", Vector2(250, 260),
		"vent control wheels", "res://assets/props/beacon_crank.png",
		Vector2(15, 15), false, false, Vector2(36, 36))
	SceneBuilder.build_prop(props, "GlassOutcrop", Vector2(420, 250),
		"a cinderglass formation", "res://assets/props/black_shard.png",
		Vector2(-15, 20), false, false, Vector2(32, 40))
	SceneBuilder.build_hotspot(props, "HeatShutters", Vector2(350, 240),
		"heat shutters", Vector2(0, 25), Vector2(40, 24))
	SceneBuilder.build_prop(props, "TransitPlinth", Vector2(500, 265),
		"an ancient transit plinth", "res://assets/props/boundary_stone.png",
		Vector2(-15, 10), false, false, Vector2(36, 44))
	SceneBuilder.build_hotspot(props, "CableTram", Vector2(150, 230),
		"a broken cable tram", Vector2(20, 35), Vector2(50, 30))
	SceneBuilder.build_hotspot(props, "WarningBells", Vector2(300, 220),
		"warning bells", Vector2(0, 45), Vector2(30, 20))
	SceneBuilder.build_hotspot(hotspots, "PathBack", Vector2(60, 275),
		"the landing site", Vector2(30, 5), Vector2(40, 60))
	var fwd = SceneBuilder.build_hotspot(hotspots, "PathForward", Vector2(580, 260),
		"the mountain path", Vector2(-30, 15), Vector2(40, 60))
	if not GameState.has_flag("terrace_crossed"): fwd.hide_object()

func _on_room_ready() -> void:
	room_name = "cinderglass_valley"
	vent_wheels = $Props/VentWheels; glass_outcrop = $Props/GlassOutcrop
	heat_shutters = $Props/HeatShutters; transit_plinth = $Props/TransitPlinth
	cable_tram = $Props/CableTram; warning_bells = $Props/WarningBells
	path_back = $Hotspots/PathBack; path_forward = $Hotspots/PathForward
	for node in [vent_wheels, glass_outcrop, heat_shutters, transit_plinth,
				 cable_tram, warning_bells, path_back, path_forward]:
		if node: connect_clickable(node)

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"mountain_breach": return Vector2(550, 285)
		_: return Vector2(100, 290)

func _play_intro() -> void:
	is_busy = true; _in_scripted_sequence = true
	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw.finished; fade_overlay.visible = false
	if not GameState.has_flag("act3_intro"):
		await _say_as("TIBBIT", "We are, in technical terms, astonishingly close to something enormous.")
		await _say_as("BRAM", "In pilot terms, that usually precedes a regrettable noise.")
		await _say("Let's try to keep the regrettable noises to a minimum.")
		await _say_as("BRAM", "I'll anchor here. If anyone asks, I was never involved in destiny. I prefer my crimes terrestrial.")
		GameState.set_flag("act3_intro")
	else:
		await _say("Cinderglass Valley. Steam, glass, and ancient bones of architecture.")
	_in_scripted_sequence = false; is_busy = false

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"VentWheels": await _say("One more industrial wheel in a world that keeps insisting circles are management.")
		"GlassOutcrop": await _say("A rock that appears to have lost an argument with lightning.")
		"HeatShutters":
			if GameState.has_flag("shutter_propped"): await _say("The shutter is propped open. Steam diverted.")
			else: await _say("Heavy metal shutters over steam vents. One is half-stuck.")
		"TransitPlinth":
			await _say("An ancient plinth with the island crest — whole, not split.")
			if not GameState.has_flag("seen_whole_crest"):
				await _say("The split happened later.")
				await _say_as("TIBBIT", "So originally, one city. One government. One inevitable future argument.")
				GameState.set_flag("seen_whole_crest")
		"CableTram": await _say("Public transit's more dramatic cousin.")
		"WarningBells": await _say("Bells for when the steam gets ambitious. Currently silent.")
		"PathBack": await _say("Back to where Bram anchored the Gull.")
		"PathForward": await _say("The mountain path. Beyond the steam.")
		_: await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"GlassOutcrop":
			if not GameState.has_item("reflective_cinderglass"):
				await _say("I snap off a flat piece. Reflective as a mirror. Could be useful.")
				give_item("reflective_cinderglass")
			else: await _say("I have a piece already.")
		_: await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"PathBack": go_to_room("res://scenes/rooms/transit_vault.tscn")
		"PathForward":
			if GameState.has_flag("terrace_crossed"): go_to_room("res://scenes/rooms/mountain_breach.tscn")
			else: await _say("Steam blocks the path. I need to clear a safe window.")
		"VentWheels":
			if not GameState.has_flag("vents_redirected"):
				await _say("I turn the wheel. One vent bank closes, another opens. The steam pattern shifts.")
				GameState.set_flag("vents_redirected")
			else: await _say("Already redirected.")
		"HeatShutters":
			if GameState.has_flag("shutter_propped"):
				await _say("Already propped open.")
			elif not GameState.has_flag("vents_redirected"):
				await _say("The shutter is jammed by pressure. I need to redirect the vents first.")
			else: await _say("The shutter is half-stuck. I need something to prop it open.")
		"WarningBells":
			if GameState.has_flag("terrace_crossed"): await _say("The bells are quiet now. The terrace is safe.")
			else: await _say("I ring a bell. Steam responds by hissing louder. Helpful.")
		_: await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"PathForward":
			if GameState.has_flag("terrace_crossed"): go_to_room("res://scenes/rooms/mountain_breach.tscn")
			else: await _say("That path is currently in a committed relationship with boiling air.")
		_: await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"HeatShutters":
			if item_name == "coil_clamp" or item_name == "broken_gear":
				if GameState.has_flag("vents_redirected"):
					await _say("I prop the shutter open with the clamp. Steam diverts cleanly.")
					GameState.set_flag("shutter_propped")
					return true
				else:
					await _say("Too much pressure. Redirect the vents first.")
					return true
		"WarningBells", "VentWheels":
			if item_name == "reflective_cinderglass":
				if GameState.has_flag("shutter_propped"):
					await _say("I angle the cinderglass to spot the safe rhythm through the distortion.")
					await _say("There — a three-second window when the terrace is clear. I cross.")
					GameState.set_flag("terrace_crossed")
					if path_forward: path_forward.show_object()
					return true
				else:
					await _say("The steam is still too chaotic. I need to control the flow first.")
					return true
	return false
