extends AdventureRoom

## Central Harmonic Gate — Act 3, Room 21 (FINALE)
## Puzzles 6-7: Rebuild Civic Harmony + Defeat Rook.
## 3 ending variants. Post-credits scene.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var bloodline_socket: Area2D
var warden_station: Area2D
var council_station: Area2D
var resonance_rings: Area2D
var gate_nexus: Area2D
var archive_terminal: Area2D
var civic_console: Area2D
var choke_lever: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act3_07_harmonic_gate.png")
	if tex: bg.texture = tex

func _build_room() -> void:
	var props := $Props
	SceneBuilder.build_player_sprite($Player)
	SceneBuilder.build_hotspot(props, "BloodlineSocket", Vector2(320, 265),
		"the bloodline socket", Vector2(0, 10), Vector2(30, 24))
	SceneBuilder.build_hotspot(props, "WardenStation", Vector2(200, 255),
		"Seraphine's station", Vector2(20, 15), Vector2(36, 30))
	SceneBuilder.build_hotspot(props, "CouncilStation", Vector2(440, 255),
		"Ilyan's station", Vector2(-20, 15), Vector2(36, 30))
	SceneBuilder.build_hotspot(props, "ResonanceRings", Vector2(320, 220),
		"the resonance rings", Vector2(0, 40), Vector2(80, 40))
	SceneBuilder.build_hotspot(props, "GateNexus", Vector2(320, 200),
		"the gate nexus", Vector2(0, 55), Vector2(60, 30))
	SceneBuilder.build_hotspot(props, "ArchiveTerminal", Vector2(460, 265),
		"Sel's archive terminal", Vector2(-15, 10), Vector2(30, 24))
	SceneBuilder.build_hotspot(props, "CivicConsole", Vector2(250, 270),
		"the civic console", Vector2(15, 5), Vector2(36, 24))
	SceneBuilder.build_hotspot(props, "ChokeLever", Vector2(380, 275),
		"the transit choke lever", Vector2(-15, 0), Vector2(24, 20))

func _on_room_ready() -> void:
	room_name = "harmonic_gate"
	bloodline_socket = $Props/BloodlineSocket; warden_station = $Props/WardenStation
	council_station = $Props/CouncilStation; resonance_rings = $Props/ResonanceRings
	gate_nexus = $Props/GateNexus; archive_terminal = $Props/ArchiveTerminal
	civic_console = $Props/CivicConsole; choke_lever = $Props/ChokeLever
	for node in [bloodline_socket, warden_station, council_station, resonance_rings,
				 gate_nexus, archive_terminal, civic_console, choke_lever]:
		if node: connect_clickable(node)

func _get_entry_position() -> Vector2:
	return Vector2(100, 290)

func _play_intro() -> void:
	is_busy = true; _in_scripted_sequence = true
	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw.finished; fade_overlay.visible = false
	await _say("The island's core. Concentric white platforms open to the sky. Suspended resonance rings catch the light.")
	await _say("This is where it ends. Or begins.")
	_in_scripted_sequence = false; is_busy = false

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"BloodlineSocket": await _say("A socket at the center. Shaped for the medallion. For me.")
		"WardenStation": await _say("Seraphine's station. She stands beside it, waiting.")
		"CouncilStation": await _say("Ilyan's station. He looks tired but resolute.")
		"ResonanceRings": await _say("Three concentric rings suspended above. Each rotatable. Each representing a civic principle.")
		"GateNexus": await _say("The heart of the gate. Where transit, power, and civic harmony converge.")
		"ArchiveTerminal": await _say("Sel's archive terminal. She can unlock ring calibration.")
		"CivicConsole":
			if GameState.has_flag("rook_defeated"): await _say("The console awaits the final decision.")
			else: await _say("The civic console. It governs what mode the gate operates in.")
		"ChokeLever": await _say("A heavy lever marked TRANSIT CHOKE. Emergency use.")
		_: await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"WardenStation":
			if not GameState.has_flag("seraphine_convinced"):
				await _say("You protected this place by closing it. I understand that. But a locked gate is still a gate. It exists for a reason.")
				await _say_as("SERAPHINE", "A reason is not a guarantee.")
				await _say("No. But it's a start.")
				await _say_as("SERAPHINE", "...Very well. I commit the warden seal.")
				GameState.set_flag("seraphine_convinced")
			else: await _say_as("SERAPHINE", "My seal is committed. Proceed.")
		"CouncilStation":
			if not GameState.has_flag("ilyan_convinced"):
				await _say("If you reopen the road carelessly, you prove every fear that closed it. This has to be chosen, not flung wide.")
				await _say_as("ILYAN", "You sound like your father.")
				await _say("I'll take that as a compliment.")
				await _say_as("ILYAN", "It was. I commit the council seal.")
				GameState.set_flag("ilyan_convinced")
			else: await _say_as("ILYAN", "The council seal holds. Do what must be done.")
		"ArchiveTerminal":
			if GameState.has_flag("seraphine_convinced") and GameState.has_flag("ilyan_convinced"):
				if not GameState.has_flag("sel_calibrated"):
					await _say_as("SEL", "All three voices present. I unlock ring calibration.")
					GameState.set_flag("sel_calibrated")
				else: await _say_as("SEL", "Calibration unlocked. Tune the rings.")
			else: await _say_as("SEL", "I need both seals committed before I can unlock calibration.")
		_: await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"BloodlineSocket":
			if GameState.has_item("medallion") and not GameState.has_flag("medallion_placed"):
				await _say("I place the medallion — my medallion — into the bloodline socket. It glows.")
				GameState.set_flag("medallion_placed")
			elif GameState.has_flag("medallion_placed"): await _say("Already in place. It recognizes me.")
			else: await _say("The socket needs the medallion.")
		"ResonanceRings":
			if GameState.has_flag("sel_calibrated") and GameState.has_flag("medallion_placed"):
				if not GameState.has_flag("rings_tuned"):
					await _say_as("TIBBIT", "Allow me. This is what I was born for.")
					await _say("Tibbit tunes the resonance rings. Three harmonics align.")
					await _say("That note has — actually, no. That note is perfect.")
					GameState.set_flag("rings_tuned")
					await _trigger_rook_confrontation()
				else: await _say("The rings are tuned.")
			else: await _say("The rings need: medallion in socket, both seals committed, and Sel's calibration.")
		"ChokeLever":
			if GameState.has_flag("rook_override_active"):
				await _say("I pull the transit choke lever. The pulse folds around Rook.")
				await _say("It strips his stolen tools, throws him behind a containment field.")
				await _say_as("ROOK", "What have you done?")
				await _say("Filed an objection.")
				await _say_as("TIBBIT", "With supporting documents.")
				await _say("CIVIC GATE: Transit privileges revoked.")
				await _say("I can't imagine a more insulting sentence for you.")
				GameState.set_flag("rook_defeated")
				await _trigger_final_decision()
			else: await _say("The lever is locked. It requires... circumstances.")
		"CivicConsole":
			if GameState.has_flag("rook_defeated"):
				await _trigger_final_decision()
			else: await _say("Not yet. The gate needs to stabilize first.")
		_: await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	await _say(_random_response(_OPEN_RESPONSES))
