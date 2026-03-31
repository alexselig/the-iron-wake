extends AdventureRoom

## Hushlight Lighthouse Main Chamber — Act 1, Room 8
## Puzzle 6: Align the Lens (shutters → memory lens → mirrors → brass strip).
## Second memory vision + Act 1 ending cutscene.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var lens_pedestal: Area2D
var chart_table: Area2D
var wall_mural: Area2D
var beacon_controls: Area2D
var window_shutters: Area2D
var mural_ring: Area2D
var door_out: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act1_08_lighthouse_chamber.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	# Main lens pedestal — center of room
	SceneBuilder.build_prop(props, "LensPedestal", Vector2(320, 260),
		"the lens pedestal", "res://assets/props/lens_pedestal.png",
		Vector2(-25, 20), false, false, Vector2(50, 50))

	# Chart table — navigation charts
	SceneBuilder.build_prop(props, "ChartTable", Vector2(180, 270),
		"the chart table", "res://assets/props/chart_table.png",
		Vector2(20, 15), false, false, Vector2(50, 36))

	# Wall mural — island depiction
	SceneBuilder.build_prop(props, "WallMural", Vector2(320, 210),
		"the wall mural", "res://assets/props/wall_mural.png",
		Vector2(0, 50), false, false, Vector2(80, 50))

	# Beacon controls — rotating mirrors
	SceneBuilder.build_prop(props, "BeaconControls", Vector2(460, 250),
		"the beacon controls", "res://assets/props/beacon_controls.png",
		Vector2(-20, 25), false, false, Vector2(40, 40))

	# Window shutters
	SceneBuilder.build_prop(props, "WindowShutters", Vector2(520, 230),
		"the window shutters", "res://assets/props/window_shutters.png",
		Vector2(-20, 35), false, false, Vector2(36, 50))

	# Ancient mural ring — hidden detail
	SceneBuilder.build_hotspot(props, "MuralRing", Vector2(320, 220),
		"a circular pattern in the mural", Vector2(0, 45), Vector2(40, 40))

	# Door back to exterior
	SceneBuilder.build_hotspot(hotspots, "DoorOut", Vector2(80, 270),
		"the door outside", Vector2(30, 10), Vector2(40, 60))

func _get_music_path() -> String:
	return "res://assets/music/lighthouse_ambient.wav"

func _on_room_ready() -> void:
	room_name = "lighthouse_chamber"

	speaker_to_node = {}

	lens_pedestal = $Props/LensPedestal
	chart_table = $Props/ChartTable
	wall_mural = $Props/WallMural
	beacon_controls = $Props/BeaconControls
	window_shutters = $Props/WindowShutters
	mural_ring = $Props/MuralRing
	door_out = $Hotspots/DoorOut

	for node in [lens_pedestal, chart_table, wall_mural, beacon_controls,
				 window_shutters, mural_ring, door_out]:
		if node:
			connect_clickable(node)

func _get_entry_position() -> Vector2:
	return Vector2(100, 290)

func _play_intro() -> void:
	is_busy = true
	_in_scripted_sequence = true

	# Fade in
	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw.finished
		fade_overlay.visible = false

	await _say("Circular chamber. Broken mirrors, brass rails, tide charts, towering lens assembly.")
	await _say("Dust in slanting light. Abandoned by people, not by purpose.")
	await _say_as("MARROW", "The chamber remembers what the town forgot.")

	_in_scripted_sequence = false
	is_busy = false

