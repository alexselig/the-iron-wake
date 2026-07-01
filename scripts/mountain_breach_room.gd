extends AdventureRoom

## The Mountain Breach — Act 3, Room 17
## Puzzle 2: Open Maintenance Hatch (sound/resonance puzzle).

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var sealed_aperture: Area2D
var auxiliary_panel: Area2D
var scaffold_pipe: Area2D
var survey_equipment: Area2D
var resonator_pipes: Area2D
var maintenance_hatch: Area2D
var path_back: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act3_02_mountain_breach.png")
	if tex: bg.texture = tex

func _build_room() -> void:
	var props := $Props; var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)
	SceneBuilder.build_hotspot(props, "SealedAperture", Vector2(320, 220),
		"the sealed aperture", Vector2(0, 45), Vector2(80, 50))
	SceneBuilder.build_hotspot(props, "AuxiliaryPanel", Vector2(400, 255),
		"an auxiliary panel", Vector2(-15, 15), Vector2(36, 28))
	SceneBuilder.build_prop(props, "ScaffoldPipe", Vector2(200, 270),
		"a scaffold pipe", "res://assets/props/scaffold_pipe.png",
		Vector2(15, 10), true, false, Vector2(40, 20))
	SceneBuilder.build_hotspot(props, "SurveyEquipment", Vector2(480, 260),
		"Rook's survey equipment", Vector2(-20, 15), Vector2(40, 30))
	SceneBuilder.build_hotspot(props, "ResonatorPipes", Vector2(300, 235),
		"resonator pipes", Vector2(10, 30), Vector2(40, 24))
	var hatch = SceneBuilder.build_hotspot(hotspots, "MaintenanceHatch", Vector2(350, 270),
		"the maintenance hatch", Vector2(-10, 5), Vector2(40, 40))
	if not GameState.has_flag("hatch_open"): hatch.hide_object()
	SceneBuilder.build_hotspot(hotspots, "PathBack", Vector2(60, 275),
		"the valley path", Vector2(30, 5), Vector2(40, 60))

func _on_room_ready() -> void:
	room_name = "mountain_breach"
	sealed_aperture = $Props/SealedAperture; auxiliary_panel = $Props/AuxiliaryPanel
	scaffold_pipe = $Props/ScaffoldPipe; survey_equipment = $Props/SurveyEquipment
	resonator_pipes = $Props/ResonatorPipes
	maintenance_hatch = $Hotspots/MaintenanceHatch; path_back = $Hotspots/PathBack
	for node in [sealed_aperture, auxiliary_panel, scaffold_pipe, survey_equipment,
				 resonator_pipes, maintenance_hatch, path_back]:
		if node: connect_clickable(node)
	if GameState.has_item("scaffold_pipe") and scaffold_pipe: scaffold_pipe.hide_object()

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"undersea_transit": return Vector2(330, 285)
		_: return Vector2(100, 290)

func _play_intro() -> void:
	is_busy = true; _in_scripted_sequence = true
	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw.finished; fade_overlay.visible = false
	await _say("A vast break in the mountainside. Rook's scaffolding clings to ancient stone.")
	await _say_as("TIBBIT", "He's been here. Recently.")
	await _say("Can you tell from the tools?")
	await _say_as("TIBBIT", "No. From the perfume of money and violation.")
	_in_scripted_sequence = false; is_busy = false

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"SealedAperture": await _say("A door the size of a philosophy. Won't open without full relay authorization.")
		"AuxiliaryPanel":
			if GameState.has_flag("cylinder_in_panel"): await _say("The panel plays a broken pattern. Needs the right resonance to complete it.")
			else: await _say("A smaller auxiliary panel. Has a slot that fits something cylindrical.")
		"ScaffoldPipe": await _say("A hollow metal pipe from the scaffolding. Could produce a deep resonance.")
		"SurveyEquipment": await _say("Precision instruments in the hands of deeply imprecise motives.")
		"ResonatorPipes": await _say("Either ventilation or a machine with opinions about music.")
		"MaintenanceHatch": await _say("The service hatch is open. Tight fit but passable.")
		"PathBack": await _say("Back to the valley.")
		_: await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"ScaffoldPipe":
			if not GameState.has_item("scaffold_pipe"):
				await _say("I wrench the pipe free. Hollow — good resonance.")
				give_item("scaffold_pipe"); obj.hide_object()
			else: await _say("Already have one.")
		_: await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"PathBack": go_to_room("res://scenes/rooms/cinderglass_valley.tscn")
		"MaintenanceHatch":
			if GameState.has_flag("hatch_open"): go_to_room("res://scenes/rooms/undersea_transit.tscn")
			else: await _say("The hatch is sealed. I need to trigger the maintenance resonance.")
		"AuxiliaryPanel":
			if GameState.has_flag("cylinder_in_panel") and GameState.has_flag("low_note") and GameState.has_flag("high_note") and GameState.has_flag("prism_aligned"):
				await _say("I trigger the full sequence. The resonance builds. The hatch shudders and opens.")
				await _say_as("TIBBIT", "I love these machines.")
				await _say("They've tried to electrocute me three times.")
				await _say_as("TIBBIT", "Yes, but artistically.")
				GameState.set_flag("hatch_open")
				if maintenance_hatch: maintenance_hatch.show_object()
			else: await _say("The sequence is incomplete. I need the right resonance pattern.")
		"ResonatorPipes":
			if GameState.has_flag("cylinder_in_panel"):
				if GameState.has_item("scaffold_pipe") and not GameState.has_flag("low_note"):
					await _say("I blow through the scaffold pipe at the resonator. A deep note fills the chamber.")
					GameState.set_flag("low_note")
				elif GameState.has_item("whistle") and not GameState.has_flag("high_note"):
					await _say("I play Tibbit's whistle. A high note pierces the air.")
					GameState.set_flag("high_note")
				elif not GameState.has_flag("low_note"):
					await _say("I need something to produce a low note. Something hollow and large.")
				elif not GameState.has_flag("high_note"):
					await _say("Low note done. Now I need something for the high note.")
				else: await _say("Both notes done. Now the light needs to match the beat.")
			else: await _say("The resonator pipes are dormant. The auxiliary panel needs input first.")
		_: await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"MaintenanceHatch":
			if GameState.has_flag("hatch_open"): go_to_room("res://scenes/rooms/undersea_transit.tscn")
			else: await _say("Sealed by resonance lock.")
		"PathBack": go_to_room("res://scenes/rooms/cinderglass_valley.tscn")
		_: await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"AuxiliaryPanel":
			if item_name == "tone_cylinder":
				await _say("I insert the Tone Cylinder. A broken playback pattern fills the chamber.")
				GameState.set_flag("cylinder_in_panel"); return true
		"ResonatorPipes":
			if item_name == "scaffold_pipe" and not GameState.has_flag("low_note"):
				await _say("I use the scaffold pipe as a low-note resonator. The chamber vibrates.")
				GameState.set_flag("low_note"); return true
			if item_name == "whistle" and not GameState.has_flag("high_note"):
				await _say("The whistle produces a perfect high note.")
				if not GameState.has_flag("low_note"):
					await _say("We have not opened the hatch, but we may have impressed a particularly judgmental bird.")
				else:
					GameState.set_flag("high_note")
				return true
			if item_name == "aerial_transit_prism":
				if GameState.has_flag("low_note") and GameState.has_flag("high_note"):
					await _say("I align the prism so the pulsing light matches the resonance beat.")
					GameState.set_flag("prism_aligned"); return true
				else: await _say("I need both notes first."); return true
	return false