func _push(obj: Clickable) -> void:
	await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"BloodlineSocket":
			if item_name == "medallion":
				await _use(target); return true
		"ResonanceRings":
			if item_name == "complete_civic_signet":
				await _say("The signet is for the final confirmation, not the rings.")
				return true
	return false

func _trigger_rook_confrontation() -> void:
	is_busy = true; _in_scripted_sequence = true
	await _say("Rook forces one channel open. The rings spin wildly. A transit tear opens above the harbor.")
	await _say_as("ROOK", "Such power. And all you would do is ask politely for permission to use it.")
	await _say("He activates an override drill on the civic console.")
	GameState.set_flag("rook_override_active")
	await _say("The rings shudder. Systems buckle. I need to stop him — now.")
	_in_scripted_sequence = false; is_busy = false

func _trigger_final_decision() -> void:
	is_busy = true; _in_scripted_sequence = true
	await _say("The island trembles. The gate stabilizes only with a permanent mode chosen.")

	var tree := DialogueTree.new()
	tree.add_node("start", "CIVIC GATE", "Permanent wake authorization required. Choose the island's future.")
	tree.add_choice("start", "Seal the island completely", "seal")
	tree.add_choice("start", "Open limited diplomatic contact", "limited")
	tree.add_choice("start", "Fully reopen the Wake Road", "full_open")

	tree.add_node("seal", "ROWAN", "Close it. Keep it safe. The world isn't ready.", "ending")
	tree.set_node_flag("seal", "ending_seal")
	tree.add_node("limited", "ROWAN", "Open it carefully. Deliberately. Together. Not for fear. For a future worth living in.", "ending")
	tree.set_node_flag("limited", "ending_limited")
	tree.add_node("full_open", "ROWAN", "Let the road speak for itself. Trust what we've built.", "ending")
	tree.set_node_flag("full_open", "ending_open")
	tree.add_node("ending", "CIVIC GATE", "Authorization accepted.")

	await run_dialogue_tree(tree)

	# Seals placed
	await _say("Sel, Ilyan, and Seraphine exchange a long look. One by one, they place their seals.")
	await _say("The rings slow. The chamber harmonizes. The sky clears. The island steadies.")
	GameState.set_flag("game_complete")

	await _trigger_ending_sequence()
	_in_scripted_sequence = false; is_busy = false

func _trigger_ending_sequence() -> void:
	if fade_overlay:
		fade_overlay.visible = true
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 1.0, 0.8)
		await tw.finished

	await _say("Harbor is calm. Systems repaired. Rook held under very polite, extremely firm guard.")
	await _say_as("BRAM", "I hate how elegant all this is.")
	await _say_as("TIBBIT", "You may hate it from aboard one of their floating trams.")
	await _say_as("BRAM", "I hate that even more.")

	await _say("Marrow and Rowan overlooking the lagoon.")
	await _say("So this is home.")
	await _say_as("MARROW", "Partly.")
	await _say("That seems unfair.")
	await _say_as("MARROW", "Most true things are.")

	await _say_as("SEL", "The council wishes to ask something difficult.")
	await _say("I had gathered that was the local sport.")
	await _say_as("SEL", "They want you to help design the new road.")
	await _say("Carefully, then.")
	await _say_as("TIBBIT", "Excellent. I had no intention of going home and becoming sensible.")

	await _say("At dusk, one thin line of white light extends from Isle Auric across the sea toward the mainland.")
	await _say("Not a floodgate. A path.")
	await _say("The first official transit cradle glides out over the water.")
	await _say("Rowan stands at the harbor beside Tibbit as bells ring — not in alarm, but in welcome.")

	await get_tree().create_timer(1.0).timeout

	# Post-credits
	await _say("...")
	await _say("Blackwake Harbor. Dockmaster Pindle receives a pristine white envelope with an island seal.")
	await _say_as("PINDLE", "Reciprocal customs delegation.")
	await _say("He looks up in horror.")
	await _say_as("PINDLE", "They have forms.")

	await _say("THE END")
	await _say("Thank you for playing The Iron Wake.")