# ============================================================
# VERB ACTIONS
# ============================================================

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"LensPedestal":
			if GameState.has_flag("lens_installed"):
				await _say("The Memory Lens sits in the pedestal, humming faintly. Ready to focus.")
			else:
				await _say("A brass pedestal with an empty circular mount. Something used to sit here.")
				await _say("The mount is sized for a lens. A very specific lens.")
		"ChartTable":
			await _say("These aren't sea lanes. They're instructions.")
			if not GameState.has_flag("read_charts"):
				await _say("Overlapping routes, all converging on a point beyond the mapped coast.")
				await _say("Someone was trying to triangulate something that didn't want to be found.")
				GameState.set_flag("read_charts")
		"WallMural":
			await _say("That island again. Either fate is calling or architecture had a mascot.")
			if not GameState.has_flag("examined_mural"):
				await _say("White terraces, silver-leaf trees, a crescent harbor. Beautiful. Impossible. Familiar.")
				GameState.set_flag("examined_mural")
		"BeaconControls":
			if GameState.has_flag("mirrors_aligned"):
				await _say("The mirrors are locked in position. Light channels through like memory.")
			else:
				await _say("A lighthouse mechanism for people who thought 'simple' was a moral failing.")
				await _say("Rotating mirrors, calibrated dials, alignment markers. The mirrors need to match the mural symbols.")
		"WindowShutters":
			if GameState.has_flag("shutters_open"):
				await _say("Sunset light pours through the windows. The chamber glows amber.")
			else:
				await _say("Heavy brass shutters. Closed tight. No light gets in.")
				await _say("If this mechanism needs light, these need to be open first.")
		"MuralRing":
			await _say("A circular pattern embedded in the mural. Symbols around the rim match the brass strip.")
			if GameState.has_flag("lens_aligned"):
				await _say("The hidden route glows beneath the mural paint. The Wake Road.")
		"DoorOut":
			await _say("The door back to the exterior. Wind howls through the gap.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"LensPedestal":
			await _say("The pedestal hums when I get close. Either it's alive or I am losing my mind.")
		_:
			await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"ChartTable":
			await _say("The charts are pinned down. And probably more useful here than in my pocket.")
		_:
			await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"WindowShutters":
			if not GameState.has_flag("shutters_open"):
				await _say("I wrench the shutters open. Sunset light floods the chamber.")
				await _say("Dust motes drift like golden snow. The room wakes up.")
				GameState.set_flag("shutters_open")
			else:
				await _say("Already open. The light is pouring in.")
		"BeaconControls":
			if not GameState.has_flag("shutters_open"):
				await _say("I rotate the mirrors. They reflect nothing. I need light first.")
			elif not GameState.has_flag("lens_installed"):
				await _say("Light hits the mirrors but scatters uselessly. The central lens is missing.")
			elif GameState.has_flag("mirrors_aligned"):
				await _say("The mirrors are already aligned. The circuit is complete.")
			else:
				await _say("I adjust the mirrors. Light bounces between them, searching for focus.")
				await _say("Almost... the symbols on the mural ring need to match.")
				await _say("I rotate until the light locks into the mural pattern.")
				GameState.set_flag("mirrors_aligned")
				await _say("The beam converges on the mural. But it needs one more thing to complete the circuit.")
		"LensPedestal":
			if GameState.has_flag("lens_installed"):
				await _say("The lens is already in place.")
			else:
				await _say("An empty mount. I need the right lens.")
		"DoorOut":
			go_to_room("res://scenes/rooms/lighthouse_exterior.tscn")
		_:
			await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"WindowShutters":
			await _use(obj)
		"DoorOut":
			go_to_room("res://scenes/rooms/lighthouse_exterior.tscn")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	match obj.name:
		"BeaconControls":
			await _say("Pushing the controls is not the same as calibrating them. Though equally satisfying.")
		"LensPedestal":
			await _say("The pedestal is bolted to the floor. Whoever built this expected impatience.")
		_:
			await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"LensPedestal":
			if item_name == "memory_lens":
				await _say("I place the Memory Lens into the pedestal mount. It clicks into place.")
				await _say("The lens hums. Light refracts through it, casting strange patterns on the walls.")
				take_item("memory_lens")
				GameState.set_flag("lens_installed")
				return true
		"BeaconControls":
			if item_name == "brass_strip":
				if GameState.has_flag("mirrors_aligned"):
					await _say("I slide the brass strip into the selector slot on the beacon controls.")
					await _say("The symbols align. The beam sharpens. The mural begins to glow.")
					take_item("brass_strip")
					GameState.set_flag("lens_aligned")
					await _trigger_memory_vision()
					return true
				else:
					await _say("The controls accept the strip, but the mirrors aren't aligned yet. Nothing happens.")
					return true
		"WallMural":
			if item_name == "brass_strip":
				await _say("The strip's symbols match the mural, but the mechanism needs it in the beacon controls.")
				return true
	return false

# ============================================================
# WRONG ALIGNMENT COMEDY
# ============================================================

func _wrong_alignment_joke() -> void:
	var jokes := [
		["We have discovered... a herring.", "Do not sound pleased."],
		["Wonderful. A haunted portrait by someone who dislikes me.", ""],
		["That's either a map of nothing or modern art.", "Same thing."],
	]
	var joke: Array = jokes[randi() % jokes.size()]
	await _say(joke[0])
	if joke[1] != "":
		await _say_as("TIBBIT", joke[1])

# ============================================================
# MEMORY VISION — Act 1 Climax
# ============================================================

func _trigger_memory_vision() -> void:
	is_busy = true
	_in_scripted_sequence = true

	await get_tree().create_timer(0.5).timeout
	await _say("The chamber darkens. A hidden route pattern glows beneath the mural paint.")
	await _say_as("MARROW", "The Wake Road.")

	await _say("I reach for the glowing route—")

	# Switch to vision music
	play_sfx(_sfx_vision)
	play_music("res://assets/music/memory_vision_music.wav", -8.0)

	# Fade to vision
	if fade_overlay:
		fade_overlay.visible = true
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 1.0, 0.6)
		await tw.finished

	await get_tree().create_timer(0.5).timeout

	# Vision sequence
	if fade_overlay:
		fade_overlay.color = Color(1, 1, 1, 1)  # White flash
		var tw2 := create_tween()
		tw2.tween_property(fade_overlay, "color:a", 0.7, 0.3)
		await tw2.finished

	# Memory dialogue
	await _say_as("NARRATOR", "Warm sunlight. White terraces. Silver-leaf trees. A courtyard.")
	await _say_as("MAN", "Listen carefully. If they close the gates, you follow the road of lights.")
	await _say_as("MAN", "You do not wait for us.")
	await _say_as("WOMAN", "The sea will hide you. The sea will bring you back.")
	await _say_as("NARRATOR", "Alarm bells. Metal doors sealing. A glowing island beyond fog.")
	await _say_as("NARRATOR", "Darkness.")

	# Return from vision
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)
		var tw3 := create_tween()
		tw3.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw3.finished
		fade_overlay.visible = false

	await get_tree().create_timer(0.3).timeout

	# Post-vision dialogue
	await _say("I remember them. I was there. That island is real.")
	await _say_as("MARROW", "Some truths must be arrived at, not handed over.")
	await _say("I may throw you into the sea on principle.")
	await _say_as("MARROW", "Get in line.")

	# Give rewards
	give_item("relay_key")
	give_item("map_plate")
	GameState.set_flag("act1_vision_complete")

	await _say("Two objects fall from a hidden compartment: a brass key and a map plate.")
	await _say("Good. The lighthouse is giving me homework now too.")

	await get_tree().create_timer(0.5).timeout

	# Act 1 ending sequence
	await _trigger_act1_ending()

func _trigger_act1_ending() -> void:
	# Pounding at the door
	await _say("Pounding at the lighthouse door.")

	await _say_as("ROOK", "Miss Vale! I do dislike closed doors. It suggests someone is learning without permission.")
	await _say_as("TIBBIT", "That's him. I know villain footsteps.")

	await get_tree().create_timer(0.3).timeout

	# Marrow points to escape
	await _say_as("MARROW", "Go inland. Find the towers. Wake the road before Rook does.")
	await _say_as("ROOK", "Open this tower, or I shall buy it and open it with receipts!")

	await get_tree().create_timer(0.3).timeout

	await _say("All right. We find the towers. We find the road. We find the island.")
	await _say_as("TIBBIT", "And possibly lunch?")
	await _say("If fate permits.")
	await _say_as("TIBBIT", "It had better. I am not solving destiny on an empty stomach.")

	GameState.set_flag("act1_complete")

	# Fade out — they flee down the rear stairs
	if fade_overlay:
		fade_overlay.visible = true
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 1.0, 1.0)
		await tw.finished

	await get_tree().create_timer(0.5).timeout

	# Epilogue narration
	await _say_as("NARRATOR", "They flee down the rear stairs. The lighthouse beam sputters once, sends a white line across the sea.")
	await _say_as("NARRATOR", "Far beyond the fog, a matching light answers.")

	await get_tree().create_timer(1.0).timeout

	await _say_as("NARRATOR", "END OF ACT 1")

	await get_tree().create_timer(2.0).timeout

	# Return to title screen
	_in_scripted_sequence = false
	is_busy = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
